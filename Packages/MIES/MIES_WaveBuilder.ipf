#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict Wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_WB
#endif // AUTOMATED_TESTING

/// @file MIES_WaveBuilder.ipf
/// @brief __WB__ Stimulus set creation

static Constant PULSE_TRAIN_MODE_DUR   = 0x01
static Constant PULSE_TRAIN_MODE_PULSE = 0x02

static Constant WB_PULSE_TRAIN_TYPE_SQUARE   = 0
static Constant WB_PULSE_TRAIN_TYPE_TRIANGLE = 1

static Constant WB_TRIG_TYPE_SIN = 0
static Constant WB_TRIG_TYPE_COS = 1

/// @name Constants for WB_GetControlWithDeltaIdx
/// @anchor ControlDeltaIndizes
/// The numeric values are row indizes in the waves returned by
/// WB_GetControlWithDeltaWvs().
///@{
static Constant WB_IDX_DURATION                 = 0
static Constant WB_IDX_AMPLITUDE                = 2
static Constant WB_IDX_OFFSET                   = 4
static Constant WB_IDX_SIN_CHIRP_SAW_FREQUENCY  = 6
static Constant WB_IDX_TRAIN_PULSE_DURATION     = 8
static Constant WB_IDX_PSC_EXP_RISE_TIME        = 10
static Constant WB_IDX_PSC_EXP_DECAY_TIME_1_2   = 12
static Constant WB_IDX_PSC_EXP_DECAY_TIME_2_2   = 14
static Constant WB_IDX_PSC_RATIO_DECAY_TIMES    = 16
static Constant WB_IDX_LOW_PASS_FILTER_CUT_OFF  = 20
static Constant WB_IDX_HIGH_PASS_FILTER_CUT_OFF = 22
static Constant WB_IDX_CHIRP_END_FREQUENCY      = 24
static Constant WB_IDX_NOISE_FILTER_ORDER       = 26
static Constant WB_IDX_PT_FIRST_MIXED_FREQUENCY = 28
static Constant WB_IDX_PT_LAST_MIXED_FREQUENCY  = 30
static Constant WB_IDX_NUMBER_OF_PULSES         = 45
static Constant WB_IDX_ITI                      = 99
///@}

static Constant DELTA_OPERATION_EXPLICIT = 6

/// @brief Return the stim set wave and create it permanently
/// in the datafolder hierarchy
///
/// @return stimset wave ref or an invalid wave ref
Function/WAVE WB_CreateAndGetStimSet(string setName)

	variable type, needToCreateStimSet

	if(isEmpty(setName))
		return $""
	endif

	type = WB_GetStimSetType(setName)

	if(type == CHANNEL_TYPE_UNKNOWN)
		return $""
	endif

	DFREF           dfr     = GetSetFolder(type)
	WAVE/Z/SDFR=dfr stimSet = $setName
	if(WB_StimsetIsFromThirdParty(setName) || !WB_StimsetNeedsUpdate(setName))
		return stimSet
	endif

	WAVE/Z/SDFR=dfr oldStimSet = $setName
	if(WaveExists(oldStimSet))
		KillOrMoveToTrash(wv = oldStimSet)
	endif

	// create current stimset
	WAVE/Z stimSet = WB_GetStimSet(setName = setName)
	if(WaveExists(stimSet))
		MoveWave stimSet, dfr:$setName
		WAVE/SDFR=dfr stimSet = $setName
	endif

	return stimSet
End

/// @brief Return the name of one of the three stimset parameter waves
///
/// @param stimset   name of stimset
/// @param type      indicate parameter wave (WP, WPT, or SegWvType), see @ref ParameterWaveTypes
/// @param nwbFormat [optional, defaults to false] nwbFormat has type as suffix
/// @return name as string
Function/S WB_GetParameterWaveName(string stimset, variable type, [variable nwbFormat])

	string shortname, fullname

	if(ParamIsDefault(nwbFormat))
		nwbFormat = 0
	else
		nwbFormat = !!nwbFormat
	endif

	shortname = GetWaveBuilderParameterTypeName(type)

	if(nwbFormat)
		sprintf fullname, "%s_%s", stimset, shortname
	else
		sprintf fullname, "%s_%s", shortname, stimset
	endif

	return fullname
End

/// @brief Return the wave `WP` for a stim set
///
/// @return valid/invalid wave reference
Function/WAVE WB_GetWaveParamForSet(string setName)

	variable type

	type = WB_GetStimSetType(setName)

	if(type == CHANNEL_TYPE_UNKNOWN)
		return $""
	endif

	DFREF dfr = GetSetParamFolder(type)

	WAVE/Z/SDFR=dfr wv = $WB_GetParameterWaveName(setName, STIMSET_PARAM_WP)

	if(WaveExists(wv))
		UpgradeWaveParam(wv)
	endif

	return wv
End

/// @brief Return the wave `WPT` for a stim set
///
/// @return valid/invalid wave reference
Function/WAVE WB_GetWaveTextParamForSet(string setName)

	variable type

	type = WB_GetStimSetType(setName)

	if(type == CHANNEL_TYPE_UNKNOWN)
		return $""
	endif

	DFREF dfr = GetSetParamFolder(type)

	WAVE/Z/SDFR=dfr wv = $WB_GetParameterWaveName(setName, STIMSET_PARAM_WPT)

	if(WaveExists(wv))
		UpgradeWaveTextParam(wv)
	endif

	return wv
End

/// @brief Return the wave `SegmentWvType` for a stim set
///
/// @return valid/invalid wave reference
Function/WAVE WB_GetSegWvTypeForSet(string setName)

	variable type

	type = WB_GetStimSetType(setName)

	if(type == CHANNEL_TYPE_UNKNOWN)
		return $""
	endif

	DFREF dfr = GetSetParamFolder(type)

	WAVE/Z/SDFR=dfr wv = $WB_GetParameterWaveName(setName, STIMSET_PARAM_SEGWVTYPE)

	if(WaveExists(wv))
		UpgradeSegWvType(wv)
	endif

	return wv
End

/// @brief Check if stimset needs to be created
///
/// Stimset is recreated
///     * if one of the parameter waves was modified
///     * the custom wave that was used to build the stimset was modified
///
/// @return 1 if stimset needs to be recreated, 0 otherwise
static Function WB_StimsetNeedsUpdate(string setName)

	string stimsets
	variable lastModStimSet, numWaves, numStimsets, i

	// stimset does not exist or wave note is too old
	if(!WB_StimsetExists(setName) || !WB_StimsetHasLatestNoteVersion(setName))
		return 1
	endif

	// check if parameter waves were modified
	stimsets    = WB_StimsetRecursion(parent = setName)
	stimsets    = AddListItem(setName, stimsets)
	numStimsets = ItemsInList(stimsets)
	for(i = 0; i < numStimsets; i += 1)
		if(WB_ParameterWvsNewerThanStim(StringFromList(i, stimsets)))
			return 1
		endif
	endfor

	// check if custom waves were modified
	lastModStimSet = WB_GetLastModStimSet(setName)
	WAVE/WAVE customWaves = WB_CustomWavesFromStimSet(stimsets)
	numWaves = DimSize(customWaves, ROWS)
	for(i = 0; i < numWaves; i += 1)
		ASSERT(WaveExists(customWaves[i]), "customWaves should not contain non-existing wave ref")
		if(modDate(customWaves[i]) > lastModStimSet)
			return 1
		endif
	endfor

	return 0
End

/// @brief Check if the stimset wave note has the latest version
static Function WB_StimsetHasLatestNoteVersion(string setName)

	variable type

	type = WB_GetStimSetType(setName)

	if(type == CHANNEL_TYPE_UNKNOWN)
		return 0
	endif

	DFREF           dfr     = GetSetFolder(type)
	WAVE/Z/SDFR=dfr stimSet = $setName

	if(!WaveExists(stimset))
		return 0
	endif

	return WB_GetWaveNoteEntryAsNumber(note(stimset), VERSION_ENTRY) >= STIMSET_NOTE_VERSION
End

/// @brief Check if parameter waves' are newer than the saved stimset
///
/// @param setName	string containing name of stimset
///
/// @return 1 if Parameter waves were modified, 0 otherwise
static Function WB_ParameterWvsNewerThanStim(string setName)

	variable lastModStimSet, lastModWP, lastModWPT, lastModSegWvType, channelType
	string msg, WPModCount, WPTModCount, SegWvTypeModCount

	WAVE/Z   WP        = WB_GetWaveParamForSet(setName)
	WAVE/Z/T WPT       = WB_GetWaveTextParamForSet(setName)
	WAVE/Z   SegWvType = WB_GetSegWvTypeForSet(setName)

	lastModStimSet = WB_GetLastModStimSet(setName)
	if(WaveExists(WP) && WaveExists(WPT) && WaveExists(SegWvType))
		lastModWP        = modDate(WP)
		lastModWPT       = modDate(WPT)
		lastModSegWvType = modDate(SegWvType)

		sprintf msg, "stimset %d, WP %d, WPT %d, SegWvType %d", lastModStimSet, lastModWP, lastModWPT, lastModSegWvType
		DEBUGPRINT(msg)

		if(lastModWP > lastModStimSet || lastModWPT > lastModStimSet || lastModSegWvType > lastModStimSet)
			return 1
		endif

		if(lastModWP == lastModStimSet || lastModWPT == lastModStimSet || lastModSegWvType == lastModStimSet)
			channelType = WB_GetStimSetType(setName)
			ASSERT(channelType != CHANNEL_TYPE_UNKNOWN, "Invalid channel type")

			DFREF           dfr     = GetSetFolder(channelType)
			WAVE/Z/SDFR=dfr stimSet = $setName
			ASSERT(WaveExists(stimSet), "Unexpected missing wave")

			WPModCount        = GetStringFromWaveNote(stimSet, "WP modification count", keySep = "=")
			WPTModCount       = GetStringFromWaveNote(stimSet, "WPT modification count", keySep = "=")
			SegWvTypeModCount = GetStringFromWaveNote(stimSet, "SegWvType modification count", keySep = "=")

			sprintf msg, "WPModCount %s, WPTModCount %s, SegWvTypeModCount %s", WPModCount, WPTModCount, SegWvTypeModCount
			DEBUGPRINT(msg)

			if(IsEmpty(WPModCount) || IsEmpty(WPTModCount) || IsEmpty(SegWvTypeModCount))
				// old stimset without these entries, force recreation
				return 1
			endif

			if(WaveModCountWrapper(WP) > str2num(WPModCount)                 \
			   || WaveModCountWrapper(WPT) > str2num(WPTModCount)            \
			   || WaveModCountWrapper(SegWvType) > str2num(SegWvTypeModCount))
				return 1
			endif
		endif
	endif

	return 0
End

/// @brief Return a checksum of the stimsets and its parameter waves.
///
/// Uses the entry from the stimset wave note if available.
Function WB_GetStimsetChecksum(WAVE stimset, string setName, variable dataAcqOrTP)

	variable crc

	if(dataAcqOrTP == TEST_PULSE_MODE)
		return NaN
	endif

	crc = NumberByKey("Checksum", note(stimset), " = ", ";")

	if(IsFinite(crc))
		return crc
	endif

	// old stimsets without the wave note entry
	return WB_CalculateStimsetChecksum(stimset, setName)
End

/// @brief Calculcate the checksum of the stimsets and its parameter waves.
static Function WB_CalculateStimsetChecksum(WAVE stimset, string setName)

	variable crc

	crc = WaveCRC(crc, stimset)

	WAVE/Z   WP        = WB_GetWaveParamForSet(setName)
	WAVE/Z/T WPT       = WB_GetWaveTextParamForSet(setName)
	WAVE/Z   SegWvType = WB_GetSegWvTypeForSet(setName)

	if(WaveExists(WP) && WaveExists(WPT) && WaveExists(SegWvType))
		crc = WaveCRC(crc, WP)
		crc = WaveCRC(crc, WPT)
		crc = WaveCRC(crc, SegWvType)
	endif

	return crc
End

/// @brief Get modification date of saved stimset wave
///
/// @param setName	string containing name of stimset
/// @return date of last modification as double precision Igor date/time value
Function WB_GetLastModStimSet(string setName)

	variable channelType

	channelType = WB_GetStimSetType(setName)

	if(channelType == CHANNEL_TYPE_UNKNOWN)
		return 0
	endif

	DFREF           dfr     = GetSetFolder(channelType)
	WAVE/Z/SDFR=dfr stimSet = $setName
	if(!WaveExists(stimSet))
		return 0
	endif

	return modDate(stimSet)
End

/// @brief Return the current stimset wave for the wavebuilder
Function/WAVE WB_GetStimSetForWaveBuilder()

	return WB_GetStimSet()
End

