.. _igor_pro_bridge_doc:

===============
Igor Pro Bridge
===============

Description
-----------

The Igor Pro Bridge lets an AI coding agent (Claude, via a local MCP server) control an
already-running Igor Pro instance directly: execute commands, read wave data, edit
``.ipf`` files on disk and recompile them, and inspect the live environment -- without a
human needing to click anything in Igor Pro for routine steps.

The code lives in ``tools/igor-mcp-bridge/``:

- ``server.py``: the MCP server implementation (Python, using ``pyzmq`` to talk to
  Igor Pro's ZeroMQ-XOP, and ``pywin32`` for OS-level window handling and process
  launching only -- see :ref:`igor_pro_bridge_v2_migration` below).
- ``igor-pro-bridge-*.mcpb``: packaged Claude Desktop Extension bundles built from
  ``server.py`` via the `mcpb <https://www.npmjs.com/package/@anthropic-ai/mcpb>`__ CLI.
- ``requirements.txt``: pinned Python dependency versions (see :ref:`igor_pro_bridge_requirements`).
- ``install.ps1``: installs those pinned dependencies into the correct Python
  environment and completes pywin32's post-install step -- see
  :ref:`igor_pro_bridge_installation`.

The companion procedure file ``Packages/MIES/ZMQ_BridgeHelpers.ipf`` (included from
``MIES_Include.ipf``, independent module ``ZBR``) provides the Igor-side functions the
bridge calls into, including an ``AfterCompiledHook`` used to get a more reliable
compile-success signal and to (re)bind the ZeroMQ server socket on every compile; see
:ref:`igor_pro_bridge_zbr_helpers` below.

This is Windows-only tooling for MIES development, not something end users of MIES
interact with.

.. _igor_pro_bridge_v2_migration:

Architecture
------------

