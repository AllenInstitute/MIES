#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=HardwareAnalysisFunctions

#include "::UTF_HardwareHelperFunctions"

// keep sorted
#include "UTF_MultiPatchSeqDAScale"
#include "UTF_MultiPatchSeqFastRheoEstimate"
#include "UTF_MultiPatchSeqSpikeControl"
#include "UTF_PatchSeqAccessResistanceSmoke"
#include "UTF_PatchSeqChirp"
#include "UTF_PatchSeqDAScale"
#include "UTF_PatchSeqPipetteInBath"
#include "UTF_PatchSeqRamp"
#include "UTF_PatchSeqRheobase"
#include "UTF_PatchSeqSealEvaluation"
#include "UTF_PatchSeqSquarePulse"
#include "UTF_PatchSeqTrueRestingMembranePotential"
#include "UTF_ReachTargetVoltage"
#include "UTF_SetControls"

// Entry point for UTF
Function run()
	return RunWithOpts(instru = DoInstrumentation())
End

// Examples:
// - RunWithOpts()
// - RunWithOpts(testsuite = "UTF_Epochs.ipf")
// - RunWithOpts(testcase = "EP_EpochTest7")
// - RunWithOpts(testcase = "EP_EpochTest7", instru = 1, traceWinList = "MIES_Epochs.ipf")
Function RunWithOpts([string testcase, string testsuite, variable allowdebug, variable instru, string traceWinList, variable ITCXOP2Debug, variable keepDataFolder])

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

	if(ParamIsDefault(ITCXOP2Debug))
		ITCXOP2Debug = 0
	else
		ITCXOP2Debug = !!ITCXOP2Debug
	endif

	if(ParamIsDefault(keepDataFolder))
		keepDataFolder = 0
	else
		keepDataFolder = !!keepDataFolder
	endif

	if(!instru)
		traceWinList = ""
	endif

	HW_ITC_DebugMode(ITCXOP2Debug)

	traceOptions = ReplaceNumberByKey(UTF_KEY_REGEXP, traceOptions, 1)

	list = AddListItem("UTF_SetControls.ipf", list, ";", inf)
	list = AddListItem("UTF_PatchSeqAccessResistanceSmoke.ipf", list, ";", inf)
	list = AddListItem("UTF_PatchSeqChirp.ipf", list, ";", inf)
	list = AddListItem("UTF_PatchSeqDAScale.ipf", list, ";", inf)
	list = AddListItem("UTF_PatchSeqSealEvaluation.ipf", list, ";", inf)
	list = AddListItem("UTF_PatchSeqSquarePulse.ipf", list, ";", inf)
	list = AddListItem("UTF_PatchSeqRheobase.ipf", list, ";", inf)
	list = AddListItem("UTF_PatchSeqRamp.ipf", list, ";", inf)
	list = AddListItem("UTF_PatchSeqPipetteInBath.ipf", list, ";", inf)
	list = AddListItem("UTF_PatchSeqTrueRestingMembranePotential.ipf", list, ";", inf)
	list = AddListItem("UTF_ReachTargetVoltage.ipf", list, ";", inf)
	list = AddListItem("UTF_MultiPatchSeqFastRheoEstimate.ipf", list, ";", inf)
	list = AddListItem("UTF_MultiPatchSeqDAScale.ipf", list, ";", inf)
	// list = AddListItem("UTF_MultiPatchSeqSpikeControl.ipf", list, ";", inf)

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
