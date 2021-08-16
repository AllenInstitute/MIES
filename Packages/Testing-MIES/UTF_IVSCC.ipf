#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=IVSCCTesting

static Function TEST_BEGIN_OVERRIDE(string name)
	// do nothing
End

static Function TEST_CASE_BEGIN_OVERRIDE(string name)

	StartZeroMQSockets(forceRestart = 1)
	zeromq_sub_remove_filter("")
End

static Function TEST_CASE_END_OVERRIDE(string name)

	StartZeroMQSockets(forceRestart = 1)
	zeromq_sub_remove_filter("")
End

Function CheckThatPublishingWorks()
	string msg, filter, expected, actual
	variable found, i, jsonID

	zeromq_sub_add_filter("")
	zeromq_sub_connect("tcp://127.0.0.1:" + num2str(ZEROMQ_BIND_PUB_PORT))

	WaitForPubSubHeartbeat()

	MIES_IVSCC#IVS_PublishQCState(123, "some text")

	for(i = 0; i < 200; i += 1)
		msg = zeromq_sub_recv(filter)
		if(strlen(msg) > 0 || strlen(filter) > 0)
			expected = IVS_PUB_FILTER
			CHECK_EQUAL_STR(filter, expected)

			// {
			// "Description": "some text",
			// "Issuer": "CheckThatPublishingWorks",
			// "Value": 123
			// }
			jsonID = JSON_Parse(msg)
			expected = JSON_GetString(jsonID, "/Issuer")
			actual   = "CheckThatPublishingWorks"
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

	CHECK(found > 0)
End
