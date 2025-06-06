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
