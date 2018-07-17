#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DEBUG
#endif

/// @file MIES_Debugging.ipf
///
/// @brief Holds functions for handling debugging information

/// @brief Return the first function from the stack trace
///         not located in this file.
static Function FindFirstOutsideCaller(func, line, file)
	string &func, &line, &file

	string stacktrace, caller
	variable numCallers, i

	stacktrace = GetRTStackInfo(3)
	numCallers = ItemsInList(stacktrace)

	for(i = numCallers - 2; i >= 0; i -= 1)
		caller = StringFromList(i, stacktrace)
		func   = StringFromList(0, caller, ",")
		file   = StringFromList(1, caller, ",")
		line   = StringFromList(2, caller, ",")

		if(cmpstr("MIES_DEBUGGING.ipf", file))
			return NaN
		endif
	endfor

	func = ""
	file = ""
	line = ""
End

#if defined(DEBUGGING_ENABLED)

static StrConstant functionReturnMessage = "return value"

/// @brief Output debug information and return the parameter var.
///
/// Debug function especially designed for usage in return statements.
///
/// For example calling the following function
/// \rst
/// .. code-block:: igorpro
///
/// 	Function doStuff()
/// 		variable var = 1 + 2
/// 		return DEBUGPRINTv(var)
/// 	End
/// \endrst
///
/// will output
/// @verbatim DEBUG doStuff(...)#L5: return value 3 @endverbatim
/// to the history.
///
/// @hidecallgraph
/// @hidecallergraph
///
///@param var     numerical argument for debug output
///@param format  optional format string to override the default of "%g"
Function DEBUGPRINTv(var, [format])
	variable var
	string format

	if(ParamIsDefault(format))
		DEBUGPRINT(functionReturnMessage, var=var)
	else
		DEBUGPRINT(functionReturnMessage, var=var, format=format)
	endif

	return var
End

/// @brief Output debug information and return the parameter str
///
/// Debug function especially designed for usage in return statements.
///
/// For example calling the following function
/// \rst
/// .. code-block:: igorpro
///
/// 	Function/s doStuff()
/// 		variable str= "a" + "b"
/// 		return DEBUGPRINTs(str)
/// 	End
/// \endrst
/// will output
/// @verbatim DEBUG doStuff(...)#L5: return value ab @endverbatim
/// to the history.
///
/// @hidecallgraph
/// @hidecallergraph
///
///@param str     string argument for debug output
///@param format  optional format string to override the default of "%s"
Function/s DEBUGPRINTs(str, [format])
	string str, format

	if(ParamIsDefault(format))
		DEBUGPRINT(functionReturnMessage, str=str)
	else
		DEBUGPRINT(functionReturnMessage, str=str, format=format)
	endif

	return str
End

///@brief Generic debug output function
///
/// Outputs variables and strings with optional format argument.
///
/// Examples:
/// \rst
/// .. code-block:: igorpro
///
/// 	DEBUGPRINT("before a possible crash")
/// 	DEBUGPRINT("some variable", var=myVariable)
/// 	DEBUGPRINT("my string", str=myString)
/// 	DEBUGPRINT("Current state", var=state, format="%.5f")
/// \endrst
///
/// @hidecallgraph
/// @hidecallergraph
///
/// @param msg    descriptive string for the debug message
/// @param var    variable
/// @param str    string
/// @param format format string overrides the default of "%g" for variables and "%s" for strings
Function DEBUGPRINT(msg, [var, str, format])
	string msg
	variable var
	string str, format

	string file, line, func, caller, stacktrace, formatted = ""
	variable numSuppliedOptParams, idx, numCallers

	// check parameters
	// valid combinations:
	// - var
	// - str
	// - var and format
	// - str and format
	// - neither var, str, format
	numSuppliedOptParams = !ParamIsDefault(var) + !ParamIsDefault(str) + !ParamIsDefault(format)

	if(numSuppliedOptParams == 0)
		// nothing to check
	elseif(numSuppliedOptParams == 1)
		ASSERT(ParamIsDefault(format), "Only supplying the \"format\" parameter is not allowed")
	elseif(numSuppliedOptParams == 2)
		ASSERT(!ParamIsDefault(format), "You can't supply \"var\" and \"str\" at the same time")
	else
		ASSERT(0, "Invalid parameter combination")
	endif

	FindFirstOutsideCaller(func, line, file)

	if(!IsEmpty(file) && !DebuggingEnabledForFileWrapper(file))
		return NaN
	endif

	if(!ParamIsDefault(var))
		if(ParamIsDefault(format))
			format = "%g"
		endif
		sprintf formatted, format, var
	elseif(!ParamIsDefault(str))
		if(ParamIsDefault(format))
			format = "%s"
		endif
		sprintf formatted, format, str
	endif

	msg = RemoveEnding(msg, "\r")

	if(!isEmpty(func))
		printf "DEBUG %s(...)#L%s: %s %s\r", func, line, msg, formatted
	else
		printf "DEBUG: %s %s\r", msg, formatted
	endif
