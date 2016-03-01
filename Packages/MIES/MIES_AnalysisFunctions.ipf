#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_AnalysisFunctions.ipf
/// @brief __AF__ Analysis functions to be called during data acquisition
///
/// Function prototypes for analysis functions
///
/// Users can implement functions which are called at certain events for each
/// data acquisition cycle. These functions should *never* abort, error out with a runtime error, or open dialogs!
///
/// Useful helper functions are defined in MIES_AnalysisFunctionHelpers.ipf.
///
/// @anchor AnalysisFunctionEventDescriptionTable
///
/// Event      | Description                          | Analysis function return value            | Specialities
/// -----------|--------------------------------------|-------------------------------------------|---------------------------------------------------------------
/// Pre DAQ    | Before any DAQ occurs                | Return 1 to *not* start data acquisition  | Called before the settings are validated
/// Mid Sweep  | Each time when new data is polled    | Ignored                                   | Available for background DAQ only
/// Post Sweep | After each sweep                     | Ignored                                   | None
/// Post Set   | After a *full* set has been acquired | Ignored                                   | This event is not always reached as the user might not acquire all steps of a set
/// Post DAQ   | After all DAQ has been finished      | Ignored                                   | None

/// @deprecated Use AF_PROTO_ANALYSIS_FUNC_V2() instead
///
/// @param panelTitle  device
/// @param eventType   eventType, one of @ref EVENT_TYPE_ANALYSIS_FUNCTIONS,
///                    always compare `eventType` with the constants, never use the current numerical value directly
/// @param ITCDataWave data wave (locked to prevent changes using `SetWaveLock`)
/// @param headStage   active headstage index
///
/// @return ignored
Function AF_PROTO_ANALYSIS_FUNC_V1(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage
End

/// @param panelTitle     device
/// @param eventType      eventType, one of @ref EVENT_TYPE_ANALYSIS_FUNCTIONS,
///                       always compare `eventType` with the constants, never use the current numerical value directly
/// @param ITCDataWave    data wave (locked to prevent changes using `SetWaveLock`)
/// @param headStage      active headstage index
/// @param realDataLength number of rows in `ITCDataWave` with data, the total number of rows in `ITCDataWave` might be
///                       higher due to alignment requirements of the data acquisition hardware
///
/// @return see @ref AnalysisFunctionEventDescriptionTable
Function AF_PROTO_ANALYSIS_FUNC_V2(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	// return value currently only honoured for `Pre DAQ` event
	return 0
End

Function TestAnalysisFunction_V1(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage

	printf "Analysis function version 1 called: device %s, eventType \"%s\", headstage %d\r", panelTitle, StringFromList(eventType, EVENT_NAME_LIST), headStage
	printf "Next sweep: %d\r", GetSetVariable(panelTitle, "SetVar_Sweep")
End

Function TestAnalysisFunction_V2(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	printf "Analysis function version 2 called: device %s, eventType \"%s\", headstage %d\r", panelTitle, StringFromList(eventType, EVENT_NAME_LIST), headStage
End

Function Enforce_VC(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	if(eventType != PRE_DAQ_EVENT)
	   return 0
	endif

	Wave GuiState = GetDA_EphysGuiStateNum(panelTitle)
	if(GuiState[headStage][%HSmode] != V_CLAMP_MODE)
		variable DAC = AFH_GetDACFromHeadstage(panelTitle, headstage)

		string stimSetName = AFH_GetStimSetName(paneltitle, DAC, CHANNEL_TYPE_DAC)
		printf "%s on DAC %d of headstage %d requires voltage clamp mode. Change clamp mode to voltage clamp to allow data acquistion\r" stimSetName, DAC, headStage
		return 1
	endif

	return 0
End

Function Enforce_IC(panelTitle, eventType, ITCDataWave, headStage, realDataLength)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage, realDataLength

	if(eventType != PRE_DAQ_EVENT)
	   return 0
	endif

	Wave GuiState = GetDA_EphysGuiStateNum(panelTitle)
	if(GuiState[headStage][%HSmode] != I_CLAMP_MODE)
		variable DAC = AFH_GetDACFromHeadstage(panelTitle, headstage)
		string stimSetName = AFH_GetStimSetName(paneltitle, DAC, CHANNEL_TYPE_DAC)
		printf "Stimulus set: %s on DAC: %d of headstage: %d requires current clamp mode. Change clamp mode to current clamp to allow data acquistion\r" stimSetName, DAC, headStage
		return 1
	endif

	return 0
End
