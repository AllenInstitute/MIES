#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DCR
#endif

/// @file MIES_DataConfiguratonRecreation.ipf
/// @brief __DCR__ Functions for recreating the DataConfigurationResult structure from the labnotebook

// @brief Recreates DataConfigurationResult structure from LabNotebook for DATA_ACQUISITION_MODE
//        Requirements: Load sweeps and stimsets before call
Function [STRUCT DataConfigurationResult s] DCR_RecreateDataConfigurationResultFromLNB(WAVE numericalValues, WAVE/T textualValues, DFREF sweepDFR, variable sweepNo)

	variable index, i, idx, hwType

	s.dataAcqOrTP = DATA_ACQUISITION_MODE
	DCR_RecreateDataConfigurationResultFromLNB_Indep(s, numericalValues, textualValues, sweepDFR, sweepNo)

	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "Headstage Active", s.dataAcqOrTP)
	if(WaveExists(settings))
		Redimension/N=(NUM_HEADSTAGES) settings
		WAVE s.statusHS = settings
	else
		DEBUGPRINT("LNB entry not found: Headstage Active")
	endif

	DCR_RecreateDataConfigurationResultFromLNB_DAC(s, numericalValues, textualValues, sweepNo)
	DC_CalculateInsertStart(s)
	if(IsNaN(s.baselineFrac))
		DCR_RecreateDataConfigurationResultFromLNB_baselineFrac_Path2(s, numericalValues, textualValues, sweepDFR, sweepNo)
	endif

	[WAVE adGains] = DCR_RecreateDataConfigurationResultFromLNB_ADC(s, numericalValues, textualValues, sweepNo)
	DCR_RecreateDataConfigurationResultFromLNB_TTL(s, numericalValues, textualValues, sweepNo)

	s.numActiveChannels = s.numDACEntries + s.numADCEntries + s.numTTLEntries

	WAVE daGains = DCR_RecreateDataConfigurationResultFromLNB_DAGains(s, numericalValues, textualValues, sweepNo)
	Make/FREE/N=(s.numTTLEntries) ttlGains
	ttlGains = 1
	Concatenate/NP {adGains, ttlGains}, daGains
	daGains[] = 1 / daGains[p]
	WAVE s.gains = daGains

	ASSERT(DimSize(s.DACList, ROWS), "Could not find any active DA channel.")
	WAVE/Z sweep = GetDAQDataSingleColumnWaveNG(numericalValues, textualValues, sweepNo, sweepDFR, XOP_CHANNEL_TYPE_DAC, s.DACList[0])
	ASSERT(WaveExists(sweep), "Could not retrieve sweep for DataConfigurationResult recreation (required for stopCollectionPoint)")
	hwType = GetLastSettingIndep(numericalValues, sweepNo, "Digitizer Hardware Type", s.dataAcqOrTP)
	if(IsNaN(hwType))
		DEBUGPRINT("LNB entry not found: Digitizer Hardware Type, defaulting to ITC")
		hwType = HARDWARE_ITC_DAC
	endif
	s.stopCollectionPoint = DC_CalculateDAQDataWaveLengthImpl(DimSize(sweep, ROWS), hwType, s.dataAcqOrTP)

	if(!IsNaN(s.baselineFrac))
		DCR_RecreateDataConfigurationResultFromLNB_TP(s, numericalValues, sweepNo)
	endif

	// TODO: Save in LNB and restore here
	// s.joinedTTLStimsetSize
	// s.powerSpectrum

End

