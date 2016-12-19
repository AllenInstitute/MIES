#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_AnalysisFunctionPrototypes.ipf
/// @brief __AF__ Analysis functions prototypes to be called during data acquisition
///
/// @sa MIES_AnalysisFunctions.ipf

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
