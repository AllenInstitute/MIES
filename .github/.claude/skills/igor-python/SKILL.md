# Igor Pro — Python Integration (`igorpro` module)

This skill covers writing Python code that communicates with Igor Pro 10
using the `igorpro` module. This module is proprietary to Igor Pro and has
no presence in general Python training data — always use this reference
when generating Python code intended to run from within Igor.

**Critical constraint:** The `igorpro` module can ONLY be used from within
Igor Pro itself. Scripts must be launched from Igor via `Python`, `PythonFile`,
or the Python Console. You cannot connect to Igor from an external session.

Official docs:
- https://docs.wavemetrics.com/igorpro/python/python-overview
- https://docs.wavemetrics.com/igorpro/python/python-module-reference

---

## 1. Three Ways to Run Python from Igor

```igor
// Inline statement
Python "import numpy as np"

// Run a .py file
PythonFile file = "MyProject/analysis.py"

// With path symbolic name
NewPath/O scriptPath, "/path/to/scripts/"
PythonFile/P=scriptPath file = "analysis.py"
```

Python Console: Python menu → Open Console. Multi-line: Ctrl-Enter. Interrupt: Ctrl-C.

---

## 2. Setup

**Supported versions:** Python 3.11–3.14 (standard only, not free-threaded).

```igor
// Activate virtual environment programmatically
NewPath/O envPath, "path/to/parent/"
PythonEnv/P=envPath activate = "myEnv"
```

Warning: Cannot change environments without restarting Igor once a session starts.

**Auto sys.path locations:**
- `~/Documents/WaveMetrics/Igor Pro 10 User Files/Python Scripts`
- `~/Documents/WaveMetrics/Igor Pro 10 User Files/User Procedures`
- `C:/Program Files/WaveMetrics/Igor Pro 10 Folder/Python Scripts`

Subdirectories are NOT auto-added. Use `from MyProject import analysis`.

**VSCode autocomplete:** Add to settings.json:
```json
"python.analysis.extraPaths": [
    "C:/Program Files/WaveMetrics/Igor Pro 10 Folder/IgorBinaries_x64/Python"
]
```

---

## 3. Top-Level Functions

```python
import igorpro

igorpro.execute("Make/O/N=100 myWave")
igorpro.execute("WaveStats/Q myWave", ignoreErrors=True)
igorpro.print("Analysis complete")   # prints to Igor history
igorpro.version()
```

---

## 4. igorpro.wave

### Access existing
```python
w = igorpro.wave('root:myWave')
w = igorpro.wave('myWave')                        # relative to current DF
df = igorpro.folder('root:data')
w = igorpro.wave('intensity', df)                 # using folder context
```

### Create
```python
w = igorpro.wave.create('newWave')                # 128 pts, float32
w = igorpro.wave.create('qVec', 500, type=igorpro.float64)
w = igorpro.wave.create('mat', (256,256), value=0.0, type=igorpro.float32)
w = igorpro.wave.create('result', 100, overwrite=True)

# From NumPy/list (type inferred)
import numpy as np
w = igorpro.wave.createfrom('qWave', np.linspace(0.001, 0.5, 200))
w = igorpro.wave.createfrom('labels', ['s1', 's2', 's3'])

# In specific folder
w = igorpro.wave.create('fit', 200, folder=igorpro.folder('root:results'))
```

### Read
```python
arr   = w.asarray()       # numpy ndarray (numeric/text; copies data)
n     = w.points()
shape = w.shape()         # e.g. (200,) or (256,256)
ndims = w.dims()
wname = w.name()
wpath = w.path()
wtype = w.type()          # igorpro.WaveType enum
ux    = w.units('x')
ud    = w.units('d')      # data units ('d' or -1)
note  = w.note()
alive = w.exists()
start, delta = w.scale('x')

val  = w[0]               # indexing (zero-based)
w[5] = 3.14
val  = w[10, 20]          # 2D: [row, col]
```

### Modify
```python
w.set_data(np.sqrt(w.asarray()))

w.set_scale('x', 0.001, 0.5,   'range')   # start to end
w.set_scale('x', 0.001, 0.002, 'delta')   # start + step

w.set_units('x', '1/A')
w.set_units('d', 'cm-1')

w.set_label('x', 0, 'first_point')
w.set_label('x', -1, 'Q')                 # overall label

w.redimension(500)
w.redimension((100, 100))

w.kill()
```

### Stats
```python
s = w.stats()                    # dict: V_avg, V_sdev, V_min, V_max, ...
s = w.stats((0.01, 0.1))         # tuple = scaled x range
s = w.stats([10, 50])            # list = point index range
s = w.stats((..., 0.05))         # up to x=0.05
```