static Function DCR_RecreateDataConfigurationResultFromLNB_TTL(STRUCT DataConfigurationResult &s, WAVE numericalValues, WAVE/T textualValues, variable sweepNo)

	variable index, indep_hs_text

	indep_hs_text = GetIndexForHeadstageIndepData(textualValues)

	// TTL value entries, fallbacks for missing data not implemented for TTL
	Make/FREE/D/N=(NUM_DA_TTL_CHANNELS) s.TTLsetLength, s.TTLsetColumn, s.TTLcycleCount
	Make/FREE/N=(NUM_DA_TTL_CHANNELS) s.statusTTLFiltered
	Make/FREE/T/N=(NUM_DA_TTL_CHANNELS) s.TTLsetName
	Make/FREE/WAVE/N=(NUM_DA_TTL_CHANNELS) s.TTLstimSet
	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "channels", NaN, XOP_CHANNEL_TYPE_TTL, s.dataAcqOrTP)
	if(WaveExists(settings))
		WAVE/T settingsT = settings
		WAVE   TTLList   = ListToNumericWave(settingsT[indep_hs_text], ";")
		ASSERT(DimSize(TTLList, ROWS) == NUM_DA_TTL_CHANNELS, "Unexpected number of TTL channels from LNB.")
		s.statusTTLFiltered[] = !IsNaN(TTLList[p])
		WAVE/Z s.TTLList = ZapNaNs(TTLList)
		if(WaveExists(s.TTLList))
			s.numTTLEntries = DimSize(s.TTLList, ROWS)
		else
			s.numTTLEntries = 0
			Make/FREE/N=(0) s.TTLList
		endif
	else
		s.numTTLEntries = 0
		Make/FREE/N=(0) s.TTLList
		DEBUGPRINT("LNB entry not found for XOP_CHANNEL_TYPE_TTL: channels")
	endif

	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "stim sets", NaN, XOP_CHANNEL_TYPE_TTL, s.dataAcqOrTP)
	if(WaveExists(settings))
		WAVE/T settingsT    = settings
		WAVE/T s.TTLsetName = ListToTextWave(settingsT[indep_hs_text], ";")
		ASSERT(DimSize(s.TTLsetName, ROWS) == NUM_DA_TTL_CHANNELS, "Got unexpected LNB entry format")
	else
		DEBUGPRINT("LNB entry not found for XOP_CHANNEL_TYPE_TTL: stim sets")
	endif

	s.TTLstimSet[] = WB_CreateAndGetStimSet(s.TTLsetName[p])

	// for TTL the setLength was not saved in the LNB, so recalculate. The result may differ from the actual TTLsetLength originally used when acquired
	s.TTLsetLength[] = WaveExists(s.TTLstimSet[p]) ? DC_CalculateGeneratedDataSizeDAQMode(DimSize(s.TTLstimSet[p], ROWS), s.decimationFactor) : 0

	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "TTL set sweep counts", NaN, XOP_CHANNEL_TYPE_TTL, s.dataAcqOrTP)
	if(WaveExists(settings))
		WAVE/T settingsT      = settings
		WAVE   s.TTLsetColumn = ListToNumericWave(settingsT[indep_hs_text], ";")
		ASSERT(DimSize(s.TTLsetColumn, ROWS) == NUM_DA_TTL_CHANNELS, "Unexpected number of TTL channels from LNB.")
	else
		DEBUGPRINT("LNB entry not found for XOP_CHANNEL_TYPE_TTL: TTL set sweep counts")
	endif

	[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "TTL set cycle counts", NaN, XOP_CHANNEL_TYPE_TTL, s.dataAcqOrTP)
	if(WaveExists(settings))
		WAVE/T settingsT       = settings
		WAVE   s.TTLcycleCount = ListToNumericWave(settingsT[indep_hs_text], ";")
		ASSERT(DimSize(s.TTLcycleCount, ROWS) == NUM_DA_TTL_CHANNELS, "Unexpected number of TTL channels from LNB.")
	else
		DEBUGPRINT("LNB entry not found for XOP_CHANNEL_TYPE_TTL: TTL set cycle counts")
	endif
End

static Function [WAVE/D adGains] DCR_RecreateDataConfigurationResultFromLNB_ADC(STRUCT DataConfigurationResult &s, WAVE numericalValues, WAVE/T textualValues, variable sweepNo)

	variable index, i, idx

	Make/FREE/N=(NUM_AD_CHANNELS) s.ADCList
	for(i = 0; i < NUM_AD_CHANNELS; i += 1)
		[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "ADC", i, XOP_CHANNEL_TYPE_ADC, s.dataAcqOrTP)
		if(WaveExists(settings))
			s.ADCList[idx] = settings[index]
			idx           += 1
		endif
	endfor
	Redimension/N=(idx) s.ADCList
	s.numADCEntries = idx
	ASSERT(s.numADCEntries > 0, "No active AD channel found")

	Make/FREE/D/N=(s.numADCEntries) s.headstageADC = NaN
	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "ADC", s.dataAcqOrTP)
	if(WaveExists(settings))
		for(i = 0; i < NUM_HEADSTAGES; i += 1)
			if(IsFinite(settings[i]))
				FindValue/V=(settings[i]) s.ADCList
				if(V_row >= 0)
					s.headstageADC[V_row] = i
				endif
			endif
		endfor
	else
		DEBUGPRINT("LNB entry not found: ADC")
	endif

	Make/FREE/D/N=(s.numADCEntries) adGains
	for(i = 0; i < s.numADCEntries; i += 1)
		[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "AD GAIN", s.ADCList[i], XOP_CHANNEL_TYPE_ADC, s.dataAcqOrTP)
		if(WaveExists(settings))
			adGains[i] = settings[index]
		endif
	endfor

	return [adGains]
End

