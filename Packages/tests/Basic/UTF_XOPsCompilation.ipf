#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=XOPsCompilationTests

static Function CheckCompilation_IGNORE()

	// JSON
	JSONXOP_Version

	// ZeroMQ
	print zeromq_test_serializeWave($"")

	// TUF
	TUFXOP_Version

	// MiesUtils
	print MU_RunningInMainThread()

#ifdef WINDOWS
	// NWBv2 compound
	IPNWB_WriteCompound ""
#endif
End
