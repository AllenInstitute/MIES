#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=HistoricData

#include "UTF_HistoricData_Includes"

// Entry point for UTF
Function run()

	return RunWithOpts(instru = DoInstrumentation())
End

// Examples:
// - RunWithOpts()
// - RunWithOpts(testsuite = "UTF_Configuration.ipf")
// - RunWithOpts(testcase = "TestFindLevel")
Function RunWithOpts([string testcase, string testsuite, variable allowdebug, variable instru, string traceWinList, variable keepDataFolder, variable enableJU, variable enableRegExp])

	variable debugMode
	string   traceOptions
	string   list             = ""
	string   name             = GetTestName()
	variable waveTrackingMode = GetWaveTrackingMode()

	// speeds up testing to start with a fresh copy
	KillWindow/Z HistoryCarbonCopy

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

	if(ParamIsDefault(enableJU))
		enableJU = IsRunningInCI()
	else
		enableJU = !!enableJU
	endif

	if(ParamIsDefault(enableRegExp))
		enableRegExp = 0
	else
		enableRegExp = !!enableRegExp
	endif

	if(!instru)
		traceWinList = ""
	endif

	traceOptions = GetDefaultTraceOptions()

	// sorted list
	list = AddListItem("UTF_AttemptNWB2ExportOnOldData.ipf", list, ";", Inf)
	list = AddListItem("UTF_EpochRecreation.ipf", list, ";", Inf)
	list = AddListItem("UTF_HistoricAnalysisBrowser.ipf", list, ";", Inf)
	list = AddListItem("UTF_HistoricDashboard.ipf", list, ";", Inf)
	list = AddListItem("UTF_HistoricEpochClipping.ipf", list, ";", Inf)
	list = AddListItem("UTF_HistoricSweepBrowser.ipf", list, ";", Inf)
	list = AddListItem("UTF_HistoricSweepUpgrade.ipf", list, ";", Inf)

	if(ParamIsDefault(testsuite))
		testsuite = list
	else
		// do nothing
	endif

	if(IsEmpty(testcase))
		RunTest(testsuite, name = name, enableJU = enableJU, enableRegExp = enableRegExp, debugMode = debugMode, traceOptions = traceOptions, traceWinList = traceWinList, keepDataFolder = keepDataFolder, waveTrackingMode = waveTrackingMode)
	else
		RunTest(testsuite, name = name, enableJU = enableJU, enableRegExp = enableRegExp, debugMode = debugMode, testcase = testcase, traceOptions = traceOptions, traceWinList = traceWinList, keepDataFolder = keepDataFolder, waveTrackingMode = waveTrackingMode)
	endif
End

Function TEST_BEGIN_OVERRIDE(string name)

	TestBeginCommon()
End

Function TEST_END_OVERRIDE(string name)

	TestEndCommon()
End

Function TEST_CASE_BEGIN_OVERRIDE(string name)

	TestCaseBeginCommon(name)
End

Function TEST_CASE_END_OVERRIDE(string testcase)

	TestCaseEndCommon(testcase)
End
