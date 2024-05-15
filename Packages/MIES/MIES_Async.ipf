#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_ASYNC
#endif

/// @file MIES_Async.ipf
/// @brief __ASYNC__ This file holds the asynchronous execution framework
///
/// \rst
/// See :ref:`async_framework_doc` for the full documentation.
/// \endrst

static StrConstant ASYNC_BACKGROUND    = "AsyncFramework"
static Constant    ASYNC_THREAD_MARKER = 299792458
static Constant    ASYNC_MAX_THREADS   = 64
static Constant    ASYNC_SLEEP_ON_WAIT = 0.01

/// @name Variable names for free data folder structure
/// @{
static StrConstant ASYNC_THREAD_MARKER_STR = "threadDFMarker"
static StrConstant ASYNC_WORKERFUNC_STR    = "WorkerFunc"
static StrConstant ASYNC_READOUTFUNC_STR   = "ReadOutFunc"
static StrConstant ASYNC_WORKLOADCLASS_STR = "workloadClass"
static StrConstant ASYNC_PARAMCOUNT_STR    = "paramCount"
static StrConstant ASYNC_INORDER_STR       = "inOrder"
static StrConstant ASYNC_ABORTFLAG_STR     = "abortFlag"
static StrConstant ASYNC_ERROR_STR         = "err"
static StrConstant ASYNC_ERRORMSG_STR      = "errmsg"
static StrConstant ASYNC_WLCOUNTER_STR     = "workloadClassCounter"
/// @}

/// @brief Starts the Async Framework with numThreads parallel threads.
///
/// @param numThreads number of threads to setup for processing data, must be >= 1 and <= ASYNC_MAX_THREADS
///
/// @param disableTask [optional, default = 0] when set to 1 the background task processing readouts is not started
///
/// @return 1 if ASYNC framework was started, 0 if ASYNC framework was already running, in this case the number of threads is not changed
Function ASYNC_Start(numThreads, [disableTask])
	variable numThreads, disableTask

	variable i

	DFREF dfr = GetAsyncHomeDF()
	if(ASYNC_IsASYNCRunning())
		return 0
	endif

	ASSERT(numThreads >= 1 && numThreads <= ASYNC_MAX_THREADS, "numThread must be > 0 and <= " + num2str(ASYNC_MAX_THREADS))
	disableTask = ParamIsDefault(disableTask) ? 0 : !!disableTask

	NVAR tgID = $GetThreadGroupID()
	NVAR numT = $GetNumThreads()
	numT = numThreads
	WAVE track = GetWorkloadTracking(getAsyncHomeDF())
	Redimension/N=(0, -1) track

	tgID = ThreadGroupCreate(numThreads)

	NVAR noTask = $GetTaskDisableStatus()
	noTask = disableTask
	if(!disableTask)
		CtrlNamedBackground $ASYNC_BACKGROUND, period=1, proc=ASYNC_BackgroundReadOut, start
	endif

#ifndef THREADING_DISABLED
	for(i = 0; i < numThreads; i += 1)
		ThreadStart tgID, i, ASYNC_Thread()
	endfor
#endif

	return 1
End

/// @brief Prototype function for an async worker function
///
/// @param dfr reference to thread data folder
///
/// @return data folder reference to output data folder
threadsafe Function/DF ASYNC_Worker(dfr)
	DFREF dfr
End

/// @brief Prototype function for an async readout function
///
/// @param dfr     reference to returned data folder from thread
/// @param err     error code, only set in the error case
/// @param errmsg  error message, only set in the error case
Function ASYNC_ReadOut(dfr, err, errmsg)
	DFREF    dfr
	variable err
	string   errmsg
End

