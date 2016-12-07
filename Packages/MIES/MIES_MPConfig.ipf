#pragma TextEncoding = "Windows-1252"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

	
Function MultiPatchConfig()

	// Set variables for each rig
//	movewindow /C 1450, 530,-1,-1								// position command window

	string UserConfigList = MPConfig_ImportUserSettings(USER_CONFIG_NB)

	if (windowExists("DA_Ephys")==0 && windowExists("ITC1600_Dev_0")==0)	
		DAP_CreateDAEphysPanel() 									//open DA_Ephys
		movewindow /W = DA_Ephys 1500, -700,-1,-1				//position DA_Ephys window
	endif

	string win = GetMainWindow(GetCurrentWindow())
	
	if (DAP_DeviceIsUnlocked(win) == 1)
		variable ITCDevNum = WhichListItem(ITC_DEV,DEVICE_TYPES) 
		PGC_SetAndActivateControl(win,"popup_MoreSettings_DeviceType", val = ITCDevNum) 
		PGC_SetAndActivateControl(win,"button_SettingsPlus_LockDevice")
	endif	
	
	MPConfig_Amplifiers(win, ConfigList = UserConfigList)
	
	MPConfig_Pressure(win, ConfigList = UserConfigList)
	
	MPConfig_ClampModes(win)
	
	MPConfig_AsyncTemp(win, ConfigList = UserConfigList)
	

	HD_LoadReplaceStimSet()
	
	PGC_SetAndActivateControl(win,"ADC", val = DA_EPHYS_PANEL_DATA_ACQUISITION)
	PGC_SetAndActivateControl(win, "tab_DataAcq_Amp", val = DA_EPHYS_PANEL_VCLAMP)
	PGC_SetAndActivateControl(win, "tab_DataAcq_Pressure", val = DA_EPHYS_PANEL_PRESSURE_AUTO)
	
	string filename = GetTimeStamp() + PACKED_FILE_EXPERIMENT_SUFFIX
	NewPath /C SavePath, SAVE_PATH
	
	SaveExperiment /P=SavePath as filename
	
	PGC_SetAndActivateControl(win,"StartTestPulseButton")
	
	print ("Start Sciencing")

End	
	

// Amplifiers	
Function MPConfig_Amplifiers(panelTitle, [ConfigList])
	string panelTitle, ConfigList
	
	if (ParamIsDefault(ConfigList))
		ConfigList = MPConfig_ImportUserSettings(USER_CONFIG_NB)
	endif
	
	string AmpSerialLocal = ReadConfigList_Textual(AMP_SERIAL,ConfigList)
	string AmpTitleLocal = ReadConfigList_Textual(AMP_TITLE,ConfigList)
	
	Assert(AI_OpenMCCs(AmpSerialLocal, ampTitleList = AmpTitleLocal, maxAttempts = ATTEMPTS),"Evil kittens prevented MultiClamp from opening - FULL STOP" ) // open MCC amps
	
	Position_MCC_Win(AmpSerialLocal,AmpTitleLocal)					// position MCC windows

	PGC_SetAndActivateControl(panelTitle,"button_Settings_UpdateAmpStatus")
	PGC_SetAndActivateControl(panelTitle,"button_Settings_UpdateDACList")
	
	string CheckDA
	variable i
	
	for (i = 0; i<NUM_HEADSTAGES; i+=1)

		PGC_SetAndActivateControl(panelTitle,"Popup_Settings_HeadStage", val = i)
		PGC_SetAndActivateControl(panelTitle,"popup_Settings_Amplifier", val = i +1)
		PGC_SetAndActivateControl(panelTitle,"Popup_Settings_VC_DA", val = i)
		
		if (i>3) 
			PGC_SetAndActivateControl(panelTitle,"Popup_Settings_VC_AD", val = i+4)
			else
			PGC_SetAndActivateControl(panelTitle,"Popup_Settings_VC_AD", val = i)
		endif
		
		CheckDA = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)
		PGC_SetAndActivateControl(panelTitle,CheckDA,val = CHECKBOX_SELECTED)

		MCC_InitParams(panelTitle,i)
	endfor
	
	PGC_SetAndActivateControl(panelTitle,"button_Hardware_AutoGainAndUnit")
End
		
// Pressure regulators
Function MPConfig_Pressure(panelTitle, [ConfigList])
	string panelTitle, ConfigList
	variable i
	variable ii=0

	for (i = 0; i<NUM_HEADSTAGES; i+=1)
		string NIDev = HW_NI_ListDevices()
			variable PressDevVal = WhichListItem(StringFromList(ii,PRESSURE_DEV),NIDev)
			PGC_SetAndActivateControl(panelTitle,"popup_Settings_Pressure_dev", val = PressDevVal+1)
		 
			if (!mod(i,2)) // even
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
	
	if (ParamIsDefault(ConfigList))
		ConfigList = MPConfig_ImportUserSettings(USER_CONFIG_NB)
	endif
	
	WAVE BathPressure = ReadConfigList_Numerical(PRESSURE_BATH, ConfigList)
	WAVE StartSealPressure = ReadConfigList_Numerical(PRESSURE_STARTSEAL, ConfigList)
	WAVE MaxSealPressure = ReadConfigList_Numerical(PRESSURE_MAXSEAL, ConfigList)
	
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
		
