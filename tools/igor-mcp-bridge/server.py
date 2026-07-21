"""
Igor Pro MCP bridge server
==========================

Exposes a running Igor Pro instance to Claude (or any MCP client) as a set of MCP tools,
by acting as a COM Automation *client* that talks to Igor Pro's built-in ActiveX
Automation *Server* on Windows.

All API details below were extracted directly from the local file:
    Igor Pro Folder\\Miscellaneous\\Windows Automation\\Automation Server.ihf
(WaveMetrics' own reference for this interface) during this session. Confirmed facts:

- ProgID: "IgorPro.Application".
- Connect to an ALREADY RUNNING Igor instance with GetActiveObject (this is the Python
  equivalent of the documented VB pattern `GetObject(, "IgorPro.Application")`). Using
  win32com.client.Dispatch() instead would *launch* a new Igor instance, which requires
  extra care (the docs warn the client must then wait for Igor to finish initializing
  before calling methods) -- GetActiveObject sidesteps that entirely by only attaching to
  something already running and initialized.
- Execute(BSTR cmds): fire-and-forget, raises a COM error on failure, no structured
  output.
- Execute2(int flags, int codePage, BSTR cmds, int* pIgorErrorCode, BSTR* errorMsg,
  BSTR* history, BSTR* results): does NOT raise a COM/Automation error just because the
  Igor command itself failed -- you must check pIgorErrorCode (0 == success) yourself.
  `codePage` is ignored since Igor 7 (pass 0). `results` is how you get data back: put
  `fprintf 0, "..."` calls inside `cmds` and read them from `results` afterwards (this is
  literally WaveMetrics' own documented example: `fprintf 0, "%g", V_avg` then read
  `results`).
- IApplication.DataFolder(nameOrPath) -> IDataFolder. IDataFolder.Wave(waveNameOrPath) ->
  IWave. `waveNameOrPath` may be an absolute path (e.g. "root:myFolder:myWave"), so in
  practice you can anchor on "root:" and pass a full absolute path straight into .Wave().
- IWave.GetDimensions(IgorProDataType* pDataType, long* pNumRows, long* pNumColumns,
  long* pNumLayers, long* pNumChunks).
- IgorProDataType enum values (confirmed from the .ihf, exact hex values):
    ipDataTypeText          = 0
    ipDataTypeComplex       = 0x01   (combination flag, OR'd with another value)
    ipDataTypeFloat         = 0x02
    ipDataTypeDouble        = 0x04
    ipDataTypeSignedByte    = 0x08
    ipDataTypeSignedShort   = 0x10
    ipDataTypeSignedLong    = 0x20
    ipDataTypeUnsignedByte  = 0x48
    ipDataTypeUnsignedShort = 0x50
    ipDataTypeUnsignedLong  = 0x60
  i.e. dataType == 0 means text, anything else is some numeric flavor (real-valued
  numeric flavors all supported by GetNumericWavePointValue below; complex waves --
  dataType & 0x01 -- are NOT handled by this file yet, see limitation note below).
- IWave.GetNumericWavePointValue(long index, double* pValue) -- single-point numeric
  read, "supports real data only" (per the docs' own wording), works for any real
  numeric subtype (float/double/int/etc.), 1D waves only.
- IWave.GetTextWavePointValue(long index, int codePage, BSTR* pValue) -- single-point
  text read, 1D waves only, codePage ignored since Igor 7 (pass 0).
  (The docs also document GetRawTextWaveData/GetNumericWaveDataAsDouble, which pull an
  entire wave at once via a SAFEARRAY, but explicitly recommend the point-value methods
  "for most uses" -- and the point-value methods sidestep SAFEARRAY marshaling questions
  entirely, so this file uses those instead. Whole-wave SAFEARRAY access could be added
  later as a faster path for large waves.)
- **CRITICAL SETUP REQUIREMENT, confirmed verbatim from the docs**: "The Windows
  operating system requires that you run the client and server (Igor) as administrator."
  I.e. BOTH this Python process AND Igor Pro itself must be started as Administrator on
  Windows 10+, or the COM connection will fail. This is not optional and is easy to miss.

ONE THING THIS FILE CANNOT VERIFY FROM here (no Windows/Igor available to actually run
this): the exact Python-side calling convention pywin32's dynamic dispatch uses for
methods with multiple [out] parameters. The general IDispatch convention -- and how
win32com.client's dynamic dispatch conventionally exposes it -- is: [out]-only
parameters (not [in,out]) are NOT passed by the caller; instead they come back bundled
as a tuple appended to the method's normal return value. That is the convention this
file assumes throughout (e.g. `errorCode, errorMsg, history, results = igor.Execute2(0,
0, cmd)`). This is standard, well-established pywin32 behavior (the same pattern used
for e.g. Excel's Automation methods), not a wild guess -- but it has not been run against
the real Igor Pro COM server in this session, so treat it as the one item to confirm on
first real use. If it doesn't unpack as expected, print(repr(result)) from a raw call to
see the actual shape pywin32 returned and adjust the unpacking.

Setup
-----
    pip install mcp pywin32

Registering with Claude Desktop
--------------------------------
Add to claude_desktop_config.json under "mcpServers":

    "igor-pro": {
      "command": "python",
      "args": ["C:\\path\\to\\server.py"]
    }

Then restart Claude Desktop. Remember: both Claude Desktop's Python process AND Igor Pro
itself need to be running elevated (as Administrator) for the COM connection to succeed.

This is a *local* MCP server (stdio transport) -- it only works from a Claude Desktop
session running on the same Windows machine as Igor Pro, not from a cloud/Cowork sandbox.
"""

import ctypes
import sys
import time

import pywintypes
import win32com.client

from mcp.server.fastmcp import FastMCP

IGOR_COM_PROGID = "IgorPro.Application"

# IgorProDataType enum (confirmed values, see module docstring)
IP_DATATYPE_TEXT = 0
IP_DATATYPE_COMPLEX_FLAG = 0x01

mcp = FastMCP("igor-pro")

_igor = None


def _is_current_process_elevated():
    """Return True/False if this Python process itself is running elevated (as
    Administrator), or None if that can't be determined.

    Uses ctypes.windll.shell32.IsUserAnAdmin() -- the standard, minimal way to check
    *this* process's own elevation on Windows. This is deliberately much simpler than
    the OpenProcessToken/GetTokenInformation dance needed to check an *arbitrary* other
    process's elevation (e.g. Igor Pro's) from outside; for our own process, this one
    call is sufficient and doesn't need that machinery.

    This check exists because an elevation mismatch between this process and Igor Pro
    is a real, easy-to-miss failure mode confirmed during development: Claude Desktop
    can appear to be "running as Administrator" while the specific child process
    running this script is not, if Claude Desktop itself was reopened normally rather
    than explicitly relaunched via "Run as administrator" (Windows does not persist
    elevation across relaunches by default).
    """
    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except Exception:
        return None


