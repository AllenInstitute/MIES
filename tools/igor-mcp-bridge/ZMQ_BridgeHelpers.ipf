#pragma rtFunctionErrors  = 1
#pragma TextEncoding      = "UTF-8"
#pragma rtGlobals         = 3
#pragma IndependentModule = ZBR
#pragma version           = 1.00

// ZMQ_BridgeHelpers.ipf -- Igor Pro-side helper functions for the Igor Pro Bridge
// (tools/igor-mcp-bridge/), which talks to Igor over the ZeroMQ-XOP's CallFunction JSON
// protocol. #include-d from Packages/MIES_Include.ipf; see igor-pro-bridge.rst for setup
// in other experiments, and SESSION_NOTES.md for full design rationale/history.
//
// Compiles as its own independent module (#pragma IndependentModule=ZBR) so it stays
// reachable via CallFunction even if the rest of the experiment has a compile error.
// Execute cannot run unqueued from inside a Function, so most operations here use a
// submit (Execute/P) + poll pattern instead of one blocking call -- see
// ZBR_SubmitCommand/ZBR_PollCommand.

// --- Constants -------------------------------------------------------------------------

/// Reported by ZBR_Ping.
static StrConstant ZBR_VERSION_STR = "1.00"

/// ZeroMQ ROUTER (server) socket endpoint -- distinct from MIES's own ZeroMQ port
/// (MIES_MiesUtilities_ZeroMQ.ipf) to avoid collisions.
static StrConstant ZBR_ZEROMQ_ENDPOINT     = "tcp://127.0.0.1"
static Constant    ZBR_ZEROMQ_DEFAULT_PORT = 5680
static StrConstant ZBR_ZEROMQ_ENV_PORT     = "IGOR_PRO_BRIDGE_PORT"

static StrConstant ZBR_RECOMPILE_WATCHDOG_TASK = "ZBR_RecompileWatchdog"

// --- Storage -------------------------------------------------------------------------

/// Parallel-array storage for in-flight ZBR_SubmitCommand() calls, indexed by row. A
/// row's index (as a string) is the token handed back to the caller.
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

/// Ensures a valid CaptureHistoryStart() refnum is active, recovering if the stored one
/// is stale (e.g. after reloading a saved experiment). See SESSION_NOTES.md for why the
/// probe call and AbortOnRTE must stay on the same line.
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
			err      = GetRTError(1)
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

/// Allocates a new token/storage row, shared by ZBR_SubmitCommand and
/// ZBR_SubmitReloadAndCompile.
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

/// Queues `cmd` for deferred execution and returns a token to poll via ZBR_PollCommand().
/// `cmd` and the finish-callback are queued as separate Execute/P entries so the
/// callback still runs even if `cmd` fails to parse or errors -- see SESSION_NOTES.md.
Function/S ZBR_SubmitCommand(string cmd)

	string token, finishCall

	token = ZBR_AllocateToken()
	sprintf finishCall, "ZBR#ZBR_FinishToken(%s)", token
	Execute/P/Q/Z cmd
	Execute/P/Q/Z finishCall

	return token
End

/// Same as ZBR_SubmitCommand, but disables Igor's Debugger for `cmd`'s duration and
/// restores it afterward via persistent globals (plain locals don't survive the
/// boundary between separate Execute/P entries).
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

/// Deferred callback that finalizes a submitted command's result row. Bounds-checks idx
/// before writing since storage may have been resized since submission. See
/// SESSION_NOTES.md for why GetRTError(1) here can't reliably detect that `cmd` errored.
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

/// Polls a token from ZBR_SubmitCommand/ZBR_SubmitCommandUnattended. isDone=0 while
/// pending; once isDone=1, result holds everything printed while the command ran (see
/// SESSION_NOTES.md for the "ran fine vs. errored silently" ambiguity).
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

/// Returns a wave by its full data-folder path.
Function/WAVE ZBR_GetWaveGeneric(string wavePath)

	WAVE/Z w = $wavePath
	return w
End

