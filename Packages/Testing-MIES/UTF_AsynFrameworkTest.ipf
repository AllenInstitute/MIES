#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=AsynTest

// If this moves to an independend test, uncomment the following line
//#include "unit-testing"

/// @file UTF_AsynFrameworkTest.ipf
/// @brief __ASYNC_Test__ This file holds the tests for the Async Framework

static Constant WORK_COUNT_GENERIC = 200
static Constant THREADING_TEST_TIMEOUT = 60

/// @brief Stops a possibly running Async frame work due to Compilehook feature of IP8
static Function TEST_CASE_BEGIN_OVERRIDE(testCase)
	string testCase

	TEST_CASE_END_OVERRIDE(testCase)
End

/// @brief Cleans up failing tests
static Function TEST_CASE_END_OVERRIDE(testCase)
	string testCase

	CtrlNamedBackground $"AsyncFramework", stop
	variable dummy
	dummy = ThreadGroupRelease(-2)
	DFREF dfr = MIES_ASYNC#getAsyncHomeDF()
	KillDataFolder/Z dfr
End

/// @brief Test to start Framework with zero threads
static Function TASYNC_Start_ZeroThreads()
	try
		ASYNC_Start(0)
		FAIL()
	catch
		PASS()
	endtry
End

/// @brief Test to start Framework with infinite threads
static Function TASYNC_Start_InfiniteThreads()
	try
		ASYNC_Start(Inf)
		FAIL()
	catch
		PASS()
	endtry
End

/// @brief Test to stop Framework when it is already stopped
static Function TASYNC_Stop_AlreadyStopped()

	CHECK_EQUAL_VAR(ASYNC_Stop(), 2)
End

/// @brief Test to start and stop the Framework
static Function TASYNC_Start_Stop()

	ASYNC_Start(ThreadProcessorCount)
	DFREF dfr = MIES_ASYNC#getAsyncHomeDF()
	NVAR/Z tgID = dfr:threadGroupID
	CHECK(NVAR_Exists(tgID))
	NVAR/Z ThreadCnt = dfr:numThreads
	CHECK(NVAR_Exists(ThreadCnt))
	CHECK_EQUAL_VAR(ThreadCnt, ThreadProcessorCount)
	CtrlNamedBackground _all_, status
	CHECK(strsearch(S_Info,"NAME:AsyncFramework;PROC:ASYNC_BackgroundReadOut;RUN:1;",0) >= 0)

	ASYNC_Stop(timeout=1)
End

/// @brief Test to start and stop the Framework without the readout task
static Function TASYNC_StartWOTask()

	ASYNC_Start(ThreadProcessorCount, disableTask=1)
	CtrlNamedBackground _all_, status
	CHECK(strsearch(S_Info,"NAME:AsyncFramework;PROC:ASYNC_BackgroundReadOut;RUN:1;",0) == -1)

	ASYNC_Stop(timeout=1)
End

/// @brief Test to start and the Framework twice
static Function TASYNC_Start_DoubleStart0()

	ASYNC_Start(ThreadProcessorCount)
	ASYNC_Start(ThreadProcessorCount)
	PASS()
	ASYNC_Stop(timeout=1)
End

/// @brief Test to prepare a thread data folder with an invalid Worker function
static Function TASYNC_PrepareDF_InvWorker()

	try
		DFREF threadDF = ASYNC_PrepareDF("1", "RunGenericReadOut", "TASYNCTest")
		FAIL()
	catch
		PASS()
	endtry
End

/// @brief Test to prepare a thread data folder with an invalid readout function
static Function TASYNC_PrepareDF_InvReadOut()

	try
		DFREF threadDF = ASYNC_PrepareDF("RunGenericWorker", "1", "TASYNCTest")
		FAIL()
	catch
		PASS()
	endtry
End

/// @brief Test to prepare a thread data folder, check if it was setup accordingly
static Function TASYNC_PrepareDF_Setup()

	string helperStr, compStr
	DFREF threadDF

	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")

	SVAR/Z/SDFR=threadDF tempS=WorkerFunc
	CHECK(SVAR_Exists(tempS))
	helperStr = tempS
	compStr = "RunGenericWorker"
	CHECK_EQUAL_STR(helperStr, compStr)

	DFREF dfrAsync = threadDF:async
	SVAR/Z/SDFR=dfrAsync tempS = ReadOutFunc
	CHECK(SVAR_Exists(tempS))
	helperStr = tempS
	compStr = "RunGenericReadOut"
	CHECK_EQUAL_STR(helperStr, compStr)

	NVAR/Z/SDFR=dfrAsync tempV = inOrder
	CHECK(NVAR_Exists(tempV))
	CHECK_EQUAL_VAR(tempV, 1)

	NVAR/Z/SDFR=threadDF tempV = threadDFMarker
	CHECK(NVAR_Exists(tempV))
	CHECK_EQUAL_VAR(tempV, 299792458)

	DFREF dfrInp = threadDF:input
	NVAR/Z/SDFR=dfrInp tempV = paramCount
	CHECK(NVAR_Exists(tempV))
	CHECK_EQUAL_VAR(tempV, 0)
