#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_LOG
#endif // AUTOMATED_TESTING

/// @file MIES_PackageSettings.ipf
/// @brief __LOG__ Routines for dealing with JSON log files
///
/// See https://jsonlines.org and [Line-delimited JSON](https://en.wikipedia.org/wiki/JSON_streaming) for background.
///
/// In short the log will contain a complete JSON document in each line. The lines are separated by `\n`.

/// @brief Get the absolute path to the log file
threadsafe Function/S LOG_GetFile(string package)

	string folder

	folder = PS_GetSettingsFolder_TS(package)

	return folder + LOGFILE_NAME
End

/// @brief Check that the given JSON document has the required top level keys
///
/// Currently we require:
/// - `source`: Source of the log entry, usually the function issuing the add entry
/// - `exp`: Name of the Igor Pro experiment
/// - `id`: Igor Pro instance identifier, see also GetIgorInstanceID()
threadsafe static Function LOG_HasRequiredKeys(variable JSONid)

	WAVE/Z/T keys = JSON_GetKeys(JSONid, "", ignoreErr = 1)

	if(!WaveExists(keys))
		return 0
	endif

	Make/FREE/T requiredKeys = {"source", "exp", "id"}

	WAVE/Z intersection = GetSetIntersection(keys, requiredKeys)

	return WaveExists(intersection) && (DimSize(intersection, ROWS) == DimSize(requiredKeys, ROWS))
End

/// @brief Generate a JSON text with all required entries
///
/// Caller is responsible for the JSON text memory.
threadsafe Function LOG_GenerateEntryTemplate(string source)

	variable JSONid

	JSONid = JSON_New()
	JSON_AddString(JSONid, "/source", source)
	JSON_AddString(JSONid, "/exp", GetExperimentName())
	JSON_AddString(JSONid, "/id", GetIgorInstanceID()[0, 6])
	return JSONid
End

/// @brief Adds a special entry to the logfile to mark the start of a session.
///
/// Should be called from IgorBeforeNewHook().
Function LOG_MarkSessionStart(string package)

	variable JSONid

	PS_Initialize(package)

	JSONid = JSON_Parse("{}")
	LOG_AddEntryWithoutChecks(package, JSONid)
	JSON_Release(JSONid)
End

/// @brief Adds the JSONid text to the logfile without any checks
threadsafe static Function LOG_AddEntryWithoutChecks(string package, variable JSONid)

	string file, str
	variable refnum

	file = LOG_GetFile(package)

	str = JSON_Dump(JSONid, indent = -1) + LOG_FILE_LINE_END

	Open/A/Z=1 refnum as file
	if(V_flag)
		printf "Could not open the log file for appending.\r"
		printf "Dropping log message: %s\r", str
		return NaN
	endif

	FBinWrite refnum, str
	Close refnum
End

/// @brief Add entry for the current function into the log file.
///
/// Before LOG_AddEntry can be used the symbolic path must have been
/// initialized via PS_Initialize or PS_FixPackageLocation. This is best done
/// from the AfterCompiledHook().
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
/// @param stacktrace [optional, defaults to false] add the stacktrace to the log
/// @param keys    [optional, defaults to $""] Additional key-value pairs to be written into the log file. Same size as
///                                            values. Either both `keys` and `values` are present or none.
/// @param values  [optional, defaults to $""] Additional key-value pairs to be written into the log file. Same size as
///                                            keys. Either both `keys` and `values` are present or none.
threadsafe Function LOG_AddEntry(string package, string action, [variable stacktrace, WAVE/Z/T keys, WAVE/Z/T values])

	variable JSONid, numAdditionalEntries
	string caller

	if(ParamIsDefault(stacktrace))
		stacktrace = 0
	else
		stacktrace = !!stacktrace
	endif

	if(WaveExists(keys) && WaveExists(values))
		numAdditionalEntries = DimSize(keys, ROWS)
		ASSERT_TS(numAdditionalEntries == DimSize(values, ROWS), "Non-matching dimension sizes")
	endif

	caller = GetRTStackInfo(2)
	JSONid = LOG_GenerateEntryTemplate(caller)
	JSON_AddString(JSONid, "/action", action)
	JSON_AddString(JSONid, "/ts", GetISO8601TimeStamp(numFracSecondsDigits = 3, localTimeZone = 1))

	if(numAdditionalEntries > 0)
		Make/FREE/N=(numAdditionalEntries) indexHelper = JSON_AddString(JSONid, "/" + keys[p], values[p])
	endif

	if(stacktrace)
		LOG_AddStackTrace(JSONid)
	endif

	ASSERT_TS(LOG_HasRequiredKeys(JSONid), "Some mandatory object keys are missing")
	LOG_AddEntryWithoutChecks(package, JSONid)

	JSON_Release(JSONid)
End

threadsafe static Function LOG_AddStackTrace(variable JSONid)

	WAVE/T stacktrace = ListToTextWave(GetStackTrace(), "\r")
	JSON_AddWave(JSONid, "/stacktrace", stacktrace)
End
