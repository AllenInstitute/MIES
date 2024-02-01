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

/// @brief Clear the list of epochs
Function EP_ClearEpochs(string device)

	WAVE/T epochWave = GetEpochsWave(device)
	epochWave = ""
End

/// @brief Fill the epoch wave with epochs before DAQ/TP
///
/// @param device device
/// @param s          struct holding all input
Function EP_CollectEpochInfo(string device, STRUCT DataConfigurationResult &s)

	if(s.dataAcqOrTP != DATA_ACQUISITION_MODE)
		return NaN
	endif

	EP_CollectEpochInfoDA(device, s)
	EP_CollectEpochInfoTTL(device, s)
End

static Function EP_CollectEpochInfoDA(string device, STRUCT DataConfigurationResult &s)

	variable i, channel, singleSetLength, epochOffset, epochBegin, epochEnd, lastP
	variable stimsetCol, startOffset, stopCollectionPoint, isUnAssociated, testPulseLength
	string tags

	stopCollectionPoint = ROVar(GetStopCollectionPoint(device))
	lastP = stopCollectionPoint - 1

	for(i = 0; i < s.numDACEntries; i += 1)

		if(WB_StimsetIsFromThirdParty(s.setName[i]) || !cmpstr(s.setName[i], STIMSET_TP_WHILE_DAQ))
			continue
		endif

		channel = s.DACList[i]
		startOffset = s.insertStart[i]
		singleSetLength = s.setLength[i]
		WAVE singleStimSet = s.stimSet[i]
		stimsetCol = s.setColumn[i]
		isUnAssociated = IsNaN(s.headstageDAC[i])

		// epoch for onsetDelayAuto is assumed to be a globalTPInsert which is added as epoch below
		if(s.onsetDelayUser)
			epochBegin = s.onsetDelayAuto * s.samplingInterval
			epochEnd = epochBegin + s.onsetDelayUser * s.samplingInterval

			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(device, channel, XOP_CHANNEL_TYPE_DAC, epochBegin, epochEnd, tags, EPOCH_SN_BL_ONSETDELAYUSER, 0)
		endif

		if(s.distributedDAQ)
			epochBegin = s.onsetDelay * s.samplingInterval
			epochEnd = startOffset * s.samplingInterval
			if(epochBegin != epochEnd)
				tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
				EP_AddEpoch(device, channel, XOP_CHANNEL_TYPE_DAC, epochBegin, epochEnd, tags, EPOCH_SN_BL_DDAQ, 0)
			endif
		endif

		if(s.terminationDelay)
			epochBegin = (startOffset + singleSetLength) * s.samplingInterval
			epochEnd = min(epochBegin + s.terminationDelay * s.samplingInterval, lastP * s.samplingInterval)

			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(device, channel, XOP_CHANNEL_TYPE_DAC, epochBegin, epochEnd, tags, EPOCH_SN_BL_TERMINATIONDELAY, 0)
		endif

		epochBegin = startOffset * s.samplingInterval
		if(s.distributedDAQOptOv && s.offsets[i] > 0)
			epochOffset = s.offsets[i] * MILLI_TO_MICRO

			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)

			EP_AddEpoch(device, channel, XOP_CHANNEL_TYPE_DAC, epochBegin, epochBegin + epochOffset, tags, EPOCH_SN_BL_DDAQOPT, 0)
			EP_AddEpochsFromStimSetNote(device, channel, XOP_CHANNEL_TYPE_DAC, s.samplingInterval, singleStimSet, epochBegin + epochOffset, singleSetLength * s.samplingInterval - epochOffset, stimsetCol, s.DACAmp[i][%DASCALE])
		else
			EP_AddEpochsFromStimSetNote(device, channel, XOP_CHANNEL_TYPE_DAC, s.samplingInterval, singleStimSet, epochBegin, singleSetLength * s.samplingInterval, stimsetCol, s.DACAmp[i][%DASCALE])
		endif

		if(s.distributedDAQOptOv)
			epochBegin = startOffset * s.samplingInterval
			epochEnd   = (startOffset + singleSetLength) * s.samplingInterval
			EP_AddEpochsFromOodDAQRegions(device, channel, s.regions[i], epochBegin, epochEnd)
		endif

		// if dDAQ is on then channels 0 to numEntries - 1 have a trailing base line
		epochBegin = startOffset + singleSetLength + s.terminationDelay
		if(lastP > epochBegin)
			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(device, channel, XOP_CHANNEL_TYPE_DAC, epochBegin * s.samplingInterval, lastP * s.samplingInterval, tags, EPOCH_SN_BL_GENERALTRAIL, 0)
		endif

		testPulseLength = s.testPulseLength * s.samplingInterval
		if(s.globalTPInsert)
			if(!isUnAssociated)
				// space in ITCDataWave for the testpulse is allocated via an automatic increase
				// of the onset delay
				EP_AddEpochsFromTP(device, s.samplingInterval, channel, s.DACAmp[i][%TPAMP])
			else
				tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
				EP_AddEpoch(device, channel, XOP_CHANNEL_TYPE_DAC, 0, testPulseLength, tags, EPOCH_SN_BL_UNASSOC_NOTP_BASELINE, 0)
			endif
		endif
	endfor
