#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=zmq_test_callfunction

Function ComplainsWithInvalidJSON1()

	string msg
	string replyMessage
	variable errorValue

	msg = ""
	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_JSON_OBJECT)
End

Function ComplainsWithInvalidJSON2()

	string msg
	string replyMessage
	variable errorValue

	msg = "abcd"
	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_JSON_OBJECT)
End

Function ComplainsWithInvalidVersion1()

	string msg
	string replyMessage
	variable errorValue

	msg = "{}"
	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_VERSION)
End

Function ComplainsWithInvalidVersion2()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 0}"
	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_VERSION)
End

Function ComplainsWithInvalidVersion3()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 2}"
	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_VERSION)
End

Function ComplainsWithInvalidVersion4()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1.1}"
	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_VERSION)
End

Function ComplainsWithInvalidMessageID1()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1, \"messageID\" : null }"
	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_MESSAGEID)
End

Function ComplainsWithInvalidMessageId2()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1, \"messageID\" : \"\"}"
	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_MESSAGEID)
End

Function ComplainsWithInvalidMessageID3()

	string msg
	string messageID = ""
	string replyMessage
	variable errorValue

	messageID = PadString(messageID, 256, 0x20)

	sprintf msg, "{\"version\" : 1, \"messageID\" : \"%s\"}", messageID
	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_MESSAGEID)
End

Function ComplainsWithInvalidOperation()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1,"                + \
		  "\"unknownOperation\" : \"blah\"}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_OPERATION)
End

Function ComplainsWithInvalidOp1()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1,"                + \
		  "\"CallFunction\" : 4711}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_OPERATION)
End

Function ComplainsWithInvalidOp2()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1,"                + \
		  "\"CallFunction\" : \"blah\"}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_OPERATION)
End

Function ComplainsWithInvalidOpFmt1()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1, "                + \
		  "\"CallFunction\" : {"              + \
		  " \"notName\" : \"a\"}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_OPERATION_FORMAT)
End

Function ComplainsWithInvalidOpFmt2()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1, "                + \
		  "\"CallFunction\" : {"              + \
		  " \"name\" : 1.5}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_OPERATION_FORMAT)
End

Function ComplainsWithInvalidOpFmt3()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1, "                + \
		  "\"CallFunction\" : {"              + \
		  "\"name\"      : \"TestFunctionNoArgs\"," +\
		  "\"notParams\" : \"\"}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_OPERATION_FORMAT)
End

Function ComplainsWithInvalidOpFmt4()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1, "                + \
		  "\"CallFunction\" : {"              + \
		  "\"name\"   : \"TestFunctionNoArgs\"," +\
		  "\"params\" : 1}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_PARAM_FORMAT)
End

Function ComplainsWithInvalidParamsObj()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1, "                + \
		  "\"CallFunction\" : {"              + \
		  "\"name\" : \"TestFunction1Arg\","  + \
		  "\"params\" : [1, { \"type\" : 1}]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_PARAM_FORMAT)
End

// procedures not compiled is not tested as I don't know how...

Function ComplainsWithWrongNumObjects()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1, "                + \
		  "\"CallFunction\" : {"              + \
		  "\"name\" : 1, \"blah\" : 2, \"blub\" : 3}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_OPERATION_FORMAT)
End

Function ComplainsWithEmptyFunctionName()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1, "                + \
		  "\"CallFunction\" : {"              + \
		  "\"name\" : \"\"}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_NON_EXISTING_FUNCTION)
End

Function ComplainsWithNonExistFunction()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1, "                + \
		  "\"CallFunction\" : {"              + \
		  "\"name\" : \"FUNCTION_I_DONT_EXIST\"}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_NON_EXISTING_FUNCTION)
End

Function ComplainsWithTooFewParameters()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1, "                + \
		  "\"CallFunction\" : {"              + \
		  "\"name\" : \"TestFunction2Args\"," +\
		  "\"params\" : [1]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_TOO_FEW_FUNCTION_PARAMS)
