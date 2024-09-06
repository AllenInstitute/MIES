#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTILSTEST_WAVEHANDLING

// Missing Tests for:
// EnsureSmallEnoughWave
// GetSizeOfType
// GetNumberFromWaveNote
// AddEntryIntoWaveNoteAsList
// HasEntryInWaveNoteList
// UniqueWaveName
// DuplicateSubRange
// GetRowWithSameContent
// GetColfromWavewithDimLabel
// SetDimensionLabels
// RemoveAllDimLabels
// MergeTwoWaves
// ChangeWaveLock
// RemoveTextWaveEntry1D
// SplitTextWaveBySuffix
// WaveRef
// WaveText
// DuplicateWaveToFree
// ConvertFreeWaveToPermanent
// MoveFreeWaveToPermanent
// GetDecimatedWaveSize
// GetLastNonEmptyEntry

/// EnsureLargeEnoughWave
/// @{

Function ELE_AbortsWOWave()

	try
		EnsureLargeEnoughWave($"")
		FAIL()
	catch
		PASS()
	endtry
End

Function ELE_AbortsInvalidDim()

	try
		Make/FREE wv
		EnsureLargeEnoughWave(wv, dimension = -1)
		FAIL()
	catch
		PASS()
	endtry
End

Function ELE_HasMinimumSize()

	Make/FREE/N=0 wv
	EnsureLargeEnoughWave(wv)
	CHECK_GT_VAR(DimSize(wv, ROWS), 0)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 0)
End

Function ELE_InitsToZero()

	Make/FREE/N=0 wv
	EnsureLargeEnoughWave(wv)
	CHECK_EQUAL_VAR(WaveMax(wv), 0)
	CHECK_EQUAL_VAR(WaveMin(wv), 0)
End

Function ELE_KeepsExistingData()

	Make/FREE/N=(1, 2) wv
	wv[0][0] = 4711
	EnsureLargeEnoughWave(wv)
	CHECK_EQUAL_VAR(wv[0], 4711)
	CHECK_EQUAL_VAR(Sum(wv), 4711) // others default to zero
End

Function ELE_HandlesCustomInitVal()

	Make/FREE/N=0 wv
	EnsureLargeEnoughWave(wv, initialValue = NaN)
	WaveStats/M=2/Q wv
	CHECK_EQUAL_VAR(V_npnts, 0)
End

Function ELE_HandlesCustomInitValCol()

	Make/FREE/N=(1, 2, 3) wv = NaN
	EnsureLargeEnoughWave(wv, dimension = COLS, initialValue = NaN)
	WaveStats/M=2/Q wv
	CHECK_EQUAL_VAR(V_npnts, 0)
End

Function ELE_WorksForColsAsWell()

	Make/FREE/N=1 wv
	EnsureLargeEnoughWave(wv, dimension = COLS)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 1)
	CHECK_GT_VAR(DimSize(wv, COLS), 0)
End

Function ELE_MinimumSize1()

	Make/FREE/N=100 wv
	EnsureLargeEnoughWave(wv, indexShouldExist = 1)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 100)
End

Function ELE_MinimumSize2()

	Make/FREE/N=100 wv
	EnsureLargeEnoughWave(wv, indexShouldExist = 100)
	CHECK_GT_VAR(DimSize(wv, ROWS), 100)
End

Function ELE_KeepsMinimumWaveSize1()

	Make/FREE/N=(MINIMUM_WAVE_SIZE) wv
	Duplicate/FREE wv, refWave
	EnsureLargeEnoughWave(wv)
	CHECK_EQUAL_WAVES(wv, refWave)
End

Function ELE_KeepsMinimumWaveSize2()

	Make/FREE/N=(MINIMUM_WAVE_SIZE) wv
	Duplicate/FREE wv, refWave
	EnsureLargeEnoughWave(wv, indexShouldExist = 1)
	CHECK_EQUAL_WAVES(wv, refWave)
End

Function ELE_KeepsMinimumWaveSize3()
	// need to check that the index MINIMUM_WAVE_SIZE is now accessible
	Make/FREE/N=(MINIMUM_WAVE_SIZE) wv
	EnsureLargeEnoughWave(wv, indexShouldExist = MINIMUM_WAVE_SIZE)
	CHECK_GT_VAR(DimSize(wv, ROWS), MINIMUM_WAVE_SIZE)
End

Function ELE_Returns1WithCheckMem()
	Make/FREE/N=(MINIMUM_WAVE_SIZE) wv
	CHECK_EQUAL_VAR(EnsureLargeEnoughWave(wv, indexShouldExist = 2^50, checkFreeMemory = 1), 1)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), MINIMUM_WAVE_SIZE)
End

Function ELE_AbortsWithTooLargeValue()
	Make/FREE/N=(MINIMUM_WAVE_SIZE) wv

	variable err

	try
		EnsureLargeEnoughWave(wv, indexShouldExist = 2^50); AbortOnRTE
		FAIL()
	catch
		err = GetRTError(1)
		PASS()
	endtry
End

/// @}

// GetWaveSize
/// @{

// UTF_TD_GENERATOR DataGenerators#GenerateAllPossibleWaveTypes
Function GWS_Works([WAVE wv])

	CHECK_WAVE(wv, FREE_WAVE)
	CHECK_GT_VAR(GetWaveSize(wv), 0)

	Make/N=1/FREE junkWave
	MultiThread junkWave = GetWaveSize(wv)
	CHECK_GT_VAR(junkWave[0], 0)
End

/// @}

// GetLockState
/// @{

Function GLS_Works()
	Make/FREE data

	CHECK_EQUAL_VAR(GetLockState(data), 0)

	SetWaveLock 1, data
	CHECK_EQUAL_VAR(GetLockState(data), 1)
End

Function GLS_Checks()

	try
		GetLockState($"")
		FAIL()
	catch
		PASS()
	endtry
End

/// @}

/// SetNumberInWaveNote
/// @{

Function SNWN_AbortsOnInvalidWave()

	WAVE/Z wv = $""

	try
		SetNumberInWaveNote(wv, "key", 123)
		FAIL()
	catch
		PASS()
	endtry
End

Function SNWN_AbortsOnInvalidKey()

	Make/FREE wv

	try
		SetNumberInWaveNote(wv, "", 123)
		FAIL()
	catch
		PASS()
	endtry
End

Function SNWN_ComplainsOnEmptyFormat()

	Make/FREE wv

	try
		SetNumberInWaveNote(wv, "key", 123, format = "")
		FAIL()
	catch
		PASS()
	endtry
End

Function SNWN_Works()

	string expected, actual

	Make/FREE wv
	SetNumberInWaveNote(wv, "key", 123)
	expected = "key:123;"
	actual   = note(wv)
	CHECK_EQUAL_STR(expected, actual)
End

Function SNWN_WorksWithNaN()

	string expected, actual

	Make/FREE wv
	SetNumberInWaveNote(wv, "key", NaN)
	expected = "key:NaN;"
	actual   = note(wv)
	CHECK_EQUAL_STR(expected, actual)
End

Function SNWN_LeavesOldEntries()

	string expected, actual, oldEntry

	Make/FREE wv
	// existing entry
	SetNumberInWaveNote(wv, "otherkey", 456)
	oldEntry = note(wv)

	SetNumberInWaveNote(wv, "key", 123)
	expected = oldEntry + "key:123;"
	actual   = note(wv)
	CHECK_EQUAL_STR(expected, actual)
End

Function SNWN_IntegerFormat()

	string expected, actual

	Make/FREE wv
	SetNumberInWaveNote(wv, "key", 123.456, format = "%d")
	expected = "key:123;"
	actual   = note(wv)
	CHECK_EQUAL_STR(expected, actual)
End

