---
name: sweepformula
paths:
  - "**/MIES_SweepFormula*.ipf"
  - "**/UTF_SweepFormula*.ipf"
description: Architectural facts about MIES's SweepFormula subsystem (dataset wrapping, array-literal evaluation, plotter targeting, nested-execution source-location tracking) that are not obvious from reading a single operation in isolation. Use before adding or modifying a SweepFormula operation, touching the executor/array-evaluation code, or debugging an error-location/assert-data-stack problem.
---

# SweepFormula — Architectural Reference

SweepFormula (`MIES_SweepFormula*.ipf`) is MIES's scripting language for data
evaluation. This document covers structural conventions that span multiple
files and are easy to violate by only looking at one operation's code. Also
read `Packages/doc/SweepFormula.rst` (the docu skill points you there for any
SweepFormula documentation question) and `.claude/skills/igor-wave-dfref` for
general WAVE/DFREF semantics.

---

## Dataset Wrapping Convention

A SweepFormula operation result is a "dataset": a `WAVE/WAVE` container
(typically built via `SFH_CreateSFRefWave(win, opShort, size)`). `size` is
**not** always 1 — most operations size it to match their input (e.g.
`SFH_CreateSFRefWave(exd.graph, opShort, DimSize(input, ROWS))`, one output
row per input row), and only some operations route through the
single-element convenience wrapper `SFH_GetOutputForExecutorSingle` (which
hardcodes `size=1`).

The `SF_META_DATATYPE` JSON wave note (set/read via `JWN_SetStringInWaveNote`/
`JWN_GetStringFromWaveNote`) is **optional per-operation metadata**, not a
universal property of every dataset — it identifies specific semantic kinds
(e.g. `SF_DATATYPE_SELECTCOMP`, `SF_DATATYPE_SELECTTAG`) and is set only when
an operation explicitly asks for it:

- `SFH_GetOutputForExecutorSingle(data, ..., dataType=X)` only sets the note
  when the optional `dataType` argument is actually supplied — most calls in
  `MIES_SweepFormula_Operations_Select.ipf` do; plenty of other call sites
  across the codebase omit `dataType` entirely and get no note at all. When
  it does set the note, it wraps `data` in a **new** wrapper wave and tags
  that wrapper — it never tags `data` itself.
- `select()` is a deliberate counter-example: it builds its own composite
  wrapper directly, sets the note on it, and returns via
  `SFH_GetOutputForExecutor` — skipping `SFH_GetOutputForExecutorSingle`
  entirely. Don't assume every operation goes through the single-wrap helper.
- `seltag` needs **two** levels of wrapping so the array-literal executor
  doesn't misinterpret a multi-tag `seltag([a,b])` result as a plain text
  wave and array-expand its elements. The datatype note must be set on the
  **inner** wrapper (which becomes `genericElement[0]` inside an array
  literal), not just the outer one.

## Array Literals Mixing Scalars and Datasets

For an array literal (`[a, b, c]`) that may mix scalar/text elements with
dataset (`WAVE/WAVE`) elements, the executor:

1. Prescans every element **exactly once** via `SF_ResolveDatasetFromJSON`
   (never resolve the same element twice — resolution can execute operations
   with side effects) to determine if any element is dataset-kind.
2. If any element is a dataset, the **whole array** is promoted to a uniform
   wave-of-datasets accumulator (`outW`), with plain scalar/text elements
   individually wrapped via `Make/FREE/WAVE promoted = {subArray}`
   (`MIES_SweepFormula_Executor.ipf`) into their own single-element
   wave-of-waves wrapper — an ad hoc free wave, not a named/tagged dataset
   kind (no `SF_META_DATATYPE` note is set on it).
3. A dataset's own internal dimensionality must never leak into the outer
   array's shape — guard any dimension-widening logic with
   `if(!WaveExists(outW))` so the dataset accumulator stays strictly 1D
   regardless of what's inside each element.

`SFH_GetArgumentSelect` correspondingly checks `IsWaveRefWave(array)` rather
than `IsTextWave(array)`, since array elements in this path are direct wave
references, not stringified markers.

## Plotter Targeting Is Entirely Outside the JSON Executor

`and`/`with` are plotter-targeting keywords, not executor syntax:

- A SweepFormula expression cannot contain line breaks, and `and`/`with` must
  each stand alone on their own line — so they can never appear inside an
  expression actually parsed by `SFE_ExecuteFormula`/
  `SFE_ExecuteVariableAssignments`. They are recognized in an earlier,
  separate notebook-text-splitting step, before the executor ever sees the
  expression text.
- They only control **where the plotter places each expression's result**:
  `with` = same sub-window as the previous expression, `and` = a new
  sub-window. There is no way to feed `and`/`with` through the executor, even
  via a nested/dynamically-generated formula string.
