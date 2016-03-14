#pragma TextEncoding = "UTF-8"		// For details execute DisplayHelpTopic "The TextEncoding Pragma"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function GetDimLabelVsCtrlInfo(win)
	string win
	string CtrlList = GetUniqueCtrlList(controlNameList(win))
	variable ctrlCount = itemsInList(CtrlList)
	print "ctrl count:", ctrlCount
	variable i, dimIndex, value
	WAVE GuiState = GetDA_EphysGuiStateNum(win)
	Variable timerRefNum
	Variable microSeconds
	Variable n
	timerRefNum = startMSTimer
	if (timerRefNum == -1)
		Abort "All timers are in use"
	endif

	for(i=0; i<ctrlCount; i+=1)
	value = GuiState[0][%$stringFromList(i, ctrlList)]
	endfor

	microSeconds = stopMSTimer(timerRefNum)
	Print microSeconds/1000/ctrlCount, "milliseconds for dimLabelSearch"

	timerRefNum = startMSTimer
	if (timerRefNum == -1)
		Abort "All timers are in use"
	endif

	for(i=0; i<=ctrlCount; i+=1)
		controlInfo/W=$win $stringFromList(i, ctrlList)
	endfor

	microSeconds = stopMSTimer(timerRefNum)
	Print microSeconds/1000/ctrlCount, "milliseconds for controlInfo"
End
