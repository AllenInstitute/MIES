#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_CHI
#endif

/// @file MIES_CheckInstallation.ipf
///
/// @brief __CHI__ Routines for checking the health of the
///        MIES installation

static StrConstant CHI_NIDAQ_XOP_64_HASH = "92427feeec9d330d410452b15ff1b6da90fe8e2dd0b8362cd711358c8726706a"
static StrConstant CHI_NIDAQ_XOP_HASH    = "ed7f5bc51553608bcf7850b06d472dc739952a32939c1b196b80d131a87f2527"
static StrConstant CHI_JSON_XOP_VERSION  = "version-817-g0ceb12c"
static StrConstant CHI_TUF_XOP_VERSION   = "version-163-g686effb"
static StrConstant CHI_ITC_XOP_VERSION   = "latest-170-g1dfb5c5"

/// @brief Collection of counters used for installation checking
static Structure CHI_InstallationState
	variable numErrors
	variable numTries
EndStructure

static Function CHI_InitInstallationState(state)
	STRUCT CHI_InstallationState &state

	state.numErrors = 0
	state.numTries  = 0
End

static Function CHI_CheckJSONXOPVersion(state)
	STRUCT CHI_InstallationState &state

	variable id
	string info, version

	info = JSON_Version()
	id = JSON_Parse(info)
	version = JSON_GetString(id, "/XOP/version", ignoreErr = 1)

	CHI_OutputVersionCheckResult(state, "JSON", CHI_JSON_XOP_VERSION, version)
End

static Function CHI_CheckTUFXOPVersion(state)
	STRUCT CHI_InstallationState &state

	variable id
	string version

	TUFXOP_Version
	id = JSON_Parse(S_value)
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

static Function CHI_CheckITCXOPVersion(state)
	STRUCT CHI_InstallationState &state

	string version

	WAVE/T/Z versionInfo = HW_ITC_GetVersionInfo(flags = HARDWARE_PREVENT_ERROR_MESSAGE)

	if(!WaveExists(versionInfo) || FindDimLabel(versionInfo, ROWS, "XOP") < 0)
		version = "error querying version"
	else
		version = RemovePrefix(versionInfo[%XOP][%Description], start = "ITCXOP2: ")
	endif

	CHI_OutputVersionCheckResult(state, "ITC2", CHI_ITC_XOP_VERSION, version)
End

/// @brief Search list for matches of item and print the results
static Function CHI_CheckXOP(list, item, name, state, [expectedHash])
	string &list, item, name
	STRUCT CHI_InstallationState &state
	string expectedHash

	variable numMatches, i, hashMatches
	string matches, fileVersion, filepath, existingHash, hashMsg

	matches    = ListMatch(list, "*" + item, "|")
	numMatches = ItemsInList(matches, "|")

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
			filepath = StringFromList(0, matches, "|")
			fileVersion = GetFileVersion(filepath)
			if(ParamIsDefault(expectedHash))
				printf "%s: Found version %s (Nice!)\r", name, fileVersion
			else
				existingHash = CalcHashForFile(filepath)
				hashMatches = !cmpstr(existingHash, expectedHash)
				hashMsg = SelectString(hashMatches, "not ok (" + expectedHash + " vs " + existingHash + ")", "ok")
				printf "%s: Found version %s and hash is %s (%s)\r", name, fileVersion, hashMsg, SelectString(hashMatches, "Very Bad", "Nice!")
				state.numErrors += !hashMatches
			endif
			break
		default:
			printf "%s: Found multiple versions in \"%s\" (Might create problems)\r", name, matches
			printf "%s: Duplicates are:\r", name
			for(i = 0; i < numMatches; i += 1)
				filepath = StringFromList(i, matches, "|")
				fileVersion = GetFileVersion(filepath)
				if(ParamIsDefault(expectedHash))
					printf "%s: Found version %s\r", name, fileVersion
				else
					existingHash = CalcHashForFile(filepath)
					hashMatches = !cmpstr(existingHash, expectedHash)
					hashMsg = SelectString(hashMatches, "not ok (" + expectedHash + " vs " + existingHash + ")", "ok")
					printf "%s: Found version %s and hash is %s\r", name, fileVersion, hashMsg
					state.numErrors += !hashMatches
				endif
			endfor
			state.numErrors += 1
			break
	endswitch
End

