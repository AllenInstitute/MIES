# Copilot Instructions for MIES

## Project Overview

MIES (Multichannel Igor Electrophysiology Suite) is a sweep-based data acquisition software package for intracellular electrophysiology (patch clamp). It runs on Igor Pro 9 (nightly) or later and supports Windows 11 64-bit for data acquisition and Windows/macOS for analysis.

## Repository Structure

- `Packages/MIES/` - Main Igor Pro procedure files (.ipf) containing the core MIES functionality
- `Packages/tests/` - Test files organized by category (Basic, HardwareBasic, HardwareAnalysisFunctions, etc.)
- `Packages/IPNWB/` - NWB (Neurodata Without Borders) support
- `Packages/ITCXOP2/` - ITC hardware XOP support
- `Packages/doc/` - Documentation source files
- `tools/` - Build, test, and utility scripts
- `HelpFiles/`, `HelpFiles-IP9/`, `HelpFiles-IP10/` - Igor Pro help files for different versions

## Coding Conventions for Igor Pro (.ipf files)

### File Header

Every IPF file must start with:

```igor
#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
```

For files used in automated testing, also include:

```igor
#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_MODULENAME
#endif // AUTOMATED_TESTING
```

### Documentation

- Use Doxygen-style documentation with `///` comments
- Document files with `/// @file FILENAME.ipf` followed by `/// @brief Description`
- Document functions with `/// @brief` and `/// @param` tags
- Use `///@{` and `///@}` to group related constants or functions

### Naming Conventions

- Constants: `UPPER_SNAKE_CASE` (e.g., `NUM_HEADSTAGES`, `DA_EPHYS_PANEL_VERSION`)
- String constants: `StrConstant NAME = "value"` with `UPPER_SNAKE_CASE`
- Functions: `PascalCase` with prefixes indicating the module (e.g., `SF_` for SweepFormula, `PSQ_` for PatchSeq)
- Variables: `camelCase`
- Structures: `PascalCase`

### Code Style

- Use tabs for indentation (tab width: 4 spaces)
- Use UTF-8 encoding
- Unix-style line endings (LF)
- Trim trailing whitespace
- Insert final newline
- The code style must follow the Igor Pro Coding Conventions defined in https://github.com/byte-physics/igor-pro-coding-conventions and specifically from https://github.com/byte-physics/igor-pro-coding-conventions/blob/main/coding_conventions.rst and https://github.com/byte-physics/igor-pro-coding-conventions/blob/main/coding_bestpractices.rst
- Global constants must be defined in MIES_Constants.ipf
- Global structures must be defined in MIES_Structures.ipf
- Functions that are called from the same procedure file only must be static.

### Structure Patterns

When functions modify structures, pass them by reference:

```igor
Function InitMyStruct(STRUCT MyStruct &s)
    s.field = value
End
```

### Wave Handling

- Use `WAVE/Z` for optional waves that may not exist
- Use `MakeWaveFree()` to convert persistent waves to free waves
- Always validate wave references before use

### Error Handling

- Use `ASSERT()` for internal consistency checks
- Use `ASSERT_TS()` for internal consistency checks in threadsafe functions
- Use `FATAL_ERROR()` for code paths that unconditionally create an error
- Use `SFH_ASSERT()` in SweepFormula operations for user-facing errors
- Use `DEBUGPRINT()` for debug output (only active when `DEBUGGING_ENABLED` is defined)

## Build and Test

### Pre-commit Hooks

The repository uses pre-commit hooks configured in `.pre-commit-config.yaml`:

- Run `./tools/run-ipt.sh lint -i --noreturn-func='FATAL_ERROR|SFH_FATAL_ERROR|FAIL'` for IPF formatting
- Custom code checks via `./tools/check-code.sh`

### Running Tests

Tests are run via Igor Pro experiments (.pxp files):

```bash
tools/autorun-test.sh -p Packages/tests/Basic/Basic.pxp -v IP_9_64
```

Test categories:

- `Basic` - Core functionality tests (no hardware required)
- `PAPlot` - Pulse averaging plot tests
- `HistoricData` - Historic data compatibility tests
- `HardwareBasic` - Hardware-dependent basic tests
- `HardwareAnalysisFunctions` - Hardware-dependent analysis function tests
- `Compilation` - Compilation verification tests

### Writing Tests

