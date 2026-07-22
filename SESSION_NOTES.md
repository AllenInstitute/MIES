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

**The user usually says when they've switched git branches, but may occasionally forget.
If something inconsistent turns up after a new user message** (a function/file that should
exist doesn't, a line number or piece of code referenced earlier in the conversation no
longer matches what's on disk, an unexpected compile/test result, etc.) **— check `git
branch --show-current` (and/or `git log -1`) before assuming a code regression or a mistake
on Claude's part.** Concretely confirmed once already this session: mid-conversation
assumptions about a file's content/line numbers (carried forward from earlier turns) turned
out to be stale after the user switched branches without an explicit callout, since the same
physical working directory is shared between the bash tool and the Read/Edit/Grep file
tools — a branch change changes what both see identically and immediately.

**Whenever a branch switch is confirmed or discovered (see above), check
`Packages/MIES/MIES_ClaudeScrapCode.ipf` and clean it up if needed.** This file is
intentionally never committed (untracked, `#include`d from `MIES_Include.ipf` purely for
interactive Claude Desktop sessions -- see the file's own header comment). Scratch helper
functions written for one branch's task frequently call `static`/module-qualified functions
or reference window/structure names from the main MIES codebase that may not exist, or may
behave differently, on the next branch checked out -- so old scratch code can silently fail
to compile, or "succeed" while doing something meaningless, after a switch. No fixed
required approach: remove the stale functions entirely, or adapt them to the new branch's
actual code, whichever fits -- judge case by case; some scratch helpers may simply no longer
have a meaningful purpose once the branch changes and are better deleted than patched.

**`read_session_history()` should always be saved straight to a file, not read inline.**
The user has seen Igor's history area grow past 10,000 lines in normal use, especially
during test runs with heavy log output — inline reads reliably exceed the context window
past a certain point in any long session. Default to writing the result to a file first
(e.g. via the bash tool) and `grep`/search it for the specific markers needed (`error:`,
`Finished with no errors`, a specific test-case name, etc.), the same technique already
worked out and written up further below, rather than waiting to hit the token-limit error
first.

**Reach for `ipt`/`ipt.exe` (the Igor Programming Tool -- `tools/ipt` (Linux),
`tools/ipt.exe` (Windows), `tools/run-ipt.sh` picks the right one) proactively in any Igor
Pro related workflow where it can plausibly sharpen understanding, not only when explicitly
asked for a parse/AST** — use it as a standing habit alongside direct reading of the source,
not as a replacement for it. Concretely, per subcommand (see the "`tools/ipt`" section below
for the full write-up of each, including confirmed gaps/bugs):
- `ipt check [--print-ast] <files>` — confirm a file/edit actually parses, or get an
  authoritative AST (node types, precise line:column spans) for understanding a function's
  real structure without needing a live Igor Pro instance.
- `ipt lint <files>` — catch known real bug/style patterns (e.g.
  `BugproneReservedKeywordsAsIdentifier`) before or instead of relying on manual review for
  those specific cases; know its confirmed gap (no built-in-*function*-name-shadowing
  detection, since it has no symbol-resolution semantics for that).
- `ipt rename --print-symbol-table <files>` (plus a full `-f`/`-l`/`-c`/`-n` target to avoid
  the no-target crash bug noted below) — get a genuine cross-referenced symbol table
  (declarations, every read/write/definition point with exact spans, function signatures)
  for a file when tracing how a variable/function is actually used matters more than just
  seeing the parse tree; also usable for the rename itself (preview without `-y`, apply
  with it).
- `ipt analyze` — available but not yet evaluated this deeply in this repo; worth trying
  when a task's shape matches its evident purpose (broader rule-based analysis) rather than
  assuming it's irrelevant.
- `ipt format` — confirmed in real use this session: the user ran it directly against
  `MIES_ClaudeHelper.ipf` right after moving a `static Constant` block to a new location by
  hand. The resulting file was consistently formatted throughout (aligned `=` signs across
  runs of consecutive assignment/declaration lines, a blank line separating a function's
  local-variable declarations from its first statement), not just around the lines that had
  just been edited by hand -- worth reaching for after any manual restructuring, not only
  after small line-level edits.
- **`ipt.exe` only ever knows about the file(s) explicitly passed via `files`/`-f`** — it
  does not resolve `#include`s itself, so pass every file actually relevant to the question
  at hand rather than assuming cross-file context comes for free. **In practice this is a
  non-issue when a live Igor Pro instance is available through the bridge, and should not
  be treated as a reason to skip `ipt` or reach for it half-heartedly**: `get_environment_
  summary()`'s `included_procedure_files` field already reports the complete, authoritative
  list of every procedure file actually included in the running instance right now (derived
  from `WinList(..., "WIN:128")`) -- exactly the context `ipt` needs, obtained without
  guessing or grepping for `#include` lines by hand. The one extra step: that field returns
  bare file names (e.g. `MIES_ForeignFunctionInterface.ipf`), not filesystem paths, so
  resolve each name to its actual on-disk path (a repo-wide filename search/glob; names are
  effectively unique across this codebase) before passing the list to `ipt` as its `files`
  argument. Combine the two rather than treating them as unrelated tools.

**When Igor's own `.ihf` help files are relevant to a question (e.g. confirming an
operation's exact flags/behavior), prefer reading them as Igor notebooks through the bridge
over an OS-level file read** -- snapshot currently-open help windows (`WinList("*", ";",
"WIN:512")`), `CloseHelp/ALL`, `OpenNotebook/R "<path>"`, `SaveNotebook/O/S=5/H=...` to
export as HTML (surfaces genuine content-block structure via named paragraph classes like
`Topic`/`Code1`/`Steps`, not just flat text), `KillWindow/Z` the temporary notebook, then
restore each snapshotted file via `OpenHelp/V=.../INT=0` -- see the dedicated section below
for the full non-destructive, repeatable workflow.

**Commands sent to Igor Pro through the bridge's COM interface (`execute_igor_command(_unattended)`)
run the same way as Igor's own command line: as *interpreted* code, not compiled procedure
code.** Several Igor language features only work inside compiled functions and are rejected
(often with an unhelpful generic error) when attempted directly this way -- confirmed this
session: `Make/FREE ...` (free waves have no valid scope outside a function), `WAVE ref =
SomeFunc()` (assigning a wave reference from a function call), and calling a `static`
function by its bare name (it's scoped to its file's `#pragma ModuleName` and needs
`ModuleName#FunctionName` from outside that module). **Workaround: create/extend a small
compiled scratch procedure file (e.g. `Packages/MIES/MIES_ClaudeScrapCode.ipf`), `#include`
it from `Packages/MIES_Include.ipf`, `reload_and_compile_procedures`, then call a single
compiled helper function from that file via the command line/Execute2** -- everything inside
the function body runs as compiled code, so none of the above restrictions apply. (A
differently-named prior-art scratch file, `MIES_ClaudeHelper.ipf`, was used the same way on
an earlier branch for a compile-confirmation hook -- same pattern, different specific
filename/purpose; there is no single fixed required name, just the `#include`-a-scratch-file
approach.) See the bridge section below for the concrete Analysis Browser example.

**Whenever writing or editing code in ANY Igor Pro procedure file (`.ipf`) in this repo --
not just Claude-authored scratch/bridge-helper files like `MIES_ClaudeHelper.ipf`, but
existing production MIES code too -- apply these three style conventions as standard
practice, not just when a specific function happens to prompt them (confirmed as the user's
explicit, general preference, applying to any `.ipf` file; first applied to
`CH_ListXOPExports`/the `CH_PE*` helpers in `MIES_ClaudeHelper.ipf`, see that section below
for the worked example):**
1. Use lowercase type keywords (`variable`, `string`, not `Variable`/`String`), and declare
   all of a function's local variables at the very top of its body, before the first
   statement -- matching Igor's own function-level (not block-level) scoping.
2. Use Igor 7+ inline parameter-type declarations in the function signature itself
   (`Function/S Foo(string bar, variable baz)`), not the old two-part style
   (`Function/S Foo(bar, baz)` followed by separate `string bar` / `variable baz` lines).
3. Replace unexplained numeric *and* string literals with named `static Constant`s /
   `static StrConstant`s declared at the top of the file, rather than leaving "magic
   numbers" (or magic strings) inline -- one constant per distinct meaning, with a trailing
   comment explaining what it represents when that isn't obvious from the name alone. This
   covers both kinds of literal equally; don't treat strings as exempt just because their
   meaning often looks self-evident in context.

**Always run `ipt format` (see the `tools/ipt` section below) immediately after editing any
`.ipf` file in this repo, every time, not as an optional habit** -- the user relies on its
canonical formatting to make the diff easier to review on their end. Re-verify behavior is
unchanged afterward (recompile, re-run whatever live test previously established
correctness) before considering the edit done.

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
- **`NewPath`/`PathInfo`'s `S_path` always returns Igor's colon-separated native path
  notation, even on Windows** -- confirmed live: normalizing `"C:\Projects\mies_data\
  ivscc_apfrequency"` via `NewPath` + `PathInfo $symbPath; S_path` produced
  `"C:Projects:mies_data:ivscc_apfrequency:"` (colon-delimited, trailing colon), not a
  backslash Windows path. This is the same normalized form MIES's own Analysis Browser
  stores internally (e.g. in its folder-list wave), so anything comparing against or
  displaying that value should expect colon notation regardless of host OS, not assume
  Windows paths stay backslash-separated after a round-trip through a symbolic path.
- **Variables declared on the Igor command line via `execute_igor_command(_unattended)`
  (e.g. `String win`) persist as global command-line variables across separate Execute2
  calls within the same Igor session** -- they are not scoped to a single bridge tool call.
  Re-declaring the same name in a later call fails with `"the name already exists as a
  variable"`; just assign to it directly (skip the `String`/`Variable` declaration) in
  follow-up calls, or expect this persistence when debugging multi-call command-line
  sequences.
- **Igor's command line does not support multi-line control-flow blocks (`if`/`else`/
  `endif`, `for`/`endfor`) the way compiled functions do.** A command sent via Execute2
  containing such a block fails as a whole (every line reported `NOT EXECUTED`, with a
  generic `expected wave name, variable name, or operation` error), even though each
  individual line would be valid inside a real function. This is a second, independent
  reason (beyond free waves/`WAVE ref = func()`/`static` scoping) to move any nontrivial
  logic into a compiled scratch-file helper function rather than a raw multi-statement
  Execute2 command -- see the standing-instruction note above.

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

## SweepFormula `and`/`with` keywords are a plotter-targeting concern, not an executor one

Clarified by the user: a SweepFormula expression itself may not contain line
breaks, so `and`/`with` (which must each stand alone on their own line) can
never appear *inside* an expression parsed/run by `SFE_ExecuteFormula`/
`SFE_ExecuteVariableAssignments` -- that's why those two functions' doc
comments say they don't support `and`/`with`, and why the JSON-based executor
(`SFE_FormulaExecutor`) never has to know about them at all. `and`/`with` are
recognized in an earlier, separate post-processing step that splits the SF
notebook text into individual single-expression formulas, and they solely
control *where the plotter puts each expression's result* -- `with` targets
the same plot sub-window as the previous expression, `and` targets a new one.
The executor always just returns the result of one already-isolated
expression; the plotter is what reads `and`/`with` to decide placement. So
there is no way to feed `and`/`with` through `SFE_ExecuteFormula` even
indirectly (e.g. via a nested/generated formula string) -- it would need to
go through the notebook-level splitting step first, which these two
executor-only entry points never invoke.

## SweepFormula executor position trackers are not restored on nested-call return

Working out `TestAssertDataStack3OP` (see the assert-data-stack test
consolidation above) raised whether two nested (`newFrame = 1`) calls made
sequentially from the same outer/dispatched operation instance could ever
freeze the outer frame's `LOCMSG` with two different, correct texts (one per
nested call). Traced through the code: `SFE_FormulaExecutor` unconditionally
overwrites the global `GetSweepFormulaJSONPathTracker` (and similarly the
`SRCLOCID`/`STEP` fields via `SFH_StoreAssertInfoExecutor`) on every call, and
nothing restores the outer frame's own former tracker value after a nested
call returns -- the tracker is simply left holding whatever the nested call
last set. Consequence: a single dispatched operation making two sequential
nested calls has no way to get the outer frame's *own* position re-frozen
correctly a second time (it would still reflect the first nested call's
position) -- the only way the outer frame's position genuinely changes
between two freezes is if something *external* to the operation (e.g. the
`SFE_ExecuteVariableAssignments` assignment loop moving to the next
assignment) re-stamps it via `SFH_StoreAssertInfoParser`/`Executor` in
between. The user confirmed there's currently no use case needing two
different frozen texts from the same outer frame (the final SFH_ASSERT
message is a one-shot terminal event), but flagged this as something to
revisit if a non-terminal message type (e.g. warnings that must be kept
correct across multiple points) is ever introduced.

## Igor Pro Universal Testing Framework: `IUTF_TD_GENERATOR`/`UTF_TD_GENERATOR` tag scanning

The advanced.rst docs are ambiguous/contradictory about how far above a
multi-data test case's `Function` line the tag comment can be (one place says
"within four lines", another says "all lines above `Function` up to the
previous `Function`"). Checked the actual implementation,
`GetFunctionTagWave` in `Packages/igortest/procedures/igortest-functiontags.ipf`:
it uses `ProcedureText(funcName, -1, ...)` minus `ProcedureText(funcName, 0,
...)` to isolate every comment line between the previous function's `End` and
this function's `Function` line, then scans *all* of those lines (looping
backwards), trying every known tag pattern against each non-empty line and
silently skipping (no error) any line that doesn't match one. There is no
four-line cutoff in the code -- the "all lines up to the previous Function"
description is the accurate one. This means ordinary `///` doc-comment lines
can be freely mixed in above a `// IUTF_TD_GENERATOR ...` tag line (they just
won't match any tag pattern and are skipped), so there was no need for the
earlier caution of keeping the tag as the only comment line directly above
`Function`.

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

## SweepFormula operation pattern: backup/restore the variable storage to run
## nested formula code in a scratch environment

`ivscc_apfrequency()` (`SFO_OperationIVSCCApFrequency`/`Impl2` in
`MIES_SweepFormula_Operations.ipf`) implements itself partly by composing
*other* SweepFormula operations (`select`, `merge`, `prepareFit`, `fit2`, ...)
rather than reimplementing their logic directly, using a
backup/mutate/restore pattern on the per-graph SweepFormula variable storage
(`GetSFVarStorage(exd.graph)`, a `WAVE/WAVE` keyed by variable name, populated
by `$varName`-style references between formula lines):

1. `SFO_OperationIVSCCApFrequencyPrepareVariables` takes `WAVE/WAVE varStorage
   = GetSFVarStorage(exd.graph)` and makes a `Duplicate/FREE` copy,
   `varBackup`, preserving the caller's existing variables untouched.
2. It then builds an ordinary SweepFormula source string on the fly (e.g.
   `"sel = select(selsweeps(), selstimset(...), selvis(all),
   selivsccsweepqc(passed))\r"` plus per-experiment/avg-plot expressions,
   assembled via `SF_AddExpressionToFormula`) and runs it for real through
   `SFE_ExecuteVariableAssignments(exd.graph, formula, allowEmptyCode = 1)` --
   i.e. it re-enters the actual formula executor with dynamically generated
   code, exactly as if the user had typed those lines into the SweepFormula
   notebook themselves. This mutates the *live* `varStorage` in place with all
   of that scratch computation's intermediate variables (`sel`,
   `ivsccavg_merged`, per-experiment `freqNorm<i>`/`currentNormMerged<i>`,
   etc.).
