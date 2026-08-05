#pragma TextEncoding      = "UTF-8"
#pragma rtGlobals         = 3
#pragma IndependentModule = ZBR
#pragma version           = 1.00

// ZMQ_BridgeHelpers.ipf -- Igor Pro-side utility functions backing the Igor Pro Bridge
// (tools/igor-mcp-bridge/) from v2.0.0 onward, which now talks to Igor Pro over the
// ZeroMQ-XOP's CallFunction JSON protocol instead of COM Execute2/IWave/IDataFolder.
//
// **No longer a throwaway prototype**: this file is now a real, permanent dependency of
// the bridge -- see SESSION_NOTES.md for the evaluation that led here and for the
// COM-vs-ZeroMQ trade-offs. #include-d from Packages/MIES_Include.ipf in this repo; any
// OTHER Igor Pro experiment that wants to use this bridge needs this file copied
// somewhere on its own procedure search path with a matching #include added by hand --
// there is deliberately no auto-load/zero-setup mechanism (see igor-pro-bridge.rst for
// the one-time setup steps).
//
// Why an independent module (#pragma IndependentModule=ZBR):
// Per Igor's own "Advanced Topics.ihf" help (Independent Modules section): "An
// independent module is a set of procedure files that are compiled separately from all
// other procedures. Because it is compiled separately, an independent module can run
// when other procedures are in an uncompiled state because the user is editing them or
// because an error occurred in the last compile." Placing bridge-support code here means
// it stays callable via ZeroMQ's CallFunction even if the rest of the experiment (e.g.
// MIES) currently has a compile error -- unlike today's MIES_ClaudeHelper.ipf, which is
// an ordinary (non-independent) file and therefore goes down along with the rest of
// MIES's compile state. (Nothing stops MIES_ClaudeHelper.ipf from being restructured the
// same way independently of any transport change -- this benefit isn't unique to
// ZeroMQ.)
//
// The central design problem this file has to work around: Igor's `Execute` operation
// (used to run arbitrary command text, replicating COM's Execute2) cannot be called
// unqueued from inside a Function -- only `Execute/P` (deferred: queued to run only
// *after* the calling function returns to Igor's main loop) is legal there. This means a
// single ZeroMQ CallFunction round trip cannot synchronously "run this command and hand
// back what it printed" the way COM's Execute2 can, because the command hasn't actually
// run yet by the time the function returns and the reply is sent.
//
// The pattern used throughout below is submit-then-poll instead of a single blocking
// call:
//   1. ZBR_SubmitCommand(cmd) queues `cmd` and a call back into this module
//      (ZBR_FinishToken) as TWO SEPARATE Execute/P entries (not one joined string), then
//      returns a token immediately. This split matters: a single joined
//      "cmd + ; + finishCall" string was tried first and found, via live testing, to be
//      broken -- if `cmd` fails to parse OR hits a genuine runtime error partway through,
//      Igor aborts the REST of that same top-level command string, so the appended
//      finish-callback would silently never run, leaving ZBR_PollCommand reporting
//      done=0 forever (indistinguishable from a job still genuinely running). Queuing
//      `cmd` and the finish-callback as independent Execute/P entries avoids this: each
//      runs (or fails) on its own, so the finish-callback always fires regardless of what
//      happened to `cmd`. ZBR_SubmitCommandUnattended follows the same principle with its
//      extra Debugger-disable/restore steps.
//   2. ZBR_PollCommand(token), called via a LATER, separate CallFunction request, reports
//      whether it's done yet and returns whatever was printed while `cmd` ran (prefixed
//      with "ERROR: ..." if `cmd` left a pending runtime error -- see ZBR_FinishToken).
// This mirrors (and reuses the same underlying mechanism as) how the COM bridge already
// has to defer COMPILEPROCEDURES/RELOAD CHANGED PROCS and SetIgorOption poundDefine via
// Execute/P -- that part is not new or specific to ZeroMQ, it's inherent to Igor's
// compile-safety model.
//
// Limitation of independent modules relevant here (same help topic, "Limitations of
// Independent Modules", #3): "Functions in an independent module can not call functions
// in other modules except through the Execute operation." This is exactly why the
// generic Execute/P-based command submission above is the right general-purpose escape
// hatch here, matching the pattern already proven live this session with the user's own
// ZMQ_TEST#SimpleExecute test function. Direct WAVE/DFREF references are NOT
// module-scoped, so ZBR_GetWaveGeneric below needs no Execute at all.
//
// What is deliberately NOT covered here, because it isn't something Igor procedure code
// can do at all -- these must stay implemented on the CLIENT side (e.g. in Python),
// regardless of which transport (COM or ZeroMQ) carries the request:
//   - dismiss_compile_error_dialog: posts a raw Win32 WM_KEYDOWN/WM_KEYUP message to an
//     arbitrary OS window handle. No Igor operation does this.
//   - configure_igor_launch / launch_igor_pro_unattended: starting a whole new Igor Pro
//     *process* has to be done from outside any already-running Igor Pro instance.
//   - load_experiment: IApplication.LoadExperiment is COM-only (confirmed: neither
//     "LoadExperiment" nor "OpenFile" appear anywhere in Igor Reference.ihf, only in
//     Automation Server.ihf) -- there is no procedure-language way to hot-swap the open
//     experiment from inside a running instance. The bridge now instead relaunches the
//     Igor Pro *process* with the target file path as a launch argument (see
//     launch_igor_pro_unattended's docstring) -- a real process restart, not an
//     in-place swap, but needs no COM at all.
//   - get_bridge_version's python_executable/mcp_package_version/pywin32_build fields:
//     these describe the Python process, not Igor Pro. ZBR_Ping below is the Igor-side
//     analogue -- confirms this module is loaded and reachable.
//
// read_help_file (CloseHelp/OpenNotebook/SaveNotebook/parse/restore, see
// ZBR_ReadHelpFile below) IS covered here, synchronously: none of those operations are
// subject to the Execute-only-from-top-level restriction that COMPILEPROCEDURES/RELOAD
// CHANGED PROCS need -- that restriction is specific to recompiling procedures while
// procedure code is running, not a blanket rule about every window/notebook operation.
//
// Verification status: the original submit/poll, wave-access, compilation-state,
// debugger-control, and ZeroMQ-bind functions were all written into a live Igor Pro 9
// Nightly test session (via the v1.27 COM bridge, temporarily included from
// Packages/MIES/, reverted afterward) and exercised directly; a subset was also
// exercised for real over ZeroMQ via tools/zeromq-xop-test/call_igor_function_via_zmq.py.
// The introspection wrappers and ZBR_ReadHelpFile added for the v2.0.0 rewrite are new
// and have only been syntax/compile-checked so far -- see SESSION_NOTES.md for exactly
// what has and hasn't been live-verified.

