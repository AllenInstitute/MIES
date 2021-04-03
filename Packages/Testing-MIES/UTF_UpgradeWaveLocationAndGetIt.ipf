#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UpgradeWaveLocationTesting

static Function TEST_CASE_BEGIN_OVERRIDE(name)
	string name

	AdditionalExperimentCleanup()

	NewDataFolder destf
	NewDataFolder srcf

	DFREF dfr = srcf

	Make/N=1 dfr:srcw = 12345
End

Function asserts_on_invalid_1()
	STRUCT WaveLocationMod p

	try
		UpgradeWaveLocationAndGetIt(p)
		FAIL()
	catch
		PASS()
	endtry
End

Function asserts_on_invalid_2()
	STRUCT WaveLocationMod p

	p.dfr = root:

	try
		UpgradeWaveLocationAndGetIt(p)
		FAIL()
	catch
		PASS()
	endtry
End

Function asserts_on_invalid_3()
	STRUCT WaveLocationMod p

	p.name = "w"

	try
		UpgradeWaveLocationAndGetIt(p)
		FAIL()
	catch
		PASS()
	endtry
End

Function empty_wave_ref()
	STRUCT WaveLocationMod p

	p.name = "w"
	p.dfr  = root:

	WAVE/Z wv = UpgradeWaveLocationAndGetIt(p)
	CHECK_WAVE(wv, NULL_WAVE)
End

Function no_trafo()
	STRUCT WaveLocationMod p

	p.name = "srcw"
	p.dfr  = srcf

	WAVE/Z wv = UpgradeWaveLocationAndGetIt(p)
	CHECK_WAVE(wv, NUMERIC_WAVE)
	CHECK_EQUAL_VAR(wv[0], 12345)
End

Function rename_wave_only()
	STRUCT WaveLocationMod p

	string newName, name

	p.name = "srcw"
	p.dfr  = srcf

	newName = "destw"
	p.newName = newName

	WAVE/Z wv = UpgradeWaveLocationAndGetIt(p)
	CHECK_WAVE(wv, NUMERIC_WAVE)
	name = NameOfWave(wv)
	CHECK_EQUAL_STR(name, newName)
	CHECK_EQUAL_VAR(wv[0], 12345)

	CHECK(DataFolderExistsDFR(p.dfr))
End

Function rename_handles_equal_names()
	STRUCT WaveLocationMod p

	string newName, name

	p.dfr = srcf

	newName = "srcw"
	p.newName = newName
	p.name = newName

	WAVE/Z wv = UpgradeWaveLocationAndGetIt(p)
	CHECK_WAVE(wv, NUMERIC_WAVE)
	name = NameOfWave(wv)
	CHECK_EQUAL_STR(name, newName)
	CHECK_EQUAL_VAR(wv[0], 12345)

	CHECK(DataFolderExistsDFR(p.dfr))
End

Function move_wave_only()
	STRUCT WaveLocationMod p

	string folder, newFolder

	p.name = "srcw"
	p.dfr  = srcf

	newFolder = "destf"
	p.newDFR = $newFolder

	WAVE/Z wv = UpgradeWaveLocationAndGetIt(p)
	CHECK_WAVE(wv, NUMERIC_WAVE)
	folder = GetWavesDataFolder(wv, 0)
	CHECK_EQUAL_STR(folder, newFolder)
	CHECK_EQUAL_VAR(wv[0], 12345)

	CHECK(!DataFolderExistsDFR(p.dfr))
End

Function move_fails_on_non_exist_ret_src()
	STRUCT WaveLocationMod p

	string newFolder
	string folder, oldFolder

	p.name = "srcw"
	p.dfr  = srcf

	newFolder = "destf_notexist"
	p.newDFR = $newFolder

	CHECK(!DataFolderExistsDFR(p.newDFR))

	WAVE/Z wv = UpgradeWaveLocationAndGetIt(p)
	CHECK_WAVE(wv, NUMERIC_WAVE)
	folder = GetWavesDataFolder(wv, 0)
	oldFolder = "srcf"
	CHECK_EQUAL_STR(folder, oldFolder)
	CHECK_EQUAL_VAR(wv[0], 12345)

	CHECK(DataFolderExistsDFR(p.dfr))
End

Function move_handles_equal_folders()
	STRUCT WaveLocationMod p

	string folder, newFolder

	p.name = "srcw"

	newFolder = "srcf"
	p.dfr     = $newFolder
	p.newDFR  = $newFolder

	WAVE/Z wv = UpgradeWaveLocationAndGetIt(p)
	CHECK_WAVE(wv, NUMERIC_WAVE)
	folder = GetWavesDataFolder(wv, 0)
	CHECK_EQUAL_STR(folder, newFolder)
	CHECK_EQUAL_VAR(wv[0], 12345)

	CHECK(DataFolderExistsDFR(p.dfr))
