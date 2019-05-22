#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict Wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_WB
#endif

/// @file MIES_WaveBuilder.ipf
/// @brief __WB__ Stimulus set creation


static Constant PULSE_TRAIN_MODE_DUR   = 0x01
static Constant PULSE_TRAIN_MODE_PULSE = 0x02

static Constant WB_PULSE_TRAIN_TYPE_SQUARE   = 0
static Constant WB_PULSE_TRAIN_TYPE_TRIANGLE = 1

/// @name Constants for WB_GetControlWithDeltaIdx
/// @anchor ControlDeltaIndizes
/// The numeric values are row indizes in the waves returned by
/// WB_GetControlWithDeltaWvs().
/// @{
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
/// @}

static Constant DELTA_OPERATION_EXPLICIT  = 6
/// @brief Return the stim set wave and create it permanently
/// in the datafolder hierarchy
/// @return stimset wave ref or an invalid wave ref
Function/Wave WB_CreateAndGetStimSet(setName)
	string setName

	variable type, needToCreateStimSet

	if(isEmpty(setName))
		return $""
	endif

	type = GetStimSetType(setName)

	if(type == CHANNEL_TYPE_UNKNOWN)
		return $""
	endif

	DFREF dfr = GetSetFolder(type)
	WAVE/Z/SDFR=dfr stimSet = $setName

	if(!WaveExists(stimSet))
		// catches non-existing stimsets as well
		if(WB_StimsetIsFromThirdParty(setName))
			return $""
		endif

		needToCreateStimSet = 1
	elseif(WB_StimsetNeedsUpdate(setName))
		needToCreateStimSet = 1
	else
		needToCreateStimSet = 0
	endif

	if(needToCreateStimSet)
		// create current stimset
		WAVE/Z stimSet = WB_GetStimSet(setName=setName)
		if(!WaveExists(stimSet))
			return $""
		endif

		WAVE/Z/SDFR=dfr oldStimSet = $setName
		if(WaveExists(oldStimSet))
			KillOrMoveToTrash(wv=oldStimSet)
		endif

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
Function/S WB_GetParameterWaveName(stimset, type, [nwbFormat])
	string stimset
	variable type, nwbFormat

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
Function/Wave WB_GetWaveParamForSet(setName)
	string setName

	variable type

	type = GetStimSetType(setName)

	if(type == CHANNEL_TYPE_UNKNOWN)
		return $""
	endif

	DFREF dfr = GetSetParamFolder(type)

	WAVE/Z/SDFR=dfr wv = $WB_GetParameterWaveName(setName, STIMSET_PARAM_WP)

	return wv
End

/// @brief Return the wave `WPT` for a stim set
///
/// @return valid/invalid wave reference
Function/Wave WB_GetWaveTextParamForSet(setName)
	string setName

	variable type

	type = GetStimSetType(setName)

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
Function/Wave WB_GetSegWvTypeForSet(setName)
	string setName

	variable type

	type = GetStimSetType(setName)

	if(type == CHANNEL_TYPE_UNKNOWN)
		return $""
	endif

	DFREF dfr = GetSetParamFolder(type)

	WAVE/Z/SDFR=dfr wv = $WB_GetParameterWaveName(setName, STIMSET_PARAM_SEGWVTYPE)

	return wv
End

/// @brief Check if stimset needs to be created
///
/// Stimset is recreated
///     * if one of the parameter waves was modified
///     * the custom wave that was used to build the stimset was modified
///
/// @return 1 if stimset needs to be recreated, 0 otherwise
static Function WB_StimsetNeedsUpdate(setName)
	string setName

	string stimsets
	variable lastModStimSet, numWaves, numStimsets, i

	// stimset wave note is too old
	if(!WB_StimsetHasLatestNoteVersion(setName))
		return 1
	endif

	// check if parameter waves were modified
	stimsets = WB_StimsetRecursion(parent = setName)
	stimsets = AddListItem(setName, stimsets)
	numStimsets = ItemsInList(stimsets)
	for(i = 0; i < numStimsets; i += 1)
		if(WB_ParameterWvsNewerThanStim(StringFromList(i, stimsets)))
			return 1
		endif
	endfor

	// check if custom waves were modified
	lastModStimSet = WB_GetLastModStimSet(setName)
	WAVE/WAVE customWaves = WB_CustomWavesFromStimSet(stimSetList = stimsets)
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
static Function WB_StimsetHasLatestNoteVersion(setName)
	string setName

	DFREF dfr = GetSetFolder(GetStimSetType(setName))
	WAVE/Z/SDFR=dfr stimSet = $setName
	ASSERT(WaveExists(stimSet), "stimset must exist")

	return WB_GetWaveNoteEntryAsNumber(note(stimset), VERSION_ENTRY) >= STIMSET_NOTE_VERSION
End

