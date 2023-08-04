#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=ConfigurationHardwareTesting

static StrConstant REF_DAEPHYS_CONFIG_FILE = "DA_Ephys.json"

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function RestoreDAEphysPanel([str])
	string str

	string fName, rewrittenConfigPath
	variable jsonID

	fName = PrependExperimentFolder_IGNORE(REF_DAEPHYS_CONFIG_FILE)

	[jsonID, rewrittenConfigPath] = FixupJSONConfig_IGNORE(fName, str)

	CONF_RestoreDAEphys(jsonID, rewrittenConfigPath)
	MIES_CONF#CONF_SaveDAEphys(fname)

	CONF_RestoreDAEphys(jsonID, rewrittenConfigPath, middleOfExperiment = 1)
	MIES_CONF#CONF_SaveDAEphys(fname)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function RestoreAndSaveConfiguration([string str])

	string settingsIPath, settingsFolder, templateFolder, workingFolder
	string fileList, fName, fContent, fContentRig, wList
	variable jsonId
	string templateIPath = "templateConf"
	string tempIPath = "tempConf"
	string defaultConfig = "1_DA_Ephys.json"
	string defaultRigConfig = "1_DA_Ephys_rig.json"
	string newConfig = "1_DA_Ephys_new.json"
	string newRigConfig = "1_DA_Ephys_new_rig.json"
	string stimsetJsonPath = "/Common configuration data/Stim set file name"
	string hsAssocJsonPath = "/Common configuration data/Headstage Association"

	settingsIPath = MIES_CONF#CONF_GetSettingsPath(0x0)
	PathInfo $settingsIPath
	settingsFolder = S_Path
	templateFolder = GetFolder(settingsFolder) + "Settings_template"

	workingFolder = GetFolder(settingsFolder) + UniqueFileOrFolder(settingsIPath, "RestoreAndSaveConfigurationTest")
	CreateFolderOnDisk(workingFolder)
	workingFolder += ":"
	NewPath/O/Q $tempIPath, workingFolder

	NewPath/O/Q $templateIPath, templateFolder
	fileList = GetAllFilesRecursivelyFromPath(templateIPath, extension = ".json")
	WAVE/T wFileList = ListToTextWave(fileList, "|")
	for(fileName : wFileList)
		[fContent, fName] = LoadTextFile(fileName)
		jsonId = JSON_Parse(fContent)

		if(JSON_Exists(jsonId, stimsetJsonPath))
			FixupJSONConfigImplMain(jsonId, str)
			fContent = JSON_Dump(jsonId, indent=2)
		elseif(JSON_Exists(jsonId, hsAssocJsonPath))
			FixupJSONConfigImplRig(jsonId)
			fContent = JSON_Dump(jsonId, indent=2)
		endif
		JSON_Release(jsonId)
		SaveTextFile(fContent, workingFolder + GetFile(fileName))
	endfor

	CONF_AutoLoader(customIPath=tempIPath)
	CHECK(WindowExists(DATABROWSER_WINDOW_NAME))
	CHECK(WindowExists(str))

	DoWindow/F $str
	CONF_SaveWindow("")
	CHECK(FileExists(workingFolder + newConfig))
	CHECK(FileExists(workingFolder + newRigConfig))

	[fContent, fName] = LoadTextFile(workingFolder + defaultRigConfig)
	[fContentRig, fName] = LoadTextFile(workingFolder + newRigConfig)
	CHECK_EQUAL_STR(fContent, fContentRig)

	wList = AddListItem(DATABROWSER_WINDOW_NAME, "")
	wList = AddListItem(str, wList)
	KillWindows(wList)

	fName = workingFolder + defaultRigConfig
	DeleteFile fName
	fName = workingFolder + defaultConfig
	DeleteFile fName

	CONF_AutoLoader(customIPath=tempIPath)
	CHECK(WindowExists(DATABROWSER_WINDOW_NAME))
	CHECK(WindowExists(str))

	fName = workingFolder + newRigConfig
	DeleteFile fName
	fName = workingFolder + newConfig
	DeleteFile fName
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckIfConfigurationRestoresMCCFilterGain([string str])

	string rewrittenConfig, fName
	variable val, gain, filterFreq, headStage, jsonID

	fName = PrependExperimentFolder_IGNORE("CheckIfConfigurationRestoresMCCFilterGain.json")

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG1_DAQ0_TP0"                 + \
										"__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:"  + \
										"__HS1_DA1_AD1_CM:IC:_ST:StimulusSetB_DA_0:")

	AcquireData_NG(s, str)

	gain = 5
	filterFreq = 6
	AI_SendToAmp(str, headStage, V_CLAMP_MODE, MCC_SETPRIMARYSIGNALLPF_FUNC, filterFreq)
	AI_SendToAmp(str, headStage, V_CLAMP_MODE, MCC_SETPRIMARYSIGNALGAIN_FUNC, gain)
	AI_SendToAmp(str, headStage + 1, I_CLAMP_MODE, MCC_SETPRIMARYSIGNALLPF_FUNC, filterFreq)
	AI_SendToAmp(str, headStage + 1, I_CLAMP_MODE, MCC_SETPRIMARYSIGNALGAIN_FUNC, gain)

	PGC_SetAndActivateControl(str, "check_Settings_SyncMiesToMCC", val=1)

	CONF_SaveWindow(fName)

	[jsonID, rewrittenConfig] = FixupJSONConfig_IGNORE(fName, str)
	JSON_Release(jsonID)

	gain = 1
	filterFreq = 2
	AI_SendToAmp(str, headStage, V_CLAMP_MODE, MCC_SETPRIMARYSIGNALLPF_FUNC, filterFreq)
	AI_SendToAmp(str, headStage, V_CLAMP_MODE, MCC_SETPRIMARYSIGNALGAIN_FUNC, gain)
	AI_SendToAmp(str, headStage + 1, I_CLAMP_MODE, MCC_SETPRIMARYSIGNALLPF_FUNC, filterFreq)
	AI_SendToAmp(str, headStage + 1, I_CLAMP_MODE, MCC_SETPRIMARYSIGNALGAIN_FUNC, gain)

	KillWindow $str

	CONF_RestoreWindow(rewrittenConfig)

	gain = 5
	filterFreq = 6
	val = AI_SendToAmp(str, headStage, V_CLAMP_MODE, MCC_GETPRIMARYSIGNALLPF_FUNC, NaN)
	CHECK_EQUAL_VAR(val, filterFreq)
	val = AI_SendToAmp(str, headStage, V_CLAMP_MODE, MCC_GETPRIMARYSIGNALGAIN_FUNC, NaN)
	CHECK_EQUAL_VAR(val, gain)
	val = AI_SendToAmp(str, headStage + 1, I_CLAMP_MODE, MCC_GETPRIMARYSIGNALLPF_FUNC, NaN)
	CHECK_EQUAL_VAR(val, filterFreq)
	val = AI_SendToAmp(str, headStage + 1, I_CLAMP_MODE, MCC_GETPRIMARYSIGNALGAIN_FUNC, NaN)
	CHECK_EQUAL_VAR(val, gain)