/// @brief Return the stim set wave
///
/// As opposed to #WB_CreateAndGetStimSet this function returns a free wave only
///
/// @param setName [optional, defaults to WaveBuilderPanel GUI settings] name of the set
/// @return free wave with the stim set, invalid wave ref if the `WP*` parameter waves could
/// not be found.
static Function/WAVE WB_GetStimSet([string setName])

	variable i, numEpochs, numSweeps, numStimsets, updateEpochIDWave
	variable last, lengthOf1DWaves, length, channelType
	variable referenceTime = DEBUG_TIMER_START()
	string stimSetList, stimSetName

	if(ParamIsDefault(setName))
		stimSetList = WB_StimsetRecursion()
	else
		stimSetList = WB_StimsetRecursion(parent = setName)
		ASSERT(WhichListItem(setName, stimSetList) == -1, "invalid stimset: stimset references itself")
	endif

	// recursive stimset creation: first stimsets have deepest dependence
	numStimsets = ItemsInList(stimSetList)
	for(i = 0; i < numStimSets; i += 1)
		stimSetName = StringFromList(i, stimSetList)
		if(WB_StimsetNeedsUpdate(stimSetName))
			WB_CreateAndGetStimSet(stimSetName)
		endif
	endfor

	if(ParamIsDefault(setName))
		updateEpochIDWave = 1

		WAVE   WP        = GetWaveBuilderWaveParam()
		WAVE/T WPT       = GetWaveBuilderWaveTextParam()
		WAVE   SegWvType = GetSegmentTypeWave()
		channelType = WBP_GetStimulusType()

		setName = ""
	else
		WAVE/Z   WP        = WB_GetWaveParamForSet(setName)
		WAVE/Z/T WPT       = WB_GetWaveTextParamForSet(setName)
		WAVE/Z   SegWvType = WB_GetSegWvTypeForSet(setName)
		channelType = WB_GetStimSetType(setName)

		if(!WaveExists(WP) || !WaveExists(WPT) || !WaveExists(SegWvType))
			return $""
		endif
	endif

	ASSERT(channelType != CHANNEL_TYPE_UNKNOWN, "Unexpected channel type")

	// WB_AddDelta modifies the waves so we pass a copy instead
	Duplicate/FREE WP, WPCopy
	Duplicate/FREE SegWvType, SegWvTypeCopy

	numSweeps = SegWvType[101]
	numEpochs = SegWvType[100]

	ASSERT(numSweeps > 0, "Invalid number of sweeps")

	MAKE/WAVE/FREE/N=(numSweeps) data

	for(i = 0; i < numSweeps; i += 1)
		data[i]         = WB_MakeWaveBuilderWave(WPCopy, WPT, SegWvTypeCopy, i, numEpochs, channelType, updateEpochIDWave, stimset = setName)
		lengthOf1DWaves = max(DimSize(data[i], ROWS), lengthOf1DWaves)
		if((i + 1) < numSweeps)
			if(WB_AddDelta(setName, WPCopy, WP, WPT, SegWvTypeCopy, SegWvType, i, numSweeps))
				return $""
			endif
		endif
	endfor

	// copy the random seed value in order to preserve it
	WP[48][][]    = WPCopy[48][q][r]
	SegWvType[97] = SegWvTypeCopy[97]

	Make/FREE/N=(lengthOf1DWaves, numSweeps) stimSet
	for(WAVE wv : data)
		Note/NOCR stimSet, note(wv)
	endfor
	if(lengthOf1DWaves == 0)
		return stimSet
	endif

	FastOp stimSet = 0

	// note: here the stimset generation is coupled to the ITC minimum sample interval which is 200 kHz wheras for NI it is 500 kHz
	SetScale/P x, 0, WAVEBUILDER_MIN_SAMPINT, "ms", stimset

	for(i = 0; i < numSweeps; i += 1)
		WAVE wv = data[i]

		length = DimSize(wv, ROWS)
		if(length == 0)
			continue
		endif

		last = length - 1
		Multithread stimSet[0, last][i] = wv[p]

		WB_AppendSweepMinMax(stimSet, i, numSweeps, numEpochs)
	endfor

	if(SegWvType[98])
		Duplicate/FREE stimset, stimsetFlipped
		for(i = 0; i < numSweeps; i += 1)
			Duplicate/FREE/R=[][i] stimset, singleSweep
			WaveTransForm/O flip, singleSweep
			Multithread stimSetFlipped[][i] = singleSweep[p]
		endfor
		WAVE stimset = stimsetFlipped
	endif
	AddEntryIntoWaveNoteAsList(stimset, STIMSET_SIZE_KEY, var = DimSize(stimset, ROWS), format = "%d")

	if(!isEmpty(setName))
		AddEntryIntoWaveNoteAsList(stimset, "Checksum", var = WB_CalculateStimsetChecksum(stimset, setName), format = "%d")
		AddEntryIntoWaveNoteAsList(stimset, "WP modification count", var = WaveModCountWrapper(WP), format = "%d")
		AddEntryIntoWaveNoteAsList(stimset, "WPT modification count", var = WaveModCountWrapper(WPT), format = "%d")
		AddEntryIntoWaveNoteAsList(stimset, "SegWvType modification count", var = WaveModCountWrapper(SegWvType), format = "%d", appendCR = 1)
	endif

	DEBUGPRINT_ELAPSED(referenceTime)

	return stimSet
End

/// @brief Return a free wave with indizes referencing the values with delta values
///
/// Indizes are into `WP` and reference the entry with the value itself.
/// @sa AddDimLabelsToWP()
///
/// Constants are defined at @ref ControlDeltaIndizes.
static Function/WAVE WB_GetControlWithDeltaIdx()

	Make/FREE/B indizes = {WB_IDX_DURATION,                 \
	                       WB_IDX_AMPLITUDE,                \
	                       WB_IDX_OFFSET,                   \
	                       WB_IDX_SIN_CHIRP_SAW_FREQUENCY,  \
	                       WB_IDX_TRAIN_PULSE_DURATION,     \
	                       WB_IDX_PSC_EXP_RISE_TIME,        \
	                       WB_IDX_PSC_EXP_DECAY_TIME_1_2,   \
	                       WB_IDX_PSC_EXP_DECAY_TIME_2_2,   \
	                       WB_IDX_PSC_RATIO_DECAY_TIMES,    \
	                       WB_IDX_LOW_PASS_FILTER_CUT_OFF,  \
	                       WB_IDX_HIGH_PASS_FILTER_CUT_OFF, \
	                       WB_IDX_CHIRP_END_FREQUENCY,      \
	                       WB_IDX_NOISE_FILTER_ORDER,       \
	                       WB_IDX_PT_FIRST_MIXED_FREQUENCY, \
	                       WB_IDX_PT_LAST_MIXED_FREQUENCY,  \
	                       WB_IDX_NUMBER_OF_PULSES,         \
	                       WB_IDX_ITI}

	return indizes
End

/// @brief Return a free wave with wave references where the values with delta reside in
///
/// @sa AddDimLabelsToWP()
static Function/WAVE WB_GetControlWithDeltaWvs(WAVE WP, WAVE SegWvType)

	Make/FREE/WAVE locations = {WP, WP, WP, WP, WP, WP, WP, WP, WP, WP, WP, WP, WP, WP, WP, WP, SegWvType}
	return locations
End

/// @brief Return the `WP`/`WPT/SegWvType` dimension labels for the related delta controls
/// given the index into `WP` of the value itself.
///
/// @return 0 on success, 1 otherwise
Function WB_GetDeltaDimLabel(WAVE wv, variable index, STRUCT DeltaControlNames &s)

	string name

	if(index >= DimSize(wv, ROWS))
		InitDeltaControlNames(s)
		return 1
	endif

	name = GetDimLabel(wv, ROWS, index)

	if(IsEmpty(name))
		InitDeltaControlNames(s)
		return 1
	endif

	s.main   = name
	s.delta  = name + " delta"
	s.dme    = name + " dme"
	s.ldelta = name + " ldel"
	s.op     = name + " op"

	return 0
End

/// @brief Add delta to appropriate parameters
///
/// Relies on alternating sequence of parameter and delta's in parameter waves
/// as documented in WB_MakeWaveBuilderWave().
///
/// @param setName       name of the stimset
/// @param WP            wavebuilder parameter wave (temporary copy)
/// @param WPOrig        wavebuilder parameter wave (original)
/// @param WPT           wavebuilder text parameter wave
/// @param SegWvType     segment parameter wave (temporary copy)
/// @param SegWvTypeOrig segment parameter wave (original)
/// @param sweep         sweep number
/// @param numSweeps     total number of sweeps
static Function WB_AddDelta(string setName, WAVE WP, WAVE WPOrig, WAVE/T WPT, WAVE SegWvType, WAVE SegWvTypeOrig, variable sweep, variable numSweeps)

	variable i, j
	variable operation
	variable type, numEntries, numEpochs
	string entry, ldelta
	variable value, delta, dme, originalValue, ret

	if(isEmpty(setName))
		setName = "Default"
	endif

	numEpochs = SegWvType[%$("Total number of epochs")]

	WAVE      indizes   = WB_GetControlWithDeltaIdx()
	WAVE/WAVE locations = WB_GetControlWithDeltaWvs(WP, SegWvType)
	ASSERT(DimSize(indizes, ROWS) == DimSize(locations, ROWS), "Unmatched wave sizes")

	numEntries = DimSize(indizes, ROWS)
	for(i = 0; i < numEntries; i += 1)

		STRUCT DeltaControlNames s
		WB_GetDeltaDimLabel(locations[i], indizes[i], s)

		if(WaveRefsEqual(locations[i], SegWvType))
			operation     = SegWvType[%$s.op]
			value         = SegWvType[%$s.main]
			delta         = SegWvType[%$s.delta]
			dme           = SegWvType[%$s.dme]
			ldelta        = WPT[%$s.ldelta][%Set][INDEP_EPOCH_TYPE]
			originalValue = SegWvTypeOrig[%$s.main]

			ret = WB_CalculateParameterWithDelta(operation, value, delta, dme, ldelta, originalValue, sweep, numSweeps, setName, s.main)

			if(ret)
				return ret
			endif

			SegWvType[%$s.main]  = value
			SegWvType[%$s.delta] = delta

			continue
		endif

		ASSERT(WaveRefsEqual(locations[i], WP), "Unexpected wave reference")

		for(j = 0; j < numEpochs; j += 1)
			type = SegWvType[j]

			// special handling for "Number of pulses"
			// don't do anything if the number of pulses is calculated
			// and not entered
			if(indizes[i] == 45 && !WP[46][j][type])
				continue
			endif

			operation     = WP[%$s.op][j][type]
			value         = WP[%$s.main][j][type]
			delta         = WP[%$s.delta][j][type]
			dme           = WP[%$s.dme][j][type]
			ldelta        = WPT[%$s.ldelta][j][type]
			originalValue = WPOrig[%$s.main][j][type]

			ret = WB_CalculateParameterWithDelta(operation, value, delta, dme, ldelta, originalValue, sweep, numSweeps, setName, s.main)

			if(ret)
				return ret
			endif

			WP[%$s.main][j][type]  = value
			WP[%$s.delta][j][type] = delta
		endfor
	endfor

	return 0
End

/// @brief Calculate the new value of a parameter taking into account the delta operation
///
/// @param[in]      operation     delta operation, one of @ref WaveBuilderDeltaOperationModes
/// @param[in, out] value         parameter value (might be incremented by former delta application calls)
/// @param[in, out] delta         delta value
/// @param[in]      dme           delta multiplier or exponent
/// @param[in]      ldelta        explicit list of delta values
/// @param[in]      originalValue unmodified parameter value
/// @param[in]      sweep         sweep number
/// @param[in]      numSweeps     number of sweeps
/// @param[in]      setName       name of the stimulus set (used for error reporting)
/// @param[in]      paramName     name of the parameter (used for error reporting)
static Function WB_CalculateParameterWithDelta(variable operation, variable &value, variable &delta, variable dme, string ldelta, variable originalValue, variable sweep, variable numSweeps, string setName, string paramName)

	string list, entry
	variable listDelta, numDeltaEntries

	if(operation != DELTA_OPERATION_EXPLICIT)
		// add the delta value
		value += delta
	endif

	switch(operation)
		case DELTA_OPERATION_DEFAULT:
			// delta is constant
			break
		case DELTA_OPERATION_FACTOR:
			delta = delta * dme
			break
		case DELTA_OPERATION_LOG:
			// ignore a delta value of exactly zero
			delta = (delta == 0) ? 0 : log(delta)
			break
		case DELTA_OPERATION_SQUARED:
			delta = (delta)^2
			break
		case DELTA_OPERATION_POWER:
			delta = (delta)^(dme)
			break
		case DELTA_OPERATION_ALTERNATE:
			delta *= -1
			break
		case DELTA_OPERATION_EXPLICIT:
			list            = ldelta
			numDeltaEntries = ItemsInList(ldelta)
			// only warn once
			if(numDeltaEntries >= numSweeps && sweep == 0)
				printf "WB_AddDelta: Stimset \"%s\" has too few sweeps for the explicit delta values list \"%s\" of \"%s\"\r", setName, list, paramName
			elseif(sweep >= numDeltaEntries)
				printf "WB_AddDelta: Stimset \"%s\" has too many sweeps for the explicit delta values list \"%s\" of \"%s\"\r", setName, list, paramName
				listDelta = 0
			else
				entry     = StringFromList(sweep, ldelta)
				listDelta = str2numSafe(entry)

				if(IsNaN(listDelta))
					printf "WB_AddDelta: Stimset \"%s\" has an invalid entry \"%s\" in the explicit delta values list \"%s\" of \"%s\"\r", setName, entry, list, paramName
					value = 0
				endif
			endif

			value = originalValue + listDelta
			break
		default:
			// future proof
			printf "WB_AddDelta: Stimset %s uses an unknown operation %g and can therefore not be recreated.\r", setName, operation
			return 1
			break
	endswitch

	return 0
End

static Structure SegmentParameters
	variable duration // ms
	variable deltaDur
	variable amplitude
	variable deltaAmp
	variable offset
	variable frequency
	variable deltaFreq
	variable pulseDuration
	variable tauRise
	variable tauDecay1
	variable tauDecay2
	variable tauDecay2Weight
	variable lowPassCutOff
	variable highPassCutOff
	variable filterOrder
	variable endFrequency
	variable numberOfPulses
	// checkboxes
	variable poisson
	variable logChirp // 0: no chirp, 1: log chirp
	variable randomSeed
	// popupmenues
	variable trigFuncType // 0: WB_TRIG_TYPE_SIN, 1: WB_TRIG_TYPE_COS
	variable noiseType // 0: white, 1: pink, 2:brown
	variable noiseGenMode // 2: NOISE_GEN_MERSENNE_TWISTER, 3: NOISE_GEN_XOSHIRO
	variable noiseGenModePTMixedFreq // 1: NOISE_GEN_LINEAR_CONGRUENTIAL, 3: NOISE_GEN_XOSHIRO
	variable buildResolution // value, not the popup menu index
	variable pulseType // 0: square, 1: triangle
	variable mixedFreq
	variable mixedFreqShuffle
	variable firstFreq
	variable lastFreq
