#pragma rtGlobals         = 3
#pragma rtFunctionErrors  = 1
#pragma TextEncoding      = "UTF-8"
#pragma ModuleName        = CompilationTester
#pragma IndependentModule = MIES_CompilationTester

#include "igortest"

/// IUTF_SKIP
Function run()

	MIES_CompilationTester#runTest("CompilationTester.ipf", name = "Compilation tests", testCase = "TestCompilation", enableJU = 1)
End

static Function SetDimensionLabelsFromWaveContents(WAVE/T wv)

	variable idx
	string   elem

	for(elem : wv)
		SetDimLabel 0, idx++, $elem, wv
	endfor
End

// Read the environment variable `key` as number and if present, return 1 for
// all finite values not equal to 0 and 0 otherwise. Return `NaN` in all other
// cases.
static Function GetEnvironmentVariableAsBoolean(string key)

	variable value, err

	value = str2num(GetEnvironmentVariable(key)); err = GetRTError(-1)

	if(numtype(value) == 0)
		return !!value
	endif

	return NaN
End

static Function/WAVE GetIncludes()

	// keep sorted
	Make/FREE/T includes = {"UTF_All_Includes"}

	SetDimensionLabelsFromWaveContents(includes)

	return includes
End

static Function/WAVE GetDefines()

	if(GetEnvironmentVariableAsBoolean("CI_SKIP_COMPILATION_TEST_DEFINES"))
		Make/FREE/T/N=1 defines
		return defines
	endif

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
	                       "TESTS_WITH_SUTTER_HARDWARE",   \
	                       "WAVECACHE_DISABLED",           \
	                       "TP_ANALYSIS_DEBUGGING",        \
	                       "THREADING_DISABLED"}

	SetDimensionLabelsFromWaveContents(defines)

	return defines
End

/// UTF_TD_GENERATOR s0:CompilationTester#GetIncludes
/// UTF_TD_GENERATOR s1:CompilationTester#GetDefines
Function TestCompilation([STRUCT IUTF_mData &md])

	if(strlen(md.s1) > 0)
		CHECK_COMPILATION(md.s0, defines = {md.s1})
	else
		CHECK_COMPILATION(md.s0)
	endif
End