/// @brief Check if parameter waves' are newer than the saved stimset
///
/// @param setName	string containing name of stimset
///
/// @return 1 if Parameter waves were modified, 0 otherwise
static Function WB_ParameterWvsNewerThanStim(setName)
	string setName

	variable lastModStimSet, lastModWP, lastModWPT, lastModSegWvType
	string msg, WPModCount, WPTModCount, SegWvTypeModCount

	WAVE/Z WP        = WB_GetWaveParamForSet(setName)
	WAVE/Z/T WPT     = WB_GetWaveTextParamForSet(setName)
	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(setName)

	lastModStimSet = WB_GetLastModStimSet(setName)
	if(WaveExists(WP) && WaveExists(WPT) && WaveExists(SegWvType))
		lastModWP        = modDate(WP)
		lastModWPT       = modDate(WPT)
		lastModSegWvType = modDate(SegWvType)

		sprintf msg, "stimset %d, WP %d, WPT %d, SegWvType %d", lastModStimSet, lastModWP, lastModWPT, lastModSegWvType
		DEBUGPRINT(msg)

		if(lastModWP > lastModStimSet || lastModWPT > lastModStimSet || lastModSegWvType > lastModStimSet)
			return 1
		elseif(lastModWP == lastModStimSet || lastModWPT == lastModStimSet || lastModSegWvType == lastModStimSet)
			DFREF dfr = GetSetFolder(GetStimSetType(setName))
			WAVE/Z/SDFR=dfr stimSet = $setName
			ASSERT(WaveExists(stimSet), "Unexpected missing wave")

			WPModCount =  GetStringFromWaveNote(stimSet, "WP modification count", keySep="=")
			WPTModCount = GetStringFromWaveNote(stimSet, "WPT modification count", keySep="=")
			SegWvTypeModCount = GetStringFromWaveNote(stimSet, "SegWvType modification count", keySep="=")

			sprintf msg, "WPModCount %s, WPTModCount %s, SegWvTypeModCount %s", WPModCount, WPTModCount, SegWvTypeModCount
			DEBUGPRINT(msg)

			if(IsEmpty(WPModCount) || IsEmpty(WPTModCount) || IsEmpty(SegWvTypeModCount))
				// old stimset without these entries, force recreation
				return 1
			endif

			if(WaveModCountWrapper(WP) > str2num(WPModCount)                  \
			   || WaveModCountWrapper(WPT) > str2num(WPTModCount)             \
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
Function WB_GetStimsetChecksum(stimset, setName, dataAcqOrTP)
	WAVE stimset
	string setName
	variable dataAcqOrTP

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
static Function WB_CalculateStimsetChecksum(stimset, setName)
	WAVE stimset
	string setName

	variable crc

	crc = WaveCRC(crc, stimset)

	WAVE/Z WP        = WB_GetWaveParamForSet(setName)
	WAVE/Z/T WPT     = WB_GetWaveTextParamForSet(setName)
	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(setName)

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
Function WB_GetLastModStimSet(setName)
	string setname

	DFREF dfr = GetSetFolder(GetStimSetType(setName))
	WAVE/Z/SDFR=dfr stimSet = $setName
	if(!WaveExists(stimSet))
		return 0
	endif

	return modDate(stimSet)
End

/// @brief Return the stim set wave
///
/// As opposed to #WB_CreateAndGetStimSet this function returns a free wave only
///
/// All external callers, outside the Wavebuilder, must call #WB_CreateAndGetStimSet
/// instead of this function.
///
/// @param setName [optional, defaults to WaveBuilderPanel GUI settings] name of the set
/// @return free wave with the stim set, invalid wave ref if the `WP*` parameter waves could
/// not be found.
Function/Wave WB_GetStimSet([setName])
	string setName

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

		WAVE WP        = GetWaveBuilderWaveParam()
		WAVE/T WPT     = GetWaveBuilderWaveTextParam()
		WAVE SegWvType = GetSegmentTypeWave()
		channelType    = WBP_GetOutputType()

		setName = ""
	else
		WAVE/Z WP        = WB_GetWaveParamForSet(setName)
		WAVE/T/Z WPT     = WB_GetWaveTextParamForSet(setName)
		WAVE/Z SegWvType = WB_GetSegWvTypeForSet(setName)
		channelType      = GetStimSetType(setName)

		if(!WaveExists(WP) || !WaveExists(WPT) || !WaveExists(SegWvType))
			return $""
		endif

		UpgradeWaveParam(WP)
		UpgradeWaveTextParam(WPT)
		UpgradeSegWvType(SegWvType)
	endif

	// WB_AddDelta modifies the waves so we pass a copy instead
	Duplicate/FREE WP, WPCopy
	Duplicate/FREE SegWvType, SegWvTypeCopy

	numSweeps  = SegWvType[101]
	numEpochs  = SegWvType[100]

	ASSERT(numSweeps > 0, "Invalid number of sweeps")

	MAKE/WAVE/FREE/N=(numSweeps) data

	for(i=0; i < numSweeps; i+=1)
		data[i] = WB_MakeWaveBuilderWave(WPCopy, WPT, SegWvTypeCopy, i, numEpochs, channelType, updateEpochIDWave, stimset = setName)
		lengthOf1DWaves = max(DimSize(data[i], ROWS), lengthOf1DWaves)
		if(i + 1 < numSweeps)
			if(WB_AddDelta(setName, WPCopy, WP, WPT, SegWvTypeCopy, SegWvType, i))
				return $""
			endif
		endif
	endfor

	// copy the random seed value in order to preserve it
	WP[48][][] = WPCopy[48][q][r]
	SegWvType[97] = SegWvTypeCopy[97]

	if(lengthOf1DWaves == 0)
		return $""
	endif

	Make/FREE/N=(lengthOf1DWaves, numSweeps) stimSet
	FastOp stimSet = 0

// note: here the stimset generation is coupled to the ITC minimum sample interval which is 200 kHz wheras for NI it is 500 kHz
	SetScale/P x 0, WAVEBUILDER_MIN_SAMPINT, "ms", stimset

	for(i = 0; i < numSweeps; i += 1)
		WAVE wv = data[i]

		length = DimSize(wv, ROWS)
		if(length == 0)
			continue
		endif

		last = length - 1
		Multithread stimSet[0, last][i] = wv[p]

		Note/NOCR stimSet, note(wv)
	endfor

	if(SegWvType[98])
		Duplicate/FREE stimset, stimsetFlipped
		for(i=0; i < numSweeps; i+=1)
			Duplicate/FREE/R=[][i] stimset, singleSweep
			WaveTransForm/O flip singleSweep
			Multithread stimSetFlipped[][i] = singleSweep[p]
		endfor
		WAVE stimset = stimsetFlipped
	endif

	if(!isEmpty(setName))
		AddEntryIntoWaveNoteAsList(stimset, "Checksum", var=WB_CalculateStimsetChecksum(stimset, setName), format = "%d")
		AddEntryIntoWaveNoteAsList(stimset, "WP modification count", var=WaveModCountWrapper(WP), format = "%d")
		AddEntryIntoWaveNoteAsList(stimset, "WPT modification count", var=WaveModCountWrapper(WPT), format = "%d")
		AddEntryIntoWaveNoteAsList(stimset, "SegWvType modification count", var=WaveModCountWrapper(SegWvType), format = "%d", appendCR=1)
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
static Function/WAVE WB_GetControlWithDeltaWvs(WP, SegWvType)
	WAVE WP, SegWvType

	Make/FREE/WAVE locations = {WP, WP, WP, WP, WP, WP, WP, WP, WP, WP, WP, WP, WP, WP, WP, WP, SegWvType}
	return locations
End

/// @brief Return the `WP`/`WPT/SegWvType` dimension labels for the related delta controls
/// given the index into `WP` of the value itself.
///
/// @return 0 on success, 1 otherwise
Function WB_GetDeltaDimLabel(wv, index, s)
	WAVE wv
	variable index
	STRUCT DeltaControlNames &s

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
static Function WB_AddDelta(setName, WP, WPOrig, WPT, SegWvType, SegWvTypeOrig, sweep)
	string setName
	Wave WP, WPOrig
	WAVE SegWvType, SegWvTypeOrig
	WAVE/T WPT
	variable sweep

	variable i, j
	variable operation
	variable type, numEntries, numEpochs
	string entry, ldelta
	variable value, delta, dme, originalValue, ret

	if(isEmpty(setName))
		setName = "Default"
	endif

	numEpochs = SegWvType[%$("Total number of epochs")]

	WAVE indizes = WB_GetControlWithDeltaIdx()
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

			ret = WB_CalculateParameterWithDelta(operation, value, delta, dme, ldelta, originalValue, sweep, setName, s.main)

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

			ret = WB_CalculateParameterWithDelta(operation, value, delta, dme, ldelta, originalValue, sweep, setName, s.main)

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
/// @param[in]      setName       name of the stimulus set (used for error reporting)
/// @param[in]      paramName     name of the parameter (used for error reporting)
static Function WB_CalculateParameterWithDelta(operation, value, delta, dme, ldelta, originalValue, sweep, setName, paramName)
	variable operation
	variable &value
	variable &delta
	variable dme
	string ldelta
	variable originalValue, sweep
	string setName, paramName

	string list, entry
	variable listDelta

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
			delta = delta == 0 ? 0 : log(delta)
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
			list = ldelta
			if(sweep >= ItemsInList(ldelta))
				printf "WB_AddDelta: Stimset \"%s\" has too many sweeps for the explicit delta values list \"%s\" of \"%s\"\r", setName, list, paramName
				listDelta = 0
			else
				entry = StringFromList(sweep, ldelta)
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
	variable duration
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
	variable trigFuncType // 0: sin, 1: cos
	variable noiseType // 0: white, 1: pink, 2:brown
	variable buildResolution // value, not the popup menu index
	variable pulseType // 0: square, 1: triangle
	variable mixedFreq
	variable mixedFreqShuffle
	variable firstFreq
	variable lastFreq
EndStructure

static Function/WAVE WB_MakeWaveBuilderWave(WP, WPT, SegWvType, stepCount, numEpochs, channelType, updateEpochIDWave, [stimset])
	Wave WP
	Wave/T WPT
	Wave SegWvType
	variable stepCount, numEpochs, channelType, updateEpochIDWave
	string stimset

	if(ParamIsDefault(stimset))
		stimset = ""
	endif

	Make/FREE/N=0 WaveBuilderWave

	string customWaveName, debugMsg, defMode, formula, formula_version
	variable i, j, type, accumulatedDuration, pulseToPulseLength
	STRUCT SegmentParameters params

	if(stepCount == 0)
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Version", var=STIMSET_NOTE_VERSION, appendCR = 1)
	endif

	AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Sweep", var=stepCount)
	AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch", var=NaN)
	AddEntryIntoWaveNoteAsList(WaveBuilderWave, "ITI", var=SegWvType[99], appendCR=1)

	for(i=0; i < numEpochs; i+=1)
		type = SegWvType[i]

		params.duration             = WP[0][i][type]
		params.deltaDur             = WP[1][i][type]
		params.amplitude            = WP[2][i][type]
		params.deltaAmp             = WP[3][i][type]
		params.offset               = WP[4][i][type]
		params.frequency            = WP[6][i][type]
		params.pulseDuration        = WP[8][i][type]
		params.tauRise              = WP[10][i][type]
		params.tauDecay1            = WP[12][i][type]
		params.tauDecay2            = WP[14][i][type]
		params.tauDecay2Weight      = WP[16][i][type]
		params.lowPassCutOff        = WP[20][i][type]
		params.highPassCutOff       = WP[22][i][type]
		params.endFrequency         = WP[24][i][type]
		params.filterOrder          = WP[26][i][type]
		params.logChirp             = WP[43][i][type]
		params.poisson              = WP[44][i][type]
		params.numberOfPulses       = WP[45][i][type]
		params.trigFuncType         = WP[53][i][type]
		params.noiseType            = WP[54][i][type]
		params.buildResolution      = str2num(StringFromList(WP[55][i][type], WBP_GetNoiseBuildResolution()))
		params.pulseType            = WP[56][i][type]
		params.mixedFreq            = WP[41][i][type]
		params.mixedFreqShuffle     = WP[42][i][type]
		params.firstFreq            = WP[28][i][type]
		params.lastFreq             = WP[30][i][type]

		sprintf debugMsg, "step count: %d, epoch: %d, duration: %g (delta %g), amplitude %d (delta %g)\r", stepCount, i, params.duration, params.DeltaDur, params.amplitude, params.DeltaAmp
		DEBUGPRINT("params", str=debugMsg)

		if(params.duration < 0 || !IsFinite(params.duration))
			printf "Stimset %s: User input has generated a negative/non-finite epoch duration. Please adjust input. Duration for epoch has been reset to 1 ms.\r", stimset
			params.duration = 1
		elseif(params.duration == 0 && type != EPOCH_TYPE_CUSTOM && type != EPOCH_TYPE_COMBINE && type != EPOCH_TYPE_PULSE_TRAIN)
			if(updateEpochIDWave && stepCount == 0)
				WB_UpdateEpochID(i, params.duration, accumulatedDuration)
			endif
			ASSERT(params.duration == 0, "Unexpected duration")

			AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Sweep", var=stepCount)
			AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch", var=i)
			AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type" , str=WB_ToEpochTypeString(type))
			AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration" , var=params.Duration, appendCR=1)
			continue
		endif

		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Sweep", var=stepCount)
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch", var=i)
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type" , str=WB_ToEpochTypeString(type))

		switch(type)
			case EPOCH_TYPE_SQUARE_PULSE:
				WB_SquareSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration" , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude", var=params.Amplitude)
				break
			case EPOCH_TYPE_RAMP:
				WB_RampSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration" , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude", var=params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"   , var=params.Offset)
				break
			case EPOCH_TYPE_NOISE:
				params.randomSeed = WB_InitializeSeed(WP, SegWvType, i, type, stepCount)

				WB_NoiseSegment(params)
				WAVE segmentWave = GetSegmentWave()
				WBP_ShowFFTSpectrumIfReq(segmentWave, stepCount)

				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration"          , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude"         , var=params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"            , var=params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Noise Type"        , \
															str=StringFromList(params.noiseType, NOISE_TYPES_STRINGS))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Low pass cut off"  , var=params.LowPassCutOff)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "High pass cut off" , var=params.HighPassCutOff)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Filter order"      , var=params.filterOrder)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Build resolution"  , var=params.buildResolution)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Random seed"       , var=params.randomSeed)
				break
			case EPOCH_TYPE_SIN_COS:
				WB_TrigSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration"     , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude"    , var=params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"       , var=params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency"    , var=params.Frequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "End frequency", var=params.EndFrequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Log chirp"    , str=ToTrueFalse(params.logChirp))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "FunctionType" , str=SelectString(params.trigFuncType, "Sin", "Cos"))
				break
			case EPOCH_TYPE_SAW_TOOTH:
				WB_SawToothSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration" , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude", var=params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency", var=params.Frequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"   , var=params.Offset)
				break
			case EPOCH_TYPE_PULSE_TRAIN:
				params.randomSeed = WB_InitializeSeed(WP, SegWvType, i, type, stepCount)

				Make/FREE/D/N=(MINIMUM_WAVE_SIZE) pulseStartTimes

				if(WP[46][i][type]) // "Number of pulses" checkbox
					WB_PulseTrainSegment(params, PULSE_TRAIN_MODE_PULSE, pulseStartTimes, pulseToPulseLength)
					if(windowExists("WaveBuilder")                                              \
					   && GetTabID("WaveBuilder", "WBP_WaveType") == EPOCH_TYPE_PULSE_TRAIN     \
					   && GetSetVariable("WaveBuilder", "setvar_WaveBuilder_CurrentEpoch") == i)
						WBP_UpdateControlAndWave("SetVar_WaveBuilder_P0", var = params.duration)
					endif
					defMode = "Pulse"
				else
					WB_PulseTrainSegment(params, PULSE_TRAIN_MODE_DUR, pulseStartTimes, pulseToPulseLength)
					if(windowExists("WaveBuilder")                                              \
					   && GetTabID("WaveBuilder", "WBP_WaveType") == EPOCH_TYPE_PULSE_TRAIN     \
					   && GetSetVariable("WaveBuilder", "setvar_WaveBuilder_CurrentEpoch") == i)
						WBP_UpdateControlAndWave("SetVar_WaveBuilder_P45", var = params.numberOfPulses)
					endif
					defMode = "Duration"
				endif

				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration"               , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude"              , var=params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"                 , var=params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Pulse Type"             , \
							               str=StringFromList(params.pulseType, PULSE_TYPES_STRINGS))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency"              , var=params.Frequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, PULSE_TO_PULSE_LENGTH_KEY, var=pulseToPulseLength)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Pulse duration"         , var=params.PulseDuration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Number of pulses"       , var=params.NumberOfPulses)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Mixed frequency"        , str=ToTrueFalse(params.mixedFreq))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Mixed frequency shuffle", str=ToTrueFalse(params.mixedFreqShuffle))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "First mixed frequency"  , var=params.firstFreq)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Last mixed frequency"   , var=params.lastFreq)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Poisson distribution"   , str=ToTrueFalse(params.poisson))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Random seed"            , var=params.randomSeed)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, PULSE_START_TIMES_KEY    , str=NumericWaveToList(pulseStartTimes, ",", format="%.15g"))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Definition mode"        , str=defMode)
				break
			case EPOCH_TYPE_PSC:
				WB_PSCSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration"          , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude"         , var=params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"            , var=params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau rise"          , var=params.TauRise)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau decay 1"       , var=params.TauDecay1)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau decay 2"       , var=params.TauDecay2)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau decay 2 weight", var=params.TauDecay2Weight)
				break
			case EPOCH_TYPE_CUSTOM:
				WB_UpgradecustomWaveInWPT(WPT, channelType, i)
				customWaveName = WPT[0][i][EPOCH_TYPE_CUSTOM]
				WAVE/Z customWave = $customWaveName
				if(WaveExists(customWave))
					WB_CustomWaveSegment(params, customWave)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration"    , var=params.Duration)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"      , var=params.Offset)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "CustomWavePath", str=customWaveName)
				elseif(!isEmpty(customWaveName))
					printf "Stimset %s: Failed to recreate custom wave epoch %d as the referenced wave %s is missing\r", stimset, i, customWaveName
				endif
				WaveClear customWave
				break
			case EPOCH_TYPE_COMBINE:
				WAVE segmentWave = GetSegmentWave(duration=0)

				formula         = WPT[6][i][EPOCH_TYPE_COMBINE]
				formula_version = WPT[7][i][EPOCH_TYPE_COMBINE]

				if(cmpstr(formula_version, WAVEBUILDER_COMBINE_FORMULA_VER))
					printf "Stimset %s: Could not create the wave from formula of version %s\r", stimset, WAVEBUILDER_COMBINE_FORMULA_VER
					break
				endif

				WAVE/Z combinedWave = WB_FillWaveFromFormula(formula, channelType, stepCount)

				if(!WaveExists(combinedWave))
					printf "Stimset %s: Could not create the wave from the formula", stimset
					break
				endif

				Duplicate/O combinedWave, segmentWave

				params.Duration = DimSize(segmentWave, ROWS) * WAVEBUILDER_MIN_SAMPINT

				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Formula"         , str=formula)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Formula Version" , str=formula_version)
				break
			default:
				printf "Stimset %s: Ignoring unknown epoch type %d\r", stimset, type
				continue
		endswitch

		// add CR as we have finished an epoch
		Note/NOCR WaveBuilderWave, "\r"

		if(type != EPOCH_TYPE_COMBINE)
			WB_ApplyOffset(params)
		endif

		if(updateEpochIDWave && stepCount == 0)
			WB_UpdateEpochID(i, params.duration, accumulatedDuration)
		endif

		accumulatedDuration += params.duration

		WAVE segmentWave = GetSegmentWave()
		Concatenate/NP=0 {segmentWave}, WaveBuilderWave
	endfor

	// adjust epochID timestamps for stimset flipping
	if(updateEpochIDWave && SegWvType[98])
		if(stepCount == 0)
			WAVE epochID = GetEpochID()
			for(i = 0; i < numEpochs; i += 1)
				epochID[i][%timeBegin] = accumulatedDuration - epochID[i][%timeBegin]
				epochID[i][%timeEnd]   = accumulatedDuration - epochID[i][%timeEnd]
			endfor
		endif
	endif

	// add stimset entries at last step
	if(stepCount + 1 == SegWvType[101])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Stimset")
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Sweep Count", var=SegWvType[101])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch Count" , var=numEpochs)
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST), str=WPT[1][%Set][INDEP_EPOCH_TYPE])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST), str=WPT[2][%Set][INDEP_EPOCH_TYPE])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST), str=WPT[3][%Set][INDEP_EPOCH_TYPE])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(POST_SET_EVENT, EVENT_NAME_LIST), str=WPT[4][%Set][INDEP_EPOCH_TYPE])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST), str=WPT[5][%Set][INDEP_EPOCH_TYPE])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(PRE_SWEEP_EVENT, EVENT_NAME_LIST), str=WPT[8][%Set][INDEP_EPOCH_TYPE])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(GENERIC_EVENT, EVENT_NAME_LIST), str=WPT[9][%Set][INDEP_EPOCH_TYPE])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(PRE_SET_EVENT, EVENT_NAME_LIST), str=WPT[27][%Set][INDEP_EPOCH_TYPE])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, ANALYSIS_FUNCTION_PARAMS_LBN, str=WPT[10][%Set][INDEP_EPOCH_TYPE])

		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Flip", var=SegWvType[98])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Random Seed", var=SegWvType[97])
	endif

	return WaveBuilderWave
