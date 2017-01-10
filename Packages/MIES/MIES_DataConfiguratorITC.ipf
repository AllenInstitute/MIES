#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_DataConfiguratorITC.ipf
/// @brief __DC__ Handle preparations before data acquisition or
/// test pulse related to the ITC waves

/// @brief Update global variables used by the Testpulse or DAQ
///
/// @param panelTitle device
/// @param dataAcqOrTP one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_UpdateGlobals(panelTitle, dataAcqOrTP)
	string panelTitle
	variable dataAcqOrTP

	DFREF testPulseDFR = GetDeviceTestPulse(panelTitle)

	variable/G testPulseDFR:pulseDuration
	NVAR/SDFR=testPulseDFR pulseDuration

	variable/G testPulseDFR:duration
	NVAR/SDFR=testPulseDFR duration

	variable/G testPulseDFR:AmplitudeVC
	NVAR/SDFR=testPulseDFR AmplitudeVC

	variable/G testPulseDFR:AmplitudeIC
	NVAR/SDFR=testPulseDFR AmplitudeIC

	variable/G testPulseDFR:baselineFrac
	NVAR/SDFR=testPulseDFR baselineFrac

	DAP_RecordDA_EphysGuiState(panelTitle)

	pulseDuration = GetSetVariable(panelTitle, "SetVar_DataAcq_TPDuration")
	duration = pulseDuration / (DAP_GetITCSampInt(panelTitle, TEST_PULSE_MODE) / 1000)
	baselineFrac = GetSetVariable(panelTitle, "SetVar_DataAcq_TPBaselinePerc") / 100

	// need to deal with units here to ensure that resistance is calculated correctly
	AmplitudeVC = GetSetVariable(panelTitle, "SetVar_DataAcq_TPAmplitude")
	AmplitudeIC = GetSetVariable(panelTitle, "SetVar_DataAcq_TPAmplitudeIC")

	NVAR n = $GetTPBufferSizeGlobal(panelTitle)
	// n determines the number of TP cycles to average
	n = GetSetVariable(panelTitle, "setvar_Settings_TPBuffer")

	SVAR panelTitleG = $GetPanelTitleGlobal()
	panelTitleG = panelTitle
End

/// @brief Prepare test pulse/data acquisition
///
/// @param panelTitle  panel title
/// @param dataAcqOrTP one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param multiDevice [optional: defaults to false] Fine tune data handling for single device (false) or multi device (true)
Function DC_ConfigureDataForITC(panelTitle, dataAcqOrTP, [multiDevice])
	string panelTitle
	variable dataAcqOrTP, multiDevice

	variable numADCs, numActiveChannels
	ASSERT(dataAcqOrTP == DATA_ACQUISITION_MODE || dataAcqOrTP == TEST_PULSE_MODE, "invalid mode")

	if(ParamIsDefault(multiDevice))
		multiDevice = 0
	else
		multiDevice = !!multiDevice
	endif

	KillOrMoveToTrash(wv=GetSweepSettingsWave(panelTitle))
	KillOrMoveToTrash(wv=GetSweepSettingsTextWave(panelTitle))
	KillOrMoveToTrash(wv=GetSweepSettingsKeyWave(panelTitle))
	KillOrMoveToTrash(wv=GetSweepSettingsTextKeyWave(panelTitle))

	DC_UpdateGlobals(panelTitle, dataAcqOrTP)

	if(dataAcqOrTP == TEST_PULSE_MODE)
		WAVE TestPulse = GetTestPulse()
		if(multiDevice)
			DC_UpdateTestPulseWaveMD(panelTitle, TestPulse)
		else
			DC_UpdateTestPulseWave(panelTitle, TestPulse)
		endif
	endif

	numActiveChannels = DC_ChanCalcForITCChanConfigWave(panelTitle, dataAcqOrTP)
	DC_MakeITCConfigAllConfigWave(panelTitle, numActiveChannels)
	DC_MakeITCFIFOPosAllConfigWave(panelTitle, numActiveChannels)
	DC_MakeFIFOAvailAllConfigWave(panelTitle, numActiveChannels)

	DC_PlaceDataInITCChanConfigWave(panelTitle, dataAcqOrTP)
	DC_PlaceDataInITCDataWave(panelTitle, numActiveChannels, dataAcqOrTP, multiDevice)
	DC_PDInITCFIFOPositionAllCW(panelTitle) // PD = Place Data
	DC_PDInITCFIFOAvailAllCW(panelTitle)

	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
	WAVE ADCs = GetADCListFromConfig(ITCChanConfigWave)
	DC_UpdateActiveHSProperties(panelTitle, ADCs)

	NVAR ADChannelToMonitor = $GetADChannelToMonitor(panelTitle)
	ADChannelToMonitor = DimSize(GetDACListFromConfig(ITCChanConfigWave), ROWS)

	if(dataAcqOrTP == TEST_PULSE_MODE)
		numADCs = DimSize(ADCs, ROWS)

		NVAR tpBufferSize = $GetTPBufferSizeGlobal(panelTitle)
		DFREF dfr = GetDeviceTestPulse(panelTitle)
		Make/O/N=(tpBufferSize, numADCs) dfr:TPBaselineBuffer = NaN
		Make/O/N=(tpBufferSize, numADCs) dfr:TPInstBuffer     = NaN
		Make/O/N=(tpBufferSize, numADCs) dfr:TPSSBuffer       = NaN
	endif

	SCOPE_CreateGraph(panelTitle, dataAcqOrTP)
End

static Function DC_UpdateTestPulseWave(panelTitle, TestPulse)
	string panelTitle
	WAVE TestPulse

	variable length

	length = TP_GetTestPulseLengthInPoints(panelTitle, MIN_SAMPLING_INTERVAL_TYPE)

	Redimension/N=(length) TestPulse
	FastOp TestPulse = 0

	NVAR baselineFrac = $GetTestpulseBaselineFraction(panelTitle)
	TestPulse[baselineFrac * length, (1 - baselineFrac) * length] = 1
End

/// @brief MD-variant of #DC_UpdateTestPulseWave
static Function DC_UpdateTestPulseWaveMD(panelTitle, TestPulse)
	string panelTitle
	WAVE TestPulse

	variable length, numPulses, singlePulseLength, i
	variable first, last

	Make/FREE singlePulse
	DC_UpdateTestPulseWave(panelTitle, singlePulse)
	singlePulseLength = DimSize(singlePulse, ROWS)
	numPulses = max(10, ceil(2^MINIMUM_ITCDATAWAVE_EXPONENT / singlePulseLength))
	length = numPulses * singlePulseLength

	Redimension/N=(length) TestPulse
	FastOp TestPulse = 0

	for(i = 0; i < numPulses; i += 1)
		first = i * singlePulseLength
		last  = (i + 1) * singlePulseLength - 1
		Multithread TestPulse[first, last] = singlePulse[p - first]
	endfor
End

