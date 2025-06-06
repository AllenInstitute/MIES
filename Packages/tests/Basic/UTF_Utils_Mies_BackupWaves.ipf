#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_MIES_BACKUPWAVES

// Missing Tests for:
// RestoreFromBackupWavesForAll

/// Backup functions
/// - CreateBackupWave
/// - CreateBackupWavesForAll
/// - GetBackupWave
/// - ReplaceWaveWithBackup
/// - ReplaceWaveWithBackupForAll
/// @{

Function CreateBackupWaveChecksArgs()

	// asserts out when passing a free wave
	try
		Make/FREE wv
		CreateBackupWave(wv)
		FAIL()
	catch
		PASS()
	endtry
End

Function CreateBackupWaveBasics()

	Make data
	WAVE/Z bak = CreateBackupWave(data)
	CHECK_WAVE(bak, NORMAL_WAVE)
	CHECK_EQUAL_WAVES(bak, data)

	KillWaves/Z data, bak
End

Function CreateBackupWaveCorrectNaming()

	string actual, expected

	Make data
	WAVE/Z bak = CreateBackupWave(data)

	// naming is correct
	actual   = NameOfWave(bak)
	expected = "data_bak"
	CHECK_EQUAL_STR(actual, expected)

	KillWaves/Z data, bak
End

Function CreateBackupWaveNoUnwantedRecreation()

	variable modCount

	// does not recreate it when called again
	Make data
	WAVE/Z bak = CreateBackupWave(data)
	modCount = WaveModCount(bak)

	WAVE/Z bakAgain = CreateBackupWave(data)

	CHECK_WAVE(bakAgain, NORMAL_WAVE)
	CHECK(WaveRefsEqual(bak, bakAgain))
	CHECK_EQUAL_VAR(modCount, WaveModCount(bakAgain))

	KillWaves/Z data, bak
End

Function CreateBackupWaveAllowsForcingRecreation()

	variable modCount

	// except when we force it
	Make data
	WAVE/Z bak = CreateBackupWave(data)
	modCount = WaveModCount(bak)

	WAVE/Z bakAgain = CreateBackupWave(data, forceCreation = 1)

	CHECK_GT_VAR(WaveModCount(bakAgain), modCount)

	KillWaves/Z data, bak
End

Function/DF PrepareFolderForBackup_IGNORE()

	variable numElements
	NewDataFolder folder
	Make :folder:data1 = p
	Make :folder:data2 = P^2
	string/G   :folder:str
	variable/G :folder:var
	NewDataFolder :folder:test

	DFREF dfr = $"folder"
	return dfr
End

Function CountElementsInFolder_IGNORE(DFREF dfr)

	return CountObjectsDFR(dfr, COUNTOBJECTS_WAVES) + CountObjectsDFR(dfr, COUNTOBJECTS_VAR)      \
	       + CountObjectsDFR(dfr, COUNTOBJECTS_STR) + CountObjectsDFR(dfr, COUNTOBJECTS_DATAFOLDER)
End

Function CreateBackupWaveForAllWorks()

	DFREF    dfr         = PrepareFolderForBackup_IGNORE()
	variable numElements = CountElementsInFolder_IGNORE(dfr)

	CreateBackupWavesForAll(dfr)

	CHECK_EQUAL_VAR(CountElementsInFolder_IGNORE(dfr), numElements + 2)

	WAVE/Z/SDFR=dfr data1_bak, data2_bak
	CHECK_WAVE(data1_bak, NORMAL_WAVE)
	CHECK_WAVE(data2_bak, NORMAL_WAVE)

	KillDataFolder/Z dfr
End

Function GetBackupWaveChecksArgs()

	// asserts out when passing a free wave
	try
		Make/FREE wv
		GetBackupWave(wv)
		FAIL()
	catch
		PASS()
	endtry
End

Function GetBackupWaveMightReturnNull()

	Make data
	WAVE/Z bak = GetBackupWave(data)
	CHECK_WAVE(bak, NULL_WAVE)

	KillWaves/Z data, bak
