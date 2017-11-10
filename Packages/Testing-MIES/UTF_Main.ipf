#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "MIES_include"
#include "unit-testing"

#include "UTF_AnalysisFunctionHelpers"
#include "UTF_WaveVersioning"
#include "UTF_UpgradeWaveLocationAndGetIt"
#include "UTF_Utils"
#include "UTF_Labnotebook"
#include "UTF_WaveBuilder"

Function run()
	DisableDebugOutput()
	string procList = ""
	procList += "UTF_AnalysisFunctionHelpers.ipf;UTF_WaveVersioning.ipf;UTF_UpgradeWaveLocationAndGetIt.ipf;"
	procList += "UTF_Utils.ipf;UTF_Labnotebook.ipf;UTF_WaveBuilder.ipf"

	RunTest(procList, enableJU = 1)

	if(GetAutorunMode() == AUTORUN_PLAIN)
		Execute/P/Q "Quit/N"
	endif
End
