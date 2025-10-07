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
static Function TestUploadJsonPayload()

	variable jsonID
	string filename, logs, retFilename

	WAVE overrideResults = CreateOverrideResults(1)
	overrideResults[] = 1

	filename = LOG_GetFile(PACKAGE_MIES)
	DeleteFile/Z filename

	jsonID = JSON_New()
	UploadJSONPayload(jsonID)

	[logs, retFilename] = LoadTextFile(filename)
	CHECK_PROPER_STR(logs)
	CHECK(GrepString(logs, "\"S_ServerResponse\":\"fake error\",\"V_Flag\":\"1\",\"action\":\"URLRequest failed"))
End
/// @}

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
	CHECK_EQUAL_STR(name, "data;")

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
