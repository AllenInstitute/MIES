#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Menu "Mies Panels"
		"DA_Ephys", execute "DA_Ephys()"
		"WaveBuilder", WB_InitiateWaveBuilder()
		"Data Browser", execute "DataBrowser()"
		"Initiate Mies", IM_InitiateMies()		
		"Close Mies", CloseMies()
End

Function CloseMies()
		
	string activeWindows = winlist("!*.*", ";", "")
	Variable index
	Variable noOfActiveWindows = itemsinlist(activeWindows, ";")

	for (index = 0; index < noOfActiveWindows;index += 1)
		string windowToClose = stringfromlist(index, activeWindows, ";")
		KillWindow windowToClose
		if (stringmatch(windowToClose, "waveBuilder") == 1)
			KillWindow waveBuilder
		elseif (stringmatch(windowToClose, "dataBrowser") == 1)
			KillWindow dataBrowser
		elseif(stringmatch(windowToClose, "DB_*") == 1)		// The data browser window title changes to display wave data
			print "killing", windowToClose
			KillWindow windowToClose
		elseif (stringmatch(windowToClose, "DA_Ephys") == 1)
			KillWindow DA_Ephys
		elseif (stringmatch(windowToClose, "ITC*") == 1)
			print "Unlocking device..."
			HSU_UnlockDevSelection(windowToClose)
			// unlocking the device changes the window title back to DA_Ephys
			KillWindow DA_Ephys
		endif
	endfor
	
	print "exiting Mies..."
End
	