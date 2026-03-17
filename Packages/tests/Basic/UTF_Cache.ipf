#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = CacheTest

static Function CheckCacheWaves(variable idx)

	CHECK_GE_VAR(idx, 0)
	CHECK(IsFinite(idx))
	CHECK(IsInteger(idx))

	WAVE values = GetCacheValueWave()
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(values, NOTE_INDEX), idx)

	WAVE stats = GetCacheStatsWave()
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(stats, NOTE_INDEX), idx)
End

static Function NoMatchWhenEmpty()

	string key = "abcd"

	WAVE/Z result = CA_TryFetchingEntryFromCache(key)
	CHECK_WAVE(result, NULL_WAVE)
End

static Function AssertOnEmptyKey()

	try
		CA_StoreEntryIntoCache("", {0})
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	try
		CA_TryFetchingEntryFromCache("")
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	try
		CA_DeleteCacheEntry("")
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

static Function TestAddFetch()

	string key = "abcd"

	Make/FREE val = p

	CheckCacheWaves(0)
	CA_StoreEntryIntoCache(key, val)
	CheckCacheWaves(1)

	WAVE/Z result = CA_TryFetchingEntryFromCache(key)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, val)
	// returned wave is a copy by default
	CHECK(!WaveRefsEqual(result, val))

	// and now we overwrite it
	Make/FREE valOv = p^2
	CA_StoreEntryIntoCache(key, valOv)
	CheckCacheWaves(1)

	WAVE/Z result = CA_TryFetchingEntryFromCache(key)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, valOv)
	CHECK(!WaveRefsEqual(result, valOv))
End

static Function TestAddFetchNoDuplicate()

	string key = "abcd"

	Make/FREE val = p

	// but we can also request the wave itself
	CA_StoreEntryIntoCache(key, val, options = CA_OPTS_NO_DUPLICATE)

	WAVE/Z result = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, val)
	CHECK(WaveRefsEqual(result, val))
End

static Function TestAddFetchWaveRefWave()

	string key = "abcd"

	Make/FREE val = p
	Make/FREE/WAVE cont = {val}

	CA_StoreEntryIntoCache(key, cont)

	WAVE/Z/WAVE resultCont = CA_TryFetchingEntryFromCache(key)
	CHECK_WAVE(resultCont, WAVE_WAVE)
	WAVE/Z result = resultCont[0]
	CHECK_EQUAL_WAVES(result, val)
	// returned wave is a copy by default
	CHECK(!WaveRefsEqual(result, val))
End

static Function TestAddFetchWaveRefWaveNoDuplicate()

	string key = "abcd"

	Make/FREE val = p
	Make/FREE/WAVE cont = {val}

	CA_StoreEntryIntoCache(key, cont, options = CA_OPTS_NO_DUPLICATE)

	WAVE/Z/WAVE resultCont = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)
	CHECK(WaveRefsEqual(resultCont, cont))
	CHECK_WAVE(resultCont, WAVE_WAVE)
	WAVE/Z result = resultCont[0]
	CHECK_EQUAL_WAVES(result, val)
	CHECK(WaveRefsEqual(result, val))
End

static Function KeyIsCaseSensitive()

	string key = "abcd"

	Make/FREE val = p

	CA_StoreEntryIntoCache(key, val)
	WAVE/Z result = CA_TryFetchingEntryFromCache(UpperStr(key))
	CHECK_WAVE(result, NULL_WAVE)
End

// UTF_TD_GENERATOR DataGenerators#CacheOptions
static Function NullEntriesCanBeStored([variable opts])

	variable found, ret

	string key = "abcd"

	CheckCacheWaves(0)
	CA_StoreEntryIntoCache(key, $"")
	CheckCacheWaves(1)

	// still an invalid wave reference with the old API
	WAVE/Z result = CA_TryFetchingEntryFromCache(key, options = opts)
	CHECK_WAVE(result, NULL_WAVE)

	// but with the new we can query that
	[WAVE result, found] = CA_TryFetchingEntryFromCacheWithNull(key, options = opts)
	CHECK_WAVE(result, NULL_WAVE)
	CHECK_EQUAL_VAR(found, 1)

	// deleting works as well
	ret = CA_DeleteCacheEntry(key)
	CHECK_EQUAL_VAR(ret, 1)

	// and now it is really gone
	[WAVE result, found] = CA_TryFetchingEntryFromCacheWithNull(key, options = opts)
	CHECK_WAVE(result, NULL_WAVE)
	CHECK_EQUAL_VAR(found, 0)
End

static Function DeletingEntriesWorks()

	variable ret
	string key = "abcd"

	Make/FREE val = p

	CheckCacheWaves(0)
	CA_StoreEntryIntoCache(key, val)
	CheckCacheWaves(1)

	ret = CA_DeleteCacheEntry(key)
	CHECK_EQUAL_VAR(ret, 1)
	// NOTE_INDEX is not touched
	CheckCacheWaves(1)

	WAVE/Z result = CA_TryFetchingEntryFromCache(key)
	CHECK_WAVE(result, NULL_WAVE)

	// entry is no more
	ret = CA_DeleteCacheEntry(key)
	CHECK_EQUAL_VAR(ret, 0)
End

static Function FlushingCacheRemovesEntries()

	variable ret
	string key = "abcd"

	Make/FREE val = p

	CA_StoreEntryIntoCache(key, val)

	CA_FlushCache()
	WAVE/Z result = CA_TryFetchingEntryFromCache(key)
	CHECK_WAVE(result, NULL_WAVE)
End

