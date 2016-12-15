#pragma TextEncoding = "Windows-1252"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @brief Configure MIES for Multi-patch experiments	
Function MultiPatchConfig()
	
	string UserConfigList, win, filename, ITCDev, UserConfigNB
	variable ITCDevNum
	
	movewindow /C 1450, 530,-1,-1								// position command window
	
	DoWindow UserConfigNB
	if(!V_flag)
		OpenNotebook /R/Z/N=UserConfigNB/V=0/T="WMTO" USER_CONFIG_PATH
		if(V_flag)
			ASSERT(V_flag == 1, "Configuration Notebook not loaded")
		endif		
	endif
	
	UserConfigNB = winname(0,16)
	UserConfigList = MPConfig_ImportUserSettings(UserConfigNB)
	ITCDev = ReadConfigList_Textual(ITC_DEV, UserConfigList)

	if(WindowExists(ITCDev +"_Dev_0"))
		win = ITCDev + "_Dev_0"
	else
		if(WindowExists("DA_Ephys"))
			win = "DA_Ephys"
		else	
			win = DAP_CreateDAEphysPanel() 									//open DA_Ephys
			movewindow /W = $win 1500, -700,-1,-1				//position DA_Ephys window
		endif
		
		ITCDevNum = WhichListItem(ITCDev,DEVICE_TYPES) 
		PGC_SetAndActivateControl(win,"popup_MoreSettings_DeviceType", val = ITCDevNum) 
		PGC_SetAndActivateControl(win,"button_SettingsPlus_LockDevice")
		
		win = ITCDev + "_Dev_0"
	endif	
	
	MPConfig_Amplifiers(win, ConfigList = UserConfigList)
	
	MPConfig_Pressure(win, ConfigList = UserConfigList)
	
	MPConfig_ClampModes(win)
	
	MPConfig_AsyncTemp(win, ConfigList = UserConfigList)
	
	MPConfig_DAEphysSettings(win, ConfigList = UserConfigList)
	

	HD_LoadReplaceStimSet()
	
	PGC_SetAndActivateControl(win,"ADC", val = DA_EPHYS_PANEL_DATA_ACQUISITION)
	PGC_SetAndActivateControl(win, "tab_DataAcq_Amp", val = DA_EPHYS_PANEL_VCLAMP)
	PGC_SetAndActivateControl(win, "tab_DataAcq_Pressure", val = DA_EPHYS_PANEL_PRESSURE_AUTO)
	
	filename = GetTimeStamp() + PACKED_FILE_EXPERIMENT_SUFFIX
	NewPath /C/O SavePath, SAVE_PATH
	
	SaveExperiment /P=SavePath as filename
	
	PGC_SetAndActivateControl(win,"StartTestPulseButton")
	
	print ("Start Sciencing")

End		

