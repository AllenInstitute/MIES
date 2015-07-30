#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ITC_DataAcq(panelTitle)
	string panelTitle

	string cmd
	variable i

	variable ADChannelToMonitor    = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_DAC)
	variable stopCollectionPoint   = DC_GetStopCollectionPoint(panelTitle, DATA_ACQUISITION_MODE)
	string oscilloscopeSubwindow   = SCOPE_GetGraph(panelTitle)

	NVAR ITCDeviceIDGlobal            = $GetITCDeviceIDGlobal(panelTitle)
	WAVE ITCDataWave                  = GetITCDataWave(panelTitle)
	WAVE ITCChanConfigWave            = GetITCChanConfigWave(panelTitle)
	WAVE ITCFIFOAvailAllConfigWave    = GetITCFIFOAvailAllConfigWave(panelTitle)
	WAVE ITCFIFOPositionAllConfigWave = GetITCFIFOPositionAllConfigWave(panelTitle)
	WAVE ResultsWave                  = GetITCResultsWave(panelTitle)
	ResultsWave = 0

	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	ExecuteITCOperationAbortOnError(cmd)

	sprintf cmd, "ITCconfigAllchannels, %s, %s" GetWavesDataFolder(ITCChanConfigWave, 2), GetWavesDataFolder(ITCDataWave, 2)
	ExecuteITCOperation(cmd)

	controlinfo /w =$panelTitle Check_DataAcq1_RepeatAcq
	variable RepeatedAcqOnOrOff = v_value

	do
		sprintf cmd, "ITCUpdateFIFOPositionAll , %s" GetWavesDataFolder(ITCFIFOPositionAllConfigWave, 2) // I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		ExecuteITCOperation(cmd)// this also seems necessary to update the DA channel data to the board!!

		if(RepeatedAcqOnOrOff)
			ITC_StartITCDeviceTimer(panelTitle) // starts a timer for each ITC device. Timer is used to do real time ITI timing.
		endif

		sprintf cmd, "ITCStartAcq"
		ExecuteITCOperationAbortOnError(cmd)

		do
			sprintf cmd, "ITCFIFOAvailableALL/z=0 , %s" GetWavesDataFolder(ITCFIFOAvailAllConfigWave, 2)
			ExecuteITCOperation(cmd)
			ITCDataWave[0][0] += 0
			DoUpdate/W=$oscilloscopeSubwindow
		while (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] < StopCollectionPoint)

		//Check Status
		sprintf cmd, "ITCGetState /R /O /C /E %s" GetWavesDataFolder(ResultsWave, 2)
		ExecuteITCOperation(cmd)
		sprintf cmd, "ITCStopAcq /z = 0"
		ExecuteITCOperation(cmd)
		itcdatawave[0][0] += 0 // Force onscreen update
		sprintf cmd, "ITCConfigChannelUpload /f /z = 0" //as long as this command is within the do-while loop the number of cycles can be repeated
		ExecuteITCOperation(cmd)
		i += 1
	while(i < 1)

	DM_SaveAndScaleITCData(panelTitle)
End

/// @brief Returns the device channel offset for the given device
///
/// @returns 16 for ITC1600 and 0 for all other types
Function ITC_CalculateDevChannelOffset(panelTitle)
	string panelTitle

	variable ret
	string deviceType, deviceNum

	ret = ParseDeviceString(panelTitle, deviceType, deviceNum)
	ASSERT(ret, "Could not parse device string")
	
	if(!cmpstr(deviceType, "ITC1600"))
		return 16
	endif

	return 0
End