3. `SFO_OperationIVSCCApFrequencyImpl2` reads whatever it needs back out of
   that now-mutated `varStorage` (by name, e.g. `varStorage[%ivsccavg_norm_y]`)
   to build the actual plot trace data.
4. Before returning, it restores the original state with `Duplicate/O
   varBackup, varStorage` -- wiping out all of its own scratch/intermediate
   variables -- and only *afterward* re-adds the specific outputs it actually
   wants to persist for the user (`SFH_AddVariableToStorage(exd.graph,
   "ivscc_apfrequency_explist_" + tagSuffix, ...)`,
   `"ivscc_apfrequency_fit_" + tagSuffix`, one set per tag group).

Net effect: the operation gets to reuse the real formula executor and other
real operations as implementation building blocks, using the shared variable
storage as a scratch workspace, without leaking any of its own internal
temporary variable names into the user's persistent SweepFormula environment
once it's done -- only the deliberately-named, explicitly re-added outputs
survive. Confirmed directly from source (`MIES_SweepFormula_Operations.ipf`
lines ~3339-3365 and ~3390-3509), per the user's own explanation of the
approach.

**Two identified architectural gaps in generalizing this pattern (user's own
analysis, verified against source):**

1. ~~**No exception safety.**~~ **Reassessed by the user: this is a non-issue,
   not a gap.** Originally flagged: neither `SFO_OperationIVSCCApFrequencyPrepareVariables`
   nor anything above it in the call chain (`Impl2`, the operation dispatch,
   all the way up) wraps the nested `SFE_ExecuteVariableAssignments` call in a
   `try`/`catch` -- the *only* `try`/`catch` in the whole path is the one in
   `SF_button_sweepFormula_display` itself -- so if the scratch formula aborts
   via `SFH_ASSERT`, that level's own `Duplicate/O varBackup, varStorage`
   restore step never runs, leaving `varStorage` in its mutated/scratch state.
   **The user's correction**: this is fully OK given how SweepFormula's
   execution model actually works. A failed evaluation simply means there is
   no valid result -- SweepFormula has no concept of updating an
   already-displayed plot in place, so there is no code path that could ever
   observe or render the stale `varStorage` contents between the abort and
   the next run. And as already noted above, `SFE_ExecuteVariableAssignments`
   unconditionally wipes `varStorage` back to 0 rows at the start of its own
   next invocation regardless, so the leftover state doesn't linger or
   accumulate either. No fix needed here; not pursuing this further.