End

static Function EP_CollectEpochInfoTTL(string device, STRUCT DataConfigurationResult &s)

	variable i, channel, singleSetLength, stimsetCol, stopCollectionPoint, lastP
	variable epochBegin, epochEnd
	string tags

	stopCollectionPoint = ROVar(GetStopCollectionPoint(device))
	lastP = stopCollectionPoint - 1

	WAVE statusTTLFiltered = DC_GetFilteredChannelState(device, DATA_ACQUISITION_MODE, CHANNEL_TYPE_TTL)

	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!statusTTLFiltered[i])
			continue
		endif

		if(WB_StimsetIsFromThirdParty(s.TTLsetName[i]))
			continue
		endif

		WAVE singleStimSet = s.TTLstimSet[i]
		singleSetLength = s.TTLsetLength[i]
		stimsetCol = s.TTLsetColumn[i]

		if(s.globalTPInsert)
			// s.testPulseLength is a synonym for s.onsetDelayAuto
			epochBegin = 0
			epochEnd = s.testPulseLength
			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(device, i, XOP_CHANNEL_TYPE_TTL, epochBegin * s.samplingInterval, epochEnd * s.samplingInterval, tags, EPOCH_SN_BL_UNASSOC_NOTP_BASELINE, 0)
		endif
		if(s.onsetDelayUser)
			epochBegin = s.onsetDelayAuto
			// s.onsetDelay = s.onsetDelayUser + s.onsetDelayAuto
			epochEnd = s.onsetDelay

			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(device, i, XOP_CHANNEL_TYPE_TTL, epochBegin * s.samplingInterval, epochEnd * s.samplingInterval, tags, EPOCH_SN_BL_ONSETDELAYUSER, 0)
		endif

		epochBegin = s.onSetDelay
		EP_AddEpochsFromStimSetNote(device, i, XOP_CHANNEL_TYPE_TTL, s.samplingInterval, singleStimSet, epochBegin * s.samplingInterval, singleSetLength * s.samplingInterval, stimsetCol, NaN)

		if(s.terminationDelay)
			epochBegin = s.onSetDelay + singleSetLength
			epochEnd = min(epochBegin + s.terminationDelay, lastP)

			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(device, i, XOP_CHANNEL_TYPE_TTL, epochBegin * s.samplingInterval, epochEnd * s.samplingInterval, tags, EPOCH_SN_BL_TERMINATIONDELAY, 0)
		endif

		epochBegin = s.onSetDelay + singleSetLength + s.terminationDelay
		if(lastP > epochBegin)
			epochEnd = lastP
			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(device, i, XOP_CHANNEL_TYPE_TTL, epochBegin * s.samplingInterval, epochEnd * s.samplingInterval, tags, EPOCH_SN_BL_GENERALTRAIL, 0)
		endif

	endfor
End