/// @brief thread function that receives data folders from the thread input queue
/// and calls the setup custom worker function. With :cpp:func:`ASYNC_Start` numThreads :cpp:func:`ASYNC_Thread`
/// functions will be started in their own thread. Each will run until the framework is
/// stopped.
/// UTF_NOINSTRUMENTATION
threadsafe static Function ASYNC_Thread()

	for(;;)
		DFREF dfr = ThreadGroupGetDFR(MAIN_THREAD, 10)
		if(!DataFolderExistsDFR(dfr))
			if(GetRTError(2))
				// Internal abort flag set, closing down
				print "Note: AsyncFrameWork thread forceful aborted."
			endif
			continue
		endif

		NVAR/Z abortFlag = dfr:$ASYNC_ABORTFLAG_STR
		if(NVAR_Exists(abortFlag))
			return 0
		endif

		DFREF dfrOut = ASYNC_Run_Worker(dfr)

		TS_ThreadGroupPutDFR(MAIN_THREAD, dfrOut)
		KillDataFolder dfr
	endfor
End

threadsafe static Function/DF ASYNC_Run_Worker(DFREF dfr)

	DFREF dfrOut, dfrTemp

	SVAR                 WFunc = dfr:$ASYNC_WORKERFUNC_STR
	FUNCREF ASYNC_Worker f     = $WFunc

	DFREF dfrInp   = dfr:input
	DFREF dfrAsync = dfr:async

	variable/G dfrAsync:$ASYNC_ERROR_STR    = 0
	NVAR       err                          = dfrAsync:$ASYNC_ERROR_STR
	string/G   dfrAsync:$ASYNC_ERRORMSG_STR = ""
	SVAR       errmsg                       = dfrAsync:$ASYNC_ERRORMSG_STR

	err    = 0
	dfrOut = $""
	AssertOnAndClearRTError()
	try
		dfrOut = f(dfrInp); AbortOnRTE
	catch
		errmsg = GetRTErrMessage()
		err    = ClearRTError()
	endtry

	if(IsFreeDatafolder(dfrOut))
		MoveDataFolder dfrOut, dfrAsync
	elseif(DataFolderExistsDFR(dfrOut))
		MoveDataFolder dfrOut, dfrAsync
		RenameDataFolder dfrOut, $DF_NAME_FREE
	else
		NewDataFolder dfrAsync:$DF_NAME_FREE
	endif

	return dfrAsync
End

/// @brief Receives data from finished workloads. Calls the user defined readout function.
/// For in order readouts this function buffers pending result data folders until they can be processed in order.
Function ASYNC_ThreadReadOut()
	variable bufferSize, i
	variable justBuffered

	variable wlcIndex, statCnt, index
	string rterrmsg
	NVAR tgID = $GetThreadGroupID()
	ASSERT(!isNaN(tgID), "Async frame work is not running")
	WAVE/DF DFREFbuffer = GetDFREFBuffer(getAsyncHomeDF())
	WAVE    track       = GetWorkloadTracking(getAsyncHomeDF())

	for(;;)
#ifdef THREADING_DISABLED
		WAVE/DF serialExecutionBuffer = GetSerialExecutionBuffer(getAsyncHomeDF())
		index = GetNumberFromWaveNote(serialExecutionBuffer, NOTE_INDEX)
		if(index > 0)
			DFREF dfr = serialExecutionBuffer[--index]
			SetNumberInWaveNote(serialExecutionBuffer, NOTE_INDEX, index)
		else
			DFREF dfr = $""
		endif
#else
		DFREF dfr = ThreadGroupGetDFR(tgID, 0)
