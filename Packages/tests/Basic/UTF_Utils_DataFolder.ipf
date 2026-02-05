#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_DATAFOLDER

static Constant CDFWAP_MAX_PATH_DEPTH     = 5
static Constant TEST_LONG_BASENAME_LENGTH = 100
static Constant TEST_CHAR_A_UPPERCASE     = 0x41

/// GetListOfObjects
/// @{

// This cuts away the temporary folder in which the tests runs
Function/S TrimVolatileFolderName_IGNORE(string list)

	variable pos, i, numEntries
	string str
	string result = ""

	if(isEmpty(list))
		return list
	endif

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		str = StringFromList(i, list)

		pos = strsearch(str, ":test", 0)

		if(pos >= 0)
			str = str[pos, Inf]
		endif

		result = AddListItem(str, result, ";", Inf)
	endfor

	return result
End

Function GetListOfObjectsWorksRE()

	string result, expected

	NewDataFolder test

	DFREF dfr = $"test"
	Make dfr:abcd
	Make dfr:efgh

	result   = GetListOfObjects(dfr, "a.*", recursive = 0, fullpath = 0)
	result   = TrimVolatileFolderName_IGNORE(result)
	expected = "abcd;"
	CHECK_EQUAL_STR(result, expected)

	result   = GetListOfObjects(dfr, "a.*", recursive = 1, fullpath = 0)
	result   = TrimVolatileFolderName_IGNORE(result)
	expected = "abcd;"
	CHECK_EQUAL_STR(result, expected)

	result   = GetListOfObjects(dfr, "a.*", recursive = 1, fullpath = 1)
	result   = TrimVolatileFolderName_IGNORE(result)
	expected = ":test:abcd;"
	CHECK_EQUAL_STR(result, expected)

	result   = GetListOfObjects(dfr, "a.*", recursive = 0, fullpath = 1)
	result   = TrimVolatileFolderName_IGNORE(result)
	expected = ":test:abcd;"
	CHECK_EQUAL_STR(result, expected)

	KillDataFolder/Z test
End

Function GetListOfObjectsWorksWC()

	string result, expected

	NewDataFolder test
	DFREF dfr = $"test"
	Make dfr:abcd
	Make dfr:efgh

	result   = GetListOfObjects(dfr, "a*", recursive = 0, fullpath = 0, exprType = MATCH_WILDCARD)
	result   = TrimVolatileFolderName_IGNORE(result)
	expected = "abcd;"
	CHECK_EQUAL_STR(result, expected)

	result   = GetListOfObjects(dfr, "a*", recursive = 1, fullpath = 0, exprType = MATCH_WILDCARD)
	result   = TrimVolatileFolderName_IGNORE(result)
	expected = "abcd;"
	CHECK_EQUAL_STR(result, expected)

	result   = GetListOfObjects(dfr, "a*", recursive = 1, fullpath = 1, exprType = MATCH_WILDCARD)
	result   = TrimVolatileFolderName_IGNORE(result)
	expected = ":test:abcd;"
	CHECK_EQUAL_STR(result, expected)

	result   = GetListOfObjects(dfr, "a*", recursive = 0, fullpath = 1, exprType = MATCH_WILDCARD)
	result   = TrimVolatileFolderName_IGNORE(result)
	expected = ":test:abcd;"
	CHECK_EQUAL_STR(result, expected)

	KillDataFolder/Z test
End

Function GetListOfObjectsWorks2()

	string result, expected

	NewDataFolder test
	NewDataFolder :test:test2

	DFREF dfr = $":test"
	CHECK(DataFolderExistsDFR(dfr))

	Make dfr:wv1
	Make dfr:wv2

	DFREF dfrDeep = $":test:test2"
	CHECK(DataFolderExistsDFR(dfrDeep))

	Make dfrDeep:wv3
	Make dfrDeep:wv4

	result   = GetListOfObjects(dfr, ".*", recursive = 0, fullpath = 0)
	result   = TrimVolatileFolderName_IGNORE(result)
	expected = "wv1;wv2;"
	CHECK_EQUAL_STR(result, expected)

	result   = GetListOfObjects(dfr, ".*", recursive = 1, fullpath = 0)
	result   = TrimVolatileFolderName_IGNORE(result)
	expected = "wv1;wv2;wv3;wv4"
	// sort order is implementation defined
	result   = SortList(result)
	expected = SortList(expected)
	CHECK_EQUAL_STR(result, expected)

	result   = GetListOfObjects(dfr, ".*", recursive = 1, fullpath = 1)
	result   = TrimVolatileFolderName_IGNORE(result)
	expected = ":test:wv1;:test:wv2;:test:test2:wv3;:test:test2:wv4;"
	// sort order is implementation defined
	result   = SortList(result)
	expected = SortList(expected)
	CHECK_EQUAL_STR(result, expected)

	result   = GetListOfObjects(dfr, ".*", recursive = 0, fullpath = 1)
	result   = TrimVolatileFolderName_IGNORE(result)
	expected = ":test:wv1;:test:wv2;"
	CHECK_EQUAL_STR(result, expected)

	KillDataFolder/Z test
