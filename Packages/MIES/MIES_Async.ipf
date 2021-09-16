#pragma TextEncoding = "UTF-8"
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

static StrConstant ASYNC_BACKGROUND = "AsyncFramework"
static Constant MAX_OBJECT_NAME_LENGTH_IN_BYTES = 255
static Constant ASYNC_THREAD_MARKER = 299792458
static Constant ASYNC_MAX_THREADS = 64
static Constant ASYNC_SLEEP_ON_WAIT = 0.01

/// @name Common Constants
/// @{
static Constant ROWS = 0
static Constant COLS = 1
static Constant LAYERS = 2
static Constant CHUNKS = 3
/// @}

/// @name Variable names for free data folder structure
/// @{
static StrConstant ASYNC_THREAD_MARKER_STR = "threadDFMarker"
static StrConstant ASYNC_WORKERFUNC_STR = "WorkerFunc"
static StrConstant ASYNC_READOUTFUNC_STR = "ReadOutFunc"
static StrConstant ASYNC_WORKLOADCLASS_STR = "workloadClass"
static StrConstant ASYNC_PARAMCOUNT_STR = "paramCount"
static StrConstant ASYNC_INORDER_STR = "inOrder"
static StrConstant ASYNC_ABORTFLAG_STR = "abortFlag"
static StrConstant ASYNC_ERROR_STR = "err"
static StrConstant ASYNC_ERRORMSG_STR = "errmsg"
static StrConstant ASYNC_WLCOUNTER_STR = "workloadClassCounter"
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
	DFREF dfr
	variable err
	string errmsg
End

/// @brief thread function that receives data folders from the thread input queue
/// and calls the setup custom worker function. With :cpp:func:`ASYNC_Start` numThreads :cpp:func:`ASYNC_Thread`
/// functions will be started in their own thread. Each will run until the framework is
/// stopped.
threadsafe static Function ASYNC_Thread()

	for(;;)
		DFREF dfr = ThreadGroupGetDFR(0, 10)
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

		TS_ThreadGroupPutDFR(0, dfrOut)
		KillDataFolder dfr
	endfor
End

