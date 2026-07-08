---
name: igor-wave-dfref
paths:
  - "**/*.ipf"
description: Reference for Igor Pro's WAVE and DFREF reference syntax: wave vs WAVE reference distinctions, declaration forms, data folder navigation, and free waves. Use before generating any Igor Pro code involving waves passed as parameters, data folder references, or free waves, since this is where AI-generated Igor code most commonly contains subtle errors.
---

# Igor Pro — WAVE and DFREF Reference Syntax

This document covers the reference system for waves, global variables, strings,
and data folders. These are the areas where AI-generated Igor code most commonly
contains subtle errors. Read this before generating any code involving waves
passed as parameters, data folder navigation, or free waves.

Official reference: https://docs.wavemetrics.com/igorpro/programming/programming

---

## 1. The Core Distinction: Wave vs. WAVE

Igor has two completely different things that look similar:

- **A wave** — an array of data stored in a data folder (a global object)
- **A WAVE reference** — a local variable inside a function that *points to* a wave

You never operate on a wave directly by name inside a function. You always
declare a WAVE reference first, then use that reference.

```igor
// WRONG — this does not work inside a function:
Function BadExample()
    myWave[] = myWave[p] * 2       // Error: myWave is not declared
End

// CORRECT:
Function GoodExample()
    WAVE myWave = GlobalWaveGetterFunction() // get reference to wave from a wave getter function
    myWave[] = myWave[p] * 2       // now valid
End
```

---

## 2. WAVE Reference Declarations

### Basic forms

```igor
WAVE w                // reference to a wave of any type
WAVE/C w              // reference to a complex wave
WAVE/T w              // reference to a text wave
WAVE/D w              // reference to a double-precision wave (rarely needed explicitly)
WAVE/I w              // reference to a 32-bit integer wave
WAVE/L w              // reference to a 64-bit integer wave (int64)
WAVE/L/U w            // reference to an unsigned 64-bit integer wave (uint64)
WAVE/B w              // reference to a byte (8-bit) wave
WAVE/W w              // reference to a 16-bit integer wave
WAVE/Z w              // reference a wave that can also be a null wave
WAVE/WAVE w           // reference a wave containing wave references
WAVE/DF w             // reference a wave containing data folder references
```
The type flag /U can be combined with numeric integer type flags.
The /C flag can be combined with numeric type flags
The /Z flag can be combined with other flags

When a `WAVE` statement (without `/Z`) *actually executes* and its right-hand-side
expression fails to resolve to an existing wave, a runtime error is raised.
This is a different situation from a `WAVE` declaration that is simply never
reached at all due to control flow — see "Scoping and Default Initialization" below.

### Scoping and Default Initialization

Igor Pro has **no block scope**. A `WAVE`/`NVAR`/`SVAR`/`DFREF` declaration
written inside an `if`, `for`, or `switch` block is visible for the rest of
the function, exactly like a `Variable` or `String` declared in a block is.
The declaration is allocated for the whole function regardless of where it
textually appears; only the *assignment* is tied to that specific line
actually executing at runtime.

Reference-typed locals (`WAVE`, `NVAR`, `SVAR`, `DFREF`, `FUNCREF`) are
automatically initialized to a null/non-existent reference at function
entry — the same way a bare `Variable` defaults to 0 and a bare `String`
defaults to a null string (not `""` — a null string is a distinct state,
distinguishable from an empty string via `strlen()`, which returns `NaN`
for a null string but `0` for `""`). If the code path containing the assignment never runs,
the reference is simply left at that safe null default. No lookup is
attempted, so no runtime error occurs:

```igor
Function/WAVE MaybeGetData(variable condition)

    if(condition)
        Make/FREE data
        WAVE test1 = data
    endif

    // If condition was false, test1 is still a valid, null WAVE reference here —
    // not an error, not uninitialized memory. This is safe:
    Make/FREE/WAVE wref = {test1}

    return wref
End
```