Function SNWN_FloatFormat()

	string expected, actual

	Make/FREE wv
	SetNumberInWaveNote(wv, "key", 123.456, format = "%.1f")
	// %f rounds
	expected = "key:123.5;"
	actual   = note(wv)
	CHECK_EQUAL_STR(expected, actual)
End

Function SNWN_FloatFormatWithZeros()

	string expected, actual

	Make/FREE wv
	SetNumberInWaveNote(wv, "key", 123.1, format = "%.06f")
	// %f rounds
	expected = "key:123.100000;"
	actual   = note(wv)
	CHECK_EQUAL_STR(expected, actual)
End

/// @}

/// GetStringFromWaveNote
/// @{

Function GSFWNR_Works()
	string ref, str

	// non-wave ref
	Make/FREE plain
	Note/K plain, "abcd:123"

	ref = "123"
	str = GetStringFromWaveNote(plain, "abcd", recursive = 1)
	CHECK_EQUAL_STR(ref, str)

	// empty wave ref
	Make/WAVE/FREE/N=0 wref
	Note/K wref, "abcd:123"

	ref = "123"
	str = GetStringFromWaveNote(wref, "abcd", recursive = 1)
	CHECK_EQUAL_STR(ref, str)

	// wave ref, matching
	Make/WAVE/FREE/N=2 wref
	wref[] = NewFreeWave(IGOR_TYPE_32BIT_FLOAT, 0)
	Note/K wref, "abcd:123"
	Note/K wref[0], "abcd:123"
	Note/K wref[1], "abcd:123"

	ref = "123"
	str = GetStringFromWaveNote(wref, "abcd", recursive = 1)
	CHECK_EQUAL_STR(ref, str)

	// wave ref 2D, matching
	Make/WAVE/FREE/N=(2, 2) wref
	wref[] = NewFreeWave(IGOR_TYPE_32BIT_FLOAT, 0)
	Note/K wref, "abcd:123"
	Note/K wref[0], "abcd:123"
	Note/K wref[1], "abcd:123"
	Note/K wref[2], "abcd:123"
	Note/K wref[3], "abcd:123"

	ref = "123"
	str = GetStringFromWaveNote(wref, "abcd", recursive = 1)
	CHECK_EQUAL_STR(ref, str)

	// wave ref, not-matching (wref has a different one)
	Make/WAVE/FREE/N=2 wref
	wref[] = NewFreeWave(IGOR_TYPE_32BIT_FLOAT, 0)
	Note/K wref, "abcde:123"
	Note/K wref[0], "abcd:123"
	Note/K wref[1], "abcd:123"

	str = GetStringFromWaveNote(wref, "abcd", recursive = 1)
	CHECK_EMPTY_STR(str)

	// wave ref, not-matching (first contained has a different one)
	Make/WAVE/FREE/N=2 wref
	wref[] = NewFreeWave(IGOR_TYPE_32BIT_FLOAT, 0)
	Note/K wref, "abcd:123"
	Note/K wref[0], "abcde:123"
	Note/K wref[1], "abcd:123"

	str = GetStringFromWaveNote(wref, "abcd", recursive = 1)
	CHECK_EMPTY_STR(str)
End

/// @}

/// SetStringInWaveNote
/// @{

Function SeSt_CheckParams()
	try
		SetStringInWaveNote($"", "abcd", "123")
		FAIL()
	catch
		PASS()
	endtry

	try
		Make/FREE wv
		SetStringInWaveNote(wv, "", "123")
		FAIL()
	catch
		PASS()
	endtry
End

static Function SeSt_CheckParams2()

	string str, ref

	Make/FREE wv
	try
		SetStringInWaveNote(wv, "abcd", "123", keySep = "")
		FAIL()
	catch
		PASS()
	endtry

	try
		Make/FREE wv
		SetStringInWaveNote(wv, "abcd", "123", listSep = "")
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE wv
	SetStringInWaveNote(wv, "abcd", "123", keySep = "?", listSep = "_")
	str = note(wv)
	ref = "abcd?123_"
	CHECK_EQUAL_STR(str, ref)
End

Function SeSt_Works()
	string str, ref

	// adds entry
	Make/FREE plain

	SetStringInWaveNote(plain, "abcd", "123")
	str = note(plain)
	ref = "abcd:123;"
	CHECK_EQUAL_STR(str, ref)

	// overwrites existing entry
	Make/FREE plain
	Note/K plain, "abcd:456;"

	SetStringInWaveNote(plain, "abcd", "123")
	str = note(plain)
	ref = "abcd:123;"
	CHECK_EQUAL_STR(str, ref)

	// wave wref, non-recursive by default
	Make/WAVE/FREE/N=2 wref
	wref[] = NewFreeWave(IGOR_TYPE_32BIT_FLOAT, 0)

	SetStringInWaveNote(wref, "abcd", "123")
	str = note(wref)
	ref = "abcd:123;"
	CHECK_EQUAL_STR(str, ref)

	str = note(wref[0])
	CHECK_EMPTY_STR(str)

	str = note(wref[1])
	CHECK_EMPTY_STR(str)

	// wave wref, recursive but empty
	Make/WAVE/FREE/N=0 wref

	SetStringInWaveNote(wref, "abcd", "123")
	str = note(wref)
	ref = "abcd:123;"
	CHECK_EQUAL_STR(str, ref)

	// wave wref 2D, recursive
	Make/WAVE/FREE/N=(2, 2) wref
	wref[] = NewFreeWave(IGOR_TYPE_32BIT_FLOAT, 0)

	SetStringInWaveNote(wref, "abcd", "123", recursive = 1)

	str = note(wref)
	ref = "abcd:123;"
	CHECK_EQUAL_STR(str, ref)

	str = note(wref[0])
	ref = "abcd:123;"
	CHECK_EQUAL_STR(str, ref)

	str = note(wref[1])
	ref = "abcd:123;"
	CHECK_EQUAL_STR(str, ref)

	str = note(wref[2])
	ref = "abcd:123;"
	CHECK_EQUAL_STR(str, ref)

	str = note(wref[3])
	ref = "abcd:123;"
	CHECK_EQUAL_STR(str, ref)
End

/// @}

/// MakeWaveFree
/// @{

static Function MWF_Works()

	WAVE/Z result = MakeWaveFree($"")
	CHECK_WAVE(result, NULL_WAVE)

	Make data
	CHECK_WAVE(data, NORMAL_WAVE)
	WAVE/Z result = MakeWaveFree(data)
	CHECK_WAVE(result, FREE_WAVE)
	CHECK(WaveRefsEqual(data, result))

	Make/FREE data
	CHECK_WAVE(result, FREE_WAVE)
	WAVE/Z result = MakeWaveFree(data)
	CHECK_WAVE(result, FREE_WAVE)
	CHECK(WaveRefsEqual(data, result))
End

/// @}

/// MakeDataFolderFree
/// @{

#if IgorVersion() >= 10

static Function MDF_Works()

	DFREF result = MakeDataFolderFree($"")
	CHECK(!DataFolderExistsDFR(result))

	NewDataFolder folder
	DFREF dfr = folder
	variable/G dfr:var
	CHECK(DataFolderExistsDFR(dfr))
	DFREF result = MakeDataFolderFree(dfr)
	CHECK(IsFreeDataFolder(result))
	CHECK(DataFolderRefsEqual(dfr, result))
	CHECK_EQUAL_STR("var;", VariableList("*", ";", 4, result))

	DFREF dfr = NewFreeDataFolder()
	variable/G dfr:var
	CHECK(DataFolderExistsDFR(dfr))
	CHECK(IsFreeDataFolder(result))
	DFREF result = MakeDataFolderFree(dfr)
	CHECK(IsFreeDataFolder(result))
	CHECK(DataFolderRefsEqual(dfr, result))
	CHECK_EQUAL_STR("var;", VariableList("*", ";", 4, result))
End

#endif

/// @}

/// DeepCopyWaveRefWave
/// @{

