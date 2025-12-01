#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_CA
#endif // AUTOMATED_TESTING

// #define CACHE_DEBUGGING

/// @file MIES_Cache.ipf
/// @brief __CA__ This file holds functions related to caching of waves.
///
/// The cache allows to store waves using a unique key for later retrieval.
/// The stored waves are kept until they are explicitly removed.
///
/// Usage:
/// * Write a key generator function returning a string
///   The parameters to CA_GenerateKeyFancyCalc() must completely determine the wave you will later store.
///   The appended version string to the key allows you to invalidate old keys
///   if the algorithm creating the wave changes, but all input stays the same.
///
/// \rst
/// .. code-block:: igorpro
///
/// 	Function/S CA_GenerateKeyFancyCalc(string input)
///
/// 	    return HashString("", input) + ":FancyCalc:Version 1"
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
/// 	Function/WAVE MyFancyCalculation(string input)
///
/// 	    string key = CA_GenerateKeyFancyCalc(input)
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
///   The cache is also stored in a experiment file.
///
/// * The entries in the cache are stored as free wave copies of what you feed into CA_StoreEntryIntoCache().
///   Similiary you get a free wave copy from CA_TryFetchingEntryFromCache().
///
/// * Storing 1D wave reference waves is supported, they are by default deep copied.

/// @name Cache key generators
/// @anchor CacheKeyGenerators
///@{

Function/S CA_MiesVersionKey()

	return "MIES Version: Version 1"
End

Function/S CA_DACDevicesKey(variable hardwareType)

	string str

	sprintf str, "DAC Devices %s: Version 1", StringFromList(hardwareType, HARDWARE_DAC_TYPES)

	return str
End

Function/S CA_AmplifierHardwareWavesKey()

	return "Amplifier hardware waves: Version 1"
End

/// @brief Cache key generator for recreated epochs wave
Function/S CA_KeyRecreatedEpochs(WAVE numericalValues, WAVE/T textualValues, DFREF sweepDFR, variable sweepNo)

	string hv = ""

	// the calculation assumes that recreated epochs are based on an old LNB
	// thats content is treated as const (except mod time, as this check is fast)

	ASSERT_TS(!IsFreeWave(numericalValues), "Numerical LNB wave must be global")
	ASSERT_TS(!IsFreeWave(textualValues), "Textual LNB wave must be global")
	ASSERT_TS(!IsFreeDatafolder(sweepDFR), "sweepDFR must not be free")

	hv = HashString(hv, GetWavesDataFolder(numericalValues, 2))
	hv = HashNumber(hv, WaveModCountWrapper(numericalValues))

	hv = HashString(hv, GetWavesDataFolder(textualValues, 2))
	hv = HashNumber(hv, WaveModCountWrapper(textualValues))

	hv = HashString(hv, GetDataFolder(1, sweepDFR))
	hv = HashNumber(hv, sweepNo)
	hv = HashNumber(hv, SWEEP_EPOCH_VERSION)

	return hv + ":Version 1"
End

/// @brief Cache key generator for oodDAQ offset waves
Function/S CA_DistDAQCreateCacheKey(STRUCT OOdDAQParams &params)

	variable numWaves, i
	string hv = ""

	numWaves = DimSize(params.stimSets, ROWS)

	hv = HashWave(hv, params.setColumns)

	for(i = 0; i < numWaves; i += 1)
		hv = HashWave(hv, params.stimSets[i])
	endfor

	hv = HashNumber(hv, params.preFeaturePoints)
	hv = HashNumber(hv, params.postFeaturePoints)

	return hv + ":Version 5"
End

/// @brief Cache key generator for @c FindLevel in PA_CalculatePulseTimes()
Function/S CA_PulseTimes(WAVE wv, string fullPath, variable channelNumber, variable totalOnsetDelay)

	string hv = ""

	hv = HashNumber(hv, ModDate(wv))
	hv = HashNumber(hv, WaveModCountWrapper(wv))
	hv = HashString(hv, fullPath)
	hv = HashNumber(hv, channelNumber)
	hv = HashNumber(hv, totalOnsetDelay)

	return hv + ":Version 2"
End

