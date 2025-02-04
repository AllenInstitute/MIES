#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_UTILS_DATAFOLDER
#endif // AUTOMATED_TESTING

/// @file MIES_Utilities_DataFolder.ipf
/// @brief utility functions for datafolder handling

/// @brief Alternative implementation for WaveList/VariableList/etc. which honours a dfref and thus
/// does not require SetDataFolder calls.
///
/// @param dfr                                  datafolder reference to search for the objects
/// @param matchExpr                            expression matching the objects, either a regular (exprType == MATCH_REGEXP)
///                                             or wildcard (exprType == MATCH_WILDCARD) expression
/// @param typeFlag [optional, default: COUNTOBJECTS_WAVES] One of @ref TypeFlags
/// @param fullPath [optional, default: false]  should only the object name or the absolute path of the object be returned
/// @param recursive [optional, default: false] descent into all subfolders recursively
/// @param exprType [optional, defaults: MATCH_REGEXP] convention used for matchExpr, one of @ref MatchExpressions
///
/// @returns list of object names matching matchExpr
threadsafe Function/S GetListOfObjects(DFREF dfr, string matchExpr, [variable typeFlag, variable fullPath, variable recursive, variable exprType])

	variable i, numFolders
	string name, folders, basePath, subList, freeDFName
	string list = ""

	ASSERT_TS(DataFolderExistsDFR(dfr), "Non-existing datafolder")
	ASSERT_TS(!isEmpty(matchExpr), "matchExpr is empty or null")

	if(ParamIsDefault(fullPath))
		fullPath = 0
	else
		fullPath = !!fullPath
	endif

	if(ParamIsDefault(recursive))
		recursive = 0
	else
		recursive = !!recursive
	endif

	if(ParamIsDefault(typeFlag))
		typeFlag = COUNTOBJECTS_WAVES
	endif

	if(ParamIsDefault(exprType))
		exprType = MATCH_REGEXP
	else
		ASSERT_TS(exprType == MATCH_REGEXP || exprType == MATCH_WILDCARD, "Invalid exprType")
	endif

	list = ListMatchesExpr(GetAllObjects(dfr, typeFlag), matchExpr, exprType)

	if(fullPath)
		basePath = GetDataFolder(1, dfr)
		if(IsFreeDataFolder(dfr))
			freeDFName = StringFromList(0, basePath, ":") + ":"
			basePath   = ReplaceString(freeDFName, basePath, "", 0, 1)
		endif
		list = AddPrefixToEachListItem(basePath, list)
	endif

	if(recursive)
		folders    = GetAllObjects(dfr, COUNTOBJECTS_DATAFOLDER)
		numFolders = ItemsInList(folders)
		for(i = 0; i < numFolders; i += 1)
			DFREF subFolder = dfr:$StringFromList(i, folders)
			subList = GetListOfObjects(subFolder, matchExpr, typeFlag = typeFlag, fullPath = fullPath, recursive = recursive, exprType = exprType)
			if(!IsEmpty(subList))
				list = AddListItem(RemoveEnding(subList, ";"), list)
			endif
		endfor
	endif

	return list
End

/// @brief Return a list of all objects of the given type from dfr
threadsafe static Function/S GetAllObjects(DFREF dfr, variable typeFlag)

	string list

	switch(typeFlag)
		case COUNTOBJECTS_WAVES:
			list = WaveList("*", ";", "", dfr)
			break
		case COUNTOBJECTS_VAR:
			list = VariableList("*", ";", 4, dfr) + VariableList("*", ";", 5, dfr)
			break
		case COUNTOBJECTS_STR:
			list = StringList("*", ";", dfr)
			break
		case COUNTOBJECTS_DATAFOLDER:
			list = DataFolderList("*", ";", dfr)
			break
		default:
			ASSERT_TS(0, "Invalid type flag")
	endswitch

	return list
End

/// @brief Checks if the datafolder referenced by dfr exists.
///
/// @param[in] dfr data folder to test
/// @returns one if dfr is valid and references an existing or free datafolder, zero otherwise
/// UTF_NOINSTRUMENTATION
threadsafe Function DataFolderExistsDFR(DFREF dfr)

	return DataFolderRefStatus(dfr) != 0
End

/// @brief Check if the passed datafolder reference is a global/permanent datafolder
///
/// UTF_NOINSTRUMENTATION
threadsafe Function IsGlobalDataFolder(DFREF dfr)

	return (DataFolderRefStatus(dfr) & (DFREF_VALID | DFREF_FREE)) == DFREF_VALID
End

/// @brief Returns 1 if dfr is a valid free datafolder, 0 otherwise
///
/// UTF_NOINSTRUMENTATION
threadsafe Function IsFreeDatafolder(DFREF dfr)

	return (DataFolderRefStatus(dfr) & (DFREF_VALID | DFREF_FREE)) == (DFREF_VALID | DFREF_FREE)
End

