#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTILSTEST_DATAFOLDER

// Missing Tests for:
// createDFWithAllParents
// RemoveEmptyDataFolder
// IsDataFolderEmpty
// UniqueDataFolder
// UniqueDataFolderName
// RefCounterDFIncrease
// RefCounterDFDecrease

/// GetListOfObjects
/// @{

// This cuts away the temporary folder in which the tests runs
Function/S TrimVolatileFolderName_IGNORE(list)
	string list

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

// IUTF_TD_GENERATOR w0:CountObjectTypeFlags
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
	variable/G/C dfr:var2
	string/G     dfr:str1

	DFREF dfrDeep = $":test:test2"
	CHECK(DataFolderExistsDFR(dfrDeep))

	Make dfrDeep:wv3
	Make dfrDeep:wv4
	variable/G   dfrDeep:var3
	variable/G/C dfrDeep:var4
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