/// @brief Cache key generator for PA_SmoothDeconv()
///
/// @param wv               input wave (average)
/// @param smoothingFactor  smoothing factor
/// @param range_pnts       number of points (p) the smoothing was performed
Function/S CA_SmoothDeconv(WAVE wv, variable smoothingFactor, variable range_pnts)

	string hv = ""

	hv = HashWave(hv, wv)
	hv = HashNumber(hv, DimDelta(wv, ROWS))
	hv = HashNumber(hv, smoothingFactor)
	hv = HashNumber(hv, range_pnts)

	return hv + ":Version 1"
End

/// @brief Cache key generator for PA_Deconvolution()
///
/// @param wv  input wave (smoothed average)
/// @param tau convolution time
Function/S CA_Deconv(WAVE wv, variable tau)

	string hv = ""

	hv = HashWave(hv, wv)
	hv = HashNumber(hv, DimDelta(wv, ROWS))
	hv = HashNumber(hv, tau)

	return hv + ":Version 1"
End

/// @brief Cache key generator for GetActiveChannels
threadsafe Function/S CA_GenKeyGetActiveChannels(WAVE numericalValues, WAVE textualValues, variable sweepNo, variable channelType, variable TTLmode)

	string primitiveKey
	string version = ":Version 1"
	string hv      = ""

	sprintf primitiveKey, "%d_%d_%d_%s", sweepNo, channelType, TTLmode, version
	hv = CA_GetWaveModHash(numericalValues, hv)
	hv = CA_GetWaveModHash(textualValues, hv)
	hv = HashString(hv, primitiveKey)

	return hv + version
End

/// @brief Cache key generator for LBN index cache
threadsafe Function/S CA_CreateLBIndexCacheKey(WAVE values)

	string name = GetWavesDataFolder(values, 2)
	ASSERT_TS(!isEmpty(name), "Invalid path to wave, free waves won't work.")

	return name + "_IndexCache"
End

/// @brief Cache key generator for LBN row cache
threadsafe Function/S CA_CreateLBRowCacheKey(WAVE values)

	string name = GetWavesDataFolder(values, 2)
	ASSERT_TS(!isEmpty(name), "Invalid path to wave, free waves won't work.")

	return name + "_RowCache"
End

/// @brief Cache key generator for Logbook sortedKeyWave
threadsafe Function/S CA_GenKeyLogbookSortedKeys(WAVE keys)

	string hv = ""

	hv = CA_GetWaveModHash(keys, hv)

	return hv + ":Version 1"
End

/// @brief Cache key generator for artefact removal ranges
Function/S CA_ArtefactRemovalRangesKey(DFREF singleSweepDFR, variable sweepNo)

	string hv = ""

	hv = HashString(hv, GetDataFolder(1, singleSweepDFR))
	hv = HashNumber(hv, sweepNo)

	return hv + ":Version 1"
End

/// @brief Cache key generator for averaging
Function/S CA_AveragingKey(WAVE/WAVE waveRefs)

	return CA_WaveHash(waveRefs, includeWaveScalingAndUnits = 1, dims = ROWS) + ":Version 6"
End

/// @brief Cache key generator for averaging info from non-free waves
Function/S CA_AveragingWaveModKey(WAVE wv)

	return CA_RecursiveWaveModHash(wv) + ":Version 1"
End

/// @brief Cache key generator for the tau range calculation
///        of psx events
Function/S CA_PSXEventGoodTauRange(WAVE wv)

	return CA_RecursiveWaveModHash(wv) + ":Version 1"
End

/// @brief Calculated a hash from non wave reference waves using modification data, wave modification count and wave location.
///        If the given wave is a wave reference wave, then the hash is calculated recursively from
///        all non wave reference waves and null wave references found.
static Function/S CA_RecursiveWaveModHash(WAVE/Z wv, [string prevHash])

	variable rows_, cols_, layers_, chunks_
	variable i, j, k, l

	if(ParamIsDefault(prevHash))
		prevHash = ""
	endif

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
		return HashString(prevHash, "null wave")
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
						prevHash = CA_RecursiveWaveModHash(wvRef[i][j][k][l], prevHash = prevHash)
					endfor
				endfor
			endfor
		endfor
	else
		prevHash = CA_GetWaveModHash(wv, prevHash)
	endif

	return prevHash
