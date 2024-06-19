#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=HistoricAnalysisBrowser

/// UTF_TD_GENERATOR GetHistoricDataNoData
static Function TestEmptyPXP([string str])

	string file, abWin, sweepBrowsers

	file = "input:" + str

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file}, loadSweeps = 1)
	CHECK(WindowExists(abWin))
	CHECK_EMPTY_STR(sweepBrowsers)
End
