#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_MIESUTILS_CHANNELS
#endif // AUTOMATED_TESTING

/// @file MIES_MiesUtilities_Channels.ipf
/// @brief This file holds MIES utility functions for Channels

/// @brief Return a list of the AD channels from the DAQ config
threadsafe Function/WAVE GetADCListFromConfig(WAVE config)

	return GetChanneListFromDAQConfigWave(config, XOP_CHANNEL_TYPE_ADC)
End

/// @brief Return a list of the DA channels from the DAQ config
threadsafe Function/WAVE GetDACListFromConfig(WAVE config)

	return GetChanneListFromDAQConfigWave(config, XOP_CHANNEL_TYPE_DAC)
End

/// @brief Return a list of the TTL channels from the DAQ config
threadsafe Function/WAVE GetTTLListFromConfig(WAVE config)

	return GetChanneListFromDAQConfigWave(config, XOP_CHANNEL_TYPE_TTL)
End

/// @brief Return a wave with all active channels
///
/// @todo change to return a 0/1 wave with constant size a la DAG_GetChannelState
///
/// @param config       DAQConfigWave as passed to the ITC XOP
/// @param channelType  DA/AD/TTL constants, see @ref ChannelTypeAndControlConstants
threadsafe static Function/WAVE GetChanneListFromDAQConfigWave(WAVE config, variable channelType)

	variable numRows, i, j

	ASSERT_TS(IsValidConfigWave(config, version = 0), "Invalid config wave")

	numRows = DimSize(config, ROWS)
	Make/U/B/FREE/N=(numRows) activeChannels

	for(i = 0; i < numRows; i += 1)
		if(channelType == config[i][0])
			activeChannels[j] = config[i][1]
			j                += 1
		endif
	endfor

	Redimension/N=(j) activeChannels

	return activeChannels
End

/// @brief Returns the number of given mode channels from channelType wave
///
/// @param chanTypes a 1D wave containing @ref DaqChannelTypeConstants, returned by GetADCTypesFromConfig()
///
/// @param type to count, one of @ref DaqChannelTypeConstants
///
/// @return number of types present in chanTypes
Function GetNrOfTypedChannels(WAVE chanTypes, variable type)

	variable i, numChannels, count

	ASSERT(type == DAQ_CHANNEL_TYPE_UNKOWN || type == DAQ_CHANNEL_TYPE_DAQ || type == DAQ_CHANNEL_TYPE_TP, "Invalid type")
	numChannels = DimSize(chanTypes, ROWS)
	for(i = 0; i < numChannels; i += 1)
		if(chanTypes[i] == type)
			count += 1
		endif
	endfor

	return count
End

/// @brief Return a types of the AD channels from the ITC config
Function/WAVE GetTTLTypesFromConfig(WAVE config)

	return GetTypeListFromITCConfig(config, XOP_CHANNEL_TYPE_TTL)
End

/// @brief Return a types of the AD channels from the ITC config
Function/WAVE GetADCTypesFromConfig(WAVE config)

	return GetTypeListFromITCConfig(config, XOP_CHANNEL_TYPE_ADC)
End

/// @brief Return a types of the DA channels from the ITC config
Function/WAVE GetDACTypesFromConfig(WAVE config)

	return GetTypeListFromITCConfig(config, XOP_CHANNEL_TYPE_DAC)
End

/// @brief Return a wave with all active channels
///
/// @todo change to return a 0/1 wave with constant size a la DAG_GetChannelState
///
/// @param config       DAQConfigWave as passed to the ITC XOP
/// @param channelType  DA/AD/TTL constants, see @ref ChannelTypeAndControlConstants
static Function/WAVE GetTypeListFromITCConfig(WAVE config, variable channelType)

	variable numRows, i, j

	ASSERT(IsValidConfigWave(config, version = 2), "Invalid config wave")

	numRows = DimSize(config, ROWS)
	Make/U/B/FREE/N=(numRows) activeChannels

	for(i = 0; i < numRows; i += 1)
		if(channelType == config[i][%ChannelType])
			activeChannels[j] = config[i][%DAQChannelType]
			j                += 1
		endif
	endfor

	Redimension/N=(j) activeChannels

	return activeChannels