static Function DC_UpdateActiveHSProperties(panelTitle, ADCs)
	string panelTitle
	WAVE ADCs

	variable i, idx, numChannels, headStage

	WAVE GUIState = GetDA_EphysGuiStateNum(panelTitle)
	WAVE activeHSProp = GetActiveHSProperties(panelTitle)

	activeHSProp = NaN

	numChannels = DimSize(ADCs, ROWS)
	for(i = 0; i < numChannels; i += 1)
		headstage = AFH_GetHeadstageFromADC(panelTitle, ADCs[i])

		if(!IsFinite(headstage))
			continue
		endif

		activeHSProp[idx][%HeadStage] = headStage
		activeHSProp[idx][%ADC]       = ADCs[i]
		activeHSProp[idx][%DAC]       = AFH_GetDACFromHeadstage(panelTitle, headstage)
		activeHSProp[idx][%ClampMode] = GUIState[headStage][%HSMode]

		idx += 1
	endfor
End

/// @brief Return the number of selected checkboxes for the given type
static Function DC_NoOfChannelsSelected(panelTitle, type)
	string panelTitle
	variable type

	return sum(DC_ControlStatusWaveCache(panelTitle, type))
End

/// @brief Returns a free wave of the status of the checkboxes specified by channelType
///
/// @param type        one of the type constants from @ref ChannelTypeAndControlConstants
/// @param panelTitle  panel title
Function/Wave DC_ControlStatusWave(panelTitle, type)
	string panelTitle
	variable type

	string ctrl
	variable i, numEntries

	numEntries = GetNumberFromType(var=type)

	Make/FREE/U/B/N=(numEntries) wv

	for(i = 0; i < numEntries; i += 1)
		ctrl = GetPanelControl(i, type, CHANNEL_CONTROL_CHECK)
		wv[i] = GetCheckboxState(panelTitle, ctrl)
	endfor

	return wv
End

/// @brief Return a free wave of the status of the checkboxes specified by
///        channelType, uses GetDA_EphysGuiStateNum() instead of GUI queries.
///
/// This function does only return correct values if GetDA_EphysGuiStateNum() is up to date.
/// At the moment this is ensured as all callers of this function have TP_UpdateGlobals() called before.
///
/// @param type        one of the type constants from @ref ChannelTypeAndControlConstants
/// @param panelTitle  panel title
Function/Wave DC_ControlStatusWaveCache(panelTitle, type)
	string panelTitle
	variable type

	variable numEntries, col

	WAVE GUIState = GetDA_EphysGuiStateNum(panelTitle)

	numEntries = GetNumberFromType(var=type)

	switch(type)
		case CHANNEL_TYPE_ASYNC:
			col = 12
			break
		case CHANNEL_TYPE_ALARM:
			col = 14
			break
		case CHANNEL_TYPE_TTL:
			col = 9
			break
		case CHANNEL_TYPE_DAC:
			col = 2
			break
		case CHANNEL_TYPE_HEADSTAGE:
			col = 0
			break
		case CHANNEL_TYPE_ADC:
			col = 7
			break
		default:
			ASSERT(0, "invalid type")
			break
	endswitch

	Make/FREE/U/B/N=(numEntries) wv = GUIState[p][col]

	return wv
End

/// @brief Returns the total number of combined channel types (DA, AD, and front TTLs) selected in the DA_Ephys Gui
///
/// @param panelTitle  panel title
/// @param dataAcqOrTP acquisition mode, one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_ChanCalcForITCChanConfigWave(panelTitle, dataAcqOrTP)
	string panelTitle
	variable dataAcqOrTP

	variable numDACs, numADCs, numTTLsRackZero, numTTLsRackOne, numActiveHeadstages

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		numDACs         = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_DAC)
		numADCs         = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_ADC)
		numTTLsRackZero = DC_AreTTLsInRackChecked(RACK_ZERO, panelTitle)
		numTTLsRackOne  = DC_AreTTLsInRackChecked(RACK_ONE, panelTitle)
	elseif(dataAcqOrTP == TEST_PULSE_MODE)
		numActiveHeadstages = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_HEADSTAGE)
		numDACs         = numActiveHeadstages
		numADCs         = numActiveHeadstages
		numTTLsRackZero = 0
		numTTLsRackOne  = 0
	else
		ASSERT(0, "Unknown value of dataAcqOrTP")
	endif

	return numDACs + numADCs + numTTLsRackZero + numTTLsRackOne
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
	WAVE statusTTL = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_TTL)

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
/// @param channelType channel type, one of @ref ChannelTypeAndControlConstants
/// @param panelTitle  device
static Function/s DC_PopMenuStringList(panelTitle, channelType)
	string panelTitle
	variable channelType

	string ControlWaveList = ""
	string ctrl
	variable i, numEntries

	numEntries = GetNumberFromType(var=channelType)
	for(i = 0; i < numEntries; i += 1)
		ctrl = GetPanelControl(i, channelType, CHANNEL_CONTROL_WAVE)
		ControlInfo/W=$panelTitle $ctrl
		ControlWaveList = AddlistItem(s_value, ControlWaveList, ";", i)
	endfor

	return ControlWaveList
End

/// @brief Returns the number of points in the longest stimset
///
/// @param panelTitle  device
/// @param dataAcqOrTP acquisition mode, one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param channelType channel type, one of @ref ChannelTypeAndControlConstants
static Function DC_LongestOutputWave(panelTitle, dataAcqOrTP, channelType)
	string panelTitle
	variable dataAcqOrTP, channelType

	variable maxNumRows, i, numEntries
	string channelTypeWaveList = DC_PopMenuStringList(panelTitle, channelType)

	WAVE statusChannel = DC_ControlStatusWaveCache(panelTitle, channelType)
	WAVE statusHS      = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	numEntries = DimSize(statusChannel, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!DC_ChannelIsActive(panelTitle, dataAcqOrTP, channelType, i, statusChannel, statusHS))
			continue
		endif

		if(dataAcqOrTP == DATA_ACQUISITION_MODE)
			WAVE/Z wv = WB_CreateAndGetStimSet(StringFromList(i, channelTypeWaveList))
		elseif(dataAcqOrTP == TEST_PULSE_MODE)
			WAVE/Z wv = GetTestPulse()
		else
			ASSERT(0, "unhandled case")
		endif

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
static Function DC_CalculateITCDataWaveLength(panelTitle, dataAcqOrTP)
	string panelTitle
	variable dataAcqOrTP

	variable exponent

	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	exponent = FindNextPower(stopCollectionPoint, 2)

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		exponent += 1
	endif

	exponent = max(MINIMUM_ITCDATAWAVE_EXPONENT, exponent)

	return 2^exponent
end

/// @brief Returns the longest sweep in a stimulus set across the given channel type
///
/// @param panelTitle  device
/// @param dataAcqOrTP mode, either #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param channelType One of @ref ChannelTypeAndControlConstants
///
/// @return number of data points, *not* time
static Function DC_CalculateLongestSweep(panelTitle, dataAcqOrTP, channelType)
	string panelTitle
	variable dataAcqOrTP
	variable channelType

	return ceil(DC_LongestOutputWave(panelTitle, dataAcqOrTP, channelType) / DC_GetDecimationFactor(panelTitle, dataAcqOrTP))
