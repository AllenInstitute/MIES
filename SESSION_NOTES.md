## Purpose

Facts, corrections, and findings from an extended Claude/Igor Pro working session on this
repository. Kept here so both the user and Claude can recall them accurately in later
sessions rather than re-deriving or re-arguing them from scratch. Entries are grouped by
topic, not chronology.

## Standing instruction

Verify findings carefully before reporting an error — read the documentation, trace the
actual code, or find corroborating evidence in the existing codebase, rather than asserting
Igor Pro semantics from memory. Several entries below exist because that wasn't done
carefully enough the first time.

**If `ipt`/`ipt.exe` (the Igor Programming Tool, `tools/ipt` in this repo) is available on
the `PATH` and the task involves parsing/understanding Igor Pro procedure code, use `ipt
check --print-ast` (or `ipt lint`/`ipt check` as appropriate) to generate the AST for the
relevant file(s) and use that AST as an additional information source alongside direct
reading of the source — not as a replacement for it.** See the "`tools/ipt`" section below
for what it reliably catches (near-100% clean parse across this repo's `.ipf` files, a real
lint rule for reserved-keyword-as-identifier misuse) and its confirmed gap (no
built-in-function-name-shadowing detection, since it has no symbol-resolution semantics).

## Igor Pro language facts (confirmed this session)

- **Reference-typed locals have function-level scope, not block scope.** `WAVE`, `NVAR`,
  `SVAR`, `DFREF`, `FUNCREF` locals are recognized by the compiler across the whole
  function body (e.g. a `WAVE test1 = data` inside an `if` block is still a valid,
  in-scope local after the `endif`), and default to a null/non-existent reference at
  function entry if the assigning line is never reached. This is *not* an error condition —
  referencing such a variable later without `/Z` only fails if the `WAVE` statement itself
  executes and its right-hand side fails to resolve, not merely because the statement was
  skipped by control flow.
- **A bare `String` defaults to a null string, not `""`.** These are distinct states,
  distinguishable via `strlen()`: `NaN` for a null string, `0` for `""`.
- **`Make` without `/N` defaults to a 1D wave with 128 points**, not 0. If an initializer
  list is given instead (`Make wv = {1, 2, 3}`), the wave is sized from the list, not
  defaulted to 128. Curly-brace initializer lists always require at least one operand —
  `Make wv = {}` is not valid syntax.
- **`Concatenate` (e.g. with `/NP=dim`) always leaves the destination wave existing**, even
  if the source has zero rows, even repeated across every iteration of a loop — the
  destination ends up as a valid 0-row wave, never an unbound/null reference. This does
  *not* apply if the outer wave-reference-wave being iterated (e.g. `sources` in
  `for(WAVE/T src : sources) ... endfor`) itself has zero rows: then the loop body never
  runs, `Concatenate` is never called, and the destination stays a null/non-existent
  reference per the default-initialization rule above.
- **Auto-indexing in a waveform assignment (e.g. `Make/WAVE/N=(n) w = SomeFunc(p)`) runs
  strictly in increasing index order when `Multithread` is *not* used.** With `Multithread`,
  execution order for a given index is not guaranteed, and the right-hand side must be
  threadsafe. This matters when the called function has order-dependent side effects.
- **The Igor compiler disallows a `WAVE name = expr` *declaration* statement where `name`
  also appears inside `expr`** (e.g. as a function argument), even if `name` was already
  declared earlier in the function. Workaround: introduce a second reference to the same
  wave under a different name (`WAVE/Z tmp = name; WAVE name = Func(tmp)`). This is
  different from a destructuring *reassignment* like `[out, outT] = Func(out, outT)`, which
  is legal because it updates already-declared references rather than re-declaring them.
- **`FindValue /TXOP` bit flags**: `4` = case-insensitive whole-cell text match (the
  pervasive default throughout this codebase), `5` = `4 | 1` = case-sensitive. Confirmed via
  existing code: `GetDecimalMultiplierValue` (`IPNWB_Utils.ipf`) uses `TXOP=(1+4)` for SI
  unit-prefix matching specifically because case matters there (`m` vs `M`).
- **`ListToTextWave` never returns a null wave.** An empty `listStr` input produces a
  0-row text wave, not a 1-row wave containing a single empty string.
- **`Make/N=(...)`: an explicit dimension size of `0` means "this dimension does not
  exist"** (same convention documented for `Redimension`), while an explicit `1` creates a
  real, if trivial, additional dimension. `Make/N=(n, 1, 1, 1)` is *not* equivalent to a
  true 1D wave — `DimSize(wv, COLS)` is `1`, not `0`. This codebase has an established
  convention that wave-of-waves values must be strictly 1D (e.g. `GetSetIntersectionWaves`
  asserts `DimSize(wv, COLS) == 0`), so creators of such waves must pass `0`-equivalent
  (or simply omit trailing dimensions) rather than `1`.
- **`Variable/G name = value` (with an explicit initializer) overwrites the global's value
  every time that line executes, even if the global already existed** — confirmed from Igor
  Reference.ihf: "/G Creates a variable with global scope and overwrites any existing
  variable," and "The variable is initialized when it is created if you supply the initial
  value." Bare `Variable/G name` (no initializer) is the safe, standard idiom to call
  unconditionally on every invocation instead: it creates the global at `0` only if missing,
  and leaves an existing value untouched otherwise — no `NVAR_Exists`-style guard needed.
  Caught in `MIES_ClaudeHelper.ipf`'s `AfterCompiledHook()`, which originally used a guarded
  `Variable/G root:gClaudeHelperCompileCounter = 0` and was simplified to the bare form.
