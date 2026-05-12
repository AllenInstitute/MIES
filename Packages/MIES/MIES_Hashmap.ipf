#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_HM
#endif // AUTOMATED_TESTING

static Constant HM_SMALL_WAVE_OPTIMIZATION_ROWS = 5
static Constant HM_MAX_LOAD_FACTOR              = 0.7

/// @name Indizes into HM_CreateStatsWave()
///@{
static Constant HM_TOTAL_ENTRIES_ROW = 0
///@}

/// @name Indizes into HM_CreateManagementWave()
///@{
static Constant HM_USED_ROWS_ROW = 0
static Constant HM_STATS_ROW     = 1
///@}

/// @name Indizes into HM_CreateHashmap()
///@{
static Constant HM_KEYS_COLUMN   = 0
static Constant HM_VALUES_COLUMN = 1
///@}

/// @name Indizes into HM_Create()
///@{
static Constant HM_MGMT_ROW    = 0
static Constant HM_HASHMAP_ROW = 1
///@}

/// @file MIES_Hashmap.ipf
///
/// Pure Igor Pro implementation of a hashmap using separate chaining.
///
/// Features:
/// - Supports all sizes which are a power of two
/// - Constant time access O(1) with small load factors
/// - Handles collisions correctly
/// - Avoids implicit rehashing but supports explicit rehashing
/// - The hashmaps can be used in preemptive threads, but none of them are reentrant

// Benchmark code from https://www.wavemetrics.com/forum/general/brief-performance-review-key-value-store-methods-igor-pro
// Usage:
// - Comment in the code between BEGIN and END
// - Comment in various different methods
// - Run `bench()`
// - Open the graph `Graph1_2()`

// BEGIN bench

