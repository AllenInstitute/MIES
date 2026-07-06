#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTF_Replay

/// @file UTF_Replay.ipf
///
/// Overview:
///
/// - ReplayDataTest checks that the replay data feature is disabled by default and does DAQ
/// - ReplayDataTest_R1 (aka _REENTRY once) checks LBN entries and enables Replay Data
/// - ReplayDataTest_R2 checks the replay data enabled settings and replays sweep zero
/// - ReplayDataTest_R3 checks that replaying the data did not result in any differences
/// - ReplayDataTest_R4 disables replay data again
/// - ReplayDataTest_R5 checks that it is disabled

// UTF_TD_GENERATOR DataGenerators#DeviceNameGeneratorMD1
static Function ReplayDataTest([string str])

	INFO("REPLAY_DATA is still defined, call DisableReplayData() before.")

	REQUIRE(!RD_IsCompilationEnabled())
	REQUIRE(!RD_IsEnabled())

	[STRUCT ACD_DAQSettings s] = ACD_InitDAQSettingsFromString("MD1_RA0_I0_L0_BKG1"                      + \
	                                                           "__HS0_DA0_AD0_CM:VC:_ST:StimulusSetA_DA_0:")

	ACD_AcquireData(s, str)
End

static Function ReplayDataTest_REENTRY([string str])

	WAVE numericalValues = GetLBnumericalValues(str)

	WAVE/Z settings = GetLastSetting(numericalValues, 0, "Original data", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(settings, WaveDouble({NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1}))

	EnableReplayData()

	RegisterReentryFunction("UTF_Replay#" + GetRTStackInfo(1))
End

static Function ReplayDataTest_REENTRY_REENTRY([string str])

	CHECK(RD_IsCompilationEnabled())
	CHECK(!RD_IsEnabled())

#ifdef REPLAY_DATA
	KillOrMoveToTrash(dfr = GetReplayStorage())
	RD_PrepareMIES()
	RD_ReplayData(0)
#else
	INFO("REPLAY_DATA is not defined")
	FAIL()
#endif // REPLAY_DATA

	RegisterReentryFunction("UTF_Replay#" + GetRTStackInfo(1))
End

static Function ReplayDataTest_REENTRY_REENTRY_REENTRY([string str])

	WAVE numericalValues = GetLBnumericalValues(str)

	WAVE/Z settings = GetLastSetting(numericalValues, 0, "Original data", DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(settings, WaveDouble({NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0}))

#ifdef REPLAY_DATA
	CHECK_EQUAL_VAR(RD_CompareRAC(), 0)
	CHECK_EQUAL_VAR(RD_CompareSCI(), 0)
	CHECK_EQUAL_VAR(RD_CompareLabnotebooks(), 0)
#else
	INFO("REPLAY_DATA is not defined")
	FAIL()
#endif // REPLAY_DATA

	RegisterReentryFunction("UTF_Replay#" + GetRTStackInfo(1))
End

static Function ReplayDataTest_REENTRY_REENTRY_REENTRY_REENTRY([string str])

	DisableReplayData()

	RegisterReentryFunction("UTF_Replay#" + GetRTStackInfo(1))
End

static Function ReplayDataTest_REENTRY_REENTRY_REENTRY_REENTRY_REENTRY([string str])

	CHECK(!RD_IsCompilationEnabled())
	// because REPLAY_DATA is not defined anymore, also the replay enable knob is disabled
	CHECK(!RD_IsEnabled())
	// although GetReplayDataEnable() would still return true
End