//======================================================================================
Function ITC_BkrdDataAcq(panelTitle)
	string panelTitle

	string cmd
	variable /G root:MIES:ITCDevices:ADChannelToMonitor = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_DAC)
	string /G root:MIES:ITCDevices:panelTitleG = panelTitle

	WAVE ITCDataWave                  = GetITCDataWave(panelTitle)
	WAVE ITCChanConfigWave            = GetITCChanConfigWave(panelTitle)
	WAVE ITCFIFOAvailAllConfigWave    = GetITCFIFOAvailAllConfigWave(panelTitle)
	WAVE ITCFIFOPositionAllConfigWave = GetITCFIFOPositionAllConfigWave(panelTitle)

	variable /G root:MIES:ITCDevices:StopCollectionPoint = DC_GetStopCollectionPoint(panelTitle, DATA_ACQUISITION_MODE)
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	ExecuteITCOperationAbortOnError(cmd)

	sprintf cmd, "ITCconfigAllchannels, %s, %s" GetWavesDataFolder(ITCChanConfigWave, 2), GetWavesDataFolder(ITCDataWave, 2)
	ExecuteITCOperation(cmd)

	// I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
	// this also seems necessary to update the DA channel data to the board!!
	sprintf cmd, "ITCUpdateFIFOPositionAll , %s" GetWavesDataFolder(ITCFIFOPositionAllConfigWave, 2)
	ExecuteITCOperation(cmd)

	if(GetCheckboxState(panelTitle, "Check_DataAcq1_RepeatAcq"))
		ITC_StartITCDeviceTimer(panelTitle) // starts a timer for each ITC device. Timer is used to do real time ITI timing.
	endif

	sprintf cmd, "ITCStartAcq" 
	ExecuteITCOperationAbortOnError(cmd)

	ITC_StartBckgrdFIFOMonitor()
End
//======================================================================================
Function ITC_StopDataAcq()
	string cmd
	SVAR panelTitleG = root:MIES:ITCDevices:panelTitleG

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitleG)
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	ExecuteITCOperation(cmd)

	sprintf cmd, "ITCStopAcq /z = 0"
	ExecuteITCOperation(cmd)

	WAVE ITCDataWave = GetITCDataWave(panelTitleG)
	ITCDataWave[0][0] += 0 // Force onscreen update

	sprintf cmd, "ITCConfigChannelUpload /f /z = 0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
	ExecuteITCOperation(cmd)

	DM_SaveAndScaleITCData(panelTitleG)

	NVAR count = $GetCount(panelTitleG)
	if(!IsFinite(count))
		controlinfo /w = $panelTitleG Check_DataAcq1_RepeatAcq
		if(v_value == 1)//repeated aquisition is selected
			RA_Start(PanelTitleG)
		else
			DAP_OneTimeCallAfterDAQ(panelTitleG)
		endif
	else
		RA_BckgTPwithCallToRACounter(panelTitleG)//FUNCTION THAT ACTIVATES BCKGRD TP AND THEN CALLS REPEATED ACQ
	endif
END

//======================================================================================
Function ITC_StartBckgrdFIFOMonitor()
	CtrlNamedBackground ITC_FIFOMonitor, period = 2, proc = ITC_FIFOMonitor
	CtrlNamedBackground ITC_FIFOMonitor, start
End

Function ITC_FIFOMonitor(s)
	STRUCT WMBackgroundStruct &s

	string cmd

	NVAR StopCollectionPoint = root:MIES:ITCDevices:StopCollectionPoint
	NVAR ADChannelToMonitor  = root:MIES:ITCDevices:ADChannelToMonitor
	SVAR panelTitleG = root:MIES:ITCDevices:panelTitleG
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitleG)
	WAVE ITCFIFOAvailAllConfigWave = GetITCFIFOAvailAllConfigWave(panelTitleG)

	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	ExecuteITCOperationAbortOnError(cmd)
	sprintf cmd, "ITCFIFOAvailableALL /z = 0 , %s" GetWavesDataFolder(ITCFIFOAvailAllConfigWave, 2)
	ExecuteITCOperation(cmd)

	WAVE ITCDataWave = GetITCDataWave(panelTitleG)
	ITCDataWave[0][0] += 0 //forces on screen update

	if(ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] >= StopCollectionPoint)	
		ITC_STOPFifoMonitor()
		ITC_StopDataAcq()
	endif
	
	AM_analysisMasterMidSweep(panelTitleG)

	return 0
