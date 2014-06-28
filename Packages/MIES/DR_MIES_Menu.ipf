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
		if (stringmatch(windowToClose, "waveBuilder") == 1)
			KillWindow waveBuilder
		elseif (stringmatch(windowToClose, "dataBrowser") == 1)
			KillWindow dataBrowser
		elseif (stringmatch(windowToClose, "DA_Ephys") == 1)
			KillWindow DA_Ephys
		elseif (stringmatch(windowToClose, "ITC*") == 1)
			KillWindow $windowToClose
		endif
	endfor
	
	print "exiting Mies..."
End
	