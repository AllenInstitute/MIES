#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_MIES_SWEEP

// Missing Tests for:
// GetDAQDataSingleColumnWaves
// GetDAQDataSingleColumnWaveNG
// GetDAQDataSingleColumnWave
// CopySweepToWRef
// SplitAndUpgradeSweep
// ResolveSweepChannel
// SplitTextSweepElement
// GetSweepComponentWaveName
// UpdateLeftOverSweepTime
// LeftOverSweepTime
// IsValidSweepWave
// GetTotalOnsetDelay
// SplitAndUpgradeSweepGlobal
// TextSweepToWaveRef

/// IsValidSweepNumber
/// @{

// UTF_TD_GENERATOR DataGenerators#InfiniteValues
static Function IVSN_WorksSpecialValues([variable val])

	CHECK(!IsValidSweepNumber(val))
End

static Function IVSN_Works()

	CHECK(!IsValidSweepNumber(INVALID_SWEEP_NUMBER))
	CHECK(IsValidSweepNumber(0))
	CHECK(IsValidSweepNumber(1000))
End

/// @}

/// ExtractSweepNumber
/// @{

// UTF_TD_GENERATOR DataGenerators#GetValidStringsWithSweepNumber
Function ESN_Works([string str])

	CHECK_EQUAL_VAR(ExtractSweepNumber(str), 100)
End

// UTF_TD_GENERATOR DataGenerators#GetInvalidStringsWithSweepNumber
Function ESN_Complains([string str])

	try
		ExtractSweepNumber(str)
		FAIL()
	catch
		PASS()
	endtry
End

/// @}

/// ExtractOneDimDataFromSweep
/// @{

static Function [WAVE config, WAVE/WAVE sweep] EODDFS_GetConfigAndSweep_IGNORE()

	Make/FREE/D/N=(2, 8) configWave
	SetWaveVersion(configWave, DAQ_CONFIG_WAVE_VERSION)
	AddEntryIntoWaveNoteAsList(configWave, CHANNEL_UNIT_KEY, str = "mV,pA")

	Make/FREE/D da = {1, 2, 3}
	SetScale d, 0, 0, "mV", da
	Make/FREE/D ad = {4, 5, 6}
	SetScale d, 0, 0, "pA", ad
	Make/FREE/WAVE sweepWave = {da, ad}
	Note/K sweepWave, "sweep note"

	return [configWave, sweepWave]
End

static Function EODDFS_CopiesByDefault()

	[WAVE config, WAVE/WAVE sweep] = EODDFS_GetConfigAndSweep_IGNORE()

	WAVE data = ExtractOneDimDataFromSweep(config, sweep, 1)
	CHECK_EQUAL_VAR(WaveRefsEqual(data, sweep[1]), 0)
	CHECK_EQUAL_WAVES(data, sweep[1], mode = WAVE_DATA | DATA_UNITS)
	CHECK_EQUAL_STR(note(data), "sweep note")
End

static Function EODDFS_DontDuplicateReturnsChannel()

	string str

	[WAVE config, WAVE/WAVE sweep] = EODDFS_GetConfigAndSweep_IGNORE()

	WAVE data = ExtractOneDimDataFromSweep(config, sweep, 1, dontDuplicate = 1)
	CHECK_EQUAL_VAR(WaveRefsEqual(data, sweep[1]), 1)
	str = note(data)
	CHECK_EMPTY_STR(str)
End

static Function EODDFS_DontDuplicateAbortsWith2DSweep()

	[WAVE config, WAVE/WAVE sweep] = EODDFS_GetConfigAndSweep_IGNORE()

	Make/FREE/D/N=(3, 2) sweep2D

	try
		ExtractOneDimDataFromSweep(config, sweep2D, 1, dontDuplicate = 1)
		FAIL()
	catch
		PASS()
	endtry
End

/// @}
