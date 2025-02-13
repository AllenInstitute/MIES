#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DAP
#endif // AUTOMATED_TESTING

/// @file MIES_DAEphys.ipf
/// @brief __DAP__ Main data acquisition panel routines

static Constant DATA_ACQU_TAB_NUM = 0
static Constant HARDWARE_TAB_NUM  = 6

static StrConstant COMMENT_PANEL          = "UserComments"
static StrConstant COMMENT_PANEL_NOTEBOOK = "NB"

static StrConstant AMPLIFIER_DEF_FORMAT = "AmpNo %d Chan %d"

//                                   PCIe-6343                                    | PXI-6259                                   | PCIe-6341                                 | USB-6346
static StrConstant NI_DAC_PATTERNS = "AI:32;AO:4;COUNTER:4;DIOPORTS:3;LINES:32,8,8|AI:32;AO:4;COUNTER:2;DIOPORTS:3;LINES:32,8,8|AI:16;AO:2;COUNTER:4;DIOPORTS:3;LINES:8,8,8|AI:8;AO:2;COUNTER:4;DIOPORTS:3;LINES:8,8,8"

static Constant DAP_WAITFORTPANALYSIS_TIMEOUT = 2

static StrConstant SU_DISABLED_CONTROLS = "Popup_Settings_VC_DA;Popup_Settings_VC_AD;Popup_Settings_IC_DA;Popup_Settings_IC_AD;button_Hardware_ClearChanConn;"

/// @brief Creates meta information about coupled CheckBoxes (Radio Button) controls
///        Used for saving/restoring the GUI state
/// @return Free text wave with lists of coupled CheckBox controls
Function/WAVE DAP_GetRadioButtonCoupling()

	Make/FREE/T/N=10 w

	w[0] = "Radio_ClampMode_0;Radio_ClampMode_1;Radio_ClampMode_1IZ;"
	w[1] = "Radio_ClampMode_2;Radio_ClampMode_3;Radio_ClampMode_3IZ;"
	w[2] = "Radio_ClampMode_4;Radio_ClampMode_5;Radio_ClampMode_5IZ;"
	w[3] = "Radio_ClampMode_6;Radio_ClampMode_7;Radio_ClampMode_7IZ;"
	w[4] = "Radio_ClampMode_8;Radio_ClampMode_9;Radio_ClampMode_9IZ;"
	w[5] = "Radio_ClampMode_10;Radio_ClampMode_11;Radio_ClampMode_11IZ;"
	w[6] = "Radio_ClampMode_12;Radio_ClampMode_13;Radio_ClampMode_13IZ;"
	w[7] = "Radio_ClampMode_14;Radio_ClampMode_15;Radio_ClampMode_15IZ;"
	w[8] = "Radio_ClampMode_AllVClamp;Radio_ClampMode_AllIClamp;Radio_ClampMode_AllIZero;"
	w[9] = "check_Settings_Option_3;check_Settings_SetOption_5;"

	return w
End

/// @brief Returns a list of DAC devices for NI devices
/// @return list of NI DAC devices, #NONE if there are none
Function/S DAP_GetNIDeviceList()

	variable i, j, numPattern, numDevices
	string propList
	string devList, pattern, device
	string allDevices = ""

	SVAR globalNIDevList = $GetNIDeviceList()
	devList = globalNIDevList

	if(!isEmpty(devList))
		return devList
	endif

	numPattern = ItemsInList(NI_DAC_PATTERNS, "|")

#if defined(WINDOWS)
	allDevices = HW_NI_ListDevices()
#endif

	numDevices = ItemsInList(allDevices)

	for(i = 0; i < numDevices; i += 1)
		device   = StringFromList(i, allDevices)
		propList = HW_NI_GetPropertyListOfDevices(device)

#ifdef EVIL_KITTEN_EATING_MODE
		devList = AddListItem(device, devList, ";", Inf)
#else
		for(j = 0; j < numPattern; j += 1)
			pattern = StringFromList(j, NI_DAC_PATTERNS, "|")
			if(strsearch(propList, pattern, 0) >= 0)
				if(!IsValidObjectName(device))
					Print "NI device " + device + " has a name that is incompatible for use in MIES. Please change the device name in NI MAX to a simple name, e.g. DeviceX."
				else
					devList = AddListItem(device, devList, ";", Inf)
				endif
			endif
		endfor
#endif // EVIL_KITTEN_EATING_MODE
	endfor

	if(!IsEmpty(devList))
		globalNIDevList = devList
	else
		globalNIDevList = NONE
	endif

	return globalNIDevList
End

/// @brief Returns a list of ITC devices for DAC, #NONE if there are none
Function/S DAP_GetITCDeviceList()

	string devList = ""

	SVAR globalITCDevList = $GetITCDeviceList()
	devList = globalITCDevList

	if(!isEmpty(devList))
		return devList
	endif

#if defined(WINDOWS)
	devList = HW_ITC_ListDevices()
#endif

	if(!IsEmpty(devList))
		globalITCDevList = devList
	else
		globalITCDevList = NONE
	endif

	return globalITCDevList
End

/// @brief Returns a list of SU devices for DAC, #NONE if there are none
Function/S DAP_GetSUDeviceList()

	string devList

	SVAR globalSUDevList = $GetSUDeviceList()
	devList = globalSUDevList

	if(!isEmpty(devList) && CmpStr(devList, NONE))
		return devList
	endif

	WAVE/T devInfo = GetSUDeviceInfo()
	devList = devInfo[%MASTERDEVICE]

	if(!IsEmpty(devList))
		globalSUDevList = devList
	else
		globalSUDevList = NONE
	endif

	return globalSUDevList
End

/// @brief Returns a list of available ITC and NI devices
///
/// @return list of DAC devices
Function/S DAP_GetDACDeviceList()

	string list = NONE
	string devices

	devices = DAP_GetITCDeviceList()

	if(CmpStr(devices, NONE))
		list = AddListItem(devices, list, ";", Inf)
	endif

	devices = DAP_GetNIDeviceList()

	if(CmpStr(devices, NONE))
		list = AddListItem(devices, list, ";", Inf)
	endif

	devices = DAP_GetSUDeviceList()

	if(CmpStr(devices, NONE))
		list = AddListItem(devices, list, ";", Inf)
	endif

	if(!cmpstr(list, NONE))
		DAP_SuggestIssueForAdditionalNIHardware()
	endif

	return list
End

static Function DAP_SuggestIssueForAdditionalNIHardware()

	if(AlreadyCalledOnce(CO_EMPTY_DAC_LIST))
		return NaN
	endif

	printf "There are no devices available for data acquisition. It might be the case that there is NI hardware connected\r"
	printf "which is not recognized by MIES. In this case please file an issue via MIES->\"Report an issue\" which will include all necessary information.\r"
End

/// @brief Restores the base state of the DA_Ephys panel.
/// Useful when adding controls to GUI. Facilitates use of auto generation of GUI code.
/// Useful when template experiment file has been overwritten.
Function DAP_EphysPanelStartUpSettings()

	string device

	variable i
	string   popValue

	device = GetMainWindow(GetCurrentWindow())

	if(!windowExists(device))
		print "The top panel does not exist"
		ControlWindowToFront()
		return NaN
	endif

	DAP_UnlockDevice(device)

	device = GetMainWindow(GetCurrentWindow())

	if(cmpstr(device, BASE_WINDOW_NAME))
		printf "The top window is not named \"%s\"\r", BASE_WINDOW_NAME
		return NaN
	endif

	// remove tools
	HideTools/W=$device/A

	// reset all device dependent controls
	DAP_AdaptPanelForDeviceSpecifics(device, forceEnable = 1)

	SetWindow $device, userData(panelVersion)=""
	SetWindow $device, userdata(Config_FileName)=""
	SetWindow $device, userdata(Config_FileHash)=""

	CheckBox Check_AD_00, WIN=$device, value=0
	CheckBox Check_AD_01, WIN=$device, value=0
	CheckBox Check_AD_02, WIN=$device, value=0
	CheckBox Check_AD_03, WIN=$device, value=0
	CheckBox Check_AD_04, WIN=$device, value=0
	CheckBox Check_AD_05, WIN=$device, value=0
	CheckBox Check_AD_06, WIN=$device, value=0
	CheckBox Check_AD_07, WIN=$device, value=0
	CheckBox Check_AD_08, WIN=$device, value=0
	CheckBox Check_AD_09, WIN=$device, value=0
	CheckBox Check_AD_10, WIN=$device, value=0
	CheckBox Check_AD_11, WIN=$device, value=0
	CheckBox Check_AD_12, WIN=$device, value=0
	CheckBox Check_AD_13, WIN=$device, value=0
	CheckBox Check_AD_14, WIN=$device, value=0
	CheckBox Check_AD_15, WIN=$device, value=0
	CheckBox Check_AD_All, WIN=$device, value=0

	CheckBox Check_DA_00, WIN=$device, value=0
	CheckBox Check_DA_01, WIN=$device, value=0
	CheckBox Check_DA_02, WIN=$device, value=0
	CheckBox Check_DA_03, WIN=$device, value=0
	CheckBox Check_DA_04, WIN=$device, value=0
	CheckBox Check_DA_05, WIN=$device, value=0
	CheckBox Check_DA_06, WIN=$device, value=0
	CheckBox Check_DA_07, WIN=$device, value=0
	CheckBox Check_DA_All, WIN=$device, value=0
	CheckBox Check_DA_AllVClamp, WIN=$device, value=0
	CheckBox Check_DA_AllIClamp, WIN=$device, value=0

	CheckBox Check_TTL_00, WIN=$device, value=0
	CheckBox Check_TTL_01, WIN=$device, value=0
	CheckBox Check_TTL_02, WIN=$device, value=0
	CheckBox Check_TTL_03, WIN=$device, value=0
	CheckBox Check_TTL_04, WIN=$device, value=0
	CheckBox Check_TTL_05, WIN=$device, value=0
	CheckBox Check_TTL_06, WIN=$device, value=0
	CheckBox Check_TTL_07, WIN=$device, value=0
	CheckBox Check_TTL_All, WIN=$device, value=0

	CheckBox Check_DataAcqHS_00, WIN=$device, value=0
	CheckBox Check_DataAcqHS_01, WIN=$device, value=0
	CheckBox Check_DataAcqHS_02, WIN=$device, value=0
	CheckBox Check_DataAcqHS_03, WIN=$device, value=0
	CheckBox Check_DataAcqHS_04, WIN=$device, value=0
	CheckBox Check_DataAcqHS_05, WIN=$device, value=0
	CheckBox Check_DataAcqHS_06, WIN=$device, value=0
	CheckBox Check_DataAcqHS_07, WIN=$device, value=0
	CheckBox Check_DataAcqHS_All, WIN=$device, value=0

	PGC_SetAndActivateControl(device, "ADC", val = 6)
	DoUpdate/W=$device

	SetVariable Gain_AD_00, WIN=$device, value=_NUM:0.00
	SetVariable Gain_AD_01, WIN=$device, value=_NUM:0.00
	SetVariable Gain_AD_02, WIN=$device, value=_NUM:0.00
	SetVariable Gain_AD_03, WIN=$device, value=_NUM:0.00
	SetVariable Gain_AD_04, WIN=$device, value=_NUM:0.00
	SetVariable Gain_AD_05, WIN=$device, value=_NUM:0.00
	SetVariable Gain_AD_06, WIN=$device, value=_NUM:0.00
	SetVariable Gain_AD_07, WIN=$device, value=_NUM:0.00
	SetVariable Gain_AD_08, WIN=$device, value=_NUM:0.00
	SetVariable Gain_AD_09, WIN=$device, value=_NUM:0.00
	SetVariable Gain_AD_10, WIN=$device, value=_NUM:0.00
	SetVariable Gain_AD_11, WIN=$device, value=_NUM:0.00
	SetVariable Gain_AD_12, WIN=$device, value=_NUM:0.00
	SetVariable Gain_AD_13, WIN=$device, value=_NUM:0.00
	SetVariable Gain_AD_14, WIN=$device, value=_NUM:0.00
	SetVariable Gain_AD_15, WIN=$device, value=_NUM:0.00

	SetVariable Gain_DA_00, WIN=$device, value=_NUM:0.00
	SetVariable Gain_DA_01, WIN=$device, value=_NUM:0.00
	SetVariable Gain_DA_02, WIN=$device, value=_NUM:0.00
	SetVariable Gain_DA_03, WIN=$device, value=_NUM:0.00
	SetVariable Gain_DA_04, WIN=$device, value=_NUM:0.00
	SetVariable Gain_DA_05, WIN=$device, value=_NUM:0.00
	SetVariable Gain_DA_06, WIN=$device, value=_NUM:0.00
	SetVariable Gain_DA_07, WIN=$device, value=_NUM:0.00

	popValue = DAP_FormatStimSetPopupValue(CHANNEL_TYPE_DAC)
	PopupMenu Wave_DA_00, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_DA_01, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_DA_02, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_DA_03, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_DA_04, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_DA_05, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_DA_06, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_DA_07, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_DA_All, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_DA_AllVClamp, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_DA_AllIClamp, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue

	SetVariable Scale_DA_00, WIN=$device, value=_NUM:1, limits={-Inf, Inf, 10}
	SetVariable Scale_DA_01, WIN=$device, value=_NUM:1, limits={-Inf, Inf, 10}
	SetVariable Scale_DA_02, WIN=$device, value=_NUM:1, limits={-Inf, Inf, 10}
	SetVariable Scale_DA_03, WIN=$device, value=_NUM:1, limits={-Inf, Inf, 10}
	SetVariable Scale_DA_04, WIN=$device, value=_NUM:1, limits={-Inf, Inf, 10}
	SetVariable Scale_DA_05, WIN=$device, value=_NUM:1, limits={-Inf, Inf, 10}
	SetVariable Scale_DA_06, WIN=$device, value=_NUM:1, limits={-Inf, Inf, 10}
	SetVariable Scale_DA_07, WIN=$device, value=_NUM:1, limits={-Inf, Inf, 10}
	SetVariable Scale_DA_All, WIN=$device, value=_NUM:1, limits={-Inf, Inf, 10}
	SetVariable Scale_DA_AllVClamp, WIN=$device, value=_NUM:1, limits={-Inf, Inf, 10}
	SetVariable Scale_DA_AllIClamp, WIN=$device, value=_NUM:1, limits={-Inf, Inf, 10}

	SetVariable SetVar_DataAcq_Comment, WIN=$device, value=_STR:""

	CheckBox Check_DataAcq1_RepeatAcq, Win=$device, value=1
	CheckBox Check_DataAcq1_DistribDaq, Win=$device, value=0
	CheckBox Check_DataAcq1_dDAQOptOv, Win=$device, value=0

	SetVariable SetVar_DataAcq_ITI, WIN=$device, value=_NUM:0

	SetVariable SetVar_DataAcq_TPDuration, WIN=$device, value=_NUM:10
	SetVariable SetVar_DataAcq_TPBaselinePerc, WIN=$device, value=_NUM:35

	Checkbox Check_TP_SendToAllHS, WIN=$device, value=1

	/// needs to be in sync with GetTPSettings()
	///@{
	WAVE TPSettingsRef = GetTPSettingsFree()
	SetVariable SetVar_DataAcq_TPAmplitude, WIN=$device, value=_NUM:TPSettingsRef[%amplitudeVC][0]
	SetVariable SetVar_DataAcq_TPAmplitudeIC, WIN=$device, value=_NUM:TPSettingsRef[%amplitudeIC][0]

	Checkbox check_DataAcq_AutoTP, WIN=$device, labelBack=0, value=TPSettingsRef[%autoTPEnable][0]
	SetVariable setvar_DataAcq_IinjMax, WIN=$device, value=_NUM:TPSettingsRef[%autoAmpMaxCurrent][0]
	SetVariable setvar_DataAcq_targetVoltage, WIN=$device, value=_NUM:TPSettingsRef[%autoAmpVoltage][0]
	SetVariable setvar_DataAcq_targetVoltageRange, WIN=$device, value=_NUM:TPSettingsRef[%autoAmpVoltageRange][0]
	///@}

	SetVariable setvar_Settings_autoTP_int, WIN=$device, value=_NUM:0
	SetVariable setvar_Settings_autoTP_perc, WIN=$device, value=_NUM:90

	popValue = DAP_FormatStimSetPopupValue(CHANNEL_TYPE_TTL)
	PopupMenu Wave_TTL_00, Win=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_TTL_01, Win=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_TTL_02, Win=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_TTL_03, Win=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_TTL_04, Win=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_TTL_05, Win=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_TTL_06, Win=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_TTL_07, Win=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu Wave_TTL_All, Win=$device, mode=1, userdata(MenuExp)="", value=#popValue

	CheckBox Check_Settings_TrigOut, Win=$device, value=0
	CheckBox Check_Settings_TrigIn, Win=$device, value=0

	SetVariable SetVar_DataAcq_SetRepeats, WIN=$device, value=_NUM:1

	CheckBox Check_Settings_UseDoublePrec, WIN=$device, value=0
	CheckBox Check_Settings_SkipAnalysFuncs, WIN=$device, value=0
	PopupMenu Popup_Settings_SampIntMult, WIN=$device, mode=1

	CheckBox Check_AsyncAD_00, WIN=$device, value=0
	CheckBox Check_AsyncAD_01, WIN=$device, value=0
	CheckBox Check_AsyncAD_02, WIN=$device, value=0
	CheckBox Check_AsyncAD_03, WIN=$device, value=0
	CheckBox Check_AsyncAD_04, WIN=$device, value=0
	CheckBox Check_AsyncAD_05, WIN=$device, value=0
	CheckBox Check_AsyncAD_06, WIN=$device, value=0
	CheckBox Check_AsyncAD_07, WIN=$device, value=0

	SetVariable Gain_AsyncAD_00, WIN=$device, value=_NUM:1
	SetVariable Gain_AsyncAD_01, WIN=$device, value=_NUM:1
	SetVariable Gain_AsyncAD_02, WIN=$device, value=_NUM:1
	SetVariable Gain_AsyncAD_03, WIN=$device, value=_NUM:1
	SetVariable Gain_AsyncAD_04, WIN=$device, value=_NUM:1
	SetVariable Gain_AsyncAD_05, WIN=$device, value=_NUM:1
	SetVariable Gain_AsyncAD_06, WIN=$device, value=_NUM:1
	SetVariable Gain_AsyncAD_07, WIN=$device, value=_NUM:1

	SetVariable Title_AsyncAD_00, WIN=$device, value=_STR:""
	SetVariable Title_AsyncAD_01, WIN=$device, value=_STR:""
	SetVariable Title_AsyncAD_02, WIN=$device, value=_STR:""
	SetVariable Title_AsyncAD_03, WIN=$device, value=_STR:""
	SetVariable Title_AsyncAD_04, WIN=$device, value=_STR:""
	SetVariable Title_AsyncAD_05, WIN=$device, value=_STR:""
	SetVariable Title_AsyncAD_06, WIN=$device, value=_STR:""
	SetVariable Title_AsyncAD_07, WIN=$device, value=_STR:""

	SetVariable Unit_AsyncAD_00, WIN=$device, value=_STR:""
	SetVariable Unit_AsyncAD_01, WIN=$device, value=_STR:""
	SetVariable Unit_AsyncAD_02, WIN=$device, value=_STR:""
	SetVariable Unit_AsyncAD_03, WIN=$device, value=_STR:""
	SetVariable Unit_AsyncAD_04, WIN=$device, value=_STR:""
	SetVariable Unit_AsyncAD_05, WIN=$device, value=_STR:""
	SetVariable Unit_AsyncAD_06, WIN=$device, value=_STR:""
	SetVariable Unit_AsyncAD_07, WIN=$device, value=_STR:""

	CheckBox Radio_ClampMode_0, WIN=$device, value=1, mode=1

	// Sets MIES headstage to V-Clamp
	CheckBox Radio_ClampMode_0, WIN=$device, value=1, mode=1
	CheckBox Radio_ClampMode_1, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_2, WIN=$device, value=1, mode=1
	CheckBox Radio_ClampMode_3, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_4, WIN=$device, value=1, mode=1
	CheckBox Radio_ClampMode_5, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_6, WIN=$device, value=1, mode=1
	CheckBox Radio_ClampMode_7, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_8, WIN=$device, value=1, mode=1
	CheckBox Radio_ClampMode_9, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_10, WIN=$device, value=1, mode=1
	CheckBox Radio_ClampMode_11, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_12, WIN=$device, value=1, mode=1
	CheckBox Radio_ClampMode_13, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_14, WIN=$device, value=1, mode=1
	CheckBox Radio_ClampMode_15, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_1IZ, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_3IZ, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_5IZ, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_7IZ, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_9IZ, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_11IZ, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_13IZ, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_15IZ, WIN=$device, value=0, mode=1

	// clamp mode sub tab
	PGC_SetAndActivateControl(device, "tab_DataAcq_Amp", val = 0)
	PGC_SetAndActivateControl(device, "ADC", val = 6)

	CheckBox Radio_ClampMode_AllVClamp, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_AllIClamp, WIN=$device, value=0, mode=1
	CheckBox Radio_ClampMode_AllIZero, WIN=$device, value=0, mode=1

	CheckBox Check_DataAcq_SendToAllAmp, WIN=$device, value=0

	SetVariable SetVar_Settings_VC_DAgain, WIN=$device, value=_NUM:20
	SetVariable SetVar_Settings_VC_ADgain, WIN=$device, value=_NUM:0.00999999977648258
	SetVariable SetVar_Settings_IC_ADgain, WIN=$device, value=_NUM:0.00999999977648258

	PopupMenu Popup_Settings_VC_DA, WIN=$device, mode=1
	PopupMenu Popup_Settings_VC_AD, WIN=$device, mode=1
	PopupMenu Popup_Settings_IC_AD, WIN=$device, mode=1
	PopupMenu Popup_Settings_HeadStage, WIN=$device, mode=1
	PopupMenu Popup_Settings_IC_DA, WIN=$device, mode=1
	PopupMenu Popup_Settings_IC_DA, WIN=$device, mode=1

	SetVariable SetVar_Settings_IC_DAgain, WIN=$device, value=_NUM:400

	SetVariable Search_DA_00, WIN=$device, value=_STR:""
	SetVariable Search_DA_01, WIN=$device, value=_STR:""
	SetVariable Search_DA_02, WIN=$device, value=_STR:""
	SetVariable Search_DA_03, WIN=$device, value=_STR:""
	SetVariable Search_DA_04, WIN=$device, value=_STR:""
	SetVariable Search_DA_05, WIN=$device, value=_STR:""
	SetVariable Search_DA_06, WIN=$device, value=_STR:""
	SetVariable Search_DA_07, WIN=$device, value=_STR:""
	SetVariable Search_DA_All, WIN=$device, value=_STR:""
	SetVariable Search_DA_AllVClamp, WIN=$device, value=_STR:""
	SetVariable Search_DA_AllIClamp, WIN=$device, value=_STR:""

	SetVariable Search_TTL_00, WIN=$device, value=_STR:""
	SetVariable Search_TTL_01, WIN=$device, value=_STR:""
	SetVariable Search_TTL_02, WIN=$device, value=_STR:""
	SetVariable Search_TTL_03, WIN=$device, value=_STR:""
	SetVariable Search_TTL_04, WIN=$device, value=_STR:""
	SetVariable Search_TTL_05, WIN=$device, value=_STR:""
	SetVariable Search_TTL_06, WIN=$device, value=_STR:""
	SetVariable Search_TTL_07, WIN=$device, value=_STR:""
	SetVariable Search_TTL_All, WIN=$device, value=_STR:""

	popValue = DAP_FormatStimSetPopupValue(CHANNEL_TYPE_DAC)
	PopupMenu IndexEnd_DA_00, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_DA_01, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_DA_02, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_DA_03, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_DA_04, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_DA_05, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_DA_06, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_DA_07, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_DA_All, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_DA_AllVClamp, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_DA_AllICLamp, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue

	popValue = DAP_FormatStimSetPopupValue(CHANNEL_TYPE_TTL)
	PopupMenu IndexEnd_TTL_00, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_TTL_01, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_TTL_02, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_TTL_03, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_TTL_04, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_TTL_05, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_TTL_06, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_TTL_07, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue
	PopupMenu IndexEnd_TTL_All, WIN=$device, mode=1, userdata(MenuExp)="", value=#popValue

	PopupMenu popup_Settings_Amplifier, mode=1, popvalue="- none -"
	// don't make the scope subwindow part of the recreation macro
	CheckBox check_Settings_ShowScopeWindow, WIN=$device, value=0
	SCOPE_KillScopeWindowIfRequest(device)
	CheckBox check_Settings_ShowScopeWindow, WIN=$device, value=1

	CheckBox check_Settings_ITITP, WIN=$device, value=1
	CheckBox check_Settings_TPAfterDAQ, WIN=$device, value=0

	CheckBox Check_Settings_NwbExport, WIN=$device, value=0
	PopupMenu Popup_Settings_NwbVersion, WIN=$device, mode=2, popvalue="2"

	PopupMenu Popup_Settings_DecMethod, mode=2, popvalue="MinMax"

	SetVariable min_AsyncAD_00, WIN=$device, value=_NUM:0
	SetVariable max_AsyncAD_00, WIN=$device, value=_NUM:0
	CheckBox check_AsyncAlarm_00, WIN=$device, value=0

	SetVariable min_AsyncAD_01, WIN=$device, value=_NUM:0
	SetVariable max_AsyncAD_01, WIN=$device, value=_NUM:0
	CheckBox check_AsyncAlarm_01, WIN=$device, value=0

	SetVariable min_AsyncAD_02, WIN=$device, value=_NUM:0
	SetVariable max_AsyncAD_02, WIN=$device, value=_NUM:0
	CheckBox check_AsyncAlarm_02, WIN=$device, value=0

	SetVariable min_AsyncAD_03, WIN=$device, value=_NUM:0
	SetVariable max_AsyncAD_03, WIN=$device, value=_NUM:0
	CheckBox check_AsyncAlarm_03, WIN=$device, value=0

	SetVariable min_AsyncAD_04, WIN=$device, value=_NUM:0
	SetVariable max_AsyncAD_04, WIN=$device, value=_NUM:0
	CheckBox check_AsyncAlarm_04, WIN=$device, value=0

	SetVariable min_AsyncAD_05, WIN=$device, value=_NUM:0
	SetVariable max_AsyncAD_05, WIN=$device, value=_NUM:0
	CheckBox check_AsyncAlarm_05, WIN=$device, value=0

	SetVariable min_AsyncAD_06, WIN=$device, value=_NUM:0
	SetVariable max_AsyncAD_06, WIN=$device, value=_NUM:0
	CheckBox check_AsyncAlarm_06, WIN=$device, value=0

	SetVariable min_AsyncAD_07, WIN=$device, value=_NUM:0
	SetVariable max_AsyncAD_07, WIN=$device, value=_NUM:0
	CheckBox check_AsyncAlarm_07, WIN=$device, value=0

	CheckBox check_DataAcq_RepAcqRandom, WIN=$device, value=0
	CheckBox check_Settings_Option_3, WIN=$device, value=0
	CheckBox check_Settings_ScalingZero, WIN=$device, value=0
	CheckBox check_Settings_SetOption_04, WIN=$device, fColor=(65280, 43520, 0), value=0

	PopupMenu popup_MoreSettings_Devices, WIN=$device, mode=1

	SetVariable SetVar_Sweep, WIN=$device, value=_NUM:0

	SetVariable SetVar_DataAcq_dDAQDelay, WIN=$device, value=_NUM:0
	SetVariable setvar_DataAcq_dDAQOptOvPost, WIN=$device, value=_NUM:0
	SetVariable setvar_DataAcq_dDAQOptOvPre, WIN=$device, value=_NUM:0
	SetVariable SetVar_DataAcq_OnsetDelayUser, WIN=$device, value=_NUM:0
	ValDisplay valdisp_DataAcq_OnsetDelayAuto, WIN=$device, value=_NUM:0
	ValDisplay valdisp_DataAcq_SweepsInSet, WIN=$device, value=_NUM:1
	ValDisplay valdisp_DataAcq_SweepsActiveSet, WIN=$device, value=_NUM:1
	ValDisplay valdisp_DataAcq_TrialsCountdown, WIN=$device, value=_NUM:1
	ValDisplay valdisp_DataAcq_ITICountdown, WIN=$device, value=_NUM:0

	SetVariable SetVar_DataAcq_TerminationDelay, WIN=$device, value=_NUM:0

	CheckBox check_Settings_SetOption_5, WIN=$device, value=1
	CheckBox Check_DataAcq1_IndexingLocked, WIN=$device, value=0
	CheckBox Check_DataAcq_Indexing, WIN=$device, value=0

	SetVariable SetVar_DataAcq_ListRepeats, WIN=$device, limits={1, Inf, 1}, value=_NUM:1

	SetVariable setvar_Settings_TPBuffer, WIN=$device, value=_NUM:1

	CheckBox check_DataAcq_IndexRandom, WIN=$device, fColor=(65280, 43520, 0), value=0

	ValDisplay ValDisp_DataAcq_SamplingInt, win=$device, value=_NUM:0

	SetVariable SetVar_Hardware_VC_DA_Unit, WIN=$device, value=_STR:"mV"
	SetVariable SetVar_Hardware_IC_DA_Unit, WIN=$device, value=_STR:"pA"
	SetVariable SetVar_Hardware_VC_AD_Unit, WIN=$device, value=_STR:"pA"
	SetVariable SetVar_Hardware_IC_AD_Unit, WIN=$device, value=_STR:"mV"

	SetVariable Unit_DA_00, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_DA_01, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_DA_02, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_DA_03, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_DA_04, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_DA_05, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_DA_06, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_DA_07, WIN=$device, limits={0, Inf, 1}, value=_STR:""

	SetVariable Unit_AD_00, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_01, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_02, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_03, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_04, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_05, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_06, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_07, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_08, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_09, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_10, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_11, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_12, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_13, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_14, WIN=$device, limits={0, Inf, 1}, value=_STR:""
	SetVariable Unit_AD_15, WIN=$device, limits={0, Inf, 1}, value=_STR:""

	SetVariable SetVar_DataAcq_Hold_IC, WIN=$device, value=_NUM:0
	SetVariable Setvar_DataAcq_PipetteOffset_VC, WIN=$device, value=_NUM:0
	SetVariable Setvar_DataAcq_PipetteOffset_IC, WIN=$device, value=_NUM:0
	SetVariable SetVar_DataAcq_BB, WIN=$device, limits={0, Inf, 1}, value=_NUM:0
	SetVariable SetVar_DataAcq_CN, WIN=$device, limits={-8, 16, 1}, value=_NUM:0

	CheckBox check_DatAcq_HoldEnable, WIN=$device, value=0
	CheckBox check_DatAcq_RsCompEnable, WIN=$device, value=0
	CheckBox check_DatAcq_CNEnable, WIN=$device, value=0

	Slider slider_DataAcq_ActiveHeadstage, WIN=$device, value=0
	CheckBox check_DataAcq_AutoBias, WIN=$device, value=0

	// auto bias default: -70 plus/minus 0.5 mV @ 200 pA
	SetVariable SetVar_DataAcq_AutoBiasV, WIN=$device, value=_NUM:-70
	SetVariable SetVar_DataAcq_AutoBiasVrange, WIN=$device, value=_NUM:0.5
	SetVariable setvar_DataAcq_IbiasMax, WIN=$device, value=_NUM:200

	// settings tab
	SetVariable setvar_Settings_AutoBiasPerc, WIN=$device, value=_NUM:15
	SetVariable setvar_Settings_AutoBiasInt, WIN=$device, value=_NUM:1

	SetVariable SetVar_DataAcq_Hold_VC, WIN=$device, value=_NUM:0
	CheckBox check_DatAcq_HoldEnableVC, WIN=$device, value=0
	SetVariable SetVar_DataAcq_WCR, WIN=$device, value=_NUM:0
	CheckBox check_DatAcq_WholeCellEnable, WIN=$device, value=0
	SetVariable SetVar_DataAcq_WCC, WIN=$device, value=_NUM:0
	SetVariable SetVar_DataAcq_RsCorr, WIN=$device, value=_NUM:0
	SetVariable SetVar_DataAcq_RsPred, WIN=$device, value=_NUM:0
	CheckBox Check_Settings_AlarmPauseAcq, WIN=$device, value=0
	CheckBox Check_Settings_AlarmAutoRepeat, WIN=$device, value=0
	CheckBox check_Settings_AmpMCCdefault, WIN=$device, value=0
	CheckBox check_Settings_SyncMiesToMCC, WIN=$device, value=0
	CheckBox check_DataAcq_Amp_Chain, WIN=$device, value=0
	CheckBox check_DatAcq_BBEnable, WIN=$device, value=0
	CheckBox check_Settings_MD, WIN=$device, value=1
	EnableControls(device, "check_Settings_MD")
	SetVariable setvar_Settings_TP_RTolerance, WIN=$device, value=_NUM:1
	CheckBox check_Settings_SaveAmpSettings, WIN=$device, value=0
	CheckBox check_Settings_AmpIEQZstep, WIN=$device, value=0
	CheckBox Check_Settings_ITImanualStart, WIN=$device, value=0

	SetControlUserData(device, "Check_Settings_BkgTP", "oldState", "")
	SetControlUserData(device, "Check_Settings_BackgrndDataAcq", "oldState", "")
	SetControlUserData(device, "check_Settings_TP_SaveTP", "oldState", "")

	CheckBox Check_Settings_BkgTP, WIN=$device, value=1
	CheckBox Check_Settings_BackgrndDataAcq, WIN=$device, value=1

	CheckBox Check_Settings_InsertTP, WIN=$device, value=1
	CheckBox Check_DataAcq_Get_Set_ITI, WIN=$device, value=1
	CheckBox check_Settings_TP_SaveTP, WIN=$device, value=0
	CheckBox check_settings_TP_show_steady, WIN=$device, value=1
	CheckBox check_settings_TP_show_peak, WIN=$device, value=1
	CheckBox check_Settings_DisablePressure, WIN=$device, value=0
	CheckBox check_Settings_RequireAmpConn, WIN=$device, value=1
	// Oscilloscope section in setting tab
	CheckBox check_settings_show_power, WIN=$device, value=0
	SetVariable setvar_Settings_OsciUpdInt, win=$device, value=_NUM:500
	SetVariable setvar_Settings_OsciUpdExt, win=$device, value=_NUM:10
	PopupMenu Popup_Settings_OsciUpdMode, WIN=$device, value=DAP_GetOsciUpdModes(), mode=3
	EnableControls(device, "Popup_Settings_OsciUpdMode")

	// defaults are also hardcoded in P_GetPressureDataWaveRef
	// and P_PressureDataTxtWaveRef
	SetPopupMenuVal(device, "popup_Settings_Pressure_dev", list = NONE)
	SetPopupMenuIndex(device, "popup_Settings_Pressure_dev", 0)
	SetPopupMenuIndex(device, "Popup_Settings_Pressure_DA", 0)
	SetPopupMenuIndex(device, "Popup_Settings_Pressure_AD", 0)
	SetPopupMenuIndex(device, "Popup_Settings_Pressure_TTLA", 1)
	SetPopupMenuIndex(device, "Popup_Settings_Pressure_TTLB", 0)
	SetSetVariable(device, "setvar_Settings_Pressure_DAgain", 2)
	SetSetVariable(device, "setvar_Settings_Pressure_ADgain", 0.5)
	SetSetVariableString(device, "SetVar_Hardware_Pressur_DA_Unit", "psi")
	SetSetVariableString(device, "SetVar_Hardware_Pressur_AD_Unit", "psi")
	SetVariable setvar_Settings_InAirP, win=$device, value=_NUM:3.8
	SetVariable setvar_Settings_InBathP, win=$device, value=_NUM:0.55
	SetVariable setvar_Settings_InSliceP, win=$device, value=_NUM:0.2
	SetVariable setvar_Settings_NearCellP, win=$device, value=_NUM:0.6
	SetVariable setvar_Settings_SealStartP, win=$device, value=_NUM:-0.2
	SetVariable setvar_Settings_SealMaxP, win=$device, value=_NUM:-1.4
	SetVariable setvar_Settings_SurfaceHeight, win=$device, value=_NUM:3500
	SetVariable setvar_Settings_SliceSurfHeight, win=$device, value=_NUM:350
	CheckBox check_Settings_DisablePressure, win=$device, value=0
	CheckBox check_DatAcq_ApproachAll, win=$device, value=0
	CheckBox check_DatAcq_BreakInAll, win=$device, value=0
	CheckBox check_DatAcq_SealALl, win=$device, value=0
	CheckBox check_DatAcq_ClearEnable, win=$device, value=0
	CheckBox check_Settings_AmpIEQZstep, win=$device, value=0
	CheckBox check_DatAcq_SealAtm, win=$device, value=0
	CheckBox check_DatAcq_ApproachNear, win=$device, value=0
	CheckBox check_DataAcq_ManPressureAll, win=$device, value=0
	CheckBox check_Settings_SaveAmpSettings, win=$device, value=1
	SetVariable setvar_DataAcq_PPDuration, win=$device, value=_NUM:0, limits={0, 300, 1}
	SetVariable setvar_DataAcq_PPPressure, win=$device, value=_NUM:0, limits={-10, 10, 1}
	SetVariable setvar_DataAcq_SSPressure, win=$device, value=_NUM:0, limits={-10, 10, 1}

	// user pressure
	PGC_SetAndActivateControl(device, "tab_DataAcq_Pressure", val = 0, switchtab = 1)
	PopupMenu popup_Settings_UserPressure, WIN=$device, mode=1, value=#"\"- none -;\""
	EnableControl(device, "popup_Settings_UserPressure")
	PopupMenu Popup_Settings_UserPressure_ADC, WIN=$device, mode=1
	EnableControl(device, "Popup_Settings_UserPressure_ADC")
	EnableControl(device, "button_Hardware_PUser_Enable")
	DisableControl(device, "button_Hardware_PUser_Disable")
	PGC_SetAndActivateControl(device, "ADC", val = 6)

	ValDisplay valdisp_DataAcq_P_LED_0, WIN=$device, value=_NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_1, WIN=$device, value=_NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_2, WIN=$device, value=_NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_3, WIN=$device, value=_NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_4, WIN=$device, value=_NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_5, WIN=$device, value=_NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_6, WIN=$device, value=_NUM:-1
	ValDisplay valdisp_DataAcq_P_LED_7, WIN=$device, value=_NUM:-1

	ValDisplay valdisp_DataAcq_P_LED_0, limits={-1, 2, 0}, barmisc={0, 0}, mode=2, highColor=(65535, 49000, 49000), lowColor=(65535, 65535, 65535), zeroColor=(49151, 53155, 65535)
	ValDisplay valdisp_DataAcq_P_LED_1, limits={-1, 2, 0}, barmisc={0, 0}, mode=2, highColor=(65535, 49000, 49000), lowColor=(65535, 65535, 65535), zeroColor=(49151, 53155, 65535)
	ValDisplay valdisp_DataAcq_P_LED_2, limits={-1, 2, 0}, barmisc={0, 0}, mode=2, highColor=(65535, 49000, 49000), lowColor=(65535, 65535, 65535), zeroColor=(49151, 53155, 65535)
	ValDisplay valdisp_DataAcq_P_LED_3, limits={-1, 2, 0}, barmisc={0, 0}, mode=2, highColor=(65535, 49000, 49000), lowColor=(65535, 65535, 65535), zeroColor=(49151, 53155, 65535)
	ValDisplay valdisp_DataAcq_P_LED_4, limits={-1, 2, 0}, barmisc={0, 0}, mode=2, highColor=(65535, 49000, 49000), lowColor=(65535, 65535, 65535), zeroColor=(49151, 53155, 65535)
	ValDisplay valdisp_DataAcq_P_LED_5, limits={-1, 2, 0}, barmisc={0, 0}, mode=2, highColor=(65535, 49000, 49000), lowColor=(65535, 65535, 65535), zeroColor=(49151, 53155, 65535)
	ValDisplay valdisp_DataAcq_P_LED_6, limits={-1, 2, 0}, barmisc={0, 0}, mode=2, highColor=(65535, 49000, 49000), lowColor=(65535, 65535, 65535), zeroColor=(49151, 53155, 65535)
	ValDisplay valdisp_DataAcq_P_LED_7, limits={-1, 2, 0}, barmisc={0, 0}, mode=2, highColor=(65535, 49000, 49000), lowColor=(65535, 65535, 65535), zeroColor=(49151, 53155, 65535)

	ValDisplay valdisp_DataAcq_P_0, valueBackColor=(65535, 65535, 65535, 0)
	ValDisplay valdisp_DataAcq_P_0, limits={0, 0, 0}, barmisc={0, 1000}, value=#"0.00"
	ValDisplay valdisp_DataAcq_P_1, valueBackColor=(65535, 65535, 65535, 0)
	ValDisplay valdisp_DataAcq_P_1, limits={0, 0, 0}, barmisc={0, 1000}, value=#"0.00"
	ValDisplay valdisp_DataAcq_P_2, valueBackColor=(65535, 65535, 65535, 0)
	ValDisplay valdisp_DataAcq_P_2, limits={0, 0, 0}, barmisc={0, 1000}, value=#"0.00"
	ValDisplay valdisp_DataAcq_P_3, valueBackColor=(65535, 65535, 65535, 0)
	ValDisplay valdisp_DataAcq_P_3, limits={0, 0, 0}, barmisc={0, 1000}, value=#"0.00"
	ValDisplay valdisp_DataAcq_P_4, valueBackColor=(65535, 65535, 65535, 0)
	ValDisplay valdisp_DataAcq_P_4, limits={0, 0, 0}, barmisc={0, 1000}, value=#"0.00"
	ValDisplay valdisp_DataAcq_P_5, valueBackColor=(65535, 65535, 65535, 0)
	ValDisplay valdisp_DataAcq_P_5, limits={0, 0, 0}, barmisc={0, 1000}, value=#"0.00"
	ValDisplay valdisp_DataAcq_P_6, valueBackColor=(65535, 65535, 65535, 0)
	ValDisplay valdisp_DataAcq_P_6, limits={0, 0, 0}, barmisc={0, 1000}, value=#"0.00"
	ValDisplay valdisp_DataAcq_P_7, valueBackColor=(65535, 65535, 65535, 0)
	ValDisplay valdisp_DataAcq_P_7, limits={0, 0, 0}, barmisc={0, 1000}, value=#"0.00"

	ValDisplay valdisp_DataAcq_P_LED_Approach, WIN=$device, value=_NUM:0
	ValDisplay valdisp_DataAcq_P_LED_Seal, WIN=$device, value=_NUM:0
	ValDisplay valdisp_DataAcq_P_LED_Breakin, WIN=$device, value=_NUM:0
	ValDisplay valdisp_DataAcq_P_LED_Clear, WIN=$device, value=_NUM:0

	CheckBox check_Settings_UserP_Approach, WIN=$device, value=0
	CheckBox check_Settings_UserP_BreakIn, WIN=$device, value=0
	CheckBox check_Settings_UserP_Seal, WIN=$device, value=0
	CheckBox check_Settings_UserP_Clear, WIN=$device, value=0
	CheckBox check_DataACq_Pressure_AutoOFF, WIN=$device, value=0
	CheckBox check_DataACq_Pressure_User, WIN=$device, value=0
	CheckBox check_DA_applyOnModeSwitch, WIN=$device, value=0

	PopupMenu Popup_Settings_SampIntMult, WIN=$device, mode=1
	PopupMenu Popup_Settings_FixedFreq, WIN=$device, mode=1
	EnableControls(device, "Popup_Settings_SampIntMult;Popup_Settings_FixedFreq")

	SetVariable setvar_dataAcq_skipAhead, win=$device, limits={0, 0, 1}, value=_NUM:0
	EnableControl(device, "button_Hardware_P_Enable")
	DisableControl(device, "button_Hardware_P_Disable")
	EnableControls(device, "Button_DataAcq_SkipBackwards;Button_DataAcq_SkipForward")

	SetDrawLayer/K UserBack

	SearchForInvalidControlProcs(device)

	Execute/P/Z "DoWindow/R " + BASE_WINDOW_NAME
	Execute/P/Q/Z "COMPILEPROCEDURES "
	CleanupOperationQueueResult()
