#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=DatabrowserChannelCheckboxes

/// UTF_TD_GENERATOR GetHistoricDataFiles
static Function TestChannelCheckboxes([string str])

	string abWin, sweepBrowsers, file, bsPanel, sbWin
	variable jsonId

	file = "input:" + str

	[abWin, sweepBrowsers] = OpenAnalysisBrowser({file}, loadSweeps = 1)
	sbWin = StringFromList(0, sweepBrowsers)
	CHECK_PROPER_STR(sbWin)
	bsPanel = BSP_GetPanel(sbWin)

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_ADC", val = 0)
	CHECK_NO_RTE()
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_ADC", val = 1)
	CHECK_NO_RTE()
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_ADC", val = 0)
	CHECK_NO_RTE()

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DAC", val = 0)
	CHECK_NO_RTE()
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DAC", val = 1)
	CHECK_NO_RTE()
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DAC", val = 0)
	CHECK_NO_RTE()

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_TTL", val = 0)
	CHECK_NO_RTE()
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_TTL", val = 1)
	CHECK_NO_RTE()
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_TTL", val = 0)
	CHECK_NO_RTE()

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_TTL", val = 1)
	CHECK_NO_RTE()
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_splitTTL", val = 0)
	CHECK_NO_RTE()
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_splitTTL", val = 1)
	CHECK_NO_RTE()
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_splitTTL", val = 0)
	CHECK_NO_RTE()

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_DAC", val = 1)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_ADC", val = 1)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_TTL", val = 1)

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_VisEpochs", val = 0)
	CHECK_NO_RTE()
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_VisEpochs", val = 1)
	CHECK_NO_RTE()
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_VisEpochs", val = 0)
	CHECK_NO_RTE()

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_splitTTL", val = 1)
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_VisEpochs", val = 1)
	CHECK_NO_RTE()
	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_VisEpochs", val = 0)
	CHECK_NO_RTE()
End
