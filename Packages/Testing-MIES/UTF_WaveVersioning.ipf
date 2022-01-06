#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=WaveVersioning

/// @{ ExistsWithCorrectLayoutVersion
Function EWCL_InvalidWaveRefHasNoVersion()
	WAVE/Z wv = $""
	CHECK(!MIES_WAVEGETTERS#ExistsWithCorrectLayoutVersion(wv, 1))
End

Function EWCL_NoWaveVersionIsFalse()
	Make/FREE wv
	CHECK(!MIES_WAVEGETTERS#ExistsWithCorrectLayoutVersion(wv, 1))
End

Function EWCL_Works()
	Make/FREE wv
	MIES_WAVEGETTERS#SetWaveVersion(wv, 1)
	CHECK(MIES_WAVEGETTERS#ExistsWithCorrectLayoutVersion(wv, 1))
End
/// @}

/// @{ SetWaveVersion
Function SWV_AssertsWithInvalidVersion0()

	WAVE/Z wv = $""
	try
		MIES_WAVEGETTERS#SetWaveVersion(wv, 1)
		FAIL()
	catch
		PASS()
	endtry
End

Function SWV_AssertsWithInvalidVersion1()

	Make/FREE wv
	try
		MIES_WAVEGETTERS#SetWaveVersion(wv, 0)
		FAIL()
	catch
		PASS()
	endtry
End

Function SWV_AssertsWithInvalidVersion2()

	Make/FREE wv
	try
		MIES_WAVEGETTERS#SetWaveVersion(wv, -1)
		FAIL()
	catch
		PASS()
	endtry
End

Function SWV_AssertsWithInvalidVersion3()

	Make/FREE wv
	try
		MIES_WAVEGETTERS#SetWaveVersion(wv, 1.5)
		FAIL()
	catch
		PASS()
	endtry
End

Function SWV_Works()

	Make/FREE wv
	MIES_WAVEGETTERS#SetWaveVersion(wv, 1)
	PASS()
End
/// @}

/// @{ GetWaveVersion
Function GWV_AbortsOnInvalidWaveRef()

	try
		MIES_WAVEGETTERS#GetWaveVersion($"")
		FAIL()
	catch
		PASS()
	endtry
End

Function GWV_NaNOnUnversionedWave()

	Make/FREE wv
	CHECK_EQUAL_VAR(MIES_WAVEGETTERS#GetWaveVersion(wv), NaN)
End

Function GWV_Works()

	Make/FREE wv
	MIES_WAVEGETTERS#SetWaveVersion(wv, 4711)
	CHECK_EQUAL_VAR(MIES_WAVEGETTERS#GetWaveVersion(wv), 4711)
End
/// @}

/// @{ WaveVersionIsAtLeast
Function WV_IsAtLeastNull()

	try
		MIES_WAVEGETTERS#WaveVersionIsAtLeast($"", 1)
		FAIL()
	catch
		PASS()
	endtry
End

Function WV_IsAtLeastOne()
	Make/FREE wv

	try
		MIES_WAVEGETTERS#WaveVersionIsAtLeast(wv, 0)
		FAIL()
	catch
		PASS()
	endtry
End

Function WV_IsAtLeastInteger()
	Make/FREE wv

	try
		MIES_WAVEGETTERS#WaveVersionIsAtLeast(wv, 1.5)
		FAIL()
	catch
		PASS()
	endtry
End

Function WV_IsAtLeast()
	Make/FREE wv
	CHECK(!MIES_WAVEGETTERS#WaveVersionIsAtLeast(wv, 1))

	MIES_WAVEGETTERS#SetWaveVersion(wv, 1)
	CHECK(MIES_WAVEGETTERS#WaveVersionIsAtLeast(wv, 1))
	CHECK(!MIES_WAVEGETTERS#WaveVersionIsAtLeast(wv, 2))
End
/// @}

/// @{ WaveVersionIsSmaller
Function WV_IsSmallerNull()

	try
		MIES_WAVEGETTERS#WaveVersionIsSmaller($"", 1)
		FAIL()
	catch
		PASS()
	endtry
End

Function WV_IsSmallerOne()
	Make/FREE wv

	try
		MIES_WAVEGETTERS#WaveVersionIsSmaller(wv, 0)
		FAIL()
	catch
		PASS()
	endtry
End

Function WV_IsSmallerInteger()
	Make/FREE wv

	try
		MIES_WAVEGETTERS#WaveVersionIsSmaller(wv, 1.5)
		FAIL()
	catch
		PASS()
	endtry
End

Function WV_IsSmaller()
	Make/FREE wv
	CHECK(MIES_WAVEGETTERS#WaveVersionIsSmaller(wv, 1))

	MIES_WAVEGETTERS#SetWaveVersion(wv, 1)
	CHECK(!MIES_WAVEGETTERS#WaveVersionIsSmaller(wv, 1))
	CHECK(MIES_WAVEGETTERS#WaveVersionIsSmaller(wv, 2))
End
/// @}

/// @{ ClearWaveNoteExceptWaveVersion

Function CWNE_ClearsNoteWithoutVersion()
	string str

	Make/FREE wv

	Note wv, "abcd"
	ClearWaveNoteExceptWaveVersion(wv)

	str = note(wv)
	CHECK_EMPTY_STR(str)
End

Function CWNE_ClearsNoteAndDropsInvalidVersion()
	string str

	Make/FREE wv

	MIES_WAVEGETTERS#SetWaveVersion(wv, 111)
	// by replacing just the wave version we don't need to know the exact key
	Note/K wv, ReplaceString("111", "-1", note(wv))

	str = note(wv)
	CHECK_NON_EMPTY_STR(str)

	ClearWaveNoteExceptWaveVersion(wv)

	str = note(wv)
	CHECK_EMPTY_STR(str)
End

Function CWNE_ClearsNoteAndKeepsValidWaveVersion()
	string str, ref

	Make/FREE wv

	MIES_WAVEGETTERS#SetWaveVersion(wv, 111)
	ref = note(wv)

	Note wv, "abcd"

	ClearWaveNoteExceptWaveVersion(wv)

	str = note(wv)
	CHECK_EQUAL_STR(ref, str)
End

/// @}
