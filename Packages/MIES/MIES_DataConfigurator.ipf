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
static Function DC_UpdateGlobals(string device, variable dataAcqOrTP)

	// we need to update the list of analysis functions here as the stimset
	// can change due to indexing, etc.
	// @todo investigate if this is really required here
	AFM_UpdateAnalysisFunctionWave(device)

	TP_UpdateTPSettingsCalculated(device)

	KillOrMoveToTrash(wv=GetTPSettingsLabnotebook(device))
	KillOrMoveToTrash(wv=GetTPSettingsLabnotebookKeyWave(device))

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		TP_UpdateTPLBNSettings(device)
	endif

	SVAR runningDevice = $GetRunningSingleDevice()
	runningDevice = device

	NVAR fifoPosition = $GetFifoPosition(device)
	fifoPosition = 0
End

/// @brief Prepare test pulse/data acquisition
///
/// @param device  panel title
/// @param dataAcqOrTP one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param multiDevice [optional: defaults to false] Fine tune data handling for single device (false) or multi device (true)
///
/// @exception Abort configuration failure
Function DC_Configure(device, dataAcqOrTP, [multiDevice])
	string device
	variable dataAcqOrTP, multiDevice

	variable numActiveChannels
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

	// prevent crash in ITC XOP as it must not run if we resize the DAQDataWave
	NVAR deviceID = $GetDAQDeviceID(device)
	variable hardwareType = GetHardwareType(device)
	ASSERT(!HW_IsRunning(hardwareType, deviceID, flags=HARDWARE_ABORT_ON_ERROR), "Hardware is still running and it shouldn't. Please report that as a bug.")

	KillOrMoveToTrash(wv=GetSweepSettingsWave(device))
	KillOrMoveToTrash(wv=GetSweepSettingsTextWave(device))
	KillOrMoveToTrash(wv=GetSweepSettingsKeyWave(device))
	KillOrMoveToTrash(wv=GetSweepSettingsTextKeyWave(device))

	EP_ClearEpochs(device)

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		if(AFM_CallAnalysisFunctions(device, PRE_SET_EVENT))
			Abort
		endif

		if(AS_HandlePossibleTransition(device, AS_PRE_SWEEP_CONFIG))
			Abort
		endif
	endif

	DC_UpdateGlobals(device, dataAcqOrTP)

	numActiveChannels = DC_ChannelCalcForDAQConfigWave(device, dataAcqOrTP)
	DC_MakeDAQConfigWave(device, numActiveChannels)

	DC_PlaceDataInDAQConfigWave(device, dataAcqOrTP)

	TP_CreateTestPulseWave(device, dataAcqOrTP)

	DC_PlaceDataInDAQDataWave(device, numActiveChannels, dataAcqOrTP, multiDevice)

	WAVE DAQConfigWave = GetDAQConfigWave(device)
	WAVE ADCs = GetADCListFromConfig(DAQConfigWave)
	DC_UpdateHSProperties(device, ADCs)

	NVAR ADChannelToMonitor = $GetADChannelToMonitor(device)
	WAVE DACs = GetDACListFromConfig(DAQConfigWave)
	ADChannelToMonitor = DimSize(DACs, ROWS)

	KillOrMoveToTrash(wv = GetTPResultsBuffer(device))

	DC_MakeHelperWaves(device, dataAcqOrTP)
	SCOPE_CreateGraph(device, dataAcqOrTP)

	WAVE DAQDataWave = GetDAQDataWave(device, dataAcqOrTP)
	WAVE DAQConfigWave = GetDAQConfigWave(device)

	ASSERT(IsValidSweepAndConfig(DAQDataWave, DAQConfigWave), "Invalid sweep and config combination")

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		AS_HandlePossibleTransition(device, AS_PRE_SWEEP)
	endif
End

static Function DC_UpdateHSProperties(device, ADCs)
	string device
	WAVE ADCs

	variable i, numChannels, headStage

	WAVE hsProp = GetHSProperties(device)

	hsProp = NaN
	hsProp[][%Enabled] = 0

	numChannels = DimSize(ADCs, ROWS)
	for(i = 0; i < numChannels; i += 1)
		headstage = AFH_GetHeadstageFromADC(device, ADCs[i])

		if(!IsFinite(headstage))
			continue
		endif

		hsProp[headStage][%Enabled]   = 1
		hsProp[headStage][%ADC]       = ADCs[i]
		hsProp[headStage][%DAC]       = AFH_GetDACFromHeadstage(device, headstage)
		hsProp[headStage][%ClampMode] = DAG_GetHeadstageMode(device, headStage)

	endfor
End

/// @brief Return the number of selected checkboxes for the given type
static Function DC_NoOfChannelsSelected(device, type)
	string device
	variable type

	WAVE channelState = DAG_GetChannelState(device, type)

	return sum(channelState)
End

/// @brief Returns the total number of combined channel types (DA, AD, and front TTLs) selected in the DA_Ephys Gui
///
/// @param device  panel title
/// @param dataAcqOrTP acquisition mode, one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_ChannelCalcForDAQConfigWave(device, dataAcqOrTP)
	string device
	variable dataAcqOrTP

	variable numDACs, numADCs, numTTLsRackZero, numTTLsRackOne, numActiveHeadstages
	variable numTTLs

	variable hardwareType = GetHardwareType(device)
	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			if(dataAcqOrTP == DATA_ACQUISITION_MODE)
				numDACs         = DC_NoOfChannelsSelected(device, CHANNEL_TYPE_DAC)
				numADCs         = DC_NoOfChannelsSelected(device, CHANNEL_TYPE_ADC)
				numTTLsRackZero = DC_AreTTLsInRackChecked(device, RACK_ZERO)
				numTTLsRackOne  = DC_AreTTLsInRackChecked(device, RACK_ONE)
			elseif(dataAcqOrTP == TEST_PULSE_MODE)
				numActiveHeadstages = DC_NoOfChannelsSelected(device, CHANNEL_TYPE_HEADSTAGE)
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
				numDACs = DC_NoOfChannelsSelected(device, CHANNEL_TYPE_DAC)
				numADCs = DC_NoOfChannelsSelected(device, CHANNEL_TYPE_ADC)
				numTTLs = DC_NoOfChannelsSelected(device, CHANNEL_TYPE_TTL)
			elseif(dataAcqOrTP == TEST_PULSE_MODE)
				numActiveHeadstages = DC_NoOfChannelsSelected(device, CHANNEL_TYPE_HEADSTAGE)
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
/// @param device  device
/// @param rackNo      Only the ITC1600 can have two racks. For all other ITC devices RackNo = 0.
static Function DC_AreTTLsInRackChecked(device, rackNo)
	string device
	variable rackNo

	variable first, last

	HW_ITC_GetRackRange(rackNo, first, last)
	WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)

	return Sum(statusTTL, first, last) > 0
End

/// @brief Returns the number of points in the longest stimset
///
/// @param device  device
/// @param dataAcqOrTP acquisition mode, one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param channelType channel type, one of @ref ChannelTypeAndControlConstants
static Function DC_LongestOutputWave(device, dataAcqOrTP, channelType)
	string device
	variable dataAcqOrTP, channelType

	variable maxNumRows, i, numEntries, numPulses, singlePulseLength

	WAVE statusFiltered = DC_GetFilteredChannelState(device, dataAcqOrTP, channelType)
	WAVE/T stimsets     = DAG_GetChannelTextual(device, channelType, CHANNEL_CONTROL_WAVE)

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
		   && GetHardwareType(device) == HARDWARE_ITC_DAC         \
		   && DAG_GetNumericalValue(device, "check_Settings_MD"))
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
/// @param device  panel title
/// @param dataAcqOrTP acquisition mode, one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_CalculateDAQDataWaveLength(string device, variable dataAcqOrTP)
	variable hardwareType = GetHardwareType(device)
	NVAR stopCollectionPoint = $GetStopCollectionPoint(device)

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
/// @param device  panel title
/// @param numActiveChannels number of active channels as returned by DC_ChannelCalcForDAQConfigWave()
static Function DC_MakeDAQConfigWave(device, numActiveChannels)
	string device
	variable numActiveChannels

	WAVE config = GetDAQConfigWave(device)

	Redimension/N=(numActiveChannels, -1) config
	FastOp config = 0

	ASSERT(IsValidConfigWave(config), "Invalid config wave")
End

/// @brief Creates DAQDataWave; The wave that the device takes DA and TTL data from and passes AD data to for all channels.
///
/// Config all refers to configuring all the channels at once
///
/// @param device      panel title
/// @param s           DataConfigurationResult structure
/// @param dataAcqOrTP one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function [WAVE/Z DAQDataWave, WAVE/WAVE NIDataWave] DC_MakeAndGetDAQDataWave(string device, STRUCT DataConfigurationResult &s, variable dataAcqOrTP)
	variable numRows, i

	switch(s.hardwareType)
		case HARDWARE_ITC_DAC:
			numRows = DC_CalculateDAQDataWaveLength(device, dataAcqOrTP)
			WAVE ITCDataWave = GetDAQDataWave(device, dataAcqOrTP)

			Redimension/N=(numRows, s.numActiveChannels) ITCDataWave

			FastOp ITCDataWave = 0
			SetScale/P x, 0, s.samplingInterval * MICRO_TO_MILLI, "ms", ITCDataWave

			return [ITCDataWave, $""]
		case HARDWARE_NI_DAC:
			WAVE/WAVE NIDataWave = GetDAQDataWave(device, dataAcqOrTP)
			Redimension/N=(s.numActiveChannels) NIDataWave

			Make/FREE/N=(s.numActiveChannels) type = SWS_GetRawDataFPType(device)
			WAVE config = GetDAQConfigWave(device)
			type = config[p][%ChannelType] == XOP_CHANNEL_TYPE_TTL ? IGOR_TYPE_UNSIGNED | IGOR_TYPE_8BIT_INT : type[p]
			NIDataWave = DC_MakeNIChannelWave(device, dataAcqOrTP, config[p][%ChannelType], config[p][%SamplingInterval], p, type[p])
			NIDataWave = DC_SetDataScaleNIChannelWave(NIDataWave[p], config[p][%ChannelType])

			return [$"", NIDataWave]
		default:
			ASSERT(0, "Unsupported hardware type")
	endswitch
End

/// @brief set a data scale for channel waves, this is not required for operation but allows to keep track of the scales
///        The waves for the hardware that output data and read back data are typically in V because any other unit, like pA in current clamp mode on DAC channels
///        is converted by the gain from pA to voltage and then by the hardware amplifier converted back from V to pA.
static Function/WAVE DC_SetDataScaleNIChannelWave(WAVE channel, variable type)

	switch(type)
		case XOP_CHANNEL_TYPE_DAC:
			SetScale d, 0, 0, "V", channel
			break
		case XOP_CHANNEL_TYPE_ADC:
			SetScale d, 0, 0, "V", channel
			break
		case XOP_CHANNEL_TYPE_TTL:
			break
		default:
			ASSERT(0, "Unknown channel type")
	endswitch

	return channel
End

