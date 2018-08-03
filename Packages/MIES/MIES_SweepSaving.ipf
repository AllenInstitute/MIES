#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
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
Function SWS_SaveAndScaleITCData(panelTitle, [forcedStop])
	string panelTitle
	variable forcedStop

	variable sweepNo

	forcedStop = ParamIsDefault(forcedStop) ? 0 : !!forcedStop

	sweepNo = DAG_GetNumericalValue(panelTitle, "SetVar_Sweep")

	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	SCOPE_UpdateOscilloscopeData(panelTitle, DATA_ACQUISITION_MODE, fifoPos=stopCollectionPoint)

	DFREf dfr = GetDeviceDataPath(panelTitle)

	WAVE dataWave = SWS_StoreITCDataWaveScaled(panelTitle, dfr, sweepNo)

	Duplicate/O GetITCChanConfigWave(panelTitle), dfr:$("Config_Sweep_" + num2str(sweepNo))/Wave=configWave

	SetSetVariableLimits(panelTitle, "SetVar_Sweep", 0, sweepNo + 1, 1)
	// SetVar_Sweep currently disabled so we have to write manually in the GUIStateWave
	SetSetVariable(panelTitle, "SetVar_Sweep", sweepNo + 1)
	DAG_Update(panelTitle, "SetVar_Sweep", val = sweepNo + 1)

	// Add labnotebook entries for the acquired sweep
	ED_createWaveNoteTags(panelTitle, sweepNo)

	if(DAG_GetNumericalValue(panelTitle, "Check_Settings_NwbExport"))
		NWB_AppendSweep(panelTitle, dataWave, configWave, sweepNo)
	endif

	AM_analysisMasterPostSweep(panelTitle, sweepNo)

	if(!forcedStop)
		AFM_CallAnalysisFunctions(panelTitle, POST_SWEEP_EVENT)
		AFM_CallAnalysisFunctions(panelTitle, POST_SET_EVENT)
	endif

	SWS_AfterSweepDataSaveHook(panelTitle)
End

/// @brief General hook function which gets always executed after sweep data saving
///
/// @param panelTitle device name
static Function SWS_AfterSweepDataSaveHook(panelTitle)
	string panelTitle

	string panelList, panel, scPanel
	variable numPanels, i

	panelList = WinList("DB_*", ";", "WIN:1")

	numPanels = ItemsInList(panelList)
	for(i = 0; i < numPanels; i += 1)
		panel = StringFromList(i, panelList)

		if(!BSP_IsDataBrowser(panel))
			continue
		endif

		if(!cmpstr(panelTitle, BSP_GetDevice(panel)))
			scPanel = BSP_GetSweepControlsPanel(panel)

			if(GetCheckBoxState(scPanel, "check_SweepControl_AutoUpdate"))
				DB_UpdateToLastSweep(panel)
			endif
		endif
	endfor
End

/// @brief Return a free wave with all channel gains
///
/// Rows:
///  - Active channels only (same as ITCChanConfigWave)
///
/// Can be used to convert the ITCDataWave contents from bits to mV/pA
/// The ITCDataWave uses digital ADC/DAC values while for NI devices the values represent actual voltages
/// So the gain for NI devices is inverted (aka it is an actual voltage gain factor)
Function/WAVE SWS_GetChannelGains(panelTitle)
	string panelTitle

	variable numDACs, numADCs, numTTLs
	variable numCols, hardwareType

	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
	numCols = DimSize(ITCChanConfigWave, ROWS)

	WAVE DA_EphysGuiState = GetDA_EphysGuiStateNum(panelTitle)
	WAVE ADCs = GetADCListFromConfig(ITCChanConfigWave)
	WAVE DACs = GetDACListFromConfig(ITCChanConfigWave)
	WAVE TTLs = GetTTLListFromConfig(ITCChanConfigWave)

	numADCs = DimSize(ADCs, ROWS)
	numDACs = DimSize(DACs, ROWS)
	numTTLs = DimSize(TTLs, ROWS)

	Make/D/FREE/N=(numCols) gain

	hardwareType = DAP_GetHardwareType(panelTitle)
	switch(hardwareType)
		case HARDWARE_NI_DAC:
			//  in mV^-1, w'(V) = w * g
			if(numDACs > 0)
				gain[0, numDACs - 1] = 1 / DA_EphysGuiState[DACs[p]][%$GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)]
			endif

			// in pA / V, w'(pA) = w * g
			if(numADCs > 0)
				gain[numDACs, numDACs + numADCs - 1] = 1 / DA_EphysGuiState[ADCs[p - numDACs]][%$GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)]
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