End

/// @brief Test to add a parameter to a thread data folder which is an invalid data folder
static Function TASYNC_AddParam_InvalidDF()

	try
		ASYNC_AddParam(root)
		FAIL()
	catch
		PASS()
	endtry
End

/// @brief Test to add a parameter to a thread data folder when no parameter is given to be added
static Function TASYNC_AddParam_NoParams()

	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)

	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")

	try
		ASYNC_AddParam(threadDF)
		FAIL()
	catch
		PASS()
	endtry

	ASYNC_Stop(timeout=1)
End

/// @brief Test to add variable and string parameter at the same time to a thread data folder
static Function TASYNC_AddParam_VarStr()

	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)

	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")

	try
		ASYNC_AddParam(threadDF, var=1, str="1")
		FAIL()
	catch
		PASS()
	endtry

	ASYNC_Stop(timeout=1)
End

/// @brief Test to add variable and wave parameter at the same time to a thread data folder
static Function TASYNC_AddParam_VarWave()

	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)

	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")

	Make/N=1 wv
	try
		ASYNC_AddParam(threadDF, var=1, w=wv)
		FAIL()
	catch
		PASS()
	endtry

	ASYNC_Stop(timeout=1)
End

/// @brief Test to add string and wave parameter at the same time to a thread data folder
static Function TASYNC_AddParam_StrWave()

	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)

	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")

	Make/N=1 wv
	try
		ASYNC_AddParam(threadDF, str="1", w=wv)
		FAIL()
	catch
		PASS()
	endtry

	ASYNC_Stop(timeout=1)
End

/// @brief Test to add variable, string and wave parameter at the same time to a thread data folder
static Function TASYNC_AddParam_VarStrWave()

	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)

	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")

	Make/N=1 wv
	try
		ASYNC_AddParam(threadDF, var=1, str="1", w=wv)
		FAIL()
	catch
		PASS()
	endtry

	ASYNC_Stop(timeout=1)
End

/// @brief Test to add variable with a move parameter to a thread data folder
static Function TASYNC_AddParam_VarMove()

	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)

	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")

	Make/N=1 wv
	try
		ASYNC_AddParam(threadDF, var=1, move=1)
		FAIL()
	catch
		PASS()
	endtry

	ASYNC_Stop(timeout=1)
End

/// @brief Test to add string with a move parameter to a thread data folder
static Function TASYNC_AddParam_StrMove()

	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)

	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")

	Make/N=1 wv
	try
		ASYNC_AddParam(threadDF, str="1", move=1)
		FAIL()
	catch
		PASS()
	endtry

	ASYNC_Stop(timeout=1)
End

/// @brief Test to add a free wave with a move parameter to a thread data folder
static Function TASYNC_AddParam_FreeWaveMove()

	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)

	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")

	Make/FREE/N=1 wv
	ASYNC_AddParam(threadDF, w=wv, move=1)

	DFREF dfrInp = threadDF:input
	WAVE/Z/SDFR=dfrInp p0 = param0
	CHECK_WAVE(p0, NUMERIC_WAVE)

	ASYNC_Stop(timeout=1)
End

/// @brief Test to add a wave with a move parameter to a thread data folder
static Function TASYNC_AddParam_WaveMove()

	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)

	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")

	Make/N=1 wv
	ASYNC_AddParam(threadDF, w=wv, move=1)

	DFREF dfrInp = threadDF:input
	WAVE/Z/SDFR=dfrInp p0 = param0
	CHECK_WAVE(p0, NUMERIC_WAVE)

	ASYNC_Stop(timeout=1)
End

/// @brief Test to add a wave parameter to a thread data folder
static Function TASYNC_AddParam_Wave()

	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)

	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")

	Make/N=1 wv
	ASYNC_AddParam(threadDF, w=wv)

	DFREF dfrInp = threadDF:input
	WAVE/Z/SDFR=dfrInp p0 = param0
	CHECK_WAVE(p0, NUMERIC_WAVE)

	ASYNC_Stop(timeout=1)
End

/// @brief Test to add a free wave parameter to a thread data folder
static Function TASYNC_AddParam_FreeWave()

	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)

	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")

	Make/FREE/N=1 wv
	ASYNC_AddParam(threadDF, w=wv)

	DFREF dfrInp = threadDF:input
	WAVE/Z/SDFR=dfrInp p0 = param0
	CHECK_WAVE(p0, NUMERIC_WAVE)

	ASYNC_Stop(timeout=1)
End