End

Function ITC_STOPFifoMonitor()
	CtrlNamedBackground ITC_FIFOMonitor, stop
End
//======================================================================================

Function ITC_StartBackgroundTimer(RunTimePassed,FunctionNameAPassedIn, FunctionNameBPassedIn,  FunctionNameCPassedIn, panelTitle)//Function name is the name of the function you want to run after run time has elapsed
	Variable RunTimePassed//how long you want the background timer to run in seconds
	String FunctionNameAPassedIn, FunctionNameBPassedIn, FunctionNameCPassedIn, panelTitle
	String /G root:MIES:ITCDevices:FunctionNameA = FunctionNameAPassedIn
	String /G root:MIES:ITCDevices:FunctionNameB = FunctionNameBPassedIn
	String /G root:MIES:ITCDevices:FunctionNameC = FunctionNameCPassedIn
	String /G root:MIES:ITCDevices:PanelTitleG = panelTitle
	Variable numTicks = 15		// Run every quarter second (15 ticks)
	Variable /G root:MIES:ITCDevices:Start = ticks
	Variable /G root:MIES:ITCDevices:RunTime = (RunTimePassed*60)
	CtrlNamedBackground ITC_Timer, period = 5, proc = ITC_Timer
	CtrlNamedBackground ITC_Timer, start
	
	If(RunTimePassed < 0)
		print "The time to configure the ITC device and the sweep time are greater than the user specified ITI"
		print "Data acquisition has not been interrupted but the actual ITI is longer than what was specified by:" + num2str(abs(RunTimePassed)) + "seconds"
	endif
End

Function ITC_Timer(s)
	STRUCT WMBackgroundStruct &s
	SVAR panelTitleG =  root:MIES:ITCDevices:panelTitleG
	NVAR Start = root:MIES:ITCDevices:Start, RunTime = root:MIES:ITCDevices:RunTime
	variable TimeLeft
	
	variable ElapsedTime = (ticks - Start)
	
	TimeLeft = abs(((RunTime - (ElapsedTime)) / 60))
	if(TimeLeft < 0)
		timeleft = 0
	endif
	ValDisplay valdisp_DataAcq_ITICountdown win = $panelTitleG, value = _NUM:TimeLeft
	
	if(ElapsedTime >= RunTime)
		ITC_StopBackgroundTimerTask()
	endif
	//printf "NextRunTicks %d", s.nextRunTicks
	return 0
End

Function ITC_StopBackgroundTimerTask()
	SVAR FunctionNameA = root:MIES:ITCDevices:FunctionNameA
	SVAR FunctionNameB = root:MIES:ITCDevices:FunctionNameB
	SVAR FunctionNameC = root:MIES:ITCDevices:FunctionNameC
	CtrlNamedBackground ITC_Timer, stop // had incorrect background procedure name
	Execute FunctionNameA
 	Execute FunctionNameB
End
//======================================================================================

Function ITC_StartBackgroundTestPulse(panelTitle)
	string panelTitle

	string /G root:MIES:ITCDevices:panelTitleG
	SVAR panelTitleG = root:MIES:ITCDevices:panelTitleG
	panelTitleG = panelTitle
	string cmd

	TP_ResetTPStorage(panelTitle)
	variable /G root:MIES:ITCDevices:StopCollectionPoint = DC_GetStopCollectionPoint(panelTitle, TEST_PULSE_MODE)
	variable /G root:MIES:ITCDevices:ADChannelToMonitor  = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_DAC)

	WAVE ITCDataWave                  = GetITCDataWave(panelTitle)
	WAVE ITCChanConfigWave            = GetITCChanConfigWave(panelTitle)

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)
	sprintf cmd, "ITCSelectDevice %d" ITCDeviceIDGlobal
	ExecuteITCOperationAbortOnError(cmd)

	sprintf cmd, "ITCconfigAllchannels, %s, %s", GetWavesDataFolder(ITCChanConfigWave, 2), GetWavesDataFolder(ITCDataWave, 2)
	ExecuteITCOperation(cmd)

	CtrlNamedBackground TestPulse, period = 1, proc = ITC_TestPulseFunc
	CtrlNamedBackground TestPulse, start
