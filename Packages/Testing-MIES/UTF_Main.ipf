#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "MIES_include"
#include "unit-testing"

#include "UTF_AnalysisFunctionHelpers"
#include "UTF_WaveVersioning"
#include "UTF_UpgradeWaveLocationAndGetIt"
#include "UTF_Utils"
#include "UTF_Labnotebook"

Function run()
	string procList = ""
	procList += "UTF_AnalysisFunctionHelpers.ipf;UTF_WaveVersioning.ipf;UTF_UpgradeWaveLocationAndGetIt.ipf;"
	procList += "UTF_Utils.ipf;UTF_Labnotebook.ipf"

	RunTest(procList, enableJU = 1)
End