// #define JSON_TEST
//
// //#define STRING_BY_KEY_TEST
// //#define DIM_LABELS_TEST
// //#define WAVE_TEST
// //#define TEXT_WAVE_TEST
// //#define TEXT_WAVE_HASH_MAP_TEST_AL
// #define TEXT_WAVE_HASH_MAP_TEST_TB
//
// Function IntNoise(variable from, variable to)
//
// 	variable amp = to - from
//
// 	return floor(from + mod(abs(enoise(100 * amp)), amp + 1))
// End
//
// Function Bench()
//
// 	variable NUM_RUNS_READ  = 100
// 	variable NUM_RUNS_WRITE = 100
//
// 	variable numExponentials = 6
// 	variable expStep         = 10
// 	variable size
// 	variable ref, i, j, idx, jsonID, e, elapsed, found
// 	string output, name, str, result
// 	variable numRunsWrite
//
// 	Make/O/D/N=(7, 2, numExponentials * expStep) resultWave
// 	resultWave = NaN
// 	SetScale/P z, 0, 1 / expStep, "", resultWave
//
// 	SetDimLabel 0, 0, JSON, resultWave
// 	SetDimLabel 0, 1, Textwave, resultWave
// 	SetDimLabel 0, 2, StringByKey, resultWave
// 	SetDimLabel 0, 3, DimLabel, resultWave
// 	SetDimLabel 0, 4, Wave, resultWave
// 	SetDimLabel 0, 5, TextWaveHashAL, resultWave
// 	SetDimLabel 0, 6, TextWaveHashTB, resultWave
//
// 	SetDimLabel 1, 0, Reading, resultWave
// 	SetDimLabel 1, 1, Writing, resultWave
//
// 	//	Execute/Q "Graph0()"
// 	//	Execute/Q "Graph1_2()"
// 	// name is the key and num2str(index) is the value
//
// 	for(e = 0; e < (numExponentials * expStep); e += 1)
// 		size = trunc(10^(e / expStep))
//
// 		if(e > 25)
// 			NUM_RUNS_READ  = 10
// 			NUM_RUNS_WRITE = 10
// 		endif
// 		if(e > 40)
// 			NUM_RUNS_READ  = 100
// 			NUM_RUNS_WRITE = 100
// 		endif
//
// 		if(size < NUM_RUNS_WRITE)
// 			numRunsWrite = NUM_RUNS_WRITE
// 		else
// 			numRunsWrite = 1
// 		endif
//
// 		SetRandomSeed 1
//
// 		Make/N=(NUM_RUNS_READ)/O indizes = IntNoise(0, size - 1)
//
// #ifdef JSON_TEST
// 		jsonID = JSON_New()
//
// 		ref = stopmSTimer(-2)
// 		for(i = 0; i < numRunsWrite; i += 1)
//
// 			for(j = 0; j < size; j += 1)
// 				name = "abcd" + num2str(j)
// 				JSON_SetString(jsonID, "/" + name, num2str(j))
// 			endfor
// 		endfor
//
// 		elapsed                        = (stopmSTimer(-2) - ref) * MICRO_TO_ONE / numRunsWrite / size
// 		resultWave[%JSON][%Writing][e] = elapsed
//
// 		ref = stopmSTimer(-2)
// 		for(i = 0; i < NUM_RUNS_READ; i += 1)
// 			name   = "abcd" + num2str(indizes[i])
// 			output = JSON_GetString(jsonID, "/" + name)
// 		endfor
//
// 		elapsed                        = (stopmSTimer(-2) - ref) * MICRO_TO_ONE / NUM_RUNS_READ
// 		resultWave[%JSON][%Reading][e] = elapsed
//
// 		JSON_Release(jsonID)
// #endif // JSON_TEST
//
// #ifdef TEXT_WAVE_TEST
// 		Make/FREE/T/N=(size) tw
// 		ref = stopmSTimer(-2)
// 		for(i = 0; i < numRunsWrite; i += 1)
// 			for(j = 0; j < size; j += 1)
// 				name  = "abcd" + num2str(j)
// 				tw[j] = name
// 			endfor
// 		endfor
//
// 		elapsed                            = (stopmSTimer(-2) - ref) * MICRO_TO_ONE / numRunsWrite / size
// 		resultWave[%TextWave][%Writing][e] = elapsed
//
// 		ref = stopmSTimer(-2)
// 		for(i = 0; i < NUM_RUNS_READ; i += 1)
// 			name = "abcd" + num2str(indizes[i])
// 			//FindValue/TEXT=(name)/TXOP=4/UOFV tw
// 			FindValue/TEXT=(name)/TXOP=4 tw
// 			output = num2str(V_Value)
// 		endfor
//
// 		elapsed                            = (stopmSTimer(-2) - ref) * MICRO_TO_ONE / NUM_RUNS_READ
// 		resultWave[%TextWave][%Reading][e] = elapsed
// #endif // TEXT_WAVE_TEST
//
// #ifdef TEXT_WAVE_HASH_MAP_TEST_AL
// 		Make/FREE/T/N=(size) tw
// 		Make/FREE/I/U/N=(size) twHash // crc32 values are unsigned 32-bit integers
//
// 		ref = stopmSTimer(-2)
// 		for(i = 0; i < numRunsWrite; i += 1)
// 			for(j = 0; j < size; j += 1)
// 				name      = "abcd" + num2str(j)
// 				tw[j]     = name
// 				twHash[j] = StringCrC(0, name)
// 			endfor
// 		endfor
//
// 		elapsed                                  = (stopmSTimer(-2) - ref) * MICRO_TO_ONE / numRunsWrite / size
// 		resultWave[%TextWaveHashAL][%Writing][e] = elapsed
//
// 		variable outputIndex
// 		ref = stopmSTimer(-2)
// 		for(i = 0; i < NUM_RUNS_READ; i += 1)
// 			name        = "abcd" + num2str(indizes[i])
// 			outputIndex = FindPointIndexOfString(name, tw, twHash)
// 			output      = tw[outputIndex]
// 		endfor
//
// 		elapsed                                  = (stopmSTimer(-2) - ref) * MICRO_TO_ONE / NUM_RUNS_READ
// 		resultWave[%TextWaveHashAL][%Reading][e] = elapsed
// #endif // TEXT_WAVE_HASH_MAP_TEST_AL
//
// #ifdef TEXT_WAVE_HASH_MAP_TEST_TB
// 		WAVE indizesHM = HM_Create()
// 		ref = stopmSTimer(-2)
//
// 		for(i = 0; i < numRunsWrite; i += 1)
// 			for(j = 0; j < size; j += 1)
// 				name = "abcd" + num2str(indizes[i])
// 				HM_AddEntry(indizesHM, name, str = num2str(j))
// 			endfor
// 		endfor
//
// 		elapsed                                  = (stopmSTimer(-2) - ref) * MICRO_TO_ONE / numRunsWrite / size
// 		resultWave[%TextWaveHashTB][%Writing][e] = elapsed
//
// 		ref = stopmSTimer(-2)
// 		for(i = 0; i < NUM_RUNS_READ; i += 1)
// 			name            = "abcd" + num2str(indizes[i])
// 			[output, found] = HM_GetEntryAsString(indizesHM, name)
// 		endfor
//
// 		elapsed                                  = (stopmSTimer(-2) - ref) * MICRO_TO_ONE / NUM_RUNS_READ
// 		resultWave[%TextWaveHashTB][%Reading][e] = elapsed
// #endif // TEXT_WAVE_HASH_MAP_TEST_TB
//
// #ifdef STRING_BY_KEY_TEST
// 		ref = stopmSTimer(-2)
// 		for(i = 0; i < numRunsWrite; i += 1)
//
// 			str = PadString("", size * 20, 0)
//
// 			for(j = 0; j < size; j += 1)
// 				name = "abcd" + num2str(j)
// 				str += name + ":" + num2str(j) + ";"
// 			endfor
// 		endfor
//
// 		elapsed                               = (stopmSTimer(-2) - ref) * MICRO_TO_ONE / numRunsWrite / size
// 		resultWave[%StringByKey][%Writing][e] = elapsed
//
// 		ref = stopmSTimer(-2)
// 		for(i = 0; i < NUM_RUNS_READ; i += 1)
// 			name   = "abcd" + num2str(indizes[i])
// 			result = StringbyKey(name, str)
// 		endfor
//
// 		elapsed                               = (stopmSTimer(-2) - ref) * MICRO_TO_ONE / NUM_RUNS_READ
// 		resultWave[%StringByKey][%Reading][e] = elapsed
// #endif // STRING_BY_KEY_TEST
//
// #ifdef DIM_LABELS_TEST
// 		Make/N=(size)/FREE/T dimlabels
//
// 		ref = stopmSTimer(-2)
// 		for(i = 0; i < numRunsWrite; i += 1)
// 			for(j = 0; j < size; j += 1)
// 				name = "abcd" + num2str(j)
// 				SetdimLabel ROWS, j, $name, dimlabels
// 				dimlabels[j] = num2str(j)
// 			endfor
// 		endfor
//
// 		elapsed                            = (stopmSTimer(-2) - ref) * MICRO_TO_ONE / numRunsWrite / size
// 		resultWave[%DimLabel][%Writing][e] = elapsed
//
// 		ref = stopmSTimer(-2)
// 		for(i = 0; i < NUM_RUNS_READ; i += 1)
// 			name   = "abcd" + num2str(indizes[i])
// 			result = dimlabels[%$name]
// 		endfor
//
// 		elapsed                            = (stopmSTimer(-2) - ref) * MICRO_TO_ONE / NUM_RUNS_READ
// 		resultWave[%DimLabel][%Reading][e] = elapsed
// #endif // DIM_LABELS_TEST
//
// #ifdef WAVE_TEST
// 		ref = stopmSTimer(-2)
// 		for(i = 0; i < numRunsWrite; i += 1)
// 			DFREF dfr = NewFreeDataFolder()
//
// 			for(j = 0; j < size; j += 1)
// 				name = "abcd" + num2istr(j)
// 				Make/T/N=1 dfr:$name/WAVE=wv
// 				wv[0] = num2istr(j)
// 			endfor
// 		endfor
//
// 		elapsed                        = (stopmSTimer(-2) - ref) * MICRO_TO_ONE / numRunsWrite / size
// 		resultWave[%Wave][%Writing][e] = elapsed
//
// 		ref = stopmSTimer(-2)
// 		for(i = 0; i < NUM_RUNS_READ; i += 1)
// 			name = "abcd" + num2istr(indizes[i])
// 			WAVE/T/SDFR=dfr wv = $name
// 			result = wv[0]
// 		endfor
//
// 		elapsed                        = (stopmSTimer(-2) - ref) * MICRO_TO_ONE / NUM_RUNS_READ
// 		resultWave[%Wave][%Reading][e] = elapsed
// #endif // WAVE_TEST
// 		DoUpdate
// 	endfor
//
// 	Duplicate/O resultWave, resultWaveSummed
//
// 	resultWaveSummed[][0][] = resultWaveSummed[p][0][r] + resultWaveSummed[p][1][r]
// 	Redimension/N=(-1, 1, -1) resultWaveSummed
// End
//
// Window Graph1_2() : Graph // NOLINT
// 	PauseUpdate; Silent 1 // building window...
// 	Display/W=(70.5, 601.25, 840.75, 1085) resultWave[%JSON][%Reading][*]/TN=JsonReading
// 	AppendToGraph resultWave[%dimlabel][%Reading][*]/TN=DimLabelReading, resultWave[%textwave][%Reading][*]/TN=TextWaveReading
// 	AppendToGraph resultWave[%stringByKey][%Reading][*]/TN=StringByKeyReading, resultWave[%wave][%Reading][*]/TN=WaveReading
// 	AppendToGraph resultWave[%TextWaveHashAL][%Reading][*]/TN=TextWaveHashReadingAL
// 	AppendToGraph resultWave[%TextWaveHashTB][%Reading][*]/TN=TextWaveHashReadingTB
// 	AppendToGraph resultWave[%JSON][%Writing][*]/TN=JsonWriting, resultWave[%dimlabel][%Writing][*]/TN=DimLabelWriting
// 	AppendToGraph resultWave[%textwave][%Writing][*]/TN=TextWaveWriting, resultWave[%stringByKey][%Writing][*]/TN=StringByKeyWriting
// 	AppendToGraph resultWave[%wave][%Writing][*]/TN=WaveWriting
// 	AppendToGraph resultWave[%TextWaveHashAL][%Writing][*]/TN=TextWaveHashWritingAL
// 	AppendToGraph resultWave[%TextWaveHashTB][%Writing][*]/TN=TextWaveHashWritingTB
// 	ModifyGraph mode=4
// 	ModifyGraph marker(JsonReading)=19, marker(DimLabelReading)=19, marker(TextWaveReading)=19
// 	ModifyGraph marker(StringByKeyReading)=19, marker(WaveReading)=19, marker(JsonWriting)=16
// 	ModifyGraph marker(DimLabelWriting)=16, marker(TextWaveWriting)=16, marker(StringByKeyWriting)=16
// 	ModifyGraph marker(WaveWriting)=16
// 	ModifyGraph marker(TextWaveHashReadingAL)=19
// 	ModifyGraph marker(TextWaveHashWritingAL)=16
// 	ModifyGraph marker(TextWaveHashReadingTB)=19
// 	ModifyGraph marker(TextWaveHashWritingTB)=16
// 	ModifyGraph lSize=1.5
// 	ModifyGraph rgb(JsonReading)=(0, 0, 0), rgb(DimLabelReading)=(39321, 1, 31457), rgb(TextWaveReading)=(2, 39321, 1)
// 	ModifyGraph rgb(StringByKeyReading)=(65535, 32764, 16385), rgb(WaveReading)=(0, 0, 65535)
// 	ModifyGraph rgb(JsonWriting)=(0, 0, 0), rgb(DimLabelWriting)=(39321, 1, 31457), rgb(TextWaveWriting)=(2, 39321, 1)
// 	ModifyGraph rgb(StringByKeyWriting)=(65535, 32764, 16385), rgb(WaveWriting)=(0, 0, 65535)
// 	ModifyGraph rgb(TextWaveHashReadingTB)=(65535, 0, 52428)
// 	ModifyGraph rgb(TextWaveHashWritingTB)=(65535, 0, 52428)
// 	ModifyGraph msize=2
// 	ModifyGraph mrkThick=1
// 	ModifyGraph grid(left)=1
// 	ModifyGraph log(left)=1
// 	ModifyGraph minor(bottom)=1
// 	ModifyGraph fSize=18
// 	ModifyGraph lblMargin(left)=10
// 	ModifyGraph lblLatPos(left)=3
// 	Label left, "\\Z18Execution time  in [s]"
// 	Label bottom, "\\Z18data size, 10\\Sx\\M elements"
// 	Legend/C/N=text0/J/A=MC/X=-30.58/Y=40.81 "\\Z18\\Zr075\rDimension Label\\[0 \\s(DimLabelReading) Read \\s(DimLabelWriting) Write"
// 	AppendText "JSON\\X0 \\s(JsonReading) Read \\s(JsonWriting) Write\nTextwave\\X0 \\s(TextWaveReading) Read \\s(TextWaveWriting) Write"
// 	AppendText "\nStringByKey\\X0 \\s(StringByKeyReading) Read \\s(StringByKeyWriting) Write\r\nWave\\X0 \\s(WaveReading) Read \\s(WaveWriting) Write"
// 	AppendText/N=text0 "TextWaveHashAL\\X0 \\s(TextWaveHashReadingAL) Read \\s(TextWaveHashWritingAL) Write"
// 	AppendText/N=text0 "TextWaveHashTB\\X0 \\s(TextWaveHashReadingTB) Read \\s(TextWaveHashWritingTB) Write"
// 	TextBox/C/N=text1/A=MC/X=-9.64/Y=147.84 "Time of one read/write operation"
// 	TextBox/C/N=text2/A=MC/X=11.55/Y=47.79 "\\Z18Time of one read/write operation"
// EndMacro
//
// Function FindPointIndexOfString(string inputStr, WAVE/T textWave, WAVE hashTableWave)
//
// 	int      inputStrCRC          = StringCRC(0, inputStr)
// 	variable pointIndex           = -1
// 	variable currentStartingIndex = 0
//
// 	do
// 		FindValue/U=(inputStrCRC)/S=(currentStartingIndex) hashTableWave // Slower but provides the right answer
// 		//FindValue/U=(inputStrCRC)/UOFV hashTableWave	// Not for use if avoiding collissions is a must!
// 		if(V_Value < 0)
// 			return V_Value // Didn't find inputStr in textWave
// 		endif
//
// 		if(CmpStr(textWave[V_Value], inputStr, 2) != 0)
// 			// Check for the unusual but possible case where the crc32 of inputStr
// 			// matches in hashTableWave but the actual unhashed text
// 			// strings do not match.
// 			currentStartingIndex = V_Value + 1
// 		else
// 			return V_Value
// 		endif
// 	while(1)
//
// 	// Should never get here
// End
//
// END bench