End

// IUTF_TD_GENERATOR w0:DataGenerators#CountObjectTypeFlags
Function GetListOfObjectsWorksTypeFlag([STRUCT IUTF_mData &md])

	string result, expected, expectedRec
	variable type

	NewDataFolder test
	NewDataFolder :test:test2
	NewDataFolder :test:test2:test3

	type        = WaveRef(md.w0, row = 0)[0]
	expected    = WaveText(WaveRef(md.w0, row = 1), row = 0)
	expectedRec = WaveText(WaveRef(md.w0, row = 2), row = 0)

	DFREF dfr = $":test"
	CHECK(DataFolderExistsDFR(dfr))

	Make dfr:wv1
	Make dfr:wv2
	variable/G   dfr:var1
	variable/C/G dfr:var2
	string/G     dfr:str1

	DFREF dfrDeep = $":test:test2"
	CHECK(DataFolderExistsDFR(dfrDeep))

	Make dfrDeep:wv3
	Make dfrDeep:wv4
	variable/G   dfrDeep:var3
	variable/C/G dfrDeep:var4
	string/G     dfrDeep:str2

	result = GetListOfObjects(dfr, ".*", recursive = 0, typeFlag = type)
	CHECK_EQUAL_STR(result, expected)

	result = GetListOfObjects(dfr, ".*", recursive = 1, typeFlag = type)
	// sort order is implementation defined
	result      = SortList(result)
	expectedRec = SortList(expectedRec)
	CHECK_EQUAL_STR(result, expectedRec)

	KillDataFolder/Z test
End

Function GetListOfObjectsWorksWithFolder()

	string result, expected

	NewDataFolder test1
	NewDataFolder :test1:test2
	NewDataFolder :test1:test2:test3

	DFREF dfr = $":test1"
	CHECK(DataFolderExistsDFR(dfr))

	DFREF dfrDeep = $":test1:test2"
	CHECK(DataFolderExistsDFR(dfrDeep))

	result   = GetListOfObjects(dfr, ".*", recursive = 0, fullpath = 0, typeFlag = COUNTOBJECTS_DATAFOLDER)
	expected = "test2"
	result   = SortList(result)
	expected = SortList(expected)
	CHECK_EQUAL_STR(result, expected)

	result   = GetListOfObjects(dfr, ".*", recursive = 1, fullpath = 0, typeFlag = COUNTOBJECTS_DATAFOLDER)
	expected = "test2;test3"
	result   = SortList(result)
	expected = SortList(expected)
	CHECK_EQUAL_STR(result, expected)

	result   = GetListOfObjects(dfr, ".*", recursive = 1, fullpath = 1, typeFlag = COUNTOBJECTS_DATAFOLDER)
	result   = TrimVolatileFolderName_IGNORE(result)
	expected = ":test1:test2;:test1:test2:test3"
	result   = SortList(result)
	expected = SortList(expected)
	CHECK_EQUAL_STR(result, expected)

	KillDataFolder/Z test1
End

static Function GetListOfObjectsWorksWithFreeDF()

	string result, expected

	DFREF dfr = NewFreeDataFolder()

	NewDataFolder dfr:SubFolder1
	DFREF dfr1 = dfr:SubFolder1
	Make dfr1:wave1

	NewDataFolder dfr1:SubFolder2
	DFREF dfr2 = dfr1:SubFolder2
	Make dfr2:wave2

	result = GetListOfObjects(dfr, ".*", recursive = 1, fullpath = 0, typeFlag = COUNTOBJECTS_WAVES)

	expected = "wave1;wave2;"
	result   = SortList(result)
	expected = SortList(expected)
	CHECK_EQUAL_STR(result, expected)

	result = GetListOfObjects(dfr, ".*", recursive = 1, fullpath = 1, typeFlag = COUNTOBJECTS_WAVES)

	expected = "SubFolder1:wave1;SubFolder1:SubFolder2:wave2;"
	result   = SortList(result)
	expected = SortList(expected)
	CHECK_EQUAL_STR(result, expected)
