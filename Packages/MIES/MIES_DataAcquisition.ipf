#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DAQ
#endif

/// @file MIES_DataAcquisition.ipf
/// @brief __DQ__ Routines for Data acquisition

/// @brief Stop DAQ and TP on all locked devices
Function DQ_StopOngoingDAQAllLocked(variable stopReason)
	variable i, numDev, err
	string device

	SVAR devices = $GetDevicePanelTitleList()
	numDev = ItemsInList(devices)
	for(i = 0; i < numDev; i += 1)
		device = StringFromList(i, devices)

		AssertOnAndClearRTError()
		DQ_StopOngoingDAQ(device, stopReason, startTPAfterDAQ = 0); err = GetRTError(1) // see developer docu section Preventing Debugger Popup
	endfor
End

/// @brief Stop the DAQ and testpulse
///
/// Works with single/multi device mode and on yoked devices simultaneously.
///
/// @param device      device
/// @param stopReason      One of @ref DAQStoppingFlags
/// @param startTPAfterDAQ [optional, defaults to true]  start "TP after DAQ" if enabled
Function DQ_StopOngoingDAQ(string device, variable stopReason, [variable startTPAfterDAQ])
	variable i, numEntries
	string list, leaderAndFollower

	startTPAfterDAQ = ParamIsDefault(startTPAfterDAQ) ? 1 : !!startTPAfterDAQ

	list = GetListofLeaderAndPossFollower(device)
	numEntries = ItemsInList(list)

	for(i = 0; i < numEntries; i += 1)
		leaderAndFollower = StringFromList(i, list)
		DQ_StopOngoingDAQHelper(leaderAndFollower, stopReason, startTPAfterDAQ)
	endfor
End

/// @brief Stop the testpulse and data acquisition
static Function DQ_StopOngoingDAQHelper(string device, variable stopReason, variable startTPAfterDAQ)
	variable needsOTCAfterDAQ = 0
	variable discardData      = 0
	variable stopDeviceTimer  = 0

	if(IsDeviceActiveWithBGTask(device, TASKNAME_TP))
		TPS_StopTestPulseSingleDevice(device)

		needsOTCAfterDAQ = needsOTCAfterDAQ | 0
		discardData      = discardData      | 1
	elseif(IsDeviceActiveWithBGTask(device, TASKNAME_TPMD))
		TPM_StopTestPulseMultiDevice(device)

		needsOTCAfterDAQ = needsOTCAfterDAQ | 0
		discardData      = discardData      | 1
	endif

	if(IsDeviceActiveWithBGTask(device, TASKNAME_TIMER))
		DQS_StopBackgroundTimer()

		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
		discardData      = discardData      | 1
	elseif(IsDeviceActiveWithBGTask(device, TASKNAME_TIMERMD))
		DQM_StopBackgroundTimer(device)

		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
		discardData      = discardData      | 1
	endif

	if(IsDeviceActiveWithBGTask(device, TASKNAME_FIFOMON))
		DQS_StopBackgroundFifoMonitor()

		NVAR deviceID = $GetDAQDeviceID(device)
		HW_StopAcq(HARDWARE_ITC_DAC, deviceID, zeroDAC = 1)

		if(!discardData)
			SWS_SaveAcquiredData(device, forcedStop = 1)
		endif

		stopDeviceTimer  = stopDeviceTimer | 1
		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
	elseif(IsDeviceActiveWithBGTask(device, TASKNAME_FIFOMONMD))
		DQM_TerminateOngoingDAQHelper(device)

		if(!discardData)
			SWS_SaveAcquiredData(device, forcedStop = 1)
		endif

		stopDeviceTimer  = stopDeviceTimer | 1
		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
	else
		// force a stop if invoked during a 'down' time, with nothing happening.
		if(!RA_IsFirstSweep(device))
			NVAR count = $GetCount(device)
			count = GetValDisplayAsNum(device, "valdisp_DataAcq_SweepsInSet")

			stopDeviceTimer  = stopDeviceTimer | 1
			needsOTCAfterDAQ = needsOTCAfterDAQ | 1
		endif
	endif

	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)

	if(dataAcqRunMode != DAQ_NOT_RUNNING)
		stopDeviceTimer  = stopDeviceTimer | 1
		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
	endif

	if(stopDeviceTimer)
		DQ_StopDAQDeviceTimer(device)
	endif

	if(needsOTCAfterDAQ)
		DAP_OneTimeCallAfterDAQ(device, stopReason, forcedStop = 1, startTPAfterDAQ = startTPAfterDAQ)
	endif
