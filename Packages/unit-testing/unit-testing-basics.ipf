#pragma rtGlobals=3
#pragma version=1.03

// Author: Thomas Braun (c) 2015
// Email: thomas dot braun at byte-physics dott de

///@cond HIDDEN_SYMBOL

/// Returns the package folder
Function/DF GetPackageFolder()
	if( !DataFolderExists(PKG_FOLDER) )
		NewDataFolder/O root:Packages
		NewDataFolder/O root:Packages:UnitTesting
	endif

	dfref dfr = $PKG_FOLDER
	return dfr
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
		str += ": is " + SelectString(booleanValue,"false","true")
		print str
	endif
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
	print getInfo(0)
End

/// Prints an informative message that the test succeeded
Function printSuccessInfo()
	print getInfo(1)
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

/// Prints an informative message about the test's success or failure
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

	contents = ProcedureText("",-1,procedure)
	text = StringFromList(str2num(line), contents, "\r")

	// remove leading and trailing whitespace
	SplitString/E="^[[:space:]]*(.+?)[[:space:]]*$" text, cleanText

	sprintf text, "Assertion \"%s\" %s in line %s, procedure \"%s\"\r", cleanText,  SelectString(result,"failed","suceeded"), line, procedure
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

/// Looks for global override hooks in the module ProcGlobal
static Function getGlobalHooks(hooks)
	Struct TestHooks& hooks

	string userHooks = FunctionList("*_OVERRIDE",";","KIND:2,NPARAMS:1")

	variable i
	for(i = 0; i < ItemsInList(userHooks); i+=1)
		string userHook = StringFromList(i,userHooks)
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
End

/// Looks for local override hooks in a specific procedure file
static Function getLocalHooks(hooks, procName)
	string procName
	Struct TestHooks& hooks

	string userHooks = FunctionList("*_OVERRIDE", ";", "KIND:18,NPARAMS:1,WIN:" + procName)

	variable i
	for(i = 0; i < ItemsInList(userHooks); i+=1)
		string userHook = StringFromList(i,userHooks)

		string fullFunctionName = getFullFunctionName(userHook, procName)
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
End

/// Returns the full name of a function including its module
static Function/S getFullFunctionName(funcName, procName)
	string funcName, procName

	string infoStr = FunctionInfo(funcName, procName)
	string errMsg

	if(strlen(infoStr) <= 0)
		sprintf errMsg, "Function %s in procedure file %s is unknown\r", funcName, procName
		Abort errMsg
	endif

	string module = StringByKey("MODULE", infoStr)

	if(strlen(module) <= 0 )
		module = "ProcGlobal"

		// we can only use static functions if they live in a module
		if( cmpstr(StringByKey("SPECIAL",infoStr),"static") == 0 )
			sprintf errMsg, "The procedure file %s is missing a \"#pragma ModuleName=myName\" declaration.\r", procName
			Abort errMsg
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

/// Main function to execute one or more test suites.
/// @param   procWinList 	 semicolon (";") separated list of procedure files
/// @param   name      	   (optional) descriptive name for the executed test suites
/// @param   testCase      (optional) function name, resembling one test case, which should be executed only
/// @return                total number of errors
Function RunTest(procWinList, [name, testCase])
	string procWinList, testCase, name

	if(strlen(procWinList) <= 0)
		printf "The list of procedure windows is empty\r"
		return NaN
	endif

	variable i, j, err

	string allProcWindows = WinList("*",";","WIN:128")

	for(i = 0; i < ItemsInList(procWinList); i+=1)
		string procWin = StringFromList(i, procWinList)
		if(FindListItem(procWin, allProcWindows) == -1)
			printf "A procedure window named %s could not be found.\r", procWin
			return NaN
		endif
	endfor

	if(ParamIsDefault(name))
		name = "Unnamed"
	endif

	struct TestHooks hooks
	// 1.) set the hooks to the default implementations
	setDefaultHooks(hooks)
	// 2.) get global user hooks which reside in ProcGlobal and replace the default ones
	getGlobalHooks(hooks)

	FUNCREF USER_HOOK_PROTO testBegin = $hooks.testBegin
	FUNCREF USER_HOOK_PROTO testEnd   = $hooks.testEnd

	testBegin(name)

	variable abortNow = 0
	for(i = 0; i < ItemsInList(procWinList); i+=1)

		procWin = StringFromList(i, procWinList)

		string testCaseList
		if(ParamIsDefault(testCase))
			// 18 == 16 (static function) or 2 (userdefined functions)
			testCaseList = FunctionList("!*_IGNORE",";","KIND:18,NPARAMS:0,WIN:" + procWin)
		else
			testCaseList = testCase
		endif

		struct TestHooks procHooks
		procHooks = hooks
		// 3.) get local user hooks which reside in the same Module as the requested procedure
		getLocalHooks(procHooks, procWin)

		FUNCREF USER_HOOK_PROTO testSuiteBegin = $procHooks.testSuiteBegin
		FUNCREF USER_HOOK_PROTO testSuiteEnd   = $procHooks.testSuiteEnd
		FUNCREF USER_HOOK_PROTO testCaseBegin  = $procHooks.testCaseBegin
		FUNCREF USER_HOOK_PROTO testCaseEnd    = $procHooks.testCaseEnd

		testSuiteBegin(procWin)

		for(j = 0; j < ItemsInList(testCaseList); j += 1)
			string funcName = StringFromList(j,testCaseList)
			string fullFuncName = getFullFunctionName(funcName, procWin)

			FUNCREF TEST_CASE_PROTO testCaseFunc = $fullFuncName

			testCaseBegin(funcName)

			try
				testCaseFunc(); AbortOnRTE
			catch
				// only complain here if the error counter if the abort happened not in our code
				if(!shouldDoAbort())
					printf "Uncaught runtime error \"%s\" in test case \"%s\", procedure \"%s\"\r", GetRTErrMessage(), funcName, procWin
					err = GetRTError(1)
					incrError()
				endif
			endtry

			testCaseEnd(funcName)

			if( shouldDoAbort() )
				break
			endif
		endfor

		testSuiteEnd(procWin)

		if( shouldDoAbort() )
			break
		endif
	endfor

	testEnd(name)

	NVAR/SDFR=GetPackageFolder() error_count
	return error_count
End

///@}
