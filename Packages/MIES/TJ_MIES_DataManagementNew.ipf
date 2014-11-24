#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static Constant FLOAT_32BIT = 0x02
static Constant FLOAT_64BIT = 0x04

Function DM_SaveITCData(panelTitle)
	string panelTitle

	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	wave ITCChanConfigWave = $WavePath + ":ITCChanConfigWave"
	variable sweepNo = GetSetVariable(panelTitle, "SetVar_Sweep")

	string savedDataWaveName = WavePath + ":Data:" + "Sweep_" +  num2str(sweepNo)
	string savedSetUpWaveName = WavePath + ":Data:" + "Config_Sweep_" + num2str(sweepNo)

	variable rowsToCopy = ITC_CalcDataAcqStopCollPoint(panelTitle)

	Duplicate/O/R=[0, rowsToCopy][] ITCDataWave $savedDataWaveName/Wave=dataWave
	Duplicate/O ITCChanConfigWave $savedSetUpWaveName
	note dataWave, Time() // adds time stamp to wave note
	getwindow kwFrameOuter wtitle 
	note dataWave, s_value
	ED_AppendCommentToDataWave(dataWave, panelTitle) // adds user comments as wave note

	if (GetCheckboxState(panelTitle, "check_Settings_SaveAmpSettings"))
		AI_createAmpliferSettingsWave(panelTitle, savedDataWaveName, SweepNo)
		// function for debugging
		// createDummySettingsWave(panelTitle, SavedDataWaveName, SweepNo)
	endif

	if(GetCheckboxState(panelTitle, "Check_Settings_Append")) // if option is checked, wave note containing single readings from (async) ADs is made
		ITC_ADDataBasedWaveNotes(dataWave, panelTitle)
	endif

	SetVariable SetVar_Sweep, Value = _NUM:(sweepNo + 1), limits={0, sweepNo + 1, 1}, win = $panelTitle

	Redimension/Y=(FLOAT_64BIT) dataWave

	DM_ADScaling(dataWave, panelTitle)
	DM_DAScaling(dataWave, panelTitle)

	//Add wave notes for the stim wave name and scale factor
	ED_createWaveNoteTags(panelTitle, savedDataWaveName, sweepNo)

	//Add wave notes for the factors on the Asyn tab
	ED_createAsyncWaveNoteTags(panelTitle, savedDataWaveName, sweepNo)
End

Function DM_CreateScaleTPHoldingWave(panelTitle)
	string panelTitle

	dfref testPulseDFR = GetDeviceTestPulse(panelTitle)

	NVAR/SDFR=testPulseDFR duration
	Wave/Z/SDFR=GetDevicePath(panelTitle) ITCDataWave

	ASSERT(WaveExists(ITCDataWave), "ITCDataWave is missing")
	ASSERT(Duration > 0, "duration is not strictly positive")
	ASSERT(DimSize(ITCDataWave, COLS) > 0, "Expected at least one headStage")

	Duplicate/O/R=[0, (duration * 2)][] ITCDataWave, testPulseDFR:TestPulseITC/Wave=TestPulseITC
	Redimension/D TestPulseITC
	DM_ADScaling(TestPulseITC, panelTitle)
End