static Function TestDeepCopyWaveRefWave()

	variable i
	variable refSize  = 3
	variable dataSize = 2

	Make/FREE/WAVE/N=(refSize) src

	Make/FREE/N=(dataSize, dataSize, dataSize, dataSize) data
	src[] = data

	WAVE/WAVE cpy = DeepCopyWaveRefWave(src)
	CHECK_EQUAL_VAR(DimSize(src, ROWS), refSize)
	for(i = 0; i < dataSize; i += 1)
		CHECK_EQUAL_WAVES(src[i], cpy[i])
		CHECK_EQUAL_VAR(WaveRefsEqual(src[i], cpy[i]), 0)
	endfor

	WAVE/WAVE cpy = DeepCopyWaveRefWave(src, dimension = CHUNKS, index = dataSize - 1)
	CHECK_EQUAL_VAR(DimSize(src, ROWS), refSize)
	Make/FREE/N=(dataSize, dataSize, dataSize) dataRef
	for(i = 0; i < dataSize; i += 1)
		CHECK_EQUAL_WAVES(dataRef, cpy[i])
	endfor

	WAVE/WAVE cpy = DeepCopyWaveRefWave(src, dimension = LAYERS, index = dataSize - 1)
	CHECK_EQUAL_VAR(DimSize(src, ROWS), refSize)
	Make/FREE/N=(dataSize, dataSize, dataSize, dataSize) wv
	Duplicate/FREE/R=[][][dataSize - 1][] wv, dataRef
	for(i = 0; i < dataSize; i += 1)
		CHECK_EQUAL_WAVES(dataRef, cpy[i])
	endfor

	Make/FREE/N=(refSize) indexWave = p
	WAVE/WAVE cpy = DeepCopyWaveRefWave(src, dimension = LAYERS, indexWave = indexWave)
	CHECK_EQUAL_VAR(DimSize(src, ROWS), refSize)
	Make/FREE/N=(dataSize, dataSize, dataSize, dataSize) wv
	Duplicate/FREE/R=[][][0][] wv, dataRef0
	Duplicate/FREE/R=[][][1][] wv, dataRef1
	Duplicate/FREE/R=[][][2][] wv, dataRef2
	CHECK_EQUAL_WAVES(dataRef0, cpy[0])
	CHECK_EQUAL_WAVES(dataRef1, cpy[1])
	CHECK_EQUAL_WAVES(dataRef2, cpy[2])

	Make/FREE/N=(dataSize) data
	src[] = data
	WAVE/WAVE cpy = DeepCopyWaveRefWave(src, dimension = ROWS, index = dataSize - 1)
	CHECK_EQUAL_VAR(DimSize(src, ROWS), refSize)
	Make/FREE/N=(dataSize) wv
	Duplicate/FREE/R=[dataSize - 1][][][] wv, dataRef
	for(i = 0; i < dataSize; i += 1)
		CHECK_EQUAL_WAVES(dataRef, cpy[i])
	endfor

	try
		WAVE/WAVE cpy = DeepCopyWaveRefWave(src, dimension = ROWS, index = 0, indexWave = indexWave); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	try
		WAVE/WAVE cpy = DeepCopyWaveRefWave(src, dimension = NaN); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	try
		WAVE/WAVE cpy = DeepCopyWaveRefWave(src, index = 0); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE/N=(refSize + 1) indexWave = p
	try
		WAVE/WAVE cpy = DeepCopyWaveRefWave(src, dimension = ROWS, indexWave = indexWave); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE/N=(refSize + 1)/T indexWaveT
	try
		WAVE/WAVE cpy = DeepCopyWaveRefWave(src, dimension = ROWS, indexWave = indexWaveT); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE/N=0 invalidSrc0
	try
		WAVE/WAVE cpy = DeepCopyWaveRefWave(invalidSrc0); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE/WAVE/N=(1, 1) invalidSrc1
	WAVE/WAVE cpy = DeepCopyWaveRefWave(invalidSrc1)
	CHECK_EQUAL_WAVES(GetWaveDimensions(cpy), {1, 1, 0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(cpy[0], NULL_WAVE)

	Make/FREE/WAVE/N=(1) invalidSrc2
	WAVE/WAVE cpy = DeepCopyWaveRefWave(invalidSrc2)
	CHECK_EQUAL_WAVES(GetWaveDimensions(cpy), {1, 0, 0, 0}, mode = WAVE_DATA)
	CHECK_WAVE(cpy[0], NULL_WAVE)

	WAVE src = $""
	try
		WAVE/WAVE cpy = DeepCopyWaveRefWave(src); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

/// @}

/// ReduceWaveDimensionality
/// @{

static Function TestReduceWaveDimensionality()

	Make/FREE/N=0 data
	ReduceWaveDimensionality(data)
	CHECK_EQUAL_VAR(numpnts(data), 0)

	Make/FREE/N=(1, 1, 1, 1) data
	ReduceWaveDimensionality(data)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 1)
	CHECK_EQUAL_VAR(DimSize(data, COLS), 0)

	Make/FREE/N=(1, 1, 1, 2) data
	ReduceWaveDimensionality(data)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 1)
	CHECK_EQUAL_VAR(DimSize(data, COLS), 1)
	CHECK_EQUAL_VAR(DimSize(data, LAYERS), 1)
	CHECK_EQUAL_VAR(DimSize(data, CHUNKS), 2)

	Make/FREE/N=(1, 1, 2, 1) data
	ReduceWaveDimensionality(data)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 1)
	CHECK_EQUAL_VAR(DimSize(data, COLS), 1)
	CHECK_EQUAL_VAR(DimSize(data, LAYERS), 2)
	CHECK_EQUAL_VAR(DimSize(data, CHUNKS), 0)

	Make/FREE/N=(1, 2, 1, 1) data
	ReduceWaveDimensionality(data)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 1)
	CHECK_EQUAL_VAR(DimSize(data, COLS), 2)
	CHECK_EQUAL_VAR(DimSize(data, LAYERS), 0)

	Make/FREE/N=(2, 1, 1, 1) data
	ReduceWaveDimensionality(data)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 2)
	CHECK_EQUAL_VAR(DimSize(data, COLS), 0)

	Make/FREE/N=(1, 1, 1, 1) data
	ReduceWaveDimensionality(data, minDimension = CHUNKS)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 1)
	CHECK_EQUAL_VAR(DimSize(data, COLS), 1)
	CHECK_EQUAL_VAR(DimSize(data, LAYERS), 1)
	CHECK_EQUAL_VAR(DimSize(data, CHUNKS), 0)

	Make/FREE/N=(1, 1, 1, 1) data
	ReduceWaveDimensionality(data, minDimension = LAYERS)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 1)
	CHECK_EQUAL_VAR(DimSize(data, COLS), 1)
	CHECK_EQUAL_VAR(DimSize(data, LAYERS), 0)

	Make/FREE/N=(1, 1, 1, 1) data
	ReduceWaveDimensionality(data, minDimension = COLS)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 1)
	CHECK_EQUAL_VAR(DimSize(data, COLS), 0)

	Make/FREE/N=(1, 1, 1, 1) data
	ReduceWaveDimensionality(data, minDimension = ROWS)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 1)
	CHECK_EQUAL_VAR(DimSize(data, COLS), 0)

	try
		ReduceWaveDimensionality(data, minDimension = NaN); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	try
		ReduceWaveDimensionality(data, minDimension = -1); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	try
		ReduceWaveDimensionality(data, minDimension = 1.5); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	try
		ReduceWaveDimensionality(data, minDimension = Inf); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	WAVE data = $""
	ReduceWaveDimensionality(data)
	CHECK_EQUAL_VAR(WaveExists(data), 0)
End

/// @}

// WaveModCountWrapper
/// @{

Function WMCW_ChecksMainThread()
	variable val

	Make/FREE data

	try
		WaveModCountWrapper(data)
		FAIL()
	catch
		PASS()
	endtry
