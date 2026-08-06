"""
Igor Pro MCP bridge server
==========================

Exposes a running Igor Pro instance to Claude (or any MCP client) as a set of MCP tools.

**v2.0.0: transport rewritten from COM to ZeroMQ.** Versions through 1.27.0 talked to
Igor Pro as a COM Automation *client* (win32com, `IgorPro.Application`, `Execute2`).
From 2.0.0 on, this bridge instead talks to Igor Pro's ZeroMQ-XOP
(https://github.com/AllenInstitute/ZeroMQ-XOP) over a plain TCP socket, sending
`CallFunction` JSON requests and calling into Igor-side helper functions in
`Packages/MIES/ZMQ_BridgeHelpers.ipf` (the `ZBR` independent module). See
SESSION_NOTES.md for the full COM-vs-ZeroMQ evaluation that led here, and
Packages/doc/igor-pro-bridge.rst for the up-to-date setup steps.

Why this changed: COM requires this Python process and Igor Pro to run at the SAME
Windows privilege level (both elevated, or both not) -- a mismatch is a real,
easy-to-miss failure mode (e.g. Claude Desktop reopened normally after Igor Pro was
left running elevated from before). ZeroMQ is a plain localhost TCP socket with no
such requirement at all -- **this bridge no longer cares about elevation in any way**.
That is also why `launch_igor_pro_unattended` no longer has an elevation-branching
code path (see its docstring): it always launches Igor Pro as a plain, non-elevated
child process, at whatever privilege level this bridge process itself is running at.

**Setup requirement, new in v2.0.0**: unlike the COM transport (which worked against
a completely stock Igor Pro installation with zero custom procedure code), this
transport requires `Packages/MIES/ZMQ_BridgeHelpers.ipf` to be `#include`-d and
compiled into whatever Igor Pro experiment this bridge talks to -- there is no
bootstrap path over ZeroMQ itself (if that file isn't loaded, there is nothing
listening on the port at all). This repo's own `Packages/MIES_Include.ipf` already
does this permanently. Any OTHER Igor Pro experiment that wants to use this bridge
needs `ZMQ_BridgeHelpers.ipf` copied onto its own procedure search path with a
matching `#include` added by hand, then a recompile -- see
Packages/doc/igor-pro-bridge.rst for the exact steps. This is a one-time,
per-experiment setup cost that didn't exist before; it is the price of everything
else this transport buys (see SESSION_NOTES.md's ZeroMQ-evaluation section for the
full trade-off discussion).

Protocol summary (confirmed empirically this session against a live Igor Pro 9.06
instance, and against https://github.com/AllenInstitute/ZeroMQ-XOP's own README):

- Endpoint: `tcp://127.0.0.1:5680` by default (`_igor_zmq_endpoint()` below) --
  matches `ZBR_ZEROMQ_ENDPOINT`/`ZBR_ZEROMQ_DEFAULT_PORT` in ZMQ_BridgeHelpers.ipf,
  deliberately NOT MIES's own `ZEROMQ_BIND_REP_PORT` (5670) so this can coexist with
  MIES's own (currently short-circuited) ZeroMQ subsystem in the same experiment.
  configure_igor_launch(port=...) can override the port this bridge itself connects
  to (every ZMQ-talking function goes through `_igor_zmq_endpoint()`, not a fixed
  constant, so they all pick up a configured custom port together).
- One JSON `CallFunction` request per ZeroMQ REQ-socket round trip: send
  `{"version": 1, "messageID": ..., "CallFunction": {"name": ..., "params": [...]}}`,
  receive `{"errorCode": {"value": ..., "msg": ...}, "result": ...}`. A NEW REQ socket
  is created for every single call (see `call_function` below) rather than one
  reused across calls -- a REQ socket that times out waiting for a reply is left in a
  state where it cannot send again without being recreated (confirmed empirically
  this session), so per-call sockets sidestep that fragility entirely at negligible
  cost for a local TCP connection.
- **Confirmed documentation bug in the XOP's own README/help**: it says
  `CallFunction.name` should be "a ProcGlobal function without module and/or
  independent module specification, i.e. without `#`" -- empirically confirmed this
  session that this is simply wrong for independent-module functions (like
  everything in the `ZBR` module): the qualified form (`"ZBR#ZBR_Ping"`) is what
  actually works; the unqualified form fails with `errorCode.value=101` ("Unknown
  function"). Every ZBR call in this file uses the qualified form.
- Multi-return Igor functions (`Function [a, b] Foo()`, Igor 8+) are fully supported
  over this protocol -- `result` becomes a JSON array of typed values in declaration
  order. `call_function` below decodes this into a plain Python list automatically.
- Wave return values carry the ENTIRE wave (dimensions, units, note, complex/text/
  wave-ref support) natively-serialized as JSON -- see `_decode_wave` below. This
  replaces the old COM bridge's per-point `GetNumericWavePointValue` loop entirely,
  and is why the new `get_wave` supports far more than the old "1D real waves only"
  limitation.
- **Central architectural constraint, unchanged from the COM-vs-ZeroMQ evaluation**:
  Igor's `Execute` operation (used to run arbitrary free-form command text) cannot be
  called unqueued from inside a Function -- only `Execute/P` (deferred: queued to run
  only after the calling function returns) is legal there. This means a single
  CallFunction round trip cannot synchronously "run this arbitrary command string and
  hand back what it printed" -- there is no direct equivalent of the COM bridge's
  `Execute2`. `execute_igor_command`/`execute_igor_command_unattended` below instead
  use a submit-then-poll pattern (`ZBR_SubmitCommand`/`ZBR_SubmitCommandUnattended`
  queue the command and return a token immediately; `ZBR_PollCommand`, called via a
  LATER separate request, reports completion and the captured output). Every OTHER
  tool below that doesn't need to run arbitrary free-form text (get_wave,
  check_compilation_state, get_debugger_state, get_environment_summary's underlying
  queries, read_help_file, etc.) is backed by a small, purpose-built, directly-callable
  Igor function instead, and is a single synchronous round trip -- no polling needed.
- **Commands with an unknown or long runtime (v2.1.0+)**: `execute_igor_command`/
  `execute_igor_command_unattended` block the whole MCP tool call while polling, up to
  their own `timeout_seconds` -- workable for anything expected to finish in seconds,
  but not for a calculation that might run for hours or weeks, since the underlying
  MCP transport itself has been observed to time out a single tool call well under a
  minute regardless of what `timeout_seconds` requests. `submit_igor_command`/
  `submit_igor_command_unattended` expose the same submit step as its own tool
  (returns a token immediately, no waiting at all), and `poll_igor_command(token)`
  exposes the same poll step as its own tool (one cheap, instant check, callable any
  number of times, spaced arbitrarily far apart). Because all of the actual state
  (done flag, captured text) lives entirely in Igor Pro's own data waves
  (`root:Packages:ZBR`), not in this bridge's Python process, polling stays reliable
  no matter how long the job runs or how many times this bridge process/Claude
  Desktop itself restarts in the meantime -- the only thing that actually ends the
  job is Igor Pro itself quitting, crashing, or restarting.

**Behavior changes from the COM version worth knowing about**:

- `execute_igor_command`/`execute_igor_command_unattended` no longer return a clean,
  separately-captured "results" (fprintf-only output) distinct from "history" (full
  history including the echoed command) -- COM's `Execute2` had special handling to
  split these; this transport cannot replicate that, since the submit/poll mechanism
  only has Igor's own history-diffing (`CaptureHistory`) to go on. Both keys are now
  populated with the same text (everything printed to history while the command ran,
  including its own echo). Prefix a command with `Silent 1;` if you want the echo
  suppressed from the returned text.
- **Use `print`, not `fprintf 0, ...`, to get data back.** Confirmed live this
  session: `CaptureHistory` (which the submit/poll mechanism above relies on)
  captures `print` output but does NOT capture `fprintf`-to-history-refnum output at
  all, whether directed at refnum 0 (history), -1, or -2 -- a command consisting of
  only `fprintf 0, "..."` runs without error but returns empty "results"/"history"
  every time, even though the exact same value printed via `print` is captured
  correctly. This is a real behavior change from the COM version, whose `Execute2`
  had its own dedicated mechanism for capturing `fprintf(0,...)` output specifically
  (unrelated to `CaptureHistory`), which is why that was the documented pattern
  before. `fprintf` remains fine (and necessary) for anything that ISN'T about
  getting data back through this bridge, e.g. writing to a wave or a real file.
- `load_experiment` no longer hot-swaps the open experiment in the running instance
  (that was `IApplication.LoadExperiment`, a COM-only method -- confirmed neither
  "LoadExperiment" nor "OpenFile" appear anywhere in Igor Reference.ihf, only in
  Automation Server.ihf, and there is no procedure-language equivalent). It instead
  asks the running instance to quit, then relaunches the configured Igor Pro
  executable with the target file path as a launch argument -- a real process
  restart, not an in-place swap. **Any unsaved changes in the currently-open
  experiment are lost** (the same as before -- COM's LoadExperiment never auto-saved
  either -- but now there is also no "hot" instance left to save from afterward if
  you forgot). Call `execute_igor_command('SaveExperiment')` first if that matters.
- `ensure_igor_pro_bridge_defined` is retired. It existed to make sure a
  `#ifdef IGOR_PRO_BRIDGE`-gated procedure file's optional code got compiled in
  without a human hand-editing the experiment's Procedure window. `ZBR`'s own
  functions have no such gating (the whole point of an independent module is that it
  compiles on its own regardless of ProcGlobal's `#define` state), so this bridge no
  longer needs it for its own purposes.
- `check_bridge_health`/`check_compilation_state` can no longer distinguish "Igor Pro
  isn't running" from "Igor Pro is running but ZMQ_BridgeHelpers.ipf isn't
  included/compiled/bound" from "wrong port" as cleanly as COM's `GetActiveObject`
  could (a clean binary "is there a registered COM object" signal) -- a ZeroMQ REQ
  socket that gets no reply at all looks the same in all three cases. See
  `check_bridge_health`'s docstring for what to check by hand if this happens.

Setup
-----
    pip install mcp pyzmq pywin32

(pywin32 is still needed for `dismiss_compile_error_dialog`'s window enumeration and
for launching the Igor Pro process -- see below. It is no longer needed for, or
involved in, talking to Igor Pro itself.)

Registering with Claude Desktop
--------------------------------
Do NOT register this by manually editing claude_desktop_config.json -- that does not
work reliably for local MCP servers in current Claude Desktop builds. Instead, package
this directory as a Claude Desktop Extension (.mcpb) and install it via Settings ->
Extensions -> Advanced settings -> Extension Developer -> Install Extension:

    mcpb pack tools/igor-mcp-bridge tools/igor-mcp-bridge/igor-pro-bridge-X.Y.Z.mcpb

See Packages/doc/igor-pro-bridge.rst ("Installation") for the full, up-to-date
installation steps, including the one-time ZMQ_BridgeHelpers.ipf setup step for any
experiment other than this repo's own.

This is a *local* MCP server (stdio transport) -- it only works from a Claude Desktop
session running on the same Windows machine as Igor Pro, not from a cloud/Cowork sandbox.
"""

