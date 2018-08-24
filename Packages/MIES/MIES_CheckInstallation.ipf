#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_CHI
#endif

/// @file MIES_CheckInstallation.ipf
///
/// @brief __CHI__ Routines for checking the health of the
///        MIES installation

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
			state.numErrors += 1
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
	listOfXOPs = TextWaveToList(DeleteDuplicates(ListToTextWave(listOfXOPs, "|")), "|")

	STRUCT CHI_InstallationState state

	info = IgorInfo(0)
	igorBuild = StringByKey("BUILD", info)

	if(!isEmpty(igorBuild))
		igorBuild = ", " + igorBuild
	endif

	printf "Igor %dbit: %s%s\r", GetArchitectureBits(), StringByKey("IGORVERS", info), igorBuild

	CHI_InitInstallationState(state)
	printf "\rChecking base installation:\r"

	SVAR miesVersion = $GetMiesVersion()
	state.numTries += 1

	if(!cmpstr(miesVersion, UNKNOWN_MIES_VERSION))
		printf "Mies version info: Invalid (Very Bad)\r"
		state.numErrors += 1
	else
		printf "Mies version info: Valid \"%s\" (Nice!)\r", miesVersion
	endif

#if defined(IGOR64)
	CHI_CheckXOP(listOfXOPs, "itcxop2-64.xop", "ITC XOP", state)
	CHI_CheckXOP(listOfXOPs, "VDT2-64.xop", "VDT2 XOP", state)
	CHI_CheckXOP(listOfXOPs, "HDF5-64.xop", "HDF5 XOP", state)
	CHI_CheckXOP(listOfXOPs, "AxonTelegraph64.xop", "Axon Telegraph XOP", state)
	CHI_CheckXOP(listOfXOPs, "MultiClamp700xCommander64.xop", "Multi Clamp Commander XOP", state)
	CHI_CheckXOP(listOfXOPs, "ZeroMQ-64.xop", "ZeroMQ XOP", state)
#else
	CHI_CheckXOP(listOfXOPs, "itcxop2.xop", "ITC XOP", state)
	CHI_CheckXOP(listOfXOPs, "VDT2.xop", "VDT2 XOP", state)
	CHI_CheckXOP(listOfXOPs, "HDF5.xop", "HDF5 XOP", state)
	CHI_CheckXOP(listOfXOPs, "AxonTelegraph.xop", "Axon Telegraph XOP", state)
	CHI_CheckXOP(listOfXOPs, "MultiClamp700xCommander.xop", "Multi Clamp Commander XOP", state)
	CHI_CheckXOP(listOfXOPs, "ZeroMQ.xop", "ZeroMQ XOP", state)
#endif

	printf "Results: %d checks, %d number of errors\r", state.numTries, state.numErrors

	CHI_InitInstallationState(state)
	printf "\rChecking extended installation:\r"

#if defined(IGOR64)
	CHI_CheckXOP(listOfXOPs, "tango_binding-64.xop", "Tango XOP", state)
	CHI_CheckXOP(listOfXOPs, "NIDAQmx64.xop", "NI-DAQ MX XOP", state)
#else
	CHI_CheckXOP(listOfXOPs, "tango_binding.xop", "Tango XOP", state)
	CHI_CheckXOP(listOfXOPs, "NIDAQmx.xop", "NI-DAQ MX XOP", state)
#endif

	printf "Results: %d checks, %d number of errors\r", state.numTries, state.numErrors
	ControlWindowToFront()
End
