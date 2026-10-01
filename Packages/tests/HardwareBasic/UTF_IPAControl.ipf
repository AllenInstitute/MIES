#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = IPAControlTesting

/// @file UTF_IPAControl.ipf
/// @brief __IPAT__ Tests for the Sutter amplifier control package IPA_Control.ipf
///
/// The tests address the first headstage of the IPA directly via its probe number 1.

static Constant IPA_PROBE = 1

// IPA_Control.ipf is only included with the Sutter XOP, see MIES_Include.ipf
#if exists("SutterDAQScanWave")

/// @brief Lock the device with the first headstage in the given clamp mode
///
/// Skips the test case for non-Sutter hardware.
static Function SetupIPA_IGNORE(string device, variable clampMode)

	string clampModeStr

	if(GetHardwareType(device) != HARDWARE_SUTTER_DAC)
		INFO("Requires Sutter hardware")
		SKIP_TESTCASE()
	endif

	clampModeStr = SelectString(clampMode == V_CLAMP_MODE, "IC", "VC")

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1_TP0_DAQ0"                                   \
	                                                           + "__HS0_DA0_AD0_CM:" + clampModeStr + ":_ST:StimulusSetA_DA_0:")
	ACD_AcquireData(s, device)

	CHECK_EQUAL_VAR(IPA_MIES_ReadClampModeFromHardware(IPA_PROBE), clampMode == I_CLAMP_MODE)
End

/// @brief Switch the amplifier back to the clamp mode of MIES
static Function RestoreClampMode_IGNORE(string device)

	variable currentClamp

	currentClamp = DAG_GetHeadstageMode(device, 0) == I_CLAMP_MODE
	CHECK_EQUAL_VAR(IPA_MIES_SetClampMode(IPA_PROBE, currentClamp), 1)
End

/// Locking the device initializes the package and unlocking it shuts it down
// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function IPAIsInitialized([string str])

	SetupIPA_IGNORE(str, V_CLAMP_MODE)

	CHECK_EQUAL_VAR(IPA_MIES_IsInitialized(), 1)

	PGC_SetAndActivateControl(str, "button_SettingsPlus_unLockDevic")
	CHECK_EQUAL_VAR(IPA_MIES_IsInitialized(), 0)
End

/// Locking the device resets the settings of the previous session and the GUI shows the reset state
// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function IPAResetOnLock([string str])

	string unlockedDevice

	SetupIPA_IGNORE(str, V_CLAMP_MODE)

	// settings with and without GUI control, the package stores them when unlocking
	CHECK_EQUAL_VAR(AI_WriteToAmplifier(str, 0, V_CLAMP_MODE, MCC_HOLDING_FUNC, 20), 0)
	CHECK_EQUAL_VAR(AI_WriteToAmplifier(str, 0, V_CLAMP_MODE, MCC_HOLDINGENABLE_FUNC, 1), 0)
	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "Filter", 1000), 1)
	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "IGain", 25e9), 1)

	PGC_SetAndActivateControl(str, "button_SettingsPlus_unLockDevic")
	unlockedDevice = GetCurrentWindow()
	ACD_CreateLockedDAEphys(str, unlockedDevice = unlockedDevice)

	// package defaults
	CHECK_EQUAL_VAR(IPA_MIES_GetValue(IPA_PROBE, "VHold"), 0)
	CHECK_EQUAL_VAR(IPA_GetValue(IPA_PROBE, "VHoldOn"), 0)
	CHECK_EQUAL_VAR(IPA_GetValue(IPA_PROBE, "Filter"), 5000)
	CHECK_EQUAL_VAR(IPA_GetValue(IPA_PROBE, "IGain"), 5e9)
	// stored in single precision
	CHECK_CLOSE_VAR(IPA_GetValue(IPA_PROBE, "ECompMag"), 0.1e-12, tol = 1e-6)

	WAVE AmpStorageWave = GetAmplifierParamStorageWave(str)
	CHECK_EQUAL_VAR(AmpStorageWave[%HoldingPotential][0][0], 0)
	CHECK_EQUAL_VAR(AmpStorageWave[%HoldingPotentialEnable][0][0], 0)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "setvar_DataAcq_Hold_VC"), 0)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(str, "check_DatAcq_HoldEnableVC"), 0)
End