End

#ifndef THREADING_DISABLED

threadsafe Function WMCW_ChecksPreemptiveThreadHelper(WAVE wv)

	try
		WaveModCountWrapper(wv)
		return Inf
	catch
		return 0
	endtry
End

Function WMCW_ChecksPreemptiveThread()

	Make/O data
	Make/FREE junkWave
	MultiThread junkWave = WMCW_ChecksPreemptiveThreadHelper(data)

	WaveStats/Q/M=2 junkWave
	CHECK_EQUAL_VAR(V_numNaNs, 0)
	CHECK_EQUAL_VAR(V_numInfs, 0)
	CHECK_EQUAL_VAR(V_Sum, 0)

	KillWaves/Z data
End

Function WMCW_Works1()
	variable val

	Make/O data
	val   = WaveModCountWrapper(data)
	data += 1
	CHECK_EQUAL_VAR(val + 1, WaveModCountWrapper(data))

	KillWaves/Z data
End

Function WMCW_Works2()
	variable val

	Make/FREE data
	Make/FREE junkWave
	MultiThread junkWave = WaveModCountWrapper(data)

	WaveStats/Q/M=2 junkWave
	CHECK_EQUAL_VAR(V_numNans, DimSize(junkWave, ROWS))
End

#endif // THREADING_DISABLED

/// @}

/// DeleteWavePoint
/// @{

Function DWP_InvalidWave()

	WAVE/Z wv = $""
	try
		DeleteWavePoint(wv, ROWS, index = 0)
		FAIL()
	catch
		PASS()
	endtry
End

Function DWP_InvalidDim()

	variable i

	Make/FREE/N=1 wv
	Make/FREE/N=4 fDims = {-1, 1, 2, 3, 5, NaN, Inf}

	for(i = 0; i < numpnts(fDims); i += 1)
		try
			DeleteWavePoint(wv, fDims[i], index = 0)
			FAIL()
		catch
			PASS()
		endtry
	endfor
End

Function DWP_InvalidIndex()

	variable i

	Make/FREE/N=1 wv
	Make/FREE/N=4 fInd = {-1, 2, NaN, Inf}

	for(i = 0; i < numpnts(fInd); i += 1)
		try
			DeleteWavePoint(wv, ROWS, index = fInd[i])
			FAIL()
		catch
			PASS()
		endtry
	endfor
End

static Function DWP_NoArg()

	Make/FREE/N=1 wv
	try
		DeleteWavePoint(wv, ROWS)
		FAIL()
	catch
		PASS()
	endtry
End

static Function DWP_BothArgs()

	Make/FREE/N=1 wv
	try
		DeleteWavePoint(wv, ROWS, index = 0, indices = {0})
		FAIL()
	catch
		PASS()
	endtry
End

static Function DWP_IndicesDontExist()

	Make/FREE/N=1 wv
	try
		DeleteWavePoint(wv, ROWS, indices = $"")
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE/N=0 indices
	try
		DeleteWavePoint(wv, ROWS, indices = indices)
		FAIL()
	catch
		PASS()
	endtry
End

static Function DWP_InvalidIndices()

	variable i

	Make/FREE/N=1 wv
	Make/FREE/N=4 fInd = {-1, 2, NaN, Inf}

	try
		DeleteWavePoint(wv, ROWS, index = fInd[i])
		FAIL()
	catch
		PASS()
	endtry
End

Function DWP_DeleteFromEmpty()

	variable i

	Make/FREE/N=0 wv

	try
		DeleteWavePoint(wv, ROWS, index = 0)
		FAIL()
	catch
		PASS()
	endtry
End

Function DWP_Check1D()

	Make/FREE/N=3 wv = {0, 1, 2}
	DeleteWavePoint(wv, ROWS, index = 1)
	CHECK_EQUAL_WAVES(wv, {0, 2})
	DeleteWavePoint(wv, ROWS, index = 1)
	CHECK_EQUAL_WAVES(wv, {0})
	DeleteWavePoint(wv, ROWS, index = 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 0)
End

static Function DWP_Check1DIndices()

	Make/FREE/N=3 wv = {0, 1, 2}
	DeleteWavePoint(wv, ROWS, indices = {1})
	CHECK_EQUAL_WAVES(wv, {0, 2})
	DeleteWavePoint(wv, ROWS, indices = {1})
	CHECK_EQUAL_WAVES(wv, {0})
	DeleteWavePoint(wv, ROWS, indices = {0})
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 0)

	Make/FREE/N=3 wv = {0, 1, 2}
	DeleteWavePoint(wv, ROWS, indices = {0, 1})
	CHECK_EQUAL_WAVES(wv, {2})
End

Function DWP_Check2D()

	Make/FREE/N=(3, 3) wv
	wv = p + DimSize(wv, COLS) * q
	DeleteWavePoint(wv, ROWS, index = 1)
	CHECK_EQUAL_WAVES(wv, {{0, 2}, {3, 5}, {6, 8}})
	DeleteWavePoint(wv, ROWS, index = 1)
	CHECK_EQUAL_WAVES(wv, {{0}, {3}, {6}})
	DeleteWavePoint(wv, ROWS, index = 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 0)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 3)

	Make/FREE/N=(3, 3) wv
	wv = p + DimSize(wv, COLS) * q
	DeleteWavePoint(wv, COLS, index = 1)
	CHECK_EQUAL_WAVES(wv, {{0, 1, 2}, {6, 7, 8}})
	DeleteWavePoint(wv, COLS, index = 1)
	CHECK_EQUAL_WAVES(wv, {{0, 1, 2}})
	DeleteWavePoint(wv, COLS, index = 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 0)
End

