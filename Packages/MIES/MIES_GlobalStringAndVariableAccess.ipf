#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_GLOBALS
#endif // AUTOMATED_TESTING

/// @file MIES_GlobalStringAndVariableAccess.ipf
///
/// @brief Helper functions for accessing global variables and strings.
///
/// The functions GetNVARAsString() and GetSVARAsString() are static as they should
/// not be used directly.
///
/// Instead if you have a global variable named `iceCreamCounter` in `root:myfood` you
/// would write in this file here a function like
///
/// \rst
/// .. code-block:: igorpro
///
/// 	Function/S GetIceCreamCounterAsVariable()
/// 		return GetNVARAsString(createDFWithAllParents("root:myfood"), "iceCreamCounter")
/// 	End
/// \endrst
///
///  and then use it in your code as
///
/// \rst
/// .. code-block:: igorpro
///
/// 	Function doStuff()
/// 		NVAR iceCreamCounter = $GetIceCreamCounterAsVariable()
///
/// 		iceCreamCounter += 1
/// 	End
/// \endrst
///
/// if you want to ensure that you only get read-only access you can use ROVar() as in
///
/// \rst
/// .. code-block:: igorpro
///
/// 	Function doStuffReadOnly()
/// 		variable iceCreamCounter = ROVar(GetIceCreamCounterAsVariable())
///
/// 		iceCreamCounter += 1
/// 	End
/// \endrst
///
/// this avoids accidental changes.

/// @brief Returns the full path to a global variable
///
/// @param dfr           location of the global variable, must exist
/// @param globalVarName name of the global variable
/// @param initialValue  initial value of the variable. Will only be used if
/// 					 it is created. 0 by default.
threadsafe static Function/S GetNVARAsString(DFREF dfr, string globalVarName, [variable initialValue])

	NVAR/Z/SDFR=dfr var = $globalVarName
	if(!NVAR_Exists(var))
		ASSERT_TS(DataFolderExistsDFR(dfr), "Missing dfr")
		ASSERT_TS(IsValidObjectName(globalVarName), "Invalid globalVarName")

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
threadsafe static Function/S GetSVARAsString(DFREF dfr, string globalStrName, [string initialValue])

	SVAR/Z/SDFR=dfr str = $globalStrName
	if(!SVAR_Exists(str))
		ASSERT_TS(DataFolderExistsDFR(dfr), "Missing dfr")
		ASSERT_TS(IsValidObjectName(globalStrName), "Invalid globalStrName")

		string/G dfr:$globalStrName

		SVAR/SDFR=dfr str = $globalStrName

		if(!ParamIsDefault(initialValue))
			str = initialValue
		endif
	endif

	return GetDataFolder(1, dfr) + globalStrName
End

/// @brief Helper function to get read-only access to a global variable
///
/// @param path absolute path to a global variable
threadsafe Function ROVar(string path)

	NVAR/Z var = $path
	ASSERT_TS(NVAR_Exists(var), "Could not recreate " + path)

	return var
End

/// @brief Helper function to get read-only access to a global string
///
/// @param path absolute path to a global string
threadsafe Function/S ROStr(string path)

	SVAR/Z str = $path
	ASSERT_TS(SVAR_Exists(str), "Could not recreate " + path)

	return str
End

/// @brief Returns the full path to the mies-igor version string. Creating it when necessary.
///
/// Never ever write this string!
Function/S GetMiesVersion()

	string path = GetSVARAsString(GetMiesPath(), "version")
	SVAR   str  = $path

	if(!CmpStr(str, "") || !CmpStr(str, UNKNOWN_MIES_VERSION))
		str = CreateMiesVersion()
	endif

	return path
End

/// @brief Return a text wave with absolute paths to git binaries with HFS `:` separators
///
/// The paths may not exist.
Function/WAVE GetPossiblePathsToGit()

	string userName

