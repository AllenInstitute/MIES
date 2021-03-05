#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma ModuleName=ReachTargetVoltageTesting

static Constant HEADSTAGE = 0

static Function [WAVE/Z deltaI, WAVE/Z deltaV, WAVE/Z resistance, WAVE/Z resistanceErr, WAVE/Z autobiasFromDialog] GetLBNEntries_IGNORE(string device, variable sweepNo)

	WAVE numericalValues = GetLBNumericalValues(device)

	WAVE/Z deltaI        = GetLastSettingEachSCI(numericalValues, sweepNo, "USER_Delta I", HEADSTAGE, UNKNOWN_MODE)
	WAVE/Z deltaV        = GetLastSettingEachSCI(numericalValues, sweepNo, "USER_Delta V", HEADSTAGE, UNKNOWN_MODE)
	WAVE/Z resistance    = GetLastSettingEachSCI(numericalValues, sweepNo, "USER_ResistanceFromFit", HEADSTAGE, UNKNOWN_MODE)
	WAVE/Z resistanceErr = GetLastSettingEachSCI(numericalValues, sweepNo, "USER_ResistanceFromFit_Err", HEADSTAGE, UNKNOWN_MODE)
	WAVE/Z autobiasFromDialog = GetLastSettingEachSCI(numericalValues, sweepNo, "USER_Autobias target voltage from dialog", HEADSTAGE, UNKNOWN_MODE)
End

static Function RTV_Works_Setter(device)
	string device

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetA_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "ReachTargetVoltage"

	PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = HEADSTAGE)

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = -70)
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function RTV_Works([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AnalysisFunctionTesting#AcquireData(s, "StimulusSetA_DA_0", str, preAcquireFunc = RTV_Works_Setter)
End

static Function RTV_Works_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE/Z deltaI, deltaV, resistance, resistanceErr, autobiasFromDialog
	[deltaI, deltaV, resistance, resistanceErr, autobiasFromDialog] = GetLBNEntries_IGNORE(str, sweepNo)

	CHECK_WAVE(deltaI, NUMERIC_WAVE)
	CHECK_WAVE(deltaV, NUMERIC_WAVE)
	CHECK_WAVE(resistance, NUMERIC_WAVE)
	CHECK_WAVE(resistanceErr, NUMERIC_WAVE)
	CHECK_WAVE(autobiasFromDialog, NULL_WAVE)
End

static Function RTV_WorksWithIndexing_Setter(device)
	string device

	WAVE/T wv = root:MIES:WaveBuilder:SavedStimulusSetParameters:DA:WPT_StimulusSetA_DA_0

	wv[][%Set] = ""
	wv[%$"Analysis function (generic)"][%Set] = "ReachTargetVoltage"

	PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = HEADSTAGE)

	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_AutoBiasV", val = -70)

	WBP_AddAnalysisParameter("StimulusSetA_DA_0", "EnableIndexing", var=1)
	WBP_AddAnalysisParameter("StimulusSetA_DA_0", "IndexingEndStimsetAllIC", str="StimulusSetB_DA_0")
End

// UTF_TD_GENERATOR HardwareMain#DeviceNameGeneratorMD1
static Function RTV_WorksWithIndexing([str])
	string str

	STRUCT DAQSettings s
	InitDAQSettingsFromString(s, "MD1_RA1_I0_L0_BKG_1")

	AnalysisFunctionTesting#AcquireData(s, "StimulusSetA_DA_0", str, preAcquireFunc = RTV_WorksWithIndexing_Setter)
End

static Function RTV_WorksWithIndexing_REENTRY([str])
	string str

	variable sweepNo

	CHECK_EQUAL_VAR(GetSetVariable(str, "SetVar_Sweep"), 4)

	sweepNo = AFH_GetLastSweepAcquired(str)
	CHECK_EQUAL_VAR(sweepNo, 3)

	WAVE/Z deltaI, deltaV, resistance, resistanceErr, autobiasFromDialog
	[deltaI, deltaV, resistance, resistanceErr, autobiasFromDialog] = GetLBNEntries_IGNORE(str, 0)

	CHECK_WAVE(deltaI, NUMERIC_WAVE)
	CHECK_WAVE(deltaV, NUMERIC_WAVE)
	CHECK_WAVE(resistance, NUMERIC_WAVE)
	CHECK_WAVE(resistanceErr, NUMERIC_WAVE)
	CHECK_WAVE(autobiasFromDialog, NUMERIC_WAVE)

	CHECK_EQUAL_VAR(autobiasFromDialog[HEADSTAGE], -69)
	CHECK_EQUAL_VAR(GetSetVariable(str, "setvar_DataAcq_AutoBiasV"), -69)
End