/// @brief Implementation of djb2 in plain Igor Pro
///
/// The implementation here does support embedded nulls, see DisplayHelpTopic "Embedded Nulls in Literal Strings".
///
/// See also https://github.com/dim13/djb2/blob/master/docs/hash.md#djb2.
threadsafe static Function [uint64 h] HM_DJBHash(string str)

	uint64 d
	h = 5381
	WAVE/U/B wv = StringToUnsignedByteWave(str)

	for(d : wv)
		h = h * 33 + d
	endfor

	return [h]
End

threadsafe static Function HM_HashKey(WAVE/WAVE hashmap, string key)

	uint64 h, size, result

	[h] = HM_DJBHash(key)

	size = HM_GetSize(hashmap) - 1

	// force integer evaluation
	result = h & size

	return result
End

threadsafe static Function HM_GetKeyIndex(WAVE/T keys, string key, variable numFilledEntries)

	variable i

	if(numFilledEntries == 0)
		return NaN
	endif

	if(numFilledEntries < HM_SMALL_WAVE_OPTIMIZATION_ROWS)
		for(i = 0; i < numFilledEntries; i += 1)
			if(!cmpstr(keys[i], key, 2))
				return i
			endif
		endfor

		return NaN
	endif

	// we search all entries and limit later as that is faster
	i = GetRowIndex(keys, str = key, textOp = (4 + 1))

	return (i < numFilledEntries) ? i : NaN
