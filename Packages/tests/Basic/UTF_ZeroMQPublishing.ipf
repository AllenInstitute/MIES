#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=ZeroMQPublishingTests

// #define OUTPUT_DOCUMENTATION_JSON_DUMP

static Function TEST_CASE_BEGIN_OVERRIDE(string testname)

	TestCaseBeginCommon(testname)

	PrepareForPublishTest()
End

static Function FetchAndParseMessage(string filter)
	variable jsonID
	string   msg

	msg = FetchPublishedMessage(filter)

	CHECK_PROPER_STR(msg)

	jsonID = JSON_Parse(msg)
	CHECK_GE_VAR(jsonID, 0)

#ifdef OUTPUT_DOCUMENTATION_JSON_DUMP
	WAVE/T contents = ListToTextWave(JSON_Dump(jsonID, indent = 2), "\n")

	contents[] = "///    " + contents[p]

	print "/// Filter: #XXXX"
	print "///"
	print "/// Example:"
	print "///"
	print "/// \\rst"
	print "/// .. code-block:: json"
	print "///"
	for(s : contents)
		print s
	endfor
	print "///"
	print "/// \\endrst"
#endif

	return jsonID
End

static Function CheckPressureState()
	string device, expected, actual
	variable headstage, i, jsonID

	device    = "my_device"
	headstage = 0

	MIES_PUB#PUB_PressureMethodChange(device, headstage, PRESSURE_METHOD_ATM, PRESSURE_METHOD_APPROACH)

	jsonID = FetchAndParseMessage(PRESSURE_STATE_FILTER)

	expected = P_PressureMethodToString(PRESSURE_METHOD_ATM)
	actual   = JSON_GetString(jsonID, "/pressure method/old")
	CHECK_EQUAL_STR(actual, expected)

	expected = P_PressureMethodToString(PRESSURE_METHOD_APPROACH)
	actual   = JSON_GetString(jsonID, "/pressure method/new")
	CHECK_EQUAL_STR(actual, expected)

	JSON_Release(jsonID)
End

static Function CheckPressureSeal()
	string device, expected, actual
	variable headstage, i, jsonID, value

	device    = "my_device"
	headstage = 0

	MIES_PUB#PUB_PressureSealedState(device, headstage)

	jsonID = FetchAndParseMessage(PRESSURE_SEALED_FILTER)

	value = JSON_GetVariable(jsonID, "/sealed")
	CHECK_EQUAL_VAR(value, 1)

	JSON_Release(jsonID)
End

static Function CheckClampMode()
	string device, expected, actual
	variable headstage, i, jsonID, value

	device    = "my_device"
	headstage = 0

	MIES_PUB#PUB_ClampModeChange(device, headstage, I_CLAMP_MODE, V_CLAMP_MODE)

	jsonID = FetchAndParseMessage(AMPLIFIER_CLAMP_MODE_FILTER)

	expected = "I_CLAMP_MODE"
	actual   = JSON_GetString(jsonID, "/clamp mode/old")
	CHECK_EQUAL_STR(actual, expected)

	expected = "V_CLAMP_MODE"
	actual   = JSON_GetString(jsonID, "/clamp mode/new")
	CHECK_EQUAL_STR(actual, expected)

	JSON_Release(jsonID)
End

static Function CheckAutoBridgeBalance()
	string device, expected, actual
	variable headstage, i, jsonID, value

	device    = "my_device"
	headstage = 0

	MIES_PUB#PUB_AutoBridgeBalance(device, headstage, 4711)

	jsonID = FetchAndParseMessage(AMPLIFIER_AUTO_BRIDGE_BALANCE)

	expected = "Ohm"
	actual   = JSON_GetString(jsonID, "/bridge balance resistance/unit")
	CHECK_EQUAL_STR(actual, expected)

	value = JSON_GetVariable(jsonID, "/bridge balance resistance/value")
	CHECK_EQUAL_VAR(value, 4711)

	JSON_Release(jsonID)
End

