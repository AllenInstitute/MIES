#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = TESTS_DEBUGGING

/// BUG
/// BUG_TS
/// @{

Function BUGWorks()

	variable bugCount

	bugCount = ROVar(GetBugCount())
	CHECK_EQUAL_VAR(bugCount, 0)

	BUG("abcd")

	bugCount = ROVar(GetBugCount())
	CHECK_EQUAL_VAR(bugCount, 1)

	DisableBugChecks()
End

Function BUG_TSWorks1()

	variable bugCount

	TUFXOP_Clear/N=(TSDS_BUGCOUNT)/Q/Z

	BUG_TS("abcd")

	bugCount = TSDS_ReadVar(TSDS_BUGCOUNT)
	CHECK_EQUAL_VAR(bugCount, 1)

	DisableBugChecks()
End

threadsafe static Function BugHelper(variable idx)

	BUG_TS(num2str(idx))

	return TSDS_ReadVar(TSDS_BUGCOUNT) == 0
End

Function BUG_TSWorks2()

	variable bugCount, numThreads

	TUFXOP_Clear/N=(TSDS_BUGCOUNT)/Q/Z

	numThreads = 10

	Make/FREE/N=(numThreads) junk = NaN

	MultiThread/NT=(numThreads) junk = BugHelper(p)

	CHECK_EQUAL_VAR(Sum(junk), 0)

	bugCount = TSDS_ReadVar(TSDS_BUGCOUNT)
	CHECK_EQUAL_VAR(bugCount, numThreads)

	DisableBugChecks()
End

/// @}
