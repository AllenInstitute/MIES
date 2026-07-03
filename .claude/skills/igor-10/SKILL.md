---
name: igor-10
paths:
  - "**/*.ipf"
description: Igor Pro 10 changes relevant to code generation: 64-bit only, Python integration, compiler behavior changes, new language features, function and operation changes, and bug fixes that alter results. Use when writing or reviewing Igor Pro code that must run on Igor Pro 10, or when Igor 9 vs 10 behavior differences matter.
---

# Igor Pro 10 — Key Changes for Code Generation

This document summarizes Igor Pro 10 changes that affect how code should be written.
It is intended as reference material for AI-assisted code generation, not as a complete
changelog. For full details, fetch the official documentation:

- What's New: https://docs.wavemetrics.com/igorpro/igor-pro-10/what-s-new-in-igor-pro-10
- Changes since 10.00: https://docs.wavemetrics.com/igorpro/igor-pro-10/what-s-changed-since-igor-pro-10-00

---

## 1. Igor Pro 10 is 64-bit Only

Igor Pro 10 ships as a 64-bit application only (unlike versions 7–9 which had both).
**All XOPs must also be 64-bit.** Do not suggest or reference 32-bit XOP patterns.
The camera operations `NewCamera`, `ModifyCamera`, and `GetCamera` have been removed.

---

## 2. Python Integration (New in Igor 10)

Igor 10 introduced direct, bidirectional Python communication via the `igorpro`
module, replacing workarounds like ExecuteScriptText for Python tasks. See the
`igor-python` skill for the full reference (syntax, setup, object model, object
lifetime rules). Version-specific facts not covered there:

- The `igorpro.fn` submodule (calling Igor functions directly from Python) was
  added in 10.01, not 10.00.
- Igor 10.00 supports Python 3.x generally; 10.01 specifically adds Python 3.14
  support (standard installation only, not free-threaded).

---

## 3. Compiler Behavior Changes (Breaking)

### Unreachable code in switch/strswitch is now a compile error

Code before `case` labels or after `break` before the next `case` is now rejected:

```igor
// THIS WILL NOT COMPILE in Igor 10:
switch(val)
    Print "this is unreachable"   // ERROR: unreachable code
    case 1:
        // ...
        break
    Print "also unreachable"      // ERROR: unreachable code
    case 2:
        // ...
endswitch

// CORRECT:
switch(val)
    case 1:
        Print "reachable"
        break
    case 2:
        // ...
endswitch
```

### ExperimentModified no longer triggered by same-value assignments

In Igor 10, assigning a global variable or string to its current value no longer
marks the experiment as modified. If your code relies on this side effect to trigger
a save prompt, explicitly call:

```igor
ExperimentModified 1
```

### #pragma independentModule=ProcGlobal is now a compile error

This was silently accepted before Igor 10. It is now rejected at compile time.

### Abort/AbortOnRTE no longer triggers "Debug on User Abort"

The debugger is now invoked only when the **user** clicks the Abort button.
Programmatic `Abort`, `AbortOnRTE`, and `AbortOnValue` calls no longer invoke
the debugger even when "Debug on User Abort" is enabled.

---

## 4. New Language Features

### #pragma moduleName now allowed in the main Procedure window

Previously, `#pragma moduleName` was only valid in included procedure files.
In Igor 10 it can be used in the main Procedure window:

```igor
#pragma moduleName = MyMainModule

Static Function helperFunction()
    // now callable as MyMainModule#helperFunction()
End
```

### DFREF supported in Multiple Return Syntax (MRS)

Data folder references can now be returned via MRS:

```igor
Function [DFREF df] GetSubfolder(String name)
    DFREF currentDF = GetDataFolderDFR()
    NewDataFolder/O currentDF:$name
    DFREF df = currentDF:$name
End

// Calling it:
[DFREF myDF] = GetSubfolder("results")
```

### Static constants accessible across modules

Constants in other modules can now be referenced with double or triple names,
just like static functions:

```igor
switch(val)
    case OtherModule#MY_CONSTANT:
        // ...
        break
    case OtherIM#SubModule#THEIR_CONSTANT:
        // ...
        break
endswitch
```

### Line continuation expanded

Line continuation with `\` now works nearly everywhere, including after
end-of-line comments, and compound name components can span lines:

```igor
Function [WAVE w]       // output wave \
    Example(String name,    // wave name \
            Variable n)     // number of points
    Make/O/N=(n) $name \
                = gnoise(1)
    WAVE w = $name
End
```

---

## 5. Function and Operation Changes

### WaveStats — new /W flag options for performance

In Igor 10, `WaveStats` accepts optional parameters with `/W` that allow
bypassing creation of `V_*` output variables. Use this in tight loops where
you don't need all statistics:

```igor
// Full stats (creates all V_ variables) — original behavior:
WaveStats/Q myWave

