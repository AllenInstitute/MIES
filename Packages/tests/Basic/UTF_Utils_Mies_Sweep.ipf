#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_MIES_SWEEP

// Missing Tests for:
// GetDAQDataSingleColumnWaves
// GetDAQDataSingleColumnWaveNG
// GetDAQDataSingleColumnWave
// ExtractOneDimDataFromSweep
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

// UTF_TD_GENERATOR InfiniteValues
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

Function/WAVE GetValidStringsWithSweepNumber()

	Make/FREE/T wv = {"Sweep_100", "Sweep_100_bak", "Config_Sweep_100", "Config_Sweep_100_bak", "X_100"}

	return wv
End

// UTF_TD_GENERATOR GetValidStringsWithSweepNumber
Function ESN_Works([string str])

	CHECK_EQUAL_VAR(ExtractSweepNumber(str), 100)
End

Function/WAVE GetInvalidStringsWithSweepNumber()

	Make/FREE/T wv = {"", "A", "A__", "Sweep_-100"}

	return wv
End

// UTF_TD_GENERATOR GetInvalidStringsWithSweepNumber
Function ESN_Complains([string str])

	try
		ExtractSweepNumber(str)
		FAIL()
	catch
		PASS()
	endtry
End

/// @}
