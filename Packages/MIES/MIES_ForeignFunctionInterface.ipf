#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3          // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma DefaultTab       = {3, 20, 4} // Set default tab width in Igor Pro 9 and later

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_FFI
#endif // AUTOMATED_TESTING

/// @file MIES_ForeignFunctionInterface.ipf
/// @brief __FFI__ ACQ4/ZeroMQ accessible functions

/// @brief Function to return Peak Resistance, Steady State Resistance to ACQ4 (Neurophysiology Acquisition and Analysis System.
/// See http://acq4.org/ for more details)
///
/// The function will pull the values (PeakResistance, SteadyStateResistance, and TimeStamp) out of
/// the TP storage wave and put them in a 3x8 wave, in a designated location where ACQ4 can then find them
Function/WAVE FFI_ReturnTPValues()

	string   lockedDevList
	variable noLockedDevs
	variable n
	string   currentPanel
	variable tpCycleCount

	//Get the active device
	// get the da_ephys panel names
	lockedDevList = GetListOfLockedDevices()
	noLockedDevs  = ItemsInList(lockedDevList)

	// Create the wave to hold values that will be queried by the ACQ4 process
	WAVE acqStorageWave = GetAcqTPStorage()

	// put the list of locked devices in the wave note
	NOTE/K acqStorageWave, "LockedDevToWvLayerMapping:" + lockedDevList

	for(n = 0; n < noLockedDevs; n += 1)
		currentPanel = StringFromList(n, lockedDevList)

		// Get the tpStorageWave
		WAVE tpStorageWave = GetTPStorage(currentPanel)

		//we want the last row of the column in question
		tpCycleCount = GetNumberFromWaveNote(tpStorageWave, NOTE_INDEX) // used to pull most recent values from TP

		//make sure we get a valid TPCycleCount value
		if(TPCycleCount == 0)
			return $""
		endif

		acqStorageWave[%PeakResistance][][n]        = tpStorageWave[tpCycleCount - 1][q][%PeakResistance]
		acqStorageWave[%SteadyStateResistance][][n] = tpStorageWave[tpCycleCount - 1][q][%SteadyStateResistance]
		acqStorageWave[%TimeStamp][][n]             = tpStorageWave[tpCycleCount - 1][q][%TimeStamp]
	endfor

	return acqStorageWave
End

