#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_ASYNC
#endif

/// @file MIES_ASYNC.ipf
/// @brief __ASYNC__ This file holds the asynchronous execution framework
///
/// \rst
/// See :ref:`async_framework_doc` for the full documentation.
/// \endrst

static StrConstant ASYNC_BACKGROUND = "AsyncFramework"
static Constant MAX_OBJECT_NAME_LENGTH_IN_BYTES = 31
static Constant ASYNC_THREAD_MARKER = 299792458
static Constant ASYNC_MAX_THREADS = 64

/// @name Variable names for free data folder structure
/// @{
static StrConstant ASYNC_THREAD_MARKER_STR = "threadDFMarker"
static StrConstant ASYNC_WORKERFUNC_STR = "WorkerFunc"
static StrConstant ASYNC_READOUTFUNC_STR = "ReadOutFunc"
static StrConstant ASYNC_WORKLOADID_STR = "workloadID"
static StrConstant ASYNC_PARAMCOUNT_STR = "paramCount"
static StrConstant ASYNC_INORDER_STR = "inOrder"
static StrConstant ASYNC_ORDERID_STR = "orderID"
static StrConstant ASYNC_ABORTFLAG_STR = "abortFlag"
static StrConstant ASYNC_ERROR_STR = "err"
static StrConstant ASYNC_ERRORMSG_STR = "errmsg"
/// @}

/// @brief Starts the Async Framework with numThreads parallel threads.
///
/// @param numThreads number of threads to setup for processing data, must be >= 1 and <= ASYNC_MAX_THREADS
///
/// @param disableTask [optional, default = 0] when set to 1 the background task processing readouts is not started
Function ASYNC_Start(numThreads, [disableTask])
	variable numThreads, disableTask

	variable i

	ASSERT(numThreads >= 1 && numThreads <= ASYNC_MAX_THREADS, "numThread must be > 0 and <= " + num2str(ASYNC_MAX_THREADS))
	disableTask = ParamIsDefault(disableTask) ? 0 : !!disableTask

	DFREF dfr = GetAsyncHomeDF()
	NVAR tgID = $GetThreadGroupID()
	ASSERT(isNaN(tgID), "Async frame work already running")

	NVAR numT = $GetNumThreads()
	numT = numThreads

	tgID = ThreadGroupCreate(numThreads)

	NVAR noTask = $GetTaskDisableStatus()
	noTask = disableTask
	if(!disableTask)
		CtrlNamedBackground $ASYNC_BACKGROUND, period=1, proc=ASYNC_BackgroundReadOut, start
	endif

	for(i = 0; i < numThreads; i += 1)
		ThreadStart tgID, i, ASYNC_Thread()
	endfor
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

	DFREF dfrOut, dfrTemp
	string datafolder

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
			dfrOut = f(dfrInp);AbortOnRTE
		catch
			err = GetRTError(1)
#if (IgorVersion() >= 7.00 && IgorVersion() < 8.00)
			if(!err)
				return 0
			endif
#endif
			errmsg = GetErrMessage(err)
		endtry

		if(DataFolderRefStatus(dfrOut) == 3)

			MoveDataFolder dfrOut, dfrAsync

		elseif(DataFolderExistsDFR(dfrOut))

#if NumberByKey("BUILD", igorinfo(0)) >= 32616
			MoveDataFolder dfrOut, dfrAsync
			RenameDataFolder dfrOut, freeroot
#else
			// MoveDataFolder does not work reliable with
			// regular to free, WM bug report sent on 10/12/2018
			// fixed in build 32616
			SetDataFolder root:
			dataFolder = UniqueDataFolderName($":", "temp")
			NewDataFolder $dataFolder
			DFREF dfrTemp = $dataFolder
			MoveDataFolder dfrOut, dfrTemp
			RenameDataFolder dfrOut, freeroot

			WAVE w = dfrAsync:workerID
			Duplicate w, dfrTemp:workerID
			SVAR s = dfrAsync:$ASYNC_READOUTFUNC_STR
			string/G dfrTemp:$ASYNC_READOUTFUNC_STR = s
			SVAR s = dfrAsync:$ASYNC_WORKLOADID_STR
			string/G dfrTemp:$ASYNC_WORKLOADID_STR = s
			NVAR v = dfrAsync:$ASYNC_INORDER_STR
			variable/G dfrTemp:$ASYNC_INORDER_STR = v
			if(v)
				NVAR v = dfrAsync:$ASYNC_ORDERID_STR
				variable/G dfrTemp:$ASYNC_ORDERID_STR = v
			endif

			SVAR s = dfrAsync:$ASYNC_ERRORMSG_STR
			string/G dfrTemp:$ASYNC_ERRORMSG_STR = s
			NVAR v = dfrAsync:$ASYNC_ERROR_STR
			variable/G dfrTemp:$ASYNC_ERROR_STR = v

			dfrAsync = dfrTemp