End

/// @brief Update the accumulated stimset duration for the mouse selection via GetEpochID()
///
/// @param[in] epochIndex          index of the epoch
/// @param[in] epochDuration       duration of the current segment
/// @param[in] accumulatedDuration accumulated duration in the stimset for the first step
static Function WB_UpdateEpochID(epochIndex, epochDuration, accumulatedDuration)
	variable epochIndex, epochDuration
	variable accumulatedDuration

	WAVE epochID = GetEpochID()
	if(epochIndex == 0)
		epochID = 0
	endif

	epochID[epochIndex][%timeBegin] = accumulatedDuration
	epochID[epochIndex][%timeEnd]   = accumulatedDuration + epochDuration
End

/// @brief Query the stimset wave note for the sweep/set specific ITI
Function WB_GetITI(stimset, sweep)
	WAVE stimset
	variable sweep

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
Function WB_UpgradeCustomWaveInWPT(wv, channelType, i)
	WAVE/T wv
	variable channelType, i

	string customWaveName = wv[0][i][EPOCH_TYPE_CUSTOM]

	// old style entries with only the wave name
	if(!isEmpty(customWaveName) && strsearch(customWaveName, ":", 0) == -1)
		printf "Warning: Legacy format for custom wave epochs detected.\r"

		if(windowExists("Wavebuilder"))
			DFREF customWaveDFR = WBP_GetFolderPath()
			Wave/Z/SDFR=customWaveDFR customWave = $customWaveName
		endif

		if(!WaveExists(customWave))
			DFREF customWaveDFR = GetSetFolder(channelType)
			Wave/Z/SDFR=customWaveDFR customWave = $customWaveName
		endif

		if(WaveExists(customWave))
			printf "Upgraded custom wave format successfully.\r"
			wv[0][i][EPOCH_TYPE_CUSTOM] = GetWavesDataFolder(customWave, 2)
		endif
	endif
