#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = ForeignFunctionTests

static Function TestMessageFilters()

	string wvNote

	WAVE/Z/T filters = FFI_GetAvailableMessageFilters()
	CHECK_WAVE(filters, FREE_WAVE | TEXT_WAVE)
	CHECK_GT_VAR(DimSize(filters, ROWS), 0)

	wvNote = note(filters)

	CHECK_PROPER_STR(wvNote)
End

static Function TestLogbookQuery()

	string key, keyTxT, device

	device        = "ITC16USB_0_DEV"
	[key, keyTxt] = PrepareLBN_IGNORE(device)

	WAVE/Z settings = FFI_QueryLogbook(device, LBT_LABNOTEBOOK, 0, key, DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, NUMERIC_WAVE)

	WAVE/Z settings = FFI_QueryLogbook(device, LBT_LABNOTEBOOK, 0, keyTxt, DATA_ACQUISITION_MODE)
	CHECK_WAVE(settings, TEXT_WAVE)
End

static Function TestLogbookQueryUnique()

	string key, keyTxT, device

	device        = "ITC16USB_0_DEV"
	[key, keyTxt] = PrepareLBN_IGNORE(device)

	WAVE/Z settings = FFI_QueryLogbookUniqueSetting(device, LBT_LABNOTEBOOK, key)
	CHECK_WAVE(settings, NUMERIC_WAVE)

	WAVE/Z settings = FFI_QueryLogbookUniqueSetting(device, LBT_LABNOTEBOOK, keyTxt)
	CHECK_WAVE(settings, TEXT_WAVE)
End

static Function TestPsxExport()

	string win, winTitle, filepath, baseFolder, datafolder
	variable ref

	CHECK_WAVE(FFI_GetSweepBrowserTitles(), NULL_WAVE)

	SB_OpenSweepBrowser()

	winTitle = "Browser"
	CHECK_EQUAL_TEXTWAVES(FFI_GetSweepBrowserTitles(), {winTitle})

	PathInfo home
	baseFolder = S_path
	filepath   = baseFolder + "someFile.h5"
	DeleteFile/Z filepath

	// no psx folders
	try
		FFI_SavePSXDataFolderToHDF5(filepath, winTitle)
		FAIL()
	catch
		CHECK_NO_RTE()
		CHECK(!FileExists(filepath))
	endtry

	// create psx folder
	win        = AB_GetSweepBrowserWindowFromTitle(winTitle)
	datafolder = GetDataFolder(1, SFH_GetWorkingDF(win)) + "psx"
	NewDataFolder $datafolder

	// file already exists (taking the experiment here)
	filepath = baseFolder + IgorInfo(12)
	try
		FFI_SavePSXDataFolderToHDF5(filepath, winTitle)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// store a wave
	DFREF dfr = $datafolder
	Make dfr:data/WAVE=data = p

	filepath = baseFolder + "someFile.h5"
	FFI_SavePSXDataFolderToHDF5(filepath, winTitle)

	ref = H5_Openfile(filepath)
	WAVE/Z read_data = H5_LoadDataset(ref, "/sweepBrowser/FormulaData/psx/data")
	CHECK_EQUAL_WAVES(data, read_data)
	H5_CloseFile(ref)
End
