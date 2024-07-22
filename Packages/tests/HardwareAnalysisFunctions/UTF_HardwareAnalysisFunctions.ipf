#pragma TextEncoding="UTF-8"
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
#include "UTF_PatchSeqDAScale_Adapt"
#include "UTF_PatchSeqDAScale_Sub"
#include "UTF_PatchSeqDAScale_Supra"
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
Function RunWithOpts([string testcase, string testsuite, variable allowdebug, variable instru, string traceWinList, variable ITCXOP2Debug, variable keepDataFolder, variable enableJU])

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

	if(ParamIsDefault(enableJU))
		enableJU = IsRunningInCI()
	else
		enableJU = !!enableJU
	endif

	if(!instru)
		traceWinList = ""
	endif

	HW_ITC_DebugMode(ITCXOP2Debug)

	traceOptions = GetDefaultTraceOptions()

	list = AddListItem("UTF_SetControls.ipf", list, ";", Inf)
	list = AddListItem("UTF_PatchSeqAccessResistanceSmoke.ipf", list, ";", Inf)
	list = AddListItem("UTF_PatchSeqChirp.ipf", list, ";", Inf)
	list = AddListItem("UTF_PatchSeqDAScale_Adapt.ipf", list, ";", Inf)
	list = AddListItem("UTF_PatchSeqDAScale_Sub.ipf", list, ";", Inf)
	list = AddListItem("UTF_PatchSeqDAScale_Supra.ipf", list, ";", Inf)
	list = AddListItem("UTF_PatchSeqSealEvaluation.ipf", list, ";", Inf)
	list = AddListItem("UTF_PatchSeqSquarePulse.ipf", list, ";", Inf)
	list = AddListItem("UTF_PatchSeqRheobase.ipf", list, ";", Inf)
	list = AddListItem("UTF_PatchSeqRamp.ipf", list, ";", Inf)
	list = AddListItem("UTF_PatchSeqPipetteInBath.ipf", list, ";", Inf)
	list = AddListItem("UTF_PatchSeqTrueRestingMembranePotential.ipf", list, ";", Inf)
	list = AddListItem("UTF_ReachTargetVoltage.ipf", list, ";", Inf)
	list = AddListItem("UTF_MultiPatchSeqFastRheoEstimate.ipf", list, ";", Inf)
	list = AddListItem("UTF_MultiPatchSeqDAScale.ipf", list, ";", Inf)
	list = AddListItem("UTF_MultiPatchSeqSpikeControl.ipf", list, ";", Inf)

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