#endif

		if(!DataFolderExistsDFR(dfr))

			if(justBuffered)
				return 0
			endif

			// Can we process one of the buffered results?
			bufferSize = numpnts(DFREFbuffer)
			for(i = 0; i < bufferSize; i += 1)
				DFREF dfr    = DFREFbuffer[i]
				DFREF dfrOut = dfr:$DF_NAME_FREE

				WAVE workloadClassCounter = dfr:$ASYNC_WLCOUNTER_STR
				SVAR workloadClass        = dfr:$ASYNC_WORKLOADCLASS_STR
				wlcIndex = FindDimLabel(track, ROWS, workloadClass)
				ASSERT(wlcIndex >= 0, "Could not find work load class")
				if(workloadClassCounter[0] - track[wlcIndex][%OUTPUTCOUNT] == 0)
					DeletePoints i, 1, DFREFbuffer
					break
				endif

			endfor

			if(i == bufferSize)
				DEBUGPRINT("Async: Number of ReadOut called: " + num2str(statCnt) + " Number buffered; " + num2str(DimSize(DFREFBuffer, ROWS)))
				return 0
			endif
		else
			// check for inOrder, do we need to buffer?
			DFREF dfrOut        = dfr:$DF_NAME_FREE
			SVAR  workloadClass = dfr:$ASYNC_WORKLOADCLASS_STR
			if(track[%$workloadClass][%INORDER])
				WAVE workloadClassCounter = dfr:$ASYNC_WLCOUNTER_STR
				wlcIndex = FindDimLabel(track, ROWS, workloadClass)
				ASSERT(wlcIndex >= 0, "Could not find work load class")
				if(workloadClassCounter[0] - track[wlcIndex][%OUTPUTCOUNT] != 0)
					bufferSize = numpnts(DFREFbuffer)
					Redimension/N=(bufferSize + 1) DFREFbuffer
					DFREFbuffer[bufferSize] = dfr
					justBuffered            = 1
					continue
				endif

				justBuffered = 0

			endif
		endif

		track[%$workloadClass][%OUTPUTCOUNT] += 1

		SVAR                  RFunc  = dfr:$ASYNC_READOUTFUNC_STR
		FUNCREF ASYNC_ReadOut f      = $RFunc
		NVAR                  err    = dfr:$ASYNC_ERROR_STR
		SVAR                  errmsg = dfr:$ASYNC_ERRORMSG_STR

		statCnt += 1
		AssertOnAndClearRTError()
		try
			f(dfrOut, err, errmsg); AbortOnRTE
		catch
			rterrmsg = GetRTErrMessage()
			ClearRTError()
			ASSERT(0, "ReadOut function " + RFunc + " aborted with: " + rterrmsg)
		endtry

	endfor
End

/// @brief Allows to check if all executed work loads of a specific work load class were read out.
///        For that case, the work load class can optionally be removed from Async.
/// @param[in] workloadClass work load class string
/// @param[in] removeClass [optional, default = 0] when set the specified work load class is removed from Async
///                        The parameter has no effect, if the work loads of the specified class are not done.
/// @returns 1 if work load class finished, 0 if work load class did not finish, NaN if work load class not known to ASYNC
Function ASYNC_IsWorkloadClassDone(string workloadClass, [variable removeClass])

	variable done, index

	if(IsEmpty(workloadClass))
		return NaN
	endif
	WAVE track = GetWorkloadTracking(getAsyncHomeDF())
	index = FindDimLabel(track, ROWS, workloadClass)
	if(!(index >= 0))
		return NaN
	endif

	removeClass = ParamIsDefault(removeClass) ? 0 : !!removeClass

	done = (track[%$workloadClass][%INPUTCOUNT] - track[%$workloadClass][%OUTPUTCOUNT]) == 0

	if(removeClass && done)
		DeleteWavePoint(track, ROWS, index = index)
	endif

	return done
End

/// @brief Wait for TP analysis from specific panel to finish and remove it
/// @param[in] workloadClass name of work load class
/// @param[in] timeout time out in seconds
/// @returns 0 if work load class is unknown or has finished and was removed, 1 if timeout was encountered.
Function ASYNC_WaitForWLCToFinishAndRemove(string workloadClass, variable timeout)

	variable result

	timeout += datetime
	for(;;)
		result = ASYNC_IsWorkloadClassDone(workloadClass, removeClass = 1)
		if(IsNaN(result))
			return 0
		endif
		if(result)
			return 0
		endif

		ASYNC_ThreadReadOut()
		if(datetime > timeout)
			return 1
		endif
		Sleep/S ASYNC_SLEEP_ON_WAIT
	endfor
End

/// @brief Background function that reads data folders from the thread output queue
/// and calls the setup custom readout function
/// The function takes care to buffer results if they should be processed in order.
///
/// @param s default structure for Igor background tasks
Function ASYNC_BackgroundReadOut(s)
	STRUCT WMBackgroundStruct &s

	return ASYNC_ThreadReadOut()
End

