#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DANDI
#endif

static Function/S DND_GetDestinationIgorPath()

	string path = "tmpPath"
	NewPath/C/O/Q $path, SpecialDirPath("Temporary", 0, 0, 1) + "DandisetDownloads"

	return path
End

static Function/S DND_ChooseAsset(WAVE/T props)
	variable idx, ret

	WAVE data = GetDandiDialogWave(props)
	Duplicate/FREE data, mock

	// select the first asset when mocking
	mock[]  = 0
	mock[0] = 1

	ret = ID_AskUserForSettings(ID_POPUPMENU_SETTINGS, "Stimulus set to load", data, mock)

	if(ret)
		return ""
	endif

	idx = GetRowIndex(data, val = 1)
	ASSERT(IsFinite(idx), "Invalid index")

	return props[idx][%asset_id]
End

/// @brief Download the given asset from the set
///
/// The asset hash is checked before returning.
///
/// @return absolute path to the downloaded asset
static Function/S DND_FetchAsset(variable setNumber, string assetID, string assetPath)
	string url, refHash, downloadUrl, path, name, assetFilePath, data, fname
	variable jsonID

	sprintf url, "https://api.dandiarchive.org/api/dandisets/%06d/versions/draft/assets/%s", setNumber, assetID
	UrlRequest/Z url=url
	ASSERT(!V_flag, "Could fetch asset properties")

	jsonID = JSON_Parse(S_serverResponse)

	refHash = JSON_GetString(jsonID, "/digest/dandi:sha2-256")
	downloadUrl = JSON_GetString(jsonID, "/contentUrl/0")

	JSON_Release(jsonID)

	path = DND_GetDestinationIgorPath()
	name = GetFile(assetPath, sep = "/")

	UrlRequest/FILE=name/O/P=$path/Z url=downloadURL
	ASSERT(!V_flag, "Could not download dandiset asset.")

	PathInfo/S $path
	assetFilePath = S_path + name
	[data, fname] = LoadTextFile(assetFilePath)

	ASSERT(!cmpstr(refHash, Hash(data, 1)), "Invalid checksum")

	KillPath $path

	return assetFilePath
End

/// @brief Parse the REST API response and fill the DANDI set properties wave
///
/// The returned wave will have the format as described at GetDandiSetProperties()
/// and row dimension label with the asset ID.
///
/// Example: https://api.dandiarchive.org/api/dandisets/000068/versions/draft/assets/
static Function/WAVE DND_ParseSetReponse(string response)
	string path
	variable jsonID, numEntries, i

	jsonID = JSON_Parse(response)

	numEntries = JSON_GetArraySize(jsonID, "/results")

	if(!numEntries)
		JSON_Release(jsonID)
		return $""
	endif

	WAVE/T props = GetDandiSetProperties()

	Redimension/N=(numEntries, -1) props

	props[][] = JSON_GetString(jsonID, "/results/" + num2str(p) + "/" + GetDimLabel(props, COLS, q))

	JSON_Release(jsonID)

	for(i = 0; i < numEntries; i += 1)
		SetDimLabel ROWS, i, $props[i][%asset_id], props
	endfor

	return props
End

Function/S DND_FetchAssetFromSet(variable setNumber)
	string url, assetID , name, path, data, fname, assetFilePath
	variable numAssets, idx, i

	sprintf url, "https://api.dandiarchive.org/api/dandisets/%06d/versions/draft/assets/", setNumber
	UrlRequest/Z url=url
	ASSERT(!V_flag, "Could not download dandiset file list")

	WAVE/T props = DND_ParseSetReponse(S_serverResponse)

	if(!WaveExists(props))
		return ""
	endif

	assetID = DND_ChooseAsset(props)

	if(IsEmpty(assetID))
		return ""
	endif

	return DND_FetchAsset(setNumber, assetID, props[%$assetID][%path])
End