End

threadsafe static Function/WAVE HM_FetchUsedRows(WAVE/WAVE hashmap)

	return WaveRef(hashmap[HM_MGMT_ROW], row = HM_USED_ROWS_ROW)
End

threadsafe static Function/WAVE HM_FetchStats(WAVE/WAVE hashmap)

	return WaveRef(hashmap[HM_MGMT_ROW], row = HM_STATS_ROW)
End

threadsafe static Function HM_GetSize(WAVE/WAVE hashmap)

	return DimSize(hashmap[HM_HASHMAP_ROW], ROWS)
End

threadsafe static Function/WAVE HM_FetchKeys(WAVE/WAVE hashmap, variable bucketIndex)

	return WaveRef(hashmap[HM_HASHMAP_ROW], row = bucketIndex, col = HM_KEYS_COLUMN)
End

threadsafe static Function/WAVE HM_FetchValues(WAVE/WAVE hashmap, variable bucketIndex)

	return WaveRef(hashmap[HM_HASHMAP_ROW], row = bucketIndex, col = HM_VALUES_COLUMN)
End

threadsafe static Function [WAVE usedRows, WAVE/T keys, WAVE values] HM_FetchWaves(WAVE/WAVE hashmap, variable bucketIndex)

	WAVE   usedRows = HM_FetchUsedRows(hashmap)
	WAVE/T keys     = HM_FetchKeys(hashmap, bucketIndex)
	WAVE   values   = HM_FetchValues(hashmap, bucketIndex)

	return [usedRows, keys, values]