/// @brief Adds one parameter to a data folder for a threaded worker execution
///
/// The parameters are globals in the threads data folder and named param0, param1, param2... in order of adding them.
/// Only one parameter can be added per call. move is only allowed in combination with a wave.
///
/// @param dfr data folder reference to thread df, prepared by calling ASYNC_PrepareDF
/// @param w [optional, default = null] wave reference of wave to be added as parameter
/// @param var [optional, default = 0] variable to be added as parameter
/// @param str [optional, default = 0] string to be added as parameter
/// @param move [optional, default = 0] if a wave was given as parameter and move is not zero then the wave is moved to the threads data folder
/// @param name [optional, default = paramXXX] name of the added parameter
Function ASYNC_AddParam(dfr, [w, var, str, move, name])
	DFREF    dfr
	WAVE     w
	variable var
	string   str
	variable move
	string   name

	variable paramCnt
	string   paramName

	ASSERT(ASYNC_isThreadDF(dfr), "Invalid data folder or not a thread data folder")
	DFREF dfrInp = dfr:input

	NVAR/Z paramCount = dfrInp:$ASYNC_PARAMCOUNT_STR
	ASSERT(NVAR_Exists(paramCount), "Thread Datafolder not properly prepared, requires paramCount variable")

	move = ParamIsDefault(move) ? 0 : !!move
	ASSERT(!(!ParamIsDefault(move) && (!ParamIsDefault(str) || !ParamIsDefault(var))), "move is only allowed in combination with a wave")

	paramCnt += 3 - ParamIsDefault(w) - ParamIsDefault(var) - ParamIsDefault(str)
	ASSERT(paramCnt == 1, "You can build the input wave only with one parameter at a time")

	if(ParamIsDefault(name))
		paramName = "param" + num2str(paramCount)
	else
		paramName = name
	endif

	if(!ParamIsDefault(w))
		if(move)
			MoveWave w, dfrInp:$paramName
		else
			Duplicate w, dfrInp:$paramName
		endif
	elseif(!ParamIsDefault(var))
		variable/G dfrInp:$paramName = var
	elseif(!ParamIsDefault(str))
		string/G dfrInp:$paramName = str
	endif

	paramCount += 1
End

/// @brief Fetch a wave from the DFREF in the worker function
threadsafe Function/WAVE ASYNC_FetchWave(DFREF dfr, string name)

	WAVE/Z/SDFR=dfr wv = $name
	ASSERT_TS(WaveExists(wv), "Missing wave: " + name)

	return wv
End

/// @brief Fetch a variable from the DFREF in the worker function
threadsafe Function ASYNC_FetchVariable(DFREF dfr, string name)

	NVAR/Z/SDFR=dfr var = $name
	ASSERT_TS(NVAR_Exists(var), "Missing variable: " + name)

	return var
End

/// @brief Fetch a string from the DFREF in the worker function
threadsafe Function/S ASYNC_FetchString(DFREF dfr, string name)

	SVAR/Z/SDFR=dfr str = $name
	ASSERT_TS(SVAR_Exists(str), "Missing string: " + name)

	return str
End

/// @brief Stops the Async Framework
///
/// @param timeout [optional, default = Inf] time in s to wait for running threads, the function waits for pending threads and pending readouts within this time.
/// After a timeout happened the readout processing is stopped and threads are stopped. Any pending data is lost.
/// If the threads have to be stopped forcefully, an assertion is raised.
/// Using a finite timeout is strongly recommended.
///
/// @param fromAssert [optional, default = 0] specified when called as cleanup function from ASSERT
/// Suppresses further assertions such that all required cleanup routines such as ThreadGroupRelease
/// are executed.
///
/// @return 2 if ASYNC framework was not running, 1 if a timeout was encountered, 0 otherwise
Function ASYNC_Stop([timeout, fromAssert])
	variable timeout, fromAssert

	variable i, endtime, waitResult, localtgID, outatime, err, doe, d
	variable inputCount, outputCount

	if(!ASYNC_IsASYNCRunning())
		return 2
	endif

	doe = DisableDebugOnError()

	NVAR tgID = $GetThreadGroupID()
	fromAssert = ParamIsDefault(fromAssert) ? 0 : !!fromAssert

