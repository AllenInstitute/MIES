#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=HardwareBasic

#include "UTF_HardwareHelperFunctions"

// keep sorted
#include "UTF_AnalysisFunctionManagement"
#include "UTF_AutoTestpulse"
#include "UTF_BasicHardwareTests"
#include "UTF_DAEphys"
#include "UTF_Dashboard"
#include "UTF_Epochs"
#include "UTF_HardwareTestsWithBUG"
#include "UTF_SweepFormulaHardware"
#include "UTF_VeryBasicHardwareTests"

#include "UTF_VeryLastTestSuite"

// Entry point for UTF
Function run()
	return RunWithOpts(instru = DoInstrumentation())
End

// Examples:
// - RunWithOpts()
// - RunWithOpts(testsuite = "UTF_Epochs.ipf")
// - RunWithOpts(testcase = "EP_EpochTest7")
// - RunWithOpts(testcase = "EP_EpochTest7", instru = 1, traceWinList = "MIES_Epochs.ipf")
Function RunWithOpts([string testcase, string testsuite, variable allowdebug, variable instru, string traceWinList, variable ITCXOP2Debug])

	variable debugMode
	string traceOptions = ""
	string list = ""
	string name = "MIES with Hardware"

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

	if(ParamIsDefault(ITCXOP2Debug))
		ITCXOP2Debug = 0
	else
		ITCXOP2Debug = !!ITCXOP2Debug
	endif

	if(!instru)
		traceWinList = ""
	endif

	HW_ITC_DebugMode(ITCXOP2Debug)

	traceOptions = ReplaceNumberByKey(UTF_KEY_REGEXP, traceOptions, 1)

	list = AddListItem("UTF_VeryBasicHardwareTests.ipf", list, ";", inf)
	list = AddListItem("UTF_BasicHardwareTests.ipf", list, ";", inf)
	list = AddListItem("UTF_DAEphys.ipf", list, ";", inf)
	list = AddListItem("UTF_Dashboard.ipf", list, ";", inf)
	list = AddListItem("UTF_Epochs.ipf", list, ";", inf)
	list = AddListItem("UTF_SweepFormulaHardware.ipf", list, ";", inf)
	list = AddListItem("UTF_AnalysisFunctionManagement.ipf", list, ";", inf)
	list = AddListItem("UTF_AutoTestpulse.ipf", list, ";", inf)
	list = AddListItem("UTF_VeryLastTestSuite.ipf", list, ";", inf)

	// tests which BUG out must come after the test-all tests in UTF_VeryLastTestSuite.ipf
	list = AddListItem("UTF_HardwareTestsWithBUG.ipf", list, ";", inf)

	if(ParamIsDefault(testsuite))
		testsuite = list
	else
		// do nothing
	endif

	if(IsEmpty(testcase))
		RunTest(testsuite, name = name, enableJU = 1, debugMode= debugMode, traceOptions=traceOptions, traceWinList=traceWinList)
	else
		RunTest(testsuite, name = name, enableJU = 1, debugMode= debugMode, testcase = testcase, traceOptions=traceOptions, traceWinList=traceWinList)
	endif
End
