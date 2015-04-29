#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @brief Prepare test pulse/data acquisition
///
/// @param panelTitle  panel title
/// @param dataAcqOrTP one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
Function DC_ConfigureDataForITC(panelTitle, dataAcqOrTP)
	string panelTitle
	variable dataAcqOrTP

	variable numADCs
	ASSERT(dataAcqOrTP == DATA_ACQUISITION_MODE || dataAcqOrTP == TEST_PULSE_MODE, "invalid mode")

	DC_MakeITCConfigAllConfigWave(panelTitle)
	DC_MakeITCDataWave(panelTitle, DataAcqOrTP)
	DC_MakeITCFIFOPosAllConfigWave(panelTitle)
	DC_MakeFIFOAvailAllConfigWave(panelTitle)

	DC_PlaceDataInITCChanConfigWave(panelTitle)
	DC_PlaceDataInITCDataWave(panelTitle)
	DC_PDInITCFIFOPositionAllCW(panelTitle) // PD = Place Data
	DC_PDInITCFIFOAvailAllCW(panelTitle)

	if(dataAcqOrTP == TEST_PULSE_MODE)
		WAVE/SDFR=GetDevicePath(panelTitle) ITCChanConfigWave
		numADCs = ItemsInList(GetADCListFromConfig(ITCChanConfigWave))

		NVAR tpBufferSize = $GetTPBufferSizeGlobal(panelTitle)
		DFREF dfr = GetDeviceTestPulse(panelTitle)
		Make/O/N=(tpBufferSize, numADCs) dfr:TPBaselineBuffer = NaN
		Make/O/N=(tpBufferSize, numADCs) dfr:TPInstBuffer     = NaN
		Make/O/N=(tpBufferSize, numADCs) dfr:TPSSBuffer       = NaN
	endif
End

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

/// @brief Return the number of channels of the given type
Function DC_NoOfChannelsSelected(channelType, panelTitle)
	string channelType, panelTitle

	return sum(DC_ControlStatusWave(panelTitle, channelType))
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

	numEntries = GetNumberFromChannelType(type)

	Make/FREE/U/B/N=(numEntries) wv

	for(i = 0; i < numEntries; i += 1)
		sprintf ctrl, "CHECK_%s_%.2d", type, i
		wv[i] = GetCheckboxState(panelTitle, ctrl)
	endfor

	return wv
End

/// @brief Returns the total number of combined channel types (DA, AD, and front TTLs) selected in the DA_Ephys Gui
///
/// @param panelTitle  panel title
static Function DC_ChanCalcForITCChanConfigWave(panelTitle)
	string panelTitle

	variable NoOfDAChannelsSelected = DC_NoOfChannelsSelected("DA", panelTitle)
	variable NoOfADChannelsSelected = DC_NoOfChannelsSelected("AD", panelTitle)
	variable AreRack0FrontTTLsUsed = DC_AreTTLsInRackChecked(0,panelTitle)
	variable AreRack1FrontTTLsUsed = DC_AreTTLsInRackChecked(1,panelTitle)

	return NoOfDAChannelsSelected + NoOfADChannelsSelected + AreRack0FrontTTLsUsed + AreRack1FrontTTLsUsed
END

/// @brief Returns the ON/OFF status of the front TTLs on a specified rack.
///
/// @param RackNo Only the ITC1600 can have two racks. For all other ITC devices RackNo = 0
/// @param panelTitle  panel title
static Function DC_AreTTLsInRackChecked(RackNo, panelTitle)
	variable RackNo
	string panelTitle

	variable a
	variable b
	WAVE statusTTL = DC_ControlStatusWave(panelTitle, "TTL")

	if(RackNo == 0)
		 a = 0
		 b = 3
	endif

	if(RackNo == 1)
		 a = 4
		 b = 7
	endif

	do
		if(statusTTL[a])
			return 1
		endif
		a += 1
	while(a <= b)

	return 0
End

/// @brief Returns the list of selected waves in pop up menus
///
/// @param ChannelType DA, AD or TTL
/// @param ControlType Igor control type. Ex. popupmenu
/// @param panelTitle  panel title
static Function/s DC_PopMenuStringList(ChannelType, ControlType, panelTitle)
	string ChannelType, ControlType, panelTitle

	String ControlWaveList = ""
	String ControlName
	variable i, numEntries

	numEntries = GetNumberFromChannelType(channelType)
	for(i = 0; i < numEntries; i += 1)
		sprintf ControlName, "%s_%s_%.2d", ControlType, ChannelType, i
		ControlInfo/W=$panelTitle $ControlName
		ControlWaveList = AddlistItem(s_value, ControlWaveList, ";", i)
	endfor

	return ControlWaveList
