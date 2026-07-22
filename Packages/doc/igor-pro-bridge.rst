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

- ``server.py``: the MCP server implementation (Python, using ``pywin32`` for COM).
- ``igor-pro-bridge-*.mcpb``: packaged Claude Desktop Extension bundles built from
  ``server.py`` via the `mcpb <https://www.npmjs.com/package/@anthropic-ai/mcpb>`__ CLI.

The companion procedure file ``Packages/MIES/MIES_ClaudeHelper.ipf`` (included from
``MIES_Include.ipf``) provides an ``AfterCompiledHook`` used by the bridge to get a more
reliable compile-success signal; see :ref:`igor_pro_bridge_claude_helper` below.

This is Windows-only tooling for MIES development, not something end users of MIES
interact with.

Architecture
------------

Igor Pro can act as a COM *server* on Windows via its built-in ActiveX Automation
Server (``IgorPro.Application``), documented in ``Igor Pro Folder/Miscellaneous/Windows
Automation/Automation Server.ihf``. Igor Pro cannot act as a COM *client*. The bridge is
a Python COM *client* process that attaches to an already-running Igor Pro instance via
``win32com.client.GetActiveObject("IgorPro.Application")`` and issues commands through
``Execute2``.

``Execute2`` does not raise a COM/Automation error just because the Igor-level command
failed -- the bridge checks the returned error code itself and raises a Python
``RuntimeError`` when appropriate. Data is retrieved by including ``fprintf 0, "..."``
calls in the command string and reading the result back.

Requirements
------------

- Igor Pro 9.00 or later, running on Windows. The Automation Server is already included
  in Igor Pro 9; ``RELOAD CHANGED PROCS``, which ``reload_and_compile_procedures``
  depends on, was introduced in Igor Pro 9.00 and sets the actual minimum version.
- Igor Pro must already be running before a tool call is made; the bridge attaches to
  the running instance, it does not launch Igor.
- **Both Igor Pro and the bridge's Python process must run elevated (as
  Administrator)**. This is a hard Windows COM requirement documented verbatim in
  Igor's own Automation Server reference and is not optional. Note that reopening
  Claude Desktop normally does not preserve elevation from a previous launch -- it must
  be relaunched via "Run as administrator" each time.
- Python, accessible as ``python`` on ``PATH``, with the ``mcp`` and ``pywin32``
  packages installed (``pip install mcp pywin32``, followed by
  ``python -m pywin32_postinstall -install``). The packaged extension does not vendor
  these.

Installation
------------

The bridge is distributed as a Claude Desktop Extension (``.mcpb``), not via manual
``claude_desktop_config.json`` editing (which does not work reliably for local MCP
servers in current Claude Desktop builds).

- Build: ``mcpb pack tools/igor-mcp-bridge tools/igor-mcp-bridge/igor-pro-bridge-X.Y.Z.mcpb``
- Install: Claude Desktop -> Settings -> Extensions -> Advanced settings -> Extension
  Developer -> Install Extension, then select the ``.mcpb`` file.
- After installing a new version, fully restart Claude Desktop (elevated) so the
  updated server code is actually loaded -- newly added tools can otherwise lag behind
  what's installed.

Available tools
----------------

``execute_igor_command(command)``
  Runs a command string on Igor's command line via ``Execute2``. Include an
  ``fprintf 0, "..."`` call to get data back. Returns a dict with ``"results"``
  (the ``fprintf`` output) and ``"history"`` (anything ``command`` sent to Igor's
  history area during this call, e.g. ``print`` output or the command echo itself
  -- confirmed from ``Automation Server.ihf``), so a ``print`` statement's output
  can be verified directly from the return value, without needing a human to look
  at Igor's screen. **Caution**: if ``command`` calls user-defined procedure code
  and the Debugger is enabled, a breakpoint/runtime error/abort/stale-reference
  pause will hang this call indefinitely -- there is no scriptable way to resume
  or dismiss the Debugger window. Prefer ``execute_igor_command_unattended``
  whenever nobody is watching who could close that popup by hand.

