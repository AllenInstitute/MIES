#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DAQ_MD
#endif

/// @file MIES_DataAcquisition_Multi.ipf
/// @brief __DQM__ Routines for Multi Device Data acquisition

/// @brief Fifo monitor for DAQ Multi Device
///
/// @ingroup BackgroundFunctions
Function DQM_FIFOMonitor(s)
	STRUCT BackgroundStruct &s

	variable deviceID, isFinished, hardwareType
	variable i, j, err, fifoLatest, result, channel, lastTP, gotTPChannels, newSamplesCount
	variable bufferSize
	string device, fifoChannelName, fifoName, errMsg
	WAVE ActiveDeviceList = GetDQMActiveDeviceList()

	if(s.wmbs.started)
		s.wmbs.started    = 0
		s.threadDeadCount = 0
		s.ticksLastReceivedFifoPos = ticks
		s.lastReceivedFifoPos = HARDWARE_ITC_FIFO_ERROR
	endif

	for(i = 0; i < DimSize(ActiveDeviceList, ROWS); i += 1) // NOLINT
		deviceID   = ActiveDeviceList[i][%DeviceID]
		hardwareType = ActiveDeviceList[i][%HardwareType]
		device = HW_GetMainDeviceName(hardwareType, deviceID, flags = HARDWARE_ABORT_ON_ERROR)

		WAVE TPSettingsCalc = GetTPSettingsCalculated(device)

		switch(hardwareType)
			case HARDWARE_NI_DAC:

				AssertOnAndClearRTError()
				try
					NVAR fifoPosGlobal = $GetFifoPosition(device)
					fifoName = GetNIFIFOName(deviceID)
					FIFOStatus/Q $fifoName
					ASSERT(V_Flag != 0,"FIFO does not exist!")
					newSamplesCount = V_FIFOChunks - fifoPosGlobal
					if(newSamplesCount < 2)
						// workaround for Igor Pro bug 5092
						continue // no new data -> next device
					endif

					Make/FREE/N=(0) wNIReadOut
					WAVE/WAVE NIDataWave = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
					for(j = 0; j < V_FIFOnchans; j += 1)

						fifoChannelName = StringByKey("NAME" + num2str(j), S_Info)
						channel = str2num(fifoChannelName)
						WAVE NIChannel = NIDataWave[channel]
						FIFO2WAVE/R=[fifoPosGlobal, fifoPosGlobal + newSamplesCount - 1] $fifoName, $fifoChannelName, wNIReadOut; AbortOnRTE

						bufferSize = DimSize(NIChannel, ROWS)
						fifoLatest = min(V_FIFOChunks, bufferSize)
						isFinished = (fifoLatest == bufferSize) ? 1 : isFinished
						multithread NIChannel[fifoPosGlobal, fifoLatest - 1] = wNIReadOut[p - fifoPosGlobal]
						SetScale/P x, 0, DimDelta(wNIReadOut, ROWS) * ONE_TO_MILLI, "ms", NIChannel

					endfor
				catch
					errMsg = GetRTErrMessage()
					err = ClearRTError()
					LOG_AddEntry(PACKAGE_MIES, "hardware error", stacktrace = 1)
					DQ_StopOngoingDAQ(device, DQ_STOP_REASON_HW_ERROR, startTPAfterDAQ = 0)
					if(err == 18)
						ASSERT(0, "Acquisition FIFO overflow, data lost. This may happen if the computer is too slow.")
					else
						ASSERT(0, "Error reading data from NI device: code " + num2str(err) + "\r" + errMsg)
					endif
				endtry
				break
			case HARDWARE_ITC_DAC:
				NVAR tgID = $GetThreadGroupIDFIFO(device)
				fifoLatest = TS_GetNewestFromThreadQueue(tgID, "fifoPos", timeout_default = HARDWARE_ITC_FIFO_ERROR, timeout_tries = THREAD_QUEUE_TRIES)

				if(fifoLatest != s.lastReceivedFifoPos)
					s.ticksLastReceivedFifoPos = ticks
					s.lastReceivedFifoPos = fifoLatest
				endif

				if(fifoLatest == HARDWARE_ITC_FIFO_ERROR)
					DQ_StopOngoingDAQ(device, DQ_STOP_REASON_FIFO_TIMEOUT, startTPAfterDAQ = 0)

					if(s.threadDeadCount < DAQ_MD_THREAD_DEAD_MAX_RETRIES)
						s.threadDeadCount += 1
						printf "Trying to restart data acquisition to cope with FIFO timeout issues, keep fingers crossed (%d/%d)\r", s.threadDeadCount, DAQ_MD_THREAD_DEAD_MAX_RETRIES
						ControlWindowToFront()

						LOG_AddEntry(PACKAGE_MIES, "begin restart DAQ", stacktrace = 1, keys = {"device", "reason"}, values = {device, "FIFO timeout"})
						DQ_RestartDAQ(device, DAQ_BG_MULTI_DEVICE)
						LOG_AddEntry(PACKAGE_MIES, "end restart DAQ", stacktrace = 1, keys = {"device", "reason"}, values = {device, "FIFO timeout"})
					endif

					continue
				elseif((ticks - s.ticksLastReceivedFifoPos) > HARDWARE_ITC_STUCK_FIFO_TICKS)
					DQ_StopOngoingDAQ(device, DQ_STOP_REASON_STUCK_FIFO, startTPAfterDAQ = 0)

					if(s.threadDeadCount < DAQ_MD_THREAD_DEAD_MAX_RETRIES)
						s.threadDeadCount += 1
						printf "Trying to restart data acquisition to cope with stuck FIFO, keep fingers crossed (%d/%d)\r", s.threadDeadCount, DAQ_MD_THREAD_DEAD_MAX_RETRIES
						ControlWindowToFront()

						LOG_AddEntry(PACKAGE_MIES, "begin restart DAQ", stacktrace = 1, keys = {"device", "reason"}, values = {device, "stuck FIFO"})
						DQ_RestartDAQ(device, DAQ_BG_MULTI_DEVICE)
						LOG_AddEntry(PACKAGE_MIES, "end restart DAQ", stacktrace = 1, keys = {"device", "reason"}, values = {device, "stuck FIFO"})
					endif

					continue
				endif

				// once TFH_FifoLoop is finished the thread is done as well and
				// therefore we get NaN from TS_GetNewestFromThreadQueue
				isFinished = IsNaN(fifoLatest)

				// Update ActiveChunk Entry for ITC, not used in DAQ mode
				gotTPChannels = GotTPChannelsOnADCs(device)
				if(gotTPChannels)
					lastTP = trunc(fifoLatest / TPSettingsCalc[%totalLengthPointsDAQ]) - 1
					if(lastTP >= 0 && lastTP != ActiveDeviceList[i][%ActiveChunk])
						ActiveDeviceList[i][%ActiveChunk] = lastTP
					endif
				endif

				break
		endswitch

		SCOPE_UpdateOscilloscopeData(device, DATA_ACQUISITION_MODE, deviceID=deviceID, fifoPos=fifoLatest)

		result = AS_HandlePossibleTransition(device, AS_MID_SWEEP)

		if(result == ANALYSIS_FUNC_RET_REPURP_TIME)
			UpdateLeftOverSweepTime(device, fifoLatest)
			isFinished = 1
		elseif(result == ANALYSIS_FUNC_RET_EARLY_STOP)
			isFinished = 1
		endif

		SCOPE_UpdateGraph(device, DATA_ACQUISITION_MODE)

		if(isFinished)
			DQM_RemoveDevice(device, deviceID)
			DQM_StopDataAcq(device, deviceID)
			i = 0
			continue
		endif

		if(GetKeyState(0) & ESCAPE_KEY)
			DQ_StopOngoingDAQ(device, DQ_STOP_REASON_ESCAPE_KEY, startTPAfterDAQ = 0)
			return 1
		endif
	endfor

	if(DimSize(ActiveDeviceList, ROWS) == 0)
		return 1
	endif

	return 0
