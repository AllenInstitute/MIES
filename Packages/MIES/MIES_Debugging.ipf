#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file TJ_MIES_Debugging.ipf
///
/// @brief Holds functions for handling debugging information

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