``execute_igor_command_unattended(command)``
  Same as ``execute_igor_command``, but automatically disables Igor's Debugger before
  running the command and restores it afterward, even if the command raises. This is
  the default choice for any unattended/automated call. On failure, both this and
  ``execute_igor_command`` include any partial ``results``/``history`` output captured,
  since Igor typically keeps running after an unhandled runtime error rather than
  stopping (see :ref:`igor_pro_bridge_runtime_errors`).

``read_session_history(stop=False)``
  Reads back everything sent to Igor's history area since this bridge process
  first talked to Igor, via Igor's built-in ``CaptureHistoryStart()``/
  ``CaptureHistory()`` functions (confirmed from ``Igor Reference.ihf``) -- a
  capture starts automatically on first use. Unlike the per-call ``history`` field
  above, this can verify *past* executions retroactively (e.g. if a command's
  return value wasn't captured at the time, or to see everything printed across
  many separate calls at once). Each call returns the full accumulated text since
  the capture started, so repeated calls are always safe. ``stop=True`` ends the
  current capture and starts a fresh one on next use.

``get_wave(wave_path)``
  Returns the data of an existing 1D Igor wave (numeric or text) as a list. Complex and
  multi-dimensional waves are not supported.

``check_bridge_health()``
  Diagnoses exactly why the bridge can't reach Igor Pro, distinguishing three separate
  failure modes: this process not running elevated, no Igor Pro COM object registered
  at all, and a registered-but-dead COM object (Igor crashed or was force-closed,
  leaving a stale registration that reconnecting alone can't fix). Run this first
  whenever something doesn't work.

``check_compilation_state()``
  Reports whether Igor's procedure code is currently compiled or uncompiled, using the
  same technique as ``IsProcGlobalCompiled()`` in
  ``Packages/igortest/procedures/igortest-test-compilation.ipf``.

``reload_and_compile_procedures()``
  Forces Igor to reload changed ``.ipf`` files from disk (``RELOAD CHANGED PROCS``) and
  attempt a fresh compilation (``COMPILEPROCEDURES``), then reports the resulting
  compiled state. Use this after editing a ``.ipf`` file directly on disk. Both
  commands go through Igor's operation queue rather than running immediately (see
  "Operation Queue" in ``Advanced Topics.ihf``), so this cross-checks two independent
  signals before trusting a "compiled" result -- see
  :ref:`igor_pro_bridge_claude_helper` and :ref:`igor_pro_bridge_compile_dialog`. If
  compilation still isn't confirmed after the initial poll, this automatically makes
  one attempt to dismiss a possible stuck compile-error dialog (see
  ``dismiss_compile_error_dialog``) before falling back to
  ``"prompt_user_to_check_for_dialog": true``. **Caution**: twice during this bridge's
  development, a real Igor Pro 10.03 instance became unreachable via COM (crashed or
  was closed) shortly after a reload/compile attempt -- no root cause was confirmed,
  and it isn't established whether this is related to the bridge at all versus a
  pre-existing Igor Pro stability issue (a subsequent retest against Igor Pro 9.06
  ran the same sequence -- broken code, reload/compile, fix, reload/compile again --
  without a repeat crash, which is reassuring but not conclusive either way). If a
  subsequent call fails with a COM/RPC error, check ``check_bridge_health()`` and be
  prepared to relaunch Igor Pro.

``dismiss_compile_error_dialog()``
  Attempts to close a stuck Igor Pro dialog by posting a simulated Escape key press
  directly to it (via ``PostMessage``), targeting a visible window owned by an Igor
  Pro process that either has class ``"#32770"`` (the standard Windows dialog class)
  or a title matching a known stuck-dialog title -- this does **not** require or
  change OS focus/foreground state. **Confirmed live against both Igor Pro 10.03 and
  Igor Pro 9.06**: the compile-error dialog is titled exactly *"Function Compilation
  Error"* and is a Qt window (class ``"Qt693QWindowIcon"`` on 10.03), not a native
  ``"#32770"`` dialog as originally assumed -- title matching is what actually finds
  it on both major versions, and a *posted* (not real hardware) Escape successfully
  closed it in both cases, with no focus/foreground change needed. Does **not**
  recover the actual error message -- it only clears the dialog so work can
  continue. See :ref:`igor_pro_bridge_compile_dialog`.

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

.. _igor_pro_bridge_unattended:

Unattended execution caveats
-----------------------------

