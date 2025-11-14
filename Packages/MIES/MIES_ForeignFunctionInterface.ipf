#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_FFI
#endif // AUTOMATED_TESTING

/// @file MIES_ForeignFunctionInterface.ipf
/// @brief __FFI__ ACQ4/ZeroMQ accessible functions

/// @name Auto Clamp Ctrls enum for FFI_TriggerAutoClampControl
/// @anchor FFI_AutoClampCtrls
///@{
static Constant AUTO_PIPETTE       = 1
static Constant AUTO_CAPACITANCE   = 2
static Constant AUTO_BRIDGEBALANCE = 3
///@}

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

/// @brief Returns the clamp state of a headstage of a locked device
///
/// - if the requested head stage is not active then a null wave is returned
/// The clamp state wave is DP numeric wave:
///
/// For VC
///
/// \rst
/// +------------------------+-----------------------+---------+
/// | Dimension Label        | Value description     | Units   |
/// +========================+=======================+=========+
/// | HoldingPotential       |                       | mV      |
/// +------------------------+-----------------------+---------+
/// | RSCompChaining         |                       | On/Off  |
/// +------------------------+-----------------------+---------+
/// | HoldingPotentialEnable |                       | On/Off  |
/// +------------------------+-----------------------+---------+
/// | WholeCellCap           | 1 : On 0 : Off        | pF      |
/// +------------------------+-----------------------+---------+
/// | WholeCellRes           |                       | MΩ      |
/// +------------------------+-----------------------+---------+
/// | WholeCellEnable        | 1 : On 0 : Off        | On/Off  |
/// +------------------------+-----------------------+---------+
/// | Correction             |                       | %       |
/// +------------------------+-----------------------+---------+
/// | Prediction             |                       | %       |
/// +------------------------+-----------------------+---------+
/// | RsCompEnable           |                       | On/Off  |
/// +------------------------+-----------------------+---------+
/// | PipetteOffsetVC        | 1 : On 0 : Off        | mV      |
/// +------------------------+-----------------------+---------+
/// | WholeCellCap           |                       | a.u.    |
/// +------------------------+-----------------------+---------+
/// | ClampMode              | 0 : VC                |         |
/// +------------------------+-----------------------+---------+
/// \endrst
///
///
/// For IC
///
/// \rst
/// +----------------------+-----------------------+---------+
/// | Dimension Label      | Value description     | Units   |
/// +======================+=======================+=========+
/// | BiasCurrent          |                       | pA      |
/// +----------------------+-----------------------+---------+
/// | BiasCurrentEnable    |                       | On/Off  |
/// +----------------------+-----------------------+---------+
/// | BridgeBalance        |                       | MΩ      |
/// +----------------------+-----------------------+---------+
/// | BridgeBalanceEnable  | 1 : On 0 : Off        | On/Off  |
/// +----------------------+-----------------------+---------+
/// | CapNeut              |                       | pF      |
/// +----------------------+-----------------------+---------+
/// | CapNeutEnable        | 1 : On 0 : Off        | On/Off  |
/// +----------------------+-----------------------+---------+
/// | AutoBiasVcom         |                       | mV      |
/// +----------------------+-----------------------+---------+
/// | AutoBiasVcomVariance |                       | mV      |
/// +----------------------+-----------------------+---------+
/// | AutoBiasIbiasmax     |                       | pA      |
/// +----------------------+-----------------------+---------+
/// | AutoBiasEnable       | 1 : On 0 : Off        | On/Off  |
/// +----------------------+-----------------------+---------+
/// | PipetteOffsetIC      |                       | mV      |
/// +----------------------+-----------------------+---------+
/// | ClampMode            | 1 : IC                |         |
/// +----------------------+-----------------------+---------+
/// \endrst
///
///
/// For I=0
///
/// \rst
/// +----------------------+-----------------------+---------+
/// | Dimension Label      | Value description     | Units   |
/// +======================+=======================+=========+
/// | ClampMode            | 2 : I=0               |         |
/// +----------------------+-----------------------+---------+
/// \endrst
///
/// @param[in] device    Device title, e.g. "Dev1"
/// @param[in] headstage headstage number
/// @returns             wave with clamp state
Function/WAVE FFI_GetClampState(string device, variable headstage)

	variable clampMode, numFuncs, i, j
	string lbl

	FFI_CheckValidDeviceAndHeadstage(device, headstage)
	if(!DAG_GetHeadstageState(device, headstage))
		return $""
	endif

	WAVE AmpStorageWave = GetAmplifierParamStorageWave(device)

	clampMode = DAG_GetHeadstageMode(device, headstage)
	if(clampMode == I_EQUAL_ZERO_MODE)
		Make/FREE/D clampState = {I_EQUAL_ZERO_MODE}
		SetDimLabel ROWS, j, ClampMode, clampState
		return clampState
	endif

	WAVE aiFuncs = AI_GetFunctionConstantForClampMode(clampMode)
	numFuncs = DimSize(aiFuncs, ROWS)
	Make/FREE/T/N=(numFuncs) ctrlNames, ampLabels

	ctrlNames[] = AI_MapFunctionConstantToControl(aiFuncs[p], clampMode)
	ampLabels[] = AI_AmpStorageControlToRowLabel(ctrlNames[p])

	Make/FREE/D/N=(numFuncs + 1) clampState
	for(i = 0; i < numFuncs; i += 1)
		if(IsEmpty(ampLabels[i]))
			continue
		endif
		clampState[j] = AmpStorageWave[%$ampLabels[i]][0][headStage]
		lbl           = AI_MapFunctionConstantToName(aiFuncs[i], clampMode)
		SetDimLabel ROWS, j, $lbl, clampState
		j += 1
	endfor
	clampState[j] = clampMode
	SetDimLabel ROWS, j, ClampMode, clampState
	Redimension/N=(j + 1) clampState

	return clampState