static Function/WAVE DCR_RecreateDataConfigurationResultFromLNB_DAGains(STRUCT DataConfigurationResult &s, WAVE numericalValues, WAVE/T textualValues, variable sweepNo)

	variable i, index

	Make/FREE/D/N=(s.numDACEntries) daGains
	for(i = 0; i < s.numDACEntries; i += 1)
		[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "DA GAIN", s.DACList[i], XOP_CHANNEL_TYPE_DAC, s.dataAcqOrTP)
		if(WaveExists(settings))
			daGains[i] = settings[index]
		endif
	endfor

	return daGains
End

static Function DCR_RecreateDataConfigurationResultFromLNB_DAC(STRUCT DataConfigurationResult &s, WAVE numericalValues, WAVE/T textualValues, variable sweepNo)

	variable index, i, idx, clampMode, wbOodDAQOffset, postFeaturePoints, stimsetError
	string key

	Make/FREE/N=(NUM_DA_TTL_CHANNELS) s.DACList
	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)
		[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "DAC", i, XOP_CHANNEL_TYPE_DAC, s.dataAcqOrTP)
		if(WaveExists(settings))
			s.DACList[idx] = settings[index]
			idx           += 1
		endif
	endfor
	Redimension/N=(idx) s.DACList
	s.numDACEntries = idx
	ASSERT(s.numDACEntries > 0, "No active DA channel found")

	Make/FREE/D/N=(s.numDACEntries) s.headstageDAC = NaN
	WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "DAC", s.dataAcqOrTP)
	if(WaveExists(settings))
		for(i = 0; i < NUM_HEADSTAGES; i += 1)
			if(IsFinite(settings[i]))
				FindValue/V=(settings[i]) s.DACList
				if(V_row >= 0)
					s.headstageDAC[V_row] = i
				endif
			endif
		endfor
	else
		DEBUGPRINT("LNB entry not found: DAC")
	endif

	Make/FREE/D/N=(s.numDACEntries) s.setCycleCount, s.setColumn, s.insertStart, daqChannelType, s.setLength
	Make/FREE/N=(s.numDACEntries) s.offsets
	Make/FREE/T/N=(s.numDACEntries) s.regions, s.setName
	Make/FREE/WAVE/N=(s.numDACEntries) s.stimSet
	WAVE/D s.DACAmp = GetDACAmplitudes(s.numDACEntries)
	for(i = 0; i < s.numDACEntries; i += 1)
		[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "Set Cycle Count", s.DACList[i], XOP_CHANNEL_TYPE_DAC, s.dataAcqOrTP)
		if(WaveExists(settings))
			s.setCycleCount[i] = settings[index]
		endif
		[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "Set Sweep Count", s.DACList[i], XOP_CHANNEL_TYPE_DAC, s.dataAcqOrTP)
		if(WaveExists(settings))
			s.setColumn[i] = settings[index]
		endif
		[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "Delay onset oodDAQ", s.DACList[i], XOP_CHANNEL_TYPE_DAC, s.dataAcqOrTP)
		if(WaveExists(settings))
			s.offsets[i] = settings[index]
		endif
		[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "oodDAQ regions", s.DACList[i], XOP_CHANNEL_TYPE_DAC, s.dataAcqOrTP)
		if(WaveExists(settings))
			WAVE/T settingsT = settings
			s.regions[i] = settingsT[index]
		endif
		[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "DA ChannelType", s.DACList[i], XOP_CHANNEL_TYPE_DAC, s.dataAcqOrTP)
		if(WaveExists(settings))
			daqChannelType[i] = settings[index]
		else
			daqChannelType[i] = NaN
		endif
		[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, STIMSET_SCALE_FACTOR_KEY, s.DACList[i], XOP_CHANNEL_TYPE_DAC, s.dataAcqOrTP)
		if(WaveExists(settings))
			if(daqChannelType[i] == DAQ_CHANNEL_TYPE_DAQ || IsNaN(daqChannelType[i]))
				s.DACAmp[i][%DASCALE] = settings[index]
			else
				s.DACAmp[i][%TPAMP] = settings[index]
			endif
		endif
		[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, STIM_WAVE_NAME_KEY, s.DACList[i], XOP_CHANNEL_TYPE_DAC, s.dataAcqOrTP)
		if(WaveExists(settings))
			WAVE/T settingsT = settings
			s.setName[i] = settingsT[index]
			s.stimSet[i] = WB_CreateAndGetStimSet(s.setName[i])
			if(!WaveExists(s.stimSet[i]))
				print "DC recreation:  Could not create stimset " + s.setName[i] + ". Was the stimset data loaded?"
			elseif(DimSize(s.stimSet[i], ROWS) == 0 || IsEmpty(note(s.stimSet[i])))
				printf "DC recreation: WB returned invalid stimset size %d / empty note %d\r", DimSize(s.stimSet[i], ROWS), IsEmpty(note(s.stimSet[i]))
			endif
			if(s.offsets[i])
				WAVE stimSet = s.stimSet[i]
				wbOodDAQOffset    = round(s.offsets[i] / WAVEBUILDER_MIN_SAMPINT)
				postFeaturePoints = s.distributedDAQOptPost / WAVEBUILDER_MIN_SAMPINT // as in @ref InitOOdDAQParams
				WAVE stimCol = OOD_OffsetStimSetColAndCutoff(stimSet, s.setColumn[i], wbOodDAQOffset, postFeaturePoints)
				Duplicate/FREE stimSet, stimSetOffsetted
				Redimension/N=(DimSize(stimCol, ROWS), -1) stimSetOffsetted
				MultiThread stimSetOffsetted[][s.setColumn[i]] = stimCol[p]
				s.stimSet[i] = stimSetOffsetted
			endif
		endif
		[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "Stim set length", s.DACList[i], XOP_CHANNEL_TYPE_DAC, s.dataAcqOrTP)
		if(WaveExists(settings))
			s.setLength[i] = settings[index]
		elseif(WaveExists(s.stimSet[i]))
			stimsetError = WB_GetWaveNoteEntryAsNumber(note(s.stimSet[i]), STIMSET_ENTRY, key = STIMSET_ERROR_KEY)
			if(!stimsetError)
				s.setLength[i] = DC_CalculateGeneratedDataSizeDAQMode(DimSize(s.stimSet[i], ROWS), s.decimationFactor)
			else
				print "DC recreation: WB returned error for creation of stimset wave data: " + s.setName[i]
				s.setLength[i] = NaN
			endif
		endif

		if(daqChannelType[i] == DAQ_CHANNEL_TYPE_DAQ)
			[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, "Clamp Mode", s.DACList[i], XOP_CHANNEL_TYPE_DAC, s.dataAcqOrTP)
			if(WaveExists(settings))
				clampMode = settings[index]
				if(clampMode == V_CLAMP_MODE)
					key = TP_AMPLITUDE_VC_ENTRY_KEY
				elseif(clampMode == I_CLAMP_MODE)
					key = TP_AMPLITUDE_IC_ENTRY_KEY
				elseif(clampMode == I_EQUAL_ZERO_MODE)
					s.DACAmp[i][%DASCALE] = 0
					s.DACAmp[i][%TPAMP]   = 0
					continue
				else
					ASSERT(0, "Unknown clamp mode")
				endif
				[WAVE settings, index] = GetLastSettingChannel(numericalValues, textualValues, sweepNo, key, s.DACList[i], XOP_CHANNEL_TYPE_DAC, s.dataAcqOrTP)
				if(WaveExists(settings))
					s.DACAmp[i][%TPAMP] = settings[index]
				endif
			endif
		endif
	endfor
