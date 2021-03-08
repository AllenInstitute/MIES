#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_LOG
#endif

/// @file MIES_PackageSettings.ipf
/// @brief __LOG__ Routines for dealing with JSON log files
///
/// See https://jsonlines.org and [Line-delimited JSON](https://en.wikipedia.org/wiki/JSON_streaming) for background.
///
/// In short the log will contain a complete JSON document in each line. The lines are separted by `\n`.

/// @brief Get the absolute path to the log file
threadsafe Function/S LOG_GetFile(string package)
	string folder

	folder = PS_GetSettingsFolder_TS(package)

	return folder + ":Log.jsonl"
End

/// @brief Check that the given JSON document has the required top level keys
///
/// Currently we require:
/// - `ts`: ISO8601 timestamp
/// - `source`: Source of the log entry, usually the function issuing the add entry
/// - `exp`: Name of the Igor Pro experiment
threadsafe static Function LOG_HasRequiredKeys(variable JSONid)
	WAVE/T/Z keys = JSON_GetKeys(JSONid, "", ignoreErr = 1)

	if(!WaveExists(keys))
		return 0
	endif

	Make/FREE/T requiredKeys = {"ts", "source", "exp"}

	WAVE/Z intersection = GetSetIntersection(keys, requiredKeys)

	return WaveExists(intersection) && (DimSize(intersection, ROWS) == DimSize(requiredKeys, ROWS))
End

threadsafe static Function LOG_GenerateEntryTemplate(string source)
	variable JSONid

	JSONid = JSON_New()
	JSON_AddString(JSONid, "/ts", GetISO8601TimeStamp(numFracSecondsDigits = 3, localTimeZone = 1))
	JSON_AddString(JSONid, "/source", source)

	return JSONid
End

/// @brief Low level function to add log entries
///
/// Allows callers to fine tune the added JSON document.
///
/// @param package package name, this determines the log file
/// @param JSONid  JSON document to add, top level object must contain all required keys. See @ref LOG_HasRequiredKeys
///                for the list of required keys.
threadsafe Function LOG_AddEntryLowLevel(string package, variable JSONid)
	string file, str
	variable refnum

	ASSERT_TS(LOG_HasRequiredKeys(JSONid), "Some mandatory object keys are missing")

	file = LOG_GetFile(package)

	Open/A/Z=2 refnum as file

	str = JSON_Dump(JSONid, indent = -1) + "\n"
	FBinWrite refnum, str
	Close refnum
End

/// @brief Add entry for the current function into the log file.
///
/// `source` is automatically set to `DoWork` and `experiment` to the current igor experiment name. Use
/// LOG_AddEntryLowLevel if you want to override those.
///
/// Usage:
/// \rst
/// .. code-block:: igorpro
///
///     Function DoWork()
///
///         LOG_AddEntry("my package", "start")
///
///         // ...
///
///         LOG_AddEntry("my package", "end")
///     End
/// \endrst
///
/// Result:
/// \rst
/// .. code-block:: js
///
///    {"action":"start","exp":"HardwareTests","source":"DoWork","ts":"2021-03-09T17:20:10.252+01:00"}
///    {"action":"end","exp":"HardwareTests","source":"DoWork","ts":"2021-03-09T17:20:10.298+01:00"}
///
/// \endrst
///
/// @param package package name, this determines the log file
/// @param action  additional string, can be something like `start` or `end`
/// @param keys    [optional, defaults to $""] Additional key-value pairs to be written into the log file. Same size as
///                                            values. Either both `keys` and `values` are present or none.
/// @param values  [optional, defaults to $""] Additional key-value pairs to be written into the log file. Same size as
///                                            keys. Either both `keys` and `values` are present or none.
Function LOG_AddEntry(string package, string action, [WAVE/T keys, WAVE/T values])

	// create the folder if it does not exist
	PathInfo PackageFolder
	if(!V_flag)
		PS_GetSettingsFolder(package)
	endif

	if(ParamIsDefault(keys) && ParamIsDefault(values))
		return LOG_AddEntryImp(package, action, GetRTStackInfo(2), $"", $"")
	else
		return LOG_AddEntryImp(package, action, GetRTStackInfo(2), keys, values)
	endif
End

/// @brief Threadsafe version of LOG_AddEntry()
///
/// Callers need to write the calling function name into `caller`.
/// @todo IP9-only: merge with LOG_AddEntry
threadsafe Function LOG_AddEntry_TS(string package, string action, string caller, [WAVE/T keys, WAVE/T values])

	if(ParamIsDefault(keys) && ParamIsDefault(values))
		return LOG_AddEntryImp(package, action, caller, $"", $"")
	else
		return LOG_AddEntryImp(package, action, caller, keys, values)
	endif
End

threadsafe static Function LOG_AddEntryImp(string package, string action, string caller, WAVE/T/Z keys, WAVE/T/Z values)
	variable JSONid, numAdditionalEntries

	if(WaveExists(keys) && WaveExists(values))
		numAdditionalEntries = DimSize(keys, ROWS)
		ASSERT_TS(numAdditionalEntries == DimSize(values, ROWS), "Non-matching dimension sizes")
	endif

	JSONid = LOG_GenerateEntryTemplate(caller)
	JSON_AddString(JSONid, "/action", action)
	JSON_AddString(JSONid, "/exp", GetExperimentName())

	if(numAdditionalEntries > 0)
		Make/FREE/N=(numAdditionalEntries) indexHelper = JSON_AddString(JSONid, "/" + keys[p], values[p])
	endif

	LOG_AddEntryLowLevel(package, JSONid)
	JSON_Release(JSONid)
End
