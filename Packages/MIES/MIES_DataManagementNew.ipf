#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_DataManagementNew.ipf
/// @brief __DM__ Convert and scale acquired data

Function DM_SaveAndScaleITCData(panelTitle)
	string panelTitle

	variable sweepNo

	sweepNo = GetSetVariable(panelTitle, "SetVar_Sweep")

	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	DM_UpdateOscilloscopeData(panelTitle, DATA_ACQUISITION_MODE, fifoPos=stopCollectionPoint)

	DFREf dfr = GetDeviceDataPath(panelTitle)

	WAVE dataWave = DM_StoreITCDataWaveScaled(panelTitle, dfr, sweepNo)
	note dataWave, Time()
	note dataWave, GetExperimentName()  + " - Igor Pro " + num2str(igorVersion())
	AppendMiesVersionToWaveNote(dataWave)

	Duplicate/O GetITCChanConfigWave(panelTitle), dfr:$("Config_Sweep_" + num2str(sweepNo))/Wave=configWave

	SetVariable SetVar_Sweep, Value = _NUM:(sweepNo + 1), limits={0, sweepNo + 1, 1}, win = $panelTitle

	if(GetCheckboxState(panelTitle, "check_Settings_SaveAmpSettings"))
		AI_FillAndSendAmpliferSettings(panelTitle, sweepNo)
		// function for debugging
		// AI_createDummySettingsWave(panelTitle, SweepNo)
	endif

	// if option is checked, wave note containing single readings from (async) ADs is made
	if(GetCheckboxState(panelTitle, "Check_Settings_Append"))
		ITC_ADDataBasedWaveNotes(dataWave, panelTitle)
	endif

	// Add wave notes for the stim wave name and scale factor
	ED_createWaveNoteTags(panelTitle, sweepNo)

	// Add wave notes for the factors on the Asyn tab
	ED_createAsyncWaveNoteTags(panelTitle, sweepNo)

	// TP settings, especially useful if "global TP insertion" is active
	ED_TPSettingsDocumentation(panelTitle)

	if(GetCheckBoxState(panelTitle, "Check_Settings_NwbExport"))
		NWB_AppendSweep(panelTitle, dataWave, configWave, sweepNo)
	endif

	AM_analysisMasterPostSweep(panelTitle, sweepNo)
	DM_CallAnalysisFunctions(panelTitle, POST_SWEEP_EVENT)

	DM_AfterSweepDataSaveHook(panelTitle)
End

/// @brief Call the analysis function associated with the stimset from the wavebuilder
///
/// @return 1 to signal the caller that the analysis function requests an immediate abort, 0 to continue
Function DM_CallAnalysisFunctions(panelTitle, eventType)
	string panelTitle
	variable eventType

	variable error, i, valid_f1, valid_f2, ret
	string func, setName

	if(GetCheckBoxState(panelTitle, "Check_Settings_SkipAnalysFuncs"))
		return 0
	endif

	NVAR count = $GetCount(panelTitle)
	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	WAVE statusHS = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		DM_GetAnalysisFuncFromHeadstage(panelTitle, i, eventType, func, setName)

		if(isEmpty(func) || isEmpty(setName))
			continue
		endif

		switch(eventType)
			case PRE_DAQ_EVENT:
			case MID_SWEEP_EVENT:
			case POST_SWEEP_EVENT:
			case POST_DAQ_EVENT:
				// nothing to do
				break
			case POST_SET_EVENT:
				if(mod(count + 1, IDX_NumberOfTrialsInSet(panelTitle, setName)) != 0)
					continue
				endif
				break
			default:
				ASSERT(0, "Invalid eventType")
				break
		endswitch

		FUNCREF AF_PROTO_ANALYSIS_FUNC_V1 f1 = $func
		FUNCREF AF_PROTO_ANALYSIS_FUNC_V2 f2 = $func

		valid_f1 = FuncRefIsAssigned(FuncRefInfo(f1))
		valid_f2 = FuncRefIsAssigned(FuncRefInfo(f2))

		if(!valid_f1 && !valid_f2) // not a valid analysis function
			continue
		endif

		WAVE ITCDataWave = GetITCDataWave(panelTitle)
		SetWaveLock 1, ITCDataWave

		ret = NaN
		try
			if(valid_f1)
				ret = f1(panelTitle, eventType, ITCDataWave, i); AbortOnRTE
			elseif(valid_f2)
				ret = f2(panelTitle, eventType, ITCDataWave, i, stopCollectionPoint - 1); AbortOnRTE
			else
				ASSERT(0, "impossible case")
			endif
		catch
			error = GetRTError(1)
			printf "The analysis function %s aborted, this is dangerous and must *not* happen!\r", func
		endtry

		SetWaveLock 0, ITCDataWave

		if(eventType == PRE_DAQ_EVENT && ret == 1)
			return  1
		endif
	endfor

	return 0