End

static Function DCR_FindStimsetOffset(STRUCT DataConfigurationResult &s, WAVE numericalValues, WAVE/T textualValues, DFREF sweepDFR, variable sweepNo)

	Make/FREE/N=(s.numDACEntries) offsets
	offsets[] = DCR_FindStimsetOffsetForChannel(s, numericalValues, textualValues, sweepDFR, sweepNo, p)
	WAVE/Z zappedOffsets = ZapNaNs(offsets)
	if(!WaveExists(zappedOffsets))
		return NaN
	endif
	if(DimSize(zappedOffsets, ROWS) == 1)
		return zappedOffsets[0]
	endif

	// sanity check if determined offset for all channel is the same
	zappedOffsets[] = round(zappedOffsets[p])
	WaveStats/Q zappedOffsets
	ASSERT(V_min == V_max, "Determined different stimset offsets for each channel, but the offsets should be the same for all channels. (Needs further investigation)")

	return zappedOffsets[0]
End

/// @brief This function requires that the stimset is featureless (zero)
static Function DCR_FindStimsetOffsetFromTP(STRUCT DataConfigurationResult &s, WAVE numericalValues, WAVE/T textualValues, DFREF sweepDFR, variable sweepNo, variable channelIndex)

	variable startIndex, endIndex

	WAVE/Z sweep = GetDAQDataSingleColumnWaveNG(numericalValues, textualValues, sweepNo, sweepDFR, XOP_CHANNEL_TYPE_DAC, s.DACList[channelIndex])
	ASSERT(WaveExists(sweep), "Could not retrieve sweep for DataConfigurationResult recreation")

	[startIndex, endIndex] = DCR_FindTestPulse(sweep, Inf)
	if(IsNaN(startIndex))
		return 0
	endif

	return endIndex + startIndex - 1
End