/// @brief Return a text wave with all available message filters for
/// Publisher/Subscriber ZeroMQ sockets
///
/// See also @ref ZeroMQMessageFilters.
///
/// Description of all messages:
///
/// \rst
///
/// ============================================ ==================================================== =============================================
///  Name                                         Description                                          Publish function
/// ============================================ ==================================================== =============================================
///  :cpp:var:ZeroMQ_HEARTBEAT                    Every 5s for alive check                             None
///  :cpp:var:PRESSURE_STATE_FILTER               Every pressure method change                         :cpp:func:PUB_PressureMethodChange
///  :cpp:var:PRESSURE_SEALED_FILTER              Pressure seal reached                                :cpp:func:PUB_PressureSealedState
///  :cpp:var:PRESSURE_BREAKIN_FILTER             Pressure breakin                                     :cpp:func:PUB_PressureBreakin
///  :cpp:var:AUTO_TP_FILTER                      Auto TP has finished                                 :cpp:func:PUB_AutoTPResult
///  :cpp:var:AMPLIFIER_CLAMP_MODE_FILTER         Clamp mode has changed                               :cpp:func:PUB_ClampModeChange
///  :cpp:var:AMPLIFIER_AUTO_BRIDGE_BALANCE       Amplifier auto bridge balance was activated          :cpp:func:PUB_AutoBridgeBalance
///  :cpp:var:ANALYSIS_FUNCTION_PB                Pipette in bath analysis function has finished       :cpp:func:PUB_PipetteInBath
///  :cpp:var:ANALYSIS_FUNCTION_SE                Seal evaluation analysis function has finished       :cpp:func:PUB_SealEvaluation
///  :cpp:var:ANALYSIS_FUNCTION_VM                True resting memb. potential function is finished    :cpp:func:PUB_TrueRestingMembranePotential
///  :cpp:var:DAQ_TP_STATE_CHANGE_FILTER          Data acquisition/Test pulse started or stopped       :cpp:func:PUB_DAQStateChange
///  :cpp:var:ANALYSIS_FUNCTION_AR                Access resistance smoke ana. function has finished   :cpp:func:PUB_AccessResistanceSmoke
///  :cpp:var:ZMQ_FILTER_TPRESULT_NOW             TP evaluation result (all TPs)                       :cpp:func:PUB_TPResult
///  :cpp:var:ZMQ_FILTER_TPRESULT_1s              TP evaluation result (every 1s)                      :cpp:func:PUB_TPResult
///  :cpp:var:ZMQ_FILTER_TPRESULT_5s              TP evaluation result (every 5s)                      :cpp:func:PUB_TPResult
///  :cpp:var:ZMQ_FILTER_TPRESULT_10s             TP evaluation result (every 10s)                     :cpp:func:PUB_TPResult
///  :cpp:var:ZMQ_FILTER_TPRESULT_NOW_WITH_DATA   TP evaluation result with AD data (all TPs)          :cpp:func:PUB_TPResult
///  :cpp:var:CONFIG_FINISHED_FILTER              JSON configuration for panel has finished            :cpp:func:PUB_ConfigurationFinished
///  :cpp:var:AMPLIFIER_SET_VALUE                 Amplifier setting was changed through MIES           :cpp:func:PUB_AmplifierSettingChange
///  :cpp:var:TESTPULSE_SET_VALUE_FILTER          Testpulse setting change                             :cpp:func:PUB_TPSettingChange
/// ============================================ ==================================================== =============================================
///
/// \endrst
///
Function/WAVE FFI_GetAvailableMessageFilters()

	Make/FREE/T wv = {ZeroMQ_HEARTBEAT, PRESSURE_STATE_FILTER, PRESSURE_SEALED_FILTER,                    \
	                  PRESSURE_BREAKIN_FILTER, AUTO_TP_FILTER, AMPLIFIER_CLAMP_MODE_FILTER,               \
	                  AMPLIFIER_AUTO_BRIDGE_BALANCE, ANALYSIS_FUNCTION_PB, ANALYSIS_FUNCTION_SE,          \
	                  ANALYSIS_FUNCTION_VM, DAQ_TP_STATE_CHANGE_FILTER,                                   \
	                  ANALYSIS_FUNCTION_AR, ZMQ_FILTER_TPRESULT_NOW, ZMQ_FILTER_TPRESULT_1S,              \
	                  ZMQ_FILTER_TPRESULT_5S, ZMQ_FILTER_TPRESULT_10S, ZMQ_FILTER_TPRESULT_NOW_WITH_DATA, \
	                  CONFIG_FINISHED_FILTER, AMPLIFIER_SET_VALUE, TESTPULSE_SET_VALUE_FILTER}

	Note/K wv, "Heartbeat is sent every 5 seconds."

	return wv
End

/// @brief Set the headstage/cell electrode name
Function FFI_SetCellElectrodeName(string device, variable headstage, string name)

	DAP_AbortIfUnlocked(device)
	ASSERT(IsValidHeadstage(headstage), "Invalid headstage index")
	ASSERT(H5_IsValidIdentifier(name), "Name of the electrode/headstage needs to be a valid HDF5 identifier")

	WAVE/T cellElectrodeNames = GetCellElectrodeNames(device)

	cellElectrodeNames[headstage] = name
End

/// @brief Query logbook entries from devices
///
/// This allows to query labnotebook/results entries from associated channels.
///
/// @param device          Name of the hardware device panel, @sa GetLockedDevices()
/// @param logbookType     One of #LBT_LABNOTEBOOK or #LBT_RESULTS
/// @param sweepNo         Sweep number
/// @param setting         Name of the entry
/// @param entrySourceType One of #DATA_ACQUISITION_MODE/#UNKNOWN_MODE/#TEST_PULSE_MODE
///
/// @return Numerical/Textual wave with #LABNOTEBOOK_LAYER_COUNT rows or a null wave reference if nothing could be found
Function/WAVE FFI_QueryLogbook(string device, variable logbookType, variable sweepNo, string setting, variable entrySourceType)

	ASSERT(logbookType != LBT_TPSTORAGE, "Invalid logbook type")

	WAVE/T numericalValues = GetLogbookWaves(logbookType, LBN_NUMERICAL_VALUES, device = device)

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, setting, entrySourceType)

	if(WaveExists(settings))
		return settings
	endif

	WAVE/T textualValues = GetLogbookWaves(logbookType, LBN_TEXTUAL_VALUES, device = device)

	WAVE/Z settings = GetLastSetting(textualValues, sweepNo, setting, entrySourceType)

	return settings
