#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_EP
#endif

/// @file MIES_Epochs.ipf
/// @brief __EP__ Handle code relating to epoch information

static StrConstant EPOCH_SHORTNAME_KEY = "ShortName"
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

/// @brief Clear the list of epochs
Function EP_ClearEpochs(string panelTitle)

	WAVE/T epochWave = GetEpochsWave(panelTitle)
	epochWave = ""
End

/// @brief Fill the epoch wave with epochs before DAQ/TP
///
/// @param panelTitle device
/// @param s          struct holding all input
Function EP_CollectEpochInfo(string panelTitle, STRUCT DataConfigurationResult &s)
	variable i, channel, headstage, singleSetLength, epochOffset, epochBegin, epochEnd
	variable stimsetCol, startOffset, stopCollectionPoint

	if(s.dataAcqOrTP != DATA_ACQUISITION_MODE)
		return NaN
	endif

	WAVE config = GetDAQConfigWave(panelTitle)

	stopCollectionPoint = ROVar(GetStopCollectionPoint(panelTitle))

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
			EP_AddEpoch(panelTitle, channel, epochBegin, epochEnd, EPOCH_BASELINE_REGION_KEY, EPOCH_SN_BL_ONSETDELAYUSER, 0)
		endif

		if(s.distributedDAQ)
			epochBegin = s.onsetDelay * s.samplingInterval
			epochEnd = startOffset * s.samplingInterval
			if(epochBegin != epochEnd)
				EP_AddEpoch(panelTitle, channel, epochBegin, epochEnd, EPOCH_BASELINE_REGION_KEY, EPOCH_SN_BL_DDAQ, 0)
			endif
		endif

		if(s.terminationDelay)
			epochBegin = (startOffset + singleSetLength) * s.samplingInterval
			EP_AddEpoch(panelTitle, channel, epochBegin, epochBegin + s.terminationDelay * s.samplingInterval, EPOCH_BASELINE_REGION_KEY, EPOCH_SN_BL_TERMINATIONDELAY, 0)
		endif

		epochBegin = startOffset * s.samplingInterval
		if(s.distributedDAQOptOv && s.offsets[i] > 0)
			epochOffset = s.offsets[i] * 1000
			EP_AddEpoch(panelTitle, channel, epochBegin, epochBegin + epochOffset, EPOCH_BASELINE_REGION_KEY, EPOCH_SN_BL_DDAQOPT, 0)
			EP_AddEpochsFromStimSetNote(panelTitle, channel, singleStimSet, epochBegin + epochOffset, singleSetLength * s.samplingInterval - epochOffset, stimsetCol, s.DACAmp[i][%DASCALE])
		else
			EP_AddEpochsFromStimSetNote(panelTitle, channel, singleStimSet, epochBegin, singleSetLength * s.samplingInterval, stimsetCol, s.DACAmp[i][%DASCALE])
		endif

		if(s.distributedDAQOptOv)
			EP_AddEpochsFromOodDAQRegions(panelTitle, channel, s.regions[i], epochBegin)
		endif

		// if dDAQ is on then channels 0 to numEntries - 1 have a trailing base line
		epochBegin = startOffset + singleSetLength + s.terminationDelay
		if(stopCollectionPoint > epochBegin)
			EP_AddEpoch(panelTitle, channel, epochBegin * s.samplingInterval, stopCollectionPoint * s.samplingInterval, EPOCH_BASELINE_REGION_KEY, EPOCH_SN_BL_DDAQTRAIL, 0)
		endif

		if(s.globalTPInsert)
			// space in ITCDataWave for the testpulse is allocated via an automatic increase
			// of the onset delay
			EP_AddEpochsFromTP(panelTitle, channel, s.baselinefrac, s.testPulseLength * s.samplingInterval, 0, "Inserted TP", s.DACAmp[i][%TPAMP])
		endif
	endfor
End