static Function DCR_FindStimsetOffsetForChannel(STRUCT DataConfigurationResult &s, WAVE numericalValues, WAVE/T textualValues, DFREF sweepDFR, variable sweepNo, variable channelIndex)

	variable lastIdx, sizeInDA, stimEdgePos, daEdgePos, daSize, offsetGuess, startSearch, endSearch, searchRange
	variable i, trailPoints, daStimsetSize, matchSize, intenseSearch, progress, progessThreshold, dacAmp
	variable lastFalling, lastRising
	variable level            = GetMachineEpsilon(IGOR_TYPE_64BIT_FLOAT)
	variable searchRangeLimit = 2
	variable threshold        = 0.015

	if(!WaveExists(s.stimset[channelIndex]))
		return NaN
	endif

	Duplicate/FREE/RMD=[][s.setColumn[channelindex]] s.stimset[channelIndex], stimset
	Redimension/N=(-1) stimset

	lastIdx  = DimSize(stimset, ROWS) - 1
	sizeInDA = round(s.decimationFactor * lastIdx)
	// Add one point of trail
	Make/FREE/N=(sizeInDA + 1) stimsetInDA
	dacAmp = s.DACAmp[channelIndex][%DASCALE]

	MultiThread stimsetInDA[] = dacAmp * stimset[round(s.decimationFactor * p)]

	WAVE/Z sweep = GetDAQDataSingleColumnWaveNG(numericalValues, textualValues, sweepNo, sweepDFR, XOP_CHANNEL_TYPE_DAC, s.DACList[channelIndex])
	ASSERT(WaveExists(sweep), "Could not retrieve sweep for DataConfigurationResult recreation")
	daSize = DimSize(sweep, ROWS)

	lastFalling = NaN
	lastRising  = NaN
	FindLevel/Q/P/EDGE=(FINDLEVEL_EDGE_DECREASING)/R=[lastIdx, 0] stimsetInDA, level
	if(!V_flag)
		lastFalling = trunc(V_LevelX)
	endif
	FindLevel/Q/P/EDGE=(FINDLEVEL_EDGE_INCREASING)/R=[lastIdx, 0] stimsetInDA, -level
	if(!V_flag)
		lastRising = trunc(V_LevelX)
	endif
	if(IsNaN(lastFalling) && IsNaN(lastRising))
		DEBUGPRINT("No feature found in stimset")
		return DCR_FindStimsetOffsetFromTP(s, numericalValues, textualValues, sweepDFR, sweepNo, channelIndex)
	endif
	if(IsNaN(lastFalling) && !IsNaN(lastRising))
		stimEdgePos = lastRising
	elseif(!IsNaN(lastFalling) && IsNaN(lastRising))
		stimEdgePos = lastFalling
	else
		stimEdgePos = max(lastFalling, lastRising)
	endif

	lastFalling = NaN
	lastRising  = NaN
	FindLevel/Q/P/EDGE=(FINDLEVEL_EDGE_DECREASING)/R=[daSize - 1, 0] sweep, level
	if(!V_flag)
		lastFalling = trunc(V_LevelX)
	endif
	FindLevel/Q/P/EDGE=(FINDLEVEL_EDGE_INCREASING)/R=[daSize - 1, 0] sweep, -level
	if(!V_flag)
		lastRising = trunc(V_LevelX)
	endif
	if(IsNaN(lastFalling) && IsNaN(lastRising))
		DEBUGPRINT("No feature found in DA wave")
		return NaN
	endif
	if(IsNaN(lastFalling) && !IsNaN(lastRising))
		daEdgePos = lastRising
	elseif(!IsNaN(lastFalling) && IsNaN(lastRising))
		daEdgePos = lastFalling
	else
		daEdgePos = max(lastFalling, lastRising)
	endif

	daStimsetSize = DimSize(stimsetInDA, ROWS) - 1
	Redimension/N=(daStimsetSize) stimsetInDA

	searchRange = round(1 / s.decimationFactor) * searchRangeLimit
	offsetGuess = daEdgePos - stimEdgePos
	startSearch = limit(offsetGuess - searchRange, 0, Inf)
	trailPoints = max(daSize - offsetGuess - daStimsetSize, 0)
	endSearch   = offsetGuess + min(searchRange, trailPoints)
	endSearch  += 1
	Make/FREE/D/N=(daStimsetSize) matchWindow
	for(;;)
		Make/FREE/D/N=(endSearch - startSearch) match
		for(i = startSearch; i < endSearch; i += 1)
			matchSize = min(daStimsetSize, daSize - i)
			MultiThread matchWindow[0, matchSize - 1] = (sweep[i + p] - stimsetInDA[p])^2
			match[i - startSearch] = sum(matchWindow) / matchSize

			progress = trunc(100 * i / (endSearch - startSearch))
			if(intenseSearch && progress >= progessThreshold)
				printf "%d %%\r", progress
				progessThreshold += 5
			endif

		endfor

		WaveStats/Q/P/M=1/R=[0, matchSize - 1] match
		if(V_min < threshold || intenseSearch)
			break
		endif

		printf "DC recreation, triggered intense search for stimset offset.\r"
		startSearch   = 0
		endSearch     = daSize - daStimsetSize
		intenseSearch = 1
	endfor

	DEBUGPRINT("stimset offset " + num2str(startSearch + V_minRowLoc) + " deviation " + num2str(V_min))

	return startSearch + V_minRowLoc