End

/// @brief Stop ongoing multi device DAQ
Function DQM_TerminateOngoingDAQHelper(device)
	String device

	variable returnedHardwareType

	NVAR deviceID = $GetDAQDeviceID(device)
	WAVE ActiveDeviceList = GetDQMActiveDeviceList()

	variable hardwareType = GetHardwareType(device)
	if(hardwareType == HARDWARE_ITC_DAC)
		TFH_StopFIFODaemon(HARDWARE_ITC_DAC, deviceID)
	endif

	try
		HW_StopAcq(hardwareType, deviceID, zeroDAC = 1, flags=HARDWARE_ABORT_ON_ERROR)
	catch
		if(hardwareType == HARDWARE_ITC_DAC)
			print "Stopping data acquisition was not successfull, trying to close and reopen the device"
			LOG_AddEntry(PACKAGE_MIES, "begin closing/opening device", stacktrace = 1, keys = {"device", "reason"}, values = {device, "stopping DAQ failed"})
			HW_CloseDevice(HARDWARE_ITC_DAC, deviceID)
			HW_OpenDevice(device, returnedHardwareType)
			ASSERT(returnedHardwareType == HARDWARE_ITC_DAC, "Error opening the device again")
			LOG_AddEntry(PACKAGE_MIES, "end closing/opening device", stacktrace = 1, keys = {"device", "reason"}, values = {device, "stopping DAQ failed"})
		endif
	endtry

	// remove device passed in from active device lists
	DQM_RemoveDevice(device, deviceID)

	// determine if device removed was the last device on the list, if yes stop the background function
	if(DimSize(ActiveDeviceList, ROWS) == 0)
		CtrlNamedBackground $TASKNAME_FIFOMONMD, stop
	endif
