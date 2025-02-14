#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_MIESUTILS_DATAMANAGEMENT
#endif // AUTOMATED_TESTING

/// @file MIES_MiesUtilities_DataManagement.ipf
/// @brief This file holds MIES utility functions for data handling.

/// @brief Convenience wrapper for KillOrMoveToTrashPath()
threadsafe Function KillOrMoveToTrash([WAVE/Z wv, DFREF dfr])

	if(!ParamIsDefault(wv) && WaveExists(wv))
		if(IsFreeWave(wv))
			KillWaves wv
		else
			KillOrMoveToTrashPath(GetWavesDataFolder(wv, 2))
		endif
	endif

	if(!ParamIsDefault(dfr) && DataFolderExistsDFR(dfr))
		if(IsGlobalDataFolder(dfr))
			KillOrMoveToTrashPath(GetDataFolder(1, dfr))
		else
			KillDataFolder dfr
		endif
	endif
End

/// @brief Delete a datafolder or wave. If this is not possible, because Igor
/// has locked the file, the wave or datafolder is moved into a trash folder
/// named `root:mies:trash_$digit`.
///
/// The trash folders will be removed, if possible, from KillTemporaries().
///
/// @param path absolute path to a datafolder or wave
threadsafe Function KillOrMoveToTrashPath(string path)

	string dest

	if(DataFolderExists(path))
		KillDataFolder/Z $path

		if(!V_flag)
			return NaN
		endif

		MoveToTrash(dfr = $path)
	elseif(WaveExists($path))
		KillWaves/Z $path

		WAVE/Z wv = $path
		if(!WaveExists(wv))
			return NaN
		endif

		MoveToTrash(wv = wv)
	else
		DEBUGPRINT_TS("Ignoring the datafolder/wave as it does not exist", str = path)
	endif
End

threadsafe Function MoveToTrash([WAVE/Z wv, DFREF dfr])

	string   dest
	variable err

	if(!ParamIsDefault(wv) && WaveExists(wv))
		DFREF tmpDFR = GetUniqueTempPath()
		MoveWave wv, tmpDFR
		err = GetRTError(0)
		if(err)
			BUG_TS("RTError at MoveWave: " + GetWavesDataFolder(wv, 2) + " " + GetRTErrMessage())
		endif
	endif

	if(!ParamIsDefault(dfr) && DataFolderExistsDFR(dfr))
		DFREF tmpDFR = GetUniqueTempPath()
		dest = RemoveEnding(GetDataFolder(1, tmpDFR), ":")
		MoveDataFolder/Z dfr, $dest
		if(V_flag)
			BUG_TS("Could not move DF to trash: " + GetDataFolder(1, dfr) + " to " + dest)
		endif
	endif
End

threadsafe Function KillTrashFolders()

	string dfPath

	DFREF  dfr          = GetMiesPath()
	WAVE/T trashFolders = ListToTextWave(GetListOfObjects(dfr, TRASH_FOLDER_PREFIX + ".*", typeFlag = COUNTOBJECTS_DATAFOLDER, fullPath = 1), ";")

	for(dfPath : trashFolders)
		KillDataFolder/Z $dfPath
	endfor
End
