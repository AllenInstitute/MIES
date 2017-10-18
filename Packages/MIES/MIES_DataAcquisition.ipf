#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DAQ
#endif

static Constant DEFAULT_MAXAUTOBIASCURRENT = 1500e-12 /// Unit: Amps

/// @file MIES_XXX.ipf
/// @brief __DAQ__ XX

/// @brief Stop the DAQ and testpulse
///
/// Works with single/multi device mode and on yoked devices simultaneously.
Function ITC_StopOngoingDAQ(panelTitle)
	string panelTitle

	DQM_CallFuncForDevicesYoked(panelTitle, ITC_StopOngoingDAQHelper)
End

/// @brief Stop the testpulse and data acquisition
static Function ITC_StopOngoingDAQHelper(panelTitle)
	string panelTitle

	variable needsOTCAfterDAQ = 0
	variable discardData      = 0

	if(IsDeviceActiveWithBGTask(panelTitle, "Testpulse"))
		ITC_StopTestPulseSingleDevice(panelTitle)

		needsOTCAfterDAQ = needsOTCAfterDAQ | 0
		discardData      = discardData      | 1
	elseif(IsDeviceActiveWithBGTask(panelTitle, "TestPulseMD"))
		ITC_StopTestPulseMultiDevice(panelTitle)

		needsOTCAfterDAQ = needsOTCAfterDAQ | 0
		discardData      = discardData      | 1
	endif

	if(IsDeviceActiveWithBGTask(panelTitle, "ITC_Timer"))
		ITC_StopBackgroundTimerTask()

		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
		discardData      = discardData      | 1
	elseif(IsDeviceActiveWithBGTask(panelTitle, "ITC_TimerMD"))
		ITC_StopITCDeviceTimer(panelTitle)

		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
		discardData      = discardData      | 1
	endif

	if(IsDeviceActiveWithBGTask(panelTitle, "ITC_FIFOMonitor"))
		ITC_STOPFifoMonitor()
		ITC_StopITCDeviceTimer(panelTitle)

		NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
		HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal)
		HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, zeroDAC = 1)

		if(!discardData)
			SWS_SaveAndScaleITCData(panelTitle, forcedStop = 1)
		endif

		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
	elseif(IsDeviceActiveWithBGTask(panelTitle, "ITC_FIFOMonitorMD"))
		DQM_TerminateOngoingDAQHelper(panelTitle)
		ITC_StopITCDeviceTimer(panelTitle)

		if(!discardData)
			SWS_SaveAndScaleITCData(panelTitle, forcedStop = 1)
		endif

		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
	else
		// force a stop if invoked during a 'down' time, with nothing happening.
		if(!RA_IsFirstSweep(panelTitle))
			NVAR count = $GetCount(panelTitle)
			count = GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_SweepsInSet")
			needsOTCAfterDAQ = needsOTCAfterDAQ | 1
		endif
	endif

	NVAR dataAcqRunMode = $GetDataAcqRunMode(panelTitle)

	if(dataAcqRunMode != DAQ_NOT_RUNNING)
		needsOTCAfterDAQ = needsOTCAfterDAQ | 1
	endif

	if(needsOTCAfterDAQ)
		DAP_OneTimeCallAfterDAQ(panelTitle, forcedStop = 1)
	endif
End

/// @brief Stores the timer number in a wave where the row number corresponds to the Device ID global.
///
/// This function and ITC_StopITCDeviceTimer are used to correct the ITI for the time it took to collect data, and pre and post processing of data.
/// It allows for a real time, start to start, ITI
Function ITC_StartITCDeviceTimer(panelTitle)
	string panelTitle

	string msg

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	DFREF timer = GetActiveITCDevicesTimerFolder()

	WAVE/Z/SDFR=timer CycleTimeStorageWave
	if(!WaveExists(CycleTimeStorageWave))
		// the size of the wave is limited by the number of igor timers.
		// This will also limit the number of simultaneously active devices possible to 10
		Make/N=10 timer:CycleTimeStorageWave/Wave=CycleTimeStorageWave
	endif

	variable timerID = startmstimer

	ASSERT(timerID != -1, "No more ms timers available, Run: ITC_StopAllMSTimers() to reset")
	CycleTimeStorageWave[ITCDeviceIDGlobal] = timerID

	sprintf msg, "started timer %d", timerID
	DEBUGPRINT(msg)
End

/// @brief Stops the timer associated with a particular device
Function ITC_StopITCDeviceTimer(panelTitle)
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
Function ITC_StopDAQ(panelTitle)
	string panelTitle

	variable runMode

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
			ITC_StopOngoingDAQ(panelTitle)
			return runMode
	endswitch

	return DAQ_NOT_RUNNING
End

