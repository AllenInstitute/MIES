#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_TFM
#endif // AUTOMATED_TESTING

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
Function TFH_StartFIFOResetDeamon(variable hwType, variable deviceID)

	TFH_StartFIFODeamonInternal(hwType, deviceID, TFH_RESTART_ACQ)
End

/// @brief Start the FIFO stop daemon used for DAQ MD
Function TFH_StartFIFOStopDaemon(variable hwType, variable deviceID)

	TFH_StartFIFODeamonInternal(hwType, deviceID, TFH_STOP_ACQ)
End

/// @brief Start the FIFO reset daemon used for TP MD
///
/// We create one thread group for each device.
static Function TFH_StartFIFODeamonInternal(variable hwType, variable deviceID, variable mode)

	string device

	device = HW_GetMainDeviceName(hwType, deviceID, flags = HARDWARE_ABORT_ON_ERROR)

	NVAR stopCollectionPoint = $GetStopCollectionPoint(device)
	NVAR ADChannelToMonitor  = $GetADChannelToMonitor(device)
	WAVE DAQConfigWave       = GetDAQConfigWave(device)

	TFH_StopFifoDaemon(hwType, deviceID)
	NVAR tgID = $GetThreadGroupIDFifo(device)
	tgID = ThreadGroupCreate(1)

	Duplicate/FREE DAQConfigWave, config

#ifdef THREADING_DISABLED
	BUG("Data acquisition with ITC hardware and no threading is not supported.")
#else
	ThreadStart tgID, 0, TFH_FifoLoop(config, deviceID, stopCollectionPoint, ADChannelToMonitor, mode)
#endif // THREADING_DISABLED

End

/// @brief Stop the FIFO daemon if required
///
/// Sets the global `threadGroupIDFifo` to NaN afterwards.
Function TFH_StopFIFODaemon(variable hwType, variable deviceID)

	string device

	device = HW_GetMainDeviceName(hwType, deviceID, flags = HARDWARE_ABORT_ON_ERROR)
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
/// Pushes the following entries into the thread queue in a free DFR dfrOut if the entries have updated values
/// Otherwise an entry does not get pushed
/// - $ITC_THREAD_FIFOPOS:       fifo position (relative to offset)
/// - $ITC_THREAD_TIMESTAMP:     timestamp of acquisition start
threadsafe static Function TFH_FifoLoop(WAVE config, variable deviceID, variable stopCollectionPoint, variable ADChannelToMonitor, variable mode)

	variable flags, moreData, fifoPos, timestamp

	DFREF dfrOut = NewFreeDataFolder()
	flags = HARDWARE_ABORT_ON_ERROR

	do
		DFREF dfr = ThreadGroupGetDFR(MAIN_THREAD, TIMEOUT_IN_MS)

		if(DataFolderExistsDFR(dfr))
			break
		endif

		moreData = HW_ITC_MoreData_TS(deviceID, ADChannelToMonitor, stopCollectionPoint, config, fifoPos = fifoPos, flags = flags)

		timestamp = NaN
		fifoPos   = limit(fifoPos, 0, stopCollectionPoint)

		if(!moreData)
			switch(mode)
				case TFH_RESTART_ACQ:

					HW_ITC_StopAcq_TS(deviceID, prepareForDAQ = 1, flags = flags)
					HW_ITC_ResetFifo_TS(deviceID, config, flags = flags)
					timestamp = ParseISO8601TimeStamp(HW_GetAcquisitionStartTimestamp())
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

		variable/G dfrOut:$ITC_THREAD_FIFOPOS = fifopos
		if(IsNaN(timestamp))
			KillVariables/Z dfrOut:$ITC_THREAD_TIMESTAMP
		else
			variable/G dfrOut:$ITC_THREAD_TIMESTAMP = timestamp
		endif
		TS_ThreadGroupPutDFR(MAIN_THREAD, dfrOut)
	while(1)

	return 0
End
