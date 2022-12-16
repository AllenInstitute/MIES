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