As of v2.0.0, the bridge talks to Igor Pro over the
`ZeroMQ-XOP <https://github.com/AllenInstitute/ZeroMQ-XOP>`__'s ``CallFunction``
JSON protocol, over a plain localhost TCP socket (``tcp://127.0.0.1:5680``) -- not
COM. Versions through 1.27.0 instead used Igor Pro's built-in ActiveX Automation
Server (``IgorPro.Application``, documented in ``Igor Pro Folder/Miscellaneous/Windows
Automation/Automation Server.ihf``): the bridge was a COM *client* process that
attached via ``win32com.client.GetActiveObject`` and issued commands through
``Execute2``. See :ref:`igor_pro_bridge_v1_history` for that transport's full design
history, now superseded.

Why this changed: COM required the bridge's Python process and Igor Pro to run at the
*same* Windows privilege level (both elevated, or both not) -- an easy-to-miss
mismatch, e.g. Claude Desktop reopened normally after Igor Pro was left running
elevated from before. ZeroMQ is a plain TCP socket with no such requirement at all --
elevation no longer matters in any way for this bridge, in either direction.

Wire protocol, in brief (see ``server.py``'s own module docstring for the full
detail): the bridge sends one JSON request per round trip --
``{"version": 1, "messageID": ..., "CallFunction": {"name": ..., "params": [...]}}``
-- and receives ``{"errorCode": {"value": ..., "msg": ...}, "result": ...}`` back. A
fresh ZeroMQ REQ socket is created for every call (a REQ socket that times out cannot
send again without being recreated). Function names for anything in the ``ZBR``
independent module must be ``#``-qualified (``"ZBR#ZBR_Ping"``) -- the XOP's own
README says to omit the ``#`` for independent-module functions; that is confirmed
empirically to be wrong. Wave return values carry the *entire* wave (dimensions,
units, note, complex/text/wave-ref support) natively serialized as JSON, and
multi-return Igor functions (``Function [a, b] Foo()``) are supported directly as a
JSON array of typed values.

A central constraint carried over unchanged from the COM design: Igor's ``Execute``
operation cannot run unqueued from inside a Function -- only ``Execute/P`` (deferred)
can. There is therefore no single-round-trip equivalent of COM's ``Execute2`` for
arbitrary free-form command text; ``execute_igor_command``/
``execute_igor_command_unattended`` instead use a submit-then-poll pattern
(``ZBR_SubmitCommand``/``ZBR_SubmitCommandUnattended`` queue the command and return a
token immediately; ``ZBR_PollCommand``, called repeatedly, reports completion and the
captured text). Every other tool that doesn't need arbitrary free-form text is backed
by a small, purpose-built, directly-callable ``ZBR_*`` function instead and needs no
polling.

The bridge checks the reply's ``errorCode.value`` itself and raises a Python
``RuntimeError`` subclass (``IgorZmqError``, or ``IgorZmqUnreachable`` if no reply
arrives at all) when appropriate -- a malformed or failing Igor-level call does not
otherwise surface as a Python exception on its own.

.. _igor_pro_bridge_requirements:

Requirements
------------

- Igor Pro 9.00 or later, running on Windows, with the ZeroMQ-XOP installed and
  loaded. ``RELOAD CHANGED PROCS``, which ``reload_and_compile_procedures`` depends
  on, was introduced in Igor Pro 9.00 and sets the actual minimum version.
- **``Packages/MIES/ZMQ_BridgeHelpers.ipf`` must be ``#include``-d and compiled into
  whichever Igor Pro experiment the bridge talks to.** Unlike the old COM transport
  (which worked against a stock Igor Pro installation with zero custom procedure
  code), there is no bootstrap path over ZeroMQ itself -- if this file isn't
  included/compiled, nothing is listening on the port at all, and every tool call
  fails with ``IgorZmqUnreachable``. This repo's own ``Packages/MIES_Include.ipf``
  already does this permanently. For any *other* Igor Pro experiment: copy
  ``ZMQ_BridgeHelpers.ipf`` onto its own procedure search path, add
  ``#include "ZMQ_BridgeHelpers"`` to that experiment's own include list by hand, and
  recompile -- a one-time, per-experiment setup step. See
  :ref:`igor_pro_bridge_zbr_helpers` for what this file provides.
- Most tools require Igor Pro to already be running; the bridge connects to the
  running instance's ZeroMQ socket. If needed, ``launch_igor_pro_unattended`` can
  start Igor Pro itself (after ``configure_igor_launch``) -- see below.
- **No privilege-matching requirement of any kind.** This is the change v2.0.0 makes
  over the old COM transport: Igor Pro and the bridge's Python process can each run
  elevated or not, independently, with no effect on connectivity -- ZeroMQ is a plain
  localhost TCP socket, not a Windows COM/RPC channel.
- Python 3.10 or later, accessible as ``python`` on ``PATH``, with the pinned packages
  in ``requirements.txt`` (``mcp==1.29.0``, ``pyzmq==27.1.0``, ``pywin32==312``)
  installed into that same environment -- see :ref:`igor_pro_bridge_installation`
  below for how. The packaged extension does not vendor these. ``pywin32`` is still a
  dependency in v2.0.0 -- it is no longer used to talk to Igor Pro, but is still used
  for ``dismiss_compile_error_dialog``'s window enumeration and for launching the
  Igor Pro process.

  ``mcp`` is pinned below its breaking v2.0.0 line (released 2026-07-27/28, protocol
  revision 2026-07-28): v2 renamed ``FastMCP`` to ``MCPServer`` and moved it from
  ``mcp.server.fastmcp`` to ``mcp.server.mcpserver``, among other changes, while
  ``server.py`` still uses the v1 ``from mcp.server.fastmcp import FastMCP`` API. An
  unpinned ``mcp`` dependency (or a plain ``pip install mcp`` today) resolves to v2 and
  breaks the bridge outright (``ModuleNotFoundError``) -- confirmed directly from both
  wheels' contents. Do not lift the ``<2`` upper bound without migrating ``server.py``
  to the v2 API first.

.. _igor_pro_bridge_installation:

Installation
------------

The bridge is distributed as a Claude Desktop Extension (``.mcpb``), not via manual
``claude_desktop_config.json`` editing (which does not work reliably for local MCP
servers in current Claude Desktop builds).

- Build: ``mcpb pack tools/igor-mcp-bridge tools/igor-mcp-bridge/igor-pro-bridge-X.Y.Z.mcpb``
- Install: Claude Desktop -> Settings -> Extensions -> Advanced settings -> Extension
  Developer -> Install Extension, then select the ``.mcpb`` file.
- **Before first use (or whenever a Python dependency changes), run
  ``tools/igor-mcp-bridge/install.ps1`` from an elevated PowerShell** to install the
  pinned packages and complete pywin32's required post-install step
  (``Scripts\pywin32_postinstall.py -install``, which a plain ``pip install`` does not
  do). The script itself must run elevated only because that post-install step
  registers COM-support DLLs into protected system locations -- pywin32 is still a
  dependency for OS-level window handling and process launching (see
  :ref:`igor_pro_bridge_requirements`), even though this bridge no longer uses COM to
  talk to Igor Pro. This elevation requirement is purely install-time and unrelated to
  how you run Claude Desktop or Igor Pro afterward -- neither needs to be elevated at
  runtime. ``install.ps1`` resolves ``python.exe`` from the Machine/User ``PATH``
  registry values directly rather than trusting the invoking shell's own
  possibly-customized ``$env:Path``, to mirror what a freshly launched Claude Desktop
  process actually sees regardless of its own elevation state (not necessarily the
  same interpreter an interactive console session would resolve, e.g. a
  PowerShell-profile-only conda activation, or a Microsoft Store app-execution-alias
  stub that behaves differently once elevated); pass ``-PythonPath`` to override this
  if needed. See ``Get-Help ./install.ps1 -Full`` for the complete rationale and all
  steps performed.
- Separately, ensure ``Packages/MIES/ZMQ_BridgeHelpers.ipf`` is ``#include``-d and
  compiled into whatever Igor Pro experiment you intend to use with the bridge -- see
  :ref:`igor_pro_bridge_requirements`. This repo's own experiments already have this
  via ``MIES_Include.ipf``; any other experiment needs the one-time manual setup step
  described there.
- After installing (or after running ``install.ps1``), fully restart Claude Desktop so
  the updated server code/environment is actually picked up -- newly added tools, or a
  freshly installed dependency, can otherwise lag behind what's on disk.
- Call ``get_bridge_version()`` afterward and confirm its ``python_executable`` field
  matches the interpreter ``install.ps1`` installed into. If it doesn't, Claude Desktop
  resolved a different Python than ``install.ps1`` guessed -- re-run ``install.ps1
  -PythonPath <that path>``.

Available tools
----------------

``execute_igor_command(command, timeout_seconds=30.0)``
  Runs a command string on Igor's command line. **Include a `print` call -- not
  `fprintf 0, ...` -- to get data back** (confirmed live in v2.0.1: Igor's
  ``CaptureHistory``, which this bridge's capture mechanism depends on, captures
  ``print`` output but never captures ``fprintf``-to-history output at all, whether
  directed at refnum 0, -1, or -2 -- the command runs without error either way, but an
  ``fprintf``-only command silently returns empty ``"results"``/``"history"`` every
  time). Returns a dict with ``"results"`` and ``"history"`` -- both now hold the
  *same* captured text (see :ref:`igor_pro_bridge_v2_migration`: this transport
  cannot isolate ``print``-only output from the full echoed history the way COM's
  ``Execute2`` could isolate ``fprintf``-only output). Prefix ``command`` with
  ``Silent 1;`` to suppress the echoed command text from the result. Implemented as
  submit-then-poll
  (``ZBR_SubmitCommand``/``ZBR_PollCommand``), since Igor's ``Execute`` cannot run
  unqueued from inside a Function; ``timeout_seconds`` bounds how long this polls
  before giving up. **Caution**: if ``command`` calls user-defined procedure code and
  the Debugger is enabled, a breakpoint/runtime error/abort/stale-reference pause will
  hang this call indefinitely (the poll loop keeps timing out and retrying, never
  seeing it finish) -- there is no scriptable way to resume or dismiss the Debugger
  window. Prefer ``execute_igor_command_unattended`` whenever nobody is watching who
  could close that popup by hand.

``execute_igor_command_unattended(command, timeout_seconds=30.0)``
  Same as ``execute_igor_command``, but automatically disables Igor's Debugger before
  running the command and restores it afterward, even if the command raises. This is
  the default choice for any unattended/automated call.

  **Neither of the two tools above is suitable for a command with an unknown or long
  runtime** (more than roughly a minute) -- both block the entire MCP tool call while
  polling, and the MCP transport itself has been observed to time out a single tool
  call well under a minute regardless of ``timeout_seconds``. Use
  ``submit_igor_command``/``poll_igor_command`` instead for anything long-running.

``submit_igor_command(command)``
  Queues ``command`` for deferred execution (via ``ZBR_SubmitCommand``) and returns a
  token immediately, without waiting for it to finish. **The tool to reach for when a
  command's runtime is unknown or could be long -- minutes, hours, even weeks.**
  Follow up with ``poll_igor_command(token)``, as many times as needed, spaced
  however far apart in time is convenient.

  Reliable over arbitrarily long horizons because all of the actual state (a done
  flag and the captured output text) lives entirely in Igor Pro's own data waves
  (``root:Packages:ZBR:done``/``resultText``), not in this bridge's own Python
  process -- polling later does not depend on this bridge process staying alive, on
  Claude Desktop staying open, or on any particular amount of time having passed. The
  one thing that *does* end the job is Igor Pro itself quitting, crashing, or
  restarting -- at that point the underlying computation is gone regardless of
  whether the token can still technically be looked up.

  **Caution**: same Debugger-pause risk as ``execute_igor_command``, but more
  consequential here, since a long-running job is by definition likely to be
  unattended -- a pause partway through leaves ``poll_igor_command`` reporting
  "not done" forever, indistinguishable from the command still genuinely running.
  **Use ``submit_igor_command_unattended`` instead for anything long-running.**

  **v2.2.0 reliability fix**: separately from the Debugger, ``command`` failing to
  parse or hitting a genuine Igor-level runtime error partway through used to have
  the exact same "hangs forever" effect, for a different reason -- confirmed live.
  Fixed by queuing the command and the internal finish-callback as independent
  ``Execute/P`` entries instead of one joined string (see SESSION_NOTES.md for the
  full live-tested root cause). ``poll_igor_command`` is now guaranteed to
  eventually report ``done: true`` regardless of whether ``command`` succeeded,
  errored, or failed to parse. **Known residual gap**: there is still no generic
  way to tell "ran and legitimately printed nothing" apart from "errored with no
  output" -- both come back as an empty/short result with no error indication
  (an attempted ``GetRTError()``-based fix was tried and confirmed live not to
  work). Have ``command`` ``print`` an explicit sentinel if success needs to be
  verifiable.

  **v2.2.3 fix**: the finish-callback (``ZBR_FinishToken``) captures its target row
  index at submission time but runs later, in its own deferred entry -- if the
  underlying storage waves are ever resized smaller in between (confirmed live
  during this bridge's own maintenance/cleanup work), the callback's write used to
  throw an uncaught "Index out of range" error and pop a modal dialog, exactly like
  the v2.2.1 bug. Now bounds-checked: if the row no longer exists, the callback
  silently does nothing, and a later ``poll_igor_command`` on that token correctly
  reports ``"ERROR: unknown token ..."`` instead of hanging or crashing.

``submit_igor_command_unattended(command)``
  Same as ``submit_igor_command``, but disables Igor's Debugger for the duration of
  ``command`` and restores it afterward (via ``ZBR_SubmitCommandUnattended``). **The
  recommended tool for anything long-running** -- without it, a Debugger pause has no
  periodic signal distinguishing it from genuine progress, only silence.

``poll_igor_command(token)``
  Checks whether a command submitted via ``submit_igor_command``/
  ``submit_igor_command_unattended`` has finished, and returns its captured output if
  so. Returns ``{"done": false}`` while still pending -- call again later, with no
  limit on how long to wait or how many times to poll. Returns
  ``{"done": true, "results": <text>, "history": <text>}`` once finished (both keys
  hold the same text, matching ``execute_igor_command``'s own return shape -- see its
  entry above for why "results"/"history" can't be kept separate over this
  transport, and why ``print``, not ``fprintf``, is what actually gets captured).
  Raises if ``token`` isn't recognized -- e.g. a typo, or a token from an Igor Pro
  instance that has since quit/restarted (tokens do not survive Igor Pro itself
  restarting, only this bridge process or Claude Desktop restarting). For a job
  expected to run over hours to weeks, consider a scheduled task that calls this
  periodically rather than relying on the conversation staying open. Does **not**
  raise just because the submitted command itself failed to parse or errored --
  see ``submit_igor_command``'s v2.2.0 note above.

``read_session_history(stop=False)``
  Reads back everything sent to Igor's history area since this bridge's capture
  started (via ``ZBR_ReadSessionHistory``, backed by Igor's built-in
  ``CaptureHistoryStart()``/``CaptureHistory()`` functions) -- a capture starts
  automatically, Igor-side, on first use. This can verify *past* executions
  retroactively (e.g. to see everything printed across many separate calls at once).
  Each call returns the full accumulated text since the capture started, so repeated
  calls are always safe. ``stop=True`` ends the current capture and starts a fresh
  one on next use.

``get_wave(wave_path)``
  Returns an existing Igor wave's full data and metadata: ``type``, ``dim_size``
  (1 to 4 dimensions), ``data`` (nested Python lists matching the wave's own
  dimensionality), ``unit``, ``note``, and per-dimension ``dimension`` info. Supports
  any dimensionality, and real, complex, text, and wave-reference waves -- a
  **capability expansion over v1.x**, which was limited to 1D real-valued waves read
  one point at a time via COM. The entire wave comes back in a single round trip,
  natively serialized by the ZeroMQ-XOP.

``load_experiment(file_path, wait_for_ready_seconds=30.0, process_exit_timeout_seconds=30.0)``
  Loads an Igor Pro experiment file (``.pxp``), replacing whatever is currently open.
  **Behavior change from v1.x**: COM's ``IApplication.LoadExperiment`` hot-swapped the
  experiment inside the same running Igor Pro process; that method has no
  procedure-language equivalent (confirmed: neither ``LoadExperiment`` nor
  ``OpenFile`` appear anywhere in ``Igor Reference.ihf``, only in
  ``Automation Server.ihf``), so this transport cannot replicate it. Instead, this
  tool asks the running instance to quit (``Quit/N``, submitted via
  ``ZBR_SubmitCommand``), waits for the underlying Igor64.exe **OS process** to fully
  exit, then relaunches the configured Igor Pro executable (see
  ``configure_igor_launch``) with ``/UNATTENDED`` plus the target file path as a
  launch argument, and polls for the new instance to become reachable. This is a
  genuine process restart, not an in-place swap -- **unsaved changes in the
  currently-open experiment are lost**; call ``execute_igor_command('SaveExperiment')``
  first if that matters. Requires ``configure_igor_launch`` to have been called first.
  Call ``get_environment_summary()`` afterward, since loading a different experiment
  changes everything about the live environment.

  **v2.0.1 fix, root-caused from a live silent-failure report**: an earlier version of
  this tool waited only for Igor Pro to stop answering ``ZBR_Ping`` over ZeroMQ as its
  signal that the old process was gone, then immediately launched the replacement
  ``Igor64.exe /UNATTENDED <path>`` command line. This does not work: ZeroMQ goes
  quiet well before the underlying OS process actually terminates (Igor can take
  several seconds to fully exit after ``Quit/N`` runs), and launching the replacement
  command line while the old process is still alive -- even mid-shutdown -- does not
  spawn a new process at all. Windows/Igor's single-instance-per-user behavior instead
  either (a) redirects the launch into the still-live old instance, which can pop an
  unhandled "save changes?" dialog if it happens to have unsaved edits, or (b) if the
  old instance is already mid-quit, silently drops the request altogether -- which
  looks exactly like the relaunch had no effect whatsoever, with nothing to diagnose
  (no error, no new process, `check_bridge_health()` just reports unreachable
  indefinitely). Fixed by polling the actual Windows process list (matching the
  configured executable's own file name, e.g. ``"Igor64.exe"``) until no such process
  remains, up to ``process_exit_timeout_seconds``, before ever invoking the relaunch
  command line; if that timeout elapses with the process still present, the tool now
  raises rather than silently proceeding into the same failure mode -- the most likely
  cause being a stuck "save changes?" dialog on the *old* instance, which needs a human
  to resolve by hand.

  **v2.2.1 fix, root-caused from another live report**: reloading a saved experiment
  via this tool (or a human manually reopening a ``.pxp``) could leave the whole
  bridge unreachable, requiring a human to dismiss a modal Igor error dialog reading
  "While executing CaptureHistory, the following error occurred: there is no open
  file with this reference number". Root cause: this bridge's history-capture
  mechanism stores its ``CaptureHistoryStart()`` reference number in a plain
  ``Variable/G`` global, which Igor persists into a saved experiment like any other
  global -- but the refnum is only meaningful within the OS process that created it,
  so reloading brought back a stale-but-present value that the old code trusted
  simply because it existed. Fixed Igor-side (``ZBR_EnsureCaptureStarted`` in
  ``ZMQ_BridgeHelpers.ipf``): the stored refnum is now validated with a
  ``try``/``catch``/``endtry`` block before being trusted, and silently replaced with
  a fresh capture if it's stale, rather than ever surfacing this to the user. No
  Python-side change was needed. See ``SESSION_NOTES.md`` for the full live-tested
  root cause and the two Igor syntax mistakes caught and fixed along the way.

  **v2.2.2 refinement** (contributed by the repo owner after installing v2.2.1): the
  stale-refnum probe call and its ``AbortOnRTE`` are kept on the SAME line rather
  than split across two, because Igor's Debug on Error check happens at the end of
  each *line*, not each statement -- on separate lines, a user with Debug on Error
  enabled would get a Debugger popup right when the stale refnum's runtime error
  occurred, before ``AbortOnRTE`` had a chance to convert it into a catchable abort.
  Confirmed live (before and after) by temporarily enabling ``debug_on_error`` and
  repeating the corrupted-refnum test: only the same-line version stays silent.

``check_bridge_health()``
  Diagnoses whether the bridge can reach Igor Pro's ZeroMQ server right now. Unlike
  the old COM-based version, this can no longer cleanly distinguish "Igor Pro isn't
  running" from "``ZMQ_BridgeHelpers.ipf`` isn't included/compiled/bound" from "wrong
  port/firewall" -- a ZeroMQ REQ socket that gets no reply at all looks the same in
  all three cases; the ``"problem"`` field lists all three as things to check by
  hand. Run this first whenever something doesn't work.

``get_bridge_version()``
  Returns the version of this Igor Pro Bridge build that is actually running in the
  current Claude Desktop session, plus which Python interpreter/packages it's actually
  running with::

      {
        "version": "2.1.0",
        "python_executable": "C:\\Python312\\python.exe",
        "python_version": "3.12.4",
        "mcp_package_version": "1.29.0",
        "pyzmq_version": "27.1.0"
      }

  Useful before relying on a specific recent fix or behavior change, or to confirm
  which ``.mcpb`` build ended up loaded after an install/restart. The
  ``python_executable`` field is also the authoritative way to confirm which Python
  environment Claude Desktop actually launched the bridge with, e.g. to cross-check
  against what ``install.ps1`` installed into -- see
  :ref:`igor_pro_bridge_installation`.

``check_compilation_state()``
  Reports whether Igor's procedure code is currently compiled or uncompiled, via
  ``ZBR_IsCompiled()`` (the same ``FunctionInfo``-based technique as
  ``IsProcGlobalCompiled()`` in
  ``Packages/igortest/procedures/igortest-test-compilation.ipf``). Since ``ZBR``
  compiles as its own independent module, a ``true`` result here specifically reflects
  ProcGlobal's compile state -- reaching ``ZBR`` at all over ZeroMQ already implies
  ``ZBR`` itself is compiled.

``reload_and_compile_procedures()``
  Forces Igor to reload changed ``.ipf`` files from disk (``RELOAD CHANGED PROCS``) and
  attempt a fresh compilation (``COMPILEPROCEDURES``, via ``ZBR_SubmitReloadAndCompile``),
  then reports the resulting compiled state. Use this after editing a ``.ipf`` file
  directly on disk. Both commands go through Igor's operation queue rather than
  running immediately (see "Operation Queue" in ``Advanced Topics.ihf``), so this
  cross-checks two independent signals before trusting a "compiled" result -- see
  :ref:`igor_pro_bridge_zbr_helpers` and :ref:`igor_pro_bridge_compile_dialog`. Poll
  errors (the bridge briefly unable to reach Igor mid-recompile) are treated as "not
  ready yet" rather than fatal. If compilation still isn't confirmed after the poll
  times out, this automatically makes one attempt to dismiss a possible stuck
  compile-error dialog (see ``dismiss_compile_error_dialog``). **Caution, carried
  over from the COM-based version**: Igor Pro has been observed becoming
  unreachable shortly after a reload/compile attempt on more than one occasion
  during this bridge's development (crashed or was closed). As of **v2.3.0**,
  crash-dump analysis (two ``.dmp`` files, parsed with Python's ``minidump``
  package) traced this to a genuine ``EXCEPTION_ACCESS_VIOLATION`` deep inside
  ``Igor64.exe`` itself, not this bridge's own code, and a likely mechanism was
  identified by comparing against this repo's own ``igortest-tracing.ipf``
  (whose ``CompileAndRestart()``/``AfterCompiledHook()`` pattern never crashes):
  this bridge's ZeroMQ-XOP handler runs as a background thread that keeps
  dispatching incoming ``CallFunction`` requests regardless of what Igor's main
  thread is doing, so a request arriving while ``COMPILEPROCEDURES`` is
  mid-rebuild of Igor's own internal function/symbol tables is a plausible
  cross-thread race. v2.3.0 mitigates this by stopping the ZeroMQ handler
  (``zeromq_handler_stop()``, via ``ZBR_StopHandlerBeforeRecompile``) before
  ``RELOAD CHANGED PROCS``/``COMPILEPROCEDURES`` run, and restarting it only
  after compilation finishes (the existing ``AfterCompiledHook`` ->
  ``ZBR_EnsureZeroMQBound()`` call, unchanged). This is a well-reasoned
  mitigation, not a proven fix -- ``Igor64.exe`` ships no public symbols, so the
  exact fault can't be confirmed from here, and the crash was already
  rare/nondeterministic. Confirmed live afterward, including three concurrent
  ``reload_and_compile_procedures()`` calls as a stress test with no crash. If a
  tool call after this one starts failing anyway, check
  ``check_bridge_health()`` and be prepared for Igor Pro to need relaunching.
  See ``SESSION_NOTES.md`` for the full investigation.

``dismiss_compile_error_dialog()``
  Attempts to close a stuck Igor Pro dialog by posting a simulated Escape key press
  directly to it (via ``PostMessage``), targeting a visible window owned by an Igor
  Pro process whose title matches a known stuck-dialog title -- this does **not**
  require or change OS focus/foreground state. **Confirmed live against both Igor
  Pro 10.03 and Igor Pro 9.06**: the compile-error dialog is titled exactly
  *"Function Compilation Error"* and is a Qt window (class ``"Qt693QWindowIcon"``
  on 10.03), not a native ``"#32770"`` dialog -- title matching is what actually
  finds it on both major versions, and a *posted* (not real hardware) Escape
  successfully closed it in both cases, with no focus/foreground change needed. An
  earlier version also matched any generic native ``"#32770"`` dialog regardless of
  title; removed after a Copilot PR review correctly flagged it as a real risk (this
  is called automatically from ``reload_and_compile_procedures``, so it could have
  Escape-dismissed an unrelated native dialog, e.g. a save-changes confirmation) and
  it was never actually needed, since the real dialog isn't ``"#32770"`` anyway.
  Does **not** recover the actual error message -- it only clears the dialog so work
  can continue. See :ref:`igor_pro_bridge_compile_dialog`.

``get_debugger_state()`` / ``set_debugger_enabled(enabled, ...)`` / ``restore_debugger_settings()``
  Read, change, and restore Igor's Debugger settings (``DebuggerOptions``). Use
  ``get_debugger_state()`` to snapshot the current settings before a longer unattended
  session, ``set_debugger_enabled(False)`` to disable the Debugger for the run, and
  ``restore_debugger_settings()`` to put things back afterward.

``get_environment_summary()``
  Summarizes the live instance: Igor version/build, the loaded experiment, loaded XOPs,
  currently included procedure files (with a category breakdown), the contents of the
  always-present "Procedure" window (which can carry experiment-specific
  ``#include``/``#define`` directives not present in any on-disk ``.ipf`` file), the
  top-level global data folder layout, and the current Debugger settings.

``read_help_file(file_path, timeout_ms=30000)``
  Reads an Igor Pro help file (``.ihf``) as structured, formatted text -- e.g. to
  confirm an operation's exact flags/behavior straight from Igor's own docs -- without
  leaving any lasting change to Igor's help-window state. ``timeout_ms`` defaults to
  30s rather than this bridge's usual 5s (**fixed in v2.0.1** after a live timeout
  reading the entire "Igor Reference.ihf" manual -- exporting a genuinely large help
  file as HTML can take longer than 5s even though the export itself succeeds
  Igor-side regardless; a timed-out client also leaves the ZeroMQ-XOP logging a
  harmless but noisy "Host unreachable" error to history when it tries to reply to a
  socket that already gave up, visible via ``read_session_history`` if this happens).
  Pass a larger value still for unusually large help files. Better than an OS-level file
  read for two reasons. First, Igor pre-registers every ``.ihf`` file in the Help Files
  folder as an open help window (visible or hidden, ``WinList``'s ``WIN:512`` bit), and
  a help-file view and a plain-notebook view of the same file are mutually exclusive
  (``OpenNotebook/R`` fails with error 251 otherwise) -- this tool handles the required
  ``CloseHelp/ALL`` -> ``OpenNotebook/R`` -> ``SaveNotebook`` export -> ``KillWindow/Z``
  -> ``OpenHelp`` restore dance, entirely in a ``finally`` block so a mid-sequence
  failure still restores whatever help state existed beforehand. Second, and more
  importantly: the returned ``"paragraphs"`` list (``[{"style": "Topic", "text":
  "Debugging"}, ...]``) preserves the paragraph style name WaveMetrics' own help
  authoring convention assigns to nearly every paragraph (e.g. ``"Topic"`` for a section
  heading, ``"Code1"`` for a line of example code, ``"Steps"`` for a bullet item) --
  genuine content-block structure, not just flat prose. Not every XOP ships its own
  help file this way -- some (e.g. the JSON XOP used elsewhere in this codebase) have
  none at all and require external documentation instead; check
  ``get_environment_summary()``'s ``loaded_xops`` field plus the global (``Igor
  Application``) and user-specific (``Igor Pro User Files``) ``Igor Help Files``
  folders (both resolved via Igor's own ``SpecialDirPath`` function) before assuming a
  given XOP has one.

``configure_igor_launch(exe_path)``
  Records the full path to the Igor Pro executable to use for
  ``launch_igor_pro_unattended``/``load_experiment``, for the rest of this bridge
  process's session. There is no default or guessed path -- whatever agent is driving
  the bridge should ask the user for this once, at the start of a session that might
  need to launch Igor Pro, since the install location and version vary (this repo
  alone has been tested against separately-named Igor Pro 9 and Igor Pro 10 installs).
  Session-scoped: resets if the bridge process itself restarts.

``launch_igor_pro_unattended(wait_for_ready_seconds=30.0)``
  Launches the configured executable with the ``/UNATTENDED`` command-line flag (see
  :ref:`igor_pro_bridge_unattended_flag` below) and polls for it to become reachable
  over ZeroMQ. Requires ``configure_igor_launch`` to have been called first in the
  same session. Refuses to launch (returns ``"launched": false`` rather than raising)
  if something already answers ``ZBR_Ping`` right now, since launching the executable
  again with only ``/UNATTENDED`` (no ``/I``, ``/X``, ``/SN``, or file-path argument)
  is documented to start a genuinely new instance rather than reuse the existing one
  -- see "Calling Igor from Scripts" in ``Advanced Topics.ihf``.

  **Always launches as a plain child process** (``subprocess.Popen``), at whatever
  privilege level the bridge's own Python process is running at -- no elevation
  request, no UAC prompt, ever. This is the key v2.0.0 change: the old COM-based
  version branched on whether this process was already elevated, using a direct
  child-process launch (inheriting elevation with no prompt) when it was, or
  ``ShellExecute``'s ``"runas"`` verb (triggering a UAC consent dialog, and leaving
  this process itself still unelevated afterward -- see :ref:`igor_pro_bridge_v1_history`)
  when it wasn't. Neither branch is needed anymore: ZeroMQ has no privilege-matching
  requirement at all, so there is nothing left to branch on.

  Patches ``COMSPEC`` into the child's environment if this Python process's own
  environment is missing it -- confirmed necessary during this bridge's development:
  without it, MIES's own startup hook (``IgorStartOrNewHook`` -> ... ->
  ``ExecuteGitForMIESVersion``, which shells out to git via ``ExecuteScriptText``
  using ``GetCmdPath()``/``COMSPEC`` to find ``cmd.exe``) asserted on every launch via
  this path with *"We have git installed but could not regenerate version.txt"*, even
  though a normal double-click/Start Menu launch never hits it (an interactive login
  session always has ``COMSPEC`` set). See ``SESSION_NOTES.md`` for the full
  diagnosis.

.. _igor_pro_bridge_unattended:

Unattended execution caveats
-----------------------------

Two independent things can silently stall an automated Claude/Igor session. Neither
hangs the bridge's own ZeroMQ calls directly -- both instead leave Igor showing a GUI
element that only a human can dismiss.

Debugger pauses
~~~~~~~~~~~~~~~~

If the Debugger is enabled and something trips it (a breakpoint, a runtime error with
"Debug on Error", a user abort, or a stale NVAR/SVAR/WAVE reference), Igor pauses and
opens the Debugger window. There is no documented operation to programmatically
resume, step, or dismiss that pause -- ``Debugger``/``DebuggerOptions`` are the only two
documented operations, and neither has a "continue" mode. The submitted command that
triggered the pause never reports as finished, so
``execute_igor_command``/``execute_igor_command_unattended``'s poll loop keeps timing
out and retrying forever. Other new ``CallFunction`` calls still get answered while
paused (Igor's command line stays reentrant), but the
original call, and anything waiting on it, is stuck for good.

Mitigation: ``execute_igor_command_unattended`` disables the Debugger for the duration
of each call automatically. For a longer session, bracket it with
``get_debugger_state()`` / ``set_debugger_enabled(False)`` at the start and
``restore_debugger_settings()`` at the end instead.

.. _igor_pro_bridge_compile_dialog:

Compile-error dialogs
~~~~~~~~~~~~~~~~~~~~~~

Separately, a failed ``COMPILEPROCEDURES`` can leave a compile-error dialog open. This
does not hang the bridge's ZeroMQ calls (they keep returning normally), but it does
block Igor's operation queue from ever draining -- confirmed from ``Advanced
Topics.ihf``, "Operation Queue": "Igor services the operation queue when no
procedures are running and the command line is empty." A modal dialog means Igor is
never idle, so ``RELOAD CHANGED PROCS``/``COMPILEPROCEDURES`` queued by a later call
sit there without ever actually running -- ``reload_and_compile_procedures`` will keep
reporting "not compiled" even after the underlying ``.ipf`` file is genuinely fixed,
until a person closes that dialog by hand.

There is no documented way to detect or dismiss this dialog via the ``CallFunction``
protocol (Igor's own compiled code can't observe or interact with its own modal
dialogs), but Escape closes it. ``dismiss_compile_error_dialog()`` exploits that: it
enumerates top-level windows for a visible one owned by an Igor Pro process whose
title matches a known stuck-dialog title, then posts ``WM_KEYDOWN``/``WM_KEYUP`` for
Escape directly to it via ``PostMessage`` -- no foreground switch, no stolen focus.
This is pure OS-level window handling (``pywin32``), independent of whichever
transport talks to Igor Pro's procedure code. **One caveat carried over from the old
COM-based elevation requirement, now the other way around**: since v2.0.0 no longer
requires the bridge to run elevated, if a user chooses to run Igor Pro elevated for
some unrelated reason while the bridge itself is not, Windows' UIPI will block this
posted key press from reaching Igor Pro's window at all (simulated input from a
lower-privilege process cannot reach a higher-privilege one) -- in that specific case,
the bridge process itself would need to be run elevated too for this one tool to
keep working, even though nothing else about the ZeroMQ transport requires it.

**Confirmed live against a real stuck dialog on both Igor Pro 10.03 and Igor Pro
9.06**: the original assumption that this dialog is an ordinary ``"#32770"``
native dialog was wrong -- Igor Pro's UI (on both major versions tested) is
Qt-based, and the compile-error dialog is a Qt window titled exactly *"Function
Compilation Error"* on both (observed class on 10.03: ``"Qt693QWindowIcon"``, a
version-hash-looking string not worth matching on directly). Title matching is what
actually finds it, and a *posted* Escape (not a real hardware key press) was
confirmed to close it on both versions -- Qt's Windows platform layer reacts to the
posted message the same way it would a real key press. An earlier version also
matched any window with the generic native ``"#32770"`` dialog class regardless of
title; removed after a Copilot PR review correctly flagged it as a real risk, since
this is called automatically from ``reload_and_compile_procedures`` and could have
Escape-dismissed an unrelated native dialog (e.g. a save-changes confirmation) --
and it was never actually needed, since the real dialog isn't ``"#32770"`` on
either version tested. If a future window's title doesn't match, dismissal safely
reports "not found" (along with a diagnostic list of
every window Igor currently owns) rather than doing something incorrect. The
trade-off either way: this recovers the ability to continue working, not the actual
error message -- check the ``.ipf`` file's syntax directly, or have a human read the
dialog text, if the exact message matters. ``reload_and_compile_procedures`` now
calls this automatically once, before falling back to asking a human.

If the automatic attempt doesn't resolve it (or wasn't possible -- e.g. no matching
dialog window was found), ``reload_and_compile_procedures``'s result includes
``"auto_dismiss_attempted"`` (the full ``dismiss_compile_error_dialog()`` result, so
its ``"attempted"``/``"igor_windows_seen"`` fields can be inspected directly) plus a
``"note"`` explaining that this looks like a genuine compile error rather than a
timing artifact. Whatever is driving the bridge (e.g. an AI agent) should treat a
``"compiled": false`` result with ``"auto_dismiss_attempted": {"attempted": false, ...}``
as a signal to ask the human operator to check for and close a stuck dialog by hand,
rather than silently retrying or only logging advisory text -- that distinction was
confirmed in practice to be what actually keeps an agent-driven/unattended workflow
moving.