/// @brief Test to add a variable parameter to a thread data folder
static Function TASYNC_AddParam_Var()

	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)

	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")

	ASYNC_AddParam(threadDF, var=1)

	DFREF dfrInp = threadDF:input
	NVAR/Z/SDFR=dfrInp v = param0
	CHECK(NVAR_Exists(v))

	ASYNC_Stop(timeout=1)
End

/// @brief Test to add a string parameter to a thread data folder
static Function TASYNC_AddParam_Str()

	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)

	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")

	ASYNC_AddParam(threadDF, str="1")

	DFREF dfrInp = threadDF:input
	SVAR/Z/SDFR=dfrInp s = param0
	CHECK(SVAR_Exists(s))

	ASYNC_Stop(timeout=1)
End

/// @brief Test to add multiple parameters to a thread data folder and check if they are counted correctly
static Function TASYNC_AddParam_ParamsCount()

	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)

	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")

	ASYNC_AddParam(threadDF, var=0)
	ASYNC_AddParam(threadDF, var=1)
	ASYNC_AddParam(threadDF, var=2)
	ASYNC_AddParam(threadDF, var=3)

	DFREF dfrInp = threadDF:input
	NVAR/Z/SDFR=dfrInp p0 = param0
	CHECK(NVAR_Exists(p0))
	CHECK_EQUAL_VAR(p0, 0)
	NVAR/Z/SDFR=dfrInp p1 = param1
	CHECK(NVAR_Exists(p1))
	CHECK_EQUAL_VAR(p1, 1)
	NVAR/Z/SDFR=dfrInp p2 = param2
	CHECK(NVAR_Exists(p2))
	CHECK_EQUAL_VAR(p2, 2)
	NVAR/Z/SDFR=dfrInp p3 = param3
	CHECK(NVAR_Exists(p3))
	CHECK_EQUAL_VAR(p3, 3)

	ASYNC_Stop(timeout=1)
End

/// @brief Test to execute a workload without a running framework
static Function TASYNC_Execute_NotRunning()

	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)
	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")
	ASYNC_Stop(timeout=1)

	try
		ASYNC_Execute(threadDF)
		FAIL()
	catch
		PASS()
	endtry
End

/// @brief Test to execute a workload from an invalid thread data folder
static Function TASYNC_Execute_InvalidDF()

	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)
	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")

	try
		ASYNC_Execute(root)
		FAIL()
	catch
		PASS()
	endtry
	ASYNC_Stop(timeout=1)
End

/// @brief Test if ASYNC_Execute triggers execution and data is returned through readout.
static Function TASYNC_Execute_Valid()

	string myDF
	DFREF threadDF
	variable endtime, timeout

	ASYNC_Start(ThreadProcessorCount)
	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")
	ASYNC_AddParam(threadDF, var=1)
	Make/N=10 data
	ASYNC_AddParam(threadDF, w=data, move=1)
	myDF = GetDataFolder(1)
	ASYNC_AddParam(threadDF, str=myDF)

	ASYNC_Execute(threadDF)

	Make/N=0 returnOrder
	endtime = datetime + THREADING_TEST_TIMEOUT
	timeout = 0
	for(;;)
		ASYNC_ThreadReadOut()
		if(numpnts(returnOrder) == 1)
			break
		endif
		if(datetime > endtime)
			timeout = 1
			break
		endif
	endfor
	CHECK(!timeout)

	ASYNC_Stop(timeout=1)
End

/// @brief Test if ASYNC_Execute triggers execution and data is returned through readout.
/// this test uses a worker returning a real data folder instead
static Function TASYNC_WorkerRealDF()

	string myDF
	DFREF threadDF
	variable endtime, timeout

	ASYNC_Start(1)
	threadDF = ASYNC_PrepareDF("RunGenericWorker3", "RunGenericReadOut", "TASYNCTest")
	ASYNC_AddParam(threadDF, var=1)
	Make/N=10 data
	ASYNC_AddParam(threadDF, w=data, move=1)
	myDF = GetDataFolder(1)
	ASYNC_AddParam(threadDF, str=myDF)

	ASYNC_Execute(threadDF)

	Make/N=0 returnOrder
	endtime = datetime + THREADING_TEST_TIMEOUT
	timeout = 0
	for(;;)
		ASYNC_ThreadReadOut()
		if(numpnts(returnOrder) == 1)
			break
		endif
		if(datetime > endtime)
			timeout = 1
			break
		endif
	endfor
	CHECK(!timeout)

	ASYNC_Stop(timeout=1)
End

/// @brief Test if ASYNC_Stop does not throw with fromAssert=1
static Function TASYNC_StopForAssert()

	string myDF
	DFREF threadDF
	variable endtime, timeout

	ASYNC_Start(ThreadProcessorCount)
	threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOutAbort", "TASYNCTest")
	ASYNC_AddParam(threadDF, var=1)
	Make/N=10 data
	ASYNC_AddParam(threadDF, w=data, move=1)
	myDF = GetDataFolder(1)
	ASYNC_AddParam(threadDF, str=myDF)

	ASYNC_Execute(threadDF)
	Make/N=0 returnOrder

	ASYNC_Stop(timeout=1, fromAssert=1)
