#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_CA
#endif

// #define CACHE_DEBUGGING

/// @file MIES_Cache.ipf
/// @brief __CA__ This file holds functions related to caching of waves.
///
/// The cache allows to store waves using a unique key for later retrieval.
/// The stored waves are kept until they are explicitly removed.
///
/// Usage:
/// * Write a key generator function returning a string
///   The parameters to CA_GenKey() must completely determine the wave you will later store.
///   The appended version string to the key allows you to invalidate old keys
///   if the algorithm creating the wave changes, but all input stays the same.
///
/// \rst
/// .. code-block:: igorpro
///
/// 	Function/S CA_GenKey(input)
/// 	    variable input
///
/// 	    return stringCRC(0, num2str(input)) + "Version 1"
/// 	End
/// \endrst
///
/// * Write your main function as in the following example. The first time
///   MyFancyCalculation(input) is called you get a cache miss and result has to
///   be created from scratch, but all subsequent calls are fast as the entry is
///   fetched from  the cache.
///
/// \rst
/// .. code-block:: igorpro
///
/// 	Function/WAVE MyFancyCalculation(input)
/// 	    variable input
///
/// 	    string key = CA_GenKey(input)
///
/// 	    WAVE/Z result = CA_TryFetchingEntryFromCache(key)
///
/// 	    if(WaveExists(result))
/// 	        return result
/// 	    endif
///
/// 	    // create result from scratch
/// 	    // ...
///
/// 	    CA_StoreEntryIntoCache(key, result)
///
/// 	    return result
/// 	End
/// \endrst
///
/// * Deleting cache entries has to be done *manually* via CA_DeleteCacheEntry().
///   The cache is also stored in a packed experiment.
///
/// * The entries in the cache are stored as free wave copies of what you feed into CA_StoreEntryIntoCache().
///   Similiary you get a free wave copy from CA_TryFetchingEntryFromCache().
///
/// * Storing 1D wave reference waves is supported, they are by default deep copied.

/// @name Cache key generators
/// @anchor CacheKeyGenerators
///@{

/// @brief Cache key generator for recreated epochs wave
Function/S CA_KeyRecreatedEpochs(WAVE numericalValues, WAVE/T textualValues, DFREF sweepDFR, variable sweepNo)

	variable crc

	// the calculation assumes that recreated epochs are based on an old LNB
	// thats content is treated as const (except mod time, as this check is fast)

	ASSERT_TS(!IsFreeWave(numericalValues), "Numerical LNB wave must be global")
	ASSERT_TS(!IsFreeWave(textualValues), "Textual LNB wave must be global")
	ASSERT_TS(!IsFreeDatafolder(sweepDFR), "sweepDFR must not be free")

	crc = StringCRC(0, GetWavesDataFolder(numericalValues, 2))
	crc = StringCRC(crc, num2istr(WaveModCountWrapper(numericalValues)))

	crc = StringCRC(crc, GetWavesDataFolder(textualValues, 2))
	crc = StringCRC(crc, num2istr(WaveModCountWrapper(textualValues)))

	crc = StringCRC(crc, GetDataFolder(1, sweepDFR))
	crc = StringCRC(crc, num2istr(sweepNo))
	crc = StringCRC(crc, num2istr(SWEEP_EPOCH_VERSION))

	return num2istr(crc) + "Version 1"
End

/// @brief Cache key generator for oodDAQ offset waves
Function/S CA_DistDAQCreateCacheKey(STRUCT OOdDAQParams &params)

	variable numWaves, crc, i

	numWaves = DimSize(params.stimSets, ROWS)

	crc = WaveCRC(0, params.setColumns)

	for(i = 0; i < numWaves; i += 1)
		crc = WaveCRC(crc, params.stimSets[i])
	endfor

	crc = StringCRC(crc, num2str(params.preFeaturePoints))
	crc = StringCRC(crc, num2str(params.postFeaturePoints))

	return num2istr(crc) + "Version 5"
End

/// @brief Cache key generator for @c FindLevel in PA_CalculatePulseTimes()
Function/S CA_PulseTimes(WAVE wv, string fullPath, variable channelNumber, variable totalOnsetDelay)

	variable crc

	crc = StringCRC(crc, num2istr(ModDate(wv)))
	crc = StringCRC(crc, num2istr(WaveModCountWrapper(wv)))
	crc = StringCRC(crc, fullPath)
	crc = StringCRC(crc, num2istr(channelNumber))
	crc = StringCRC(crc, num2str(totalOnsetDelay))

	return num2istr(crc) + "Version 2"
