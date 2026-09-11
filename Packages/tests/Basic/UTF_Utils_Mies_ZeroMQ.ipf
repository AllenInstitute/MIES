#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_MIES_ZEROMQ

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
