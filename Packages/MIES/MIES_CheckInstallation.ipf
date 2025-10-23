#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_CHI
#endif // AUTOMATED_TESTING

/// @file MIES_CheckInstallation.ipf
///
/// @brief __CHI__ Routines for checking the health of the
///        MIES installation

static StrConstant CHI_NIDAQ_XOP_64_HASH  = "b13267a080053c07b80302212b7f73ac199e1f001d9a1b4303e2d7dce1aeb39e"
static StrConstant CHI_JSON_XOP_VERSION   = "version-919-g9b6b617"
static StrConstant CHI_TUF_XOP_VERSION    = "version-163-g686effb"
static StrConstant CHI_ITC_XOP_VERSION    = "latest-174-gb9915a9"
static StrConstant CHI_ZEROMQ_XOP_64_HASH = "06b4fab7456a4a8922b42cef6c4ee5081916017e886022461375d48bb555eae3"

static StrConstant CHI_INSTALLCONFIG_NAME          = "installation_configuration.json"
static Constant    CHI_INSTALLDEFAULT_WITHHARDWARE = 1
static StrConstant CHI_INSTALLDEFAULT_ALLUSER      = "current"

/// @brief Collection of counters used for installation checking
static Structure CHI_InstallationState
	variable numErrors
	variable numTries
EndStructure

static Function CHI_InitInstallationState(STRUCT CHI_InstallationState &state)

	state.numErrors = 0
	state.numTries  = 0
End

static Function CHI_CheckJSONXOPVersion(STRUCT CHI_InstallationState &state)

	variable id
	string info, version

	info    = JSON_Version()
	id      = JSON_Parse(info)
	version = JSON_GetString(id, "/XOP/version", ignoreErr = 1)

	CHI_OutputVersionCheckResult(state, "JSON", CHI_JSON_XOP_VERSION, version)
End

static Function CHI_CheckTUFXOPVersion(STRUCT CHI_InstallationState &state)

	variable id
	string   version

	TUFXOP_Version
	id      = JSON_Parse(S_value)
	version = JSON_GetString(id, "/version", ignoreErr = 1)

	CHI_OutputVersionCheckResult(state, "TUF", CHI_TUF_XOP_VERSION, version)
End

static Function CHI_OutputVersionCheckResult(STRUCT CHI_InstallationState &state, string xopName, string expectedVersion, string foundVersion)

	if(!cmpstr(foundVersion, expectedVersion))
		printf "%s XOP: Present in the right version (%s) (Nice!)\r", xopName, foundVersion
	else
		printf "%s XOP: Present in the wrong version (expected: %s vs present: %s) (Very Bad)\r", xopName, expectedVersion, foundVersion
		state.numErrors += 1
	endif
End

static Function CHI_CheckITCXOPVersion(STRUCT CHI_InstallationState &state)

	string version

	WAVE/Z/T versionInfo = HW_ITC_GetVersionInfo(flags = HARDWARE_PREVENT_ERROR_MESSAGE)

	if(!WaveExists(versionInfo) || FindDimLabel(versionInfo, ROWS, "XOP") < 0)
		version = "error querying version"
	else
		version = RemovePrefix(versionInfo[%XOP][%Description], start = "ITCXOP2: ")
	endif

	CHI_OutputVersionCheckResult(state, "ITC2", CHI_ITC_XOP_VERSION, version)
End

/// @brief Search list for matches of item and print the results
static Function CHI_CheckXOP(WAVE/T list, string item, string name, STRUCT CHI_InstallationState &state, [string expectedHash])

	variable numMatches, i, hashMatches
	string fileVersion, filepath, existingHash, hashMsg

	WAVE/Z/T matches = GrepTextWave(list, "(?i)" + item)
	numMatches = WaveExists(matches) ? DimSize(matches, ROWS) : 0

	if(numMatches > 1)
		if(CheckIfPathsRefIdenticalFiles(matches))
			// multiple paths point to the same file
			// this can be handled by Igor properly
			numMatches = 1
		endif
	endif

	state.numTries += 1

	switch(numMatches)
		case 0:
			printf "%s: The file %s could not be found (Very Bad)\r", name, item
			state.numErrors += 1
			break
		case 1:
			filepath    = matches[0]
			fileVersion = GetFileVersion(filepath)
			if(ParamIsDefault(expectedHash))
				printf "%s: Found version %s (Nice!)\r", name, fileVersion
			else
				existingHash = CalcHashForFile(filepath)
				hashMatches  = !cmpstr(existingHash, expectedHash)
				hashMsg      = SelectString(hashMatches, "not ok (" + expectedHash + " vs " + existingHash + ")", "ok")
				printf "%s: Found version %s and hash is %s (%s)\r", name, fileVersion, hashMsg, SelectString(hashMatches, "Very Bad", "Nice!")
				state.numErrors += !hashMatches
			endif
			break
		default:
			printf "%s: Found multiple versions in \"%s\" (Might create problems)\r", name, TextWaveToList(matches, ", ", trailSep = 0)
			printf "%s: Duplicates are:\r", name
			for(i = 0; i < numMatches; i += 1)
				filepath    = matches[i]
				fileVersion = GetFileVersion(filepath)
				if(ParamIsDefault(expectedHash))
					printf "%s: Found version %s\r", name, fileVersion
				else
					existingHash = CalcHashForFile(filepath)
					hashMatches  = !cmpstr(existingHash, expectedHash)
					hashMsg      = SelectString(hashMatches, "not ok (" + expectedHash + " vs " + existingHash + ")", "ok")
					printf "%s: Found version %s and hash is %s\r", name, fileVersion, hashMsg
					state.numErrors += !hashMatches
				endif
			endfor
			state.numErrors += 1
			break
	endswitch