static Function CheckPressureBreakin()
	string device
	variable headstage, i, jsonID, value

	device    = "my_device"
	headstage = 0

	MIES_PUB#PUB_PressureBreakin(device, headstage)

	jsonID = FetchAndParseMessage(PRESSURE_BREAKIN_FILTER)

	value = JSON_GetVariable(jsonID, "/break in")
	CHECK_EQUAL_VAR(value, 1)

	JSON_Release(jsonID)
End

static Function CheckAutoTP()
	string device, expected, actual
	variable headstage, i, jsonID, value

	device    = "my_device"
	headstage = 0

	// BEGIN required entries
	WAVE TPStorage = GetTPstorage(device)

	TPStorage[0][headstage][%AutoTPDeltaV] = 0.5
	SetNumberInWaveNote(TPStorage, NOTE_INDEX, 1)

	// Fake TPSettings to avoid GUI calls
	DFREF dfr        = GetDeviceTestPulse(device)
	WAVE  TPsettings = GetTPSettingsFree()
	MIES_WAVEGETTERS#SetWaveVersion(TPSettings, 2)
	MoveWave TPSettings, dfr:settings

	TPSettings[%baselinePerc][INDEP_HEADSTAGE] = 123
	TPSettings[%amplitudeIC][headstage]        = 456
	TPSettings[%amplitudeVC][headstage]        = 789

	// END required entries

	MIES_PUB#PUB_AutoTPResult(device, headstage, 1)

	jsonID = FetchAndParseMessage(AUTO_TP_FILTER)

	expected = "%"
	actual   = JSON_GetString(jsonID, "/results/baseline/unit")
	CHECK_EQUAL_STR(actual, expected)

	value = JSON_GetVariable(jsonID, "/results/baseline/value")
	CHECK_EQUAL_VAR(value, 123)

	expected = "pA"
	actual   = JSON_GetString(jsonID, "/results/amplitude IC/unit")
	CHECK_EQUAL_STR(actual, expected)

	value = JSON_GetVariable(jsonID, "/results/amplitude IC/value")
	CHECK_EQUAL_VAR(value, 456)

	expected = "mV"
	actual   = JSON_GetString(jsonID, "/results/amplitude VC/unit")
	CHECK_EQUAL_STR(actual, expected)

	value = JSON_GetVariable(jsonID, "/results/amplitude VC/value")
	CHECK_EQUAL_VAR(value, 789)

	expected = "mV"
	actual   = JSON_GetString(jsonID, "/results/delta V/unit")
	CHECK_EQUAL_STR(actual, expected)

	value = JSON_GetVariable(jsonID, "/results/delta V/value")
	CHECK_EQUAL_VAR(value, 0.5)

	JSON_Release(jsonID)
End

