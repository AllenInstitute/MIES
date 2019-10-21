#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DAG
#endif

/// @file MIES_DAEphys_GuiState.ipf
/// @brief __DAG__ Routines dealing with the DA_Ephys GUI state waves

/// @brief Records the state of the DA_ephys panel into the numerical GUI state wave
Function DAG_RecordGuiStateNum(panelTitle, [GUIState])
	string panelTitle
	WAVE GUIState

	variable i, numEntries
	string ctrlName, lbl

	if(ParamIsDefault(GuiState))
		Wave GUIState = GetDA_EphysGuiStateNum(panelTitle)
	endif

	WAVE state = DAG_ControlStatusWave(panelTitle, CHANNEL_TYPE_HEADSTAGE)
	lbl        = GetSpecialControlLabel(CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
	GUIState[0, NUM_HEADSTAGES - 1][%$lbl] = state[p]

	WAVE state = DAG_GetAllHSMode(panelTitle)
	GUIState[0, NUM_HEADSTAGES - 1][%HSMode] = state[p]

	WAVE state = DAG_ControlStatusWave(panelTitle, CHANNEL_TYPE_DAC)
	lbl        = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysSetVarNum(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
	lbl        = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysSetVarNum(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	lbl        = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysPopMenuIndex(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	lbl        = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysPopMenuIndex(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
	lbl        = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%$lbl] = state[p]

	WAVE state = DAG_ControlStatusWave(panelTitle, CHANNEL_TYPE_ADC)
	lbl        = GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK)
	GUIState[0, NUM_AD_CHANNELS - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysSetVarNum(panelTitle, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
	lbl        = GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
	GUIState[0, NUM_AD_CHANNELS - 1][%$lbl] = state[p]

	WAVE state = DAG_ControlStatusWave(panelTitle, CHANNEL_TYPE_TTL)
	lbl        = GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK)
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysPopMenuIndex(panelTitle, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
	lbl        = GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysPopMenuIndex(panelTitle, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
	lbl        = GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
	GUIState[0, NUM_DA_TTL_CHANNELS - 1][%$lbl] = state[p]

	WAVE state = DAG_ControlStatusWave(panelTitle, CHANNEL_TYPE_ASYNC)
	lbl        = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_CHECK)
	GUIState[0, NUM_ASYNC_CHANNELS - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysSetVarNum(panelTitle, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN)
	lbl        = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN)
	GUIState[0, NUM_ASYNC_CHANNELS - 1][%$lbl] = state[p]

	WAVE state = DAG_ControlStatusWave(panelTitle, CHANNEL_TYPE_ALARM)
	lbl        = GetSpecialControlLabel(CHANNEL_TYPE_ALARM, CHANNEL_CONTROL_CHECK)
	GUIState[0, NUM_ASYNC_CHANNELS - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysSetVarNum(panelTitle, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN)
	lbl        = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN)
	GUIState[0, NUM_ASYNC_CHANNELS - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysSetVarNum(panelTitle, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX)
	lbl        = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX)
	GUIState[0, NUM_ASYNC_CHANNELS - 1][%$lbl] = state[p]

	numEntries = DimSize(GUIState, COLS)
	for(i = COMMON_CONTROL_GROUP_COUNT_NUM; i < numEntries; i += 1)
		ctrlName = GetDimLabel(GUIState, COLS, i)
		controlInfo/w=$panelTitle $ctrlName
		ASSERT(V_flag != 0, "invalid or non existing control")

		if(abs(V_Flag) == CONTROL_TYPE_POPUPMENU)
			V_Value -= 1
		endif

		GUIState[0][i] = V_Value
	endfor
End

/// @brief Records the state of the DA_ephys panel into the textual GUI state wave
Function DAG_RecordGuiStateTxT(panelTitle, [GUIState])
	string panelTitle
	WAVE GUIState

	variable i, numEntries
	string ctrlName, lbl

	if(ParamIsDefault(GuiState))
		Wave/T GUIStateTxT = GetDA_EphysGuiStateTxT(panelTitle)
	else
		WAVE/T GUIStateTxT = GUIState
	endif

	WAVE/T state = GetAllDAEphysPopMenuString(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	lbl          = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	GUIStateTxT[0, NUM_DA_TTL_CHANNELS - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysPopMenuString(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
	lbl          = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
	GUIStateTxT[0, NUM_DA_TTL_CHANNELS - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysSetVarTxT(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
	lbl          = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
	GUIStateTxT[0, NUM_DA_TTL_CHANNELS - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysSetVarTxT(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SEARCH)
	lbl          = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SEARCH)
	GUIStateTxT[0, NUM_DA_TTL_CHANNELS - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysSetVarTxT(panelTitle, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
	lbl          = GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
	GUIStateTxT[0, NUM_AD_CHANNELS - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysPopMenuString(panelTitle, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
	lbl          = GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
	GUIStateTxT[0, NUM_DA_TTL_CHANNELS - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysPopMenuString(panelTitle, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
	lbl          = GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
	GUIStateTxT[0, NUM_DA_TTL_CHANNELS - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysSetVarTxT(panelTitle, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_SEARCH)
	lbl          = GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_SEARCH)
	GUIStateTxT[0, NUM_DA_TTL_CHANNELS - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysSetVarTxT(panelTitle, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_TITLE)
	lbl          = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_TITLE)
	GUIStateTxT[0, NUM_ASYNC_CHANNELS - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysSetVarTxT(panelTitle, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_UNIT)
	lbl          = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_UNIT)
	GUIStateTxT[0, NUM_ASYNC_CHANNELS - 1][%$lbl] = state[p]

	numEntries = DimSize(GUIStateTxT, COLS)
	for(i = COMMON_CONTROL_GROUP_COUNT_TXT; i < numEntries; i += 1)
		ctrlName = GetDimLabel(GUIStateTxT, COLS, i)
		controlInfo/w=$panelTitle $ctrlName
		ASSERT(V_flag != 0, "invalid or non existing control")
		GUIStateTxT[0][i] = S_Value
	endfor
End

/// @brief Query a control value from the numerical gui state wave
///
/// Convienience wrapper to make the call sites nicer.
///
/// @param panelTitle device
/// @param ctrl       control name
/// @param index      [optional, default to NaN] Some control entries have multiple
///                   entries per headstage/channel/etc.
Function DAG_GetNumericalValue(panelTitle, ctrl, [index])
	string panelTitle, ctrl
	variable index

	variable refValue, waveIndex
	string msg

	if(ParamIsDefault(index) || IsNaN(index))
		waveIndex = 0
		index = NaN
	else
		waveIndex = index
	endif

#if defined(AUTOMATED_TESTING) || defined(DEBUGGING_ENABLED)

	// check if the GUI state wave is consistent
	if(defined(AUTOMATED_TESTING) || DP_DebuggingEnabledForFile(GetFile(FunctionPath(""))))
		ControlInfo/W=$panelTitle $ctrl

		if(!IsFinite(index))
			ControlInfo/W=$panelTitle $ctrl
		else
			string fullCtrl
			sprintf fullCtrl, "%s_%02d", ctrl, index
			ControlInfo/W=$panelTitle $fullCtrl
		endif

		if(abs(V_Flag) == CONTROL_TYPE_POPUPMENU)
			V_Value -= 1
		endif

		refValue = GetDA_EphysGuiStateNum(panelTitle)[waveIndex][%$ctrl]

		if(!CheckIfClose(V_Value, refValue) && !(V_Value == 0 && refValue == 0))
			sprintf msg, "Numeric GUI state wave is inconsistent for %s: %g vs. %g\r", ctrl, V_Value, refValue
			BUG(msg)
		endif
	endif
#endif

	return GetDA_EphysGuiStateNum(panelTitle)[waveIndex][%$ctrl]
End

/// @brief Query a control value from the textual gui state wave
///
/// Convienience wrapper to make the call sites nicer.
///
/// @param panelTitle device
/// @param ctrl       control name
/// @param index      [optional, default to NaN] Some control entries have multiple
///                   entries per headstage/channel/etc.
Function/S DAG_GetTextualValue(panelTitle, ctrl, [index])
	string panelTitle, ctrl
	variable index

	string str, msg
	variable waveIndex

	if(ParamIsDefault(index) || IsNaN(index))
		waveIndex = 0
		index = NaN
	else
		waveIndex = index
	endif

	WAVE/T GUIState = GetDA_EphysGuiStateTxT(panelTitle)

#if defined(AUTOMATED_TESTING) || defined(DEBUGGING_ENABLED)

	// check if the GUI state wave is consistent
	if(defined(AUTOMATED_TESTING) || DP_DebuggingEnabledForFile(GetFile(FunctionPath(""))))

		if(!IsFinite(index))
			ControlInfo/W=$panelTitle $ctrl
		else
			string fullCtrl
			sprintf fullCtrl, "%s_%02d", ctrl, index
			ControlInfo/W=$panelTitle $fullCtrl
		endif

		str = GUIState[waveIndex][%$ctrl]

		if(IsEmpty(S_Value) != IsEmpty(str) || cmpstr(S_Value, str))
			sprintf msg, "Textual GUI state wave is inconsistent for %s: %s vs. %s\r", ctrl, SelectString(IsNull(S_Value), S_Value, "<null>"), GUIState[index][%$ctrl]
			BUG(msg)
		endif
	endif
#endif

	return GUIState[waveIndex][%$ctrl]
End

/// @brief Return a free wave of the status of the checkboxes specified by
///        channelType, uses GetDA_EphysGuiStateNum() instead of GUI queries.
///
/// @param type        one of the type constants from @ref ChannelTypeAndControlConstants
/// @param panelTitle  panel title
Function/Wave DAG_GetChannelState(panelTitle, type)
	string panelTitle
	variable type

	variable numEntries, col

	WAVE GUIState = GetDA_EphysGuiStateNum(panelTitle)

	numEntries = GetNumberFromType(var=type)

	switch(type)
		case CHANNEL_TYPE_ASYNC:
			col = 12
			break
		case CHANNEL_TYPE_ALARM:
			col = 14
			break
		case CHANNEL_TYPE_TTL:
			col = 9
			break
		case CHANNEL_TYPE_DAC:
			col = 2
			break
		case CHANNEL_TYPE_HEADSTAGE:
			col = 0
			break
		case CHANNEL_TYPE_ADC:
			col = 7
			break
		default:
			ASSERT(0, "invalid type")
			break
	endswitch

	Make/FREE/D/N=(numEntries) wv = GUIState[p][col]

	return wv
End

/// @brief Return a free wave of the popup menu strings specified by
///        channelType, uses GetDA_EphysGuiStateTxT() instead of GUI queries.
///
/// @param panelTitle  panel title
/// @param channelType one of the channel type constants from @ref ChannelTypeAndControlConstants
/// @param controlType one of the control type constants from @ref ChannelTypeAndControlConstants
Function/Wave DAG_GetChannelTextual(panelTitle, channelType, controlType)
	string panelTitle
	variable channelType, controlType

	variable numEntries

	WAVE/T GUIState = GetDA_EphysGuiStateTxT(panelTitle)

	numEntries = GetNumberFromType(var=channelType)

	Make/FREE/T/N=(numEntries) wv = GUIState[p][%$GetSpecialControlLabel(channelType, controlType)]

	return wv
End

/// @brief Returns the headstage State
Function DAG_GetHeadstageState(panelTitle, headStage)
	string panelTitle
	variable headStage

	WAVE wv = GetDA_EphysGuiStateNum(panelTitle)
	return wv[headStage][%$GetSpecialControlLabel(CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)]
End

/// @returns the mode of the headstage defined in the locked DA_ephys panel,
///          can be V_CLAMP_MODE or I_CLAMP_MODE or NC
Function DAG_GetHeadstageMode(panelTitle, headStage)
	string panelTitle
	variable headStage  // range: [0, NUM_HEADSTAGES[

	return GetDA_EphysGuiStateNum(panelTitle)[headStage][%HSMode]
End

/// @brief Updates the state of a control in the GUIState numeric wave
///
/// One or both parameters have to be passed.
///
/// @param panelTitle  device
/// @param controlName control name
/// @param val         [optional] numerical value, 0-based index for popup menues
/// @param str         [optional] textual value
Function DAG_Update(panelTitle, controlName, [val, str])
	string panelTitle
	string controlName
	variable val
	string str

	variable col, channelIndex, channelType, controlType

	ASSERT(ParamIsDefault(val) + ParamIsDefault(str) < 2, "One or both of `val` and `str` must be passed.")

	if(!ParamIsDefault(val))
		WAVE GUIState = GetDA_EphysGuiStateNum(panelTitle)
		col = FindDimLabel(GUIState, COLS, controlName)
		if(col != -2)
			GUIState[0][col] = val
		elseif(!DAP_ParsePanelControl(controlName, channelIndex, channelType, controlType))
			col = FindDimLabel(GUIState, COLS, GetSpecialControlLabel(channelType, controlType))
			if(col != -2)
				GuiState[channelIndex][col] = val
			endif
		endif
	endif

	WaveClear GuiState

	if(!ParamIsDefault(str))
		WAVE/T GUIStateTxT = GetDA_EphysGuiStateTxT(panelTitle)
		col = FindDimLabel(GUIStateTxT, COLS, controlName)
		if(col != -2)
			GUIStateTxT[0][col] = str
		elseif(!DAP_ParsePanelControl(controlName, channelIndex, channelType, controlType))
			col = FindDimLabel(GUIStateTxT, COLS, GetSpecialControlLabel(channelType, controlType))
			if(col != -2)
				GuiStateTxT[channelIndex][col] = str
			endif
		endif
	endif
End

/// @brief Returns a list of unique and type specific controls
///
Function/S DAG_GetUniqueSpecCtrlListNum(panelTitle)
	string panelTitle

	return DAG_GetSpecificCtrlNum(panelTitle, DAG_GetUniqueCtrlList(panelTitle))
End

/// @brief Returns a list of unique and type specific controls with textual values
Function/S DAG_GetUniqueSpecCtrlListTxT(panelTitle)
	string panelTitle

	return DAG_GetSpecificCtrlTxT(panelTitle, DAG_GetUniqueCtrlList(panelTitle))
End

/// @brief Returns a free wave of the status of the checkboxes specified by channelType
///
/// The only caller should be DAG_RecordGuiStateNum().
///
/// @param type        one of the type constants from @ref ChannelTypeAndControlConstants
/// @param panelTitle  panel title
static Function/Wave DAG_ControlStatusWave(panelTitle, type)
	string panelTitle
	variable type

	string ctrl
	variable i, numEntries

	numEntries = GetNumberFromType(var=type)

	Make/FREE/U/B/N=(numEntries) wv

	for(i = 0; i < numEntries; i += 1)
		ctrl = GetPanelControl(i, type, CHANNEL_CONTROL_CHECK)
		wv[i] = GetCheckBoxState(panelTitle, ctrl)
	endfor

	return wv
End

/// @brief Return the mode of all DA_Ephys panel headstages
///
/// All callers, except the ones updating the GUIState wave,
/// should prefer DAG_GetHeadstageMode() instead.
static Function/Wave DAG_GetAllHSMode(panelTitle)
	string panelTitle

	variable i, headStage, clampMode
	string ctrl

	Make/FREE/N=(NUM_HEADSTAGES) Mode
	for(i = 0; i < NUM_HEADSTAGES; i+=1)
		ctrl = GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
		DAP_GetInfoFromControl(panelTitle, ctrl, clampMode, headStage)
		ASSERT(headStage == i, "Unexpected value")
		Mode[i] = clampMode
	endfor

	return Mode
End

/// @brief Parses a list of controls in the panelTitle and returns a list of unique controls
static Function/S DAG_GetUniqueCtrlList(paneltitle)
	string panelTitle

	string prunedList = ""
	string list, ctrlToRemove, ctrl
	variable i, channelIndex, channelType, controlType, numEntries

	list = ControlNameList(panelTitle)

	// remove special controls (1)
	ctrlToRemove = "Radio_ClampMode_*;ValDisp_DataAcq_P_*"
	numEntries = ItemsInlist(ctrlToRemove)
	for(i = 0; i < numEntries ; i += 1)
		prunedList = ListMatch(list, StringFromList(i, ctrlToRemove))
		list = RemoveFromList(prunedList, list)
	endfor

	// remove special controls (2)
	numEntries = ItemsInlist(list)
	for(i = 0;i < numEntries ;i += 1)
		ctrl = StringFromList(i, list)
		if(!DAP_ParsePanelControl(ctrl,  channelIndex, channelType, controlType) && channelIndex >= 0)
			// special control already handled, but only for non-All controls
			continue
		endif
		prunedList = AddListItem(ctrl, prunedList, ";", inf)
	endfor

	// remove controls which are too complicated to handle
	ctrlToRemove = "Popup_Settings_HeadStage;popup_Settings_Amplifier;Popup_Settings_VC_DA;setvar_Settings_VC_DAgain;SetVar_Hardware_VC_DA_Unit;Popup_Settings_VC_AD;setvar_Settings_VC_ADgain;SetVar_Hardware_VC_AD_Unit;Popup_Settings_IC_DA;setvar_Settings_IC_DAgain;SetVar_Hardware_IC_DA_Unit;Popup_Settings_IC_AD;setvar_Settings_IC_ADgain;SetVar_Hardware_IC_AD_Unit;popup_Settings_Pressure_dev;Popup_Settings_Pressure_DA;Popup_Settings_Pressure_AD;setvar_Settings_Pressure_DAgain;setvar_Settings_Pressure_ADgain;SetVar_Hardware_Pressur_DA_Unit;SetVar_Hardware_Pressur_AD_Unit;Popup_Settings_Pressure_TTLA;Popup_Settings_Pressure_TTLB"

	prunedList = RemoveFromList(ctrlToRemove, prunedList)

	return prunedList
End

/// @brief Parses a list of controls and returns numeric checkBox, valDisplay, setVariable, popUpMenu, and slider controls
static Function/S DAG_GetSpecificCtrlNum(panelTitle, list)
	string panelTitle
	string list

	string subtypeCtrlList = ""
	variable i, numEntries
	string controlName

	numEntries = itemsinlist(list)
	for(i = 0; i < numEntries; i += 1)
		controlName = StringFromList(i, list)
		controlInfo/W=$panelTitle $controlName
		switch(abs(V_flag))
			case CONTROL_TYPE_CHECKBOX:
			case CONTROL_TYPE_POPUPMENU:
			case CONTROL_TYPE_SLIDER: // fallthrough by design
				subtypeCtrlList = AddListItem(controlName, subtypeCtrlList)
				break
			case CONTROL_TYPE_VALDISPLAY:
			case CONTROL_TYPE_SETVARIABLE:  // fallthrough by design
				if(!DoesControlHaveInternalString(panelTitle, controlName))
					subtypeCtrlList = AddListItem(controlName, subtypeCtrlList)
				endif
				break
			default:
				// do nothing
				break
		endswitch
	endfor

	return subtypeCtrlList
End

/// @brief Parses a list of controls and returns textual valDisplay, setVariable and popUpMenu controls
static Function/S DAG_GetSpecificCtrlTxT(panelTitle, list)
	string panelTitle
	string list

	string subtypeCtrlList = ""
	variable i, numEntries
	string controlName

	numEntries = itemsinlist(list)
	for(i = 0; i < numEntries; i += 1)
		controlName = StringFromList(i, list)
		controlInfo/W=$panelTitle $controlName
		switch(abs(V_flag))
			case CONTROL_TYPE_POPUPMENU:
				subtypeCtrlList = AddListItem(controlName, subtypeCtrlList)
				break
			case CONTROL_TYPE_VALDISPLAY:
			case CONTROL_TYPE_SETVARIABLE:  // fallthrough by design
				if(DoesControlHaveInternalString(panelTitle, controlName))
					subtypeCtrlList = AddListItem(controlName, subtypeCtrlList)
				endif
				break
			default:
				// do nothing
				break
		endswitch
	endfor

	return subtypeCtrlList
End
