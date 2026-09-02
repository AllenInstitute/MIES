#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = MiesPythonTests

#if IgorVersion() < 10

static Function EmptyTestCase()

	INFO("This testsuite is IP10 only.")

	PASS()
End

#else

static Function TestLimsPythonScript()

	WAVE results = PY_FetchFilesFromLims({"fake"})
	Make/T/FREE ref = {"\\\\\\\\allen\\\\programs\\\\celltypes\\\\production\\\\mousecelltypes\\\\prod174\\\\Ephys_Roi_Result_1429085938\\\\"}
	CHECK_EQUAL_TEXTWAVES(results, ref)
End

#endif