END

/// @brief Handles function calls for data acquistion
///
/// Handles the calls to the data configurator (DC) functions and BackgroundMD
/// it is required because of the special handling syncronous ITC1600s require
///
/// @param device      device
/// @param initialSetupReq [optional, defaults to true] performs initialization routines
///                        at the very beginning of DAQ, turn off for RA
Function DQM_StartDAQMultiDevice(device, [initialSetupReq])
	string device
	variable initialSetupReq

	ASSERT(WhichListItem(GetRTStackInfo(2), DAQ_ALLOWED_FUNCTIONS) != -1, \
		"Calling this function directly is not supported, please use PGC_SetAndActivateControl.")

	if(ParamIsDefault(initialSetupReq))
		initialSetupReq = 1
	else
		initialSetupReq = !!initialSetupReq
	endif

	try
		if(initialSetupReq)
			DAP_OneTimeCallBeforeDAQ(device, DAQ_BG_MULTI_DEVICE)
		endif

		DC_Configure(device, DATA_ACQUISITION_MODE)
		NVAR maxITI = $GetMaxIntertrialInterval(device)
	catch
		if(initialSetupReq)
			DAP_OneTimeCallAfterDAQ(device, DQ_STOP_REASON_CONFIG_FAILED, forcedStop = 1)
		else // required for RA
			DQ_StopDAQDeviceTimer(device)
		endif

		return NaN
	endtry

	// configure passed device
	NVAR deviceID = $GetDAQDeviceID(device)
	HW_PrepareAcq(GetHardwareType(device), deviceID, DATA_ACQUISITION_MODE, flags=HARDWARE_ABORT_ON_ERROR)

	DAP_UpdateITIAcrossSets(device, maxITI)
	DQM_BkrdDataAcq(device)
End

/// @brief Start the background timer for the inter trial interval (ITI)
///
/// Multi device variant
///
/// @param device device
/// @param runTime    left over time to wait in seconds
/// @param funcList   list of functions to execute at the end of the ITI
Function DQM_StartBackgroundTimer(device, runTime, funcList)
	string device, funcList
	variable runTime

	ASSERT(!isEmpty(funcList), "Empty funcList does not makse sense")

	variable startTime    = RelativeNowHighPrec()
	variable durationTime = runTime
	variable endTime      = startTime + durationTime

	DQM_MakeOrUpdateTimerParamWave(device, funcList, startTime, durationTime, endTime, 1)
	if(!IsBackgroundTaskRunning(TASKNAME_TIMERMD))
		CtrlNamedBackground $TASKNAME_TIMERMD, start
	endif
End

/// @brief Stop the background timer used for ITI tracking
Function DQM_StopBackgroundTimer(device)
	string device

	WAVE/SDFR=GetActiveDAQDevicesTimerFolder() ActiveDevTimeParam

	DQM_MakeOrUpdateTimerParamWave(device, "", 0, 0, 0, -1)
	variable DevicesWithActiveTimers = DimSize(ActiveDevTimeParam, 0)
	if(DevicesWithActiveTimers == 0) // stops background timer if no more devices are in the parameter waves
		CtrlNamedBackground $TASKNAME_TIMERMD, Stop
	endif
End