End

/// @brief Test if ASYNC_Execute triggers execution and data is returned through readout.
/// this test uses a worker returning no data folder
static Function TASYNC_WorkerNoDF()

	string myDF
	DFREF threadDF
	variable endtime, timeout

	ASYNC_Start(1)
	threadDF = ASYNC_PrepareDF("RunGenericWorker4", "ReadOutCheckDF", "TASYNCTest")
	ASYNC_AddParam(threadDF, var=1)
	Make/N=10 data
	ASYNC_AddParam(threadDF, w=data, move=1)
	myDF = GetDataFolder(1)
	ASYNC_AddParam(threadDF, str=myDF)

	ASYNC_Execute(threadDF)

	Make/N=0 returnOrder
	endtime = datetime + THREADING_TEST_TIMEOUT
	timeout = 0
	for(;;)
		ASYNC_ThreadReadOut()
		if(numpnts(returnOrder) == 1)
			break
		endif
		if(datetime > endtime)
			timeout = 1
			break
		endif
	endfor
	CHECK(!timeout)

	ASYNC_Stop(timeout=1)
End

/// @brief Test if workloads are correctly processed out of order
/// note: due to the random order there is still a tiny chance that the processing is ordered
/// In such case a warning is given.
static Function TASYNC_RunOrderless()

	variable i
	string myDF
	DFREF threadDF
	variable endtime, timeout
	variable wlCount

	ASYNC_Start(ThreadProcessorCount)

	myDF = GetDataFolder(1)
	for(i = 0;i < WORK_COUNT_GENERIC; i += 1)

		threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest", inOrder=0)
		ASYNC_AddParam(threadDF, var=wlCount)
		Make/N=10 data
		ASYNC_AddParam(threadDF, w=data, move=1)
		ASYNC_AddParam(threadDF, str=myDF)

		ASYNC_Execute(threadDF)
		wlCount += 1
	endfor

	// We can not use the background task for readout, so we have to do it manually
	Make/N=0 returnOrder
	endtime = datetime + THREADING_TEST_TIMEOUT
	for(;;)
		ASYNC_ThreadReadOut()
		if(numpnts(returnOrder) == WORK_COUNT_GENERIC)
			break
		endif
		if(endtime < datetime)
			timeout = 1
			break
		endif
	endfor
	CHECK(!timeout)

	if(!timeout)
		// There are chances the result is still in Order, so we give only a Warning
		for(i = 0;i < WORK_COUNT_GENERIC; i += 1)
			if(returnOrder[i] != i)
				WARN(1)
				break
			endif
		endfor
	endif

	ASYNC_Stop(timeout=1)
End

/// @brief Test if workloads are correctly processed in order
static Function TASYNC_RunInOrder()

	variable i
	DFREF threadDF
	string myDF
	variable endtime, timeout
	variable wlCount

	ASYNC_Start(ThreadProcessorCount)

	myDF = GetDataFolder(1)
	for(i = 0;i < WORK_COUNT_GENERIC; i += 1)

		threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")
		ASYNC_AddParam(threadDF, var=wlCount)
		Make/N=10 data
		ASYNC_AddParam(threadDF, w=data, move=1)
		ASYNC_AddParam(threadDF, str=myDF)

		ASYNC_Execute(threadDF)
		wlCount += 1
	endfor
	// We can not use the background task for readout, so we have to do it manually
	Make/N=0 returnOrder
	endtime = datetime + THREADING_TEST_TIMEOUT
	for(;;)
		ASYNC_ThreadReadOut()
		if(numpnts(returnOrder) == WORK_COUNT_GENERIC)
			break
		endif
		if(endtime < datetime)
			timeout = 1
			break
		endif
	endfor
	CHECK(!timeout)

	if(!timeout)
		for(i = 0;i < WORK_COUNT_GENERIC; i += 1)
			CHECK_EQUAL_VAR(returnOrder[i], i)
		endfor
	endif

	ASYNC_Stop(timeout=1)
End

