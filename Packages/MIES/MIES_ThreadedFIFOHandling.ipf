#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_TFM
#endif

/// @file MIES_ThreadedFIFOHandling.ipf
/// @brief __TFH__ Functions related to threadsafe FIFO monitor and stop daemons

static Constant TIMEOUT_IN_MS = 50

/// @brief Mode constants
///
///@{
static Constant TFH_RESTART_ACQ = 0x1 ///< DAQ restarting for TP MP
static Constant TFH_STOP_ACQ    = 0x2 ///< DAQ stopping
///@}

/// @brief Start the FIFO reset daemon used for TP MD
Function TFH_StartFIFOResetDeamon(hwType, deviceID, triggerMode)
	variable hwType, deviceID, triggerMode

	TFH_StartFIFODeamonInternal(hwType, deviceID, TFH_RESTART_ACQ, triggerMode = triggerMode)
End

/// @brief Start the FIFO stop daemon used for DAQ MD
Function TFH_StartFIFOStopDaemon(hwType, deviceID)
	variable hwType, deviceID

	TFH_StartFIFODeamonInternal(hwType, deviceID, TFH_STOP_ACQ)
End

/// @brief Start the FIFO reset daemon used for TP MD
///
/// We create one thread group for each device.
static Function TFH_StartFIFODeamonInternal(hwType, deviceID, mode, [triggerMode])
	variable hwType, deviceID, mode, triggerMode

	string panelTitle

	if(ParamIsDefault(triggerMode))
		triggerMode = HARDWARE_DAC_DEFAULT_TRIGGER
	endif

	panelTitle = HW_GetMainDeviceName(hwType, deviceID)

	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	NVAR ADChannelToMonitor  = $GetADChannelToMonitor(panelTitle)
	WAVE ITCChanConfigWave   = GetITCChanConfigWave(panelTitle)

	TFH_StopFifoDaemon(hwType, deviceID)
	NVAR tgID  = $GetThreadGroupIDFifo(panelTitle)
	tgID = ThreadGroupCreate(1)

	Duplicate/FREE ITCChanConfigWave, config
	ThreadStart tgID, 0, TFH_FifoLoop(config, triggerMode, deviceID, stopCollectionPoint, ADChannelToMonitor, mode)
End

/// @brief Stop the FIFO daemon if required
///
/// Sets the global `threadGroupIDFifo` to NaN afterwards.
Function TFH_StopFIFODaemon(hwType, deviceID)
	variable hwType, deviceID

	string panelTitle

	panelTitle = HW_GetMainDeviceName(hwType, deviceID)
	NVAR tgID = $GetThreadGroupIDFifo(panelTitle)

	TS_StopThreadGroup(tgID)
	tgID = NaN
End

/// @brief Worker function used for monitoring the FIFO position of the given device.
///
/// Actions depend on `mode`:
/// - #TFH_RESTART_ACQ: Restart acquisition from the start
/// - #TFH_STOP_ACQ:    Stop acqusition and quit running
///
/// Stops in the following cases:
/// - An error during ITC operation calls
/// - The input queue is not empty
///
/// Pushes the following entries into the thread queue:
/// - fifoPos:       fifo position
/// - startSequence: (yoking only) inform the main thread
///                  that ARDStartSequence() commmand should be called
threadsafe static Function TFH_FifoLoop(config, triggerMode, deviceID, stopCollectionPoint, ADChannelToMonitor, mode)
	WAVE config
	variable triggerMode, deviceID, stopCollectionPoint, ADChannelToMonitor, mode

	variable flags, moreData, fifoPos

	variable enableDebug = 0 // = 1 for debugging

	flags = HARDWARE_ABORT_ON_ERROR | HARDWARE_PREVENT_ERROR_POPUP
	HW_ITC_DebugMode_TS(enableDebug, flags = flags)

	do
		DFREF dfr = ThreadGroupGetDFR(MAIN_THREAD, TIMEOUT_IN_MS)

		if(DataFolderExistsDFR(dfr))
			break
		endif

		moreData = HW_ITC_MoreData_TS(deviceID, ADChannelToMonitor, stopCollectionPoint, config, fifoPos = fifoPos)

		if(fifoPos > 0)
			TS_ThreadGroupPutVariable(MAIN_THREAD, "fifoPos", fifoPos)
		endif

		if(!moreData)
			switch(mode)
				case TFH_RESTART_ACQ:

					HW_ITC_StopAcq_TS(deviceID, prepareForDAQ = 1, flags = flags)
					HW_ITC_ResetFifo_TS(deviceID, config, flags = flags)
					HW_ITC_StartAcq_TS(deviceID, triggerMode, flags = flags)

					if(triggerMode != HARDWARE_DAC_DEFAULT_TRIGGER)
						TS_ThreadGroupPutVariable(MAIN_THREAD, "startSequence", 1)
					endif
					break
				case TFH_STOP_ACQ:

					HW_ITC_StopAcq_TS(deviceID, flags = flags)

					return 0
					break
				default:
					ASSERT_TS(0, "Invalid mode")
					break
			endswitch
		endif
	while(1)

	return 0
End
