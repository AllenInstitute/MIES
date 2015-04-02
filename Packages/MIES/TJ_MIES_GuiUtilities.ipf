#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static constant DISABLE_CONTROL_BIT = 2
static constant HIDDEN_CONTROL_BIT  = 1

Constant CHECKBOX_SELECTED     = 1
Constant CHECKBOX_UNSELECTED   = 0
 
/// @brief Show a GUI control in the given window
Function ShowControl(win, control)
	string win, control

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")

	if((V_disable & HIDDEN_CONTROL_BIT) == 0)
		return NaN
	endif

	ModifyControl $control win=$win, disable=(V_disable & ~HIDDEN_CONTROL_BIT)
End

/// @brief Show a list of GUI controls in the given window
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

/// @brief Hide a GUI control in the given window
Function HideControl(win, control)
	string win, control

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")

	if(V_disable & HIDDEN_CONTROL_BIT)
		return NaN
	endif

	ModifyControl $control win=$win, disable=(V_disable | HIDDEN_CONTROL_BIT)
End

/// @brief Hide a list of GUI controls in the given window
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

/// @brief Enable a GUI control in the given window
Function EnableControl(win, control)
	string win, control

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")

	if( (V_disable & DISABLE_CONTROL_BIT) == 0)
		return NaN
	endif

	ModifyControl $control win=$win, disable=(V_disable & ~DISABLE_CONTROL_BIT)
End

/// @brief Enable a list of GUI controls in the given window
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

/// @brief Disable a GUI control in the given window
Function DisableControl(win, control)
	string win, control

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")

	if(V_disable & DISABLE_CONTROL_BIT)
		return NaN
	endif

	ModifyControl $control win=$win, disable=(V_disable | DISABLE_CONTROL_BIT)
End

/// @brief Disable a list of GUI controls in the given window
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

/// @brief Set the title of a control
Function SetControlTitle(win, controlName, newTitle)
	string win, controlName, newTitle

	ControlInfo/W=$win $controlName
	ASSERT(V_flag != 0, "Non-existing control or window")

	ModifyControl $ControlName WIN = $win, title = newTitle
End

/// @brief Change color of a control
Function SetControlTitleColor(win, controlName, R, G, B) ///@todo store color in control user data, check for color change before applying change
	string win, controlName
	variable R, G, B

	ControlInfo/W=$win $controlName
	ASSERT(V_flag != 0, "Non-existing control or window")

	ModifyControl $ControlName WIN = $win, fColor = (R,G,B)
End

/// @brief Change color of a control
Function ChangeControlColor(win, controlName, R, G, B)
	string win, controlName
	variable R, G, B
	
	ControlInfo/W=$win $controlName
	ASSERT(V_flag != 0, "Non-existing control or window")	
	
	ModifyControl $ControlName WIN = $win, fColor = (R,G,B)

End

/// @brief Change the font color of a control
Function ChangeControlValueColor(win, controlName, R, G, B)
	string win, controlName
	variable R, G, B
	
	ControlInfo/W=$win $controlName
	ASSERT(V_flag != 0, "Non-existing control or window")	
	
	ModifyControl $ControlName WIN = $win, valueColor = (R,G,B)

End

/// @brief Change the font color of a list of controls
Function ChangeListOfControlValueColor(win, controlList, R, G, B)
	string win, controlList
	variable R, G, B
	variable i
	variable numItems = ItemsInList(controlList)
	string ctrl
	for(i=0; i < numItems; i+=1)
		ctrl = StringFromList(i,controlList)
		ControlInfo/W=$win $ctrl
		ASSERT(V_flag != 0, "Non-existing control or window")	
	//	ChangeControlValueColor(win, ctrl, R, G, B)
	endfor
	
	ModifyControlList controlList, WIN = $win, valueColor = (R,G,B)
	
End

/// @brief Changes the background color of a control
Function ChangeControlBckgColor(win, controlName, R, G, B)
	string win, controlName
	variable R, G, B
	
	ControlInfo/W=$win $controlName
	ASSERT(V_flag != 0, "Non-existing control or window")	
	
	ModifyControl $ControlName WIN = $win, valueBackColor = (R,G,B)

End

/// @brief Change the background color of a list of controls
Function ChangeListOfControlBckgColor(win, controlList, R, G, B)
	string win, controlList
	variable R, G, B
	variable i
	variable numItems = ItemsInList(controlList)
	string ctrl
	for(i=0; i < numItems; i+=1)
		ctrl = StringFromList(i,controlList)
		ControlInfo/W=$win $ctrl
		ASSERT(V_flag != 0, "Non-existing control or window")	
	//	ChangeControlValueColor(win, ctrl, R, G, B)
	endfor
	
	ModifyControlList controlList, WIN = $win, valueBackColor = (R,G,B)
	
