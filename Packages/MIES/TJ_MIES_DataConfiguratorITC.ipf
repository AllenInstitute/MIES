#pragma rtGlobals=3		// Use modern global access method and strict wave access.

///@name Constants for DC_ConfigureDataForITC
///@{
CONSTANT DATA_ACQUISITION_MODE = 0
CONSTANT TEST_PULSE_MODE       = 1
///@}

///@name Constants shared with the ITC XOP
///@{
Constant ITC_XOP_CHANNEL_TYPE_ADC = 0
Constant ITC_XOP_CHANNEL_TYPE_DAC = 1
Constant ITC_XOP_CHANNEL_TYPE_TTL = 3
///@}

/// @brief Prepare test pulse/data acquisition
///
/// @param panelTitle  panel title
/// @param dataAcqOrTP one of DATA_ACQUISITION_MODE or TEST_PULSE_MODE
Function DC_ConfigureDataForITC(panelTitle, dataAcqOrTP)
	string panelTitle
	variable DataAcqOrTP

	ASSERT(dataAcqOrTP == DATA_ACQUISITION_MODE || dataAcqOrTP == TEST_PULSE_MODE, "invalid mode")

	DC_MakeITCConfigAllConfigWave(panelTitle)  
	DC_MakeITCConfigAllDataWave(panelTitle, DataAcqOrTP)  
	DC_MakeITCFIFOPosAllConfigWave(panelTitle)
	DC_MakeFIFOAvailAllConfigWave(panelTitle)

	DC_PlaceDataInITCChanConfigWave(panelTitle)
	DC_PlaceDataInITCDataWave(panelTitle)
	DC_PDInITCFIFOPositionAllCW(panelTitle) // PD = Place Data
	DC_PDInITCFIFOAvailAllCW(panelTitle)
End

//==========================================================================================

/// @brief The minimum sampling interval is determined by the rack with the most channels selected
///
/// Minimum sampling intervals are 5, 10, 15, 20 or 25 microseconds
Function DC_ITCMinSamplingInterval(panelTitle)
	string panelTitle

	variable Rack0DAMinInt, Rack0ADMinInt, Rack1DAMinInt, Rack1ADMinInt
	
	Rack0DAMinInt = DC_DAMinSampInt(0, panelTitle)
	Rack1DAMinInt = DC_DAMinSampInt(1, panelTitle)
	
	Rack0ADMinInt = DC_ADMinSampInt(0, panelTitle)
	Rack1ADMinInt = DC_ADMinSampInt(1, panelTitle)
	
	return max(max(Rack0DAMinInt,Rack1DAMinInt), max(Rack0ADMinInt,Rack1ADMinInt))
End

//==========================================================================================
Function DC_NoOfChannelsSelected(channelType, panelTitle) // channelType = DA, AD, or TTL
	string channelType, panelTitle

	return sum(DC_ControlStatusWave(panelTitle, channelType))
End


/// @brief Returns a list of the status of the checkboxes specified by ChannelType and ControlType
///
/// @deprecated use @ref DC_ControlStatusWave() instead
///
/// @param ChannelType  one of DA, AD, or TTL
/// @param ControlType  currently restricted to "Check"
/// @param panelTitle   panel title
Function/S DC_ControlStatusListString(ChannelType, ControlType, panelTitle)
	String ChannelType, panelTitle
	string ControlType

	variable TotalPossibleChannels = DC_GetNumberFromType(channelType)

	String ControlStatusList = ""
	String ControlName
	variable i
	
	i=0
	do
		sprintf ControlName, "%s_%s_%.2d", ControlType, ChannelType, i
		ControlInfo /w = $panelTitle $ControlName
		ControlStatusList = AddlistItem(num2str(v_value), ControlStatusList, ";",i)
		i+=1
	while(i <= (TotalPossibleChannels - 1))
	
	return ControlStatusList
End

Function DC_GetNumberFromType(channelType)
	string channelType

	strswitch(channelType)
		case "AsyncAD":
			return NUM_ASYNC_CHANNELS
			break
		case "DA":
		case "TTL":
			return NUM_DA_TTL_CHANNELS
			break
		case "DataAcq_HS":
			return NUM_HEADSTAGES
			break
		case "AD":
			return NUM_AD_CHANNELS
			break
		default:
			ASSERT(0, "invalid type")
			break
	endswitch

	return 0
