#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DC
#endif

/// @file MIES_DataConfigurator.ipf
/// @brief __DC__ Handle preparations before data acquisition or
/// test pulse related to the DAQ data and config waves

static Structure DC_WriteTTLParams
	variable numDACEntries, numADCEntries, onsetDelay, hardwareType, decimationFactor, dataAcqOrTP
EndStructure

static Structure DC_PrepareLBNEntryParams
	variable distributedDAQ, distributedDAQOptOv, numDACEntries, numADCEntries, dataAcqOrTP, samplingInterval, hardwareType
	WAVE/WAVE stimSet
	WAVE setColumn, setCycleCount
	WAVE DACList, ADCList, headstageDAC, headstageADC, DACAmp, setLength, offsets, statusHS
	WAVE/T setName, regions
EndStructure

// TODO unify param structs
Structure DC_CollectEpochInfoParams
	variable numDACEntries, onsetDelayUser, onsetDelayAuto, onsetDelay, distributedDAQ, distributedDAQOptOv
	variable globalTPInsert, distributedDAQDelay, samplingInterval, terminationDelay, dataAcqOrTP
	WAVE headstageDAC, insertStart, DACList, statusHS, setLength, setColumn, offsets, DACAmp
	variable baselineFrac, testPulseLength
	WAVE/WAVE stimSet
	WAVE/T regions
EndStructure

static Structure DC_FillSetEventFlagParams
	variable numDACEntries
	WAVE DACList, setColumn
	WAVE/T setName
EndStructure

static Structure DC_FillDAQDataWaveForTPParams
	variable numDACEntries, numADCEntries, numActiveChannels, multiDevice, hardwareType, samplingInterval
	WAVE insertStart, setColumn, DAGain, DACAmp
	variable baselineFrac
EndStructure

static Structure DC_FillDAQDataWaveForDAQParams
	variable hardwareType, numActiveChannels, samplingInterval, numDACEntries, decimationFactor, globalTPInsert
	WAVE DACList, headstageDAC, DACAmp, DAGain, setLength, setColumn, insertStart
	WAVE/WAVE stimSet
EndStructure

static Structure DC_FillConfiguratorStruct
	variable globalTPInsert
	variable scalingZero
	variable indexingLocked
	variable indexing
	variable distributedDAQ
	variable distributedDAQOptOv
	variable distributedDAQOptPre
	variable distributedDAQOptPost
	variable decimationFactor
	variable baselineFrac
	WAVE statusHS
	WAVE DAGain
	WAVE DACList
	WAVE ADCList
	// TTLList
	variable numDACEntries
	variable numADCEntries
	// numTTLs
	WAVE/D DACAmp
	WAVE/T setName
	WAVE/WAVE stimSet
	WAVE/D headstageDAC
	WAVE/D headstageADC
	WAVE/D setColumn
	WAVE/D setCycleCount
	variable dataAcqOrTP
	variable numActiveChannels
	variable multiDevice
	WAVE/D setLength
	variable hardwareType
	variable samplingInterval
	WAVE/D insertStart
	variable onsetDelayUser
	variable onsetDelayAuto
	variable onsetDelay
	variable distributedDAQDelay
	variable terminationDelay
	WAVE offsets
	variable testPulseLength
	WAVE/T regions
	WAVE testPulse
EndStructure

/// @brief Update global variables used by the Testpulse or DAQ
///
/// @param panelTitle device
static Function DC_UpdateGlobals(panelTitle)
	string panelTitle

	// we need to update the list of analysis functions here as the stimset
	// can change due to indexing, etc.
	// @todo investigate if this is really required here
	AFM_UpdateAnalysisFunctionWave(panelTitle)

	TP_ReadTPSettingFromGUI(panelTitle)

	SVAR panelTitleG = $GetPanelTitleGlobal()
	panelTitleG = panelTitle

	NVAR tpLengthInPointsTP = $GetTestpulseLengthInPoints(panelTitle, TEST_PULSE_MODE)
	tpLengthInPointsTP = TP_GetTestPulseLengthInPoints(panelTitle, TEST_PULSE_MODE)

	NVAR tpLengthInPointsDAQ = $GetTestpulseLengthInPoints(panelTitle, DATA_ACQUISITION_MODE)
	tpLengthInPointsDAQ = TP_GetTestPulseLengthInPoints(panelTitle, DATA_ACQUISITION_MODE)

	NVAR fifoPosition = $GetFifoPosition(panelTitle)
	fifoPosition = 0
End

/// @brief Prepare test pulse/data acquisition
///
/// @param panelTitle  panel title
/// @param dataAcqOrTP one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param multiDevice [optional: defaults to false] Fine tune data handling for single device (false) or multi device (true)
///
/// @exception Abort configuration failure
Function DC_Configure(panelTitle, dataAcqOrTP, [multiDevice])
	string panelTitle
	variable dataAcqOrTP, multiDevice

	variable numActiveChannels
	variable gotTPChannels
	ASSERT(dataAcqOrTP == DATA_ACQUISITION_MODE || dataAcqOrTP == TEST_PULSE_MODE, "invalid mode")

	if(ParamIsDefault(multiDevice))
		multiDevice = 0
	else
		multiDevice = !!multiDevice
	endif

	if(GetFreeMemory() < FREE_MEMORY_LOWER_LIMIT)
		printf "The amount of free memory is below %gGB, therefore a new experiment is started.\r", FREE_MEMORY_LOWER_LIMIT
		printf "Please be patient while we are performing all the necessary steps.\r"
		ControlWindowToFront()

		SaveExperimentSpecial(SAVE_AND_SPLIT)
	endif

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		if(AFM_CallAnalysisFunctions(panelTitle, PRE_SET_EVENT))
			Abort
		endif

		if(AS_HandlePossibleTransition(panelTitle, AS_PRE_SWEEP_CONFIG))
			Abort
		endif
	endif

	// prevent crash in ITC XOP as it must not run if we resize the DAQDataWave
	NVAR deviceID = $GetDAQDeviceID(panelTitle)
	variable hardwareType = GetHardwareType(panelTitle)
	ASSERT(!HW_IsRunning(hardwareType, deviceID, flags=HARDWARE_ABORT_ON_ERROR | HARDWARE_PREVENT_ERROR_POPUP), "Hardware is still running and it shouldn't. Please report that as a bug.")

	KillOrMoveToTrash(wv=GetSweepSettingsWave(panelTitle))
	KillOrMoveToTrash(wv=GetSweepSettingsTextWave(panelTitle))
	KillOrMoveToTrash(wv=GetSweepSettingsKeyWave(panelTitle))
	KillOrMoveToTrash(wv=GetSweepSettingsTextKeyWave(panelTitle))

	DC_UpdateGlobals(panelTitle)

	numActiveChannels = DC_ChannelCalcForDAQConfigWave(panelTitle, dataAcqOrTP)
	DC_MakeDAQConfigWave(panelTitle, numActiveChannels)

	DC_PlaceDataInDAQConfigWave(panelTitle, dataAcqOrTP)

	TP_CreateTestPulseWave(panelTitle, dataAcqOrTP)

	DC_PlaceDataInDAQDataWave(panelTitle, numActiveChannels, dataAcqOrTP, multiDevice)

	WAVE DAQConfigWave = GetDAQConfigWave(panelTitle)
	WAVE ADCs = GetADCListFromConfig(DAQConfigWave)
	DC_UpdateHSProperties(panelTitle, ADCs)

	NVAR ADChannelToMonitor = $GetADChannelToMonitor(panelTitle)
	ADChannelToMonitor = DimSize(GetDACListFromConfig(DAQConfigWave), ROWS)

	gotTPChannels = GotTPChannelsOnADCs(paneltitle)

	if(dataAcqOrTP == TEST_PULSE_MODE || gotTPChannels)
		TP_CreateTPAvgBuffer(panelTitle)
	endif

	DC_MakeHelperWaves(panelTitle, dataAcqOrTP)
	SCOPE_CreateGraph(panelTitle, dataAcqOrTP)

	WAVE DAQDataWave = GetDAQDataWave(panelTitle, dataAcqOrTP)
	WAVE DAQConfigWave = GetDAQConfigWave(panelTitle)

	ASSERT(IsValidSweepAndConfig(DAQDataWave, DAQConfigWave), "Invalid sweep and config combination")

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		AS_HandlePossibleTransition(panelTitle, AS_PRE_SWEEP)
	endif
End

static Function DC_UpdateHSProperties(panelTitle, ADCs)
	string panelTitle
	WAVE ADCs

	variable i, numChannels, headStage

	WAVE hsProp = GetHSProperties(panelTitle)

	hsProp = NaN
	hsProp[][%Enabled] = 0

	numChannels = DimSize(ADCs, ROWS)
	for(i = 0; i < numChannels; i += 1)
		headstage = AFH_GetHeadstageFromADC(panelTitle, ADCs[i])

		if(!IsFinite(headstage))
			continue
		endif

		hsProp[headStage][%Enabled]   = 1
		hsProp[headStage][%ADC]       = ADCs[i]
		hsProp[headStage][%DAC]       = AFH_GetDACFromHeadstage(panelTitle, headstage)
		hsProp[headStage][%ClampMode] = DAG_GetHeadstageMode(panelTitle, headStage)

	endfor
End

/// @brief Return the number of selected checkboxes for the given type
static Function DC_NoOfChannelsSelected(panelTitle, type)
	string panelTitle
	variable type

	return sum(DAG_GetChannelState(panelTitle, type))
End

/// @brief Returns the total number of combined channel types (DA, AD, and front TTLs) selected in the DA_Ephys Gui
///
/// @param panelTitle  panel title
/// @param dataAcqOrTP acquisition mode, one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_ChannelCalcForDAQConfigWave(panelTitle, dataAcqOrTP)
	string panelTitle
	variable dataAcqOrTP

	variable numDACs, numADCs, numTTLsRackZero, numTTLsRackOne, numActiveHeadstages
	variable numTTLs

	variable hardwareType = GetHardwareType(panelTitle)
	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			if(dataAcqOrTP == DATA_ACQUISITION_MODE)
				numDACs         = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_DAC)
				numADCs         = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_ADC)
				numTTLsRackZero = DC_AreTTLsInRackChecked(panelTitle, RACK_ZERO)
				numTTLsRackOne  = DC_AreTTLsInRackChecked(panelTitle, RACK_ONE)
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
			break
		case HARDWARE_NI_DAC:
			if(dataAcqOrTP == DATA_ACQUISITION_MODE)
				numDACs = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_DAC)
				numADCs = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_ADC)
				numTTLs = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_TTL)
			elseif(dataAcqOrTP == TEST_PULSE_MODE)
				numActiveHeadstages = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_HEADSTAGE)
				numDACs = numActiveHeadstages
				numADCs = numActiveHeadstages
				numTTLs = 0
			else
				ASSERT(0, "Unknown value of dataAcqOrTP")
			endif
			return numDACs + numADCs + numTTLs
			break
	endswitch

	return NaN
END

/// @brief Returns the ON/OFF status of the front TTLs on a specified rack.
///
/// @param panelTitle  device
/// @param rackNo      Only the ITC1600 can have two racks. For all other ITC devices RackNo = 0.
static Function DC_AreTTLsInRackChecked(panelTitle, rackNo)
	string panelTitle
	variable rackNo

	variable first, last

	HW_ITC_GetRackRange(rackNo, first, last)
	WAVE statusTTL = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_TTL)

	return Sum(statusTTL, first, last) > 0
End

/// @brief Returns the number of points in the longest stimset
///
/// @param panelTitle  device
/// @param dataAcqOrTP acquisition mode, one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param channelType channel type, one of @ref ChannelTypeAndControlConstants
static Function DC_LongestOutputWave(panelTitle, dataAcqOrTP, channelType)
	string panelTitle
	variable dataAcqOrTP, channelType

	variable maxNumRows, i, numEntries, numPulses, singlePulseLength

	WAVE statusFiltered = DC_GetFilteredChannelState(panelTitle, dataAcqOrTP, channelType)
	WAVE/T stimsets     = DAG_GetChannelTextual(panelTitle, channelType, CHANNEL_CONTROL_WAVE)

	numEntries = DimSize(statusFiltered, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!statusFiltered[i])
			continue
		endif

		if(dataAcqOrTP == DATA_ACQUISITION_MODE)
			WAVE/Z wv = WB_CreateAndGetStimSet(stimsets[i])
		elseif(dataAcqOrTP == TEST_PULSE_MODE)
			WAVE/Z wv = GetTestPulse()
		else
			ASSERT(0, "unhandled case")
		endif

		if(!WaveExists(wv))
			continue
		endif

		if(dataAcqOrTP == TEST_PULSE_MODE                             \
		   && GetHardwareType(panelTitle) == HARDWARE_ITC_DAC         \
		   && DAG_GetNumericalValue(panelTitle, "check_Settings_MD"))
			// ITC hardware requires us to use a pulse train for TP MD,
			// so we need to determine the number of TP pulses here (numPulses)
			// In DC_PlaceDataInDAQDataWave we write as many pulses into the
			// DAQDataWave which fit in
			singlePulseLength = DimSize(wv, ROWS)
			numPulses = max(10, ceil((2^(MINIMUM_ITCDATAWAVE_EXPONENT + 1) * 0.90) / singlePulseLength))
			maxNumRows = max(maxNumRows, numPulses * singlePulseLength)
		else
			maxNumRows = max(maxNumRows, DimSize(wv, ROWS))
		endif
	endfor

	return maxNumRows
End

