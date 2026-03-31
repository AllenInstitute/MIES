#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = HashmapTest

//Reference values from godbolt.org with
//#include <iostream>
//
//unsigned long hash(unsigned char *str)
//{
//    unsigned long hash = 5381;
//    int c;
//
//    while (c = *str++)
//        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
//
//    return hash;
//}
//
//int main(int argc, char** argv)
//{
//    std::string str = "aaaaaaaaaaaaaaaaaaaaaaaaaa";
//
//    std::cout << hash(str.data()) << std::endl;
//
//    str = "a";
//
//    std::cout << hash(str.data()) << std::endl;
//
//}
static Function TestDJBHash()

	uint64 result

	[result] = MIES_HM#HM_DJBHash("")
	CHECK_EQUAL_UINT64(result, 5381)

	[result] = MIES_HM#HM_DJBHash("a")
	CHECK_EQUAL_UINT64(result, 177670)

	// embedded nulls, so this is different than plain a
	[result] = MIES_HM#HM_DJBHash("a\x00")
	CHECK_EQUAL_UINT64(result, 5863110)

	// check signedness
	[result] = MIES_HM#HM_DJBHash("ä")
	CHECK_EQUAL_UINT64(result, 5866508)

	// and overflow
	[result] = MIES_HM#HM_DJBHash("ääääääääääääääääääääääääääääääääääääääääääääääääääääääääääääääääääääääääääääääääääääääääääää")
	CHECK_EQUAL_UINT64(result, 17309477878133240073)

	[result] = MIES_HM#HM_DJBHash("aaaaaaaaaaaaaaaaaaaaaaaaaa")
	CHECK_EQUAL_UINT64(result, 9992975210972501951)
End

static Function TestHashKey()

	WAVE/WAVE wv = HM_Create()

	CHECK_EQUAL_VAR(21974, MIES_HM#HM_HashKey(wv, "adfadffffffffffffffffffffffffffffffffffffffffffffaaaaaaaaaaaaaaaaaaaaaaaaa"))
End

static Function CreateHashmapWorks()

	WAVE/WAVE hashmap = HM_Create()
	CHECK_WAVE(hashmap, WAVE_WAVE)

	WAVE/WAVE hashmap_impl = hashmap[1]

	// hashmap implementation
	// verify sizes
	CHECK_EQUAL_VAR(DimSize(hashmap_impl, ROWS), 2^16)
	CHECK_EQUAL_VAR(DimSize(hashmap_impl, COLS), 2)

	// verify contained waves
	CHECK_WAVE(hashmap_impl[0][0], TEXT_WAVE)
	CHECK_WAVE(hashmap_impl[0][1], TEXT_WAVE)

	// management waves
	WAVE/WAVE mgmt = hashmap[0]
	CHECK_WAVE(mgmt, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(mgmt, ROWS), 2)

	CHECK_WAVE(mgmt[0], NUMERIC_WAVE, minorType = IGOR_TYPE_UNSIGNED | IGOR_TYPE_32BIT_INT)
	CHECK_WAVE(mgmt[1], NUMERIC_WAVE, minorType = IGOR_TYPE_64BIT_FLOAT)

	// bails with invalid size
	try
		HM_Create(size = 3)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

/// @brief Return the indizes into hashmap with one or more key/value pairs
///
/// Complexity: O(n)
static Function/WAVE GetFilledEntries(WAVE/WAVE hashmap)

	variable numThreads, numPossibleEntries

	numPossibleEntries = MIES_HM#HM_GetSize(hashmap)

	numThreads = GetNumberOfUsefulThreads({numPossibleEntries})

	WAVE usedRows = MIES_HM#HM_FetchUsedRows(hashmap)

	// not using GetTemporaryWave here to avoid issues with recursion
	Make/FREE/N=(numPossibleEntries) matches

	Multithread/NT=(numThreads) matches = usedRows[p] ? p : NaN

	WAVE/Z result = ZapNaNs(matches)

	return result
End

static Function CheckHashmapEntry(WAVE/WAVE hashmap, variable index, variable usedEntries, WAVE/T keys, WAVE/T values)

	[WAVE usedRows, WAVE/T keysRef, WAVE valuesRef] = MIES_HM#HM_FetchWaves(hashmap, index)

	// used entries in keys/values
	CHECK_EQUAL_VAR(usedRows[index], usedEntries)

	// and it is the first one in keys
	INFO("keys: @%s", s = keysRef)
	CHECK_EQUAL_TEXTWAVES(keysRef, keys, mode = WAVE_DATA)

	// and values
	INFO("values: @%s", s = valuesRef)
	CHECK_EQUAL_TEXTWAVES(valuesRef, values, mode = WAVE_DATA)
End

static Function AddEntryWorks()

	string key, value
	variable ret

	WAVE hashmap = HM_Create()

	WAVE/Z result = GetFilledEntries(hashmap)
	CHECK_WAVE(result, NULL_WAVE)

	// adding first value
	key   = "7314"
	value = "efgh"
	ret   = HM_AddEntry(hashmap, key, str = value)
	CHECK_EQUAL_VAR(ret, 1)

	WAVE/Z result = GetFilledEntries(hashmap)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, {6100}, mode = WAVE_DATA)

	CheckHashmapEntry(hashmap, result[0], 1, {key, ""}, {value, ""})

	// overwrite the same value again
	ret = HM_AddEntry(hashmap, key, str = value)
	CHECK_EQUAL_VAR(ret, 0)

	WAVE/Z result = GetFilledEntries(hashmap)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, {6100}, mode = WAVE_DATA)

	CheckHashmapEntry(hashmap, result[0], 1, {key, ""}, {value, ""})

	// write new value with the same index
	// Found via
	// •FindCollision_IGNORE(6100)
	// dup[0] = {7314,57289,71869}
	ret = HM_AddEntry(hashmap, "57289", str = "ijkl")
	CHECK_EQUAL_VAR(ret, 1)

	WAVE/Z result = GetFilledEntries(hashmap)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, {6100}, mode = WAVE_DATA)

	CheckHashmapEntry(hashmap, result[0], 2, {key, "57289"}, {value, "ijkl"})

	// add yet another collision, this time keys and values is resized
	ret = HM_AddEntry(hashmap, "71869", str = "mnop")
	CHECK_EQUAL_VAR(ret, 1)

	WAVE/Z result = GetFilledEntries(hashmap)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, {6100}, mode = WAVE_DATA)

	CheckHashmapEntry(hashmap, result[0], 3, {key, "57289", "71869", ""}, {value, "ijkl", "mnop", ""})

	try
		HM_AddEntry(hashmap, "abcd")
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