End

/// @brief Return all unique logbook entries from devices
///
/// @param device      Name of the hardware device panel, @sa GetLockedDevices()
/// @param logbookType One of #LBT_LABNOTEBOOK or #LBT_RESULTS
/// @param setting     Name of the entry
///
/// @return Numerical/Textual 1D wave or a null wave reference if nothing could be found
Function/WAVE FFI_QueryLogbookUniqueSetting(string device, variable logbookType, string setting)

	ASSERT(logbookType != LBT_TPSTORAGE, "Invalid logbook type")

	WAVE/T numericalValues = GetLogbookWaves(logbookType, LBN_NUMERICAL_VALUES, device = device)

	WAVE/Z settings = GetUniqueSettings(numericalValues, setting)

	if(WaveExists(settings))
		return settings
	endif

	WAVE/T textualValues = GetLogbookWaves(logbookType, LBN_TEXTUAL_VALUES, device = device)

	WAVE/Z settings = GetUniqueSettings(textualValues, setting)

	return settings
End

/// @brief Save the given permanent Igor Pro `datafolder` in the HDF5 format into `filepath`
Function FFI_SaveDataFolderToHDF5(string filepath, string datafolder)

	return FFI_SaveDataFolderToHDF5Impl(filepath, {datafolder})
End

static Function FFI_SaveDataFolderToHDF5Impl(string filepath, WAVE/T datafolders)

	variable ref = NaN
	variable groupID
	string entry, cleanName

	ASSERT(!FileExists(filepath), "filepath points to an existing file")
	ASSERT(!FolderExists(filepath), "filepath points to an existing folder and is missing the filename")

	try
		HDF5CreateFile ref as filepath; AbortOnRTE
		for(entry : datafolders)
			DFREF dfr = $entry
			ASSERT(DataFolderExistsDFR(dfr), "datafolder " + entry + " does not point to an existing datafolder")
			cleanName = ReplaceString(":", RemovePrefix(entry, start = "root:"), "/")
			H5_CreateGroupsRecursively(ref, cleanName)
			groupID = H5_OpenGroup(ref, cleanName)
			HDf5SaveGroup/R/IGOR=(-1)/OPTS=(2^0)/COMP={1000, 3, 0} dfr, groupID, "."; AbortOnRTE
			HDF5CloseGroup groupId; AbortOnRTE
		endfor
	catch
		HDF5DumpErrors/CLR=1
		// do nothing
	endtry

	HDF5CloseFile/Z ref
End

/// @brief Return the titles of all sweep browser windows
Function/WAVE FFI_GetSweepBrowserTitles()

	WAVE wv = ListToTextWave(AB_GetSweepBrowserTitles(), ";")

	if(DimSize(wv, ROWS) == 0)
		return $""
	endif

	return wv
End

/// @brief Save the psx data of the sweepbrowser with title `wintTitle` in the HDF5 format into `filepath`
Function FFI_SavePSXDataFolderToHDF5(string filepath, string winTitle)

	string sbWin, folderList

	sbWin = AB_GetSweepBrowserWindowFromTitle(winTitle)

	DFREF dfr = SFH_GetWorkingDF(sbWin)

	folderList = GetListOfObjects(dfr, "^psx[0-9]*$", typeFlag = COUNTOBJECTS_DATAFOLDER, fullPath = 1)
	ASSERT(!IsEmpty(folderList), "Could find any psx folders")
	WAVE/T folders = ListToTextWave(folderList, ";")

	return FFI_SaveDataFolderToHDF5Impl(filepath, folders)
End

// ---------- TP Helpers ----------

/// @brief Return 1 if the device can be selected (exists/available), 0 otherwise
///
/// @param[in] device   Device title, e.g. "ITC1600_Dev_0"
/// @returns            1 if selectable, 0 otherwise
static Function FFI_TP_DeviceSelectable(string device)

	variable hardwareType = GetHardwareType(device)
	NVAR     deviceID     = $GetDAQDeviceID(device)
	// HW_SelectDevice returns 0 on success; invert to get 1 on success.
	return !HW_SelectDevice(hardwareType, deviceID, flags = HARDWARE_PREVENT_ERROR_MESSAGE)
End

// ---------- TP API wrappers ----------