End

/// @return JSON id or NaN if configuration file does not exist
static Function CHI_LoadInstallationConfiguration()

	string folder, fullFilePath, txt

	folder       = ParseFilePath(1, FunctionPath(""), ":", 1, 2)
	fullFilePath = folder + CHI_INSTALLCONFIG_NAME
	if(!FileExists(fullFilePath))
		return NaN
	endif
	[txt, fullFilePath] = LoadTextFile(fullFilePath)
	return JSON_Parse(txt, ignoreErr = 1)
End

/// @param key key in JSON tree under /Installation
/// @param defValue [optional] default value to return if the key does not exist. Either defValue or defSValue can be given as argument, not both.
/// @param defSValue [optional] default value to return if the key does not exist. Either defValue or defSValue can be given as argument, not both.
/// @return either value or sValue depending on requested JSOn key, the unused result value is either Nan or "".
static Function [variable value, string sValue] CHI_GetInstallationConfigProp(string key, [variable defValue, string defSValue])

	variable jsonId, objType
	string jPath

	ASSERT((ParamIsDefault(defValue) + ParamIsDefault(defSValue)) == 1, "Either defValue or defSValue must be given")

	jsonId = CHI_LoadInstallationConfiguration()
	if(IsNaN(jsonId))
		if(ParamIsDefault(defValue))
			return [NaN, defSValue]
		endif
		return [defValue, ""]
	endif

	jPath = "/Installation/" + key

	ClearRTError()
	try
		objType = JSON_GetType(jsonId, jPath)
	catch
		FATAL_ERROR("The following path could not be found in installation configuration: " + jPath)
	endtry
	if(objType == JSON_NUMERIC)
		value = JSON_GetVariable(jsonId, jPath)
		JSON_Release(jsonId)
		return [value, ""]
	elseif(objType == JSON_STRING)
		sValue = JSON_GetString(jsonId, jPath)
		JSON_Release(jsonId)
		return [NaN, sValue]
	endif

	FATAL_ERROR("Unsupported JSON object type")
End

/// @return 1 if MIES was installed with hardware support, 0 otherwise
Function CHI_IsMIESInstalledWithHardware()

	variable installedWithHW
	string   s

	[installedWithHW, s] = CHI_GetInstallationConfigProp("WithHardware", defValue = CHI_INSTALLDEFAULT_WITHHARDWARE)

	return installedWithHW
End

/// @return 1 if MIES was installed for all users, 0 otherwise
Function CHI_IsMIESInstalledForAllUsers()

	variable value
	string   installType

	[value, installType] = CHI_GetInstallationConfigProp("User", defSValue = CHI_INSTALLDEFAULT_ALLUSER)
	ASSERT(!CmpStr(installType, "current") || !CmpStr(installType, "all"), "Read unknown installation type from installation configuration")

	return !CmpStr(installType, "all")
End

/// @brief Check the installation and print the results to the history
///
/// Currently checks that all expected/optional XOPs are installed.
///
/// @return number of errors
Function CHI_CheckInstallation()

	string symbPath, allFiles, path, extName, info, igorBuild
	variable aslrEnabled, archBits, installedWithHW

	symbPath = GetUniqueSymbolicPath()
	extName  = GetIgorExtensionFolderName()

	path = SpecialDirPath("Igor Pro User Files", 0, 0, 0) + extName
	NewPath/Q/O $symbPath, path
	WAVE/Z/T allFilesUser = GetAllFilesRecursivelyFromPath(symbPath, regex = "(?i)\.xop$", resolveAliases = 1)

	path = SpecialDirPath("Igor Application", 0, 0, 0) + extName
	NewPath/Q/O $symbPath, path
	WAVE/Z/T allFilesSystem = GetAllFilesRecursivelyFromPath(symbPath, regex = "(?i)\.xop$", resolveAliases = 1)

	KillPath $symbPath

	if(WaveExists(allFilesUser) && WaveExists(allFilesSystem))
		Concatenate/T/FREE/NP=(ROWS) {allFilesUser, allFilesSystem}, listWithDuplicates
	elseif(WaveExists(allFilesUser))
		WAVE/T listWithDuplicates = allFilesUser
	elseif(WaveExists(allFilesSystem))
		WAVE/T listWithDuplicates = allFilesSystem
	else
		Make/FREE/N=0/T listWithDuplicates
	endif

	WAVE/T listOfXOPs = GetUniqueEntries(listWithDuplicates)

	STRUCT CHI_InstallationState state
	CHI_InitInstallationState(state)

	info      = IgorInfo(0)
	igorBuild = GetIgorProBuildVersion()

	if(!isEmpty(igorBuild))
		igorBuild = ", " + igorBuild
	endif

	archBits = GetArchitectureBits()

	printf "Checking system properties:\r"
	printf "Igor %dbit: %s%s\r", archBits, StringByKey("IGORVERS", info), igorBuild
	printf "%s\r", StringByKey("OS", IgorInfo(3))
	if(IsWindows10Or11() && archBits == 64)
		aslrEnabled = GetASLREnabledState()
		printf "ASLR: %s (%s)\r", ToTrueFalse(aslrEnabled), SelectString(aslrEnabled, "Nice!", "Very Bad")
		if(aslrEnabled != 0)
			state.numErrors += 1
		endif
	else
		printf "ASLR: (not relevant)\r"
	endif

	printf "\rChecking known defines:\r"

	state.numTries += 1

	printf "DEBUGGING_ENABLED: "