End

threadsafe static Function/S CA_GetWaveModHash(WAVE wv, string hv)

	hv = HashNumber(hv, ModDate(wv))
	hv = HashNumber(hv, WaveModCountWrapper(wv))
	hv = HashString(hv, GetWavesDataFolder(wv, 2))

	return hv
End

/// @brief Calculate the hash of all metadata of all dimensions or the given only
threadsafe static Function/S CA_WaveScalingHash(string hv, WAVE wv, [variable dimension])

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
		hv = HashNumber(hv, DimSize(wv, dimension))
		hv = HashNumber(hv, DimOffset(wv, dimension))
		hv = HashNumber(hv, DimDelta(wv, dimension))
		hv = HashString(hv, WaveUnits(wv, dimension))
	endfor

	return hv
End

/// @brief Calculate hash values of the wave `dims` giving the dimensions of a wave
threadsafe static Function/S CA_WaveSizeHash(WAVE dims)

	variable numRows, i
	string hv = ""

	numRows = DimSize(dims, ROWS)
	ASSERT_TS(numRows > 0 && numRows <= MAX_DIMENSION_COUNT && DimSize(dims, COLS) <= 1, "Invalid dims dimensions")

	for(i = 0; i < numRows; i += 1)
		hv = HashNumber(hv, dims[i])
	endfor

	return hv
End

/// @brief Calculate all hash values of the waves referenced in waveRefs
///
/// @param waveRefs                   wave reference wave
/// @param includeWaveScalingAndUnits [optional] include the wave scaling and units of filled dimensions
/// @param dims                       [optional] number of dimensions to include wave scaling and units in hash
static Function/S CA_WaveHash(WAVE/WAVE waveRefs, [variable includeWaveScalingAndUnits, variable dims])

	variable rows

	ASSERT(IsWaveRefWave(waveRefs), "Expected a wave reference wave")

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

	Make/T/FREE/N=(rows) hashes
	MultiThread/NT=(rows < NUM_ENTRIES_FOR_MULTITHREAD) hashes[] = HashWave("", waveRefs[p])

	if(includeWaveScalingAndUnits)
		MultiThread/NT=(rows < NUM_ENTRIES_FOR_MULTITHREAD) hashes[] = CA_WaveScalingHash(hashes[p], waveRefs[p], dimension = dims)
	endif

	return HashWave("", hashes)
End

/// @brief Calculate the cache key for SI_FindMatchingTableEntry.
///
/// We are deliberatly not using a HashWave here as know that the wave is not
/// changed in IP once loaded. Therefore using its name and ModDate is enough.
Function/S CA_SamplingIntervalKey(WAVE lut, STRUCT ActiveChannels &s)

	string hv = ""

	hv = HashNumber(hv, s.numDARack1)
	hv = HashNumber(hv, s.numADRack1)
	hv = HashNumber(hv, s.numTTLRack1)
	hv = HashNumber(hv, s.numDARack2)
	hv = HashNumber(hv, s.numADRack2)
	hv = HashNumber(hv, s.numTTLRack2)

	ASSERT(!IsFreeWave(lut), "lut can not be a free wave")
	hv = HashString(hv, NameOfWave(lut))
	hv = HashNumber(hv, ModDate(lut))

	return hv + ":Version 1"
End

/// @brief Generic key generator for storing throw away waves used for
///        Multithread assignments
///
/// Only the size is relevant, the rest is undefined.
threadsafe Function/S CA_TemporaryWaveKey(WAVE dims)

	string hv = ""

	hv = CA_WaveSizeHash(dims)

	return hv + "Temporary waves Version 2"
End

/// @brief Key generator for FindIndizes
threadsafe Function/S CA_FindIndizesKey(WAVE dims)

	string hv

	hv = CA_WaveSizeHash(dims)

	return hv + "FindIndizes Version 1"
End

