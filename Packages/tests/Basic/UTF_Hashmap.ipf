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

static Function CheckHashmapEntry(WAVE/WAVE hashmap, variable index, variable usedEntries, WAVE/T keys, WAVE/T values)

	[WAVE usedRows, WAVE/T keysRef, WAVE/T valuesRef] = MIES_HM#HM_FetchWaves(hashmap, index)

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

	WAVE/Z result = MIES_HM#HM_GetFilledEntries(hashmap)
	CHECK_WAVE(result, NULL_WAVE)

	// adding first value
	key   = "7314"
	value = "efgh"
	ret   = HM_AddEntry(hashmap, key, value)
	CHECK_EQUAL_VAR(ret, 1)

	WAVE/Z result = MIES_HM#HM_GetFilledEntries(hashmap)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, {6100}, mode = WAVE_DATA)

	CheckHashmapEntry(hashmap, result[0], 1, {key, ""}, {value, ""})

	// overwrite the same value again
	ret = HM_AddEntry(hashmap, key, value)
	CHECK_EQUAL_VAR(ret, 0)

	WAVE/Z result = MIES_HM#HM_GetFilledEntries(hashmap)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, {6100}, mode = WAVE_DATA)

	CheckHashmapEntry(hashmap, result[0], 1, {key, ""}, {value, ""})

	// write new value with the same index
	// Found via
	// •FindCollision_IGNORE(6100)
	// dup[0] = {7314,57289,71869}
	ret = HM_AddEntry(hashmap, "57289", "ijkl")
	CHECK_EQUAL_VAR(ret, 1)

	WAVE/Z result = MIES_HM#HM_GetFilledEntries(hashmap)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, {6100}, mode = WAVE_DATA)

	CheckHashmapEntry(hashmap, result[0], 2, {key, "57289"}, {value, "ijkl"})

	// add yet another collision, this time keys and values is resized
	ret = HM_AddEntry(hashmap, "71869", "mnop")
	CHECK_EQUAL_VAR(ret, 1)

	WAVE/Z result = MIES_HM#HM_GetFilledEntries(hashmap)
	CHECK_WAVE(result, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(result, {6100}, mode = WAVE_DATA)

	CheckHashmapEntry(hashmap, result[0], 3, {key, "57289", "71869", ""}, {value, "ijkl", "mnop", ""})
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
	variable found

	WAVE hashmap = HM_Create()

	// adding first value
	key   = "7314"
	value = "efgh"
	HM_AddEntry(hashmap, key, value)

	[result, found] = HM_GetEntry(hashmap, key)

	CHECK_EQUAL_VAR(found, 1)
	CHECK_EQUAL_STR(result, value)

	// unknown key
	[result, found] = HM_GetEntry(hashmap, "I_DONT_EXIST")

	CHECK_EQUAL_VAR(found, 0)
	CHECK_EQUAL_STR(result, "")

	// can store and retrieve empty value
	key   = ""
	value = ""
	HM_AddEntry(hashmap, key, value)

	[result, found] = HM_GetEntry(hashmap, key)

	CHECK_EQUAL_VAR(found, 1)
	CHECK_EQUAL_STR(result, "")

	// returned key is from a collision, see AddEntryWorks()
	key   = "57289"
	value = "ijkl"
	HM_AddEntry(hashmap, key, value)

	[result, found] = HM_GetEntry(hashmap, key)

	CHECK_EQUAL_VAR(found, 1)
	CHECK_EQUAL_STR(result, value)
End

static Function DeleteEntryWorks()

	string key, value, result
	variable found, ret

	WAVE hashmap = HM_Create()

	// adding first value
	key   = "7314"
	value = "efgh"
	HM_AddEntry(hashmap, key, value)

	WAVE/Z results = MIES_HM#HM_GetFilledEntries(hashmap)
	CHECK_WAVE(results, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(results, {6100}, mode = WAVE_DATA)

	CheckHashmapEntry(hashmap, results[0], 1, {key, ""}, {value, ""})

	ret = HM_DeleteEntry(hashmap, key)
	CHECK_EQUAL_VAR(ret, 0)

	WAVE/Z results = MIES_HM#HM_GetFilledEntries(hashmap)
	CHECK_WAVE(results, NULL_WAVE)

	CheckHashmapEntry(hashmap, 6100, 0, {"", ""}, {"", ""})

	[result, found] = HM_GetEntry(hashmap, key)

	CHECK_EQUAL_VAR(found, 0)
	CHECK_EQUAL_STR(result, "")

	// value can't be deleted anymore
	ret = HM_DeleteEntry(hashmap, key)
	CHECK_EQUAL_VAR(ret, 1)

	WAVE/Z results = MIES_HM#HM_GetFilledEntries(hashmap)
	CHECK_WAVE(results, NULL_WAVE)

	// add three collisions, see AddEntryWorks()
	// dup[0] = {7314,57289,71869}
	key   = "7314"
	value = "efgh"
	HM_AddEntry(hashmap, key, value)

	key   = "57289"
	value = "ijkl"
	HM_AddEntry(hashmap, key, value)

	key   = "71869"
	value = "mnop"
	HM_AddEntry(hashmap, key, value)

	WAVE/Z results = MIES_HM#HM_GetFilledEntries(hashmap)
	CHECK_WAVE(results, NUMERIC_WAVE)
	CHECK_EQUAL_WAVES(results, {6100}, mode = WAVE_DATA)

	CheckHashmapEntry(hashmap, results[0], 3, {"7314", "57289", "71869", ""}, {"efgh", "ijkl", "mnop", ""})

	// delete the center one
	ret = HM_DeleteEntry(hashmap, "57289")
	CHECK_EQUAL_VAR(ret, 0)

	CheckHashmapEntry(hashmap, results[0], 2, {"7314", "71869", "", ""}, {"efgh", "mnop", "", ""})
End

/// UTF_TD_GENERATOR DataGenerators#ValidHashmapSizes
static Function WorksWithDifferentSizes([variable var])

	string key, value, result
	variable found, ret

	WAVE/WAVE hashmap = HM_Create(size = var)

	// add entry
	key   = "7314"
	value = "efgh"
	HM_AddEntry(hashmap, key, value)

	// fetch it
	[result, found] = HM_GetEntry(hashmap, key)

	CHECK_EQUAL_VAR(found, 1)
	CHECK_EQUAL_STR(result, value)

	// delete it
	ret = HM_DeleteEntry(hashmap, key)
	CHECK_EQUAL_VAR(ret, 0)

	[result, found] = HM_GetEntry(hashmap, key)

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
	HM_AddEntry(hashmap, key, value)

	loadFactor = MIES_HM#HM_CalculateLoadFactor(hashmap)
	CHECK_EQUAL_VAR(loadFactor, 1 / 8)

	// add a collision, see FindCollision_IGNORE()
	key   = "7"
	value = "mnop"
	HM_AddEntry(hashmap, key, value)

	WAVE/Z filledEntries = MIES_HM#HM_GetFilledEntries(hashmap)
	CHECK_WAVE(filledEntries, NUMERIC_WAVE)

	CheckHashmapEntry(hashmap, filledEntries[0], 2, {"7314", "7"}, {"efgh", "mnop"})

	// and add another entry
	key   = "someKey"
	value = "ijkl"
	HM_AddEntry(hashmap, key, value)

	WAVE/Z filledEntries = MIES_HM#HM_GetFilledEntries(hashmap)
	CHECK_WAVE(filledEntries, NUMERIC_WAVE)

	loadFactor = MIES_HM#HM_CalculateLoadFactor(hashmap)
	CHECK_EQUAL_VAR(loadFactor, 3 / 8)
End

/// UTF_TD_GENERATOR DataGenerators#PermanentOrFree
static Function RehashingWorks([variable var])

	variable numEntries, i, size, found
	string value

	size = 8

	WAVE/WAVE hashmapFree = HM_Create(size = size)

	if(var)
		Duplicate/WAVE hashmapFree, hashmap
	else
		WAVE/WAVE hashmap = hashmapFree
	endif

	WAVE/WAVE hashmap_old = hashmap

	CHECK_EQUAL_VAR(HM_RehashIfRequired(hashmap), 0)
	CHECK(WaveRefsEqual(hashmap, hashmap_old))

	for(i = 0; i < size; i += 1)
		HM_AddEntry(hashmap, num2str(i), "-" + num2str(i))
	endfor

	CHECK_EQUAL_VAR(HM_RehashIfRequired(hashmap), 1)
	WAVE/WAVE hashmap_impl = hashmap[1]
	CHECK_EQUAL_VAR(DimSize(hashmap_impl, ROWS), size * 2)
	CHECK(!WaveRefsEqual(hashmap, hashmap_old))

	WAVE/Z filledEntries = MIES_HM#HM_GetFilledEntries(hashmap)
	CHECK_WAVE(filledEntries, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(DimSize(filledEntries, ROWS), size)
	CHECK_EQUAL_WAVES(filledEntries, {5, 6, 7, 8, 9, 10, 11, 12}, mode = WAVE_DATA)

	for(i = 0; i < size; i += 1)
		[value, found] = HM_GetEntry(hashmap, num2str(i))
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
	HM_AddEntry(hashmap, key, value)

	WAVE/Z allKeys = HM_GetAllKeys(hashmap)
	CHECK_EQUAL_TEXTWAVES(allKeys, {"7314"})

	// random other entry
	key   = "1234"
	value = "abcdf"
	HM_AddEntry(hashmap, key, value)

	WAVE/Z allKeys = HM_GetAllKeys(hashmap)
	CHECK_EQUAL_TEXTWAVES(allKeys, {"7314", "1234"})

	// returned key is from a collision, see AddEntryWorks()
	key   = "57289"
	value = "ijkl"
	HM_AddEntry(hashmap, key, value)

	WAVE/Z allKeys = HM_GetAllKeys(hashmap)
	CHECK_EQUAL_TEXTWAVES(allKeys, {"7314", "57289", "1234"})
End
