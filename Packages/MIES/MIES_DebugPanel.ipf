#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_DP
#endif // AUTOMATED_TESTING

/// @file MIES_DebugPanel.ipf
///
/// @brief __DP__ Holds the debug panel

static StrConstant PANEL = "DebugPanel"

Function DP_DebuggingEnabledForFile(string file)

	if(!WindowExists(PANEL))
		return 1
	endif

	WAVE/T listWave    = GetDebugPanelListWave()
	WAVE   listSelWave = GetDebugPanelListSelWave()

	FindValue/TXOP=4/TEXT=file listWave
	if(V_Value == -1)
		// list waves are out of date
		DP_FillDebugPanelWaves()
	endif

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

	WAVE/T listWave    = GetDebugPanelListWave()
	WAVE   listSelWave = GetDebugPanelListSelWave()
	ListBox listbox_mies_files, win=$PANEL, listWave=listWave, selWave=listSelWave

	debugMode = QuerySetIgorOption("DEBUGGING_ENABLED", globalSymbol = 1)
	SetCheckBoxState(PANEL, "check_debug_mode", debugMode == 1)
	// we can't readout the ITC XOP debugging state

	return panel
End

static Function DP_FillDebugPanelWaves()

	string symbPath, path, allProcFiles

	WAVE/T listWave    = GetDebugPanelListWave()
	WAVE   listSelWave = GetDebugPanelListSelWave()

	symbPath = GetUniqueSymbolicPath()

	path = FunctionPath("") + "::"
	NewPath/Q/O $symbPath, path
	allProcFiles = GetAllFilesRecursivelyFromPath(symbPath, extension = ".ipf")

	path += ":IPNWB"
	NewPath/Q/O $symbPath, path
	allProcFiles = AddListItem(allProcFiles, GetAllFilesRecursivelyFromPath(symbPath, extension = ".ipf"), FILE_LIST_SEP)

	KillPath $symbPath

	WAVE/T list = ListToTextWave(allProcFiles, FILE_LIST_SEP)
	// remove path components
	list = GetFile(list[p])
	// remove non mies files
	Make/FREE/T/N=0 results
	Grep/E="^(MIES|IPNWB)_.*$" list as results
	// sort list
	Sort/A results, results

	Redimension/N=(DimSize(results, ROWS)) listWave, listSelWave

	listWave[]    = results[p]
	listSelWave[] = listSelWave[p] | 0x20
End

Function DP_WindowHook(STRUCT WMWinHookStruct &s)

	variable debugMode

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_ACTIVATE:
			debugMode = QuerySetIgorOption("DEBUGGING_ENABLED", globalSymbol = 1)
			SetCheckBoxState(PANEL, "check_debug_mode", debugMode == 1)
			break
		default:
			break
	endswitch

	return 0
End

Function DP_CheckProc_Debug(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	string   ctrl
	variable checked

	switch(cba.eventCode)
		case 2: // mouse up
			ctrl    = cba.ctrlName
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
		default:
			break
	endswitch

	return 0
End

Function DP_PopMenuProc_Selection(STRUCT WMPopupAction &pa) : PopupMenuControl

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
		default:
			break
	endswitch

	return 0
End