/// @brief Start the test pulse for a device unless it is already running
///
/// @param[in] device   Device title, e.g. "ITC1600_Dev_0"
/// @returns            0 = started now, 1 = already running (ignored), -1 = device unavailable
Function [variable ret, string errorMsg] FFI_StartTestPulse(string device)

	if(!FFI_TP_DeviceSelectable(device))
		sprintf errorMsg, "Device %s is not available.\r", device
		return [-1, errorMsg]
	endif

	if(TP_CheckIfTestpulseIsRunning(device))
		sprintf errorMsg, "Test pulse already running on %s; start ignored.\r", device
		return [1, errorMsg]
	endif

	TPM_StartTestPulseMultiDevice(device)
	return [0, ""]
End

/// @brief Stop the test pulse for a device unless it is already stopped
///
/// @param[in] device   Device title, e.g. "ITC1600_Dev_0"
/// @returns            0 = stopped now, 1 = already stopped (ignored), -1 = device unavailable
Function [variable ret, string errorMsg] FFI_StopTestPulse(string device)

	if(!FFI_TP_DeviceSelectable(device))
		sprintf errorMsg, "Device %s is not available.\r", device
		return [-1, errorMsg]
	endif

	if(!TP_CheckIfTestpulseIsRunning(device))
		sprintf errorMsg, "Test pulse already stopped on %s; stop ignored.\r", device
		return [1, errorMsg]
	endif

	TPM_StopTestPulseMultiDevice(device)

	return [0, ""]
End

/// @brief Unified API entry point to start or stop the test pulse
///
/// @param[in] device   Device title, e.g. "ITC1600_Dev_0"
/// @param[in] action   1 to start, 0 to stop
/// @returns            Pass-through of API_StartTestPulse()/API_StopTestPulse() return codes
Function [variable ret, string errorMsg] FFI_TestPulseMD(string device, variable action)

	switch(action)
		case 0:
			[ret, errorMsg] = FFI_StopTestPulse(device)
			break
		case 1:
			[ret, errorMsg] = FFI_StartTestPulse(device)
			break
		default:
			FATAL_ERROR("Invalid action. Action != 0 or 1. Action = " + num2istr(action))
	endswitch

	return [ret, errorMsg]
End

Function FFI_TestPulseMDSingleResult(string device, variable action)

	variable ret
	string   errorMsg

	[ret, errorMsg] = FFI_TestPulseMD(device, action)

	return ret
End

// for external callers to set manual pressure
Function DoPressureManual(string device, variable headstage, [variable manualOnOff, variable targetPressure, variable userAccessOnOff])

	// 0) Select the headstage

	if(DAG_GetNumericalValue(device, "slider_DataAcq_ActiveHeadstage") != headStage)
		PGC_SetAndActivateControl(device, "slider_DataAcq_ActiveHeadstage", val = headstage)
	endif

	// 1) Set the requested pressure value on the GUI control
	PGC_SetAndActivateControl(device, "setvar_DataAcq_SSPressure", val = targetPressure)

	// 2) Check the current pressure mode
	variable currentMode = P_GetPressureMethod(device, headstage)

	// 3) If we want manual mode ON...
	if(manualOnOff == 1)
		// ...and we are NOT in manual mode yet, switch to manual
		if(currentMode != PRESSURE_METHOD_MANUAL)
			P_SetManual(device, "button_DataAcq_SSSetPressureMan")
		endif
	else
		// If we want manual mode OFF...
		// ...and we ARE currently in manual mode, switch to atmospheric (or the "off" state)
		if(currentMode == PRESSURE_METHOD_MANUAL)
			P_SetManual(device, "button_DataAcq_SSSetPressureMan")
		endif
	endif

End

// -----------------------------
// FFI: GetPressureWithOptionToSetSourceAndPressure
// -----------------------------
/// @brief FFI entry: set/rout pressure per 'requestedSource' and/or set regulator setpoint.
/// @param device          		MIES device name
/// @param headstage       		target headstage index
/// @param requestedSource		"atmosphere" | "regulator" | "user" | "default" | ""
/// @param requestedPressure 	regulator setpoint (psi; <9.9, >-9.9) | NaN
/// @return regulatorPressure, pipettePressure