EndStructure

static Function/WAVE WB_MakeWaveBuilderWave(WAVE WP, WAVE/T WPT, WAVE SegWvType, variable stepCount, variable numEpochs, variable channelType, variable updateEpochIDWave, [string stimset])

	if(ParamIsDefault(stimset))
		stimset = ""
	endif

	Make/FREE/N=0 WaveBuilderWave

	string customWaveName, debugMsg, defMode, formula, formula_version
	variable i, j, type, accumulatedDuration, pulseToPulseLength, first, last, segmentLength, buildError
	STRUCT SegmentParameters params

	if(stepCount == 0)
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Version", var = STIMSET_NOTE_VERSION, appendCR = 1)
	endif

	AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Sweep", var = stepCount)
	AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch", var = NaN)
	AddEntryIntoWaveNoteAsList(WaveBuilderWave, "ITI", var = SegWvType[99], appendCR = 1)
	// Minimum, Maximum is appended later

	for(i = 0; i < numEpochs; i += 1)
		type = SegWvType[i]

		params.duration         = WP[0][i][type]
		params.deltaDur         = WP[1][i][type]
		params.amplitude        = WP[2][i][type]
		params.deltaAmp         = WP[3][i][type]
		params.offset           = WP[4][i][type]
		params.frequency        = WP[6][i][type]
		params.pulseDuration    = WP[8][i][type]
		params.tauRise          = WP[10][i][type]
		params.tauDecay1        = WP[12][i][type]
		params.tauDecay2        = WP[14][i][type]
		params.tauDecay2Weight  = WP[16][i][type]
		params.lowPassCutOff    = WP[20][i][type]
		params.highPassCutOff   = WP[22][i][type]
		params.endFrequency     = WP[24][i][type]
		params.filterOrder      = WP[26][i][type]
		params.logChirp         = WP[43][i][type]
		params.poisson          = WP[44][i][type]
		params.numberOfPulses   = WP[45][i][type]
		params.trigFuncType     = WP[53][i][type]
		params.noiseType        = WP[54][i][type]
		params.buildResolution  = NumberFromList(WP[55][i][type], WBP_GetNoiseBuildResolution())
		params.pulseType        = WP[56][i][type]
		params.mixedFreq        = WP[41][i][type]
		params.mixedFreqShuffle = WP[42][i][type]
		params.firstFreq        = WP[28][i][type]
		params.lastFreq         = WP[30][i][type]

		sprintf debugMsg, "step count: %d, epoch: %d, duration: %g (delta %g), amplitude %d (delta %g)\r", stepCount, i, params.duration, params.DeltaDur, params.amplitude, params.DeltaAmp
		DEBUGPRINT("params", str = debugMsg)

		if(params.duration < 0 || !IsFinite(params.duration))
			printf "Stimset %s: User input has generated a negative/non-finite epoch duration. Please adjust input. Duration for epoch has been reset to 1 ms.\r", stimset
			params.duration = 1
		elseif(params.duration == 0 && type != EPOCH_TYPE_CUSTOM && type != EPOCH_TYPE_COMBINE && type != EPOCH_TYPE_PULSE_TRAIN)
			if(updateEpochIDWave && stepCount == 0)
				WB_UpdateEpochID(i, params.duration, accumulatedDuration)
			endif
			ASSERT(params.duration == 0, "Unexpected duration")

			AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Sweep", var = stepCount)
			AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch", var = i)
			AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type", str = WB_ToEpochTypeString(type))
			AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration", var = params.Duration, appendCR = 1)
			continue
		endif

		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Sweep", var = stepCount)
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch", var = i)
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type", str = WB_ToEpochTypeString(type))

		switch(type)
			case EPOCH_TYPE_SQUARE_PULSE:
				WB_SquareSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration", var = params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude", var = params.Amplitude)
				break
			case EPOCH_TYPE_RAMP:
				WB_RampSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration", var = params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude", var = params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset", var = params.Offset)
				break
			case EPOCH_TYPE_NOISE:
				params.randomSeed   = WB_InitializeSeed(WP, SegWvType, i, type, stepCount)
				params.noiseGenMode = WP[86][i][type]

				WB_NoiseSegment(params)
				WAVE segmentWave = GetSegmentWave()
				WBP_ShowFFTSpectrumIfReq(segmentWave, stepCount)

				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration", var = params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude", var = params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset", var = params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Noise Type",                             \
				                           str = StringFromList(params.noiseType, NOISE_TYPES_STRINGS))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Low pass cut off", var = params.LowPassCutOff)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "High pass cut off", var = params.HighPassCutOff)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Filter order", var = params.filterOrder)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Build resolution", var = params.buildResolution)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Random seed", var = params.randomSeed)
				break
			case EPOCH_TYPE_SIN_COS:
				[WAVE inflectionPoints, WAVE inflectionIndices] = WB_TrigSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration", var = params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude", var = params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset", var = params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency", var = params.Frequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "End frequency", var = params.EndFrequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Log chirp", str = ToTrueFalse(params.logChirp))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "FunctionType", str = StringFromList(params.trigFuncType, WAVEBUILDER_TRIGGER_TYPES))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Inflection Points", str = NumericWaveToList(inflectionPoints, ",", format = "%.15g"))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, INFLECTION_POINTS_INDEX_KEY, str = NumericWaveToList(inflectionIndices, ",", format = "%.15g"))
				break
			case EPOCH_TYPE_SAW_TOOTH:
				WB_SawToothSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration", var = params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude", var = params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency", var = params.Frequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset", var = params.Offset)
				break
			case EPOCH_TYPE_PULSE_TRAIN:
				params.randomSeed              = WB_InitializeSeed(WP, SegWvType, i, type, stepCount)
				params.noiseGenMode            = WP[86][i][type]
				params.noiseGenModePTMixedFreq = WP[87][i][type]

				if(WP[46][i][type]) // "Number of pulses" checkbox
					[WAVE pulseStartTimes, WAVE pulseStartIndices, WAVE pulseEndIndices, pulseToPulseLength] = WB_PulseTrainSegment(params, PULSE_TRAIN_MODE_PULSE)
					if(windowExists("WaveBuilder")                                             \
					   && GetTabID("WaveBuilder", "WBP_WaveType") == EPOCH_TYPE_PULSE_TRAIN    \
					   && GetSetVariable("WaveBuilder", "setvar_WaveBuilder_CurrentEpoch") == i)
						WBP_UpdateControlAndWave("SetVar_WaveBuilder_P0", var = params.duration)
					endif
					defMode = "Pulse"
				else
					[WAVE pulseStartTimes, WAVE pulseStartIndices, WAVE pulseEndIndices, pulseToPulseLength] = WB_PulseTrainSegment(params, PULSE_TRAIN_MODE_DUR)
					if(windowExists("WaveBuilder")                                             \
					   && GetTabID("WaveBuilder", "WBP_WaveType") == EPOCH_TYPE_PULSE_TRAIN    \
					   && GetSetVariable("WaveBuilder", "setvar_WaveBuilder_CurrentEpoch") == i)
						WBP_UpdateControlAndWave("SetVar_WaveBuilder_P45", var = params.numberOfPulses)
					endif
					defMode = "Duration"
				endif

				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration", var = params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude", var = params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset", var = params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Pulse Type",                             \
				                           str = StringFromList(params.pulseType, PULSE_TYPES_STRINGS))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency", var = params.Frequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, PULSE_TO_PULSE_LENGTH_KEY, var = pulseToPulseLength)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Pulse duration", var = params.PulseDuration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Number of pulses", var = params.NumberOfPulses)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Mixed frequency", str = ToTrueFalse(params.mixedFreq))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Mixed frequency shuffle", str = ToTrueFalse(params.mixedFreqShuffle))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "First mixed frequency", var = params.firstFreq)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Last mixed frequency", var = params.lastFreq)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Poisson distribution", str = ToTrueFalse(params.poisson))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Random seed", var = params.randomSeed)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, PULSE_START_TIMES_KEY, str = NumericWaveToList(pulseStartTimes, ",", format = "%.15g"))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, PULSE_START_INDICES_KEY, str = NumericWaveToList(pulseStartIndices, ",", format = "%d"))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, PULSE_END_INDICES_KEY, str = NumericWaveToList(pulseEndIndices, ",", format = "%d"))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Definition mode", str = defMode)
				break
			case EPOCH_TYPE_PSC:
				WB_PSCSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration", var = params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude", var = params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset", var = params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau rise", var = params.TauRise)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau decay 1", var = params.TauDecay1)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau decay 2", var = params.TauDecay2)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau decay 2 weight", var = params.TauDecay2Weight)
				break
			case EPOCH_TYPE_CUSTOM:
				WAVE segmentWave = GetSegmentWave(duration = 0)
				WB_UpgradecustomWaveInWPT(WPT, channelType, i)
				customWaveName = WPT[0][i][EPOCH_TYPE_CUSTOM]
				WAVE/Z customWave = $customWaveName
				if(WaveExists(customWave))
					WB_CustomWaveSegment(params, customWave)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration", var = params.Duration)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset", var = params.Offset)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "CustomWavePath", str = customWaveName)
				elseif(!isEmpty(customWaveName))
					printf "Stimset %s: Failed to recreate custom wave epoch %d as the referenced wave %s is missing\r", stimset, i, customWaveName
					buildError = WAVEBUILDER_STATUS_ERROR
				endif
				WaveClear customWave
				break
			case EPOCH_TYPE_COMBINE:
				WAVE segmentWave = GetSegmentWave(duration = 0)

				formula         = WPT[6][i][EPOCH_TYPE_COMBINE]
				formula_version = WPT[7][i][EPOCH_TYPE_COMBINE]

				if(cmpstr(formula_version, WAVEBUILDER_COMBINE_FORMULA_VER))
					printf "Stimset %s: Could not create the wave from formula of version %s\r", stimset, WAVEBUILDER_COMBINE_FORMULA_VER
					break
				endif

				WAVE/Z combinedWave = WB_FillWaveFromFormula(formula, channelType, stepCount)

				if(!WaveExists(combinedWave))
					printf "Stimset %s: Could not create the wave from the formula\r", stimset
					buildError = WAVEBUILDER_STATUS_ERROR
					break
				endif

				Duplicate/O combinedWave, segmentWave

				params.Duration = DimSize(segmentWave, ROWS) * WAVEBUILDER_MIN_SAMPINT

				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Formula", str = formula)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Formula Version", str = formula_version)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration", var = params.Duration)
				break
			default:
				printf "Stimset %s: Ignoring unknown epoch type %d\r", stimset, type
				continue
		endswitch

		if(type != EPOCH_TYPE_COMBINE)
			WB_ApplyOffset(params)
		endif

		if(updateEpochIDWave && stepCount == 0)
			WB_UpdateEpochID(i, params.duration, accumulatedDuration)
		endif

		accumulatedDuration += params.duration

		WAVE/Z segmentWave = GetSegmentWave()
		segmentLength = WaveExists(segmentWave) ? DimSize(segmentWave, ROWS) : 0
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, EPOCH_LENGTH_INDEX_KEY, var = segmentLength, format = "%d")
		if(WaveExists(segmentWave))
			Concatenate/NP=0 {segmentWave}, WaveBuilderWave
		endif

		// add CR as we have finished an epoch
		Note/NOCR WaveBuilderWave, "\r"
	endfor

	// adjust epochID timestamps for stimset flipping
	if(updateEpochIDWave && SegWvType[98])
		if(stepCount == 0)
			WAVE epochID = GetEpochID()
			for(i = 0; i < numEpochs; i += 1)
				first                  = epochID[i][%timeBegin]
				last                   = epochID[i][%timeEnd]
				epochID[i][%timeEnd]   = accumulatedDuration - first
				epochID[i][%timeBegin] = accumulatedDuration - last
			endfor
		endif
	endif

	// add stimset entries at last step
	if((stepCount + 1) == SegWvType[101])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Stimset")
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Sweep Count", var = SegWvType[101])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch Count", var = numEpochs)
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST), str = WPT[1][%Set][INDEP_EPOCH_TYPE])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST), str = WPT[2][%Set][INDEP_EPOCH_TYPE])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST), str = WPT[3][%Set][INDEP_EPOCH_TYPE])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(POST_SET_EVENT, EVENT_NAME_LIST), str = WPT[4][%Set][INDEP_EPOCH_TYPE])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST), str = WPT[5][%Set][INDEP_EPOCH_TYPE])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(PRE_SWEEP_CONFIG_EVENT, EVENT_NAME_LIST), str = WPT[8][%Set][INDEP_EPOCH_TYPE])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(GENERIC_EVENT, EVENT_NAME_LIST), str = WPT[9][%Set][INDEP_EPOCH_TYPE])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST), str = WPT[27][%Set][INDEP_EPOCH_TYPE])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, ANALYSIS_FUNCTION_PARAMS_STIMSET, str = WPT[%$"Analysis function params (encoded)"][%Set][INDEP_EPOCH_TYPE])

		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Flip", var = SegWvType[98])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Random Seed", var = SegWvType[97])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, STIMSET_ERROR_KEY, var = buildError)
	endif

	return WaveBuilderWave
End

static Function WB_AppendSweepMinMax(WAVE wv, variable sweep, variable numSweeps, variable numEpochs)

	variable minimum, maximum, idx, first, last, trailSep
	string entry

	first = (sweep == 0)
	last  = ((sweep + 1) == numSweeps)

	MatrixOP/FREE singleSweep = col(wv, sweep)

	[minimum, maximum] = WaveMinAndMax(singleSweep)

	WAVE/T wvNote = ListToTextWave(note(wv), "\r")
	//  "Version" line preceds the first sweep
	idx = 1 + sweep * (numEpochs + 1)

	sprintf entry, "Minimum = %.15g;", minimum
	wvNote[idx] += entry

	sprintf entry, "Maximum = %.15g;", maximum
	wvNote[idx] += entry

	// append a trailing CR except for the last entry
	trailSep = !last

	Note/K wv, TextWaveToList(wvNote, "\r", trailSep = trailSep)