.. _igor_pro_bridge_unattended_flag:

The ``/UNATTENDED`` launch flag and compile errors
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Igor Pro's own ``/UNATTENDED`` command-line flag (added in Igor Pro 9.00; see
"Calling Igor from Scripts" in ``Advanced Topics.ihf``) is documented only as
suppressing "certain interactions that are inconvenient for unattended
operations," with two concrete documented examples: the About Autosave dialog, and
(Igor Pro 10+) the license activation dialog. Nothing in Igor's help files ties it
to compile errors specifically.

Empirically confirmed against a live Igor Pro 9.06 instance launched with
``/UNATTENDED``: it *also* suppresses the modal "Function Compilation Error" dialog
described above. A genuine syntax error introduced into an actually-loaded procedure
file produced ``reload_and_compile_procedures`` results of ``compiled: false`` (per
both the ``ZBR_ReadCompileCounter`` and ``ZBR_IsCompiled`` signals), while
``dismiss_compile_error_dialog``'s diagnostic window enumeration found no dialog
window at all -- only Igor's main window was visible. Instead, the compile error
appears as a plain line in Igor's history area, in the form
``<file>:<line>:<col>: error: <message>`` (e.g.
``ZMQ_BridgeHelpers.ipf:46:7: error: expected terminating quote``), fully readable
via ``read_session_history``/the per-call ``history`` field.

