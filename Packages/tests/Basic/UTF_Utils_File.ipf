#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_FILE

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
// ShowDiagnosticsDirectory
// SanitizeFilename
// LoadWaveFromDisk
// StoreWaveOnDisk
// GetUserDocumentsFolderPath
// CleanupExperimentName
// CalcHashForFile
// CheckIfPathsRefIdenticalFiles
// GetProgramFilesFolder

// FileExists, FolderExists
/// @{

Function CheckMiscSettings()

	string folder, symbPath

	folder = GetFolder(FunctionPath("")) + "testFolder:"

	symbPath = GetUniqueSymbolicPath()
	NewPath/Q/O/C/Z $symbPath, folder
	CHECK(!V_Flag)

	DeleteFolder/P=$symbPath/Z
	INFO("When the check fails, ensure that you have set Misc->Miscellaneous Settings->Miscellaneous->\"Operations that overwrite or delete folders\" to \"Always give permission\"")
	REQUIRE(!V_Flag)
End

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

	string folder, symbPath, list, cmd, symbPathSub

	folder = GetFolder(FunctionPath("")) + "testFolder:"

	symbPath = GetUniqueSymbolicPath()
	NewPath/Q/O/C/Z $symbPath, folder
	CHECK(!V_Flag)

	// start with a fresh folder
	DeleteFolder/P=$symbPath/Z

	NewPath/Q/O/C/Z $symbPath, folder
	CHECK(!V_Flag)

	CreateFolderOnDisk(folder + "b:")
	CreateFolderOnDisk(folder + "c:")
	CreateFolderOnDisk(folder + "d:")

	SaveTextFile("", folder + "file.txt")
	SaveTextFile("", folder + "b:file1.txt")
	SaveTextFile("", folder + "c:file2.txt")

	CreateAliasShortcut/Z/P=$symbPath "file.txt" as "alias.txt"
	CHECK(!V_flag)

	WAVE/Z/T result = GetAllFilesRecursivelyFromPath(symbPath, regex = "\.txt$")
	CHECK_WAVE(result, TEXT_WAVE)
	result[] = RemovePrefix(result[p], start = folder)
	CHECK_EQUAL_TEXTWAVES(result, {"file.txt", "b:file1.txt", "c:file2.txt"})

	WAVE/Z/T result = GetAllFilesRecursivelyFromPath(symbPath, regex = "\.txt$", resolveAliases = 1)
	CHECK_WAVE(result, TEXT_WAVE)
	result[] = RemovePrefix(result[p], start = folder)
	// alias.txt.lnk points to file.txt
	CHECK_EQUAL_TEXTWAVES(result, {"file.txt", "file.txt", "b:file1.txt", "c:file2.txt"})

	WAVE/Z/T result = GetAllFilesRecursivelyFromPath(symbPath, resolveAliases = 1)
	CHECK_WAVE(result, TEXT_WAVE)

	result[] = RemovePrefix(result[p], start = folder)
	// alias.txt.lnk points to file.txt
	CHECK_EQUAL_TEXTWAVES(result, {"file.txt", "file.txt", "b:file1.txt", "c:file2.txt"})

	// shortcut to non-existing file (created above)
	CHECK(!V_flag)
	DeleteFile/P=$symbPath "file.txt"
	CHECK(!V_flag)

	WAVE/Z/T result = GetAllFilesRecursivelyFromPath(symbPath)
	CHECK_WAVE(result, TEXT_WAVE)

	result[] = RemovePrefix(result[p], start = folder)
	// although alias.txt.lnk is invalid, we don't resolve it
	CHECK_EQUAL_TEXTWAVES(result, {"alias.txt.lnk", "b:file1.txt", "c:file2.txt"})

	WAVE/Z/T result = GetAllFilesRecursivelyFromPath(symbPath, resolveAliases = 1)
	CHECK_WAVE(result, TEXT_WAVE)

	result[] = RemovePrefix(result[p], start = folder)
	// file.txt is not included as alias.txt.lnk is invalid
	CHECK_EQUAL_TEXTWAVES(result, {"b:file1.txt", "c:file2.txt"})

	// shortcut to non-existing folder
	CreateAliasShortcut/Z/P=$symbPath/D "b" as "someFolder"
	CHECK(!V_flag)
	DeleteFolder/P=$symbPath/Z "b"
	CHECK(!V_flag)

	WAVE/Z/T result = GetAllFilesRecursivelyFromPath(symbPath)
	CHECK_WAVE(result, TEXT_WAVE)

	result[] = RemovePrefix(result[p], start = folder)
	CHECK_EQUAL_TEXTWAVES(result, {"alias.txt.lnk", "someFolder.lnk", "c:file2.txt"})

	WAVE/Z/T result = GetAllFilesRecursivelyFromPath(symbPath, resolveAliases = 1)
	CHECK_WAVE(result, TEXT_WAVE)

	result[] = RemovePrefix(result[p], start = folder)
	CHECK_EQUAL_TEXTWAVES(result, {"c:file2.txt"})

	// no matches
	WAVE/Z/T result = GetAllFilesRecursivelyFromPath(symbPath, regex = "\.abc$")
	CHECK_WAVE(result, NULL_WAVE)

	// empty directory
	symbPathSub = GetUniqueSymbolicPath()
	NewPath/Q/O/C/Z $symbPathSub, (folder + ":d")
	CHECK(!V_Flag)

	WAVE/Z/T result = GetAllFilesRecursivelyFromPath(symbPathSub, resolveAliases = 1)
	CHECK_WAVE(result, NULL_WAVE)

	KillPath $symbPath
	KillPath $symbPathSub
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