End

static Function WB_ApplyOffset(pa)
	struct SegmentParameters &pa

	if(pa.offset == 0)
		return NaN
	endif

	WAVE SegmentWave = GetSegmentWave()

	MultiThread segmentWave[] += pa.offset
End

/// @brief Initialize the seed value of the pseudo random number generator
static Function WB_InitializeSeed(WP, SegWvType, epoch, type, stepCount)
	WAVE WP, SegWvType
	variable epoch, type, stepCount

	variable j, randomSeed

	// initialize the random seed value if not already done
	// per epoch seed
	if(WP[48][epoch][type] == 0)
		NewRandomSeed()
		WP[48][epoch][type] = GetReproducibleRandom()
	endif

	// global stimset seed
	if(SegWvType[97] == 0)
		NewRandomSeed()
		SegWvType[97] = GetReproducibleRandom()
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
			randomSeed = GetReproducibleRandom()
		endfor

		SetRandomSeed/BETR=1 randomSeed
	endif

	return randomSeed
End

/// @name Functions that build wave types
/// @{
static Function WB_SquareSegment(pa)
	struct SegmentParameters &pa

	Wave SegmentWave = GetSegmentWave(duration=pa.duration)
	MultiThread SegmentWave = pa.amplitude
End

static Function WB_RampSegment(pa)
	struct SegmentParameters &pa

	variable amplitudeIncrement = pa.amplitude * WAVEBUILDER_MIN_SAMPINT / pa.duration

	Wave SegmentWave = GetSegmentWave(duration=pa.duration)
	MultiThread SegmentWave = amplitudeIncrement * p
End

/// @brief Check if the given frequency is a valid setting for the noise epoch
Function WB_IsValidCutoffFrequency(freq)
	variable freq

	return WB_IsValidScaledCutoffFrequency(freq / WAVEBUILDER_MIN_SAMPINT_HZ)
End

/// @brief Check if the given frequency is a valid setting for the noise epoch
///
/// Requires a scaled frequency as input, see `DisplayHelpTopic "FilterIIR"`
Function WB_IsValidScaledCutoffFrequency(freq)
	variable freq

	return freq > 0 && freq <= 0.5
End

