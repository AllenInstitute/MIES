#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = ThreadsafeDataSharingTests

static StrConstant KEY = "abcd"

static Function TEST_CASE_BEGIN_OVERRIDE(string testname)

	TestCaseBeginCommon(testname)

	TUFXOP_Clear/N=(KEY)/Q/Z
End

static Function TEST_CASE_END_OVERRIDE(string testname)

	TUFXOP_Clear/N=(KEY)/Q/Z

	TestCaseEndCommon(testname)
End

static Function ChecksParams()

	try
		TSDS_WriteVar("", 1)
		FAIL()
	catch
		PASS()
	endtry

	try
		TSDS_ReadVar("")
		FAIL()
	catch
		PASS()
	endtry
End

static Function WriteVarWorks1()

	variable var

	TSDS_WriteVar(KEY, 123)
	var = TSDS_ReadVar(KEY)
	CHECK_EQUAL_VAR(var, 123)

	TSDS_WriteVar(KEY, 567)
	var = TSDS_ReadVar(KEY)
	CHECK_EQUAL_VAR(var, 567)
End

static Function ReadVarWorks1()

	variable var

	try
		TSDS_ReadVar(KEY)
		FAIL()
	catch
		PASS()
	endtry

	TSDS_WriteVar(KEY, 123)

	var = TSDS_ReadVar(KEY)
	CHECK_EQUAL_VAR(var, 123)
End

static Function ReadVarWorksWithDefault()

	try
		TSDS_ReadVar(KEY, defValue = 567)
		FAIL()
	catch
		PASS()
	endtry
End

static Function ReadVarWorksWithDefaultAndCreate()

	variable var

	var = TSDS_ReadVar(KEY, defValue = 567, create = 1)
	CHECK_EQUAL_VAR(var, 567)

	// now it is created
	var = TSDS_ReadVar(KEY)
	CHECK_EQUAL_VAR(var, 567)
End

static Function ReadVarBrokenStorage1()

	variable var

	var = TSDS_ReadVar(KEY, defValue = 0, create = 1)
	CHECK_EQUAL_VAR(var, 0)

	// top level has the wrong size
	TUFXOP_GetStorage/N=KEY wv
	CHECK_WAVE(wv, WAVE_WAVE)

	Redimension/N=0 wv

	try
		TSDS_ReadVar(KEY)
		FAIL()
	catch
		PASS()
	endtry
End

static Function ReadVarBrokenStorage2()

	variable var

	var = TSDS_ReadVar(KEY, defValue = 0, create = 1)
	CHECK_EQUAL_VAR(var, 0)

	// contained wave is null
	TUFXOP_GetStorage/N=KEY wv
	CHECK_WAVE(wv, WAVE_WAVE)

	wv[0] = $""

	try
		TSDS_ReadVar(KEY)
		FAIL()
	catch
		PASS()
	endtry
End
