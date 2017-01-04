#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma igorVersion=7.0

/// @file MIES_ExperimentConfig.ipf
///
/// @brief __ExpConfig__ Import user settings to configure paramters for Ephys experiments
///
/// These include:
/// - Amplifier settings
/// - Pressure regulator settings
/// - Interactions with MCCs
/// - DAEphys panel settings

/// @brief Configure MIES for experiments
Function ExpConfig_ConfigureMIES()

	string UserConfigNB, win, filename, ITCDevNum, ITCDevType, fullPath, StimSetPath, activeNotebooks
	variable i
//	movewindow /C 1450, 530,-1,-1								// position command window

	activeNotebooks = WinList("*",";","WIN:16")
	if(!isempty(activeNotebooks))
		for(i = 0; i < ItemsInList(activeNotebooks); i += 1)
			KillWindow /Z $StringFromList(i, activeNotebooks)
		endfor
	endif
	
	fullPath = GetFolder(FunctionPath("")) + USER_CONFIG_PATH
	ASSERT(!cmpstr(GetFileSuffix(fullPath), "txt"), "Only plain notebooks are supported")
	OpenNotebook/ENCG=1/R/N=UserConfigNB/V=0/Z fullPath
	if(V_flag)
		ASSERT(V_flag > 0, "Configuration Notebook not loaded")
	endif

	UserConfigNB = winname(0,16)
	Wave /T KeyTypes = GetExpConfigKeyTypes()
	Wave /T UserSettings = GetExpUserSettings(UserConfigNB, KeyTypes)
	FindValue /TXOP = 4 /TEXT = ITC_DEV_TYPE UserSettings
	ITCDevType = UserSettings[V_value][%SettingValue]
	FindValue /TXOP = 4 /TEXT = ITC_DEV_NUM UserSettings
	ITCDevNum = UserSettings[V_value][%SettingValue]

	if(WindowExists(BuildDeviceString(ITCDevType, ITCDevNum)))
		win = BuildDeviceString(ITCDevType, ITCDevNum)
	else
		if(WindowExists("DA_Ephys"))
			win = BASE_WINDOW_TITLE
		else
			win = DAP_CreateDAEphysPanel() 									//open DA_Ephys
//			movewindow /W = $win 1500, -700,-1,-1				//position DA_Ephys window
		endif

		PGC_SetAndActivateControl(win,"popup_MoreSettings_DeviceType", val = WhichListItem(ITCDevType,DEVICE_TYPES))
		PGC_SetAndActivateControl(win,"popup_moreSettings_DeviceNo", val = WhichListItem(ITCDevNum,DEVICE_TYPES))
		PGC_SetAndActivateControl(win,"button_SettingsPlus_LockDevice")

		win = BuildDeviceString(ITCDevType, ITCDevNum)
	endif

	ExpConfig_Amplifiers(win, UserSettings)

	ExpConfig_Pressure(win, UserSettings)

	ExpConfig_ClampModes(win, UserSettings)

	ExpConfig_AsyncTemp(win, UserSettings)

	ExpConfig_DAEphysSettings(win, UserSettings)

	FindValue /TXOP = 4 /TEXT = STIMSET_PATH UserSettings
	StimSetPath = UserSettings[V_value][%SettingValue]
	HD_LoadReplaceStimSet(incomingFileDirectory = StimSetPath)

	PGC_SetAndActivateControl(win,"ADC", val = DA_EPHYS_PANEL_DATA_ACQUISITION)
	PGC_SetAndActivateControl(win, "tab_DataAcq_Amp", val = DA_EPHYS_PANEL_VCLAMP)
	PGC_SetAndActivateControl(win, "tab_DataAcq_Pressure", val = DA_EPHYS_PANEL_PRESSURE_AUTO)

	filename = GetTimeStamp() + PACKED_FILE_EXPERIMENT_SUFFIX
	FindValue /TXOP = 4 /TEXT = SAVE_PATH UserSettings
	NewPath /C/O SavePath, UserSettings[V_value][%SettingValue]

	SaveExperiment /P=SavePath as filename

	PGC_SetAndActivateControl(win,"StartTestPulseButton")

	print ("Start Sciencing")

