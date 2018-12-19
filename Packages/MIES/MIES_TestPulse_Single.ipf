#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_TP_SD
#endif

/// @file MIES_TestPulse_Multi.ipf
/// @brief __TPM__ Multi device background test pulse functionality

Function TPS_StartBackgroundTestPulse(panelTitle)
	string panelTitle

	CtrlNamedBackground $TASKNAME_TP, start
End

Function TPS_StopTestPulseSingleDevice(panelTitle)
	string panelTitle

	CtrlNamedBackground $TASKNAME_TP, stop
	TP_Teardown(panelTitle)
End

/// @brief Background TP Single Device
///
/// @ingroup BackgroundFunctions
Function TPS_TestPulseFunc(s)
	STRUCT BackgroundStruct &s

	variable readTimeStamp
	SVAR panelTitleG = $GetPanelTitleGlobal()
	// create a copy as panelTitleG is killed in TPS_StopTestPulseSingleDevice
	// but we still need it afterwards
	string panelTitle = panelTitleG

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	if(s.wmbs.started)
		s.wmbs.started = 0
		s.count  = 0
	else
		s.count += 1
	endif

	HW_ITC_ResetFifo(ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_StartAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	do
		// nothing
	while (HW_ITC_MoreData(ITCDeviceIDGlobal))

	readTimeStamp = ticks * TICKS_TO_SECONDS

	HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, prepareForDAQ=1)
	SCOPE_UpdateOscilloscopeData(panelTitle, TEST_PULSE_MODE)

	SCOPE_UpdateGraph(panelTitle)

	if(GetKeyState(0) & ESCAPE_KEY)
		DQ_StopOngoingDAQ(panelTitle)
		return 1
	endif

	return 0
End

/// @brief Start a single device test pulse, either in background
/// or in foreground mode depending on the settings
Function TPS_StartTestPulseSingleDevice(panelTitle)
	string panelTitle

	AbortOnValue DAP_CheckSettings(panelTitle, TEST_PULSE_MODE),1

	DQ_StopOngoingDAQ(panelTitle)

	// stop early as "TP after DAQ" might be already running
	if(TP_CheckIfTestpulseIsRunning(panelTitle))
		return NaN
	endif

	try
		if(DAG_GetNumericalValue(panelTitle, "Check_Settings_BkgTP"))

			TP_Setup(panelTitle, TEST_PULSE_BG_SINGLE_DEVICE)

			TPS_StartBackgroundTestPulse(panelTitle)

			P_InitBeforeTP(panelTitle)
		else
			TP_Setup(panelTitle, TEST_PULSE_FG_SINGLE_DEVICE)
			TPS_StartTestPulseForeground(panelTitle)
			TP_Teardown(panelTitle)
		endif
	catch
		TP_Teardown(panelTitle)
		return NaN
	endtry
End

/// @brief Start the single device foreground test pulse
///
/// @param panelTitle  device
/// @param elapsedTime [defaults to infinity] allow to run the testpulse for the given amount
///                                           of seconds only.
/// @return zero if time elapsed, one if the Testpulse was manually stopped
Function TPS_StartTestPulseForeground(panelTitle, [elapsedTime])
	string panelTitle
	variable elapsedTime

	variable i, refTime, timeLeft, readTimeStamp
	string oscilloscopeSubwindow

	if(ParamIsDefault(elapsedTime))
		refTime = NaN
	else
		refTime = RelativeNowHighPrec()
	endif

	oscilloscopeSubwindow = SCOPE_GetGraph(panelTitle)
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	do
		DoXOPIdle
		HW_ITC_ResetFifo(ITCDeviceIDGlobal)
		HW_StartAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)

		do
			// nothing
		while (HW_ITC_MoreData(ITCDeviceIDGlobal))

		readTimeStamp = ticks * TICKS_TO_SECONDS

		HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, prepareForDAQ=1)
		SCOPE_UpdateOscilloscopeData(panelTitle, TEST_PULSE_MODE)

		SCOPE_UpdateGraph(panelTitle)

		if(IsFinite(refTime))
			timeLeft = max((refTime + elapsedTime) - RelativeNowHighPrec(), 0)
			SetValDisplay(panelTitle, "valdisp_DataAcq_ITICountdown", var = timeLeft)

			DoUpdate/W=$oscilloscopeSubwindow

			if(timeLeft == 0)
				return 0
			endif
		else
			DoUpdate/W=$oscilloscopeSubwindow
		endif

		i += 1
	while(!(GetKeyState(0) & ESCAPE_KEY))

	return 1
End