/// @brief Background function for tracking ITI
///
/// @ingroup BackgroundFunctions
Function DQM_Timer(s)
	STRUCT WMBackgroundStruct &s

	WAVE/SDFR=GetActiveDAQDevicesTimerFolder() ActiveDevTimeParam
	// column 0 = deviceID; column 1 = Start time; column 2 = run time; column 3 = end time
	WAVE/T/SDFR=GetActiveDAQDevicesTimerFolder() TimerFunctionListWave
	// column 0 = panel title; column 1 = list of functions
	variable i
	string device
	variable TimeLeft

	for(i = 0; i < DimSize(ActiveDevTimeParam, ROWS); i += 1) // NOLINT
		ActiveDevTimeParam[i][4] = (RelativeNowHighPrec() - ActiveDevTimeParam[i][1])
		timeLeft = max(ActiveDevTimeParam[i][2] - ActiveDevTimeParam[i][4], 0)
		device = TimerFunctionListWave[i][0]

		SetValDisplay(device, "valdisp_DataAcq_ITICountdown", var = timeLeft)

		if(timeLeft == 0)
			ExecuteListOfFunctions(TimerFunctionListWave[i][1])
			DQM_MakeOrUpdateTimerParamWave(device, "", 0, 0, 0, -1)

			// restart iterating over the remaining devices
			i = 0
			continue
		endif
	endfor

	if(DimSize(ActiveDevTimeParam, ROWS) == 0)
		return 1
	endif

	return 0
End

static Function DQM_StartBckrdFIFOMonitor()
	CtrlNamedBackground $TASKNAME_FIFOMONMD, start
End

static Function DQM_StopDataAcq(device, deviceID)
	String device
	Variable deviceID

	variable hardwareType = GetHardwareType(device)
	if(hardwareType == HARDWARE_ITC_DAC)
		TFH_StopFIFODaemon(hardwareType, deviceID)
	endif
	HW_StopAcq(hardwareType, deviceID, prepareForDAQ = 1, zeroDAC = 1, flags=HARDWARE_ABORT_ON_ERROR)

	SWS_SaveAcquiredData(device)
	RA_ContinueOrStop(device, multiDevice=1)
End

static Function DQM_BkrdDataAcq(device, [triggerMode])
	string device
	variable triggerMode

	if(ParamIsDefault(triggerMode))
		triggerMode = HARDWARE_DAC_DEFAULT_TRIGGER
	endif

	NVAR deviceID   = $GetDAQDeviceID(device)

	if(triggerMode == HARDWARE_DAC_DEFAULT_TRIGGER && DAG_GetNumericalValue(device, "Check_DataAcq1_RepeatAcq"))
		DQ_StartDAQDeviceTimer(device)
	endif

	variable hardwareType = GetHardwareType(device)
	HW_StartAcq(hardwareType, deviceID, triggerMode=triggerMode, flags=HARDWARE_ABORT_ON_ERROR)
	AS_HandlePossibleTransition(device, AS_MID_SWEEP)

	if(hardwareType == HARDWARE_ITC_DAC)
		TFH_StartFIFOStopDaemon(hardwareType, deviceID)
	endif

	DQM_AddDevice(device)

	if(!IsBackgroundTaskRunning(TASKNAME_FIFOMONMD))
		DQM_StartBckrdFIFOMonitor()
	endif
End

/// @brief Removes a device from the ActiveDeviceList
///
/// @param device panel title
/// @param deviceID   id of the device to be removed
static Function DQM_RemoveDevice(device, deviceID)
	string device
	variable deviceID

	variable row

	WAVE ActiveDeviceList = GetDQMActiveDeviceList()

	row = DQM_GetActiveDeviceRow(deviceID)
	DeleteWavePoint(ActiveDeviceList, ROWS, row)
End

/// @brief Return the row into `ActiveDeviceList` for the given deviceID
Function DQM_GetActiveDeviceRow(variable deviceID)

	variable idCol
	WAVE ActiveDeviceList = GetDQMActiveDeviceList()

	idCol = FindDimLabel(ActiveDeviceList, COLS, "DeviceID")
	FindValue/V=(deviceID)/RMD=[][idCol] ActiveDeviceList

	if(V_Value == -1)
		return NaN
	endif

	return V_Value
End

/// @brief Adds a device to the ActiveDeviceList
///
/// @param device panel title
static Function DQM_AddDevice(device)
	string device

	variable numberOfRows

	NVAR ADChannelToMonitor  = $GetADChannelToMonitor(device)
	NVAR deviceID   = $GetDAQDeviceID(device)
	WAVE ActiveDeviceList    = GetDQMActiveDeviceList()

	numberOfRows = DimSize(ActiveDeviceList, ROWS)
	Redimension/N=(numberOfRows + 1, 4) ActiveDeviceList

	ActiveDeviceList[numberOfRows][%DeviceID] = deviceID
	ActiveDeviceList[numberOfRows][%ADChannelToMonitor] = ADChannelToMonitor
	ActiveDeviceList[numberOfRows][%HardwareType] = GetHardwareType(device)
	ActiveDeviceList[numberOfRows][%ActiveChunk] = NaN