End

/// @name Control types from ControlInfo
/// @{
Constant CONTROL_TYPE_CHECKBOX    = 2
Constant CONTROL_TYPE_POPUPMENU   = 3
Constant CONTROL_TYPE_VALDISPLAY  = 4
Constant CONTROL_TYPE_SETVARIABLE = 5
Constant CONTROL_TYPE_SLIDER      = 7
/// @}

/// @brief Returns control disable state
Function GetControlDisable(win, control)
	string win, control

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	return V_disable
End

/// @brief Returns one if the checkbox is selected, zero if it is unselected
/// and, if allowMissingControl is true, NaN for non existing controls.
///
/// Checking non existing controls is useful to support old panels
/// stored in experiments which don't have the control.
Function GetCheckBoxState(win, control, [allowMissingControl])
	string win, control
	variable allowMissingControl

	ControlInfo/W=$win $control
	if(ParamIsDefault(allowMissingControl) || allowMissingControl == 0)
		ASSERT(V_flag != 0, "Non-existing control or window")
		ASSERT(V_flag == CONTROL_TYPE_CHECKBOX, "Control is not a checkbox")
		return V_Value
	else
		if(V_flag == 0) // control/window is missing
			ASSERT(windowExists(win), "missing window")
			return NaN
		else
			ASSERT(V_flag == CONTROL_TYPE_CHECKBOX, "Control is not a checkbox")
			return V_Value
		endif
	endif
End

/// @brief Set the internal number in a setvariable control
Function SetSetVariable(win,Control, newValue)
	string win, control
	variable newValue

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_SETVARIABLE, "Control is not a setvariable")
	if(newValue != v_value)
		SetVariable $control, win = $win, value =_NUM:newValue
	endif
End

Function SetSetVariableString(win,Control, newString)
	string win, control, newString

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_SETVARIABLE, "Control is not a setvariable")

	SetVariable $control, win = $win, value =_STR:newString
End

/// @brief Set the state of the checkbox
Function SetCheckBoxState(win,control,state)
	string win, control
	variable state

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_CHECKBOX, "Control is not a checkbox")
	
	state = !!state
	
	if(state != V_Value)
		CheckBox $control, win=$win, value=(state==CHECKBOX_SELECTED)
	endif
	
End

/// @brief Returns the contents of a SetVariable
Function GetSetVariable(win, control)
	string win, control

	ControlInfo/W=$win $control	
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_SETVARIABLE, "Control is not a setvariable")
	return V_Value
end

/// @brief Returns the contents of a SetVariable with an internal string
Function/S GetSetVariableString(win, control)
	string win, control

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_SETVARIABLE, "Control is not a setvariable")
	return S_Value
end

/// @brief Returns the current PopupMenu item as string
Function/S GetPopupMenuString(win, control)
	string win, control

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_POPUPMENU, "Control is not a popupmenu")
	return S_Value
End

/// @brief Returns the zero-based index of a PopupMenu
Function GetPopupMenuIndex(win, control)
	string win, control

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_POPUPMENU, "Control is not a popupmenu")
	ASSERT(V_Value >= 1,"Invalid index")
	return V_Value - 1
End

/// @brief Sets the zero-based index of the PopupMenu
Function SetPopupMenuIndex(win, control, index)
	string win, control
	variable index
	index += 1

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_POPUPMENU, "Control is not a popupmenu")
	ASSERT(index >= 0,"Invalid index")
	if(index != v_value)
		PopupMenu $control win=$win, mode=index
	endif
End

/// @brief Sets the popupmenu value
Function SetPopupMenuVal(win, control, List)
	string win, control
	string List
	string outputList

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_POPUPMENU, "Control is not a popupmenu")
	sprintf outputList, "\"%s\"" List
	ASSERT(strlen(outputList) < 400, "Popop menu list is greater than 400 characters")
	PopupMenu $control win=$win, value = #outputList
End	

/// @brief Returns the contents of a ValDisplay
Function/S GetValDisplayAsString(win, control)
	string win, control

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_VALDISPLAY, "Control is not a val display")
	return S_value
End

/// @brief Returns the contents of a ValDisplay as a number
Function GetValDisplayAsNum(win, control)
	string win, control

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_VALDISPLAY, "Control is not a val display")
	return V_Value
End

/// @brief Returns the slider position
Function GetSliderPositionIndex(win, control)
	string win, control

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_SLIDER, "Control is not a slider")
	return V_value
End

/// @brief Sets the slider position
Function SetSliderPositionIndex(win, control, index)
	string win, control
	variable index
	
	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_SLIDER, "Control is not a slider")
	Slider $control win=$win, value = index
End