2. **No per-call-level source-location tracking, so nested-operation errors
   get misattributed to the wrong place in the notebook.** Traced precisely:
   `GetSFAssertData()` (`MIES_WaveDataFolderGetters.ipf`) is a single flat,
   *non-stacked* per-graph text wave (`SFAssertData`, 8 fields: `JSONID`,
   `SRCLOCID`, `JSONPATH`, `STEP`, `LINE`, `OFFSET`, `FORMULA`,
   `INFORMULAOFFSET`), written in place by `SFH_StoreAssertInfoParser`/
   `SFH_StoreAssertInfoExecutor` (`MIES_SweepFormula_Helpers.ipf`) every time
   *any* formula gets parsed/executed -- including a nested
   `SFE_ExecuteVariableAssignments` call like the one inside
   `SFO_OperationIVSCCApFrequencyPrepareVariables`. When that inner call
   parses its own dynamically-built scratch formula (e.g. `"sel =
   select(...)"`), it overwrites the *same* global `LINE`/`OFFSET`/`FORMULA`
   fields with values relative to *that* internal string, clobbering
   whatever the outer (real, user-visible) formula's own values were.
   Crucially, `SF_CalculateErrorLocationInNotebook` (`MIES_SweepFormula.ipf`)
   *always* re-reads the real, on-screen SF notebook's text
   (`GetNotebookText(BSP_GetSFFormula(win), mode = 2)`) and blindly indexes
   into it using whatever `info[%LINE]`/`info[%OFFSET]` currently hold --
   with no way to know those numbers actually describe a position inside an
   entirely different, invisible string (`ivscc_apfrequency`'s own generated
   formula) rather than the real notebook. The result: an assert inside a
   nested operation call resolves to some essentially coincidental position
   in the *outer*, user-visible formula (in this repo's typical case, the
   `ivscc_apfrequency()` call site itself, since the inner formula's line 0
   gets misread as notebook line 0) -- not the actual failing sub-expression,
   which was never textually present in the notebook at all.

   **User's proposed fix**: replace the single-frame `SFAssertData` wave with
   a wave-reference wave used as a LIFO stack -- each nested formula-execution
   episode pushes its own independent frame (mirroring today's 8 fields) on
   entry, and error-message construction needs extending to walk *every*
   frame on the stack (not just the current/top one) so a nested failure's
   message can show the full call chain, e.g. innermost failing sub-formula
   plus which outer operation (`ivscc_apfrequency()`) invoked it and at what
   notebook location. **Noted interaction with gap 1**: the aggregated
   error message must be built by walking the stack *at the moment
   `SFH_ASSERT` fires*, before any unwinding -- relying on a normal
   push-on-entry/pop-on-return discipline alone would never populate a
   correct message on the failure path itself (that's precisely the path
   where "pop" never executes, per gap 1), and conversely, if the stack isn't
   explicitly reset somewhere (e.g. alongside `SF_ClearSFOutputState()`),
   stale frames from a previous aborted run would corrupt the *next* run's
   tracking. Also worth covering when implementing: `SRCLOCID` is a JSON id
   requiring `JSON_Release` (currently released once, in
   `SFH_GetAssertLocationMessage`/`SF_MarkErrorLocationInNotebook`'s cleanup)
   -- with multiple stacked frames, every frame's JSON id needs releasing
   during error handling/reset, not just the top one.

   Not yet implemented -- discussed/designed only so far in this session; the
   user has not yet asked for code changes.

### Gap 2 fix implemented: LIFO assert-data stack

Implemented per the design above, with one refinement discovered while
implementing: the *global* execution-position trackers
(`GetSweepFormulaJSONPathTracker()`/`GetSweepFormulaBufferOffsetTracker()`,
`MIES_GlobalStringAndVariableAccess.ipf`) only ever reflect whatever is
executing *right now* -- they're updated on every recursion level/token,
unconditionally, not scoped per formula-execution episode. So a naive
"walk the stack and read the live trackers for each frame" would give every
frame the *innermost* (currently-failing) position, not its own. Fix: freeze
each frame's rendered location message into a new `LOCMSG` field on that frame
at the moment a *deeper* frame gets pushed on top of it (i.e. while the live
trackers still reflect its position) -- see `SFH_PushAssertDataFrame`.

Files changed:
- `MIES_WaveDataFolderGetters.ipf`: `GetSFAssertDataStack()` (new, `WAVE/WAVE`
  LIFO, lazily created), `GetSFAssertData()` rewritten to return the
  top-of-stack frame (auto-pushing a base frame if the stack is empty).
  `SF_ASSERTDATA_NUMFIELDS` bumped 8 -> 9 for the new `LOCMSG` field.
- `MIES_SweepFormula_Helpers.ipf`: `SFH_PushAssertDataFrame()` (freezes the
  outer frame's `LOCMSG` first, then pushes a blank frame),
  `SFH_PopAssertDataFrame()` (asserts against popping the base frame;
  deliberately does *not* release JSON ids -- a normal return already released
  them via the ordinary executor success path, so releasing again here would
  double-release), `SFH_GetOutermostAssertDataFrame()` (stack[0], for
  notebook-position lookups), `SFH_ResetAssertDataStack()` (releases every
  remaining frame's `JSONID`/`SRCLOCID` via `JSON_Release(..., ignoreErr=1)`,
  then empties the stack). `SFH_GetAssertLocationMessage` refactored: the old
  per-frame logic moved unchanged into `SFH_GetAssertLocationMessageForFrame`
  (returns the frozen `LOCMSG` if present, otherwise computes fresh from the
  live trackers -- exactly right for whichever frame is currently on top), and
  the public function now walks the stack top-to-bottom, joining more than one
  non-empty frame message with `"\rCalled from:"`.
- `MIES_SweepFormula.ipf`: `SF_CalculateErrorLocationInNotebook` now reads
  `SFH_GetOutermostAssertDataFrame()` instead of `GetSFAssertData()` (only the
  outermost frame's `LINE`/`OFFSET` are ever real notebook positions);
  `SF_ClearSFOutputState()` now also calls `SFH_ResetAssertDataStack()`.
  `SF_MarkErrorLocationInNotebook`/`SF_IsExecutionErrorInVariable` needed **no
  change** -- both correctly keep top-of-stack semantics via the unchanged
  `GetSFAssertData()`.
- `MIES_SweepFormula_Operations.ipf`: the nested
  `SFE_ExecuteVariableAssignments` call inside
  `SFO_OperationIVSCCApFrequencyPrepareVariables` is now wrapped with
  `SFH_PushAssertDataFrame()`/`SFH_PopAssertDataFrame()`. No `try`/`catch` --
  on an abort, the pop is simply skipped, deliberately leaving that frame's
  data on the stack for the aggregate error message (gap 1, the exception
  -safety issue, is still open/unaddressed; this only fixes gap 2).

**Verified compiling and working live** (Igor Pro 9.06 Nightly, via the
bridge): added a temporary `ClaudeScrap_TestAssertStack()` smoke test to
`MIES_ClaudeScrapCode.ipf` simulating the exact scenario -- outer formula
reaches an operation call site (line 5, offset 2) -> operation pushes a frame
-> nested formula hits its own parser error and `SFH_ASSERT` fires (caught
here instead of propagating). Confirmed: the outer frame's `LOCMSG` freezes on
push; the outer frame's own `LINE`/`OFFSET` (5/2) are untouched by the nested
frame's write (0/3) -- the actual bug being fixed; the pushed frame is left on
the stack after the simulated abort (pop correctly skipped); the final
aggregated message is `"Nested op failed\r 1 +\rCalled from:\r
ivscc_apfrequency()"` -- both levels present, joined as designed; and
`SFH_ResetAssertDataStack()` empties the stack back to 0. This test function
is left in `MIES_ClaudeScrapCode.ipf` (harmless, no window/GUI interaction) in
case it's useful again.

**Pitfall hit and fixed while getting a clean compile, unrelated to this
task**: `MIES_ClaudeScrapCode.ipf` (the scratch file from earlier in this
session) wouldn't compile for two separate, unrelated reasons, both now fixed:
1. `Make/FREE/T/N=1 wFolder = {folder}` -- turned out to be a red herring; the
   idiom itself is valid (confirmed against `DAP_GetRadioButtonCoupling` in
   `MIES_DAEphys.ipf`), the real error was #2 below, just cascading to a
   nearby line. Split into `Make/FREE/T/N=1 wFolder` + `wFolder[0] = folder`
   anyway (harmless simplification).
2. **The actual cause, identified by the user**: every `MIES_AB#...`/
   `MIES_SF#...` module-qualified call in the scratch file relies on
   `#pragma ModuleName = MIES_AB`/`MIES_SF` etc., which are themselves gated
   behind `#ifdef AUTOMATED_TESTING` in each source file (e.g.
   `MIES_AnalysisBrowser.ipf` lines 4-6). `AUTOMATED_TESTING` is a test-only
   define (unlocks otherwise-`static`/private functions for test code) and is
   **not** defined in a regular MIES session -- so those module namespaces
   don't exist at all right now, and any `ModuleName#Function(...)` call
   referencing them is simply unresolvable. Fixed by stripping the reliance
   per-call: `AB_GetExperimentsIndices()`'s one-line body
   (`FindIndizes(expBrowserSel, col = 0, var = LISTBOX_TREEVIEW, prop =
   PROP_MATCHES_VAR_BIT_MASK)`) was reproduced inline in
   `ClaudeScrap_TagExperimentsViaGUI`/`ClaudeScrap_DumpExperimentTags` (its
   dependencies are non-static/non-gated); the `AB_UpdateColors()`/
   `AB_UpdateTagList()` calls were dropped entirely after confirming from
   source they're purely cosmetic (folder-list background highlighting and
   the tag-list summary panel respectively) and already re-triggered by the
   real button-click handler where it matters;
   `ClaudeScrap_AddAnalysisBrowserFolder`/`ClaudeScrap_GetSFPlotWindowInfo`
   were stubbed out (disabled, with an explanatory note) since their
   remaining dependencies (`AB_AddExperimentEntries`/`AB_CollapseAll`/
   `SF_GetDataDisplayWindowName`, the latter pulling in several more gated
   helpers/constants) weren't worth reproducing inline for disposable scratch
   code unrelated to the current task.

**Separate live-session pitfall hit while testing** (not a code bug): calling
`SFE_ExecuteFormula(formula, "test", ...)` with a made-up, nonexistent window
name triggers `DoAbortNow("The main panel is too old to be usable...")` from a
panel-version check deep in `MIES_BrowserSettingsPanel.ipf`/
`MIES_AnalysisBrowser_SweepBrowser.ipf`. Unlike a normal `Abort`, `DoAbortNow`
shows its alert dialog *synchronously before* unwinding, so it is not
suppressed by a `try`/`catch` around the call, and it blocks Igor's operation
queue the same way a stuck compile-error dialog does -- the bridge has no
auto-dismiss logic for this dialog title (only for "Function Compilation
Error"), so it required the user to close it by hand twice before this was
understood and the offending test function was deleted rather than retried.
Lesson: never pass a fabricated window name to SF/BSP-layer entry points in
this bridge; use a real, currently-open panel or avoid the panel-version-
checked code paths entirely (as `ClaudeScrap_TestAssertStack()` does, by
exercising `SFH_*`/`GetSFAssertData*` directly instead of going through
`SFE_ExecuteFormula`).

### Gap 2 fix: real UTF tests added, reviewed, and iterated on with the user

The user added their own real tests in `UTF_SweepFormula.ipf` (`TestAssertDataStack`/
`TestAssertDataStackOP`, then `TestAssertDataStack2`/`TestAssertDataStack2OP`),
using the test-only `testop(...)` SweepFormula operation
(`SF_OP_TESTOP`/`SFO_OperationTestop`, `#ifdef AUTOMATED_TESTING`-gated, with its
implementation swapped in per-test via the `GetSFTestopName(graph)` SVAR/`FUNCREF`
indirection) to exercise a **real 4-level-deep recursive** nested-call chain
(`testop(0)` -> `testop(1)` -> `testop(2)` -> `testop(3)`, failing at level 3),
rather than the single hand-simulated level in `ClaudeScrap_TestAssertStack()`.
Both now pass. Findings and fixes along the way:

- **How to actually run a single UTF test case via the bridge**: not by calling
  the (static, module-scoped) test function directly -- that bypasses the
  igortest framework's fixture setup/teardown and is unreliable (see the next
  bullet). The correct invocation, per the user: `RunWithOpts(testcase="<name>")`.
- **Pitfall hit calling a test function directly** (bypassing `RunWithOpts`):
  got `RTE 27 "MoveWave...the name already exists"` from
  `CreateEmptyUnlockedDataBrowserWindow()`/`CreateFakeSweepData()`, traced to
  leftover `DB_ITC16_Dev_0`/`DB_ITC16_Dev_02` DataBrowser windows already open in
  the session from earlier manual work -- an artifact of skipping the test
  runner's normal per-test cleanup, not a bug in the test itself. Resolved by
  using `RunWithOpts` instead, which passed cleanly.
- **Missing cleanup bug (found by review, fixed by user)**: `TestAssertDataStack()`
  originally never called `SFH_ResetAssertDataStack()` after its check. Since
  the assert-data stack lives at `GetSweepFormulaPath()` -- a single *global*
  path (`root:MIES:SweepFormula`), not per-graph -- leftover frames from an
  intentionally-aborted nested test like this one would persist for the rest of
  the Igor session and could corrupt any *later* test that also inspects
  `SFH_GetAssertLocationMessage()`'s output (stale frames' frozen `LOCMSG`
  would get walked and appended as spurious "Called from:" segments). Fixed by
  adding `SFH_ResetAssertDataStack()` + a `DimSize(...)==0` check at the end of
  the test; both `TestAssertDataStack`/`TestAssertDataStack2` now do this.
- **Wiring bug (found by review, fixed by user)**: `TestAssertDataStack2()`
  initially set `funcName = "UTF_SWEEPFORMULA#TestAssertDataStackOP"` (the
  *original*, `SFE_ExecuteVariableAssignments`-based operation) instead of
  `TestAssertDataStack2OP` (the new `SFE_ExecuteFormula`-based one) -- silently
  testing the same code path twice rather than the new one. One-line fix.
- **Trailing-space bug (diagnosed, fixed by user)**: after fixing the wiring
  bug, `TestAssertDataStack2` failed with two extra trailing spaces in the
  innermost `"testop(3)"` line of the message. Root cause:
  `formula = SF_AddExpressionToFormula("", expr)` appends a trailing
  `SF_CHAR_CR` (`return formula + expr + SF_CHAR_CR`) -- fine for the
  assignment-extraction path (`SF_GetVariableAssignments` pulls lines via
  `StringFromList`, which strips the separator, so the CR never survives into
  the stored formula text), but fatal for a bare-expression string fed straight
  into `SFE_ExecuteFormula`: since `"testop(3)\r"` contains no `=`,
  `SF_GetVariableAssignments` finds zero assignments and takes its early-return
  path, `return [$"", preProcCode]`, handing back the *whole string unchanged,
  CR intact*. That CR rides into `SFP_ParseFormulaToJSON`, ends up baked into
  the source-location JSON's stored formula text, and
  `SFH_FormatSourceLocationError`'s `ReplaceString("\r", formula, " ")` turns it
  into a trailing space when rendering the error message. Fixed by dropping
  `SF_AddExpressionToFormula` entirely in `TestAssertDataStack2OP` and
  `sprintf`-ing straight into the formula string passed to `SFE_ExecuteFormula`
  (which doesn't need/want a trailing CR -- other call sites in this file pass
  it bare strings like `"testop()"`).

### Design refactor by the user: push/pop centralized into `SFE_ExecuteVariableAssignments`/`SFE_ExecuteFormula` via a new `newFrame` flag

Rather than every caller manually bracketing its own nested-execution call with
`SFH_PushAssertDataFrame()`/`SFH_PopAssertDataFrame()` (the original design,
easy to forget), the user added an optional `newFrame` parameter (default 0) to
both `SFE_ExecuteVariableAssignments` and `SFE_ExecuteFormula`
(`MIES_SweepFormula_Executor.ipf`): when set, the function pushes a frame on
entry and pops it on every normal-return path itself. `SFO_OperationIVSCCApFrequencyPrepareVariables`,
`TestAssertDataStackOP`, and `TestAssertDataStack2OP` were all updated to just
pass `newFrame = 1` instead of the manual push/pop wrapper.

Reviewed this in detail and confirmed it's correct: the push happens before
anything that could consume the live execution-position trackers (and, in
`SFE_ExecuteVariableAssignments`'s case, after the harmless
`SF_GetVariableAssignments` parse, which never touches those trackers); pop
happens on every normal-return branch in both functions, including the
`singleResult` branch of `SFE_ExecuteFormula`; on abort, the pop is correctly
skipped everywhere (frame deliberately left for the aggregate message, matching
the original design intent); and `SFE_ExecuteFormula`'s own internal call to
`SFE_ExecuteVariableAssignments(graph, formula)` (inside its `preProcess`
block) correctly omits `newFrame`, since the outer push already covers that
inner call -- no double-push.

**Bug found (since fixed)**: right after this refactor, `TestAssertDataStack2OP`
still had a leftover manual `SFH_PopAssertDataFrame()` call immediately after
`SFE_ExecuteFormula(formula, exd.graph, newFrame = 1)` -- a copy-paste artifact
from before push/pop was centralized. Since `SFE_ExecuteFormula(..., newFrame=1)`
now pops its own frame internally on normal return, this extra call would have
double-popped (removing a frame belonging to a *different*, outer level) on any
non-aborting run. It was invisible in this specific test only because every
recursive call always ends in an abort at `result=3`, which skips straight past
it. Removed.

### Code style / convention fixes from the user

- Constants must be `static` "when possible" (i.e. whenever not needed
  cross-file) and, by convention, declared at the *top* of the procedure file,
  not inline near their first use. `SF_ASSERTDATA_NUMFIELDS`
  (`MIES_WaveDataFolderGetters.ipf`) was moved from an inline declaration next
  to `GetSFAssertDataStack()` up to the file's top-of-file constants block, and
  changed from a bare `Constant` to `static Constant` (confirmed it's only used
  within this one file). Non-static "global" constants are by convention only
  supposed to live in `MIES_Constants.ipf` -- audited every file touched by
  this task's diff and confirmed no other new global constants were
  introduced anywhere else.
- The new cross-file functions (`GetSFAssertDataStack`, `GetNewSFAssertDataFrame`,
  `SFH_PushAssertDataFrame`, `SFH_PopAssertDataFrame`,
  `SFH_GetOutermostAssertDataFrame`, `SFH_ResetAssertDataStack`) were checked
  against the same "static when possible" rule -- all of them are genuinely
  called across multiple files (`MIES_SweepFormula_Executor.ipf`,
  `MIES_SweepFormula.ipf`, `MIES_SweepFormula_Operations.ipf`, the UTF test
  file), so none can be made `static` without breaking those call sites. The
  one truly file-local helper, `SFH_GetAssertLocationMessageForFrame`, is
  already `static`.
- **Redundant getter-call pattern, caught by the user, fixed in two places**:
  both `GetSFAssertData()` and `SFH_GetOutermostAssertDataFrame()` originally
  re-called `GetSFAssertDataStack()` a second time *inside* the
  `if(DimSize(...)==0) SFH_PushAssertDataFrame() ... endif` block, apparently
  to "refresh" the reference after the push. This is unnecessary:
  `SFH_PushAssertDataFrame()` grows the *same* underlying wave via
  `Redimension`, it does not replace/recreate it, so the `WAVE/WAVE` reference
  obtained *before* the `if` already reflects the new size afterward -- Igor
  wave references stay valid across `Redimension` of the same wave. Removed
  the redundant second call in both functions.
  **Standing lesson to avoid repeating this**: before re-calling a getter a
  second time just to "pick up" a change made by an intervening function call,
  check what that intervening call actually does to the wave/data structure.
  If it only mutates or resizes the *same* object (`Redimension`, in-place
  wave-note edits, etc.) rather than replacing it (a fresh `Make` under the
  same name, or swapping in a different wave reference), the original
  reference obtained from the first getter call is still valid and current --
  a second call is dead weight and, worse, invites the reader to wonder if it
  matters (or to copy the pattern elsewhere believing it's necessary). Only
  re-fetch when the intervening call could plausibly have replaced the
  underlying object, not merely resized/mutated it.
- **Standing convention: unconditional `SFH_ASSERT(0, ...)` calls must use
  `SFH_FATAL_ERROR(...)` instead.** `SFH_FATAL_ERROR(message, [jsonId])` is
  exactly `SFH_ASSERT(0, message) // NOLINT` under the hood (see
  `MIES_SweepFormula_Helpers.ipf`), but its name and the (linter-suppressed)
  `SFH_ASSERT(0, ...)` inside make the "this always aborts, there is no
  condition to evaluate" intent explicit at the call site, rather than
  requiring the reader to notice a literal `0` first argument. Caught in
  `UTF_SweepFormula.ipf`'s `TestAssertDataStack3OP` test-op, which had
  `SFH_ASSERT(0, "TestOP result threshold reached")` in its unconditional
  failure branch -- changed to `SFH_FATAL_ERROR("TestOP result threshold
  reached")`. Apply this whenever writing a new unconditional abort in
  SweepFormula code, test or production.

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
  itself). Current implementation (as of the v1.18.0 fix below) also captures
  `modifiedBefore` via `ExperimentModified`/`V_flag` before touching the counter and
  restores unmodified state (`ExperimentModified 0`) afterward if it wasn't modified
  before — matching the sibling `AfterCompiledHook` in `MIES_IgorHooks.ipf`, so this
  hook never spuriously flips an otherwise-unmodified experiment to "modified" (see the
  v1.18.0 Copilot-review entry further down for why this matters specifically for this
  bridge).
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
  - **v1.20.0: follow-up Copilot comment, also acted on**: `launch_igor_pro_unattended`'s
    own `elevated else ...` ternary and `if elevated:` check had the same
    None-treated-as-False pattern. Behaviorally identical either way (None was
    already falsy), but changed to explicit `is True` checks anyway so the
    deliberate unknown-treated-as-not-elevated choice is unambiguous in the code,
    not just documented in prose. Packaged and delivered as v1.20.0, sha256-verified
    between build output and the repo copy, same as every prior version.
  - **Note**: this copy of SESSION_NOTES.md was carried over by the user from a
    different branch's working tree partway through a later session; entries for
    bridge v1.21.0 (relaxed reload/compile timing + the `is True` elevation fix),
    v1.22.0 (`get_bridge_version()`/`close_data_browser()`), and a clean 25-step
    Igor Pro crash stress test (0 crashes) exist in that other branch's copy but are
    not reflected here. Not re-added on this branch since they describe bridge/tool
    work rather than anything specific to this branch's code.
  - **Analysis Browser: programmatically added a folder to the source list**
    (`C:\Projects\mies_data\ivscc_apfrequency`), reproducing what the "Add Folder"
    button does after its (non-scriptable, OS-native) folder-picker dialog returns a
    path -- `AB_ButtonProc_AddFolder` in `MIES_AnalysisBrowser.ipf` calls
    `AB_AddElementToSourceList(folder)` then `AB_AddExperimentEntries(win, wFolder)`
    then `AB_CollapseAll()`. Hit exactly the three interpreted-vs-compiled
    restrictions noted above in immediate succession while trying to do this as raw
    Execute2 command-line statements: `Make/FREE/T wFolder = {folder}` failed
    (`/FREE` outside a function), `WAVE/T folderList = GetAnalysisBrowserGUIFolderList()`
    failed as a command-line assignment, and `AB_AddExperimentEntries`/`AB_CollapseAll`
    both failed by bare name because they're `static` and scoped to
    `#pragma ModuleName = MIES_AB` (active because this experiment's Procedure window
    has `#define AUTOMATED_TESTING`) -- calling them from outside that module needs
    `MIES_AB#AB_AddExperimentEntries(...)`/`MIES_AB#AB_CollapseAll()`. Resolved per
    the user's direct instruction: created `Packages/MIES/MIES_ClaudeScrapCode.ipf`
    (`#include`d from `Packages/MIES_Include.ipf`) holding one compiled function,
    `ClaudeScrap_AddAnalysisBrowserFolder(nativeFolderPath)`, that does the whole
    sequence internally (including the module-qualified calls) and returns
    `"<panel win>|<normalized folder>"`; called via `execute_igor_command_unattended`
    after a `reload_and_compile_procedures`. Confirmed working: folder list ended at
    exactly 1 entry (no duplicates from the earlier partial command-line attempts,
    thanks to a `FindValue` dedup check before adding), `get_environment_summary()`
    showed `MIES_ClaudeScrapCode.ipf` in `included_procedure_files` (252 total, up
    from 251) with a clean compile. Also had to clean up a stray global `wFolder`
    wave left behind at `root:` by an earlier failed command-line attempt (a
    `KillWaves/Z` line that never ran because the same command errored on an
    earlier statement) -- `top_level_waves` in `get_environment_summary()` is a good
    place to spot this kind of debris after an interrupted multi-statement
    Execute2 command.
  - **Analysis Browser: tagging experiments -- redone via actual GUI controls,
    not the internal static function, per explicit user correction.** First
    attempt tagged experiments by calling `MIES_AB#AB_AddTagToRow(idx, tag)`
    directly for each target row -- this produced the correct result but the
    user pointed out it "is not the way a human user would interact with the
    AnalysisBrowser Panel" and asked for it to be redone driving the panel's
    actual GUI controls via `MIES_ProgrammaticGUIControl.ipf`
    (`PGC_SetAndActivateControl`), after manually clearing the tags added the
    first way. Redone as `ClaudeScrap_TagExperimentsViaGUI` in
    `MIES_ClaudeScrapCode.ipf`: (1) click `button_show_tagcontrol` via PGC to
    reveal the Tag Control subpanel (`AnalysisBrowser#TagControl`, hidden by
    default on panel open), (2) type each tag into `setvar_tagcontrol_tagname`
    and click `button_tagcontrol_addtag` via PGC (both real controls -- this is
    exactly what `AB_ButtonProc_AddTagControl`/`AB_SetVarProc_TagNameControl`
    do, reached this time through genuine control interaction rather than by
    calling `AB_AddTagToSelectedExperiments`/`AB_AddTagToRow` directly).
    **Confirmed empirically, and user-confirmed as a known, correct limitation**:
    `list_experiment_contents` is a "mode=9" (treeview + checkbox-style)
    ListBox, and its multi-row *selection* cannot be driven through
    `PGC_SetAndActivateControl(win, control, val=row)` or the raw
    `ListBox ..., selRow=row` command at all -- both were tested directly
    (writing a small debug dump of the selWave's column-0 bits before/after)
    and neither changed the selection bit for this control style; there is no
    synthetic-mouse-click primitive available for this kind of listbox through
    the bridge. **`MIES_ProgrammaticGUIControl.ipf` does not support every
    possible GUI interaction -- ListBox row selection is a confirmed, known gap
    in `PGC_*`, not a bug in how it was called.** Consistent with the existing
    `ListBoxSelectAll` (Ctrl+A handler) convention already in this codebase:
    multi-select state for this listbox style is managed by writing
    `LISTBOX_SELECT_OR_SHIFT_SELECTION` directly into the selWave, not through
    any higher-level control API. So the final approach sets that selection bit
    directly for the target rows (the same mechanism `ListBoxSelectAll` uses),
    then performs the actual tag-adding step entirely through the real
    SetVariable/Button controls via PGC -- selection state is the one piece not
    driven through a GUI-control function, because no such function exists for
    it yet. Verified end-to-end: rows 0-1 tagged "a", rows 2-4 tagged "b",
    `hideState` for `button_show_tagcontrol` read back as `0` (subpanel
    genuinely shown, not just internally flagged).
  - **Select all + Load Sweeps into a new SweepBrowser + enable SweepFormula +
    execute a formula, all via real GUI controls/documented APIs.** Selection:
    `ListBoxSelectAll(GetExperimentBrowserGUISel())` -- the exact function
    `AB_ListBoxProc_ExpBrowser`'s own Ctrl+A handler calls, confirmed still
    present (non-static) on this branch too. Loading: set
    `popup_SweepBrowserSelect` to `"New"` and click `button_load_sweeps` via
    PGC -- `AB_ButtonProc_LoadSweeps` opens a new `SweepBrowser` window and
    loads sweeps for every selected+expanded experiment
    (`AB_GetExpandedIndices` starts from the same selection bit). The new
    window was identified by diffing `WinList(SWEEPBROWSER_WINDOW_NAME+"*", ";",
    "WIN:1")` before/after the click (loop-based list diff -- no ready-made
    "list difference" utility found). SweepFormula: enable via PGC on
    `check_BrowserSettings_SF` in `BSP_GetPanel(win)` -- confirmed correct
    against this codebase's own `TestDefaultFormula` test, which uses the
    identical control/value. Formula text: **`SF_SetFormula(win, formula)`**
    (non-static, in `MIES_SweepFormula.ipf`) is the documented, intended way to
    set the SweepFormula notebook's contents (`ReplaceNotebookText` under the
    hood) -- notebooks aren't one of PGC's supported control types, so this
    isn't a PGC call, but it's a real public API, not a bypass of anything;
    used once with `""` to clear, once with the real formula. Execute: click
    `button_sweepFormula_display` via PGC (matches `TestDefaultFormula` again).
  - **`GetNotebookText(win, mode=N)` mode pitfall, caught via a false alarm**:
    initially verified the notebook's content using `mode=4` (copied from
    unrelated `BSP_*` help-notebook code elsewhere in `MIES_BrowserSettingsPanel.ipf`)
    and got an empty string back even though `SF_SetFormula` had just set real
    text -- looked like `SF_SetFormula` was silently failing. **It wasn't**:
    `SF_GetCode` (`MIES_SweepFormula.ipf`), the function the Display button
    itself uses to read the notebook, explicitly calls
    `GetNotebookText(formula_nb, mode = 2)`. Reading back with `mode=2`
    correctly showed the real text every time. Lesson: don't assume a
    `getData`/similar mode number from one call site transfers to a different
    notebook/purpose -- check the specific reader the real code path uses.
  - **`ivscc_apfrequency()` executed with no error and DID produce real plotted
    output -- initial verification methodology was wrong, corrected by the
    user.** `GetSweepFormulaOutputSeverity()`/`GetSweepFormulaOutputMessage()`
    correctly showed a clean run (`SF_MSG_OK`, no error). But the "no visible
    output" conclusion drawn at the time was wrong, for two compounding
    reasons: (1) **SweepFormula plots into a separate, dedicated plotter
    panel, not into the SweepBrowser's own graph** -- so checking
    `TraceNameList("SweepBrowser", ...)` for new traces was checking the wrong
    window entirely (user explicitly corrected this: "The sweepformula
    plotter does not change the traces in the SweepBrowser graph but creates
    a new panel with graph or table subwindows"). The actual window is named
    `SweepFormula_plotsweepBrowser_graph`, and its traces live in a *child
    subwindow* (`ChildWindowList(...)` -> `graph0`), not at the panel's own
    top level -- `TraceNameList("SweepFormula_plotsweepBrowser_graph", ...)`
    alone is also empty; the real call is
    `TraceNameList("SweepFormula_plotsweepBrowser_graph#graph0", ";", 1)`.
    (2) The before/after `WinList("*", ";", "WIN:65535")` window-diff was run
    too late (in a separate debug call after the plotter window had already
    been created by the first real run), so by the time that diff ran, the
    window already existed in both the "before" and "after" snapshots and
    correctly showed as "not new" -- a false negative caused by diffing at
    the wrong point in time, not by the operation failing.
    **Confirmed working correctly**: `TraceNameList("SweepFormula_plotsweepBrowser_graph#graph0", ";", 1)`
    returned 13 real traces, including per-experiment traces
    (`T000000d0_a__Scn1a_R613X_B6_825669_02_09_02_nwb`, etc.) split into `_a__`/`_b__`
    groups matching the "a"/"b" tags applied earlier in this session (via
    `ClaudeScrap_TagExperimentsViaGUI`, still in effect -- confirming
    `ivscc_apfrequency()` auto-groups by existing experiment tags when no
    explicit `seltag` argument is given), plus computed
    `ivscc_apfrequency_concat`/`_DAScale`/`_DAScale_Avg`/`_avg_bins` traces per
    group. **Lesson for future verification of SweepFormula operations: check
    the dedicated `SweepFormula_plot*` panel and its child graph/table
    subwindows (via `ChildWindowList`), not the host DataBrowser/SweepBrowser's
    own graph** -- and take a window-list snapshot immediately before the
    triggering action, not in a later, separate diagnostic call.
  - **Better yet, per the user's follow-up explanation: don't discover the
    SweepFormula plot window via `WinList`/diffing at all -- derive its name
    deterministically.** MIES allows multiple simultaneous SweepBrowsers, each
    accepting its own SweepFormula input and creating its own independently-
    named SweepFormula plot window, precisely so they don't collide -- the
    naming is generated from the specific SweepBrowser/DataBrowser `graph`
    argument, not a global counter. Chain: `SF_FormulaPlotter` ->
    `SF_CreateDataDisplayWindow` -> `SF_GetDataDisplayWindowName`/
    `SF_NewSweepFormulaBaseWindow` (all `static`, module `MIES_SF` under
    `#pragma ModuleName`, since `MIES_SweepFormula.ipf` also gets that pragma
    when `AUTOMATED_TESTING` is defined -- same pattern as `MIES_AB` elsewhere
    in this file). Added `ClaudeScrap_GetSFPlotWindowInfo(graph)` to
    `MIES_ClaudeScrapCode.ipf`, calling
    `MIES_SF#SF_GetDataDisplayWindowName(graph, SF_DISPLAYTYPE_GRAPH, SF_DM_SUBWINDOWS, 0)`
    directly (module-qualified, all-global constants) -- confirmed it returns
    exactly `SweepFormula_plotsweepBrowser_graph#graph0` for `graph="SweepBrowser"`,
    matching the real window found manually, with the same 13 real traces.
    Note the `SF_DM_NORMAL`-mode variant (no `idx` suffix child window) is a
    *different*, non-existent name for this case (`WindowExists` false) --
    `SF_DM_SUBWINDOWS` is the mode actually used by the real plotter code, and
    already returns the fully-qualified `host#graph0` reference in one call
    (no need to manually append `"#" + SF_WINNAME_SUFFIX_GRAPH + "0"` on top
    of it -- that would double up the suffix). This is now the correct,
    robust way to locate a specific SweepBrowser's SweepFormula plot output,
    including when more than one SweepBrowser/plot is open at once.

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
- **`--print-symbol-table` lives under `ipt rename`, not `ipt check`** (corrected after
  actually running it -- `ipt check --help` has no such flag; `ipt rename --help` does,
  alongside its own `--print-ast`, which per its help text prints "each AST after symbol
  table creation"). **`ipt.exe` only ever knows about the procedure file(s) explicitly passed
  via the `files`/`-f` arguments** -- it does not resolve `#include`s or otherwise pull in
  the rest of the codebase itself, so a symbol table (or an AST) requested for one file only
  reflects that file's own top-level declarations, not anything defined in files it
  `#include`s or that `#include` it. Pass every file actually needed for a complete picture
  explicitly.
  - **Verified the output format is genuinely parseable**, live, against a small throwaway
    test file (`Function IPTSymTestAdd(variable a, variable b)` with a local `result`, plus
    a `static Function/S IPTSymTestGreet`, plus one global `Constant`). `ipt rename
    --print-symbol-table <file>` prints a structured cross-reference table, not a flat list:
    a top-level `files: [...]` block per input file (module name(s), and reference-only
    lists of its constants/structs/functions), followed by global `structures:`/`constants:
    `/`functions:`/`variables:` sections holding the *actual* records, each tagged with an
    `id: [address/counter]` (an ephemeral, process-memory-derived identifier -- confirmed by
    running twice and seeing different numbers both times; **not** stable across runs, so
    don't rely on it for anything beyond within-a-single-invocation cross-referencing).
    Records elsewhere just hold a `-> [id] kind: name` pointer back to the real one. Each
    function record carries its full signature (required/optional args, return type, `multi
    return types` for the `[a, b] = Func()` destructuring style) and a `variables:` list of
    pointers to every one of its params/locals. Each variable record carries `write points`/
    `read points`/`definition points` -- each a `statement: <NodeType> [line:col - line:col]`
    span -- distinguishing where a variable is declared/assigned versus merely read.
  - **Cross-checked this understanding against real rename behavior**: the test file's
    `result` local (`variable result = a + b`) showed exactly one `write points`/
    `definition points` entry at its `Declaration` statement (line 9) and one `read points`
    entry at its `ReturnStatementNormal` (line 10). Running an actual `ipt rename -f <file>
    -l 9 -c 11 -n resultRenamed <file>` (targeting that same declaration) previewed renames
    at exactly `9:11` and `10:9` -- matching the symbol table's own write/read points
    precisely, confirming the table was read correctly rather than just superficially.
  - **Gotcha hit while testing**: `ipt rename --print-symbol-table <file>` with *no* rename
    target (`-f`/`-l`/`-c`/`-n` all omitted) prints the full symbol table correctly, then
    **crashes** (`Bug: target file was not parsed`, `terminate called without an active
    exception`, exit code 134/SIGABRT) instead of exiting cleanly -- a real bug in `ipt`
    itself (`rename` apparently always expects a valid target even when only the debug
    printout is wanted). The printed symbol table content before the crash is complete and
    trustworthy regardless; just don't rely on the process's exit code in that no-target
    case, and prefer always supplying a valid target if a clean exit matters.
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

## Reading Igor Pro `.ihf` help files as formatted notebooks (better than an OS-level file read)

The user pointed out a second way to read Igor's own `.ihf` help files, beyond just reading
the raw file bytes at the OS level: `.ihf` files are themselves Igor formatted-text
notebooks, and any such notebook can be opened directly via `OpenNotebook`, then read back
through Igor's own notebook operations via the bridge -- confirmed live end-to-end against
`Igor Pro 9 Folder Nightly:Igor Help Files:Debugging.ihf`.

- **Igor pre-registers `.ihf` files as "open as a help file" via ordinary (often hidden)
  help windows -- `WIN:512` is the correct `WinList` bit for these, confirmed against
  `WinList` operation's own bit table** (1=graphs, 2=tables, 4=layouts, 16=notebooks,
  64=panels, 128=procedure windows, **512=help windows**, ...). An earlier pass through this
  investigation guessed `WIN:1024` for help windows and got an empty result, which was
  wrongly read as "the file is registered with no window object at all" -- corrected after
  actually checking `WinList`'s documented bit values: `1024` isn't a defined window type at
  all, so that query was meaningless, not evidence of anything. Re-tested with the correct
  bit: `WinList("*", ";", "WIN:512")` reliably lists every currently-open help file
  (including invisible ones), while adding `,VISIBLE:1` restricts to only the visible ones
  -- e.g. `Igor Reference.ihf` showed up in the plain `WIN:512` list but not the
  `VISIBLE:1`-qualified one, i.e. it was open as a hidden help window (Igor appears to open
  it in the background on its own, e.g. for command-line help lookups, independent of
  anything this session did explicitly). `OpenNotebook/R "<path-to-any-.ihf-file>"` fails
  with error 251 ("The file ... is already open but as a help file") whenever the target
  file's help window (hidden or not) is currently open -- a help-file view and a
  plain-notebook view of the same file are mutually exclusive.
- **The user's own manual technique**: hold Alt (Option on Mac) and click a help window's
  close button to close and unregister it, then reopen the same file via File > Open >
  Notebook. **Programmatic equivalent, found in `Igor Reference.ihf`**: the `CloseHelp`
  operation (added in Igor Pro 7.00). `CloseHelp/ALL` (closes every registered help window)
  confirmed working live -- immediately unblocks `OpenNotebook/R` on any `.ihf` file
  afterward. `CloseHelp/FILE="<path>"` (meant to close just one specific file) instead threw
  `error 140: expected window title` when tried against a full HFS-style path -- not yet
  resolved why; `/ALL` is the confirmed-working option and is harmless to use even when only
  one file matters, since Igor's help windows are cheap to reopen on demand.
- **Full plain-text readback**: after `OpenNotebook/R "<path>"` succeeds, find the resulting
  window's actual name via `WinList("*", ";", "WIN:16")` (Igor auto-assigns
  `Notebook0`/`Notebook1`/... unless `/N=name` was given to `OpenNotebook`), then:
  `Notebook <name> selection={startOfFile, endOfFile}` followed by `GetSelection notebook,
  <name>, 2` sets `S_Selection` to the notebook's entire text in one call (paragraph breaks
  come through as `\r`). Confirmed against `Debugging.ihf`: 20,554 characters, first ~400
  matched the file's actual visible content exactly.
- **Formatted-text export reveals genuine content-block structure, not just prose (the
  user's key hint)**: `.ihf` files are *formatted* notebooks, and WaveMetrics' own help
  authoring convention uses named paragraph styles for different content roles, not just ad
  hoc bold/italic/font-size choices. Exporting via `SaveNotebook/O/S=5/H={"UTF-8",
  writeParagraphProperties, writeCharacterProperties, PNGOrJPEG, quality, bitDepth} <name> as
  "<path>.html"` (saveType 5 = HTML export; confirmed with
  `writeParagraphProperties=3`/`writeCharacterProperties=7`, `SaveNotebook` V-823) produces a
  `<P class="...">` tag on every single paragraph, and the class name itself directly
  identifies the paragraph's semantic role -- confirmed live against `Debugging.ihf`'s
  export:
  - `Topic` -- a section heading (e.g. `<P class=Topic>Debugging</P>`).
  - `Subtopic` / `Subtopic-Indented` -- a sub-heading.
  - `TopicBody1` / `TopicBody1a` -- ordinary body prose.
  - `Steps` / `ListNumbered` -- bullet/numbered list items (e.g. `<P class=Steps>•	Using
    print statements</P>`).
  - `Code1` / `Code1a` / `Code-Indented1` -- a line of example code (e.g. `<P
    class=Code1>Function Test(w, num, str)</P>`).
  - `SeeAlso`, `NOTE`, `Table2Col`, `Table3Col`, `RelatedTopics` -- self-explanatory by name.
  This is strictly better than inferring structure from raw font weight/size, since the
  class names already encode the author's intended block type -- heading vs. body vs. code
  vs. list item vs. note -- with no guessing required.
- **Non-destructive, repeatable workflow (user-specified, live-verified end-to-end)**: the
  first pass through this technique left `CloseHelp/ALL` in effect permanently and never put
  the previously-open help file(s) back -- a real gap, since Igor may have had help windows
  open (visibly or in the background) before this workflow ever touched anything, and those
  shouldn't be lost as a side effect of reading a different file. Corrected workflow:
  1. **Snapshot what's currently registered as open help**, before touching anything:
     `String helpAll = WinList("*", ";", "WIN:512")` and `String helpVisible = WinList("*",
     ";", "WIN:512,VISIBLE:1")` (the latter needed to restore visible ones as visible, not
     just hidden).
  2. `CloseHelp/ALL`.
  3. `OpenNotebook/R "<path-to-.ihf-of-interest>"`; find the resulting window's actual name
     via `WinList("*", ";", "WIN:16")` (Igor auto-assigns `Notebook0`/`Notebook1`/... unless
     `/N=name` was given).
  4. `SaveNotebook/O/S=5/H={"UTF-8", 3, 7, 0, 0.9, 32} <name> as "<scratch-path>.html"` (path
     must be reachable by whatever reads it back -- e.g. somewhere under the bash-mounted
     repo), then read/parse the exported HTML for the `<P class=...>` per-paragraph
     structure.
  5. `KillWindow/Z <name>` to close the temporary notebook.
  6. Repeat steps 3-5 for any other `.ihf` files that need reading in the same session --
     no need to re-run `CloseHelp/ALL` again since it's already in effect.
  7. **Restore**: for each file name captured in step 1, `OpenHelp/V=(1 if it was in
     helpVisible else 0)/INT=0 "<resolved full path>"` (`/INT=0` suppresses any
     recompile-confirmation dialog; `WinList` only returns bare file names for help/procedure
     windows, so resolve each back to a full path -- e.g. by prefixing the known Help Files
     folder path, or matching against an `IndexedFile` listing of that folder).
  - Live-verified full round trip: before touching anything, `helpAll = "Igor
    Reference.ihf;"` (not in `helpVisible`, i.e. open hidden in the background). `CloseHelp/
    ALL` -> `OpenNotebook/R` on `Igor Shortcuts.ihf` (a file not touched earlier this
    session) opened as `Notebook1` -> HTML export showed new paragraph classes specific to
    this file's content (`ShortcutHow`, `ShortcutHow-7`, `ShortcutTo`,
    `SeeAlsoIndented`, alongside the already-known `Topic`/`TopicBody1`/`TopicBody1a`) --
    confirming the class-naming convention is genuinely per-content-role, not just a fixed
    set from one file. `KillWindow/Z Notebook1` closed it cleanly. `OpenHelp/V=0/INT=0
    "<path>...Igor Reference.ihf"` restored it: returned `V_Flag=0` (success) and
    `WinList("*", ";", "WIN:512")` immediately showed `Igor Reference.ihf;` again -- state
    fully restored. Scratch HTML export files deleted after each read; they have no lasting
    purpose once parsed.
  - **Caveat: expect drift between the snapshot and later checks.** `Igor Reference.ihf`
    reappeared in the `WIN:512` list at one point in this session even though nothing in this
    workflow had explicitly reopened it -- ordinary Igor Pro activity (e.g. command-line
    help lookups) can silently open/reopen certain help files in the background outside of
    any explicit `OpenHelp` call. Always take the snapshot (step 1) immediately before
    intervening, rather than trusting an earlier snapshot or assuming the set of open help
    files is static.
- **This entire technique only applies to XOPs that ship their own `.ihf` help file --
  not every XOP does.** Some XOPs that extend Igor Pro's built-in pool of
  functions/operations bundle a compiled `.ihf` help file of their own (readable via this
  same `CloseHelp`/`OpenNotebook`/`SaveNotebook` workflow, same as any of WaveMetrics' own
  help files) -- e.g. National Instruments' `DAQmx_*` operations. **Other XOPs ship no help
  file at all** -- per the user, the JSON XOP (used elsewhere in this codebase) is one of
  these; its documentation is only available externally, at
  <https://docs.byte-physics.de/json-xop/>.
- **Igor Pro loads XOPs/help files/fonts/procedure files from two places, joined together
  at startup into one environment (per the user, matching the "Igor Pro User Files" help
  topic)**: a **global** location, subfolders of the Igor Pro program folder itself (e.g.
  `...Igor Pro 9 Folder Nightly:Igor Extensions (64-bit):`), and a **user-specific**
  location, `<Documents>:WaveMetrics:Igor Pro <major-version> User Files:` (confirmed live:
  `C:Users:enigm:Documents:WaveMetrics:Igor Pro 9 User Files:` exists and, via
  `IndexedDir`, mirrors the exact same subfolder set as the global program folder --
  `Igor Extensions`, `Igor Extensions (64-bit)`, `Igor Fonts`, `Igor Help Files`, `Igor
  Procedures`, `User Procedures`). This resolves the open question from earlier this
  session about where `DAQmx`'s own help file actually lives, and turned up two more
  concrete, useful facts from the user's own installation (`IndexedFile(..., "????")` to
  list all files regardless of type, since `.ihf`-only filtering misses shortcuts):
  - `Igor Extensions (64-bit):` (user-specific) contains `NIDAQmx64.XOP - Shortcut.lnk`
    (a second reference to the same DAQmx XOP already found in the global folder) and
    `Debug  JSONXOP- Shortcut.lnk.dis`. **Corrected by the user**: the `.dis` suffix here
    is *not* Igor's disable-an-extension convention (initial guess, wrong) -- it's the
    user's own unrelated helper file for switching which JSON XOP build (release vs.
    debug) gets included. Lesson: don't assume a plausible-sounding Igor convention
    without checking -- a `.dis`-suffixed file sitting in an XOP folder isn't
    self-explanatory and can just as easily be project-specific tooling.
  - `Igor Help Files:` (user-specific) contains `NIDAQ Tools MX Help - Shortcut.lnk` (a
    shortcut to DAQmx's real help file -- confirming it does ship one, as expected) and
    `ZeroMQ.ihf` (a real, non-shortcut `.ihf` file) -- a second concrete, directly-readable
    example of an XOP-supplied help file via this same technique, alongside DAQmx.
  **Practical upshot**: before assuming an XOP operation/function can be looked up via this
  `.ihf`-reading workflow, check both the global and user-specific `Igor Help Files:`
  folders for it (`IndexedFile`/`IndexedDir`, `"????"` wildcard to include shortcuts), or
  just try `OpenNotebook`/`OpenHelp` and see if it resolves -- if neither location has one,
  fall back to that XOP's own external documentation instead of assuming no help exists at
  all.
- **`FunctionList`/`OperationList` (per the user) enumerate every function/operation
  actually available in the running instance, including ones added by XOPs -- a
  complementary way to know the live environment's real capabilities, independent of
  whether any given one happens to have a help file.** Confirmed live:
  `FunctionList("*", ";", "KIND:4")` (KIND:4 = "external functions, defined by an XOP")
  returned 244 functions this session, including the `fDAQmx_*` family (e.g.
  `fDAQmx_ReadChan`, `fDAQmx_ScanStart`); `OperationList("*", ";", "external")` returned 80
  operations, including the `DAQmx_*` family (e.g. `DAQmx_AI_SetupReader`,
  `DAQmx_CTR_CountEdges`). Cross-checked against the ZeroMQ XOP-help finding above and it
  matched exactly as expected: `FunctionList("*ZeroMQ*", ";", "KIND:4")` returned 21 real
  `zeromq_*` functions, consistent with `ZeroMQ.ihf` actually being present and loadable.
  **Corrected by the user on the JSON XOP check specifically**: the JSON XOP adds
  *operations*, not functions -- `FunctionList("*JSON*", ";", "KIND:4")` returning nothing
  was simply the wrong list to check, not evidence the XOP wasn't loaded (see the `.dis`
  correction above -- that file was never actually a disable marker in the first place).
  `OperationList("*JSON*", ";", "external")` is the correct check and returns 13 real,
  currently-loaded `JSONXOP_*` operations (`JSONXOP_Parse`, `JSONXOP_GetValue`,
  `JSONXOP_Dump`, `JSONXOP_AddTree`, etc.) -- the JSON XOP is loaded and fully functional in
  this instance; the earlier "not loaded" conclusion was wrong on two independent counts at
  once. **Practical use, corrected**: when unsure whether a given function/operation is
  actually available in the current live instance, check `FunctionList` for XOP-added
  *functions* (`KIND:4`) and `OperationList("*", ";", "external")` for XOP-added
  *operations* -- an XOP can contribute either or both, so check both list types rather
  than assuming from one empty result that an XOP contributes nothing at all.