threadsafe static Function/DF ASYNC_Run_Worker(DFREF dfr)

	DFREF dfrOut, dfrTemp

	SVAR WFunc = dfr:$ASYNC_WORKERFUNC_STR
	FUNCREF ASYNC_Worker f = $WFunc

	DFREF dfrInp = dfr:input
	DFREF dfrAsync = dfr:async

	variable/G dfrAsync:$ASYNC_ERROR_STR = 0
	NVAR err = dfrAsync:$ASYNC_ERROR_STR
	string/G dfrAsync:$ASYNC_ERRORMSG_STR = ""
	SVAR errmsg = dfrAsync:$ASYNC_ERRORMSG_STR

	err = 0
	dfrOut = $""
	try
		ClearRTError()
		dfrOut = f(dfrInp);AbortOnRTE
	catch
		errmsg = GetRTErrMessage()
		err = ClearRTError()
	endtry

	if(DataFolderRefStatus(dfrOut) == 3)
		MoveDataFolder dfrOut, dfrAsync
	elseif(DataFolderExistsDFR(dfrOut))
		MoveDataFolder dfrOut, dfrAsync
		RenameDataFolder dfrOut, freeroot
	else
		NewDataFolder dfrAsync:freeroot
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
	WAVE track = GetWorkloadTracking(getAsyncHomeDF())

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
				DFREF dfr = DFREFbuffer[i]
				DFREF dfrOut = dfr:freeroot

				WAVE workloadClassCounter = dfr:$ASYNC_WLCOUNTER_STR
				SVAR workloadClass = dfr:$ASYNC_WORKLOADCLASS_STR
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
			DFREF dfrOut = dfr:freeroot
			SVAR workloadClass = dfr:$ASYNC_WORKLOADCLASS_STR
			if(track[%$workloadClass][%INORDER])
				WAVE workloadClassCounter = dfr:$ASYNC_WLCOUNTER_STR
				wlcIndex = FindDimLabel(track, ROWS, workloadClass)
				ASSERT(wlcIndex >= 0, "Could not find work load class")
				if(workloadClassCounter[0] - track[wlcIndex][%OUTPUTCOUNT] != 0)
					bufferSize = numpnts(DFREFbuffer)
					Redimension/N=(bufferSize + 1) DFREFbuffer
					DFREFbuffer[bufferSize] = dfr
					justBuffered = 1
					continue
				endif

				justBuffered = 0

			endif
		endif

		track[%$workloadClass][%OUTPUTCOUNT] += 1

		SVAR RFunc = dfr:$ASYNC_READOUTFUNC_STR
		FUNCREF ASYNC_ReadOut f = $RFunc
		NVAR err = dfr:$ASYNC_ERROR_STR
		SVAR errmsg = dfr:$ASYNC_ERRORMSG_STR

		statCnt += 1
		try
			ClearRTError()
			f(dfrOut, err, errmsg);AbortOnRTE
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
		DeleteWavePoint(track, ROWS, index)
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
	DFREF dfr
	WAVE w
	variable var
	string str
	variable move
	string name

	variable paramCnt
	string paramName

	ASSERT(isThreadDF(dfr), "Invalid data folder or not a thread data folder")
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
		DFREF dfrAsync = dfr:async
		variable/G dfrAsync:$ASYNC_INORDER_STR = 0
		variable/G dfr:$ASYNC_ABORTFLAG_STR
		variable/G dfr:$ASYNC_THREAD_MARKER_STR
		NVAR marker = dfr:$ASYNC_THREAD_MARKER_STR
		marker = ASYNC_THREAD_MARKER
		if(fromAssert)
			try
				ClearRTError()
				ASYNC_Execute(dfr);AbortOnRTE
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
		try
			ClearRTError()
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
				d = FindDimLabel(track, COLS, "OUTPUTCOUNT")
				WaveStats/Q/M=1/RMD=[][d] track
				outputCount = V_Sum
				if(inputCount == outputCount)
					break
				endif

				if(fromAssert)
					try
						ClearRTError()
						ASYNC_ThreadReadOut();AbortOnRTE
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
Function/DF ASYNC_PrepareDF(string WorkerFunc, string ReadOutFunc, string workloadClass,[variable inOrder])

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

	string/G dfrAsync:$ASYNC_READOUTFUNC_STR = ReadOutFunc
	variable/G dfrAsync:$ASYNC_INORDER_STR = inOrder

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

	ASSERT(isThreadDF(dfr), "Invalid data folder or not a thread data folder")
	NVAR tgID = $GetThreadGroupID()
	ASSERT(!isNaN(tgID), "Async frame work is not running")

	KillVariables dfr:$ASYNC_THREAD_MARKER_STR

	DFREF dfrAsync = dfr:async

	SVAR/Z workloadClass = dfrAsync:$ASYNC_WORKLOADCLASS_STR
	if(SVAR_Exists(workloadClass))
		NVAR inOrder = dfrAsync:$ASYNC_INORDER_STR
		WAVE track = GetWorkloadTracking(getAsyncHomeDF())
		if(!(FindDimLabel(track, ROWS, workloadClass) >= 0))
			size = DimSize(track, ROWS)
			Redimension/N=(size + 1, -1) track
			SetDimLabel ROWS, size, $workloadClass, track

			track[%$workloadClass][%INORDER] = inOrder
		else
			ASSERT(track[%$workloadClass][%INORDER] == inOrder, "Can not mix ordered/unordered work load execution in the same class.")
		endif

		KillVariables dfrAsync:$ASYNC_INORDER_STR

		Make/L/U/N=1 dfrAsync:$ASYNC_WLCOUNTER_STR/Wave=wlCounter
		wlCounter[0] = track[%$workloadClass][%INPUTCOUNT]

		track[%$workloadClass][%INPUTCOUNT] += 1
	endif

#ifdef THREADING_DISABLED
	DFREF result = ASYNC_Run_Worker(dfr)
	WAVE/DF serialExecutionBuffer = GetSerialExecutionBuffer(getAsyncHomeDF())
	index = GetNumberFromWaveNote(serialExecutionBuffer, NOTE_INDEX)
	EnsureLargeEnoughWave(serialExecutionBuffer, minimumSize = index)
	serialExecutionBuffer[index] = result
	SetNumberInWaveNote(serialExecutionBuffer, NOTE_INDEX, ++index)