End

/// @brief Statistics wave
///
/// Rows:
/// - 0: Total number of filled entries
threadsafe static Function/WAVE HM_CreateStatsWave()

	Make/FREE/N=(1)/D wv

	return wv
End

/// @brief List of stored key/value pairs per hash prefix
///
/// Rows:
/// - Number of key/value pairs per hashmap row
threadsafe static Function/WAVE HM_CreateUsedRows(variable size)

	Make/FREE/N=(size)/U/I wv

	return wv
End

/// @brief Internal management wave
///
/// Rows:
/// - 0: 32-bit unsigned int wave with size rows denoting the number of key/value pairs per line
/// - 1: wave ref wave with stats entries, see HM_GetStatsWave()
threadsafe static Function/WAVE HM_CreateManagementWave(variable size)

	Make/FREE/N=(2)/WAVE wv

	wv[HM_USED_ROWS_ROW] = HM_CreateUsedRows(size)
	wv[HM_STATS_ROW]     = HM_CreateStatsWave()

	return wv
End

/// @brief Return a wave reference wave resembling a hashmap (implementation)
///
/// Rows:
///  - first bits of the hash
///
/// Columns:
/// - 0: 1D text wave with all keys for this hash
/// - 1: 1D wave with all values for this hash, type depends on valueType parameter
///
/// Complexity: O(n)
///
/// @param size size of the hashmap, needs to be a power of two
/// @param valueType wave type of the values, defaults to text wave and can be one of @ref IgorTypes
threadsafe static Function/WAVE HM_CreateHashmap(variable size, variable valueType)

	variable numThreads

	numThreads = GetNumberOfUsefulThreads({size})

	Make/FREE/WAVE/N=(size, 2) hashmap_impl

	Multithread/NT=(numThreads) hashmap_impl[][HM_KEYS_COLUMN] = NewFreeWave(IGOR_TYPE_TEXT_WREF_DFR, 2)
	Multithread/NT=(numThreads) hashmap_impl[][HM_VALUES_COLUMN] = NewFreeWave(valueType, 2)

	return hashmap_impl