/// @todo how to handle yoked devices??
Function ITC_RestartDAQ(panelTitle, dataAcqRunMode)
	string panelTitle
	variable dataAcqRunMode

	switch(dataAcqRunMode)
		case DAQ_NOT_RUNNING:
			// nothing to do
			break
		case DAQ_FG_SINGLE_DEVICE:
			ITC_StartDAQSingleDevice(panelTitle, useBackground=0)
			break
		case DAQ_BG_SINGLE_DEVICE:
			ITC_StartDAQSingleDevice(panelTitle, useBackground=1)
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
Function ITC_ApplyAutoBias(panelTitle, BaselineSSAvg, SSResistance)
	string panelTitle
	Wave BaselineSSAvg, SSResistance

	variable headStage, actualcurrent, current, targetVoltage, targetVoltageTol, setVoltage
	variable activeADCol, DAC, ADC
	variable resistance, maximumAutoBiasCurrent
	Wave TPStorage = GetTPStorage(panelTitle)
	variable lastInvocation = GetNumberFromWaveNote(TPStorage, AUTOBIAS_LAST_INVOCATION_KEY)
	variable curTime = ticks * TICKS_TO_SECONDS

	WAVE guiStateWave = GetDA_EphysGuiStateNum(panelTitle)

	if( (curTime - lastInvocation) < GuiStateWave[0][%setvar_Settings_AutoBiasInt] )
		return NaN
	endif

	DEBUGPRINT("ITC_ApplyAutoBias's turn, curTime=", var=curTime)
	SetNumberInWaveNote(TPStorage, AUTOBIAS_LAST_INVOCATION_KEY, curTime)

	if(isEmpty(panelTitle))
		DEBUGPRINT("Can't work with an empty panelTitle")
		return NaN
	endif

	Wave channelClampMode = GetChannelClampMode(panelTitle)
	Wave ampSettings      = GetAmplifierParamStorageWave(panelTitle)

	for(headStage=0; headStage < NUM_HEADSTAGES; headStage+=1)

		DAC = AFH_GetDACFromHeadstage(panelTitle, headstage)
		ADC = AFH_GetADCFromHeadstage(panelTitle, headstage)

		// From DAP_RemoveClampModeSettings and DAP_ApplyClmpModeSavdSettngs we know that
		// both wave entries are NaN iff the headstage is unset
		if(!IsFinite(DAC) || !IsFinite(ADC) || !IsFinite(channelClampMode[DAC][%DAC]) || !IsFinite(channelClampMode[ADC][%ADC]))
			continue
		endif

		// headStage channels not in current clamp mode
		if(channelClampMode[DAC][%DAC] != I_CLAMP_MODE && channelClampMode[ADC][%ADC] != I_CLAMP_MODE)
			continue
		endif

		// autobias not enabled
		if(!ampSettings[%AutoBiasEnable][0][headStage])
			continue
		endif

		DEBUGPRINT("current clamp mode set in headstage", var=headStage)

		maximumAutoBiasCurrent = abs(ampSettings[%AutoBiasIbiasmax][0][headStage] * 1e-12)
		if(maximumAutoBiasCurrent == 0 || maximumAutoBiasCurrent > DEFAULT_MAXAUTOBIASCURRENT)
			printf "Warning for headStage %d: replacing invalid maximum auto bias currrent of %g with %g\r", headStage, maximumAutoBiasCurrent, DEFAULT_MAXAUTOBIASCURRENT
			maximumAutoBiasCurrent = DEFAULT_MAXAUTOBIASCURRENT
		endif

		DEBUGPRINT("maximumAutoBiasCurrent=", var=maximumAutoBiasCurrent)

		/// all variables holding physical units use plain values without prefixes
		/// e.g Amps instead of pA

		targetVoltage    = ampSettings[%AutoBiasVcom][0][headStage] * 1e-3
		targetVoltageTol = ampSettings[%AutoBiasVcomVariance][0][headStage] * 1e-3

		activeADCol = TP_GetTPResultsColOfHS(panelTitle, headstage)
		ASSERT(activeADCol >= 0, "Active Testpulse column is invalid")

		resistance = SSResistance[0][activeADCol] * 1e6
		setVoltage = BaselineSSAvg[0][activeADCol] * 1e-3

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
			printf "Headstage %d: Not applying autobias current shot of %gA as that would exceed the maximum allowed current of %gA\r", headStage, current, maximumAutoBiasCurrent
			continue
		endif

		DEBUGPRINT("current[A] to send=", var=current)
		AI_UpdateAmpModel(panelTitle, "check_DatAcq_HoldEnable", headStage, value=1)
		AI_UpdateAmpModel(panelTitle, "setvar_DataAcq_Hold_IC", headstage, value=current * 1e12)
	endfor
End
