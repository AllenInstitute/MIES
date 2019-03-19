#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DAQ
#endif

/// @file MIES_DataAcquisition.ipf
/// @brief __DQ__ Routines for Data acquisition

/// @brief Stop the DAQ and testpulse
///
/// Works with single/multi device mode and on yoked devices simultaneously.
///
/// @param panelTitle      device
/// @param startTPAfterDAQ [optional, defaults to true]  start "TP after DAQ" if enabled
Function DQ_StopOngoingDAQ(panelTitle, [startTPAfterDAQ])
	string panelTitle
	variable startTPAfterDAQ

	startTPAfterDAQ = ParamIsDefault(startTPAfterDAQ) ? 1 : !!startTPAfterDAQ

	if(startTPAfterDAQ)
		DQM_CallFuncForDevicesYoked(panelTitle, DQ_StopOngoingDAQHelperWithTPA)
	else
		DQM_CallFuncForDevicesYoked(panelTitle, DQ_StopOngoingDAQHelperNoTPA)
	endif
End

/// @brief Helper function for DQ_StopOngoingDAQHelper() with CallFunctionForEachListItem() compatible signature
static Function DQ_StopOngoingDAQHelperWithTPA(panelTitle)
	string panelTitle

	DQ_StopOngoingDAQHelper(panelTitle, startTPAfterDAQ = 1)
End

/// @brief Helper function for DQ_StopOngoingDAQHelper() with CallFunctionForEachListItem() compatible signature
static Function DQ_StopOngoingDAQHelperNoTPA(panelTitle)
	string panelTitle

	DQ_StopOngoingDAQHelper(panelTitle, startTPAfterDAQ = 0)
End

/// @brief Stop the testpulse and data acquisition
static Function DQ_StopOngoingDAQHelper(panelTitle, [startTPAfterDAQ])
	string panelTitle
	variable startTPAfterDAQ

	variable needsOTCAfterDAQ = 0
	variable discardData      = 0
	variable stopDeviceTimer  = 0

	startTPAfterDAQ = ParamIsDefault(startTPAfterDAQ) ? 1 : !!startTPAfterDAQ

	if(IsDeviceActiveWithBGTask(panelTitle, TASKNAME_TP))
		TPS_StopTestPulseSingleDevice(panelTitle)

		needsOTCAfterDAQ = needsOTCAfterDAQ | 0
		discardData      = discardData      | 1
	elseif(IsDeviceActiveWithBGTask(panelTitle, TASKNAME_TPMD))
		TPM_StopTestPulseMultiDevice(panelTitle)

		needsOTCAfterDAQ = needsOTCAfterDAQ | 0
		discardData      = discardData      | 1
	endif

	if(IsDeviceActiveWithBGTask(panelTitle, TASKNAME_TIMER))
		DQS_StopBackgroundTimer()

		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
		discardData      = discardData      | 1
	elseif(IsDeviceActiveWithBGTask(panelTitle, TASKNAME_TIMERMD))
		DQM_StopBackgroundTimer(panelTitle)

		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
		discardData      = discardData      | 1
	endif

	if(IsDeviceActiveWithBGTask(panelTitle, TASKNAME_FIFOMON))
		DQS_StopBackgroundFifoMonitor()

		NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
		HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, zeroDAC = 1)

		if(!discardData)
			SWS_SaveAndScaleITCData(panelTitle, forcedStop = 1)
		endif

		stopDeviceTimer  = stopDeviceTimer | 1
		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
	elseif(IsDeviceActiveWithBGTask(panelTitle, TASKNAME_FIFOMONMD))
		DQM_TerminateOngoingDAQHelper(panelTitle)

		if(!discardData)
			SWS_SaveAndScaleITCData(panelTitle, forcedStop = 1)
		endif

		stopDeviceTimer  = stopDeviceTimer | 1
		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
	else
		// force a stop if invoked during a 'down' time, with nothing happening.
		if(!RA_IsFirstSweep(panelTitle))
			NVAR count = $GetCount(panelTitle)
			count = GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_SweepsInSet")

			stopDeviceTimer  = stopDeviceTimer | 1
			needsOTCAfterDAQ = needsOTCAfterDAQ | 1
		endif
	endif

	NVAR dataAcqRunMode = $GetDataAcqRunMode(panelTitle)

	if(dataAcqRunMode != DAQ_NOT_RUNNING)
		stopDeviceTimer  = stopDeviceTimer | 1
		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
	endif

	if(stopDeviceTimer)
		DQ_StopITCDeviceTimer(panelTitle)
	endif

	if(needsOTCAfterDAQ)
		DAP_OneTimeCallAfterDAQ(panelTitle, forcedStop = 1, startTPAfterDAQ = startTPAfterDAQ)
	endif
End

/// @brief Start the per-device timer used for the ITI (inter trial interval)
///
/// This function and DQ_StopITCDeviceTimer are used to correct the ITI for the
/// time it took to collect data, and pre and post processing of data. It
/// allows for a real time, start to start, ITI
Function DQ_StartITCDeviceTimer(panelTitle)
	string panelTitle

	string msg

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	DFREF timer = GetActiveITCDevicesTimerFolder()

	WAVE/Z/SDFR=timer CycleTimeStorageWave
	if(!WaveExists(CycleTimeStorageWave))
		// the size of the wave is limited by the number of igor timers.
		// This will also limit the number of simultaneously active devices possible to 10
		Make/N=(MAX_NUM_MS_TIMERS) timer:CycleTimeStorageWave/Wave=CycleTimeStorageWave
	endif

	variable timerID = startmstimer

	ASSERT(timerID != -1, "No more ms timers available, Run: StopAllMSTimers() to reset")
	CycleTimeStorageWave[ITCDeviceIDGlobal] = timerID

	sprintf msg, "started timer %d", timerID
	DEBUGPRINT(msg)