- **Even more direct and conclusive, per the user: if currently-compiled code calls an
  XOP's operation/function and the instance is in compiled state, the XOP must be loaded --
  no separate enumeration needed at all.** `Packages/MIES/json_functions.ipf` (confirmed
  present in `included_procedure_files`) calls `JSONXOP_Parse`, `JSONXOP_Dump`,
  `JSONXOP_New`, `JSONXOP_Release`, `JSONXOP_Remove`, etc. directly (e.g. line 85:
  `JSONXOP_Parse/Z=1/Q=(JSON_QFLAG_DEFAULT) jsonStr`); Igor cannot compile a call to an
  operation that doesn't exist, so a clean `check_compilation_state()` (`compiled: true`)
  together with this file being included is already airtight proof the JSON XOP is loaded
  -- stronger and simpler than inferring it from an `OperationList` scan. **Even simpler
  still, and the one to reach for first**: `get_environment_summary()` already has a
  dedicated `loaded_xops` field for exactly this question -- confirmed live it lists
  `"JSON-64"` (and `"NIDAQmx64"`, `"ZeroMQ-64"`, etc.) directly by name. No need for
  `FunctionList`/`OperationList` scans, or the compiled-code inference above, when the
  question is simply "is XOP X loaded right now" -- `loaded_xops` answers that in one call.
  **Corrected by the user: `FunctionList`/`OperationList` do *not* actually solve the other
  question either (which specific entries a given XOP contributes) -- overclaimed above.**
  Both return a flat name list with no per-entry attribution back to the XOP that defined
  it (confirmed: neither operation's documented output includes an owning-XOP field, and no
  `IgorMan.md` search turned up any dedicated name-to-XOP lookup). In practice, attributing
  a specific function/operation name to a specific XOP relies entirely on already knowing
  that XOP's naming convention (e.g. `JSONXOP_*`, `DAQmx_*`, `zeromq_*` -- all human
  knowledge, not queryable from Igor). Diffing the list before/after loading only the XOP in
  question isn't a practical workaround either: no `IgorMan.md` search found any operation
  for loading/unloading a specific XOP at runtime, so XOPs are apparently fixed for an
  entire Igor Pro session (set only via which files sit in the Extensions folders at
  startup) -- there's no in-session way to toggle just one and diff. **Bottom line, per the
  user: with no documentation or source available for a given XOP, there is no simple way
  to determine which operations/functions it specifically contributes** -- `loaded_xops`
  and `FunctionList`/`OperationList` only answer "is this XOP loaded" and "what's available
  in total," not "which of these came from XOP X."