import html.parser
import importlib.metadata
import json
import os
import subprocess
import sys
import tempfile
import time
import uuid
from typing import Optional

if sys.platform != "win32":
    raise RuntimeError(
        "tools/igor-mcp-bridge/server.py is Windows-only (requires pywin32 for "
        "dismiss_compile_error_dialog's window enumeration and for launching the "
        "configured Igor Pro executable). It cannot run on this platform "
        f"({sys.platform!r}) -- e.g. running it by accident on a non-Windows dev "
        "machine or in CI. The ZeroMQ transport itself is cross-platform; this "
        "restriction is only about this file's OS-level helper tools."
    )

import win32api
import win32con
import win32gui
import win32process

import zmq

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("igor-pro")

# --- ZeroMQ transport ----------------------------------------------------------------

# Matches ZBR_ZEROMQ_ENDPOINT/ZBR_ZEROMQ_DEFAULT_PORT in
# Packages/MIES/ZMQ_BridgeHelpers.ipf.
IGOR_ZMQ_HOST = "tcp://127.0.0.1"
IGOR_ZMQ_DEFAULT_PORT = 5680
_ZMQ_DEFAULT_RECV_TIMEOUT_MS = 5000
_ZMQ_SEND_TIMEOUT_MS = 2000
_ZMQ_LINGER_MS = 0

# Set by configure_igor_launch(port=...) -- see that tool's docstring. None means
# "use IGOR_ZMQ_DEFAULT_PORT".
_configured_igor_port = None

_zmq_context = None


def _get_zmq_context():
    global _zmq_context
    if _zmq_context is None:
        _zmq_context = zmq.Context()
    return _zmq_context


def _igor_zmq_endpoint():
    """The ZeroMQ endpoint this bridge currently connects to. Every function that
    talks to Igor Pro over ZeroMQ must go through this (not a fixed string) so they
    all consistently follow whatever custom port configure_igor_launch(port=...) set,
    instead of some functions silently still targeting the default port."""
    port = (
        _configured_igor_port
        if _configured_igor_port is not None
        else IGOR_ZMQ_DEFAULT_PORT
    )
    return f"{IGOR_ZMQ_HOST}:{port}"


class IgorZmqError(RuntimeError):
    """Igor Pro replied, but reported errorCode.value != 0 for the CallFunction call."""


class IgorZmqUnreachable(RuntimeError):
    """No reply was received at all within the timeout. Could mean: Igor Pro isn't
    running, ZMQ_BridgeHelpers.ipf isn't #include-d/compiled in the running instance,
    its ZeroMQ server socket isn't bound to this bridge's currently configured
    endpoint (see _igor_zmq_endpoint), or the reply is simply slow (e.g. a
    long-running command; pass a longer timeout_ms)."""


def _decode_number(value):
    """Non-normal numbers (NaN/Inf/-Inf) are encoded as strings per the ZeroMQ-XOP's
    own spec ("Messages consist of JSON ... NaN, Inf and -Inf are not supported by
    JSON, so we encode these non-normal numbers as strings"). Decode those back to
    real Python floats; pass anything else through unchanged."""
    if isinstance(value, str):
        low = value.strip().lower()
        if low == "nan":
            return float("nan")
        if low in ("inf", "+inf"):
            return float("inf")
        if low == "-inf":
            return float("-inf")
    return value


def _reshape_column_major(flat, dim_size):
    """Reshape a flat, column-major list per dim_size (1 to 4 entries, per the
    ZeroMQ-XOP's wave serialization spec) into nested Python lists indexed
    data[row][col][layer][chunk] -- matches the spec's own worked example
    (`np.array(raw).reshape(dim_size, order='F')`) without requiring numpy."""
    if not dim_size or list(dim_size) == [0]:
        return []

    dims = list(dim_size) + [1] * (4 - len(dim_size))
    rows, cols, layers, chunks = dims[:4]
    if rows == 0:
        return []

    def at(r, c=0, l=0, k=0):
        return flat[r + rows * (c + cols * (l + layers * k))]

    ndims = len(dim_size)
    if ndims <= 1:
        return [at(r) for r in range(rows)]
    if ndims == 2:
        return [[at(r, c) for c in range(cols)] for r in range(rows)]
    if ndims == 3:
        return [
            [[at(r, c, l) for l in range(layers)] for c in range(cols)]
            for r in range(rows)
        ]
    return [
        [
            [[at(r, c, l, k) for k in range(chunks)] for l in range(layers)]
            for c in range(cols)
        ]
        for r in range(rows)
    ]


def _decode_wave(value):
    """value is None (an invalid/free wave reference, `$""`) or the wave-serialization
    object documented in https://github.com/AllenInstitute/ZeroMQ-XOP's README ("Wave
    serialization format"). Returns None, or a dict with the wave's type, shape, data
    (reshaped into nested Python lists matching the wave's own dimensionality), unit,
    and note. Supports numeric (real and complex), text, and wave-reference waves."""
    if value is None:
        return None

    wave_type = value.get("type", "")
    dimension = value.get("dimension", {}) or {}
    dim_size = dimension.get("size", [])
    data = value.get("data", {}) or {}
    raw = data.get("raw", [])

    if wave_type == "WAVE_TYPE":
        decoded_data = [
            _decode_wave(item) if item is not None else None for item in raw
        ]
    elif isinstance(raw, dict) and "real" in raw:
        # Complex wave: raw = {"real": [...], "imag": [...]}.
        real = [_decode_number(x) for x in raw.get("real", [])]
        imag = [_decode_number(x) for x in raw.get("imag", [])]
        decoded_data = [complex(r, i) for r, i in zip(real, imag)]
    else:
        decoded_data = [_decode_number(x) for x in raw]

    return {
        "type": wave_type,
        "dim_size": dim_size,
        "data": _reshape_column_major(decoded_data, dim_size),
        "unit": data.get("unit"),
        "note": value.get("note", ""),
        "dimension": dimension,
    }


def _decode_typed(typed):
    """typed is {"type": "variable"|"string"|"wave"|"dfref", "value": ...} -- return
    the corresponding plain Python value (numbers get NaN/Inf decoded, waves get fully
    decoded via _decode_wave, everything else passes through as-is)."""
    if not isinstance(typed, dict):
        return typed
    kind = typed.get("type")
    value = typed.get("value")
    if kind == "variable":
        return _decode_number(value)
    if kind == "wave":
        return _decode_wave(value)
    return value


def call_function(name, params=None, timeout_ms=_ZMQ_DEFAULT_RECV_TIMEOUT_MS):
    """Send one CallFunction request to Igor Pro and return its decoded result.

    name must be the FULLY QUALIFIED function name for anything in the ZBR
    independent module, e.g. "ZBR#ZBR_Ping" -- see the module docstring's
    documentation-bug note for why (the XOP's own docs say to omit the "#"; that is
    wrong for independent-module functions, confirmed empirically).

    Returns a plain Python value: None/number/string for a single scalar return, a
    dict for a wave return (see _decode_wave), or a list of such values (in
    declaration order) for a multi-return ("Function [a, b] Foo()") function.

    Raises IgorZmqUnreachable if no reply arrives within timeout_ms at all, or
    IgorZmqError if Igor Pro replied but reported errorCode.value != 0 (the error
    message includes any "history" the XOP reports alongside the error, which often
    shows exactly where inside the called function things went wrong).
    """
    request = {
        "version": 1,
        "messageID": uuid.uuid4().hex,
        "CallFunction": {"name": name, "params": list(params) if params else []},
    }
    payload = json.dumps(request)

    endpoint = _igor_zmq_endpoint()
    sock = _get_zmq_context().socket(zmq.REQ)
    sock.setsockopt(zmq.RCVTIMEO, timeout_ms)
    sock.setsockopt(zmq.SNDTIMEO, _ZMQ_SEND_TIMEOUT_MS)
    sock.setsockopt(zmq.LINGER, _ZMQ_LINGER_MS)
    sock.connect(endpoint)
    try:
        sock.send_string(payload)
        reply_raw = sock.recv_string()
    except zmq.error.Again:
        raise IgorZmqUnreachable(
            f"No reply from Igor Pro within {timeout_ms}ms while calling {name!r}. "
            f"Make sure Igor Pro is running, ZMQ_BridgeHelpers.ipf is #include-d and "
            f"compiled in the current experiment, and its ZeroMQ server socket is "
            f"bound to {endpoint!r} (see check_bridge_health)."
        ) from None
    finally:
        sock.close()

    try:
        reply = json.loads(reply_raw)
    except json.JSONDecodeError as e:
        raise IgorZmqError(
            f"Malformed reply from Igor Pro for {name!r}: {reply_raw!r}"
        ) from e

    error_code = reply.get("errorCode") or {}
    if error_code.get("value", 0) != 0:
        detail = (
            f"Igor Pro reported an error calling {name!r} (code "
            f"{error_code.get('value')}): {error_code.get('msg', '(no message)')}"
        )
        history = reply.get("history")
        if history:
            detail += f"\nIgor history during this call: {history!r}"
        raise IgorZmqError(detail)

    result = reply.get("result")
    if isinstance(result, list):
        return [_decode_typed(item) for item in result]
    return _decode_typed(result)