/// @brief Creates a single NIChannel wave
///
/// Config all refers to configuring all the channels at once
///
/// @param device           panel title
/// @param dataAcqOrTP      one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param channelType      channel type, one of @sa XopChannelConstants
/// @param samplingInterval minimum sample intervall in microseconds
/// @param index            number of NI channel
/// @param dataType         numeric data type of NI channel
///
/// @return                 Wave Reference to NI Channel wave
static Function/WAVE DC_MakeNIChannelWave(string device, variable dataAcqOrTP, variable channelType, variable samplingInterval, variable index, variable dataType)

	variable numRows = DC_CalculateDAQDataWaveLength(device, dataAcqOrTP)

	WAVE channel = GetNIDAQChannelWave(device, index, dataAcqOrTP)
	Redimension/N=(numRows)/Y=(dataType) channel
	// @todo test
	switch(channelType)
		case XOP_CHANNEL_TYPE_DAC:
		case XOP_CHANNEL_TYPE_TTL: // intended drop through
			FastOp channel = 0
			break
		case XOP_CHANNEL_TYPE_ADC:
			FastOp channel = (NaN)
			break
		default:
			ASSERT(0, "Unsupported channel type")
	endswitch
	SetScale/P x, 0, samplingInterval * MICRO_TO_MILLI, "ms", channel

	return channel
End

/// @brief Initializes the waves used for displaying DAQ/TP results in the
/// oscilloscope window and the scaled data wave
///
/// @param device        panel title
/// @param dataAcqOrTP   one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_MakeHelperWaves(string device, variable dataAcqOrTP)
	variable numRows, col, hardwareType, decimatedNumRows, numPixels, dataPointsPerPixel
	variable decMethod, decFactor, tpLength, numADCs, numDACs, numTTLs, decimatedSampleInterval
	variable tpOrPowerSpectrumLength, powerSpectrum
	variable sampleIntervalADC, pointsAcq

	WAVE config = GetDAQConfigWave(device)
	WAVE OscilloscopeData = GetOscilloscopeWave(device)
	WAVE TPOscilloscopeData = GetTPOscilloscopeWave(device)
	WAVE TPSettingsCalc = GetTPSettingsCalculated(device)

	hardwareType = GetHardwareType(device)

	WAVE ADCs = GetADCListFromConfig(config)
	numADCs = DimSize(ADCs, ROWS)
	WAVE DACs = GetDACListFromConfig(config)
	numDACs = DimSize(DACs, ROWS)
	WAVE TTLs = GetTTLListFromConfig(config)
	numTTLs = DimSize(TTLs, ROWS)

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			WAVE ITCDataWave = GetDAQDataWave(device, dataAcqOrTP)
			sampleIntervalADC = DimDelta(ITCDataWave, ROWS)
			break
		case HARDWARE_NI_DAC:
			WAVE/WAVE NIDataWave = GetDAQDataWave(device, dataAcqOrTP)
			sampleIntervalADC = DimDelta(NIDataWave[numDACs], ROWS)
			break
	endswitch

	tpLength      = dataAcqOrTP == DATA_ACQUISITION_MODE ? TPSettingsCalc[%totalLengthPointsDAQ_ADC] : TPSettingsCalc[%totalLengthPointsTP_ADC]
	powerSpectrum = DAG_GetNumericalValue(device, "check_settings_show_power")
	if(powerSpectrum)
		// see DisplayHelpTopic `FFT` for the explanation of the calculation
		tpOrPowerSpectrumLength = floor(TP_GetPowerSpectrumLength(tpLength) / 2) + 1
		if(dataAcqOrTP == DATA_ACQUISITION_MODE)
			WAVE tpOsciForPowerSpectrum = GetScaledTPTempWave(device)
			Redimension/N=(tpLength, numDACs + numADCs) tpOsciForPowerSpectrum
		endif
	else
		tpOrPowerSpectrumLength = tpLength
	endif

	if(dataAcqOrTP == TEST_PULSE_MODE)

		numRows = tpLength

		decMethod = DECIMATION_NONE
		decFactor = NaN

		decimatedNumRows        = numRows
		decimatedSampleInterval = sampleIntervalADC

	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)

		switch(hardwareType)
			case HARDWARE_ITC_DAC:
				numRows = DimSize(ITCDataWave, ROWS)
				pointsAcq = ROVar(GetStopCollectionPoint(device))
				break
			case HARDWARE_NI_DAC:
				numRows = DimSize(NIDataWave[numDACs], ROWS)
				pointsAcq = numRows
				break
		endswitch

		decMethod = DAG_GetNumericalValue(device, "Popup_Settings_DecMethod")
		decFactor = DEFAULT_DECIMATION_FACTOR

		switch(decMethod)
			case DECIMATION_NONE:
				decFactor = 1
				decimatedNumRows = numRows
				decimatedSampleInterval = sampleIntervalADC
				break
			default:
				STRUCT RectD s
				GetPlotArea(SCOPE_GetGraph(device), s)

				// use twice as many pixels as we need
				// but round to a power of two
				numPixels = s.right - s.left
				dataPointsPerPixel = trunc((pointsAcq / (numPixels * 2)))
				if(dataPointsPerPixel > 2)
					decFactor = 2^FindPreviousPower(dataPointsPerPixel, 2)
					decimatedNumRows = GetDecimatedWaveSize(numRows, decFactor, decMethod)
					decimatedSampleInterval = sampleIntervalADC * decFactor
				else
					// turn off decimation for very short stimsets
					decMethod = DECIMATION_NONE
					decFactor = 1
					decimatedNumRows = numRows
					decimatedSampleInterval = sampleIntervalADC
				endif
				break
		endswitch
	else
		ASSERT(0, "Invalid dataAcqOrTP")
	endif

	SetNumberInWaveNote(OscilloscopeData, "DecimationMethod", decMethod)
	SetNumberInWaveNote(OscilloscopeData, "DecimationFactor", decFactor)

	DC_InitOscilloscopeDataWave(TPOscilloscopeData, tpOrPowerSpectrumLength, sampleIntervalADC, numDACs, numADCs, numTTLs, isFourierTransform=powerSpectrum)
	DC_InitOscilloscopeDataWave(OscilloscopeData, decimatedNumRows, decimatedSampleInterval, numDACs, numADCs, numTTLs)

	DC_InitScaledDataWave(device, dataAcqOrTP)
End

/// @brief Returns the size of a channel for scaledData wave creation. The DAQDataWave must already be existing at this point.
///        channelIndex must be given for non-ITC hardware in DATA_ACQUISITION_MODE
static Function DC_CalculateChannelSizeForScaledData(string device, variable dataAcqOrTP, [variable channelIndex])

	variable hardwareType

	WAVE TPSettingsCalc = GetTPSettingsCalculated(device)
	hardwareType = GetHardwareType(device)
	if(hardwareType != HARDWARE_ITC_DAC && dataAcqOrTP == DATA_ACQUISITION_MODE)
		ASSERT(!ParamIsDefault(channelIndex), "Require channelIndex to be specified")
	endif

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			return dataAcqOrTP == DATA_ACQUISITION_MODE ? ROVar(GetStopCollectionPoint(device)) : TPSettingsCalc[%totalLengthPointsTP_ADC]
		case HARDWARE_NI_DAC:
			if(dataAcqOrTP == DATA_ACQUISITION_MODE)
				WAVE/WAVE dataWave = GetDAQDataWave(device, dataAcqOrTP)
				ASSERT(channelIndex >= 0 && channelIndex < DimSize(dataWave, ROWS), "ChannelIndex out of range")
				return DimSize(dataWave[channelIndex], ROWS)
			endif

			return TPSettingsCalc[%totalLengthPointsTP_ADC]
		default:
			ASSERT(0, "Unknown hardware type")
	endswitch
End

/// @brief Initialize scaledDataWave, as NI output already properly scaled data, we can prefill output channels.
///        So in in the more time critical SCOPE_xx_UpdateOscilloscope we can optimize by only copying the ADC data over (ADC data from NI is already properly scaled by hardware)
static Function DC_InitScaledDataWave(string device, variable dataAcqOrTP)

	variable i, numChannels, dataType, size, sampleIntervalADC, hardwareType

	WAVE/WAVE scaledDataWave = GetScaledDataWave(device)
	WAVE config = GetDAQConfigWave(device)
	WAVE/T units = AFH_GetChannelUnits(config)
	dataType = SWS_GetRawDataFPType(device)
	hardwareType = GetHardwareType(device)

	WAVE gains = SWS_GetChannelGains(device, timing = GAIN_BEFORE_DAQ)

	if(hardwareType == HARDWARE_ITC_DAC)
		size = DC_CalculateChannelSizeForScaledData(device, dataAcqOrTP)
		WAVE ITCDataWave = GetDAQDataWave(device, dataAcqOrTP)
		sampleIntervalADC = DimDelta(ITCDataWave, ROWS)
	else
		WAVE/WAVE dataWave = GetDAQDataWave(device, dataAcqOrTP)
	endif

	numChannels = DimSize(config, ROWS)
	Redimension/N=(numChannels) scaledDataWave
	for(i = 0; i < numChannels; i += 1)

		if(hardwareType != HARDWARE_ITC_DAC)
			WAVE channel = dataWave[i]
			size = DC_CalculateChannelSizeForScaledData(device, dataAcqOrTP, channelIndex = i)
			if(hardwareType == HARDWARE_NI_DAC)
				sampleIntervalADC = DimDelta(channel, ROWS)
			endif
		endif

		Make/FREE/Y=(dataType)/N=(size) wv
		if(config[i][%ChannelType] == XOP_CHANNEL_TYPE_DAC || config[i][%ChannelType] == XOP_CHANNEL_TYPE_TTL)
			if(hardwareType == HARDWARE_ITC_DAC)
				Multithread wv[] = ITCDataWave[p][i] / gains[i]
			else
				Multithread wv[] = channel[p] / gains[i]
			endif
		else
			FastOp wv = (NaN)
		endif

		SetScale/P x, 0, sampleIntervalADC, "ms", wv

		if(i < DimSize(units, ROWS))
			SetScale d, 0, 0, units[i], wv
		endif
		scaledDataWave[i] = wv
	endfor
End

/// @brief Initialize OscilloscopeData waves to NaN
static Function DC_InitOscilloscopeDataWave(wv, numRows, sampleInterval, numDACs, numADCs, numTTLs, [type, isFourierTransform])
	WAVE wv
	variable numRows, sampleInterval, numDACs, numADCs, numTTLs, type, isFourierTransform
	string msg

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

	if(GetLockState(wv))
		sprintf msg, "Clearing leftover lock in %s from earlier acquisition runs.\r", GetWavesDataFolder(wv, 2)
		BUG(msg)
		ChangeWaveLock(wv, 0)
	endif

	Redimension/N=(numRows, numDACs + numADCs + numTTLs)/Y=(type) wv

	if(isFourierTransform)
		SetScale/I x, 0, 1 / (2 * (sampleInterval * MICRO_TO_MILLI)), "Hz", wv
	else
		SetScale/P x, 0, sampleInterval, "ms", wv
	endif

	ASSERT(IsFloatingPointWave(wv), "Wave is not of floating point type")

	MultiThread wv[][] = NaN
End

