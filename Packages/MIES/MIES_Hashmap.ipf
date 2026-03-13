#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_HM
#endif // AUTOMATED_TESTING

static Constant HM_SMALL_WAVE_OPTIMIZATION_ROWS = 5
static Constant HM_MAX_LOAD_FACTOR              = 0.7

/// @file MIES_Hashmap.ipf
///
/// Pure Igor Pro implementation of a hashmap using separate chaining.
///
/// Features:
/// - Supports all sizes which are a power of two
/// - Constant time access O(1) with small load factors
/// - Handles collisions correctly
/// - Avoids implicit rehashing but supports explicit rehashing

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
// 				HM_AddEntry(indizesHM, name, num2str(j))
// 			endfor
// 		endfor
//
// 		elapsed                                  = (stopmSTimer(-2) - ref) * MICRO_TO_ONE / numRunsWrite / size
// 		resultWave[%TextWaveHashTB][%Writing][e] = elapsed
//
// 		ref = stopmSTimer(-2)
// 		for(i = 0; i < NUM_RUNS_READ; i += 1)
// 			name            = "abcd" + num2str(indizes[i])
// 			[output, found] = HM_GetEntry(indizesHM, name)
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

	size = DimSize(hashmap, ROWS) - 1

	// force integer evaluation
	result = h & size

	return result
End

threadsafe static Function HM_GetKeyIndex(WAVE/T keys, string key, variable numFilledEntries)

	variable i

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

/// @brief Return a wave reference wave resembling a hashmap
///
/// Rows:
///  - `size` rows with the first bits of the hash
///
/// Columns:
/// - 0: 32bit-unsigned integer wave with one point holding parts of the key's hash
/// - 1: 1D text wave with all keys for this hash
/// - 2: 1D text wave with all values for this hash
///
/// Complexity: O(n)
///
/// @param size size of the hashmap, needs to be a power of two
threadsafe Function/WAVE HM_Create([variable size])

	variable numThreads

	if(ParamIsDefault(size))
		size = 2^16
	else
		ASSERT_TS(IsPower(size, 2), "size must be a power of two")
	endif

	Make/FREE/WAVE/N=(size, 3) hashmap

	numThreads = GetNumberOfUsefulThreads({size, 3})

	// 32-bit unsigned integer
	Multithread/NT=(numThreads) hashmap[][0] = NewFreeWave(IGOR_TYPE_UNSIGNED | IGOR_TYPE_32BIT_INT, 1)

	// both text waves
	Multithread/NT=(numThreads) hashmap[][1] = NewFreeWave(IGOR_TYPE_TEXT_WREF_DFR, 2)
	Multithread/NT=(numThreads) hashmap[][2] = NewFreeWave(IGOR_TYPE_TEXT_WREF_DFR, 2)

	return hashmap
End

/// @brief Add an entry into the hashmap
///
/// Complexity: Amortized O(1)
///
/// @return 1 when adding a new value and 0 when overwriting
threadsafe Function HM_AddEntry(WAVE/WAVE hashmap, string key, string value)

	variable idx, entriesWithHash, keyIndex

	idx = HM_HashKey(hashmap, key)

	WAVE   usedRows = hashmap[idx][0]
	WAVE/T keys     = hashmap[idx][1]
	WAVE/T values   = hashmap[idx][2]

	entriesWithHash = usedRows[0]

	if(entriesWithHash > 0)
		keyIndex = HM_GetKeyIndex(keys, key, entriesWithHash)

		if(keyIndex >= 0)
			// overwrite existing entry
			values[keyIndex] = value
			return 0
		endif

		// no more space, need to expand keys and values
		if(entriesWithHash == DimSize(keys, ROWS))
			Redimension/N=(DimSize(keys, ROWS) * 2) keys, values
		endif
	endif

	keys[entriesWithHash]   = key
	values[entriesWithHash] = value
	usedRows[0]             = entriesWithHash + 1

	return 1
End

/// @brief Get an entry from the hashmap
///
/// Complexity: Amortized O(1)
///
/// @retval value string value found
/// @retval found 1 if something was found, 0 if not
threadsafe Function [string value, variable found] HM_GetEntry(WAVE/WAVE hashmap, string key)

	variable idx, keyIndex, entriesWithHash

	idx = HM_HashKey(hashmap, key)

	WAVE   usedRows = hashmap[idx][0]
	WAVE/T keys     = hashmap[idx][1]
	WAVE/T values   = hashmap[idx][2]

	entriesWithHash = usedRows[0]

	keyIndex = HM_GetKeyIndex(keys, key, entriesWithHash)

	if(keyIndex >= 0)
		return [values[keyIndex], 1]
	endif

	return ["", 0]
End

