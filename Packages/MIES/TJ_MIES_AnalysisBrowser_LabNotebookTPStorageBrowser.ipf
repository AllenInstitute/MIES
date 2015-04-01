#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static StrConstant LAB_NOTEBOOK_BROWSER = "LabnotebookBrowser"

static Function/S LBN_GetLeftPanel()
	return LAB_NOTEBOOK_BROWSER + "#P0"
End

static Function/S LBN_GetExpFolderFromPopup()

	string panel
	variable index

	WAVE/T experimentMap = GetExperimentMap()
	panel = LBN_GetLeftPanel()
	index = GetPopupMenuIndex(panel, "popup_select_experiment")

	ASSERT(index >= 0 && index < DimSize(experimentMap, ROWS), "Invalid index")

	return experimentMap[index][%ExperimentFolder]
End

Function LBN_OpenLabnotebookBrowser()

	string panel = LAB_NOTEBOOK_BROWSER

	if(windowExists(panel))
		DoWindow/F $panel
		return NaN
	endif

	Execute panel + "()"

	DoUpdate/W=$LBN_GetLeftPanel()
	SetPopupMenuIndex(LBN_GetLeftPanel(), "popup_select_experiment", 0)
	SetPopupMenuIndex(LBN_GetLeftPanel(), "popup_select_device", 0)

	DoUpdate/W=$LBN_GetLeftPanel()
	SetPopupMenuIndex(LBN_GetLeftPanel(), "popup_labenotebookViewableCols", 0)
End

Window LabnotebookBrowser() : Graph
	PauseUpdate; Silent 1		// building window...
	Display/K=1/W=(1224,152.75,1656,401.75)
	ModifyGraph margin(right)=74
	TextBox/C/N=text0/F=0/B=1/X=0.50/Y=2.02/E=2 ""
	NewPanel/K=2/HOST=#/EXT=1/W=(258,0,0,332) as " "
	ModifyPanel fixedSize=0
	Button button_clearlabnotebookgraph,pos={59,37},size={73,23},proc=LBN_ButtonProc_ClearGraph,title="Clear graph"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo)= A"!!,KCJ,ht*J,hp!!!#<pz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	PopupMenu popup_select_experiment,pos={29,94},size={199,21},proc=LBN_PopMenuProc_ExpDevSelector,title="Experiment:"
	PopupMenu popup_select_experiment,mode=1,value= #"LBN_GetAllExperiments()"
	PopupMenu popup_select_device,pos={46,123},size={161,21},proc=LBN_PopMenuProc_ExpDevSelector,title="Device: "
	PopupMenu popup_select_device,mode=1,value= #"LBN_GetAllDevicesForExperiment()"
	PopupMenu popup_labenotebookViewableCols,pos={27,12},size={150,21},bodyWidth=150,proc=LBN_PopMenuProc_ViewableCols
	PopupMenu popup_labenotebookViewableCols,userdata(ResizeControlsInfo)= A"!!,K>TE%@>J,hqP!!#<`z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_labenotebookViewableCols,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	PopupMenu popup_labenotebookViewableCols,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	PopupMenu popup_labenotebookViewableCols,mode=1,value= #"LBN_GetLabNotebookViewAbleCols()"
	Button button_switch,pos={58,63},size={72,23},proc=LBN_ButtonProc_SwitchXaxisType,title="Switch x-axis"
	CheckBox check_sync_with_sweepBrowser,pos={17,194},size={141,14},proc=LBN_CheckProc_SyncSweepBrowser,title="Sync with Sweep Browser"
	CheckBox check_sync_with_sweepBrowser,value= 0, disable=2
	RenameWindow #,P0
	SetActiveSubwindow ##
EndMacro

