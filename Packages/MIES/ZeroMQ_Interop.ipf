#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IgorVersion=6.37

// This file is part of the `ZeroMQ-XOP` project and licensed under BSD-3-Clause.

/// ** Define ZeroMQ Constants (for back-compatibility) for Igor8 case. **
#if igorVersion() >= 8
/// @name Flags for zeromq_set()
/// @anchor ZeroMQSetFlags
///@{
/// Sets the default flags (no debug, no ipv6, busy wait on receive)
Constant ZeroMQ_SET_FLAGS_DEFAULT = 0x1
/// Enable debug output
Constant ZeroMQ_SET_FLAGS_DEBUG = 0x2
/// Enable ipv6 support
Constant ZeroMQ_SET_FLAGS_IPV6 = 0x4
/// Don't do busy waiting on zeromq_server_recv() and zeromq_client_recv()
/// instead immediately return if no messages are available.
Constant ZeroMQ_SET_FLAGS_NOBUSYWAITRECV = 0x8
/// Log incoming and outgoing messages
Constant ZeroMQ_SET_FLAGS_LOGGING = 0x10
/// Call interceptor function for message handler CallFunction requests
Constant ZeroMQ_SET_FLAGS_INTERCEPTOR = 0x20

///@}

StrConstant ZeroMQ_HEARTBEAT = "heartbeat"

/// @name Error codes
/// @anchor ZeroMQErrorCodes
///@{
Constant ZeroMQ_UNKNOWN_SET_FLAG          = 10003
Constant ZeroMQ_INTERNAL_ERROR            = 10004
Constant ZeroMQ_INVALID_ARG               = 10005
Constant ZeroMQ_HANDLER_ALREADY_RUNNING   = 10006
Constant ZeroMQ_HANDLER_NO_CONNECTION     = 10007
Constant ZeroMQ_MISSING_PROCEDURE_FILES   = 10008
Constant ZeroMQ_INVALID_MESSAGE_FORMAT    = 10009
Constant ZeroMQ_INVALID_LOGGING_TEMPLATE  = 10010
Constant ZeroMQ_MESSAGE_FILTER_DUPLICATED = 10011
Constant ZeroMQ_MESSAGE_FILTER_MISSING    = 10012
Constant ZeroMQ_MESSAGE_INVALID_TYPE      = 10013
///@}
#endif

/// @name Flags for zeromq_set()
/// @anchor ZeroMQSetFlags
///@{
/// Sets the default flags (no debug, no ipv6, busy wait on receive, no interceptor function)
Constant ZMQ_SET_FLAGS_DEFAULT = 0x1
/// Enable debug output
Constant ZMQ_SET_FLAGS_DEBUG = 0x2
/// Enable ipv6 support
Constant ZMQ_SET_FLAGS_IPV6 = 0x4
/// Don't do busy waiting on zeromq_server_recv() and zeromq_client_recv()
/// instead immediately return if no messages are available.
Constant ZMQ_SET_FLAGS_NOBUSYWAITRECV = 0x8
/// Log incoming and outgoing messages
Constant ZMQ_SET_FLAGS_LOGGING = 0x10
/// Call interceptor function for message handler CallFunction requests
Constant ZMQ_SET_FLAGS_INTERCEPTOR = 0x20
///@}

StrConstant ZMQ_HEARTBEAT = "heartbeat"

/// @name Error codes
/// @anchor ZeroMQErrorCodes
///@{
Constant ZMQ_UNKNOWN_SET_FLAG          = 10003
Constant ZMQ_INTERNAL_ERROR            = 10004
Constant ZMQ_INVALID_ARG               = 10005
Constant ZMQ_HANDLER_ALREADY_RUNNING   = 10006
Constant ZMQ_HANDLER_NO_CONNECTION     = 10007
Constant ZMQ_MISSING_PROCEDURE_FILES   = 10008
Constant ZMQ_INVALID_MESSAGE_FORMAT    = 10009
Constant ZMQ_INVALID_LOGGING_TEMPLATE  = 10010
Constant ZMQ_MESSAGE_FILTER_DUPLICATED = 10011
Constant ZMQ_MESSAGE_FILTER_MISSING    = 10012
Constant ZMQ_MESSAGE_INVALID_TYPE      = 10013
Constant ZMQ_NO_INTERCEPTOR_FUNC       = 10014
Constant ZMQ_INVALID_INTERCEPTOR_FUNC  = 10015
///@}

Constant REQ_SUCCESS                  = 0
Constant REQ_UNKNOWN_ERROR            = 1
Constant REQ_INVALID_JSON_OBJECT      = 3
Constant REQ_INVALID_VERSION          = 4
Constant REQ_INVALID_OPERATION        = 5
Constant REQ_INVALID_OPERATION_FORMAT = 6
Constant REQ_INVALID_MESSAGEID        = 7
Constant REQ_OUT_OF_MEMORY            = 8
// error codes for CallFunction class
Constant REQ_PROC_NOT_COMPILED        = 100
Constant REQ_NON_EXISTING_FUNCTION    = 101
Constant REQ_TOO_FEW_FUNCTION_PARAMS  = 102
Constant REQ_TOO_MANY_FUNCTION_PARAMS = 103
Constant REQ_UNSUPPORTED_FUNC_SIG     = 104
Constant REQ_UNSUPPORTED_FUNC_RET     = 105
Constant REQ_INVALID_PARAM_FORMAT     = 106
Constant REQ_FUNCTION_ABORTED         = 107
Constant REQ_INTERCEPT_FUNC_ABORTED   = 108

/// @name Functions which might be useful for outside callers
/// @anchor ZeroMQInterfaceFunctions
///@{
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

/// @name Possible values for the mode parameter of ZeroMQ_Interceptor_Proto()
/// @anchor ZeroMQInterceptorModes
///@{
Constant ZeroMQ_INTERCEPT_BEGIN = 1
Constant ZeroMQ_INTERCEPT_END   = 2
///@}

/// @brief Prototype function to be used as interceptor function
///
/// @param json JSON payload with function name and parameters
/// @param iden Routing id (formerly known as identity) of the remote zeromq side
/// @param mode One of @ref ZeroMQInterceptorModes, communicates if we are before the function call or after.
///        Due to an Igor Pro implementation detail the after interceptor call is skipped when the main function aborts
Function ZeroMQ_Interceptor_Proto(json, iden, mode)
	string json, iden
	variable mode

	Abort "Can't call prototype function"
End
///@}