Do **not** confuse this with a `WAVE` statement that *does* execute but whose
right-hand side fails to resolve (e.g. `$name` pointing at a wave that
doesn't exist). That is a different failure mode and, without `/Z`, does
raise a runtime error:

```igor
// This line executes every time; if "someName" isn't an existing wave,
// this errors (no /Z):
WAVE w = $someName

// Safe form when the target might not exist:
WAVE/Z w = $someName
if(!WaveExists(w))
    // handle missing wave
endif
```

The distinguishing question is not "does the reference look null" but
"did the assignment statement itself run." A conditionally-assigned WAVE
reference that's never reached is a normal, safe null. A WAVE statement
that runs and can't find its target is a runtime error unless guarded
with `/Z`.

Practical implication: it's a legitimate pattern in this
codebase to conditionally assign a WAVE reference inside a branch and use
it unconditionally afterward (typically feeding into a wave-ref array or
an `if(WaveExists(...))` check), without a separate `WAVE/Z x = $""`
pre-declaration. That pre-declaration is harmless but redundant for this
specific case — it's only necessary when you need the null-default to be
explicit/self-documenting, or when reusing the same variable name across
multiple, non-exclusive branches where the "did it run" tracking gets
less obvious.

### Referencing waves in other data folders

```igor
WAVE w = root:myData:myWave              // full absolute path

DFREF dfr = root:myData
WAVE w = dfr:myWave                      // using a DFREF variable (see section 5)

string wavePath = "root:myData:myWave"
WAVE w = $wavePath                       // path constructed at runtime in a string
```
References to global permanent waves should be retrieved through wave-getter functions.

### Checking if a reference is valid

Always use `/Z` and then check `WaveExists()` when the wave may not exist:

```igor
WAVE/Z w = FunctionReturningPossibleNullWave()
if(!WaveExists(w))
    Print "Wave not found"
    return NaN
endif
```

**Never** assume a WAVE declaration succeeded without checking — if the wave
doesn't exist and you didn't use /Z, the function aborts with an error.

### Getting a wave reference from a name string

```igor
string name = "myWave"
WAVE w = $name                    // wave in current data folder
WAVE w = root:myData:$name        // wave in specific folder — WRONG syntax
string fullPath = "root:myData:" + name
WAVE w = $fullPath                // build full path in string
```

The `$` operator dereferences a string into a name. It cannot be used
mid-path — build the full path string first, then apply `$` once.

---

## 3. Passing Waves to and from Functions

### Passing waves as parameters

Waves are always passed by reference (the reference is copied, not the data):

```igor
// Declare parameter as WAVE in both the parameter list and declaration
Function ProcessWave(WAVE w)
    w[] = w[p] * 2
End

// Typed wave parameters:
Function ProcessTextWave(WAVE/T tw)
    Print tw[0]
End

Function ProcessComplexWave(WAVE/C cw)
    // ...
End
```

### Returning a wave reference from a function

Use `Function/WAVE` return type:

```igor
Function/WAVE MakeResultWave(variable n)
    Make/FREE/N=(n) resultWave

    return resultWave
End

// Calling it:
WAVE result = MakeResultWave(100)
```

Or use Multiple Return Syntax (Igor 8+):

```igor
Function [WAVE w1, WAVE w2] MakeResultWaves(variable n)
    Make/FREE/N=(n) resultWave1, resultWave2

    return [resultWave1, resultWave2]
End

// Calling it:
[WAVE result1, WAVE result2] = MakeResultWaves(100)
```

### Returning a wave reference to a wave in a specific data folder

```igor
Function/WAVE GetMyWave(DFREF dfr, string name)
    WAVE/Z w = dfr:$name

    return w
End

// Check for null on the receiving side:
WAVE/Z result = GetMyWave(myDFR, "data")
if(!WaveExists(result))
    Abort "Wave not found"
endif
```

---

## 4. NVAR and SVAR — Global Variable References

Global numeric variables and global strings are **not** directly accessible
inside functions by name. You must declare a reference first.

```igor
// WRONG — globals are not automatically visible in functions:
Function BadGlobal()
    myGlobalVar = 42          // Error: not declared
End

// CORRECT:
Function GoodGlobal()
    NVAR myGlobalVar          // reference to global numeric variable in current DF
    myGlobalVar = 42
End

Function GoodGlobalString()
    SVAR myGlobalStr          // reference to global string in current DF
    myGlobalStr = "hello"
End
```

### Referencing globals in other data folders

```igor
NVAR v = root:Packages:MyPkg:settingValue
SVAR s = root:Packages:MyPkg:settingName
```

### Checking existence before use

```igor
NVAR/Z v = root:Packages:MyPkg:counter
if (!NVAR_Exists(v))
    variable/G root:Packages:MyPkg:counter
    NVAR v = root:Packages:MyPkg:counter
endif
```

Similarly for strings: `SVAR/Z s = ...` then `SVAR_Exists(s)`.

---

## 5. DFREF — Data Folder References

`DFREF` is a reference to a data folder, analogous to WAVE for waves.
It is the preferred way to write folder-aware code in Igor 7+.

### Declaring and obtaining a DFREF

```igor
DFREF dfr = root:myData                   // absolute path
DFREF dfr = :subFolder                    // relative to current DF
DFREF dfr = GetDataFolderDFR()            // current data folder
DFREF dfr = NewFreeDataFolder()           // anonymous free data folder (not in tree)
DFREF dfr = $("root:myData:" + name)      // dynamic path
```

### Checking if a DFREF is valid

```igor
DFREF dfr = root:mayNotExist
if (DataFolderRefStatus(dfr) == 0)
    Print "Data folder does not exist"
    return
endif
```

`DataFolderRefStatus` returns:
- `0` — invalid (folder doesn't exist)
- `1` — refers to a regular data folder
- `3` — refers to a free data folder

### Using DFREF to access waves and variables

```igor
DFREF dfr = root:myData
WAVE w = dfr:intensity           // wave in that folder
NVAR n = dfr:temperature         // global variable in that folder
SVAR s = dfr:sampleName         // global string in that folder
```

### Passing DFREF as a function parameter

```igor
Function AnalyzeFolder(DFREF dfr)
    WAVE/Z w = dfr:data
    if (!WaveExists(w))
        Abort "No data wave found"
    endif
    WaveStats/Q w
    Print "Mean =", V_avg
End
```

### Saving and restoring the current data folder

**Always** save and restore the current data folder if your function changes it:

```igor
Function DoSomethingInFolder(String path)
    DFREF saveDF = GetDataFolderDFR()        // save current DF
    SetDataFolder path
    // ... do work ...
    SetDataFolder saveDF                     // restore
End
```

Failure to restore the current data folder is one of the most common bugs
in Igor procedures. Use this pattern every time you call `SetDataFolder`.

### Returning a DFREF (Igor 10+)

```igor
Function [DFREF df] GetOrCreateFolder(String name)
    DFREF root = GetDataFolderDFR()
    NewDataFolder/O root:$name
    DFREF df = root:$name

    return [df]
End

// Calling:
[DFREF myDF] = GetOrCreateFolder("results")
```

---

## 6. Free Waves

Free waves exist only in memory, are not in any data folder, and are
automatically destroyed when no references point to them. They are ideal
for temporary intermediate results in functions.

### Creating free waves

```igor
// Make with /FREE flag:
Make/FREE/N=100 tempWave
Make/FREE/N=(n, m) tempMatrix

// Duplicate with /FREE:
Duplicate/FREE sourceWave, tempCopy

// NewFreeWave function:
WAVE tempWave = NewFreeWave(2, 100)   // type 2 = single precision float, 100 points
```

Wave type codes for `NewFreeWave`: 0=double, 1=complex, 2=single, 4=int8,
8=int16, 16=int32, 32=unsigned int, 64=int64, 128=unsigned int64, 512=text.
Add these together for combinations (e.g. 4+32=36 for unsigned int8).

### Key rules for free waves

- Free waves cannot be the target of GUI related functions that permanently cause the data to be displayed, like `Display`, `Edit`, `AppendToGraph`, etc.
  Create a permanent wave in a wave getter function for anything that needs to be plotted persistently.
- Free waves **can** be passed to operations like `WaveStats`, `FFT`,
  `CurveFit` (with /NOINT or structure-based approaches), `MatrixOP`, etc.
- A free wave is destroyed as soon as the last WAVE reference to it goes
  out of scope (end of function, or explicitly set to a different reference).

---

## 7. Free Data Folders

Free data folders are in-memory containers not attached to the data folder
tree. Useful for bundling temporary waves inside a function.

```igor
DFREF freeDFR = NewFreeDataFolder()
Make/O freeDFR:tempWave/N=100
WAVE w = freeDFR:tempWave
w = gnoise(1)
// freeDFR and all its contents are destroyed when freeDFR goes out of scope
```

---

## 8. The $ Operator — Name-to-Reference Resolution

`$` converts a string expression into an Igor object reference. It is used
whenever the name of a wave, variable, or data folder is constructed at runtime.

```igor
string name = "myWave"
WAVE w = $name                    // resolve name to wave in current DF

string path = "root:myData:myWave"
WAVE w = $path                    // resolve full path

Make/O $(name + "_result")        // create wave with constructed name
WAVE result = $(name + "_result")
```

### $ in wave arithmetic (assignment to dynamically named wave)

```igor
string outName = "processedData"
Make/O/N=100 $outName
WAVE out = $outName
out[] = p^2
```

### $ cannot be used mid-path — build the full path string first

```igor
// WRONG:
WAVE w = root:myData:$waveName       // syntax error

// CORRECT:
DFREF dfr = root:myData
WAVE w = dfr:$waveName               // $ at the end of a dfr: prefix IS valid
```

---

## 9. WaveExists, DataFolderExists, NVAR_Exists, SVAR_Exists

Use these to check validity before using references. Never assume an object
exists without checking, especially in general-purpose functions.

```igor
// Waves:
if(WaveExists(w))          // w is a WAVE reference (use after WAVE/Z)

// Data folders:
if(DataFolderExists("root:myData"))       // string path

DFREF/Z dfr = root:myData
if(DataFolderRefStatus(dfr) != 0)         // using a DFREF

// Global variables:
NVAR/Z v = myGlobalVar
if(NVAR_Exists(v))

// Global strings:
SVAR/Z s = myGlobalStr
if(SVAR_Exists(s))
```

---

## 10. Common Patterns

### Global Permanent Waves

Global permanent waves are created in wave getter functions that must be located in MIES_WaveDataFolderGetters.ipf.

A wave getter function has the form:
```
Function/WAVE MyWaveGetter()

	string name = "waveName"

    DFREF           dfr = GetDataFolderPath()
	WAVE/Z/SDFR=dfr wv  = $name

	if(WaveExists(wv))
		return wv
	endif

	Make/D/N=(10) dfr:$name/WAVE=wv

	return wv
End
```

A wave getter function always returns a valid WAVE reference.

Call it with:
```
WAVE wv = MyWaveGetter()
```

### Global Permanent Waves with Versioning

Global permanent waves with versioning are created in wave getter functions that must be located in MIES_WaveDataFolderGetters.ipf.
Versioning is required if the wave data is read by MIES after an experiment with MIES data was loaded because the loaded MIES data could be created with an older version of MIES.

A wave getter function with versioning has the form:
```
Function/WAVE GetMyWave(string device)

	string name = "myWave"
    DFREF dfr = GetMyPath(device)
	variable versionOfNewWave = 2

	WAVE/Z/SDFR=dfr wv = $name

	if(ExistsWithCorrectLayoutVersion(wv, versionOfNewWave))
		return wv
	elseif(WaveExists(wv)) // handle upgrade
		if(WaveVersionIsAtLeast(wv, 1)) // upgrade version 1 to 2
			Redimension/D wv
		else
            // upgrade version 0 to 2
			// change the required dimensions and leave all others untouched with -1
			// the extended dimensions are initialized with zero
			Redimension/D/N=(10, -1, -1, -1) wv
		endif
	else
		Make/R/N=(10, 2) dfr:$name/WAVE=wv
	endif

	SetWaveVersion(wv, versionOfNewWave)

	return wv
End
```

The wave getter function upgrades the wave on demand. The wave getter function always returns a valid wave reference with a wave of the latest version.

Call it with:
```
WAVE wv = GetMyWave(device)
```

### Global Datafolders

Global datafolders are created in data folder getter functions that must be located in MIES_WaveDataFolderGetters.ipf

A data folder getter function has the form:

```
threadsafe Function/S GetDatafolderPathAsString()

	return GetParentDatafolderPathAsString() + ":myDataFolder"
End

threadsafe Function/DF GetMyDataFolderPath()

	return createDFWithAllParents(GetDatafolderPathAsString())
End
```

The functions are always pairs, where one function returns the data folder as string and the other as data folder reference.
The function that returns the data folder path as string refers internally to the getter function for the parent data folder.
The topmost data folder of MIES can be retrieved with `GetMiesPath()` or as string with `GetMiesPathAsString()`.
Data folder getter functions always return a valid data folder reference.

Call it with:
```
DFREF dfr = GetMyDataFolderPath()
```

### Global Strings

Global strings are created in getter functions that must be located in MIES_GlobalStringAndVariableAccess.ipf

A global string getter function has the form:
```
threadsafe Function/S GetMyGlobalString()

	return GetNVARAsString(GetMyDataFolderPath(), "stringName", initialValue = "new string")
End
```

The getter function always returns a valid path to the global string. The initialValue is optional and depends on how the string is used in MIES.

Call it with:
```
SVAR myGlobalString = $GetMyGlobalString()
```

### Global Variables

Global variables are created in getter functions that must be located in MIES_GlobalStringAndVariableAccess.ipf

A global variable getter function has the form:
```
threadsafe Function/S GetMyGlobalVariable()

	return GetNVARAsString(GetMyDataFolderPath(), "variableName", initialValue = 1337)
End
```

The getter function always returns a valid path to the global variable. The initialValue is optional and depends on how the variable is used in MIES.

Call it with:
```
NVAR myGlobalVariable = $GetMyGlobalVariable()
```

### Prefer Existing Utility Functions over Reimplementation

The procedure files `MIES_Utilities_*.ipf` and `MIES_MiesUtilities_*.ipf` contain utility functions for common tasks. Always prefer an already existing utility function
over reimplementing the same functionality. If for a task there is no utility function but an extension of a utility function would solve the task prefer the extension of an already existing function.

WRONG:
```
if(DataFolderRefStatus(dfr) != 0)
```

CORRECT:
```
if(DataFolderExistsDFR(dfr))
```

---

### ListToTextWave

The Igor Pro integrated function `ListToTextWave` never returns a null wave. If the `listStr` argument is an empty string then a text wave with zero rows is returned.

WRONG:
```
WAVE/Z/T wv = ListToTextWave(listStr, separatorStr)
if(WaveExists(wv))
  // code working with wv
endif
```

CORRECT:
```
WAVE/T wv = ListToTextWave(listStr, separatorStr)
// code working with wv
```

---

## 11. Quick Reference Table

| Goal | Syntax |
|---|---|
| Retrieve wave from wave getter function | `WAVE w = MyWaveGetter()` |
| Retrieve wave from function that can return a null wave | `WAVE/Z w = MyFunction()` |
| Reference wave via DFREF (only used in wave getter function) | `WAVE w = dfr:myWave` |
| Check wave exists | `WaveExists(w)` after `WAVE/Z` |
| Reference text wave | `WAVE/T tw = myTextWave` |
| Reference complex wave | `WAVE/C cw = myComplexWave` |
| Reference global variable from getter function | `NVAR v = $MyNVARGetter()` |
| Reference global string from getter function | `SVAR s = $MySVARGetter()` |
| Get current DF as DFREF | `DFREF dfr = GetDataFolderDFR()` |
| Reference data folder | `DFREF dfr = root:myData` |
| Check DFREF is valid | `if(DataFolderExistsDFR(dfr))` |
| Save/restore current DF | `DFREF saveDF = GetDataFolderDFR()` ... `SetDataFolder saveDF` |
| Create free wave | `Make/FREE/N=(n) w` |
| Create free data folder | `DFREF dfr = NewFreeDataFolder()` |
| Get DF containing a wave | `DFREF dfr = GetWavesDataFolderDFR(w)` |
| Get name of a wave | `string name = NameOfWave(w)` |
| Return wave from function | `Function/WAVE Foo()` ... `return w` |
| Return DFREF from function (Igor 10) | `Function [DFREF df] Foo()` ... |

---

## Reference URLs

| Topic | URL |
|---|---|
| Programming Overview (functions, parameters) | https://docs.wavemetrics.com/igorpro/programming/programming |
| Programming Techniques (DF patterns) | https://docs.wavemetrics.com/igorpro/programming/programming-techniques |
| WAVE keyword | https://docs.wavemetrics.com/igorpro/commands/wave |
| Conditionally-assigned WAVE ref used after the block | Safe — defaults to null if the branch didn't run, not an error |
| NewFreeWave | https://docs.wavemetrics.com/igorpro/commands/newfreewave |
| NewFreeDataFolder | https://docs.wavemetrics.com/igorpro/commands/newfreedatafolder |
| GetDataFolderDFR | https://docs.wavemetrics.com/igorpro/commands/getdatafolderdfr |
| GetWavesDataFolderDFR | https://docs.wavemetrics.com/igorpro/commands/getwavesdatafolderdfr |
| DataFolderRefStatus | https://docs.wavemetrics.com/igorpro/commands/datafolderrefstatus |
| WaveExists | https://docs.wavemetrics.com/igorpro/commands/waveexists |
| CountObjectsDFR | https://docs.wavemetrics.com/igorpro/commands/countobjectsdfr |
| GetIndexedObjNameDFR | https://docs.wavemetrics.com/igorpro/commands/getindexedobjnamedfr |
| NVAR_Exists | https://docs.wavemetrics.com/igorpro/commands/nvar_exists |
| SVAR_Exists | https://docs.wavemetrics.com/igorpro/commands/svar_exists |
