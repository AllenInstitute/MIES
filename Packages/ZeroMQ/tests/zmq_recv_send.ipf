#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=zmq_recv_send

Function ComplainsOnMultiMessageAsClient()

	variable err, ret, rc

	rc = zeromq_server_bind("tcp://127.0.0.1:5555")
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 1)

	zeromq_client_connect("tcp://127.0.0.1:5555")

	zeromq_test_sendMultiMsg(1)

	try
		zeromq_recv(0); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		CheckErrorMessage(err, ZMQ_INVALID_MULTIPART_MSG)
	endtry

	CHECK_EQUAL_VAR(ret, 0)
End

Function ComplainsOnMultiMessageAsServer()

	variable err, ret, rc

	rc = zeromq_server_bind("tcp://127.0.0.1:5555")
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 1)

	zeromq_client_connect("tcp://127.0.0.1:5555")

	zeromq_client_send("garbage")
	zeromq_recv(0)
	zeromq_test_sendMultiMsg(0)

	try
		zeromq_recv(1); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		CheckErrorMessage(err, ZMQ_INVALID_MULTIPART_MSG)
	endtry

	CHECK_EQUAL_VAR(ret, 0)
End
