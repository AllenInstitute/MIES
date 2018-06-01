#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_GLOBALS
#endif

/// @file MIES_GlobalStringAndVariableAccess.ipf
///
/// @brief Helper functions for accessing global variables and strings.
///
/// The functions GetNVARAsString and GetSVARAsString are static as they should
/// not be used directly.
///
/// Instead if you have a global variable named `iceCreamCounter` in `root:myfood` you
/// would write in this file here a function like
/// \rst
/// .. code-block:: igorpro
///
/// 	Function/S GetIceCreamCounterAsVariable()
/// 		return GetNVARAsString(createDFWithAllParents("root:myfood"), "iceCreamCounter")
/// 	End
/// \endrst
///  and then use it in your code as
/// \rst
/// .. code-block:: igorpro
///
/// 	Function doStuff()
/// 		NVAR iceCreamCounter = $GetIceCreamCounterAsVariable()
///
/// 		iceCreamCounter += 1
/// 	End
/// \endrst

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
/// The mies version looks like
///
/// @verbatim
/// Release_1.4_20170929-16-g497e7aa8
/// Date and time of last commit: 2018-05-08T14:42:50+02:00
/// Submodule status:
/// 160000 6c47163858d99986b27c70f6226e8fca894ed5f7 0	Packages/IPNWB
/// 160000 ed7e824a6e065e383ae31bb304383e13d7c7ccb5 0	Packages/ITCXOP2
/// 160000 2bd259940cb332339ed3c82b74632f06c9b68a15 0	Packages/ZeroMQ
/// 160000 657e9e8abdc92aa299301796d710a0a717da4ef8 0	Packages/unit-testing
/// @endverbatim
///
/// or #UNKNOWN_MIES_VERSION on error
///
/// @returns the mies version
Function/S CreateMiesVersion()

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

				sprintf cmd "cmd.exe /C \"echo | set /p=\"Date and time of last commit: \" >> \"%sversion.txt\" 2>&1\"", topDir
				DEBUGPRINT("Cmd to execute: ", str=cmd)
				ExecuteScriptText/B/Z cmd
				ASSERT(!V_flag, "We have git installed but could not regenerate version.txt")

				sprintf cmd "cmd.exe /C \"\"%s\" --git-dir=\"%s\" log -1 --pretty=format:%%cI%%n >> \"%sversion.txt\" 2>&1\"", gitPath, gitDir, topDir
				DEBUGPRINT("Cmd to execute: ", str=cmd)
				ExecuteScriptText/B/Z cmd
				ASSERT(!V_flag, "We have git installed but could not regenerate version.txt")

				sprintf cmd "cmd.exe /C \"echo Submodule status: >> \"%sversion.txt\" 2>&1\"", topDir
				DEBUGPRINT("Cmd to execute: ", str=cmd)
				ExecuteScriptText/B/Z cmd
				ASSERT(!V_flag, "We have git installed but could not regenerate version.txt")

				// git submodule status can not be used here as submodule is currently a sh script and executing that with --git-dir does not work
				// but we can use the helper command which outputs a slightly uglier version, but is much faster
				// the submodule helper is shipped with git 2.7 and later, therefore its failed execution is not fatal
				sprintf cmd "cmd.exe /C \"\"%s\" --git-dir=\"%s\" submodule--helper list >> \"%sversion.txt\" 2>&1\"", gitPath, gitDir, topDir
				DEBUGPRINT("Cmd to execute: ", str=cmd)
				ExecuteScriptText/B/Z cmd
			endif

			break
		endif
	endfor

	open/R/Z refNum as path + "version.txt"
	if(V_flag != 0)
		return UNKNOWN_MIES_VERSION
	endif

	FStatus refNum
	version = PadString("", V_logEOF, 0x20)
	FBinRead refNum, version
	Close refNum

	version = NormalizeToEOL(version, "\r")

	DEBUGPRINT("Version.txt contents:\r\r", str=version)

	if(IsEmpty(version) || strsearch(version, "Release", 0) == -1)
		return UNKNOWN_MIES_VERSION
	endif

	return RemoveEnding(version, "\r")
End

/// @brief Returns the absolute path to the variable `runMode`
///
/// The variable holds one of @ref DAQRunModes.
Function/S GetDataAcqRunMode(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDevicePath(panelTitle), "runMode", initialValue=DAQ_NOT_RUNNING)
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
///        number of data acquisition cycles performed.
///
/// Count equals zero on the first sweep.
Function/S GetCount(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDevicePath(panelTitle), "count", initialValue=0)
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
/// selected set on all active channels still have to be done. Not counting the
/// currently acquiring sweep.
Function/S GetActiveSetCount(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDevicePath(panelTitle), "activeSetCount", initialValue=NaN)
End

/// @brief Return the interactive mode
///
/// By default MIES operates in interactive mode (1). The user can change
/// that to non-interactive mode where all dialog/popups etc. are avoided
/// and replaced with sensible defaults.
threadsafe Function/S GetInteractiveMode()

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

/// @brief Return the absolute path to the temporary global string
///
/// Callers should always assume that this string contains garbage.
Function/S GetTemporaryString()

	return GetSVARAsString(GetTempPath(), "tempString")
End

/// @brief Return the absolute path to the RNG seed value
///
/// This seed value can be used for deriving device dependent random numbers.
///
/// Typical sequence:
///
/// \rst
/// .. code-block:: igorpro
///
/// 	NVAR rngSeed = $GetRNGSeed(device)
/// 	SetRandomSeed/BETR=1 rngSeed
/// 	rngSeed += 1
/// 	variable val = GetReproducibleRandonNumber()
/// \endrst
Function/S GetRNGSeed(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDevicePath(panelTitle), "rngSeed", initialValue=NaN)
End

/// @brief Return the absolute path to the repeated acquisition cycle ID
Function/S GetRepeatedAcquisitionCycleID(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDevicePath(panelTitle), "raCycleID", initialValue=NaN)
End

/// @brief Return the absolute path to the repurposed sweep time global variable.
///
/// Units are seconds.
Function/S GetRepurposedSweepTime(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDevicePath(panelTitle), "additionalITI", initialValue = 0)
End

/// @brief Return the list of functions to be executed after ITI in repeated acquisition
Function/S GetRepeatedAcquisitionFuncList()

	return GetSVARAsString(GetITCDevicesFolder(), "repeatedAcqFuncList", initialValue = "")
End

/// @brief Return the start time, in ticks, of the ITI cycle
Function/S GetRepeatedAcquisitionStart()

	return GetNVARAsString(GetITCDevicesFolder(), "repeatedAcqStart", initialValue = 0)
End

/// @brief Return the duration, in ticks, of the ITI cycle
Function/S GetRepeatedAcquisitionDuration()

	return GetNVARAsString(GetITCDevicesFolder(), "repeatedAcqDuration", initialValue = 0)
End

/// @brief Return the current fifo position. Only valid if called during DAQ with DATA_ACQUISITION_MODE.
Function/S GetFifoPosition(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDevicePath(panelTitle), "fifoPosition", initialValue = NaN)
End

/// @brief Return history capture reference number
///
/// Used for storing the igor history in NWB
Function/S GetHistoryRefNumber()

	return GetNVARAsString(GetNWBFolder(), "histRefNumber", initialValue = NaN)
End

/// @brief Return the error counter for the analysis function management
///
/// Mainly used during testing to ensure that no RTE was thrown.
Function/S GetAnalysisFuncErrorCounter(panelTitle)
	string panelTitle

	return GetNVARAsString(GetDevicePath(panelTitle), "analysisFunctionErrorCounter", initialValue = 0)
End
