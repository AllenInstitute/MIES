#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DP
#endif

/// @file MIES_DebugPanel.ipf
///
/// @brief __DP__ Holds the debug panel

static StrConstant PANEL = "DP_DebugPanel"

Function DP_DebuggingEnabledForFile(file)
	string file

	if(!WindowExists(PANEL))
		return 1
	endif

	WAVE/T listWave  = GetDebugPanelListWave()
	WAVE listSelWave = GetDebugPanelListSelWave()

	FindValue/TXOP=4/TEXT=file listWave
	ASSERT(V_Value != -1, "Invalid filename")

	return listSelWave[V_Value] & LISTBOX_CHECKBOX_SELECTED
End

Function DP_DebuggingEnabledForCaller()

	string stacktrace, callerInfo, callerFile
	variable numEntries

	stacktrace = GetRTStackInfo(3)

	numEntries = ItemsInList(stacktrace)
	ASSERT(numEntries >= 2, "Can not deduce calling function")

	callerInfo = StringFromList(numEntries - 2, stacktrace)
	callerFile = StringFromList(1, callerInfo, ",")
	ASSERT(!IsEmpty(callerFile), "Missing caller file")

	return DP_DebuggingEnabledForFile(callerFile)
End

Function/S DP_OpenDebugPanel()

	variable debugMode

	DoWindow/F $PANEL
	if(V_Flag)
		return panel
	endif

	Execute PANEL + "()"
	DP_FillDebugPanelWaves()

	WAVE/T listWave  = GetDebugPanelListWave()
	WAVE listSelWave = GetDebugPanelListSelWave()
	ListBox listbox_mies_files win=$PANEL, listWave=listWave, selWave=listSelWave

	debugMode = QuerySetIgorOption("DEBUGGING_ENABLED", globalSymbol = 1)
	SetCheckBoxState(PANEL, "check_debug_mode",  debugMode == 1)
	// we can't readout the ITC XOP debugging state

	return panel
End

Window DP_DebugPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(230,184,625,648)
	SetDrawLayer UserBack
	CheckBox check_itc_xop_debug_mode,pos={254.00,11.00},size={121.00,15.00},proc=DP_CheckProc_Debug,title="ITC XOP Debugging"
	CheckBox check_itc_xop_debug_mode,userdata(ResizeControlsInfo)= A"!!,H9!!#;=!!#@V!!#<(z!!#o2B4uAezzzzzzzzzzzzzz!!#o2B4uAezz"
	CheckBox check_itc_xop_debug_mode,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_itc_xop_debug_mode,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	CheckBox check_itc_xop_debug_mode,value= 0
	CheckBox check_debug_mode,pos={20.00,11.00},size={74.00,15.00},proc=DP_CheckProc_Debug,title="Debugging"
	CheckBox check_debug_mode,userdata(ResizeControlsInfo)= A"!!,BY!!#;=!!#?M!!#<(z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	CheckBox check_debug_mode,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	CheckBox check_debug_mode,userdata(ResizeControlsInfo) += A"zzz!!#u:Du]k<zzzzzzzzzzzzzz!!!"
	CheckBox check_debug_mode,value= 1
	ListBox listbox_mies_files,pos={19.00,33.00},size={356.00,411.00}
	ListBox listbox_mies_files,userdata(ResizeControlsInfo)= A"!!,BQ!!#=g!!#Bl!!#C2J,fQL!!#](Aon\"Qzzzzzzzzzzzzzz!!#o2B4uAezz"
	ListBox listbox_mies_files,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox listbox_mies_files,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_select_files,pos={106.00,9.00},size={90.00,19.00},proc=DP_PopMenuProc_Selection,title="Selection:"
	PopupMenu popup_select_files,userdata(ResizeControlsInfo)= A"!!,F9!!#:r!!#?m!!#<Pz!!#](Aon#azzzzzzzzzzzzzz!!#](Aon#azz"
	PopupMenu popup_select_files,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	PopupMenu popup_select_files,userdata(ResizeControlsInfo) += A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	PopupMenu popup_select_files,mode=2,popvalue="All",value= #"\"- none -;All\""
	SetWindow kwTopWin,hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin,userdata(ResizeControlsInfo)= A"!!*'\"z!!#C*J,ht#zzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzzzzzzzzz!!!"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={296.25,348,inf,inf}" // sizeLimit requires Igor 7 or later
	SetWindow kwTopWin,hook(MainHook)=DP_WindowHook
EndMacro

Function DP_FillDebugPanelWaves()
	string symbPath, path, allProcFiles

	WAVE/T listWave  = GetDebugPanelListWave()
	WAVE listSelWave = GetDebugPanelListSelWave()

	symbPath = GetUniqueSymbolicPath()

	path = FunctionPath("") + ":..:"
	NewPath/Q/O $symbPath, path
	allProcFiles = GetAllFilesRecursivelyFromPath(symbPath, extension=".ipf")

	path += "..:IPNWB"
	NewPath/Q/O $symbPath, path
	allProcFiles = AddListItem(allProcFiles, GetAllFilesRecursivelyFromPath(symbPath, extension=".ipf"), "|")

	KillPath $symbPath

	WAVE/T list = ListToTextWave(allProcFiles, "|")
	// remove path components
	list = GetFile(list[p])
	// remove non mies files
	Make/FREE/T/N=0 results
	Grep/E="^(MIES|IPNWB)_.*$" list results
	// sort list
	Sort/A results, results

	Redimension/N=(DimSize(results, ROWS)) listWave, listSelWave

	listWave[]    = results[p]
	listSelWave[] = listSelWave[p] | 0x20
End

Function DP_WindowHook(s)
	STRUCT WMWinHookStruct &s

	variable debugMode

	strswitch(s.eventName)
		case "activate":
			debugMode = QuerySetIgorOption("DEBUGGING_ENABLED", globalSymbol = 1)
			SetCheckBoxState(PANEL, "check_debug_mode",  debugMode == 1)
			break
	endswitch
End

Function DP_CheckProc_Debug(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	string ctrl
	variable checked

	switch(cba.eventCode)
		case 2: // mouse up
			ctrl = cba.ctrlName
			checked = cba.checked

			if(!cmpstr(ctrl, "check_debug_mode"))
				if(checked)
					EnableDebugMode()
				else
					DisableDebugMode()
				endif
			elseif(!cmpstr(ctrl, "check_itc_xop_debug_mode"))
				HW_ITC_DebugMode(checked)
			endif
			break
	endswitch

	return 0
End

Function DP_PopMenuProc_Selection(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string popStr

	switch(pa.eventCode)
		case 2: // mouse up
			popStr = pa.popStr

			WAVE listSelWave = GetDebugPanelListSelWave()

			if(!cmpstr(popStr, NONE))
				listSelWave = ClearBit(listSelWave[p], LISTBOX_CHECKBOX_SELECTED)
			elseif(!cmpstr(popStr, "All"))
				listSelWave = SetBit(listSelWave[p], LISTBOX_CHECKBOX_SELECTED)
			else
				ASSERT(0, "unknown selection")
			endif
			break
	endswitch

	return 0
End