#else
	TS_ThreadGroupPutDFR(tgID, dfr)
#endif

End

/// @brief Returns 1 if var is a finite/normal number, 0 otherwise
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe static Function IsFinite(var)
	variable var

	return numType(var) == 0
End

/// @brief Returns one if str is empty or null, zero otherwise.
/// @param str must not be a SVAR
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe static Function IsEmpty(str)
	string& str

	variable len = strlen(str)
	return numtype(len) == 2 || len <= 0
End

/// @brief Returns 1 if var is a NaN, 0 otherwise
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe static Function IsNaN(var)
	variable var

	return numType(var) == 2
End

/// @brief Checks if the datafolder referenced by dfr exists.
///
/// Unlike DataFolderExists() a dfref pointing to an empty ("") dataFolder is considered non-existing here.
/// @returns one if dfr is valid and references an existing or free datafolder, zero otherwise
/// Taken from http://www.igorexchange.com/node/2055
threadsafe static Function DataFolderExistsDFR(dfr)
	dfref dfr

	string dataFolder

	switch(DataFolderRefStatus(dfr))
		case 0: // invalid ref, does not exist
			return 0
		case 1: // might be valid
			dataFolder = GetDataFolder(1,dfr)
			return cmpstr(dataFolder,"") != 0 && DataFolderExists(dataFolder)
		case 3: // free data folders always exist
			return 1
		default:
			ASSERT_TS(0, "impossible case")
			return 0
	endswitch
End

/// @brief Return a nicely formatted multiline stacktrace
static Function/S GetStackTrace([prefix])
	string prefix

	string stacktrace, entry, func, line, file, str
	string output
	variable i, numCallers

	if(ParamIsDefault(prefix))
		prefix = ""
	endif

	stacktrace = GetRTStackInfo(3)
	numCallers = ItemsInList(stacktrace)

	if(numCallers < 3)
		// our caller was called directly
		return "Stacktrace not available"
	endif

	output = prefix + "Stacktrace:\r"

	for(i = 0; i < numCallers - 2; i += 1)
		entry = StringFromList(i, stacktrace)
		func  = StringFromList(0, entry, ",")
		file  = StringFromList(1, entry, ",")
		line  = StringFromList(2, entry, ",")
		sprintf str, "%s%s(...)#L%s [%s]\r", prefix, func, line, file
		output += str
	endfor

	return output
End
/// @brief Low overhead function to check assertions
///
/// @param var      if zero an error message is printed into the history and procedure execution is aborted,
///                 nothing is done otherwise.  If the debugger is enabled, it also steps into it.
/// @param errorMsg error message to output in failure case
///
/// Example usage:
/// \rst
/// .. code-block:: igorpro
///
/// 	ControlInfo/W = $panelTitle popup_MoreSettings_DeviceType
/// 	ASSERT(V_flag > 0, "Non-existing control or window")
/// 	do something with S_value
/// \endrst
///
/// @hidecallgraph
/// @hidecallergraph
static Function ASSERT(var, errorMsg)
	variable var
	string errorMsg

	string stracktrace, miesVersionStr


	try
		AbortOnValue var==0, 1
	catch
		// Recursion detection, if ASSERT appears multiple times in StackTrace
		if (ItemsInList(ListMatch(GetRTStackInfo(0), GetRTStackInfo(1))) > 1)

			// Happens e.g. when ASSERT is encounterd in cleanup functions
			print "Double Assertion Fail encountered !"
#ifndef AUTOMATED_TESTING
			DoWindow/H
			Debugger
#endif // AUTOMATED_TESTING

			Abort
		endif
		print "!!! Assertion FAILED !!!"
		printf "Message: \"%s\"\r", RemoveEnding(errorMsg, "\r")

#ifndef AUTOMATED_TESTING
		print "################################"
		print GetStackTrace()
		print "################################"

		DoWindow/H
		Debugger
#endif // AUTOMATED_TESTING

		Abort
	endtry
End

