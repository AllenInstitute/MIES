#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_CA
#endif

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
/// @{

/// @brief Cache key generator for oodDAQ offset waves
Function/S CA_DistDAQCreateCacheKey(params)
	STRUCT OOdDAQParams &params

	variable numWaves, crc, i

	numWaves = DimSize(params.stimSets, ROWS)

	crc = WaveCRC(0, params.setColumns)

	for(i = 0; i < numWaves; i += 1)
		crc = WaveCRC(crc, params.stimSets[i])
	endfor

	crc = StringCRC(crc, num2str(params.preFeaturePoints))
	crc = StringCRC(crc, num2str(params.postFeaturePoints))
	crc = StringCRC(crc, num2str(params.resolution))

	if(WaveExists(params.preload))
		crc = WaveCRC(crc, params.preload)
	endif

	return num2istr(crc) + "Version 2"
End

/// @brief Cache key generator for artefact removal ranges
Function/S CA_ArtefactRemovalRangesKey(singleSweepDFR, sweepNo)
	DFREF singleSweepDFR
	variable sweepNo

	variable crc

	crc = StringCRC(crc, GetDataFolder(1, singleSweepDFR))
	crc = StringCRC(crc, num2str(sweepNo))

	return num2istr(crc) + "Version 1"
End

/// @brief Cache key generator for testpulse waves
Function/S CA_TestPulseMultiDeviceKey(testpulseLengthInPoints, baselineFraction)
	variable testpulseLengthInPoints, baselineFraction

	variable crc

	crc = StringCRC(crc, num2str(testpulseLengthInPoints))
	crc = StringCRC(crc, num2str(baselineFraction))

	return num2istr(crc) + "Version 1"
End

/// @brief Cache key generator for multi device testpulse ITCDataWave
Function/S CA_ITCDataWaveTestPulseMD(waveRefs, ITCDataWave)
	WAVE/WAVE waveRefs
	WAVE ITCDataWave

	variable crc

	crc = CA_WaveScalingCRC(crc, ITCDataWave, ROWS)
	crc = CA_WaveScalingCRC(crc, ITCDataWave, COLS)

	return CA_WaveCRCs(waveRefs) + num2istr(crc) + "Version 1"
End

/// @brief Cache key generator for averaging
Function/S CA_AveragingKey(waveRefs)
	WAVE/WAVE waveRefs

	return CA_WaveCRCs(waveRefs, crcMode=2) + "Version 2"
End

/// @brief Calculate the CRC of all metadata of a dimension
static Function CA_WaveScalingCRC(crc, wv, dimension)
	variable crc
	WAVE wv
	variable dimension

	ASSERT(dimension >= ROWS && dimension <= CHUNKS, "Invalid dimension")

	crc = StringCRC(crc, num2str(DimSize(wv, dimension)))
	crc = StringCRC(crc, num2str(DimOffset(wv, dimension)))
	crc = StringCRC(crc, num2str(DimDelta(wv, dimension)))
	crc = StringCRC(crc, WaveUnits(wv, dimension))

	return crc
End

/// @brief Calculate all CRC values of the waves referenced in waveRefs
///
/// @param waveRefs  wave reference wave
/// @param crcMode   parameter to WaveCRC
static Function/S CA_WaveCRCs(waveRefs, [crcMode])
	WAVE/WAVE waveRefs
	variable crcMode

	variable rows

	if(ParamIsDefault(crcMode))
		crcMode = 0
	endif

	rows = DimSize(waveRefs, ROWS)
	ASSERT(rows > 0, "Unexpected number of entries")

	if(rows < NUM_ENTRIES_FOR_MULTITHREAD)
		Make/D/FREE/N=(rows) crc = WaveCRC(0, waveRefs[p], crcMode)
	else

		Make/D/FREE/N=(rows) crc
		MultiThread crc[] = WaveCRC(0, waveRefs[p], crcMode)
	endif

	return NumericWaveToList(crc, ";", format = "%d")
End

/// @}