/// @brief Test if mixed workloads are correctly processed in order, independently
static Function TASYNC_InOrderDiffWL()

	variable i
	DFREF threadDF
	string myDF
	variable endtime, timeout
	variable workCnt = WORK_COUNT_GENERIC * 2
	variable wl1Count, wl2Count

	ASYNC_Start(ThreadProcessorCount)

	myDF = GetDataFolder(1)
	for(i = 0;i < workCnt; i += 1)

		if(mod(i, 2))
			threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")
			ASYNC_AddParam(threadDF, var=wl1Count)
		else
			threadDF = ASYNC_PrepareDF("RunGenericWorker2", "RunGenericReadOut2", "TASYNCTest")
			ASYNC_AddParam(threadDF, var=wl2Count)
		endif
		Make/N=10 data
		ASYNC_AddParam(threadDF, w=data, move=1)
		ASYNC_AddParam(threadDF, str=myDF)

		ASYNC_Execute(threadDF)
		if(mod(i, 2))
			wl1Count += 1
		else
			wl2Count += 1
		endif
	endfor
	// We can not use the background task for readout, so we have to do it manually
	Make/N=0 returnOrder
	Make/N=0 returnOrder2
	endtime = datetime + THREADING_TEST_TIMEOUT
	timeout = 0
	for(;;)
		ASYNC_ThreadReadOut()
		if(numpnts(returnOrder) == workCnt / 2 && numpnts(returnOrder2) == workCnt / 2)
			break
		endif
		if(endtime < datetime)
			timeout = 1
			break
		endif
	endfor
	CHECK(!timeout)

	if(!timeout)
		for(i = 0;i < workCnt / 2; i += 1)
			CHECK_EQUAL_VAR(returnOrder[i], i)
			CHECK_EQUAL_VAR(returnOrder2[i], i)
		endfor
	endif

	ASYNC_Stop(timeout=1)
End

/// @brief Test if errors are returned properly, note: the assertion is in the readout function
static Function TASYNC_RunErrorWorker()

	variable workCnt = ThreadProcessorCount
	variable i
	DFREF threadDF
	string myDF = GetDataFolder(1)
	variable endtime, timeout
	Make/N=0 returnOrder

	ASYNC_Start(ThreadProcessorCount)

	for(i = 0;i < workCnt; i += 1)

		threadDF = ASYNC_PrepareDF("RunWorkerOfDOOM", "RunReadOutOfDOOM", "TASYNCTest")
		ASYNC_AddParam(threadDF, var=i)
		Make/N=10 data
		ASYNC_AddParam(threadDF, w=data, move=1)
		ASYNC_AddParam(threadDF, str=myDF)

		ASYNC_Execute(threadDF)
	endfor
	// We can not use the background task for readout, so we have to do it manually
	endtime = datetime + THREADING_TEST_TIMEOUT
	timeout = 0
	for(;;)
		ASYNC_ThreadReadOut()
		if(numpnts(returnOrder) == workCnt)
			break
		endif
		if(endtime < datetime)
			timeout = 1
			break
		endif
	endfor
	CHECK(!timeout)

	ASYNC_Stop(timeout=1)
End

/// @brief Test if a ReadOut function that generates a runtime error is properly caught.
static Function TASYNC_RunErrorReadOut()

	string myDF
	DFREF threadDF
	variable endtime, timeout

	ASYNC_Start(ThreadProcessorCount)
	threadDF = ASYNC_PrepareDF("RunGenericWorker", "FailReadOut", "TASYNCTest")
	ASYNC_AddParam(threadDF, var=1)
	Make/N=10 data
	ASYNC_AddParam(threadDF, w=data, move=1)
	myDF = GetDataFolder(1)
	ASYNC_AddParam(threadDF, str=myDF)

	ASYNC_Execute(threadDF)

	Make/N=0 returnOrder
	endtime = datetime + THREADING_TEST_TIMEOUT
	timeout = 0
	for(;;)

		try
			ASYNC_ThreadReadOut()
			if(numpnts(returnOrder) == 1)
				FAIL()
			endif
		catch
			PASS()
		endtry

		if(numpnts(returnOrder) == 1)
			break
		endif
		if(datetime > endtime)
			timeout = 1
			break
		endif
	endfor
	CHECK(!timeout)

	ASYNC_Stop(timeout=1)
End

/// @brief Test if a stop on delayed workloads releases the threads properly without force, finishing pending readouts
static Function TASYNC_OrderlessDirectStop()

	variable i
	string myDF
	DFREF threadDF
	variable endtime, timeout
	variable wlCount

	ASYNC_Start(ThreadProcessorCount)

	myDF = GetDataFolder(1)
	for(i = 0;i < WORK_COUNT_GENERIC; i += 1)

		threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest", inOrder=0)
		ASYNC_AddParam(threadDF, var=wlCount)
		Make/N=10 data
		ASYNC_AddParam(threadDF, w=data, move=1)
		ASYNC_AddParam(threadDF, str=myDF)

		ASYNC_Execute(threadDF)
		wlCount += 1
	endfor
	Make/N=0 returnOrder
	timeout=ASYNC_Stop(timeout=THREADING_TEST_TIMEOUT)
	CHECK(!timeout)

	if(!timeout)
		// There are chances the result is still in Order, so we give only a Warning
		for(i = 0;i < WORK_COUNT_GENERIC; i += 1)
			if(returnOrder[i] != i)
				WARN(1)
				break
			endif
		endfor
	endif
