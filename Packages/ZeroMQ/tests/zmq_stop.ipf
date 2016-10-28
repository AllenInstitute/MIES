#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=zmq_stop

Function WorksWithoutConnections()

	variable ret

	ret = zeromq_stop()
	CHECK_EQUAL_VAR(ret, 0)
End

Function StopsBinds()

	variable ret

	ret = zeromq_server_bind("tcp://127.0.0.1:5555")
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 1)

	ret = zeromq_stop()
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 0)
End

Function StopsConnections()

	variable ret

	ret = zeromq_server_bind("tcp://127.0.0.1:5555")
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 1)

	ret = zeromq_client_connect("tcp://127.0.0.1:5555")

	ret = zeromq_stop()
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 0)
	/// @todo how to check that the connections are closed?
End
