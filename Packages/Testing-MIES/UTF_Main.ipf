#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#include "MIES_include"
#include "unit-testing"

#include "UTF_AnalysisFunctionHelpers"
#include "UTF_PGCSetAndActivateControl"
#include "UTF_UpgradeWaveLocationAndGetIt"
#include "UTF_UpgradeDataFolderLocation"
#include "UTF_Utils"
#include "UTF_Labnotebook"
#include "UTF_WaveBuilder"
#include "UTF_WaveBuilderRegression"
#include "UTF_WaveVersioning"
#include "UTF_AsynFrameworkTest"
#include "UTF_SweepFormula"
#include "UTF_TraceUserData"
#include "UTF_Configuration"
#include "UTF_HelperFunctions"
#include "UTF_WaveAveraging"

Function run()
	// speeds up testing to start with a fresh copy
	KillWindow/Z HistoryCarbonCopy

	DisableDebugOutput()
	string procList = ""
	procList += "UTF_AnalysisFunctionHelpers.ipf;UTF_WaveVersioning.ipf;UTF_UpgradeWaveLocationAndGetIt.ipf;"
	procList += "UTF_Utils.ipf;UTF_Labnotebook.ipf;UTF_WaveBuilder.ipf;UTF_WaveBuilderRegression.ipf;UTF_PGCSetAndActivateControl.ipf;"
	procList += "UTF_UpgradeDataFolderLocation.ipf;UTF_AsynFrameworkTest.ipf;UTF_SweepFormula.ipf;UTF_Configuration.ipf;UTF_TraceUserData.ipf;"
	procList += "UTF_WaveAveraging.ipf"

	RunTest(procList, enableJU = 1)
End
