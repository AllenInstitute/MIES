#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = GlobalStringAndVar

static Function TestCreateMiesVersionNoCache()

	string   path
	variable oldVersionDate

	path = ParseFilePath(1, FunctionPath("MIES_GLOBALS#CreateMiesVersionNoCache"), ":", 1, 2) + "version.txt"

	GetFileFolderInfo/Z/Q/UTC=1 path
	REQUIRE_EQUAL_VAR(V_flag, 0)
	oldVersionDate = V_modificationDate

	MIES_GLOBALS#CreateMiesVersionNoCache()

	GetFileFolderInfo/Z/Q/UTC=1 path
	REQUIRE_EQUAL_VAR(V_flag, 0)
	CHECK_EQUAL_VAR(oldVersionDate, V_modificationDate)
End