static Function CheckPipetteInBath()
	string device, expected, actual
	variable headstage, i, jsonID, value, sweepNo

	device    = "my_device"
	headstage = 0
	sweepNo   = 0

	// BEGIN required entries
	ED_AddEntryToLabnotebook(device, "Pipette in Bath Set QC", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1}, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(device, "Pipette in Bath Chk0 Leak Current BL QC", {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(device, "Pipette in Bath Chk0 Leak Current BL", {123, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, unit = "Amperes", overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(device, "Pipette in Bath pipette resistance", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 456}, unit = "Ω", overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(device, "Pipette in Bath pipette resistance QC", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1}, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)

	Make/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values = NaN
	Make/T/FREE/N=(3, 1, 1) keys

	values[headstage] = GetUniqueInteger()
	keys[0][0][0]     = STIMSET_ACQ_CYCLE_ID_KEY
	keys[2][0][0]     = "1"

	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)
	// END required entries

	MIES_PUB#PUB_PipetteInBath(device, sweepNo, headstage)

	jsonID = FetchAndParseMessage(ANALYSIS_FUNCTION_PB)

	expected = LABNOTEBOOK_BINARY_UNIT
	actual   = JSON_GetString(jsonID, "/results/USER_Pipette in Bath Set QC/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_Pipette in Bath Set QC/value")
	CHECK_EQUAL_WAVES(entries, {1}, mode = WAVE_DATA)

	expected = LABNOTEBOOK_BINARY_UNIT
	actual   = JSON_GetString(jsonID, "/results/USER_Pipette in Bath Chk0 Leak Current BL QC/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_Pipette in Bath Chk0 Leak Current BL QC/value")
	CHECK_EQUAL_WAVES(entries, {0}, mode = WAVE_DATA)

	expected = "Amperes"
	actual   = JSON_GetString(jsonID, "/results/USER_Pipette in Bath Chk0 Leak Current BL/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_Pipette in Bath Chk0 Leak Current BL/value")
	CHECK_EQUAL_WAVES(entries, {123}, mode = WAVE_DATA)

	expected = "Ω"
	actual   = JSON_GetString(jsonID, "/results/USER_Pipette in Bath pipette resistance/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_Pipette in Bath pipette resistance/value")
	CHECK_EQUAL_WAVES(entries, {456}, mode = WAVE_DATA)

	expected = LABNOTEBOOK_BINARY_UNIT
	actual   = JSON_GetString(jsonID, "/results/USER_Pipette in Bath pipette resistance QC/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_Pipette in Bath pipette resistance QC/value")
	CHECK_EQUAL_WAVES(entries, {1}, mode = WAVE_DATA)

	JSON_Release(jsonID)
End

static Function CheckSealEvaluation()
	string device, expected, actual
	variable headstage, i, jsonID, value, sweepNo

	device    = "my_device"
	headstage = 0
	sweepNo   = 0

	// BEGIN required entries
	ED_AddEntryToLabnotebook(device, "Seal evaluation Set QC", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1}, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(device, "Seal evaluation seal resistance max", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 123}, unit = "Ω", overrideSweepNo = sweepNo)

	Make/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values = NaN
	Make/T/FREE/N=(3, 1, 1) keys

	values[headstage] = GetUniqueInteger()
	keys[0][0][0]     = STIMSET_ACQ_CYCLE_ID_KEY
	keys[2][0][0]     = "1"

	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)
	// END required entries

	MIES_PUB#PUB_SealEvaluation(device, sweepNo, headstage)

	jsonID = FetchAndParseMessage(ANALYSIS_FUNCTION_SE)

	expected = LABNOTEBOOK_BINARY_UNIT
	actual   = JSON_GetString(jsonID, "/results/USER_Seal evaluation Set QC/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_Seal evaluation Set QC/value")
	CHECK_EQUAL_WAVES(entries, {1}, mode = WAVE_DATA)

	expected = "Ω"
	actual   = JSON_GetString(jsonID, "/results/USER_Seal evaluation seal resistance max/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_Seal evaluation seal resistance max/value")
	CHECK_EQUAL_WAVES(entries, {123}, mode = WAVE_DATA)

	JSON_Release(jsonID)
End

static Function CheckTrueRestMembPot()
	string device, expected, actual
	variable headstage, i, jsonID, value, sweepNo

	device    = "my_device"
	headstage = 0
	sweepNo   = 0

	// BEGIN required entries
	ED_AddEntryToLabnotebook(device, "True Rest Memb. Set QC", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1}, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(device, "True Rest Memb. Full Average", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 123}, unit = "Volt", overrideSweepNo = sweepNo)

	Make/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values = NaN
	Make/T/FREE/N=(3, 1, 1) keys

	values[headstage] = GetUniqueInteger()
	keys[0][0][0]     = STIMSET_ACQ_CYCLE_ID_KEY
	keys[2][0][0]     = "1"

	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)
	// END required entries

	MIES_PUB#PUB_TrueRestingMembranePotential(device, sweepNo, headstage)

	jsonID = FetchAndParseMessage(ANALYSIS_FUNCTION_VM)

	expected = LABNOTEBOOK_BINARY_UNIT
	actual   = JSON_GetString(jsonID, "/results/USER_True Rest Memb. Set QC/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_True Rest Memb. Set QC/value")
	CHECK_EQUAL_WAVES(entries, {1}, mode = WAVE_DATA)

	expected = "Volt"
	actual   = JSON_GetString(jsonID, "/results/USER_True Rest Memb. Full Average/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_True Rest Memb. Full Average/value")
	CHECK_EQUAL_WAVES(entries, {123}, mode = WAVE_DATA)

	JSON_Release(jsonID)
