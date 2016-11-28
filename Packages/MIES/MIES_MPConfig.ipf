#pragma TextEncoding = "Windows-1252"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.



static strConstant AMP_SERIAL = "836760;836761;836782;836783" 	// Serial numbers of amps in proper order
static strConstant AMP_TITLE = "0,1;2,3;4,5;6,7" 					// names you want to give the amps
static Constant ATTEMPTS = 5 												// number of attempts to open MCC
static strConstant ITC_DEV = "ITC1600" 								// name of ITC device
static strConstant PRESSURE_DEV = "Dev6;Dev7;Dev2;Dev1"				// Device numbers of pressure control boxes (2 headstages/device)
static Constant TEMP_GAIN = 0.01											// Gain for Asynchronous Temperature input
static Constant TEMP_MAX = 34												// Max limit for Asynchronous Temperature alarm
static Constant TEMP_MIN = -1												// Min limit for Asynchrounous Temperature alarm
static strConstant SAVE_PATH = "C:Users:stephanies:Desktop:MiesSave"		// Default path to store MIES experiments
	
Function MultiPatchConfig()
	// Set variables for each rig
	movewindow /C 1450, 530,-1,-1								// position command window
	
	// Configure MIES Start-up

	Assert(AI_OpenMCCs(AMP_SERIAL, ampTitleList = AMP_TITLE, maxAttempts = ATTEMPTS),"Evil kittens prevented MultiClamp from opening - FULL STOP" ) // open MCC amps
	
	Position_MCC_Win(AMP_SERIAL,AMP_TITLE)					// position MCC windows

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

	// Configure headstage amplifier and pressure associations

	win = GetMainWindow(GetCurrentWindow())

	PGC_SetAndActivateControl(win,"button_Settings_UpdateAmpStatus")
	PGC_SetAndActivateControl(win,"button_Settings_UpdateDACList")
	string CheckDA 
	variable i
	variable ii=0
	
	for (i = 0; i<NUM_HEADSTAGES; i+=1)

		PGC_SetAndActivateControl(win,"Popup_Settings_HeadStage", val = i)
		PGC_SetAndActivateControl(win,"popup_Settings_Amplifier", val = i +1)
		PGC_SetAndActivateControl(win,"Popup_Settings_VC_DA", val = i)
		
		if (i>3) 
			PGC_SetAndActivateControl(win,"Popup_Settings_VC_AD", val = i+4)
			else
			PGC_SetAndActivateControl(win,"Popup_Settings_VC_AD", val = i)
		endif
		
		CheckDA = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK)
		PGC_SetAndActivateControl(win,CheckDA,val = 1)

		
		
		// Pressure regulators 
		
		string NIDev = HW_NI_ListDevices()
		variable PressDevVal = WhichListItem(StringFromList(ii,PRESSURE_DEV),NIDev)
		PGC_SetAndActivateControl(win,"popup_Settings_Pressure_dev", val = PressDevVal+1)
		 
		if (!mod(i,2)) // even
			PGC_SetAndActivateControl(win,"Popup_Settings_Pressure_DA", val = 0)
			PGC_SetAndActivateControl(win,"Popup_Settings_Pressure_AD", val = 0)
			PGC_SetAndActivateControl(win,"Popup_Settings_Pressure_TTLA", val = 1)
			PGC_SetAndActivateControl(win,"Popup_Settings_Pressure_TTLB", val = 2)
		else // odd
			PGC_SetAndActivateControl(win,"Popup_Settings_Pressure_DA", val = 1)
			PGC_SetAndActivateControl(win,"Popup_Settings_Pressure_AD", val = 1)
			PGC_SetAndActivateControl(win,"Popup_Settings_Pressure_TTLA", val = 3)
			PGC_SetAndActivateControl(win,"Popup_Settings_Pressure_TTLB", val = 4)
			ii+= 1
		endif		

	MCC_InitParams(win,i)

	endfor
	
	PGC_SetAndActivateControl(win,"button_Hardware_AutoGainAndUnit")
	PGC_SetAndActivateControl(win,"button_Hardware_P_Enable")
	PGC_SetAndActivateControl(win,"check_Settings_TPAfterDAQ", val = 1)
	PGC_SetAndActivateControl(win,"check_Settings_TP_SaveTPRecord", val = 1)
	PGC_SetAndActivateControl(win,"Check_Settings_NwbExport", val = 1)
	PGC_SetAndActivateControl(win,"Check_Settings_Append", val = 1)
	PGC_SetAndActivateControl(win,"check_Settings_SyncMiesToMCC", val = 1)	
	PGC_SetAndActivateControl(win,"check_Settings_AmpIEQZstep", val = 1)
	PGC_SetAndActivateControl(win,"setvar_Settings_InBathP", val = 0.5)  			// set approach positive pressure to 1 psi
	PGC_SetAndActivateControl(win,"setvar_Settings_SealStartP", val = -0.1)		// set initial seal pressure to -0.1 psi
	PGC_SetAndActivateControl(win,"setvar_Settings_SealMaxP", val = -1.4)		// set max seal pressure to -1.4 psi
	PGC_SetAndActivateControl(win,"Check_DataAcq1_dDAQOptOv", val = 1)
	PGC_SetAndActivateControl(win,"setvar_DataAcq_dDAQOptOvPost", val = 150)
	PGC_SetAndActivateControl(win,"setvar_DataAcq_dDAQOptOvRes", val = 25)
	PGC_SetAndActivateControl(win,"SetVar_DataAcq_SetRepeats", val = 5)
	PGC_SetAndActivateControl(win,"SetVar_DataAcq_ITI", val = 15)
	PGC_SetAndActivateControl(win,"Check_DataAcq_Get_Set_ITI", val = 0)
	PGC_SetAndActivateControl(win,"check_DataACq_Pressure_AutoOFF", val = 1)	// User mode WILL NOT follow headstage
	PGC_SetAndActivateControl(win,"check_Settings_UserP_Seal", val = 1)
	
	//Asynchronous Temperature input
	PGC_SetAndActivateControl(win,"SetVar_AsyncAD_Title_00", str = "Set Temperature")
	PGC_SetAndActivateControl(win,"Check_AsyncAD_00", val = 1)
	PGC_SetAndActivateControl(win,"Gain_AsyncAD_00", val = TEMP_GAIN)
	PGC_SetAndActivateControl(win,"Unit_AsyncAD_00", str = "degC")
	PGC_SetAndActivateControl(win,"SetVar_AsyncAD_Title_01", str = "Bath Temperature")
	PGC_SetAndActivateControl(win,"Check_AsyncAD_01", val = 1)
	PGC_SetAndActivateControl(win,"Gain_AsyncAD_01", val = TEMP_GAIN)
	PGC_SetAndActivateControl(win,"Unit_AsyncAD_01", str = "degC")
	PGC_SetAndActivateControl(win,"check_AsyncAlarm_01", val = 1)
	PGC_SetAndActivateControl(win,"max_AsyncAD_01", val = TEMP_MAX)
	PGC_SetAndActivateControl(win,"min_AsyncAD_01", val = TEMP_MIN)
	
	
	// Set initial values for V-Clamp and I-Clamp in MIES
	PGC_SetAndActivateControl(win,"Check_DataAcq_SendToAllAmp", val = 1)
	PGC_SetAndActivateControl(win,"check_DatAcq_HoldEnableVC", val = 0)
	PGC_SetAndActivateControl(win,"setvar_DataAcq_Hold_VC", val = -70)
	PGC_SetAndActivateControl(win,"setvar_DataAcq_PipetteOffset_VC", val = 0)
	PGC_SetAndActivateControl(win,"setvar_DataAcq_WCC", val = 0)
	PGC_SetAndActivateControl(win,"setvar_DataAcq_WCR", val = 0)
	PGC_SetAndActivateControl(win,"setvar_DataAcq_RsCorr", val = 0)
	PGC_SetAndActivateControl(win,"setvar_DataAcq_RsPred", val = 0)
	PGC_SetAndActivateControl(win,"check_DatAcq_HoldEnable", val = 0)
	PGC_SetAndActivateControl(win,"check_DatAcq_BBEnable", val = 0)
	PGC_SetAndActivateControl(win,"check_DatAcq_CNEnable", val = 0)
	PGC_SetAndActivateControl(win,"setvar_DataAcq_PipetteOffset_IC", val = 0)
	PGC_SetAndActivateControl(win,"check_DataAcq_AutoBias", val = 0)
	PGC_SetAndActivateControl(win,"setvar_DataAcq_PipetteOffset_IC", val = -70)
	PGC_SetAndActivateControl(win,"Check_DataAcq_SendToAllAmp", val = 0)
	
	// Set pressure calibration values
	WAVE pressureDataWv = P_GetPressureDataWaveRef(win)

	pressureDataWv[%headStage_0][%PosCalConst] = 0.04
	pressureDataWv[%headStage_1][%PosCalConst] = 0.14
	pressureDataWv[%headStage_2][%PosCalConst] = 0.05
	pressureDataWv[%headStage_3][%PosCalConst] = 0.14
	pressureDataWv[%headStage_4][%PosCalConst] = 0.29
	pressureDataWv[%headStage_5][%PosCalConst] = 0.03
	pressureDataWv[%headStage_6][%PosCalConst] = 0.05
	pressureDataWv[%headStage_7][%PosCalConst] = 0.045

	pressureDataWv[%headStage_0][%NegCalConst] = -0.04
	pressureDataWv[%headStage_1][%NegCalConst] = -0.14
	pressureDataWv[%headStage_2][%NegCalConst] = -0.05
	pressureDataWv[%headStage_3][%NegCalConst] = -0.14
	pressureDataWv[%headStage_4][%NegCalConst] = -0.29
	pressureDataWv[%headStage_5][%NegCalConst] = -0.03
	pressureDataWv[%headStage_6][%NegCalConst] = -0.05
	pressureDataWv[%headStage_7][%NegCalConst] = -0.045
	
	
	HD_LoadReplaceStimSet()
	
	PGC_SetAndActivateControl(win,"SetVar_DataAcq_TPAmplitude", val = -10)
	
	PGC_SetAndActivateControl(win,"ADC", val = 0)										// go to Data Acquisition tab
	
	string filename = GetTimeStamp() + PACKED_FILE_EXPERIMENT_SUFFIX
	NewPath /C SavePath, SAVE_PATH
	
	SaveExperiment /P=SavePath as filename
	
	PGC_SetAndActivateControl(win,"StartTestPulseButton")
	
	print ("Start Sciencing")

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