End

Function ComplainsWithTooManyParameters()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1, "                + \
		  "\"CallFunction\" : {"              + \
		  "\"name\" : \"TestFunction1Arg\","  + \
		  "\"params\" : [1, 2]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_TOO_MANY_FUNCTION_PARAMS)
End

Function ComplainsWithInvalidFuncSig1()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1, "                + \
		  "\"CallFunction\" : {"              + \
		  "\"name\" : \"TestFunctionInvalidSig1\","  + \
		  "\"params\" : [\"blah\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_UNSUPPORTED_FUNC_SIG)
End

Function ComplainsWithInvalidFuncRet2()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\" : 1, "                + \
		  "\"CallFunction\" : {"              + \
		  "\"name\" : \"TestFunctionInvalidRet2\"}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_UNSUPPORTED_FUNC_RET)
End

Function ComplainsWithGarbageInParams()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunction1Arg\"," + \
		  "\"params\"       : [\"1.a\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_PARAM_FORMAT)
End

Function ComplainsWithInternalFunction()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"cos\"," + \
		  "\"params\"       : [1]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_NON_EXISTING_FUNCTION)
End

Function WorksWithFuncNoArgs()

	string msg
	string replyMessage
	variable errorValue

	msg = "{\"version\"     : 1, "                    + \
		  "\"CallFunction\" : {"                      + \
		  "\"name\"         : \"TestFunctionNoArgs\"" + \
		  "}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)
End

Function WorksWithFunc1ArgAndOpt()

	string msg
	string replyMessage
	variable errorValue, resultVariable

	msg = "{\"version\"     : 1, "                    + \
		  "\"CallFunction\" : {"                      + \
		  "\"name\"         : \"TestFunction1ArgAndOpt\"," + \
		  " \"params\" : [1]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVariable)
	CHECK_EQUAL_VAR(resultVariable, 1)
End

Function WorksWithFunc2Vars()

	string msg
	variable expected
	string replyMessage, resultString
	variable errorValue, resultVar

	msg = "{\"version\" : 1, "                + \
		  "\"CallFunction\" : {"              + \
		  "\"name\" : \"TestFunction2Args\"," +\
		  "\"params\" : [1, 2]}}"

	replyMessage = zeromq_test_callfunction(msg)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVar)
	expected = 1 + 2
	CHECK_EQUAL_VAR(resultVar, expected)
End

Function WorksWithFunc2Strings()

	string msg, expected
	string replyMessage, resultString
	variable errorValue

	msg = "{\"version\" : 1, "                + \
		  "\"CallFunction\" : {"              + \
		  "\"name\" : \"TestFunction2ArgsString\"," +\
		  "\"params\" : [\"1\", \"2\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, str=resultString)
	expected = "1_2"
	CHECK_EQUAL_STR(resultString, expected)
End

Function WorksWithFuncStrVarStr()

	string msg, expected
	string replyMessage, resultString
	variable errorValue

	msg = "{\"version\" : 1, "                + \
		  "\"CallFunction\" : {"              + \
		  "\"name\" : \"TestFunctionStrVarStr\"," +\
		  "\"params\" : [\"1\", 2, \"3\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, str=resultString)
	expected = "1_2_3"
	CHECK_EQUAL_STR(resultString, expected)
End

Function WorksWithFuncVarArgAsStr()

	string msg
	string replyMessage
	variable errorValue, resultVariable

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunction1Arg\"," + \
		  "\"params\"       : [\"1\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVariable)
	CHECK_EQUAL_VAR(resultVariable, 1)
End

Function ComplainsWithNonStringNaN()

	string msg
	string replyMessage
	variable errorValue, resultVariable

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunction1Arg\"," + \
		  "\"params\"       : [NaN]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_INVALID_JSON_OBJECT)
End