End

Function move_rename_both_equal()
	STRUCT WaveLocationMod p

	string folder, newFolder
	string name, newName

	newFolder = "srcf"
	p.dfr     = $newFolder
	p.newDFR  = $newFolder

	newName   = "srcw"
	p.name    = newName
	p.newName = newName

	WAVE/Z wv = UpgradeWaveLocationAndGetIt(p)
	CHECK_WAVE(wv, NUMERIC_WAVE)
	folder = GetWavesDataFolder(wv, 0)
	CHECK_EQUAL_STR(folder, newFolder)
	CHECK_EQUAL_VAR(wv[0], 12345)

	CHECK(DataFolderExistsDFR(p.dfr))
End

Function move_rename()
	STRUCT WaveLocationMod p

	string folder, newFolder
	string name, newName

	folder    = "srcf"
	p.dfr     = srcf

	newFolder = "destf"
	p.newDFR  = $newFolder

	name      = "srcw"
	p.name    = name

	newName   = "destw"
	p.newName = newName

	WAVE/Z wv = UpgradeWaveLocationAndGetIt(p)
	CHECK_WAVE(wv, NUMERIC_WAVE)
	name = NameOfWave(wv)
	CHECK_EQUAL_STR(name, newName)
	folder = GetWavesDataFolder(wv, 0)
	CHECK_EQUAL_STR(folder, newFolder)
	CHECK_EQUAL_VAR(wv[0], 12345)

	CHECK(!DataFolderExistsDFR(p.dfr))
End

Function move_rename_keeps_dfr()
	STRUCT WaveLocationMod p

	string folder, newFolder
	string name, newName

	folder    = "srcf"
	p.dfr     = srcf

	newFolder = "destf"
	p.newDFR  = $newFolder

	name      = "srcw"
	p.name    = name

	newName   = "destw"
	p.newName = newName

	DFREF tmpDFR = p.dfr
	Make tmpDFR:tmp

	WAVE/Z wv = UpgradeWaveLocationAndGetIt(p)
	CHECK_WAVE(wv, NUMERIC_WAVE)
	name = NameOfWave(wv)
	CHECK_EQUAL_STR(name, newName)
	folder = GetWavesDataFolder(wv, 0)
	CHECK_EQUAL_STR(folder, newFolder)
	CHECK_EQUAL_VAR(wv[0], 12345)

	CHECK(DataFolderExistsDFR(p.dfr))

	WAVE/SDFR=tmpDFR src = $name
	CHECK_WAVE(src, NULL_WAVE)
End

Function return_dest_if_both_keep_src()
	STRUCT WaveLocationMod p

	string folder, newFolder
	string name, newName

	folder    = "srcf"
	p.dfr     = srcf

	newFolder = "destf"
	p.newDFR  = $newFolder

	name      = "srcw"
	p.name    = name

	newName   = "destw"
	p.newName = newName

	WAVE/SDFR=p.dfr src = $name
	DFREF tmpDFR = p.newDFR
	Duplicate src, tmpDFR:$(p.newName)/WAVE=dest

	WAVE/Z wv = UpgradeWaveLocationAndGetIt(p)
	CHECK_WAVE(wv, NUMERIC_WAVE)
	CHECK(WaveRefsEqual(wv, dest))

	WAVE/SDFR=p.dfr src = $name
	// src still exists
	CHECK_WAVE(src, NUMERIC_WAVE)

	name = NameOfWave(wv)
	CHECK_EQUAL_STR(name, newName)
	folder = GetWavesDataFolder(wv, 0)
	CHECK_EQUAL_STR(folder, newFolder)
	CHECK_EQUAL_VAR(wv[0], 12345)

	CHECK(DataFolderExistsDFR(p.dfr))
End

Function fails_on_liberal_wavename()
	STRUCT WaveLocationMod p

	p.dfr     = srcf
	p.name    = "srcw"
	p.newName = "123destw"

	try
		WAVE/Z wv = UpgradeWaveLocationAndGetIt(p); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

Function fails_on_invalid_wavename()
	STRUCT WaveLocationMod p

	p.dfr     = srcf
	p.name    = "srcw"
	p.newName = ":"

	try
		WAVE/Z wv = UpgradeWaveLocationAndGetIt(p); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End
