#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma IndependentModule=IPNWB
#pragma version=0.15

/// @file IPNWB_Utils.ipf
/// @brief Utility functions

/// @brief Returns 1 if var is a finite/normal number, 0 otherwise
///
/// @hidecallgraph
/// @hidecallergraph
Function IsFinite(var)
	variable var

	return numType(var) == 0
End

/// @brief Returns 1 if str is null, 0 otherwise
/// @param str must not be a SVAR
///
/// @hidecallgraph
/// @hidecallergraph
Function isNull(str)
	string& str

	variable len = strlen(str)
	return numtype(len) == 2
End

/// @brief Returns one if str is empty or null, zero otherwise.
/// @param str must not be a SVAR
///
/// @hidecallgraph
/// @hidecallergraph
Function isEmpty(str)
	string& str

	variable len = strlen(str)
	return numtype(len) == 2 || len <= 0
End

/// @brief Return the seconds since Igor Pro epoch (1/1/1904) in UTC time zone
Function DateTimeInUTC()
	return DateTime - date2secs(-1, -1, -1)
End

/// @brief Return a string in ISO 8601 format with timezone UTC
/// @param secondsSinceIgorEpoch [optional, defaults to number of seconds until now] Seconds since the Igor Pro epoch (1/1/1904) in UTC
Function/S GetISO8601TimeStamp([secondsSinceIgorEpoch])
	variable secondsSinceIgorEpoch

	string str

	if(ParamIsDefault(secondsSinceIgorEpoch))
		secondsSinceIgorEpoch = DateTimeInUTC()
	endif

	sprintf str, "%s %sZ", Secs2Date(secondsSinceIgorEpoch, -2), Secs2Time(secondsSinceIgorEpoch, 3, 0)

	return str
End

/// @brief Parse a simple unit with prefix into its prefix and unit.
///
/// Note: The currently allowed units are the SI base units [1] and other
/// common derived units.  And in accordance to SI definitions, "kg" is a
/// *base* unit. "Simple" unit means means one unit with prefix, not e.g.
/// "km/s".
///
/// @param[in]  unitWithPrefix string to parse, examples are "ms" or "kHz"
/// @param[out] prefix         symbol of decimal multipler of the unit,
///                            see below or [1] chapter 3 for the full list
/// @param[out] numPrefix      numerical value of the decimal multiplier
/// @param[out] unit           unit
///
/// \rst
///
/// =====  ======  ===============
/// Name   Symbol  Numerical value
/// =====  ======  ===============
/// yotta    Y        1e24
/// zetta    Z        1e21
/// exa      E        1e18
/// peta     P        1e15
/// tera     T        1e12
/// giga     G        1e9
/// mega     M        1e6
/// kilo     k        1e3
/// hecto    h        1e2
/// deca     da       1e1
/// deci     d        1e-1
/// centi    c        1e-2
/// milli    m        1e-3
/// micro    mu       1e-6
/// nano     n        1e-9
/// pico     p        1e-12
/// femto    f        1e-15
/// atto     a        1e-18
/// zepto    z        1e-21
/// yocto    y        1e-24
/// =====  ======  ===============
///
/// \endrst
///
/// [1]: 8th edition of the SI Brochure (2014), http://www.bipm.org/en/publications/si-brochure
Function ParseUnit(unitWithPrefix, prefix, numPrefix, unit)
	string unitWithPrefix
	string &prefix
	variable &numPrefix
	string &unit

	string expr

	ASSERT(!isEmpty(unitWithPrefix), "empty unit")

	prefix    = ""
	numPrefix = NaN
	unit      = ""

	expr = "(Y|Z|E|P|T|G|M|k|h|d|c|m|mu|n|p|f|a|z|y)?[[:space:]]*(m|kg|s|A|K|mol|cd|Hz|V|N|W|J|a.u.)"

	SplitString/E=(expr) unitWithPrefix, prefix, unit
	ASSERT(V_flag >= 1, "Could not parse unit string")

	numPrefix = GetDecimalMultiplierValue(prefix)
End

/// @brief Return the numerical value of a SI decimal multiplier
///
/// @see ParseUnit
Function GetDecimalMultiplierValue(prefix)
	string prefix

	if(isEmpty(prefix))
		return 1
	endif

	Make/FREE/T prefixes = {"Y", "Z", "E", "P", "T", "G", "M", "k", "h", "da", "d", "c", "m", "mu", "n", "p", "f", "a", "z", "y"}
	Make/FREE/D values   = {1e24, 1e21, 1e18, 1e15, 1e12, 1e9, 1e6, 1e3, 1e2, 1e1, 1e-1, 1e-2, 1e-3, 1e-6, 1e-9, 1e-12, 1e-15, 1e-18, 1e-21, 1e-24}

	FindValue/Z/TXOP=(1 + 4)/TEXT=(prefix) prefixes
	ASSERT(V_Value != -1, "Could not find prefix")

	ASSERT(DimSize(prefixes, ROWS) == DimSize(values, ROWS), "prefixes and values wave sizes must match")
	return values[V_Value]
End

/// @brief Write a text dataset only if it is not equal to #PLACEHOLDER
///
/// @param locationID                                  HDF5 identifier, can be a file or group
/// @param name                                        Name of the HDF5 dataset
/// @param str                                         Contents to write into the dataset
/// @param chunkedLayout [optional, defaults to false] Use chunked layout with compression and shuffling. Will be ignored for small waves.
Function WriteTextDatasetIfSet(locationID, name, str, [chunkedLayout])
	variable locationID
	string name, str
	variable chunkedLayout

	chunkedLayout = ParamIsDefault(chunkedLayout) ? 0 : !!chunkedLayout

	if(!cmpstr(str, PLACEHOLDER))
		return NaN
	endif

	H5_WriteTextDataset(locationID, name, str=str, chunkedLayout=chunkedLayout)