End

Function GetBackupWaveWorks()

	Make data
	WAVE/Z bak1 = CreateBackupWave(data)
	WAVE/Z bak2 = GetBackupWave(data)

	CHECK_WAVE(bak1, NORMAL_WAVE)
	CHECK_WAVE(bak2, NORMAL_WAVE)
	CHECK(WaveRefsEqual(bak1, bak2))

	KillWaves/Z data, bak1, bak2
End

Function ReplaceWaveWithBackupWorks()

	variable originalSum

	Make data = p
	WAVE bak = CreateBackupWave(data)
	originalSum = Sum(data)
	data        = 0

	CHECK_EQUAL_VAR(Sum(data), 0)

	WAVE/Z dataOrig = ReplaceWaveWithBackup(data)
	CHECK_WAVE(dataOrig, NORMAL_WAVE)
	CHECK_EQUAL_VAR(Sum(dataOrig), originalSum)
	CHECK(WaveRefsEqual(data, dataOrig))

	KillWaves/Z data, bak
End

Function ReplaceWaveWithBackupNonExistingBackupIsFatal()

	// backups are required by default
	try
		Make data
		ReplaceWaveWithBackup(data)
		FAIL()
	catch
		PASS()
	endtry

	KillWaves/Z data
End

Function ReplaceWaveWithBackupNonExistingBackupIsOkay()

	// but that can be turned off
	Make data
	WAVE/Z bak = ReplaceWaveWithBackup(data, nonExistingBackupIsFatal = 0)
	CHECK_WAVE(bak, NULL_WAVE)

	KillWaves/Z data, bak
End

Function ReplaceWaveWithBackupRemoval()

	Make data
	CreateBackupWave(data)
	ReplaceWaveWithBackup(data)

	// by default the backup is removed
	WAVE/Z bak = GetBackupWave(data)
	CHECK_WAVE(bak, NULL_WAVE)

	KillWaves/Z data, bak
End

Function ReplaceWaveWithBackupKeeping()

	Make data

	// but that can be turned off
	CreateBackupWave(data)
	ReplaceWaveWithBackup(data, keepBackup = 1)
	WAVE/Z bak = GetBackupWave(data)
	CHECK_WAVE(bak, NORMAL_WAVE)

	KillWaves/Z data, bak
End

Function ReplaceWaveWithBackupForAllNonFatal()

	DFREF    dfr         = PrepareFolderForBackup_IGNORE()
	variable numElements = CountElementsInFolder_IGNORE(dfr)
	ReplaceWaveWithBackupForAll(dfr)
	CHECK_EQUAL_VAR(CountElementsInFolder_IGNORE(dfr), numElements)

	KillDataFolder/Z dfr
End

Function ReplaceWaveWithBackupForAllWorks()

	variable originalSum1, originalSum2

	DFREF    dfr         = PrepareFolderForBackup_IGNORE()
	variable numElements = CountElementsInFolder_IGNORE(dfr)

	WAVE/SDFR=dfr data1

	WAVE/SDFR=dfr data1
	originalSum1 = Sum(data1)

	WAVE/SDFR=dfr data2
	originalSum2 = Sum(data2)

	CreateBackupWavesForAll(dfr)

	data1 = 0
	data2 = 0
	CHECK_EQUAL_VAR(Sum(data1), 0)
	CHECK_EQUAL_VAR(Sum(data2), 0)

	ReplaceWaveWithBackupForAll(dfr)

	WAVE/SDFR=dfr data1_restored = data1
	WAVE/SDFR=dfr data2_restored = data2
	CHECK_EQUAL_VAR(Sum(data1_restored), originalSum1)
	CHECK_EQUAL_VAR(Sum(data2_restored), originalSum2)

	// backup waves are kept
	CHECK_EQUAL_VAR(CountElementsInFolder_IGNORE(dfr), numElements + 2)

	KillDataFolder/Z dfr
End

/// @}
