#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_AnalysisFunctionHelpers.ipf
/// @brief __AFH__ Helper functions for analysis function writers
///
/// Additionally the following functions might be useful
///
/// Function                      | Return value
/// ------------------------------|------------------------------------------------------
/// GetADCListFromConfig()        | Free wave with all active AD channels as entries
/// GetDACListFromConfig()        | Free wave with all active DA channels as entries
/// GetLBNumericalValues()        | Wave reference to the labnotebook (numerical version)
/// GetLBTextualValues()          | Wave reference to the labnotebook (textual version)
/// GetLastSetting()              | Last documented numerical value for headstages of a specific setting in the labnotebook for a given sweep number.
/// GetLastSettingText()          | Last documented textual value for headstages of a specific setting in the labnotebook for a given sweep number.
/// GetLastSweepWithSetting()     | Last documented numerical value for headstages of a specific setting in the labnotebook and the sweep number it was set last.
/// GetLastSweepWithSettingText() | Last documented textual value for headstages of a specific setting in the labnotebook and the sweep number it was set last.

/// @brief Return the headstage the AD channel is assigned to
///
/// @param panelTitle device
/// @param AD         AD channel in the range [0,8[ or [0,16[
///                   depending on the hardware
///
/// @return headstage or NaN (for non-associated channels)
Function AFH_GetHeadstageFromADC(panelTitle, AD)
	string panelTitle
	variable AD

	variable i, row, entries

	WAVE ChanAmpAssign = GetChanAmpAssign(panelTitle)
	WAVE ChannelClampMode = GetChannelClampMode(panelTitle)

	entries = DimSize(ChanAmpAssign, COLS)
	row = ChannelClampMode[AD][%ADC] == V_CLAMP_MODE ? 2 : 2 + 4
	for(i = 0; i < entries; i += 1)
		if(chanAmpAssign[row][i] == AD)
			return i
		endif
	endfor

	return NaN
End

/// @brief Return the headstage the DA channel is assigned to
///
/// @param panelTitle device
/// @param DA         DA channel in the range [0,4[ or [0,8[
///                   depending on the hardware
///
/// @return headstage or NaN (for non-associated channels)
Function AFH_GetHeadstageFromDAC(panelTitle, DA)
	string 	panelTitle
	variable DA

	variable i, row, entries

	WAVE ChanAmpAssign = GetChanAmpAssign(panelTitle)
	WAVE channelClampMode = GetChannelClampMode(panelTitle)

	entries = DimSize(chanAmpAssign, COLS)
	row = channelClampMode[DA][%DAC] == V_CLAMP_MODE ? 0 : 0 + 4

	for(i = 0; i < entries; i += 1)
		if(chanAmpAssign[row][i] == DA)
			return i
		endif
	endfor

	return NaN
End

/// @brief Return the AD channel assigned to the headstage
///
/// @param panelTitle device
/// @param headstage  headstage in the range [0,8[
///
/// @return AD channel or NaN (for non-associated channels)
Function AFH_GetADCFromHeadstage(panelTitle, headstage)
	string panelTitle
	variable headstage

	variable i, retHeadstage

	for(i = 0; i < NUM_AD_CHANNELS; i += 1)
		retHeadstage = AFH_GetHeadstageFromADC(panelTitle, i)
		if(isFinite(retHeadstage) && retHeadstage == headstage)
			return i
		endif
	endfor

	return NaN
End

/// @brief Return the DA channel assigned to the headstage
///
/// @param panelTitle device
/// @param headstage  headstage in the range [0,8[
///
/// @return DA channel or NaN (for non-associated channels)
Function AFH_GetDACFromHeadstage(panelTitle, headstage)
	string panelTitle
	variable headstage

	variable i, retHeadstage

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		retHeadstage = AFH_GetHeadstageFromDAC(panelTitle, i)
		if(isFinite(retHeadstage) && retHeadstage == headstage)
			return i
		endif
	endfor

	return NaN
End

/// @brief Return the column index into `ITCDataWave` for the given channel/type
///        combination
///
/// @param ITCChanConfigWave ITC configuration wave, most users need to call
///                          `GetITCChanConfigWave(panelTitle)` to get that wave.
/// @param channelNumber     channel number (0-based)
/// @param channelType       channel type, one of @ref ITC_XOP_CHANNEL_CONSTANTS
Function AFH_GetITCDataColumn(ITCChanConfigWave, channelNumber, channelType)
	WAVE ITCChanConfigWave
	variable channelNumber, channelType

	variable numRows, i

	ASSERT(IsFinite(channelNumber), "Non-finite channel number")

	numRows = DimSize(ITCChanConfigWave, ROWS)
	for(i = 0; i < numRows; i += 1)

		if(channelType != ITCChanConfigWave[i][0])
			continue
		endif

		if(channelNumber != ITCChanConfigWave[i][1])
			continue
		endif

		return i
	endfor

	DEBUGPRINT("Could not find the column")
	DEBUGPRINT("Channel number", var = channelNumber)
	DEBUGPRINT("Channel type", var = channelType)

	return NaN
End

/// @brief Return the sweep number of the last acquired sweep
///
/// Handles sweep number rollback properly.
///
/// @return a non-negative integer sweep number or NaN if there is no data
Function AFH_GetLastSweepAcquired(panelTitle)
	string panelTitle

	string list, name
	variable numItems, i, sweep

	list = GetListOfWaves(GetDeviceDataPath(panelTitle), DATA_SWEEP_REGEXP, waveProperty="MINCOLS:2")
	list = SortList(list, ";", 1 + 16) // descending and case-insensitive alphanumeric

	numItems = ItemsInList(list)
	for(i = 0; i < numItems; i += 1)
		name = StringFromList(i, list)
		sweep = ExtractSweepNumber(name)

		if(WaveExists(GetSweepWave(panelTitle, sweep)))
			return sweep
		endif
	endfor

	return NaN
End

/// @brief Return the sweep wave of the last acquired sweep
///
/// @return an existing sweep wave or an invalid wave reference if there is no data
Function/WAVE AFH_GetLastSweepWaveAcquired(panelTitle)
	string panelTitle

	return GetSweepWave(panelTitle, AFH_GetLastSweepAcquired(panelTitle))
End

/// @brief Return the stimset for the given DA channel
///
/// @param panelTitle device
/// @param chanNo	channel number (0-based)
/// @param channelType		one of the type constants from @ref ChannelTypeAndControlConstants
/// @return an existing stimulus set name for a DA channel
Function/S AFH_GetStimSetName(panelTitle, chanNo, channelType)
	string panelTitle
	variable chanNo
	variable channelType

	string ctrl, stimset
	ctrl = GetPanelControl(chanNo, channelType, CHANNEL_CONTROL_WAVE)
	ControlInfo/W=$panelTitle $ctrl
	stimset = S_Value

	ASSERT(!isEmpty(stimset), "Empty stimset")

	return stimset
End