- **`#define` symbols meant to control cross-file conditional compilation (`#ifdef`/
  `#ifndef`) must be set in the experiment's special "Procedure" window, not in a regular
  included `.ipf` file.** Confirmed from Programming.ihf: "Although it is difficult to
  determine the order in which procedure files are compiled, the main procedure window is
  always first." Since the Procedure window compiles before every other included file, a
  `#define` placed there (e.g. this experiment's existing `#define AUTOMATED_TESTING`) is
  reliably visible to every file's `#ifdef` checks; a `#define` in an ordinary `.ipf` file
  has no such guarantee and should not be relied on for this purpose.
- **The Igor compiler does not stop a local variable/string/`WAVE` reference from
  being named the same as a built-in Igor function or reserved keyword** (e.g.
  `string log` shadows the built-in `log()` function; the same applies to names
  like `return` or other keywords/function names). This compiles without error but
  is a real footgun: within that variable's scope, every reference to the name
  resolves to the local variable instead of the built-in function, silently
  breaking any code in that scope that expected to call the actual function/keyword
  behavior. **Rule: never name a variable, string, or `WAVE` reference after an
  Igor built-in function or reserved keyword**, even though the compiler allows it.

## MIES wave-versioning convention

Located in `MIES_WaveDataFolderGetters.ipf`: `WAVE_NOTE_LAYOUT_KEY = "WAVE_LAYOUT_VERSION"`,
with helpers `GetWaveVersion`, `SetWaveVersion`, `WaveVersionIsAtLeast`, `WaveVersionIsSmaller`,
`IsWaveVersioned`, `ExistsWithCorrectLayoutVersion`. `WaveVersionIsSmaller(wv, N)` returns
true if the wave is unversioned (`NaN`) or its version is `< N`. Correct migration idiom is a
sequence of independent `if(WaveVersionIsSmaller(wv, N))` blocks (N increasing), each
performing exactly the upgrade needed for that step — *not* an exclusive `if/elseif` chain,
which can skip needed migration steps for very old wave versions.

**Open bug, not yet fixed as of last check**: `GetAnalysisBrowserMap()` in
`MIES_WaveDataFolderGetters.ipf` (branch `feature/2737-prepare2_ivscc_apfrequency`) writes to
column index 3 (`wv[][3] = ANALYSISBROWSER_FILE_TYPE_IGOR`) inside its
`WaveVersionIsSmaller(wv, 1)` block *before* the wave is ever redimensioned beyond its
original 3 columns (widening to 5 columns only happens later, in the
`WaveVersionIsSmaller(wv, 4)` block). For a genuinely unversioned pre-2016 `experimentMap`
wave (confirmed via git history to have exactly 3 columns:
`ExperimentDiscLocation`/`ExperimentName`/`ExperimentFolder`), this throws an
index-out-of-range runtime error instead of migrating, because Igor bounds-checks wave
assignments. `GetSweepBrowserMap()` and `GetExperimentBrowserGUIList()` in the same diff
both redimension correctly before/with their writes — `GetAnalysisBrowserMap()` is the
outlier and needs the same treatment (redimension to at least 4 columns before writing
column 3).

**Fixed correctly in later commits on that branch** (for reference, not action items):
`GetSweepBrowserMap()` now uses the `WaveVersionIsSmaller`-gated pattern with
`SetWaveVersion`; the `SweepFormula.rst` doc wording around `seltag("")` matching all
sweeps in DataBrowser context was corrected to be precisely scoped and now matches the code;
`seltag`'s `SFH_CheckArgumentCount` minArgs was fixed from 0 to 1.

## SweepFormula dataset/datatype architecture

- Every SweepFormula operation result is a "dataset": a single-element `WAVE/WAVE`
  container, typically created via `SFH_CreateSFRefWave`, with an `SF_META_DATATYPE` JSON
  wave note (`JWN_SetStringInWaveNote`/`JWN_GetStringFromWaveNote`) identifying its kind
  (`SF_DATATYPE_SELECTCOMP`, `SF_DATATYPE_SELECTTAG`, etc.).
- `SFH_GetOutputForExecutorSingle(data, ..., dataType=X)` wraps whatever `data` it's given
  in a *new* single-element `WAVE/WAVE`, setting the note on that new wrapper — it does not
  tag `data` itself. Operations that call this directly on their own final payload (most
  `select*` filter operations) get one level of wrapping, note on the outside.
- `select()` itself is the counter-example: `SFOS_OperationSelect` builds its own composite
  (`GetSFSelectDataComp`), sets `SF_META_DATATYPE = SF_DATATYPE_SELECTCOMP` directly on it,
  and returns it via `SFH_GetOutputForExecutor(output, ...)` directly — skipping
  `SFH_GetOutputForExecutorSingle` entirely, so there's no extra wrapper for the note to get
  lost behind.
- `seltag` needs *two* levels of wrapping around its `tags` text wave specifically to stop
  the array-literal executor from treating a multi-tag `seltag([a, b])` result as a plain
  text wave and array-expanding its elements (see below). The `SF_META_DATATYPE` note must
  be set on the *inner* wrapper (the one that becomes `genericElement[0]` when the call
  appears inside an array literal), not only on the outer one — otherwise the note is lost
  the moment `seltag(...)` appears inside `[...]`.

## SweepFormula executor: array-literal handling of dataset elements

This session added support, in `SFE_FormulaExecutor`'s `JSON_ARRAY` branch
(`MIES_SweepFormula_Executor.ipf`), for array literals whose elements are datasets (e.g.
`[seltag(a), seltag(b)]`), where previously any non-text/non-numeric array element was
encoded as a stringified `wRefPath` marker (via `SFH_GetOutputForExecutor`) and placed into
a plain text accumulator — which silently discarded each element's own `SF_META_DATATYPE`
note, since the note lived on a wrapper level that got peeled away and never re-attached to
the marker.

Fix, in outline:

1. Introduce a genuine `WAVE/WAVE` accumulator (`outW`), alongside the existing numeric
   (`out`) and textual (`outT`) ones, used specifically for dataset array elements. Each
   element is stored as a direct wave reference (`outW[index] = subArray`) — never a
   stringified marker — so it keeps its own note natively; no marker-resolution helper is
   needed by consumers.
2. New helper `SFE_ExecutorCreateOrCheckWaveRef(WAVE/Z/WAVE outW, variable size0)` —
   deliberately takes only one size parameter, since `outW` should always stay strictly 1D
   (datasets are never spread across the outer array's other dimensions; see the `Make/N`
   dimension-size fact above for why `0`/omitted, not `1`, matters here).
3. `SFE_PlaceSubArrayAt` gained a `WAVE/WAVE` branch that assigns `outW[index] = subArray`
   directly — no `Multithread`, no elementwise copy, since a dataset occupies exactly one
   opaque slot regardless of its own internal shape.
4. The dimension-widening logic (`effectiveArrayDimCount` bump, `topArraySize[1,*] =
   max(...)`) must be guarded with `if(!WaveExists(outW))` — a dataset's own internal
   dimensionality must never influence the outer array's shape. This was an actual bug
   caught by testing: `[dataset(1,"abcd"), dataset(2,"cdef")]` produced a `(2,2)`-shaped
   `outW` instead of a flat 2-element one, because `dataset(...)`'s own multi-row payload
   leaked into `topArraySize` before this guard was added.
5. To allow *mixed* arrays like `["text", dataset(2, "cdef")]` (previously a hard
   `"mixed array types"` assertion failure): the loop was restructured into a prescan that
   resolves every element exactly once via `SF_ResolveDatasetFromJSON` (stored once, reused
   by both possible downstream branches — resolving twice was flagged as potentially
   unsafe, since resolution can execute arbitrary operations with side effects), determines
   whether *any* element is dataset-kind, and only then decides the accumulation strategy:
   if any dataset is present, the whole array is promoted to a uniform wave-of-datasets,
   with plain text/numeric elements individually wrapped into their own single-element
   `"PromotedArrayElement"` dataset (no `SF_META_DATATYPE` note attached to that wrapper).
   Otherwise, it falls through to the original `out`/`outT` accumulation logic, still reusing
   the already-resolved elements rather than re-resolving from JSON.
6. `SFH_GetArgumentSelect` (`MIES_SweepFormula_Helpers.ipf`) needs a matching update: check
   `IsWaveRefWave(array)` instead of `IsTextWave(array)`, and use
   `Duplicate/FREE/WAVE array, selectArray` directly instead of resolving each element via
   `SFH_AttemptDatasetResolve(WaveText(array, row = p), ...)` — array elements are now real
   wave references, not stringified markers, so there's nothing left to string-parse.

**Follow-up cleanup, not yet done** (tracked as session TODO items, not written to disk):
the fallback (`containsDataset == 0`) loop still carries the full original per-element
dispatch logic, including now-unreachable "mixed array types" asserts and the dataset/`else`
branch — harmless (dead code, since `containsDataset` is guaranteed false there) but worth
trimming down to just the text/numeric paths, reusing `IsTextWave(preResolved[i])` /
`IsNumericWave(preResolved[i])` directly instead of re-deriving `subArray` and re-running
`SFE_ConvertNonFiniteElements` a second time.

## Igor Pro COM Automation Server bridge (this session's later work)

Goal: let Claude control a running Igor Pro instance directly, from a local MCP server
(`tools/igor-mcp-bridge/server.py`) acting as a COM client on Windows.

- **Ruled out**: Igor 10's built-in Python bridge (`igorpro` module, `Python`/`PythonFile`
  operations) is documented by WaveMetrics as usable only *from within* Igor Pro itself --
  it cannot be used by an external process to control a running Igor instance.
- **Viable mechanism**: Igor's separate ActiveX/COM Automation Server (Windows-only). Igor
  can act as a COM *server*; it cannot act as a COM *client*. All details below were
  extracted directly from the local `Igor Pro Folder\Miscellaneous\Windows
  Automation\Automation Server.ihf` file (not secondhand/forum info).
- ProgID: `"IgorPro.Application"`. Connect to an already-running instance with
  `win32com.client.GetActiveObject("IgorPro.Application")` (Python equivalent of the
  documented VB `GetObject(, "IgorPro.Application")`). Using `Dispatch()` instead would
  launch a new instance and require handling Igor's post-launch initialization delay.
- `Execute2(int flags, int codePage, BSTR cmds, int* pIgorErrorCode, BSTR* errorMsg, BSTR*
  history, BSTR* results)`: does not raise a COM error on Igor-level command failure --
  check `pIgorErrorCode` (0 = success). `codePage` ignored since Igor 7 (pass 0). To get
  data back, put `fprintf 0, "..."` inside `cmds` and read it from `results` (WaveMetrics'
  own documented example: `WaveStats/Q jack; fprintf 0, "%g", V_avg`).
- `IApplication.DataFolder(nameOrPath)` -> `IDataFolder`; `IDataFolder.Wave(waveNameOrPath)`
  -> `IWave`. `waveNameOrPath` accepts an absolute path directly, so `root:` can be used as
  a fixed anchor and any full path passed straight into `.Wave(...)`.
