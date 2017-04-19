#pragma rtGlobals=3
#pragma version=1.06
#pragma TextEncoding="UTF-8"

// Licensed under 3-Clause BSD, see License.txt

///@cond HIDDEN_SYMBOL

Constant FFNAME_OK	 = 0x00
Constant FFNAME_NOT_FOUND = 0x01
Constant FFNAME_NO_MODULE = 0x02

/// Returns the package folder
Function/DF GetPackageFolder()
	if(!DataFolderExists(PKG_FOLDER))
		NewDataFolder/O root:Packages
		NewDataFolder/O root:Packages:UnitTesting
	endif

	dfref dfr = $PKG_FOLDER
	return dfr
End

/// Returns 0 if the file exists, !0 otherwise
Function FileNotExists(fname)
	string fname

	GetFileFolderInfo/Q/Z fname
	return V_Flag
End

/// returns a non existing file name an empty string
Function/S getUnusedFileName(fname)
	string fname

	variable count
	string fn, fnext, fnn

	if (FileNotExists(fname))
		return fname
	endif
	fname = ParseFilePath(5, fname, "\\", 0, 0)
	fnext = "." + ParseFilePath(4, fname, "\\", 0, 0)
	fnn = RemoveEnding(fname, fnext)

	count = -1
	do
		count += 1
		sprintf fn, "%s_%03d%s", fnn, count, fnext
	while(!FileNotExists(fn) && count < 999)
	if(!FileNotExists(fn))
		return ""
	endif
	return fn
End

/// Returns 1 if debug output is enabled and zero otherwise
Function EnabledDebug()
	dfref dfr = GetPackageFolder()
	NVAR/Z/SDFR=dfr verbose

	if(NVAR_EXISTS(verbose) && verbose == 1)
		return 1
	endif

	return 0
End

/// Output debug string in assertions
/// @param str            debug string
/// @param booleanValue   assertion state
Function DebugOutput(str, booleanValue)
	string str
	variable booleanValue

	if(EnabledDebug())
		str += ": is " + SelectString(booleanValue, "false", "true")
		print str
	endif
End

/// Disable the Igor Pro Debugger and return its state prior to deactivation
Function DisableIgorDebugger()

	variable debuggerState

	DebuggerOptions
	debuggerState = V_enable

	DebuggerOptions enable=0

	return debuggerState
End

/// Restore the Igor Pro Debugger to its prior state
Function RestoreIgorDebugger(debuggerState)
	variable debuggerState

	DebuggerOptions enable=debuggerState
End

/// Create the variable igorDebugState in PKG_FOLDER
/// and initialize it to zero
Function InitIgorDebugState()
	DFREF dfr = GetPackageFolder()
	variable/G dfr:igor_debug_state = 0
End

/// Creates the variable global_error_count in PKG_FOLDER
/// and initializes it to zero
Function initGlobalError()
	dfref dfr = GetPackageFolder()
	variable/G dfr:global_error_count = 0
End

/// Creates the variable error_count in PKG_FOLDER
/// and initializes it to zero
Function initError()
	dfref dfr = GetPackageFolder()
	variable/G dfr:error_count = 0
End

/// Increments the error_count in PKG_FOLDER and creates it if necessary
Function incrError()
	dfref dfr = GetPackageFolder()
	NVAR/Z/SDFR=dfr error_count

	if(!NVAR_Exists(error_count))
		initError()
		NVAR/SDFR=dfr error_count
	endif

	error_count +=1
End

/// Creates the variable assert_count in PKG_FOLDER
/// and initializes it to zero
Function initAssertCount()
	dfref dfr = GetPackageFolder()
	variable/G dfr:assert_count = 0
End

/// Increments the assert_count in PKG_FOLDER and creates it if necessary
Function incrAssert()
	dfref dfr = GetPackageFolder()
	NVAR/SDFR=dfr/Z assert_count

	if(!NVAR_Exists(assert_count))
		initAssertCount()
		NVAR/SDFR=dfr assert_count
		assert_count = 0
	endif

	assert_count +=1