End

/// @brief Test if a stop on delayed workloads releases the threads properly without force, discarding queued data for short timeout
static Function TASYNC_StopTimeOut()

	variable i
	string myDF
	DFREF threadDF
	variable endtime, timeout
	variable wlCount

	ASYNC_Start(ThreadProcessorCount)

	myDF = GetDataFolder(1)
	for(i = 0;i < WORK_COUNT_GENERIC; i += 1)

		threadDF = ASYNC_PrepareDF("RunGenericWorker5", "RunGenericReadOut", "TASYNCTest", inOrder=0)
		ASYNC_AddParam(threadDF, var=wlCount)
		Make/N=10 data
		ASYNC_AddParam(threadDF, w=data, move=1)
		ASYNC_AddParam(threadDF, str=myDF)

		ASYNC_Execute(threadDF)
		wlCount += 1
	endfor
	Make/N=0 returnOrder
	timeout=ASYNC_Stop(timeout=0)
	CHECK(timeout)
	CHECK(numpnts(returnOrder) < WORK_COUNT_GENERIC)
End

/// @brief Test if a stop on blocking workloads forcefully stops the threads and throws an assertion
/// note: Igor stops the threads but does not release them from the function module...
static Function TASYNC_StopTimeOutForce()

	variable i, timeout
	DFREF threadDF

	ASYNC_Start(ThreadProcessorCount)

	for(i = 0;i < WORK_COUNT_GENERIC; i += 1)
		threadDF = ASYNC_PrepareDF("InfiniteWorker", "EmptyReadOut", "TASYNCTest", inOrder=0)
		ASYNC_Execute(threadDF)
	endfor
	Make/N=0 returnOrder

	timeout=ASYNC_Stop(timeout = 0)
	PASS()
End

/// @brief Test if a direct stop after pushing mixed workloads finishes all readouts properly on stopping attempt
static Function TASYNC_IODiffWLDirectStop()

	variable i
	DFREF threadDF
	string myDF
	variable endtime, timeout
	variable workCnt = WORK_COUNT_GENERIC * 2
	variable wl1Count, wl2Count

	ASYNC_Start(ThreadProcessorCount)

	myDF = GetDataFolder(1)
	for(i = 0;i < workCnt; i += 1)

		if(mod(i, 2))
			threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "TASYNCTest")
			ASYNC_AddParam(threadDF, var=wl1Count)
		else
			threadDF = ASYNC_PrepareDF("RunGenericWorker2", "RunGenericReadOut2", "TASYNCTest")
			ASYNC_AddParam(threadDF, var=wl2Count)
		endif
		Make/N=10 data
		ASYNC_AddParam(threadDF, w=data, move=1)
		ASYNC_AddParam(threadDF, str=myDF)

		ASYNC_Execute(threadDF)
		if(mod(i, 2))
			wl1Count += 1
		else
			wl2Count += 1
		endif
	endfor
	Make/N=0 returnOrder
	Make/N=0 returnOrder2
	timeout=ASYNC_Stop(timeout=THREADING_TEST_TIMEOUT)
	CHECK(!timeout)

	if(!timeout)
		for(i = 0;i < workCnt / 2; i += 1)
			CHECK_EQUAL_VAR(returnOrder[i], i)
			CHECK_EQUAL_VAR(returnOrder2[i], i)
		endfor
	endif
End

/// @brief Test if workloads tracking works based on class
static Function TASYNC_RunClassSingle()

	variable i
	string myDF
	DFREF threadDF
	variable endtime, timeout
	variable wlCount

	ASYNC_Start(ThreadProcessorCount)

	myDF = GetDataFolder(1)
	for(i = 0;i < WORK_COUNT_GENERIC; i += 1)

		threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "WorkLoadSingleClass1", inOrder=0)
		ASYNC_AddParam(threadDF, var=wlCount)
		Make/N=10 data
		ASYNC_AddParam(threadDF, w=data, move=1)
		ASYNC_AddParam(threadDF, str=myDF)

		ASYNC_Execute(threadDF)
		wlCount += 1
	endfor

	// We can not use the background task for readout, so we have to do it manually
	// Correlate our own returnOrder counter with the tracking done by the frame work
	Make/N=0 returnOrder
	endtime = datetime + THREADING_TEST_TIMEOUT
	for(;;)
		ASYNC_ThreadReadOut()
		if(numpnts(returnOrder) == WORK_COUNT_GENERIC)
			CHECK(ASYNC_IsWorkloadClassDone("WorkLoadSingleClass1"))
			break
		else
			CHECK(!ASYNC_IsWorkloadClassDone("WorkLoadSingleClass1"))
		endif
		if(endtime < datetime)
			timeout = 1
			break
		endif
	endfor
	CHECK(!timeout)

	ASYNC_Stop(timeout=1)
