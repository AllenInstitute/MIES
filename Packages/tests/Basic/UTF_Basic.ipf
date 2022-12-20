#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=Basic

#include "UTF_HelperFunctions"

// keep sorted
#include "UTF_AnalysisBrowserTest"
#include "UTF_AnalysisFunctionHelpers"
#include "UTF_AnalysisFunctionParameters"
#include "UTF_AsynFrameworkTest"
#include "UTF_Configuration"
#include "UTF_EpochswoHardware"
#include "UTF_JSONWaveNotes"
#include "UTF_Labnotebook"
#include "UTF_Macros"
#include "UTF_PGCSetAndActivateControl"
#include "UTF_StimsetAPI"
#include "UTF_SweepFormula"
#include "UTF_Testpulse"
#include "UTF_ThreadsafeDataSharing"
#include "UTF_TraceUserData"
#include "UTF_UpgradeDataFolderLocation"
#include "UTF_UpgradeWaveLocationAndGetIt"
#include "UTF_Utils"
#include "UTF_WaveAveraging"
#include "UTF_WaveBuilder"
#include "UTF_WaveBuilderRegression"
#include "UTF_WaveVersioning"
#include "UTF_ZeroMQPublishing"

// include examples here so that these are compile tested as well
#include "example-stimulus-set-api"

// Entry point for UTF
Function run()
	return RunWithOpts(instru = DoInstrumentation())
End

// Examples:
// - RunWithOpts()
// - RunWithOpts(testsuite = "UTF_Configuration.ipf")
// - RunWithOpts(testcase = "TestFindLevel")
Function RunWithOpts([string testcase, string testsuite, variable allowdebug, variable instru, string traceWinList, variable keepDataFolder])

	variable debugMode
	string traceOptions = ""
	string list = ""
	string name = GetTestName()

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

	if(ParamIsDefault(instru))
		instru = 0
	else
		instru = !!instru
	endif

	if(ParamIsDefault(traceWinList))
		traceWinList = "MIES_.*\.ipf"
	endif

	if(ParamIsDefault(keepDataFolder))
		keepDataFolder = 0
	else
		keepDataFolder = !!keepDataFolder
	endif

	if(!instru)
		traceWinList = ""
	endif

	traceOptions = ReplaceNumberByKey(UTF_KEY_REGEXP, traceOptions, 1)

	// sorted list
	list = AddListItem("UTF_AnalysisBrowserTest.ipf", list, ";", inf)
	list = AddListItem("UTF_AnalysisFunctionHelpers.ipf", list, ";", inf)
	list = AddListItem("UTF_AnalysisFunctionParameters.ipf", list, ";", inf)
	list = AddListItem("UTF_AsynFrameworkTest.ipf", list, ";", inf)
	list = AddListItem("UTF_Configuration.ipf", list, ";", inf)
	list = AddListItem("UTF_EpochswoHardware.ipf", list, ";", inf)
	list = AddListItem("UTF_JSONWaveNotes.ipf", list, ";", inf)
	list = AddListItem("UTF_Labnotebook.ipf", list, ";", inf)
	list = AddListItem("UTF_Macros.ipf", list, ";", inf)
	list = AddListItem("UTF_PGCSetAndActivateControl.ipf", list, ";", inf)
	list = AddListItem("UTF_StimsetAPI.ipf", list, ";", inf)
	list = AddListItem("UTF_SweepFormula.ipf", list, ";", inf)
	list = AddListItem("UTF_Testpulse.ipf", list, ";", inf)
	list = AddListItem("UTF_TraceUserData.ipf", list, ";", inf)
	list = AddListItem("UTF_ThreadsafeDataSharing.ipf", list, ";", inf)
	list = AddListItem("UTF_UpgradeDataFolderLocation.ipf", list, ";", inf)
	list = AddListItem("UTF_UpgradeWaveLocationAndGetIt.ipf", list, ";", inf)
	list = AddListItem("UTF_Utils.ipf", list, ";", inf)
	list = AddListItem("UTF_WaveAveraging.ipf", list, ";", inf)
	list = AddListItem("UTF_WaveBuilder.ipf", list, ";", inf)
	list = AddListItem("UTF_WaveBuilderRegression.ipf", list, ";", inf)
	list = AddListItem("UTF_WaveVersioning.ipf", list, ";", inf)
	list = AddListItem("UTF_ZeroMQPublishing.ipf", list, ";", inf)

	if(ParamIsDefault(testsuite))
		testsuite = list
	else
		// do nothing
	endif

	if(IsEmpty(testcase))
		RunTest(testsuite, name = name, enableJU = 1, debugMode= debugMode, traceOptions=traceOptions, traceWinList=traceWinList, keepDataFolder = keepDataFolder)
	else
		RunTest(testsuite, name = name, enableJU = 1, debugMode= debugMode, testcase = testcase, traceOptions=traceOptions, traceWinList=traceWinList, keepDataFolder = keepDataFolder)
	endif
End

Function TEST_BEGIN_OVERRIDE(string name)
	RetrieveAllWindowsInCI()
End

Function TEST_CASE_BEGIN_OVERRIDE(name)
	string name

	AdditionalExperimentCleanup()
End

Function TEST_CASE_END_OVERRIDE(string testcase)
	CheckForBugMessages()
End
