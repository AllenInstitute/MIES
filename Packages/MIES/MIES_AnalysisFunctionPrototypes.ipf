#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_AFP
#endif

/// @file MIES_AnalysisFunctionPrototypes.ipf
/// @brief __AFP__ Analysis functions prototypes to be called during data acquisition
///
/// @sa MIES_AnalysisFunctions.ipf

/// @deprecated Use AFP_ANALYSIS_FUNC_V3() instead
///
/// @param device  device
/// @param eventType   eventType, one of @ref EVENT_TYPE_ANALYSIS_FUNCTIONS,
///                    always compare `eventType` with the constants, never use the current numerical value directly
/// @param DAQDataWave data wave (locked to prevent changes using `SetWaveLock`)
/// @param headStage   active headstage index
///
/// @return ignored
Function AFP_ANALYSIS_FUNC_V1(string device, variable eventType, WAVE DAQDataWave, variable headStage)

	ASSERT(0, "Prototype function which must not be called")
End

/// @deprecated Use AFP_ANALYSIS_FUNC_V3() instead
///
/// @param device     device
/// @param eventType      eventType, one of @ref EVENT_TYPE_ANALYSIS_FUNCTIONS,
///                       always compare `eventType` with the constants, never use the current numerical value directly
/// @param DAQDataWave    data wave (locked to prevent changes using `SetWaveLock`)
/// @param headStage      active headstage index
/// @param realDataLength number of rows in `DAQDataWave` with data, the total number of rows in `DAQDataWave` might be
///                       higher due to alignment requirements of the data acquisition hardware. `NaN` for #PRE_DAQ_EVENT events.
///
/// @return see @ref AnalysisFunction_V3DescriptionTable
Function AFP_ANALYSIS_FUNC_V2(string device, variable eventType, WAVE DAQDataWave, variable headStage, variable realDataLength)

	ASSERT(0, "Prototype function which must not be called")
End

/// @param device device
/// @param s          analysis event structure
///
/// @return see @ref AnalysisFunction_V3DescriptionTable
Function AFP_ANALYSIS_FUNC_V3(string device, STRUCT AnalysisFunction_V3 &s)

	ASSERT(0, "Prototype function which must not be called")
End

/// @brief Prototype function for the user supplied parameter getter functions
///
Function/S AFP_PARAM_GETTER_V3()

	ASSERT(0, "Prototype function which must not be called")
End

/// @brief Prototype function for the user supplied parameter help functions
///
Function/S AFP_PARAM_HELP_GETTER_V3(string name)

	ASSERT(0, "Prototype function which must not be called")
End

/// @brief Prototype function for the user supplied parameter check function (legacy signature)
///
Function/S AFP_PARAM_CHECK_V1(string name, string params)

	ASSERT(0, "Prototype function which must not be called")
End

/// @brief Prototype function for the user supplied parameter check function
///
Function/S AFP_PARAM_CHECK_V2(string name, STRUCT CheckParametersStruct &s)

	ASSERT(0, "Prototype function which must not be called")
End