// --- Compilation state -------------------------------------------------------------

/// True if ProcGlobal is compiled. Must qualify the FunctionInfo() probe with
/// "ProcGlobal#" -- an unqualified name resolves against this (always-compiled)
/// independent module instead. See SESSION_NOTES.md.
Function ZBR_IsCompiled()

	return strlen(FunctionInfo("ProcGlobal#ZBR_DefinitelyNotARealFunctionName_8f3a1c")) == 0
End

/// Reads root:gClaudeHelperCompileCounter (bumped by AfterCompiledHook on every
/// successful compile) without creating it. Returns -1 if not yet created.
Function ZBR_ReadCompileCounter()

	return NumVarOrDefault("root:gClaudeHelperCompileCounter", -1)
End

/// Queues ZBR_StopHandlerBeforeRecompile, RELOAD CHANGED PROCS, and COMPILEPROCEDURES as
/// three separate Execute/P entries (each needs its own trailing space). Poll
/// ZBR_IsCompiled()/ZBR_ReadCompileCounter() rather than a finish-callback -- anything
/// queued behind COMPILEPROCEDURES is discarded by the recompile. See SESSION_NOTES.md
/// for the crash mitigation this exists for.
Function ZBR_SubmitReloadAndCompile()

	Execute/P/Q/Z "ZBR#ZBR_StopHandlerBeforeRecompile()"
	Execute/P/Q/Z "RELOAD CHANGED PROCS "
	Execute/P/Q/Z "COMPILEPROCEDURES "

	return 0
End

/// Stops the ZeroMQ handler and arms the recompile watchdog before RELOAD CHANGED
/// PROCS/COMPILEPROCEDURES run.
Function ZBR_StopHandlerBeforeRecompile()

	variable err

	zeromq_handler_stop(); err = GetRTError(1)
	ZBR_ArmRecompileWatchdog()

	return 0
End

/// Restarts the ZeroMQ handler only -- does not rebind the socket. See
/// ZBR_EnsureZeroMQBound's docstring for why binding now lives elsewhere.
Function ZBR_StartHandlerAfterRecompile()

	variable err

	zeromq_handler_start(); err = GetRTError(1)

	return 0
End

/// Arms a named background task that unconditionally restarts the ZeroMQ handler after a
/// reload/compile attempt, whether it succeeded or failed (AfterCompiledHook alone can't
/// cover the failure case). `start=60` sets an explicit ~1s floor before the first
/// possible tick, since background tasks and the deferred operation queue are not
/// strictly ordered -- see SESSION_NOTES.md for the timing data behind this value.
static Function ZBR_ArmRecompileWatchdog()

	variable err

	CtrlNamedBackground $ZBR_RECOMPILE_WATCHDOG_TASK, period=30, proc=ZBR_RecompileWatchdogTick, start=60
	err = GetRTError(1)

	return 0
End

/// Restarts the ZeroMQ handler via ZBR_StartHandlerAfterRecompile() and self-disarms.
/// Public (non-static): CtrlNamedBackground's proc= target must be resolvable from
/// outside this function's own immediate caller.
Function ZBR_RecompileWatchdogTick(STRUCT WMBackgroundStruct &s)

	ZBR_StartHandlerAfterRecompile()
	CtrlNamedBackground $ZBR_RECOMPILE_WATCHDOG_TASK, stop

	return 1
End

// --- Debugger control ----------------------------------------------------------------

Function [variable enable, variable debugOnError, variable debugOnAbort, variable nvarChecking] ZBR_GetDebuggerState()

	DebuggerOptions
	variable e   = V_enable
	variable doe = V_debugOnError
	variable doa = V_debugOnAbort
	variable nv  = V_NVAR_SVAR_WAVE_Checking
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
// Thin, generic passthroughs to read-only Igor built-ins -- structuring/parsing the
// returned raw strings into a proper dict happens client-side (Python); see
// get_environment_summary in server.py for where these get assembled.

