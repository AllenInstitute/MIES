#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_EP
#endif

/// @file MIES_Epochs.ipf
/// @brief __EP__ Handle code relating to epoch information

static StrConstant EPOCH_SHORTNAME_KEY  = "ShortName"
static StrConstant EPOCH_TYPE_KEY       = "Type"
static StrConstant EPOCH_SUBTYPE_KEY    = "SubType"
static StrConstant EPOCH_AMPLITUDE_KEY  = "Amplitude"
static StrConstant EPOCH_PULSE_KEY      = "Pulse"
static StrConstant EPOCH_CYCLE_KEY      = "Cycle"
static StrConstant EPOCH_INCOMPLETE_CYCLE_KEY = "Incomplete Cycle"
static StrConstant EPOCH_HALF_CYCLE_KEY = "Half Cycle"

static StrConstant EPOCHNAME_SEP = ";"
static StrConstant STIMSETKEYNAME_SEP = "="
static StrConstant SHORTNAMEKEY_SEP = "="

static StrConstant EPOCH_SN_BL_TOTALONSETDELAY = "B0_TO"
static StrConstant EPOCH_SN_BL_ONSETDELAYUSER = "B0_OD"
static StrConstant EPOCH_SN_BL_DDAQ = "B0_DD"
static StrConstant EPOCH_SN_BL_TERMINATIONDELAY = "B0_TD"
static StrConstant EPOCH_SN_BL_UNASSOC_NOTP_BASELINE = "B0_TP"
static StrConstant EPOCH_SN_BL_DDAQOPT = "B0_DO"
static StrConstant EPOCH_SN_BL_GENERALTRAIL = "B0_TR"
static StrConstant EPOCH_SN_TP = "TP"
static StrConstant EPOCH_SN_TP_PULSE = "TP_P"
static StrConstant EPOCH_SN_TP_BLFRONT = "TP_B0"
static StrConstant EPOCH_SN_TP_BLBACK = "TP_B1"
static StrConstant EPOCH_SN_OODAQ = "OD"
static StrConstant EPOCH_SN_STIMSET = "ST"
static StrConstant EPOCH_SN_STIMSETBLTRAIL = "B"
static StrConstant EPOCH_SN_EPOCH = "E"
static StrConstant EPOCH_SN_PULSETRAIN = "PT"
static StrConstant EPOCH_SN_PULSETRAIN_FULLPULSE = "P"
static StrConstant EPOCH_SN_PULSETRAIN_PULSEAMP = "P"
static StrConstant EPOCH_SN_PULSETRAIN_PULSEBASE = "B"
static StrConstant EPOCH_SN_PULSETRAIN_PULSEBASETRAIL = "BT"
static StrConstant EPOCH_SN_PULSETRAINBASETRAIL = "BT"
static StrConstant EPOCH_SN_TRIG = "TG"
static StrConstant EPOCH_SN_TRIG_CYCLE = "C"
static StrConstant EPOCH_SN_TRIG_CYCLE_INCOMPLETE = "I"
static StrConstant EPOCH_SN_TRIG_HALF_CYCLE = "H"
static StrConstant EPOCH_SN_UNACQUIRED = "UA"

static Constant EPOCH_GAPS_WORKAROUND = 0

/// @brief Helper structure for data used in epoch creation
///
/// structure variables for index based positions are prefixed:
/// dw*  - index in the data wave (e.g. DAChannel)
/// wb*  - index in the stimset wave from the wave builder
static Structure EP_EpochCreationData
	/// Epochs wave
	WAVE/T epochWave
	/// GUI channel number
	variable channel
	/// channel type as of @ref XopChannelConstants
	variable channelType
	/// sweep of stimset
	variable sweep
	/// decimation factor from stimset to data wave
	variable decimationFactor
	/// sampling interval of data wave
	variable samplingInterval
	/// DAScale of channel
	variable scale
	/// stimset wave note
	string stimNote
	/// stimset size in data wave
	variable dwStimsetSize
	/// For DA: size of stimset wave that was decimated to the data wave
	/// the duration of that stimset can be reduced compared to the duration of the original wavebuilder stimset
	/// due to oodDAQ end cutoff, typically DimSize of the stimset in DC
	/// For TTL: same as dwStimsetSize
	/// note: While for DA the stimset size in DC can only be reduced for TTL channels it can be increased, see structure element dwJoinedTTLStimsetSize
	variable reducedStimsetSize
	/// begin of stimset in indicces of the data wave
	variable dwStimsetBegin
	/// offset from oodDAQ shift in wavebuilder stimset wave indices
	variable wbOodDAQOffset
	/// size of the original wavebuilder stimset, used as reference point for flipping calculation
	variable wbStimsetSize
	/// sum of all stimset epochs without extension from delta mechanism (multi sweep, different size)
	variable wbEffectiveStimsetSize
	/// for ITC TTL stimsets are joined in DC to a single 2D wave that ROWS size equals the largest single stimset.
	/// This value is the data wave length that is used to decimate the from DC modified stimset into the data wave.
	/// The stimset is decimated to the data wave until dwJoinedTTLStimsetSize - 1.
	/// The related value for DA channels is s.setLength.
	/// For DA channels: NaN
	variable dwJoinedTTLStimsetSize
	/// set to one if the stimset is flipped, zero otherwise
	variable flipping
	/// test pulse properties transferred from DataConfigurationResult structure,
	/// originally calculated by @ref TP_GetCreationPropertiesInPoints
	variable tpTotalLengthPoints
	variable tpPulseStartPoint
	variable tpPulseLengthPoints
EndStructure

/// @brief Clear the list of epochs
Function EP_ClearEpochs(string device)

	WAVE/T epochWave = GetEpochsWave(device)
	epochWave = ""
End

/// @brief Fill the epoch wave with epochs before DAQ/TP
///
/// @param epochWave epochs wave
/// @param s         struct holding all input
Function EP_CollectEpochInfo(WAVE/T epochWave, STRUCT DataConfigurationResult &s)

	if(s.dataAcqOrTP != DATA_ACQUISITION_MODE)
		return NaN
	endif

	EP_CollectEpochInfoDA(epochWave, s)
	EP_CollectEpochInfoTTL(epochWave, s)
End

static Function EP_CollectEpochInfoDA(WAVE/T epochWave, STRUCT DataConfigurationResult &s)

	variable i, epochBegin, epochEnd
	variable isUnAssociated, testPulseLength
	string tags
	STRUCT EP_EpochCreationData ec

	WAVE/T ec.epochWave = epochWave
	ec.channelType = XOP_CHANNEL_TYPE_DAC
	ec.decimationFactor = s.decimationFactor
	ec.samplingInterval = s.samplingInterval
	ec.tpTotalLengthPoints = s.testPulseLength
	ec.tpPulseStartPoint = s.tpPulseStartPoint
	ec.tpPulseLengthPoints = s.tpPulseLengthPoints

	for(i = 0; i < s.numDACEntries; i += 1)

		if(WB_StimsetIsFromThirdParty(s.setName[i]) || !cmpstr(s.setName[i], STIMSET_TP_WHILE_DAQ))
			continue
		endif

		WAVE singleStimSet = s.stimSet[i]
		isUnAssociated = IsNaN(s.headstageDAC[i])

		ec.channel = s.DACList[i]
		ec.sweep = s.setColumn[i]
		ec.scale = s.DACAmp[i][%DASCALE]
		ec.stimNote = note(singleStimSet)
		ec.dwStimsetSize = s.setLength[i]
		ec.reducedStimsetSize = DimSize(singleStimSet, ROWS)
		ec.dwStimsetBegin = s.insertStart[i]
		ec.wbStimsetSize = WB_GetWaveNoteEntryAsNumber(ec.stimNote, STIMSET_ENTRY, key = STIMSET_SIZE_KEY)
		ec.flipping = WB_GetWaveNoteEntryAsNumber(ec.stimNote, STIMSET_ENTRY, key = "Flip")
		ec.dwJoinedTTLStimsetSize = NaN
		if(s.distributedDAQOptOv && s.offsets[i] > 0)
			ec.wbOodDAQOffset = round(s.offsets[i] / WAVEBUILDER_MIN_SAMPINT)
		else
			ec.wbOodDAQOffset = 0
		endif

		// epoch for onsetDelayAuto is assumed to be a globalTPInsert which is added as epoch below
		if(s.onsetDelayUser)
			epochBegin = s.onsetDelayAuto * s.samplingInterval
			epochEnd = epochBegin + s.onsetDelayUser * s.samplingInterval

			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, epochBegin, epochEnd, tags, EPOCH_SN_BL_ONSETDELAYUSER, 0)
		endif

		if(s.distributedDAQ)
			epochBegin = s.onsetDelay * s.samplingInterval
			epochEnd = ec.dwStimsetBegin * s.samplingInterval
			if(epochBegin != epochEnd)
				tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
				EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, epochBegin, epochEnd, tags, EPOCH_SN_BL_DDAQ, 0)
			endif
		endif

		if(s.terminationDelay)
			epochBegin = (ec.dwStimsetBegin + ec.dwStimsetSize) * s.samplingInterval
			epochEnd = min(epochBegin + s.terminationDelay * s.samplingInterval, s.stopCollectionPoint * s.samplingInterval)

			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, epochBegin, epochEnd, tags, EPOCH_SN_BL_TERMINATIONDELAY, 0)
		endif

		EP_AddEpochsFromStimSetNote(ec)

		if(s.distributedDAQOptOv)
			epochBegin = ec.dwStimsetBegin * s.samplingInterval
			epochEnd   = (ec.dwStimsetBegin + ec.dwStimsetSize) * s.samplingInterval
			EP_AddEpochsFromOodDAQRegions(ec.epochWave, ec.channel, s.regions[i], epochBegin, epochEnd)
		endif

		// if dDAQ is on then channels 0 to numEntries - 1 have a trailing base line
		epochBegin = ec.dwStimsetBegin + ec.dwStimsetSize + s.terminationDelay
		if(s.stopCollectionPoint > epochBegin)
			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, epochBegin * ec.samplingInterval, s.stopCollectionPoint * ec.samplingInterval, tags, EPOCH_SN_BL_GENERALTRAIL, 0)
		endif

		testPulseLength = s.testPulseLength * s.samplingInterval
		if(s.globalTPInsert)
			if(!isUnAssociated)
				// space in ITCDataWave for the testpulse is allocated via an automatic increase
				// of the onset delay
				EP_AddEpochsFromTP(ec, s.DACAmp[i][%TPAMP])
			else
				tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
				EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, 0, testPulseLength, tags, EPOCH_SN_BL_UNASSOC_NOTP_BASELINE, 0)
			endif
		endif
	endfor
End