#endif
		else

			NewDataFolder dfrAsync:freeroot

		endif

		ASYNC_putDF(dfrAsync, 0)
		KillDataFolder dfr
	endfor
End

/// @brief Receives data from finished workloads. Calls the user defined readout function.
/// For in order readouts this function buffers pending result data folders until they can be processed in order.
Function ASYNC_ThreadReadOut()
	variable bufferSize, i
	variable justBuffered

	variable orderIndex, rterr
	string rterrmsg
	NVAR tgID = $GetThreadGroupID()
	ASSERT(!isNaN(tgID), "Async frame work is not running")
	WAVE/DF DFREFbuffer = GetDFREFBuffer(getAsyncHomeDF())
	WAVE/T workloadID = GetWorkloadID(getAsyncHomeDF())
	WAVE workloadOrder = GetWorkloadOrder(getAsyncHomeDF())

	for(;;)
		DFREF dfr = ThreadGroupGetDFR(tgID, 0)
		if(!DataFolderExistsDFR(dfr))

			if(justBuffered)
				return 0
			endif

			// Can we process one of the buffered results?
			bufferSize = numpnts(DFREFbuffer)
			for(i = 0; i < bufferSize; i += 1)
				DFREF dfr = DFREFbuffer[i]
				DFREF dfrOut = dfr:freeroot
				NVAR orderID = dfr:$ASYNC_ORDERID_STR
				SVAR wID = dfr:$ASYNC_WORKLOADID_STR

				FindValue/TXOP=4/TEXT=wID workloadID
				orderIndex = V_Value
				ASSERT(orderIndex != -1, "workloadID not found")
				if(orderID == workloadOrder[orderIndex][%orderGlobal])
					DeletePoints i, 1, DFREFbuffer
					break
				endif

			endfor

			if(i == bufferSize)
				return 0
			endif
		else
			// check for inOrder, do we need to buffer?
			DFREF dfrOut = dfr:freeroot
			NVAR inOrder = dfr:$ASYNC_INORDER_STR
			if(inOrder)
				NVAR orderID = dfr:$ASYNC_ORDERID_STR
				SVAR wID = dfr:$ASYNC_WORKLOADID_STR

				FindValue/TXOP=4/TEXT=wID workloadID
				orderIndex = V_Value
				ASSERT(orderIndex != -1, "workloadID not found")
				if(orderID != workloadOrder[orderIndex][%orderGlobal])
					bufferSize = numpnts(DFREFbuffer)
					Redimension/N=(bufferSize + 1) DFREFbuffer
					DFREFbuffer[bufferSize] = dfr
					justBuffered = 1
					continue
				endif

				justBuffered = 0

			endif
		endif

		workloadOrder[orderIndex][%orderGlobal] += 1
		SVAR RFunc = dfr:$ASYNC_READOUTFUNC_STR
		FUNCREF ASYNC_ReadOut f = $RFunc
		NVAR err = dfr:$ASYNC_ERROR_STR
		SVAR errmsg = dfr:$ASYNC_ERRORMSG_STR
		NVAR rc = $GetReadOutCounter()
		rc += 1

		try
			f(dfrOut, err, errmsg);AbortOnRTE
		catch
			rterrmsg = GetRTErrMessage()
			rterr = GetRTError(1)
			ASSERT(0, "ReadOut function " + RFunc + " aborted with: " + rterrmsg)
		endtry

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
Function ASYNC_AddParam(dfr, [w, var, str, move])
	DFREF dfr
	WAVE w
	variable var
	string str
	variable move

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

	paramName = "param" + num2str(paramCount)

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