- SweepFormula renders into a separate, dedicated plotter panel — **never**
  the host DataBrowser/SweepBrowser's own graph. The window name is
  deterministic: `SF_GetDataDisplayWindowName(graph, SF_DISPLAYTYPE_GRAPH,
  SF_DM_SUBWINDOWS, 0)` (static, module `MIES_SF` — needs `MIES_SF#`
  qualification from outside) returns the fully-qualified subwindow name,
  e.g. `"SweepFormula_plotsweepBrowser_graph#graph0"` for host graph
  `"SweepBrowser"`. Each SweepBrowser/DataBrowser gets its own independently
  named plot window keyed off its own `graph` argument (MIES supports
  multiple simultaneous SweepBrowsers). `SF_DM_NORMAL` gives a wrong/
  non-existent name for this case, and the `SF_DM_SUBWINDOWS` result already
  includes the `#graph0` suffix — don't append it again.

## Composing New Operations Out of Existing Ones

An operation can implement itself by re-entering the real formula executor
with dynamically-built source text, reusing other real operations as
building blocks, via this pattern. This is a documented extension pattern
(`Packages/doc/SweepFormula.rst`, "full plotting specification" section) --
currently exercised by `UTF_SweepFormula.ipf`'s tests, not by a named
production operation, so treat it as the supported way to build a new
operation this way rather than a description of an existing one:

1. `Duplicate/FREE` the per-graph `GetSFVarStorage(graph)` (a `WAVE/WAVE`
   keyed by variable name) as a backup.
2. Build an ordinary SweepFormula source string on the fly and run it via
   `SFE_ExecuteVariableAssignments(graph, formula, allowEmptyCode=1)`, which
   mutates the **live** `varStorage` in place.
3. Read back whatever result is needed by name.
4. `Duplicate/O backup, varStorage` to wipe all scratch variables, then
   re-add only the specific desired outputs via `SFH_AddVariableToStorage` —
   this keeps the operation's own temporary variable names from leaking into
   the user's persistent SweepFormula environment.

Exception safety is a non-issue here: if the nested call aborts, the restore
step (4) is simply skipped, but that's fine — a failed evaluation just means
"no result" (SweepFormula never updates an already-displayed plot in place
on failure), and the next run's `SFE_ExecuteVariableAssignments` unconditionally
wipes `varStorage` back to 0 rows regardless of what a prior aborted run left
behind.

## Nested-Execution Source-Location Tracking Is a LIFO Stack

Source-location tracking for (possibly nested) formula execution uses a
stack, not a single flat frame:

- `GetSFAssertDataStack()` (`MIES_WaveDataFolderGetters.ipf`, `WAVE/WAVE`,
  lazily created) holds the stack. `GetSFAssertData()` returns the top frame,
  auto-pushing a base frame if the stack is empty.
- `SFH_PushAssertDataFrame()`/`SFH_PopAssertDataFrame()`
  (`MIES_SweepFormula_Helpers.ipf`) manage nested execution frames —
  centralized via a `newFrame` flag parameter on
  `SFE_ExecuteVariableAssignments`/`SFE_ExecuteFormula`, rather than each
  caller manually bracketing its own call.
- On abort, the pop is deliberately **skipped** so the frame's data survives
  for the aggregate error message. `SFH_PopAssertDataFrame` asserts against
  popping the base frame, and deliberately does **not** release JSON ids
  itself — a normal return already released them via the ordinary success
  path, so releasing again would double-release.
- The live global position trackers (`GetSweepFormulaJSONPathTracker()`/
  `GetSweepFormulaBufferOffsetTracker()`) only ever reflect whatever is
  executing *right now* — so each frame's rendered location message is
  frozen into a `LOCMSG` field at the moment a deeper frame is pushed on top
  of it, while the live trackers still reflect that outer frame's own
  position at that time.
- `SFH_GetAssertLocationMessage` walks the stack top-to-bottom, joining more
  than one non-empty frame's message with `"\rCalled from:"`.
- Only the **outermost** frame (`SFH_GetOutermostAssertDataFrame()`, i.e.
  `stack[0]`) has `LINE`/`OFFSET` that are real, on-screen notebook
  positions — `SF_CalculateErrorLocationInNotebook` must read that specific
  frame, not whatever is currently on top of the stack.
- `SFH_ResetAssertDataStack()` (called from `SF_ClearSFOutputState()`)
  releases every remaining frame's `JSONID`/`SRCLOCID` via
  `JSON_Release(..., ignoreErr=1)` then empties the stack — necessary
  because stale frames from an aborted run would otherwise corrupt the
  *next* run's error-location tracking. **Any test that deliberately aborts
  a nested formula must call `SFH_ResetAssertDataStack()` itself afterward**
  for the same reason.

---

## Reference

- `Packages/doc/SweepFormula.rst` — user-facing behavior and array/operation
  evaluation semantics (e.g. empty-array and mixed numeric/text handling).
- `Packages/MIES/MIES_SweepFormula_Executor.ipf` — `SFE_FormulaExecutor`
  (array/object/string dispatch), `SFE_ConvertNonFiniteElements`.
- `Packages/MIES/MIES_SweepFormula_Helpers.ipf` — dataset resolution
  (`SF_ResolveDatasetFromJSON`, `SFH_ResolveDatasetElementFromJSON`),
  assert-data-stack management.
- `Packages/MIES/MIES_SweepFormula_Operations.ipf` — individual operation
  implementations; the primitive `+ - * /` operators live here
  (`SFO_IndexOverDataSetsForPrimitiveOperation`).
