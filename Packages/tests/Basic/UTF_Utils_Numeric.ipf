#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTILSTEST_NUMERIC

// Missing Tests for:
// NewRandomSeed
// GetReproducibleRandom
// GetUniqueInteger
// SetBit
// ClearBit
// MinMax
// FindPreviousPower
// GetAlignment
// CalculateLCM
// SymmetrizeRangeAroundZero
// Base64EncodeSize
// RoundAndDelta
// CeilAndDelta
// FloorAndDelta

/// PopCount
/// @{

static Function PopCount_Works()

	uint64 ui

	CHECK_EQUAL_VAR(PopCount(0), 0)
	CHECK_EQUAL_VAR(PopCount(1), 1)
	CHECK_EQUAL_VAR(PopCount(2), 1)
	CHECK_EQUAL_VAR(PopCount(3), 2)
	CHECK_EQUAL_VAR(PopCount(7), 3)
	CHECK_EQUAL_VAR(PopCount(15), 4)
	// negative numbers are represented as two's complement
	CHECK_EQUAL_VAR(PopCount(-1), 64)
	CHECK_EQUAL_VAR(PopCount(-2), 63)
	CHECK_EQUAL_VAR(PopCount(-3), 63)
	CHECK_EQUAL_VAR(PopCount(-4), 62)
	// non-finite numbers get implicitly converted to 0x8000000000000000
	CHECK_EQUAL_VAR(PopCount(NaN), 1)
	CHECK_EQUAL_VAR(PopCount(Inf), 1)
	CHECK_EQUAL_VAR(PopCount(-Inf), 1)
	// tests when no implicit conversion takes place
	ui = 0xAAAAAAAAAAAAAAAA
	CHECK_EQUAL_VAR(PopCount(ui), 32)
	ui = 0x5555555555555555
	CHECK_EQUAL_VAR(PopCount(ui), 32)
End

/// @}

/// RoundNumber
/// @{

// failure cases are covered in the num2strHighPrec tests

// UTF_TD_GENERATOR DataGenerators#RoundNumberPairs
Function RN_Works([WAVE wv])

	variable number, precision, expected

	number    = wv[0]
	precision = wv[1]
	expected  = wv[2]

	CHECK_EQUAL_VAR(RoundNumber(number, precision), expected)
End

/// @}

/// GenerateRFC4122UUID
/// @{

Function CheckUUIDs()

	Make/FREE/T/N=128 data = GenerateRFC4122UUID()

	// check correct size
	Make/FREE/N=128 sizes = strlen(data[p])
	Make/FREE/N=128 refSizes = 36
	CHECK_EQUAL_WAVES(sizes, refSizes)

	// no duplicates
	FindDuplicates/Z/DT=dups/FREE data
	CHECK_EQUAL_VAR(DimSize(dups, ROWS), 0)

	// correct format
	Make/FREE/N=128 checkFormat = GrepString(data[p], "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
	CHECK_EQUAL_VAR(Sum(checkFormat), 128)
End

/// @}

/// LimitWithReplace
/// @{

// IUTF_TD_GENERATOR w0:DataGenerators#GetLimitValues
static Function TestLimitWithReplace([STRUCT IUTF_mData &mData])

	variable val    = mData.w0[0]
	variable low    = mData.w0[1]
	variable high   = mData.w0[2]
	variable repl   = mData.w0[3]
	variable result = mData.w0[4]

	CHECK_EQUAL_VAR(LimitWithReplace(val, low, high, repl), result)
End

/// @}

/// FindRightMostHighBit
/// @{

static Function TestFindRightMostHighBit()

	Make/FREE/N=(64) result = FindRightMostHighBit(1 << p) == p
	CHECK_EQUAL_VAR(sum(result), 64)

	CHECK_EQUAL_VAR(FindRightMostHighBit(0), NaN)

	CHECK_EQUAL_VAR(FindRightMostHighBit(3), 0)
	CHECK_EQUAL_VAR(FindRightMostHighBit(18), 1)
End

/// @}

/// IndexAfterDecimation
/// @{

// IUTF_TD_GENERATOR v0:IndexAfterDecimation_Positions
// IUTF_TD_GENERATOR v1:IndexAfterDecimation_Sizes
static Function TestIndexAfterDecimation([STRUCT IUTF_mData &md])

	variable decimationFactor, srcPulseLength, srcOffset
	variable edgeLeft, edgeLeftCalculated

	variable srcLength = 1000

	Make/FREE/N=(srcLength) source
	Make/FREE/N=(md.v1) target

	decimationFactor = srcLength / md.v1
	// make srcPulseLength as least as long that there is at least one point with amplitude in target for FindLevel
	srcPulseLength                                = ceil(decimationFactor)
	srcOffset                                     = trunc(srcLength * md.v0)
	source[srcOffset, srcOffset + srcPulseLength] = 1

	target[] = source[limit(round(p * decimationFactor), 0, srcLength - 1)]

	FindLevel/Q/EDGE=1 target, 0.5
	edgeLeft = trunc(V_LevelX)

	edgeLeftCalculated = IndexAfterDecimation(srcOffset, decimationFactor)

	CHECK_EQUAL_VAR(edgeLeft, edgeLeftCalculated)
End

/// @}

/// FindNextPower
/// @{
static Function TestFindNextPower()

	// invalid a (zero)
	try
		FindNextPower(0, 2)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// invalid a (fractional)
	try
		FindNextPower(1.5, 2)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// invalid p
	try
		FindNextPower(1, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// works
	CHECK_EQUAL_VAR(2, FindNextPower(3, 2))
	CHECK_EQUAL_VAR(3, FindNextPower(25, 3))
End
/// @}