## Solved: extracting an XOP's operations/functions from its compiled binary, no source/docs needed

Follow-up to the "no simple way" conclusion just above. The user explained the actual mechanism:
an XOP is a DLL with a specific structure, and the list of operations/functions it adds to Igor is
encoded in that DLL's resources -- and gave read access to WaveMetrics' own XOP Toolkit 8.01
(`c:\download\XOP8.01\`, containing `XOPMan8.pdf` plus buildable sample-XOP source). Working
through the toolkit manual (`pdftotext -layout` extraction, `poppler-utils`'s `pdftotext` already
available in the sandbox) confirmed this in full, and a live test against real, closed-source,
already-compiled `.xop` files proved it works with zero vendor documentation or source needed:

- **The relevant resources are `XOPI` 1100 (required, general XOP info), `XOPC` 1100 (operations
  the XOP adds), and `XOPF` 1100 (functions it adds)** -- confirmed from the manual's "XOP
  Resources" chapter (`XOPMan8.pdf`, "There are three types of resources... XOP-specific
  ...WaveMetrics..."). On Windows, unlike the Macintosh `.r`/Rez-resource-fork mechanism, these
  are compiled by the **standard Windows resource compiler** from a `.rc` file (e.g.
  `WaveAccessWinCustom.rc`) directly into the `.xop`/DLL's own PE resource section, using the
  literal strings `"XOPC"`/`"XOPF"`/`"XOPI"` as the resource *type* name (not a numeric type) and
  `1100` as the resource ID -- confirmed directly from the manual's own words: "Igor examines
  these custom resources to determine what operations, functions and menus the XOP adds." This
  means any XOP's `.xop` file, being an ordinary PE/DLL, can have these extracted by any generic
  PE resource reader -- no proprietary format, no vendor cooperation needed.
- **Exact binary layout, confirmed from the manual's Chapter 5/6 (`XOPC`/`XOPF` Windows `.rc`
  source examples)**:
  - `XOPC` (operations): repeating `{null-terminated name string; int16 little-endian category
    bitmask}` records, terminated by a record whose name is the empty string (a single `0x00`
    byte) with no trailing bitmask after it.
  - `XOPF` (functions): repeating `{null-terminated name string; int16 category bitmask; int16
    return-type code; int16 parameter-type code}*N; int16 `0` to terminate that function's
    parameter list}` records, the whole resource terminated the same way as `XOPC` (an empty-name
    record).
  - Category/type bit meanings (`XOPOp`/`ioOp`/`compilableOp`/... for `XOPC`; `NT_FP64`/
    `WAVE_TYPE`/`HSTRING_TYPE`/... for `XOPF` return/parameter types; `F_UTIL`/`F_EXTERNAL`/...
    for `XOPF`'s own category bitmask) are all documented in the manual with their exact decimal
    values -- not needed just to get the name list, but available for full interpretation.
- **Live-verified against real, compiled, closed-source `.xop` files already present in this
  machine's global Igor Pro 10 install** (`More Extensions (64-bit)/.../*.xop` -- no need to build
  anything from the toolkit's own sample sources): using Python's `pefile` library (pure Python,
  `pip install pefile`, works even in this Linux sandbox against a Windows PE file) to walk the PE
  resource directory for a type entry named `"XOPC"`/`"XOPF"`, then the above byte-layout parser
  (implemented and run directly, not just theorized):
  - `NIGPIB2-64.xop`'s `XOPC` resource decoded to exactly the 10 operations already known from its
    `.r` source seen earlier in the XOP Toolkit (`NI4882`, `GPIB2`, `GPIBRead2`, `GPIBWrite2`,
    `GPIBReadWave2`, `GPIBWriteWave2`, `GPIBReadBinary2`, `GPIBWriteBinary2`,
    `GPIBReadBinaryWave2`, `GPIBWriteBinaryWave2`), each with category `0x1060` -- exactly
    `XOPOp(0x20) | ioOp(0x1000) | compilableOp(0x40)`, matching the source's `XOPOp | ioOp |
    compilableOp` declaration bit-for-bit.
  - `VISA64.xop`'s `XOPF` resource decoded to all 57 `vi*` functions (`viOpenDefaultRM`, `viRead`,
    `viWrite`, `viClose`, ...) with full parameter-type lists; `TDM64.xop` decoded to 63 `TDM*`
    functions; `SQL64.xop` to 79 `SQL*` functions; `AxonTelegraph64.xop` to 8
    `AxonTelegraph*`/`AxonTelegraphA*` functions -- all with sensible, correctly-decoded return
    and parameter type codes matching each function's evident purpose (e.g. `HSTRING_TYPE`
    (`0x2000`) return type on `*GetDataString`, `WAVE_TYPE`-flavored params on wave-taking
    functions).
- **This fully resolves the "no simple way" conclusion above, with one caveat**: it requires
  actual read access to the compiled `.xop` file's bytes (trivial for XOPs sitting in the global
  or user Extensions folders on the same machine, as confirmed this session), not just a live
  Igor Pro instance talking COM -- the Igor Pro Bridge itself has no channel for reading arbitrary
  files' raw bytes off the host disk today. Turning this into a proper bridge tool (e.g.
  `list_xop_exports(xop_path)`, using `pywin32`'s own resource APIs or bundling `pefile`) was
  not yet done this session -- flagged as a natural next step, not yet actioned.
- **Cross-validated against this repo's own production XOPs (`XOPs-64bit/*.xop`), including the
  exact two (`JSON-64.xop`, `ZeroMQ-64.xop`) whose loaded-function/operation lists were already
  independently confirmed earlier this session via live `FunctionList`/`OperationList` calls --
  and the static extraction matched the live runtime introspection exactly, both directions**:
  - `JSON-64.xop`'s `XOPC` decoded to precisely the same 13 `JSONXOP_*` operations already seen
    live via `OperationList("*JSON*", ";", "external")` (`JSONXOP_AddTree`, `JSONXOP_AddValue`,
    `JSONXOP_Dump`, `JSONXOP_GetArraySize`, `JSONXOP_GetKeys`, `JSONXOP_GetMaxArraySize`,
    `JSONXOP_GetType`, `JSONXOP_GetValue`, `JSONXOP_New`, `JSONXOP_Parse`, `JSONXOP_Release`,
    `JSONXOP_Remove`, `JSONXOP_Version`) -- same 13, no more, no fewer.
  - `ZeroMQ-64.xop`'s `XOPF` decoded to precisely the same 21 `zeromq_*` functions already seen
    live via `FunctionList("*ZeroMQ*", ";", "KIND:4")`.
  - Also decoded every other XOP in that folder, several directly relevant to this repo's own
    hardware-interface work this session: `MultiClamp700xCommander64.xop` (1 operation,
    `MCC_FindServers`, plus 65 `MCC_*` functions -- the amplifier-control layer behind
    `MIES_ForeignFunctionInterface.ipf`'s `FFI_*` wrappers this session added hardware tests
    for), `itcXOP2-64.xop` (32 `ITC*2` DAQ-hardware operations), `SutterXOP_Win-64.xop` (2
    operations, 69 functions), `TUF-64.xop` (7 `TUFXOP_*` operations -- this repo's own test
    framework support XOP), `MIESUtils-64.xop` (3 functions, `MU_GetFreeDiskSpace`/
    `MU_RunningInMainThread`/`MU_WaveModCount` -- this repo's own small utility XOP),
    `mies-nwb2-compound-XOP-64.xop` (2 operations, `IPNWB_WriteCompound`/`IPNWB_ReadCompound`).
  - **This means the technique isn't just a WaveMetrics-sample-XOP party trick -- it works
    identically on this specific codebase's real, in-use, already-compiled dependencies**,
    including ones with no external documentation at all (`MIESUtils-64.xop` appears to be
    built in-house for this repo specifically).

### Implemented as a pure Igor Pro procedure function instead of a bridge tool

Per the user's judgment call (this would be a rarely-used capability, not worth a permanent
bridge Python tool), reimplemented the whole PE-resource extraction from scratch as ordinary
Igor Pro procedure code -- `Function/S CH_ListXOPExports(string xopPath)` plus a dozen
`static` helper functions (`CH_PEReadU16`/`CH_PEReadU32`/`CH_PEReadBytes`/`CH_PECStringLen`/
`CH_BytesToU16`/`CH_PEReadUnicodeName`/`CH_PERVAToFileOffset`/`CH_PEFindResourceOffset`/
`CH_ParseXOPResourceBlob`/`CH_PEListXOPResource`) -- added to `MIES_ClaudeHelper.ipf`, inside
the existing `#ifdef IGOR_PRO_BRIDGE ... #endif` block alongside `AfterCompiledHook`. Uses
only `Open/R`, `FSetPos`, `FBinRead` (with `/F=2` or `/F=3`, `/U`, `/B=3` for little-endian
unsigned 16-/32-bit reads) and ordinary string operations (`strsearch`, substring indexing,
`char2num`/`num2char`) to walk the PE header, section table, and 3-level resource directory
tree (Type -> ID -> Language) entirely by hand, find the named `"XOPC"`/`"XOPF"` resource
type's `CH_XOP_RESOURCE_ID` (1100) entry, and decode it per the binary layout documented above
`CH_ListXOPExports` in the file itself. Only supports 64-bit (PE32+) XOPs (every XOP actually
in use in this repo) -- aborts clearly for a 32-bit one rather than misreading it. Returns
`"operations:op1;op2;...\rfunctions:func1;func2;..."`.

**Three style passes applied after the initial working implementation, each re-verified
end-to-end against `JSON-64.xop`/`ZeroMQ-64.xop` (identical output every time -- no
regressions from any of these):**
1. Lowercased the `Variable`/`String` type keywords to `variable`/`string`, and moved every
   function's local-variable declarations to the very top of its body (matching Igor's own
   function-level, not block-level, scoping -- see the language-facts note above), per the
   user's explicit style preference.
2. Converted every function signature from the old two-part style
   (`Function/S Foo(paramName)` + a separate `string paramName` line) to Igor 7+'s inline
   parameter-type declarations (`Function/S Foo(string paramName)`), removing the
   now-redundant standalone type lines, per the user's explicit request.
3. Replaced every unexplained numeric literal in the PE-parsing code with a named
   `static Constant` -- PE/COFF structure signatures and offsets (`CH_PE_DOS_SIGNATURE`,
   `CH_PE_SIGNATURE`, `CH_PE_E_LFANEW_OFFSET`, `CH_PE_OPTIONAL_HEADER_MAGIC_PE32PLUS`, the
   `IMAGE_FILE_HEADER`/`IMAGE_SECTION_HEADER`/`IMAGE_RESOURCE_DIRECTORY(_ENTRY)`/
   `IMAGE_RESOURCE_DATA_ENTRY` field offsets and struct sizes, the
   `CH_PE_RESOURCE_HIGH_BIT_FLAG`/`CH_PE_RESOURCE_OFFSET_MASK` name/subdirectory bit
   convention), the XOP Toolkit's own `CH_XOP_RESOURCE_ID` (1100), plus a few
   implementation-detail constants (`CH_PE_PAD_CHAR`, `CH_UINT16_BYTE_SIZE`,
   `CH_BYTE_SHIFT_8BIT`, `CH_CSTRING_SEARCH_INITIAL_CHUNK`/`_MAX_CHUNK`,
   `CH_CMPSTR_CASE_SENSITIVE`) -- per the user's explicit request. Initially added this
   `static Constant` block directly above the `CH_PE*` helpers that use it; the user
   subsequently moved the whole block to the top of the `#ifdef IGOR_PRO_BRIDGE` section
   (before `AfterCompiledHook`) to match this repo's own convention of declaring module-level
   constants at the top of a file, then ran `ipt format` (see the `tools/ipt` section above)
   over the whole file to reapply canonical formatting after the manual restructuring.

**Live-verified end-to-end, exact match against the already-validated Python reference, for
every XOP tested**: `JSON-64.xop` -> 13 operations (`JSONXOP_AddValue;JSONXOP_GetValue;...`),
0 functions; `ZeroMQ-64.xop` -> 0 operations, 21 functions (`zeromq_client_connect;...`);
`MultiClamp700xCommander64.xop` -> 1 operation (`MCC_FindServers`), 65 `MCC_*` functions;
`itcXOP2-64.xop` -> 32 `ITC*2` operations, 0 functions -- every single name, in the same
order, for all four.

**Two real gotchas hit and resolved while testing this, both worth remembering generally, not
just for this function**:
1. **The very first test call failed with `FunctionInfo("CH_ListXOPExports")` returning an
   empty string** (function not found at all), even right after a `reload_and_compile_procedures`
   that reported `"compiled": true`. Root cause: the experiment's "Procedure" window
   (`ProcedureText("", 0, "Procedure")`) had no `#define IGOR_PRO_BRIDGE` in it at all this
   session -- so the entire `#ifdef IGOR_PRO_BRIDGE ... #endif` block in
   `MIES_ClaudeHelper.ipf` compiled out silently, including the *pre-existing*
   `AfterCompiledHook`, not just the newly-added function (confirmed by
   `reload_and_compile_procedures`'s own `"confirmed_via"` field saying "AfterCompiledHook
   counter unavailable or unchanged" -- a real, self-diagnosing signal that was almost missed).
   The user added the `#define` and a subsequent `reload_and_compile_procedures` confirmed via
   the `AfterCompiledHook` counter again, and the function became visible.
   **Lesson: after adding new code to a `#ifdef`-gated file, don't just check `compiled: true`
   -- confirm the specific new function actually exists (`FunctionInfo`/`FunctionList`) before
   debugging anything else**, since a successful compile says nothing about which conditional
   branches were actually included.
2. **`String result = CH_ListXOPExports(...)` and even a bare
   `fprintf 0, "%s", CH_ListXOPExports(...)` both initially failed** with `"expected string
   variable or string function"` / `"got ... instead of a string variable or string function
   name"` -- but this turned out to be a symptom of gotcha 1 above (the function genuinely
   didn't exist yet at that point), not a separate interpreted-vs-compiled restriction. Once
   the `#define` was added and recompiled, the exact same `fprintf 0, "%s",
   CH_ListXOPExports(...)` form worked without any change -- confirming user-defined
   `Function/S` calls work perfectly normally from the command line via `_execute2`, same as
   any other function call documented elsewhere in this file.

Since `MIES_ClaudeHelper.ipf` is the never-committed, per-branch-emptied scratch file (see the
standing instruction near the top of this file), this implementation is session/branch-scoped
like everything else in it -- it will be gone after the next branch switch unless copied
somewhere permanent first, which was not requested this session.

## Hardware test environment: MultiClamp Commander must run elevated

Added `FFIGetCurrentClampStateWorks`/`FFIGetCurrentClampStateWorks_REENTRY` to
`Packages/tests/HardwareBasic/UTF_ForeignFunctionInterfaceWithHardware.ipf`, covering the new
`FFI_GetCurrentClampState` (part of the FFI clamp-control PR on
`feature/2559-mh_add_ffi_clamp_control`), following the exact same pattern as
`HardwareSelectionWorks`: a `DeviceNameGeneratorMD1`-driven multi-data test case that configures
one headstage via `InitDAQSettingsFromString`/`AcquireData_NG` (no actual DAQ/TP start needed --
`_TP0_DAQ0` in the settings string), then a `_REENTRY` function that checks the active
headstage's returned clamp-state wave (`%ClampMode`, a few IC-mode dimension labels via
`IsFinite`), that an inactive headstage returns a null wave, and that an invalid headstage index
aborts (`try`/`FAIL()`/`catch CHECK_NO_RTE()`).

First run failed immediately in `EnsureMCCIsOpen` (`REQUIRE_EQUAL_VAR(DimSize(ampMCC, ROWS), 2)`
-- found 0), before the new test's own body ever ran. Confirmed this was an environment issue,
not a bug in the new test, by running the pre-existing `StartingStoppingTestPulseWorks` (same
`AcquireData_NG` settings string, same default `s.amp = 1`) and seeing the identical failure.
Root cause (per the user): MultiClamp Commander -- the process MIES actually talks to for
amplifier control -- needs to be running **elevated** on this machine for MIES to see its
amplifier channels at all; it wasn't. Once started elevated, both tests passed. Worth checking
first (rather than assuming a test-code bug) whenever a hardware test fails specifically inside
`EnsureMCCIsOpen`/`REQUIRE_EQUAL_VAR(DimSize(ampMCC, ROWS), ...)`.

Extended `FFIGetCurrentClampStateWorks`/`_REENTRY` to cover all three clamp modes (VC, IC, I=0),
parameterized via a new `FFI_ClampModeCases()` data generator in `Packages/tests/UTF_DataGenerators.ipf`
(one `WAVE/T` per mode: `_CM` token for `InitDAQSettingsFromString`, expected `ClampMode` value,
representative dimension labels to check `IsFinite` on). All three subcases' actual assertions
(clamp state wave contents, inactive-headstage null check, invalid-headstage abort) passed.

## `CHECK_EMPTY_FOLDER()` false-positive on the first hardware test case run interactively

Running any hardware test case via `RunWithOpts(testcase=...)` from the interactive command
line/bridge -- as opposed to the normal CI harness -- makes the *first* test case of that run fail
its `TestCaseEndCommon` teardown with `Assertion "CHECK_EMPTY_FOLDER()" failed`, reporting stray
root-level variables `V_enable;V_debugOnError;V_NVAR_SVAR_WAVE_Checking;V_debugOnAbort` (sometimes
also `V_Flag`/`interactiveMode`) as the folder's "contents". This looks like a test bug but isn't.

**First theory (wrong, corrected below after a live A/B test)**: traced into `igortest`'s own
source (`Packages/igortest/procedures/igortest-debug.ipf`) and initially blamed `RunTest`/
`RunWithOpts`'s unconditional `SetDebugger(debugMode)` setup call (which chains into
`SetIgorDebugger()` -> `GetCurrentDebuggerState()`, whose body is a bare, argument-less
`DebuggerOptions` call) for leaving `V_enable`/`V_debugOnError`/`V_debugOnAbort`/
`V_NVAR_SVAR_WAVE_Checking` in `root:`. This didn't actually explain why the user's own manual
Igor-command-line usage never sees this residue, since that same igortest setup chain runs
identically either way.

**Corrected root cause**, found by a controlled A/B test (clean `root:`, running the identical
`RunWithOpts(testcase=...)` call two different ways): the residue comes from the **Igor Pro
Bridge's own `execute_igor_command_unattended` tool**, not from anything in igortest. That tool
documents itself as disabling the Debugger for the duration of the call and restoring it after --
which means it issues its own `DebuggerOptions enable=0` call *immediately before* running the
user's actual command. That bare-argument-style `DebuggerOptions` invocation is exactly what
leaves the four/six stray variables in whatever data folder is current (`root:`, for an
interactive/bridge call) -- confirmed live: identical `RunWithOpts(...)` calls, from a freshly
cleaned `root:`, **failed** via `execute_igor_command_unattended` and **passed** ("Finished with no
errors") via the plain `execute_igor_command` (with the Debugger separately confirmed off
beforehand via `get_debugger_state()`), reproduced for `FFIGetCurrentClampStateWorks`,
`HardwareSelectionWorks`, and other test cases across the session. Igor's own `DebuggerOptions`
operation, called without arguments (or to set a value), sets those output variables **in whatever
the current data folder is at that moment** -- so this is a genuine, confirmed side effect of the
bridge's implementation, not of igortest or of any test's own code.

Only the first test case in a run shows the `CHECK_EMPTY_FOLDER()` failure; subsequent
subcases/test cases in the same run pass clean (IUTF appears to only count/report the first
occurrence of an identical failure message per run -- `"Failed with 1 errors"` regardless of how
many subcases hit it).

**Workaround used for the remainder of the affected part of this session (no longer needed as of
bridge v1.23.0, see below)**: use plain `execute_igor_command` (never `_unattended`) for
`RunWithOpts(...)` test invocations, after confirming the Debugger is off via
`get_debugger_state()`, and run `KillVariables/Z root:V_Flag, root:V_enable, root:V_debugOnError,
root:V_debugOnAbort, root:V_NVAR_SVAR_WAVE_Checking, root:interactiveMode` before/after each run
for hygiene (harmless if some don't exist, since `/Z` suppresses the error). This avoided the
false positive entirely rather than just tolerating/ignoring it, while the bridge itself still
had the bug.

**Fixed properly in Igor Pro Bridge v1.23.0** -- see the "Igor Pro Bridge v1.23.0" section below
for the implementation, and the live confirmation that `RunWithOpts(testcase=
"HardwareSelectionWorks")` run through `execute_igor_command_unattended` now finishes with
`"Finished with no errors"`, no `CHECK_EMPTY_FOLDER()` failure. **The `execute_igor_command`
-only workaround above is no longer necessary** -- `execute_igor_command_unattended` is safe to
use directly for test runs again.

## Igor Pro Bridge v1.23.0: stray debugger-globals fix + `close_data_browser` removal

Two changes made on branch `feature/2754-add-basic-igor-pro-mcp-server` (`tools/igor-mcp-bridge/`
in this repo, a separate codebase from the MIES procedures themselves, packaged as its own
`.mcpb` Claude Desktop extension) after the corrected `CHECK_EMPTY_FOLDER()` root-cause analysis
above pinned the actual bug on this bridge's own code.

**Fix**: every tool that touches Igor's Debugger settings funnels through exactly two shared
helpers in `server.py` -- `_read_debugger_options()` (a read-only query, used by
`get_debugger_state`, `set_debugger_enabled`, `restore_debugger_settings`,
`execute_igor_command_unattended`, `load_experiment`, `get_environment_summary`) and
`_apply_debugger_options(state)` (the write/set command, used by
`execute_igor_command_unattended`, `load_experiment`, `set_debugger_enabled`,
`restore_debugger_settings`). Both build an Igor command string containing a bare/argument
`DebuggerOptions` invocation -- confirmed (see the `CHECK_EMPTY_FOLDER()` section above) that
this operation *always* creates `V_enable`/`V_debugOnError`/`V_debugOnAbort`/
`V_NVAR_SVAR_WAVE_Checking` as output variables in whatever data folder is current, purely as a
side effect of being called, regardless of arguments. Fix: both helpers now append
`; KillVariables/Z V_enable, V_debugOnError, V_debugOnAbort, V_NVAR_SVAR_WAVE_Checking` onto the
*same* command string (one Execute2 round-trip, not a separate call) -- for the read-only query,
this runs after the `fprintf` that captures the values into `results`, so nothing is lost by
cleaning up immediately. Fixing it at this shared-helper level (rather than only inside
`execute_igor_command_unattended`, as the original TODO was phrased) means every one of the six
tools listed above gets the fix, not just one.

**`close_data_browser` removed** (per explicit user request, no longer wanted): deleted the tool
function from `server.py` and its entry from `Packages/doc/igor-pro-bridge.rst`. It was a
precautionary tool (close Igor's built-in Data Browser before a reload/compile cycle, added
after Igor Pro was reported to sometimes crash with one open) that turned out to not be needed
in practice.

**Packaged as v1.23.0 using the official `mcpb` CLI** (`@anthropic-ai/mcpb`, available via
`npx mcpb`), replacing an earlier ad hoc/undocumented packaging process -- no build script or
`manifest.json` existed anywhere in this repo before this session; both were reconstructed by
unpacking the prior `igor-pro-bridge-1.22.0.mcpb` (a plain zip of `manifest.json` +
`pyproject.toml` + `src/server.py`) with `unzip`, editing in place, and repacking with
`npx mcpb pack . <output>.mcpb`. Kept `_BRIDGE_VERSION` (`server.py`), `manifest.json`'s
`"version"`, and `pyproject.toml`'s `version` all in sync at `1.23.0` (found and fixed a
pre-existing drift while at it: `pyproject.toml` had been stuck at `"1.19.0"` since at least
v1.22.0). Also found and fixed a pre-existing gap in `manifest.json`'s `"tools"` array: the
`get_bridge_version` tool has existed in `server.py` since v1.22.0 but was never actually listed
there -- added it. `npx mcpb validate manifest.json` and a `python -m py_compile` of the packaged
`src/server.py` both passed before delivering the bundle. **Gotcha**: the first `npx mcpb pack`
attempt swept a stray `src/__pycache__/*.pyc` (left over from an earlier local `py_compile` check
in the same build directory) into the archive -- deleted it and repacked; always check `npx mcpb
pack`'s own "Archive Contents" listing for anything unexpected like this before shipping.

**Live-verified after the user installed the new build and restarted Claude Desktop**:
`get_bridge_version()` confirmed `{"version": "1.23.0"}` actually loaded; `check_bridge_health()`
returned `"status": "OK"`. Confirmed the fix directly: ran a trivial
`execute_igor_command_unattended('print "hello from unattended"')` from a freshly-cleaned `root:`
and checked `VariableList("*", ";", 4)` immediately after -- empty, no stray globals, where the
old (pre-fix) bridge would have left the same four variables behind on every such call. Then ran
the actual regression case: `RunWithOpts(testcase="HardwareSelectionWorks")` via
`execute_igor_command_unattended` (the exact call shape that reliably failed with
`CHECK_EMPTY_FOLDER()` before the fix) -- result: `"Finished with no errors"` /
`"Test finished with no errors"`, no assertion failure. Confirms the fix is real and the
`execute_igor_command`-only workaround from the section above can be retired.

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

## Git note

`.git/packed-refs` was observed truncated (trailing NUL bytes, "unterminated line" error
blocking all git commands) partway through an earlier session. **Resolved/non-issue as of
this session**: `git status`/`git log` ran cleanly (checked while investigating whether
this session's local fixes had reached the PR branch), confirming it was a transient
artifact of the folder mount rather than lasting repo damage.

## FFI hardware test coverage: remaining write functions (branch `feature/2559-mh_add_ffi_clamp_control`)

Added tests for every remaining `FFI_Set*`/`FFI_TriggerAutoClampControl` write function in
`Packages/tests/HardwareBasic/UTF_ForeignFunctionInterfaceWithHardware.ipf`, each following the
established setup/`_REENTRY` two-function pattern (`InitDAQSettingsFromString`/`AcquireData_NG` in
setup, assertions in `_REENTRY`), all live-verified via the bridge ("Finished with no errors" for
each), in order added:

- **`FFIGetClampStateWorks`/`_REENTRY`**: covers `FFI_GetClampState` (the *unfiltered* clamp state,
  containing both VC and IC fields regardless of active mode -- unlike `FFI_GetCurrentClampState`,
  which is filtered to the active mode only), plus a `GetWaveDimensionality(clampState) == ROWS`
  check confirming the returned wave is 1D (`GetWaveDimensionality`, `MIES_Utilities_WaveHandling.ipf`
  line 142, returns the highest dimension index with `DimSize > 1`, or `ROWS` if none -- the
  established MIES idiom for a 1D-wave assertion).
- **`FFISetGetHeadstageActiveWorks`/`_REENTRY`**: `FFI_SetHeadstageActive`/`FFI_GetHeadstageActive`
  round-trip on HS1 (enable, verify, disable, verify), plus invalid-headstage abort for both.
- **`FFISetClampModeWorks`/`_REENTRY`**: cycles HS0 through VC -> I=0 -> back to IC via
  `FFI_SetClampMode`, verifying `FFI_GetCurrentClampState(...)[%ClampMode]` after each; invalid
  clamp mode (`-1`) and invalid headstage both abort. Refactored (user request) to introduce a
  `variable headstage = 0` local instead of repeating the literal `0` at every call site.
- **`FFISetHoldingPotentialWorks`/`_REENTRY`**: sets/verifies/disables a VC holding potential
  (`CHECK_CLOSE_VAR` for the float value, `tol = 1e-6`); NaN potential aborts; calling it while not
  in VC aborts (`"Attempt to set holding potential but current clamp mode is not VC !"`); invalid
  headstage aborts. Also given the `headstage` variable refactor.
- **`FFISetBiasCurrentWorks`/`_REENTRY`**: same shape as holding-potential, for IC/bias current
  (`"Attempt to set bias current but current clamp mode is not IC !"`).
- **`FFISetAutoBiasWorks`/`_REENTRY`**: same shape again, for `FFI_SetAutoBias`'s target
  potential/enable. Clamp-state field names for this one are **`AutoBiasVcom`**/`AutoBiasEnable`
  (not e.g. "AutoBiasPotential") -- confirmed from `AI_MapFunctionConstantToName`'s
  `MCC_NO_AUTOBIAS_V_FUNC`/`MCC_NO_AUTOBIAS_ENABLE_FUNC` cases in `MIES_AmplifierInteraction.ipf`.
  Note: unlike `FFI_SetHoldingPotential`/`FFI_SetBiasCurrent`, `FFI_SetAutoBias`'s source has **no
  `IsNaN` guard** on its `potential` argument -- so this test intentionally has no NaN-abort case
  (there is nothing to assert there); the positive-path enable/disable/verify assertions cover it
  instead.