End

Function DAP_WindowHook(STRUCT WMWinHookStruct &s)

	string device, ctrl
	variable sgn, i

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_KILL:
			device = s.winName

			NVAR JSONid = $GetSettingsJSONid()
			PS_StoreWindowCoordinate(JSONid, device)

			AssertOnAndClearRTError()
			try
				// catch all error conditions, asserts and aborts
				// and silently ignore them
				DAP_UnlockDevice(device); AbortOnRTE
			catch
				ClearRTError()
			endtry

			// return zero so that other hooks are called as well
			break
		case EVENT_WINDOW_HOOK_MOUSEWHEEL:
			device = s.winName

			if(GetTabID(device, "ADC") != DATA_ACQU_TAB_NUM)
				break
			endif

			for(i = 0; i < NUM_HEADSTAGES; i += 1)
				ctrl = StringFromList(i, PRESSURE_CONTROL_LED_DASHBOARD)

				STRUCT RectF ctrlRect
				GetControlCoordinates(device, ctrl, ctrlRect)

				// help the user by allowing some more vertical space
				ctrlRect.top    -= 20
				ctrlRect.bottom += 20

				if(IsInsideRect(s.mouseLoc, ctrlRect))
					P_SetPressureOffset(s.winName, i, 0.1 * sign(s.wheelDy))
					break
				endif
			endfor
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Return a popValue string suitable for stimsets
/// @todo rework the code to have a fixed popValue
Function/S DAP_FormatStimSetPopupValue(variable channelType, [string searchString])

	if(ParamIsDefault(searchString))
		searchString = "*"
	endif

	string str
	sprintf str, "\"%s;\"+ST_GetStimsetList(channelType = %d, searchString = \"%s\")", NONE, channelType, searchString

	return str
End

static Function DAP_UpdateDrawElements(string device, variable tab)

	SetDrawLayer/W=$device/K ProgBack

	switch(tab)
		case 0: // Daa acqusition
			SetDrawEnv/W=$device textrot=-90
			DrawText/W=$device 167, 441, "All HS"

			break
		default:
			// do nothing
			break
	endswitch
End

/// @brief Called by ACL tab control after the tab is updated.
/// see line 257 of ACL_TabUtilities.ipf
Function DAP_TabControlFinalHook(STRUCT WMTabControlAction &tca)

	string win

	win = tca.win

	DAP_UpdateDrawElements(win, tca.tab)

	if(DAP_DeviceIsUnLocked(win))
		print "Please lock the panel to a DAC in the Hardware tab"
		ControlWindowToFront()
		return 0
	endif

	return 0
End

Function DAP_SetVarProc_Channel_Search(STRUCT WMSetVariableAction &sva) : SetVariableControl

	variable channelIndex, channelType, channelControl
	variable i, isCustomSearchString, numSuppChannels
	string ctrl, searchString, str
	string popupValue, listOfWaves
	string device, varstr, sel

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			device = sva.win
			ctrl   = sva.ctrlName
			varstr = sva.sval

			ASSERT(!DAP_ParsePanelControl(ctrl, channelIndex, channelType, channelControl), "Invalid control format")
			DAG_Update(sva.win, sva.ctrlName, val = sva.dval, str = sva.sval)

			if(isEmpty(varstr))
				searchString = "*"
			else
				isCustomSearchString = 1
				searchString         = varStr
			endif

			listOfWaves = ST_GetStimsetList(channelType = channelType, searchString = searchString)
			popupValue  = DAP_FormatStimSetPopupValue(channelType, searchString = searchString)

			ctrl = GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_WAVE)
			PopupMenu $ctrl, win=$device, value=#popupValue, userdata($USER_DATA_MENU_EXP)=listOfWaves
			sel = GetPopupMenuString(device, ctrl)
			PopupMenu $ctrl, win=$device, popmatch=sel

			ctrl = GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_INDEX_END)
			PopupMenu $ctrl, win=$device, value=#popupValue
			sel = GetPopupMenuString(device, ctrl)
			PopupMenu $ctrl, win=$device, popmatch=sel

			if(DAP_IsAllControl(channelIndex))
				numSuppChannels = GetNumberFromType(var = channelType)
				for(i = 0; i < numSuppChannels; i += 1)

					if(!DAP_DACHasExpectedClampMode(device, channelIndex, i, channelType))
						continue
					endif

					ctrl = GetPanelControl(i, channelType, CHANNEL_CONTROL_SEARCH)
					str  = SelectString(isCustomSearchString, "", searchString)
					PGC_SetAndActivateControl(device, ctrl, str = str, mode = PGC_MODE_SKIP_ON_DISABLED)
					DAG_Update(device, ctrl, str = str)

					ctrl = GetPanelControl(i, channelType, CHANNEL_CONTROL_WAVE)
					PopupMenu $ctrl, win=$device, value=#popupValue, userdata($USER_DATA_MENU_EXP)=listOfWaves
					sel = GetPopupMenuString(device, ctrl)
					PopupMenu $ctrl, win=$device, popmatch=sel

					ctrl = GetPanelControl(i, channelType, CHANNEL_CONTROL_INDEX_END)
					PopupMenu $ctrl, win=$device, value=#popupValue
					sel = GetPopupMenuString(device, ctrl)
					PopupMenu $ctrl, win=$device, popmatch=sel
				endfor
			endif
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_DAorTTLCheckProc(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	string device, control

	switch(cba.eventCode)
		case 2:
			AssertOnAndClearRTError()
			try
				device  = cba.win
				control = cba.ctrlName
				DAG_Update(cba.win, cba.ctrlName, val = cba.checked)
				DAP_AdaptAssocHeadstageState(device, control)
				DAP_UpdateDAQControls(device, REASON_STIMSET_CHANGE | REASON_HEADSTAGE_CHANGE)
			catch
				ClearRTError()
				SetCheckBoxState(device, control, !cba.checked)
				DAG_Update(cba.win, cba.ctrlName, val = !cba.checked)
				Abort
			endtry

			break
		default:
			break
	endswitch
End

Function DAP_CheckProc_Channel_All(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	string device, control, lbl
	variable i, checked, allChecked, channelIndex, channelType, controlType, numEntries

	switch(cba.eventCode)
		case 2: // mouse up
			device     = cba.win
			allChecked = cba.checked
			ASSERT(!DAP_ParsePanelControl(cba.ctrlName, channelIndex, channelType, controlType), "Invalid control format")
			ASSERT(controlType == CHANNEL_CONTROL_CHECK, "Invalid control type")
			ASSERT(DAP_ISAllControl(channelIndex), "Invalid channel index")
			DAG_Update(cba.win, cba.ctrlName, val = cba.checked)

			numEntries = GetNumberFromType(var = channelType)

			lbl = GetSpecialControlLabel(channelType, CHANNEL_CONTROL_CHECK)

			for(i = 0; i < numEntries; i += 1)
				checked = DAG_GetNumericalValue(device, lbl, index = i)

				if(checked == allChecked)
					continue
				endif

				if(!DAP_DACHasExpectedClampMode(device, channelIndex, i, channelType))
					continue
				endif

				control = GetPanelControl(i, channelType, CHANNEL_CONTROL_CHECK)
				PGC_SetAndActivateControl(device, control, val = allChecked, mode = PGC_MODE_SKIP_ON_DISABLED)
			endfor
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Determines if the control refers to an "All" control
Function DAP_IsAllControl(variable channelIndex)

	return channelIndex == CHANNEL_INDEX_ALL            \
	       || channelIndex == CHANNEL_INDEX_ALL_V_CLAMP \
	       || channelIndex == CHANNEL_INDEX_ALL_I_CLAMP
End

/// @brief Helper for "All" controls in the DA tab
///
/// @returns 0 if the given channel is a DA channel and not in the expected
///          clamp mode as determined by `controlChannelIndex`, 1 otherwise
Function DAP_DACHasExpectedClampMode(string device, variable controlChannelIndex, variable channelNumber, variable channelType)

	variable headstage, clampMode

	ASSERT(DAP_IsAllControl(controlChannelIndex), "Invalid controlChannelIndex")

	if(channelType != CHANNEL_TYPE_DAC || controlChannelIndex == CHANNEL_INDEX_ALL)
		return 1 // don't care
	endif

	headstage = AFH_GetHeadstageFromDAC(device, channelNumber)

	if(!IsAssociatedChannel(headstage))
		return 0
	endif

	clampMode = DAG_GetHeadstageMode(device, headStage)

	if(clampMode == V_CLAMP_MODE && controlChannelIndex == CHANNEL_INDEX_ALL_V_CLAMP)
		return 1
	endif

	if(clampMode == I_CLAMP_MODE && controlChannelIndex == CHANNEL_INDEX_ALL_I_CLAMP)
		return 1
	endif

	return 0
End

Function DAP_CheckProc_AD(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	string device, control

	switch(cba.eventCode)
		case 2: // mouse up
			AssertOnAndClearRTError()
			try
				device  = cba.win
				control = cba.ctrlName

				DAG_Update(cba.win, cba.ctrlName, val = cba.checked)
				DAP_AdaptAssocHeadstageState(device, control)
			catch
				ClearRTError()
				SetCheckBoxState(device, control, !cba.checked)
				DAG_Update(cba.win, cba.ctrlName, val = !cba.checked)
				Abort
			endtry

			break
		default:
			break
	endswitch

	return 0
End

/// @brief Get the headstage for the given channel number and type from the amplifier settings
///
/// This is different from what GetChannelClampMode holds as we here hold the
/// setup information and GetChannelClampMode holds what is currently active.
Function GetHeadstageFromSettings(string device, variable channelType, variable channelNumber, variable clampMode)

	variable i, row

	if(!AI_IsValidClampMode(clampMode))
		return NaN
	endif

	WAVE chanAmpAssign = GetChanAmpAssign(device)

	if(channelType == XOP_CHANNEL_TYPE_ADC)
		row = (clampMode == V_CLAMP_MODE) ? 2 : (2 + 4)
	elseif(channelType == XOP_CHANNEL_TYPE_DAC)
		row = (clampMode == V_CLAMP_MODE) ? 0 : (0 + 4)
	else
		ASSERT(0, "Unexpected clamp mode")
	endif

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(chanAmpAssign[row][i] == channelNumber)
			return i
		endif
	endfor

	return NaN
End

/// @brief Adapt the state of the associated headstage on DA/AD channel change
///
static Function DAP_AdaptAssocHeadstageState(string device, string checkboxCtrl)

	string headStageCheckBox
	variable headstage, idx, channelType, controlType
	variable headstageState, headStageFromSettingsVC, headStageFromSettingsIC
	string checkboxLabel, headstageLabel

	DAP_AbortIfUnlocked(device)

	ASSERT(!DAP_ParsePanelControl(checkboxCtrl, idx, channelType, controlType), "Invalid control format")
	ASSERT(CHANNEL_CONTROL_CHECK == controlType, "Not a valid control type")

	if(channelType == CHANNEL_TYPE_DAC)
		headStage               = AFH_GetHeadstageFromDAC(device, idx)
		headStageFromSettingsVC = GetHeadstageFromSettings(device, XOP_CHANNEL_TYPE_DAC, idx, V_CLAMP_MODE)
		headStageFromSettingsIC = GetHeadstageFromSettings(device, XOP_CHANNEL_TYPE_DAC, idx, I_CLAMP_MODE)
	elseif(channelType == CHANNEL_TYPE_ADC)
		headStage               = AFH_GetHeadstageFromADC(device, idx)
		headStageFromSettingsVC = GetHeadstageFromSettings(device, XOP_CHANNEL_TYPE_ADC, idx, V_CLAMP_MODE)
		headStageFromSettingsIC = GetHeadstageFromSettings(device, XOP_CHANNEL_TYPE_ADC, idx, I_CLAMP_MODE)
	elseif(channelType == CHANNEL_TYPE_TTL)
		// nothing to do
		headStageFromSettingsVC = NaN
		headStageFromSettingsIC = NaN
		return NaN
	endif

	if(!IsAssociatedChannel(headStage))
		if(headStageFromSettingsIC == headStageFromSettingsVC)
			// be nice to users and activate the headstage for them
			headStage = headStageFromSettingsIC
		else
			return NaN
		endif
	endif

	checkboxLabel  = GetSpecialControlLabel(channelType, CHANNEL_CONTROL_CHECK)
	headstageLabel = GetSpecialControlLabel(CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
	headstageState = DAG_GetNumericalValue(device, headstageLabel, index = headstage)

	if(DAG_GetNumericalValue(device, checkboxLabel, index = idx) == headstageState)
		// nothing to do
		return NaN
	endif

	headStageCheckBox = GetPanelControl(headstage, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
	PGC_SetAndActivateControl(device, headStageCheckBox, val = !headstageState)
End

/// @brief Return the repeated acquisition cycle ID for the given devide.
static Function DAP_GetRAAcquisitionCycleID(string device)

	DAP_AbortIfUnlocked(device)

	return GetNextRandomNumberForDevice(device)
End

/// @brief One time initialization before data acquisition
///
/// @param device device
/// @param runMode    One of @ref DAQRunModes except DAQ_NOT_RUNNING
Function DAP_OneTimeCallBeforeDAQ(string device, variable runMode)

	variable i, DAC, ADC, hardwareType

	ASSERT(runMode != DAQ_NOT_RUNNING, "Invalid running mode")

	NVAR count = $GetCount(device)
	count = 0

	NVAR activeSetCount = $GetActiveSetCount(device)
	activeSetCount = IDX_CalculcateActiveSetCount(device)

	NVAR repurposeTime = $GetRepurposedSweepTime(device)
	repurposeTime = 0

	NVAR raCycleID = $GetRepeatedAcquisitionCycleID(device)
	raCycleID = DAP_GetRAAcquisitionCycleID(device)

	NVAR fifoPosition = $GetFifoPosition(device)
	fifoPosition = NaN

	WAVE stimsetAcqIDHelper = GetStimsetAcqIDHelperWave(device)
	stimsetAcqIDHelper = NaN

	DAP_ClearDelayedClampModeChange(device)

	WAVE setEventFlag = GetSetEventFlag(device)
	setEventFlag[][%PRE_SET_EVENT] = 1

	if(DAG_GetNumericalValue(device, "Check_DataAcq_Indexing"))
		IDX_StoreStartFinishForIndexing(device)
	endif

	// disable the clamp mode checkboxes of all active headstages
	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		DisableControl(device, GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK))

		DAC = AFH_GetDACFromHeadstage(device, i)

		// DA controls
		DisableControl(device, GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK))
		DisableControl(device, GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN))
		DisableControl(device, GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT))

		ADC = AFH_GetDACFromHeadstage(device, i)

		// AD controls
		DisableControl(device, GetPanelControl(ADC, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK))
		DisableControl(device, GetPanelControl(ADC, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN))
		DisableControl(device, GetPanelControl(ADC, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT))
	endfor

	DisableControls(device, CONTROLS_DISABLE_DURING_DAQ)

	if(DAG_GetNumericalvalue(device, "Check_DataAcq_Indexing"))
		DisableControls(device, CONTROLS_DISABLE_DURING_IDX)
	endif

	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)
	PUB_DAQStateChange(device, DATA_ACQUISITION_MODE, dataAcqRunMode, runMode)
	dataAcqRunMode = runMode

	hardwareType = GetHardwareType(device)
	if(hardwareType == HARDWARE_NI_DAC)
		HW_NI_ResetTaskIDs(device)
	endif

	DAP_ToggleAcquisitionButton(device, DATA_ACQ_BUTTON_TO_STOP)
	DisableControls(device, CONTROLS_DISABLE_DURING_DAQ_TP)

	// turn off active pressure control modes
	if(DAG_GetNumericalValue(device, "check_Settings_DisablePressure"))
		P_SetAllHStoAtmospheric(device)
	endif

	RA_StepSweepsRemaining(device)

	if(DC_GotTPChannelWhileDAQ(device))
		TP_SetupCommon(device)
		P_InitBeforeTP(device)
	endif