// --- Constants -------------------------------------------------------------------------

/// Reported by ZBR_Ping -- kept as a named constant (rather than inline in the sprintf
/// call) per this repo's standing convention against unexplained literals, and so it
/// only needs updating in one place if this module's version ever changes independently
/// of the #pragma version above.
static StrConstant ZBR_VERSION_STR = "1.00"

/// Local endpoint this module's ZeroMQ ROUTER (server) socket (re-)binds to on every
/// compile -- see ZBR_EnsureZeroMQBound/AfterCompiledHook below. Deliberately not
/// MIES_Constants.ipf's own ZEROMQ_BIND_REP_PORT (5670) -- this prototype needs its own
/// port so it can't collide with MIES's real ZeroMQ subsystem
/// (MIES_MiesUtilities_ZeroMQ.ipf's StartZeroMQSockets) if that's ever active in the
/// same experiment. Matches the port already used throughout this session's own manual
/// testing (tools/zeromq-xop-test/call_igor_function_via_zmq.py's default endpoint).
static StrConstant ZBR_ZEROMQ_ENDPOINT = "tcp://127.0.0.1:5680"

// --- Storage -------------------------------------------------------------------------

/// Parallel-array storage for in-flight ZBR_SubmitCommand() calls, indexed by row.
/// A row's index (as a string) is the "token" handed back to the caller.
static Function ZBR_EnsureStorage()

	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:ZBR
	DFREF dfr = root:Packages:ZBR

	if(!WaveExists(dfr:done))
		Make/N=0/O dfr:done // 0 = pending, 1 = done
		Make/N=0/O/T dfr:resultText
		Make/N=0/O dfr:historyStart
	endif
End

/// One-time CaptureHistoryStart() so ZBR_SubmitCommand/ZBR_FinishToken can diff Igor's
/// history area to recover what a deferred command printed. Mirrors the same mechanism
/// (and the same "start once, read incrementally" usage pattern) the COM bridge already
/// uses for read_session_history.
///
/// CaptureHistory's real signature -- confirmed from Igor Reference.ihf, since a first
/// draft of this file wrongly assumed a single-argument CaptureHistory(stopCapturing)
/// and failed to compile -- is CaptureHistory(refnum, stopCapturing): refnum must be the
/// value CaptureHistoryStart() returned, not omitted.
///
/// **Confirmed live bug, now fixed**: `root:Packages:ZBR:captureRefNum` is a plain
/// `Variable/G`, which Igor persists into a saved experiment like any other global --
/// but the refnum it holds is only meaningful within the OS process that called
/// CaptureHistoryStart() to create it. Reloading a saved experiment (via this bridge's
/// own load_experiment, or the user manually reopening a .pxp) brings the OLD numeric
/// value back even though the process is brand new, so the mere *existence* check this
/// function used to do (`NVAR_Exists(refnum)`) was not enough -- it happily trusted a
/// stale refnum from a now-dead process. Using it then throws a genuine Igor runtime
/// error ("there is no open file with this reference number"), which -- since this can
/// be reached from a plain top-level Execute/P entry, not just from inside a Try/Catch
/// higher up -- pops a real modal error dialog and blocks Igor's whole main thread
/// (and therefore every ZeroMQ reply) until a human dismisses it. Confirmed live by
/// saving+reloading an experiment via load_experiment and then calling
/// execute_igor_command, which triggered exactly this dialog.
///
/// Fix: don't just check existence, actually try using the stored refnum, wrapped in a
/// try-catch-endtry block (see "Flow Control for Aborts" in Igor's own Programming.ihf
/// help) with an explicit AbortOnRTE right after the risky call -- a runtime error
/// inside a try block does NOT by itself jump to catch, only AbortOnRTE converts it
/// into an abort that does (confirmed from Igor's own help; an earlier version of this
/// fix omitted AbortOnRTE and also used a bare `return` with no value inside a plain,
/// implicit-Variable-returning Function, which is invalid and failed to compile --
/// see Igor's help, "The Return Statement": "The type of the returned value must
/// agree with the type declared in the function declaration"). try-catch-endtry
/// suppresses the error dialog for anything aborted inside the try block (that's its
/// whole documented purpose), so this also prevents the dialog described above from
/// appearing at all going forward. If the stored refnum turns out stale, silently
/// start a fresh capture and overwrite the stored global instead of ever surfacing
/// this to the user.
///
/// **User refinement**: CaptureHistory(...) and AbortOnRTE are deliberately kept on
/// the SAME line, not split across two lines the way this was first written. Igor's
/// Debug on Error check happens at the END of each line, not each statement -- if the
/// probe call and AbortOnRTE were on separate lines, Debug on Error (if the user
/// happens to have it enabled) would trigger a Debugger popup right when the stale
/// refnum's runtime error occurs, before AbortOnRTE ever gets a chance to convert it
/// into a catchable abort. Keeping both on one line means the end-of-line check only
/// happens after AbortOnRTE has already run, so there's nothing left pending to
/// trigger the Debugger.
static Function ZBR_EnsureCaptureStarted()

	string   dummy
	variable err

	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:ZBR

	NVAR/Z refnum = root:Packages:ZBR:captureRefNum
	if(!NVAR_Exists(refnum))
		variable/G root:Packages:ZBR:captureRefNum = CaptureHistoryStart()
	else
		NVAR refnumRW = root:Packages:ZBR:captureRefNum

		try
			dummy = CaptureHistory(refnumRW, 0); AbortOnRTE
		catch
			err      = GetRTError(1) // clear the trapped error; discard the specific code, we always recover the same way
			refnumRW = CaptureHistoryStart()
		endtry
	endif