Function [string source, variable regulatorPressure] FFI_GetWithOptionToSetPressure(string device, variable headstage, string requestedSource, variable requestedPressure)

	// ---- Safety & validation ----
	DAP_AbortIfUnlocked(device)
	ASSERT(IsValidHeadstage(headstage), "Invalid headstage (0–7)")

	// Normalize inputs
	string src = TrimString(requestedSource)
	// hoops to jump through because xop toolkit used for zeroMQ XOP does not support optional parameters
	variable hasSetpoint = (numtype(requestedPressure) == 0) // finite number?
	if(numtype(requestedPressure) == 1) // +/-INF -> treat as "no change"
		hasSetpoint = 0
	endif

	// If a pressure pulse is still running, wait it out. Max pressure pulse time is 300 ms.
	FFI_WaitForIdle(device, headstage)

	// ---- Apply according to contract ----
	// strswitch is case-insensitive in Igor
	strswitch(src)

		case "atmosphere":
			// Route to atmosphere
			if(hasSetpoint)
				P_SetPressureMode(device, headstage, PRESSURE_METHOD_ATM)
				PGC_SetAndActivateControl(Device, "setvar_DataAcq_SSPressure", val = requestedPressure)
			else
				P_SetPressureMode(device, headstage, PRESSURE_METHOD_ATM)
			endif
			P_PressureControl(device)
			PGC_SetAndActivateControl(device, "check_DataAcq_Pressure_User", val = CHECKBOX_UNSELECTED)
			break

		case "regulator":
			// Enter/keep manual; set setpoint if provided
			if(hasSetpoint)
				P_SetPressureMode(device, headstage, PRESSURE_METHOD_MANUAL, pressure = requestedPressure)
			else
				P_SetPressureMode(device, headstage, PRESSURE_METHOD_MANUAL)
			endif
			P_PressureControl(device)
			PGC_SetAndActivateControl(device, "check_DataAcq_Pressure_User", val = CHECKBOX_UNSELECTED)

			break

		case "user":
			// Optionally update regulator setpoint first (even though pipette will route to user)
			if(hasSetpoint)
				P_SetPressureMode(device, headstage, PRESSURE_METHOD_MANUAL, pressure = requestedPressure)
				P_PressureControl(device)
			endif
			// Now route valves to the user line
			PGC_SetAndActivateControl(device, "check_DataAcq_Pressure_User", val = CHECKBOX_SELECTED)
			// Ensure valves reflect current mode/access explicitly
			P_SetPressureValves(device, headstage,                                                        \
			                    P_GetUserAccess(device, headstage, P_GetPressureMethod(device, headstage)))
			break

		case "default": // fallthrough
		case "":
			// No routing change; set manual setpoint only if provided
			if(hasSetpoint)
				PGC_SetAndActivateControl(Device, "setvar_DataAcq_SSPressure", val = requestedPressure)
			endif
			break

		default:
			// Unknown token -> treat like "default" (no routing change)
			if(hasSetpoint)
				PGC_SetAndActivateControl(Device, "setvar_DataAcq_SSPressure", val = requestedPressure)
			endif
			break
	endswitch

	// ---- Readback ----

	[source, regulatorPressure] = ReadPressureSourceAndPressure(device, headstage)
	return [source, regulatorPressure]
End

Function [string source, variable pressure] ReadPressureSourceAndPressure(string device, variable headstage)

	WAVE PD = P_GetPressureDataWaveRef(device)
	pressure = PD[headstage][%LastPressureCommand]

	variable mode   = P_GetPressureMethod(device, headstage)
	variable access = P_GetUserAccess(device, headstage, mode)

	if(mode == PRESSURE_METHOD_ATM) // need to think about how to handle unimplemented manual pressure command versus implemented pressure command
		source = "atmosphere"
	elseif(access == ACCESS_USER)
		source = "user"
	else
		source = "regulator"
	endif

	return [source, pressure]

End

// Max pressure pulse is 300 ms. Add a little slack for routing/GUI churn.
static Constant kPressurePulseMaxMS  = 300
static Constant kPressureWaitSlackMS = 150

/// Return 1 if idle, 0 if we timed out still busy.
Function FFI_WaitForIdle(string device, variable headstage)

	WAVE PD = P_GetPressureDataWaveRef(device)

	// Fast path: already idle
	if(!PD[headstage][%OngoingPressurePulse])
		return 1
	endif

	variable t0 = stopmstimer(-2)
	// Wait until the pulse finishes or timeout elapses
	do
		if(!PD[headstage][%OngoingPressurePulse])
			return 1
		endif

		// Timeout check (treating stopmstimer(-2) deltas as milliseconds)
		if((stopmstimer(-2) - t0) > (kPressurePulseMaxMS + kPressureWaitSlackMS))
			// one last check before giving up
			return !PD[headstage][%OngoingPressurePulse]
		endif

		DoUpdate // yield to background tasks/UI
	while(1)
