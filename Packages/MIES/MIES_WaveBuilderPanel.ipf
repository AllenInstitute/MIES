#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_WBP
#endif

/// @file MIES_WaveBuilderPanel.ipf
/// @brief __WBP__ Panel for creating stimulus sets

Menu "TracePopup"
	"Open stimulus set in wavebuilder", /Q, WB_OpenStimulusSetInWaveBuilder()
End

static StrConstant panel              = "WaveBuilder"
static StrConstant WaveBuilderGraph   = "WaveBuilder#WaveBuilderGraph"
static StrConstant AnalysisParamGUI   = "WaveBuilder#AnalysisParamGUI"
static StrConstant DEFAULT_SET_PREFIX = "StimulusSetA"

static StrConstant SEGWVTYPE_CONTROL_REGEXP     = ".*_S[[:digit:]]+"
static StrConstant WP_CONTROL_REGEXP            = ".*_P[[:digit:]]+"
static StrConstant WPT_CONTROL_REGEXP           = ".*_T[[:digit:]]+"
static StrConstant SEGWVTYPE_ALL_CONTROL_REGEXP = "^.*_ALL$"

static Constant WBP_WAVETYPE_WP        = 0x1
static Constant WBP_WAVETYPE_WPT       = 0x2
static Constant WBP_WAVETYPE_SEGWVTYPE = 0x4

/// @name Parameters for WBP_TranslateControlContents()
/// @{
static Constant FROM_PANEL_TO_WAVE = 0x1
static Constant FROM_WAVE_TO_PANEL = 0x2
/// @}

static StrConstant HIDDEN_CONTROLS_CUSTOM_COMBINE = "SetVar_WaveBuilder_P0;SetVar_WaveBuilder_P1;SetVar_WaveBuilder_P2;SetVar_WaveBuilder_P3;SetVar_WB_DurDeltaMult_P52;SetVar_WB_AmpDeltaMult_P50;popup_WaveBuilder_op_P70;popup_WaveBuilder_op_P71;popup_WaveBuilder_op_P72;setvar_explDeltaValues_T11;setvar_explDeltaValues_T12_DD02;setvar_explDeltaValues_T13"
static StrConstant HIDDEN_CONTROLS_SQUARE_PULSE   = "popup_WaveBuilder_op_P71;setvar_explDeltaValues_T12_DD02"

Function WB_OpenStimulusSetInWaveBuilder()

	string graph, trace, extPanel, waveBuilder, stimset, device
	variable sweepNo, headstage, abIndex, sbIndex

	GetLastUserMenuInfo
	graph = S_graphName
	trace = S_traceName

	extPanel = BSP_GetPanel(graph)

	if(!WindowExists(extPanel))
		printf "Context menu option \"%s\" is only useable for the databrowser/sweepbrowser.\r", S_Value
		ControlWindowToFront()
		return NaN
	endif

	sweepNo = str2num(TUD_GetUserData(graph, trace, "sweepNumber"))
	headstage = str2num(TUD_GetUserData(graph, trace, "headstage"))
	WAVE/T textualValues = $TUD_GetUserData(graph, trace, "textualValues")

	WAVE/T/Z stimsetLBN = GetLastSetting(textualValues, sweepNo, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)

	if(!WaveExists(stimsetLBN) || IsNaN(headstage))
		printf "Context menu option \"%s\" could not find the stimulus set of the trace %s.\r", S_Value, trace
		ControlWindowToFront()
		return NaN
	endif

	stimset = stimsetLBN[headstage]

	WAVE/Z stimsetWave = WB_CreateAndGetStimSet(stimset)

	if(!WaveExists(stimsetWave))
		if(BSP_IsDataBrowser(graph))
			printf "Context menu option \"%s\" could not be find the stimulus set %s.", S_Value, stimset
			ControlWindowToFront()
			return NaN
		else
			// we might need to load the stimset
			WAVE traceWave = $TUD_GetUserData(graph, trace, "fullPath")
			DFREF sweepDataDFR = GetWavesDataFolderDFR(traceWave)
			sbIndex = SB_GetIndexFromSweepDataPath(graph, sweepDataDFR)

			DFREF sweepBrowserDFR = SB_GetSweepBrowserFolder(graph)
			WAVE/T sweepMap = GetSweepBrowserMap(sweepBrowserDFR)

			abIndex = SB_TranslateSBMapIndexToABMapIndex(graph, sbIndex)
			device  = sweepMap[sbIndex][%Device]
			if(AB_LoadStimsetForSweep(device, abIndex, sweepNo))
				printf "Context menu option \"%s\" could not load the stimulus set %s.", S_Value, stimset
				ControlWindowToFront()
				return NaN
			endif
		endif
	endif

	waveBuilder = WBP_CreateWaveBuilderPanel()
	PGC_SetAndActivateControl(waveBuilder, "popup_WaveBuilder_SetList", str = stimset)
End

Function/S WBP_CreateWaveBuilderPanel()

	if(windowExists(panel))
		DoWindow/F $panel
		return panel
	endif

	// create all necessary data folders
	GetWBSvdStimSetParamPath()
	GetWBSvdStimSetParamDAPath()
	GetWBSvdStimSetParamTTLPath()
	GetWBSvdStimSetPath()
	GetWBSvdStimSetDAPath()
	GetWBSvdStimSetTTLPath()

	KillOrMoveToTrash(wv=GetSegmentTypeWave())
	KillOrMoveToTrash(wv=GetWaveBuilderWaveParam())
	KillOrMoveToTrash(wv=GetWaveBuilderWaveTextParam())

	Execute "WaveBuilder()"
	ListBox listbox_combineEpochMap, listWave=GetWBEpochCombineList()
	AddVersionToPanel(panel, WAVEBUILDER_PANEL_VERSION)

	NVAR JSONid = $GetSettingsJSONid()
	PS_InitCoordinates(JSONid, panel, "wavebuilder")

	return panel
End

Function WBP_StartupSettings()

	if(!WindowExists(panel))
		printf "The window %s does not exist\r", panel
		ControlWindowToFront()
		return 1
	endif

	HideTools/A/W=$panel

	WAVE/Z wv = $""
	ListBox listbox_combineEpochMap, listWave=wv, win=$panel

	KillWindow/Z $WBP_GetFFTSpectrumPanel()

	if(SearchForInvalidControlProcs(panel))
		return NaN
	endif

	KillOrMoveToTrash(wv=GetSegmentTypeWave())
	KillOrMoveToTrash(wv=GetWaveBuilderWaveParam())
	KillOrMoveToTrash(wv=GetWaveBuilderWaveTextParam())

	SetPopupMenuIndex(panel, "popup_WaveBuilder_SetList", 0)
	SetCheckBoxState(panel, "check_PreventUpdate", CHECKBOX_UNSELECTED)

	SetPopupMenuIndex(panel, "popup_WaveBuilder_FolderList", 0)
	SetPopupMenuIndex(panel, "popup_WaveBuilder_ListOfWaves", 0)

	SetCheckBoxState(panel, "check_allow_saving_builtin_nam", CHECKBOX_UNSELECTED)

	WBP_LoadSet(NONE)

	if(WindowExists(AnalysisParamGUI))
		PGC_SetAndActivateControl(panel, "button_toggle_params")
	endif

	CallFunctionForEachListItem(WBP_AdjustDeltaControls, ControlNameList(panel, ";", "popup_WaveBuilder_op_*"))

	Execute/P/Q/Z "DoWindow/R " + panel
	Execute/P/Q/Z "COMPILEPROCEDURES "
End

static Constant EPOCH_HL_TYPE_LEFT  = 0x01
static Constant EPOCH_HL_TYPE_RIGHT = 0x02

/// @brief Add epoch highlightning traces
/// Uses fill-to-next on specially created waves added before and after the current trace
static Function WBP_AddEpochHLTraces(dfr, epochHLType, epoch, numEpochs)
	DFREF dfr
	variable epochHLType, epoch, numEpochs

	string nameBegin, nameEnd
	variable first, last

	WAVE epochID = GetEpochID()

	if(epochHLType == EPOCH_HL_TYPE_LEFT)
		nameBegin = "epochHLBeginLeft"
		nameEnd   = "epochHLEndLeft"

		Make/O/N=(2) dfr:$nameBegin = NaN, dfr:$nameEnd = NaN
		WAVE/SDFR=dfr waveBegin = $nameBegin
		WAVE/SDFR=dfr waveEnd   = $nameEnd

		if(epoch == 0)
			// no epoch to highlight left of the current one
			return NaN
		endif

		// we highlight the range 0, 1, ..., epoch - 1
		first = epochID[0][%timeBegin]
		last  = epochID[epoch - 1][%timeEnd]
	elseif(epochHLType == EPOCH_HL_TYPE_RIGHT)
		nameBegin = "epochHLBeginRight"
		nameEnd   = "epochHLEndRight"

		Make/O/N=(2) dfr:$nameBegin = NaN, dfr:$nameEnd = NaN
		WAVE/SDFR=dfr waveBegin = $nameBegin
		WAVE/SDFR=dfr waveEnd   = $nameEnd

		if(epoch == numEpochs - 1)
			// no epoch to highlight right of the current one
			return NaN
		endif

		// and the range epoch + 1, ...,  lastEpoch
		first = epochID[epoch + 1][%timeBegin]
		last  = epochID[numEpochs - 1][%timeEnd]
	endif

	if(first == last)
		// don't try to highlight empty epochs
		return NaN
	endif

	SetScale/I x, first, last, "ms", waveBegin, waveEnd

	AppendToGraph/W=$waveBuilderGraph waveBegin
	ModifyGraph/W=$waveBuilderGraph hbFill($nameBegin)=5
	ModifyGraph/W=$waveBuilderGraph mode($nameBegin)=7, toMode($nameBegin)=1
	ModifyGraph/W=$waveBuilderGraph useNegRGB($nameBegin)=1, usePlusRGB($nameBegin)=1
	ModifyGraph/W=$waveBuilderGraph plusRGB($nameBegin)=(56576,56576,56576), negRGB($nameBegin)=(56576,56576,56576)
	ModifyGraph/W=$waveBuilderGraph rgb($nameBegin)=(65535,65535,65535)

	AppendToGraph/W=$waveBuilderGraph waveEnd
	ModifyGraph/W=$waveBuilderGraph rgb($nameEnd)=(65535,65535,65535)