End

static Function DQM_MakeOrUpdateTimerParamWave(device, listOfFunctions, startTime, RunTime, EndTime, addOrRemoveDevice)
	string device, ListOfFunctions
	variable startTime, RunTime, EndTime, addOrRemoveDevice

	variable rowToRemove = NaN
	variable numberOfRows

	NVAR deviceID = $GetDAQDeviceID(device)
	DFREF dfr = GetActiveDAQDevicesTimerFolder()

	WAVE/Z/SDFR=dfr ActiveDevTimeParam
	if(addOrRemoveDevice == 1) // add a DAQ device
		if(!WaveExists(ActiveDevTimeParam))
			Make/N=(1, 5) dfr:ActiveDevTimeParam/Wave=ActiveDevTimeParam
			ActiveDevTimeParam[0][0] = deviceID
			ActiveDevTimeParam[0][1] = startTime
			ActiveDevTimeParam[0][2] = RunTime
			ActiveDevTimeParam[0][3] = EndTime
			//ActiveDevTimeParam[0][4] = Elapsed time - calculated by background timer
		else
			numberOfRows = DimSize(ActiveDevTimeParam, ROWS)
			Redimension/N=(numberOfRows + 1, 5) ActiveDevTimeParam
			ActiveDevTimeParam[numberOfRows][0] = deviceID
			ActiveDevTimeParam[numberOfRows][1] = startTime
			ActiveDevTimeParam[numberOfRows][2] = RunTime
			ActiveDevTimeParam[numberOfRows][3] = EndTime
			//ActiveDevTimeParam[0][4] = Elapsed time - calculated by background timer
		endif
	elseif(addOrRemoveDevice == -1) // remove a DAQ device
		FindValue/V=(deviceID)/RMD=[][0] ActiveDevTimeParam
		rowToRemove = V_Value
		ASSERT(rowToRemove >= 0, "Trying to remove a non existing device")
		DeletePoints/M=(ROWS) rowToRemove, 1, ActiveDevTimeParam
	else
		ASSERT(0, "Invalid addOrRemoveDevice value")
	endif

	DQM_MakeOrUpdtDevTimerTxtWv(device, ListOfFunctions, rowToRemove, addOrRemoveDevice)

	WAVE/Z/SDFR=dfr ActiveDevTimeParam, TimerFunctionListWave
	ASSERT(WaveExists(ActiveDevTimeParam), "Missing wave ActiveDevTimeParam")
	ASSERT(WaveExists(TimerFunctionListWave), "Missing wave TimerFunctionListWave")
	ASSERT(DimSize(TimerFunctionListWave, ROWS) == DimSize(ActiveDevTimeParam, ROWS), "Number of rows in ActiveDevTimeParam and TimerFunctionListWave must be equal")
End

static Function DQM_MakeOrUpdtDevTimerTxtWv(device, listOfFunctions, rowToRemove, addOrRemoveDevice)
	string device, listOfFunctions
	variable rowToRemove, addOrRemoveDevice

	variable numberOfRows

	DFREF dfr = GetActiveDAQDevicesTimerFolder()
	WAVE/Z/T/SDFR=dfr TimerFunctionListWave

	if(addOrRemoveDevice == 1) // Add a device
		if(!WaveExists(TimerFunctionListWave))
			Make/T/N=(1, 2) dfr:TimerFunctionListWave/Wave=TimerFunctionListWave
			TimerFunctionListWave[0][0] = device
			TimerFunctionListWave[0][1] = listOfFunctions
		else
			numberOfRows = DimSize(TimerFunctionListWave, ROWS)
			Redimension/N=(numberOfRows + 1, 2) TimerFunctionListWave
			TimerFunctionListWave[numberOfRows][0] = device
			TimerFunctionListWave[numberOfRows][1] = listOfFunctions
		endif
	elseif(addOrRemoveDevice == -1) // remove a device
		ASSERT(rowToRemove >= 0 && rowToRemove < DimSize(TimerFunctionListWave, ROWS), "Trying to remove a non existing index")
		DeletePoints/M=(ROWS) rowToRemove, 1, TimerFunctionListWave
	else
		ASSERT(0, "Invalid addOrRemoveDevice value")
	endif
End
