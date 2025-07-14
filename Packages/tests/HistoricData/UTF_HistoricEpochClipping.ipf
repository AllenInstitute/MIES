#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = HistoricEochClipping

/// UTF_TD_GENERATOR HistoricDataHelpers#GetHistoricDataFiles
static Function TestEpochClipping([string str])

	string abWin, sweepBrowsers, file, bsPanel, sbWin
	variable jsonId

	file = "input:" + str

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file}, loadSweeps = 1)
	sbWin                  = StringFromList(0, sweepBrowsers)
	CHECK_PROPER_STR(sbWin)
	bsPanel = BSP_GetPanel(sbWin)

	jsonId = MIES_SF#SF_FormulaParser("data(select(selrange(\"Stimset;\"), selchannels(AD), selsweeps()))")
	CHECK_NEQ_VAR(jsonId, NaN)
	WAVE/WAVE result = MIES_SF#SF_FormulaExecutor(sbWin, jsonId)
	JSON_Release(jsonId)
End