- `IWave.GetDimensions(IgorProDataType* pDataType, long* pNumRows, long* pNumColumns, long*
  pNumLayers, long* pNumChunks)`.
- `IgorProDataType` enum (confirmed exact values): `ipDataTypeText = 0`,
  `ipDataTypeComplex = 0x01` (OR'd combination flag), `ipDataTypeFloat = 0x02`,
  `ipDataTypeDouble = 0x04`, `ipDataTypeSignedByte = 0x08`, `ipDataTypeSignedShort = 0x10`,
  `ipDataTypeSignedLong = 0x20`, `ipDataTypeUnsignedByte = 0x48`,
  `ipDataTypeUnsignedShort = 0x50`, `ipDataTypeUnsignedLong = 0x60`. So `dataType == 0`
  means text; anything else is some real numeric subtype (or has the complex flag set).
- `IWave.GetNumericWavePointValue(long index, double* pValue)` and
  `IWave.GetTextWavePointValue(long index, int codePage, BSTR* pValue)`: single-point
  reads, 1D waves only, real data only for the numeric one. The docs also document
  whole-wave SAFEARRAY methods (`GetNumericWaveDataAsDouble`, `GetRawTextWaveData`) but
  explicitly recommend the point-value methods "for most uses" -- and the point methods
  avoid SAFEARRAY marshaling questions entirely, so the bridge uses those for now (a
  whole-wave SAFEARRAY path could be added later for speed on large waves).
- **Critical setup requirement (verbatim from the docs)**: "The Windows operating system
  requires that you run the client and server (Igor) as administrator." Both Igor Pro
  and the Python client process must run elevated on Windows 10+, or the COM connection
  fails.
- **Not verifiable from this session (no Windows/Igor available here to run it)**: the
  exact Python-side tuple-unpacking shape pywin32's dynamic dispatch produces for
  multi-`[out]`-parameter methods like `Execute2`. The implementation assumes the standard
  IDispatch/pywin32 convention (`[out]`-only params come back as a tuple appended to the
  return value, e.g. `errorCode, errorMsg, history, results = igor.Execute2(0, 0, cmd)`) --
  this is well-established pywin32 behavior generally, but has not been run against the
  real Igor COM server yet. This is the one thing to verify first when testing
  `tools/igor-mcp-bridge/server.py` for real.
- `tools/igor-mcp-bridge/server.py` now has a real (not placeholder) implementation of
  `execute_igor_command` (via `Execute2`) and `get_wave` (via `DataFolder`/`Wave`/
  `GetDimensions`/point-value methods, 1D real waves only for now). It has grown
  substantially since: `execute_igor_command_unattended` (auto-disables/restores the
  Debugger around a call — a Debugger pause has no scriptable resume and hangs the
  triggering call forever otherwise), `check_bridge_health`, `check_compilation_state` /
  `reload_and_compile_procedures` (requires two consecutive "compiled" reads before
  trusting one, since `RELOAD CHANGED PROCS`/`COMPILEPROCEDURES` only run once Igor's
  operation queue drains — see Advanced Topics.ihf, "Operation Queue" section — and a
  single immediate check can race ahead of that), `get_debugger_state`/
  `set_debugger_enabled`/`restore_debugger_settings`, and `get_environment_summary`.
  Confirmed live: a leftover compile-error dialog from a failed compile blocks the
  operation queue from ever draining (so a later, genuinely-fixed reload/compile keeps
  reporting "not compiled") without hanging the bridge's own COM calls directly — there is
  no *documented* (COM-level) way to detect or dismiss that dialog. However, it's an
  ordinary modal Windows dialog that closes on a real Escape key press, and since this
  bridge's Python process and Igor Pro are both required to run elevated anyway (see
  above), Windows' UIPI doesn't block a simulated Escape key press from this process
  reaching Igor Pro's window (unlike the usual low-to-high-privilege case). v1.10.0 first
  added `dismiss_compile_error_dialog` using a hardware-level simulated key press
  (`keybd_event`) sent to whatever window was currently in the OS foreground — requiring
  a `SetForegroundWindow` call first, i.e. stealing focus. **v1.11.0 replaced this**, per
  the user's suggestion, with a `PostMessage(WM_KEYDOWN/WM_KEYUP, VK_ESCAPE)` sent
  directly to Igor's dialog window, found by enumerating top-level windows for one with
  class `"#32770"` (the standard Windows dialog class) owned by an Igor Pro process — no
  foreground/focus change needed at all.
  **Live-tested end to end against a real Igor Pro 10.03 instance (v1.12.0), and it
  worked.** First finding: the `"#32770"` assumption was wrong — `dismiss_compile_error_dialog`
  correctly and safely reported "not found" the first time, with no crash or bad
  side effect, and its diagnostic `"igor_windows_seen"` fallback (added specifically
  for this) revealed the real window: titled exactly `"Function Compilation Error"`,
  class `"Qt693QWindowIcon"` — Igor Pro 10's UI is Qt-based, not native Win32 dialogs.
  Switched targeting (v1.12.0) to match by that title (keeping `"#32770"` as a second,
  OR'd condition for any genuinely native dialog). Retested: `dismiss_compile_error_dialog`
  found the Qt window and posted Escape to it — **user confirmed the dialog actually
  closed on screen**. Confirms a *posted* (not real hardware) key event is enough for
  Qt's Windows platform layer to react the same as a real key press, with zero
  foreground/focus disruption. `reload_and_compile_procedures` calls this automatically
  once before giving up and asking a human.
  **Separately, twice during this same testing session, Igor Pro became unreachable
  via COM (crashed or was closed) shortly after a `reload_and_compile_procedures`
  call** — once with broken code present, once right after fixing it back. No root
  cause confirmed (no Windows crash logs accessible from here); not established
  whether this is related to the bridge's own actions (e.g. the new dismiss logic)
  or a pre-existing Igor Pro stability issue independent of it. Documented as a
  caution in the tool's docstring and the RST docs. Worth keeping an eye on in
  future sessions — if it recurs a third time with a clearer trigger, that would be
  worth isolating further.
  **Cross-version retest (user's request): closed Igor Pro 10 and opened Igor Pro
  9.06 (build 56685) instead, then repeated the entire scenario from scratch** —
  broke `test()`, `reload_and_compile_procedures`, confirmed the same
  `"Function Compilation Error"` Qt dialog title, ran `dismiss_compile_error_dialog`
  (found it, posted Escape, **user confirmed it closed** — same result as on 10.03),
  fixed the code, `reload_and_compile_procedures` succeeded via the
  `AfterCompiledHook` counter with **no crash this time**, and `test()` executed
  correctly (`"Hello World"` printed, user-confirmed). So both the dialog-title/Qt
  behavior and the PostMessage-Escape mechanism are now confirmed across both major
  Igor Pro versions (9.06 and 10.03) — updated `server.py`'s docstrings/comments and
  `igor-pro-bridge.rst` accordingly (including softening the crash note to note the
  9.06 retest didn't reproduce it, without claiming that rules anything out).
- **`MIES_ClaudeHelper.ipf`** (new file, included from `MIES_Include.ipf`) holds a `static
  Function AfterCompiledHook()` that increments `root:gClaudeHelperCompileCounter` on every
  successful compile — a compile-confirmation signal driven by Igor itself, as a more
  reliable alternative to polling `FunctionInfo()` for a non-existing function. The whole
  function body is gated behind `#ifdef IGOR_PRO_BRIDGE ... #endif`, so it compiles out
  entirely for a normal end-user build; a developer wanting it active must add
  `#define IGOR_PRO_BRIDGE` to the experiment's "Procedure" window (see the `#define`
  ordering fact above for why it has to go there specifically, not in the `.ipf` file
  itself).
- **History readback (v1.13.0)**: `execute_igor_command`/`execute_igor_command_unattended`
  now return `{"results": ..., "history": ...}` instead of a plain results string --
  `history` is Execute2's own `history` out-parameter ("any text sent to Igor's history
  area by the commands", confirmed from `Automation Server.ihf`), so a `print`
  statement's output can be verified directly from the return value instead of asking
  the user to look at Igor's screen. Also added `read_session_history(stop=False)`,
  backed by Igor's built-in `CaptureHistoryStart()`/`CaptureHistory()` functions
  (confirmed from `Igor Reference.ihf`) -- a capture starts automatically the first
  time `_execute2` runs in the bridge process's lifetime, and each read returns the
  full accumulated text since then. Live-tested against Igor Pro 9.06: confirmed
  `history` correctly showed `test()`'s "Hello World" output, and separately used both
  mechanisms to verify a full `RunWithOpts(testsuite="UTF_Utils_Algorithm")` MIES test
  suite run completed with no real failures (distinguishing the suite's own deliberate
  fail-path test cases, which print `"!!! ... assertion FAILED !!!"` as *expected*
  output, from an actual suite failure -- the suite's own closing "Finished with no
  errors" / "Test finished with no errors" lines are the authoritative signal).
- **PR #2754 opened** (`AllenInstitute/MIES` on GitHub) for this bridge. GitHub
  Copilot's automated PR review caught several real issues, all fixed (v1.14.0):
  (1) the module crashed with a raw ImportError on non-Windows platforms instead of
  failing clearly -- added an early `sys.platform != "win32"` check with an actionable
  message; (2) `set_debugger_enabled`'s optional sub-flags (`debug_on_error`/
  `debug_on_abort`/`nvar_svar_wave_checking`) were documented as "leave unchanged if
  omitted" but `bool(None)` silently forced them to `False` whenever the debugger was
  enabled -- fixed to read Igor's current setting and fall back to that instead of
  `False`; (3) `get_wave`'s docstring claimed every COM call was individually
  reconnect-protected, but the initial post-`GetDimensions` `_get_wave_ref` call
  wasn't actually wrapped in `_run_with_reconnect` -- fixed to match the claim; (4) the
  module docstring's "Registering with Claude Desktop" section still described editing
  `claude_desktop_config.json` directly, contradicting `igor-pro-bridge.rst`'s
  documented (and correct) `.mcpb`-install process -- updated to match; (5) a
  duplicated-word typo in `MIES_ClaudeHelper.ipf` ("Igor Pro Bridge bridge"). Two
  other Copilot comments (both about a "Make sure Igor Pro 10 (or later)..." message,
  in `_get_igor` and `check_bridge_health`) were already fixed earlier in this session
  when the Igor Pro 9 minimum-version requirement was confirmed -- verified those two
  specific strings already said "Igor Pro 9.00" before concluding no further change was
  needed. Note: GitHub's PR page loads inline review comment bodies via JavaScript: a
  plain `WebFetch`/`api.github.com` fetch only returned the file/line ranges, not the
  actual comment text, and the Claude in Chrome extension wasn't connected to render
  it -- the user pasted each comment's text manually instead.

- **`Quit/N` via `Execute2` logs `NOT EXECUTED: Quit/N` to history but Igor quits anyway.**
  Confirmed live: `execute_igor_command_unattended("Quit/N")` returned history text
  `"  NOT EXECUTED: Quit/N\r"`, and a subsequent `check_bridge_health()` call confirmed no
  COM object was reachable -- Igor had genuinely quit. Per `Automation Server.ihf`, `Quit`
  is exposed as its own dedicated `IApplication.Quit()` method, distinct from
  `Execute`/`Execute2`'s command-string interface -- consistent with Igor deferring the
  actual quit until after the in-flight `Execute2` RPC call returns (it can't tear down the
  process from inside the call servicing it), and logging the deferred line as
  "NOT EXECUTED" from the perspective of the synchronous command interpreter, even though
  the quit still happens moments later. Practical upshot: don't treat a `NOT EXECUTED:` line
  in `history` as proof a command had no effect for operations like `Quit` that are
  legitimately deferred/special-cased -- verify with an independent check
  (`check_bridge_health`) rather than trusting the history text alone. The bridge has no
  dedicated `quit_igor_pro()` tool wrapping the real `IApplication.Quit()` COM method;
  `execute_igor_command_unattended("Quit/N")` is sufficient in practice and no new tool was
  added for this.

- **`/UNATTENDED` suppresses the modal "Function Compilation Error" dialog entirely and
  reports the error via history instead.** Confirmed live against Igor Pro 9.06
  launched with `/UNATTENDED`: introducing a genuine syntax error into an actually-loaded
  file (`MIES_ClaudeHelper.ipf`) and running `reload_and_compile_procedures` gave
  `compiled: false`, `raw_function_info: "Procedures Not Compiled"`, and
  `dismiss_compile_error_dialog` found no dialog window at all (only Igor's main window
  was visible) -- unlike the interactive/non-`/UNATTENDED` case, where that same dialog
  reliably appears (confirmed earlier this session on both Igor Pro 10.03 and 9.06). The
  exact compile error is readable directly from history via `CaptureHistory`:
  `MIES_ClaudeHelper.ipf:46:7: error: expected terminating quote` (format
  `<file>:<line>:<col>: error: <message>`). This is strictly better for the bridge than
  the dialog path: nothing to dismiss, and the real error text is available
  programmatically, which the dialog-dismissal path never provided. Not documented
  anywhere in Igor's help files (the `/UNATTENDED` flag's own doc entry only mentions the
  About Autosave dialog and, as of Igor Pro 10, skipping license activation) --
  this compile-error behavior was inferred and confirmed empirically, not from docs.

- **Methodology error, caught by the user: verify a target .ipf file is actually loaded
  before editing it to test a bridge behavior.** While testing how Igor Pro's
  `/UNATTENDED` command-line flag affects the compile-error case, a syntax error was
  deliberately introduced into `Packages/tests/Basic/UTF_Basic_Includes.ipf` (the file
  used for this in earlier sessions), but this Igor Pro 9 instance had been started
  without loading `Basic.pxp` -- so that file was never `#include`d by anything
  actually loaded, and `get_environment_summary()`'s `included_procedure_files` list
  (fetched earlier in the same session) did not contain it. `RELOAD CHANGED
  PROCS`/`COMPILEPROCEDURES` therefore never touched the file at all: no compile error
  ever occurred, which is why no dialog appeared, no error text showed up in history,
  and `test()` merely failed as "not a recognized command" rather than "broken
  function." All of this looked superficially like a real `/UNATTENDED` behavior
  change but was actually a no-op test. **Lesson: before editing any procedure file
  to probe or reproduce bridge/compile behavior, cross-check the file's name against
  the current `included_procedure_files` list from `get_environment_summary()` --
  do not assume a file on disk is part of the live compiled environment just because
  it exists in the repo or was used successfully in a previous session (a different
  experiment, or no experiment at all, may be loaded now).** Redone correctly on
  `MIES_ClaudeHelper.ipf` (confirmed present in `included_procedure_files`), which
  gave the real, useful result -- see the `/UNATTENDED` entry above.

- **v1.15.0: added `configure_igor_launch(exe_path)` / `launch_igor_pro_unattended(...)`**,
  letting the bridge start Igor Pro itself with `/UNATTENDED` rather than requiring a
  human to do it. `configure_igor_launch` deliberately has no default/guessed
  executable path -- the calling agent must ask the user for it once per session (this
  repo alone has been tested against two differently-located Igor Pro installs), and
  the setting is session-scoped like the history-capture refnum (resets if the bridge
  process restarts). `launch_igor_pro_unattended` refuses to launch a second instance
  if one is already reachable via COM (launching with only `/UNATTENDED`, no `/I`/`/X`/
  `/SN`/file argument, is documented to start a genuinely new instance rather than
  reuse an existing one), and handles elevation two ways: if this Python process is
  already elevated, Igor launches as a direct child process (inherits elevation, no
  prompt); if not, it launches via `ShellExecute`'s `"runas"` verb (triggers a UAC
  consent dialog) -- but the bridge process itself remains unelevated either way in
  that second case, so COM calls will keep failing until Claude Desktop is itself
  relaunched as Administrator. Live-tested end-to-end the same session -- see the
  next entry.