End

static Function DAP_ResetClampModeTitle(string device, string ctrl)

	SetControlTitle(device, ctrl, "")
	SetControlTitleColor(device, ctrl, 0, 0, 0)
End

/// @brief Enable all controls which were disabled before DAQ by #DAP_OneTimeCallBeforeDAQ
static Function DAP_ResetGUIAfterDAQ(string device)

	variable i, ADC, DAC

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		EnableControl(device, GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK))

		DAC = AFH_GetDACFromHeadstage(device, i)

		// DA controls
		if(IsFinite(DAC))
			EnableControl(device, GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK))
			EnableControl(device, GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN))
			EnableControl(device, GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT))
		endif

		ADC = AFH_GetDACFromHeadstage(device, i)

		// AD controls
		if(IsFinite(ADC))
			EnableControl(device, GetPanelControl(ADC, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK))
			EnableControl(device, GetPanelControl(ADC, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN))
			EnableControl(device, GetPanelControl(ADC, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT))
		endif

		DAP_ResetClampModeTitle(device, DAP_GetClampModeControl(I_CLAMP_MODE, i))
		DAP_ResetClampModeTitle(device, DAP_GetClampModeControl(V_CLAMP_MODE, i))
		DAP_ResetClampModeTitle(device, DAP_GetClampModeControl(I_EQUAL_ZERO_MODE, i))
	endfor

	EnableControls(device, CONTROLS_DISABLE_DURING_DAQ)
	EnableControls(device, CONTROLS_DISABLE_DURING_IDX)

	DAP_ToggleAcquisitionButton(device, DATA_ACQ_BUTTON_TO_DAQ)

	DAP_HandleSingleDeviceDependentControls(device)
End

/// @brief One time cleaning up after data acquisition
///
/// @param device      device
/// @param stopReason      One of @ref DAQStoppingFlags
/// @param forcedStop      [optional, defaults to false] if DAQ was aborted (true) or stopped by itself (false)
/// @param startTPAfterDAQ [optional, defaults to true]  start "TP after DAQ" if enabled at the end
Function DAP_OneTimeCallAfterDAQ(string device, variable stopReason, [variable forcedStop, variable startTPAfterDAQ])

	variable hardwareType, indexing

	forcedStop      = ParamIsDefault(forcedStop) ? 0 : !!forcedStop
	startTPAfterDAQ = ParamIsDefault(startTPAfterDAQ) ? 1 : !!startTPAfterDAQ

	indexing = DAG_GetNumericalValue(device, "Check_DataAcq_Indexing")

	DAP_ResetGUIAfterDAQ(device)

	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)
	PUB_DAQStateChange(device, DATA_ACQUISITION_MODE, dataAcqRunMode, DAQ_NOT_RUNNING)
	dataAcqRunMode = DAQ_NOT_RUNNING

	// needs to be done before changing the acquisition state
	DAP_DocumentStopReason(device, stopReason)

	AS_HandlePossibleTransition(device, AS_POST_DAQ, call = !forcedStop)

	hardwareType = GetHardwareType(device)
	switch(hardwareType)
		case HARDWARE_NI_DAC:
			HW_NI_ResetTaskIDs(device)
			break
		default:
			// do nothing
			break
	endswitch

	NVAR count = $GetCount(device)
	count = 0

	NVAR activeSetCount = $GetActiveSetCount(device)
	activeSetCount = NaN

	SetValDisplay(device, "valdisp_DataAcq_ITICountdown", var = 0)

	NVAR raCycleID = $GetRepeatedAcquisitionCycleID(device)
	raCycleID = NaN // invalidate

	NVAR fifoPosition = $GetFifoPosition(device)
	fifoPosition = NaN

	// restore the selected sets before DAQ
	if(indexing)
		IDX_ResetStartFinishForIndexing(device)
	endif

	if(DC_GotTPChannelWhileDAQ(device))
		TP_TeardownCommon(device)
	endif

	DAP_ApplyDelayedClampModeChange(device)

	AS_HandlePossibleTransition(device, AS_INACTIVE)

	if(!DAG_GetNumericalValue(device, "check_Settings_TPAfterDAQ") || !startTPAfterDAQ)
		return NaN
	endif

	ASSERT(!IsFunctionCalledRecursively(), "Recursion detected, aborting")

	if(DAG_GetNumericalValue(device, "check_Settings_MD"))
		TPM_StartTestPulseMultiDevice(device)
	else
		TPS_StartTestPulseSingleDevice(device)
	endif
End

static Function DAP_DocumentStopReason(string device, variable stopReason)

	variable sweepNo

	Make/FREE/N=(3, 1)/T keys

	keys[0][0] = "DAQ stop reason"
	keys[1][0] = "" // @todo: use enumeration as unit once available
	keys[2][0] = LABNOTEBOOK_NO_TOLERANCE

	Make/FREE/D/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values = NaN
	values[][][INDEP_HEADSTAGE] = stopReason

	sweepNo = AS_GetSweepNumber(device)
	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, UNKNOWN_MODE)
End

Function DAP_CheckProc_IndexingState(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	string device

	switch(cba.eventCode)
		case 2: // mouse up

			device = cba.win
			DAG_Update(cba.win, cba.ctrlName, val = cba.checked)
			DAP_UpdateDAQControls(device, REASON_STIMSET_CHANGE)

			if(cmpstr(cba.ctrlname, "Check_DataAcq1_IndexingLocked") == 0)
				ToggleCheckBoxes(device, "Check_DataAcq1_IndexingLocked", "check_Settings_SetOption_5", cba.checked)
				EqualizeCheckBoxes(device, "Check_DataAcq1_IndexingLocked", "check_Settings_Option_3", cba.checked)
			endif

			break
		default:
			break
	endswitch

	return 0
End

Function DAP_CheckProc_ShowScopeWin(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	string device

	switch(cba.eventCode)
		case 2: // mouse up
			device = cba.win

			DAG_Update(cba.win, cba.ctrlName, val = cba.checked)

			if(cba.checked)
				SCOPE_OpenScopeWindow(device)
			else
				SCOPE_KillScopeWindowIfRequest(device)
			endif
			break
		default:
			break
	endswitch

	return 0
End

static Function DAP_TurnOffAllChannels(string device, variable channelType)

	variable i, numEntries
	string ctrl

	numEntries = GetNumberFromType(var = channelType)
	for(i = 0; i < numEntries; i += 1)
		ctrl = GetPanelControl(i, channelType, CHANNEL_CONTROL_CHECK)
		PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_UNSELECTED)
	endfor

	// we just called the control procedure for each channel, so we just have to set
	// the checkbox to unselected here
	if(channelType == CHANNEL_TYPE_ADC || channelType == CHANNEL_TYPE_DAC || channelType == CHANNEL_TYPE_TTL)
		ctrl = GetPanelControl(CHANNEL_INDEX_ALL, channelType, CHANNEL_CONTROL_CHECK)
		PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_UNSELECTED)
	endif
End

Function DAP_ButtonProc_AllChanOff(STRUCT WMButtonAction &ba) : ButtonControl

	string device

	switch(ba.eventcode)
		case 2: // mouse up
			device = ba.win
			DAP_TurnOffAllChannels(device, CHANNEL_TYPE_HEADSTAGE)
			DAP_TurnOffAllChannels(device, CHANNEL_TYPE_ADC)
			DAP_TurnOffAllChannels(device, CHANNEL_TYPE_DAC)
			DAP_TurnOffAllChannels(device, CHANNEL_TYPE_TTL)
			break
		default:
			break
	endswitch
End

/// @brief Update the ITI for the given device
Function DAP_UpdateITIAcrossSets(string device, variable maxITI)

	if(DAG_GetNumericalValue(device, "Check_DataAcq_Get_Set_ITI"))
		PGC_SetAndActivateControl(device, "SetVar_DataAcq_ITI", val = maxITI)
	endif
End

/// @brief Procedure for DA/TTL popupmenus including indexing wave popupmenus
Function DAP_PopMenuChkProc_StimSetList(STRUCT WMPopupAction &pa) : PopupMenuControl

	string ctrl, list
	string device, stimSet
	variable channelIndex, channelType, channelControl, isAllControl, indexing
	variable i, numEntries, idx, dataAcqRunMode, headstage, activeChannel

	switch(pa.eventCode)
		case 2:
			device  = pa.win
			ctrl    = pa.ctrlName
			stimSet = pa.popStr
			idx     = pa.popNum

			DAP_AbortIfUnlocked(device)
			ASSERT(!DAP_ParsePanelControl(ctrl, channelIndex, channelType, channelControl), "Invalid control format")
			DAG_Update(pa.win, pa.ctrlName, val = pa.popNum - 1, str = pa.popStr)

			indexing      = DAG_GetNumericalValue(device, "Check_DataAcq_Indexing")
			isAllControl  = DAP_IsAllControl(channelIndex)
			activeChannel = isAllControl                                                                                                        \
			                || (DAG_GetNumericalValue(device, GetSpecialControlLabel(channelType, CHANNEL_CONTROL_CHECK), index = channelIndex) \
			                    && (channelControl == CHANNEL_CONTROL_WAVE                                                                      \
			                        || (channelControl == CHANNEL_CONTROL_INDEX_END                                                             \
			                            && indexing)))

			if(activeChannel)
				dataAcqRunMode = DQ_StopDAQ(device, DQ_STOP_REASON_STIMSET_SELECTION, startTPAfterDAQ = 0)

				// stopping DAQ will reset the stimset popupmenu to its initial value
				// so we have to set the now old value again
				if(indexing && channelControl == CHANNEL_CONTROL_WAVE)
					SetPopupMenuIndex(device, ctrl, idx - 1)
					DAG_Update(pa.win, pa.ctrlName, val = idx - 1, str = pa.popStr)
				endif
			endif

			if(!isAllControl)
				// check if this is a third party stim set which
				// is not yet reflected in the user data
				list = GetUserData(device, ctrl, USER_DATA_MENU_EXP)
				if(FindListItem(stimSet, list) == -1)
					WB_UpdateChangedStimsets()
				endif
			endif

			if(isAllControl)
				numEntries = GetNumberFromType(var = channelType)
				for(i = 0; i < numEntries; i += 1)
					ctrl = GetPanelControl(i, channelType, channelControl)

					if(!DAP_DACHasExpectedClampMode(device, channelIndex, i, channelType))
						continue
					endif

					SetPopupMenuIndex(device, ctrl, idx - 1)
					DAG_Update(pa.win, ctrl, val = idx - 1, str = pa.popStr)
				endfor
			endif

			DAP_UpdateDAQControls(device, REASON_STIMSET_CHANGE)

			if(activeChannel)
				DQ_RestartDAQ(device, dataAcqRunMode)
			endif

			break
		default:
			break
	endswitch
	return 0
End

Function DAP_SetVarProc_DA_Scale(STRUCT WMSetVariableAction &sva) : SetVariableControl

	variable val, channelIndex, channelType, controlType, numEntries, i
	string device, ctrl

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			val    = sva.dval
			ctrl   = sva.ctrlName
			device = sva.win

			ASSERT(!DAP_ParsePanelControl(ctrl, channelIndex, channelType, controlType), "Invalid control format")
			ASSERT(DAP_IsAllControl(channelIndex), "Unexpected channel index")
			DAG_Update(sva.win, ctrl, val = sva.dval, str = sva.sval)

			numEntries = GetNumberFromType(var = channelType)

			for(i = 0; i < numEntries; i += 1)
				ctrl = GetPanelControl(i, channelType, controlType)

				if(!DAP_DACHasExpectedClampMode(device, channelIndex, i, channelType))
					continue
				endif

				SetSetVariable(device, ctrl, val)
				DAG_Update(sva.win, ctrl, val = sva.dval, str = sva.sval)
			endfor

			break
		case 9: // mouse down
			ShowSetVariableLimitsSelectionPopup(sva)
			break
		default:
			break
	endswitch

	return 0
End

static Function DAP_UpdateSweepLimitsAndDisplay(string device)

	variable sweep

	sweep = AFH_GetLastSweepAcquired(device) + 1

	if(IsNaN(sweep))
		return NaN
	endif

	PGC_SetAndActivateControl(device, "SetVar_Sweep", val = sweep, mode = PGC_MODE_FORCE_ON_DISABLED)
End

/// @brief Return the sampling interval in μs with taking the mode,
/// the multiplier and the fixed frequency selection into account
///
/// @param[in]  device  device
/// @param[in]  dataAcqOrTP one of @ref DataAcqModes
/// @param[in]  channelType channel type, one of @ref XopChannelConstants
/// @param[out] valid       [optional] returns if the choosen
///                         sampling interval is valid or not (DAQ only)
/// @see SI_CalculateMinSampInterval()
Function DAP_GetSampInt(string device, variable dataAcqOrTP, variable channelType, [variable &valid])

	variable multiplier, sampInt
	string fixedFreqkHzStr

	if(!ParamIsDefault(valid))
		valid = 1
	endif

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		if(IsDeviceNameFromSutter(device) && channelType != XOP_CHANNEL_TYPE_ADC)
			return SI_CalculateMinSampInterval(device, dataAcqOrTP, channelType)
		endif

		fixedFreqkHzStr = DAG_GetTextualValue(device, "Popup_Settings_FixedFreq")
		if(cmpstr(fixedFreqkHzStr, "Maximum"))
			sampInt = 1 / (str2num(fixedFreqkHzStr) * KILO_TO_ONE) * ONE_TO_MICRO

			if(!ParamIsDefault(valid))
				valid = DAP_IsSampleIntervalValid(device, channelType, sampInt)
			endif

			return sampInt
		else
			multiplier = str2num(DAG_GetTextualValue(device, "Popup_Settings_SampIntMult"))
			return SI_CalculateMinSampInterval(device, dataAcqOrTP, channelType) * multiplier
		endif
	elseif(dataAcqOrTP == TEST_PULSE_MODE)
		return SI_CalculateMinSampInterval(device, dataAcqOrTP, channelType)
	else
		ASSERT(0, "unknown mode")
	endif
End

static Function DAP_IsSampleIntervalValid(string device, variable channelType, variable sampInt)

	if(!IsDeviceNameFromSutter(device))
		return sampInt >= SI_CalculateMinSampInterval(device, DATA_ACQUISITION_MODE, channelType)
	endif

	switch(channelType)
		case XOP_CHANNEL_TYPE_DAC: // intended drop-through
		case XOP_CHANNEL_TYPE_TTL:
			WAVE allowedIntervals = GetSutterDACTTLSampleInterval()
			FindValue/Z/V=(sampInt) allowedIntervals
			return V_value >= 0
		case XOP_CHANNEL_TYPE_ADC:
			WAVE allowedIntervals = GetSutterADCSampleInterval()
			FindValue/Z/V=(sampInt) allowedIntervals
			return V_value >= 0
		default:
			ASSERT(0, "Invalid channel type")
	endswitch
End

Function DAP_UpdateSweepSetVariables(string device)

	variable numSetRepeats

	if(DAG_GetNumericalValue(device, "Check_DataAcq1_RepeatAcq"))
		numSetRepeats = DAG_GetNumericalValue(device, "SetVar_DataAcq_SetRepeats")

		if(DAG_GetNumericalValue(device, "Check_DataAcq1_IndexingLocked"))
			numSetRepeats *= IDX_MaxSweepsLockedIndexing(device)
		else
			numSetRepeats *= IDX_MaxNoOfSweeps(device, 0)
		endif
	else
		numSetRepeats = 1
	endif

	SetValDisplay(device, "valdisp_DataAcq_TrialsCountdown", var = numSetRepeats)
	SetValDisplay(device, "valdisp_DataAcq_SweepsInSet", var = numSetRepeats)
	SetValDisplay(device, "valdisp_DataAcq_SweepsActiveSet", var = IDX_MaxNoOfSweeps(device, 1))
End

Function DAP_SetVarProc_TotSweepCount(STRUCT WMSetVariableAction &sva) : SetVariableControl

	string device

	switch(sva.eventCode)
		case 1:
		case 2:
		case 3:
			device = sva.win
			DAG_Update(sva.win, sva.ctrlName, val = sva.dval)
			DAP_UpdateSweepSetVariables(device)
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_ButtonCtrlFindConnectedAmps(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventcode)
		case 2: // mouse up
			AI_FindConnectedAmps()
			break
		default:
			break
	endswitch
End

/// @brief Return a nicely layouted list of amplifier channels
Function/S DAP_GetNiceAmplifierChannelList()

	WAVE telegraphServers = GetAmplifierTelegraphServers()

	if(!DimSize(telegraphServers, ROWS))
		return AddListItem("\\M1(MC not available", NONE, ";", Inf)
	endif

	return AddListItem(DAP_FormatTelegraphServerList(telegraphServers), NONE, ";", Inf)
End

Function/S DAP_FormatTelegraphServerList(WAVE telegraphServers)

	variable i, numRows
	string str
	string list = ""

	numRows = DimSize(telegraphServers, ROWS)
	for(i = 0; i < numRows; i += 1)
		str  = DAP_GetAmplifierDef(telegraphServers[i][0], telegraphServers[i][1])
		list = AddListItem(str, list, ";", Inf)
	endfor

	return list
End

static Function/S DAP_GetAmplifierDef(variable ampSerial, variable ampChannel)

	string str

	sprintf str, AMPLIFIER_DEF_FORMAT, ampSerial, ampChannel

	return str
End

/// @brief Parse the entries which DAP_GetAmplifierDef() created
Function DAP_ParseAmplifierDef(string amplifierDef, variable &ampSerial, variable &ampChannelID)

	ampSerial    = NaN
	ampChannelID = NaN

	if(!cmpstr(amplifierDef, NONE))
		return NaN
	endif

	sscanf amplifierDef, AMPLIFIER_DEF_FORMAT, ampSerial, ampChannelID
	ASSERT(V_Flag == 2, "Unexpected amplifier popup list format")
End

Function DAP_SyncDeviceAssocSettToGUI(string device, variable headStage)

	DAP_AbortIfUnlocked(device)

	DAP_UpdateChanAmpAssignPanel(device)
	P_UpdatePressureControls(device, headStage)
End

Function DAP_PopMenuProc_Headstage(STRUCT WMPopupAction &pa) : PopupMenuControl

	string   device
	variable headStage

	switch(pa.eventCode)
		case 2: // mouse up
			device    = pa.win
			headStage = str2num(pa.popStr)

			DAG_Update(pa.win, pa.ctrlName, val = pa.popNum - 1, str = pa.popStr)
			DAP_SyncDeviceAssocSettToGUI(device, headStage)

			break
		default:
			break
	endswitch

	return 0
End

Function DAP_PopMenuProc_CAA(STRUCT WMPopupAction &pa) : PopupMenuControl

	string device

	switch(pa.eventCode)
		case 2: // mouse up
			device = pa.win
			DAP_AbortIfUnlocked(device)

			DAP_UpdateChanAmpAssignStorWv(device)
			P_UpdatePressureDataStorageWv(device)
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_SetVarProc_CAA(STRUCT WMSetVariableAction &sva) : SetVariableControl

	string device

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
			device = sva.win
			DAP_AbortIfUnlocked(device)

			strswitch(sva.ctrlName)
				case "setvar_DataAcq_SSPressure":
				case "setvar_DataAcq_PPPressure":
				case "setvar_DataAcq_PPDuration":
					DAG_Update(sva.win, sva.ctrlName, val = sva.dval)
					break
				default:
					// not stored in GUI state wave
					break
			endswitch

			DAP_UpdateChanAmpAssignStorWv(device)
			P_UpdatePressureDataStorageWv(device)
			break
		case 9: // mouse down
			strswitch(sva.ctrlName)
				case "setvar_DataAcq_SSPressure":
				case "setvar_DataAcq_PPPressure":
				case "setvar_DataAcq_PPDuration":
					ShowSetVariableLimitsSelectionPopup(sva)
					break
				default:
					// not stored in GUI state wave
					break
			endswitch
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_ButtonProc_ClearChanCon(STRUCT WMButtonAction &ba) : ButtonControl

	string device
	variable headStage, daVC, daIC, adVC, adIC

	switch(ba.eventCode)
		case 2: // mouse up
			device = ba.win
			DAP_AbortIfUnlocked(device)

			WAVE ChanAmpAssign = GetChanAmpAssign(device)

			headStage = str2num(GetPopupMenuString(device, "Popup_Settings_HeadStage"))

			daVC = ChanAmpAssign[%VC_DA][headStage]
			daIC = ChanAmpAssign[%IC_DA][headStage]

			adVC = ChanAmpAssign[%VC_AD][headStage]
			adIC = ChanAmpAssign[%IC_AD][headStage]

			WAVE channelClampMode = GetChannelClampMode(device)

			if(IsFinite(daVC))
				channelClampMode[daVC][%DAC][%Headstage] = NaN
			endif

			if(IsFinite(daIC))
				channelClampMode[daIC][%DAC][%Headstage] = NaN
			endif

			if(IsFinite(adVC))
				channelClampMode[adVC][%ADC][%Headstage] = NaN
			endif

			if(IsFinite(adIC))
				channelClampMode[adIC][%ADC][%Headstage] = NaN
			endif

			// set all DA/AD channels for both clamp modes to an invalid channel number
			ChanAmpAssign[0, 6; 2][headStage] = NaN
			ChanAmpAssign[8, 9][headStage]    = NaN

			DAP_UpdateChanAmpAssignPanel(device)
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Return true if the sweep ordering is ascending, false otherwise
static Function DAP_HasAscendingSweepOrdering(string device)

	variable lastAcquiredSweep, nextSweepNumber

	lastAcquiredSweep = AFH_GetLastSweepAcquired(device)

	if(IsNaN(lastAcquiredSweep))
		// nothing acquired
		return 1
	endif

	nextSweepNumber = GetSetVariable(device, "SetVar_Sweep")

	if(nextSweepNumber > lastAcquiredSweep)
		return 1
	endif

	return 0