This makes an Igor Pro instance started with ``/UNATTENDED`` (e.g. via
``launch_igor_pro_unattended``) strictly better for this bridge's purposes than one
started normally: there is no dialog to dismiss at all, and the exact error message
is available programmatically, which the dialog-dismissal path never provided (it
only recovers the ability to continue, never the message itself). A bridge session
driving an ``/UNATTENDED`` Igor Pro instance should never need
``dismiss_compile_error_dialog`` in the first place.

Methodological note: verify a target ``.ipf`` file is actually part of the
currently-loaded environment (``get_environment_summary()``'s
``included_procedure_files``) before editing it to test compile behavior. An
earlier attempt at this same test edited a file that turned out not to be included
in the loaded environment at all (no experiment file was open), so no compile ever
actually occurred -- which superficially looked like a real ``/UNATTENDED``
behavior change but was really a no-op test. See ``SESSION_NOTES.md`` for the full
account.

.. _igor_pro_bridge_runtime_errors:

Igor's runtime error model (why a failure doesn't mean execution stopped)
---------------------------------------------------------------------------

With the Debugger disabled, an unhandled runtime error does not stop execution: it sets
Igor's internal runtime-error flag (readable via ``GetRTError(0)``, without clearing
it) and execution continues completely normally -- every subsequent line runs,
including side effects, all the way to the end of the function, unless something
explicitly checks the flag (see "Runtime Error / Abort Handling Conventions" in
:doc:`developers` for the project's ``AbortOnRTE``/``try``/``catch``
conventions). If nothing ever checks it, the flag persists until execution unwinds all
the way back to the top-level command boundary -- i.e. the submitted command run via
``ZBR_SubmitCommand``/``ZBR_SubmitCommandUnattended`` -- which reports it as that
command's own failure, carrying the *original* error code and message. This boundary
check also clears the flag afterward, so a failure here never contaminates the next
command.