End

/// @brief Update the accumulated stimset duration for the mouse selection via GetEpochID()
///
/// @param[in] epochIndex          index of the epoch
/// @param[in] epochDuration       duration of the current segment
/// @param[in] accumulatedDuration accumulated duration in the stimset for the first step
static Function WB_UpdateEpochID(variable epochIndex, variable epochDuration, variable accumulatedDuration)

	WAVE epochID = GetEpochID()
	if(epochIndex == 0)
		epochID = 0
	endif

	epochID[epochIndex][%timeBegin] = accumulatedDuration
	epochID[epochIndex][%timeEnd]   = accumulatedDuration + epochDuration
End

/// @brief Query the stimset wave note for the sweep/set specific ITI
Function WB_GetITI(WAVE stimset, variable sweep)

	variable ITI

	// per sweep ITI
	ITI = WB_GetWaveNoteEntryAsNumber(note(stimset), SWEEP_ENTRY, key = "ITI", sweep = sweep)

	if(IsFinite(ITI))
		return ITI
	endif

	// per stimset ITI (legacy stimsets, which were not recreated)
	ITI = WB_GetWaveNoteEntryAsNumber(note(stimset), STIMSET_ENTRY, key = "ITI")

	if(IsFinite(ITI))
		return ITI
	endif

	// third party stimsets with no ITI at all
	return 0
End

/// @brief Try to recover a custom wave when in the old format
///        (aka with only a wave name and not a full path)
///
/// @param wv          WPT wave reference
/// @param channelType AD/DA or TTL channel type
/// @param i           index of epoch containing custom wave
Function WB_UpgradeCustomWaveInWPT(WAVE/T wv, variable channelType, variable i)

	string customWaveName = wv[0][i][EPOCH_TYPE_CUSTOM]

	// old style entries with only the wave name
	if(!isEmpty(customWaveName) && strsearch(customWaveName, ":", 0) == -1)
		printf "Warning: Legacy format for custom wave epochs detected.\r"

		if(windowExists("Wavebuilder"))
			DFREF                     customWaveDFR = WBP_GetFolderPath()
			WAVE/Z/SDFR=customWaveDFR customWave    = $customWaveName
		endif

		if(!WaveExists(customWave))
			DFREF                     customWaveDFR = GetSetFolder(channelType)
			WAVE/Z/SDFR=customWaveDFR customWave    = $customWaveName
		endif

		if(!WaveExists(customWave))
			DFREF                     customWaveDFR = root:
			WAVE/Z/SDFR=customWaveDFR customWave    = $customWaveName
		endif

		if(WaveExists(customWave))
			printf "Upgraded custom wave format successfully.\r"
			wv[0][i][EPOCH_TYPE_CUSTOM] = GetWavesDataFolder(customWave, 2)
		endif
	endif
End

static Function WB_ApplyOffset(STRUCT SegmentParameters &pa)

	if(pa.offset == 0)
		return NaN
	endif

	WAVE SegmentWave = GetSegmentWave()

	MultiThread segmentWave[] += pa.offset
End

/// @brief Initialize the seed value of the pseudo random number generator
static Function WB_InitializeSeed(WAVE WP, WAVE SegWvType, variable epoch, variable type, variable stepCount)

	variable j, randomSeed, noiseGenMode

	noiseGenMode = WP[86][epoch][type]

	// initialize the random seed value if not already done
	// per epoch seed
	if(WP[48][epoch][type] == 0)
		NewRandomSeed()
		WP[48][epoch][type] = GetReproducibleRandom(noiseGenMode = noiseGenMode)
	endif

	// global stimset seed
	if(SegWvType[97] == 0)
		NewRandomSeed()
		SegWvType[97] = GetReproducibleRandom(noiseGenMode = noiseGenMode)
	endif

	if(WP[39][epoch][type])
		randomSeed = WP[48][epoch][type]
	else
		randomSeed = SegWvType[97]
	endif

	SetRandomSeed/BETR=1 randomSeed

	if(WP[49][epoch][type])
		// the stored seed value is the seed value for the *generation*
		// of the individual seed values for each step
		// Procedure:
		// - Initialize RNG with stored seed
		// - Query as many random numbers as current step count
		// - Use the *last* random number as seed value for the new epoch
		// In this way we get a different seed value for each step, but all are reproducibly
		// derived from one seed value. And we still have different values for different epochs.
		for(j = 1; j <= stepCount; j += 1)
			randomSeed = GetReproducibleRandom(noiseGenMode = noiseGenMode)
		endfor

		SetRandomSeed/BETR=1 randomSeed
	endif

	return randomSeed
End

/// @name Functions that build wave types
///@{
static Function WB_SquareSegment(STRUCT SegmentParameters &pa)

	WAVE SegmentWave = GetSegmentWave(duration = pa.duration)
	MultiThread SegmentWave = pa.amplitude
End

static Function WB_RampSegment(STRUCT SegmentParameters &pa)

	variable amplitudeIncrement = pa.amplitude * WAVEBUILDER_MIN_SAMPINT / pa.duration

	WAVE SegmentWave = GetSegmentWave(duration = pa.duration)
	MultiThread SegmentWave = amplitudeIncrement * p
End

/// @brief Check if the given frequency is a valid setting for the noise epoch
Function WB_IsValidCutoffFrequency(variable freq)

	return WB_IsValidScaledCutoffFrequency(freq / WAVEBUILDER_MIN_SAMPINT_HZ)
End

/// @brief Check if the given frequency is a valid setting for the noise epoch
///
/// Requires a scaled frequency as input, see `DisplayHelpTopic "FilterIIR"`
Function WB_IsValidScaledCutoffFrequency(variable freq)

	return freq > 0 && freq <= 0.5
End

static Function WB_NoiseSegment(STRUCT SegmentParameters &pa)

	variable samples, filterOrder
	variable lowPassCutoffScaled, highPassCutoffScaled
	variable referenceTime = DEBUG_TIMER_START()

	ASSERT(IsInteger(pa.buildResolution) && pa.buildResolution > 0, "Invalid build resolution")

	// duration is in ms
	samples = pa.duration * pa.buildResolution * WAVEBUILDER_MIN_SAMPINT_HZ * MILLI_TO_ONE

	// even number of points for IFFT
	samples = 2 * ceil(samples / 2)

	Make/FREE/D/C/N=(samples / 2 + 1) magphase
	FastOp magphase = 0
	SetScale/P x, 0, WAVEBUILDER_MIN_SAMPINT_HZ / samples, "Hz", magphase

	// we can't use Multithread here as this creates non-reproducible data
	switch(pa.noiseType)
		case NOISE_TYPE_WHITE:
			magphase[1, Inf] = cmplx(1, enoise(Pi, pa.noiseGenMode))
			break
		case NOISE_TYPE_PINK: // drops with 10db per decade
			magphase[1, Inf] = cmplx(1 / sqrt(x), enoise(Pi, pa.noiseGenMode))
			break
		case NOISE_TYPE_BROWN: // drops with 20db per decade
			magphase[1, Inf] = cmplx(1 / x, enoise(Pi, pa.noiseGenMode))
			break
		default:
			FATAL_ERROR("Invalid noise type")
			break
	endswitch

	WAVE SegmentWave = GetSegmentWave(duration = pa.duration)

#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForCaller())
		Duplicate/O magphase, noiseEpochMagnitude
		Redimension/R noiseEpochMagnitude
		Duplicate/O magphase, noiseEpochPhase
		Redimension/R noiseEpochPhase

		MultiThread noiseEpochPhase = imag(magphase[p]) * 180 / Pi
		MultiThread noiseEpochMagnitude = 20 * log(real(magphase[p]))
	endif
#endif // DEBUGGING_ENABLED

	MultiThread magphase = p2Rect(magphase)
	IFFT/R/DEST=SegmentWave magphase

	ASSERT(!cmpstr(WaveUnits(segmentWave, ROWS), "s"), "Unexpect wave unit")
	ASSERT(DimOffset(segmentWave, ROWS) == 0, "Unexpected wave rows offset")
	SetScale/P x, 0, DimDelta(segmentWave, ROWS) * ONE_TO_MILLI, "ms", segmentWave

	Redimension/N=(DimSize(segmentWave, ROWS) / pa.buildResolution) segmentWave

	lowPassCutoffScaled  = pa.lowpasscutoff / WAVEBUILDER_MIN_SAMPINT_HZ
	highPassCutoffScaled = pa.highpasscutoff / WAVEBUILDER_MIN_SAMPINT_HZ

	if(WB_IsValidScaledCutoffFrequency(lowPassCutoffScaled) && WB_IsValidScaledCutoffFrequency(highPassCutoffScaled))
		FilterIIR/CASC/LO=(lowPassCutoffScaled)/HI=(highPassCutoffScaled)/ORD=(pa.filterOrder) segmentWave
	elseif(WB_IsValidScaledCutoffFrequency(lowPassCutoffScaled))
		FilterIIR/CASC/LO=(lowPassCutoffScaled)/ORD=(pa.filterOrder) segmentWave
	elseif(WB_IsValidScaledCutoffFrequency(highPassCutoffScaled))
		FilterIIR/CASC/HI=(highPassCutoffScaled)/ORD=(pa.filterOrder) segmentWave
	else
		// do nothing
	endif

	MatrixOp/FREE scaleFactor = pa.amplitude / (maxVal(segmentWave) - minVal(segmentWave))
	MultiThread segmentWave[] = segmentWave[p] * scaleFactor[0] // ScaleFactor is a 1x1 matrix

	DEBUGPRINT_ELAPSED(referenceTime)
End

static Function [variable lowerBound, variable upperBound] WB_TrigGetBoundsForInflectionPoints(STRUCT SegmentParameters &pa, variable offset)

	variable d, f, fs, fe, phi, phii

	if(pa.logChirp)
		d  = pa.duration
		fs = pa.frequency / 1000    // NOLINT
		fe = pa.endFrequency / 1000 // NOLINT

		phi  = fs / ln(fe / fs)
		phii = fe / ln(fe / fs)

		lowerBound = 2 * trunc(d * phi) - offset
		upperBound = 2 * d * phii - 2 * mod(d * phi, 1) - offset

		ASSERT(IsFinite(lowerBound), "lowerBound must be finite")
		ASSERT(IsFinite(upperBound), "upperBound must be finite")

		// we don't require that lowerBound < upperBound, because for the cosine case
		// we can actually have no solutions at all
	else
		d = pa.duration
		f = pa.frequency / 1000 // NOLINT

		lowerBound = 0 - offset
		upperBound = 2 * d * f - offset
	endif

	lowerBound = ceil(lowerBound)
	upperBound = floor(upperBound)

	return [lowerBound, upperBound]
End

static Function WB_CheckTrigonometricSegmentParameters(STRUCT SegmentParameters &pa)

	if(pa.amplitude == 0)
		print "Can't calculate inflection points with amplitude zero"
		ControlWindowToFront()
		return 1
	elseif(pa.frequency <= 0)
		print "Can't calculate inflection points with frequency zero"
		ControlWindowToFront()
		return 1
	elseif(pa.logChirp && pa.frequency == pa.endFrequency)
		print "Can't calculate inflection points with both frequencies being equal"
		ControlWindowToFront()
		return 1
	elseif(pa.endfrequency <= 0 && pa.logChirp)
		print "Can't calculate inflection points with end frequency zero"
		ControlWindowToFront()
		return 1
	endif

	return 0
End

/// @brief Calculate the x values where the trigonometric epoch has inflection points
///
/// For zero offset, the inflection points coincide with the zero crossings/roots.
/// In case nothing can be calculated the inflectionPoints wave has one NaN entry.
///
/// \rst
///
/// The formula without chirp can be solved for :math:`f(x) == 0` as:
///
/// .. math::
///
///    f(x)        &= a \cdot \sin(k_0 \cdot x) \\
///    k_0 \cdot x &= c \cdot \pi               \\
///    x           &= \frac{c \cdot \pi}{k_0}
///
/// And for cosine:
///
/// .. math::
///
///    x = \frac{(c + \frac{1}{2}) \cdot \pi}{k_0}
///
/// With chirp and sine:
///
/// .. math::
///
///    f(x)                            &= a \cdot \sin(k_2 \cdot e^{k_1 \cdot x}- k_3)                      \\
///    k_2 \cdot e^{k_1 \cdot x} - k_3 &= c \cdot \pi                                                       \\
///    e^{k_1 \cdot x}                 &= \frac{c \cdot \pi + k_3}{k_2}                                     \\
///    k_1 \cdot x                     &= \ln\left(\frac{c \cdot \pi + k_3}{k_2}\right)                     \\
///    x                               &= \frac{1}{k_1} \cdot \ln\left(\frac{c \cdot \pi + k_3}{k_2}\right)
///
/// And analogous for cosine:
///
/// .. math::
///
///    x = \frac{1}{k_1} \cdot \ln\left(\frac{(c + \frac{1}{2}) \cdot \pi + k_3}{k_2}\right)
///
/// \endrst
static Function [WAVE/D inflectionPoints, WAVE/D inflectionIndices] WB_TrigCalculateInflectionPoints(STRUCT SegmentParameters &pa, variable k0, variable k1, variable k2, variable k3)

	variable i, idx, xzero, offset, lowerBound, upperBound

	if(WB_CheckTrigonometricSegmentParameters(pa))
		Make/FREE/D inflectionPoints = {NaN}, inflectionIndices = {NaN}
		return [inflectionPoints, inflectionIndices]
	endif

	switch(pa.trigFuncType)
		case WB_TRIG_TYPE_SIN:
			offset = 0
			break
		case WB_TRIG_TYPE_COS:
			offset = 1 / 2
			break
		default:
			FATAL_ERROR("Unknown trigFuncType")
	endswitch

	[lowerBound, upperBound] = WB_TrigGetBoundsForInflectionPoints(pa, offset)

	Make/FREE/D/N=(MINIMUM_WAVE_SIZE) inflectionPoints, inflectionIndices

	for(i = lowerBound; i <= upperBound; i += 1)
		if(pa.logChirp)
			xzero = 1 / k1 * ln(((i + offset) * pi + k3) / k2)
		else
			xzero = (i + offset) * pi / k0
		endif

		ASSERT(IsFinite(xzero), "xzero must be finite")
		ASSERT(xzero >= 0, "xzero must >= 0")
		ASSERT(xzero < pa.duration || CheckIfClose(xzero, pa.duration), "xzero must <= pa.duration")

		EnsureLargeEnoughWave(inflectionPoints, indexShouldExist = idx, dimension = ROWS, initialValue = NaN)
		EnsureLargeEnoughWave(inflectionIndices, indexShouldExist = idx, dimension = ROWS, initialValue = NaN)
		inflectionPoints[idx]  = xzero
		inflectionIndices[idx] = trunc(xzero / WAVEBUILDER_MIN_SAMPINT)
		idx                   += 1
	endfor

	Redimension/N=(idx) inflectionPoints, inflectionIndices

	return [inflectionPoints, inflectionIndices]
