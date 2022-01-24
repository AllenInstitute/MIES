#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=ThreadsafeDataSharingTests

#if IgorVersion() >= 9.0

static StrConstant KEY = "abcd"

static Function TEST_CASE_BEGIN_OVERRIDE(string testname)

	AdditionalExperimentCleanup()

	TUFXOP_Clear/N=(KEY)/Q/Z
End

static Function ChecksParams()

	try
		TSDS_Write(KEY)
		FAIL()
	catch
		PASS()
	endtry

	try
		TSDS_Write("", var = 1)
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

static Function WriteWorks1()
	variable var

	TSDS_Write(KEY, var = 123)
	var = TSDS_ReadVar(KEY)
	CHECK_EQUAL_VAR(var, 123)

	TSDS_Write(KEY, var = 567)
	var = TSDS_ReadVar(KEY)
	CHECK_EQUAL_VAR(var, 567)
End

static Function ReadWorks1()
	variable var

	var = TSDS_ReadVar(KEY)
	CHECK_EQUAL_VAR(var, NaN)

	TSDS_Write(KEY, var = 123)

	var = TSDS_ReadVar(KEY)
	CHECK_EQUAL_VAR(var, 123)
End

static Function ReadWorksWithDefault()
	variable var

	var = TSDS_ReadVar(KEY, defValue = 567)
	CHECK_EQUAL_VAR(var, 567)

	// but it is still not created
	var = TSDS_ReadVar(KEY)
	CHECK_EQUAL_VAR(var, NaN)
End

static Function ReadWorksWithDefaultAndCreate()
	variable var

	var = TSDS_ReadVar(KEY, defValue = 567, create = 1)
	CHECK_EQUAL_VAR(var, 567)

	// now it is created
	var = TSDS_ReadVar(KEY)
	CHECK_EQUAL_VAR(var, 567)
End

static Function ReadBrokenStorage1()
	variable var

	var = TSDS_ReadVar(KEY, create = 1)
	CHECK_EQUAL_VAR(var, NaN)

	// top level has the wrong size
	TUFXOP_GetStorage/N=KEY wv
	CHECK_WAVE(wv, WAVE_WAVE)

	Redimension/N=0 wv

	var = TSDS_ReadVar(KEY)
	CHECK_EQUAL_VAR(var, NaN)
End

static Function ReadBrokenStorage2()
	variable var

	var = TSDS_ReadVar(KEY, create = 1)
	CHECK_EQUAL_VAR(var, NaN)

	// contained wave is null
	TUFXOP_GetStorage/N=KEY wv
	CHECK_WAVE(wv, WAVE_WAVE)

	wv[0] = $""

	var = TSDS_ReadVar(KEY)
	CHECK_EQUAL_VAR(var, NaN)
End

#else

Function NotImplemented()
	PASS()
end

#endif
