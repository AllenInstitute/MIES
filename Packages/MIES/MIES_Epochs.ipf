#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_EP
#endif

/// @file MIES_Epochs.ipf
/// @brief __EP__ Handle code relating to epoch information

static StrConstant EPOCH_SHORTNAME_KEY = "ShortName"
static StrConstant EPOCH_TYPE_KEY      = "Type"
static StrConstant EPOCH_SUBTYPE_KEY   = "SubType"
static StrConstant EPOCH_AMPLITUDE_KEY = "Amplitude"
static StrConstant EPOCH_PULSE_KEY     = "Pulse"

static StrConstant EPOCHNAME_SEP = ";"
static StrConstant STIMSETKEYNAME_SEP = "="
static StrConstant SHORTNAMEKEY_SEP = "="

static StrConstant EPOCH_SN_BL_ONSETDELAYUSER = "B0_OD"
static StrConstant EPOCH_SN_BL_DDAQ = "B0_DD"
static StrConstant EPOCH_SN_BL_TERMINATIONDELAY = "B0_TD"
static StrConstant EPOCH_SN_BL_DDAQOPT = "B0_DO"
static StrConstant EPOCH_SN_BL_DDAQTRAIL = "B0_TR"
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
static StrConstant EPOCH_SN_UNACQUIRED = "UA"

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
	variable i, channel, headstage, singleSetLength, epochOffset, epochBegin, epochEnd
	variable stimsetCol, startOffset, stopCollectionPoint
	string tags

	if(s.dataAcqOrTP != DATA_ACQUISITION_MODE)
		return NaN
	endif

	WAVE config = GetDAQConfigWave(device)

	stopCollectionPoint = ROVar(GetStopCollectionPoint(device))

	for(i = 0; i < s.numDACEntries; i += 1)

		if(WB_StimsetIsFromThirdParty(s.setName[i]) || !cmpstr(s.setName[i], STIMSET_TP_WHILE_DAQ))
			continue
		endif

		channel = s.DACList[i]
		headstage = s.headstageDAC[i]
		startOffset = s.insertStart[i]
		singleSetLength = s.setLength[i]
		WAVE singleStimSet = s.stimSet[i]
		stimsetCol = s.setColumn[i]

		// epoch for onsetDelayAuto is assumed to be a globalTPInsert which is added as epoch below
		if(s.onsetDelayUser)
			epochBegin = s.onsetDelayAuto * s.samplingInterval
			epochEnd = epochBegin + s.onsetDelayUser * s.samplingInterval

			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(device, channel, epochBegin, epochEnd, tags, EPOCH_SN_BL_ONSETDELAYUSER, 0)
		endif

		if(s.distributedDAQ)
			epochBegin = s.onsetDelay * s.samplingInterval
			epochEnd = startOffset * s.samplingInterval
			if(epochBegin != epochEnd)
				tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
				EP_AddEpoch(device, channel, epochBegin, epochEnd, tags, EPOCH_SN_BL_DDAQ, 0)
			endif
		endif

		if(s.terminationDelay)
			epochBegin = (startOffset + singleSetLength) * s.samplingInterval

			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(device, channel, epochBegin, epochBegin + s.terminationDelay * s.samplingInterval, tags, EPOCH_SN_BL_TERMINATIONDELAY, 0)
		endif

		epochBegin = startOffset * s.samplingInterval
		if(s.distributedDAQOptOv && s.offsets[i] > 0)
			epochOffset = s.offsets[i] * 1000

			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)

			EP_AddEpoch(device, channel, epochBegin, epochBegin + epochOffset, tags, EPOCH_SN_BL_DDAQOPT, 0)
			EP_AddEpochsFromStimSetNote(device, channel, singleStimSet, epochBegin + epochOffset, singleSetLength * s.samplingInterval - epochOffset, stimsetCol, s.DACAmp[i][%DASCALE])
		else
			EP_AddEpochsFromStimSetNote(device, channel, singleStimSet, epochBegin, singleSetLength * s.samplingInterval, stimsetCol, s.DACAmp[i][%DASCALE])
		endif

		if(s.distributedDAQOptOv)
			epochBegin = startOffset * s.samplingInterval
			epochEnd   = (startOffset + singleSetLength) * s.samplingInterval
			EP_AddEpochsFromOodDAQRegions(device, channel, s.regions[i], epochBegin, epochEnd)
		endif

		// if dDAQ is on then channels 0 to numEntries - 1 have a trailing base line
		epochBegin = startOffset + singleSetLength + s.terminationDelay
		if(stopCollectionPoint > epochBegin)
			tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
			EP_AddEpoch(device, channel, epochBegin * s.samplingInterval, stopCollectionPoint * s.samplingInterval, tags, EPOCH_SN_BL_DDAQTRAIL, 0)
		endif

		if(s.globalTPInsert)
			// space in ITCDataWave for the testpulse is allocated via an automatic increase
			// of the onset delay
			EP_AddEpochsFromTP(device, channel, s.baselinefrac, s.testPulseLength * s.samplingInterval, 0, s.DACAmp[i][%TPAMP])
		endif
	endfor