#ifdef DEBUGGING_ENABLED
	printf "Yes\r"
#else
	printf "No\r"
#endif // DEBUGGING_ENABLED

	printf "EVIL_KITTEN_EATING_MODE: "
#ifdef EVIL_KITTEN_EATING_MODE
	state.numErrors += 1
	printf "Yes (Very Bad)\r"
#else
	printf "No\r"
#endif // EVIL_KITTEN_EATING_MODE

	printf "BACKGROUND_TASK_DEBUGGING: "
#ifdef BACKGROUND_TASK_DEBUGGING
	printf "Yes\r"
#else
	printf "No\r"
#endif // BACKGROUND_TASK_DEBUGGING

	printf "THREADING_DISABLED: "
#ifdef THREADING_DISABLED
	state.numErrors += 1
	printf "Yes (Very Bad)\r"
#else
	printf "No\r"
#endif // THREADING_DISABLED

	printf "\rInstallation Configuration:\r"
	installedWithHW = CHI_IsMIESInstalledWithHardware()
	printf "  Installation with hardware: %s\r", ToTrueFalse(installedWithHW)
	printf "  Installated for all users: %s\r", ToTrueFalse(CHI_IsMIESInstalledForAllUsers())

	printf "\rChecking base installation:\r"

	SVAR miesVersion = $GetMiesVersion()
	state.numTries += 1

	if(!cmpstr(miesVersion, UNKNOWN_MIES_VERSION))
		printf "Mies version info: Invalid (Very Bad)\r"
		state.numErrors += 1
	else
		printf "Mies version info: Valid \"%s...\" (Nice!)\r", StringFromList(0, miesVersion, "\r")
	endif

#ifdef WINDOWS
	if(installedWithHW)
		CHI_CheckXOP(listOfXOPs, "itcxop2-64.xop", "ITC XOP", state)
		CHI_CheckXOP(listOfXOPs, "AxonTelegraph64.xop", "Axon Telegraph XOP", state)
		CHI_CheckXOP(listOfXOPs, "MultiClamp700xCommander64.xop", "Multi Clamp Commander XOP", state)
	endif
#endif // WINDOWS

	// one operation/function of each non-hardware XOP needs to be called in CheckCompilation_IGNORE()
	CHI_CheckXOP(listOfXOPs, "JSON-64.xop", "JSON XOP", state)
	CHI_CheckXOP(listOfXOPs, "ZeroMQ-64.xop", "ZeroMQ XOP", state, expectedHash = CHI_ZEROMQ_XOP_64_HASH)
	CHI_CheckXOP(listOfXOPs, "TUF-64.xop", "TUF XOP", state)

#ifdef WINDOWS
	CHI_CheckXOP(listOfXOPs, "MiesUtils-64.xop", "MiesUtils XOP", state)
	CHI_CheckXOP(listOfXOPs, "mies-nwb2-compound-XOP-64.xop", "NWBv2 compound XOP", state)
#endif // WINDOWS

	CHI_CheckJSONXOPVersion(state)
#ifdef WINDOWS
	if(installedWithHW)
		CHI_CheckITCXOPVersion(state)
	endif
#endif // WINDOWS
	CHI_CheckTUFXOPVersion(state)

	printf "Results: %d checks, %d number of errors\r", state.numTries, state.numErrors

#ifdef WINDOWS
	STRUCT CHI_InstallationState stateExtended
	CHI_InitInstallationState(stateExtended)
	printf "\rChecking extended installation:\r"

	if(installedWithHW)
		CHI_CheckXOP(listOfXOPs, "NIDAQmx64.xop", "NI-DAQ MX XOP", stateExtended, expectedHash = CHI_NIDAQ_XOP_64_HASH)
	endif

	printf "Results: %d checks, %d number of errors\r", stateExtended.numTries, stateExtended.numErrors
#endif // WINDOWS
	ControlWindowToFront()

	return state.numErrors
End