End

static Function ZBR_CaptureRefNum()

	ZBR_EnsureCaptureStarted()
	NVAR refnum = root:Packages:ZBR:captureRefNum

	return refnum
End

static Function ZBR_HistoryLength()

	return strlen(CaptureHistory(ZBR_CaptureRefNum(), 0))
End

static Function/S ZBR_HistorySince(variable startLen)

	string full = CaptureHistory(ZBR_CaptureRefNum(), 0)

	if(strlen(full) <= startLen)
		return ""
	endif

	return full[startLen, Inf]
End

// --- Generic command execution (submit/poll) ------------------------------------------

/// Allocate a new token/storage row for an in-flight submission -- shared by
/// ZBR_SubmitCommand and ZBR_SubmitReloadAndCompile (the latter needs its own submit
/// function since its two commands must be queued separately, not joined into one
/// compound Execute/P string -- see its docstring below).
static Function/S ZBR_AllocateToken()

	variable n

	ZBR_EnsureStorage()
	DFREF  dfr          = root:Packages:ZBR
	WAVE   done         = dfr:done
	WAVE/T resultText   = dfr:resultText
	WAVE   historyStart = dfr:historyStart

	n = DimSize(done, 0)
	Redimension/N=(n + 1) done, resultText, historyStart
	done[n]         = 0
	resultText[n]   = ""
	historyStart[n] = ZBR_HistoryLength()

	return num2istr(n)
End

/// Queue `cmd` for deferred execution and return a token to poll for its result via
/// ZBR_PollCommand(). Does NOT run `cmd` synchronously -- see the module docstring above
/// for why that's not possible from inside a Function at all, independent module or not.
///
/// IMPORTANT: `cmd` and the finish-callback are queued as TWO SEPARATE Execute/P entries,
/// not joined into one string with ";". This is deliberate and was learned the hard way:
/// if `cmd` fails to parse, OR hits a genuine runtime error partway through, Igor aborts
/// the REST of that same top-level command string -- so a joined "cmd; finishCall" string
/// would silently drop the finish-callback whenever cmd errors, leaving ZBR_PollCommand
/// reporting done=0 forever with no way to distinguish that from a job still genuinely
/// running. Queuing them as independent Execute/P entries avoids this: each one runs (or
/// fails) on its own, regardless of what happened to the entry before it. This was verified
/// live: two separately-queued Execute/P entries (one invalid, one valid) both ran their
/// own outcome independently, whereas joining them with ";" let a failure in the first
/// swallow the second.
Function/S ZBR_SubmitCommand(string cmd)

	string token, finishCall

	token = ZBR_AllocateToken()
	sprintf finishCall, "ZBR#ZBR_FinishToken(%s)", token
	Execute/P/Q/Z cmd
	Execute/P/Q/Z finishCall

	return token
End

/// Same as ZBR_SubmitCommand, but disables Igor's Debugger for the duration of `cmd` and
/// restores its exact prior settings afterward -- mirrors execute_igor_command_unattended's
/// reason for existing (a Debugger pause has no scriptable resume and would otherwise hang
/// forever).
///
/// The disable step, `cmd`, the restore step, and the finish-callback are FOUR SEPARATE
/// Execute/P entries (not one joined string), for the same reason described in
/// ZBR_SubmitCommand's docstring: if `cmd` errors, anything appended after it in the same
/// string would never run. Here that would mean the Debugger stays disabled forever after
/// any erroring `cmd`, in addition to the finish-callback never firing. Because a plain
/// local variable does not survive the boundary between separate top-level Execute/P
/// entries, the saved Debugger settings are stashed in persistent globals under
/// root:Packages:ZBR instead, and the restore entry reads them back from there.
Function/S ZBR_SubmitCommandUnattended(string cmd)

	string token, finishCall, restore

	DebuggerOptions
	variable/G root:Packages:ZBR:savedDebugEnable    = V_enable
	variable/G root:Packages:ZBR:savedDebugOnError   = V_debugOnError
	variable/G root:Packages:ZBR:savedDebugOnAbort   = V_debugOnAbort
	variable/G root:Packages:ZBR:savedDebugNvarCheck = V_NVAR_SVAR_WAVE_Checking
	KillVariables/Z V_enable, V_debugOnError, V_debugOnAbort, V_NVAR_SVAR_WAVE_Checking

	restore  = "DebuggerOptions enable=root:Packages:ZBR:savedDebugEnable, "
	restore += "debugOnError=root:Packages:ZBR:savedDebugOnError, "
	restore += "debugOnAbort=root:Packages:ZBR:savedDebugOnAbort, "
	restore += "NVAR_SVAR_WAVE_Checking=root:Packages:ZBR:savedDebugNvarCheck; "
	restore += "KillVariables/Z V_enable, V_debugOnError, V_debugOnAbort, V_NVAR_SVAR_WAVE_Checking, "
	restore += "root:Packages:ZBR:savedDebugEnable, root:Packages:ZBR:savedDebugOnError, "
	restore += "root:Packages:ZBR:savedDebugOnAbort, root:Packages:ZBR:savedDebugNvarCheck"

	token = ZBR_AllocateToken()
	sprintf finishCall, "ZBR#ZBR_FinishToken(%s)", token

	Execute/P/Q/Z "DebuggerOptions enable=0"
	Execute/P/Q/Z cmd
	Execute/P/Q/Z restore
	Execute/P/Q/Z finishCall

	return token