Two independent things can silently stall an automated Claude/Igor session. Neither
hangs the bridge's own COM calls directly -- both instead leave Igor showing a GUI
element that only a human can dismiss.

Debugger pauses
~~~~~~~~~~~~~~~~

If the Debugger is enabled and something trips it (a breakpoint, a runtime error with
"Debug on Error", a user abort, or a stale NVAR/SVAR/WAVE reference), Igor pauses and
opens the Debugger window. There is no documented operation to programmatically
resume, step, or dismiss that pause -- ``Debugger``/``DebuggerOptions`` are the only two
documented operations, and neither has a "continue" mode. The specific COM call that
triggered the pause then blocks forever, since ``Execute2`` is synchronous. Other new
COM calls still get answered while paused (Igor's command line stays reentrant), but the
original call, and anything waiting on it, is stuck for good.

Mitigation: ``execute_igor_command_unattended`` disables the Debugger for the duration
of each call automatically. For a longer session, bracket it with
``get_debugger_state()`` / ``set_debugger_enabled(False)`` at the start and
``restore_debugger_settings()`` at the end instead.

.. _igor_pro_bridge_compile_dialog:

Compile-error dialogs
~~~~~~~~~~~~~~~~~~~~~~

Separately, a failed ``COMPILEPROCEDURES`` can leave a compile-error dialog open. This
does not hang the bridge's COM calls (they keep returning normally), but it does block
Igor's operation queue from ever draining -- confirmed from ``Advanced Topics.ihf``,
"Operation Queue": "Igor services the operation queue when no procedures are running
and the command line is empty." A modal dialog means Igor is never idle, so
``RELOAD CHANGED PROCS``/``COMPILEPROCEDURES`` queued by a later call sit there without
ever actually running -- ``reload_and_compile_procedures`` will keep reporting
"not compiled" even after the underlying ``.ipf`` file is genuinely fixed, until a
person closes that dialog by hand.

There is no documented way to detect or dismiss this dialog via COM, but Escape
closes it. ``dismiss_compile_error_dialog()`` exploits that: it enumerates top-level
windows for a visible one owned by an Igor Pro process that matches either window
class ``"#32770"`` (the standard native Windows dialog class) or a known
stuck-dialog title, then posts ``WM_KEYDOWN``/``WM_KEYUP`` for Escape directly to it
via ``PostMessage`` -- no foreground switch, no stolen focus. This works despite
Igor Pro's elevated status specifically because this bridge's own process is also
required to run elevated (see Requirements above) -- Windows' UIPI blocks simulated
input from a lower-privilege process reaching a higher-privilege one, but not
between two equally elevated processes.

**Confirmed live against a real stuck dialog on both Igor Pro 10.03 and Igor Pro
9.06**: the original assumption that this dialog is an ordinary ``"#32770"``
native dialog was wrong -- Igor Pro's UI (on both major versions tested) is
Qt-based, and the compile-error dialog is a Qt window titled exactly *"Function
Compilation Error"* on both (observed class on 10.03: ``"Qt693QWindowIcon"``, a
version-hash-looking string not worth matching on directly). Title matching is what
actually finds it, and a *posted* Escape (not a real hardware key press) was
confirmed to close it on both versions -- Qt's Windows platform layer reacts to the
posted message the same way it would a real key press. If a future window doesn't
match either signature, dismissal safely reports "not found" (along with a
diagnostic list of
every window Igor currently owns) rather than doing something incorrect. The
trade-off either way: this recovers the ability to continue working, not the actual
error message -- check the ``.ipf`` file's syntax directly, or have a human read the
dialog text, if the exact message matters. ``reload_and_compile_procedures`` now
calls this automatically once, before falling back to asking a human.

If the automatic attempt doesn't resolve it (or wasn't possible -- e.g. no matching
dialog window was found), ``reload_and_compile_procedures``'s result includes
``"prompt_user_to_check_for_dialog": true``; whatever is driving the bridge (e.g. an AI
agent) should use this as an explicit instruction to ask the human operator to check for
and close a stuck dialog, rather than silently retrying or only logging advisory text --
that distinction was confirmed in practice to be what actually keeps an
agent-driven/unattended workflow moving.

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
the way back to the top-level command boundary -- i.e. this bridge's ``Execute2``
call -- which reports it as that call's own failure, carrying the *original* error code
and message. This boundary check also clears the flag afterward, so a failure here
never contaminates the next command.