/// @brief Create a datafolder and all its parents,
///
/// @hidecallgraph
/// @hidecallergraph
///
/// Includes fast handling of the common case that the datafolder exists.
/// @returns reference to the datafolder
/// UTF_NOINSTRUMENTATION
threadsafe Function/DF createDFWithAllParents(string dataFolder)

	variable i, numItems
	string partialPath, component
	DFREF dfr = $dataFolder

	if(DataFolderRefStatus(dfr))
		return dfr
	endif

	partialPath = "root"

	// i=1 because we want to skip root, as this exists always
	numItems = ItemsInList(dataFolder, ":")
	for(i = 1; i < numItems; i += 1)
		component = StringFromList(i, dataFolder, ":")
		ASSERT_TS(IsValidObjectName(component), "dataFolder must follow strict object naming rules.")

		partialPath += ":" + component
		if(!DataFolderExists(partialPath))
			NewDataFolder $partialPath
		endif
	endfor

	return $dataFolder
End

/// @brief Removes the datafolder reference if there are no objects in it anymore
///
/// @param dfr data folder reference to kill
/// @returns 1 in case the folder was removed and 0 in all other cases
Function RemoveEmptyDataFolder(DFREF dfr)

	if(!DataFolderExistsDFR(dfr))
		return 0
	endif

	if(IsDataFolderEmpty(dfr))
		KillDataFolder dfr
		return 1
	endif

	return 0
End

/// @brief Return 1 if the datafolder is empty, zero if not
Function IsDataFolderEmpty(DFREF dfr)

	ASSERT(DataFolderExistsDFR(dfr), "Missing dfr")

	return (CountObjectsDFR(dfr, COUNTOBJECTS_WAVES)        \
	        + CountObjectsDFR(dfr, COUNTOBJECTS_VAR)        \
	        + CountObjectsDFR(dfr, COUNTOBJECTS_STR)        \
	        + CountObjectsDFR(dfr, COUNTOBJECTS_DATAFOLDER) \
	       ) == 0
End

/// @brief Remove all empty datafolders in the passed datafolder reference recursively including sourceDFR
Function RemoveAllEmptyDataFolders(DFREF sourceDFR)

	variable numFolder, i
	string folder

	if(!DataFolderExistsDFR(sourceDFR))
		return NaN
	endif

	numFolder = CountObjectsDFR(sourceDFR, COUNTOBJECTS_DATAFOLDER)

	for(i = numFolder - 1; i >= 0; i -= 1)
		folder = GetDataFolder(1, sourceDFR) + GetIndexedObjNameDFR(sourceDFR, COUNTOBJECTS_DATAFOLDER, i)
		RemoveAllEmptyDataFolders($folder)
	endfor

	RemoveEmptyDataFolder(sourceDFR)
End

/// @brief Returns a reference to a newly created datafolder
///
/// Basically a datafolder aware version of UniqueName for datafolders
///
/// @param dfr 	    datafolder reference where the new datafolder should be created
/// @param baseName first part of the datafolder, might be shortend due to Igor Pro limitations
threadsafe Function/DF UniqueDataFolder(DFREF dfr, string baseName)

	string path

	path = UniqueDataFolderName(dfr, basename)

	NewDataFolder $path
	return $path
End

/// @brief Return an absolute unique data folder name which does not exist in dfr
///
/// @param dfr      datafolder to search
/// @param baseName first part of the datafolder
threadsafe Function/S UniqueDataFolderName(DFREF dfr, string baseName)

	ASSERT_TS(!isEmpty(baseName), "baseName must not be empty")
	ASSERT_TS(DataFolderExistsDFR(dfr), "dfr does not exist")
	ASSERT_TS(!IsFreeDatafolder(dfr), "dfr can not be a free DF")

	return GetDataFolder(1, dfr) + CreateDataObjectName(dfr, basename, 11, 0, 0)
End

/// @brief Rename the given datafolder path to a unique name
///
/// With path `root:a:b:c` and suffix `_old` the datafolder is renamed to `root:a:b:c_old` or if that exists
/// `root:a:b:c_old_1` and so on.
Function RenameDataFolderToUniqueName(string path, string suffix)

	string name, folder

	if(!DataFolderExists(path))
		return NaN
	endif

	DFREF dfr = $path
	name   = GetFile(path)
	folder = UniqueDataFolderName($(path + "::"), name + suffix)
	name   = GetFile(folder)
	RenameDataFolder $path, $name
	ASSERT_TS(!DataFolderExists(path), "Could not move it of the way.")
	ASSERT_TS(DataFolderExists(folder), "Could not create it in the correct place.")
End

/// @brief For DF memory management, increase reference count
///
/// @param dfr data folder reference of the target df
Function RefCounterDFIncrease(DFREF dfr)

	NVAR rc = $GetDFReferenceCount(dfr)
	rc += 1
End

/// @brief For DF memory management, decrease reference count and kill DF if zero is reached
///
/// @param dfr data folder reference of the target df
Function RefCounterDFDecrease(DFREF dfr)

	NVAR rc = $GetDFReferenceCount(dfr)
	rc -= 1

	if(rc == 0)
		KillOrMoveToTrash(dfr = dfr)
	endif
End

/// @brief Clear the given datafolder reference
threadsafe Function DFREFClear(DFREF &dfr)

	DFREF dfr = $""
End