End

///@brief Generic debug output function (threadsafe variant)
///
/// Outputs variables and strings with optional format argument.
///
/// Examples:
/// \rst
/// .. code-block:: igorpro
///
///		DEBUGPRINT("before a possible crash")
///		DEBUGPRINT("some variable", var=myVariable)
///		DEBUGPRINT("my string", str=myString)
///		DEBUGPRINT("Current state", var=state, format="%.5f")
/// \endrst
///
/// @hidecallgraph
/// @hidecallergraph
///
/// @param msg    descriptive string for the debug message
/// @param var    variable
/// @param str    string
/// @param format format string overrides the default of "%g" for variables and "%s" for strings
threadsafe Function DEBUGPRINT_TS(msg, [var, str, format])
	string msg
	variable var
	string str, format

	string formatted = ""
	variable numSuppliedOptParams

	// check parameters
	// valid combinations:
	// - var
	// - str
	// - var and format
	// - str and format
	// - neither var, str, format
	numSuppliedOptParams = !ParamIsDefault(var) + !ParamIsDefault(str) + !ParamIsDefault(format)

	if(numSuppliedOptParams == 0)
		// nothing to check
	elseif(numSuppliedOptParams == 1)
		ASSERT_TS(ParamIsDefault(format), "Only supplying the \"format\" parameter is not allowed")
	elseif(numSuppliedOptParams == 2)
		ASSERT_TS(!ParamIsDefault(format), "You can't supply \"var\" and \"str\" at the same time")
	else
		ASSERT_TS(0, "Invalid parameter combination")
	endif

	if(!ParamIsDefault(var))
		if(ParamIsDefault(format))
			format = "%g"
		endif
		sprintf formatted, format, var
	elseif(!ParamIsDefault(str))
		if(ParamIsDefault(format))
			format = "%s"
		endif
		sprintf formatted, format, str
	endif

	printf "DEBUG: %s %s\r", RemoveEnding(msg, "\r"), formatted
End

/// @brief Print a nicely formatted stack trace to the history
Function DEBUGPRINTSTACKINFO()

	string func, line, file

	FindFirstOutsideCaller(func, line, file)

	if(!IsEmpty(file) && !DebuggingEnabledForFileWrapper(file))
		return NaN
	endif

	print GetStackTrace(prefix = "\tDEBUG ")

	if(!windowExists("HistoryCarbonCopy"))
		ASSERT(cmpstr(GetExperimentName(), UNTITLED_EXPERIMENT), "Untitled experiments do not work")
		CreateHistoryLog()
	endif

	SaveHistoryLog()
End

/// Creates a notebook with the special name "HistoryCarbonCopy"
/// which will hold a copy of the history
static Function CreateHistoryLog()
	DoWindow/K HistoryCarbonCopy
	NewNotebook/V=0/F=0 /N=HistoryCarbonCopy
End

/// Save the contents of the history notebook on disk
/// in the same folder as this experiment as timestamped file "run_*_*.log"
static Function SaveHistoryLog()

	string historyLog
	sprintf historyLog, "%s.log", IgorInfo(1)//, Secs2Date(DateTime,-2), ReplaceString(":",Secs2Time(DateTime,1),"-")

	DoWindow HistoryCarbonCopy
	if(V_flag == 0)
		print "No log notebook found, please call CreateHistoryLog() before."
		ControlWindowToFront()
		return NaN
	endif

	SaveNoteBook/O/S=3/P=home HistoryCarbonCopy as historyLog
End

/// @brief Prints a message to the command history in debug mode,
///        aborts with dialog in release mode
Function DEBUGPRINT_OR_ABORT(msg)
	string msg

	DEBUGPRINT(msg)
End

