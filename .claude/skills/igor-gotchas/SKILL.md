---
name: igor-gotchas
paths:
  - "**/*.ipf"
description: Confirmed Igor Pro runtime/compiler behavior that is not obvious from the command reference alone -- compilation and conditional-compilation mechanics, Execute/deferred-execution restrictions, try/catch/Abort/Debugger interaction, command-line-only restrictions, and specific command quirks (FindValue, WinList, NewPath, CaptureHistory, background tasks, compile hooks, XOP/help-file introspection). Use before writing or debugging any Igor Pro code that touches compilation, error handling, background tasks, or a command whose exact behavior matters and isn't already covered by igor-wave-dfref or igor-10.
---

# Igor Pro — Confirmed Runtime and Compiler Gotchas

This document covers Igor Pro language/runtime behavior that is easy to get
wrong because it isn't obvious from a command's one-line documentation, or
because the documentation itself is ambiguous. Every entry here was confirmed
against real behavior or Igor's own reference documentation, not assumed from
general programming-language intuition.

See also: `igor-wave-dfref` (WAVE/DFREF reference semantics), `igor-10`
(Igor Pro 10 version differences), `igor-commands` (alphabetical command
link index).

---

## Compilation and Conditional Compilation

### `#define` symbols for cross-file `#ifdef`/`#ifndef` belong in the main Procedure window

A `#define` intended to control `#ifdef`/`#ifndef` checks in OTHER procedure
files must be set in the experiment's main Procedure window, not inside an
ordinary `.ipf` file. Per Igor's own documentation, the main procedure window
is always compiled first — a `#define` there is reliably visible to every
other file's `#ifdef` checks; one placed in a regular `.ipf` file has no such
guarantee (compilation order across included files is not something to rely
on for this).

### `SetIgorOption poundDefine`/`poundUndefine` — the session-scoped, non-compilable alternative

`SetIgorOption poundDefine=symb` / `poundUndefine=symb` add/remove a
conditional-compilation symbol from a global symbol list available to every
procedure window — broader in scope than a single `#define` line, and usable
without editing any file on disk. Query current state with
`SetIgorOption poundDefine=symb?` → `V_flag` (1 if defined, 0 if not).

```igor
SetIgorOption poundDefine=IGOR_PRO_BRIDGE?
print V_flag   // 0 = undefined

Execute/P "SetIgorOption poundDefine=IGOR_PRO_BRIDGE"
Execute/P "COMPILEPROCEDURES "
```

Important properties:
- **Session-only** — not saved with the experiment, lost on relaunch. Must be
  re-set every time a fresh Igor Pro instance/experiment needs it.
- **Not compilable** — "`SetIgorOption` is not compilable. To use it in a
  user-defined function, you need to use `Execute`." Only `Execute`/`Execute/P`
  can invoke it, never a bare call from inside a `Function`.
- **Triggers a recompile** the same way `RELOAD CHANGED PROCS`/
  `COMPILEPROCEDURES` do — an `#ifdef`/`#ifndef` block gated on the symbol
  only takes effect after the next compile.

### `RELOAD CHANGED PROCS` / `COMPILEPROCEDURES` — separate calls, mandatory trailing space

These must be issued as two separate `Execute`/`Execute/P` calls, never
joined by `;` into one string, and each needs a mandatory trailing space
(`"RELOAD CHANGED PROCS "`, `"COMPILEPROCEDURES "`). Anything queued via
`Execute/P` immediately after a `COMPILEPROCEDURES` in the same batch may
simply never run — poll the compiled state directly afterward rather than
relying on a follow-up deferred callback to confirm success.

### Compile hooks: know which one actually fires when

- `AfterCompiledHook` fires only after a **successful** compile — never on a
  failed one. Any cleanup/restart logic that must run regardless of outcome
  needs an independent mechanism (e.g. a watchdog background task), not just
  this hook.
- `BeforeUncompiledHook(changeCode, procedureWindowTitleStr, textChangeStr)`
  fires before procedures uncompile.