End

/// @brief  Open and configure amplifiers for Multi-Patch experiments
///
/// @param panelTitle		Name of ITC device panel
/// @param UserSettings	User settings wave from configuration Notebook
static Function ExpConfig_Amplifiers(panelTitle, UserSettings)
	string panelTitle
	Wave /T UserSettings

	string AmpSerialLocal, AmpTitleLocal, CheckDA, HeadstagesToConfigure
	variable i, ii, ampSerial

	FindValue /TXOP = 4 /TEXT = AMP_SERIAL UserSettings
	AmpSerialLocal = UserSettings[V_value][%SettingValue]
	FindValue /TXOP = 4 /TEXT = AMP_TITLE UserSettings
	AmpTitleLocal = UserSettings[V_value][%SettingValue]
	FindValue /TXOP = 4 /TEXT = ACTIVE_HEADSTAGES UserSettings
	HeadstagesToConfigure = UserSettings[V_value][%SettingValue]

	Assert(AI_OpenMCCs(AmpSerialLocal, ampTitleList = AmpTitleLocal, maxAttempts = ATTEMPTS),"Evil kittens prevented MultiClamp from opening - FULL STOP" )

	ExpConfig_Position_MCC_Win(AmpSerialLocal,AmpTitleLocal)

	PGC_SetAndActivateControl(panelTitle,"button_Settings_UpdateAmpStatus")

	for(i = 0; i<NUM_HEADSTAGES; i+=1)

		PGC_SetAndActivateControl(panelTitle,"Popup_Settings_HeadStage", val = i)
		
		if(WhichListItem(num2str(i), HeadstagesToConfigure) != -1)
			if(!mod(i,2)) // even
				ampSerial = str2num(StringFromList(ii, AmpSerialLocal))
				PGC_SetAndActivateControl(panelTitle,"popup_Settings_Amplifier", val = ExpConfig_FindAmpInList(ampSerial, 1))
			else //odd
				ampSerial = str2num(StringFromList(ii, AmpSerialLocal))
				PGC_SetAndActivateControl(panelTitle,"popup_Settings_Amplifier", val = ExpConfig_FindAmpInList(ampSerial, 2))
				ii+=1
			endif
	
			PGC_SetAndActivateControl(panelTitle,"Popup_Settings_VC_DA", val = i)
	
			if(i>3)
				PGC_SetAndActivateControl(panelTitle,"Popup_Settings_VC_AD", val = i+4)
			else
				PGC_SetAndActivateControl(panelTitle,"Popup_Settings_VC_AD", val = i)
			endif
	
			CheckDA = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)
			PGC_SetAndActivateControl(panelTitle,CheckDA,val = CHECKBOX_SELECTED)
			PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_DATA_ACQUISITION)
			ExpConfig_MCC_InitParams(panelTitle,i)
			PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_HARDWARE)
		else
			PGC_SetAndActivateControl(panelTitle,"popup_Settings_Amplifier", val = WhichListItem(NONE, DAP_GetNiceAmplifierChannelList()))
		endif
	endfor

	PGC_SetAndActivateControl(panelTitle,"button_Hardware_AutoGainAndUnit")
End