End

static Function CheckDAQStateChange_DAQ()
	string device, actual, expected
	variable headstage, i, jsonID, type

	device    = "my_device"
	headstage = 0

	MIES_PUB#PUB_DAQStateChange(device, DATA_ACQUISITION_MODE, 0, 1)

	jsonID = FetchAndParseMessage(DAQ_TP_STATE_CHANGE_FILTER)

	actual   = JSON_GetString(jsonID, "/daq")
	expected = "starting"
	CHECK_EQUAL_STR(actual, expected)

	type = JSON_GetType(jsonID, "/tp")
	CHECK_EQUAL_VAR(type, JSON_NULL)

	JSON_Release(jsonID)
End

static Function CheckDAQStateChange_TP()
	string device, actual, expected
	variable headstage, i, jsonID, type

	device    = "my_device"
	headstage = 0

	MIES_PUB#PUB_DAQStateChange(device, TEST_PULSE_MODE, 1, 0)

	jsonID = FetchAndParseMessage(DAQ_TP_STATE_CHANGE_FILTER)

	actual   = JSON_GetString(jsonID, "/tp")
	expected = "stopping"
	CHECK_EQUAL_STR(actual, expected)

	type = JSON_GetType(jsonID, "/daq")
	CHECK_EQUAL_VAR(type, JSON_NULL)

	JSON_Release(jsonID)
End

static Function CheckAccessResSmoke()
	string device, msg, expected, actual
	variable headstage, i, jsonID, value, sweepNo

	device    = "my_device"
	headstage = 0
	sweepNo   = 0

	// BEGIN required entries
	ED_AddEntryToLabnotebook(device, "Access Res. Smoke Set QC", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1}, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(device, "Access Res. Smoke access resistance", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 123}, unit = "Ω", overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(device, "Access Res. Smoke access resistance QC", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0}, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(device, "Access Res. Smoke access vs steady state ratio", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0.5}, overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(device, "Access Res. Smoke access vs steady state ratio QC", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1}, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)

	Make/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values = NaN
	Make/T/FREE/N=(3, 1, 1) keys

	values[headstage] = GetUniqueInteger()
	keys[0][0][0]     = STIMSET_ACQ_CYCLE_ID_KEY
	keys[2][0][0]     = "1"

	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)
	// END required entries

	MIES_PUB#PUB_AccessResistanceSmoke(device, sweepNo, headstage)

	msg = FetchPublishedMessage(ANALYSIS_FUNCTION_AR)

	jsonID = JSON_Parse(msg)

	expected = LABNOTEBOOK_BINARY_UNIT
	actual   = JSON_GetString(jsonID, "/results/USER_Access Res. Smoke Set QC/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_Access Res. Smoke Set QC/value")
	CHECK_EQUAL_WAVES(entries, {1}, mode = WAVE_DATA)

	expected = "Ω"
	actual   = JSON_GetString(jsonID, "/results/USER_Access Res. Smoke access resistance/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_Access Res. Smoke access resistance/value")
	CHECK_EQUAL_WAVES(entries, {123}, mode = WAVE_DATA)

	expected = LABNOTEBOOK_BINARY_UNIT
	actual   = JSON_GetString(jsonID, "/results/USER_Access Res. Smoke access resistance QC/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_Access Res. Smoke access resistance QC/value")
	CHECK_EQUAL_WAVES(entries, {0}, mode = WAVE_DATA)

	actual = JSON_GetString(jsonID, "/results/USER_Access Res. Smoke access vs steady state ratio/unit")
	CHECK_EMPTY_STR(actual)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_Access Res. Smoke access vs steady state ratio/value")
	CHECK_EQUAL_WAVES(entries, {0.5}, mode = WAVE_DATA)

	expected = LABNOTEBOOK_BINARY_UNIT
	actual   = JSON_GetString(jsonID, "/results/USER_Access Res. Smoke access vs steady state ratio QC/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_Access Res. Smoke access vs steady state ratio QC/value")
	CHECK_EQUAL_WAVES(entries, {1}, mode = WAVE_DATA)

	JSON_Release(jsonID)
