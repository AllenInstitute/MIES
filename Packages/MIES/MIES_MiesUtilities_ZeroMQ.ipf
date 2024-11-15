#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_MIESUTILS_ZEROMQ
#endif

/// @file MIES_MiesUtilities_ZeroMQ.ipf
/// @brief This file holds MIES utility functions for ZeroMQ

Function GetZeroMQXOPFlags()

	return ZeroMQ_SET_FLAGS_DEFAULT | ZeroMQ_SET_FLAGS_LOGGING | ZeroMQ_SET_FLAGS_NOBUSYWAITRECV
End

/// @brief Start the ZeroMQ sockets and the message handler
///
/// Debug note: Tracking the connection state can be done via
/// `netstat | grep $port`. The binded port only shows up *after* a
/// successfull connection with zeromq_client_connect() is established.
///
/// @return NaN if already running, otherwise it returns the number of trials
///         it had to iterate for an unused port.
Function StartZeroMQSockets([variable forceRestart])

	variable i, port, err, numBinds, flags, numTrials

	if(ParamIsDefault(forceRestart))
		forceRestart = 0
	else
		forceRestart = !!forceRestart
	endif

	if(!forceRestart)
		// do nothing if we are already running
		AssertOnAndClearRTError()
		zeromq_handler_start(); err = GetRTError(1) // see developer docu section Preventing Debugger Popup
		if(ConvertXOPErrorCode(err) == ZeroMQ_HANDLER_ALREADY_RUNNING)
			DEBUGPRINT("Already running, nothing to do.")
			return NaN
		endif
	endif

	zeromq_stop()

	flags = GetZeroMQXOPFlags()

	zeromq_set(flags)

#if defined(DEBUGGING_ENABLED)
	if(DP_DebuggingEnabledForCaller())
		zeromq_set(flags | ZeroMQ_SET_FLAGS_DEBUG)
	endif
#endif

	for(i = 0; i < ZEROMQ_NUM_BIND_TRIALS; i += 1)
		port = ZEROMQ_BIND_REP_PORT + i
		AssertOnAndClearRTError()
		zeromq_server_bind("tcp://127.0.0.1:" + num2str(port)); err = GetRTError(1) // see developer docu section Preventing Debugger Popup

		if(!err)
			DEBUGPRINT("Successfully listening with server on port:", var = port)
			numBinds += 1
			break
		endif
	endfor

	numTrials += i

	for(i = 0; i < ZEROMQ_NUM_BIND_TRIALS; i += 1)
		port = ZEROMQ_BIND_PUB_PORT + i
		AssertOnAndClearRTError()
		zeromq_pub_bind("tcp://127.0.0.1:" + num2str(port)); err = GetRTError(1) // see developer docu section Preventing Debugger Popup

		if(!err)
			DEBUGPRINT("Successfully listening with publisher on port:", var = port)
			numBinds += 1
			break
		endif
	endfor

	numTrials += i

	ASSERT(numBinds == 2, "Could not establish ZeroMQ bind connections.")
	zeromq_handler_start()

	return numTrials
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
