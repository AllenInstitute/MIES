#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IndependentModule=CompilationTester

/// @cond DOXYGEN_IGNORES_THIS
#include "unit-testing"
/// @endcond // DOXYGEN_IGNORES_THIS

/// @file CompilationTester.ipf
///
/// @brief Compilation Testing
///
/// How it works:
///  - `input.txt` holds a EOL separated list of files to test and must be
///    located in the same folder as the experiment.
///  - The procedure files to be included must be located in
///    the Igor Pro "User Procedure".
///  - For each include file use the unit-testing framework to report the
///    success/failure of the compilation check.

/// @brief Perform compilation testing
///
/// This function should be called by a Function named `run` without arguments in ProcGlobal.
/// See chapter 1.5 in the unit testing framework [documentation](../Manual-UnitTestingFramework-v1.03.pdf).
Function TestCompilation()
	variable i, numEntries

	string data, includeFile

	string/G root:includeFile = ""

	NVAR compilationState = $GetCompilationState()
	compilationState = 0x0

	data = LoadTextFile("input.txt")
	data = ReplaceString("\r\n", data, "\n")
	data = ReplaceString("\r", data, "\n")
	data = RemoveEnding(data, "\n")
	WAVE/T includeFileList = ListToTextWave(data, "\n")

	compilationState = 0x1

	numEntries = DimSize(includeFileList, 0)
	REQUIRE(numEntries > 0)
	for(i = 0; i < numEntries; i += 1)
		includeFile = trimstring(includeFileList[i])
		CHECK_PROPER_STR(includeFile)
		TestCompilationOnFile(includeFile)
	endfor
End

Function TestCompilationOnFile(includeFile)
	string includeFile

	NVAR compilationState = $GetCompilationState()
	compilationState = 0x1

	Execute/P "root:includeFile = " + "\"" + includeFile + "\""
	Execute/P "INSERTINCLUDE \"" + includeFile + "\""
	Execute/P "compilationState = 0x2"
	Execute/P "COMPILEPROCEDURES "
	Execute/P "root:compilationState = CompilationTester#IsProcGlobalCompiled() ? 0x4 : 0x8"
	Execute/P "DELETEINCLUDE \"" + includeFile + "\""
	Execute/P "CloseProc/COMP=1/NAME=\"" + includeFile + ".ipf\""
	Execute/P "CompilationTester#runTest(\"CompilationTester.ipf\", name = \"Evaluate " + includeFile +"\", testCase = \"EvaluateResult\", enableJU = 1)"
End

Function EvaluateResult()

	string str, ref
	NVAR compilationState = $GetCompilationState()
	SVAR includeFile      = root:includeFile

	strswitch(includeFile)
		case "MIES_Include":
			CHECK_EQUAL_VAR(compilationState, 0x4) // "MIES_Include"
			break
		case "MIES_AnalysisBrowser":
			CHECK_EQUAL_VAR(compilationState, 0x4) // "MIES_AnalysisBrowser"
			break
		case "MIES_DataBrowser":
			CHECK_EQUAL_VAR(compilationState, 0x4) // "MIES_DataBrowser"
			break
		case "MIES_WaveBuilderPanel":
			CHECK_EQUAL_VAR(compilationState, 0x4) // "MIES_WaveBuilderPanel"
			break
		case "MIES_Downsample":
			CHECK_EQUAL_VAR(compilationState, 0x4) // "MIES_Downsample"
			break
		case "UTF_Main":
			CHECK_EQUAL_VAR(compilationState, 0x4) // "UTF_Main"
			break
		case "UTF_HardwareMain":
			CHECK_EQUAL_VAR(compilationState, 0x4) // "UTF_HardwareMain"
			break
		default:
			CHECK_EQUAL_VAR(compilationState, 0x4) // "unknown"
			FAIL()
			break
	endswitch
End