End

/// @brief Cache key generator for PA_SmoothDeconv()
///
/// @param wv               input wave (average)
/// @param smoothingFactor  smoothing factor
/// @param range_pnts       number of points (p) the smoothing was performed
Function/S CA_SmoothDeconv(WAVE wv, variable smoothingFactor, variable range_pnts)

	variable crc

	crc = WaveCRC(0, wv)
	crc = StringCRC(crc, num2str(DimDelta(wv, ROWS)))
	crc = StringCRC(crc, num2istr(smoothingFactor))
	crc = StringCRC(crc, num2istr(range_pnts))

	return num2istr(crc) + "Version 1"
End

/// @brief Cache key generator for PA_Deconvolution()
///
/// @param wv  input wave (smoothed average)
/// @param tau convolution time
Function/S CA_Deconv(WAVE wv, variable tau)

	variable crc

	crc = WaveCRC(0, wv)
	crc = StringCRC(crc, num2str(DimDelta(wv, ROWS)))
	crc = StringCRC(crc, num2str(tau))

	return num2istr(crc) + "Version 1"
End

/// @brief Cache key generator for GetActiveChannels
threadsafe Function/S CA_GenKeyGetActiveChannels(WAVE numericalValues, WAVE textualValues, variable sweepNo, variable channelType, variable TTLmode)

	string primitiveKey
	string version = "Version 1"
	variable crc

	sprintf primitiveKey, "%d_%d_%d_%s", sweepNo, channelType, TTLmode, version
	crc = CA_GetWaveModCRC(numericalValues, 0)
	crc = CA_GetWaveModCRC(textualValues, crc)
	crc = StringCRC(crc, primitiveKey)

	return num2istr(crc) + version
End

/// @brief Cache key generator for Logbook sortedKeyWave
threadsafe Function/S CA_GenKeyLogbookSortedKeys(WAVE keys)

	string version = "Version 1"
	variable crc

	crc = CA_GetWaveModCRC(keys, 0)

	return num2istr(crc) + version
End

/// @brief Cache key generator for artefact removal ranges
Function/S CA_ArtefactRemovalRangesKey(DFREF singleSweepDFR, variable sweepNo)

	variable crc

	crc = StringCRC(crc, GetDataFolder(1, singleSweepDFR))
	crc = StringCRC(crc, num2str(sweepNo))

	return num2istr(crc) + "Version 1"
End

/// @brief Cache key generator for averaging
Function/S CA_AveragingKey(WAVE/WAVE waveRefs)

	return CA_WaveCRCs(waveRefs, includeWaveScalingAndUnits = 1, dims = ROWS) + "Version 6"
End

/// @brief Cache key generator for averaging info from non-free waves
Function/S CA_AveragingWaveModKey(WAVE wv)

	return num2istr(CA_RecursiveWavemodCRC(wv)) + "Version 1"
End

/// @brief Calculated a CRC from non wave reference waves using modification data, wave modification count and wave location.
///        If the given wave is a wave reference wave, then the CRC is calculated recursively from
///        all non wave reference waves and null wave references found.
static Function CA_RecursiveWavemodCRC(WAVE/Z wv, [variable prevCRC])

	variable rows_, cols_, layers_, chunks_
	variable i, j, k, l

	prevCRC = ParamIsDefault(prevCRC) ? 0 : prevCRC

	if(!WaveExists(wv))
		// prevents getting the same key when the internal layout of the multi dimensional
		// wave reference wave changes due to additional null waves, while the sub set and order of
		// existing waves stays the same
		// e.g. original input:
		// w1, w2
		// w3, w4
		// new input:
		// null, null, null
		// null,   w1,   w2
		// null,   w3,   w4
		return StringCRC(prevCRC, "null wave")
	endif

	if(IsWaveRefWave(wv))
		WAVE/WAVE wvRef = wv

		rows_   = DimSize(wv, ROWS)
		cols_   = DimSize(wv, COLS)
		layers_ = DimSize(wv, LAYERS)
		chunks_ = DimSize(wv, CHUNKS)

		chunks_ = chunks_ ? chunks_ : 1
		layers_ = layers_ ? layers_ : 1
		cols_   = cols_ ? cols_ : 1

		for(l = 0; l < chunks_; l += 1)
			for(k = 0; k < layers_; k += 1)
				for(j = 0; j < cols_; j += 1)
					for(i = 0; i < rows_; i += 1)
						prevCRC = CA_RecursiveWavemodCRC(wvRef[i][j][k][l], prevCRC = prevCRC)
					endfor
				endfor
			endfor
		endfor
	else
		prevCRC = CA_GetWaveModCRC(wv, prevCRC)
	endif

	return prevCRC
