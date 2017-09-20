#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=PatchSeqTest

StrConstant DEVICE = "ITC18USB_DEV_0"
Constant HEADSTAGE = 0

Function CLEANUP_IGNORE()
	SetSetVariable(DEVICE, "SetVar_Sweep", 0)
	SWS_DeleteDataWaves(DEVICE)

	KillOrMoveToTrash(dfr=GetDevSpecLabNBFolder(DEVICE))
End

Function/WAVE GetSweepResults_IGNORE(sweepNo)
	variable sweepNo

	WAVE numericalValues = GetLBNumericalValues(DEVICE)
	WAVE/Z sweeps = AFH_GetSweepsFromSameRACycle(numericalValues, sweepNo)
	CHECK_WAVE(sweeps, NUMERIC_WAVE)

	Make/FREE/N=(DimSize(sweeps, ROWS)) sweepPassed = GetLastSettingIndep(numericalValues, sweeps[p], LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_SWEEP_PASSED, UNKNOWN_MODE)

	return sweepPassed
End

Function WaitUntilDAQDone(s)
	STRUCT WMBackgroundStruct &s

	NVAR dataAcqRunMode = $GetDataAcqRunMode(DEVICE)

	if(dataAcqRunMode == DAQ_NOT_RUNNING)
		SVAR testCase = root:testCase
		Execute/P/Q "runtest(\"PatchSeqSubThreshold-Testing.ipf\", testCase=\"" + testCase + "\")"
		return 1
	endif

	return 0
End

static Function SetupTestFunction(testFuncName)
	string testFuncName

	string/G root:testCase = testFuncName

	CtrlNamedBackGround DAQWatchdog, start, period=120, proc=WaitUntilDAQDone
End

Function Run1()

	CLEANUP_IGNORE()

	WAVE wv = CreateOverrideResults(DEVICE, HEADSTAGE)
	// all tests fail
	wv = 0

	SetupTestFunction("Test1")

	PASS()
	PGC_SetAndActivateControl(DEVICE, "DataAcquireButton")
End

Function Test1()

	variable sweepNo, setPassed

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 7)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 6)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_SET_PASSED, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 0, 0, 0, 0, 0})
End

Function Run2()

	CLEANUP_IGNORE()

	WAVE wv = CreateOverrideResults(DEVICE, HEADSTAGE)
	// only pre pulse chunk pass, others fail
	wv[]    = 0
	wv[0][] = 1

	SetupTestFunction("Test2")

	PASS()
	PGC_SetAndActivateControl(DEVICE, "DataAcquireButton")
End

Function Test2()

	variable sweepNo, setPassed

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 7)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 6)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_SET_PASSED, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 0, 0, 0, 0, 0})
End

Function Run3()

	CLEANUP_IGNORE()

	WAVE wv = CreateOverrideResults(DEVICE, HEADSTAGE)
	// pre pulse chunk pass
	// first post pulse chunk pass
	wv[]      = 0
	wv[0,1][] = 1

	SetupTestFunction("Test3")

	PASS()
	PGC_SetAndActivateControl(DEVICE, "DataAcquireButton")
End

Function Test3()

	variable sweepNo, setPassed

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_SET_PASSED, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 1})
End

Function Run4()

	CLEANUP_IGNORE()

	WAVE wv = CreateOverrideResults(DEVICE, HEADSTAGE)
	// pre pulse chunk pass
	// last post pulse chunk pass
	wv[] = 0
	wv[0][] = 1
	wv[DimSize(wv, ROWS) - 1][] = 1

	SetupTestFunction("Test4")

	PASS()
	PGC_SetAndActivateControl(DEVICE, "DataAcquireButton")
End

Function Test4()

	variable sweepNo, setPassed

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_SET_PASSED, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
	CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 1})
End

Function Run5()

	CLEANUP_IGNORE()

	WAVE wv = CreateOverrideResults(DEVICE, HEADSTAGE)
	// pre pulse chunk fails
	// all post pulse chunk pass
	wv[]    = 1
	wv[0][] = 0

	SetupTestFunction("Test5")

	PASS()
	PGC_SetAndActivateControl(DEVICE, "DataAcquireButton")
End

Function Test5()

	variable sweepNo, setPassed

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 7)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 6)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_SET_PASSED, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 0)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
		CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 0, 0, 0, 0, 0})
End

Function Run6()

	CLEANUP_IGNORE()

	WAVE wv = CreateOverrideResults(DEVICE, HEADSTAGE)
	// pre pulse chunk pass
	// second post pulse chunk pass
	wv[]    = 0
	wv[0][] = 1
	wv[2][] = 1

	SetupTestFunction("Test6")

	PASS()
	PGC_SetAndActivateControl(DEVICE, "DataAcquireButton")
End

Function Test6()

	variable sweepNo, setPassed

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 3)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 2)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_SET_PASSED, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
		CHECK_EQUAL_WAVES(sweepPassed, {1, 1, 1})
End

Function Run7()

	CLEANUP_IGNORE()

	WAVE wv = CreateOverrideResults(DEVICE, HEADSTAGE)
	// pre pulse chunk pass
	// first post pulse chunk pass
	// of sweeps 2-4
	wv[]          = 0
	wv[0, 1][2,4] = 1

	SetupTestFunction("Test7")

	PASS()
	PGC_SetAndActivateControl(DEVICE, "DataAcquireButton")
End

Function Test7()

	variable sweepNo, setPassed

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 5)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 4)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_SET_PASSED, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
		CHECK_EQUAL_WAVES(sweepPassed, {0, 0, 1, 1, 1})
End

Function Run8()

	CLEANUP_IGNORE()

	WAVE wv = CreateOverrideResults(DEVICE, HEADSTAGE)
	// pre pulse chunk pass
	// first post pulse chunk pass
	// of sweep 0, 3, 7
	wv[]        = 0
	wv[0, 1][0] = 1
	wv[0, 1][3] = 1
	wv[0, 1][7] = 1

	SetupTestFunction("Test8")

	PASS()
	PGC_SetAndActivateControl(DEVICE, "DataAcquireButton")
End

Function Test8()

	variable sweepNo, setPassed

	CHECK_EQUAL_VAR(GetSetVariable(DEVICE, "SetVar_Sweep"), 8)

	sweepNo = AFH_GetLastSweepAcquired(DEVICE)
	CHECK_EQUAL_VAR(sweepNo, 7)

	WAVE numericalValues = GetLBNumericalValues(DEVICE)

	setPassed = GetLastSettingIndep(numericalValues, sweepNo, LABNOTEBOOK_USER_PREFIX + PATCHSEQ_LBN_SET_PASSED, UNKNOWN_MODE)
	CHECK_EQUAL_VAR(setPassed, 1)

	WAVE/Z sweepPassed = GetSweepResults_IGNORE(sweepNo)
		CHECK_EQUAL_WAVES(sweepPassed, {1, 0, 0, 1, 0, 0, 0, 1})
End