End

/// @brief Returns the output wave with the most points (rows)
///
/// @param channelType channel type Ex. DA, AD, or TTL
/// @param panelTitle  panel title
static Function DC_LongestOutputWave(channelType, panelTitle)
	string channelType, panelTitle

	variable maxNumRows = 0, i, numEntries
	string channelTypeWaveList = DC_PopMenuStringList(channelType, "Wave", panelTitle)

	Wave status = DC_ControlStatusWave(panelTitle, channelType)
	numEntries = DimSize(status, ROWS)
	for(i = 0; i < numEntries; i += 1)
		if(!status[i])
			continue
		endif

		Wave/Z/SDFR=IDX_GetSetFolderFromString(channelType) wv = $StringFromList(i, channelTypeWaveList)

		if(WaveExists(wv))
			maxNumRows = max(maxNumRows, DimSize(wv, ROWS))
		endif
	endfor

	return maxNumRows
End

//// @brief Calculate the required length of the ITCDataWave
///
/// The ITCdatawave length = 2^x where is the first integer large enough to contain the longest output wave plus one.
/// X also has a minimum value of 17 to ensure sufficient time for communication with the ITC device to prevent FIFO overflow or underrun.
///
/// @param panelTitle  panel title
/// @param dataAcqOrTP acquisition mode, one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_CalculateITCDataWaveLength(panelTitle, DataAcqOrTP)
	string panelTitle
	variable dataAcqOrTP

	variable LongestSweep = DC_CalculateLongestSweep(panelTitle)
	variable exponent = ceil(log(LongestSweep)/log(2))

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		exponent += 1
	endif

	if(exponent < 17)
		exponent = 17
	endif

	return (2^exponent)
end

/// @brief Returns the longest sweep in a stimulus set across all active DA and TTL channels.
///
/// @param panelTitle  panel title
/// @return number of data points, *not* time
Function DC_CalculateLongestSweep(panelTitle)
	string panelTitle

	variable longestSweep

	longestSweep  = max(DC_LongestOutputWave("DA", panelTitle), DC_LongestOutputWave("TTL", panelTitle))
	longestSweep /= DC_ITCMinSamplingInterval(panelTitle) / 5

	return ceil(longestSweep)
End

/// @brief Creates the ITCConfigALLConfigWave used to configure channels the ITC device
///
/// @param panelTitle  panel title
static Function DC_MakeITCConfigAllConfigWave(panelTitle)
	string panelTitle

	DFREF dfr = GetDevicePath(panelTitle)
	Make/I/O/N=(DC_ChanCalcForITCChanConfigWave(panelTitle), 4) dfr:ITCChanConfigWave/Wave=wv
	wv = 0
End

/// @brief Creates ITCDataWave; The wave that the ITC device takes DA and TTL data from and passes AD data to for all channels.
///
/// Config all refers to configuring all the channels at once
///
/// @param panelTitle  panel title
/// @param DataAcqOrTP one for data acquisition, zero for test pulse
static Function DC_MakeITCDataWave(panelTitle, DataAcqOrTP)
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

/// @brief Creates ITCFIFOPosAllConfigWave, the wave used to configure the FIFO on all channels of the ITC device
///
/// @param panelTitle  panel title
static Function DC_MakeITCFIFOPosAllConfigWave(panelTitle)
	string panelTitle
	DFREF dfr = GetDevicePath(panelTitle)
	Make/I/O/N=(DC_ChanCalcForITCChanConfigWave(panelTitle), 4) dfr:ITCFIFOPositionAllConfigWave/Wave=wv
	wv = 0
End

/// @brief Creates the ITCFIFOAvailAllConfigWave used to recieve FIFO position data
///
/// @param panelTitle  panel title
static Function DC_MakeFIFOAvailAllConfigWave(panelTitle)
	string panelTitle
	DFREF dfr = GetDevicePath(panelTitle)
	Make/I/O/N=(DC_ChanCalcForITCChanConfigWave(panelTitle), 4) dfr:ITCFIFOAvailAllConfigWave/Wave=wv
	wv = 0
End