// Igor 10: bypass V_ variable creation for performance
WaveStats/Q/W=0 myWave   // fetch only; see docs for parameter options
```

See https://docs.wavemetrics.com/igorpro/commands/wavestats for full syntax.

### MatrixOP — new functions (Igor 10.00 + 10.01)

The following functions were added to `MatrixOP` in Igor 10:

`subtractMin()`, `indexMatch()`, `removeCol()`, `removeCols()`,
`scaleLayers()`, `scaleChunks()`, `subtractRows()`, `subtractCols()`,
`quatFromSpherical()`, `quatInverse()`, `median()`, `zapZeros()`,
`replaceInfs()`, `enoise()`, `setType()`, `rowDiff()`, `binMean()`,
`binVar()`, `limit()`, `not()`

The `/KCLS` flag was extended to support the third dimension (10.01).

Do not suggest manual workarounds for these operations — use the built-in
MatrixOP functions instead.

### New functions: Interp4D and Interp4DPath

Four-dimensional interpolation is now available:

```igor
result = Interp4D(w, x0, x1, x2, x3)
```

### /K=4 flag on window creation operations

`Display`, `Edit`, `NewPanel`, `NewGizmo`, `NewLayout`, `NewNotebook`,
`NewWaterfall`, `NewImage`, and `OpenNotebook` now support `/K=4`, which
kills the window without a dialog and does not save it with the experiment.
Useful for temporary tool or progress windows in pipeline code:

```igor
NewPanel/K=4 as "Processing..."
```

### New drawing layers: ProgTop and UserTop

Two new drawing layers were added that render **above** annotations:
`ProgTop` (for programmatic drawing) and `UserTop` (for user drawing).
Use `SetDrawLayer ProgTop` when you need overlays that sit on top of
annotation text boxes.

### Say operation (text-to-speech)

```igor
Say "Analysis complete"
```

### printf engineering notation: %W2P and %W3P

New format specifiers interpret precision as total significant digits
(not fractional digits as %W0P/%W1P do):

```igor
printf "%.4W3PHz", 12.342E3   // prints "12.34 KHz"
printf "%.2W2PV", -12.342E-3  // prints "-12mV"
```

---

## 6. Bug Fixes That Affect Results (Important)

### area() and faverage() — incorrect results fixed (10.01)

Both functions had a bug where the trapezoidal end-point correction was
discarded, producing slightly incorrect results. **Results from these
functions changed in Igor 10.01.** If you have existing code or saved
results that used `area()` or `faverage()`, the values will differ
slightly after upgrading.

### CurveFit now accepts wave subranges with X waves (10.01)

Previously, using a wave subrange in `CurveFit` when an X wave was also
specified was incorrectly rejected. This now works:

```igor
CurveFit/Q gauss myWave[10,50] /X=xWave /W=weightWave
```

### FindPeak crash fixed for waves > 1 million points (10.01)

`FindPeak` previously crashed on large waves. This is fixed in 10.01
with up to 40x performance improvement on large waves.

### AnnotationInfo returns "" instead of error for missing annotations

In Igor 10, `AnnotationInfo` returns an empty string if the window has
no annotations or the named annotation doesn't exist. Previously this
was a runtime error. Code that used `try/catch` around `AnnotationInfo`
for this case can be simplified.

### Bitwise operators now use signed integer conversion (10.01)

`|`, `&`, `~`, and `%^` previously converted operands to unsigned integers.
They now convert to signed integers. This can change results for negative
operands.

---

## 7. Compatibility Notes

### File compatibility
Experiment files saved by Igor 10 using Igor 10-specific features cannot
be opened by earlier versions. If cross-version compatibility matters,
avoid Igor 10-only syntax.

### _labels_ keyword no longer translated (10.01)
In localized versions of Igor (e.g. Japanese), the `_labels_` keyword in
`Display`, `AppendToGraph`, and `ReplaceWave` is no longer translated.
Igor always generates `_labels_` regardless of OS language. This is only
relevant when sharing `.pxp` files across language environments.

---

## Reference URLs

| Topic | URL |
|---|---|
| What's New in Igor 10 | https://docs.wavemetrics.com/igorpro/igor-pro-10/what-s-new-in-igor-pro-10 |
| Changes since 10.00 | https://docs.wavemetrics.com/igorpro/igor-pro-10/what-s-changed-since-igor-pro-10-00 |
| MatrixOP | https://docs.wavemetrics.com/igorpro/commands/matrixop |
| WaveStats | https://docs.wavemetrics.com/igorpro/commands/wavestats |
| Multiple Return Syntax | https://docs.wavemetrics.com/igorpro/programming/programming#multiple-return-syntax |
