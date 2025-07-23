#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = TestPackageJSON

static Function TestPackageUpgrade()

	variable jsonID, numEntries, i
	string path, group, old_name, new_name, old_path, new_path

	PathInfo home
	path = S_path + "input:OldPackageSettingsBeforeMultipleWindowSupport.json"

	INFO("json path: %s", s0 = path)

	jsonID = JSON_Load(path)
	CHECK(JSON_IsValid(jsonID))

	MIES_MIESUTILS_SETTINGS#UpgradeCoordinateSavePaths(jsonID)

	CHECK(!JSON_Exists(jsonID, "/datasweepbrowser/coordinates"))
	CHECK(JSON_Exists(jsonID, "/datasweepbrowser/DataBrowser/coordinates"))

	CHECK(!JSON_Exists(jsonID, "/wavebuilder/coordinates"))
	CHECK(JSON_Exists(jsonID, "/wavebuilder/WaveBuilder/coordinates"))

	CHECK(!JSON_Exists(jsonID, "/daephys/coordinates"))
	CHECK(JSON_Exists(jsonID, "/daephys/DA_Ephys/coordinates"))

	CHECK(!JSON_Exists(jsonID, "/analysisbrowser/coordinates"))
	CHECK(JSON_Exists(jsonID, "/analysisbrowser/AnalysisBrowser/coordinates"))

	JSON_Release(jsonID)
End

static Function TestGenerateSettingsDefault()

	variable jsonID

	jsonID = GenerateSettingsDefaults()
	CHECK(JSON_IsValid(jsonID))
End
