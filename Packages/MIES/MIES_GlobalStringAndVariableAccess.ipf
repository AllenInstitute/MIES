#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_GlobalStringAndVariableAccess.ipf
///
/// @brief Helper functions for accessing global variables and strings.
///
/// The functions GetNVARAsString and GetSVARAsString are static as they should
/// not be used directly.
///
/// Instead if you have a global variable named `iceCreamCounter` in `root:myfood` you
/// would write in this file here a function like
///@code
///Function/S GetIceCreamCounterAsVariable()
///	return GetNVARAsString(createDFWithAllParents("root:myfood"), "iceCreamCounter")
///End
///@endcode
/// and then use it in your code as
///@code
///Function doStuff()
///	NVAR iceCreamCounter = $GetIceCreamCounterAsVariable()
///
///	iceCreamCounter += 1
///End
///@endcode

/// @brief Returns the full path to a global variable
///
/// @param dfr           location of the global variable, must exist
/// @param globalVarName name of the global variable
/// @param initialValue  initial value of the variable. Will only be used if
/// 					 it is created. 0 by default.
static Function/S GetNVARAsString(dfr, globalVarName, [initialValue])
	dfref dfr
	string globalVarName
	variable initialValue

	ASSERT(DataFolderExistsDFR(dfr), "Missing dfr")

	NVAR/Z/SDFR=dfr var = $globalVarName
	if(!NVAR_Exists(var))
		variable/G dfr:$globalVarName

		NVAR/SDFR=dfr var = $globalVarName

		if(!ParamIsDefault(initialValue))
			var = initialValue
		endif
	endif

	return GetDataFolder(1, dfr) + globalVarName
End

/// @brief Returns the full path to a global string
///
/// @param dfr           location of the global string, must exist
/// @param globalStrName name of the global string
/// @param initialValue  initial value of the string. Will only be used if
/// 					 it is created. null by default.
static Function/S GetSVARAsString(dfr, globalStrName, [initialValue])
	dfref dfr
	string globalStrName
	string initialValue

	ASSERT(DataFolderExistsDFR(dfr), "Missing dfr")

	SVAR/Z/SDFR=dfr str = $globalStrName
	if(!SVAR_Exists(str))
		String/G dfr:$globalStrName

		SVAR/SDFR=dfr str = $globalStrName

		if(!ParamIsDefault(initialValue))
			str = initialValue
		endif
	endif

	return GetDataFolder(1, dfr) + globalStrName
End

/// @brief Returns the full path to the mies-igor version string. Creating it when necessary.
///
/// Never ever write this string!
Function/S GetMiesVersion()

	string path = GetSVARAsString(GetMiesPath(), "version")
	SVAR str = $path

	if(!CmpStr(str,""))
		str = CreateMiesVersion()
	endif

	return path
End

/// @brief Return the version string for the mies-igor project
///
/// @returns the mies version (e.g. Release_0.3.0.0_20141007-3-gdf4bb1e-dirty) or "unknown version"
static Function/S CreateMiesVersion()

	string path, cmd, topDir, gitPaths, version
	variable refNum, numEntries, i

	// set path to the toplevel directory in the mies folder structure
	path = ParseFilePath(1, FunctionPath(""), ":", 1, 2)
	gitPaths = "C:\\Program Files\\Git\\mingw64\\bin\\git.exe;C:\\Program Files (x86)\\Git\\bin\\git.exe"

	numEntries = ItemsInList(gitPaths)
	for(i = 0; i < numEntries; i += 1)
		GetFileFolderInfo/Z/Q StringFromList(i, gitPaths)
		if(!V_flag) // git is installed, try to regenerate version.txt
			topDir = ParseFilePath(5, path, "*", 0, 0)
			GetFileFolderInfo/Z/Q topDir + ".git"
			if(!V_flag) // topDir is a git repository
				sprintf cmd "\"%stools\\gitVersion.bat\"", topDir
				ExecuteScriptText/Z/B/W=5 cmd
				ASSERT(!V_flag, "We have git installed but could not regenerate version.txt")
			endif

			break
		endif
	endfor

	open/R/Z refNum as path + "version.txt"
	if(V_flag != 0)
		return "unknown version"
	endif

	FReadLine refNum, version
	Close refNum

	if(IsEmpty(version))
		return "unknown version"
	endif

	return RemoveEnding(version, "\r")