End

/// @brief Creates the ITCConfigALLConfigWave used to configure channels the ITC device
///
/// @param panelTitle  panel title
/// @param numActiveChannels number of active channels as returned by DC_ChanCalcForITCChanConfigWave()
static Function DC_MakeITCConfigAllConfigWave(panelTitle, numActiveChannels)
	string panelTitle
	variable numActiveChannels

	DFREF dfr = GetDevicePath(panelTitle)
	Make/I/O/N=(numActiveChannels, 4) dfr:ITCChanConfigWave/Wave=wv
	wv = 0
End

/// @brief Creates ITCDataWave; The wave that the ITC device takes DA and TTL data from and passes AD data to for all channels.
///
/// Config all refers to configuring all the channels at once
///
/// @param panelTitle          panel title
/// @param numActiveChannels   number of active channels as returned by DC_ChanCalcForITCChanConfigWave()
/// @param minSamplingInterval sampling interval as returned by DAP_GetITCSampInt()
/// @param dataAcqOrTP         one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_MakeITCDataWave(panelTitle, numActiveChannels, minSamplingInterval, dataAcqOrTP)
	string panelTitle
	variable numActiveChannels, minSamplingInterval, dataAcqOrTP

	variable numRows

	DFREF dfr = GetDevicePath(panelTitle)
	numRows   = DC_CalculateITCDataWaveLength(panelTitle, dataAcqOrTP)

	Make/W/O/N=(numRows, numActiveChannels) dfr:ITCDataWave/Wave=ITCDataWave

	FastOp ITCDataWave = 0
	SetScale/P x 0, minSamplingInterval / 1000, "ms", ITCDataWave
End

/// @brief Initializes the wave used for displaying DAQ/TP results in the
/// oscilloscope window
///
/// @param panelTitle  panel title
/// @param numActiveChannels number of active channels as returned by DC_ChanCalcForITCChanConfigWave()
/// @param dataAcqOrTP one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_MakeOscilloscopeWave(panelTitle, numActiveChannels, dataAcqOrTP)
	string panelTitle
	variable numActiveChannels, dataAcqOrTP

	variable numRows
	WAVE ITCDataWave      = GetITCDataWave(panelTitle)
	WAVE OscilloscopeData = GetOscilloscopeWave(panelTitle)

	if(dataAcqOrTP == TEST_PULSE_MODE)
		numRows = TP_GetTestPulseLengthInPoints(panelTitle, REAL_SAMPLING_INTERVAL_TYPE)
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)
		numRows = DimSize(ITCDataWave, ROWS)
	else
		ASSERT(0, "Invalid dataAcqOrTP value")
	endif

	Redimension/N=(numRows, numActiveChannels) OscilloscopeData
	SetScale/P x, 0, DimDelta(ITCDataWave, ROWS), "ms", OscilloscopeData
	Multithread OscilloscopeData = NaN
End

/// @brief Creates ITCFIFOPosAllConfigWave, the wave used to configure the FIFO on all channels of the ITC device
///
/// @param panelTitle        panel title
/// @param numActiveChannels number of active channels as returned by DC_ChanCalcForITCChanConfigWave()
static Function DC_MakeITCFIFOPosAllConfigWave(panelTitle, numActiveChannels)
	string panelTitle
	variable numActiveChannels

	DFREF dfr = GetDevicePath(panelTitle)
	Make/I/O/N=(numActiveChannels, 4) dfr:ITCFIFOPositionAllConfigWave/Wave=wv
	wv = 0
End

/// @brief Creates the ITCFIFOAvailAllConfigWave used to recieve FIFO position data
///
/// @param panelTitle        panel title
/// @param numActiveChannels number of active channels as returned by DC_ChanCalcForITCChanConfigWave()
static Function DC_MakeFIFOAvailAllConfigWave(panelTitle, numActiveChannels)
	string panelTitle
	variable numActiveChannels

	DFREF dfr = GetDevicePath(panelTitle)
	Make/I/O/N=(numActiveChannels, 4) dfr:ITCFIFOAvailAllConfigWave/Wave=wv
	wv = 0
End

/// @brief Check if the given channel is active
///
/// For DAQ a channel is active if it is selected. For the testpulse it is active if it is connected with
/// an active headstage.
///
/// `statusChannel` and `statusHS` are passed in for performance reasons.
///
/// @param panelTitle        panel title
/// @param dataAcqOrTP       one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param channelType       one of the channel type constants from @ref ChannelTypeAndControlConstants
/// @param channelNumber     number of the channel
/// @param statusChannel     status wave of the given channelType
/// @param statusHS     	 status wave of the headstages
Function DC_ChannelIsActive(panelTitle, dataAcqOrTP, channelType, channelNumber, statusChannel, statusHS)
	string panelTitle
	variable dataAcqOrTP, channelType, channelNumber
	WAVE statusChannel, statusHS

	variable headstage

	if(!statusChannel[channelNumber])
		return 0
	endif

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		return 1
	endif

	switch(channelType)
		case CHANNEL_TYPE_TTL:
			// TTL channels are always considered inactive for the testpulse
			return 0
			break
		case CHANNEL_TYPE_ADC:
			headstage = AFH_GetHeadstageFromADC(panelTitle, channelNumber)
			break
		case CHANNEL_TYPE_DAC:
			headstage = AFH_GetHeadstageFromDAC(panelTitle, channelNumber)
			break
		default:
			ASSERT(0, "unhandled case")
			break
	endswitch

	return IsFinite(headstage) && statusHS[headstage]
End