End

/// @brief Checks if a channel of TP type exists on ADCs
///
/// @param device device
///
/// @return 1 if TP type present, 0 otherwise
Function GotTPChannelsOnADCs(string device)

	WAVE config  = GetDAQConfigWave(device)
	WAVE ADCmode = GetADCTypesFromConfig(config)
	FindValue/I=(DAQ_CHANNEL_TYPE_TP) ADCmode
	return (V_Value != -1)
End

/// @brief Get the TTL bit mask from the labnotebook
/// @param numericalValues Numerical labnotebook values
/// @param sweep           Sweep number
/// @param channel         TTL hardware channel
threadsafe Function GetTTLBits(WAVE numericalValues, variable sweep, variable channel)

	variable index = GetIndexForHeadstageIndepData(numericalValues)

	WAVE/Z ttlRackZeroChannel = GetLastSetting(numericalValues, sweep, "TTL rack zero channel", DATA_ACQUISITION_MODE)
	WAVE/Z ttlRackOneChannel  = GetLastSetting(numericalValues, sweep, "TTL rack one channel", DATA_ACQUISITION_MODE)

	if(WaveExists(ttlRackZeroChannel) && ttlRackZeroChannel[index] == channel)
		WAVE ttlBits = GetLastSetting(numericalValues, sweep, "TTL rack zero bits", DATA_ACQUISITION_MODE)
	elseif(WaveExists(ttlRackOneChannel) && ttlRackOneChannel[index] == channel)
		WAVE ttlBits = GetLastSetting(numericalValues, sweep, "TTL rack one bits", DATA_ACQUISITION_MODE)
	else
		return NaN
	endif

	return ttlBits[index]
End

/// @brief Returns the used hardware DAC type from the LNB
///
/// @param numericalValues Numerical labnotebook values
/// @param sweep           Sweep number
/// @returns used hardware dac type @sa HardwareDACTypeConstants
threadsafe Function GetUsedHWDACFromLNB(WAVE numericalValues, variable sweep)

	// introduced in db531d20 (DC_PlaceDataIn ITCDataWave: Document the digitizer hardware type, 2018-07-30)
	// before that we only had ITC hardware
	return GetLastSettingIndep(numericalValues, sweep, "Digitizer Hardware Type", UNKNOWN_MODE, defValue = HARDWARE_ITC_DAC)
End

