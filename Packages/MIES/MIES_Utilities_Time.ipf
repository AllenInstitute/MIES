#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_UTILS_TIME
#endif

/// @file MIES_Utilities_Time.ipf
/// @brief utility functions for time/date related operations

/// @brief Return a formatted timestamp of the form `YY_MM_DD_HHMMSS`
///
/// Uses the local time zone and *not* UTC.
///
/// @param humanReadable [optional, default to false]                                Return a format viable for display in a GUI
/// @param secondsSinceIgorEpoch [optional, defaults to number of seconds until now] Seconds since the Igor Pro epoch (1/1/1904)
Function/S GetTimeStamp([variable secondsSinceIgorEpoch, variable humanReadable])

	if(ParamIsDefault(secondsSinceIgorEpoch))
		secondsSinceIgorEpoch = DateTime
	endif

	if(ParamIsDefault(humanReadable))
		humanReadable = 0
	else
		humanReadable = !!humanReadable
	endif

	if(humanReadable)
		return Secs2Time(secondsSinceIgorEpoch, 1) + " " + Secs2Date(secondsSinceIgorEpoch, -2, "/")
	else
		return Secs2Date(secondsSinceIgorEpoch, -2, "_") + "_" + ReplaceString(":", Secs2Time(secondsSinceIgorEpoch, 3), "")
	endif
End

/// @brief Return the seconds, including fractional part, since Igor Pro epoch (1/1/1904) in UTC time zone
threadsafe Function DateTimeInUTC()

	return DateTime - date2secs(-1, -1, -1)
End

/// @brief Return a string in ISO 8601 format with timezone UTC
/// @param secondsSinceIgorEpoch [optional, defaults to number of seconds until now] Seconds since the Igor Pro epoch (1/1/1904)
///                              in UTC (or local time zone depending on `localTimeZone`)
/// @param numFracSecondsDigits  [optional, defaults to zero] Number of sub-second digits
/// @param localTimeZone         [optional, defaults to false] Use the local time zone instead of UTC
threadsafe Function/S GetISO8601TimeStamp([variable secondsSinceIgorEpoch, variable numFracSecondsDigits, variable localTimeZone])

	string   str
	variable timezone

	if(ParamIsDefault(localTimeZone))
		localTimeZone = 0
	else
		localTimeZone = !!localTimeZone
	endif

	if(ParamIsDefault(numFracSecondsDigits))
		numFracSecondsDigits = 0
	else
		ASSERT_TS(IsInteger(numFracSecondsDigits) && numFracSecondsDigits >= 0, "Invalid value for numFracSecondsDigits")
	endif

	if(ParamIsDefault(secondsSinceIgorEpoch))
		if(localTimeZone)
			secondsSinceIgorEpoch = DateTime
		else
			secondsSinceIgorEpoch = DateTimeInUTC()
		endif
	endif

	if(localTimeZone)
		timezone = Date2Secs(-1, -1, -1)
		sprintf str, "%sT%s%+03d:%02d", Secs2Date(secondsSinceIgorEpoch, -2), Secs2Time(secondsSinceIgorEpoch, 3, numFracSecondsDigits), trunc(timezone / 3600), abs(mod(timezone / 60, 60))
	else
		sprintf str, "%sT%sZ", Secs2Date(secondsSinceIgorEpoch, -2), Secs2Time(secondsSinceIgorEpoch, 3, numFracSecondsDigits)
	endif

	return str
End

/// @brief Parse a ISO8601 timestamp, e.g. created by GetISO8601TimeStamp(), and returns the number
/// of seconds, including fractional parts, since Igor Pro epoch (1/1/1904) in UTC time zone
///
/// Accepts also the following specialities:
/// - no UTC timezone specifier (UTC timezone is still used)
/// - ` `/`T` between date and time
/// - fractional seconds
/// - `,`/`.` as decimal separator
threadsafe Function ParseISO8601TimeStamp(string timestamp)

	string year, month, day, hour, minute, second, regexp, fracSeconds, tzOffsetSign, tzOffsetHour, tzOffsetMinute
	variable secondsSinceEpoch, timeOffset, err

	if(IsEmpty(timestamp))
		return NaN
	endif

	[err, year, month, day, hour, minute, second, fracSeconds, tzOffsetSign, tzOffsetHour, tzOffsetMinute] = ParseISO8601TimeStampToComponents(timestamp)
	if(err)
		return NaN
	endif

	secondsSinceEpoch  = date2secs(str2num(year), str2num(month), str2num(day))
	secondsSinceEpoch += 60 * 60 * str2num(hour) + 60 * str2num(minute)
	if(!IsEmpty(second))
		secondsSinceEpoch += str2num(second)
	endif

	if(!IsEmpty(tzOffsetSign) && !IsEmpty(tzOffsetHour))
		timeOffset = str2num(tzOffsetHour) * 3600
		if(!IsEmpty(tzOffsetMinute))
			timeOffset -= str2num(tzOffsetMinute) * 60
		endif

		if(!cmpstr(tzOffsetSign, "+"))
			secondsSinceEpoch -= timeOffset
		elseif(!cmpstr(tzOffsetSign, "-"))
			secondsSinceEpoch += timeOffset
		else
			ASSERT_TS(0, "Invalid case")
		endif
	endif

	if(!IsEmpty(fracSeconds))
		secondsSinceEpoch += str2num(ReplaceString(",", fracSeconds, "."))
	endif

	return secondsSinceEpoch
