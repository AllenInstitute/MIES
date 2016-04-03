#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_DataManagementNew.ipf
/// @brief __DM__ Convert and scale acquired data

Function DM_SaveAndScaleITCData(panelTitle)
	string panelTitle

	variable sweepNo, rowsToCopy
	string savedDataWaveName, savedSetUpWaveName, oscilloscopeSubwindow

	sweepNo = GetSetVariable(panelTitle, "SetVar_Sweep")
	oscilloscopeSubwindow = SCOPE_GetGraph(panelTitle)

	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	Redimension/Y=(DM_GetRawDataFPType(panelTitle)) ITCDataWave
	DM_ADScaling(ITCDataWave, panelTitle)
	DM_DAScaling(ITCDataWave, panelTitle)

	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	rowsToCopy = stopCollectionPoint - 1

	DM_UpdateOscilloscopeData(panelTitle, DATA_ACQUISITION_MODE, fifoPos=stopCollectionPoint)

	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)

	GetDeviceDataPath(panelTitle)
	savedDataWaveName = GetDeviceDataPathAsString(panelTitle)  + ":Sweep_" +  num2str(sweepNo)
	savedSetUpWaveName = GetDeviceDataPathAsString(panelTitle) + ":Config_Sweep_" + num2str(sweepNo)

	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	rowsToCopy = stopCollectionPoint - 1

	Duplicate/O/R=[0, rowsToCopy][] ITCDataWave $savedDataWaveName/Wave=dataWave
	Duplicate/O ITCChanConfigWave $savedSetUpWaveName/Wave=configWave
	note dataWave, Time()
	note dataWave, GetExperimentName()  + " - Igor Pro " + num2str(igorVersion())
	AppendMiesVersionToWaveNote(dataWave)

	SetVariable SetVar_Sweep, Value = _NUM:(sweepNo + 1), limits={0, sweepNo + 1, 1}, win = $panelTitle

	if(GetCheckboxState(panelTitle, "check_Settings_SaveAmpSettings"))
		AI_FillAndSendAmpliferSettings(panelTitle, sweepNo)
		// function for debugging
		// AI_createDummySettingsWave(panelTitle, SweepNo)
	endif

	if(GetCheckboxState(panelTitle, "Check_Settings_Append"))
		ED_createAsyncWaveNoteTags(panelTitle, sweepNo)
	endif

	// Add wave notes for the stim wave name and scale factor
	ED_createWaveNoteTags(panelTitle, sweepNo)

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

		GetAnalysisFuncFromHeadstage(panelTitle, i, eventType, func, setName)

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

	WAVE OscilloscopeData = GetOscilloscopeWave(panelTitle)
	WAVE ITCDataWave      = GetITCDataWave(panelTitle)

	if(dataAcqOrTP == TEST_PULSE_MODE)
		if(ParamIsDefault(chunk))
			chunk = 0
		endif

		ASSERT(ParamIsDefault(fifoPos), "optional parameter fifoPos is not possible with TEST_PULSE_MODE")

		length = TP_GetTestPulseLengthInPoints(panelTitle, REAL_SAMPLING_INTERVAL_TYPE)
		first  = chunk * length
		last   = first + length - 1
		ASSERT(first >= 0 && last < DimSize(ITCDataWave, ROWS) && first < last, "Invalid wave subrange")

		Multithread OscilloscopeData[][] = ITCDataWave[first + p][q]
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

		Multithread OscilloscopeData[0, fifoPos - 1][] = ITCDataWave[p][q]
	else
		ASSERT(0, "Invalid dataAcqOrTP value")
	endif

	DM_ADScaling(OscilloscopeData, panelTitle)
End

static Function DM_ADScaling(WaveToScale, panelTitle)
	wave WaveToScale
	string panelTitle

	variable startOfADColumns
	variable gain, i, numEntries, adc

	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
	WAVE ADCs = GetADCListFromConfig(ITCChanConfigWave)
	WAVE DA_EphysGuiState = GetDA_EphysGuiStateNum(panelTitle)
	startOfADColumns = DimSize(GetDACListFromConfig(ITCChanConfigWave), ROWS)

	numEntries = DimSize(ADCs, ROWS)
	for(i = 0; i < numEntries; i += 1)
		adc = ADCs[i]

		// w' = w  / (g * s)
		gain  = DA_EphysGuiState[adc][%ADGain]
		gain *= HARDWARE_ITC_BITS_PER_VOLT
		MultiThread WaveToScale[][(startOfADColumns + i)] /= gain
	endfor
end

static Function DM_DAScaling(WaveToScale, panelTitle)
	wave WaveToScale
	string panelTitle

	variable gain, i, dac, numEntries

	WAVE DA_EphysGuiState = GetDA_EphysGuiStateNum(panelTitle)
	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
	WAVE DACs = GetDACListFromConfig(ITCChanConfigWave)

	numEntries = DimSize(DACs, ROWS)
	for(i = 0; i < numEntries ; i += 1)
		dac  = DACs[i]

		// w' = w * g / s
		gain  = DA_EphysGuiState[dac][%DAGain]
		gain /= HARDWARE_ITC_BITS_PER_VOLT
		MultiThread WaveToScale[][i] *= gain
	endfor
end

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
static Function GetAnalysisFuncFromHeadstage(panelTitle, headStage, eventType, func, setName)
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
