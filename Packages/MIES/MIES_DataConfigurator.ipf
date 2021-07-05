#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DC
#endif

/// @file MIES_DataConfigurator.ipf
/// @brief __DC__ Handle preparations before data acquisition or
/// test pulse related to the DAQ data and config waves

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

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		AS_HandlePossibleTransition(panelTitle, AS_PRE_SWEEP)
	endif

	WAVE DAQDataWave = GetDAQDataWave(panelTitle, dataAcqOrTP)
	WAVE DAQConfigWave = GetDAQConfigWave(panelTitle)

	ASSERT(IsValidSweepAndConfig(DAQDataWave, DAQConfigWave), "Invalid sweep and config combination")
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

	tpLength = ROVAR(GetTestPulseLengthInPoints(panelTitle, TEST_PULSE_MODE))
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

	variable i, j
	variable numDACEntries, numADCEntries, ttlIndex, setChecksum, stimsetCycleID, fingerprint, hardwareType, maxITI
	string ctrl, str, list, func, key
	variable setCycleCount, val, singleSetLength, samplingInterval
	variable channelMode, TPAmpVClamp, TPAmpIClamp, testPulseLength, maxStimSetLength
	variable GlobalTPInsert, scalingZero, indexingLocked, indexing, distributedDAQ, pulseToPulseLength
	variable distributedDAQDelay, onSetDelay, onsetDelayAuto, onsetDelayUser, terminationDelay
	variable decimationFactor, cutoff, row, column
	variable multiplier, powerSpectrum, distributedDAQOptOv, distributedDAQOptPre, distributedDAQOptPost, headstage
	variable lastValidRow, isoodDAQMember, channel, tpAmp, DAScale, stimsetCol, startOffset, ret
	variable epochBegin, epochEnd, epochOffset

	globalTPInsert        = DAG_GetNumericalValue(panelTitle, "Check_Settings_InsertTP")
	scalingZero           = DAG_GetNumericalValue(panelTitle,  "check_Settings_ScalingZero")
	indexingLocked        = DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_IndexingLocked")
	indexing              = DAG_GetNumericalValue(panelTitle, "Check_DataAcq_Indexing")
	distributedDAQ        = DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_DistribDaq")
	distributedDAQOptOv   = DAG_GetNumericalValue(panelTitle, "Check_DataAcq1_dDAQOptOv")
	distributedDAQOptPre  = DAG_GetNumericalValue(panelTitle, "Setvar_DataAcq_dDAQOptOvPre")
	distributedDAQOptPost = DAG_GetNumericalValue(panelTitle, "Setvar_DataAcq_dDAQOptOvPost")
	TPAmpVClamp           = DAG_GetNumericalValue(panelTitle, "SetVar_DataAcq_TPAmplitude")
	TPAmpIClamp           = DAG_GetNumericalValue(panelTitle, "SetVar_DataAcq_TPAmplitudeIC")
	powerSpectrum         = DAG_GetNumericalValue(panelTitle, "check_settings_show_power")

	// MH: note with NI the decimationFactor can now be < 1, like 0.4 if a single NI ADC channel runs with 500 kHz
	// whereas the source data generated waves for ITC min sample rate are at 200 kHz
	decimationFactor      = DC_GetDecimationFactor(panelTitle, dataAcqOrTP)
	samplingInterval      = DAP_GetSampInt(panelTitle, dataAcqOrTP)
	multiplier            = str2num(DAG_GetTextualValue(panelTitle, "Popup_Settings_SampIntMult"))
	WAVE/T allSetNames    = DAG_GetChannelTextual(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	WAVE/T allIndexingEndSetNames = DAG_GetChannelTextual(panelTitle, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
	hardwareType          = GetHardwareType(panelTitle)

	NVAR baselineFrac     = $GetTestpulseBaselineFraction(panelTitle)
	WAVE ChannelClampMode = GetChannelClampMode(panelTitle)
	WAVE statusHS         = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_HEADSTAGE)

	WAVE sweepDataLNB         = GetSweepSettingsWave(panelTitle)
	WAVE/T sweepDataTxTLNB    = GetSweepSettingsTextWave(panelTitle)
	WAVE/T cellElectrodeNames = GetCellElectrodeNames(panelTitle)
	WAVE/T analysisFunctions  = GetAnalysisFunctionStorage(panelTitle)
	WAVE setEventFlag         = GetSetEventFlag(panelTitle)
	WAVE DAGain               = SWS_GetChannelGains(panelTitle, timing = GAIN_BEFORE_DAQ)
	WAVE config               = GetDAQConfigWave(panelTitle)
	WAVE DACList              = GetDACListFromConfig(config)
	WAVE ADCList              = GetADCListFromConfig(config)
	WAVE/T epochsWave         = GetEpochsWave(panelTitle)
	epochsWave = ""

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		setEventFlag = 0
	endif

	numDACEntries = DimSize(DACList, ROWS)
	Make/D/FREE/N=(numDACEntries) insertStart, setLength, setColumn, headstageDAC
	Make/D/FREE/N=(numDACEntries, 2) DACAmp
	SetDimLabel COLS, 0, DASCALE, DACAmp
	SetDimLabel COLS, 1, TPAMP, DACAmp
	Make/T/FREE/N=(numDACEntries) setName
	Make/WAVE/FREE/N=(numDACEntries) stimSet

	NVAR raCycleID = $GetRepeatedAcquisitionCycleID(panelTitle)
	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		ASSERT(IsFinite(raCycleID), "Uninitialized raCycleID detected")
	endif

	WAVE testPulse = GetTestPulse()
	// test pulse length is calculated for dataAcqOrTP
	testPulseLength = DimSize(testPulse, ROWS)

	DC_DocumentChannelProperty(panelTitle, RA_ACQ_CYCLE_ID_KEY, INDEP_HEADSTAGE, NaN, NaN, var=raCycleID)

	headstageDAC[] = channelClampMode[DACList[p]][%DAC][%Headstage]

	// index guide:
	// - numEntries: Number of active DACs
	// - i: Zero-based index of the active DACS
	// - channel: DA channel number

	for(i = 0; i < numDACEntries; i += 1)
		channel = DACList[i]
		headstage = headstageDAC[i]

		// Setup stimset name for logging and stimset, for tp mode and tp channels stimset references the tp wave
		if(dataAcqOrTP == DATA_ACQUISITION_MODE)

			setName[i] = allSetNames[channel]
			if(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ)
				stimSet[i] = WB_CreateAndGetStimSet(setName[i])
			elseif(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_TP)
				stimSet[i] = GetTestPulse()
			else
				ASSERT(0, "Unknown DAQ Channel Type")
			endif

			DC_DocumentChannelProperty(panelTitle, "Indexing End Stimset", headstage, channel, XOP_CHANNEL_TYPE_DAC, str = allIndexingEndSetNames[channel])

		elseif(dataAcqOrTP == TEST_PULSE_MODE)

			setName[i] = LowerStr(STIMSET_TP_WHILE_DAQ)
			stimSet[i] = GetTestPulse()

		else
			ASSERT(0, "unknown mode")
		endif

		// restarting DAQ via the stimset popup menues does not call DAP_CheckSettings()
		// so the stimest must not exist here or it could be empty
		if(!WaveExists(stimSet[i]) || DimSize(stimSet[i], ROWS) == 0)
			Abort
		endif

		if(dataAcqOrTP == TEST_PULSE_MODE)
			setColumn[i] = 0
		elseif(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_TP)
			// DATA_ACQUISITION_MODE cases
			setColumn[i] = 0
		elseif(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ)
			// only call DC_CalculateChannelColumnNo for real data acquisition
			[ret, setCycleCount] = DC_CalculateChannelColumnNo(panelTitle, setName[i], channel, CHANNEL_TYPE_DAC)
			setColumn[i] = ret
		endif

		maxITI = max(maxITI, WB_GetITI(stimSet[i], setColumn[i]))

		if(IsFinite(headstage))
			channelMode = ChannelClampMode[channel][%DAC][%ClampMode]
			if(channelMode == V_CLAMP_MODE)
				DACAmp[i][%TPAMP] = TPAmpVClamp
			elseif(channelMode == I_CLAMP_MODE || channelMode == I_EQUAL_ZERO_MODE)
				DACAmp[i][%TPAMP] = TPAmpIClamp
			else
				ASSERT(0, "Unknown clamp mode")
			endif
		else // unassoc channel
			channelMode = NaN
			DACAmp[i][%TPAMP] = 0.0
		endif

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
		DACAmp[i][%DASCALE] = DAG_GetNumericalValue(panelTitle, ctrl, index = channel)

		// DA Scale and TP Amplitude tuning for special cases
		if(dataAcqOrTP == DATA_ACQUISITION_MODE)
			if(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ)
				// checks if user wants to set scaling to 0 on sets that have already cycled once
				if(scalingZero && (indexingLocked || !indexing) && setCycleCount > 0)
					DACAmp[i][%DASCALE] = 0
				endif

				if(channelMode == I_EQUAL_ZERO_MODE)
					DACAmp[i][%DASCALE] = 0
					DACAmp[i][%TPAMP] = 0
				endif
			elseif(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_TP)
				// do nothing
			endif
		elseif(dataAcqOrTP == TEST_PULSE_MODE)
			if(powerSpectrum)
				DACAmp[i][%TPAMP] = 0
			endif
		else
			ASSERT(0, "unknown mode")
		endif

		DC_DocumentChannelProperty(panelTitle, "DAC", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=channel)
		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
		DC_DocumentChannelProperty(panelTitle, "DA GAIN", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=DAG_GetNumericalValue(panelTitle, ctrl, index = channel))
		DC_DocumentChannelProperty(panelTitle, "DA ChannelType", headstage, channel, XOP_CHANNEL_TYPE_DAC, var = config[i][%DAQChannelType])

		DC_DocumentChannelProperty(panelTitle, STIM_WAVE_NAME_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, str=setName[i])
		DC_DocumentChannelProperty(panelTitle, STIMSET_WAVE_NOTE_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, str=NormalizeToEOL(RemoveEnding(note(stimSet[i]), "\r"), "\n"))

		for(j = 0; j < TOTAL_NUM_EVENTS; j += 1)
			if(IsFinite(headstage)) // associated channel
				func = analysisFunctions[headstage][j]
			else
				func = ""
			endif

			DC_DocumentChannelProperty(panelTitle, StringFromList(j, EVENT_NAME_LIST_LBN), headstage, channel, XOP_CHANNEL_TYPE_DAC, str=func)
		endfor

		if(IsFinite(headstage)) // associated channel
			str = analysisFunctions[headstage][ANALYSIS_FUNCTION_PARAMS]
		else
			str = ""
		endif

		DC_DocumentChannelProperty(panelTitle, ANALYSIS_FUNCTION_PARAMS_LBN, headstage, channel, XOP_CHANNEL_TYPE_DAC, str=str)

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
		DC_DocumentChannelProperty(panelTitle, "DA Unit", headstage, channel, XOP_CHANNEL_TYPE_DAC, str=DAG_GetTextualValue(panelTitle, ctrl, index = channel))

		DC_DocumentChannelProperty(panelTitle, STIMSET_SCALE_FACTOR_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, var = dataAcqOrTP == DATA_ACQUISITION_MODE && config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ ? DACAmp[i][%DASCALE] : DACAmp[i][%TPAMP])
		DC_DocumentChannelProperty(panelTitle, "Set Sweep Count", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=setColumn[i])
		DC_DocumentChannelProperty(panelTitle, "Electrode", headstage, channel, XOP_CHANNEL_TYPE_DAC, str=cellElectrodeNames[headstage])
		DC_DocumentChannelProperty(panelTitle, "Set Cycle Count", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=setCycleCount)

		setChecksum = WB_GetStimsetChecksum(stimSet[i], setName[i], dataAcqOrTP)
		DC_DocumentChannelProperty(panelTitle, "Stim Wave Checksum", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=setChecksum)

		if(dataAcqOrTP == DATA_ACQUISITION_MODE && config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ)
			fingerprint = DC_GenerateStimsetFingerprint(raCycleID, setName[i], setCycleCount, setChecksum, dataAcqOrTP)
			stimsetCycleID = DC_GetStimsetAcqCycleID(panelTitle, fingerprint, channel)

			setEventFlag[channel][] = (setColumn[i] + 1 == IDX_NumberOfSweepsInSet(setName[i]))
			DC_DocumentChannelProperty(panelTitle, STIMSET_ACQ_CYCLE_ID_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, var=stimsetCycleID)
		endif

		if(dataAcqOrTP == DATA_ACQUISITION_MODE)
			isoodDAQMember = (distributedDAQOptOv && config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ && IsFinite(headstage))
			DC_DocumentChannelProperty(panelTitle, "oodDAQ member", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=isoodDAQMember)
		endif
	endfor

	NVAR maxITIGlobal = $GetMaxIntertrialInterval(panelTitle)
	ASSERT(IsFinite(maxITI), "Invalid maxITI")
	maxITIGlobal = maxITI
	DC_DocumentChannelProperty(panelTitle, "Inter-trial interval", INDEP_HEADSTAGE, NaN, NaN, var=maxITIGlobal)

	// for distributedDAQOptOv create temporary reduced input waves holding DAQ types channels only (removing TP typed channels from TPwhileDAQ), put results back to unreduced waves
	if(distributedDAQOptOv && dataAcqOrTP == DATA_ACQUISITION_MODE)
		Duplicate/FREE/WAVE stimSet, reducedStimSet
		Duplicate/FREE setColumn, reducedSetColumn, iTemp

		j = 0
		for(i = 0; i < numDACEntries; i += 1)
			if(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ)
				reducedStimSet[j] = stimSet[i]
				reducedSetColumn[j] = setColumn[i]
				iTemp[j] = i
				j += 1
			endif
		endfor
		Redimension/N=(j) reducedStimSet, reducedSetColumn

		STRUCT OOdDAQParams params
		InitOOdDAQParams(params, reducedStimSet, reducedSetColumn, distributedDAQOptPre, distributedDAQOptPost)
		WAVE/WAVE reducedStimSet = OOD_GetResultWaves(panelTitle, params)
		WAVE reducedOffsets = params.offsets
		WAVE/T reducedRegions = params.regions

		Make/FREE/N=(numDACEntries) offsets = 0
		Make/FREE/T/N=(numDACEntries) regions

		j = DimSize(reducedStimSet, ROWS)
		for(i = 0; i < j; i += 1)
			stimSet[iTemp[i]] = reducedStimSet[i]
			setColumn[iTemp[i]] = reducedSetColumn[i]
			offsets[iTemp[i]] = reducedOffsets[i]
			regions[iTemp[i]] = reducedRegions[i]
		endfor
	endif

	if(!WaveExists(offsets))
		Make/FREE/N=(numDACEntries) offsets = 0
	else
		offsets[] *= WAVEBUILDER_MIN_SAMPINT
	endif

	// when DC_CalculateStimsetLength is called with dataAcqOrTP = DATA_ACQUISITION_MODE decimationFactor is considered
	if(dataAcqOrTP == TEST_PULSE_MODE)
		setLength[] = DC_CalculateStimsetLength(stimSet[p], panelTitle, TEST_PULSE_MODE)
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)
		Duplicate/FREE setLength, setMode
		setMode[] = config[p][%DAQChannelType] == DAQ_CHANNEL_TYPE_TP ? TEST_PULSE_MODE : DATA_ACQUISITION_MODE
		setLength[] = DC_CalculateStimsetLength(stimSet[p], panelTitle, setMode[p])
	endif

	if(dataAcqOrTP == TEST_PULSE_MODE)
		insertStart[] = 0
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)
		Duplicate/FREE insertStart, epochIndexer
		WAVE/T epochWave = GetEpochsWave(panelTitle)

		DC_ReturnTotalLengthIncrease(panelTitle, onsetdelayUser=onsetDelayUser, onsetDelayAuto=onsetDelayAuto, terminationDelay=terminationDelay, distributedDAQDelay=distributedDAQDelay)
		// epoch for onsetDelayAuto is assumed to be a globalTPInsert which is added as epoch below when the DA wave is filled
		if(onsetDelayUser)
			epochBegin = onsetDelayAuto * samplingInterval
			epochEnd = epochBegin + onsetDelayUser * samplingInterval
			epochIndexer[] = DC_AddEpoch(panelTitle, DACList[p], epochBegin, epochEnd, EPOCH_BASELINE_REGION_KEY, 0)
		endif

		onsetDelay = onsetDelayUser + onsetDelayAuto
		if(distributedDAQ)
			insertStart[] = onsetDelay + (sum(statusHS, 0, headstageDAC[p]) - 1) * (distributedDAQDelay + setLength[p])

			epochBegin = onsetDelay * samplingInterval
			epochIndexer[] = insertStart[p] * samplingInterval
			epochIndexer[] = epochBegin != epochIndexer[p] ? DC_AddEpoch(panelTitle, DACList[p], epochBegin, epochIndexer[p], EPOCH_BASELINE_REGION_KEY, 0) : 0

		else
			insertStart[] = onsetDelay
		endif

		if(terminationDelay)
			epochIndexer[] = (insertStart[p] + setLength[p]) * samplingInterval
			epochIndexer[] = DC_AddEpoch(panelTitle, DACList[p], epochIndexer[p], epochIndexer[p] + terminationDelay * samplingInterval, EPOCH_BASELINE_REGION_KEY, 0)
		endif

	endif

	NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
	stopCollectionPoint = DC_GetStopCollectionPoint(panelTitle, dataAcqOrTP, setLength)

	NVAR fifoPosition = $GetFifoPosition(panelTitle)
	fifoPosition = 0

	numADCEntries = DimSize(ADCList, ROWS)

	ClearRTError()

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
		ASSERT(DimSize(testPulse, COLS) <= 1, "Expected a 1D testpulse wave")
		ASSERT(numADCEntries > 0, "Number of ADCs can not be zero")
		ASSERT(numDACEntries > 0, "Number of DACs can not be zero")

		struct HardwareDataTPInput s
		s.hardwareType = hardwareType
		s.numDACs = numDACEntries
		s.numActiveChannels = numActiveChannels
		s.numberOfRows = DC_CalculateDAQDataWaveLength(panelTitle, TEST_PULSE_MODE)
		s.samplingInterval = samplingInterval
		WAVE s.DAGain = DAGain
		Duplicate/FREE/RMD=[][FindDimLabel(DACAmp, COLS, "TPAMP")] DACAmp, DACAmpTP
		WAVE s.DACAmpTP = DACAmpTP
		s.testPulseLength = testPulseLength
		s.baseLineFrac = baselineFrac

		key = CA_HardwareDataTPKey(s)

		WAVE/Z result = CA_TryFetchingEntryFromCache(key)

		if(WaveExists(result))
			WAVE DAQDataWave = GetDAQDataWave(panelTitle, dataAcqOrTP)

			if(!cmpstr(GetStringFromWaveNote(DAQDataWave, TP_PROPERTIES_HASH), key))
				// clear the AD data only
				switch(hardwareType)
					case HARDWARE_ITC_DAC:
						WAVE/W ITCDataWave = DAQDataWave
						Multithread ITCDataWave[][numDACEntries, numDACEntries + numADCEntries - 1] = 0
						break
					case HARDWARE_NI_DAC:
						WAVE/WAVE NIDataWave = DAQDataWave
						for(i = 0; i < numADCEntries; i += 1)
							WAVE NIChannel = NIDataWave[numDACEntries + i]
							FastOp NIChannel = 0
						endfor
						break
				endswitch
			else
				if(IsWaveRefWave(DAQDataWave))
					WAVE/WAVE DAQDataWaveRef = DAQDataWave
					Redimension/N=(numActiveChannels) DAQDataWaveRef
					DAQDataWaveRef[] = GetNIDAQChannelWave(panelTitle, p)
				endif
				SetStringInWaveNote(result, TP_PROPERTIES_HASH, key)
				MoveWaveWithOverwrite(DAQDataWave, result, recursive = 1)
			endif
		else
			WAVE/Z ITCDataWave
			WAVE/WAVE/Z NIDataWave

			[ITCDataWave, NIDataWave] = DC_MakeAndGetDAQDataWave(panelTitle, hardwareType, numActiveChannels, \
			                                                     samplingInterval, dataAcqOrTP)

			switch(hardwareType)
				case HARDWARE_ITC_DAC:
					if(multiDevice)
						Multithread ITCDataWave[][0, numDACEntries - 1] =                           \
						limit(                                                                      \
						      (DAGain[q] * DACAmp[q][%TPAMP]) * testPulse[mod(p, testPulseLength)], \
						      SIGNED_INT_16BIT_MIN,                                                 \
						      SIGNED_INT_16BIT_MAX); AbortOnRTE
						cutOff = mod(DimSize(ITCDataWave, ROWS), testPulseLength)
						if(cutOff > 0)
							ITCDataWave[DimSize(ITCDataWave, ROWS) - cutoff, *][0, numDACEntries - 1] = 0
						endif
					else
						Multithread ITCDataWave[0, testPulseLength - 1][0, numDACEntries - 1] = \
						limit(                                                                  \
						      DAGain[q] * DACAmp[q][%TPAMP] * testPulse[p],                     \
						      SIGNED_INT_16BIT_MIN,                                             \
						      SIGNED_INT_16BIT_MAX); AbortOnRTE
					endif

					SetStringInWaveNote(ITCDataWave, TP_PROPERTIES_HASH, key)
					CA_StoreEntryIntoCache(key, ITCDataWave)
					break
				case HARDWARE_NI_DAC:
					for(i = 0;i < numDACEntries; i += 1)
						WAVE NIChannel = NIDataWave[i]
						tpAmp = DACAmp[i][%TPAMP] * DAGain[i]
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
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)

		WAVE/Z ITCDataWave
		WAVE/WAVE/Z NIDataWave

		[ITCDataWave, NIDataWave] = DC_MakeAndGetDAQDataWave(panelTitle, hardwareType, numActiveChannels, \
		                                                     samplingInterval, dataAcqOrTP)

		for(i = 0; i < numDACEntries; i += 1)
			if(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_TP)
				// TP wave does not need to be decimated, it has already correct size reg. sample rate
				tpAmp = DACAmp[i][%TPAMP] * DAGain[i]
				ASSERT(DimSize(testPulse, COLS) <= 1, "Expected a 1D testpulse wave")
				switch(hardwareType)
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
				channel = DACList[i]
				headstage = headstageDAC[i]
				tpAmp = DACAmp[i][%TPAMP] * DAGain[i]
				DAScale = DACAmp[i][%DASCALE] * DAGain[i]
				WAVE singleStimSet = stimSet[i]
				singleSetLength = setLength[i]
				stimsetCol = setColumn[i]
				startOffset = insertStart[i]

				epochBegin = startOffset * samplingInterval
				if(distributedDAQOptOv && offsets[i] > 0)
					epochOffset = offsets[i] * 1000
					DC_AddEpoch(panelTitle, channel, epochBegin, epochBegin + epochOffset, EPOCH_BASELINE_REGION_KEY, 0)
					DC_AddEpochsFromStimSetNote(panelTitle, channel, singleStimSet, epochBegin + epochOffset, singleSetLength * samplingInterval - epochOffset, stimsetCol, DACAmp[i][%DASCALE])
				else
					DC_AddEpochsFromStimSetNote(panelTitle, channel, singleStimSet, epochBegin, singleSetLength * samplingInterval, stimsetCol, DACAmp[i][%DASCALE])
				endif
				if(distributedDAQOptOv)
					DC_AddEpochsFromOodDAQRegions(panelTitle, channel, regions[i], epochBegin)
				endif
				// if dDAQ is on then channels 0 to numEntries - 1 have a trailing base line
				epochBegin = startOffset + singleSetLength + terminationDelay
				if(stopCollectionPoint > epochBegin)
					DC_AddEpoch(panelTitle, channel, epochBegin * samplingInterval, stopCollectionPoint * samplingInterval, EPOCH_BASELINE_REGION_KEY, 0)
				endif

				switch(hardwareType)
					case HARDWARE_ITC_DAC:
						Multithread ITCDataWave[startOffset, startOffset + singleSetLength - 1][i] =     \
						limit(                                                                           \
						      DAScale * singleStimSet[decimationFactor * (p - startOffset)][stimsetCol], \
						      SIGNED_INT_16BIT_MIN,                                                      \
						      SIGNED_INT_16BIT_MAX); AbortOnRTE

						if(globalTPInsert)
							// space in ITCDataWave for the testpulse is allocated via an automatic increase
							// of the onset delay
							DC_AddEpochsFromTP(panelTitle, channel, baselinefrac, testPulseLength * samplingInterval, 0, "Inserted TP", DACAmp[i][%TPAMP])
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
						MultiThread NIChannel[startOffset, startOffset + singleSetLength - 1] =                                  \
						limit(                                                                                                   \
						      DAScale * singleStimSet[limit(decimationFactor * (p - startOffset), 0, lastValidRow)][stimsetCol], \
						      NI_DAC_MIN,                                                                                        \
						      NI_DAC_MAX); AbortOnRTE

						if(globalTPInsert)
							// space in ITCDataWave for the testpulse is allocated via an automatic increase
							// of the onset delay
							DC_AddEpochsFromTP(panelTitle, channel, baselinefrac, testPulseLength * samplingInterval, 0, "Inserted TP", DACAmp[i][%TPAMP])
							MultiThread NIChannel[0, testPulseLength - 1] = \
							limit(tpAmp * testPulse[p], NI_DAC_MIN, NI_DAC_MAX); AbortOnRTE
						endif
						break
				endswitch
			else
				ASSERT(0, "Unknown DAC channel type")
			endif
		endfor
	endif

	DC_SortEpochs(panelTitle)

	if(!WaveExists(regions))
		Make/FREE/T/N=(numDACEntries) regions
	endif

	for(i = 0; i < numDACEntries; i += 1)
		channel = DACList[i]
		headstage = headstageDAC[i]
		DC_DocumentChannelProperty(panelTitle, "Stim set length", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=setLength[i])
		DC_DocumentChannelProperty(panelTitle, "Delay onset oodDAQ", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=offsets[i])
		DC_DocumentChannelProperty(panelTitle, "oodDAQ regions", headstage, channel, XOP_CHANNEL_TYPE_DAC, str=regions[i])

		WAVE/T epochWave = GetEpochsWave(panelTitle)
		Duplicate/FREE/RMD=[][][channel] epochWave, epochChannel
		Redimension/N=(-1, -1, 0) epochChannel
		DC_DocumentChannelProperty(panelTitle, EPOCHS_ENTRY_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, str=TextWaveToList(epochChannel, ":", colSep = ",", stopOnEmpty = 1))
	endfor

	DC_DocumentChannelProperty(panelTitle, "Sampling interval multiplier", INDEP_HEADSTAGE, NaN, NaN, var=str2num(DAG_GetTextualValue(panelTitle, "Popup_Settings_SampIntMult")))
	DC_DocumentChannelProperty(panelTitle, "Fixed frequency acquisition", INDEP_HEADSTAGE, NaN, NaN, var=str2numSafe(DAG_GetTextualValue(panelTitle, "Popup_Settings_FixedFreq")))
	DC_DocumentChannelProperty(panelTitle, "Sampling interval", INDEP_HEADSTAGE, NaN, NaN, var=samplingInterval * 1e-3)

	DC_DocumentChannelProperty(panelTitle, "Delay onset user", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_OnsetDelayUser"))
	DC_DocumentChannelProperty(panelTitle, "Delay onset auto", INDEP_HEADSTAGE, NaN, NaN, var=GetValDisplayAsNum(panelTitle, "valdisp_DataAcq_OnsetDelayAuto"))
	DC_DocumentChannelProperty(panelTitle, "Delay termination", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_TerminationDelay"))
	DC_DocumentChannelProperty(panelTitle, "Delay distributed DAQ", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "setvar_DataAcq_dDAQDelay"))
	DC_DocumentChannelProperty(panelTitle, "oodDAQ Pre Feature", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "Setvar_DataAcq_dDAQOptOvPre"))
	DC_DocumentChannelProperty(panelTitle, "oodDAQ Post Feature", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "Setvar_DataAcq_dDAQOptOvPost"))
	DC_DocumentChannelProperty(panelTitle, "oodDAQ Resolution", INDEP_HEADSTAGE, NaN, NaN, var=WAVEBUILDER_MIN_SAMPINT)

	DC_DocumentChannelProperty(panelTitle, "TP Insert Checkbox", INDEP_HEADSTAGE, NaN, NaN, var=GlobalTPInsert)
	DC_DocumentChannelProperty(panelTitle, "Distributed DAQ", INDEP_HEADSTAGE, NaN, NaN, var=distributedDAQ)
	DC_DocumentChannelProperty(panelTitle, "Optimized Overlap dDAQ", INDEP_HEADSTAGE, NaN, NaN, var=distributedDAQOptOv)
	DC_DocumentChannelProperty(panelTitle, "Repeat Sets", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(panelTitle, "SetVar_DataAcq_SetRepeats"))
	DC_DocumentChannelProperty(panelTitle, "Scaling zero", INDEP_HEADSTAGE, NaN, NaN, var=scalingZero)
	DC_DocumentChannelProperty(panelTitle, "Indexing", INDEP_HEADSTAGE, NaN, NaN, var=indexing)
	DC_DocumentChannelProperty(panelTitle, "Locked indexing", INDEP_HEADSTAGE, NaN, NaN, var=indexingLocked)
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

	DC_DocumentHardwareProperties(panelTitle, hardwareType)

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

		DC_DocumentChannelProperty(panelTitle, "Headstage Active", i, NaN, NaN, var=statusHS[i])

		if(!statusHS[i])
			continue
		endif

		DC_DocumentChannelProperty(panelTitle, "Clamp Mode", i, NaN, NaN, var=DAG_GetHeadstageMode(panelTitle, i))
	endfor

	if(distributedDAQ)
		// dDAQ requires that all stimsets have the same length, so store the stim set length
		// also headstage independent
		ASSERT(!distributedDAQOptOv, "Unexpected oodDAQ mode")
		ASSERT(WaveMin(setLength) == WaveMax(setLength), "Unexpected varying stim set length")
		DC_DocumentChannelProperty(panelTitle, "Stim set length", INDEP_HEADSTAGE, NaN, NaN, var=setLength[0])
	endif

	for(i = 0; i < numADCEntries; i += 1)
		channel = ADCList[i]
		headstage = channelClampMode[channel][%ADC][%Headstage]

		DC_DocumentChannelProperty(panelTitle, "ADC", headstage, channel, XOP_CHANNEL_TYPE_ADC, var=channel)

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
		DC_DocumentChannelProperty(panelTitle, "AD Gain", headstage, channel, XOP_CHANNEL_TYPE_ADC, var=DAG_GetNumericalValue(panelTitle, ctrl, index = channel))

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
		DC_DocumentChannelProperty(panelTitle, "AD Unit", headstage, channel, XOP_CHANNEL_TYPE_ADC, str=DAG_GetTextualValue(panelTitle, ctrl, index = channel))

		DC_DocumentChannelProperty(panelTitle, "AD ChannelType", headstage, channel, XOP_CHANNEL_TYPE_ADC, var = config[numDACEntries + i][%DAQChannelType])
	endfor

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		// reset to the default value without distributedDAQ
		startOffset = onSetDelay
		ttlIndex = numDACEntries + numADCEntries
		switch(hardwareType)
			case HARDWARE_NI_DAC:
				WAVE/WAVE TTLWaveNI = GetTTLWave(panelTitle)
				DC_NI_MakeTTLWave(panelTitle)
				for(i = 0; i < DimSize(config, ROWS); i += 1)
					if(config[i][%ChannelType] == XOP_CHANNEL_TYPE_TTL)
						WAVE NIChannel = NIDataWave[ttlIndex]
						WAVE TTLWaveSingle = TTLWaveNI[config[i][%ChannelNumber]]
						singleSetLength = DC_CalculateStimsetLength(TTLWaveSingle, panelTitle, DATA_ACQUISITION_MODE)
						MultiThread NIChannel[startOffset, startOffset + singleSetLength - 1] = \
						limit(TTLWaveSingle[trunc(decimationFactor * (p - startOffset))], 0, 1); AbortOnRTE
						ttlIndex += 1
					endif
				endfor
				break
			case HARDWARE_ITC_DAC:
				WAVE TTLWaveITC = GetTTLWave(panelTitle)
				// Place TTL waves into ITCDataWave
				if(DC_AreTTLsInRackChecked(panelTitle, RACK_ZERO))
					DC_ITC_MakeTTLWave(panelTitle, RACK_ZERO)
					singleSetLength = DC_CalculateStimsetLength(TTLWaveITC, panelTitle, DATA_ACQUISITION_MODE)
					MultiThread ITCDataWave[startOffset, startOffset + singleSetLength - 1][ttlIndex] = \
					limit(TTLWaveITC[trunc(decimationFactor * (p - startOffset))], SIGNED_INT_16BIT_MIN, SIGNED_INT_16BIT_MAX); AbortOnRTE
					ttlIndex += 1
				endif

				if(DC_AreTTLsInRackChecked(panelTitle, RACK_ONE))
					DC_ITC_MakeTTLWave(panelTitle, RACK_ONE)
					singleSetLength = DC_CalculateStimsetLength(TTLWaveITC, panelTitle, DATA_ACQUISITION_MODE)
					MultiThread ITCDataWave[startOffset, startOffset + singleSetLength - 1][ttlIndex] = \
					limit(TTLWaveITC[trunc(decimationFactor * (p - startOffset))], SIGNED_INT_16BIT_MIN, SIGNED_INT_16BIT_MAX); AbortOnRTE
				endif
				break
		endswitch
	endif

	[ret, row, column] = DC_CheckIfDataWaveHasBorderVals(panelTitle, dataAcqOrTP)

	if(ret)
		printf "Error writing into DataWave in %s mode: The values at [%g, %g] are out of range. Maybe the DA/AD Gain needs adjustment?\r", SelectString(dataAcqOrTP, "DATA_ACQUISITION", "TestPulse"), row, column
		ControlWindowToFront()
		Abort
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