/// @brief Adds four epochs for a test pulse and three sub epochs for test pulse components
/// @param[in] panelTitle      title of device panel
/// @param[in] channel         number of DA channel
/// @param[in] baselinefrac    base line fraction of testpulse
/// @param[in] testPulseLength test pulse length in micro seconds
/// @param[in] offset          start time of test pulse in micro seconds
/// @param[in] name            name of test pulse (e.g. Inserted TP)
/// @param[in] amplitude       amplitude of the TP in the DA wave without gain
static Function EP_AddEpochsFromTP(panelTitle, channel, baselinefrac, testPulseLength, offset, name, amplitude)
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
	EP_AddEpoch(panelTitle, channel, epochBegin, epochEnd, epochName, EPOCH_SN_TP, 0)

	// TP sub ranges
	epochBegin = baselineFrac * testPulseLength + offset
	epochEnd = (1 - baselineFrac) * testPulseLength + offset
	epochSubName = AddListItem("pulse", epochName, EPOCHNAME_SEP, Inf)
	epochSubName = ReplaceNumberByKey("Amplitude", epochSubName, amplitude, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
	EP_AddEpoch(panelTitle, channel, epochBegin, epochEnd, epochSubName, EPOCH_SN_TP_PULSE, 1)

	epochBegin = offset
	epochEnd = epochBegin + baselineFrac * testPulseLength
	EP_AddEpoch(panelTitle, channel, epochBegin, epochEnd, EPOCH_BASELINE_REGION_KEY, EPOCH_SN_TP_BLFRONT, 1)

	epochBegin = (1 - baselineFrac) * testPulseLength + offset
	epochEnd = testPulseLength + offset
	EP_AddEpoch(panelTitle, channel, epochBegin, epochEnd, EPOCH_BASELINE_REGION_KEY, EPOCH_SN_TP_BLBACK, 1)
End

/// @brief Adds epochs for oodDAQ regions
/// @param[in] panelTitle    title of device panel
/// @param[in] channel       number of DA channel
/// @param[in] oodDAQRegions string containing list of oodDAQ regions as %d-%d;...
/// @param[in] stimsetBegin offset time in micro seconds where stim set begins
static Function EP_AddEpochsFromOodDAQRegions(panelTitle, channel, oodDAQRegions, stimsetBegin)
	string panelTitle
	variable channel
	string oodDAQRegions
	variable stimsetBegin

	variable numRegions
	WAVE/T regions = ListToTextWave(oodDAQRegions, ";")
	numRegions = DimSize(regions, ROWS)
	if(numRegions)
		Make/FREE/N=(numRegions) epochIndexer
		epochIndexer[] = EP_AddEpoch(panelTitle, channel, str2num(StringFromList(0, regions[p], "-")) * 1E3 + stimsetBegin, str2num(StringFromList(1, regions[p], "-")) * 1E3 + stimsetBegin, EPOCH_OODDAQ_REGION_KEY + "=" + num2str(p), EPOCH_SN_OODAQ + num2str(p), 2)
	endif
End

/// @brief Adds epochs for a stimset and sub epochs for stimset components
/// currently adds also sub sub epochs for pulse train components
/// @param[in] panelTitle   title of device panel
/// @param[in] channel      number of DA channel
/// @param[in] stimset      stimset wave
/// @param[in] stimsetBegin offset time in micro seconds where stim set begins
/// @param[in] setLength    length of stimset in micro seconds
/// @param[in] sweep        number of sweep
/// @param[in] scale        scale factor between the stimsets internal amplitude to the DA wave without gain
static Function EP_AddEpochsFromStimSetNote(panelTitle, channel, stimset, stimsetBegin, setLength, sweep, scale)
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
	string shortNameEp, shortNameEpTypePT, shortNameEpTypePTPulse, shortNameEpTypePTPulseP, shortNameEpTypePTPulseB, shortNameEpTypePTPulseBT
	string shortNameEpTypePTBaseline
	string stimNote = note(stimset)

	ASSERT(!IsEmpty(stimNote), "Stimset note is empty.")

	stimsetEnd = stimsetBegin + setLength
	EP_AddEpoch(panelTitle, channel, stimsetBegin, stimsetEnd, "Stimset", EPOCH_SN_STIMSET, 0)

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

		shortNameEp = EPOCH_SN_EPOCH + num2istr(epochNr)
		EP_AddEpoch(panelTitle, channel, epochBegin, epochEnd, epSubName, shortNameEp, 1, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)

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
							EP_AddEpoch(panelTitle, channel, epochBegin, subEpochBegin, EPOCH_BASELINE_REGION_KEY, shortNameEpTypePTPulseBT, 2, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)
						endif

						epSubSubName = ReplaceNumberByKey("Pulse", epSubName, pulseNr, STIMSETKEYNAME_SEP, EPOCHNAME_SEP)
						EP_AddEpoch(panelTitle, channel, subEpochBegin, subEpochEnd, epSubSubName, shortNameEpTypePTPulse, 2, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)

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
							EP_AddEpoch(panelTitle, channel, subsubEpochBegin, subsubEpochEnd, epSubSubName, shortNameEpTypePTPulseP, 3, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)

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
								EP_AddEpoch(panelTitle, channel, subsubEpochBegin, subsubEpochEnd, epSubSubName, shortNameEpTypePTPulseB, 3, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)
							endif
						endif
					endif
				endfor
			else
				EP_AddEpoch(panelTitle, channel, epochBegin, epochEnd, EPOCH_BASELINE_REGION_KEY, shortNameEpTypePTBaseline, 2, lowerlimit = stimsetBegin, upperlimit = stimsetEnd)
			endif
		else
			// Epoch details on other types not implemented yet
		endif

	endfor

	// stimsets with multiple sweeps where each sweep has a different length (due to delta mechanism)
	// result in 2D stimset waves where all sweeps have the same length
	// therefore we must add a baseline epoch after all defined epochs
	if(stimsetEnd > stimsetEndLogical)
		EP_AddEpoch(panelTitle, channel, stimsetEndLogical, stimsetEnd, EPOCH_BASELINE_REGION_KEY, EPOCH_SN_STIMSET + "_" + EPOCH_SN_STIMSETBLTRAIL, 1)
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
/// @param[in] panelTitle title of device panel
static Function EP_SortEpochs(panelTitle)
	string panelTitle

	variable channel, channelCnt, epochCnt
	WAVE/T epochWave = GetEpochsWave(panelTitle)
	channelCnt = DimSize(epochWave, LAYERS)
	for(channel = 0; channel < channelCnt; channel += 1)
		epochCnt = EP_GetEpochCount(panelTitle, channel)
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
		for(;!RemoveTextWaveEntry1D(epochChannel, "NaN");)
		endfor

		epochCnt = DimSize(epochChannel, ROWS)

		if(epochCnt > 0)
			epochWave[, epochCnt - 1][][channel] = epochChannel[p][q]
		endif

		epochWave[epochCnt, *][][channel] = ""
	endfor
End

/// @brief Returns the number of epoch in the epochsWave for the given channel
/// @param[in] panelTitle title of device panel
/// @param[in] channel    number of DA channel
/// @return number of epochs for channel
static Function EP_GetEpochCount(panelTitle, channel)
	string panelTitle
	variable channel

	WAVE/T epochWave = GetEpochsWave(panelTitle)
	FindValue/Z/RMD=[][][channel]/TXOP=4/TEXT="" epochWave
	return V_row == -1 ? DimSize(epochWave, ROWS) : V_row
End

/// @brief Adds a epoch to the epochsWave
/// @param[in] panelTitle  title of device panel
/// @param[in] channel     number of DA channel
/// @param[in] epBegin     start time of the epoch in micro seconds
/// @param[in] epEnd       end time of the epoch in micro seconds
/// @param[in] epName      name of the epoch
/// @param[in] epShortName short name of the epoch, should be unique
/// @param[in] level       level of epoch
/// @param[in] lowerlimit  [optional, default = -Inf] epBegin is limited between lowerlimit and Inf, epEnd must be > this limit
/// @param[in] upperlimit  [optional, default = Inf] epEnd is limited between -Inf and upperlimit, epBegin must be < this limit
static Function EP_AddEpoch(panelTitle, channel, epBegin, epEnd, epName, epShortName, level[, lowerlimit, upperlimit])
	string panelTitle
	variable channel
	variable epBegin, epEnd
	string epName, epShortName
	variable level
	variable lowerlimit, upperlimit

	WAVE/T epochWave = GetEpochsWave(panelTitle)
	variable i, j, numEpochs, pos
	string entry, startTimeStr, endTimeStr

	lowerlimit = ParamIsDefault(lowerlimit) ? -Inf : lowerlimit
	upperlimit = ParamIsDefault(upperlimit) ? Inf : upperlimit

	ASSERT(!isNull(epName), "Epoch name is null")
	ASSERT(!isEmpty(epName), "Epoch name is empty")
	ASSERT(!isEmpty(epShortName), "Epoch short name is empty")
	ASSERT(epBegin <= epEnd, "Epoch end is < epoch begin")
	ASSERT(epBegin < upperlimit, "Epoch begin is greater than upper limit")
	ASSERT(epEnd > lowerlimit, "Epoch end lesser than lower limit")

	epBegin = limit(epBegin, lowerlimit, Inf)
	epEnd = limit(epEnd, -Inf, upperlimit)

	i = EP_GetEpochCount(panelTitle, channel)
	EnsureLargeEnoughWave(epochWave, minimumSize = i + 1, dimension = ROWS)

	startTimeStr = num2strHighPrec(epBegin / 1E6, precision = EPOCHTIME_PRECISION)
	endTimeStr = num2strHighPrec(epEnd / 1E6, precision = EPOCHTIME_PRECISION)

	if(!cmpstr(startTimeStr, endTimeStr))
		// don't add single point epochs
		return NaN
	endif

	epName = ReplaceStringByKey(EPOCH_SHORTNAME_KEY, epName, epShortName, SHORTNAMEKEY_SEP)

	epochWave[i][%StartTime][channel] = startTimeStr
	epochWave[i][%EndTime][channel] = endTimeStr
	epochWave[i][%Name][channel] = epName
	epochWave[i][%TreeLevel][channel] = num2str(level)
End

/// @brief Write the epoch info into the sweep settings wave
///
/// @param panelTitle device
/// @param sweepWave  sweep wave
/// @param configWave config wave
Function EP_WriteEpochInfoIntoSweepSettings(string panelTitle, WAVE sweepWave, WAVE configWave)
	variable i, numDACEntries, channel, headstage, acquiredTime
	string entry

	EP_SortEpochs(panelTitle)

	WAVE DACList = GetDACListFromConfig(configWave)
	numDACEntries = DimSize(DACList, ROWS)

	WAVE channelClampMode = GetChannelClampMode(panelTitle)
	Make/D/FREE/N=(numDACEntries) headstageDAC = channelClampMode[DACList[p]][%DAC][%Headstage]

	WAVE/T epochsWave = GetEpochsWave(panelTitle)

	for(i = 0; i < numDACEntries; i += 1)
		channel = DACList[i]
		headstage = headstageDAC[i]

		Duplicate/FREE/RMD=[][][channel] epochsWave, epochChannel
		Redimension/N=(-1, -1, 0) epochChannel
		entry = TextWaveToList(epochChannel, EPOCH_LIST_ROW_SEP, colSep = EPOCH_LIST_COL_SEP, stopOnEmpty = 1)
		DC_DocumentChannelProperty(panelTitle, EPOCHS_ENTRY_KEY, headstage, channel, XOP_CHANNEL_TYPE_DAC, str=entry)
	endfor

	DC_DocumentChannelProperty(panelTitle, "Epochs Version", INDEP_HEADSTAGE, NaN, NaN, var=SWEEP_EPOCH_VERSION)
End

/// @brief Converts a string containing epoch information in the format that is stored in the Labnotebook
///        to a 2D epoch wave @sa GetEpochsWave
///
/// @param[in] epochStr string with epoch information in the format as stored in the labnotebook
/// @returns 2D text wave with epoch information, use EPOCH_COL_ constants for column access
Function/WAVE EP_EpochStrToWave(string epochStr)

	ASSERT(!IsEmpty(epochStr), "No information in epochStr")
	WAVE/T epochWave = ListToTextWaveMD(epochStr, 2, rowSep = EPOCH_LIST_ROW_SEP, colSep = EPOCH_LIST_COL_SEP)
	return epochWave
End

/// @brief Returns the ShortName from a epoch name string, empty string if no ShortName is present
Function/S EP_GetShortName(string name)

	return StringByKey(EPOCH_SHORTNAME_KEY, name, SHORTNAMEKEY_SEP)
End
