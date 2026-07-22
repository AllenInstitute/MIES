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
import os
import sys
import time

import pywintypes
import win32api
import win32con
import win32com.client
import win32gui
import win32process

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
                "Automation), and (3) Igor Pro 9.00 (or later) is installed with the "
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


# --- Session-wide history capture (verifying print output after the fact) ----------
#
# Confirmed from Igor Reference.ihf: CaptureHistoryStart() is a built-in Igor
# function returning a reference number marking the CURRENT position in the history
# area (the command/history window's text). CaptureHistory(refnum, stopCapturing)
# then returns a string containing everything sent to the history area since that
# reference point -- "Set stopCapturing to zero to retrieve history text captured
# so far. Further calls to CaptureHistory with the same reference number will
# return this text, plus any additional history text added subsequently" (i.e. each
# call returns the FULL accumulated text since the start point, not just a delta,
# so repeated reads are simple and never miss anything in between). This is the
# documented, supported way to read back what Igor printed (via `print`, command
# echoing, etc.) after the fact, rather than only being able to see it live on
# screen or asking a human to look.
#
# A capture is started lazily, once, the first time _execute2 runs in this
# process's lifetime (see _ensure_session_history_capture_started), so
# read_session_history() always has something to report without requiring a
# separate explicit "start" call first -- it covers everything since this bridge
# process first talked to Igor.
_session_history_capture_refnum = None


def _ensure_session_history_capture_started():
    """Start a session-wide CaptureHistoryStart() capture if one isn't already
    running. Deliberately swallows all errors -- this is a best-effort convenience
    feature, and must never break a normal command just because this bookkeeping
    call failed for some reason (e.g. an ancient Igor version without this
    function). Calls igor.Execute2 directly rather than going through _execute2 to
    avoid recursing back into this same function.
    """
    global _session_history_capture_refnum
    if _session_history_capture_refnum is not None:
        return
    try:
        igor = _get_igor()
        errorCode, errorMsg, history, results = igor.Execute2(
            0, 0, 'fprintf 0, "%.0f", CaptureHistoryStart()'
        )
        if errorCode == 0 and results:
            _session_history_capture_refnum = float(results)
    except Exception:
        pass


def _execute2(command: str):
    """Run `command` via Execute2 and return (errorCode, errorMsg, history, results).

    See the calling-convention caveat in the module docstring -- this unpacking is the
    one thing to verify empirically on first real run.
    """
    _ensure_session_history_capture_started()

    def work():
        igor = _get_igor()
        return igor.Execute2(0, 0, command)

    errorCode, errorMsg, history, results = _run_with_reconnect(work)
    return errorCode, errorMsg, history, results