- **`FFITriggerAutoClampControlWorks`/`_REENTRY`**: exercises all three `FFI_TriggerAutoClampControl`
  auto-control kinds -- auto pipette offset (works in either clamp mode), auto bridge balance
  (IC-only, `"MCC_AUTOBRIDGEBALANCE_FUNC works only in IC clampMode"` if not), auto capacitance
  (VC-only, `"MCC_AUTOWHOLECELLCOMP_FUNC works only in VC clampMode"` if not) -- plus an unknown
  auto-control value (`"Unknown auto clamp control"`, via `FATAL_ERROR`) and the usual invalid
  -headstage abort. `AUTO_PIPETTE`/`AUTO_CAPACITANCE`/`AUTO_BRIDGEBALANCE` are `static Constant`s
  private to `MIES_ForeignFunctionInterface.ipf` (values `1`/`2`/`3`), so the test uses the numeric
  literals directly with an explanatory comment rather than referencing the (inaccessible-from-here)
  named constants.

**Gotcha hit and fixed once (`FFISetHoldingPotentialWorks`)**: an early version tried to force HS1
into IC (to test the "wrong mode" abort path) via `FFI_SetClampMode(device, 1, I_CLAMP_MODE)`. This
doesn't abort -- it just prints `"(Dev1) Could not switch the clamp mode to I_CLAMP_MODE as no DA
and/or AD channels are associated with headstage 1."` and returns normally, since HS1 has no DA/AD
channels associated in this suite's standard single-headstage setup (only HS0 does) --
`DAP_SetClampMode` requires associated channels to actually perform the switch and just logs and
returns otherwise, it does not `ASSERT`/abort. This made the subsequent `try
FFI_SetHoldingPotential(device, 1, 0, 1); FAIL()` block spuriously fail, since HS1's mode never
actually changed. **Fix, and standing pattern for every later "wrong mode" test in this group**: use
HS0 itself for the mode-mismatch check (switch HS0 to the wrong mode via `FFI_SetClampMode`, which
does work on HS0, run the abort-expecting `try`/`catch`, then switch HS0 back) -- never rely on HS1
for anything that requires an actual clamp-mode change.

