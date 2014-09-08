#pragma rtGlobals=3

/// @brief Return a wave reference to the channel <-> amplifier relation wave (numeric part)
///
/// Columns:
/// - Head stage number
///
/// Rows:
/// - 0-3: V-Clamp: DA channel number of amp (0 or 1), DA gain, AD channel, AD gain
/// - 4-7: I-Clamp: DA channel number of amp (0 or 1), DA gain, AD channel, AD gain
/// - 8: Amplifier Serial number as returned by `AxonTelegraphFindServers`. This differs
///      compared to the ones returned by `MCC_FindServers`, as the latter are strings with leading zeros.
///      E.g.: "00000123" vs 123
///      E.g.: "Demo"     vs 0
/// - 9: Amplifier Channel ID
/// - 10: Index into popup_Settings_Amplifier in the DA_Ephys panel
/// - 11: Unused
Function/Wave GetChanAmpAssign(panelTitle)
	string panelTitle

	DFREF dfr = HSU_GetDevicePathFromTitle(panelTitle)

	Wave/Z/SDFR=dfr wv = ChanAmpAssign

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(12,8) dfr:ChanAmpAssign/Wave=wv
	wv = NaN

	return wv
End

/// @brief Return a wave reference to the channel <-> amplifier relation wave (textual part)
///
/// Columns:
/// - Head stage number
///
/// Rows:
/// - 0: DA unit (V-Clamp mode)
/// - 1: AD unit (V-Clamp mode)
/// - 3: DA unit (I-Clamp mode)
/// - 4: AD unit (I-Clamp mode)
Function/Wave GetChanAmpAssignUnit(panelTitle)
	string panelTitle

	DFREF dfr = HSU_GetDevicePathFromTitle(panelTitle)

	Wave/T/Z/SDFR=dfr wv = ChanAmpAssignUnit

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(4,8) dfr:ChanAmpAssignUnit/Wave=wv
	wv = ""

	return wv
End

/// @brief Return a wave reference to the channel clamp mode wave
///
/// Columns:
/// - 0: DAC channels
/// - 1: ADC channels
///
/// Rows:
/// - Channel numbers
///
/// Contents:
/// - Clamp mode: One of V_CLAMP_MODE, I_CLAMP_MODE and I_EQUAL_ZERO_MODE
Function/Wave GetChannelClampMode(panelTitle)
	string panelTitle

	DFREF dfr = HSU_GetDevicePathFromTitle(panelTitle)

	Wave/Z/SDFR=dfr wv = ChannelClampMode

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(16,2) dfr:ChannelClampMode/Wave=wv

	SetDimLabel COLS, 0, DAC, wv
	SetDimLabel COLS, 1, ADC, wv

	return wv
End

/// @brief Returns a wave reference to the SweepData
///
/// SweepData is used to store GUI configuration info which can then be transferred into the documenting functions
/// Columns:
/// - 0: DAC
/// - 1: ADC
/// - 2: DA Gain
/// - 3: AD Gain
/// - 4: DA Scale
/// - 5: Set sweep count 
///
/// Rows:
/// - Only one
///
/// Layers:
/// - Headstage
Function/Wave DC_SweepDataWvRef(panelTitle)
	string panelTitle
	
	DFREF dfr = HSU_GetDevicePathFromTitle(panelTitle)

	Wave/Z/SDFR=dfr wv = SweepData

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(1, 6, 8) dfr:SweepData/Wave=wv
	wv = NaN

	return wv
End

/// @brief Returns a wave reference to the SweepTxtData
///
/// SweepTxtData is used to store the set name used on a particular headstage
/// Columns:
/// - 0: SetName
///
/// Rows:
/// - Only one
///
/// Layers:
/// - Headstage
Function/Wave DC_SweepDataTxtWvRef(panelTitle)
	string panelTitle
	
	DFREF dfr = HSU_GetDevicePathFromTitle(panelTitle)

	Wave/Z/T/SDFR=dfr wv = SweepTxtData

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(1,1,8) dfr:SweepTxtData/Wave=wv
	wv = ""

	return wv
End