End

/// @brief General hook function which gets always executed after sweep data saving
static Function DM_AfterSweepDataSaveHook(panelTitle)
	string panelTitle

	string panelList, dataPath, panel, panelType
	variable numPanels, i

	panelList = WinList("DB_*", ";", "WIN:64")

	numPanels = ItemsInList(panelList)
	for(i = 0; i < numPanels; i += 1)
		panel = StringFromList(i, panelList)

		panelType = GetUserData(panel, "", MIES_PANEL_TYPE_USER_DATA)
		if(!cmpstr(panelType, MIES_DATABROWSER_PANEL))
			dataPath   = GetUserData(panel, "", "DataFolderPath")
			if(!cmpstr(dataPath, GetDevicePathAsString(panelTitle)))
				DB_UpdateToLastSweep(panel)
			endif
		endif
	endfor
End

/// @brief Prepares a subset/copy of `ITCDataWave` for displaying it in the
/// oscilloscope panel
///
/// @param panelTitle  panel title
/// @param dataAcqOrTP One of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param chunk       Only for #TEST_PULSE_MODE and multi device mode; Selects
///                    the testpulse to extract
/// @param fifoPos     Position of the fifo used by the ITC XOP to keep track of
///                    the position which will be written next
Function DM_UpdateOscilloscopeData(panelTitle, dataAcqOrTP, [chunk, fifoPos])
	string panelTitle
	variable dataAcqOrTP, chunk, fifoPos

	variable length, first, last
	variable startOfADColumns, numEntries

	WAVE OscilloscopeData = GetOscilloscopeWave(panelTitle)
	WAVE ITCDataWave      = GetITCDataWave(panelTitle)
	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
	WAVE ADCs = GetADCListFromConfig(ITCChanConfigWave)
	WAVE DA_EphysGuiState = GetDA_EphysGuiStateNum(panelTitle)
	startOfADColumns = DimSize(GetDACListFromConfig(ITCChanConfigWave), ROWS)
	numEntries = DimSize(ADCs, ROWS)

	//do the AD scaling here manually so that is can be as fast as possible
	Make/FREE/N=(numEntries) gain = DA_EphysGuiState[ADCs[p]][%ADGain] * HARDWARE_ITC_BITS_PER_VOLT

	if(dataAcqOrTP == TEST_PULSE_MODE)
		if(ParamIsDefault(chunk))
			chunk = 0
		endif

		ASSERT(ParamIsDefault(fifoPos), "optional parameter fifoPos is not possible with TEST_PULSE_MODE")

		length = TP_GetTestPulseLengthInPoints(panelTitle, REAL_SAMPLING_INTERVAL_TYPE)
		first  = chunk * length
		last   = first + length - 1
		ASSERT(first >= 0 && last < DimSize(ITCDataWave, ROWS) && first < last, "Invalid wave subrange")

		Multithread OscilloscopeData[][startOfADColumns, startOfADColumns + numEntries - 1] = ITCDataWave[first + p][q] / gain[q - startOfADColumns]
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)
		ASSERT(ParamIsDefault(chunk), "optional parameter chunk is not possible with DATA_ACQUISITION_MODE")
		ASSERT(EqualWaves(ITCDataWave, OscilloscopeData, 512), "ITCDataWave and OscilloscopeData have differing dimensions")

		ASSERT(!ParamIsDefault(fifoPos), "optional parameter fifoPos missing")

		if(fifoPos == 0)
			// nothing to do
			return NaN
		elseif(fifoPos < 0)
			printf "fifoPos was clipped to zero, old value %g\r", fifoPos
			return NaN
		elseif(fifoPos >= DimSize(OscilloscopeData, ROWS))
			printf "fifoPos was clipped to row size of OscilloscopeData, old value %g\r", fifoPos
			fifoPos = DimSize(OscilloscopeData, ROWS) - 1
		endif

		Multithread OscilloscopeData[0, fifoPos - 1][startOfADColumns, startOfADColumns + numEntries - 1] = ITCDataWave[p][q] / gain[q - startOfADColumns]
	else
		ASSERT(0, "Invalid dataAcqOrTP value")
	endif
End

