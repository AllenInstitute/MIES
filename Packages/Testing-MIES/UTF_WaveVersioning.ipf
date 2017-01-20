#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
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
