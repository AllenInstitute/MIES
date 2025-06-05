#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_TIME

// Missing Tests for:
// GetTimeStamp
// DateTimeInUTC
// GetISO8601TimeStamp
// ParseISO8601TimeStampToComponents
// StopAllMSTimers
// RelativeNowHighPrec
// GetReferenceTime
// GetElapsedTime
// StoreElapsedTime
// GetDayOfWeek

/// ISO8601Tests
/// @{

// UTF_TD_GENERATOR DataGenerators#ISO8601_timestamps
Function ISO8601_teststamps([string str])

	variable secondsSinceIgorEpoch

	secondsSinceIgorEpoch = ParseISO8601TimeStamp(str)
	REQUIRE_NEQ_VAR(NaN, secondsSinceIgorEpoch)
End

/// @}

/// ParseISO8601TimeStamp
/// @{
Function ReturnsNaNOnInvalid1()

	variable expected = NaN
	variable actual   = ParseISO8601TimeStamp("")
	CHECK_EQUAL_VAR(actual, expected)
End

Function ReturnsNaNOnInvalid2()

	variable expected = NaN
	variable actual   = ParseISO8601TimeStamp("asdklajsd")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid1()

	variable expected = 3578412052
	variable actual   = ParseISO8601TimeStamp("2017-05-23 19:20:52Z")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid2()

	variable expected = 3578412052
	variable actual   = ParseISO8601TimeStamp("2017-05-23 19:20:52")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid3()

	variable expected = 3578412052
	variable actual   = ParseISO8601TimeStamp("2017-05-23T19:20:52")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid4()

	variable expected = 3578412052
	variable actual   = ParseISO8601TimeStamp("2017-05-23T19:20:52Z")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid5()

	variable expected = 3578412052.12345678910
	variable actual   = ParseISO8601TimeStamp("2017-05-23 19:20:52.12345678910")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid6()

	variable expected = 3578412052.12345678910
	variable actual   = ParseISO8601TimeStamp("2017-05-23T19:20:52.12345678910")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid7()

	variable expected = 3578412052.12345678910
	variable actual   = ParseISO8601TimeStamp("2017-05-23T19:20:52.12345678910Z")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid8()

	variable expected = 3578412052.12345678910
	// ISO 8601 does not define decimal separator, so comma is also okay
	variable actual = ParseISO8601TimeStamp("2017-05-23T19:20:52,12345678910")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid9()

	variable now      = DateTimeInUTC()
	variable expected = trunc(now)
	variable actual   = ParseISO8601TimeStamp(GetIso8601TimeStamp(secondsSinceIgorEpoch = now))
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid10()

	variable now      = DateTimeInUTC()
	variable expected = now
	// DateTime currently returns six digits of precision
	variable actual = ParseISO8601TimeStamp(GetIso8601TimeStamp(secondsSinceIgorEpoch = now, numFracSecondsDigits = 6))
	CHECK_CLOSE_VAR(actual, expected)
End

Function AcceptsValid11()

	variable now      = DateTime
	string   actual   = GetIso8601TimeStamp(secondsSinceIgorEpoch = now, localTimeZone = 1)
	string   expected = GetIso8601TimeStamp(secondsSinceIgorEpoch = now - Date2Secs(-1, -1, -1))

	CHECK_EQUAL_VAR(ParseISO8601TimeStamp(actual), ParseISO8601TimeStamp(expected))
End

Function AcceptsValid12()

	variable now      = DateTime
	variable expected = trunc(now) - Date2Secs(-1, -1, -1)
	variable actual   = ParseISO8601TimeStamp(GetIso8601TimeStamp(secondsSinceIgorEpoch = now, localTimeZone = 1))

	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid13()

	variable expected = ParseISO8601TimeStamp("2017-05-23T9:20:52-08:00")
	variable actual   = ParseISO8601TimeStamp("2017-05-23T18:20:52+01:00")
	CHECK_EQUAL_VAR(actual, expected)

	expected = ParseISO8601TimeStamp("2017-05-23T09:20:52-08:00")
	actual   = ParseISO8601TimeStamp("2017-05-23T17:20:52Z")
	CHECK_EQUAL_VAR(actual, expected)
End

Function AcceptsValid14()

	variable expected = 1
	variable actual

	actual = ParseISO8601Timestamp("1904-01-1T00:00:01")
	CHECK_EQUAL_VAR(actual, expected)
	actual = ParseISO8601Timestamp("1904-01-1T00:00:01Z")
	CHECK_EQUAL_VAR(actual, expected)
	actual = ParseISO8601Timestamp("1904-01-1T00:00:01+00:00")
	CHECK_EQUAL_VAR(actual, expected)
	actual = ParseISO8601Timestamp("1904-01-1T01:00:01+01:00")
	CHECK_EQUAL_VAR(actual, expected)

	// works also with standard timezone format which does not have : separator
	// between hour and minutes
	actual = ParseISO8601Timestamp("1904-01-1T01:00:01+0100")
	CHECK_EQUAL_VAR(actual, expected)
End

/// @}
