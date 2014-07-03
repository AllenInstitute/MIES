#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file TJ_MIES_Utilities.ipf
/// This file holds general utility functions available for all other procedures

/// Used by CheckName and UniqueName
Constant CONTROL_PANEL_TYPE = 9

/// See "Control Structure eventMod Field"
Constant EVENT_MOUSE_UP = 2

/// Returns 1 if str is null, 0 otherwise
/// @param str must not be a SVAR
Function isNull(str)
	string& str

	variable len = strlen(str)
	return numtype(len) == 2
End

/// Low overhead function to check assertions
/// @param var if zero an error message is printed into the history, nothing is done otherwise.
/// If the debugger is enabled, it also steps into it.
/// @param errorMsg error message to output in failure case
/// Example usage:
/// @code
///	ControlInfo /w = $panelTitle popup_MoreSettings_DeviceTypeh
///	ASSERT(V_flag > 0, "Non-existing control or window")
/// do something with S_value
/// @endcode
Function ASSERT(var,errorMsg)
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
			caller     = StringFromList(numCallers-2,stacktrace)
			func       = StringFromList(0,caller,",")
			file       = StringFromList(1,caller,",")
			line       = StringFromList(2,caller,",")
		else
			func = ""
			file = ""
			line = ""
		endif

		sprintf abortMsg, "Assertion FAILED in function %s(...) %s:%s.\rMessage: %s\r", func, file, line, errorMsg
		printf abortMsg
		Debugger
	endtry
End

/// Checks if the given name exists as window
Function windowExists(win)
	string win

	if(isNull(win) || cmpstr(CleanupName(win,0),win) != 0)
		return 0
	endif

	DoWindow $win
	return V_flag != 0
End