/// @brief Set a ValDisplay
///
/// The variable var can be formatted using format.
Function SetValDisplaySingleVariable(win, control, var, [format])
	string win, control
	variable var
	string format

	string formattedString

	if(ParamIsDefault(format))
		formattedString = num2istr(var)
	else
		sprintf formattedString, format, var
	endif

	// Don't update if the content does not change, prevents flickering
	if(CmpStr(GetValDisplayAsString(win, control), formattedString) == 0)
		return NaN
	endif

	ValDisplay $control win=$win, value=#formattedString
End

/// @brief Change the active tab of a panel
///
/// @param panel    window name, tabs must be managed with Adam's Tab Control procedures
/// @param ctrl     name of the TabControl
/// @param tabID    tab index (zero-based)
Function ChangeTab(panel, ctrl, tabID)
	string panel, ctrl
	variable tabID

	Struct WMTabControlAction tca

	tca.win	= panel
	tca.ctrlName = ctrl
	tca.eventCode = 2
	tca.tab = tabID

	return ACL_DisplayTab(tca)
End

/// @brief Returns the number of the current tab
///
/// @param win	window name
/// @param ctrl	name of the control
Function GetTabID(win, ctrl)
	string win, ctrl
	
	ControlInfo/W=$win $ctrl
	ASSERT(V_flag != 0, "Non-existing control or window")
	return V_value
End

/// @brief Set value as the user data named key
///
/// @param win     window name
/// @param control name of the control
/// @param key     user data identifier
/// @param value   user data value
Function SetControlUserData(win, control, key, value)
	string win, control, key, value

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ModifyControl $control win=$win, userdata($key)=value
End

/// @brief Get a nice trace color for a given index
///
/// Holds ten different trace colors, borrowed from KBColorizeTraces.ipf
Function GetTraceColor(index, red, green, blue)
	variable index
	variable &red, &green, &blue

	index = mod(index, 10) // Wrap after 10 traces.
	switch(index)
		case 0:
			red = 0; green = 0; blue = 0;
			break

		case 1:
			red = 65535; green = 16385; blue = 16385;
			break

		case 2:
			red = 2; green = 39321; blue = 1;
			break

		case 3:
			red = 0; green = 0; blue = 65535;
			break

		case 4:
			red = 39321; green = 1; blue = 31457;
			break

		case 5:
			red = 48059; green = 48059; blue = 48059;
			break

		case 6:
			red = 65535; green = 32768; blue = 32768;
			break

		case 7:
			red = 0; green = 65535; blue = 0;
			break

		case 8:
			red = 16385; green = 65535; blue = 65535;
			break

		case 9:
			red = 65535; green = 32768; blue = 58981;
			break
	endswitch
End

/// @brief Query the axis minimum and maximum values
///
/// For none existing graph, axis or an autoscaled axis
/// NaN is returned for minimum and high.
///
/// @param[in]  graph    graph name
/// @param[in]  axis     axis name
/// @param[out] minimum  minimum value of the axis range
/// @param[out] maximum  maximum value of the axis range
Function GetAxisRange(graph, axis, minimum, maximum)
	string graph, axis
	variable &minimum, &maximum

	string info, flags

	minimum  = NaN
	maximum = NaN

	if(!windowExists(graph))
		return NaN
	endif

	info  = AxisInfo(graph, axis)
	flags = StringByKey("SETAXISFLAGS", info)

	// only set the axis range
	// - if the specified axis exists
	// - it is not autoscaled
	if(!isEmpty(info) && isEmpty(flags))
		GetAxis/W=$graph/Q $axis
		minimum = V_min
		maximum = V_max
	endif
End

/// @name Constants for GetAxisOrientation
/// @{
static Constant AXIS_ORIENTATION_LEFT   = 0x01
static Constant AXIS_ORIENTATION_RIGHT  = 0x02
static Constant AXIS_ORIENTATION_BOTTOM = 0x04
static Constant AXIS_ORIENTATION_TOP    = 0x08
/// @}

/// @brief Return the orientation of the axis as numeric value
Function GetAxisOrientation(graph, axes)
	string graph, axes

	string orientation

	orientation = StringByKey("AXTYPE", AxisInfo(graph, axes))

	strswitch(orientation)
		case "left":
			return AXIS_ORIENTATION_LEFT
			break
		case "right":
			return AXIS_ORIENTATION_RIGHT
			break
		case "bottom":
			return AXIS_ORIENTATION_BOTTOM
			break
		case "top":
			return AXIS_ORIENTATION_TOP
			break
	endswitch

	Abort "unknown axis type"
End