## Rebase verification (`feature/2559-mh_add_ffi_clamp_control` onto latest `main`)

After the user rebased this branch onto the latest `origin/main`, verified the rebase was resolved
correctly rather than just trusting a clean `git status`:

- No conflict markers (`<<<<<<<`/`>>>>>>>`) anywhere in the repo; no `.git/rebase-merge`/
  `rebase-apply` in progress -- the rebase had genuinely completed.
- `git merge-base HEAD origin/main` equals `origin/main`'s own tip exactly, confirming the 3
  feature commits (`DAP: Refactor...`, `AI: Add range check...`, `FFI: Add functions for clamp and
  headstage control`) sit directly on latest `main` with nothing missing or duplicated.
- `git diff --stat <old-base>..origin/main` showed upstream only touched
  `MIES_SweepFormula_Parser.ipf` and its tests/docs in the interim -- completely disjoint from
  every file this branch touches (`MIES_DAEphys.ipf`, `MIES_AmplifierInteraction.ipf`,
  `MIES_ForeignFunctionInterface.ipf`, the FFI hardware test file, `UTF_DataGenerators.ipf`). So
  there was essentially no real content to conflict on in the first place.
- `DAP_SetClampMode` (`MIES_DAEphys.ipf`) picked up an added `AI_AssertOnInvalidClampMode(mode)`
  call at its top -- redundant with (but harmless alongside) `FFI_SetClampMode`'s own
  `ASSERT(AI_IsValidClampMode(...))` check one level up; confirmed harmless since the FFI-level
  assert still fires first with its own more specific message ("Invalid clamp mode: -1"), verified
  by the still-passing `FFISetClampModeWorks` test.
- Working tree was clean for every FFI-related file (no diff vs. `HEAD`) -- all 16 FFI test
  functions this session added were confirmed present and byte-identical to what had been tested.
- **Transient, self-resolved compile error observed mid-verification, not a real problem**: one
  `read_session_history()` dump showed `UTF_ForeignFunctionInterfaceWithHardware.ipf:35:8: error:
  No such structure exists.` sandwiched between two full-suite runs that both completed with
  "Finished with no errors." `check_compilation_state()` immediately after reported clean, and two
  subsequent full-suite runs both passed cleanly -- the error did not recur and was very likely a
  transient artifact of file-on-disk churn during the rebase (e.g. Igor's file-watcher catching a
  momentarily-inconsistent file state), not a lasting defect. Lesson: don't treat one compile-error
  line found in a long, cumulative history dump as necessarily current -- corroborate with a fresh
  `check_compilation_state()` and/or another clean run before concluding something is actually
  broken.
- Two pieces of uncommitted, unrelated-to-the-rebase local state, initially just flagged for the
  user -- **now clarified by the user as permanent, intentional, and never to be committed**:
  - `Packages/tests/Basic/UTF_Basic_Includes.ipf`'s commented-out `example-stimulus-set-api`
    include: the file is only present in CI, not locally, so this line must stay commented out
    for local test runs to work at all -- but must equally never be committed that way, since CI
    needs it active. Leave this uncommitted local diff alone; don't "fix" it by committing either
    state.
  - `Packages/MIES_Include.ipf`'s `#include "MIES_ClaudeScrapCode"` line and
    `Packages/MIES/MIES_ClaudeScrapCode.ipf` itself: **never commit**, purely a scratch file used
    only during interactive Claude Desktop sessions (see the dedicated section below for the
    required per-branch-switch cleanup step this implies).