End

/// @brief Triggers an auto clamp control
///
/// @param[in] device    Device title, e.g. "Dev1"
/// @param[in] headstage headstage number
/// @param[in] autoCtrl  auto control number @ref FFI_AutoClampCtrls
Function FFI_TriggerAutoClampControl(string device, variable headstage, variable autoCtrl)

	variable clampMode

	FFI_CheckValidDeviceAndHeadstage(device, headstage)

	clampMode = DAG_GetHeadstageMode(device, headstage)

	if(autoCtrl == AUTO_PIPETTE)
		AI_WriteToAmplifier(device, headstage, clampMode, MCC_AUTOPIPETTEOFFSET_FUNC, 1, GUIWrite = 1)
	elseif(autoCtrl == AUTO_CAPACITANCE)
		AI_WriteToAmplifier(device, headstage, V_CLAMP_MODE, MCC_AUTOWHOLECELLCOMP_FUNC, 1, GUIWrite = 1)
	elseif(autoCtrl == AUTO_BRIDGEBALANCE)
		AI_WriteToAmplifier(device, headstage, I_CLAMP_MODE, MCC_AUTOBRIDGEBALANCE_FUNC, 1, GUIWrite = 1)
	else
		FATAL_ERROR("Unknown auto clamp control")
	endif
End

/// @brief Sets clamp mode
///
/// @param[in] device    Device title, e.g. "Dev1"
/// @param[in] headstage headstage number
/// @param[in] clampMode clamp mode @ref AmplifierClampModes
Function FFI_SetClampMode(string device, variable headstage, variable clampMode)

	FFI_CheckValidDeviceAndHeadstage(device, headstage)
	ASSERT(AI_IsValidClampMode(clampMode), "Invalid clamp mode: " + num2istr(clampMode))

	DAP_SetClampMode(device, headstage, clampMode)
End

/// @brief Sets Holding Potential
///
/// @param[in] device    Device title, e.g. "Dev1"
/// @param[in] headstage headstage number
/// @param[in] potential holding potential in mV when current clamp mode of headstage is VC, bias current in pA when current clamp mode of headstage is IC
Function FFI_SetHoldingPotential(string device, variable headstage, variable potential)

	variable clampMode

	FFI_CheckValidDeviceAndHeadstage(device, headstage)

	clampMode = DAG_GetHeadstageMode(device, headstage)
	ASSERT(clampMode == V_CLAMP_MODE, "Attempt to set holding potential but current clamp mode is not VC !")
	ASSERT(!IsNaN(potential), "potential argument is NaN")

	FFI_SetHolding(device, headstage, clampMode, potential)
End

/// @brief Sets Bias Current
///
/// @param[in] device      Device title, e.g. "Dev1"
/// @param[in] headstage   headstage number
/// @param[in] biasCurrent bias current in pA
Function FFI_SetBiasCurrent(string device, variable headstage, variable biasCurrent)

	variable clampMode

	FFI_CheckValidDeviceAndHeadstage(device, headstage)

	clampMode = DAG_GetHeadstageMode(device, headstage)
	ASSERT(clampMode == I_CLAMP_MODE, "Attempt to set holding potential but current clamp mode is not IC !")
	ASSERT(!IsNaN(biasCurrent), "bias current argument is NaN")

	FFI_SetHolding(device, headstage, clampMode, biasCurrent)
End

static Function FFI_SetHolding(string device, variable headstage, variable clampMode, variable value)

	AI_WriteToAmplifier(device, headstage, clampMode, MCC_HOLDING_FUNC, value, GUIWrite = 1)
End

static Function FFI_CheckValidDeviceAndHeadstage(string device, variable headstage)

	ASSERT(!DAP_DeviceIsUnlocked(device), "Target device is not locked:" + device)
	ASSERT(IsValidHeadstage(headstage), "Invalid headStage index: " + num2str(headstage))
End

/// @brief Sets Auto Bias
///
/// @param[in] device    Device title, e.g. "Dev1"
/// @param[in] headstage headstage number
/// @param[in] potential Vm in mV in the range -99 mV to 99 mV
/// @param[in] enable    when set to 1 then auto bias gets enabled, 0 disabled
Function FFI_SetAutoBias(string device, variable headstage, variable potential, variable enable)

	variable clampMode

	enable = !!enable

	FFI_CheckValidDeviceAndHeadstage(device, headstage)

	clampMode = DAG_GetHeadstageMode(device, headstage)
	ASSERT(clampMode == I_CLAMP_MODE, "Attempt to set auto bias but current clamp mode is not IC !")

	AI_WriteToAmplifier(device, headstage, clampMode, MCC_NO_AUTOBIAS_V_FUNC, potential, GUIWrite = 1)
	AI_WriteToAmplifier(device, headstage, clampMode, MCC_NO_AUTOBIAS_ENABLE_FUNC, enable, GUIWrite = 1)
End

/// @brief Enables/Disables a headstage
///
/// The headstage state can not be changed while a data acquisition is running
///
/// @param[in] device    Device title, e.g. "Dev1"
/// @param[in] headstage headstage number
/// @param[in] enable    when set to 1 the headstage gets enabled, 0 disabled
/// @returns 0 when successful
Function FFI_SetHeadstageActive(string device, variable headstage, variable enable)

	string ctrlName

	enable = !!enable

	FFI_CheckValidDeviceAndHeadstage(device, headstage)

	ctrlName = GetPanelControl(headstage, CHANNEL_TYPE_HEADSTAGE, CHANNEL_CONTROL_CHECK)
	PGC_SetAndActivateControl(device, ctrlName, val = enable)

	return 0
End