/// @brief Start a timer for performance measurements
///
/// Usage:
/// \rst
/// .. code-block:: igorpro
///
/// 	variable referenceTime = DEBUG_TIMER_START()
/// 	// part one to benchmark
/// 	DEBUGPRINT_ELAPSED(referenceTime)
/// 	// part two to benchmark
/// 	DEBUGPRINT_ELAPSED(referenceTime)
/// \endrst
Function DEBUG_TIMER_START()

	return stopmstimer(-2)
End

/// @brief Print the elapsed time for performance measurements in seconds
/// @see DEBUG_TIMER_START()
Function DEBUGPRINT_ELAPSED(referenceTime)
	variable referenceTime

	DEBUGPRINT("timestamp: ", var=(stopmstimer(-2) - referenceTime) / 1e6)
End

/// @brief Print and store the elapsed time for performance measurements
/// @see DEBUG_TIMER_START()
Function DEBUGPRINT_ELAPSED_WAVE(referenceTime)
	variable referenceTime

	variable count, elapsed

	elapsed = (stopmstimer(-2) - referenceTime) / 1e6

	WAVE/D/Z elapsedTime

	if(!WaveExists(elapsedTime))
		Make/D/N=(MINIMUM_WAVE_SIZE) elapsedTime
		SetScale d, 0, 0, "s", elapsedTime
		SetNumberInWaveNote(elapsedTime, NOTE_INDEX, 0)
	endif

	count = GetNumberFromWaveNote(elapsedTime, NOTE_INDEX)
	EnsureLargeEnoughWave(elapsedTime, minimumSize=count)

	elapsedTime[count] = elapsed
	SetNumberInWaveNote(elapsedTime, NOTE_INDEX, count + 1)

	DEBUGPRINT("timestamp: ", var=elapsed)
End

#else

Function DEBUGPRINTv(var, [format])
	variable var
	string format

	// do nothing

	return var
End

Function/s DEBUGPRINTs(str, [format])
	string str, format

	// do nothing

	return str
End

Function DEBUGPRINT(msg, [var, str, format])
	string msg
	variable var
	string str, format

	// do nothing
End

threadsafe Function DEBUGPRINT_TS(msg, [var, str, format])
	string msg
	variable var
	string str, format

	// do nothing
End

Function DEBUGPRINTSTACKINFO()
	// do nothing
End

Function DEBUGPRINT_OR_ABORT(msg)
	string msg

	DoAbortNow(msg)
End

Function DEBUG_TIMER_START()

End

Function DEBUGPRINT_ELAPSED(referenceTime)
	variable referenceTime
End

Function DEBUGPRINT_ELAPSED_WAVE(referenceTime)
	variable referenceTime
End
#endif

///@brief Enable debug mode
Function EnableDebugMode()
	Execute/P/Q "SetIgorOption poundDefine=DEBUGGING_ENABLED"
	Execute/P/Q "COMPILEPROCEDURES "
End

///@brief Disable debug mode
Function DisableDebugMode()
	Execute/P/Q "SetIgorOption poundUnDefine=DEBUGGING_ENABLED"
	Execute/P/Q "COMPILEPROCEDURES "
End

///@brief Enable evil mode
Function EnableEvilMode()
	Execute/P/Q "SetIgorOption poundDefine=EVIL_KITTEN_EATING_MODE"
	Execute/P/Q "COMPILEPROCEDURES "
End

///@brief Disable evil mode
Function DisableEvilMode()
	Execute/P/Q "SetIgorOption poundUnDefine=EVIL_KITTEN_EATING_MODE"
	Execute/P/Q "COMPILEPROCEDURES "
End

/// @brief Prototype for DebuggingEnabledForFileWrapper()
Function DebuggingEnabledForFileSimple(file)
	string file

	return 1
End

/// @brief Wrapper for DP_DebuggingEnabledForFile()
Function DebuggingEnabledForFileWrapper(file)
	string file

	FUNCREF DebuggingEnabledForFileSimple f = $"DP_DebuggingEnabledForFile"

	return f(file)
End

/// @brief Complain and ask the user to report the error
///
/// In nearly all cases ASSERT() is the more appropriate method to use.
Function Bug(msg)
	string msg

	string func, line, file
	FindFirstOutsideCaller(func, line, file)

	if(!isEmpty(func))
		printf "BUG %s(...)#L%s: %s\r", func, line, msg
	else
		printf "BUG: %s\r", msg
	endif

	ControlWindowToFront()
End