static Function EP_CollectEpochInfoTTL(WAVE/T epochWave, STRUCT DataConfigurationResult &s)

	variable i
	variable epochBegin, epochEnd, dwStimsetEndIndex
	string tags
	STRUCT EP_EpochCreationData ec

	WAVE/T ec.epochWave = epochWave
	ec.channelType = XOP_CHANNEL_TYPE_TTL
	ec.decimationFactor = s.decimationFactor
	ec.samplingInterval = s.samplingInterval
	ec.tpTotalLengthPoints = NaN
	ec.tpPulseStartPoint = NaN
	ec.tpPulseLengthPoints = NaN
	ec.scale = 1
	ec.wbOodDAQOffset = 0
	ec.dwJoinedTTLStimsetSize = s.joinedTTLStimsetSize
	ec.dwStimsetBegin = s.onSetDelay

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!s.statusTTLFiltered[i])
			continue
		endif

		if(WB_StimsetIsFromThirdParty(s.TTLsetName[i]))
			continue
		endif

		WAVE singleStimSet = s.TTLstimSet[i]

		ec.channel = i
		ec.sweep = s.TTLsetColumn[i]
		ec.stimNote = note(singleStimSet)
		ec.dwStimsetSize = s.TTLsetLength[i]
		ec.reducedStimsetSize = DimSize(singleStimSet, ROWS)
		ec.wbStimsetSize = WB_GetWaveNoteEntryAsNumber(ec.stimNote, STIMSET_ENTRY, key = STIMSET_SIZE_KEY)
		ec.flipping = WB_GetWaveNoteEntryAsNumber(ec.stimNote, STIMSET_ENTRY, key = "Flip")

		if(s.globalTPInsert)
			// s.testPulseLength is a synonym for s.onsetDelayAuto
			epochBegin = 0
			epochEnd = s.testPulseLength
			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, epochBegin * ec.samplingInterval, epochEnd * ec.samplingInterval, tags, EPOCH_SN_BL_UNASSOC_NOTP_BASELINE, 0)
		endif
		if(s.onsetDelayUser)
			epochBegin = s.onsetDelayAuto
			// s.onsetDelay = s.onsetDelayUser + s.onsetDelayAuto
			epochEnd = s.onsetDelay

			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, epochBegin * ec.samplingInterval, epochEnd * ec.samplingInterval, tags, EPOCH_SN_BL_ONSETDELAYUSER, 0)
		endif

		dwStimsetEndIndex = EP_AddEpochsFromStimSetNote(ec)

		if(s.terminationDelay)
			epochBegin = dwStimsetEndIndex
			epochEnd = min(epochBegin + s.terminationDelay, s.stopCollectionPoint)

			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, epochBegin * ec.samplingInterval, epochEnd * ec.samplingInterval, tags, EPOCH_SN_BL_TERMINATIONDELAY, 0)
		endif

		epochBegin = dwStimsetEndIndex + s.terminationDelay
		if(s.stopCollectionPoint > epochBegin)
			epochEnd = s.stopCollectionPoint
			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, epochBegin * ec.samplingInterval, epochEnd * ec.samplingInterval, tags, EPOCH_SN_BL_GENERALTRAIL, 0)
		endif

	endfor
End

/// @brief Adds four epochs for a test pulse and three sub epochs for test pulse components
/// @param[in] ec        EP_EpochCreationData
/// @param[in] amplitude amplitude of the TP in the DA wave without gain
static Function EP_AddEpochsFromTP(STRUCT EP_EpochCreationData &ec, variable amplitude)

	variable epochBegin, epochEnd
	string epochTags, epochSubTags

	variable offset = 0

	epochTags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", "Inserted Testpulse", STIMSETKEYNAME_SEP, EPOCHNAME_SEP)

	// main TP range
	epochBegin = offset
	epochEnd = epochBegin + ec.tpTotalLengthPoints * ec.samplingInterval
	EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, epochBegin, epochEnd, epochTags, EPOCH_SN_TP, 0)

	// TP sub ranges
	epochBegin = offset + ec.tpPulseStartPoint * ec.samplingInterval
	epochEnd = epochBegin + (ec.tpPulseLengthPoints + 1) * ec.samplingInterval
	epochSubTags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, epochTags, EPOCH_PULSE_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	epochSubTags = ReplaceNumberByKey(EPOCH_AMPLITUDE_KEY, epochSubTags, amplitude, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, epochBegin, epochEnd, epochSubTags, EPOCH_SN_TP_PULSE, 1)

	// pre pulse BL
	epochBegin = offset
	epochEnd = epochBegin + ec.tpPulseStartPoint * ec.samplingInterval
	epochSubTags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, epochTags, EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, epochBegin, epochEnd, epochSubTags, EPOCH_SN_TP_BLFRONT, 1)

	// post pulse BL
	epochBegin = offset + (ec.tpPulseStartPoint + ec.tpPulseLengthPoints + 1) * ec.samplingInterval
	epochEnd = offset + ec.tpTotalLengthPoints * ec.samplingInterval
	EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, epochBegin, epochEnd, epochSubTags, EPOCH_SN_TP_BLBACK, 1)
End

/// @brief Adds epochs for oodDAQ regions
/// @param[in] epochWave     epoch wave
/// @param[in] channel       number of DA channel
/// @param[in] oodDAQRegions string containing list of oodDAQ regions as %d-%d;...
/// @param[in] stimsetBegin offset time in micro seconds where stim set begins
/// @param[in] stimsetEnd   offset time in micro seconds where stim set ends
static Function EP_AddEpochsFromOodDAQRegions(WAVE epochWave, variable channel, string oodDAQRegions, variable stimsetBegin, variable stimsetEnd)

	variable numRegions, first, last
	string tags

	WAVE/T regions = ListToTextWave(oodDAQRegions, ";")
	numRegions = DimSize(regions, ROWS)
	if(numRegions)
		Make/FREE/N=(numRegions) epochIndexer
		tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", "oodDAQ", STIMSETKEYNAME_SEP, EPOCHNAME_SEP)

		epochIndexer[] = EP_AddEpoch(epochWave, channel, XOP_CHANNEL_TYPE_DAC, str2num(StringFromList(0, regions[p], "-")) * MILLI_TO_MICRO + stimsetBegin,          \
																						str2num(StringFromList(1, regions[p], "-")) * MILLI_TO_MICRO + stimsetBegin,             \
																						ReplaceNumberByKey(EPOCH_OODDAQ_REGION_KEY, tags, p, STIMSETKEYNAME_SEP, EPOCHNAME_SEP), \
																						EPOCH_SN_OODAQ + num2str(p),                                                             \
																						2, lowerLimit = stimsetBegin, upperLimit = stimsetEnd)
	endif
End

/// @brief Calculate stimset epoch offsets and stimset epoch lengths in wavebuilder stimset indices
static Function [WAVE/D wbStimsetEpochOffset, WAVE/D wbStimsetEpochLength] EP_GetStimEpochsOffsetAndLength(STRUCT EP_EpochCreationData &ec)

	variable offset, epochCount, epochNr

	epochCount = WB_GetWaveNoteEntryAsNumber(ec.stimNote, STIMSET_ENTRY, key="Epoch Count")

	Make/FREE/D/N=(epochCount) wbStimsetEpochOffset, wbStimsetEpochLength

	wbStimsetEpochLength[] = WB_GetWaveNoteEntryAsNumber(ec.stimNote, EPOCH_ENTRY, sweep = ec.sweep, epoch = p, key = EPOCH_LENGTH_INDEX_KEY)
	for(epochNr = 0; epochNr < epochCount; epochNr += 1)
		wbStimsetEpochOffset[epochNr] = offset
		offset += wbStimsetEpochLength[epochNr]
	endfor

	return [wbStimsetEpochOffset, wbStimsetEpochLength]
End

/// @brief Calculates the offset times in microseconds of stimset epochs relative to the stimset start in the data wave
///
/// @param ec                   EP_EpochCreationData
/// @param wbStimsetEpochOffset offsets of the epochs of the stimset in wavebuilder stimset wave indices
/// @param wbStimsetEpochLength length of the epochs of the stimset in wavebuilder stimset wave indices
static Function [WAVE/D stimepochOffsetTime, WAVE/D stimepochDuration] EP_GetStimEpochsOffsetTimeAndDuration(STRUCT EP_EpochCreationData &ec, WAVE wbStimsetEpochOffset, WAVE wbStimsetEpochLength)

	variable epochCount, epochNr, wbFlippingIndex, indexInStimset

	wbFlippingIndex = EP_GetFlippingIndex(ec)
	epochCount = DimSize(wbStimsetEpochOffset, ROWS)

	Make/FREE/D/N=(epochCount) stimepochDuration, stimepochOffsetTime

	for(epochNr = 0; epochNr < epochCount; epochNr += 1)
		indexInStimset = ec.flipping ? wbFlippingIndex - wbStimsetEpochOffset[epochNr] - wbStimsetEpochLength[epochNr] : ec.wbOodDAQOffset + wbStimsetEpochOffset[epochNr]
		stimepochOffsetTime[epochNr] = (IndexAfterDecimation(indexInStimset, ec.decimationFactor) + 1) * ec.samplingInterval
	endfor

	for(epochNr = 0; epochNr < epochCount; epochNr += 1)
		if(ec.flipping)
			if(epochNr > 0)
				stimepochDuration[epochNr] = stimepochOffsetTime[epochNr - 1] - stimepochOffsetTime[epochNr]
			else
				stimepochDuration[epochNr] = (IndexAfterDecimation(wbFlippingIndex - wbStimsetEpochOffset[epochNr], ec.decimationFactor) + 1 ) * ec.samplingInterval - stimepochOffsetTime[epochNr]
			endif
		else
			if(epochNr < epochCount - 1)
				stimepochDuration[epochNr] = stimepochOffsetTime[epochNr + 1] - stimepochOffsetTime[epochNr]
			else
				stimepochDuration[epochNr] = (IndexAfterDecimation(ec.wbOodDAQOffset + wbStimsetEpochOffset[epochNr] + wbStimsetEpochLength[epochNr], ec.decimationFactor) + 1) * ec.samplingInterval - stimepochOffsetTime[epochNr]
			endif
		endif
		ASSERT(stimepochDuration[epochNr] > 0, "Epoch duration must be greater than zero")
	endfor

	return [stimepochOffsetTime, stimepochDuration]
End

