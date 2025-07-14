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
