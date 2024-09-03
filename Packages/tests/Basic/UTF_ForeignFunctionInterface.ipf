#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=ForeignFunctionTests

static Function TestMessageFilters()

	string wvNote

	WAVE/T/Z filters = FFI_GetAvailableMessageFilters()
	CHECK_WAVE(filters, FREE_WAVE | TEXT_WAVE)
	CHECK_GT_VAR(DimSize(filters, ROWS), 0)

	wvNote = note(filters)

	CHECK_PROPER_STR(wvNote)
End