/// @brief Stops the Async Framework
///
/// @param timeout [optional, default = Inf] time in s to wait for running threads, the function waits for pending threads and pending readouts within this time.
/// After a timeout happened the readout processing is stopped and threads are stopped. Any pending data is lost.
/// If the threads have to be stopped forcefully, an assertion is raised.
/// Using a finite timeout is strongly recommended.
///
/// @return 1 if a timeout was encountered, 0 otherwise
Function ASYNC_Stop([timeout])
	variable timeout

	variable i, endtime, waitResult, localtgID, outatime

	NVAR tgID = $GetThreadGroupID()
	ASSERT(!isNaN(tgID), "Async FrameWork already in stopped state")

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
		ASYNC_Execute(dfr)
	endfor

	// Wait for all threads to finish (or timeout)
	if(ParamIsDefault(timeout))
		timeout = Inf
	endif
	endTime = dateTime + timeout
	do
		waitResult = ThreadGroupWait(tgID, 0)

		if(dateTime >= endtime)
			outatime = 1
			break
		endif

	while(waitResult != 0)

	NVAR noTask = $GetTaskDisableStatus()
	if(!noTask)
		CtrlNamedBackground $ASYNC_BACKGROUND, stop
	endif

	if(!outatime)

		NVAR ReadOutCounter = $GetReadOutCounter()
		WAVE workerIDCounter = GetWorkerIDCounter(getAsyncHomeDF())
		do
			if(ReadOutCounter < workerIDCOunter[0] - numThreads)
				ASYNC_ThreadReadOut()
			else
				break
			endif

			if(datetime >= endtime)
				outatime = 1
			endif

		while(!outatime)

	endif

	localtgID = tgID
	KillDataFolder GetAsyncHomeDF()
	ASSERT(!(ThreadGroupRelease(localtgID) == -2), "Async framework stopped forcefully")

	return outatime
End

/// @brief Prepares a thread data folder for use with the AsyncFramework
/// This function should be called first when setting up a worker with parameters
///
/// @param WorkerFunc string naming a threadsafe worker function in the form of the ASYNC_Worker template
///
/// @param ReadOutFunc string naming a readout function in the form of the ASYNC_ReadOut template
///
/// @param inOrder [optional, default = 1] flag that allows to disable in order readout of results
///
/// @return data folder for thread, where parameters can be put to with :cpp:func:`ASYNC_AddParam`
Function/DF ASYNC_PrepareDF(WorkerFunc, ReadOutFunc, [inOrder])
	string WorkerFunc
	string ReadOutFunc
	variable inOrder

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
	string/G dfrAsync:$ASYNC_WORKLOADID_STR = ":" + WorkerFunc + ":" + ReadOutFunc + ":"
	variable/G dfrAsync:$ASYNC_INORDER_STR = inOrder

	variable/G dfrInp:$ASYNC_PARAMCOUNT_STR = 0

	variable/G dfr:$ASYNC_THREAD_MARKER_STR
	NVAR marker = dfr:$ASYNC_THREAD_MARKER_STR
	marker = ASYNC_THREAD_MARKER

	return dfr
End

/// @brief Puts a prepared thread data folder to parallel execution in another thread
///
/// @param dfr data folder that is setup for thread and is to be deployed
Function ASYNC_Execute(dfr)
	DFREF dfr

	variable orderIndex

	ASSERT(isThreadDF(dfr), "Invalid data folder or not a thread data folder")
	NVAR tgID = $GetThreadGroupID()
	ASSERT(!isNaN(tgID), "Async frame work is not running")

	KillVariables dfr:$ASYNC_THREAD_MARKER_STR

	DFREF dfrAsync = dfr:async

	NVAR inOrder = dfrAsync:$ASYNC_INORDER_STR
	if(inOrder)
		WAVE/T workloadID = GetWorkloadID(getAsyncHomeDF())
		WAVE workloadOrder = GetWorkloadOrder(getAsyncHomeDF())
		SVAR wID = dfrAsync:$ASYNC_WORKLOADID_STR

		FindValue/TXOP=4/TEXT=wID workloadID
		orderIndex = V_Value
		if(orderIndex == -1)
			orderIndex = numpnts(workloadID)
			Redimension/N=(orderIndex + 1) workLoadID
			Redimension/N=(orderIndex + 1, -1) workloadOrder
			workLoadID[orderIndex] = wID
		endif

		variable/G dfrAsync:$ASYNC_ORDERID_STR = workloadOrder[orderIndex][%orderID]
		workloadOrder[orderIndex][%orderID] += 1

	endif

	WAVE workerIDCounter = GetWorkerIDCounter(getAsyncHomeDF())
	Duplicate workerIDCounter, dfrAsync:workerID

	workerIDCounter[0] += 1

	ASYNC_putDF(dfr, tgID)
End

/// @brief Puts a data folder to/from a threadgroup
threadsafe static Function ASYNC_putDF(dfr, tgID)
	DFREF dfr
	variable tgID

	string dataFolder
	DFREF dfrSave

	dataFolder = UniqueDataFolderName($":", "temp")
	DuplicateDataFolder dfr, $dataFolder
	dfrSave = GetDataFolderDFR()

	SetDataFolder $dataFolder
	ThreadGroupPutDF tgID, :

	SetDatafolder dfrSave
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