#if defined(WINDOWS)
	// standard locations for 32bit and 64bit standalone git versions
	Make/FREE/T/N=(5) paths
	paths[0] = "C:Program Files:Git:mingw64:bin:git.exe"
	paths[1] = "C:Program Files (x86):Git:bin:git.exe"
	paths[2] = "C:Program Files:Git:cmd:git.exe"

	// Atlassian Sourcetree (Embedded git)
	userName = GetSystemUserName()
	paths[3] = "C:Users:" + userName + ":AppData:Local:Atlassian:SourceTree:git_local:mingw32:bin:git.exe"

	// user installation of git for windows
	paths[4] = "C:Users:" + userName + ":AppData:Local:Programs:Git:cmd:git.exe"
#elif defined(MACINTOSH)
	Make/T/FREE paths = {"Macintosh HD:usr:bin:git"}
#else
	FATAL_ERROR("Unsupported OS")
#endif

	return paths
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
static Function/S CreateMiesVersion()

	string path, topDir, version, gitPath
	string gitDir, fullVersionPath
	variable refNum
	variable ret = 1

	// set path to the toplevel directory in the mies folder structure
	path            = ParseFilePath(1, FunctionPath(""), ":", 1, 2)
	fullVersionPath = path + "version.txt"

	topDir = path
	gitDir = topDir + ".git"
	if(FolderExists(gitDir))
		// topDir is a git repository

		WAVE/T gitPathCandidates = GetPossiblePathsToGit()

		for(gitPath : gitPathCandidates)
			if(!FileExists(gitPath))
				continue
			endif

			ret = ExecuteGitForMIESVersion(gitPath, gitDir, topDir, fullVersionPath)
			break
		endfor

		if(ret)
			// none of the candidates worked, fallback to use git from PATH
			ExecuteGitForMIESVersion("git", gitDir, topDir, fullVersionPath)
		endif
	endif

	open/R/Z refNum as fullVersionPath
	if(V_flag != 0)
		printf "Could not determine the MIES version.\r"
		printf "Possible reasons:\r"
		printf "- Borked up installation, please use the installer again."
		printf "- If you are using a git clone, please ensure that you followed\r"    + \
		       "the manual installation steps correctly, and ensure that files and\r" + \
		       "folders must *not* be copied but a shortcut must be created.\r"
		ControlWindowToFront()
		return UNKNOWN_MIES_VERSION
	endif

	FStatus refNum
	version = PadString("", V_logEOF, 0x20)
	FBinRead refNum, version
	Close refNum

	version = NormalizeToEOL(version, "\r")

	DEBUGPRINT("Version.txt contents:\r\r", str = version)

	if(IsEmpty(version) || strsearch(version, "Release", 0) == -1)
		return UNKNOWN_MIES_VERSION
	endif

	return RemoveEnding(version, "\r")
End

/// @brief Run some git commands to generate version.txt from the MIES repository
///
/// @param gitPathOrName   full path to a git binary on the system or plain git for using the one in PATH
/// @param gitDir          full path to .git in the MIES repository
/// @param topDir          full path to the toplevel folder of the MIES repository
/// @param fullVersionPath full path to the version.txt file in the MIES repository
///
/// @return zero on success, aborts on failure
static Function ExecuteGitForMIESVersion(string gitPathOrName, string gitDir, string topDir, string fullVersionPath)

	string cmd, userName, shellPath

	gitPathOrName = HFSPathToNative(gitPathOrName)
	gitDir        = HFSPathToNative(gitDir)
	topDir        = HFSPathToNative(topDir)
	shellPath     = GetCmdPath()

	// git is installed, try to regenerate version.txt
	DEBUGPRINT("Found git at: ", str = gitPathOrName)

	// delete the old version.txt so that we can be sure to get the correct one afterwards
	DeleteFile/Z fullVersionPath
	DEBUGPRINT("Folder is a git repository: ", str = topDir)