Function WorksWithFuncVarArgAsInfPlus1()

	string msg
	string replyMessage
	variable errorValue, resultVariable

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunction1Arg\"," + \
		  "\"params\"       : [\"+INF\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVariable)
	CHECK_EQUAL_VAR(resultVariable, Inf)
End

Function WorksWithFuncVarArgAsInfPlus2()

	string msg
	string replyMessage
	variable errorValue, resultVariable

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunction1Arg\"," + \
		  "\"params\"       : [\"+inf\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVariable)
	CHECK_EQUAL_VAR(resultVariable, Inf)
End

Function WorksWithFuncVarArgAsInfPlus3()

	string msg
	string replyMessage
	variable errorValue, resultVariable

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunction1Arg\"," + \
		  "\"params\"       : [\"inf\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVariable)
	CHECK_EQUAL_VAR(resultVariable, Inf)
End

Function WorksWithFuncVarArgAsInfMinus()

	string msg
	string replyMessage
	variable errorValue, resultVariable

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunction1Arg\"," + \
		  "\"params\"       : [\"-inf\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVariable)
	CHECK_EQUAL_VAR(resultVariable, -Inf)
End

Function WorksWithFuncVarArgAsNaN()

	string msg
	string replyMessage
	variable errorValue, resultVariable

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunction1Arg\"," + \
		  "\"params\"       : [\"naN\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVariable)
	CHECK_EQUAL_VAR(resultVariable, NaN)
End

Function WorksWithFuncVarArgAsVar()

	string msg
	string replyMessage
	variable errorValue, resultVariable

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunction1Arg\"," + \
		  "\"params\"       : [1]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVariable)
	CHECK_EQUAL_VAR(resultVariable, 1)
End

Function WorksWithFuncVarArgAsBoolean()

	string msg
	string replyMessage
	variable errorValue, resultVariable

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunction1Arg\"," + \
		  "\"params\"       : [true]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVariable)
	CHECK_EQUAL_VAR(resultVariable, 1)
End

Function WorksWithFuncVarArgAndFullPrec()

	string msg
	string replyMessage
	variable errorValue, resultVariable

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunction1Arg\"," + \
		  "\"params\"       : [1.23456789101112]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVariable)
	CHECK_EQUAL_VAR(resultVariable, 1.23456789101112)
End

Function WorksWithFuncStrArg1()

	string msg
	string replyMessage
	variable errorValue
	string resultString, expected

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunction1StrArg\"," + \
		  "\"params\"       : [\"hi\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, str=resultString)
	expected = "prefix__hi__suffix"
	CHECK_EQUAL_STR(resultString, expected)
End

Function DoesNotHaveMemLeaksReturnString()
	variable i, errorValue, memBefore, memAfter

	string replyMessage
	string contents = ""

	zeromq_set(ZeroMQ_SET_FLAGS_DEFAULT)

	contents = PadString(contents, 1e6, 0x20)

	string msg = "{\"version\"     : 1, "         + \
	"\"CallFunction\" : {"                        + \
	"\"name\"         : \"TestFunction1StrArg\"," + \
	"\"params\"       : [\"" + contents + "\"]}}"

	memBefore = NumberByKey("USEDPHYSMEM", IgorInfo(0))

	for(i = 0; i < 50; i++)
		replyMessage = zeromq_test_callfunction(msg)
		errorValue = ExtractErrorValue(replyMessage)
		CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)
	endfor

	memAfter = NumberByKey("USEDPHYSMEM", IgorInfo(0))

	CHECK(memAfter < memBefore * 1.15)
End

Function WorksWithFuncNullWaveReturn()

	string msg
	string replyMessage
	variable errorValue
	string expected
	STRUCT WaveProperties s

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionReturnNullWave\"" + \
		  "}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, wvProp=s)
	CHECK(!WaveExists(s.raw))
	CHECK(!WaveExists(s.dimensions))
	CHECK_EQUAL_VAR(numtype(s.modificationDate), 2)
End