/// @brief Create a sweep wave holding the scaled contents of ITCDataWave
///
/// Only the x-range up to `stopCollectionPoint` is stored.
static Function/WAVE DM_StoreITCDataWaveScaled(panelTitle, dfr, sweepNo)
	string panelTitle
	DFREF dfr
	variable sweepNo

	variable numEntries, numDACs, numADCs, numTTLs
	variable numRows, numCols
	string sweepWaveName

	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
	WAVE DA_EphysGuiState = GetDA_EphysGuiStateNum(panelTitle)
	WAVE ADCs = GetADCListFromConfig(ITCChanConfigWave)
	WAVE DACs = GetDACListFromConfig(ITCChanConfigWave)
	WAVE TTLs = GetTTLListFromConfig(ITCChanConfigWave)

	numRows = stopCollectionPoint
	numCols = DimSize(ITCDataWave, COLS)
	ASSERT(numCols > 0, "Expected at least one channel")

	numADCs = DimSize(ADCs, ROWS)
	numDACs = DimSize(DACs, ROWS)
	numTTLs = DimSize(TTLs, ROWS)

	Make/FREE/N=(numCols) gain

	// DA: w' = w * g / s
	if(numDACs > 0)
		gain[0, numDACs - 1] = DA_EphysGuiState[DACs[p]][%DAGain] / HARDWARE_ITC_BITS_PER_VOLT
	endif

	// AD: w' = w  / (g * s)
	if(numADCs > 0)
		gain[numDACs, numDACs + numADCs - 1] = DA_EphysGuiState[ADCs[p - numDACs]][%ADGain] * HARDWARE_ITC_BITS_PER_VOLT
	endif

	// no scaling done for TTL
	if(numTTLs > 0)
		gain[numDACs + numADCs, *] = 1
	endif

	sweepWaveName = "Sweep_" +  num2str(sweepNo)
	Make/O/N=(numRows, numCols)/Y=(DM_GetRawDataFPType(panelTitle)) dfr:$sweepWaveName/Wave=sweepWave

	MultiThread sweepWave[0, stopCollectionPoint - 1][] = ITCDataWave[p][q] / gain[q]

	return sweepWave
End

/// @brief Delete all sweep and config waves having a sweep number
/// of `sweepNo` and higher
Function DM_DeleteDataWaves(panelTitle)
	string panelTitle

	string list, path, name
	variable i, numItems, waveSweepNo, sweepNo

	sweepNo = GetSetVariable(panelTitle, "SetVar_Sweep")
	path    = GetDeviceDataPathAsString(panelTitle)
	list    = GetListOfWaves(GetDeviceDataPath(panelTitle), DATA_SWEEP_REGEXP, waveProperty="MINCOLS:2")
	list   += GetListOfWaves(GetDeviceDataPath(panelTitle), DATA_CONFIG_REGEXP, waveProperty="MINCOLS:2")

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
static Function DM_GetRawDataFPType(panelTitle)
	string panelTitle

	return GetCheckboxState(panelTitle, "Check_Settings_UseDoublePrec") ? IGOR_TYPE_64BIT_FLOAT : IGOR_TYPE_32BIT_FLOAT
End

/// @brief Get the analysis function and the stimset from the headstage
///
/// We are called earlier than DAP_CheckSettings() so we can not rely on anything setup in a sane way.
///
/// @param[in]  panelTitle Device
/// @param[in]  headStage  Headstage
/// @param[in]  eventType  One of @ref EVENT_TYPE_ANALYSIS_FUNCTIONS
/// @param[out] func       Analysis function name
/// @param[out] setName    Name of the Stim set
static Function DM_GetAnalysisFuncFromHeadstage(panelTitle, headStage, eventType, func, setName)
	string panelTitle
	variable headStage, eventType
	string &func, &setName

	string ctrl, dacWave, setNameFromCtrl
	variable clampMode, DACchannel

	func    = ""
	setName = ""

	WAVE chanAmpAssign = GetChanAmpAssign(panelTitle)

	clampMode = DAP_MIESHeadstageMode(panelTitle, headStage)
	if(clampMode == V_CLAMP_MODE)
		DACchannel = ChanAmpAssign[%VC_DA][headStage]
	elseif(clampMode == I_CLAMP_MODE)
		DACchannel = ChanAmpAssign[%IC_DA][headStage]
	else
		return NaN
	endif

	if(!IsFinite(DACchannel))
		return NaN
	endif

	ctrl = GetPanelControl(DACchannel, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	setNameFromCtrl = GetPopupMenuString(panelTitle, ctrl)

	if(!cmpstr(setNameFromCtrl, NONE))
		return NaN
	endif

	WAVE/Z stimSet = WB_CreateAndGetStimSet(setNameFromCtrl)

	if(!WaveExists(stimSet))
		return NaN
	endif

	func    = ExtractAnalysisFuncFromStimSet(stimSet, eventType)
	setName = setNameFromCtrl
End
