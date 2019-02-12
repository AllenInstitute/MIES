#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_ASD
#endif

/// @file MIES_AsynchronousData.ipf
/// @brief __ASD__ Support functions for the asynchronous channels

/// @brief Check if the given asynchronous channel is in alarm state
///
/// @return true if in alarm state, false if not in alarm state or not enabled.
Function ASD_CheckAsynAlarmState(panelTitle, channel, value)
	string panelTitle
	variable channel, value

	string minCtrl, maxCtrl, checkCtrl
	variable paramMin, paramMax

	checkCtrl = GetSpecialControlLabel(CHANNEL_TYPE_ALARM, CHANNEL_CONTROL_CHECK)

	if(!DAG_GetNumericalValue(panelTitle, checkCtrl, index = channel))
		return 0
	endif

	minCtrl   = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN)
	maxCtrl   = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX)
	paramMin = DAG_GetNumericalValue(panelTitle, minCtrl, index = channel)
	paramMax = DAG_GetNumericalValue(panelTitle, maxCtrl, index = channel)

	return value >= ParamMax || value <= ParamMin
End

/// @brief Read the given asynchronous channel and return the scaled value
Function ASD_ReadChannel(panelTitle, channel)
	string panelTitle
	variable channel

	string ctrl
	variable gain, deviceChannelOffset, rawChannelValue

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	deviceChannelOffset = HW_ITC_CalculateDevChannelOff(panelTitle)

	rawChannelValue = HW_ReadADC(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, channel + deviceChannelOffset)

	ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN)
	gain = DAG_GetNumericalValue(panelTitle, ctrl, index = channel)

	return rawChannelValue / gain
End