End

static Function [WAVE/D inflectionPoints, WAVE/D inflectionIndices] WB_TrigSegment(STRUCT SegmentParameters &pa)

	variable k0, k1, k2, k3

	if(pa.trigFuncType != WB_TRIG_TYPE_SIN && pa.trigFuncType != WB_TRIG_TYPE_COS)
		printf "Ignoring unknown trigonometric function"
		WAVE SegmentWave = GetSegmentWave(duration = 0)
		Make/FREE/D inflectionPoints = {NaN}, inflectionIndices = {NaN}
		return [inflectionPoints, inflectionIndices]
	endif

	WAVE SegmentWave = GetSegmentWave(duration = pa.duration)

	if(pa.logChirp)
		k0 = ln(pa.frequency / 1000)                           // NOLINT
		k1 = (ln(pa.endFrequency / 1000) - k0) / (pa.duration) // NOLINT
		k2 = 2 * pi * e^k0 / k1
		k3 = mod(k2, 2 * pi)                                   // LH040117: start on rising edge of sin and don't try to round.
		if(pa.trigFuncType == WB_TRIG_TYPE_SIN)
			MultiThread SegmentWave = pa.amplitude * sin(k2 * e^(k1 * x) - k3)
		else
			MultiThread SegmentWave = pa.amplitude * cos(k2 * e^(k1 * x) - k3)
		endif

		[WAVE inflectionPoints, WAVE inflectionIndices] = WB_TrigCalculateInflectionPoints(pa, k0, k1, k2, k3)
	else
		k0 = 2 * Pi * (pa.frequency / 1000) // NOLINT
		k1 = NaN
		k2 = NaN
		k3 = NaN

		if(pa.trigFuncType == WB_TRIG_TYPE_SIN)
			MultiThread SegmentWave = pa.amplitude * sin(k0 * x)
		else
			MultiThread SegmentWave = pa.amplitude * cos(k0 * x)
		endif

		[WAVE inflectionPoints, WAVE inflectionIndices] = WB_TrigCalculateInflectionPoints(pa, k0, k1, k2, k3)
	endif

	return [inflectionPoints, inflectionIndices]
End

static Function WB_SawToothSegment(STRUCT SegmentParameters &pa)

	WAVE SegmentWave = GetSegmentWave(duration = pa.duration)

	MultiThread SegmentWave = pa.amplitude * sawtooth(2 * Pi * (pa.frequency * 1000) * (5 / 1000000000) * p) // NOLINT
End

static Function WB_CreatePulse(WAVE wv, variable pulseType, variable amplitude, variable first, variable last)

	if(pulseType == WB_PULSE_TRAIN_TYPE_SQUARE)
		wv[first, last] = amplitude
	elseif(pulseType == WB_PULSE_TRAIN_TYPE_TRIANGLE)
		ASSERT(last > first, "last must be > first")
		wv[first, last] = amplitude * (p - first) / (last - first)
	else
		FATAL_ERROR("unknown pulse type")
	endif
End

/// @brief Convert the numeric epoch type to a stringified version
Function/S WB_ToEpochTypeString(variable epochType)

	switch(epochType)
		case EPOCH_TYPE_SQUARE_PULSE:
			return "Square pulse"
		case EPOCH_TYPE_RAMP:
			return "Ramp"
		case EPOCH_TYPE_NOISE:
			return "Noise"
		case EPOCH_TYPE_SIN_COS:
			return "Sin Wave"
		case EPOCH_TYPE_SAW_TOOTH:
			return "Saw tooth"
		case EPOCH_TYPE_PULSE_TRAIN:
			return "Pulse Train"
		case EPOCH_TYPE_PSC:
			return "PSC"
		case EPOCH_TYPE_CUSTOM:
			return "Custom Wave"
		case EPOCH_TYPE_COMBINE:
			return "Combine"
		default:
			FATAL_ERROR("Unknown epoch: " + num2str(epochType))
			return ""
	endswitch
End

/// @brief Convert the stringified epoch type to a numerical one
Function WB_ToEpochType(string epochTypeStr)

	strswitch(epochTypeStr)
		case "Square pulse":
			return EPOCH_TYPE_SQUARE_PULSE
		case "Ramp":
			return EPOCH_TYPE_RAMP
		case "Noise":
			return EPOCH_TYPE_NOISE
		case "Sin Wave":
			return EPOCH_TYPE_SIN_COS
		case "Saw tooth":
			return EPOCH_TYPE_SAW_TOOTH
		case "Pulse Train":
			return EPOCH_TYPE_PULSE_TRAIN
		case "PSC":
			return EPOCH_TYPE_PSC
		case "Custom Wave":
			return EPOCH_TYPE_CUSTOM
		case "Combine":
			return EPOCH_TYPE_COMBINE
		default:
			FATAL_ERROR("Unknown epoch: " + epochTypeStr)
			return NaN
	endswitch
End

/// @brief Query stimset wave note entries
///
/// \rst
/// Format of the wave note:
///
/// The wave note version is tracked through STIMSET_NOTE_VERSION
///
/// Lines separated by ``\r`` (carriage return) in UTF-8 encoding.
/// The lines hold Igor Pro style key value pairs in the form ``key = value;``
/// where value can contain any character except ``;`` (semicolon).
///
/// Four types of entries can be distinguished:
///
/// - Version: In the very first line (line 1)
/// - Sweep specific entries have an epoch of ``nan``: (line 2, 7)
/// - Epoch specific: (line 3 - 6)
/// - Stimset specific: (line 12)
///
/// Additional infos on selected entries:
/// - `ITI` is in seconds
/// - `Flipping` is done on a per stimset basis
/// - `Durations` are in `stimset build ms`
/// - `Pulse Train Pulses` are absolute pulse starting times in `epoch build ms`
/// - `Pulse To Pulse Length` is in `stimset build ms`
/// - `Function params (encoded)` contains the analysis function parameters. The values have the format described at GetWaveBuilderWaveTextParam().
/// - `Inflection Points` are in `epoch build ms`. For offset zero these coincide with the roots.
///
/// Added with version 10:
///    - start and end indices for pulses in pulse trains (end index is part of the pulse)
///    - length of each segment
///    - inflection point positions (left side index)
///
/// Example:
///
/// .. code-block:: none
/// 	:linenos:
///
/// 	Version = 2;
/// 	Sweep = 0;Epoch = nan;ITI = 1;
/// 	Sweep = 0;Epoch = 0;Type = Square pulse;Duration = 500;Amplitude = 0;
/// 	Sweep = 0;Epoch = 1;Type = Ramp;Duration = 150;Amplitude = 1;Offset = 0;
/// 	Sweep = 0;Epoch = 2;Type = Square pulse;Duration = 300;Amplitude = 0;
/// 	Sweep = 0;Epoch = 3;Type = Pulse Train;Duration = 960.005;Amplitude = 1;Offset = 0;Pulse Type = Square;Frequency = 20;Pulse To Pulse Length = 50;Pulse duration = 10;Number of pulses = 20;Mixed frequency = False;First mixed frequency = 0;Last mixed frequency = 0;Poisson distribution = False;Random seed = 0.963638;Pulse Train Pulses = 0,50,100,150,200,250,300,350,400,450,500,550,600,650,700,750,800,850,900,950,;Definition mode = Duration;
/// 	Sweep = 1;Epoch = nan;ITI = 2;
/// 	Sweep = 1;Epoch = 0;Type = Square pulse;Duration = 500;Amplitude = 0;
/// 	Sweep = 1;Epoch = 1;Type = Ramp;Duration = 150;Amplitude = 1;Offset = 0;
/// 	Sweep = 1;Epoch = 2;Type = Square pulse;Duration = 300;Amplitude = 0;
/// 	Sweep = 1;Epoch = 3;Type = Pulse Train;Duration = 960.005;Amplitude = 1;Offset = 0;Pulse Type = Square;Frequency = 20;Pulse To Pulse Length = 50;Pulse duration = 10;Number of pulses = 20;Mixed frequency = False;First mixed frequency = 0;Last mixed frequency = 0;Poisson distribution = False;Random seed = 0.963638;Pulse Train Pulses = 0,50,100,150,200,250,300,350,400,450,500,550,600,650,700,750,800,850,900,950,;Definition mode = Duration;
/// 	Stimset;Sweep Count = 2;Epoch Count = 4;Pre DAQ = ;Mid Sweep = ;Post Sweep = ;Post Set = ;Post DAQ = ;Pre Sweep = ;Generic = PSQ_Ramp;Pre Set = ;Function params (encoded)= NumberOfSpikes:variable=5,Elements:string=%20%3B%2C;Flip = 0;Random Seed = 0.963638;Wavebuilder Error = 0;Checksum = 65446509;
/// \endrst
///
/// @param text      stimulus set wave note
/// @param entryType one of @ref StimsetWaveNoteEntryTypes
/// @param key       [optional] named entry to return, not required for #VERSION_ENTRY
/// @param sweep     [optional] number of the sweep
/// @param epoch     [optional] number of the epoch
Function/S WB_GetWaveNoteEntry(string text, variable entryType, [string key, variable sweep, variable epoch])

	string match, re

	if(!ParamIsDefault(sweep))
		ASSERT(IsValidSweepNumber(sweep), "Invalid sweep number")
	endif

	if(!ParamIsDefault(epoch))
		ASSERT(IsValidEpochNumber(epoch), "Invalid epoch number")
	endif

	switch(entryType)
		case VERSION_ENTRY:
			ASSERT(ParamIsDefault(key), "Unexpected key")
			key = "Version"
			sprintf re, "^%s.*;$", key
			break
		case SWEEP_ENTRY:
			ASSERT(!ParamIsDefault(key) && !IsEmpty(key), "Missing key")
			sprintf re, "^Sweep = %d;Epoch = nan;", sweep
			break
		case EPOCH_ENTRY:
			ASSERT(!ParamIsDefault(key) && !IsEmpty(key), "Missing key")
			sprintf re, "^Sweep = %d;Epoch = %d;", sweep, epoch
			break
		case STIMSET_ENTRY:
			ASSERT(!ParamIsDefault(key) && !IsEmpty(key), "Missing key")
			re = "^Stimset;"
			break
		default:
			FATAL_ERROR("Unknown entryType")
	endswitch

	match = GrepList(text, re, 0, "\r")

	if(IsEmpty(match))
		return match
	endif

	ASSERT(ItemsInList(match, "\r") == 1, "Expected only one matching line")

	return ExtractStringFromPair(match, key, keySep = "=")
End

// @copydoc WB_GetWaveNoteEntry
Function WB_GetWaveNoteEntryAsNumber(string text, variable entryType, [string key, variable sweep, variable epoch])

	string str

	if(ParamIsDefault(key) && ParamIsDefault(sweep) && ParamIsDefault(epoch))
		str = WB_GetWaveNoteEntry(text, entryType)
	elseif(ParamIsDefault(sweep) && ParamIsDefault(epoch))
		str = WB_GetWaveNoteEntry(text, entryType, key = key)
	elseif(ParamIsDefault(key) && ParamIsDefault(epoch))
		str = WB_GetWaveNoteEntry(text, entryType, sweep = sweep)
	elseif(ParamIsDefault(key) && ParamIsDefault(sweep))
		str = WB_GetWaveNoteEntry(text, entryType, epoch = epoch)
	elseif(ParamIsDefault(key))
		str = WB_GetWaveNoteEntry(text, entryType, sweep = sweep, epoch = epoch)
	elseif(ParamIsDefault(sweep))
		str = WB_GetWaveNoteEntry(text, entryType, key = key, epoch = epoch)
	elseif(ParamIsDefault(epoch))
		str = WB_GetWaveNoteEntry(text, entryType, sweep = sweep, key = key)
	else
		str = WB_GetWaveNoteEntry(text, entryType, key = key, sweep = sweep, epoch = epoch)
	endif

	if(IsEmpty(str))
		return NaN
	endif

	return str2num(str)
End