/// @brief Create a sweep wave holding the scaled contents of ITCDataWave
///
/// Only the x-range up to `stopCollectionPoint` is stored.
static Function/WAVE SWS_StoreITCDataWaveScaled(panelTitle, dfr, sweepNo)
	string panelTitle
	DFREF dfr
	variable sweepNo

	variable numEntries, numDACs, numADCs, numTTLs
	variable numRows, numCols
	string sweepWaveName

	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	WAVE ITCDataWave = GetHardwareDataWave(panelTitle)
	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)

	ASSERT(IsValidSweepAndConfig(ITCDataWave, ITCChanConfigWave), "ITC Data and config wave are not compatible")

	numRows = stopCollectionPoint
	numCols = DimSize(ITCDataWave, COLS)
	ASSERT(numCols > 0, "Expected at least one channel")

	sweepWaveName = "Sweep_" +  num2str(sweepNo)
	Make/O/N=(numRows, numCols)/Y=(SWS_GetRawDataFPType(panelTitle)) dfr:$sweepWaveName/Wave=sweepWave

	WAVE gain = SWS_GetChannelGains(paneltitle)

	MultiThread sweepWave[][] = ITCDataWave[p][q] / gain[q]
	CopyScales/P ITCDataWave, sweepWave

	return sweepWave
End

/// @brief Delete all sweep and config waves having a sweep number
/// of `sweepNo` and higher
Function SWS_DeleteDataWaves(panelTitle)
	string panelTitle

	string list, path, name
	variable i, numItems, waveSweepNo, sweepNo

	sweepNo   = DAG_GetNumericalValue(panelTitle, "SetVar_Sweep")
	path      = GetDeviceDataPathAsString(panelTitle)
	DFREF dfr = GetDeviceDataPath(panelTitle)
	list      = GetListOfObjects(dfr, DATA_SWEEP_REGEXP, waveProperty="MINCOLS:2")
	list     += GetListOfObjects(dfr, DATA_SWEEP_REGEXP_BAK, waveProperty="MINCOLS:2")
	list     += GetListOfObjects(dfr, DATA_CONFIG_REGEXP, waveProperty="MINCOLS:2")
	list     += GetListOfObjects(dfr, DATA_CONFIG_REGEXP_BAK, waveProperty="MINCOLS:2")
	list     += GetListOfObjects(dfr, ".*", typeFlag=COUNTOBJECTS_DATAFOLDER)

	numItems = ItemsInList(list)
	for(i = 0; i < numItems; i += 1)
		name = StringFromList(i, list)
		waveSweepNo = ExtractSweepNumber(name)

		if(waveSweepNo < sweepNo)
			continue
		endif
		KillOrMoveToTrashPath(path + ":" + name)
	endfor
End

/// @brief Return the floating point type for storing the raw data
///
/// The returned values are the same as for `WaveType`
static Function SWS_GetRawDataFPType(panelTitle)
	string panelTitle

	return DAG_GetNumericalValue(panelTitle, "Check_Settings_UseDoublePrec") ? IGOR_TYPE_64BIT_FLOAT : IGOR_TYPE_32BIT_FLOAT
End
