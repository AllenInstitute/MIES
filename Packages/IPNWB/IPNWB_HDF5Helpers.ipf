#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion=6.3
#pragma IndependentModule=IPNWB
#pragma version=0.12

/// @cond DOXYGEN_IGNORES_THIS
#include "HDF5 Browser", version=1.04
/// @endcond

/// @file IPNWB_HDF5Helpers.ipf
/// @brief __H5__ Wrapper functions for convenient use of the HDF5 operations

/// @brief Write a string or text wave into a HDF5 dataset
///
/// @param locationID                                  HDF5 identifier, can be a file or group
/// @param name                                        Name of the HDF5 dataset
/// @param str                                         Contents to write into the dataset
/// @param wvText                                      Contents to write into the dataset
/// @param overwrite [optional, defaults to false]     Should existing datasets be overwritten
/// @param chunkedLayout [optional, defaults to false] Use chunked layout with compression and shuffling. Will be ignored for small waves.
/// @param skipIfExists [optional, defaults to false]  Do nothing if the dataset already exists
/// @param writeIgorAttr [optional, defaults to false] Add Igor specific attributes to the dataset, see the `/IGOR` flag of `HDF5SaveData`
///
/// Only one of `str` or `wvText` can be given.
Function H5_WriteTextDataset(locationID, name, [str, wvText, overwrite, chunkedLayout, skipIfExists, writeIgorAttr])
	variable locationID
	string name, str
	Wave/Z/T wvText
	variable overwrite, chunkedLayout, skipIfExists, writeIgorAttr

	overwrite     = ParamIsDefault(overwrite)     ? 0 : !!overwrite
	chunkedLayout = ParamIsDefault(chunkedLayout) ? 0 : !!chunkedLayout
	skipIfExists  = ParamIsDefault(skipIfExists)  ? 0 : !!skipIfExists
	writeIgorAttr = ParamIsDefault(writeIgorAttr) ? 0 : !!writeIgorAttr

	ASSERT(ParamIsDefault(str) + ParamIsDefault(wvText) == 1, "Need exactly one of str or wvText")

	if(!ParamIsDefault(str))
		Make/FREE/T/N=1 wvText = str
	endif

	H5_WriteDatasetLowLevel(locationID, name, wvText, overwrite, chunkedLayout, skipIfExists, writeIgorAttr)
End

/// @brief Write a variable or text wave into a HDF5 dataset
///
/// @param locationID                                  HDF5 identifier, can be a file or group
/// @param name                                        Name of the HDF5 dataset
/// @param var                                         Contents to write into the dataset
/// @param varType                                     Type of the data, must be given if `var` is supplied. See @ref IgorTypes
/// @param wv                                          Contents to write into the dataset
/// @param overwrite [optional, defaults to false]     Should existing datasets be overwritten
/// @param chunkedLayout [optional, defaults to false] Use chunked layout with compression and shuffling. Will be ignored for small waves.
/// @param skipIfExists [optional, defaults to false]  Do nothing if the dataset already exists
/// @param writeIgorAttr [optional, defaults to false] Add Igor specific attributes to the dataset, see the `/IGOR` flag of `HDF5SaveData`
///
/// Only one of `var` or `wv` can be given.
Function H5_WriteDataset(locationID, name, [var, varType, wv, overwrite, chunkedLayout, skipIfExists, writeIgorAttr])
	variable locationID
	string name
	variable var, varType
	Wave/Z wv
	variable overwrite, chunkedLayout, skipIfExists, writeIgorAttr

	overwrite     = ParamIsDefault(overwrite)     ? 0 : !!overwrite
	chunkedLayout = ParamIsDefault(chunkedLayout) ? 0 : !!chunkedLayout
	skipIfExists  = ParamIsDefault(skipIfExists)  ? 0 : !!skipIfExists
	writeIgorAttr = ParamIsDefault(writeIgorAttr) ? 0 : !!writeIgorAttr

	ASSERT(ParamIsDefault(var) + ParamIsDefault(wv) == 1, "Need exactly one of var or wv")

	if(!ParamIsDefault(var))
		ASSERT(!ParamIsDefault(varType), "var needs varType")
		Make/FREE/Y=(varType)/N=1 wv = var
	endif

	H5_WriteDatasetLowLevel(locationID, name, wv, overwrite, chunkedLayout, skipIfExists, writeIgorAttr)
End

static Constant H5_CHUNK_SIZE = 8192 // 2^13, determined by trial-and-error

/// @brief Return a wave for the valid chunk sizes of each dimension.
static Function/Wave H5_GetChunkSizes(wv)
	WAVE wv

	MAKE/FREE/N=(WaveDims(wv))/I/U chunkSizes = (DimSize(wv, p) > H5_CHUNK_SIZE ? H5_CHUNK_SIZE : 32)

	return chunkSizes