#if defined(WINDOWS)
	// explanation:
	// cmd /C "<full path to git.exe> --git-dir=<mies repository .git> describe <options> redirect everything into <mies respository>/version.txt"
	sprintf cmd, "%s /C \"\"%s\" --git-dir=\"%s\" describe --always --tags --match \"Release_*\" > \"%sversion.txt\" 2>&1\"", shellPath, gitPathOrName, gitDir, topDir
	DEBUGPRINT("Cmd to execute: ", str = cmd)
	ExecuteScriptText/B/Z cmd
	ASSERT(!V_flag, "We have git installed but could not regenerate version.txt")

	sprintf cmd, "%s /C \"echo | set /p=\"Date and time of last commit: \" >> \"%sversion.txt\" 2>&1\"", shellPath, topDir
	DEBUGPRINT("Cmd to execute: ", str = cmd)
	ExecuteScriptText/B/Z cmd
	ASSERT(!V_flag, "We have git installed but could not regenerate version.txt")

	sprintf cmd, "%s /C \"\"%s\" --git-dir=\"%s\" log -1 --pretty=format:%%cI%%n >> \"%sversion.txt\" 2>&1\"", shellPath, gitPathOrName, gitDir, topDir
	DEBUGPRINT("Cmd to execute: ", str = cmd)
	ExecuteScriptText/B/Z cmd
	ASSERT(!V_flag, "We have git installed but could not regenerate version.txt")

	sprintf cmd, "%s /C \"echo Submodule status: >> \"%sversion.txt\" 2>&1\"", shellPath, topDir
	DEBUGPRINT("Cmd to execute: ", str = cmd)
	ExecuteScriptText/B/Z cmd
	ASSERT(!V_flag, "We have git installed but could not regenerate version.txt")

	// git submodule status can not be used here as submodule is currently a sh script and executing that with --git-dir does not work
	// but we can use the helper command which outputs a slightly uglier version, but is much faster
	// the submodule helper is shipped with git 2.7 and later, therefore its failed execution is not fatal
	sprintf cmd, "%s /C \"\"%s\" --git-dir=\"%s\" submodule--helper status >> \"%sversion.txt\" 2>&1\"", shellPath, gitPathOrName, gitDir, topDir
	DEBUGPRINT("Cmd to execute: ", str = cmd)
	ExecuteScriptText/B/Z cmd
#elif defined(MACINTOSH)

	sprintf cmd, "do shell script \"%s --version\"", gitPathOrName
	DEBUGPRINT("Cmd to execute: ", str = cmd)
	ExecuteScriptText/UNQ/Z cmd
	if(V_flag)
		printf "Missing functional git executable, please install the \"Xcode commandline tools\" via \"xcode-select --install\" in Terminal.\r"
		ControlWindowToFront()
		abort
	endif

	sprintf cmd, "do shell script \"%s --git-dir='%s' describe --always --tags --match 'Release_*' > '%sversion.txt' 2>&1\"", gitPathOrName, gitDir, topDir
	DEBUGPRINT("Cmd to execute: ", str = cmd)
	ExecuteScriptText/UNQ/Z cmd
	ASSERT(!V_flag, "We have git installed but could not regenerate version.txt")

	sprintf cmd, "do shell script \"printf 'Date and time of last commit: ' >> '%sversion.txt' 2>&1\"", topDir
	DEBUGPRINT("Cmd to execute: ", str = cmd)
	ExecuteScriptText/UNQ/Z cmd
	ASSERT(!V_flag, "We have git installed but could not regenerate version.txt")

	sprintf cmd, "do shell script \"%s --git-dir='%s' log -1 --pretty=format:%%cI%%n >> '%sversion.txt' 2>&1\"", gitPathOrName, gitDir, topDir
	DEBUGPRINT("Cmd to execute: ", str = cmd)
	ExecuteScriptText/UNQ/Z cmd
	ASSERT(!V_flag, "We have git installed but could not regenerate version.txt")

	sprintf cmd, "do shell script \"echo 'Submodule status:' >> '%sversion.txt' 2>&1\"", topDir
	DEBUGPRINT("Cmd to execute: ", str = cmd)
	ExecuteScriptText/UNQ/Z cmd
	ASSERT(!V_flag, "We have git installed but could not regenerate version.txt")

	// see comment in WINDOWS branch
	sprintf cmd, "do shell script \"%s --git-dir='%s' submodule--helper status >> '%sversion.txt' 2>&1\"", gitPathOrName, gitDir, topDir
	DEBUGPRINT("Cmd to execute: ", str = cmd)
	ExecuteScriptText/UNQ/Z cmd