/// @brief Return the list of active channels, filtered for various special cases
///
/// @param device     panel title
/// @param dataAcqOrTP    one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param channelType    one of the channel type constants from @ref ChannelTypeAndControlConstants
/// @param DAQChannelType only return channels as active if they have the desired DAQChannel type (only respected for DA channel)
Function/WAVE DC_GetFilteredChannelState(device, dataAcqOrTP, channelType, [DAQChannelType])
	string device
	variable dataAcqOrTP, channelType, DAQChannelType

	if(ParamIsDefault(DAQChannelType))
		DAQChannelType = DAQ_CHANNEL_TYPE_UNKOWN
	endif

	ASSERT(DAQChannelType == DAQ_CHANNEL_TYPE_UNKOWN || DAQChannelType == DAQ_CHANNEL_TYPE_DAQ || DAQChannelType == DAQ_CHANNEL_TYPE_TP, "Invalid DAQChannelType")

	WAVE statusChannel = DAG_GetChannelState(device, channelType)

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

				WAVE/T allSetNames = DAG_GetChannelTextual(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)

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
			Make/FREE/N=(NUM_AD_CHANNELS) result = AFH_GetHeadstageFromADC(device, p)
			break
		case CHANNEL_TYPE_DAC:
			Make/FREE/N=(NUM_DA_TTL_CHANNELS) result = AFH_GetHeadstageFromDAC(device, p)
			break
		default:
			ASSERT(0, "unhandled case")
			break
	endswitch

	WAVE statusHS = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	result[] = IsFinite(result[p]) && statusHS[result[p]]

	return result
End

/// @brief Places channel (DA, AD, and TTL) settings data into DAQConfigWave
///
/// @param device  panel title
/// @param dataAcqOrTP one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_PlaceDataInDAQConfigWave(device, dataAcqOrTP)
	string device
	variable dataAcqOrTP

	variable i, j, numEntries, ret, channel
	variable col, adc, dac, headstage
	string ctrl, deviceType, deviceNumber
	string unitList = ""

	WAVE DAQConfigWave = GetDAQConfigWave(device)

	// query DA properties
	WAVE statusDAFiltered = DC_GetFilteredChannelState(device, dataAcqOrTP, CHANNEL_TYPE_DAC)
	WAVE/T allSetNames    = DAG_GetChannelTextual(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	ctrl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
	DAQConfigWave[][%HEADSTAGE] = NaN
	DAQConfigWave[][%CLAMPMODE] = NaN

	numEntries = DimSize(statusDAFiltered, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!statusDAFiltered[i])
			continue
		endif

		DAQConfigWave[j][%ChannelType]   = XOP_CHANNEL_TYPE_DAC
		DAQConfigWave[j][%ChannelNumber] = i
		unitList = AddListItem(DAG_GetTextualValue(device, ctrl, index = i), unitList, ",", Inf)
		DAQConfigWave[j][%DAQChannelType] = !CmpStr(allSetNames[i], STIMSET_TP_WHILE_DAQ, 1) || dataAcqOrTP == TEST_PULSE_MODE ? DAQ_CHANNEL_TYPE_TP : DAQ_CHANNEL_TYPE_DAQ
		headstage = AFH_GetHeadstageFromDAC(device, i)
		DAQConfigWave[j][%HEADSTAGE] = headstage
		if(IsFinite(headstage))
			DAQConfigWave[j][%CLAMPMODE] = DAG_GetHeadstageMode(device, headstage)
		endif

		j += 1
	endfor

	// query AD properties
	WAVE statusADFiltered = DC_GetFilteredChannelState(device, dataAcqOrTP, CHANNEL_TYPE_ADC)

	ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)

	numEntries = DimSize(statusADFiltered, ROWS)
	for(i = 0; i < numEntries; i += 1)

		if(!statusADFiltered[i])
			continue
		endif

		DAQConfigWave[j][%ChannelType]   = XOP_CHANNEL_TYPE_ADC
		DAQConfigWave[j][%ChannelNumber] = i
		unitList = AddListItem(DAG_GetTextualValue(device, ctrl, index = i), unitList, ",", Inf)

		headstage = AFH_GetHeadstageFromADC(device, i)

		if(IsFinite(headstage))
			// use the same channel type as the DAC
			DAQConfigWave[j][%DAQChannelType] = DC_GetChannelTypefromHS(device, headstage)
			DAQConfigWave[j][%HEADSTAGE] = headstage
			DAQConfigWave[j][%CLAMPMODE] = DAG_GetHeadstageMode(device, headstage)
		else
			// unassociated ADCs are always of DAQ type
			DAQConfigWave[j][%DAQChannelType] = DAQ_CHANNEL_TYPE_DAQ
		endif

		j += 1
	endfor

	AddEntryIntoWaveNoteAsList(DAQConfigWave, CHANNEL_UNIT_KEY, str = unitList, replaceEntry = 1)

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		variable hardwareType = GetHardwareType(device)
		switch(hardwareType)
			case HARDWARE_ITC_DAC:
				if(DC_AreTTLsInRackChecked(device, RACK_ZERO))
					DAQConfigWave[j][%ChannelType] = XOP_CHANNEL_TYPE_TTL

					channel = HW_ITC_GetITCXOPChannelForRack(device, RACK_ZERO)
					DAQConfigWave[j][%ChannelNumber] = channel
					DC_DocumentChannelProperty(device, "rack zero channel", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, var=channel)
					DAQConfigWave[j][%DAQChannelType] = DAQ_CHANNEL_TYPE_DAQ

					j += 1
				endif

				if(DC_AreTTLsInRackChecked(device, RACK_ONE))
					DAQConfigWave[j][%ChannelType] = XOP_CHANNEL_TYPE_TTL

					channel = HW_ITC_GetITCXOPChannelForRack(device, RACK_ONE)
					DAQConfigWave[j][%ChannelNumber] = channel
					DC_DocumentChannelProperty(device, "rack one channel", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, var=channel)
					DAQConfigWave[j][%DAQChannelType] = DAQ_CHANNEL_TYPE_DAQ
				endif
				break
			case HARDWARE_NI_DAC:
				WAVE statusTTL = DAG_GetChannelState(device, CHANNEL_TYPE_TTL)
				numEntries = DimSize(statusTTL, ROWS)
				for(i = 0; i < numEntries; i += 1)
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

	DAQConfigWave[][%SamplingInterval] = DAP_GetSampInt(device, dataAcqOrTP, DAQConfigWave[p][%ChannelType])
	DAQConfigWave[][%DecimationMode]   = 0
	DAQConfigWave[][%Offset]           = 0
End

/// @brief Get the decimation factor for the current channel configuration
///
/// This is the factor between the minimum sampling interval and the real.
/// If the multiplier is taken into account depends on `dataAcqOrTP`.
///
/// @param device  device
/// @param dataAcqOrTP one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
static Function DC_GetDecimationFactor(string device, variable dataAcqOrTP)

	variable samplingInterval = DAP_GetSampInt(device, dataAcqOrTP, XOP_CHANNEL_TYPE_DAC)

	return DC_GetDecimationFactorCalc(samplingInterval)
End

/// @brief Calculcate decimation factor device independent
/// @param samplingInterval sampling interval in microseconds
static Function DC_GetDecimationFactorCalc(variable samplingInterval)

	return samplingInterval / (WAVEBUILDER_MIN_SAMPINT * MILLI_TO_MICRO)
End

/// @brief Returns the longest sweep in a stimulus set across the given channel type
///
/// @param device  device
/// @param dataAcqOrTP mode, either #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param channelType One of @ref ChannelTypeAndControlConstants
///
/// @return number of data points, *not* time
static Function DC_CalculateLongestSweep(device, dataAcqOrTP, channelType)
	string device
	variable dataAcqOrTP
	variable channelType

	return DC_CalculateGeneratedDataSize(device, dataAcqOrTP, DC_LongestOutputWave(device, dataAcqOrTP, channelType))
End

/// @brief Get the stimset length for the real sampling interval
///
/// @param stimSet          stimset wave
/// @param device 		 device
/// @param dataAcqOrTP      one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
Function DC_CalculateStimsetLength(stimSet, device, dataAcqOrTP)
	WAVE stimSet
	string device
	variable dataAcqOrTP

	return DC_CalculateGeneratedDataSize(device, dataAcqOrTP, DimSize(stimSet, ROWS))
End

/// @brief Get the length for the real sampling interval from a generated wave with length
///
/// @param device 		 device
/// @param dataAcqOrTP      one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param genLength        length of a generated data wave
static Function DC_CalculateGeneratedDataSize(device, dataAcqOrTP, genLength)
	string device
	variable dataAcqOrTP, genLength

	variable decimationFactor = DC_GetDecimationFactor(device, dataAcqOrTP)

	// note: the decimationFactor is the factor between the hardware sample rate and the sample rate of the generated waveform in singleStimSet
	// The ratio of the source to target wave sizes is however limited by the integer size of both waves
	// While ideally srcLength == tgtLength the floor(...) limits the real data wave length such that
	// when decimationFactor * index of real data wave is applied as index of the generated data wave it never exceeds its size
	// Also if decimationFactor >= 2 the last point of the generated data wave is never transferred
	// e.g. generated data with 10 points and decimationFactor == 2 copies index 0, 2, 4, 6, 8 to the real data wave of size 5
	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		return floor(genLength / decimationFactor) + IndexAfterDecimation(0, decimationFactor)
	elseif(dataAcqOrTP == TEST_PULSE_MODE)
		return genLength
	else
		ASSERT(0, "unhandled case")
	endif
End

/// @brief Places data from appropriate DA and TTL stimulus set(s) into DAQDataWave.
/// Also records certain DA_Ephys GUI settings into sweepDataLNB and sweepDataTxTLNB
/// @param device        panel title
/// @param numActiveChannels number of active channels as returned by DC_ChannelCalcForDAQConfigWave()
/// @param dataAcqOrTP       one of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param multiDevice       Fine tune data handling for single device (false) or multi device (true)
///
/// @exception Abort configuration failure
static Function DC_PlaceDataInDAQDataWave(device, numActiveChannels, dataAcqOrTP, multiDevice)
	string device
	variable numActiveChannels, dataAcqOrTP, multiDevice

	variable ret, row, column

	WAVE/T epochWave = GetEpochsWave(device)

	STRUCT DataConfigurationResult s
	[s] = DC_GetConfiguration(device, numActiveChannels, dataAcqOrTP, multiDevice)

	NVAR stopCollectionPoint = $GetStopCollectionPoint(device)
	stopCollectionPoint = DC_GetStopCollectionPoint(device, s)
	s.stopCollectionPoint = stopCollectionPoint

	AssertOnAndClearRTError()

	if(dataAcqOrTP == TEST_PULSE_MODE)
		DC_FillDAQDataWaveForTP(device, s)
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)
		DC_FillDAQDataWaveForDAQ(device, s)
	endif

	EP_CollectEpochInfo(epochWave, s)
	DC_PrepareLBNEntries(device, s)

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		DC_WriteTTLIntoDAQDataWave(device, s)
		DC_FillSetEventFlag(device, s)
	endif

	[ret, row, column] = DC_CheckIfDataWaveHasBorderVals(device, dataAcqOrTP)

	if(ret)
		printf "Error writing into DataWave in %s mode: The values at [%g, %g] are out of range. Maybe the DA/AD Gain needs adjustment?\r", SelectString(dataAcqOrTP, "DATA_ACQUISITION", "TestPulse"), row, column
		ControlWindowToFront()
		Abort
	endif
End

