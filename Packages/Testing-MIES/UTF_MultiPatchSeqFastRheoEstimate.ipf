#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma ModuleName=MultiPatchSeqFastRheoEstimate

/// @brief Acquire data with the given DAQSettings
static Function AcquireData(s, [postInitializeFunc, preAcquireFunc])
	STRUCT DAQSettings& s
	FUNCREF CALLABLE_PROTO postInitializeFunc, preAcquireFunc

	Initialize_IGNORE()

	if(!ParamIsDefault(postInitializeFunc))
		postInitializeFunc()
	endif

	string unlockedPanelTitle = DAP_CreateDAEphysPanel()

	ChooseCorrectDevice(unlockedPanelTitle, DEVICE)
	PGC_SetAndActivateControl(unlockedPanelTitle, "button_SettingsPlus_LockDevice")

	REQUIRE(WindowExists(DEVICE))

	PGC_SetAndActivateControl(DEVICE, "ADC", val=0)
	DoUpdate/W=$DEVICE

	PGC_SetAndActivateControl(DEVICE, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(DEVICE, "setvar_DataAcq_AutoBiasV", val = 70)
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(0, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str ="MSQ_FastRheoEst_DA_0")
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(1, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK), val=1)
	PGC_SetAndActivateControl(DEVICE, GetPanelControl(1, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "MSQ_FastRheoEst_DA_0")

	WAVE ampMCC = GetAmplifierMultiClamps()
	WAVE ampTel = GetAmplifierTelegraphServers()

	CHECK_EQUAL_VAR(DimSize(ampMCC, ROWS), 2)
	CHECK_EQUAL_VAR(DimSize(ampTel, ROWS), 2)

	// HS 0 with Amp
	PGC_SetAndActivateControl(DEVICE, "Popup_Settings_HeadStage", val = 0)
	PGC_SetAndActivateControl(DEVICE, "popup_Settings_Amplifier", val = 1)
	PGC_SetAndActivateControl(DEVICE, DAP_GetClampModeControl(I_CLAMP_MODE, 0), val=1)

	// HS 1 with Amp
	PGC_SetAndActivateControl(DEVICE, "Popup_Settings_HeadStage", val = 1)
	PGC_SetAndActivateControl(DEVICE, "popup_Settings_Amplifier", val = 2)
	PGC_SetAndActivateControl(DEVICE, DAP_GetClampModeControl(I_CLAMP_MODE, 1), val=1)

	DoUpdate/W=$DEVICE

	PGC_SetAndActivateControl(DEVICE, "button_Hardware_AutoGainAndUnit")

	PGC_SetAndActivateControl(DEVICE, "check_Settings_MD", val = s.MD)
	PGC_SetAndActivateControl(DEVICE, "Check_DataAcq1_RepeatAcq", val = s.RA)
	PGC_SetAndActivateControl(DEVICE, "Check_DataAcq_Indexing", val = s.IDX)
	PGC_SetAndActivateControl(DEVICE, "Check_DataAcq1_IndexingLocked", val = s.LIDX)
	PGC_SetAndActivateControl(DEVICE, "Check_Settings_BackgrndDataAcq", val = s.BKG_DAQ)
	PGC_SetAndActivateControl(DEVICE, "SetVar_DataAcq_SetRepeats", val = s.RES)
	PGC_SetAndActivateControl(DEVICE, "Check_Settings_SkipAnalysFuncs", val = 0)
	PGC_SetAndActivateControl(DEVICE, "Popup_Settings_SampIntMult", str = "4")

	DoUpdate/W=$DEVICE

	CtrlNamedBackGround DAQWatchdog, start, period=120, proc=WaitUntilDAQDone_IGNORE

	if(!ParamIsDefault(preAcquireFunc))
		preAcquireFunc()
	endif

	PGC_SetAndActivateControl(DEVICE, "DataAcquireButton")
	OpenDatabrowser()
End

static Constant INDEP_EACH_SCI = 0x01
static Constant EACH_SCI       = 0x02
static Constant INDEP          = 0x04
static Constant SINGLE_SCI     = 0x08

static Function/WAVE GetResults_IGNORE(sweepNo, str, headstage, mode)
	variable sweepNo, headstage, mode
	string str

	string key

	WAVE numericalValues = GetLBNumericalValues(DEVICE)
	key = MSQ_CreateLBNKey(MSQ_FAST_RHEO_EST, str, query = 1)

	switch(mode)
		case INDEP_EACH_SCI:
			return GetLastSettingIndepEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
		case EACH_SCI:
			return GetLastSettingEachSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
		case INDEP:
			CHECK_EQUAL_VAR(numtype(headstage), 2)
			Make/D/N=1/FREE val = GetLastSettingIndep(numericalValues, sweepNo, key, UNKNOWN_MODE)
			return val
		case SINGLE_SCI:
			return GetLastSettingSCI(numericalValues, sweepNo, key, headstage, UNKNOWN_MODE)
	endswitch
End

static Function MSQ_FRE_Run1()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s)

	WAVE wv = MSQ_CreateOverrideResults(DEVICE, 0, MSQ_FAST_RHEO_EST)
	// all tests fail
	wv = 0