/// @brief Delete the entry with the given key
///
/// Complexity: Amortized O(1)
///
/// @return 0 on success, 1 if the key could not be found
threadsafe Function HM_DeleteEntry(WAVE/WAVE hashmap, string key)

	variable keyIndex, idx, entriesWithHash

	idx = HM_HashKey(hashmap, key)

	WAVE   usedRows = hashmap[idx][0]
	WAVE/T keys     = hashmap[idx][1]
	WAVE/T values   = hashmap[idx][2]

	entriesWithHash = usedRows[0]

	keyIndex = HM_GetKeyIndex(keys, key, entriesWithHash)

	if(!(keyIndex >= 0))
		return 1
	endif

	if(entriesWithHash > 1)
		// move all keys and values in the range [keyIndex + 1, entriesWithHash - 1]
		// one element to the left
		keys[keyIndex, entriesWithHash - 2]   = keys[p + 1]
		values[keyIndex, entriesWithHash - 2] = values[p + 1]
	endif

	// clear last key/value pair
	// keyIndex == 0 and entriesWithHash == 1
	keys[entriesWithHash - 1]   = ""
	values[entriesWithHash - 1] = ""

	usedRows[0] = entriesWithHash - 1

	return 0
End

/// @brief Return all keys in the hashmap
///
/// Complexity: O(n)
threadsafe Function/WAVE HM_GetAllKeys(WAVE/WAVE hashmap)

	variable idx, entriesWithHash, wvIndex

	WAVE/Z results = HM_GetFilledEntries(hashmap)

	if(!WaveExists(results))
		return $""
	endif

	Make/FREE/WAVE/N=(DimSize(results, ROWS)) allKeysTmp

	for(idx : results)
		WAVE   usedRows = hashmap[idx][0]
		WAVE/T keys     = hashmap[idx][1]

		entriesWithHash = usedRows[0]

		Duplicate/FREE/RMD=[0, entriesWithHash - 1]/T keys, filledKeys
		allKeysTmp[wvIndex] = filledKeys
		wvIndex++
	endfor

	Concatenate/NP=(ROWS)/FREE/T {allKeysTmp}, allKeys

	return allKeys
End

/// @brief Return the indizes into hashmap with one or more key/value pairs
///
/// Complexity: O(n)
threadsafe static Function/WAVE HM_GetFilledEntries(WAVE/WAVE hashmap)

	variable numThreads, numPossibleEntries

	numPossibleEntries = DimSize(hashmap, ROWS)

	numThreads = GetNumberOfUsefulThreads({numPossibleEntries})

	// not using GetTemporaryWave here to avoid issues with recursion
	Make/FREE/N=(numPossibleEntries) matches

	Multithread/NT=(numThreads) matches = (WaveRef(hashmap, row = p, col = 0)[0] > 0) ? p : NaN

	WAVE/Z result = ZapNaNs(matches)

	return result
End

/// @brief Calculate the load factor from the hashmap and the filled entries
///
/// Complexity: O(n)
threadsafe static Function HM_CalculateLoadFactor(WAVE/WAVE hashmap)

	variable numPossibleEntries, numThreads

	numPossibleEntries = DimSize(hashmap, ROWS)

	// not using GetTemporaryWave here to avoid issues with recursion
	Make/FREE/N=(numPossibleEntries) counts

	numThreads = GetNumberOfUsefulThreads({numPossibleEntries})

	Multithread/NT=(numThreads) counts = WaveRef(hashmap, row = p, col = 0)[0]

	return Sum(counts) / numPossibleEntries
End

/// @brief Rehashes if required and returns a modified hashmap pass-by-reference
///
/// The load factor (number of available entries vs filled entries) is determined.
/// And if that is above #HM_MAX_LOAD_FACTOR we create a new hashmap with the doubled size and
/// readd all existing entries.
///
/// Complexity: O(n)
///
/// @return 0 if nothing needed to be done, 1 if the hashmap was resized and rehashed
threadsafe Function HM_RehashIfRequired(WAVE/WAVE &hashmap)

	variable loadFactor, newSize, srcIdx, entriesWithHash, i, srcNumEntries

	loadFactor = HM_CalculateLoadFactor(hashmap)

	if(loadFactor < HM_MAX_LOAD_FACTOR)
		// all good
		return 0
	endif

	srcNumEntries = DimSize(hashmap, ROWS)
	newSize       = 2 * srcNumEntries
	WAVE/WAVE hashmapLarger = HM_Create(size = newSize)

	for(srcIdx = 0; srcIdx < srcNumEntries; srcIdx += 1)
		WAVE usedRows = hashmap[srcIdx][0]

		entriesWithHash = usedRows[0]

		if(entriesWithHash == 0)
			continue
		endif

		for(i = 0; i < entriesWithHash; i += 1)
			WAVE/T keys   = hashmap[srcIdx][1]
			WAVE/T values = hashmap[srcIdx][2]

			HM_AddEntry(hashmapLarger, keys[i], values[i])
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