The flag is "sticky": if two *different* unhandled runtime errors occur in sequence
with nothing checking/clearing in between, only the *first* one is ever visible --
matching Igor's own documented caveat that ``GetErrMessage`` can be "incomplete" when
multiple errors occur.

Practical consequence: a nonzero error code from ``execute_igor_command``/
``execute_igor_command_unattended`` means at least one problem occurred and reports it,
but does **not** mean execution stopped there, and does **not** mean it was the only
problem.

.. _igor_pro_bridge_zbr_helpers:

ZMQ_BridgeHelpers.ipf and the ZBR module
-------------------------------------------

``Packages/MIES/ZMQ_BridgeHelpers.ipf``, included from ``MIES_Include.ipf``, is no
longer a throwaway prototype -- it is the permanent Igor-side dependency of this
bridge as of v2.0.0, providing every ``ZBR_*`` function ``server.py`` calls via
``CallFunction``. Its own header comment documents the manual, one-time ``#include``
delivery model (see :ref:`igor_pro_bridge_requirements`): this repo's own
``MIES_Include.ipf`` includes it permanently, but any other experiment needs its own
copy plus its own ``#include`` added by hand.

It compiles as its own independent module (``#pragma IndependentModule = ZBR``),
which is why every ``CallFunction`` name for one of its functions must be
``#``-qualified (``"ZBR#ZBR_Ping"``, not ``"ZBR_Ping"``) -- see
:ref:`igor_pro_bridge_v2_migration`. This also means a compile error inside
``ZMQ_BridgeHelpers.ipf`` itself fails the *whole* experiment's compile (an
independent module is not somehow exempt from that), even though it compiles
separately from ProcGlobal.

