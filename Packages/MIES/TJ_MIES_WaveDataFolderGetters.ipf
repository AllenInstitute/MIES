#pragma rtGlobals=3

/// @brief Return a wave reference to the channel <-> amplifier relation wave (numeric part)
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
///
/// Columns:
/// - Head stage number
///
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
/// Rows:
/// - 0: DA unit (V-Clamp mode)
/// - 1: AD unit (V-Clamp mode)
/// - 3: DA unit (I-Clamp mode)
/// - 4: AD unit (I-Clamp mode)
///
/// Columns:
/// - Head stage number
///
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
/// Rows:
/// - Channel numbers
///
/// Columns:
/// - 0: DAC channels
/// - 1: ADC channels
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
///
/// Rows:
/// - Only one
///
/// Columns:
/// - 0: DAC
/// - 1: ADC
/// - 2: DA Gain
/// - 3: AD Gain
/// - 4: DA Scale
/// - 5: Set sweep count 
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
/// Rows:
/// - Only one
///
/// Columns:
/// - 0: SetName
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

/// @brief Returns a wave reference to the textDocWave
///
/// textDocWave is used to save settings for each data sweep and create waveNotes for tagging data sweeps
/// Rows:
/// - Only one
///
/// Columns:
/// - 0: Sweep Number
/// - 1: Time Stamp
///
/// Layers:
/// - Headstage
Function/Wave DC_txtDocWvRef(panelTitle)
	string panelTitle
	
	DFREF dfr = DF_GetDevSpecLabNotebkTxtDoc(panelTitle)

	Wave/Z/T/SDFR=dfr wv = txtDocWave

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(1,2,0) dfr:txtDocWave/Wave=wv
	wv = ""

	return wv
End

/// @brief Returns a wave reference to the textDocKeyWave
///
/// textDocKeyWave is used to index save settings for each data sweep and create waveNotes for tagging data sweeps
///
/// Rows:
/// - 0: Parameter Name
///
/// Columns:
/// - 0: Sweep Number
/// - 1: Time Stamp
///
/// Layers:
/// - Headstage
Function/Wave DC_txtDocKeyWvRef(panelTitle)
	string panelTitle
	
	DFREF dfr = DF_GetDevSpecLabNotebkTxtDocKey(panelTitle)

	Wave/Z/T/SDFR=dfr wv = txtDocKeyWave

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(1,2,0) dfr:txtDocKeyWave/Wave=wv
	wv = ""

	return wv
End

/// @brief Returns a wave reference to the sweepSettingsWave
///
/// sweepSettingsWave is used to save stimulus settings for each data sweep and create waveNotes for tagging data sweeps
/// Rows:
///  One row
///
/// Columns:
/// 0: Stim Wave Name
/// 1: Stim Scale Factor
///
/// Layers:
/// - Headstage
Function/Wave DC_sweepSettingsWvRef(panelTitle, noHeadStages)
	string panelTitle
	variable noHeadStages
	
	DFREF dfr =  DF_GetDevSpecLabNotebkSttngs(panelTitle)

	Wave/Z/SDFR=dfr wv = sweepSettingsWave

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(1,6,noHeadStages) dfr:sweepSettingsWave/Wave=wv
	wv = Nan

	return wv
End

/// @brief Returns a wave reference to the sweepSettingsKeyWave
///
/// sweepSettingsKeyWave is used to index save stimulus settings for each data sweep and create waveNotes for tagging data sweeps
///
/// Rows:
/// 0: Parameter
/// 1: Units
/// 2: Tolerance Factor
///
/// Columns:
/// 0: Stim Scale Factor
/// 1: DAC
/// 2: ADC
/// 3: DA Gain
/// 4: AD Gain
/// 5: Set sweep count 
///
/// Layers:
/// - Headstage
Function/Wave DC_sweepSettingsKeyWvRef(panelTitle)
	string panelTitle
	
	DFREF dfr = DF_GetDevSpecLabNotebkSttngsKey(panelTitle)

	Wave/Z/T/SDFR=dfr wv = sweepSettingsKeyWave

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(3,6) dfr:sweepSettingsKeyWave/Wave=wv
	wv = ""

	return wv
End

/// @brief Returns a wave reference to the SweepSettingsTxtWave
///
/// SweepTxtData is used to store the set name used on a particular headstage and then create waveNotes for the sweep data
///
/// Rows:
/// - Only one
///
/// Columns:
/// - 0: SetName
///
/// Layers:
/// - Headstage
Function/Wave DC_SweepSettingsTxtWvRef(panelTitle, noHeadStages)
	string panelTitle
	variable noHeadStages
	
	DFREF dfr =DF_GetDevSpecLabNotebkTxtDoc(panelTitle)

	Wave/Z/T/SDFR=dfr wv = SweepSettingsTxtData

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(1,1,noHeadStages) dfr:SweepSettingsTxtData/Wave=wv
	wv = ""

	return wv
End

/// @brief Returns a wave reference to the SweepSettingsTxtKeyWave
///
/// SweepTxtKeyWave is used to index Txt Key Wave
///
/// Rows:
/// - Only one
///
/// Columns:
/// - 0: SetName
///
/// Layers:
/// - Headstage
Function/Wave DC_sweepSettingsTxtKyWvRef(panelTitle, noHeadStages)
	string panelTitle
	variable noHeadStages
	
	DFREF dfr =DF_GetDevSpecLabNotebkTxtDocKey(panelTitle)

	Wave/Z/T/SDFR=dfr wv = SweepSettingsKeyTxtData

	if(WaveExists(wv))
		return wv
	endif

	Make/T/N=(1,1,noHeadStages) dfr:SweepSettingsKeyTxtData/Wave=wv
	wv = ""

	return wv
End