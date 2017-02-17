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
/// @code
/// Function/S CA_GenKey(input)
///     variable input
///
///     return stringCRC(0, num2str(input)) + "Version 1"
/// End
/// @endcode
///
/// * Write your main function as in the following example. The first time
///   MyFancyCalculation(input) is called you get a cache miss and result has to
///   be created from scratch, but all subsequent calls are fast as the entry is
///   fetched from  the cache.
/// @code
/// Function/WAVE MyFancyCalculation(input)
///     variable input
///
///     string key = CA_GenKey(input)
///
///     WAVE/Z result = CA_TryFetchingEntryFromCache(key)
///
///     if(WaveExists(result))
///         return result
///     endif
///
///     // create result from scratch
///     // ...
///
///     CA_StoreEntryIntoCache(key, result)
///
///     return result
/// End
/// @endcode
///
/// * Deleting cache entries has to be done *manually* via CA_DeleteCacheEntry().
///   The cache is also stored in a packed experiment.
///
/// * The entries in the cache are stored as free wave copies of what you feed into CA_StoreEntryIntoCache().
///   Similiary you get a free wave copy from CA_TryFetchingEntryFromCache().

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

	return num2istr(crc) + "Version 1"
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

/// @}

/// @brief Make space for one new entry in the cache waves
///
/// @return index into cache waves
static Function CA_MakeSpaceForNewEntry()

	variable index

	WAVE/T keys      = GetCacheKeyWave()
	WAVE/WAVE values = GetCacheValueWave()

	index = GetNumberFromWaveNote(keys, NOTE_INDEX)
	ASSERT(index == GetNumberFromWaveNote(values, NOTE_INDEX), "Mismatched indizes in key and value waves")

	EnsureLargeEnoughWave(keys, dimension=ROWS, minimumSize=index)
	EnsureLargeEnoughWave(values, dimension=ROWS, minimumSize=index)
	ASSERT(DimSize(keys, ROWS) == DimSize(values, ROWS), "Mismatched row sizes")

	SetNumberInWaveNote(keys, NOTE_INDEX, index + 1)
	SetNumberInWaveNote(values, NOTE_INDEX, index + 1)

	return index
End

/// @brief Add a new entry into the cache
///
/// Existing entries with the same key are overwritten.
Function CA_StoreEntryIntoCache(key, val)
	string key
	WAVE val

	variable index

	ASSERT(!IsEmpty(key), "Key must not be empty")

	WAVE/T keys      = GetCacheKeyWave()
	WAVE/WAVE values = GetCacheValueWave()

	FindValue/TEXT=key/TXOP=4 keys
	if(V_Value == -1)
		index = CA_MakeSpaceForNewEntry()
	else
		index = V_Value
	endif

	Duplicate/FREE val, valCopy

	values[index] = valCopy
	keys[index]   = key
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
/// @return A wave reference with the stored data or a invalid wave reference
/// if nothing could be found.
Function/WAVE CA_TryFetchingEntryFromCache(key)
	string key

	variable index = CA_GetCacheIndex(key)

	WAVE/T keys      = GetCacheKeyWave()
	WAVE/WAVE values = GetCacheValueWave()

	if(!IsFinite(index))
		DEBUGPRINT("Could not find a cache entry for key=", str=key)
		return $""
	else
		ASSERT(index < DimSize(values, ROWS), "Invalid index")
		WAVE/Z cache = values[index]

		if(!WaveExists(cache))
			DEBUGPRINT("Could not find a valid wave for key=", str=key)
			// invalidate cache entry due to non existent wave,
			// this can happen for unpacked experiments which don't store free waves
			keys[index] = ""
			return $""
		endif

		Duplicate/FREE cache, wv
		DEBUGPRINT("Found cache entry for key=", str=key)
		return wv
	endif
End

/// @brief Try to delete a cache entry
///
/// @return One if it could be found and deleted, zero otherwise
Function CA_DeleteCacheEntry(key)
	string key

	variable index = CA_GetCacheIndex(key)

	WAVE/T keys      = GetCacheKeyWave()
	WAVE/WAVE values = GetCacheValueWave()

	if(!IsFinite(index))
		return 0
	else
		ASSERT(index < DimSize(values, ROWS) && index < DimSize(keys, ROWS), "Invalid index")
		// does currently not reset `NOTE_INDEX`
		keys[index]   = ""
		values[index] = $""
		return 1
	endif
End

/// @brief Remove all entries from the wave cache
Function CA_FlushCache()

	KillOrMoveToTrash(wv=GetCacheKeyWave())
	KillOrMoveToTrash(wv=GetCacheValueWave())
End