End

/// @}

/// DataFolderExistsDFR
/// @{

static Structure dfrTest
	DFREF structDFR
EndStructure

Function DFED_WorksRegular1()

	STRUCT dfrTest s
	Make/FREE/DF/N=1 wDfr

	NewDataFolder test
	DFREF dfr = test
	s.structDFR = test
	wDfr[0]     = test

	CHECK(DataFolderExistsDFR(dfr))
	CHECK(DataFolderExistsDFR(s.structDFR))
	CHECK(DataFolderExistsDFR(wDfr[0]))

	KillDataFolder/Z test
End

Function DFED_WorksRegular2()

	STRUCT dfrTest s
	Make/FREE/DF/N=1 wDfr

	NewDataFolder test
	DFREF dfr = test
	s.structDFR = test
	wDfr[0]     = test

	NewDataFolder test1
	MoveDataFolder test, test1

	CHECK(DataFolderExistsDFR(dfr))
	CHECK(DataFolderExistsDFR(s.structDFR))
	CHECK(DataFolderExistsDFR(wDfr[0]))

	KillDataFolder/Z test
	KillDataFolder/Z test1
End

Function DFED_WorksRegular3()

	STRUCT dfrTest s
	Make/FREE/DF/N=1 wDfr

	DFREF dfr = NewFreeDataFolder()
	s.structDFR = dfr
	wDfr[0]     = dfr

	NewDataFolder test
	MoveDataFolder dfr, test

	CHECK(DataFolderExistsDFR(dfr))
	CHECK(DataFolderExistsDFR(s.structDFR))
	CHECK(DataFolderExistsDFR(wDfr[0]))

	KillDataFolder/Z test
End

Function DFED_WorksRegular4()

	STRUCT dfrTest s
	Make/FREE/DF/N=1 wDfr

	DFREF dfr = NewFreeDataFolder()
	s.structDFR = dfr
	wDfr[0]     = dfr

	RenameDataFolder dfr, test1234

	CHECK(DataFolderExistsDFR(dfr))
	CHECK(DataFolderExistsDFR(s.structDFR))
	CHECK(DataFolderExistsDFR(wDfr[0]))
End

Function DFED_FailsRegular1()

	STRUCT dfrTest s
	Make/FREE/DF/N=1 wDfr

	DFREF dfr = $""
	s.structDFR = $""
	wDfr[0]     = $""

	CHECK(!DataFolderExistsDFR(dfr))
	CHECK(!DataFolderExistsDFR(s.structDFR))
	CHECK(!DataFolderExistsDFR(wDfr[0]))
End

Function DFED_FailsRegular2()

	STRUCT dfrTest s
	Make/FREE/DF/N=1 wDfr

	NewDataFolder test

	DFREF dfr = test
	s.structDFR = test
	wDfr[0]     = test

	KillDataFolder test

	CHECK(!DataFolderExistsDFR(dfr))
	CHECK(!DataFolderExistsDFR(s.structDFR))
	CHECK(!DataFolderExistsDFR(wDfr[0]))
End

Function DFED_FailsRegular3()

	DFREF dfr = NewFreeDataFolder()
	Make/DF/N=1 dfr:wDfr/WAVE=wDfr
	wDfr[0] = dfr
	CHECK(DataFolderExistsDFR(wDfr[0]))

	dfr = NewFreeDataFolder()
	CHECK(DataFolderExistsDFR(wDfr[0]))

	dfr = GetWavesDataFolderDFR(wDfr)
	CHECK(DataFolderExistsDFR(dfr))

	wDfr[0] = root:

	dfr = GetWavesDataFolderDFR(wDfr)
	CHECK(DataFolderExistsDFR(dfr))

	dfr = NewFreeDataFolder()
	dfr = GetWavesDataFolderDFR(wDfr)
	CHECK(!DataFolderExistsDFR(dfr))
End

/// @}

/// IsGlobalDataFolder
/// @{