//// @brief Calculate the required length of the DAQDataWave
///
/// ITC Hardware:
/// - The DAQDataWave length = 2^x where is the first integer large enough to contain the longest output wave plus one.
///   X also has a minimum value of 17 to ensure sufficient time for communication with the ITC device to prevent FIFO overflow or underrun.
///
/// NI Hardware:
/// - Returns stopCollectionPoint
///
/// @param panelTitle  panel title
/// @param dataAcqOrTP acquisition mode, one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_CalculateDAQDataWaveLength(panelTitle, dataAcqOrTP)
	string panelTitle
	variable dataAcqOrTP

	variable hardwareType = GetHardwareType(panelTitle)
	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			variable exponent = FindNextPower(stopCollectionPoint, 2)

			if(dataAcqOrTP == DATA_ACQUISITION_MODE)
				exponent += 1
			endif

			exponent = max(MINIMUM_ITCDATAWAVE_EXPONENT, exponent)

			return 2^exponent
			break
		case HARDWARE_NI_DAC:
			return stopCollectionPoint
			break
	endswitch
	return NaN
end

/// @brief Create the DAQConfigWave used to configure the DAQ device
///
/// @param panelTitle  panel title
/// @param numActiveChannels number of active channels as returned by DC_ChannelCalcForDAQConfigWave()
static Function DC_MakeDAQConfigWave(panelTitle, numActiveChannels)
	string panelTitle
	variable numActiveChannels

	WAVE config = GetDAQConfigWave(panelTitle)

	Redimension/N=(numActiveChannels, -1) config
	FastOp config = 0

	ASSERT(IsValidConfigWave(config), "Invalid config wave")
End

/// @brief Creates DAQDataWave; The wave that the device takes DA and TTL data from and passes AD data to for all channels.
///
/// Config all refers to configuring all the channels at once
///
/// @param panelTitle          panel title
/// @param hardwareType        hardware type
/// @param numActiveChannels   number of active channels as returned by DC_ChannelCalcForDAQConfigWave()
/// @param samplingInterval    sampling interval as returned by DAP_GetSampInt()
/// @param dataAcqOrTP         one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function [WAVE/Z DAQDataWave, WAVE/WAVE NIDataWave] DC_MakeAndGetDAQDataWave(string panelTitle, variable hardwareType, variable numActiveChannels, variable samplingInterval, variable dataAcqOrTP)
	variable numRows, i

	numRows = DC_CalculateDAQDataWaveLength(panelTitle, dataAcqOrTP)
	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			WAVE ITCDataWave = GetDAQDataWave(panelTitle, dataAcqOrTP)

			Redimension/N=(numRows, numActiveChannels) ITCDataWave

			FastOp ITCDataWave = 0
			SetScale/P x 0, samplingInterval / 1000, "ms", ITCDataWave

			return [ITCDataWave, $""]
			break
		case HARDWARE_NI_DAC:
			WAVE/WAVE NIDataWave = GetDAQDataWave(panelTitle, dataAcqOrTP)
			Redimension/N=(numActiveChannels) NIDataWave

			SetScale/P x 0, samplingInterval / 1000, "ms", NIDataWave

			Make/FREE/N=(numActiveChannels) type = SWS_GetRawDataFPType(panelTitle)
			WAVE config = GetDAQConfigWave(panelTitle)
			type = config[p][%ChannelType] == XOP_CHANNEL_TYPE_TTL ? IGOR_TYPE_UNSIGNED | IGOR_TYPE_8BIT_INT : type[p]
			NIDataWave = DC_MakeNIChannelWave(panelTitle, numRows, samplingInterval, p, type[p])

			return [$"", NIDataWave]
			break
	endswitch
End

/// @brief Creates a single NIChannel wave
///
/// Config all refers to configuring all the channels at once
///
/// @param panelTitle       panel title
/// @param numRows          size of the 1D channel wave
/// @param samplingInterval minimum sample intervall in microseconds
/// @param index            number of NI channel
/// @param type             numeric data type of NI channel
///
/// @return                 Wave Reference to NI Channel wave
static Function/WAVE DC_MakeNIChannelWave(panelTitle, numRows, samplingInterval, index, type)
	variable numRows, samplingInterval, index, type
	string panelTitle

	WAVE NIChannel = GetNIDAQChannelWave(panelTitle, index)
	Redimension/N=(numRows)/Y=(type) NIChannel
	FastOp NIChannel= 0
	SetScale/P x 0, samplingInterval / 1000, "ms", NIChannel

	return NIChannel
End

/// @brief Initializes the waves used for displaying DAQ/TP results in the
/// oscilloscope window and the scaled data wave
///
/// @param panelTitle  panel title
/// @param dataAcqOrTP one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_MakeHelperWaves(panelTitle, dataAcqOrTP)
	string panelTitle
	variable dataAcqOrTP

	variable numRows, sampleInterval, col, hardwareType, decimatedNumRows, numPixels, dataPointsPerPixel
	variable decMethod, decFactor, tpLength, numADCs, numDACs, numTTLs, decimatedSampleInterval
	variable tpOrPowerSpectrumLength

	WAVE config = GetDAQConfigWave(panelTitle)
	WAVE OscilloscopeData = GetOscilloscopeWave(panelTitle)
	WAVE TPOscilloscopeData = GetTPOscilloscopeWave(panelTitle)
	WAVE scaledDataWave = GetScaledDataWave(panelTitle)
	WAVE ITCDataWave = GetDAQDataWave(panelTitle, dataAcqOrTP)
	WAVE/WAVE NIDataWave = GetDAQDataWave(panelTitle, dataAcqOrTP)

	hardwareType = GetHardwareType(panelTitle)

	numADCs = DimSize(GetADCListFromConfig(config), ROWS)
	numDACs = DimSize(GetDACListFromConfig(config), ROWS)
	numTTLs = DimSize(GetTTLListFromConfig(config), ROWS)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			sampleInterval = DimDelta(ITCDataWave, ROWS)
			break
		case HARDWARE_NI_DAC:
			sampleInterval = DimDelta(NIDataWave[0], ROWS)
			break
	endswitch

	if(dataAcqOrTP == TEST_PULSE_MODE)
		tpLength = ROVAR(GetTestPulseLengthInPoints(panelTitle, TEST_PULSE_MODE))
		numRows = tpLength

		decMethod = DECIMATION_NONE
		decFactor = NaN

		decimatedNumRows        = tpLength
		decimatedSampleInterval = sampleInterval

		if(DAG_GetNumericalValue(panelTitle, "check_settings_show_power"))
			tpOrPowerSpectrumLength  = floor(tpLength / 2) + 1
		else
			tpOrPowerSpectrumLength = tpLength
		endif

	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)
		tpLength = NaN

		switch(hardwareType)
			case HARDWARE_ITC_DAC:
				numRows = DimSize(ITCDataWave, ROWS)
				break
			case HARDWARE_NI_DAC:
				numRows = DimSize(NIDataWave[0], ROWS)
				break
		endswitch

		NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)

		decMethod = DAG_GetNumericalValue(panelTitle, "Popup_Settings_DecMethod")
		decFactor = DEFAULT_DECIMATION_FACTOR

		switch(decMethod)
			case DECIMATION_NONE:
				decFactor = 1
				decimatedNumRows = numRows
				decimatedSampleInterval = sampleInterval
				break
			default:
				STRUCT RectD s
				GetPlotArea(SCOPE_GetGraph(panelTitle), s)

				// use twice as many pixels as we need
				// but round to a power of two
				numPixels = s.right - s.left
				dataPointsPerPixel = trunc((stopCollectionPoint / (numPixels * 2)))
				if(dataPointsPerPixel > 2)
					decFactor = 2^FindPreviousPower(dataPointsPerPixel, 2)
					decimatedNumRows = GetDecimatedWaveSize(numRows, decFactor, decMethod)
					decimatedSampleInterval = sampleInterval * decFactor
				else
					// turn off decimation for very short stimsets
					decMethod = DECIMATION_NONE
					decFactor = 1
					decimatedNumRows = numRows
					decimatedSampleInterval = sampleInterval
				endif
				break
		endswitch
	else
		ASSERT(0, "Invalid dataAcqOrTP")
	endif

	SetNumberInWaveNote(OscilloscopeData, "DecimationMethod", decMethod)
	SetNumberInWaveNote(OscilloscopeData, "DecimationFactor", decFactor)

	DC_InitDataHoldingWave(TPOscilloscopeData, tpOrPowerSpectrumLength, sampleInterval, numDACs, numADCs, numTTLs, isFourierTransform=DAG_GetNumericalValue(panelTitle, "check_settings_show_power") && dataAcqOrTP == TEST_PULSE_MODE)
	DC_InitDataHoldingWave(OscilloscopeData, decimatedNumRows, decimatedSampleInterval, numDACs, numADCs, numTTLs)

	DC_InitDataHoldingWave(scaledDataWave, dataAcqOrTP == DATA_ACQUISITION_MODE ? stopCollectionPoint : tpLength, sampleInterval, numDACs, numADCs, numTTLs, type = SWS_GetRawDataFPType(panelTitle))
End

/// @brief Initialize data holding waves to NaN
static Function DC_InitDataHoldingWave(wv, numRows, sampleInterval, numDACs, numADCs, numTTLs, [type, isFourierTransform])
	WAVE wv
	variable numRows, sampleInterval, numDACs, numADCs, numTTLs, type, isFourierTransform

	ASSERT(numDACs > 0, "Invalid number of DACs")
	ASSERT(numADCs > 0, "Invalid number of ADCs")

	if(ParamIsDefault(type))
		type = WaveType(wv)
	endif

	if(ParamIsDefault(isFourierTransform))
		isFourierTransform = 0
	else
		isFourierTransform = !!isFourierTransform
	endif

	Redimension/N=(numRows, numDACs + numADCs + numTTLs)/Y=(type) wv

	if(isFourierTransform)
		SetScale/I x, 0, 1 / (2 * (sampleInterval / 1000)), "Hz", wv
	else
		SetScale/P x, 0, sampleInterval, "ms", wv
	endif

	ASSERT(IsFloatingPointWave(wv), "Wave is not of floating point type")

	MultiThread wv[][] = NaN
End

/// @brief Return the list of active channels, filtered for various special cases
///
/// @param panelTitle     panel title
/// @param dataAcqOrTP    one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param channelType    one of the channel type constants from @ref ChannelTypeAndControlConstants
/// @param DAQChannelType only return channels as active if they have the desired DAQChannel type (only respected for DA channel)
Function/WAVE DC_GetFilteredChannelState(panelTitle, dataAcqOrTP, channelType, [DAQChannelType])
	string panelTitle
	variable dataAcqOrTP, channelType, DAQChannelType

	if(ParamIsDefault(DAQChannelType))
		DAQChannelType = DAQ_CHANNEL_TYPE_UNKOWN
	endif

	ASSERT(DAQChannelType == DAQ_CHANNEL_TYPE_UNKOWN || DAQChannelType == DAQ_CHANNEL_TYPE_DAQ || DAQChannelType == DAQ_CHANNEL_TYPE_TP, "Invalid DAQChannelType")

	WAVE statusChannel = DAG_GetChannelState(panelTitle, channelType)

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		switch(channelType)
			case CHANNEL_TYPE_TTL:
			case CHANNEL_TYPE_ADC:
				// DAQChannelType does not matter
				return statusChannel
				break
			case CHANNEL_TYPE_DAC:
				if(DAQChannelType == DAQ_CHANNEL_TYPE_UNKOWN)
					return statusChannel
				endif

				Make/FREE/N=(NUM_DA_TTL_CHANNELS) result = 0

				WAVE/T allSetNames = DAG_GetChannelTextual(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)

				result[] = statusChannel[p] && (!cmpstr(allSetNames[p], STIMSET_TP_WHILE_DAQ, 1) \
												? DAQChannelType == DAQ_CHANNEL_TYPE_TP          \
												: DAQChannelType == DAQ_CHANNEL_TYPE_DAQ)

				return result

				break
			default:
				ASSERT(0, "unhandled case")
				break
		endswitch
	endif

	switch(channelType)
		case CHANNEL_TYPE_TTL:
			// TTL channels are always considered inactive for the testpulse
			Make/FREE/N=(NUM_DA_TTL_CHANNELS) result = 0
			return result
			break
		case CHANNEL_TYPE_ADC:
			Make/FREE/N=(NUM_AD_CHANNELS) result = AFH_GetHeadstageFromADC(panelTitle, p)
			break
		case CHANNEL_TYPE_DAC:
			Make/FREE/N=(NUM_DA_TTL_CHANNELS) result = AFH_GetHeadstageFromDAC(panelTitle, p)
			break
		default:
			ASSERT(0, "unhandled case")
			break
	endswitch

	WAVE statusHS = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	result[] = IsFinite(result[p]) && statusHS[result[p]]

	return result
End