End

/// @brief Returns the absolute path to the variable `DataAcqState`
///
/// The variable holds 1 if a data acquisition is currently running, 0 if not
Function/S GetDataAcqState(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDevicePath(panelTitle), "DataAcqState", initialValue=0)
End

/// @brief Returns the list of follower devices of a ITC1600 Device 0, aka the Lead Device
///
/// For backward compatibility the string is not created if it does not exist
/// This is also the reason why callers have to call it as
/// @code
/// GetFollowerList(doNotCreateSVAR=1)
/// @endcode
/// so that they remember that.
/// @todo remove the doNotCreateSVAR-hack
Function/S GetFollowerList([doNotCreateSVAR])
	variable doNotCreateSVAR

	ASSERT(!ParamIsDefault(doNotCreateSVAR) && doNotCreateSVAR == 1, "Wrong parameter, read the function documentation")
	string path = GetDevicePathAsString(ITC1600_FIRST_DEVICE)

	if(!DataFolderExists(path))
		return ""
	endif

	return path + ":ListOfFollowerITC1600s"
End

/// @brief Returns the absolute path to the ITC device ID
Function/S GetITCDeviceIDGlobal(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDevicePath(panelTitle), "ITCDeviceIDGlobal", initialValue=NaN)
End

/// @brief Returns the absolute path to the testpulse averaging buffer size
Function/S GetTPBufferSizeGlobal(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDeviceTestPulse(panelTitle), "n", initialValue=NaN)
End

/// @brief Returns the absolute path to the global variable `count` storing the
///        number of data acquisition still left to perform.
///
///        The initial value of NaN has the same semantics as the previous non existence
///        of this variable. Both meaning that no data acquisition is done right now.
Function/S GetCount(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDevicePath(panelTitle), "count", initialValue=NaN)
End

/// @brief Return the absolute path to the clamp mode string
///
/// This string holds the clamp modes of the active ADCs.
/// See also @ref AmplifierClampModes.
Function/S GetClampModeString(panelTitle)
	string panelTitle

	return GetSVARAsString(GetDeviceTestPulse(panelTitle), "clampModeString")
End

/// @brief Return the absolute path to the testpulse duration variable
///
/// The duration is for a single pulse only without baseline.
///
/// The duration is *not* in units of time but in number of points for
/// the real (compared to #MINIMUM_SAMPLING_INTERVAL) sampling interval
Function/S GetTestpulseDuration(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDeviceTestPulse(panelTitle), "duration", initialValue=NaN)
End

/// @brief Return the absolute path to the testpulse baseline fraction variable
///
/// The returned value is the fraction which the baseline occupies relative to the total
/// testpulse length, before and after the pulse itself.
Function/S GetTestpulseBaselineFraction(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDeviceTestPulse(panelTitle), "baselineFrac", initialValue=NaN)
End

/// @brief Return the absolute path to the user comment string
Function/S GetUserComment(panelTitle)
	string panelTitle

	return GetSVARAsString(GetDevicePath(panelTitle), "userComment")
End

/// @brief Return the stop collection point as calculated by DC_GetStopCollectionPoint()
Function/S GetStopCollectionPoint(panelTitle)
	string panelTitle

	// panelTitle currently unused, but kept for easier upgrade later on
	return GetNVARAsString(GetITCDevicesFolder(), "stopCollectionPoint", initialValue=NaN)
End

/// @brief Return the ADC to monitor
///
/// This is the first actice AD channel in ITCDataWave and ITCChanConfigWave.
Function/S GetADChannelToMonitor(panelTitle)
	string panelTitle

	// panelTitle currently unused, but kept for easier upgrade later on
	return GetNVARAsString(GetITCDevicesFolder(), "ADChannelToMonitor", initialValue=NaN)
End

/// @brief Return global panelTitle for background tasks
Function/S GetPanelTitleGlobal()

	return GetSVARAsString(GetITCDevicesFolder(), "panelTitleG")
End
