#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=zmq_test_interop

Function ReturnsTrueForExistingWave()

	string msg
	string replyMessage
	variable errorValue, result, expected
	string resultString, path

	Make data
	path = GetWavesDataFolder(data, 2)

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"ZeroMQ_WaveExists\"," + \
		  "\"params\"       : [\"" + path + "\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=result)
	expected = 1
	CHECK_EQUAL_VAR(result, expected)
End

Function ReturnsFalseForNonExistingWave()

	string msg
	string replyMessage
	variable errorValue
	string path
	variable result, expected

	Make data
	path = GetWavesDataFolder(data, 2)
	KillWaves data

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"ZeroMQ_WaveExists\"," + \
		  "\"params\"       : [\"" + path + "\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=result)
	expected = 0
	CHECK_EQUAL_VAR(result, expected)
End

Function ReturnsTrueForExistingDF()

	string msg
	string replyMessage
	variable errorValue, result, expected
	string resultString, path

	NewDataFolder ttest
	DFREF dfr = ttest
	path = GetDataFolder(1, dfr)

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"ZeroMQ_DataFolderExists\"," + \
		  "\"params\"       : [\"" + path + "\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=result)
	expected = 1
	CHECK_EQUAL_VAR(result, expected)
End

Function ReturnsFalseForNonExistingDF()

	string msg
	string replyMessage
	variable errorValue
	string path
	variable result, expected

	NewDataFolder ttest
	DFREF dfr = ttest
	path = GetDataFolder(1, dfr)
	KillDataFolder ttest

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"ZeroMQ_DataFolderExists\"," + \
		  "\"params\"       : [\"" + path + "\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, var=result)
	expected = 0
	CHECK_EQUAL_VAR(result, expected)
End

Function FunctionListWorks()

	string msg
	string replyMessage
	variable errorValue
	string path, resultString, expected

	NewDataFolder ttest
	DFREF dfr = ttest
	path = GetDataFolder(1, dfr)
	KillDataFolder ttest

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"ZeroMQ_FunctionList\"," + \
		  "\"params\"       : [\"FunctionListWorks\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, str=resultString)
	expected = "FunctionListWorks;"
	CHECK_EQUAL_STR(resultString, expected)
End

Function FunctionInfoWorks()

	string msg
	string replyMessage
	variable errorValue
	string path, resultString, expected

	NewDataFolder ttest
	DFREF dfr = ttest
	path = GetDataFolder(1, dfr)
	KillDataFolder ttest

	msg = "{\"version\"     : 1, "                   + \
		  "\"CallFunction\" : {"                     + \
		  "\"name\"         : \"ZeroMQ_FunctionInfo\"," + \
		  "\"params\"       : [\"FunctionInfoWorks\"]}}"

	replyMessage = zeromq_test_callfunction(msg)
	errorValue = ExtractErrorValue(replyMessage)
	CHECK_EQUAL_VAR(errorValue, REQ_SUCCESS)

	ExtractReturnValue(replyMessage, str=resultString)
	expected = FunctionInfo("FunctionInfoWorks")
	CHECK_EQUAL_STR(resultString, expected)
End