/// @brief Make space for one new entry in the cache waves
///
/// @return index into cache waves
static Function CA_MakeSpaceForNewEntry()

	variable index

	WAVE/T keys      = GetCacheKeyWave()
	WAVE/WAVE values = GetCacheValueWave()
	WAVE stats       = GetCacheStatsWave()

	index = GetNumberFromWaveNote(keys, NOTE_INDEX)
	ASSERT(index == GetNumberFromWaveNote(values, NOTE_INDEX), "Mismatched indizes in key and value waves")

	EnsureLargeEnoughWave(keys, dimension=ROWS, minimumSize=index)
	EnsureLargeEnoughWave(values, dimension=ROWS, minimumSize=index)
	EnsureLargeEnoughWave(stats, dimension=ROWS, minimumSize=index, initialValue = NaN)
	ASSERT(DimSize(keys, ROWS) == DimSize(values, ROWS), "Mismatched row sizes")
	ASSERT(DimSize(stats, ROWS) == DimSize(values, ROWS), "Mismatched row sizes")

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
Function CA_StoreEntryIntoCache(key, val, [options])
	string key
	WAVE val
	variable options

	variable index, storeDuplicate

	if(ParamIsDefault(options))
		storeDuplicate = 1
	else
		storeDuplicate = !(options & CA_OPTS_NO_DUPLICATE)
	endif

	ASSERT(!IsEmpty(key), "Key must not be empty")

	WAVE/T keys      = GetCacheKeyWave()
	WAVE/WAVE values = GetCacheValueWave()
	WAVE stats       = GetCacheStatsWave()

	FindValue/TEXT=key/TXOP=4 keys
	if(V_Value == -1)
		index = CA_MakeSpaceForNewEntry()
	else
		index = V_Value
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
	stats[index][%Size]                  = GetWaveSize(val, recursive=1)
	stats[index][%ModificationTimestamp] = DateTimeInUTC()
End

/// @brief Return the index of the entry `key`
///
/// @return non-negative number or `NaN` if it could not be found.
static Function CA_GetCacheIndex(key)
	string key

	ASSERT(!isEmpty(key), "Cache key can not be empty")

	WAVE/T keys = GetCacheKeyWave()
	FindValue/TXOP=4/TEXT=key keys

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
Function/WAVE CA_TryFetchingEntryFromCache(key, [options])
	string key
	variable options

	variable index, returnDuplicate

	if(ParamIsDefault(options))
		returnDuplicate = 1
	else
		returnDuplicate = !(options & CA_OPTS_NO_DUPLICATE)
	endif

	index = CA_GetCacheIndex(key)

	if(!IsFinite(index))
		DEBUGPRINT("Could not find a cache entry for key=", str=key)
		return $""
	endif

	WAVE/T keys      = GetCacheKeyWave()
	WAVE/WAVE values = GetCacheValueWave()
	WAVE stats       = GetCacheStatsWave()

	ASSERT(index < DimSize(values, ROWS), "Invalid index")
	WAVE/Z cache = values[index]

	if(!WaveExists(cache))
		DEBUGPRINT("Could not find a valid wave for key=", str=key)
		// invalidate cache entry due to non existent wave,
		// this can happen for unpacked experiments which don't store free waves
		keys[index] = ""
		return $""
	endif

	stats[index][%Hits] += 1
	DEBUGPRINT("Found cache entry for key=", str=key)

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
Function CA_DeleteCacheEntry(key)
	string key

	variable index = CA_GetCacheIndex(key)

	WAVE/T keys      = GetCacheKeyWave()
	WAVE/WAVE values = GetCacheValueWave()
	WAVE stats       = GetCacheStatsWave()

	if(!IsFinite(index))
		return 0
	else
		ASSERT(index < DimSize(values, ROWS) && index < DimSize(keys, ROWS), "Invalid index")
		// does currently not reset `NOTE_INDEX`
		keys[index]   = ""
		values[index] = $""
		stats[index]  = NaN
		return 1
	endif
End

/// @brief Remove all entries from the wave cache
Function CA_FlushCache()

	KillOrMoveToTrash(wv=GetCacheKeyWave())
	KillOrMoveToTrash(wv=GetCacheValueWave())
	KillOrMoveToTrash(wv=GetCacheStatsWave())
End

/// @brief Output cache statistics
Function CA_OutputCacheStatistics()

	variable index, i

	WAVE stats = GetCacheStatsWave()
	index = GetNumberFromWaveNote(stats, NOTE_INDEX)

	printf "\r"
	printf "%s   | %s | %s | %s (MB)\r",  GetDimLabel(stats, COLS, 0), GetDimLabel(stats, COLS, 1), GetDimLabel(stats, COLS, 2), GetDimLabel(stats, COLS, 3)
	printf "---------------------------------------------------\r"

	for(i = 0; i < index; i += 1)
		printf "%6d | %6d | %s  | %6d\r", stats[i][%Hits] , stats[i][%Misses], GetISO8601TimeStamp(secondsSinceIgorEpoch=stats[i][%ModificationTimestamp]), stats[i][%Size] / 1024 / 1024
	endfor

	printf "\r"

	ControlWindowToFront()
End
