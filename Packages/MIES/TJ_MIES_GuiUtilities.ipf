#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static constant DISABLE_CONTROL_BIT = 2
static constant HIDDEN_CONTROL_BIT  = 1

/// Show a GUI control in the given window
Function ShowControl(win, control)
	string win, control

	string errmsg

	ControlInfo/W=$win $control

	if(V_flag == 0)
		sprintf errmsg, "The control %s does not exist in the window %s\r", control, win
		Abort errmsg
	endif

	if((V_disable & HIDDEN_CONTROL_BIT) == 0)
		return NaN
	endif

	ModifyControl $control win=$win, disable=(V_disable & ~HIDDEN_CONTROL_BIT)
End

/// Show a list of GUI controls in the given window
Function ShowListOfControls(win, controlList)
	string win, controlList

	variable i
	variable numItems = ItemsInList(controlList)
	string ctrl
	for(i=0; i < numItems; i+=1)
		ctrl = StringFromList(i,controlList)
		ShowControl(win,ctrl)
	endfor
End

/// Hide a GUI control in the given window
Function HideControl(win, control)
	string win, control

	string errmsg

	ControlInfo/W=$win $control

	if(V_flag == 0)
		sprintf errmsg, "The control %s does not exist in the window %s\r", control, win
		Abort errmsg
	endif

	if(V_disable & HIDDEN_CONTROL_BIT)
		return NaN
	endif

	ModifyControl $control win=$win, disable=(V_disable | HIDDEN_CONTROL_BIT)
End

/// Hide a list of GUI controls in the given window
Function HideListOfControls(win, controlList)
	string win, controlList

	variable i
	variable numItems = ItemsInList(controlList)
	string ctrl
	for(i=0; i < numItems; i+=1)
		ctrl = StringFromList(i,controlList)
		HideControl(win,ctrl)
	endfor
End

/// Enable a GUI control in the given window
Function EnableControl(win, control)
	string win, control

	string errmsg

	ControlInfo/W=$win $control

	if(V_flag == 0)
		sprintf errmsg, "The control %s does not exist in the window %s\r", control, win
		Abort errmsg
	endif

	if( (V_disable & DISABLE_CONTROL_BIT) == 0)
		return NaN
	endif

	ModifyControl $control win=$win, disable=(V_disable & ~DISABLE_CONTROL_BIT)
End

/// Enable a list of GUI controls in the given window
Function EnableListOfControls(win, controlList)
	string win, controlList

	variable i
	variable numItems = ItemsInList(controlList)
	string ctrl
	for(i=0; i < numItems; i+=1)
		ctrl = StringFromList(i,controlList)
		EnableControl(win,ctrl)
	endfor
End

/// Disable a GUI control in the given window
Function DisableControl(win, control)
	string win, control

	string errmsg

	ControlInfo/W=$win $control

	if(V_flag == 0)
		sprintf errmsg, "The control %s does not exist in the window %s\r", control, win
		Abort errmsg
	endif

	if(V_disable & DISABLE_CONTROL_BIT)
		return NaN
	endif

	ModifyControl $control win=$win, disable=(V_disable | DISABLE_CONTROL_BIT)
End

/// Disable a list of GUI controls in the given window
Function DisableListOfControls(win, controlList)
	string win, controlList

	variable i
	variable numItems = ItemsInList(controlList)
	string ctrl
	for(i=0; i < numItems; i+=1)
		ctrl = StringFromList(i,controlList)
		DisableControl(win,ctrl)
	endfor
End
