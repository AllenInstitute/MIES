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

	CONF_RestoreWindow(rewrittenConfig, usePanelTypeFromFile=1)

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
