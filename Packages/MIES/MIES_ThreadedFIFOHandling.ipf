#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_TFM
#endif

/// @file MIES_ThreadedFIFOHandling.ipf
/// @brief __TFH__ Functions related to threadsafe FIFO monitor and stop daemons

/// FIFO will be resetted once this fraction of the stop collection point is
/// reached
static Constant FIFO_RESETTING_SCP_FRAC = 0.5

static Constant TIMEOUT_IN_MS = 50

/// @brief Start the FIFO reset daemon used for TP MD
///
/// We create one thread group for each device.
Function TFH_StartFIFOResetDeamon(hwType, deviceID)
	variable hwType, deviceID

	string panelTitle
	variable dataLength

	panelTitle = HW_GetMainDeviceName(hwType, deviceID)

	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	NVAR ADChannelToMonitor  = $GetADChannelToMonitor(panelTitle)
	WAVE ITCChanConfigWave   = GetITCChanConfigWave(panelTitle)
	WAVE ITCDataWave         = GetITCDataWave(panelTitle)
	WAVE fifoPos             = GetITCFIFOPositionAllConfigWave(panelTitle)

	WAVE config_t  = HW_ITC_TransposeAndToDouble(ITCChanConfigWave)
	WAVE fifoPos_t = HW_ITC_TransposeAndToDouble(fifoPos)

	dataLength = DimSize(ITCDataWave, ROWS)

	TFH_StopFifoDaemon(hwType, deviceID)
	NVAR tgID  = $GetThreadGroupIDFifo(panelTitle)
	tgID = ThreadGroupCreate(1)
	ThreadStart tgID, 0, TFH_ResetFifoLoop(config_t, deviceID, stopCollectionPoint, ADChannelToMonitor, dataLength)
	WaveClear config_t
End

/// @brief Stop the FIFO daemon if required
///
/// Sets the global `threadGroupIDFifo` to NaN afterwards.
Function TFH_StopFIFODaemon(hwType, deviceID)
	variable hwType, deviceID

	variable numThreadsRunning, returnValue, releaseValue
	string panelTitle, msg

	panelTitle = HW_GetMainDeviceName(hwType, deviceID)
	NVAR tgID = $GetThreadGroupIDFifo(panelTitle)

	if(!IsFinite(tgID))
		// nothing to do
		return NaN
	endif

	TS_ThreadGroupPutVariable(tgID, "abort", 1)

	numThreadsRunning = ThreadGroupWait(tgID, 100)
	sprintf msg, "TFH_StopFifoDaemon: num running threads: %d\r", numThreadsRunning
	DEBUGPRINT_TS(msg)

	if(numThreadsRunning)
		printf "WARNING: The FIFO monitoring thread will be forcefully stopped. This might turn out ugly!\r"
	endif

	returnValue  = ThreadReturnValue(tgID, 0)
	releaseValue = ThreadGroupRelease(tgID)
	sprintf msg, "TFH_StopFifoDaemon: return value %g, thread release %g\r", returnValue, releaseValue
	DEBUGPRINT_TS(msg)

	tgID = NaN
End

/// @brief Worker function used for monitoring and resetting the FIFO position of the given device
///
/// Stops in the following cases:
/// - An error during ITC operation calls
/// - The input queue is not empty
threadsafe static Function TFH_ResetFifoLoop(config_t, deviceID, stopCollectionPoint, ADChannelToMonitor, dataLength)
	WAVE config_t
	variable deviceID, stopCollectionPoint, ADChannelToMonitor, dataLength

	variable fifoPos

	variable enableDebug = 0 // = 1 for debugging
	string msg

	ITCSetGlobals2/Z/D=(enableDebug)

	do
		DFREF dfr = ThreadGroupGetDFR(0, TIMEOUT_IN_MS)

		if(DataFolderExistsDFR(dfr))
			break
		endif

		do
			ITCFIFOAvailableAll2/FREE/DEV=(deviceID)/Z config_t, fifoPos_t
		while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)

		if(V_ITCError != 0 || V_ITCXOPERROR != 0)
			sprintf msg, "TFH_ResetFifoLoop: Communication error with ITC XOP2: itc=%g, xop=%g\r", V_ITCERror, V_ITCXOPERROR
			ASSERT_TS(0, msg)
			break
		endif

		fifoPos = fifoPos_t[%Value][ADChannelToMonitor]

		TS_ThreadGroupPutVariable(MAIN_THREAD, "fifoPos", fifoPos)

		fifoPos = mod(fifoPos, dataLength)

		if(fifoPos > FIFO_RESETTING_SCP_FRAC * stopCollectionPoint)
			fifoPos_t[%Value][] = -1
			do
				ITCUpdateFIFOPositionAll2/DEV=(deviceID) fifoPos_t
			while(V_ITCXOPError == SLOT_LOCKED_TO_OTHER_THREAD && V_ITCError == 0)
		endif
	while(1)

	return 0
End