End

/// @brief Remove a string prefix from each list item and
/// return the new list
Function/S RemovePrefixFromListItem(prefix, list, [listSep])
	string prefix, list
	string listSep
	if(ParamIsDefault(listSep))
		listSep = ";"
	endif

	string result, entry
	variable numEntries, i, len

	result = ""
	len = strlen(prefix)
	numEntries = ItemsInList(list, listSep)
	for(i = 0; i < numEntries; i += 1)
		entry = StringFromList(i, list, listSep)
		if(!cmpstr(entry[0,(len-1)], prefix))
			entry = entry[(len),inf]
		endif
		result = AddListItem(entry, result, listSep, inf)
	endfor

	return result
End

/// @brief Turn a persistent wave into a free wave
Function/Wave MakeWaveFree(wv)
	WAVE wv

	DFREF dfr = NewFreeDataFolder()

	MoveWave wv, dfr

	return wv
End

/// @brief Rename wv to newName. Check for Unique Name and return new name of wave
Function MoveAndRename(wv, newName, [dfr])
	WAVE wv
	String newName
	DFREF dfr

	if(ParamIsDefault(dfr))
		dfr = GetWavesDataFolderDFR(wv)
	endif
	newName = UniqueWaveName(dfr, newName)

	MoveWave wv, dfr:$newName
End

/// @brief Returns a wave name not used in the given datafolder
///
/// Basically a datafolder aware version of UniqueName for datafolders
///
/// @param dfr 	    datafolder reference where the new datafolder should be created
/// @param baseName first part of the wave name, might be shorted due to Igor Pro limitations
Function/S UniqueWaveName(dfr, baseName)
	dfref dfr
	string baseName

	variable index
	string name
	string path

	ASSERT(!isEmpty(baseName), "baseName must not be empty" )
	ASSERT(DataFolderExistsDFR(dfr), "dfr does not exist")

	// shorten basename so that we can attach some numbers
	baseName = CleanupName(baseName[0, 26], 0)
	path = GetDataFolder(1, dfr)
	name = baseName

	do
		if(!WaveExists($(path + name)))
			return name
		endif

		name = baseName + "_" + num2istr(index)

		index += 1
	while(index < 10000)

	DEBUGPRINT("Could not find a unique folder with 10000 trials")

	return ""
End

/// @brief Checks if the datafolder referenced by dfr exists.
///
/// Unlike DataFolderExists() a dfref pointing to an empty ("") dataFolder is considered non-existing here.
/// @returns one if dfr is valid and references an existing or free datafolder, zero otherwise
/// Taken from http://www.igorexchange.com/node/2055
Function DataFolderExistsDFR(dfr)
	dfref dfr

	string dataFolder

	switch(DataFolderRefStatus(dfr))
		case 0: // invalid ref, does not exist
			return 0
		case 1: // might be valid
			dataFolder = GetDataFolder(1,dfr)
			return cmpstr(dataFolder,"") != 0 && DataFolderExists(dataFolder)
		case 3: // free data folders always exist
			return 1
		default:
			Abort "unknown status"
			return 0
	endswitch
End

/// @brief Bring the control window (the window with the command line) to the
///        front of the desktop
Function ControlWindowToFront()
	DoWindow/H
End

/// @brief Return the base name of the file
///
/// Given `path/file.suffix` this gives `file`.
///
/// @param filePathWithSuffix full path
/// @param sep                [optional, defaults to ":"] character
///                           separating the path components
Function/S GetBaseName(filePathWithSuffix, [sep])
	string filePathWithSuffix, sep

	if(ParamIsDefault(sep))
		sep = ":"
	endif

	return ParseFilePath(3, filePathWithSuffix, sep, 1, 0)
End

/// @brief Return the file extension (suffix)
///
/// Given `path/file.suffix` this gives `suffix`.
///
/// @param filePathWithSuffix full path
/// @param sep                [optional, defaults to ":"] character
///                           separating the path components
Function/S GetFileSuffix(filePathWithSuffix, [sep])
	string filePathWithSuffix, sep

	if(ParamIsDefault(sep))
		sep = ":"
	endif

	return ParseFilePath(4, filePathWithSuffix, sep, 0, 0)
End

/// @brief Return the folder of the file
///
/// Given `path/file.suffix` this gives `path`.
///
/// @param filePathWithSuffix full path
/// @param sep                [optional, defaults to ":"] character
///                           separating the path components
Function/S GetFolder(filePathWithSuffix, [sep])
	string filePathWithSuffix, sep

	if(ParamIsDefault(sep))
		sep = ":"
	endif

	return ParseFilePath(1, filePathWithSuffix, sep, 1, 0)
End

/// @brief Return the filename with extension
///
/// Given `path/file.suffix` this gives `file.suffix`.
///
/// @param filePathWithSuffix full path
/// @param sep                [optional, defaults to ":"] character
///                           separating the path components
Function/S GetFile(filePathWithSuffix, [sep])
	string filePathWithSuffix, sep

	if(ParamIsDefault(sep))
		sep = ":"
	endif

	return ParseFilePath(0, filePathWithSuffix, sep, 1, 0)
End