End

static Function DAP_CheckSampleInterval(string device, variable mode)

	variable sampIntADC, sampIntDAC, sampIntTTL, validSampInt

	sampIntDAC = DAP_GetSampInt(device, mode, XOP_CHANNEL_TYPE_DAC, valid = validSampInt)
	if(!validSampInt)
		printf "%s: The selected sampling interval is not possible with your DAC hardware.\r", device
		ControlWindowToFront()
		return 1
	endif

	sampIntADC = DAP_GetSampInt(device, mode, XOP_CHANNEL_TYPE_ADC, valid = validSampInt)
	if(!validSampInt)
		printf "%s: The selected sampling interval is not possible with your ADC hardware.\r", device
		ControlWindowToFront()
		return 1
	endif

	sampIntTTL = DAP_GetSampInt(device, mode, XOP_CHANNEL_TYPE_TTL, valid = validSampInt)
	if(!validSampInt)
		printf "%s: The selected sampling interval is not possible with your TTL hardware.\r", device
		ControlWindowToFront()
		return 1
	endif

	return 0
End

/// @brief Check if all settings are valid to send a test pulse or acquire data
///
/// For invalid settings an informative message is printed into the history area.
///
/// Callers must ensure to set the acquisition state back to #AS_INACTIVE when
/// calling with #DATA_ACQUISITION_MODE.
///
/// @param device device
/// @param mode       One of @ref DataAcqModes
///
/// @return 0 for valid settings, 1 for invalid settings
Function DAP_CheckSettings(string device, variable mode)

	variable numDACs, numADCs, numHS, numEntries, i, clampMode, headstage
	variable ampSerial, ampChannelID, hardwareType
	variable lastStartSeconds, lastITI, nextStart, leftTime, sweepNo
	variable DACchannel, ret
	string ctrl, endWave, ttlWave, dacWave, refDacWave, reqParams
	string list, lastStart, msg

	ASSERT(mode == DATA_ACQUISITION_MODE || mode == TEST_PULSE_MODE, "Invalid mode")

	if(mode == DATA_ACQUISITION_MODE)
		AS_HandlePossibleTransition(device, AS_EARLY_CHECK)
	endif

	if(DAP_DeviceIsUnlocked(device))
		printf "(%s) Device is unlocked. Please lock the device.\r", device
		ControlWindowToFront()
		return 1
	endif

	if(!DAP_HasAscendingSweepOrdering(device))
		printf "(%s) The sweep number ordering is not strictly ascending.\r", device
		ControlWindowToFront()
		return 1
	endif

	PathInfo home
	if(V_Flag) // saved experiment
		if(!HasEnoughDiskspaceFree(S_path, MINIMUM_FREE_DISK_SPACE))
			printf "%s: The amount of free disk space on drive \"%s:\" is less than %.0W0PB. Therefore it is not possible to acquire data in MIES.\nPlease contact your hardware administrator.\r", device, GetDrive(S_path), MINIMUM_FREE_DISK_SPACE
			ControlWindowToFront()
			return 1
		endif
	endif

	if(mode == DATA_ACQUISITION_MODE)
		// update dependent entries, the stimset might have changed behind our back
		DAP_UpdateDAQControls(device, REASON_STIMSET_CHANGE)

		WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
		numEntries = DimSize(statusHS, ROWS)
		for(i = 0; i < numEntries; i += 1)
			if(!statusHS[i])
				continue
			endif

			DACchannel = AFH_GetDACFromHeadstage(device, i)

			if(!IsFinite(DACchannel))
				continue
			endif

			WAVE/T stimsets = IDX_GetSetsInRange(device, DACchannel, CHANNEL_TYPE_DAC, 1)
			ASSERT(DimSize(stimsets, ROWS) == 1, "Unexpected stimsets size")

			if(DAP_CheckAnalysisFunctionAndParameter(device, stimsets[0]))
				return 1
			endif
		endfor
	endif

	if(mode == DATA_ACQUISITION_MODE && AS_HandlePossibleTransition(device, AS_PRE_DAQ))
		printf "%s: Pre DAQ analysis function requested an abort\r", device
		ControlWindowToFront()
		return 1
	endif

	if(DAP_CheckSampleInterval(device, mode))
		return 1
	endif

	// check that if multiple devices are locked we are in multi device mode
	if(ItemsInList(GetListOfLockedDevices()) > 1 && !DAG_GetNumericalValue(device, "check_Settings_MD"))
		print "If multiple devices are locked, DAQ/TP is only possible in multi device mode"
		ControlWindowToFront()
		return 1
	endif

	if(DAG_GetNumericalValue(device, "Popup_Settings_SampIntMult") > 0 && DAG_GetNumericalValue(device, "Popup_Settings_FixedFreq") > 0)
		print "It is not possible to combine fixed frequency acquisition with the sampling interval multiplier"
		ControlWindowToFront()
		return 1
	endif

	if(DAP_DeviceIsUnlocked(device))
		printf "(%s) Device is unlocked. Please lock the device.\r", device
		ControlWindowToFront()
		return 1
	endif

	NVAR deviceID = $GetDAQDeviceID(device)
	hardwareType = GetHardwareType(device)

#ifndef EVIL_KITTEN_EATING_MODE
	if(HW_SelectDevice(hardwareType, deviceID, flags = HARDWARE_PREVENT_ERROR_MESSAGE))
		printf "(%s) Device can not be selected. Please unlock and lock the device.\r", device
		ControlWindowToFront()
		return 1
	endif

	if(hardwareType == HARDWARE_NI_DAC && !DAG_GetNumericalValue(device, "check_Settings_MD"))
		printf "(%s) NI hardware can only be used in multi device mode.\r", device
		ControlWindowToFront()
		return 1
	endif
#endif // !EVIL_KITTEN_EATING_MODE
	if(!HasPanelLatestVersion(device, DA_EPHYS_PANEL_VERSION))
		printf "(%s) The DA_Ephys panel is too old to be usable. Please close it and open a new one.\r", device
		ControlWindowToFront()
		return 1
	endif

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
	numHS = sum(statusHS)
	if(!numHS)
		printf "(%s) Please activate at least one headstage\r", device
		ControlWindowToFront()
		return 1
	endif

	WAVE statusDA = DAG_GetChannelState(device, CHANNEL_TYPE_DAC)
	numDACs = sum(statusDA)
	if(!numDACS)
		printf "(%s) Please activate at least one DA channel\r", device
		ControlWindowToFront()
		return 1
	endif

	WAVE statusAD = DAG_GetChannelState(device, CHANNEL_TYPE_ADC)
	numADCs = sum(statusAD)
	if(!numADCs)
		printf "(%s) Please activate at least one AD channel\r", device
		ControlWindowToFront()
		return 1
	endif

	if(mode == DATA_ACQUISITION_MODE)

		if(DAG_GetNumericalValue(device, "Check_Settings_ITImanualStart"))
			WAVE numericalValues = GetLBNumericalValues(device)
			WAVE textualValues   = GetLBTextualValues(device)
			lastITI = GetLastSweepWithSettingIndep(numericalValues, "Inter-trial interval", sweepNo)

			if(IsFinite(lastITI))
				lastStart = GetLastSettingTextIndep(textualValues, sweepNo, HIGH_PREC_SWEEP_START_KEY, DATA_ACQUISITION_MODE)

				if(IsFinite(lastITI) && !IsEmpty(lastStart))
					lastStartSeconds = ParseISO8601TimeStamp(lastStart)
					nextStart        = DateTimeInUTC()
					leftTime         = lastStartSeconds + lastITI - nextStart

					if(leftTime > 0)
						printf "(%s) The next sweep can not be started as that would break the required inter trial interval. Please wait another %g seconds.\r", device, leftTime
						ControlWindowToFront()
						return 1
					endif
				endif
			endif
		endif

		// check all selected TTLs
		WAVE statusTTLFiltered = DC_GetFilteredChannelState(device, mode, CHANNEL_TYPE_TTL)
		numEntries = DimSize(statusTTLFiltered, ROWS)
		for(i = 0; i < numEntries; i += 1)
			if(!statusTTLFiltered[i])
				continue
			endif

			if(DAP_CheckStimset(device, CHANNEL_TYPE_TTL, i, NaN))
				return 1
			endif
		endfor

		if(DAG_GetNumericalValue(device, "Check_DataAcq1_RepeatAcq") && DAG_GetNumericalValue(device, "check_DataAcq_RepAcqRandom") && DAG_GetNumericalValue(device, "Check_DataAcq_Indexing"))
			printf "(%s) Repeated random acquisition can not be combined with indexing.\r", device
			printf "(%s) If you need this feature please contact the MIES developers.\r", device
			ControlWindowToFront()
			return 1
		endif

		if(DAG_GetNumericalValue(device, "Check_DataAcq1_DistribDaq") && DAG_GetNumericalValue(device, "Check_DataAcq1_dDAQOptOv"))
			printf "(%s) Only one of distributed DAQ and optimized overlap distributed DAQ can be checked.\r", device
			ControlWindowToFront()
			return 1
		endif

		// classic distributed acquisition requires that all stim sets are the same
		// oodDAQ allows different stim sets
		refDacWave = ""
		if(DAG_GetNumericalValue(device, "Check_DataAcq1_DistribDaq") || DAG_GetNumericalValue(device, "Check_DataAcq1_dDAQOptOv"))
			WAVE statusDAFiltered = DC_GetFilteredChannelState(device, mode, CHANNEL_TYPE_DAC)
			numEntries = DimSize(statusDAFiltered, ROWS)
			for(i = 0; i < numEntries; i += 1)
				if(!statusDAFiltered[i])
					continue
				endif

				if(!IsFinite(AFH_GetHeadstagefromDAC(device, i)))
					printf "(%s) Distributed Acquisition does not work with unassociated DA channel %d.\r", device, i
					ControlWindowToFront()
					return 1
				endif

				if(DAG_GetNumericalValue(device, "Check_DataAcq1_dDAQOptOv"))
					continue
				endif

				dacWave = DAG_GetTextualValue(device, GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), index = i)
				if(isEmpty(refDacWave))
					refDacWave = dacWave
				elseif(CmpStr(refDacWave, dacWave))
					printf "(%s) Please select the same stim sets for all DACs when distributed acquisition is used\r", device
					ControlWindowToFront()
					return 1
				endif
			endfor
		endif

		if(DAP_CheckAsyncSettings(device))
			return 1
		endif
	endif

	// avoid having different headstages reference the same amplifiers
	// and/or DA/AD channels in the "DAC Channel and Device Associations" menu
	Make/FREE/N=(NUM_HEADSTAGES) DACs, ADCs
	Make/FREE/N=(NUM_HEADSTAGES)/T ampSpec

	WAVE chanAmpAssign = GetChanAmpAssign(device)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		ampSerial    = ChanAmpAssign[%AmpSerialNo][i]
		ampChannelID = ChanAmpAssign[%AmpChannelID][i]
		if(IsFinite(ampSerial) && IsFinite(ampChannelID))
			ampSpec[i] = DAP_GetAmplifierDef(ampSerial, ampChannelID)
		else
			// add a unique alternative entry
			ampSpec[i] = num2str(i)
		endif

		clampMode = DAG_GetHeadstageMode(device, i)

		if(clampMode == V_CLAMP_MODE)
			DACs[i] = ChanAmpAssign[%VC_DA][i]
			ADCs[i] = ChanAmpAssign[%VC_AD][i]
		elseif(clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
			DACs[i] = ChanAmpAssign[%IC_DA][i]
			ADCs[i] = ChanAmpAssign[%IC_AD][i]
		else
			printf "(%s) Unhandled mode %d\r", device, clampMode
			ControlWindowToFront()
			return 1
		endif
	endfor

	if(SearchForDuplicates(DACs))
		printf "(%s) Different headstages in the \"DAC Channel and Device Associations\" menu reference the same DA channels.\r", device
		printf "Please clear the associations for unused headstages.\r"
		ControlWindowToFront()
		return 1
	endif

	if(SearchForDuplicates(ADCs))
		printf "(%s) Different headstages in the \"DAC Channel and Device Associations\" menu reference the same AD channels.\r", device
		printf "Please clear the associations for unused headstages.\r"
		ControlWindowToFront()
		return 1
	endif

	if(SearchForDuplicates(ampSpec))
		printf "(%s) Different headstages in the \"DAC Channel and Device Associations\" menu reference the same amplifier-channel-combination.\r", device
		printf "Please clear the associations for unused headstages.\r"
		ControlWindowToFront()
		return 1
	endif

	// check all active headstages
	numEntries = DimSize(statusHS, ROWS)
	for(i = 0; i < numEntries; i += 1)
		if(!statusHS[i])
			continue
		endif

		ret = DAP_CheckHeadStage(device, i, mode)

		switch(ret)
			case 0:
				// passed, do nothing
				break
			case 1: // non-recoverable error
				return 1
			case 2: // recoverable error, try again once
				if(DAP_CheckHeadStage(device, i, mode))
					return 1
				endif
				break
			default:
				ASSERT(0, "Unexpected value")
		endswitch
	endfor

	if(DAG_GetNumericalValue(device, "SetVar_DataAcq_TPDuration") <= 0)
		print "The testpulse duration must be greater than 0 ms"
		ControlWindowToFront()
		return 1
	endif

	if(mode == DATA_ACQUISITION_MODE)
		WAVE/T allSetNames      = DAG_GetChannelTextual(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		WAVE   statusDAFiltered = DC_GetFilteredChannelState(device, DATA_ACQUISITION_MODE, CHANNEL_TYPE_DAC)
		numEntries = DimSize(statusDAFiltered, ROWS)
		for(i = 0; i < numEntries; i += 1)

			if(!statusDAFiltered[i])
				continue
			endif

			if(GetValDisplayAsNum(device, "valdisp_DataAcq_SweepsInSet") == 0 \
			   && CmpStr(allSetNames[i], STIMSET_TP_WHILE_DAQ))
				printf "(%s) The calculated number of sweeps is zero. This is unexpected and very likely a bug.\r", device
				ControlWindowToFront()
				return 1
			endif

			headstage = AFH_GetHeadstageFromDAC(device, i)

			if(IsAssociatedChannel(headstage) && DAG_GetHeadstageMode(device, headstage) == I_EQUAL_ZERO_MODE \
			   && !cmpstr(allSetNames[i], STIMSET_TP_WHILE_DAQ))
				printf "(%s) When TP while DAQ is used the channel clamp mode for headstage %d can not be I=0.\r", device, headstage
				ControlWindowToFront()
				return 1
			endif

			if(!IsAssociatedChannel(headstage))
				if(DAP_CheckStimset(device, CHANNEL_TYPE_DAC, i, NaN))
					return 1
				endif

				if(DAP_CheckChannel(device, CHANNEL_TYPE_DAC, i))
					return 1
				endif
			endif
		endfor

		WAVE statusADFiltered = DC_GetFilteredChannelState(device, DATA_ACQUISITION_MODE, CHANNEL_TYPE_ADC)
		numEntries = DimSize(statusADFiltered, ROWS)
		for(i = 0; i < numEntries; i += 1)

			if(!statusADFiltered[i])
				continue
			endif

			headstage = AFH_GetHeadstageFromADC(device, i)

			if(!IsAssociatedChannel(headstage))
				if(DAP_CheckChannel(device, CHANNEL_TYPE_ADC, i))
					return 1
				endif
			endif
		endfor

		if(DC_GotTPChannelWhileDAQ(device))
			if(DAG_GetNumericalValue(device, "Popup_Settings_SampIntMult") > 0)
				printf "(%s) When TP while DAQ is used only sample multiplier of 1 is supported.\r", device
				ControlWindowToFront()
				return 1
			endif
			if(DAG_GetNumericalValue(device, "Popup_Settings_FixedFreq") > 0)
				printf "(%s) When TP while DAQ is used no fixed frequency acquisition is supported.\r", device
				ControlWindowToFront()
				return 1
			endif
		endif
	endif

	// unlock DAQDataWave, this happens if user functions error out and we don't catch it
	WAVE DAQDataWave = GetDAQDataWave(device, mode)
	if(GetLockState(DAQDataWave))
		sprintf msg, "(%s) Removing leftover lock on %s.\r", device, GetWavesDataFolder(DAQDataWave, 2)
		BUG(msg)
		ChangeWaveLock(DAQDataWave, 0)
	endif

	if(DAP_CheckPressureSettings(device))
		return 1
	endif

	if(DAG_GetNumericalValue(device, "Check_Settings_NwbExport"))
		NWB_PrepareExport(str2num(DAG_GetTextualValue(device, "Popup_Settings_NwbVersion")), device)
	endif

	return 0
End

static Function DAP_CheckAsyncSettings(string device)

	variable i, hwChannel, minValue, maxValue, auxOffset, isADinUse
	string ctrl

	WAVE statusAsync = DAG_GetChannelState(device, CHANNEL_TYPE_ASYNC)
	WAVE statusAD    = DAG_GetChannelState(device, CHANNEL_TYPE_ADC)
	if(IsDeviceNameFromSutter(device))
		WAVE deviceInfo = GetDeviceInfoWave(device)
		auxOffset = deviceInfo[%AD]
	endif

	for(i = 0; i < NUM_ASYNC_CHANNELS; i += 1)

		if(!statusAsync[i])
			continue
		endif

		hwChannel = HW_ITC_CalculateDevChannelOff(device) + i

		// AD channel already used
		isADinUse = ((hwChannel + auxOffset) < NUM_AD_CHANNELS) ? statusAD[hwChannel + auxOffset] : 0
		if(hwChannel < NUM_ASYNC_CHANNELS && isADinUse)
			printf "(%s) The Async channel %d is already used for DAQ.\r", device, i
			ControlWindowToFront()
			return 1
		endif

		// active async channel

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN)
		if(!IsFinite(DAG_GetNumericalValue(device, ctrl, index = i)))
			printf "(%s) Please select a finite gain value for async channel %d\r", device, i
			ControlWindowToFront()
			return 1
		endif

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ALARM, CHANNEL_CONTROL_CHECK)
		if(!DAG_GetNumericalValue(device, ctrl, index = i))
			continue
		endif

		// with alarm enabled

		ctrl     = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN)
		minValue = DAG_GetNumericalValue(device, ctrl, index = i)
		if(!IsFinite(minValue))
			printf "(%s) Please select a finite minimum value for async channel %d\r", device, i
			ControlWindowToFront()
			return 1
		endif

		ctrl     = GetSpecialControlLabel(CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX)
		maxValue = DAG_GetNumericalValue(device, ctrl, index = i)
		if(!IsFinite(maxValue))
			printf "(%s) Please select a finite maximum value for async channel %d\r", device, i
			ControlWindowToFront()
			return 1
		endif

		if(!(minValue < maxValue))
			printf "(%s) Please select a minimum value which is strictly smaller than the maximum value for async channel %d\r", device, i
			ControlWindowToFront()
			return 1
		endif

		if(DAG_GetNumericalValue(device, "Check_Settings_AlarmAutoRepeat"))
			if(!DAG_GetNumericalValue(device, "Check_DataAcq1_RepeatAcq"))
				printf "(%s) Repeat sweep on async alarm can only be used with repeated acquisition enabled\r", device
				ControlWindowToFront()
				return 1
			endif
		endif
	endfor

	return 0
End

static Function DAP_CheckPressureSettings(string device)

	variable ADConfig, ADC
	string pressureDevice, userPressureDevice

#ifndef EVIL_KITTEN_EATING_MODE
	pressureDevice = GetPopupMenuString(device, "popup_Settings_Pressure_dev")

	if(cmpstr(pressureDevice, NONE))
		if(GetHardwareType(pressureDevice) == HARDWARE_NI_DAC)

			ADC      = str2num(GetPopupMenuString(device, "Popup_Settings_Pressure_AD"))
			ADConfig = HW_NI_GetAnalogInputConfig(pressureDevice, ADC)

			if((ADConfig & HW_NI_CONFIG_DIFFERENTIAL) != HW_NI_CONFIG_DIFFERENTIAL)
				printf "(%s) The AD channel %d of the pressure device %s can not be used in differential mode, please try another channel number.\r", device, ADC, pressureDevice
				printf "For USB-6001 devices only the channels 0 to 3 can be used in differential mode, the channels 4 to 7 are fixed in Referenced Single Ended (RSE) mode."
				ControlWindowToFront()
				return 1
			endif
		endif
	endif

	userPressureDevice = GetPopupMenuString(device, "popup_Settings_UserPressure")

	if(cmpstr(userPressureDevice, NONE))
		if(GetHardwareType(userPressureDevice) == HARDWARE_NI_DAC)

			ADC      = str2num(GetPopupMenuString(device, "Popup_Settings_UserPressure_ADC"))
			ADConfig = HW_NI_GetAnalogInputConfig(userPressureDevice, ADC)

			if((ADConfig & HW_NI_CONFIG_DIFFERENTIAL) != HW_NI_CONFIG_DIFFERENTIAL)
				printf "(%s) The AD channel %d of the user pressure device %s can not be used in differential mode, please try another channel number.\r", device, ADC, userPressureDevice
				printf "For USB-6001 devices only the channels 0 to 3 can be used in differential mode, the channels 4 to 7 are fixed in Referenced Single Ended (RSE) mode."
				ControlWindowToFront()
				return 1
			endif
		endif
	endif
#endif // !EVIL_KITTEN_EATING_MODE

	return 0
End

/// @brief Returns zero if everything is okay, 1 if a non-recoverable error was found and 2 on recoverable errors
static Function DAP_CheckHeadStage(string device, variable headStage, variable mode)

	string unit, ADUnit, DAUnit
	variable DACchannel, ADCchannel, DAheadstage, ADheadstage, DAGain, ADGain, realMode
	variable gain, scale, clampMode, i, j, ampConnState, needResetting, ADConfig
	variable DAGainMCC, ADGainMCC, numEntries, gainAtChannel
	string DAUnitMCC, ADUnitMCC, unitAtChannel, clampModeStr

	if(DAP_DeviceIsUnlocked(device))
		printf "(%s) Device is unlocked. Please lock the device.\r", device
		ControlWindowToFront()
		return 1
	endif

	WAVE   ChanAmpAssign     = GetChanAmpAssign(device)
	WAVE/T ChanAmpAssignUnit = GetChanAmpAssignUnit(device)
	WAVE   channelClampMode  = GetChannelClampMode(device)

	if(headstage < 0 || headStage >= DimSize(ChanAmpAssign, COLS))
		printf "(%s) Invalid headstage %d\r", device, headStage
		ControlWindowToFront()
		return 1
	endif

	ampConnState = AI_SelectMultiClamp(device, headStage)
	clampMode    = DAG_GetHeadstageMode(device, headstage)

	// needs to be at the beginning as DAP_ApplyClmpModeSavdSettngs writes into
	// ChanAmpAssign/ChanAmpAssignUnit
	if(ampConnState == AMPLIFIER_CONNECTION_SUCCESS && AI_IsValidClampMode(clampMode))
		DAP_ApplyClmpModeSavdSettngs(device, headstage, clampMode)
	endif

	if(clampMode == V_CLAMP_MODE)
		DACchannel = ChanAmpAssign[%VC_DA][headStage]
		ADCchannel = ChanAmpAssign[%VC_AD][headStage]
		DAGain     = ChanAmpAssign[%VC_DAGain][headStage]
		ADGain     = ChanAmpAssign[%VC_ADGain][headStage]
		DAUnit     = ChanAmpAssignUnit[%VC_DAUnit][headStage]
		ADUnit     = ChanAmpAssignUnit[%VC_ADUnit][headStage]
	elseif(clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
		DACchannel = ChanAmpAssign[%IC_DA][headStage]
		ADCchannel = ChanAmpAssign[%IC_AD][headStage]
		DAGain     = ChanAmpAssign[%IC_DAGain][headStage]
		ADGain     = ChanAmpAssign[%IC_ADGain][headStage]
		DAUnit     = ChanAmpAssignUnit[%IC_DAUnit][headStage]
		ADUnit     = ChanAmpAssignUnit[%IC_ADUnit][headStage]
	else
		printf "(%s) Unhandled mode %d\r", device, clampMode
		ControlWindowToFront()
		return 1
	endif

	if(ampConnState == AMPLIFIER_CONNECTION_SUCCESS)

		AI_EnsureCorrectMode(device, headStage)
		AI_QueryGainsUnitsForClampMode(device, headStage, clampMode, DAGainMCC, ADGainMCC, DAUnitMCC, ADUnitMCC)

		if(cmpstr(DAUnit, DAUnitMCC))
			printf "(%s) The configured unit for the DA channel %d differs from the one in the \"DAC Channel and Device Associations\" menu (%s vs %s).\r", device, DACchannel, DAUnit, DAUnitMCC
			needResetting = 1
		endif

		if(clampMode == I_EQUAL_ZERO_MODE && !CheckIfSmall(DAGainMCC))
			printf "(%s) The DA gain for the DA channel %d in I=0 clamp mode is expected to be zero but the configured gain is %g.\r", device, DACchannel, DAGainMCC
			return 2
		elseif(clampMode != I_EQUAL_ZERO_MODE && CheckIfSmall(DAGainMCC))
			printf "(%s) The DA gain for the DA channel %d is zero, this is an MCC bug. Please reset the  MultiClamp Commander to default settings and restart MIES.\r", device, DACchannel
			return 2
		elseif(clampMode != I_EQUAL_ZERO_MODE && !CheckIfClose(DAGain, DAGainMCC, tol = 1e-4))
			printf "(%s) The configured gain for the DA channel %d differs from the one in the \"DAC Channel and Device Associations\" menu (%g vs %g).\r", device, DACchannel, DAGain, DAGainMCC
			needResetting = 1
		endif

		if(cmpstr(ADUnit, ADUnitMCC))
			printf "(%s) The configured unit for the AD channel %d differs from the one in the \"DAC Channel and Device Associations\" menu (%s vs %s).\r", device, ADCchannel, ADUnit, ADUnitMCC
			needResetting = 1
		endif

		if(!CheckIfClose(ADGain, ADGainMCC, tol = 1e-4))
			printf "(%s) The configured gain for the AD channel %d differs from the one in the \"DAC Channel and Device Associations\" menu (%g vs %g).\r", device, ADCchannel, ADGain, ADGainMCC
			needResetting = 1
		endif

		if(needResetting)
			AI_UpdateChanAmpAssign(device, headStage, clampMode, DAGainMCC, ADGainMCC, DAUnitMCC, ADUnitMCC)
			printf "(%s) The automatically imported gains from MCC were used to overwrite differing manual settings.\r", device
			ControlWindowToFront()
			DAP_UpdateChanAmpAssignPanel(device)
			DAP_SyncChanAmpAssignToActiveHS(device)
			return 2
		endif
	else
		clampModeStr  = ConvertAmplifierModeShortStr(clampMode)
		unitAtChannel = DAG_GetTextualValue(device, GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT), index = DACchannel)
		if(CmpStr(unitAtChannel, DAUnit))
			printf "(%s) The DA unit for the DA channel %d is different from the DA unit for headstage %d in the Hardware tab (clampMode %s).\r", device, DACchannel, headstage, clampModeStr
			return 1
		endif
		unitAtChannel = DAG_GetTextualValue(device, GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT), index = ADCchannel)
		if(CmpStr(unitAtChannel, ADUnit))
			printf "(%s) The AD unit for the AD channel %d is different from the AD unit for headstage %d in the Hardware tab (clampMode %s).\r", device, ADCchannel, headstage, clampModeStr
			return 1
		endif
		gainAtChannel = DAG_GetNumericalValue(device, GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN), index = DACchannel)
		if(!CheckIfClose(DAGain, gainAtChannel, tol = 1e-4))
			printf "(%s) The DA gain for the DA channel %d is different from the DA gain for headstage %d in the Hardware tab (clampMode %s).\r", device, ADCchannel, headstage, clampModeStr
			return 1
		endif
		gainAtChannel = DAG_GetNumericalValue(device, GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN), index = ADCchannel)
		if(!CheckIfClose(ADGain, gainAtChannel, tol = 1e-4))
			printf "(%s) The AD gain for the AD channel %d is different from the AD gain for headstage %d in the Hardware tab (clampMode %s).\r", device, ADCchannel, headstage, clampModeStr
			return 1
		endif
	endif

	if(!IsFinite(DACchannel) || !IsFinite(ADCchannel))
		printf "(%s) Please select a valid DA and AD channel in \"DAC Channel and Device Associations\" in the Hardware tab for headstage %d.\r", device, headstage
		ControlWindowToFront()
		return 1
	endif

	realMode = channelClampMode[DACchannel][%DAC][%ClampMode]
	if(realMode != clampMode)
		printf "(%s) The clamp mode of DA %d is %s and differs from the requested mode %s.\r", device, DACchannel, ConvertAmplifierModeToString(realMode), ConvertAmplifierModeToString(clampMode)
		ControlWindowToFront()
		return 1
	endif

	realMode = channelClampMode[ADCchannel][%ADC][%ClampMode]
	if(realMode != clampMode)
		printf "(%s) The clamp mode of AD %d is %s and differs from the requested mode %s.\r", device, ADCchannel, ConvertAmplifierModeToString(realMode), ConvertAmplifierModeToString(clampMode)
		ControlWindowToFront()
		return 1
	endif

	ADheadstage = AFH_GetHeadstageFromADC(device, ADCchannel)
	if(!IsFinite(ADheadstage))
		printf "(%s) Could not determine the headstage for the ADChannel %d.\r", device, ADCchannel
		ControlWindowToFront()
		return 1
	endif

	DAheadstage = AFH_GetHeadstageFromDAC(device, DACchannel)
	if(!IsFinite(DAheadstage))
		printf "(%s) Could not determine the headstage for the DACchannel %d.\r", device, DACchannel
		ControlWindowToFront()
		return 1
	endif

	if(DAheadstage != ADheadstage || headstage != ADheadstage || headstage != DAheadstage)
		printf "(%s) The configured headstages for the DA channel %d and the AD channel %d differ (%d vs %d).\r", device, DACchannel, ADCchannel, DAheadstage, ADheadstage
		ControlWindowToFront()
		return 1
	endif

	if(DAP_CheckChannel(device, CHANNEL_TYPE_DAC, DACchannel))
		return 1
	endif

	unit = DAG_GetTextualValue(device, GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT), index = DACchannel)
	if(ampConnState == AMPLIFIER_CONNECTION_SUCCESS && cmpstr(DAUnit, unit))
		printf "(%s) The configured unit for the DA channel %d differs from the one in the \"DAC Channel and Device Associations\" menu (%s vs %s).\r", device, DACchannel, DAUnit, unit
		ControlWindowToFront()
		return 1
	endif

	gain = DAG_GetNumericalValue(device, GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN), index = DACchannel)
	if(!CheckIfClose(DAGain, gain, tol = 1e-4))
		printf "(%s) The configured gain for the DA channel %d differs from the one in the \"DAC Channel and Device Associations\" menu (%d vs %d).\r", device, DACchannel, DAGain, gain
		ControlWindowToFront()
		return 1
	endif

	if(DAP_CheckChannel(device, CHANNEL_TYPE_ADC, ADCchannel))
		return 1
	endif

	unit = DAG_GetTextualValue(device, GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT), index = ADCchannel)
	if(cmpstr(ADUnit, unit))
		printf "(%s) The configured unit for the AD channel %d differs from the one in the \"DAC Channel and Device Associations\" menu (%s vs %s).\r", device, ADCchannel, ADUnit, unit
		ControlWindowToFront()
		return 1
	endif

	gain = DAG_GetNumericalValue(device, GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN), index = ADCchannel)
	if(!CheckIfClose(ADGain, gain, tol = 1e-4))
		printf "(%s) The configured gain for the AD channel %d differs from the one in the \"DAC Channel and Device Associations\" menu (%g vs %g).\r", device, ADCchannel, ADGain, gain
		ControlWindowToFront()
		return 1
	endif

	if(mode == DATA_ACQUISITION_MODE)
		if(DAP_CheckStimset(device, CHANNEL_TYPE_DAC, DACchannel, headstage))
			return 1
		endif
	endif