- Practical technique for reading a very large `read_session_history()` dump without exceeding the
  context window: save it to a file, convert the JSON-escaped `\r` sequences to real newlines
  (`sed 's/\\r/\n/g'`, **not** `tr '\r' '\n'` -- the saved file contains the literal two-character
  escape sequence, not an actual carriage-return byte, since it's JSON text written verbatim), then
  `grep -n` for just the markers of interest (`error:`, `Finished with no errors`, `RunWithOpts(`)
  instead of reading the whole thing.

## `tools/check-code.sh`'s "trailing semicolon" check has a comment-detection blind spot

The check (`git grep --perl-regexp '^[[:space:]]*[^\/].*;$' ...`) is meant to flag lines of actual
Igor code with a stray trailing `;` (Igor doesn't need semicolons to terminate statements, only to
separate multiple statements on one line), while skipping `//`-comment lines via the `[^\/]`
right after the leading whitespace. **This comment-exclusion doesn't reliably work for indented
comments**: `[^\/]` matches any single character that isn't a literal `/`, including whitespace
itself. Since `[[:space:]]*` is greedy but backtracks on failure, the regex engine can satisfy
`[^\/]` by consuming the leading tab/space instead of requiring `[[:space:]]*` to do it -- so an
indented `//` comment line still matches the overall pattern as long as it happens to end in a
literal `;`. Net effect: only comments with *zero* leading indentation are reliably excluded;
virtually every real comment in this codebase is indented and so is not actually protected by this
guard.

Hit this for real: three new comments in `UTF_ForeignFunctionInterfaceWithHardware.ipf` used a
semicolon as a prose separator ("... aborts; use HS0 itself for this ...", written as two
sentences split across lines with the first ending in `;`) and were flagged as "trailing
semicolon" hits even though there was no actual code semicolon anywhere nearby -- confirmed by
inspecting the flagged lines directly, all three were `//`-comments. Fixed by rewording (no longer
ending any comment in `;`); `tools/check-code.sh` reported no more trailing-semicolon failures
afterward.

**Standing rule (user's instruction) going forward**: never end a comment with a semicolon.
`tools/check-code.sh` runs as part of this repo's pre-push git hook, and a "trailing semicolon"
hit blocks `git push` outright -- so this isn't just a style nit, it's a hard gate. Prefer a
period, comma, or just restructuring the sentence instead of `;` at a comment's line-end.

## Igor Pro Bridge v1.25.0: pinned `install.ps1`/`requirements.txt`, and the MCP Python SDK's
## breaking v1 -> v2 transition

**Dated finding, confirmed via web search this session (2026-08-03) and by directly inspecting
both wheels' contents**: the MCP Python SDK's v2 line (`mcp` on PyPI) went stable at `2.0.0`,
released 2026-07-27/28 alongside MCP protocol revision `2026-07-28` -- a deliberate breaking
rework, not a routine minor bump. Most relevant to this bridge: `FastMCP` was renamed to
`MCPServer` and moved from `mcp.server.fastmcp` to `mcp.server.mcpserver`. `server.py` still
uses the v1 API (`from mcp.server.fastmcp import FastMCP`), confirmed still present by
unzipping the `mcp==1.29.0` wheel directly (`mcp/server/fastmcp/server.py` exists; the `2.0.0`
wheel does not have that path at all). **This means the bridge's previous unpinned dependency
spec (`mcp>=1.0.0` in `pyproject.toml`, and the manifest's own documented `pip install mcp
pywin32` instruction) was a live, undiscovered bug as of this finding**: running either command
today resolves to `2.0.0` and breaks the bridge outright with a `ModuleNotFoundError` on
import, with no warning beforehand. Fixed by pinning `mcp==1.29.0` (the last 1.x release,
confirmed via `pip index versions mcp`) in a new `requirements.txt`, and tightening
`pyproject.toml`'s spec to `mcp>=1.29.0,<2` so a future `pip install -e .`-style install can't
silently repeat the same mistake. `pywin32` pinned to `312` (confirmed latest via web search)
in the same file for the same "don't drift silently" reason, even though it wasn't at similar
risk of a breaking rename.

**The user's request that prompted this**: an installation script for the bridge that (a)
installs pinned versions from a `requirements.txt`, (b) installs specifically into the Python
environment Claude Desktop itself uses when run elevated -- explicitly *not* assumed to be the
same as whatever Python an elevated console resolves by default -- and (c) runs pywin32's
required post-install step. Delivered as `tools/igor-mcp-bridge/install.ps1`.

**Design rationale for (b), the "which Python does Claude Desktop actually use" problem**:
Claude Desktop's `manifest.json` invokes the bridge as the bare command `"python"`, resolved by
Claude Desktop's own (elevated) process via whatever `PATH` its environment has at launch time.
This is a different resolution mechanism than an interactive elevated PowerShell/cmd session,
which can have extra `PATH` entries injected only for that session (a PowerShell profile
script activating a conda environment, pyenv-win shims, etc.) that a plain elevated GUI-app
launch never picks up -- so trusting an elevated console's own `$env:Path` to decide where to
`pip install` can silently target the wrong interpreter entirely. There's also a known Windows
elevation-specific quirk with per-user Microsoft Store "app execution alias" stubs (a
placeholder `python.exe` that just opens the Store) behaving differently once elevated.
`install.ps1` avoids all of this by reading `[Environment]::GetEnvironmentVariable('Path',
'Machine')` and `...('Path', 'User')` directly (the same two registry-backed sources, in the
same order, Windows composes into a freshly created process's environment block) instead of
the invoking shell's own `$env:Path`, and explicitly rejects a Microsoft Store app-execution-
alias stub found that way (detected by path containing `\WindowsApps\` and a small file size).
An `-PythonPath` parameter bypasses this resolution entirely for a known-correct interpreter.

**Because auto-resolution is still a best-effort guess, not a guarantee**, also added ground-
truth verification: `get_bridge_version()` now additionally reports `python_executable`
(`sys.executable`), `python_version`, `mcp_package_version`, and `pywin32_build` (all via
`importlib.metadata.version(...)`, since the `mcp` package itself has no `__version__`
attribute -- confirmed by inspecting its `__init__.py`). The documented workflow: run
`install.ps1`, restart Claude Desktop (elevated), then call `get_bridge_version()` and confirm
`python_executable` matches what `install.ps1` installed into; if not, re-run `install.ps1
-PythonPath <that path>`. This closes the loop with an authoritative answer from inside the
actual process Claude Desktop launched, rather than relying on `install.ps1`'s guess alone.

Repackaged as `igor-pro-bridge-1.25.0.mcpb` (bumped from 1.24.0), now including
`requirements.txt` and `install.ps1` alongside `server.py` in the bundle. Also bumped
`requires-python`/the manifest's `compatibility.runtimes.python` from `>=3.9` to `>=3.10` to
match `mcp==1.29.0`'s own floor (confirmed via that wheel's `METADATA`: `Requires-Python:
>=3.10`). Verified: `python3 -m py_compile` on `server.py` inside the repacked bundle, and a
byte-for-byte diff against the repo's own copy, both clean. Could not test-run `install.ps1`
itself end-to-end (no Windows/PowerShell available in this session's sandbox; downloading a
portable `pwsh` build failed -- GitHub's release-asset CDN host was unreachable from here,
unlike `github.com` itself) -- reviewed by hand instead (brace/paren/bracket/here-string
balance checked programmatically, backtick-escape usage traced line by line). **Should be
smoke-tested on a real elevated Windows session before being treated as fully proven.**

## Igor Pro Bridge `requirements.txt`: added pip hash-pinning (no version bump, per user request)

Follow-up to the above: the user asked to additionally pin every package in `requirements.txt`
to its cryptographic hash, explicitly **without** bumping the bridge version or repackaging the
`.mcpb` -- so this only touched `tools/igor-mcp-bridge/requirements.txt` and `install.ps1`
(added `--require-hashes` to the latter's `pip install` call for a clear failure instead of a
silent unverified install if the hashes are ever accidentally stripped later). **The already-
packaged `igor-pro-bridge-1.25.0.mcpb` still contains the old, unhashed `requirements.txt`** --
that's a deliberate consequence of not repackaging, not an oversight; only the working-tree copy
(which is what `install.ps1` actually reads via `$PSScriptRoot`, whether run from the repo or
copied out of an already-installed extension folder) is updated. Bundling the hashed version
requires a future repackage.

**Why this is more involved than pinning just the two direct dependencies**: pip's hash-checking
mode (triggered automatically the instant any requirement has a `--hash`) requires **every**
package that would actually be installed -- not just the top-level ones -- to be pinned to an
exact version with a hash, including the entire transitive dependency tree. Since `mcp==1.29.0`
alone pulls in roughly two dozen packages (`anyio`, `httpx`/`httpcore`/`h11`, `pydantic`/
`pydantic-core`, `jsonschema` and its own tree, `pyjwt`+`cryptography`+`cffi`+`pycparser`,
`starlette`/`sse-starlette`/`uvicorn`, etc.), the whole tree had to be resolved and hashed, not
just `mcp`/`pywin32` themselves.

**Resolving a Windows dependency tree from this session's Linux sandbox**: used
`pip download --platform win_amd64 --python-version <N> --implementation cp --abi cp<N>
--only-binary=:all: -r requirements.in -d <dir>`, which lets pip's real resolver fetch metadata
and wheels for a *different* target platform/Python version than the host is actually running,
entirely through wheel-tag matching (no code execution/building needed, since every package in
this tree ships wheels for Windows). Ran this once per Python version (310/311/312/313, the
range this bridge's `pyproject.toml` currently declares, `>=3.10`) to catch any per-version
divergence, then `sha256sum` on every downloaded wheel file directly (not via PyPI's JSON API --
see the gotcha below) to get the hash values themselves.

**Real, non-obvious finding surfaced by doing this per-Python-version rather than just once**:
`rpds-py` (a transitive dependency of `jsonschema`/`referencing`) resolved to a **different
version**, not just a different wheel file, depending on target Python version -- `0.30.0` for
Python 3.10, `2026.6.3` for 3.11+ -- because the current `rpds-py` release has dropped Python
3.10 support entirely (no cp310 wheel published for it), so pip's resolver falls back to the
newest version that still has one. This is a real version-vs-version divergence, not just a
platform/ABI-tag difference (contrast with `cryptography`, which stays at one version, `50.0.0`,
but ships two different abi3 wheels -- `cp39-abi3` and `cp311-abi3` -- covering the same version
across the whole 3.10-3.13 range with two hashes on one pinned line). Handled by splitting
`rpds-py` into two separate pinned+hashed lines gated by `python_version < '3.11'` /
`>= '3.11'` markers in the requirements file -- valid, standard pip syntax, confirmed working
(see verification below).

**Gotcha hit and worth remembering generally**: plain `curl`/Python `urllib` requests to
`pypi.org`'s JSON API (`https://pypi.org/pypi/<name>/<version>/json`) failed outright from this
sandbox (TLS handshake reset partway through) even though `pip download` itself worked fine --
this environment's outbound network evidently only allow-lists pip's own configured index
traffic, not arbitrary HTTPS to `pypi.org`. Worked around it by computing `sha256sum` directly on
the wheel files `pip download` had already fetched, which is equally correct (identical bytes,
identical hash) and doesn't depend on being able to query PyPI's API directly.

**Second gotcha, more subtle and specifically relevant to how this was verified**: pip's
`--platform`/`--python-version`/`--implementation`/`--abi` flags (as used with `download`)
**only affect wheel-tag matching, not PEP 508 environment-marker evaluation** -- markers like
`python_version` and `sys_platform` are always evaluated against the *actual, real* running
interpreter, never the target flags. First noticed when a `pip download --require-hashes`
verification pass targeting `cp312` (from this sandbox's real Python 3.10) tried to install
`rpds-py==0.30.0` (the marker-selected, `python_version < '3.11'` line -- true for the *real*
host interpreter, 3.10) while simultaneously asking for a `cp312`-tagged wheel of it -- a
self-inflicted, impossible-in-real-life combination (a real Python 3.12 install would never
evaluate that marker true) that only arises from mixing this sandbox's real 3.10 interpreter
with cross-platform *download* target overrides. **This is a testing-methodology artifact only,
not a bug in the requirements.txt itself** -- on a real target machine, there is no
cross-compilation happening at all; pip runs natively on the real interpreter, so markers and
wheel-tag selection are automatically consistent. Verified correctly instead by: (1) a full,
un-confounded `pip download --require-hashes` round-trip for the complete dependency tree,
restricted to `--python-version 310 --abi cp310` (an exact match for this sandbox's real
interpreter -- zero host/target mismatch), which succeeded end-to-end with zero hash or
"missing pin" errors across all ~30 packages; (2) isolated single-package hash checks (each
package alone in a throwaway requirements file, no markers) for `pywin32` (cp310), `rpds-py`
(cp311, the *other* branch, confirming its hash independently of marker evaluation), and a
`pydantic-core` cp313 wheel. All passed. The cp311/cp312/cp313-specific wheel hashes for
`pydantic-core`/`cffi`/`cryptography`/`pywin32` that couldn't be round-tripped this way (no
3.11+ interpreter available in this sandbox, and installing one would have required root/apt
access this sandbox doesn't have) were still computed via direct `sha256sum` on the actual
downloaded wheel bytes, which is the authoritative hash regardless of pip's marker-evaluation
quirks -- just not independently re-verified through pip's own hash checker for those specific
combinations. **Should still be smoke-tested with a real `pip install --require-hashes -r
requirements.txt` on an actual elevated Windows machine with each supported Python version, the
same caveat as install.ps1 itself above.**

**That real-machine smoke test happened, and it failed exactly the way the caveat above
predicted it could.** The user ran `install.ps1` for real (elevated PowerShell): auto-resolution
correctly found their actual Python (`C:\Users\enigm\AppData\Local\Programs\Python\Python314\
python.exe`, i.e. **Python 3.14.0**), pip upgraded cleanly, then failed with
`THESE PACKAGES DO NOT MATCH THE HASHES FROM THE REQUIREMENTS FILE` on `pywin32==312` --
because this session's resolution pass had only covered cp310/311/312/313, never cp314, so
there was no hash for it at all yet Python 3.14 exists and was in real, current use. Exactly the
gap called out in the requirements.txt regeneration comment: `pyproject.toml` declares an
open-ended `>=3.10` floor, so a newly released Python version can reach real users before its
wheels are covered here -- this isn't a hypothetical, it happened on the very first real test.

Fixed by re-running the same `pip download --platform win_amd64 --python-version 314
--implementation cp --abi cp314 --only-binary=:all:` resolution pass and adding the resulting
hashes for the four version-specific compiled packages needing them (`pywin32`, `pydantic-core`,
`cffi`, `rpds-py`'s 2026.6.3 branch) to the existing lines -- confirmed all four packages still
resolve to the exact same *versions* already pinned (no new divergence beyond the pre-existing
rpds-py 3.10 split), `cryptography`'s existing `cp311-abi3` wheel already covers 3.14 (stable
ABI, no new file needed, confirmed no new cryptography download occurred for the cp314 target).
The `pywin32==312` cp314 hash added
(`a4dd3a848290ef724347b19f301045831d8e802fa4464f491b98b1e0a081432e`) was cross-checked against
the exact "Got" value in the user's own error message -- an exact match, confirming both that
the file pip fetched really is the genuine, untampered PyPI artifact and that the fix is
correct. Verified the regenerated file with the same methodology as before: a full
`pip download --require-hashes` round-trip for the complete tree at `--python-version 310`
(unchanged, zero errors), plus isolated single-package hash checks for the four new cp314
hashes at `--python-version 314` (three passed to completion; the `cffi`/`pydantic-core`
isolated checks correctly got past the hash check itself -- reaching "Using cached ...whl" before
failing only on their own *unpinned* transitive deps in the deliberately minimal, single-package
test file, which the real requirements.txt already pins).

**Lesson for future maintenance**: an unbounded `requires-python` floor (`>=3.10`, no upper
bound) means this hash-pinned file needs updating **every time a new CPython minor version is
released and gains adoption**, not just when a dependency version is deliberately bumped --
there's no automatic detection of this short of someone actually hitting the gap, as happened
here. Worth checking for a new Python release's wheel availability periodically rather than only
reactively.

## `install.ps1`: PowerShell mangles a multi-line, quote-containing argument passed to a native exe

After the cp314 hash fix above, the user's real elevated run got all the way through --
`pip install --require-hashes` succeeded (all packages installed/upgraded cleanly, including
correctly *skipping* the `rpds-py==0.30.0; python_version < '3.11'` line on their real Python
3.14, exactly as designed) and the `pywin32_postinstall.py -install` step also completed
successfully (DLLs copied to `system32`, COM registrations done) -- **only the final
verification step failed**, with a Python `SyntaxError` on a line that should have read
`print(f"python_executable: {sys.executable}")` but arrived as `print(fpython_executable:` --
every embedded `"` character had vanished, and the embedded newlines had become literal raw
newlines inside what pip/Python received as a single command-line argument.

**Root cause**: `install.ps1`'s verification step built a multi-line Python snippet (containing
several f-strings, i.e. embedded double quotes) as a single PowerShell string and passed it as
one argument to `python.exe -c` via `& $Exe @Arguments` (the script's own `Invoke-Checked`
helper). PowerShell's argument-to-native-command-line conversion is a known weak point exactly
for this combination -- a single argument containing both embedded double quotes *and*
newlines -- and mangled the quotes when re-serializing the argument array into the actual Win32
process command-line string. This is a genuine, confirmed-in-practice limitation, not a
one-off typo: the other `Invoke-Checked` call sites in this same script (`pip install ...`,
`pywin32_postinstall.py -install`) never hit this because none of their arguments contain both
quotes and newlines together -- only the verification step's inline multi-line snippet did.

**Fix**: stopped passing the Python snippet via `-c` entirely. Instead, `Set-Content` writes it
to a temp file (`Join-Path ([System.IO.Path]::GetTempPath()) "igor-bridge-verify-<guid>.py"`,
via `[guid]::NewGuid()` for a collision-free name) inside a `try`/`finally`, then
`python <thatfile>.py` is run as an ordinary script argument (just a path -- no quotes, no
newlines, no PowerShell native-argument-quoting risk at all), with the temp file always removed
afterward regardless of success/failure. This is the standard, robust pattern for handing a
non-trivial script to a subprocess from PowerShell -- avoid command-line argument quoting
entirely for anything beyond simple flags/paths, and use a temp file instead.

**Confirmed this really was the whole remaining problem**: everything upstream of the
verification step (Python resolution, elevation check, `pip install --require-hashes` against
the newly-fixed hashed `requirements.txt`, `pywin32_postinstall.py -install`) succeeded cleanly
on this real Python 3.14/Windows run with zero other issues -- a good sign that the rest of the
script's design (registry-PATH-based Python resolution, hash-pinned installs, elevation
handling) is sound in practice, not just in this session's own sandboxed review. Could not
re-run the fixed version against the same real machine this session (no live access) -- the fix
itself (write-to-temp-file instead of inline `-c` argument) is a well-established pattern for
this exact class of problem, but it should still be re-confirmed on a real elevated Windows
session before being treated as fully proven, same standing caveat as the rest of this script.