End

/// @brief Return a wave reference wave resembling a hashmap
///
/// Rows:
///  - 0: Wave reference wave with management wave, see HM_CreateManagementWave()
///  - 1: Wave reference wave with hashmap data, see HM_CreateHashmap()
///
/// Complexity: O(n)
///
/// @param size size of the hashmap, needs to be a power of two
/// @param valueType wave type of the values, defaults to text wave and all
///                  non-complex numeric types from @ref IgorTypes are supported
threadsafe Function/WAVE HM_Create([variable size, variable valueType])

	if(ParamIsDefault(size))
		size = 2^16
	else
		ASSERT_TS(IsPower(size, 2), "size must be a power of two")
	endif

	if(ParamIsDefault(valueType))
		valueType = IGOR_TYPE_TEXT_WREF_DFR
	endif

	Make/FREE/WAVE/N=(2) hashmap

	hashmap[HM_MGMT_ROW]    = HM_CreateManagementWave(size)
	hashmap[HM_HASHMAP_ROW] = HM_CreateHashmap(size, valueType)

	return hashmap
End

/// @brief Clear the hashmap
threadsafe Function HM_Clear(WAVE/WAVE hashmap)

	WAVE usedRows = HM_FetchUsedRows(hashmap)
	Multithread usedRows[] = HM_ClearKeysAndValues(hashmap, p)

	WAVE totalEntries = HM_FetchStats(hashmap)
	totalEntries[HM_TOTAL_ENTRIES_ROW] = 0
End

threadsafe static Function HM_ClearKeysAndValues(WAVE/WAVE hashmap, variable bucketIndex)

	WAVE/T keys = HM_FetchKeys(hashmap, bucketIndex)
	keys[] = ""

	WAVE values = HM_FetchValues(hashmap, bucketIndex)

	if(IsTextWave(values))
		WAVE/T valuesText = values
		valuesText[] = ""
	else
		values[] = 0
	endif

	return 0
End

threadsafe static Function HM_StoreValue(WAVE values, variable bucketIndex, [string &str, variable &var])

	if(IsTextWave(values))
		ASSERT_TS(!IsNull(str), "Need a string value for a values text wave.")
		WAVE/T valuesText = values
		valuesText[bucketIndex] = str
	else
		ASSERT_TS(IsNull(str), "Can't write a string value without a values text wave.")
		values[bucketIndex] = var
	endif
End

/// @brief Add an entry into the hashmap
///
/// Complexity: Amortized O(1)
///
/// @return 1 when adding a new value and 0 when overwriting
threadsafe Function HM_AddEntry(WAVE/WAVE hashmap, string key, [string str, variable var])

	variable bucketIndex, entriesWithHash, keyIndex

	ASSERT_TS((ParamIsDefault(str) + ParamIsDefault(var)) == 1, "Need exactly one of str or var")

	bucketIndex = HM_HashKey(hashmap, key)

	[WAVE usedRows, WAVE/T keys, WAVE values] = HM_FetchWaves(hashmap, bucketIndex)

	entriesWithHash = usedRows[bucketIndex]

	if(entriesWithHash > 0)
		keyIndex = HM_GetKeyIndex(keys, key, entriesWithHash)

		if(keyIndex >= 0)
			// overwrite existing entry
			HM_StoreValue(values, keyIndex, str = str, var = var)
			return 0
		endif

		// no more space, need to expand keys and values
		if(entriesWithHash == DimSize(keys, ROWS))
			Redimension/N=(DimSize(keys, ROWS) * 2) keys, values
		endif
	endif

	keys[entriesWithHash] = key
	HM_StoreValue(values, entriesWithHash, str = str, var = var)

	usedRows[bucketIndex] = entriesWithHash + 1

	WAVE totalEntries = HM_FetchStats(hashmap)
	totalEntries[HM_TOTAL_ENTRIES_ROW] += 1

	return 1
End