Function DWP_Check3D()

	Make/FREE/N=(3, 3, 3) wv
	wv = p + DimSize(wv, COLS) * q + DimSize(wv, COLS) * DimSize(wv, LAYERS) * r
	DeleteWavePoint(wv, ROWS, index = 1)
	CHECK_EQUAL_WAVES(wv, {{{0, 2}, {3, 5}, {6, 8}}, {{9, 11}, {12, 14}, {15, 17}}, {{18, 20}, {21, 23}, {24, 26}}})
	DeleteWavePoint(wv, ROWS, index = 1)
	CHECK_EQUAL_WAVES(wv, {{{0}, {3}, {6}}, {{9}, {12}, {15}}, {{18}, {21}, {24}}})
	DeleteWavePoint(wv, ROWS, index = 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 0)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, LAYERS), 3)

	Make/FREE/N=(3, 3, 3) wv
	wv = p + DimSize(wv, COLS) * q + DimSize(wv, COLS) * DimSize(wv, LAYERS) * r
	DeleteWavePoint(wv, COLS, index = 1)
	CHECK_EQUAL_WAVES(wv, {{{0, 1, 2}, {6, 7, 8}}, {{9, 10, 11}, {15, 16, 17}}, {{18, 19, 20}, {24, 25, 26}}})
	DeleteWavePoint(wv, COLS, index = 1)
	CHECK_EQUAL_WAVES(wv, {{{0, 1, 2}}, {{9, 10, 11}}, {{18, 19, 20}}})
	DeleteWavePoint(wv, COLS, index = 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 0)
	CHECK_EQUAL_VAR(DimSize(wv, LAYERS), 3)

	Make/FREE/N=(3, 3, 3) wv
	wv = p + DimSize(wv, COLS) * q + DimSize(wv, COLS) * DimSize(wv, LAYERS) * r
	DeleteWavePoint(wv, LAYERS, index = 1)
	CHECK_EQUAL_WAVES(wv, {{{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}, {{18, 19, 20}, {21, 22, 23}, {24, 25, 26}}})
	DeleteWavePoint(wv, LAYERS, index = 1)
	CHECK_EQUAL_WAVES(wv, {{{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}})
	DeleteWavePoint(wv, LAYERS, index = 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, LAYERS), 0)
End

Function DWP_Check4D()

	Make/FREE/N=(3, 3, 3, 3) wv
	wv = p + DimSize(wv, COLS) * q + DimSize(wv, COLS) * DimSize(wv, LAYERS) * r + +DimSize(wv, COLS) * DimSize(wv, LAYERS) * DimSize(wv, CHUNKS) * s

	DeleteWavePoint(wv, ROWS, index = 1)
	Make/FREE/N=(2, 3, 3, 3) comp
	comp[][][][0] = {{{0, 2}, {3, 5}, {6, 8}}, {{9, 11}, {12, 14}, {15, 17}}, {{18, 20}, {21, 23}, {24, 26}}}
	comp[][][][1] = {{{27, 29}, {30, 32}, {33, 35}}, {{36, 38}, {39, 41}, {42, 44}}, {{45, 47}, {48, 50}, {51, 53}}}
	comp[][][][2] = {{{54, 56}, {57, 59}, {60, 62}}, {{63, 65}, {66, 68}, {69, 71}}, {{72, 74}, {75, 77}, {78, 80}}}
	CHECK_EQUAL_WAVES(wv, comp)

	DeleteWavePoint(wv, ROWS, index = 1)
	Make/FREE/N=(1, 3, 3, 3) comp
	comp[][][][0] = {{{0}, {3}, {6}}, {{9}, {12}, {15}}, {{18}, {21}, {24}}}
	comp[][][][1] = {{{27}, {30}, {33}}, {{36}, {39}, {42}}, {{45}, {48}, {51}}}
	comp[][][][2] = {{{54}, {57}, {60}}, {{63}, {66}, {69}}, {{72}, {75}, {78}}}
	CHECK_EQUAL_WAVES(wv, comp)

	DeleteWavePoint(wv, ROWS, index = 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 0)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, LAYERS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, CHUNKS), 3)

	Make/FREE/N=(3, 3, 3, 3) wv
	wv = p + DimSize(wv, COLS) * q + DimSize(wv, COLS) * DimSize(wv, LAYERS) * r + +DimSize(wv, COLS) * DimSize(wv, LAYERS) * DimSize(wv, CHUNKS) * s

	DeleteWavePoint(wv, COLS, index = 1)
	Make/FREE/N=(3, 2, 3, 3) comp
	comp[][][][0] = {{{0, 1, 2}, {6, 7, 8}}, {{9, 10, 11}, {15, 16, 17}}, {{18, 19, 20}, {24, 25, 26}}}
	comp[][][][1] = {{{27, 28, 29}, {33, 34, 35}}, {{36, 37, 38}, {42, 43, 44}}, {{45, 46, 47}, {51, 52, 53}}}
	comp[][][][2] = {{{54, 55, 56}, {60, 61, 62}}, {{63, 64, 65}, {69, 70, 71}}, {{72, 73, 74}, {78, 79, 80}}}
	CHECK_EQUAL_WAVES(wv, comp)

	DeleteWavePoint(wv, COLS, index = 1)
	Make/FREE/N=(3, 1, 3, 3) comp
	comp[][][][0] = {{{0, 1, 2}}, {{9, 10, 11}}, {{18, 19, 20}}}
	comp[][][][1] = {{{27, 28, 29}}, {{36, 37, 38}}, {{45, 46, 47}}}
	comp[][][][2] = {{{54, 55, 56}}, {{63, 64, 65}}, {{72, 73, 74}}}
	CHECK_EQUAL_WAVES(wv, comp)

	DeleteWavePoint(wv, COLS, index = 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 0)
	CHECK_EQUAL_VAR(DimSize(wv, LAYERS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, CHUNKS), 3)

	Make/FREE/N=(3, 3, 3, 3) wv
	wv = p + DimSize(wv, COLS) * q + DimSize(wv, COLS) * DimSize(wv, LAYERS) * r + +DimSize(wv, COLS) * DimSize(wv, LAYERS) * DimSize(wv, CHUNKS) * s

	DeleteWavePoint(wv, LAYERS, index = 1)
	Make/FREE/N=(3, 3, 2, 3) comp
	comp[][][][0] = {{{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}, {{18, 19, 20}, {21, 22, 23}, {24, 25, 26}}}
	comp[][][][1] = {{{27, 28, 29}, {30, 31, 32}, {33, 34, 35}}, {{45, 46, 47}, {48, 49, 50}, {51, 52, 53}}}
	comp[][][][2] = {{{54, 55, 56}, {57, 58, 59}, {60, 61, 62}}, {{72, 73, 74}, {75, 76, 77}, {78, 79, 80}}}
	CHECK_EQUAL_WAVES(wv, comp)

	DeleteWavePoint(wv, LAYERS, index = 1)
	Make/FREE/N=(3, 3, 1, 3) comp
	comp[][][][0] = {{{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}}
	comp[][][][1] = {{{27, 28, 29}, {30, 31, 32}, {33, 34, 35}}}
	comp[][][][2] = {{{54, 55, 56}, {57, 58, 59}, {60, 61, 62}}}
	CHECK_EQUAL_WAVES(wv, comp)

	DeleteWavePoint(wv, LAYERS, index = 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, LAYERS), 0)
	CHECK_EQUAL_VAR(DimSize(wv, CHUNKS), 3)

	Make/FREE/N=(3, 3, 3, 3) wv
	wv = p + DimSize(wv, COLS) * q + DimSize(wv, COLS) * DimSize(wv, LAYERS) * r + +DimSize(wv, COLS) * DimSize(wv, LAYERS) * DimSize(wv, CHUNKS) * s

	DeleteWavePoint(wv, CHUNKS, index = 1)
	Make/FREE/N=(3, 3, 3, 2) comp
	comp[][][][0] = {{{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}, {{9, 10, 11}, {12, 13, 14}, {15, 16, 17}}, {{18, 19, 20}, {21, 22, 23}, {24, 25, 26}}}
	comp[][][][1] = {{{54, 55, 56}, {57, 58, 59}, {60, 61, 62}}, {{63, 64, 65}, {66, 67, 68}, {69, 70, 71}}, {{72, 73, 74}, {75, 76, 77}, {78, 79, 80}}}
	CHECK_EQUAL_WAVES(wv, comp)

	DeleteWavePoint(wv, CHUNKS, index = 1)
	Make/FREE/N=(3, 3, 3, 1) comp
	comp[][][][0] = {{{0, 1, 2}, {3, 4, 5}, {6, 7, 8}}, {{9, 10, 11}, {12, 13, 14}, {15, 16, 17}}, {{18, 19, 20}, {21, 22, 23}, {24, 25, 26}}}
	CHECK_EQUAL_WAVES(wv, comp)

	DeleteWavePoint(wv, CHUNKS, index = 0)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, COLS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, LAYERS), 3)
	CHECK_EQUAL_VAR(DimSize(wv, CHUNKS), 0)
End

/// @}

/// SelectWave
/// @{

// UTF_TD_GENERATOR DataGenerators#SW_TrueValues
Function SW_WorksWithTrue([var])
	variable var

	Make/FREE a, b
	WAVE/Z trueWave = SelectWave(var, a, b)
	CHECK_WAVE(trueWave, FREE_WAVE)
	CHECK(WaveRefsEqual(trueWave, b))
End

// UTF_TD_GENERATOR DataGenerators#SW_FalseValues
Function SW_WorksWithFalse([var])
	variable var

	Make/FREE a, b
	WAVE/Z falseWave = SelectWave(var, a, b)
	CHECK_WAVE(falseWave, FREE_WAVE)
	CHECK(WaveRefsEqual(falseWave, a))
End

/// @}

/// RemoveUnusedRows
/// @{

Function RUR_WorksWithRandomWave()

	Make/FREE wv

	WAVE ret = RemoveUnusedRows(wv)
	CHECK(WaveRefsEqual(ret, wv))