End

static Function WBP_DisplaySetInPanel()

	variable i, epoch, numEpochs, numSweeps
	string trace
	variable maxYValue, minYValue
	STRUCT RGBColor s

	if(!HasPanelLatestVersion(panel, WAVEBUILDER_PANEL_VERSION))
		DoAbortNow("Wavebuilder panel is out of date. Please close and reopen it.")
	endif

	RemoveTracesFromGraph(waveBuilderGraph)

	WAVE/Z stimSet = WB_GetStimSetForWaveBuilder()
	if(!WaveExists(stimSet))
		return NaN
	endif

	WAVE ranges = GetAxesRanges(waveBuilderGraph)

	WAVE SegWvType = GetSegmentTypeWave()

	epoch     = GetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch")
	numEpochs = SegWvType[100]

	DFREF dfr = GetWaveBuilderDataPath()
	WBP_AddEpochHLTraces(dfr, EPOCH_HL_TYPE_LEFT, epoch, numEpochs)
	WAVE/SDFR=dfr epochHLBeginLeft, epochHLEndLeft

	WBP_AddEpochHLTraces(dfr, EPOCH_HL_TYPE_RIGHT, epoch, numEpochs)
	WAVE/SDFR=dfr epochHLBeginRight, epochHLEndRight

	WAVE displayData = GetWaveBuilderDispWave()
	Duplicate/O stimSet, displayData
	WaveClear stimSet

	numSweeps = DimSize(displayData, COLS)

	if(numSweeps == 0)
		return NaN
	endif

	for(i = 0; i < numSweeps; i += 1)
		trace = NameOfWave(displayData) + "_S" + num2str(i)
		AppendToGraph/W=$waveBuilderGraph displayData[][i]/TN=$trace
		[s] = WBP_GetSweepColor(i)
		ModifyGraph/W=$waveBuilderGraph rgb($trace) = (s.red, s.green, s.blue)
	endfor

	[minYValue, maxYValue] = WaveMinAndMaxWrapper(displayData)

	if(maxYValue == minYValue)
		maxYValue = 1e-12
		minYValue = 1e-12
	endif

	epochHLBeginRight = maxYValue
	epochHLBeginLeft  = maxYValue

	epochHLEndRight   = min(0, minYValue)
	epochHLEndLeft    = min(0, minYValue)

	SetAxis/W=$waveBuilderGraph/A/E=3 left
	SetAxesRanges(waveBuilderGraph, ranges)
End

/// @brief Reponsible for adjusting controls which depend on other controls
///
/// Must be called before the changed settings are written into the parameter waves.
static Function WBP_UpdateDependentControls(checkBoxCtrl, checked)
	string checkBoxCtrl
	variable checked

	variable val

	switch(GetTabID(panel, "WBP_WaveType"))
		case EPOCH_TYPE_PULSE_TRAIN:
			if(!cmpstr(checkBoxCtrl,"check_SPT_Poisson_P44"))

				if(checked)
					WBP_UpdateControlAndWave("check_SPT_MixedFreq_P41", var = CHECKBOX_UNSELECTED)

					val = str2numsafe(GetUserData(panel, "check_SPT_NumPulses_P46", "old_state"))
					if(IsFinite(val))
						WBP_UpdateControlAndWave("check_SPT_NumPulses_P46", var = !!val)
					endif

					EnableControls(panel,"check_SPT_NumPulses_P46;SetVar_WaveBuilder_P6_FD01;SetVar_WaveBuilder_P7_DD01")
				endif

			elseif(!cmpstr(checkBoxCtrl,"check_SPT_MixedFreq_P41"))

				if(checked)
					WBP_UpdateControlAndWave("check_SPT_Poisson_P44", var = CHECKBOX_UNSELECTED)
					val = GetCheckBoxState(panel,"check_SPT_NumPulses_P46")
					SetControlUserData(panel, "check_SPT_NumPulses_P46", "old_state", num2str(val))
					WBP_UpdateControlAndWave("check_SPT_NumPulses_P46", var = CHECKBOX_SELECTED)
					DisableControls(panel,"check_SPT_NumPulses_P46;SetVar_WaveBuilder_P6_FD01;SetVar_WaveBuilder_P7_DD01")
				else
					EnableControls(panel,"check_SPT_NumPulses_P46;SetVar_WaveBuilder_P6_FD01;SetVar_WaveBuilder_P7_DD01")
				endif

			endif
			break
		default:
			// nothing to do
			break
	endswitch
End

static Function WBP_UpdatePanelIfAllowed()

	string controls
	variable lowPassCutOff, highPassCutOff, maxDuration, deltaMode

	if(!GetCheckBoxState(panel, "check_PreventUpdate"))
		WBP_DisplaySetInPanel()
	endif

	switch(GetTabID(panel, "WBP_WaveType"))
		case EPOCH_TYPE_NOISE:
			lowPassCutOff  = GetSetVariable(panel, "SetVar_WaveBuilder_P20")
			highPassCutOff = GetSetVariable(panel, "SetVar_WaveBuilder_P22")

			if(WB_IsValidCutoffFrequency(HighPassCutOff) || WB_IsValidCutoffFrequency(LowPassCutOff))
				EnableControls(panel, "SetVar_WaveBuilder_P26;SetVar_WaveBuilder_P27")
			else
				DisableControls(panel, "SetVar_WaveBuilder_P26;SetVar_WaveBuilder_P27")
			endif

			WBP_LowPassDeltaLimits()
			WBP_HighPassDeltaLimits()
			WBP_CutOffCrossOver()
			break
		case EPOCH_TYPE_SIN_COS:
			if(GetCheckBoxState(panel,"check_Sin_Chirp_P43"))
				EnableControls(panel, "SetVar_WaveBuilder_P24;SetVar_WaveBuilder_P25;SetVar_WB_DeltaMult_P65;popup_WaveBuilder_op_P81;setvar_explDeltaValues_T22")
			else
				DisableControls(panel, "SetVar_WaveBuilder_P24;SetVar_WaveBuilder_P25;SetVar_WB_DeltaMult_P65;popup_WaveBuilder_op_P81;setvar_explDeltaValues_T22")
			endif
			break
		case EPOCH_TYPE_PULSE_TRAIN:
			if(GetCheckBoxState(panel,"check_SPT_NumPulses_P46"))
				DisableControl(panel, "SetVar_WaveBuilder_P0")
				EnableControls(panel, "SetVar_WaveBuilder_P45;SetVar_WaveBuilder_P47;SetVar_WB_DeltaMult_P69;popup_WaveBuilder_op_P85;setvar_explDeltaValues_T26")
			else
				EnableControl(panel, "SetVar_WaveBuilder_P0")
				DisableControls(panel, "SetVar_WaveBuilder_P45;SetVar_WaveBuilder_P47;SetVar_WB_DeltaMult_P69;popup_WaveBuilder_op_P85;setvar_explDeltaValues_T26")
			endif

			if(GetCheckBoxState(panel, "check_SPT_MixedFreq_P41"))
				EnableControls(panel, "SetVar_WaveBuilder_P28;SetVar_WaveBuilder_P29;SetVar_WB_DeltaMult_P67;popup_WaveBuilder_op_P83;setvar_explDeltaValues_T24;SetVar_WaveBuilder_P30;SetVar_WaveBuilder_P31;SetVar_WB_DeltaMult_P68;popup_WaveBuilder_op_P84;setvar_explDeltaValues_T25")
			else
				DisableControls(panel, "SetVar_WaveBuilder_P28;SetVar_WaveBuilder_P29;SetVar_WB_DeltaMult_P67;popup_WaveBuilder_op_P83;setvar_explDeltaValues_T24;SetVar_WaveBuilder_P30;SetVar_WaveBuilder_P31;SetVar_WB_DeltaMult_P68;popup_WaveBuilder_op_P84;setvar_explDeltaValues_T25")
			endif

			if(GetCheckBoxState(panel,"check_SPT_Poisson_P44") || GetCheckBoxState(panel,"check_SPT_MixedFreqShuffle_P42"))
				EnableControls(panel, "check_NewSeedForEachSweep_P49_0;button_NewSeed_P48_0;check_UseEpochSeed_P39_0")
			else
				DisableControls(panel, "check_NewSeedForEachSweep_P49_0;button_NewSeed_P48_0;check_UseEpochSeed_P39_0")
			endif

			maxDuration = WBP_ReturnPulseDurationMax()
			SetVariable SetVar_WaveBuilder_P8 win=$panel, limits = {0, maxDuration, 0.1}
			if(GetSetVariable(panel, "SetVar_WaveBuilder_P8") > maxDuration)
				SetSetVariable(panel, "SetVar_WaveBuilder_P8", maxDuration)
			endif
			break
		case EPOCH_TYPE_COMBINE:
			WB_UpdateEpochCombineList(WBP_GetStimulusType())
			break
		default:
			// nothing to do
			break
	endswitch
End