End

/// @brief Adds four epochs for a test pulse and three sub epochs for test pulse components
/// @param[in] device      title of device panel
/// @param[in] channel         number of DA channel
/// @param[in] baselinefrac    base line fraction of testpulse
/// @param[in] testPulseLength test pulse length in micro seconds
/// @param[in] offset          start time of test pulse in micro seconds
/// @param[in] amplitude       amplitude of the TP in the DA wave without gain
static Function EP_AddEpochsFromTP(device, channel, baselinefrac, testPulseLength, offset, amplitude)
	string device
	variable channel
	variable baselinefrac, testPulseLength
	variable offset
	variable amplitude

	variable epochBegin
	variable epochEnd
	string epochTags, epochSubTags

	epochTags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", "Inserted Testpulse", STIMSETKEYNAME_SEP, EPOCHNAME_SEP)

	// main TP range
	epochBegin = offset
	epochEnd = epochBegin + testPulseLength
	EP_AddEpoch(device, channel, epochBegin, epochEnd, epochTags, EPOCH_SN_TP, 0)

	// TP sub ranges
	epochBegin = baselineFrac * testPulseLength + offset
	epochEnd = (1 - baselineFrac) * testPulseLength + offset
	epochSubTags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, epochTags, EPOCH_PULSE_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	epochSubTags = ReplaceNumberByKey(EPOCH_AMPLITUDE_KEY, epochSubTags, amplitude, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	EP_AddEpoch(device, channel, epochBegin, epochEnd, epochSubTags, EPOCH_SN_TP_PULSE, 1)

	// pre pulse BL
	epochBegin = offset
	epochEnd = epochBegin + baselineFrac * testPulseLength
	epochSubTags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, epochTags, EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	EP_AddEpoch(device, channel, epochBegin, epochEnd, epochSubTags, EPOCH_SN_TP_BLFRONT, 1)

	// post pulse BL
	epochBegin = (1 - baselineFrac) * testPulseLength + offset
	epochEnd = testPulseLength + offset
	EP_AddEpoch(device, channel, epochBegin, epochEnd, epochSubTags, EPOCH_SN_TP_BLBACK, 1)
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

		epochIndexer[] = EP_AddEpoch(device, channel, str2num(StringFromList(0, regions[p], "-")) * 1E3 + stimsetBegin,                        \
		                                                  str2num(StringFromList(1, regions[p], "-")) * 1E3 + stimsetBegin,                        \
		                                                  ReplaceNumberByKey(EPOCH_OODDAQ_REGION_KEY, tags, p, STIMSETKEYNAME_SEP, EPOCHNAME_SEP), \
		                                                  EPOCH_SN_OODAQ + num2str(p),                                                             \
		                                                  2, lowerLimit = stimsetBegin, upperLimit = stimsetEnd)
	endif
End

/// @brief Adds epochs for a stimset and sub epochs for stimset components
/// currently adds also sub sub epochs for pulse train components
/// @param[in] device   title of device panel
/// @param[in] channel      number of DA channel
/// @param[in] stimset      stimset wave
/// @param[in] stimsetBegin offset time in micro seconds where stim set begins
/// @param[in] setLength    length of stimset in micro seconds
/// @param[in] sweep        number of sweep
/// @param[in] scale        scale factor between the stimsets internal amplitude to the DA wave without gain
static Function EP_AddEpochsFromStimSetNote(device, channel, stimset, stimsetBegin, setLength, sweep, scale)
	string device
	variable channel
	WAVE stimset
	variable stimsetBegin, setLength, sweep, scale

	variable stimsetEnd, stimsetEndLogical
	variable epochBegin, epochEnd, subEpochBegin, subEpochEnd
	string epSweepTags, epSubTags, epSubSubTags, tags, epSpecifier
	variable epochCount, totalDuration, poissonDistribution
	variable epochNr, pulseNr, numPulses, epochType, flipping, pulseToPulseLength, stimEpochAmplitude, amplitude
	variable pulseDuration
	variable subsubEpochBegin, subsubEpochEnd
	string type, startTimesList
	string shortNameEp, shortNameEpTypePT, shortNameEpTypePTPulse, shortNameEpTypePTPulseP, shortNameEpTypePTPulseB, shortNameEpTypePTPulseBT
	string shortNameEpTypePTBaseline
	string stimNote = note(stimset)

	ASSERT(!IsEmpty(stimNote), "Stimset note is empty.")

	stimsetEnd = stimsetBegin + setLength
	epSweepTags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", "Stimset", STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	EP_AddEpoch(device, channel, stimsetBegin, stimsetEnd, epSweepTags, EPOCH_SN_STIMSET, 0)

	epochCount = WB_GetWaveNoteEntryAsNumber(stimNote, STIMSET_ENTRY, key="Epoch Count")
	ASSERT(IsFinite(epochCount), "Could not find Epoch Count in stimset wave note.")

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
		EP_AddEpoch(device, channel, epochBegin, epochEnd, epSubTags, shortNameEp, 1, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)

		// Add Sub Sub Epochs
		if(epochType == EPOCH_TYPE_PULSE_TRAIN)
			shortNameEpTypePT = shortNameEp + "_" + EPOCH_SN_PULSETRAIN
			shortNameEpTypePTBaseline = shortNameEpTypePT + "_" + EPOCH_SN_PULSETRAINBASETRAIL
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
							EP_AddEpoch(device, channel, epochBegin, subEpochBegin, tags, shortNameEpTypePTPulseBT, 2, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)
						endif

						epSubSubTags = ReplaceNumberByKey(EPOCH_PULSE_KEY, epSubTags, pulseNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
						EP_AddEpoch(device, channel, subEpochBegin, subEpochEnd, epSubSubTags, shortNameEpTypePTPulse, 2, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)

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
							EP_AddEpoch(device, channel, subsubEpochBegin, subsubEpochEnd, epSubSubTags, shortNameEpTypePTPulseP, 3, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)

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
								EP_AddEpoch(device, channel, subsubEpochBegin, subsubEpochEnd, epSubSubTags, shortNameEpTypePTPulseB, 3, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)
							endif
						endif
					endif
				endfor
			else
				tags = ReplaceStringByKey(EPOCH_SUBTYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
				EP_AddEpoch(device, channel, epochBegin, epochEnd, tags, shortNameEpTypePTBaseline, 2, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)
			endif
		else
			// Epoch details on other types not implemented yet
		endif

	endfor

	// stimsets with multiple sweeps where each sweep has a different length (due to delta mechanism)
	// result in 2D stimset waves where all sweeps have the same length
	// therefore we must add a baseline epoch after all defined epochs
	if(stimsetEnd > stimsetEndLogical)
		tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", EPOCH_BASELINE_REGION_KEY, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
		EP_AddEpoch(device, channel, stimsetEndLogical, stimsetEnd, tags, EPOCH_SN_STIMSET + "_" + EPOCH_SN_STIMSETBLTRAIL, 1)
	endif
End

/// @brief Sorts all epochs per channel in EpochsWave
///
/// Removes epochs marked for removal, those with NaN as StartTime and EndTime, as well.
///
/// Sorting:
/// - Ascending starting time
/// - Descending ending time
/// - Ascending tree level
///
/// @param[in] device title of device panel
static Function EP_SortEpochs(device)
	string device

	variable channel, channelCnt, epochCnt
	WAVE/T epochWave = GetEpochsWave(device)
	channelCnt = DimSize(epochWave, LAYERS)
	for(channel = 0; channel < channelCnt; channel += 1)
		epochCnt = EP_GetEpochCount(device, channel)
		if(epochCnt == 0)
			continue
		endif

		Duplicate/FREE/T/RMD=[, epochCnt - 1][][channel] epochWave, epochChannel
		Redimension/N=(-1, -1, 0) epochChannel

		epochChannel[][%EndTime] = num2strHighPrec(-1 * str2num(epochChannel[p][%EndTime]), precision = EPOCHTIME_PRECISION)
		SortColumns/DIML/KNDX={EPOCH_COL_STARTTIME, EPOCH_COL_ENDTIME, EPOCH_COL_TREELEVEL} sortWaves={epochChannel}
		epochChannel[][%EndTime] = num2strHighPrec(-1 * str2num(epochChannel[p][%EndTime]), precision = EPOCHTIME_PRECISION)

		// remove epochs marked for removal
		// first column needs to be StartTime
		ASSERT(EPOCH_COL_STARTTIME == 0, "First column changed")
		RemoveTextWaveEntry1D(epochChannel, "NaN", all = 1)

		epochCnt = DimSize(epochChannel, ROWS)

		if(epochCnt > 0)
			epochWave[, epochCnt - 1][][channel] = epochChannel[p][q]
		endif

		epochWave[epochCnt, *][][channel] = ""
	endfor
End

/// @brief Returns the number of epoch in the epochsWave for the given channel
/// @param[in] device title of device panel
/// @param[in] channel    number of DA channel
/// @return number of epochs for channel
static Function EP_GetEpochCount(device, channel)
	string device
	variable channel

	WAVE/T epochWave = GetEpochsWave(device)
	FindValue/Z/RMD=[][][channel]/TXOP=4/TEXT="" epochWave
	return V_row == -1 ? DimSize(epochWave, ROWS) : V_row
End

/// @brief Add user epochs
///
/// Allows to add user epochs for not yet finished sweeps. The tree level
/// is fixed to #EPOCH_USER_LEVEL to not collide with stock entries.
///
/// @param device    device
/// @param channelType   channel type, currently only #XOP_CHANNEL_TYPE_DAC is supported
/// @param channelNumber channel number
/// @param epBegin       start time of the epoch in seconds
/// @param epEnd         end time of the epoch in seconds
/// @param tags          tags for the epoch
/// @param shortName     [optional, defaults to auto-generated] user defined short name for the epoch, will
///                      be prefixed with #EPOCH_SHORTNAME_USER_PREFIX
Function EP_AddUserEpoch(string device, variable channelType, variable channelNumber, variable epBegin, variable epEnd, string tags, [string shortName])

	ASSERT(channelType == XOP_CHANNEL_TYPE_DAC, "Currently only epochs for the DA channels are supported")

	if(ParamIsDefault(shortName))
		sprintf shortName, "%s%d", EPOCH_SHORTNAME_USER_PREFIX,  EP_GetEpochCount(device, channelNumber)
	else
		ASSERT(!GrepString(shortName, "^" + EPOCH_SHORTNAME_USER_PREFIX), "short name must not be prefixed with " + EPOCH_SHORTNAME_USER_PREFIX)
		shortName = EPOCH_SHORTNAME_USER_PREFIX + shortName
	endif

	return EP_AddEpoch(device, channelNumber, epBegin * 1e6, epEnd * 1e6, tags, shortName, EPOCH_USER_LEVEL)
End

/// @brief Adds a epoch to the epochsWave
/// @param[in] device  title of device panel
/// @param[in] channel     number of DA channel
/// @param[in] epBegin     start time of the epoch in micro seconds
/// @param[in] epEnd       end time of the epoch in micro seconds
/// @param[in] epTags      tags of the epoch
/// @param[in] epShortName short name of the epoch, should be unique
/// @param[in] level       level of epoch
/// @param[in] lowerlimit  [optional, default = -Inf] epBegin is limited between lowerlimit and Inf, epEnd must be > this limit
/// @param[in] upperlimit  [optional, default = Inf] epEnd is limited between -Inf and upperlimit, epBegin must be < this limit
static Function EP_AddEpoch(device, channel, epBegin, epEnd, epTags, epShortName, level[, lowerlimit, upperlimit])
	string device
	variable channel
	variable epBegin, epEnd
	string epTags, epShortName
	variable level
	variable lowerlimit, upperlimit

	WAVE/T epochWave = GetEpochsWave(device)
	variable i, j, numEpochs, pos
	string entry, startTimeStr, endTimeStr

	lowerlimit = ParamIsDefault(lowerlimit) ? -Inf : lowerlimit
	upperlimit = ParamIsDefault(upperlimit) ? Inf : upperlimit

	ASSERT(!isNull(epTags), "Epoch name is null")
	ASSERT(!isEmpty(epTags), "Epoch name is empty")
	ASSERT(!isEmpty(epShortName), "Epoch short name is empty")
	ASSERT(epBegin <= epEnd, "Epoch end is < epoch begin")
	ASSERT(epBegin < upperlimit, "Epoch begin is greater than upper limit")
	ASSERT(epEnd > lowerlimit, "Epoch end lesser than lower limit")
	ASSERT(channel >=0 && channel < NUM_DA_TTL_CHANNELS, "channel is out of range")
	ASSERT(!GrepString(epTags, EPOCH_TAG_INVALID_CHARS_REGEXP), "Epoch name contains invalid characters: " + EPOCH_TAG_INVALID_CHARS_REGEXP)

	epBegin = limit(epBegin, lowerlimit, Inf)
	epEnd = limit(epEnd, -Inf, upperlimit)

	i = EP_GetEpochCount(device, channel)
	EnsureLargeEnoughWave(epochWave, minimumSize = i + 1, dimension = ROWS)

	startTimeStr = num2strHighPrec(epBegin / 1E6, precision = EPOCHTIME_PRECISION)
	endTimeStr = num2strHighPrec(epEnd / 1E6, precision = EPOCHTIME_PRECISION)

	if(!cmpstr(startTimeStr, endTimeStr))
		// don't add single point epochs
		return NaN
	endif

	epTags = ReplaceStringByKey(EPOCH_SHORTNAME_KEY, epTags, epShortName, SHORTNAMEKEY_SEP)

	epochWave[i][%StartTime][channel] = startTimeStr
	epochWave[i][%EndTime][channel] = endTimeStr
	epochWave[i][%Tags][channel] = epTags
	epochWave[i][%TreeLevel][channel] = num2str(level)
End

/// @brief Write the epoch info into the sweep settings wave
///
/// @param device device
/// @param sweepWave  sweep wave
/// @param configWave config wave
Function EP_WriteEpochInfoIntoSweepSettings(string device, WAVE sweepWave, WAVE configWave)
	variable i, numDACEntries, channel, headstage, acquiredTime, plannedTime
	string entry

	// all channels are acquired simultaneously we can just check if the last
	// channel has NaN in the last element
	if(IsNaN(sweepWave[inf][inf]))
		FindValue/FNAN sweepWave
		ASSERT(V_row >= 0, "Unexpected result")

		acquiredTime = IndexToScale(sweepWave, max(V_row - 1, 0), ROWS) / 1e3
		plannedTime  = IndexToScale(sweepWave, DimSize(sweepWave, ROWS) - 1, ROWS) / 1e3
		EP_AdaptEpochInfo(device, configWave, acquiredTime, plannedTime)
	endif

	EP_SortEpochs(device)

	WAVE DACList = GetDACListFromConfig(configWave)
	numDACEntries = DimSize(DACList, ROWS)

	WAVE/T epochsWave = GetEpochsWave(device)

	for(i = 0; i < numDACEntries; i += 1)
		channel = DACList[i]
		headstage = AFH_GetHeadstageFromDAC(device, channel)

		entry = EP_EpochWaveToStr(epochsWave, channel)
		DC_DocumentChannelProperty(device, EPOCHS_ENTRY_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, str=entry)
	endfor

	DC_DocumentChannelProperty(device, "Epochs Version", INDEP_HEADSTAGE, NaN, NaN, var=SWEEP_EPOCH_VERSION)
End

/// @brief Convert the epochs wave layer given by `channel` to a string suitable for storing the labnotebook
///
/// @param epochsWave wave with epoch information
/// @param channel    DA channel
threadsafe Function/S EP_EpochWaveToStr(WAVE epochsWave, variable channel)
	Duplicate/FREE/RMD=[][][channel] epochsWave, epochChannel
	Redimension/N=(-1, -1, 0) epochChannel

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
	variable i, channel, epoch, numEntries, endTime, startTime, epochCnt
	string tags

	WAVE/T epochWave = GetEpochsWave(device)

	numEntries = DimSize(configWave, ROWS)
	for(i = 0; i < numEntries; i += 1)
		if(configWave[i][%ChannelType] != XOP_CHANNEL_TYPE_DAC)
			// no more DACs, we are done
			break
		endif

		if(configWave[i][%DAQChannelType] != DAQ_CHANNEL_TYPE_DAQ)
			// skip all other channel types
			 continue
		endif

		channel = configWave[i][%ChannelNumber]

		epochCnt = EP_GetEpochCount(device, channel)
		ASSERT(epochCnt > 0, "Unexpected epoch count of zero")

		for(epoch = 0; epoch < epochCnt; epoch += 1)
			startTime = str2num(epochWave[epoch][%StartTime][channel])
			endTime   = str2num(epochWave[epoch][%EndTime][channel])

			if(acquiredTime >= endTime)
				continue
			endif

			if(acquiredTime < startTime || abs(acquiredTime - startTime) <= 10^(-EPOCHTIME_PRECISION))
				// lies completely outside the acquired region
				// mark it for deletion
				epochWave[epoch][%StartTime][channel] = "NaN"
				epochWave[epoch][%EndTime][channel]   = "NaN"
			else
				// epoch was cut off
				epochWave[epoch][%EndTime][channel] = num2strHighPrec(acquiredTime, precision = EPOCHTIME_PRECISION)
			endif
		endfor

		// add unacquired epoch
		// relies on EP_AddEpoch ignoring single point epochs
		tags = ReplaceStringByKey(EPOCH_TYPE_KEY, "", "Unacquired", STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
		EP_AddEpoch(device, channel, acquiredTime * 1e6 , plannedTime * 1e6, tags , EPOCH_SN_UNACQUIRED, 0)
	endfor
End

/// @brief Get epochs from the LBN filtered by given parameters
///
/// @param numericalValues Numerical values from the labnotebook
/// @param textualValues   Textual values from the labnotebook
/// @param sweepNo         Number of sweep
/// @param channelType     type of channel @sa XopChannelConstants
/// @param channelNumber   number of channel
/// @param shortname       short name filter, can be a regular expression which is matched caseless
/// @param treelevel       [optional: default = not set] tree level of epochs, if not set then treelevel is ignored
///
/// @returns Text wave with epoch information, only rows fitting the input parameters are returned. Can also be a null wave.
Function/WAVE EP_GetEpochs(WAVE numericalValues, WAVE textualValues, variable sweepNo, variable channelType, variable channelNumber, string shortname[, variable treelevel])

	variable index, epochCnt

	ASSERT(channelType == XOP_CHANNEL_TYPE_DAC, "Only channelType XOP_CHANNEL_TYPE_DAC is supported")
	treelevel = ParamIsDefault(treelevel) ? NaN : treelevel

	WAVE/Z settings
	[settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, EPOCHS_ENTRY_KEY, channelNumber, channelType, DATA_ACQUISITION_MODE)
	if(!WaveExists(settings))
		return $""
	endif

	WAVE/T settingsT = settings
	WAVE/T epochInfo = EP_EpochStrToWave(settingsT[index])
	epochCnt = DimSize(epochInfo, ROWS)

	if(IsNaN(treelevel))
		Make/FREE/N=(epochCnt) indizesLevel = p
	else
		WAVE/Z indizesLevel = FindIndizes(epochInfo, col = EPOCH_COL_TREELEVEL, var = treelevel)

		if(!WaveExists(indizesLevel))
			return $""
		endif
	endif

	// @todo add support for grepping in FindIndizes later
	Make/FREE/N=(epochCnt) indizesName = GrepString(EP_GetShortName(epochInfo[p][EPOCH_COL_TAGS]), "(?i)" + shortName) ? p : NaN

	WAVE/Z indizes = GetSetIntersection(indizesLevel, indizesName)
	if(!WaveExists(indizes))
		return $""
	endif

	Make/FREE/T/N=(DimSize(indizes, ROWS), DimSize(epochInfo, COLS)) matches = epochInfo[indizes[p]][q]

	SortColumns/KNDX={EPOCH_COL_STARTTIME} sortWaves={matches}

	return matches
End