static Function [WAVE/D pulseStartTimes, WAVE/D pulseStartIndices, WAVE/D pulseEndIndices, variable pulseToPulseLength] WB_PulseTrainSegment(STRUCT SegmentParameters &pa, variable mode)

	variable startIndex, endIndex, startOffset, durationError, lastValidStartIndex
	variable pulseStartTime, i, amplitudeStartIndex
	variable numRows, interPulseInterval, idx, firstStep, lastStep, dist
	string str

	pulseToPulseLength = NaN

	ASSERT((pa.poisson + pa.mixedFreq) <= 1, "Only one of Mixed Frequency or poisson can be checked")

	if(!(pa.pulseDuration > 0))
		printf "Resetting invalid pulse duration of %gms to 1ms\r", pa.pulseDuration
		pa.pulseDuration = 1.0
	endif

	if(!pa.mixedFreq)
		if(!(pa.frequency > 0))
			printf "Resetting invalid frequency of %gHz to 1Hz\r", pa.frequency
			pa.frequency = 1.0
		endif

		if(mode == PULSE_TRAIN_MODE_PULSE)
			// user defined number of pulses
			pa.duration = pa.numberOfPulses / pa.frequency * ONE_TO_MILLI
		elseif(mode == PULSE_TRAIN_MODE_DUR)
			// user defined duration
			pa.numberOfPulses = pa.frequency * pa.duration * MILLI_TO_ONE
		else
			FATAL_ERROR("Invalid mode")
		endif

		if(!(pa.duration > 0))
			printf "Resetting invalid duration of %gms to 1ms\r", pa.duration
			pa.duration = 1.0
		endif
	endif

	Make/FREE/D/N=(MINIMUM_WAVE_SIZE) pulseStartTimes, pulseStartIndices, pulseEndIndices

	if(pa.poisson)
		interPulseInterval = (1 / pa.frequency) * ONE_TO_MILLI - pa.pulseDuration

		WAVE segmentWave = GetSegmentWave(duration = pa.duration)
		FastOp segmentWave = 0
		numRows = DimSize(segmentWave, ROWS)

		pulseToPulseLength = 0

		for(;;)
			pulseStartTime                                    += -ln(abs(enoise(1, pa.noiseGenMode))) / pa.frequency * ONE_TO_MILLI
			[startIndex, endIndex, startOffset, durationError] = WB_GetIndicesForSignalDuration(pulseStartTime, pa.pulseDuration, WAVEBUILDER_MIN_SAMPINT)
			if(endIndex >= numRows || endIndex < 0)
				break
			endif

			lastValidStartIndex = startIndex
			WB_CreatePulse(segmentWave, pa.pulseType, pa.amplitude, startIndex, endIndex)

			EnsureLargeEnoughWave(pulseStartTimes, indexShouldExist = idx)
			EnsureLargeEnoughWave(pulseStartIndices, indexShouldExist = idx)
			EnsureLargeEnoughWave(pulseEndIndices, indexShouldExist = idx)
			pulseStartTimes[idx]   = pulseStartTime
			pulseStartIndices[idx] = startIndex
			pulseEndIndices[idx]   = endIndex
			idx                   += 1
		endfor
	elseif(pa.mixedFreq)

		firstStep = 1 / pa.firstFreq
		lastStep  = 1 / pa.lastFreq
		dist      = (lastStep / firstStep)^(1 / (pa.numberOfPulses - 1))
		Make/D/FREE/N=(pa.numberOfPulses) interPulseIntervals = firstStep * dist^p * ONE_TO_MILLI - pa.pulseDuration

		if(pa.mixedFreqShuffle)
			InPlaceRandomShuffle(interPulseIntervals, noiseGenMode = pa.noiseGenModePTMixedFreq)
		endif

		pulseToPulseLength = 0

		pa.duration = (sum(interPulseIntervals) + pa.numberOfPulses * pa.pulseDuration)
		WAVE segmentWave = GetSegmentWave(duration = pa.duration)
		FastOp segmentWave = 0
		numRows = DimSize(segmentWave, ROWS)

		for(i = 0; i < pa.numberOfPulses; i += 1)

			[startIndex, endIndex, startOffset, durationError] = WB_GetIndicesForSignalDuration(pulseStartTime, pa.pulseDuration, WAVEBUILDER_MIN_SAMPINT)
			if(endIndex >= numRows || endIndex < 0)
				break
			endif

			lastValidStartIndex = startIndex
			WB_CreatePulse(segmentWave, pa.pulseType, pa.amplitude, startIndex, endIndex)

			EnsureLargeEnoughWave(pulseStartTimes, indexShouldExist = idx)
			EnsureLargeEnoughWave(pulseStartIndices, indexShouldExist = idx)
			EnsureLargeEnoughWave(pulseEndIndices, indexShouldExist = idx)
			pulseStartTimes[idx]   = pulseStartTime
			pulseStartIndices[idx] = startIndex
			pulseEndIndices[idx]   = endIndex
			idx                   += 1

			pulseStartTime += interPulseIntervals[i] + pa.pulseDuration
		endfor
	else
		interPulseInterval = (1 / pa.frequency) * ONE_TO_MILLI - pa.pulseDuration

		WAVE segmentWave = GetSegmentWave(duration = pa.duration)
		FastOp segmentWave = 0
		numRows = DimSize(segmentWave, ROWS)

		pulseToPulseLength = interPulseInterval + pa.pulseDuration

		for(;;)

			[startIndex, endIndex, startOffset, durationError] = WB_GetIndicesForSignalDuration(pulseStartTime, pa.pulseDuration, WAVEBUILDER_MIN_SAMPINT)
			if(endIndex >= numRows || endIndex < 0)
				break
			endif

			lastValidStartIndex = startIndex
			WB_CreatePulse(segmentWave, pa.pulseType, pa.amplitude, startIndex, endIndex)

			EnsureLargeEnoughWave(pulseStartTimes, indexShouldExist = idx)
			EnsureLargeEnoughWave(pulseStartIndices, indexShouldExist = idx)
			EnsureLargeEnoughWave(pulseEndIndices, indexShouldExist = idx)
			pulseStartTimes[idx]   = pulseStartTime
			pulseStartIndices[idx] = startIndex
			pulseEndIndices[idx]   = endIndex
			idx                   += 1

			pulseStartTime += interPulseInterval + pa.pulseDuration
		endfor
	endif

	Redimension/N=(idx) pulseStartTimes, pulseStartIndices, pulseEndIndices

	// remove the zero part at the end
	amplitudeStartIndex = (pa.pulseType == WB_PULSE_TRAIN_TYPE_SQUARE) ? lastValidStartIndex : (lastValidStartIndex + 1)
	if(amplitudeStartIndex < DimSize(segmentWave, ROWS))
		FindValue/V=(0)/S=(amplitudeStartIndex) segmentWave
		if(V_Value != -1)
			DEBUGPRINT("Removal of points:", var = (DimSize(segmentWave, ROWS) - V_Value))
			Redimension/N=(V_Value) segmentWave
			pa.duration = V_Value * WAVEBUILDER_MIN_SAMPINT
		else
			DEBUGPRINT("No removal of points")
		endif
	else
		DEBUGPRINT("No removal of points")
	endif

	sprintf str, "interPulseInterval=%g ms, numberOfPulses=%g [a.u.], pulseDuration=%g [ms], real duration=%.6f [a.u.]\r", \
	        interPulseInterval, pa.numberOfPulses, pa.pulseDuration, DimSize(segmentWave, ROWS) * WAVEBUILDER_MIN_SAMPINT

	DEBUGPRINT(str)

	return [pulseStartTimes, pulseStartIndices, pulseEndIndices, pulseToPulseLength]
End

static Function WB_PSCSegment(STRUCT SegmentParameters &pa)

	variable baseline, peak

	WAVE SegmentWave = GetSegmentWave(duration = pa.duration)

	pa.TauRise    = 1 / pa.TauRise
	pa.TauRise   *= WAVEBUILDER_MIN_SAMPINT
	pa.TauDecay1  = 1 / pa.TauDecay1
	pa.TauDecay1 *= WAVEBUILDER_MIN_SAMPINT
	pa.TauDecay2  = 1 / pa.TauDecay2
	pa.TauDecay2 *= WAVEBUILDER_MIN_SAMPINT

	MultiThread SegmentWave[] = pa.amplitude * ((1 - exp(-pa.TauRise * p)) + exp(-pa.TauDecay1 * p) * (1 - pa.TauDecay2Weight) + exp(-pa.TauDecay2 * p) * pa.TauDecay2Weight)

	[baseline, peak] = WaveMinAndMax(SegmentWave)
	MultiThread SegmentWave *= abs(pa.amplitude) / (peak - baseline)

	baseline = WaveMin(SegmentWave)
	MultiThread SegmentWave -= baseline
End

static Function WB_CustomWaveSegment(STRUCT SegmentParameters &pa, WAVE customWave)

	pa.duration = DimSize(customWave, ROWS) * WAVEBUILDER_MIN_SAMPINT
	WAVE segmentWave = GetSegmentWave(duration = pa.duration)
	MultiThread segmentWave[] = customWave[p]
End

/// @brief Create a wave segment as combination of existing stim sets
static Function/WAVE WB_FillWaveFromFormula(string formula, variable channelType, variable sweep)

	STRUCT FormulaProperties fp
	string                   shorthandFormula

	shorthandFormula = WB_FormulaSwitchToShorthand(channelType, formula)

	if(WB_ParseCombinerFormula(channelType, shorthandFormula, sweep, fp))
		return $""
	endif

	DEBUGPRINT("Formula:", str = fp.formula)

	DFREF dfr       = GetDataFolderDFR()
	DFREF targetDFR = GetSetFolder(channelType)

	SetDataFolder targetDFR
	Make/O/D/N=(fp.numRows) d
	Execute/Q/Z fp.formula

	if(V_Flag)
		printf "WB_FillWaveFromFormula: Error executing the formula \"%s\"\r", formula
		KillOrMoveToTrash(wv = d)
		SetDataFolder dfr
		return $""
	endif

	SetDataFolder dfr

	return MakeWaveFree(d)
End
///@}

/// @brief Update the shorthand/stimset wave for the epoch type `Combine`
///
/// The rows are sorted by creationDate of the WP/stimset wave to try to keep
/// the shorthands constants even when new stimsets are added.
Function WB_UpdateEpochCombineList(WAVE/T epochCombineList, variable channelType)

	string list, setPath, setParamPath, entry
	variable numEntries, i

	list = ST_GetStimsetList(channelType = channelType)
	list = RemoveFromList(STIMSET_TP_WHILE_DAQ, list)

	numEntries = ItemsInList(list)

	if(!numEntries)
		return NaN
	endif

	Make/D/FREE/N=(numEntries) creationDates
	WAVE/T stimsets = ListToTextWave(list, ";")

	DFREF dfr = GetSetFolder(channelType)

	for(i = 0; i < numEntries; i += 1)
		entry = StringFromList(i, list)
		WAVE/Z/SDFR=dfr stimset = $entry
		WAVE/Z          WP      = WB_GetWaveParamForSet(entry)

		if(WaveExists(WP))
			creationDates[i] = CreationDate(WP)
		elseif(WaveExists(stimset))
			creationDates[i] = CreationDate(stimset)
		else
			FATAL_ERROR("Missing stimset/param wave")
		endif
	endfor

	Sort creationDates, stimsets

	Redimension/N=(numEntries, -1) epochCombineList

	epochCombineList[][%StimSet]   = stimsets[p]
	epochCombineList[][%Shorthand] = WB_GenerateUniqueLabel(p)
End

/// @brief Generate a unique textual representation of an index
///
/// Returns the alphabet for 1-26, and then A1, B1, ..., Z1000
static Function/S WB_GenerateUniqueLabel(variable idx)

	variable number, charNum
	string str

	charNum = mod(idx, 26)
	number  = floor(idx / 26)

	if(!number)
		return num2char(65 + charNum)
	endif

	sprintf str, "%s%d", num2char(65 + charNum), number
	return str
End

/// @brief Parse the formula from the epoch type `Combine`
///
/// @param[in]  channelType One of CHANNEL_TYPE_DA or CHANNEL_TYPE_TTL
/// @param[in]  formula     math formula to execute, all operators which Igor can grok are allowed
/// @param[in]  sweep       current sweep (aka step)
/// @param[out] fp          parsed formula structure, with shorthands replaced by stimsets,
///                         empty on parse error, ready to be executed by WB_FillWaveFromFormula()
///
/// @returns 0 on success, 1 on parse errors (currently not many are found)
Function WB_ParseCombinerFormula(variable channelType, string formula, variable sweep, STRUCT FormulaProperties &fp)

	string dependentStimsets
	variable i, numStimsets
	STRUCT FormulaProperties trans
	variable numRows = Inf
	variable numCols = Inf

	InitFormulaProperties(fp)
	InitFormulaProperties(trans)
	WB_FormulaSwitchToStimset(channelType, formula, trans)

	// look for shorthand-like strings not referring to existing stimsets
	if(GrepString(trans.formula, "\\b[A-Z][0-9]*\\b"))
		printf "WBP_ParseCombinerFormula: Parse error in the formula \"%s\": Non-existing shorthand found\r", formula
		ControlWindowToFront()
		return 1
	endif

	// Do not allow questionmarks as part of the formula
	if(CountSubstrings(formula, "?") > 0)
		printf "WBP_ParseCombinerFormula: Quenstionmark char not allowed in formula.\r"
		ControlWindowToFront()
		return 1
	endif

	numStimsets = ItemsInList(trans.stimsetList)
	for(i = 0; i < numStimsets; i += 1)
		WAVE/Z wv = WB_CreateAndGetStimSet(StringFromList(i, trans.stimsetList))
		ASSERT(WaveExists(wv), "all stimsets of current formula should have been created previously by WB_GetStimset()")
		numRows = min(numRows, DimSize(wv, ROWS))
		numCols = min(numCols, DimSize(wv, COLS))
	endfor
	trans.numRows = numRows
	trans.numCols = numCols

	if(sweep >= trans.numCols)
		printf "WBP_ParseCombinerFormula: Requested step %d is larger than the minimum number of sweeps in the referenced stim sets\r", sweep
		ControlWindowToFront()
		return 1
	endif

	WB_PrepareFormulaForExecute(trans, sweep)

	if(strlen(trans.formula) >= MAX_COMMANDLINE_LENGTH)
		printf "WBP_ParseCombinerFormula: Parsed formula is too long to be executed in one step. Please shorten it and perform the desired task in two steps.\r"
		ControlWindowToFront()
		return 1
	endif

	fp = trans

	return 0