Function DM_CreateScaleTPHoldWaveChunk(panelTitle,startPoint, NoOfPointsInTP)// TestPulseITC is the TP (test pulse) holding wave.
	string panelTitle
	variable startPoint, NoOfPointsInTP
	// variable RowsToCopy = (DC_CalculateLongestSweep(panelTitle)) / 99  // divide by 100 becuase there are 100 TPs
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	ITCDataWave[0][0] += 0
	variable RowsToCopy = ((NoOfPointsInTP) // / (deltax(ITCDataWave)/.005)  // DC_CalculateITCDataWaveLength(panelTitle) / 5
	string TestPulseITCPath = WavePath + ":TestPulse:TestPulseITC"
	startPoint += RowsToCopy / 4
	Duplicate /o /r = [startPoint,(startPoint + RowsToCopy)][] ITCDataWave $TestPulseITCPath
	//Duplicate /o /r = [((startPoint + RowsToCopy)/4),(((startPoint + RowsToCopy)/4)+(startPoint + RowsToCopy))][] ITCDataWave $TestPulseITCPath
	wave TestPulseITC = $TestPulseITCPath
	redimension /d TestPulseITC
	SetScale/P x 0,deltax(TestPulseITC),"ms", TestPulseITC
	DM_ADScaling(TestPulseITC, panelTitle)
End

Function DM_ADScaling(WaveToScale, panelTitle)
	wave WaveToScale
	string panelTitle

	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave ITCChanConfigWave = $WavePath + ":ITCChanConfigWave"
	string ADChannelList  =  SCOPE_RefToPullDatafrom2DWave(0,0, 1, ITCChanConfigWave)
	variable StartOfADColumns = DC_NoOfChannelsSelected("da", panelTitle)
	variable gain, i, numEntries, adc
	Wave ChannelClampMode    = GetChannelClampMode(panelTitle)
	Wave SweepData = DC_SweepDataWvRef(panelTitle)
	variable headstage
	string ctrl

	numEntries = ItemsInList(ADChannelList)
	for(i = 0; i < numEntries; i += 1)
		adc = str2num(StringFromList(i, ADChannelList))
		headstage = TP_HeadstageUsingADC(panelTitle, i)
	
		sprintf ctrl, "Gain_AD_%02d", i
		gain = GetSetVariable(panelTitle, ctrl)
	
		// document AD parameters into SweepData wave
		if(IsFinite(Headstage))
			SweepData[0][1][HeadStage] = i // document the AD channel
			SweepData[0][3][HeadStage] = gain // document the AD gain
		endif

		if(ChannelClampMode[adc][1] == V_CLAMP_MODE || ChannelClampMode[adc][1] == I_CLAMP_MODE)
			gain *= 3200
			WaveToScale[][(StartOfADColumns + i)] /= gain
		endif
	endfor
end

Function DM_DAScaling(WaveToScale, panelTitle)
	wave WaveToScale
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	wave ITCChanConfigWave = $WavePath + ":ITCChanConfigWave"
	variable NoOfDAColumns = DC_NoOfChannelsSelected("da", panelTitle)
	string DAChannelList  =  SCOPE_RefToPullDatafrom2DWave(1, 0, 1, ITCChanConfigWave)
	string DAGainControlName
	variable gain, i
	Wave ChannelClampMode    = GetChannelClampMode(panelTitle)

	for(i = 0; i < (itemsinlist(DAChannelList)); i += 1)
		if(str2num(stringfromlist(i, DAChannelList, ";")) < 10)
			DAGainControlName = "Gain_DA_0" + stringfromlist(i, DAChannelList, ";")
		else
			DAGainControlName = "Gain_DA_" + stringfromlist(i, DAChannelList, ";")
		endif
		controlinfo /w = $panelTitle $DAGainControlName
		gain = v_value

		if(ChannelClampMode[str2num(stringfromlist(i, DAChannelList,";"))][0] == V_CLAMP_MODE)
			WaveToScale[][i] /= 3200
			WaveToScale[][i] *= gain
		endif

		if(ChannelClampMode[str2num(stringfromlist(i, DAChannelList, ";"))][0] == I_CLAMP_MODE)
			WaveToScale[][i] /= 3200
			WaveToScale[][i] *= gain
		endif
	endfor

end

// Used after single trial of data aquisition - cannot be used when the same wave is output multiple times by the DAC
Function DM_ScaleITCDataWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)
	WAVE/SDFR=dfr ITCDataWave
	Redimension/D ITCDataWave

	DM_ADScaling(ITCDataWave,panelTitle)
end

Function DM_DeleteSettingsHistoryWaves(SweepNo,panelTitle)// deletes setting history waves "older" than SweepNo
	variable SweepNo
	string panelTitle
	variable i = 0
	
	DFREF saveDFR = GetDataFolderDFR()// creates a data folder reference that is later used to access the folder
	
	SetDataFolder GetDevicePath(panelTitle)
	string WavePath = GetDevicePathAsString(panelTitle)
	string ListOf_ChanAmpAssign_Sweep_x_Wv = wavelist("ChanAmpAssign_Sweep_*", ";","")
	string WaveNameUnderConsideration
	do
		WaveNameUnderConsideration = WavePath + ":" + stringfromlist(i, ListOf_ChanAmpAssign_Sweep_x_Wv, ";")
		if(itemsinlist(ListOf_ChanAmpAssign_Sweep_x_Wv) > 0)
		duplicate /free $WaveNameUnderConsideration WorkingWave
			if(WorkingWave[11][0] > SweepNo)
				killwaves /f /z $WaveNameUnderConsideration
			endif	
		endif
		i += 1
	while(i < itemsinlist(ListOf_ChanAmpAssign_Sweep_x_Wv))
	
	SetDataFolder saveDFR

End
//=============================================================================================================	
Function DM_ReturnLastSweepAcquired(panelTitle)
	string panelTitle
	
	string list

	list = GetListOfWaves(GetDeviceDataPath(panelTitle), DATA_SWEEP_REGEXP, options="MINCOLS:2")
	return ItemsInList(list) - 1
End
//=============================================================================================================
Function DM_IsLastSwpGreatrThnNxtSwp(panelTitle)
	string panelTitle
	variable NextSweep
	controlinfo /w = $panelTitle SetVar_Sweep
	NextSweep = v_value
	
	if(NextSweep > DM_ReturnLastSweepAcquired(panelTitle))
		return 0
	else
		return 1
	endif
End
//=============================================================================================================
Function DM_DeleteDataWaves(panelTitle, SweepNo)
	string panelTitle
	variable SweepNo
	variable i = SweepNo

	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder GetDeviceDataPath(panelTitle)

	string ListOfDataWaves = wavelist("Sweep_*", ";", "MINCOLS:2")
	string WaveNameUnderConsideration
	do
		WaveNameUnderConsideration = stringfromlist(i, ListOfDataWaves, ";")
		if(itemsinlist(ListOfDataWaves) > 0)
			killwaves /z /f $WaveNameUnderConsideration
		endif
		i+=1
	while(i < itemsinlist(ListOfDataWaves))

	i = SweepNo
	ListOfDataWaves = wavelist("Config_Sweep_*", ";", "MINCOLS:2")
	do
		WaveNameUnderConsideration = stringfromlist(i, ListOfDataWaves, ";")
		if(itemsinlist(ListOfDataWaves) > 0)
			killwaves /z /f $WaveNameUnderConsideration
		endif
		i += 1
	while(i < itemsinlist(ListOfDataWaves))

	SetDataFolder saveDFR
End

//=============================================================================================================