static Function IGDF_Test1()

	DFREF dfr = NewFreeDataFolder()
	CHECK(!IsGlobalDatafolder(dfr))

	DFREF dfr = root:
	CHECK(IsGlobalDatafolder(dfr))

	DFREF dfr = $""
	CHECK(!IsGlobalDatafolder(dfr))
End

/// @}

/// IsFreeDataFolder
/// @{

static Function IFDF_Test1()

	DFREF dfr = NewFreeDataFolder()
	CHECK(IsFreeDatafolder(dfr))

	DFREF dfr = root:
	CHECK(!IsFreeDatafolder(dfr))

	DFREF dfr = $""
	CHECK(!IsFreeDatafolder(dfr))
End

/// @}

/// RemoveAllEmptyDataFolders
/// @{

Function RemoveAllEmpty_init_IGNORE()

	NewDataFolder/O root:removeMe
	NewDataFolder/O root:removeMe:X1
	NewDataFolder/O root:removeMe:X2
	NewDataFolder/O root:removeMe:X3
	NewDataFolder/O root:removeMe:X4
	NewDataFolder/O root:removeMe:X4:data
	NewDataFolder/O root:removeMe:X5
	variable/G root:removeMe:X5:data
	NewDataFolder/O root:removeMe:X6
	string/G root:removeMe:X6:data
	NewDataFolder/O root:removeMe:X7
	Make/O root:removeMe:X7:data
	NewDataFolder/O root:removeMe:X8
	NewDataFolder/O root:removeMe:X8:Y8
	NewDataFolder/O root:removeMe:X8:Y8:Z8
End

Function RemoveAllEmpty_Works1()

	RemoveAllEmptyDataFolders($"")
	PASS()
End

Function RemoveAllEmpty_Works2()

	DFREF dfr = NewFreeDataFolder()
	RemoveAllEmptyDataFolders(dfr)
	PASS()
End

Function RemoveAllEmpty_Works3()

	NewDataFolder ttest
	string folder = GetDataFolder(1) + "ttest"
	RemoveAllEmptyDataFolders($folder)
	CHECK(!DataFolderExists(folder))
End

Function RemoveAllEmpty_Works4()

	RemoveAllEmpty_init_IGNORE()

	DFREF dfr = root:removeMe
	RemoveAllEmptyDataFolders(dfr)
	CHECK_EQUAL_VAR(CountObjectsDFR(dfr, COUNTOBJECTS_DATAFOLDER), 3)
End

/// @}

// RenameDataFolderToUniqueName
/// @{

Function RDFU_Works()

	string name, suffix, path

	name   = "I_DONT_EXIST"
	suffix = "DONT_CARE"

	CHECK(!DataFolderExists(name))
	RenameDataFolderToUniqueName(name, suffix)
	CHECK(!DataFolderExists(name))

	name   = "folder"
	suffix = "_old"

	NewDataFolder $name
	path = GetDataFolder(1) + name
	CHECK(DataFolderExists(path))
	RenameDataFolderToUniqueName(path, suffix)
	CHECK(!DataFolderExists(path))
	CHECK(DataFolderExists(path + suffix))

	KillDataFolder $(path + suffix)
End

/// @}

// DFREFClear
/// @{

Function DC_DFREFClear_Perm_Works()

	NewDataFolder/O test
	DFREF dfr = :test
	CHECK(DataFolderExistsDFR(dfr))
	DFREFClear(dfr)
	CHECK(!DataFolderExistsDFR(dfr))

	KillDataFolder/Z test
End

Function DC_DFREFClear_Free_Works()

	DFREF dfr = NewFreeDataFolder()
	CHECK(DataFolderExistsDFR(dfr))
	DFREFClear(dfr)
	CHECK(!DataFolderExistsDFR(dfr))
End

/// @}

/// createDFWithAllParents
/// @{

Function CDFWAP_CreatesSimplePath()

	string path
	DFREF  dfr

	path = "root:test1"
	dfr  = createDFWithAllParents(path)
	CHECK(DataFolderExistsDFR(dfr))
	CHECK(DataFolderExists(path))

	KillDataFolder/Z test1
End

Function CDFWAP_CreatesDeepPath()

	string path
	DFREF  dfr

	path = "root:test1:test2:test3"
	dfr  = createDFWithAllParents(path)
	CHECK(DataFolderExistsDFR(dfr))
	CHECK(DataFolderExists(path))
	CHECK(DataFolderExists("root:test1"))
	CHECK(DataFolderExists("root:test1:test2"))

	KillDataFolder/Z test1