/// IgorInfo(n) passthrough -- see Igor Reference.ihf for the index table.
Function/S ZBR_IgorInfo(variable n)

	return IgorInfo(n)
End

/// WinList(matchStr, ";", options) passthrough.
Function/S ZBR_WinList(string matchStr, string options)

	return WinList(matchStr, ";", options)
End

/// ProcedureText(funcName, flags, winTitle) passthrough. Pass funcName="" and winTitle=a
/// window name to retrieve that window's whole contents -- winTitle is the third
/// argument, not the first (passing it first silently returns "").
Function/S ZBR_ProcedureText(string funcName, variable flags, string winTitle)

	return ProcedureText(funcName, flags, winTitle)
End

/// DataFolderDir(bits) for the current data folder. Callers wanting a specific folder
/// should set it first via ZBR_SubmitCommand("SetDataFolder ...").
Function/S ZBR_DataFolderDir(variable bits)

	return DataFolderDir(bits)
End

/// FunctionInfo(name) passthrough. ZBR_IsCompiled() is this called with a bogus name.
Function/S ZBR_FunctionInfo(string name)

	return FunctionInfo(name)
End

// --- Environment introspection -------------------------------------------------------

/// Minimal identity/diagnostic summary; get_environment_summary composes its full
/// picture client-side from the granular wrappers above instead.
Function/S ZBR_GetEnvironmentSummary()

	string summary
	sprintf summary, "igorInfo0=%s;experiment=%s;dataFolder=%s;compiled=%d", IgorInfo(0), IgorInfo(1), GetDataFolder(1), ZBR_IsCompiled()

	return summary
End

/// Reads back everything sent to history since the capture started. stop=1 also kills
/// the stored refnum; the next call starts a fresh capture.
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

/// Confirms this module specifically is loaded and reachable.
Function/S ZBR_Ping()

	string info
	sprintf info, "ZBR_ALIVE|version=%s|experiment=%s|dateTime=%.0f", ZBR_VERSION_STR, IgorInfo(1), DateTime

	return info
End

// --- Help file reading ------------------------------------------------------------------
//
// Synchronous equivalent of the COM bridge's read_help_file -- none of these operations
// are subject to the Execute-only-from-top-level restriction COMPILEPROCEDURES needs, so
// this runs as one direct CallFunction round trip, no submit/poll needed.

/// Returns the first entry in `afterList` not present in `beforeList`, or "" if none.
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

/// Resolves a bare help-file name (as returned by WinList's WIN:512 bit) to a full path,
/// or "" if not found in Igor's standard Help Files folders.
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

/// Exports filePath (an .ihf help file) as HTML to tmpHtmlPath, restoring whatever help
/// windows were open beforehand. Returns "OK|<restoreFailures>" or
/// "ERROR|<message>|<restoreFailures>". See SESSION_NOTES.md for the full sequence and
/// the Abort-dialog pitfall this avoids.
Function/S ZBR_ReadHelpFile(string filePath, string tmpHtmlPath)

	string helpAll, helpVisible, notebooksBefore, newName, restoreFailures
	string name, resolvedPath, statusStr
	variable i, numHelpWin, visibleFlag, err

	helpAll         = WinList("*", ";", "WIN:512")
	helpVisible     = WinList("*", ";", "WIN:512,VISIBLE:1")
	notebooksBefore = WinList("*", ";", "WIN:16")
	newName         = ""
	statusStr       = "OK"

	try
		CloseHelp/ALL; AbortOnRTE

		OpenNotebook/R filePath; AbortOnRTE

		newName = ZBR_FirstNewListEntry(WinList("*", ";", "WIN:16"), notebooksBefore)
		if(strlen(newName) == 0)
			// Not Abort "<message>" -- pops a dialog before catch runs. See SESSION_NOTES.md.
			statusStr = "ERROR|OpenNotebook/R succeeded but no new notebook window was found"
		else
			SaveNotebook/O/S=5/H={"UTF-8", 3, 7, 0, 0.9, 32} $newName as tmpHtmlPath; AbortOnRTE
		endif
	catch
		err       = GetRTError(1)
		statusStr = "ERROR|" + GetErrMessage(err)
	endtry

	if(strlen(newName) > 0)
		KillWindow/Z $newName
	endif

	restoreFailures = ""
	numHelpWin      = ItemsInList(helpAll)
	for(i = 0; i < numHelpWin; i += 1)
		name         = StringFromList(i, helpAll)
		resolvedPath = ZBR_ResolveHelpFilePath(name)
		if(strlen(resolvedPath) == 0)
			restoreFailures = AddListItem(name, restoreFailures, ";", Inf)
			continue
		endif
		visibleFlag = (WhichListItem(name, helpVisible) != -1) ? 1 : 0
		OpenHelp/V=(visibleFlag)/INT=0/Z=1 resolvedPath; err = GetRTError(1)
		if(err)
			restoreFailures = AddListItem(name, restoreFailures, ";", Inf)
		endif
	endfor

	return statusStr + "|" + restoreFailures
