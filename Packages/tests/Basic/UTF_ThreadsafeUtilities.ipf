#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = ThreadsafeUtilitiesTests

/// TSDS key which the worker sets when it finishes regularly
static StrConstant WORKER_FINISHED_KEY = "ThreadsafeUtilitiesTests_WorkerFinished"

static Function TEST_CASE_BEGIN_OVERRIDE(string testname)

	TestCaseBeginCommon(testname)

	TUFXOP_Clear/N=(WORKER_FINISHED_KEY)/Q/Z
End

static Function TEST_CASE_END_OVERRIDE(string testname)

	TUFXOP_Clear/N=(WORKER_FINISHED_KEY)/Q/Z

	TestCaseEndCommon(testname)
End

/// @brief Worker which waits for input from the main thread, then for `delay` [s] and finishes
///
/// With an infinite delay it does not finish on its own.
threadsafe static Function Worker_IGNORE(variable delay)

	variable refTime

	do
		DFREF dfr = ThreadGroupGetDFR(MAIN_THREAD, 10)
	while(!DataFolderExistsDFR(dfr))

	refTime = GetReferenceTime()
	do
		DFREF dfr = ThreadGroupGetDFR(MAIN_THREAD, 10)
	while(GetElapsedTime(refTime) < delay)

	TSDS_WriteVar(WORKER_FINISHED_KEY, 1)

	return 0
End

static Function StartWorker_IGNORE(variable delay)

	variable tgID

	tgID = ThreadGroupCreate(1)
	ThreadStart tgID, 0, Worker_IGNORE(delay)

	return tgID
End

/// TS_StopThreadGroup
/// @{
static Function StopThreadGroupWorks()

	variable tgID

	tgID = StartWorker_IGNORE(0)
	TS_StopThreadGroup(tgID)

	CHECK_EQUAL_VAR(TSDS_ReadVar(WORKER_FINISHED_KEY, defValue = 0, create = 1), 1)
	CHECK_EQUAL_VAR(ROVar(GetBugCount()), 0)
End

static Function StopThreadGroupWaitsForSlowWorker()

	variable tgID

	tgID = StartWorker_IGNORE(0.5)
	TS_StopThreadGroup(tgID)

	CHECK_EQUAL_VAR(TSDS_ReadVar(WORKER_FINISHED_KEY, defValue = 0, create = 1), 1)
	CHECK_EQUAL_VAR(ROVar(GetBugCount()), 0)
End

static Function StopThreadGroupAbortsHangingWorker()

	variable tgID

	tgID = StartWorker_IGNORE(Inf)
	TS_StopThreadGroup(tgID)

	CHECK_EQUAL_VAR(TSDS_ReadVar(WORKER_FINISHED_KEY, defValue = 0, create = 1), 0)
	CHECK_EQUAL_VAR(ROVar(GetBugCount()), 1)

	DisableBugChecks()
End

static Function StopThreadGroupIgnoresInvalidThreadGroup()

	TS_StopThreadGroup(NaN)

	CHECK_EQUAL_VAR(ROVar(GetBugCount()), 0)
End
/// @}