End

/// @see H5_WriteTextDataset or H5_WriteDataset
static Function H5_WriteDatasetLowLevel(locationID, name, wv, overwrite, chunkedLayout, skipIfExists, writeIgorAttr)
	variable locationID
	string name
	Wave wv
	variable overwrite, chunkedLayout, skipIfExists, writeIgorAttr

	variable numDims, attrFlag

	numDims = WaveDims(wv)

	if(skipIfExists && H5_DatasetExists(locationID, name))
		return NaN
	endif

	attrFlag = writeIgorAttr ? -1 : 0

	if(chunkedLayout)
		WAVE chunkSizes = H5_GetChunkSizes(wv)
	endif

	if(overwrite)
		if(chunkedLayout)
			if(numDims == 1)
				HDF5SaveData/IGOR=(attrFlag)/GZIP={3, 1}/LAYO={2, chunkSizes[ROWS]}/MAXD={-1}/O/Z wv, locationID, name
			elseif(numDims == 2)
				HDF5SaveData/IGOR=(attrFlag)/GZIP={3, 1}/LAYO={2, chunkSizes[ROWS], chunkSizes[COLS]}/MAXD={-1, -1}/O/Z wv, locationID, name
			elseif(numDims == 3)
				HDF5SaveData/IGOR=(attrFlag)/GZIP={3, 1}/LAYO={2, chunkSizes[ROWS], chunkSizes[COLS], chunkSizes[LAYERS]}/MAXD={-1, -1, -1}/O/Z wv, locationID, name
			elseif(numDims == 4)
				HDF5SaveData/IGOR=(attrFlag)/GZIP={3, 1}/LAYO={2, chunkSizes[ROWS], chunkSizes[COLS], chunkSizes[LAYERS], chunkSizes[CHUNKS]}/MAXD={-1, -1, -1, -1}/O/Z wv, locationID, name
			else
				ASSERT(0, "unhandled numDims")
			endif
		else
			HDF5SaveData/IGOR=(attrFlag)/O/Z wv, locationID, name
		endif
	else
		if(chunkedLayout)
			if(numDims == 1)
				HDF5SaveData/IGOR=(attrFlag)/GZIP={3, 1}/LAYO={2, chunkSizes[ROWS]}/MAXD={-1}/Z wv, locationID, name
			elseif(numDims == 2)
				HDF5SaveData/IGOR=(attrFlag)/GZIP={3, 1}/LAYO={2, chunkSizes[ROWS], chunkSizes[COLS]}/MAXD={-1, -1}/Z wv, locationID, name
			elseif(numDims == 3)
				HDF5SaveData/IGOR=(attrFlag)/GZIP={3, 1}/LAYO={2, chunkSizes[ROWS], chunkSizes[COLS], chunkSizes[LAYERS]}/MAXD={-1, -1, -1}/Z wv, locationID, name
			elseif(numDims == 4)
				HDF5SaveData/IGOR=(attrFlag)/GZIP={3, 1}/LAYO={2, chunkSizes[ROWS], chunkSizes[COLS], chunkSizes[LAYERS], chunkSizes[CHUNKS]}/MAXD={-1, -1, -1, -1}/Z wv, locationID, name
			else
				ASSERT(0, "unhandled numDims")
			endif
		else
			HDF5SaveData/IGOR=(attrFlag)/Z wv, locationID, name
		endif
	endif

	if(V_flag)
		HDf5DumpErrors/CLR=1
		HDF5DumpState
		ASSERT(0, "Could not store HDF5 dataset to file")
	endif
End

/// @brief Attach a text attribute to the given location
///
/// @param locationID                              HDF5 identifier, can be a file, group or dataset
/// @param attrName                                Name of the attribute
/// @param path                                    Additional path on top of `locationID` which identifies the object onto which the
///                                                attribute should be attached.
/// @param wvText                                  Contents to write into the attribute
/// @param list                                    Contents to write into the attribute, list will be written as 1D-array
/// @param str                                     Contents to write into the attribute
/// @param overwrite [optional, defaults to false] Should existing attributes be overwritten
///
/// Only one of `str `, `wvText` or `list` can be given.
Function H5_WriteTextAttribute(locationID, attrName, path, [wvText, list, str, overwrite])
	variable locationID
	string attrName, path
	WAVE/T/Z wvText
	string list, str
	variable overwrite

	ASSERT(ParamIsDefault(wvText) + ParamIsDefault(str) + ParamIsDefault(list) == 2, "Need exactly one of wvText, str or list")

	if(!ParamIsDefault(str))
		Make/FREE/T/N=(1) data = str
	elseif(!ParamIsDefault(list))
		Make/FREE/T/N=(ItemsInList(list)) data = StringFromList(p, list)
	elseif(!ParamIsDefault(wvText))
		ASSERT(WaveExists(wvText), "wvText does not exist")
		WAVE/T data = wvText
	endif

	overwrite = ParamIsDefault(overwrite) ? 0 : !!overwrite

	if(overwrite)
		HDF5SaveData/A=attrName/IGOR=0/O/Z data, locationID, path
	else
		HDF5SaveData/A=attrName/IGOR=0/Z data, locationID, path
	endif

	if(V_flag)
		HDf5DumpErrors/CLR=1
		HDF5DumpState
		ASSERT(0, "Could not write HDF5 attribute to file")
	endif