End

/// Prints an informative message that the test failed
Function printFailInfo()
	dfref dfr = GetPackageFolder()
	SVAR/SDFR=dfr message
	SVAR/SDFR=dfr type
	SVAR/SDFR=dfr systemErr

	message = getInfo(0)

	print message
	type = "FAIL"
	systemErr = message

	if(TAP_IsOutputEnabled())
		SVAR/SDFR=dfr tap_diagnostic
		tap_diagnostic = tap_diagnostic + message
	endif
End

/// Prints an informative message that the test succeeded
Function printSuccessInfo()
	string str_info

	str_info = getInfo(1)
	print str_info

	if(TAP_IsOutputEnabled())
		SVAR/SDFR=GetPackageFolder() tap_diagnostic
		tap_diagnostic = tap_diagnostic + str_info
	endif
End

/// Returns 1 if the abortFlag is set and zero otherwise
Function shouldDoAbort()
	NVAR/Z/SDFR=GetPackageFolder() abortFlag
	if(NVAR_Exists(abortFlag) && abortFlag == 1)
		return 1
	else
		return 0
	endif
End

/// Sets the abort flag
Function abortNow()
	dfref dfr = GetPackageFolder()
	variable/G dfr:abortFlag = 1

	Abort
End

/// Resets the abort flag
Function InitAbortFlag()
	dfref dfr = GetPackageFolder()
	variable/G dfr:abortFlag = 0
End

/// Prints an informative message about the test's success or failure
// 0 failed, 1 succeeded
static Function/S getInfo(result)
	variable result

	string caller, procedure, callStack, contents
	string text, cleanText, line
	variable numCallers, i
	variable callerIndex = NaN

	callStack = GetRTStackInfo(3)
	numCallers = ItemsInList(callStack)

	// traverse the callstack from bottom up,
	// the first function not in one of the unit testing procedures is
	// the one we want to report.
	for(i = numCallers - 1; i >= 0; i -= 1)
		caller    = StringFromList(i, callStack)
		procedure = StringFromList(1, caller, ",")

		if(StringMatch(procedure, "unit-testing*"))
			continue
		else
			callerIndex = i
			break
		endif

	endfor

	if(numtype(callerIndex) != 0)
		return "Assertion failed in unknown location"
	endif

	caller    = StringFromList(callerIndex, callStack)
	procedure = StringFromList(1, caller, ",")
	line      = StringFromList(2, caller, ",")

	contents = ProcedureText("", -1, procedure)
	text = StringFromList(str2num(line), contents, "\r")

	// remove leading and trailing whitespace
	SplitString/E="^[[:space:]]*(.+?)[[:space:]]*$" text, cleanText

	sprintf text, "Assertion \"%s\" %s in line %s, procedure \"%s\"\r", cleanText,  SelectString(result, "failed", "succeeded"), line, procedure
	return text
End

/// Groups all hooks which are executed at test case/suite begin/end
static Structure TestHooks
	string testBegin
	string testEnd
	string testSuiteBegin
	string testSuiteEnd
	string testCaseBegin
	string testCaseEnd
EndStructure

/// Sets the hooks to the builtin defaults
static Function setDefaultHooks(hooks)
	Struct TestHooks &hooks

	hooks.testBegin      = "TEST_BEGIN"
	hooks.testEnd        = "TEST_END"
	hooks.testSuiteBegin = "TEST_SUITE_BEGIN"
	hooks.testSuiteEnd   = "TEST_SUITE_END"
	hooks.testCaseBegin  = "TEST_CASE_BEGIN"
	hooks.testCaseEnd    = "TEST_CASE_END"
End

