#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_UTILS_JSON
#endif

/// @file MIES_Utilities_JSON.ipf
/// @brief utility functions for json

/// @brief Helper function for UploadCrashDumps
///
/// Fill `payload` array with content from files
Function AddPayloadEntriesFromFiles(variable jsonID, WAVE/T paths, [variable isBinary])
	string data, fName, filepath, jsonpath
	variable numEntries, i, offset

	numEntries = DimSize(paths, ROWS)
	Make/FREE/N=(numEntries)/T values, keys

	for(i = 0; i < numEntries; i += 1)
		[data, fName] = LoadTextFile(paths[i])
		values[i] = data

		keys[i] = GetFile(paths[i])
	endfor

	AddPayloadEntries(jsonID, keys, values, isBinary = isBinary)
End

/// @brief Helper function for UploadCrashDumps
///
/// Fill `payload` array
Function AddPayloadEntries(variable jsonID, WAVE/T keys, WAVE/T values, [variable isBinary])
	string jsonpath
	variable numEntries, i, offset

	numEntries = DimSize(keys, ROWS)
	ASSERT(numEntries == DimSize(values, ROWS), "Mismatched dimensions")

	if(ParamIsDefault(isBinary))
		isBinary = 0
	else
		isBinary = !!isBinary
	endif

	if(!JSON_Exists(jsonID, "/payload"))
		JSON_AddTreeArray(jsonID, "/payload")
	endif

	if(!numEntries)
		return NaN
	endif

	offset = JSON_GetArraySize(jsonID, "/payload")
	JSON_AddObjects(jsonID, "/payload", objCount = numEntries)

	for(i = 0; i < numEntries; i += 1)
		jsonpath = "/payload/" + num2str(offset + i) + "/"

		JSON_AddString(jsonID, jsonpath + "name", keys[i])

		if(isBinary)
			JSON_AddString(jsonID, jsonpath + "encoding", "base64")
			JSON_AddString(jsonID, jsonpath + "contents", Base64Encode(values[i]))
		else
			JSON_AddString(jsonID, jsonpath + "contents", values[i])
		endif
	endfor
End
