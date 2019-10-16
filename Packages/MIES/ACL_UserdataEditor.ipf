#pragma rtGlobals=1		// Use modern global access method.
#pragma version = 1.0.0.0
#pragma IgorVersion = 6		// requires Igor 6 or later
#pragma IndependentModule=ACL_UserDataEditor
// ********************
//  LICENSE
// ********************
//	Copyright (c) 2007 by Adam Light
//	
//	Permission is hereby granted, free of charge, to any person
//	obtaining a copy of this software and associated documentation
//	files (the "Software"), to deal in the Software without
//	restriction, including without limitation the rights to use,
//	copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following
//	conditions:
//	
//	The above copyright notice and this permission notice shall be
//	included in all copies or substantial portions of the Software.
//	
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//	OTHER DEALINGS IN THE SOFTWARE.
//
// *************************
//  VERSION HISTORY
// *************************
//	Date			Version #				Changes
//	Jan 20, 2007		Version 1.0.0.0			Initial release
//	Oct 17, 2019		Version 1.0.0.1			Michael Huth / byte physics: Added PopupMenus to select userdata key instead of fixed tabNum/tabControl
//
//
// Known issues:
//
// - If both columns list the same key, after editing an entry the other column does not update. Workaround press 'Refresh Control List'
// - After clicking at the column header for sorting the key selection resets
//
// ********************
//  MENUS
// ********************
Menu "Panel"
	SubMenu "Packages"
		"Userdata Editor for Controls",/Q,InitializeUserDataEditor()
	End
End	

static StrConstant EMPTY_USERDATA = "- empty -"

// ********************
//  PANEL
// ********************
Function BuildpnlUserDataEditor(panelName)
	String &panelName
	NewPanel /K=1 /W=(606,339,1337,1479) /N=$(panelName) as "Userdata Editor for Controls"
	panelName = S_name
	PopupMenu popupPanelSelect,pos={9.00,7.00},size={140.00,19.00},proc=PopMenuSelectPanel,title="Select Panel"
	PopupMenu popupPanelSelect,help={"Select the panel that contains the controls for which you want to edit the userdata."}
	PopupMenu popupPanelSelect,mode=3,popvalue="pnlUserDataEditor",value= #"SortList(WinList(\"*\", \";\", \"WIN:64\"), \";\", 0)"
	ListBox listPanelControls,pos={9.00,68.00},size={711.00,1065.00},proc=ListBoxPanelControls
	ListBox listPanelControls,help={"This list box contains the controls of a the selected type on the selected panel.\rSee the Userdata Editor for Controls help file for detailed information."}
	ListBox listPanelControls,userdata(order0)=  "0",userdata(sortCol)=  "1"
	ListBox listPanelControls,userdata(order1)=  "0"
	ListBox listPanelControls,listWave=root:Packages:ACL_UserDataEditor:controlInfoWave
	ListBox listPanelControls,selWave=root:Packages:ACL_UserDataEditor:controlInfoSelectWave
	ListBox listPanelControls,mode= 8,widths={264,216,1038},userColumnResize= 1
	Button buttonRefreshControlList,pos={314.00,7.00},size={117.00,19.00},proc=ButtonRefresh,title="Refresh Control List"
	Button buttonRefreshControlList,help={"Click this button if you add or remove a control on a panel after opening the Userdata Editor panel.  Doing so will update the list of controls on the target panel."}
	PopupMenu popupControlType,pos={9.00,34.00},size={296.00,19.00},proc=PopMenuSelectControlType,title="Show Controls of Type"
	PopupMenu popupControlType,help={"Use this popmenu to edit the userdata for only certain types of controls on a panel."}
	PopupMenu popupControlType,userdata(controlType)=  "NaN"
	PopupMenu popupControlType,mode=1,popvalue="All controls and subwindows",value= #"root:Packages:ACL_UserDataEditor:gsControlTypePopmenu"
	PopupMenu popupSelectColumn0,pos={316.00,34.00},size={64.00,19.00},proc=PopMenuSelectColumn
	PopupMenu popupSelectColumn0,mode=1,popvalue="",value= #"\"ContentHolder\""
	PopupMenu popupSelectColumn1,pos={489.00,34.00},size={64.00,19.00},proc=PopMenuSelectColumn
	PopupMenu popupSelectColumn1,mode=1,popvalue="",value= #"\"ContentHolder\""
	SetWindow $(panelName),hook(ACLUserDataEditor)=ACL_UserDataEditorHook
	SetWindow $(panelName),userdata=S_name
End