End

/// Callback queued by ZBR_SubmitCommand/ZBR_SubmitCommandUnattended as its own, separate
/// deferred entry -- runs after `cmd` (and, for the unattended path, after the Debugger
/// restore entry) regardless of whether those entries succeeded, errored, or failed to
/// parse, so by the time a later ZBR_PollCommand() call sees done[idx] == 1, resultText[idx]
/// is guaranteed fully populated. Public (non-static) because it's invoked via a qualified
/// name (ZBR#ZBR_FinishToken) from a queued Execute/P string.
///
/// Also checks GetRTError(1), on the theory that a runtime error left pending by `cmd`
/// could be surfaced here as an explicit "ERROR: ..." prefix. **Confirmed live NOT to
/// work**: GetRTError(1) reads 0 here even immediately after a `cmd` that genuinely
/// errored (tested with both an unparseable command and a genuine runtime error --
/// WaveStats on a non-existent wave). Root cause: each Execute/P entry is dispatched as
/// its own independent top-level execution, the same as if a person had typed it at the
/// command line and pressed enter separately -- Igor resolves and clears any runtime-error
/// state as part of returning that entry to idle, before the queue advances to the next
/// entry, so nothing is left pending for a later, separate entry (like this callback) to
/// read. Also confirmed: Igor does not append anything about the error to the
/// CaptureHistory-tracked history stream either, so ZBR_HistorySince(historyStart[idx])
/// alone won't reveal it. Net effect: **there is currently no reliable, generic way for a
/// caller to distinguish "cmd ran and legitimately printed nothing" from "cmd errored out
/// partway through with no output"** -- both look identical (done=true, empty result). The
/// check below is kept as a harmless no-op/best-effort in case some other error path does
/// leave state behind, but callers should not rely on it.
///
/// **Bounds-checks idx before writing, confirmed live necessary**: `idx` is captured by
/// ZBR_AllocateToken at submission time, but this callback runs later, in its own
/// separate deferred Execute/P entry -- if the `done`/`resultText`/`historyStart` waves
/// are ever resized smaller in between (e.g. maintenance code clearing out old/orphaned
/// tokens, as happened live during this bridge's own development), `idx` can end up
/// pointing past the end of the (now-shorter) waves. Writing to an out-of-range wave
/// index throws an uncaught Igor runtime error ("Index out of range for wave..."), which
/// -- exactly like the CaptureHistory bug this module already works around -- pops a
/// real modal dialog and blocks Igor's entire main thread until a human dismisses it.
/// If idx no longer refers to a real row, there is nothing useful left to do (that
/// token's storage is simply gone), so just skip the write silently rather than crash;
/// ZBR_PollCommand already reports "ERROR: unknown token" for exactly this case via its
/// own DimSize check, so the caller still gets a clear, non-hanging answer.
Function ZBR_FinishToken(variable idx)

	variable err
	string   errMsg

	DFREF  dfr          = root:Packages:ZBR
	WAVE   done         = dfr:done
	WAVE/T resultText   = dfr:resultText
	WAVE   historyStart = dfr:historyStart

	if(idx >= 0 && idx < DimSize(done, 0))
		err = GetRTError(1)
		if(err)
			errMsg = "ERROR: " + GetErrMessage(err) + "\r"
		else
			errMsg = ""
		endif

		resultText[idx] = errMsg + ZBR_HistorySince(historyStart[idx])
		done[idx]       = 1
	endif
End

/// Poll a token from ZBR_SubmitCommand/ZBR_SubmitCommandUnattended. isDone is 0 while
/// still pending (result is then always ""); once isDone is 1, result holds everything
/// printed to history while the command ran. This is now guaranteed to eventually reach
/// isDone==1 even if the submitted command failed to parse or hit a genuine runtime error
/// partway through (see ZBR_SubmitCommand's docstring) -- but note there is currently no
/// generic way to tell that case apart from "ran fine and simply printed nothing": both
/// come back as an empty result (see ZBR_FinishToken's docstring for why the obvious
/// GetRTError(1)-based approach to detecting this doesn't work). If a command's success
/// needs to be verifiable, have it `print` an explicit sentinel value/message itself.
Function [variable isDone, string result] ZBR_PollCommand(string token)

	variable idx

	DFREF  dfr        = root:Packages:ZBR
	WAVE   done       = dfr:done
	WAVE/T resultText = dfr:resultText

	idx = str2num(token)
	if(NumType(idx) != 0 || idx < 0 || idx >= DimSize(done, 0))
		return [1, "ERROR: unknown token " + token]
	endif

	if(!done[idx])
		return [0, ""]
	endif

	return [1, resultText[idx]]
End

// --- Wave access -----------------------------------------------------------------------

/// Return a wave by its full data-folder path (e.g. "root:MyFolder:mywave"). WAVE/DFREF
/// references are not module-scoped, so this needs no Execute at all -- and unlike the
/// COM bridge's current per-point GetNumericWavePointValue loop, the ZeroMQ-XOP
/// serializes the ENTIRE wave (dimensions, units, note, complex/text/wave-ref support)
/// from this one call, per its documented wave serialization format.
Function/WAVE ZBR_GetWaveGeneric(string wavePath)

	WAVE/Z w = $wavePath
	return w
End

// --- Compilation state -------------------------------------------------------------