---

## 5. igorpro.WaveType

```python
igorpro.float32 / float64
igorpro.int8 / uint8 / int16 / uint16 / int32 / uint32
igorpro.int64 / uint64           # Igor 10+
igorpro.complex64 / complex128
igorpro.WaveType.text
```

**numpy.float16 is NOT supported — convert to float32 first.**

NumPy dtype → Igor type: float32→32-bit float, float64→64-bit float,
complex64→32-bit complex, complex128→64-bit complex, bool→uint8, str→text.
Integer types map directly to same-width Igor type.

---

## 6. igorpro.folder

```python
df = igorpro.folder('root:data')
df = igorpro.folder.current()
df = igorpro.folder.create('root:results')
df = igorpro.folder.create('root:results', overwrite=True)

parent  = df.parent()
sub     = df.subfolder('fits')
subs    = df.subfolders()         # list[igorpro.folder]
waves   = df.waves()              # list[igorpro.wave]

df.name(); df.path(); df.exists()
df.num_subfolders(); df.num_waves()

df.set()                          # set as current DF (restore afterwards!)
df.kill(ignoreErrors=True)
```

---

## 7. igorpro.variable

```python
v = igorpro.variable('root:Packages:MyPkg:temp')
val = v.value(); v.set(298.15)
v.exists(); v.real(); v.imag(); v.iscomplex()

v = igorpro.variable.create('root:Packages:MyPkg:Rg', 42.0)
v = igorpro.variable.create('root:myVar', 3+4j)
v = igorpro.variable.create('root:myVar', 0.0, overwrite=True)
```

---

## 8. igorpro.string

```python
s = igorpro.string('root:Packages:MyPkg:sampleName')
val = s.value(); s.set('new_name')
s.exists(); s.name(); s.path()

s = igorpro.string.create('root:Packages:MyPkg:fileName', 'data.h5')
s = igorpro.string.create('root:myStr', '', overwrite=True)
```

---

## 9. igorpro.fn — Call Igor Functions from Python

Case-insensitive. Calls built-in, XOP, or user-defined functions.

```python
# Built-ins
igorpro.fn.sqrt(2.0)                             # → float
igorpro.fn.num2str(3.14159)                      # → str
igorpro.fn.cmplx(3, -4)                          # → complex
igorpro.fn.sortlist('x;c;e;g;d;a', ';', 1)      # → str

# Pass a wave
w   = igorpro.wave('root:data:intensity')
med = igorpro.fn.median(w)                       # → float

# Returns wave reference
tw  = igorpro.fn.traceNameToWaveRef('Graph0', 'yWave')  # → igorpro.wave

# User-defined function
result = igorpro.fn.MyAnalysisFunc(w, 0.01, 0.1)

# Optional arguments: keyword=value syntax
igorpro.fn.greet('Jan')
igorpro.fn.greet('Jan', optionalPlace='Argonne')
```

### Return types
| Igor return | Python receives |
|-------------|-----------------|
| Variable (real) | float |
| Variable (complex) | complex |
| String | str |
| Wave reference | igorpro.wave |
| DFREF | igorpro.folder |

### igorpro.fn CANNOT call:
- Functions with pass-by-reference parameters
- Functions with Structure parameters
- Functions using Multiple Return Syntax `[a, b] = func()`
- Functions taking object names as bare identifiers (e.g. CsrInfo)
- Functions with FUNCREF arguments
- Igor operations (use `igorpro.execute` or wrap in a user function)
- `p`, `q`, `r`, `s`, `x`, `y`, `z`, `t` (wave loop variables)
- Functions returning free waves or free data folders

### Wrapping an operation
```igor
// Igor wrapper for an operation:
Function/WAVE RunWaveStats(Wave w)
    WaveStats/Q w
    Make/FREE/N=4 result = {V_avg, V_sdev, V_min, V_max}
    return result
End
```
```python
stats = igorpro.fn.RunWaveStats(w).asarray()
avg, sdev, vmin, vmax = stats
```

---

## 10. Object Lifetime Rules

- Objects created in Console or via operations are global, persist until Igor closes.
- Killing an Igor wave while Python holds it → exception on next use.
- Deleting `igorpro.wave` in Python does NOT kill the Igor wave.
- Opening a new Igor experiment invalidates all existing `igorpro` objects.
- Free waves and free data folders are NOT supported.

---

## 11. Stability Warnings

- Python crashes crash Igor — enable Igor auto-save.
- Avoid importing Qt for Python (Igor is Qt-based).
- Avoid non-blocking event loops.

---