End

/// @brief Replace shorthands with the real stimset names suffixed with `?`
Function WB_FormulaSwitchToStimset(variable channelType, string formula, STRUCT FormulaProperties &fp)

	string stimset, shorthand, stimsetSpec, prefix, suffix
	variable numSets, i, stimsetFound

	InitFormulaProperties(fp)

	if(isEmpty(formula))
		return NaN
	endif

	WAVE/T epochCombineList = GetWBEpochCombineList(channeltype)

	formula = UpperStr(formula)

	// we replace, case sensitive!, all upper case shorthands with lower case
	// stimsets in that way we don't mess up the formula
	// iterate the stimset list from bottom to top, so that we replace first the shorthands
	// with numeric prefix and only later on the ones without
	numSets = DimSize(epochCombineList, ROWS)
	for(i = numSets - 1; i >= 0 && numSets > 0; i -= 1)
		shorthand    = epochCombineList[i][%Shorthand]
		stimset      = epochCombineList[i][%stimset]
		stimsetSpec  = LowerStr(stimset) + "?"
		stimsetFound = 0

		// search and replace until shorthand isn't found in formula anymore.
		ASSERT(!SearchWordInString(stimsetSpec, shorthand), "circular reference: shorthand is part of stimset. prevented infinite loop")
		do
			if(!SearchWordInString(formula, shorthand, prefix = prefix, suffix = suffix))
				break
			endif
			formula      = prefix + stimsetSpec + suffix
			stimsetFound = 1
		while(1)

		// save current stimset in a list
		if(stimsetFound)
			fp.stimsetList = AddListItem(stimset, fp.stimsetList)
		endif
	endfor

	if(ItemsInList(fp.stimsetList) == 0)
		printf "no stimset present in formula.\r"
	endif

	fp.formula = formula
End

/// @brief Add wave ranges to every stimset (location marked by `?`) and
///        add a left hand side to the formula
static Function WB_PrepareFormulaForExecute(STRUCT FormulaProperties &fp, variable sweep)

	string spec
	sprintf spec, "[p][%d]", sweep

	fp.formula = "d[]=" + ReplaceString("?", fp.formula, spec)
End

/// @brief Replace all stimsets suffixed with `?` by their shorthands
Function/S WB_FormulaSwitchToShorthand(variable channelType, string formula)

	variable numSets, i
	string stimset, shorthand, regex

	if(isEmpty(formula))
		return ""
	endif

	WAVE/T epochCombineList = GetWBEpochCombineList(channelType)

	numSets = DimSize(epochCombineList, ROWS)
	for(i = 0; i < numSets; i += 1)
		shorthand = epochCombineList[i][%Shorthand]
		stimset   = epochCombineList[i][%stimset]

		regex   = "\\b\\Q" + LowerStr(stimset) + "\\E\\b\?"
		formula = ReplaceRegexInString(regex, formula, shorthand)
	endfor

	return formula
End

/// @brief Get all custom waves that are used by the supplied stimset.
///
/// used by WaveBuilder and NeuroDataWithoutBorders
///
/// @returns a wave of wave references
Function/WAVE WB_CustomWavesFromStimSet(string stimsetList)

	variable i, j, numStimsets

	WB_UpgradeCustomWaves(stimsetList)
	WAVE/T cw = WB_CustomWavesPathFromStimSet(stimsetList)

	numStimSets = Dimsize(cw, ROWS)
	Make/FREE/WAVE/N=(numStimSets) wv

	for(i = 0; i < numStimSets; i += 1)
		WAVE/Z customwave = $cw[i]
		if(WaveExists(customwave))
			wv[j] = customwave
			j    += 1
		else
			printf "Reference in stimsets \"%s\" to custom wave \"%s\" failed.\r", stimsetList, cw[i]
		endif
		WaveClear customwave
	endfor
	Redimension/N=(j) wv

	return wv
End

/// @brief Get all custom waves that are used by the supplied stimset.
///
/// @returns a text wave with paths to custom waves.
Function/WAVE WB_CustomWavesPathFromStimSet(string stimsetList)

	variable numStimSets, i, j, k, numEpochs
	string stimset

	numStimsets = ItemsInList(stimsetList)

	Make/N=(numStimsets * WB_TOTAL_NUMBER_OF_EPOCHS)/FREE/T customWaves

	for(i = 0; i < numStimsets; i += 1)
		stimset = StringFromList(i, stimsetList)
		WAVE/Z/T WPT       = WB_GetWaveTextParamForSet(stimSet)
		WAVE/Z   SegWvType = WB_GetSegWvTypeForSet(stimSet)

		if(!WaveExists(WPT) || !WaveExists(SegWvType))
			continue
		endif

		numEpochs = SegWvType[%'Total number of epochs']
		for(j = 0; j < numEpochs; j += 1)
			if(SegWvType[j] == EPOCH_TYPE_CUSTOM)
				customwaves[k] = WPT[0][j][EPOCH_TYPE_CUSTOM]
				k             += 1
			endif
		endfor
	endfor

	Redimension/N=(k) customWaves
	return customWaves
End

/// @brief Try to upgrade all epochs with custom waves from the stimsetlist.
///
/// you can only use this function if the custom wave is present in the current experiment.
/// do not try to upgrade when loading stimsets. The custom waves have to be loaded first.
///
/// @returns a text wave with paths to custom waves.
static Function/WAVE WB_UpgradeCustomWaves(string stimsetList)

	variable channelType, numStimsets, numEpochs, i, j
	string stimset

	numStimsets = ItemsInList(stimsetList)

	for(i = 0; i < numStimsets; i += 1)
		stimset = StringFromList(i, stimsetList)
		WAVE/Z/T WPT       = WB_GetWaveTextParamForSet(stimSet)
		WAVE/Z   SegWvType = WB_GetSegWvTypeForSet(stimSet)
		channelType = WB_GetStimSetType(stimSet)

		if(!WaveExists(WPT) || !WaveExists(SegWvType))
			continue
		endif

		ASSERT(channelType != CHANNEL_TYPE_UNKNOWN, "Unexpected channel type")

		numEpochs = SegWvType[%'Total number of epochs']
		for(j = 0; j < numEpochs; j += 1)
			if(SegWvType[j] == EPOCH_TYPE_CUSTOM)
				WB_UpgradecustomWaveInWPT(WPT, channelType, j)
			endif
		endfor
	endfor
End

/// @brief Search for stimsets in formula epochs
///
/// a stimset (parent) can depend on other stimsets (child)
///
/// @return non-unique list of all (child) stimsets
static Function/S WB_StimsetChildren([string stimset])

	variable numEpochs, numStimsets, i, j
	string formula, regex, prefix, match, suffix
	string stimsets = ""

	if(ParamIsDefault(stimset))
		WAVE/Z   WP        = GetWaveBuilderWaveParam()
		WAVE/Z/T WPT       = GetWaveBuilderWaveTextParam()
		WAVE/Z   SegWvType = GetSegmentTypeWave()
	else
		if(!WB_ParameterWavesExist(stimset))
			// stimset without parameter waves has no dependencies
			return ""
		endif

		WAVE/Z   WP        = WB_GetWaveParamForSet(stimSet)
		WAVE/Z/T WPT       = WB_GetWaveTextParamForSet(stimSet)
		WAVE/Z   SegWvType = WB_GetSegWvTypeForSet(stimSet)
	endif

	ASSERT(WaveExists(WP) && WaveExists(WPT) && WaveExists(SegWvType), "Parameter Waves not found.")

	numEpochs = SegWvType[%'Total number of epochs']

	// search for stimsets in all formula-epochs by a regex pattern
	for(i = 0; i < numEpochs; i += 1)
		if(SegWvType[i] == EPOCH_TYPE_COMBINE)
			formula     = WPT[6][i][EPOCH_TYPE_COMBINE]
			numStimsets = CountSubstrings(formula, "?")
			for(j = 0; j < numStimsets; j += 1)
				WAVE/Z/T wv = SearchStringBase(formula, "(.*)\\b(\\w+)\\b\\?(.*)")
				ASSERT(WaveExists(wv), "Error in formula: could not properly resolve formula to stimset")
				formula  = wv[0] + wv[2]
				stimsets = AddListItem(wv[1], stimsets)
			endfor
		endif
	endfor

	return stimsets
End

/// @brief Get children of current parent stimset.
///
/// @param      parent		[optional: defaults to current WB panel] specify parent stimset.
/// @param[out] knownNames	unique list of stimsets
///
/// @return number of parents stimsets that were moved to child stimsets
Function WB_StimsetFamilyNames(string &knownNames, [string parent])

	string children, familynames
	variable numChildren, i, numMoved

	// look for family members
	if(ParamIsDefault(parent))
		children = WB_StimsetChildren()
	else
		children = WB_StimsetChildren(stimset = parent)
	endif

	// unique names list with dependent children always left to their parents
	children   = GetUniqueTextEntriesFromList(children, caseSensitive = 0)
	knownNames = children + knownNames
	numMoved   = ItemsInList(knownNames)
	knownNames = GetUniqueTextEntriesFromList(knownNames, caseSensitive = 0)
	numMoved  -= ItemsInList(knownNames)

	return numMoved
End

/// @brief Recursively descents into parent stimsets
///
/// You can not recurse into a stimset that depends on itself.
///
/// @return list of stimsets that derive from the input stimset
Function/S WB_StimsetRecursion([string parent, string knownStimsets])

	string stimset, stimsetQueue
	variable numStimsets, i, numBefore, numAfter, numMoved

	if(ParamIsDefault(knownStimsets))
		knownStimsets = ""
	endif

	numBefore = ItemsInList(knownStimsets)
	if(ParamIsDefault(parent))
		numMoved = WB_StimsetFamilyNames(knownStimsets)
		parent   = ""
	else
		numMoved = WB_StimsetFamilyNames(knownStimsets, parent = parent)
	endif
	numAfter = ItemsInList(knownStimsets)

	// check recently added stimsets.
	// @todo: moved parent stimsets should not be checked again and therefore moved between child and parent.
	stimsetQueue = knownStimsets
	for(i = 0; i < (numAfter - numBefore + numMoved); i += 1)
		stimset = StringFromList(i, stimsetQueue)
		// avoid first order circular references.
		if(cmpstr(stimset, parent))
			knownStimsets = WB_StimsetRecursion(parent = stimset, knownStimsets = knownStimsets)
		endif
	endfor

	DebugPrint(num2str(numMoved) + "stimsets were moved to the front because they have deep relationships.")
	DebugPrint(num2str(numAfter - numBefore) + " new stimsets added.")

	return knownStimsets
End

/// @brief Recursively descents into parent stimsets
///
/// @param stimsetQueue	can be a list of stimsets (separated by ;) or a simple string
///
/// @return list of stimsets that derive from the input stimsets
Function/S WB_StimsetRecursionForList(string stimsetQueue)

	variable i, numStimsets
	string stimset, stimsetList

	stimsetQueue = GetUniqueTextEntriesFromList(stimsetQueue, caseSensitive = 0)

	// loop through list
	numStimsets = ItemsInList(stimsetQueue)
	stimsetList = stimsetQueue
	for(i = 0; i < numStimsets; i += 1)
		stimset     = StringFromList(i, stimsetQueue)
		stimsetList = WB_StimsetRecursion(parent = stimset, knownStimsets = stimsetList)
	endfor

	return stimsetList
End

/// @brief check if parameter waves exist
///
/// @return 1 if parameter waves exist, 0 otherwise
Function WB_ParameterWavesExist(string stimset)

	WAVE/Z   WP        = WB_GetWaveParamForSet(stimset)
	WAVE/Z/T WPT       = WB_GetWaveTextParamForSet(stimset)
	WAVE/Z   SegWvType = WB_GetSegWvTypeForSet(stimset)

	if(WaveExists(WP) && WaveExists(WPT) && WaveExists(SegWvType))
		return 1
	endif

	return 0
End

/// @brief check if (custom) stimset exists
///
/// @return 1 if stimset wave was found, 0 otherwise
Function WB_StimsetExists(string stimset)

	variable channelType

	channelType = WB_GetStimSetType(stimset)

	if(channelType == CHANNEL_TYPE_UNKNOWN)
		return 0
	endif

	DFREF              setDFR = GetSetFolder(channelType)
	WAVE/Z/SDFR=setDFR wv     = $stimset

	if(WaveExists(wv))
		return 1
	endif

	return 0
End

/// @brief Kill Parameter waves for stimset
Function WB_KillParameterWaves(string stimset)

	WAVE/Z   WP        = WB_GetWaveParamForSet(stimset)
	WAVE/Z/T WPT       = WB_GetWaveTextParamForSet(stimset)
	WAVE/Z   SegWvType = WB_GetSegWvTypeForSet(stimset)

	if(!WaveExists(WP) && !WaveExists(WPT) && !WaveExists(SegWvType))
		return NaN
	endif

	KillOrMoveToTrash(wv = WP)
	KillOrMoveToTrash(wv = WPT)
	KillOrMoveToTrash(wv = SegWvType)

	return NaN
End

/// @brief Kill (custom) stimset
Function WB_KillStimset(string stimset)

	variable channelType

	channelType = WB_GetStimSetType(stimset)

	if(channelType == CHANNEL_TYPE_UNKNOWN)
		return NaN
	endif

	DFREF              setDFR = GetSetFolder(channelType)
	WAVE/Z/SDFR=setDFR wv     = $stimset

	if(!WaveExists(wv))
		return NaN
	endif

	KillOrMoveToTrash(wv = wv)

	return NaN
End