#else
	FATAL_ERROR("Unsupported OS")
#endif

	return 0
End

/// @brief Returns the absolute path to the variable `runMode`
///
/// The variable holds one of @ref DAQRunModes.
Function/S GetDataAcqRunMode(string device)

	return GetNVARAsString(GetDevicePath(device), "runMode", initialValue = DAQ_NOT_RUNNING)
End

/// @brief Returns the absolute path to the device ID
Function/S GetDAQDeviceID(string device)

	return GetNVARAsString(GetDevicePath(device), "deviceID", initialValue = NaN)
End

/// @brief Returns the absolute path to the global variable `count` storing the
///        number of data acquisition cycles performed.
///
/// Count equals zero on the first sweep.
Function/S GetCount(string device)

	return GetNVARAsString(GetDevicePath(device), "count", initialValue = 0)
End

/// @brief Returns the list of locked devices
Function/S GetLockedDevices()

	string device

	return GetSVARAsString(GetDAQDevicesFolder(), "lockedDevices", initialValue = "")
End

/// @brief Return the absolute path to the user comment string
Function/S GetUserComment(string device)

	return GetSVARAsString(GetDevicePath(device), "userComment")
End

/// @brief Return the stop collection point, this is a *length* in points.
///        The StopCollectionPoint is the effective length of the DAC data.
///        While for NI and SUTTER hardware this equals the length of the DAC output wave,
///        for ITC the DAC output wave is longer, see @ref DC_CalculateDAQDataWaveLengthImpl.
///
///        Also for SUTTER hardware the ADC input wave length is different from the DAC output wave.
///        StopCollectionPoint CAN NOT be used to determine the length of the ADC input wave.
///
/// @sa GetFifoPosition()
Function/S GetStopCollectionPoint(string device)

	return GetNVARAsString(GetDevicePath(device), "stopCollectionPoint", initialValue = NaN)
End

/// @brief Return the ADC to monitor
///
/// This is the first actice AD channel in DAQDataWave and DAQConfigWave.
Function/S GetADChannelToMonitor(string device)

	return GetNVARAsString(GetDevicePath(device), "ADChannelToMonitor", initialValue = NaN)
End

/// @brief Return global device for background tasks
/// @todo remove and use background struct members for the deviceID and GetDeviceMapping instead
Function/S GetRunningSingleDevice()

	return GetSVARAsString(GetDAQDevicesFolder(), "runningDevice")
End

/// @brief Return the active set count
///
/// Active set count keeps track of how many steps of the largest currently
/// selected set on all active channels still have to be done. Not counting the
/// currently acquiring sweep.
Function/S GetActiveSetCount(string device)

	return GetNVARAsString(GetDevicePath(device), "activeSetCount", initialValue = NaN)
End

/// @brief Return the interactive mode
///
/// By default MIES operates in interactive mode (1) in the main thread and in
/// non-interactive mode in preemptive threads. The user can change that to
/// non-interactive mode where all dialog/popups etc. are avoided and replaced
/// with sensible defaults.
threadsafe Function/S GetInteractiveMode()

	return GetNVARAsString(GetMiesPath(), "interactiveMode", initialValue = !!MU_RunningInMainThread())
End

/// @brief Returns the absolute path to the testpulse running modes, holds one of @ref TestPulseRunModes
Function/S GetTestpulseRunMode(string device)

	return GetNVARAsString(GetDeviceTestPulse(device), "runMode", initialValue = TEST_PULSE_NOT_RUNNING)
End

/// @brief Returns SU device list
///
/// Internal use only, prefer DAP_GetSUDeviceList() instead.
///
/// The initial value `""` is different from #NONE which denotes no matches.
Function/S GetSUDeviceList()

	// note: this global gets killed in IH_KillTemporaries
	return GetSVARAsString(GetDAQDevicesFolder(), "SUDeviceList", initialValue = "")