/// Check that all hook functions, default and override,
/// have the expected signature and abort if not.
static Function abortWithInvalidHooks(hooks)
	Struct TestHooks& hooks

	variable i, numEntries
	string msg

	Make/T/N=6/FREE info

	info[0] = FunctionInfo(hooks.testBegin)
	info[1] = FunctionInfo(hooks.testEnd)
	info[2] = FunctionInfo(hooks.testSuiteBegin)
	info[3] = FunctionInfo(hooks.testSuiteEnd)
	info[4] = FunctionInfo(hooks.testCaseBegin)
	info[5] = FunctionInfo(hooks.testCaseEnd)

	numEntries = DimSize(info, 0)
	for(i = 0; i < numEntries; i += 1)
		if(NumberByKey("N_PARAMS", info[i]) != 1 || NumberByKey("N_OPT_PARAMS", info[i]) != 0 || NumberByKey("PARAM_0_TYPE", info[i]) != 0x2000)
			sprintf msg, "The override test hook \"%s\" must accept exactly one string parameter.\r", StringByKey("NAME", info[i])
			Abort msg
		endif

		if(NumberByKey("RETURNTYPE", info[i]) != 0x4)
			sprintf msg, "The override test hook \"%s\" must return a numeric variable.\r", StringByKey("NAME", info[i])
			Abort msg
		endif
	endfor
End

/// Looks for global override hooks in the module ProcGlobal
static Function getGlobalHooks(hooks)
	Struct TestHooks& hooks

	string userHooks = FunctionList("*_OVERRIDE", ";", "KIND:2")

	variable i
	for(i = 0; i < ItemsInList(userHooks); i += 1)
		string userHook = StringFromList(i, userHooks)
		strswitch(userHook)
			case "TEST_BEGIN_OVERRIDE":
				hooks.testBegin = userHook
				break
			case "TEST_END_OVERRIDE":
				hooks.testEnd = userHook
				break
			case "TEST_SUITE_BEGIN_OVERRIDE":
				hooks.testSuiteBegin = userHook
				break
			case "TEST_SUITE_END_OVERRIDE":
				hooks.testSuiteEnd = userHook
				break
			case "TEST_CASE_BEGIN_OVERRIDE":
				hooks.testCaseBegin = userHook
				break
			case "TEST_CASE_END_OVERRIDE":
				hooks.testCaseEnd = userHook
				break
			default:
				// ignore unknown functions
				break
		endswitch
	endfor

	abortWithInvalidHooks(hooks)
End

/// Looks for local override hooks in a specific procedure file
static Function getLocalHooks(hooks, procName)
	string procName
	Struct TestHooks& hooks

	variable err
	string userHooks = FunctionList("*_OVERRIDE", ";", "KIND:18,WIN:" + procName)

	variable i
	for(i = 0; i < ItemsInList(userHooks); i += 1)
		string userHook = StringFromList(i, userHooks)

		string fullFunctionName = getFullFunctionName(err, userHook, procName)
		strswitch(userHook)
			case "TEST_SUITE_BEGIN_OVERRIDE":
				hooks.testSuiteBegin = fullFunctionName
				break
			case "TEST_SUITE_END_OVERRIDE":
				hooks.testSuiteEnd = fullFunctionName
				break
			case "TEST_CASE_BEGIN_OVERRIDE":
				hooks.testCaseBegin = fullFunctionName
				break
			case "TEST_CASE_END_OVERRIDE":
				hooks.testCaseEnd = fullFunctionName
				break
			default:
				// ignore unknown functions
				break
		endswitch
	endfor

	abortWithInvalidHooks(hooks)
End

/// Returns the full name of a function including its module
/// @param   &err	returns 0 for no error, 1 if function not found, 2 is static function in proc without ModuleName
static Function/S getFullFunctionName(err, funcName, procName)
	variable &err
	string funcName, procName

	err = FFNAME_OK
	string infoStr = FunctionInfo(funcName, procName)
	string errMsg

	if(strlen(infoStr) <= 0)
		sprintf errMsg, "Function %s in procedure file %s is unknown\r", funcName, procName
		err = FFNAME_NOT_FOUND
		return errMsg
	endif

	string module = StringByKey("MODULE", infoStr)

	if(strlen(module) <= 0)
		module = "ProcGlobal"

		// we can only use static functions if they live in a module
		if(cmpstr(StringByKey("SPECIAL", infoStr), "static") == 0)
			sprintf errMsg, "The procedure file %s is missing a \"#pragma ModuleName=myName\" declaration.\r", procName
			err = FFNAME_NO_MODULE
			return errMsg
		endif
	endif

	return module + "#" + funcName