/// @brief Adds the stimset level 0 epoch, oodDAQ offset epoch level 0, stimset sweep extension from delta method as level 1 epoch
///
/// @param ec                EP_EpochCreationData
/// @param stimepochDuration durations of the stimset epochs in microseconds
static Function [variable stimsetBegin, variable stimsetEnd, variable stimsetEndIndex] EP_AddEpochsForStimset(STRUCT EP_EpochCreationData &ec, WAVE stimepochDuration)

	variable stimsetDuration, stimsetEndLogical, oodDAQTime
	variable tiStimsetBaselineTrailBegin, tiStimsetBaselineTrailEnd, dwEffectiveStimsetStartIndex
	variable dwFullDecimationCarrySize
	string msg, epSweepTags, tags

	stimsetBegin = ec.dwStimsetBegin * ec.samplingInterval
	oodDAQTime = (IndexAfterDecimation(ec.wbOodDAQOffset, ec.decimationFactor) + 1) * ec.samplingInterval

	stimsetDuration = sum(stimepochDuration)
	ASSERT(stimsetDuration > 0, "Expected stimsetDuration > 0")
	stimsetEndLogical = stimsetBegin + stimsetDuration + oodDAQTime

	if(!IsNaN(ec.dwJoinedTTLStimsetSize) && ec.dwStimsetSize < ec.dwJoinedTTLStimsetSize)
		dwFullDecimationCarrySize = IndexAfterDecimation(ec.wbEffectiveStimsetSize, ec.decimationFactor) + 1
		if(ec.dwJoinedTTLStimsetSize < dwFullDecimationCarrySize)
			stimsetEndIndex = ec.dwStimsetBegin + ec.dwJoinedTTLStimsetSize
			stimsetEnd = stimsetEndIndex * ec.samplingInterval
		else
			stimsetEndIndex = ec.dwStimsetBegin + dwFullDecimationCarrySize
			stimsetEnd = stimsetEndIndex * ec.samplingInterval
		endif
	else
		stimsetEndIndex = ec.dwStimsetBegin + ec.dwStimsetSize
		stimsetEnd = stimsetEndIndex * ec.samplingInterval
	endif

	sprintf msg, "Stimset: iBegin setLength iEnd tEndLogical tBegin tEnd\r %7d %7d %7d %7.0f µs %7.0f µs %7.0f µs\r", ec.dwStimsetBegin, ec.dwStimsetSize, stimsetEndIndex, stimsetEndLogical / ec.samplingInterval, stimsetBegin, stimsetEnd
	DEBUGPRINT(msg)

	if(oodDAQTime > 0)
		tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
		EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, stimsetBegin, stimsetBegin + oodDAQTime, tags, EPOCH_SN_BL_DDAQOPT, 0)
	endif

	epSweepTags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", "Stimset", STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, stimsetBegin + oodDAQTime, stimsetEnd, epSweepTags, EPOCH_SN_STIMSET, 0)

	// If decimationFactor < 1 then stimsetEndLogical < stimsetEnd (if acquisition was not stopped early)
	// because the round function in the decimation shifts effectively the stimset by 0.5 * WAVEBUILDER_MIN_SAMPINT to the left.
	// Thus, after decimation the end is shifted to the left as well, potentially leaving remaining sample points in the DA wave.
	//
	// Case 2: stimsets with multiple sweeps where each sweep has a different length (due to delta mechanism)
	// result in 2D stimset waves where all sweeps have the same length
	// therefore we must add a baseline epoch after/before all defined epochs
	if(stimsetEnd > stimsetEndLogical)
		tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
		if(ec.flipping)
			dwEffectiveStimsetStartIndex = IndexAfterDecimation(ec.wbStimsetSize - ec.wbEffectiveStimsetSize, ec.decimationFactor) + 1
			tiStimsetBaselineTrailBegin = stimsetBegin + oodDAQTime
			tiStimsetBaselineTrailEnd = stimsetBegin + oodDAQTime + dwEffectiveStimsetStartIndex * ec.samplingInterval
		else
			tiStimsetBaselineTrailBegin = stimsetEndLogical
			tiStimsetBaselineTrailEnd = stimsetEnd
		endif
		EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, tiStimsetBaselineTrailBegin, tiStimsetBaselineTrailEnd, tags, EPOCH_SN_STIMSET + "_" + EPOCH_SN_STIMSETBLTRAIL, 1)
	endif

	return [stimsetBegin, stimsetEnd, stimsetEndIndex]
End

/// @brief Returns numerical epoch type from a stimset epoch of a sweep @ref WaveBuilderEpochTypes
///
/// @param stimNote stimset wave note
/// @param sweep    stimset sweep number
/// @param epochNr  epoch number
static Function EP_GetEpochType(string stimNote, variable sweep, variable epochNr)

	string type

	type = WB_GetWaveNoteEntry(stimNote, EPOCH_ENTRY, key="Type", sweep=sweep, epoch=epochNr)

	return WB_ToEpochType(type)
End

/// @brief Returns epoch short name from stimset epoch number
///
/// @param epochNr  epoch number
static Function/S EP_GetStimsetEpochShortName(variable epochNr)

	return EPOCH_SN_EPOCH + num2istr(epochNr)
End