End

/// @brief Parses a ISO8601 timestamp to its components, year, month, day, hour, minute are required and the remaining components are optional and can be returned as empty strings.
///
threadsafe Function [variable err, string year, string month, string day, string hour, string minute, string second, string fracSeconds, string tzOffsetSign, string tzOffsetHour, string tzOffsetMinute] ParseISO8601TimeStampToComponents(string timestamp)

	string regexp

	regexp = "^([[:digit:]]+)-([[:digit:]]+)-([[:digit:]]+)[T ]{1}([[:digit:]]+):([[:digit:]]+)(?::([[:digit:]]+)([.,][[:digit:]]+)?)?(?:Z|([\+-])([[:digit:]]{2})(?::?([[:digit:]]{2}))?)?$"
	SplitString/E=regexp timestamp, year, month, day, hour, minute, second, fracSeconds, tzOffsetSign, tzOffsetHour, tzOffsetMinute

	if(V_flag < 5)
		return [1, year, month, day, hour, minute, second, fracSeconds, tzOffsetSign, tzOffsetHour, tzOffsetMinute]
	endif

	return [0, year, month, day, hour, minute, second, fracSeconds, tzOffsetSign, tzOffsetHour, tzOffsetMinute]
End

/// @brief Stop all millisecond Igor Pro timers
Function StopAllMSTimers()

	variable i

	for(i = 0; i < MAX_NUM_MS_TIMERS; i += 1)
		printf "ms timer %d stopped. Elapsed time: %g\r", i, stopmstimer(i)
	endfor
End

/// @brief Return a time in seconds with high precision, microsecond resolution, using an
///        arbitrary zero point.
Function RelativeNowHighPrec()

	return stopmstimer(-2) * MICRO_TO_ONE
End

/// @brief Start a timer for performance measurements
///
/// Usage:
/// \rst
/// .. code-block:: igorpro
///
/// 	variable referenceTime = GetReferenceTime()
/// 	// part one to benchmark
/// 	print GetReferenceTime(referenceTime)
/// 	// part two to benchmark
/// 	print GetReferenceTime(referenceTime)
/// 	// you can also store all times via
/// 	StoreElapsedTime(referenceTime)
/// \endrst
Function GetReferenceTime()

	return stopmstimer(-2)
End

/// @brief Get the elapsed time in seconds
Function GetElapsedTime(variable referenceTime)

	return (stopmstimer(-2) - referenceTime) * MICRO_TO_ONE
End

/// @brief Store the elapsed time in a wave
Function StoreElapsedTime(variable referenceTime)

	variable count, elapsed

	WAVE/D elapsedTime = GetElapsedTimeWave()

	count = GetNumberFromWaveNote(elapsedTime, NOTE_INDEX)
	EnsureLargeEnoughWave(elapsedTime, indexShouldExist = count, initialValue = NaN)

	elapsed            = GetElapsedTime(referenceTime)
	elapsedTime[count] = elapsed
	SetNumberInWaveNote(elapsedTime, NOTE_INDEX, count + 1)

	DEBUGPRINT("timestamp: ", var = elapsed)

	return elapsed
End

/// @brief Returns the day of the week, where 1 == Sunday, 2 == Monday ... 7 == Saturday
Function GetDayOfWeek(variable seconds)

	string dat, regex, dayOfWeek

	ASSERT(seconds >= -1094110934400 && seconds <= 973973807999, "seconds input out of range")
	dat = Secs2Date(seconds, -1)

	regex = "^.*\(([0-9])\)"
	SplitString/E=regex dat, dayOfWeek
	ASSERT(V_flag == 1, "Error parsing date: " + dat)

	return str2num(dayOfWeek)
End