/// @brief Passes the data from the WP wave to the panel
static Function WBP_ParameterWaveToPanel(stimulusType)
	variable stimulusType

	string list, control, data, customWaveName, allControls
	variable segment, numEntries, i, row

	WAVE WP    = GetWaveBuilderWaveParam()
	WAVE/T WPT = GetWaveBuilderWaveTextParam()

	segment = GetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch")
	allControls = ControlNameList(panel)

	list = GrepList(allControls, WP_CONTROL_REGEXP)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		control = StringFromList(i, list)
		row = WBP_ExtractRowNumberFromControl(control)
		ASSERT(IsFinite(row), "Could not find row in: " + control)
		WBP_SetControl(panel, control, value = WP[row][segment][stimulusType])
	endfor

	list = GrepList(allControls, WPT_CONTROL_REGEXP)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		control = StringFromList(i, list)
		row = WBP_ExtractRowNumberFromControl(control)
		ASSERT(IsFinite(row), "Could not find row in: " + control)

		if(GrepString(control, SEGWVTYPE_ALL_CONTROL_REGEXP))
			data = WPT[row][%Set][INDEP_EPOCH_TYPE]
		else
			data = WPT[row][segment][stimulusType]
		endif

		data = WBP_TranslateControlContents(control, FROM_WAVE_TO_PANEL, data)
		SetSetVariableString(panel, control, data)
	endfor

	if(stimulusType == EPOCH_TYPE_CUSTOM)
		customWaveName = WPT[0][segment][EPOCH_TYPE_CUSTOM]
		WAVE/Z customWave = $customWaveName
		if(WaveExists(customWave))
			GroupBox group_WaveBuilder_FolderPath win=$panel, title=GetWavesDataFolder(customWave, 1)
			PopupMenu popup_WaveBuilder_ListOfWaves, win=$panel, popMatch=NameOfWave(customWave)
		endif
	elseif(stimulusType == EPOCH_TYPE_PULSE_TRAIN)
		WBP_UpdateDependentControls("check_SPT_Poisson_P44", GetCheckBoxState(panel, "check_SPT_Poisson_P44"))
		WBP_UpdateDependentControls("check_SPT_MixedFreq_P41", GetCheckBoxState(panel, "check_SPT_MixedFreq_P41"))
	endif
End

/// @brief Generic wrapper for setting a control's value
static Function WBP_SetControl(win, control, [value, str])
	string win, control
	variable value
	string str

	variable controlType

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	controlType = abs(V_flag)

	if(controlType == 1)
		// nothing to do
	elseif(controlType == 2)
		ASSERT(!ParamIsDefault(value), "Missing value parameter")
		CheckBox $control, win=$win, value=(value == CHECKBOX_SELECTED)
	elseif(controlType == 5)
		if(!ParamIsDefault(value))
			SetVariable $control, win=$win, value=_NUM:value
		elseif(!ParamIsDefault(str))
			SetVariable $control, win=$win, value=_STR:str
		else
			ASSERT(0, "Missing optional parameter")
		endif
	elseif(controlType == 3)
		ASSERT(!ParamIsDefault(value), "Missing value parameter")
		PopupMenu $control, win=$win, mode=value + 1
	else
		ASSERT(0, "Unsupported control type")
	endif
End