End

threadsafe static Function CA_GetWaveModCRC(WAVE wv, variable crc)

	return StringCRC(crc, num2istr(ModDate(wv)) + num2istr(WaveModCountWrapper(wv)) + GetWavesDataFolder(wv, 2))
End

/// @brief Calculate the CRC of all metadata of all or the given dimension
threadsafe static Function CA_WaveScalingCRC(variable crc, WAVE wv, [variable dimension])

	variable dims, i

	if(ParamIsDefault(dimension))
		i    = 0
		dims = WaveDims(wv)
	else
		ASSERT_TS(dimension >= ROWS && dimension <= CHUNKS, "Invalid dimension")

		i    = dimension
		dims = dimension + 1
	endif

	for(i = 0; i < dims; i += 1)
		crc = StringCRC(crc, num2str(DimSize(wv, dimension)))
		crc = StringCRC(crc, num2str(DimOffset(wv, dimension)))
		crc = StringCRC(crc, num2str(DimDelta(wv, dimension)))
		crc = StringCRC(crc, WaveUnits(wv, dimension))
	endfor

	return crc
End

/// @brief Calculate all CRC values of the waves referenced in waveRefs
///
/// @param waveRefs                   wave reference wave
/// @param crcMode                    [optional] parameter to WaveCRC
/// @param includeWaveScalingAndUnits [optional] include the wave scaling and units of filled dimensions
/// @param dims                       [optional] number of dimensions to include wave scaling and units in crc
static Function/S CA_WaveCRCs(WAVE/WAVE waveRefs, [variable crcMode, variable includeWaveScalingAndUnits, variable dims])

	variable rows

	if(ParamIsDefault(crcMode))
		crcMode = 0
	endif

	if(ParamIsDefault(includeWaveScalingAndUnits))
		includeWaveScalingAndUnits = 0
	else
		includeWaveScalingAndUnits = !!includeWaveScalingAndUnits
		if(ParamIsDefault(dims))
			dims = ROWS
		endif
	endif

	rows = DimSize(waveRefs, ROWS)
	ASSERT(rows > 0, "Unexpected number of entries")

	Make/D/FREE/N=(rows) crc
	MultiThread/NT=(rows < NUM_ENTRIES_FOR_MULTITHREAD) crc[] = WaveCRC(0, waveRefs[p], crcMode)

	if(includeWaveScalingAndUnits)
		MultiThread/NT=(rows < NUM_ENTRIES_FOR_MULTITHREAD) crc[] = CA_WaveScalingCRC(crc[p], waveRefs[p])
	endif

	return NumericWaveToList(crc, ";", format = "%.15g")
End

/// @brief Calculate the cache key for SI_FindMatchingTableEntry.
///
/// We are deliberatly not using a WaveCRC here as know that the wave is not
/// changed in IP once loaded. Therefore using its name and ModDate is enough.
Function/S CA_SamplingIntervalKey(WAVE lut, STRUCT ActiveChannels &s)

	variable crc

	crc = StringCRC(crc, num2istr(s.numDARack1))
	crc = StringCRC(crc, num2istr(s.numADRack1))
	crc = StringCRC(crc, num2istr(s.numTTLRack1))
	crc = StringCRC(crc, num2istr(s.numDARack2))
	crc = StringCRC(crc, num2istr(s.numADRack2))
	crc = StringCRC(crc, num2istr(s.numTTLRack2))

	ASSERT(!IsFreeWave(lut), "lut can not be a free wave")
	return num2istr(crc) + NameOfWave(lut) + num2istr(ModDate(lut)) + "Version 1"
End