End

/// @brief Test if multiple workloads class tracking works based on class
static Function TASYNC_RunClassDouble()

	variable i
	DFREF threadDF
	string myDF
	variable endtime, timeout
	variable workCnt = WORK_COUNT_GENERIC * 2
	variable wl1Count, wl2Count

	ASYNC_Start(ThreadProcessorCount)

	myDF = GetDataFolder(1)
	for(i = 0;i < workCnt; i += 1)

		if(mod(i, 2))
			threadDF = ASYNC_PrepareDF("RunGenericWorker", "RunGenericReadOut", "WorkLoadDoubleClass1")
			ASYNC_AddParam(threadDF, var=wl1Count)
		else
			threadDF = ASYNC_PrepareDF("RunGenericWorker2", "RunGenericReadOut2", "WorkLoadDoubleClass2")
			ASYNC_AddParam(threadDF, var=wl2Count)
		endif
		Make/N=10 data
		ASYNC_AddParam(threadDF, w=data, move=1)
		ASYNC_AddParam(threadDF, str=myDF)

		ASYNC_Execute(threadDF)
		if(mod(i, 2))
			wl1Count += 1
		else
			wl2Count += 1
		endif
	endfor
	// We can not use the background task for readout, so we have to do it manually
	Make/N=0 returnOrder
	Make/N=0 returnOrder2
	endtime = datetime + THREADING_TEST_TIMEOUT
	timeout = 0
	for(;;)
		ASYNC_ThreadReadOut()
		if(numpnts(returnOrder) == workCnt / 2 && numpnts(returnOrder2) == workCnt / 2)
			CHECK(ASYNC_IsWorkloadClassDone("WorkLoadDoubleClass1"))
			CHECK(ASYNC_IsWorkloadClassDone("WorkLoadDoubleClass2"))
			break
		endif
		if(numpnts(returnOrder) != workCnt / 2)
			CHECK(!ASYNC_IsWorkloadClassDone("WorkLoadDoubleClass1"))
		endif
		if(numpnts(returnOrder2) != workCnt / 2)
			CHECK(!ASYNC_IsWorkloadClassDone("WorkLoadDoubleClass2"))
		endif

		if(endtime < datetime)
			timeout = 1
			break
		endif
	endfor
	CHECK(!timeout)

	ASYNC_Stop(timeout=1)
End

/// @brief Test if workloads class is known
static Function TASYNC_RunClassFail()

	CHECK(IsNaN(ASYNC_IsWorkloadClassDone("UnknownWorkLoadClass")))
End

/// Worker/Readout functions follow

/// @brief Generic worker with a variable runtime, the function transfers required data to the output folder
threadsafe Function/DF RunGenericWorker(dfr)
	DFREF dfr

	DFREF dfrOut = NewFreeDataFolder()

	variable i, j
	string s

	SVAR/SDFR=dfr testDF=param2
	string/G dfrOut:myDF = testDF

	WAVE/SDFR=dfr w=param1
	MoveWave w, dfrOut:outWave

	NVAR/SDFR=dfr v=param0
	variable/G dfrOut:outV = v

	// some processing that has a random runtime
	variable runtime = abs(floor(gnoise(1))) * 10
	for(i = 0; i < runtime; i += 1)
			for(j = 0; j < 100; j += 1)
				s = num2str(i)
			endfor
	endfor

	return dfrOut
End

/// @brief A second generic worker, with a different name, which is identical to the first
threadsafe Function/DF RunGenericWorker2(dfr)
	DFREF dfr

	return RunGenericWorker(dfr)
End

/// @brief Generic worker with a variable runtime, the function transfers required data to the output folder
/// this worker uses a real data folder instead of an empty one
threadsafe Function/DF RunGenericWorker3(dfr)
	DFREF dfr

	NewDataFolder freeroot
	DFREF dfrOut = :freeroot

	variable i, j
	string s

	SVAR/SDFR=dfr testDF=param2
	string/G dfrOut:myDF = testDF

	WAVE/SDFR=dfr w=param1
	MoveWave w, dfrOut:outWave

	NVAR/SDFR=dfr v=param0
	variable/G dfrOut:outV = v

	// some processing that has a random runtime
	variable runtime = abs(floor(gnoise(1))) * 10
	for(i = 0; i < runtime; i += 1)
			for(j = 0; j < 100; j += 1)
				s = num2str(i)
			endfor
	endfor

	return dfrOut
End

/// @brief A worker, that return no data folder
threadsafe Function/DF RunGenericWorker4(dfr)
	DFREF dfr
End