/// @brief Adds four epochs for a test pulse and three sub epochs for test pulse components
/// @param[in] panelTitle      title of device panel
/// @param[in] channel         number of DA channel
/// @param[in] baselinefrac    base line fraction of testpulse
/// @param[in] testPulseLength test pulse length in micro seconds
/// @param[in] offset          start time of test pulse in micro seconds
/// @param[in] name            name of test pulse (e.g. Inserted TP)
/// @param[in] amplitude       amplitude of the TP in the DA wave without gain
static Function DC_AddEpochsFromTP(panelTitle, channel, baselinefrac, testPulseLength, offset, name, amplitude)
	string panelTitle
	variable channel
	variable baselinefrac, testPulseLength
	variable offset
	string name
	variable amplitude

	variable epochBegin
	variable epochEnd
	string epochName, epochSubName

	// main TP range
	epochBegin = offset
	epochEnd = epochBegin + testPulseLength
	epochName = AddListItem("Test Pulse", name, EPOCHNAME_SEP, Inf)
	DC_AddEpoch(panelTitle, channel, epochBegin, epochEnd, epochName, 0)

	// TP sub ranges
	epochBegin = baselineFrac * testPulseLength + offset
	epochEnd = (1 - baselineFrac) * testPulseLength + offset
	epochSubName = AddListItem("pulse", epochName, EPOCHNAME_SEP, Inf)
	epochSubName = ReplaceNumberByKey("Amplitude", epochSubName, amplitude, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	DC_AddEpoch(panelTitle, channel, epochBegin, epochEnd, epochSubName, 1)

	epochBegin = offset
	epochEnd = epochBegin + baselineFrac * testPulseLength
	DC_AddEpoch(panelTitle, channel, epochBegin, epochEnd, EPOCH_BASELINE_REGION_KEY, 1)

	epochBegin = (1 - baselineFrac) * testPulseLength + offset
	epochEnd = testPulseLength + offset
	DC_AddEpoch(panelTitle, channel, epochBegin, epochEnd, EPOCH_BASELINE_REGION_KEY, 1)
End

/// @brief Adds epochs for oodDAQ regions
/// @param[in] panelTitle    title of device panel
/// @param[in] channel       number of DA channel
/// @param[in] oodDAQRegions string containing list of oodDAQ regions as %d-%d;...
/// @param[in] stimsetBegin offset time in micro seconds where stim set begins
static Function DC_AddEpochsFromOodDAQRegions(panelTitle, channel, oodDAQRegions, stimsetBegin)
	string panelTitle
	variable channel
	string oodDAQRegions
	variable stimsetBegin

	variable numRegions
	WAVE/T regions = ListToTextWave(oodDAQRegions, ";")
	numRegions = DimSize(regions, ROWS)
	if(numRegions)
		Make/FREE/N=(numRegions) epochIndexer
		epochIndexer[] = DC_AddEpoch(panelTitle, channel, str2num(StringFromList(0, regions[p], "-")) * 1E3 + stimsetBegin, str2num(StringFromList(1, regions[p], "-")) * 1E3 + stimsetBegin, EPOCH_OODDAQ_REGION_KEY + "=" + num2str(p), 2)
	endif
End

static StrConstant EPOCHNAME_SEP = ";"
static StrConstant STIMSETKEYNAME_SEP = "="

/// @brief Adds epochs for a stimset and sub epochs for stimset components
/// currently adds also sub sub epochs for pulse train components
/// @param[in] panelTitle   title of device panel
/// @param[in] channel      number of DA channel
/// @param[in] stimset      stimset wave
/// @param[in] stimsetBegin offset time in micro seconds where stim set begins
/// @param[in] setLength    length of stimset in micro seconds
/// @param[in] sweep        number of sweep
/// @param[in] scale        scale factor between the stimsets internal amplitude to the DA wave without gain
static Function DC_AddEpochsFromStimSetNote(panelTitle, channel, stimset, stimsetBegin, setLength, sweep, scale)
	string panelTitle
	variable channel
	WAVE stimset
	variable stimsetBegin, setLength, sweep, scale

	variable stimsetEnd, stimsetEndLogical
	variable epochBegin, epochEnd, subEpochBegin, subEpochEnd
	string epSweepName, epSubName, epSubSubName, epSpecifier
	variable epochCount, totalDuration, poissonDistribution
	variable epochNr, pulseNr, numPulses, epochType, flipping, pulseToPulseLength, stimEpochAmplitude, amplitude
	variable pulseDuration
	variable subsubEpochBegin, subsubEpochEnd
	string type, startTimesList
	string stimNote = note(stimset)

	stimsetEnd = stimsetBegin + setLength
	DC_AddEpoch(panelTitle, channel, stimsetBegin, stimsetEnd, "Stimset", 0)

	epochCount = WB_GetWaveNoteEntryAsNumber(stimNote, STIMSET_ENTRY, key="Epoch Count")

	Make/FREE/D/N=(epochCount) duration, sweepOffset

	duration[] = WB_GetWaveNoteEntryAsNumber(stimNote, EPOCH_ENTRY, key="Duration", sweep=sweep, epoch=p)
	duration *= 1000
	totalDuration = sum(duration)

	ASSERT(IsFinite(totalDuration), "Expected finite totalDuration")
	ASSERT(IsFinite(stimsetBegin), "Expected finite stimsetBegin")
	stimsetEndLogical = stimsetBegin + totalDuration

	if(epochCount > 1)
		sweepOffset[0] = 0
		sweepOffset[1,] = sweepOffset[p - 1] + duration[p - 1]
	endif

	flipping = WB_GetWaveNoteEntryAsNumber(stimNote, STIMSET_ENTRY, key = "Flip")

	epSweepName = ""

	for(epochNr = 0; epochNr < epochCount; epochNr += 1)
		type = WB_GetWaveNoteEntry(stimNote, EPOCH_ENTRY, key="Type", sweep=sweep, epoch=epochNr)
		epochType = WB_ToEpochType(type)
		stimEpochAmplitude = WB_GetWaveNoteEntryAsNumber(stimNote, EPOCH_ENTRY, key="Amplitude", sweep=sweep, epoch=epochNr)
		amplitude = scale * stimEpochAmplitude
		if(flipping)
			// in case of oodDAQ cutOff stimsetEndLogical can be greater than stimsetEnd, thus epochEnd can be greater than stimsetEnd
			epochEnd = stimsetEndLogical - sweepOffset[epochNr]
			epochBegin = epochEnd - duration[epochNr]
		else
			epochBegin = sweepOffset[epochNr] + stimsetBegin
			epochEnd = epochBegin + duration[epochNr]
		endif

		if(epochBegin >= stimsetEnd)
			// sweep epoch starts beyond stimset end
			DEBUGPRINT("Warning: Epoch starts after Stimset end.")
			continue
		endif

		poissonDistribution = !CmpStr(WB_GetWaveNoteEntry(stimNote, EPOCH_ENTRY, sweep = sweep, epoch = epochNr, key = "Poisson distribution"), "True")

		epSubName = ReplaceNumberByKey("Epoch", epSweepName, epochNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
		epSubName = ReplaceStringByKey("Type", epSubName, type, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
		epSubName = ReplaceNumberByKey("Amplitude", epSubName, amplitude, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
		if(epochType == EPOCH_TYPE_PULSE_TRAIN)
			if(!CmpStr(WB_GetWaveNoteEntry(stimNote, EPOCH_ENTRY, sweep = sweep, epoch = epochNr, key = "Mixed frequency"), "True"))
				epSpecifier = "Mixed frequency"
			elseif(poissonDistribution)
				epSpecifier = "Poisson distribution"
			endif
			if(!CmpStr(WB_GetWaveNoteEntry(stimNote, EPOCH_ENTRY, key="Mixed frequency shuffle", sweep=sweep, epoch=epochNr), "True"))
				epSpecifier += " shuffled"
			endif
		else
			epSpecifier = ""
		endif
		if(!isEmpty(epSpecifier))
			epSubName = ReplaceStringByKey("Details", epSubName, epSpecifier, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
		endif

		DC_AddEpoch(panelTitle, channel, epochBegin, epochEnd, epSubName, 1, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)

		// Add Sub Sub Epochs
		if(epochType == EPOCH_TYPE_PULSE_TRAIN)
			WAVE startTimes = WB_GetPulsesFromPTSweepEpoch(stimset, sweep, epochNr, pulseToPulseLength)
			startTimes *= 1000
			numPulses = DimSize(startTimes, ROWS)
			if(numPulses)
				Duplicate/FREE startTimes, ptp
				ptp[] = pulseToPulseLength ? pulseToPulseLength * 1000 : startTimes[p] - startTimes[limit(p - 1, 0, Inf)]
				pulseDuration = WB_GetWaveNoteEntryAsNumber(stimNote, EPOCH_ENTRY, key="Pulse duration", sweep=sweep, epoch=epochNr)
				pulseDuration *= 1000

				// with flipping we iterate the pulses from large to small time points

				for(pulseNr = 0; pulseNr < numPulses; pulseNr += 1)
					if(flipping)
						// shift all flipped pulse intervalls by pulseDuration to the left, except the rightmost with pulseNr 0
						if(!pulseNr)
							subEpochBegin = epochEnd - startTimes[0] - pulseDuration
							// assign left over time after the last pulse to that pulse
							subEpochEnd = epochEnd
						else
							subEpochEnd = epochEnd - startTimes[pulseNr - 1] - pulseDuration
							subEpochBegin = pulseNr + 1 == numPulses ? epochBegin : subEpochEnd - ptp[pulseNr]
						endif

					else
						subEpochBegin = epochBegin + startTimes[pulseNr]
						subEpochEnd = pulseNr + 1 == numPulses ? epochEnd : subEpochBegin + ptp[pulseNr + 1]
					endif

					if(subEpochBegin >= epochEnd || subEpochEnd <= epochBegin)
						DEBUGPRINT("Warning: sub epoch of pulse starts after epoch end or ends before epoch start.")
					elseif(subEpochBegin >= stimsetEnd || subEpochEnd <= stimsetBegin)
						DEBUGPRINT("Warning: sub epoch of pulse starts after stimset end or ends before stimset start.")
					else
						subEpochBegin = limit(subEpochBegin, epochBegin, Inf)
						subEpochEnd = limit(subEpochEnd, -Inf, epochEnd)

						// baseline before leftmost/rightmost pulse?
						if(((pulseNr == numPulses - 1 && flipping) || (!pulseNr && !flipping)) \
						   && subEpochBegin > epochBegin && subEpochBegin > stimsetBegin)
							DC_AddEpoch(panelTitle, channel, epochBegin, subEpochBegin, EPOCH_BASELINE_REGION_KEY, 2, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)
						endif

						epSubSubName = ReplaceNumberByKey("Pulse", epSubName, pulseNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
						DC_AddEpoch(panelTitle, channel, subEpochBegin, subEpochEnd, epSubSubName, 2, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)

						// active
						subsubEpochBegin = subEpochBegin

						// normally we never have a trailing baseline with pulse train except when poission distribution
						// is used. So we can only assign the left over time to pulse active if we are not in this
						// special case.
						if(!poissonDistribution && (pulseNr == (flipping ? 0 : numPulses - 1)))
							subsubEpochEnd = subEpochEnd
						else
							subsubEpochEnd = subEpochBegin + pulseDuration
						endif

						if(subsubEpochBegin >= subEpochEnd || subsubEpochEnd <= subEpochBegin)
							DEBUGPRINT("Warning: sub sub epoch of active pulse starts after stimset end or ends before stimset start.")
						else
							subsubEpochBegin = limit(subsubEpochBegin, subEpochBegin, Inf)
							subsubEpochEnd = limit(subsubEpochEnd, -Inf, subEpochEnd)

							epSubSubName = ReplaceNumberByKey("Pulse", epSubName, pulseNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
							epSubSubName = epSubSubName + "Active"
							DC_AddEpoch(panelTitle, channel, subsubEpochBegin, subsubEpochEnd, epSubSubName, 3, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)

							// baseline
							subsubEpochBegin = subsubEpochEnd
							subsubEpochEnd   = subEpochEnd

							if(subsubEpochBegin >= stimsetEnd || subsubEpochEnd <= stimsetBegin)
								DEBUGPRINT("Warning: sub sub epoch of pulse active starts after stimset end or ends before stimset start.")
							elseif(subsubEpochBegin >= subsubEpochEnd)
								DEBUGPRINT("Warning: sub sub epoch of pulse baseline is not present.")
							else
								epSubSubName = ReplaceNumberByKey("Pulse", epSubName, pulseNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
								epSubSubName = RemoveByKey("Amplitude", epSubSubName, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
								epSubSubName = epSubSubName + "Baseline"
								DC_AddEpoch(panelTitle, channel, subsubEpochBegin, subsubEpochEnd, epSubSubName, 3, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)
							endif
						endif
					endif
				endfor
			else
				DC_AddEpoch(panelTitle, channel, epochBegin, epochEnd, EPOCH_BASELINE_REGION_KEY, 2, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)
			endif
		else
			// Epoch details on other types not implemented yet
		endif

	endfor

	// stimsets with multiple sweeps where each sweep has a different length (due to delta mechanism)
	// result in 2D stimset waves where all sweeps have the same length
	// therefore we must add a baseline epoch after all defined epochs
	if(stimsetEnd > stimsetEndLogical)
		DC_AddEpoch(panelTitle, channel, stimsetEndLogical, stimsetEnd, EPOCH_BASELINE_REGION_KEY, 1)
	endif
End

/// Epoch times are saved in s, so 7 digits are 0.1 microseconds precision
/// which is sufficient to represent each sample point time with a distinctive number up to rates of 10 MHz.
static Constant EPOCHTIME_PRECISION = 7

/// @brief Sorts all epochs per channel in EpochsWave
/// @param[in] panelTitle title of device panel
static Function DC_SortEpochs(panelTitle)
	string panelTitle

	variable channel, channelCnt, epochCnt
	variable col0, col1, col2
	WAVE/T epochWave = GetEpochsWave(panelTitle)
	channelCnt = DimSize(epochWave, LAYERS)
	for(channel = 0; channel < channelCnt; channel += 1)
		epochCnt = DC_GetEpochCount(panelTitle, channel)
		if(epochCnt)
			Duplicate/FREE/T/RMD=[, epochCnt - 1][][channel] epochWave, epochChannel
			Redimension/N=(-1, -1, 0) epochChannel
			epochChannel[][%EndTime] = num2strHighPrec(-1 * str2num(epochChannel[p][%EndTime]), precision = EPOCHTIME_PRECISION)
			col0 = FindDimLabel(epochChannel, COLS, "StartTime")
			col1 = FindDimLabel(epochChannel, COLS, "EndTime")
			col2 = FindDimLabel(epochChannel, COLS, "TreeLevel")
			ASSERT(col0 >= 0 && col1 >= 0 && col2 >= 0, "Column in epochChannel wave not found")
			MDSort(epochChannel, col0, keyColSecondary = col1, keyColTertiary = col2)
			epochChannel[][%EndTime] = num2strHighPrec(-1 * str2num(epochChannel[p][%EndTime]), precision = EPOCHTIME_PRECISION)
			epochWave[, epochCnt - 1][][channel] = epochChannel[p][q]
		endif
	endfor

End

/// @brief Returns the number of epoch in the epochsWave for the given channel
/// @param[in] panelTitle title of device panel
/// @param[in] channel    number of DA channel
/// @return number of epochs for channel
static Function DC_GetEpochCount(panelTitle, channel)
	string panelTitle
	variable channel

	WAVE/T epochWave = GetEpochsWave(panelTitle)
	FindValue/Z/RMD=[][][channel]/TXOP=4/TEXT="" epochWave
	return V_row == -1 ? DimSize(epochWave, ROWS) : V_row
End

/// @brief Adds a epoch to the epochsWave
/// @param[in] panelTitle title of device panel
/// @param[in] channel    number of DA channel
/// @param[in] epBegin    start time of the epoch in micro seconds
/// @param[in] epEnd      end time of the epoch in micro seconds
/// @param[in] epName     name of the epoch
/// @param[in] level      level of epoch
/// @param[in] lowerlimit [optional, default = -Inf] epBegin is limited between lowerlimit and Inf, epEnd must be > this limit
/// @param[in] upperlimit [optional, default = Inf] epEnd is limited between -Inf and upperlimit, epBegin must be < this limit
static Function DC_AddEpoch(panelTitle, channel, epBegin, epEnd, epName, level[, lowerlimit, upperlimit])
	string panelTitle
	variable channel
	variable epBegin, epEnd
	string epName
	variable level
	variable lowerlimit, upperlimit

	WAVE/T epochWave = GetEpochsWave(panelTitle)
	variable i, j, numEpochs, pos
	string entry, startTimeStr, endTimeStr

	lowerlimit = ParamIsDefault(lowerlimit) ? -Inf : lowerlimit
	upperlimit = ParamIsDefault(upperlimit) ? Inf : upperlimit

	ASSERT(!isNull(epName), "Epoch name is null")
	ASSERT(!isEmpty(epName), "Epoch name is empty")
	ASSERT(epBegin <= epEnd, "Epoch end is < epoch begin")
	ASSERT(epBegin < upperlimit, "Epoch begin is greater than upper limit")
	ASSERT(epEnd > lowerlimit, "Epoch end lesser than lower limit")

	epBegin = limit(epBegin, lowerlimit, Inf)
	epEnd = limit(epEnd, -Inf, upperlimit)

	i = DC_GetEpochCount(panelTitle, channel)
	EnsureLargeEnoughWave(epochWave, minimumSize = i + 1, dimension = ROWS)

	startTimeStr = num2strHighPrec(epBegin / 1E6, precision = EPOCHTIME_PRECISION)
	endTimeStr = num2strHighPrec(epEnd / 1E6, precision = EPOCHTIME_PRECISION)

	if(!cmpstr(startTimeStr, endTimeStr))
		// don't add single point epochs
		return NaN
	endif

	epochWave[i][%StartTime][channel] = startTimeStr
	epochWave[i][%EndTime][channel] = endTimeStr
	epochWave[i][%Name][channel] = epName
	epochWave[i][%TreeLevel][channel] = num2str(level)
End
