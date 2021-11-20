#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_BWO
#endif

/// @file MIES_Blowout.ipf
/// @brief __BWO__ Automates amplifier configuration and acquisition of the sweep used to measure drift in the zero calibration of the amplifer.

static Constant BWO_MAX_RESISTANCE = 10 // MΩ
static Constant BWO_INIT_PRESSURE = 5 // psi
static Constant BWO_PRESSURE_INCREMENT = 1 // psi
static Constant TWO_SECONDS = 120 // ticks in two seconds
static Constant FIFTEEN_SECONDS = 900 // ticks in fifteen seconds

/// @brief Initiates blowout protocol on single locked device
Function BWO_SelectDevice()

	string device
	string lockedDeviceList = GetListOfLockedDevices()
	variable noOfLockedDevices = ItemsInList(lockedDeviceList)
	NVAR interactiveMode = $GetInteractiveMode()

	If(noOfLockedDevices == 0)
		return NaN
	elseif(noOfLockedDevices == 1)
	   if(interactiveMode)
	     DoAlert 1, "Proceed with automated blowout routine?"
	     if(V_flag != 1)
	        return NaN
	     endif
	   endif

   		BWO_Go(StringFromList(0, lockedDeviceList))
	elseif(noOfLockedDevices > 1)
		print "Blowout is not available for multiple locked devices"
		return Nan
	endif
End

/// @brief Executes blowout protocol
Function BWO_Go(device)
	string device

	If(!BWO_CheckGlobalSettings(device))
		return NaN
	endif

	//configure MIES for blowout
	BWO_SetMIESSettings(device)
	BWO_AllMCCCtrlsOFF(device)
	// start the TP
	BWO_ConfigureTP(device)
	// try clearing all pipettes at once
	BWO_InitParaPipetteClear(device)
	// check if pipettes are clear, if not try to clear clogged pipettes individually
	BWO_CheckAndClearPipettes(device)
	// acquire blowout sweep
	BWO_AcquireSweep(device)

	SaveExperiment
End

/// @brief Checks that MIES is correctly configured for automated blowout protocol
///
/// @returns one if settings are valid, zero otherwise
static Function BWO_CheckGlobalSettings(device)
	string device

	string stimSetList
	variable PressureModeStorageCol, Connected, i
	WAVE pressure = P_GetPressureDataWaveRef(device)

	// check that data acquisition is not running
	NVAR dataAcqRunMode = $GetDataAcqRunMode(device)
	if(dataAcqRunMode != DAQ_NOT_RUNNING)
		printf "Please terminate ongoing data acquisition on %s \r" device
		return 0
	endif
	// check that blowout protocol exists
	stimSetList = ST_GetStimsetList(channelType = CHANNEL_TYPE_DAC, searchString = "MIES_Blowout*")
	If(itemsinlist(stimSetList) ==  0)
		print "Blowout stimulus set does not exist. Please create a MIES_Blowout stimulus set using the waveBuilder"
		return 0
	endif
	// check that background TP is on
	if(!DAG_GetNumericalValue(device, "Check_Settings_BkgTP"))
		print "Background TP must be enabled"
		return 0
	endif

	// check that pressure is set to Atomospheric on all headstages
	PressureModeStorageCol = findDimLabel(pressure, COLS, "Approach_Seal_BrkIn_Clear")
	wavestats/Q/RMD=[][PressureModeStorageCol,PressureModeStorageCol] pressure
	if(V_max > PRESSURE_METHOD_ATM)
		print "Turn off pressure on all headstages"
		return 0
	endif

	for(i=0; i < NUM_HEADSTAGES; i += 1)
		connected = min(connected, AI_SelectMultiClamp(device, i))
	endfor

	if(connected != AMPLIFIER_CONNECTION_SUCCESS)
		print "No amplifiers are configured. Cannot proceed with automated blowout protocol"
		return 0
	endif

	return 1
End