/// @brief Adds four epochs for a test pulse and three sub epochs for test pulse components
/// @param[in] device           title of device panel
/// @param[in] samplingInterval samplingInterval in microSec
/// @param[in] channel          number of DA channel
/// @param[in] amplitude        amplitude of the TP in the DA wave without gain
static Function EP_AddEpochsFromTP(string device, variable samplingInterval, variable channel, variable amplitude)

	variable totalLengthPoints, pulseStartPoints, pulseLengthPoints
	variable epochBegin, epochEnd
	string epochTags, epochSubTags

	variable offset = 0

	[totalLengthPoints, pulseStartPoints, pulseLengthPoints] = TP_GetCreationPropertiesInPoints(device, DATA_ACQUISITION_MODE)

	epochTags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", "Inserted Testpulse", STIMSETKEYNAME_SEP, EPOCHNAME_SEP)

	// main TP range
	epochBegin = offset
	epochEnd = epochBegin + totalLengthPoints * samplingInterval
	EP_AddEpoch(device, channel, XOP_CHANNEL_TYPE_DAC, epochBegin, epochEnd, epochTags, EPOCH_SN_TP, 0)

	// TP sub ranges
	epochBegin = offset + pulseStartPoints * samplingInterval
	epochEnd = epochBegin + pulseLengthPoints * samplingInterval
	epochSubTags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, epochTags, EPOCH_PULSE_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	epochSubTags = ReplaceNumberByKey(EPOCH_AMPLITUDE_KEY, epochSubTags, amplitude, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	EP_AddEpoch(device, channel, XOP_CHANNEL_TYPE_DAC, epochBegin, epochEnd, epochSubTags, EPOCH_SN_TP_PULSE, 1)

	// pre pulse BL
	epochBegin = offset
	epochEnd = epochBegin + pulseStartPoints * samplingInterval
	epochSubTags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, epochTags, EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	EP_AddEpoch(device, channel, XOP_CHANNEL_TYPE_DAC, epochBegin, epochEnd, epochSubTags, EPOCH_SN_TP_BLFRONT, 1)

	// post pulse BL
	epochBegin = offset + (pulseStartPoints + pulseLengthPoints) * samplingInterval
	epochEnd = offset + totalLengthPoints * samplingInterval
	EP_AddEpoch(device, channel, XOP_CHANNEL_TYPE_DAC, epochBegin, epochEnd, epochSubTags, EPOCH_SN_TP_BLBACK, 1)
End

/// @brief Adds epochs for oodDAQ regions
/// @param[in] device    title of device panel
/// @param[in] channel       number of DA channel
/// @param[in] oodDAQRegions string containing list of oodDAQ regions as %d-%d;...
/// @param[in] stimsetBegin offset time in micro seconds where stim set begins
/// @param[in] stimsetEnd   offset time in micro seconds where stim set ends
static Function EP_AddEpochsFromOodDAQRegions(device, channel, oodDAQRegions, stimsetBegin, stimsetEnd)
	string device
	variable channel
	string oodDAQRegions
	variable stimsetBegin, stimsetEnd

	variable numRegions, first, last
	string tags

	WAVE/T regions = ListToTextWave(oodDAQRegions, ";")
	numRegions = DimSize(regions, ROWS)
	if(numRegions)
		Make/FREE/N=(numRegions) epochIndexer
		tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", "oodDAQ", STIMSETKEYNAME_SEP, EPOCHNAME_SEP)

		epochIndexer[] = EP_AddEpoch(device, channel, XOP_CHANNEL_TYPE_DAC, str2num(StringFromList(0, regions[p], "-")) * MILLI_TO_MICRO + stimsetBegin,          \
																						str2num(StringFromList(1, regions[p], "-")) * MILLI_TO_MICRO + stimsetBegin,             \
																						ReplaceNumberByKey(EPOCH_OODDAQ_REGION_KEY, tags, p, STIMSETKEYNAME_SEP, EPOCHNAME_SEP), \
																						EPOCH_SN_OODAQ + num2str(p),                                                             \
																						2, lowerLimit = stimsetBegin, upperLimit = stimsetEnd)
	endif
End

/// @brief Adds epochs for a stimset and sub epochs for stimset components
/// currently adds also sub sub epochs for pulse train components
/// @param[in] device           title of device panel
/// @param[in] channel          number of DA or TTL channel
/// @param[in] channelType      type of channel
/// @param[in] samplingInterval sampling interval in microsec
/// @param[in] stimset          stimset wave
/// @param[in] stimsetBegin     offset time in micro seconds where stim set begins
/// @param[in] setLength        length of stimset in micro seconds
/// @param[in] sweep            number of sweep
/// @param[in] scale            scale factor between the stimsets internal amplitude to the DA wave without gain
static Function EP_AddEpochsFromStimSetNote(string device, variable channel, variable channelType, variable samplingInterval, WAVE stimset, variable stimsetBegin, variable setLength, variable sweep, variable scale)

	variable stimsetEnd, stimsetEndLogical, functionType, stopCollectionPoint
	variable epochBegin, epochEnd, subEpochBegin, subEpochEnd
	string epSweepTags, epSubTags, epSubSubTags, tags, epSpecifier
	variable epochCount, totalDuration, poissonDistribution, cycleNr
	variable epochNr, pulseNr, numPulses, epochType, flipping, pulseToPulseLength, stimEpochAmplitude, amplitude, i, j
	variable pulseDuration, halfCycleNr, hasFullCycle, hasIncompleteCycleAtStart, hasIncompleteCycleAtEnd
	variable subsubEpochBegin, subsubEpochEnd, numInflectionPoints, incompleteCycleNr
	string type, startTimesList
	string shortNameEp, shortNameEpTypePT, shortNameEpTypePTPulse, shortNameEpTypePTPulseP, shortNameEpTypePTPulseB, shortNameEpTypePTPulseBT
	string shortNameEpTRIGCycle, shortNameEpTRIGIncomplete, shortNameEpTRIGHalfCycle, shortNameEpTypeTRIG_C, shortNameEpTypeTRIG_I
	string shortNameEpTypePTBaseline
	string stimNote = note(stimset)

	ASSERT(!IsEmpty(stimNote), "Stimset note is empty.")

	stopCollectionPoint = ROVar(GetStopCollectionPoint(device))

	scale = channelType == XOP_CHANNEL_TYPE_TTL ? 1 : scale

	stimsetEnd = min(stimsetBegin + setLength, (stopCollectionPoint - 1) * samplingInterval)
	epSweepTags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", "Stimset", STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	EP_AddEpoch(device, channel, channelType, stimsetBegin, stimsetEnd, epSweepTags, EPOCH_SN_STIMSET, 0)

	epochCount = WB_GetWaveNoteEntryAsNumber(stimNote, STIMSET_ENTRY, key="Epoch Count")
	ASSERT(IsFinite(epochCount), "Could not find Epoch Count in stimset wave note.")

	Make/FREE/D/N=(epochCount) duration, sweepOffset

	duration[] = WB_GetWaveNoteEntryAsNumber(stimNote, EPOCH_ENTRY, key="Duration", sweep=sweep, epoch=p)
	duration *= MILLI_TO_MICRO
	totalDuration = sum(duration)

	ASSERT(IsFinite(totalDuration), "Expected finite totalDuration")
	ASSERT(IsFinite(stimsetBegin), "Expected finite stimsetBegin")
	stimsetEndLogical = stimsetBegin + totalDuration

	if(epochCount > 1)
		sweepOffset[0] = 0
		sweepOffset[1,] = sweepOffset[p - 1] + duration[p - 1]
	endif

	flipping = WB_GetWaveNoteEntryAsNumber(stimNote, STIMSET_ENTRY, key = "Flip")

	epSweepTags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", "Epoch", STIMSETKEYNAME_SEP, EPOCHNAME_SEP)

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

		epSubTags = ReplaceStringByKey("EpochType", epSweepTags, type, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
		epSubTags = ReplaceNumberByKey("Epoch", epSubTags, epochNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
		epSubTags = ReplaceNumberByKey(EPOCH_AMPLITUDE_KEY, epSubTags, amplitude, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)

		epSpecifier = ""

		if(epochType == EPOCH_TYPE_PULSE_TRAIN)
			if(!CmpStr(WB_GetWaveNoteEntry(stimNote, EPOCH_ENTRY, sweep = sweep, epoch = epochNr, key = "Mixed frequency"), "True"))
				epSpecifier = "Mixed frequency"
			elseif(poissonDistribution)
				epSpecifier = "Poisson distribution"
			endif
			if(!CmpStr(WB_GetWaveNoteEntry(stimNote, EPOCH_ENTRY, key="Mixed frequency shuffle", sweep=sweep, epoch=epochNr), "True"))
				epSpecifier += " shuffled"
			endif
		endif

		if(!isEmpty(epSpecifier))
			epSubTags = ReplaceStringByKey("Details", epSubTags, epSpecifier, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
		endif

		shortNameEp = EPOCH_SN_EPOCH + num2istr(epochNr)
		EP_AddEpoch(device, channel, channelType, epochBegin, epochEnd, epSubTags, shortNameEp, 1, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)

		// Add Sub Sub Epochs
		if(epochType == EPOCH_TYPE_PULSE_TRAIN)
			shortNameEpTypePT = shortNameEp + "_" + EPOCH_SN_PULSETRAIN
			shortNameEpTypePTBaseline = shortNameEpTypePT + "_" + EPOCH_SN_PULSETRAINBASETRAIL
			WAVE startTimes = WB_GetPulsesFromPTSweepEpoch(stimset, sweep, epochNr, pulseToPulseLength)
			startTimes *= MILLI_TO_MICRO
			numPulses = DimSize(startTimes, ROWS)
			if(numPulses)
				Duplicate/FREE startTimes, ptp
				ptp[] = pulseToPulseLength ? pulseToPulseLength * MILLI_TO_MICRO : startTimes[p] - startTimes[limit(p - 1, 0, Inf)]
				pulseDuration = WB_GetWaveNoteEntryAsNumber(stimNote, EPOCH_ENTRY, key="Pulse duration", sweep=sweep, epoch=epochNr)
				pulseDuration *= MILLI_TO_MICRO

				// with flipping we iterate the pulses from large to small time points

				for(pulseNr = 0; pulseNr < numPulses; pulseNr += 1)
					shortNameEpTypePTPulse = shortNameEpTypePT + "_" + EPOCH_SN_PULSETRAIN_FULLPULSE + num2istr(pulseNr)
					shortNameEpTypePTPulseP = shortNameEpTypePTPulse + "_" + EPOCH_SN_PULSETRAIN_PULSEAMP
					shortNameEpTypePTPulseB = shortNameEpTypePTPulse + "_" + EPOCH_SN_PULSETRAIN_PULSEBASE
					shortNameEpTypePTPulseBT = shortNameEpTypePTPulse + "_" + EPOCH_SN_PULSETRAIN_PULSEBASETRAIL
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

							tags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, epSubTags, EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
							EP_AddEpoch(device, channel, channelType, epochBegin, subEpochBegin, tags, shortNameEpTypePTPulseBT, 2, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)
						endif

						epSubSubTags = ReplaceNumberByKey(EPOCH_PULSE_KEY, epSubTags, pulseNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
						EP_AddEpoch(device, channel, channelType, subEpochBegin, subEpochEnd, epSubSubTags, shortNameEpTypePTPulse, 2, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)

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

							epSubSubTags = ReplaceNumberByKey(EPOCH_PULSE_KEY, epSubTags, pulseNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
							epSubSubTags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, epSubSubTags, "Pulse", STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
							EP_AddEpoch(device, channel, channelType, subsubEpochBegin, subsubEpochEnd, epSubSubTags, shortNameEpTypePTPulseP, 3, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)

							// baseline
							subsubEpochBegin = subsubEpochEnd
							subsubEpochEnd   = subEpochEnd

							if(subsubEpochBegin >= stimsetEnd || subsubEpochEnd <= stimsetBegin)
								DEBUGPRINT("Warning: sub sub epoch of pulse active starts after stimset end or ends before stimset start.")
							elseif(subsubEpochBegin >= subsubEpochEnd)
								DEBUGPRINT("Warning: sub sub epoch of pulse baseline is not present.")
							else
								epSubSubTags = ReplaceNumberByKey(EPOCH_PULSE_KEY, epSubTags, pulseNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
								epSubSubTags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, epSubSubTags, EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
								EP_AddEpoch(device, channel, channelType, subsubEpochBegin, subsubEpochEnd, epSubSubTags, shortNameEpTypePTPulseB, 3, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)
							endif
						endif
					endif
				endfor
			else
				tags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
				EP_AddEpoch(device, channel, channelType, epochBegin, epochEnd, tags, shortNameEpTypePTBaseline, 2, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)
			endif
		elseif(epochType == EPOCH_TYPE_SIN_COS)
			WAVE inflectionPoints = WB_GetInflectionPoints(stimset, sweep, epochNr)

			if(!WaveExists(inflectionPoints))
				continue
			endif

			numInflectionPoints = DimSize(inflectionPoints, ROWS)

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
					EP_AddEpoch(device, channel, channelType, subEpochBegin, subEpochEnd, epSubSubTags, shortNameEpTRIGIncomplete, 2, lowerlimit = epochBegin, upperlimit = epochEnd)
					incompleteCycleNr++
				continue
			endif

			inflectionPoints *= MILLI_TO_MICRO

			if(flipping)
				inflectionPoints[] = (epochEnd - epochBegin) - inflectionPoints[p]
				WaveTransform/O flip, inflectionPoints
			endif

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
				hasIncompleteCycleAtStart = (i == 0 && inflectionPoints[i] != 0)
				hasIncompleteCycleAtEnd   = !hasFullCycle || (i + 1 >= numInflectionPoints)

				if(!hasFullCycle || hasIncompleteCycleAtStart)
					if(hasIncompleteCycleAtStart)
						subEpochBegin = epochBegin
					else
						subEpochBegin = epochBegin + inflectionPoints[i]
					endif

					if(hasIncompleteCycleAtEnd)
						subEpochEnd = epochEnd
					else
						subEpochEnd = epochBegin + inflectionPoints[i]
					endif

					// add incomplete cycle epoch if it is not-empty
					if(subEpochBegin != subEpochEnd)
						shortNameEpTRIGIncomplete = shortNameEpTypeTRIG_I + num2istr(incompleteCycleNr)
						epSubSubTags = ReplaceNumberByKey(EPOCH_INCOMPLETE_CYCLE_KEY, epSubTags, incompleteCycleNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
						EP_AddEpoch(device, channel, channelType, subEpochBegin, subEpochEnd, epSubSubTags, shortNameEpTRIGIncomplete, 2, lowerlimit = epochBegin, upperlimit = epochEnd)
						incompleteCycleNr++
					endif
				endif

				if(hasFullCycle)
					cycleNr = i / 2
					subEpochBegin = epochBegin + inflectionPoints[i]
					subEpochEnd   = epochBegin + inflectionPoints[i + 2]
					shortNameEpTRIGCycle = shortNameEpTypeTRIG_C + num2istr(cycleNr)
					epSubSubTags = ReplaceNumberByKey(EPOCH_CYCLE_KEY, epSubTags, cycleNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
					EP_AddEpoch(device, channel, channelType, subEpochBegin, subEpochEnd, epSubSubTags, shortNameEpTRIGCycle, 2, lowerlimit = epochBegin, upperlimit = epochEnd)

					// add half cycles, only for full cycles
					for(j = 0; j < 2; j += 1)
						subsubEpochBegin = epochBegin + inflectionPoints[i + j]
						subsubEpochEnd   = epochBegin + inflectionPoints[i + j + 1]

						halfCycleNr = IsEven(j) ? 0 : 1
						shortNameEpTRIGHalfCycle = shortNameEpTRIGCycle + "_" + EPOCH_SN_TRIG_HALF_CYCLE + num2istr(halfCycleNr)
						epSubSubTags = ReplaceNumberByKey(EPOCH_CYCLE_KEY, epSubTags, cycleNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
						epSubSubTags = ReplaceNumberByKey(EPOCH_HALF_CYCLE_KEY, epSubSubTags, halfCycleNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
						EP_AddEpoch(device, channel, channelType, subsubEpochBegin, subsubEpochEnd, epSubSubTags, shortNameEpTRIGHalfCycle, 3, lowerlimit = subEpochBegin, upperlimit = subEpochEnd)
					endfor
				endif
			endfor
		else
			// Epoch details on other types not implemented yet
		endif

	endfor

	// stimsets with multiple sweeps where each sweep has a different length (due to delta mechanism)
	// result in 2D stimset waves where all sweeps have the same length
	// therefore we must add a baseline epoch after all defined epochs
	if(stimsetEnd > stimsetEndLogical)
		tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
		EP_AddEpoch(device, channel, channelType, stimsetEndLogical, stimsetEnd, tags, EPOCH_SN_STIMSET + "_" + EPOCH_SN_STIMSETBLTRAIL, 1)
	endif
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
/// @param[in] device title of device panel
static Function EP_SortEpochs(string device)

	variable channel, channelCnt, epochCnt, channelType

	WAVE/T epochWave = GetEpochsWave(device)
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

	if(ParamIsDefault(shortName))
		WAVE/T epochWave = GetEpochsWave(device)
		sprintf shortName, "%s%d", EPOCH_SHORTNAME_USER_PREFIX,  EP_GetEpochCount(epochWave, channelNumber, channelType)
	else
		ASSERT(!GrepString(shortName, "^" + EPOCH_SHORTNAME_USER_PREFIX), "short name must not be prefixed with " + EPOCH_SHORTNAME_USER_PREFIX)
		shortName = EPOCH_SHORTNAME_USER_PREFIX + shortName
	endif

	return EP_AddEpoch(device, channelNumber, channelType, epBegin * ONE_TO_MICRO, epEnd * ONE_TO_MICRO, tags, shortName, EPOCH_USER_LEVEL)
End

/// @brief Adds a epoch to the epochsWave
/// @param[in] device  title of device panel
/// @param[in] channel     number of DA/TTL channel
/// @param[in] channelType type of channel (either DA or TTL)
/// @param[in] epBegin     start time of the epoch in micro seconds
/// @param[in] epEnd       end time of the epoch in micro seconds
/// @param[in] epTags      tags of the epoch
/// @param[in] epShortName short name of the epoch, should be unique
/// @param[in] level       level of epoch
/// @param[in] lowerlimit  [optional, default = -Inf] epBegin is limited between lowerlimit and Inf, epEnd must be > this limit
/// @param[in] upperlimit  [optional, default = Inf] epEnd is limited between -Inf and upperlimit, epBegin must be < this limit
static Function EP_AddEpoch(device, channel, channelType, epBegin, epEnd, epTags, epShortName, level, [lowerlimit, upperlimit])
	string device
	variable channel, channelType
	variable epBegin, epEnd
	string epTags, epShortName
	variable level
	variable lowerlimit, upperlimit

	WAVE/T epochWave = GetEpochsWave(device)
	variable i, j, numEpochs, pos
	string entry, startTimeStr, endTimeStr

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
End

/// @brief Write the epoch info into the sweep settings wave
///
/// @param device       device
/// @param sweepNo      sweep Number
/// @param acquiredTime actual acquired time in seconds, if acquisition was stopped early lower than plannedTime
/// @param plannedTime  planned acquisition time in seconds, if acquisition was not stopped early equals acquiredTime
Function EP_WriteEpochInfoIntoSweepSettings(string device, variable sweepNo, variable acquiredTime, variable plannedTime)
	variable i, numDACEntries, channel, headstage
	string entry

	[WAVE sweepWave, WAVE configWave] = GetSweepAndConfigWaveFromDevice(device, sweepNo)

	EP_AdaptEpochInfo(device, configWave, acquiredTime, plannedTime)

	EP_SortEpochs(device)

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
/// @param device    device
/// @param configWave    DAQ config wave
/// @param acquiredTime  Last acquired time point [s]
/// @param plannedTime   Last time point in the sweep [s]
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

	variable epochCnt, epoch, startTime, endTime
	string tags

	WAVE/T epochWave = GetEpochsWave(device)

	epochCnt = EP_GetEpochCount(epochWave, channelNumber, channelType)

	for(epoch = 0; epoch < epochCnt; epoch += 1)
		startTime = str2num(epochWave[epoch][%StartTime][channelNumber][channelType])
		endTime   = str2num(epochWave[epoch][%EndTime][channelNumber][channelType])

		if(acquiredTime >= endTime)
			continue
		endif

		if(acquiredTime < startTime || abs(acquiredTime - startTime) <= 10^(-EPOCHTIME_PRECISION))
			// lies completely outside the acquired region
			// mark it for deletion
			epochWave[epoch][%StartTime][channelNumber][channelType] = "NaN"
			epochWave[epoch][%EndTime][channelNumber][channelType]   = "NaN"
		else
			// epoch was cut off
			epochWave[epoch][%EndTime][channelNumber][channelType] = num2strHighPrec(acquiredTime, precision = EPOCHTIME_PRECISION)
		endif
	endfor

	// add unacquired epoch
	// relies on EP_AddEpoch ignoring single point epochs
	tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", "Unacquired", STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	EP_AddEpoch(device, channelNumber, channelType, acquiredTime * ONE_TO_MICRO , plannedTime * ONE_TO_MICRO, tags , EPOCH_SN_UNACQUIRED, 0)
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
