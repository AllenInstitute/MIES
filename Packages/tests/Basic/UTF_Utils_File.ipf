#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTILSTEST_FILE

// Missing Tests for:
// UniqueFileOrFolder
// IsDriveValid
// GetDrive
// CreateFolderOnDisk
// GetBaseName
// GetFileSuffix
// GetFile
// GetWindowsPath
// GetHFSPath
// GetUniqueSymbolicPath
// AskUserForExistingFolder
// HasEnoughDiskspaceFree
// SaveTextFile
// LoadTextFile
// GetFileVersion
// GetFileSize
// HFSPathToPosix
// HFSPathToWindows
// HFSPathToNative
// GetSymbolicPathForDiagnosticsDirectory
// ShowDiagnosticsDirectory
// SanitizeFilename
// LoadWaveFromDisk
// StoreWaveOnDisk
// GetUserDocumentsFolderPath
// CleanupExperimentName
// CalcHashForFile
// CheckIfPathsRefIdenticalFiles
// GetProgramFilesFolder

// FileExists, FolderExists, ResolveAlias
/// @{

Function FR_FileExistsWorks()

	CHECK(FileExists(FunctionPath("")))

#if defined(WINDOWS)
	CHECK(!FileExists("C:\\I_DONT_EXIST"))
	CHECK(!FileExists("C:\\"))
#elif defined(MACINTOSH)
	CHECK(!FileExists("Macintosh HD:I_DONT_EXIST"))
	CHECK(!FileExists("Macintosh HD:"))
#else
	FAIL()
#endif
End

Function FR_FolderExistsWorks()

	CHECK(!FolderExists(FunctionPath("")))

#if defined(WINDOWS)
	CHECK(!FolderExists("C:\\I_DONT_EXIST"))
	CHECK(FolderExists("C:\\"))
	CHECK(FolderExists("C:"))
#elif defined(MACINTOSH)
	CHECK(!FolderExists("Macintosh HD:I_DONT_EXIST"))
	CHECK(FolderExists("Macintosh HD:"))
#else
	FAIL()
#endif
End

Function FR_WorksWithAliasFiles()

	string target, alias
	string expected, ref

	// alias is a folder
	target = GetFolder(FunctionPath(""))
	alias  = GetFolder(target) + "alias"
	CreateAliasShortCut target as alias
	CHECK(!V_flag)
	CHECK(!FileExists(S_path))
	CHECK(FolderExists(S_path))

	expected = target
	ref      = ResolveAlias(S_path)
	CHECK_EQUAL_STR(expected, ref)

	DeleteFile/Z alias + ".lnk"

	// alias is a file
	target = FunctionPath("")
	alias  = GetFolder(target) + "alias.ipf"
	CreateAliasShortCut/Z target as alias
	CHECK(!V_flag)
	CHECK(FileExists(S_path))
	CHECK(!FolderExists(S_path))

	expected = target
	ref      = ResolveAlias(S_path)
	CHECK_EQUAL_STR(expected, ref)

	DeleteFile/Z alias + ".lnk"
End

/// @}

// GetAllFilesRecursivelyFromPath
/// @{

static Function TestGetAllFilesRecursivelyFromPath()

	string folder, symbPath, list

	folder = GetFolder(FunctionPath("")) + "testFolder:"

	symbPath = GetUniqueSymbolicPath()
	NewPath/Q/O/C/Z $symbPath, folder
	CHECK(!V_Flag)

	CreateFolderOnDisk(folder + "b:")
	CreateFolderOnDisk(folder + "c:")

	SaveTextFile("", folder + "file.txt")
	SaveTextFile("", folder + "b:file1.txt")
	SaveTextFile("", folder + "c:file2.txt")

	CreateAliasShortcut/Z/P=$symbPath "file.txt" as "alias.txt"
	CHECK(!V_flag)

	list = GetAllFilesRecursivelyFromPath(symbPath, extension = ".txt")
	CHECK_PROPER_STR(list)

	WAVE/T result = ListToTextWave(list, FILE_LIST_SEP)
	result[] = RemovePrefix(result[p], start = folder)
	CHECK_EQUAL_TEXTWAVES(result, {"file.txt", "b:file1.txt", "c:file2.txt"})

	// no matches
	list = GetAllFilesRecursivelyFromPath(symbPath, extension = ".abc")
	CHECK_EMPTY_STR(list)

	KillPath $symbPath
	CHECK_NO_RTE()
End

/// @}

// LoadTextFileToWave
/// @{

static Function TestLoadTextFileToWave1()

	variable i, cnt, fNum
	string line
	string tmpFile = GetFolder(FunctionPath("")) + "LoadTextWave.txt"

	line = PadString("", MEGABYTE - 1, 0x20) + "\n"
	cnt  = ceil(STRING_MAX_SIZE / MEGABYTE + 1)
	Open fNum as tmpFile
	for(i = 0; i < cnt; i += 1)
		FBinWrite fnum, line
	endfor
	Close fNum

	WAVE/T input = LoadTextFileToWave(tmpFile, "\n")
	CHECK_WAVE(input, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(input, ROWS), cnt)

	DeleteFile tmpFile
End

static Function TestLoadTextFileToWave2()

	variable fNum
	string tmpFile = GetFolder(FunctionPath("")) + "LoadTextWave.txt"

	Open fNum as tmpFile
	Close fNum
	WAVE/T input = LoadTextFileToWave(tmpFile, "\n")
	CHECK_WAVE(input, NULL_WAVE)

	DeleteFile tmpFile
End

static Function TestLoadTextFileToWave3()

	WAVE/T input = LoadTextFileToWave("", "")
	CHECK_WAVE(input, NULL_WAVE)
End

static Function GetDayOfWeekTest()

	variable i, day

	Make/FREE days = {FRIDAY, SATURDAY, SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY}
	for(day : days)
		CHECK_EQUAL_VAR(GetDayOfWeek(i * SECONDS_PER_DAY), day)
		i += 1
	endfor

	try
		GetDayOfWeek(NaN)
		FAIL()
	catch
		PASS()
	endtry
	try
		GetDayOfWeek(Inf)
		FAIL()
	catch
		PASS()
	endtry
	try
		GetDayOfWeek(-Inf)
		FAIL()
	catch
		PASS()
	endtry
End

/// @}