/// @brief Calculate the cache key for the hardware device info wave
Function/S CA_HWDeviceInfoKey(string device, variable hardwareType, variable deviceID)

	string hv = ""

	hv = HashString(hv, device)
	hv = HashNumber(hv, hardwareType)
	hv = HashNumber(hv, deviceID)

	return hv + ":HW Device Info Version 1"
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

	string hv = ""

	hv = HashNumber(hv, s.hardwareType)
	hv = HashNumber(hv, s.numDACs)
	hv = HashNumber(hv, s.numActiveChannels)
	hv = HashNumber(hv, s.numberOfRows)
	hv = HashNumber(hv, s.samplingInterval)
	hv = HashWave(hv, s.gains)
	hv = HashWave(hv, s.DACAmpTP)
	hv = HashNumber(hv, s.testPulseLength)
	hv = HashNumber(hv, s.baselineFrac)

	return hv + "HW Datawave Testpulse Version 2"
End

Function/S CA_PSXKernelOperationKey(variable riseTau, variable decayTau, variable amp, variable numPoints, variable dt, WAVE range)

	string hv = ""

	hv = HashString(hv, num2strHighPrec(riseTau, precision = MAX_DOUBLE_PRECISION))
	hv = HashString(hv, num2strHighPrec(decayTau, precision = MAX_DOUBLE_PRECISION))
	hv = HashString(hv, num2strHighPrec(amp, precision = MAX_DOUBLE_PRECISION))
	hv = HashString(hv, num2strHighPrec(numPoints, precision = MAX_DOUBLE_PRECISION))
	hv = HashString(hv, num2strHighPrec(dt, precision = MAX_DOUBLE_PRECISION))
	hv = HashWave(hv, range)

	return hv + "PSX Kernel Version 2"
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

	return CA_PSXBaseKey(comboKey, psxParameters) + " Operation " + ":Version 3"
End

Function/S CA_PSXAnalyzePeaks(string comboKey, string psxParameters)

	return CA_PSXBaseKey(comboKey, psxParameters) + " Analyze Peaks " + ":Version 2"
End

/// @brief Return the key for the igor info entries
threadsafe Function/S CA_IgorInfoKey(variable selector)

	string key

	// only add new selectors if their output is fixed for the current IP session
	switch(selector)
		case 0: // fallthrough
		case 3:
			sprintf key, "IgorInfo(%d):Version 1", selector
			return key
		default:
			FATAL_ERROR("Unimplemented selector")
	endswitch
End

/// @brief Return the key for the filled labnotebook parameter names
threadsafe Function/S CA_GetLabnotebookNamesKey(WAVE/Z/T textualValues, WAVE/Z/T numericalValues)

	string key = ""

	if(WaveExists(textualValues))
		key += GetWavesDataFolder(textualValues, 2)
		key += num2istr(WaveModCountWrapper(textualValues))
	endif

	if(WaveExists(numericalValues))
		key += GetWavesDataFolder(numericalValues, 2)
		key += num2istr(WaveModCountWrapper(numericalValues))
	endif

	return HashString("", key) + ":Version 1"
End

Function/S CA_CalculateEpochsKey(WAVE numericalvalues, WAVE textualValues, variable sweepNo, variable channelType, variable channelNumber, string shortName, variable treelevel, DFREF sweepDFR)

	string hv

	hv = CA_GetLabnotebookNamesKey(numericalvalues, textualValues)
	hv = HashNumber(hv, sweepNo)
	hv = HashNumber(hv, channelType)
	hv = HashNumber(hv, channelNumber)
	hv = HashString(hv, shortName)
	hv = HashNumber(hv, treelevel)

	if(DataFolderExistsDFR(sweepDFR))
		hv = HashString(hv, GetDataFolder(1, sweepDFR))
	else
		hv = HashString(hv, "invalid DFREF")
	endif

	return hv + ":Version 1"
End

threadsafe Function/S CA_CalculateFetchEpochsKey(WAVE numericalvalues, WAVE textualValues, variable sweepNo, variable channelNumber, variable channelType)

	string hv = ""

	hv = HashString(hv, CA_GetLabnotebookNamesKey(numericalvalues, textualValues))
	hv = HashNumber(hv, sweepNo)
	hv = HashNumber(hv, channelType)
	hv = HashNumber(hv, channelNumber)

	return hv + ":Version 1"
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
threadsafe Function CA_StoreEntryIntoCache(string key, WAVE/Z val, [variable options])

	variable index, storeDuplicate, foundIndex