/// @brief Places channel (DA, AD, and TTL) settings data into DAQConfigWave
///
/// @param panelTitle  panel title
/// @param dataAcqOrTP one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_PlaceDataInDAQConfigWave(panelTitle, dataAcqOrTP)
	string panelTitle
	variable dataAcqOrTP

	variable i, j, numEntries, ret, channel
	variable col, adc, dac, headstage
	string ctrl, deviceType, deviceNumber
	string unitList = ""

	WAVE DAQConfigWave = GetDAQConfigWave(panelTitle)

	// query DA properties
	WAVE statusDAFiltered = DC_GetFilteredChannelState(panelTitle, dataAcqOrTP, CHANNEL_TYPE_DAC)
	WAVE/T allSetNames    = DAG_GetChannelTextual(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	ctrl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)

	numEntries = DimSize(statusDAFiltered, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!statusDAFiltered[i])
			continue
		endif

		DAQConfigWave[j][%ChannelType]   = XOP_CHANNEL_TYPE_DAC
		DAQConfigWave[j][%ChannelNumber] = i
		unitList = AddListItem(DAG_GetTextualValue(panelTitle, ctrl, index = i), unitList, ",", Inf)
		DAQConfigWave[j][%DAQChannelType] = !CmpStr(allSetNames[i], STIMSET_TP_WHILE_DAQ, 1) || dataAcqOrTP == TEST_PULSE_MODE ? DAQ_CHANNEL_TYPE_TP : DAQ_CHANNEL_TYPE_DAQ
		j += 1
	endfor

	// query AD properties
	WAVE statusADFiltered = DC_GetFilteredChannelState(panelTitle, dataAcqOrTP, CHANNEL_TYPE_ADC)

	ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)

	numEntries = DimSize(statusADFiltered, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!statusADFiltered[i])
			continue
		endif

		DAQConfigWave[j][%ChannelType]   = XOP_CHANNEL_TYPE_ADC
		DAQConfigWave[j][%ChannelNumber] = i
		unitList = AddListItem(DAG_GetTextualValue(panelTitle, ctrl, index = i), unitList, ",", Inf)

		headstage = AFH_GetHeadstageFromADC(panelTitle, i)

		if(IsFinite(headstage))
			// use the same channel type as the DAC
			DAQConfigWave[j][%DAQChannelType] = DC_GetChannelTypefromHS(panelTitle, headstage)
		else
			// unassociated ADCs are always of DAQ type
			DAQConfigWave[j][%DAQChannelType] = DAQ_CHANNEL_TYPE_DAQ
		endif

		j += 1
	endfor

	AddEntryIntoWaveNoteAsList(DAQConfigWave, CHANNEL_UNIT_KEY, str = unitList, replaceEntry = 1)

	DAQConfigWave[][%SamplingInterval] = DAP_GetSampInt(panelTitle, dataAcqOrTP)
	DAQConfigWave[][%DecimationMode]   = 0
	DAQConfigWave[][%Offset]           = 0

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		variable hardwareType = GetHardwareType(panelTitle)
		switch(hardwareType)
			case HARDWARE_ITC_DAC:
				WAVE sweepDataLNB = GetSweepSettingsWave(panelTitle)

				if(DC_AreTTLsInRackChecked(panelTitle, RACK_ZERO))
					DAQConfigWave[j][%ChannelType] = XOP_CHANNEL_TYPE_TTL

					channel = HW_ITC_GetITCXOPChannelForRack(panelTitle, RACK_ZERO)
					DAQConfigWave[j][%ChannelNumber] = channel
					sweepDataLNB[0][10][INDEP_HEADSTAGE] = channel
					DAQConfigWave[j][%DAQChannelType] = DAQ_CHANNEL_TYPE_DAQ

					j += 1
				endif

				if(DC_AreTTLsInRackChecked(panelTitle, RACK_ONE))
					DAQConfigWave[j][%ChannelType] = XOP_CHANNEL_TYPE_TTL

					channel = HW_ITC_GetITCXOPChannelForRack(panelTitle, RACK_ONE)
					DAQConfigWave[j][%ChannelNumber] = channel
					sweepDataLNB[0][11][INDEP_HEADSTAGE] = channel
					DAQConfigWave[j][%DAQChannelType] = DAQ_CHANNEL_TYPE_DAQ
				endif
				break
			case HARDWARE_NI_DAC:
				WAVE statusTTL = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_TTL)
				for(i = 0; i < numpnts(statusTTL); i += 1)
					if(statusTTL[i])
						DAQConfigWave[j][%ChannelType] = XOP_CHANNEL_TYPE_TTL
						DAQConfigWave[j][%ChannelNumber] = i
						DAQConfigWave[j][%DAQChannelType] = DAQ_CHANNEL_TYPE_DAQ
						j += 1
					endif
				endfor
				break
		endswitch
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

	return DAP_GetSampInt(panelTitle, dataAcqOrTP) / (WAVEBUILDER_MIN_SAMPINT * 1000)
End

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

	return DC_CalculateGeneratedDataSize(panelTitle, dataAcqOrTP, DC_LongestOutputWave(panelTitle, dataAcqOrTP, channelType))
End

/// @brief Get the stimset length for the real sampling interval
///
/// @param stimSet          stimset wave
/// @param panelTitle 		 device
/// @param dataAcqOrTP      one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_CalculateStimsetLength(stimSet, panelTitle, dataAcqOrTP)
	WAVE stimSet
	string panelTitle
	variable dataAcqOrTP

	return DC_CalculateGeneratedDataSize(panelTitle, dataAcqOrTP, DimSize(stimSet, ROWS))
End

/// @brief Get the length for the real sampling interval from a generated wave with length
///
/// @param panelTitle 		 device
/// @param dataAcqOrTP      one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param genLength        length of a generated data wave
static Function DC_CalculateGeneratedDataSize(panelTitle, dataAcqOrTP, genLength)
	string panelTitle
	variable dataAcqOrTP, genLength

	// note: the decimationFactor is the factor between the hardware sample rate and the sample rate of the generated waveform in singleStimSet
	// The ratio of the source to target wave sizes is however limited by the integer size of both waves
	// While ideally srcLength == tgtLength the floor(...) limits the real data wave length such that
	// when decimationFactor * index of real data wave is applied as index of the generated data wave it never exceeds its size
	// Also if decimationFactor >= 2 the last point of the generated data wave is never transferred
	// e.g. generated data with 10 points and decimationFactor == 2 copies index 0, 2, 4, 6, 8 to the real data wave of size 5
	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		return floor(genLength / DC_GetDecimationFactor(panelTitle, dataAcqOrTP))
	elseif(dataAcqOrTP == TEST_PULSE_MODE)
		return genLength
	else
		ASSERT(0, "unhandled case")
	endif
End

/// @brief Places data from appropriate DA and TTL stimulus set(s) into DAQDataWave.
/// Also records certain DA_Ephys GUI settings into sweepDataLNB and sweepDataTxTLNB
/// @param panelTitle        panel title
/// @param numActiveChannels number of active channels as returned by DC_ChannelCalcForDAQConfigWave()
/// @param dataAcqOrTP       one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param multiDevice       Fine tune data handling for single device (false) or multi device (true)
///
/// @exception Abort configuration failure
static Function DC_PlaceDataInDAQDataWave(panelTitle, numActiveChannels, dataAcqOrTP, multiDevice)
	string panelTitle
	variable numActiveChannels, dataAcqOrTP, multiDevice

	variable ret, row, column

	STRUCT DC_FillConfiguratorStruct s
	[s] = DC_FillConfigurator(panelTitle, numActiveChannels, dataAcqOrTP, multiDevice)

	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	stopCollectionPoint = DC_GetStopCollectionPoint(panelTitle, s.dataAcqOrTP, s.setLength)

	ClearRTError()

	if(dataAcqOrTP == TEST_PULSE_MODE)
		STRUCT DC_FillDAQDataWaveForTPParams fillTPParams
		fillTPParams.numDACEntries     = s.numDACEntries
		fillTPParams.numADCEntries     = s.numADCEntries
		fillTPParams.numActiveChannels = s.numActiveChannels
		fillTPParams.multiDevice       = s.multiDevice
		fillTPParams.hardwareType      = s.hardwareType
		fillTPParams.samplingInterval  = s.samplingInterval
		fillTPParams.insertStart       = s.insertStart
		fillTPParams.setColumn         = s.setColumn
		fillTPParams.DAGain            = s.DAGain
		fillTPParams.DACAmp            = s.DACAmp
		fillTPParams.baselinefrac      = s.baselinefrac
		DC_FillDAQDataWaveForTP(panelTitle, fillTPParams)
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)
		STRUCT DC_FillDAQDataWaveForDAQParams fillDAQParams
		fillDAQParams.hardwareType      = s.hardwareType
		fillDAQParams.numActiveChannels = s.numActiveChannels
		fillDAQParams.samplingInterval  = s.samplingInterval
		fillDAQParams.numDACEntries     = s.numDACEntries
		fillDAQParams.decimationFactor  = s.decimationFactor
		fillDAQParams.globalTPInsert    = s.globalTPInsert
		WAVE fillDAQParams.DACList      = s.DACList
		WAVE fillDAQParams.headstageDAC = s.headstageDAC
		WAVE fillDAQParams.DACAmp       = s.DACAmp
		WAVE fillDAQParams.DAGain       = s.DAGain
		WAVE fillDAQParams.setLength    = s.setLength
		WAVE fillDAQParams.setColumn    = s.setColumn
		WAVE fillDAQParams.insertStart  = s.insertStart
		WAVE/WAVE fillDAQParams.stimSet = s.stimSet
		DC_FillDAQDataWaveForDAQ(panelTitle, fillDAQParams)
	endif

	STRUCT DC_CollectEpochInfoParams epochParams
	epochParams.numDACEntries       = s.numDACEntries
	epochParams.onsetDelayUser      = s.onsetDelayUser
	epochParams.onsetDelayAuto      = s.onsetDelayAuto
	epochParams.onSetDelay          = s.onSetDelay
	epochParams.distributedDAQ      = s.distributedDAQ
	epochParams.distributedDAQOptOv = s.distributedDAQOptOv
	epochParams.globalTPInsert      = s.globalTPInsert
	epochParams.distributedDAQDelay = s.distributedDAQDelay
	epochParams.samplingInterval    = s.samplingInterval
	epochParams.terminationDelay    = s.terminationDelay
	epochParams.dataAcqOrTP         = s.dataAcqOrTP
	WAVE epochParams.headstageDAC   = s.headstageDAC
	WAVE epochParams.insertStart    = s.insertStart
	WAVE epochParams.DACList        = s.DACList
	WAVE epochParams.statusHS       = s.statusHS
	WAVE epochParams.setLength      = s.setLength
	WAVE epochParams.setColumn      = s.setColumn
	WAVE epochParams.offsets        = s.offsets
	WAVE epochParams.DACAmp         = s.DACAmp
	epochParams.baselineFrac        = s.baselineFrac
	epochParams.testPulseLength     = s.testPulseLength
	WAVE/WAVE epochParams.stimSet   = s.stimSet
	WAVE/T epochParams.regions      = s.regions
	EP_CollectEpochInfo(panelTitle, epochParams)

	STRUCT DC_PrepareLBNEntryParams prepLBNParams
	prepLBNParams.distributedDAQ      = s.distributedDAQ
	prepLBNParams.distributedDAQOptOv = s.distributedDAQOptOv
	prepLBNParams.numDACEntries       = s.numDACEntries
	prepLBNParams.numADCEntries       = s.numADCEntries
	prepLBNParams.dataAcqOrTP         = s.dataAcqOrTP
	prepLBNParams.samplingInterval    = s.samplingInterval
	prepLBNParams.hardwareType        = s.hardwareType
	WAVE/WAVE prepLBNParams.stimSet   = s.stimSet
	WAVE prepLBNParams.setColumn      = s.setColumn
	WAVE prepLBNParams.setCycleCount  = s.setCycleCount
	WAVE prepLBNParams.DACList        = s.DACList
	WAVE prepLBNParams.ADCList        = s.ADCList
	WAVE prepLBNParams.headstageDAC   = s.headstageDAC
	WAVE prepLBNParams.headstageADC   = s.headstageADC
	WAVE prepLBNParams.DACAmp         = s.DACAmp
	WAVE prepLBNParams.setLength      = s.setLength
	WAVE prepLBNParams.offsets        = s.offsets
	WAVE prepLBNParams.statusHS       = s.statusHS
	WAVE/T prepLBNParams.setName      = s.setName
	WAVE/T prepLBNParams.regions      = s.regions

	DC_PrepareLBNEntries(panelTitle, prepLBNParams)

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		STRUCT DC_WriteTTLParams ttlParams
		ttlParams.dataAcqOrTP      = s.dataAcqOrTP
		ttlParams.decimationFactor = s.decimationFactor
		ttlParams.hardwareType     = s.hardwareType
		ttlParams.onsetDelay       = s.onsetDelay
		ttlParams.numADCEntries    = s.numADCEntries
		ttlParams.numDACEntries    = s.numDACEntries
		DC_WriteTTLIntoDAQDataWave(panelTitle, ttlParams)
	endif

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		STRUCT DC_FillSetEventFlagParams setEventFlagParams
		setEventFlagParams.numDACEntries  = s.numDACEntries
		WAVE setEventFlagParams.DACList   = s.DACList
		WAVE setEventFlagParams.setColumn = s.setColumn
		WAVE/T setEventFlagParams.setName = s.setName
		DC_FillSetEventFlag(panelTitle, setEventFlagParams)
	endif

	[ret, row, column] = DC_CheckIfDataWaveHasBorderVals(panelTitle, dataAcqOrTP)

	if(ret)
		printf "Error writing into DataWave in %s mode: The values at [%g, %g] are out of range. Maybe the DA/AD Gain needs adjustment?\r", SelectString(dataAcqOrTP, "DATA_ACQUISITION", "TestPulse"), row, column
		ControlWindowToFront()
		Abort
	endif
End