Compile-confirmation counter, migrated from MIES_ClaudeHelper.ipf
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``ZMQ_BridgeHelpers.ipf`` defines a static ``AfterCompiledHook`` that increments
``root:gClaudeHelperCompileCounter`` (the global name, and the counter's role, carried
over unchanged from this repo's older ``MIES_ClaudeHelper.ipf``, which no longer
exists as a separate file):

.. code-block:: igorpro

   static Function AfterCompiledHook()
       Variable modifiedBefore
       Variable/G root:gClaudeHelperCompileCounter
       NVAR gClaudeHelperCompileCounter = root:gClaudeHelperCompileCounter

       modifiedBefore = GetDataFolderDF(...)... // ExperimentModified state captured here

       ZBR_EnsureZeroMQBound()

       gClaudeHelperCompileCounter += 1

       return 0
   End

``AfterCompiledHook`` is a predefined Igor hook that Igor calls only after *all*
procedure windows have compiled successfully. Unlike polling ``FunctionInfo()`` for a
non-existing function (which can read stale state before Igor's operation queue has
actually drained -- see :ref:`igor_pro_bridge_compile_dialog`), this counter only ever
changes at the exact moment Igor itself confirms a successful compile, so it is a
race-free confirmation signal, read back via ``ZBR_ReadCompileCounter()``.
``reload_and_compile_procedures`` reads a baseline before issuing
``RELOAD CHANGED PROCS``/``COMPILEPROCEDURES`` and treats any increase as immediate,
trustworthy success, falling back to the ``ZBR_IsCompiled()``-based poll when the
counter is unavailable. There is no equivalent hook for a *failed* compile. Declared
``static`` so it coexists with any other file's own static ``AfterCompiledHook``
without colliding.