End

static Function MSQ_FRE_Test1()

	variable sweepNo
	string lbl

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	WAVE/Z setPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, UNKNOWN_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(DEVICE, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	CHECK_CLOSE_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 0), 2100)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	CHECK_CLOSE_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 1), 2100)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	EnsureNoAnaFuncErrors()
End

static Function MSQ_FRE_Run2()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s)

	WAVE wv = MSQ_CreateOverrideResults(DEVICE, 0, MSQ_FAST_RHEO_EST)
	// all tests fail
	// spike before pulse, does not count
	wv = 2.5
End

static Function MSQ_FRE_Test2()

	variable sweepNo
	string lbl

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	WAVE/Z setPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(DEVICE, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_CLOSE_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 0), 2100)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_CLOSE_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 1), 2100)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	EnsureNoAnaFuncErrors()
End

static Function MSQ_FRE_Run3()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s)

	WAVE wv = MSQ_CreateOverrideResults(DEVICE, 0, MSQ_FAST_RHEO_EST)
	// spike detected on second sweep, but never again
	wv[]  = 0
	wv[1][] = 1
End

static Function MSQ_FRE_Test3()

	variable sweepNo
	string lbl

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	WAVE/Z setPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320},  mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320},  mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, -50, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, -50, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(DEVICE, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	CHECK_CLOSE_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 0), 330)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	CHECK_CLOSE_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 1), 330)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	EnsureNoAnaFuncErrors()
End

static Function MSQ_FRE_Run4()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s)

	WAVE wv = MSQ_CreateOverrideResults(DEVICE, 0, MSQ_FAST_RHEO_EST)
	// HS0: no spikes
	// HS1: spike on second and fourth sweep
	// -> HS1 passes, but the sweep does not
	wv[]  = 0
	wv[1][1] = 1
	wv[3][1] = 1
End

static Function MSQ_FRE_Test4()

	variable sweepNo
	string lbl

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	WAVE/Z setPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 0, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale,  {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000},   mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},  mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, -50, 10, 10, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(DEVICE, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_CLOSE_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 0), 2100)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 1), 0)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	EnsureNoAnaFuncErrors()
End

static Function MSQ_FRE_Run5()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s)

	WAVE wv = MSQ_CreateOverrideResults(DEVICE, 0, MSQ_FAST_RHEO_EST)

	// HS0: spike on fifth and seventh sweep
	// HS1: spike on second and fourth sweep
	// -> Sweep and Set passes
	wv[]  = 0
	wv[5][0] = 1
	wv[7][0] = 1
	wv[1][1] = 1
	wv[3][1] = 1
End

static Function MSQ_FRE_Test5()

	variable sweepNo
	string lbl

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 8)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 7)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	WAVE/Z setPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 1, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 1, 0, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 0, 1, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 550, 560}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 160, 0, 0, 0, 0},  mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, -50, 10, 10}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, -50, 10, 10, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(DEVICE, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(finalDAScale, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, 560e-12}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z finalDAScale = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(finalDAScale, {NaN, NaN, NaN, 160e-12, NaN, NaN, NaN, NaN},  mode = WAVE_DATA, tol = 1e-14)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 0), 0)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 1), 0)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	EnsureNoAnaFuncErrors()
End

static Function VClampOnSecondHS_IGNORE()

	PGC_SetAndActivateControl(DEVICE, DAP_GetClampModeControl(V_CLAMP_MODE, 1), val=1)
End

// only one IC and one VC headstage
// check that VC is on again in the end
static Function MSQ_FRE_Run6()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, preAcquireFunc=VClampOnSecondHS_IGNORE)

	WAVE wv = MSQ_CreateOverrideResults(DEVICE, 0, MSQ_FAST_RHEO_EST)

	// HS0: spike on fifth and seventh sweep
	wv[]  = 0
	wv[5][0] = 1
	wv[7][0] = 1