Function WBP_ButtonProc_DeleteSet(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string setWaveToDelete

	switch(ba.eventCode)
		case 2: // mouse up

			setWaveToDelete = GetPopupMenuString(panel, "popup_WaveBuilder_SetList")

			if(!CmpStr(SetWaveToDelete, NONE))
				print "Select a set to delete from popup menu."
				ControlWindowToFront()
				break
			endif

			ST_RemoveStimSet(setWaveToDelete)

			ControlUpdate/W=$panel popup_WaveBuilder_SetList
			PopupMenu popup_WaveBuilder_SetList win=$panel, mode = 1
			break
	endswitch

	return 0
End

Function WBP_ButtonProc_AutoScale(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			SetAxis/A/W=$WaveBuilderGraph
			break
	endswitch

	return 0
End

Function WBP_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up

			WBP_UpdateDependentControls(cba.ctrlName, cba.checked)
			WBP_UpdateControlAndWave(cba.ctrlName, var = cba.checked)
			WBP_UpdatePanelIfAllowed()
			break
	endswitch

	return 0
End

/// @brief Additional `initialhook` called in `ACL_DisplayTab`
Function WBP_InitialTabHook(tca)
	STRUCT WMTabControlAction &tca

	string type
	variable tabnum, idx
	Wave SegWvType = GetSegmentTypeWave()

	tabnum = tca.tab

	type = GetPopupMenuString(panel, "popup_WaveBuilder_OutputType")
	if(!CmpStr(type, "TTL"))
		// only allow 0th and 5th tab for TTL wave type
		if(tabnum == 1 || tabnum == 2 || tabnum == 3 || tabnum == 4 || tabnum == 6)
			return 1
		endif
	endif

	idx = GetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch")
	ASSERT(IsValidEpochNumber(idx), "Invalid number of epochs")
	SegWvType[idx] = tabnum

	WBP_ParameterWaveToPanel(tabnum)
	WBP_UpdatePanelIfAllowed()
	return 0
End

/// @brief Additional `finalhook` called in `ACL_DisplayTab`
Function WBP_FinalTabHook(tca)
	STRUCT WMTabControlAction &tca

	if(tca.tab != EPOCH_TYPE_PULSE_TRAIN)
		EnableControl(panel, "SetVar_WaveBuilder_P0")
	endif

	ShowControls(tca.win, HIDDEN_CONTROLS_CUSTOM_COMBINE)
	ShowControls(tca.win, HIDDEN_CONTROLS_SQUARE_PULSE)

	switch(tca.tab)
		case EPOCH_TYPE_CUSTOM:
		case EPOCH_TYPE_COMBINE:
			HideControls(tca.win, HIDDEN_CONTROLS_CUSTOM_COMBINE)
			break
		case EPOCH_TYPE_SQUARE_PULSE:
			HideControls(tca.win, HIDDEN_CONTROLS_SQUARE_PULSE)
			break
	endswitch

	CallFunctionForEachListItem(WBP_AdjustDeltaControls, ControlNameList(panel, ";", "popup_WaveBuilder_op_*"))

	return 0
End

Function WBP_ButtonProc_SaveSet(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string basename, setName
	variable stimulusType, setNumber, saveAsBuiltin, ret

	switch(ba.eventCode)
		case 2: // mouse up
			basename = GetSetVariableString(panel, "setvar_WaveBuilder_baseName")
			stimulusType = WBP_GetStimulusType()
			setNumber = GetSetVariable(panel, "setvar_WaveBuilder_SetNumber")
			saveAsBuiltin = GetCheckBoxState(panel, "check_allow_saving_builtin_nam")

			WAVE SegWvType = GetSegmentTypeWave()
			WAVE WP        = GetWaveBuilderWaveParam()
			WAVE/T WPT     = GetWaveBuilderWaveTextParam()

			setName = WB_SaveStimSet(baseName, stimulusType, SegWvType, WP, WPT, setNumber, saveAsBuiltin)

			if(IsEmpty(setName))
				break
			endif

			DAP_UpdateDaEphysStimulusSetPopups()
			WB_UpdateEpochCombineList(stimulusType)

			SetSetVariableString(panel, "setvar_WaveBuilder_baseName", DEFAULT_SET_PREFIX)
			WBP_LoadSet(NONE)
			break
	endswitch
End

static Function WBP_GetWaveTypeFromControl(control)
	string control

	if(GrepString(control, WP_CONTROL_REGEXP))
		return WBP_WAVETYPE_WP
	elseif(GrepString(control, SEGWVTYPE_CONTROL_REGEXP))
		return WBP_WAVETYPE_SEGWVTYPE
	elseif(GrepString(control, WPT_CONTROL_REGEXP))
		return WBP_WAVETYPE_WPT
	else
		return NaN
	endif
End

/// @brief Returns the row index into the parameter wave of the parameter represented by the named control
///
/// @param control name of the control, the expected format is `$str_$sep$row_$suffix` where `$str` may contain any
/// characters but `$suffix` is not allowed to include the substring `_$sep`.
///
/// All entries are per epoch type and per epoch number except when the `$suffix` is `ALL`
/// which denotes that it is a setting for the full stimset.
static Function WBP_ExtractRowNumberFromControl(control)
	string control

	variable start, stop, row
	string sep

	switch(WBP_GetWaveTypeFromControl(control))
		case WBP_WAVETYPE_WP:
			sep = "P"
			break
		case WBP_WAVETYPE_WPT:
			sep = "T"
			break
		case WBP_WAVETYPE_SEGWVTYPE:
			sep = "S"
			break
		default:
			return NaN
			break
	endswitch

	start = strsearch(control, "_" + sep, Inf, 1)
	stop  = strsearch(control, "_", start + 2)

	if(stop == -1)
		stop = Inf
	endif

	row = str2num(control[start + 2,stop - 1])
	ASSERT(IsFinite(row), "Non finite row")

	return row
End

/// @brief Update the named control and pass its new value into the parameter wave
Function WBP_UpdateControlAndWave(control, [var, str])
	string control
	variable var
	string str

	variable stimulusType, epoch, paramRow

	ASSERT(ParamIsDefault(var) + ParamIsDefault(str) == 1, "Exactly one of var/str must be given")

	if(!ParamIsDefault(var))
		WBP_SetControl(panel, control, value = var)
	elseif(!ParamIsDefault(str))
		WBP_SetControl(panel, control, str = str)
	endif

	stimulusType = GetTabID(panel, "WBP_WaveType")
	epoch        = GetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch")
	paramRow     = WBP_ExtractRowNumberFromControl(control)
	ASSERT(IsFinite(paramRow), "Could not find row in: " + control)

	switch(WBP_GetWaveTypeFromControl(control))
		case WBP_WAVETYPE_WP:
			WAVE WP = GetWaveBuilderWaveParam()
			WP[paramRow][epoch][stimulusType] = var
			break
		case WBP_WAVETYPE_WPT:
			WAVE/T WPT = GetWaveBuilderWaveTextParam()

			if(GrepString(control, SEGWVTYPE_ALL_CONTROL_REGEXP))
				WPT[paramRow][%Set][INDEP_EPOCH_TYPE] = str
			else
				WPT[paramRow][epoch][stimulusType] = str
			endif

			break
		case WBP_WAVETYPE_SEGWVTYPE:
			WAVE SegWvType = GetSegmentTypeWave()
			SegWvType[paramRow] = var
			break
	endswitch
End

Function WBP_SetVarProc_UpdateParam(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update

			if(sva.isStr)
				WBP_UpdateControlAndWave(sva.ctrlName, str = sva.sval)
			else
				WBP_UpdateControlAndWave(sva.ctrlName, var = sva.dval)
			endif

			if(!cmpstr(sva.ctrlName, "SetVar_WB_NumEpochs_S100"))
				WBP_UpdateEpochControls()
			endif

			WBP_UpdatePanelIfAllowed()
			break
	endswitch

	return 0
End

static Function WBP_LowPassDeltaLimits()

	variable LowPassCutOff, numSweeps, LowPassDelta, DeltaLimit

	WAVE SegWvType = GetSegmentTypeWave()
	numSweeps = SegWvType[101]

	LowPassCutoff = GetSetVariable(panel, "SetVar_WaveBuilder_P20")
	LowPassDelta = GetSetVariable(panel, "SetVar_WaveBuilder_P21")

	if(LowPassDelta > 0)
		DeltaLimit = trunc(100000 / numSweeps)
		SetVariable SetVar_WaveBuilder_P21 win=$panel, limits = {-inf, DeltaLimit, 1}
		if(LowPassDelta > DeltaLimit)
			SetSetVariable(panel, "SetVar_WaveBuilder_P21", DeltaLimit)
		endif
	endif

	if(LowPassDelta < 0)
		DeltaLimit = trunc(-((LowPassCutOff/numSweeps) -1))
		SetVariable SetVar_WaveBuilder_P21 win=$panel, limits = {DeltaLimit, 99999, 1}
		if(LowPassDelta < DeltaLimit)
			SetSetVariable(panel, "SetVar_WaveBuilder_P21", DeltaLimit)
		endif
	endif
End

static Function WBP_HighPassDeltaLimits()

	variable HighPassCutOff, numSweeps, HighPassDelta, DeltaLimit

	WAVE SegWvType = GetSegmentTypeWave()
	numSweeps = SegWvType[101]

	HighPassCutoff = GetSetVariable(panel, "SetVar_WaveBuilder_P22")
	HighPassDelta = GetSetVariable(panel, "SetVar_WaveBuilder_P23")

	if(HighPassDelta > 0)
		DeltaLimit = trunc((100000 - HighPassCutOff) / numSweeps) - 1
		SetVariable SetVar_WaveBuilder_P23 win=$panel, limits = { -inf, DeltaLimit, 1}
		if(HighPassDelta > DeltaLimit)
			SetSetVariable(panel, "SetVar_WaveBuilder_P23", DeltaLimit)
		endif
	endif

	if(HighPassDelta < 0)
		DeltaLimit = trunc(HighPassCutOff / numSweeps) + 1
		SetVariable SetVar_WaveBuilder_P23 win=$panel, limits = {DeltaLimit, 99999, 1}
		if(HighPassDelta < DeltaLimit)
			SetSetVariable(panel, "SetVar_WaveBuilder_P23", DeltaLimit)
		endif
	endif
End

static Function WBP_ChangeWaveType()

	variable stimulusType
	string list

	WAVE SegWvType = GetSegmentTypeWave()
	WAVE WP = GetWaveBuilderWaveParam()

	list  = "SetVar_WaveBuilder_P3;SetVar_WaveBuilder_P4;SetVar_WaveBuilder_P5;"
	list += "SetVar_WaveBuilder_P4_OD00;SetVar_WaveBuilder_P4_OD01;SetVar_WaveBuilder_P4_OD02;SetVar_WaveBuilder_P4_OD03;SetVar_WaveBuilder_P4_OD04;"
	list += "SetVar_WaveBuilder_P5_DD02;SetVar_WaveBuilder_P5_DD03;SetVar_WaveBuilder_P5_DD04;SetVar_WaveBuilder_P5_DD05;SetVar_WaveBuilder_P5_DD06;"
	list += "popup_af_generic_S9;button_af_jump_to_proc"

	stimulusType = WBP_GetStimulusType()

	if(stimulusType == CHANNEL_TYPE_TTL)
		// recreate SegWvType with its defaults
		KillOrMoveToTrash(wv=GetSegmentTypeWave())

		WP[1,6][][] = 0

		SetVariable SetVar_WaveBuilder_P2 win = $panel, limits = {0,1,1}
		DisableControls(panel, list)

		WBP_UpdateControlAndWave("SetVar_WaveBuilder_P2", var = 0)
		WBP_UpdateControlAndWave("SetVar_WaveBuilder_P3", var = 0)
		WBP_UpdateControlAndWave("SetVar_WaveBuilder_P4", var = 0)
		WBP_UpdateControlAndWave("SetVar_WaveBuilder_P5", var = 0)
	elseif(stimulusType == CHANNEL_TYPE_DAC)
		SetVariable SetVar_WaveBuilder_P2 win =$panel, limits = {-inf,inf,1}
		EnableControls(panel, list)
	else
		ASSERT(0, "Unknown stimulus type")
	endif

	WBP_UpdatePanelIfAllowed()
End

Function WBP_GetStimulusType()
	return WB_ParseStimulusType(GetPopupMenuString(panel, "popup_wavebuilder_outputtype"))
End

Function WBP_PopMenuProc_WaveType(pa) : PopupMenuControl
	STRUCT WMPopupAction& pa

	switch(pa.eventCode)
		case 2:
			WBP_ChangeWaveType()
			break
	endswitch

	return 0
End

Function/S WBP_GetListOfWaves()

	string listOfWaves
	string searchPattern = "*"

	ControlInfo/W=$panel setvar_WaveBuilder_SearchString
	if(!IsEmpty(s_value))
		searchPattern = S_Value
	endif

	DFREF dfr = WBP_GetFolderPath()
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder dfr
	listOfWaves = NONE + ";" + Wavelist(searchPattern, ";", "TEXT:0,MAXCOLS:1")
	SetDataFolder saveDFR

	return listOfWaves
End

Function WBP_SetVarProc_SetSearchString(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			break
	endswitch

	return 0
End

Function WBP_PopMenuProc_WaveToLoad(pa) : PopupMenuControl
	struct WMPopupAction& pa

	variable SegmentNo
	string win

	switch(pa.eventCode)
		case 2:
			win = pa.win

			WAVE/T WPT = GetWaveBuilderWaveTextParam()

			dfref dfr = WBP_GetFolderPath()
			Wave/Z/SDFR=dfr customWave = $pa.popStr

			SegmentNo = GetSetVariable(win, "setvar_WaveBuilder_CurrentEpoch")

			if(WaveExists(customWave))
				WPT[0][SegmentNo][EPOCH_TYPE_CUSTOM] = GetWavesDataFolder(customWave, 2)
			else
				WPT[0][SegmentNo][EPOCH_TYPE_CUSTOM] = ""
			endif

			WBP_UpdatePanelIfAllowed()
		break
	endswitch
End

Function/S WBP_ReturnListSavedSets()

	string stimsetList, searchString

	searchString = GetSetVariableString(panel, "setvar_WaveBuilder_search")

	if(IsEmpty(searchString))
		searchString = "*"
	endif

	ST_GetStimsetList(searchString = searchString, WBstimSetList = stimsetList)

	return NONE + ";" + stimsetList
end

/// @brief Return true if the given stimset is a builtin, false otherwise
Function WBP_IsBuiltinStimset(setName)
	string setName

	return GrepString(setName, "^MIES_.*") || !CmpStr(setName, STIMSET_TP_WHILE_DAQ)
End

static Function WBP_LoadSet(setName)
	string setName

	string funcList, setPrefix
	variable channelType, setNumber, preventUpdate

	// prevent update until graph was loaded
	preventUpdate = GetCheckBoxState(panel, "check_PreventUpdate")
	SetCheckBoxState(panel, "check_PreventUpdate", 1)

	if(cmpstr(setName, NONE))
		WB_SplitStimsetName(setName, setPrefix, channelType, setNumber)

		PGC_SetAndActivateControl(panel, "popup_WaveBuilder_OutputType", val = channelType)

		WAVE WP        = WB_GetWaveParamForSet(setName)
		WAVE/T WPT     = WB_GetWaveTextParamForSet(setName)
		WAVE SegWvType = WB_GetSegWvTypeForSet(setName)

		DFREF dfr = GetWaveBuilderDataPath()
		Duplicate/O WP, dfr:WP
		Duplicate/O WPT, dfr:WPT
		Duplicate/O SegWvType, dfr:SegWvType
	else
		setPrefix = DEFAULT_SET_PREFIX
		channelType = CHANNEL_TYPE_DAC

		KillOrMoveToTrash(wv=GetSegmentTypeWave())
		KillOrMoveToTrash(wv=GetWaveBuilderWaveParam())
		KillOrMoveToTrash(wv=GetWaveBuilderWaveTextParam())

		PGC_SetAndActivateControl(panel, "popup_WaveBuilder_OutputType", val = channelType)
	endif

	// fetch wave references, possibly updating the wave layout if required
	WAVE WP        = GetWaveBuilderWaveParam()
	WAVE/T WPT     = GetWaveBuilderWaveTextParam()
	WAVE SegWvType = GetSegmentTypeWave()

	SetPopupMenuIndex(panel, "popup_WaveBuilder_op_S94", SegWvType[94])
	SetSetVariable(panel, "SetVar_WB_Multiplier_S95", SegWvType[95])
	SetSetVariable(panel, "SetVar_WaveBuilder_S96", SegWvType[96])
	SetCheckBoxState(panel, "check_FlipEpoch_S98", SegWvType[98])
	SetSetVariable(panel, "SetVar_WaveBuilder_S99", SegWvType[99])
	SetSetVariable(panel, "SetVar_WB_NumEpochs_S100", SegWvType[100])
	SetSetVariable(panel, "SetVar_WB_SweepCount_S101", SegWvType[101])
	SetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch", 0)

	SetSetVariableString(panel, "setvar_WaveBuilder_baseName", setPrefix)
	SetSetVariable(panel, "setvar_WaveBuilder_SetNumber", setNumber)

	funcList = WBP_GetAnalysisFunctions_V3()
	SetAnalysisFunctionIfFuncExists(panel, "popup_af_generic_S9", setName, funcList, WPT[9][%Set][INDEP_EPOCH_TYPE])
	WBP_AnaFuncsToWPT()

	ASSERT(IsValidEpochNumber(SegWvType[100]), "Invalid number of epochs")

	WBP_UpdateEpochControls()
	PGC_SetAndActivateControl(panel, "setvar_WaveBuilder_CurrentEpoch", val = 0)

	// reset old state of checkbox and update panel
	SetCheckBoxState(panel, "check_PreventUpdate", preventUpdate)
	WBP_UpdatePanelIfAllowed()

	if(WindowExists(AnalysisParamGUI))
		Wave/T listWave = WBP_GetAnalysisParamGUIListWave()

		if(DimSize(listWave, ROWS) == 0)
			PGC_SetAndActivateControl(AnalysisParamGUI, "setvar_param_name", str = "")
			ReplaceNoteBookText(AnalysisParamGUI + "#nb_param_value","")
		endif
	endif
End

static Function SetAnalysisFunctionIfFuncExists(win, ctrl, stimset, funcList, func)
	string win, ctrl, stimset, funcList, func

	string entry

	if(IsEmpty(func))
		entry = NONE
	else
		if(WhichListItem(func, funcList) != -1)
			entry = func
		else
			printf "The analysis function \"%s\" referenced in the stimset \"%s\" could not be found.\r", func, stimset
			ControlWindowToFront()
			entry = NONE
		endif
	endif

	SetPopupMenuString(win, ctrl, entry)
End

static Function WBP_UpdateEpochControls()

	variable currentEpoch, numEpochs

	WAVE SegWvType = GetSegmentTypeWave()
	currentEpoch = GetSetVariable("WaveBuilder", "setvar_WaveBuilder_CurrentEpoch")
	numEpochs = SegWvType[100]

	SetVariable setvar_WaveBuilder_CurrentEpoch win=$panel, limits = {0, numEpochs - 1, 1}

	if(currentEpoch >= numEpochs)
		PGC_SetAndActivateControl(panel, "setvar_WaveBuilder_CurrentEpoch", val = numEpochs - 1)
	else
		WBP_UpdatePanelIfAllowed()
	endif
End

Function WBP_SetVarProc_EpochToEdit(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			WAVE SegWvType = GetSegmentTypeWave()
			PGC_SetAndActivateControl(panel, "WBP_WaveType", val = SegWvType[sva.dval])
			break
	endswitch
End

Function WBP_PopupMenu_LoadSet(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string setName

	switch(pa.eventCode)
		case 2: // mouse up
			setName = GetPopupMenuString(panel, "popup_WaveBuilder_SetList")
			WBP_LoadSet(setName)
			break
	endswitch

	return 0
End

static Function WBP_CutOffCrossOver()

	variable HighPassCutOff, LowPassCutOff

	LowPassCutOff = GetSetVariable(panel, "SetVar_WaveBuilder_P20")
	HighPassCutOff = GetSetVariable(panel, "SetVar_WaveBuilder_P22")

	if(!WB_IsValidCutoffFrequency(HighPassCutOff) || !WB_IsValidCutoffFrequency(LowPassCutOff))
		return NaN
	endif

	if(HighPassCutOff >= LowPassCutOff)
		SetSetVariable(panel, "SetVar_WaveBuilder_P22", LowPassCutOff - 1)
	endif
End

/// @brief Checks to see if the pulse duration in square pulse stimulus trains is too long
static Function WBP_ReturnPulseDurationMax()

	variable frequency

	if(GetCheckBoxState(panel, "check_SPT_NumPulses_P46"))
		return Inf
	endif

	frequency = GetSetVariable(panel, "SetVar_WaveBuilder_P6_FD01")

	return 1000 / frequency
End

Function/DF WBP_GetFolderPath()

	ControlInfo/W=$panel group_WaveBuilder_FolderPath
	if(IsEmpty(S_value) || !DataFolderExists(S_value))
		return $"root:"
	else
		return $S_value
	endif
End

Function/S WBP_ReturnFoldersList()

	DFREF dfr = WBP_GetFolderPath()

	return NONE + ";root:;..;" + GetListOfObjects(dfr, ".*", typeFlag = COUNTOBJECTS_DATAFOLDER)
End

Function WBP_PopMenuProc_FolderSelect(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string popStr, path

	switch(pa.eventCode)
		case 2: // mouse up
			popStr = pa.popStr

			if(!CmpStr(popStr, NONE))
				return 0
			elseif(!CmpStr(popStr, "root:"))
				path = "root:"
			else
				ControlInfo/W=$panel group_WaveBuilder_FolderPath

				if(!cmpstr(popStr, ".."))
					path = S_Value + ":"
				else
					path = s_value + popStr + ":"
				endif

				// canonicalize path
				if(DataFolderExists(path))
					path = GetDataFolder(1, $path)
				endif
			endif

			GroupBox group_WaveBuilder_FolderPath win=$panel, title = path
			PopupMenu popup_WaveBuilder_FolderList win=$panel, mode = 1
			PopupMenu popup_WaveBuilder_ListOfWaves win=$panel, mode = 1
			ControlUpdate/W=$panel popup_WaveBuilder_ListOfWaves
			break
	endswitch

	return 0
End

Function WBP_CheckProc_PreventUpdate(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			WBP_UpdatePanelIfAllowed()
			break
	endswitch
End

Function WBP_PopupMenu(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch(pa.eventCode)
		case 2:
			WBP_UpdateControlAndWave(pa.ctrlName, var = pa.popNum - 1)
			WBP_UpdatePanelIfAllowed()
			if(StringMatch(pa.ctrlName, "popup_WaveBuilder_op_*"))
				WBP_AdjustDeltaControls(pa.ctrlName)
			endif
			break
	endswitch

	return 0
End

/// @brief Convert from the row index of a delta related control to a list of control names
static Function/S WBP_ConvertDeltaLblToCtrlNames(allControls, dimLabel)
	string allControls
	string dimLabel

	variable index

	WAVE WP  = GetWaveBuilderWaveParam()
	WAVE WPT = GetWaveBuilderWaveTextParam()
	WAVE SegWvType = GetSegmentTypeWave()

	index = FindDimLabel(WP, ROWS, dimLabel)
	if(index >= 0)
		return GrepList(allControls, ".*_P" + num2str(index) + "(_|$)")
	endif

	index = FindDimLabel(WPT, ROWS, dimLabel)
	if(index >= 0)
		return GrepList(allControls, ".*_T" + num2str(index) + "(_|$)")
	endif

	index = FindDimLabel(SegWvType, ROWS, dimLabel)
	if(index >= 0)
		return GrepList(allControls, ".*_S" + num2str(index) + "(_|$)")
	endif

	ASSERT(0, "Invalid dimLabel")
End

/// @brief Depending on the delta operation the visibility of related controls
/// is adjusted.
///
/// @param control delta operation control name
static Function WBP_AdjustDeltaControls(control)
	string control

	variable deltaMode, index, row
	string allControls, op, delta, dme, ldelta
	string lbl

	row = WBP_ExtractRowNumberFromControl(control)

	switch(WBP_GetWaveTypeFromControl(control))
		case WBP_WAVETYPE_WP:
			WAVE loc = GetWaveBuilderWaveParam()
			break
		case WBP_WAVETYPE_SEGWVTYPE:
			WAVE loc = GetSegmentTypeWave()
			break
		default:
			ASSERT(0, "Invalid control type")
	endswitch

	lbl   = GetDimLabel(loc, ROWS, row)
	lbl   = RemoveEnding(lbl, " op")
	index = FindDimLabel(loc, ROWS, lbl)

	if(index < 0)
		return NaN
	endif

	STRUCT DeltaControlNames s
	WB_GetDeltaDimLabel(loc, index, s)

	allControls = ControlNameList(panel)

	op     = WBP_ConvertDeltaLblToCtrlNames(allControls, s.op)
	delta  = WBP_ConvertDeltaLblToCtrlNames(allControls, s.delta)
	dme    = WBP_ConvertDeltaLblToCtrlNames(allControls, s.dme)
	ldelta = WBP_ConvertDeltaLblToCtrlNames(allControls, s.ldelta)

	deltaMode = GetPopupMenuIndex(panel, control)
	switch(deltaMode)
		case DELTA_OPERATION_DEFAULT:
			EnableControls(panel, delta)
			DisableControls(panel, dme)
			DisableControls(panel, ldelta)
			break
		case DELTA_OPERATION_FACTOR:
			EnableControls(panel, delta)
			EnableControls(panel, dme)
			DisableControls(panel, ldelta)
			break
		case DELTA_OPERATION_LOG:
			EnableControls(panel, delta)
			DisableControls(panel, dme)
			DisableControls(panel, ldelta)
			break
		case DELTA_OPERATION_SQUARED:
			EnableControls(panel, delta)
			DisableControls(panel, dme)
			DisableControls(panel, ldelta)
			break
		case DELTA_OPERATION_POWER:
			EnableControls(panel, delta)
			EnableControls(panel, dme)
			DisableControls(panel, ldelta)
			break
		case DELTA_OPERATION_ALTERNATE:
			EnableControls(panel, delta)
			DisableControls(panel, dme)
			DisableControls(panel, ldelta)
			break
		case DELTA_OPERATION_EXPLICIT:
			DisableControls(panel, delta)
			DisableControls(panel, dme)
			EnableControls(panel, ldelta)
			break
		default:
			ASSERT(0, "Unknown delta mode")
	endswitch
End

Function WBP_ButtonProc_NewSeed(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			NewRandomSeed()
			WBP_UpdateControlAndWave(ba.ctrlName, var = GetReproducibleRandom())
			WBP_UpdatePanelIfAllowed()
			break
	endswitch

	return 0
End

Function WBP_PopupMenu_AnalysisFunctions(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch(pa.eventCode)
		case 2: // mouse up
			WBP_AnaFuncsToWPT()
			break
	endswitch

	return 0
End

static Function WBP_AnaFuncsToWPT()

	variable stimulusType
	string analysisFunction

	if(WBP_GetStimulusType() == CHANNEL_TYPE_TTL)
		return NaN
	endif

	analysisFunction = GetPopupMenuString(panel, "popup_af_generic_S9")
	stimulusType = WBP_GetStimulusType()
	WAVE/T WPT = GetWaveBuilderWaveTextParam()

	WB_SetAnalysisFunctionGeneric(stimulusType, analysisFunction, WPT)

	WBP_UpdateParameterWave()
End

/// Wrapper functions to be used in GUI recreation macros
/// This avoids having to hardcode the parameter values.
/// @{
Function/S WBP_GetAnalysisFunctions_V3()
	return WBP_GetAnalysisFunctions(ANALYSIS_FUNCTION_VERSION_V3)
End
/// @}

/// @brief Return a list of analysis functions including NONE, usable for popup menues
///
/// @sa AFM_GetAnalysisFunctions
Function/S WBP_GetAnalysisFunctions(versionBitMask)
	variable versionBitMask

	return AddListItem(NONE, AFH_GetAnalysisFunctions(versionBitMask))
End

/// @brief Return a list of noise types, usable for popup menues
Function/S WBP_GetNoiseTypes()
	return NOISE_TYPES_STRINGS
End

/// @brief Return a list of build resolutions , usable for popup menues
Function/S WBP_GetNoiseBuildResolution()
	return "1;5;10;20;40;60;80;100"
End

Function WBP_ButtonProc_OpenAnaFuncs(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string userFile, baseName, fileName, func
	variable refNum

	switch(ba.eventCode)
		case 2: // mouse up

			if(TP_GetNumDevicesWithTPRunning() > 0)
				printf "The analysis function procedure window can not be opened when the testpulse is running.\n"
				ControlWindowToFront()
				break
			endif

			func = GetPopupMenuString(panel, "popup_af_generic_S9")

			if(cmpstr(func, NONE))
				DisplayProcedure func
				break
			endif

			baseName = "UserAnalysisFunctions"
			fileName = baseName + ".ipf"
			userFile = GetFolder(FunctionPath("")) + fileName

			if(!FileExists(userFile))
				Open refNum as userFile

				fprintf refNum, "#pragma rtGlobals=3 // Use modern global access method and strict wave access.\n"
				fprintf refNum, "\n"
				fprintf refNum, "// This file can be used for user analysis functions.\n"
				fprintf refNum, "// It will not be overwritten by MIES on an upgrade.\n"
				Close refNum
			endif
			Execute/P/Q/Z "INSERTINCLUDE \"" + baseName + "\""
			Execute/P/Q/Z "COMPILEPROCEDURES "
			Execute/P/Q/Z "DisplayProcedure/W=$\"" + fileName + "\""
			break
	endswitch

	return 0
End

Function WBP_SetVarCombineEpochFormula(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	struct FormulaProperties fp
	string win, formula
	variable currentEpoch, lastSweep

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			win     = sva.win
			formula = sva.sval

			WAVE/T WPT = GetWaveBuilderWaveTextParam()

			lastSweep = GetSetVariable(win, "SetVar_WB_SweepCount_S101") - 1

			if(WB_ParseCombinerFormula(formula, lastSweep, fp))
				break
			endif

			currentEpoch = GetSetVariable(win, "setvar_WaveBuilder_CurrentEpoch")

			WPT[6][currentEpoch][EPOCH_TYPE_COMBINE] = WBP_TranslateControlContents(sva.ctrlName, FROM_PANEL_TO_WAVE, formula)
			WPT[7][currentEpoch][EPOCH_TYPE_COMBINE] = WAVEBUILDER_COMBINE_FORMULA_VER

			WBP_UpdatePanelIfAllowed()
			break
	endswitch

	return 0
End

/// @brief Convert a control entry for the panel or the wave.
///
/// Useful if the visualization is different from the stored data.
///
/// @param control   name of WaveBuilder GUI control
/// @param direction one of #FROM_PANEL_TO_WAVE or #FROM_WAVE_TO_PANEL
/// @param data      string to convert
static Function/S WBP_TranslateControlContents(control, direction, data)
	string control, data
	variable direction

	strswitch(control)
		case "setvar_combine_formula_T6":
			if(direction == FROM_PANEL_TO_WAVE)
				struct FormulaProperties fp
				WB_FormulaSwitchToStimset(data, fp)
				return fp.formula
			elseif(direction == FROM_WAVE_TO_PANEL)
				return WB_FormulaSwitchToShorthand(data)
			endif
			break
		default:
			return data
			break
	endswitch
End

/// @brief Wavebuilder panel window hook
///
/// The epoch selection is done on the mouseup event if there exists no marquee.
/// This allows to still use the zooming capability.
Function WBP_MainWindowHook(s)
	STRUCT WMWinHookStruct &s

	string win
	variable numEntries, i, loc
	string controls, ctrl, name
	variable row, found

	switch(s.eventCode)
		case 2:
			KillOrMoveToTrash(dfr = GetWaveBuilderDataPath())
			break
#ifdef DEBUGGING_ENABLED
		case 4:
			win = s.winName

			if(DP_DebuggingEnabledForCaller())
				controls = ControlNameList(win)
				numEntries = ItemsInList(controls)
				for(i = 0; i < numEntries; i += 1)
					ctrl = StringFromList(i, controls)

					if(IsControlDisabled(win, ctrl))
						continue
					endif

					if(!cmpstr(ctrl, "WBP_WaveType"))
						continue
					endif

					STRUCT RectF ctrlRect
					GetControlCoordinates(win, ctrl, ctrlRect)

					if(!IsInsideRect(s.mouseLoc, ctrlRect))
						continue
					endif

					row = WBP_ExtractRowNumberFromControl(ctrl)

					switch(WBP_GetWaveTypeFromControl(ctrl))
						case WBP_WAVETYPE_WP:
							WAVE WP = GetWaveBuilderWaveParam()
							name = GetDimLabel(WP, ROWS, row)
							break
						case WBP_WAVETYPE_WPT:
							WAVE/T WPT = GetWaveBuilderWaveTextParam()
							name = GetDimLabel(WPT, ROWS, row)
							break
						case WBP_WAVETYPE_SEGWVTYPE:
							WAVE SegWvType = GetSegmentTypeWave()
							name = GetDimLabel(SegWvType, ROWS, row)
							break
						default:
							name = "unknown type"
							break
					endswitch

					printf "%s -> %s\r", ctrl, 	name
				endfor
			endif
			break
#endif
		case 5:
			win = s.winName

			if(cmpstr(win, WaveBuilderGraph))
				break
			endif

			GetAxis/Q/W=$WaveBuilderGraph bottom
			if(V_Flag)
				break
			endif

			loc = AxisValFromPixel(WaveBuilderGraph, "bottom", s.mouseLoc.h)

			if(loc < V_min || loc > V_max)
				break
			endif

			GetMarquee/W=$WaveBuilderGraph/Z
			if(V_flag)
				break
			endif

			WAVE epochID = GetEpochID()
			numEntries = DimSize(epochID, ROWS)
			for(i = 0; i < numEntries; i += 1)
				if(epochID[i][%timeBegin] < loc && epochID[i][%timeEnd] > loc)

					if(GetSetVariable(panel, "setvar_WaveBuilder_CurrentEpoch") == i)
						return 0
					endif

					PGC_SetAndActivateControl(panel, "setvar_WaveBuilder_CurrentEpoch", val = i)
					return 1
				endif
			endfor
		break
	endswitch

	return 0
End

Function/S WBP_GetFFTSpectrumPanel()
	return panel + "#fftSpectrum"
End

Function WBP_ShowFFTSpectrumIfReq(segmentWave, sweep)
	WAVE segmentWave
	variable sweep

	DEBUGPRINT("sweep=", var=sweep)

	string extPanel, graphMag, graphPhase, trace
	STRUCT RGBColor s

	if(!WindowExists(panel))
		return NaN
	endif

	extPanel = WBP_GetFFTSpectrumPanel()

	if(GetTabID(panel, "WBP_WaveType") != EPOCH_TYPE_NOISE)
		KillWindow/z $extPanel
		return NaN
	endif

	if(DimSize(segmentWave, ROWS) == 0)
		return NaN
	endif

	ASSERT(IsInteger(sweep), "Expected an integer sweep value")

	DFREF dfr = GetWaveBuilderDataPath()

	Duplicate/FREE segmentWave, input

	ASSERT(!cmpstr(WaveUnits(input, ROWS), "ms"), "Unexpected data units for row dimension")
	SetScale/P x 0, WAVEBUILDER_MIN_SAMPINT/1000, "s", input
	FFT/FREE/DEST=cmplxFFT input

	MultiThread cmplxFFT = r2polar(cmplxFFT)

	Duplicate/O cmplxFFT dfr:$(SEGMENTWAVE_SPECTRUM_PREFIX + "Mag_" + num2str(sweep))/WAVE=spectrumMag
	Redimension/R spectrumMag

	MultiThread spectrumMag = 20 * log(real(cmplxFFT[p]))
	SetScale y, 0, 0, "dB", spectrumMag

	Duplicate/O cmplxFFT dfr:$(SEGMENTWAVE_SPECTRUM_PREFIX + "Phase_" + num2str(sweep))/WAVE=spectrumPhase
	Redimension/R spectrumPhase

	MultiThread spectrumPhase = imag(cmplxFFT[p]) * 180 / Pi
	SetScale y, 0, 0, "deg", spectrumPhase

	if(!WindowExists(extPanel))
		SetActiveSubwindow $panel
		NewPanel/HOST=#/EXT=0/W=(0,0,460,638)
		ModifyPanel fixedSize=1
		Display/W=(10,10,450,330)/HOST=#
		RenameWindow #,magnitude
		SetActiveSubwindow ##
		Display/W=(10,330,450,629)/HOST=#
		RenameWindow #,phase
		SetActiveSubwindow ##
		RenameWindow #,fftSpectrum
		SetActiveSubwindow ##
	endif

	graphMag   = extPanel + "#magnitude"
	graphPhase = extPanel + "#phase"

	WAVE axesRangesMag   = GetAxesRanges(graphMag)
	WAVE axesRangesPhase = GetAxesRanges(graphPhase)
	WAVE/T/Z cursorInfosMag = GetCursorInfos(graphMag)
	WAVE/T/Z cursorInfosPhase = GetCursorInfos(graphPhase)

	if(sweep == 0)
		RemoveTracesFromGraph(graphMag)
		RemoveTracesFromGraph(graphPhase)
	endif

	trace = "sweep_" + num2str(sweep)

	AppendToGraph/W=$graphMag spectrumMag/TN=$trace
	ModifyGraph/W=$graphMag log(bottom)=1
	ModifyGraph/W=$graphMag mode=4

	AppendToGraph/W=$graphPhase spectrumPhase/TN=$trace
	ModifyGraph/W=$graphPhase log(bottom)=1
	ModifyGraph/W=$graphPhase mode=4

	[s] = WBP_GetSweepColor(sweep)
	ModifyGraph/W=$graphMag rgb($trace)   = (s.red, s.green, s.blue)
	ModifyGraph/W=$graphPhase rgb($trace) = (s.red, s.green, s.blue)

	SetAxesRanges(graphMag, axesRangesMag)
	SetAxesRanges(graphPhase, axesRangesPhase)
	RestoreCursors(graphMag, cursorInfosMag)
	RestoreCursors(graphPhase, cursorInfosPhase)
End

/// @brief Return distinct colors the sweeps of the wavebuilder
///
/// These are backwards compared to the trace colors
static Function [STRUCT RGBColor s] WBP_GetSweepColor(variable sweep)

	[s] = GetTraceColor(20 - mod(sweep, 20))
End

/// @brief Delete the given analysis parameter
///
/// @param name    name of the parameter
static Function WBP_DeleteAnalysisParameter(name)
	string name

	string params

	WAVE/T WPT = GetWaveBuilderWaveTextParam()

	params = WPT[%$"Analysis function params (encoded)"][%Set][INDEP_EPOCH_TYPE]
	params = AFH_RemoveAnalysisParameter(name, params)
	WPT[%$"Analysis function params (encoded)"][%Set][INDEP_EPOCH_TYPE] = params
End

/// @brief Return a list of all possible analysis parameter types
Function/S WBP_GetParameterTypes()

	return ANALYSIS_FUNCTION_PARAMS_TYPES
End

/// @brief Return the analysis parameters
static Function/S WBP_GetAnalysisParameters()

	WAVE/T WPT = GetWaveBuilderWaveTextParam()

	return WPT[%$"Analysis function params (encoded)"][%Set][INDEP_EPOCH_TYPE]
End

static Function/S WBP_GetAnalysisGenericFunction()

	WAVE/T WPT = GetWaveBuilderWaveTextParam()

	return WPT[%$("Analysis function (generic)")][%Set][INDEP_EPOCH_TYPE]
End

/// @brief Return the analysis parameter names for the currently
///        selected stimset
Function/S WBP_GetAnalysisParameterNames()

	string params = WBP_GetAnalysisParameters()

	if(IsEmpty(params))
		return NONE
	endif

	return NONE + ";" + AFH_GetListOfAnalysisParamNames(params)
End

/// @brief Fill the listwave from the stimset analysis
///        parameters extracted from its WPT
static Function WBP_UpdateParameterWave()

	string params, names, name, type, genericFunc, suggParams
	string missingParams, suggNames, reqNames, help
	variable i, numEntries, offset

	Wave/T listWave = WBP_GetAnalysisParamGUIListWave()
	WAVE   selWave  = WBP_GetAnalysisParamGUISelWave()
	WAVE/T helpWave = WBP_GetAnalysisParamGUIHelpWave()

	genericFunc = WBP_GetAnalysisGenericFunction()

	suggParams = AFH_GetListOfAnalysisParams(genericFunc, REQUIRED_PARAMS | OPTIONAL_PARAMS)
	suggNames = AFH_GetListOfAnalysisParamNames(suggParams)

	reqNames = AFH_GetListOfAnalysisParamNames(AFH_GetListOfAnalysisParams(genericFunc, REQUIRED_PARAMS))

	params = WBP_GetAnalysisParameters()
	names  = AFH_GetListOfAnalysisParamNames(params)

	numEntries = ItemsInList(names)
	Redimension/N=(numEntries, -1) listWave, selWave, helpWave

	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, names)
		listWave[i][%Name]     = name
		listWave[i][%Type]     = AFH_GetAnalysisParamType(name, params)
		listWave[i][%Value]    = URLDecode(AFH_GetAnalysisParameter(name, params))
		listWave[i][%Required] = ToTrueFalse(WhichListItem(name, reqNames) != -1)
	endfor

	offset = DimSize(listWave, ROWS)

	missingParams = GetListDifference(suggNames, names)
	numEntries = ItemsInList(missingParams)
	Redimension/N=(offset + numEntries, -1) listWave, selWave, helpWave

	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, missingParams)
		listWave[offset + i][%Name]     = name
		listWave[offset + i][%Type]     = AFH_GetAnalysisParamType(name, suggParams, typeCheck = 0)
		listWave[offset + i][%Required] = ToTrueFalse(WhichListItem(name, reqNames) != -1)
	endfor

	listWave[][%Help] = ""
	helpWave[][] = ""

	numEntries = DimSize(listWave, ROWS)
	for(i = 0; i < numEntries; i += 1)
		name = listWave[i][%Name]

		if(WhichListItem(name, suggNames) != -1)
			help = AFH_GetHelpForAnalysisParameter(genericFunc, name)
			listWave[i][%Help] = help
			helpWave[i][%Help] = LineBreakingIntoPar(help, minimumWidth = 40)
		endif
	endfor
End

/// @brief Toggle the analysis parameter GUI
///
/// @return one if the panel was killed, zero if it was created
static Function WBP_ToggleAnalysisParamGUI()

	if(WindowExists(AnalysisParamGUI))
		KillWindow $AnalysisParamGUI
		return 1
	endif

	Wave/T listWave = WBP_GetAnalysisParamGUIListWave()
	WAVE   selWave  = WBP_GetAnalysisParamGUISelWave()
	WAVE/T helpWave = WBP_GetAnalysisParamGUIHelpWave()

	NewPanel/EXT=2/HOST=$panel/N=AnalysisParamGUI/W=(0,0,785,233)/K=2 as " "
	ModifyPanel fixedSize=0
	GroupBox group_main,pos={5.00,11.00},size={365,252}
	GroupBox group_main,userdata(ResizeControlsInfo)= A"!!,?X!!#;=!!#BpJ,hraz!!#](Aon\"Qzzzzzzzzzzzzzz!!#N3Bk1ct<C]MV0`V1R"
	GroupBox group_main,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	GroupBox group_main,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	Button button_delete_parameter,pos={40,232},size={280,25},proc=WBP_ButtonProc_DeleteParam,title="Delete"
	Button button_delete_parameter,help={"Delete the selected parameter"}
	Button button_delete_parameter,userdata(ResizeControlsInfo)= A"!!,D/!!#B\"!!#BF!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#N3Bk1ct<C]MV0`V1R"
	Button button_delete_parameter,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]MF0`V1Rzzzzzzzzz"
	Button button_delete_parameter,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]MF0`V1Rzzzzzzzzzzzz!!!"
	Button button_add_parameter,pos={40,205},size={280,25},proc=WBP_ButtonProc_AddParam,title="Add"
	Button button_add_parameter,help={"Add the parameter with type and value to the stimset"}
	Button button_add_parameter,userdata(ResizeControlsInfo)= A"!!,D/!!#A\\!!#BF!!#=+z!!#](Aon\"Qzzzzzzzzzzzzzz!!#N3Bk1ct<C]MV0`V1R"
	Button button_add_parameter,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]MF0`V1Rzzzzzzzzz"
	Button button_add_parameter,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]MF0`V1Rzzzzzzzzzzzz!!!"
	PopupMenu popup_param_types,pos={136,42},size={100.00,19.00},bodyWidth=70,title="Type:"
	PopupMenu popup_param_types,help={"Choose the parameter type"}
	PopupMenu popup_param_types,mode=4,popvalue="textwave",value= #"WBP_GetParameterTypes()"
	PopupMenu popup_param_types,userdata(ResizeControlsInfo)= A"!!,Fm!!#>6!!#@,!!#<Pz!!#](Aon\"q<C]MP0`V1Rzzzzzzzzzzzz!!#N3Bk1ct<C]MV0`V1R"
	PopupMenu popup_param_types,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]MX0`V1Rzzzzzzzzz"
	PopupMenu popup_param_types,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]MX0`V1Rzzzzzzzzzzzz!!!"
	SetVariable setvar_param_name,pos={15.00,19.00},size={350,18}
	SetVariable setvar_param_name,help={"The parameter name"}
	SetVariable setvar_param_name,value= _STR:""
	SetVariable setvar_param_name,userdata(ResizeControlsInfo)= A"!!,B)!!#<P!!#Bi!!#<Hz!!#N3Bk1ct<C]MP0`V1Rzzzzzzzzzzzz!!#N3Bk1ct<C]MV0`V1R"
	SetVariable setvar_param_name,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	SetVariable setvar_param_name,userdata(ResizeControlsInfo) += A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	ListBox list_params,pos={375,11},size={644,247},proc=WBP_ListBoxProc_AnalysisParams
	ListBox list_params,help={"Visualization of all parameters with types and values"}
	ListBox list_params,listWave=listWave
	ListBox list_params,selWave=selWave
	ListBox list_params,helpWave=helpWave
	ListBox list_params,mode= 4,widths={180, 60, 120, 60, 600}, userColumnResize=1
	ListBox list_params,userdata(ResizeControlsInfo)= A"!!,I!J,hkh!!#D1!!#B1z!!#N3Bk1ct<C]MV0`V1Rzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox list_params,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Duafnzzzzzzzzzzz"
	ListBox list_params,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	DefineGuide UGFR1={FL,0.35, FR},UGFL1={FL,12},UGFT1={FT,68},UGFB1={FB,-78}
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#E<5QF0/J,fQLzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin,userdata(ResizeControlsGuides)=  "UGFR1;UGFL1;UGFT1;UGFB1;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGFR1)=  "NAME:UGFR1;WIN:WaveBuilder#AnalysisParamGUI;TYPE:User;HORIZONTAL:0;POSITION:351.00;GUIDE1:FL;GUIDE2:FR;RELPOSITION:0.339357;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGFL1)=  "NAME:UGFL1;WIN:WaveBuilder#AnalysisParamGUI;TYPE:User;HORIZONTAL:0;POSITION:12.00;GUIDE1:FL;GUIDE2:;RELPOSITION:12;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGFT1)=  "NAME:UGFT1;WIN:WaveBuilder#AnalysisParamGUI;TYPE:User;HORIZONTAL:1;POSITION:68.00;GUIDE1:FT;GUIDE2:;RELPOSITION:68;"
	SetWindow kwTopWin,userdata(ResizeControlsInfoUGFB1)=  "NAME:UGFB1;WIN:WaveBuilder#AnalysisParamGUI;TYPE:User;HORIZONTAL:1;POSITION:199.00;GUIDE1:FB;GUIDE2:;RELPOSITION:-78;"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={785,233,inf,inf}" // sizeLimit requires Igor 7 or later
	NewNotebook /F=0 /N=nb_param_value /W=(16,76,216,120)/FG=(UGFL1,UGFT1,UGFR1,UGFB1) /HOST=# /OPTS=3
	Notebook kwTopWin, defaultTab=20, autoSave= 0, magnification=100
	Notebook kwTopWin font="Lucida Console", fSize=11, fStyle=0, textRGB=(0,0,0)
	SetActiveSubwindow ##

	WBP_UpdateParameterWave()

	return 0
End

Function WBP_ButtonProc_DeleteParam(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	variable numEntries, i

	switch(ba.eventCode)
		case 2: // mouse up
			Wave/T listWave = WBP_GetAnalysisParamGUIListWave()
			WAVE selWave    = WBP_GetAnalysisParamGUISelWave()

			WAVE/Z indizes = FindIndizes(selWave, var = LISTBOX_SELECTED, col = 0, prop = PROP_MATCHES_VAR_BIT_MASK)
			if(!WaveExists(indizes))
				break
			endif

			numEntries = DimSize(indizes, ROWS)

			// map to names which are stable even after deletion
			Make/T/FREE/N=(numEntries) names = listWave[indizes[p]][%Name]

			for(i = 0; i < numEntries; i += 1)
				WBP_DeleteAnalysisParameter(names[i])
			endfor

			WBP_UpdateParameterWave()
			break
	endswitch

	return 0
End

Function WBP_ButtonProc_AddParam(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string win, name, type
	string value

	switch(ba.eventCode)
		case 2: // mouse up
			win  = ba.win
			name = GetSetVariableString(win, "setvar_param_name")
			if(!AFH_IsValidAnalysisParameter(name))
				printf "The parameter name \"%s\" is not valid.\r", name
				ControlWindowToFront()
				break
			endif

			WAVE/T WPT = GetWaveBuilderWaveTextParam()
			type       = GetPopupMenuString(win, "popup_param_types")
			value      = GetNotebookText(win + "#nb_param_value")

			if(IsEmpty(value))
				printf "The parameter \"%s\" has an empty value and is thus not valid.\r", name
				ControlWindowToFront()
				break
			endif

			strswitch(type)
				case "variable":
					WB_AddAnalysisParameterIntoWPT(WPT, name, var = str2numSafe(value))
					break
				case "string":
					WB_AddAnalysisParameterIntoWPT(WPT, name, str = value)
					break
				case "wave":
					WB_AddAnalysisParameterIntoWPT(WPT, name, wv = ListToNumericWave(value, ";"))
					break
				case "textwave":
					WB_AddAnalysisParameterIntoWPT(WPT, name, wv = ListToTextWave(value, ";"))
					break
				default:
					ASSERT(0, "invalid type")
					break
			endswitch

			WBP_UpdateParameterWave()
			SetSetVariableString(win, "setvar_param_name", "")
			ReplaceNoteBookText(win + "#nb_param_value","")
			break
	endswitch

	return 0
End

Function WBP_ButtonProc_OpenAnaParamGUI(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			if(WBP_ToggleAnalysisParamGUI())
				SetControlTitle(panel, "button_toggle_params","Open parameters panel")
			else
				SetControlTitle(panel, "button_toggle_params","Close parameters panel")
			endif
			break
	endswitch

	return 0
End

Function WBP_ListBoxProc_AnalysisParams(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	variable numericValue
	string stimset, win, name, value, params
	string type
	variable row, col

	switch(lba.eventCode)
		case 1: // mouse down
		case 3: // double click
		case 4: // cell selection
		case 5: // cell selection plus shift key

			win = lba.win
			row = lba.row
			col = lba.col
			WAVE/T/Z listWave = lba.listWave
			WAVE/Z selWave = lba.selWave

			if(row < 0 || row >= DimSize(listWave, ROWS))
				break
			endif

			params = WBP_GetAnalysisParameters()
			name   = listWave[row][%Name]

			value = ""
			type  = listWave[row][%Type]
			if(!IsEmpty(type))
				strswitch(type)
					case "variable":
						numericValue = AFH_GetAnalysisParamNumerical(name, params)
						if(!IsNan(numericValue))
							value = num2str(numericValue)
						endif
						break
					case "string":
						value = AFH_GetAnalysisParamTextual(name, params)
						break
					case "wave":
						WAVE/Z wv = AFH_GetAnalysisParamWave(name, params)
						if(WaveExists(wv))
							value = NumericWaveToList(wv, ";")
						endif
						break
					case "textwave":
						WAVE/Z wv = AFH_GetAnalysisParamTextWave(name, params)
						if(WaveExists(wv))
							value = TextWaveToList(wv, ";")
						endif
						break
					default:
						ASSERT(0, "invalid type")
						break
				endswitch

				SetPopupMenuString(win, "popup_param_types", type)
			endif

			SetSetVariableString(win, "setvar_param_name", name)
			ReplaceNoteBookText(win + "#nb_param_value", value)
			break
	endswitch

	return 0
End

Function WBP_ButtonProc_LoadSet(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string setName

	switch(ba.eventCode)
		case 2: // mouse up
			setName = GetPopupMenuString(panel, "popup_WaveBuilder_SetList")
			WBP_LoadSet(setName)
			break
	endswitch

	return 0
End

/// @brief Function to regenerate code for GetEpochParameterNames()
Function/S WBP_RegenerateEpochParameterNamesCode()
	variable i, numEntries
	string list, msg
	string code = ""

	for(i = 0; i < EPOCH_TYPES_TOTAL_NUMBER; i += 1)
		WAVE names = WBP_ListControlsPerStimulusType(i)
		list = GetCodeForWaveContents(names)
		sprintf msg, "Make/T/FREE st_%d = %s\r", i, list
		code += msg
	endfor

	return code
End

/// @brief Return a list of all parameter names of the given epochType
static Function/WAVE WBP_ListControlsPerStimulusType(variable epochType)
	string list, control, tab, hiddenControls
	variable i, numEntries, tabNumber, row, index

	WBP_CreateWaveBuilderPanel()

	WAVE WP    = GetWaveBuilderWaveParam()
	WAVE/T WPT = GetWaveBuilderWaveTextParam()

	Make/FREE/T/N=(MINIMUM_WAVE_SIZE) names
	SetNumberInWaveNote(names, NOTE_INDEX, 0)

	list = ControlNameList(panel)

	switch(epochType)
		case EPOCH_TYPE_COMBINE:
		case EPOCH_TYPE_CUSTOM:
			hiddenControls = HIDDEN_CONTROLS_CUSTOM_COMBINE
			break
		case EPOCH_TYPE_SQUARE_PULSE:
			hiddenControls = HIDDEN_CONTROLS_SQUARE_PULSE
			break
		default:
			hiddenControls = ""
			break
	endswitch

	list = RemoveFromList(hiddenControls, list)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		control = StringFromList(i, list)

		if(!GrepString(control, WP_CONTROL_REGEXP) && !GrepString(control, WPT_CONTROL_REGEXP))
			continue
		endif

		if(GrepString(control, SEGWVTYPE_ALL_CONTROL_REGEXP))
			continue
		endif

		tabNumber = str2num(GetUserData(panel, control, "tabnum"))

		if(tabNumber != epochType && !IsNaN(tabNumber))
			continue
		endif

		row = WBP_ExtractRowNumberFromControl(control)
		ASSERT(IsFinite(row), "Could not find row in: " + control)

		index = GetNumberFromWaveNote(names, NOTE_INDEX)
		EnsureLargeEnoughWave(names, minimumSize = index)

		if(GrepString(control, WP_CONTROL_REGEXP))
			names[index] = GetDimLabel(WP, ROWS, row)
		elseif(GrepString(control, WPT_CONTROL_REGEXP))
			names[index] = GetDimLabel(WPT, ROWS, row)
		endif

		SetNumberInWaveNote(names, NOTE_INDEX, ++index)
	endfor

	Redimension/N=(index) names
	Note/K names

	// additional entries which are not covered by the usual naming scheme
	if(epochType == EPOCH_TYPE_CUSTOM)
		Make/FREE/T additional = {"Custom epoch wave name"}
	else
		Make/FREE/T/N=(0) additional
	endif

	Concatenate/FREE/NP=(ROWS) {names, additional}, all

	WAVE/T unique = GetUniqueEntries(all)

	Sort/LOC unique, unique

	return unique
End

Function/S WBP_GetDeltaModes()

	return WAVEBUILDER_DELTA_MODES
End

Function/S WBP_GetTriggerTypes()

	return WAVEBUILDER_TRIGGER_TYPES
End

Function/S WBP_GetPulseTypes()

	return PULSE_TYPES_STRINGS
End
