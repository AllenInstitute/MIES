#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=ZeroMQPublishingTests

static Function TEST_CASE_BEGIN_OVERRIDE(string testname)

	AdditionalExperimentCleanup()

	PrepareForPublishTest()
End

static Function CheckPressureState()
	string device, msg, expected, actual
	variable headstage, i, jsonID

	device = "my_device"
	headstage = 0

	MIES_PUB#PUB_PressureMethodChange(device, headstage, PRESSURE_METHOD_ATM, PRESSURE_METHOD_APPROACH)

	msg = FetchPublishedMessage(PRESSURE_STATE_FILTER)

	jsonID = JSON_Parse(msg)

	expected = P_PressureMethodToString(PRESSURE_METHOD_ATM)
	actual   = JSON_GetString(jsonID, "/pressure method/old")
	CHECK_EQUAL_STR(actual, expected)

	expected = P_PressureMethodToString(PRESSURE_METHOD_APPROACH)
	actual   = JSON_GetString(jsonID, "/pressure method/new")
	CHECK_EQUAL_STR(actual, expected)

	JSON_Release(jsonID)
End

static Function CheckPressureSeal()
	string device, msg, expected, actual
	variable headstage, i, jsonID, value

	device = "my_device"
	headstage = 0

	MIES_PUB#PUB_PressureSealedState(device, headstage)

	msg = FetchPublishedMessage(PRESSURE_SEALED_FILTER)

	jsonID = JSON_Parse(msg)

	value = JSON_GetVariable(jsonID, "/sealed")
	CHECK_EQUAL_VAR(value, 1)

	JSON_Release(jsonID)
End

static Function CheckClampMode()
	string device, msg, expected, actual
	variable headstage, i, jsonID, value

	device = "my_device"
	headstage = 0

	MIES_PUB#PUB_ClampModeChange(device, headstage, I_CLAMP_MODE, V_CLAMP_MODE)

	msg = FetchPublishedMessage(AMPLIFIER_CLAMP_MODE_FILTER)

	jsonID = JSON_Parse(msg)

	expected = "I_CLAMP_MODE"
	actual   = JSON_GetString(jsonID, "/clamp mode/old")
	CHECK_EQUAL_STR(actual, expected)

	expected = "V_CLAMP_MODE"
	actual   = JSON_GetString(jsonID, "/clamp mode/new")
	CHECK_EQUAL_STR(actual, expected)

	JSON_Release(jsonID)
End

static Function CheckAutoBridgeBalance()
	string device, msg, expected, actual
	variable headstage, i, jsonID, value

	device = "my_device"
	headstage = 0

	MIES_PUB#PUB_AutoBridgeBalance(device, headstage, 4711)

	msg = FetchPublishedMessage(AMPLIFIER_AUTO_BRIDGE_BALANCE)

	jsonID = JSON_Parse(msg)

	expected = "Ohm"
	actual   = JSON_GetString(jsonID, "/bridge balance resistance/unit")
	CHECK_EQUAL_STR(actual, expected)

	value = JSON_GetVariable(jsonID, "/bridge balance resistance/value")
	CHECK_EQUAL_VAR(value, 4711)

	JSON_Release(jsonID)
End

static Function CheckPressureBreakin()
	string device, msg
	variable headstage, i, jsonID, value

	device = "my_device"
	headstage = 0

	MIES_PUB#PUB_PressureBreakin(device, headstage)

	msg = FetchPublishedMessage(PRESSURE_BREAKIN_FILTER)

	jsonID = JSON_Parse(msg)

	value = JSON_GetVariable(jsonID, "/break in")
	CHECK_EQUAL_VAR(value, 1)

	JSON_Release(jsonID)
End