- **`launch_igor_pro_unattended` (v1.15.0) confirmed working end-to-end**, live-tested
  against the Igor Pro 9 nightly install (`...\Igor Pro 9 Folder Nightly\
  IgorBinaries_x64\Igor64.exe`): with the bridge process already elevated,
  `configure_igor_launch` + `launch_igor_pro_unattended` launched Igor Pro as a direct
  child process with no UAC prompt (exactly as `configure_igor_launch`'s
  `"elevation_plan"` predicted), and `check_bridge_health` confirmed COM reachable
  afterward.
  **New finding from this test**: the initial readiness poll (30s) timed out even
  though the launch itself worked, because Igor Pro's Debugger popped up during its
  own startup and blocked the COM Automation Server from responding until the user
  manually closed it. The Debugger's enabled state is a persistent Igor Pro
  preference (confirmed: `get_environment_summary()` showed
  `debugger_settings.enable: true` immediately after this fresh launch, with no
  experiment loaded) -- it is not reset by `/UNATTENDED` and carries over from
  whatever it was left at in a previous Igor Pro session. So a fresh `/UNATTENDED`
  launch can still hit the already-documented "Debugger pauses" failure mode (no
  scriptable way to dismiss it) during Igor's own startup, before the bridge ever
  gets a chance to call `set_debugger_enabled(False)` -- only a human closing it
  manually unblocks the COM connection at that point. Disabled the Debugger
  afterward via `set_debugger_enabled(False)` for the rest of this session.
  **Not yet implemented**: having `launch_igor_pro_unattended` automatically call
  `set_debugger_enabled(False)` right after a successful COM connection, to prevent
  this recurring on the *next* launch (it can't help the *current* launch, since the
  Debugger pause happens before a connection exists to call it through) -- suggested
  to the user, not yet actioned.

