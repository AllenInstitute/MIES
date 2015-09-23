#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_AnalysisFunctions.ipf
/// @brief __AF__ Analysis functions to be called during data acquisition

/// @brief Function prototype for analysis functions
///
/// Users can implement functions which are called at certain events for each
/// data acquisition cycle. These functions should *never* abort, error out with a runtime error, or open dialogs!
///
/// Useful helper functions are defined in MIES_AnalysisFunctionHelpers.ipf.
///
/// Event      | Description                          | Specialities
/// -----------|--------------------------------------|---------------------------------------------------------------------------------
/// Pre DAQ    | Immediately before any DAQ occurs    | None
/// Mid Sweep  | Each time when new data is polled    | Available for background DAQ only
/// Post Sweep | After each sweep                     | None
/// Post Set   | After a *full* set has been acquired | This event is not always reached as the user might not acquire all steps of a set
/// Post DAQ   | After all DAQ has been finished      | None
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

Function TestAnalysisFunction_V1(panelTitle, eventType, ITCDataWave, headStage)
	string panelTitle
	variable eventType
	Wave ITCDataWave
	variable headstage

	printf "Analysis function version 1 called: device %s, eventType \"%s\", headstage %d\r", panelTitle, StringFromList(eventType, EVENT_NAME_LIST), headStage
	printf "Next sweep: %d\r", GetSetVariable(panelTitle, "SetVar_Sweep")
End