/// @brief Generic key generator for storing throw away waves used for
///        Multithread assignments
///
/// Only the size is relevant, the rest is undefined.
threadsafe Function/S CA_TemporaryWaveKey(WAVE dims)

	variable numRows, crc, i

	numRows = DimSize(dims, ROWS)
	ASSERT_TS(numRows > 0 && numRows <= MAX_DIMENSION_COUNT && DimSize(dims, COLS) <= 1, "Invalid dims dimensions")

	for(i = 0; i < numRows; i += 1)
		crc = StringCRC(crc, num2istr(dims[i]))
	endfor

	return num2istr(crc) + "Temporary waves Version 2"
End

/// @brief Calculate the cache key for the hardware device info wave
Function/S CA_HWDeviceInfoKey(string device, variable hardwareType, variable deviceID)

	variable crc

	crc = StringCrc(crc, device)
	crc = StringCrc(crc, num2str(hardwareType))
	crc = StringCrc(crc, num2str(deviceID))

	return num2istr(crc) + "HW Device Info Version 1"
End

/// @brief Generate a key for the DAQDataWave in TEST_PULSE_MODE
///
/// Properties which influence the Testpulse:
/// - hardwareType
/// - numDA (filled columns)
/// - numActiveChannels (number of columns)
/// - number of rows, return from DC_CalculateDAQDataWaveLength(device, TEST_PULSE_MODE)
/// - samplingInterval
/// - DAGain
/// - DACAmp[][%TPAmp] column
/// - testPulseLength, baselineFrac
Function/S CA_HardwareDataTPKey(STRUCT HardwareDataTPInput &s)

	variable crc

	crc = StringCRC(crc, num2str(s.hardwareType))
	crc = StringCRC(crc, num2str(s.numDACs))
	crc = StringCRC(crc, num2str(s.numActiveChannels))
	crc = StringCRC(crc, num2str(s.numberOfRows))
	crc = StringCRC(crc, num2str(s.samplingInterval))
	crc = WaveCRC(crc, s.gains)
	crc = WaveCRC(crc, s.DACAmpTP)
	crc = StringCRC(crc, num2str(s.testPulseLength))
	crc = StringCRC(crc, num2str(s.baselineFrac))

	return num2istr(crc) + "HW Datawave Testpulse Version 2"
End

Function/S CA_PSXKernelOperationKey(variable riseTau, variable decayTau, variable amp, variable numPoints, variable dt, WAVE range)

	variable crc

	crc = StringCRC(crc, num2strHighPrec(riseTau, precision = MAX_DOUBLE_PRECISION))
	crc = StringCRC(crc, num2strHighPrec(decayTau, precision = MAX_DOUBLE_PRECISION))
	crc = StringCRC(crc, num2strHighPrec(amp, precision = MAX_DOUBLE_PRECISION))
	crc = StringCRC(crc, num2strHighPrec(numPoints, precision = MAX_DOUBLE_PRECISION))
	crc = StringCRC(crc, num2strHighPrec(dt, precision = MAX_DOUBLE_PRECISION))
	crc = WaveCRC(crc, range)

	return num2istr(crc) + "PSX Kernel Version 2"
End

static Function/S CA_PSXBaseKey(string comboKey, string psxParameters)

	ASSERT(!IsEmpty(comboKey), "Invalid comboKey")
	ASSERT(!IsEmpty(psxParameters), "Invalid psxParameters")

	return comboKey + Hash(psxParameters, HASH_SHA2_256)
End

/// @brief Generate the key for the cache and the results wave for psxEvent
///        data of the `psx` SweepFormula operation
///
/// @param comboKey      combination key, see PSX_GenerateComboKey()
/// @param psxParameters JSON dump of the psx/psxKernel operation parameters
Function/S CA_PSXEventsKey(string comboKey, string psxParameters)

	return CA_PSXBaseKey(comboKey, psxParameters) + " Events " + ":Version 2"
End

Function/S CA_PSXOperationKey(string comboKey, string psxParameters)

	return CA_PSXBaseKey(comboKey, psxParameters) + " Operation " + ":Version 2"
End

Function/S CA_PSXRiseTimeKey(string comboKey, string psxParameters)

	return CA_PSXBaseKey(comboKey, psxParameters) + " PSX Rise time " + ":Version 2"
End

Function/S CA_PSXAnalyzePeaks(string comboKey, string psxParameters)

	return CA_PSXBaseKey(comboKey, psxParameters) + " Analyze Peaks " + ":Version 2"