#ifndef EVIL_KITTEN_EATING_MODE
	if((DAG_GetNumericalValue(device, "check_Settings_RequireAmpConn") && ampConnState != AMPLIFIER_CONNECTION_SUCCESS) || ampConnState == AMPLIFIER_CONNECTION_MCC_FAILED)
		printf "(%s) The amplifier of the headstage %d can not be selected, please call \"Query connected Amps\" from the Hardware Tab\r", device, headStage
		printf " and ensure that the \"Multiclamp 700B Commander\" application is open.\r"
		ControlWindowToFront()
		return 1
	endif
#endif // !EVIL_KITTEN_EATING_MODE

#ifndef EVIL_KITTEN_EATING_MODE
	if(GetHardwareType(device) == HARDWARE_NI_DAC)
		ADConfig = HW_NI_GetAnalogInputConfig(device, ADCchannel)
		if((ADConfig & HW_NI_CONFIG_DIFFERENTIAL) != HW_NI_CONFIG_DIFFERENTIAL)
			printf "(%s) The AD channel %d from headstage %d can not be used in differential mode.\r", device, ADCchannel, headstage
			printf "Available modes are: %s\r", HW_NI_AnalogInputToString(ADConfig)
			ControlWindowToFront()
			return 1
		endif
	endif
#endif // !EVIL_KITTEN_EATING_MODE

	return 0
End

static Function DAP_CheckChannel(string device, variable channelType, variable channel)

	string ctrl, channelName, unit
	variable gain, scale

	channelName = ChannelTypeToString(channelType)

	ctrl = GetSpecialControlLabel(channelType, CHANNEL_CONTROL_UNIT)
	unit = DAG_GetTextualValue(device, ctrl, index = channel)
	if(IsEmpty(unit))
		printf "(%s) The unit for %s channel %d is empty.\r", device, channelName, channel
		ControlWindowToFront()
		return 1
	endif

	ctrl = GetSpecialControlLabel(channelType, CHANNEL_CONTROL_GAIN)
	gain = DAG_GetNumericalValue(device, ctrl, index = channel)
	if(!IsFinite(gain) || gain == 0)
		printf "(%s) The gain for %s channel %d must be finite and non-zero.\r", device, channelName, channel
		ControlWindowToFront()
		return 1
	endif

	if(channelType == CHANNEL_TYPE_DAC)
		// we allow the scale being zero for DA only
		ctrl  = GetSpecialControlLabel(channelType, CHANNEL_CONTROL_SCALE)
		scale = DAG_GetNumericalValue(device, ctrl, index = channel)
		if(!IsFinite(scale))
			printf "(%s) The scale for %s channel %d must be finite.\r", device, channelName, channel
			ControlWindowToFront()
			return 1
		endif
	endif

	return 0
End

static Function DAP_CheckAnalysisFunctionAndParameter(string device, string setName)

	string func, listOfAnalysisFunctions
	string info, str
	string diff, name, errorMessage
	variable i, j, numEntries

	if(!CmpStr(setName, STIMSET_TP_WHILE_DAQ))
		return 0
	endif

	WAVE/Z stimSet = WB_CreateAndGetStimSet(setName)
	if(!WaveExists(stimSet))
		// we complain later on this error
		return 0
	endif

	if(DAG_GetNumericalValue(device, "Check_Settings_SkipAnalysFuncs"))
		return 0
	endif

	listOfAnalysisFunctions = AFH_GetAnalysisFunctions(ANALYSIS_FUNCTION_VERSION_ALL)

	for(i = 0; i < TOTAL_NUM_EVENTS; i += 1)
		func = WB_ExtractAnalysisFuncFromStimSet(stimSet, i)

		if(isEmpty(func)) // none set
			continue
		endif

		info = FunctionInfo(func)

		if(isEmpty(info))
			printf "(%s) Warning: The analysis function %s for stim set %s and event type \"%s\" could not be found\r", device, func, setName, StringFromList(i, EVENT_NAME_LIST)
			ControlWindowToFront()
			continue
		endif

		if(WhichListItem(func, listOfAnalysisFunctions) == -1) // not a valid analysis function
			printf "(%s) The analysis function %s for stim set %s and event type \"%s\" has an invalid signature or is in an unlisted location\r", device, func, setName, StringFromList(i, EVENT_NAME_LIST)
			ControlWindowToFront()
			return 1
		endif

		if(i == MID_SWEEP_EVENT && !DAG_GetNumericalValue(device, "Check_Settings_BackgrndDataAcq"))
			printf "(%s) The event type \"%s\" for stim set %s can not be used together with foreground DAQ\r", device, StringFromList(i, EVENT_NAME_LIST), setName
			ControlWindowToFront()
			return 1
		endif

		if(i != GENERIC_EVENT)
			FUNCREF AFP_ANALYSIS_FUNC_V3 f3 = $func
			if(FuncRefIsAssigned(FuncRefInfo(f3)))
				printf "(%s) The analysis function %s for stim set %s is of type V3 but associated with the event type \"%s\", which is not supported.\nPlease reassign the analysis function to the stimset in the wavebuilder.\r", device, func, setName, StringFromList(i, EVENT_NAME_LIST)
				ControlWindowToFront()
				return 1
			endif

			continue
		endif

		STRUCT CheckParametersStruct s
		s.params  = WB_ExtractAnalysisFunctionParams(stimSet)
		s.setName = setName

		errorMessage = AFH_CheckAnalysisParameter(func, s)
		if(!IsEmpty(errorMessage))
			printf "(%s) The analysis parameter check for function %s in stim set %s did not pass.\r", device, func, setName
			print errorMessage
			ControlWindowToFront()
			return 1
		endif
	endfor
End

static Function DAP_CheckStimset(string device, variable channelType, variable channel, variable headstage)

	string setName, setNameEnd, channelTypeStr, str
	variable i, numSets

	channelTypeStr = ChannelTypeToString(channelType)

	setName = AFH_GetStimSetName(device, channel, channelType)
	if(!CmpStr(setName, NONE))
		printf "(%s) Please select a stimulus set for %s channel %d referenced by headstage %g\r", device, channelTypeStr, channel, headStage
		ControlWindowToFront()
		return 1
	endif

	if(DAG_GetNumericalValue(device, "Check_DataAcq_Indexing") && CmpStr(setName, STIMSET_TP_WHILE_DAQ))
		setNameEnd = DAG_GetTextualValue(device, GetSpecialControlLabel(channelType, CHANNEL_CONTROL_INDEX_END), index = channel)
		if(!CmpStr(setNameEnd, NONE))
			printf "(%s) Please select a valid indexing end wave for %s channel %d referenced by headstage %g\r", device, channelTypeStr, channel, headStage
			ControlWindowToFront()
			return 1
		elseif(!CmpStr(setName, setNameEnd))
			printf "(%s) Please select a different indexing end stimset for %s channel %d referenced by headstage %g\r", device, channelTypeStr, channel, headStage
			return 1
		endif
	endif

	WAVE/T stimsets = IDX_GetSetsInRange(device, channel, channelType, 0)

	numSets = DimSize(stimsets, ROWS)
	for(i = 0; i < numSets; i += 1)
		setName = stimsets[i]

		if(!CmpStr(setName, STIMSET_TP_WHILE_DAQ))
			if(!IsAssociatedChannel(headstage))
				printf "(%s) Channel %d is an unassociated DA channel. Selection of the \"Test Pulse\" stimset for TP during DAQ is not allowed on unassociated DA channels.\r", device, channel
				ControlWindowToFront()
				return 1
			endif
			continue
		endif

		// third party stim sets might not match our expectations
		WAVE/Z stimSet = WB_CreateAndGetStimSet(setName)

		if(!WaveExists(stimSet))
			printf "(%s) The stim set %s of headstage %g does not exist or could not be created.\r", device, setName, headstage
			ControlWindowToFront()
			return 1
		elseif(DimSize(stimSet, ROWS) == 0)
			printf "(%s) The stim set %s of headstage %g is empty, but must have at least one row.\r", device, setName, headstage
			ControlWindowToFront()
			return 1
		elseif(HasOneNonFiniteEntry(stimSet))
			printf "(%s) The stim set %s of headstage %g has at least one NaN/Inf/-Inf. Please remove them.\r", device, setName, headstage
			ControlWindowToFront()
			return 1
		endif

		// non fatal errors which we fix ourselves
		if(DimDelta(stimSet, ROWS) != WAVEBUILDER_MIN_SAMPINT || DimOffset(stimSet, ROWS) != 0.0 || cmpstr(WaveUnits(stimSet, ROWS), "ms"))
			sprintf str, "(%s) The stim set %s for %s channel of headstage %g must have a row dimension delta of %g, "                          + \
			             "row dimension offset of zero and row unit \"ms\".\r", device, setName, channelTypeStr, headstage, WAVEBUILDER_MIN_SAMPINT
			DEBUGPRINT(str)
			DEBUGPRINT("The stim set is now automatically fixed")
			SetScale/P x, 0, WAVEBUILDER_MIN_SAMPINT, "ms", stimSet
		endif

		if(DAG_GetNumericalValue(device, "Check_Settings_SkipAnalysFuncs") || channelType != CHANNEL_TYPE_DAC)
			continue
		endif

		if(DAP_CheckAnalysisFunctionAndParameter(device, setName))
			return 1
		endif

		if(DAP_CheckEpochLengthsOfStimset(device, setName))
			return 1
		endif
	endfor
End

static Function DAP_CheckEpochLengthsOfStimset(string device, string setName)

	variable sampInt, epochLength, i, numEntries

	if(WB_StimsetIsFromThirdParty(setName))
		return 0
	endif

	WAVE/Z epochLengths = WB_GetEpochLengths(setName)

	if(!WaveExists(epochLengths))
		printf "(%s) The stimset \"%s\" has no epochs.", device, setName
		ControlWindowToFront()
		return 1
	endif

	sampInt = DAP_GetSampInt(device, DATA_ACQUISITION_MODE, XOP_CHANNEL_TYPE_DAC) * MICRO_TO_MILLI

	numEntries = DimSize(epochLengths, ROWS)
	for(i = 0; i < numEntries; i += 1)
		if(epochLengths[i] <= sampInt)
			printf "(%s) Epoch %d of stimset \"%s\" is shorter than the sampling interval. It will therefore not be present in the acquisition.\r", device, i, setName
			ControlWindowToFront()
		endif
	endfor

	return 0
End

/// @brief Synchronizes the contents of `ChanAmpAssign` and
/// `ChanAmpAssignUnit` to all active headstages
static Function DAP_SyncChanAmpAssignToActiveHS(string device)

	variable i, clampMode
	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		clampMode = DAG_GetHeadstageMode(device, i)
		DAP_ApplyClmpModeSavdSettngs(device, i, clampMode)
	endfor
End

/// @brief Reads the channel amp waves and inserts that info into the DA_EPHYS panel
static Function DAP_ApplyClmpModeSavdSettngs(string device, variable headStage, variable clampMode)

	string ctrl, ADUnit, DAUnit
	variable DAGain, ADGain
	variable DACchannel, ADCchannel

	WAVE   ChanAmpAssign     = GetChanAmpAssign(device)
	WAVE   ChannelClampMode  = GetChannelClampMode(device)
	WAVE/T ChanAmpAssignUnit = GetChanAmpAssignUnit(device)
	WAVE   GuiState          = GetDA_EphysGuiStateNum(device)
	WAVE/T GuiStateTxT       = GetDA_EphysGuiStateTxT(device)

	if(clampMode == V_CLAMP_MODE)
		DACchannel = ChanAmpAssign[%VC_DA][headStage]
		ADCchannel = ChanAmpAssign[%VC_AD][headStage]
		DAGain     = ChanAmpAssign[%VC_DAGain][headStage]
		ADGain     = ChanAmpAssign[%VC_ADGain][headStage]
		DAUnit     = ChanAmpAssignUnit[%VC_DAUnit][headStage]
		ADUnit     = ChanAmpAssignUnit[%VC_ADUnit][headStage]
	elseif(ClampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
		DACchannel = ChanAmpAssign[%IC_DA][headStage]
		ADCchannel = ChanAmpAssign[%IC_AD][headStage]
		DAGain     = ChanAmpAssign[%IC_DAGain][headStage]
		ADGain     = ChanAmpAssign[%IC_ADGain][headStage]
		DAUnit     = ChanAmpAssignUnit[%IC_DAUnit][headStage]
		ADUnit     = ChanAmpAssignUnit[%IC_ADUnit][headStage]
	endif

	if(!IsFinite(DACchannel) || !IsFinite(ADCchannel))
		return NaN
	endif

	// DAC channels
	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)
	SetCheckBoxState(device, ctrl, CHECKBOX_SELECTED)
	GuiState[DACchannel][%$GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)] = CHECKBOX_SELECTED
	ctrl                                                                                    = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
	SetSetVariable(device, ctrl, DaGain)
	GuiState[DACchannel][%$GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)] = DAGain
	ctrl                                                                                   = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
	SetSetVariableString(device, ctrl, DaUnit)
	GuiStateTxT[DACchannel][%$GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)] = DAUnit
	ChannelClampMode[DACchannel][%DAC][%ClampMode]                                            = clampMode
	ChannelClampMode[DACchannel][%DAC][%Headstage]                                            = headStage

	// ADC channels
	ctrl = GetPanelControl(ADCchannel, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK)
	SetCheckBoxState(device, ctrl, CHECKBOX_SELECTED)
	GuiState[ADCchannel][%$GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK)] = CHECKBOX_SELECTED
	ctrl                                                                                    = GetPanelControl(ADCchannel, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
	SetSetVariable(device, ctrl, ADGain)
	GuiState[ADCchannel][%$GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)] = ADGain
	ctrl                                                                                   = GetPanelControl(ADCchannel, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
	SetSetVariableString(device, ctrl, ADUnit)
	GuiStateTxT[ADCchannel][%$GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)] = ADUnit
	ChannelClampMode[ADCchannel][%ADC][%ClampMode]                                            = clampMode
	ChannelClampMode[ADCchannel][%ADC][%Headstage]                                            = headStage
End

static Function DAP_RemoveClampModeSettings(string device, variable headStage, variable clampMode)

	string ctrl
	variable DACchannel, ADCchannel

	WAVE ChanAmpAssign    = GetChanAmpAssign(device)
	WAVE ChannelClampMode = GetChannelClampMode(device)
	WAVE GuiState         = GetDA_EphysGuiStateNum(device)

	if(ClampMode == V_CLAMP_MODE)
		DACchannel = ChanAmpAssign[%VC_DA][headStage]
		ADCchannel = ChanAmpAssign[%VC_AD][headStage]
	elseif(ClampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
		DACchannel = ChanAmpAssign[%IC_DA][headStage]
		ADCchannel = ChanAmpAssign[%IC_AD][headStage]
	endif

	if(!IsFinite(DACchannel) || !IsFinite(ADCchannel))
		ChannelClampMode[][][%Headstage] = (ChannelClampMode[p][q][%Headstage] == headstage) ? NaN : ChannelClampMode[p][q][%Headstage]
		return NaN
	endif

	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)
	SetCheckBoxState(device, ctrl, CHECKBOX_UNSELECTED)
	ChannelClampMode[DACchannel][%DAC][]                                                    = NaN
	GuiState[DACchannel][%$GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)] = CHECKBOX_UNSELECTED

	ctrl = GetPanelControl(ADCchannel, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK)
	SetCheckBoxState(device, ctrl, CHECKBOX_UNSELECTED)
	ChannelClampMode[ADCchannel][%ADC][]                                                    = NaN
	GuiState[ADCchannel][%$GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_CHECK)] = CHECKBOX_UNSELECTED
End

/// @brief Returns the name of the checkbox control (radio button) handling the clamp mode of the given headstage or all headstages
/// @param mode			One of the amplifier modes @ref AmplifierClampModes
/// @param headstage	number of the headstage or one of @ref AllHeadstageModeConstants
Function/S DAP_GetClampModeControl(variable mode, variable headstage)

	ASSERT(headStage >= CHANNEL_INDEX_ALL_I_ZERO && headStage < NUM_HEADSTAGES, "invalid headStage index")

	if(headstage >= 0)
		switch(mode)
			case V_CLAMP_MODE:
				return "Radio_ClampMode_" + num2str(headstage * 2)
			case I_CLAMP_MODE:
				return "Radio_ClampMode_" + num2str(headstage * 2 + 1)
			case I_EQUAL_ZERO_MODE:
				return "Radio_ClampMode_" + num2str(headstage * 2 + 1) + "IZ"
			default:
				ASSERT(0, "invalid mode")
				break
		endswitch
	else
		switch(mode)
			case V_CLAMP_MODE:
				return "Radio_ClampMode_AllVClamp"
			case I_CLAMP_MODE:
				return "Radio_ClampMode_AllIClamp"
			case I_EQUAL_ZERO_MODE:
				return "Radio_ClampMode_AllIZero"
			default:
				ASSERT(0, "invalid mode")
				break
		endswitch
	endif
End

/// @brief Return information readout from headstage and clamp mode controls
///
/// Users interested in the clamp mode of a known headstage should prefer DAG_GetHeadstageMode() instead.
///
/// @param[in]  device  panel
/// @param[in]  ctrl        control can be either `Radio_ClampMode_*` or `Check_DataAcqHS_*`
///                         referring to an existing control
/// @param[out] mode        I_CLAMP_MODE, V_CLAMP_MODE or I_EQUAL_ZERO_MODE, the currently active mode for headstage controls
///                         and the clamp mode of the control for clamp mode controls
/// @param[out] headStage   number of the headstage or one of @ref AllHeadstageModeConstants
Function DAP_GetInfoFromControl(string device, string ctrl, variable &mode, variable &headStage)

	string clampMode     = "Radio_ClampMode_"
	string headStageCtrl = "Check_DataAcqHS_"
	variable pos1, pos2, ctrlNo
	string ICctrl, VCctrl, iZeroCtrl, ctrlClean, ctrlSuffix

	mode      = NaN
	headStage = NaN

	ASSERT(!isEmpty(ctrl), "Empty control")

	pos1 = strsearch(ctrl, clampMode, 0)
	pos2 = strsearch(ctrl, headStageCtrl, 0)

	if(pos1 != -1)
		ctrlClean  = RemoveEnding(ctrl, "IZ")
		ctrlSuffix = ctrlClean[pos1 + strlen(clampMode), Inf]
		if(!cmpstr(ctrlSuffix, "AllVclamp"))
			headStage = CHANNEL_INDEX_ALL_V_CLAMP
			mode      = V_CLAMP_MODE
		elseif(!cmpstr(ctrlSuffix, "AllIclamp"))
			headStage = CHANNEL_INDEX_ALL_I_CLAMP
			mode      = I_CLAMP_MODE
		elseif(!cmpstr(ctrlSuffix, "AllIzero"))
			headStage = CHANNEL_INDEX_ALL_I_ZERO
			mode      = I_EQUAL_ZERO_MODE
		else
			ctrlNo = str2num(ctrlSuffix)
			ASSERT(IsFinite(ctrlNo), "non finite number parsed from control")
			if(IsEven(ctrlNo))
				mode      = V_CLAMP_MODE
				headStage = ctrlNo / 2
			else
				if(!cmpstr(ctrlClean, ctrl))
					mode = I_CLAMP_MODE
				else
					mode = I_EQUAL_ZERO_MODE
				endif
				headStage = (ctrlNo - 1) / 2
			endif
		endif
	elseif(pos2 != -1)
		ctrlNo = str2num(ctrl[pos2 + strlen(headStageCtrl), Inf])
		ASSERT(IsFinite(ctrlNo), "non finite number parsed from control")
		headStage = ctrlNo

		VCctrl    = DAP_GetClampModeControl(V_CLAMP_MODE, headstage)
		ICctrl    = DAP_GetClampModeControl(I_CLAMP_MODE, headstage)
		iZeroCtrl = DAP_GetClampModeControl(I_EQUAL_ZERO_MODE, headstage)

		mode = V_CLAMP_MODE // safe default

		// deliberately not using the GUI state wave
		if(GetCheckBoxState(device, VCctrl))
			mode = V_CLAMP_MODE
		elseif(GetCheckBoxState(device, ICctrl))
			mode = I_CLAMP_MODE
		elseif(GetCheckBoxState(device, iZeroCtrl))
			mode = I_EQUAL_ZERO_MODE
		endif
	else
		ASSERT(0, "unhandled control")
	endif

	AI_AssertOnInvalidClampMode(mode)
End

