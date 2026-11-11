#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_MIES_SETTINGS

static Function/WAVE GetCredentialWave()

	Make/T/FREE=1/N=3 entries
	SetDimensionLabels(entries, "a;b;c", ROWS)

	entries[] = num2str(p)

	return entries
End

static Function TestLIMSCredentialHandling()

	WAVE entries = GetCredentialWave()

	StoreLIMSCredentials(entries)

	WAVE/Z/T results = QueryLIMSCredentials()
	CHECK_EQUAL_TEXTWAVES(entries, results)
End

static Function TestLIMSCredentialValidation1()

	// empty value
	WAVE/T entries = GetCredentialWave()
	entries[1] = ""

	try
		StoreLIMSCredentials(entries)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

static Function TestLIMSCredentialValidation2()

	// empty dim label
	WAVE/T entries = GetCredentialWave()
	SetDimLabel ROWS, 2, $"", entries

	try
		StoreLIMSCredentials(entries)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End
