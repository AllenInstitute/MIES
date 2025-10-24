#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_MIES_ZeroMQ

static Function TEST_CASE_BEGIN_OVERRIDE(string name)

	variable flags

	TestCaseBeginCommon(name)

	flags = GetZeroMQXOPFlags()
	zeromq_set(flags)
End

static Function TestInterceptor()

	string inputMsg, backMsg, header
	variable jsonId, errorCode, flags

	// by default the interceptor is enabled

	inputMsg = "{"                                     \
	           + "\"version\" : 1,"                    \
	           + "\"CallFunction\" : {"                \
	           + "\"name\" : \"Getstacktraceheader\"," \
	           + "\"params\" : []"                     \
	           + "}"                                   \
	           + "}"

	backMsg = zeromq_test_callfunction(inputMsg)

	jsonID = JSON_Parse(backmsg, ignoreErr = 1)
	CHECK(JSON_IsValid(jsonID))

	errorCode = JSON_GetVariable(jsonID, "/errorCode/value")
	CHECK_EQUAL_VAR(errorCode, REQ_SUCCESS)

	header = JSON_GetString(jsonID, "/result/value")
	CHECK_EQUAL_STR(header, "Stacktrace (ZeroMQ XOP IDLE event call from \"\" with payload \"{\"name\":\"Getstacktraceheader\",\"params\":[]}\")")

	// and if we disable the interceptor
	flags = ClearBit(GetZeroMQXOPFlags(), ZeroMQ_SET_FLAGS_INTERCEPTOR)
	zeromq_set(flags)

	backMsg = zeromq_test_callfunction(inputMsg)

	jsonID = JSON_Parse(backmsg, ignoreErr = 1)
	CHECK(JSON_IsValid(jsonID))

	errorCode = JSON_GetVariable(jsonID, "/errorCode/value")
	CHECK_EQUAL_VAR(errorCode, REQ_SUCCESS)

	// we get the default stacktrace header
	header = JSON_GetString(jsonID, "/result/value")
	CHECK_EQUAL_STR(header, "Stacktrace")
End