End
//======================================================================================

///@brief Background execution function for the test pulse data acquisition
Function ITC_TestPulseFunc(s)
	STRUCT BackgroundStruct &s

	NVAR StopCollectionPoint = root:MIES:ITCDevices:StopCollectionPoint
	NVAR ADChannelToMonitor  = root:MIES:ITCDevices:ADChannelToMonitor
	SVAR panelTitleG         = root:MIES:ITCDevices:PanelTitleG
	// create a copy as panelTitleG is killed in ITC_StopTestPulseSingleDevice
	// but we still need it afterwards
	string panelTitle        = panelTitleG

	if(s.wmbs.started)
		s.wmbs.started = 0
		s.count  = 0
	else
		s.count += 1
	endif

	String cmd, Keyboard
	WAVE ResultsWave                  = GetITCResultsWave(panelTitle)
	WAVE ITCFIFOAvailAllConfigWave    = GetITCFIFOAvailAllConfigWave(panelTitle)
	WAVE ITCFIFOPositionAllConfigWave = GetITCFIFOPositionAllConfigWave(panelTitle)

	NVAR DeviceID = $GetITCDeviceIDGlobal(panelTitle)
	sprintf cmd, "ITCSelectDevice %d" DeviceID
	ExecuteITCOperationAbortOnError(cmd)

	sprintf cmd, "ITCUpdateFIFOPositionAll , %s", GetWavesDataFolder(ITCFIFOPositionAllConfigWave, 2) // I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
	ExecuteITCOperation(cmd) // this also seems necessary to update the DA channel data to the board!!
	sprintf cmd, "ITCStartAcq"
	ExecuteITCOperationAbortOnError(cmd)

	do
		sprintf cmd, "ITCFIFOAvailableALL /z = 0 , %s", GetWavesDataFolder(ITCFIFOAvailAllConfigWave, 2)
		ExecuteITCOperation(cmd)
	while (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] < StopCollectionPoint)// 5000 IS CHOSEN AS A POINT THAT IS A BIT LARGER THAN THE OUTPUT DATA

	sprintf cmd, "ITCGetState /R /O /C /E %s", GetWavesDataFolder(ResultsWave, 2)
	ExecuteITCOperation(cmd)
	sprintf cmd, "ITCStopAcq /z = 0"
	ExecuteITCOperation(cmd)
	sprintf cmd, "ITCConfigChannelUpload /f /z = 0"//AS Long as this command is within the do-while loop the number of cycles can be repeated
	ExecuteITCOperation(cmd)
	DM_CreateScaleTPHoldingWave(panelTitle)
	TP_Delta(panelTitle)

	if(mod(s.count, TEST_PULSE_LIVE_UPDATE_INTERVAL) == 0)
		SCOPE_UpdateGraph(panelTitle)
	endif

	NVAR count = $GetCount(panelTitle)
	if(!IsFinite(count))
		Keyboard = KeyboardState("")
		if (cmpstr(Keyboard[9], " ") == 0)	// Is space bar pressed (note the space between the quotations)?
			beep
			ITC_StopTestPulseSingleDevice(panelTitle)
		endif
	endif

	return 0
End

Function ITC_StopTestPulseSingleDevice(panelTitle)
	string panelTitle

	variable headstage

	CtrlNamedBackground TestPulse, stop
	SCOPE_KillScopeWindowIfRequest(panelTitle)

	DAP_RestoreTTLState(panelTitle)
	EnableControl(panelTitle, "StartTestPulseButton")

	DFREF dfr = GetITCDevicesFolder()
	KillStrings/Z dfr:PanelTitleG

	headStage = GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage")
	P_LoadPressureButtonState(panelTitle, headStage)

	ED_TPDocumentation(panelTitle)
End

