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

/// Returns one if str is empty or null, zero otherwise.
/// @param str must not be a SVAR
Function isEmpty(str)
	string& str

	variable len = strlen(str)
	return numtype(len) == 2 || len <= 0
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

/// Parse a device string of the form X_DEV_Y, where X is from DEVICE_TYPES
/// and Y from DEVICE_NUMBERS
/// @returns one on successfull parsing, zero on error
/// TODO replace all similiar usages in the rest of the code
Function ParseDeviceString(device, deviceType, deviceNumber)
	string device
	string &deviceType, &deviceNumber

	if(isEmpty(device))
		return 0
	endif

	deviceType   = StringFromList(0,device,"_")
	deviceNumber = StringFromList(2,device,"_")

	return !isEmpty(deviceType) && !isEmpty(deviceNumber)
End

/// Builds the common device string X_DEV_Y, e.g. ITC1600_DEV_O and friends
/// TODO replace all similiar usages in the rest of the code
Function/S BuildDeviceString(deviceType, deviceNumber)
	string deviceType, deviceNumber
	return deviceType + "_Dev_" + deviceNumber
End

/// Checks if the datafolder referenced by dfr exists.
/// Unlike DataFolderExists() a dfref pointing to an empty ("") dataFolder is considered non-existing here.
/// @returns one if dfr is valid and references an existing datafolder, zero otherwise
// Taken from http://www.igorexchange.com/node/2055
Function DataFolderExistsDFR(dfr)
	dfref dfr

	string dataFolder

	// invalid dfrefs don't exist
	if(DataFolderRefStatus(dfr) == 0)
		return 0
	else
		dataFolder = GetDataFolder(1,dfr)
		if( cmpstr(dataFolder,"") != 0 && DataFolderExists(dataFolder))
			return 1
		endif
	endif

	return 0
End
