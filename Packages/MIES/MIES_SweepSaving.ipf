#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SWS
#endif

/// @file MIES_SweepSaving.ipf
/// @brief __SWS__ Scale and store acquired data

/// @brief Save the acquired sweep permanently
///
/// @param device device
/// @param forcedStop [optional, defaults to false] if DAQ was aborted (true) or stopped by itself (false)
Function SWS_SaveAcquiredData(device, [forcedStop])
	string device
	variable forcedStop

	variable sweepNo
	string sweepName, configName

	forcedStop = ParamIsDefault(forcedStop) ? 0 : !!forcedStop

	sweepNo = DAG_GetNumericalValue(device, "SetVar_Sweep")

	WAVE DAQDataWave = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
	WAVE hardwareConfigWave = GetDAQConfigWave(device)
	WAVE scaledDataWave = GetScaledDataWave(device)

	ASSERT(IsValidSweepAndConfig(DAQDataWave, hardwareConfigWave), "Data and config wave are not compatible")

	DFREF dfr = GetDeviceDataPath(device)

	configName = GetConfigWaveName(sweepNo)
	WAVE/SDFR=dfr/Z configWave = $configName
	ASSERT(!WaveExists(configWave), "The config wave must not exist, name=" + configName)

	sweepName = GetSweepWaveName(sweepNo)
	WAVE/SDFR=dfr/Z sweepWave = $sweepName
	ASSERT(!WaveExists(sweepWave), "The sweep wave must not exist, name=" + sweepName)

	Duplicate hardwareConfigWave, dfr:$configName
	MoveWave scaledDataWave, dfr:$sweepName

	WAVE sweepWave = GetSweepWave(device, sweepNo)
	WAVE configWave = GetConfigWave(sweepWave)

	SetSetVariableLimits(device, "SetVar_Sweep", 0, sweepNo + 1, 1)
	// SetVar_Sweep currently disabled so we have to write manually in the GUIStateWave
	SetSetVariable(device, "SetVar_Sweep", sweepNo + 1)
	DAG_Update(device, "SetVar_Sweep", val = sweepNo + 1)

	EP_WriteEpochInfoIntoSweepSettings(device, sweepWave, configWave)

	// Add labnotebook entries for the acquired sweep
	ED_createWaveNoteTags(device, sweepNo)

	if(DAG_GetNumericalValue(device, "Check_Settings_NwbExport"))
		NWB_AppendSweepDuringDAQ(device, sweepWave, configWave, sweepNo, str2num(DAG_GetTextualValue(device, "Popup_Settings_NwbVersion")))
	endif

	SWS_AfterSweepDataChangeHook(device)

	AS_HandlePossibleTransition(device, AS_POST_SWEEP, call = !forcedStop)

	if(!forcedStop)
		AFM_CallAnalysisFunctions(device, POST_SET_EVENT)
	endif
End

/// @brief General hook function which gets always executed after sweep data was added or removed
///
/// @param device device name
static Function SWS_AfterSweepDataChangeHook(device)
	string device

	string databrowser, scPanel

	databrowser = DB_FindDataBrowser(device)

	if(IsEmpty(databrowser))
		return NaN
	endif

	scPanel = BSP_GetSweepControlsPanel(databrowser)

	if(!GetCheckBoxState(scPanel, "check_SweepControl_AutoUpdate"))
		return NaN
	endif

	// catch all error conditions, asserts and aborts
	// and silently ignore them
	AssertOnAndClearRTError()
	try
		DB_UpdateToLastSweep(databrowser); AbortOnRTE
	catch
		ClearRTError()
	endtry
End