Auto-binding the ZeroMQ server socket on every compile
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The same hook also calls ``ZBR_EnsureZeroMQBound()``, which (re)binds the ZeroMQ-XOP's
server socket to ``ZBR_ZEROMQ_ENDPOINT`` (``tcp://127.0.0.1:5680``) and starts its
handler every time Igor finishes a successful compile:

.. code-block:: igorpro

   static Function ZBR_EnsureZeroMQBound()
       Variable err
       zeromq_server_bind(ZBR_ZEROMQ_ENDPOINT); err = GetRTError(1)
       zeromq_handler_start(); err = GetRTError(1)
       return 0
   End

Two corrections were made to the first draft of this function, both confirmed to
matter in practice: it does **not** call ``zeromq_stop()`` first (that would tear down
and corrupt any *other* ZeroMQ binds already active in the same experiment on every
recompile -- e.g. MIES's own, currently short-circuited, ZeroMQ subsystem on a
different port); and each XOP call is followed by ``; err = GetRTError(1)`` on the
*same line* specifically to suppress a theoretical Debugger popup, since "Debug on
Error" only checks for a pending runtime-error state at the end of a line, not
mid-statement. ``ZBR_EnsureZeroMQBound()`` is called from ``AfterCompiledHook``
immediately after the pre-compile ``ExperimentModified`` state is captured (needed so
that binding a socket -- itself an experiment-modifying action, from Igor's
perspective -- doesn't get misattributed as user-driven unsaved-changes state).

Why this replaces the old ``#ifdef IGOR_PRO_BRIDGE`` convention
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The v1.x COM-based bridge's ``MIES_ClaudeHelper.ipf`` gated its entire function body
behind ``#ifdef IGOR_PRO_BRIDGE``, activated either by hand-editing the experiment's
Procedure window or via the (now-retired) ``ensure_igor_pro_bridge_defined`` tool --
see :ref:`igor_pro_bridge_v1_history`. ``ZMQ_BridgeHelpers.ipf``'s independent-module
architecture has no equivalent gating at all: everything in the ``ZBR`` module
compiles unconditionally whenever the file is included, by design (the whole point of
an independent module is that its own compilation doesn't depend on ProcGlobal's
``#define`` state). This is strictly simpler for this bridge's own purposes, but it is
also *why* the one-time manual ``#include`` step in
:ref:`igor_pro_bridge_requirements` can't be skipped programmatically the way the old
``#define`` could -- there is no bootstrap tool call over ZeroMQ that could add an
``#include`` directive to a `.ipf` file on disk and trigger Igor to notice it; that
step is inherently a one-time, human, on-disk action.

Known limitations
------------------

- No scriptable way to resume a Debugger pause -- this requires a human, as described
  above. A compile-error dialog can usually be auto-dismissed via a posted Escape key
  press (see ``dismiss_compile_error_dialog``, confirmed live), but that recovers the
  ability to continue, not the error message itself; if a genuinely new/different
  Igor popup shows up (not the known "Function Compilation Error" title), dismissal
  safely reports "not found" and a human is still needed -- title matching only,
  deliberately, since matching any generic native dialog risked dismissing an
  unrelated one (e.g. a save-changes confirmation).
- ``execute_igor_command``/``execute_igor_command_unattended`` can no longer separate
  ``print``-only output from the full echoed history the way COM's ``Execute2`` could
  isolate ``fprintf``-only output -- both ``"results"`` and ``"history"`` now hold the
  same captured text (see :ref:`igor_pro_bridge_v2_migration`). Also,
  **use `print`, never `fprintf 0/-1/-2, ...`, to get data back** -- confirmed live
  (v2.0.1) that ``fprintf``-to-history output is never captured at all by this
  transport's ``CaptureHistory``-based mechanism, regardless of which refnum it
  targets.
- ``load_experiment`` needs the OLD Igor Pro process to fully exit (not just stop
  answering over ZeroMQ) before relaunching with the new file -- fixed in v2.0.1 after
  a live silent-failure report; see that tool's reference entry above for the full
  mechanism.
- ``load_experiment`` is a real process restart (quit + relaunch with a file-path
  argument), not an in-place experiment swap -- unsaved changes in the previously-open
  experiment are lost. See that tool's own reference entry above.
- The ZeroMQ-XOP's Router (server) socket documents a default
  ``ZMQ_MAXMSGSIZE`` of 1024 bytes; whether this caps incoming requests only, or also
  outgoing replies, has not been confirmed. Treated as a risk specifically for
  ``read_help_file``'s underlying ``ZBR_ReadHelpFile``, which sidesteps the question
  entirely by writing the exported HTML to a local temp file (both Igor Pro and the
  bridge run on the same machine) and reading it back off disk, rather than returning
  the HTML content through the ``CallFunction`` reply itself. No other tool in this
  bridge returns a payload large enough for this to plausibly matter, but it hasn't
  been stress-tested.
- This is a *local* MCP server (stdio transport): it only works from a Claude Desktop
  session running on the same Windows machine as Igor Pro, not from a cloud/sandboxed
  session.
- **Observed on more than one occasion during this bridge's development (both under
  the v1.x COM transport and v2.0.0's ZeroMQ transport)**: Igor Pro became unreachable
  (crashed or was closed) shortly after a ``reload_and_compile_procedures`` call. As
  of **v2.3.0**, this was traced via crash-dump analysis to a genuine
  ``EXCEPTION_ACCESS_VIOLATION`` inside ``Igor64.exe`` itself, with a likely
  mechanism identified (confirmed correct by the repo owner's comparison against
  ``igortest-tracing.ipf``'s crash-free ``CompileAndRestart()``/``AfterCompiledHook()``
  pattern): the ZeroMQ-XOP's background message-handler thread dispatching a
  ``CallFunction`` request while Igor's main thread is mid-``COMPILEPROCEDURES``,
  racing on Igor's own internal function/symbol tables. v2.3.0 mitigates this by
  stopping the handler before reload/compile and restarting it only after
  compilation finishes -- see the ``reload_and_compile_procedures()`` reference entry
  above for the full mechanism and the caveat that this is a mitigation, not a
  proven fix. Treat any unreachability after a compile attempt as a signal to check
  ``check_bridge_health()`` and be prepared to relaunch Igor Pro. See
  ``SESSION_NOTES.md`` for the full investigation.

.. _igor_pro_bridge_v1_history:

Version history (v1.x, COM-based transport)
----------------------------------------------

Versions through 1.27.0 used Igor Pro's COM Automation Server instead of ZeroMQ (see
:ref:`igor_pro_bridge_v2_migration` for why this changed). Key milestones, newest
first, kept here for reference since the design decisions behind them (Igor's runtime
error model, the Debugger/compile-dialog caveats, the submit/poll necessity) all
carried forward unchanged into v2.0.0:

- **v1.27.0**: corrected an overstated elevation requirement -- confirmed empirically
  that COM only required client and server to run at the *same* privilege level, not
  that elevation itself was mandatory.
- **v1.26.0**: added ``ensure_igor_pro_bridge_defined`` (retired in v2.0.0 -- see
  :ref:`igor_pro_bridge_zbr_helpers`), managing the ``IGOR_PRO_BRIDGE``
  conditional-compilation symbol via ``SetIgorOption poundDefine``.
- **v1.25.0**: pinned Python dependencies via ``requirements.txt`` and added
  ``install.ps1``; discovered and worked around the MCP Python SDK's breaking v2.0.0
  line (unrelated to this bridge's own v2.0.0 -- a naming coincidence between the
  ``mcp`` package's major version and this project's own).
- **v1.24.0**: added ``read_help_file``.
- **v1.22.0**: added ``get_bridge_version``.
- **v1.17.0**: added ``load_experiment`` (via the COM-only ``IApplication.LoadExperiment``
  method, superseded in v2.0.0 by a relaunch-based implementation -- see that tool's
  current reference entry above).
- **v1.15.0 and earlier**: initial ``execute_igor_command``/``get_wave``/
  ``check_compilation_state``/``reload_and_compile_procedures``/
  ``dismiss_compile_error_dialog``/Debugger-control/``launch_igor_pro_unattended``
  tools, all built directly on ``win32com.client.GetActiveObject("IgorPro.Application")``
  and ``Execute2``.