/// @brief Places channel (DA, AD, and TTL) settings data into ITCChanConfigWave
///
/// @param panelTitle  panel title
static Function DC_PlaceDataInITCChanConfigWave(panelTitle)
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
		ctrl = GetPanelControl(panelTitle, i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
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
		ctrl = GetPanelControl(panelTitle, i, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
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

/// @brief Places data from appropriate DA and TTL stimulus set(s) into ITCdatawave.
/// Also records certain DA_Ephys GUI settings into sweepData and sweepTxTData
/// @param panelTitle  panel title
static Function DC_PlaceDataInITCDataWave(panelTitle)
	string panelTitle

	variable i, col, headstage, numEntries, isTestPulse
	DFREF deviceDFR = GetDevicePath(panelTitle)
	WAVE/SDFR=deviceDFR ITCDataWave

	string setNameList, setName
	string ctrl, comment
	variable DAGain, DAScale, setColumn, insertStart, insertEnd, endRow, oneFullCycle, val
	variable channelMode, TPDuration, TPAmpVClamp, TPAmpIClamp, TPStartPoint, TPEndPoint
	variable GlobalTPInsert, ITI, scalingZero, indexingLocked, indexing
	variable/C ret

	globalTPInsert  = GetCheckboxState(panelTitle, "Check_Settings_InsertTP")
	ITI             = GetSetVariable(panelTitle, "SetVar_DataAcq_ITI")
	scalingZero     = GetCheckboxState(panelTitle,  "check_Settings_ScalingZero")
	indexingLocked  = GetCheckboxState(panelTitle, "Check_DataAcq1_IndexingLocked")
	indexing        = GetCheckboxState(panelTitle, "Check_DataAcq_Indexing")
	comment         = GetSetVariableString(panelTitle, "SetVar_DataAcq_Comment")

	if(globalTPInsert)
		Wave ChannelClampMode = GetChannelClampMode(panelTitle)
		TPDuration   = 2 * GetSetVariable(panelTitle, "SetVar_DataAcq_TPDuration")
		TPAmpVClamp  = GetSetVariable(panelTitle, "SetVar_DataAcq_TPAmplitude")
		TPAmpIClamp  = GetSetVariable(panelTitle, "SetVar_DataAcq_TPAmplitudeIC")
		TPStartPoint = x2pnt(ITCDataWave, TPDuration / 4)
		TPEndPoint   = x2pnt(ITCDataWave, TPDuration / 2) + TPStartPoint
	endif

	// waves below are used to document the settings for each sweep
	Wave sweepData = DC_SweepDataWvRef(panelTitle)
	Wave/T sweepTxTData = DC_SweepDataTxtWvRef(panelTitle)
	sweepData = NaN // empty the waves on each new sweep
	sweepTxTData = ""

	NVAR/Z/SDFR=GetDevicePath(panelTitle) count
	if(NVAR_exists(count))
		setColumn = count - 1
	else
		setColumn = 0
	endif

	//Place DA waves into ITCDataWave
	variable decimationFactor = DC_ITCMinSamplingInterval(panelTitle) / 5
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

		ctrl = GetPanelControl(panelTitle, i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
		val = GetSetVariable(panelTitle, ctrl)
		DAGain = 3200 / val // 3200 = 1V, 3200/gain = bits per unit

		sweepData[0][2][HeadStage] = val // document the DA gain

		ctrl = GetPanelControl(panelTitle, i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
		DAScale = GetSetVariable(panelTitle, ctrl)

		sweepData[0][4][HeadStage] = DAScale // document the DA scale

		setName = StringFromList(i, setNameList)
		isTestPulse = TP_IsTestPulseSet(setName)

		sweepTxTData[0][0][HeadStage] = setName
		sweepTxTData[0][1][HeadStage] = comment

		ctrl = GetPanelControl(panelTitle, i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
		sweepTxTData[0][2][HeadStage] = GetSetVariableString(panelTitle, ctrl)

		if(isTestPulse)
			setColumn   = 0
			insertStart = 0
			insertEnd   = 0
		else
			// only call DC_CalculateChannelColumnNo for real data acquisition
			ret = DC_CalculateChannelColumnNo(panelTitle, setName, i, DATA_ACQUISITION_MODE)
			oneFullCycle = imag(ret)
			setColumn   = real(ret)
			if(col == 0)
				insertStart = DC_GlobalChangesToITCDataWave(panelTitle)
				insertEnd   = insertStart
			endif
		endif

		// checks if user wants to set scaling to 0 on sets that have already cycled once
		if(scalingZero && (indexingLocked || !indexing))
			// makes sure test pulse wave scaling is maintained
			if(!isTestPulse)
				if(oneFullCycle) // checks if set has completed one full cycle
					DAScale = 0
				endif
			endif
		endif

		// resample the wave to min samp interval and place in ITCDataWave
		Wave/SDFR=GetWBSvdStimSetDAPath() stimSet = $setName
		endRow = (DimSize(stimSet, ROWS) / decimationFactor - 1) + insertEnd
		sweepData[0][5][HeadStage] = setColumn // document the set column

		Multithread ITCDataWave[insertStart, endRow][col] = (DAGain * DAScale) * stimSet[DecimationFactor * (p - insertStart)][setColumn]

		// Global TP insertion
		if(!isTestPulse && globalTPInsert)
			channelMode  = ChannelClampMode[i][%DAC]
			if(channelMode == V_CLAMP_MODE)
				ITCDataWave[TPStartPoint, TPEndPoint][col] = TPAmpVClamp * DAGain
			elseif(channelMode == I_CLAMP_MODE)
				ITCDataWave[TPStartPoint, TPEndPoint][col] = TPAmpIClamp * DAGain
			else
				ASSERT(0, "Unknown clamp mode")
			endif
		endif

		// put the insert test pulse checkbox status into the sweep data wave
		sweepData[0][6][HeadStage] = GlobalTPInsert
		sweepData[0][7][HeadStage] = ITI

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

		ctrl = GetPanelControl(panelTitle, i, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
		sweepData[0][3][headStage] = GetSetVariable(panelTitle, ctrl) // document the AD gain

		ctrl = GetPanelControl(panelTitle, i, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
		sweepTxTData[0][3][HeadStage] = GetSetVariableString(panelTitle, ctrl)
	endfor

	// Place TTL waves into ITCDataWave
	if(DC_AreTTLsInRackChecked(0, panelTitle))
		DC_MakeITCTTLWave(0, panelTitle)
		WAVE/SDFR=deviceDFR TTLwave
		endRow = round(DimSize(TTLWave, ROWS) / decimationFactor) - 1 + insertEnd
		ITCDataWave[insertStart, endRow][col] = TTLWave[decimationFactor * (p - insertStart)]
		col += 1
	endif

	if(DC_AreTTLsInRackChecked(1, panelTitle))
		DC_MakeITCTTLWave(1, panelTitle)
		WAVE/SDFR=deviceDFR TTLwave
		endRow = round(DimSize(TTLWave, ROWS) / decimationFactor) - 1 + insertEnd
		ITCDataWave[insertStart, endRow][col] = TTLWave[decimationFactor * (p - insertStart)]
	endif
End

/// @brief Populates the ITCFIFOPositionAllConfigWave
///
/// @param panelTitle  panel title
static Function DC_PDInITCFIFOPositionAllCW(panelTitle)
	string panelTitle

	WAVE ITCFIFOPositionAllConfigWave = GetITCFIFOPositionAllConfigWave(panelTitle)
	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)

	ITCFIFOPositionAllConfigWave[][0,1] = ITCChanConfigWave
	ITCFIFOPositionAllConfigWave[][2]   = -1
	ITCFIFOPositionAllConfigWave[][3]   = 0
End

/// @brief Populates the ITCFIFOAvailAllConfigWave
///
/// @param panelTitle  panel title
static Function DC_PDInITCFIFOAvailAllCW(panelTitle)
	string panelTitle

	WAVE ITCFIFOAvailAllConfigWave = GetITCFIFOAvailAllConfigWave(panelTitle)
	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)

	ITCFIFOAvailAllConfigWave[][0,1] = ITCChanConfigWave
	ITCFIFOAvailAllConfigWave[][2]   = 0
	ITCFIFOAvailAllConfigWave[][3]   = 0
End

/// @brief Combines the TTL stimulus sweeps across different TTL channels into a single wave
///
/// Makes single ttl wave for each rack. each ttl wave is added to the next after being multiplied by its bit number
///
/// @param RackNo Front TTL rack (break out box) number of ITC devices. Only the ITC1600 has two racks, rack 0 and rack 1. Rack number for all other devices is zero.
/// @param panelTitle  panel title
static Function DC_MakeITCTTLWave(RackNo, panelTitle)
	variable RackNo
	string panelTitle

	variable a, i, channelStatus, col
	variable needsInitialization = 1

	WAVE statusTTL = DC_ControlStatusWave(panelTitle, "TTL")
	string TTLWaveList = DC_PopMenuStringList("TTL", "Wave", panelTitle)
	DFREF setDFR    = GetWBSvdStimSetTTLPath()
	DFREF deviceDFR = GetDevicePath(panelTitle)

	if(RackNo == 0)
		a = 0
	endif

	if(RackNo == 1)
		a = 4
	endif

	for(i = 0; i < 4; i +=1, a += 1)

		if(!statusTTL[a])
			continue
		endif

		WAVE/SDFR=setDFR TTLStimSet = $StringFromList(a, TTLWaveList)
		// assumes that the first active stim set is the largest one
		if(needsInitialization)
			Make/O/N=(DimSize(TTLStimSet, ROWS)) deviceDFR:TTLWave/Wave=TTLWave
			needsInitialization = 0
		else
			WAVE/SDFR=deviceDFR TTLWave
		endif

		col = DC_CalculateChannelColumnNo(panelTitle, StringFromList(a, TTLWaveList), i, TEST_PULSE_MODE)
		TTLWave += (2^i) * TTLStimSet[p][col]
	endfor
End

/// @brief Returns the minimum possible sampling interval of the ITC device based on the number of active DA channels.
///
/// @param rackNo      Front TTL rack (break out box) number of ITC devices. Only the ITC1600 has two racks,
///                    rack 0 and rack 1. Rack number for all other devices is zero.
/// @param panelTitle  panel title
static Function DC_DAMinSampInt(rackNo, panelTitle)
	variable rackNo
	string panelTitle

	variable a, i, sampInt
	WAVE statusDA = DC_ControlStatusWave(panelTitle, "DA")

	a = RackNo * 4

	do
		sampInt += 5 * statusDA[a]
		a += 1
		i += 1
	while(i < 4)

	return sampInt
End

/// @brief Returns the minimum possible sampling interval of the ITC device based on the number of active AD channels.
///
/// @param RackNo      Front TTL rack (break out box) number of ITC devices. Only the ITC1600 has two racks,
///                    rack 0 and rack 1. Rack number for all other devices is zero.
/// @param panelTitle  panel title
static Function DC_ADMinSampInt(RackNo, panelTitle)
	variable RackNo
	string panelTitle

	variable a, i, Bank1SampInt, Bank2SampInt
	WAVE statusAD = DC_ControlStatusWave(panelTitle, "AD")

	a = RackNo*8

	do
		Bank1SampInt += 5 * statusAD[a]
		a += 1
		i += 1
	while(i < 4)

	do
		Bank2SampInt += 5 * statusAD[a]
		a += 1
		i += 1
	while(i < 4)

	return max(Bank1SampInt, Bank2SampInt)
End

/// @brief Returns column number/step of the stimulus set, independent of the times the set is being cycled through
///        (as defined by SetVar_DataAcq_SetRepeats)
///
/// @param panelTitle panel title
/// @param SetName    A string that contains the path and name of the stimulus set.
/// @param channelNo  The DA or TTL channel number
/// @param DAorTTL    The channel type. DA = 0. TTL = 1
static Function/C DC_CalculateChannelColumnNo(panelTitle, SetName, channelNo, DAorTTL)
	string panelTitle, SetName
	variable ChannelNo, DAorTTL

	variable ColumnsInSet = IDX_NumberOfTrialsInSet(panelTitle, SetName, DAorTTL)
	variable column
	variable CycleCount // when cycleCount = 1 the set has already cycled once.
	variable localCount
	string sequenceWaveName

	DFREF devicePath = GetDevicePath(panelTitle)
	NVAR/Z/SDFR=devicePath count

	// wave exists only if random set sequence is selected
	sequenceWaveName = SetName + num2str(DAorTTL) + num2str(channelNo) + "_S"
	WAVE/Z/SDFR=devicePath WorkingSequenceWave = $sequenceWaveName

	// Below code calculates the variable local count which is then used to determine what column to select from a particular set
	if(NVAR_exists(count))// the global variable count is created at the initiation of the repeated aquisition functions and killed at their completion,
		//thus the vairable "count" is used to determine if acquisition is on the first cycle
		ControlInfo/W=$panelTitle Check_DataAcq_Indexing // check indexing status
		if(v_value == 0)// if indexing is off...
			localCount = count
			cycleCount = 0
		else // else is used when indexing is on. The local count is now set length dependent
			ControlInfo/W=$panelTitle Check_DataAcq1_IndexingLocked // check locked status. locked = popup menus on channels idex in lock - step
			if(v_value == 1)// indexing is locked
				NVAR/SDFR=GetDevicePath(panelTitle) ActiveSetCount
				ControlInfo/W=$panelTitle valdisp_DataAcq_SweepsActiveSet // how many columns in the largest currently selected set on all active channels
				localCount = v_value
				ControlInfo/W=$panelTitle SetVar_DataAcq_SetRepeats // how many times does the user want the sets to repeat
				localCount *= v_value
				localCount -= ActiveSetCount // active set count keeps track of how many steps of the largest currently selected set on all active channels has been taken
			else //indexing is unlocked
				// calculate where in list global count is
				localCount = IDX_UnlockedIndexingStepNo(panelTitle, channelNo, DAorTTL, count)
			endif
		endif

		//Below code uses local count to determine  what step to use from the set based on the sweeps in cycle and sweeps in active set
		if(((localCount) / ColumnsInSet) < 1 || (localCount) == 0) // if remainder is less than 1, count is on 1st cycle
			ControlInfo/W=$panelTitle check_DataAcq_RepAcqRandom
			if(v_value == 0) // set step sequence is not random
				column = localCount
				cycleCount = 0
			else // set step sequence is random
				if(localCount == 0)
					InPlaceRandomShuffle(WorkingSequenceWave)
				endif
				column = WorkingSequenceWave[localcount]
				cycleCount = 0
			endif
		else
			ControlInfo/W=$panelTitle check_DataAcq_RepAcqRandom
			if(v_value == 0) // set step sequence is not random
				column = mod((localCount), columnsInSet) // set has been cyled through once or more, uses remainder to determine correct column
				cycleCount = 1
			else
				if(mod((localCount), columnsInSet) == 0)
					InPlaceRandomShuffle(WorkingSequenceWave) // added to handle 1 channel, unlocked indexing
				endif
				column = WorkingSequenceWave[mod((localCount), columnsInSet)]
				cycleCount = 1
			endif
		endif
	else
		ControlInfo/W=$panelTitle check_DataAcq_RepAcqRandom
		if(v_value == 0) // set step sequence is not random
			column = 0
		else
			Make/O/N=(ColumnsInSet) devicePath:$SequenceWaveName/Wave=WorkingSequenceWave = x
			InPlaceRandomShuffle(WorkingSequenceWave)
			column = WorkingSequenceWave[0]
		endif
	endif

	return cmplx(column, cycleCount)
End

/// @brief Adjust the length of the ITCdataWave according to the onset and termination delay set on the data acquisition tab of the DA_Ephys panel
///
/// Only gets called for data acquisition cycles (non TP).
/// @param panelTitle  panel title
static Function DC_GlobalChangesToITCDataWave(panelTitle)
	string panelTitle

	variable totalLengthIncrease, onsetDelay, additionalRows

	totalLengthIncrease = DC_ReturnTotalLengthIncrease(panelTitle, onsetDelay=onsetDelay)
	additionalRows = round(totalLengthIncrease * 5)

	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	Redimension/N=(DimSize(ITCDataWave, ROWS) + additionalRows, -1, -1, -1) ITCDataWave

	return onsetDelay
End

/// @brief Returns the lenght increase of the ITCDataWave following onset and/or termination delay insertion.
///
/// @param[in] panelTitle                   panel title
/// @param[out] onsetDelay [optional]       onset delay
/// @param[out] terminationDelay [optional] termination delay
Function DC_ReturnTotalLengthIncrease(panelTitle, [onsetDelay, terminationDelay])
	string panelTitle
	variable &onsetDelay, &terminationDelay

	variable minSamplingInterval, onsetDelayVal, terminationDelayVal

	minSamplingInterval = DC_ITCMinSamplingInterval(panelTitle)

	onsetDelayVal = GetSetVariable(panelTitle, "setvar_DataAcq_OnsetDelay") / (minSamplingInterval / 1000)
	terminationDelayVal = GetSetVariable(panelTitle, "setvar_DataAcq_TerminationDelay") / (minSamplingInterval / 1000)

	if(!ParamIsDefault(onsetDelay))
		onsetDelay = onsetDelayVal
	endif

	if(!ParamIsDefault(terminationDelay))
		terminationDelay = terminationDelayVal
	endif

	return onsetDelayVal + terminationDelayVal
End