End

// --- ZeroMQ server bind ----------------------------------------------------------------

/// (Re-)binds this module's ZeroMQ ROUTER socket and starts its handler. Does not call
/// zeromq_stop() first, so it won't tear down any other ZeroMQ binds in the same
/// experiment (e.g. MIES's own). Safe to call repeatedly -- an already-bound error is
/// caught, not propagated. Called only from IgorStartOrNewHook; recompiles instead just
/// stop/restart the handler via ZBR_StopHandlerBeforeRecompile/
/// ZBR_StartHandlerAfterRecompile, not a full rebind. See SESSION_NOTES.md.
static Function ZBR_EnsureZeroMQBound()

	variable err, port
	string bindURL, envPort

	envPort = GetEnvironmentVariable(ZBR_ZEROMQ_ENV_PORT)
	if(!strlen(envPort))
		port = ZBR_ZEROMQ_DEFAULT_PORT
	else
		port = str2num(envPort); err = GetRTError(1)
		if(numType(port) == 2)
			printf "Could not parse port number from %s: %s\rUsing default port %d\r", ZBR_ZEROMQ_ENV_PORT, envPort, ZBR_ZEROMQ_DEFAULT_PORT
			port = ZBR_ZEROMQ_DEFAULT_PORT
		endif
	endif

	sprintf bindURL, "%s:%d", ZBR_ZEROMQ_ENDPOINT, port
	zeromq_server_bind(bindURL); err = GetRTError(1)
	if(!err)
		printf "Igor Pro Bridge MCP bound through ZMQ at port %d\r", port
	endif
	zeromq_handler_start(); err = GetRTError(1)

	return 0
End

/// Releases running thread groups before Igor uncompiles, preventing a blocking
/// "Function Execution Module is still active" dialog from a stray MIES background
/// thread during COMPILEPROCEDURES. See SESSION_NOTES.md.
static Function BeforeUncompiledHook(variable changeCode, string procedureWindowTitleStr, string textChangeStr)

	variable err

	err = ThreadGroupRelease(-2)
End

/// Fires on Igor launch and on creating a new experiment. Binds/starts the ZeroMQ
/// handler here (once per process) rather than in AfterCompiledHook.
static Function IgorStartOrNewHook(string igorApplicationNameStr)

	variable modifiedBefore

	ExperimentModified
	modifiedBefore = V_flag

	ZBR_EnsureZeroMQBound()

	if(!modifiedBefore)
		ExperimentModified 0
	endif

	return 0
End

/// Bumps the compile-confirmation counter on every successful compile. Does not touch
/// the ZeroMQ socket/handler -- see IgorStartOrNewHook.
static Function AfterCompiledHook()

	variable modifiedBefore

	ExperimentModified
	modifiedBefore = V_flag

	variable/G root:gClaudeHelperCompileCounter
	NVAR gClaudeHelperCompileCounter = root:gClaudeHelperCompileCounter

	gClaudeHelperCompileCounter += 1

	if(!modifiedBefore)
		ExperimentModified 0
	endif

	return 0
End