Function FindCollision_IGNORE(variable value, [variable size])

	if(ParamIsDefault(size))
		WAVE hashmap = HM_Create()
	else
		WAVE hashmap = HM_Create(size = size)
	endif

	Make/FREE/N=(5 * DimSize(hashmap, ROWS)) hashes, values = p

	Multithread hashes = (MIES_HM#HM_HashKey(hashmap, num2str(values[p])) == value) ? p : NaN

	WAVE/Z result = ZapNaNs(hashes)

	print result
End

#if IgorVersion() >= 10

static Function GetKeyIndexWorks()

	// check both code paths in HM_GetKeyIndex
	variable numEntries = MIES_HM#HM_SMALL_WAVE_OPTIMIZATION_ROWS * 10 // NOLINT

	Make/FREE/T/N=(numEntries) keys = num2str(p)

	Make/FREE/N=(numEntries) values = p
	Make/FREE/N=(numEntries) result

	result[] = MIES_HM#HM_GetKeyIndex(keys, keys[p], p + 1)

	CHECK_EQUAL_WAVES(result, values)

	// check that we are not looking beyond the filled entries
	keys[Inf] = ""
	CHECK_EQUAL_VAR(MIES_HM#HM_GetKeyIndex(keys, "", numEntries - 1), NaN)
	CHECK_EQUAL_VAR(MIES_HM#HM_GetKeyIndex(keys, "", numEntries), numEntries - 1)
End

#endif

static Function GetEntryWorks()

	string key, value, result
	variable found, valueVar

	WAVE hashmap = HM_Create()

	// adding first value
	key   = "7314"
	value = "efgh"
	HM_AddEntry(hashmap, key, str = value)

	[result, found] = HM_GetEntryAsString(hashmap, key)

	CHECK_EQUAL_VAR(found, 1)
	CHECK_EQUAL_STR(result, value)

	// unknown key
	[result, found] = HM_GetEntryAsString(hashmap, "I_DONT_EXIST")

	CHECK_EQUAL_VAR(found, 0)
	CHECK_EQUAL_STR(result, "")

	// can store and retrieve empty value
	key   = ""
	value = ""
	HM_AddEntry(hashmap, key, str = value)

	[result, found] = HM_GetEntryAsString(hashmap, key)

	CHECK_EQUAL_VAR(found, 1)
	CHECK_EQUAL_STR(result, "")

	// returned key is from a collision, see AddEntryWorks()
	key   = "57289"
	value = "ijkl"
	HM_AddEntry(hashmap, key, str = value)

	[result, found] = HM_GetEntryAsString(hashmap, key)

	CHECK_EQUAL_VAR(found, 1)
	CHECK_EQUAL_STR(result, value)

	try
		[valueVar, found] = HM_GetEntryAsNumber(hashmap, key)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

static Function DeleteEntryWorks()

	string key, value, result
	variable found, ret

	WAVE hashmap = HM_Create()

	// adding first value
	key   = "7314"
	value = "efgh"
	HM_AddEntry(hashmap, key, str = value)

	WAVE/Z results = GetFilledEntries(hashmap)
	CHECK_WAVE(results, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(results, {6100}, mode = WAVE_DATA)

	CheckHashmapEntry(hashmap, results[0], 1, {key, ""}, {value, ""})

	ret = HM_DeleteEntry(hashmap, key)
	CHECK_EQUAL_VAR(ret, 0)

	WAVE/Z results = GetFilledEntries(hashmap)
	CHECK_WAVE(results, NULL_WAVE)

	CheckHashmapEntry(hashmap, 6100, 0, {"", ""}, {"", ""})

	[result, found] = HM_GetEntryAsString(hashmap, key)

	CHECK_EQUAL_VAR(found, 0)
	CHECK_EQUAL_STR(result, "")

	// value can't be deleted anymore
	ret = HM_DeleteEntry(hashmap, key)
	CHECK_EQUAL_VAR(ret, 1)

	WAVE/Z results = GetFilledEntries(hashmap)
	CHECK_WAVE(results, NULL_WAVE)

	// add three collisions, see AddEntryWorks()
	// dup[0] = {7314,57289,71869}
	key   = "7314"
	value = "efgh"
	HM_AddEntry(hashmap, key, str = value)

	key   = "57289"
	value = "ijkl"
	HM_AddEntry(hashmap, key, str = value)

	key   = "71869"
	value = "mnop"
	HM_AddEntry(hashmap, key, str = value)

	WAVE/Z results = GetFilledEntries(hashmap)
	CHECK_WAVE(results, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(results, {6100}, mode = WAVE_DATA)

	CheckHashmapEntry(hashmap, results[0], 3, {"7314", "57289", "71869", ""}, {"efgh", "ijkl", "mnop", ""})

	// delete the center one
	ret = HM_DeleteEntry(hashmap, "57289")
	CHECK_EQUAL_VAR(ret, 0)

	CheckHashmapEntry(hashmap, results[0], 2, {"7314", "71869", "", ""}, {"efgh", "mnop", "", ""})
End

static Function DeleteLastEntryWorks()

	string key, value
	variable ret

	WAVE hashmap = HM_Create()

	// add two collisions
	key   = "7314"
	value = "efgh"
	HM_AddEntry(hashmap, key, str = value)

	key   = "57289"
	value = "ijkl"
	HM_AddEntry(hashmap, key, str = value)

	WAVE/Z results = GetFilledEntries(hashmap)
	CHECK_WAVE(results, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(results, {6100}, mode = WAVE_DATA)

	// delete last one
	ret = HM_DeleteEntry(hashmap, key)
	CHECK_EQUAL_VAR(ret, 0)
	CHECK_NO_RTE()
End

/// UTF_TD_GENERATOR DataGenerators#ValidHashmapSizes
static Function WorksWithDifferentSizes([variable var])

	string key, value, result
	variable found, ret

	WAVE/WAVE hashmap = HM_Create(size = var)

	// add entry
	key   = "7314"
	value = "efgh"
	HM_AddEntry(hashmap, key, str = value)

	// fetch it
	[result, found] = HM_GetEntryAsString(hashmap, key)

	CHECK_EQUAL_VAR(found, 1)
	CHECK_EQUAL_STR(result, value)

	// delete it
	ret = HM_DeleteEntry(hashmap, key)
	CHECK_EQUAL_VAR(ret, 0)

	[result, found] = HM_GetEntryAsString(hashmap, key)

	CHECK_EQUAL_VAR(found, 0)
	CHECK_EQUAL_STR(result, "")
End

static Function CalculateLoadFactorWorks()

	variable loadFactor
	string key, value

	WAVE/WAVE hashmap = HM_Create(size = 8)

	loadFactor = MIES_HM#HM_CalculateLoadFactor(hashmap)
	CHECK_EQUAL_VAR(loadFactor, 0)

	// add entry
	key   = "7314"
	value = "efgh"
	HM_AddEntry(hashmap, key, str = value)

	loadFactor = MIES_HM#HM_CalculateLoadFactor(hashmap)
	CHECK_EQUAL_VAR(loadFactor, 1 / 8)

	// add a collision, see FindCollision_IGNORE()
	key   = "7"
	value = "mnop"
	HM_AddEntry(hashmap, key, str = value)

	WAVE/Z filledEntries = GetFilledEntries(hashmap)
	CHECK_WAVE(filledEntries, NUMERIC_WAVE)

	CheckHashmapEntry(hashmap, filledEntries[0], 2, {"7314", "7"}, {"efgh", "mnop"})

	// and add another entry
	key   = "someKey"
	value = "ijkl"
	HM_AddEntry(hashmap, key, str = value)

	WAVE/Z filledEntries = GetFilledEntries(hashmap)
	CHECK_WAVE(filledEntries, NUMERIC_WAVE)

	loadFactor = MIES_HM#HM_CalculateLoadFactor(hashmap)
	CHECK_EQUAL_VAR(loadFactor, 3 / 8)
End

/// UTF_TD_GENERATOR DataGenerators#PermanentOrFree
static Function RehashingWorks([variable var])

	variable numEntries, i, found, initialSize
	string value

	initialSize = 1
	numEntries  = 8

	WAVE/WAVE hashmapFree = HM_Create(size = initialSize)

	if(var)
		Duplicate/WAVE hashmapFree, hashmap
	else
		WAVE/WAVE hashmap = hashmapFree
	endif

	WAVE/WAVE hashmap_old = hashmap

	CHECK_EQUAL_VAR(HM_RehashIfRequired(hashmap), 0)
	CHECK(WaveRefsEqual(hashmap, hashmap_old))

	for(i = 0; i < numEntries; i += 1)
		HM_AddEntry(hashmap, num2str(i), str = "-" + num2str(i))
	endfor

	CHECK_EQUAL_VAR(HM_RehashIfRequired(hashmap), 1)
	WAVE/WAVE hashmap_impl = hashmap[1]
	CHECK_EQUAL_VAR(DimSize(hashmap_impl, ROWS), numEntries * 4)
	CHECK(!WaveRefsEqual(hashmap, hashmap_old))

	WAVE/Z filledEntries = GetFilledEntries(hashmap)
	CHECK_WAVE(filledEntries, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(filledEntries, ROWS), numEntries)
	CHECK_EQUAL_WAVES(filledEntries, {21, 22, 23, 24, 25, 26, 27, 28}, mode = WAVE_DATA)

	for(i = 0; i < numEntries; i += 1)
		[value, found] = HM_GetEntryAsString(hashmap, num2str(i))
		CHECK(found)
		CHECK_EQUAL_STR(value, "-" + num2str(i))
	endfor

	if(var)
		KillWaves hashmap
	endif
End

static Function GetAllKeysWorks()

	string key, value, result
	variable found

	WAVE hashmap = HM_Create()

	WAVE/Z allKeys = HM_GetAllKeys(hashmap)
	CHECK_WAVE(allKeys, NULL_WAVE)

	// adding first value
	key   = "7314"
	value = "efgh"
	HM_AddEntry(hashmap, key, str = value)

	WAVE/Z allKeys = HM_GetAllKeys(hashmap)
	CHECK_EQUAL_TEXTWAVES(allKeys, {"7314"})

	// random other entry
	key   = "1234"
	value = "abcdf"
	HM_AddEntry(hashmap, key, str = value)

	WAVE/Z allKeys = HM_GetAllKeys(hashmap)
	CHECK_EQUAL_TEXTWAVES(allKeys, {"7314", "1234"})

	// returned key is from a collision, see AddEntryWorks()
	key   = "57289"
	value = "ijkl"
	HM_AddEntry(hashmap, key, str = value)

	WAVE/Z allKeys = HM_GetAllKeys(hashmap)
	CHECK_EQUAL_TEXTWAVES(allKeys, {"7314", "57289", "1234"})
End

/// UTF_TD_GENERATOR DataGenerators#GenerateAllPossibleNumericWaveTypes
static Function WorksWithNumericValues([variable var])

	string key, valueStr
	variable value, found, ret

	if(var & IGOR_TYPE_COMPLEX)
		// no support for complex
		SKIP_TESTCASE()
		return NaN
	endif

	WAVE/WAVE hashmap = HM_Create(size = 8, valueType = var)

	WAVE/Z results = GetFilledEntries(hashmap)
	CHECK_WAVE(results, NULL_WAVE)

	key   = "1234"
	value = 200
	HM_AddEntry(hashmap, key, var = value)
	WAVE/Z results = GetFilledEntries(hashmap)
	CHECK_WAVE(results, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(results, {7})

	// another entry
	key   = "910111213"
	value = 150
	HM_AddEntry(hashmap, key, var = value)
	WAVE/Z results = GetFilledEntries(hashmap)
	CHECK_WAVE(results, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(results, {0, 7})

	WAVE/Z/T keys = HM_GetAllKeys(hashmap)
	CHECK_WAVE(keys, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(keys, {"910111213", "1234"})

	// collision
	// •FindCollision_IGNORE(7, size = 8)
	// dup[0] = {2,11,19}
	key   = "2"
	value = 30
	HM_AddEntry(hashmap, key, var = value)

	[value, found] = HM_GetEntryAsNumber(hashmap, key)
	CHECK(found)
	CHECK_EQUAL_VAR(value, 30)

	ret = HM_DeleteEntry(hashmap, key)
	CHECK_EQUAL_VAR(ret, 0)

	WAVE/Z results = GetFilledEntries(hashmap)
	CHECK_WAVE(results, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(results, {0, 7})

	try
		[valueStr, found] = HM_GetEntryAsString(hashmap, "1234")
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

static Function CalcOptSizeWorks()

	CHECK_EQUAL_VAR(HM_CalculateOptimumSize(0), 4)
	CHECK_EQUAL_VAR(HM_CalculateOptimumSize(1), 4)
	CHECK_EQUAL_VAR(HM_CalculateOptimumSize(2), 8)
	CHECK_EQUAL_VAR(HM_CalculateOptimumSize(3), 16)
	CHECK_EQUAL_VAR(HM_CalculateOptimumSize(4), 16)
	CHECK_EQUAL_VAR(HM_CalculateOptimumSize(5), 16)
	CHECK_EQUAL_VAR(HM_CalculateOptimumSize(6), 32)

	CHECK_EQUAL_VAR(HM_CalculateOptimumSize(32), 128)
End

static Function HashmapFromIndizesWorks()

	variable type = IGOR_TYPE_32BIT_FLOAT
	variable found, value

	WAVE hashmap = HM_GetHashmapFromEntriesAndIndizes($"", 0, type, 1)
	CHECK_WAVE(hashmap, WAVE_WAVE)
	CHECK_EQUAL_VAR(MIES_HM#HM_GetSize(hashmap), 4)

	// numEntries larger 1 but no entries wave
	try
		WAVE hashmap = HM_GetHashmapFromEntriesAndIndizes($"", 1, type, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// only the first two elements are added as the third is empty
	Make/FREE/T entries = {"a", "b", "", "c"}
	WAVE/WAVE hashmap = HM_GetHashmapFromEntriesAndIndizes(entries, 3, type, 16)
	CHECK_WAVE(hashmap, WAVE_WAVE)
	CHECK_EQUAL_VAR(MIES_HM#HM_GetSize(hashmap), 16)

	WAVE/T allKeys = HM_GetAllKeys(hashmap)
	Sort allKeys, allKeys
	CHECK_EQUAL_TEXTWAVES({"a", "b"}, allKeys)

	[value, found] = HM_GetEntryAsNumber(hashmap, "a")
	CHECK_EQUAL_VAR(found, 1)
	CHECK_EQUAL_VAR(value, 0)

	[value, found] = HM_GetEntryAsNumber(hashmap, "b")
	CHECK_EQUAL_VAR(found, 1)
	CHECK_EQUAL_VAR(value, 1)

	// adding as case insensitive
	Make/FREE/T entries = {"A", "b", ""}
	WAVE/WAVE hashmap = HM_GetHashmapFromEntriesAndIndizes(entries, 3, type, 16, caseSensitive = 0)

	// gives all lower keys
	WAVE/T allKeys = HM_GetAllKeys(hashmap)
	Sort allKeys, allKeys
	CHECK_EQUAL_TEXTWAVES({"a", "b"}, allKeys)
End