static Function WB_NoiseSegment(pa)
	STRUCT SegmentParameters &pa

	variable samples, filterOrder
	variable lowPassCutoffScaled, highPassCutoffScaled
	variable referenceTime = DEBUG_TIMER_START()

	ASSERT(IsInteger(pa.buildResolution) && pa.buildResolution > 0, "Invalid build resolution")

	// duration is in ms
	samples = pa.duration * pa.buildResolution * WAVEBUILDER_MIN_SAMPINT_HZ * 1e-3

	// even number of points for IFFT
	samples = 2 * ceil(samples / 2)

	Make/FREE/D/C/N=(samples / 2 + 1) magphase
	FastOp magphase = 0
	SetScale/P x 0, WAVEBUILDER_MIN_SAMPINT_HZ/samples, "Hz" magphase

	// we can't use Multithread here as this creates non-reproducible data
	switch(pa.noiseType)
		case NOISE_TYPE_WHITE:
			magphase[1, inf] = cmplx(1, enoise(Pi, NOISE_GEN_MERSENNE_TWISTER))
			break
		case NOISE_TYPE_PINK: // drops with 10db per decade
			magphase[1, inf] = cmplx(1/sqrt(x), enoise(Pi, NOISE_GEN_MERSENNE_TWISTER))
			break
		case NOISE_TYPE_BROWN: // drops with 20db per decade
			magphase[1, inf] = cmplx(1/x, enoise(Pi, NOISE_GEN_MERSENNE_TWISTER))
			break
		default:
			ASSERT(0, "Invalid noise type")
			break
	endswitch

	WAVE SegmentWave = GetSegmentWave(duration=pa.duration)

#ifdef DEBUGGING_ENABLED
	if(DP_DebuggingEnabledForFile(GetFile(FunctionPath(""))))
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
	SetScale/P x, 0, DimDelta(segmentWave, ROWS) * 1000, "ms", segmentWave

	Redimension/N=(DimSize(segmentWave, ROWS) / pa.buildResolution) segmentWave

	lowPassCutoffScaled  = pa.lowpasscutoff  / WAVEBUILDER_MIN_SAMPINT_HZ
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

	MatrixOp/FREE scaleFactor = pa.amplitude / (maxVal(segmentWave) - minVal(segmentWave)))
	MultiThread segmentWave[] = segmentWave[p] * scaleFactor[0] // ScaleFactor is a 1x1 matrix

	DEBUGPRINT_ELAPSED(referenceTime)
End

static Function WB_TrigSegment(pa)
	struct SegmentParameters &pa

	variable k0, k1, k2, k3

	if(pa.trigFuncType != 0 && pa.trigFuncType != 1)
		printf "Ignoring unknown trigonometric function"
		Wave SegmentWave = GetSegmentWave(duration=0)
		return NaN
	endif

	Wave SegmentWave = GetSegmentWave(duration=pa.duration)

	if(pa.logChirp)
		k0 = ln(pa.frequency / 1000)
		k1 = (ln(pa.endFrequency / 1000) - k0) / (pa.duration)
		k2 = 2 * pi * e^k0 / k1
		k3 = mod(k2, 2 * pi)		// LH040117: start on rising edge of sin and don't try to round.
		if(pa.trigFuncType == 0)
			MultiThread SegmentWave = pa.amplitude * sin(k2 * e^(k1 * x) - k3)
		else
			MultiThread SegmentWave = pa.amplitude * cos(k2 * e^(k1 * x) - k3)
		endif
	else
		if(pa.trigFuncType == 0)
			MultiThread SegmentWave = pa.amplitude * sin(2 * Pi * (pa.frequency * 1000) * (5 / 1000000000) * p)
		else
			MultiThread SegmentWave = pa.amplitude * cos(2 * Pi * (pa.frequency * 1000) * (5 / 1000000000) * p)
		endif
	endif
End

static Function WB_SawToothSegment(pa)
	struct SegmentParameters &pa

	Wave SegmentWave = GetSegmentWave(duration=pa.duration)

	MultiThread SegmentWave = 1 * pa.amplitude * sawtooth(2 * Pi * (pa.frequency * 1000) * (5 / 1000000000) * p)
End

static Function WB_CreatePulse(wv, pulseType, amplitude, first, last)
	WAVE wv
	variable pulseType, amplitude, first, last

	if(pulseType == WB_PULSE_TRAIN_TYPE_SQUARE)
		wv[first, last] = amplitude
	elseif(pulseType == WB_PULSE_TRAIN_TYPE_TRIANGLE)
		wv[first, last] = amplitude * (p - first) / (last - first)
	else
		ASSERT(0, "unknown pulse type")
	endif
End

/// @brief Convert the numeric epoch type to a stringified version
Function/S WB_ToEpochTypeString(epochType)
	variable epochType

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
			ASSERT(0, "Unknown epoch: " + num2str(epochType))
			return ""
	endswitch
End

/// @brief Convert the stringified epoch type to a numerical one
Function WB_ToEpochType(epochTypeStr)
	string epochTypeStr

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
			ASSERT(0, "Unknown epoch: " + epochTypeStr)
			return NaN
	endswitch
End

/// @brief Query stimset wave note entries
///
/// \rst
/// Format of the wave note:
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
/// 	Stimset;Sweep Count = 2;Epoch Count = 4;Pre DAQ = ;Mid Sweep = ;Post Sweep = ;Post Set = ;Post DAQ = ;Pre Sweep = ;Generic = PSQ_Ramp;Pre Set = ;Function params = NumberOfSpikes:variable=5,Elements:string=Hidiho,;Flip = 0;Random Seed = 0.963638;Checksum = 65446509;
/// \endrst
///
/// @param text      stimulus set wave note
/// @param entryType one of @ref StimsetWaveNoteEntryTypes
/// @param key       [optional] named entry to return, not required for #VERSION_ENTRY
/// @param sweep     [optional] number of the sweep
/// @param epoch     [optional] number of the epoch
Function/S WB_GetWaveNoteEntry(text, entryType, [key, sweep, epoch])
	string text
	variable entryType
	string key
	variable sweep, epoch

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
			sprintf re "^%s.*;$", key
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
			ASSERT(0, "Unknown entryType")
	endswitch

	match = GrepList(text, re, 0, "\r")

	if(IsEmpty(match))
		return match
	endif

	ASSERT(ItemsInList(match, "\r") == 1, "Expected only one matching line")

	return ExtractStringFromPair(match, key, keySep = "=")
End

// @copydoc WB_GetWaveNoteEntry
Function WB_GetWaveNoteEntryAsNumber(text, entryType, [key, sweep, epoch])
	string text
	variable entryType
	string key
	variable sweep, epoch

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

Function/WAVE WB_GetPulsesFromPTSweepEpoch(stimset, sweep, epoch, pulseToPulseLength)
	WAVE stimset
	variable sweep, epoch
	variable &pulseToPulseLength

	string startTimesList, stimNote
	stimNote = note(stimset)

	pulseToPulseLength = WB_GetWaveNoteEntryAsNumber(stimNote, EPOCH_ENTRY, sweep = sweep, epoch = epoch, key = PULSE_TO_PULSE_LENGTH_KEY)
	ASSERT(IsFinite(pulseToPulseLength), "Non-finite " + PULSE_TO_PULSE_LENGTH_KEY)

	startTimesList = WB_GetWaveNoteEntry(stimNote, EPOCH_ENTRY, sweep = sweep, epoch = epoch, key = PULSE_START_TIMES_KEY)
	WAVE/Z/D startTimes = ListToNumericWave(startTimesList, ",")
	ASSERT(WaveExists(startTimes) && DimSize(startTimes, ROWS) > 0, "Found no starting times")

	return startTimes
End