End

/// @brief Returns NI device list
///
/// Internal use only, prefer DAP_GetNIDeviceList() instead.
///
/// The initial value `""` is different from #NONE which denotes no matches.
Function/S GetNIDeviceList()

	// note: this global gets killed in IH_KillTemporaries
	return GetSVARAsString(GetDAQDevicesFolder(), "NIDeviceList", initialValue = "")
End

/// @brief Returns ITC device list
///
/// Internal use only, prefer DAP_GetITCDeviceList() instead.
///
/// The initial value `""` is different from #NONE which denotes no matches.
Function/S GetITCDeviceList()

	// note: this global gets killed in IH_KillTemporaries
	return GetSVARAsString(GetDAQDevicesFolder(), "ITCDeviceList", initialValue = "")
End

/// @brief Returns the last time stamp HW_NI_RepeatAcqHook was called
Function/S GetLastAcqHookCallTimeStamp(string device)

	return GetNVARAsString(GetDeviceTestPulse(device), "acqHookTimeStamp", initialValue = DateTime)
End

/// @brief Returns FIFO file reference
Function/S GetFIFOFileRef(string device)

	return GetNVARAsString(GetDeviceTestPulse(device), "FIFOFileRef", initialValue = 0)
End

/// @brief Returns TestPulse Counter for Background Task
Function/S GetNITestPulseCounter(string device)

	return GetNVARAsString(GetDeviceTestPulse(device), "NITestPulseCounter", initialValue = 0)
End

/// @brief Returns the current NI setup string for analog in through DAQmx_Scan
Function/S GetNI_AISetup(string device)

	return GetSVARAsString(GetDevicePath(device), "NI_AI_setupStr0")
End

/// @brief Returns the ADC task ID set after DAQmx_Scan in HW_NI_StartAcq
Function/S GetNI_ADCTaskID(string device)

	return GetNVARAsString(GetDevicePath(device), "NI_ADC_taskID", initialValue = NaN)
End

/// @brief Returns the DAC task ID set after DAQmx_WaveFormGen in HW_NI_PrepareAcq
Function/S GetNI_DACTaskID(string device)

	return GetNVARAsString(GetDevicePath(device), "NI_DAC_taskID", initialValue = NaN)
End

/// @brief Returns if the Sutter hardware is acquiring
Function/S GetSU_IsAcquisitionRunning(string device)

	return GetNVARAsString(GetDevicePath(device), "SU_AcquisitionRunning", initialValue = 0)
End

/// @brief Returns if the Sutter hardware had an acquisition error
Function/S GetSU_AcquisitionError(string device)

	return GetNVARAsString(GetDevicePath(device), "SU_AcquisitionError", initialValue = 0)
End

/// @brief Returns the TTL task ID set by DAQmx_DIO_Config in HW_NI_PrepareAcq
Function/S GetNI_TTLTaskID(string device)

	return GetNVARAsString(GetDevicePath(device), "NI_TTL_taskID", initialValue = NaN)
End

/// @brief Return the Analysis Browser experiment session start time (only used for NWB type experiments)
Function/S GetAnalysisExpSessionStartTime(string dataFolder)

	return GetSVARAsString(GetAnalysisExpFolder(dataFolder), "sessionStartTime", initialValue = "")
End

/// @brief Returns the global that stores the last acquisition start time
Function/S GetLastAcquisitionStartTime(string device)

	return GetSVARAsString(GetDevicePath(device), "LastAcquisitionStartTime", initialValue = "")
End

/// @brief Return the experiment session start time in NWB-speech
///
/// This is the time when the last device was locked.
Function/S GetSessionStartTime()

	return GetNVARAsString(GetNWBFolder(), "sessionStartTime", initialValue = NaN)
End

/// @brief Return the HDF5 file identifier for the NWB export
Function/S GetNWBFileIDExport(string device)

	return GetNVARAsString(GetDevicePath(device), "NWBfileIdExport", initialValue = NaN)
End

