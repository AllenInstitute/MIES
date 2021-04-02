#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion=8.0

// This file is part of the `ZeroMQ-XOP` project and licensed under BSD-3-Clause.

/// @name Flags for zeromq_set()
/// @anchor ZeroMQSetFlags
/// @{
/// Sets the default flags (no debug, no ipv6, busy wait on receive)
Constant ZeroMQ_SET_FLAGS_DEFAULT  = 0x1
/// Enable debug output
Constant ZeroMQ_SET_FLAGS_DEBUG    = 0x2
/// Enable ipv6 support
Constant ZeroMQ_SET_FLAGS_IPV6     = 0x4
/// Don't do busy waiting on zeromq_server_recv() and zeromq_client_recv()
/// instead immediately return if no messages are available.
Constant ZeroMQ_SET_FLAGS_NOBUSYWAITRECV = 0x8
/// Log incoming and outgoing messages
Constant ZeroMQ_SET_FLAGS_LOGGING = 0x10

/// @}

/// @name Error codes
/// @anchor ZeroMQErrorCodes
/// @{
Constant ZeroMQ_UNKNOWN_SET_FLAG        = 10003
Constant ZeroMQ_INTERNAL_ERROR          = 10004
Constant ZeroMQ_INVALID_ARG             = 10005
Constant ZeroMQ_HANDLER_ALREADY_RUNNING = 10006
Constant ZeroMQ_HANDLER_NO_CONNECTION   = 10007
Constant ZeroMQ_MISSING_PROCEDURE_FILES = 10008
Constant ZeroMQ_INVALID_MESSAGE_FORMAT  = 10009
Constant ZeroMQ_INVALID_LOGGING_TEMPLATE= 10010
/// @}

Constant REQ_SUCCESS                         =   0
Constant REQ_UNKNOWN_ERROR                   =   1
Constant REQ_INVALID_JSON_OBJECT             =   3
Constant REQ_INVALID_VERSION                 =   4
Constant REQ_INVALID_OPERATION               =   5
Constant REQ_INVALID_OPERATION_FORMAT        =   6
Constant REQ_INVALID_MESSAGEID               =   7
Constant REQ_OUT_OF_MEMORY                   =   8
// error codes for CallFunction class
Constant REQ_PROC_NOT_COMPILED               = 100
Constant REQ_NON_EXISTING_FUNCTION           = 101
Constant REQ_TOO_FEW_FUNCTION_PARAMS         = 102
Constant REQ_TOO_MANY_FUNCTION_PARAMS        = 103
Constant REQ_UNSUPPORTED_FUNC_SIG            = 104
Constant REQ_UNSUPPORTED_FUNC_RET            = 105
Constant REQ_INVALID_PARAM_FORMAT            = 106
Constant REQ_FUNCTION_ABORTED                = 107

/// @name Functions which might be useful for outside callers
/// @anchor ZeroMQInterfaceFunctions
/// @{
Function ZeroMQ_WaveExists(pathToWave)
	string pathToWave

	WAVE/Z wv = $pathToWave

	return WaveExists(wv)
End

Function/WAVE ZeroMQ_GetWave(pathToWave)
	string pathToWave

	WAVE/Z wv = $pathToWave

	return wv
End

Function ZeroMQ_DataFolderExists(pathToDataFolder)
	string pathToDataFolder

	return DataFolderExists(pathToDataFolder)
End

Function/S ZeroMQ_FunctionList(matchStr)
	string matchStr

	return FunctionList(matchStr, ";", "")
End

Function/S ZeroMQ_FunctionInfo(functionNameStr)
	string functionNameStr

	return FunctionInfo(functionNameStr)
End

Function ZeroMQ_ShowHelp(topic)
	string topic

	DisplayHelpTopic topic
End
/// @}
