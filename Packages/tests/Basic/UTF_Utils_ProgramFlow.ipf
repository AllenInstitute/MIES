#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_PROGRAMFLOW

// Missing Tests for:
// AssertOnAndClearRTError
// ClearRTError
// IsFunctionCalledRecursively
// GetStackTrace

/// ASSERT
/// @{

Function AssertionWorksWithPassingOne()

	PASS()
	ASSERT(1, "Nothing to see here")
End

Function AssertionFiresWithPassingZero()

	try
		ASSERT(0, "Kaboom") // NOLINT
		FAIL()
	catch
		CHECK_EQUAL_VAR(V_AbortCode, -3)
	endtry
End

/// @}

/// ASSERT_TS
/// @{

Function AssertionThreadsafeWorksWithPassingOne()

	PASS()
	ASSERT_TS(1, "Nothing to see here")
End

Function AssertionThreadsafeFiresWithPassingZero()

	try
		ASSERT_TS(0, "Kaboom") // NOLINT
		FAIL()
	catch
		CHECK_GE_VAR(V_AbortCode, 1)
	endtry
End

Function FatalErrorAlwaysFires()

	try
		FATAL_ERROR("Kaboom")
		FAIL()
	catch
		CHECK_GE_VAR(V_AbortCode, 1)
	endtry
End

/// @}

/// DoAbortNow
/// @{

Function DON_WorksWithDefault()

	NVAR interactiveMode = $GetInteractiveMode()
	KillVariables/Z interactiveMode

	NVAR interactiveMode = $GetInteractiveMode()
	CHECK_EQUAL_VAR(interactiveMode, 1)

	try
		DoAbortNow("")
		FAIL()
	catch
		PASS()
	endtry
End

Function DON_WorksWithNoMsgAndInterMode()

	NVAR interactiveMode = $GetInteractiveMode()
	interactiveMode = 1

	try
		DoAbortNow("")
		FAIL()
	catch
		PASS()
	endtry
End

Function DON_WorksWithNoMsgAndNInterMode()

	NVAR interactiveMode = $GetInteractiveMode()
	interactiveMode = 0

	try
		DoAbortNow("")
		FAIL()
	catch
		PASS()
	endtry
End

Function DON_WorksWithMsgAndNInterMode()

	NVAR interactiveMode = $GetInteractiveMode()
	interactiveMode = 0

	try
		DoAbortNow("MyMessage")
		FAIL()
	catch
		PASS()
	endtry
End

// we can't test with message and interactive abort as that
// will trigger a dialog ...

/// @}

/// AlreadyCalledOnce
/// @{

Function CO_Works()

	try
		AlreadyCalledOnce("")
		FAIL()
	catch
		PASS()
	endtry

	CHECK_EQUAL_VAR(AlreadyCalledOnce("abcd"), 0)
	CHECK_EQUAL_VAR(AlreadyCalledOnce("abcd"), 1)

	CHECK_EQUAL_VAR(AlreadyCalledOnce("efgh"), 0)
	CHECK_EQUAL_VAR(AlreadyCalledOnce("efgh"), 1)
End

/// @}

/// MiesUtils XOP functions
/// @{

#ifndef THREADING_DISABLED

Function RunningInMainThread_Thread()

	make/FREE data
	multithread data = MU_RunningInMainThread()
	CHECK_EQUAL_VAR(Sum(data), 0)
End

#endif // !THREADING_DISABLED

Function RunningInMainThread_Main()

	make/FREE data
	data = MU_RunningInMainThread()
	CHECK_EQUAL_VAR(Sum(data), 128)
End

/// @}