/// @brief Get a string entry from the hashmap
///
/// Complexity: Amortized O(1)
///
/// @retval value string value found
/// @retval found 1 if something was found, 0 if not
threadsafe Function [string value, variable found] HM_GetEntryAsString(WAVE/WAVE hashmap, string key)

	variable bucketIndex, keyIndex, entriesWithHash

	bucketIndex = HM_HashKey(hashmap, key)

	[WAVE usedRows, WAVE/T keys, WAVE values] = HM_FetchWaves(hashmap, bucketIndex)

	entriesWithHash = usedRows[bucketIndex]

	keyIndex = HM_GetKeyIndex(keys, key, entriesWithHash)

	if(keyIndex >= 0)
		ASSERT_TS(IsTextWave(values), "Wave type of the values wave must be text.")
		return [WaveText(values, row = keyIndex), 1]
	endif

	return ["", 0]
End

/// @brief Get a numeric entry from the hashmap
///
/// Complexity: Amortized O(1)
///
/// @retval value value found
/// @retval found 1 if something was found, 0 if not
threadsafe Function [variable value, variable found] HM_GetEntryAsNumber(WAVE/WAVE hashmap, string key)

	variable bucketIndex, keyIndex, entriesWithHash

	bucketIndex = HM_HashKey(hashmap, key)

	[WAVE usedRows, WAVE/T keys, WAVE values] = HM_FetchWaves(hashmap, bucketIndex)

	entriesWithHash = usedRows[bucketIndex]

	keyIndex = HM_GetKeyIndex(keys, key, entriesWithHash)

	if(keyIndex >= 0)
		ASSERT_TS(IsNumericWave(values), "Wave type of the values wave must be numeric.")
		return [values[keyIndex], 1]
	endif

	// not returning NaN here as the wave type of values might not be floating point
	return [0, 0]
End

/// @brief Delete the entry with the given key
///
/// Complexity: Amortized O(1)
///
/// @return 0 on success, 1 if the key could not be found
threadsafe Function HM_DeleteEntry(WAVE/WAVE hashmap, string key)

	variable keyIndex, bucketIndex, entriesWithHash, isStr

	bucketIndex = HM_HashKey(hashmap, key)

	[WAVE usedRows, WAVE/T keys, WAVE values] = HM_FetchWaves(hashmap, bucketIndex)

	entriesWithHash = usedRows[bucketIndex]

	keyIndex = HM_GetKeyIndex(keys, key, entriesWithHash)

	if(!(keyIndex >= 0))
		return 1
	endif

	isStr = IsTextWave(values)

	if(entriesWithHash > 1 && (keyIndex + 1) != entriesWithHash)
		// move all keys and values in the range [keyIndex + 1, entriesWithHash - 1]
		// one element to the left
		keys[keyIndex, entriesWithHash - 2] = keys[p + 1]

		if(isStr)
			WAVE/T valuesText = values
			valuesText[keyIndex, entriesWithHash - 2] = valuesText[p + 1]
		else
			values[keyIndex, entriesWithHash - 2] = values[p + 1]
		endif
	endif

	// clear last key/value pair
	keys[entriesWithHash - 1] = ""

	if(isStr)
		WAVE/T valuesText = values
		valuesText[entriesWithHash - 1] = ""
	else
		values[entriesWithHash - 1] = 0
	endif

	usedRows[bucketIndex] = entriesWithHash - 1

	WAVE totalEntries = HM_FetchStats(hashmap)
	totalEntries[HM_TOTAL_ENTRIES_ROW] -= 1

	return 0
End

/// @brief Return all keys in the hashmap
///
/// Complexity: O(n)
threadsafe Function/WAVE HM_GetAllKeys(WAVE/WAVE hashmap)

	variable numThreads, numPossibleEntries

	numPossibleEntries = HM_GetSize(hashmap)

	numThreads = GetNumberOfUsefulThreads({numPossibleEntries})

	Make/FREE/WAVE/N=(numPossibleEntries) allKeysWR

	WAVE usedRows = HM_FetchUsedRows(hashmap)
	Multithread/NT=(numThreads) allKeysWR[] = HM_GetAllKeysPerRow(hashmap, p, usedRows[p])

	Concatenate/NP=(ROWS)/FREE/T {allKeysWR}, allKeys

	if(DimSize(allKeys, ROWS) == 0)
		return $""
	endif

	return allKeys
End

threadsafe static Function/WAVE HM_GetAllKeysPerRow(WAVE/WAVE hashmap, variable index, variable entriesWithHash)

	if(entriesWithHash == 0)
		return NewFreeWave(IGOR_TYPE_TEXT_WREF_DFR, 0)
	endif

	WAVE/T keys = HM_FetchKeys(hashmap, index)

	Duplicate/FREE/RMD=[0, entriesWithHash - 1]/T keys, filledKeys

	return filledKeys
End