Function LBN_ButtonProc_ClearGraph(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			RemoveTracesFromGraph(LAB_NOTEBOOK_BROWSER)
			UpdateLBGraphLegend(LAB_NOTEBOOK_BROWSER)
			break
	endswitch

	return 0
End

Function LBN_PopMenuProc_ViewableCols(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string popStr, graph, panel, expFolder, device, folder
	switch(pa.eventCode)
		case 2: // mouse up
			popStr = pa.popStr
			graph = LAB_NOTEBOOK_BROWSER
			panel = LBN_GetLeftPanel()

			expFolder = LBN_GetExpFolderFromPopup()
			device = GetPopupMenuString(panel, "popup_select_device")

			folder = GetAnalysisLabNBFolderAS(expFolder, device)

			if(!DataFolderExists(folder))
				break
			endif

			DFREF dfr = $folder
			WAVE/T/SDFR=dfr numericKeys
			WAVE/T/SDFR=dfr numericValues

			AddTraceToLBGraph(graph, numericKeys, numericValues, popStr)
			break
	endswitch

	return 0
End

Function LBN_ButtonProc_SwitchXaxisType(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string graph, panel, expFolder, device
	switch(ba.eventCode)
		case 2: // mouse up
			graph = LAB_NOTEBOOK_BROWSER
			panel = LBN_GetLeftPanel()

			expFolder = LBN_GetExpFolderFromPopup()
			device = GetPopupMenuString(panel, "popup_select_device")

			DFREF dfr = GetAnalysisLabNBFolder(expFolder, device)
			WAVE/T/SDFR=dfr numericValues

			SwitchLBGraphXAxis(graph, numericValues)
			break
	endswitch

	return 0
End

Function LBN_PopMenuProc_ExpDevSelector(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string graph, panel, expFolder, device, traceList, trace, key
	string keyList = ""
	variable pos, numTraces, numKeys, i

	switch(pa.eventCode)
		case 2: // mouse up
			graph = LAB_NOTEBOOK_BROWSER
			panel = LBN_GetLeftPanel()

			expFolder = LBN_GetExpFolderFromPopup()
			device = GetPopupMenuString(panel, "popup_select_device")

			DFREF dfr = GetAnalysisLabNBFolder(expFolder, device)

			WAVE/Z/T/SDFR=dfr numericKeys
			WAVE/Z/T/SDFR=dfr numericValues

			if(!WaveExists(numericKeys) || !WaveExists(numericValues))
				print "BUG: missing labnotebook, handle that earlier"
				break
			endif

			traceList = TraceNameList(graph, ";", 0 + 1)
			numTraces = ItemsInList(traceList)

			for(i = 0; i < numTraces; i += 1)
				trace = StringFromList(i, traceList)
				key   = GetUserData(graph, trace, "key")
				ASSERT(!isEmpty(key), "Invalid key in trace user data")

				if(FindListItem(key, keyList) != -1)
					continue
				endif
				keyList = AddListItem(key, keyList, ";", Inf)
			endfor

			RemoveTracesFromGraph(graph)

			numKeys = ItemsInList(keyList)
			for(i = 0; i < numKeys; i += 1)
				key = StringFromList(i, keyList)
				AddTraceToLBGraph(graph, numericKeys, numericValues, key)
			endfor
			break
	endswitch

	return 0
End

Function LBN_CheckProc_SyncSweepBrowser(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			/// @todo implement
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function/S LBN_GetAllDevicesForExperiment()

	DFREF expFolder = GetAnalysisExpFolder(LBN_GetExpFolderFromPopup())

	return GetListOfDataFolders(expFolder)
End

Function/S LBN_GetAllExperiments()

	variable i, index
	string list = ""

	WAVE/T experimentMap = GetExperimentMap()
	index = GetNumberFromWaveNote(experimentMap, "index")

	for(i = 0; i < index; i += 1)
		list = AddListItem(experimentMap[i][%ExperimentName], list, ";", Inf)
	endfor

	return list
End

Function/S LBN_GetLabNotebookViewAbleCols()

	string expFolder, device, panel, control

	panel   = LBN_GetLeftPanel()
	control = "popup_select_device"

	if(!windowExists(panel) || !ControlExists(panel, control))
		return NONE
	endif

	device = GetPopupMenuString(panel, control)
	expFolder = LBN_GetExpFolderFromPopup()

	if(isEmpty(device) || isEmpty(expFolder))
		return NONE
	endif

	DFREF dfr = GetAnalysisLabNBFolder(expFolder, device)
	WAVE/T/Z/SDFR=dfr numericKeys

	return GetLabNotebookSortedKeys(numericKeys)
End