Function WorksWithFuncReturnPermWave()

	string msg, replyMessage, expected
	variable errorValue
	STRUCT WaveProperties s

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionReturnPermWave\"" + \
		  "}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, wvProp=s)
	WAVE wv = TestFunctionReturnPermWave()
	CompareWaveWithSerialized(wv, s)
End

Function WorksWithFuncReturnFreeWave()

	string msg, replyMessage,  expected
	variable errorValue
	STRUCT WaveProperties s

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionReturnFreeWave\"" + \
		  "}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, wvProp=s)
	WAVE wv = TestFunctionReturnFreeWave()
	CompareWaveWithSerialized(wv, s)
End

Function ComplainsWithFuncReturnWaveWave()

	string msg, replyMessage,  expected
	variable errorValue
	STRUCT WaveProperties s

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionReturnWaveWave\"" + \
		  "}}"

	replyMessage = zeromq_test_callfunction(msg)

	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_UNSUPPORTED_FUNC_RET)
End

Function ComplainsWithFuncReturnDFWave()

	string msg, replyMessage,  expected
	variable errorValue
	STRUCT WaveProperties s

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionReturnDFWave\"" + \
		  "}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_UNSUPPORTED_FUNC_RET)
End

Function DoesNotHaveMemLeaksReturnWave()
	variable i, errorValue, memBefore, memAfter

	string replyMessage
	variable initialSize = 100
	STRUCT WaveProperties s

	string msg = "{\"version\"     : 1, "               + \
	"\"CallFunction\" : {"                              + \
	"\"name\"         : \"TestFunctionReturnLargeFreeWave\"" + \
	"}}"

	memBefore = NumberByKey("USEDPHYSMEM", IgorInfo(0))

	for(i = 0; i < 10; i++)
		replyMessage = zeromq_test_callfunction(msg)
	endfor

	memAfter = NumberByKey("USEDPHYSMEM", IgorInfo(0))

	CHECK(memAfter < memBefore * 1.05)
End

Function ComplainsWithFuncAndIntParam1()

	string msg, replyMessage, expected
	variable errorValue
	STRUCT WaveProperties s

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionWithIntParam1\"," + \
		  "\"params\" : [1]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_UNSUPPORTED_FUNC_SIG)
End

Function ComplainsWithFuncAndIntParam2()

	string msg, replyMessage, expected
	variable errorValue
	STRUCT WaveProperties s

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionWithIntParam2\"," + \
		  "\"params\" : [1]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_UNSUPPORTED_FUNC_SIG)
End

Function ComplainsWithFuncAndIntParam3()

	string msg, replyMessage, expected
	variable errorValue
	STRUCT WaveProperties s

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionWithIntParam3\"," + \
		  "\"params\" : [1]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_UNSUPPORTED_FUNC_SIG)
End

// IP7 style "double" parameters are accepted
Function WorksWithFuncAndDoubleParam()

	string msg, replyMessage, expected
	variable errorValue
	STRUCT WaveProperties s

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionWithDoubleParam\"," + \
		  "\"params\" : [1]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)
End