/// @brief  Open and configure amplifiers for Multi-Patch experiments
///
/// @param panelTitle		Name of ITC device panel
/// @param ConfigList (optional)		List of configurable variables from a configuration NoteBook
/// @param ConfigNB (optional)		Configuration NoteBook to generate list of configureable variabels
///	 One or the other ConfigList or ConfigNB need to be defined
Function MPConfig_Amplifiers(panelTitle, [ConfigList, ConfigNB])
	string panelTitle, ConfigList, ConfigNB
	
	string AmpSerialLocal, AmpTitleLocal, CheckDA, ConnectedAmps
	variable i, ii = 0
	
	if(ParamIsDefault(ConfigList))
		if(ParamIsDefault(ConfigNB))
			ASSERT(0, "Need to provide User Configuration Notebook in order to initialize amplifiers")
		endif
		ConfigList = MPConfig_ImportUserSettings(ConfigNB)
	endif
	
	AmpSerialLocal = ReadConfigList_Textual(AMP_SERIAL,ConfigList)
	AmpTitleLocal = ReadConfigList_Textual(AMP_TITLE,ConfigList)
	
	Assert(AI_OpenMCCs(AmpSerialLocal, ampTitleList = AmpTitleLocal, maxAttempts = ATTEMPTS),"Evil kittens prevented MultiClamp from opening - FULL STOP" ) 
	
	Position_MCC_Win(AmpSerialLocal,AmpTitleLocal)					

	PGC_SetAndActivateControl(panelTitle,"button_Settings_UpdateAmpStatus")
	ConnectedAmps = DAP_GetNiceAmplifierChannelList()
	
	for(i = 0; i<NUM_HEADSTAGES; i+=1)
		
		PGC_SetAndActivateControl(panelTitle,"Popup_Settings_HeadStage", val = i)
		
		if(!mod(i,2)) // even 
			Wave AmpListIndex = FindAmpInList(StringFromList(ii, AmpSerialLocal))
			PGC_SetAndActivateControl(panelTitle,"popup_Settings_Amplifier", val = AmpListIndex[0])
		else //odd
			Wave AmpListIndex = FindAmpInList(StringFromList(ii, AmpSerialLocal))
			PGC_SetAndActivateControl(panelTitle,"popup_Settings_Amplifier", val = AmpListIndex[1])
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
		MCC_InitParams(panelTitle,i)
		PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_HARDWARE)
	endfor
	
	PGC_SetAndActivateControl(panelTitle,"button_Hardware_AutoGainAndUnit")
End
		
/// @brief  Configure pressure devices for Multi-Patch experiments
///
/// @param panelTitle		Name of ITC device panel
/// @param ConfigList (optional)		List of configurable variables from a configuration NoteBook
/// @param ConfigNB (optional)		Configuration NoteBook to generate list of configureable variabels
///	 One or the other ConfigList or ConfigNB need to be defined
Function MPConfig_Pressure(panelTitle, [ConfigList, ConfigNB])
	string panelTitle, ConfigList, ConfigNB
	
	variable i, ii=0, PressDevVal
	string NIDev, PressureDevLocal
	
		
	if(ParamIsDefault(ConfigList))
		if(ParamIsDefault(ConfigNB))
			ASSERT(0, "Need to provide User Configuration Notebook in order to initialize pressure devices")
		endif
		ConfigList = MPConfig_ImportUserSettings(ConfigNB)
	endif
	
	PGC_SetAndActivateControl(panelTitle,"button_Settings_UpdateDACList")
	PressureDevLocal = ReadConfigList_Textual(PRESSURE_DEV, ConfigList)
	NIDev = HW_NI_ListDevices()
	
	for(i = 0; i<NUM_HEADSTAGES; i+=1)
		PressDevVal = WhichListItem(StringFromList(ii,PressureDevLocal),NIDev)
		PGC_SetAndActivateControl(panelTitle,"Popup_Settings_HeadStage", val = i)
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
	endfor
	
	PGC_SetAndActivateControl(panelTitle,"button_Hardware_P_Enable")
	
	WAVE BathPressure = ReadConfigList_Numerical(PRESSURE_BATH, ConfigList)
	WAVE StartSealPressure = ReadConfigList_Numerical(PRESSURE_STARTSEAL, ConfigList)
	WAVE MaxSealPressure = ReadConfigList_Numerical(PRESSURE_MAXSEAL, ConfigList)
	PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_SETTINGS)
	PGC_SetAndActivateControl(panelTitle,"setvar_Settings_InBathP", val = BathPressure[0])  			
	PGC_SetAndActivateControl(panelTitle,"setvar_Settings_SealStartP", val = StartSealPressure[0])		
	PGC_SetAndActivateControl(panelTitle,"setvar_Settings_SealMaxP", val = MaxSealPressure[0])		
	
	// Set pressure calibration values
	WAVE pressureDataWv = P_GetPressureDataWaveRef(panelTitle)
	WAVE PressureConstants = ReadConfigList_Numerical(PRESSURE_CONST,ConfigList)

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
/// @param ConfigList (optional)		List of configurable variables from a configuration NoteBook
/// @param ConfigNB (optional)		Configuration NoteBook to generate list of configureable variabels
///	 One or the other ConfigList or ConfigNB need to be defined		
Function MPConfig_AsyncTemp(panelTitle, [ConfigList, ConfigNB])
	string panelTitle, ConfigList, ConfigNB
	
	if(ParamIsDefault(ConfigList))
		if(ParamIsDefault(ConfigNB))
			ASSERT(0, "Need to provide User Configuration Notebook in order to set asynchronous temperature monitoring")
		endif
		ConfigList = MPConfig_ImportUserSettings(ConfigNB)
	endif
	
	WAVE TempGainLocal = ReadConfigList_Numerical(TEMP_GAIN, ConfigList)
	WAVE TempMaxLocal = ReadConfigList_Numerical(TEMP_MAX, ConfigList)
	WAVE TempMinLocal = ReadConfigList_Numerical(TEMP_MIN, ConfigList)
	PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_ASYNCHRONOUS)		
	PGC_SetAndActivateControl(panelTitle,"SetVar_AsyncAD_Title_00", str = "Set Temperature")
	PGC_SetAndActivateControl(panelTitle,"Check_AsyncAD_00", val = 1)
	PGC_SetAndActivateControl(panelTitle,"Gain_AsyncAD_00", val = TempGainLocal[0])
	PGC_SetAndActivateControl(panelTitle,"Unit_AsyncAD_00", str = "degC")
	PGC_SetAndActivateControl(panelTitle,"SetVar_AsyncAD_Title_01", str = "Bath Temperature")
	PGC_SetAndActivateControl(panelTitle,"Check_AsyncAD_01", val = 1)
	PGC_SetAndActivateControl(panelTitle,"Gain_AsyncAD_01", val = TempGainLocal[0])
	PGC_SetAndActivateControl(panelTitle,"Unit_AsyncAD_01", str = "degC")
	PGC_SetAndActivateControl(panelTitle,"check_AsyncAlarm_01", val = 1)
	PGC_SetAndActivateControl(panelTitle,"max_AsyncAD_01", val = TempMaxLocal[0])
	PGC_SetAndActivateControl(panelTitle,"min_AsyncAD_01", val = TempMinLocal[0])