static Function DC_MakeTTLWave(string device, STRUCT DataConfigurationResult &s)

	if(s.numTTLEntries == 0)
		return NaN
	endif

	switch(s.hardwareType)
		case HARDWARE_NI_DAC:
			DC_NI_MakeTTLWave(device, s)
			break
		case HARDWARE_ITC_DAC:
			DC_ITC_MakeTTLWave(device, s)
			break
		default:
			ASSERT(0, "Unsupported hardware type specified")
	endswitch
End

static Function DC_WriteTTLIntoDAQDataWave(string device, STRUCT DataConfigurationResult &s)

	variable i, startOffset, ttlOffset, singleSetLength, bitMask
	variable ITCRackZeroChecked

	if(s.numTTLEntries == 0)
		return NaN
	endif

	// reset to the default value without distributedDAQ
	startOffset = s.onSetDelay
	ttlOffset = s.numDACEntries + s.numADCEntries

	WAVE config = GetDAQConfigWave(device)

	switch(s.hardwareType)
		case HARDWARE_NI_DAC:
			WAVE/WAVE NIDataWave = GetDAQDataWave(device, s.dataAcqOrTP)
			WAVE/WAVE TTLWaveNI = GetTTLWave(device)

			for(i = 0; i < s.numTTLEntries; i += 1)
				WAVE TTLWaveSingle = TTLWaveNI[config[i + ttlOffset][%ChannelNumber]]
				singleSetLength = DC_CalculateStimsetLength(TTLWaveSingle, device, DATA_ACQUISITION_MODE)
				WAVE NIChannel = NIDataWave[i + ttlOffset]
				MultiThread NIChannel[startOffset, startOffset + singleSetLength - 1] = \
				limit(TTLWaveSingle[round(s.decimationFactor * (p - startOffset))], 0, 1); AbortOnRTE
			endfor
			break
		case HARDWARE_ITC_DAC:
			WAVE ITCDataWave = GetDAQDataWave(device, s.dataAcqOrTP)
			WAVE TTLWaveITC = GetTTLWave(device)
			singleSetLength = DC_CalculateStimsetLength(TTLWaveITC, device, DATA_ACQUISITION_MODE)

			// Place TTL waves into ITCDataWave
			ITCRackZeroChecked = !!DC_AreTTLsInRackChecked(device, RACK_ZERO)
			bitMask = 1 << NUM_ITC_TTL_BITS_PER_RACK - 1
			if(ITCRackZeroChecked)
				MultiThread ITCDataWave[startOffset, startOffset + singleSetLength - 1][ttlOffset] = \
				limit(TTLWaveITC[round(s.decimationFactor * (p - startOffset))] & bitMask, SIGNED_INT_16BIT_MIN, SIGNED_INT_16BIT_MAX); AbortOnRTE
			endif

			if(DC_AreTTLsInRackChecked(device, RACK_ONE))
				MultiThread ITCDataWave[startOffset, startOffset + singleSetLength - 1][ttlOffset + ITCRackZeroChecked] = \
				limit(TTLWaveITC[round(s.decimationFactor * (p - startOffset))] >> NUM_ITC_TTL_BITS_PER_RACK & bitMask, SIGNED_INT_16BIT_MIN, SIGNED_INT_16BIT_MAX); AbortOnRTE
			endif
			break
	endswitch
End

static Function DC_PrepareLBNEntries(string device, STRUCT DataConfigurationResult &s)
	variable i, j, maxITI, channel, headstage, setChecksum, fingerprint, stimsetCycleID, isoodDAQMember
	string func, ctrl, str

	WAVE config = GetDAQConfigWave(device)

	WAVE/T allIndexingEndSetNames = DAG_GetChannelTextual(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_INDEX_END)
	WAVE/T cellElectrodeNames = GetCellElectrodeNames(device)
	WAVE/T analysisFunctions  = GetAnalysisFunctionStorage(device)

	NVAR raCycleID = $GetRepeatedAcquisitionCycleID(device)
	if(s.dataAcqOrTP == DATA_ACQUISITION_MODE)
		ASSERT(IsFinite(raCycleID), "Uninitialized raCycleID detected")
	endif

	DC_DocumentChannelProperty(device, RA_ACQ_CYCLE_ID_KEY, INDEP_HEADSTAGE, NaN, NaN, var=raCycleID)

	// get maximum ITI from all DACs
	for(i = 0; i < s.numDACEntries; i += 1)
		maxITI = max(maxITI, WB_GetITI(s.stimSet[i], s.setColumn[i]))
	endfor

	NVAR maxITIGlobal = $GetMaxIntertrialInterval(device)
	ASSERT(IsFinite(maxITI), "Invalid maxITI")
	maxITIGlobal = maxITI
	DC_DocumentChannelProperty(device, "Inter-trial interval", INDEP_HEADSTAGE, NaN, NaN, var=maxITIGlobal)

	// index guide:
	// - numEntries: Number of active DACs
	// - i: Zero-based index of the active DACS
	// - channel: DA channel number

	for(i = 0; i < s.numDACEntries; i += 1)
		channel = s.DACList[i]
		headstage = s.headstageDAC[i]

		if(s.dataAcqOrTP == DATA_ACQUISITION_MODE)
			DC_DocumentChannelProperty(device, "Indexing End Stimset", headstage, channel, XOP_CHANNEL_TYPE_DAC, str = allIndexingEndSetNames[channel])
		endif

		for(j = 0; j < TOTAL_NUM_EVENTS; j += 1)
			if(IsFinite(headstage)) // associated channel
				func = analysisFunctions[headstage][j]
			else
				func = ""
			endif

			DC_DocumentChannelProperty(device, StringFromList(j, EVENT_NAME_LIST_LBN), headstage, channel, XOP_CHANNEL_TYPE_DAC, str=func)
		endfor

		DC_DocumentChannelProperty(device, "DAC", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=channel)
		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_GAIN)
		DC_DocumentChannelProperty(device, "DA GAIN", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=DAG_GetNumericalValue(device, ctrl, index = channel))
		DC_DocumentChannelProperty(device, "DA ChannelType", headstage, channel, XOP_CHANNEL_TYPE_DAC, var = config[i][%DAQChannelType])

		DC_DocumentChannelProperty(device, STIM_WAVE_NAME_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, str=s.setName[i])
		DC_DocumentChannelProperty(device, STIMSET_WAVE_NOTE_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, str=NormalizeToEOL(RemoveEnding(note(s.stimSet[i]), "\r"), "\n"))

		if(IsFinite(headstage)) // associated channel
			str = analysisFunctions[headstage][ANALYSIS_FUNCTION_PARAMS]
		else
			str = ""
		endif

		DC_DocumentChannelProperty(device, ANALYSIS_FUNCTION_PARAMS_LBN, headstage, channel, XOP_CHANNEL_TYPE_DAC, str=str)

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_UNIT)
		DC_DocumentChannelProperty(device, "DA Unit", headstage, channel, XOP_CHANNEL_TYPE_DAC, str=DAG_GetTextualValue(device, ctrl, index = channel))

		DC_DocumentChannelProperty(device, STIMSET_SCALE_FACTOR_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, var = s.dataAcqOrTP == DATA_ACQUISITION_MODE && config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ ? s.DACAmp[i][%DASCALE] : s.DACAmp[i][%TPAMP])
		DC_DocumentChannelProperty(device, "Set Sweep Count", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=s.setColumn[i])
		DC_DocumentChannelProperty(device, "Electrode", headstage, channel, XOP_CHANNEL_TYPE_DAC, str=cellElectrodeNames[headstage])
		DC_DocumentChannelProperty(device, "Set Cycle Count", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=s.setCycleCount[i])

		setChecksum = WB_GetStimsetChecksum(s.stimSet[i], s.setName[i], s.dataAcqOrTP)
		DC_DocumentChannelProperty(device, "Stim Wave Checksum", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=setChecksum)

		if(s.dataAcqOrTP == DATA_ACQUISITION_MODE && config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ)
			fingerprint = DC_GenerateStimsetFingerprint(raCycleID, s.setName[i], s.setCycleCount[i], setChecksum)
			stimsetCycleID = DC_GetStimsetAcqCycleID(device, fingerprint, channel)

			DC_DocumentChannelProperty(device, STIMSET_ACQ_CYCLE_ID_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, var=stimsetCycleID)
		endif

		if(s.dataAcqOrTP == DATA_ACQUISITION_MODE)
			isoodDAQMember = (s.distributedDAQOptOv && config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ && IsFinite(headstage))
			DC_DocumentChannelProperty(device, "oodDAQ member", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=isoodDAQMember)
		endif

		DC_DocumentChannelProperty(device, "Stim set length", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=s.setLength[i])
		DC_DocumentChannelProperty(device, "Delay onset oodDAQ", headstage, channel, XOP_CHANNEL_TYPE_DAC, var=s.offsets[i])
		DC_DocumentChannelProperty(device, "oodDAQ regions", headstage, channel, XOP_CHANNEL_TYPE_DAC, str=s.regions[i])
	endfor

	DC_DocumentChannelProperty(device, "Sampling interval multiplier", INDEP_HEADSTAGE, NaN, NaN, var=str2num(DAG_GetTextualValue(device, "Popup_Settings_SampIntMult")))
	DC_DocumentChannelProperty(device, "Fixed frequency acquisition", INDEP_HEADSTAGE, NaN, NaN, var=str2numSafe(DAG_GetTextualValue(device, "Popup_Settings_FixedFreq")))
	DC_DocumentChannelProperty(device, "Sampling interval", INDEP_HEADSTAGE, NaN, NaN, var=s.samplingInterval * MICRO_TO_MILLI)

	DC_DocumentChannelProperty(device, "Delay onset user", INDEP_HEADSTAGE, NaN, NaN, var=(s.onsetDelayUser * (s.samplingInterval * MICRO_TO_MILLI)))
	DC_DocumentChannelProperty(device, "Delay onset auto", INDEP_HEADSTAGE, NaN, NaN, var=(s.onsetDelayAuto * (s.samplingInterval * MICRO_TO_MILLI)))
	DC_DocumentChannelProperty(device, "Delay termination", INDEP_HEADSTAGE, NaN, NaN, var=(s.terminationDelay * (s.samplingInterval * MICRO_TO_MILLI)))
	DC_DocumentChannelProperty(device, "Delay distributed DAQ", INDEP_HEADSTAGE, NaN, NaN, var=(s.distributedDAQDelay * (s.samplingInterval * MICRO_TO_MILLI)))
	DC_DocumentChannelProperty(device, "oodDAQ Pre Feature", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "Setvar_DataAcq_dDAQOptOvPre"))
	DC_DocumentChannelProperty(device, "oodDAQ Post Feature", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "Setvar_DataAcq_dDAQOptOvPost"))
	DC_DocumentChannelProperty(device, "oodDAQ Resolution", INDEP_HEADSTAGE, NaN, NaN, var=WAVEBUILDER_MIN_SAMPINT)

	DC_DocumentChannelProperty(device, "TP Insert Checkbox", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "Check_Settings_InsertTP"))
	DC_DocumentChannelProperty(device, "Distributed DAQ", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "Check_DataAcq1_DistribDaq"))
	DC_DocumentChannelProperty(device, "Optimized Overlap dDAQ", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "Check_DataAcq1_dDAQOptOv"))
	DC_DocumentChannelProperty(device, "Repeat Sets", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "SetVar_DataAcq_SetRepeats"))
	DC_DocumentChannelProperty(device, "Scaling zero", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device,  "check_Settings_ScalingZero"))
	DC_DocumentChannelProperty(device, "Indexing", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "Check_DataAcq_Indexing"))
	DC_DocumentChannelProperty(device, "Locked indexing", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "Check_DataAcq1_IndexingLocked"))
	DC_DocumentChannelProperty(device, "Repeated Acquisition", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "Check_DataAcq1_RepeatAcq"))
	DC_DocumentChannelProperty(device, "Random Repeated Acquisition", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "check_DataAcq_RepAcqRandom"))
	DC_DocumentChannelProperty(device, "Multi Device mode", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "check_Settings_MD"))
	DC_DocumentChannelProperty(device, "Background Testpulse", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "Check_Settings_BkgTP"))
	DC_DocumentChannelProperty(device, "Background DAQ", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "Check_Settings_BackgrndDataAcq"))
	DC_DocumentChannelProperty(device, "TP during ITI", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "check_Settings_ITITP"))
	DC_DocumentChannelProperty(device, "Amplifier change via I=0", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "check_Settings_AmpIEQZstep"))
	DC_DocumentChannelProperty(device, "Skip analysis functions", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "Check_Settings_SkipAnalysFuncs"))
	DC_DocumentChannelProperty(device, "Repeat sweep on async alarm", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "Check_Settings_AlarmAutoRepeat"))
	DC_DocumentChannelProperty(device, "Autobias %", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "setvar_Settings_AutoBiasPerc"))
	DC_DocumentChannelProperty(device, "Autobias interval", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "setvar_Settings_AutoBiasInt"))

	DC_DocumentHardwareProperties(device, s.hardwareType)

	DC_DocumentChannelProperty(device, "Follower Device", INDEP_HEADSTAGE, NaN, NaN, str="")

	DC_DocumentChannelProperty(device, "Device", INDEP_HEADSTAGE, NaN, NaN, str=device)

	DC_DocumentChannelProperty(device, "MIES version", INDEP_HEADSTAGE, NaN, NaN, str=GetMIESVersionAsString())
	DC_DocumentChannelProperty(device, "Igor Pro version", INDEP_HEADSTAGE, NaN, NaN, str=GetIgorProVersion())
	DC_DocumentChannelProperty(device, "Igor Pro build", INDEP_HEADSTAGE, NaN, NaN, str=GetIgorProBuildVersion())
	DC_DocumentChannelProperty(device, "Igor Pro bitness", INDEP_HEADSTAGE, NaN, NaN, var=GetArchitectureBits())
	DC_DocumentChannelProperty(device, "JSON config file [path]", INDEP_HEADSTAGE, NaN, NaN, str=GetUserData(device, "", EXPCONFIG_UDATA_SOURCEFILE_PATH))
	DC_DocumentChannelProperty(device, "JSON config file [SHA-256 hash]", INDEP_HEADSTAGE, NaN, NaN, str=GetUserData(device, "", EXPCONFIG_UDATA_SOURCEFILE_HASH))
	DC_DocumentChannelProperty(device, "JSON config file [stimset nwb file path]", INDEP_HEADSTAGE, NaN, NaN, str=GetUserData(device, "", EXPCONFIG_UDATA_STIMSET_NWB_PATH))
	DC_DocumentChannelProperty(device, "TP after DAQ", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "check_Settings_TPAfterDAQ"))
	DC_DocumentChannelProperty(device, "Get/Set Inter-trial interval", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "Check_DataAcq_Get_Set_ITI"))
	DC_DocumentChannelProperty(device, "Double precision data", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "Check_Settings_UseDoublePrec"))
	DC_DocumentChannelProperty(device, "Save amplifier settings", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "check_Settings_SaveAmpSettings"))
	DC_DocumentChannelProperty(device, "Require amplifier", INDEP_HEADSTAGE, NaN, NaN, var=DAG_GetNumericalValue(device, "check_Settings_RequireAmpConn"))
	DC_DocumentChannelProperty(device, "Skip Ahead", INDEP_HEADSTAGE, NaN, NaN, var=s.skipAhead)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)

		DC_DocumentChannelProperty(device, "Headstage Active", i, NaN, NaN, var=s.statusHS[i])

		if(!s.statusHS[i])
			continue
		endif

		DC_DocumentChannelProperty(device, CLAMPMODE_ENTRY_KEY, i, NaN, NaN, var=DAG_GetHeadstageMode(device, i))
	endfor

	if(s.distributedDAQ)
		// dDAQ requires that all stimsets have the same length, so store the stim set length
		// also headstage independent
		ASSERT(!s.distributedDAQOptOv, "Unexpected oodDAQ mode")
		ASSERT(IsConstant(s.setLength, s.setLength[0]), "Unexpected varying stim set length")
		DC_DocumentChannelProperty(device, "Stim set length", INDEP_HEADSTAGE, NaN, NaN, var=s.setLength[0])
	endif

	for(i = 0; i < s.numADCEntries; i += 1)
		channel = s.ADCList[i]
		headstage = s.headstageADC[i]

		DC_DocumentChannelProperty(device, "ADC", headstage, channel, XOP_CHANNEL_TYPE_ADC, var=channel)

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)
		DC_DocumentChannelProperty(device, "AD Gain", headstage, channel, XOP_CHANNEL_TYPE_ADC, var=DAG_GetNumericalValue(device, ctrl, index = channel))

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_UNIT)
		DC_DocumentChannelProperty(device, "AD Unit", headstage, channel, XOP_CHANNEL_TYPE_ADC, str=DAG_GetTextualValue(device, ctrl, index = channel))

		DC_DocumentChannelProperty(device, "AD ChannelType", headstage, channel, XOP_CHANNEL_TYPE_ADC, var = config[s.numDACEntries + i][%DAQChannelType])
	endfor
