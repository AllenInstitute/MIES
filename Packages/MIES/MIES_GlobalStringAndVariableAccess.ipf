#pragma TextEncoding = "UTF-8"
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
/// @code
/// Function/S GetIceCreamCounterAsVariable()
/// 	return GetNVARAsString(createDFWithAllParents("root:myfood"), "iceCreamCounter")
/// End
/// @endcode
///  and then use it in your code as
/// @code
/// Function doStuff()
/// 	NVAR iceCreamCounter = $GetIceCreamCounterAsVariable()
///
/// 	iceCreamCounter += 1
/// End
/// @endcode

/// @brief Returns the full path to a global variable
///
/// @param dfr           location of the global variable, must exist
/// @param globalVarName name of the global variable
/// @param initialValue  initial value of the variable. Will only be used if
/// 					 it is created. 0 by default.
threadsafe static Function/S GetNVARAsString(dfr, globalVarName, [initialValue])
	dfref dfr
	string globalVarName
	variable initialValue

	ASSERT_TS(DataFolderExistsDFR(dfr), "Missing dfr")

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
threadsafe static Function/S GetSVARAsString(dfr, globalStrName, [initialValue])
	dfref dfr
	string globalStrName
	string initialValue

	ASSERT_TS(DataFolderExistsDFR(dfr), "Missing dfr")

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

	if(!CmpStr(str,"") || !CmpStr(str, UNKNOWN_MIES_VERSION))
		str = CreateMiesVersion()
	endif

	return path
End

/// @brief Return the version string for the mies-igor project
///
/// @returns the mies version (e.g. Release_0.3.0.0_20141007-3-gdf4bb1e-dirty) or #UNKNOWN_MIES_VERSION
static Function/S CreateMiesVersion()

	string path, cmd, topDir, version, gitPathCandidates, gitPath
	string userName, gitDir, fullVersionPath
	variable refNum, numEntries, i

	// set path to the toplevel directory in the mies folder structure
	path = ParseFilePath(1, FunctionPath(""), ":", 1, 2)
	fullVersionPath = path + "version.txt"

	// standard locations for 32bit and 64bit standalone git versions
	gitPathCandidates = "C:\\Program Files\\Git\\mingw64\\bin\\git.exe;C:\\Program Files (x86)\\Git\\bin\\git.exe"

	// Atlassian Sourcetree (Embedded git)
	userName = GetSystemUserName()
	gitPathCandidates = AddListItem("C:\\Users\\" + userName + "\\AppData\\Local\\Atlassian\\SourceTree\\git_local\\mingw32\\bin\\git.exe", gitPathCandidates, ";", Inf)

	numEntries = ItemsInList(gitPathCandidates)
	for(i = 0; i < numEntries; i += 1)
		gitPath = StringFromList(i, gitPathCandidates)
		GetFileFolderInfo/Z/Q gitPath
		if(!V_flag) // git is installed, try to regenerate version.txt
			DEBUGPRINT("Found git at: ", str=gitPath)
			topDir = ParseFilePath(5, path, "*", 0, 0)
			gitDir = topDir + ".git"
			GetFileFolderInfo/Z/Q gitDir
			if(!V_flag) // topDir is a git repository
				// delete the old version.txt so that we can be sure to get the correct one afterwards
				DeleteFile/Z fullVersionPath
				DEBUGPRINT("Folder is a git repository: ", str=topDir)
				// explanation:
				// cmd /C "<full path to git.exe> --git-dir=<mies repository .git> describe <options> redirect everything into <mies respository>/version.txt"
				sprintf cmd "cmd.exe /C \"\"%s\" --git-dir=\"%s\" describe --always --tags > \"%sversion.txt\" 2>&1\"", gitPath, gitDir, topDir
				DEBUGPRINT("Cmd to execute: ", str=cmd)
				ExecuteScriptText/B/Z cmd
				ASSERT(!V_flag, "We have git installed but could not regenerate version.txt")
			endif

			break
		endif
	endfor

	open/R/Z refNum as path + "version.txt"
	if(V_flag != 0)
		return UNKNOWN_MIES_VERSION
	endif

	FReadLine refNum, version
	Close refNum

	DEBUGPRINT("Version.txt contents: ", str=version)

	if(IsEmpty(version) || strsearch(version, " ", 0) != -1) // only error messages have spaces
		return UNKNOWN_MIES_VERSION
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

/// @brief Return the list of follower devices of a lead device
///
/// @sa GetListofLeaderAndPossFollower()
Function/S GetFollowerList(leadPanel)
	string leadPanel

	return GetSVARAsString(GetDevicePath(leadPanel), "ListOfFollowerITC1600s", initialValue="")
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
/// the real (compared to #HARDWARE_ITC_MIN_SAMPINT) sampling interval
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

	return GetNVARAsString(GetDevicePath(panelTitle), "stopCollectionPoint", initialValue=NaN)
End

/// @brief Return the ADC to monitor
///
/// This is the first actice AD channel in ITCDataWave and ITCChanConfigWave.
Function/S GetADChannelToMonitor(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDevicePath(panelTitle), "ADChannelToMonitor", initialValue=NaN)
End

/// @brief Return global panelTitle for background tasks
/// @todo remove and use background struct members for the deviceID and GetDeviceMapping instead
Function/S GetPanelTitleGlobal()

	return GetSVARAsString(GetITCDevicesFolder(), "panelTitleG")
End

/// @brief Return the active set count
///
/// Active set count keeps track of how many steps of the largest currently
/// selected set on all active channels has been taken
Function/S GetActiveSetCount(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDevicePath(panelTitle), "activeSetCount", initialValue=NaN)
End

/// @brief Return the interactive mode
///
/// By default MIES operates in interactive mode (1). The user can change
/// that to non-interactive mode where all dialog/popups etc. are avoided
/// and replaced with sensible defaults.
Function/S GetInteractiveMode()

	return GetNVARAsString(GetMiesPath(), "interactiveMode", initialValue=1)
End

/// @brief Returns the absolute path to the testpulse running modes, holds one of @ref TestPulseRunModes
Function/S GetTestpulseRunMode(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDeviceTestPulse(panelTitle), "runMode", initialValue=NaN)
End

/// @brief Return the experiment session start time in NWB-speech
///
/// This is the time when the last device was locked.
Function/S GetSessionStartTime()

	return GetNVARAsString(GetNWBFolder(), "sessionStartTime", initialValue=NaN)
End

/// @brief Return the HDF5 file identifier for the NWB export
Function/S GetNWBFileIDExport()

	return GetNVARAsString(GetNWBFolder(), "fileIdExport", initialValue=NaN)
End

/// @brief Return the absolute path to the file for NWB export
Function/S GetNWBFilePathExport()

	return GetSVARAsString(GetNWBFolder(), "filePathExport")
End

/// @brief Return the experiment session start time in NWB-speech as
///        read back from the NWB file.
Function/S GetSessionStartTimeReadBack()

	return GetNVARAsString(GetNWBFolder(), "sessionStartTimeReadBack", initialValue=NaN)
End

/// @brief Return the thread group ID for the FIFO monitor/resetting daemon
threadsafe Function/S GetThreadGroupIDFIFO(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDevicePath(panelTitle), "threadGroupIDFifo", initialValue=NaN)
End