Function DAP_CheckProc_ClampMode(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	variable mode, headStage
	string device, control

	switch(cba.eventCode)
		case 2: // mouse up
			AssertOnAndClearRTError()
			try
				device  = cba.win
				control = cba.ctrlName
				DAP_GetInfoFromControl(device, control, mode, headStage)

				NVAR dataAcqRunMode = $GetDataAcqRunMode(device)
				if(dataAcqRunMode == DAQ_NOT_RUNNING)
					DAP_ChangeHeadStageMode(device, mode, headstage, DO_MCC_MIES_SYNCING)
				else
					WAVE GuiState = GetDA_EphysGuiStateNum(device)
					GuiState[headstage][%HSmode_delayed] = mode
					DAP_SetAmpModeControls(device, headstage, mode, delayed = 1)
				endif
			catch
				ClearRTError()
				SetCheckBoxState(device, control, !cba.checked)
				Abort
			endtry
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_CheckProc_HedstgeChck(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	string device, control
	variable checked

	switch(cba.eventCode)
		case 2: // mouse up
			AssertOnAndClearRTError()
			try
				device  = cba.win
				control = cba.ctrlName
				checked = cba.checked
				DAP_ChangeHeadstageState(device, control, checked)
			catch
				ClearRTError()
				SetCheckBoxState(device, control, !checked)
				Abort
			endtry

			DAG_Update(cba.win, cba.ctrlName, val = cba.checked)
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Change the clamp mode of the given headstage
/// @param device Device
/// @param clampMode  Clamp mode to activate
/// @param headstage  Headstage [0, 8[ or use one of @ref AllHeadstageModeConstants
/// @param options    One of @ref ClampModeChangeOptions
Function DAP_ChangeHeadStageMode(string device, variable clampMode, variable headstage, variable options)

	string iZeroCtrl, VCctrl, ICctrl, headstageCtrl, ctrl
	variable activeHS, testPulseMode, oppositeMode, DAC, ADC, i, oldTab, oldState, newSliderPos

	AI_AssertOnInvalidClampMode(clampMode)
	DAP_AbortIfUnlocked(device)

	if(options != MCC_SKIP_UPDATES)
		// explicitly switch to the data acquistion tab to avoid having
		// the control layout messed up
		oldTab = GetTabID(device, "ADC")
		if(oldTab != 0)
			PGC_SetAndActivateControl(device, "ADC", val = 0)
		endif
	endif

	WAVE ChanAmpAssign = GetChanAmpAssign(device)
	WAVE GuiState      = GetDA_EphysGuiStateNum(device)

	Make/FREE/N=(NUM_HEADSTAGES) changeHS = 0
	if(headstage < 0)
		changeHS[] = 1
		DAP_SetAmpModeControls(device, headstage, clampMode)
		newSliderPos = DAG_GetNumericalValue(device, "slider_DataAcq_ActiveHeadstage")
	else
		changeHS[headstage] = 1
		activeHS            = DAG_GetHeadstageState(device, headstage)
		newSliderPos        = headstage
	endif

	if(options != MCC_SKIP_UPDATES)
		if(activeHS || headstage < 0)
			testPulseMode = TP_StopTestPulse(device)
		endif
	endif

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(!changeHS[i])
			continue
		endif

		if(clampMode == V_CLAMP_MODE)
			DAC = ChanAmpAssign[%VC_DA][i]
			ADC = ChanAmpAssign[%VC_AD][i]
		elseif(clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE)
			DAC = ChanAmpAssign[%IC_DA][i]
			ADC = ChanAmpAssign[%IC_AD][i]
		endif

		if(!IsFinite(DAC) || !IsFinite(ADC))
			printf "(%s) Could not switch the clamp mode to %s as no DA and/or AD channels are associated with headstage %d.\r", device, ConvertAmplifierModeToString(clampMode), headstage
			continue
		endif

		PUB_ClampModeChange(device, i, GuiState[i][%HSmode], clampMode)

		GuiState[i][%HSmode] = clampMode

		if(options != MCC_SKIP_UPDATES)
			DAP_SetAmpModeControls(device, i, clampMode)
			DAP_SetHeadstageChanControls(device, i, clampMode, delayed = IsFinite(GuiState[i][%HSmode_delayed]))
		endif

		AI_SetClampMode(device, i, clampMode, zeroStep = DAG_GetNumericalValue(device, "check_Settings_AmpIEQZstep"))
	endfor

	if(options == MCC_SKIP_UPDATES)
		// we are done
		return NaN
	elseif(options == DO_MCC_MIES_SYNCING)
		PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = newSliderPos)
	elseif(options == NO_SLIDER_MOVEMENT)
		// do nothing
	else
		ASSERT(0, "Unsupported option: " + num2str(options))
	endif

	DAP_UpdateDAQControls(device, REASON_HEADSTAGE_CHANGE)

	if(activeHS || headstage < 0)
		TP_RestartTestPulse(device, testPulseMode)
	endif

	if(oldTab != 0)
		PGC_SetAndActivateControl(device, "ADC", val = oldTab)
	endif
End

///@brief Sets the control state of the radio buttons used for setting the clamp mode on the Data Acquisition Tab of the DA_Ephys panel
///@param device	device
///@param headstage		controls associated with headstage are set
///@param clampMode		clamp mode to activate
///@param delayed       indicate on the control that the change is delayed
static Function DAP_SetAmpModeControls(string device, variable headstage, variable clampMode, [variable delayed])

	if(ParamIsDefault(delayed))
		delayed = 0
	else
		delayed = !!delayed
	endif

	string VCctrl    = DAP_GetClampModeControl(V_CLAMP_MODE, headstage)
	string ICctrl    = DAP_GetClampModeControl(I_CLAMP_MODE, headstage)
	string iZeroCtrl = DAP_GetClampModeControl(I_EQUAL_ZERO_MODE, headstage)
	string ctrl      = DAP_GetClampModeControl(clampMode, headstage)

	SetCheckboxState(device, VCctrl, CHECKBOX_UNSELECTED)
	SetCheckboxState(device, ICctrl, CHECKBOX_UNSELECTED)
	SetCheckboxState(device, iZeroCtrl, CHECKBOX_UNSELECTED)

	if(headstage >= 0)
		SetCheckboxState(device, ctrl, CHECKBOX_SELECTED)
	endif

	if(delayed)
		SetControlTitle(device, ctrl, "D")
		SetControlTitleColor(device, ctrl, 1, 39321, 19939)
	else
		DAP_ResetClampModeTitle(device, ctrl)
	endif
End

/// @brief Sets the DA and AD channel settings according to the headstage mode
///
/// @param device Device (used for data acquisition)
/// @param headstage  Channels associated with headstage are set
/// @param clampMode  Clamp mode to activate
/// @param delayed    [optional, defaults to false] Indicate that this is a delayed clamp mode change
static Function DAP_SetHeadstageChanControls(string device, variable headstage, variable clampMode, [variable delayed])

	variable oppositeMode

	if(!DAG_GetHeadstageState(device, headstage))
		return NaN
	endif

	oppositeMode = ((clampMode == I_CLAMP_MODE || clampMode == I_EQUAL_ZERO_MODE) ? V_CLAMP_MODE : I_CLAMP_MODE)
	DAP_RemoveClampModeSettings(device, headstage, oppositeMode)
	DAP_ApplyClmpModeSavdSettngs(device, headstage, clampMode)
	DAP_AllChanDASettings(device, headStage, delayed = delayed)
End

static Function DAP_UpdateClampmodeTabs(string device, variable headStage, variable clampMode)

	string highlightSpec = "\\f01\\Z11"

	AI_AssertOnInvalidClampMode(clampMode)

	AI_SyncAmpStorageToGUI(device, headStage)
	PGC_SetAndActivateControl(device, "tab_DataAcq_Amp", val = clampMode)

	if(DAG_GetNumericalValue(device, "check_Settings_SyncMiesToMCC"))
		AI_SyncGUIToAmpStorageAndMCCApp(device, headStage, clampMode)
	endif

	TabControl tab_DataAcq_Amp, win=$device, tabLabel(V_CLAMP_MODE)=SelectString(clampMode == V_CLAMP_MODE, "", highlightSpec) + "V-Clamp"
	TabControl tab_DataAcq_Amp, win=$device, tabLabel(I_CLAMP_MODE)=SelectString(clampMode == I_CLAMP_MODE, "", highlightSpec) + "I-Clamp"
	TabControl tab_DataAcq_Amp, win=$device, tabLabel(I_EQUAL_ZERO_MODE)=SelectString(clampMode == I_EQUAL_ZERO_MODE, "", highlightSpec) + "I = 0"
End

static Function DAP_ChangeHeadstageState(string device, string headStageCtrl, variable enabled)

	variable clampMode, headStage, TPState, ICstate, VCstate, IZeroState
	variable channelType, controlType, i
	string VCctrl, ICctrl, IZeroCtrl

	DAP_AbortIfUnlocked(device)

	WAVE GUIState = GetDA_EphysGuiStateNum(device)

	ASSERT(!DAP_ParsePanelControl(headStageCtrl, headstage, channelType, controlType), "Invalid control format")
	ASSERT(channelType == CHANNEL_TYPE_HEADSTAGE && controlType == CHANNEL_CONTROL_CHECK, "Expected headstage checkbox control")

	TPState = TP_StopTestPulse(device)

	Make/FREE/N=(NUM_HEADSTAGES) changeHS = 0
	if(headstage >= 0)
		changeHS[headstage] = 1
	else
		changeHS[] = 1
	endif

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if(!changeHS[i])
			continue
		endif

		headStageCtrl = GetPanelControl(i, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
		SetCheckBoxState(device, headStageCtrl, enabled)

		GuiState[i][%$GetSpecialControlLabel(CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)] = enabled

		clampMode = GuiState[i][%HSmode]
		if(!enabled)
			DAP_RemoveClampModeSettings(device, i, clampMode)
			P_SetPressureMode(device, i, PRESSURE_METHOD_ATM)
			P_UpdatePressureType(device)
		else
			DAP_ApplyClmpModeSavdSettngs(device, i, clampMode)
		endif

		VCctrl    = DAP_GetClampModeControl(V_CLAMP_MODE, i)
		ICctrl    = DAP_GetClampModeControl(I_CLAMP_MODE, i)
		IZeroCtrl = DAP_GetClampModeControl(I_EQUAL_ZERO_MODE, i)

		// deliberately not using the GUI state wave
		VCstate    = GetCheckBoxState(device, VCctrl)
		ICstate    = GetCheckBoxState(device, ICctrl)
		IZeroState = GetCheckBoxState(device, IZeroCtrl)

		if((VCstate + ICstate + IZeroState) != 1) // someone messed up the radio button logic, reset to V_CLAMP_MODE
			PGC_SetAndActivateControl(device, VCctrl, val = CHECKBOX_SELECTED)
		else
			if(enabled && DAG_GetNumericalValue(device, "check_Settings_SyncMiesToMCC"))
				PGC_SetAndActivateControl(device, DAP_GetClampModeControl(clampMode, i), val = CHECKBOX_SELECTED)
			endif
		endif
	endfor

	DAP_UpdateDAQControls(device, REASON_STIMSET_CHANGE | REASON_HEADSTAGE_CHANGE)

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)
	if(Sum(statusHS) > 0)
		TP_RestartTestPulse(device, TPState)
	endif
End

/// @brief Set the acquisition button text
///
/// @param device device
/// @param mode       One of @ref ToggleAcquisitionButtonConstants
Function DAP_ToggleAcquisitionButton(string device, variable mode)

	ASSERT(mode == DATA_ACQ_BUTTON_TO_STOP || mode == DATA_ACQ_BUTTON_TO_DAQ, "Invalid mode")

	string text

	if(mode == DATA_ACQ_BUTTON_TO_STOP)
		text = "\\Z14\\f01Stop\rAcquistion"
	elseif(mode == DATA_ACQ_BUTTON_TO_DAQ)
		text = "\\Z14\\f01Acquire\rData"
	endif

	Button DataAcquireButton, title=text, win=$device
End

/// @brief Set the testpulse button text
///
/// @param device device
/// @param mode       One of @ref ToggleTestpulseButtonConstants
Function DAP_ToggleTestpulseButton(string device, variable mode)

	ASSERT(mode == TESTPULSE_BUTTON_TO_STOP || mode == TESTPULSE_BUTTON_TO_START, "Invalid mode")

	string text

	if(mode == TESTPULSE_BUTTON_TO_STOP)
		text = "\\Z14\\f01Stop Test \rPulse"
	elseif(mode == TESTPULSE_BUTTON_TO_START)
		text = "\\Z14\\f01Start Test \rPulse"
	endif

	Button StartTestPulseButton, title=text, win=$device
End

Function DAP_ButtonProc_AutoFillGain(STRUCT WMButtonAction &ba) : ButtonControl

	string   device
	variable numConnAmplifiers

	switch(ba.eventCode)
		case 2: // mouse up
			device = ba.win

			DAP_AbortIfUnlocked(device)

			numConnAmplifiers = AI_QueryGainsFromMCC(device)

			if(numConnAmplifiers)
				DAP_UpdateChanAmpAssignPanel(device)
				DAP_SyncChanAmpAssignToActiveHS(device)
			else
				printf "(%s) Could not find any amplifiers connected with headstages.\r", device
			endif
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_SliderProc_MIESHeadStage(STRUCT WMSliderAction &sc) : SliderControl

	variable mode, headstage
	string device

	// eventCode is a bitmask as opposed to a plain value
	// compared to other controls
	if(sc.eventCode > 0 && (sc.eventCode & 0x1))
		headstage = sc.curval
		device    = sc.win
		DAG_Update(device, sc.ctrlName, val = headstage)

		DAP_AbortIfUnlocked(device)
		mode = DAG_GetHeadstageMode(device, headStage)
		P_PressureDisplayHighlite(device, 0)
		P_SaveUserSelectedHeadstage(device, headStage)
		P_GetAutoUserOff(device)
		P_UpdatePressureType(device)
		P_LoadPressureButtonState(device)
		P_UpdatePressureModeTabs(device, headStage)
		DAP_UpdateClampmodeTabs(device, headStage, mode)
		SCOPE_SetADAxisLabel(device, UNKNOWN_MODE, HeadStage)
		P_RunP_ControlIfTPOFF(device)
		DAP_TPSettingsToGUI(device)
	endif

	return 0
End

Function DAP_SetVarProc_AmpCntrls(STRUCT WMSetVariableAction &sva) : SetVariableControl

	string device, ctrl
	variable headStage

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
			device = sva.win
			ctrl   = sva.ctrlName
			DAG_Update(sva.win, sva.ctrlName, val = sva.dval)
			headStage = DAG_GetNumericalValue(device, "slider_DataAcq_ActiveHeadstage")
			AI_UpdateAmpModel(device, ctrl, headStage)
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_ButtonProc_AmpCntrls(STRUCT WMButtonAction &ba) : ButtonControl

	string device, ctrl
	variable headStage

	switch(ba.eventCode)
		case 2: // mouse up
			device = ba.win
			ctrl   = ba.ctrlName

			headStage = DAG_GetNumericalValue(device, "slider_DataAcq_ActiveHeadstage")
			AI_UpdateAmpModel(device, ctrl, headstage)
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_CheckProc_AmpCntrls(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	string device, ctrl
	variable headStage

	switch(cba.eventCode)
		case 2: // mouse up
			device = cba.win
			ctrl   = cba.ctrlName

			DAG_Update(cba.win, cba.ctrlName, val = cba.checked)
			headStage = DAG_GetNumericalValue(device, "slider_DataAcq_ActiveHeadstage")
			AI_UpdateAmpModel(device, ctrl, headStage)
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Check box procedure for multiple device (MD) support
Function DAP_CheckProc_MDEnable(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	variable checked
	string   device

	switch(cba.eventCode)
		case 2: // mouse up
			device  = cba.win
			checked = cba.checked
			DAG_Update(device, cba.ctrlName, val = checked)
			AdaptDependentControls(device, "Check_Settings_BkgTP;Check_Settings_BackgrndDataAcq", CHECKBOX_UNSELECTED, checked, DEP_CTRLS_SAME)
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Enable controls post DAQ/TP in single device mode
///
/// @param device device
Function DAP_HandleSingleDeviceDependentControls(string device)

	variable useMultiDevice

	useMultiDevice = DAG_GetNumericalValue(device, "check_Settings_MD")

	if(!useMultiDevice)
		ASSERT(!cmpstr(CONTROLS_DISABLE_DURING_DAQ_TP, "Check_Settings_BkgTP;Check_Settings_BackgrndDataAcq"), "Control lists deviated")
		EnableControls(device, CONTROLS_DISABLE_DURING_DAQ_TP)
	endif
End

/// @brief Controls TP Insertion into set sweeps before the sweep begins
Function DAP_CheckProc_InsertTP(STRUCT WMCheckBoxAction &cba) : CheckBoxControl

	string device

	switch(cba.eventCode)
		case 2:
			DAG_Update(cba.win, cba.ctrlName, val = cba.checked)
			device = cba.win
			DAP_UpdateOnsetDelay(cba.win)
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Update the onset delay due to the `Insert TP` setting
Function DAP_UpdateOnsetDelay(string device)

	variable testPulseDurWithBL

	if(DAG_GetNumericalValue(device, "Check_Settings_InsertTP"))
		TP_UpdateTPSettingsCalculated(device)

		WAVE TPSettingsCalculated = GetTPSettingsCalculated(device)

		testPulseDurWithBL = TPSettingsCalculated[%totalLengthMS]
	else
		testPulseDurWithBL = 0
	endif

	SetValDisplay(device, "valdisp_DataAcq_OnsetDelayAuto", var = testPulseDurWithBL)
End

Function DAP_SetVarProc_TestPulseSett(STRUCT WMSetVariableAction &sva) : SetVariableControl

	variable TPState
	string   device

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			sva.blockReentry = 1
			device           = sva.win
			DAP_AbortIfUnlocked(device)
			DAG_Update(sva.win, sva.ctrlName, val = sva.dval)

			DAP_TPGUISettingToWave(device, sva.ctrlName, sva.dval)
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_CheckProc_TestPulseSett(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	string device, ctrl
	variable saveTP, dataAcqRunMode, checked

	switch(cba.eventCode)
		case 2: // mouse up
			device  = cba.win
			ctrl    = cba.ctrlName
			checked = cba.checked

			DAP_AbortIfUnlocked(device)
			DAG_Update(device, ctrl, val = checked)

			DAP_TPGUISettingToWave(device, ctrl, checked)
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_AdaptAutoTPColorAndDependent(string device)

	variable runMode, hasAutoTPActive, disabledSaveTP

	runMode = RoVAR(GetTestpulseRunMode(device))

	hasAutoTPActive = TP_AutoTPActive(device)

	disabledSaveTP = IsControlDisabled(device, "check_Settings_TP_SaveTP")

	if(hasAutoTPActive && !disabledSaveTP)
		AdaptDependentControls(device, "check_Settings_TP_SaveTP", CHECKBOX_UNSELECTED, CHECKBOX_SELECTED, DEP_CTRLS_SAME)
	elseif(!hasAutoTPActive && disabledSaveTP)
		AdaptDependentControls(device, "check_Settings_TP_SaveTP", CHECKBOX_UNSELECTED, CHECKBOX_UNSELECTED, DEP_CTRLS_SAME)
	endif

	if(hasAutoTPActive && runMode != TEST_PULSE_NOT_RUNNING && !(runMode & TEST_PULSE_DURING_RA_MOD))
		CheckBox check_DataAcq_AutoTP, win=$device, labelBack=(3, 52428, 1, 0.5 * 65535)
	else
		CheckBox check_DataAcq_AutoTP, win=$device, labelBack=0
	endif
End

Function DAP_UnlockAllDevices()

	string list = GetListOfLockedDevices()
	string win
	variable i, numItems

	numItems = ItemsInList(list)
	for(i = 0; i < numItems; i += 1)
		win = StringFromList(i, list)
		DAP_UnlockDevice(win)
	endfor
End

Function DAP_CheckProc_RepeatedAcq(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	switch(cba.eventCode)
		case 2: // mouse up
			DAG_Update(cba.win, cba.ctrlName, val = cba.checked)
			DAP_UpdateSweepSetVariables(cba.win)
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Allows two checkboxes to be treated
///        as a group where only one can be checked at a time.
///
/// Write into the GUI state wave as well
static Function DAP_ToggleCheckBoxes(string win, string ctrl, string list, variable checked)

	string partner

	ASSERT(!IsEmpty(ctrl), "Expected non empty control")
	ASSERT(ItemsInList(list) == 2, "Expected a list of two")

	partner = StringFromList(mod(WhichListItem(ctrl, list) + 1, 2), list)
	ASSERT(!IsEmpty(partner), "Invalid ctrl or list")

	DAG_Update(win, partner, val = !checked)
	SetCheckBoxState(win, partner, !checked)
End

Function DAP_CheckProc_SyncCtrl(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	switch(cba.eventCode)
		case 2: // mouse up

			if(cba.checked)
				DAP_ToggleCheckBoxes(cba.win, cba.ctrlName, "Check_DataAcq1_DistribDaq;Check_DataAcq1_dDAQOptOv", cba.checked)
			endif

			DAG_Update(cba.win, cba.ctrlName, val = cba.checked)
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_SetVarProc_SyncCtrl(STRUCT WMSetVariableAction &sva) : SetVariableControl

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			DAG_Update(sva.win, sva.ctrlName, val = sva.dval)
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_ButtonProc_TPDAQ(STRUCT WMButtonAction &ba) : ButtonControl

	string   device
	variable testpulseRunMode

	switch(ba.eventcode)
		case 2:
			ba.blockreentry = 1
			device          = ba.win

			DAP_AbortIfUnlocked(device)

			if(!cmpstr(ba.ctrlName, "StartTestPulseButton"))

				NVAR dataAcqRunMode = $GetDataAcqRunMode(device)

				// if data acquisition is currently running we just
				// call TP_StartTestPulse* which automatically ends DAQ
				if(dataAcqRunMode == DAQ_NOT_RUNNING && TP_CheckIfTestpulseIsRunning(device))
					TP_StopTestPulse(device)
				elseif(DAG_GetNumericalValue(device, "check_Settings_MD"))
					TPM_StartTestPulseMultiDevice(device)
				else
					TPS_StartTestPulseSingleDevice(device)
				endif
			elseif(!cmpstr(ba.ctrlName, "DataAcquireButton"))

				NVAR dataAcqRunMode = $GetDataAcqRunMode(device)

				if(dataAcqRunMode == DAQ_NOT_RUNNING)
					testpulseRunMode = TP_StopTestPulse(device)
					if(DAP_CheckSettings(device, DATA_ACQUISITION_MODE))
						AS_HandlePossibleTransition(device, AS_INACTIVE)
						TP_RestartTestPulse(device, testpulseRunMode)
						Abort
					endif

					if(DAG_GetNumericalValue(device, "check_Settings_MD"))
						DQM_StartDAQMultiDevice(device)
					else
						DQS_StartDAQSingleDevice(device)
					endif
				else // data acquistion is ongoing, stop data acq
					DQ_StopDAQ(device, DQ_STOP_REASON_DAQ_BUTTON)
				endif
			else
				ASSERT(0, "invalid control")
			endif
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Return the comment panel name
Function/S DAP_GetCommentPanel(string device)

	return device + "#" + COMMENT_PANEL
End

/// @brief Return the full window path to the comment notebook
Function/S DAP_GetCommentNotebook(string device)

	return DAP_GetCommentPanel(device) + "#" + COMMENT_PANEL_NOTEBOOK
End

/// @brief Create the comment panel
static Function DAP_OpenCommentPanel(string device)

	string commentPanel, commentNotebook

	DAP_AbortIfUnlocked(device)

	commentPanel = DAP_GetCommentPanel(device)
	if(windowExists(commentPanel))
		return NaN
	endif

	commentNotebook = DAP_GetCommentNotebook(device)

	NewPanel/HOST=$device/N=$COMMENT_PANEL/EXT=1/W=(400, 0, 0, 200)
	NewNotebook/HOST=$commentPanel/F=0/N=$COMMENT_PANEL_NOTEBOOK/FG=(FL, FT, FR, FB)
	ModifyPanel/W=$commentPanel fixedSize=0
	SetWindow $commentPanel, hook(mainHook)=DAP_CommentPanelHook

	SVAR userComment = $GetUserComment(device)
	ReplaceNotebookText(commentNotebook, userComment)
End

Function DAP_ButtonProc_OpenCommentNB(STRUCT WMButtonAction &ba) : ButtonControl

	string device

	switch(ba.eventCode)
		case 2: // mouse up
			device = ba.win

			DAP_OpenCommentPanel(device)
			DAP_AddUserComment(device)
			break
		default:
			break
	endswitch

	return 0
End

static Function/S DAP_FormatCommentString(string device, string comment, variable sweepNo)

	string str, contents, commentNotebook
	variable length

	ASSERT(!IsEmpty(comment), "Comment can not be empty")
	sweepNo = IsNaN(sweepNo) ? -1 : sweepNo

	sprintf str, "%s, % 5d: %s\r", GetTimeStamp(humanReadable = 1), sweepNo, comment

	DAP_OpenCommentPanel(device)
	commentNotebook = DAP_GetCommentNotebook(device)
	contents        = GetNotebookText(commentNotebook)

	// add a carriage return if the last line does not end with one
	length = strlen(contents)
	if(length > 0 && cmpstr(contents[length - 1], "\r"))
		str = "\r" + str
	endif

	return str
End

/// @brief Add the current user comment of the previous sweep
///        to the comment notebook and to the labnotebook.
///
/// The `SetVariable` for the user comment is also cleared
static Function DAP_AddUserComment(string device)

	string commentNotebook, comment, formattedComment
	variable sweepNo

	if(!WindowExists(device))
		return NaN
	endif

	comment = DAG_GetTextualValue(device, "SetVar_DataAcq_Comment")

	if(isEmpty(comment))
		return NaN
	endif

	DAP_OpenCommentPanel(device)

	sweepNo = AFH_GetLastSweepAcquired(device)

	commentNotebook  = DAP_GetCommentNotebook(device)
	formattedComment = DAP_FormatCommentString(device, comment, sweepNo)
	AppendToNotebookText(commentNotebook, formattedComment)
	NotebookSelectionAtEnd(commentNotebook)

	// after writing the user comment, clear it
	ED_WriteUserCommentToLabNB(device, comment, sweepNo)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_Comment", str = "")
End

/// @brief Make the comment notebook read-only
Function DAP_LockCommentNotebook(string device)

	string commentPanel, commentNotebook

	commentPanel = DAP_GetCommentPanel(device)
	if(!windowExists(commentPanel))
		return NaN
	endif

	commentNotebook = DAP_GetCommentNotebook(device)
	Notebook $commentNotebook, writeProtect=1, changeableByCommandOnly=1
	DoWindow/W=$commentPanel/T $COMMENT_PANEL, COMMENT_PANEL + " (Lock device to make it writeable again)"
End

/// @brief Make the comment notebook writeable
Function DAP_UnlockCommentNotebook(string device)

	string commentPanel, commentNotebook

	commentPanel = DAP_GetCommentPanel(device)
	if(!windowExists(commentPanel))
		return NaN
	endif

	commentNotebook = DAP_GetCommentNotebook(device)
	Notebook $commentNotebook, writeProtect=0, changeableByCommandOnly=0

	DoWindow/W=$commentPanel/T $COMMENT_PANEL, COMMENT_PANEL
End

/// @brief Clear the comment notebook's content and the serialized string
Function DAP_ClearCommentNotebook(string device)

	string commentPanel, commentNotebook

	SVAR userComment = $GetUserComment(device)
	userComment = ""

	commentPanel = DAP_GetCommentPanel(device)
	if(!windowExists(commentPanel))
		return NaN
	endif

	commentNotebook = DAP_GetCommentNotebook(device)
	ReplaceNotebookText(commentNotebook, "")
End

/// @brief Serialize all comment notebooks
Function DAP_SerializeAllCommentNBs()

	string list = GetListOfLockedDevices()
	CallFunctionForEachListItem(DAP_SerializeCommentNotebook, list)
End

/// @brief Copy the contents of the comment notebook to the user comment string
Function DAP_SerializeCommentNotebook(string device)

	string commentPanel, commentNotebook, text

	DAP_AddUserComment(device)

	commentPanel = DAP_GetCommentPanel(device)
	if(!windowExists(commentPanel))
		return NaN
	endif

	commentNotebook = DAP_GetCommentNotebook(device)
	text            = GetNotebookText(commentNotebook)

	if(isEmpty(text))
		return NaN
	endif

	SVAR userComment = $GetUserComment(device)
	userComment = text

	NotebookSelectionAtEnd(commentNotebook)
End

Function DAP_CommentPanelHook(STRUCT WMWinHookStruct &s)

	string device

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_KILL:
			device = GetMainWindow(s.winName)

			if(!DAP_DeviceIsUnlocked(device))
				DAP_SerializeCommentNotebook(device)
			endif
			break
		default:
			break
	endswitch

	// return zero so that other hooks are called as well
	return 0
End

/// @brief Create a new DA_Ephys panel
///
/// @returns panel name
Function/S DAP_CreateDAEphysPanel()

	string panel

	UploadPingPeriodically()

	if(!WindowExists("HistoryCarbonCopy"))
		CreateHistoryNotebook()
	endif

	// upgrade folder locations
	GetDAQDevicesFolder()

	// fetch device lists
	DAP_GetNIDeviceList()
	DAP_GetITCDeviceList()
	DAP_GetSUDeviceList()

	Execute "DA_Ephys()"
	panel = GetCurrentWindow()
	SCOPE_OpenScopeWindow(panel)
	AddVersionToPanel(panel, DA_EPHYS_PANEL_VERSION)

	NVAR JSONid = $GetSettingsJSONid()
	PS_InitCoordinates(JSONid, panel, "daephys")

	return panel
End

/// @brief	Sets the locked indexing logic checkbox states
Function DAP_CheckProc_LockedLogic(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	switch(cba.eventCode)
		case 2: // mouse up
			DAG_Update(cba.win, cba.ctrlName, val = cba.checked)
			string checkBoxPartener = SelectString(cmpstr(cba.ctrlName, "check_Settings_Option_3"), "check_Settings_SetOption_5", "check_Settings_Option_3")
			ToggleCheckBoxes(cba.win, cba.ctrlName, checkBoxPartener, cba.checked)
			EqualizeCheckBoxes(cba.win, "check_Settings_Option_3", "Check_DataAcq1_IndexingLocked", DAG_GetNumericalValue(cba.win, "check_Settings_Option_3"))
			if(cmpstr(cba.win, "check_Settings_Option_3") == 0 && cba.checked)
				PGC_SetAndActivateControl(cba.win, "Check_DataAcq_Indexing", val = 1)
			endif
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Extracts `channelType`, `controlType` and `channelIndex` from `ctrl`
///
/// Counterpart to GetPanelControl()
///
/// @return 0 if the control name could be parsed, one otherwise
///
/// UTF_NOINSTRUMENTATION
Function DAP_ParsePanelControl(string ctrl, variable &channelIndex, variable &channelType, variable &controlType)

	string elem0, elem1, elem2
	variable numUnderlines

	channelIndex = NaN
	channelType  = NaN
	controlType  = NaN

	if(isEmpty(ctrl))
		return 1
	endif

	numUnderlines = ItemsInList(ctrl, "_")
	if(numUnderlines < 2)
		return 1
	endif

	elem0 = StringFromList(0, ctrl, "_")
	elem1 = StringFromList(1, ctrl, "_")
	elem2 = StringFromList(numUnderlines - 1, ctrl, "_")

	strswitch(elem0)
		case "Wave":
			controlType = CHANNEL_CONTROL_WAVE
			break
		case "IndexEnd":
			controlType = CHANNEL_CONTROL_INDEX_END
			break
		case "Unit":
			controlType = CHANNEL_CONTROL_UNIT
			break
		case "Gain":
			controlType = CHANNEL_CONTROL_GAIN
			break
		case "Scale":
			controlType = CHANNEL_CONTROL_SCALE
			break
		case "Check":
			controlType = CHANNEL_CONTROL_CHECK
			break
		case "Min":
			controlType = CHANNEL_CONTROL_ALARM_MIN
			break
		case "Max":
			controlType = CHANNEL_CONTROL_ALARM_MAX
			break
		case "Search":
			controlType = CHANNEL_CONTROL_SEARCH
			break
		case "Title":
			controlType = CHANNEL_CONTROL_TITLE
			break
		default:
			channelIndex = NaN
			channelType  = NaN
			controlType  = NaN
			return 1
			break
	endswitch

	channelType = ParseChannelTypeFromString(elem1, allowFail = 1)

	if(IsNaN(channelType))
		channelIndex = NaN
		channelType  = NaN
		controlType  = NaN

		return 1
	endif

	strswitch(elem2)
		case "All":
			channelIndex = CHANNEL_INDEX_ALL
			break
		case "AllVClamp":
			channelIndex = CHANNEL_INDEX_ALL_V_CLAMP
			break
		case "AllIClamp":
			channelIndex = CHANNEL_INDEX_ALL_I_CLAMP
			break
		default:
			channelIndex = str2numSafe(elem2)
			if(!IsFinite(channelIndex))
				channelIndex = NaN
				channelType  = NaN
				controlType  = NaN
				return 1
			endif
			break
	endswitch

	return 0
End

/// @brief Update the list of available pressure devices on all locked device panels
Function DAP_UpdateListOfPressureDevices()

	string list, device
	variable i, numItems

	list     = GetListOfLockedDevices()
	numItems = ItemsInList(list)

	for(i = 0; i < numItems; i += 1)
		device = StringFromList(i, list)
		PGC_SetAndActivateControl(device, "button_Settings_UpdateDACList")
	endfor
End

/// @brief Query the device lock status
///
/// @returns device lock status, 1 if unlocked, 0 if locked
Function DAP_DeviceIsUnlocked(string device)

	return WhichListItem(device, GetListOfLockedDevices(), ";", 0, 0) == -1
End

Function DAP_AbortIfUnlocked(string device)

	if(DAP_DeviceIsUnlocked(device))
		DoAbortNow("A device must be locked (see Hardware tab) to proceed")
	endif
End

/// @brief GUI procedure which has the only purpose
///        of storing the control state in the GUI state wave
Function DAP_CheckProc_UpdateGuiState(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	switch(cba.eventCode)
		case 2: // mouse up
			DAG_Update(cba.win, cba.ctrlName, val = cba.checked)
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_SetVar_SetScale(STRUCT WMSetVariableAction &sva) : SetVariableControl

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
		case 8: // end edit
			DAG_Update(sva.win, sva.ctrlName, val = sva.dval, str = sva.sval)
			break
		case 9: // mouse down
			ShowSetVariableLimitsSelectionPopup(sva)
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_SetVar_UpdateGuiState(STRUCT WMSetVariableAction &sva) : SetVariableControl

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
		case 8: // end edit
			DAG_Update(sva.win, sva.ctrlName, val = sva.dval, str = sva.sval)
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_CheckProc_Settings_PUser(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	variable headstage

	switch(cba.eventCode)
		case 2: // mouse up
			DAP_AbortIfUnlocked(cba.win)
			DAG_Update(cba.win, cba.ctrlName, val = cba.checked)
			WAVE pressureDataWv = P_GetPressureDataWaveRef(cba.win)
			P_RunP_ControlIfTPOFF(cba.win)
			headstage = PressureDataWv[0][%UserSelectedHeadStage]
			if(P_ValidatePressureSetHeadstage(cba.win, headstage))
				P_SetPressureValves(cba.win, headstage, P_GetUserAccess(cba.win, headstage, PressureDataWv[headstage][%Approach_Seal_BrkIn_Clear]))
			endif
			P_UpdatePressureType(cba.win)

			break
		default:
			break
	endswitch

	return 0
End

Function DAP_ButtonProc_LockDev(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			ba.blockReentry = 1
			DAP_LockDevice(ba.win)
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_ButProc_Hrdwr_UnlckDev(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			ba.blockReentry = 1
			DAP_UnlockDevice(ba.win)
			break
		default:
			break
	endswitch

	return 0
End

static Function DAP_UpdateDataFolderDisplay(string device, variable locked)

	string title
	if(locked)
		title = "Data folder path = " + GetDevicePathAsString(device)
	else
		title = "Lock a device to generate device folder structure"
	endif

	GroupBox group_Hardware_FolderPath, win=$device, title=title
End

Function DAP_LockDevice(string win)

	variable locked, hardwareType, headstage
	string deviceLocked, msg

	SVAR miesVersion = $GetMiesVersion()

	if(!cmpstr(miesVersion, UNKNOWN_MIES_VERSION))
		DEBUGPRINT_OR_ABORT("The MIES version is unknown, locking devices is therefore only allowed in debug mode.")
	endif

	deviceLocked = GetPopupMenuString(win, "popup_MoreSettings_Devices")
	if(windowExists(deviceLocked))
		DoAbortNow("Attempt to duplicate device connection! Please choose another device number as that one is already in use.")
	endif

	if(!cmpstr(deviceLocked, NONE))
		DoAbortNow("Please select a valid device.")
	endif

	if(!HasPanelLatestVersion(win, DA_EPHYS_PANEL_VERSION))
		DoAbortNow("Can not lock the device. The DA_Ephys panel is too old to be usable. Please close it and open a new one.")
	endif

	NVAR deviceID = $GetDAQDeviceID(deviceLocked)
	deviceID = HW_OpenDevice(deviceLocked, hardwareType)

	if(deviceID < 0 || deviceID >= HARDWARE_MAX_DEVICES)
#ifndef EVIL_KITTEN_EATING_MODE
		DoAbortNow("Can not lock the device.")
#else
		print "EVIL_KITTEN_EATING_MODE is ON: Forcing deviceID to zero"
		ControlWindowToFront()
		deviceID = 0
#endif // !EVIL_KITTEN_EATING_MODE
	endif

	DisableControls(win, "button_SettingsPlus_LockDevice;popup_MoreSettings_Devices;button_hardware_rescan")
	EnableControl(win, "button_SettingsPlus_unLockDevic")

	DoWindow/W=$win/C $deviceLocked

	KillOrMoveToTrash(wv = GetChannelClampMode(deviceLocked))
	KillOrMoveToTrash(wv = GetDA_EphysGuiStateNum(deviceLocked))
	KillOrMoveToTrash(wv = GetDA_EphysGuiStateTxT(deviceLocked))
	// initial fill of the GUI state wave
	// all other changes are propagated immediately to the GUI state waves
	DAG_RecordGuiStateNum(deviceLocked)
	DAG_RecordGuiStateTxT(deviceLocked)

	locked = 1
	DAP_UpdateDataFolderDisplay(deviceLocked, locked)

	AI_FindConnectedAmps()
	DAP_UpdateListOfLockedDevices()
	DAP_UpdateListOfPressureDevices()
	headstage = str2num(GetPopupMenuString(deviceLocked, "Popup_Settings_HeadStage"))
	DAP_SyncDeviceAssocSettToGUI(deviceLocked, headstage)

	DAP_UpdateDAQControls(deviceLocked, REASON_STIMSET_CHANGE | REASON_HEADSTAGE_CHANGE)
	// create the amplifier settings waves
	GetAmplifierParamStorageWave(deviceLocked)
	WB_UpdateChangedStimsets(device = deviceLocked)
	DAP_UnlockCommentNotebook(deviceLocked)
	DAP_ToggleAcquisitionButton(deviceLocked, DATA_ACQ_BUTTON_TO_DAQ)
	SI_CalculateMinSampInterval(deviceLocked, DATA_ACQUISITION_MODE, XOP_CHANNEL_TYPE_DAC)

	// deliberately not using the GUIState wave
	headstage = GetSliderPositionIndex(deviceLocked, "slider_DataAcq_ActiveHeadstage")
	P_SaveUserSelectedHeadstage(deviceLocked, headstage)

	// upgrade all four labnotebook waves in wanna-be atomic way
	GetLBNumericalKeys(deviceLocked)
	GetLBNumericalValues(deviceLocked)
	GetLBTextualKeys(deviceLocked)
	GetLBTextualValues(deviceLocked)

	NVAR sessionStartTime = $GetSessionStartTime()
	sessionStartTime = DateTimeInUTC()

	NVAR acqState = $GetAcquisitionState(deviceLocked)
	acqState = AS_INACTIVE

	NVAR rngSeed = $GetRNGSeed(deviceLocked)
	NewRandomSeed()
	rngSeed = GetReproducibleRandom()

	DAP_UpdateOnsetDelay(deviceLocked)

	HW_RegisterDevice(deviceLocked, hardwareType, deviceID)
	if(ItemsInList(GetListOfLockedDevices()) == 1)
		DAP_LoadBuiltinStimsets()
		GetPxPVersion()
		SetupBackgroundTasks()
		CtrlNamedBackground _all_, noevents=1
		UploadCrashDumpsDaily()
		// avoid problems with IP not keeping the dimension labels
		// of columns when we have no rows
		// we kill the wave here so that it is recreated properly
		KillOrMoveToTrash(wv = GetDQMActiveDeviceList())
	endif

	DAP_UpdateSweepLimitsAndDisplay(deviceLocked)
	DAP_AdaptPanelForDeviceSpecifics(deviceLocked)

	WAVE TPSettings = GetTPSettings(deviceLocked)
	// force update the stored TP settings
	// they could have been changed during panel unlock
	DAP_TPSettingsToWave(deviceLocked, TPSettings)

	TP_AutoTPGenerateNewCycleID(deviceLocked)

	LOG_AddEntry(PACKAGE_MIES, "locking", keys = {"device"}, values = {deviceLocked})
End

static Function DAP_AdaptPanelForDeviceSpecifics(string device, [variable forceEnable])

	variable i, channels
	string controls

	if(ParamIsDefault(forceEnable))
#ifdef EVIL_KITTEN_EATING_MODE
		forceEnable = 1
#else
		forceEnable = 0
#endif // EVIL_KITTEN_EATING_MODE
	else
		forceEnable = !!forceEnable
	endif

	if(forceEnable)
		EnableControls(device, SU_DISABLED_CONTROLS)
		for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
			controls = DAP_GetControlsForChannelIndex(i, CHANNEL_TYPE_DAC)
			EnableControls(device, controls)
			controls = DAP_GetControlsForChannelIndex(i, CHANNEL_TYPE_TTL)
			EnableControls(device, controls)
		endfor
		for(i = 0; i < NUM_AD_CHANNELS; i += 1)
			controls = DAP_GetControlsForChannelIndex(i, CHANNEL_TYPE_ADC)
			EnableControls(device, controls)
		endfor

		return NaN
	endif

	WAVE deviceInfo = GetDeviceInfoWave(device)
	ASSERT(IsFinite(deviceInfo[%DA]) && IsFinite(deviceInfo[%AD]) && deviceInfo[%TTL], "Could not query the device info wave")

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		controls = DAP_GetControlsForChannelIndex(i, CHANNEL_TYPE_DAC)
		channels = isNaN(deviceInfo[%AuxDA]) ? deviceInfo[%DA] : (deviceInfo[%DA] + deviceInfo[%AuxDA])
		if(i < channels)
			EnableControls(device, controls)
		else
			DisableControls(device, controls)
		endif

		controls = DAP_GetControlsForChannelIndex(i, CHANNEL_TYPE_TTL)
		if(i < deviceInfo[%TTL])
			EnableControls(device, controls)
		else
			DisableControls(device, controls)
		endif
	endfor

	for(i = 0; i < NUM_AD_CHANNELS; i += 1)
		controls = DAP_GetControlsForChannelIndex(i, CHANNEL_TYPE_ADC)
		channels = isNaN(deviceInfo[%AuxAD]) ? deviceInfo[%AD] : (deviceInfo[%AD] + deviceInfo[%AuxAD])
		if(i < channels)
			EnableControls(device, controls)
		else
			DisableControls(device, controls)
		endif
	endfor

	for(i = 0; i < NUM_ASYNC_CHANNELS; i += 1)
		controls = DAP_GetControlsForChannelIndex(i, CHANNEL_TYPE_ASYNC)
		channels = isNaN(deviceInfo[%AuxAD]) ? deviceInfo[%AD] : deviceInfo[%AuxAD]
		if(i < channels)
			EnableControls(device, controls)
		else
			DisableControls(device, controls)
		endif
	endfor

	if(IsDeviceNameFromSutter(device))
		for(i = 0; i < NUM_HEADSTAGES; i += 1)
			PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = i)
			if(i < deviceInfo[%DA])
				PGC_SetAndActivateControl(device, "Popup_Settings_VC_DA", val = i)
				PGC_SetAndActivateControl(device, "Popup_Settings_IC_DA", val = i)
				PGC_SetAndActivateControl(device, "Popup_Settings_VC_AD", val = i)
				PGC_SetAndActivateControl(device, "Popup_Settings_IC_AD", val = i)
			else
				PGC_SetAndActivateControl(device, "button_Hardware_ClearChanConn")
			endif
		endfor
		PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", val = 0)
		DisableControls(device, SU_DISABLED_CONTROLS)
	endif
End

static Function/S DAP_GetControlsForChannelIndex(variable channelIndex, variable channelType)

	string controls = ""

	switch(channelType)
		case CHANNEL_TYPE_DAC:
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_CHECK), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_GAIN), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_UNIT), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_WAVE), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_SEARCH), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_SCALE), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_INDEX_END), controls, ";", Inf)
			break
		case CHANNEL_TYPE_ADC:
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_CHECK), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_GAIN), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_UNIT), controls, ";", Inf)
			break
		case CHANNEL_TYPE_TTL:
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_CHECK), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_WAVE), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_SEARCH), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_INDEX_END), controls, ";", Inf)
			break
		case CHANNEL_TYPE_ASYNC:
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_TITLE), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_CHECK), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_GAIN), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_UNIT), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, CHANNEL_TYPE_ALARM, CHANNEL_CONTROL_CHECK), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_ALARM_MIN), controls, ";", Inf)
			controls = AddListItem(GetPanelControl(channelIndex, channelType, CHANNEL_CONTROL_ALARM_MAX), controls, ";", Inf)
			break
		default:
			ASSERT(0, "Invalid channel type")
			break
	endswitch

	return controls