- The test framework used for MIES is [IgorTest](https://github.com/byte-physics/igortest) with documentation in the [IgorTest reference docs](../.claude/skills/igortest/) files.
- Procedures containing tests are located in Packages/tests with sub folders for specific test categories
- Tests must be part of one of the test categories
- Test case functions must be declared static
- Test cases must not have any wave leaks
- Test cases must not leave any new permanent objects in their data folder hierarchy
- If the same test is applied for different input data then a single test case has to be created and the input data provided through a data generator function
- Data generator functions must be in Packages/tests/UTF_DataGenerators.ipf and declared as static
- Any new utility function that is created for a generic task in either MIES_Utilities*.ipf or MIES_MiesUtilities*.ipf must have its own test cases
- Test cases may call static MIES functions by prefixing the ModuleName defined in the MIES procedure files when AUTOMATED_TESTING is defined

### Building Documentation

```bash
tools/build-documentation.sh
```

### Creating Installer

```bash
tools/create-installer.sh unelevated
```

## CI/CD Workflows

The repository uses GitHub Actions with these main workflows:

- [PR validation](workflows/build-pr.yml) (compilation, tests, documentation)
- [Release builds](workflows/build-release.yml) -  (deploys documentation, installer, reports)
- [Test Workflow](workflows/test-igor-workflow.yml) - Reusable test workflow for Igor Pro

CI runs tests on multiple Igor Pro versions (9 and 10) and hardware configurations (ITC18, ITC1600, NI).

## Key Modules

- **SweepFormula** (`MIES_SweepFormula*.ipf`) - Scripting language for data evaluation
- **AnalysisFunctions** (`MIES_AnalysisFunctions*.ipf`) - Automated analysis during acquisition
- **Configuration** (`MIES_Configuration.ipf`) - JSON-based configuration management
- **Cache** (`MIES_Cache.ipf`) - Wave caching with hashmap-based key storage
- **Labnotebook** (`MIES_Labnotebook.ipf`) - Experiment metadata storage
- **AnalysisBrowser** (`MIES_AnalysisBrowser*.ipf`) - GUI that allows loading of saved sweep and stimset data from *.pxp and *.nwb files
- **DAEphys** (`MIES_DAEphys*.ipf`) - GUI to setup and control data acquisition
- **DataBrowser** (`MIES_DataBrowser*.ipf`) - GUI to display and analyze data from current acquisition
- **Epochs** (`MIES_Epochs.ipf`) - Logic to create and read epoch information for sweep data
- **WaveBuilder** (`MIES_WaveBuilder*.ipf`) - GUI that allows the creation of user-defined stimsets

## Igor Pro

The language, commands and the environment within Igor Pro is described at https://docs.wavemetrics.com/

Some aspects of the Igor Pro programming language are different to other common programming languages:
- variables, strings, wave references, datafolder references, function references, constants, structure names and dimension labels are case-insensitive
- Object references can be redefined within the same function with a different name. If the object is a WAVE and the wave type (e.g. /T) is explicitly set at the first declaration then all following redeclarations must have the same type.

```igorpro
Function test()
    WAVE wv = WaveGetterFunctionOne()
    WAVE wv = WaveGetterFunctionTwo()
    WAVE/T wvt = WaveGetterFunctionThree()
    WAVE/T wvt = WaveGetterFunctionFour()
End
```

- Functions defined in Igor Pro procedure code can use also Multiple-Return-Syntax (MRS) that is documented at https://docs.wavemetrics.com/igorpro/programming/programming#multiple-return-syntax
- Igor Pro initializes variables in functions with zero
- Igor Pro initializes strings in function with null-strings
- Igor Pro initializes new numeric waves with zero when created
- Igor Pro initializes new text waves with empty strings
- Igor Pro initializes new wave-reference waves with null references
- Igor Pro initializes new data-folder-reference waves with null references
- Documentation for JSONXOP_* operations are at https://docs.byte-physics.de/json-xop/
- Documentation for TUFXOP_* operations are at https://docs.byte-physics.de/tuf-xop/
- Always use inline syntax in Function declaration
- At the end of a Function with multiple return syntax always put a `return [...]` statement.

- include all instructions for [Igor Pro 10](../.claude/skills/igor-10/SKILL.md)
- include all instructions for [Igor Pro commands](../.claude/skills/igor-commands/SKILL.md)
- include all instructions for [Igor Pro - Python interface](../.claude/skills/igor-python/SKILL.md)
- include all instructions for [Igor Pro Wave and Datafolder reference handling](../.claude/skills/igor-wave-dfref/SKILL.md)
- include all instructions for [Documentation](../.claude/skills/docu/SKILL.md)

## Important Notes

- The codebase maintains backward compatibility with all earlier MIES versions
- ZeroMQ is used for inter-process communication (use `ZEROMQ_PROT_AND_NETWORK` for TCP endpoints)
- NWBv2 format is used for data export
- Hardware support includes ITC (16/18/1600) and National Instruments DACs