/// @brief Low overhead function to check assertions (threadsafe variant)
///
/// @param var      if zero an error message is printed into the history and procedure execution is aborted,
///                 nothing is done otherwise.
/// @param errorMsg error message to output in failure case
///
/// Example usage:
/// \rst
///  .. code-block:: igorpro
///
///		ASSERT(DataFolderExistsDFR(dfr), "MyFunc: dfr does not exist")
///		do something with dfr
/// \endrst
///
/// Unlike ASSERT() this function does not print a stacktrace or jumps into the debugger. The reasons are Igor Pro limitations.
/// Therefore it is advised to prefix `errorMsg` with the current function name.
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe static Function ASSERT_TS(var, errorMsg)
	variable var
	string errorMsg

	try
		AbortOnValue var==0, 1
	catch
		printf "Assertion FAILED with message %s\r", errorMsg
		AbortOnValue 1, 1
	endtry
End

/// @brief Check wether the function reference points to
/// the prototype function or to an assigned function
///
/// Due to Igor Pro limitations you need to pass the function
/// info from `FuncRefInfo` and not the function reference itself.
///
/// @return 1 if pointing to prototype function, 0 otherwise
threadsafe static Function FuncRefIsAssigned(funcInfo)
	string funcInfo

	variable result

	ASSERT_TS(!isEmpty(funcInfo), "Empty function info")
	result = NumberByKey("ISPROTO", funcInfo)
	ASSERT_TS(IsFinite(result), "funcInfo does not look like a FuncRefInfo string")

	return result == 0
End

/// @brief Returns the full path to a global variable
///
/// @param dfr           location of the global variable, must exist
/// @param globalVarName name of the global variable
/// @param initialValue  initial value of the variable. Will only be used if
/// 					 it is created. 0 by default.
static Function/S GetNVARAsString(dfr, globalVarName, [initialValue])
	dfref dfr
	string globalVarName
	variable initialValue

	ASSERT_TS(DataFolderExistsDFR(dfr), "Missing dfr")

	NVAR/Z/SDFR=dfr var = $globalVarName
	if(!NVAR_Exists(var))
		variable/G dfr:$globalVarName

		NVAR/SDFR=dfr var = $globalVarName

		if(!ParamIsDefault(initialValue))
			var = initialValue
		endif
	endif

	return GetDataFolder(1, dfr) + globalVarName
End

/// @brief Returns the full path to a global string
///
/// @param dfr           location of the global string, must exist
/// @param globalStrName name of the global string
/// @param initialValue  initial value of the string. Will only be used if
/// 					 it is created. null by default.
threadsafe static Function/S GetSVARAsString(dfr, globalStrName, [initialValue])
	dfref dfr
	string globalStrName
	string initialValue

	ASSERT_TS(DataFolderExistsDFR(dfr), "Missing dfr")

	SVAR/Z/SDFR=dfr str = $globalStrName
	if(!SVAR_Exists(str))
		String/G dfr:$globalStrName

		SVAR/SDFR=dfr str = $globalStrName

		if(!ParamIsDefault(initialValue))
			str = initialValue
		endif
	endif

	return GetDataFolder(1, dfr) + globalStrName
End

/// @brief Create a datafolder and all its parents,
///
/// @hidecallgraph
/// @hidecallergraph
///
/// Includes fast handling of the common case that the datafolder exists.
/// @returns reference to the datafolder
threadsafe static Function/DF createDFWithAllParents(dataFolder)
	string dataFolder

	variable i, numItems
	string partialPath
	DFREF dfr = $dataFolder

	if(DataFolderRefStatus(dfr))
		return dfr
	endif

	partialPath = "root"

	// i=1 because we want to skip root, as this exists always
	numItems = ItemsInList(dataFolder,":")
	for(i=1; i < numItems ; i+=1)
		partialPath += ":"
		partialPath += StringFromList(i,dataFolder,":")
		if(!DataFolderExists(partialPath))
			NewDataFolder $partialPath
		endif
	endfor

	return $dataFolder
end

/// @brief Returns string path to async framework home data folder
static Function/S GetAsyncHomeStr()
	return "root:Packages:Async"
End

/// @brief Returns reference to async framework home data folder
static Function/DF GetAsyncHomeDF()
	return createDFWithAllParents(getAsyncHomeStr())
End

/// @brief test if data folder is marked for thread usage
static Function isThreadDF(dfr)
	DFREF dfr

	NVAR/Z marker = dfr:$ASYNC_THREAD_MARKER_STR
	if(NVAR_Exists(marker))
		return marker == ASYNC_THREAD_MARKER
	else
		return 0
	endif