/// @brief  Configure pressure devices for experiments
///
/// @param panelTitle		Name of ITC device panel
/// @param UserSettings	User settings wave from configuration Notebook
static Function ExpConfig_Pressure(panelTitle, UserSettings)
	string panelTitle
	Wave /T UserSettings

	variable i, ii=0, PressDevVal
	string NIDev, PressureDevLocal, PressureDataList, HeadstagesToConfigure

	PGC_SetAndActivateControl(panelTitle,"button_Settings_UpdateDACList")
	FindValue /TXOP = 4 /TEXT = PRESSURE_DEV UserSettings
	PressureDevLocal = UserSettings[V_value][%SettingValue]
	NIDev = HW_NI_ListDevices()
	FindValue /TXOP = 4 /TEXT = ACTIVE_HEADSTAGES UserSettings
	HeadstagesToConfigure = UserSettings[V_value][%SettingValue]

	for(i = 0; i<NUM_HEADSTAGES; i+=1)
		
		PGC_SetAndActivateControl(panelTitle,"Popup_Settings_HeadStage", val = i)
		
		if(WhichListItem(num2str(i), HeadstagesToConfigure) != -1)
			PressDevVal = WhichListItem(StringFromList(ii,PressureDevLocal),NIDev)
			PGC_SetAndActivateControl(panelTitle,"popup_Settings_Pressure_dev", val = PressDevVal+1)
			if(!mod(i,2)) // even
				PGC_SetAndActivateControl(panelTitle,"Popup_Settings_Pressure_DA", val = 0)
				PGC_SetAndActivateControl(panelTitle,"Popup_Settings_Pressure_AD", val = 0)
				PGC_SetAndActivateControl(panelTitle,"Popup_Settings_Pressure_TTLA", val = 1)
				PGC_SetAndActivateControl(panelTitle,"Popup_Settings_Pressure_TTLB", val = 2)
			else // odd
				PGC_SetAndActivateControl(panelTitle,"Popup_Settings_Pressure_DA", val = 1)
				PGC_SetAndActivateControl(panelTitle,"Popup_Settings_Pressure_AD", val = 1)
				PGC_SetAndActivateControl(panelTitle,"Popup_Settings_Pressure_TTLA", val = 3)
				PGC_SetAndActivateControl(panelTitle,"Popup_Settings_Pressure_TTLB", val = 4)
				ii+= 1
			endif
		else
			PGC_SetAndActivateControl(panelTitle,"popup_Settings_Pressure_dev", val = WhichListItem(NONE, DAP_GetNiceAmplifierChannelList()))
		endif
	endfor

	PGC_SetAndActivateControl(panelTitle,"button_Hardware_P_Enable")

	PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_SETTINGS)
	FindValue /TXOP = 4 /TEXT = PRESSURE_BATH UserSettings
	PGC_SetAndActivateControl(panelTitle,"setvar_Settings_InBathP", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = PRESSURE_STARTSEAL UserSettings
	PGC_SetAndActivateControl(panelTitle,"setvar_Settings_SealStartP", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = PRESSURE_MAXSEAL UserSettings
	PGC_SetAndActivateControl(panelTitle,"setvar_Settings_SealMaxP", val = str2num(UserSettings[V_value][%SettingValue]))

	// Set pressure calibration values
	FindValue /TXOP = 4 /TEXT = PRESSURE_CONST UserSettings
	Wave /T PressureConstantTextWv = ListToTextWave(UserSettings[V_value][%SettingValue], ";")
	Make /D/FREE PressureConstants = str2num(PressureConstantTextWv)
	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)

	pressureDataWv[%headStage_0][%PosCalConst] = PressureConstants[0]
	pressureDataWv[%headStage_1][%PosCalConst] = PressureConstants[1]
	pressureDataWv[%headStage_2][%PosCalConst] = PressureConstants[2]
	pressureDataWv[%headStage_3][%PosCalConst] = PressureConstants[3]
	pressureDataWv[%headStage_4][%PosCalConst] = PressureConstants[4]
	pressureDataWv[%headStage_5][%PosCalConst] = PressureConstants[5]
	pressureDataWv[%headStage_6][%PosCalConst] = PressureConstants[6]
	pressureDataWv[%headStage_7][%PosCalConst] = PressureConstants[7]

	pressureDataWv[%headStage_0][%NegCalConst] = -PressureConstants[0]
	pressureDataWv[%headStage_1][%NegCalConst] = -PressureConstants[1]
	pressureDataWv[%headStage_2][%NegCalConst] = -PressureConstants[2]
	pressureDataWv[%headStage_3][%NegCalConst] = -PressureConstants[3]
	pressureDataWv[%headStage_4][%NegCalConst] = -PressureConstants[4]
	pressureDataWv[%headStage_5][%NegCalConst] = -PressureConstants[5]
	pressureDataWv[%headStage_6][%NegCalConst] = -PressureConstants[6]
	pressureDataWv[%headStage_7][%NegCalConst] = -PressureConstants[7]

End

/// @brief  Monitor set and bath temperature during experiments
///
/// @param panelTitle		Name of ITC device panel
/// @param UserSettings	User settings wave from configuration Notebook
static Function ExpConfig_AsyncTemp(panelTitle, UserSettings)
	string panelTitle
	Wave /T UserSettings

	PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_ASYNCHRONOUS)
	FindValue /TXOP = 4 /TEXT = ASYNC_CH00 UserSettings
	PGC_SetAndActivateControl(panelTitle,"SetVar_AsyncAD_Title_00", str = UserSettings[V_value][%SettingValue])
	PGC_SetAndActivateControl(panelTitle,"Check_AsyncAD_00", val = 1)
	FindValue /TXOP = 4 /TEXT = TEMP_GAIN UserSettings
	PGC_SetAndActivateControl(panelTitle,"Gain_AsyncAD_00", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = ASYNC_UNIT UserSettings
	PGC_SetAndActivateControl(panelTitle,"Unit_AsyncAD_00", str = UserSettings[V_value][%SettingValue])
	FindValue /TXOP = 4 /TEXT = ASYNC_CH01 UserSettings
	PGC_SetAndActivateControl(panelTitle,"SetVar_AsyncAD_Title_01", str = UserSettings[V_value][%SettingValue])
	PGC_SetAndActivateControl(panelTitle,"Check_AsyncAD_01", val = 1)
	FindValue /TXOP = 4 /TEXT = TEMP_GAIN UserSettings
	PGC_SetAndActivateControl(panelTitle,"Gain_AsyncAD_01", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = ASYNC_UNIT UserSettings
	PGC_SetAndActivateControl(panelTitle,"Unit_AsyncAD_01", str = UserSettings[V_value][%SettingValue])
	PGC_SetAndActivateControl(panelTitle,"check_AsyncAlarm_01", val = 1)
	FindValue /TXOP = 4 /TEXT = TEMP_MAX UserSettings
	PGC_SetAndActivateControl(panelTitle,"max_AsyncAD_01", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = TEMP_MIN UserSettings
	PGC_SetAndActivateControl(panelTitle,"min_AsyncAD_01", val = str2num(UserSettings[V_value][%SettingValue]))

End

/// @brief  Set user defined experimental parameters
///
/// @param panelTitle		Name of ITC device panel
/// @param UserSettings	User settings wave from configuration Notebook
static Function ExpConfig_DAEphysSettings(panelTitle, UserSettings)
	string panelTitle
	Wave /T UserSettings

	PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_SETTINGS)
	FindValue /TXOP = 4 /TEXT = ENABLE_MULTIPLE_ITC UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_Settings_MD", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = TP_AFTER_DAQ UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_Settings_TPAfterDAQ", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = SAVE_TP UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_Settings_TP_SaveTPRecord", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = EXPORT_NWB UserSettings
	PGC_SetAndActivateControl(panelTitle,"Check_Settings_NwbExport", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = APPEND_ASYNC UserSettings
	PGC_SetAndActivateControl(panelTitle,"Check_Settings_Append", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = SYNC_MIES_MCC UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_Settings_SyncMiesToMCC", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = ENABLE_I_EQUAL_ZERO UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_Settings_AmpIEQZstep", val = str2num(UserSettings[V_value][%SettingValue]))
	PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_DATA_ACQUISITION)
	FindValue /TXOP = 4 /TEXT = ENABLE_OODAQ UserSettings
	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq1_dDAQOptOv", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = OODAQ_POST_DELAY UserSettings
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_dDAQOptOvPost", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = OODAQ_RESOLUTION UserSettings
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_dDAQOptOvRes", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = NUM_STIM_SETS UserSettings
	PGC_SetAndActivateControl(panelTitle,"SetVar_DataAcq_SetRepeats", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = GET_SET_ITI UserSettings
	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq_Get_Set_ITI", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = DEFAULT_ITI UserSettings
	PGC_SetAndActivateControl(panelTitle,"SetVar_DataAcq_ITI", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT  = PRESSURE_USER_FOLLOW_HS UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_DataACq_Pressure_AutoOFF", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = PRESSURE_USER_ON_SEAL UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_Settings_UserP_Seal", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = TP_AMP_VC UserSettings
	PGC_SetAndActivateControl(panelTitle,"SetVar_DataAcq_TPAmplitude", val = str2num(UserSettings[V_value][%SettingValue]))
End

/// @brief Intiate MCC parameters for active headstages
///
/// @param panelTitle	ITC device panel
/// @param headStage	Active headstage	 index
static Function ExpConfig_MCC_InitParams(panelTitle, headStage)
	string panelTitle
	variable headStage

	// Set initial parameters within MCC itself.

	AI_SelectMultiClamp(panelTitle, headStage)

	//Set V-clamp parameters

	DAP_ChangeHeadStageMode(panelTitle, V_CLAMP_MODE, headStage, DO_MCC_MIES_SYNCING)
	MCC_SetHoldingEnable(0)
	MCC_SetOscKillerEnable(0)
	MCC_SetFastCompTau(1.8e-6)
	MCC_SetSlowCompTau(1e-5)
	MCC_SetSlowCompTauX20Enable(0)
	MCC_SetRsCompBandwidth(1.02e3)
	MCC_SetRSCompCorrection(0)
	MCC_SetPrimarySignalGain(1)
	MCC_SetPrimarySignalLPF(10e3)
	MCC_SetPrimarySignalHPF(0)
	MCC_SetSecondarySignalGain(1)
	MCC_SetSecondarySignalLPF(10e3)

	//Set I-Clamp Parameters

	DAP_ChangeHeadStageMode(panelTitle, I_CLAMP_MODE, headStage, DO_MCC_MIES_SYNCING)
	MCC_SetHoldingEnable(0)
	MCC_SetSlowCurrentInjEnable(0)
	MCC_SetNeutralizationEnable(0)
	MCC_SetOscKillerEnable(0)
	MCC_SetPrimarySignalGain(1)
	MCC_SetPrimarySignalLPF(10e3)
	MCC_SetPrimarySignalHPF(0)
	MCC_SetSecondarySignalGain(1)
	MCC_SetSecondarySignalLPF(10e3)

	//Set mode back to V-clamp
	DAP_ChangeHeadStageMode(panelTitle, V_CLAMP_MODE, headStage, DO_MCC_MIES_SYNCING)

End

/// @brief Position MCC windows to upper right monitor using nircmd.exe
///
/// @param serialNum	Serial number of MCC
/// @param winTitle		Name of MCC window
static Function ExpConfig_Position_MCC_Win(serialNum, winTitle)
	string serialNum, winTitle
	Make /T /FREE winNm
	string cmd, fullPath
	variable w
	
	fullPath = GetFolder(FunctionPath("")) + "..:..:nircmd.exe"
	GetFileFolderInfo /Q/Z fullPath
	if(V_flag != 0)
		printf "nircmd.exe is not installed, please download it here: %s", "http://www.nirsoft.net/utils/nircmd.html"
	endif
	
	for(w = 0; w<NUM_HEADSTAGES/2; w+=1)

		winNm[w] = {stringfromlist(w,winTitle) + "(" + stringfromlist(w,serialNum) + ")"}
		sprintf cmd, "nircmd.exe win center title \"%s\"", winNm[w]
		ExecuteScriptText cmd
	endfor

	sprintf cmd, "nircmd.exe win move title \"%s\" 2300 -1250 0 0",  winNm[0]
	ExecuteScriptText cmd
	sprintf cmd, "nircmd.exe win activate title \"%s\"", winNm[0]
	ExecuteScriptText cmd
	sprintf cmd, "nircmd.exe win move title \"%s\" 2675 -1250 0 0",  winNm[1]
	ExecuteScriptText cmd
	sprintf cmd, "nircmd.exe win activate title \"%s\"", winNm[1]
	ExecuteScriptText cmd
	sprintf cmd, "nircmd.exe win move title \"%s\" 2300 -900 0 0",  winNm[2]
	ExecuteScriptText cmd
	sprintf cmd, "nircmd.exe win activate title \"%s\"", winNm[2]
	ExecuteScriptText cmd
	sprintf cmd, "nircmd.exe win move title \"%s\" 2675 -900 0 0",  winNm[3]
	ExecuteScriptText cmd
	sprintf cmd, "nircmd.exe win activate title \"%s\"", winNm[3]
	ExecuteScriptText cmd

End

///@brief Set intial values for headstage clamp modes
static Function ExpConfig_ClampModes(panelTitle, UserSettings)
	string panelTitle
	Wave /T UserSettings

	// Set initial values for V-Clamp and I-Clamp in MIES
	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq_SendToAllAmp", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(panelTitle,"check_DatAcq_HoldEnableVC", val = CHECKBOX_UNSELECTED)
	FindValue /TXOP = 4 /TEXT = HOLDING UserSettings
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_Hold_VC", val = str2num(UserSettings[V_value][%SettingValue]))
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_PipetteOffset_VC", val = 0)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_WCC", val = 0)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_WCR", val = 0)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_RsCorr", val = 0)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_RsPred", val = 0)
	PGC_SetAndActivateControl(panelTitle,"check_DatAcq_HoldEnable", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(panelTitle,"check_DatAcq_BBEnable", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(panelTitle,"check_DatAcq_CNEnable", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_PipetteOffset_IC", val = 0)
	FindValue /TXOP = 4 /TEXT = HOLDING UserSettings
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_AutoBiasV", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = AUTOBIAS_RANGE UserSettings
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_AutoBiasVrange", val = str2num(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = AUTOBIAS_MAXI UserSettings
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_IbiasMax", val = str2num(UserSettings[V_value][%SettingValue]))
	PGC_SetAndActivateControl(panelTitle,"check_DataAcq_AutoBias", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq_SendToAllAmp", val = CHECKBOX_UNSELECTED)

End

/// @brief Find the list index of a connected amplifier serial number
///
/// @param ampSerialRef		Amplifier Serial Number to search for
/// @param ampChannelIDRef	Headstage reference number
static Function ExpConfig_FindAmpInList(ampSerialRef, ampChannelIDRef)
	variable ampSerialRef, ampChannelIDRef

	string listOfAmps, ampDef
	variable numAmps, i, ampSerial, ampChannelID

	listOfAmps = DAP_GetNiceAmplifierChannelList()
	numAmps = ItemsInList(listOfAmps)

	for(i = 0; i < numAmps; i += 1)
		ampDef = StringFromList(i, listOfAmps)
		DAP_ParseAmplifierDef(ampDef, ampSerial, ampChannelID)
		if(ampSerial == ampSerialRef && ampChannelID == ampChannelIDRef)
			return i
		endif
	endfor

		ASSERT(0, "Could not find amplifier")
End