Function MPConfig_AsyncTemp(panelTitle, [ConfigList])
	string panelTitle, ConfigList
	
	if (ParamIsDefault(ConfigList))
		ConfigList = MPConfig_ImportUserSettings(USER_CONFIG_NB)
	endif
	
	WAVE TempGainLocal = ReadConfigList_Numerical(TEMP_GAIN, ConfigList)
	WAVE TempMaxLocal = ReadConfigList_Numerical(TEMP_MAX, ConfigList)
	WAVE TempMinLocal = ReadConfigList_Numerical(TEMP_MIN, ConfigList)
			
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
	
	
 Function DAEphysSettings(panelTitle, [ConfigList])
 	string panelTitle, ConfigList
 	
// 	static Constant Yes = CHECKBOX_SELECTED
// 	static Constant No = CHECKBOX_UNSELECTED
 	
 	if (ParamIsDefault(ConfigList))
 		ConfigList = MPConfig_ImportUserSettings(USER_CONFIG_NB)
 	endif
 	
// 	String TPAfterDAQ = ReadConfigList(

	PGC_SetAndActivateControl(panelTitle,"check_Settings_TPAfterDAQ", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(panelTitle,"check_Settings_TP_SaveTPRecord", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(panelTitle,"Check_Settings_NwbExport", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(panelTitle,"Check_Settings_Append", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(panelTitle,"check_Settings_SyncMiesToMCC", val = CHECKBOX_SELECTED)	
	PGC_SetAndActivateControl(panelTitle,"check_Settings_AmpIEQZstep", val = CHECKBOX_SELECTED)
	
	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq1_dDAQOptOv", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_dDAQOptOvPost", val = 150)
	PGC_SetAndActivateControl(panelTitle,"setvar_DataAcq_dDAQOptOvRes", val = 25)
	PGC_SetAndActivateControl(panelTitle,"SetVar_DataAcq_SetRepeats", val = 5)
	PGC_SetAndActivateControl(panelTitle,"SetVar_DataAcq_ITI", val = 15)
	PGC_SetAndActivateControl(panelTitle,"Check_DataAcq_Get_Set_ITI", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(panelTitle,"check_DataACq_Pressure_AutoOFF", val = CHECKBOX_SELECTED)	// User mode WILL NOT follow headstage
	PGC_SetAndActivateControl(panelTitle,"check_Settings_UserP_Seal", val = CHECKBOX_SELECTED)
 PGC_SetAndActivateControl(panelTitle,"SetVar_DataAcq_TPAmplitude", val = -10)
 End
	
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


Function Position_MCC_Win(serialNum, winTitle)

// positions the MCC windows in the upper right monitor use nircmd.exe

string serialNum
string winTitle
Make /T /FREE winNm
string cmd
variable w

	for (w = 0; w<NUM_HEADSTAGES/2; w+=1)
	
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
Function /S MPConfig_ImportUserSettings(UserConfigNB)
	string UserConfigNB
	string ConfigList = "", TempText
	variable p = 0
	
	do
		Notebook $UserConfigNB selection = {(p,0),(p,0)}
		if (V_flag)
			break
		endif
		
		Notebook $UserConfigNB selection = {startOfParagraph, endofChars}
		
		GetSelection notebook, $UserConfigNB, 2
		TempText = ""
		TempText = S_Selection
		if (strlen(TempText) > 0)
			if (strlen(ConfigList) == 0)
				ConfigList = TrimString(TempText)
			else
				ConfigList = ConfigList + "/" + TrimString(TempText)
			endif
			
		endif	
		
		p += 1
	
	while (stringmatch(TempText, "!---End of Configuration---"))
	
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
	
	Value = StringByKey(Keyword, ConfigList, "=","/")
	
	if (strlen(Value) == 0)
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
	
	ItemList = StringByKey(Keyword, ConfigList, "=","/")
	
	Make /FREE/N = (ItemsInList(ItemList, ";")), Value
	
	variable i
	for (i=0; i<ItemsInList(ItemList); i+=1)
			Value[i] = str2num(StringFromList(i,ItemList,";"))
			if (numType(Value[i]) != 0)
				string errorMsg
				sprintf errorMsg, "%s has not been set, please enter a value in the Configuration NoteBook", KeyWord 
				ASSERT(numType(Value[i]) == 0,errorMsg)
			endif
	endfor
	
	return Value
	
End