/// @brief Returns a wave with the minimum and maximum
/// values of each axis
///
/// Use SetAxesRanges to set the minimum and maximum values
/// @see GetAxisRange
Function/Wave GetAxesRanges(graph)
	string graph

	string list, axis, orientation
	variable numAxes, i, minimum, maximum

	list    = AxisList(graph)
	list    = SortList(list)
	numAxes = ItemsInList(list)

	Make/FREE/D/N=(numAxes, 3) ranges = 0
	SetDimLabel COLS, 0, minimum , ranges
	SetDimLabel COLS, 1, maximum , ranges
	SetDimLabel COLS, 2, axisType, ranges

	for(i = 0; i < numAxes; i += 1)
		axis = StringFromList(i, list)
		SetDimLabel ROWS, i, $axis, ranges
		ranges[i][%axisType] = GetAxisOrientation(graph, axis)

		GetAxisRange(graph, axis, minimum, maximum)
		ranges[i][%minimum] = minimum
		ranges[i][%maximum] = maximum
	endfor

	return ranges
End

/// @brief Set the range of all axes as stored by GetAxesRange
///
/// Includes a heuristic if the name of the axis changed after GetAxesRange.
/// The axis range is also restored if its index in the sorted axis list and its
/// orientation is the same.
/// @see GetAxisRange
Function SetAxesRanges(graph, ranges)
	string graph
	Wave ranges

	variable numRows, i, minimum, maximum, row, numAxes
	string axis, list

	ASSERT(windowExists(graph), "Graph does not exist")
	numRows = DimSize(ranges, ROWS)

	list    = AxisList(graph)
	list    = SortList(list)
	numAxes = ItemsInList(list)

	for(i = 0; i < numAxes; i += 1)
		axis = StringFromList(i, list)

		row = FindDimLabel(ranges, ROWS, axis)

		if(row >= 0)
			minimum = ranges[row][%minimum]
			maximum = ranges[row][%maximum]
		else
			// axis does not exist, lets just try the axis at the current index
			// and check if the orientation is correct
			if(i < numRows && GetAxisOrientation(graph, axis) == ranges[i][%axisType])
				minimum = ranges[i][%minimum]
				maximum = ranges[i][%maximum]
			else
				continue
			endif
		endif

		if(!IsFinite(minimum) || !IsFinite(maximum))
			continue
		endif

		SetAxis/W=$graph $axis, minimum, maximum
	endfor
End

/// @brief Returns the next axis name in a row of *consecutive*
/// and already existing axis names
Function/S GetNextFreeAxisName(graph, axesBaseName)
	string graph, axesBaseName

	variable numAxes

	numAxes = ItemsInList(ListMatch(AxisList(graph), axesBaseName + "*"))

	return axesBaseName + num2str(numAxes)
End

/// @brief Generic wrapper for setting a control's value 
/// pass in the value as a string, and then decide whether to change to a number based on the type of control
Function SetGuiControlValue(win, control, value)
	string win, control
	string value

	variable controlType

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	controlType = abs(V_flag)

	if(controlType == 2)
		SetCheckBoxState(win, control, str2num(value))
	elseif(controlType == 5)
		SetSetVariableString(win, control, value)
	elseif(controlType == 7)
		Slider $control, value = str2num(value)		
	else
		print "trying to set this: ", control
		print "to this: ", value
		ASSERT(0, "Unsupported control type") // if I get this, something's really gone pear shaped
	endif
End

/// @brief Generic wrapper for getting a control's value 
Function/S GetGuiControlValue(win, control)
	string win, control
	
	string value
	variable controlType
	
	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	controlType = abs(V_flag)
	
	if(controlType == 2) // Check boxes
		value = num2str(GetCheckBoxState(win, control))
	elseif(controlType == 7) // slider for active headstages
		value = num2str(V_value)
	elseif(controlType == 5) // 
		value = num2str(GetSetVariable(win, control))
		if (cmpstr(value, "NaN") == 0)
			value = GetSetVariableString(win, control)
		endif
	endif
	
	return value
End

/// @brief Generic wrapper for getting a controls state (enabled, hidden, disabled)
Function/S GetGuiControlState(win, control)
	string win, control
	
	string controlState
	
	
	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	controlState = num2str(abs(V_disable))	

	return controlState
End

/// @brief Generic wrapper for setting a controls state (enabled, hidden, disabled)
Function SetGuiControlState(win, control, controlState)
	string win, control
	string controlState

	variable controlType

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	controlType = abs(V_flag)

	if(controlType == 2)
		CheckBox $control, win=$win, disable=str2num(controlState) 
	elseif(controlType == 5)
		SetVariable $control, win = $win, disable = str2num(controlState)
	elseif(controlType == 7)
		Slider $control, win=$win, disable = str2num(controlState)		
	else
		ASSERT(0, "Unsupported control type") // if I get this, something's really gone pear shaped
	endif
End