static Function DC_WriteTTLIntoDAQDataWave(string panelTitle, STRUCT DC_WriteTTLParams &s)
	variable i, startOffset, ttlIndex, singleSetLength, numRows

	// reset to the default value without distributedDAQ
	startOffset = s.onSetDelay
	ttlIndex = s.numDACEntries + s.numADCEntries

	WAVE config = GetDAQConfigWave(panelTitle)

	WAVE TTLList = GetTTLListFromConfig(config)

	if(DimSize(TTLList, ROWS) == 0)
		return NaN
	endif

	switch(s.hardwareType)
		case HARDWARE_NI_DAC:
			WAVE/WAVE NIDataWave = GetDAQDataWave(panelTitle, s.dataAcqOrTP)

			WAVE/WAVE TTLWaveNI = GetTTLWave(panelTitle)
			DC_NI_MakeTTLWave(panelTitle)

			numRows = DimSize(config, ROWS)
			for(i = 0; i < numRows; i += 1)
				if(config[i][%ChannelType] == XOP_CHANNEL_TYPE_TTL)
					WAVE NIChannel = NIDataWave[ttlIndex]
					WAVE TTLWaveSingle = TTLWaveNI[config[i][%ChannelNumber]]
					singleSetLength = DC_CalculateStimsetLength(TTLWaveSingle, panelTitle, DATA_ACQUISITION_MODE)
					MultiThread NIChannel[startOffset, startOffset + singleSetLength - 1] = \
					limit(TTLWaveSingle[trunc(s.decimationFactor * (p - startOffset))], 0, 1); AbortOnRTE
					ttlIndex += 1
				endif
			endfor
			break
		case HARDWARE_ITC_DAC:
			WAVE ITCDataWave = GetDAQDataWave(panelTitle, s.dataAcqOrTP)

			WAVE TTLWaveITC = GetTTLWave(panelTitle)

			// Place TTL waves into ITCDataWave
			if(DC_AreTTLsInRackChecked(panelTitle, RACK_ZERO))
				DC_ITC_MakeTTLWave(panelTitle, RACK_ZERO)
				singleSetLength = DC_CalculateStimsetLength(TTLWaveITC, panelTitle, DATA_ACQUISITION_MODE)
				MultiThread ITCDataWave[startOffset, startOffset + singleSetLength - 1][ttlIndex] = \
				limit(TTLWaveITC[trunc(s.decimationFactor * (p - startOffset))], SIGNED_INT_16BIT_MIN, SIGNED_INT_16BIT_MAX); AbortOnRTE
				ttlIndex += 1
			endif

			if(DC_AreTTLsInRackChecked(panelTitle, RACK_ONE))
				DC_ITC_MakeTTLWave(panelTitle, RACK_ONE)
				singleSetLength = DC_CalculateStimsetLength(TTLWaveITC, panelTitle, DATA_ACQUISITION_MODE)
				MultiThread ITCDataWave[startOffset, startOffset + singleSetLength - 1][ttlIndex] = \
				limit(TTLWaveITC[trunc(s.decimationFactor * (p - startOffset))], SIGNED_INT_16BIT_MIN, SIGNED_INT_16BIT_MAX); AbortOnRTE
			endif
			break
	endswitch
End

static Function DC_PrepareLBNEntries(string panelTitle, STRUCT DC_PrepareLBNEntryParams &s)
	variable i, j, maxITI, channel, headstage, setChecksum, fingerprint, stimsetCycleID, isoodDAQMember
	string func, ctrl, str

	WAVE config = GetDAQConfigWave(panelTitle)

	WAVE/T allIndexingEndSetNames = DAG_GetChannelTextual(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
	WAVE/T cellElectrodeNames = GetCellElectrodeNames(panelTitle)
	WAVE/T analysisFunctions  = GetAnalysisFunctionStorage(panelTitle)

	NVAR raCycleID = $GetRepeatedAcquisitionCycleID(panelTitle)
	if(s.dataAcqOrTP == DATA_ACQUISITION_MODE)
		ASSERT(IsFinite(raCycleID), "Uninitialized raCycleID detected")
	endif

	DC_DocumentChannelProperty(panelTitle, RA_ACQ_CYCLE_ID_KEY, INDEP_HEADSTAGE, NaN, NaN, var=raCycleID)

	// get maximum ITI from all DACs
	for(i = 0; i < s.numDACEntries; i += 1)
		maxITI = max(maxITI, WB_GetITI(s.stimSet[i], s.setColumn[i]))
	endfor

	NVAR maxITIGlobal = $GetMaxIntertrialInterval(panelTitle)
	ASSERT(IsFinite(maxITI), "Invalid maxITI")
	maxITIGlobal = maxITI
	DC_DocumentChannelProperty(panelTitle, "Inter-trial interval", INDEP_HEADSTAGE, NaN, NaN, var=maxITIGlobal)

	WAVE/T epochWave = GetEpochsWave(panelTitle)
	EP_SortEpochs(panelTitle)

	// index guide:
	// - numEntries: Number of active DACs
	// - i: Zero-based index of the active DACS
	// - channel: DA channel number

	for(i = 0; i < s.numDACEntries; i += 1)
		channel = s.DACList[i]
		headstage = s.headstageDAC[i]

		if(s.dataAcqOrTP == DATA_ACQUISITION_MODE)
			DC_DocumentChannelProperty(panelTitle, "Indexing End Stimset", headstage, channel, XOP_CHANNEL_TYPE_DAC, str = allIndexingEndSetNames[channel])
		endif

		for(j = 0; j < TOTAL_NUM_EVENTS; j += 1)
			if(IsFinite(headstage)) // associated channel
				func = analysisFunctions[headstage][j]
			else
				func = ""
			endif

			DC_DocumentChannelProperty(panelTitle, StringFromList(j, EVENT_NAME_LIST_LBN), headstage, channel, XOP_CHANNEL_TYPE_DAC, str=func)
		endfor

		DC_DocumentChannelProperty(panelTitle, "DAC", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=channel)
		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
		DC_DocumentChannelProperty(panelTitle, "DA GAIN", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=DAG_GetNumericalValue(panelTitle, ctrl, index = channel))
		DC_DocumentChannelProperty(panelTitle, "DA ChannelType", headstage, channel, XOP_CHANNEL_TYPE_DAC, var = config[i][%DAQChannelType])

		DC_DocumentChannelProperty(panelTitle, STIM_WAVE_NAME_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, str=s.setName[i])
		DC_DocumentChannelProperty(panelTitle, STIMSET_WAVE_NOTE_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, str=NormalizeToEOL(RemoveEnding(note(s.stimSet[i]), "\r"), "\n"))

		if(IsFinite(headstage)) // associated channel
			str = analysisFunctions[headstage][ANALYSIS_FUNCTION_PARAMS]
		else
			str = ""
		endif

		DC_DocumentChannelProperty(panelTitle, ANALYSIS_FUNCTION_PARAMS_LBN, headstage, channel, XOP_CHANNEL_TYPE_DAC, str=str)

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
		DC_DocumentChannelProperty(panelTitle, "DA Unit", headstage, channel, XOP_CHANNEL_TYPE_DAC, str=DAG_GetTextualValue(panelTitle, ctrl, index = channel))

		DC_DocumentChannelProperty(panelTitle, STIMSET_SCALE_FACTOR_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, var = s.dataAcqOrTP == DATA_ACQUISITION_MODE && config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ ? s.DACAmp[i][%DASCALE] : s.DACAmp[i][%TPAMP])
		DC_DocumentChannelProperty(panelTitle, "Set Sweep Count", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=s.setColumn[i])
		DC_DocumentChannelProperty(panelTitle, "Electrode", headstage, channel, XOP_CHANNEL_TYPE_DAC, str=cellElectrodeNames[headstage])
		DC_DocumentChannelProperty(panelTitle, "Set Cycle Count", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=s.setCycleCount[i])

		setChecksum = WB_GetStimsetChecksum(s.stimSet[i], s.setName[i], s.dataAcqOrTP)
		DC_DocumentChannelProperty(panelTitle, "Stim Wave Checksum", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=setChecksum)

		if(s.dataAcqOrTP == DATA_ACQUISITION_MODE && config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ)
			fingerprint = DC_GenerateStimsetFingerprint(raCycleID, s.setName[i], s.setCycleCount[i], setChecksum, s.dataAcqOrTP)
			stimsetCycleID = DC_GetStimsetAcqCycleID(panelTitle, fingerprint, channel)

			DC_DocumentChannelProperty(panelTitle, STIMSET_ACQ_CYCLE_ID_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, var=stimsetCycleID)
		endif

		if(s.dataAcqOrTP == DATA_ACQUISITION_MODE)
			isoodDAQMember = (s.distributedDAQOptOv && config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ && IsFinite(headstage))
			DC_DocumentChannelProperty(panelTitle, "oodDAQ member", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=isoodDAQMember)
		endif

		DC_DocumentChannelProperty(panelTitle, "Stim set length", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=s.setLength[i])
		DC_DocumentChannelProperty(panelTitle, "Delay onset oodDAQ", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=s.offsets[i])
		DC_DocumentChannelProperty(panelTitle, "oodDAQ regions", headstage, channel, XOP_CHANNEL_TYPE_DAC, str=s.regions[i])

		Duplicate/FREE/RMD=[][][channel] epochWave, epochChannel
		Redimension/N=(-1, -1, 0) epochChannel
		DC_DocumentChannelProperty(panelTitle, EPOCHS_ENTRY_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, str=TextWaveToList(epochChannel, ":", colSep = ",", stopOnEmpty = 1))
	endfor

	DC_DocumentChannelProperty(panelTitle, "Sampling interval multiplier", INDEP_HEADSTAGE, NaN, NaN, var=str2num(DAG_GetTextualValue(panelTitle, "Popup_Settings_SampIntMult")))
	DC_DocumentChannelProperty(panelTitle, "Fixed frequency acquisition", INDEP_HEADSTAGE, NaN, NaN, var=str2numSafe(DAG_GetTextualValue(panelTitle, "Popup_Settings_FixedFreq")))
	DC_DocumentChannelProperty(panelTitle, "Sampling interval", INDEP_HEADSTAGE, NaN, NaN, var=s.samplingInterval * 1e-3)

	DC_DocumentChannelProperty(panelTitle, "Delay onset user", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_OnsetDelayUser"))
	DC_DocumentChannelProperty(panelTitle, "Delay onset auto", INDEP_HEADSTAGE, NaN, NaN, var=GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_OnsetDelayAuto"))
	DC_DocumentChannelProperty(panelTitle, "Delay termination", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_TerminationDelay"))
	DC_DocumentChannelProperty(panelTitle, "Delay distributed DAQ", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_dDAQDelay"))
	DC_DocumentChannelProperty(panelTitle, "oodDAQ Pre Feature", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "Setvar_DataAcq_dDAQOptOvPre"))
	DC_DocumentChannelProperty(panelTitle, "oodDAQ Post Feature", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "Setvar_DataAcq_dDAQOptOvPost"))
	DC_DocumentChannelProperty(panelTitle, "oodDAQ Resolution", INDEP_HEADSTAGE, NaN, NaN, var=WAVEBUILDER_MIN_SAMPINT)

	DC_DocumentChannelProperty(panelTitle, "TP Insert Checkbox", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "Check_Settings_InsertTP"))
	DC_DocumentChannelProperty(panelTitle, "Distributed DAQ", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_DistribDaq"))
	DC_DocumentChannelProperty(panelTitle, "Optimized Overlap dDAQ", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_dDAQOptOv"))
	DC_DocumentChannelProperty(panelTitle, "Repeat Sets", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "SetVar_DataAcq_SetRepeats"))
	DC_DocumentChannelProperty(panelTitle, "Scaling zero", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle,  "check_Settings_ScalingZero"))
	DC_DocumentChannelProperty(panelTitle, "Indexing", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "Check_DataAcq_Indexing"))
	DC_DocumentChannelProperty(panelTitle, "Locked indexing", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_IndexingLocked"))
	DC_DocumentChannelProperty(panelTitle, "Repeated Acquisition", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_RepeatAcq"))
	DC_DocumentChannelProperty(panelTitle, "Random Repeated Acquisition", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "check_DataAcq_RepAcqRandom"))
	DC_DocumentChannelProperty(panelTitle, "Multi Device mode", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "check_Settings_MD"))
	DC_DocumentChannelProperty(panelTitle, "Background Testpulse", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "Check_Settings_BkgTP"))
	DC_DocumentChannelProperty(panelTitle, "Background DAQ", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "Check_Settings_BackgrndDataAcq"))
	DC_DocumentChannelProperty(panelTitle, "TP buffer size", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "setvar_Settings_TPBuffer"))
	DC_DocumentChannelProperty(panelTitle, "TP during ITI", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "check_Settings_ITITP"))
	DC_DocumentChannelProperty(panelTitle, "Amplifier change via I=0", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "check_Settings_AmpIEQZstep"))
	DC_DocumentChannelProperty(panelTitle, "Skip analysis functions", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "Check_Settings_SkipAnalysFuncs"))
	DC_DocumentChannelProperty(panelTitle, "Repeat sweep on async alarm", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "Check_Settings_AlarmAutoRepeat"))
	DC_DocumentChannelProperty(panelTitle, "Autobias %", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "setvar_Settings_AutoBiasPerc"))
	DC_DocumentChannelProperty(panelTitle, "Autobias interval", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "setvar_Settings_AutoBiasInt"))

	DC_DocumentHardwareProperties(panelTitle, s.hardwareType)

	if(DeviceCanLead(panelTitle))
		SVAR listOfFollowerDevices = $GetFollowerList(panelTitle)
		DC_DocumentChannelProperty(panelTitle, "Follower Device", INDEP_HEADSTAGE, NaN, NaN, str=listOfFollowerDevices)
	endif

	DC_DocumentChannelProperty(panelTitle, "MIES version", INDEP_HEADSTAGE, NaN, NaN, str=GetMIESVersionAsString())
	DC_DocumentChannelProperty(panelTitle, "Igor Pro version", INDEP_HEADSTAGE, NaN, NaN, str=GetIgorProVersion())
	DC_DocumentChannelProperty(panelTitle, "Igor Pro build", INDEP_HEADSTAGE, NaN, NaN, str=GetIgorProBuildVersion())
	DC_DocumentChannelProperty(panelTitle, "Igor Pro bitness", INDEP_HEADSTAGE, NaN, NaN, var=GetArchitectureBits())
	DC_DocumentChannelProperty(panelTitle, "JSON config file: path", INDEP_HEADSTAGE, NaN, NaN, str=GetUserData(panelTitle, "", EXPCONFIG_UDATA_SOURCEFILE_PATH))
	DC_DocumentChannelProperty(panelTitle, "JSON config file: SHA-256 hash", INDEP_HEADSTAGE, NaN, NaN, str=GetUserData(panelTitle, "", EXPCONFIG_UDATA_SOURCEFILE_HASH))
	DC_DocumentChannelProperty(panelTitle, "JSON config file: stimset nwb file path", INDEP_HEADSTAGE, NaN, NaN, str=GetUserData(panelTitle, "", EXPCONFIG_UDATA_STIMSET_NWB_PATH))
	DC_DocumentChannelProperty(panelTitle, "TP after DAQ", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "check_Settings_TPAfterDAQ"))

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		DC_DocumentChannelProperty(panelTitle, "Headstage Active", i, NaN, NaN, var=s.statusHS[i])

		if(!s.statusHS[i])
			continue
		endif

		DC_DocumentChannelProperty(panelTitle, "Clamp Mode", i, NaN, NaN, var=DAG_GetHeadstageMode(panelTitle, i))
	endfor

	if(s.distributedDAQ)
		// dDAQ requires that all stimsets have the same length, so store the stim set length
		// also headstage independent
		ASSERT(!s.distributedDAQOptOv, "Unexpected oodDAQ mode")
		ASSERT(IsConstant(s.setLength, s.setLength[0]), "Unexpected varying stim set length")
		DC_DocumentChannelProperty(panelTitle, "Stim set length", INDEP_HEADSTAGE, NaN, NaN, var=s.setLength[0])
	endif

	for(i = 0; i < s.numADCEntries; i += 1)
		channel = s.ADCList[i]
		headstage = s.headstageADC[i]

		DC_DocumentChannelProperty(panelTitle, "ADC", headstage, channel, XOP_CHANNEL_TYPE_ADC, var=channel)

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
		DC_DocumentChannelProperty(panelTitle, "AD Gain", headstage, channel, XOP_CHANNEL_TYPE_ADC, var=DAG_GetNumericalValue(panelTitle, ctrl, index = channel))

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
		DC_DocumentChannelProperty(panelTitle, "AD Unit", headstage, channel, XOP_CHANNEL_TYPE_ADC, str=DAG_GetTextualValue(panelTitle, ctrl, index = channel))

		DC_DocumentChannelProperty(panelTitle, "AD ChannelType", headstage, channel, XOP_CHANNEL_TYPE_ADC, var = config[s.numDACEntries + i][%DAQChannelType])
	endfor
