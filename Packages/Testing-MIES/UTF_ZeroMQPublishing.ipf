#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=ZeroMQPublishingTests

static Function TEST_CASE_BEGIN_OVERRIDE(string testname)

	AdditionalExperimentCleanup()

	StartZeroMQSockets(forceRestart = 1)

	zeromq_sub_add_filter("")
	zeromq_sub_connect("tcp://127.0.0.1:" + num2str(ZEROMQ_BIND_PUB_PORT))
End

static Function TEST_CASE_END_OVERRIDE(string testname)

	StartZeroMQSockets(forceRestart = 1)
	zeromq_sub_add_filter("")
End

Function CheckMessageFilters_IGNORE(string filter)
	WAVE/T/Z allFilters = FFI_GetAvailableMessageFilters()
	CHECK_WAVE(allFilters, TEXT_WAVE)

	FindValue/TXOP=4/TEXT=(filter) allFilters
	CHECK_GE_VAR(V_Value, 0)
End

static Function CheckPressureStatePublishing()
	string device, msg, filter, expected, actual
	variable headstage, i, jsonID

	WaitForPubSubHeartbeat()

	device = "my_device"
	headstage = 0

	MIES_P#P_PublishPressureMethodChange(device, headstage, PRESSURE_METHOD_ATM, PRESSURE_METHOD_APPROACH)

	for(i = 0; i < 100; i += 1)
		msg = zeromq_sub_recv(filter)

		if(!cmpstr(filter, PRESSURE_STATE_FILTER))
			break
		endif

		Sleep/S 0.1
	endfor

	expected = PRESSURE_STATE_FILTER
	actual   = filter
	CHECK_EQUAL_STR(actual, expected)
	CheckMessageFilters_IGNORE(expected)

	jsonID = JSON_Parse(msg)

	expected = MIES_P#P_PressureMethodToString(PRESSURE_METHOD_ATM)
	actual   = JSON_GetString(jsonID, "/pressure method/old")
	CHECK_EQUAL_STR(actual, expected)

	expected = MIES_P#P_PressureMethodToString(PRESSURE_METHOD_APPROACH)
	actual   = JSON_GetString(jsonID, "/pressure method/new")
	CHECK_EQUAL_STR(actual, expected)

	JSON_Release(jsonID)
End

static Function CheckPressureSealPublishing()
	string device, msg, filter, expected, actual
	variable headstage, i, jsonID, value

	WaitForPubSubHeartbeat()

	device = "my_device"
	headstage = 0

	MIES_P#P_PublishSealedState(device, headstage)

	for(i = 0; i < 100; i += 1)
		msg = zeromq_sub_recv(filter)

		if(!cmpstr(filter, PRESSURE_SEALED_FILTER))
			break
		endif

		Sleep/S 0.1
	endfor

	expected = PRESSURE_SEALED_FILTER
	actual   = filter
	CHECK_EQUAL_STR(actual, expected)
	CheckMessageFilters_IGNORE(expected)

	jsonID = JSON_Parse(msg)

	value = JSON_GetVariable(jsonID, "/sealed")
	CHECK_EQUAL_VAR(value, 1)

	JSON_Release(jsonID)
End

static Function CheckClampModePublishing()
	string device, msg, filter, expected, actual
	variable headstage, i, jsonID, value

	WaitForPubSubHeartbeat()

	device = "my_device"
	headstage = 0

	MIES_DAP#DAP_PublishClampModeChange(device, headstage, I_CLAMP_MODE, V_CLAMP_MODE)

	for(i = 0; i < 100; i += 1)
		msg = zeromq_sub_recv(filter)

		if(!cmpstr(filter, AMPLIFIER_CLAMP_MODE_FILTER))
			break
		endif

		Sleep/S 0.1
	endfor

	expected = AMPLIFIER_CLAMP_MODE_FILTER
	actual   = filter
	CHECK_EQUAL_STR(actual, expected)
	CheckMessageFilters_IGNORE(expected)

	jsonID = JSON_Parse(msg)

	expected = "I_CLAMP_MODE"
	actual   = JSON_GetString(jsonID, "/clamp mode/old")
	CHECK_EQUAL_STR(actual, expected)

	expected = "V_CLAMP_MODE"
	actual   = JSON_GetString(jsonID, "/clamp mode/new")
	CHECK_EQUAL_STR(actual, expected)

	JSON_Release(jsonID)
End

static Function CheckAutoBridgeBalancePublishing()
	string device, msg, filter, expected, actual
	variable headstage, i, jsonID, value

	WaitForPubSubHeartbeat()

	device = "my_device"
	headstage = 0

	MIES_AI#AI_PublishAutoBridgeBalance(device, headstage, 4711)

	for(i = 0; i < 100; i += 1)
		msg = zeromq_sub_recv(filter)

		if(!cmpstr(filter, AMPLIFIER_AUTO_BRIDGE_BALANCE))
			break
		endif

		Sleep/S 0.1
	endfor

	expected = AMPLIFIER_AUTO_BRIDGE_BALANCE
	actual   = filter
	CHECK_EQUAL_STR(actual, expected)
	CheckMessageFilters_IGNORE(expected)

	jsonID = JSON_Parse(msg)

	expected = "Ohm"
	actual   = JSON_GetString(jsonID, "/bridge balance resistance/unit")
	CHECK_EQUAL_STR(actual, expected)

	value = JSON_GetVariable(jsonID, "/bridge balance resistance/value")
	CHECK_EQUAL_VAR(value, 4711)

	JSON_Release(jsonID)
End

static Function CheckPressureBreakinPublishing()
	string device, msg, filter, expected, actual
	variable headstage, i, jsonID, value

	WaitForPubSubHeartbeat()

	device = "my_device"
	headstage = 0

	MIES_P#P_PublishBreakin(device, headstage)

	for(i = 0; i < 100; i += 1)
		msg = zeromq_sub_recv(filter)

		if(!cmpstr(filter, PRESSURE_BREAKIN_FILTER))
			break
		endif

		Sleep/S 0.1
	endfor

	expected = PRESSURE_BREAKIN_FILTER
	actual   = filter
	CHECK_EQUAL_STR(actual, expected)
	CheckMessageFilters_IGNORE(expected)

	jsonID = JSON_Parse(msg)

	value = JSON_GetVariable(jsonID, "/break in")
	CHECK_EQUAL_VAR(value, 1)

	JSON_Release(jsonID)
End

static Function CheckAutoTPPublishing()
	string device, msg, filter, expected, actual
	variable headstage, i, jsonID, value

	WaitForPubSubHeartbeat()

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

	MIES_TP#TP_PublishAutoTPResult(device, headstage, 1)

	for(i = 0; i < 100; i += 1)
		msg = zeromq_sub_recv(filter)

		if(!cmpstr(filter, AUTO_TP_FILTER))
			break
		endif

		Sleep/S 0.1
	endfor

	expected = AUTO_TP_FILTER
	actual   = filter
	CHECK_EQUAL_STR(actual, expected)
	CheckMessageFilters_IGNORE(expected)

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