End

static Function DAP_LoadBuiltinStimsets()

	string symbPath, stimset, files, filename
	variable i, numEntries

	symbPath = GetUniqueSymbolicPath()
	NewPath/Q $symbPath, GetFolder(FunctionPath("")) + ":Stimsets"

	PathInfo $symbPath
	if(!V_flag)
		KillPath $symbPath
		return NaN
	endif

	files      = GetAllFilesRecursivelyFromPath(symbPath, extension = ".nwb")
	numEntries = ItemsInList(files, FILE_LIST_SEP)
	for(i = 0; i < numEntries; i += 1)
		filename = StringFromList(i, files, FILE_LIST_SEP)
		NWB_LoadAllStimsets(filename = filename, overwrite = 1, loadOnlyBuiltins = 1)
	endfor

	KillPath $symbPath
End

static Function DAP_ClearWaveIfExists(WAVE/Z wv)

	if(WaveExists(wv))
		Redimension/N=(0, -1, -1, -1) wv
	endif
End

static Function DAP_UnlockDevice(string device)

	variable flags, state, hardwareType
	string lockedDevices, wlName

	if(!windowExists(device))
		DEBUGPRINT("Can not unlock the non-existing panel", str = device)
		return NaN
	endif

	if(DAP_DeviceIsUnlocked(device))
		DEBUGPRINT("Device is not locked, doing nothing", str = device)
		return NaN
	endif

	// we need to turn off TP after DAQ as this could prevent stopping the TP,
	// especially for foreground TP
	state = DAG_GetNumericalValue(device, "check_Settings_TPAfterDAQ")
	PGC_SetAndActivateControl(device, "check_Settings_TPAfterDAQ", val = CHECKBOX_UNSELECTED)
	DQ_StopDAQ(device, DQ_STOP_REASON_UNLOCKED_DEVICE)
	TP_StopTestPulse(device)

	wlName = GetWorkLoadName(WORKLOADCLASS_TP, device)
	ASSERT(!ASYNC_WaitForWLCToFinishAndRemove(wlName, DAP_WAITFORTPANALYSIS_TIMEOUT), "TP analysis did not finish within timeout")
	NWB_CloseNWBFile(device)

	PGC_SetAndActivateControl(device, "check_Settings_TPAfterDAQ", val = state)

	DAP_SerializeCommentNotebook(device)
	DAP_LockCommentNotebook(device)

	if(!IsControlDisabled(device, "button_Hardware_P_Disable"))
		PGC_SetAndActivateControl(device, "button_Hardware_P_Disable")
	endif

	if(!IsControlDisabled(device, "button_Hardware_PUser_Disable"))
		PGC_SetAndActivateControl(device, "button_Hardware_PUser_Disable")
	endif

	EnableControls(device, "button_SettingsPlus_LockDevice;popup_MoreSettings_Devices;button_hardware_rescan")
	DisableControl(device, "button_SettingsPlus_unLockDevic")
	EnableControls(device, "StartTestPulseButton;DataAcquireButton;Check_DataAcq1_RepeatAcq;Check_DataAcq_Indexing;SetVar_DataAcq_ITI;SetVar_DataAcq_SetRepeats;Check_DataAcq_Get_Set_ITI")
	DAP_ResetGUIAfterDAQ(device)
	DAP_ToggleTestpulseButton(device, TESTPULSE_BUTTON_TO_START)

	// turn off auto TP on all headstages
	PGC_SetAndActivateControl(device, "check_DataAcq_AutoTP", val = CHECKBOX_UNSELECTED)
	WAVE TPSettings = GetTPsettings(device)
	TPSettings[%autoTPEnable][0, NUM_HEADSTAGES - 1] = 0

	if(IsDeviceNameFromSutter(device))
		EnableControls(device, SU_DISABLED_CONTROLS)
	endif

	KillOrMoveToTrash(wv = GetDA_EphysGuiStateNum(device))
	KillOrMoveToTrash(wv = GetDA_EphysGuiStateTxT(device))

	string unlockedDevice = BASE_WINDOW_NAME
	if(CheckName(unlockedDevice, CONTROL_PANEL_TYPE))
		unlockedDevice = UniqueName(BASE_WINDOW_NAME + "_", CONTROL_PANEL_TYPE, 1)
	endif
	DoWindow/W=$device/C $unlockedDevice

	variable locked = 0
	DAP_UpdateDataFolderDisplay(unlockedDevice, locked)

	NVAR/SDFR=GetDevicePath(device) deviceID

	hardwareType = GetHardwareType(device)
	// shutdown the FIFO thread now in case it is still running (which should never be the case)
	TFH_StopFIFODaemon(hardwareType, deviceID)

	flags = HARDWARE_ABORT_ON_ERROR
	HW_CloseDevice(hardwareType, deviceID, flags = flags)
	HW_ResetDevice(hardwareType, deviceID, flags = flags)
	HW_DeRegisterDevice(hardwareType, deviceID, flags = flags)

	DAP_UpdateListOfLockedDevices()

	// reset our state variables to safe defaults
	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)
	dataAcqRunMode = DAQ_NOT_RUNNING
	NVAR count = $GetCount(device)
	count = 0
	NVAR runMode = $GetTestpulseRunMode(device)
	runMode = TEST_PULSE_NOT_RUNNING

	lockedDevices = GetListOfLockedDevices()
	if(IsEmpty(lockedDevices))

		WAVE ActiveDevicesTPMD = GetActiveDevicesTPMD()
		ActiveDevicesTPMD = NaN
		SetNumberInWaveNote(ActiveDevicesTPMD, NOTE_INDEX, 0)

		DFREF dfr = GetActiveDAQDevicesFolder()
		WAVE/Z/SDFR=dfr ActiveDeviceList
		DAP_ClearWaveIfExists(ActiveDeviceList)

		DFREF dfr = GetActiveDAQDevicesTimerFolder()
		WAVE/Z/SDFR=dfr ActiveDevTimeParam, TimerFunctionListWave
		DAP_ClearWaveIfExists(ActiveDevTimeParam)
		DAP_ClearWaveIfExists(TimerFunctionListWave)

		KillOrMoveToTrash(wv = GetDeviceMapping())
	endif

	KillOrMoveToTrash(wv = GetDA_EphysGuiStateNum(unlockedDevice))
	KillOrMoveToTrash(wv = GetDA_EphysGuiStateTxT(unlockedDevice))
End

/// @brief Update the list of locked devices
static Function DAP_UpdateListOfLockedDevices()

	variable i, numDevs, numItm
	string NIPanelList  = ""
	string ITCPanelList = WinList("ITC*", ";", "WIN:64")
	string allPanelList = WinList("*", ";", "WIN:64")
	string NIDevList    = DAP_GetNIDeviceList()
	string SUPanelList  = WinList(DEVICE_SUTTER_NAME_START_CLEAN + "*", ";", "WIN:64")

	numDevs = ItemsInList(NIDevList)
	for(i = 0; i < numDevs; i += 1)
		numItm = WhichListItem(StringFromList(i, NIDevList), allPanelList)
		if(numItm > -1)
			NIPanelList = AddListItem(StringFromList(numItm, allPanelList), NIPanelList, ";")
		endif
	endfor

	SVAR panelList = $GetLockedDevices()
	panelList = ITCPanelList + NIPanelList + SUPanelList
End

static Function DAP_UpdateChanAmpAssignStorWv(string device)

	variable HeadStageNo, ampSerial, ampChannelID
	string amplifierDef
	WAVE   ChanAmpAssign     = GetChanAmpAssign(device)
	WAVE/T ChanAmpAssignUnit = GetChanAmpAssignUnit(device)

	HeadStageNo = str2num(GetPopupMenuString(device, "Popup_Settings_HeadStage"))

	// Assigns V-clamp settings for a particular headstage
	ChanAmpAssign[%VC_DA][HeadStageNo]         = str2numSafe(GetPopupMenuString(device, "Popup_Settings_VC_DA"))
	ChanAmpAssign[%VC_DAGain][HeadStageNo]     = GetSetVariable(device, "setvar_Settings_VC_DAgain")
	ChanAmpAssignUnit[%VC_DAUnit][HeadStageNo] = GetSetVariableString(device, "SetVar_Hardware_VC_DA_Unit")
	ChanAmpAssign[%VC_AD][HeadStageNo]         = str2numSafe(GetPopupMenuString(device, "Popup_Settings_VC_AD"))
	ChanAmpAssign[%VC_ADGain][HeadStageNo]     = GetSetVariable(device, "setvar_Settings_VC_ADgain")
	ChanAmpAssignUnit[%VC_ADUnit][HeadStageNo] = GetSetVariableString(device, "SetVar_Hardware_VC_AD_Unit")

	//Assigns I-clamp settings for a particular headstage
	ChanAmpAssign[%IC_DA][HeadStageNo]         = str2numSafe(GetPopupMenuString(device, "Popup_Settings_IC_DA"))
	ChanAmpAssign[%IC_DAGain][HeadStageNo]     = GetSetVariable(device, "setvar_Settings_IC_DAgain")
	ChanAmpAssignUnit[%IC_DAUnit][HeadStageNo] = GetSetVariableString(device, "SetVar_Hardware_IC_DA_Unit")
	ChanAmpAssign[%IC_AD][HeadStageNo]         = str2numSafe(GetPopupMenuString(device, "Popup_Settings_IC_AD"))
	ChanAmpAssign[%IC_ADGain][HeadStageNo]     = GetSetVariable(device, "setvar_Settings_IC_ADgain")
	ChanAmpAssignUnit[%IC_ADUnit][HeadStageNo] = GetSetVariableString(device, "SetVar_Hardware_IC_AD_Unit")

	// Assigns amplifier to a particular headstage
	// sounds weird because this relationship is predetermined in hardware
	// but now you are telling the software what it is
	amplifierDef = GetPopupMenuString(device, "popup_Settings_Amplifier")
	DAP_ParseAmplifierDef(amplifierDef, ampSerial, ampChannelID)

	if(IsFinite(ampSerial) && IsFinite(ampChannelID))
		ChanAmpAssign[%AmpSerialNo][HeadStageNo]  = ampSerial
		ChanAmpAssign[%AmpChannelID][HeadStageNo] = ampChannelID
	else
		ChanAmpAssign[%AmpSerialNo][HeadStageNo]  = NaN
		ChanAmpAssign[%AmpChannelID][HeadStageNo] = NaN
	endif