End

static Function DC_FillSetEventFlag(string panelTitle, STRUCT DC_FillSetEventFlagParams &s)
	variable i, channel

	WAVE config = GetDAQConfigWave(panelTitle)

	WAVE setEventFlag = GetSetEventFlag(panelTitle)
	setEventFlag = 0

	for(i = 0; i < s.numDACEntries; i += 1)
		channel = s.DACList[i]

		if(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ)
			setEventFlag[channel][] = (s.setColumn[i] + 1 == IDX_NumberOfSweepsInSet(s.setName[i]))
		endif
	endfor
End

static Function DC_FillDAQDataWaveForTP(string panelTitle, STRUCT DC_FillDAQDataWaveForTPParams &s)
	variable testPulseLength, cutOff, i, tpAmp
	string key

	WAVE testPulse = GetTestPulse()
	testPulseLength = DimSize(testPulse, ROWS)

	// varies per DAC:
	// DAGain, DAScale, insertStart (with dDAQ), setLength, testPulseAmplitude (can be non-constant due to different VC/IC)
	// setName, setColumn, headstageDAC
	//
	// constant:
	// decimationFactor, testPulseLength, baselineFrac
	//
	// we only have to fill in the DA channels
	ASSERT(sum(s.insertStart) == 0, "Unexpected insert start value")
	ASSERT(sum(s.setColumn) == 0, "Unexpected setColumn value")
	ASSERT(DimSize(testPulse, COLS) <= 1, "Expected a 1D testpulse wave")
	ASSERT(s.numADCEntries > 0, "Number of ADCs can not be zero")
	ASSERT(s.numDACEntries > 0, "Number of DACs can not be zero")

	struct HardwareDataTPInput cacheParams
	cacheParams.hardwareType = s.hardwareType
	cacheParams.numDACs = s.numDACEntries
	cacheParams.numActiveChannels = s.numActiveChannels
	cacheParams.numberOfRows = DC_CalculateDAQDataWaveLength(panelTitle, TEST_PULSE_MODE)
	cacheParams.samplingInterval = s.samplingInterval
	WAVE cacheParams.DAGain = s.DAGain
	Duplicate/FREE/RMD=[][FindDimLabel(s.DACAmp, COLS, "TPAMP")] s.DACAmp, DACAmpTP
	WAVE cacheParams.DACAmpTP = DACAmpTP
	cacheParams.testPulseLength = testPulseLength
	cacheParams.baseLineFrac = s.baselineFrac

	key = CA_HardwareDataTPKey(cacheParams)

	WAVE/Z result = CA_TryFetchingEntryFromCache(key)

	if(WaveExists(result))
		WAVE DAQDataWave = GetDAQDataWave(panelTitle, TEST_PULSE_MODE)

		if(!cmpstr(GetStringFromWaveNote(DAQDataWave, TP_PROPERTIES_HASH), key))
			// clear the AD data only
			switch(s.hardwareType)
				case HARDWARE_ITC_DAC:
					WAVE/W ITCDataWave = DAQDataWave
					Multithread ITCDataWave[][s.numDACEntries, s.numDACEntries + s.numADCEntries - 1] = 0
					break
				case HARDWARE_NI_DAC:
					WAVE/WAVE NIDataWave = DAQDataWave
					for(i = 0; i < s.numADCEntries; i += 1)
						WAVE NIChannel = NIDataWave[s.numDACEntries + i]
						FastOp NIChannel = 0
					endfor
					break
			endswitch
		else
			if(IsWaveRefWave(DAQDataWave))
				WAVE/WAVE DAQDataWaveRef = DAQDataWave
				Redimension/N=(s.numActiveChannels) DAQDataWaveRef
				DAQDataWaveRef[] = GetNIDAQChannelWave(panelTitle, p)
			endif
			SetStringInWaveNote(result, TP_PROPERTIES_HASH, key)
			MoveWaveWithOverwrite(DAQDataWave, result, recursive = 1)
		endif
	else
		WAVE/Z ITCDataWave
		WAVE/WAVE/Z NIDataWave

		[ITCDataWave, NIDataWave] = DC_MakeAndGetDAQDataWave(panelTitle, s.hardwareType, s.numActiveChannels, \
															 s.samplingInterval, TEST_PULSE_MODE)

		switch(s.hardwareType)
			case HARDWARE_ITC_DAC:
				if(s.multiDevice)
					Multithread ITCDataWave[][0, s.numDACEntries - 1] =                             \
					limit(                                                                          \
						  (s.DAGain[q] * s.DACAmp[q][%TPAMP]) * testPulse[mod(p, testPulseLength)], \
						  SIGNED_INT_16BIT_MIN,                                                     \
						  SIGNED_INT_16BIT_MAX); AbortOnRTE
					cutOff = mod(DimSize(ITCDataWave, ROWS), testPulseLength)
					if(cutOff > 0)
						ITCDataWave[DimSize(ITCDataWave, ROWS) - cutoff, *][0, s.numDACEntries - 1] = 0
					endif
				else
					Multithread ITCDataWave[0, testPulseLength - 1][0, s.numDACEntries - 1] = \
					limit(                                                                    \
						  s.DAGain[q] * s.DACAmp[q][%TPAMP] * testPulse[p],                   \
						  SIGNED_INT_16BIT_MIN,                                               \
						  SIGNED_INT_16BIT_MAX); AbortOnRTE
				endif

				SetStringInWaveNote(ITCDataWave, TP_PROPERTIES_HASH, key)
				CA_StoreEntryIntoCache(key, ITCDataWave)
				break
			case HARDWARE_NI_DAC:
				for(i = 0;i < s.numDACEntries; i += 1)
					WAVE NIChannel = NIDataWave[i]
					tpAmp = s.DACAmp[i][%TPAMP] * s.DAGain[i]
					Multithread NIChannel[0, testPulseLength - 1] = \
					limit(                                          \
						  tpAmp * testPulse[p],                     \
						  NI_DAC_MIN,                               \
						  NI_DAC_MAX); AbortOnRTE
				endfor

				SetStringInWaveNote(NIDataWave, TP_PROPERTIES_HASH, key)
				CA_StoreEntryIntoCache(key, NIDataWave)
				break
		endswitch
	endif
End

static Function DC_FillDAQDataWaveForDAQ(string panelTitle, STRUCT DC_FillDAQDataWaveForDAQParams &s)
	variable i, tpAmp, cutOff, channel, headstage, DAScale, singleSetLength, stimsetCol, startOffset, testPulseLength
	variable lastValidRow

	WAVE testPulse = GetTestPulse()
	testPulseLength = DimSize(testPulse, ROWS)

	WAVE/Z ITCDataWave
	WAVE/WAVE/Z NIDataWave

	WAVE config = GetDAQConfigWave(panelTitle)

	[ITCDataWave, NIDataWave] = DC_MakeAndGetDAQDataWave(panelTitle, s.hardwareType, s.numActiveChannels, \
														 s.samplingInterval, DATA_ACQUISITION_MODE)

	for(i = 0; i < s.numDACEntries; i += 1)
		if(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_TP)
			// TP wave does not need to be decimated, it has already correct size reg. sample rate
			tpAmp = s.DACAmp[i][%TPAMP] * s.DAGain[i]
			ASSERT(DimSize(testPulse, COLS) <= 1, "Expected a 1D testpulse wave")
			switch(s.hardwareType)
				case HARDWARE_ITC_DAC:
					Multithread ITCDataWave[][i] =                    \
					limit(                                            \
						  tpAmp * testPulse[mod(p, testPulseLength)], \
						  SIGNED_INT_16BIT_MIN,                       \
						  SIGNED_INT_16BIT_MAX); AbortOnRTE
					cutOff = mod(DimSize(ITCDataWave, ROWS), testPulseLength)
					if(cutOff > 0)
						ITCDataWave[DimSize(ITCDataWave, ROWS) - cutOff, *][i] = 0
					endif
					break
				case HARDWARE_NI_DAC:
					WAVE NIChannel = NIDataWave[i]
					Multithread NIChannel[] =                         \
					limit(                                            \
						  tpAmp * testPulse[mod(p, testPulseLength)], \
						  NI_DAC_MIN,                                 \
						  NI_DAC_MAX); AbortOnRTE
					cutOff = mod(DimSize(NIChannel, ROWS), testPulseLength)
					if(cutOff > 0)
						NIChannel[DimSize(NIChannel, ROWS) - cutOff, *] = 0
					endif
					break
			endswitch
		elseif(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ)
			channel = s.DACList[i]
			headstage = s.headstageDAC[i]
			tpAmp = s.DACAmp[i][%TPAMP] * s.DAGain[i]
			DAScale = s.DACAmp[i][%DASCALE] * s.DAGain[i]
			WAVE singleStimSet = s.stimSet[i]
			singleSetLength = s.setLength[i]
			stimsetCol = s.setColumn[i]
			startOffset = s.insertStart[i]

			switch(s.hardwareType)
				case HARDWARE_ITC_DAC:
					Multithread ITCDataWave[startOffset, startOffset + singleSetLength - 1][i] =       \
					limit(                                                                             \
						  DAScale * singleStimSet[s.decimationFactor * (p - startOffset)][stimsetCol], \
						  SIGNED_INT_16BIT_MIN,                                                        \
						  SIGNED_INT_16BIT_MAX); AbortOnRTE

					if(s.globalTPInsert)
						// space in ITCDataWave for the testpulse is allocated via an automatic increase
						// of the onset delay
						MultiThread ITCDataWave[0, testPulseLength - 1][i] =                        \
						limit(tpAmp * testPulse[p], SIGNED_INT_16BIT_MIN, SIGNED_INT_16BIT_MAX); AbortOnRTE
					endif
					break
				case HARDWARE_NI_DAC:
					// for an index step of 1 in NIChannel, singleStimSet steps decimationFactor
					// for an index step of 1 in singleStimset, NIChannel steps 1 / decimationFactor
					// for decimationFactor < 1 and indexing NIChannel to DimSize(NIChannel, ROWS) - 1 (as implemented here),
					// singleStimset would be indexed to DimSize(singleStimSet, ROWS) - decimationFactor
					// this leads to an invalid index if decimationFactor is <= 0.5 (due to the way Igor handles nD wave indexing)
					// it is solved here by limiting the index of singleStimSet to the last valid integer index
					// for the case of decimationFactor >= 1 there is no issue since index DimSize(singleStimSet, ROWS) - decimationFactor is valid
					// for ITC decimationFactor is always >= 1 since the stimSets are generated for the ITC max. sample rate
					WAVE NIChannel = NIDataWave[i]
					lastValidRow = DimSize(singleStimSet, ROWS) - 1
					MultiThread NIChannel[startOffset, startOffset + singleSetLength - 1] =                                    \
					limit(                                                                                                     \
						  DAScale * singleStimSet[limit(s.decimationFactor * (p - startOffset), 0, lastValidRow)][stimsetCol], \
						  NI_DAC_MIN,                                                                                          \
						  NI_DAC_MAX); AbortOnRTE

					if(s.globalTPInsert)
						// space in ITCDataWave for the testpulse is allocated via an automatic increase
						// of the onset delay
						MultiThread NIChannel[0, testPulseLength - 1] = \
						limit(tpAmp * testPulse[p], NI_DAC_MIN, NI_DAC_MAX); AbortOnRTE
					endif
					break
			endswitch
		else
			ASSERT(0, "Unknown DAC channel type")
		endif
	endfor
