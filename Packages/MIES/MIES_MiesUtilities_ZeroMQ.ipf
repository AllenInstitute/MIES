#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_MIESUTILS_ZEROMQ
#endif // AUTOMATED_TESTING

/// @file MIES_MiesUtilities_ZeroMQ.ipf
/// @brief This file holds MIES utility functions for ZeroMQ

Function GetZeroMQXOPFlags()

	return ZeroMQ_SET_FLAGS_DEFAULT | ZeroMQ_SET_FLAGS_NOBUSYWAITRECV
End

/// @brief Stop every ZeroMQ socket/handler in this Igor Pro instance, then
/// immediately rebind an active Igor Pro Bridge session (if present).
Function StopZeroMQSockets()

	zeromq_stop()

#if exists("ZBR#ZBR_EnsureZeroMQBound")
	ZBR#ZBR_EnsureZeroMQBound()
#endif
End

/// @brief Bind the server and publisher endpoints of MIES
///
/// @returns number of successful binds
static Function BindZeroMQEndpoints()

	variable err, port
	variable numBinds = 0

	AssertOnAndClearRTError()
	port = ZEROMQ_BIND_REP_PORT
	zeromq_server_bind(ZEROMQ_PROT_AND_NETWORK + num2str(port)); err = GetRTError(1) // see developer docu section Preventing Debugger Popup

	if(!err)
		DEBUGPRINT("Successfully listening with server on port:", var = port)
		numBinds += 1
	endif

	port = ZEROMQ_BIND_PUB_PORT
	AssertOnAndClearRTError()
	zeromq_pub_bind(ZEROMQ_PROT_AND_NETWORK + num2str(port)); err = GetRTError(1) // see developer docu section Preventing Debugger Popup

	if(!err)
		DEBUGPRINT("Successfully listening with publisher on port:", var = port)
		numBinds += 1
	endif

	return numBinds
End

/// @brief Start the ZeroMQ sockets and the message handler
///
/// Debug note: Tracking the connection state can be done via
/// `netstat | grep $port`. The binded port only shows up *after* a
/// successfull connection with zeromq_client_connect() is established.
///
/// @return 0 on success, 1 if already running and 2 on error
Function StartZeroMQSockets([variable forceRestart])

	variable err, numBinds, flags
	variable expectedBinds = 2

	if(ParamIsDefault(forceRestart))
		forceRestart = 0
	else
		forceRestart = !!forceRestart
	endif

	if(!forceRestart)
		AssertOnAndClearRTError()
		zeromq_handler_start(); err = GetRTError(1) // see developer docu section Preventing Debugger Popup
		if(ConvertXOPErrorCode(err) == ZeroMQ_HANDLER_ALREADY_RUNNING)
			if(!BindZeroMQEndpoints())
				DEBUGPRINT("Already running, nothing to do.")
				return 1
			endif

			return 0
		endif
	endif

	StopZeroMQSockets()

	flags = GetZeroMQXOPFlags()

	zeromq_set(flags)

#if defined(DEBUGGING_ENABLED)
	if(DP_DebuggingEnabledForCaller())
		zeromq_set(flags | ZeroMQ_SET_FLAGS_DEBUG)
	endif
#endif

	numBinds = BindZeroMQEndpoints()

	if(numBinds == expectedBinds)
		AssertOnAndClearRTError()
		zeromq_handler_start(); err = GetRTError(1) // see developer docu section Preventing Debugger Popup
		err = ConvertXOPErrorCode(err)
		if(!err || err == ZeroMQ_HANDLER_ALREADY_RUNNING)
			DEBUGPRINT("Successfully started zeromq handler")
			return 0
		endif
		printf "Error %d starting ZeroMQ handler\r", err
	else
		printf "Could only establish %d ZeroMQ bind connections and not %d. Shutting down ZeroMQ subsystem.\r", numBinds, expectedBinds
	endif

	ControlWindowToFront()
	StopZeroMQSockets()

	return 2
End

/// @brief Update the logging template used by the ZeroMQ-XOP and ITCXOP2
Function UpdateXOPLoggingTemplate()

	variable JSONid
	string   str

	JSONid = LOG_GenerateEntryTemplate("XOP")

	str = JSON_Dump(JSONid)
	zeromq_set_logging_template(str)
	HW_ITC_SetLoggingTemplate(str)

	JSON_Release(JSONid)
End