- `IgorStartOrNewHook` fires both on Igor launch and on new-experiment
  creation — it does not distinguish between the two on its own.

### `FunctionInfo` resolves unqualified names relative to the CALLING function's own module, not global scope

`FunctionInfo(functionNameStr)` with an unqualified name resolves relative to
the module the *calling* code is compiled in — not `ProcGlobal`, not global
scope. To check a different module's compile state from code running in an
Independent Module (or any non-`ProcGlobal` module), qualify explicitly:

```igor
FunctionInfo("ProcGlobal#SomeName")
```

### A single compile error anywhere poisons `FunctionInfo` for everything

When any compile error exists anywhere in the experiment, `FunctionInfo(...)`
reports `"Procedures Not Compiled"` for **every** function queried, including
unrelated, genuinely-fine ones. Do not conclude a specific module/function has
its own problem just because `FunctionInfo` fails on it — check for a compile
error anywhere in the experiment first (e.g. via the compiled-state check
this repo's tooling already uses).

---

## `Execute`, Deferred Execution, and Error Handling

### `Execute` (unqueued) cannot be called from inside a `Function` at all

Only `Execute/P` (deferred — runs after the calling function returns control
to Igor's main loop) is legal inside a compiled function. This is a genuine
language restriction, not a tooling limitation. Several operations —
`COMPILEPROCEDURES`, `RELOAD CHANGED PROCS`, `SetIgorOption poundDefine` —
are themselves restricted to only running via `Execute`/`Execute/P` in the
first place, so this combination (`Execute/P "SetIgorOption ..."`) is often
the only legal way to invoke them from procedure code.

### A `;`-joined command string aborts entirely on its first runtime error

If `stmt1` errors, `stmt2` in the same `;`-joined string never runs.
Independently *queued* `Execute/P` calls are unaffected by each other's
failure this way — only text joined into one string shares fate. Prefer
separate `Execute/P` calls when a later step should still run even if an
earlier one might fail.

### `try`/`catch`/`endtry`: a bare runtime error does not jump to `catch` by itself

Only an explicit `AbortOnRTE` (or `AbortOnValue`) placed right after the
risky call converts a pending runtime error into a catchable abort. Per
Igor's own documentation, "When an abort occurs, execution immediately jumps
to the first statement after `catch`" — but a bare error alone, without that
explicit conversion, does not trigger this.

```igor
try
    RiskyCall()
    AbortOnRTE          // without this line, a runtime error in RiskyCall()
                        // does NOT transfer control to catch
catch
    // handle it
endtry
```

**Put the risky call and its `AbortOnRTE`/`GetRTError(1)` check on the SAME
line** (`dummy = RiskyCall(); AbortOnRTE`), not on separate lines — Igor's
Debug-on-Error checking happens at the END OF EACH LINE, not after each
`;`-separated statement, so a pending error left unacknowledged across a line
boundary can pop a real Debugger window before the guard has a chance to run.

### `Abort "<message>"` pops a real alert dialog immediately — `try`/`catch` does not suppress it

Unlike an ordinary runtime error, `Abort` with a message string shows its
alert dialog right away, before any enclosing `try`'s `catch` block runs
(wrapping it in `try`/`catch` only lets you react after the dialog has
already appeared). If a failure is purely logical/internal and must not
block on a popup, set an error status directly instead of calling `Abort`
with a message.

### A bare `return` is invalid inside an ordinary scalar-returning `Function`

A value-less `return` (no expression) is only valid inside a Multiple-Return-
Syntax function. In an ordinary `Function`/`Function/S`/`Function/WAVE`
declaration, the returned value's type must always match the declared return
type — `return` alone does not compile there.

### Checking `GetRTError(1)` after an XOP call that can error

Check it on the SAME line as the call (`SomeXOPCall(...); err = GetRTError(1)`),
not split across two lines — otherwise an unacknowledged pending error can
surface as an unexpected Debugger popup on a later, unrelated line (same
underlying mechanism as the `try`/`AbortOnRTE` line-boundary issue above).

---

## Command-Line-Only Restrictions

The following are only restrictions when typed directly at Igor's command
line (interpreted, not compiled) — the identical statement works fine inside
a compiled `Function`:

- `WAVE/Z w = SomeFunc(...)` — assigning a wave reference from a function
  call fails at the command line ("expected wave name, variable name, or
  operation").
- `Make/FREE ...` — free waves have no valid scope outside a function.
- Multiple-return-value destructuring (`[val1, val2] = SomeFunc()`).
- Calling a `static` function by its bare name — it's scoped to its file's
  `#pragma ModuleName` and needs `ModuleName#FunctionName` from outside that
  module (this restriction is not command-line-specific, but is easy to
  mistake for one when it first surfaces there).
- Multi-line control-flow blocks (`if`/`else`/`endif`, `for`/`endfor`) — a
  command line containing such a block fails as a whole with a generic error,
  even though each line would be valid inside a real function.

**Workaround for anything needing compiled-only features interactively**:
write/extend a small compiled scratch procedure file, `#include` it, compile,
then call a single compiled helper function from that file via the command
line — everything inside the function body runs as compiled code, so none of
the above restrictions apply.

A related but distinct fact: variables/strings declared directly on the
command line persist as global command-line variables across separate
command executions within the same Igor session — they are not scoped to
one call. Re-declaring the same name later fails ("the name already exists
as a variable"); assign directly instead of re-declaring.

---

## Specific Command/Function Behavior

### `FindValue /TXOP` bit flags

`4` = case-insensitive whole-cell text match (the pervasive default in this
codebase); `5` = `4 | 1` = case-sensitive. Use `TXOP=(1+4)` when case
matters (e.g. matching an SI unit prefix like `m` vs. `M`).

### `NewPath`/`PathInfo`'s `S_path` always returns Igor's native colon notation, even on Windows

Confirmed live: normalizing a Windows path via `NewPath` + `PathInfo`
produces `"C:Projects:mies_data:..."`, not backslashes — the same normalized
form MIES stores internally in places like the Analysis Browser's folder-list
wave. Anything comparing/displaying such a value should expect colon
notation regardless of host OS.

### `WinList`'s `WIN:` bit values

`1`=graphs, `2`=tables, `4`=layouts, `16`=notebooks, `64`=panels,
`128`=procedure windows, `512`=help windows. (`1024` is not a defined type.)

### `ProcedureText(funcName, flags, winTitle)` — window title is the THIRD argument

Passing a window name as the first argument silently returns `""` with no
error. To read an entire window's contents (not a specific function), pass
`funcName=""` and the window name as the third argument.

### `CaptureHistory(refnum, stopCapturing)` and stale refnums

Both arguments are required — a one-argument call fails to compile. A saved
numeric refnum from `CaptureHistoryStart()` is only meaningful within the OS
process that created it. If persisted in a global and the experiment is
reloaded (a real process quit+relaunch, not just a recompile), the global
still exists (`NVAR_Exists` succeeds) but the refnum itself is stale — using
it throws a runtime error. Never trust mere existence of a stored refnum-like
handle across a save/reload boundary; validate by trying to use it (wrapped
in `try`/`AbortOnRTE`/`catch`) and recreate if stale.

### `stopmstimer(-2)` returns microseconds, not milliseconds

Despite the name, Igor's free-running timer via `stopmstimer(-2)` returns a
value in **microseconds**.

### `CtrlNamedBackground`'s `start=N` is only a floor, not a guarantee of ordering

`start=N` (ticks, ~1/60s each) only sets the earliest possible first
invocation — independent of `period`. Background tasks and the deferred
`Execute/P` queue have **no guaranteed ordering relative to each other**; a
task registered "after" some queued work can still tick first. Treat
`start=` only as an empirical safety margin, never as a strict ordering
guarantee.

### `ThreadGroupRelease(-2)` releases every currently-running thread group

Useful inside a `BeforeUncompiledHook` to release a stray background thread
before procedures uncompile — a running thread group can otherwise block
`COMPILEPROCEDURES`/`RELOAD CHANGED PROCS` with a modal "still active"
dialog.

### `DebuggerOptions` creates output globals wherever the current data folder happens to be

A bare/partial-argument call to `DebuggerOptions` creates its output
variables (`V_enable`, `V_debugOnError`, `V_debugOnAbort`,
`V_NVAR_SVAR_WAVE_Checking`) in whatever data folder is current **at call
time**, regardless of which arguments were actually given. Code that calls it
purely for its toggling side effect should `KillVariables/Z` these four names
in the target folder afterward, or expect stray globals to trip a
`CHECK_EMPTY_FOLDER()`-style assertion downstream (relevant in tests).

### Auto-indexing order in waveform assignments

An auto-indexed waveform assignment (e.g. `Make/WAVE/N=(n) w = SomeFunc(p)`)
runs strictly in increasing index order when `Multithread` is **not** used.
With `Multithread`, per-index execution order is not guaranteed and the
right-hand side must be threadsafe. This matters whenever the called
function has order-dependent side effects.

### `MultiThread` works with any wave type -- the restriction is on the expression, not the wave

The `MultiThread` keyword (in front of a wave assignment statement inside a
function, e.g. `MultiThread w = expr`) has no restriction based on the
destination or source wave's data type. Confirmed against Igor's own
"MultiThread" keyword reference and the "Automatic Parallel Processing with
MultiThread" article (Advanced Topics.ihf): the entire discussion is about
whether the *expression* (and any function it calls) is thread-safe, never
about which wave type is involved. Igor's own docs explicitly cover
`MultiThread` with numeric waves, and separately confirm it for wave
reference waves (`WAVE/WAVE`, "You can use a wave reference wave as a list
of waves for further processing and in multithreaded wave assignment using
the MultiThread keyword") and data folder reference waves (`WAVE/DF`, same
wording) -- Advanced Topics.ihf has dedicated worked examples for both
("Wave Reference MultiThread Example", "Data Folder Reference MultiThread
Example"), plus one for structure arrays ("Structure Array MultiThread
Example"). This repo's own code confirms `MultiThread` with **text** waves
too, e.g. `SFE_ConvertNonFiniteElements`
(`MIES_SweepFormula_Executor.ipf`) reads a `WAVE/T` source
(`subArray[p][q][r][s]`) via `MultiThread`, and
`SFE_FormulaExecutor` writes into a `WAVE/T` destination
(`Multithread outT[index][][][] = outT[index][0][0][0]`).

The real constraints are about the *expression*, not the wave type:
- It must be thread-safe -- any function it calls (built-in or
  user-defined) must be thread-safe; user-defined functions need the
  `ThreadSafe` keyword.
- Do not reference any point of the destination wave other than the
  current point (`p`/`q`/`r`/`s`) being computed -- e.g.
  `wave1 = wave1[p+1] - wave1[p-1]` gives indeterminate results.
- A thread-safe function called from the expression must not resize/
  retype/kill any wave passed to it, write to a text wave passed to it, or
  write to a variable passed by reference; any waves/globals it creates
  itself disappear when the assignment finishes; and it cannot use `WAVE`/
  `NVAR`/`SVAR` to reach into the main thread's data folder tree (each
  thread has its own private data folder tree).
- Only worth the overhead for a destination with a large number of points,
  or an expensive expression -- for small waves `MultiThread` can be
  slower than the unthreaded assignment.

### Igor Pro on Windows is single-instance-per-user for command-line launches

Launching `Igor64.exe <path>` while an instance is already running does
**not** spawn a new process — it signals the existing instance to load the
file, popping an unhandled "save changes?" dialog if that instance has
unsaved changes. If the existing instance is mid-quit when the launch command
runs, the load request can be silently dropped instead. Any programmatic
relaunch logic must confirm the prior process has actually exited from the
OS process list before invoking the executable again — checking that some
IPC channel has merely gone quiet is not sufficient, since that can happen
well before the process itself actually terminates.

---

## Introspecting XOPs and Help Files

### Locating XOPs, help files, and checking whether something is loaded

Igor Pro loads XOPs/help files/fonts/procedure files from two merged
locations: under the Igor Pro program folder, and
`<Documents>/WaveMetrics/Igor Pro <version> User Files/` — both mirror the
same subfolder names (`Igor Extensions`, `Igor Extensions (64-bit)`,
`Igor Fonts`, `Igor Help Files`, `Igor Procedures`, `User Procedures`). Check
both when looking for an XOP's help file; not every XOP ships one.

To check whether an XOP's functions/operations are actually loaded:
`FunctionList("*", ";", "KIND:4")` lists XOP functions,
`OperationList("*", ";", "external")` lists XOP operations — check both, and
be aware that once an XOP is loaded it can't be toggled/unloaded mid-session,
and neither list attributes a name back to its owning XOP (only naming
convention, or the PE-resource technique below, can do that).

### `.ihf` help files are themselves Igor notebooks

Read them with `OpenNotebook/R` (fails with error 251 if that file's
help-window view is already open elsewhere — a help-file view and a plain
notebook view of the same file are mutually exclusive). Export via
`SaveNotebook/O/S=5/H={...}` (HTML) to recover genuine structure: each
paragraph gets a `<P class="...">` matching WaveMetrics' own semantic style
convention — `Topic`, `Subtopic`/`Subtopic-Indented`,
`TopicBody1`/`TopicBody1a`, `Steps`/`ListNumbered`,
`Code1`/`Code1a`/`Code-Indented1`, `SeeAlso`/`NOTE`/`Table2Col`/`Table3Col`/
`RelatedTopics`. Useful for reliably parsing structure out of any Igor help
file rather than treating it as flat text.

### Recovering a closed-source XOP's operations/functions with no vendor docs

A closed-source `.xop`'s Igor-visible operations/functions are recoverable
from standard Windows PE resources named `"XOPC"` (operations) and `"XOPF"`
(functions), resource ID 1100 — any generic PE resource reader (e.g. Python's
`pefile`) can extract them without vendor documentation:

- `XOPC` records: `{null-terminated name; int16 LE category bitmask}*`,
  terminated by an empty-name record.
- `XOPF` adds a return-type code and per-parameter type codes to each entry.

Useful for any closed-source XOP in this repo (`MultiClamp700xCommander64.xop`,
`itcXOP2-64.xop`, `MIESUtils-64.xop`, `TUF-64.xop`, `SutterXOP_Win-64.xop`)
with no available documentation.

---

## Reference URLs

| Topic | URL |
|---|---|
| SetIgorOption | https://docs.wavemetrics.com/igorpro/commands/setigoroption |
| Execute | https://docs.wavemetrics.com/igorpro/commands/execute |
| Abort | https://docs.wavemetrics.com/igorpro/commands/abort |
| GetRTError | https://docs.wavemetrics.com/igorpro/commands/getrterror |
| FunctionInfo | https://docs.wavemetrics.com/igorpro/commands/functioninfo |
| FindValue | https://docs.wavemetrics.com/igorpro/commands/findvalue |
| WinList | https://docs.wavemetrics.com/igorpro/commands/winlist |
| NewPath | https://docs.wavemetrics.com/igorpro/commands/newpath |
| CaptureHistory | https://docs.wavemetrics.com/igorpro/commands/capturehistory |
| CtrlNamedBackground | https://docs.wavemetrics.com/igorpro/commands/ctrlnamedbackground |
| ThreadGroupRelease | https://docs.wavemetrics.com/igorpro/commands/threadgrouprelease |
| DebuggerOptions | https://docs.wavemetrics.com/igorpro/commands/debuggeroptions |