End

/// @brief Start the per-device timer used for the ITI (inter trial interval)
///
/// This function and DQ_StopDAQDeviceTimer are used to correct the ITI for the
/// time it took to collect data, and pre and post processing of data. It
/// allows for a real time, start to start, ITI
Function DQ_StartDAQDeviceTimer(device)
	string device

	string msg

	NVAR deviceID = $GetDAQDeviceID(device)
	DFREF timer = GetActiveDAQDevicesTimerFolder()

	WAVE/Z/SDFR=timer CycleTimeStorageWave
	if(!WaveExists(CycleTimeStorageWave))
		// the size of the wave is limited by the number of igor timers.
		// This will also limit the number of simultaneously active devices possible to 10
		Make/N=(MAX_NUM_MS_TIMERS) timer:CycleTimeStorageWave/Wave=CycleTimeStorageWave
	endif

	variable timerID = startmstimer

	ASSERT(timerID != -1, "No more ms timers available, Run: StopAllMSTimers() to reset")
	CycleTimeStorageWave[deviceID] = timerID

	sprintf msg, "started timer %d", timerID
	DEBUGPRINT(msg)
End

/// @brief Stop the per-device timer associated with a particular device
Function DQ_StopDAQDeviceTimer(device)
	string device

	variable timerID
	string msg

	WAVE/Z/SDFR=GetActiveDAQDevicesTimerFolder() CycleTimeStorageWave

	if(!WaveExists(CycleTimeStorageWave))
		return NaN
	endif

	NVAR deviceID = $GetDAQDeviceID(device)

	timerID = CycleTimeStorageWave[deviceID]

	sprintf msg, "stopped timer %d", timerID
	DEBUGPRINT(msg)

	return stopmstimer(timerID) / 1000000
End

/// @brief Stop any running background DAQ
///
/// Assumes that single device and multi device do not run at the same time.
/// @return One of @ref DAQRunModes
Function DQ_StopDAQ(string device, variable stopReason, [variable startTPAfterDAQ])
	variable runMode

	startTPAfterDAQ = ParamIsDefault(startTPAfterDAQ) ? 1 : !!startTPAfterDAQ

	// create readonly copy as the implicitly called DAP_OneTimeCallAfterDAQ()
	// will change it
	runMode = ROVar(GetDataAcqRunMode(device))

	switch(runMode)
		case DAQ_FG_SINGLE_DEVICE:
			// can not be stopped
			return runMode
		case DAQ_BG_SINGLE_DEVICE:
		case DAQ_BG_MULTI_DEVICE:
			DQ_StopOngoingDAQ(device, stopReason, startTPAfterDAQ = startTPAfterDAQ)
			return runMode
	endswitch

	return DAQ_NOT_RUNNING
End

/// @todo how to handle yoked devices??
Function DQ_RestartDAQ(device, dataAcqRunMode)
	string device
	variable dataAcqRunMode

	switch(dataAcqRunMode)
		case DAQ_NOT_RUNNING:
			// nothing to do
			break
		case DAQ_FG_SINGLE_DEVICE:
			AS_HandlePossibleTransition(device, AS_EARLY_CHECK, call = 0)
			AS_HandlePossibleTransition(device, AS_PRE_DAQ, call = 0)
			DQS_StartDAQSingleDevice(device, useBackground=0)
			break
		case DAQ_BG_SINGLE_DEVICE:
			AS_HandlePossibleTransition(device, AS_EARLY_CHECK, call = 0)
			AS_HandlePossibleTransition(device, AS_PRE_DAQ, call = 0)
			DQS_StartDAQSingleDevice(device, useBackground=1)
			break
		case DAQ_BG_MULTI_DEVICE:
			AS_HandlePossibleTransition(device, AS_EARLY_CHECK, call = 0)
			AS_HandlePossibleTransition(device, AS_PRE_DAQ, call = 0)
			DQM_StartDAQMultiDevice(device)
			break
		default:
			DEBUGPRINT("Ignoring unknown value:", var=dataAcqRunMode)
			break
	endswitch
End

