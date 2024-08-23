#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_FFI
#endif

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
/// @sa PUB_GetJSONTemplate
Function/WAVE FFI_GetAvailableMessageFilters()

	Make/FREE/T wv = {ZeroMQ_HEARTBEAT, IVS_PUB_FILTER, PRESSURE_STATE_FILTER, PRESSURE_SEALED_FILTER, \
	                  PRESSURE_BREAKIN_FILTER, AUTO_TP_FILTER, AMPLIFIER_CLAMP_MODE_FILTER,            \
	                  AMPLIFIER_AUTO_BRIDGE_BALANCE, ANALYSIS_FUNCTION_PB, ANALYSIS_FUNCTION_SE,       \
	                  ANALYSIS_FUNCTION_VM, DAQ_TP_STATE_CHANGE_FILTER,                                \
	                  ANALYSIS_FUNCTION_AR, ZMQ_FILTER_TPRESULT_NOW, ZMQ_FILTER_TPRESULT_1S,           \
	                  ZMQ_FILTER_TPRESULT_5S, ZMQ_FILTER_TPRESULT_10S}

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