End

static Function MSQ_FRE_Test6()

	variable sweepNo
	string lbl

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 8)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 7)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	WAVE/Z setPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_WAVE(sweepPass, NULL_WAVE)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_WAVE(headstagePass, NULL_WAVE)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 1, 0, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_WAVE(spikeDetectionWave, NULL_WAVE)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 550, 560}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_WAVE(stimScale, NULL_WAVE)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, -50, 10, 10}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	CHECK_WAVE(stepsizes, NULL_WAVE)

	WAVE/Z activeHS = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(DEVICE, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_WAVE(rangeExceeded, NULL_WAVE)

	WAVE/Z finalDAScale = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(finalDAScale, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, 560e-12}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z finalDAScale = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 1, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 0), 0)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	EnsureNoAnaFuncErrors()
End

static Function AddAnalysisParamsDAScale_IGNORE()
	WBP_AddAnalysisParameter("MSQ_FastRheoEst_DA_0", "PostDAQDAScale", var=1)
	WBP_AddAnalysisParameter("MSQ_FastRheoEst_DA_0", "PostDAQDAScaleFactor", var=1.5)
End

// one test with PostDAQDAScale and PostDAQDAScaleFactor analysis parameters
// check dascale after DAQ
static Function MSQ_FRE_Run7()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, postInitializeFunc=AddAnalysisParamsDAScale_IGNORE)

	WAVE wv = MSQ_CreateOverrideResults(DEVICE, 0, MSQ_FAST_RHEO_EST)

	// HS0: spike on fifth and seventh sweep
	// HS1: spike on second and fourth sweep
	// -> Sweep and Set passes
	wv[]  = 0
	wv[5][0] = 1
	wv[7][0] = 1
	wv[1][1] = 1
	wv[3][1] = 1
End

static Function MSQ_FRE_Test7()

	variable sweepNo
	string lbl

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 8)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 7)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	WAVE/Z setPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 1, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 1, 0, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 0, 1, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 550, 560}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 160, 0, 0, 0, 0},  mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, -50, 10, 10}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, -50, 10, 10, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(DEVICE, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(finalDAScale, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, 560e-12}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z finalDAScale = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(finalDAScale, {NaN, NaN, NaN, 160e-12, NaN, NaN, NaN, NaN},  mode = WAVE_DATA, tol = 1e-14)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 0), 560 * 1.5)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 1), 160 * 1.5)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	EnsureNoAnaFuncErrors()
End

// one test with PostDAQDAScale and PostDAQDAScaleFactor analysis parameters
// check dascale after DAQ and one headstage failed
static Function MSQ_FRE_Run8()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, postInitializeFunc=AddAnalysisParamsDAScale_IGNORE)

	WAVE wv = MSQ_CreateOverrideResults(DEVICE, 0, MSQ_FAST_RHEO_EST)

	// HS0: spike on fifth and seventh sweep
	// -> Sweep and Set failed
	wv[]  = 0
	wv[5][0] = 1
	wv[7][0] = 1
End

static Function MSQ_FRE_Test8()

	variable sweepNo
	string lbl

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 20)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 19)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	WAVE/Z setPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 1, 0, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 550, 560, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, -50, 10, 10, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(DEVICE, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(finalDAScale, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, 560e-12, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z finalDAScale = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 1, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 0), 560 * 1.5)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 1), 1250)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	EnsureNoAnaFuncErrors()
End

static Function AddAnalysisParamsMaxDa_IGNORE()
	WBP_AddAnalysisParameter("MSQ_FastRheoEst_DA_0", "MaximumDAScale", var=205)
End

// one test with range exceeded and MaximumDAScale analysis parameter
static Function MSQ_FRE_Run9()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, postInitializeFunc=AddAnalysisParamsMaxDa_IGNORE)

	WAVE wv = MSQ_CreateOverrideResults(DEVICE, 0, MSQ_FAST_RHEO_EST)

	// all fail
	wv[] = 0
End

static Function MSQ_FRE_Test9()

	variable sweepNo
	string lbl

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 2)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 1)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	WAVE/Z setPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200},  mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, 100}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, 100}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(DEVICE, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, 1}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, 1}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	WAVE/Z finalDAScale = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 1, EACH_SCI)
	CHECK_WAVE(finalDAScale, NULL_WAVE)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 0), 200)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
	CHECK_EQUAL_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 1), 200)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	EnsureNoAnaFuncErrors()
