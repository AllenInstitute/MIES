#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = ForeignFunctionInterfaceWithHW

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function HardwareSelectionWorks([STRUCT IUTF_MDATA &md])

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"             + \
	                                                           "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	ACD_AcquireData(s, md.s0)
End

static Function HardwareSelectionWorks_REENTRY([STRUCT IUTF_MDATA &md])

	string device = md.s0

	CHECK(MIES_FFI#FFI_TP_DeviceSelectable(md.s0))

	PGC_SetAndActivateControl(device, "button_SettingsPlus_unLockDevic")

	// non-available device
	CHECK(!MIES_FFI#FFI_TP_DeviceSelectable("ITC16USB_Dev_1"))
End

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
// UTF_TD_GENERATOR w0:DataGenerators#FFI_ClampModeCases
static Function FFIGetCurrentClampStateWorks([STRUCT IUTF_MDATA &md])

	string settings
	WAVE/T clampModeCase = md.w0

	sprintf settings, "MD1_RA0_I0_L0_BKG1_TP0_DAQ0__HS0_DA0_AD0_CM:%s:_ST:StimulusSetA_DA_0:", clampModeCase[0]

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString(settings)

	ACD_AcquireData(s, md.s0)
End

static Function FFIGetCurrentClampStateWorks_REENTRY([STRUCT IUTF_MDATA &md])

	variable i, numLabels, expectedMode
	string device, lbl

	device = md.s0

	WAVE/T clampModeCase = md.w0
	expectedMode = str2num(clampModeCase[1])

	WAVE/Z clampState = FFI_GetCurrentClampState(device, 0)
	CHECK_WAVE(clampState, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(clampState[%ClampMode], expectedMode)

	numLabels = ItemsInList(clampModeCase[2])
	for(i = 0; i < numLabels; i += 1)
		lbl = StringFromList(i, clampModeCase[2])
		CHECK(IsFinite(clampState[%$lbl]))
	endfor

	// a headstage that was never activated returns a null wave
	WAVE/Z clampStateInactive = FFI_GetCurrentClampState(device, 1)
	CHECK(!WaveExists(clampStateInactive))

	// an invalid headstage index aborts
	try
		WAVE/Z clampStateInvalid = FFI_GetCurrentClampState(device, NUM_HEADSTAGES)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function FFIGetClampStateWorks([STRUCT IUTF_MDATA &md])

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"             + \
	                                                           "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	ACD_AcquireData(s, md.s0)
End

static Function FFIGetClampStateWorks_REENTRY([STRUCT IUTF_MDATA &md])

	string device = md.s0

	// The full clamp state always contains both VC and IC parameters, regardless of the
	// headstage's current clamp mode (IC here, see setup) -- unlike FFI_GetCurrentClampState,
	// which is filtered down to only the active mode's parameters.
	WAVE/Z clampState = FFI_GetClampState(device, 0)
	CHECK_WAVE(clampState, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(GetWaveDimensionality(clampState), ROWS)
	CHECK(IsFinite(clampState[%HoldingPotential]))
	CHECK(IsFinite(clampState[%BiasCurrent]))

	// a headstage that was never activated returns a null wave
	WAVE/Z clampStateInactive = FFI_GetClampState(device, 1)
	CHECK(!WaveExists(clampStateInactive))

	// an invalid headstage index aborts
	try
		WAVE/Z clampStateInvalid = FFI_GetClampState(device, NUM_HEADSTAGES)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function FFISetGetHeadstageActiveWorks([STRUCT IUTF_MDATA &md])

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"             + \
	                                                           "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	ACD_AcquireData(s, md.s0)
End

static Function FFISetGetHeadstageActiveWorks_REENTRY([STRUCT IUTF_MDATA &md])

	string device = md.s0

	// HS0 was activated by AcquireData_NG's setup; HS1 was never touched
	CHECK_EQUAL_VAR(FFI_GetHeadstageActive(device, 0), 1)
	CHECK_EQUAL_VAR(FFI_GetHeadstageActive(device, 1), 0)

	// enable HS1, verify, then disable again to leave the device in its original state
	CHECK_EQUAL_VAR(FFI_SetHeadstageActive(device, 1, 1), 0)
	CHECK_EQUAL_VAR(FFI_GetHeadstageActive(device, 1), 1)

	CHECK_EQUAL_VAR(FFI_SetHeadstageActive(device, 1, 0), 0)
	CHECK_EQUAL_VAR(FFI_GetHeadstageActive(device, 1), 0)

	// an invalid headstage index aborts, for both the getter and the setter
	try
		FFI_GetHeadstageActive(device, NUM_HEADSTAGES)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	try
		FFI_SetHeadstageActive(device, NUM_HEADSTAGES, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function FFISetClampModeWorks([STRUCT IUTF_MDATA &md])

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"             + \
	                                                           "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	ACD_AcquireData(s, md.s0)
End

static Function FFISetClampModeWorks_REENTRY([STRUCT IUTF_MDATA &md])

	string   device    = md.s0
	variable headstage = 0

	// starts out in IC, per setup above
	WAVE/Z clampState = FFI_GetCurrentClampState(device, headstage)
	CHECK_WAVE(clampState, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(clampState[%ClampMode], I_CLAMP_MODE)

	// switch to VC and verify
	FFI_SetClampMode(device, headstage, V_CLAMP_MODE)
	WAVE/Z clampState = FFI_GetCurrentClampState(device, headstage)
	CHECK_WAVE(clampState, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(clampState[%ClampMode], V_CLAMP_MODE)

	// switch to I=0 and verify
	FFI_SetClampMode(device, headstage, I_EQUAL_ZERO_MODE)
	WAVE/Z clampState = FFI_GetCurrentClampState(device, headstage)
	CHECK_WAVE(clampState, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(clampState[%ClampMode], I_EQUAL_ZERO_MODE)

	// switch back to IC, leaving the headstage in its original mode
	FFI_SetClampMode(device, headstage, I_CLAMP_MODE)
	WAVE/Z clampState = FFI_GetCurrentClampState(device, headstage)
	CHECK_WAVE(clampState, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(clampState[%ClampMode], I_CLAMP_MODE)

	// an invalid clamp mode value aborts
	try
		FFI_SetClampMode(device, headstage, -1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// an invalid headstage index aborts
	try
		FFI_SetClampMode(device, NUM_HEADSTAGES, I_CLAMP_MODE)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function FFISetHoldingPotentialWorks([STRUCT IUTF_MDATA &md])

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"             + \
	                                                           "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:")

	ACD_AcquireData(s, md.s0)
End

static Function FFISetHoldingPotentialWorks_REENTRY([STRUCT IUTF_MDATA &md])

	string   device    = md.s0
	variable headstage = 0

	// starts out in VC, per setup above
	WAVE/Z clampState = FFI_GetCurrentClampState(device, headstage)
	CHECK_WAVE(clampState, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(clampState[%ClampMode], V_CLAMP_MODE)

	// set holding potential to 10 mV and enable it
	FFI_SetHoldingPotential(device, headstage, 10, 1)
	WAVE/Z clampState = FFI_GetCurrentClampState(device, headstage)
	CHECK_WAVE(clampState, NUMERIC_WAVE)
	CHECK_CLOSE_VAR(clampState[%HoldingPotential], 10, tol = 1e-6)
	CHECK_EQUAL_VAR(clampState[%HoldingPotentialEnable], 1)

	// disable it, changing the value back to 0 at the same time
	FFI_SetHoldingPotential(device, headstage, 0, 0)
	WAVE/Z clampState = FFI_GetCurrentClampState(device, headstage)
	CHECK_WAVE(clampState, NUMERIC_WAVE)
	CHECK_CLOSE_VAR(clampState[%HoldingPotential], 0, tol = 1e-6)
	CHECK_EQUAL_VAR(clampState[%HoldingPotentialEnable], 0)

	// a NaN potential aborts
	try
		FFI_SetHoldingPotential(device, headstage, NaN, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// attempting to set a holding potential while the headstage is not in VC aborts
	// use HS0 itself for this (headstage 1 has no DA/AD channels associated, per the setup
	// above, so its clamp mode can not be changed at all), switching it back to VC afterwards
	FFI_SetClampMode(device, headstage, I_CLAMP_MODE)
	try
		FFI_SetHoldingPotential(device, headstage, 0, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
	FFI_SetClampMode(device, headstage, V_CLAMP_MODE)

	// an invalid headstage index aborts
	try
		FFI_SetHoldingPotential(device, NUM_HEADSTAGES, 0, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function FFISetBiasCurrentWorks([STRUCT IUTF_MDATA &md])

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"             + \
	                                                           "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	ACD_AcquireData(s, md.s0)
End

static Function FFISetBiasCurrentWorks_REENTRY([STRUCT IUTF_MDATA &md])

	string   device    = md.s0
	variable headstage = 0

	// starts out in IC, per setup above
	WAVE/Z clampState = FFI_GetCurrentClampState(device, headstage)
	CHECK_WAVE(clampState, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(clampState[%ClampMode], I_CLAMP_MODE)

	// set bias current to 10 pA and enable it
	FFI_SetBiasCurrent(device, headstage, 10, 1)
	WAVE/Z clampState = FFI_GetCurrentClampState(device, headstage)
	CHECK_WAVE(clampState, NUMERIC_WAVE)
	CHECK_CLOSE_VAR(clampState[%BiasCurrent], 10, tol = 1e-6)
	CHECK_EQUAL_VAR(clampState[%BiasCurrentEnable], 1)

	// disable it, changing the value back to 0 at the same time
	FFI_SetBiasCurrent(device, headstage, 0, 0)
	WAVE/Z clampState = FFI_GetCurrentClampState(device, headstage)
	CHECK_WAVE(clampState, NUMERIC_WAVE)
	CHECK_CLOSE_VAR(clampState[%BiasCurrent], 0, tol = 1e-6)
	CHECK_EQUAL_VAR(clampState[%BiasCurrentEnable], 0)

	// a NaN bias current aborts
	try
		FFI_SetBiasCurrent(device, headstage, NaN, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// attempting to set a bias current while the headstage is not in IC aborts
	// use HS0 itself for this, switching it back to IC afterwards
	FFI_SetClampMode(device, headstage, V_CLAMP_MODE)
	try
		FFI_SetBiasCurrent(device, headstage, 0, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
	FFI_SetClampMode(device, headstage, I_CLAMP_MODE)

	// an invalid headstage index aborts
	try
		FFI_SetBiasCurrent(device, NUM_HEADSTAGES, 0, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function FFISetAutoBiasWorks([STRUCT IUTF_MDATA &md])

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"             + \
	                                                           "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	ACD_AcquireData(s, md.s0)
End

static Function FFISetAutoBiasWorks_REENTRY([STRUCT IUTF_MDATA &md])

	string   device    = md.s0
	variable headstage = 0

	// starts out in IC, per setup above
	WAVE/Z clampState = FFI_GetCurrentClampState(device, headstage)
	CHECK_WAVE(clampState, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(clampState[%ClampMode], I_CLAMP_MODE)

	// set auto bias target potential to 10 mV and enable it
	FFI_SetAutoBias(device, headstage, 10, 1)
	WAVE/Z clampState = FFI_GetCurrentClampState(device, headstage)
	CHECK_WAVE(clampState, NUMERIC_WAVE)
	CHECK_CLOSE_VAR(clampState[%AutoBiasVcom], 10, tol = 1e-6)
	CHECK_EQUAL_VAR(clampState[%AutoBiasEnable], 1)

	// disable it, changing the value back to 0 at the same time
	FFI_SetAutoBias(device, headstage, 0, 0)
	WAVE/Z clampState = FFI_GetCurrentClampState(device, headstage)
	CHECK_WAVE(clampState, NUMERIC_WAVE)
	CHECK_CLOSE_VAR(clampState[%AutoBiasVcom], 0, tol = 1e-6)
	CHECK_EQUAL_VAR(clampState[%AutoBiasEnable], 0)

	// attempting to set auto bias while the headstage is not in IC aborts
	// use HS0 itself for this, switching it back to IC afterwards
	FFI_SetClampMode(device, headstage, V_CLAMP_MODE)
	try
		FFI_SetAutoBias(device, headstage, 0, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
	FFI_SetClampMode(device, headstage, I_CLAMP_MODE)

	// an invalid headstage index aborts
	try
		FFI_SetAutoBias(device, NUM_HEADSTAGES, 0, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function FFITriggerAutoClampControlWorks([STRUCT IUTF_MDATA &md])

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"             + \
	                                                           "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	ACD_AcquireData(s, md.s0)
End

static Function FFITriggerAutoClampControlWorks_REENTRY([STRUCT IUTF_MDATA &md])

	string   device    = md.s0
	variable headstage = 0

	// starts out in IC, per setup above
	WAVE/Z clampState = FFI_GetCurrentClampState(device, headstage)
	CHECK_WAVE(clampState, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(clampState[%ClampMode], I_CLAMP_MODE)

	// auto pipette offset works regardless of the current clamp mode
	FFI_TriggerAutoClampControl(device, headstage, AUTO_PIPETTE)

	// auto bridge balance works in IC, per setup above
	FFI_TriggerAutoClampControl(device, headstage, AUTO_BRIDGEBALANCE)

	// auto bridge balance aborts outside of IC
	FFI_SetClampMode(device, headstage, V_CLAMP_MODE)
	try
		FFI_TriggerAutoClampControl(device, headstage, AUTO_BRIDGEBALANCE)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// auto capacitance works in VC
	FFI_TriggerAutoClampControl(device, headstage, AUTO_CAPACITANCE)

	// auto capacitance aborts outside of VC; switch back to IC afterwards,
	// leaving the headstage in its original mode
	FFI_SetClampMode(device, headstage, I_CLAMP_MODE)
	try
		FFI_TriggerAutoClampControl(device, headstage, AUTO_CAPACITANCE)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// an unknown auto clamp control value aborts
	try
		FFI_TriggerAutoClampControl(device, headstage, 99)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// an invalid headstage index aborts
	try
		FFI_TriggerAutoClampControl(device, NUM_HEADSTAGES, AUTO_PIPETTE)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

// UTF_TD_GENERATOR s0:DataGenerators#DeviceNameGeneratorMD1
static Function StartingStoppingTestPulseWorks([STRUCT IUTF_MDATA &md])

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"             + \
	                                                           "__HS0_DA0_AD0_CM:IC:_ST:StimulusSetA_DA_0:")

	ACD_AcquireData(s, md.s0)
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