_elevated_at_startup = _is_current_process_elevated()
if _elevated_at_startup is False:
    print(
        "WARNING: this MCP server process is NOT running elevated (as Administrator). "
        "Igor Pro's COM Automation Server requires BOTH Igor Pro and this process to be "
        "elevated, or every tool call will fail with a COM/RPC error. Relaunch Claude "
        "Desktop specifically via 'Run as administrator' -- reopening it normally does "
        "not preserve elevation across restarts.",
        file=sys.stderr,
    )
elif _elevated_at_startup is None:
    print(
        "NOTE: could not determine whether this process is running elevated.",
        file=sys.stderr,
    )


def _get_igor(force_reconnect=False):
    """Attach to an already-running Igor Pro instance via COM.

    Uses GetActiveObject (not Dispatch) deliberately: GetActiveObject only attaches to
    an instance that's already running and initialized, matching WaveMetrics' own
    documented VB pattern `GetObject(, "IgorPro.Application")`. Dispatch() would instead
    launch a brand-new Igor instance if one isn't already registered, which requires
    extra initialization-wait handling this file doesn't implement.

    force_reconnect=True discards any cached connection first. Needed because this
    process caches _igor for its whole lifetime (it may serve many tool calls): if Igor
    Pro is closed/restarted/crashes in between, the cached COM reference goes stale and
    every subsequent call fails with a COM/RPC-transport error (e.g. "The RPC server is
    unavailable") -- not a normal Igor-level failure. See _run_with_reconnect below.
    """
    global _igor
    if force_reconnect:
        _igor = None
    if _igor is None:
        try:
            _igor = win32com.client.GetActiveObject(IGOR_COM_PROGID)
        except Exception as e:
            raise RuntimeError(
                "Could not attach to a running Igor Pro instance via COM. Make sure: "
                "(1) Igor Pro is already running, (2) BOTH Igor Pro and this Python "
                "process are running as Administrator (Windows requires this for COM "
                "Automation), and (3) Igor Pro 10 (or later) is installed with the "
                "Automation Server component."
            ) from e
    return _igor


def _run_with_reconnect(work_fn):
    """Run work_fn() once, retrying exactly once with a fresh COM connection if the
    cached connection turns out to be stale.

    work_fn should call _get_igor() itself (not close over a stale `igor` variable) so
    the retry actually picks up a freshly reconnected object.

    Why this is safe to do unconditionally: Execute2 reports Igor-level command
    failures via pIgorErrorCode, not exceptions (see module docstring) -- so a
    pywintypes.com_error escaping from here always means the COM/RPC transport itself
    broke (most commonly: Igor Pro was closed or restarted since the last call, leaving
    a dead reference cached), never that an Igor command merely failed. If Igor is
    genuinely not reachable at all, the retry's _get_igor() call raises a plain
    RuntimeError (see above), which is not caught here and propagates immediately --
    so this never turns into a silent retry loop.
    """
    try:
        return work_fn()
    except pywintypes.com_error:
        _get_igor(force_reconnect=True)
        return work_fn()


def _get_wave_ref(wave_path: str):
    """(Re)derive the IWave COM object for wave_path from the *current* Igor connection.

    This goes through DataFolder() and Wave() -- two more COM calls, same reconnect
    risk as everything else here. Factored out so both the initial fetch and any
    post-reconnect re-fetch (in get_wave below) call the exact same path, and never
    accidentally keep using a `wave` object derived from a now-dead `igor`/`root`.
    """
    igor = _get_igor()
    root = igor.DataFolder("root:")
    wave = root.Wave(wave_path)
    if wave is None:
        raise RuntimeError(f"Wave not found: {wave_path}")
    return wave


def _read_wave_point(wave, index: int, is_text: bool):
    """One point-value COM call -- GetTextWavePointValue or GetNumericWavePointValue."""
    if is_text:
        return wave.GetTextWavePointValue(index, 0)
    return wave.GetNumericWavePointValue(index)


def _execute2(command: str):
    """Run `command` via Execute2 and return (errorCode, errorMsg, history, results).

    See the calling-convention caveat in the module docstring -- this unpacking is the
    one thing to verify empirically on first real run.
    """
    def work():
        igor = _get_igor()
        return igor.Execute2(0, 0, command)

    errorCode, errorMsg, history, results = _run_with_reconnect(work)
    return errorCode, errorMsg, history, results


# --- Igor runtime error model (how errors surface through Execute2) -----------------
#
# Confirmed empirically this session, against a live Igor Pro instance, by
# instrumenting test functions with checkpoints (a global string variable, since
# GetRTError does not expose "where in the call did this happen", only "what/whether"):
#
# - With the Debugger disabled (the state required for unattended use -- see
#   "Debugger control" below), an unhandled runtime error (e.g. indexing a wave
#   reference that doesn't exist, or Make with invalid parameters) does NOT stop
#   execution. It sets Igor's internal runtime-error flag (readable via GetRTError(0)
#   without clearing it) and execution continues completely normally -- every
#   subsequent line in the function runs, including any side effects (prints, wave
#   writes, global variable assignments), all the way to the function's natural end,
#   unless something explicitly checks the flag.
# - AbortOnRTE is that explicit check: placed after a command that might set the
#   flag, it raises an Igor abort if the flag is set, which unwinds the *entire*
#   current function immediately (nothing after it in that function runs, not even
#   the rest of the function) and propagates to the nearest enclosing
#   try-catch-endtry, exactly like a normal exception -- confirmed with a runtime
#   error inside a *called* function: the abort skipped the rest of that function
#   entirely and was caught by a try/catch in the *caller*. Nested try-catch-endtry
#   behaves as expected too: an inner catch fully absorbs an abort (the outer catch
#   never triggers), and a bare `Abort` (no arguments) re-raised from inside a catch
#   unwinds past that catch's own endtry to the next enclosing catch, still carrying
#   the original pending error code if it was only peeked (GetRTError(0)) and not
#   cleared (GetRTError(1)) beforehand.
# - If nothing ever checks the flag (no AbortOnRTE, no try-catch), execution reaches
#   the top-level command boundary -- i.e. this bridge's Execute2 call -- with the
#   flag still set. Igor's command-line evaluator checks for this at that boundary
#   and reports it as the Execute2 call's own failure (pIgorErrorCode/errorMsg),
#   confirmed to carry the *original* error code and message, not a generic one.
#   This boundary check also clears the flag afterward -- confirmed by checking
#   GetRTError(0) in a completely separate subsequent call and seeing 0 -- so a
#   failure here never contaminates the next command.
# - The flag is "sticky": if two *different* unhandled runtime errors occur in
#   sequence with nothing checking/clearing in between, GetRTError keeps reporting
#   only the *first* one throughout -- confirmed by triggering two distinct errors
#   (a null-wave read, then an invalid Make) and seeing the reported code/message
#   stay fixed at the first error the whole time, including in the final Execute2
#   result. This matches Igor's own documented caveat that GetErrMessage can be
#   "incomplete" when multiple errors occur.
#
# Net effect for this bridge: a successful (errorCode 0) unattended call is a
# reliable clean signal -- the boundary check guarantees no lingering error. A
# failed call reliably reports the *first* unhandled runtime error's code and
# message, but does NOT mean execution stopped there -- everything before and after
# it in the procedure code likely still ran to completion -- and does NOT mean it
# was the *only* problem, since any later distinct error would be silently masked
# by the same stuck flag. Because of this, _format_execute2_error below includes
# whatever `results` (fprintf output) was captured, not just the error itself --
# that's often the only way to tell how far execution actually got.