/// @brief Return a wave with the requested TTL channel information defined by TTLmode
///
/// @param numericalValues Numerical labnotebook values
/// @param textualValues   Text labnotebook values
/// @param sweep           Sweep number
/// @param TTLmode         One of @ref ActiveChannelsTTLMode.
threadsafe static Function/WAVE GetActiveChannelsTTL(WAVE numericalValues, WAVE textualValues, variable sweep, variable TTLmode)

	variable i, index, first, last, haveRackZero, haveRackOne, numHWTTLChannels, bits, hwChannel, hwDACType

	index = GetIndexForHeadstageIndepData(numericalValues)

	hwDACType = GetUsedHWDACFromLNB(numericalValues, sweep)
	ASSERT_TS(hwDACType == HARDWARE_ITC_DAC || hwDACType == HARDWARE_NI_DAC || hwDACType == HARDWARE_SUTTER_DAC, "Unsupported hardware dac type")

	if(hwDACType == HARDWARE_NI_DAC || hwDACType == HARDWARE_SUTTER_DAC)
		// present since 2f56481a (DC_MakeNITTLWave: Document TTL settings and rework it completely, 2018-09-06)
		WAVE/Z/T ttlChannels = GetLastSetting(textualValues, sweep, "TTL channels", DATA_ACQUISITION_MODE)
		if(!WaveExists(ttlChannels))
			return $""
		endif
		switch(TTLmode)
			case TTL_HARDWARE_CHANNEL: // intended drop-through
			case TTL_DAEPHYS_CHANNEL:
				return ListToNumericWave(ttlChannels[index], ";")
			case TTL_GUITOHW_CHANNEL:
				WAVE channelMapGUIToHW  = GetActiveChannelMapTTLGUIToHW()
				WAVE NIChannelNumbersHW = ListToNumericWave(ttlChannels[index], ";")
				channelMapGUIToHW[][%HWCHANNEL] = NIChannelNumbersHW[p]

				return channelMapGUIToHW
			case TTL_HWTOGUI_CHANNEL:
				WAVE channelMapHWToGUI = GetActiveChannelMapTTLHWToGUI()

				WAVE NIChannelNumbersHW = ListToNumericWave(ttlChannels[index], ";")
				channelMapHWToGUI[][] = NIChannelNumbersHW[p]

				return channelMapHWToGUI
			default:
				ASSERT_TS(0, "Invalid TTLmode")
		endswitch
	endif

	// ITC hardware
	//
	// LBN entries are present since c54d32a1 (Rework sweep settings
	// labnotebook interaction and add TTL info, 2015-07-03)
	switch(TTLmode)
		case TTL_HARDWARE_CHANNEL:

			WAVE/Z ttlChannelRackZero = GetLastSetting(numericalValues, sweep, "TTL rack zero channel", DATA_ACQUISITION_MODE)
			WAVE/Z ttlChannelRackOne  = GetLastSetting(numericalValues, sweep, "TTL rack one channel", DATA_ACQUISITION_MODE)
			if(WaveExists(ttlChannelRackZero) || WaveExists(ttlChannelRackOne))
				numHWTTLChannels = max(HARDWARE_ITC_TTL_1600_RACK_ONE + 1, NUM_DA_TTL_CHANNELS)
				Make/FREE/D/N=(numHWTTLChannels) entries = NaN
				if(WaveExists(ttlChannelRackZero))
					hwChannel          = ttlChannelRackZero[index]
					entries[hwChannel] = hwChannel
				endif

				if(WaveExists(ttlChannelRackOne))
					hwChannel          = ttlChannelRackOne[index]
					entries[hwChannel] = hwChannel
				endif

				return entries
			endif

			break
		case TTL_DAEPHYS_CHANNEL:

			WAVE/Z ttlBitsRackZero = GetLastSetting(numericalValues, sweep, "TTL rack zero bits", DATA_ACQUISITION_MODE)
			WAVE/Z ttlBitsRackOne  = GetLastSetting(numericalValues, sweep, "TTL rack one bits", DATA_ACQUISITION_MODE)
			if(WaveExists(ttlBitsRackZero) || WaveExists(ttlBitsRackOne))
				Make/FREE/D/N=(NUM_DA_TTL_CHANNELS) entries = NaN

				if(WaveExists(ttlBitsRackZero))
					HW_ITC_GetRackRange(RACK_ZERO, first, last)
					bits                 = ttlBitsRackZero[index]
					entries[first, last] = (bits & (1 << p)) != 0 ? p : NaN
				endif

				if(WaveExists(ttlBitsRackOne))
					HW_ITC_GetRackRange(RACK_ONE, first, last)
					bits                 = ttlBitsRackOne[index]
					entries[first, last] = (bits & (1 << (p - NUM_ITC_TTL_BITS_PER_RACK))) != 0 ? p : NaN
				endif

				return entries
			endif

			break
		case TTL_GUITOHW_CHANNEL:
			WAVE channelMapGUIToHW = GetActiveChannelMapTTLGUIToHW()

			WAVE/Z ttlChannelRackZero = GetLastSetting(numericalValues, sweep, "TTL rack zero channel", DATA_ACQUISITION_MODE)
			WAVE/Z ttlChannelRackOne  = GetLastSetting(numericalValues, sweep, "TTL rack one channel", DATA_ACQUISITION_MODE)
			WAVE/Z ttlBitsRackZero    = GetLastSetting(numericalValues, sweep, "TTL rack zero bits", DATA_ACQUISITION_MODE)
			WAVE/Z ttlBitsRackOne     = GetLastSetting(numericalValues, sweep, "TTL rack one bits", DATA_ACQUISITION_MODE)
			haveRackZero = WaveExists(ttlBitsRackZero) && WaveExists(ttlChannelRackZero)
			haveRackOne  = WaveExists(ttlBitsRackOne) && WaveExists(ttlChannelRackOne)
			if(haveRackZero)
				HW_ITC_GetRackRange(RACK_ZERO, first, last)
				bits                                       = ttlBitsRackZero[index]
				hwChannel                                  = ttlChannelRackZero[index]
				channelMapGUIToHW[first, last][%TTLBITNR]  = (bits & (1 << p)) != 0 ? p : NaN
				channelMapGUIToHW[first, last][%HWCHANNEL] = IsNaN(channelMapGUIToHW[p][%TTLBITNR]) ? NaN : hwChannel
			endif
			if(haveRackOne)
				HW_ITC_GetRackRange(RACK_ONE, first, last)
				bits                                       = ttlBitsRackOne[index]
				hwChannel                                  = ttlChannelRackOne[index]
				channelMapGUIToHW[first, last][%TTLBITNR]  = (bits & (1 << (p - NUM_ITC_TTL_BITS_PER_RACK))) != 0 ? p - NUM_ITC_TTL_BITS_PER_RACK : NaN
				channelMapGUIToHW[first, last][%HWCHANNEL] = IsNaN(channelMapGUIToHW[p][%TTLBITNR]) ? NaN : hwChannel
			endif
			if(haveRackZero || haveRackOne)
				return channelMapGUIToHW
			endif
			break
		case TTL_HWTOGUI_CHANNEL:
			WAVE channelMapHWToGUI = GetActiveChannelMapTTLHWToGUI()

			WAVE/Z ttlChannelRackZero = GetLastSetting(numericalValues, sweep, "TTL rack zero channel", DATA_ACQUISITION_MODE)
			WAVE/Z ttlChannelRackOne  = GetLastSetting(numericalValues, sweep, "TTL rack one channel", DATA_ACQUISITION_MODE)
			WAVE/Z ttlBitsRackZero    = GetLastSetting(numericalValues, sweep, "TTL rack zero bits", DATA_ACQUISITION_MODE)
			WAVE/Z ttlBitsRackOne     = GetLastSetting(numericalValues, sweep, "TTL rack one bits", DATA_ACQUISITION_MODE)
			haveRackZero = WaveExists(ttlBitsRackZero) && WaveExists(ttlChannelRackZero)
			haveRackOne  = WaveExists(ttlBitsRackOne) && WaveExists(ttlChannelRackOne)
			if(haveRackZero)
				HW_ITC_GetRackRange(RACK_ZERO, first, last)
				bits                                      = ttlBitsRackZero[index]
				hwChannel                                 = ttlChannelRackZero[index]
				channelMapHWToGUI[hwChannel][first, last] = (bits & (1 << q)) != 0 ? q : NaN
			endif
			if(haveRackOne)
				HW_ITC_GetRackRange(RACK_ONE, first, last)
				bits                                                                                              = ttlBitsRackOne[index]
				hwChannel                                                                                         = ttlChannelRackOne[index]
				channelMapHWToGUI[hwChannel][first - NUM_ITC_TTL_BITS_PER_RACK, last - NUM_ITC_TTL_BITS_PER_RACK] = (bits & (1 << q)) != 0 ? q + NUM_ITC_TTL_BITS_PER_RACK : NaN
			endif
			if(haveRackZero || haveRackOne)
				return channelMapHWToGUI
			endif
			break
		default:
			ASSERT_TS(0, "Invalid TTLmode")
	endswitch

	return $""