- **Confirmed the Debugger-enable preference is genuinely persistent across a full
  quit/relaunch cycle, not just within one running instance.** After disabling it
  (`set_debugger_enabled(False)`, see entry above), quit Igor Pro via
  `execute_igor_command_unattended("Quit/N")` (again showed the misleading
  `NOT EXECUTED: Quit/N` history line, again actually quit -- see the earlier `Quit/N`
  entry) and relaunched fresh via `launch_igor_pro_unattended`. This time
  `com_ready: true` came back in 25 poll attempts (~25s) with no manual intervention
  needed -- no Debugger popup -- and `get_environment_summary()` confirmed
  `debugger_settings.enable: false` on the freshly-launched instance. So the fix
  from the previous entry wasn't a one-time fluke of that running instance; it holds
  across restarts, as expected for a genuine Igor Pro preference rather than
  per-session state.

- **Diagnosed and fixed (v1.16.0): `launch_igor_pro_unattended`'s direct-child-process
  path triggered a real MIES startup assertion, "We have git installed but could not
  regenerate version.txt", that never happens on a normal user launch.** Full chain,
  confirmed by reading the actual code (not guessed) and querying the live instance
  directly:
  - The assertion's stacktrace pointed to `IgorStartOrNewHook` (`MIES_IgorHooks.ipf`,
    runs on every Igor Pro launch) -> `GetMiesVersion` -> `CreateMiesVersion` ->
    `CreateMiesVersionNoCache` -> `ExecuteGitForMIESVersion`
    (`MIES_GlobalStringAndVariableAccess.ipf`).
  - `ExecuteGitForMIESVersion` shells out to git via `ExecuteScriptText/B/Z`,
    building the command as `<shellPath> /C "<git> -C <topDir> describe ... >
    version.txt"`, where `shellPath = GetCmdPath()` (`MIES_Utilities_File.ipf`) is
    just `GetEnvironmentVariable("COMSPEC")`. `ASSERT(!V_flag, "We have git
    installed but could not regenerate version.txt")` follows each
    `ExecuteScriptText` call.
  - Queried the live bridge-launched instance directly:
    `GetEnvironmentVariable("COMSPEC")` came back **empty**, while `PATH` was intact
    (including a working git-for-Windows install) -- ruling out a missing/
    unfindable git and pointing specifically at `COMSPEC`.
  - Root cause: `launch_igor_pro_unattended`'s direct-child-process path used
    `subprocess.Popen([exe_path, "/UNATTENDED"])` with no explicit `env`, so the
    child inherits this Python process's own environment -- which, inherited in
    turn from whatever launched Claude Desktop, apparently never had `COMSPEC` set.
    Windows normally sets `COMSPEC` automatically for every interactive login
    session, so a normal double-click/Start Menu launch of Igor Pro never hits
    this; it only surfaced via this bridge's non-interactive launch path.
  - Fix: added `_build_igor_launch_env()`, which copies `os.environ` and patches in
    `COMSPEC` (falling back to `<SystemRoot>\System32\cmd.exe`) if missing, passed
    as `env=` to the `subprocess.Popen` call. Only patches this one confirmed-missing
    variable, not a full environment rebuild.
  - **Re-tested live after the fix (v1.16.0 installed): confirmed working.** Quit
    Igor Pro, relaunched via `launch_igor_pro_unattended` -- `com_ready` in 12 poll
    attempts, no Debugger popup, and `GetEnvironmentVariable("COMSPEC")` queried
    directly on the fresh instance now returns `C:\Windows\System32\cmd.exe`
    (previously empty). User confirmed no assertion appeared on screen this time.
    Note: history-based verification still can't retroactively prove the assertion
    text is absent (the capture only starts once this bridge process first talks to
    a fresh instance, which is necessarily after its startup hook already ran) --
    the fix is confirmed at the root-cause level (COMSPEC populated) plus the
    user's direct visual confirmation, not via history text.
  - Separately observed mid-test: a `configure_igor_launch` tool call failed with
    "Tool permission stream closed before response received", and Claude Desktop
    itself relaunched (not Igor Pro) shortly after -- cause not established, but
    unrelated to the COMSPEC fix itself (this bridge process's own session state,
    e.g. the configured exe path, was simply reset by the restart, same as any
    other Claude Desktop restart; re-ran configure_igor_launch and proceeded
    normally afterward).
  - The `ShellExecute`/`"runas"` path (used when this process isn't elevated) was
    not touched -- `ShellExecute` goes through the shell (similar to a normal
    double-click), so it's expected to already inherit a proper interactive-session
    environment including `COMSPEC`; this was not independently verified, though.

- **v1.17.0: added `load_experiment(file_path)`** to open a `.pxp` experiment (e.g.
  MIES's `Basic.pxp`) into the running instance. Like `Quit` earlier this session,
  `LoadExperiment` turned out to exist only as a COM Automation method
  (`IApplication.LoadExperiment(flags, loadType, symbolicPathName, filePath)`,
  confirmed from `Automation Server.ihf`) -- confirmed absent from `Igor
  Reference.ihf` (neither `LoadExperiment` nor `OpenFile` appear there at all), so
  it cannot be run as an `Execute2` command string the way most other tools in this
  bridge work. Implemented by calling the COM method directly (same pattern as
  `get_wave`'s direct `DataFolder`/`Wave` calls), using `loadType=ipLoadTypeOpen`
  (2). Per the docs, this does not prompt to save the previously-open experiment's
  changes -- left to the caller to do explicitly via
  `execute_igor_command('SaveExperiment')` first if needed. Wrapped with the same
  Debugger disable/restore bracket as `execute_igor_command_unattended`, since
  loading an experiment runs its recreation procedures and MIES's
  `IgorStartOrNewHook` startup hook, and this call bypasses `_execute2` entirely so
  it wouldn't otherwise get that protection. **Live-tested successfully**: loaded
  `Packages/tests/Basic/Basic.pxp`, confirmed via `get_environment_summary()`
  (`experiment_file_name: "Basic.pxp"`, 252 procedure files included, Debugger
  stayed disabled, no COM reconnect needed) and again later with
  `Packages/tests/HistoricData/HistoricData.pxp` to run the
  `UTF_HistoricSweepBrowser` test suite (passed -- "Finished with no errors").

- **v1.18.0: fixed 2 real issues from a fresh Copilot PR review on #2754**, triggered
  by a third commit (`3eca418`, "MCP: Added two new functions") that had been pushed
  to the PR branch independently of this session's own (still-uncommitted) local
  edits. Same pattern as the first review: user pasted each comment, each was
  verified against the actual current code before fixing, both turned out real.
  1. `_is_stuck_dialog_window` (`server.py`) unconditionally treated ANY window with
     the generic native Windows dialog class `"#32770"` as safe to dismiss,
     regardless of title. Since `dismiss_compile_error_dialog` is called
     automatically from `reload_and_compile_procedures`, this could have
     Escape-dismissed an unrelated native dialog (e.g. a save-changes
     confirmation) -- and it was never actually needed, since the real
     compile-error dialog (confirmed live on both Igor Pro 10.03 and 9.06) is a Qt
     window, not `"#32770"` at all. Fixed by removing the class-based branch
     entirely -- title matching alone (already confirmed sufficient) is what's
     used now. Removed the now-unused `_DIALOG_WINDOW_CLASS` constant and updated
     every docstring/comment that described the old OR'd-class behavior
     (`_attempt_dismiss_compile_error_dialog`'s "reason" message,
     `dismiss_compile_error_dialog`'s docstring, the module-level comment block).
  2. `MIES_ClaudeHelper.ipf`'s `AfterCompiledHook` incremented a global variable
     without capturing/restoring `ExperimentModified` state first, unlike the
     sibling `AfterCompiledHook` in `MIES_IgorHooks.ipf` which already does exactly
     this. Left as-is, this could flip an otherwise-unmodified experiment to
     "modified," risking a "Save changes?" prompt later -- particularly bad for
     this bridge specifically, since that's exactly the kind of dialog it has no
     way to dismiss remotely (unlike the compile-error dialog). Fixed to match the
     established convention: capture `modifiedBefore` via `ExperimentModified`/
     `V_flag` before the increment, restore to unmodified afterward if it wasn't
     modified before.
  - Packaged and delivered as v1.18.0. User then committed and force-pushed
    directly (outside this session's own git actions) -- PR branch confirmed via
    the PR page to now be at commit `af09a1f` (3 commits: `8ae3cf7`, `357ca75`,
    `af09a1f`), closing the previously-tracked gap between local fixes and the
    GitHub branch. Both of this entry's fixed comments now show "Show resolved" on
    the PR page. A new Copilot review was triggered by this push but had not
    produced visible results yet as of the last check -- worth checking back for
    new comments.
  - **Follow-up Copilot comment on this same push, also real**: `igor-pro-bridge.rst`
    still described the old, now-removed class-based `"#32770"` matching in the
    `dismiss_compile_error_dialog()` tool entry -- the `server.py` code and its
    docstrings were updated when the fix was made, but this RST doc was missed.
    Fixed all three stale mentions (the tool entry, the "Compile-error dialogs"
    narrative section, and the "Known limitations" bullet) to describe title-only
    matching, with the removed class-check kept only as explanatory history. Doc-only
    change, no new `.mcpb` package needed -- just needs committing alongside the code.
  - **Next Copilot comment on the same push, also real**: the RST "Requirements"
    section still said "Igor Pro must already be running before a tool call is made
    ... it does not launch Igor," predating the v1.15.0 launch tools entirely. Fixed
    to note most tools require an already-running instance, with
    `launch_igor_pro_unattended` (after `configure_igor_launch`) as the exception.
    Checked `server.py`'s own module docstring for the same stale claim -- not
    present there, so this was the only spot. Doc-only, no new package needed.
  - **v1.19.0: fixed a real Copilot comment on `configure_igor_launch`'s
    `elevation_plan` text.** `_is_current_process_elevated()` can return `True`,
    `False`, or `None` (undetermined), but the plain `if elevated ... else ...`
    ternary treated `None` the same as `False`, reporting "NOT currently elevated"
    as a confirmed fact when it was actually unknown. Fixed with explicit
    three-way branching (`is True` / `is False` / else-unknown), the unknown case
    explaining that `launch_igor_pro_unattended` conservatively treats undetermined
    the same as not-elevated (safer than risking a silently unelevated direct
    launch). `launch_igor_pro_unattended`'s own launch-path selection was left
    unchanged initially -- that fallback behavior is a deliberate, safe default, not
    a documentation-accuracy bug.
  - **v1.20.0 (original, elevation-check fix) -- apparently never actually made it to
    disk; correcting the record.** This entry originally described a follow-up Copilot
    fix: `launch_igor_pro_unattended`'s own `elevated else ...` ternary and `if elevated:`
    check had the same None-treated-as-False pattern as the `elevation_plan` text fix
    above, changed to explicit `is True` checks for clarity. That work was reported here
    as "packaged and delivered as v1.20.0, sha256-verified," but **no `igor-pro-bridge-
    1.20.0.mcpb` file was ever found in `tools/igor-mcp-bridge/`** in a later session --
    only versions up through 1.19.0 exist on disk, and 1.19.0's own `src/server.py` still
    has the plain `if elevated:` truthy check, not the `is True` fix. Since files copied
    into this workspace folder cannot be deleted or renamed, its absence means it was
    never actually copied here in the first place (likely only shown to the user via a
    temporary/chat-only share, not saved to the repo) -- this was not caught until a much
    later session re-examined the actual files on disk. **The `is True` elevation-check
    fix is therefore still outstanding**, not yet re-applied to any file present in this
    repo. The version number 1.20.0 has since been reused (see the next entry) for an
    unrelated change built directly on top of 1.19.0, so that fix is not incidentally
    included there either.
  - **v1.20.0 (actual, currently in the repo): relaxed reload/compile timing**, per an
    explicit user request after the Igor Pro crashes observed around
    `reload_and_compile_procedures` calls earlier this session (see the crash-pattern
    entry above) -- not a confirmed root-cause fix, just a precaution to stop packing the
    two `Execute/P` calls and the poll loop so tightly. Built directly from 1.19.0 (the
    highest version actually present on disk; see the correction above), three changes to
    `reload_and_compile_procedures` and its module-level constants:
    1. `time.sleep(_RELOAD_TO_COMPILE_PAUSE_SECONDS)` (new constant, `2.0`) inserted
       between the `"RELOAD CHANGED PROCS "` and `"COMPILEPROCEDURES "` `Execute/P` calls.
    2. `time.sleep(_POST_COMPILE_PAUSE_SECONDS)` (new constant, `1.0`) inserted
       immediately after the `"COMPILEPROCEDURES "` call, before polling begins.
    3. `_COMPILE_POLL_INTERVAL_SECONDS` raised from `0.2` to `0.5`.
    Packaged and delivered as v1.20.0 (manifest version bumped to match), sha256-verified
    between build output and the repo copy. Note this build does **not** include the
    still-outstanding `is True` elevation-check fix described in the correction above --
    worth folding in together if/when that's revisited.
  - **v1.21.0: folded in the still-outstanding `is True` elevation-check fix**, per the
    user's follow-up request. Built directly on top of the actual v1.20.0 staging dir
    (timing changes above, still present). `launch_igor_pro_unattended`'s
    `launch_method = "direct_child_process" if elevated else "shell_execute_runas"` and
    `if elevated:` were changed to `elevated is True`, matching the fix already applied to
    `configure_igor_launch`'s `elevation_plan` text (v1.19.0). Behaviorally identical
    either way (an undetermined `None` was already falsy, so both versions fall back to
    the not-elevated/UAC-prompting path the same way) -- purely a code-clarity change, so
    the previously-lost fix is now genuinely present in a file on disk in this repo.
    Packaged and delivered as v1.21.0, sha256-verified between build output and the repo
    copy.
  - **v1.21.0 confirmed installed and live-tested for the crash-mitigation timing.** User
    confirmed installing v1.21.0 (after an initial "1.12.0" typo, corrected). With it active,
    ran three consecutive `reload_and_compile_procedures` cycles against a trivial, genuinely
    branch-appropriate test addition (`TestArbitraryPlaceholder` in `UTF_Utils_GUI.ipf` --
    see the `ListBoxSelectAll` correction entry above for why an earlier attempt at this used
    the wrong, cross-branch test instead) -- each followed by `check_bridge_health` and/or a
    `RunWithOpts` test run. All three cycles compiled cleanly and Igor stayed reachable
    throughout; no crash reproduced. **Not conclusive** -- the original crashes were observed
    twice, intermittently, not on every attempt, so a handful of clean cycles doesn't rule out
    recurrence, but it's a real, confirmed-active data point in the timing-relaxation's favor.
  - **Follow-up requested: v1.22.0 should add a tool to report the bridge's own running
    version** (e.g. from `manifest.json`'s `version` field), precisely because this session
    had no way to confirm from inside a conversation which `.mcpb` build was actually loaded
    in Claude Desktop -- the ambiguity above (was v1.21.0 or an old build active during the
    crash test?) could have been resolved instantly with such a tool. Tracked as a to-do item,
    not yet implemented.
  - **v1.22.0: added `get_bridge_version()` and `close_data_browser()`.**
    `get_bridge_version()` returns a hardcoded `_BRIDGE_VERSION` constant (not read from
    `manifest.json` at runtime -- the on-disk layout after Claude Desktop installs a `.mcpb`
    isn't guaranteed to keep `server.py` and `manifest.json` at a fixed relative path, so a
    hardcoded constant, bumped by hand every release, is simpler and more robust). Directly
    fulfills the to-do above.
    `close_data_browser()` was the actual point of a user report: **an open instance of
    Igor Pro's own built-in Data Browser (the stock, integrated feature -- explicitly *not*
    MIES's own `DB_*` DataBrowser panel, which was investigated and ruled out as a
    misunderstanding first) can sometimes cause Igor Pro to crash while procedure code is
    running** (e.g. during a reload/compile cycle or a test run). Confirmed the closing
    mechanism directly from Igor Reference.ihf before implementing anything: `ModifyBrowser
    close` ("Closes the Data Browser"; without `/M` it targets the regular, non-modal
    browser). Empirically confirmed live (via `execute_igor_command_unattended`) that calling
    it with no Data Browser open raises `"The Data Browser must be active."` rather than
    silently no-op'ing -- no documented `/Z`-style quiet flag exists for this operation, so
    `close_data_browser()` catches specifically that error message and returns
    `{"was_open": False, "closed": False}`, re-raising for any other error. Made an
    **on-demand-only tool** by explicit user choice (not called automatically from
    `reload_and_compile_procedures` or anywhere else) -- so using it as a crash-mitigation
    precaution before a test run is left to whoever is driving the bridge, not baked into
    existing tool behavior. Packaged and delivered as v1.22.0, sha256-verified between build
    output and the repo copy; `igor-pro-bridge.rst` updated with both new tool entries.
    **Not yet live-tested against a real crash reproduction** -- the underlying crash this is
    meant to mitigate was only ever observed by the user outside of a session where this
    tool existed yet, so its actual effectiveness is still unconfirmed.
  - **25-step crash stress test, v1.22.0 confirmed active: zero crashes.** Per the user's
    request, starting from a freshly closed Igor Pro and a `UTF_Utils_GUI.ipf` reverted to
    match HEAD, ran 25 iterations of: append one new, uniquely-named, trivial `static`
    test case (`TestArbitraryStress01` .. `TestArbitraryStress25`, each just
    `CHECK_EQUAL_VAR(N + 1, N + 1)`) -> `ipt check` -> `reload_and_compile_procedures` ->
    `RunWithOpts(testcase=...)` for that specific new case -> `check_bridge_health`.
    Confirmed `get_bridge_version()` returned `"1.22.0"` before starting, so this run
    genuinely exercised the current timing relaxation (`_RELOAD_TO_COMPILE_PAUSE_SECONDS`,
    `_POST_COMPILE_PAUSE_SECONDS`, the raised `_COMPILE_POLL_INTERVAL_SECONDS`) and the
    `is True` elevation fix, not an older build. **Result: all 25 steps compiled and passed
    cleanly, `check_bridge_health` reported `"status": "OK"` after every single one, and a
    final combined run of all 25 test cases together (`testcase="TestArbitraryStress.*"`)
    also finished with no errors -- zero crashes across the entire 25-step run.** This is
    the strongest single data point so far in favor of the timing relaxation actually
    helping (or at minimum, that this particular edit/compile/test pattern alone isn't
    sufficient to reproduce the original crash) -- still not proof the underlying crash
    mode is fully fixed, since the original incidents were rare/intermittent even before
    any mitigation existed, but 25/25 clean is a meaningfully larger sample than the 3
    cycles run previously. `close_data_browser()` was *not* exercised in this run (no Data
    Browser was open at any point) -- its own effectiveness remains separately unconfirmed,
    per the entry above.

## `tools/ipt` (Igor Programming Tool) evaluated for AST/code understanding

The repo ships `tools/ipt` (Linux ELF, statically linked), `tools/ipt.exe` (Windows), and
`tools/run-ipt.sh` (a git-root-relative wrapper picking the right binary by `uname`). Docs at
docs.byte-physics.de/ipt. Investigated whether it genuinely improves understanding of Igor
Pro source beyond manual reading -- conclusion: **yes, with real value and one confirmed
gap**, based on live runs against this repo (not assumed from the docs alone).

- **`ipt check --print-ast <file>` parses actual Igor Pro source into a real AST** (node
  types like `Function`, `Declaration`, `Assignment`, `OperationStatement`, each with
  precise line:column spans) -- confirmed by running it against
  `Packages/MIES/MIES_GlobalStringAndVariableAccess.ipf` (the exact file investigated
  earlier this session for the COMSPEC/git bug): it parses cleanly with **zero errors**,
  including the tricky nested-quote `sprintf`/`ExecuteScriptText` command-building lines,
  confirming the parser handles real, non-trivial MIES code correctly, not just toy
  examples.
- **Whole-codebase check**: ran `ipt check` (no `--print-ast`, batched to fit the shell's
  per-call time budget) over all 487 `.ipf` files under `Packages/`. Result: **484 parse with
  zero errors; the only 3 parsing errors are the same deliberately-malformed fixture file**
  (`test-input-function-params.ipf`, a doxygen-filter test input, vendored/duplicated under
  `doc/`, `igortest/docu/`, and `unit-testing/docu/`) -- not real MIES source bugs. So `ipt`
  is practically usable across this entire real codebase, not just isolated files.
- **Directly relevant to the shadowing rule just added above**: `ipt` ships a lint rule
  named exactly for this, `BugproneReservedKeywordsAsIdentifier` (confirmed via `ipt lint
  --list`). Live-tested its actual scope with three throwaway test files: it correctly
  flags a variable named after a genuine reserved **keyword/type name** (e.g. `variable
  wave` -> "Use of reserved keyword as identifier. Please rename it."), **but it does
  NOT flag a variable/string named after a built-in **function** name** (`variable abs`,
  `string print`, `string log` all passed both `ipt check` and `ipt lint` -- including
  `--include BugproneReservedKeywordsAsIdentifier` explicitly -- with zero warnings). This
  is a real, confirmed gap: `ipt`'s existing tooling would not have caught the user's
  original `string log` example, which is exactly why that rule was worth writing down by
  hand in this file rather than assuming `ipt lint` already covers it.
- **The AST itself has no built-in-name-resolution semantics** -- confirmed from the
  printed tree for a `string log` test case: the declaration, assignment target, `print`
  argument, and `return` value all show up as plain `(Id \`log\` ...)` nodes with no
  annotation distinguishing "shadows a built-in" from "an ordinary local name." This is
  consistent with `ipt` being a syntax-level tool (parser + lints operating on the parse
  tree), not a full semantic/symbol-resolution engine against Igor's built-in function
  table -- explains why the lint gap above exists rather than being an oversight.
- **Practical takeaway for future sessions**: `ipt check`/`ipt check --print-ast` is a fast,
  reliable way to get an authoritative parse of a `.ipf` file's structure (function
  signatures, statement nesting, operation-argument shape) without needing a live Igor Pro
  instance, and is trustworthy against this codebase (near-100% clean parse rate). `ipt
  lint` catches genuine keyword-as-identifier misuse and a range of other real style/bug
  patterns (see `ipt lint --list` / the docs' rule list), but does not catch built-in
  *function*-name shadowing -- that class of bug still needs to be caught by review/manual
  attention (or a new custom rule), not by relying on existing `ipt` output.
- Performance note: parsing this repo's ~487 `.ipf` files is not uniformly fast -- most
  batches process in the range of tens-of-milliseconds-per-file, but at least one file in
  the tree parses roughly 10x slower than the rest (bisection pinned it to a ~125-file
  slice without identifying the specific file); worth keeping invocations chunked/batched
  rather than assuming a single whole-codebase call finishes quickly.

## `ListBoxSelectAll` test coverage added, live-verified

`MIES_Utilities_GUI.ipf`'s `ListBoxSelectAll(WAVE selWave)` had no test coverage. Added
`TestListBoxSelectAll` and `TestListBoxSelectAllOnPlainSelectionWave` to
`Packages/tests/Basic/UTF_Utils_GUI.ipf`, designed from actually reading the function body
(`selWave[][0][0] = selWave[p][0][0] | LISTBOX_SELECT_OR_SHIFT_SELECTION`) plus corroborating
evidence from Igor's own `Igor Reference.ihf` `ListBox` operation docs (`selWave` is "a
numeric wave with the same dimensions as listWave," bit 0 = selected, "additional dimensions
are used for color info," "in modes 3 and 4 bit 0 is set only in column zero") and from how
MIES itself builds a real selWave (`GetAnalysisBrowserGUIFolderSelection`: `Make/N=(1,1,3)`,
layer 0 = selection, layers 1/2 dim-labeled `foreColors`/`backColors`) -- so the first test's
3-layer shape mirrors production usage rather than being an arbitrary shape.

- **Live-tested via the Igor Pro Bridge** (launched Igor Pro 9 nightly with
  `launch_igor_pro_unattended`, loaded `Basic.pxp`, ran `RunWithOpts(testsuite=
  "UTF_Utils_GUI")`). First run caught a real bug in the second test, not in
  `ListBoxSelectAll` itself: `TestListBoxSelectAllOnPlainSelectionWave` built `selWave` as
  `Make/FREE/N=(numRows, 1)` (2D) but `expected` as `Make/FREE/N=(numRows)` (1D) --
  `CHECK_EQUAL_WAVES` failed on `DIMENSION_SIZES`/`DIMENSION_LABELS` even though the actual
  data values matched. Fixed by making `expected` explicitly `(numRows, 1)` too. Re-ran after
  fixing and reloading/recompiling: **"Test finished with no errors."**
- **`RunWithOpts` also accepts a single `testcase=` name** (in addition to `testsuite=`), to
  run one specific test function without the rest of its suite -- confirmed live: `RunWithOpts
  (testcase="TestListBoxSelectAll")` ran only that one case ("Entering test case
  \"TestListBoxSelectAll\"" / "Finished with no errors"), still reporting "Entering test suite
  \"UTF_Utils_GUI.ipf\"" around it (the suite file is still scanned to locate the named case,
  but only that case actually runs). Useful for iterating on a single new/failing test without
  re-running an entire suite.
- **Fuller option reference for `RunWithOpts`**, read directly from its own source
  (`Packages/tests/UTF_HelperFunctions.ipf`) and the underlying `RunTest` it calls
  (`Packages/igortest/procedures/igortest-basics.ipf` -- this experiment's compiled
  environment uses the `igortest` framework, not the older, also-present `unit-testing`
  package; confirmed by `included_procedure_files` listing `igortest-basics.ipf` but not
  `unit-testing-basics.ipf`). `RunWithOpts` is a thin MIES-specific wrapper: `testsuite`
  defaults to `GetDefaultTestSuitesForExperiment()` if omitted, `traceWinList` defaults to
  `"MIES_.*\.ipf"` (only used if `instru=1`), and it otherwise forwards straight to `RunTest`.
  Named parameters, all optional:
  - `testsuite` -- semicolon-separated list of procedure files to treat as test suites (e.g.
    `"UTF_Utils_GUI"` -- `RunWithOpts` appends `.ipf` automatically unless `enableRegExp=1`).
    Defaults to this experiment's full default suite list if omitted entirely.
  - `testcase` -- semicolon-separated list of test-case function names to run within
    `testsuite` (default: all). Confirmed live above for a single name.
  - `enableRegExp` -- when `1`, both `testsuite` and `testcase` are matched as (anchored,
    case-insensitive) regular expressions instead of literal/list names, and `testsuite` is
    matched against the full file name **including** `.ipf` (confirmed live: `testsuite=
    "UTF_Utils_GUI"` with `enableRegExp=1` failed with "A procedure window matching the
    pattern \"^(?i)UTF_Utils_GUI$\" could not be found" -- needed `testsuite=
    "UTF_Utils_GUI.ipf"`). Combining both let one `RunWithOpts(testsuite="UTF_Utils_GUI.ipf",
    testcase="TestListBoxSelectAll.*", enableRegExp=1)` call run both new `ListBoxSelectAll`
    tests together without the rest of the suite or a semicolon-joined exact-name list --
    confirmed live, both passed.
  - `allowDebug` -- leave Igor's Debugger in whatever state it's already in for the run
    (normally overridden off); ignored if `debugMode` is also given. Not relevant to this
    bridge's own calls, since `execute_igor_command_unattended`/`load_experiment` already
    force the Debugger off for the duration of the call regardless.
  - `instru` -- turns on execution tracing/coverage instrumentation (RTF + optionally
    Cobertura output) over `traceWinList` (defaults to all `MIES_*.ipf` files); off by
    default. Unrelated to pass/fail reporting -- a coverage feature, not needed just to
    check correctness.
  - `ITCXOP2Debug` -- hardware (ITC) XOP debug mode passthrough via `HW_ITC_DebugMode`; not
    relevant without real DAQ hardware attached.
  - `keepDataFolder` -- don't clean up each test case's temporary data folder afterward, to
    allow inspecting produced data by hand; off by default.
  - `enableJU` -- write a JUnit-compatible XML report at the end; defaults to on only when
    `IsRunningInCI()` is true, off in an interactive/bridge-driven run like this session's.
  - All of the above are also documented with more nuance directly on `RunTest` itself
    (`igortest-basics.ipf` around line 1490), including two options `RunWithOpts` doesn't
    expose at all: `shuffle` (randomize suite/test-case execution order, useful for catching
    order-dependent test bugs) and `retry`/`retryMaxCount` (rerun flaky tests tagged
    `IUTF_RETRY_FAILED` up to N times) -- call `RunTest` directly instead of `RunWithOpts` if
    either of those is needed.
- **Note on `TestRemoveAllColumnsFromTable`'s console output**: this pre-existing,
  unmodified test deliberately prints two `"!!! Assertion FAILED !!!"` lines (from
  `RemoveAllColumnsFromTable`'s own internal `ASSERT` firing inside a `try/catch` the test
  sets up on purpose, to confirm the function rejects a non-table window) -- this is expected
  output, not a real failure, and correctly does not appear in the suite's final failure list
  (consistent with the fail-path-test convention already noted elsewhere in this file for
  UTF test suites generally).
- `ipt check`/`ipt lint` were run against the edited test file both before and after the fix
  (per the new standing `ipt` rule above) and reported zero errors/warnings each time -- a
  reminder that a clean `ipt` parse does not guarantee the test's *assertions* are actually
  correct (that dimension-mismatch bug parsed and linted cleanly); only the live Igor Pro run
  caught it.
- **CORRECTION, root-caused by the user: this whole section was based on a branch mix-up, not
  a real feature of the `feature/2754-add-basic-igor-pro-mcp-server` branch this bridge work
  lives on.** `ListBoxSelectAll` (and its test coverage above) was observed/added while this
  repo's working tree happened to be checked out to a *different* branch,
  `feature/2737-prepare2_ivscc_apfrequency` (the one with the `GetAnalysisBrowserGUIFolderSelection`
  wave-versioning bug noted elsewhere in this file) -- confirmed via `git log` that
  `ListBoxSelectAll` does not exist in `MIES_Utilities_GUI.ipf` on `feature/2754-...` at all. A
  `git reflog` entry mid-session showed a checkout from 2737 back to 2754 that was missed at
  the time (compounded by the 5-autostash situation noted below), so the "lost test edits"
  incident this session, and the reproducible `UTF_Utils_GUI.ipf:241:1: error: expected a
  keyword or an object name` compile error investigated right after, were **not** evidence of
  Igor Pro compiler/process corruption as suspected in the moment -- they were simply a real,
  mundane bug: re-adding a test that calls `ListBoxSelectAll(selWave)`, a function that
  genuinely does not exist in the currently-checked-out branch's compiled environment. Quitting
  and relaunching Igor Pro fresh (to rule out stale process state) reproduced the identical
  error, which in hindsight makes sense for an undefined-symbol problem but was, at the time,
  read as evidence *against* a real code bug. **Lesson, an extension of the existing
  `included_procedure_files` methodology rule above: verify not just that a file is included,
  but that the specific function/symbol being tested actually exists in the currently
  checked-out branch/environment**, especially mid-session after any branch switch -- a
  function seen once earlier in the same conversation is not guaranteed to still exist if the
  working tree has moved to a different branch since. The user has since reverted
  `UTF_Utils_GUI.ipf` back to matching `feature/2754-...`'s own HEAD, with none of the
  `ListBoxSelectAll` test work in it; that test coverage properly belongs on
  `feature/2737-prepare2_ivscc_apfrequency` instead, not this branch.

## Git note

`.git/packed-refs` was observed truncated (trailing NUL bytes, "unterminated line" error
blocking all git commands) partway through an earlier session. **Resolved/non-issue as of
this session**: `git status`/`git log` ran cleanly (checked while investigating whether
this session's local fixes had reached the PR branch), confirming it was a transient
artifact of the folder mount rather than lasting repo damage.