def _format_execute2_error(
    command: str, errorCode: int, errorMsg: str, results: str, history: str = ""
) -> str:
    """Build the message for a RuntimeError raised after a failed Execute2 call,
    including any partial `results` (fprintf output) and/or `history` captured
    before/around the error -- see the runtime error model notes above for why that
    matters: the procedure code very likely kept running after the error, so there
    may be diagnostic output that would otherwise be silently discarded.

    DIAGNOSTIC NOTE (temporary, being verified live): confirmed empirically that
    Igor's Execute2 returns an EMPTY `results` string whenever pIgorErrorCode is
    nonzero, even when an fprintf 0, ... earlier in the same command definitely ran
    (confirmed via a separate global-variable checkpoint) -- so `results` alone does
    NOT recover anything in the common case of a single top-level command/function
    call failing. Including `history` here as well to check whether it fares better."""
    parts = [
        f"Igor command failed (error code {errorCode}): {errorMsg or '(no error message)'}"
    ]
    if results:
        parts.append(f"Partial results captured before/around the error: {results!r}")
    if history:
        parts.append(f"History captured for this call: {history!r}")
    parts.append(f"Command was: {command}")
    return "\n".join(parts)


@mcp.tool()
def execute_igor_command(command: str) -> str:
    """Execute a single Igor Pro command string in the running Igor instance.

    To get data back (not just run a command for its side effect), include an
    `fprintf 0, "..."` call in `command` -- its output is captured and returned.

    Example: execute_igor_command('WaveStats/Q jack; fprintf 0, "%g", V_avg')

    **Caution:** if `command` calls user-defined procedure code (e.g. a MIES or test
    function) and Igor Pro's Debugger is currently enabled, a breakpoint/runtime
    error/abort/stale-reference pause in that code will hang this call indefinitely --
    there is no scriptable way to resume or dismiss the Debugger window (see
    set_debugger_enabled's docstring). This happened for real during development.
    Whenever nobody is watching who could close that popup manually, use
    execute_igor_command_unattended instead, which disables the Debugger for the
    duration of the call automatically. Only use this plain version when you
    deliberately want the Debugger available (e.g. interactively testing a
    breakpoint).

    **On failure:** a nonzero error code means at least one unhandled runtime error
    occurred somewhere in `command` -- it does NOT mean execution stopped there, and
    it does NOT mean it was the only problem (see the runtime error model notes
    above `_format_execute2_error`). The raised error includes any partial `results`
    captured, since that's often the only way to tell how far execution actually got.
    """
    errorCode, errorMsg, history, results = _execute2(command)
    if errorCode != 0:
        raise RuntimeError(
            _format_execute2_error(command, errorCode, errorMsg, results, history)
        )
    return results


@mcp.tool()
def get_wave(wave_path: str) -> list:
    """Return the data of an existing 1D Igor wave as a list of numbers or strings.

    wave_path should be an absolute Igor path, e.g. "root:testWave" or
    "root:myFolder:testWave".

    Limitation: only 1D, real (non-complex) waves are supported. Multi-dimensional or
    complex waves will raise an error.

    Every COM call below is individually reconnect-protected (DataFolder/Wave/
    GetDimensions as one unit via _run_with_reconnect, then each point read
    separately) rather than only wrapping the function as a whole. The point-level
    wrapping matters for large waves specifically: if the connection drops on point
    4000 of 5000, this resumes from point 4000 after reconnecting instead of
    re-fetching the wave and re-reading points 0-3999 again.
    """
    def get_dims():
        return _get_wave_ref(wave_path).GetDimensions()

    dataType, numRows, numCols, numLayers, numChunks = _run_with_reconnect(get_dims)

    if numCols or numLayers or numChunks:
        raise RuntimeError(
            f"{wave_path} is not 1D (dims: rows={numRows}, cols={numCols}, "
            f"layers={numLayers}, chunks={numChunks}) -- only 1D waves are supported."
        )
    if dataType & IP_DATATYPE_COMPLEX_FLAG:
        raise RuntimeError(f"{wave_path} is complex-valued -- not supported yet.")

    is_text = dataType == IP_DATATYPE_TEXT
    wave = _get_wave_ref(wave_path)
    values = []
    for i in range(numRows):
        try:
            values.append(_read_wave_point(wave, i, is_text))
        except pywintypes.com_error:
            _get_igor(force_reconnect=True)
            wave = _get_wave_ref(wave_path)
            values.append(_read_wave_point(wave, i, is_text))
    return values


