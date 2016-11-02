#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=zmq_handler_start

Function ComplainsWithNoBind()

	variable err, ret

	try
		ret = zeromq_handler_start(); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		CheckErrorMessage(err, ZeroMQ_HANDLER_NO_CONNECTION)
	endtry

	CHECK_EQUAL_VAR(ret, 0)
End

Function ComplainsWithConnectInsteadBind()

	variable err, ret

	zeromq_client_connect("tcp://127.0.0.1:5555")

	try
		ret = zeromq_handler_start(); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		CheckErrorMessage(err, ZeroMQ_HANDLER_NO_CONNECTION)
	endtry

	CHECK_EQUAL_VAR(ret, 0)
End

Function StartsWithBind()

	variable err, ret

	zeromq_server_bind("tcp://127.0.0.1:5555")
	ret = zeromq_handler_start()

	CHECK_EQUAL_VAR(ret, 0)
End

Function CannotStartTwice()

	variable err, ret

	zeromq_server_bind("tcp://127.0.0.1:5555")
	ret = zeromq_handler_start()
	CHECK_EQUAL_VAR(ret, 0)

	try
		ret = zeromq_handler_start(); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		CheckErrorMessage(err, ZeroMQ_HANDLER_ALREADY_RUNNING)
	endtry

	CHECK_EQUAL_VAR(ret, 0)
End

Function ComplainsImmediatelyOnErrors()

	variable err, ret, errorValue
	string replyMessage

	zeromq_server_bind("tcp://127.0.0.1:5555")
	zeromq_client_connect("tcp://127.0.0.1:5555")

	ret = zeromq_handler_start()
	CHECK_EQUAL_VAR(ret, 0)

	zeromq_client_send("garbage")
	replyMessage = zeromq_client_recv()

	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_JSON_OBJECT)

	CHECK_EQUAL_VAR(ret, 0)
End

Function CallsFunctionsAtIdleEventOnly()

	variable err, ret, errorValue, resultVariable
	variable expected
	string replyMessage

	string msg = "{                    " + \
	"\"version\" : 1,                  " + \
	 "\"CallFunction\" : {             " + \
	   "\"name\" : \"FunctionToCall\"  " + \
	"}                                 " + \
	"}"

	zeromq_stop()
	zeromq_server_bind("tcp://127.0.0.1:5555")
	zeromq_client_connect("tcp://127.0.0.1:5555")

	ret = zeromq_handler_start()
	CHECK_EQUAL_VAR(ret, 0)

	zeromq_client_send(msg)
	// the json message is now in the internal message queue and
	// will be processed at the next idle event
	// zeromq_recv will also create idle events while waiting
	replyMessage = zeromq_client_recv()

	print replyMessage

	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVariable)
	expected = FunctionToCall()
	CHECK_EQUAL_VAR(resultVariable, expected)

	CHECK_EQUAL_VAR(ret, 0)
End
