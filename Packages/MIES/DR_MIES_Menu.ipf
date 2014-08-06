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
		
	string activeWindows = winlist("*", ";", "WIN:64")
	Variable index
	Variable noOfActiveWindows = itemsinlist(activeWindows)

	print "Closing Mies windows..."
	for (index = 0; index < noOfActiveWindows;index += 1)
		string windowToClose = stringfromlist(index, activeWindows)
		if (stringmatch(windowToClose, "waveBuilder") == 1)
			KillWindow waveBuilder
		elseif (stringmatch(windowToClose, "dataBrowser") == 1)
			KillWindow dataBrowser
		elseif(stringmatch(windowToClose, "DB_ITC*") == 1)		// The data browser window title changes to display wave data
			KillWindow $windowToClose
		elseif (stringmatch(windowToClose, "DA_Ephys") == 1)
			KillWindow DA_Ephys
		elseif (stringmatch(windowToClose, "ITC*") == 1)
			HSU_UnlockDevice(windowToClose)
			// unlocking the device changes the window title back to DA_Ephys
			KillWindow DA_Ephys
		endif
	endfor
	
	print "Exiting Mies..."
End
	