// tests are flaky
//
//Function WorksWithFunctionsWhichAbort1()
//
//	string msg, replyMessage, expected
//	variable errorValue, err
//
//	msg = "{\"version\"     : 1, "                   + \
//		  "\"CallFunction\" : {"                     + \
//		  "\"name\"         : \"TestFunctionAbort1\"" + \
//		  "}}"
//
//	try
//		replyMessage = zeromq_test_callfunction(msg)
//	catch
//	endtry
//
//	errorValue = ExtractErrorValue(replyMessage)
//	CHECK_EQUAL_VAR(errorValue, REQ_FUNCTION_ABORTED)
//End
//
//Function WorksWithFunctionsWhichAbort2()
//
//	string msg, replyMessage, expected
//	variable errorValue, err
//
//	msg = "{\"version\"     : 1, "                   + \
//		  "\"CallFunction\" : {"                     + \
//		  "\"name\"         : \"TestFunctionAbort2\"" + \
//		  "}}"
//
//	try
//		replyMessage = zeromq_test_callfunction(msg)
//	catch
//	endtry
//
//	errorValue = ExtractErrorValue(replyMessage)
//	CHECK_EQUAL_VAR(errorValue, REQ_FUNCTION_ABORTED)
//End
//
// Works with functions which Abort and have pass by ref parameters
//Function WorksWithFunctionsAndPassByRef4()
//
//	string msg, replyMessage
//	string expected, actual
//	variable errorValue, resultVariable
//
//	msg = "{\"version\"     : 1, "                   + \
//		  "\"CallFunction\" : {"                     + \
//		  "\"name\"         : \"TestFunctionPassByRef4\"," + \
//		  "\"params\" : [123, \"nothing\"]}}"
//
//	try
//		replyMessage = zeromq_test_callfunction(msg)
//	catch
//	endtry
//
//	errorValue = ExtractErrorValue(replyMessage)
//	CHECK_EQUAL_VAR(errorValue, REQ_FUNCTION_ABORTED)
//End

Function WorksWithFunctionsAndPassByRef1()

	string msg, replyMessage
	variable expected, actual
	variable errorValue, resultVariable

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionPassByRef1\"," + \
		  "\"params\" : [1]}}"

	replyMessage = zeromq_test_callfunction(msg)

	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVariable)
	expected = 42
	CHECK_EQUAL_VAR(expected, resultVariable)

	Make/FREE/T/N=0 wv
	ExtractReturnValue(replyMessage, passByRefWave=wv)
	expected = 4711
	actual   = str2num(wv[0])
	CHECK_EQUAL_VAR(expected, actual)
End

Function WorksWithFunctionsAndPassByRef2()

	string msg, replyMessage
	string expected, actual
	variable errorValue, resultVariable

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionPassByRef2\"," + \
		  "\"params\" : [\"nothing\"]}}"

	replyMessage = zeromq_test_callfunction(msg)

	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVariable)
	CHECK_EQUAL_VAR(42, resultVariable)

	Make/FREE/T/N=0 wv
	ExtractReturnValue(replyMessage, passByRefWave=wv)
	expected = "hi there"
	actual   = wv[0]
	CHECK_EQUAL_STR(expected, actual)
End

Function WorksWithFunctionsAndPassByRef3()

	string msg, replyMessage
	string expected, actual
	variable errorValue, resultVariable

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionPassByRef3\"," + \
		  "\"params\" : [123, \"nothing\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	print replyMessage

	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVariable)
	CHECK_EQUAL_VAR(42, resultVariable)

	Make/FREE/T/N=0 wv
	ExtractReturnValue(replyMessage, passByRefWave=wv)
	expected = "NaN"
	actual   = wv[0]
	CHECK_EQUAL_STR(expected, actual)

	expected = "hi there"
	actual   = wv[1]
	CHECK_EQUAL_STR(expected, actual)
End

Function DoesNotHaveMemLeaksPassByRefStr()
	variable i, errorValue, memBefore, memAfter

	string replyMessage, msg

	zeromq_set(ZeroMQ_SET_FLAGS_DEFAULT)

	msg = "{\"version\"     : 1, "                         + \
		  "\"CallFunction\" : {"                           + \
		  "\"name\"         : \"TestFunctionPassByRef5\"," + \
		  "\"params\" : [\"nothing\", 123]}}"

	memBefore = NumberByKey("USEDPHYSMEM", IgorInfo(0))

	for(i = 0; i < 50; i++)
		replyMessage = zeromq_test_callfunction(msg)
		errorValue = ExtractErrorValue(replyMessage)
		CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)
	endfor

	memAfter = NumberByKey("USEDPHYSMEM", IgorInfo(0))

	CHECK(memAfter < memBefore * 1.05)
End

