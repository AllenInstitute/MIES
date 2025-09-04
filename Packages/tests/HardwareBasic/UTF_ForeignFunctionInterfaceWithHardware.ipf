#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = ForeignFunctionInterfaceWithHW

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function HardwareSelectionWorks([STRUCT IUTF_MDATA &md])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_TP0_DAQ0"             + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	AcquireData_NG(s, md.s0)
End

static Function HardwareSelectionWorks_REENTRY([STRUCT IUTF_MDATA &md])

	string device = md.s0

	CHECK(MIES_FFI#FFI_TP_DeviceSelectable(md.s0))

	PGC_SetAndActivateControl(device, "button_SettingsPlus_unLockDevic")

	// non-available device
	CHECK(!MIES_FFI#FFI_TP_DeviceSelectable("ITC16USB_Dev_1"))
End

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function StartingStoppingTestPulseWorks([STRUCT IUTF_MDATA &md])

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA0_I0_L0_BKG1_TP0_DAQ0"             + \
	                             "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	AcquireData_NG(s, md.s0)
End

static Function StartingStoppingTestPulseWorks_REENTRY([STRUCT IUTF_MDATA &md])

	string device = md.s0
	string   errorMsg
	variable ret

	CHECK_EQUAL_VAR(RoVar(GetTestpulseRunMode(device)), TEST_PULSE_NOT_RUNNING)

	[ret, errorMsg] = FFI_StopTestPulse(device)
	CHECK_EQUAL_VAR(ret, 1)
	CHECK(GrepString(errorMsg, "Test pulse already stopped on .*; stop ignored.\r"))

	[ret, errorMsg] = FFI_StopTestPulse("ITC16USB_Dev_1")
	CHECK_EQUAL_VAR(ret, -1)
	CHECK(GrepString(errorMsg, "Device .* is not available.\r"))

	[ret, errorMsg] = FFI_StartTestPulse(device)
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EMPTY_STR(errorMsg)

	// The testpulse is already running altough the osciolloscope is not updated
	// but this is enough for us

	[ret, errorMsg] = FFI_StartTestPulse("ITC16USB_Dev_1")
	CHECK_EQUAL_VAR(ret, -1)
	CHECK(GrepString(errorMsg, "Device .* is not available.\r"))

	CHECK_EQUAL_VAR(RoVar(GetTestpulseRunMode(device)), TEST_PULSE_BG_MULTI_DEVICE)

	[ret, errorMsg] = FFI_StartTestPulse(device)
	CHECK_EQUAL_VAR(ret, 1)
	CHECK(GrepString(errorMsg, "Test pulse already running on .*; start ignored.\r"))

	[ret, errorMsg] = FFI_StopTestPulse(device)
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EMPTY_STR(errorMsg)

	CHECK_EQUAL_VAR(RoVar(GetTestpulseRunMode(device)), TEST_PULSE_NOT_RUNNING)

	[ret, errorMsg] = FFI_TestPulseMD(device, 1)
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EMPTY_STR(errorMsg)

	CHECK_EQUAL_VAR(RoVar(GetTestpulseRunMode(device)), TEST_PULSE_BG_MULTI_DEVICE)

	[ret, errorMsg] = FFI_TestPulseMD(device, 0)
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EMPTY_STR(errorMsg)

	CHECK_EQUAL_VAR(RoVar(GetTestpulseRunMode(device)), TEST_PULSE_NOT_RUNNING)

	try
		[ret, errorMsg] = FFI_TestPulseMD(device, -1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End