End

/// Prototype for test cases
Function TEST_CASE_PROTO()
End

/// Prototype for run functions in autorun mode
Function AUTORUN_MODE_PROTO()
End

/// Prototype for hook functions
Function USER_HOOK_PROTO(str)
	string str
End

///@endcond // HIDDEN_SYMBOL

///@addtogroup TestRunnerAndHelper
///@{

/// Turns debug output on
Function EnableDebugOutput()
	dfref dfr = GetPackageFolder()
	variable/G dfr:verbose = 1
End

/// Turns debug output off
Function DisableDebugOutput()
	dfref dfr = GetPackageFolder()
	variable/G dfr:verbose = 0
End

///@}

///@cond HIDDEN_SYMBOL

/// Evaluates an RTE and puts a composite error message into message/type
Function EvaluateRTE(err, errmessage, abortCode, funcName, procWin)
	variable err
	string errmessage
	variable abortCode
	string funcName
	string procWin

	dfref dfr = GetPackageFolder()
	SVAR/SDFR=dfr message
	SVAR/SDFR=dfr type
	string str

	type = ""
	message = ""
	if(err)
		sprintf str, "Uncaught runtime error %d:\"%s\" in test case \"%s\", procedure file \"%s\"\r", err, errmessage, funcName, procWin
		message = str
		type = "RUNTIME ERROR"
	endif
	if(abortCode != -4)
		if(!strlen(type))
			type = "ABORT"
		endif
		str = ""
		switch(abortCode)
			case -1:
				sprintf str, "User aborted Test Run manually in test case \"%s\", procedure file \"%s\"\r", funcName, procWin
				break
			case -2:
				sprintf str, "Stack Overflow in test case \"%s\", procedure file \"%s\"\r", funcName, procWin
				break
			case -3:
				sprintf str, "Encountered \"Abort\" in test case \"%s\", procedure file \"%s\"\r", funcName, procWin
				break
			default:
				break
		endswitch
		message += str
		if(abortCode > 0)
			sprintf str, "Encountered \"AbortOnvalue\" Code %d in test case \"%s\", procedure file \"%s\"\r", abortCode, funcName, procWin
			message += str
		endif
	endif
End

/// Internal Setup for Testrun
/// @param name   name of the test suite group
Function TestBegin(name, allowDebug)
	string name
	variable allowDebug

	// we have to remember the state of debugging
	variable reEnableDebugOutput=EnabledDebug()

	KillDataFolder/Z $PKG_FOLDER
	initGlobalError()

	DFREF dfr = GetPackageFolder()

	if(reEnableDebugOutput)
		EnableDebugOutput()
	endif

	InitAbortFlag()

	if (!allowDebug)
		initIgorDebugState()
		NVAR/SDFR=dfr igor_debug_state
		igor_debug_state = DisableIgorDebugger()
	endif

	string/G dfr:message = ""
	string/G dfr:type = "0"
	string/G dfr:systemErr = ""

	ClearBaseFilename()

	printf "Start of test \"%s\"\r", name
End

/// Internal Cleanup for Testrun
/// @param name   name of the test suite group
Function TestEnd(name, allowDebug)
	string name
	variable allowDebug

	dfref dfr = GetPackageFolder()
	NVAR/SDFR=dfr global_error_count

	if(global_error_count == 0)
		printf "Test finished with no errors\r"
	else
		printf "Test finished with %d errors\r", global_error_count
	endif

	printf "End of test \"%s\"\r", name

	if (!allowDebug)
		NVAR/SDFR=dfr igor_debug_state
		RestoreIgorDebugger(igor_debug_state)
	endif