@mcp.tool()
def check_bridge_health() -> dict:
    """Check whether the Igor Pro bridge is actually able to reach Igor Pro right now,
    and report exactly which requirement is unmet if not.

    Call this first whenever a command fails or behaves unexpectedly. This session's
    own debugging hit three distinct failure modes that all needed different fixes:
    (1) this Python process not running elevated, (2) no Igor Pro COM object
    registered at all (Igor not running), and (3) a registered-but-dead COM object
    (Igor crashed/was force-closed, leaving a stale registration that reconnecting
    alone can't fix -- Igor itself needs relaunching). This check distinguishes all
    three rather than surfacing one generic failure.

    Returns a dict with at least a "status" key ("OK" or "FAIL") and, on FAIL, a
    "problem" key with a specific, actionable description.
    """
    report = {"python_process_elevated": _is_current_process_elevated()}

    if report["python_process_elevated"] is False:
        report["status"] = "FAIL"
        report["problem"] = (
            "This Python process is not running elevated (as Administrator). Igor "
            "Pro's COM Automation Server requires both Igor Pro and this process to "
            "be elevated. Relaunch Claude Desktop specifically via 'Run as "
            "administrator' -- reopening it normally does not preserve elevation -- "
            "then retry."
        )
        return report

    try:
        _get_igor()
    except RuntimeError as e:
        report["status"] = "FAIL"
        report["problem"] = (
            f"No running Igor Pro instance found via COM ({e}). Make sure Igor Pro 10 "
            "or later is open and running elevated."
        )
        return report

    def try_call():
        igor = _get_igor()
        return igor.Execute2(0, 0, 'fprintf 0, "%s", IgorInfo(1)')

    try:
        errorCode, errorMsg, history, results = try_call()
        report["reconnect_was_needed"] = False
    except pywintypes.com_error:
        report["reconnect_was_needed"] = True
        try:
            _get_igor(force_reconnect=True)
            errorCode, errorMsg, history, results = try_call()
        except pywintypes.com_error as e2:
            report["status"] = "FAIL"
            report["problem"] = (
                f"Found a registered Igor Pro COM object, but calls to it fail with a "
                f"COM/RPC-transport error even after reconnecting ({e2}). This means a "
                "stale/dead COM registration, most likely because Igor Pro crashed or "
                "was force-closed previously. Check Task Manager for Igor64.exe -- "
                "there should be exactly one -- fully close it, and relaunch Igor Pro "
                "fresh, as Administrator."
            )
            return report

    if errorCode != 0:
        report["status"] = "FAIL"
        report["problem"] = f"Igor-level command failed (code {errorCode}): {errorMsg}"
        return report

    report["status"] = "OK"
    report["igor_info"] = results
    return report


# Confirmed against a live Igor Pro instance during development: this is exactly the
# method used by IsProcGlobalCompiled() in
# Packages/igortest/procedures/igortest-test-compilation.ipf. FunctionInfo() for a
# deliberately non-existing function returns an empty string when procedure code is
# compiled, and a non-empty string (observed: "Procedures Not Compiled") when it is
# not. The expression is inlined directly into the fprintf call (no intermediate
# variable) deliberately: an earlier version assigned to a local first, but Igor's
# command line persists local variables across separate command-line invocations, so
# a *second* call declaring the same variable name again failed with "the name
# already exists as a variable" -- confirmed empirically. Inlining the expression
# sidesteps that entirely, since there is no variable to persist or collide with.
_PROCEDURES_COMPILED_CHECK_CMD = (
    'fprintf 0, "%s", FunctionInfo("ProcGlobal#NON_EXISTING_FUNCTION")'
)


@mcp.tool()
def check_compilation_state() -> dict:
    """Check whether Igor Pro's procedure code is currently compiled or uncompiled.

    Functions from procedure code can only be called while compiled. Igor Pro enters
    the uncompiled state when procedure code is edited inside Igor (only possible
    while nothing is running), or when nothing is running and an included procedure
    file changed on disk. Use reload_and_compile_procedures to get back to compiled
    after editing a .ipf file on disk.
    """
    errorCode, errorMsg, history, results = _execute2(_PROCEDURES_COMPILED_CHECK_CMD)
    if errorCode != 0:
        raise RuntimeError(
            f"Could not check compilation state (error code {errorCode}): {errorMsg}"
        )
    return {"compiled": results == "", "raw_function_info": results}


_COMPILE_POLL_INTERVAL_SECONDS = 0.2
_COMPILE_POLL_TIMEOUT_SECONDS = 5.0
# Number of consecutive "compiled" reads required before trusting the FunctionInfo-based
# fallback signal -- see the false-positive race explained in
# reload_and_compile_procedures's docstring. Not needed for the AfterCompiledHook-based
# counter signal, which is race-free by construction (see _read_claude_helper_compile_counter).
_COMPILE_CONFIRM_CHECKS = 2

# MIES_ClaudeHelper.ipf's AfterCompiledHook (gated behind #ifdef IGOR_PRO_BRIDGE -- see
# SESSION_NOTES.md) increments root:gClaudeHelperCompileCounter every time Igor calls it,
# which only happens once ALL procedure windows have genuinely compiled successfully
# (confirmed from Igor Pro Folder/Igor Help Files/Advanced Topics.ihf). Unlike the
# FunctionInfo-based poll below, there is no staleness/race concern reading this: the
# counter only ever changes at the exact moment Igor itself confirms a successful
# compile, so any observed increase over a baseline is unconditionally trustworthy, no
# repeated-confirmation dance required. NumVarOrDefault's own -1 default is used as the
# "unavailable" sentinel (a real counter value can never be negative), which handles two
# unavailability cases identically: IGOR_PRO_BRIDGE not defined for this experiment (the
# hook doesn't exist at all), or MIES_ClaudeHelper.ipf not included in the first place --
# this bridge has to keep working either way, so the counter is only ever an optional
# extra confirmation, never a requirement.
_CLAUDE_HELPER_COMPILE_COUNTER_CMD = (
    'fprintf 0, "%g", NumVarOrDefault("root:gClaudeHelperCompileCounter", -1)'
)


def _read_claude_helper_compile_counter():
    """Read root:gClaudeHelperCompileCounter, or None if it's unavailable for any reason
    (COM/Igor-level error, or the sentinel -1 meaning the variable doesn't exist -- see
    the constant's comment above for why both are treated as simply "unavailable", never
    fatal)."""
    errorCode, errorMsg, history, results = _execute2(_CLAUDE_HELPER_COMPILE_COUNTER_CMD)
    if errorCode != 0:
        return None
    try:
        value = float(results)
    except (TypeError, ValueError):
        return None
    return None if value < 0 else value

_COMPILE_ERROR_DIALOG_NOTE = (
    "One confirmed cause if this is unexpected (e.g. you just fixed a known syntax "
    "error and expected this to succeed): a compile-error dialog left open in Igor "
    "from a PREVIOUS failed attempt blocks Igor's operation queue from ever draining "
    "-- confirmed from Igor Pro Folder/Igor Help Files/Advanced Topics.ihf, "
    "'Operation Queue' section: 'Igor services the operation queue when no "
    "procedures are running and the command line is empty.' A modal dialog means "
    "Igor is never idle, so RELOAD CHANGED PROCS/COMPILEPROCEDURES queued by a later "
    "call sit there without ever actually running, even though this bridge's own COM "
    "calls keep responding normally throughout (confirmed empirically: this hang "
    "does not show up as a hung tool call, only as 'compiled' staying stuck at False "
    "no matter how many times this is retried). There is no documented way to "
    "detect or dismiss that dialog via COM. "
    "ACTION FOR WHATEVER IS CALLING THIS TOOL: do not just log this and retry silently "
    "-- explicitly ask the human operator right now whether a compile-error dialog is "
    "showing in Igor Pro, and if so, to close it, before retrying. This was confirmed "
    "during development to be the only thing that reliably un-sticks this state -- "
    "passively worded advice in a note is easy to skip past; an explicit prompt to the "
    "human is what actually keeps an unattended/agent-driven workflow moving."
)


