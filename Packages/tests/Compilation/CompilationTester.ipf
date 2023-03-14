#pragma rtGlobals=3
#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma IndependentModule=MIES_CompilationTester

#include "igortest"

/// IUTF_SKIP
Function run()
	MIES_CompilationTester#runTest("CompilationTester.ipf", name = "Compilation tests", testCase = "TestCompilation", enableJU = 1)
End

static Function SetDimensionLabelsFromWaveContents(WAVE/T wv)

	variable idx
	string elem

	for(elem: wv)
		SetDimLabel 0, idx++, $elem, wv
	endfor
End

Function/WAVE GetIncludes()
	// keep sorted
	Make/FREE/T includes = {"MIES_Include",                  \
	                        "UTF_Basic",                     \
	                        "UTF_PAPlot",                    \
	                        "UTF_HardwareAnalysisFunctions", \
	                        "UTF_HardwareBasic"}

	SetDimensionLabelsFromWaveContents(includes)

	return includes
End

Function/WAVE GetDefines()
	// keep sorted
	Make/FREE/T defines = {"AUTOMATED_TESTING",            \
	                       "AUTOMATED_TESTING_DEBUGGING",  \
	                       "AUTOMATED_TESTING_EXPENSIVE",  \
	                       "BACKGROUND_TASK_DEBUGGING",    \
	                       "DEBUGGING_ENABLED",            \
	                       "EVIL_KITTEN_EATING_MODE",      \
	                       "SWEEPFORMULA_DEBUG",           \
	                       "TESTS_WITH_ITC1600_HARDWARE",  \
	                       "TESTS_WITH_ITC18USB_HARDWARE", \
	                       "TESTS_WITH_NI_HARDWARE",       \
	                       "THREADING_DISABLED"}

	SetDimensionLabelsFromWaveContents(defines)

	return defines
End

/// UTF_TD_GENERATOR s0:GetIncludes
/// UTF_TD_GENERATOR s1:GetDefines
Function TestCompilation([STRUCT IUTF_mData & md])

	CHECK_COMPILATION(md.s0, defines = {md.s1})
End
