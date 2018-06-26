#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

/// @file MIES_ExperimentConfig.ipf
///
/// @brief __ExpConfig__ Import user settings to configure paramters for Ephys experiments
///
/// These include:
/// - Amplifier settings
/// - Pressure regulator settings
/// - Interactions with MCCs
/// - DAEphys panel settings

#if exists("MCC_GetMode") && exists("AxonTelegraphGetDataStruct")
#define AMPLIFIER_XOPS_PRESENT
#endif

/// @brief Configure MIES for experiments
///
/// @param middleOfExperiment [optional, defaults to false] Allows MIES config in the middle of experiment. Instead of setting MCC parameters they are pulled from actively recording MCCs to configure MIES]
Function ExpConfig_ConfigureMIES([middleOfExperiment])
	variable middleOfExperiment

	string UserConfigNB, win, filename, ITCDevNum, ITCDevType, fullPath, StimSetPath, activeNotebooks, AmpSerialLocal, AmpTitleLocal, ConfigError, StimSetList
	variable i, load
//	movewindow /C 1450, 530,-1,-1								// position command window
	
	if(ParamIsDefault(middleOfExperiment))
		middleOfExperiment = 0
	else
		middleOfExperiment = !!middleOfExperiment
	endif
	
	if(middleOfExperiment)
		HW_ITC_CloseAllDevices(flags = HARDWARE_PREVENT_ERROR_POPUP | HARDWARE_PREVENT_ERROR_MESSAGE)
	endif
	
	activeNotebooks = WinList("*",";","WIN:16")
	if(!isempty(activeNotebooks))
		for(i = 0; i < ItemsInList(activeNotebooks); i += 1)
			KillWindow /Z $StringFromList(i, activeNotebooks)
		endfor
	endif
	
	fullPath = GetFolder(FunctionPath("")) + USER_CONFIG_PATH
	ASSERT(!cmpstr(GetFileSuffix(fullPath), "txt"), "Only plain notebooks are supported")
	printf "Opening User Configuration Notebook\r"
	OpenNotebook/ENCG=1/R/N=UserConfigNB/V=0/Z fullPath
	if(V_flag)
		printf "A User Configuration Notebook could not be loaded.\r" + \
				 "Please ensure that there is a plain text file named 'UserConfig.txt' in the following path: %s\r" + \
				 "If it does not exist you may create one using the following format:\r" + \
				 "#### Header information or instructions that will NOT be parsed ####\r" + \
				 "Control A to be configured = control A setting\r" + \
				 "Control B to be configured = control B setting\r" + \
				 "...\r" + \
				 "#### end ####\r" + \
				 "Add a strConstant for each configurable control text and use that strConstant in GetExpConfigKeyTypes to extract Control:Value pairs\r", fullPath
		ControlWindowToFront()
		
	else
	
		printf "Configuration Notebook successfully loaded, extracting user settings\r"
		
		UserConfigNB = winname(0,16)
		Wave /T KeyTypes = GetExpConfigKeyTypes()
		Wave /T UserSettings = GetExpUserSettings(UserConfigNB, KeyTypes)

		KillWindow/Z $UserConfigNB
		
		FindValue /TXOP = 4 /TEXT = AMP_SERIAL UserSettings
		AmpSerialLocal = UserSettings[V_value][%SettingValue]
		FindValue /TXOP = 4 /TEXT = AMP_TITLE UserSettings
		AmpTitleLocal = UserSettings[V_value][%SettingValue]
	
		printf "Openning MCC amplifiers\r"
		Assert(AI_OpenMCCs(AmpSerialLocal, ampTitleList = AmpTitleLocal, maxAttempts = ATTEMPTS),"Evil kittens prevented MultiClamp from opening - FULL STOP" )
		
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
			PGC_SetAndActivateControl(win,"popup_moreSettings_DeviceNo", val = WhichListItem(ITCDevNum,DEVICE_NUMBERS))
			PGC_SetAndActivateControl(win,"button_SettingsPlus_LockDevice")
	
			win = BuildDeviceString(ITCDevType, ITCDevNum)
		endif
		
		if(middleOfExperiment)
			PGC_SetAndActivateControl(win,"check_Settings_SyncMiesToMCC", val = CHECKBOX_UNSELECTED)
		endif
		
		ExpConfig_Amplifiers(win, UserSettings, middleOfExperiment)
	
		ExpConfig_Pressure(win, UserSettings)
	
		ExpConfig_ClampModes(win, UserSettings, middleOfExperiment)
	
		ExpConfig_AsyncTemp(win, UserSettings)
	
		ExpConfig_DAEphysSettings(win, UserSettings)
	
		FindValue /TXOP = 4 /TEXT = STIMSET_NAME UserSettings
		if(V_value != -1)
			StimSetPath = UserSettings[V_value][%SettingValue]
			load = NWB_LoadAllStimSets(overwrite = 1, fileName = StimSetPath)
		else
			load = NWB_LoadAllStimSets(overwrite = 1)
		endif
		
		if (!load)
			print "Stim set successfully loaded"
			StimSetList = "- none -;"+ReturnListOfAllStimSets(0, CHANNEL_DA_SEARCH_STRING)
			FindValue /TXOP = 4 /TEXT = FIRST_STIM_VC_ALL UserSettings
			PGC_SetAndActivateControl(win,GetPanelControl(CHANNEL_INDEX_ALL_V_CLAMP,CHANNEL_TYPE_DAC,CHANNEL_CONTROL_WAVE), val = WhichListItem(UserSettings[V_value][%SettingValue], StimSetList))
			FindValue /TXOP = 4 /TEXT = FIRST_STIM_AMP_VC_ALL UserSettings
			PGC_SetAndActivateControl(win,GetPanelControl(CHANNEL_INDEX_ALL_V_CLAMP,CHANNEL_TYPE_DAC,CHANNEL_CONTROL_SCALE), val = str2numSafe(UserSettings[V_value][%SettingValue]))
			FindValue /TXOP = 4 /TEXT = FIRST_STIM_IC_ALL UserSettings
			PGC_SetAndActivateControl(win,GetPanelControl(CHANNEL_INDEX_ALL_I_CLAMP,CHANNEL_TYPE_DAC,CHANNEL_CONTROL_WAVE), val = WhichListItem(UserSettings[V_value][%SettingValue], StimSetList))
			FindValue /TXOP = 4 /TEXT = FIRST_STIM_AMP_IC_ALL UserSettings
			PGC_SetAndActivateControl(win,GetPanelControl(CHANNEL_INDEX_ALL_I_CLAMP,CHANNEL_TYPE_DAC,CHANNEL_CONTROL_SCALE), val = str2numSafe(UserSettings[V_value][%SettingValue]))
		else
			print "Stim set failed to load, check file path"
			ControlWindowToFront()
		endif
		
		PGC_SetAndActivateControl(win,"ADC", val = DA_EPHYS_PANEL_DATA_ACQUISITION)
		PGC_SetAndActivateControl(win, "tab_DataAcq_Amp", val = DA_EPHYS_PANEL_VCLAMP)
		PGC_SetAndActivateControl(win, "tab_DataAcq_Pressure", val = DA_EPHYS_PANEL_PRESSURE_AUTO)
	
		filename = GetTimeStamp() + PACKED_FILE_EXPERIMENT_SUFFIX
		FindValue /TXOP = 4 /TEXT = SAVE_PATH UserSettings
		NewPath /C/O SavePath, UserSettings[V_value][%SettingValue]
	
		SaveExperiment /P=SavePath as filename

		KillPath/Z SavePath
	
		PGC_SetAndActivateControl(win,"StartTestPulseButton")
	
		print "Start Sciencing"
	endif
