#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_MIES_SETTINGS

Function TestLIMSCredentialHandling()

	Make/T/FREE=1/N=3 entries
	SetDimensionLabels(entries, "a;b;c", ROWS)

	entries[] = num2str(p)

	StoreLIMSCredentials(entries)

	WAVE/Z/T results = QueryLIMSCredentials()
	CHECK_EQUAL_TEXTWAVES(entries, results)
End