End

static Function DC_FillSetEventFlag(string device, STRUCT DataConfigurationResult &s)
	variable i, channel

	WAVE config = GetDAQConfigWave(device)

	WAVE setEventFlag = GetSetEventFlag(device)
	setEventFlag = 0

	for(i = 0; i < s.numDACEntries; i += 1)
		channel = s.DACList[i]

		if(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ)
			setEventFlag[channel][] = (s.setColumn[i] + 1 == IDX_NumberOfSweepsInSet(s.setName[i]))
		endif
	endfor
End

static Function DC_FillDAQDataWaveForTP(string device, STRUCT DataConfigurationResult &s)

	variable cutOff, i, tpAmp, channelSize, minLimit, maxLimit
	string key

	// varies per DAC:
	// gains, DAScale, insertStart (with dDAQ), setLength, testPulseAmplitude (can be non-constant due to different VC/IC)
	// setName, setColumn, headstageDAC
	//
	// constant:
	// decimationFactor, testPulseLength, baselineFrac
	//
	// we only have to fill in the DA channels
	ASSERT(sum(s.insertStart) == 0, "Unexpected insert start value")
	ASSERT(sum(s.setColumn) == 0, "Unexpected setColumn value")
	ASSERT(DimSize(s.testPulse, COLS) <= 1, "Expected a 1D testpulse wave")
	ASSERT(s.numADCEntries > 0, "Number of ADCs can not be zero")
	ASSERT(s.numDACEntries > 0, "Number of DACs can not be zero")

	struct HardwareDataTPInput cacheParams
	cacheParams.hardwareType = s.hardwareType
	cacheParams.numDACs = s.numDACEntries
	cacheParams.numActiveChannels = s.numActiveChannels
	cacheParams.numberOfRows = DC_CalculateDAQDataWaveLength(device, TEST_PULSE_MODE)
	cacheParams.samplingInterval = s.samplingInterval
	WAVE cacheParams.gains = s.gains
	Duplicate/FREE/RMD=[][FindDimLabel(s.DACAmp, COLS, "TPAMP")] s.DACAmp, DACAmpTP
	WAVE cacheParams.DACAmpTP = DACAmpTP
	cacheParams.testPulseLength = s.testPulseLength
	cacheParams.baseLineFrac = s.baselineFrac

	key = CA_HardwareDataTPKey(cacheParams)

	WAVE/Z result = CA_TryFetchingEntryFromCache(key)

	if(WaveExists(result))
		WAVE DAQDataWave = GetDAQDataWave(device, TEST_PULSE_MODE)

		if(!cmpstr(GetStringFromWaveNote(DAQDataWave, TP_PROPERTIES_HASH, recursive = 1), key))
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
						FastOp NIChannel = (NaN)
					endfor
					break
			endswitch
		else
			if(IsWaveRefWave(DAQDataWave))
				WAVE/WAVE DAQDataWaveRef = DAQDataWave
				Redimension/N=(s.numActiveChannels) DAQDataWaveRef
				DAQDataWaveRef[] = GetNIDAQChannelWave(device, p, TEST_PULSE_MODE)
			endif
			SetStringInWaveNote(result, TP_PROPERTIES_HASH, key, recursive = 1)
			MoveWaveWithOverwrite(DAQDataWave, result, recursive = 1)
		endif
	else
		[WAVE ITCDataWave, WAVE/WAVE NISUDataWave] = DC_MakeAndGetDAQDataWave(device, s, TEST_PULSE_MODE)
		WAVE config = GetDAQConfigWave(device)

		switch(s.hardwareType)
			case HARDWARE_ITC_DAC:
				if(s.multiDevice)
					Multithread ITCDataWave[][0, s.numDACEntries - 1] =                                 \
					limit(                                                                              \
						  (s.gains[q] * s.DACAmp[q][%TPAMP]) * s.testPulse[mod(p, s.testPulseLength)], \
						  SIGNED_INT_16BIT_MIN,                                                         \
						  SIGNED_INT_16BIT_MAX); AbortOnRTE
					cutOff = mod(DimSize(ITCDataWave, ROWS), s.testPulseLength)
					if(cutOff > 0)
						ITCDataWave[DimSize(ITCDataWave, ROWS) - cutoff, *][0, s.numDACEntries - 1] = 0
					endif
				else
					Multithread ITCDataWave[0, s.testPulseLength - 1][0, s.numDACEntries - 1] = \
					limit(                                                                      \
						  s.gains[q] * s.DACAmp[q][%TPAMP] * s.testPulse[p],                   \
						  SIGNED_INT_16BIT_MIN,                                                 \
						  SIGNED_INT_16BIT_MAX); AbortOnRTE
				endif

				SetStringInWaveNote(ITCDataWave, TP_PROPERTIES_HASH, key, recursive = 1)
				CA_StoreEntryIntoCache(key, ITCDataWave)
				break
			case HARDWARE_NI_DAC:
				for(i = 0;i < s.numDACEntries; i += 1)
					WAVE NIChannel = NISUDataWave[i]
					tpAmp = s.DACAmp[i][%TPAMP] * s.gains[i]
					Multithread NIChannel[0, s.testPulseLength - 1] = \
					limit(                                          \
						  tpAmp * s.testPulse[p],                     \
						  NI_DAC_MIN,                               \
						  NI_DAC_MAX); AbortOnRTE
				endfor

				SetStringInWaveNote(NISUDataWave, TP_PROPERTIES_HASH, key, recursive = 1)
				CA_StoreEntryIntoCache(key, NISUDataWave)
				break
		endswitch
	endif