static Function/WAVE WB_PulseTrainSegment(pa, mode, pulseStartTimes, pulseToPulseLength)
	struct SegmentParameters &pa
	variable mode
	WAVE pulseStartTimes
	variable &pulseToPulseLength

	variable pulseStartTime, endIndex, startIndex, i
	variable numRows, interPulseInterval, idx, firstStep, lastStep, dist
	string str

	pulseToPulseLength = NaN

	ASSERT(pa.poisson + pa.mixedFreq <= 1, "Only one of Mixed Frequency or poisson can be checked")

	if(!pa.mixedFreq)
		if(!(pa.frequency > 0))
			printf "Resetting invalid frequency of %gHz to 1Hz\r", pa.frequency
			pa.frequency = 1.0
		endif

		if(mode == PULSE_TRAIN_MODE_PULSE)
			// user defined number of pulses
			pa.duration = pa.numberOfPulses / pa.frequency * 1000
		elseif(mode == PULSE_TRAIN_MODE_DUR)
			// user defined duration
			pa.numberOfPulses = pa.frequency * pa.duration / 1000
		else
			ASSERT(0, "Invalid mode")
		endif

		if(!(pa.duration > 0))
			printf "Resetting invalid duration of %gms to 1ms\r", pa.duration
			pa.duration = 1.0
		endif
	endif

	if(pa.poisson)

		interPulseInterval = (1 / pa.frequency) * 1000 - pa.pulseDuration

		WAVE segmentWave = GetSegmentWave(duration=pa.duration)
		FastOp segmentWave = 0
		numRows = DimSize(segmentWave, ROWS)

		pulseToPulseLength = 0

		for(;;)
			pulseStartTime += -ln(abs(enoise(1, NOISE_GEN_MERSENNE_TWISTER))) / pa.frequency * 1000
			endIndex = floor((pulseStartTime + pa.pulseDuration) / WAVEBUILDER_MIN_SAMPINT)

			if(endIndex >= numRows || endIndex < 0)
				break
			endif

			startIndex = floor(pulseStartTime / WAVEBUILDER_MIN_SAMPINT)
			WB_CreatePulse(segmentWave, pa.pulseType, pa.amplitude, startIndex, endIndex)

			EnsureLargeEnoughWave(pulseStartTimes, minimumSize=idx)
			pulseStartTimes[idx++] = pulseStartTime
		endfor
	elseif(pa.mixedFreq)

		firstStep = 1 / pa.firstFreq
		lastStep  = 1 / pa.lastFreq
		dist      = (lastStep / firstStep)^(1 / (pa.numberOfPulses - 1))
		Make/D/FREE/N=(pa.numberOfPulses) interPulseIntervals = firstStep * dist^p * 1000 - pa.pulseDuration

		if(pa.mixedFreqShuffle)
			InPlaceRandomShuffle(interPulseIntervals, noiseGenMode = NOISE_GEN_MERSENNE_TWISTER)
		endif

		pulseToPulseLength = 0

		pa.duration = (sum(interPulseIntervals) + pa.numberOfPulses * pa.pulseDuration)
		WAVE segmentWave = GetSegmentWave(duration=pa.duration)
		FastOp segmentWave = 0
		numRows = DimSize(segmentWave, ROWS)

		for(i = 0; i < pa.numberOfPulses; i += 1)

			endIndex = floor((pulseStartTime + pa.pulseDuration) / WAVEBUILDER_MIN_SAMPINT)

			if(endIndex >= numRows || endIndex < 0)
				break
			endif

			startIndex = floor(pulseStartTime / WAVEBUILDER_MIN_SAMPINT)
			WB_CreatePulse(segmentWave, pa.pulseType, pa.amplitude, startIndex, endIndex)

			EnsureLargeEnoughWave(pulseStartTimes, minimumSize=idx)
			pulseStartTimes[idx++] = pulseStartTime

			pulseStartTime += interPulseIntervals[i] + pa.pulseDuration
		endfor
	else
		interPulseInterval = (1 / pa.frequency) * 1000 - pa.pulseDuration

		WAVE segmentWave = GetSegmentWave(duration=pa.duration)
		FastOp segmentWave = 0
		numRows = DimSize(segmentWave, ROWS)

		pulseToPulseLength = interPulseInterval + pa.pulseDuration

		for(;;)
			endIndex = floor((pulseStartTime + pa.pulseDuration) / WAVEBUILDER_MIN_SAMPINT)

			if(endIndex >= numRows || endIndex < 0)
				break
			endif

			startIndex = floor(pulseStartTime / WAVEBUILDER_MIN_SAMPINT)
			WB_CreatePulse(segmentWave, pa.pulseType, pa.amplitude, startIndex, endIndex)

			EnsureLargeEnoughWave(pulseStartTimes, minimumSize=idx)
			pulseStartTimes[idx++] = pulseStartTime

			pulseStartTime += interPulseInterval + pa.pulseDuration
		endfor
	endif

	Redimension/N=(idx) pulseStartTimes

	// remove the zero part at the end
	FindValue/V=(0)/S=(pa.pulseType == WB_PULSE_TRAIN_TYPE_SQUARE ? startIndex : startIndex + 1) segmentWave
	if(V_Value != -1)
		DEBUGPRINT("Removal of points:", var=(DimSize(segmentWave, ROWS) - V_Value))
		Redimension/N=(V_Value) segmentWave
		pa.duration = V_Value * WAVEBUILDER_MIN_SAMPINT
	else
		DEBUGPRINT("No removal of points")
	endif

	sprintf str, "interPulseInterval=%g ms, numberOfPulses=%g [a.u.], pulseDuration=%g [ms], real duration=%.6f [a.u.]\r", \
	 			  interPulseInterval, pa.numberOfPulses, pa.pulseDuration, DimSize(segmentWave, ROWS) * WAVEBUILDER_MIN_SAMPINT

	DEBUGPRINT(str)
End

static Function WB_PSCSegment(pa)
	struct SegmentParameters &pa

	variable baseline, peak

	Wave SegmentWave = GetSegmentWave(duration=pa.duration)

	pa.TauRise = 1 / pa.TauRise
	pa.TauRise *= WAVEBUILDER_MIN_SAMPINT
	pa.TauDecay1 = 1 / pa.TauDecay1
	pa.TauDecay1 *= WAVEBUILDER_MIN_SAMPINT
	pa.TauDecay2 = 1 / pa.TauDecay2
	pa.TauDecay2 *= WAVEBUILDER_MIN_SAMPINT

	MultiThread SegmentWave[] = pa.amplitude * ((1 - exp(-pa.TauRise * p)) + exp(-pa.TauDecay1 * p) * (1 - pa.TauDecay2Weight) + exp(-pa.TauDecay2 * p) * pa.TauDecay2Weight)

	baseline = WaveMin(SegmentWave)
	peak = WaveMax(SegmentWave)
	MultiThread SegmentWave *= abs(pa.amplitude)/(peak - baseline)

	baseline = WaveMin(SegmentWave)
	MultiThread SegmentWave -= baseline
End

static Function WB_CustomWaveSegment(pa, customWave)
	struct SegmentParameters &pa
	WAVE customWave

	pa.duration = DimSize(customWave, ROWS) * WAVEBUILDER_MIN_SAMPINT
	WAVE segmentWave = GetSegmentWave(duration=pa.duration)
	MultiThread segmentWave[] = customWave[p]
End

/// @brief Create a wave segment as combination of existing stim sets
static Function/WAVE WB_FillWaveFromFormula(formula, channelType, sweep)
	string formula
	variable channelType
	variable sweep

	STRUCT FormulaProperties fp
	string shorthandFormula

	// update shorthand -> stimset mapping
	WB_UpdateEpochCombineList(channelType)

	shorthandFormula = WB_FormulaSwitchToShorthand(formula)

	if(WB_ParseCombinerFormula(shorthandFormula, sweep, fp))
		return $""
	endif

	DEBUGPRINT("Formula:", str=fp.formula)

	DFREF dfr       = GetDataFolderDFR()
	DFREF targetDFR = GetSetFolder(channelType)

	SetDataFolder targetDFR
	Make/O/D/N=(fp.numRows) d
	Execute/Q/Z fp.formula

	if(V_Flag)
		printf "WB_FillWaveFromFormula: Error executing the formula \"%s\"\r", formula
		KillOrMoveToTrash(wv=d)
		SetDataFolder dfr
		return $""
	endif

	SetDataFolder dfr

	return MakeWaveFree(d)