End

static Function [variable startIndex, variable endIndex] DCR_FindTestPulse(WAVE sweep, variable testPulseLength)

	variable startIndexHigh = NaN
	variable endIndexHigh   = NaN
	variable startIndexLow  = NaN
	variable endIndexLow    = NaN
	variable level          = GetMachineEpsilon(IGOR_TYPE_64BIT_FLOAT)

	FindLevel/Q/EDGE=(FINDLEVEL_EDGE_INCREASING)/P/R=[0, testPulseLength - 1] sweep, level
	if(!V_flag)
		startIndexHigh = trunc(V_LevelX) + 1
		FindLevel/Q/EDGE=(FINDLEVEL_EDGE_DECREASING)/P/R=[startIndexHigh, testPulseLength - 1] sweep, level
		if(!V_flag)
			endIndexHigh = trunc(V_LevelX) + 1
		endif
	endif
	// try negative
	FindLevel/Q/EDGE=(FINDLEVEL_EDGE_DECREASING)/P/R=[0, testPulseLength - 1] sweep, -level
	if(!V_flag)
		startIndexLow = trunc(V_LevelX) + 1
		FindLevel/Q/EDGE=(FINDLEVEL_EDGE_INCREASING)/P/R=[startIndexLow, testPulseLength - 1] sweep, -level
		if(!V_flag)
			endIndexLow = trunc(V_LevelX) + 1
		endif
	endif

	if(IsNaN(startIndexHigh) || IsNaN(endIndexHigh))
		if(IsNaN(startIndexLow) || IsNaN(endIndexLow))
			return [NaN, NaN]
		else
			startIndex = startIndexLow
			endIndex   = endIndexLow
		endif
	elseif(IsNaN(startIndexLow) || IsNaN(endIndexLow))
		startIndex = startIndexHigh
		endIndex   = endIndexHigh
	elseif(startIndexLow < startIndexHigh)
		startIndex = startIndexLow
		endIndex   = endIndexLow
	else
		startIndex = startIndexHigh
		endIndex   = endIndexHigh
	endif

	return [startIndex, endIndex]
End

static Function DCR_RecreateDataConfigurationResultFromLNB_baselineFrac_Path2(STRUCT DataConfigurationResult &s, WAVE numericalValues, WAVE/T textualValues, DFREF sweepDFR, variable sweepNo)

	variable startIndex, endIndex, testPulseLength

	ASSERT(DimSize(s.DACList, ROWS), "No active DA channel found.")
	if(IsNaN(s.onsetDelayAuto))
		s.onsetDelayAuto = DCR_FindStimsetOffset(s, numericalValues, textualValues, sweepDFR, sweepNo)
		if(IsNaN(s.onsetDelayAuto))
			return NaN
		endif
		s.insertStart[]  = s.onsetDelayAuto
		s.globalTPInsert = s.onsetDelayAuto > 0
	elseif(s.onsetDelayAuto == 0)
		return NaN
	endif

	testPulseLength = s.onsetDelayAuto

	WAVE/Z sweep = GetDAQDataSingleColumnWaveNG(numericalValues, textualValues, sweepNo, sweepDFR, XOP_CHANNEL_TYPE_DAC, s.DACList[0])
	ASSERT(WaveExists(sweep), "Could not retrieve sweep for DataConfigurationResult recreation")

	[startIndex, endIndex] = DCR_FindTestPulse(sweep, testPulseLength)
	if(IsNaN(startIndex))
		return NaN
	endif

	s.baselineFrac = TP_CalculateBaselineFraction(endIndex - startIndex, testPulseLength)

	s.testPulseLength     = testPulseLength
	s.tpPulseStartPoint   = startIndex
	s.tpPulseLengthPoints = endIndex - startIndex - 1

	WAVE s.testPulse = GetTestPulseAsFree()
	TP_CreateTestPulseWaveImpl(s.testPulse, s.testPulseLength, s.tpPulseStartPoint, s.tpPulseLengthPoints)
End

static Function DCR_RecreateDataConfigurationResultFromLNB_SamplingInterval_Path2(STRUCT DataConfigurationResult &s, WAVE numericalValues, WAVE/T textualValues, DFREF sweepDFR, variable sweepNo)

	DCR_RecreateDataConfigurationResultFromLNB_DAC(s, numericalValues, textualValues, sweepNo)
	ASSERT(DimSize(s.DACList, ROWS), "No DA channel found")
	WAVE/Z sweep = GetDAQDataSingleColumnWaveNG(numericalValues, textualValues, sweepNo, sweepDFR, XOP_CHANNEL_TYPE_DAC, s.DACList[0])
	ASSERT(WaveExists(sweep), "Could not retrieve sweep for DataConfigurationResult recreation")
	s.samplingIntervalDA = DimDelta(sweep, ROWS)