End

Function RUR_ChecksNote1()

	Make/FREE wv
	SetNumberInWaveNote(wv, NOTE_INDEX, -1)

	try
		RemoveUnusedRows(wv); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

Function RUR_ChecksNote2()

	Make/FREE wv
	SetNumberInWaveNote(wv, NOTE_INDEX, Inf)

	try
		RemoveUnusedRows(wv); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

Function RUR_ReturnsAlwaysAWave()

	Make/FREE wv
	SetNumberInWaveNote(wv, NOTE_INDEX, 0)

	WAVE dup = RemoveUnusedRows(wv)
	CHECK_EQUAL_WAVES(dup, {0}, mode = WAVE_DATA | WAVE_DATA_TYPE | DIMENSION_SIZES)
End

Function RUR_Works()

	Make/FREE/N=(10, 3, 2) wv
	SetNumberInWaveNote(wv, NOTE_INDEX, 4)

	WAVE dup = RemoveUnusedRows(wv)

	WAVE dims = GetWaveDimensions(dup)
	CHECK_EQUAL_WAVES(dims, {4, 3, 2, 0}, mode = WAVE_DATA)
	CHECK(!WaveRefsEqual(wv, dup))
End

/// @}

// ZapNaNs
/// @{

Function ZN_AbortsWithInvalidWaveInput()

	try
		Make/FREE/T wv
		ZapNaNs(wv); AbortONRTE
		FAIL()
	catch
		PASS()
	endtry
End

Function ZN_EmptyToNull()

	Make/FREE/N=0 wv
	WAVE/Z reduced = ZapNaNs(wv)
	CHECK_WAVE(reduced, NULL_WAVE)
End

Function ZN_AllNaNToNull()

	Make/FREE/N=2 wv = {NaN, NaN}
	WAVE/Z reduced = ZapNaNs(wv)
	CHECK_WAVE(reduced, NULL_WAVE)
End

Function ZN_RemovesNaNs()

	Make/FREE wv = {NaN, Inf, 1}
	WAVE/Z reduced = ZapNaNs(wv)
	CHECK_EQUAL_WAVES(reduced, {Inf, 1})
End

Function ZN_RemovesNaNs2D()

	// row is NaN
	Make/FREE wv = {{NaN, Inf}, {NaN, 1}}
	WAVE/Z reduced = ZapNaNs(wv)
	CHECK_EQUAL_WAVES(reduced, {Inf, 1})

	// column is NaN
	Make/FREE wv = {{NaN, NaN}, {Inf, 1}}
	WAVE/Z reduced = ZapNaNs(wv)
	CHECK_EQUAL_WAVES(reduced, {Inf, 1})

	// single point NaN only
	Make/FREE wv = {{NaN, 2}, {Inf, 1}}
	WAVE/Z reduced = ZapNaNs(wv)
	CHECK_EQUAL_WAVES(reduced, {2, Inf, 1})

End

/// @}

/// ChangeFreeWaveName
/// @{

Function CFW_ChecksParameters()

	Make perm

	try
		ChangeFreeWaveName(perm, "abcd"); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE free

	try
		ChangeFreeWaveName(free, ""); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	try
		ChangeFreeWaveName(free, "123"); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	KillWaves/Z perm
End

Function CFW_Works1()

	string str, expected

	Make/FREE=1 wv
	CHECK_WAVE(wv, FREE_WAVE)

	expected = "wv"
	str      = NameOfWave(wv)
	CHECK_EQUAL_STR(str, expected)

	ChangeFreeWaveName(wv, "abcd")

	expected = "abcd"
	str      = NameOfWave(wv)
	CHECK_EQUAL_STR(str, expected)
End

/// @}

/// ZapNullRefs
/// @{

static Function TestZapNullRefs()

	try
		Make/FREE/T wvText
		ZapNullRefs(wvText)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	try
		Make/FREE/WAVE/N=(1, 1) wv
		ZapNullRefs(wv)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// empty
	Make/FREE/WAVE/N=0 wv
	WAVE/WAVE result = ZapNullRefs(wv)
	CHECK_WAVE(result, NULL_WAVE)

	// only nulls
	Make/FREE/WAVE wv
	WAVE/WAVE result = ZapNullRefs(wv)
	CHECK_WAVE(result, NULL_WAVE)

	// removes nulls and keeps order
	Make/FREE a, b
	Make/FREE/WAVE/N=3 wv
	wv[0] = a
	wv[2] = b

	WAVE/WAVE result = ZapNullRefs(wv)
	CHECK_WAVE(result, WAVE_WAVE)
	CHECK(WaveRefsEqual(result[0], a))
	CHECK(WaveRefsEqual(result[1], b))
End

/// @}

/// SplitWavesToDimension
/// @{