static Constant DEFAULT_MAXAUTOBIASCURRENT = 500e-12 /// Unit: Amps
static Constant AUTOBIAS_INTERVALL_SECONDS = 1

/// @brief Handle automatic bias current injection
///
/// @param panelTitle	locked panel with test pulse running occasionally
/// @param BaselineSSAvg
/// @param SSResistance
Function ITC_ApplyAutoBias(panelTitle, BaselineSSAvg, SSResistance)
	string panelTitle
	Wave BaselineSSAvg, SSResistance

	variable headStage, actualcurrent, current, targetVoltage, targetVoltageTol, setVoltage
	variable activeHeadStages, DAC, ADC
	variable resistance, maximumAutoBiasCurrent
	Wave TPStorage = GetTPStorage(panelTitle)
	variable lastInvocation = GetNumberFromWaveNote(TPStorage, AUTOBIAS_LAST_INVOCATION_KEY)
	variable curTime = ticks * TICKS_TO_SECONDS

	if( (curTime - lastInvocation) < AUTOBIAS_INTERVALL_SECONDS )
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

	activeHeadStages = 0
	for(headStage=0; headStage < NUM_HEADSTAGES; headStage+=1)

		DAC = TP_GetDAChannelFromHeadstage(panelTitle, headstage)
		ADC = TP_GetADChannelFromHeadstage(panelTitle, headstage)

		// From DAP_RemoveClampModeSettings and DAP_ApplyClmpModeSavdSettngs we know that
		// both wave entries are NaN iff the headstage is unset
		if(!IsFinite(DAC) || !IsFinite(ADC) || !IsFinite(channelClampMode[DAC][%DAC]) || !IsFinite(channelClampMode[ADC][%ADC]))
			continue
		endif

		activeHeadStages += 1

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

		/// all variables holding physical units use plain values without prefixes
		/// e.g Amps instead of pA

		targetVoltage    = ampSettings[%AutoBiasVcom][0][headStage] * 1e-3
		targetVoltageTol = ampSettings[%AutoBiasVcomVariance][0][headStage] * 1e-3

		resistance = SSResistance[0][activeHeadStages - 1] * 1e6
		setVoltage = BaselineSSAvg[0][activeHeadStages - 1] * 1e-3

		DEBUGPRINT("resistance=", var=resistance)
		DEBUGPRINT("setVoltage=", var=setVoltage)
		DEBUGPRINT("targetVoltage=", var=targetVoltage)

		// if we are in the desired voltage region, check the next headstage
		if(abs(targetVoltage - setVoltage) < targetVoltageTol)
			continue
		endif

		// neuron needs a current shot
		// I = U / R
		current = ( targetVoltage - setVoltage ) / resistance
		DEBUGPRINT("current=", var=current)
		// only use part of the calculated current, as BaselineSSAvg holds
		// an overestimate for small buffer sizes
		current *= 0.15
		
		// check if holding is enabled. If it is not, ignore holding current value.
		if(AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETHOLDINGENABLE_FUNC, NaN))
			actualCurrent = AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_GETHOLDING_FUNC, NaN)
		endif
		DEBUGPRINT("actualCurrent=", var=actualCurrent)

		if(!IsFinite(actualCurrent))
			print "Queried amplifier current is non-finite"
			continue
		endif

		current += actualCurrent

		if( abs(current) > maximumAutoBiasCurrent)
			printf "Not applying autobias current shot of %gA as that would exceed the maximum allowed current of %gA\r", current, maximumAutoBiasCurrent
			continue
		endif

		DEBUGPRINT("current to send=", var=current)

		AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_SETHOLDINGENABLE_FUNC, 1)
		ampSettings[17][0][headStage] = 1 /// @todo Modify AI_UpdateAmpModel to allow a value to be passed in, in place of the GUI query. 
		AI_SendToAmp(panelTitle, headStage, I_CLAMP_MODE, MCC_SETHOLDING_FUNC, current)
		ampSettings[16][0][headStage] = current * 1e12

		// update the DA_Ephys panel amp controls
		AI_UpdateAmpView(panelTitle, headStage, cntrlName = "setvar_DataAcq_Hold_IC")
		AI_UpdateAmpView(panelTitle, headStage, cntrlName = "check_DatAcq_HoldEnable")
	endfor