@mcp.tool()
def reload_and_compile_procedures() -> dict:
    """Force Igor Pro to reload procedure code from the .ipf files on disk and attempt
    a fresh compilation, then report whether it ended up compiled.

    Use this after editing a .ipf file directly on disk -- the correct way to change
    MIES/Igor procedure code -- to make Igor pick up the change. Only call this while
    Igor Pro is not currently running other procedure code; reloading/compiling while
    code is running is not supported.

    Mirrors the exact method used by CompileAndRestart() in igortest-tracing.ipf:

        Execute/P "RELOAD CHANGED PROCS "
        Execute/P "COMPILEPROCEDURES "

    Both commands go through Igor's operation queue, not immediate execution --
    confirmed from Igor Pro Folder/Igor Help Files/Advanced Topics.ihf, "Operation
    Queue" section (COMPILEPROCEDURES and RELOAD CHANGED PROCS are documented there;
    neither has its own entry in the main Igor Reference): "Igor services the
    operation queue when no procedures are running and the command line is empty. If
    the operation queue is not empty, Igor then executes the oldest command in the
    queue." /P only appends to that queue -- it does NOT guarantee either command has
    actually run by the time this function starts checking, only that Igor will get
    to it once genuinely idle.

    Because of that, a single immediate compiled-state check was observed (against a
    live Igor Pro instance) to occasionally report "compiled: true" on the very
    first read even though the queue had not drained yet -- a false positive, reading
    stale pre-reload state rather than the real post-compile result -- as well as the
    opposite false negative (briefly still "not compiled" right after a compile that
    actually succeeded). To guard against both, this checks two independent signals on
    every poll (every 0.2s, up to 5s total):

    1. root:gClaudeHelperCompileCounter, incremented by MIES_ClaudeHelper.ipf's
       AfterCompiledHook (see _read_claude_helper_compile_counter) -- authoritative and
       race-free when available (requires #define IGOR_PRO_BRIDGE in the experiment's
       Procedure window), since it only changes at the exact moment Igor itself confirms
       a successful compile. Any increase over the baseline read before issuing RELOAD/
       COMPILE is trusted immediately, no repeated confirmation needed.
    2. The original FunctionInfo-based check_compilation_state poll, kept as a fallback
       for when the counter is unavailable (IGOR_PRO_BRIDGE not defined, or
       MIES_ClaudeHelper.ipf not included at all) -- still requires
       _COMPILE_CONFIRM_CHECKS consecutive "compiled" reads in a row before trusting it,
       since this signal alone doesn't rule out the staleness race described above.

    If neither signal confirms compilation after the full 5s, that's a much stronger
    signal of a genuine compile error -- check Igor's history/procedure window
    directly. See _COMPILE_ERROR_DIALOG_NOTE for one confirmed, concrete cause: a
    compile-error dialog left open from an earlier failed attempt blocks the
    operation queue from ever draining, so this will keep reporting "not compiled"
    even after the underlying .ipf file is genuinely fixed, until a person closes
    that dialog by hand. This happened for real during development.

    **If the returned dict has "prompt_user_to_check_for_dialog": True, whatever is
    calling this tool should explicitly ask the human operator to check Igor Pro's
    screen for a stuck compile-error dialog and close it, before retrying** -- not
    just read the accompanying "note" text and move on. Confirmed directly during
    development: silently retrying or only logging the note left the workflow stuck;
    explicitly prompting the human at this point is what actually un-stuck it.
    """
    baseline_counter = _read_claude_helper_compile_counter()

    errorCode, errorMsg, history, results = _execute2('Execute/P "RELOAD CHANGED PROCS "')
    if errorCode != 0:
        raise RuntimeError(
            f"RELOAD CHANGED PROCS failed (error code {errorCode}): {errorMsg}"
        )

    errorCode, errorMsg, history, results = _execute2('Execute/P "COMPILEPROCEDURES "')
    if errorCode != 0:
        raise RuntimeError(
            f"COMPILEPROCEDURES failed (error code {errorCode}): {errorMsg}"
        )

    deadline = time.monotonic() + _COMPILE_POLL_TIMEOUT_SECONDS
    lastErrorCode = None
    lastErrorMsg = None
    lastResults = None
    attempts = 0
    consecutive_compiled = 0

    while True:
        attempts += 1

        current_counter = _read_claude_helper_compile_counter()
        if (
            baseline_counter is not None
            and current_counter is not None
            and current_counter > baseline_counter
        ):
            return {
                "reload_triggered": True,
                "compile_triggered": True,
                "compiled": True,
                "poll_attempts": attempts,
                "confirmed_via": "AfterCompiledHook counter (root:gClaudeHelperCompileCounter)",
            }

        compiledErrorCode, compiledErrorMsg, _, compiledResults = _execute2(
            _PROCEDURES_COMPILED_CHECK_CMD
        )
        if compiledErrorCode == 0:
            lastErrorCode = None
            lastResults = compiledResults
            if compiledResults == "":
                consecutive_compiled += 1
                if consecutive_compiled >= _COMPILE_CONFIRM_CHECKS:
                    return {
                        "reload_triggered": True,
                        "compile_triggered": True,
                        "compiled": True,
                        "poll_attempts": attempts,
                        "confirmed_via": (
                            "FunctionInfo poll (AfterCompiledHook counter unavailable "
                            "or unchanged)"
                        ),
                    }
            else:
                consecutive_compiled = 0
        else:
            lastErrorCode, lastErrorMsg = compiledErrorCode, compiledErrorMsg
            consecutive_compiled = 0

        if time.monotonic() >= deadline:
            break
        time.sleep(_COMPILE_POLL_INTERVAL_SECONDS)

    if lastErrorCode is not None:
        return {
            "reload_triggered": True,
            "compile_triggered": True,
            "compiled_state_known": False,
            "poll_attempts": attempts,
            "prompt_user_to_check_for_dialog": True,
            "note": (
                f"Reload/compile commands ran, but checking the resulting state kept "
                f"failing (last error code {lastErrorCode}): {lastErrorMsg}. "
                + _COMPILE_ERROR_DIALOG_NOTE
            ),
        }

    return {
        "reload_triggered": True,
        "compile_triggered": True,
        "compiled": False,
        "poll_attempts": attempts,
        "raw_function_info": lastResults,
        "prompt_user_to_check_for_dialog": True,
        "note": (
            f"Still not compiled after polling for {_COMPILE_POLL_TIMEOUT_SECONDS:.0f}s "
            f"(requiring {_COMPILE_CONFIRM_CHECKS} consecutive confirmations). This is "
            "more likely a genuine compile error in the procedure code than a timing "
            "artifact -- check Igor's history/procedure window directly. "
            + _COMPILE_ERROR_DIALOG_NOTE
        ),
    }


