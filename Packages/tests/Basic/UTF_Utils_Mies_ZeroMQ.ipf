#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_MIES_ZEROMQ

/// Endpoint of another package which uses the ZeroMQ XOP, e.g. the Igor Pro Bridge
static Constant FOREIGN_PORT = 5690

/// @brief StopZeroMQSockets() must leave the ZeroMQ subsystem in a state that
/// StartZeroMQSockets() can cleanly rebuild from
///
/// Deliberately does not assert on whether the message handler itself is left
/// running: with the Igor Pro Bridge active, StopZeroMQSockets() intentionally
/// restarts it again immediately (rebinding the bridge), so that end state
/// differs depending on whether a bridge session is present.
static Function StopZeroMQSocketsAllowsRestart()

	variable err

	CHECK_EQUAL_VAR(StartZeroMQSockets(forceRestart = 1), 0)

	StopZeroMQSockets()

	zeromq_handler_start(); err = GetRTError(1)
	err = ConvertXOPErrorCode(err)
#if exists("ZBR#ZBR_EnsureZeroMQBound")
	CHECK_EQUAL_VAR(err, ZeroMQ_HANDLER_ALREADY_RUNNING)
#else
	CHECK_EQUAL_VAR(err, ZeroMQ_HANDLER_NO_CONNECTION)
#endif

	// restore MIES ZeroMQ sockets
	CHECK_EQUAL_VAR(StartZeroMQSockets(forceRestart = 1), 0)
End

/// @brief StopZeroMQSockets() must be safe to call even when nothing is running
static Function StopZeroMQSocketsIsSafeWhenNotRunning()

	StopZeroMQSockets()

	try
		StopZeroMQSockets()
		CHECK_NO_RTE()
	catch
		FAIL()
	endtry

	// restore MIES ZeroMQ sockets
	CHECK_EQUAL_VAR(StartZeroMQSockets(forceRestart = 1), 0)
End

static Function CheckBoundEndpoints(variable socketType, WAVE/T expected)

	WAVE/T endpoints = zeromq_get_bound_endpoints(socketType)

	Sort endpoints, endpoints
	Sort expected, expected
	CHECK_EQUAL_TEXTWAVES(endpoints, expected)
End

/// @brief StartZeroMQSockets() must bind the MIES endpoints when another package
/// already started the message handler, and keep the endpoints of that package
static Function StartZeroMQSocketsBindsWithForeignHandler()

	zeromq_stop()

	zeromq_server_bind(ZEROMQ_PROT_AND_NETWORK + num2str(FOREIGN_PORT))
	zeromq_handler_start()

	CHECK_EQUAL_VAR(StartZeroMQSockets(), 0)
	CHECK_EQUAL_VAR(StartZeroMQSockets(), 1)

	Make/FREE/T expected = {ZEROMQ_PROT_AND_NETWORK + num2str(FOREIGN_PORT), ZEROMQ_PROT_AND_NETWORK + num2str(ZEROMQ_BIND_REP_PORT)}
	CheckBoundEndpoints(ZMQ_SOCKET_TYPE_SERVER, expected)

	Make/FREE/T expected = {ZEROMQ_PROT_AND_NETWORK + num2str(ZEROMQ_BIND_PUB_PORT)}
	CheckBoundEndpoints(ZMQ_SOCKET_TYPE_PUBLISHER, expected)

	// restore MIES ZeroMQ sockets
	CHECK_EQUAL_VAR(StartZeroMQSockets(forceRestart = 1), 0)
End

/// @brief StartZeroMQSockets() must only bind the MIES endpoints which are not
/// bound yet
static Function StartZeroMQSocketsBindsOnlyMissingEndpoints()

	zeromq_stop()

	zeromq_server_bind(ZEROMQ_PROT_AND_NETWORK + num2str(ZEROMQ_BIND_REP_PORT))
	zeromq_handler_start()

	CHECK_EQUAL_VAR(StartZeroMQSockets(), 0)

	Make/FREE/T expected = {ZEROMQ_PROT_AND_NETWORK + num2str(ZEROMQ_BIND_REP_PORT)}
	CheckBoundEndpoints(ZMQ_SOCKET_TYPE_SERVER, expected)

	Make/FREE/T expected = {ZEROMQ_PROT_AND_NETWORK + num2str(ZEROMQ_BIND_PUB_PORT)}
	CheckBoundEndpoints(ZMQ_SOCKET_TYPE_PUBLISHER, expected)

	// restore MIES ZeroMQ sockets
	CHECK_EQUAL_VAR(StartZeroMQSockets(forceRestart = 1), 0)
End

/// @brief StartZeroMQSockets() must report an endpoint which it can't bind,
/// e.g. as another process uses it, and keep the endpoints of the other
/// packages
static Function StartZeroMQSocketsComplainsAboutUsedEndpoint()

	zeromq_stop()

	zeromq_server_bind(ZEROMQ_PROT_AND_NETWORK + num2str(FOREIGN_PORT))
	// the server port is used by a socket of another type
	zeromq_pub_bind(ZEROMQ_PROT_AND_NETWORK + num2str(ZEROMQ_BIND_REP_PORT))
	zeromq_handler_start()

	CHECK_EQUAL_VAR(StartZeroMQSockets(), 2)

	Make/FREE/T expected = {ZEROMQ_PROT_AND_NETWORK + num2str(FOREIGN_PORT)}
	CheckBoundEndpoints(ZMQ_SOCKET_TYPE_SERVER, expected)

	// restore MIES ZeroMQ sockets
	CHECK_EQUAL_VAR(StartZeroMQSockets(forceRestart = 1), 0)
End
