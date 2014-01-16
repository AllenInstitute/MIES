#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function InitiateMIES()
	WB_InitiateWaveBuilder()
	execute "ITC_Ephys_panel()"
	execute "DataBrowser()"
End