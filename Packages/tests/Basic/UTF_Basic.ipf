#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=Basic

#include "UTF_HelperFunctions"

// keep sorted
#include "UTF_Amplifier"
#include "UTF_AnalysisBrowserTest"
#include "UTF_AnalysisFunctionHelpers"
#include "UTF_AnalysisFunctionParameters"
#include "UTF_AnalysisFunctionPrototypes"
#include "UTF_AsynFrameworkTest"
#include "UTF_Configuration"
#include "UTF_DAEphyswoHardware"
#include "UTF_Debugging"
#include "UTF_EpochswoHardware"
#include "UTF_ForeignFunctionInterface"
#include "UTF_GuiUtilities"
#include "UTF_JSONWaveNotes"
#include "UTF_Labnotebook"
#include "UTF_Macros"
#include "UTF_oodDAQ"
#include "UTF_PGCSetAndActivateControl"
#include "UTF_StimsetAPI"
#include "UTF_SweepFormula"
#include "UTF_SweepFormula_Operations"
#include "UTF_SweepFormula_PSX"
#include "UTF_Testpulse"
#include "UTF_ThreadsafeDataSharing"
#include "UTF_TraceUserData"
#include "UTF_UpgradeDataFolderLocation"
#include "UTF_UpgradeWaveLocationAndGetIt"
#include "UTF_Utils_Algorithm"
#include "UTF_Utils_Checks"
#include "UTF_Utils_Conversions"
#include "UTF_Utils_DataFolder"
#include "UTF_Utils_File"
#include "UTF_Utils_GUI"
#include "UTF_Utils_List"
#include "UTF_Utils_Mies_Algorithm"
#include "UTF_Utils_Mies_BackupWaves"
#include "UTF_Utils_Mies_Config"
#include "UTF_Utils_Mies_Logging"
#include "UTF_Utils_Mies_Sweep"
#include "UTF_Utils_Numeric"
#include "UTF_Utils_ProgramFlow"
#include "UTF_Utils_Strings"
#include "UTF_Utils_Settings"
#include "UTF_Utils_System"
#include "UTF_Utils_Time"
#include "UTF_Utils_WaveHandling"
#include "UTF_UtilsChecks"
#include "UTF_WaveAveraging"
#include "UTF_WaveBuilder"
#include "UTF_WaveBuilderRegression"
#include "UTF_WaveVersioning"
#include "UTF_XOPsCompilation"
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
Function RunWithOpts([string testcase, string testsuite, variable allowdebug, variable instru, string traceWinList, variable keepDataFolder, variable enableJU])

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

	if(ParamIsDefault(enableJU))
		enableJU = IsRunningInCI()
	else
		enableJU = !!enableJU
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

	traceOptions = GetDefaultTraceOptions()

	// sorted list
	list = AddListItem("UTF_Amplifier.ipf", list, ";", Inf)
	list = AddListItem("UTF_AnalysisBrowserTest.ipf", list, ";", Inf)
	list = AddListItem("UTF_AnalysisFunctionHelpers.ipf", list, ";", Inf)
	list = AddListItem("UTF_AnalysisFunctionParameters.ipf", list, ";", Inf)
	list = AddListItem("UTF_AnalysisFunctionPrototypes.ipf", list, ";", Inf)
	list = AddListItem("UTF_AsynFrameworkTest.ipf", list, ";", Inf)
	list = AddListItem("UTF_Debugging.ipf", list, ";", Inf)
	list = AddListItem("UTF_Configuration.ipf", list, ";", Inf)
	list = AddListItem("UTF_DAEphyswoHardware.ipf", list, ";", Inf)
	list = AddListItem("UTF_EpochswoHardware.ipf", list, ";", Inf)
	list = AddListItem("UTF_ForeignFunctionInterface.ipf", list, ";", Inf)
	list = AddListItem("UTF_GuiUtilities.ipf", list, ";", Inf)
	list = AddListItem("UTF_JSONWaveNotes.ipf", list, ";", Inf)
	list = AddListItem("UTF_Labnotebook.ipf", list, ";", Inf)
	list = AddListItem("UTF_Macros.ipf", list, ";", Inf)
	list = AddListItem("UTF_oodDAQ.ipf", list, ";", Inf)
	list = AddListItem("UTF_PGCSetAndActivateControl.ipf", list, ";", Inf)
	list = AddListItem("UTF_StimsetAPI.ipf", list, ";", Inf)
	list = AddListItem("UTF_SweepFormula.ipf", list, ";", Inf)
	list = AddListItem("UTF_SweepFormula_Operations.ipf", list, ";", Inf)
	list = AddListItem("UTF_SweepFormula_PSX.ipf", list, ";", Inf)
	list = AddListItem("UTF_Testpulse.ipf", list, ";", Inf)
	list = AddListItem("UTF_TraceUserData.ipf", list, ";", Inf)
	list = AddListItem("UTF_ThreadsafeDataSharing.ipf", list, ";", Inf)
	list = AddListItem("UTF_UpgradeDataFolderLocation.ipf", list, ";", Inf)
	list = AddListItem("UTF_UpgradeWaveLocationAndGetIt.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_Algorithm.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_Checks.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_Conversions.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_DataFolder.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_File.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_GUI.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_List.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_Mies_Algorithm.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_Mies_BackupWaves.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_Mies_Config.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_Mies_Logging.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_Mies_Sweep.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_Numeric.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_ProgramFlow.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_Strings.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_Settings.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_System.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_Time.ipf", list, ";", Inf)
	list = AddListItem("UTF_Utils_WaveHandling.ipf", list, ";", Inf)
	list = AddListItem("UTF_UtilsChecks.ipf", list, ";", Inf)
	list = AddListItem("UTF_WaveAveraging.ipf", list, ";", Inf)
	list = AddListItem("UTF_WaveBuilder.ipf", list, ";", Inf)
	list = AddListItem("UTF_WaveBuilderRegression.ipf", list, ";", Inf)
	list = AddListItem("UTF_WaveVersioning.ipf", list, ";", Inf)
	list = AddListItem("UTF_ZeroMQPublishing.ipf", list, ";", Inf)

	if(ParamIsDefault(testsuite))
		testsuite = list
	else
		// do nothing
	endif

	if(IsEmpty(testcase))
		RunTest(testsuite, name = name, enableJU = enableJU, debugMode = debugMode, traceOptions = traceOptions, traceWinList = traceWinList, keepDataFolder = keepDataFolder, waveTrackingMode = waveTrackingMode)
	else
		RunTest(testsuite, name = name, enableJU = enableJU, debugMode = debugMode, testcase = testcase, traceOptions = traceOptions, traceWinList = traceWinList, keepDataFolder = keepDataFolder, waveTrackingMode = waveTrackingMode)
	endif
End

Function TEST_BEGIN_OVERRIDE(string name)

	TestBeginCommon()

	if(DoExpensiveChecks())
		PrepareForPublishTest()
	endif
End

Function TEST_END_OVERRIDE(string name)

	TestEndCommon()
End

Function TEST_CASE_BEGIN_OVERRIDE(string name)

	TestCaseBeginCommon(name)
End

Function TEST_CASE_END_OVERRIDE(string testcase)

	TestCaseEndCommon(testcase)

	if(DoExpensiveChecks())
		CheckPubMessagesHeartbeatOnly()
	endif
End