End

/// @brief Returns a free wave of the status of the checkboxes specified by channelType
///
/// @param type        one of DA, AD, TTL, DataAcq_HS or AsyncAD
/// @param panelTitle  panel title
Function/Wave DC_ControlStatusWave(panelTitle, type)
	string type
	string panelTitle

	string ctrl
	variable i, numEntries

	numEntries = DC_GetNumberFromType(type)

	Make/FREE/U/B/N=(numEntries) wv

	for(i = 0; i < numEntries; i += 1)
		sprintf ctrl, "CHECK_%s_%.2d", type, i
		wv[i] = GetCheckboxState(panelTitle, ctrl)
	endfor

	return wv
End

//==========================================================================================
Function DC_ChanCalcForITCChanConfigWave(panelTitle)
	string panelTitle
	Variable NoOfDAChannelsSelected = DC_NoOfChannelsSelected("DA", panelTitle)
	Variable NoOfADChannelsSelected = DC_NoOfChannelsSelected("AD", panelTitle)
	Variable AreRack0FrontTTLsUsed = DC_AreTTLsInRackChecked(0,panelTitle)
	Variable AreRack1FrontTTLsUsed = DC_AreTTLsInRackChecked(1,panelTitle)
	Variable ChannelCount
	
	ChannelCount = NoOfDAChannelsSelected + NoOfADChannelsSelected + AreRack0FrontTTLsUsed + AreRack1FrontTTLsUsed
	
	return ChannelCount

END
//==========================================================================================
Function DC_AreTTLsInRackChecked(RackNo, panelTitle)
	variable RackNo
	string panelTitle
	variable a
	variable b
	string TTLsInUse = DC_ControlStatusListString("TTL", "Check",panelTitle)
	variable RackTTLStatus
	
	if(RackNo == 0)
		 a = 0
		 b = 3
	endif
	
	if(RackNo == 1)
		 a = 4
		 b = 7
	endif
	
	do
		If(str2num(stringfromlist(a,TTLsInUse,";")) == 1)
			RackTTLStatus = 1
			return RackTTLStatus
		endif
		a += 1
	while(a <= b)
	
	RackTTLStatus = 0
	return RackTTLStatus
End

//=========================================================================================

Function/s DC_PopMenuStringList(ChannelType, ControlType, panelTitle)// returns the list of selected waves in pop up menus
	string ChannelType, ControlType, panelTitle

	String ControlWaveList = ""
	String ControlName
	variable i, numEntries

	numEntries = DC_GetNumberFromType(channelType)
	for(i = 0; i < numEntries; i += 1)
		sprintf ControlName, "%s_%s_%.2d", ControlType, ChannelType, i
		ControlInfo /w = $panelTitle $ControlName
		ControlWaveList = AddlistItem(s_value, ControlWaveList, ";", i)
	endfor

	return ControlWaveList
End

//=========================================================================================
/// ttl and da channel types need to be passed into this and compared to determine longest wave
Function DC_LongestOutputWave(channelType, panelTitle)
	string channelType, panelTitle

	variable maxNumRows = 0, i, numEntries
	string channelTypeWaveList = DC_PopMenuStringList(channelType, "Wave", panelTitle)

	Wave statusHS = DC_ControlStatusWave(panelTitle, channelType)
	numEntries = DimSize(statusHS, ROWS)
	for(i = 0; i < numEntries; i += 1)
		if(!statusHS[i])
			continue
		endif

		Wave/Z/SDFR=IDX_GetSetFolderFromString(channelType) wv = $StringFromList(i, channelTypeWaveList)

		if(WaveExists(wv))
			maxNumRows = max(maxNumRows, DimSize(wv, ROWS))
		endif
	endfor

	return maxNumRows
End