End

/// @brief Checks if every typed panel restores with auto opening
///
/// IUTF_TD_GENERATOR s0:GetMiesMacrosWithPanelType
/// IUTF_TD_GENERATOR s1:DeviceNameGenerator
static Function TCONF_CheckTypedPanelRestore([STRUCT IUTF_mData &md])

	string win, winRestored
	string fName = GetFolder(FunctionPath("")) + "CheckTypedPanelRestore.json"

	Execute/Q md.s0 + "()"
	win = WinName(0, -1)
	if(!CmpStr(win, BASE_WINDOW_NAME))
		// special handling for DAEphys
		KillWindow $win
		CreateLockedDAEphys(md.s1)
		win = WinName(0, -1)
		PGC_SetAndActivateControl(win, "check_Settings_RequireAmpConn", val=0)
		PGC_SetAndActivateControl(win, "Check_DataAcqHS_00",val=1)
		PGC_SetAndActivateControl(win, "Gain_DA_00",val=20)
		PGC_SetAndActivateControl(win, "setvar_Settings_VC_DAgain",val=20)
		PGC_SetAndActivateControl(win, "Gain_AD_00",val=0.0025)
		PGC_SetAndActivateControl(win, "setvar_Settings_VC_ADgain",val=0.0025)
	endif
	CONF_SaveWindow(fName)
	KillWindow $win
	CONF_RestoreWindow(fName)
	winRestored = WinName(0, -1)
	DeleteFile fName
	CHECK_EQUAL_STR(win, winRestored)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckIfConfigurationRestoresDAEphysWithUnassocDA([string str])

	string rewrittenConfig, fName
	variable hardwareType, jsonID, numRacks, DAState

	fName = PrependExperimentFolder_IGNORE("CheckIfConfigurationRestoresDAEphysWithUnassocDA.json")

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                         + \
								 "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:"      + \
								 "__HS1_DA1_AD1_CM:VC:_ST:StimulusSetC_DA_0:_ASO0" + \
								 "__HS2_DA2_AD2_CM:VC:_ST:StimulusSetA_DA_0:_ASO0" + \
								 "__TTL1_ST:StimulusSetA_TTL_0:"                   + \
								 "__TTL3_ST:StimulusSetB_TTL_0:"                   + \
								 "__TTL5_ST:StimulusSetA_TTL_0:"                   + \
								 "__TTL7_ST:StimulusSetB_TTL_0:")

	AcquireData_NG(s, str)

	CONF_SaveWindow(fName)

	[jsonID, rewrittenConfig] = FixupJSONConfig_IGNORE(fName, str)
	JSON_Release(jsonID)

	KillWindow $str
	KillOrMoveToTrash(dfr=root:MIES)

	CONF_RestoreWindow(rewrittenConfig)
	PGC_SetAndActivateControl(str, "StartTestPulseButton")

	WAVE DACState = DAG_GetChannelState(str, CHANNEL_TYPE_DAC)
	CHECK_EQUAL_WAVES(DACState, {1, 1, 1, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE ADCState = DAG_GetChannelState(str, CHANNEL_TYPE_ADC)
	CHECK_EQUAL_WAVES(ADCState, {1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE TTLState = DAG_GetChannelState(str, CHANNEL_TYPE_TTL)
	hardwareType = GetHardwareType(str)
	if(hardwareType == HARDWARE_ITC_DAC)
		numRacks = HW_ITC_GetNumberOfRacks(str)
		if(numRacks == 2)
			CHECK_EQUAL_WAVES(TTLState, {0, 1, 0, 1, 0, 1, 0, 1}, mode = WAVE_DATA)
		else
			CHECK_EQUAL_WAVES(TTLState, {0, 1, 0, 1, 0, 0, 0, 0}, mode = WAVE_DATA)
		endif
	elseif(hardwareType == HARDWARE_NI_DAC)
		CHECK_EQUAL_WAVES(TTLState, {0, 1, 0, 1, 0, 1, 0, 1}, mode = WAVE_DATA)
	else
		FAIL()
	endif

	WAVE HSState = DAG_GetChannelState(str, CHANNEL_TYPE_HEADSTAGE)
	CHECK_EQUAL_WAVES(HSState, {1, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	// switch off unassoc DA channels
	PGC_SetAndActivateControl(str, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK), val = 0)
	PGC_SetAndActivateControl(str, GetPanelControl(2, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK), val = 0)

	// switch on HS1, then if correctly unassoc, DA1 must stay off
	PGC_SetAndActivateControl(str, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 1)
	DAState = GetCheckBoxState(str, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK))
	CHECK_EQUAL_VAR(DAState, 0)

	PGC_SetAndActivateControl(str, GetPanelControl(2, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val = 1)
	DAState = GetCheckBoxState(str, GetPanelControl(2, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_CHECK))
	CHECK_EQUAL_VAR(DAState, 0)
End

static Function CheckIfConfigurationRestoresDAEphysWithoutAmp_PreAcq(device)
	string device

	string hs1Ctrl
	string unit = "testunit"
	variable gain = 19

	PGC_SetAndActivateControl(device, "check_Settings_RequireAmpConn", val = 0)
	PGC_SetAndActivateControl(device, "Popup_Settings_HeadStage", str = "1")
	PGC_SetAndActivateControl(device, "popup_Settings_Amplifier", str = NONE)
	PGC_SetAndActivateControl(device, "SetVar_Hardware_VC_DA_Unit", str = unit)
	PGC_SetAndActivateControl(device, "SetVar_Hardware_VC_AD_Unit", str = unit)
	PGC_SetAndActivateControl(device, "SetVar_Hardware_IC_DA_Unit", str = unit)
	PGC_SetAndActivateControl(device, "SetVar_Hardware_IC_AD_Unit", str = unit)
	PGC_SetAndActivateControl(device, "setvar_Settings_VC_DAgain", val = gain)
	PGC_SetAndActivateControl(device, "setvar_Settings_VC_ADgain", val = gain)
	PGC_SetAndActivateControl(device, "setvar_Settings_IC_DAgain", val = gain)
	PGC_SetAndActivateControl(device, "setvar_Settings_IC_ADgain", val = gain)
	hs1Ctrl = GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
	PGC_SetAndActivateControl(device, hs1Ctrl, val = 0)
	PGC_SetAndActivateControl(device, hs1Ctrl, val = 1)

	PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = 1)
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_TPAmplitude", val = 9.5)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckIfConfigurationRestoresDAEphysWithoutAmp([string str])

	string rewrittenConfig, fName
	variable jsonID

	fName = PrependExperimentFolder_IGNORE("CheckIfConfigurationRestoresDAEphysWithoutAmp.json")

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1"                         + \
								 "__HS0_DA3_AD2_CM:VC:_ST:StimulusSetA_DA_0:"      + \
								 "__HS1_DA1_AD0_CM:VC:_ST:StimulusSetC_DA_0:"      + \
								 "__HS2_DA2_AD1_CM:VC:_ST:StimulusSetA_DA_0:_ASO0")

	AcquireData_NG(s, str)

	CONF_SaveWindow(fName)

	[jsonID, rewrittenConfig] = FixupJSONConfig_IGNORE(fName, str)
	JSON_Release(jsonID)

	KillWindow $str
	KillOrMoveToTrash(dfr=root:MIES)

	CONF_RestoreWindow(rewrittenConfig)
	CtrlNamedBackGround StopTPAfterFiveSeconds, start=(ticks + TP_DURATION_S * 60), period=1, proc=StopTPAfterFiveSeconds_IGNORE
End

static Function CheckIfConfigurationRestoresDAEphysWithoutAmp_REENTRY([string str])

	WAVE/Z numericalValues = GetLBNumericalValues(str)
	CHECK_WAVE(numericalValues, NUMERIC_WAVE)
	WAVE/Z DACs = GetLastSetting(numericalValues, NaN, "DAC", TEST_PULSE_MODE)
	WAVE DACRef = LBN_GetNumericWave(defValue = NaN)
	DACRef[0] = 3
	DACRef[1] = 1
	CHECK_EQUAL_WAVES(DACs, DACRef, mode = WAVE_DATA)
	WAVE/Z ADCs = GetLastSetting(numericalValues, NaN, "ADC", TEST_PULSE_MODE)
	WAVE ADCRef = LBN_GetNumericWave(defValue = NaN)
	ADCRef[0] = 2
	ADCRef[1] = 0
	CHECK_EQUAL_WAVES(ADCs, ADCRef, mode = WAVE_DATA)

	PGC_SetAndActivateControl(str, "DataAcquireButton")
	RegisterReentryFunction("ConfigurationHardwareTesting#CheckIfConfigurationRestoresDAEphysWithoutAmp2")
End

static Function CheckIfConfigurationRestoresDAEphysWithoutAmp2_REENTRY([string str])

	variable sweepNo = 0
	string strTmp

	WAVE/Z numericalValues = GetLBNumericalValues(str)
	CHECK_WAVE(numericalValues, NUMERIC_WAVE)
	WAVE/Z/T textualValues = GetLBTextualValues(str)
	CHECK_WAVE(textualValues, TEXT_WAVE)

	WAVE/Z/T ADUnit = GetLastSetting(textualValues, sweepNo, "AD Unit", DATA_ACQUISITION_MODE)
	WAVE/T ADUnitRef = LBN_GetTextWave()
	ADUnitRef[0] = "pA"
	ADUnitRef[1] = "testunit"
	CHECK_EQUAL_WAVES(ADUnit, ADUnitRef, mode = WAVE_DATA)

	WAVE/Z/T DAUnit = GetLastSetting(textualValues, sweepNo, "DA Unit", DATA_ACQUISITION_MODE)
	WAVE/T DAUnitRef = LBN_GetTextWave()
	DAUnitRef[0] = "mV"
	DAUnitRef[1] = "testunit"
	CHECK_EQUAL_WAVES(DAUnit, DAUnitRef, mode = WAVE_DATA)

	WAVE/Z ADGain = GetLastSetting(numericalValues, sweepNo, "AD Gain", DATA_ACQUISITION_MODE)
	WAVE ADGainRef = LBN_GetNumericWave(defValue = NaN)
	ADGainRef[0] = 0.0025
	ADGainRef[1] = 19
	CHECK_EQUAL_WAVES(ADGain, ADGainRef, mode = WAVE_DATA)

	WAVE/Z DAGain = GetLastSetting(numericalValues, sweepNo, "DA Gain", DATA_ACQUISITION_MODE)
	WAVE DAGainRef = LBN_GetNumericWave(defValue = NaN)
	DAGainRef[0] = 20
	DAGainRef[1] = 19
	CHECK_EQUAL_WAVES(DAGain, DAGainRef, mode = WAVE_DATA)

	WAVE/Z serialNum = GetLastSetting(numericalValues, sweepNo, "Serial Number", DATA_ACQUISITION_MODE)
	CHECK_WAVE(serialNum, NUMERIC_WAVE)
	CHECK(IsFinite(serialNum[0]))
	CHECK_EQUAL_VAR(serialNum[1], NaN)

	WAVE/Z channelID = GetLastSetting(numericalValues, sweepNo, "Channel ID", DATA_ACQUISITION_MODE)
	CHECK_WAVE(channelID, NUMERIC_WAVE)
	CHECK(IsFinite(channelID[0]))
	CHECK_EQUAL_VAR(channelID[1], NaN)

	WAVE/Z/T hwTypeString = GetLastSetting(textualValues, sweepNo, "HardwareTypeString", DATA_ACQUISITION_MODE)
	CHECK_WAVE(hwTypeString, TEXT_WAVE)
	strTmp = hwTypeString[0]
	CHECK_PROPER_STR(strTmp)
	CHECK_EQUAL_STR(hwTypeString[1], "")
End