End

/// @brief Stop the per-device timer associated with a particular device
Function DQ_StopITCDeviceTimer(panelTitle)
	string panelTitle

	variable timerID
	string msg

	WAVE/Z/SDFR=GetActiveITCDevicesTimerFolder() CycleTimeStorageWave

	if(!WaveExists(CycleTimeStorageWave))
		return NaN
	endif

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	timerID = CycleTimeStorageWave[ITCDeviceIDGlobal]

	sprintf msg, "stopped timer %d", timerID
	DEBUGPRINT(msg)

	return stopmstimer(timerID) / 1000000
End

/// @brief Stop any running background DAQ
///
/// Assumes that single device and multi device do not run at the same time.
/// @return One of @ref DAQRunModes
Function DQ_StopDAQ(panelTitle, [startTPAfterDAQ])
	string panelTitle
	variable startTPAfterDAQ

	variable runMode

	startTPAfterDAQ = ParamIsDefault(startTPAfterDAQ) ? 1 : !!startTPAfterDAQ

	NVAR dataAcqRunMode = $GetDataAcqRunMode(panelTitle)

	// create copy as the implicitly called DAP_OneTimeCallAfterDAQ()
	// will change it
	runMode = dataAcqRunMode

	switch(runMode)
		case DAQ_FG_SINGLE_DEVICE:
			// can not be stopped
			return runMode
		case DAQ_BG_SINGLE_DEVICE:
		case DAQ_BG_MULTI_DEVICE:
			DQ_StopOngoingDAQ(panelTitle, startTPAfterDAQ = startTPAfterDAQ)
			return runMode
	endswitch

	return DAQ_NOT_RUNNING
End

/// @todo how to handle yoked devices??
Function DQ_RestartDAQ(panelTitle, dataAcqRunMode)
	string panelTitle
	variable dataAcqRunMode

	switch(dataAcqRunMode)
		case DAQ_NOT_RUNNING:
			// nothing to do
			break
		case DAQ_FG_SINGLE_DEVICE:
			DQS_StartDAQSingleDevice(panelTitle, useBackground=0)
			break
		case DAQ_BG_SINGLE_DEVICE:
			DQS_StartDAQSingleDevice(panelTitle, useBackground=1)
			break
		case DAQ_BG_MULTI_DEVICE:
			DQM_StartDAQMultiDevice(panelTitle)
			break
		default:
			DEBUGPRINT("Ignoring unknown value:", var=dataAcqRunMode)
			break
	endswitch
End

/// @brief Handle automatic bias current injection
///
/// @param panelTitle	locked panel with test pulse running occasionally
/// @param BaselineSSAvg
/// @param SSResistance
Function DQ_ApplyAutoBias(panelTitle, BaselineSSAvg, SSResistance)
	string panelTitle
	Wave BaselineSSAvg, SSResistance

	variable headStage, actualcurrent, current, targetVoltage, targetVoltageTol, setVoltage
	variable resistance, maximumAutoBiasCurrent
	Wave TPStorage = GetTPStorage(panelTitle)
	variable lastInvocation = GetNumberFromWaveNote(TPStorage, AUTOBIAS_LAST_INVOCATION_KEY)
	variable curTime = ticks * TICKS_TO_SECONDS

	WAVE guiStateWave = GetDA_EphysGuiStateNum(panelTitle)

	if( (curTime - lastInvocation) < GuiStateWave[0][%setvar_Settings_AutoBiasInt] )
		return NaN
	endif

	DEBUGPRINT("DQ_ApplyAutoBias's turn, curTime=", var=curTime)
	SetNumberInWaveNote(TPStorage, AUTOBIAS_LAST_INVOCATION_KEY, curTime, format="%.06f")

	Wave ampSettings = GetAmplifierParamStorageWave(panelTitle)
	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	for(headStage=0; headStage < NUM_HEADSTAGES; headStage+=1)

		if(!statusHS[headstage])
			continue
		endif

		if(DAG_GetHeadstageMode(panelTitle, headstage) != I_CLAMP_MODE)
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

		resistance = SSResistance[headstage] * 1e6
		setVoltage = BaselineSSAvg[headstage] * 1e-3

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
		current *= GuiStateWave[0][%setvar_Settings_AutoBiasPerc] / 100

		// check if holding is enabled. If it is not, ignore holding current value.
		if(AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETHOLDINGENABLE_FUNC, NaN))
			actualCurrent = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETHOLDING_FUNC, NaN, usePrefixes=0)
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
		AI_UpdateAmpModel(panelTitle, "check_DatAcq_HoldEnable", headStage, value=1, sendToAll=0)
		AI_UpdateAmpModel(panelTitle, "setvar_DataAcq_Hold_IC", headstage, value=current * 1e12,sendToAll=0)
	endfor
End
