#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=PressureTests

static Function TEST_CASE_BEGIN_OVERRIDE(string testname)

	StartZeroMQSockets(forceRestart = 1)

	zeromq_sub_add_filter("")
	zeromq_sub_connect("tcp://127.0.0.1:" + num2str(ZEROMQ_BIND_PUB_PORT))
End

static Function TEST_CASE_END_OVERRIDE(string testname)

	StartZeroMQSockets(forceRestart = 1)
	zeromq_sub_add_filter("")
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

	jsonID = JSON_Parse(msg)

	expected = MIES_P#P_PressureMethodToString(PRESSURE_METHOD_ATM)
	actual   = JSON_GetString(jsonID, "/pressure method/old")
	CHECK_EQUAL_STR(actual, expected)

	expected = MIES_P#P_PressureMethodToString(PRESSURE_METHOD_APPROACH)
	actual   = JSON_GetString(jsonID, "/pressure method/new")
	CHECK_EQUAL_STR(actual, expected)

	JSON_Release(jsonID)
End
