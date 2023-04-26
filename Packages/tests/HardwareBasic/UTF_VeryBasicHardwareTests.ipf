#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=VeryBasicHardwareTesting

static Function CheckInstallation()

	CHECK_EQUAL_VAR(CHI_CheckInstallation(), 0)
End

static Function CheckTestingInstallation()

	string str

	// this function is present in our special UserAnalysisFunctions.ipf
	str = FunctionList("CorrectFileMarker", ";", "")
	REQUIRE_PROPER_STR(str)
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function TestLocking([str])
	string str

	// check that we can gather the device config wave
	KillOrMoveToTrash(dfr = GetDeviceInfoPath())

	try
		CreateLockedDAEphys(str)
		PASS()
	catch
		FAIL()
	endtry
End

// stop testing if the disc is running full
static Function EnsureEnoughDiscSpace()

	PathInfo home
	REQUIRE(V_flag)
	REQUIRE(HasEnoughDiskspaceFree(S_path, MINIMUM_FREE_DISK_SPACE))
End

static Function CheckThatZeroMQMessagingWorks()
	PrepareForPublishTest()
End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckNumberOfRacksAndTTLs([string str])

	variable numRacksRef, numTTLsRef

	WAVE deviceInfo = GetDeviceInfoWave(str)

#ifdef TESTS_WITH_ITC18USB_HARDWARE
	numRacksRef = 1
	numTTlsRef  = 4
#endif

#ifdef TESTS_WITH_ITC1600_HARDWARE
	numRacksRef = 2
	numTTlsRef  = 8
#endif

#ifdef TESTS_WITH_NI_HARDWARE
	numRacksRef = NaN
	numTTlsRef  = 32
#endif

	CHECK_EQUAL_VAR(numRacksRef, deviceInfo[%RACK])
	CHECK_EQUAL_VAR(numTTLsRef, deviceInfo[%TTL])
End

static Function CheckDeviceLists()

	string ITCdevices, NIdevices, ref

	ITCDevices = DAP_GetITCDeviceList()
	NIDevices  = DAP_GetNIDeviceList()

	ref = NONE

#if defined(TESTS_WITH_NI_HARDWARE)
	CHECK_NEQ_STR(NIDevices, ref)
	CHECK_EQUAL_STR(ITCDevices, ref)
#elif defined(TESTS_WITH_ITC18USB_HARDWARE)
	CHECK_NEQ_STR(ITCDevices, ref)
	CHECK_EQUAL_STR(NIDevices, ref)
#elif defined(TESTS_WITH_ITC1600_HARDWARE)
	CHECK_NEQ_STR(ITCDevices, ref)
	CHECK_EQUAL_STR(NIDevices, ref)
#else
	FAIL()
#endif

End

// UTF_TD_GENERATOR DeviceNameGeneratorMD1
static Function CheckGetDeviceInfoValid([string str])

	WAVE/Z wv = GetDeviceInfoWave(str)
	CHECK_WAVE(wv, NORMAL_WAVE | NUMERIC_WAVE)
	CHECK_GT_VAR(wv[%AD], 0)
	CHECK_GT_VAR(wv[%AD], 0)
	CHECK_GT_VAR(wv[%TTL], 0)

#ifdef TESTS_WITH_NI_HARDWARE
	CHECK_EQUAL_VAR(wv[%Rack], NaN)
#else
	CHECK_GE_VAR(wv[%Rack], 0)
#endif

	CHECK_EQUAL_VAR(wv[%HardwareType], GetHardwareType(str))
End

// UTF_TD_GENERATOR NonExistingDevices
static Function CheckGetDeviceInfoWithInvalid([string str])

	WAVE/Z wv = GetDeviceInfoWave(str)
	CHECK_WAVE(wv, NORMAL_WAVE | NUMERIC_WAVE)
	CHECK(!HasOneValidEntry(wv))
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
