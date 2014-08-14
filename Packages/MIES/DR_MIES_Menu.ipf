#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Menu "Mies Panels"
		"DA_Ephys", execute "DA_Ephys()"
		"WaveBuilder", WB_InitiateWaveBuilder()
		"Data Browser", execute "DataBrowser()"
		"Initiate Mies", IM_InitiateMies()		
		"Close Mies", CloseMies()
		"Open Downsample Panel", CreateDownsamplePanel()
		"Start Polling WSE queue", StartTestTask()
		"Stop Polling WSE queue", StopTestTask()
End

Function CloseMies()

	DAP_UnlockAllDevices()

	string windowToClose
	string activeWindows = WinList("*", ";", "WIN:64")
	Variable index
	Variable noOfActiveWindows = ItemsInList(activeWindows)

	print "Closing Mies windows..."

	for (index = 0; index < noOfActiveWindows;index += 1)
		windowToClose = StringFromList(index, activeWindows)
		if ( StringMatch(windowToClose, "waveBuilder*") || StringMatch(windowToClose, "dataBrowser*") || StringMatch(windowToClose, "DB_ITC*") || StringMatch(windowToClose, "DA_Ephys*") )
			KillWindow $windowToClose
		endif
	endfor

	print "Exiting Mies..."
End
