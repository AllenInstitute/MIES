#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#include "MIES_Include"
#include "unit-testing"

#include "UTF_HelperFunctions"
#include "UTF_PA_Tests"

// Entry point for UTF
Function run()
	return RunWithOpts()
End

// Examples:
// - RunWithOpts()
// - RunWithOpts(testsuite = "UTF_PA_Tests.ipf")
// - RunWithOpts(testcase = "PAT_ZeroPulses")
Function RunWithOpts([string testcase, string testsuite, variable allowdebug])

	variable debugMode
	string list = ""
	string name = "MIES pulse average tests"

	// speeds up testing to start with a fresh copy
	KillWindow/Z HistoryCarbonCopy
	DisableDebugOutput()

	if(ParamIsDefault(allowdebug))
		debugMode = 0
	else
		debugMode = IUTF_DEBUG_FAILED_ASSERTION | IUTF_DEBUG_ENABLE | IUTF_DEBUG_ON_ERROR | IUTF_DEBUG_NVAR_SVAR_WAVE
	endif

	if(ParamIsDefault(testcase))
		testcase = ""
	endif

	list = AddListItem("UTF_PA_Tests.ipf", list, ";", inf)

	if(ParamIsDefault(testsuite))
		testsuite = list
	else
		// do nothing
	endif

	if(IsEmpty(testcase))
		RunTest(testsuite, name = name, enableJU = 1, debugMode= debugMode)
	else
		RunTest(testsuite, name = name, enableJU = 1, debugMode= debugMode, testcase = testcase)
	endif
End
