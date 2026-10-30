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

/// @brief Bind the endpoint unless this Igor Pro instance has it bound already
///
/// Other packages, like the Igor Pro Bridge, use the ZeroMQ XOP as well, so
/// a failed bind does not tell whether this instance or another process
/// holds the endpoint.
///
/// @param socketType One of @ref ZeroMQSocketTypes, server or publisher
/// @param port       TCP port
///
/// @retval newBind 1 if the endpoint was bound now, 0 if it was bound already
/// @retval success 1 if the endpoint is bound, 0 if binding it failed
static Function [variable newBind, variable success] BindZeroMQEndpoint(variable socketType, variable port)

	variable err
	string   endpoint

	endpoint = ZEROMQ_PROT_AND_NETWORK + num2str(port)

	WAVE/T boundEndpoints = zeromq_get_bound_endpoints(socketType)
	if(IsFinite(GetRowIndex(boundEndpoints, str = endpoint)))
		return [0, 1]
	endif

	AssertOnAndClearRTError()
	switch(socketType)
		case ZMQ_SOCKET_TYPE_SERVER:
			zeromq_server_bind(endpoint); err = GetRTError(1) // see developer docu section Preventing Debugger Popup
			break
		case ZMQ_SOCKET_TYPE_PUBLISHER:
			zeromq_pub_bind(endpoint); err = GetRTError(1) // see developer docu section Preventing Debugger Popup
			break
		default:
			FATAL_ERROR("Unsupported socket type")
	endswitch

	if(err)
		printf "Could not bind the ZeroMQ endpoint %s, another program, e.g. a second Igor Pro instance, might use it.\r", endpoint
		return [0, 0]
	endif

	DEBUGPRINT("Successfully listening on endpoint:", str = endpoint)

	return [1, 1]
End

/// @brief Bind the server and publisher endpoints of MIES which are not bound yet
///
/// @retval numNewBinds number of endpoints bound now
/// @retval success     1 if all endpoints are bound, 0 otherwise
static Function [variable numNewBinds, variable success] BindZeroMQEndpoints()

	variable newServerBind, serverSuccess, newPubBind, pubSuccess

	[newServerBind, serverSuccess] = BindZeroMQEndpoint(ZMQ_SOCKET_TYPE_SERVER, ZEROMQ_BIND_REP_PORT)
	[newPubBind, pubSuccess]       = BindZeroMQEndpoint(ZMQ_SOCKET_TYPE_PUBLISHER, ZEROMQ_BIND_PUB_PORT)

	return [newServerBind + newPubBind, serverSuccess && pubSuccess]
End

/// @brief Start the ZeroMQ sockets and the message handler
///
/// Debug note: Tracking the connection state can be done via
/// `netstat | grep $port`. The binded port only shows up *after* a
/// successfull connection with zeromq_client_connect() is established.
///
/// @return 0 on success, 1 if already running and 2 on error
Function StartZeroMQSockets([variable forceRestart])

	variable err, numNewBinds, success, flags

	if(ParamIsDefault(forceRestart))
		forceRestart = 0
	else
		forceRestart = !!forceRestart
	endif

	if(!forceRestart)
		AssertOnAndClearRTError()
		zeromq_handler_start(); err = GetRTError(1) // see developer docu section Preventing Debugger Popup
		if(ConvertXOPErrorCode(err) == ZeroMQ_HANDLER_ALREADY_RUNNING)
			[numNewBinds, success] = BindZeroMQEndpoints()

			if(!success)
				// keep the endpoints of the other packages using the XOP
				ControlWindowToFront()
				return 2
			endif

			if(!numNewBinds)
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

	[numNewBinds, success] = BindZeroMQEndpoints()

	if(success)
		AssertOnAndClearRTError()
		zeromq_handler_start(); err = GetRTError(1) // see developer docu section Preventing Debugger Popup
		err = ConvertXOPErrorCode(err)
		if(!err || err == ZeroMQ_HANDLER_ALREADY_RUNNING)
			DEBUGPRINT("Successfully started zeromq handler")
			return 0
		endif
		printf "Error %d starting ZeroMQ handler\r", err
	else
		printf "Shutting down the ZeroMQ subsystem.\r"
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