#ifdef THREADING_DISABLED
	ASYNC_ThreadReadOut()
#else
	// Send abort to all threads
	NVAR numThreads = $GetNumThreads()
	for(i = 0; i < numThreads; i += 1)
		DFREF dfr = NewFreeDataFolder()
		NewDataFolder dfr:async
		DFREF      dfrAsync                    = dfr:async
		variable/G dfrAsync:$ASYNC_INORDER_STR = 0
		variable/G dfr:$ASYNC_ABORTFLAG_STR
		variable/G dfr:$ASYNC_THREAD_MARKER_STR
		NVAR marker = dfr:$ASYNC_THREAD_MARKER_STR
		marker = ASYNC_THREAD_MARKER
		if(fromAssert)
			try
				ClearRTError()
				ASYNC_Execute(dfr); AbortOnRTE
			catch
				ClearRTError()
			endtry
		else
			ASYNC_Execute(dfr)
		endif
	endfor

	// Wait for all threads to finish (or timeout)
	if(ParamIsDefault(timeout))
		timeout = Inf
	endif

	endTime = dateTime + timeout
	do
		AssertOnAndClearRTError()
		try
			waitResult = ThreadGroupWait(tgID, 0); AbortOnRTE
		catch
			ClearRTError()
			waitResult = 0
		endtry

		if(dateTime >= endtime)
			outatime = 1
			break
		endif
	while(waitResult != 0)
#endif

	NVAR noTask = $GetTaskDisableStatus()
	if(!noTask)
		CtrlNamedBackground $ASYNC_BACKGROUND, stop
	endif

	if(!outatime)

		WAVE track = GetWorkloadTracking(getAsyncHomeDF())
		if(DimSize(track, ROWS) > 0)
			for(;;)
				d = FindDimLabel(track, COLS, "INPUTCOUNT")
				WaveStats/Q/M=1/RMD=[][d] track
				inputCount = V_Sum
				d          = FindDimLabel(track, COLS, "OUTPUTCOUNT")
				WaveStats/Q/M=1/RMD=[][d] track
				outputCount = V_Sum
				if(inputCount == outputCount)
					break
				endif

				if(fromAssert)
					try
						ClearRTError()
						ASYNC_ThreadReadOut(); AbortOnRTE
					catch
						ClearRTError()
					endtry
				else
					ASYNC_ThreadReadOut()
				endif

				if(datetime >= endtime)
					outatime = 1
					break
				endif

			endfor
		endif
	endif

	ResetDebugOnError(doe)

	localtgID = tgID
	KillDataFolder GetAsyncHomeDF()
	err = ThreadGroupRelease(localtgID)
	if(!fromAssert)
		ASSERT(err != -2, "Async framework stopped forcefully")
	endif

	return outatime
End

/// @brief Prepares a thread data folder for use with the AsyncFramework
/// This function should be called first when setting up a worker with parameters
///
/// @param WorkerFunc string naming a threadsafe worker function in the form of the ASYNC_Worker template
///
/// @param ReadOutFunc string naming a readout function in the form of the ASYNC_ReadOut template
///
/// @param workloadClass string naming a work load class for work load attribution like "TestPulse"
///        The string must follow strict object naming rules.
///
/// @param inOrder [optional, default = 1] flag that allows to disable in order readout of results
///
/// @return data folder for thread, where parameters can be put to with :cpp:func:`ASYNC_AddParam`
Function/DF ASYNC_PrepareDF(string WorkerFunc, string ReadOutFunc, string workloadClass, [variable inOrder])

	ASSERT(!IsEmpty(workloadClass), "No work load class string specified")
	ASSERT(IsValidObjectName(workloadClass), "Work load class name does not follow strict object naming rules")
	FUNCREF ASYNC_Worker fw = $WorkerFunc
	ASSERT(FuncRefIsAssigned(FuncRefInfo(fw)), "set worker function has the wrong parameter template")
	FUNCREF ASYNC_ReadOut fr = $ReadOutFunc
	ASSERT(FuncRefIsAssigned(FuncRefInfo(fr)), "set readout function has the wrong parameter template")

	inOrder = ParamIsDefault(inOrder) ? 1 : !!inOrder

	DFREF dfr = NewFreeDatafolder()
	NewDataFolder dfr:input
	DFREF dfrInp = dfr:input
	NewDataFolder dfr:async
	DFREF dfrAsync = dfr:async

	string/G dfr:$ASYNC_WORKERFUNC_STR = WorkerFunc

	string/G   dfrAsync:$ASYNC_READOUTFUNC_STR = ReadOutFunc
	variable/G dfrAsync:$ASYNC_INORDER_STR     = inOrder

	variable/G dfrInp:$ASYNC_PARAMCOUNT_STR = 0

	variable/G dfr:$ASYNC_THREAD_MARKER_STR
	NVAR marker = dfr:$ASYNC_THREAD_MARKER_STR
	marker = ASYNC_THREAD_MARKER

	string/G dfrAsync:$ASYNC_WORKLOADCLASS_STR = workloadClass

	return dfr