def _reachable(timeout_ms=1000):
    """True if ZBR#ZBR_Ping answers within timeout_ms, False otherwise. Used for
    "is anything listening right now" checks (already_running / poll loops) where the
    caller doesn't need the actual reply."""
    try:
        call_function("ZBR#ZBR_Ping", timeout_ms=timeout_ms)
        return True
    except (IgorZmqError, IgorZmqUnreachable):
        return False


# --- Command execution (submit/poll) ---------------------------------------------------

_SUBMIT_POLL_INTERVAL_SECONDS = 0.1
_SUBMIT_POLL_TIMEOUT_SECONDS = 30.0


def _submit_and_poll(submit_function: str, command: str, timeout_seconds: float) -> str:
    """Submit `command` via the given ZBR submit function (ZBR_SubmitCommand or
    ZBR_SubmitCommandUnattended) and poll ZBR_PollCommand until it reports done,
    returning the captured text. See the module docstring for why this submit/poll
    dance is needed at all (Execute cannot run unqueued inside a Function)."""
    token = call_function(f"ZBR#{submit_function}", [command])

    deadline = time.monotonic() + timeout_seconds
    while True:
        is_done, text = call_function("ZBR#ZBR_PollCommand", [token])
        if is_done:
            return text
        if time.monotonic() >= deadline:
            raise RuntimeError(
                f"Timed out after {timeout_seconds:.0f}s waiting for a submitted "
                f"command to finish (token {token!r}). Command was: {command}"
            )
        time.sleep(_SUBMIT_POLL_INTERVAL_SECONDS)


@mcp.tool()
def execute_igor_command(
    command: str, timeout_seconds: float = _SUBMIT_POLL_TIMEOUT_SECONDS
) -> dict:
    """Execute a single Igor Pro command string in the running Igor instance.

    **If `command`'s runtime is unknown or could be long (more than roughly a
    minute), use submit_igor_command/poll_igor_command instead.** This tool blocks
    the whole MCP call for up to `timeout_seconds` and will itself get killed by
    Claude Desktop's own MCP request timeout well before that if `timeout_seconds`
    is set too high -- it is only suitable for commands expected to finish quickly.

    **To get data back, include a `print` call in `command` -- NOT `fprintf 0, ...`.**
    Confirmed live: this transport's capture mechanism (`CaptureHistory`) picks up
    `print` output but does not capture `fprintf`-to-history output at all (refnum 0,
    -1, or -2 all silently produce nothing) -- see the module docstring's "Behavior
    changes" section for why (the old COM-based Execute2 had its own separate
    mechanism specifically for fprintf(0,...), which no longer applies here).
    Whatever `print`s (and the echoed command itself, unless prefixed with
    `Silent 1;`) is captured and returned in both "results" and "history" (see the
    module docstring for why this transport can no longer separate the two the way
    Execute2 did).

    Example: execute_igor_command('WaveStats/Q jack; print V_avg')

    Implementation note: this queues `command` (ZBR_SubmitCommand) and polls for
    completion (ZBR_PollCommand) rather than running it in one synchronous round trip
    -- Igor's Execute operation cannot run unqueued from inside a Function at all, so
    there is no direct equivalent of COM's Execute2 here. `timeout_seconds` bounds how
    long this will poll before giving up (raises TimeoutError-style RuntimeError).

    **Caution:** if `command` calls user-defined procedure code and Igor Pro's
    Debugger is currently enabled, a breakpoint/runtime error/abort/stale-reference
    pause in that code will hang the underlying command indefinitely (this poll loop
    will keep timing out and retrying, never actually seeing it finish) -- there is no
    scriptable way to resume or dismiss the Debugger window (see set_debugger_enabled's
    docstring). Use execute_igor_command_unattended instead whenever nobody is
    watching who could close that popup manually.

    **If `command` itself fails to parse or hits a genuine Igor-level runtime error
    (Debugger not involved), this now still returns normally instead of hanging until
    `timeout_seconds` expires** -- confirmed live for both cases. There is currently no
    way to tell that apart from "ran fine and printed nothing", though: the returned
    text will simply be shorter/emptier than expected, with no error indication. If
    verifying success matters, have `command` `print` an explicit sentinel/result
    value itself.
    """
    text = _submit_and_poll("ZBR_SubmitCommand", command, timeout_seconds)
    return {"results": text, "history": text}


@mcp.tool()
def execute_igor_command_unattended(
    command: str, timeout_seconds: float = _SUBMIT_POLL_TIMEOUT_SECONDS
) -> dict:
    """Run `command` exactly like execute_igor_command, but automatically disable
    Igor's Debugger before running it and restore it again afterward -- even if
    `command` raises an Igor-level error.

    **This is the tool to reach for whenever `command` might call user-defined
    procedure code and nothing is watching that could close a Debugger popup by
    hand.** See set_debugger_enabled's docstring for why a Debugger pause has no
    scriptable resume.

    Only reach for plain execute_igor_command when you deliberately want the Debugger
    available (e.g. interactively testing a breakpoint).
    """
    text = _submit_and_poll("ZBR_SubmitCommandUnattended", command, timeout_seconds)
    return {"results": text, "history": text}


_UNKNOWN_TOKEN_PREFIX = "ERROR: unknown token "


@mcp.tool()
def submit_igor_command(command: str) -> dict:
    """Queue `command` for deferred execution and return a token immediately, WITHOUT
    waiting for it to finish.

    **Use this instead of execute_igor_command whenever a command's runtime is
    unknown or could be long -- minutes, hours, even weeks.** execute_igor_command
    blocks the entire MCP tool call until the command finishes or timeout_seconds
    elapses, which cannot work for a genuinely long-running calculation: it will hit
    Claude Desktop's own MCP request timeout (observed in practice to trigger in well
    under a minute) long before a multi-hour command finishes, even though the
    command itself keeps running in Igor Pro regardless of what the MCP call does.

    Call poll_igor_command(token) afterward -- as many times as needed, spaced
    however far apart in time you like -- to check whether it's done yet and
    retrieve its output once it is.

    **Why this is reliable even across very long waits**: the token is just a row
    index into plain data waves in root:Packages:ZBR (done/resultText), maintained
    entirely by Igor Pro itself. Nothing about polling it later depends on this
    bridge's own Python process, on any particular MCP/Claude Desktop session
    staying open, or on how much time passes between calls -- this bridge process
    restarting, or Claude Desktop being closed and reopened, does not lose or
    invalidate the token. The one thing that DOES end the underlying job is Igor
    Pro itself quitting, crashing, or restarting -- in that case the computation
    itself is gone, not just the token, so there is nothing to recover regardless of
    transport.

    **Caution:** if `command` calls user-defined procedure code and Igor Pro's
    Debugger is enabled, a breakpoint/runtime error/abort/stale-reference pause
    leaves poll_igor_command reporting "not done" forever -- indistinguishable from
    a command that's still genuinely, legitimately running, since there is no
    scriptable way to detect or resume a Debugger pause (see
    set_debugger_enabled's docstring). **Use submit_igor_command_unattended instead
    for anything long-running -- this matters far more here than for
    execute_igor_command, since nobody is likely to be watching a job that might run
    for weeks.**

    **Separately (Debugger not involved): `command` failing to parse, or hitting a
    genuine Igor-level runtime error partway through, will NOT leave the token stuck
    forever** -- confirmed live. The finish-callback that flips poll_igor_command's
    "done" flag is queued as its own independent step, so it always runs regardless
    of what happens to `command`. There is, however, no reliable generic way to tell
    "command ran and legitimately printed nothing" apart from "command errored out
    with no output" -- both come back from poll_igor_command as `"done": True` with
    an empty/short result and no error indication. If verifying success matters, have
    `command` `print` an explicit sentinel/result value itself.
    """
    token = call_function("ZBR#ZBR_SubmitCommand", [command])
    return {"token": token}


@mcp.tool()
def submit_igor_command_unattended(command: str) -> dict:
    """Same as submit_igor_command, but disables Igor's Debugger for the duration of
    `command` and restores it afterward -- see execute_igor_command_unattended's
    docstring for the general reasoning.

    **This is the recommended tool for anything long-running submitted via
    submit_igor_command/poll_igor_command.** Without it, a Debugger pause partway
    through a multi-hour or multi-week calculation would silently hang forever with
    no way to distinguish it from the command still legitimately running -- there is
    no periodic "is this actually still making progress" signal beyond
    poll_igor_command's own done/not-done state.
    """
    token = call_function("ZBR#ZBR_SubmitCommandUnattended", [command])
    return {"token": token}