End
/// @}

/// @brief Update the shorthand/stimset wave for the epoch type `Combine`
///
/// The rows are sorted by creationDate of the WP/stimset wave to try to keep
/// the shorthands constants even when new stimsets are added.
Function WB_UpdateEpochCombineList(channelType)
	variable channelType

	string list, setPath, setParamPath, entry
	variable numEntries, i

	list = ReturnListOfAllStimSets(channelType, "*")
	list = RemoveFromList("TestPulse", list)

	numEntries = ItemsInList(list)

	if(!numEntries)
		return NaN
	endif

	Make/D/FREE/N=(numEntries) creationDates
	Make/T/FREE/N=(numEntries) stimsets = StringFromList(p, list)

	DFREF dfr = GetSetFolder(channelType)

	for(i = 0; i < numEntries; i += 1)
		entry = StringFromList(i, list)
		WAVE/SDFR=dfr/Z stimset = $entry
		WAVE/Z WP = WB_GetWaveParamForSet(entry)

		if(WaveExists(WP))
			creationDates[i] = CreationDate(WP)
		elseif(WaveExists(stimset))
			creationDates[i] = CreationDate(stimset)
		else
			ASSERT(0, "Missing stimset/param wave")
		endif
	endfor

	Sort creationDates, stimsets

	Wave/T epochCombineList = GetWBEpochCombineList()
	Redimension/N=(numEntries, -1) epochCombineList

	epochCombineList[][%StimSet]   = stimsets[p]
	epochCombineList[][%Shorthand] = WB_GenerateUniqueLabel(p)
End

/// @brief Generate a unique textual representation of an index
///
/// Returns the alphabet for 1-26, and then A1, B1, ..., Z1000
static Function/S WB_GenerateUniqueLabel(idx)
	variable idx

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
/// @param[in]  formula  math formula to execute, all operators which Igor can grok are allowed
/// @param      sweep    current sweep (aka step)
/// @param[out] fp       parsed formula structure, with shorthands replaced by stimsets,
///                      empty on parse error, ready to be executed by WB_FillWaveFromFormula()
///
/// @returns 0 on success, 1 on parse errors (currently not many are found)
Function WB_ParseCombinerFormula(formula, sweep, fp)
	string formula
	variable sweep
	struct FormulaProperties &fp

	string dependentStimsets
	variable i, numStimsets
	struct FormulaProperties trans
	variable numRows = Inf
	variable numCols = Inf

	InitFormulaProperties(fp)
	InitFormulaProperties(trans)
	WB_FormulaSwitchToStimset(formula, trans)

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
Function WB_FormulaSwitchToStimset(formula, fp)
	string formula
	struct FormulaProperties &fp

	string stimset, shorthand, stimsetSpec, prefix, suffix
	variable numSets, i, stimsetFound

	InitFormulaProperties(fp)

	if(isEmpty(formula))
		return NaN
	endif

	WAVE/T epochCombineList = GetWBEpochCombineList()

	formula = UpperStr(formula)

	// we replace, case sensitive!, all upper case shorthands with lower case
	// stimsets in that way we don't mess up the formula
	// iterate the stimset list from bottom to top, so that we replace first the shorthands
	// with numeric prefix and only later on the ones without
	numSets = DimSize(epochCombineList, ROWS)
	for(i = numSets - 1; i >= 0; i -= 1)
		shorthand   = epochCombineList[i][%Shorthand]
		stimset     = epochCombineList[i][%stimset]
		stimsetSpec = LowerStr(stimset) + "?"
		stimsetFound = 0

		// search and replace until shorthand isn't found in formula anymore.
		ASSERT(!SearchWordInString(stimsetSpec, shorthand), "circle reference: shorthand is part of stimset. prevented infinite loop")
		do
			if(!SearchWordInString(formula, shorthand, prefix = prefix, suffix = suffix))
				break
			endif
			formula = prefix + stimsetSpec + suffix
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
static Function WB_PrepareFormulaForExecute(fp, sweep)
	struct FormulaProperties &fp
	variable sweep

	string spec
	sprintf spec, "[p][%d]", sweep

	fp.formula = "d[]=" + ReplaceString("?", fp.formula, spec)
End

/// @brief Replace all stimsets suffixed with `?` by their shorthands
Function/S WB_FormulaSwitchToShorthand(formula)
	string formula

	variable numSets, i
	string stimset, shorthand

	if(isEmpty(formula))
		return ""
	endif

	WAVE/T epochCombineList = GetWBEpochCombineList()

	numSets = DimSize(epochCombineList, ROWS)
	for(i = 0; i < numSets; i += 1)
		shorthand = epochCombineList[i][%Shorthand]
		stimset   = epochCombineList[i][%stimset]

		formula = ReplaceString(stimset + "?", formula, shorthand)
	endfor

	return formula
End

/// @brief Get all custom waves that are used by the supplied stimset.
///
/// used by WaveBuilder and NeuroDataWithoutBorders
///
/// @returns a wave of wave references
Function/WAVE WB_CustomWavesFromStimSet([stimsetList])
	string stimsetList

	variable i, j, numStimsets

	if(ParamIsDefault(stimsetList))
		WB_UpgradeCustomWaves()
		WAVE/T cw = WB_CustomWavesPathFromStimSet()
	else
		WB_UpgradeCustomWaves(stimsetList = stimsetList)
		WAVE/T cw = WB_CustomWavesPathFromStimSet(stimsetList = stimsetList)
	endif

	numStimSets = Dimsize(cw, ROWS)
	Make/FREE/WAVE/N=(numStimSets) wv

	for(i = 0; i < numStimSets; i += 1)
		WAVE/Z customwave = $cw[i]
		if(WaveExists(customwave))
			wv[j] = customwave
			j += 1
		else
			printf "reference to custom wave \"%s\" failed.\r", cw[i]
		endif
		WaveClear customwave
	endfor
	Redimension/N=(j) wv

	return wv
End

