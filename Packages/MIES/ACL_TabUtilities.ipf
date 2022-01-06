#pragma rtGlobals=1		// Use modern global access method.

// ********************
//  UTILITY FUNCTIONS
// ********************

Function/S ControlNameListByType(winNameStr, listSepStr, matchStr, controlTypeVal)
	// This function behaves in a way similar to the built in function ControlNameList, except
	// this function will return only controls of one type, as specified by controlTypeVal
	// See the Igor Command Help for a list of the controlTypeVal values to pass to the function
	// (pass controlTypeVal such that the V_Flag value returned by ControlInfo matches the type
	// of control you are interested in).
	//
	// All parameters are required.
	String winNameStr, listSepStr, matchStr
	Variable controlTypeVal

	// make sure window exists
	if (WinType(winNameStr) == 0)
		return ""		// window doesn't exist
	endif

	String controls = ControlNameList(winNameStr, listSepStr, matchStr)
	Variable n, numControls
	String typeControls = ""		// list of controls of the specified type
	String currentControlName
	numControls = ItemsInList(controls, listSepStr)
	For (n=0; n<numControls; n+=1)
		currentControlName = StringFromList(n, controls, listSepStr)
		ControlInfo/W=$(winNameStr) $(currentControlName)
		if (abs(V_Flag) == controlTypeVal)
			typeControls += currentControlName + listSepStr
		endif
	EndFor
	return typeControls
End

Function ACL_SetControlDisableStatus(panel, currentControl, tabControlName, newTabNum)
	String &panel			// REFERENCE:  name of window with control
	String &currentControl		// REFERENCE:  name of control
	String &tabControlName	// REFERENCE:  name of tab control that originally prompted the action procedure
	Variable &newTabNum	// REFERENCE:  number of the new tab that has been selected

	// declare variables
	Variable tabNumber
	Variable windowType
	Variable windowHide
	Variable controlDisable
	String potentialWindowName
	String controllingTab

	ControlInfo/W=$(panel) $(currentControl)
	// tabs are a special case since we want to change the value, not the disable status
	if (abs(V_flag == 8) && cmpstr(currentControl, tabControlName) == 0)		// this control is a tab
		TabControl $(currentControl) win=$(panel), value=(newTabNum)
	elseif (abs(V_flag) > 0)		// the control exists--this should always be positive unless it's a window
		// see if this control is "controlled" by the current tab control
		// and if so, change it's disable status.  If it's not controlled by the current
		// tab control, then check to see if the tab that controls it is visible.  If so display; if not, ignore
		controllingTab = GetUserData(panel, currentControl, "tabcontrol")
		tabNumber = str2num(GetUserData(panel, currentControl, "tabnum"))
		if (cmpstr(tabControlName, controllingTab) == 0)
			if (numtype(tabNumber) == 0)	// tabnumber userdata is defined
				ModifyControl $(currentControl), win=$(panel), disable=((tabNumber == newTabNum) ? (V_disable & ~0x1) : (V_disable | 0x1))		// clear the hide bit/set the hide bit
			else		// display the control since it's controlled by this tab but should be visible whenever the controlling tab control is visible
				ModifyControl $(currentControl), win=$(panel), disable=(V_disable & ~0x1)		// clear the hide bit
			endif
		elseif (cmpstr(controllingTab, "") != 0)
			// store the V_disable value of the control
			controlDisable = V_disable
			// determine status of controlling tab
			ControlInfo/W=$(panel) $(controllingTab)
			if (abs(V_Flag == 8))		// this is really a tab
				if (V_disable & 0x1)		// if tab hide bit is set
					ModifyControl $(currentControl), win=$(panel), disable= (controlDisable | 0x1)	// set the hide bit of control
				else		// if tab is not hidden
					if (numtype(tabNumber) == 0)	// tabnumber userdata of control is defined
						ModifyControl $(currentControl), win=$(panel), disable=((tabNumber == V_value) ? (controlDisable & ~0x1) : (controlDisable | 0x1))		// clear the hide bit/set the hide bit
					else		// display the control since it's controlled by this tab but should be visible whenever the controlling tab control is visible
						ModifyControl $(currentControl), win=$(panel), disable=(controlDisable & ~0x1)		// clear the hide bit
					endif
				endif
			endif
		endif
	else
		// ************* NOTICE ***************
		// ***** The code below will only work on Igor 6.  If using Igor 5, comment out the block of code starting here
		// ***** and ending below at the END NOTICE text.  On Igor 5, you won't be able to have subwindows on a panel
		// ***** that are controlled by tabs because Igor 5 does not support the hide or needUpdate operation of SetWindow
		// ****************************************
		// see if this is a window, and if so see if it is "controlled" by the current tab control
		// and if so, change the "disable" status.  If it's not controlled by the current
		// tab control, then ignore it.

		sprintf potentialWindowName, "%s#%s", panel, currentControl
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
				controllingTab = GetUserData(potentialWindowName, "", "tabcontrol")
				tabNumber = str2num(GetUserData(potentialWindowName, "", "tabnum"))
				GetWindow $(potentialWindowName) hide
				windowHide = V_Value
				if (cmpstr(tabControlName, controllingTab) == 0)
					if (numtype(tabNumber) == 0)	// tabnumber userdata is defined
						SetWindow $(potentialWindowName) hide=((tabNumber == newTabNum) ? (windowHide & ~0x1) : (windowHide | 0x1)), needUpdate=1		// clear the hide bit/set the hide bit and force update of window
					else		// display the control since it's controlled by this tab but should be visible whenever the controlling tab control is visible
						SetWindow $(potentialWindowName) hide=(windowHide & ~0x1), needUpdate=1		// clear the hide bit and force update of window
					endif
				elseif (cmpstr(controllingTab, "") != 0)
					// determine status of controlling tab
					ControlInfo/W=$(panel) $(controllingTab)
					if (abs(V_Flag == 8))		// this is really a tab
						if (V_disable & 0x1)		// if hide bit is set
							SetWindow $(potentialWindowName) hide=(windowHide | 0x1), needUpdate=1	// set the hide bit and force update of window
						else
							SetWindow $(potentialWindowName) hide=((tabNumber == V_Value) ? (windowHide & ~0x1) : (windowHide | 0x1)), needUpdate=1		// clear the hide bit/set the hide bit and force update of window
						endif
					endif
				EndIf
		EndSwitch
		// ************************************
		// ***** END NOTICE
		// ************************************
	endif
	return 0	// input parameters are passed by reference so there is no need to return the values themselves