End

static Function DCR_RecreateDataConfigurationResultFromLNB_Indep(STRUCT DataConfigurationResult &s, WAVE numericalValues, WAVE/T textualValues, DFREF sweepDFR, variable sweepNo)

	variable onsetDelayUserTime, onsetDelayAutoTime, distributedDAQDelayTime, terminationDelayTime
	string device

	s.globalTPInsert = GetLastSettingIndep(numericalValues, sweepNo, "TP Insert Checkbox", s.dataAcqOrTP)
	if(IsNaN(s.globalTPInsert))
		DEBUGPRINT("LNB entry not found: TP Insert Checkbox")
	endif

	s.scalingZero = GetLastSettingIndep(numericalValues, sweepNo, "Scaling zero", s.dataAcqOrTP)
	if(IsNaN(s.scalingZero))
		DEBUGPRINT("LNB entry not found: Scaling zero")
	endif

	// the field s.indexingLocked is not set or used in DC?
	s.indexingLocked = GetLastSettingIndep(numericalValues, sweepNo, "Locked indexing", s.dataAcqOrTP)
	if(IsNaN(s.indexingLocked))
		DEBUGPRINT("LNB entry not found: Locked indexing")
	endif

	s.indexing = GetLastSettingIndep(numericalValues, sweepNo, "Indexing", s.dataAcqOrTP)
	if(IsNaN(s.indexing))
		DEBUGPRINT("LNB entry not found: Indexing")
	endif

	s.distributedDAQ = GetLastSettingIndep(numericalValues, sweepNo, "Distributed DAQ", s.dataAcqOrTP)
	if(IsNaN(s.distributedDAQ))
		DEBUGPRINT("LNB entry not found: Distributed DAQ")
	endif

	s.distributedDAQOptOv = GetLastSettingIndep(numericalValues, sweepNo, "Optimized Overlap dDAQ", s.dataAcqOrTP)
	if(IsNaN(s.distributedDAQOptOv))
		DEBUGPRINT("LNB entry not found: Optimized Overlap dDAQ")
	endif

	s.distributedDAQOptPre = GetLastSettingIndep(numericalValues, sweepNo, "oodDAQ Pre Feature", s.dataAcqOrTP)
	if(IsNaN(s.distributedDAQOptPre))
		DEBUGPRINT("LNB entry not found: oodDAQ Pre Feature")
	endif

	s.distributedDAQOptPost = GetLastSettingIndep(numericalValues, sweepNo, "oodDAQ Post Feature", s.dataAcqOrTP)
	if(IsNaN(s.distributedDAQOptPost))
		DEBUGPRINT("LNB entry not found: oodDAQ Post Feature")
	endif

	s.multiDevice = GetLastSettingIndep(numericalValues, sweepNo, "Multi Device mode", s.dataAcqOrTP)
	if(IsNaN(s.multiDevice))
		DEBUGPRINT("LNB entry not found: Multi Device mode")
	endif

	s.baselineFrac = GetLastSettingIndep(numericalValues, sweepNo, "TP Baseline Fraction", s.dataAcqOrTP)
	if(IsNaN(s.baselineFrac))
		DEBUGPRINT("LNB entry not found: TP Baseline Fraction")
	endif

	s.samplingIntervalDA  = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval DA", s.dataAcqOrTP)
	s.samplingIntervalAD  = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval AD", s.dataAcqOrTP)
	s.samplingIntervalTTL = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval TTL", s.dataAcqOrTP)
	if(IsNaN(s.samplingIntervalDA))
		DEBUGPRINT("LNB entry not found: Sampling interval DA")
		// fallback to old LNB entry
		s.samplingIntervalDA = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval", s.dataAcqOrTP)
		if(IsNaN(s.samplingIntervalDA))
			DEBUGPRINT("LNB entry not found: Sampling interval")
		endif
	endif
	if(IsNaN(s.samplingIntervalDA))
		DCR_RecreateDataConfigurationResultFromLNB_SamplingInterval_Path2(s, numericalValues, textualValues, sweepDFR, sweepNo)
	endif

	s.samplingIntervalAD   = IsNaN(s.samplingIntervalAD) ? s.samplingIntervalDA : s.samplingIntervalAD
	s.samplingIntervalTTL  = IsNaN(s.samplingIntervalTTL) ? s.samplingIntervalDA : s.samplingIntervalTTL
	s.samplingIntervalDA  *= MILLI_TO_MICRO
	s.samplingIntervalAD  *= MILLI_TO_MICRO
	s.samplingIntervalTTL *= MILLI_TO_MICRO

	s.decimationFactor = IsNaN(s.samplingIntervalDA) ? NaN : DC_GetDecimationFactorCalc(s.samplingIntervalDA)

	device = GetLastSettingTextIndep(textualValues, sweepNo, "Device", s.dataAcqOrTP)
	if(IsEmpty(device))
		s.hardwareType = NaN
		DEBUGPRINT("LNB entry not found: Device")
	else
		s.hardwareType = GetHardwareType(device)
	endif

	onsetDelayUserTime = GetLastSettingIndep(numericalValues, sweepNo, "Delay onset user", s.dataAcqOrTP)
	if(IsNaN(onsetDelayUserTime))
		s.onsetDelayUser = NaN
		DEBUGPRINT("LNB entry not found: Delay onset user")
	else
		s.onsetDelayUser = round(onsetDelayUserTime * MILLI_TO_MICRO / s.samplingIntervalDA)
	endif

	onsetDelayAutoTime = GetLastSettingIndep(numericalValues, sweepNo, "Delay onset auto", s.dataAcqOrTP)
	if(IsNaN(onsetDelayAutoTime))
		s.onsetDelayAuto = NaN
		DEBUGPRINT("LNB entry not found: Delay onset auto")
	else
		s.onsetDelayAuto = round(onsetDelayAutoTime * MILLI_TO_MICRO / s.samplingIntervalDA)
	endif

	s.onsetDelay = s.onsetDelayUser + s.onsetDelayAuto

	distributedDAQDelayTime = GetLastSettingIndep(numericalValues, sweepNo, "Delay distributed DAQ", s.dataAcqOrTP)
	if(IsNaN(distributedDAQDelayTime))
		s.distributedDAQDelay = NaN
		DEBUGPRINT("LNB entry not found: Delay distributed DAQ")
	else
		s.distributedDAQDelay = round(distributedDAQDelayTime * MILLI_TO_MICRO / s.samplingIntervalDA)
	endif

	terminationDelayTime = GetLastSettingIndep(numericalValues, sweepNo, "Delay termination", s.dataAcqOrTP)
	if(IsNaN(terminationDelayTime))
		s.terminationDelay = NaN
		DEBUGPRINT("LNB entry not found: Delay termination")
	else
		s.terminationDelay = round(terminationDelayTime * MILLI_TO_MICRO / s.samplingIntervalDA)
	endif

	s.skipAhead = GetLastSettingIndep(numericalValues, sweepNo, "Skip Ahead", s.dataAcqOrTP)
	if(IsNaN(s.skipAhead))
		DEBUGPRINT("LNB entry not found: Skip Ahead")
	endif
