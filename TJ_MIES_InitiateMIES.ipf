#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function InitiateMIES()
	WB_InitiateWaveBuilder()
	execute "DA_Ephys()"
	execute "DataBrowser()"
End