End

static Function [STRUCT DC_FillConfiguratorStruct s] DC_FillConfigurator(string panelTitle, variable numActiveChannels, variable dataAcqOrTP, variable multiDevice)
	variable TPAmpVClamp, TPAmpIClamp, powerSpectrum, channel, headstage, channelMode
	variable onsetDelayUserLocal, onsetDelayAutoLocal, terminationDelayLocal, distributedDAQDelayLocal
	variable scalingZero, indexingLocked, indexing
	variable i, j, ret, setCycleCountLocal
	string ctrl

	// pass parameters into returned struct
	s.numActiveChannels = numActiveChannels
	s.dataAcqOrTP       = dataAcqOrTP
	s.multiDevice       = multiDevice

	s.globalTPInsert        = DAG_GetNumericalValue(panelTitle, "Check_Settings_InsertTP")
	scalingZero             = DAG_GetNumericalValue(panelTitle,  "check_Settings_ScalingZero")
	indexingLocked          = DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_IndexingLocked")
	indexing                = DAG_GetNumericalValue(panelTitle, "Check_DataAcq_Indexing")
	s.distributedDAQ        = DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_DistribDaq")
	s.distributedDAQOptOv   = DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_dDAQOptOv")
	s.distributedDAQOptPre  = DAG_GetNumericalValue(panelTitle, "Setvar_DataAcq_dDAQOptOvPre")
	s.distributedDAQOptPost = DAG_GetNumericalValue(panelTitle, "Setvar_DataAcq_dDAQOptOvPost")
	TPAmpVClamp             = DAG_GetNumericalValue(panelTitle, "SetVar_DataAcq_TPAmplitude")
	TPAmpIClamp             = DAG_GetNumericalValue(panelTitle, "SetVar_DataAcq_TPAmplitudeIC")
	powerSpectrum           = DAG_GetNumericalValue(panelTitle, "check_settings_show_power")

	// MH: note with NI the decimationFactor can now be < 1, like 0.4 if a single NI ADC channel runs with 500 kHz
	// whereas the source data generated waves for ITC min sample rate are at 200 kHz
	s.decimationFactor = DC_GetDecimationFactor(panelTitle, dataAcqOrTP)
	s.samplingInterval = DAP_GetSampInt(panelTitle, dataAcqOrTP)
	WAVE/T allSetNames = DAG_GetChannelTextual(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	s.hardwareType     = GetHardwareType(panelTitle)

	s.baselineFrac        = ROVar(GetTestpulseBaselineFraction(panelTitle))
	WAVE ChannelClampMode = GetChannelClampMode(panelTitle)
	WAVE s.statusHS       = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	WAVE s.DAGain  = SWS_GetChannelGains(panelTitle, timing = GAIN_BEFORE_DAQ)
	WAVE config  = GetDAQConfigWave(panelTitle)
	WAVE s.DACList = GetDACListFromConfig(config)
	WAVE s.ADCList = GetADCListFromConfig(config)

	s.numDACEntries = DimSize(s.DACList, ROWS)
	Make/D/FREE/N=(s.numDACEntries) s.insertStart, s.setLength, s.setColumn, s.headstageDAC, s.setCycleCount

	Make/D/FREE/N=(s.numDACEntries, 2) s.DACAmp
	SetDimLabel COLS, 0, DASCALE, s.DACAmp
	SetDimLabel COLS, 1, TPAMP, s.DACAmp

	Make/T/FREE/N=(s.numDACEntries) s.setName
	// @todo IP9-only: Remove workaround once this is fixed upstream
	Make/WAVE/FREE/N=(s.numDACEntries) stimSetLocal
	WAVE/WAVE s.stimSet = stimSetLocal

	s.numADCEntries = DimSize(s.ADCList, ROWS)
	Make/D/FREE/N=(s.numADCEntries) s.headstageADC

	WAVE s.testPulse = GetTestPulse()

	// test pulse length is calculated for dataAcqOrTP
	s.testPulseLength = DimSize(s.testPulse, ROWS)

	s.headstageDAC[] = channelClampMode[s.DACList[p]][%DAC][%Headstage]
	s.headstageADC[] = channelClampMode[s.ADCList[p]][%ADC][%Headstage]

	// index guide:
	// - numEntries: Number of active DACs
	// - i: Zero-based index of the active DACS
	// - channel: DA channel number

	for(i = 0; i < s.numDACEntries; i += 1)
		channel = s.DACList[i]
		headstage = s.headstageDAC[i]

		// Setup stimset name for logging and stimset, for tp mode and tp channels stimset references the tp wave
		if(s.dataAcqOrTP == DATA_ACQUISITION_MODE)
			s.setName[i] = allSetNames[channel]
			if(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ)
				s.stimSet[i] = WB_CreateAndGetStimSet(s.setName[i])
			elseif(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_TP)
				s.stimSet[i] = GetTestPulse()
			else
				ASSERT(0, "Unknown DAQ Channel Type")
			endif
		elseif(dataAcqOrTP == TEST_PULSE_MODE)
			s.setName[i] = LowerStr(STIMSET_TP_WHILE_DAQ)
			s.stimSet[i] = GetTestPulse()
		else
			ASSERT(0, "unknown mode")
		endif

		// restarting DAQ via the stimset popup menues does not call DAP_CheckSettings()
		// so the stimest must not exist here or it could be empty
		if(!WaveExists(s.stimSet[i]) || DimSize(s.stimSet[i], ROWS) == 0)
			Abort
		endif

		if(dataAcqOrTP == TEST_PULSE_MODE)
			s.setColumn[i] = 0
		elseif(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_TP)
			// DATA_ACQUISITION_MODE cases
			s.setColumn[i] = 0
		elseif(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ)
			// only call DC_CalculateChannelColumnNo for real data acquisition
			[ret, setCycleCountLocal] = DC_CalculateChannelColumnNo(panelTitle, s.setName[i], channel, CHANNEL_TYPE_DAC)
			s.setColumn[i]     = ret
			s.setCycleCount[i] = setCycleCountLocal
		endif

		if(IsFinite(headstage))
			channelMode = ChannelClampMode[channel][%DAC][%ClampMode]
			if(channelMode == V_CLAMP_MODE)
				s.DACAmp[i][%TPAMP] = TPAmpVClamp
			elseif(channelMode == I_CLAMP_MODE || channelMode == I_EQUAL_ZERO_MODE)
				s.DACAmp[i][%TPAMP] = TPAmpIClamp
			else
				ASSERT(0, "Unknown clamp mode")
			endif
		else // unassoc channel
			channelMode = NaN
			s.DACAmp[i][%TPAMP] = 0.0
		endif

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
		s.DACAmp[i][%DASCALE] = DAG_GetNumericalValue(panelTitle, ctrl, index = channel)

		// DA Scale and TP Amplitude tuning for special cases
		if(s.dataAcqOrTP == DATA_ACQUISITION_MODE)
			if(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ)
				// checks if user wants to set scaling to 0 on sets that have already cycled once
				if(scalingZero && (indexingLocked || !indexing) && s.setCycleCount[i] > 0)
					s.DACAmp[i][%DASCALE] = 0
				endif

				if(channelMode == I_EQUAL_ZERO_MODE)
					s.DACAmp[i][%DASCALE] = 0
					s.DACAmp[i][%TPAMP] = 0
				endif
			elseif(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_TP)
				// do nothing
			endif
		elseif(dataAcqOrTP == TEST_PULSE_MODE)
			if(powerSpectrum)
				s.DACAmp[i][%TPAMP] = 0
			endif
		else
			ASSERT(0, "unknown mode")
		endif
	endfor

	// for distributedDAQOptOv create temporary reduced input waves holding DAQ types channels only (removing TP typed channels from TPwhileDAQ), put results back to unreduced waves
	if(s.distributedDAQOptOv && s.dataAcqOrTP == DATA_ACQUISITION_MODE)
		Duplicate/FREE/WAVE s.stimSet, reducedStimSet
		Duplicate/FREE s.setColumn, reducedSetColumn, iTemp

		j = 0
		for(i = 0; i < s.numDACEntries; i += 1)
			if(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ)
				reducedStimSet[j] = s.stimSet[i]
				reducedSetColumn[j] = s.setColumn[i]
				iTemp[j] = i
				j += 1
			endif
		endfor
		Redimension/N=(j) reducedStimSet, reducedSetColumn

		STRUCT OOdDAQParams params
		InitOOdDAQParams(params, reducedStimSet, reducedSetColumn, s.distributedDAQOptPre, s.distributedDAQOptPost)
		WAVE/WAVE reducedStimSet = OOD_GetResultWaves(panelTitle, params)
		WAVE reducedOffsets = params.offsets
		WAVE/T reducedRegions = params.regions

		Make/FREE/N=(s.numDACEntries) s.offsets = 0
		Make/FREE/T/N=(s.numDACEntries) s.regions

		j = DimSize(reducedStimSet, ROWS)
		for(i = 0; i < j; i += 1)
			s.stimSet[iTemp[i]] = reducedStimSet[i]
			s.setColumn[iTemp[i]] = reducedSetColumn[i]
			s.offsets[iTemp[i]] = reducedOffsets[i]
			s.regions[iTemp[i]] = reducedRegions[i]
		endfor
	endif

	if(!WaveExists(s.offsets))
		Make/FREE/N=(s.numDACEntries) s.offsets = 0
	else
		s.offsets[] *= WAVEBUILDER_MIN_SAMPINT
	endif

	if(!WaveExists(s.regions))
		Make/FREE/T/N=(s.numDACEntries) s.regions
	endif

	// when DC_CalculateStimsetLength is called with dataAcqOrTP = DATA_ACQUISITION_MODE decimationFactor is considered
	if(dataAcqOrTP == TEST_PULSE_MODE)
		s.setLength[] = DC_CalculateStimsetLength(s.stimSet[p], panelTitle, TEST_PULSE_MODE)
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)
		Duplicate/FREE s.setLength, setMode
		setMode[] = config[p][%DAQChannelType] == DAQ_CHANNEL_TYPE_TP ? TEST_PULSE_MODE : DATA_ACQUISITION_MODE
		s.setLength[] = DC_CalculateStimsetLength(s.stimSet[p], panelTitle, setMode[p])
	endif

	if(dataAcqOrTP == TEST_PULSE_MODE)
		s.insertStart[] = 0
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)
		DC_ReturnTotalLengthIncrease(panelTitle, onsetdelayUser=onsetDelayUserLocal, onsetDelayAuto=onsetDelayAutoLocal, terminationDelay=terminationDelayLocal, distributedDAQDelay=distributedDAQDelayLocal)

		s.onsetDelayUser      = onsetDelayUserLocal
		s.onsetDelayAuto      = onsetDelayAutoLocal
		s.terminationDelay    = terminationDelayLocal
		s.distributedDAQDelay = distributedDAQDelayLocal

		s.onsetDelay = s.onsetDelayUser + s.onsetDelayAuto
		if(s.distributedDAQ)
			s.insertStart[] = s.onsetDelay + (sum(s.statusHS, 0, s.headstageDAC[p]) - 1) * (s.distributedDAQDelay + s.setLength[p])
		else
			s.insertStart[] = s.onsetDelay
		endif
	endif
End

/// @brief Document hardware type/name/serial number into the labnotebook
static Function DC_DocumentHardwareProperties(panelTitle, hardwareType)
	string panelTitle
	variable hardwareType

	string str, key

	DC_DocumentChannelProperty(panelTitle, "Digitizer Hardware Type", INDEP_HEADSTAGE, NaN, NaN, var=hardwareType)

	NVAR deviceID = $GetDAQDeviceID(panelTitle)

	key = CA_HWDeviceInfoKey(panelTitle, hardwareType, deviceID)
	WAVE/Z devInfo = CA_TryFetchingEntryFromCache(key)

	if(!WaveExists(devInfo))
		WAVE devInfo = HW_GetDeviceInfo(hardwareType, deviceID, flags=HARDWARE_ABORT_ON_ERROR | HARDWARE_PREVENT_ERROR_POPUP)
		CA_StoreEntryIntoCache(key, devInfo)
	endif

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			DC_DocumentChannelProperty(panelTitle, "Digitizer Hardware Name", INDEP_HEADSTAGE, NaN, NaN, str=StringFromList(devInfo[%DeviceType], DEVICE_TYPES_ITC))
			sprintf str, "Master:%#0X,Secondary:%#0X,Host:%#0X", devInfo[%MasterSerialNumber], devInfo[%SecondarySerialNumber], devInfo[%HostSerialNumber]
			DC_DocumentChannelProperty(panelTitle, "Digitizer Serial Numbers", INDEP_HEADSTAGE, NaN, NaN, str=str)
			break
		case HARDWARE_NI_DAC:
			WAVE/T devInfoText = devInfo
			sprintf str, "%s %s (%#0X)", devInfoText[%DeviceCategoryStr], devInfoText[%ProductType], str2num(devInfoText[%ProductNumber])
			DC_DocumentChannelProperty(panelTitle, "Digitizer Hardware Name", INDEP_HEADSTAGE, NaN, NaN, str=str)
			sprintf str, "%#0X", str2num(devInfoText[%DeviceSerialNumber])
			DC_DocumentChannelProperty(panelTitle, "Digitizer Serial Numbers", INDEP_HEADSTAGE, NaN, NaN, str=str)
			break
		default:
			ASSERT(0, "Unknown hardware")
	endswitch
End

