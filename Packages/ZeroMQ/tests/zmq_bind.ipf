#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=zqm_bind

Function ComplainsWithInvalidArg1()

	variable err, ret

	try
		ret = zeromq_server_bind(""); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		CheckErrorMessage(err, ZeroMQ_INVALID_ARG)
	endtry

	CHECK_EQUAL_VAR(ret, 0)
End

Function ComplainsWithInvalidArg2()

	variable err, ret

	try
		ret = zeromq_server_bind("abcd:1234"); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		CheckErrorMessage(err, ZeroMQ_INVALID_ARG)
	endtry

	CHECK_EQUAL_VAR(ret, 0)
End

// bind does not accept names
Function ComplainsWithInvalidArg3()

	variable err, ret

	try
		ret = zeromq_server_bind("tcp://localhost:5555"); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		CheckErrorMessage(err, ZeroMQ_INVALID_ARG)
	endtry

	CHECK_EQUAL_VAR(ret, 0)
End

Function BindsToLocalHost()

	variable ret

	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 0)
	ret = zeromq_server_bind("tcp://127.0.0.1:5555")
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 1)
End

Function BindsToLocalHostIPV6()

	variable ret

	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 0)
	zeromq_set(ZeroMQ_SET_FLAGS_IPV6)
	ret = zeromq_server_bind("tcp://::1:5555")
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 1)
End

Function BindsToLocalHostIPV6AndIPV4()

	variable ret

	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 0)
	ret = zeromq_server_bind("tcp://127.0.0.1:5555")
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 1)
	// the ipv6 flag juggling is required due to https://github.com/zeromq/libzmq/issues/853
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(6666), 0)
	zeromq_set(ZeroMQ_SET_FLAGS_IPV6)
	ret = zeromq_server_bind("tcp://::1:6666")
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(6666), 1)
End

Function ComplainsOnBindOnUsedPort()

	variable err, ret

	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 0)
	ret = zeromq_server_bind("tcp://127.0.0.1:5555")
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 1)

	try
		ret = zeromq_server_bind("tcp://127.0.0.1:5555"); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		CheckErrorMessage(err, ZeroMQ_INVALID_ARG)
	endtry
End

Function AllowsBindingMultiplePorts()

	variable err, ret

	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 0)
	ret = zeromq_server_bind("tcp://127.0.0.1:5555")
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 1)

	ret = zeromq_server_bind("tcp://127.0.0.1:6666")
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(6666), 1)
End

Function DoesNotAcceptLargeMessages()

	variable err, ret, rc, i
	string identity, reply
	string msg = ""

	zeromq_set(ZeroMQ_SET_FLAGS_DEFAULT | ZeroMQ_SET_FLAGS_NOBUSYWAITRECV)

	rc = zeromq_server_bind("tcp://127.0.0.1:5555")
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_EQUAL_VAR(GetListeningStatus_IGNORE(5555), 1)

	zeromq_client_connect("tcp://127.0.0.1:5555")

	msg = PadString(msg, 1e6, 0x20)

	zeromq_client_send(msg)

	for(i = 0; i < 100; i += 1)
		reply = zeromq_server_recv(identity)
		CHECK_EQUAL_VAR(strlen(identity), 0)
		CHECK_EQUAL_VAR(strlen(reply), 0)
	endfor
End
