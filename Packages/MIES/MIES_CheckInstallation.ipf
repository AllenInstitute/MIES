#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_CheckInstallation.ipf
///
/// @brief __CHI__ Routines for checking the health of the
///        MIES installation

/// @brief Collection of counters used for installation checking
static Structure CHI_InstallationState
	variable numErrors, numWarnings
	variable numTries
EndStructure

static Function CHI_InitInstallationState(state)
	STRUCT CHI_InstallationState &state

	state.numErrors   = 0
	state.numTries    = 0
	state.numWarnings = 0
End

/// @brief Calculate a cryptographic hash for the file contents of path
///
/// @param path absolute path to a file
/// @param method [optional, defaults to SHA-2 with 256 bytes]
/// 			  Type of cryptographic hash function
Function/S CalcHashForFile(path, [method])
	string path
	variable method

	variable refNum
	string contents = ""

	if(ParamIsDefault(method))
		method = 1
	endif

	GetFileFolderInfo/Q path
	ASSERT(V_IsFile, "Expected a file")

	Open/R refNum as path

	contents = PadString(contents, V_logEOF, 0)

	FBinRead refNum, contents
	Close refNum

	return Hash(contents, method)
End

/// @brief Check if the file paths referenced in `list` are pointing
///        to identical files
Function CheckIfPathsRefIdenticalFiles(list)
	string list

	variable i, numEntries
	string path, refHash, newHash

	if(ItemsInList(list, "|") <= 1)
		return 1
	endif

	numEntries = ItemsInList(list, "|")
	for(i = 0; i < numEntries; i += 1)
		path = StringFromList(i, list, "|")

		if(i == 0)
			refHash = CalcHashForFile(path)
			continue
		endif

		newHash = CalcHashForFile(path)

		if(cmpstr(newHash, refHash))
			return 0
		endif
	endfor

	return 1
End

/// @brief Return the file version
static Function/S CHI_GetFileVersion(path)
	string path

	GetFileFolderInfo/Q path
	ASSERT(V_IsFile, "Expected a file")

	return S_FileVersion
End

/// @brief Search list for matches of item and print the results
static Function CHI_CheckXOP(list, item, name, state)
	string &list, item, name
	STRUCT CHI_InstallationState &state

	variable numMatches, i
	string matches

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
			printf "%s: Found version %s (Nice!)\r", name, CHI_GetFileVersion(StringFromList(0, matches, "|"))
			break
		default:
			printf "%s: Found multiple versions (Might create problems)\r", name
			printf "%s: Duplicates are:\r", name
			for(i = 0; i < numMatches; i += 1)
				printf "%s: Found version %s\r", name, CHI_GetFileVersion(StringFromList(i, matches, "|"))
			endfor
			state.numWarnings += 1
			break
	endswitch
End

/// @brief Check the installation and print the results to the history
///
/// Currently checks that all expected/optional XOPs are installed.
Function CHI_CheckInstallation()

	string symbPath, allFiles, path, extName, info, igorBuild
	string allFilesSystem, allFilesUser, listOfXOPs

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
	listOfXOPs = TextWaveToList(RemoveDuplicates(ListToTextWave(listOfXOPs, "|")), "|")

	STRUCT CHI_InstallationState state

	info = IgorInfo(0)
	igorBuild = StringByKey("BUILD", info)

	if(!isEmpty(igorBuild))
		igorBuild = ", " + igorBuild
	endif

	printf "Igor %dbit: %s%s\r", GetArchitectureBits(), StringByKey("IGORVERS", info), igorBuild

	CHI_InitInstallationState(state)
	printf "\rChecking base installation:\r"

#if defined(IGOR64)
	CHI_CheckXOP(listOfXOPs, "itcxop2-64.xop", "ITC XOP", state)
	CHI_CheckXOP(listOfXOPs, "VDT2-64.xop", "VDT2 XOP", state)
	CHI_CheckXOP(listOfXOPs, "HDF5-64.xop", "HDF5 XOP", state)
	CHI_CheckXOP(listOfXOPs, "AxonTelegraph64.xop", "Axon Telegraph XOP", state)
	CHI_CheckXOP(listOfXOPs, "MultiClamp700xCommander64.xop", "Multi Clamp Commander XOP", state)
#else
	CHI_CheckXOP(listOfXOPs, "ITC_X86_V31.xop", "ITC XOP", state)
	CHI_CheckXOP(listOfXOPs, "VDT2.xop", "VDT2 XOP", state)
	CHI_CheckXOP(listOfXOPs, "HDF5.xop", "HDF5 XOP", state)
	CHI_CheckXOP(listOfXOPs, "AxonTelegraph.xop", "Axon Telegraph XOP", state)
	CHI_CheckXOP(listOfXOPs, "MultiClamp700xCommander.xop", "Multi Clamp Commander XOP", state)
#endif

	printf "Results: %d checks, %d number of errors, %d number of warnings\r", state.numTries, state.numErrors, state.numWarnings

	CHI_InitInstallationState(state)
	printf "\rChecking extended installation:\r"

#if defined(IGOR64)
	CHI_CheckXOP(listOfXOPs, "tango_binding-64.xop", "Tango XOP", state)
#else
	CHI_CheckXOP(listOfXOPs, "tango_binding.xop", "Tango XOP", state)
#endif

	printf "Results: %d checks, %d number of errors, %d number of warnings\r", state.numTries, state.numErrors, state.numWarnings
End