End

Function CDFWAP_ReturnsExistingFolder()

	string path
	DFREF dfr, dfrExisting

	path = "root:test1:test2"

	NewDataFolder/O root:test1
	NewDataFolder/O root:test1:test2

	dfrExisting = $path
	dfr         = createDFWithAllParents(path)

	CHECK(DataFolderExistsDFR(dfr))
	CHECK(DataFolderExists(path))
	CHECK_EQUAL_VAR(DataFolderRefsEqual(dfr, dfrExisting), 1)

	KillDataFolder/Z test1
End

Function CDFWAP_CreatesPartialPath()

	string path
	DFREF  dfr

	NewDataFolder/O root:existing

	path = "root:existing:newFolder:deepFolder"
	dfr  = createDFWithAllParents(path)

	CHECK(DataFolderExistsDFR(dfr))
	CHECK(DataFolderExists(path))
	CHECK(DataFolderExists("root:existing:newFolder"))

	KillDataFolder/Z existing
End

Function CDFWAP_HandlesRootFolder()

	string path
	DFREF  dfr

	path = "root:"
	dfr  = createDFWithAllParents(path)

	CHECK(DataFolderExistsDFR(dfr))
	CHECK_EQUAL_VAR(DataFolderRefsEqual(dfr, root:), 1)
End

static Function CDFWAP_AssertsInvalidName()

	string path
	DFREF  dfr

	try
		path = "root:invalid name:test"
		dfr  = createDFWithAllParents(path)
		FAIL()
	catch
		PASS()
	endtry
End

Function CDFWAP_HandlesLongPaths()

	string path, component
	variable i
	DFREF    dfr

	path = "root:"
	for(i = 0; i < CDFWAP_MAX_PATH_DEPTH; i += 1)
		component = "folder" + num2str(i)
		path     += component + ":"
	endfor

	path = RemoveEnding(path, ":")
	dfr  = createDFWithAllParents(path)

	CHECK(DataFolderExistsDFR(dfr))
	CHECK(DataFolderExists(path))

	KillDataFolder/Z folder0
End

/// @}

/// RemoveEmptyDataFolder
/// @{

Function REDF_RemovesEmptyFolder()

	variable result

	NewDataFolder test
	DFREF dfr = test

	result = RemoveEmptyDataFolder(dfr)
	CHECK_EQUAL_VAR(result, 1)
	CHECK(!DataFolderExists("test"))
End

Function REDF_DoesNotRemoveNonEmpty()

	variable result

	NewDataFolder test
	DFREF dfr = test
	Make dfr:wave1

	result = RemoveEmptyDataFolder(dfr)
	CHECK_EQUAL_VAR(result, 0)
	CHECK(DataFolderExists("test"))

	KillDataFolder/Z test
End

Function REDF_HandlesNonExistentFolder()

	variable result
	DFREF dfr = $""

	result = RemoveEmptyDataFolder(dfr)
	CHECK_EQUAL_VAR(result, 0)
End

Function REDF_HandlesKilledFolder()

	variable result

	NewDataFolder test
	DFREF dfr = test
	KillDataFolder test

	result = RemoveEmptyDataFolder(dfr)
	CHECK_EQUAL_VAR(result, 0)
End

Function REDF_DoesNotRemoveWithVariable()

	variable result

	NewDataFolder test
	DFREF dfr = test
	variable/G dfr:var1

	result = RemoveEmptyDataFolder(dfr)
	CHECK_EQUAL_VAR(result, 0)
	CHECK(DataFolderExists("test"))

	KillDataFolder/Z test
End

Function REDF_DoesNotRemoveWithString()

	variable result

	NewDataFolder test
	DFREF dfr = test
	string/G dfr:str1

	result = RemoveEmptyDataFolder(dfr)
	CHECK_EQUAL_VAR(result, 0)
	CHECK(DataFolderExists("test"))

	KillDataFolder/Z test
End

Function REDF_DoesNotRemoveWithSubfolder()

	variable result

	NewDataFolder test
	DFREF dfr = test
	NewDataFolder :test:subfolder

	result = RemoveEmptyDataFolder(dfr)
	CHECK_EQUAL_VAR(result, 0)
	CHECK(DataFolderExists("test"))

	KillDataFolder/Z test