/// @brief Return the stimset acquisition cycle ID
///
/// @param panelTitle  device
/// @param fingerprint fingerprint as returned by DC_GenerateStimsetFingerprint()
/// @param DAC         DA channel
static Function DC_GetStimsetAcqCycleID(panelTitle, fingerprint, DAC)
	string panelTitle
	variable fingerprint, DAC

	WAVE stimsetAcqIDHelper = GetStimsetAcqIDHelperWave(panelTitle)

	if(!IsFinite(fingerprint))
		return NaN
	endif

	if(fingerprint == stimsetAcqIDHelper[DAC][%fingerprint])
		return stimsetAcqIDHelper[DAC][%id]
	endif

	stimsetAcqIDHelper[DAC][%fingerprint] = fingerprint
	stimsetAcqIDHelper[DAC][%id] = GetNextRandomNumberForDevice(panelTitle)

	return stimsetAcqIDHelper[DAC][%id]
End

/// @brief Generate the stimset fingerprint
///
/// This fingerprint is unique for the combination of the following properties:
/// - Repeated acquisition cycle ID
/// - stimset name
/// - stimset checksum
/// - set cycle count
///
/// Always then this fingerprint changes, a new stimset acquisition cycle ID has
/// to be generated.
///
/// Returns NaN for the testpulse.
static Function DC_GenerateStimsetFingerprint(raCycleID, setName, setCycleCount, setChecksum, dataAcqOrTP)
	variable raCycleID
	string setName
	variable setChecksum, setCycleCount, dataAcqOrTP

	variable crc

	if(dataAcqOrTP == TEST_PULSE_MODE)
		return NaN
	endif

	ASSERT(IsInteger(raCycleID) && raCycleID > 0, "Invalid raCycleID")
	ASSERT(IsInteger(setCycleCount), "Invalid setCycleCount")
	ASSERT(IsInteger(setChecksum) && setChecksum > 0, "Invalid stimset checksum")
	ASSERT(!IsEmpty(setName) && !cmpstr(setName, trimstring(setName)) , "Invalid setName")

	crc = StringCRC(crc, num2str(raCycleID))
	crc = StringCRC(crc, num2str(setCycleCount))
	crc = StringCRC(crc, num2str(setChecksum))
	crc = StringCRC(crc, setName)

	return crc
End

static Function [variable result, variable row, variable column] DC_CheckIfDataWaveHasBorderVals(string panelTitle, variable dataAcqOrTP)

	variable hardwareType = GetHardwareType(panelTitle)
	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			WAVE/Z ITCDataWave = GetDAQDataWave(panelTitle, dataAcqOrTP)
			ASSERT(WaveExists(ITCDataWave), "Missing DAQDataWave")
			ASSERT(WaveType(ITCDataWave) == IGOR_TYPE_16BIT_INT, "Unexpected wave type: " + num2str(WaveType(ITCDataWave)))

			FindValue/UOFV/I=(SIGNED_INT_16BIT_MIN) ITCDataWave

			if(V_Value != -1)
				return [1, V_row, V_col]
			endif

			FindValue/UOFV/I=(SIGNED_INT_16BIT_MAX) ITCDataWave

			if(V_Value != -1)
				return [1, V_row, V_col]
			endif

			return [0, NaN, NaN]
			break
		case HARDWARE_NI_DAC:
			WAVE/WAVE NIDataWave = GetDAQDataWave(panelTitle, dataAcqOrTP)
			ASSERT(IsWaveRefWave(NIDataWave), "Unexpected wave type")
			variable channels = numpnts(NIDataWave)
			variable i
			for(i = 0; i < channels; i += 1)
				WAVE NIChannel = NIDataWave[i]

				FindValue/UOFV/V=(NI_DAC_MIN)/T=1E-6 NIChannel

				if(V_Value != -1)
					return [1, V_row, V_col]
				endif

				FindValue/UOFV/V=(NI_DAC_MAX)/T=1E-6 NIChannel

				if(V_Value != -1)
					return [1, V_row, V_col]
				endif

				return [0, NaN, NaN]
			endfor
			break
	endswitch
End

/// @brief Document channel properties of DA and AD channels
///
/// Knows about unassociated channels and creates the special key returned by
/// CreateLBNUnassocKey().
///
/// @param panelTitle     device
/// @param entry          name of the property
/// @param headstage      number of headstage, must be `NaN` for unassociated channels
/// @param channelNumber  number of the channel
/// @param channelType    type of the channel
/// @param var [optional] numeric value
/// @param str [optional] string value
static Function DC_DocumentChannelProperty(panelTitle, entry, headstage, channelNumber, channelType, [var, str])
	string panelTitle, entry
	variable headstage, channelNumber, channelType
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
	ua_entry = CreateLBNUnassocKey(entry, channelNumber, channelType)

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
			sweepDataLNB[][numCols][] = NaN
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

/// @brief Combines the TTL stimulus sweeps across different TTL channels into a single wave
///
/// @param panelTitle  panel title
/// @param rackNo      Front TTL rack aka number of ITC devices. Only the ITC1600
///                    has two racks, see @ref RackConstants. Rack number for all other devices is
///                    #RACK_ZERO.
static Function DC_ITC_MakeTTLWave(panelTitle, rackNo)
	string panelTitle
	variable rackNo

	variable first, last, i, col, maxRows, lastIdx, bit, bits, setCycleCount
	variable setLength, setChecksum

	string set
	string listOfSets = ""
	string setSweepCounts = ""
	string indexingEndStimset = ""
	string stimSetWaveNote = ""
	string stimSetchecksum = ""
	string stimSetLength = ""

	WAVE statusTTLFiltered = DC_GetFilteredChannelState(panelTitle, DATA_ACQUISITION_MODE, CHANNEL_TYPE_TTL)

	WAVE/T allSetNames = DAG_GetChannelTextual(panelTitle, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
	WAVE/T allSetNamesIndexingEnd = DAG_GetChannelTextual(panelTitle, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)

	WAVE sweepDataLNB      = GetSweepSettingsWave(panelTitle)
	WAVE/T sweepDataTxTLNB = GetSweepSettingsTextWave(panelTitle)

	HW_ITC_GetRackRange(rackNo, first, last)

	for(i = first; i <= last; i += 1)

		if(!statusTTLFiltered[i])
			listOfSets = AddListItem("", listOfSets, ";", inf)
			continue
		endif

		set = allSetNames[i]
		WAVE wv = WB_CreateAndGetStimSet(set)
		maxRows = max(maxRows, DimSize(wv, ROWS))
		bits += 2^(i - first)
		listOfSets = AddListItem(set, listOfSets, ";", inf)
	endfor

	ASSERT(maxRows > 0, "Expected stim set of non-zero size")
	WAVE TTLWave = GetTTLWave(panelTitle)
	Redimension/N=(maxRows) TTLWave
	FastOp TTLWave = 0

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusTTLFiltered[i])
			if(i >= first && i <= last)
				setSweepCounts = AddListItem("", setSweepCounts, ";", inf)
			endif

			indexingEndStimset = AddListItem("", indexingEndStimset, ";", inf)
			stimSetWaveNote = AddListItem("", stimSetWaveNote, ";", inf)
			stimSetChecksum = AddListItem("", stimSetChecksum, ";", inf)
			stimSetLength = AddListItem("", stimSetLength, ";", inf)
			continue
		endif

		set = allSetNames[i]
		WAVE TTLStimSet = WB_CreateAndGetStimSet(set)

		setLength = DimSize(TTLStimSet, ROWS)
		setChecksum = WB_GetStimsetChecksum(TTLStimSet, set, DATA_ACQUISITION_MODE)

		indexingEndStimset = AddListItem(allSetNamesIndexingEnd[i], indexingEndStimset, ";", inf)
		stimSetWaveNote = AddListItem(URLEncode(note(TTLStimSet)), stimSetWaveNote, ";", inf)
		stimSetChecksum = AddListItem(num2istr(setChecksum), stimSetChecksum, ";", inf)
		stimSetLength = AddListItem(num2istr(setLength), stimSetLength, ";", inf)

		if(i >= first && i <= last)
			// part of this rack
			[col, setCycleCount] = DC_CalculateChannelColumnNo(panelTitle, set, i, CHANNEL_TYPE_TTL)

			lastIdx = setLength - 1
			bit = 2^(i - first)
			MultiThread TTLWave[0, lastIdx] += bit * TTLStimSet[p][col]
			setSweepCounts = AddListItem(num2str(col), setSweepCounts, ";", inf)
		endif
	endfor

	if(rackNo == RACK_ZERO)
		sweepDataLNB[0][%$"TTL rack zero bits"][INDEP_HEADSTAGE]                = bits
		sweepDataTxTLNB[0][%$"TTL rack zero stim sets"][INDEP_HEADSTAGE]        = listOfSets
		sweepDataTxTLNB[0][%$"TTL rack zero set sweep counts"][INDEP_HEADSTAGE] = setSweepCounts
	else
		sweepDataLNB[0][%$"TTL rack one bits"][INDEP_HEADSTAGE]                = bits
		sweepDataTxTLNB[0][%$"TTL rack one stim sets"][INDEP_HEADSTAGE]        = listOfSets
		sweepDataTxTLNB[0][%$"TTL rack one set sweep counts"][INDEP_HEADSTAGE] = setSweepCounts
	endif

	sweepDataTxTLNB[0][%$"TTL Indexing End stimset"][INDEP_HEADSTAGE] = indexingEndStimset
	sweepDataTxTLNB[0][%$"TTL Stimset wave note"][INDEP_HEADSTAGE]    = stimSetWaveNote
	sweepDataTxTLNB[0][%$"TTL Stim Wave Checksum"][INDEP_HEADSTAGE]   = stimSetChecksum
	sweepDataTxTLNB[0][%$"TTL Stim set length"][INDEP_HEADSTAGE]      = stimSetLength
End