@mcp.tool()
def read_session_history(stop: bool = False) -> dict:
    """Read back everything sent to Igor's history area (print output, command
    echoing, error messages, etc.) since this bridge process first talked to Igor
    -- the reliable way to verify a PAST execute_igor_command/
    execute_igor_command_unattended call's `print` output actually happened,
    without asking a human to look at Igor's screen or needing to have captured
    the per-call `history` field at the time.

    Backed by Igor's built-in CaptureHistoryStart()/CaptureHistory() functions
    (confirmed from Igor Reference.ihf). A capture is started automatically the
    first time any command runs through this bridge in this process's lifetime,
    so this always has something to report. Each call returns the FULL
    accumulated text since that start point, not just what's new since the last
    read -- so calling this repeatedly with stop=False (the default) is always
    safe and simply returns more (growing) text as more commands run in between.

    stop=True stops the capture (no further text will be recorded for it) and
    returns whatever was captured up to that point; a subsequent call to this
    tool (or the next command run through this bridge) then starts a brand-new
    capture automatically, covering only from that point forward -- use this to
    intentionally "reset" what counts as history for a fresh phase of work.

    Raises if no capture is currently active, which should only happen if
    CaptureHistoryStart() itself failed when first attempted (e.g. an
    unexpectedly old Igor version) -- in that case, fall back to reading the
    `history` field returned directly by execute_igor_command/
    execute_igor_command_unattended for that specific call instead.
    """
    global _session_history_capture_refnum
    if _session_history_capture_refnum is None:
        raise RuntimeError(
            "No history capture is currently active in this bridge process. This "
            "starts automatically on first use, so this likely means "
            "CaptureHistoryStart() failed earlier (see server logs) or nothing "
            "has been executed yet -- try running check_bridge_health() first, "
            "then retry this call."
        )

    refnum = _session_history_capture_refnum
    stop_flag = 1 if stop else 0
    cmd = f'fprintf 0, "%s", CaptureHistory({refnum:.0f}, {stop_flag})'
    errorCode, errorMsg, history, results = _execute2(cmd)
    if errorCode != 0:
        raise RuntimeError(
            f"Could not read history capture (error code {errorCode}): "
            f"{errorMsg or '(no error message)'}"
        )

    if stop:
        _session_history_capture_refnum = None

    return {"history_text": results, "capture_stopped": stop}


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
def execute_igor_command(command: str) -> dict:
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

    Returns a dict with:
      - "results": the fprintf output captured, if any (empty string otherwise).
      - "history": any text `command` sent to Igor's history area during this
        specific call -- confirmed from Automation Server.ihf: "history [output] is
        a Basic string. On output it contains any text sent to Igor's history area
        by the commands." This is exactly how to verify a `print` statement inside
        `command` actually ran, without needing a human to look at Igor's screen or
        calling the separate read_session_history tool. (Note: the command itself
        is also normally echoed into history unless Silent 2 is in effect, so this
        may include more than just explicit `print` output.)

    **On failure:** a nonzero error code means at least one unhandled runtime error
    occurred somewhere in `command` -- it does NOT mean execution stopped there, and
    it does NOT mean it was the only problem (see the runtime error model notes
    above `_format_execute2_error`). The raised error includes any partial `results`
    and `history` captured, since that's often the only way to tell how far
    execution actually got.
    """
    errorCode, errorMsg, history, results = _execute2(command)
    if errorCode != 0:
        raise RuntimeError(
            _format_execute2_error(command, errorCode, errorMsg, results, history)
        )
    return {"results": results, "history": history}


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
            f"No running Igor Pro instance found via COM ({e}). Make sure Igor Pro "
            "9.00 or later is open and running elevated."
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
    errorCode, errorMsg, history, results = _execute2(
        _CLAUDE_HELPER_COMPILE_COUNTER_CMD
    )
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
    "no matter how many times this is retried). "
    "reload_and_compile_procedures already attempts an automatic fix for exactly this "
    "case (posting an Escape key press directly to Igor's dialog window, via "
    "dismiss_compile_error_dialog's underlying logic, without needing OS focus/"
    "foreground) before returning this note -- see the 'auto_dismiss_attempted' "
    "field for what that attempt found and did. "
    "ACTION FOR WHATEVER IS CALLING THIS TOOL: if the automatic attempt did not "
    "resolve it (or was not attempted, e.g. because no matching dialog window was "
    "found), do not just log this and retry silently -- explicitly ask "
    "the human operator right now whether a compile-error dialog is showing in Igor "
    "Pro, and if so, to close it, before retrying. Explicitly prompting the human is "
    "what actually keeps an unattended/agent-driven workflow moving when the "
    "automatic attempt isn't enough."
)


# --- Compile-error dialog dismissal (posted Escape key message) ---------------------
#
# Added after a user-proposed mitigation for the compile-error-dialog problem
# documented above: there is still no documented COM operation to detect or dismiss
# that dialog, but Escape closes it, and a simulated key press can be delivered to
# it directly.
#
# **Confirmed live against real Igor Pro instances -- both Igor Pro 10.03 and Igor
# Pro 9.06 (this is no longer a guess for either)**: the original assumption that
# this dialog is an ordinary "#32770" Win32 dialog was WRONG -- Igor Pro's UI (both
# major versions tested) is Qt-based, and the compile-error dialog is a Qt window
# with a version-hash-looking class name (observed on 10.03: "Qt693QWindowIcon";
# not re-checked on 9.06 since title matching alone was already sufficient there).
# Since that class name likely varies across Igor/Qt builds and isn't a stable
# thing to match on, this instead matches on the dialog's window TITLE, which was
# directly observed to be exactly "Function Compilation Error" on BOTH Igor Pro
# 10.03 and 9.06 -- a stable, Igor-chosen string, not a toolkit implementation
# detail, and apparently stable across at least these two major versions. The
# "#32770" class check is kept as a second, OR'd condition (harmless, and covers
# the case of a genuinely native Win32 dialog for some other Igor-raised error).
#
# PostMessage(hwnd, WM_KEYDOWN/WM_KEYUP, VK_ESCAPE, ...) is used rather than a
# hardware-level input simulation so this never needs to steal OS focus/
# foreground from whatever the user is doing. **Confirmed live against a real
# stuck "Function Compilation Error" dialog on BOTH Igor Pro 10.03 and Igor Pro
# 9.06: a POSTED (not real hardware) WM_KEYDOWN/WM_KEYUP for VK_ESCAPE
# successfully closed it in both cases** -- Qt's Windows platform plugin
# intercepts native window messages in its own WndProc regardless of a message's
# origin, so it reacted the same way a real key press would, with no
# foreground/focus change needed. (If a future Igor/Qt version doesn't react the
# same way, the fallback would be a hardware-level simulation --
# SetForegroundWindow + keybd_event/SendInput -- targeted at this same window, at
# the cost of stealing focus.)
#
# Targeting no longer relies on the OS foreground window at all (the very first,
# now-superseded approach): it enumerates all top-level windows and keeps visible
# ones belonging to an Igor Pro process (exe name starting with "igor") that either
# have window class "#32770" or a title matching a known stuck-dialog title (see
# _KNOWN_STUCK_DIALOG_TITLES). If neither ever matches, dismissal safely reports
# "not found" (see "igor_windows_seen" in that result for exactly what windows
# exist, to extend this list further if a new stuck-dialog title shows up).
#
# Trade-off, confirmed to be acceptable by the user who proposed this mitigation:
# this recovers the ability to continue working, but does NOT recover the actual
# compile-error message -- Escape just closes the dialog, it doesn't read it. If the
# exact error text matters, check Igor's procedure window/history directly (or ask a
# human to read the dialog) before this or reload_and_compile_procedures's automatic
# call to it dismisses it.

_IGOR_PROCESS_NAME_PREFIX = "igor"
_DIALOG_WINDOW_CLASS = "#32770"  # standard Windows "Dialog" window class
# Known titles of Igor Pro popups that block the operation queue and are safe to
# dismiss with Escape. Confirmed live against both Igor Pro 10.03 and Igor Pro
# 9.06: the compile-error dialog is titled exactly "Function Compilation Error"
# and is a Qt window, NOT a "#32770" native dialog -- so title matching is the
# primary signal for this one, and it appears stable across major versions.
_KNOWN_STUCK_DIALOG_TITLES = ("Function Compilation Error",)
_POSTED_KEY_GAP_SECONDS = 0.05
_POSTED_KEY_SETTLE_SECONDS = 0.2


def _is_stuck_dialog_window(class_name: str, title: str) -> bool:
    """True if a window looks like one of the known stuck-dialog cases this bridge
    knows how to dismiss -- either the standard Win32 dialog class, or a title
    matching a known Igor popup (see _KNOWN_STUCK_DIALOG_TITLES)."""
    if class_name == _DIALOG_WINDOW_CLASS:
        return True
    return any(known.lower() in title.lower() for known in _KNOWN_STUCK_DIALOG_TITLES)


def _get_process_exe_name(pid: int):
    """Best-effort lookup of the executable file name (e.g. "Igor64.exe") owning
    `pid`, or None if it can't be determined. Returns just the base file name, not
    the full path, so callers can do a simple case-insensitive prefix check."""
    ACCESS = win32con.PROCESS_QUERY_INFORMATION | win32con.PROCESS_VM_READ
    hProcess = None
    try:
        hProcess = win32api.OpenProcess(ACCESS, False, pid)
        path = win32process.GetModuleFileNameEx(hProcess, 0)
        return os.path.basename(path)
    except Exception:
        return None
    finally:
        if hProcess is not None:
            win32api.CloseHandle(hProcess)


def _find_igor_dialog_window():
    """Find a visible top-level window that looks like a known stuck Igor Pro
    dialog (see _is_stuck_dialog_window) and is owned by an Igor Pro process,
    without regard to OS foreground/focus state.

    Returns (hwnd, title, exe_name) for the first match found, or None if no such
    window exists right now. EnumWindows's callback is never made to return False
    (pywin32 raises a spurious error if it does -- the underlying Win32 call reports
    that as a failure even though it just means "the callback asked to stop early"),
    so this always enumerates every top-level window and collects all matches, then
    returns the first one -- windows are typically (though not strictly guaranteed)
    reported in top-to-bottom Z-order, so in the common case of a single dialog this
    is simply that dialog.
    """
    matches = []

    def _callback(hwnd, _extra):
        if win32gui.IsWindowVisible(hwnd):
            title = win32gui.GetWindowText(hwnd)
            class_name = win32gui.GetClassName(hwnd)
            if _is_stuck_dialog_window(class_name, title):
                _, pid = win32process.GetWindowThreadProcessId(hwnd)
                exe_name = _get_process_exe_name(pid)
                if exe_name and exe_name.lower().startswith(_IGOR_PROCESS_NAME_PREFIX):
                    matches.append((hwnd, title, exe_name))
        return True

    win32gui.EnumWindows(_callback, None)
    return matches[0] if matches else None


def _list_igor_top_level_windows() -> list:
    """Diagnostic helper: list EVERY visible top-level window owned by an Igor Pro
    process, regardless of class -- title, class name, and exe name for each.

    Used only when _find_igor_dialog_window() finds no match, to surface what's
    actually there instead of just reporting "not found" with no further
    information -- this is exactly how the compile-error dialog's real title
    ("Function Compilation Error") and class ("Qt693QWindowIcon", a Qt window, NOT
    a native "#32770" dialog) were identified live, without needing a separate
    one-off diagnostic tool. Useful again if some other stuck dialog shows up with
    a title not yet in _KNOWN_STUCK_DIALOG_TITLES.
    """
    windows = []

    def _callback(hwnd, _extra):
        if win32gui.IsWindowVisible(hwnd):
            _, pid = win32process.GetWindowThreadProcessId(hwnd)
            exe_name = _get_process_exe_name(pid)
            if exe_name and exe_name.lower().startswith(_IGOR_PROCESS_NAME_PREFIX):
                windows.append(
                    {
                        "title": win32gui.GetWindowText(hwnd),
                        "class_name": win32gui.GetClassName(hwnd),
                        "process": exe_name,
                    }
                )
        return True

    win32gui.EnumWindows(_callback, None)
    return windows


def _attempt_dismiss_compile_error_dialog() -> dict:
    """Post a simulated Escape key press directly to an Igor Pro dialog window (if
    one can be found), without requiring it to be focused or in the OS foreground.
    Returns a dict describing what was found and whether anything was actually sent
    -- see the module-level comment above this function for the reasoning, the
    unverified assumptions, and the trade-offs.
    """
    found = _find_igor_dialog_window()
    if found is None:
        return {
            "attempted": False,
            "reason": (
                "No visible window matching a known stuck-dialog signature "
                '(class "#32770", or title containing one of '
                f"{_KNOWN_STUCK_DIALOG_TITLES}) owned by an Igor Pro process was "
                "found. Either there is no stuck dialog right now, or it's a kind "
                "not seen before -- see 'igor_windows_seen' below for every "
                "visible window Igor currently owns, to identify it."
            ),
            "igor_windows_seen": _list_igor_top_level_windows(),
        }

    hwnd, window_title, exe_name = found

    try:
        win32api.PostMessage(hwnd, win32con.WM_KEYDOWN, win32con.VK_ESCAPE, 0)
        time.sleep(_POSTED_KEY_GAP_SECONDS)
        win32api.PostMessage(hwnd, win32con.WM_KEYUP, win32con.VK_ESCAPE, 0)
        time.sleep(_POSTED_KEY_SETTLE_SECONDS)
    except Exception as e:
        return {
            "attempted": False,
            "reason": f"Posting the simulated Escape key press failed: {e}",
            "dialog_window_title": window_title,
            "dialog_window_process": exe_name,
        }

    return {
        "attempted": True,
        "dialog_window_title": window_title,
        "dialog_window_process": exe_name,
        "note": (
            "Posted a simulated Escape key press directly to this dialog window "
            "(no OS foreground/focus change was made or needed) -- confirmed live "
            'to close Igor\'s "Function Compilation Error" Qt dialog the same way '
            "a real key press would. This does NOT recover the actual "
            "compile-error message -- it only closes whatever modal dialog was "
            "showing. Follow up with check_compilation_state() or "
            "reload_and_compile_procedures() to see whether this actually "
            "un-stuck anything."
        ),
    }


@mcp.tool()
def dismiss_compile_error_dialog() -> dict:
    """Attempt to close a stuck Igor Pro modal compile-error dialog by posting a
    simulated Escape key press directly to it, WITHOUT recovering the actual error
    message and WITHOUT requiring or changing OS focus/foreground state.

    Use this manually when you suspect Igor Pro has a compile-error dialog open (e.g.
    reload_and_compile_procedures kept reporting "not compiled" even after fixing a
    known syntax error) and want to try clearing it yourself, separately from
    reload_and_compile_procedures's own automatic attempt at the same thing (see its
    docstring -- it already calls this same logic once before giving up and asking a
    human).

    Mechanism: enumerates top-level windows for a visible one, owned by a process
    whose exe name starts with "igor" (e.g. Igor64.exe), that either has window
    class "#32770" (the standard Windows Dialog Box class) OR a title matching a
    known stuck-dialog title. **Confirmed live against both Igor Pro 10.03 and
    Igor Pro 9.06: the compile-error dialog is titled exactly "Function
    Compilation Error" and is a Qt window (class observed as "Qt693QWindowIcon" on
    10.03), NOT a native "#32770" dialog** -- so title matching is what actually
    finds it, on both major versions tested. Once found, this posts
    WM_KEYDOWN/WM_KEYUP for VK_ESCAPE directly to that window via PostMessage,
    without requiring it to be focused or in the foreground.

    **Confirmed live on both Igor Pro 10.03 and Igor Pro 9.06: a POSTED (not real
    hardware) Escape key event is enough to make Qt's Windows platform layer
    close this dialog the same way a real key press would** -- verified against a
    real stuck "Function Compilation Error" dialog on each version, with no
    foreground/focus change needed. If no matching window is found at all (e.g. a
    different, not-yet-seen Igor popup), this reports "attempted": false (safe
    failure) along with "igor_windows_seen": every visible top-level window
    currently owned by an Igor Pro process (title/class/process), so a new stuck
    dialog's real title/class can be identified and added to
    _KNOWN_STUCK_DIALOG_TITLES instead of guessing.

    This works despite Igor Pro's elevated status because this bridge's own process
    is also required to run elevated (see the module docstring) -- Windows blocks
    simulated input from a lower-privilege process reaching a higher-privilege
    window (UIPI), but does not block it between two equally elevated processes.

    **Trade-off: this does not tell you what the error was.** It only clears
    whatever dialog is blocking Igor's operation queue so work can continue. If the
    actual error text matters, check the .ipf file directly or ask a human to read
    the dialog before calling this.
    """
    return _attempt_dismiss_compile_error_dialog()


_COMPILE_POLL_TIMEOUT_AFTER_DISMISS_SECONDS = 3.0


def _poll_for_compile_confirmation(baseline_counter, timeout_seconds: float) -> dict:
    """Poll for up to timeout_seconds for confirmation that Igor Pro's procedure code
    compiled successfully, checking both signals described in
    reload_and_compile_procedures's docstring. Returns one of:

    - {"compiled": True, "poll_attempts": N, "confirmed_via": "..."}
    - {"compiled": False, "compiled_state_known": False, "poll_attempts": N,
       "last_error_code": ..., "last_error_msg": ...} -- the compiled-state check
      itself kept failing throughout the poll.
    - {"compiled": False, "poll_attempts": N, "raw_function_info": ...} -- the
      compiled-state check succeeded but never confirmed a compile within the
      timeout.

    Factored out of reload_and_compile_procedures so it can be called a second time,
    with a shorter timeout, after an automatic compile-error-dialog dismissal
    attempt, without duplicating the polling logic.
    """
    deadline = time.monotonic() + timeout_seconds
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
            "compiled": False,
            "compiled_state_known": False,
            "poll_attempts": attempts,
            "last_error_code": lastErrorCode,
            "last_error_msg": lastErrorMsg,
        }

    return {
        "compiled": False,
        "poll_attempts": attempts,
        "raw_function_info": lastResults,
    }


@mcp.tool()
def reload_and_compile_procedures() -> dict:
    """Force Igor Pro to reload procedure code from the .ipf files on disk and attempt
    a fresh compilation, then report whether it ended up compiled.

    Use this after editing a .ipf file directly on disk -- the correct way to change
    MIES/Igor procedure code -- to make Igor pick up the change. Only call this while
    Igor Pro is not currently running other procedure code; reloading/compiling while
    code is running is not supported.

    **Caution, observed twice during this bridge's development against a real Igor
    Pro 10.03 instance**: Igor Pro became unreachable via COM (crashed or was
    closed) shortly after a reload/compile attempt, in two separate incidents --
    once with broken procedure code present, once immediately after fixing it. No
    root cause has been confirmed (no Windows crash logs were accessible from
    here), and it's not established whether this bridge's own actions are involved
    at all versus a pre-existing Igor Pro stability issue independent of it. If a
    tool call after this one starts failing with a COM/RPC error, check
    check_bridge_health() and be prepared for Igor Pro to need relaunching.

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

    Before giving up, if compilation isn't confirmed within the initial timeout, this
    automatically makes ONE attempt to dismiss a possible stuck compile-error dialog
    by posting an Escape key press directly to it (see dismiss_compile_error_dialog),
    then polls again briefly. This does not require or change OS focus/foreground
    state; it only fires if a matching Igor Pro dialog window can actually be found
    -- see dismiss_compile_error_dialog's docstring for the full mechanism and its
    trade-off (it recovers the ability to continue, not the error message). The
    returned dict's "auto_dismiss_attempted" field always reports what that attempt
    found/did, even when it wasn't needed or no matching window was found.

    **If the returned dict has "prompt_user_to_check_for_dialog": True, whatever is
    calling this tool should explicitly ask the human operator to check Igor Pro's
    screen for a stuck compile-error dialog and close it, before retrying** -- not
    just read the accompanying "note" text and move on. This only happens after the
    automatic dismissal attempt above has already been tried and didn't resolve it
    (or wasn't possible, e.g. no matching dialog window was found).
    Confirmed directly during development: silently retrying or only logging the
    note left the workflow stuck; explicitly prompting the human at this point is
    what actually un-stuck it.
    """
    baseline_counter = _read_claude_helper_compile_counter()

    errorCode, errorMsg, history, results = _execute2(
        'Execute/P "RELOAD CHANGED PROCS "'
    )
    if errorCode != 0:
        raise RuntimeError(
            f"RELOAD CHANGED PROCS failed (error code {errorCode}): {errorMsg}"
        )

    errorCode, errorMsg, history, results = _execute2('Execute/P "COMPILEPROCEDURES "')
    if errorCode != 0:
        raise RuntimeError(
            f"COMPILEPROCEDURES failed (error code {errorCode}): {errorMsg}"
        )

    poll_result = _poll_for_compile_confirmation(
        baseline_counter, _COMPILE_POLL_TIMEOUT_SECONDS
    )
    if poll_result["compiled"]:
        return {"reload_triggered": True, "compile_triggered": True, **poll_result}

    dismiss_result = _attempt_dismiss_compile_error_dialog()

    if dismiss_result.get("attempted"):
        poll_result = _poll_for_compile_confirmation(
            baseline_counter, _COMPILE_POLL_TIMEOUT_AFTER_DISMISS_SECONDS
        )
        if poll_result["compiled"]:
            return {
                "reload_triggered": True,
                "compile_triggered": True,
                **poll_result,
                "auto_dismiss_attempted": dismiss_result,
                "note": (
                    "Compilation only succeeded after automatically simulating an "
                    "Escape key press to close what was very likely a stuck "
                    "compile-error dialog. The dialog's exact error message was NOT "
                    "recovered -- if this keeps happening, check the .ipf file's "
                    "syntax directly, or ask a human to read the dialog text before "
                    "it gets dismissed next time."
                ),
            }

    if "compiled_state_known" in poll_result:
        note = (
            f"Reload/compile commands ran, but checking the resulting state kept "
            f"failing (last error code {poll_result.get('last_error_code')}): "
            f"{poll_result.get('last_error_msg')}. " + _COMPILE_ERROR_DIALOG_NOTE
        )
    else:
        note = (
            f"Still not compiled after polling for {_COMPILE_POLL_TIMEOUT_SECONDS:.0f}s"
            + (
                f" plus a further {_COMPILE_POLL_TIMEOUT_AFTER_DISMISS_SECONDS:.0f}s "
                "after an automatic Escape-key dismissal attempt"
                if dismiss_result.get("attempted")
                else ""
            )
            + f" (requiring {_COMPILE_CONFIRM_CHECKS} consecutive confirmations). This is "
            "more likely a genuine compile error in the procedure code than a timing "
            "artifact -- check Igor's history/procedure window directly. "
            + _COMPILE_ERROR_DIALOG_NOTE
        )

    return {
        "reload_triggered": True,
        "compile_triggered": True,
        **poll_result,
        "auto_dismiss_attempted": dismiss_result,
        "prompt_user_to_check_for_dialog": True,
        "note": note,
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
def execute_igor_command_unattended(command: str) -> dict:
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

    Returns a dict with "results" (fprintf output) and "history" (anything
    `command` sent to Igor's history area during this call, e.g. `print` output or
    the command echo itself) -- see execute_igor_command's docstring for exactly
    what "history" contains and why it's the reliable way to verify a `print`
    actually happened.

    **On failure:** a nonzero error code means at least one unhandled runtime error
    occurred somewhere in `command` -- it does NOT mean execution stopped there, and
    it does NOT mean it was the only problem (see the runtime error model notes
    above _format_execute2_error, right before execute_igor_command). The raised
    error includes any partial `results` and `history` captured, since that's often
    the only way to tell how far execution actually got.
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
    return {"results": results, "history": history}


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
            folders_part = part[len("FOLDERS:") :].rstrip(";")
        elif part.startswith("WAVES:"):
            waves_part = part[len("WAVES:") :].rstrip(";")
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