/// @brief Return the absolute path to the file for NWB export
Function/S GetNWBFilePathExport(string device)

	return GetSVARAsString(GetDevicePath(device), "NWBfilePathExport")
End

/// @brief Return the experiment session start time in NWB-speech as
///        read back from the NWB file.
Function/S GetSessionStartTimeReadBack(string device)

	return GetNVARAsString(GetDevicePath(device), "sessionStartTimeReadBack", initialValue = NaN)
End

/// @brief Return the thread group ID for the FIFO monitor/resetting daemon
threadsafe Function/S GetThreadGroupIDFIFO(string device)

	return GetNVARAsString(GetDevicePath(device), "threadGroupIDFifo", initialValue = NaN)
End

/// @brief Return the absolute path to the temporary global string
///
/// Callers should always assume that this string contains garbage.
Function/S GetTemporaryString()

	return GetSVARAsString(GetTempPath(), "tempString")
End

/// @brief Return the absolute path to the temporary global variable
///
/// Callers should always assume that this variable contains garbage.
Function/S GetTemporaryVar()

	return GetNVARAsString(GetTempPath(), "tempVar")
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
Function/S GetRNGSeed(string device)

	return GetNVARAsString(GetDevicePath(device), "rngSeed", initialValue = NaN)
End

/// @brief Return the absolute path to the repeated acquisition cycle ID
Function/S GetRepeatedAcquisitionCycleID(string device)

	return GetNVARAsString(GetDevicePath(device), "raCycleID", initialValue = NaN)
End

/// @brief Return the absolute path to the repurposed sweep time global variable.
///
/// Units are seconds.
///
/// This value is added on *top* of the left over sweep time. Use a negative
/// value to have a shorter ITI than what is left over in the sweep.
///
/// @sa LeftOverSweepTime()
Function/S GetRepurposedSweepTime(string device)

	return GetNVARAsString(GetDevicePath(device), "additionalITI", initialValue = 0)
End

/// @brief Return the list of functions to be executed after ITI in repeated acquisition
Function/S GetRepeatedAcquisitionFuncList()

	return GetSVARAsString(GetDAQDevicesFolder(), "repeatedAcqFuncList", initialValue = "")
End

/// @brief Return the start time, in ticks, of the ITI cycle
Function/S GetRepeatedAcquisitionStart()

	return GetNVARAsString(GetDAQDevicesFolder(), "repeatedAcqStart", initialValue = 0)
End

/// @brief Return the duration, in ticks, of the ITI cycle
Function/S GetRepeatedAcquisitionDuration()

	return GetNVARAsString(GetDAQDevicesFolder(), "repeatedAcqDuration", initialValue = 0)
End

/// @brief Return the current fifo position (a length)
///
/// Only valid if called during DAQ with DATA_ACQUISITION_MODE.
/// This value is relative to first row of the rawDACWave, so an
/// possible offset is already included in it.
Function/S GetFifoPosition(string device)

	return GetNVARAsString(GetDevicePath(device), "fifoPosition", initialValue = NaN)
End

/// @brief Return the error counter for the analysis function management
///
/// Mainly used during testing to ensure that no RTE was thrown.
Function/S GetAnalysisFuncErrorCounter(string device)

	return GetNVARAsString(GetDevicePath(device), "analysisFunctionErrorCounter", initialValue = 0)
End

/// @brief Return the maximum ITI of all active sets
///
/// Only meaningful after preparing DAQ in DC_Configure()
Function/S GetMaxIntertrialInterval(string device)

	return GetNVARAsString(GetDevicePath(device), "maxIntertrialInterval", initialValue = 0)
End

/// @brief Return the version number of the Igor experiment
Function/S GetPxPVersion()

	return GetNVARAsString(GetMiesPath(), "pxpVersion", initialValue = EXPERIMENT_VERSION)
End

/// @brief Return the version number of the Igor experiment loaded into the analysis browser
///
/// @param dfr experiment folder, @sa GetAnalysisExpFolder()
Function/S GetPxPVersionForAB(DFREF dfr)

	return GetNVARAsString(dfr, "pxpVersion", initialValue = NaN)