# --- Debugger control ---------------------------------------------------------------
#
# Confirmed against a live Igor Pro instance during development, and against Igor
# Reference.ihf / Debugging.ihf directly (not guessed):
#
# - DebuggerOptions [enable=en, debugOnAbort=doa, debugOnError=doe,
#   NVAR_SVAR_WAVE_Checking=nvwc] is the only operation that changes debugger settings.
#   All parameters are optional; calling it with none just (re)sets its V_enable /
#   V_debugOnError / V_debugOnAbort / V_NVAR_SVAR_WAVE_Checking output variables to the
#   current state without changing anything -- confirmed verbatim from the docs: "All
#   parameters are optional. If none are specified, no action is taken, but the output
#   variables are still set." Multiple keyword arguments are comma-separated, confirmed
#   from a real doc example: "DebuggerOptions enable=1, debugOnError=1".
# - "If the debugger is disabled then the other settings are cleared even if other
#   settings are on" (verbatim from the docs) -- so enable=0 always clears everything.
# - **Why this matters for unattended/automated use, confirmed empirically this
#   session**: there is no scriptable/COM way to resume, step, or dismiss the Debugger
#   window once something pauses it (no such operation exists in Igor Reference.ihf,
#   and the Debugger panel itself doesn't even show up as a window in
#   WinList("*", ";", "WIN:65535")). If a breakpoint, a runtime error (debugOnError),
#   a user abort (debugOnAbort), or a stale NVAR/SVAR/WAVE reference
#   (NVAR_SVAR_WAVE_Checking) trips the debugger during an automated run, the specific
#   COM call that triggered it hangs forever -- Execute2 is synchronous, and only a
#   human clicking "Go" in the Debugger window can unblock it. (Other new COM calls
#   still get answered while paused, since Igor's command line stays reentrant -- but
#   the original call, and anything waiting on it, is stuck for good.) So: the debugger
#   must be disabled before any unattended/automated session.
# - **This is not hypothetical -- it happened during development of this bridge**: a
#   plain execute_igor_command call ran a test function while the Debugger was still
#   enabled from earlier interactive use, Igor paused with the Debugger window open,
#   and the call hung until a person closed the window by hand. That's exactly why
#   execute_igor_command_unattended exists below: it disables the Debugger, runs the
#   command, and restores the Debugger afterward automatically (in a try/finally, so
#   it restores even if the command errors), rather than depending on whoever/whatever
#   is calling this bridge to remember the manual get_debugger_state() /
#   set_debugger_enabled(False) / restore_debugger_settings() dance every time. Use
#   execute_igor_command_unattended by default for anything that might call
#   user-defined procedure code unattended; reach for plain execute_igor_command only
#   when a Debugger pause is deliberately wanted (e.g. interactively testing a
#   breakpoint).

_DEBUGGER_STATE_CHECK_CMD = (
    'DebuggerOptions; fprintf 0, "enable=%d,debugOnError=%d,debugOnAbort=%d,'
    'NVAR_SVAR_WAVE_Checking=%d", V_enable, V_debugOnError, V_debugOnAbort, '
    "V_NVAR_SVAR_WAVE_Checking"
)

# Snapshot captured by get_debugger_state(), consumed by restore_debugger_settings().
# Process-lifetime state is fine here: one bridge process serves one Claude Desktop
# session, and this is meant to bracket exactly one unattended run within that.
_saved_debugger_settings = None


def _read_debugger_options() -> dict:
    """Read the four DebuggerOptions settings without changing them. Returns
    {"enable": bool, "debug_on_error": bool, "debug_on_abort": bool,
    "nvar_svar_wave_checking": bool}."""
    errorCode, errorMsg, history, results = _execute2(_DEBUGGER_STATE_CHECK_CMD)
    if errorCode != 0:
        raise RuntimeError(
            f"Could not read Debugger settings (error code {errorCode}): "
            f"{errorMsg or '(no error message)'}"
        )
    values = {}
    for pair in results.split(","):
        key, _, value = pair.partition("=")
        values[key] = value
    return {
        "enable": values.get("enable") == "1",
        "debug_on_error": values.get("debugOnError") == "1",
        "debug_on_abort": values.get("debugOnAbort") == "1",
        "nvar_svar_wave_checking": values.get("NVAR_SVAR_WAVE_Checking") == "1",
    }


def _apply_debugger_options(state: dict):
    """Issue a DebuggerOptions command that sets all four settings to `state`
    (enable/debug_on_error/debug_on_abort/nvar_svar_wave_checking), used by both
    set_debugger_enabled and restore_debugger_settings so they can't drift apart."""
    parts = [f"enable={1 if state['enable'] else 0}"]
    if state["enable"]:
        parts.append(f"debugOnError={1 if state['debug_on_error'] else 0}")
        parts.append(f"debugOnAbort={1 if state['debug_on_abort'] else 0}")
        parts.append(
            f"NVAR_SVAR_WAVE_Checking={1 if state['nvar_svar_wave_checking'] else 0}"
        )
    cmd = "DebuggerOptions " + ", ".join(parts)

    errorCode, errorMsg, history, results = _execute2(cmd)
    if errorCode != 0:
        raise RuntimeError(
            f"Could not set Debugger settings (error code {errorCode}): "
            f"{errorMsg or '(no error message)'}\nCommand was: {cmd}"
        )


@mcp.tool()
def get_debugger_state() -> dict:
    """Read Igor Pro's current Debugger settings (enable, debugOnError, debugOnAbort,
    NVAR_SVAR_WAVE_Checking) without changing them, and save a snapshot inside this
    bridge process for restore_debugger_settings to restore later.

    **Call this before starting any unattended/automated session**, immediately before
    calling set_debugger_enabled(False) to actually turn the debugger off. See
    set_debugger_enabled's docstring for why the debugger must be off for unattended
    execution -- a pause it causes cannot be resumed or dismissed remotely.
    """
    global _saved_debugger_settings
    state = _read_debugger_options()
    _saved_debugger_settings = dict(state)
    return state


