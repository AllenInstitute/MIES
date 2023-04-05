#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
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
Function TFH_StartFIFOResetDeamon(hwType, deviceID)
	variable hwType, deviceID

	TFH_StartFIFODeamonInternal(hwType, deviceID, TFH_RESTART_ACQ)
End

/// @brief Start the FIFO stop daemon used for DAQ MD
Function TFH_StartFIFOStopDaemon(hwType, deviceID)
	variable hwType, deviceID

	TFH_StartFIFODeamonInternal(hwType, deviceID, TFH_STOP_ACQ)
End

/// @brief Start the FIFO reset daemon used for TP MD
///
/// We create one thread group for each device.
static Function TFH_StartFIFODeamonInternal(hwType, deviceID, mode)
	variable hwType, deviceID, mode

	string device

	device = HW_GetMainDeviceName(hwType, deviceID)

	NVAR stopCollectionPoint = $GetStopCollectionPoint(device)
	NVAR ADChannelToMonitor  = $GetADChannelToMonitor(device)
	WAVE DAQConfigWave   = GetDAQConfigWave(device)

	TFH_StopFifoDaemon(hwType, deviceID)
	NVAR tgID  = $GetThreadGroupIDFifo(device)
	tgID = ThreadGroupCreate(1)

	Duplicate/FREE DAQConfigWave, config

#ifdef THREADING_DISABLED
	BUG("Data acquisition with ITC hardware and no threading is not supported.")
#else
	ThreadStart tgID, 0, TFH_FifoLoop(config, deviceID, stopCollectionPoint, ADChannelToMonitor, mode)
#endif

End

/// @brief Stop the FIFO daemon if required
///
/// Sets the global `threadGroupIDFifo` to NaN afterwards.
Function TFH_StopFIFODaemon(hwType, deviceID)
	variable hwType, deviceID

	string device

	device = HW_GetMainDeviceName(hwType, deviceID)
	NVAR tgID = $GetThreadGroupIDFifo(device)

	TS_StopThreadGroup(tgID)
	tgID = NaN
End

/// @brief Worker function used for monitoring the FIFO position of the given device.
///
/// Actions depend on `mode`:
/// - #TFH_RESTART_ACQ: Restart acquisition from the start
/// - #TFH_STOP_ACQ:    Stop acquisition and quit running
///
/// Stops in the following cases:
/// - An error during ITC operation calls
/// - The input queue is not empty
///
/// Pushes the following entries into the thread queue:
/// - fifoPos:       fifo position (relative to offset)
threadsafe static Function TFH_FifoLoop(config, deviceID, stopCollectionPoint, ADChannelToMonitor, mode)
	WAVE config
	variable deviceID, stopCollectionPoint, ADChannelToMonitor, mode

	variable flags, moreData, fifoPos

	flags = HARDWARE_ABORT_ON_ERROR

	do
		DFREF dfr = ThreadGroupGetDFR(MAIN_THREAD, TIMEOUT_IN_MS)

		if(DataFolderExistsDFR(dfr))
			break
		endif

		moreData = HW_ITC_MoreData_TS(deviceID, ADChannelToMonitor, stopCollectionPoint, config, fifoPos = fifoPos, flags = flags)
		fifoPos = limit(fifoPos, 0, stopCollectionPoint)

		TS_ThreadGroupPutVariable(MAIN_THREAD, "fifoPos", fifoPos)

		if(!moreData)
			switch(mode)
				case TFH_RESTART_ACQ:

					HW_ITC_StopAcq_TS(deviceID, prepareForDAQ = 1, flags = flags)
					HW_ITC_ResetFifo_TS(deviceID, config, flags = flags)
					HW_ITC_StartAcq_TS(deviceID, HARDWARE_DAC_DEFAULT_TRIGGER, flags = flags)
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