/// Same trick already used by check_compilation_state (and by
/// Packages/igortest/procedures/igortest-test-compilation.ipf's IsProcGlobalCompiled()):
/// FunctionInfo() for a deliberately non-existent function returns "" when procedures
/// are compiled, and a non-empty string ("Procedures Not Compiled") otherwise. No
/// Execute needed -- FunctionInfo is a plain built-in function.
Function ZBR_IsCompiled()

	return strlen(FunctionInfo("ZBR_DefinitelyNotARealFunctionName_8f3a1c")) == 0
End

/// Read root:gClaudeHelperCompileCounter (bumped by AfterCompiledHook below every time
/// Igor confirms a successful compile -- see that function) without creating it if
/// missing. Returns -1 (a real counter value can never be negative) if the global
/// doesn't exist yet, e.g. before this module's own first compile -- mirrors the COM
/// bridge's _read_claude_helper_compile_counter/_CLAUDE_HELPER_COMPILE_COUNTER_CMD
/// exactly, just as a direct typed call instead of an fprintf-wrapped command string.
/// Race-free by construction: unlike ZBR_IsCompiled's FunctionInfo poll, this only ever
/// changes at the exact moment Igor itself confirms a successful compile, so any
/// observed increase over a baseline read before triggering a reload/compile is
/// trustworthy immediately, no repeated-confirmation dance needed.
Function ZBR_ReadCompileCounter()

	return NumVarOrDefault("root:gClaudeHelperCompileCounter", -1)
End

/// RELOAD CHANGED PROCS / COMPILEPROCEDURES are themselves restricted the same way
/// Execute is -- not a new restriction introduced by this module; the COM bridge
/// already has to defer these exact same operations via Execute/P (see that bridge's
/// reload_and_compile_procedures).
///
/// **Correction (user-supplied): the two commands must be issued as separate
/// Execute/P calls, not joined into one compound string via ";" the way
/// ZBR_SubmitCommand does for arbitrary commands -- and each needs its own mandatory
/// trailing space ("RELOAD CHANGED PROCS ", "COMPILEPROCEDURES ").**
///
/// Deliberately does NOT use the ZBR_SubmitCommand/ZBR_PollCommand token+callback
/// mechanism, despite that being the obvious first attempt (and what an earlier
/// version of this function did) -- confirmed live that a finish-callback queued via
/// Execute/P *after* COMPILEPROCEDURES never actually runs: recompiling the whole
/// procedure set appears to discard/invalidate whatever was still pending behind it
/// in Igor's operation queue, rather than letting it complete afterward
/// (ZBR_FinishToken's target row stayed permanently un-done in a live test, with no
/// error reported anywhere). Poll ZBR_IsCompiled() instead -- already a direct,
/// synchronous, standalone check that doesn't depend on anything surviving the
/// recompile -- to find out when this has taken effect.
///
/// **User-identified crash hypothesis, now addressed here**: this bridge has hit
/// multiple unexplained `EXCEPTION_ACCESS_VIOLATION` crashes deep inside Igor64.exe
/// itself (confirmed via crash-dump analysis, see SESSION_NOTES.md) coinciding with
/// COMPILEPROCEDURES, with no root cause ever identified. `igortest-tracing.ipf`'s own
/// `CompileAndRestart()` runs the exact same RELOAD-CHANGED-PROCS/COMPILEPROCEDURES
/// pair reliably, with no crashes ever observed -- the key structural difference
/// (per direct user review) is that nothing else can call into Igor between
/// `CompileAndRestart()` running and Igor itself firing `AfterCompiledHook`, whereas
/// this bridge's ZeroMQ-XOP runs "a threaded message handler" (its own help file's
/// wording, ZeroMQ.ihf) that keeps dispatching incoming CallFunction requests in the
/// background regardless of what Igor's main thread is doing. If a new CallFunction
/// request -- including this bridge's own compile-status polling, or any other tool
/// call that happens to be in flight -- gets dispatched while Igor's main thread is
/// mid-COMPILEPROCEDURES (tearing down and rebuilding its own internal
/// compiled-function/symbol tables), that's a genuine cross-thread race on those very
/// tables, and a bad-pointer read deep inside Igor64.exe (exactly what both crash dumps
/// showed) is a very plausible symptom.
///
/// Fix: stop the ZeroMQ handler (`zeromq_handler_stop()`, queued via
/// ZBR_StopHandlerBeforeRecompile so it runs only after THIS call's own reply has
/// already gone out -- see that function's docstring) before RELOAD CHANGED
/// PROCS/COMPILEPROCEDURES ever run, so nothing can be dispatched into Igor while
/// it's mid-recompile. AfterCompiledHook's existing (unchanged, synchronous)
/// ZBR_EnsureZeroMQBound() call restarts the handler once compilation has actually
/// finished. This is a mitigation based on a well-reasoned but not 100%-certain
/// mechanism (Igor64.exe ships no public symbols, so the exact fault can't be proven
/// from here) -- see SESSION_NOTES.md for the full reasoning and its honest
/// limitations.
Function ZBR_SubmitReloadAndCompile()

	Execute/P/Q/Z "ZBR#ZBR_StopHandlerBeforeRecompile()"
	Execute/P/Q/Z "RELOAD CHANGED PROCS "
	Execute/P/Q/Z "COMPILEPROCEDURES "

	return 0
End