// ********************
//  INITIALIZATION
// ********************
Function InitializeUserDataEditor()
	String currentPanel = WinName(0, 64)	// get name of top panel
	String panelName = "pnlUserDataEditor"
	DoWindow $(panelName)
	if (!V_flag)
		String curDataFolder = GetDataFolder(1)
		if (!DataFolderExists("root:Packages:ACL_UserDataEditor"))
			NewDataFolder/O/S root:Packages
			NewDataFolder/O/S root:Packages:ACL_UserDataEditor
		else
			SetDataFolder root:Packages:ACL_UserDataEditor
		endif
		
		// create list box wave
		Make/T/O/N=(1,3) controlInfoWave
		Make/O/N=(1,3) controlInfoSelectWave
		SetDimLabel 1, 0, $("Control Name"), controlInfoWave, controlInfoSelectWave
		SetDimLabel 1, 1, $("key left"), controlInfoWave, controlInfoSelectWave
		SetDimLabel 1, 2, $("key right"), controlInfoWave, controlInfoSelectWave
		
		// create a wave that will store the types of controls and the value of V_flag that will be
		// returned for that type of control
		Make/O/T/N=(15,2) controlTypes
		// set control types names
		controlTypes[0,7][0] = {"", "All controls and subwindows", "Button", "Chart", "Check Box", "Custom Control", "Group Box", "List Box"}
		controlTypes[8,14][0] = {"Popup Menu", "Set Variable", "Slider", "Tab Control", "Title Box", "Value Display", "Subwindow"}
		
		// set control types V_flag values returned from ControlInfo
		controlTypes[0,7][1] = {"", "", "1", "6", "2", "12", "9", "11"}
		controlTypes[8,14][1] = {"3", "5", "7", "8", "10", "4", ""}
		
		// create string that will contain the menu choices for the control type popmenu
		String/G gsControlTypePopmenu = ""
		Variable n
		For (n=1; n<DimSize(controlTypes, 0); n+=1)
			gsControlTypePopmenu += controlTypes[n][0] + ";"
		EndFor
	
		// activate panel
		BuildpnlUserDataEditor(panelName)
		SetDataFolder curDataFolder
		ControlInfo/W=$(panelName) popupPanelSelect

		if (V_Flag == 3)		// popup control exists
			String panelList = SortList(WinList("*", ";", "WIN:64"), ";", 0)
			Variable listPos =WhichListItem(currentPanel, panelList, ";")
		
			if (listPos >= 0)
				ModifyControl popupPanelSelect, win=$(panelName), mode=listPos + 1
			else
				ModifyControl popupPanelSelect, win=$(panelName), mode=1
			EndIf

		endif

		// determine the currently selected panel and execute the popup action procedure so that the
		// list box will be filled in correctly
		ControlInfo/W=$(panelName) popupPanelSelect
		if (V_flag == 3)		// this is actually a popup menu--should always be true
			STRUCT WMPopupAction pa
			pa.ctrlName = "popupPanelSelect"
			pa.win = panelName
			pa.eventCode = 2
			pa.popNum = V_Value
			pa.popStr = S_Value
			FUNCREF ACLUserDataEditorProtoFunc actionproc = PopMenuSelectPanel
			actionproc(pa)
		endif
	else
		DoWindow/F $(panelName)
	EndIf
	return 0
End

// ********************
// FUNCREFs
// ********************

Function ACLUserDataEditorProtoFunc(pa)
	STRUCT WMPopupAction &pa
End