@mcp.tool()
def poll_igor_command(token: str) -> dict:
    """Check whether a command submitted via submit_igor_command/
    submit_igor_command_unattended has finished yet, and retrieve its captured
    output if so.

    Returns `{"done": False}` while still pending -- call again later, there is no
    limit on how long you can wait or how many times you poll (see
    submit_igor_command's docstring for why this stays reliable no matter how much
    time passes or how many times this bridge process itself restarts in the
    meantime). Returns `{"done": True, "results": <text>, "history": <text>}` once
    finished -- both keys hold the same captured text, matching
    execute_igor_command's own return shape (see that tool's docstring for why
    "results"/"history" can no longer be kept separate over this transport, and why
    `print`, not `fprintf`, is what actually gets captured).

    For a job expected to run over a very long horizon (hours to weeks), consider
    setting up a scheduled task that calls this periodically and reports back once
    `"done"` flips to true, rather than relying on this conversation staying open.

    Raises if `token` is not recognized -- e.g. a typo, or a token from a
    since-quit/since-restarted Igor Pro instance (tokens do not survive Igor Pro
    itself restarting, only this bridge process or Claude Desktop restarting).

    Does NOT raise just because the submitted command itself failed to parse or hit
    a runtime error -- that case still reports `"done": True`, just with an
    empty/shorter-than-expected result and no explicit error indication (see
    submit_igor_command's docstring for why: there is currently no generic way to
    detect this here).
    """
    is_done, text = call_function("ZBR#ZBR_PollCommand", [token])
    if not is_done:
        return {"done": False}
    if isinstance(text, str) and text.startswith(_UNKNOWN_TOKEN_PREFIX):
        raise RuntimeError(text)
    return {"done": True, "results": text, "history": text}


@mcp.tool()
def read_session_history(stop: bool = False) -> dict:
    """Read back everything sent to Igor's history area (print output, command
    echoing, error messages, etc.) since this bridge (specifically, ZMQ_BridgeHelpers.
    ipf's own capture) started tracking it -- the reliable way to verify a PAST
    execute_igor_command/execute_igor_command_unattended call's output actually
    happened, without asking a human to look at Igor's screen.

    A capture is started automatically, Igor-side, the first time it's needed (see
    ZBR_EnsureCaptureStarted in ZMQ_BridgeHelpers.ipf) so this always has something to
    report. Each call returns the FULL accumulated text since that start point, not
    just what's new since the last read -- calling this repeatedly with stop=False
    (the default) is always safe.

    stop=True stops the capture (no further text will be recorded for it) and returns
    whatever was captured up to that point; the next call (to this tool, or the next
    command run through this bridge) transparently starts a brand-new capture.
    """
    text = call_function("ZBR#ZBR_ReadSessionHistory", [1 if stop else 0])
    return {"history_text": text, "capture_stopped": stop}


@mcp.tool()
def get_wave(wave_path: str) -> dict:
    """Return an existing Igor wave's data and metadata.

    wave_path should be an absolute Igor path, e.g. "root:testWave" or
    "root:myFolder:testWave".

    Unlike the old COM-based version of this tool (limited to 1D, real-valued waves,
    read one point at a time via GetNumericWavePointValue), this transport's native
    wave serialization supports any dimensionality (up to 4D), real and complex
    numeric waves, text waves, and wave-reference waves (waves of waves) -- the entire
    wave comes back from ONE CallFunction round trip. See the module docstring's wave
    serialization notes for the JSON format this is decoded from.

    Returns a dict with "wave_path", "type" (e.g. "NT_FP64", "TEXT_WAVE_TYPE",
    "WAVE_TYPE"), "dim_size" (1 to 4 numbers), "data" (nested Python lists matching
    the wave's own dimensionality -- data[row][col]... for multi-dimensional waves,
    or a single flat list for 1D), "unit", "note", and "dimension" (delta/offset/
    label/unit per dimension, if set).

    Raises if wave_path does not refer to an existing wave.
    """
    wave = call_function("ZBR#ZBR_GetWaveGeneric", [wave_path])
    if wave is None:
        raise RuntimeError(f"Wave not found: {wave_path}")
    return {"wave_path": wave_path, **wave}


# --- Compilation state -----------------------------------------------------------------


@mcp.tool()
def check_compilation_state() -> dict:
    """Check whether Igor Pro's procedure code is currently compiled or uncompiled.

    Functions from procedure code can only be called while compiled. Igor Pro enters
    the uncompiled state when procedure code is edited inside Igor (only possible
    while nothing is running), or when nothing is running and an included procedure
    file changed on disk. Use reload_and_compile_procedures to get back to compiled
    after editing a .ipf file on disk.

    Note: since ZBR (the independent module this bridge's Igor-side code lives in)
    compiles separately from ProcGlobal/regular MIES code, a "true" result here
    specifically means ProcGlobal's compile state -- confirmed reachable via ZBR at
    all already implies ZBR itself is compiled (otherwise this call would have failed
    with IgorZmqUnreachable/IgorZmqError instead of returning a result).
    """
    compiled = call_function("ZBR#ZBR_IsCompiled")
    return {"compiled": bool(compiled)}


_COMPILE_POLL_INTERVAL_SECONDS = 0.5
_COMPILE_POLL_TIMEOUT_SECONDS = 15.0


def _read_compile_counter():
    """ZBR_ReadCompileCounter(), or None if the call itself fails (e.g. Igor is
    mid-recompile and briefly unreachable) -- treated as "unknown", never fatal, same
    as the counter's own -1-means-unavailable convention Igor-side."""
    try:
        value = call_function("ZBR#ZBR_ReadCompileCounter")
    except (IgorZmqError, IgorZmqUnreachable):
        return None
    return None if value is None or value < 0 else value


@mcp.tool()
def reload_and_compile_procedures() -> dict:
    """Force Igor Pro to reload procedure code from the .ipf files on disk and attempt
    a fresh compilation, then report whether it ended up compiled.

    Use this after editing a .ipf file directly on disk. Only call this while Igor Pro
    is not currently running other procedure code.

    **Caution, carried over from the COM-based version**: Igor Pro has been observed
    becoming unreachable shortly after a reload/compile attempt on more than one
    occasion during this bridge's development (crashed or was closed). As of v2.3.0,
    crash-dump analysis traced this to a genuine EXCEPTION_ACCESS_VIOLATION deep inside
    Igor64.exe itself (not this bridge's own code), and a likely mechanism was
    identified: this bridge's ZeroMQ handler runs as a background thread that keeps
    dispatching incoming CallFunction requests regardless of what Igor's main thread is
    doing, so a request arriving while COMPILEPROCEDURES is mid-rebuild of Igor's own
    internal function/symbol tables is a plausible cross-thread race. v2.3.0 mitigates
    this by stopping the ZeroMQ handler before RELOAD CHANGED PROCS/COMPILEPROCEDURES
    run and restarting it only after compilation finishes. This is a well-reasoned
    mitigation, not a proven fix -- Igor64.exe ships no public symbols, so the exact
    fault can't be confirmed from here, and the crash was already rare/nondeterministic.
    If a tool call after this one starts failing anyway, check_bridge_health() and be
    prepared for Igor Pro to need relaunching.

    **v2.3.1 fix -- handler could stay stopped forever on a failed compile**: v2.3.0's
    restart path was AfterCompiledHook alone, which Igor only calls after a
    *successful* compile. If the edited .ipf had a syntax error, COMPILEPROCEDURES
    failed, AfterCompiledHook never fired, and the ZeroMQ handler -- already stopped by
    ZBR_StopHandlerBeforeRecompile -- stayed stopped permanently, killing the bridge
    with no recovery path short of restarting Igor. Fixed by ZBR_ArmRecompileWatchdog/
    ZBR_RecompileWatchdogTick in ZMQ_BridgeHelpers.ipf: a named background task, armed
    right before the handler is stopped, that unconditionally rebinds/restarts the
    handler regardless of whether the compile succeeds or fails. It is registered with
    `start=60` (an explicit ~1-second floor before its first possible tick, independent
    of its `period=30` interval) so it cannot fire before RELOAD CHANGED
    PROCS/COMPILEPROCEDURES have finished draining Igor's operation queue -- confirmed
    necessary by live timing instrumentation (stopmstimer(-2)) showing the background
    task could otherwise tick within ~62ms of being armed, well before a real compile
    (~414ms observed) finishes. AfterCompiledHook still restarts the handler
    immediately on the success path; the watchdog is what covers the failure path, and
    self-disarms (CtrlNamedBackground .. stop) the first time either one runs.

    **v2.3.1 fix -- ZBR_IsCompiled() checked the wrong module**: its FunctionInfo() call
    was unqualified, so it resolved against ZBR's own (independent-module) namespace
    -- which compiles separately from ProcGlobal -- instead of ProcGlobal's. This meant
    it could report "compiled" even while ProcGlobal itself had a compile error. Fixed
    by qualifying the lookup as `FunctionInfo("ProcGlobal#...")`.

    **v2.3.1 fix -- "Function Execution Module is still active" dialog**: an unrelated
    pre-existing MIES background thread (not task) left running during
    COMPILEPROCEDURES could raise this modal dialog and freeze the entire operation
    queue. Mitigated by a new BeforeUncompiledHook in ZMQ_BridgeHelpers.ipf that calls
    ThreadGroupRelease(-2) to release any running thread groups before Igor uncompiles.

    Mechanism: calls ZBR_SubmitReloadAndCompile(), which queues (as three independent
    Execute/P entries) a call to stop the ZeroMQ handler and arm the watchdog, then
    `Execute/P "RELOAD CHANGED PROCS "`, then `Execute/P "COMPILEPROCEDURES "`
    Igor-side (see that function's docstring in ZMQ_BridgeHelpers.ipf), then polls for
    completion using two independent signals, same as the COM-based version did:

    1. root:gClaudeHelperCompileCounter (ZBR_ReadCompileCounter), bumped by
       AfterCompiledHook every time Igor confirms a successful compile -- race-free:
       any increase over the baseline read before submitting is trusted immediately.
    2. ZBR_IsCompiled() (the FunctionInfo-based check), as a fallback.

    Poll errors (IgorZmqError/IgorZmqUnreachable) during either check are treated as
    "not ready yet" rather than fatal, since Igor Pro can be briefly unreachable while
    genuinely mid-recompile.

    If this returns "compiled": False, check Igor's history/procedure window directly
    -- if Igor Pro was launched with /UNATTENDED, a genuine compile error shows up as
    a plain "<file>:<line>:<col>: error: <message>" line there (readable via
    read_session_history), rather than a modal dialog. If NOT launched /UNATTENDED, a
    stuck "Function Compilation Error" dialog is also possible -- see
    dismiss_compile_error_dialog. As of v2.3.1, the bridge itself should still be
    reachable in this case (see the watchdog fix above) -- fix the .ipf and call this
    tool again rather than needing to relaunch Igor Pro.
    """
    baseline_counter = _read_compile_counter()

    call_function("ZBR#ZBR_SubmitReloadAndCompile")

    deadline = time.monotonic() + _COMPILE_POLL_TIMEOUT_SECONDS
    attempts = 0
    while True:
        attempts += 1

        counter = _read_compile_counter()
        if (
            baseline_counter is not None
            and counter is not None
            and counter > baseline_counter
        ):
            return {
                "compiled": True,
                "poll_attempts": attempts,
                "confirmed_via": "AfterCompiledHook counter (ZBR_ReadCompileCounter)",
            }

        try:
            if call_function("ZBR#ZBR_IsCompiled"):
                return {
                    "compiled": True,
                    "poll_attempts": attempts,
                    "confirmed_via": "ZBR_IsCompiled",
                }
        except (IgorZmqError, IgorZmqUnreachable):
            pass  # treat as "not ready yet", same as a False result

        if time.monotonic() >= deadline:
            break
        time.sleep(_COMPILE_POLL_INTERVAL_SECONDS)

    dismiss_result = _attempt_dismiss_compile_error_dialog()
    return {
        "compiled": False,
        "poll_attempts": attempts,
        "auto_dismiss_attempted": dismiss_result,
        "note": (
            f"Still not compiled after polling for {_COMPILE_POLL_TIMEOUT_SECONDS:.0f}s. "
            "This is more likely a genuine compile error than a timing artifact -- "
            "check Igor's history/procedure window directly (or call "
            "read_session_history() if launched with /UNATTENDED, see the "
            "'<file>:<line>:<col>: error: ...' line reported there), or check for a "
            "stuck compile-error dialog (see 'auto_dismiss_attempted' above)."
        ),
    }


