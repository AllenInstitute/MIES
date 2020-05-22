#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTF_UpgradeDataLoc

static Function TEST_CASE_BEGIN_OVERRIDE(name)
	string name

	KillDataFolder/Z root:A1
	KillDataFolder/Z root:B1
	KillDataFolder/Z root:C1

	NewDataFolder/O root:A1
	NewDataFolder/O root:B1
	NewDataFolder/O root:A1:A2
	NewDataFolder/O root:B1:B2
	NewDataFolder/O root:A1:A2:A3
	NewDataFolder/O root:B1:B2:B3

	CA_FlushCache()
End

static Function TEST_CASE_END_OVERRIDE(name)
	string name

	KillDataFolder/Z root:A1
	KillDataFolder/Z root:B1
	KillDataFolder/Z root:C1
End

Function AssertsOnEmptyString1()

	try
		UpgradeDataFolderLocation("root:A1", "")
		FAIL()
	catch
		PASS()
	endtry
End

Function AssertsOnEmptyString2()

	try
		UpgradeDataFolderLocation("", "root:A2")
		FAIL()
	catch
		PASS()
	endtry
End

Function AssertsOnNonLib1()

	try
		UpgradeDataFolderLocation("", "root:2abcd")
		FAIL()
	catch
		PASS()
	endtry
End

Function AssertsOnNonLib2()

	try
		UpgradeDataFolderLocation("root:2abcd", "")
		FAIL()
	catch
		PASS()
	endtry
End

Function AssertsOnRelPath1()

	try
		UpgradeDataFolderLocation("abcd", "root:efgh")
		FAIL()
	catch
		PASS()
	endtry
End

Function AssertsOnRelPath2()

	try
		UpgradeDataFolderLocation("root:abcd", "efgh")
		FAIL()
	catch
		PASS()
	endtry
End

Function MovesSrcToNewFolder1()

	string oldFolder = "root:A1:A2"
	string newFolder   = "root:C1:C2"

	CHECK(DataFolderExists(oldFolder))
	CHECK(!DataFolderExists(newFolder))
	UpgradeDataFolderLocation(oldFolder, newFolder)
	CHECK(!DataFolderExists(oldFolder))
	CHECK(DataFolderExists(newFolder))
End

Function MovesSrcToNewFolder2()

	string oldFolder = "root:A1:A2:"
	string newFolder   = "root:C1:C2:"

	CHECK(DataFolderExists(oldFolder))
	CHECK(!DataFolderExists(newFolder))
	UpgradeDataFolderLocation(oldFolder, newFolder)
	CHECK(!DataFolderExists(oldFolder))
	CHECK(DataFolderExists(newFolder))
End

Function MovesSrcToNewFolder3()

	string oldFolder = "root:A1:A2:"
	string newFolder = "root:C1:C2:"

	CHECK(DataFolderExists(oldFolder))
	CHECK(!DataFolderExists(newFolder))
	UpgradeDataFolderLocation(oldFolder, newFolder)
	CHECK(!DataFolderExists(oldFolder))
	CHECK(DataFolderExists(newFolder))
End

Function MovesSrcToNewFolderWithRel1()

	string oldFolder = "root:A1::A1:A2" // same as root:A1:A2
	string newFolder   = "root:C1:C2"

	CHECK(DataFolderExists(oldFolder))
	CHECK(!DataFolderExists(newFolder))
	UpgradeDataFolderLocation(oldFolder, newFolder)
	CHECK(!DataFolderExists(oldFolder))
	CHECK(DataFolderExists(newFolder))
End

Function JustReturnsNewFolder1()

	string oldFolder = "root:I_DONT_EXIST"
	string newFolder   = "root:C1:C2"

	CHECK(!DataFolderExists(oldFolder))
	CHECK(!DataFolderExists(newFolder))
	UpgradeDataFolderLocation(oldFolder, newFolder)
	CHECK(!DataFolderExists(oldFolder))
	CHECK(DataFolderExists(newFolder))
End

Function ReturnsNewIfBothExist()

	string oldFolder = "root:A1:A2"
	string newFolder   = "root:B1:B2"

	CHECK(DataFolderExists(oldFolder))
	CHECK(DataFolderExists(newFolder))
	UpgradeDataFolderLocation(oldFolder, newFolder)
	CHECK(DataFolderExists(oldFolder))
	CHECK(DataFolderExists(newFolder))
End

Function DoesNotTouchOtherObjects1()

	string oldFolder, newFolder
	string new, ref

	oldFolder = "root:A1:A2"
	newFolder   = "root:B1:B2:B3:B4"

	Make root:B1:B2:B3:B4/Wave=B4

	CHECK(DataFolderExists(oldFolder))
	CHECK(!DataFolderExists(newFolder))
	UpgradeDataFolderLocation(oldFolder, newFolder)
	CHECK(!DataFolderExists(oldFolder))
	CHECK(DataFolderExists(newFolder))
	CHECK_WAVE(B4, NUMERIC_WAVE)
End

Function DoesNotTouchOtherObjects2()

	string oldFolder, newFolder
	string new, ref

	oldFolder = "root:A1:A2"
	newFolder = "root:C1:C2"

	Make root:A1:A2:A3/Wave=A3

	CHECK(DataFolderExists(oldFolder))
	CHECK(!DataFolderExists(newFolder))
	UpgradeDataFolderLocation(oldFolder, newFolder)
	CHECK(!DataFolderExists(oldFolder))
	CHECK(DataFolderExists(newFolder))
	CHECK_WAVE(A3, NUMERIC_WAVE)
	ref = newFolder + ":A3"
	new = GetWavesDataFolder(A3, 2)
	CHECK_EQUAL_STR(ref, new)
End
