#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_LBN
#endif

/// @file MIES_AnalysisBrowser_LabNotebookTPStorageBrowser.ipf
/// @brief __LBN__ Panels for browsing the labnotebook and the TPStorage waves
/// in the analysis browser

static StrConstant LAB_NOTEBOOK_BROWSER = "LabnotebookBrowser"
static StrConstant TPSTORAGE_BROWSER    = "TPStorageBrowser"
static StrConstant USERDATA_AD_COLUMNS = "ADColumns"

static Function/S LBN_GetLeftPanel(win)
	string win

	return win + "#P0"
End

static Function/S LBN_GetExpFolderFromPopup(graph)
	string graph

	string panel
	variable index

	WAVE/T map = GetAnalysisBrowserMap()
	panel = LBN_GetLeftPanel(graph)
	index = GetPopupMenuIndex(panel, "popup_select_experiment")

	ASSERT(index >= 0 && index < DimSize(map, ROWS), "Invalid index")

	return map[index][%DataFolder]
End

Function LBN_OpenLabnotebookBrowser()

	string panel     = LAB_NOTEBOOK_BROWSER
	string leftPanel = LBN_GetLeftPanel(panel)

	if(windowExists(panel))
		DoWindow/F $panel
		return NaN
	endif

	Execute panel + "()"

	SetPopupMenuIndex(leftPanel, "popup_select_experiment", 0)
	SetPopupMenuIndex(leftPanel, "popup_select_device", 0)
	SetPopupMenuIndex(leftPanel, "popup_LBNumericalKeys", 0)
	SetPopupMenuIndex(leftPanel, "popup_LBTextualKeys", 0)
	DoUpdate/W=$leftPanel
End

/// @brief Add a trace to the TPStorage browser graph
static Function LBN_AddTraceToTPStorage(panel, TPStorage, ActiveADC, key)
	string panel
	WAVE TPStorage
	variable activeADC
	string key
	variable column

	string lbl, axis, trace, graph, columns, traceList
	variable col
	variable red, green, blue
	variable numExistingTraces

	graph = GetMainWindow(panel)

	if(FindDimLabel(TPStorage, LAYERS, key) < 0)
		return NaN
	endif

	lbl = LineBreakingIntoParWithMinWidth(key)

	axis = GetNextFreeAxisName(graph, VERT_AXIS_BASE_NAME)
	trace = CleanupName(lbl + "_" + num2str(activeADC), 1)

	traceList = TraceNameList(graph, ";", 0 + 1)
	numExistingTraces = ItemsInList(traceList)

	AppendToGraph/W=$graph/L=$axis TPStorage[][activeADC][%$key]/TN=$trace vs TPStorage[][activeADC][%DeltaTimeInSeconds]
	GetTraceColor(numExistingTraces, red, green, blue)
	ModifyGraph/W=$graph rgb($trace)=(red, green, blue)
	ModifyGraph/W=$graph marker=8,msize=2
	ModifyGraph/W=$graph userData($trace)={key, 0, key}
	ModifyGraph/W=$graph userData($trace)={activeADC, 0, num2str(activeADC)}

	Label/W=$graph $axis lbl
	Label/W=$graph bottom "Delta time [s]"

	ModifyGraph/W=$graph lblPosMode = 1, standoff($axis) = 0, freePos($axis) = 0
	ModifyGraph/W=$graph mode = 3
	ModifyGraph/W=$graph nticks(bottom) = 10

	EquallySpaceAxis(graph, axisRegExp=VERT_AXIS_BASE_NAME + ".*")

	traceList = AddListItem(trace, traceList, ";", inf)
	LBN_UpdateTPSGraphLegend(graph, traceList=traceList)
End

static Function LBN_UpdateTPSGraphLegend(graph, [traceList])
	string graph, traceList

	string str, trace, entry, key
	variable i, numTraces, numRows, activeADC

	if(!windowExists(graph))
		return NaN
	endif

	if(FindListItem("text0", AnnotationList(graph)) == -1)
		return NaN
	endif

	if(ParamIsDefault(traceList) || ItemsInList(traceList) == 0)
		TextBox/C/W=$graph/N=text0/F=0 ""
		return NaN
	endif

	str = "\\JCActive ADC\\JL\r"

	Make/N=(NUM_AD_CHANNELS)/FREE/T sections
	numRows = DimSize(sections, ROWS)
	numTraces = ItemsInList(traceList)

	for(i = 0; i < numTraces; i += 1)
		trace = StringFromList(i, traceList)
		key = GetUserData(graph, trace, "key")
		activeADC = str2num(GetUserData(graph, trace, "activeADC"))
		ASSERT(IsFinite(activeADC), "activeDA user data is not valid")

		entry = sections[activeADC]
		if(isEmpty(entry))
			entry = StringFromList(activeADC, numerals) + "\r"
		endif
		entry += "\\s(" + trace + ") " + key + "\r"

		sections[activeADC] = entry
	endfor

	for(i = 0; i < numRows; i += 1)
		entry = sections[i]
		if(!isEmpty(entry))
			str += entry
		endif
	endfor

	str = RemoveEnding(str, "\r")
	TextBox/C/W=$graph/N=text0/F=2 str