/// Stops this module's ZeroMQ message handler thread (zeromq_handler_stop()) -- queued
/// as its own independent Execute/P entry by ZBR_SubmitReloadAndCompile, deliberately
/// BEFORE RELOAD CHANGED PROCS/COMPILEPROCEDURES, so no new CallFunction request can be
/// dispatched into Igor while it's mid-recompile. See ZBR_SubmitReloadAndCompile's own
/// docstring for the full crash-hypothesis reasoning this targets.
///
/// Deliberately NOT called directly/synchronously from inside ZBR_SubmitReloadAndCompile
/// itself -- that function's own invocation is, in the end, just another CallFunction
/// request being served by the very same handler this stops. Queuing the stop via
/// Execute/P instead guarantees it only actually runs after Igor has returned to idle,
/// i.e. after THIS call's own reply has already been sent back over ZeroMQ -- avoiding
/// any risk of the handler being stopped out from under its own in-flight response.
///
/// Does not call zeromq_stop() (which would tear down every ZeroMQ bind/connection for
/// the whole Igor Pro instance, not just this module's own -- see ZBR_EnsureZeroMQBound's
/// docstring for why that's avoided elsewhere too) -- zeromq_handler_stop() is the
/// narrower, paired stop for zeromq_handler_start(), per ZeroMQ.ihf.
Function ZBR_StopHandlerBeforeRecompile()

	variable err

	zeromq_handler_stop(); err = GetRTError(1)

	return 0
End

// --- Debugger control ----------------------------------------------------------------

/// Direct (non-deferred) call -- confirmed live that DebuggerOptions, unlike
/// COMPILEPROCEDURES, is NOT restricted to top-level/Execute-only use.
Function [variable enable, variable debugOnError, variable debugOnAbort, variable nvarChecking] ZBR_GetDebuggerState()

	DebuggerOptions
	variable e = V_enable, doe = V_debugOnError, doa = V_debugOnAbort, nv = V_NVAR_SVAR_WAVE_Checking
	KillVariables/Z V_enable, V_debugOnError, V_debugOnAbort, V_NVAR_SVAR_WAVE_Checking

	return [e, doe, doa, nv]
End

Function ZBR_SetDebuggerEnabled(variable enable)

	DebuggerOptions enable=(enable != 0)
	KillVariables/Z V_enable, V_debugOnError, V_debugOnAbort, V_NVAR_SVAR_WAVE_Checking

	return 0
End

Function ZBR_RestoreDebuggerSettings(variable enable, variable debugOnError, variable debugOnAbort, variable nvarChecking)

	DebuggerOptions enable=enable, debugOnError=debugOnError, debugOnAbort=debugOnAbort, NVAR_SVAR_WAVE_Checking=nvarChecking
	KillVariables/Z V_enable, V_debugOnError, V_debugOnAbort, V_NVAR_SVAR_WAVE_Checking

	return 0
End

// --- Direct built-in introspection wrappers -------------------------------------------
//
// Each of these is exactly one synchronous CallFunction round trip: a thin wrapper
// around a single read-only Igor built-in function with no side effects and no
// Execute-restriction, so none of them need the submit/poll pattern above. Deliberately
// generic (parameters passed straight through) rather than one bespoke wrapper per
// COM-bridge tool -- structuring/parsing the returned raw strings into a proper dict
// happens client-side (Python), exactly mirroring how the COM bridge already worked (it
// also just ran fprintf-wrapped built-in calls and parsed the raw string results in
// Python) -- see get_environment_summary in server.py for where these get assembled.

/// IgorInfo(n) -- e.g. n=0 for the version/build/memory/screen report string, n=3 for
/// OS info, n=10 for the semicolon-separated loaded-XOPs list, n=11/12 for the current
/// experiment's file kind/name. See Igor Reference.ihf for the full index table.
Function/S ZBR_IgorInfo(variable n)

	return IgorInfo(n)
End

/// WinList(matchStr, ";", options) -- e.g. ZBR_WinList("*", "WIN:128") for included
/// procedure windows/files, ZBR_WinList("*", "WIN:512") for help windows.
Function/S ZBR_WinList(string matchStr, string options)

	return WinList(matchStr, ";", options)
End

/// ProcedureText(funcName, flags, winTitle) -- pass funcName="" and winTitle=a specific
/// window name (e.g. "Procedure") to retrieve that whole window's contents, per the
/// hard-won finding recorded in the COM bridge's own get_environment_summary comment:
/// the window name goes in the THIRD argument, not the first -- passing it as the first
/// argument instead silently returns "" rather than raising an error.
Function/S ZBR_ProcedureText(string funcName, variable flags, string winTitle)

	return ProcedureText(funcName, flags, winTitle)
End

/// DataFolderDir(bits) for the CURRENT data folder -- callers wanting a specific folder
/// should set it first via ZBR_SubmitCommand("SetDataFolder ...") since a DFREF argument
/// isn't threaded through here; bits=3 (folders + waves) is what get_environment_summary
/// uses.
Function/S ZBR_DataFolderDir(variable bits)

	return DataFolderDir(bits)
End

/// FunctionInfo(name) -- generic compiled-function-exists probe. ZBR_IsCompiled() above
/// is really just this called with a deliberately-bogus name; exposed generically here
/// too so a caller can check any specific marker function by name.
Function/S ZBR_FunctionInfo(string name)

	return FunctionInfo(name)
End

// --- Environment introspection -------------------------------------------------------

/// Minimal identity/diagnostic summary -- NOT what get_environment_summary uses (that
/// tool composes its full picture client-side from the granular ZBR_IgorInfo/ZBR_WinList/
/// etc. wrappers above instead, for the same reason those exist as separate functions:
/// keeping each Igor-side wrapper trivial and generic, with all the actual structuring
/// done in Python). Kept as a quick one-call smoke check alongside ZBR_Ping.
Function/S ZBR_GetEnvironmentSummary()

	string summary
	sprintf summary, "igorInfo0=%s;experiment=%s;dataFolder=%s;compiled=%d", IgorInfo(0), IgorInfo(1), GetDataFolder(1), ZBR_IsCompiled()

	return summary
End

/// Read back everything sent to history since the capture started -- analogue of
/// read_session_history. stop=1 stops the capture (matching that tool's stop=True) --
/// per CaptureHistory's own docs, a stopped refnum errors if reused, so this kills the
/// stored refnum too; the next call transparently starts a fresh capture, same as the
/// COM bridge's own read_session_history behavior.
Function/S ZBR_ReadSessionHistory(variable stop)

	string text
	variable refnum = ZBR_CaptureRefNum()

	text = CaptureHistory(refnum, stop)

	if(stop)
		KillVariables/Z root:Packages:ZBR:captureRefNum
	endif

	return text