End

/// Internal Setup for Test Suite
/// @param testSuite name of the test suite
Function TestSuiteBegin(testSuite)
	string testSuite

	initError()
	printf "Entering test suite \"%s\"\r", testSuite
End

/// Internal Cleanup for Test Suite
/// @param testSuite name of the test suite
Function TestSuiteEnd(testSuite)
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

/// Internal Setup for Test Case
/// @param testCase name of the test case
Function TestCaseBegin(testCase)
	string testCase

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

/// Internal Cleanup for Test Case
/// @param testCase name of the test case
Function TestCaseEnd(testCase, keepDataFolder)
	string testCase
	variable keepDataFolder

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
	if (!keepDataFolder)
		if(SVAR_Exists(workFolder) && DataFolderExists(workFolder))
			KillDataFolder $workFolder
		endif
	endif

	printf "Leaving test case \"%s\"\r", testCase
End

/// Returns List of Test Functions in Procedure Window procWin
Function/S getTestCaseList(procWin)
	string procWin
	return (FunctionList("!*_IGNORE", ";", "KIND:18,NPARAMS:0,WIN:" + procWin))
End

/// Returns FullName List of Test Functions in all Procedure Windows from procWinList
Function/S getCompleteTestCaseList(procWinList)
	string procWinList

	string procWin
	string testCaseList
	string funcName
	string fullFuncName
	string allCaseList
	variable numpWL, numtCL
	variable err
	variable i, j

	allCaseList = ""
	numpWL = ItemsInList(procWinList)
	for(i = 0; i < numpWL; i += 1)
		procWin = StringFromList(i, procWinList)
		testCaseList = getTestCaseList(procWin)
		numtCL = ItemsInList(testCaseList)
		for(j = 0; j < numtCL; j += 1)
			funcName = StringFromList(j, testCaseList)
			fullFuncName = getFullFunctionName(err, funcName, procWin)
			allCaseList = AddListItem(fullfuncName, allCaseList, ";")
		endfor
	endfor
	return allCaseList
End

/// Returns FullName List of Test Functions in all Procedure Windows from procWinList that match ShortName Function funcName
Function/S getTestCasesMatch(procWinList, funcName)
	string procWinList
	string funcName

	string procWin
	string ffName
	string testCaseList
	variable err
	variable numpWL
	variable i

	testCaseList = ""
	numpWL = ItemsInList(procWinList)
	for(i = 0; i < numpWL; i += 1)
		procWin = StringFromList(i, procWinList)
		ffName = getFullFunctionName(err, funcName, procWin)
		if(!err)
			testCaseList = AddListItem(ffName, testCaseList, ";")
		endif
	endfor
	return testCaseList
End

///@endcond // HIDDEN_SYMBOL

///@addtogroup TestRunnerAndHelper
///@{

