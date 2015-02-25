#pragma rtGlobals=3

/// @brief Extracts the date/time column of the settingsHistory wave
///
/// This is useful if you want to plot values against the time and let
/// Igor do the formatting of the date/time values
Function/WAVE GetSettingsHistoryDateTime(settingsHistory)
	WAVE settingsHistory

	DFREF dfr = GetWavesDataFolderDFR(settingsHistory)
	WAVE/Z/SDFR=dfr settingsHistoryDat

	if(!WaveExists(settingsHistoryDat))
		Duplicate/R=[0, DimSize(settingsHistory, ROWS)][1][-1][-1] settingsHistory, dfr:settingsHistoryDat/Wave=settingsHistoryDat
		// we want to have a pure 1D wave without any columns or layers, this is currently not possible with Duplicate
		Redimension/N=-1 settingsHistoryDat
		// redimension has the odd behaviour to change a wave with zero rows to one with 1 row and then initializes that point to zero
		// we need to fix that
		if(DimSize(settingsHistoryDat, ROWS) == 1)
			settingsHistoryDat = NaN
		endif
		SetScale d, 0, 0, "dat" settingsHistoryDat
		SetDimLabel ROWS, -1, TimeStamp, settingsHistoryDat
	endif

	return settingsHistoryDat
End

/// @brief Returns a list of all active DA channels
/// @todo change function to return a numeric wave of variable length
/// and merge with GetADCListFromConfig
Function/S GetDACListFromConfig(ITCChanConfigWave)
	Wave ITCChanConfigWave

	return RefToPullDatafrom2DWave(1, 0, 1, ITCChanConfigWave)
End

/// @brief Returns a list of all active AD channels
Function/S GetADCListFromConfig(ITCChanConfigWave)
	Wave ITCChanConfigWave

	return RefToPullDatafrom2DWave(0, 0, 1, ITCChanConfigWave)
End

/// @brief Returns the data from the data column based on matched values in the ref column
///
/// For ITCDataWave 0 (value) in Ref column = AD channel, 1 = DA channel
static Function/s RefToPullDatafrom2DWave(refValue, refColumn, dataColumn, twoDWave)
	wave twoDWave
	variable refValue, refColumn, dataColumn

	variable i, numRows
	string list = ""

	numRows = DimSize(twoDWave, ROWS)
	for(i = 0; i < numRows; i += 1)
		if(TwoDwave[i][refColumn] == refValue)
			list = AddListItem(num2str(TwoDwave[i][DataColumn]), list, ";", i)
		endif
	endfor

	return list
End

/// @brief Returns the name of a control from the DA_EPHYS panel
///
/// Constants are defined at @ref ChannelTypeAndControlConstants
Function/S GetPanelControl(panelTitle, idx, channelType, controlType)
	string panelTitle
	variable idx, channelType, controlType

	string ctrl

	if(channelType == CHANNEL_TYPE_DAC)
		ctrl = "DA"
	elseif(channelType == CHANNEL_TYPE_ADC)
		ctrl = "AD"
	elseif(channelType == CHANNEL_TYPE_TTL)
		ctrl = "TTL"
	else
		ASSERT(0, "Invalid channelType")
	endif

	if(controlType == CHANNEL_CONTROL_WAVE)
		ctrl = "Wave_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_INDEX_END)
		ctrl = "Popup_" + ctrl + "_IndexEnd"
	elseif(controlType == CHANNEL_CONTROL_UNIT)
		ctrl = "Unit_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_GAIN)
		ctrl = "Gain_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_SCALE)
		ctrl = "Scale_" + ctrl
	elseif(controlType == CHANNEL_CONTROL_CHECK)
		ctrl = "Check_" + ctrl
	else
		ASSERT(0, "Invalid controlType")
	endif

	ASSERT(idx >= 0 && idx < 100, "invalid idx")
	sprintf ctrl, "%s_%02d", ctrl, idx

	return ctrl
End