Function WorksWithReturningNullDFR()

	string msg, replyMessage
	string expected
	variable errorValue
	string resultString

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionReturnNullDFR\"" + \
		  "}}"

	replyMessage = zeromq_test_callfunction(msg)

	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, dfr=resultString)
	expected = "null"
	CHECK_EQUAL_STR(expected, resultString)
End

Function WorksWithReturningDFR()

	string msg, replyMessage
	string expected
	variable errorValue
	string resultString

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionReturnDFR\"" + \
		  "}}"

	replyMessage = zeromq_test_callfunction(msg)

	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, dfr=resultString)
	expected = "root:"
	CHECK_EQUAL_STR(expected, resultString)
End

Function WorksWithReturningFreeDFR()

	string msg, replyMessage
	string expected
	variable errorValue
	string resultString

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionReturnFreeDFR\"" + \
		  "}}"

	replyMessage = zeromq_test_callfunction(msg)

	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, dfr=resultString)
	expected = "free"
	CHECK_EQUAL_STR(expected, resultString)
End

Function WorksWithReturningDanglingDFR()

	string msg, replyMessage
	string expected
	variable errorValue
	string resultString

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionReturnDanglingDFR\"" + \
		  "}}"

	replyMessage = zeromq_test_callfunction(msg)

	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, dfr=resultString)
	expected = "null"
	CHECK_EQUAL_STR(expected, resultString)
End

Function WorksWithPassingValidDFR1()

	string msg, replyMessage
	variable errorValue, resultVariable,  expected

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionWithDFRParam1\"," + \
		  "\"params\": [\"root:\"]}}"

	replyMessage = zeromq_test_callfunction(msg)

	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVariable)
	expected = 123
	CHECK_EQUAL_VAR(expected, resultVariable)
End

Function WorksWithPassingValidDFR2()

	string msg, replyMessage
	variable errorValue
	string resultString,  expected

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionWithDFRParam2\"," + \
		  "\"params\": [\"root:\"]}}"

	replyMessage = zeromq_test_callfunction(msg)

	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, str=resultString)
	expected = "root:"
	CHECK_EQUAL_STR(expected, resultString)
End

Function WorksWithPassingValidDFR3()

	string msg, replyMessage
	variable errorValue
	string resultString,  expected

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"TestFunctionWithDFRParam3\"," + \
		  "\"params\": [\"root:\"]}}"

	replyMessage = zeromq_test_callfunction(msg)

	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, dfr=resultString)
	expected = "root:"
	CHECK_EQUAL_STR(expected, resultString)
End

Function WorksWithPassingMessageIDAndRep()
	string msg, replyMessage
	variable errorValue, resultVariable
	string expected, actual

	msg = "{\"version\"     : 1, "                    + \
		  " \"messageID\"   : \"4711\", "             + \
		  "\"CallFunction\" : {"                      + \
		  "\"name\"         : \"TestFunctionNoArgs\"" + \
		  "}}"

	replyMessage = zeromq_test_callfunction(msg)

	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=resultVariable)
	CHECK_EQUAL_VAR(resultVariable, NaN)

	expected = "4711"
	actual   = ExtractMessageID(replyMessage)
	CHECK_EQUAL_STR(expected, actual, case_sensitive=1)
End

static Function ReturnsOOMError()
	string msg, replyMessage
	variable errorValue, resultVariable
	string expected, actual

#ifdef IGOR64
	printf "Skipping test \"%s\" on Igor Pro 64bit\r", GetRTStackInfo(1)
	PASS()
	return NaN
#endif

	ExhaustMemory(1.0)

	// wave will be returned by TestFunctionReturnExistingWave
	// on serialization this will then trigger the OOM
	Make/N=(100e6)/B/O root:bigWAVE

	msg = "{\"version\"     : 1, "                    + \
		  "\"CallFunction\" : {"                      + \
		  "\"name\"         : \"TestFunctionReturnExistingWave\"" + \
		  "}}"

	replyMessage = zeromq_test_callfunction(msg)

	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_OUT_OF_MEMORY)
End