/// @brief Get all custom waves that are used by the supplied stimset.
///
/// @returns a text wave with paths to custom waves.
Function/WAVE WB_CustomWavesPathFromStimSet([stimsetList])
	string stimsetList

	variable numStimSets, i, j, k, numEpochs
	string stimset

	if(ParamIsDefault(stimsetList))
		numStimsets = 1
	else
		numStimsets = ItemsInList(stimsetList)
	endif

	Make/N=(numStimsets * SEGMENT_TYPE_WAVE_LAST_IDX)/FREE/T customWaves

	for(i = 0; i < numStimsets; i += 1)
		if(ParamIsDefault(stimsetList))
			WAVE/Z/T WPT     = GetWaveBuilderWaveTextParam()
			WAVE/Z SegWvType = GetSegmentTypeWave()
		else
			stimset = StringFromList(i, stimsetList)
			WAVE/Z/T WPT     = WB_GetWaveTextParamForSet(stimSet)
			WAVE/Z SegWvType = WB_GetSegWvTypeForSet(stimSet)
		endif

		if(!WaveExists(WPT) || !WaveExists(SegWvType))
			continue
		endif

		UpgradeSegWvType(SegWvType)
		UpgradeWaveTextParam(WPT)

		ASSERT(FindDimLabel(SegWvType, ROWS, "Total number of epochs") != -2, "SegWave Layout column not found. Check for changed DimLabels in SegWave!")
		numEpochs = SegWvType[%'Total number of epochs']
		for(j = 0; j < numEpochs; j += 1)
			if(SegWvType[j] == 7)
				customwaves[k] = WPT[0][j][EPOCH_TYPE_CUSTOM]
				k += 1
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
Function/WAVE WB_UpgradeCustomWaves([stimsetList])
	string stimsetList

	variable channelType, numStimsets, numEpochs, i, j
	string stimset

	if(ParamIsDefault(stimsetList))
		numStimsets = 1
	else
		numStimsets = ItemsInList(stimsetList)
	endif

	for(i = 0; i < numStimsets; i += 1)
		if(ParamIsDefault(stimsetList))
			WAVE/Z/T WPT     = GetWaveBuilderWaveTextParam()
			WAVE/Z SegWvType = GetSegmentTypeWave()
			channelType    = WBP_GetOutputType()
		else
			stimset = StringFromList(i, stimsetList)
			WAVE/Z/T WPT     = WB_GetWaveTextParamForSet(stimSet)
			WAVE/Z SegWvType = WB_GetSegWvTypeForSet(stimSet)
			channelType    = GetStimSetType(stimSet)
		endif

		if(!WaveExists(WPT) || !WaveExists(SegWvType))
			continue
		endif

		UpgradeSegWvType(SegWvType)
		UpgradeWaveTextParam(WPT)

		ASSERT(FindDimLabel(SegWvType, ROWS, "Total number of epochs") != -2, "SegWave Layout column not found. Check for changed DimLabels in SegWave!")
		numEpochs = SegWvType[%'Total number of epochs']
		for(j = 0; j < numEpochs; j += 1)
			if(SegWvType[j] == 7)
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
static Function/S WB_StimsetChildren([stimset])
	string stimset

	variable numEpochs, numStimsets, i, j
	string formula, regex, prefix, match, suffix
	string stimsets = ""

	if(ParamIsDefault(stimset))
		WAVE/Z WP        = GetWaveBuilderWaveParam()
		WAVE/Z/T WPT     = GetWaveBuilderWaveTextParam()
		WAVE/Z SegWvType = GetSegmentTypeWave()
	else
		if(!WB_ParameterWavesExist(stimset))
			// stimset without parameter waves has no dependencies
			return ""
		endif

		WAVE/Z WP        = WB_GetWaveParamForSet(stimSet)
		WAVE/Z/T WPT     = WB_GetWaveTextParamForSet(stimSet)
		WAVE/Z SegWvType = WB_GetSegWvTypeForSet(stimSet)
	endif

	ASSERT(WaveExists(WP) && WaveExists(WPT) && WaveExists(SegWvType), "Parameter Waves not found.")

	UpgradeSegWvType(SegWvType)
	ASSERT(FindDimLabel(SegWvType, ROWS, "Total number of epochs") != -2, "Dimension Label not found. Check for changed DimLabels in SegWave!")
	numEpochs = SegWvType[%'Total number of epochs']

	// search for stimsets in all formula-epochs by a regex pattern
	for(i = 0; i < numEpochs; i += 1)
		if(SegWvType[i] == 8)
			formula = WPT[6][i][EPOCH_TYPE_CUSTOM]
			numStimsets = CountSubstrings(formula, "?")
			for(j = 0; j < numStimsets; j += 1)
				WAVE/T/Z wv = SearchStringBase(formula, "(.*)\\b(\\w+)\\b\\?(.*)")
				ASSERT(WaveExists(wv), "Error in formula: could not properly resolve formula to stimset")
				formula = wv[0] + wv[2]
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
Function WB_StimsetFamilyNames(knownNames, [parent])
	string parent, &knownNames

	string children, familynames
	variable numChildren, i, numMoved

	// look for family members
	if(ParamIsDefault(parent))
		children = WB_StimsetChildren()
	else
		children = WB_StimsetChildren(stimset = parent)
	endif

	// unique names list with dependent children always left to their parents
	children = GetUniqueTextEntriesFromList(children, caseSensitive=0)
	knownNames = children + knownNames
	numMoved = ItemsInList(knownNames)
	knownNames = GetUniqueTextEntriesFromList(knownNames, caseSensitive=0)
	numMoved -= ItemsInList(knownNames)

	return numMoved
End

/// @brief Recursively descents into parent stimsets
///
/// You can not recurse into a stimset that depends on itself.
///
/// @return list of stimsets that derive from the input stimset
Function/S WB_StimsetRecursion([parent, knownStimsets])
	string parent, knownStimsets

	string stimset, stimsetQueue
	variable numStimsets, i, numBefore, numAfter, numMoved

	if(ParamIsDefault(knownStimsets))
		knownStimsets = ""
	endif

	numBefore = ItemsInList(knownStimsets)
	if(ParamIsDefault(parent))
		numMoved = WB_StimsetFamilyNames(knownStimsets)
		parent = ""
	else
		numMoved = WB_StimsetFamilyNames(knownStimsets, parent = parent)
	endif
	numAfter = ItemsInList(knownStimsets)

	// check recently added stimsets.
	// @todo: moved parent stimsets should not be checked again and therefore moved between child and parent.
	stimsetQueue = knownStimsets
	for(i = 0; i < numAfter - numBefore + numMoved; i += 1)
		stimset  = StringFromList(i, stimsetQueue)
		// avoid first order circle references.
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
Function/S WB_StimsetRecursionForList(stimsetQueue)
	string stimsetQueue

	variable i, numStimsets
	string stimset, stimsetList

	stimsetQueue = GetUniqueTextEntriesFromList(stimsetQueue, caseSensitive = 0)

	// loop through list
	numStimsets = ItemsInList(stimsetQueue)
	stimsetList = stimsetQueue
	for(i = 0; i < numStimsets; i += 1)
		stimset = StringFromList(i, stimsetQueue)
		stimsetList = WB_StimsetRecursion(parent = stimset, knownStimsets = stimsetList)
	endfor

	return stimsetList
End

/// @brief check if parameter waves exist
///
/// @return 1 if parameter waves exist, 0 otherwise
Function WB_ParameterWavesExist(stimset)
	string stimset

	WAVE/Z WP        = WB_GetWaveParamForSet(stimset)
	WAVE/Z/T WPT     = WB_GetWaveTextParamForSet(stimset)
	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(stimset)

	if(WaveExists(WP) && WaveExists(WPT) && WaveExists(SegWvType))
		return 1
	endif

	return 0
End

/// @brief check if (custom) stimset exists
///
/// @return 1 if stimset wave was found, 0 otherwise
Function WB_StimsetExists(stimset)
	string stimset

	DFREF setDFR = GetSetFolder(GetStimSetType(stimset))
	WAVE/Z/SDFR=setDFR wv = $stimset

	if(WaveExists(wv))
		return 1
	endif

	return 0
End

/// @brief Kill Parameter waves for stimset
Function WB_KillParameterWaves(stimset)
	string stimset

	WAVE/Z WP        = WB_GetWaveParamForSet(stimset)
	WAVE/Z/T WPT     = WB_GetWaveTextParamForSet(stimset)
	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(stimset)

	if(!WaveExists(WP) && !WaveExists(WPT) && !WaveExists(SegWvType))
		return 1
	endif

	KillOrMoveToTrash(wv=WP)
	KillOrMoveToTrash(wv=WPT)
	KillOrMoveToTrash(wv=SegWvType)

	return 1
End

/// @brief Kill (custom) stimset
Function WB_KillStimset(stimset)
   string stimset

   DFREF setDFR = GetSetFolder(GetStimSetType(stimset))
   WAVE/Z/SDFR=setDFR wv = $stimset

   if(!WaveExists(wv))
	   return 1
   endif

   KillOrMoveToTrash(wv=wv)

   return 1
End

/// @brief Determine if the stimset is third party or from MIES
///
/// Third party stimsets don't have all parameter waves
///
/// @return true if from third party, false otherwise
Function WB_StimsetIsFromThirdParty(stimset)
	string stimset

	ASSERT(!IsEmpty(stimset), "Stimset name can not be empty")

	WAVE/Z WP        = WB_GetWaveParamForSet(stimSet)
	WAVE/Z WPT       = WB_GetWaveTextParamForSet(stimSet)
	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(stimSet)

	return !WaveExists(WP) || !WaveExists(WPT) || !WaveExists(SegWvType)
End
