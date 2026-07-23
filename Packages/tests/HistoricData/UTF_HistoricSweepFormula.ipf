#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = HistoricDataSweepFormula

static Function TestSelectWithSeltag()

	string abWin, sweepBrowsers, sweepBrowser, str

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 0)

	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	PGC_SetAndActivateControl(abWin, "button_show_tagcontrol")

	expBrowserSel[0][0][0] = expBrowserSel[0][0][0] | LISTBOX_SELECTED
	SetSetVariableString(AB_GetTagControlName(), "setvar_tagcontrol_tagname", "myTag1")
	PGC_SetAndActivateControl(AB_GetTagControlName(), "button_tagcontrol_addtag")
	expBrowserSel[0][0][0] = expBrowserSel[0][0][0] | LISTBOX_SELECTED
	SetSetVariableString(AB_GetTagControlName(), "setvar_tagcontrol_tagname", "myTag2")
	PGC_SetAndActivateControl(AB_GetTagControlName(), "button_tagcontrol_addtag")

	sweepBrowser = LoadSweepsFromAllExperimentsFromAB(abWin)

	// select with not tags set
	str = "select(selvis(displayed))"
	WAVE/WAVE comp = SFE_ExecuteFormula(str, sweepBrowser, useVariables = 0)
	CHECK_WAVE(comp, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(comp, ROWS), 2)
	WAVE/Z dataSel = comp[0]
	CHECK_EQUAL_VAR(DimSize(dataSel, ROWS), 1)

	str = "select(selvis(all))"
	WAVE/WAVE comp = SFE_ExecuteFormula(str, sweepBrowser, useVariables = 0)
	CHECK_WAVE(comp, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(comp, ROWS), 2)
	WAVE/Z dataSel = comp[0]
	CHECK_EQUAL_VAR(DimSize(dataSel, ROWS), (98 + 78) * 2)

	// with seltag set
	str = "select(seltag([myTag1,myTag2]),selvis(displayed))"
	WAVE/WAVE comp = SFE_ExecuteFormula(str, sweepBrowser, useVariables = 0)
	CHECK_WAVE(comp, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(comp, ROWS), 2)
	WAVE/Z dataSel = comp[0]
	CHECK_EQUAL_VAR(DimSize(dataSel, ROWS), 1)

	str = "select(seltag([myTag1,myTag2]),selvis(all))"
	WAVE/WAVE comp = SFE_ExecuteFormula(str, sweepBrowser, useVariables = 0)
	CHECK_WAVE(comp, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(comp, ROWS), 2)
	WAVE/Z dataSel = comp[0]
	CHECK_EQUAL_VAR(DimSize(dataSel, ROWS), 98 * 2)

	str = "select(seltag([myTag2,myTag1]),selvis(all))"
	WAVE/WAVE comp = SFE_ExecuteFormula(str, sweepBrowser, useVariables = 0)
	CHECK_WAVE(comp, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(comp, ROWS), 2)
	WAVE/Z dataSel = comp[0]
	CHECK_EQUAL_VAR(DimSize(dataSel, ROWS), 98 * 2)

	str = "select(seltag(myTag1),selvis(all))"
	WAVE/WAVE comp = SFE_ExecuteFormula(str, sweepBrowser, useVariables = 0)
	CHECK_WAVE(comp, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(comp, ROWS), 2)
	WAVE/Z dataSel = comp[0]
	CHECK_WAVE(datasel, NULL_WAVE)

	str = "select(seltag(\"\"),selvis(all))"
	WAVE/WAVE comp = SFE_ExecuteFormula(str, sweepBrowser, useVariables = 0)
	CHECK_WAVE(comp, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(comp, ROWS), 2)
	WAVE/Z dataSel = comp[0]
	CHECK_EQUAL_VAR(DimSize(dataSel, ROWS), 78 * 2)

	str = "select(seltag(myTag1),seltag(myTag2))"
	ExecuteSweepFormulaCode(sweepBrowser, str, expectFailure = 1)
End