End

/// @}

/// IsDataFolderEmpty
/// @{

Function IDFE_ReturnsTrueForEmpty()

	variable result

	NewDataFolder test
	DFREF dfr = test

	result = IsDataFolderEmpty(dfr)
	CHECK_EQUAL_VAR(result, 1)

	KillDataFolder/Z test
End

Function IDFE_ReturnsFalseWithWave()

	variable result

	NewDataFolder test
	DFREF dfr = test
	Make dfr:wave1

	result = IsDataFolderEmpty(dfr)
	CHECK_EQUAL_VAR(result, 0)

	KillDataFolder/Z test
End

Function IDFE_ReturnsFalseWithVariable()

	variable result

	NewDataFolder test
	DFREF dfr = test
	variable/G dfr:var1

	result = IsDataFolderEmpty(dfr)
	CHECK_EQUAL_VAR(result, 0)

	KillDataFolder/Z test
End

Function IDFE_ReturnsFalseWithString()

	variable result

	NewDataFolder test
	DFREF dfr = test
	string/G dfr:str1

	result = IsDataFolderEmpty(dfr)
	CHECK_EQUAL_VAR(result, 0)

	KillDataFolder/Z test
End

Function IDFE_ReturnsFalseWithSubfolder()

	variable result

	NewDataFolder test
	DFREF dfr = test
	NewDataFolder :test:subfolder

	result = IsDataFolderEmpty(dfr)
	CHECK_EQUAL_VAR(result, 0)

	KillDataFolder/Z test
End

static Function IDFE_AssertsNonExistent()

	variable result

	try
		DFREF dfr = $""
		result = IsDataFolderEmpty(dfr)
		FAIL()
	catch
		PASS()
	endtry
End

Function IDFE_ReturnsFalseWithMultipleObjects()

	variable result

	NewDataFolder test
	DFREF dfr = test
	Make dfr:wave1
	variable/G dfr:var1
	string/G   dfr:str1
	NewDataFolder :test:subfolder

	result = IsDataFolderEmpty(dfr)
	CHECK_EQUAL_VAR(result, 0)

	KillDataFolder/Z test
End

/// @}

/// UniqueDataFolder
/// @{

Function UDF_CreatesUniqueFolder()

	string path
	DFREF dfr, dfrNew

	NewDataFolder test
	dfr = test

	dfrNew = UniqueDataFolder(dfr, "myFolder")
	CHECK(DataFolderExistsDFR(dfrNew))

	path = GetDataFolder(1, dfrNew)
	CHECK(GrepString(path, "myFolder"))

	KillDataFolder/Z test
End

Function UDF_CreatesSecondWhenFirstExists()

	string path1, path2
	DFREF dfr, dfrNew1, dfrNew2

	NewDataFolder test
	dfr = test

	NewDataFolder :test:myFolder
	dfrNew1 = :test:myFolder

	dfrNew2 = UniqueDataFolder(dfr, "myFolder")
	CHECK(DataFolderExistsDFR(dfrNew2))
	CHECK(!DataFolderRefsEqual(dfrNew1, dfrNew2))

	path1 = GetDataFolder(1, dfrNew1)
	path2 = GetDataFolder(1, dfrNew2)
	CHECK_NEQ_STR(path1, path2)

	KillDataFolder/Z test
End

Function UDF_CreatesInRoot()

	DFREF dfr, dfrNew

	dfr    = root:
	dfrNew = UniqueDataFolder(dfr, "testFolder")

	CHECK(DataFolderExistsDFR(dfrNew))

	KillDataFolder dfrNew
End

Function UDF_HandlesLongBaseName()

	string baseName
	DFREF dfr, dfrNew

	NewDataFolder test
	dfr = test

	baseName = PadString("", TEST_LONG_BASENAME_LENGTH, TEST_CHAR_A_UPPERCASE)
	dfrNew   = UniqueDataFolder(dfr, baseName)

	CHECK(DataFolderExistsDFR(dfrNew))

	KillDataFolder/Z test
End

