#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_ASD
#endif // AUTOMATED_TESTING

/// @file MIES_AsynchronousData.ipf
/// @brief __ASD__ Support functions for the asynchronous channels

/// @brief Check if the given asynchronous channel is in alarm state
Function ASD_CheckAsynAlarmState(string device, variable value, variable minValue, variable maxValue)

	if(TestOverrideActive())
		WAVE overrideResults = GetOverrideResults()
		NVAR count           = $GetCount(device)

		return !overrideResults[0][count][%AsyncQC]
	endif

	return IsNaN(value) || value >= maxValue || value <= minValue
End

/// @brief Read the given asynchronous channel and return the scaled value
///        It is only valid to call for ITC and SUTTER when there is no acquisition running.
Function ASD_ReadChannel(string device, variable channel)

	string ctrl
	variable gain, deviceChannelOffset, rawChannelValue, hardwareType

	NVAR deviceID = $GetDAQDeviceID(device)
	deviceChannelOffset = HW_ITC_CalculateDevChannelOff(device)

	hardwareType    = GetHardwareType(device)
	rawChannelValue = HW_ReadADC(hardwareType, deviceID, channel + deviceChannelOffset)

	ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN)
	gain = DAG_GetNumericalValue(device, ctrl, index = channel)

#ifdef REPLAY_DATA
	if(ROvar(GetReplayDataEnable()))
		WAVE/Z replaySettings = RD_GetReplaySettings(device, RD_MODE_ALWAYS, RD_SWEEP_SELECTOR_CURRENT)

		return replaySettings[%$("AsyncAD" + num2str(channel))]
	endif
#endif // REPLAY_DATA

	return rawChannelValue / gain
End