End

/// @brief Return a fixed size wave with the the active channels for the given channel type
///
/// The function takes into account unassociated DA/AD channels as well. It returns fixed size waves with the active
/// entries having the same value as their index. This allows users to either remove unused entries and use the wave as
/// active entries list or use the whole wave where not being NaN is active.
///
/// With the following DAEphys setup (only the first four channels are shown)
///
/// \rst
///
/// +----+----+----+-----+
/// | Nr | DA | AD | TTL |
/// +====+====+====+=====+
/// | 0  |    | •  |     |
/// +----+----+----+-----+
/// | 1  | •  |    |     |
/// +----+----+----+-----+
/// | 2  |    |    |  •  |
/// +----+----+----+-----+
/// | 3  |    |    |  •  |
/// +----+----+----+-----+
///
/// this function returns the following:
///
/// - ``DA``: ``{NaN,  1, NaN, NaN, ...}``
/// - ``AD``: ``{0, NaN, NaN, NaN, ...}``
/// - ``TTL``:
///
///   - NI hardware (regardless of TTLmode): ``{NaN, NaN, 2, 3, ...}``
///   - ITC hardware with TTLmode, example for two active racks:
///
///     - ``TTL_DAEPHYS_CHANNEL``: ``{NaN, NaN, 2, 3, NaN, 5, NaN, NaN}``
///     - ``TTL_HARDWARE_CHANNEL``: ``{0, NaN, NaN, 3, NaN, NaN, Nan, NaN}``
///     - ``TTL_GUITOHW_CHANNEL``: returns a 2D wave that allows to index by GUI channel (row) and retrieve hardware channel number and ttlbit number.
///       The columns are %HWCHANNEL and %TTLBITNR. The %TTLBITNR column is only valid for ITC hardware.
///     - ``TTL_HWTOGUI_CHANNEL``: returns a 2D wave that allows to index by hardware channel number and TTL bit number and retrieve the GUI channel number.
///       The hardware channel is indexed in the row and the TTL bit number in the column dimension. For NI hardware the TTL bit index should be zero.
///       Inactive hardware channel/ttlbit combinations return NaN.
///
/// \endrst
///
/// @see HW_ITC_GetITCXOPChannelForRack
///
/// @param numericalValues Numerical labnotebook values
/// @param textualValues   Text labnotebook values
/// @param sweepNo         Sweep number
/// @param channelType     One of @ref XopChannelConstants
/// @param TTLmode         [optional, defaults to #TTL_DAEPHYS_CHANNEL] One of @ref ActiveChannelsTTLMode.
///                        Does only apply to TTL channels.
threadsafe Function/WAVE GetActiveChannels(WAVE numericalValues, WAVE textualValues, variable sweepNo, variable channelType, [variable TTLmode])

	variable i, numEntries, index
	string key, cacheKey

	if(ParamIsDefault(TTLmode))
		TTLmode = TTL_DAEPHYS_CHANNEL
	endif

	cacheKey = CA_GenKeyGetActiveChannels(numericalValues, textualValues, sweepNo, channelType, TTLmode)
	WAVE/Z result = CA_TryFetchingEntryFromCache(cacheKey)
	if(WaveExists(result))
		return result
	endif

	switch(channelType)
		case XOP_CHANNEL_TYPE_DAC:
			key = "DAC"
			break
		case XOP_CHANNEL_TYPE_ADC:
			key = "ADC"
			break
		case XOP_CHANNEL_TYPE_TTL:
			return GetActiveChannelsTTL(numericalValues, textualValues, sweepNo, TTLmode)
		default:
			ASSERT_TS(0, "Unexpected channelType")
	endswitch

	numEntries = GetNumberFromType(xopVar = channelType)

	Make/FREE/N=(numEntries) channelStatus = NaN

	for(i = 0; i < numEntries; i += 1)
		[WAVE setting, index] = GetLastSettingChannel(numericalValues, $"", sweepNo, key, i, channelType, DATA_ACQUISITION_MODE)

		if(!WaveExists(setting))
			continue
		endif

		channelStatus[i] = i
	endfor

	CA_StoreEntryIntoCache(cacheKey, channelStatus)

	return channelStatus
End
