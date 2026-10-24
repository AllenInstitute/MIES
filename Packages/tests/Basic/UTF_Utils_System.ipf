#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_SYSTEM

// Missing Tests for:
// GetExperimentName
// GetExperimentFileType
// GetFreeMemory
// IsBackgroundTaskRunning
// QuerySetIgorOption
// ForceRecompile
// GetIgorExtensionFolderName
// GetIgorExecutable
// GetArchitectureBits
// GetIgorInfo
// GetIgorProVersion
// GetIgorProBuildVersion
// GetSystemUserName
// ControlWindowToFront
// ExecuteListOfFunctions
// SleepHighPrecision
// CreateHistoryNotebook
// GetHistoryNotebookText
// GetASLREnabledState
// TurnOffASLR
// IsWindows10
// GetIgorInstanceID
// CleanupOperationQueueResult

/// @name Log entries of UploadJSONPayload for an upload of an empty JSON, which is dumped as "null"
///
/// The upload ID is appended to the regular expressions.
///@{
static StrConstant UPLOAD_START_REGEXP = "\"action\":\"start\",.*\"size\":\"4\",\"source\":\"UploadJSONPayload\",\"timeout\":\"15\",\"ts\":\"[^\"]*\",\"uploadID\":\""
static StrConstant UPLOAD_END_REGEXP   = "\"action\":\"end\",.*\"rate \[kB per s\]\":\"[0-9.]+\",\"source\":\"UploadJSONPayload\",\"ts\":\"[^\"]*\",\"uploadID\":\""
///@}

/// GetMachineEpsilon
/// @{

Function EPS_WorksWithDouble()

	variable eps, type

	type = IGOR_TYPE_64BIT_FLOAT
	eps  = GetMachineEpsilon(type)
	Make/FREE/Y=(type)/N=1 ref = 1
	Make/FREE/Y=(type)/N=1 val

	val = ref[0] + eps
	CHECK_NEQ_VAR(ref[0], val[0])

	val = ref[0] + eps / 2.0
	CHECK_EQUAL_VAR(ref[0], val[0])
End

Function EPS_WorksWithFloat()

	variable eps, type

	type = IGOR_TYPE_32BIT_FLOAT
	eps  = GetMachineEpsilon(type)
	Make/FREE/Y=(type)/N=1 ref = 1
	Make/FREE/Y=(type)/N=1 val

	val = ref[0] + eps
	CHECK_NEQ_VAR(ref[0], val[0])

	val = ref[0] + eps / 2.0
	CHECK_EQUAL_VAR(ref[0], val[0])
End

/// @}

/// ConvertXOPErrorCode
/// @{

static Function TestErrorCodeConversion()

	variable err, convErr
	string errMsg

	JSONXOP_Parse/Q ""
	err = GetRTError(0)
	CHECK_RTE(err)

	errMsg = "Error when parsing string to JSON"
	CHECK_EQUAL_STR(errMsg, GetErrMessage(err))

	convErr = ConvertXOPErrorCode(err)
	CHECK_EQUAL_VAR(convErr, 10009)

	// is idempotent
	CHECK_EQUAL_VAR(ConvertXOPErrorCode(convErr), 10009)
End

/// @}

/// UploadJSONPayload
/// @{
// UTF_TD_GENERATOR DataGenerators#UploadJSONPayloadOutcomes
static Function TestUploadJsonPayload([WAVE wv])

	variable err
	string filename, logs, msg, uploadID

	WAVE overrideResults = CreateOverrideResults(2)
	overrideResults[0] = wv[%V_flag]
	overrideResults[1] = wv[%V_responseCode]

	filename = LOG_GetFile(PACKAGE_MIES)
	DeleteFile/Z filename

	[err, msg, uploadID] = UploadJSONPayload(JSON_New())
	CHECK_EQUAL_VAR(err, wv[%err])
	CHECK_EQUAL_VAR(GrepString(msg, note(wv)), 1)
	CHECK_PROPER_STR(uploadID)

	logs = LoadTextFile(filename)
	CHECK_PROPER_STR(logs)
	CHECK_EQUAL_VAR(GrepString(logs, UPLOAD_START_REGEXP + uploadID), 1)
	// only a successful upload has an end entry
	CHECK_EQUAL_VAR(GrepString(logs, UPLOAD_END_REGEXP + uploadID), !err)
End
/// @}

// Marking the experiment as unmodified can not be tested, as igortest copies the history into the
// HistoryCarbonCopy notebook, which marks the experiment as modified again after history output

static Function GetExperimentModifiedWorks()

	ExperimentModified 1
	CHECK_EQUAL_VAR(GetExperimentModified(), 1)
End

static Function RestoreExperimentModifiedKeepsModified()

	ExperimentModified 1
	RestoreExperimentModified(1)
	CHECK_EQUAL_VAR(GetExperimentModified(), 1)
End

static Function TestCacheBackupAndRestore()

	string name

	CA_FlushCache()

	DFREF dfr = GetCacheFolder()

	Make/FREE old = p
	Note/K old, "abcd"

	Duplicate old, dfr:data

	BackupCacheWaves()
	KillDataFolder dfr
	RestoreCacheWaves()

	DFREF dfr = GetCacheFolder()

	name = GetListOfObjects(dfr, ".*")
	CHECK_EQUAL_STR(name, "data;hashmap;")

	WAVE/Z/SDFR=dfr new = $StringFromList(0, name)
	CHECK(!WaveRefsEqual(new, old))
	CHECK_EQUAL_WAVES(new, old)
End

static Function TestCacheBackupAndRestoreIntegration()

	string key = "abcd"

	KillOrMoveToTrash(dfr = GetCacheFolder())
	Make/FREE data = {NaN}
	CA_StoreEntryIntoCache(key, data)
	WAVE/Z match = CA_TryFetchingEntryFromCache(key)
	CHECK_WAVE(match, NUMERIC_WAVE)

	BackupCacheWaves()

	RenameDataFolderToUniqueName(GetCacheFolderAS(), "_old")

	RestoreCacheWaves()

	WAVE/Z match = CA_TryFetchingEntryFromCache(key)
	CHECK_WAVE(match, NUMERIC_WAVE)
End

static Function TestCacheBackupAndRestoreNoWaves()

	CA_FlushCache()

	BackupCacheWaves()

	DFREF dfr = GetCacheFolder()
	CHECK(IsDataFolderEmpty(dfr))

	RestoreCacheWaves()

	CHECK(IsDataFolderEmpty(dfr))
End

#if IgorVersion() >= 10

static Function TestGetPythonScriptsFolder()

	string loc = GetPythonScriptsFolder()

	CHECK_PROPER_STR(loc)
	CHECK(FolderExists(loc))
End

#endif