End

// --- Health / identity -----------------------------------------------------------------

/// Minimal health-check/identity analogue of get_bridge_version -- confirms this module
/// specifically (not just "some Igor Pro instance") is loaded and reachable, and gives a
/// per-instance-distinguishing value (same idea as this session's earlier
/// GetInstanceInfo, generalized).
Function/S ZBR_Ping()

	string info
	sprintf info, "ZBR_ALIVE|version=%s|experiment=%s|dateTime=%.0f", ZBR_VERSION_STR, IgorInfo(1), DateTime

	return info
End

// --- Help file reading ------------------------------------------------------------------
//
// Synchronous equivalent of the COM bridge's read_help_file. CloseHelp/OpenNotebook/
// SaveNotebook/KillWindow/OpenHelp are ordinary window/notebook operations -- NOT subject
// to the Execute-only-from-top-level restriction that COMPILEPROCEDURES/RELOAD CHANGED
// PROCS need (see the module docstring: that restriction is about recompiling procedures
// while procedure code is running, not a blanket rule about every operation) -- so this
// entire sequence runs as one direct, synchronous CallFunction round trip, no
// submit/poll needed.

/// Return the first entry in `afterList` (semicolon-delimited) that is not present in
/// `beforeList` -- used to identify which new window WinList assigned to a just-opened
/// notebook (OpenNotebook/R doesn't return this directly). Returns "" if none found.
static Function/S ZBR_FirstNewListEntry(string afterList, string beforeList)

	variable i, n
	string name

	n = ItemsInList(afterList)
	for(i = 0; i < n; i += 1)
		name = StringFromList(i, afterList)
		if(WhichListItem(name, beforeList) == -1)
			return name
		endif
	endfor

	return ""
End

/// Resolve a bare help-file name (WinList's WIN:512 bit never includes a path -- "Procedure
/// windows and help windows don't have names. WinList returns the window title instead")
/// back to a full path, checking the two folders Igor Pro itself loads help files from.
/// Mirrors the COM bridge's _resolve_help_file_path exactly, just in compiled Igor
/// instead of Python + os.path. Returns "" if not found in either location.
static Function/S ZBR_ResolveHelpFilePath(string bareName)

	string specialDirs = "Igor Application;Igor Pro User Files"
	string base, candidate
	variable i, n

	n = ItemsInList(specialDirs)
	for(i = 0; i < n; i += 1)
		base = SpecialDirPath(StringFromList(i, specialDirs), 0, 1, 0)
		if(strlen(base) == 0)
			continue
		endif
		candidate = base + "Igor Help Files:" + bareName
		GetFileFolderInfo/Q/Z candidate
		if(V_flag == 0)
			return candidate
		endif
	endfor

	return ""
End

/// Read filePath (an .ihf help file, itself an Igor formatted-text notebook) and export
/// it as HTML to tmpHtmlPath (caller-supplied -- built by the Python side via
/// tempfile.mkstemp, same as the COM bridge already did), for the caller to parse
/// afterward. tmpHtmlPath is read directly off disk by the caller rather than being
/// serialized back through this reply: both processes run on the same machine, so a
/// local file handoff sidesteps any question about how large a CallFunction reply can
/// carry for a potentially big HTML export (the ZeroMQ-XOP's own default
/// ZMQ_MAXMSGSIZE=1024-byte limit applies to the Router's *incoming* request size, but
/// this avoids relying on any assumption about outgoing reply size limits too).
///
/// Full sequence, matching the COM bridge's read_help_file exactly, just executed
/// synchronously in compiled Igor code instead of via a client-side finally block:
///   1. Snapshot every currently open help file (visible or hidden, WIN:512) and every
///      currently open plain-notebook window (WIN:16).
///   2. CloseHelp/ALL (required: an .ihf can't be opened as a notebook while Igor
///      considers it already open as a help file).
///   3. OpenNotebook/R filePath, then diff WinList's notebook list against the step-1
///      snapshot to find the name Igor assigned the new window.
///   4. SaveNotebook/O/S=5/H=... export to tmpHtmlPath.
///   5. KillWindow/Z the temporary notebook.
///   6. Restore every help file captured in step 1 via OpenHelp/V=.../INT=0.
/// Steps 5-6 always run (via try/catch rather than a true finally, since Igor procedure
/// code has no finally block) even if step 3 or 4 failed, so a failure partway through
/// still restores whatever help state existed before this call.
///
/// Returns a "|"-joined status string: "OK|<restoreFailuresSemicolonList>" on success,
/// or "ERROR|<message>|<restoreFailuresSemicolonList>" if OpenNotebook/SaveNotebook
/// itself failed. restoreFailures lists bare file names from step 1 that could not be
/// resolved back to a full path (e.g. a help file supplied from somewhere other than the
/// two standard Help Files folders) -- these were NOT reopened.
Function/S ZBR_ReadHelpFile(string filePath, string tmpHtmlPath)

	string helpAll, helpVisible, notebooksBefore, newName, restoreFailures
	string name, resolvedPath, statusStr
	variable i, n, visibleFlag, err

	helpAll         = WinList("*", ";", "WIN:512")
	helpVisible     = WinList("*", ";", "WIN:512,VISIBLE:1")
	notebooksBefore = WinList("*", ";", "WIN:16")
	newName         = ""
	statusStr       = "OK"

	try
		CloseHelp/ALL
		AbortOnRTE

		OpenNotebook/R filePath
		AbortOnRTE

		newName = ZBR_FirstNewListEntry(WinList("*", ";", "WIN:16"), notebooksBefore)
		if(strlen(newName) == 0)
			Abort "OpenNotebook/R succeeded but no new notebook window was found"
		endif

		SaveNotebook/O/S=5/H={"UTF-8", 3, 7, 0, 0.9, 32} $newName as tmpHtmlPath
		AbortOnRTE
	catch
		err       = GetRTError(1)
		statusStr = "ERROR|" + GetErrMessage(err)
	endtry

	if(strlen(newName) > 0)
		KillWindow/Z $newName
	endif

	restoreFailures = ""
	n               = ItemsInList(helpAll)
	for(i = 0; i < n; i += 1)
		name         = StringFromList(i, helpAll)
		resolvedPath = ZBR_ResolveHelpFilePath(name)
		if(strlen(resolvedPath) == 0)
			restoreFailures = AddListItem(name, restoreFailures, ";", Inf)
			continue
		endif
		visibleFlag = (WhichListItem(name, helpVisible) != -1) ? 1 : 0
		OpenHelp/V=(visibleFlag)/INT=0/Z=1 resolvedPath
		err = GetRTError(1)
		if(err)
			restoreFailures = AddListItem(name, restoreFailures, ";", Inf)
		endif
	endfor

	return statusStr + "|" + restoreFailures
