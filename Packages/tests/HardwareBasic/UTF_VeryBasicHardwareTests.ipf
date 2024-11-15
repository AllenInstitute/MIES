#pragma TextEncoding="UTF-8"
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
static Function TestLocking([string str])

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

#ifdef TESTS_WITH_SUTTER_HARDWARE
	numRacksRef = NaN
	numTTlsRef  = 8
#endif

	CHECK_EQUAL_VAR(numRacksRef, deviceInfo[%RACK])
	CHECK_EQUAL_VAR(numTTLsRef, deviceInfo[%TTL])
End

static Function CheckDeviceLists()

	string ITCdevices, NIdevices, SUdevices, ref

	ITCDevices = DAP_GetITCDeviceList()
	NIDevices  = DAP_GetNIDeviceList()
	SUDevices  = DAP_GetSUDeviceList()

	ref = NONE

#if defined(TESTS_WITH_NI_HARDWARE)
	CHECK_NEQ_STR(NIDevices, ref)
	CHECK_EQUAL_STR(ITCDevices, ref)
	CHECK_EQUAL_STR(SUDevices, ref)
#elif defined(TESTS_WITH_ITC18USB_HARDWARE)
	CHECK_NEQ_STR(ITCDevices, ref)
	CHECK_EQUAL_STR(NIDevices, ref)
	CHECK_EQUAL_STR(SUDevices, ref)
#elif defined(TESTS_WITH_ITC1600_HARDWARE)
	CHECK_NEQ_STR(ITCDevices, ref)
	CHECK_EQUAL_STR(NIDevices, ref)
	CHECK_EQUAL_STR(SUDevices, ref)
#elif defined(TESTS_WITH_SUTTER_HARDWARE)
	CHECK_NEQ_STR(SUDevices, ref)
	CHECK_EQUAL_STR(NIDevices, ref)
	CHECK_EQUAL_STR(ITCDevices, ref)
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
#ifdef TESTS_WITH_SUTTER_HARDWARE
	CHECK_EQUAL_VAR(wv[%Rack], NaN)
#else
	CHECK_GE_VAR(wv[%Rack], 0)
#endif
#endif

	CHECK_EQUAL_VAR(wv[%HardwareType], GetHardwareType(str))
End

// UTF_TD_GENERATOR NonExistingDevices
static Function CheckGetDeviceInfoWithInvalid([string str])

	WAVE/Z wv = GetDeviceInfoWave(str)
	CHECK_WAVE(wv, NORMAL_WAVE | NUMERIC_WAVE)
	CHECK(!HasOneValidEntry(wv))
End