End

Function SetPressureToBaseline()

	string   source
	variable pressure
	[source, pressure] = FFI_GetWithOptionToSetPressure("ITC1600_Dev_0", 0, "atmosphere", 0)
End

Function readoutPressureSourceAndPressure() // should readout source and pressure without making changes to pressure settings

	SetPressureToBaseline()
	string sourceIn, sourceOut
	variable pressureIn, PressureOut
	WAVE PD = P_GetPressureDataWaveRef("ITC1600_Dev_0")
	[SourceIn, pressureIn]   = ReadPressureSourceAndPressure("ITC1600_Dev_0", 0)
	pressureIn               = PD[0][%ManSSPressure]
	[SourceOut, pressureOut] = FFI_GetWithOptionToSetPressure("ITC1600_Dev_0", 0, "default", NaN)
	pressureOut              = PD[0][%ManSSPressure]
	assert(!cmpstr(SourceIn, SourceOut), "changed source when it shouldn't have")
	assert(pressureIn == pressureOut, " changed pressure when it shouldn't have")
End

Function SetRegulatorPressure() // should set the pressure of the next manual pressure command to 2 psi. Should not turn on manual pressure

	SetPressureToBaseline()
	string sourceIn, sourceOut
	variable pressureIn, PressureOut, NextRegulatorPressureCommand
	WAVE PD = P_GetPressureDataWaveRef("ITC1600_Dev_0")
	[SourceIn, pressureIn]       = ReadPressureSourceAndPressure("ITC1600_Dev_0", 0)
	[SourceOut, pressureOut]     = FFI_GetWithOptionToSetPressure("ITC1600_Dev_0", 0, "default", 2)
	NextRegulatorPressureCommand = PD[0][%ManSSPressure]
	assert(!cmpstr(SourceIn, SourceOut), "changed source when it shouldn't have")
	assert(pressureOut == 0, "set output pressure when it shouldn't have")
	assert(NextRegulatorPressureCommand == 2, "did not set the next manual/regulator pressure command to 2 psi")

End

Function SetRegulatorPressureAndSetREgulatorSource() // should set the pressure of the manual pressure command to 3 psi and set the source to regulator. Should not turn on manual pressure

	SetPressureToBaseline()
	string sourceIn, sourceOut
	variable pressureIn, PressureOut
	[SourceIn, pressureIn]   = ReadPressureSourceAndPressure("ITC1600_Dev_0", 0)
	[SourceOut, pressureOut] = FFI_GetWithOptionToSetPressure("ITC1600_Dev_0", 0, "regulator", 3)
	assert(!cmpstr("regulator", SourceOut), "did not change the source to regulator")
	assert(pressureOut == 3, "did not set pressure to 3 psi")
End

Function SetSourceToRegulator() // should set the source to regulator/manual without changing the regulator pressure.

	SetPressureToBaseline()
	string sourceIn, sourceOut
	variable pressureIn, PressureOut
	[SourceIn, pressureIn]   = ReadPressureSourceAndPressure("ITC1600_Dev_0", 0)
	[SourceOut, pressureOut] = FFI_GetWithOptionToSetPressure("ITC1600_Dev_0", 0, "regulator", NaN)
	assert(!cmpstr("regulator", SourceOut), "did not change the source to regulator")
	assert(pressureIn == pressureOut, "changed the pressure!")
End

Function SetSourceToUserSetPressureToNeg2() // should set the source to user and set the next manual pressure command to -2psi

	SetPressureToBaseline()
	string sourceIn, sourceOut
	variable pressureIn, PressureOut
	[SourceIn, pressureIn]   = ReadPressureSourceAndPressure("ITC1600_Dev_0", 0)
	[SourceOut, pressureOut] = FFI_GetWithOptionToSetPressure("ITC1600_Dev_0", 0, "user", -2)
	assert(!cmpstr("user", SourceOut), "did not change the source to user")
	assert(-2 == pressureOut, "changed the pressure!")
End

Function RunTests()

	readoutPressureSourceAndPressure()
	SetRegulatorPressure()
	SetRegulatorPressureAndSetREgulatorSource()
	setSourceToRegulator()
	SetSourceToUserSetPressureToNeg2()
End