End

// --- ZeroMQ server bind ----------------------------------------------------------------

/// (Re-)bind this module's ZeroMQ ROUTER (server) socket and (re-)start the XOP's
/// background message handler, so CallFunction requests (e.g. "ZBR#ZBR_Ping") are served
/// automatically from here on -- no separate manual zeromq_server_bind/
/// zeromq_handler_start call needed after a recompile, unlike this session's earlier
/// manual testing.
///
/// **Correction (user-supplied): deliberately does NOT call zeromq_stop() first**,
/// unlike the three-call idiom shown in Igor Pro Folder/Igor Help Files/ZeroMQ.ihf's own
/// introductory example (its ServerSide() function). zeromq_stop() stops *every* ZeroMQ
/// bind/connection/handler for the whole Igor Pro instance, not just this module's own
/// -- calling it unconditionally on every compile would corrupt/tear down any other
/// already-established ZeroMQ binds (e.g. MIES's own real subsystem,
/// MIES_MiesUtilities_ZeroMQ.ipf's StartZeroMQSockets, currently short-circuited via an
/// uncommitted `return 2` in this repo's working tree but not necessarily always so).
/// Calling zeromq_server_bind directly, without stopping first, is safe to repeat on
/// every compile: if this module's own socket is already bound from an earlier compile,
/// the call simply errors ("Address in use"), caught below rather than propagated.
///
/// `; err = GetRTError(1)` immediately after each XOP call clears any resulting runtime
/// error right there on the same line -- necessary because Igor's Debugger (when
/// "Debug on Error" is enabled) only checks for a pending RTE state at the *end of a
/// line*, so leaving either of these calls' potential error unacknowledged until some
/// later line would risk popping the Debugger window here, which -- same as every other
/// popup this session has hit -- has no scriptable dismissal and would hang unattended
/// operation.
///
/// Called synchronously and directly from AfterCompiledHook (not deferred) -- confirmed
/// via user review that this part of the design is fine as-is. See
/// ZBR_StopHandlerBeforeRecompile's docstring instead for the actual fix targeting the
/// crashes this bridge has hit coinciding with COMPILEPROCEDURES: the real hazard is on
/// the OTHER side of the recompile window (a live ZeroMQ handler thread able to dispatch
/// a new CallFunction request WHILE Igor is mid-recompile), not anything happening here
/// after compilation has already finished successfully.
static Function ZBR_EnsureZeroMQBound()

	variable err

	zeromq_server_bind(ZBR_ZEROMQ_ENDPOINT); err = GetRTError(1)
	zeromq_handler_start(); err = GetRTError(1)

	return 0
End

static Function AfterCompiledHook()

	variable modifiedBefore

	// Creating/incrementing a global marks the experiment as modified, same as any
	// other data change. Captured/restored here so this hook never flips an
	// otherwise-unmodified experiment to modified, matching the existing convention
	// in MIES_IgorHooks.ipf's own AfterCompiledHook -- flagged by a Copilot PR
	// review as a real risk otherwise: an experiment spuriously marked modified can
	// trigger a "Save changes?" prompt later, which is exactly the kind of dialog
	// this bridge (built around unattended operation) cannot dismiss remotely.
	ExperimentModified
	modifiedBefore = V_flag

	// Make this module's ZeroMQ server listen again immediately after every compile --
	// the whole point of running this from AfterCompiledHook rather than requiring a
	// separate manual step each time the code changes. Called directly/synchronously
	// (not deferred) -- confirmed via user review that this is fine: by the time
	// AfterCompiledHook runs, compilation has already finished successfully, so there
	// is nothing left to race against here. See ZBR_StopHandlerBeforeRecompile's
	// docstring for the actual fix targeting this bridge's COMPILEPROCEDURES-adjacent
	// crashes -- the real hazard is upstream of this point (a live handler able to
	// dispatch a new CallFunction request while Igor is still mid-recompile).
	ZBR_EnsureZeroMQBound()

	// Bare Variable/G (no initializer) is safe to call unconditionally: per Igor
	// Reference.ihf, /G "overwrites any existing variable" but "the variable is
	// initialized when it is created if you supply the initial value" -- i.e. the
	// overwrite-to-a-value only happens when an initializer is given. Without one,
	// this creates the global at 0 the first time and leaves an existing value
	// alone on every call after that, so no NVAR_Exists guard is needed.
	variable/G root:gClaudeHelperCompileCounter
	NVAR gClaudeHelperCompileCounter = root:gClaudeHelperCompileCounter

	gClaudeHelperCompileCounter += 1

	if(!modifiedBefore)
		ExperimentModified 0
	endif

	return 0
End