End

static Function/WAVE PrepareTPData()

	WAVE tpData = GetTPAnalysisDataWave()
	tpData[%NOW]                   = 1E6
	tpData[%HEADSTAGE]             = 1
	tpData[%MARKER]                = 1234
	tpData[%NUMBER_OF_TP_CHANNELS] = 2
	tpData[%TIMESTAMP]             = 2E6
	tpData[%TIMESTAMPUTC]          = 3E6
	tpData[%CLAMPMODE]             = V_CLAMP_MODE
	tpData[%CLAMPAMP]              = 10
	tpData[%BASELINEFRAC]          = 0.35
	tpData[%CYCLEID]               = 456
	tpData[%TPLENGTHPOINTSADC]     = 1500
	tpData[%PULSELENGTHPOINTSADC]  = 500
	tpData[%PULSESTARTPOINTSADC]   = 500
	tpData[%SAMPLINGINTERVALADC]   = 0.002
	tpData[%TPLENGTHPOINTSDAC]     = 1800
	tpData[%PULSELENGTHPOINTSDAC]  = 600
	tpData[%PULSESTARTPOINTSDAC]   = 600
	tpData[%SAMPLINGINTERVALDAC]   = 0.002

	tpData[%BASELINE]       = 2
	tpData[%ELEVATED_SS]    = 10
	tpData[%ELEVATED_INST]  = 11
	tpData[%STEADYSTATERES] = 1234
	tpData[%INSTANTRES]     = 2345

	return tpData
End