/// Main function to execute one or more test suites.
/// @param   procWinList   semicolon (";") separated list of procedure files
/// @param   name           (optional) descriptive name for the executed test suites
/// @param   testCase       (optional) function name, resembling one test case, which should be executed only for each test suite
/// @param   enableJU       (optional) enables JUNIT xml output when set to 1
/// @param   enableTAP      (optional) enables Test Anything Protocol (TAP) output when set to 1
/// @param   allowDebug     (optional) when set != 0 then the Debugger does not get disabled while running the tests
/// @param   keepDataFolder (optional) when set != 0 then the temporary Data Folder where the Test Case is executed in is not removed after the Test Case finishes
/// @return                 total number of errors
Function RunTest(procWinList, [name, testCase, enableJU, enableTAP, allowDebug, keepDataFolder])
	string procWinList, name, testCase
	variable enableJU, enableTAP
	variable allowDebug, keepDataFolder

	string procWin
	string allProcWindows
	string testCaseList
	string allTestCasesList
	string FuncName
	string fullFuncName
	string fullFuncNameList
	variable numItemsPW
	variable numItemsTC
	variable numItemsFFN
	variable tap_skipCase
	variable tap_caseCount
	variable tap_caseErr
	DFREF dfr = GetPackageFolder()
	string juTestSuitesOut
	string juTestCaseListOut
	STRUCT strTestSuite juTS
	STRUCT strSuiteProperties juTSProp
	STRUCT strTestCase juTC
	struct TestHooks hooks
	struct TestHooks procHooks
	variable i, j, err

	// Arguments check

	ClearBaseFilename()
	CreateHistoryLog(recreate=0)

	PathInfo home
	if(!V_flag)
		printf "Error: Please Save experiment first.\r"
		return NaN
	endif

	if(strlen(procWinList) <= 0)
		printf "Error: The list of procedure windows is empty\r"
		return NaN
	endif

	allProcWindows = WinList("*", ";", "WIN:128")

	numItemsPW = ItemsInList(procWinList)
	for(i = 0; i < numItemsPW; i += 1)
		procWin = StringFromList(i, procWinList)
		if(FindListItem(procWin, allProcWindows, ";", 0, 0) == -1)
			printf "Error: A procedure window named %s could not be found.\r", procWin
			return NaN
		endif
		testCaseList = getTestCaseList(procWin)
		numItemsTC = ItemsInList(testCaseList)
		if(!numItemsTC)
			printf "Error: Procedure window %s does not define any test case(s).\r", procWin
			return NaN
		endif
		for(j = 0; j < numItemsTC; j += 1)
			funcName = StringFromList(j, testCaseList)
			fullFuncName = getFullFunctionName(err, funcName, procWin)
			if(err)
				printf fullFuncName
				return NaN
			endif
		endfor
	endfor

	if(ParamIsDefault(name))
		name = "Unnamed"
	endif
	if(ParamIsDefault(enableJU))
		enableJU = 0
	else
		enableJU = !!enableJU
	endif
	if(ParamIsDefault(enableTAP))
		enableTAP = 0
	else
		enableTAP = !!enableTAP
	endif
	if(ParamIsDefault(allowDebug))
		allowDebug = 0
	else
		allowDebug = !!allowDebug
	endif
	if(ParamIsDefault(keepDataFolder))
		keepDataFolder = 0
	else
		keepDataFolder = !!keepDataFolder
	endif
	if(ParamIsDefault(testCase))
		allTestCasesList = getCompleteTestCaseList(procWinList)
	else
		allTestCasesList = getTestCasesMatch(procWinList, testCase)
		if(!strlen(allTestCasesList))
			printf "Error: Could not find test case \"%s\" in procedure(s) \"%s\"\r", testcase, procWinList
			return NaN
		endif
	endif

	// 1.) set the hooks to the default implementations
	setDefaultHooks(hooks)
	// 2.) get global user hooks which reside in ProcGlobal and replace the default ones
	getGlobalHooks(hooks)

	FUNCREF USER_HOOK_PROTO TestBeginUser = $hooks.testBegin
	FUNCREF USER_HOOK_PROTO TestEndUser   = $hooks.testEnd

	TestBegin(name, allowDebug)
	TestBeginUser(name)

	SVAR/SDFR=dfr message
	SVAR/SDFR=dfr type
	SVAR/SDFR=dfr systemErr
	NVAR/SDFR=dfr global_error_count

	// TAP Handling, find out if all should be skipped and number of all test cases
	if(enableTAP)
		TAP_EnableOutput()
		TAP_CreateFile()

		if(TAP_CheckAllSkip(allTestCasesList))
			TAP_WriteOutput("1..0 All test cases marked SKIP" + TAP_LINEEND_STR)
			TestEnd(name, allowDebug)
			TestEndUser(name)
			Abort
		else
			TAP_WriteOutput("1.." + num2str(ItemsInList(allTestCasesList)) + TAP_LINEEND_STR)
		endif
	endif

	tap_caseCount = 1
	juTestSuitesOut = ""

	// The Test Run itself is split into Test Suites for each Procedure File
	for(i = 0; i < numItemsPW; i += 1)
		procWin = StringFromList(i, procWinList)

		if(ParamIsDefault(testCase))
			testCaseList = getTestCaseList(procWin)
		else
			testCaseList = testCase
		endif
		fullFuncNameList = ""
		numItemsTC = ItemsInList(testCaseList)
		for(j = 0; j < numItemsTC; j += 1)
			funcName = StringFromList(j, testCaseList)
			fullFuncName = getFullFunctionName(err, funcName, procWin)
			if(!err)
				fullFuncNameList = AddListItem(fullFuncName, fullFuncNameList, ";")
			endif
		endfor
		if (!strlen(fullFuncNameList))
			continue
		endif

		procHooks = hooks
		// 3.) get local user hooks which reside in the same Module as the requested procedure
		getLocalHooks(procHooks, procWin)

		FUNCREF USER_HOOK_PROTO TestSuiteBeginUser = $procHooks.testSuiteBegin
		FUNCREF USER_HOOK_PROTO TestSuiteEndUser   = $procHooks.testSuiteEnd
		FUNCREF USER_HOOK_PROTO TestCaseBeginUser  = $procHooks.testCaseBegin
		FUNCREF USER_HOOK_PROTO TestCaseEndUser    = $procHooks.testCaseEnd

		TestSuiteBegin(procWin)
		JU_TestSuiteBegin(enableJU, juTS, juTSProp, procWin, testCaseList, name, i)
		TestSuiteBeginUser(procWin)
		juTestCaseListOut = ""

		NVAR/SDFR=dfr error_count

		numItemsFFN = ItemsInList(fullFuncNameList)
		for(j = numItemsFFN-1; j >= 0; j -= 1)
			fullFuncName = StringFromList(j, fullFuncNameList)
			FUNCREF TEST_CASE_PROTO TestCaseFunc = $fullFuncName

			// get Description and Directive of current Function for TAP
			tap_skipCase = 0
			if(TAP_IsOutputEnabled())
				tap_skipCase = TAP_GetNotes(fullFuncName)
				TAP_InitDiagnosticBuffer()
			endif

			if(!tap_skipCase)
				tap_caseErr = error_count

				JU_TestCaseBegin(enableJU, juTC, fullfuncName, fullfuncName, procWin)
				TestCaseBegin(fullFuncName)
				TestCaseBeginUser(fullFuncName)

				systemErr = ""

				try
					TestCaseFunc(); AbortOnRTE
				catch
					// only complain here if the error counter if the abort happened not in our code
					if(!shouldDoAbort())
						message = GetRTErrMessage()
						err = GetRTError(1)
						EvaluateRTE(err, message, V_AbortCode, fullFuncName, procWin)
						printf message
						systemErr = message
						if(TAP_IsOutputEnabled())
							SVAR/SDFR=dfr tap_diagnostic
							tap_diagnostic += message
						endif
						incrError()
					endif
				endtry

				TestCaseEnd(fullFuncName, keepDataFolder)
				juTestCaseListOut += JU_TestCaseEnd(enableJU, juTS, juTC, fullFuncName, procWin)
				TestCaseEndUser(fullFuncName)
				tap_caseErr -= error_count
			endif

			if(shouldDoAbort())
				TAP_WriteOutputIfReq("Bail out!" + TAP_LINEEND_STR)
				break
			endif
			TAP_WriteCaseIfReq(tap_caseCount, tap_skipCase, tap_caseErr)
			tap_caseCount += 1

		endfor

		TestSuiteEnd(procWin)
		juTestSuitesOut += JU_TestSuiteEnd(enableJU, juTS, juTSProp, juTestCaseListOut)
		TestSuiteEndUser(procWin)
		if(shouldDoAbort())
			break
		endif

	endfor
	JU_WriteOutput(enableJU, juTestSuitesOut, "JU_" + GetBaseFilename() + ".xml")

	TestEnd(name, allowDebug)
	TestEndUser(name)

	return global_error_count
End

///@}
