#pragma rtGlobals=3
#pragma version=1.03

// Author: Thomas Braun (c) 2015
// Email: thomas dot braun at byte-physics dott de

///@addtogroup HookFunctions
///@{

/// Default test begin hook.
///
/// The hook is immediately called after RunTest starts.
/// @param name   name of the test suite group
Function TEST_BEGIN(name)
	string name

	// we have to remember the state of debugging
	variable reEnableDebugOutput=EnabledDebug()

	KillDataFolder/Z $PKG_FOLDER
	initGlobalError()

	if(reEnableDebugOutput)
		EnableDebugOutput()
	endif

	printf "Start of test \"%s\"\r", name
End

/// Default test end hook.
///
/// The hook is called after all tests suites.
/// @param name   name of the test suite group
Function TEST_END(name)
	string name

	dfref dfr = GetPackageFolder()
	NVAR/SDFR=dfr global_error_count

	if(global_error_count == 0)
		printf "Test finished with no errors\r"
	else
		printf "Test finished with %d errors\r", global_error_count
	endif

	printf "End of test \"%s\"\r", name
End

/// Default hook for test suite begin.
///
/// The hook is called before executing the first test case of every test suite.
/// @param testSuite name of the test suite
Function TEST_SUITE_BEGIN(testSuite)
	string testSuite

	initError()
	printf "Entering test suite \"%s\"\r", testSuite
End

/// Default hook for test suite end.
///
/// The hook is called after executing the last test case of every test suite.
/// @param testSuite name of the test suite
Function TEST_SUITE_END(testSuite)
	string testSuite

	dfref dfr = GetPackageFolder()
	NVAR/SDFR=dfr error_count

	if(error_count == 0)
		printf "Finished with no errors\r"
	else
		printf "Failed with %d errors\r", error_count
	endif

	NVAR/SDFR=dfr global_error_count
	global_error_count += error_count

	printf "Leaving test suite \"%s\"\r", testSuite
End

/// Default hook for test case begin.
///
/// The hook is called before executing the test case.
/// @param testCase name of the test case
Function TEST_CASE_BEGIN(testCase)
	string testCase

	// kill all paths
	KillPath/A/Z

	initAssertCount()

	// create a new unique folder as working folder
	dfref dfr = GetPackageFolder()
	string/G dfr:lastFolder = GetDataFolder(1)
	SetDataFolder root:
	string/G dfr:workFolder = "root:" + UniqueName("tempFolder", 11, 0)
	SVAR/SDFR=dfr workFolder
	NewDataFolder/O/S $workFolder

	printf "Entering test case \"%s\"\r", testCase
End

/// Default hook for test case end
///
/// The hook is called after executing the test case.
/// @param testCase name of the test case
Function TEST_CASE_END(testCase)
	string testCase

	dfref dfr = GetPackageFolder()
	SVAR/Z/SDFR=dfr lastFolder
	SVAR/Z/SDFR=dfr workFolder
	NVAR/SDFR=dfr assert_count

	if(assert_count == 0)
		printf "The test case \"%s\" did not make any assertions!\r", testCase
	endif

	if(SVAR_Exists(lastFolder) && DataFolderExists(lastFolder))
		SetDataFolder $lastFolder
	endif
	if(SVAR_Exists(workFolder) && DataFolderExists(workFolder))
		KillDataFolder $workFolder
	endif

	printf "Leaving test case \"%s\"\r", testCase
End

///@}