/// @brief Handle automatic bias current injection
///
/// @param device Locked panel with test pulse running occasionally
/// @param TPResults  Data from TP_ROAnalysis()
Function DQ_ApplyAutoBias(device, TPResults)
	string device
	Wave TPResults

	variable headStage, actualcurrent, current, targetVoltage, targetVoltageTol, setVoltage
	variable resistance, maximumAutoBiasCurrent, lastInvocation, curTime

	if(DAP_DeviceIsUnlocked(device))
		return NaN
	endif

	Wave TPStorage = GetTPStorage(device)
	lastInvocation = GetNumberFromWaveNote(TPStorage, AUTOBIAS_LAST_INVOCATION_KEY)
	curTime = ticks * TICKS_TO_SECONDS

	if( (curTime - lastInvocation) < DAG_GetNumericalValue(device, "setvar_Settings_AutoBiasInt"))
		return NaN
	endif

	DEBUGPRINT("DQ_ApplyAutoBias's turn, curTime=", var=curTime)
	SetNumberInWaveNote(TPStorage, AUTOBIAS_LAST_INVOCATION_KEY, curTime, format="%.06f")

	Wave ampSettings = GetAmplifierParamStorageWave(device)
	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	for(headStage=0; headStage < NUM_HEADSTAGES; headStage+=1)

		if(!statusHS[headstage])
			continue
		endif

		if(DAG_GetHeadstageMode(device, headstage) != I_CLAMP_MODE)
			continue
		endif

		// autobias not enabled
		if(!ampSettings[%AutoBiasEnable][0][headStage])
			continue
		endif

		DEBUGPRINT("current clamp mode set in headstage", var=headStage)

		maximumAutoBiasCurrent = abs(ampSettings[%AutoBiasIbiasmax][0][headStage] * 1e-12)
		DEBUGPRINT("maximumAutoBiasCurrent=", var=maximumAutoBiasCurrent)

		/// all variables holding physical units use plain values without prefixes
		/// e.g Amps instead of pA

		targetVoltage    = ampSettings[%AutoBiasVcom][0][headStage] * 1e-3
		targetVoltageTol = ampSettings[%AutoBiasVcomVariance][0][headStage] * 1e-3

		resistance = TPResults[%ResistanceSteadyState][headstage] * 1e6
		setVoltage = TPResults[%BaselineSteadyState][headstage] * 1e-3

		DEBUGPRINT("resistance[Ohm]=", var=resistance)
		DEBUGPRINT("setVoltage[V]=", var=setVoltage)
		DEBUGPRINT("targetVoltage[V]=", var=targetVoltage)

		// if we are in the desired voltage region, check the next headstage
		if(abs(targetVoltage - setVoltage) < targetVoltageTol)
			continue
		endif

		// neuron needs a current shot
		// I = U / R
		current = ( targetVoltage - setVoltage ) / resistance
		DEBUGPRINT("current[A]=", var=current)
		// only use part of the calculated current, as BaselineSSAvg holds
		// an overestimate for small buffer sizes
		current *= DAG_GetNumericalValue(device, "setvar_Settings_AutoBiasPerc") / 100

		// check if holding is enabled. If it is not, ignore holding current value.
		if(AI_SendToAmp(device, headStage, I_CLAMP_MODE, MCC_GETHOLDINGENABLE_FUNC, NaN))
			actualCurrent = AI_SendToAmp(device, headStage, I_CLAMP_MODE, MCC_GETHOLDING_FUNC, NaN, usePrefixes=0)
		else
			actualCurrent = 0
		endif

		DEBUGPRINT("actualCurrent[A]=", var=actualCurrent)

		if(!IsFinite(actualCurrent))
			print "Queried amplifier current is non-finite"
			ControlWindowToFront()
			continue
		endif

		current += actualCurrent

		if( abs(current) > maximumAutoBiasCurrent)
			printf "Headstage %d: Not applying autobias current shot of %.0W0PA as that would exceed the maximum allowed current of %.0W0PA\r", headStage, current, maximumAutoBiasCurrent
			continue
		endif

		DEBUGPRINT("current[A] to send=", var=current)
		AI_UpdateAmpModel(device, "check_DatAcq_HoldEnable", headStage, value=1, sendToAll=0)
		AI_UpdateAmpModel(device, "setvar_DataAcq_Hold_IC", headstage, value=current * 1e12,sendToAll=0)
	endfor
End

/// @brief Return the number of devices which have DAQ running
Function DQ_GetNumDevicesWithDAQRunning()

	variable numEntries, i, count
	string list, device

	list = GetListOfLockedDevices()
	numEntries = ItemsInList(list)
	for(i= 0; i < numEntries;i += 1)
		device = StringFromList(i, list)
		NVAR daqMode=$GetDataAcqRunMode(device)

		count += (daqMode != DAQ_NOT_RUNNING)
	endfor

	return count
End