End

/// @brief Return the key for the igor info entries
threadsafe Function/S CA_IgorInfoKey(variable selector)

	string key

	// only add new selectors if their output is fixed for the current IP session
	switch(selector)
		case 0: // fallthrough-by-design
		case 3:
			sprintf key, "IgorInfo(%d):Version 1", selector
			return key
		default:
			ASSERT_TS(0, "Unimplemented selector")
	endswitch
End

/// @brief Return the key for the filled labnotebook parameter names
Function/S CA_GetLabnotebookNamesKey(WAVE/Z/T textualValues, WAVE/Z/T numericalValues)

	string key = ""
	variable crc

	if(WaveExists(textualValues))
		key += GetWavesDataFolder(textualValues, 2)
		key += num2istr(WaveModCountWrapper(textualValues))
	endif

	if(WaveExists(numericalValues))
		key += GetWavesDataFolder(numericalValues, 2)
		key += num2istr(WaveModCountWrapper(numericalValues))
	endif

	ASSERT(!IsEmpty(key), "key can't be empty")

	return "Version 1:" + Hash(key, HASH_SHA2_256)
End

///@}

/// @brief Make space for one new entry in the cache waves
///
/// @return index into cache waves
threadsafe static Function CA_MakeSpaceForNewEntry()

	variable index

	WAVE/T    keys   = GetCacheKeyWave()
	WAVE/WAVE values = GetCacheValueWave()
	WAVE      stats  = GetCacheStatsWave()

	index = GetNumberFromWaveNote(keys, NOTE_INDEX)
	ASSERT_TS(index == GetNumberFromWaveNote(values, NOTE_INDEX), "Mismatched indizes in key and value waves")

	EnsureLargeEnoughWave(keys, dimension = ROWS, indexShouldExist = index)
	EnsureLargeEnoughWave(values, dimension = ROWS, indexShouldExist = index)
	EnsureLargeEnoughWave(stats, dimension = ROWS, indexShouldExist = index, initialValue = NaN)
	ASSERT_TS(DimSize(keys, ROWS) == DimSize(values, ROWS), "Mismatched row sizes")
	ASSERT_TS(DimSize(stats, ROWS) == DimSize(values, ROWS), "Mismatched row sizes")

	SetNumberInWaveNote(keys, NOTE_INDEX, index + 1)
	SetNumberInWaveNote(values, NOTE_INDEX, index + 1)
	SetNumberInWaveNote(stats, NOTE_INDEX, index + 1)

	return index
End

/// @brief Add a new entry into the cache
///
/// @param key     string which uniquely identifies the cached wave
/// @param val     wave to store
/// @param options [optional, defaults to none] One or multiple constants from
///                @ref CacheFetchOptions
///
/// Existing entries with the same key are overwritten.
threadsafe Function CA_StoreEntryIntoCache(string key, WAVE val, [variable options])

	variable index, storeDuplicate, foundIndex

#ifdef WAVECACHE_DISABLED
	return NaN
#endif

	if(ParamIsDefault(options))
		storeDuplicate = 1
	else
		storeDuplicate = !(options & CA_OPTS_NO_DUPLICATE)
	endif

	WAVE/T    keys   = GetCacheKeyWave()
	WAVE/WAVE values = GetCacheValueWave()
	WAVE      stats  = GetCacheStatsWave()

	foundIndex = CA_GetCacheIndex(keys, key)

	if(IsNaN(foundIndex))
		index = CA_MakeSpaceForNewEntry()
	else
		index = foundIndex
	endif

	if(storeDuplicate)
		if(IsWaveRefWave(val))
			WAVE waveToStore = DeepCopyWaveRefWave(val)
		else
			Duplicate/FREE val, waveToStore
		endif
	else
		WAVE waveToStore = val
	endif

	values[index] = waveToStore
	keys[index]   = key

	stats[index][]                       = 0
	stats[index][%Misses]               += 1
	stats[index][%Size]                  = GetWaveSize(val, recursive = 1)
	stats[index][%ModificationTimestamp] = DateTimeInUTC()
End