End

/// @brief Low level implementation for starting the test pulse
///
/// Please check before calling this function if not the functions #TP_StartTestPulseSingleDevice
/// or #TP_StartTestPulseMultiDevice are better suited for your application.
Function ITC_StartTestPulse(panelTitle)
	string panelTitle

	string cmd, keyboard
	variable i
	variable StopCollectionPoint = DC_GetStopCollectionPoint(panelTitle, TEST_PULSE_MODE)
	variable ADChannelToMonitor = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_DAC)

	TP_ResetTPStorage(panelTitle)
	string oscilloscopeSubwindow = SCOPE_GetGraph(panelTitle)

	WAVE ITCDataWave                  = GetITCDataWave(panelTitle)
	WAVE ITCChanConfigWave            = GetITCChanConfigWave(panelTitle)
	WAVE ITCFIFOAvailAllConfigWave    = GetITCFIFOAvailAllConfigWave(panelTitle)
	WAVE ITCFIFOPositionAllConfigWave = GetITCFIFOPositionAllConfigWave(panelTitle)
	WAVE ResultsWave                  = GetITCResultsWave(paneltitle)
	ResultsWave = 0

	sprintf cmd, "ITCconfigAllchannels, %s, %s", GetWavesDataFolder(ITCChanConfigWave, 2), GetWavesDataFolder(ITCDataWave, 2)
	ExecuteITCOperation(cmd)
	do
		// I have found it necessary to reset the fifo here, using the /r=1 with start acq doesn't seem to work
		// this also seems necessary to update the DA channel data to the board!!
		sprintf cmd, "ITCUpdateFIFOPositionAll , %s", GetWavesDataFolder(ITCFIFOPositionAllConfigWave, 2)
		ExecuteITCOperation(cmd)
		sprintf cmd, "ITCStartAcq"
		ExecuteITCOperationAbortOnError(cmd)

		do
			sprintf cmd, "ITCFIFOAvailableALL /z = 0 , %s", GetWavesDataFolder(ITCFIFOAvailAllConfigWave, 2)
			ExecuteITCOperation(cmd)
		while (ITCFIFOAvailAllConfigWave[ADChannelToMonitor][2] < StopCollectionPoint)

		sprintf cmd, "ITCGetState /R /O /C /E %s", GetWavesDataFolder(ResultsWave, 2)
		ExecuteITCOperation(cmd)
		sprintf cmd, "ITCStopAcq /z = 0"
		ExecuteITCOperation(cmd)
		DM_CreateScaleTPHoldingWave(panelTitle)
		TP_Delta(panelTitle)
		DoUpdate/W=$oscilloscopeSubwindow
		sprintf cmd, "ITCConfigChannelUpload /f /z = 0"//AS Long as this command is within the do-while loop the number of cycles can be repeated		
		ExecuteITCOperation(cmd)

		if(mod(i, TEST_PULSE_LIVE_UPDATE_INTERVAL) == 0)
			SCOPE_UpdateGraph(panelTitle)
		endif

		i += 1	
		Keyboard = KeyboardState("")
	while (cmpstr(Keyboard[9], " ") != 0)
	
	DAP_RestoreTTLState(panelTitle)
	ED_TPDocumentation(panelTitle)
	EnableControl(panelTitle,"StartTestPulseButton")
	
	// Update pressure buttons
	variable headStage = GetSliderPositionIndex(panelTitle, "slider_DataAcq_ActiveHeadstage") // determine the selected MIES headstage
	P_LoadPressureButtonState(panelTitle, headStage)
END
//======================================================================================