End

static Function AddAnalysisParamsMinRheo_IGNORE()
	WBP_AddAnalysisParameter("MSQ_FastRheoEst_DA_0", "PostDAQDAScale", var=1)
	WBP_AddAnalysisParameter("MSQ_FastRheoEst_DA_0", "PostDAQDAScaleMinOffset", var=100)
	WBP_AddAnalysisParameter("MSQ_FastRheoEst_DA_0", "PostDAQDAScaleFactor", var=1.5)
End

// Using MinOffset and a scale factor
static Function MSQ_FRE_Run10()

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "DAQ_MD1_RA1_IDX0_LIDX0_BKG_1")
	AcquireData(s, postInitializeFunc=AddAnalysisParamsMinRheo_IGNORE)

	WAVE wv = MSQ_CreateOverrideResults(DEVICE, 0, MSQ_FAST_RHEO_EST)

	// HS0: spike on fifth and seventh sweep
	// HS1: spike on second and fourth sweep
	// -> Sweep and Set passes
	wv[]  = 0
	wv[5][0] = 1
	wv[7][0] = 1
	wv[1][1] = 1
	wv[3][1] = 1
End

static Function MSQ_FRE_Test10()

	variable sweepNo
	string lbl

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 8)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 7)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	WAVE/Z setPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SET_PASS, NaN, INDEP)
	CHECK_EQUAL_WAVES(setPass, {1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 0, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z sweepPass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SWEEP_PASS, 1, INDEP_EACH_SCI)
	CHECK_EQUAL_WAVES(sweepPass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 0, 0, 0, 0, 1}, mode = WAVE_DATA)

	WAVE/Z headstagePass = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_HEADSTAGE_PASS, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(headstagePass, {0, 0, 0, 1, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 0, 0, 0, 0, 1, 0, 1}, mode = WAVE_DATA)

	WAVE/Z spikeDetectionWave = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_SPIKE_DETECT, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(spikeDetectionWave, {0, 1, 0, 1, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 0, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 300, 400, 500, 600, 550, 560}, mode = WAVE_DATA)

	WAVE/Z stimScale = GetLastSettingEachSCI(numericalValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, 1, DATA_ACQUISITION_MODE)
	CHECK_EQUAL_WAVES(stimScale, {100, 200, 150, 160, 0, 0, 0, 0},  mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 0, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, 100, 100, 100, 100, -50, 10, 10}, mode = WAVE_DATA)

	WAVE/Z stepsizes = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_STEPSIZE, 1, EACH_SCI)
	stepsizes *= 1e12
	CHECK_EQUAL_WAVES(stepsizes, {100, -50, 10, 10, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z activeHS = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_ACTIVE_HS, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(activeHS, {1, 1, 0, 0, 0, 0, 0, 0, NaN}, mode = WAVE_DATA)

	WAVE/Z statusHS = DAG_GetChannelState(DEVICE, CHANNEL_TYPE_HEADSTAGE)
	WaveTransform/O zapNaNs, activeHS
	CHECK_EQUAL_WAVES(activeHS, statusHS, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z rangeExceeded = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_DASCALE_EXC, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(rangeExceeded, {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z finalDAScale = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 0, EACH_SCI)
	CHECK_EQUAL_WAVES(finalDAScale, {NaN, NaN, NaN, NaN, NaN, NaN, NaN, 560e-12}, mode = WAVE_DATA, tol = 1e-14)

	WAVE/Z finalDAScale = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_FINAL_SCALE, 1, EACH_SCI)
	CHECK_EQUAL_WAVES(finalDAScale, {NaN, NaN, NaN, 160e-12, NaN, NaN, NaN, NaN},  mode = WAVE_DATA, tol = 1e-14)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 0), 560 * 1.5)

	lbl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)

	CHECK_EQUAL_VAR(DAG_GetNumericalValue(DEVICE, lbl, index = 1), 160 + 100)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 0, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	WAVE/Z pulseDuration = GetResults_IGNORE(sweepNo, MSQ_FMT_LBN_PULSE_DUR, 1, SINGLE_SCI)
	CHECK_EQUAL_WAVES(pulseDuration, {3, 3, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, mode = WAVE_DATA, tol=1e-8)

	EnsureNoAnaFuncErrors()
End
