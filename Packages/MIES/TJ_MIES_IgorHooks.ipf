#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file TJ_MIES_IgorHooks.ipf
/// @brief Various hooks which influence the behaviour at certain global events

/// @brief Remove all strings/variables/waves which should not
/// survive experiment reload/quit/saving
///
/// Mainly useful for temporaries which you want to recreate on initialization
static Function KillTemporaries()

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
End

Function IH_UnlockAllDevicesProto()

End

/// @brief Calls `DAP_UnlockAllDevices` if the function can be found,
/// otherwise calls `IH_UnlockAllDevicesProto` which does nothing.
static Function UnlockAllDevicesWrapper()

	FUNCREF IH_UnlockAllDevicesProto f = $"DAP_UnlockAllDevices"
	f()
End

static Function BeforeExperimentSaveHook(rN, fileName, path, type, creator, kind)
	Variable rN, kind
	String fileName, path, type, creator

	KillTemporaries()
End

static Function IgorBeforeQuitHook(igorApplicationNameStr)
	string igorApplicationNameStr

	UnlockAllDevicesWrapper()
	KillTemporaries()
	return 0
End

static Function IgorBeforeNewHook(igorApplicationNameStr)
	string igorApplicationNameStr

	UnlockAllDevicesWrapper()
	KillTemporaries()
	return 0
End
