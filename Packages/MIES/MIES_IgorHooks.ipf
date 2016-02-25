#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_IgorHooks.ipf
/// @brief __IH__ Various hooks which influence the behaviour at certain global events

/// @brief Remove all strings/variables/waves which should not
/// survive experiment reload/quit/saving
///
/// Mainly useful for temporaries which you want to recreate on initialization
static Function IH_KillTemporaries()

	string trashFolders, path, allFolders
	variable numFolders, i

	DFREF dfr = GetMiesPath()

	KillStrings/Z dfr:version
	KillVariables/Z dfr:skip_free_memory_warning

	// try to delete all trash folders
	allFolders = StringByKey("FOLDERS", DataFolderDir(1, dfr))
	trashFolders = ListMatch(allFolders, TRASH_FOLDER_PREFIX + "*", ",")

	numFolders = ItemsInList(trashFolders, ",")
	for(i = 0; i < numFolders; i += 1)
		path = GetDataFolder(1, dfr) + StringFromList(i, trashFolders, ",")
		KillDataFolder/Z $path
	endfor

	RemoveEmptyDataFolder(dfr)
	IH_KillStimSets()
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

/// @brief Use the same pixel <-> point conversion rules as in Igor Pro 6
static Function IH_SetPanelResolutionAsInIP6()

/// @todo remove PanelResolution hack once we can discontinue Igor Pro 6 support
#if (IgorVersion() >= 7.0)
	if(QuerySetIgorOption("PanelResolution") != 72)
		Execute/P/Q "SetIgorOption PanelResolution=72"
		Execute/P/Q/Z "COMPILEPROCEDURES "
	endif
#endif

End

static Function BeforeExperimentSaveHook(rN, fileName, path, type, creator, kind)
	Variable rN, kind
	String fileName, path, type, creator

	IH_SerAllCommentNBsWrapper()
	IH_KillTemporaries()
End

static Function IgorBeforeQuitHook(unsavedExp, unsavedNotebooks, unsavedProcedures)
	variable unsavedExp, unsavedNotebooks, unsavedProcedures

	IH_UnlockAllDevicesWrapper()
	IH_KillTemporaries()

	// save the experiment silently if it was saved before
	if(unsavedExp == 0)
		SaveExperiment
	endif

	return 0
End

static Function IgorBeforeNewHook(igorApplicationNameStr)
	string igorApplicationNameStr

	IH_UnlockAllDevicesWrapper()
	IH_KillTemporaries()
	IH_SetPanelResolutionAsInIP6()

	return 0
End

static Function AfterCompiledHook()

	IH_SetPanelResolutionAsInIP6()

	return 0
End