/// @brief Calculate the load factor from the hashmap and the filled entries
///
/// Complexity: O(1)
threadsafe static Function HM_CalculateLoadFactor(WAVE/WAVE hashmap)

	WAVE totalEntries = HM_FetchStats(hashmap)

	return totalEntries[HM_TOTAL_ENTRIES_ROW] / HM_GetSize(hashmap)
End

/// @brief Calculate the optimum size for the hashmap so that the load factor is below (#HM_MAX_LOAD_FACTOR / 2)
///
/// Complexity: O(1)
threadsafe Function HM_CalculateOptimumSize(variable totalEntries)

	totalEntries = max(1, totalEntries)

	return 2^ceil(log(totalEntries / (HM_MAX_LOAD_FACTOR / 2)) / log(2))
End

/// @brief Rehashes if required and returns a modified hashmap pass-by-reference
///
/// The load factor (number of available entries vs filled entries) is determined.
/// And if that is above #HM_MAX_LOAD_FACTOR we create a new hashmap with a large enough size and
/// add all existing entries to it.
///
/// Complexity: Usually amortized O(1) but in the worst case O(n)
///
/// @return 0 if nothing needed to be done, 1 if the hashmap was resized and rehashed
threadsafe Function HM_RehashIfRequired(WAVE/WAVE &hashmap)

	variable loadFactor, newSize, srcIdx, entriesWithHash, i, srcNumEntries, isStr

	loadFactor = HM_CalculateLoadFactor(hashmap)

	if(loadFactor < HM_MAX_LOAD_FACTOR)
		// all good
		return 0
	endif

	WAVE values = HM_FetchValues(hashmap, 0)
	isStr = IsTextWave(values)

	WAVE totalEntries = HM_FetchStats(hashmap)

	srcNumEntries = HM_GetSize(hashmap)
	newSize       = HM_CalculateOptimumSize(totalEntries[HM_TOTAL_ENTRIES_ROW])
	ASSERT_TS(newSize > srcNumEntries, "Invalid size calculation")
	WAVE/WAVE hashmapLarger = HM_Create(size = newSize, valueType = WaveType(values))

	WAVE usedRows = HM_FetchUsedRows(hashmap)

	for(srcIdx = 0; srcIdx < srcNumEntries; srcIdx += 1)
		entriesWithHash = usedRows[srcIdx]

		if(entriesWithHash == 0)
			continue
		endif

		WAVE/T keys   = HM_FetchKeys(hashmap, srcIdx)
		WAVE   values = HM_FetchValues(hashmap, srcIdx)

		for(i = 0; i < entriesWithHash; i += 1)
			if(isStr)
				HM_AddEntry(hashmapLarger, keys[i], str = WaveText(values, row = i))
			else
				HM_AddEntry(hashmapLarger, keys[i], var = values[i])
			endif
		endfor
	endfor

	if(IsFreeWave(hashmap))
		WAVE hashmap = hashmapLarger
	else
		// we don't want it recursive as the contained waves are free
		// so we don't have to duplicate those
		WAVE result  = MoveWaveWithOverwrite(hashmap, hashmapLarger)
		WAVE hashmap = result
	endif

	return 1
End

/// @brief Create a hashmap and fill it with `entries` and their indizes
///
/// @param entries       wave with the entries to be added, can be a null wave iff numEntries is zero. Empty entries are ignored.
/// @param numEntries    number of values to read from entries
/// @param valueType     type of the values in the hashmap, see #HM_Create
/// @param minSize       minimum size of the created hashmap, required to be a power of two
/// @param caseSensitive [optional, defaults to true] lower case all keys if false, don't touch them if true
///
/// @return hashmap with the content from entries as keys and their indizes as values
threadsafe Function/WAVE HM_GetHashmapFromEntriesAndIndizes(WAVE/Z/T entries, variable numEntries, variable valueType, variable minSize, [variable caseSensitive])

	variable size

	if(ParamIsDefault(caseSensitive))
		caseSensitive = 1
	else
		caseSensitive = !!caseSensitive
	endif

	size = max(minSize, HM_CalculateOptimumSize(numEntries))
	WAVE hashmap = HM_Create(size = size, valueType = valueType)

	if(numEntries == 0)
		return hashmap
	endif

	ASSERT_TS(WaveExists(entries), "Missing entries wave")
	ASSERT_TS(IsInteger(numEntries) && numEntries > 0 && numEntries <= DimSize(entries, ROWS), "numEntries must be an integer and within the range of entries' rows")

	// can't use GetTemporareWave here as that uses the cache and we are also used from the cache
	Make/FREE/B/N=(numEntries) indexHelper

	indexHelper[] = (strlen(entries[p]) > 0) ? HM_AddEntry(hashmap, SelectString(caseSensitive, LowerStr(entries[p]), entries[p]), var = p) : 0

	return hashmap
End