End

/// @brief Return the JSON ID for the sweep formula
Function/S GetSweepFormulaJSONid(DFREF dfr)

	return GetNVARAsString(dfr, "sweepFormulaJSONid", initialValue = NaN)
End

/// @brief Return the formula output message for the sweep formula
Function/S GetSweepFormulaOutputMessage()

	return GetSVARAsString(GetSweepFormulaPath(), "outputResult")
End

/// @brief Return the formula error severity for the sweep formula, @sa SFOutputSeverity
Function/S GetSweepFormulaOutputSeverity()

	return GetNVARAsString(GetSweepFormulaPath(), "outputSeverity")
End

/// @brief Return the JSON id of the settings file
///
/// Loads the stored settings on disc if required.
Function/S GetSettingsJSONid()

	string path   = GetNVARAsString(GetMiesPath(), "settingsJSONid", initialValue = NaN)
	NVAR   JSONid = $path

	// missing or stale JSON document
	if(!JSON_IsValid(JSONid))
		JSONid = PS_ReadSettings(PACKAGE_MIES, GenerateSettingsDefaults)
		CONF_UpdatePackageSettingsFromConfigFiles(JSONid)
	endif

	UpgradeSettings(JSONid)

	return path
End

/// @brief Return the path to the acquisition state
///
/// Holds one of @ref AcquisitionStates
Function/S GetAcquisitionState(string device)

	return GetNVARAsString(GetDevicePath(device), "acquisitionState", initialValue = AS_INACTIVE)
End

/// @brief Return the global bug count, incremented by Bug()
///
/// Mostly used for testing.
Function/S GetBugCount()

	return GetNVARAsString(GetMiesPath(), "bugCount", initialValue = 0)
End

/// @brief Temporary storage for IP history and logfile
///
/// Used for reexporting from NWBv1 into NWBv2, see AB_ReExport()
Function/S GetNWBOverrideHistoryAndLogFile()

	return GetSVARAsString(GetNwBFolder(), "overrideHistoryAndLogFile")
End

/// @brief Return the absolute path to the test pulse cycle ID
Function/S GetTestpulseCycleID(string device)

	return GetNVARAsString(GetDeviceTestPulse(device), "tpCycleID", initialValue = NaN)
End

/// @brief Returns the path to the "called once" variable of the given name
Function/S GetCalledOnceVariable(string name)

	return GetNVARAsString(GetCalledOncePath(), name, initialValue = 0)
End

/// @brief Returns string path to the thread group id
Function/S GetThreadGroupID()

	return GetNVARAsString(getAsyncHomeDF(), "threadGroupID", initialValue = NaN)
End

/// @brief Returns string path to the number of threads
Function/S GetNumThreads()

	return GetNVARAsString(getAsyncHomeDF(), "numThreads", initialValue = 0)
End

/// @brief Returns string path to flag if background task was disabled
Function/S GetTaskDisableStatus()

	return GetNVARAsString(getAsyncHomeDF(), "disableTask", initialValue = 0)
End

/// @brief Returns the string path to the last successfully executed SweepFormula code
Function/S GetLastSweepFormulaCode(DFREF dfr)

	return GetSVARAsString(dfr, "lastSweepFormulaCode", initialValue = "")
End

/// @brief Returns the reference count variable of the given DF
Function/S GetDFReferenceCount(DFREF dfr)

	return GetNVARAsString(dfr, MEMORY_REFCOUNTER_DF, initialValue = 0)
End

/// @brief Return the current JSON path in the sweep formula execution
Function/S GetSweepFormulaJSONPathTracker()

	return GetSVARAsString(GetSweepFormulaPath(), "sweepFormulaJSONPath", initialValue = "")
End

/// @brief Return the current buffer offset in the sweep formula parser
Function/S GetSweepFormulaBufferOffsetTracker()

	return GetNVARAsString(GetSweepFormulaPath(), "sweepFormulaParserBufferOffset", initialValue = NaN)
End
