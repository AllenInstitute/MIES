#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_UTILS_DEBUGGER
#endif // AUTOMATED_TESTING

/// @file MIES_Utilities_Debugger.ipf
/// @brief utility functions for debugger

/// @name Debugger state constants for DisableDebugger and ResetDebuggerState
///@{
static Constant DEBUGGER_ENABLED        = 0x01
static Constant DEBUGGER_DEBUG_ON_ERROR = 0x02
static Constant DEBUGGER_NVAR_CHECKING  = 0x04
///@}

/// @brief Disable the debugger
///
/// @returns the full debugger state binary encoded. first bit: on/off, second bit: debugOnError on/off, third bit: nvar/svar/wave checking on/off
Function DisableDebugger()

	variable debuggerState
	DebuggerOptions
	debuggerState = V_enable * DEBUGGER_ENABLED + V_debugOnError * DEBUGGER_DEBUG_ON_ERROR + V_NVAR_SVAR_WAVE_Checking * DEBUGGER_NVAR_CHECKING

	if(V_enable)
		DebuggerOptions enable=0
	endif

	return debuggerState
End

/// @brief Reset the debugger to the given state
///
/// Useful in conjunction with DisableDebugger() to temporarily disable the debugger
/// \rst
/// .. code-block:: igorpro
///
/// 	variable debuggerState = DisableDebugger()
/// 	// code which might trigger the debugger, e.g. CurveFit
/// 	ResetDebuggerState(debuggerState)
/// 	// now the debugger is in the same state as before
/// \endrst
Function ResetDebuggerState(variable debuggerState)

	variable debugOnError, nvarChecking

	if(debuggerState & DEBUGGER_ENABLED)
		debugOnError = debuggerState & DEBUGGER_DEBUG_ON_ERROR
		nvarChecking = debuggerState & DEBUGGER_NVAR_CHECKING
		DebuggerOptions enable=1, debugOnError=debugOnError, NVAR_SVAR_WAVE_Checking=nvarChecking
	endif
End

/// @brief Disable Debug on Error
///
/// @returns 1 if it was enabled, 0 if not, pass this value to ResetDebugOnError()
Function DisableDebugOnError()

	DebuggerOptions
	if(V_enable && V_debugOnError)
		DebuggerOptions enable=1, debugOnError=0
		return 1
	endif

	return 0
End

/// @brief Reset Debug on Error state
///
/// @param debugOnError state before, usually the same value as DisableDebugOnError() returned
Function ResetDebugOnError(variable debugOnError)

	if(!debugOnError)
		return NaN
	endif

	DebuggerOptions enable=1, debugOnError=debugOnError
End