End

static Function DAP_UpdateChanAmpAssignPanel(string device)

	variable HeadStageNo, channel, ampSerial, ampChannelID
	string entry

	WAVE   ChanAmpAssign     = GetChanAmpAssign(device)
	WAVE/T ChanAmpAssignUnit = GetChanAmpAssignUnit(device)

	HeadStageNo = str2num(GetPopupMenuString(device, "Popup_Settings_HeadStage"))

	// function does not use PGC_SetAndActivateControl on purpose, see #1872

	// VC DA settings
	channel = ChanAmpAssign[%VC_DA][HeadStageNo]
	Popupmenu Popup_Settings_VC_DA, win=$device, mode=(IsFinite(channel) ? channel : NUM_DA_TTL_CHANNELS) + 1
	Setvariable setvar_Settings_VC_DAgain, win=$device, value=_NUM:ChanAmpAssign[%VC_DAGain][HeadStageNo]
	Setvariable SetVar_Hardware_VC_DA_Unit, win=$device, value=_STR:ChanAmpAssignUnit[%VC_DAUnit][HeadStageNo]

	// VC AD settings
	channel = ChanAmpAssign[%VC_AD][HeadStageNo]
	Popupmenu Popup_Settings_VC_AD, win=$device, mode=(IsFinite(channel) ? channel : NUM_MAX_CHANNELS) + 1
	Setvariable setvar_Settings_VC_ADgain, win=$device, value=_NUM:ChanAmpAssign[%VC_ADGain][HeadStageNo]
	Setvariable SetVar_Hardware_VC_AD_Unit, win=$device, value=_STR:ChanAmpAssignUnit[%VC_ADUnit][HeadStageNo]

	// IC DA settings
	channel = ChanAmpAssign[%IC_DA][HeadStageNo]
	Popupmenu Popup_Settings_IC_DA, win=$device, mode=(IsFinite(channel) ? channel : NUM_DA_TTL_CHANNELS) + 1
	Setvariable setvar_Settings_IC_DAgain, win=$device, value=_NUM:ChanAmpAssign[%IC_DAGain][HeadStageNo]
	Setvariable SetVar_Hardware_IC_DA_Unit, win=$device, value=_STR:ChanAmpAssignUnit[%IC_DAUnit][HeadStageNo]

	// IC AD settings
	channel = ChanAmpAssign[%IC_AD][HeadStageNo]
	Popupmenu Popup_Settings_IC_AD, win=$device, mode=(IsFinite(channel) ? channel : NUM_MAX_CHANNELS) + 1
	Setvariable setvar_Settings_IC_ADgain, win=$device, value=_NUM:ChanAmpAssign[%IC_ADGain][HeadStageNo]
	Setvariable SetVar_Hardware_IC_AD_Unit, win=$device, value=_STR:ChanAmpAssignUnit[%IC_ADUnit][HeadStageNo]

	ampSerial    = ChanAmpAssign[%AmpSerialNo][HeadStageNo]
	ampChannelID = ChanAmpAssign[%AmpChannelID][HeadStageNo]
	if(isFinite(ampSerial) && isFinite(ampChannelID))
		entry = DAP_GetAmplifierDef(ampSerial, ampChannelID)
		Popupmenu popup_Settings_Amplifier, win=$device, popmatch=entry
	else
		Popupmenu popup_Settings_Amplifier, win=$device, popmatch=NONE
	endif
End

/// @brief Helper function to update all DAQ related controls after something changed.
///
/// @param device device
/// @param updateFlag One of @ref UpdateControlsFlags
Function DAP_UpdateDAQControls(string device, variable updateFlag)

	DEBUGPRINT("updateFlag", var = updateFlag)

	if(updateFlag & REASON_STIMSET_CHANGE)
		DAP_UpdateSweepSetVariables(device)
		AFM_UpdateAnalysisFunctionWave(device)
	elseif(updateFlag & REASON_STIMSET_CHANGE_DUR_DAQ)
		AFM_UpdateAnalysisFunctionWave(device)
		SetValDisplay(device, "valdisp_DataAcq_SweepsActiveSet", var = IDX_MaxNoOfSweeps(device, 1))
	endif

	if(updateFlag & REASON_HEADSTAGE_CHANGE)
		SetValDisplay(device, "ValDisp_DataAcq_SamplingInt", var = DAP_GetSampInt(device, DATA_ACQUISITION_MODE, XOP_CHANNEL_TYPE_DAC))
	endif

	if((updateFlag & REASON_HEADSTAGE_CHANGE) || (updateFlag & REASON_STIMSET_CHANGE))
		DAP_CheckSkipAhead(device)
	endif
End

/// @brief Applies user settings for the clamp mode stimulus sets (DA Set and Indexing End Set) on mode switch
///
/// @param device device
/// @param headStage  MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
/// @param delayed    [optional, defaults to false] On a delayed clamp mode change the stimulus set is not set.
static Function DAP_AllChanDASettings(string device, variable headStage, [variable delayed])

	string ctrl
	variable scalar, index, indexEnd, DAC, clampMode

	if(!DAG_GetNumericalValue(device, "check_DA_applyOnModeSwitch"))
		return NaN
	endif

	if(ParamIsDefault(delayed))
		delayed = 0
	else
		delayed = !!delayed
	endif

	DAC = AFH_GetDACFromHeadstage(device, headstage)

	if(IsNan(DAC))
		return NaN
	endif

	clampMode = DAG_GetHeadstageMode(device, headStage)

	if(clampMode == V_CLAMP_MODE)
		scalar   = DAG_GetNumericalValue(device, GetPanelControl(CHANNEL_INDEX_ALL_V_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE))
		index    = DAG_GetNumericalValue(device, GetPanelControl(CHANNEL_INDEX_ALL_V_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE))
		indexEnd = DAG_GetNumericalValue(device, GetPanelControl(CHANNEL_INDEX_ALL_V_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END))
	elseif(clampMode == I_CLAMP_MODE)
		scalar   = DAG_GetNumericalValue(device, GetPanelControl(CHANNEL_INDEX_ALL_I_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE))
		index    = DAG_GetNumericalValue(device, GetPanelControl(CHANNEL_INDEX_ALL_I_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE))
		indexEnd = DAG_GetNumericalValue(device, GetPanelControl(CHANNEL_INDEX_ALL_I_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END))
	endif

	// update the scalar
	ctrl = GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	PGC_SetAndActivateControl(device, ctrl, val = scalar)

	// update the stimulus/index end set if not delayed clamp mode change
	if(!delayed)
		ctrl = GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
		PGC_SetAndActivateControl(device, ctrl, val = index)

		ctrl = GetPanelControl(DAC, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
		PGC_SetAndActivateControl(device, ctrl, val = indexEnd)
	endif
End

Function DAP_ButtonProc_skipSweep(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2:
			RA_SkipSweeps(ba.win, 1, SWEEP_SKIP_USER, limitToSetBorder = 1)
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_ButtonProc_skipBack(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2:
			RA_SkipSweeps(ba.win, -1, SWEEP_SKIP_USER, limitToSetBorder = 1)
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_GetskipAhead(string device)

	return GetDA_EphysGuiStateNum(device)[0][%SetVar_DataAcq_skipAhead]
End

Function DAP_ResetskipAhead(string device)

	WAVE guiState = GetDA_EphysGuiStateNum(device)
	guiState[0][%SetVar_DataAcq_skipAhead] = 0
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_skipAhead", val = 0)
End

Function DAP_getFilteredSkipAhead(string device, variable skipAhead)

	variable maxSkipAhead = max(0, IDX_MinNoOfSweeps(device) - 1)
	return (skipAhead > maxSkipAhead) ? maxSkipAhead : skipAhead
End

Function DAP_setSkipAheadLimit(string device, variable filteredSkipAhead)

	SetSetVariableLimits(device, "SetVar_DataAcq_skipAhead", 0, max(0, filteredSkipAhead), 1)
End

Function DAP_SetVarProc_skipAhead(STRUCT WMSetVariableAction &sva) : SetVariableControl

	switch(sva.eventCode)
		case 1:
		case 2:
		case 3:
			DAG_Update(sva.win, sva.ctrlName, val = sva.dval)
			DAP_setSkipAheadLimit(sva.win, IDX_MinNoOfSweeps(sva.win) - 1)
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_CheckProc_RandomRA(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	switch(cba.eventCode)
		case 2:
			DAG_Update(cba.win, cba.ctrlName, val = cba.checked)
			if(cba.checked)
				PGC_SetAndActivateControl(cba.win, "SetVar_DataAcq_skipAhead", val = 0)
				DisableControl(cba.win, "SetVar_DataAcq_skipAhead")
			else
				EnableControl(cba.win, "SetVar_DataAcq_skipAhead")
			endif
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_CheckSkipAhead(string device)

	variable activeSkipAhead   = DAG_GetNumericalValue(device, "SetVar_DataAcq_skipAhead")
	variable filteredSkipAhead = DAP_getFilteredSkipAhead(device, activeSkipAhead)
	if(activeSkipAhead > filteredSkipAhead)
		printf "Skip ahead value exceeds allowed limit for new selection and has been set to %d \r", filteredSkipAhead
		PGC_SetAndActivateControl(device, "SetVar_DataAcq_skipAhead", val = filteredSkipAhead)
		controlWindowToFront()
	endif

	DAP_setSkipAheadLimit(device, filteredSkipAhead)
End

Function DAP_PopMenuProc_UpdateGuiState(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 2: // mouse up
			DAG_Update(pa.win, pa.ctrlName, val = pa.popNum - 1, str = pa.popStr)
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Return the list of available sampling multipliers
///
/// Has no `NONE` element as `1` means no multiplier.
Function/S DAP_GetSamplingMultiplier()

	return "1;2;4;8;16;32;64"
End

Function DAP_PopMenuProc_SampMult(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 2: // mouse up
			DAG_Update(pa.win, pa.ctrlName, val = pa.popNum - 1, str = pa.popStr)
			DAP_UpdateDAQControls(pa.win, REASON_HEADSTAGE_CHANGE)

			if(!cmpstr(pa.popStr, "1"))
				EnableControl(pa.win, "Popup_Settings_FixedFreq")
			else
				DisableControl(pa.win, "Popup_Settings_FixedFreq")
			endif
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_CheckProc_RequireAmplifier(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	variable checked
	string   device

	switch(cba.eventCode)
		case 2: // mouse up
			checked = cba.checked
			device  = cba.win
			DAG_Update(device, cba.ctrlName, val = checked)
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Return the list of available fixed sampling frequencies
Function/S DAP_GetSamplingFrequencies()

	return "Maximum;100;50;25;10"
End

Function DAP_PopMenuProc_FixedSampInt(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 2: // mouse up
			DAG_Update(pa.win, pa.ctrlName, val = pa.popNum - 1, str = pa.popStr)
			DAP_UpdateDAQControls(pa.win, REASON_HEADSTAGE_CHANGE)

			if(!cmpstr(pa.popStr, "Maximum"))
				EnableControl(pa.win, "Popup_Settings_SampIntMult")
			else
				DisableControl(pa.win, "Popup_Settings_SampIntMult")
			endif
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Return the list of available Oscilloscope Update Modes
Function/S DAP_GetOsciUpdModes()

	string list = ""
	list = AddListItem("Interval", list, ";", GUI_SETTING_OSCI_SCALE_INTERVAL)
	list = AddListItem("Auto Scale", list, ";", GUI_SETTING_OSCI_SCALE_AUTO)
	list = AddListItem("Fixed Scale", list, ";", GUI_SETTING_OSCI_SCALE_FIXED)
	return list
End

Function DAP_PopMenuProc_OsciUpdMode(STRUCT WMPopupAction &pa) : PopupMenuControl

	string device

	switch(pa.eventCode)
		case 2: // mouse up
			device = pa.win
			DAG_Update(device, pa.ctrlName, val = pa.popNum - 1, str = pa.popStr)

			NVAR tpRunMode      = $GetTestpulseRunMode(device)
			NVAR dataAcqRunMode = $GetDataAcqRunMode(device)

			if(IsFinite(tpRunMode) && tpRunMode != TEST_PULSE_NOT_RUNNING)
				SCOPE_CreateGraph(device, TEST_PULSE_MODE)
			elseif(IsFinite(dataAcqRunMode) && dataAcqRunMode != DAQ_NOT_RUNNING)
				SCOPE_CreateGraph(device, DATA_ACQUISITION_MODE)
			endif
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_ApplyDelayedClampModeChange(string device)

	variable i, mode

	WAVE GuiState = GetDA_EphysGuiStateNum(device)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		mode = GuiState[i][%HSmode_delayed]

		if(IsNaN(mode))
			continue
		endif

		DAP_ChangeHeadStageMode(device, mode, i, NO_SLIDER_MOVEMENT)
	endfor

	DAP_ClearDelayedClampModeChange(device)
End

Function DAP_ClearDelayedClampModeChange(string device)

	WAVE GuiState = GetDA_EphysGuiStateNum(device)
	GuiState[][%HSmode_delayed] = NaN
End

Function ButtonProc_Hardware_rescan(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			SVAR globalITCDevList = $GetITCDeviceList()
			SVAR globalNIDevList  = $GetNIDeviceList()

			KillStrings/Z globalITCDevList, globalNIDevList

			DAP_GetNIDeviceList()
			DAP_GetITCDeviceList()
			DAP_GetSUDeviceList()
			break
		default:
			break
	endswitch

	return 0
End

Function DAP_CheckProc_PowerSpectrum(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	variable testPulseMode
	string   device

	switch(cba.eventCode)
		case 2: // mouse up
			device = cba.win
			DAG_Update(device, cba.ctrlName, val = cba.checked)

			testPulseMode = TP_StopTestPulse(device)
			TP_RestartTestPulse(device, testPulseMode)
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Update the popup menus and its #USER_DATA_MENU_EXP user data after stim set changes
///
/// @param device [optional, defaults to all locked devices] device
Function DAP_UpdateDaEphysStimulusSetPopups([string device])

	variable i, j, numPanels
	string ctrlWave, ctrlIndexEnd, ctrlSearch, DAlist, TTLlist, listOfPanels
	string filteredDAList, filteredTTLList, searchString

	if(ParamIsDefault(device))
		listOfPanels = GetListOfLockedDevices()

		if(isEmpty(listOfPanels))
			return NaN
		endif
	else
		listOfPanels = device
	endif

	DEBUGPRINT("Updating", str = listOfPanels)

	DAlist  = ST_GetStimsetList(channelType = CHANNEL_TYPE_DAC)
	TTLlist = ST_GetStimsetList(channelType = CHANNEL_TYPE_TTL)

	numPanels = ItemsInList(listOfPanels)
	for(i = 0; i < numPanels; i += 1)
		device = StringFromList(i, listOfPanels)

		if(!WindowExists(device))
			continue
		endif

		WAVE/T searchStrings = DAG_GetChannelTextual(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SEARCH)

		for(j = CHANNEL_INDEX_ALL_I_CLAMP; j < NUM_DA_TTL_CHANNELS; j += 1)
			ctrlWave     = GetPanelControl(j, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
			ctrlIndexEnd = GetPanelControl(j, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)

			if(j >= 0)
				searchString = searchStrings[j]
			else
				ctrlSearch   = GetPanelControl(j, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SEARCH)
				searchString = DAG_GetTextualValue(device, ctrlSearch)
			endif

			if(!IsEmpty(searchString))
				filteredDAList = ListMatch(DAlist, searchString)
			else
				filteredDAList = DAlist
			endif

			SetControlUserData(device, ctrlWave, USER_DATA_MENU_EXP, filteredDAlist)
			DAP_UpdateStimulusSetPopup(device, ctrlWave, filteredDAlist)

			SetControlUserData(device, ctrlIndexEnd, USER_DATA_MENU_EXP, filteredDAlist)
			DAP_UpdateStimulusSetPopup(device, ctrlIndexEnd, filteredDAlist)
		endfor

		WAVE/T searchStrings = DAG_GetChannelTextual(device, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_SEARCH)

		for(j = CHANNEL_INDEX_ALL; j < NUM_DA_TTL_CHANNELS; j += 1)
			ctrlWave     = GetPanelControl(j, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
			ctrlIndexEnd = GetPanelControl(j, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)

			if(j >= 0)
				searchString = searchStrings[j]
			else
				ctrlSearch   = GetPanelControl(j, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_SEARCH)
				searchString = DAG_GetTextualValue(device, ctrlSearch)
			endif

			if(!IsEmpty(searchString))
				filteredTTLlist = ListMatch(TTLlist, searchString)
			else
				filteredTTLlist = TTLlist
			endif

			SetControlUserData(device, ctrlWave, USER_DATA_MENU_EXP, filteredTTLlist)
			DAP_UpdateStimulusSetPopup(device, ctrlWave, filteredTTLlist)

			SetControlUserData(device, ctrlIndexEnd, USER_DATA_MENU_EXP, filteredTTLlist)
			DAP_UpdateStimulusSetPopup(device, ctrlIndexEnd, filteredTTLlist)
		endfor

		DAP_UpdateDAQControls(device, REASON_STIMSET_CHANGE)
	endfor
End

static Function DAP_UpdateStimulusSetPopup(string device, string ctrl, string stimsets)

	string   stimset
	variable index

	stimset = GetPopupMenuString(device, ctrl)
	index   = WhichListItem(stimset, stimsets)

	if(index == -1)
		// not found, select NONE
		index   = 0
		stimset = NONE
	else
		index += 1
	endif

	SetPopupMenuIndex(device, ctrl, index)
	DAG_Update(device, ctrl, val = index, str = stimset)
End

/// @brief Delete the stimulus set in the given DAEphys
///
/// Internal use only, outside callers should use ST_RemoveStimSet()
Function DAP_DeleteStimulusSet(string setName, [string device])

	variable channelType

	if(ParamIsDefault(device))
		WB_KillParameterWaves(setName)
		WB_KillStimset(setName)
		WB_UpdateChangedStimsets()
		return NaN
	endif

	channelType = WB_GetStimSetType(setName)

	if(channeltype == CHANNEL_TYPE_UNKNOWN)
		return NaN
	endif

	WB_KillParameterWaves(setName)
	WB_KillStimset(setName)

	WB_UpdateChangedStimsets(device = device)
End

/// @brief Write all TP settings from the data acquisition/settings tab to the settings wave
Function DAP_TPSettingsToWave(string device, WAVE TPSettings)

	variable i, numEntries, headstage, col
	string ctrl, lbl

	WAVE/T controls = ListToTextWave(DAEPHYS_TP_CONTROLS_ALL, ";")

	headstage = DAG_GetNumericalValue(device, "slider_DataAcq_ActiveHeadstage")

	numEntries = DimSize(controls, ROWS)
	for(i = 0; i < numEntries; i += 1)
		ctrl = controls[i]
		lbl  = DAP_TPControlToLabel(ctrl)

		if(WhichListItem(ctrl, DAEPHYS_TP_CONTROLS_DEPEND) != -1)
			col = headstage
		else
			ASSERT(WhichListItem(ctrl, DAEPHYS_TP_CONTROLS_INDEP) != -1, "Inconsistent control lists")
			col = INDEP_HEADSTAGE
		endif

		TPSettings[%$lbl][col] = DAG_GetNumericalValue(device, ctrl)
	endfor
End

/// @brief Convert the control name to a dimension label for GetTPSettings()
static Function/S DAP_TPControlToLabel(string ctrl)

	strswitch(ctrl)
		case "SetVar_DataAcq_TPDuration":
			return "durationMS"
		case "SetVar_DataAcq_TPBaselinePerc":
			return "baselinePerc"
		case "SetVar_DataAcq_TPAmplitude":
			return "amplitudeVC"
		case "SetVar_DataAcq_TPAmplitudeIC":
			return "amplitudeIC"
		case "setvar_Settings_TPBuffer":
			return "bufferSize"
		case "setvar_Settings_TP_RTolerance":
			return "resistanceTol"
		case "check_DataAcq_AutoTP":
			return "autoTPEnable"
		case "setvar_DataAcq_IinjMax":
			return "autoAmpMaxCurrent"
		case "setvar_DataAcq_targetVoltage":
			return "autoAmpVoltage"
		case "setvar_DataAcq_targetVoltageRange":
			return "autoAmpVoltageRange"
		case "Check_TP_SendToAllHS":
			return "sendToAllHS"
		case "setvar_Settings_autoTP_perc":
			return "autoTPPercentage"
		case "setvar_Settings_autoTP_int":
			return "autoTPInterval"
		default:
			ASSERT(0, "invalid control")
			break
	endswitch
End

/// @brief Write a new TP setting value to the wave
static Function DAP_TPGUISettingToWave(string device, string ctrl, variable val)

	string lbl, entry
	variable first, last, TPState, needsTPRestart

	needsTPRestart = WhichListItem(ctrl, DAEPHYS_TP_CONTROLS_NO_RESTART) == -1

	// we only want to restart the testpulse if DAQ is not running
	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)
	if(dataAcqRunMode == DAQ_NOT_RUNNING && needsTPRestart)
		TPState = TP_StopTestPulse(device)
	else
		TPState = TEST_PULSE_NOT_RUNNING
	endif

	WAVE TPSettings = GetTPSettings(device)

	lbl = DAP_TPControlToLabel(ctrl)

	if(WhichListItem(ctrl, DAEPHYS_TP_CONTROLS_INDEP) != -1)
		first = INDEP_HEADSTAGE
		last  = first
	elseif(TPSettings[%sendToAllHS][INDEP_HEADSTAGE])
		first = 0
		last  = NUM_HEADSTAGES - 1
	else
		first = DAG_GetNumericalValue(device, "slider_DataAcq_ActiveHeadstage")
		last  = first
	endif

	TPSettings[%$lbl][first, last] = val

	if(!cmpstr(lbl, "autoTPEnable"))
		TP_AutoTPGenerateNewCycleID(device, first = first, last = last)
		DAP_AdaptAutoTPColorAndDependent(device)
	endif

	if(!cmpstr(ctrl, "SetVar_DataAcq_TPDuration") || !cmpstr(ctrl, "SetVar_DataAcq_TPBaselinePerc"))
		DAP_UpdateOnsetDelay(device)
	endif

	TP_RestartTestPulse(device, TPState)
End

/// @brief Synchronize the TP settings from the wave into the GUI
///
/// Needs to be done when the selected headstage changes or the TPsettings wave
/// contents. This function ignores "Send To All HS" as this does not make sense
/// to respect here.
///
/// @param device device
/// @param entry      [optional, defaults to all] Only update one of the entries TPSettings.
///                   Accepted strings are the labels from DAP_TPControlToLabel().
Function DAP_TPSettingsToGUI(string device, [string entry])

	variable i, numEntries, val, headstage, col, originalHSAll
	string ctrl, lbl
	variable TPState

	WAVE/T controls = ListToTextWave(DAEPHYS_TP_CONTROLS_ALL, ";")

	WAVE TPSettings = GetTPSettings(device)
	headstage = DAG_GetNumericalValue(device, "slider_DataAcq_ActiveHeadstage")

	// turn off send to all headstages temporarily
	// we want the values for the *current* headstage only be set in the GUI
	// and only for the *current* headstage
	originalHSAll                             = TPSettings[%sendToAllHS][INDEP_HEADSTAGE]
	TPSettings[%sendToAllHS][INDEP_HEADSTAGE] = 0

	TPState = TP_StopTestPulse(device)

	numEntries = DimSize(controls, ROWS)
	for(i = 0; i < numEntries; i += 1)
		ctrl = controls[i]
		lbl  = DAP_TPControlToLabel(ctrl)

		if(!ParamIsDefault(entry) && cmpstr(lbl, entry))
			continue
		endif

		if(!cmpstr(lbl, "sendToAllHS"))
			continue
		endif

		if(WhichListItem(ctrl, DAEPHYS_TP_CONTROLS_INDEP) != -1)
			col = INDEP_HEADSTAGE
		else
			col = headstage
		endif

		val = TPSettings[%$lbl][col]
		ASSERT(IsFinite(val), "Value has to be finite")

		PGC_SetAndActivateControl(device, ctrl, val = val)
	endfor

	TPSettings[%sendToAllHS][INDEP_HEADSTAGE] = originalHSAll

	if(IsFinite(TPState))
		TP_RestartTestPulse(device, TPState)
	endif
End

/// @brief Return the maximum possible DAScale value
///
/// @param device        DAC device
/// @param headstage     headstage
/// @param stimsetName   name of the stimset
/// @param stimsetColumn set sweep count of the given stimset to use for min/max calculation
Function DAP_GetDAScaleMax(string device, variable headstage, string stimsetName, variable stimsetColumn)

	variable minData, maxData, gain, hardwareType, DAC, minStimset, maxStimset, activeDACIndex
	variable result, minimum, maximum
	string ctrl, text, msg

	if(DAP_DeviceIsUnLocked(device))
		return NaN
	endif

	DAC = AFH_GetDACFromHeadstage(device, headstage)
	if(!IsValidHeadstage(DAC))
		return NaN
	endif

	if(WB_StimsetIsFromThirdParty(stimsetName))
		return NaN
	endif

	WAVE/Z stimset = WB_CreateAndGetStimSet(stimsetName)
	ASSERT(WaveExists(stimset), "Could not create stimset")

	if(stimsetColumn >= DimSize(stimset, COLS))
		return NaN
	endif

	text       = note(stimset)
	minStimset = WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "Minimum", sweep = stimsetColumn)
	maxStimset = WB_GetWaveNoteEntryAsNumber(text, SWEEP_ENTRY, key = "Maximum", sweep = stimsetColumn)
	ASSERT(IsFinite(minStimset) && IsFinite(maxStimset), "Invalid minimum/maximum")

	hardwareType       = GetHardwareType(device)
	[minData, maxData] = HW_GetDataRange(hardwareType, XOP_CHANNEL_TYPE_DAC, 1)

	WAVE DAQConfigWave = GetDAQConfigWave(device)
	WAVE DACs          = GetDACListFromConfig(DAQConfigWave)
	activeDACIndex = GetRowIndex(DACs, val = DAC)

	WAVE gains = SWS_GetChannelGains(device, timing = GAIN_BEFORE_DAQ)
	gain = gains[activeDACIndex]
	ASSERT(IsFinite(gain), "Invalid gain")

	minimum = minData / (minStimset * gain)
	maximum = maxData / (maxStimset * gain)

	if(IsInf(minimum) && IsInf(maximum))
		result = Inf
	elseif(IsInf(minimum))
		result = maximum
	elseif(IsInf(maximum))
		result = minimum
	else
		result = min(minimum, maximum)
	endif

	result = trunc(result)

	sprintf msg, "result %g, minimum %g, maximum %g, minData %g, maxData %g, minStimset %g, maxStimset %g, channel gain %g\r", result, minimum, maximum, minData, maxData, minStimset, maxStimset, gain
	DEBUGPRINT(msg)

	return result
End