#if (IgorVersion() >= 8.00)

/// @brief Return a unique data folder name which does not exist in dfr
///
/// If you want to have the datafolder created for you and don't need a
/// threadsafe function, use UniqueDataFolder() instead.
///
/// @param dfr      datafolder to search
/// @param baseName first part of the datafolder, must be a *valid* Igor Pro object name
threadsafe static Function/S UniqueDataFolderName(dfr, baseName)
	DFREF dfr
	string baseName

	variable index, numRuns
	string basePath, path

	ASSERT_TS(!isEmpty(baseName), "baseName must not be empty" )
	ASSERT_TS(DataFolderExistsDFR(dfr), "dfr does not exist")

	numRuns = 10000
	// shorten basename so that we can attach some numbers
	baseName = baseName[0, MAX_OBJECT_NAME_LENGTH_IN_BYTES - (ceil(log(numRuns)) + 1)]
	baseName = CleanupName(baseName, 0)
	basePath = GetDataFolder(1, dfr)
	path = basePath + baseName

	do
		if(!DataFolderExists(path))
			return path
		endif

		path = basePath + baseName + "_" + num2istr(index)

		index += 1
	while(index < numRuns)

	DEBUGPRINT_TS("Could not find a unique folder with trials:", var = numRuns)

	return ""
End

#else

/// @brief Return a unique data folder name which does not exist in dfr
///
/// If you want to have the datafolder created for you and don't need a
/// threadsafe function, use UniqueDataFolder() instead.
///
/// @param dfr      datafolder to search
/// @param baseName first part of the datafolder, must be a *valid* Igor Pro object name
///
/// @todo use CleanupName for baseName once that is threadsafe
threadsafe static Function/S UniqueDataFolderName(dfr, baseName)
	DFREF dfr
	string baseName

	variable index
	string basePath, path

	ASSERT_TS(!isEmpty(baseName), "baseName must not be empty" )
	ASSERT_TS(DataFolderExistsDFR(dfr), "dfr does not exist")

	basePath = GetDataFolder(1, dfr)
	path = basePath + baseName

	do
		if(!DataFolderExists(path))
			return path
		endif

		path = basePath + baseName + "_" + num2istr(index)

		index += 1
	while(index < 10000)

	DEBUGPRINT_TS("Could not find a unique folder with 10000 trials")

	return ""
End

#endif

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

/// @brief Returns string path to thread DF marker
static Function/S GetReadOutCounter()
	return GetNVARAsString(getAsyncHomeDF(), "ReadOutCounter", initialValue=0)
End

/// @brief Returns workerIDCounter wave reference
/// 1d wave with exactly one element of type UINT64
/// It counts the jobs executed and is unique per job
static Function/WAVE GetWorkerIDCounter(dfr)
	DFREF dfr

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/L/U/SDFR=dfr wv = workerIDCounter

	if(WaveExists(wv))
		return wv
	endif
	Make/N=1/L/U dfr:workerIDCounter/Wave=wv

	return wv
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

/// @brief Returns workloadID wave reference
/// 1d wave that stored the id strings for job types that are executed in order
/// the id strings are a combination of the worker and readout function name
/// The size of this wave is increased in ASYNC_Execute for each new job type
/// that should be executed in order
static Function/WAVE GetWorkloadID(dfr)
	DFREF dfr

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/T/SDFR=dfr wv = workloadID

	if(WaveExists(wv))
		return wv
	endif
	Make/T/N=0 dfr:workloadID/Wave=wv

	return wv
End

/// @brief Returns workloadOrder wave reference
/// 2d wave,
/// row counts job types
/// column 0 stores the orderID which is unique and increased by 1 per in order executed job of a job type
/// column 1 stores the order counter for readout per in order read out job per job type
/// both counters are used to track the order of jobs, as orderID is set when executing a job it is
/// running in advance of orderGlobal for a job type
static Function/WAVE GetWorkloadOrder(dfr)
	DFREF dfr

	ASSERT(DataFolderExistsDFR(dfr), "Invalid dfr")
	WAVE/Z/SDFR=dfr wv = WorkloadOrder

	if(WaveExists(wv))
		return wv
	endif

	Make/N=(0, 2) dfr:WorkloadOrder/Wave=wv
	SetDimLabel 1, 0, $"orderID", wv
	SetDimLabel 1, 1, $"orderGlobal", wv
	return wv
End