End

static Function DCR_RecreateDataConfigurationResultFromLNB_TP(STRUCT DataConfigurationResult &s, WAVE numericalValues, variable sweepNo)

	variable pulseDurationTime, totalLengthPoints, pulseStartPoints, pulseLengthPoints

	if(s.testPulseLength > 0)
		// calculated before with a workaround for old LNBs
		return NaN
	endif
	pulseDurationTime = GetLastSettingIndep(numericalValues, sweepNo, "TP Pulse Duration", s.dataAcqOrTP)
	if(IsNaN(pulseDurationTime))
		DEBUGPRINT("LNB entry not found: TP Pulse Duration")
	endif

	WAVE samplingIntervals = GetNewSamplingIntervalsAsFree()
	samplingIntervals[%SI_TP_DAC]  = NaN
	samplingIntervals[%SI_DAQ_DAC] = s.samplingIntervalDA
	samplingIntervals[%SI_TP_ADC]  = NaN
	samplingIntervals[%SI_DAQ_ADC] = NaN
	WAVE tpSettings = GetTPSettingsFree()
	TPSettings[%baselinePerc][INDEP_HEADSTAGE] = s.baselineFrac * ONE_TO_PERCENT
	TPSettings[%durationMS][INDEP_HEADSTAGE]   = pulseDurationTime
	WAVE tpCalculated = GetTPSettingsCalculatedAsFree()

	TP_UpdateTPSettingsCalculatedImpl(TPSettings, samplingIntervals, tpCalculated)

	[totalLengthPoints, pulseStartPoints, pulseLengthPoints] = TP_GetCreationPropertiesInPoints(tpCalculated, s.dataAcqOrTP)
	s.testPulseLength                                        = totalLengthPoints
	s.tpPulseStartPoint                                      = pulseStartPoints
	s.tpPulseLengthPoints                                    = pulseLengthPoints

	WAVE s.testPulse = GetTestPulseAsFree()
	TP_CreateTestPulseWaveImpl(s.testPulse, s.testPulseLength, s.tpPulseStartPoint, s.tpPulseLengthPoints)
End
