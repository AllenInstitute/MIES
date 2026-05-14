#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = HistoricDataSweepFormula

Function TestIVSCCAPFrequency()

	string abWin, code, sweepBrowsers, sweepBrowser

	WAVE/T files = HistoricDataHelpers#GetHistoricDataFilesSweepFormulaIVSCCAPFreq()

	files[] = "input:" + files[p]

	[abWin, sweepBrowsers] = OpenAnalysisBrowser(files, loadSweeps = 1)
	sweepBrowser           = StringFromList(0, sweepBrowsers)

	code  = ""
	code += "ivscc_apfrequency(none, none, 100, 100, prepareFit(), bins2)\r"
	code += "and\r"
	code += "ivscc_apfrequency(none, none, 100, 100, prepareFit(log), bins2)\r"

	ExecuteSweepFormulaCode(sweepBrowser, code)
End