Function UDF_CreatesMultipleUnique()

	variable i
	DFREF    dfr
	Make/FREE/DF/N=3 folders

	NewDataFolder test
	dfr = test

	for(i = 0; i < 3; i += 1)
		folders[i] = UniqueDataFolder(dfr, "folder")
		CHECK(DataFolderExistsDFR(folders[i]))
	endfor

	CHECK(!DataFolderRefsEqual(folders[0], folders[1]))
	CHECK(!DataFolderRefsEqual(folders[1], folders[2]))
	CHECK(!DataFolderRefsEqual(folders[0], folders[2]))

	KillDataFolder/Z test
End

/// @}

/// UniqueDataFolderName
/// @{

Function UDFN_ReturnsUniqueNameSimple()

	string path
	DFREF  dfr

	NewDataFolder test
	dfr = test

	path = UniqueDataFolderName(dfr, "myFolder")
	CHECK(!isEmpty(path))
	CHECK(GrepString(path, "myFolder"))
	CHECK(!DataFolderExists(path))

	KillDataFolder/Z test
End

Function UDFN_ReturnsSecondWhenFirstExists()

	string path1, path2
	DFREF dfr

	NewDataFolder test
	dfr = :test

	NewDataFolder :test:myFolder

	path1 = GetDataFolder(1, :test:myFolder)
	path2 = UniqueDataFolderName(dfr, "myFolder")

	CHECK(!isEmpty(path2))
	CHECK_NEQ_STR(path1, path2)
	CHECK(!DataFolderExists(path2))
	CHECK(GrepString(path2, "myFolder"))

	KillDataFolder/Z test
End

Function UDFN_ReturnsAbsolutePath()

	string path
	DFREF  dfr

	NewDataFolder test
	dfr = test

	path = UniqueDataFolderName(dfr, "myFolder")
	CHECK(!isEmpty(path))
	CHECK(GrepString(path, "^root:"))

	KillDataFolder/Z test
End

static Function UDFN_AssertsEmptyBaseName()

	string path

	try
		NewDataFolder test
		DFREF dfr = test
		path = UniqueDataFolderName(dfr, "")
		FAIL()
	catch
		PASS()
	endtry

	KillDataFolder/Z test
End

static Function UDFN_AssertsNonExistentDFR()

	string path

	try
		DFREF dfr = $""
		path = UniqueDataFolderName(dfr, "test")
		FAIL()
	catch
		PASS()
	endtry
End

static Function UDFN_AssertsFreeDF()

	string path

	try
		DFREF dfr = NewFreeDataFolder()
		path = UniqueDataFolderName(dfr, "test")
		FAIL()
	catch
		PASS()
	endtry
End

Function UDFN_HandlesLongBaseName()

	string baseName, path
	DFREF dfr

	NewDataFolder test
	dfr = test

	baseName = PadString("", TEST_LONG_BASENAME_LENGTH, TEST_CHAR_A_UPPERCASE)
	path     = UniqueDataFolderName(dfr, baseName)

	CHECK(!isEmpty(path))
	CHECK(!DataFolderExists(path))

	KillDataFolder/Z test
End

Function UDFN_ConsecutiveCallsReturnDifferent()

	string path1, path2
	DFREF dfr

	NewDataFolder test
	dfr = test

	path1 = UniqueDataFolderName(dfr, "folder")
	NewDataFolder $path1

	path2 = UniqueDataFolderName(dfr, "folder")

	CHECK_NEQ_STR(path1, path2)
	CHECK(!DataFolderExists(path2))

	KillDataFolder/Z test
End

/// @}

/// RefCounterDFIncrease
/// @{

Function RCDFI_IncreasesRefCount()

	string refPath
	variable refCountBefore, refCountAfter
	DFREF dfr

	NewDataFolder test
	dfr = test

	refPath = GetDFReferenceCount(dfr)
	NVAR rc = $refPath
	refCountBefore = rc

	RefCounterDFIncrease(dfr)

	refCountAfter = rc

	CHECK_EQUAL_VAR(refCountAfter, refCountBefore + 1)

	KillDataFolder/Z test
End

Function RCDFI_IncreasesFromZero()

	string   refPath
	variable refCountAfter
	DFREF    dfr

	NewDataFolder test
	dfr = test

	refPath = GetDFReferenceCount(dfr)

	RefCounterDFIncrease(dfr)

	NVAR rc = $refPath
	refCountAfter = rc

	CHECK_EQUAL_VAR(refCountAfter, 1)

	KillDataFolder/Z test
End