static Function CheckTPData(variable jsonId)

	variable var
	string stv, daUnit, adUnit
	variable clampMode = V_CLAMP_MODE

	daUnit = GetDAChannelUnit(clampMode)
	adUnit = GetADChannelUnit(clampMode)

	var = JSON_GetVariable(jsonID, "/properties/tp marker")
	CHECK_EQUAL_VAR(var, 1234)
	var = JSON_GetVariable(jsonID, "/properties/headstage")
	CHECK_EQUAL_VAR(var, 1)
	stv = JSON_GetString(jsonID, "/properties/device")
	CHECK_EQUAL_STR(stv, "TestDevice")
	var = JSON_GetVariable(jsonID, "/properties/clamp mode")
	CHECK_EQUAL_VAR(var, clampMode)
	var = JSON_GetVariable(jsonID, "/properties/time of tp acquisition/value")
	CHECK_EQUAL_VAR(var, 1E6)
	stv = JSON_GetString(jsonID, "/properties/time of tp acquisition/unit")
	CHECK_EQUAL_STR(stv, "s")
	var = JSON_GetVariable(jsonID, "/properties/clamp amplitude/value")
	CHECK_EQUAL_VAR(var, 10)
	stv = JSON_GetString(jsonID, "/properties/clamp amplitude/unit")
	CHECK_EQUAL_STR(stv, daUnit)
	var = JSON_GetVariable(jsonID, "/properties/tp length ADC/value")
	CHECK_EQUAL_VAR(var, 1500)
	stv = JSON_GetString(jsonID, "/properties/tp length ADC/unit")
	CHECK_EQUAL_STR(stv, "points")
	var = JSON_GetVariable(jsonID, "/properties/pulse duration ADC/value")
	CHECK_EQUAL_VAR(var, 500)
	stv = JSON_GetString(jsonID, "/properties/pulse duration ADC/unit")
	CHECK_EQUAL_STR(stv, "points")
	var = JSON_GetVariable(jsonID, "/properties/pulse start point ADC/value")
	CHECK_EQUAL_VAR(var, 500)
	stv = JSON_GetString(jsonID, "/properties/pulse start point ADC/unit")
	CHECK_EQUAL_STR(stv, "point")
	var = JSON_GetVariable(jsonID, "/properties/sample interval ADC/value")
	CHECK_EQUAL_VAR(var, 0.002)
	stv = JSON_GetString(jsonID, "/properties/sample interval ADC/unit")
	CHECK_EQUAL_STR(stv, "ms")
	var = JSON_GetVariable(jsonID, "/properties/tp length DAC/value")
	CHECK_EQUAL_VAR(var, 1800)
	stv = JSON_GetString(jsonID, "/properties/tp length DAC/unit")
	CHECK_EQUAL_STR(stv, "points")
	var = JSON_GetVariable(jsonID, "/properties/pulse duration DAC/value")
	CHECK_EQUAL_VAR(var, 600)
	stv = JSON_GetString(jsonID, "/properties/pulse duration DAC/unit")
	CHECK_EQUAL_STR(stv, "points")
	var = JSON_GetVariable(jsonID, "/properties/pulse start point DAC/value")
	CHECK_EQUAL_VAR(var, 600)
	stv = JSON_GetString(jsonID, "/properties/pulse start point DAC/unit")
	CHECK_EQUAL_STR(stv, "point")
	var = JSON_GetVariable(jsonID, "/properties/sample interval DAC/value")
	CHECK_EQUAL_VAR(var, 0.002)
	stv = JSON_GetString(jsonID, "/properties/sample interval DAC/unit")
	CHECK_EQUAL_STR(stv, "ms")
	var = JSON_GetVariable(jsonID, "/properties/baseline fraction/value")
	CHECK_EQUAL_VAR(var, 35)
	stv = JSON_GetString(jsonID, "/properties/baseline fraction/unit")
	CHECK_EQUAL_STR(stv, "%")
	var = JSON_GetVariable(jsonID, "/properties/timestamp/value")
	CHECK_EQUAL_VAR(var, 2E6)
	stv = JSON_GetString(jsonID, "/properties/timestamp/unit")
	CHECK_EQUAL_STR(stv, "s")
	var = JSON_GetVariable(jsonID, "/properties/timestampUTC/value")
	CHECK_EQUAL_VAR(var, 3E6)
	stv = JSON_GetString(jsonID, "/properties/timestampUTC/unit")
	CHECK_EQUAL_STR(stv, "s")

	var = JSON_GetVariable(jsonID, "/properties/tp cycle id")
	CHECK_EQUAL_VAR(var, 456)

	var = JSON_GetVariable(jsonID, "/results/average baseline steady state/value")
	CHECK_EQUAL_VAR(var, 2)
	stv = JSON_GetString(jsonID, "/results/average baseline steady state/unit")
	CHECK_EQUAL_STR(stv, adUnit)
	var = JSON_GetVariable(jsonID, "/results/average tp steady state/value")
	CHECK_EQUAL_VAR(var, 10)
	stv = JSON_GetString(jsonID, "/results/average tp steady state/unit")
	CHECK_EQUAL_STR(stv, adUnit)
	var = JSON_GetVariable(jsonID, "/results/instantaneous/value")
	CHECK_EQUAL_VAR(var, 11)
	stv = JSON_GetString(jsonID, "/results/instantaneous/unit")
	CHECK_EQUAL_STR(stv, adUnit)
	var = JSON_GetVariable(jsonID, "/results/steady state resistance/value")
	CHECK_EQUAL_VAR(var, 1234)
	stv = JSON_GetString(jsonID, "/results/steady state resistance/unit")
	CHECK_EQUAL_STR(stv, "MΩ")
	var = JSON_GetVariable(jsonID, "/results/instantaneous resistance/value")
	CHECK_EQUAL_VAR(var, 2345)
	stv = JSON_GetString(jsonID, "/results/instantaneous resistance/unit")
	CHECK_EQUAL_STR(stv, "MΩ")
End

// IUTF_TD_GENERATOR DataGenerators#PUB_TPFilters
static Function CheckTPPublishing([string str])

	variable jsonId

	WAVE tpData = PrepareTPData()

	TUFXOP_Clear/Z/N=(str)
	PUB_TPResult("TestDevice", tpData)

	jsonId = FetchAndParseMessage(str)
	CheckTPData(jsonId)
	JSON_Release(jsonID)
End
