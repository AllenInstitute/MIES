#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion=6.3
#pragma IndependentModule=IPNWB
#pragma version=0.1

/// @file IPNWB_Debugging.ipf
///
/// @brief Holds functions for debugging

/// @brief Low overhead function to check assertions
///
/// @param var      if zero an error message is printed into the history and procedure execution is aborted,
///                 nothing is done otherwise.  If the debugger is enabled, it also steps into it.
/// @param errorMsg error message to output in failure case
///
/// Example usage:
///@code
///ControlInfo/W = $panelTitle popup_MoreSettings_DeviceType
///ASSERT(V_flag > 0, "Non-existing control or window")
///do something with S_value
///@endcode
///
/// @hidecallgraph
/// @hidecallergraph
Function ASSERT(var, errorMsg)
	variable var
	string errorMsg

	string file, line, func, caller, stacktrace
	string abortMsg
	variable numCallers

	try
		AbortOnValue var==0, 1
	catch
		stacktrace = GetRTStackInfo(3)
		numCallers = ItemsInList(stacktrace)

		if(numCallers >= 2)
			caller = StringFromList(numCallers-2, stacktrace)
			func   = StringFromList(0, caller, ",")
			file   = StringFromList(1, caller, ",")
			line   = StringFromList(2, caller, ",")
		else
			func = ""
			file = ""
			line = ""
		endif

		sprintf abortMsg, "Assertion FAILED in function %s(...) %s:%s.\rMessage: %s\r", func, file, line, errorMsg
		printf abortMsg
		Debugger
		Abort
	endtry
End

#if defined(DEBUGGING_ENABLED)

static StrConstant functionReturnMessage = "return value"

/// @brief Output debug information and return the parameter var.
///
/// Debug function especially designed for usage in return statements.
///
/// For example calling the following function
///@code
///Function doStuff()
/// variable var = 1 + 2
/// return DEBUGPRINTv(var)
///End
///@endcode
/// will output
///@verbatim DEBUG doStuff(...)#L5: return value 3 @endverbatim
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
///@code
///Function/s doStuff()
/// variable str= "a" + "b"
/// return DEBUGPRINTs(str)
///End
///@endcode
/// will output
///@verbatim DEBUG doStuff(...)#L5: return value ab @endverbatim
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
///Examples:
///@code
///DEBUGPRINT("before a possible crash")
///DEBUGPRINT("some variable", var=myVariable)
///DEBUGPRINT("my string", str=myString)
///DEBUGPRINT("Current state", var=state, format="%.5f")
///@endcode
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

	stacktrace = GetRTStackInfo(3)

	idx = strsearch(stacktrace,"DEBUGPRINT",0)
	ASSERT(idx != -1, "Could not find the name of the current function")
	stacktrace = stacktrace[0, idx - 1]
	numCallers = ItemsInList(stacktrace)

	if(numCallers >= 1)
		caller = StringFromList(numCallers - 1, stacktrace)
		func   = StringFromList(0, caller, ",")
		file   = StringFromList(1, caller, ",")
		line   = StringFromList(2, caller, ",")
	else
		func   = ""
		file   = ""
		line   = ""
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

	if(!isEmpty(func))
		printf "DEBUG %s(...)#L%s: %s %s\r", func, line, msg, formatted
	else
		printf "DEBUG: %s %s\r", msg, formatted
	endif
End

/// @brief Start a timer for performance measurements
///
/// Usage:
/// @code
/// variable referenceTime = DEBUG_TIMER_START()
/// // part one to benchmark
/// DEBUGPRINT_ELAPSED(referenceTime)
/// // part two to benchmark
/// DEBUGPRINT_ELAPSED(referenceTime)
/// @endcode
Function DEBUG_TIMER_START()

	return stopmstimer(-2)
End

/// @brief Print the elapsed time for performance measurements
/// @see DEBUG_TIMER_START()
Function DEBUGPRINT_ELAPSED(referenceTime)
	variable referenceTime

	DEBUGPRINT("timestamp: ", var=(stopmstimer(-2) - referenceTime) / 1e6)
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

Function DEBUG_TIMER_START()

End

Function DEBUGPRINT_ELAPSED(referenceTime)
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