static Function CheckAutoTP()
	string device, msg, expected, actual
	variable headstage, i, jsonID, value

	device = "my_device"
	headstage = 0

	// BEGIN required entries
	WAVE TPStorage = GetTPstorage(device)

	TPStorage[0][headstage][%AutoTPDeltaV] = 0.5
	SetNumberInWaveNote(TPStorage, NOTE_INDEX, 1)

	// Fake TPSettings to avoid GUI calls
	DFREF dfr = GetDeviceTestPulse(device)
	WAVE TPsettings = GetTPSettingsFree()
	MIES_WAVEGETTERS#SetWaveVersion(TPSettings, 2)
	MoveWave TPSettings, dfr:settings

	TPSettings[%baselinePerc][INDEP_HEADSTAGE] = 123
	TPSettings[%amplitudeIC][headstage]        = 456
	TPSettings[%amplitudeVC][headstage]        = 789

	// END required entries

	MIES_PUB#PUB_AutoTPResult(device, headstage, 1)

	msg = FetchPublishedMessage(AUTO_TP_FILTER)

	jsonID = JSON_Parse(msg)

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
	string device, msg, expected, actual
	variable headstage, i, jsonID, value, sweepNo

	device = "my_device"
	headstage = 0
	sweepNo = 0

	// BEGIN required entries
	ED_AddEntryToLabnotebook(device, "Pipette in Bath Set QC", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1}, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(device, "Pipette in Bath Chk0 Leak Current BL QC", {0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(device, "Pipette in Bath Chk0 Leak Current BL", {123, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, unit = "Amperes", overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(device, "Pipette in Bath pipette resistance", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 456}, unit = "Ω", overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(device, "Pipette in Bath pipette resistance QC", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1}, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)

	Make/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values = NaN
	Make/T/FREE/N=(3, 1, 1) keys

	values[headstage] = GetUniqueInteger()
	keys[0][0][0] = STIMSET_ACQ_CYCLE_ID_KEY
	keys[2][0][0] = "1"

	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)
	// END required entries

	MIES_PUB#PUB_PipetteInBath(device, sweepNo, headstage)

	msg = FetchPublishedMessage(ANALYSIS_FUNCTION_PB)

	jsonID = JSON_Parse(msg)

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
	actual = JSON_GetString(jsonID, "/results/USER_Pipette in Bath pipette resistance/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_Pipette in Bath pipette resistance/value")
	CHECK_EQUAL_WAVES(entries, {456}, mode = WAVE_DATA)

	expected = LABNOTEBOOK_BINARY_UNIT
	actual = JSON_GetString(jsonID, "/results/USER_Pipette in Bath pipette resistance QC/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_Pipette in Bath pipette resistance QC/value")
	CHECK_EQUAL_WAVES(entries, {1}, mode = WAVE_DATA)

	JSON_Release(jsonID)
End

static Function CheckSealEvaluation()
	string device, msg, expected, actual
	variable headstage, i, jsonID, value, sweepNo

	device = "my_device"
	headstage = 0
	sweepNo = 0

	// BEGIN required entries
	ED_AddEntryToLabnotebook(device, "Seal evaluation Set QC", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1}, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(device, "Seal evaluation seal resistance max", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 123}, unit = "Ω", overrideSweepNo = sweepNo)

	Make/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values = NaN
	Make/T/FREE/N=(3, 1, 1) keys

	values[headstage] = GetUniqueInteger()
	keys[0][0][0] = STIMSET_ACQ_CYCLE_ID_KEY
	keys[2][0][0] = "1"

	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)
	// END required entries

	MIES_PUB#PUB_SealEvaluation(device, sweepNo, headstage)

	msg = FetchPublishedMessage(ANALYSIS_FUNCTION_SE)

	jsonID = JSON_Parse(msg)

	expected = LABNOTEBOOK_BINARY_UNIT
	actual   = JSON_GetString(jsonID, "/results/USER_Seal evaluation Set QC/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_Seal evaluation Set QC/value")
	CHECK_EQUAL_WAVES(entries, {1}, mode = WAVE_DATA)

	expected = "Ω"
	actual = JSON_GetString(jsonID, "/results/USER_Seal evaluation seal resistance max/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_Seal evaluation seal resistance max/value")
	CHECK_EQUAL_WAVES(entries, {123}, mode = WAVE_DATA)

	JSON_Release(jsonID)
End

static Function CheckTrueRestMembPot()
	string device, msg, expected, actual
	variable headstage, i, jsonID, value, sweepNo

	device = "my_device"
	headstage = 0
	sweepNo = 0

	// BEGIN required entries
	ED_AddEntryToLabnotebook(device, "True Rest Memb. Set QC", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1}, unit = LABNOTEBOOK_BINARY_UNIT, overrideSweepNo = sweepNo)
	ED_AddEntryToLabnotebook(device, "True Rest Memb. Full Average", {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 123}, unit = "Volt", overrideSweepNo = sweepNo)

	Make/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) values = NaN
	Make/T/FREE/N=(3, 1, 1) keys

	values[headstage] = GetUniqueInteger()
	keys[0][0][0] = STIMSET_ACQ_CYCLE_ID_KEY
	keys[2][0][0] = "1"

	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)
	// END required entries

	MIES_PUB#PUB_TrueRestingMembranePotential(device, sweepNo, headstage)

	msg = FetchPublishedMessage(ANALYSIS_FUNCTION_VM)

	jsonID = JSON_Parse(msg)

	expected = LABNOTEBOOK_BINARY_UNIT
	actual   = JSON_GetString(jsonID, "/results/USER_True Rest Memb. Set QC/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_True Rest Memb. Set QC/value")
	CHECK_EQUAL_WAVES(entries, {1}, mode = WAVE_DATA)

	expected = "Volt"
	actual = JSON_GetString(jsonID, "/results/USER_True Rest Memb. Full Average/unit")
	CHECK_EQUAL_STR(actual, expected)

	WAVE/Z entries = JSON_GetWave(jsonID, "/results/USER_True Rest Memb. Full Average/value")
	CHECK_EQUAL_WAVES(entries, {123}, mode = WAVE_DATA)

	JSON_Release(jsonID)
End

static Function CheckIVSCC()
	string msg, filter, expected, actual
	variable found, i, jsonID

	MIES_PUB#PUB_IVS_QCState(123, "some text")

	for(i = 0; i < 200; i += 1)
		msg = zeromq_sub_recv(filter)
		if(strlen(msg) > 0 || strlen(filter) > 0)
			expected = IVS_PUB_FILTER
			CHECK_EQUAL_STR(filter, expected)

			jsonID = JSON_Parse(msg)
			expected = JSON_GetString(jsonID, "/Issuer")
			actual   = "CheckIVSCC"
			CHECK_EQUAL_STR(actual, expected)

			expected = JSON_GetString(jsonID, "/Description")
			actual   = "some text"
			CHECK_EQUAL_STR(actual, expected)

			CHECK_EQUAL_VAR(JSON_GetVariable(jsonID, "/Value"), 123)

			found += 1
			break
		endif

		Sleep/S 0.1
	endfor

	CHECK_GT_VAR(found, 0)
End