End

/// @brief  Set user defined experimental parameters
///
/// @param panelTitle		Name of ITC device panel
/// @param ConfigList (optional)		List of configurable variables from a configuration NoteBook
/// @param ConfigNB (optional)		Configuration NoteBook to generate list of configureable variabels
///	 One or the other ConfigList or ConfigNB need to be defined		
Function MPConfig_DAEphysSettings(panelTitle, [ConfigList, ConfigNB])
	string panelTitle, ConfigList, ConfigNB
 	
 	if(ParamIsDefault(ConfigList))
 		if(ParamIsDefault(ConfigNB))
			ASSERT(0, "Need to provide User Configuration Notebook in order to set experimental parameters")
		endif
 		ConfigList = MPConfig_ImportUserSettings(ConfigNB)
 	endif
	PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_SETTINGS)
	PGC_SetAndActivateControl(panelTitle,"check_Settings_TPAfterDAQ", val = ReadConfigList_CheckBox(TP_AFTER_DAQ, ConfigList))
	PGC_SetAndActivateControl(panelTitle,"check_Settings_TP_SaveTPRecord", val = ReadConfigList_CheckBox(SAVE_TP, ConfigList))
	PGC_SetAndActivateControl(panelTitle,"Check_Settings_NwbExport", val = ReadConfigList_CheckBox(EXPORT_NWB, ConfigList))
	PGC_SetAndActivateControl(panelTitle,"Check_Settings_Append", val = ReadConfigList_CheckBox(APPEND_ASYNC, ConfigList))
	PGC_SetAndActivateControl(panelTitle,"check_Settings_SyncMiesToMCC", val = ReadConfigList_CheckBox(SYNC_MIES_MCC, ConfigList))	
	PGC_SetAndActivateControl(panelTitle,"check_Settings_AmpIEQZstep", val = ReadConfigList_CheckBox(ENABLE_I_EQUAL_ZERO, ConfigList))
	PGC_SetAndActivateControl(panelTitle,"ADC", val = DA_EPHYS_PANEL_DATA_ACQUISITION)
	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq1_dDAQOptOv", val = ReadConfigList_CheckBox(ENABLE_OODAQ, ConfigList))
	Wave ooDAQPostDelay = ReadConfigList_Numerical(OODAQ_POST_DELAY, ConfigList)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_dDAQOptOvPost", val = ooDAQPostDelay[0])
	Wave ooDAQResolution = ReadConfigList_Numerical(OODAQ_RESOLUTION, ConfigList)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_dDAQOptOvRes", val = ooDAQResolution[0])
	Wave StimSetRepeats = ReadConfigList_Numerical(NUM_STIM_SETS, ConfigList)
	PGC_SetAndActivateControl(panelTitle,"SetVar_DataAcq_SetRepeats", val = StimSetRepeats[0])
	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq_Get_Set_ITI", val = ReadConfigList_CheckBox(GET_SET_ITI, ConfigList))
	Wave DefaultITI = ReadConfigList_Numerical(DEFAULT_ITI, ConfigList)
	PGC_SetAndActivateControl(panelTitle,"SetVar_DataAcq_ITI", val = DefaultITI[0])
	PGC_SetAndActivateControl(panelTitle,"check_DataACq_Pressure_AutoOFF", val = ReadConfigList_CheckBox(PRESSURE_USER_FOLLOW_HS, ConfigList))	
	PGC_SetAndActivateControl(panelTitle,"check_Settings_UserP_Seal", val = ReadConfigList_CheckBox(PRESSURE_USER_ON_SEAL, ConfigList))
	Wave TPAmp = ReadConfigList_Numerical(TP_AMP_VC, ConfigList)
 	PGC_SetAndActivateControl(panelTitle,"SetVar_DataAcq_TPAmplitude", val = TPAmp[0])