# --- Debugger control --------------------------------------------------------------
#
# Unchanged in spirit from the COM-based version -- see that version's extensive
# comment block (still true) for why the Debugger MUST be disabled for any
# unattended/automated session: there is no scriptable way to resume, step, or
# dismiss the Debugger window once something pauses it, and a paused call hangs
# forever. DebuggerOptions is NOT subject to the Execute-only restriction (confirmed
# live), so ZBR_GetDebuggerState/ZBR_SetDebuggerEnabled/ZBR_RestoreDebuggerSettings
# are all single, synchronous CallFunction calls -- no submit/poll needed.

_saved_debugger_settings = None


def _decode_debugger_state(multi) -> dict:
    enable, debug_on_error, debug_on_abort, nvar_checking = multi
    return {
        "enable": bool(enable),
        "debug_on_error": bool(debug_on_error),
        "debug_on_abort": bool(debug_on_abort),
        "nvar_svar_wave_checking": bool(nvar_checking),
    }


@mcp.tool()
def get_debugger_state() -> dict:
    """Read Igor Pro's current Debugger settings (enable, debugOnError, debugOnAbort,
    NVAR_SVAR_WAVE_Checking) without changing them, and save a snapshot inside this
    bridge process for restore_debugger_settings to restore later.

    **Call this before starting any unattended/automated session**, immediately
    before calling set_debugger_enabled(False).
    """
    global _saved_debugger_settings
    state = _decode_debugger_state(call_function("ZBR#ZBR_GetDebuggerState"))
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
    debugOnAbort/NVAR_SVAR_WAVE_Checking sub-settings).

    **For any unattended/automated session, the debugger MUST be disabled: call
    set_debugger_enabled(False) before starting.** See get_debugger_state's docstring
    and the module-level Debugger-control comment above for why.

    enabled=False clears all four settings regardless of the other arguments -- this
    is Igor's own documented DebuggerOptions behavior, not a limitation of this
    function -- so the sub-flags are only applied when enabled=True. Any sub-flag left
    as None (the default) falls back to Igor's CURRENT setting for that flag rather
    than being forced off.

    Recommended pattern around an unattended session:
        get_debugger_state()           # read + save the current settings
        set_debugger_enabled(False)    # disable for the unattended run
        ... run the unattended session ...
        restore_debugger_settings()    # put the saved settings back
    """
    current = _decode_debugger_state(call_function("ZBR#ZBR_GetDebuggerState"))
    if not enabled:
        call_function("ZBR#ZBR_SetDebuggerEnabled", [0])
    else:
        call_function(
            "ZBR#ZBR_RestoreDebuggerSettings",
            [
                1,
                int(
                    current["debug_on_error"]
                    if debug_on_error is None
                    else debug_on_error
                ),
                int(
                    current["debug_on_abort"]
                    if debug_on_abort is None
                    else debug_on_abort
                ),
                int(
                    current["nvar_svar_wave_checking"]
                    if nvar_svar_wave_checking is None
                    else nvar_svar_wave_checking
                ),
            ],
        )
    return _decode_debugger_state(call_function("ZBR#ZBR_GetDebuggerState"))


@mcp.tool()
def restore_debugger_settings() -> dict:
    """Restore Igor Pro's Debugger settings to whatever get_debugger_state last
    captured.

    **Call this when an unattended/automated session ends.**

    Raises if get_debugger_state was never called in this bridge process.
    """
    if _saved_debugger_settings is None:
        raise RuntimeError(
            "No saved Debugger settings to restore -- call get_debugger_state() "
            "before starting the unattended session so there is something to "
            "restore afterward."
        )
    s = _saved_debugger_settings
    call_function(
        "ZBR#ZBR_RestoreDebuggerSettings",
        [
            int(s["enable"]),
            int(s["debug_on_error"]),
            int(s["debug_on_abort"]),
            int(s["nvar_svar_wave_checking"]),
        ],
    )
    return _decode_debugger_state(call_function("ZBR#ZBR_GetDebuggerState"))


# --- Environment summary -----------------------------------------------------------
#
# Composed client-side from the small, generic ZBR_IgorInfo/ZBR_WinList/
# ZBR_ProcedureText/ZBR_DataFolderDir wrappers in ZMQ_BridgeHelpers.ipf -- exactly
# mirroring how the COM-based version worked (it also just ran fprintf-wrapped
# built-in calls and parsed/structured the raw string results in Python). See that
# file's own comments for the confirmed IgorInfo() index meanings and the
# ProcedureText("", 0, "Procedure") argument-order gotcha.


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
    actually included right now, the contents of the always-present "Procedure"
    window, and the top-level global data folder layout.

    Returns a dict with:
      - igor_version_info / os_info: raw IgorInfo(0) / IgorInfo(3) strings
      - experiment_file_name / experiment_file_kind: e.g. "Basic.pxp" / "Packed"
      - loaded_xops: list of loaded external operations
      - procedure_window_text: raw contents of the special "Procedure" window --
        inspect this for experiment-specific #include/#define directives
      - included_procedure_file_count / included_procedure_files_by_category /
        included_procedure_files: currently included .ipf files
      - data_folders / top_level_waves: top-level layout under root:
      - debugger_settings: current Debugger state (see set_debugger_enabled's
        docstring for why this matters before any unattended session)
    """
    igor_version_info = call_function("ZBR#ZBR_IgorInfo", [0])
    os_info = call_function("ZBR#ZBR_IgorInfo", [3])
    loaded_xops_raw = call_function("ZBR#ZBR_IgorInfo", [10])
    experiment_file_kind = call_function("ZBR#ZBR_IgorInfo", [11])
    experiment_file_name = call_function("ZBR#ZBR_IgorInfo", [12])
    included_raw = call_function("ZBR#ZBR_WinList", ["*", "WIN:128"])
    data_folders_raw = call_function("ZBR#ZBR_DataFolderDir", [3])
    procedure_window_text = call_function("ZBR#ZBR_ProcedureText", ["", 0, "Procedure"])
    debugger_settings = _decode_debugger_state(
        call_function("ZBR#ZBR_GetDebuggerState")
    )

    included_procedure_files = [
        name for name in included_raw.split(";") if name and name != "Procedure"
    ]
    loaded_xops = [x for x in loaded_xops_raw.split(";") if x]

    folders_part, waves_part = "", ""
    for part in data_folders_raw.split("\r"):
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
        "igor_version_info": igor_version_info,
        "os_info": os_info,
        "experiment_file_name": experiment_file_name,
        "experiment_file_kind": experiment_file_kind,
        "loaded_xops": loaded_xops,
        "procedure_window_text": procedure_window_text,
        "included_procedure_file_count": len(included_procedure_files),
        "included_procedure_files_by_category": category_counts,
        "included_procedure_files": included_procedure_files,
        "data_folders": data_folders,
        "top_level_waves": top_level_waves,
        "debugger_settings": debugger_settings,
    }


