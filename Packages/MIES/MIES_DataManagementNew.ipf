#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_DataManagementNew.ipf
/// @brief __DM__ Convert and scale acquired data

Function DM_SaveAndScaleITCData(panelTitle)
	string panelTitle

	variable sweepNo, rowsToCopy
	string savedDataWaveName, savedSetUpWaveName

	sweepNo = GetSetVariable(panelTitle, "SetVar_Sweep")

	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	Redimension/Y=(GetRawDataFPType(panelTitle)) ITCDataWave
	DM_ADScaling(ITCDataWave, panelTitle)
	DM_DAScaling(ITCDataWave, panelTitle)

	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)

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
Function DM_CallAnalysisFunctions(panelTitle, eventType)
	string panelTitle
	variable eventType

	variable error, i, valid_f1, valid_f2
	string func, setName

	if(GetCheckBoxState(panelTitle, "Check_Settings_SkipAnalysFuncs"))
		return NaN
	endif

	NVAR count = $GetCount(panelTitle)
	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	WAVE/T sweepDataTxTLNB = GetSweepSettingsTextWave(panelTitle)
	WAVE statusHS = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		if(!statusHS[i])
			continue
		endif

		switch(eventType)
			case PRE_DAQ_EVENT:
				func = sweepDataTxTLNB[0][5][i]
				break
			case MID_SWEEP_EVENT:
				func = sweepDataTxTLNB[0][6][i]
				break
			case POST_SWEEP_EVENT:
				func = sweepDataTxTLNB[0][7][i]
				break
			case POST_SET_EVENT:
				func = sweepDataTxTLNB[0][8][i]
				// we have to check if we acquired a full set for the headstage
				setName = sweepDataTxTLNB[0][0][i]

				if(mod(count + 1, IDX_NumberOfTrialsInSet(panelTitle, setName)) != 0)
					continue
				endif
				break
			case POST_DAQ_EVENT:
				func = sweepDataTxTLNB[0][9][i]
				break
			default:
				ASSERT(0, "Invalid eventType")
				break
		endswitch

		DEBUGPRINT("function", str=func)

		if(isEmpty(func))
			continue
		endif

		FUNCREF AF_PROTO_ANALYSIS_FUNC_V1 f1 = $func
		FUNCREF AF_PROTO_ANALYSIS_FUNC_V2 f2 = $func

		valid_f1 = FuncRefIsAssigned(FuncRefInfo(f1))
		valid_f2 = FuncRefIsAssigned(FuncRefInfo(f2))

		if(!valid_f1 && !valid_f2) // not a valid analysis function
			continue
		endif

		WAVE ITCDataWave = GetITCDataWave(panelTitle)
		SetWaveLock 1, ITCDataWave

		try
			if(valid_f1)
				f1(panelTitle, eventType, ITCDataWave, i); AbortOnRTE
			elseif(valid_f2)
				f2(panelTitle, eventType, ITCDataWave, i, stopCollectionPoint - 1); AbortOnRTE
			else
				ASSERT(0, "impossible case")
			endif
		catch
			error = GetRTError(1)
			printf "The analysis function %s aborted, this is dangerous and must *not* happen!\r", func
		endtry

		SetWaveLock 0, ITCDataWave
	endfor
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

Function DM_CreateScaleTPHoldingWave(panelTitle, [chunk])
	string panelTitle
	variable chunk

	variable length, first, last

	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	WAVE TestPulseITC = GetTestPulseITCWave(panelTitle)
	length = TP_GetTestPulseLengthInPoints(panelTitle)

	if(ParamIsDefault(chunk))
		chunk = 0
	endif

	first = chunk * length
	last  = first + length
	ASSERT(first >= 0 && last < DimSize(ITCDataWave, ROWS), "Invalid wave subrange")

	Duplicate/O/R=[first, last][] ITCDataWave, TestPulseITC
	Redimension/Y=(GetRawDataFPType(panelTitle)) TestPulseITC
	SetScale/P x, 0, DimDelta(TestPulseITC, ROWS), "ms", TestPulseITC
	DM_ADScaling(TestPulseITC, panelTitle)
End

static Function DM_ADScaling(WaveToScale, panelTitle)
	wave WaveToScale
	string panelTitle

	variable startOfADColumns
	variable gain, i, numEntries, adc

	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
	WAVE ADCs = GetADCListFromConfig(ITCChanConfigWave)
	Wave ChannelClampMode = GetChannelClampMode(panelTitle)
	WAVE DA_EphysGuiState = GetDA_EphysGuiStateNum(panelTitle)
	startOfADColumns = DimSize(GetDACListFromConfig(ITCChanConfigWave), ROWS)

	numEntries = DimSize(ADCs, ROWS)
	for(i = 0; i < numEntries; i += 1)
		adc = ADCs[i]

		gain = DA_EphysGuiState[adc][%ADGain]

		if(ChannelClampMode[adc][1] == V_CLAMP_MODE || ChannelClampMode[adc][1] == I_CLAMP_MODE)
			// w' = w  / (g * s)
			gain *= 3200
			MultiThread WaveToScale[][(startOfADColumns + i)] /= gain
		endif
	endfor
end

static Function DM_DAScaling(WaveToScale, panelTitle)
	wave WaveToScale
	string panelTitle

	variable gain, i, dac, numEntries
	DFREF deviceDFR       = GetDevicePath(panelTitle)
	Wave ChannelClampMode = GetChannelClampMode(panelTitle)
	WAVE DA_EphysGuiState = GetDA_EphysGuiStateNum(panelTitle)
	WAVE/SDFR=deviceDFR ITCDataWave, ITCChanConfigWave
	WAVE DACs = GetDACListFromConfig(ITCChanConfigWave)

	numEntries = DimSize(DACs, ROWS)
	for(i = 0; i < numEntries ; i += 1)
		dac  = DACs[i]

		gain = DA_EphysGuiState[dac][%DAGain]

		if(ChannelClampMode[dac][0] == V_CLAMP_MODE || ChannelClampMode[dac][0] == I_CLAMP_MODE)
			// w' = w * g / s
			gain /= 3200
			MultiThread WaveToScale[][i] *= gain
		endif
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
static Function GetRawDataFPType(panelTitle)
	string panelTitle

	return GetCheckboxState(panelTitle, "Check_Settings_UseDoublePrec") ? IGOR_TYPE_64BIT_FLOAT : IGOR_TYPE_32BIT_FLOAT
End