End

/// @brief Puts a prepared thread data folder to parallel execution in another thread
///
/// @param dfr data folder that is setup for thread and is to be deployed
Function ASYNC_Execute(dfr)
	DFREF dfr

	variable orderIndex, size, index

	ASSERT(ASYNC_IsThreadDF(dfr), "Invalid data folder or not a thread data folder")
	NVAR tgID = $GetThreadGroupID()
	ASSERT(!isNaN(tgID), "Async frame work is not running")

	KillVariables dfr:$ASYNC_THREAD_MARKER_STR

	DFREF dfrAsync = dfr:async

	SVAR/Z workloadClass = dfrAsync:$ASYNC_WORKLOADCLASS_STR
	if(SVAR_Exists(workloadClass))
		NVAR inOrder = dfrAsync:$ASYNC_INORDER_STR
		WAVE track   = GetWorkloadTracking(getAsyncHomeDF())
		if(!(FindDimLabel(track, ROWS, workloadClass) >= 0))
			size = DimSize(track, ROWS)
			Redimension/N=(size + 1, -1) track
			SetDimLabel ROWS, size, $workloadClass, track

			track[%$workloadClass][%INORDER] = inOrder
		else
			ASSERT(track[%$workloadClass][%INORDER] == inOrder, "Can not mix ordered/unordered work load execution in the same class.")
		endif

		KillVariables dfrAsync:$ASYNC_INORDER_STR

		Make/L/U/N=1 dfrAsync:$ASYNC_WLCOUNTER_STR/WAVE=wlCounter
		wlCounter[0] = track[%$workloadClass][%INPUTCOUNT]

		track[%$workloadClass][%INPUTCOUNT] += 1
	endif

#ifdef THREADING_DISABLED
	DFREF   result                = ASYNC_Run_Worker(dfr)
	WAVE/DF serialExecutionBuffer = GetSerialExecutionBuffer(getAsyncHomeDF())
	index = GetNumberFromWaveNote(serialExecutionBuffer, NOTE_INDEX)
	EnsureLargeEnoughWave(serialExecutionBuffer, indexShouldExist = index)
	serialExecutionBuffer[index] = result
	SetNumberInWaveNote(serialExecutionBuffer, NOTE_INDEX, ++index)
#else
	TS_ThreadGroupPutDFR(tgID, dfr)
#endif

End

/// @brief test if data folder is marked for thread usage
///
/// UTF_NOINSTRUMENTATION
static Function ASYNC_IsThreadDF(dfr)
	DFREF dfr

	NVAR/Z marker = dfr:$ASYNC_THREAD_MARKER_STR
	if(NVAR_Exists(marker))
		return marker == ASYNC_THREAD_MARKER
	else
		return 0
	endif
End

/// @brief returns 1 if ASYNC framework is running, 0 otherwise
static Function ASYNC_IsASYNCRunning()

	variable waitResult, err

	NVAR tgID = $GetThreadGroupID()

#ifdef THREADING_DISABLED
	return !IsNaN(tgID)
#else
	AssertOnAndClearRTError()
	waitResult = ThreadGroupWait(tgID, 0); err = GetRTError(1)
#endif

	return err == 0 && waitResult != 0
End