/// @brief Return the index of the entry `key`
///
/// @return non-negative number or `NaN` if it could not be found.
///
/// UTF_NOINSTRUMENTATION
threadsafe static Function CA_GetCacheIndex(WAVE keys, string key)

	variable numFilledRows

	numFilledRows = GetNumberFromWaveNote(keys, NOTE_INDEX) - 1

	ASSERT_TS(!isEmpty(key), "Cache key can not be empty")

	if(numFilledRows <= 0)
		return NaN
	endif

	FindValue/TXOP=4/TEXT=key/RMD=[0, numFilledRows] keys

	return V_Value == -1 ? NaN : V_Value
End

/// @brief Try to fetch the wave stored under key from the cache
///
/// @param key     string which uniquely identifies the cached wave
/// @param options [optional, defaults to none] One or multiple constants from
///                @ref CacheFetchOptions
///
/// @return A wave reference with the stored data or a invalid wave reference
/// if nothing could be found.
threadsafe Function/WAVE CA_TryFetchingEntryFromCache(string key, [variable options])

	variable index, returnDuplicate

#ifdef WAVECACHE_DISABLED
	return $""
#endif

	if(ParamIsDefault(options))
		returnDuplicate = 1
	else
		returnDuplicate = !(options & CA_OPTS_NO_DUPLICATE)
	endif

	WAVE/T keys = GetCacheKeyWave()

	index = CA_GetCacheIndex(keys, key)

	if(!IsFinite(index))
#ifdef CACHE_DEBUGGING
		DEBUGPRINT_TS("Could not find a cache entry for key=", str = key)
#endif
		return $""
	endif

	WAVE/WAVE values = GetCacheValueWave()

	ASSERT_TS(index < DimSize(values, ROWS), "Invalid index")
	WAVE/Z cache = values[index]

	if(!WaveExists(cache))
#ifdef CACHE_DEBUGGING
		DEBUGPRINT_TS("Could not find a valid wave for key=", str = key)
#endif
		// invalidate cache entry due to non existent wave,
		// this can happen for unpacked experiments which don't store free waves
		keys[index] = ""
		return $""
	endif

	WAVE stats = GetCacheStatsWave()
	stats[index][%Hits] += 1

#ifdef CACHE_DEBUGGING
	DEBUGPRINT_TS("Found cache entry for key=", str = key)
#endif

	if(returnDuplicate)
		if(IsWaveRefWave(cache))
			WAVE wv = DeepCopyWaveRefWave(cache)
		else
			Duplicate/FREE cache, wv
		endif
	else
		WAVE wv = cache
	endif

	return wv
End

/// @brief Try to delete a cache entry
///
/// @return One if it could be found and deleted, zero otherwise
Function CA_DeleteCacheEntry(string key)

	WAVE/T keys = GetCacheKeyWave()

	variable index = CA_GetCacheIndex(keys, key)

	if(!IsFinite(index))
		return 0
	endif

	WAVE/WAVE values = GetCacheValueWave()
	WAVE      stats  = GetCacheStatsWave()

	ASSERT(index < DimSize(values, ROWS) && index < DimSize(keys, ROWS), "Invalid index")

	// does currently not reset `NOTE_INDEX`
	keys[index]   = ""
	values[index] = $""
	stats[index]  = NaN

	return 1
End

/// @brief Remove all entries from the wave cache
Function CA_FlushCache()

	KillOrMoveToTrash(wv = GetCacheKeyWave())
	KillOrMoveToTrash(wv = GetCacheValueWave())
	KillOrMoveToTrash(wv = GetCacheStatsWave())
End

/// @brief Output cache statistics
Function CA_OutputCacheStatistics()

	variable index, i

	WAVE stats = GetCacheStatsWave()
	index = GetNumberFromWaveNote(stats, NOTE_INDEX)

	printf "Number of entries: %d\r", index

	printf "\r"
	printf "%s   | %s | %s | %s (MB)\r", GetDimLabel(stats, COLS, 0), GetDimLabel(stats, COLS, 1), GetDimLabel(stats, COLS, 2), GetDimLabel(stats, COLS, 3)
	printf "---------------------------------------------------\r"

	for(i = 0; i < index; i += 1)
		printf "%6d | %6d | %s  | %6d\r", stats[i][%Hits], stats[i][%Misses], GetISO8601TimeStamp(secondsSinceIgorEpoch = stats[i][%ModificationTimestamp], numFracSecondsDigits = 3), stats[i][%Size] / 1024 / 1024
	endfor

	printf "\r"

	ControlWindowToFront()
End
