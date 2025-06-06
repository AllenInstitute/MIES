#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_SETTINGS

/// GetSettingsJSONid
/// @{

Function GSJIWorks()

	NVAR/Z jsonID = $GetSettingsJSONid()
	CHECK(NVAR_Exists(jsonID))
	CHECK(JSON_Exists(jsonID, ""))
End

Function GSJIWorksWithCorruptID()

	NVAR/Z jsonID = $GetSettingsJSONid()
	CHECK(NVAR_Exists(jsonID))

	// close the JSON document to fake an invalid ID
	JSON_Release(jsonID)

	// fetching again now returns a valid ID again
	NVAR/Z jsonID = $GetSettingsJSONid()
	CHECK(NVAR_Exists(jsonID))
	CHECK(JSON_Exists(jsonID, ""))
End

/// @}