@mcp.tool()
def set_debugger_enabled(
    enabled: bool,
    debug_on_error: bool = None,
    debug_on_abort: bool = None,
    nvar_svar_wave_checking: bool = None,
) -> dict:
    """Turn Igor Pro's Debugger on or off (and optionally its debugOnError/
    debugOnAbort/NVAR_SVAR_WAVE_Checking sub-settings), via DebuggerOptions.

    **For any unattended/automated session -- running tests, scripted builds, anything
    without a person watching -- the debugger MUST be disabled: call
    set_debugger_enabled(False) before starting.** Confirmed empirically this session:
    there is no scriptable/COM way to resume, step, or dismiss the Debugger window once
    something pauses it (no such operation is documented in Igor Reference.ihf, and the
    Debugger panel doesn't even appear as a window in WinList). If a breakpoint, a
    runtime error (debugOnError), a user abort (debugOnAbort), or a stale NVAR/SVAR/WAVE
    reference (NVAR_SVAR_WAVE_Checking) trips the debugger mid-run, the specific COM
    call that triggered it hangs forever -- Execute2 is synchronous, and only a human
    clicking "Go" in the Debugger window can unblock it. Other new COM calls still get
    answered while paused (Igor's command line stays reentrant), but the original call,
    and anything waiting on it, is stuck for good.

    enabled=False clears all four settings regardless of the other arguments -- this is
    Igor's own documented behavior ("If the debugger is disabled then the other
    settings are cleared even if other settings are on"), not a limitation of this
    function -- so debug_on_error/debug_on_abort/nvar_svar_wave_checking are only
    applied when enabled=True.

    Recommended pattern around an unattended session:
        get_debugger_state()           # read + save the current settings
        set_debugger_enabled(False)    # disable for the unattended run
        ... run the unattended session ...
        restore_debugger_settings()    # put the saved settings back
    """
    _apply_debugger_options(
        {
            "enable": enabled,
            "debug_on_error": bool(debug_on_error),
            "debug_on_abort": bool(debug_on_abort),
            "nvar_svar_wave_checking": bool(nvar_svar_wave_checking),
        }
    )
    return _read_debugger_options()


@mcp.tool()
def restore_debugger_settings() -> dict:
    """Restore Igor Pro's Debugger settings to whatever get_debugger_state last
    captured.

    **Call this when an unattended/automated session ends**, to put the debugger back
    the way it was before set_debugger_enabled(False) turned it off for the run.

    Raises if get_debugger_state was never called in this bridge process (nothing has
    been saved to restore).
    """
    if _saved_debugger_settings is None:
        raise RuntimeError(
            "No saved Debugger settings to restore -- call get_debugger_state() "
            "before starting the unattended session so there is something to restore "
            "afterward."
        )
    _apply_debugger_options(_saved_debugger_settings)
    return _read_debugger_options()


@mcp.tool()
def execute_igor_command_unattended(command: str) -> str:
    """Run `command` exactly like execute_igor_command, but automatically disable
    Igor's Debugger before running it and restore it again afterward -- even if
    `command` raises an Igor-level error. Uses its own local snapshot rather than the
    get_debugger_state/restore_debugger_settings pair, so it's self-contained and
    won't clash with a separate manual bracket around a longer session.

    **This is the tool to reach for whenever `command` might call user-defined
    procedure code (e.g. any MIES or test function) and nothing is watching that could
    close a Debugger popup by hand.** It exists because of a concrete failure hit
    during development of this bridge: a plain execute_igor_command call ran a test
    function while the Debugger was still enabled from earlier interactive use; Igor
    Pro paused with the Debugger window open, and the call hung until a person closed
    it manually -- there is no scriptable way to resume or dismiss a Debugger pause
    (see set_debugger_enabled's docstring for the full explanation of why). Wrapping
    the call so the Debugger is guaranteed off first removes that failure mode
    entirely, instead of relying on remembering to call set_debugger_enabled(False)
    beforehand every time.

    Only reach for plain execute_igor_command when you deliberately want the Debugger
    available -- e.g. interactively testing a breakpoint, as done earlier in this
    bridge's own development.

    For a longer unattended session made of many calls, prefer bracketing the whole
    session with get_debugger_state() / set_debugger_enabled(False) once at the start
    and restore_debugger_settings() once at the end, rather than paying the extra
    disable/restore COM round-trip on every single command via this tool.

    **On failure:** a nonzero error code means at least one unhandled runtime error
    occurred somewhere in `command` -- it does NOT mean execution stopped there, and
    it does NOT mean it was the only problem (see the runtime error model notes
    above _format_execute2_error, right before execute_igor_command). The raised
    error includes any partial `results` captured, since that's often the only way
    to tell how far execution actually got.
    """
    saved = _read_debugger_options()
    _apply_debugger_options(
        {
            "enable": False,
            "debug_on_error": False,
            "debug_on_abort": False,
            "nvar_svar_wave_checking": False,
        }
    )
    try:
        errorCode, errorMsg, history, results = _execute2(command)
    finally:
        _apply_debugger_options(saved)

    if errorCode != 0:
        raise RuntimeError(
            _format_execute2_error(command, errorCode, errorMsg, results, history)
        )
    return results


