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
/// @param panelTitle device
/// @param forcedStop [optional, defaults to false] if DAQ was aborted (true) or stopped by itself (false)
Function SWS_SaveAcquiredData(panelTitle, [forcedStop])
	string panelTitle
	variable forcedStop

	variable sweepNo
	string sweepName, configName

	forcedStop = ParamIsDefault(forcedStop) ? 0 : !!forcedStop

	sweepNo = DAG_GetNumericalValue(panelTitle, "SetVar_Sweep")

	WAVE DAQDataWave = GetDAQDataWave(panelTitle, DATA_ACQUISITION_MODE)
	WAVE hardwareConfigWave = GetDAQConfigWave(panelTitle)
	WAVE scaledDataWave = GetScaledDataWave(panelTitle)

	ASSERT(IsValidSweepAndConfig(DAQDataWave, hardwareConfigWave), "Data and config wave are not compatible")

	DFREF dfr = GetDeviceDataPath(panelTitle)

	configName = GetConfigWaveName(sweepNo)
	WAVE/SDFR=dfr/Z configWave = $configName
	ASSERT(!WaveExists(configWave), "The config wave must not exist, name=" + configName)

	sweepName = GetSweepWaveName(sweepNo)
	WAVE/SDFR=dfr/Z sweepWave = $sweepName
	ASSERT(!WaveExists(sweepWave), "The sweep wave must not exist, name=" + sweepName)

	Duplicate hardwareConfigWave, dfr:$configName
	MoveWave scaledDataWave, dfr:$sweepName

	WAVE sweepWave = GetSweepWave(panelTitle, sweepNo)
	WAVE configWave = GetConfigWave(sweepWave)

	SetSetVariableLimits(panelTitle, "SetVar_Sweep", 0, sweepNo + 1, 1)
	// SetVar_Sweep currently disabled so we have to write manually in the GUIStateWave
	SetSetVariable(panelTitle, "SetVar_Sweep", sweepNo + 1)
	DAG_Update(panelTitle, "SetVar_Sweep", val = sweepNo + 1)

	// Add labnotebook entries for the acquired sweep
	ED_createWaveNoteTags(panelTitle, sweepNo)

	if(DAG_GetNumericalValue(panelTitle, "Check_Settings_NwbExport"))
		NWB_AppendSweepDuringDAQ(panelTitle, sweepWave, configWave, sweepNo, str2num(DAG_GetTextualValue(panelTitle, "Popup_Settings_NwbVersion")))
	endif

	SWS_AfterSweepDataChangeHook(panelTitle)

	AS_HandlePossibleTransition(panelTitle, AS_POST_SWEEP, call = !forcedStop)

	if(!forcedStop)
		AFM_CallAnalysisFunctions(panelTitle, POST_SET_EVENT)
	endif
End

/// @brief General hook function which gets always executed after sweep data was added or removed
///
/// @param panelTitle device name
static Function SWS_AfterSweepDataChangeHook(panelTitle)
	string panelTitle

	string databrowser, scPanel

	databrowser = DB_FindDataBrowser(panelTitle)

	if(IsEmpty(databrowser))
		return NaN
	endif

	scPanel = BSP_GetSweepControlsPanel(databrowser)

	if(!GetCheckBoxState(scPanel, "check_SweepControl_AutoUpdate"))
		return NaN
	endif

	try
		ClearRTError()
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
/// @param panelTitle device
/// @param timing     One of @ref GainTimeParameter
///
/// @see GetDAQDataWave()
Function/WAVE SWS_GetChannelGains(panelTitle, [timing])
	string panelTitle
	variable timing

	variable numDACs, numADCs, numTTLs
	variable numCols, hardwareType

	ASSERT(!ParamIsDefault(timing) && (timing == GAIN_BEFORE_DAQ || timing == GAIN_AFTER_DAQ), "time argument is missing or wrong")

	WAVE DAQConfigWave = GetDAQConfigWave(panelTitle)
	numCols = DimSize(DAQConfigWave, ROWS)

	WAVE DA_EphysGuiState = GetDA_EphysGuiStateNum(panelTitle)
	WAVE ADCs = GetADCListFromConfig(DAQConfigWave)
	WAVE DACs = GetDACListFromConfig(DAQConfigWave)
	WAVE TTLs = GetTTLListFromConfig(DAQConfigWave)

	numADCs = DimSize(ADCs, ROWS)
	numDACs = DimSize(DACs, ROWS)
	numTTLs = DimSize(TTLs, ROWS)

	Make/D/FREE/N=(numCols) gain

	hardwareType = GetHardwareType(panelTitle)
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
Function SWS_DeleteDataWaves(panelTitle)
	string panelTitle

	string list, path, name, absolutePath
	variable i, numItems, waveSweepNo, sweepNo, refTime

	refTime = DEBUG_TIMER_START()

	WAVE numericalValues = GetLBNumericalValues(panelTitle)
	WAVE/Z sweepRollbackUsed = GetSweepsWithSetting(numericalValues, SWEEP_ROLLBACK_KEY)

	if(!WaveExists(sweepRollbackUsed))
		return NaN
	endif

	sweepNo   = DAG_GetNumericalValue(panelTitle, "SetVar_Sweep")
	DFREF dfr = GetDeviceDataPath(panelTitle)
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

	path = GetDeviceDataPathAsString(panelTitle)

	DFREF deletedFolder = UniqueDataFolder($GetDevicePathAsString(panelTitle), "Data_deleted")
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

	SWS_AfterSweepDataChangeHook(panelTitle)
End

/// @brief Return the floating point type for storing the raw data
///
/// The returned values are the same as for `WaveType`
Function SWS_GetRawDataFPType(panelTitle)
	string panelTitle

	return DAG_GetNumericalValue(panelTitle, "Check_Settings_UseDoublePrec") ? IGOR_TYPE_64BIT_FLOAT : IGOR_TYPE_32BIT_FLOAT
End