The flag is "sticky": if two *different* unhandled runtime errors occur in sequence
with nothing checking/clearing in between, only the *first* one is ever visible --
matching Igor's own documented caveat that ``GetErrMessage`` can be "incomplete" when
multiple errors occur.

Practical consequence: a nonzero error code from ``execute_igor_command``/
``execute_igor_command_unattended`` means at least one problem occurred and reports it,
but does **not** mean execution stopped there, and does **not** mean it was the only
problem.

.. _igor_pro_bridge_claude_helper:

MIES_ClaudeHelper.ipf and the AfterCompiledHook
-------------------------------------------------

``Packages/MIES/MIES_ClaudeHelper.ipf``, included from ``MIES_Include.ipf``, defines:

.. code-block:: igorpro

   static Function AfterCompiledHook()

       Variable/G root:gClaudeHelperCompileCounter
       NVAR gClaudeHelperCompileCounter = root:gClaudeHelperCompileCounter

       gClaudeHelperCompileCounter += 1

       return 0
   End

``AfterCompiledHook`` is a predefined Igor hook that Igor calls only after *all*
procedure windows have compiled successfully. Unlike polling ``FunctionInfo()`` for a
non-existing function (which can read stale state before Igor's operation queue has
actually drained -- see :ref:`igor_pro_bridge_compile_dialog`), this counter only ever
changes at the exact moment Igor itself confirms a successful compile, so it is a
race-free confirmation signal. ``reload_and_compile_procedures`` reads a baseline before
issuing ``RELOAD CHANGED PROCS``/``COMPILEPROCEDURES`` and treats any increase as
immediate, trustworthy success, falling back to the ``FunctionInfo``-based poll when the
counter is unavailable. There is no equivalent hook for a *failed* compile.

The whole function body is gated behind ``#ifdef IGOR_PRO_BRIDGE`` so it compiles out
entirely for a normal end-user build. To activate it, add:

.. code-block:: igorpro

   #define IGOR_PRO_BRIDGE

to the experiment's special "Procedure" window specifically -- Igor always compiles the
Procedure window first, so only a ``#define`` placed there is reliably visible to every
other file's ``#ifdef`` checks; a ``#define`` in an ordinary ``.ipf`` file has no such
guarantee.

``AfterCompiledHook`` is declared ``static`` so it coexists with any other file's own
static ``AfterCompiledHook`` (e.g. the one in ``MIES_Include.ipf`` used only for the
too-old-Igor warning panel) without colliding.

Known limitations
------------------

- No scriptable way to resume a Debugger pause -- this requires a human, as described
  above. A compile-error dialog can usually be auto-dismissed via a posted Escape key
  press (see ``dismiss_compile_error_dialog``, confirmed live), but that recovers the
  ability to continue, not the error message itself; if a genuinely new/different
  Igor popup shows up (not the known "Function Compilation Error" dialog or a native
  ``"#32770"`` one), dismissal safely reports "not found" and a human is still needed.
- ``get_wave`` supports 1D, real-valued waves only.
- The pywin32 dynamic-dispatch calling convention for ``Execute2``'s multiple ``[out]``
  parameters is assumed to follow the standard IDispatch convention (parameters come
  back as a tuple appended to the return value); this matches observed behavior in
  practice.
- This is a *local* MCP server (stdio transport): it only works from a Claude Desktop
  session running on the same Windows machine as Igor Pro, not from a cloud/sandboxed
  session.
- **Observed twice during development on Igor Pro 10.03, root cause unconfirmed**:
  Igor Pro became unreachable via COM (crashed or was closed) shortly after a
  ``reload_and_compile_procedures`` call. It isn't established whether this is
  related to the bridge's own actions or a pre-existing Igor Pro stability issue
  independent of it. A repeat of the same broken-code/reload/fix/reload sequence
  against Igor Pro 9.06 did not reproduce it, which doesn't rule out a 10.03-specific
  or environment-specific cause -- treat any COM/RPC failure after a compile attempt
  as a signal to check ``check_bridge_health()`` and be prepared to relaunch Igor Pro.
