#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file TJ_MIES_IgorHooks.ipf
/// @brief Various hooks which influence the behaviour at certain global events

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

/// @brief Delete all stim sets to save memory
Function IH_KillStimSets()

	string list

	DFREF dfr = GetWBSvdStimSetDAPath()
	list = GetListOfWaves(dfr, ".*DA.*", fullPath=1)
	CallFunctionForEachListItem(KillOrMoveToTrash, list)

	DFREF dfr = GetWBSvdStimSetTTLPath()
	list = GetListOfWaves(dfr, ".*TTL.*", fullPath=1)
	CallFunctionForEachListItem(KillOrMoveToTrash, list)
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

	IH_SerAllCommentNBsWrapper()
	IH_KillTemporaries()
End

static Function IgorBeforeQuitHook(igorApplicationNameStr)
	string igorApplicationNameStr

	IH_UnlockAllDevicesWrapper()
	IH_KillTemporaries()
	return 0
End

static Function IgorBeforeNewHook(igorApplicationNameStr)
	string igorApplicationNameStr

	IH_UnlockAllDevicesWrapper()
	IH_KillTemporaries()
	return 0
End