//==========================================================================================
Function DC_CalculateITCDataWaveLength(panelTitle, DataAcqOrTP)// determines the longest output DA or DO wave. Divides it by the min sampling interval and quadruples its length (to prevent buffer overflow).
	string panelTitle
	variable DataAcqOrTP // 0 = DataAcq, 1 = TP
	Variable LongestSweep = DC_CalculateLongestSweep(panelTitle)
	// print "Longest sweep =", LongestSweep
	variable exponent = ceil(log(LongestSweep)/log(2))
	//exponent += 2
	if(DataAcqOrTP == 0)
	// print " data acq not TP exponent"
		exponent += 1 // round(5000 / LongestSweep) // buffer for sweep length
	endif
	
	if(exponent < 17)
		exponent = 17
	endif
	//print "exponent = ",exponent
	//print ceil(5000 / LongestSweep)
	//LongestWaveLength *= 5
	// print "DC_CalculateITCDataWaveLength =",(2^exponent), "exponent =", exponent
	return (2^exponent)
	//return round(LongestWaveLength)
end
//==========================================================================================

Function DC_CalculateLongestSweep(panelTitle) // returns the longest sweep in points
	string panelTitle
	variable LongestSweep
	
	if (DC_LongestOutputWave("DA", panelTitle) >= DC_LongestOutputWave("TTL", panelTitle))
		LongestSweep = DC_LongestOutputWave("DA", panelTitle)
	else
		LongestSweep = DC_LongestOutputWave("TTL", panelTitle)
	endif
	LongestSweep /= (DC_ITCMinSamplingInterval(panelTitle) / 5)
	
	return ceil(LongestSweep)
End
//==========================================================================================
Function DC_MakeITCConfigAllConfigWave(panelTitle)
	string panelTitle
	string ITCChanConfigPath = HSU_DataFullFolderPathString(panelTitle) + ":ITCChanConfigWave"
	Make /I /o /n = (DC_ChanCalcForITCChanConfigWave(panelTitle), 4) $ITCChanConfigPath
	wave /z ITCChanConfigWave = $ITCChanConfigPath
	ITCChanConfigWave = 0
End
//==========================================================================================

Function DC_MakeITCConfigAllDataWave(panelTitle, DataAcqOrTP)// config all refers to configuring all the channels at once
	string panelTitle
	variable DataAcqOrTP

	variable numRows, numCols

	DFREF dfr = GetDevicePath(panelTitle)
	numRows   = DC_CalculateITCDataWaveLength(panelTitle, DataAcqOrTP)
	numCols   = DC_ChanCalcForITCChanConfigWave(panelTitle)

	Make/W/O/N=(numRows, numCols) dfr:ITCDataWave/Wave=ITCDataWave

	FastOp ITCDataWave = 0
	SetScale/P x 0, DC_ITCMinSamplingInterval(panelTitle) / 1000, "ms", ITCDataWave
End

//==========================================================================================
Function DC_MakeITCFIFOPosAllConfigWave(panelTitle)//MakeITCUpdateFIFOPosAllConfigWave
	string panelTitle
	string ITCFIFOPosAllConfigWavePath = HSU_DataFullFolderPathString(panelTitle) + ":ITCFIFOPositionAllConfigWave"
	Make /I /o /n = (DC_ChanCalcForITCChanConfigWave(panelTitle), 4) $ITCFIFOPosAllConfigWavePath
	wave /z ITCFIFOPositionAllConfigWave = $ITCFIFOPosAllConfigWavePath
	ITCFIFOPositionAllConfigWave = 0
End
//==========================================================================================
Function DC_MakeFIFOAvailAllConfigWave(panelTitle)//MakeITCFIFOAvailAllConfigWave
	string panelTitle
	string ITCFIFOAvailAllConfigWavePath = HSU_DataFullFolderPathString(panelTitle) + ":ITCFIFOAvailAllConfigWave"
	Make /I /o /n = (DC_ChanCalcForITCChanConfigWave(panelTitle), 4) $ITCFIFOAvailAllConfigWavePath
	wave /z ITCFIFOAvailAllConfigWave = $ITCFIFOAvailAllConfigWavePath
	ITCFIFOAvailAllConfigWave = 0
End
//==========================================================================================