End

static Function DC_FillDAQDataWaveForDAQ(string device, STRUCT DataConfigurationResult &s)
	variable i, tpAmp, cutOff, channel, headstage, DAScale, singleSetLength, stimsetCol, startOffset
	variable lastValidRow, isUnAssociated, maxLimit, minLimit

	WAVE config = GetDAQConfigWave(device)

	[WAVE ITCDataWave, WAVE/WAVE NIDataWave] = DC_MakeAndGetDAQDataWave(device, s, DATA_ACQUISITION_MODE)

	// Note on decimation:
	// - There is no decimation for transfer of TP to the dataWave as the TP wave is always created with the same sample interval as the dataWave
	// - StimSets are created with the fixed WB interval WAVEBUILDER_MIN_SAMPINT and are resampled to the sample interval of the dataWave.
	//   The resample method picks the closest sample point in the stimSet by using round()
	//   The decimation factor can be < 1 (picking stimset samples one or multiple times) and > 1 (picking stimset samples or skipping it)
	for(i = 0; i < s.numDACEntries; i += 1)
		if(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_TP)
			tpAmp = s.DACAmp[i][%TPAMP] * s.gains[i]
			ASSERT(DimSize(s.testPulse, COLS) <= 1, "Expected a 1D testpulse wave")
			switch(s.hardwareType)
				case HARDWARE_ITC_DAC:
					Multithread ITCDataWave[][i] =                    \
					limit(                                            \
						  tpAmp * s.testPulse[mod(p, s.testPulseLength)], \
						  SIGNED_INT_16BIT_MIN,                       \
						  SIGNED_INT_16BIT_MAX); AbortOnRTE
					cutOff = mod(DimSize(ITCDataWave, ROWS), s.testPulseLength)
					if(cutOff > 0)
						ITCDataWave[DimSize(ITCDataWave, ROWS) - cutOff, *][i] = 0
					endif
					break
				case HARDWARE_NI_DAC:
					WAVE NIChannel = NIDataWave[i]
					Multithread NIChannel[] =                         \
					limit(                                            \
						  tpAmp * s.testPulse[mod(p, s.testPulseLength)], \
						  NI_DAC_MIN,                                 \
						  NI_DAC_MAX); AbortOnRTE
					cutOff = mod(DimSize(NIChannel, ROWS), s.testPulseLength)
					if(cutOff > 0)
						NIChannel[DimSize(NIChannel, ROWS) - cutOff, *] = 0
					endif
					break
			endswitch
		elseif(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ)
			channel = s.DACList[i]
			headstage = s.headstageDAC[i]
			tpAmp = s.DACAmp[i][%TPAMP] * s.gains[i]
			DAScale = s.DACAmp[i][%DASCALE] * s.gains[i]
			WAVE singleStimSet = s.stimSet[i]
			singleSetLength = s.setLength[i]
			stimsetCol = s.setColumn[i]
			startOffset = s.insertStart[i]
			isUnAssociated = IsNaN(headstage)

			switch(s.hardwareType)
				case HARDWARE_ITC_DAC:
					Multithread ITCDataWave[startOffset, startOffset + singleSetLength - 1][i] =       \
					limit(                                                                             \
						  DAScale * singleStimSet[round(s.decimationFactor * (p - startOffset))][stimsetCol], \
						  SIGNED_INT_16BIT_MIN,                                                        \
						  SIGNED_INT_16BIT_MAX); AbortOnRTE

					if(s.globalTPInsert && !isUnAssociated)
						// space in ITCDataWave for the testpulse is allocated via an automatic increase
						// of the onset delay
						MultiThread ITCDataWave[0, s.testPulseLength - 1][i] =                        \
						limit(tpAmp * s.testPulse[p], SIGNED_INT_16BIT_MIN, SIGNED_INT_16BIT_MAX); AbortOnRTE
					endif
					break
				case HARDWARE_NI_DAC:
					// for an index step of 1 in NIChannel, singleStimSet steps decimationFactor
					// for an index step of 1 in singleStimset, NIChannel steps 1 / decimationFactor
					// for decimationFactor < 1 and indexing NIChannel to DimSize(NIChannel, ROWS) - 1 (as implemented here),
					// singleStimset would be indexed to DimSize(singleStimSet, ROWS) - decimationFactor
					// this leads to an invalid index if decimationFactor is <= 0.5 (due to the way Igor handles nD wave indexing using round())
					// it is solved here by limiting the index of singleStimSet to the last valid integer index
					// for the case of decimationFactor >= 1 there is no issue since index DimSize(singleStimSet, ROWS) - decimationFactor is valid
					// for ITC decimationFactor is always >= 1 since the stimSets are generated for the ITC max. sample rate
					WAVE NIChannel = NIDataWave[i]
					lastValidRow = DimSize(singleStimSet, ROWS) - 1
					if(s.hardwareType == HARDWARE_NI_DAC)
						minLimit = NI_DAC_MIN
						maxLimit = NI_DAC_MAX
					endif

					MultiThread NIChannel[startOffset, startOffset + singleSetLength - 1] =                                    \
					limit(                                                                                                     \
						  DAScale * singleStimSet[round(limit(s.decimationFactor * (p - startOffset), 0, lastValidRow))][stimsetCol], \
						  minLimit,                                                                                          \
						  maxLimit); AbortOnRTE

					if(s.globalTPInsert && !isUnAssociated)
						// space in ITCDataWave for the testpulse is allocated via an automatic increase
						// of the onset delay
						MultiThread NIChannel[0, s.testPulseLength - 1] = \
						limit(tpAmp * s.testPulse[p], minLimit, maxLimit); AbortOnRTE
					endif
					break
			endswitch
		else
			ASSERT(0, "Unknown DAC channel type")
		endif
	endfor
End

static Function [STRUCT DataConfigurationResult s] DC_GetConfiguration(string device, variable numActiveChannels, variable dataAcqOrTP, variable multiDevice)
	variable channel, headstage, channelMode
	variable scalingZero, indexingLocked, indexing
	variable i, j, ret, setCycleCountLocal
	variable testPulseLength, tpPulseStartPoint, tpPulseLengthPoints
	string ctrl

	// pass parameters into returned struct
	s.numActiveChannels = numActiveChannels
	s.dataAcqOrTP       = dataAcqOrTP
	s.multiDevice       = multiDevice

	s.globalTPInsert        = DAG_GetNumericalValue(device, "Check_Settings_InsertTP")
	scalingZero             = DAG_GetNumericalValue(device,  "check_Settings_ScalingZero")
	indexingLocked          = DAG_GetNumericalValue(device, "Check_DataAcq1_IndexingLocked")
	indexing                = DAG_GetNumericalValue(device, "Check_DataAcq_Indexing")
	s.distributedDAQ        = DAG_GetNumericalValue(device, "Check_DataAcq1_DistribDaq")
	s.distributedDAQOptOv   = DAG_GetNumericalValue(device, "Check_DataAcq1_dDAQOptOv")
	s.distributedDAQOptPre  = DAG_GetNumericalValue(device, "Setvar_DataAcq_dDAQOptOvPre")
	s.distributedDAQOptPost = DAG_GetNumericalValue(device, "Setvar_DataAcq_dDAQOptOvPost")
	s.powerSpectrum         = DAG_GetNumericalValue(device, "check_settings_show_power")
	s.skipAhead             = DAG_GetNumericalValue(device, "SetVar_DataAcq_skipAhead")

	// MH: note with NI the decimationFactor can now be < 1, like 0.4 if a single NI ADC channel runs with 500 kHz
	// whereas the source data generated waves for ITC min sample rate are at 200 kHz
	s.decimationFactor = DC_GetDecimationFactor(device, dataAcqOrTP)
	s.samplingInterval = DAP_GetSampInt(device, dataAcqOrTP, XOP_CHANNEL_TYPE_DAC)
	WAVE/T allSetNames = DAG_GetChannelTextual(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
	s.hardwareType     = GetHardwareType(device)

	WAVE TPSettings     = GetTPSettings(device)
	WAVE TPSettingsCalc = GetTPSettingsCalculated(device)

	s.baselineFrac        = TPSettingsCalc[%baselineFrac]
	WAVE ChannelClampMode = GetChannelClampMode(device)
	WAVE s.statusHS       = DAG_GetChannelState(device, CHANNEL_TYPE_HEADSTAGE)

	WAVE s.gains  = SWS_GetChannelGains(device, timing = GAIN_BEFORE_DAQ)
	WAVE config  = GetDAQConfigWave(device)
	WAVE s.DACList = GetDACListFromConfig(config)
	WAVE s.ADCList = GetADCListFromConfig(config)
	WAVE s.TTLList = GetTTLListFromConfig(config)
	s.numTTLEntries = DimSize(s.TTLList, ROWS)

	Make/D/FREE/N=(NUM_DA_TTL_CHANNELS) s.TTLsetLength, s.TTLsetColumn, s.TTLcycleCount
	Make/T/FREE/N=(NUM_DA_TTL_CHANNELS) s.TTLsetName
	Make/WAVE/FREE/N=(NUM_DA_TTL_CHANNELS) s.TTLstimSet

	s.numDACEntries = DimSize(s.DACList, ROWS)
	Make/D/FREE/N=(s.numDACEntries) s.insertStart, s.setLength, s.setColumn, s.headstageDAC, s.setCycleCount
	Make/T/FREE/N=(s.numDACEntries) s.setName

	Make/WAVE/FREE/N=(s.numDACEntries) s.stimSet

	s.numADCEntries = DimSize(s.ADCList, ROWS)
	Make/D/FREE/N=(s.numADCEntries) s.headstageADC

	WAVE s.testPulse = GetTestPulse()

	// test pulse length is calculated for dataAcqOrTP @ref TP_CreateTestPulseWave
	WAVE TPSettingsCalc = GetTPsettingsCalculated(device)
	[testPulseLength, tpPulseStartPoint, tpPulseLengthPoints] = TP_GetCreationPropertiesInPoints(TPSettingsCalc, dataAcqOrTP)
	s.testPulseLength = testPulseLength
	s.tpPulseStartPoint = tpPulseStartPoint
	s.tpPulseLengthPoints = tpPulseLengthPoints

	s.headstageDAC[] = channelClampMode[s.DACList[p]][%DAC][%Headstage]
	s.headstageADC[] = channelClampMode[s.ADCList[p]][%ADC][%Headstage]

	WAVE/D s.DACAmp = GetDACAmplitudes(s.numDACEntries)

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
				s.stimSet[i] = s.testPulse
			else
				ASSERT(0, "Unknown DAQ Channel Type")
			endif
		elseif(dataAcqOrTP == TEST_PULSE_MODE)
			s.setName[i] = LowerStr(STIMSET_TP_WHILE_DAQ)
			s.stimSet[i] = s.testPulse
		else
			ASSERT(0, "unknown mode")
		endif

		// restarting DAQ via the stimset popup menues does not call DAP_CheckSettings()
		// so the stimest must not exist here or it could be empty
		if(!WaveExists(s.stimSet[i]) || DimSize(s.stimSet[i], ROWS) == 0)
			Abort
		endif

		if(dataAcqOrTP == TEST_PULSE_MODE)
			s.setColumn[i]     = 0
			s.setCycleCount[i] = NaN
		elseif(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_TP)
			// DATA_ACQUISITION_MODE cases
			s.setColumn[i]     = 0
			s.setCycleCount[i] = NaN
		elseif(config[i][%DAQChannelType] == DAQ_CHANNEL_TYPE_DAQ)
			// only call DC_CalculateChannelColumnNo for real data acquisition
			[ret, setCycleCountLocal] = DC_CalculateChannelColumnNo(device, s.setName[i], channel, CHANNEL_TYPE_DAC)
			s.setColumn[i]     = ret
			s.setCycleCount[i] = setCycleCountLocal
		endif

		if(IsFinite(headstage))
			channelMode = ChannelClampMode[channel][%DAC][%ClampMode]
			if(channelMode == V_CLAMP_MODE)
				s.DACAmp[i][%TPAMP] = TPSettings[%amplitudeVC][headstage]
			elseif(channelMode == I_CLAMP_MODE || channelMode == I_EQUAL_ZERO_MODE)
				s.DACAmp[i][%TPAMP] = TPSettings[%amplitudeIC][headstage]
			else
				ASSERT(0, "Unknown clamp mode")
			endif
		else // unassoc channel
			channelMode = NaN
			s.DACAmp[i][%TPAMP] = NaN
		endif

		ctrl = GetSpecialControlLabel(CHANNEL_TYPE_DAC, CHANNEL_CONTROL_SCALE)
		s.DACAmp[i][%DASCALE] = DAG_GetNumericalValue(device, ctrl, index = channel)

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
				if(s.powerSpectrum)
					s.DACAmp[i][%TPAMP] = 0
				endif
			endif
		elseif(dataAcqOrTP == TEST_PULSE_MODE)
			if(s.powerSpectrum)
				// intended use of powerspectrum is for noise checking
				s.DACAmp[i][%TPAMP] = 0
			endif
		else
			ASSERT(0, "unknown mode")
		endif
	endfor

	DC_SetupConfigurationTTLstimSets(device, s)

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

		if(j > 0)
			// we have at least one DAQ_CHANNEL_TYPE_DAQ channel
			Redimension/N=(j) reducedStimSet, reducedSetColumn

			STRUCT OOdDAQParams params
			InitOOdDAQParams(params, reducedStimSet, reducedSetColumn, s.distributedDAQOptPre, s.distributedDAQOptPost)
			WAVE/WAVE reducedStimSet = OOD_GetResultWaves(device, params)
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
		s.setLength[] = DC_CalculateStimsetLength(s.stimSet[p], device, TEST_PULSE_MODE)
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)
		Duplicate/FREE s.setLength, setMode
		setMode[] = config[p][%DAQChannelType] == DAQ_CHANNEL_TYPE_TP ? TEST_PULSE_MODE : DATA_ACQUISITION_MODE
		s.setLength[] = DC_CalculateStimsetLength(s.stimSet[p], device, setMode[p])
		WaveClear setMode
	endif

	if(dataAcqOrTP == TEST_PULSE_MODE)
		s.insertStart[] = 0
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)

		if(s.globalTPInsert)
			s.onsetDelayAuto = s.testPulseLength
		endif

		s.onsetDelayUser = round(DAG_GetNumericalValue(device, "setvar_DataAcq_OnsetDelayUser") / (s.samplingInterval * MICRO_TO_MILLI))
		s.terminationDelay = round(DAG_GetNumericalValue(device, "setvar_DataAcq_TerminationDelay") / (s.samplingInterval * MICRO_TO_MILLI))
		s.distributedDAQDelay = round(DAG_GetNumericalValue(device, "setvar_DataAcq_dDAQDelay") / (s.samplingInterval * MICRO_TO_MILLI))

		s.onsetDelay = s.onsetDelayUser + s.onsetDelayAuto
		if(s.distributedDAQ)
			s.insertStart[] = s.onsetDelay + (sum(s.statusHS, 0, s.headstageDAC[p]) - 1) * (s.distributedDAQDelay + s.setLength[p])
		else
			s.insertStart[] = s.onsetDelay
		endif
	endif