/// @brief Places channel (DA, AD, and TTL) settings data into ITCChanConfigWave
///
/// @param panelTitle  panel title
/// @param dataAcqOrTP one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_PlaceDataInITCChanConfigWave(panelTitle, dataAcqOrTP)
	string panelTitle
	variable dataAcqOrTP

	variable i, j, numEntries, ret, channel
	string ctrl, deviceType, deviceNumber
	string unitList = ""

	WAVE/SDFR=GetDevicePath(panelTitle) ITCChanConfigWave

	WAVE statusHS = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	// query DA properties
	WAVE channelStatus = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_DAC)

	numEntries = DimSize(channelStatus, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!DC_ChannelIsActive(panelTitle, dataAcqOrTP, CHANNEL_TYPE_DAC, i, channelStatus, statusHS))
			continue
		endif

		ITCChanConfigWave[j][0] = ITC_XOP_CHANNEL_TYPE_DAC
		ITCChanConfigWave[j][1] = i
		ctrl = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
		unitList = AddListItem(GetSetVariableString(panelTitle, ctrl), unitList, ";", Inf)
		j += 1
	endfor

	// query AD properties
	WAVE channelStatus = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_ADC)

	numEntries = DimSize(channelStatus, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!DC_ChannelIsActive(panelTitle, dataAcqOrTP, CHANNEL_TYPE_ADC, i, channelStatus, statusHS))
			continue
		endif

		ITCChanConfigWave[j][0] = ITC_XOP_CHANNEL_TYPE_ADC
		ITCChanConfigWave[j][1] = i
		ctrl = GetPanelControl(i, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
		unitList = AddListItem(GetSetVariableString(panelTitle, ctrl), unitList, ";", Inf)
		j += 1
	endfor

	Note ITCChanConfigWave, unitList

	ITCChanConfigWave[][2] = DAP_GetITCSampInt(panelTitle, dataAcqOrTP)
	ITCChanConfigWave[][3] = 0

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		WAVE sweepDataLNB      = GetSweepSettingsWave(panelTitle)
		WAVE/T sweepDataTxTLNB = GetSweepSettingsTextWave(panelTitle)

		if(DC_AreTTLsInRackChecked(RACK_ZERO, panelTitle))
			ITCChanConfigWave[j][0] = ITC_XOP_CHANNEL_TYPE_TTL

			channel = HW_ITC_GetITCXOPChannelForRack(panelTitle, RACK_ZERO)
			ITCChanConfigWave[j][1] = channel
			sweepDataLNB[0][10][]   = channel

			j += 1
		endif

		if(DC_AreTTLsInRackChecked(RACK_ONE, panelTitle))
			ITCChanConfigWave[j][0] = ITC_XOP_CHANNEL_TYPE_TTL

			channel = HW_ITC_GetITCXOPChannelForRack(panelTitle, RACK_ONE)
			ITCChanConfigWave[j][1] = channel
			sweepDataLNB[0][11][]   = channel
		endif
	endif
End

/// @brief Get the decimation factor for the current channel configuration
///
/// This is the factor between the minimum sampling interval and the real.
/// If the multiplier is taken into account depends on `dataAcqOrTP`.
///
/// @param panelTitle  device
/// @param dataAcqOrTP one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_GetDecimationFactor(panelTitle, dataAcqOrTP)
	string panelTitle
	variable dataAcqOrTP

	return DAP_GetITCSampInt(panelTitle, dataAcqOrTP) / (HARDWARE_ITC_MIN_SAMPINT * 1000)
End

/// @brief Get the stimset length for the real sampling interval
///
/// @param stimSet          stimset wave
/// @param decimationFactor see DC_GetDecimationFactor()
static Function DC_CalculateStimsetLength(stimSet, decimationFactor)
	WAVE stimSet
	variable decimationFactor

	return round(DimSize(stimSet, ROWS) / decimationFactor)
End

/// @brief Places data from appropriate DA and TTL stimulus set(s) into ITCdatawave.
/// Also records certain DA_Ephys GUI settings into sweepDataLNB and sweepDataTxTLNB
/// @param panelTitle        panel title
/// @param numActiveChannels number of active channels as returned by DC_ChanCalcForITCChanConfigWave()
/// @param dataAcqOrTP       one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param multiDevice       [optional: defaults to false] Fine tune data handling for single device (false) or multi device (true)
static Function DC_PlaceDataInITCDataWave(panelTitle, numActiveChannels, dataAcqOrTP, multiDevice)
	string panelTitle
	variable numActiveChannels, dataAcqOrTP, multiDevice

	variable i, activeColumn, numEntries
	string setNameList
	string ctrl, str, list, func, colLabel
	variable oneFullCycle, val, singleSetLength, singleInsertStart, minSamplingInterval
	variable channelMode, TPAmpVClamp, TPAmpIClamp, testPulseLength, maxStimSetLength
	variable GlobalTPInsert, scalingZero, indexingLocked, indexing, distributedDAQ
	variable distributedDAQDelay, onSetDelay, onsetDelayAuto, onsetDelayUser, decimationFactor, cutoff
	variable multiplier, j, powerSpectrum, distributedDAQOptOv, distributedDAQOptPre, distributedDAQOptPost, distributedDAQOptRes, headstage
	variable/C ret

	globalTPInsert        = GetCheckboxState(panelTitle, "Check_Settings_InsertTP")
	scalingZero           = GetCheckboxState(panelTitle,  "check_Settings_ScalingZero")
	indexingLocked        = GetCheckboxState(panelTitle, "Check_DataAcq1_IndexingLocked")
	indexing              = GetCheckboxState(panelTitle, "Check_DataAcq_Indexing")
	distributedDAQ        = GetCheckboxState(panelTitle, "Check_DataAcq1_DistribDaq")
	distributedDAQOptOv   = GetCheckboxState(panelTitle, "Check_DataAcq1_dDAQOptOv")
	distributedDAQOptPre  = GetSetVariable(panelTitle, "Setvar_DataAcq_dDAQOptOvPre")
	distributedDAQOptPost = GetSetVariable(panelTitle, "Setvar_DataAcq_dDAQOptOvPost")
	distributedDAQOptRes  = GetSetVariable(panelTitle, "Setvar_DataAcq_dDAQOptOvRes")
	TPAmpVClamp           = GetSetVariable(panelTitle, "SetVar_DataAcq_TPAmplitude")
	TPAmpIClamp           = GetSetVariable(panelTitle, "SetVar_DataAcq_TPAmplitudeIC")
	powerSpectrum         = GetCheckboxState(panelTitle, "check_settings_show_power")
	decimationFactor      = DC_GetDecimationFactor(panelTitle, dataAcqOrTP)
	minSamplingInterval   = DAP_GetITCSampInt(panelTitle, dataAcqOrTP)
	multiplier            = str2num(GetPopupMenuString(panelTitle, "Popup_Settings_SampIntMult"))
	testPulseLength       = TP_GetTestPulseLengthInPoints(panelTitle, REAL_SAMPLING_INTERVAL_TYPE) / multiplier
	setNameList           = DC_PopMenuStringList(panelTitle, CHANNEL_TYPE_DAC)
	DC_ReturnTotalLengthIncrease(panelTitle, onsetdelayUser=onsetDelayUser, onsetDelayAuto=onsetDelayAuto, distributedDAQDelay=distributedDAQDelay)
	onsetDelay            = onsetDelayUser + onsetDelayAuto

	NVAR baselineFrac     = $GetTestpulseBaselineFraction(panelTitle)
	WAVE ChannelClampMode = GetChannelClampMode(panelTitle)
	WAVE statusDA         = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_DAC)
	WAVE statusHS         = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	WAVE sweepDataLNB         = GetSweepSettingsWave(panelTitle)
	WAVE/T sweepDataTxTLNB    = GetSweepSettingsTextWave(panelTitle)
	WAVE/T cellElectrodeNames = GetCellElectrodeNames(panelTitle)

	numEntries = DimSize(statusDA, ROWS)
	Make/D/FREE/N=(numEntries) DAGain, DAScale, insertStart, setLength, testPulseAmplitude, setColumn, headstageDAC, DAC
	Make/T/FREE/N=(numEntries) setName
	Make/WAVE/FREE/N=(numEntries) stimSet

	for(i = 0; i < numEntries; i += 1)

		if(!DC_ChannelIsActive(panelTitle, dataAcqOrTP, CHANNEL_TYPE_DAC, i, statusDA, statusHS))
			continue
		endif

		DAC[activeColumn]          = i
		headstageDAC[activeColumn] = AFH_GetheadstageFromDAC(panelTitle, i)

		if(dataAcqOrTP == DATA_ACQUISITION_MODE)
			setName[activeColumn] = StringFromList(i, setNameList)
			stimSet[activeColumn] = WB_CreateAndGetStimSet(setName[activeColumn])
		elseif(dataAcqOrTP == TEST_PULSE_MODE)
			setName[activeColumn] = "testpulse"
			stimSet[activeColumn] = GetTestPulse()
		else
			ASSERT(0, "unknown mode")
		endif

		if(dataAcqOrTP == TEST_PULSE_MODE)
			setColumn[activeColumn] = 0
		else
			// only call DC_CalculateChannelColumnNo for real data acquisition
			ret = DC_CalculateChannelColumnNo(panelTitle, setName[activeColumn], i, CHANNEL_TYPE_DAC)
			oneFullCycle = imag(ret)
			setColumn[activeColumn] = real(ret)
		endif

		channelMode = ChannelClampMode[i][%DAC]
		if(channelMode == V_CLAMP_MODE)
			testPulseAmplitude[activeColumn] = TPAmpVClamp
		elseif(channelMode == I_CLAMP_MODE || channelMode == I_EQUAL_ZERO_MODE)
			testPulseAmplitude[activeColumn] = TPAmpIClamp
		else
			ASSERT(0, "Unknown clamp mode")
		endif

		ctrl = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
		DAScale[activeColumn] = GetSetVariable(panelTitle, ctrl)

		// DAScale tuning for special cases
		if(dataAcqOrTP == DATA_ACQUISITION_MODE)
			// checks if user wants to set scaling to 0 on sets that have already cycled once
			if(scalingZero && (indexingLocked || !indexing) && oneFullCycle)
				DAScale[activeColumn] = 0
			endif

			if(channelMode == I_EQUAL_ZERO_MODE)
				DAScale[activeColumn]            = 0.0
				testPulseAmplitude[activeColumn] = 0.0
			endif
		elseif(dataAcqOrTP == TEST_PULSE_MODE)
			if(powerSpectrum)
				testPulseAmplitude[activeColumn] = 0.0
			endif
			DAScale[activeColumn] = testPulseAmplitude[activeColumn]
		else
			ASSERT(0, "unknown mode")
		endif

		DC_DocumentChannelProperty(panelTitle, "DAC", headstageDAC[activeColumn], i, var=i)

		ctrl = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
		val = GetSetVariable(panelTitle, ctrl)
		DAGain[activeColumn] = HARDWARE_ITC_BITS_PER_VOLT / val

		DC_DocumentChannelProperty(panelTitle, "DA GAIN", headstageDAC[activeColumn], i, var=val)

		DC_DocumentChannelProperty(panelTitle, STIM_WAVE_NAME_KEY, headstageDAC[activeColumn], i, str=setName[activeColumn])

		for(j = 0; j < TOTAL_NUM_EVENTS; j += 1)
			func     = ExtractAnalysisFuncFromStimSet(stimSet[activeColumn], j)
			colLabel = GetDimLabel(sweepDataTxTLNB, COLS, 5 + j)
			DC_DocumentChannelProperty(panelTitle, colLabel, headstageDAC[activeColumn], i, str=func)
		endfor

		ctrl = GetPanelControl(i, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
		DC_DocumentChannelProperty(panelTitle, "DA Unit", headstageDAC[activeColumn], i, str=GetSetVariableString(panelTitle, ctrl))

		DC_DocumentChannelProperty(panelTitle, "Stim Scale Factor", headstageDAC[activeColumn], i, var=DAScale[activeColumn])
		DC_DocumentChannelProperty(panelTitle, "Set Sweep Count", headstageDAC[activeColumn], i, var=setColumn[activeColumn])
		DC_DocumentChannelProperty(panelTitle, "Electrode", headstageDAC[activeColumn], i, str=cellElectrodeNames[headstageDAC[activeColumn]])

		activeColumn += 1
	endfor

	numEntries = activeColumn
	Redimension/N=(numEntries) DAGain, DAScale, insertStart, setLength, testPulseAmplitude, setColumn, stimSet, setName, headstageDAC

	if(distributedDAQOptOv && dataAcqOrTP == DATA_ACQUISITION_MODE)
		STRUCT OOdDAQParams params
		InitOOdDAQParams(params, stimSet, setColumn, distributedDAQOptPre, distributedDAQOptPost, distributedDAQOptRes)
		OOD_CalculateOffsetsYoked(panelTitle, decimationFactor, minSamplingInterval, params)
		WAVE offsets = params.offsets
		WAVE/T regions = params.regions
		WAVE/WAVE stimSet = OOD_CreateStimSet(params)
	endif

	setLength[] = DC_CalculateStimsetLength(stimSet[p], decimationFactor)

	if(dataAcqOrTP == TEST_PULSE_MODE)
		insertStart[] = 0
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)
		if(distributedDAQ)
			insertStart[] = onsetDelay + (sum(statusHS, 0, headstageDAC[p]) - 1) * (distributedDAQDelay + setLength[p])
		else
			insertStart[] = onsetDelay
		endif
	endif

	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	stopCollectionPoint = DC_GetStopCollectionPoint(panelTitle, dataAcqOrTP, setLength)

	DC_MakeITCDataWave(panelTitle, numActiveChannels, minSamplingInterval, dataAcqOrTP)
	DC_MakeOscilloscopeWave(panelTitle, numActiveChannels, dataAcqOrTP)

	WAVE ITCDataWave = GetITCDataWave(panelTitle)

	// varies per DAC:
	// DAGain, DAScale, insertStart (with dDAQ), setLength, testPulseAmplitude (can be non-constant due to different VC/IC)
	// setName, setColumn, headstageDAC
	//
	// constant:
	// decimationFactor, testPulseLength, baselineFrac
	//
	// we only have to fill in the DA channels
	if(dataAcqOrTP == TEST_PULSE_MODE)
		ASSERT(sum(insertStart) == 0, "Unexpected insert start value")
		ASSERT(sum(setColumn) == 0, "Unexpected setColumn value")
		WAVE singleStimSet = GetTestPulse()
		singleSetLength = setLength[0]
		ASSERT(DimSize(singleStimSet, COLS) <= 1, "Expected a 1D testpulse wave")
		if(multiDevice)
			Multithread ITCDataWave[][0, numEntries - 1] = (DAGain[q] * DAScale[q]) * singleStimSet[decimationFactor * mod(p, singleSetLength)][0]
			cutOff = mod(DimSize(ITCDataWave, ROWS), testPulseLength)
			ITCDataWave[DimSize(ITCDataWave, ROWS) - cutoff, *][0, numEntries - 1] = 0
		else
			Multithread ITCDataWave[0, setLength[0] - 1][0, numEntries - 1] = (DAGain[q] * DAScale[q]) * singleStimSet[decimationFactor * p][0]
		endif
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)
		for(i = 0; i < numEntries; i += 1)
			WAVE singleStimSet = stimSet[i]
			Multithread ITCDataWave[insertStart[i], insertStart[i] + setLength[i] - 1][i] = (DAGain[i] * DAScale[i]) * singleStimSet[decimationFactor * (p - insertStart[i])][setColumn[i]]
		endfor

		if(globalTPInsert)
			// space in ITCDataWave for the testpulse is allocated via an automatic increase
			// of the onset delay
			ITCDataWave[baselineFrac * testPulseLength, (1 - baselineFrac) * testPulseLength][0, numEntries - 1] = testPulseAmplitude[q] * DAGain[q]
		endif
	endif

	if(!WaveExists(offsets))
		Make/FREE/N=(numEntries) offsets = 0
	else
		// realSamplingInterval / 1000 is the real sampling interval in ms
		// decimationFactor because offset is in number of stimset points and stimsets
		// are with minimum sampling interval
		offsets[] *= minSamplingInterval / 1000 / decimationFactor
	endif

	if(!WaveExists(regions))
		Make/FREE/T/N=(numEntries) regions
	endif

	for(i = 0; i < numEntries; i += 1)
		DC_DocumentChannelProperty(panelTitle, "Stim set length", headstageDAC[i], DAC[i], var=setLength[i])
		DC_DocumentChannelProperty(panelTitle, "Delay onset oodDAQ", headstageDAC[i], DAC[i], var=offsets[i])
		DC_DocumentChannelProperty(panelTitle, "oodDAQ regions", headstageDAC[i], DAC[i], str=regions[i])
	endfor

	DC_DocumentChannelProperty(panelTitle, "Sampling interval multiplier", INDEP_HEADSTAGE, NaN, var=multiplier)
	DC_DocumentChannelProperty(panelTitle, "Minimum sampling interval", INDEP_HEADSTAGE, NaN, var=SI_CalculateMinSampInterval(panelTitle, dataAcqOrTP) * 1e-3)

	DC_DocumentChannelProperty(panelTitle, "Inter-trial interval", INDEP_HEADSTAGE, NaN, var=GetSetVariable(panelTitle, "SetVar_DataAcq_ITI"))
	DC_DocumentChannelProperty(panelTitle, "Delay onset user", INDEP_HEADSTAGE, NaN, var=GetSetVariable(panelTitle, "setvar_DataAcq_OnsetDelayUser"))
	DC_DocumentChannelProperty(panelTitle, "Delay onset auto", INDEP_HEADSTAGE, NaN, var=GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_OnsetDelayAuto"))
	DC_DocumentChannelProperty(panelTitle, "Delay termination", INDEP_HEADSTAGE, NaN, var=GetSetVariable(panelTitle, "setvar_DataAcq_TerminationDelay"))
	DC_DocumentChannelProperty(panelTitle, "Delay distributed DAQ", INDEP_HEADSTAGE, NaN, var=GetSetVariable(panelTitle, "setvar_DataAcq_dDAQDelay"))
	DC_DocumentChannelProperty(panelTitle, "oodDAQ Pre Feature", INDEP_HEADSTAGE, NaN, var=GetSetVariable(panelTitle, "Setvar_DataAcq_dDAQOptOvPre"))
	DC_DocumentChannelProperty(panelTitle, "oodDAQ Post Feature", INDEP_HEADSTAGE, NaN, var=GetSetVariable(panelTitle, "Setvar_DataAcq_dDAQOptOvPost"))
	DC_DocumentChannelProperty(panelTitle, "oodDAQ Resolution", INDEP_HEADSTAGE, NaN, var=GetSetVariable(panelTitle, "setvar_DataAcq_dDAQOptOvRes"))

	DC_DocumentChannelProperty(panelTitle, "TP Insert Checkbox", INDEP_HEADSTAGE, NaN, var=GlobalTPInsert)
	DC_DocumentChannelProperty(panelTitle, "Distributed DAQ", INDEP_HEADSTAGE, NaN, var=distributedDAQ)
	DC_DocumentChannelProperty(panelTitle, "Optimized Overlap dDAQ", INDEP_HEADSTAGE, NaN, var=distributedDAQOptOv)
	DC_DocumentChannelProperty(panelTitle, "Repeat Sets", INDEP_HEADSTAGE, NaN, var=GetSetVariable(panelTitle, "SetVar_DataAcq_SetRepeats"))
	DC_DocumentChannelProperty(panelTitle, "Scaling zero", INDEP_HEADSTAGE, NaN, var=scalingZero)
	DC_DocumentChannelProperty(panelTitle, "Indexing", INDEP_HEADSTAGE, NaN, var=indexing)
	DC_DocumentChannelProperty(panelTitle, "Locked indexing", INDEP_HEADSTAGE, NaN, var=indexingLocked)
	DC_DocumentChannelProperty(panelTitle, "Repeated Acquisition", INDEP_HEADSTAGE, NaN, var=GetCheckboxState(panelTitle, "Check_DataAcq1_RepeatAcq"))
	DC_DocumentChannelProperty(panelTitle, "Random Repeated Acquisition", INDEP_HEADSTAGE, NaN, var=GetCheckboxState(panelTitle, "check_DataAcq_RepAcqRandom"))

	if(distributedDAQ)
		// dDAQ requires that all stimsets have the same length, so store the stim set length
		// also headstage independent
		ASSERT(!distributedDAQOptOv, "Unexpected oodDAQ mode")
		ASSERT(WaveMin(setLength) == WaveMax(setLength), "Unexpected varying stim set length")
		DC_DocumentChannelProperty(panelTitle, "Stim set length", INDEP_HEADSTAGE, NaN, var=setLength[0])
	endif

	WAVE statusAD = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_ADC)

	numEntries = DimSize(statusAD, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!DC_ChannelIsActive(panelTitle, dataAcqOrTP, CHANNEL_TYPE_ADC, i, statusAD, statusHS))
			continue
		endif

		headstage = AFH_GetHeadstageFromADC(panelTitle, i)

		DC_DocumentChannelProperty(panelTitle, "ADC", headstage, i, var=i)

		ctrl = GetPanelControl(i, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
		DC_DocumentChannelProperty(panelTitle, "AD Gain", headstage, i, var=GetSetVariable(panelTitle, ctrl))

		ctrl = GetPanelControl(i, CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
		DC_DocumentChannelProperty(panelTitle, "AD Unit", headstage, i, str=GetSetVariableString(panelTitle, ctrl))

		activeColumn += 1
	endfor

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		// reset to the default value without distributedDAQ
		singleInsertStart = onSetDelay

		// Place TTL waves into ITCDataWave
		if(DC_AreTTLsInRackChecked(RACK_ZERO, panelTitle))
			DC_MakeITCTTLWave(panelTitle, RACK_ZERO)
			WAVE TTLWave = GetTTLWave(panelTitle)
			singleSetLength = round(DimSize(TTLWave, ROWS) / decimationFactor)
			ITCDataWave[singleInsertStart, singleInsertStart + singleSetLength - 1][activeColumn] = TTLWave[decimationFactor * (p - singleInsertStart)]
			activeColumn += 1
		endif

		if(DC_AreTTLsInRackChecked(RACK_ONE, panelTitle))
			DC_MakeITCTTLWave(panelTitle, RACK_ONE)
			WAVE TTLWave = GetTTLWave(panelTitle)
			singleSetLength = round(DimSize(TTLWave, ROWS) / decimationFactor)
			ITCDataWave[singleInsertStart, singleInsertStart + singleSetLength - 1][activeColumn] = TTLWave[decimationFactor * (p - singleInsertStart)]
		endif
	endif
End

/// @brief Document channel properties of DA and AD channels
///
/// Knows about unassociated channels and creates the key `$entry UNASSOC_$channelNumber` for them
///
/// @param panelTitle device
/// @param entry      name of the property
/// @param headstage  number of headstage, must be `NaN` for unassociated channels
/// @param channelNumber number of the channel
/// @param var [optional] numeric value
/// @param str [optional] string value
static Function DC_DocumentChannelProperty(panelTitle, entry, headstage, channelNumber, [var, str])
	string panelTitle, entry
	variable headstage, channelNumber
	variable var
	string str

	variable colData, colKey, numCols
	string ua_entry

	ASSERT(ParamIsDefault(var) + ParamIsDefault(str) == 1, "Exactly one of var or str has to be supplied")

	WAVE sweepDataLNB         = GetSweepSettingsWave(panelTitle)
	WAVE/T sweepDataTxTLNB    = GetSweepSettingsTextWave(panelTitle)
	WAVE/T sweepDataLNBKey    = GetSweepSettingsKeyWave(panelTitle)
	WAVE/T sweepDataTxTLNBKey = GetSweepSettingsTextKeyWave(panelTitle)

	if(!ParamIsDefault(var))
		colData = FindDimLabel(sweepDataLNB, COLS, entry)
		colKey  = FindDimLabel(sweepDataLNBKey, COLS, entry)
	elseif(!ParamIsDefault(str))
		colData = FindDimLabel(sweepDataTxTLNB, COLS, entry)
		colKey  = FindDimLabel(sweepDataTxTLNBKey, COLS, entry)
	endif

	ASSERT(colData >= 0, "Could not find entry in the labnotebook input waves")
	ASSERT(colKey >= 0, "Could not find entry in the labnotebook input key waves")

	if(IsFinite(headstage))
		if(!ParamIsDefault(var))
			sweepDataLNB[0][%$entry][headstage] = var
		elseif(!ParamIsDefault(str))
			sweepDataTxTLNB[0][%$entry][headstage] = str
		endif
		return NaN
	endif

	// headstage is not finite, so the channel is unassociated
	ua_entry = CreateLBNUnassocKey(entry, channelNumber)

	if(!ParamIsDefault(var))
		colData = FindDimLabel(sweepDataLNB, COLS, ua_entry)
		colKey  = FindDimLabel(sweepDataLNBKey, COLS, ua_entry)
	elseif(!ParamIsDefault(str))
		colData = FindDimLabel(sweepDataTxTLNB, COLS, ua_entry)
		colKey  = FindDimLabel(sweepDataTxTLNBKey, COLS, ua_entry)
	endif

	ASSERT((colData >= 0 && colKey >= 0) || (colData < 0 && colKey < 0), "input and key wave got out of sync")

	if(colData < 0)
		if(!ParamIsDefault(var))
			numCols = DimSize(sweepDataLNB, COLS)
			Redimension/N=(-1, numCols + 1, -1) sweepDataLNB, sweepDataLNBKey
			SetDimLabel COLS, numCols, $ua_entry, sweepDataLNB, sweepDataLNBKey
			sweepDataLNBKey[0][%$ua_entry]   = ua_entry
			sweepDataLNBKey[1,2][%$ua_entry] = sweepDataLNBKey[p][%$entry]
		elseif(!ParamIsDefault(str))
			numCols = DimSize(sweepDataTxTLNB, COLS)
			Redimension/N=(-1, numCols + 1, -1) sweepDataTxTLNB, sweepDataTxTLNBKey
			SetDimLabel COLS, numCols, $ua_entry, sweepDataTxTLNB, sweepDataTxTLNBKey
			sweepDataTxtLNBKey[0][%$ua_entry] = ua_entry
		endif
	endif

	if(!ParamIsDefault(var))
		sweepDataLNB[0][%$ua_entry][INDEP_HEADSTAGE] = var
	elseif(!ParamIsDefault(str))
		sweepDataTxTLNB[0][%$ua_entry][INDEP_HEADSTAGE] = str
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
/// @param rackNo Front TTL rack aka number of ITC devices. Only the ITC1600 has two racks, see @ref RackConstants. Rack number for all other devices is #RACK_ZERO.
/// @param panelTitle  panel title
static Function DC_MakeITCTTLWave(panelTitle, rackNo)
	string panelTitle
	variable rackNo

	variable first, last, i, col, maxRows, lastIdx, bit, bits
	string set
	string listOfSets = ""

	WAVE statusTTL = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_TTL)
	WAVE statusHS = DC_ControlStatusWaveCache(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	string TTLWaveList = DC_PopMenuStringList(panelTitle, CHANNEL_TYPE_TTL)
	DFREF deviceDFR = GetDevicePath(panelTitle)

	WAVE sweepDataLNB      = GetSweepSettingsWave(panelTitle)
	WAVE/T sweepDataTxTLNB = GetSweepSettingsTextWave(panelTitle)

	HW_ITC_GetRackRange(rackNo, first, last)

	for(i = first; i <= last; i += 1)

		if(!DC_ChannelIsActive(panelTitle, DATA_ACQUISITION_MODE, CHANNEL_TYPE_TTL, i, statusTTL, statusHS))
			listOfSets = AddListItem("", listOfSets, ";", inf)
			continue
		endif

		set = StringFromList(i, TTLWaveList)
		WAVE wv = WB_CreateAndGetStimSet(set)
		maxRows = max(maxRows, DimSize(wv, ROWS))
		bits += 2^(i)
		listOfSets = AddListItem(set, listOfSets, ";", inf)
	endfor

	if(rackNo == RACK_ZERO)
		sweepDataLNB[0][8][INDEP_HEADSTAGE]    = bits
		sweepDataTxTLNB[0][3][INDEP_HEADSTAGE] = listOfSets
	else
		sweepDataLNB[0][9][INDEP_HEADSTAGE]    = bits
		sweepDataTxTLNB[0][4][INDEP_HEADSTAGE] = listOfSets
	endif

	ASSERT(maxRows > 0, "Expected stim set of non-zero size")
	WAVE TTLWave = GetTTLWave(panelTitle)
	Redimension/N=(maxRows) TTLWave
	FastOp TTLWave = 0

	for(i = first; i <= last; i += 1)

		if(!DC_ChannelIsActive(panelTitle, DATA_ACQUISITION_MODE, CHANNEL_TYPE_TTL, i, statusTTL, statusHS))
			continue
		endif

		set = StringFromList(i, TTLWaveList)
		WAVE TTLStimSet = WB_CreateAndGetStimSet(set)
		col = DC_CalculateChannelColumnNo(panelTitle, set, i, CHANNEL_TYPE_TTL)
		lastIdx = DimSize(TTLStimSet, ROWS) - 1
		bit = 2^(i - first)
		TTLWave[0, lastIdx] += bit * TTLStimSet[p][col]
	endfor
End

/// @brief Returns column number/step of the stimulus set, independent of the times the set is being cycled through
///        (as defined by SetVar_DataAcq_SetRepeats)
///
/// @param panelTitle    panel title
/// @param SetName       name of the stimulus set
/// @param channelNo     channel number
/// @param channelType   channel type, one of @ref CHANNEL_TYPE_DAC or @ref CHANNEL_TYPE_TTL
static Function/C DC_CalculateChannelColumnNo(panelTitle, SetName, channelNo, channelType)
	string panelTitle, SetName
	variable ChannelNo, channelType

	variable ColumnsInSet = IDX_NumberOfTrialsInSet(panelTitle, SetName)
	variable column
	variable CycleCount // when cycleCount = 1 the set has already cycled once.
	variable localCount
	string sequenceWaveName

	DFREF devicePath = GetDevicePath(panelTitle)
	NVAR count = $GetCount(panelTitle)

	// wave exists only if random set sequence is selected
	sequenceWaveName = SetName + num2str(channelType) + num2str(channelNo) + "_S"
	WAVE/Z/SDFR=devicePath WorkingSequenceWave = $sequenceWaveName

	// Below code calculates the variable local count which is then used to determine what column to select from a particular set
	if(IsFinite(count))
		//thus the vairable "count" is used to determine if acquisition is on the first cycle
		ControlInfo/W=$panelTitle Check_DataAcq_Indexing // check indexing status
		if(v_value == 0)// if indexing is off...
			localCount = count
			cycleCount = 0
		else // else is used when indexing is on. The local count is now set length dependent
			ControlInfo/W=$panelTitle Check_DataAcq1_IndexingLocked // check locked status. locked = popup menus on channels idex in lock - step
			if(v_value == 1)
				/// @todo this code here is different compared to what RA_BckgTPwithCallToRACounterMD and RA_CounterMD do
				NVAR activeSetCount = $GetActiveSetCount(panelTitle)
				localCount = IDX_CalculcateActiveSetCount(panelTitle) - activeSetCount
			else
				// calculate where in list global count is
				localCount = IDX_UnlockedIndexingStepNo(panelTitle, channelNo, channelType, count)
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

	ASSERT(IsFinite(column), "column has to be finite")

	return cmplx(column, cycleCount)
End

/// @brief Returns the length increase of the ITCDataWave following onset/termination delay insertion and
/// distributed data aquisition. Does not incorporate adaptations for oodDAQ.
///
/// All returned values are in number of points, *not* in time.
///
/// @param[in] panelTitle                      panel title
/// @param[out] onsetDelayUser [optional]      onset delay set by the user
/// @param[out] onsetDelayAuto [optional]      onset delay required by other settings
/// @param[out] terminationDelay [optional]    termination delay
/// @param[out] distributedDAQDelay [optional] distributed DAQ delay
static Function DC_ReturnTotalLengthIncrease(panelTitle, [onsetDelayUser, onsetDelayAuto, terminationDelay, distributedDAQDelay])
	string panelTitle
	variable &onsetDelayUser, &onsetDelayAuto, &terminationDelay, &distributedDAQDelay

	variable minSamplingInterval, onsetDelayUserVal, onsetDelayAutoVal, terminationDelayVal, distributedDAQDelayVal, numActiveDACs
	variable distributedDAQ

	numActiveDACs          = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_DAC)
	minSamplingInterval    = DAP_GetITCSampInt(panelTitle, DATA_ACQUISITION_MODE)
	distributedDAQ         = GetCheckboxState(panelTitle, "Check_DataAcq1_DistribDaq")
	onsetDelayUserVal      = round(GetSetVariable(panelTitle, "setvar_DataAcq_OnsetDelayUser") / (minSamplingInterval / 1000))
	onsetDelayAutoVal      = round(GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_OnsetDelayAuto") / (minSamplingInterval / 1000))
	terminationDelayVal    = round(GetSetVariable(panelTitle, "setvar_DataAcq_TerminationDelay") / (minSamplingInterval / 1000))
	distributedDAQDelayVal = round(GetSetVariable(panelTitle, "setvar_DataAcq_dDAQDelay") / (minSamplingInterval / 1000))

	if(!ParamIsDefault(onsetDelayUser))
		onsetDelayUser = onsetDelayUserVal
	endif

	if(!ParamIsDefault(onsetDelayAuto))
		onsetDelayAuto = onsetDelayAutoVal
	endif

	if(!ParamIsDefault(terminationDelay))
		terminationDelay = terminationDelayVal
	endif

	if(!ParamIsDefault(distributedDAQDelay))
		distributedDAQDelay = distributedDAQDelayVal
	endif

	if(distributedDAQ)
		ASSERT(numActiveDACs > 0, "Number of DACs must be at least one")
		return onsetDelayUserVal + onsetDelayAutoVal + terminationDelayVal + distributedDAQDelayVal * (numActiveDACs - 1)
	else
		return onsetDelayUserVal + onsetDelayAutoVal + terminationDelayVal
	endif
End

/// @brief Calculate the stop collection point, includes all required global adjustments
static Function DC_GetStopCollectionPoint(panelTitle, dataAcqOrTP, setLengths)
	string panelTitle
	variable dataAcqOrTP
	WAVE setLengths

	variable DAClength, TTLlength, totalIncrease
	DAClength = DC_CalculateLongestSweep(panelTitle, dataAcqOrTP, CHANNEL_TYPE_DAC)

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		totalIncrease = DC_ReturnTotalLengthIncrease(panelTitle)
		TTLlength     = DC_CalculateLongestSweep(panelTitle, DATA_ACQUISITION_MODE, CHANNEL_TYPE_TTL)

		if(GetCheckBoxState(panelTitle, "Check_DataAcq1_dDAQOptOv"))
			DAClength = WaveMax(setLengths)
		elseif(GetCheckBoxState(panelTitle, "Check_DataAcq1_DistribDaq"))
			DAClength *= DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_DAC)
		endif

		return max(DAClength, TTLlength) + totalIncrease
	elseif(dataAcqOrTP == TEST_PULSE_MODE)
		return DAClength
	endif

	ASSERT(0, "unknown mode")
End