Function DC_PlaceDataInITCChanConfigWave(panelTitle)
	string panelTitle

	variable i, j, numEntries
	string ctrl, unitList = ""

	WAVE/SDFR=GetDevicePath(panelTitle) ITCChanConfigWave

	// query DA properties
	WAVE channelStatus = DC_ControlStatusWave(panelTitle, "DA")

	numEntries = DimSize(channelStatus, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!channelStatus[i])
			continue
		endif

		ITCChanConfigWave[j][0] = ITC_XOP_CHANNEL_TYPE_DAC
		ITCChanConfigWave[j][1] = i
		ctrl = IDX_GetChannelControl(panelTitle, i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
		unitList = AddListItem(GetSetVariableString(panelTitle, ctrl), unitList, ";", Inf)
		j += 1
	endfor

	// query AD properties
	WAVE channelStatus = DC_ControlStatusWave(panelTitle, "AD")

	numEntries = DimSize(channelStatus, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!channelStatus[i])
			continue
		endif

		ITCChanConfigWave[j][0] = ITC_XOP_CHANNEL_TYPE_ADC
		ITCChanConfigWave[j][1] = i
		ctrl = IDX_GetChannelControl(panelTitle, i, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
		unitList = AddListItem(GetSetVariableString(panelTitle, ctrl), unitList, ";", Inf)
		j += 1
	endfor

	Note ITCChanConfigWave, unitList

	// Place TTL config data
	if(DC_AreTTLsInRackChecked(0, panelTitle))
		ITCChanConfigWave[j][0] = ITC_XOP_CHANNEL_TYPE_TTL
		ITCChanConfigWave[j][1] = 0
		j += 1
	endif

	if(DC_AreTTLsInRackChecked(1, panelTitle))
		ITCChanConfigWave[j][0] = ITC_XOP_CHANNEL_TYPE_TTL
		ITCChanConfigWave[j][1] = 3
	endif

	ITCChanConfigWave[][2] = DC_ITCMinSamplingInterval(panelTitle)
	ITCChanConfigWave[][3] = 0
End

//==========================================================================================
/// @brief Places data from appropriate DA and TTL stimulus set(s) into ITCdatawave. 
/// Also records certain DA_Ephys GUI settings into sweepData and sweepTxTData
Function DC_PlaceDataInITCDataWave(panelTitle)
	string panelTitle

	variable i, col, headstage, numEntries
	string ChannelStatus
	DFREF deviceDFR = GetDevicePath(panelTitle)
	WAVE/SDFR=deviceDFR ITCDataWave = ITCDataWave

	string setNameList, setName, setNameFullPath
	string ctrl
	variable DAGain, DAScale, setColumn, insertStart, insertEnd, endRow, oneFullCycle, val
	variable/C ret
	variable GlobalTPInsert = GetCheckboxState(panelTitle, "Check_Settings_InsertTP")
	
	if(GlobalTPInsert) // param for global TP Insertion placed outside of for loop so that they are only called once	
		Wave ChannelClampMode = GetChannelClampMode(panelTitle)
		variable channelMode  = ChannelClampMode[i][0]
		variable TPDuration   = 2 * GetSetVariable(panelTitle, "SetVar_DataAcq_TPDuration")
		variable TPAmp
		variable TPStartPoint = x2pnt(ITCDataWave, TPDuration / 4)
		variable TPEndPoint   = x2pnt(ITCDataWave, TPDuration / 2) + TPStartPoint
		if(channelMode == V_CLAMP_MODE)
			TPAmp = GetSetVariable(panelTitle, "SetVar_DataAcq_TPAmplitude")
		elseif(channelMode == I_CLAMP_MODE)
			TPAmp = GetSetVariable(panelTitle, "SetVar_DataAcq_TPAmplitudeIC")
		endif
	endif
	
	string CountPath = HSU_DataFullFolderPathString(panelTitle) + ":count"
	// waves below are used to document the settings for each sweep
	Wave sweepData = DC_SweepDataWvRef(panelTitle)
	Wave/T sweepTxTData = DC_SweepDataTxtWvRef(panelTitle)
	sweepData = nan // empty the waves on each new sweep
	sweepTxTData = ""

	if(exists(CountPath) == 2)
		NVAR count = $CountPath
		setColumn = count - 1
	else
		setColumn = 0
	endif

	//Place DA waves into ITCDataWave
	variable DecimationFactor = DC_ITCMinSamplingInterval(panelTitle) / 5
	setNameList = DC_PopMenuStringList("DA", "Wave", panelTitle)
	WAVE statusDA = DC_ControlStatusWave(panelTitle, "DA")

	numEntries = DimSize(statusDA, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!statusDA[i])
			continue
		endif

		headstage = TP_HeadstageUsingDAC(panelTitle, i)
		ASSERT(IsFinite(headstage), "Non-finite headstage")

		sweepData[0][0][HeadStage] = i // document the DA channel

		ctrl = IDX_GetChannelControl(panelTitle, i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
		val = GetSetVariable(panelTitle, ctrl)
		DAGain = 3200 / val // 3200 = 1V, 3200/gain = bits per unit

		sweepData[0][2][HeadStage] = val // document the DA gain

		ctrl = IDX_GetChannelControl(panelTitle, i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
		DAScale = GetSetVariable(panelTitle, ctrl)

		sweepData[0][4][HeadStage] = DAScale // document the DA scale

		// get the wave name
		setName = StringFromList(i, setNameList)
		setNameFullPath = GetWBSvdStimSetDAPathAsString() + ":" + setName

		sweepTxTData[0][0][HeadStage] = setName // document the Set name

		ret = DC_CalculateChannelColumnNo(panelTitle, setName, i, 0)
		oneFullCycle = imag(ret)

		if(!cmpstr(setNameFullPath,"root:MIES:WaveBuilder:SavedStimulusSets:DA:testpulse"))
			setColumn   = 0
			insertStart = 0
			insertEnd   = 0
		else
			setColumn   = real(ret)
			if(col == 0)
				insertStart = DC_GlobalChangesToITCDataWave(panelTitle)
				insertEnd   = insertStart
			endif
		endif

		// checks if user wants to set scaling to 0 on sets that have already cycled once
		if(GetCheckboxState(panelTitle,  "check_Settings_ScalingZero") && (GetCheckboxState(panelTitle, "Check_DataAcq1_IndexingLocked") || !GetCheckboxState(panelTitle, "Check_DataAcq_Indexing")))
			// makes sure test pulse wave scaling is maintained
			if(cmpstr(setNameFullPath,"root:MIES:WaveBuilder:SavedStimulusSets:DA:testpulse") != 0)
				if(oneFullCycle) // checks if set has completed one full cycle
					DAScale = 0
				endif
			endif
		endif

		// resample the wave to min samp interval and place in ITCDataWave
		Wave stimSet = $setNameFullPath
		endRow = (DimSize(stimSet, ROWS) / DecimationFactor - 1) + insertEnd
		sweepData[0][5][HeadStage] = setColumn // document the set column

		Multithread ITCDataWave[insertStart, endRow][col] = (DAGain * DAScale) * stimSet[DecimationFactor * (p - insertStart)][setColumn]

		// Global TP insertion
		if(cmpstr(setNameFullPath,"root:MIES:WaveBuilder:SavedStimulusSets:DA:testpulse") != 0 && GlobalTPInsert)
			ITCDataWave[TPStartPoint, TPEndPoint][col] = TPAmp * DAGain
		endif
		
		// put the insert test pulse checkbox status into the sweep data wave
		sweepData[0][6][HeadStage] = GlobalTPInsert

		col += 1 // col determines what column of the ITCData wave the DAC wave is inserted into
	endfor

	WAVE statusAD = DC_ControlStatusWave(panelTitle, "AD")

	numEntries = DimSize(statusAD, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!statusAD[i])
			continue
		endif

		headstage = TP_HeadstageUsingADC(panelTitle, i)
		ASSERT(IsFinite(headstage), "Non-finite headstage")

		// document AD parameters into SweepData wave
		sweepData[0][1][headStage] = i // document the AD channel

		ctrl = IDX_GetChannelControl(panelTitle, i, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
		sweepData[0][3][headStage] = GetSetVariable(panelTitle, ctrl) // document the AD gain
	endfor

	// Place TTL waves into ITCDataWave
	if(DC_AreTTLsInRackChecked(0, panelTitle))
		DC_MakeITCTTLWave(0, panelTitle)
		WAVE/SDFR=deviceDFR TTLwave
		endRow = round(DimSize(TTLWave, ROWS) / DecimationFactor) - 1 + insertEnd
		ITCDataWave[insertStart, endRow][col] = TTLWave[DecimationFactor * (p - insertStart)]
		col += 1
	endif

	if(DC_AreTTLsInRackChecked(1, panelTitle))
		DC_MakeITCTTLWave(1, panelTitle)
		WAVE/SDFR=deviceDFR TTLwave
		endRow = round(DimSize(TTLWave, ROWS) / DecimationFactor) - 1 + insertEnd
		ITCDataWave[insertStart, endRow][col] = TTLWave[DecimationFactor * (p - insertStart)]
	endif
End

//=========================================================================================
Function DC_PDInITCFIFOPositionAllCW(panelTitle)//PlaceDataInITCFIFOPositionAllConfigWave()
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave ITCFIFOPositionAllConfigWave = $WavePath+":ITCFIFOPositionAllConfigWave" , ITCChanConfigWave = $WavePath+":ITCChanConfigWave"
	ITCFIFOPositionAllConfigWave[][0,1] = ITCChanConfigWave
	ITCFIFOPositionAllConfigWave[][2]=-1
	ITCFIFOPositionAllConfigWave[][3]=0
End
//=========================================================================================
Function DC_PDInITCFIFOAvailAllCW(panelTitle)//PlaceDataInITCFIFOAvailAllConfigWave()
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave ITCFIFOAvailAllConfigWave = $WavePath+":ITCFIFOAvailAllConfigWave", ITCChanConfigWave = $WavePath+":ITCChanConfigWave"
	ITCFIFOAvailAllConfigWave[][0,1] = ITCChanConfigWave
	ITCFIFOAvailAllConfigWave[][2] = 0
	ITCFIFOAvailAllConfigWave[][3] = 0
End
//=========================================================================================
Function DC_MakeITCTTLWave(RackNo, panelTitle)//makes single ttl wave for each rack. each ttl wave is added to the next after being multiplied by its bit number
	variable RackNo
	string panelTitle
	variable a, i, TTLChannelStatus,Code
	string TTLStatusString = DC_ControlStatusListString("TTL", "Check", panelTitle)
	string TTLWaveList = DC_PopMenuStringList("TTL", "Wave", panelTitle)
	string TTLWaveName
	string cmd
	string WavePath = HSU_DataFullFolderPathString(panelTitle)+":"//"root:MIES:WaveBuilder:savedStimulusSets:TTL:"// the ttl wave should really be located in the device folder not the wavebuilder folder
	string TTLWavePath = "root:MIES:WaveBuilder:savedStimulusSets:TTL:"
	if(RackNo == 0)
		a = 0
	endif
	
	if(RackNo == 1)
		a = 4
	endif
	
	code = 0
	i = 0
	
	do 
		TTLChannelStatus = str2num(stringfromlist(a,TTLStatusString,";"))
		Code = (((2 ^ i)) * TTLChannelStatus)
		TTLWaveName = stringfromlist(a,TTLWaveList,";")
		if(i == 0)
			TTLWaveName = TTLWavePath + TTLWaveName// 
			make /o /n = (dimsize($TTLWaveName,0)) $WavePath+"TTLWave" = 0// 
		endif
		
		if(TTLChannelStatus == 1)
			sprintf cmd, "%sTTLWave+=(%d)*(%s%s%d%s)" wavepath, code, TTLWaveName,"[p][",DC_CalculateChannelColumnNo(panelTitle, stringfromlist(a,TTLWaveList,";"),i,1),"]"
			execute cmd
		endif
		a += 1
		i += 1
	while( i <4)
End
//=========================================================================================
Function DC_DAMinSampInt(RackNo, panelTitle)
	variable RackNo
	string panelTitle

	variable a, i, DAChannelStatus,SampInt
	string DAStatusString = DC_ControlStatusListString("DA", "Check", panelTitle)
	
	a = RackNo*4
	
	SampInt = 0
	i = 0
	
	do 
		DAChannelStatus = str2num(stringfromlist(a,DAStatusString,";"))
		SampInt += 5*DAChannelStatus
		a += 1
		i += 1
	while(i < 4)
	
	return SampInt
End
//=========================================================================================
Function DC_ADMinSampInt(RackNo, panelTitle)
	variable RackNo
	string panelTitle

	variable a, i, ADChannelStatus, Bank1SampInt, Bank2SampInt
	string ADStatusString = DC_ControlStatusListString("AD", "Check",panelTitle)
	
	a = RackNo*8
	
	Bank1SampInt = 0
	Bank2SampInt = 0
	i = 0
	
	do 
		ADChannelStatus = str2num(stringfromlist(a,ADStatusString,";"))
		Bank1SampInt += 5 * ADChannelStatus
		a += 1
		i += 1
	while(i < 4)
	
	i = 0
	do 
		ADChannelStatus = str2num(stringfromlist(a,ADStatusString,";"))
		Bank2SampInt += 5 * ADChannelStatus
		a += 1
		i += 1
	while(i < 4)
	
	return max(Bank1SampInt,Bank2SampInt)
End
//=========================================================================================

// returns column number, independent of the times the set is being cycled through (as defined by SetVar_DataAcq_SetRepeats)
Function/c DC_CalculateChannelColumnNo(panelTitle, SetName, channelNo, DAorTTL)// setname is a string that contains the full wave path
	string panelTitle, SetName
	variable ChannelNo, DAorTTL
	variable ColumnsInSet = IDX_NumberOfTrialsInSet(panelTitle, SetName, DAorTTL)
	variable column
	variable CycleCount // when cycleCount = 1 the set has already cycled once.
	variable /c column_CycleCount
	variable localCount
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	string CountPath = WavePath +":Count"
	string AcitveSetCountPath = WavePath +":ActiveSetCount"
	//following string and wave apply when random set sequence is selected
	string SequenceWaveName = WavePath + ":" + SetName + num2str(daorttl) + num2str(channelNo) + "_S"//s is for sequence
	if(waveexists($SequenceWaveName) == 0)
		make /o /n = (ColumnsInSet) $SequenceWaveName = 0
		DC_shuffle( $SequenceWaveName)
	endif
	wave /z WorkingSequenceWave = $SequenceWaveName	
	// Below code calculates the variable local count which is then used to determine what column to select from a particular set
		if(exists(CountPath) == 2)// the global variable count is created at the initiation of the repeated aquisition functions and killed at their completion, 
							//thus the vairable "count" is used to determine if acquisition is on the first cycle
			NVAR count = $CountPath
			controlinfo /w = $panelTitle Check_DataAcq_Indexing// check indexing status
			if(v_value == 0)// if indexing is off...
				localCount = count
				cycleCount = 0
			else // else is used when indexing is on. The local count is now set length dependent
				controlinfo /w = $panelTitle Check_DataAcq1_IndexingLocked// check locked status. locked = popup menus on channels idex in lock - step
				if(v_value == 1)// indexing is locked
					NVAR ActiveSetCount = $AcitveSetCountPath
					controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet// how many columns in the largest currently selected set on all active channels
					localCount = v_value
					controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats// how many times does the user want the sets to repeat
					localCount *= v_value
					localCount -= ActiveSetCount// active set count keeps track of how many steps of the largest currently selected set on all active channels has been taken
				else //indexing is unlocked
					// calculate where in list global count is
					localCount = IDX_UnlockedIndexingStepNo(panelTitle, channelNo, DAorTTL, count)
				endif
			endif

	//Below code uses local count to determine  what step to use from the set based on the sweeps in cycle and sweeps in active set
			wave/z WorkingSequenceWave = $SequenceWaveName
			if(((localCount) / ColumnsInSet) < 1 || (localCount) == 0)// if remainder is less than 1, count is on 1st cycle
				controlinfo /w = $panelTitle check_DataAcq_RepAcqRandom
				if(v_value == 0) // set step sequence is not random
					column = localCount
					cycleCount = 0
				else // set step sequence is random
					if(localCount == 0)
						DC_shuffle(WorkingSequenceWave)
					endif
					column = WorkingSequenceWave[localcount]
					cycleCount = 0
				endif	
			else
				controlinfo /w = $panelTitle check_DataAcq_RepAcqRandom
				if(v_value == 0) // set step sequence is not random
					column = mod((localCount), columnsInSet)// set has been cyled through once or more, uses remainder to determine correct column
					cycleCount = 1
				else
					if(mod((localCount), columnsInSet) == 0)
						DC_shuffle(WorkingSequenceWave) // added to handle 1 channel, unlocked indexing
					endif
					column = WorkingSequenceWave[mod((localCount), columnsInSet)]
					cycleCount = 1
				endif
			endif
		else
			controlinfo /w = $panelTitle check_DataAcq_RepAcqRandom
			if(v_value == 0) // set step sequence is not random
				column = 0
			else
				make /o /n = (ColumnsInSet) $SequenceWaveName
				wave WorkingSequenceWave = $SequenceWaveName
				WorkingSequenceWave = x
				DC_shuffle(WorkingSequenceWave)
				column = WorkingSequenceWave[0]
			endif
		endif
	
	if(channelNo == 1)
		if(DAorTTL == 0)
		//print "DA channel 1 column = " + num2str(column)
		else
		//print "TTL channel 1 column = " + num2str(column)
		endif
		//print setname
	endif
	if(channelNo == 0)
		if(DAorTTL == 0)
		//print "DA channel 0 column = " + num2str(column)
		else
		//print "TTL channel 0 column = " + num2str(column)
		endif
		//print setname
	endif
	
	column_CycleCount = cmplx(column, cycleCount)
	return column_CycleCount
end

//below function was taken from: http://www.igorexchange.com/node/1614
//author s.r.chinn
Function DC_shuffle(inwave)	//	in-place random permutation of input wave elements
	wave inwave
	variable N	=	numpnts(inwave)
	variable i, j, emax, temp
	for(i = N; i>1; i-=1)
		emax = i / 2
		j =  floor(emax + enoise(emax))		//	random index
// 		emax + enoise(emax) ranges in random value from 0 to 2*emax = i
		temp		= inwave[j]
		inwave[j]		= inwave[i-1]
		inwave[i-1]	= temp
	endfor
end

Function DC_GlobalChangesToITCDataWave(panelTitle) // adjust the length of the ITCdataWave according to the global changes on the data acquisition tab - should only get called for non TP data acquisition cycles
	string panelTitle
	controlinfo /w = $panelTitle setvar_DataAcq_OnsetDelay
	variable OnsetDelay = round(v_value / (DC_ITCMinSamplingInterval(panelTitle) / 1000))
	controlinfo /w = $panelTitle setvar_DataAcq_TerminationDelay
	variable TerminationDelay = v_value / (DC_ITCMinSamplingInterval(panelTitle) / 1000)
	variable NewRows = round((OnsetDelay + TerminationDelay) * 5)
	string WavePath = HSU_DataFullFolderPathString(panelTitle) + ":"
	wave ITCDataWave = $WavePath + "ITCDataWave"
	variable ITCDataWaveRows = dimsize(ITCDataWave, 0)
	redimension /N = (ITCDataWaveRows + NewRows, -1, -1, -1) ITCDataWave
	return OnsetDelay
End

Function DC_ReturnTotalLengthIncrease(panelTitle)
	string panelTitle
	controlinfo /w = $panelTitle setvar_DataAcq_OnsetDelay
	variable OnsetDelay = v_value / (DC_ITCMinSamplingInterval(panelTitle) / 1000)
	controlinfo /w = $panelTitle setvar_DataAcq_TerminationDelay
	variable TerminationDelay = v_value / (DC_ITCMinSamplingInterval(panelTitle) / 1000)
	variable NewRows = round((OnsetDelay + TerminationDelay) * 5)
	return OnsetDelay + TerminationDelay
end