End

/// @brief Attach a numerical attribute to the given location
///
/// @param locationID                              HDF5 identifier, can be a file, group or dataset
/// @param attrName                                Name of the attribute
/// @param path                                    Additional path on top of `locationID` which identifies
///                                                the object onto which the attribute should be attached.
/// @param var                                     Contents to write into the attribute
/// @param varType                                 Type of the attribute, see @ref IgorTypes
/// @param overwrite [optional, defaults to false] Should existing attributes be overwritten
///
/// Only one of `str `, `wvText` or `list` can be given.
Function H5_WriteAttribute(locationID, attrName, path, var, varType, [overwrite])
	variable locationID
	string attrName, path
	variable var, varType
	variable overwrite

	Make/FREE/Y=(varType)/N=1 data = var

	overwrite = ParamIsDefault(overwrite) ? 0 : !!overwrite

	if(overwrite)
		HDF5SaveData/A=attrName/IGOR=0/O/Z data, locationID, path
	else
		HDF5SaveData/A=attrName/IGOR=0/Z data, locationID, path
	endif

	if(V_flag)
		HDf5DumpErrors/CLR=1
		HDF5DumpState
		ASSERT(0, "Could not write HDF5 attribute to file")
	endif
End

/// @brief Return 1 if the given HDF5 file is already open, 0 otherwise.
///
/// @param fileID HDF5 locationID from `HDF5OpenFile`.
Function H5_IsFileOpen(fileID)
	variable fileID

	// group "/" does exist, therefore the fileID refers to an open file
	return H5_GroupExists(fileID, "/")
End

/// @brief Return 1 if the given HDF5 dataset exists, 0 otherwise.
///
/// @param[in] locationID           HDF5 identifier, can be a file or group
/// @param[in] name                 Additional path on top of `locationID` which identifies
///                                 the dataset
Function H5_DatasetExists(locationID, name)
	variable locationID
	string name

	STRUCT HDF5DataInfo di
	InitHDF5DataInfo(di)

	return !HDF5DatasetInfo(locationID, name, 2^0, di)
End

/// @brief Return 1 if the given HDF5 group exists, 0 otherwise.
///
/// @param[in] locationID           HDF5 identifier, can be a file or group
/// @param[in] path                 Additional path on top of `locationID` which identifies
///                                 the group
/// @param[out] groupID [optional]  Allows to return the locationID of the group, zero in case
///                                 the group does not exist. If this parameter is not provided,
///                                 the group is closed before the function returns.
Function H5_GroupExists(locationID, path, [groupID])
	variable locationID
	string path
	variable &groupID

	variable id, success

	HDF5OpenGroup/Z locationID, path, id
	success = !V_Flag

	if(ParamIsDefault(groupID))
		if(success)
			HDF5CloseGroup id
		endif
	else
		groupID = id
	endif

	return success
End

/// @brief Create all groups along the given path
///
/// @param[in] locationID          HDF5 identifier, can be a file or group
/// @param[in] path                Additional path on top of `locationID` which identifies
///                                the group
/// @param[out] groupID [optional] Allows to return the locationID of the group, zero in case
///                                the group could not be created. If this parameter is not
///                                provided, the group is closed before the function returns.
Function H5_CreateGroupsRecursively(locationID, path, [groupID])
	variable locationID
	string path
	variable &groupID

	variable id, i, numElements, start
	string str

	if(!H5_GroupExists(locationID, path, groupID=id))
		numElements = ItemsInList(path, "/")

		if(!cmpstr(path[0], "/"))
			start = 1
			str   = "/"
		else
			start = 0
			str   = ""
		endif

		for(i = start; i < numElements; i += 1)
			str += StringFromList(i, path, "/")

			HDF5CreateGroup/Z locationID, str, id
			if(V_flag)
				HDf5DumpErrors/CLR=1
				HDF5DumpState
				ASSERT(0, "Could not create HDF5 group")
			endif

			if(i != numElements - 1)
				HDF5CloseGroup/Z id
			endif

			str += "/"
		endfor
	endif

	if(ParamIsDefault(groupID))
		HDF5CloseGroup id
	else
		groupID = id
	endif
End