End

/// @brief Intiate MCC parameters for active headstages
///
/// @param panelTitle	ITC device panel
/// @param headStage	Active headstage	 index
Function MCC_InitParams(panelTitle, headStage)
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
Function Position_MCC_Win(serialNum, winTitle)
string serialNum, winTitle
Make /T /FREE winNm
string cmd
variable w

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
Function MPConfig_ClampModes(panelTitle)
	string panelTitle

	// Set initial values for V-Clamp and I-Clamp in MIES
	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq_SendToAllAmp", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(panelTitle,"check_DatAcq_HoldEnableVC", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_Hold_VC", val = -70)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_PipetteOffset_VC", val = 0)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_WCC", val = 0)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_WCR", val = 0)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_RsCorr", val = 0)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_RsPred", val = 0)
	PGC_SetAndActivateControl(panelTitle,"check_DatAcq_HoldEnable", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(panelTitle,"check_DatAcq_BBEnable", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(panelTitle,"check_DatAcq_CNEnable", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_PipetteOffset_IC", val = 0)
	PGC_SetAndActivateControl(panelTitle,"check_DataAcq_AutoBias", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_AutoBiasV", val = -70)
	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq_SendToAllAmp", val = CHECKBOX_UNSELECTED)
	
End

/// @brief Read User_Config NoteBook file and extract parameters as a KeyWordList
///
/// @param UserConfigNB  Name of User Configuration Notebook as a string
/// @return ConfigList   KeyWordList string of configuration parameters to be called by ReadConfigList
Function /S MPConfig_ImportUserSettings(ConfigNB)
	string ConfigNB
	string ConfigList = "", TempText
	variable p = 0
	
	do
		Notebook $ConfigNB selection = {(p,0),(p,0)}
		if(V_flag)
			break
		endif
		
		Notebook $ConfigNB selection = {startOfParagraph, endofChars}
		
		GetSelection notebook, $ConfigNB, 2
		TempText = ""
		TempText = S_Selection
		if(strlen(TempText) > 0)
			if(strlen(ConfigList) == 0)
				ConfigList = TrimString(TempText)
			else
				ConfigList = ConfigList + "/" + TrimString(TempText)
			endif
			
		endif	
		
		p += 1
	
	while(stringmatch(TempText, "!---End of Configuration---"))
	
	return ConfigList
	
End

///@brief Extract parameter values from configuration list that need to be strings
///
///@param KeyWord     Key for the value you wish to extract
///@param ConfigList  KeyWordList generated from ImportUserConfig
///@return Value      Parameter value requested
Function /S ReadConfigList_Textual(KeyWord, ConfigList)
	string KeyWord, ConfigList
	
	string Value
	
	Value = TrimString(StringByKey(Keyword, ConfigList, "=","/"))
	
	if(strlen(Value) == 0)
		string errorMsg
		sprintf errorMsg, "%s has not been set, please enter a value in the Configuration NoteBook", KeyWord 
		ASSERT(strlen(Value) > 0,errorMsg)
	endif
	
	return Value
	
End

///@brief Extract parameter values from configuration list that need to be numerical
///
///@param KeyWord     Key for the value you wish to extract
///@param ConfigList  KeyWordList generated from ImportUserConfig
///@return Value      Parameter value requested as a wave
Function /WAVE ReadConfigList_Numerical(KeyWord, ConfigList)
	string KeyWord, ConfigList
	
	string ItemList
	variable i
	
	ItemList = TrimString(StringByKey(Keyword, ConfigList, "=","/"))
	
	Make /FREE/N = (ItemsInList(ItemList, ";")), Value
	
	for(i=0; i<ItemsInList(ItemList); i+=1)
			Value[i] = str2num(StringFromList(i,ItemList,";"))
			if(numType(Value[i]) != 0)
				string errorMsg
				sprintf errorMsg, "%s has not been set, please enter a value in the Configuration NoteBook", KeyWord 
				ASSERT(numType(Value[i]) == 0,errorMsg)
			endif
	endfor
	
	return Value
	
End

///@brief Extract parameter values from configuration list that interacts with a checkbox
///
///@param KeyWord     Key for the value you wish to extract
///@param ConfigList  KeyWordList generated from ImportUserConfig
///@return Value      Parameter value requested
Function ReadConfigList_CheckBox(KeyWord, ConfigList)
	string KeyWord, ConfigList
	
	variable Value
	string Value_temp
	
	Value_temp = TrimString(StringByKey(Keyword, ConfigList, "=","/"))
	
	if(strlen(Value_temp) == 0)
		string errorMsg
		sprintf errorMsg, "%s has not been set, please enter a value in the Configuration NoteBook", KeyWord 
		ASSERT(strlen(Value_temp) > 0,errorMsg)
	endif
	
	if(StringMatch(Value_temp, "Yes"))
		Value = CHECKBOX_SELECTED
	elseif(StringMatch(Value_temp, "No"))
		Value = CHECKBOX_UNSELECTED
	endif
	
	return Value
	
End

/// @brief Find the list index of a connected amplifier serial number
///
/// @param AmpSerialNum		Amplifier Serial Number to search for
/// @param AmpListIndex		Return a wave of headstage indeces where that serial number is found
Function /WAVE FindAmpInList(AmpSerialNum)
	string AmpSerialNum
	
	string ConnectedAmps, AmpListEntry
	variable AmpSerialIndex, i, ii = 0
	
	ConnectedAmps = DAP_GetNiceAmplifierChannelList()
	Make /FREE/N = 2, AmpListIndex
	
	for(i = 0; i < ItemsInList(ConnectedAmps); i+=1)
		AmpListEntry = StringFromList(i, ConnectedAmps)[6,11]
		if(stringmatch(AmpSerialNum, AmpListEntry))
			AmpListIndex[ii] = i
			ii+=1
		endif
	endfor
		
	return AmpListIndex
	
End