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

	if(!IsValidSweepAndConfig(DAQDataWave, hardwareConfigWave)       \
	   || !IsValidSweepAndConfig(scaledDataWave, hardwareConfigWave))
		BUG("Scaled data and config wave are not compatible, nothing will be saved!")
		return 0
	endif

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

	EP_WriteEpochInfoIntoSweepSettings(device, sweepWave, configWave)

	// Add labnotebook entries for the acquired sweep
	ED_createWaveNoteTags(device, sweepNo)

	EP_AppendLBNEpochs(device, sweepNo)

	if(DAG_GetNumericalValue(device, "Check_Settings_NwbExport"))
		NWB_AppendSweepDuringDAQ(device, sweepWave, configWave, sweepNo, str2num(DAG_GetTextualValue(device, "Popup_Settings_NwbVersion")))
	endif

	SWS_AfterSweepDataChangeHook(device)

	// SetVar_Sweep currently disabled so we have to write manually in the GUIStateWave
	SetSetVariable(device, "SetVar_Sweep", sweepNo + 1)
	DAG_Update(device, "SetVar_Sweep", val = sweepNo + 1)

	AS_HandlePossibleTransition(device, AS_POST_SWEEP, call = !forcedStop)

	if(!forcedStop)
		AFM_CallAnalysisFunctions(device, POST_SET_EVENT)
	endif

	EP_WriteEpochInfoIntoSweepSettings(device, sweepWave, configWave)
	SWS_SweepSettingsEpochInfoToLBN(device, sweepNo)
End

static Function SWS_SweepSettingsEpochInfoToLBN(string device, variable sweepNo)
	variable idx

	WAVE/T sweepSettingsTxtWave = GetSweepSettingsTextWave(device)
	WAVE/T sweepSettingsTxtKey = GetSweepSettingsTextKeyWave(device)

	idx = FindDimLabel(sweepSettingsTxtWave, COLS, "Epochs")
	ASSERT(idx >= 0, "Could not find epochs wave")

	Duplicate/FREE/RMD=[idx] sweepSettingsTxtWave, values
	Duplicate/FREE/RMD=[idx] sweepSettingsTxtKey, keys

	ED_AddEntriesToLabnotebook(values, keys, sweepNo, device, DATA_ACQUISITION_MODE)
End

/// @brief General hook function which gets always executed after sweep data was added or removed
///
/// @param device device name
static Function SWS_AfterSweepDataChangeHook(string device)

	WAVE/T/Z allDBs = DB_FindAllDataBrowser(device, mode = BROWSER_MODE_ALL)

	if(!WaveExists(allDBs))
		return NaN
	endif

	for(win : allDBs)
		DB_UpdateToLastSweep(win)
	endfor
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

/// @brief Return the floating point type for storing the raw data
///
/// The returned values are the same as for `WaveType`
Function SWS_GetRawDataFPType(device)
	string device

	return DAG_GetNumericalValue(device, "Check_Settings_UseDoublePrec") ? IGOR_TYPE_64BIT_FLOAT : IGOR_TYPE_32BIT_FLOAT
End
