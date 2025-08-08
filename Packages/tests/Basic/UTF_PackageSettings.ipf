#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = TestPackageJSON

Function/S CreateFromMacro_IGNORE(string macroName)

	string panel

	Execute macroName + "()"
	panel = GetCurrentWindow()

	NVAR JSONid = $GetSettingsJSONid()
	PS_InitCoordinates(JSONid, panel, recursive = 1)

	return panel
End

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

/// UTF_TD_GENERATOR DataGenerators#GetMiesMacrosWithCoordinateSaving
static Function TestWindowCoordinateSaving([string str])

	string panel
	variable newTop, newLeft

	panel = CreateFromMacro_IGNORE(str)
	DoUpdate

	GetWindow $panel, wsize

	newLeft = 100
	newTop  = 200

	MoveWindow/W=$panel newLeft, newTop, -1, -1

	KillWindow $panel
	DoUpdate

	panel = CreateFromMacro_IGNORE(str)
	DoUpdate

	GetWindow $panel, wsize

	REQUIRE_CLOSE_VAR(newTop, V_top, tol = 1e-1)
	REQUIRE_CLOSE_VAR(newLeft, V_left, tol = 1e-1)
End