/// @brief Adds the epochs of a stimset as level 1 epochs
///
/// @param ec                  EP_EpochCreationData
/// @param stimepochOffsetTime stimset epoch offset time in microseconds
/// @param stimepochDuration   stimset epoch duration in microseconds
/// @param epochNr             epoch number
/// @param stimsetBegin        stimset begin time offset in microseconds
/// @param stimsetEnd          stimset end time offset in microseconds
static Function [variable epochBegin, variable epochEnd, string epSubTags] EP_AddStimsetEpoch(STRUCT EP_EpochCreationData &ec, variable stimepochOffsetTime, variable stimepochDuration, variable epochNr, variable stimsetBegin, variable stimsetEnd)

	variable amplitude, stimEpochAmplitude, poissonDistribution, epochType
	string epSweepTags, epSpecifier, msg, type, shortNameEp

	epochBegin = stimepochOffsetTime + stimsetBegin
	epochEnd = epochBegin + stimepochDuration

	if(epochBegin >= stimsetEnd)
		return[NaN, NaN, ""]
	endif
	epochEnd = limit(epochEnd, 0, stimsetEnd)

	stimEpochAmplitude = WB_GetWaveNoteEntryAsNumber(ec.stimNote, EPOCH_ENTRY, key = "Amplitude", sweep = ec.sweep, epoch = epochNr)
	amplitude = ec.scale * stimEpochAmplitude
	poissonDistribution = !CmpStr(WB_GetWaveNoteEntry(ec.stimNote, EPOCH_ENTRY, sweep = ec.sweep, epoch = epochNr, key = "Poisson distribution"), "True")

	epSweepTags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", "Epoch", STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	type = WB_GetWaveNoteEntry(ec.stimNote, EPOCH_ENTRY, key="Type", sweep=ec.sweep, epoch=epochNr)
	epSubTags = ReplaceStringByKey("EpochType", epSweepTags, type, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	epSubTags = ReplaceNumberByKey("Epoch", epSubTags, epochNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	epSubTags = ReplaceNumberByKey(EPOCH_AMPLITUDE_KEY, epSubTags, amplitude, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)

	epSpecifier = ""
	epochType = EP_GetEpochType(ec.stimNote, ec.sweep, epochNr)
	if(epochType == EPOCH_TYPE_PULSE_TRAIN)
		if(!CmpStr(WB_GetWaveNoteEntry(ec.stimNote, EPOCH_ENTRY, sweep = ec.sweep, epoch = epochNr, key = "Mixed frequency"), "True"))
			epSpecifier = "Mixed frequency"
		elseif(poissonDistribution)
			epSpecifier = "Poisson distribution"
		endif
		if(!CmpStr(WB_GetWaveNoteEntry(ec.stimNote, EPOCH_ENTRY, key="Mixed frequency shuffle", sweep=ec.sweep, epoch=epochNr), "True"))
			epSpecifier += " shuffled"
		endif
	endif

	if(!isEmpty(epSpecifier))
		epSubTags = ReplaceStringByKey("Details", epSubTags, epSpecifier, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	endif

	shortNameEp = EP_GetStimsetEpochShortName(epochNr)
	EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, epochBegin, epochEnd, epSubTags, shortNameEp, 1, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)

	sprintf msg, "\rStimEpoch: nEpoch tBegin tEnd\r %7d %7.0f µs %7.0f µs\r", epochNr, epochBegin, epochEnd
	DEBUGPRINT(msg)

	return [epochBegin, epochEnd, epSubTags]
End

/// @brief Get PulseTrain start and end indices (inclusive), where the pulse is active in the wavebuilder stimset wave
///
/// @param ec      EP_EpochCreationData
/// @param epochNr epoch number
/// @returns pulse start and end indices where the pulse is active in the wavebuilder stimset wave
static Function [WAVE pulseStartIndices, WAVE pulseEndIndices] EP_PTGetPulseIndices(STRUCT EP_EpochCreationData &ec, variable epochNr)

	string pulseStartIndicesList, pulseEndIndicesList

	pulseStartIndicesList = WB_GetWaveNoteEntry(ec.stimNote, EPOCH_ENTRY, sweep = ec.sweep, epoch = epochNr, key = PULSE_START_INDICES_KEY)
	WAVE/Z pulseStartIndices = ListToNumericWave(pulseStartIndicesList, ",")
	ASSERT(WaveExists(pulseStartIndices) && DimSize(pulseStartIndices, ROWS) > 0, "Found no starting indices")
	pulseEndIndicesList = WB_GetWaveNoteEntry(ec.stimNote, EPOCH_ENTRY, sweep = ec.sweep, epoch = epochNr, key = PULSE_END_INDICES_KEY)
	WAVE/Z pulseEndIndices = ListToNumericWave(pulseEndIndicesList, ",")
	ASSERT(WaveExists(pulseEndIndices) && DimSize(pulseEndIndices, ROWS) > 0, "Found no end indices")

	return [pulseStartIndices, pulseEndIndices]
End

/// @brief Correction for overlapping pulses from e.g. poisson distribution
///
/// @param pulseStartIndices pulse active start indices in wavebuilder stimset wave indices
/// @param pulseEndIndices   pulse active end indices in wavebuilder stimset wave indices
static Function EP_PTCorrectOverlap(WAVE pulseStartIndices, WAVE pulseEndIndices)

	variable pulseNr, numPulses
	string msg

	numPulses = DimSize(pulseStartIndices, ROWS)
	for(pulseNr = 1; pulseNr < numPulses; pulseNr += 1)
		if(pulseStartIndices[pulseNr] < pulseEndIndices[pulseNr - 1])
			pulseStartIndices[pulseNr] = pulseEndIndices[pulseNr - 1]

			sprintf msg, "\rPT pulse overlap: nPulse nPulse iStart\r %d %d %d\r", pulseNr - 1, pulseNr, pulseStartIndices[pulseNr]
			DEBUGPRINT(msg)
		endif
	endfor
End

/// @brief Calculates the start times of PulseTrain pulses in the data wave
///
/// @param ec                   EP_EpochCreationData
/// @param wbStimsetEpochOffset offset of the stimset epoch in wavebuilder stimset indices
/// @param pulseStartIndices    start indices of PulseTrain pulses in the wavebuilder stimset
/// @returns wave with start times of PulseTrain pulses in the data wave relative to the stimset begin in the data wave in microseconds
static Function/WAVE EP_PTGetPulseStartTimes(STRUCT EP_EpochCreationData &ec, variable wbStimsetEpochOffset, WAVE  pulseStartIndices)

	variable indexInStimset, pulseNr, numPulses, wbFlippingIndex
	string msg

	Duplicate/FREE pulseStartIndices, startTimes
	wbFlippingIndex = EP_GetFlippingIndex(ec)

	numPulses = DimSize(pulseStartIndices, ROWS)
	for(pulseNr = 0; pulseNr < numPulses; pulseNr += 1)
		indexInStimset = ec.flipping ? wbFlippingIndex - wbStimsetEpochOffset - pulseStartIndices[pulseNr] : ec.wbOodDAQOffset + wbStimsetEpochOffset + pulseStartIndices[pulseNr]
		startTimes[pulseNr] = (IndexAfterDecimation(indexInStimset, ec.decimationFactor) + 1) * ec.samplingInterval

		sprintf msg, "\rPT pulse starts: nPulse iStimOffset tStart\r %d %d %7.0f µs\r", pulseNr, indexInStimset, startTimes[pulseNr]
		DEBUGPRINT(msg)
	endfor

	return startTimes
End

/// @brief Adds the PulseTrain Pulse-To-Pulse level 2 epoch
///
/// @param ec                EP_EpochCreationData
/// @param shortNameEpTypePT short name for the epoch type PulseTrain
/// @param epSubTags         tags for the PulseTrain epoch
/// @param startTimes        start times in micro seconds of the pulses relative to the start of the data wave (zero)
/// @param pulseNr           pulse number
/// @param epochBegin        start time of stimset epoch (level 1) in microseconds
/// @param epochEnd          end time of stimset epoch (level 1) in microseconds
/// @returns start and end time of the added Pulse-To-Pulse level 2 epoch in microseconds
static Function [variable subEpochBegin, variable subEpochEnd] EP_PTAddPTPEpoch(STRUCT EP_EpochCreationData &ec, string shortNameEpTypePT, string epSubTags, WAVE startTimes, variable pulseNr, variable epochBegin, variable epochEnd)

	variable numPulses
	string shortNameEpTypePTPulse, epSubSubTags, msg

	numPulses = DimSize(startTimes, ROWS)

	shortNameEpTypePTPulse = shortNameEpTypePT + "_" + EPOCH_SN_PULSETRAIN_FULLPULSE + num2istr(pulseNr)

	// Pulse-to-Pulse epoch
	if(ec.flipping)
		subEpochBegin = pulseNr + 1 == numPulses ? epochBegin : startTimes[pulseNr + 1]
		subEpochEnd = startTimes[pulseNr]
	else
		subEpochBegin = startTimes[pulseNr]
		subEpochEnd = pulseNr + 1 == numPulses ? epochEnd : startTimes[pulseNr + 1]
	endif
	if(subEpochBegin >= epochEnd)
		return [NaN, NaN]
	endif

	subEpochBegin = limit(subEpochBegin, epochBegin, Inf)
	subEpochEnd = limit(subEpochEnd, -Inf, epochEnd)

	epSubSubTags = ReplaceNumberByKey(EPOCH_PULSE_KEY, epSubTags, pulseNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, subEpochBegin, subEpochEnd, epSubSubTags, shortNameEpTypePTPulse, 2, lowerlimit = epochBegin, upperlimit = epochEnd)

	sprintf msg, "\rPTP: nPulse tEpBegin tEpEnd tSubEpBegin tSubEpEnd tStart\r %d %7.0f µs %7.0f µs %7.0f µs %7.0f µs %7.0f µs\r", pulseNr, epochBegin, epochEnd, subEpochBegin, subEpochEnd, startTimes[pulseNr]
	DEBUGPRINT(msg)

	return [subEpochBegin, subEpochEnd]
End

/// @brief Adds the PulseTrain Pulse-To-Pulse-Baseline-Trail level 2 epoch if present
///
/// @param ec                EP_EpochCreationData
/// @param shortNameEpTypePT short name for the epoch type PulseTrain
/// @param epSubTags         tags for the PulseTrain epoch
/// @param pulseNr           pulse number
/// @param numPulses         number of pulses in PulseTrain
/// @param epochBegin        start time of stimset epoch (level 1) in microseconds
/// @param epochEnd          end time of stimset epoch (level 1) in microseconds
/// @param subEpochbegin     start time of Pulse-To-Pulse epoch (level 2) in microseconds
/// @param subEpochend       end time of Pulse-To-Pulse epoch (level 2) in microseconds
static Function EP_PTAddPTBLTEpoch(STRUCT EP_EpochCreationData &ec, string shortNameEpTypePT, string epSubTags, variable pulseNr, variable numPulses, variable epochBegin, variable epochEnd, variable subEpochbegin, variable subEpochend)

	variable subsubEpochEnd
	string shortNameEpTypePTPulseBT, tags
	variable subsubEpochBegin = NaN

	shortNameEpTypePTPulseBT = shortNameEpTypePT + "_" + EPOCH_SN_PULSETRAIN_FULLPULSE + num2istr(pulseNr) + "_" + EPOCH_SN_PULSETRAIN_PULSEBASETRAIL

	// pulse-to-pulse base line trail, consider both sides as oodDAQ can introduce a base line trail on the front
	tags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, epSubTags, EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	if(pulseNr + 1 == numPulses)
		if(ec.flipping && subEpochBegin > epochBegin)
			subsubEpochBegin = epochBegin
			subsubEpochEnd = subEpochBegin
		elseif(!ec.flipping && subEpochEnd < epochEnd)
			subsubEpochBegin = subEpochEnd
			subsubEpochEnd = epochEnd
		endif
		// baseline before first pulse?
	elseif(pulseNr == 0)
		if(ec.flipping && subEpochEnd < epochEnd)
			subsubEpochBegin = subEpochEnd
			subsubEpochEnd = epochEnd
		elseif(!ec.flipping && epochBegin < subEpochBegin)
			subsubEpochBegin = epochBegin
			subsubEpochEnd = subEpochBegin
		endif
	endif

	if(!IsNaN(subsubEpochBegin))
		EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, subsubEpochBegin, subsubEpochEnd, tags, shortNameEpTypePTPulseBT, 2, lowerlimit = epochBegin, upperlimit = epochEnd)
	endif
End

/// @brief For flipped stimsets: Adds the PulseTrain Pulse-Active level 3 epoch, and Pulse-Baseline level 3 epoch if present
///
/// @param ec                   EP_EpochCreationData
/// @param shortNameEpTypePT    short name for the epoch type PulseTrain
/// @param epSubTags            tags for the PulseTrain epoch
/// @param stimsetEndIndex      offset of the stimset epoch in wavebuilder stimset indices
/// @param wbStimsetEpochOffset end index of the stimset in the data wave
/// @param pulseNr              pulse number
/// @param pulseStartIndexWB    start index of the pulse in wavebuilder stimset indices
/// @param pulseEndIndexWB      end index of the pulse in wavebuilder stimset indices
/// @param subEpochBegin        start time of Pulse-To-Pulse epoch (level 2) in microseconds
/// @param subEpochEnd          end time of Pulse-To-Pulse epoch (level 2) in microseconds
static Function EP_PTAddPTPActiveAndBaseFlipped(STRUCT EP_EpochCreationData &ec, string shortNameEpTypePT, string epSubTags, variable stimsetEndIndex, variable wbStimsetEpochOffset, variable pulseNr, variable pulseStartIndexWB, variable pulseEndIndexWB, variable subEpochBegin, variable subEpochEnd)

	variable pulseStartIndexStim, pulseEndIndexStim, wbFlippingIndex
	variable pulseStartIndex, pulseEndIndex, pulseDuration
	variable subsubEpochbegin, subsubEpochEnd, pulseActiveAddedFlag
	string shortNameEpTypePTPulse, shortNameEpTypePTPulseP, shortNameEpTypePTPulseB, epSubSubTags, msg

	shortNameEpTypePTPulse = shortNameEpTypePT + "_" + EPOCH_SN_PULSETRAIN_FULLPULSE + num2istr(pulseNr)
	wbFlippingIndex = EP_GetFlippingIndex(ec)

	pulseStartIndexStim = wbFlippingIndex - wbStimsetEpochOffset - (pulseEndIndexWB + 1)
	if(pulseStartIndexStim < ec.reducedStimsetSize)
		pulseEndIndexStim = limit(wbFlippingIndex - wbStimsetEpochOffset - pulseStartIndexWB, 0, ec.reducedStimsetSize)
		pulseStartIndex = ec.dwStimsetBegin + IndexAfterDecimation(pulseStartIndexStim, ec.decimationFactor)
		pulseEndIndex = ec.dwStimsetBegin + IndexAfterDecimation(pulseEndIndexStim, ec.decimationFactor)
		pulseEndIndex = limit(pulseEndIndex, 0, stimsetEndIndex - 1)
		pulseDuration = (pulseEndIndex - pulseStartIndex) * ec.samplingInterval
		subsubEpochBegin = subEpochEnd - pulseDuration
		subsubEpochEnd = subEpochEnd

		subsubEpochBegin = limit(subsubEpochBegin, subEpochBegin, Inf)
		if(subsubEpochBegin < subsubEpochEnd)
			epSubSubTags = ReplaceNumberByKey(EPOCH_PULSE_KEY, epSubTags, pulseNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			epSubSubTags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, epSubSubTags, "Pulse", STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			shortNameEpTypePTPulseP = shortNameEpTypePTPulse + "_" + EPOCH_SN_PULSETRAIN_PULSEAMP
			EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, subsubEpochBegin, subsubEpochEnd, epSubSubTags, shortNameEpTypePTPulseP, 3, lowerlimit = subEpochBegin, upperlimit = subEpochEnd)
			pulseActiveAddedFlag = 1

			sprintf msg, "\rPTP_a_f: nPulse iStart iEnd iDataStart iDataEnd tPulseDur tBegin tEnd\r %d %d %d %d %d %7.0f µs %7.0f µs %7.0f µs\r", pulseNr, pulseStartIndexStim, pulseEndIndexStim, pulseStartIndex, pulseEndIndex, pulseDuration, subsubEpochBegin, subsubEpochEnd
			DEBUGPRINT(msg)

		endif
	endif

	// baseline
	subsubEpochEnd = pulseActiveAddedFlag ? subsubEpochBegin : subEpochEnd
	subsubEpochBegin = subEpochBegin
	if(subsubEpochBegin >= subsubEpochEnd)
		return NaN
	endif

	epSubSubTags = ReplaceNumberByKey(EPOCH_PULSE_KEY, epSubTags, pulseNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	epSubSubTags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, epSubSubTags, EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	shortNameEpTypePTPulseB = shortNameEpTypePTPulse + "_" + EPOCH_SN_PULSETRAIN_PULSEBASE
	EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, subsubEpochBegin, subsubEpochEnd, epSubSubTags, shortNameEpTypePTPulseB, 3, lowerlimit = subEpochBegin, upperlimit = subEpochEnd)

	sprintf msg, "\rPTP_b_f: nPulse tBegin tEnd tDur\r %d %7.0f µs %7.0f µs %7.0f µs\r", pulseNr, subsubEpochBegin, subsubEpochEnd, subsubEpochEnd - subsubEpochBegin
	DEBUGPRINT(msg)
End

/// @brief For non-flipped stimsets: Adds the PulseTrain Pulse-Active level 3 epoch, and Pulse-Baseline level 3 epoch if present
///
/// @param ec                   EP_EpochCreationData
/// @param shortNameEpTypePT    short name for the epoch type PulseTrain
/// @param epSubTags            tags for the PulseTrain epoch
/// @param stimsetEndIndex      offset of the stimset epoch in wavebuilder stimset indices
/// @param wbStimsetEpochOffset end index of the stimset in the data wave
/// @param pulseNr              pulse number
/// @param pulseStartIndexWB    start index of the pulse in wavebuilder stimset indices
/// @param pulseEndIndexWB      end index of the pulse in wavebuilder stimset indices
/// @param subEpochBegin        start time of Pulse-To-Pulse epoch (level 2) in microseconds
/// @param subEpochEnd          end time of Pulse-To-Pulse epoch (level 2) in microseconds
static Function EP_PTAddPTPActiveAndBase(STRUCT EP_EpochCreationData &ec, string shortNameEpTypePT, string epSubTags, variable stimsetEndIndex, variable wbStimsetEpochOffset, variable pulseNr, variable pulseStartIndexWB, variable pulseEndIndexWB, variable subEpochBegin, variable subEpochEnd)

	variable pulseStartIndexStim, pulseEndIndexStim
	variable pulseStartIndex, pulseEndIndex, pulseDuration
	variable subsubEpochbegin, subsubEpochEnd
	string shortNameEpTypePTPulse, shortNameEpTypePTPulseP, shortNameEpTypePTPulseB, epSubSubTags, msg

	// active
	pulseStartIndexStim = ec.wbOodDAQOffset + wbStimsetEpochOffset + pulseStartIndexWB
	if(pulseStartIndexStim >= ec.reducedStimsetSize)
		return NaN
	endif

	pulseEndIndexStim = limit(ec.wbOodDAQOffset + wbStimsetEpochOffset + pulseEndIndexWB + 1, 0, ec.reducedStimsetSize)
	pulseStartIndex = ec.dwStimsetBegin + IndexAfterDecimation(pulseStartIndexStim, ec.decimationFactor)
	pulseEndIndex = ec.dwStimsetBegin + IndexAfterDecimation(pulseEndIndexStim, ec.decimationFactor)
	pulseEndIndex = limit(pulseEndIndex, 0, stimsetEndIndex - 1)
	pulseDuration = (pulseEndIndex - pulseStartIndex) * ec.samplingInterval
	subsubEpochBegin = subEpochBegin
	subsubEpochEnd = subEpochBegin + pulseDuration

	subsubEpochEnd = limit(subsubEpochEnd, -Inf, subEpochEnd)
	if(subsubEpochBegin == subsubEpochEnd)
		// With poissondistribution the offset to the next pulse can be very small, such that it is at the same position as the current pulse, leaving a zero sized pulse, then skip it
		// Or it was cutoff
		return NaN
	endif

	shortNameEpTypePTPulse = shortNameEpTypePT + "_" + EPOCH_SN_PULSETRAIN_FULLPULSE + num2istr(pulseNr)
	shortNameEpTypePTPulseP = shortNameEpTypePTPulse + "_" + EPOCH_SN_PULSETRAIN_PULSEAMP
	epSubSubTags = ReplaceNumberByKey(EPOCH_PULSE_KEY, epSubTags, pulseNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	epSubSubTags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, epSubSubTags, "Pulse", STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, subsubEpochBegin, subsubEpochEnd, epSubSubTags, shortNameEpTypePTPulseP, 3, lowerlimit = subEpochBegin, upperlimit = subEpochEnd)

	sprintf msg, "\rPTP_a: nPulse iStart iEnd iDataStart iDataEnd tPulseDur tBegin tEnd\r %d %d %d %d %d %7.0f µs %7.0f µs %7.0f µs\r", pulseNr, pulseStartIndexStim, pulseEndIndexStim, pulseStartIndex, pulseEndIndex, pulseDuration, subsubEpochBegin, subsubEpochEnd
	DEBUGPRINT(msg)

	// baseline
	if(subsubEpochEnd >= subEpochEnd)
		return NaN
	endif

	subsubEpochBegin = subsubEpochEnd
	subsubEpochEnd   = subEpochEnd

	epSubSubTags = ReplaceNumberByKey(EPOCH_PULSE_KEY, epSubTags, pulseNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	epSubSubTags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, epSubSubTags, EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	shortNameEpTypePTPulseB = shortNameEpTypePTPulse + "_" + EPOCH_SN_PULSETRAIN_PULSEBASE
	EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, subsubEpochBegin, subsubEpochEnd, epSubSubTags, shortNameEpTypePTPulseB, 3, lowerlimit = subEpochBegin, upperlimit = subEpochEnd)

	sprintf msg, "\rPTP_b: nPulse tBegin tEnd tDur\r %d %7.0f µs %7.0f µs %7.0f µs\r", pulseNr, subsubEpochBegin, subsubEpochEnd, subsubEpochEnd - subsubEpochBegin
	DEBUGPRINT(msg)
End

static Function EP_GetFlippingIndex(STRUCT EP_EpochCreationData &ec)

	return ec.wbOodDAQOffset + ec.wbStimsetSize
End

/// @brief Adds epochs for a stimset including higher tree level epochs
///
/// Hints for epoch calculation:
///  - prefer index based calculation over time based
///  - for IndexAfterDecimation(wbStimOffset, decimationFactor) the wbStimOffset must always refer to the same runnign index value as used in the decimation in DC
///    It is usually (e.g. for DA) dwIndex = dwOffset + IndexAfterDecimation(wbStimOffset, decimationFactor)
///    with dwOffset equal to ec.dwStimsetBegin (from s.insertStart)
///  - In contrast to the generated stimset wave the stimset epoch includes only the effective stimset, extensions from oodDAQ shifts get an own epoch.
///  - For DA without oodDAQ the generated and effective stimset are the same
///  - If ITC hardware is used and multiple TTL channels are active where one channel uses a shorter wavebuilder stimset than the other(s) then
///    the shorter stimset is extended to match the size of the largest stimset. The larger size is in DC then decimated to the data wave.
///    Due to decimation effects such stimset can increase in size in the data wave (e.g. with wb stimset size 185000, decimation factor 5 the increase is 2 points in the data wave)
///    relative to the calculated setLength.
///
/// @param ec                   EP_EpochCreationData
/// @returns stimset end index in data wave
static Function EP_AddEpochsFromStimSetNote(STRUCT EP_EpochCreationData &ec)

	variable stimsetBegin, stimsetEnd, stimsetEndIndex
	variable epochBegin, epochEnd, subEpochBegin, subEpochEnd
	string epSubTags, tags
	variable epochNr, epochCount, cycleNr, wbFlippingIndex
	variable pulseNr, numPulses, epochType, i, j
	variable halfCycleNr, hasFullCycle, hasIncompleteCycleAtStart, hasIncompleteCycleAtEnd, numInflectionPoints, incompleteCycleNr
	variable subsubEpochBegin, subsubEpochEnd
	string msg
	string shortNameEp, shortNameEpTypePT, shortNameEpTypePTPulse
	string shortNameEpTRIGCycle, shortNameEpTRIGIncomplete, shortNameEpTRIGHalfCycle, shortNameEpTypeTRIG_C, shortNameEpTypeTRIG_I
	string shortNameEpTypePTBaseline
	string inflectionPointsList

	string epSubSubTags

	ASSERT(!IsEmpty(ec.stimNote), "Stimset note is empty.")

	[WAVE wbStimsetEpochOffset, WAVE wbStimsetEpochLength] = EP_GetStimEpochsOffsetAndLength(ec)
	ec.wbEffectiveStimsetSize = sum(wbStimsetEpochLength)

	[WAVE stimepochOffsetTime, WAVE stimepochDuration] = EP_GetStimEpochsOffsetTimeAndDuration(ec, wbStimsetEpochOffset, wbStimsetEpochLength)

	[stimsetBegin, stimsetEnd, stimsetEndIndex] = EP_AddEpochsForStimset(ec, stimepochDuration)

	wbFlippingIndex = EP_GetFlippingIndex(ec)
	epochCount = WB_GetWaveNoteEntryAsNumber(ec.stimNote, STIMSET_ENTRY, key="Epoch Count")
	ASSERT(IsFinite(epochCount), "Could not find Epoch Count in stimset wave note.")
	for(epochNr = 0; epochNr < epochCount; epochNr += 1)

		if(ec.flipping)
			if(wbFlippingIndex - wbStimsetEpochOffset[epochNr] - wbStimsetEpochLength[epochNr] >= ec.reducedStimsetSize)
				continue
			endif
		else
			if(ec.wbOodDAQOffset + wbStimsetEpochOffset[epochNr] >= ec.reducedStimsetSize)
				break
			endif
		endif

		[epochBegin, epochEnd, epSubTags] = EP_AddStimsetEpoch(ec, stimepochOffsetTime[epochNr], stimepochDuration[epochNr], epochNr, stimsetBegin, stimsetEnd)
		if(IsNaN(epochBegin))
			if(ec.flipping)
				continue
			else
				break
			endif
		endif

		// Add Sub Epochs / Sub Sub Epochs
		shortNameEp = EP_GetStimsetEpochShortName(epochNr)
		epochType = EP_GetEpochType(ec.stimNote, ec.sweep, epochNr)
		if(epochType == EPOCH_TYPE_PULSE_TRAIN)
			shortNameEpTypePT = shortNameEp + "_" + EPOCH_SN_PULSETRAIN

			[WAVE pulseStartIndices, WAVE pulseEndIndices] = EP_PTGetPulseIndices(ec, epochNr)
			EP_PTCorrectOverlap(pulseStartIndices, pulseEndIndices)
			WAVE startTimes = EP_PTGetPulseStartTimes(ec, wbStimsetEpochOffset[epochNr], pulseStartIndices)
			startTimes += stimsetBegin

			numPulses = DimSize(pulseStartIndices, ROWS)
			// with flipping we iterate the pulses from large to small time points
			for(pulseNr = 0; pulseNr < numPulses; pulseNr += 1)

				[subEpochBegin, subEpochEnd] = EP_PTAddPTPEpoch(ec, shortNameEpTypePT, epSubTags, startTimes, pulseNr, epochBegin, epochEnd)
				if(IsNaN(subEpochBegin))
					// handle only beyond right limit, as cutoff only happens right
					if(ec.flipping)
						continue
					else
						break
					endif
				endif

				EP_PTAddPTBLTEpoch(ec, shortNameEpTypePT, epSubTags, pulseNr, numPulses, epochBegin, epochEnd, subEpochbegin, subEpochend)

				// Pulse Pulse part (active) and Pulse Baseline part
				if(ec.flipping)
					EP_PTAddPTPActiveAndBaseFlipped(ec, shortNameEpTypePT, epSubTags, stimsetEndIndex, wbStimsetEpochOffset[epochNr], pulseNr, pulseStartIndices[pulseNr], pulseEndIndices[pulseNr], subEpochBegin, subEpochEnd)
				else
					EP_PTAddPTPActiveAndBase(ec, shortNameEpTypePT, epSubTags, stimsetEndIndex, wbStimsetEpochOffset[epochNr], pulseNr, pulseStartIndices[pulseNr], pulseEndIndices[pulseNr], subEpochBegin, subEpochEnd)
				endif

			endfor

			if(numPulses == 0)
				// PulseTrain with numPulses = 0
				shortNameEpTypePTBaseline = shortNameEpTypePT + "_" + EPOCH_SN_PULSETRAINBASETRAIL
				tags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
				EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, epochBegin, epochEnd, tags, shortNameEpTypePTBaseline, 2, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)
			endif
		elseif(epochType == EPOCH_TYPE_SIN_COS)

			inflectionPointsList = WB_GetWaveNoteEntry(ec.stimNote, EPOCH_ENTRY, sweep = ec.sweep, epoch = epochNr, key = INFLECTION_POINTS_INDEX_KEY)
			WAVE/Z wbInflectionPoints = ListToNumericWave(inflectionPointsList, ",")
			if(!WaveExists(wbInflectionPoints))
				continue
			endif

			numInflectionPoints = DimSize(wbInflectionPoints, ROWS)

			cycleNr           = 0
			incompleteCycleNr = 0

			shortNameEpTypeTRIG_C  = shortNameEp + "_" + EPOCH_SN_TRIG + "_" + EPOCH_SN_TRIG_CYCLE
			shortNameEpTypeTRIG_I  = shortNameEp + "_" + EPOCH_SN_TRIG + "_" + EPOCH_SN_TRIG_CYCLE_INCOMPLETE

			if(!numInflectionPoints)
					// no inflection points at all, mark everything as incomplete cycle
					subEpochBegin = epochBegin
					subEpochEnd   = epochEnd
					shortNameEpTRIGIncomplete = shortNameEpTypeTRIG_I + num2istr(incompleteCycleNr)
					epSubSubTags = ReplaceNumberByKey(EPOCH_INCOMPLETE_CYCLE_KEY, epSubTags, incompleteCycleNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
					EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, subEpochBegin, subEpochEnd, epSubSubTags, shortNameEpTRIGIncomplete, 2, lowerlimit = epochBegin, upperlimit = epochEnd)
					incompleteCycleNr++
				continue
			endif

			Duplicate/FREE wbInflectionPoints, tiInflectionPoints
			// start/end op epoch is the first point in the data wave after the zero crossing
			if(ec.flipping)
				tiInflectionPoints[] = (ec.dwStimsetBegin + IndexAfterDecimation(wbFlippingIndex - wbStimsetEpochOffset[epochNr] - wbInflectionPoints[p] - 1, ec.decimationFactor) + 1) * ec.samplingInterval
				tiInflectionPoints[] = limit(tiInflectionPoints[p], epochBegin, Inf)
				WaveTransform/O flip, tiInflectionPoints
			else
				tiInflectionPoints[] = (ec.dwStimsetBegin + IndexAfterDecimation(ec.wbOodDAQOffset + wbStimsetEpochOffset[epochNr] + wbInflectionPoints[p] + 1, ec.decimationFactor) + 1) * ec.samplingInterval
			endif
			tiInflectionPoints -= epochBegin

			for(i = 0; i < numInflectionPoints; i += 2)

				// Cycle 0: 0, 1, 2
				// Half Cycle 0: 0, 1
				// Half Cycle 1: 1, 2
				//
				// Cycle 1: 2, 3, 4
				// Half Cycle 0: 2, 3
				// Half Cycle 1: 3, 4
				// ...

				hasFullCycle              = (i + 2 < numInflectionPoints)
				hasIncompleteCycleAtStart = (i == 0 && tiInflectionPoints[i] != 0)
				hasIncompleteCycleAtEnd   = !hasFullCycle || (i + 1 >= numInflectionPoints)

				if(!hasFullCycle || hasIncompleteCycleAtStart)
					if(hasIncompleteCycleAtStart)
						subEpochBegin = epochBegin
					else
						subEpochBegin = epochBegin + tiInflectionPoints[i]
					endif

					if(hasIncompleteCycleAtEnd)
						subEpochEnd = epochEnd
					else
						subEpochEnd = epochBegin + tiInflectionPoints[i]
					endif

					// add incomplete cycle epoch if it is not-empty
					if(subEpochBegin != subEpochEnd)
						shortNameEpTRIGIncomplete = shortNameEpTypeTRIG_I + num2istr(incompleteCycleNr)
						epSubSubTags = ReplaceNumberByKey(EPOCH_INCOMPLETE_CYCLE_KEY, epSubTags, incompleteCycleNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
						EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, subEpochBegin, subEpochEnd, epSubSubTags, shortNameEpTRIGIncomplete, 2, lowerlimit = epochBegin, upperlimit = epochEnd)
						incompleteCycleNr++
					endif
				endif

				if(hasFullCycle)
					cycleNr = i / 2
					subEpochBegin = epochBegin + tiInflectionPoints[i]
					subEpochEnd   = epochBegin + tiInflectionPoints[i + 2]
					shortNameEpTRIGCycle = shortNameEpTypeTRIG_C + num2istr(cycleNr)
					epSubSubTags = ReplaceNumberByKey(EPOCH_CYCLE_KEY, epSubTags, cycleNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
					EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, subEpochBegin, subEpochEnd, epSubSubTags, shortNameEpTRIGCycle, 2, lowerlimit = epochBegin, upperlimit = epochEnd)

					// add half cycles, only for full cycles
					for(j = 0; j < 2; j += 1)
						subsubEpochBegin = epochBegin + tiInflectionPoints[i + j]
						subsubEpochEnd   = epochBegin + tiInflectionPoints[i + j + 1]

						halfCycleNr = IsEven(j) ? 0 : 1
						shortNameEpTRIGHalfCycle = shortNameEpTRIGCycle + "_" + EPOCH_SN_TRIG_HALF_CYCLE + num2istr(halfCycleNr)
						epSubSubTags = ReplaceNumberByKey(EPOCH_CYCLE_KEY, epSubTags, cycleNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
						epSubSubTags = ReplaceNumberByKey(EPOCH_HALF_CYCLE_KEY, epSubSubTags, halfCycleNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
						EP_AddEpoch(ec.epochWave, ec.channel, ec.channelType, subsubEpochBegin, subsubEpochEnd, epSubSubTags, shortNameEpTRIGHalfCycle, 3, lowerlimit = subEpochBegin, upperlimit = subEpochEnd)
					endfor
				endif
			endfor
		else
			// Epoch details on other types not implemented yet
		endif

	endfor

	return stimsetEndIndex
End

/// @brief Sorts all epochs per channel number / channel type in EpochsWave
///
/// Removes epochs marked for removal, those with NaN as StartTime and EndTime, as well.
///
/// Sorting:
/// - Ascending starting time
/// - Descending ending time
/// - Ascending tree level
///
/// @param[in] epochWave epoch wave
Function EP_SortEpochs(WAVE/T epochWave)

	variable channel, channelCnt, epochCnt, channelType

	channelCnt = DimSize(epochWave, LAYERS)
	for(channelType = 0; channelType < XOP_CHANNEL_TYPE_COUNT; channelType += 1)
		for(channel = 0; channel < channelCnt; channel += 1)
			epochCnt = EP_GetEpochCount(epochWave, channel, channelType)
			if(epochCnt == 0)
				continue
			endif

			Duplicate/FREE/T/RMD=[, epochCnt - 1][][channel][channelType] epochWave, epochChannel
			Redimension/N=(-1, -1) epochChannel

			Make/FREE/D/N=(DimSize(epochChannel, ROWS), DimSize(epochChannel, COLS)) epochSortColStartTime, epochSortColEndTime, epochSortColTreeLevel
			epochSortColStartTime[] = str2numSafe(epochChannel[p][EPOCH_COL_STARTTIME])
			epochSortColEndTime[] = -1 * str2numSafe(epochChannel[p][EPOCH_COL_ENDTIME])
			epochSortColTreeLevel[] = str2numSafe(epochChannel[p][EPOCH_COL_TREELEVEL])
			SortColumns/DIML keyWaves={epochSortColStartTime, epochSortColEndTime, epochSortColTreeLevel} sortWaves={epochChannel}

			// remove epochs marked for removal
			// first column needs to be StartTime
			ASSERT(EPOCH_COL_STARTTIME == 0, "First column changed")
			RemoveTextWaveEntry1D(epochChannel, "NaN", all = 1)

			epochCnt = DimSize(epochChannel, ROWS)

			if(epochCnt > 0)
				epochWave[, epochCnt - 1][][channel][channelType] = epochChannel[p][q]
			endif

			if(epochCnt < DimSize(epochWave, ROWS))
				epochWave[epochCnt, *][][channel][channelType] = ""
			endif
		endfor
	endfor
End

/// @brief Returns the number of epoch in the epochsWave for the given channel
///
/// @param[in] epochWave   wave with epoch info
/// @param[in] channel     number of DA/TTL channel
/// @param[in] channelType type of channel (DA or TTL)
///
/// @return number of epochs for channel
static Function EP_GetEpochCount(WAVE/T epochWave, variable channel, variable channelType)

	FindValue/Z/RMD=[][][channel][channelType]/TXOP=4/TEXT="" epochWave
	return V_row == -1 ? DimSize(epochWave, ROWS) : V_row
End

/// @brief Add user epochs
///
/// Allows to add user epochs for not yet finished sweeps. The tree level
/// is fixed to #EPOCH_USER_LEVEL to not collide with stock entries.
///
/// @param device    device
/// @param channelType   channel type, currently only #XOP_CHANNEL_TYPE_DAC and #XOP_CHANNEL_TYPE_TTL is supported
/// @param channelNumber channel number
/// @param epBegin       start time of the epoch in seconds
/// @param epEnd         end time of the epoch in seconds
/// @param tags          tags for the epoch
/// @param shortName     [optional, defaults to auto-generated] user defined short name for the epoch, will
///                      be prefixed with #EPOCH_SHORTNAME_USER_PREFIX
Function EP_AddUserEpoch(string device, variable channelType, variable channelNumber, variable epBegin, variable epEnd, string tags, [string shortName])

	ASSERT(channelType == XOP_CHANNEL_TYPE_DAC || channelType == XOP_CHANNEL_TYPE_TTL, "Currently only epochs for the DA and TTL channels are supported")

	WAVE/T epochWave = GetEpochsWave(device)
	if(ParamIsDefault(shortName))
		sprintf shortName, "%s%d", EPOCH_SHORTNAME_USER_PREFIX,  EP_GetEpochCount(epochWave, channelNumber, channelType)
	else
		ASSERT(!GrepString(shortName, "^" + EPOCH_SHORTNAME_USER_PREFIX), "short name must not be prefixed with " + EPOCH_SHORTNAME_USER_PREFIX)
		shortName = EPOCH_SHORTNAME_USER_PREFIX + shortName
	endif

	return EP_AddEpoch(epochWave, channelNumber, channelType, epBegin * ONE_TO_MICRO, epEnd * ONE_TO_MICRO, tags, shortName, EPOCH_USER_LEVEL)
End

/// @brief Adds a epoch to the epochsWave
/// @param[in] epochWave   epochs wave
/// @param[in] channel     number of DA/TTL channel
/// @param[in] channelType type of channel (either DA or TTL)
/// @param[in] epBegin     start time of the epoch in micro seconds
/// @param[in] epEnd       end time of the epoch in micro seconds
/// @param[in] epTags      tags of the epoch
/// @param[in] epShortName short name of the epoch, should be unique
/// @param[in] level       level of epoch
/// @param[in] lowerlimit  [optional, default = -Inf] epBegin is limited between lowerlimit and Inf, epEnd must be > this limit
/// @param[in] upperlimit  [optional, default = Inf] epEnd is limited between -Inf and upperlimit, epBegin must be < this limit
static Function EP_AddEpoch(WAVE/T epochWave, variable channel, variable channelType, variable epBegin, variable epEnd, string epTags, string epShortName, variable level, [variable lowerlimit, variable upperlimit])

	variable i, j, numEpochs, pos
	string entry, startTimeStr, endTimeStr, msg

	lowerlimit = ParamIsDefault(lowerlimit) ? -Inf : lowerlimit
	upperlimit = ParamIsDefault(upperlimit) ? Inf : upperlimit

	ASSERT(channelType == XOP_CHANNEL_TYPE_DAC || channelType == XOP_CHANNEL_TYPE_TTL, "Unsupported channel type")
	ASSERT(!isNull(epTags), "Epoch name is null")
	ASSERT(!isEmpty(epTags), "Epoch name is empty")
	ASSERT(!isEmpty(epShortName), "Epoch short name is empty")
	ASSERT(epBegin <= epEnd, "Epoch end is <= epoch begin")
	ASSERT(epBegin < upperlimit, "Epoch begin is greater than upper limit")
	ASSERT(epEnd > lowerlimit, "Epoch end lesser than lower limit")
	ASSERT(channel >=0 && channel < NUM_DA_TTL_CHANNELS, "channel is out of range")
	ASSERT(!GrepString(epTags, EPOCH_TAG_INVALID_CHARS_REGEXP), "Epoch name contains invalid characters: " + EPOCH_TAG_INVALID_CHARS_REGEXP)

	epBegin = limit(epBegin, lowerlimit, Inf)
	epEnd = limit(epEnd, -Inf, upperlimit)

	i = EP_GetEpochCount(epochWave, channel, channelType)
	EnsureLargeEnoughWave(epochWave, indexShouldExist = i, dimension = ROWS)

	startTimeStr = num2strHighPrec(epBegin * MICRO_TO_ONE, precision = EPOCHTIME_PRECISION)
	endTimeStr = num2strHighPrec(epEnd * MICRO_TO_ONE, precision = EPOCHTIME_PRECISION)

	if(!cmpstr(startTimeStr, endTimeStr))
		// don't add single point epochs
		return NaN
	endif

	epTags = ReplaceStringByKey(EPOCH_SHORTNAME_KEY, epTags, epShortName, SHORTNAMEKEY_SEP)

	epochWave[i][%StartTime][channel][channelType] = startTimeStr
	epochWave[i][%EndTime][channel][channelType] = endTimeStr
	epochWave[i][%Tags][channel][channelType] = epTags
	epochWave[i][%TreeLevel][channel][channelType] = num2str(level)

	sprintf msg, "AddEpoch (chan, chanType, Lvl, Start, End, Tags): %d %d %d %s %s %s\r", channel, channelType, level, startTimeStr, endTimeStr, epTags
	DEBUGPRINT(msg)
End

/// @brief Write the epoch info into the sweep settings wave
///
/// @param device       device
/// @param sweepNo      sweep Number
/// @param acquiredTime if acquisition was stopped early time of last acquired point in AD wave, NaN otherwise
/// @param plannedTime  time of one point after the end of the DA wave
Function EP_WriteEpochInfoIntoSweepSettings(string device, variable sweepNo, variable acquiredTime, variable plannedTime)
	variable i, numDACEntries, channel, headstage
	string entry

	[WAVE sweepWave, WAVE configWave] = GetSweepAndConfigWaveFromDevice(device, sweepNo)

	EP_AdaptEpochInfo(device, configWave, acquiredTime, plannedTime)

	WAVE/T epochWave = GetEpochsWave(device)
	EP_SortEpochs(epochWave)

	WAVE DACList = GetDACListFromConfig(configWave)
	numDACEntries = DimSize(DACList, ROWS)

	WAVE/T epochsWave = GetEpochsWave(device)

	for(i = 0; i < numDACEntries; i += 1)
		channel = DACList[i]
		headstage = AFH_GetHeadstageFromDAC(device, channel)

		entry = EP_EpochWaveToStr(epochsWave, channel, XOP_CHANNEL_TYPE_DAC)
		DC_DocumentChannelProperty(device, EPOCHS_ENTRY_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, str=entry)
	endfor

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		entry = EP_EpochWaveToStr(epochsWave, i, XOP_CHANNEL_TYPE_TTL)
		if(!IsEmpty(entry))
			DC_DocumentChannelProperty(device, EPOCHS_ENTRY_KEY, INDEP_HEADSTAGE, i, XOP_CHANNEL_TYPE_TTL, str=entry)
		endif
	endfor

	DC_DocumentChannelProperty(device, "Epochs Version", INDEP_HEADSTAGE, NaN, NaN, var=SWEEP_EPOCH_VERSION)
End

/// @brief Convert the epochs wave layer given by `channel` and `channelType` to a string suitable for storing the labnotebook
///
/// @param epochsWave  wave with epoch information
/// @param channel     DA/TTL channel number
/// @param channelType channel type (DA or TTL)
threadsafe Function/S EP_EpochWaveToStr(WAVE epochsWave, variable channel, variable channelType)
	Duplicate/FREE/RMD=[][][channel][channelType] epochsWave, epochChannel
	Redimension/N=(-1, -1, 0, 0) epochChannel

	return TextWaveToList(epochChannel, EPOCH_LIST_ROW_SEP, colSep = EPOCH_LIST_COL_SEP, stopOnEmpty = 1)
End

/// @brief Converts a string containing epoch information in the format that is stored in the Labnotebook
///        to a 2D epoch wave @sa GetEpochsWave
///
/// @param[in] epochStr string with epoch information in the format as stored in the labnotebook
/// @returns 2D text wave with epoch information, use EPOCH_COL_ constants for column access
threadsafe Function/WAVE EP_EpochStrToWave(string epochStr)

	ASSERT_TS(!IsEmpty(epochStr), "No information in epochStr")
	WAVE/T epochWave = ListToTextWaveMD(epochStr, 2, rowSep = EPOCH_LIST_ROW_SEP, colSep = EPOCH_LIST_COL_SEP)
	SetEpochsDimensionLabelsSingleChannel(epochWave)

	return epochWave
End

/// @brief Returns the ShortName from a epoch name string, empty string if no ShortName is present
Function/S EP_GetShortName(string name)

	return StringByKey(EPOCH_SHORTNAME_KEY, name, SHORTNAMEKEY_SEP)
End

Function/S EP_RemoveShortNameFromTags(string tags)

	return RemoveByKey(EPOCH_SHORTNAME_KEY, tags, SHORTNAMEKEY_SEP)
End

/// @brief Adapt epoch information
///
/// - Adjust epoch end time to the acquired time
/// - Blanks out which are then too small or lie outside the acquired region
/// - Add an unacquired epoch
///
/// @param device        device
/// @param configWave    DAQ config wave
/// @param acquiredTime  if acquisition was stopped early time of last acquired point in AD wave [s], NaN otherwise
/// @param plannedTime   planned acquisition time, time at one point after the end of the DA wave [s]
static Function EP_AdaptEpochInfo(string device, WAVE configWave, variable acquiredTime, variable plannedTime)

	variable i, hwChannelNumber, numEntries, chanType

	numEntries = DimSize(configWave, ROWS)
	for(i = 0; i < numEntries; i += 1)
		chanType = configWave[i][%ChannelType]
		if(chanType != XOP_CHANNEL_TYPE_DAC)
			continue
		endif

		if(configWave[i][%DAQChannelType] != DAQ_CHANNEL_TYPE_DAQ)
			// skip all other channel types
			 continue
		endif
		hwChannelNumber = configWave[i][%ChannelNumber]
		EP_AdaptEpochInfoChannel(device, hwChannelNumber, XOP_CHANNEL_TYPE_DAC, acquiredTime, plannedTime)
	endfor

	WAVE statusFiltered = DC_GetFilteredChannelState(device, DATA_ACQUISITION_MODE, CHANNEL_TYPE_TTL)
	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		if(!statusFiltered[i])
			continue
		endif
		EP_AdaptEpochInfoChannel(device, i, XOP_CHANNEL_TYPE_TTL, acquiredTime, plannedTime)
	endfor
End

static Function EP_AdaptEpochInfoChannel(string device, variable channelNumber, variable channelType, variable acquiredTime, variable plannedTime)

	variable samplingInterval

	WAVE/T epochWave = GetEpochsWave(device)
	samplingInterval = DAP_GetSampInt(device, DATA_ACQUISITION_MODE, channelType)
	EP_AdaptEpochInfoChannelImpl(epochWave, channelNumber, channelType, samplingInterval, acquiredTime, plannedTime)
End

/// @brief Device independent implementation of EP_AdaptEpochInfoChannel
/// @param epochWave        epoch wave (4d)
/// @param channelNumber    GUI channel number
/// @param channelType      channel type
/// @param samplingInterval sampling interval of channel type
/// @param acquiredTime     acquiredTime in [s]
/// @param plannedTime      plannedTime in [s]
Function EP_AdaptEpochInfoChannelImpl(WAVE/T epochWave, variable channelNumber, variable channelType, variable samplingInterval, variable acquiredTime, variable plannedTime)

	variable epochCnt, epoch, startTime, endTime
	variable acquiredEpochsEndTime, lastValidIndex
	string tags

	epochCnt = EP_GetEpochCount(epochWave, channelNumber, channelType)
	if(IsNaN(acquiredTime))
		acquiredEpochsEndTime = plannedTime
	else
		lastValidIndex = trunc(acquiredTime * ONE_TO_MICRO / samplingInterval)
		acquiredEpochsEndTime = (lastValidIndex + 1) * samplingInterval * MICRO_TO_ONE
	endif

	for(epoch = 0; epoch < epochCnt; epoch += 1)
		startTime = str2num(epochWave[epoch][%StartTime][channelNumber][channelType])
		endTime   = str2num(epochWave[epoch][%EndTime][channelNumber][channelType])

		if(acquiredEpochsEndTime >= endTime)
			continue
		endif

		if(acquiredEpochsEndTime < startTime || abs(acquiredEpochsEndTime - startTime) <= 10^(-EPOCHTIME_PRECISION))
			// lies completely outside the acquired region
			// mark it for deletion
			epochWave[epoch][%StartTime][channelNumber][channelType] = "NaN"
			epochWave[epoch][%EndTime][channelNumber][channelType]   = "NaN"
		else
			// epoch was cut off
			epochWave[epoch][%EndTime][channelNumber][channelType] = num2strHighPrec(acquiredEpochsEndTime, precision = EPOCHTIME_PRECISION)
			DEBUGPRINT("Epoch EndTime was cutted, should only happen if acquisition was aborted early.")
		endif
	endfor

	if(acquiredEpochsEndTime < plannedTime)
		// add unacquired epoch
		// relies on EP_AddEpoch ignoring single point epochs
		tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", "Unacquired", STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
		EP_AddEpoch(epochWave, channelNumber, channelType, acquiredEpochsEndTime * ONE_TO_MICRO , plannedTime * ONE_TO_MICRO, tags , EPOCH_SN_UNACQUIRED, 0)
	endif
End

/// @brief Get epochs from the LBN filtered by given parameters
///
/// @param numericalValues Numerical values from the labnotebook
/// @param textualValues   Textual values from the labnotebook
/// @param sweepNo         Number of sweep
/// @param channelType     type of channel @sa XopChannelConstants
/// @param channelNumber   GUI channel number
/// @param shortname       short name filter, can be a regular expression which is matched caseless. For older tag formats
///                        it can be a simple tag entry (or regexp).
/// @param treelevel       [optional: default = not set] tree level of epochs, if not set then treelevel is ignored
/// @param epochsWave      [optional: defaults to $""] when passed, gathers epoch information from this wave directly.
///                        This is required for callers who want to read epochs during MID_SWEEP_EVENT in analysis functions.
///
/// @returns Text wave with epoch information, only rows fitting the input parameters are returned. Can also be a null wave.
Function/WAVE EP_GetEpochs(WAVE numericalValues, WAVE textualValues, variable sweepNo, variable channelType, variable channelNumber, string shortname, [variable treelevel, WAVE/T epochsWave])

	variable index, epochCnt, midSweep
	string regexp

	ASSERT(channelType == XOP_CHANNEL_TYPE_DAC || channelType == XOP_CHANNEL_TYPE_ADC || channelType == XOP_CHANNEL_TYPE_TTL, "Unsupported channel type")
	treelevel = ParamIsDefault(treelevel) ? NaN : treelevel

	if(ParamIsDefault(epochsWave) || !WaveExists(epochsWave))
		midSweep = 0
	else
		midSweep = 1
	endif

	if(!midsweep)
		WAVE/T/Z epochInfoChannel =  EP_FetchEpochs(numericalValues, textualValues, sweepNo, channelNumber, channelType)
		if(!WaveExists(epochInfoChannel))
			return $""
		endif

		epochCnt = DimSize(epochInfoChannel, ROWS)
	else
		epochCnt = EP_GetEpochCount(epochsWave, channelNumber, channelType)

		if(epochCnt == 0)
			return $""
		endif

		Duplicate/FREE/T/RMD=[0, epochCnt - 1][][channelNumber][channelType] epochsWave, epochInfoChannel
	endif

	Make/FREE/T/N=(epochCnt) shortnames = EP_GetShortName(epochInfoChannel[p][EPOCH_COL_TAGS])

	regexp = "(?i)" + shortname
	WAVE/Z indizesName = FindIndizes(shortnames, str = regexp, prop = PROP_GREP)

	if(!WaveExists(indizesName))
		if(HasOneValidEntry(shortnames))
			// we got short names but no hit
			return $""
		endif

		// fallback to previous tag name formats without shortname
		regexp = "(?i)(^|;)" + shortname + "($|;)"
		WAVE/Z indizesName = FindIndizes(epochInfoChannel, col = EPOCH_COL_TAGS, str = regexp, prop = PROP_GREP)

		if(!WaveExists(indizesName))
			return $""
		endif
	endif

	if(IsNaN(treelevel))
		WAVE indizes = indizesName
	else
		WAVE/Z indizesLevel = FindIndizes(epochInfoChannel, col = EPOCH_COL_TREELEVEL, var = treelevel)

		if(!WaveExists(indizesLevel))
			return $""
		endif

		WAVE/Z indizes = GetSetIntersection(indizesLevel, indizesName)
		if(!WaveExists(indizes))
			return $""
		endif
	endif

	Make/FREE/T/N=(DimSize(indizes, ROWS), DimSize(epochInfoChannel, COLS)) matches = epochInfoChannel[indizes[p]][q]

	SortColumns/KNDX={EPOCH_COL_STARTTIME} sortWaves={matches}

	CopyDimLabels/COLS=(COLS) epochInfoChannel, matches

	return matches
End

/// @brief Return free text wave with the epoch information of the given channel
///
/// @param numericalValues Numerical values from the labnotebook
/// @param textualValues   Textual values from the labnotebook
/// @param sweep           Number of sweep
/// @param channelNumber   GUI channel number
/// @param channelType     Type of channel @sa XopChannelConstants
///
/// @return epochs wave, see GetEpochsWave() for the wave layout
threadsafe Function/WAVE EP_FetchEpochs(WAVE numericalValues, WAVE/T/Z textualValues, variable sweep, variable channelNumber, variable channelType)

	variable index

	ASSERT_TS(channelType == XOP_CHANNEL_TYPE_DAC || channelType == XOP_CHANNEL_TYPE_ADC || channelType == XOP_CHANNEL_TYPE_TTL, "Unsupported channel type")
	if(channelType == XOP_CHANNEL_TYPE_ADC)
		[WAVE setting, index] = GetLastSettingChannel(numericalValues, $"", sweep, "DAC", channelNumber, XOP_CHANNEL_TYPE_ADC, DATA_ACQUISITION_MODE)
		if(!WaveExists(setting))
			return $""
		endif
		channelType = XOP_CHANNEL_TYPE_DAC
		channelNumber = setting[index]
		if(!(IsFinite(channelNumber) && index < NUM_HEADSTAGES))
			return $""
		endif
	endif

	[WAVE setting, index] = GetLastSettingChannel(numericalValues, textualValues, sweep, EPOCHS_ENTRY_KEY, channelNumber, channelType, DATA_ACQUISITION_MODE)

	if(!WaveExists(setting))
		return $""
	endif

	WAVE/T settingText = setting
	if(IsEmpty(settingText[index]))
		return $""
	endif
	WAVE/T epochs = EP_EpochStrToWave(settingText[index])
	ASSERT_TS(DimSize(epochs, ROWS) > 0, "Invalid epochs")
	SetEpochsDimensionLabelsSingleChannel(epochs)
	epochs[][%Tags] = RemoveEnding(epochs[p][%Tags], ";") + ";"

	return epochs
End

/// @brief Append epoch information from the labnotebook to the newly cleared epoch wave
Function EP_CopyLBNEpochsToEpochsWave(string device, variable sweepNo)
	variable i, j, epochCnt, epochChannelCnt, chanType

	EP_ClearEpochs(device)

	WAVE/T epochWave = GetEpochsWave(device)

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE textualValues   = GetLBTextualValues(device)

	Make/FREE/D channelTypes = {XOP_CHANNEL_TYPE_DAC, XOP_CHANNEL_TYPE_TTL}

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		for(chanType : channelTypes)
			WAVE/T/Z epochChannel = EP_FetchEpochs(numericalValues, textualValues, sweepNo, i, chanType)

			if(!WaveExists(epochChannel))
				continue
			endif

			epochChannelCnt = DimSize(epochChannel, ROWS)

			EnsureLargeEnoughWave(epochWave, dimension = ROWS, indexShouldExist = epochChannelCnt)

			epochWave[0, epochChannelCnt - 1][][i][chanType] = epochChannel[p][q]
		endfor
	endfor
End

/// @brief Helper function that returns (unintended) gaps between epochs
static Function/WAVE EP_GetGaps(WAVE numericalValues, WAVE textualValues, variable sweepNo, variable channelType, variable channelNumber)

	variable i, numEpochs, index

	WAVE/Z/T zeroEpochs = EP_GetEpochs(numericalValues, textualValues, sweepNo, channelType, channelNumber, ".*", treelevel=0)
	if(!WaveExists(zeroEpochs))
		return $""
	endif

	numEpochs = DimSize(zeroEpochs, ROWS)

	Make/FREE/D/N=(numEpochs, 2) gaps
	SetDimLabel COLS, 0, GAPBEGIN, gaps
	SetDimLabel COLS, 1, GAPEND, gaps

	for(i = 0; i < numEpochs - 1; i += 1)

		if(i == 0 && str2numSafe(zeroEpochs[i][EPOCH_COL_STARTTIME]) > 0)
			gaps[index][%GAPBEGIN] = 0
			gaps[index][%GAPEND] = str2numSafe(zeroEpochs[i][EPOCH_COL_STARTTIME])
			index += 1
		endif

		if(str2numSafe(zeroEpochs[i][EPOCH_COL_ENDTIME]) != str2numSafe(zeroEpochs[i + 1][EPOCH_COL_STARTTIME]))
			gaps[index][%GAPBEGIN] = str2numSafe(zeroEpochs[i][EPOCH_COL_ENDTIME])
			gaps[index][%GAPEND] = str2numSafe(zeroEpochs[i + 1][EPOCH_COL_STARTTIME])
			index += 1
		endif
	endfor

	if(!index)
		return $""
	endif

	Redimension/N=(index, -1) gaps

	return gaps
End

/// @brief Returns the following epoch of a given epoch name in a specified tree level
Function/WAVE EP_GetNextEpoch(WAVE numericalValues, WAVE textualValues, variable sweepNo, variable channelType, variable channelNumber, string shortname, variable treelevel, [variable ignoreGaps])

	variable currentEnd, dim

	ignoreGaps = ParamIsDefault(ignoreGaps) ? EPOCH_GAPS_WORKAROUND : !!ignoreGaps

	WAVE/Z/T currentEpoch = EP_GetEpochs(numericalValues, textualValues, sweepNo, channelType, channelNumber, shortname)
	ASSERT(WaveExists(currentEpoch) && DimSize(currentEpoch, ROWS) == 1, "Found multiple candidates for current epoch.")
	currentEnd = str2numSafe(currentEpoch[0][EPOCH_COL_ENDTIME])
	WAVE/Z/T levelEpochs = EP_GetEpochs(numericalValues, textualValues, sweepNo, channelType, channelNumber, ".*", treelevel=treelevel)
	if(!WaveExists(levelEpochs))
		return $""
	endif

	if(ignoreGaps)
		WAVE/Z gaps = EP_GetGaps(numericalValues, textualValues, sweepNo, channelType, channelNumber)
		if(WaveExists(gaps))
			dim = FindDimlabel(gaps, COLS, "GAPBEGIN")
			FindValue/Z/RMD=[][dim]/V=(currentEnd) gaps
			if(V_Value >= 0)
				currentEnd = gaps[V_row][%GAPEND]
			endif
		endif
	endif

	Make/FREE/D/N=(DimSize(levelEpochs, ROWS)) startTimes
	startTimes = str2numSafe(levelEpochs[p][EPOCH_COL_STARTTIME])
	WAVE/Z nextEpochCandidates = FindIndizes(startTimes, col=0, var=currentEnd)
	if(!WaveExists(nextEpochCandidates))
		return $""
	endif
	ASSERT(DimSize(nextEpochCandidates, ROWS) == 1, "Found multiple candidates for possible next epoch.")
	Duplicate/FREE/RMD=[nextEpochCandidates[0]][] levelEpochs, result

	return result
End

/// @brief returns the Amplitude value from the epoch tag data
Function EP_GetEpochAmplitude(string epochTag)

	return NumberByKey(EPOCH_AMPLITUDE_KEY, epochTag, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
End

/// @brief Recreate DA epochs from loaded data. The following must be loaded: LabNotebook, Sweep data of sweepNo, Stimsets used in the sweep
///        User epochs are not recreated !
///
/// @param numericalValues numerical LabNotebook
/// @param textualValues   textual LabNotebook
/// @param sweepDFR        single sweep folder, e.g. for measurement with a device this wold be DFREF sweepDFR = GetSingleSweepFolder(deviceDFR, sweepNo)
/// @param sweepNo         sweep number
/// @returns recreated 4D epoch wave
Function/WAVE EP_RecreateEpochsFromLoadedData(WAVE numericalValues, WAVE/T textualValues, DFREF sweepDFR, variable sweepNo)

	STRUCT DataConfigurationResult s
	variable channelNr, plannedTime, acquiredTime, adSize, firstUnacquiredIndex

	[s] = DC_RecreateDataConfigurationResultFromLNB(numericalValues, textualValues, sweepDFR, sweepNo)

	WAVE/T recEpochWave = GetEpochsWaveAsFree()
	EP_CollectEpochInfoDA(recEpochWave, s)

	WAVE/Z channelDA = GetDAQDataSingleColumnWaveNG(numericalValues, textualValues, sweepNo, sweepDFR, XOP_CHANNEL_TYPE_DAC, s.DACList[0])
	ASSERT(WaveExists(channelDA), "Could not retrieve first DA sweep")
	WAVE/Z channelAD = GetDAQDataSingleColumnWaveNG(numericalValues, textualValues, sweepNo, sweepDFR, XOP_CHANNEL_TYPE_ADC, s.ADCList[0])
	ASSERT(WaveExists(channelAD), "Could not retrieve first AD sweep")
	adSize = DimSize(channelAD, ROWS)
	firstUnacquiredIndex = FindFirstNaNIndex(channelAD)
	if(IsNaN(firstUnacquiredIndex))
		firstUnacquiredIndex = adSize
	endif
	[plannedTime, acquiredTime] = SWS_DeterminePlannedAndAcquiredTime(channelDA, channelAD, adSize, firstUnacquiredIndex)
	for(channelNr : s.DACList)
		EP_AdaptEpochInfoChannelImpl(recEpochWave, channelNr, XOP_CHANNEL_TYPE_DAC, s.samplingInterval, acquiredTime, plannedTime)
	endfor
	EP_SortEpochs(recEpochWave)

	return recEpochWave
End

/// @brief Fetches a single epoch channel from a recreated epoch wave.
///        The returned epoch channel wave has the same form as epoch information that was stored in the LNB returned by @ref EP_FetchEpochs
///
/// @param epochWave 4d epoch wave
/// @param channelNumber GUI channel number
/// @param channelType   channel type, one of @ref XopChannelConstants
/// @returns epoch channel wave (2d)
Function/WAVE EP_FetchEpochsFromRecreated(WAVE epochWave, variable channelNumber, variable channelType)

	string epList

	epList = EP_EpochWaveToStr(epochWave, channelNumber, channelType)
	if(IsEmpty(epList))
		return $""
	endif
	WAVE epChannel = EP_EpochStrToWave(epList)
	if(!DimSize(epChannel, ROWS))
		return $""
	endif

	return epChannel
End