End

/// @brief  Open and configure amplifiers for Multi-Patch experiments
///
/// @param panelTitle		Name of ITC device panel
/// @param UserSettings	User settings wave from configuration Notebook
/// @param midExp			Configure in middle of experiment, default  = 0
static Function ExpConfig_Amplifiers(panelTitle, UserSettings, midExp)
	string panelTitle
	Wave /T UserSettings
	variable midExp

	string AmpSerialLocal, AmpTitleLocal, CheckDA, HeadstagesToConfigure, MCCWinPosition
	variable i, ii, ampSerial, numRows, RequireAmpConnection
	
	FindValue /TXOP = 4 /TEXT = AMP_SERIAL UserSettings
	AmpSerialLocal = UserSettings[V_value][%SettingValue]
	FindValue /TXOP = 4 /TEXT = AMP_TITLE UserSettings
	AmpTitleLocal = UserSettings[V_value][%SettingValue]
	FindValue /TXOP = 4 /TEXT = ACTIVE_HEADSTAGES UserSettings
	HeadstagesToConfigure = UserSettings[V_value][%SettingValue]
	FindValue /TXOP = 4 /TEXT = REQUIRE_AMP UserSettings
	RequireAmpConnection = str2numSafe(UserSettings[V_value][%SettingValue])
	PGC_SetAndActivateControl(panelTitle,"check_Settings_RequireAmpConn", val = RequireAmpConnection)
	FindValue /TXOP = 4 /TEXT = ENABLE_I_EQUAL_ZERO UserSettings

	WAVE telegraphServers = GetAmplifierTelegraphServers()

	numRows = DimSize(telegraphServers, ROWS)
	if(!numRows)
		printf "Openning MCC amplifiers\r"
		Assert(AI_OpenMCCs(AmpSerialLocal, ampTitleList = AmpTitleLocal, maxAttempts = ATTEMPTS),"Evil kittens prevented MultiClamp from opening - FULL STOP" )
	endif
	
	FindValue /TXOP = 4 /TEXT = POSITION_MCC UserSettings
	MCCWinPosition = UserSettings[V_Value][%SettingValue]
	if(cmpstr(NONE, MCCWinPosition) != 0)
		ExpConfig_Position_MCC_Win(AmpSerialLocal,AmpTitleLocal, MCCWinPosition)
	endif

	PGC_SetAndActivateControl(panelTitle,"button_Settings_UpdateAmpStatus")

	printf "Configuring headstage:\r"
	for(i = 0; i<NUM_HEADSTAGES; i+=1)

		PGC_SetAndActivateControl(panelTitle,"Popup_Settings_HeadStage", val = i)
		
		if(WhichListItem(num2str(i), HeadstagesToConfigure) != -1)
			CheckDA = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)
			if(IsInteger(str2numSafe(StringFromList(ii, AmpSerialLocal))))
				if(!mod(i,2)) // even
					ampSerial = str2numSafe(StringFromList(ii, AmpSerialLocal))
					PGC_SetAndActivateControl(panelTitle,"popup_Settings_Amplifier", val = ExpConfig_FindAmpInList(ampSerial, 1))
				else //odd
					ampSerial = str2numSafe(StringFromList(ii, AmpSerialLocal))
					PGC_SetAndActivateControl(panelTitle,"popup_Settings_Amplifier", val = ExpConfig_FindAmpInList(ampSerial, 2))
					ii+=1
				endif
		
				PGC_SetAndActivateControl(panelTitle,"Popup_Settings_VC_DA", val = i)
		
				if(i>3)
					PGC_SetAndActivateControl(panelTitle,"Popup_Settings_VC_AD", val = i+4)
				else
					PGC_SetAndActivateControl(panelTitle,"Popup_Settings_VC_AD", val = i)
				endif
				
				if(!midExp)
					ExpConfig_MCC_InitParams(panelTitle, i)
				else
					ExpConfig_MCC_MidExp(panelTitle, i, UserSettings)
				endif
				
				PGC_SetAndActivateControl(panelTitle,CheckDA,val = CHECKBOX_SELECTED)
				PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_DATA_ACQUISITION)
				PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_HARDWARE)
		
				printf "%d successful\r", i
			elseif(!RequireAmpConnection)  
				PGC_SetAndActivateControl(panelTitle,"popup_Settings_Amplifier", val = WhichListItem(NONE, DAP_GetNiceAmplifierChannelList()))
				PGC_SetAndActivateControl(panelTitle,CheckDA,val = CHECKBOX_SELECTED)
				printf "%d not connected to amplifier but configured\r", i	
			else
				PGC_SetAndActivateControl(panelTitle,"popup_Settings_Amplifier", val = WhichListItem(NONE, DAP_GetNiceAmplifierChannelList()))
				printf "%d not active\r", i
			endif
		else
			PGC_SetAndActivateControl(panelTitle,"popup_Settings_Amplifier", val = WhichListItem(NONE, DAP_GetNiceAmplifierChannelList()))
			printf "%d not active\r", i
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
	string NIDev, PressureDevLocal, PressureDataList, HeadstagesToConfigure, AmpSerialLocal

	PGC_SetAndActivateControl(panelTitle,"button_Settings_UpdateDACList")
	FindValue /TXOP = 4 /TEXT = PRESSURE_DEV UserSettings
	PressureDevLocal = UserSettings[V_value][%SettingValue]
	NIDev = HW_NI_ListDevices()
	FindValue /TXOP = 4 /TEXT = ACTIVE_HEADSTAGES UserSettings
	HeadstagesToConfigure = UserSettings[V_value][%SettingValue]
	FindValue /TXOP = 4 /TEXT = AMP_SERIAL UserSettings
	AmpSerialLocal = UserSettings[V_value][%SettingValue]
	
	printf "Configuring pressure device for headstage:\r"
	for(i = 0; i<NUM_HEADSTAGES; i+=1)
		
		PGC_SetAndActivateControl(panelTitle,"Popup_Settings_HeadStage", val = i)
		
		if(WhichListItem(num2str(i), HeadstagesToConfigure) != -1)
			if(IsInteger(str2numSafe(StringFromList(ii, AmpSerialLocal))))
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
				printf "%d successful\r", i
			else
				PGC_SetAndActivateControl(panelTitle,"popup_Settings_Pressure_dev", val = WhichListItem(NONE, DAP_GetNiceAmplifierChannelList()))
				printf "%d not connected to pressure DAQ\r", i
			endif
		else
			PGC_SetAndActivateControl(panelTitle,"popup_Settings_Pressure_dev", val = WhichListItem(NONE, DAP_GetNiceAmplifierChannelList()))
			printf "%d not active\r", i
		endif
	endfor

	PGC_SetAndActivateControl(panelTitle,"button_Hardware_P_Enable")

	PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_SETTINGS)
	FindValue /TXOP = 4 /TEXT = PRESSURE_BATH UserSettings
	PGC_SetAndActivateControl(panelTitle,"setvar_Settings_InBathP", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = PRESSURE_STARTSEAL UserSettings
	PGC_SetAndActivateControl(panelTitle,"setvar_Settings_SealStartP", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = PRESSURE_MAXSEAL UserSettings
	PGC_SetAndActivateControl(panelTitle,"setvar_Settings_SealMaxP", val = str2numSafe(UserSettings[V_value][%SettingValue]))

	// Set pressure calibration values
	FindValue /TXOP = 4 /TEXT = PRESSURE_CONST UserSettings
	Wave /T PressureConstantTextWv = ListToTextWave(UserSettings[V_value][%SettingValue], ";")
	Make /D/FREE PressureConstants = str2numSafe(PressureConstantTextWv)
	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	printf "Setting pressure calibration constants\r"
	
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
	printf "Setting Asynchronous Temperature monitoring\r"
	
	PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_ASYNCHRONOUS)
	FindValue /TXOP = 4 /TEXT = ASYNC_CH00 UserSettings
	PGC_SetAndActivateControl(panelTitle, GetPanelControl(0, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_TITLE), str = UserSettings[V_value][%SettingValue])
	PGC_SetAndActivateControl(panelTitle, GetPanelControl(0, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_CHECK), val = 1)
	FindValue /TXOP = 4 /TEXT = TEMP_GAIN UserSettings
	PGC_SetAndActivateControl(panelTitle, GetPanelControl(0, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN), val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = ASYNC_UNIT UserSettings
	PGC_SetAndActivateControl(panelTitle, GetPanelControl(0, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_UNIT), str = UserSettings[V_value][%SettingValue])
	FindValue /TXOP = 4 /TEXT = ASYNC_CH01 UserSettings
	PGC_SetAndActivateControl(panelTitle, GetPanelControl(1, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_TITLE), str = UserSettings[V_value][%SettingValue])
	PGC_SetAndActivateControl(panelTitle, GetPanelControl(1, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_CHECK), val = 1)
	FindValue /TXOP = 4 /TEXT = TEMP_GAIN UserSettings
	PGC_SetAndActivateControl(panelTitle, GetPanelControl(1, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_GAIN), val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = ASYNC_UNIT UserSettings
	PGC_SetAndActivateControl(panelTitle, GetPanelControl(1, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_UNIT), str = UserSettings[V_value][%SettingValue])
	PGC_SetAndActivateControl(panelTitle, GetPanelControl(1, CHANNEL_TYPE_ALARM, CHANNEL_CONTROL_CHECK), val = 1)
	FindValue /TXOP = 4 /TEXT = TEMP_MAX UserSettings
	PGC_SetAndActivateControl(panelTitle,GetPanelControl(1, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MAX), val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = TEMP_MIN UserSettings
	PGC_SetAndActivateControl(panelTitle, GetPanelControl(1, CHANNEL_TYPE_ASYNC, CHANNEL_CONTROL_ALARM_MIN), val = str2numSafe(UserSettings[V_value][%SettingValue]))

End

/// @brief  Set user defined experimental parameters
///
/// @param panelTitle		Name of ITC device panel
/// @param UserSettings	User settings wave from configuration Notebook
static Function ExpConfig_DAEphysSettings(panelTitle, UserSettings)
	string panelTitle
	Wave /T UserSettings
	variable midExp
	printf "Setting user defined DA_Ephys parameters\r"
	PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_SETTINGS)
	FindValue /TXOP = 4 /TEXT = ENABLE_MULTIPLE_ITC UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_Settings_MD", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = TP_AFTER_DAQ UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_Settings_TPAfterDAQ", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = SAVE_TP UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_Settings_TP_SaveTPRecord", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = SAVE_TP_SWEEP UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_Settings_TP_SaveTP", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = EXPORT_NWB UserSettings
	PGC_SetAndActivateControl(panelTitle,"Check_Settings_NwbExport", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = APPEND_ASYNC UserSettings
	PGC_SetAndActivateControl(panelTitle,"Check_Settings_Append", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = SYNC_MIES_MCC UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_Settings_SyncMiesToMCC", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = SAVE_AMP_SETTINGS UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_Settings_SaveAmpSettings", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = ENABLE_I_EQUAL_ZERO UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_Settings_AmpIEQZstep", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_DATA_ACQUISITION)
	FindValue /TXOP = 4 /TEXT = ENABLE_OODAQ UserSettings
	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq1_dDAQOptOv", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = OODAQ_POST_DELAY UserSettings
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_dDAQOptOvPost", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = OODAQ_RESOLUTION UserSettings
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_dDAQOptOvRes", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = USER_ONSET_DELAY UserSettings
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_OnsetDelayUser", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = TERMINATION_DELAY UserSettings
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_TerminationDelay", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = NUM_STIM_SETS UserSettings
	PGC_SetAndActivateControl(panelTitle,"SetVar_DataAcq_SetRepeats", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = GET_SET_ITI UserSettings
	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq_Get_Set_ITI", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = DEFAULT_ITI UserSettings
	PGC_SetAndActivateControl(panelTitle,"SetVar_DataAcq_ITI", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT  = PRESSURE_USER_FOLLOW_HS UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_DataACq_Pressure_AutoOFF", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = PRESSURE_USER_ON_SEAL UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_Settings_UserP_Seal", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = TP_AMP_VC UserSettings
	PGC_SetAndActivateControl(panelTitle,"SetVar_DataAcq_TPAmplitude", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = TP_AMP_IC UserSettings
	PGC_SetAndActivateControl(panelTitle,"SetVar_DataAcq_TPAmplitudeIC", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = TP_BASELINE UserSettings
	PGC_SetAndActivateControl(panelTitle,"SetVar_DataAcq_TPBaselinePerc", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = STIM_MODE_SWITCH UserSettings
	PGC_SetAndActivateControl(panelTitle,"check_DA_applyOnModeSwitch", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	FindValue /TXOP = 4 /TEXT = ANALYSIS_FUNC UserSettings
	PGC_SetAndActivateControl(panelTitle,"Check_Settings_SkipAnalysFuncs", val = str2numSafe(UserSettings[V_value][%SettingValue]))
	
End

#ifdef AMPLIFIER_XOPS_PRESENT

/// @brief Intiate MCC parameters for active headstages
///
/// @param panelTitle	ITC device panel
/// @param headStage	MIES headstage number, must be in the range [0, NUM_HEADSTAGES]
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

#else

static Function ExpConfig_MCC_InitParams(panelTitle, headStage)
	string panelTitle
	variable headStage

	DEBUGPRINT("Unimplemented")

	return NaN
End

#endif

Function ExpConfig_MCC_MidExp(panelTitle, headStage, UserSettings)
	string panelTitle
	variable headStage
	Wave /T UserSettings

	variable settingValue, clampMode
	
	PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_DATA_ACQUISITION)
	PGC_SetAndActivateControl(panelTitle,"slider_DataAcq_ActiveHeadstage", val = headStage)

	clampMode = AI_GetMode(panelTitle, headstage)

	if(clampMode == V_CLAMP_MODE)
		
		DAP_ChangeHeadStageMode(panelTitle, V_CLAMP_MODE, headStage, SKIP_MCC_MIES_SYNCING)
		settingValue = AI_SendToAmp(panelTitle, headStage, V_CLAMP_MODE, MCC_GETPIPETTEOFFSET_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_PipetteOffset_VC", val = settingValue)
		PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_PipetteOffset_IC", val = settingValue)
		settingValue = AI_SendToAmp(panelTitle, headStage, V_CLAMP_MODE, MCC_GETHOLDING_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_Hold_VC", val = settingValue)
		settingValue = AI_SendToAmp(panelTitle, headStage, V_CLAMP_MODE, MCC_GETHOLDINGENABLE_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "check_DatAcq_HoldEnableVC", val = settingValue)
		FindValue /TXOP = 4 /TEXT = HOLDING UserSettings
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_AutoBiasV", val = str2numSafe(UserSettings[V_value][%SettingValue]))
		FindValue /TXOP = 4 /TEXT = AUTOBIAS_RANGE UserSettings
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_AutoBiasVrange", val = str2numSafe(UserSettings[V_value][%SettingValue]))
		FindValue /TXOP = 4 /TEXT = AUTOBIAS_MAXI UserSettings
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_IbiasMax", val = str2numSafe(UserSettings[V_value][%SettingValue]))
		PGC_SetAndActivateControl(panelTitle,"check_DataAcq_AutoBias", val = CHECKBOX_SELECTED)
		printf "HeadStage %d is in V-Clamp mode and has been configured from the MCC. I-Clamp settings were reset to initial values, check before switching!\r", headStage
	elseif(clampMode == I_CLAMP_MODE)
		DAP_ChangeHeadStageMode(panelTitle, I_CLAMP_MODE, headStage, SKIP_MCC_MIES_SYNCING)
		settingValue = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETPIPETTEOFFSET_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_PipetteOffset_VC", val = settingValue)
		PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_PipetteOffset_IC", val = settingValue)
		settingValue = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETHOLDING_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_Hold_IC", val = settingValue)
		settingValue = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETHOLDINGENABLE_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "check_DatAcq_HoldEnable", val = settingValue)
		settingValue = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETBRIDGEBALRESIST_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_BB", val = settingValue)
		settingValue = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETBRIDGEBALENABLE_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "check_DatAcq_BBEnable", val = settingValue)
		settingValue = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETNEUTRALIZATIONCAP_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "setvar_DataAcq_CN", val = settingValue)
		settingValue = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETNEUTRALIZATIONENABL_FUNC, NaN, checkBeforeWrite = 1)
		PGC_SetAndActivateControl(panelTitle, "check_DatAcq_CNEnable", val = settingValue)
		FindValue /TXOP = 4 /TEXT = AUTOBIAS_RANGE UserSettings
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_AutoBiasVrange", val = str2numSafe(UserSettings[V_value][%SettingValue]))
		FindValue /TXOP = 4 /TEXT = AUTOBIAS_MAXI UserSettings
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_IbiasMax", val = str2numSafe(UserSettings[V_value][%SettingValue]))
		PGC_SetAndActivateControl(panelTitle,"check_DataAcq_AutoBias", val = CHECKBOX_UNSELECTED)
		PGC_SetAndActivateControl(panelTitle,"check_DatAcq_HoldEnableVC", val = CHECKBOX_UNSELECTED)
		FindValue /TXOP = 4 /TEXT = HOLDING UserSettings
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_Hold_VC", val = str2numSafe(UserSettings[V_value][%SettingValue]))
		printf "HeadStage %d is in I-Clamp mode and has been configured from the MCC. V-Clamp settings were reset to initial values, check before switching!\r", headStage
	elseif(clampMode == I_EQUAL_ZERO_MODE)
		// do nothing
	endif
	PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_SETTINGS)
End

/// @brief Position MCC windows to upper right monitor using nircmd.exe
///
/// @param serialNum	Serial number of MCC
/// @param winTitle		Name of MCC window
/// @param winPosition One of 4 monitors to position MCCs in
Function ExpConfig_Position_MCC_Win(serialNum, winTitle, winPosition)
	string serialNum, winTitle, winPosition
	Make /T /FREE winNm
	string cmd, fullPath, cmdPath
	variable w
	
	if(cmpstr(winPosition, NONE) == 0)
		return 0
	endif
	
	fullPath = GetFolder(FunctionPath("")) + "..:..:tools:nircmd:nircmd.exe"
	GetFileFolderInfo /Q/Z fullPath
	cmdPath = S_Creator
	if(V_flag != 0)
		printf "nircmd.exe is not installed, please download it here: %s", "http://www.nirsoft.net/utils/nircmd.html"
	endif
	
	for(w = 0; w<NUM_HEADSTAGES/2; w+=1)

		winNm[w] = {stringfromlist(w,winTitle) + "(" + stringfromlist(w,serialNum) + ")"}
		sprintf cmd, "\"%s\" nircmd.exe win center title \"%s\"", cmdPath, winNm[w]
		ExecuteScriptText cmd
	endfor

	if(cmpstr(winPosition, "Upper Right") == 0)
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 2300 -1250 0 0", cmdPath, winNm[0]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[0]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 2675 -1250 0 0", cmdPath, winNm[1]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[1]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 2300 -900 0 0", cmdPath, winNm[2]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[2]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\"nircmd.exe win move title \"%s\" 2675 -900 0 0", cmdPath, winNm[3]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[3]
		ExecuteScriptText cmd
	elseif(cmpstr(winPosition, "Lower Right") == 0)
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 2300 -200 0 0", cmdPath, winNm[0]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[0]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 2675 -200 0 0", cmdPath, winNm[1]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[1]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 2300 100 0 0", cmdPath, winNm[2]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[2]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\"nircmd.exe win move title \"%s\" 2675 100 0 0", cmdPath, winNm[3]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[3]
		ExecuteScriptText cmd
	elseif(cmpstr(winPosition, "Lower Left") == 0)
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 300 -200 0 0", cmdPath, winNm[0]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[0]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 700 -200 0 0", cmdPath, winNm[1]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[1]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 300 100 0 0", cmdPath, winNm[2]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[2]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\"nircmd.exe win move title \"%s\" 700 100 0 0", cmdPath, winNm[3]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[3]
		ExecuteScriptText cmd
	elseif(cmpstr(winPosition, "Upper Left") == 0)
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 300 -1250 0 0", cmdPath, winNm[0]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[0]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 700 -1250 0 0", cmdPath, winNm[1]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[1]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win move title \"%s\" 300 -900 0 0", cmdPath, winNm[2]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[2]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\"nircmd.exe win move title \"%s\" 700 -900 0 0", cmdPath, winNm[3]
		ExecuteScriptText cmd
		sprintf cmd, "\"%s\" nircmd.exe win activate title \"%s\"", cmdPath, winNm[3]
		ExecuteScriptText cmd
	else
		printf "Message: If you would like to position the MCC windows please select a monitor in the Configuration text file"
	endif

End

/// @brief Set intial values for headstage clamp modes
///
/// @param panelTitle		Name of ITC device panel
/// @param UserSettings	User settings wave from configuration Notebook
/// @param midExp			Configure in middle of experiment, default  = 0
static Function ExpConfig_ClampModes(panelTitle, UserSettings, midExp)
	string panelTitle
	Wave /T UserSettings
	variable midExp

	if(!midExp)
	
		// Set initial values for V-Clamp and I-Clamp in MIES
		PGC_SetAndActivateControl(panelTitle,"Check_DataAcq_SendToAllAmp", val = CHECKBOX_SELECTED)
		PGC_SetAndActivateControl(panelTitle,"check_DatAcq_HoldEnableVC", val = CHECKBOX_UNSELECTED)
		FindValue /TXOP = 4 /TEXT = HOLDING UserSettings
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_Hold_VC", val = str2numSafe(UserSettings[V_value][%SettingValue]))
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_PipetteOffset_VC", val = 0)
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_WCC", val = 0)
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_WCR", val = 0)
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_RsCorr", val = 0)
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_RsPred", val = 0)
		PGC_SetAndActivateControl(panelTitle,"check_DatAcq_HoldEnable", val = CHECKBOX_UNSELECTED)
		PGC_SetAndActivateControl(panelTitle,"check_DatAcq_BBEnable", val = CHECKBOX_UNSELECTED)
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_CN", val = 0)
		FindValue /TXOP = 4 /TEXT = CAP_NEUT UserSettings
		PGC_SetAndActivateControl(panelTitle,"check_DatAcq_CNEnable", val = str2numSafe(UserSettings[V_value][%SettingValue]))
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_PipetteOffset_IC", val = 0)
		FindValue /TXOP = 4 /TEXT = HOLDING UserSettings
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_AutoBiasV", val = str2numSafe(UserSettings[V_value][%SettingValue]))
		FindValue /TXOP = 4 /TEXT = AUTOBIAS_RANGE UserSettings
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_AutoBiasVrange", val = str2numSafe(UserSettings[V_value][%SettingValue]))
		FindValue /TXOP = 4 /TEXT = AUTOBIAS_MAXI UserSettings
		PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_IbiasMax", val = str2numSafe(UserSettings[V_value][%SettingValue]))
		FindValue /TXOP = 4 /TEXT = AUTOBIAS UserSettings
		PGC_SetAndActivateControl(panelTitle,"check_DataAcq_AutoBias", val = str2numSafe(UserSettings[V_value][%SettingValue]))
		PGC_SetAndActivateControl(panelTitle,"Check_DataAcq_SendToAllAmp", val = CHECKBOX_UNSELECTED)
	endif
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