/// @brief Initates test pulse
static Function BWO_ConfigureTP(device)
	string device

	if(!TP_CheckIfTestpulseIsRunning(device))
		PGC_SetAndActivateControl(device,"StartTestPulseButton", switchTab = 1)
	endif

	DoUpdate/W=$SCOPE_GetPanel(device)
End

/// @brief Configures data acquisition settings for blowout
static Function BWO_SetMIESSettings(device)
	string device

	// turn on insert TP
	PGC_SetAndActivateControl(device, "Check_Settings_InsertTP", val = 1)
	// select blowout stim set
	PGC_SetAndActivateControl(device, GetPanelControl(CHANNEL_INDEX_ALL_I_CLAMP, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "MIES_Blowout*", switchTab = 1)
	PGC_SetAndActivateControl(device, GetPanelControl(CHANNEL_INDEX_ALL, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE), str = "MIES_Blowout*", switchTab = 1)
	// set repeatsets to 1
	PGC_SetAndActivateControl(device, "SetVar_DataAcq_SetRepeats", val = 1)
	// set delays
	PGC_SetAndActivateControl(device, "setvar_DataAcq_OnsetDelayUser", val = 0)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_TerminationDelay", val = 0)
	// turn off dDAQ modes
	PGC_SetAndActivateControl(device, "Check_DataAcq1_DistribDaq", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(device, "Check_DataAcq1_dDAQOptOv", val = CHECKBOX_UNSELECTED)
End

/// @brief Applies a pressure pulse to all headstages with valid pressure settings
static Function BWO_InitParaPipetteClear(device)
	string device

	variable 	startTime
	STRUCT BackgroundStruct s
	s.wmbs.name = "TestPulseMD"

	PGC_SetAndActivateControl(device, "check_DataAcq_ManPressureAll", val = CHECKBOX_SELECTED, switchTab = 1)
	PGC_SetAndActivateControl(device, "setvar_DataAcq_SSPressure", val = BWO_INIT_PRESSURE) // set the initial manual pressure
	PGC_SetAndActivateControl(device, "button_DataAcq_SSSetPressureMan")// turn on manual pressure
	startTime = ticks
	Do
		TPM_BkrdTPFuncMD(s)
		DoUpdate/W=$SCOPE_GetPanel(device)
	While(ticks - startTime < 90 ) // wait for 1.5 seconds but update oscilloscope
	PGC_SetAndActivateControl(device, "button_DataAcq_SSSetPressureMan") // turn OFF manual pressure
	PGC_SetAndActivateControl(device, "check_DataAcq_ManPressureAll", val = CHECKBOX_UNSELECTED) // turn off apply pressure mode to all HS
End

/// @brief Attempts to clear pipettes that have a resistance larger than MAX_RESISTANCE
static Function BWO_CheckAndClearPipettes(device)
	string device

	variable i, j, col, initPressure, startTime, pressurePulseStartTime, pressurePulseTime

	wave TPResults = GetTPResults(device)
	WAVE pressure = P_GetPressureDataWaveRef(device)

	STRUCT BackgroundStruct s
	s.wmbs.name = "TestPulseMD"

	make/FREE/n = (NUM_HEADSTAGES) PressureTracking = BWO_INIT_PRESSURE + BWO_PRESSURE_INCREMENT

	for(i = 0; i < NUM_HEADSTAGES; i += 1)


		if(!P_ValidatePressureSetHeadstage(device, i) || TPResults[%ResistanceSteadyState][i] < BWO_MAX_RESISTANCE)
			continue
		endif

		PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = i)
		PGC_SetAndActivateControl(device, "button_DataAcq_SSSetPressureMan") // turn on manual pressure

		TPM_BkrdTPFuncMD(s)
		DoUpdate/W=$SCOPE_GetPanel(device)
		startTime = ticks
		PGC_SetAndActivateControl(device, "setvar_DataAcq_SSPressure", val = PressureTracking[i])
		pressurePulseStartTime = ticks
		PressureTracking[i] += BWO_PRESSURE_INCREMENT

		do
			pressurePulseTime = ticks - pressurePulseStartTime
			if(pressurePulseTime >= TWO_SECONDS)
				PGC_SetAndActivateControl(device, "setvar_DataAcq_SSPressure", val = PressureTracking[i])
				if(PressureTracking[i] <= MAX_REGULATOR_PRESSURE) // only increase pressure if less than or equal to max pressure
					PressureTracking[i] += 1
				endif
				PressureTracking[i] = min(PressureTracking[i], MAX_REGULATOR_PRESSURE)
				pressurePulseStartTime = ticks
			endif
			TPM_BkrdTPFuncMD(s)
			DoUpdate/W=$SCOPE_GetPanel(device)
		while(TPResults[%ResistanceSteadyState][i] > BWO_MAX_RESISTANCE && ticks - startTime < FIFTEEN_SECONDS) // continue if the pipette is not clear AND the timeout hasn't been exceeded

		PGC_SetAndActivateControl(device, "button_DataAcq_SSSetPressureMan") // turn off manual pressure
		PGC_SetAndActivateControl(device, "setvar_DataAcq_SSPressure", val = 0)

		if(TPResults[%ResistanceSteadyState][i] > BWO_MAX_RESISTANCE)
			printf "Unable to clear pipette on headstage %d with %g psi\r" i, PressureTracking[i]
		endif
	endfor
End

/// @brief Turns OFF all relevant MCC amplifier controls in I- and V-clamp modes
static Function BWO_AllMCCCtrlsOFF(device)
	string device

	PGC_SetAndActivateControl(device, "Check_DataAcq_SendToAllAmp", val = CHECKBOX_SELECTED)
	BWO_SetClampModeAll(device, I_CLAMP_MODE)
	DoUpdate/W=$device
	BWO_DisableMCCIClampCtrls(device)
	BWO_SetClampModeAll(device, V_CLAMP_MODE)
	BWO_DisableMCCVClampCtrls(device)
	PGC_SetAndActivateControl(device, "Check_DataAcq_SendToAllAmp", val = CHECKBOX_UNSELECTED)
End

/// @brief Wrapper function for setting the clamp mode on all headstages (T̶h̶o̶m̶a̶s̶ ̶p̶r̶o̶b̶a̶b̶l̶y̶ ̶w̶o̶n̶'̶t̶ ̶l̶i̶k̶e̶ ̶i̶t̶  He liked it!! :/ ).
static Function BWO_SetClampModeAll(device, mode)
	string device
	variable mode

	switch(mode)
		case V_CLAMP_MODE:
			PGC_SetAndActivateControl(device, "Radio_ClampMode_AllVClamp", val = CHECKBOX_SELECTED)
			break
		case I_CLAMP_MODE:
			PGC_SetAndActivateControl(device, "Radio_ClampMode_AllIClamp", val = CHECKBOX_SELECTED)
			break
		case I_EQUAL_ZERO_MODE:
			PGC_SetAndActivateControl(device, "Radio_ClampMode_AllIZero", val = CHECKBOX_SELECTED)
			break
		default:
			ASSERT(0, "unhandled case")
	endswitch
End

/// @brief Turns OFF I-clamp controls
static Function BWO_DisableMCCIClampCtrls(device)
	string device

	PGC_SetAndActivateControl(device, "check_DatAcq_HoldEnable", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(device, "check_DatAcq_BBEnable", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(device, "check_DatAcq_CNEnable", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(device, "check_DataAcq_AutoBias", val = CHECKBOX_UNSELECTED)
End

/// @brief Turns OFF V-clamp controls
static Function BWO_DisableMCCVClampCtrls(device)
	string device

	PGC_SetAndActivateControl(device, "check_DatAcq_HoldEnableVC", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(device, "check_DatAcq_WholeCellEnable", val = CHECKBOX_UNSELECTED)
	PGC_SetAndActivateControl(device, "check_DatAcq_RsCompEnable", val = CHECKBOX_UNSELECTED)
End

/// @brief Acquires blowout sweep
static Function BWO_AcquireSweep(device)
	string device

	PGC_SetAndActivateControl(device, "Radio_ClampMode_AllIClamp", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(device, "DataAcquireButton")
End