// ********************
//  ACTION FUNCTIONS
// ********************
Function PopMenuSelectPanel(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	string userKeys, controlList
	String curDataFolder = GetDataFolder(1)
	variable controltypes

	if (!DataFolderExists("root:Packages:ACL_UserDataEditor"))
		NewDataFolder/O/S root:Packages:ACL_UserDataEditor
	else
		SetDataFolder root:Packages:ACL_UserDataEditor
	endif
		
	switch( pa.eventCode )
		case 2: // mouse up
			// make sure that window selected in popup menu (pa.popStr) still exists
			DoWindow $(pa.popStr)
			if (!V_Flag)
				ControlUpdate/W=$(pa.win) $(pa.ctrlName)
				ControlInfo/W=$(pa.win) $(pa.ctrlName)
				if (V_Flag == 3)		// this is a popup menu
					pa.popStr = S_Value
					PopMenuSelectPanel(pa)
					return 0
				EndIf
			EndIf

			controlTypes = str2num(GetUserData(pa.win, "popupControlType", "controlType"))
		
			userKeys = ACL_GetUserdataKeys(StringFromList(0, pa.popStr), controltypes)
			userKeys = AddListItem(EMPTY_USERDATA, userKeys, ";", 0)
			userKeys = "\"" + userKeys + "\""
			PopupMenu popupSelectColumn0,mode=1,popvalue="",value=#userKeys
			PopupMenu popupSelectColumn1,mode=1,popvalue="",value=#userKeys
			
			ACL_SetupListControlWaves(pa.win, pa.popStr)

			// put value of selected panel in the (unnamed) userdata of the window that contains the PopMenu box
			SetWindow $(pa.win) userdata=pa.popStr
			
			break
	endswitch

	SetDataFolder curDataFolder
	return 0
End

Function PopMenuSelectColumn(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	String curDataFolder = GetDataFolder(1)
	if (!DataFolderExists("root:Packages:ACL_UserDataEditor"))
		NewDataFolder/O/S root:Packages:ACL_UserDataEditor
	else
		SetDataFolder root:Packages:ACL_UserDataEditor
	endif

	ControlInfo/W=$pa.win popupPanelSelect
	ACL_SetupListControlWaves(pa.win, S_Value)

	SetDataFolder curDataFolder
	return 0
End

Function/S ACL_GetAllControlsAndWindows(wName)
	string wName

	// Get a list of all controls on designated panel and any children.
	String controlList = ""
	Variable numWindows
	String allWindows, currentWindow
	Variable n

	// Make a list of all windows and child windows (recursively) on this panel, including
	// this parent panel itself.
	allWindows = ""
	GetAllWindows(wName, allWindows)

	numWindows = ItemsInList(allWindows, ";")
	For (n=0; n<numWindows; n+=1)
		currentWindow = StringFromList(n, allWindows, ";")
		controlList += GetAllControls(currentWindow)
	EndFor

	// Add all relevent windows and child windows to this list.
	controlList += allWindows

	// Remove the parent panel from the list of "controls"
	controlList = RemoveFromList(wName, controlList, ";")

	return controlList
End

Function ACL_SetupListControlWaves(wName, targetWin)
	string wName, targetWin

	Variable controlTypes, showAllControls, showSubwindows
	string controlList, keyLeft, keyRight
	variable n

	ControlInfo/W=$wName popupSelectColumn0
	keyLeft = S_Value
	ControlInfo/W=$wName popupSelectColumn1
	keyRight = S_Value
	keyLeft = SelectString(!CmpStr(keyLeft, EMPTY_USERDATA), keyLeft, "")
	keyRight = SelectString(!CmpStr(keyRight, EMPTY_USERDATA), keyRight, "")

	controlTypes = str2num(GetUserData(wName, "popupControlType", "controlType"))
	if (numtype(controlTypes) == 2)		// controlTypes = NaN
		// get currently selected value of popupControlType using control info
		ControlInfo/W=$(wName) popupControlType
		if (abs(V_flag) == 3)		// this is a popup control
			Switch (V_value)		// currently selected popup item
				Case 1:			// show all controls and subwindows
					showAllControls = 1
					showSubwindows = 1
					break
				Case 14:		// show only subwindows
					showAllControls = 0
					showSubwindows = 1
					break
				default:			// default:  show all controls and subwindows
					showAllControls = 1
					showSubwindows = 1
			EndSwitch
		endif
	endif

	controlList = ACL_GetAllControlsAndWindows(targetWin)

	// populate list box wave with the new controls
	Variable numControls = ItemsInList(controlList)
	Variable windowType
	WAVE/T controlInfoWave
	String currentControlName
	String potentialWindowName
			
	Redimension/N=(0,3) controlInfoWave
		
	// create variables that represent the colum indices of the 3 columns of the wave
	Variable ctrlNameCol, tabnumCol, tabcontrolCol
	Variable numCols = DimSize(controlInfoWave, 1)
	String currentDimLabel
	For (n=0; n<numCols; n+=1)
		currentDimLabel = GetDimLabel(controlInfoWave, 1, n)
		if (stringmatch(currentDimLabel, "*Control Name*") == 1)
			ctrlNameCol = n
		elseif (stringmatch(currentDimLabel, "*key left*") == 1)
			tabnumCol = n
		elseif (stringmatch(currentDimLabel, "*key right*") == 1)
			tabcontrolCol = n
		endif
	EndFor
			
	String windowName = "", controlName = "", displayName = ""
	For (n=0; n<numControls; n+=1)
		Variable waveRow = DimSize(controlInfoWave, 0)
		currentControlName = StringFromList(n, controlList, ";")
				
		// Parse out the window name and the actual control name.
		// Note that, if currentControlName is actually a subwindow, that
		// the windowName and controlName values set in the call below
		// may not be valid.  However, this possibility is accounted for
		// in the else clause below.
		ParseFullControlName(currentControlName, windowName, controlName, displayName)

		// see if this is a control or a child window
		ControlInfo/W=$(windowName) $(controlName)
		if (abs(V_Flag) > 0)
			if (showAllControls || (numtype(controlTypes) == 0 && controlTypes == abs(V_flag)))		// see if this control type should be shown
				Redimension/N=(waveRow + 1, -1) controlInfoWave
				// put in control names
				controlInfoWave[waveRow][ctrlNameCol] = displayName
				// put in tabnum values
				controlInfoWave[waveRow][tabnumCol] = GetUserData(windowName, controlName, keyLeft)
				// put in tabcontrol values
				controlInfoWave[waveRow][tabcontrolCol] = GetUserData(windowName, controlName, keyRight)
			endif
		elseif (showSubwindows)
			// see if this is a window
			sprintf potentialWindowName, "%s#%s", windowName, controlName
			windowType = WinType(potentialWindowName)
			Switch (windowType)
				Case 0:		// no window by that name
					// do nothing
					break
				Case 1:		// window is a graph
				Case 2:		// window is a table
				Case 3:		// window is a layout
				Case 5:		// window is a notebook
				Case 7:		// window is a panel
				Case 13:	// window is an XOP target window
				default:
					Redimension/N=(waveRow + 1, -1) controlInfoWave
					// put in window name
					controlInfoWave[waveRow][ctrlNameCol] = displayName		// should this be the complete window name instead?
					// put in tabnum values
					controlInfoWave[waveRow][tabnumCol] = GetUserData(potentialWindowName, "", keyLeft)
					// put in tabcontrol values
					controlInfoWave[waveRow][tabcontrolCol] = GetUserData(potentialWindowName, "", keyRight)
			EndSwitch
		EndIf
	EndFor
		
	// see if sorting information is present, and if so sort the controls based on those values
	Variable sortCol = str2num(GetUserData(wName, "listPanelControls", "sortCol"))
	if (numType(sortCol) == 0)		// we need to sort
		Variable sortOrder = str2num(GetUserData(wName, "listPanelControls", "order" + num2str(sortCol)))
		if (numType(sortOrder) != 0)
			sortOrder = 0		// default sort: ascending
		endif

		// break each column of controlInfoWave into a 1D wave
		String newWaveName
		String waveListString = ""
		For (n=0; n<DimSize(controlInfoWave, 1); n+=1)
			newWaveName = "controlInfoWaveCol" + num2str(n)
			Duplicate/O/R=[][n] controlInfoWave, $(newWaveName)		// copy column of controlInfoWave
			Redimension/N=(-1, 0) $(newWaveName)
			waveListString += newWaveName + ";"
		EndFor
			
		// sort the waves
		String sortKeyWaves = ""
		Switch (sortCol)
			Case 0:		// control name column
				if (sortOrder == 1)		// descending
					Sort/A/R {controlInfoWaveCol0, controlInfoWaveCol2, controlInfoWaveCol1}, controlInfoWaveCol0, controlInfoWaveCol1, controlInfoWaveCol2
				else					// ascending
					Sort/A {controlInfoWaveCol0, controlInfoWaveCol2, controlInfoWaveCol1}, controlInfoWaveCol0, controlInfoWaveCol1, controlInfoWaveCol2
				endif
				break
			Case 1:		// tabnum column
				if (sortOrder == 1)		// descending
					Sort/A/R {controlInfoWaveCol1, controlInfoWaveCol2, controlInfoWaveCol0}, controlInfoWaveCol0, controlInfoWaveCol1, controlInfoWaveCol2
				else					// ascending
					Sort/A {controlInfoWaveCol1, controlInfoWaveCol2, controlInfoWaveCol0}, controlInfoWaveCol0, controlInfoWaveCol1, controlInfoWaveCol2
				endif
				break
			Case 2:		// tabcontrol name column
				if (sortOrder == 1)		// descending
					Sort/A/R {controlInfoWaveCol2, controlInfoWaveCol1, controlInfoWaveCol0}, controlInfoWaveCol0, controlInfoWaveCol1, controlInfoWaveCol2
				else					// ascending
					Sort/A {controlInfoWaveCol2, controlInfoWaveCol1, controlInfoWaveCol0}, controlInfoWaveCol0, controlInfoWaveCol1, controlInfoWaveCol2
				endif
				break
		EndSwitch
				
		// put waves back together
		Concatenate/O/T/KILL waveListString, sortedWave
		controlInfoWave[][] = sortedWave[p][q]
		KillWaves sortedWave
			
	endif
			
	// make select wave for list box
	WAVE controlInfoSelectWave
	Redimension/N=(DimSize(controlInfoWave, 0),3) controlInfoSelectWave
	// disable editing of Control Name values
	controlInfoSelectWave[][ctrlNameCol] = controlInfoSelectWave[p][q] & ~2
	// enable editing of tabnum values
	controlInfoSelectWave[][tabnumCol] = controlInfoSelectWave[p][q] | 2
	// enable editing of tabcontrol values
	controlInfoSelectWave[][tabcontrolCol] = controlInfoSelectWave[p][q] | 2
End

Function PopMenuSelectControlType(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	String curDataFolder = GetDataFolder(1)
	if (!DataFolderExists("root:Packages:ACL_UserDataEditor"))
		NewDataFolder/O/S root:Packages:ACL_UserDataEditor
	else
		SetDataFolder root:Packages:ACL_UserDataEditor
	endif
	
	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			String panel = pa.win		// window that hosts the popup menu
			
			WAVE/T controlTypes		// text wave that matches the popNum value to the ControlInfo V_flag type
			
			// put V_flag type of newly selected control type into userdata of this popup control
			Variable controlType = str2num(controlTypes[pa.popNum][1])
			PopupMenu $(pa.ctrlName) win=$(pa.win), userdata(controlType) = num2str(controlType)
			
			// simulate a click on the Select Panel popmenu that will force a refresh of the list of controls
			
			// determine the currently selected panel and execute the popup action procedure so that the
			// list box will be filled in correctly
			ControlInfo/W=$(panel) popupPanelSelect
			if (V_flag == 3)		// this is actually a popup menu--should always be true
				STRUCT WMPopupAction pa2
				pa2.ctrlName = "popupPanelSelect"
				pa2.win = panel
				pa2.eventCode = 2
				pa2.popNum = V_Value
				pa2.popStr = S_Value
				FUNCREF ACLUserDataEditorProtoFunc actionproc = PopMenuSelectPanel
				actionproc(pa2)
			endif
			
			break
	endswitch
	
	SetDataFolder curDataFolder
	return 0
End

Function ListBoxPanelControls(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	Variable windowType
	String panel = GetUserData(lba.win, "", "")	// name of panel that is currently selected to set userdata of controls
	String potentialWindowName
	string keyLeft, keyRight
	WAVE/T/Z controlInfoWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	String curDataFolder = GetDataFolder(1)
	if (!DataFolderExists("root:Packages:ACL_UserDataEditor"))
		NewDataFolder/O/S root:Packages:ACL_UserDataEditor
	else
		SetDataFolder root:Packages:ACL_UserDataEditor
	endif
	
	String currentDimLabel
	Variable n, numCols
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1:	// mouse down
			// if the row=-1, that means the colum headers were clicked.  If so, sort
			// the list of controls using the selected column as a key
			if (lba.row == -1 && (numtype(lba.col) == 0 && lba.col >= 0))		// column header was clicked
				// get last column to sort by, if it's set already
				Variable lastSortCol = str2num(GetUserData(lba.win, lba.ctrlName, "sortCol"))
				if (numtype(lastSortCol) != 0)
					lastSortCol = -1
				endif
				ListBox $(lba.ctrlName) win=$(lba.win), userdata(sortCol) = num2str(lba.col)		// indicate which column to sort by
				
				// now, toggle the ascending/descending sort flag for this column (but only if this column was already selected)
				Variable sortOrder = str2num(GetUserData(lba.win, lba.ctrlName, "order"+num2str(lba.col)))
				if (numtype(sortOrder) != 0)
					sortOrder = 0		// default: ascending
				elseif (lastSortCol == lba.col)
					sortOrder = !sortOrder
				endif
				ListBox $(lba.ctrlName) win=$(lba.win), userdata($("order" + num2str(lba.col)))=num2str(sortOrder)
				
				// now change the dimension labels of the list box text wave so that the column controlling the
				// sort has the up or down arrow icon on it, depending on the order of the sort
				numCols = DimSize(controlInfoWave, 1)
				Variable slashPos
				For (n=0; n<numCols; n+=1)
					currentDimLabel = GetDimLabel(controlInfoWave, 1, n)
					slashPos = strsearch(currentDimLabel, "\\", inf, 1)	// search for a slash starting from the end of the string
					if (slashPos > 0)		// don't remove a slash if it's the first char in the dim label because that's used to make colum label bold
						currentDimLabel = currentDimLabel[0,slashPos - 1]
					endif

					if (n == lba.col)		// if this is the column we're using as a search column
						if (sortOrder == 0)		// ascending
							currentDimLabel += "\W517"
						elseif (sortOrder == 1)	// descending
							currentDimLabel += "\W523"
						endif
//						SetDimLabel 1, n, $(currentDimLabel), controlInfoWave
					else
//						SetDimLabel 1, n, $(currentDimLabel), controlInfoWave					
					endif
				EndFor
				
				// simulate a click on the Select Panel popmenu that will force a refresh of the list of controls
			
				// determine the currently selected panel and execute the popup action procedure so that the
				// list box will be filled in correctly
				ControlInfo/W=$(lba.win) popupPanelSelect
				if (V_flag == 3)		// this is actually a popup menu--should always be true
					STRUCT WMPopupAction pa
					pa.ctrlName = "popupPanelSelect"
					pa.win = lba.win
					pa.eventCode = 2
					pa.popNum = V_Value
					pa.popStr = S_Value
					FUNCREF ACLUserDataEditorProtoFunc actionproc = PopMenuSelectPanel
					actionproc(pa)
				endif
			
			endif
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			// create variables that represent the colum indices of the 3 columns of the wave
			Variable ctrlNameCol, tabnumCol, tabcontrolCol
			numCols = DimSize(controlInfoWave, 1)
			For (n=0; n<numCols; n+=1)
				currentDimLabel = GetDimLabel(controlInfoWave, 1, n)
				if (stringmatch(currentDimLabel, "*Control Name*") == 1)
					ctrlNameCol = n
				elseif (stringmatch(currentDimLabel, "*key left*") == 1)
					tabnumCol = n
				elseif (stringmatch(currentDimLabel, "*key right*") == 1)
					tabcontrolCol = n
				endif
			EndFor
			
			// Build the full control name, including parent panel, and then parse into full window
			// path and actual control name of selected row.  If "control" in selected row is a window
			// and not actually a control, this call will return incorrect values, however that possibility
			// will be checked for in the else statement below.
			String currentControlName = panel + "#" + controlInfoWave[lba.row][ctrlNameCol]
			String windowName = "", controlName = "", displayName = ""
			ParseFullControlName(currentControlName, windowName, controlName, displayName)
			
			ControlInfo/W=$lba.win popupSelectColumn0
			keyLeft = S_Value
			ControlInfo/W=$lba.win popupSelectColumn1
			keyRight = S_Value
			keyLeft = SelectString(!CmpStr(keyLeft, EMPTY_USERDATA), keyLeft, "")
			keyRight = SelectString(!CmpStr(keyRight, EMPTY_USERDATA), keyRight, "")

			// make sure the control exists and if not check to see if it is a window
			ControlInfo/W=$(windowName) $(controlName)
			if (abs(V_Flag) > 0)
				// control exists
				if(lba.col == tabnumCol)
					ModifyControl $(controlName), win=$(windowName), userdata($keyLeft)=controlInfoWave[lba.row][tabnumCol]
				elseif(lba.col == tabcontrolCol)
					ModifyControl $(controlName), win=$(windowName), userdata($keyRight)=controlInfoWave[lba.row][tabcontrolCol]
				endif
			else
				// see if this is a window
				sprintf potentialWindowName, "%s#%s", windowName, controlName
				windowType = WinType(potentialWindowName)
				Switch (windowType)
					Case 0:		// no window by that name
						// do nothing
						break
					Case 1:		// window is a graph
					Case 2:		// window is a table
					Case 3:		// window is a layout
					Case 5:		// window is a notebook
					Case 7:		// window is a panel
					Case 13:	// window is an XOP target window
					default:
						if(lba.col == tabnumCol)
							SetWindow $(potentialWindowName), userdata($keyLeft) = controlInfoWave[lba.row][tabnumCol]
						elseif(lba.col == tabcontrolCol)
							SetWindow $(potentialWindowName), userdata($keyRight) = controlInfoWave[lba.row][tabcontrolCol]
						endif
				EndSwitch
			EndIf
		
			break
	endswitch

	SetDataFolder curDataFolder
	return 0
End

Function ButtonRefresh(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	String panel = ba.win
	switch( ba.eventCode )
		case 2: // mouse up
			// determine the currently selected panel and execute the popup action procedure so that the
			// list box will be filled in correctly
			ControlInfo/W=$(ba.win) popupPanelSelect
	
			if (V_flag == 3)		// this is actually a popup menu--should always be true
				STRUCT WMPopupAction pa
				pa.ctrlName = "popupPanelSelect"
				pa.win = ba.win
				pa.eventCode = 2
				pa.popNum = V_Value
				pa.popStr = S_Value
				FUNCREF ACLUserDataEditorProtoFunc actionproc = PopMenuSelectPanel
				actionproc(pa)
			endif
			break
	endswitch

	return 0
End

// ********************
//  AUXILLARY FUNCTIONS
// ********************
Function ACL_FitListToWindow(win, ctrlName)
	// modified from original Wavemetrics function
	String win, ctrlName
	
	GetWindow $win wsize
	Variable winHeight= V_bottom-V_top	// points
	Variable winWidth = V_right-V_left
	winHeight *= ScreenResolution/72	// points to pixels
	winWidth *= ScreenResolution/72	// points to pixels
	
	// make the list span the entire height and width of the panel
	// with the exception of the area for the PopupMenu and the refresh button at the top
	ControlInfo/W=$win $ctrlName

	if( V_Flag )
		// determine size parameters of list box now that the window has been resized
		// S_recreation contains the commands that would recreate the named control.
		// ListBox lb1,pos={42,9},size={137,94},listWave=tjack,selWave=sjack,mode= 3
		String posInfo= StringByKey("pos", S_recreation,"=",",")	// {10,41}
		Variable xpos= str2num(posInfo[1,inf])	// pixels
		String sizeInfo= StringByKey("size", S_recreation,"=",",")	// {338,246}
		//Variable width= str2num(sizeInfo[1,inf])	// pixels
		
		// if the window is tall enough that there is extra space at the bottom of the listbox
		// that is not filled in with rows, change the top displayed row so that all space is
		// taken up
		String waveNameStr = StringByKey("listwave", S_recreation, "=", ",")		
		if (strlen(waveNameStr) > 0)	// the name of the list wave is set
			WAVE/T listWave = $(waveNameStr)
			Variable numRows = DimSize(listWave, 0)
			if ((numRows - V_StartRow) < (round(V_height/V_RowHeight)))
				Variable newStartRow = ceil(numRows - (V_height/V_RowHeight)) + 1		// scroll box up automatically
			else
				newStartRow = V_StartRow		// don't change starting row			
			endif
		endif	
		// save changes to list box		
		ListBox $ctrlName, win=$(win), pos={xpos,68},size={winWidth - 20,winHeight-75}, row=newStartRow	// leave some margin for focus rectangle
	endif
End

Function ACL_MinWindowSize(winName,minwidth,minheight)
	// modified from original wavemetrics function
	String winName
	Variable minwidth,minheight

	GetWindow $winName wsize
	Variable width= max(V_right-V_left,minwidth)
	Variable height= max(V_bottom-V_top,minheight)
	MoveWindow/W=$winName V_left, V_top, V_left+width, V_top+height
End

//**
// Recursively build a list of windows, including all child
// windows, starting with wName.
//
// @param wName
// 	Parent window to start with.
// @param windowList
// 	A string containing names of windows.  This list is
// 	a semicolon separated list.  It will include the window
// 	wName and all of its children and children of children, etc.
// 	Note:  This parameter is passed by reference.
//*
Function GetAllWindows(wName, windowList)
	String wName
	String &windowList
	
	// Add the target window to the list of windows.
	windowList = AddListItem(wName, windowList, ";", inf)
	
	// Recursively call this function on any children windows.
	String children = ChildWindowList(wName)
	Variable numChildren = ItemsInList(children, ";")
	Variable n
	For (n=0; n<numChildren; n+=1)
		GetAllWindows(wName + "#" + StringFromList(n, children, ";"), windowList)
	EndFor
End

//**
// Get a semicolon separated list of all controls on a particular window prefixed
// with the name of the window.  This function only returns controls on the
// immediate window, not any child windows.
//
// For example, if wName is "Panel1#Child1#Child2", then
// the listOfControls might look like this:
// "Panel1#Child1#Child2#button0;Panel1#Child1#Child2#button1;"
//  
// @param wName
// 	Target window name, using standard subwindow syntax if necessary.
//
// @return
// 	A semicolon separated list of controls on the window.
//*
Function/S GetAllControls(wName)
	String wName
	
	String controls = ControlNameList(wName, ";", "*")
	Variable numControls = ItemsInList(controls, ";")
	String listOfControls = ""
	Variable n
	For (n=0; n<numControls; n+=1)
		listOfControls = AddListItem(wName + "#" + StringFromList(n, controls, ";"), listOfControls, ";", inf)
	EndFor
	return listOfControls	
End

//**
// Parse a complete control name, including the full window path, into
// separate parts.
//
// Note:  This function will also work when fullName is not actually
// the name of a control but just the name of a window.  However,
// the values of windowName and controlName that are set will
// not make sense.
//
// @param fullName
// 	The full name of a control or window.  For example,
// 	"Panel0#SW0#SW0_0#button0
// @param windowName
// 	The full path to the window on which the control is placed.
// 	For example, "Panel0#SW0#SW0_0".
// 	This parameter is passed by reference.
// @param controlName
// 	The name of the control.
// 	For example, "button0".
// 	This parameter is passed by reference.
// @param displayName
// 	The name of the control that should be used in the Userdata Editor
// 	list wave.  This is the full name without the parent window name.
// 	For example, "SW0#SW0_0#button0".
// 	This parameter is passed by reference.
//*
Function ParseFullControlName(fullName, windowName, controlName, displayName)
	String fullName
	String &windowName
	String &controlName
	String &displayName
	
	Variable numParts = ItemsInList(fullName, "#")
	controlName = StringFromList(numParts - 1, fullName, "#")
	windowName = RemoveEnding(RemoveListItem(numParts -1, fullName, "#"), "#")	
	displayName = RemoveListItem(0, fullName, "#")
End

// ********************
//  HOOK FUNCTIONS
// ********************
Function ACL_UserDataEditorHook(str)
	STRUCT WMWinHookStruct &str
	Variable statusCode = 0
	Switch (str.eventCode)
		Case 2:		// window is being killed
			// delete the panel's data folder
			ControlUpdate/A/W=$(str.winName)
			if (DataFolderExists("root:Packages:ACL_UserDataEditor"))
				Execute/P/Q/Z "KillDataFolder root:Packages:ACL_UserDataEditor"
			endif

			return 0
			break
		Case 6:		// window is being resized
			// resize the list box control if the window itself is resized
			// NOTE:  code below and auxillary functions taken from Wavemetrics
			// Examples -> Testing & Misc -> Resize Panel and List Demo
			ACL_MinWindowSize(str.winName,(355*72/ScreenResolution),(200*72/ScreenResolution))	// make sure the window isn't too small
			ACL_FitListToWindow(str.winName,"listPanelControls")
			statusCode=1
			break;
		default:
			
	EndSwitch
	return statusCode
End

// ********************
//  UTILITY FUNCTIONS
// ********************
Function/S ACL_ControlTypeName(controlType)
	variable controlType

	if(numtype(controlType) == 2)
		return ""
	endif
	controlType = abs(controlType)
	if(controlType == 1)
		return "Button"
	elseif(controlType == 6)
		return "Chart"
	elseif(controlType == 2)
		return "CheckBox"
	elseif(controlType == 12)
		return "CustomControl"
	elseif(controlType == 9)
		return "GroupBox"
	elseif(controlType == 11)
		return "ListBox"
	elseif(controlType == 3)
		return "PopupMenu"
	elseif(controlType == 5)
		return "SetVariable"
	elseif(controlType == 7)
		return "Slider"
	elseif(controlType == 8)
		return "TabControl"
	elseif(controlType == 10)
		return "TitleBox"
	elseif(controlType == 4)
		return "ValDisplay"
	endif

	return ""
End

Function/S ACL_RecreationFilter(recMacro, controlTypes)
	string recMacro
	variable controlTypes

	string controlName, grepFilter

	if(numtype(controlTypes) == 2)
		return recMacro
	endif

	controlName = ACL_ControlTypeName(controlTypes)
	grepFilter = "(?i)^[[:space:]](" + controlName + ").*"
	return GrepList(recMacro, grepFilter, 0, "\r")
End

Function/S ACL_GetUserdataKeys(wName, controlTypes)
	string wName
	variable controlTypes

	string userKeys = ""
	string recMacro, key
	variable pos1, pos2

	recMacro = WinRecreation(wName, 0)
	recMacro = ACL_RecreationFilter(recMacro, controlTypes)
	do
		pos1 = strsearch(recMacro, "userdata(", pos1)
		if(pos1 == -1)
			break
		endif
		pos2 = strsearch(recMacro, ")", pos1)
		key = recMacro[pos1 + 9, pos2 - 1]
		userKeys = AddListItem(key, userKeys, ";", Inf)
		pos1 = pos2
	while(1)

	if(!isEmpty(userKeys))
		Wave/T w = ListToTextWave(userKeys, ";")
		FindDuplicates/FREE /RT=wClean w
		wfprintf userKeys, "%s;", wClean
	endif

	return userKeys
End

/// @brief Returns one if str is empty or null, zero otherwise.
/// @param str must not be a SVAR
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe static Function IsEmpty(str)
	string& str

	variable len = strlen(str)
	return numtype(len) == 2 || len <= 0
End