/// The reset to the package defaults keeps the DAC offset trim of the hardware
// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function IPAResetKeepsDACOffset([string str])

	variable dacOffset

	STRUCT IPASeries SIPA

	SetupIPA_IGNORE(str, V_CLAMP_MODE)

	IPAControl#GetStructure(SIPA)
	dacOffset                            = SIPA.ipa.HS[IPA_PROBE - 1].DACOffset
	SIPA.ipa.HS[IPA_PROBE - 1].DACOffset = dacOffset + 1
	IPAControl#SaveStructure(SIPA)

	CHECK_EQUAL_VAR(IPA_MIES_ResetToDefaults(), 1)

	IPAControl#GetStructure(SIPA)
	CHECK_EQUAL_VAR(SIPA.ipa.HS[IPA_PROBE - 1].DACOffset, dacOffset + 1)

	SIPA.ipa.HS[IPA_PROBE - 1].DACOffset = dacOffset
	IPAControl#SaveStructure(SIPA)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function IPAClampModeKeywords([string str])

	SetupIPA_IGNORE(str, V_CLAMP_MODE)

	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "CCMode", 1), 1)
	CHECK_EQUAL_VAR(IPA_MIES_ReadClampModeFromHardware(IPA_PROBE), 1)
	CHECK_EQUAL_VAR(IPA_GetValue(IPA_PROBE, "CCMode"), 1)
	CHECK_EQUAL_VAR(IPA_GetValue(IPA_PROBE, "VCMode"), 0)

	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "VCMode", 1), 1)
	CHECK_EQUAL_VAR(IPA_MIES_ReadClampModeFromHardware(IPA_PROBE), 0)
	CHECK_EQUAL_VAR(IPA_GetValue(IPA_PROBE, "CCMode"), 0)
	CHECK_EQUAL_VAR(IPA_GetValue(IPA_PROBE, "VCMode"), 1)

	RestoreClampMode_IGNORE(str)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function IPADynamicHold([string str])

	SetupIPA_IGNORE(str, I_CLAMP_MODE)

	// setting the level with dynamic hold off does not enable it
	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "DynHoldOn", 0), 1)
	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "DynHold", 0.01), 1)
	CHECK_CLOSE_VAR(IPA_GetValue(IPA_PROBE, "DynHold"), 0.01, tol = 1e-6)
	CHECK_EQUAL_VAR(IPA_GetValue(IPA_PROBE, "DynHoldOn"), 0)

	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "DynHoldOn", 1), 1)
	CHECK_EQUAL_VAR(IPA_GetValue(IPA_PROBE, "DynHoldOn"), 1)
	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "DynHold", -0.02), 1)
	CHECK_CLOSE_VAR(IPA_GetValue(IPA_PROBE, "DynHold"), -0.02, tol = 1e-6)

	// limited to +/- 1 V
	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "DynHold", 5), 1)
	CHECK_CLOSE_VAR(IPA_GetValue(IPA_PROBE, "DynHold"), 1, tol = 1e-6)

	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "DynHoldOn", 0), 1)
	CHECK_EQUAL_VAR(IPA_GetValue(IPA_PROBE, "DynHoldOn"), 0)
	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "DynHold", 0), 1)

	RestoreClampMode_IGNORE(str)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function IPASealTest([string str])

	SetupIPA_IGNORE(str, V_CLAMP_MODE)

	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "SealTest", 2), 1)
	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "SealTest", 0), 1)

	RestoreClampMode_IGNORE(str)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function IPABuzz([string str])

	SetupIPA_IGNORE(str, I_CLAMP_MODE)

	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "Buzz", 5), 1)
	CHECK_EQUAL_VAR(IPA_MIES_ReadClampModeFromHardware(IPA_PROBE), 1)

	RestoreClampMode_IGNORE(str)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function IPAAuxChannels([string str])

	variable i

	SetupIPA_IGNORE(str, V_CLAMP_MODE)

	for(i = 1; i <= 2; i += 1)
		CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "AuxOut" + num2istr(i), 0.5), 1)
		CHECK_CLOSE_VAR(IPA_GetValue(IPA_PROBE, "AuxOut" + num2istr(i)), 0.5, tol = 1e-6)
		CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "AuxOut" + num2istr(i), 0), 1)
		CHECK_SMALL_VAR(IPA_GetValue(IPA_PROBE, "AuxOut" + num2istr(i)))
	endfor

	for(i = 1; i <= 4; i += 1)
		INFO("AuxIn%d", n0 = i)
		CHECK_EQUAL_VAR(IsFinite(IPA_GetValue(IPA_PROBE, "AuxIn" + num2istr(i))), 1)
	endfor

	RestoreClampMode_IGNORE(str)
End

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function IPAInvalidArguments([string str])

	variable invalidProbe, probe

	SetupIPA_IGNORE(str, V_CLAMP_MODE)

	invalidProbe = IPA_GetValue(IPA_PROBE, "NumProbes") + 1

	Make/FREE/D probes = {0, invalidProbe}
	for(probe : probes)
		INFO("probe %d", n0 = probe)
		CHECK_EQUAL_VAR(IPA_MIES_GetValue(probe, "VHold"), NaN)
		CHECK_EQUAL_VAR(IPA_MIES_ReadClampModeFromHardware(probe), NaN)
		CHECK_EQUAL_VAR(IPA_MIES_SetValue(probe, "VHold", 0), 0)
		CHECK_EQUAL_VAR(IPA_MIES_SetClampMode(probe, 0), 0)
		CHECK_EQUAL_VAR(IPA_SetValue(probe, "VHold", 0), 0)
	endfor

	CHECK_EQUAL_VAR(IPA_SetValue(IPA_PROBE, "NoSuchKeyword", 0), 0)
End

#else

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function IPARequiresSutterXOP([string str])

	INFO("Requires the Sutter XOP")
	SKIP_TESTCASE()
End

#endif // exists("SutterDAQScanWave")