/// @brief Determine if the stimset is third party or from MIES
///
/// Third party stimsets don't have all parameter waves
///
/// @return true if from third party, false otherwise
Function WB_StimsetIsFromThirdParty(string stimset)

	ASSERT(!IsEmpty(stimset), "Stimset name can not be empty")

	WAVE/Z WP        = WB_GetWaveParamForSet(stimSet)
	WAVE/Z WPT       = WB_GetWaveTextParamForSet(stimSet)
	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(stimSet)

	return !WaveExists(WP) || !WaveExists(WPT) || !WaveExists(SegWvType)
End

/// @brief Internal use only
Function WB_AddAnalysisParameterIntoWPT(WAVE/T WPT, string name, [variable var, string str, WAVE wv])

	string params

	ASSERT((ParamIsDefault(var) + ParamIsDefault(str) + ParamIsDefault(wv)) == 2, "Expected one of var, str or wv")

	params = WPT[%$"Analysis function params (encoded)"][%Set][INDEP_EPOCH_TYPE]

	if(!ParamIsDefault(var))
		AFH_AddAnalysisParameterToParams(params, name, var = var)
	elseif(!ParamIsDefault(str))
		AFH_AddAnalysisParameterToParams(params, name, str = str)
	elseif(!ParamIsDefault(wv))
		AFH_AddAnalysisParameterToParams(params, name, wv = wv)
	endif

	WPT[%$"Analysis function params (encoded)"][%Set][INDEP_EPOCH_TYPE] = params
End

/// @brief Internal use only
Function WB_SetAnalysisFunctionGeneric(variable stimulusType, string analysisFunction, WAVE/T WPT)

	if(stimulusType != CHANNEL_TYPE_DAC)
		// only store analysis functions for DAC
		return 1
	endif

	WPT[9][%Set][INDEP_EPOCH_TYPE] = SelectString(cmpstr(analysisFunction, NONE), "", analysisFunction)

	// clear deprecated entries for single analysis function events
	if(cmpstr(analysisFunction, NONE))
		WPT[1, 5][%Set][INDEP_EPOCH_TYPE] = ""
		WPT[8][%Set][INDEP_EPOCH_TYPE]    = ""
		WPT[27][%Set][INDEP_EPOCH_TYPE]   = ""
	endif

	return 0
End

static Function WB_SaveStimSetParameterWaves(string setName, WAVE SegWvType, WAVE WP, WAVE/T WPT, variable stimulusType)

	string segWvTypeName, WPName, WPTName

	segWvTypeName = WB_GetParameterWaveName(setName, STIMSET_PARAM_SEGWVTYPE)
	WPName        = WB_GetParameterWaveName(setName, STIMSET_PARAM_WP)
	WPTName       = WB_GetParameterWaveName(setName, STIMSET_PARAM_WPT)

	DFREF dfr = GetSetParamFolder(stimulusType)

	Duplicate/O SegWvType, dfr:$segWvTypeName
	Duplicate/O WP, dfr:$WPName
	Duplicate/O WPT, dfr:$WPTName
End

Function/S WB_SaveStimSet(string baseName, variable stimulusType, WAVE SegWvType, WAVE WP, WAVE/T WPT, variable setNumber, variable saveAsBuiltin)

	string setName, genericFunc, params, errorMessage, childStimsets
	string   tempName
	variable i

	setName = WB_AssembleSetName(baseName, stimulusType, setNumber)

	if(IsEmpty(setName))
		return ""
	endif

	if(WBP_IsBuiltinStimset(setName) && !saveAsBuiltin)
		printf "The stimset %s can not be saved as it violates the naming scheme for user stimsets.\r", setName
		ControlWindowToFront()
		return ""
	endif

	genericFunc = WPT[%$("Analysis function (generic)")][%Set][INDEP_EPOCH_TYPE]
	params      = WPT[%$("Analysis function params (encoded)")][%Set][INDEP_EPOCH_TYPE]

	// avoid circular references of any order
	childStimsets = WB_StimsetRecursion()
	if(WhichListItem(setname, childStimsets, ";", 0, 0) != -1)
		do
			i      += 1
			setName = WB_AssembleSetName(basename, stimulusType, setNumber, suffix = "_" + num2str(i))
		while(WhichListItem(setname, childStimsets, ";", 0, 0) != -1)
		printf "Naming failure: Stimset can not reference itself. Saving with different name: \"%s\" to remove reference to itself.\r", setName
	endif

	// now we know that setName is a valid stimset name
	// but we need to first store it under a temporary name, so that
	// we can recover from errors when the checks fail
	tempName = WB_AssembleSetName("MIES_TEMPORARY_STIMSET_WILL_BE_DELETED", stimulusType, setNumber, lengthLimit = MAX_OBJECT_NAME_LENGTH_IN_BYTES)

	WB_SaveStimSetParameterWaves(tempName, SegWvType, WP, WPT, stimulusType)

	WAVE/Z stimset = WB_CreateAndGetStimSet(tempName)
	ASSERT(WaveExists(stimset), "Could not recreate stimset")

	// _CheckParam users rely on the stimset being present already
	STRUCT CheckParametersStruct s
	s.params  = params
	s.setName = tempName

	errorMessage = AFH_CheckAnalysisParameter(genericFunc, s)

	if(!IsEmpty(errorMessage))
		printf "The analysis parameters are not valid and the stimset can therefore not be saved.\r"
		print errorMessage
		ControlWindowToFront()
		ST_RemoveStimSet(tempName)
		return ""
	endif

	if(WB_CheckForEmptyEpochs(tempName))
		return ""
	endif

	if(WB_CheckStimsetContents(stimset))
		return ""
	endif

	// we now know that the stimset is valid
	// let's save it under the desired name and delete the temporary one
	WB_SaveStimSetParameterWaves(setName, SegWvType, WP, WPT, stimulusType)

	ST_RemoveStimSet(tempName)

	WAVE/Z stimset = WB_CreateAndGetStimSet(setName)
	ASSERT(WaveExists(stimset), "Could not recreate stimset")

	// propagate the existence of the new set
	WB_UpdateChangedStimsets(stimulusType = stimulusType)

	return setName
End

/// @brief Return a wave with the length of all epochs
///
/// @returns wave with epoch lengths or an invalid wave reference in case we don't have any epochs
Function/WAVE WB_GetEpochLengths(string setName)

	variable numEpochs

	numEpochs = ST_GetStimsetParameterAsVariable(setName, "Total number of epochs")
	ASSERT(IsInteger(numEpochs), "Expected numEpochs to be an integer")

	if(numEpochs <= 0)
		return $""
	endif

	Make/FREE/N=(numEpochs)/D epochLengths = ST_GetStimsetParameterAsVariable(setName, "Duration", epochIndex = p)

	return epochLengths
End

static Function WB_CheckStimsetContents(WAVE stimset)

	if(HasOneNonFiniteEntry(stimset))
		printf "The stimset contains at least one NaN/Inf/-Inf. Please remove them.\r"
		ControlWindowToFront()
		return 1
	endif

	return 0
End

static Function WB_CheckForEmptyEpochs(string setname)

	variable idx

	WAVE/Z epochLengths = WB_GetEpochLengths(setname)

	if(!WaveExists(epochLengths))
		printf "The stimset has no epochs. Please add at least one non-empty epoch.\r"
		ControlWindowToFront()
		return 1
	endif

	idx = GetRowIndex(epochLengths, val = 0)

	if(idx >= 0)
		printf "The epoch %d has a duration of zero. Please either remove that epoch or make its duration non-zero.\r", idx
		ControlWindowToFront()
		return 1
	endif

	return 0
End

/// @brief Return the name of a stimulus set build up from the passed parts
///
/// @returns complete stimulus set name or an empty string in case the basename is too long
static Function/S WB_AssembleSetName(string basename, variable stimulusType, variable setNumber, [string suffix, variable lengthLimit])

	string result

	if(ParamIsDefault(suffix))
		suffix = ""
	endif

	if(ParamIsDefault(lengthLimit))
		lengthLimit = MAX_OBJECT_NAME_LENGTH_IN_BYTES_SHORT
	else
		ASSERT(IsInteger(lengthLimit) && lengthLimit > 0, "Invalid length limit")
	endif

	if(strlen(basename) > lengthLimit)
		printf "The stimset %s can not be saved as it is too long (%d) compared to the allowed number (%d) of characters.\r", baseName, strlen(basename), lengthLimit
		ControlWindowToFront()
		return ""
	endif

	result = basename + suffix + "_" + ChannelTypeToString(stimulusType) + "_" + num2str(setNumber)

	return CleanupName(result, 0)
End

/// @brief Split the full setname into its three parts: prefix, stimulusType and set number
///
/// Counterpart to WB_AssembleSetName()
Function WB_SplitStimsetName(string setName, string &setPrefix, variable &stimulusType, variable &setNumber)

	string stimulusTypeString, setNumberString, setPrefixString

	setNumber    = NaN
	setPrefix    = ""
	stimulusType = CHANNEL_TYPE_UNKNOWN

	SplitString/E="(?i)(.*)_(DA|TTL)_([[:digit:]]+)" setName, setPrefixString, stimulusTypeString, setNumberString

	if(V_flag != 3)
		return NaN
	endif

	setNumber    = str2num(setNumberString)
	setPrefix    = setPrefixString
	stimulusType = ParseChannelTypeFromString(stimulusTypeString)
End

/// @brief Changes an existing stimset to a third party stimset
Function WB_MakeStimsetThirdParty(string setName)

	ASSERT(!IsEmpty(setName), "Stimset name can not be empty.")
	ASSERT(!WB_StimsetIsFromThirdParty(setName), "Specified Stimset is already a third party stimset")

	WAVE/Z stimset = WB_CreateAndGetStimSet(setName)
	ASSERT(WaveExists(stimset), "Specified stimset does not exist.")
	Note/K stimset

	WAVE WP        = WB_GetWaveParamForSet(setName)
	WAVE WPT       = WB_GetWaveTextParamForSet(setName)
	WAVE SegWvType = WB_GetSegWvTypeForSet(setName)
	KillOrMoveToTrash(wv = WP)
	KillOrMoveToTrash(wv = WPT)
	KillOrMoveToTrash(wv = SegWvType)
End

/// @brief Propagate added/removed stimsets to DA_Ephys panels and our epoch combine list
Function WB_UpdateChangedStimsets([string device, variable stimulusType])

	if(ParamIsDefault(device))
		DAP_UpdateDaEphysStimulusSetPopups()
	else
		DAP_UpdateDaEphysStimulusSetPopups(device = device)
	endif

	if(ParamIsDefault(stimulusType))
		WAVE/T epochCombineList = GetWBEpochCombineList(CHANNEL_TYPE_DAC)
		WB_UpdateEpochCombineList(epochCombineList, CHANNEL_TYPE_DAC)

		WAVE/T epochCombineList = GetWBEpochCombineList(CHANNEL_TYPE_TTL)
		WB_UpdateEpochCombineList(epochCombineList, CHANNEL_TYPE_TTL)
	else
		WAVE/T epochCombineList = GetWBEpochCombineList(stimulusType)
		WB_UpdateEpochCombineList(epochCombineList, stimulusType)
	endif
End

/// @brief Returns the start and end indices for a wave given a FP duration. The length within the wave is calculated in a way,
///        that at least the points to fill duration are included. So the effective duration never gets shortened.
///
/// @param  startTime      floating point start time of the range
/// @param  duration       floating point duration time
/// @param  sampleInterval floating point sample interval
/// @retval startIndex     index where the range starts
/// @retval endIndex       index where the range ends, this is inclusive for e.g. data[startIndex, endIndex] = amplitude
/// @retval startOffset    floating point error of start in wave regarding startTime argument: >= -0.5 * sampleInterval && < 0.5 * sampleInterval
/// @retval durationError  floating point error of duration in wave regarding duration argument: >= 0 && < sampleInterval
static Function [variable startIndex, variable endIndex, variable startOffset, variable durationError] WB_GetIndicesForSignalDuration(variable startTime, variable duration, variable sampleInterval)

	variable actualStartTime, ceilDelta, actualDuration

	ASSERT(startTime >= 0 && duration > 0 && sampleInterval > 0, "invalid argument values")
	[startIndex, startOffset] = RoundAndDelta(startTime / sampleInterval)
	actualStartTime           = startIndex * sampleInterval
	[endIndex, ceilDelta]     = CeilAndDelta((actualStartTime + duration) / sampleInterval)
	actualDuration            = (endIndex - startIndex) * sampleInterval

	return [startIndex, endIndex, startOffset, actualDuration - duration]
End

/// @brief Return the type, #CHANNEL_TYPE_DAC, #CHANNEL_TYPE_TTL or #CHANNEL_TYPE_UNKNOWN, of the stimset
///
/// All callers must ensure that they can handle the unexpected #CHANNEL_TYPE_UNKNOWN properly.
Function WB_GetStimSetType(string setName)

	string setPrefix
	variable channelType, setNumber

	WB_SplitStimsetName(setName, setPrefix, channelType, setNumber)

	return channelType
End

/// @brief Extract the analysis function name from the wave note of the stim set
/// @return Analysis function for the given event type, empty string if none is set
Function/S WB_ExtractAnalysisFuncFromStimSet(WAVE stimSet, variable eventType)

	string eventName

	eventName = StringFromList(eventType, EVENT_NAME_LIST)
	ASSERT(!IsEmpty(eventName), "Unknown event type")

	return WB_GetWaveNoteEntry(note(stimset), STIMSET_ENTRY, key = eventName)
End

/// @brief Return the analysis function parameters as comma (`,`) separated list
///
/// @sa GetWaveBuilderWaveTextParam() for the exact format.
Function/S WB_ExtractAnalysisFunctionParams(WAVE stimSet)

	return WB_GetWaveNoteEntry(note(stimset), STIMSET_ENTRY, key = ANALYSIS_FUNCTION_PARAMS_STIMSET)
End
