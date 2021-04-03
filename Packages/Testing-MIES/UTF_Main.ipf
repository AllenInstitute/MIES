#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#include "MIES_Include", optional
#include "unit-testing"

#include "UTF_AnalysisFunctionHelpers"
#include "UTF_PGCSetAndActivateControl"
#include "UTF_UpgradeWaveLocationAndGetIt"
#include "UTF_UpgradeDataFolderLocation"
#include "UTF_Utils"
#include "UTF_Labnotebook"
#include "UTF_WaveBuilder"
#include "UTF_WaveBuilderRegression"
#include "UTF_WaveVersioning"
#include "UTF_AsynFrameworkTest"
#include "UTF_SweepFormula"
#include "UTF_TraceUserData"
#include "UTF_Configuration"
#include "UTF_HelperFunctions"
#include "UTF_WaveAveraging"

// Entry point for UTF
Function run()
	return RunWithOpts()
End

// Examples:
// - RunWithOpts()
// - RunWithOpts(testsuite = "UTF_Configuration.ipf")
// - RunWithOpts(testcase = "TestFindLevel")
Function RunWithOpts([string testcase, string testsuite, variable allowdebug])
	variable debugMode
	string list = ""
	string name = "MIES"

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

	// sorted list
	list = AddListItem("UTF_AnalysisFunctionHelpers.ipf", list, ";", inf)
	list = AddListItem("UTF_AsynFrameworkTest.ipf", list, ";", inf)
	list = AddListItem("UTF_Configuration.ipf", list, ";", inf)
	list = AddListItem("UTF_Labnotebook.ipf", list, ";", inf)
	list = AddListItem("UTF_PGCSetAndActivateControl.ipf", list, ";", inf)
	list = AddListItem("UTF_SweepFormula.ipf", list, ";", inf)
	list = AddListItem("UTF_TraceUserData.ipf", list, ";", inf)
	list = AddListItem("UTF_UpgradeDataFolderLocation.ipf", list, ";", inf)
	list = AddListItem("UTF_UpgradeWaveLocationAndGetIt.ipf", list, ";", inf)
	list = AddListItem("UTF_Utils.ipf", list, ";", inf)
	list = AddListItem("UTF_WaveAveraging.ipf", list, ";", inf)
	list = AddListItem("UTF_WaveBuilder.ipf", list, ";", inf)
	list = AddListItem("UTF_WaveBuilderRegression.ipf", list, ";", inf)
	list = AddListItem("UTF_WaveVersioning.ipf", list, ";", inf)

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

Function TEST_CASE_BEGIN_OVERRIDE(name)
	string name

	AdditionalExperimentCleanup()
End