# --- Reading .ihf help files ---------------------------------------------------------
#
# The actual CloseHelp/OpenNotebook/SaveNotebook/KillWindow/OpenHelp sequence now runs
# synchronously, Igor-side, in ZBR_ReadHelpFile (ZMQ_BridgeHelpers.ipf) -- none of
# those operations are subject to the Execute-only restriction, so this needs no
# submit/poll. The exported HTML is written to a temp file (built here, same as the
# COM-based version did) and read directly off disk afterward rather than serialized
# back through the CallFunction reply -- both processes run on the same machine, so
# this sidesteps any question about reply-size limits for a potentially large export.


class _NotebookHTMLParser(html.parser.HTMLParser):
    """Extracts one {"style": ..., "text": ...} record per <P> paragraph from a
    notebook's HTML export (SaveNotebook/S=5)."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.paragraphs = []
        self._in_paragraph = False
        self._style = ""
        self._text_parts = []

    def handle_starttag(self, tag, attrs):
        if tag.lower() == "p":
            self._in_paragraph = True
            self._style = ""
            self._text_parts = []
            for key, value in attrs:
                if key.lower() == "class" and value:
                    self._style = value

    def handle_endtag(self, tag):
        if tag.lower() == "p" and self._in_paragraph:
            text = "".join(self._text_parts).strip()
            self.paragraphs.append({"style": self._style, "text": text})
            self._in_paragraph = False

    def handle_data(self, data):
        if self._in_paragraph:
            self._text_parts.append(data)


@mcp.tool()
def read_help_file(file_path: str, timeout_ms: int = 30000) -> dict:
    """Read an Igor Pro help file (.ihf) as structured, formatted text -- e.g. to
    look up an operation's exact flags/behavior straight from Igor's own docs --
    without leaving any lasting change to Igor's help-window state.

    file_path must be a full path to an existing .ihf file (e.g. one found via
    get_environment_summary's "loaded_xops" field plus the global/user Help Files
    folders under Igor's own installation for XOP-supplied help files).

    timeout_ms defaults to 30 seconds rather than this bridge's usual 5-second
    default -- confirmed live that exporting a genuinely large help file (e.g. the
    entire "Igor Reference.ihf" manual) as HTML can take longer than 5 seconds, which
    would otherwise time out this call even though Igor-side the export eventually
    succeeds anyway (harmlessly logging a "Host unreachable" ZeroMQ-XOP error to
    history when it tries to reply to a client that already gave up -- see
    check_bridge_health if you see that in read_session_history's output after a
    timeout here). Pass a larger value still for very large help files if 30s isn't
    enough.

    Returns a dict with:
      - "paragraphs": [{"style": "Topic", "text": "Debugging"}, ...] -- "style" is
        WaveMetrics' own paragraph-class convention (e.g. "Topic" for a heading,
        "Code1" for example code, "Steps" for a bullet item), "" if unset.
      - "restore_failures": bare file names that could not be resolved back to a full
        path and so were NOT reopened as help windows (e.g. a help file supplied from
        somewhere other than the two standard Help Files folders).

    Raises if file_path does not exist, or if the underlying OpenNotebook/SaveNotebook
    sequence fails Igor-side (e.g. file_path is not actually a notebook-compatible
    file) -- help-window restoration is still attempted even then.
    """
    normalized = os.path.abspath(file_path)
    if not os.path.isfile(normalized):
        raise RuntimeError(f"'{normalized}' does not exist or is not a file.")

    tmp_fd, tmp_html_path = tempfile.mkstemp(suffix=".html", prefix="igor_help_")
    os.close(tmp_fd)
    os.remove(
        tmp_html_path
    )  # SaveNotebook must create it fresh; only the name is reused

    try:
        status = call_function(
            "ZBR#ZBR_ReadHelpFile", [normalized, tmp_html_path], timeout_ms=timeout_ms
        )
        parts = status.split("|")
        outcome = parts[0] if parts else ""
        restore_failures = [f for f in (parts[-1] if parts else "").split(";") if f]

        if outcome != "OK":
            message = parts[1] if len(parts) > 1 else "(no message)"
            raise RuntimeError(
                f"Could not read help file {normalized!r}: {message} "
                f"(restore_failures={restore_failures!r})"
            )

        if not os.path.isfile(tmp_html_path):
            raise RuntimeError(
                f"ZBR_ReadHelpFile reported success but {tmp_html_path!r} was not "
                "created."
            )

        with open(tmp_html_path, "r", encoding="utf-8") as f:
            html_text = f.read()
        parser = _NotebookHTMLParser()
        parser.feed(html_text)
    finally:
        try:
            if os.path.isfile(tmp_html_path):
                os.remove(tmp_html_path)
        except Exception:
            pass

    return {"paragraphs": parser.paragraphs, "restore_failures": restore_failures}


# --- Bridge identity / health --------------------------------------------------------

# Kept as a hardcoded constant (not read from manifest.json at runtime) for the same
# reason as before: the on-disk layout after Claude Desktop installs a .mcpb isn't
# guaranteed to keep server.py and manifest.json at a fixed relative path, and this
# needs to be confirmable from inside a conversation independent of that.
_BRIDGE_VERSION = "2.3.2"


def _installed_package_version(distribution_name: str) -> str | None:
    try:
        return importlib.metadata.version(distribution_name)
    except importlib.metadata.PackageNotFoundError:
        return None


@mcp.tool()
def get_bridge_version() -> dict:
    """Return the version of this Igor Pro Bridge build that is actually running right
    now, plus which Python interpreter and package versions it's running with.

    Call this whenever it matters to confirm which build is active -- e.g. before
    relying on a specific fix, or when reporting results from a test that depends on
    a particular fix being in effect. Installing a newer .mcpb requires restarting
    Claude Desktop; this is the only way to confirm afterward which version actually
    loaded.
    """
    return {
        "version": _BRIDGE_VERSION,
        "python_executable": sys.executable,
        "python_version": sys.version.split()[0],
        "mcp_package_version": _installed_package_version("mcp"),
        "pyzmq_version": _installed_package_version("pyzmq"),
    }


@mcp.tool()
def check_bridge_health() -> dict:
    """Check whether this bridge can actually reach Igor Pro's ZeroMQ server right
    now, and report what's known if not.

    Call this first whenever a command fails or behaves unexpectedly.

    Unlike the old COM-based version, this can no longer cleanly distinguish "Igor
    Pro isn't running" from "Igor Pro is running but ZMQ_BridgeHelpers.ipf isn't
    included/compiled/bound" from "wrong port/firewall" -- a ZeroMQ REQ socket that
    gets no reply at all looks the same in all three cases (see the module docstring's
    "Behavior changes" section). If this reports FAIL, check by hand: is Igor64.exe
    actually running (Task Manager)? Is Packages/MIES/ZMQ_BridgeHelpers.ipf
    #include-d and does check_compilation_state-equivalent info suggest it's
    compiled? Try `netstat -a -b` (needs admin) to see whether anything is actually
    listening on this bridge's currently configured port (see _igor_zmq_endpoint;
    reported in the "problem" message below on FAIL) -- if a custom port was set via
    configure_igor_launch(port=...), make sure the target Igor Pro instance was
    actually launched with that same port in effect.

    Returns a dict with a "status" key ("OK" or "FAIL") and, on FAIL, a "problem" key.
    """
    try:
        info = call_function("ZBR#ZBR_Ping")
    except IgorZmqUnreachable as e:
        return {
            "status": "FAIL",
            "problem": (
                f"No reply from Igor Pro's ZeroMQ server ({e}). This can mean Igor "
                "Pro isn't running, ZMQ_BridgeHelpers.ipf isn't #include-d/compiled "
                "in the current experiment (see that file's own header comment for "
                "the one-time setup step), or its ZeroMQ socket isn't bound to "
                f"{_igor_zmq_endpoint()} for some other reason."
            ),
        }
    except IgorZmqError as e:
        return {
            "status": "FAIL",
            "problem": f"Igor Pro's ZeroMQ server replied but reported an error: {e}",
        }

    return {"status": "OK", "igor_info": info}


# --- Compile-error dialog dismissal (posted Escape key message) ---------------------
#
# Unchanged from the COM-based version: this is pure OS-level window handling
# (win32gui/win32api), entirely independent of which transport talks to Igor Pro's
# procedure code. See the original version's extensive comment history (still
# accurate) for how the dialog's title/class were identified live, why title-only
# matching is used (a Copilot PR review flagged blanket "#32770" matching as unsafe),
# and why PostMessage (not a real hardware key event) is used.

_IGOR_PROCESS_NAME_PREFIX = "igor"
_KNOWN_STUCK_DIALOG_TITLES = ("Function Compilation Error",)
_POSTED_KEY_GAP_SECONDS = 0.05
_POSTED_KEY_SETTLE_SECONDS = 0.2


def _is_stuck_dialog_window(class_name: str, title: str) -> bool:
    return any(known.lower() in title.lower() for known in _KNOWN_STUCK_DIALOG_TITLES)


def _get_process_exe_name(pid: int):
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


def _list_pids_for_exe_basename(basename_lower: str) -> list:
    """Return the PIDs of every currently running process whose own module file name
    matches basename_lower exactly (case-insensitively), e.g. "igor64.exe".

    Used by load_experiment to wait for an Igor Pro process to fully exit -- **not**
    the same thing as it going quiet over ZeroMQ. Confirmed live (user report, this
    session): ZeroMQ stops answering well before the underlying Igor64.exe process
    actually terminates, and launching a replacement `Igor64.exe /UNATTENDED <path>`
    command line while the old process is still alive -- even if it's already mid-quit
    -- does NOT spawn a new process at all. Windows/Igor's single-instance-per-user
    behavior instead either (a) redirects the launch request into the still-live old
    instance, which can pop an unhandled "save changes?" dialog if it has unsaved
    edits, or (b) if the old instance is already mid-shutdown, silently drops the
    request altogether -- which looks exactly like the relaunch had no effect at all,
    with no error reported anywhere. Waiting for the actual OS process list to be
    clear of the target exe name, rather than trusting ZeroMQ silence, avoids both.
    """
    matches = []
    for pid in win32process.EnumProcesses():
        if pid == 0:
            continue
        exe_name = _get_process_exe_name(pid)
        if exe_name and exe_name.lower() == basename_lower:
            matches.append(pid)
    return matches


def _find_igor_dialog_window():
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
    found = _find_igor_dialog_window()
    if found is None:
        return {
            "attempted": False,
            "reason": (
                "No visible window with a title containing one of "
                f"{_KNOWN_STUCK_DIALOG_TITLES}, owned by an Igor Pro process, was "
                "found. Either there is no stuck dialog right now, or it's a kind "
                "not seen before -- see 'igor_windows_seen' below."
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
            "(no OS foreground/focus change was made or needed). This does NOT "
            "recover the actual compile-error message -- it only closes whatever "
            "modal dialog was showing. Follow up with check_compilation_state() or "
            "reload_and_compile_procedures() to see whether this actually un-stuck "
            "anything."
        ),
    }


@mcp.tool()
def dismiss_compile_error_dialog() -> dict:
    """Attempt to close a stuck Igor Pro modal compile-error dialog by posting a
    simulated Escape key press directly to it, WITHOUT recovering the actual error
    message and WITHOUT requiring or changing OS focus/foreground state.

    Use this manually when you suspect Igor Pro has a compile-error dialog open (e.g.
    reload_and_compile_procedures kept reporting "not compiled" even after fixing a
    known syntax error). Note: launching Igor Pro with /UNATTENDED (see
    launch_igor_pro_unattended) suppresses this dialog entirely in favor of a plain
    history line, so this should rarely be needed for an instance launched that way.

    Mechanism: enumerates top-level windows for a visible one, owned by a process
    whose exe name starts with "igor", whose title matches a known stuck-dialog title
    ("Function Compilation Error", confirmed live on both Igor Pro 10.03 and 9.06,
    both a Qt window rather than a native "#32770" dialog). Posts WM_KEYDOWN/WM_KEYUP
    for VK_ESCAPE via PostMessage, without requiring focus or foreground.

    If no matching window is found, reports "attempted": False along with
    "igor_windows_seen": every visible top-level window currently owned by an Igor
    Pro process, so a new stuck dialog's real title/class can be identified.

    **Trade-off: this does not tell you what the error was.** It only clears whatever
    dialog is blocking Igor's operation queue so work can continue.
    """
    return _attempt_dismiss_compile_error_dialog()


# --- Launching / relaunching Igor Pro -------------------------------------------------
#
# Still pure Python/OS-level (starting a whole new Igor Pro *process* has to be done
# from outside any already-running instance -- no transport can do this from the
# inside). **No more elevation branching at all** -- see the module docstring: ZeroMQ
# has no privilege-matching requirement, so Igor Pro is always launched as a plain
# child process of this bridge process, at whatever privilege level that already is.

# Matches ZBR_ZEROMQ_ENV_PORT in Packages/MIES/ZMQ_BridgeHelpers.ipf: when set, a
# launched Igor Pro instance's ZBR_EnsureZeroMQBound binds its ZeroMQ socket to this
# port instead of its own default (5680). Preparation for talking to more than one
# Igor Pro instance -- see configure_igor_launch. _configured_igor_port itself lives
# up in the "ZeroMQ transport" section since _igor_zmq_endpoint() also reads it.
_IGOR_PRO_BRIDGE_PORT_ENV_VAR = "IGOR_PRO_BRIDGE_PORT"

_configured_igor_exe_path = None


def _build_igor_launch_env():
    """Return an environment dict for subprocess.Popen when launching Igor Pro,
    patching in COMSPEC if this process's own environment is missing it.

    Confirmed necessary during this bridge's development: MIES's own startup hook
    (IgorStartOrNewHook -> ... -> ExecuteGitForMIESVersion, MIES_GlobalStringAndVariable
    Access.ipf) shells out to git via ExecuteScriptText using GetCmdPath()/COMSPEC to
    find cmd.exe. A child process launched via subprocess.Popen with no explicit env
    inherits this process's own environment -- which may not have COMSPEC set (a
    normal interactive login session always does; this bridge process's own
    environment, inherited from whatever launched Claude Desktop, might not). Without
    it, MIES's git-shell-out becomes malformed and
    `ASSERT(!V_flag, "We have git installed but could not regenerate version.txt")`
    trips on every launch via this path.

    Also carries through _IGOR_PRO_BRIDGE_PORT_ENV_VAR if configure_igor_launch set
    (or cleared) it on this process's own os.environ -- no extra handling needed here
    since this starts from a plain copy of that.
    """
    env = os.environ.copy()
    if not env.get("COMSPEC"):
        system_root = env.get("SystemRoot", r"C:\Windows")
        env["COMSPEC"] = os.path.join(system_root, "System32", "cmd.exe")
    return env


@mcp.tool()
def configure_igor_launch(exe_path: str, port: Optional[int] = None) -> dict:
    """Record the full path to the Igor Pro executable (e.g. "...\\IgorBinaries_x64\\
    Igor64.exe") to use for launch_igor_pro_unattended/load_experiment, for the rest
    of this bridge process's session.

    **Whatever agent is calling this tool should ask the user for this path once, at
    the start of a session that might need to launch Igor Pro** -- do not guess or
    default to a typical installation path; this repo alone has been tested against
    Igor Pro installed in more than one differently-named folder. This setting is
    session-scoped: it resets if this bridge process itself restarts.

    port, if given, is a custom ZeroMQ port for the NEXT launched instance to bind
    to, instead of its own default (5680) -- preparation for eventually talking to
    more than one Igor Pro instance at once. Setting this writes
    IGOR_PRO_BRIDGE_PORT=str(port) into this bridge process's own environment;
    launch_igor_pro_unattended/load_experiment inherit that when they start Igor Pro
    (see _build_igor_launch_env), and the launched instance's own
    ZBR_EnsureZeroMQBound (ZMQ_BridgeHelpers.ipf) reads it back to decide which port
    to bind. **Omitting port (or passing None) clears any previously-configured
    custom port** -- it removes IGOR_PRO_BRIDGE_PORT from this process's environment
    entirely, so the next launch uses Igor's own default port again. This is not
    "leave unchanged": repeat the same port value on every call while a custom port
    should stay in effect.

    Also updates which port THIS bridge itself connects to for every subsequent tool
    call (see _igor_zmq_endpoint) -- every ZMQ-talking function goes through that one
    helper, so setting/clearing port here immediately retargets all of them, not just
    the next launch. This bridge still only tracks ONE currently-configured
    endpoint at a time, though -- talking to two Igor Pro instances simultaneously
    (rather than switching which single one this points at) isn't supported yet.

    Raises if exe_path does not point to an existing file, or if port is given but
    is not a valid TCP port number (1-65535). Does not otherwise validate that
    exe_path is actually Igor Pro (beyond a soft filename check).
    """
    global _configured_igor_exe_path, _configured_igor_port

    normalized = os.path.abspath(exe_path)
    if not os.path.isfile(normalized):
        raise RuntimeError(
            f"'{normalized}' does not exist or is not a file. Ask the user for the "
            "exact full path to the Igor Pro executable (typically something like "
            r'"C:\Program Files\WaveMetrics\Igor Pro 9 Folder\IgorBinaries_x64\Igor64.exe"'
            " -- the exact folder name varies by Igor Pro version) and try again."
        )

    if port is not None and (
        not isinstance(port, int) or isinstance(port, bool) or not (1 <= port <= 65535)
    ):
        raise RuntimeError(
            f"'{port}' is not a valid TCP port -- expected an integer between 1 and "
            "65535, or omit/None to clear a previously-configured custom port."
        )

    note = None
    if "igor" not in os.path.basename(normalized).lower():
        note = (
            "This file name does not look like a typical Igor Pro executable "
            "(expected something like 'Igor64.exe'). Proceeding anyway in case the "
            "user has a renamed executable."
        )

    if port is not None:
        os.environ[_IGOR_PRO_BRIDGE_PORT_ENV_VAR] = str(port)
    else:
        os.environ.pop(_IGOR_PRO_BRIDGE_PORT_ENV_VAR, None)

    _configured_igor_exe_path = normalized
    _configured_igor_port = port
    return {"configured_exe_path": normalized, "configured_port": port, "note": note}


_POST_LAUNCH_POLL_INTERVAL_SECONDS = 1.0


@mcp.tool()
def launch_igor_pro_unattended(wait_for_ready_seconds: float = 30.0) -> dict:
    """Launch the configured Igor Pro executable with the /UNATTENDED command-line
    flag.

    Per Igor Pro Folder/Igor Help Files/Advanced Topics.ihf ("Calling Igor from
    Scripts"), /UNATTENDED "suppresses certain interactions that are inconvenient for
    unattended operations" -- documented examples are the About Autosave dialog and
    (Igor Pro 10+) the license activation dialog. Also confirmed empirically (not
    documented anywhere in Igor's help files): /UNATTENDED also suppresses the modal
    "Function Compilation Error" dialog on a bad procedure compile, reporting the
    error as a plain history line instead (format "<file>:<line>:<col>: error:
    <message>", readable via read_session_history).

    **Requires configure_igor_launch(exe_path) to have been called first.**

    Refuses to launch (returns "launched": False) if something already answers
    ZBR#ZBR_Ping right now -- launching the executable again with only /UNATTENDED
    starts a genuinely new instance rather than reusing an existing one (Advanced
    Topics.ihf), which would leave two Igor64.exe processes running.

    **Always launches as a plain child process (subprocess.Popen), at whatever
    privilege level this bridge process itself is running at -- no elevation request,
    no UAC prompt, ever.** This is a deliberate change from the COM-based version:
    ZeroMQ has no privilege-matching requirement at all (unlike COM, which needed this
    process and Igor Pro to run at the SAME privilege level), so there is nothing to
    branch on anymore.

    Patches COMSPEC into the child's environment if missing (see
    _build_igor_launch_env) -- needed for MIES's own git-based startup hook.

    After launching, polls for ZBR#ZBR_Ping to start answering (every ~1s) up to
    wait_for_ready_seconds. Returns whether it became ready and how many polling
    attempts that took.
    """
    if not _configured_igor_exe_path:
        raise RuntimeError(
            "No Igor Pro executable path configured yet. Ask the user for the full "
            "path to their Igor Pro executable (e.g. "
            r'"C:\Program Files\WaveMetrics\Igor Pro 9 Folder\IgorBinaries_x64\Igor64.exe")'
            ", then call configure_igor_launch(exe_path) with it before calling "
            "this tool."
        )

    if _reachable(timeout_ms=1000):
        return {
            "launched": False,
            "reason": (
                "Something already answered ZBR#ZBR_Ping over ZeroMQ. Refusing to "
                "launch a second Igor Pro instance -- close the existing one first "
                "if a genuinely fresh one is actually wanted."
            ),
        }

    try:
        subprocess.Popen(
            [_configured_igor_exe_path, "/UNATTENDED"],
            env=_build_igor_launch_env(),
        )
    except Exception as e:
        return {"launched": False, "reason": f"Failed to start the process ({e})."}

    deadline = time.monotonic() + wait_for_ready_seconds
    attempts = 0
    while time.monotonic() < deadline:
        attempts += 1
        if _reachable(timeout_ms=1000):
            return {"launched": True, "zmq_ready": True, "poll_attempts": attempts}
        time.sleep(_POST_LAUNCH_POLL_INTERVAL_SECONDS)

    return {
        "launched": True,
        "zmq_ready": False,
        "poll_attempts": attempts,
        "note": (
            f"The process was started, but nothing answered ZBR#ZBR_Ping within "
            f"{wait_for_ready_seconds:.0f}s. Igor Pro may still be initializing "
            "(slower on first launch or a cold machine), or ZMQ_BridgeHelpers.ipf may "
            "not be #include-d/compiled in whatever experiment this instance opened "
            "by default -- try check_bridge_health() again after waiting longer."
        ),
    }


@mcp.tool()
def load_experiment(
    file_path: str,
    wait_for_ready_seconds: float = 30.0,
    process_exit_timeout_seconds: float = 30.0,
) -> dict:
    """Load an Igor Pro experiment file (.pxp), replacing whatever is currently open.

    **Behavior change from the COM-based version, read carefully**: COM's
    IApplication.LoadExperiment hot-swapped the experiment inside the SAME running
    Igor Pro process. That method is COM-only (confirmed: neither "LoadExperiment"
    nor "OpenFile" appear anywhere in Igor Reference.ihf, only in Automation
    Server.ihf) -- there is no procedure-language equivalent, so this transport
    cannot replicate it. Instead, this tool:

    1. Asks the currently-running instance to quit (`Quit/N`, submitted via
       ZBR_SubmitCommand -- deferred, so this step itself still gets a normal reply
       before Igor actually exits).
    2. Waits for the underlying Igor64.exe **OS process** to fully disappear from the
       process list -- see below for why this can't just check ZeroMQ reachability.
    3. Relaunches the configured Igor Pro executable (see configure_igor_launch) with
       `/UNATTENDED` plus the target file path as a launch argument -- passing a file
       path on launch is documented (Advanced Topics.ihf, "Calling Igor from
       Scripts") to open that specific file.
    4. Polls for the new instance to start answering ZBR#ZBR_Ping, same as
       launch_igor_pro_unattended.

    **Step 2 is not optional, and checking ZeroMQ reachability alone is not enough --
    confirmed live (user report) after an early version of this tool relied on exactly
    that and silently failed.** ZeroMQ goes quiet well before the Igor64.exe process
    actually terminates (Igor can take several seconds to fully exit after `Quit/N`
    runs). If the replacement `Igor64.exe /UNATTENDED <path>` command line is launched
    while the old process is still alive -- even mid-shutdown -- Windows/Igor's
    single-instance-per-user behavior does not spawn a new process at all: it either
    (a) redirects the launch into the still-live old instance, which pops an unhandled
    "save changes?" dialog if it happens to have unsaved edits, or (b) if the old
    instance is already mid-quit, silently drops the request altogether. Case (b) is
    especially deceptive: nothing errors, no new process appears, and the net effect
    looks exactly like the relaunch had no effect whatsoever. This tool instead polls
    the actual OS process list (matching the configured executable's own file name,
    e.g. "Igor64.exe") until no such process remains, up to
    process_exit_timeout_seconds, before ever invoking the relaunch command line. If
    that timeout elapses with the process still present, this raises rather than
    proceeding -- proceeding anyway would just reproduce the same silent-failure risk
    this check exists to prevent. A stuck "save changes?" dialog on the OLD instance
    (e.g. if something modified the experiment after your last save) is the most
    likely cause; check for one by hand if this happens.

    This is a genuine process restart, not an in-place swap. **Any unsaved changes in
    the currently-open experiment are lost** -- call
    execute_igor_command('SaveExperiment') first if that matters (matching the old
    version's own behavior: LoadExperiment never auto-saved either, but there was at
    least still a "hot" instance to save from afterward if you forgot; now there
    isn't).

    Requires configure_igor_launch(exe_path) to have been called first.

    Raises if file_path does not point to an existing file, or if the old Igor Pro
    process does not fully exit within process_exit_timeout_seconds.
    """
    if not _configured_igor_exe_path:
        raise RuntimeError(
            "No Igor Pro executable path configured yet -- call "
            "configure_igor_launch(exe_path) first."
        )

    normalized = os.path.abspath(file_path)
    if not os.path.isfile(normalized):
        raise RuntimeError(f"'{normalized}' does not exist or is not a file.")

    igor_basename_lower = os.path.basename(_configured_igor_exe_path).lower()

    try:
        call_function("ZBR#ZBR_SubmitCommand", ["Quit/N"])
    except (IgorZmqError, IgorZmqUnreachable):
        pass  # nothing was running/reachable to begin with -- nothing to quit

    quit_deadline = time.monotonic() + process_exit_timeout_seconds
    remaining_pids = _list_pids_for_exe_basename(igor_basename_lower)
    while remaining_pids and time.monotonic() < quit_deadline:
        time.sleep(0.5)
        remaining_pids = _list_pids_for_exe_basename(igor_basename_lower)

    if remaining_pids:
        raise RuntimeError(
            f"'{igor_basename_lower}' did not fully exit within "
            f"{process_exit_timeout_seconds:.0f}s of sending Quit/N (PIDs still "
            f"running: {remaining_pids}). Relaunching now would risk silently doing "
            "nothing (see this tool's own docstring) -- check whether the existing "
            "Igor Pro instance is stuck on an unhandled dialog (e.g. 'save changes?' "
            "if something modified the experiment since your last save) and resolve "
            "it by hand, or retry with a longer process_exit_timeout_seconds."
        )

    try:
        subprocess.Popen(
            [_configured_igor_exe_path, "/UNATTENDED", normalized],
            env=_build_igor_launch_env(),
        )
    except Exception as e:
        raise RuntimeError(
            f"Failed to relaunch Igor Pro with {normalized!r}: {e}"
        ) from e

    deadline = time.monotonic() + wait_for_ready_seconds
    attempts = 0
    while time.monotonic() < deadline:
        attempts += 1
        if _reachable(timeout_ms=1000):
            return {
                "loaded_file": normalized,
                "zmq_ready": True,
                "poll_attempts": attempts,
            }
        time.sleep(_POST_LAUNCH_POLL_INTERVAL_SECONDS)

    return {
        "loaded_file": normalized,
        "zmq_ready": False,
        "poll_attempts": attempts,
        "note": (
            f"Process relaunched with {normalized!r}, but nothing answered "
            f"ZBR#ZBR_Ping within {wait_for_ready_seconds:.0f}s. Try "
            "check_bridge_health() again after waiting longer."
        ),
    }


if __name__ == "__main__":
    mcp.run()
