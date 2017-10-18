
/// @todo rework logic and make static
Function ITC_StartBackgroundTestPulse(panelTitle)
	string panelTitle

	CtrlNamedBackground TestPulse, period = 5, proc = ITC_TestPulseFunc
	CtrlNamedBackground TestPulse, start
End

Function ITC_StopTestPulseSingleDevice(panelTitle)
	string panelTitle

	variable headstage

	CtrlNamedBackground TestPulse, stop

	TP_Teardown(panelTitle)
End

///@brief Background execution function for the test pulse data acquisition
Function ITC_TestPulseFunc(s)
	STRUCT BackgroundStruct &s

	SVAR panelTitleG = $GetPanelTitleGlobal()
	// create a copy as panelTitleG is killed in ITC_StopTestPulseSingleDevice
	// but we still need it afterwards
	string panelTitle = panelTitleG

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	if(s.wmbs.started)
		s.wmbs.started = 0
		s.count  = 0
	else
		s.count += 1
	endif

	HW_SelectDevice(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)
	HW_ITC_ResetFifo(ITCDeviceIDGlobal)
	HW_StartAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)

	do
		// nothing
	while (HW_ITC_MoreData(ITCDeviceIDGlobal))

	HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, prepareForDAQ=1)
	SCOPE_UpdateOscilloscopeData(panelTitle, TEST_PULSE_MODE)
	TP_Delta(panelTitle)

	if(mod(s.count, TEST_PULSE_LIVE_UPDATE_INTERVAL) == 0)
		SCOPE_UpdateGraph(panelTitle)
	endif

	if(RA_IsFirstSweep(panelTitle))
		if(GetKeyState(0) & ESCAPE_KEY)
			beep
			ITC_StopTestPulseSingleDevice(panelTitle)
		endif
	endif

	return 0
End

/// @brief Start a single device test pulse, either in background
/// or in foreground mode depending on the settings
Function TP_StartTestPulseSingleDevice(panelTitle)
	string panelTitle

	AbortOnValue DAP_CheckSettings(panelTitle, TEST_PULSE_MODE),1

	ITC_StopOngoingDAQ(panelTitle)

	// stop early as "TP after DAQ" might be already running
	if(TP_CheckIfTestpulseIsRunning(panelTitle))
		return NaN
	endif

	try
		if(GetCheckBoxState(panelTitle, "Check_Settings_BkgTP"))

			TP_Setup(panelTitle, TEST_PULSE_BG_SINGLE_DEVICE)

			ITC_StartBackgroundTestPulse(panelTitle)

			P_InitBeforeTP(panelTitle)
		else
			TP_Setup(panelTitle, TEST_PULSE_FG_SINGLE_DEVICE)
			TP_StartTestPulseForeground(panelTitle)
			TP_Teardown(panelTitle)
		endif
	catch
		TP_Teardown(panelTitle)
		return NaN
	endtry
End

/// @brief Low level implementation for starting the single device foreground test pulse
static Function TP_StartTestPulseForeground(panelTitle)
	string panelTitle

	variable i
	string oscilloscopeSubwindow

	oscilloscopeSubwindow = SCOPE_GetGraph(panelTitle)
	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	do
		DoXOPIdle
		HW_ITC_ResetFifo(ITCDeviceIDGlobal)
		HW_StartAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, flags=HARDWARE_ABORT_ON_ERROR)

		do
			// nothing
		while (HW_ITC_MoreData(ITCDeviceIDGlobal))

		HW_StopAcq(HARDWARE_ITC_DAC, ITCDeviceIDGlobal, prepareForDAQ=1)
		SCOPE_UpdateOscilloscopeData(panelTitle, TEST_PULSE_MODE)
		TP_Delta(panelTitle)

		if(mod(i, TEST_PULSE_LIVE_UPDATE_INTERVAL) == 0)
			SCOPE_UpdateGraph(panelTitle)
		endif

		DoUpdate/W=$oscilloscopeSubwindow

		i += 1
	while(!(GetKeyState(0) & ESCAPE_KEY))
END