Function ITC_SingleADReading(Channel, panelTitle)//channels 16-23 are asynch channels on ITC1600
	variable Channel
	string panelTitle

	variable channelValue
	string cmd
	DFREF deviceDFR = GetDevicePath(panelTitle)

	Make/O/N=1 deviceDFR:AsyncChannelData/Wave=AsyncChannelData
	sprintf cmd, "ITCReadADC /V = 1 %d, %s" Channel, GetWavesDataFolder(AsyncChannelData, 2)
	ExecuteITCOperation(cmd)

	channelValue = AsyncChannelData[0]
	KillWaves/F AsyncChannelData
	return channelValue
End 

Function ITC_ADDataBasedWaveNotes(dataWave, panelTitle)
	WAVE dataWave
	string panelTitle

	// This function takes about 0.9 seconds to run
	// this is the wave that the note gets appended to. The note contains the async ad channel value and info
	variable i, numEntries, rawChannelValue, gain, deviceChannelOffset
	string setvarTitle, setvarGain, title

	// Create the measurement wave that will hold the measurement values
	WAVE asyncMeasurementWave = GetAsyncMeasurementWave(panelTitle)
	asyncMeasurementWave[0][] = NaN

	WAVE asyncChannelState = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_ASYNC)
	deviceChannelOffset = ITC_CalculateDevChannelOffset(panelTitle)

	numEntries = DimSize(asyncChannelState, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!asyncChannelState[i])
			continue
		endif

		// Async channels start at channel 16 on ITC 1600, needs to be a diff value constant for ITC18
		rawChannelValue = ITC_SingleADReading(i + deviceChannelOffset, panelTitle)

		sprintf setvarTitle, "SetVar_Async_Title_%02d", i
		sprintf setvarGain,  "SetVar_AsyncAD_Gain_%02d", i

		title = GetSetVariableString(panelTitle, setvarTitle)
		gain  = GetSetVariable(panelTitle, setvarGain)
		print "raw async", rawChannelValue
		// put the measurement value into the async settings wave for creation of wave notes
		asyncMeasurementWave[0][i] = rawChannelValue / gain // put the measurement value into the async settings wave for creation of wave notes
		ITC_SupportSystemAlarm(i, asyncMeasurementWave[0][i], title, panelTitle)
	endfor
End

//======================================================================================
Function ITC_SupportSystemAlarm(Channel, Measurement, MeasurementTitle, panelTitle)
	variable Channel, Measurement
	string MeasurementTitle, panelTitle

	String CheckAlarm, SetVarTitle, SetVarMin, SetVarMax, Title
	variable ParamMin, ParamMax

	if(channel < 10)
		CheckAlarm = "check_Async_Alarm_0" + num2str(channel)
		SetVarMin = "setvar_Async_min_0" + num2str(channel)
		SetVarMax = "setvar_Async_max_0" + num2str(channel)
	else
		CheckAlarm = "check_Async_Alarm_" + num2str(channel)
		SetVarMin = "setvar_Async_min_" + num2str(channel)
		SetVarMax = "setvar_Async_max_" + num2str(channel)
	endif

	ControlInfo /W = $panelTitle $CheckAlarm
	if(v_value == 1)
		ControlInfo /W = $panelTitle $SetVarMin
		ParamMin = v_value
		ControlInfo /W = $panelTitle $SetVarMax
		ParamMax = v_value
		print measurement
		if(Measurement >= ParamMax || Measurement <= ParamMin)
			beep
			print time() + " !!!!!!!!!!!!! " + MeasurementTitle + " has exceeded max/min settings" + " !!!!!!!!!!!!!"
			beep
		endif
	endif
End

/// @brief Sets active DA channels to Zero - used after TP MD
Function ITC_ZeroITCOnActiveChan(panelTitle)
	string panelTitle // function operates on active device - does not check to see if a device is open.

	string cmd
	variable i
	WAVE statusDA = DC_ControlStatusWave(panelTitle, CHANNEL_TYPE_DAC)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		if(statusDA[i])
			sprintf cmd, "ITCSetDAC /z = 0 %d, 0" i
			ExecuteITCOperation(cmd)
		endif
	endfor
End