End

Window LabnotebookBrowser() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(1160.25,188.75,1592.25,437.75)/K=1
	ModifyGraph margin(right)=74
	TextBox/C/N=text0/F=0/B=1/X=0.50/Y=2.02/E=2 ""
	NewPanel/HOST=#/EXT=1/W=(258,0,0,332) /K=2  as " "
	ModifyPanel fixedSize=0
	Button button_clearlabnotebookgraph,pos={59.00,57.00},size={90.00,23.00},proc=LBN_ButtonProc_ClearGraph,title="Clear graph"
	Button button_clearlabnotebookgraph,help={"Remove all traces from the graph"}
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo)= A"!!,KCJ,ht*J,hp!!!#<pz!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	Button button_clearlabnotebookgraph,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	PopupMenu popup_select_experiment,pos={29.00,124.00},size={174.00,19.00},proc=LBN_PopMenuProc_ExpDevSelector,title="Experiment:"
	PopupMenu popup_select_experiment,help={"Select an experiment from the ones open in the experiment browser"}
	PopupMenu popup_select_experiment,mode=1,value= #"LBN_GetAllExperiments()"
	PopupMenu popup_select_device,pos={46.00,153.00},size={144.00,19.00},proc=LBN_PopMenuProc_ExpDevSelector,title="Device: "
	PopupMenu popup_select_device,help={"Select a device from the currently selected experiment"}
	PopupMenu popup_select_device,mode=1,value= #"LBN_GetAllDevicesForExperiment(\"LabnotebookBrowser\")"
	PopupMenu popup_LBNumericalKeys,pos={27.00,12.00},size={150.00,19.00},bodyWidth=150,proc=LBN_PopMenuProc_LBNViewableCols
	PopupMenu popup_LBNumericalKeys,help={"All keys from the numeric labnotebook. Selecting one will add it to the graph."}
	PopupMenu popup_LBNumericalKeys,userdata(ResizeControlsInfo)= A"!!,K>TE%@>J,hqP!!#<`z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_LBNumericalKeys,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	PopupMenu popup_LBNumericalKeys,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	PopupMenu popup_LBNumericalKeys,mode=1,value= #"LBN_GetLBNumericalKeys(\"LabnotebookBrowser\")"
	PopupMenu popup_LBTextualKeys,pos={27.00,34.00},size={150.00,19.00},bodyWidth=150,proc=LBN_PopMenuProc_LBNViewableCols
	PopupMenu popup_LBTextualKeys,userdata(ResizeControlsInfo)= A"!!,K>TE%@>J,hqP!!#<`z!!#N3Bk1ct<C^(Dzzzzzzzzzzzzz!!#N3Bk1ct<C^(Dz"
	PopupMenu popup_LBTextualKeys,userdata(ResizeControlsInfo) += A"zzzzzzzzzzzz!!#N3Bk1ct<C]S7zzzzzzzzzz"
	PopupMenu popup_LBTextualKeys,userdata(ResizeControlsInfo) += A"zzz!!#N3Bk1ct<C]S7zzzzzzzzzzzzz!!!"
	PopupMenu popup_LBTextualKeys,mode=1,value= #"LBN_GetLBTextualKeys(\"LabnotebookBrowser\")"
	Button button_switch,pos={58.00,83.00},size={90.00,23.00},proc=LBN_ButtonProc_SwitchXaxisType,title="Switch x-axis"
	Button button_switch,help={"Switch between timestamp and sweep numbers as x axis type"}
	CheckBox check_sync_with_sweepBrowser,pos={17.00,194.00},size={148.00,15.00},disable=2,proc=LBN_CheckProc_SyncSweepBrowser,title="Sync with Sweep Browser"
	CheckBox check_sync_with_sweepBrowser,help={"Synchronize the currently selected experiment and device to the current sweep from the top sweep browser"}
	CheckBox check_sync_with_sweepBrowser,value= 0
	RenameWindow #,P0
	SetActiveSubwindow ##
EndMacro

Function LBN_OpenTPStorageBrowser()

	string panel     = TPSTORAGE_BROWSER
	string leftPanel = LBN_GetLeftPanel(panel)

	if(windowExists(panel))
		DoWindow/F $panel
		return NaN
	endif

	Execute panel + "()"

	DoUpdate/W=$leftPanel
	SetPopupMenuIndex(leftPanel, "popup_select_experiment", 0)
	SetPopupMenuIndex(leftPanel, "popup_select_device", 0)
	SetPopupMenuIndex(leftPanel, "popup_select_tpstorage", 0)

	DoUpdate/W=$leftPanel
	SetPopupMenuIndex(leftPanel, "popup_TPStorageViewableCols", 1)
End

Window TPStorageBrowser() : Graph
	PauseUpdate; Silent 1		// building window...
	Display/K=1/W=(1224,152.75,1656,401.75)
	ModifyGraph margin(right)=74
	TextBox/C/N=text0/F=0/B=1/X=0.50/Y=2.02/E=2 ""
	NewPanel/K=2/HOST=#/EXT=1/W=(258,0,0,332) as " "
	ModifyPanel fixedSize=0
	Button button_cleargraph,pos={59,37},size={73,23},proc=LBN_ButtonProc_ClearGraph,title="Clear graph"
	Button button_cleargraph, help={"Remove all traces from the graph"}
	PopupMenu popup_select_experiment,pos={29,94},size={199,21},proc=LBN_PopMenuProc_TPSAllSelector,title="Experiment:"
	PopupMenu popup_select_experiment,mode=1,value= #"LBN_GetAllExperiments()"
	PopupMenu popup_select_experiment,help={"Select an experiment from the ones open in the experiment browser"}
	PopupMenu popup_select_device,pos={46,123},size={161,21},proc=LBN_PopMenuProc_TPSAllSelector,title="Device: "
	PopupMenu popup_select_device,mode=1,value= #"LBN_GetAllDevicesForExperiment(\"TPStorageBrowser\")"
	PopupMenu popup_select_device,help={"Select a device from the currently selected experiment"}
	PopupMenu popup_select_tpstorage,pos={46,150},size={161,21},proc=LBN_PopMenuProc_TPSAllSelector,title="TPStorage: "
	PopupMenu popup_select_tpstorage,mode=1,popvalue="TPStorage",value= #"LBN_GetAllTPStorageForExpDev(\"TPStorageBrowser\")"
	PopupMenu popup_select_tpstorage,help={"Select the main TPStorage wave or one of the backup waves"}
	PopupMenu popup_TPStorageViewableCols,pos={27,12},size={150,21},bodyWidth=150,proc=LBN_PopMenuProc_TPSViewEntries
	PopupMenu popup_TPStorageViewableCols,mode=1,value= #"LBN_TPStorageViewAbleCols(\"TPStorageBrowser\")"
	PopupMenu popup_TPStorageViewableCols,help={"All keys sorted by active channel from the currently selected TPStorage wave. Selecting one will add it to the graph."}
	RenameWindow #,P0
	SetActiveSubwindow ##
EndMacro

Function LBN_ButtonProc_ClearGraph(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string graph, panel

	switch(ba.eventCode)
		case 2: // mouse up
			panel = ba.win
			graph = GetMainWindow(panel)
			RemoveTracesFromGraph(graph)

			if(!cmpstr(graph, TPSTORAGE_BROWSER))
				LBN_UpdateTPSGraphLegend(graph)
			else
				UpdateLBGraphLegend(graph)
			endif

			break
	endswitch

	return 0
End

Function LBN_PopMenuProc_LBNViewableCols(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string popStr, graph, panel, expFolder, device, folder
	string ctrl

	switch(pa.eventCode)
		case 2: // mouse up
			popStr = pa.popStr
			panel  = pa.win
			graph  = GetMainWindow(panel)
			ctrl   = pa.ctrlName

			expFolder = LBN_GetExpFolderFromPopup(graph)
			device = GetPopupMenuString(panel, "popup_select_device")

			folder = GetAnalysisLabNBFolderAS(expFolder, device)

			if(!DataFolderExists(folder))
				break
			endif

			strswitch(ctrl)
				case "popup_LBNumericalKeys":
					Wave values = GetAnalysLBNumericalValues(expFolder, device)
					WAVE keys   = GetAnalysLBNumericalKeys(expFolder, device)
				break
				case "popup_LBTextualKeys":
					Wave values = GetAnalysLBTextualValues(expFolder, device)
					WAVE keys   = GetAnalysLBTextualKeys(expFolder, device)
				break
				default:
					ASSERT(0, "Unknown ctrl")
					break
			endswitch

			AddTraceToLBGraph(graph, keys, values, popStr)
			break
	endswitch

	return 0
End

Function LBN_PopMenuProc_TPSViewEntries(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string key, graph, panel, expFolder, device, columns
	variable numActiveADC

	switch(pa.eventCode)
		case 2: // mouse up
			key = pa.popStr
			panel = pa.win
			graph = GetMainWindow(panel)

			expFolder = LBN_GetExpFolderFromPopup(graph)
			device = GetPopupMenuString(panel, "popup_select_device")

			DFREF dfr = GetAnalysisDeviceTestPulse(expFolder, device)
			WAVE/Z/SDFR=dfr TPStorage = $GetPopupMenuString(panel, "popup_select_tpstorage")

			if(!WaveExists(TPStorage))
				break
			endif

			columns = GetUserData(panel, pa.ctrlName, USERDATA_AD_COLUMNS)
			numActiveADC = str2num(StringFromList(pa.popNum - 1, columns))
			ASSERT(IsFinite(numActiveADC), "Expected valid numActiveADC")

			LBN_AddTraceToTPStorage(panel, TPStorage, numActiveADC, key)
			break
	endswitch

	return 0
End

Function LBN_ButtonProc_SwitchXaxisType(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string graph, panel, expFolder, device
	switch(ba.eventCode)
		case 2: // mouse up
			panel = ba.win
			graph = GetMainWindow(panel)

			expFolder = LBN_GetExpFolderFromPopup(graph)
			device = GetPopupMenuString(panel, "popup_select_device")

			WAVE numericalValues = GetAnalysLBNumericalValues(expFolder, device)
			WAVE textualValues   = GetAnalysLBTextualValues(expFolder, device)

			SwitchLBGraphXAxis(graph, numericalValues, textualValues)
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
			panel = pa.win
			graph = GetMainWindow(panel)

			expFolder = LBN_GetExpFolderFromPopup(graph)
			device = GetPopupMenuString(panel, "popup_select_device")

			WAVE/T numericalKeys = GetAnalysLBNumericalKeys(expFolder, device)
			WAVE numericalValues = GetAnalysLBNumericalValues(expFolder, device)

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
				AddTraceToLBGraph(graph, numericalKeys, numericalValues, key)
			endfor
			break
	endswitch

	return 0
End

Function LBN_PopMenuProc_TPSAllSelector(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string graph, panel, expFolder, device, traceList, trace, key, tpstorageName, activeADC
	string keyList = ""
	string ADCList = ""
	variable i, numTraces

	switch(pa.eventCode)
		case 2: // mouse up
			panel = pa.win
			graph = GetMainWindow(panel)

			expFolder = LBN_GetExpFolderFromPopup(graph)
			device = GetPopupMenuString(panel, "popup_select_device")
			tpstorageName= GetPopupMenuString(panel, "popup_select_tpstorage")

			// update the control user data on the TPStorage layer selector popup
			if(!cmpstr(pa.ctrlName, "popup_select_tpstorage"))
				LBN_TPStorageViewAbleCols(graph)
			endif

			DFREF dfr = GetAnalysisDeviceTestPulse(expFolder, device)
			WAVE/Z/SDFR=dfr TPStorage = $tpstorageName

			if(!WaveExists(TPStorage))
				break
			endif

			traceList = TraceNameList(graph, ";", 0 + 1)
			numTraces = ItemsInList(traceList)

			for(i = 0; i < numTraces; i += 1)
				trace = StringFromList(i, traceList)

				key = GetUserData(graph, trace, "key")
				activeADC = GetUserData(graph, trace, "activeADC")
				ASSERT(!isEmpty(key), "Invalid key in trace user data")
				ASSERT(!isEmpty(activeADC), "Invalid activeADC in trace user data")

				keyList  = AddListItem(key, keyList, ";", Inf)
				ADCList = AddListItem(activeADC, ADCList, ";", Inf)
			endfor

			RemoveTracesFromGraph(graph)

			ASSERT(numTraces == ItemsInList(keyList) && numTraces == ItemsInList(ADCList), "Unexpected list size")
			for(i = 0; i < numTraces; i += 1)
				key           = StringFromList(i, keyList)
				activeADC = StringFromList(i, ADCList)
				LBN_AddTraceToTPStorage(panel, TPStorage, str2num(activeADC), key)
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

Function/S LBN_GetAllDevicesForExperiment(graph)
	string graph

	DFREF expFolder = GetAnalysisExpFolder(LBN_GetExpFolderFromPopup(graph))

	return GetListOfDataFolders(expFolder)
End

Function/S LBN_GetAllExperiments()

	variable i, index
	string list = ""

	WAVE/T map = GetAnalysisBrowserMap()
	index = GetNumberFromWaveNote(map, NOTE_INDEX)

	for(i = 0; i < index; i += 1)
		list = AddListItem(map[i][%FileName], list, ";", Inf)
	endfor

	return list
End

Function/S LBN_GetLBTextualKeys(graph)
	string graph

	string expFolder, device, panel, control

	panel   = LBN_GetLeftPanel(graph)
	control = "popup_select_device"

	if(!windowExists(panel) || !ControlExists(panel, control))
		return NONE
	endif

	device    = GetPopupMenuString(panel, control)
	expFolder = LBN_GetExpFolderFromPopup(graph)

	if(isEmpty(device) || isEmpty(expFolder))
		return NONE
	endif

	WAVE/T textualKeys = GetAnalysLBTextualKeys(expFolder, device)

	return GetLabNotebookSortedKeys(textualKeys)
End

Function/S LBN_GetLBNumericalKeys(graph)
	string graph

	string expFolder, device, panel, control

	panel   = LBN_GetLeftPanel(graph)
	control = "popup_select_device"

	if(!windowExists(panel) || !ControlExists(panel, control))
		return NONE
	endif

	device    = GetPopupMenuString(panel, control)
	expFolder = LBN_GetExpFolderFromPopup(graph)

	if(isEmpty(device) || isEmpty(expFolder))
		return NONE
	endif

	WAVE/T numericalKeys = GetAnalysLBNumericalKeys(expFolder, device)

	return GetLabNotebookSortedKeys(numericalKeys)
End

Function/S LBN_TPStorageViewAbleCols(graph)
	string graph

	string expFolder, device, panel, control, entry
	string userDataList = ""
	string list = ""
	variable numCols, numLayers, i, j, currentCol, numEntries

	panel   = LBN_GetLeftPanel(graph)
	control = "popup_select_device"

	if(!windowExists(panel) || !ControlExists(panel, control))
		return NONE
	endif

	device = GetPopupMenuString(panel, control)
	expFolder = LBN_GetExpFolderFromPopup(graph)

	if(isEmpty(device) || isEmpty(expFolder))
		return NONE
	endif

	DFREF dfr = GetAnalysisDeviceTestpulse(expFolder, device)
	WAVE/Z/SDFR=dfr TPStorage = $GetPopupMenuString(panel, "popup_select_tpstorage")

	if(!WaveExists(TPStorage))
		return NONE
	endif

	numCols   = DimSize(TPStorage, COLS)
	numLayers = DimSize(TPStorage, LAYERS)
	for(i = 0; i < numCols; i += 1)
		list = AddListItem("\\M1(" + StringFromList(i, NUMERALS) + " Active AD", list, ";", Inf)

		for(j = 0; j < numLayers; j += 1)
			list = AddListItem(GetDimLabel(TPStorage, LAYERS, j), list, ";", Inf)
		endfor
		if(i != numCols - 1)
			list = AddListItem(POPUPMENU_DIVIDER, list, ";", Inf)
		endif
	endfor

	list = ListMatch(list, "!*Time*")
	list = ListMatch(list, "!*Slope*")

	// create a list of the column index into TPStorage of each TPStorage layer
	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		entry = StringFromList(i, list)

		if(!cmpstr(entry, POPUPMENU_DIVIDER))
			currentCol += 1
		endif

		userDataList = AddListItem(num2str(currentCol), userDataList, ";", Inf)
	endfor

	SetControlUserData(panel, "popup_TPStorageViewableCols", USERDATA_AD_COLUMNS, userDataList)

	return list
End

Function/S LBN_GetAllTPStorageForExpDev(graph)
	string graph

	string list, expFolder, device

	string leftPanel = LBN_GetLeftPanel(graph)
	expFolder = LBN_GetExpFolderFromPopup(graph)
	device = GetPopupMenuString(leftPanel, "popup_select_device")

	DFREF dfr = GetAnalysisDeviceTestPulse(expFolder, device)

	list = GetListOfObjects(dfr, ".*")

	if(isEmpty(list))
		return NONE
	endif

	return list
End