/// @brief Generic worker with a fixed runtime, the function transfers required data to the output folder
/// The fixed runtime should be > granularity of datetime
threadsafe Function/DF RunGenericWorker5(dfr)
	DFREF dfr

	DFREF dfrOut = NewFreeDataFolder()

	variable i, j, now
	string s

	SVAR/SDFR=dfr testDF=param2
	string/G dfrOut:myDF = testDF

	WAVE/SDFR=dfr w=param1
	MoveWave w, dfrOut:outWave

	NVAR/SDFR=dfr v=param0
	variable/G dfrOut:outV = v

	// sleep for 1s, Sleep does not work
	// reliable here on Win7/wine
	now = datetime
	for(;;)
		if(datetime > now + 1)
			break
		endif
	endfor

	return dfrOut
End

/// @brief ReadOut function for combination with RunGenericWorker, order is saved in wave returnOrder
Function RunGenericReadOut(dfr, err, errmsg)
	DFREF dfr
	variable err
	string errmsg

	variable size

	CHECK(!err)

	SVAR/SDFR=dfr testDF=myDF
	NVAR/SDFR=dfr oID=outV
	WAVE retOrder = $(testDF + "returnOrder")
	size = numpnts(retOrder)
	Redimension/N=(size + 1) retOrder
	retOrder[size] = oID
End

/// @brief ReadOut function for combination with RunGenericWorker2, order is saved in wave returnOrder2
Function RunGenericReadOut2(dfr, err, errmsg)
	DFREF dfr
	variable err
	string errmsg

	variable size

	CHECK(!err)

	SVAR/SDFR=dfr testDF=myDF
	NVAR/SDFR=dfr oID=outV
	WAVE retOrder = $(testDF + "returnOrder2")
	size = numpnts(retOrder)
	Redimension/N=(size + 1) retOrder
	retOrder[size] = oID
End

/// @brief ReadOut function for combination with RunGenericWorker, order is saved in wave returnOrder
/// Aborts at end to trigger an exception
Function RunGenericReadOutAbort(dfr, err, errmsg)
	DFREF dfr
	variable err
	string errmsg

	variable size

	CHECK(!err)

	SVAR/SDFR=dfr testDF=myDF
	NVAR/SDFR=dfr oID=outV
	WAVE retOrder = $(testDF + "returnOrder")
	size = numpnts(retOrder)
	Redimension/N=(size + 1) retOrder
	retOrder[size] = oID
	Abort
End

/// @brief Worker that generates a runtime error 330
threadsafe Function/DF RunWorkerOfDOOM(dfr)
	DFREF dfr

	DFREF dfrOut = NewFreeDataFolder()

	SVAR/SDFR=dfr testDF=param2
	string/G dfrOut:myDF = testDF

	NVAR/SDFR=dfr v=param0
	variable/G dfrOut:outV = v

	WAVE/Z w=$""
	w[0] = 0xCAFEBABE
	return dfrOut
End

/// @brief ReadOut function for combination with RunWorkerOfDOOM, checks if Worker generated an error
Function RunReadOutOfDOOM(dfr, err, errmsg)
	DFREF dfr
	variable err
	string errmsg

	CHECK(err == 330)

	SVAR/SDFR=dfr testDF=myDF
	NVAR/SDFR=dfr oID=outV
	WAVE retOrder = $(testDF + "returnOrder")
	variable size = numpnts(retOrder)
	Redimension/N=(size + 1) retOrder
	retOrder[size] = oID
End

/// @brief Worker that sleeps infinitely, thus blocking the thread
threadsafe Function/DF InfiniteWorker(dfr)
	DFREF dfr

	// some processing that has a infinite runtime
	// We want to catch the thread abort RT on IP7
	for(;;)
		try
			InfiniteWorkerHelper_IGNORE();AbortOnRTE
		catch
		endtry
	endfor
End

threadsafe Function InfiniteWorkerHelper_IGNORE()
	Sleep/S 1
End

/// @brief Empty ReadOut function
Function EmptyReadOut(dfr, err, errmsg)
	DFREF dfr
	variable err
	string errmsg
End

/// @brief Empty ReadOut function
Function ReadOutCheckDF(dfr, err, errmsg)
	DFREF dfr
	variable err
	string errmsg

	CHECK(DataFolderExistsDFR(dfr))

	WAVE returnOrder
	Redimension/N=1 returnOrder
End

/// @brief ReadOut function for combination with RunGenericWorker that generates a runtime error 330
Function FailReadOut(dfr, err, errmsg)
	DFREF dfr
	variable err
	string errmsg

	variable size

	CHECK(!err)

	SVAR/SDFR=dfr testDF=myDF
	NVAR/SDFR=dfr oID=outV
	WAVE retOrder = $(testDF + "returnOrder")
	size = numpnts(retOrder)
	Redimension/N=(size + 1) retOrder
	retOrder[size] = oID
	// generate runtime error 330
	WAVE/Z w=$""
	w[0] = 0xCAFEBABE
End