# --- Environment summary -----------------------------------------------------------
#
# Confirmed against a live Igor Pro instance during development (Igor Pro 10.03, build
# 30115). These are ordinary Igor built-in functions -- not part of the COM Automation
# Server API itself -- run the same way as any other command, via _execute2/fprintf:
#
# - IgorInfo(n) for n in 0-18 (n outside that range raises an Igor-level error, e.g.
#   "expected value between 0 and 18"). The indices used below were identified
#   empirically by probing all valid values against a live instance and matching each
#   returned string to its evident meaning -- there is no single confirmed index for
#   "the experiment's name", for example, so this was found by inspection, not assumed:
#     IgorInfo(0)  -- system report string (IGORVERS/BUILD/COMMIT/memory/screen info)
#     IgorInfo(3)  -- OS name/version/locale string
#     IgorInfo(10) -- semicolon-separated list of loaded XOPs
#     IgorInfo(11) -- experiment file kind (e.g. "Packed")
#     IgorInfo(12) -- experiment file name (e.g. "Basic.pxp")
# - WinList("*", ";", "WIN:128") -- lists currently included procedure windows/files.
#   The "128" bit was confirmed empirically (tested directly against a live instance,
#   not looked up in documentation) to mean "procedure windows"; it reliably returns a
#   complete, sensible-looking list of every included .ipf plus the special "Procedure"
#   window (see below).
# - ProcedureText(macroOrFunctionNameStr, flags, winTitleStr) -- retrieves procedure
#   text. IMPORTANT, confirmed the hard way this session: to get the *entire contents*
#   of a named procedure window, the window name goes in winTitleStr (the third
#   argument), with macroOrFunctionNameStr left as "" -- i.e.
#   ProcedureText("", 0, "Procedure"), NOT ProcedureText("Procedure", 0, ""). The first
#   argument instead names one specific macro/function *within* a window; passing a
#   window name there matches nothing and silently returns "" rather than raising an
#   error, which produced an incorrect "the Procedure window is empty" result during
#   development until the user caught and corrected it.
# - The always-present "Procedure" window matters because Igor experiments (.pxp) can
#   carry additional #include/#define directives there beyond what's in any on-disk
#   .ipf file in the repo -- e.g. this project's experiments were found to #include
#   ":UTF_Basic" and #define AUTOMATED_TESTING directly in that window. So the live
#   in-memory environment is experiment-dependent, not fully determined by the repo
#   file system alone.
# - DataFolderDir(3) -- returns "FOLDERS:name1,name2,...;WAVES:name1,name2,...;"
#   (bitmask 3 = folders + waves) for the current data folder; confirmed empirically
#   against root: to list top-level data folders and top-level waves.

_ENV_SUMMARY_COMMANDS = {
    "igor_version_info": 'fprintf 0, "%s", IgorInfo(0)',
    "os_info": 'fprintf 0, "%s", IgorInfo(3)',
    "loaded_xops_raw": 'fprintf 0, "%s", IgorInfo(10)',
    "experiment_file_kind": 'fprintf 0, "%s", IgorInfo(11)',
    "experiment_file_name": 'fprintf 0, "%s", IgorInfo(12)',
    "included_procedure_windows_raw": 'fprintf 0, "%s", WinList("*", ";", "WIN:128")',
    "data_folders_raw": 'fprintf 0, "%s", DataFolderDir(3)',
    "procedure_window_text": 'fprintf 0, "%s", ProcedureText("", 0, "Procedure")',
}


def _categorize_procedure_file(name: str) -> str:
    """Bucket an included procedure file name into a coarse category, purely to make a
    ~250-entry file list skimmable in a summary. Buckets reflect this specific repo's
    naming conventions (MIES_*, UTF_* unit tests, igortest-* test framework, IPNWB_*),
    not a general Igor Pro convention."""
    if name.startswith("igortest"):
        return "igortest_framework"
    if name.startswith("UTF_"):
        return "unit_tests"
    if name.startswith("IPNWB"):
        return "ipnwb"
    if name.startswith("MIES_"):
        return "mies_production"
    return "other"


@mcp.tool()
def get_environment_summary() -> dict:
    """Summarize the current Igor Pro instance's live environment: Igor version, the
    loaded experiment, loaded external operations (XOPs), which procedure files are
    actually included right now, the contents of the always-present "Procedure" window
    (which can carry experiment-specific #include/#define directives not present in any
    on-disk .ipf file), and the top-level global data folder layout.

    This queries the live instance directly rather than assuming the repo's file system
    determines what's loaded -- which experiment (.pxp) is open changes all of this.

    Returns a dict with:
      - igor_version_info: raw IgorInfo(0) string (version/build/commit/memory/screen)
      - os_info: raw IgorInfo(3) string (OS name/version/locale)
      - experiment_file_name / experiment_file_kind: e.g. "Basic.pxp" / "Packed"
      - loaded_xops: list of loaded external operations (e.g. NIDAQmx64, itcXOP2-64)
      - procedure_window_text: raw contents of the special "Procedure" window --
        inspect this for experiment-specific #include/#define directives
      - included_procedure_file_count: total number of currently included .ipf files
        (excluding the "Procedure" window entry itself)
      - included_procedure_files_by_category: counts per category (see
        _categorize_procedure_file)
      - included_procedure_files: the full list of currently included .ipf file names
      - data_folders: top-level data folder names under root:
      - top_level_waves: top-level wave names directly under root: (usually empty --
        MIES keeps its data organized into subfolders)
      - debugger_settings: current enable/debugOnError/debugOnAbort/
        NVAR_SVAR_WAVE_Checking state (see _read_debugger_options). If "enable" is
        True here, any unattended/automated session must call
        get_debugger_state() + set_debugger_enabled(False) first -- see
        set_debugger_enabled's docstring for why.
    """
    raw = {}
    for key, cmd in _ENV_SUMMARY_COMMANDS.items():
        errorCode, errorMsg, history, results = _execute2(cmd)
        if errorCode != 0:
            raise RuntimeError(
                f"Could not retrieve '{key}' (error code {errorCode}): "
                f"{errorMsg or '(no error message)'}\nCommand was: {cmd}"
            )
        raw[key] = results

    included_procedure_files = [
        name for name in raw["included_procedure_windows_raw"].split(";") if name
    ]
    included_procedure_files = [
        name for name in included_procedure_files if name != "Procedure"
    ]

    loaded_xops = [x for x in raw["loaded_xops_raw"].split(";") if x]

    folders_part, waves_part = "", ""
    for part in raw["data_folders_raw"].split("\r"):
        part = part.strip()
        if part.startswith("FOLDERS:"):
            folders_part = part[len("FOLDERS:"):].rstrip(";")
        elif part.startswith("WAVES:"):
            waves_part = part[len("WAVES:"):].rstrip(";")
    data_folders = [f for f in folders_part.split(",") if f]
    top_level_waves = [w for w in waves_part.split(",") if w]

    category_counts: dict = {}
    for name in included_procedure_files:
        category = _categorize_procedure_file(name)
        category_counts[category] = category_counts.get(category, 0) + 1

    return {
        "igor_version_info": raw["igor_version_info"],
        "os_info": raw["os_info"],
        "experiment_file_name": raw["experiment_file_name"],
        "experiment_file_kind": raw["experiment_file_kind"],
        "loaded_xops": loaded_xops,
        "procedure_window_text": raw["procedure_window_text"],
        "included_procedure_file_count": len(included_procedure_files),
        "included_procedure_files_by_category": category_counts,
        "included_procedure_files": included_procedure_files,
        "data_folders": data_folders,
        "top_level_waves": top_level_waves,
        "debugger_settings": _read_debugger_options(),
    }


if __name__ == "__main__":
    mcp.run()