Function RCDFI_AllowsMultipleIncreases()

	string refPath
	variable i, refCountFinal
	DFREF dfr

	NewDataFolder test
	dfr = test

	refPath = GetDFReferenceCount(dfr)

	for(i = 0; i < 5; i += 1)
		RefCounterDFIncrease(dfr)
	endfor

	NVAR rc = $refPath
	refCountFinal = rc

	CHECK_EQUAL_VAR(refCountFinal, 5)

	KillDataFolder/Z test
End

Function RCDFI_WorksWithDifferentFolders()

	string refPath1, refPath2
	variable refCount1, refCount2
	DFREF dfr1, dfr2

	NewDataFolder test1
	NewDataFolder test2
	dfr1 = test1
	dfr2 = test2

	refPath1 = GetDFReferenceCount(dfr1)
	refPath2 = GetDFReferenceCount(dfr2)

	RefCounterDFIncrease(dfr1)
	RefCounterDFIncrease(dfr1)
	RefCounterDFIncrease(dfr2)

	NVAR rc1 = $refPath1
	NVAR rc2 = $refPath2
	refCount1 = rc1
	refCount2 = rc2

	CHECK_EQUAL_VAR(refCount1, 2)
	CHECK_EQUAL_VAR(refCount2, 1)

	KillDataFolder/Z test1
	KillDataFolder/Z test2
End

/// @}

/// RefCounterDFDecrease
/// @{

Function RCDFD_DecreasesRefCount()

	string refPath
	variable refCountBefore, refCountAfter
	DFREF dfr

	NewDataFolder test
	dfr = test

	refPath = GetDFReferenceCount(dfr)

	RefCounterDFIncrease(dfr)
	RefCounterDFIncrease(dfr)

	NVAR rc = $refPath
	refCountBefore = rc

	RefCounterDFDecrease(dfr)

	refCountAfter = rc

	CHECK_EQUAL_VAR(refCountAfter, refCountBefore - 1)

	KillDataFolder/Z test
End

Function RCDFD_AllowsMultipleDecreases()

	string refPath
	variable i, refCountFinal
	DFREF dfr

	NewDataFolder test
	dfr = test

	refPath = GetDFReferenceCount(dfr)

	for(i = 0; i < 5; i += 1)
		RefCounterDFIncrease(dfr)
	endfor

	for(i = 0; i < 3; i += 1)
		RefCounterDFDecrease(dfr)
	endfor

	NVAR rc = $refPath
	refCountFinal = rc

	CHECK_EQUAL_VAR(refCountFinal, 2)

	KillDataFolder/Z test
End

Function RCDFD_KillsFolderAtZero()

	string path
	DFREF  dfr

	NewDataFolder test
	path = GetDataFolder(1) + "test"
	dfr  = test

	RefCounterDFIncrease(dfr)
	CHECK(DataFolderExists(path))

	RefCounterDFDecrease(dfr)
	CHECK(!DataFolderExists(path))
End

Function RCDFD_WorksWithDifferentFolders()

	string refPath1, refPath2, path1, path2
	variable refCount1, refCount2
	DFREF dfr1, dfr2

	NewDataFolder test1
	NewDataFolder test2
	dfr1  = test1
	dfr2  = test2
	path1 = GetDataFolder(1) + "test1"
	path2 = GetDataFolder(1) + "test2"

	refPath1 = GetDFReferenceCount(dfr1)
	refPath2 = GetDFReferenceCount(dfr2)

	RefCounterDFIncrease(dfr1)
	RefCounterDFIncrease(dfr1)
	RefCounterDFIncrease(dfr2)

	RefCounterDFDecrease(dfr1)

	CHECK(DataFolderExists(path1))
	CHECK(DataFolderExists(path2))

	NVAR rc1 = $refPath1
	NVAR rc2 = $refPath2
	refCount1 = rc1
	refCount2 = rc2

	CHECK_EQUAL_VAR(refCount1, 1)
	CHECK_EQUAL_VAR(refCount2, 1)

	KillDataFolder/Z test1
	KillDataFolder/Z test2
End

Function RCDFD_HandlesDecreaseToZero()

	string refPath
	DFREF  dfr

	NewDataFolder test
	dfr = test

	refPath = GetDFReferenceCount(dfr)

	RefCounterDFIncrease(dfr)
	RefCounterDFIncrease(dfr)
	RefCounterDFDecrease(dfr)
	RefCounterDFDecrease(dfr)

	CHECK(!DataFolderExists("test"))
End

/// @}