#ifdef WAVECACHE_DISABLED
	return NaN
#endif // WAVECACHE_DISABLED

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

	if(storeDuplicate && WaveExists(val))
		if(IsWaveRefWave(val))
			WAVE waveToStore = DeepCopyWaveRefWave(val)
		else
			Duplicate/FREE val, waveToStore
		endif
	else
		WAVE/Z waveToStore = val
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

	numFilledRows = GetNumberFromWaveNote(keys, NOTE_INDEX)

	ASSERT_TS(!isEmpty(key), "Cache key can not be empty")

	if(numFilledRows <= 0)
		return NaN
	endif

	FindValue/TXOP=(1 + 4)/TEXT=key keys

	return (V_Value == -1) ? NaN : V_Value
End

/// @brief Try to fetch the wave stored under key from the cache
///
/// @param key     string which uniquely identifies the cached wave
/// @param options [optional, defaults to none] One or multiple constants from
///                @ref CacheFetchOptions
///
/// Prefer CA_TryFetchingEntryFromCacheWithNull if you stored an invalid wave
/// reference and need to query that.
///
/// @return wave reference with stored data or an invalid wave reference.
threadsafe Function/WAVE CA_TryFetchingEntryFromCache(string key, [variable options])

	variable found

	if(ParamIsDefault(options))
		[WAVE entry, found] = CA_TryFetchingEntryFromCacheWithNull(key)
	else
		[WAVE entry, found] = CA_TryFetchingEntryFromCacheWithNull(key, options = options)
	endif

	return entry
End

/// @brief Try to fetch the wave stored under key from the cache
///
/// @param key     string which uniquely identifies the cached wave
/// @param options [optional, defaults to none] One or multiple constants from
///                @ref CacheFetchOptions
///
/// @retval entry wave reference with the stored data or an invalid wave reference
/// @retval found true/false value if something could be found. Allows to distinguish no match from null wave stored.
threadsafe Function [WAVE entry, variable found] CA_TryFetchingEntryFromCacheWithNull(string key, [variable options])

	variable index, returnDuplicate

#ifdef WAVECACHE_DISABLED
	return [$"", 0]
#endif // WAVECACHE_DISABLED

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
#endif // CACHE_DEBUGGING
		return [$"", 0]
	endif

	WAVE/WAVE values = GetCacheValueWave()

	WAVE/Z cache = values[index]

	WAVE stats = GetCacheStatsWave()
	stats[index][%Hits] += 1

#ifdef CACHE_DEBUGGING
	DEBUGPRINT_TS("Found cache entry for key=", str = key)
#endif // CACHE_DEBUGGING

	if(returnDuplicate && WaveExists(cache))
		if(IsWaveRefWave(cache))
			WAVE wv = DeepCopyWaveRefWave(cache)
		else
			Duplicate/FREE cache, wv
		endif
	else
		WAVE/Z wv = cache
	endif

	return [wv, 1]
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

	KillOrMoveToTrash(dfr = GetCacheFolder())
End

/// @brief Output cache statistics
Function CA_OutputCacheStatistics()

	variable index, i, size

	WAVE stats = GetCacheStatsWave()
	index = GetNumberFromWaveNote(stats, NOTE_INDEX)

	printf "Number of entries: %d\r", index

	printf "\r"
	printf "%s  | %s  | %s | %s     | %s (MB)\r", "Index", GetDimLabel(stats, COLS, 0), GetDimLabel(stats, COLS, 1), GetDimLabel(stats, COLS, 2), GetDimLabel(stats, COLS, 3)
	printf "----------------------------------------------------------------\r"

	for(i = 0; i < index; i += 1)
		size = stats[i][%Size] / 1024 / 1024
		size = (size == 0) ? 0 : max(1, size)
		printf "%6d |%6d | %6d | %s  | %6d\r", i, stats[i][%Hits], stats[i][%Misses], GetISO8601TimeStamp(secondsSinceIgorEpoch = stats[i][%ModificationTimestamp], numFracSecondsDigits = 3), size
	endfor

	printf "\r"

	ControlWindowToFront()
End