End

/// @brief fills in TTL stimset wave references in DataConfigurationResult structure
///        needs: s.hardwareType, s.numXXXEntries fields
static Function DC_SetupConfigurationTTLstimSets(string device, STRUCT DataConfigurationResult &s)

	variable i, col, setCycleCount

	WAVE/T allSetNames = DAG_GetChannelTextual(device, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_WAVE)
	WAVE statusTTLFiltered = DC_GetFilteredChannelState(device, s.dataAcqOrTP, CHANNEL_TYPE_TTL)
	WAVE s.statusTTLFiltered = statusTTLFiltered

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		if(!statusTTLFiltered[i])
			continue
		endif
		s.TTLsetName[i] = allSetNames[i]
		s.TTLstimSet[i] = WB_CreateAndGetStimSet(s.TTLsetName[i])
		ASSERT(WaveExists(s.TTLstimSet[i]), "Can't retrieve TTL stimset " + s.TTLsetName[i])
		s.TTLsetLength[i] = DC_CalculateStimsetLength(s.TTLstimSet[i], device,  s.dataAcqOrTP)

		[col, setCycleCount] = DC_CalculateChannelColumnNo(device, s.TTLsetName[i], i, CHANNEL_TYPE_TTL)
		s.TTLsetColumn[i] = col
		s.TTLcycleCount[i] = setCycleCount
	endfor

	DC_MakeTTLWave(device, s)
End

/// @brief Document hardware type/name/serial number into the labnotebook
static Function DC_DocumentHardwareProperties(device, hardwareType)
	string device
	variable hardwareType

	string str, key

	DC_DocumentChannelProperty(device, "Digitizer Hardware Type", INDEP_HEADSTAGE, NaN, NaN, var=hardwareType)

	NVAR deviceID = $GetDAQDeviceID(device)

	key = CA_HWDeviceInfoKey(device, hardwareType, deviceID)
	WAVE/Z devInfo = CA_TryFetchingEntryFromCache(key)

	if(!WaveExists(devInfo))
		WAVE devInfo = HW_GetDeviceInfo(hardwareType, deviceID, flags=HARDWARE_ABORT_ON_ERROR)
		CA_StoreEntryIntoCache(key, devInfo)
	endif

	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			DC_DocumentChannelProperty(device, "Digitizer Hardware Name", INDEP_HEADSTAGE, NaN, NaN, str=StringFromList(devInfo[%DeviceType], DEVICE_TYPES_ITC))
			sprintf str, "Master:%#0X,Secondary:%#0X,Host:%#0X", devInfo[%MasterSerialNumber], devInfo[%SecondarySerialNumber], devInfo[%HostSerialNumber]
			DC_DocumentChannelProperty(device, "Digitizer Serial Numbers", INDEP_HEADSTAGE, NaN, NaN, str=str)
			break
		case HARDWARE_NI_DAC:
			WAVE/T devInfoText = devInfo
			sprintf str, "%s %s (%#0X)", devInfoText[%DeviceCategoryStr], devInfoText[%ProductType], str2num(devInfoText[%ProductNumber])
			DC_DocumentChannelProperty(device, "Digitizer Hardware Name", INDEP_HEADSTAGE, NaN, NaN, str=str)
			sprintf str, "%#0X", str2num(devInfoText[%DeviceSerialNumber])
			DC_DocumentChannelProperty(device, "Digitizer Serial Numbers", INDEP_HEADSTAGE, NaN, NaN, str=str)
			break
		default:
			ASSERT(0, "Unknown hardware")
	endswitch
End

/// @brief Return the stimset acquisition cycle ID
///
/// @param device  device
/// @param fingerprint fingerprint as returned by DC_GenerateStimsetFingerprint()
/// @param DAC         DA channel
static Function DC_GetStimsetAcqCycleID(device, fingerprint, DAC)
	string device
	variable fingerprint, DAC

	WAVE stimsetAcqIDHelper = GetStimsetAcqIDHelperWave(device)

	ASSERT(IsFinite(fingerprint), "Invalid fingerprint")

	if(fingerprint == stimsetAcqIDHelper[DAC][%fingerprint])
		return stimsetAcqIDHelper[DAC][%id]
	endif

	stimsetAcqIDHelper[DAC][%fingerprint] = fingerprint
	stimsetAcqIDHelper[DAC][%id] = GetNextRandomNumberForDevice(device)

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
static Function DC_GenerateStimsetFingerprint(raCycleID, setName, setCycleCount, setChecksum)
	variable raCycleID
	string setName
	variable setChecksum, setCycleCount

	variable crc

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

