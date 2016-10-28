#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=zmq_connect

static Function ComplainsWithInvalidArg1()

	variable err, ret

	try
		ret = zeromq_client_connect(""); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		CheckErrorMessage(err, ZeroMQ_INVALID_ARG)
	endtry

	CHECK_EQUAL_VAR(ret, 0)
End

static Function ComplainsWithInvalidArg2()

	variable err, ret

	try
		ret = zeromq_client_connect("abcd:1234"); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		CheckErrorMessage(err, ZeroMQ_INVALID_ARG)
	endtry

	CHECK_EQUAL_VAR(ret, 0)
End

Function ConnectionsAcceptsHostName()

	variable ret
	ret = zeromq_client_connect("tcp://localhost:5555")
	CHECK_EQUAL_VAR(ret, 0)
End

Function ConnectionOrderDoesNotMatter1()

	variable ret
	ret = zeromq_client_connect("tcp://127.0.0.1:5555")
	CHECK_EQUAL_VAR(ret, 0)

	ret = zeromq_server_bind("tcp://127.0.0.1:5555")
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 1)
End

Function ConnectionOrderDoesNotMatter2()

	variable ret
	ret = zeromq_server_bind("tcp://127.0.0.1:5555")
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 1)

	ret = zeromq_client_connect("tcp://127.0.0.1:5555")
	CHECK_EQUAL_VAR(ret, 0)
End

Function AllowsMultipleConnections()

	variable ret
	ret = zeromq_client_connect("tcp://127.0.0.1:5555")
	CHECK_EQUAL_VAR(ret, 0)

	ret = zeromq_client_connect("tcp://127.0.0.1:6666")
	CHECK_EQUAL_VAR(ret, 0)
End