static Function TestSplitWavesToDimension()

	// bails on invalid wave
	try
		Make/FREE wv
		SplitWavesToDimension(wv)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// bails on invalid sdim parameter
	try
		Make/FREE wvData = {{1, 2}, {3, 4}}
		Make/FREE/WAVE wvRef = {wvData}
		SplitWavesToDimension(wvRef, sdim = MAX_DIMENSION_COUNT + 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// bails on invalid contained wv
	try
		Make/FREE/WAVE wvRef
		SplitWavesToDimension(wvRef)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	Make/FREE wvData1 = {{1, 2}, {3, 4}}
	Make/FREE wvData2 = {5, 6}
	Make/FREE/WAVE wvRef = {wvData1, wvData2}

	WAVE/WAVE/Z result = SplitWavesToDimension(wvRef)
	CHECK_WAVE(result, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(result, ROWS), 3)
	CHECK_EQUAL_VAR(DimSize(result, COLS), 0)
	CHECK_EQUAL_WAVES(result[0], {1, 2}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(result[1], {3, 4}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(result[2], {5, 6}, mode = WAVE_DATA)

	Make/FREE wvData1 = {{1, 2}, {3, 4}}
	Make/FREE/T wvDataTxt1 = {{"a", "b"}, {"c", "d"}}
	Make/FREE/WAVE wvRef = {wvData1, wvDataTxt1}

	WAVE/WAVE/Z result = SplitWavesToDimension(wvRef)
	CHECK_WAVE(result, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(result, ROWS), 4)
	CHECK_EQUAL_VAR(DimSize(result, COLS), 0)
	CHECK_EQUAL_WAVES(result[0], {1, 2}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(result[1], {3, 4}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(result[2], {"a", "b"}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(result[3], {"c", "d"}, mode = WAVE_DATA)
End

/// @}

/// FindFirstNaNIndex
/// @{

Function TestFindFirstNaNIndex()

	variable idx

	Make/FREE/I wi
	try
		FindFirstNaNIndex(wi)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	Make/FREE wv
	idx = FindFirstNaNIndex(wv)
	CHECK_EQUAL_VAR(idx, NaN)

	Make/FREE wv
	wv[10,] = NaN
	idx     = FindFirstNaNIndex(wv)
	CHECK_EQUAL_VAR(idx, 10)

	Make/FREE wv
	wv[] = NaN
	idx  = FindFirstNaNIndex(wv)
	CHECK_EQUAL_VAR(idx, 0)
End

/// @}

/// SetDimensionLabelsFromWaveContents
/// @{

static Function TestSetDimensionLabelsFromWaveContents()

	WAVE/ZZ input
	try
		SetDimensionLabelsFromWaveContents(input)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	Make/FREE/N=0 input
	SetDimensionLabelsFromWaveContents(input)
	CHECK_NO_RTE()

	Make/FREE/N=3 input = p
	SetDimensionLabelsFromWaveContents(input)
	CHECK_EQUAL_STR(GetDimLabel(input, ROWS, 0), "NUM_0")
	CHECK_EQUAL_STR(GetDimLabel(input, ROWS, 1), "NUM_1")
	CHECK_EQUAL_STR(GetDimLabel(input, ROWS, 2), "NUM_2")

	Make/FREE/N=3 input = p
	SetDimensionLabelsFromWaveContents(input, prefix = "N")
	CHECK_EQUAL_STR(GetDimLabel(input, ROWS, 0), "N0")
	CHECK_EQUAL_STR(GetDimLabel(input, ROWS, 1), "N1")
	CHECK_EQUAL_STR(GetDimLabel(input, ROWS, 2), "N2")

	Make/FREE/N=3 input = p
	SetDimensionLabelsFromWaveContents(input, suffix = "N")
	CHECK_EQUAL_STR(GetDimLabel(input, ROWS, 0), "NUM_0N")
	CHECK_EQUAL_STR(GetDimLabel(input, ROWS, 1), "NUM_1N")
	CHECK_EQUAL_STR(GetDimLabel(input, ROWS, 2), "NUM_2N")

	Make/FREE/N=3 input = p
	try
		SetDimensionLabelsFromWaveContents(input, prefix = ".")
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	Make/FREE/T inputt = {"A", "B", "C"}
	SetDimensionLabelsFromWaveContents(inputt)
	CHECK_EQUAL_STR(GetDimLabel(inputt, ROWS, 0), "A")
	CHECK_EQUAL_STR(GetDimLabel(inputt, ROWS, 1), "B")
	CHECK_EQUAL_STR(GetDimLabel(inputt, ROWS, 2), "C")

	Make/FREE/T inputt = {"A", "B", "C"}
	SetDimensionLabelsFromWaveContents(inputt, prefix = "H")
	CHECK_EQUAL_STR(GetDimLabel(inputt, ROWS, 0), "HA")
	CHECK_EQUAL_STR(GetDimLabel(inputt, ROWS, 1), "HB")
	CHECK_EQUAL_STR(GetDimLabel(inputt, ROWS, 2), "HC")

	Make/FREE/T inputt = {"A", "B", "C"}
	SetDimensionLabelsFromWaveContents(inputt, suffix = "H")
	CHECK_EQUAL_STR(GetDimLabel(inputt, ROWS, 0), "AH")
	CHECK_EQUAL_STR(GetDimLabel(inputt, ROWS, 1), "BH")
	CHECK_EQUAL_STR(GetDimLabel(inputt, ROWS, 2), "CH")

	Make/FREE/N=3 input = p / 2
	SetDimensionLabelsFromWaveContents(input, prefix = "B", suffix = "N")
	CHECK_EQUAL_STR(GetDimLabel(input, ROWS, 0), "B0N")
	CHECK_EQUAL_STR(GetDimLabel(input, ROWS, 1), "B1N")
	CHECK_EQUAL_STR(GetDimLabel(input, ROWS, 2), "B1N")

	Make/FREE/N=3 input = p
	try
		SetDimensionLabelsFromWaveContents(input, suffix = ".")
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	Make/FREE/T inputt = {"A", "A", "C"}
	try
		SetDimensionLabelsFromWaveContents(inputt, strict = 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	Make/FREE/T inputt = {"A", "A", "."}
	try
		SetDimensionLabelsFromWaveContents(inputt, strict = 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	Make/FREE input = {0, 0, 1}
	try
		SetDimensionLabelsFromWaveContents(input, strict = 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

/// @}

/// DuplicateWaveAndKeepTargetRef
/// @{

static Function TestDuplicateWaveAndKeepTargetRef()

	Make/FREE wv
	Make/FREE/WAVE wvRef
	try
		DuplicateWaveAndKeepTargetRef(wv, $"")
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	try
		DuplicateWaveAndKeepTargetRef($"", wv)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	try
		DuplicateWaveAndKeepTargetRef(wvRef, wv)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	DFREF dfr = GetDataFolderDFR()

	Make/N=0 dfr:tgt/WAVE=tgt
	Make/FREE/N=10 src
	src[] = p + q + r + s
	SetScale/P x, 0, 2, "unit", src
	SetDimLabel ROWS, 0, DIMLABEL, src
	note src, "wavenote"
	DuplicateWaveAndKeepTargetRef(src, tgt)
	CHECK_EQUAL_WAVES(src, tgt)
	WAVE afterTgt = dfr:tgt
	CHECK(WaveRefsEqual(tgt, afterTgt))

	Make/O/N=0 dfr:tgt/WAVE=tgt
	WAVE origTgt = tgt
	Redimension/N=(10, 10) src
	src[] = p + q + r + s
	DuplicateWaveAndKeepTargetRef(src, tgt)
	CHECK_EQUAL_WAVES(src, tgt)
	CHECK(WaveRefsEqual(tgt, origtgt))

	Make/O/N=0 dfr:tgt/WAVE=tgt
	Redimension/N=(10, 10, 10) src
	src[] = p + q + r + s
	DuplicateWaveAndKeepTargetRef(src, tgt)
	CHECK_EQUAL_WAVES(src, tgt)
	WAVE afterTgt = dfr:tgt
	CHECK(WaveRefsEqual(tgt, afterTgt))

	Make/O/N=0 dfr:tgt/WAVE=tgt
	Redimension/N=(10, 10, 10, 10) src
	src[] = p + q + r + s
	DuplicateWaveAndKeepTargetRef(src, tgt)
	CHECK_EQUAL_WAVES(src, tgt)
	WAVE afterTgt = dfr:tgt
	CHECK(WaveRefsEqual(tgt, afterTgt))

	Make/O/N=0 dfr:tgt/WAVE=tgt
	Redimension/N=0 src
	DuplicateWaveAndKeepTargetRef(src, tgt)
	CHECK_EQUAL_WAVES(src, tgt)
	WAVE afterTgt = dfr:tgt
	CHECK(WaveRefsEqual(tgt, afterTgt))

	Make/T/N=0 dfr:tgtT/WAVE=tgtT
	Make/FREE/T/N=(10) srcT
	srcT[] = num2istr(p)
	SetScale/P x, 0, 2, "unit", srcT
	SetDimLabel ROWS, 0, DIMLABEL, srcT
	note srcT, "wavenote"
	Redimension/N=10 srcT
	DuplicateWaveAndKeepTargetRef(srcT, tgtT)
	CHECK_EQUAL_WAVES(srcT, tgtT)
	WAVE/T afterTgtT = dfr:tgtT
	CHECK(WaveRefsEqual(tgtT, afterTgtT))

	Make/DF/N=0 dfr:tgtDF/WAVE=tgtDF
	Make/FREE/DF/N=(10) srcDF
	srcDF[] = GetDataFolderDFR()
	SetScale/P x, 0, 2, "unit", srcDF
	SetDimLabel ROWS, 0, DIMLABEL, srcDF
	note srcDF, "wavenote"
	Redimension/N=10 srcDF
	DuplicateWaveAndKeepTargetRef(srcDF, tgtDF)
	CHECK_EQUAL_WAVES(srcDF, tgtDF)
	WAVE/DF afterTgtDF = dfr:tgtDF
	CHECK(WaveRefsEqual(tgtDF, afterTgtDF))

	Make/WAVE/N=0 dfr:tgtWR/WAVE=tgtWR
	WAVE/WAVE origTgtWR = tgtWR
	Make/FREE/WAVE/N=(10) srcWR
	srcWR[] = tgtWR
	SetScale/P x, 0, 2, "unit", srcWR
	SetDimLabel ROWS, 0, DIMLABEL, srcWR
	note srcWR, "wavenote"
	Redimension/N=10 srcWR
	DuplicateWaveAndKeepTargetRef(srcWR, tgtWR)
	CHECK_EQUAL_WAVES(srcWR, tgtWR)
	WAVE/WAVE afterTgtWR = dfr:tgtWR
	CHECK(WaveRefsEqual(tgtWR, afterTgtWR))

	KillWaves/Z tgt, tgtT, tgtDF, tgtWR
End

/// @}

/// SearchForDuplicates
/// @{

Function SFD_AbortsWithNull()

	try
		SearchForDuplicates($"")
		FAIL()
	catch
		PASS()
	endtry
End

Function SFD_WorksWithEmptyWave()

	Make/FREE/N=0 data
	CHECK(!SearchForDuplicates(data))
End

Function SFD_WorksWithSingleEntryWave()

	Make/FREE/N=1 data = 0
	CHECK(!SearchForDuplicates(data))
End

Function SFD_Works()

	Make/FREE data = {0, 1, 2, 4, 5, 0}
	CHECK(SearchForDuplicates(data))
End

/// @}

/// FindNeighbourDuplicates
/// @{

static Function FND_Works()

	WAVE/Z result = FindNeighbourDuplicates({1})
	CHECK_WAVE(result, NULL_WAVE)

	Make/FREE/N=0 emptyWave
	WAVE/Z result = FindNeighbourDuplicates(emptyWave)
	CHECK_WAVE(result, NULL_WAVE)

	// no duplicates
	WAVE/Z result = FindNeighbourDuplicates({1, 2})
	CHECK_WAVE(result, NULL_WAVE)

	// duplicates but not neighbouring
	WAVE/Z result = FindNeighbourDuplicates({1, 2, 1})
	CHECK_WAVE(result, NULL_WAVE)

	// easy neighbouring
	WAVE/Z result = FindNeighbourDuplicates({1, 1})
	CHECK_EQUAL_WAVES(result, {1}, mode = WAVE_DATA)

	// neighbouring chains
	WAVE/Z result = FindNeighbourDuplicates({1, 1, 1, 1, 1, 2, 2, 2, 2, 2})
	CHECK_EQUAL_WAVES(result, {1, 2, 3, 4, 6, 7, 8, 9}, mode = WAVE_DATA)

	// complex neighbouring
	WAVE/Z result = FindNeighbourDuplicates({1, 1, 2, 3, 4, 5, 5, 5, 6, 7, 7, 7})
	CHECK_EQUAL_WAVES(result, {1, 6, 7, 10, 11}, mode = WAVE_DATA)

	// non-finite values
	WAVE/Z result = FindNeighbourDuplicates({1, NaN, NaN, Inf, -Inf, Inf, Inf, 2})
	CHECK_EQUAL_WAVES(result, {2, 6}, mode = WAVE_DATA)
End

/// @}

/// MoveWaveWithOverwrite
/// @{

Function MWWO_RequiresPermanentDestWave()

	variable err

	Make/FREE dest, src

	try
		MoveWaveWithOverwrite(dest, src)
		FAIL()
	catch
		err = GetRtError(1)
		PASS()
	endtry
End

Function MWWO_RequiresDistinctWaves()

	variable err

	Make wv

	try
		MoveWaveWithOverwrite(wv, wv)
		FAIL()
	catch
		err = GetRtError(1)
		PASS()
	endtry

	KillWaves/Z wv
End

Function MWWO_Works()

	Make dest = p
	Make src = 0

	MoveWaveWithOverwrite(dest, src)

	WAVE dest
	CHECK_EQUAL_VAR(Sum(dest), 0)
	WAVE/Z src
	CHECK_WAVE(src, NULL_WAVE)

	KillWaves/Z dest, src
End

Function MWWO_WorksWithFreeSource()

	Make dest = p
	Make/FREE src = 0

	MoveWaveWithOverwrite(dest, src)

	WAVE dest
	CHECK_EQUAL_VAR(Sum(dest), 0)
	WAVE/Z src
	CHECK_WAVE(src, NULL_WAVE)

	KillWaves/Z dest
End

Function MWWO_HandlesLockedDest()

	Make dest = p
	Make src = 0

	Display dest

	MoveWaveWithOverwrite(dest, src)

	WAVE dest
	CHECK_EQUAL_VAR(Sum(dest), 0)
	WAVE/Z src
	CHECK_WAVE(src, NULL_WAVE)

	KillWindow/Z $S_name
	KillWaves/Z dest, src
End

Function MWWO_ReturnsNewRef()

	string path

	Make dest = p
	Make src = 0

	path = GetWavesDataFolder(dest, 2)
	WAVE newDest = MoveWaveWithOverwrite(dest, src)

	CHECK_WAVE(newDest, NORMAL_WAVE)
	CHECK_EQUAL_STR(path, GetWavesDataFolder(newDest, 2))

	WAVE dest
	CHECK_EQUAL_VAR(Sum(dest), 0)
	WAVE src
	CHECK_WAVE(src, NULL_WAVE)

	KillWaves/Z dest, src
End

Function MWWO_RecursiveWorks()
	variable err

	Make/WAVE/N=2 dest
	Make/D dest0 = p
	Make/D dest1 = 2 * p

	dest[0] = dest0
	dest[1] = dest1

	Make/WAVE/N=2 src
	Make src0 = -1
	Make src1 = -2

	src[0] = src0
	src[1] = src1

	MoveWaveWithOverwrite(dest, src, recursive = 1)

	// now we have the waves referenced in src
	// at the same locations as they were in dest
	WAVE/Z src, src0, src1
	CHECK_WAVE(src, NULL_WAVE)
	CHECK_WAVE(src0, NULL_WAVE)
	CHECK_WAVE(src1, NULL_WAVE)

	WAVE/Z dest, dest0, dest1
	CHECK_WAVE(dest, WAVE_WAVE | NORMAL_WAVE)
	CHECK_WAVE(dest0, NORMAL_WAVE, minorType = FLOAT_WAVE)
	CHECK_WAVE(dest1, NORMAL_WAVE, minorType = FLOAT_WAVE)

	CHECK_EQUAL_VAR(Sum(dest0), -128)
	CHECK_EQUAL_VAR(Sum(dest1), -256)

	KillWaves/Z dest, dest0, dest1, src, src0, src1
End

/// @}

/// ZeroWaveImpl
/// @{

Function ZWI_Works1()

	variable numRows = 0

	Make/N=(numRows)/FREE wv
	ZeroWaveImpl(wv)
	CHECK_WAVE(wv, NUMERIC_WAVE, minorType = FLOAT_WAVE)
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), numRows)
End

Function ZWI_Works2()

	variable numRows = 5

	Make/N=(numRows)/FREE wv = {1, 2, 3, 4, -5}
	ZeroWaveImpl(wv)
	CHECK_WAVE(wv, NUMERIC_WAVE, minorType = FLOAT_WAVE)
	CHECK_EQUAL_WAVES(wv, {0, 1, 2, 3, -6})
End

Function ZWI_Works3()

	variable numRows = 5

	Make/N=(numRows)/FREE wv = {-1, 2, 3, 4, -5}
	ZeroWaveImpl(wv)
	CHECK_WAVE(wv, NUMERIC_WAVE, minorType = FLOAT_WAVE)
	CHECK_EQUAL_WAVES(wv, {0, 3, 4, 5, -4})
End

/// @}

/// GetWaveDimensions
/// @{

Function GWD_ChecksParam()

	try
		GetWaveDimensions($"")
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

Function GWD_Works()

	Make/FREE/N=0 wv
	WAVE sizes = GetWaveDimensions(wv)
	CHECK_EQUAL_WAVES(sizes, {0, 0, 0, 0}, mode = WAVE_DATA)

	Make/FREE/N=(1, 2, 3, 4) wv
	WAVE sizes = GetWaveDimensions(wv)
	CHECK_EQUAL_WAVES(sizes, {1, 2, 3, 4}, mode = WAVE_DATA)

	Make/FREE/N=(1, 2, 0, 4) wv
	WAVE sizes = GetWaveDimensions(wv)
	CHECK_EQUAL_WAVES(sizes, {1, 2, 0, 4}, mode = WAVE_DATA)
End

/// @}