static Function DC_NI_MakeTTLWave(panelTitle)
	string panelTitle

	variable col, i, setCycleCount, setLength, setChecksum
	string set
	string listOfSets = ""
	string setSweepCounts = ""
	string channels = ""
	string indexingEndStimset = ""
	string stimSetWaveNote = ""
	string stimSetChecksum = ""
	string stimSetLength = ""

	WAVE statusTTLFiltered = DC_GetFilteredChannelState(panelTitle, DATA_ACQUISITION_MODE, CHANNEL_TYPE_TTL)
	WAVE/T allSetNames = DAG_GetChannelTextual(panelTitle, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
	WAVE/T allSetNamesIndexingEnd = DAG_GetChannelTextual(panelTitle, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
	WAVE/WAVE TTLWave = GetTTLWave(panelTitle)

	WAVE/T sweepDataTxTLNB = GetSweepSettingsTextWave(panelTitle)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusTTLFiltered[i])
			listOfSets = AddListItem("", listOfSets, ";", inf)
			setSweepCounts = AddListItem("", setSweepCounts, ";", inf)
			channels = AddListItem("", channels, ";", inf)
			indexingEndStimset = AddListItem("", indexingEndStimset, ";", inf)
			stimSetWaveNote = AddListItem("", stimSetWaveNote, ";", inf)
			stimSetChecksum = AddListItem("", stimSetChecksum, ";", inf)
			stimSetLength = AddListItem("", stimSetLength, ";", inf)
			continue
		endif

		set = allSetNames[i]
		WAVE TTLStimSet = WB_CreateAndGetStimSet(set)
		[col, setCycleCount] = DC_CalculateChannelColumnNo(panelTitle, set, i, CHANNEL_TYPE_TTL)

		setLength = DimSize(TTLStimSet, ROWS)
		setChecksum = WB_GetStimsetChecksum(TTLStimSet, set, DATA_ACQUISITION_MODE)

		listOfSets = AddListItem(set, listOfSets, ";", inf)
		setSweepCounts = AddListItem(num2str(col), setSweepCounts, ";", inf)
		channels = AddListItem(num2str(i), channels, ";", inf)
		indexingEndStimset = AddListItem(allSetNamesIndexingEnd[i], indexingEndStimset, ";", inf)
		stimSetWaveNote = AddListItem(URLEncode(note(TTLStimSet)), stimSetWaveNote, ";", inf)
		stimSetChecksum = AddListItem(num2istr(setChecksum), stimSetChecksum, ";", inf)
		stimSetLength = AddListItem(num2istr(setLength), stimSetLength, ";", inf)

		Make/FREE/B/U/N=(setLength) TTLWaveSingle
		MultiThread TTLWaveSingle[] = TTLStimSet[p][col]
		TTLWave[i] = TTLWaveSingle
	endfor

	sweepDataTxTLNB[0][%$"TTL channels"][INDEP_HEADSTAGE]             = channels
	sweepDataTxTLNB[0][%$"TTL stim sets"][INDEP_HEADSTAGE]            = listOfSets
	sweepDataTxTLNB[0][%$"TTL set sweep counts"][INDEP_HEADSTAGE]     = setSweepCounts
	sweepDataTxTLNB[0][%$"TTL Indexing End stimset"][INDEP_HEADSTAGE] = indexingEndStimset
	sweepDataTxTLNB[0][%$"TTL Stimset wave note"][INDEP_HEADSTAGE]    = stimSetWaveNote
	sweepDataTxTLNB[0][%$"TTL Stim Wave Checksum"][INDEP_HEADSTAGE]   = stimSetChecksum
	sweepDataTxTLNB[0][%$"TTL Stim set length"][INDEP_HEADSTAGE]      = stimSetLength
End

/// @brief Returns column number/step of the stimulus set, independent of the times the set is being cycled through
///        (as defined by SetVar_DataAcq_SetRepeats)
///
/// @param panelTitle    panel title
/// @param setName       name of the stimulus set
/// @param channelNo     channel number
/// @param channelType   channel type, one of @ref CHANNEL_TYPE_DAC or @ref CHANNEL_TYPE_TTL
///
/// @retval column        stimset column
/// @retval setCycleCount set cycle count
static Function [variable column, variable setCycleCount] DC_CalculateChannelColumnNo(string panelTitle, string setName, variable channelNo, variable channelType)

	variable ColumnsInSet = IDX_NumberOfSweepsInSet(SetName)
	variable localCount, repAcqRandom
	string sequenceWaveName
	variable skipAhead = DAP_GetskipAhead(panelTitle)

	repAcqRandom = DAG_GetNumericalValue(panelTitle, "check_DataAcq_RepAcqRandom")

	DFREF devicePath = GetDevicePath(panelTitle)

	// wave exists only if random set sequence is selected
	sequenceWaveName = SetName + num2str(channelType) + num2str(channelNo) + "_S"
	WAVE/Z/SDFR=devicePath WorkingSequenceWave = $sequenceWaveName
	NVAR count = $GetCount(panelTitle)
	// Below code calculates the variable local count which is then used to determine what column to select from a particular set
	if(!RA_IsFirstSweep(panelTitle))
		//thus the vairable "count" is used to determine if acquisition is on the first cycle
		if(!DAG_GetNumericalValue(panelTitle, "Check_DataAcq_Indexing"))
			localCount = count
		else // The local count is now set length dependent
			// check locked status. locked = popup menus on channels idex in lock - step
			if(DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_IndexingLocked"))
				/// @todo this code here is different compared to what RA_BckgTPwithCallToRACounterMD and RA_CounterMD do
				NVAR activeSetCount = $GetActiveSetCount(panelTitle)
				ASSERT(IsFinite(activeSetCount), "activeSetCount has to be finite")
				localCount = IDX_CalculcateActiveSetCount(panelTitle) - activeSetCount
			else
				// calculate where in list global count is
				localCount = IDX_UnlockedIndexingStepNo(panelTitle, channelNo, channelType, count)
			endif
		endif

		setCycleCount = trunc(localCount / ColumnsInSet)

		//Below code uses local count to determine  what step to use from the set based on the sweeps in cycle and sweeps in active set
		if(setCycleCount == 0)
			if(!repAcqRandom)
				column = localCount
			else
				if(localCount == 0)
					InPlaceRandomShuffle(WorkingSequenceWave)
				endif
				column = WorkingSequenceWave[localcount]
			endif
		else
			if(!repAcqRandom)
				column = mod((localCount), columnsInSet) // set has been cyled through once or more, uses remainder to determine correct column
			else
				if(mod((localCount), columnsInSet) == 0)
					InPlaceRandomShuffle(WorkingSequenceWave) // added to handle 1 channel, unlocked indexing
				endif
				column = WorkingSequenceWave[mod((localCount), columnsInSet)]
			endif
		endif
	else // first sweep
		if(!repAcqRandom)
			count += skipAhead
			column = count
			DAP_ResetSkipAhead(panelTitle)
			RA_StepSweepsRemaining(panelTitle)
		else
			Make/O/N=(ColumnsInSet) devicePath:$SequenceWaveName/Wave=WorkingSequenceWave = x
			InPlaceRandomShuffle(WorkingSequenceWave)
			column = WorkingSequenceWave[0]
		endif
	endif

	ASSERT(IsFinite(column) && column >=0, "column has to be finite and non-negative")

	return [column, setCycleCount]
End

/// @brief Returns the length increase of the DAQDataWave following onset/termination delay insertion and
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

	variable samplingInterval, onsetDelayUserVal, onsetDelayAutoVal, terminationDelayVal, distributedDAQDelayVal, numActiveDACs
	variable distributedDAQ

	numActiveDACs          = DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_DAC)
	samplingInterval       = DAP_GetSampInt(panelTitle, DATA_ACQUISITION_MODE)
	distributedDAQ         = DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_DistribDaq")
	onsetDelayUserVal      = round(DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_OnsetDelayUser") / (samplingInterval / 1000))
	onsetDelayAutoVal      = round(GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_OnsetDelayAuto") / (samplingInterval / 1000))
	terminationDelayVal    = round(DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_TerminationDelay") / (samplingInterval / 1000))
	distributedDAQDelayVal = round(DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_dDAQDelay") / (samplingInterval / 1000))

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

		// find out if we have only TP channels
		WAVE config = GetDAQConfigWave(panelTitle)
		WAVE DACmode = GetDACTypesFromConfig(config)

		FindValue/I=(DAQ_CHANNEL_TYPE_DAQ) DACmode

		if(V_Value == -1)
			return TIME_TP_ONLY_ON_DAQ * 1E6 / DAP_GetSampInt(panelTitle, dataAcqOrTP)
		else
			totalIncrease = DC_ReturnTotalLengthIncrease(panelTitle)
			TTLlength     = DC_CalculateLongestSweep(panelTitle, DATA_ACQUISITION_MODE, CHANNEL_TYPE_TTL)

			if(DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_dDAQOptOv"))
				DAClength = WaveMax(setLengths)
			elseif(DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_DistribDaq"))
				DAClength *= DC_NoOfChannelsSelected(panelTitle, CHANNEL_TYPE_DAC)
			endif

			return max(DAClength, TTLlength) + totalIncrease
		endif
	elseif(dataAcqOrTP == TEST_PULSE_MODE)
		return DAClength
	endif

	ASSERT(0, "unknown mode")
End

/// @brief Returns 1 if a channel is set to TP, the check is through the
/// stimset name from the GUI
Function DC_GotTPChannelWhileDAQ(panelTitle)
	string panelTitle

	variable i, numEntries
	WAVE statusDAFiltered = DC_GetFilteredChannelState(panelTitle, DATA_ACQUISITION_MODE, CHANNEL_TYPE_DAC)
	WAVE/T allSetNames = DAG_GetChannelTextual(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	numEntries = DimSize(statusDAFiltered, ROWS)

	for(i = 0; i < numEntries; i += 1)

		if(!statusDAFiltered[i])
			continue
		endif

		if(!CmpStr(allSetNames[i], STIMSET_TP_WHILE_DAQ))
			return 1
		endif

	endfor

	return 0
End

/// @brief Get the channel type of given headstage
///
/// @param panelTitle panel title
/// @param headstage head stage
///
/// @return One of @ref DaqChannelTypeConstants
Function DC_GetChannelTypefromHS(panelTitle, headstage)
	string panelTitle
	variable headstage

	variable dac, row
	WAVE config = GetDAQConfigWave(panelTitle)

	dac = AFH_GetDACFromHeadstage(panelTitle, headstage)

	if(!IsFinite(dac))
		return DAQ_CHANNEL_TYPE_UNKOWN
	endif

	row = AFH_GetDAQDataColumn(config, dac, XOP_CHANNEL_TYPE_DAC)
	ASSERT(IsFinite(row), "Invalid column")
	return config[row][%DAQChannelType]
End

#if IgorVersion() >= 9.0

/// @brief Debug function to add traces with epoch information
Function DC_AddDebugTracesForEpochs()

	variable i, j, k, numEntries, start_x, start_y, end_x, end_y, yOffset
	variable headstage, yLevelOffset, level, idx, numTraces, numEpochs
	variable sweepNumber
	STRUCT RGBColor c
	string devicesWithData, device, xaxis, yaxis, axes, axis, databrowser, levels_x_name, levels_y_name, name
	string level_0_trace, level_1_trace, level_2_trace, level_3_trace

	devicesWithData = GetAllDevicesWithContent()

	numEntries = ItemsInList(devicesWithData)
	for(i = 0; i < numEntries; i += 1)
		device = StringFromList(i, devicesWithData)

		databrowser = DB_FindDataBrowser(device)

		DFREF dfr = BSP_GetFolder(databrowser, MIES_BSP_PANEL_FOLDER)

		if(IsEmpty(databrowser))
			printf "Could not find databrowser for device %s\r", device
			continue
		endif

		WAVE/T textualValues = GetLBTextualValues(device)

		WAVE/T/Z traceInfos = GetTraceInfos(databrowser, addFilterKeys = {"channelType", "AssociatedHeadstage"}, addFilterValues = {"DA", "1"})

		if(!WaveExists(traceInfos))
			printf "Could not find any DA traces %s\r", device
			continue
		endif

		numTraces = DimSize(traceInfos, ROWS)
		for(j = 0; j < numTraces; j += 1)
			yaxis = traceInfos[j][%YAXIS]
			xaxis = traceInfos[j][%XAXIS]

			headstage   = str2num(traceInfos[j][%headstage])
			sweepNumber = str2num(traceInfos[j][%sweepNumber])

			WAVE/T epochLBEntries = GetLastSetting(textualValues, sweepNumber, EPOCHS_ENTRY_KEY, DATA_ACQUISITION_MODE)
			WAVE/T epochs = ListToTextWaveMD(epochLBEntries[headstage], 2, rowSep = ":", colSep = ",")

			sprintf name, "epochs_sweep%d_HS%d", sweepNumber, headstage
			Duplicate/O/T epochs, dfr:$name/Wave=epochs

			yLevelOffset = 10
			yOffset = - yLevelOffset

			numEpochs = DimSize(epochs, ROWS)

			Make/FREE/N=(4) currentLevel, indexInLevel

			sprintf levels_x_name, "epoch_vis_levels_x_sweep%d_HS%d", sweepNumber, headstage
			Make/O/N=(numEpochs * 3, 4, 2) dfr:$levels_x_name/WAVE=levels_x
			levels_x = NaN

			sprintf levels_y_name, "epoch_vis_levels_y_sweep%d_HS%d", sweepNumber, headstage
			Make/O/N=(numEpochs * 3, 4, 2) dfr:$levels_y_name/WAVE=levels_y
			levels_y = NaN
			SetStringInWaveNote(levels_y, "EpochInfo", GetWavesDataFolder(epochs, 2))

			for(k = 0; k < numEpochs; k += 1)

				start_x = str2num(epochs[k][0]) * 1000
				end_x   = str2num(epochs[k][1]) * 1000

				level = str2num(epochs[k][3])

				start_y = yOffset - yLevelOffset * level  - 0.1 * yLevelOffset * currentLevel[level]
				end_y = start_y

				idx = indexInLevel[level]
				levels_x[idx][level][0] = start_x
				levels_x[idx + 1][level][0] = end_x
				levels_x[idx + 2][level][0] = NaN
				levels_x[idx, idx + 2][level][1] = k

				levels_y[idx][level][0] = start_y
				levels_y[idx + 1][level][0] = end_y
				levels_y[idx + 2][level][0] = NaN
				levels_y[idx, idx + 2][level][1] = k

				indexInLevel[level] = idx + 3

				currentLevel[level] += 1
			endfor

			RemoveTracesFromGraph(databrowser, wv = levels_y)
			sprintf level_0_trace, "level%d_x_sweep%d_HS%d", 0, sweepNumber, headstage
			sprintf level_1_trace, "level%d_x_sweep%d_HS%d", 1, sweepNumber, headstage
			sprintf level_2_trace, "level%d_x_sweep%d_HS%d", 2, sweepNumber, headstage
			sprintf level_3_trace, "level%d_x_sweep%d_HS%d", 3, sweepNumber, headstage

			AppendToGraph/W=$databrowser/L=$yAxis levels_y[][0]/TN=$level_0_trace vs levels_x[][0]
			AppendToGraph/W=$databrowser/L=$yAxis levels_y[][1]/TN=$level_1_trace vs levels_x[][1]
			AppendToGraph/W=$databrowser/L=$yAxis levels_y[][2]/TN=$level_2_trace vs levels_x[][2]
			AppendToGraph/W=$databrowser/L=$yAxis levels_y[][3]/TN=$level_3_trace vs levels_x[][3]

			[c] = GetTraceColor(0)
			ModifyGraph/W=$databrowser marker($level_0_trace)=10, mode($level_0_trace)=4, rgb($level_0_trace)=(c.red, c.green, c.blue)
			[c] = GetTraceColor(1)
			ModifyGraph/W=$databrowser marker($level_1_trace)=10, mode($level_1_trace)=4, rgb($level_1_trace)=(c.red, c.green, c.blue)
			[c] = GetTraceColor(2)
			ModifyGraph/W=$databrowser marker($level_2_trace)=10, mode($level_2_trace)=4, rgb($level_2_trace)=(c.red, c.green, c.blue)
			[c] = GetTraceColor(3)
			ModifyGraph/W=$databrowser marker($level_3_trace)=10, mode($level_3_trace)=4, rgb($level_3_trace)=(c.red, c.green, c.blue)

			SetWindow $databrowser tooltipHook(hook) = DC_EpochGraphToolTip

			DoWindow/F $databrowser
			DoUpdate/W=$databrowser
			DoIgorMenu "Graph", "Show Trace Info Tags"

			SetAxis/W=$databrowser/A
		endfor
	endfor
End

Function DC_EpochGraphToolTip(s)
	STRUCT WMTooltipHookStruct &s

	variable idx, first, last
	Variable hookResult = 0 // 0 tells Igor to use the standard tooltip

	// traceName is set only for graphs and only if the mouse hovered near a trace
	if (strlen(s.traceName) > 0)
		s.tooltip = "a <-> b"
		s.isHtml = 1
		WAVE w = s.yWave // The trace's Y wave
		if (WaveDims(w) > 2)
			WAVE/T/Z epochs = $GetStringFromWaveNote(w, "EpochInfo")
			ASSERT(WaveExists(epochs), "Missing epoch info")
			hookResult = 1 // 1 tells Igor to use our custom tooltip
			idx = w[s.row][s.column][1]
			first = str2num(epochs[idx][0]) * 1000
			last  = str2num(epochs[idx][1]) * 1000

			s.tooltip = num2str(first) + "<->" + num2str(last) + "\n" + epochs[idx][2]
		endif
	endif

	return hookResult
End

#endif