End

/// @brief Returns string path to the thread group id
static Function/S GetThreadGroupID()
	return GetNVARAsString(getAsyncHomeDF(), "threadGroupID", initialValue=NaN)
End

/// @brief Returns string path to the number of threads
static Function/S GetNumThreads()
	return GetNVARAsString(getAsyncHomeDF(), "numThreads", initialValue=0)
End

/// @brief Returns string path to flag if background task was disabled
static Function/S GetTaskDisableStatus()
	return GetNVARAsString(getAsyncHomeDF(), "disableTask", initialValue=0)
End

/// @brief Return wave reference to wave with data folder reference buffer for delayed readouts
/// 1d wave for data folder references, starts with size 0
/// when jobs should be read out in order, the waiting data folders are buffered in this wave
/// e.g. if the next read out would be job 2, but a data folder from job 3 is returned
/// the data folder is buffered until the one from job 2 appears from the output queue
static Function/WAVE GetDFREFbuffer(dfr)
	DFREF dfr

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/DF/SDFR=dfr wv = DFREFbuffer

	if(WaveExists(wv))
		return wv
	endif
	Make/DF/N=0 dfr:DFREFbuffer/Wave=wv

	return wv
End

/// @brief Returns wave ref for workload tracking
/// 2d wave
/// row stores work load classes named through dimension label
/// column 0 stores how many work loads were pushed to Async
/// column 1 stores how many work loads were read out from Async
static Function/WAVE GetWorkloadTracking(dfr)
	DFREF dfr

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/SDFR=dfr/L/U wv = WorkloadTracking

	if(WaveExists(wv))
		return wv
	endif

	Make/L/U/N=(0, 3) dfr:WorkloadTracking/Wave=wv
	SetDimLabel COLS, 0, $"INPUTCOUNT", wv
	SetDimLabel COLS, 1, $"OUTPUTCOUNT", wv
	SetDimLabel COLS, 2, $"INORDER", wv
	return wv
End

/// @brief Returns wave ref for buffering results when THREADING_DISABLED is defined
/// 1D wave using NOTE_INDEX logic
static Function/WAVE GetSerialExecutionBuffer(dfr)
	DFREF dfr

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/SDFR=dfr/DF wv = SerialExecutionBuffer

	if(WaveExists(wv))
		return wv
	endif

	Make/DF/N=(MINIMUM_WAVE_SIZE) dfr:SerialExecutionBuffer/Wave=wv
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	return wv
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

/// @brief Deletes one row, column, layer or chunk from a wave
/// Advantages over DeletePoints:
/// Keeps the dimensionality of the wave when deleting the last row, column, layer or chunk in a wave
/// Implements range check
/// Advantages over DeletePoints + KillWaves:
/// The wave reference stays valid
///
/// @param wv wave where the row, column, layer or chunk should be deleted
///
/// @param dim dimension 0 - rows, 1 - column, 2 - layer, 3 - chunk
///
/// @param index index where one point in the given dimension is deleted
static Function DeleteWavePoint(wv, dim, index)
   WAVE wv
   variable dim, index

   variable size

   ASSERT(WaveExists(wv), "wave does not exist")
   ASSERT(dim >= 0 && dim < 4, "dim must be 0, 1, 2 or 3")
   size = DimSize(wv, dim)
   if(index >= 0 && index < size)
	   if(size > 1)
		   DeletePoints/M=(dim) index, 1, wv
	   else
		   switch(dim)
			   case 0:
				   Redimension/N=(0, -1, -1, -1) wv
				   break
			   case 1:
				   Redimension/N=(-1, 0, -1, -1) wv
				   break
			   case 2:
				   Redimension/N=(-1, -1, 0, -1) wv
				   break
			   case 3:
				   Redimension/N=(-1, -1, -1, 0) wv
				   break
		   endswitch
	   endif
   else
	   ASSERT(0, "index out of range")
   endif
End

/// @brief Check if a name for an object adheres to the strict naming rules
///
/// @see `DisplayHelpTopic "ObjectName"`
threadsafe static Function IsValidObjectName(name)
	string name

	return !cmpstr(name, CleanupName(name, 0, MAX_OBJECT_NAME_LENGTH_IN_BYTES))
End
