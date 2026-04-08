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
- Use `SFH_ASSERT()` in SweepFormula operations for user-facing errors
- Use `DEBUGPRINT()` for debug output (only active when `DEBUGGING_ENABLED` is defined)

## Build and Test

### Pre-commit Hooks

The repository uses pre-commit hooks configured in `.pre-commit-config.yaml`:

- Run `./tools/run-ipt.sh lint -i --noreturn-func=FATAL_ERROR|SFH_FATAL_ERROR|FAIL` for IPF formatting
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

### Building Documentation

```bash
tools/documentation/run.sh
```

### Creating Installer

```bash
tools/create-installer.sh unelevated
```

## CI/CD Workflows

The repository uses GitHub Actions with these main workflows:

- `build-pr.yml` - PR validation (compilation, tests, documentation)
- `build-release.yml` - Release builds (deploys documentation, installer, reports)
- `test-igor-workflow.yml` - Reusable test workflow for Igor Pro

CI runs tests on multiple Igor Pro versions (9 and 10) and hardware configurations (ITC18, ITC1600, NI).

## Key Modules

- **SweepFormula** (`MIES_SweepFormula*.ipf`) - Scripting language for data evaluation
- **AnalysisFunctions** (`MIES_AnalysisFunctions*.ipf`) - Automated analysis during acquisition
- **Configuration** (`MIES_Configuration.ipf`) - JSON-based configuration management
- **Cache** (`MIES_Cache.ipf`) - Wave caching with hashmap-based key storage
- **Labnotebook** (`MIES_Labnotebook.ipf`) - Experiment metadata storage

## Important Notes

- The codebase maintains backward compatibility with all earlier MIES versions
- ZeroMQ is used for inter-process communication (use `ZEROMQ_PROT_AND_NETWORK` for TCP endpoints)
- NWBv2 format is used for data export
- Hardware support includes ITC (16/18/1600) and National Instruments DACs