static Function StatisticsWork()

	variable ret, ref
	string key, hist

	key = "abcd"

	Make/FREE val = p
	CA_StoreEntryIntoCache(key, val)

	WAVE stats = GetCacheStatsWave()
	CHECK_EQUAL_VAR(DimSize(stats, COLS), 4)

	CHECK_EQUAL_VAR(stats[0][%Hits], 0)
	CHECK_EQUAL_VAR(stats[0][%Misses], 1)
	CHECK_GT_VAR(stats[0][%ModificationTimestamp], 0)
	CHECK_EQUAL_VAR(stats[0][%Size], 1160)

	WAVE/Z result = CA_TryFetchingEntryFromCache(key)
	CHECK_WAVE(result, NUMERIC_WAVE)

	CHECK_EQUAL_VAR(stats[0][%Hits], 1)
	CHECK_EQUAL_VAR(stats[0][%Misses], 1)
	CHECK_GT_VAR(stats[0][%ModificationTimestamp], 0)
	CHECK_EQUAL_VAR(stats[0][%Size], 1160)

	ref = CaptureHistoryStart()
	CA_OutputCacheStatistics()
	hist = CaptureHistory(ref, 1)
	CHECK_PROPER_STR(hist)
End

Function UpgradePathWithEmptyKeys()

	DFREF dfr = GetCacheFolder()
	Make/T/N=(MINIMUM_WAVE_SIZE) dfr:keys/WAVE=keys_old
	SetNumberInWaveNote(keys_old, NOTE_INDEX, 0)

	WAVE keys_new = GetCacheKeyHashMap()
	CHECK_WAVE(keys_old, NULL_WAVE)

	WAVE/Z result = MIES_HM#HM_GetFilledEntries(keys_new)
	CHECK_WAVE(result, NULL_WAVE)
End

Function UpgradePathWithFilledKeys()

	variable found, value

	DFREF dfr = GetCacheFolder()
	Make/T/N=(MINIMUM_WAVE_SIZE) dfr:keys/WAVE=keys_old
	SetNumberInWaveNote(keys_old, NOTE_INDEX, 11)

	keys_old[0] = "abcd"
	// holes are allowed
	keys_old[10] = "efgh"

	WAVE keys_new = GetCacheKeyHashMap()
	CHECK_WAVE(keys_old, NULL_WAVE)

	WAVE/Z result = MIES_HM#HM_GetFilledEntries(keys_new)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(result, ROWS), 2)

	[value, found] = HM_GetEntryAsNumber(keys_new, "abcd")
	CHECK(found)
	CHECK_EQUAL_VAR(value, 0)

	[value, found] = HM_GetEntryAsNumber(keys_new, "efgh")
	CHECK(found)
	CHECK_EQUAL_VAR(value, 10)
End

static Function/WAVE GetModCounts(WAVE keys, WAVE values, WAVE stats)

	Make/FREE/N=(3) modCounts = {WaveModCountWrapper(keys), WaveModCountWrapper(values), WaveModCountWrapper(stats)}

	return modCounts
End

Function CompactificationWorks()

	string key        = "someKey"
	string hitlessKey = "anotherKey"
	string randomKey  = "abcd"

	Make/FREE val = p

	// does nothing for empty cache
	WAVE/WAVE keys   = GetCacheKeyHashMap()
	WAVE/WAVE values = GetCacheValueWave()
	WAVE      stats  = GetCacheStatsWave()

	CheckCacheWaves(0)

	WAVE modCountsBefore = GetModCounts(keys, values, stats)
	CA_Compactify()
	WAVE modCountsAfter = GetModCounts(keys, values, stats)
	CHECK_EQUAL_WAVES(modCountsBefore, modCountsAfter)

	WAVE modCountsBefore = GetModCounts(keys, values, stats)

	CheckCacheWaves(0)
	CA_StoreEntryIntoCache(key, val)
	CheckCacheWaves(1)

	// fetch it so that it has a hit
	WAVE/Z result = CA_TryFetchingEntryFromCache(key)
	CHECK_EQUAL_WAVES(val, result)

	CA_Compactify()

	CheckCacheWaves(1)

	// refetch the waves
	WAVE/WAVE keys   = GetCacheKeyHashMap()
	WAVE/WAVE values = GetCacheValueWave()
	WAVE      stats  = GetCacheStatsWave()

	WAVE modCountsAfter = GetModCounts(keys, values, stats)

	// hashmap did not change
	CHECK_EQUAL_VAR(modCountsAfter[0], modCountsBefore[0])
	CHECK_GT_VAR(modCountsAfter[1], modCountsBefore[1])
	CHECK_GT_VAR(modCountsAfter[2], modCountsBefore[2])

	// and we can still find our value
	WAVE/Z result = CA_TryFetchingEntryFromCache(key)
	CHECK_EQUAL_WAVES(val, result)

	// entries without hits are thrown away
	CA_StoreEntryIntoCache(hitlessKey, val)
	CheckCacheWaves(2)
	CA_Compactify()
	CheckCacheWaves(1)

	WAVE/Z result = CA_TryFetchingEntryFromCache(hitlessKey)
	CHECK_WAVE(result, NULL_WAVE)

	// and holes are also plugged
	CA_StoreEntryIntoCache(randomKey, val)

	WAVE/Z result = CA_TryFetchingEntryFromCache(randomKey)
	CHECK_EQUAL_WAVES(val, result)
	CheckCacheWaves(2)

	CA_StoreEntryIntoCache(hitlessKey, val)
	CheckCacheWaves(3)

	// key
	// randomKey
	// hitlessKey

	CA_DeleteCacheEntry(key)
	// NOTE_INDEX was not yet touched
	CheckCacheWaves(3)
	CA_Compactify()
	// but now
	CheckCacheWaves(1)
End
