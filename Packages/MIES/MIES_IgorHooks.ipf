#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_IH
#endif

/// @file MIES_IgorHooks.ipf
/// @brief __IH__ Various hooks which influence the behaviour at certain global events

/// @brief Remove all strings/variables/waves which should not
/// survive experiment reload/quit/saving
///
/// Mainly useful for temporaries which you want to recreate on initialization
static Function IH_KillTemporaries()

	string trashFolders, path, allFolders, list
	variable numFolders, i

	DFREF dfr = GetMiesPath()

	KillStrings/Z dfr:version

	// try to delete all trash folders
	allFolders = StringByKey("FOLDERS", DataFolderDir(1, dfr))
	trashFolders = ListMatch(allFolders, TRASH_FOLDER_PREFIX + "*", ",")

	numFolders = ItemsInList(trashFolders, ",")
	for(i = 0; i < numFolders; i += 1)
		path = GetDataFolder(1, dfr) + StringFromList(i, trashFolders, ",")
		KillDataFolder/Z $path
	endfor

	RemoveEmptyDataFolder(dfr)

	DFREF dfr = GetWaveBuilderDataPath()
	list = GetListOfObjects(dfr, SEGMENTWAVE_SPECTRUM_PREFIX + ".*", fullPath=1)
	CallFunctionForEachListItem(KillOrMoveToTrashPath, list)
End

/// @brief Remove the amplifier connection waves
Function IH_RemoveAmplifierConnWaves()

	KillOrMoveToTrash(wv=GetAmplifierTelegraphServers())
	KillOrMoveToTrash(wv=GetAmplifierMultiClamps())
End

/// @brief Delete all wavebuilder stim sets to save memory
Function IH_KillStimSets()

	string list, path

	ReturnListOfAllStimSets(CHANNEL_TYPE_DAC, "*", WBstimSetList=list)
	path = GetDataFolder(1, GetWBSvdStimSetDAPath())
	list = AddPrefixToEachListItem(path, list)
	CallFunctionForEachListItem(KillOrMoveToTrashPath, list)

	ReturnListOfAllStimSets(CHANNEL_TYPE_TTL, "*", WBstimSetList=list)
	path = GetDataFolder(1, GetWBSvdStimSetTTLPath())
	list = AddPrefixToEachListItem(path, list)
	CallFunctionForEachListItem(KillOrMoveToTrashPath, list)
End

/// @brief Prototype function for #IH_UnlockAllDevicesWrapper
Function IH_UnlockAllDevicesProto()

End

/// @brief Prototype function for #IH_SerAllCommentNBsWrapper
Function IH_SerAllCommentNBsProto()

End

/// @brief Calls `DAP_UnlockAllDevices` if it can be found,
/// otherwise calls `IH_UnlockAllDevicesProto` which does nothing.
static Function IH_UnlockAllDevicesWrapper()

	FUNCREF IH_UnlockAllDevicesProto f = $"DAP_UnlockAllDevices"
	f()
End

/// @brief Calls #DAP_SerializeAllCommentNBs if it can be found,
/// otherwise calls #IH_SerAllCommentNBsProto which does nothing.
static Function IH_SerAllCommentNBsWrapper()

	FUNCREF IH_SerAllCommentNBsProto f = $"DAP_SerializeAllCommentNBs"
	f()
End

static Function BeforeExperimentSaveHook(rN, fileName, path, type, creator, kind)
	Variable rN, kind
	String fileName, path, type, creator

	// don't try cleaning up if the user never used MIES
	if(!DataFolderExists(GetMiesPathAsString()))
		return NaN
	endif

	IH_SerAllCommentNBsWrapper()
	IH_KillTemporaries()
#if !defined(IGOR64)
	IH_KillStimSets()
#endif
	NWB_Flush()
End

/// @brief Cleanup before closing or starting a new experiment
///
/// Takes care of unlocking the hardware, removing any data which is stale on
/// reload anyway (amplifier connection details) and removes temporary waves.
static Function IH_Cleanup()

	variable error, debuggerState

	// don't try cleaning up if the user never used MIES
	if(!DataFolderExists(GetMiesPathAsString()))
		return NaN
	endif

	debuggerState = DisableDebugger()

	try
		IH_UnlockAllDevicesWrapper(); AbortOnRTE
		IH_RemoveAmplifierConnWaves(); AbortOnRTE
		IH_KillTemporaries(); AbortOnRTE
		IH_KillStimSets(); AbortOnRTE
		CA_FlushCache(); AbortOnRTE
	catch
		error = GetRTError(1)
		DEBUGPRINT("Caught runtime error or assertion")
	endtry

	ResetDebuggerState(debuggerState)
End

static Function IgorBeforeQuitHook(unsavedExp, unsavedNotebooks, unsavedProcedures)
	variable unsavedExp, unsavedNotebooks, unsavedProcedures

	IH_Cleanup()

	// save the experiment silently if it was saved before
	if(unsavedExp == 0 && cmpstr(UNTITLED_EXPERIMENT, GetExperimentName()))
		SaveExperiment
	endif

	return 0
End

static Function IgorBeforeNewHook(igorApplicationNameStr)
	string igorApplicationNameStr

	IH_Cleanup()
	StartZeroMQMessageHandler()

	return 0
End

static Function IgorStartOrNewHook(igorApplicationNameStr)
	string igorApplicationNameStr

	StartZeroMQMessageHandler()

	return 0
End
