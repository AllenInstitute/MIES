#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_DAG
#endif // AUTOMATED_TESTING

/// @file MIES_DAEphys_GuiState.ipf
/// @brief __DAG__ Routines dealing with the DA_Ephys GUI state waves

/// @brief Records the state of the DA_ephys panel into the numerical GUI state wave
Function DAG_RecordGuiStateNum(string device, [WAVE GUIState])

	variable i, numEntries
	string ctrlName, lbl

	if(ParamIsDefault(GuiState))
		WAVE GUIState = GetDA_EphysGuiStateNum(device)
	endif

	WAVE state = DAG_ControlStatusWave(device, CHANNEL_TYPE_HEADSTAGE)
	lbl                                          = GetSpecialControlLabel(CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
	GUIState[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE state = DAG_GetAllHSMode(device)
	GUIState[0, DimSize(state, ROWS) - 1][%HSMode] = state[p]

	WAVE state = DAG_ControlStatusWave(device, CHANNEL_TYPE_DAC)
	lbl                                          = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)
	GUIState[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysSetVarNum(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
	lbl                                          = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
	GUIState[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysSetVarNum(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	lbl                                          = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	GUIState[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysPopMenuIndex(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	lbl                                          = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	GUIState[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysPopMenuIndex(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
	lbl                                          = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
	GUIState[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE state = DAG_ControlStatusWave(device, CHANNEL_TYPE_ADC)
	lbl                                          = GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK)
	GUIState[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysSetVarNum(device, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
	lbl                                          = GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
	GUIState[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE state = DAG_ControlStatusWave(device, CHANNEL_TYPE_TTL)
	lbl                                          = GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_CHECK)
	GUIState[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysPopMenuIndex(device, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
	lbl                                          = GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
	GUIState[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysPopMenuIndex(device, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
	lbl                                          = GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
	GUIState[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE state = DAG_ControlStatusWave(device, CHANNEL_TYPE_ASYNC)
	lbl                                          = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_CHECK)
	GUIState[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysSetVarNum(device, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN)
	lbl                                          = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN)
	GUIState[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE state = DAG_ControlStatusWave(device, CHANNEL_TYPE_ALARM)
	lbl                                          = GetSpecialControlLabel(CHANNEL_TYPE_ALARM, CHANNEL_CONTROL_CHECK)
	GUIState[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysSetVarNum(device, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN)
	lbl                                          = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN)
	GUIState[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE state = GetAllDAEphysSetVarNum(device, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX)
	lbl                                          = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX)
	GUIState[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	numEntries = DimSize(GUIState, COLS)
	for(i = COMMON_CONTROL_GROUP_COUNT_NUM; i < numEntries; i += 1)
		ctrlName = GetDimLabel(GUIState, COLS, i)
		controlInfo/W=$device $ctrlName
		ASSERT(V_flag != 0, "invalid or non existing control")

		if(abs(V_Flag) == CONTROL_TYPE_POPUPMENU)
			V_Value -= 1
		endif

		GUIState[0][i] = V_Value
	endfor
End

/// @brief Records the state of the DA_ephys panel into the textual GUI state wave
Function DAG_RecordGuiStateTxT(string device, [WAVE GUIState])

	variable i, numEntries
	string ctrlName, lbl

	if(ParamIsDefault(GuiState))
		WAVE/T GUIStateTxT = GetDA_EphysGuiStateTxT(device)
	else
		WAVE/T GUIStateTxT = GUIState
	endif

	WAVE/T state = GetAllDAEphysPopMenuString(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	lbl                                             = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	GUIStateTxT[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysPopMenuString(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
	lbl                                             = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
	GUIStateTxT[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysSetVarTxT(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
	lbl                                             = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
	GUIStateTxT[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysSetVarTxT(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SEARCH)
	lbl                                             = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SEARCH)
	GUIStateTxT[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysSetVarTxT(device, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
	lbl                                             = GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
	GUIStateTxT[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysPopMenuString(device, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
	lbl                                             = GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
	GUIStateTxT[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysPopMenuString(device, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
	lbl                                             = GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
	GUIStateTxT[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysSetVarTxT(device, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_SEARCH)
	lbl                                             = GetSpecialControlLabel(CHANNEL_TYPE_TTL, CHANNEL_CONTROL_SEARCH)
	GUIStateTxT[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysSetVarTxT(device, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_TITLE)
	lbl                                             = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_TITLE)
	GUIStateTxT[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	WAVE/T state = GetAllDAEphysSetVarTxT(device, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_UNIT)
	lbl                                             = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_UNIT)
	GUIStateTxT[0, DimSize(state, ROWS) - 1][%$lbl] = state[p]

	numEntries = DimSize(GUIStateTxT, COLS)
	for(i = COMMON_CONTROL_GROUP_COUNT_TXT; i < numEntries; i += 1)
		ctrlName = GetDimLabel(GUIStateTxT, COLS, i)
		controlInfo/W=$device $ctrlName
		ASSERT(V_flag != 0, "invalid or non existing control")
		GUIStateTxT[0][i] = S_Value
	endfor
End

/// @brief Query a control value from the numerical gui state wave
///
/// This does return the zero-based *index* for PopupMenues.
///
/// Convienience wrapper to make the call sites nicer.
///
/// @param device device
/// @param ctrl       control name
/// @param index      [optional, default to NaN] Some control entries have multiple
///                   entries per headstage/channel/etc.
///
/// UTF_NOINSTRUMENTATION
Function DAG_GetNumericalValue(string device, string ctrl, [variable index])

	variable refValue, waveIndex, ctrlDim
	string msg

	if(ParamIsDefault(index) || IsNaN(index))
		waveIndex = 0
		index     = NaN
	else
		waveIndex = index
	endif

#if defined(AUTOMATED_TESTING) || defined(DEBUGGING_ENABLED)

	// check if the GUI state wave is consistent
	if(defined(AUTOMATED_TESTING) || DP_DebuggingEnabledForCaller())

		if(!IsFinite(index))
			ControlInfo/W=$device $ctrl
		else
			string fullCtrl
			sprintf fullCtrl, "%s_%02d", ctrl, index
			ControlInfo/W=$device $fullCtrl
		endif

		if(abs(V_Flag) == CONTROL_TYPE_POPUPMENU)
			V_Value -= 1
		endif

		WAVE GUIState = GetDA_EphysGuiStateNum(device)
		ctrlDim = FindDimLabel(GUIState, COLS, ctrl)
		if(ctrlDim < 0)
			sprintf msg, "Control entry not found in numeric GUI state wave: %s\r", ctrl
			BUG(msg)
		else
			refValue = GUIState[waveIndex][ctrlDim]
		endif

		if(!CheckIfClose(V_Value, refValue) && !EqualValuesOrBothNaN(V_Value, refValue))
			sprintf msg, "Numeric GUI state wave is inconsistent for %s: %g vs. %g\r", ctrl, V_Value, refValue
			BUG(msg)
		endif
	endif
#endif

	return GetDA_EphysGuiStateNum(device)[waveIndex][%$ctrl]
End

/// @brief Query a control value from the textual gui state wave
///
/// Convienience wrapper to make the call sites nicer.
///
/// @param device device
/// @param ctrl       control name
/// @param index      [optional, default to NaN] Some control entries have multiple
///                   entries per headstage/channel/etc.
Function/S DAG_GetTextualValue(string device, string ctrl, [variable index])

	string str, msg
	variable waveIndex, ctrlDim

	if(ParamIsDefault(index) || IsNaN(index))
		waveIndex = 0
		index     = NaN
	else
		waveIndex = index
	endif

	WAVE/T GUIState = GetDA_EphysGuiStateTxT(device)

#if defined(AUTOMATED_TESTING) || defined(DEBUGGING_ENABLED)

	// check if the GUI state wave is consistent
	if(defined(AUTOMATED_TESTING) || DP_DebuggingEnabledForCaller())

		if(!IsFinite(index))
			ControlInfo/W=$device $ctrl
		else
			string fullCtrl
			sprintf fullCtrl, "%s_%02d", ctrl, index
			ControlInfo/W=$device $fullCtrl
		endif

		if(V_flag == 0)
			sprintf msg, "Control %s does not exist in window %s.\r", ctrl, device
			BUG(msg)
		endif

		ctrlDim = FindDimLabel(GUIState, COLS, ctrl)
		if(ctrlDim < 0)
			sprintf msg, "Control entry not found in textual GUI state wave: %s\r", ctrl
			BUG(msg)
			str = "@@@ CONTROL NOT PRESENT IN GUISTATE WAVE @@@"
		else
			str = GUIState[waveIndex][ctrlDim]
		endif

		if(IsEmpty(S_Value) != IsEmpty(str) || cmpstr(S_Value, str))
			sprintf msg, "Textual GUI state wave is inconsistent for %s: %s vs. %s\r", ctrl, SelectString(IsNull(S_Value), S_Value, "<null>"), str
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
/// @param device  panel title
Function/WAVE DAG_GetChannelState(string device, variable type)

	variable numEntries, col

	WAVE GUIState = GetDA_EphysGuiStateNum(device)

	numEntries = GetNumberFromType(var = type)

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
			FATAL_ERROR("invalid type")
			break
	endswitch

	Make/FREE/D/N=(numEntries) wv = GUIState[p][col]

	return wv
End

/// @brief Return a wave with `NUM_HEADSTAGES` rows with `1` where
///        the given headstages is active and in the given clamp mode.
Function/WAVE DAG_GetActiveHeadstages(string device, variable clampMode)

	AI_AssertOnInvalidClampMode(clampMode)

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
	WAVE GUIState = GetDA_EphysGuiStateNum(device)

	Make/FREE/N=(NUM_HEADSTAGES) status = statusHS[p] && (GUIState[p][%HSMode] == clampMode)

	return status
End

/// @brief Return true/false if the given headstage is the highest active
///
/// @param device device
/// @param headstage  headstage to check
/// @param clampMode  [optional, defaults to all clamp modes] Restrict to the given clamp mode
Function DAG_HeadstageIsHighestActive(string device, variable headstage, [variable clampMode])

	if(ParamIsDefault(clampMode))
		WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
	else
		WAVE statusHS = DAG_GetActiveHeadstages(device, clampMode)
	endif

	// no headstage active
	if(Sum(statusHS) == 0)
		return 0
	endif

	Make/FREE/N=(NUM_HEADSTAGES) activeHS = statusHS[p] * p

	return WaveMax(activeHS) == headstage
End

/// @brief Return a free wave of the popup menu strings specified by
///        channelType, uses GetDA_EphysGuiStateTxT() instead of GUI queries.
///
/// @param device  panel title
/// @param channelType one of the channel type constants from @ref ChannelTypeAndControlConstants
/// @param controlType one of the control type constants from @ref ChannelTypeAndControlConstants
Function/WAVE DAG_GetChannelTextual(string device, variable channelType, variable controlType)

	variable numEntries

	WAVE/T GUIState = GetDA_EphysGuiStateTxT(device)

	numEntries = GetNumberFromType(var = channelType)

	Make/FREE/T/N=(numEntries) wv = GUIState[p][%$GetSpecialControlLabel(channelType, controlType)]

	return wv
End

/// @brief Returns the headstage State
Function DAG_GetHeadstageState(string device, variable headStage)

	WAVE wv = GetDA_EphysGuiStateNum(device)
	return wv[headStage][%$GetSpecialControlLabel(CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)]
End

/// @returns the mode of the headstage defined in the locked DA_ephys panel,
///          can be V_CLAMP_MODE or I_CLAMP_MODE or NC
Function DAG_GetHeadstageMode(string device, variable headStage)

	return GetDA_EphysGuiStateNum(device)[headStage][%HSMode]
End

/// @brief Updates the state of a control in the GUIState numeric wave
///
/// One or both parameters have to be passed.
///
/// @param device  device
/// @param controlName control name
/// @param val         [optional] numerical value, 0-based index for popup menues
/// @param str         [optional] textual value
Function DAG_Update(string device, string controlName, [variable val, string str])

	variable col, channelIndex, channelType, controlType

	ASSERT((ParamIsDefault(val) + ParamIsDefault(str)) < 2, "One or both of `val` and `str` must be passed.")

	if(!ParamIsDefault(val))
		WAVE GUIState = GetDA_EphysGuiStateNum(device)
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

	if(!ParamIsDefault(str))
		WAVE/T GUIStateTxT = GetDA_EphysGuiStateTxT(device)
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
Function/S DAG_GetUniqueSpecCtrlListNum(string device)

	ASSERT(WindowExists(device), "Missing window")

	return DAG_GetSpecificCtrlNum(device, DAG_GetUniqueCtrlList(device))
End

/// @brief Returns a list of unique and type specific controls with textual values
Function/S DAG_GetUniqueSpecCtrlListTxT(string device)

	ASSERT(WindowExists(device), "Missing window")

	return DAG_GetSpecificCtrlTxT(device, DAG_GetUniqueCtrlList(device))
End

/// @brief Returns a free wave of the status of the checkboxes specified by channelType
///
/// The only caller should be DAG_RecordGuiStateNum().
///
/// @param type        one of the type constants from @ref ChannelTypeAndControlConstants
/// @param device  panel title
static Function/WAVE DAG_ControlStatusWave(string device, variable type)

	string ctrl
	variable i, numEntries

	numEntries = GetNumberFromType(var = type)

	Make/FREE/U/B/N=(numEntries) wv

	for(i = 0; i < numEntries; i += 1)
		ctrl  = GetPanelControl(i, type, CHANNEL_CONTROL_CHECK)
		wv[i] = GetCheckBoxState(device, ctrl)
	endfor

	return wv
End

/// @brief Return the mode of all DA_Ephys panel headstages
///
/// All callers, except the ones updating the GUIState wave,
/// should prefer DAG_GetHeadstageMode() instead.
static Function/WAVE DAG_GetAllHSMode(string device)

	variable i, headStage, clampMode
	string ctrl

	Make/FREE/N=(NUM_HEADSTAGES) Mode
	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		ctrl = GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
		DAP_GetInfoFromControl(device, ctrl, clampMode, headStage)
		ASSERT(headStage == i, "Unexpected value")
		Mode[i] = clampMode
	endfor

	return Mode
End

/// @brief Parses a list of controls in the device and returns a list of unique controls
static Function/S DAG_GetUniqueCtrlList(string device)

	string prunedList = ""
	string list, ctrlToRemove, ctrl
	variable i, channelIndex, channelType, controlType, numEntries

	list = ControlNameList(device)

	// remove special controls (1)
	ctrlToRemove = "Radio_ClampMode_*;ValDisp_DataAcq_P_*"
	numEntries   = ItemsInlist(ctrlToRemove)
	for(i = 0; i < numEntries; i += 1)
		prunedList = ListMatch(list, StringFromList(i, ctrlToRemove))
		list       = RemoveFromList(prunedList, list)
	endfor

	// remove special controls (2)
	numEntries = ItemsInlist(list)
	for(i = 0; i < numEntries; i += 1)
		ctrl = StringFromList(i, list)
		if(!DAP_ParsePanelControl(ctrl, channelIndex, channelType, controlType) && channelIndex >= 0)
			// special control already handled, but only for non-All controls
			continue
		endif
		prunedList = AddListItem(ctrl, prunedList, ";", Inf)
	endfor

	// remove controls which are too complicated to handle
	ctrlToRemove = "Popup_Settings_HeadStage;popup_Settings_Amplifier;Popup_Settings_VC_DA;setvar_Settings_VC_DAgain;SetVar_Hardware_VC_DA_Unit;Popup_Settings_VC_AD;setvar_Settings_VC_ADgain;SetVar_Hardware_VC_AD_Unit;Popup_Settings_IC_DA;setvar_Settings_IC_DAgain;SetVar_Hardware_IC_DA_Unit;Popup_Settings_IC_AD;setvar_Settings_IC_ADgain;SetVar_Hardware_IC_AD_Unit;popup_Settings_Pressure_dev;Popup_Settings_Pressure_DA;Popup_Settings_Pressure_AD;setvar_Settings_Pressure_DAgain;setvar_Settings_Pressure_ADgain;SetVar_Hardware_Pressur_DA_Unit;SetVar_Hardware_Pressur_AD_Unit;Popup_Settings_Pressure_TTLA;Popup_Settings_Pressure_TTLB"

	prunedList = RemoveFromList(ctrlToRemove, prunedList)

	return prunedList
End

/// @brief Parses a list of controls and returns numeric checkBox, valDisplay, setVariable, popUpMenu, and slider controls
static Function/S DAG_GetSpecificCtrlNum(string device, string list)

	string subtypeCtrlList = ""
	variable i, numEntries, controlType
	string controlName, recMacro

	numEntries = itemsinlist(list)
	for(i = 0; i < numEntries; i += 1)
		controlName = StringFromList(i, list)

		[recMacro, controlType] = GetRecreationMacroAndType(device, controlName)

		switch(controlType)
			case CONTROL_TYPE_CHECKBOX:
			case CONTROL_TYPE_POPUPMENU:
			case CONTROL_TYPE_SLIDER: // fallthrough
				subtypeCtrlList = AddListItem(controlName, subtypeCtrlList)
				break
			case CONTROL_TYPE_VALDISPLAY:
			case CONTROL_TYPE_SETVARIABLE: // fallthrough
				if(!DoesControlHaveInternalString(recMacro))
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
static Function/S DAG_GetSpecificCtrlTxT(string device, string list)

	string subtypeCtrlList = ""
	variable i, numEntries, controlType
	string controlName, recMacro

	numEntries = itemsinlist(list)
	for(i = 0; i < numEntries; i += 1)
		controlName = StringFromList(i, list)

		[recMacro, controlType] = GetRecreationMacroAndType(device, controlName)

		switch(controlType)
			case CONTROL_TYPE_POPUPMENU:
				subtypeCtrlList = AddListItem(controlName, subtypeCtrlList)
				break
			case CONTROL_TYPE_VALDISPLAY:
			case CONTROL_TYPE_SETVARIABLE: // fallthrough
				if(DoesControlHaveInternalString(recMacro))
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

/// @brief Returns the mode of all setVars in the DA_Ephys panel of a controlType
static Function/WAVE GetAllDAEphysSetVarNum(string device, variable channelType, variable controlType)

	variable CtrlNum = GetNumberFromType(var = channelType)
	string ctrl
	make/FREE/N=(CtrlNum) Wv
	variable i
	for(i = 0; i < CtrlNum; i += 1)
		ctrl  = GetPanelControl(i, channelType, controlType)
		wv[i] = GetSetVariable(device, ctrl)
	endfor
	return wv
End

/// @brief Returns the mode of all setVars in the DA_Ephys panel of a controlType
static Function/WAVE GetAllDAEphysSetVarTxT(string device, variable channelType, variable controlType)

	variable CtrlNum = GetNumberFromType(var = channelType)
	string ctrl
	make/FREE/N=(CtrlNum)/T Wv
	variable i
	for(i = 0; i < CtrlNum; i += 1)
		ctrl  = GetPanelControl(i, channelType, controlType)
		wv[i] = GetSetVariableString(device, ctrl)
	endfor
	return wv
End

/// @brief Returns the index of all popupmenus in the DA_Ephys panel of a controlType
static Function/WAVE GetAllDAEphysPopMenuIndex(string device, variable channelType, variable controlType)

	variable CtrlNum = GetNumberFromType(var = channelType)
	string ctrl
	make/FREE/N=(CtrlNum) Wv
	variable i
	for(i = 0; i < CtrlNum; i += 1)
		ctrl  = GetPanelControl(i, channelType, controlType)
		wv[i] = GetPopupMenuIndex(device, ctrl)
	endfor
	return wv
End

/// @brief Returns the string contents of all popupmenus in the DA_Ephys panel of a controlType
static Function/WAVE GetAllDAEphysPopMenuString(string device, variable channelType, variable controlType)

	variable CtrlNum = GetNumberFromType(var = channelType)
	string ctrl
	make/FREE/N=(CtrlNum)/T Wv
	variable i
	for(i = 0; i < CtrlNum; i += 1)
		ctrl  = GetPanelControl(i, channelType, controlType)
		wv[i] = GetPopupMenuString(device, ctrl)
	endfor
	return wv
End