static Function [variable result, variable row, variable column] DC_CheckIfDataWaveHasBorderVals(string device, variable dataAcqOrTP)

	variable hardwareType = GetHardwareType(device)
	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			WAVE/Z ITCDataWave = GetDAQDataWave(device, dataAcqOrTP)
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
			WAVE/WAVE NIDataWave = GetDAQDataWave(device, dataAcqOrTP)
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
/// @param device     device
/// @param entry          name of the property
/// @param headstage      number of headstage, must be `NaN` for unassociated channels
/// @param channelNumber  number of the channel
/// @param channelType    type of the channel
/// @param var [optional] numeric value
/// @param str [optional] string value
Function DC_DocumentChannelProperty(device, entry, headstage, channelNumber, channelType, [var, str])
	string device, entry
	variable headstage, channelNumber, channelType
	variable var
	string str

	variable colData, colKey, numCols
	string ua_entry

	ASSERT(ParamIsDefault(var) + ParamIsDefault(str) == 1, "Exactly one of var or str has to be supplied")
	ASSERT(!IsEmpty(entry), "Entry must be non-empty")

	WAVE sweepDataLNB         = GetSweepSettingsWave(device)
	WAVE/T sweepDataTxTLNB    = GetSweepSettingsTextWave(device)
	WAVE/T sweepDataLNBKey    = GetSweepSettingsKeyWave(device)
	WAVE/T sweepDataTxTLNBKey = GetSweepSettingsTextKeyWave(device)

	if(channelType == XOP_CHANNEL_TYPE_TTL)
		ASSERT(headstage == INDEP_HEADSTAGE, "sweepNB entry for TTL must target INDEP_HEADSTAGE")
		entry = CreateTTLChannelLBNKey(entry, channelNumber)
	endif

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
/// @param device  panel title
/// @param s       DataConfigurationResult structure
static Function DC_ITC_MakeTTLWave(string device, STRUCT DataConfigurationResult &s)

	variable i, first, last, rackIndex, rackNo
	variable bits, maxRows, lastIdx, bit
	string rackLNBPrefix

	WAVE statusTTLFiltered = DC_GetFilteredChannelState(device, DATA_ACQUISITION_MODE, CHANNEL_TYPE_TTL)
	WAVE/T allSetNamesIndexingEnd = DAG_GetChannelTextual(device, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)

	Make/FREE/D racks = {RACK_ZERO, RACK_ONE}
	for(rackNo : racks)
		if(DC_AreTTLsInRackChecked(device, rackNo))
			bits = 0
			HW_ITC_GetRackRange(rackNo, first, last)
			Make/FREE/T/N=(NUM_ITC_TTL_BITS_PER_RACK) sets, setSweepCount, cycleCount
			for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
				if(!statusTTLFiltered[i])
					continue
				endif

				if(i >= first && i <= last)
					maxRows = max(maxRows, DimSize(s.TTLstimSet[i], ROWS))
					rackIndex = i - first
					bits += 2^rackIndex

					setSweepCount[rackindex] = num2istr(s.TTLsetColumn[i])
					cycleCount[rackindex] = num2istr(s.TTLcycleCount[i])
					sets[rackIndex] = s.TTLsetName[i]
				endif
			endfor
			rackLNBPrefix = SelectString(rackNo == RACK_ZERO, "rack one", "rack zero")
			DC_DocumentChannelProperty(device, rackLNBPrefix + " bits", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, var=bits)
			DC_DocumentChannelProperty(device, rackLNBPrefix + " stim sets", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, str=TextWaveToList(sets, ";"))
			DC_DocumentChannelProperty(device, rackLNBPrefix + " set sweep counts", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, str=TextWaveToList(setSweepCount, ";"))
			DC_DocumentChannelProperty(device, rackLNBPrefix + " set cycle counts", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, str=TextWaveToList(cycleCount, ";"))
		endif
	endfor

	Make/FREE/T/N=(NUM_DA_TTL_CHANNELS) setLength, indexingEndStimSet, waveNote, checksum
	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		if(!statusTTLFiltered[i])
			continue
		endif

		setLength[i] = num2istr(s.TTLsetLength[i])
		indexingEndStimSet[i] = allSetNamesIndexingEnd[i]
		waveNote[i] = URLEncode(note(s.TTLstimSet[i]))
		checksum[i] = num2istr(WB_GetStimsetChecksum(s.TTLstimSet[i], s.TTLsetName[i], DATA_ACQUISITION_MODE))
	endfor

	DC_DocumentChannelProperty(device, "Stim set length", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, str=TextWaveToList(setLength, ";"))
	DC_DocumentChannelProperty(device, "Indexing End stimset", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, str=TextWaveToList(indexingEndStimSet, ";"))
	DC_DocumentChannelProperty(device, "Stimset wave note", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, str=TextWaveToList(waveNote, ";"))
	DC_DocumentChannelProperty(device, "Stim Wave Checksum", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, str=TextWaveToList(checksum, ";"))

	ASSERT(maxRows > 0, "Expected stim set of non-zero size")
	WAVE TTLWave = GetTTLWave(device)
	Redimension/N=(maxRows) TTLWave
	FastOp TTLWave = 0
	for(rackNo : racks)
		if(DC_AreTTLsInRackChecked(device, rackNo))
			HW_ITC_GetRackRange(rackNo, first, last)
			for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
				if(!statusTTLFiltered[i])
					continue
				endif
				if(i >= first && i <= last)
					bit = 1 << i
					WAVE TTLStimSet = s.TTLstimSet[i]
					lastIdx = DimSize(TTLStimSet, ROWS) - 1
					MultiThread TTLWave[0, lastIdx] += bit * TTLStimSet[p][s.TTLsetColumn[i]]
				endif
			endfor
		endif
	endfor
	s.joinedTTLStimsetSize = DC_CalculateStimsetLength(TTLWave, device, DATA_ACQUISITION_MODE)
End

static Function DC_NI_MakeTTLWave(string device, STRUCT DataConfigurationResult &s)

	variable i

	WAVE statusTTLFiltered = DC_GetFilteredChannelState(device, DATA_ACQUISITION_MODE, CHANNEL_TYPE_TTL)
	WAVE/T allSetNamesIndexingEnd = DAG_GetChannelTextual(device, CHANNEL_TYPE_TTL, CHANNEL_CONTROL_INDEX_END)
	WAVE/WAVE TTLWave = GetTTLWave(device)

	Make/FREE/T/N=(NUM_DA_TTL_CHANNELS) setLength, setName, setColumn, cycleCount, channels, indexingEndStimSet, waveNote, checksum
	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		if(!statusTTLFiltered[i])
			continue
		endif

		setLength[i] = num2istr(s.TTLsetLength[i])
		setName[i] = s.TTLsetName[i]
		setColumn[i] = num2istr(s.TTLsetColumn[i])
		cycleCount[i] = num2istr(s.TTLcycleCount[i])
		channels[i] = num2istr(i)
		indexingEndStimSet[i] = allSetNamesIndexingEnd[i]
		waveNote[i] = note(s.TTLstimSet[i])
		checksum[i] = num2istr(WB_GetStimsetChecksum(s.TTLstimSet[i], s.TTLsetName[i], DATA_ACQUISITION_MODE))

		WAVE TTLStimSet = s.TTLstimSet[i]
		Make/FREE/B/U/N=(DimSize(TTLStimSet, ROWS)) TTLWaveSingle
		MultiThread TTLWaveSingle[] = TTLStimSet[p][s.TTLsetColumn[i]]
		TTLWave[i] = TTLWaveSingle
	endfor
	s.joinedTTLStimsetSize = NaN

	DC_DocumentChannelProperty(device, "Stim set length", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, str=TextWaveToList(setLength, ";"))
	DC_DocumentChannelProperty(device, "channels", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, str=TextWaveToList(channels, ";"))
	DC_DocumentChannelProperty(device, "stim sets", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, str=TextWaveToList(setName, ";"))
	DC_DocumentChannelProperty(device, "set sweep counts", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, str=TextWaveToList(setColumn, ";"))
	DC_DocumentChannelProperty(device, "set cycle counts", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, str=TextWaveToList(cycleCount, ";"))
	DC_DocumentChannelProperty(device, "Indexing End stimset", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, str=TextWaveToList(indexingEndStimSet, ";"))
	DC_DocumentChannelProperty(device, "Stimset wave note", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, str=TextWaveToList(waveNote, ";"))
	DC_DocumentChannelProperty(device, "Stim Wave Checksum", INDEP_HEADSTAGE, NaN, XOP_CHANNEL_TYPE_TTL, str=TextWaveToList(checksum, ";"))
End

/// @brief Returns column number/step of the stimulus set, independent of the times the set is being cycled through
///        (as defined by SetVar_DataAcq_SetRepeats)
///
/// @param device    panel title
/// @param setName       name of the stimulus set
/// @param channelNo     channel number
/// @param channelType   channel type, one of @ref CHANNEL_TYPE_DAC or @ref CHANNEL_TYPE_TTL
///
/// @retval column        stimset column
/// @retval setCycleCount set cycle count
static Function [variable column, variable setCycleCount] DC_CalculateChannelColumnNo(string device, string setName, variable channelNo, variable channelType)

	variable ColumnsInSet = IDX_NumberOfSweepsInSet(SetName)
	variable localCount, repAcqRandom
	string sequenceWaveName
	variable skipAhead = DAP_GetskipAhead(device)

	repAcqRandom = DAG_GetNumericalValue(device, "check_DataAcq_RepAcqRandom")

	DFREF devicePath = GetDevicePath(device)

	// wave exists only if random set sequence is selected
	sequenceWaveName = SetName + num2str(channelType) + num2str(channelNo) + "_S"
	WAVE/Z/SDFR=devicePath WorkingSequenceWave = $sequenceWaveName
	NVAR count = $GetCount(device)
	// Below code calculates the variable local count which is then used to determine what column to select from a particular set
	if(!RA_IsFirstSweep(device))
		//thus the vairable "count" is used to determine if acquisition is on the first cycle
		if(!DAG_GetNumericalValue(device, "Check_DataAcq_Indexing"))
			localCount = count
		else // The local count is now set length dependent
			// check locked status. locked = popup menus on channels idex in lock - step
			if(DAG_GetNumericalValue(device, "Check_DataAcq1_IndexingLocked"))
				/// @todo this code here is different compared to what RA_BckgTPwithCallToRACounterMD and RA_CounterMD do
				NVAR activeSetCount = $GetActiveSetCount(device)
				ASSERT(IsFinite(activeSetCount), "activeSetCount has to be finite")
				localCount = IDX_CalculcateActiveSetCount(device) - activeSetCount
			else
				// calculate where in list global count is
				localCount = IDX_UnlockedIndexingStepNo(device, channelNo, channelType, count)
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
			DAP_ResetSkipAhead(device)
			RA_StepSweepsRemaining(device)
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
static Function DC_ReturnTotalLengthIncrease(STRUCT DataConfigurationResult &s)

	if(s.distributedDAQ)
		ASSERT(s.numDACEntries > 0, "Number of DACs must be at least one")
		return s.onsetDelayUser + s.onsetDelayAuto + s.terminationDelay + s.distributedDAQDelay * (s.numDACEntries - 1)
	else
		return s.onsetDelayUser + s.onsetDelayAuto + s.terminationDelay
	endif
End

/// @brief Calculate the stop collection point, includes all required global adjustments
static Function DC_GetStopCollectionPoint(string device, STRUCT DataConfigurationResult &s)
	variable DAClength, TTLlength, totalIncrease

	DAClength = DC_CalculateLongestSweep(device, s.dataAcqOrTP, CHANNEL_TYPE_DAC)

	if(s.dataAcqOrTP == DATA_ACQUISITION_MODE)

		// find out if we have only TP channels
		WAVE config = GetDAQConfigWave(device)
		WAVE DACmode = GetDACTypesFromConfig(config)

		FindValue/I=(DAQ_CHANNEL_TYPE_DAQ) DACmode

		if(V_Value == -1)
			return TIME_TP_ONLY_ON_DAQ * ONE_TO_MICRO / s.samplingInterval
		else
			totalIncrease = DC_ReturnTotalLengthIncrease(s)
			TTLlength     = DC_CalculateLongestSweep(device, DATA_ACQUISITION_MODE, CHANNEL_TYPE_TTL)

			if(s.distributedDAQOptOv)
				DAClength = WaveMax(s.setLength)
			elseif(s.distributedDAQ)
				DAClength *= DC_NoOfChannelsSelected(device, CHANNEL_TYPE_DAC)
			endif

			return max(DAClength, TTLlength) + totalIncrease
		endif
	elseif(s.dataAcqOrTP == TEST_PULSE_MODE)
		return DAClength
	endif

	ASSERT(0, "unknown mode")
End

/// @brief Returns 1 if a channel is set to TP, the check is through the
/// stimset name from the GUI
Function DC_GotTPChannelWhileDAQ(device)
	string device

	variable i, numEntries
	WAVE statusDAFiltered = DC_GetFilteredChannelState(device, DATA_ACQUISITION_MODE, CHANNEL_TYPE_DAC)
	WAVE/T allSetNames = DAG_GetChannelTextual(device, CHANNEL_TYPE_DAC, CHANNEL_CONTROL_WAVE)
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
/// @param device panel title
/// @param headstage head stage
///
/// @return One of @ref DaqChannelTypeConstants
Function DC_GetChannelTypefromHS(device, headstage)
	string device
	variable headstage

	variable dac, row
	WAVE config = GetDAQConfigWave(device)

	dac = AFH_GetDACFromHeadstage(device, headstage)

	if(!IsFinite(dac))
		return DAQ_CHANNEL_TYPE_UNKOWN
	endif

	row = AFH_GetDAQDataColumn(config, dac, XOP_CHANNEL_TYPE_DAC)
	ASSERT(IsFinite(row), "Invalid column")
	return config[row][%DAQChannelType]
End