/// @brief Check the installation and print the results to the history
///
/// Currently checks that all expected/optional XOPs are installed.
///
/// @return number of errors
Function CHI_CheckInstallation()

	string symbPath, allFiles, path, extName, info, igorBuild
	string allFilesSystem, allFilesUser, listOfXOPs
	variable aslrEnabled, archBits

	symbPath = GetUniqueSymbolicPath()
	extName  = GetIgorExtensionFolderName()

	path = SpecialDirPath("Igor Pro User Files", 0, 0, 0) + extName
	NewPath/Q/O $symbPath, path
	allFilesUser = GetAllFilesRecursivelyFromPath(symbPath)

	path = SpecialDirPath("Igor Application", 0, 0, 0) + extName
	NewPath/Q/O $symbPath, path
	allFilesSystem = GetAllFilesRecursivelyFromPath(symbPath)

	KillPath $symbPath

	listOfXOPs = ListMatch(allFilesUser + "|" + allFilesSystem, "*.xop", "|")
	WAVE/T list = ListToTextWave(listOfXOPs, "|")
	WAVE/T listNoDups = GetUniqueEntries(list)
	listOfXOPs = TextWaveToList(listNoDups, "|")

	STRUCT CHI_InstallationState state
	CHI_InitInstallationState(state)

	info = IgorInfo(0)
	igorBuild = StringByKey("BUILD", info)

	if(!isEmpty(igorBuild))
		igorBuild = ", " + igorBuild
	endif

	archBits = GetArchitectureBits()

	printf "Checking system properties:\r"
	printf "Igor %dbit: %s%s\r", archBits, StringByKey("IGORVERS", info), igorBuild
	printf "Windows 10: %s\r", ToTrueFalse(IsWindows10())
	if(IsWindows10() && archBits == 64)
		aslrEnabled = GetASLREnabledState()
		printf "ASLR: %s (%s)\r" ToTrueFalse(aslrEnabled), SelectString(aslrEnabled, "Nice!", "Very Bad")
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
#endif

	printf "EVIL_KITTEN_EATING_MODE: "
#ifdef EVIL_KITTEN_EATING_MODE
	state.numErrors += 1
	printf "Yes (Very Bad)\r"
#else
	printf "No\r"
#endif

	printf "BACKGROUND_TASK_DEBUGGING: "
#ifdef BACKGROUND_TASK_DEBUGGING
	printf "Yes\r"
#else
	printf "No\r"
#endif

	printf "THREADING_DISABLED: "
#ifdef THREADING_DISABLED
	state.numErrors += 1
	printf "Yes (Very Bad)\r"
#else
	printf "No\r"
#endif

	printf "\rChecking base installation:\r"

	SVAR miesVersion = $GetMiesVersion()
	state.numTries += 1

	if(!cmpstr(miesVersion, UNKNOWN_MIES_VERSION))
		printf "Mies version info: Invalid (Very Bad)\r"
		state.numErrors += 1
	else
		printf "Mies version info: Valid \"%s...\" (Nice!)\r", StringFromList(0, miesVersion, "\r")
	endif

	CHI_CheckXOP(listOfXOPs, "itcxop2-64.xop", "ITC XOP", state)
	CHI_CheckXOP(listOfXOPs, "JSON-64.xop", "JSON XOP", state)
	CHI_CheckXOP(listOfXOPs, "VDT2-64.xop", "VDT2 XOP", state)
	CHI_CheckXOP(listOfXOPs, "AxonTelegraph64.xop", "Axon Telegraph XOP", state)
	CHI_CheckXOP(listOfXOPs, "MultiClamp700xCommander64.xop", "Multi Clamp Commander XOP", state)
	CHI_CheckXOP(listOfXOPs, "ZeroMQ-64.xop", "ZeroMQ XOP", state)
	CHI_CheckXOP(listOfXOPs, "TUF-64.xop", "TUF XOP", state)

	CHI_CheckJSONXOPVersion(state)
	CHI_CheckITCXOPVersion(state)
	CHI_CheckTUFXOPVersion(state)

	printf "Results: %d checks, %d number of errors\r", state.numTries, state.numErrors

	STRUCT CHI_InstallationState stateExtended
	CHI_InitInstallationState(stateExtended)
	printf "\rChecking extended installation:\r"

	CHI_CheckXOP(listOfXOPs, "NIDAQmx64.xop", "NI-DAQ MX XOP", stateExtended, expectedHash = CHI_NIDAQ_XOP_64_HASH)

	printf "Results: %d checks, %d number of errors\r", stateExtended.numTries, stateExtended.numErrors
	ControlWindowToFront()

	return state.numErrors
End