static Function TestGetSymbolicPathForDiagnosticsDirectory()

	string symbPath

	symbPath = GetSymbolicPathForDiagnosticsDirectory()
	CHECK_PROPER_STR(symbPath)

	PathInfo $symbPath
	CHECK(V_flag)
End

static Function TestResolveAlias()

	string filePath, result, folder, symbPath, cmd

	folder = GetFolder(FunctionPath("")) + "testFolder:"

	symbPath = GetUniqueSymbolicPath()
	NewPath/Q/O/C/Z $symbPath, folder
	CHECK(!V_Flag)

	CreateFolderOnDisk(folder + "b:")

	// none existing
	filePath = "I_DONT_EXIST.txt"
	result   = ResolveAlias(filePath)
	CHECK_EMPTY_STR(result)

	// plain file
	filePath = folder + "file.txt"
	SaveTextFile("", filePath)

	result = ResolveAlias(filePath)
	CHECK_EQUAL_STR(result, filePath)

	result = ResolveAlias("file.txt", pathName = symbPath)
	CHECK_EQUAL_STR(result, filePath)

	// plain folder
	result = ResolveAlias(folder)
	CHECK_EQUAL_STR(result, folder)

	// shortcut to file
	CreateAliasShortcut/Z/P=$symbPath "file.txt" as "alias.txt"
	CHECK(!V_flag)

	result   = ResolveAlias(S_path)
	filePath = folder + "file.txt"
	CHECK_EQUAL_STR(result, filePath)

	result   = ResolveAlias("alias.txt", pathName = symbPath)
	filePath = folder + "file.txt"
	CHECK_EQUAL_STR(result, filePath)

	// shortcut to folder
	CreateAliasShortcut/Z/P=$symbPath/D as "someFolder"
	CHECK(!V_flag)

	result   = ResolveAlias(S_path)
	filePath = folder
	CHECK_EQUAL_STR(result, filePath)

	result   = ResolveAlias("someFolder", pathName = symbPath)
	filePath = folder
	CHECK_EQUAL_STR(result, filePath)

	// shortcut to non-existing file
	CreateAliasShortcut/Z/P=$symbPath "file.txt" as "alias.txt"
	CHECK(!V_flag)
	DeleteFile/P=$symbPath/Z "file.txt"
	CHECK(!V_flag)

	result = ResolveAlias(S_path)
	CHECK_EMPTY_STR(result)

	result = ResolveAlias("alias.txt", pathName = symbPath)
	CHECK_EMPTY_STR(result)

	// shortcut to non-existing folder
	CreateAliasShortcut/Z/P=$symbPath/D "b" as "someFolder"
	CHECK(!V_flag)
	DeleteFolder/P=$symbPath/Z "b"
	CHECK(!V_flag)

	result = ResolveAlias(S_path)
	CHECK_EMPTY_STR(result)

	result = ResolveAlias("someFolder", pathName = symbPath)
	CHECK_EMPTY_STR(result)

	KillPath $symbPath
	CHECK_NO_RTE()
End