End

// ********************
//  FUNCREFs
// ********************
Function ACLTabControlHookProtoFunc(tca)
	STRUCT WMTabControlAction &tca
End

Function TabInitialHook(tca)
	STRUCT WMTabControlAction &tca
	return 0
End

Function TabFinalHook(tca)
	STRUCT WMTabControlAction &tca
	return 1
End

// ********************
//  API FUNCTIONS
// ********************
Function ACL_DisplayTab(tca): TabControl
	// this function will respond to calls from tab controls themselves, but will also work
	// if a WMTabControlAction structure is passed to the function.  This structure can
	// be created in any function.
	//
	// If a structure is passed by another function, the following structure fields must be filled out as follows:
	//	REQUIRED
	//	tca.ctrlName 	--> 	name of tab control which should have the active tab switched
	//	tca.win			-->	window (panel) containing the tab control to be switched
	//	tca.eventCode	-->	pass a value of 2 for tab to be switched.  other values will be ignored
	//	tca.tab			-->	new tab to switch to
	//
	//	OPTIONAL
	//	tca.eventMod		-->	bitfield of modifiers.  See command help for TabControl for more info
	//	tca.userdata		-->	primary (unnamed) user data.  If this is not set correctly this function may not work properly

	STRUCT WMTabControlAction &tca

	// Don't do anything unless tca.eventCode is 2, which is the mouse up event.
	if (tca.eventCode != 2)
		return 0
	endif

	String panel = tca.win
	String tabControlName = tca.ctrlName

	// some of the checks below aren't necessary if the tab control calls this function, but are necessary
	// if another function calls this function, so we'll do them anyway in all cases

	// make sure window exists
	if (WinType(panel) == 0)
		return -1
	endif

	// make sure tab control exists
	ControlInfo/W=$(panel) $(tabControlName)

	if (abs(V_Flag != 8))		// this is not a tab control or the control doesn't exist)
		return -1
	endif

	//	This function supports setting a separate hook function for a tab control that will be executed before the
	//	tab event handling code is executed.  The function name should be stored in the named userdata(initialhook) value
	//	of the tab control.  The function must exist and must return a numerical parameter.  If the returned value is
	//	anything but zero the rest of the tab handling code will not execute.  This could be used to prevent
	//	clicking on a tab from acutally activating the tab, for example.
	String initialhook = (GetUserData(panel, tabControlName, "initialhook"))
	Variable initialReturnType
	Variable initialReturnValue
	if (cmpstr(initialhook, "") != 0)
		String initialhookInfo = FunctionInfo(initialhook)
		if (strlen(initialhookInfo) > 0)
			initialReturnType = NumberByKey("RETURNTYPE", initialhookInfo)
			if (initialReturnType == 4)		// function returns a variable
				FUNCREF ACLTabControlHookProtoFunc InitialHookFunction =$(initialhook)
					initialReturnValue = InitialHookFunction(tca)
					if (initialReturnValue != 0)		// don't allow changing of tab
						// the tab itself has already changed, so we have to reset the selected tab to the value
						// stored in the tab controls userdata(currenttab)
						Variable originalTab = str2num(GetUserData(panel, tabControlName, "currenttab"))
						TabControl $(tabControlName) win=$(panel), value=originalTab		// reset selected tab
						return 1
					endif
			EndIf
		EndIf
	EndIf

	// declare variables
	String controls
	String currentControl
	String potentialWindowName
	String controllingTab
	Variable n, numControls
	Variable tabNumber
	Variable windowType
	Variable windowHide
	Variable controlDisable
	Variable newTabNum = tca.tab

	// first go through and change the disable status of any tabs on the control
	controls = ControlNameListByType(panel, ";", "*", 8)
	numControls = ItemsInList(controls, ";")
	For (n=0; n<numControls; n+=1)
		currentControl = StringFromList(n, controls, ";")
		ACL_SetControlDisableStatus(panel, currentControl, tabControlName, newTabNum)
	EndFor

	controls = ControlNameList(panel, ";", "*")
	// add to the list of controls any child windows of the panel (ie. graphs, etc.)
	controls += ChildWindowList(panel)
	numControls = ItemsInList(controls, ";")
	For (n=0; n<numControls;n+=1)
		currentControl = StringFromList(n, controls, ";")
		ACL_SetControlDisableStatus(panel, currentControl, tabControlName, newTabNum)
	EndFor
	// write the value of the currently displayed tab into the userdata(currenttab) of tab control
	if (newTabNum >= 0)
		TabControl $(tabControlName) win=$(panel), userdata(currenttab)=num2str(newTabNum)
	EndIf

	//	This function supports setting a separate hook function for a tab control that will be executed after the
	//	tab event handling code is executed.  The function name should be stored in the named userdata(finalhook) value
	//	of the tab control.  The function must exist and must return a numerical parameter.  The value returned by this
	// 	hook function, if it exists, will also be returned by this main tab handling action procedure.
	String finalhook = (GetUserData(panel, tabControlName, "finalhook"))
	Variable finalReturnType
	Variable finalReturnValue
	if (cmpstr(finalhook, "") != 0)
		String finalhookInfo = FunctionInfo(finalhook)
		if (strlen(finalhookInfo) > 0)
			finalReturnType = NumberByKey("RETURNTYPE", finalhookInfo)
			if (finalReturnType == 4)		// function returns a variable
				FUNCREF ACLTabControlHookProtoFunc finalhookFunction =$(finalhook)
				finalReturnValue = finalhookFunction(tca)
				return finalReturnValue
			EndIf
		EndIf
	EndIf
	return 0
End