/// @brief Return a free wave with all channel gains
///
/// Rows:
///  - Active channels only (same as DAQConfigWave)
///
/// Different hardware has different requirements how the DA, AD and TLL
/// channels are scaled. As general rule use `data * SWS_GetChannelGains` for
/// GAIN_BEFORE_DAQ and `data / SWS_GetChannelGains` for GAIN_AFTER_DAQ, i.e.
/// `before_gain * data(before_DAQ) == after_gain * data(after_DAQ)`.
///
/// \rst
///
/// ========== ========= ===============================================
///  Hardware   Channel   Specialities
/// ========== ========= ===============================================
///  ITC        DA        None
///  ITC        AD        None
///  ITC        TTL       Multiple TTL bits are combined. See SplitTTLWaveIntoComponents() for details.
///  NI         DA        None
///  NI         AD        Scaled directly on acquisition.
///  NI         TTL       One channel per TTL bit.
/// ========== ========= ===============================================
///
/// \endrst
///
/// @param device device
/// @param timing     One of @ref GainTimeParameter
///
/// @see GetDAQDataWave()
Function/WAVE SWS_GetChannelGains(device, [timing])
	string device
	variable timing

	variable numDACs, numADCs, numTTLs
	variable numCols, hardwareType

	ASSERT(!ParamIsDefault(timing) && (timing == GAIN_BEFORE_DAQ || timing == GAIN_AFTER_DAQ), "time argument is missing or wrong")

	WAVE DAQConfigWave = GetDAQConfigWave(device)
	numCols = DimSize(DAQConfigWave, ROWS)

	WAVE DA_EphysGuiState = GetDA_EphysGuiStateNum(device)
	WAVE ADCs = GetADCListFromConfig(DAQConfigWave)
	WAVE DACs = GetDACListFromConfig(DAQConfigWave)
	WAVE TTLs = GetTTLListFromConfig(DAQConfigWave)

	numADCs = DimSize(ADCs, ROWS)
	numDACs = DimSize(DACs, ROWS)
	numTTLs = DimSize(TTLs, ROWS)

	Make/D/FREE/N=(numCols) gain

	hardwareType = GetHardwareType(device)
	switch(hardwareType)
		case HARDWARE_NI_DAC:
			//  in mV^-1, w'(V) = w * g
			if(numDACs > 0)
				gain[0, numDACs - 1] = 1 / DA_EphysGuiState[DACs[p]][%$GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)]
			endif

			// in pA / V, w'(pA) = w * g
			if(numADCs > 0)
				if(timing == GAIN_BEFORE_DAQ)
					gain[numDACs, numDACs + numADCs - 1] = 1 / DA_EphysGuiState[ADCs[p - numDACs]][%$GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)]
				elseif(timing == GAIN_AFTER_DAQ)
					gain[numDACs, numDACs + numADCs - 1] = 1
				endif
			endif

			// no scaling done for TTL
			if(numTTLs > 0)
				gain[numDACs + numADCs, *] = 1
			endif
			break
		case HARDWARE_ITC_DAC:
			// DA: w' = w / (s / g)
			if(numDACs > 0)
				gain[0, numDACs - 1] = HARDWARE_ITC_BITS_PER_VOLT / DA_EphysGuiState[DACs[p]][%$GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)]
			endif

			// AD: w' = w  / (g * s)
			if(numADCs > 0)
				gain[numDACs, numDACs + numADCs - 1] = DA_EphysGuiState[ADCs[p - numDACs]][%$GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)] * HARDWARE_ITC_BITS_PER_VOLT
			endif

			// no scaling done for TTL
			if(numTTLs > 0)
				gain[numDACs + numADCs, *] = 1
			endif
			break
	endswitch

	return gain
End

/// @brief Delete all sweep and config waves having a sweep number
/// of `sweepNo` and higher
Function SWS_DeleteDataWaves(device)
	string device

	string list, path, name, absolutePath
	variable i, numItems, waveSweepNo, sweepNo, refTime

	refTime = DEBUG_TIMER_START()

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE/Z sweepRollbackUsed = GetSweepsWithSetting(numericalValues, SWEEP_ROLLBACK_KEY)

	if(!WaveExists(sweepRollbackUsed))
		return NaN
	endif

	sweepNo   = DAG_GetNumericalValue(device, "SetVar_Sweep")
	DFREF dfr = GetDeviceDataPath(device)
	list      = GetListOfObjects(dfr, DATA_SWEEP_REGEXP + "|" + DATA_SWEEP_REGEXP_BAK + "|" + DATA_CONFIG_REGEXP + "|" + DATA_CONFIG_REGEXP_BAK)
	list     += GetListOfObjects(dfr, ".*", typeFlag=COUNTOBJECTS_DATAFOLDER)

	numItems = ItemsInList(list)

	if(!numItems)
		return NaN
	endif

	Make/FREE/N=(numItems) matchesWithNaNs
	MultiThread matchesWithNaNs[] = ExtractSweepNumber(StringFromList(p, list)) >= sweepNo ? p : NaN

	WAVE/Z matches = ZapNaNs(matchesWithNaNs)

	DEBUGPRINT_ELAPSED(refTime)

	if(!WaveExists(matches))
		return NaN
	endif

	path = GetDeviceDataPathAsString(device)

	DFREF deletedFolder = UniqueDataFolder($GetDevicePathAsString(device), "Data_deleted")
	ASSERT(IsDataFolderEmpty(deletedFolder), "Invalid target datafolder")

	numItems = DimSize(matches, ROWS)
	for(i = 0; i < numItems; i += 1)
		absolutePath = path + ":" + StringFromList(matches[i], list)

		WAVE/Z wv = $absolutePath
		if(WaveExists(wv))
			MoveWave wv, deletedFolder
			continue
		endif

		DFREF folder = $absolutePath
		if(DataFolderExistsDFR(folder))
			MoveDataFolder folder, deletedFolder
			continue
		endif

		ASSERT(0, "Invalid state when deleting data: " + absolutePath)
	endfor

	DEBUGPRINT_ELAPSED(refTime)

	SWS_AfterSweepDataChangeHook(device)
End

/// @brief Return the floating point type for storing the raw data
///
/// The returned values are the same as for `WaveType`
Function SWS_GetRawDataFPType(device)
	string device

	return DAG_GetNumericalValue(device, "Check_Settings_UseDoublePrec") ? IGOR_TYPE_64BIT_FLOAT : IGOR_TYPE_32BIT_FLOAT
End
