#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_GUI
#endif

/// @file MIES_GuiUtilities.ipf
/// @brief Helper functions related to GUI controls

static StrConstant USERDATA_PREFIX = "userdata("
static StrConstant USERDATA_SUFFIX = ")"

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
Function ShowControls(win, controlList)
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
Function HideControls(win, controlList)
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
Function EnableControls(win, controlList)
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
Function DisableControls(win, controlList)
	string win, controlList

	variable i
	variable numItems = ItemsInList(controlList)
	string ctrl
	for(i=0; i < numItems; i+=1)
		ctrl = StringFromList(i,controlList)
		DisableControl(win,ctrl)
	endfor
End

/// @brief Set the title of a list of controls
Function SetControlTitles(win, controlList, controlTitleList)
	string win, controlList, controlTitleList

	variable i
	variable numItems = ItemsInList(controlList)
	ASSERT(numItems <= ItemsInList(controlTitleList), "List of control titles is too short")
	string controlName, newTitle
	for(i=0; i < numItems; i+=1)
		controlName = StringFromList(i,controlList)
		newTitle = StringFromList(i,controlTitleList)
		SetControlTitle(win, controlName, newTitle)
	endfor
End

/// @brief Set the title of a control
Function SetControlTitle(win, controlName, newTitle)
	string win, controlName, newTitle

	ControlInfo/W=$win $controlName
	ASSERT(V_flag != 0, "Non-existing control or window")

	ModifyControl $ControlName WIN = $win, title = newTitle
End

/// @brief Set the procedure of a list of controls
Function SetControlProcedures(win, controlList, newProcedure)
	string win, controlList, newProcedure

	variable i
	string controlName
	variable numItems = ItemsInList(controlList)

	for(i = 0; i < numItems; i += 1)
		controlName = StringFromList(i, controlList)
		SetControlProcedure(win, controlName, newProcedure)
	endfor
End

/// @brief Set the procedure of a control
Function SetControlProcedure(win, controlName, newProcedure)
	string win, controlName, newProcedure

	ControlInfo/W=$win $controlName
	ASSERT(V_flag != 0, "Non-existing control or window")

	ModifyControl $ControlName WIN = $win, proc = $newProcedure
End

/// @brief Return the title of a control
///
/// @param recMacro     recreation macro for ctrl
/// @param supress      supress assertion that ctrl must have a title
/// @return Returns     the title or an empty string
Function/S GetTitle(recMacro, [supress])
 	string recMacro
 	variable supress
 
 	string title, errorMessage

 	if(ParamIsDefault(supress))
 		supress = 0
 	endif
    
    // [^\"\\\\] matches everything except escaped quotes
    // \\\\.     eats backslashes
    // [^\"\\\\] up to the next escaped quote
    // does only match valid strings
 	SplitString/E="(?i)title=\"([^\"\\\\]*(?:\\\\.[^\"\\\\]*)*)\"" recMacro, title
 
 	if(!V_Flag)
	 	sprintf errorMessage, "recreation macro %.30s does not contain a title", recMacro
 		ASSERT(supress, errorMessage)
 	endif
 
  	return title
End

/// @brief Change color of the title of mulitple controls
Function SetControlTitleColors(win, controlList, R, G, B)
	string win, controlList
	variable R, G, B

	variable i
	variable numItems = ItemsInList(controlList)
	string controlName
	for(i=0; i < numItems; i+=1)
		controlName = StringFromList(i,controlList)
		SetControlTitleColor(win, controlName, R, G, B)
	endfor
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
Function ChangeControlValueColors(win, controlList, R, G, B)
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
///
/// @param win         panel
/// @param controlName GUI control name
/// @param R           red
/// @param G           green
/// @param B           blue
/// @param Alpha defaults to opaque if not provided
Function SetControlBckgColor(win, controlName, R, G, B, [Alpha])
	string win, controlName
	variable R, G, B, Alpha
	
	if(paramIsDefault(Alpha))
		Alpha = 1
	Endif
	ASSERT(Alpha > 0 && Alpha <= 1, "Alpha must be between 0 and 1")
	Alpha *= 65535
	ControlInfo/W=$win $controlName
	ASSERT(V_flag != 0, "Non-existing control or window")	

	ModifyControl $ControlName WIN = $win, valueBackColor = (R,G,B,Alpha)
End

/// @brief Change the background color of a list of controls
Function ChangeControlBckgColors(win, controlList, R, G, B)
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

/// @brief Returns one if the checkbox is selected or zero if it is unselected
Function GetCheckBoxState(win, control)
	string win, control
	variable allowMissingControl

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(V_flag == CONTROL_TYPE_CHECKBOX, "Control is not a checkbox")
	return V_Value
End

/// @brief Set the internal number in a setvariable control
Function SetSetVariable(win,Control, newValue, [respectLimits])
	string win, control
	variable newValue
	variable respectLimits
	
	if(ParamIsDefault(respectLimits))
		respectLimits = 0
	endif
	
	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_SETVARIABLE, "Control is not a setvariable")

	if(respectLimits)
		newValue = GetLimitConstrainedSetVar(win, control, newValue)
	endif

	if(newValue != v_value)
		SetVariable $control, win = $win, value =_NUM:newValue
	endif
	
	return newValue
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

/// @brief Set the input limits for a setVariable control
Function SetSetVariableLimits(win, Control, low, high, increment)
	string win, control
	variable low, high, increment

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_SETVARIABLE, "Control is not a setvariable")

	SetVariable $control, win = $win, limits={low,high,increment}
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
	PopupMenu $control win=$win, mode=index
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
	ASSERT(strlen(outputList) < MAX_COMMANDLINE_LENGTH, "Popop menu list is greater than MAX_COMMANDLINE_LENGTH characters")
	PopupMenu $control win=$win, value = #outputList
End

/// @brief Sets the popupmenu string
///
/// @param win     target window
/// @param control target control
/// @param str     popupmenu string to select. Supports wildcard character(*)
///
/// @return set string with wildcard expanded
Function/S SetPopupMenuString(win, control, str)
	string win, control
	string str

	string result

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_POPUPMENU, "Control is not a popupmenu")
	PopupMenu $control win=$win, popmatch = str

	result = GetPopupMenuString(win, control)
	ASSERT(stringMatch(result, str), "str is not in the popupmenu list")

	return result
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
/// @param win     panel
/// @param control GUI control
/// @param var     numeric variable to set
/// @param format  format string referencing the numeric variable `var`
/// @param str     path to global variable or wave element
///
/// The following parameter combinations are valid:
/// - `var`
/// - `var` and `format`
/// - `str`
Function SetValDisplay(win, control, [var, str, format])
	string win, control
	variable var
	string str, format

	string formattedString

	if(!ParamIsDefault(format))
		ASSERT(ParamIsDefault(str), "Unexpected parameter combination")
		ASSERT(!ParamIsDefault(var), "Unexpected parameter combination")
		sprintf formattedString, format, var
	elseif(!ParamIsDefault(var))
		ASSERT(ParamIsDefault(str), "Unexpected parameter combination")
		ASSERT(ParamIsDefault(format), "Unexpected parameter combination")
		sprintf formattedString, "%g", var
	elseif(!ParamIsDefault(str))
		ASSERT(ParamIsDefault(var), "Unexpected parameter combination")
		ASSERT(ParamIsDefault(format), "Unexpected parameter combination")
		formattedString = str
	else
		ASSERT(0, "Unexpected parameter combination")
	endif

	// Don't update if the content does not change, prevents flickering
	if(CmpStr(GetValDisplayAsString(win, control), formattedString) == 0)
		return NaN
	endif

	ValDisplay $control win=$win, value=#formattedString
End

/// @brief Check if a given control exists
Function ControlExists(win, control)
	string win, control

	ControlInfo/W=$win $control
	return V_flag != 0
End

/// @brief Return the full subwindow path to the windows the control belongs to
Function/S FindControl(control)
	string control

	string windows, childWindows, childWindow, win
	variable i, j, numWindows, numChildWindows
	string matches = ""

	// search in all panels and graphs
	windows = WinList("*", ";", "WIN:65")

	numWindows = ItemsInList(windows)
	for(i = 0; i < numWindows; i += 1)
		win = StringFromList(i, windows)

		childWindows = GetAllWindows(win)

		numChildWindows = ItemsInList(childWindows)
		for(j = 0; j < numChildWindows; j += 1)
			childWindow = StringFromList(j, childWindows)

			if(ControlExists(childWindow, control))
				matches = AddListItem(childWindow, matches, ";", Inf)
			endif
		endfor
	endfor

	return matches
End

/// @brief Return the full subwindow path to the given notebook
Function/S FindNotebook(nb)
	string nb

	string windows, childWindows, childWindow, win, leaf
	variable i, j, numWindows, numChildWindows
	string matches = ""

	// search in all panels and graphs
	windows = WinList("*", ";", "WIN:65")

	numWindows = ItemsInList(windows)
	for(i = 0; i < numWindows; i += 1)
		win = StringFromList(i, windows)

		childWindows = GetAllWindows(win)

		numChildWindows = ItemsInList(childWindows)
		for(j = 0; j < numChildWindows; j += 1)
			childWindow = StringFromList(j, childWindows)

			leaf = StringFromList(ItemsInList(childWindow, "#") - 1, childWindow, "#")

			if(!cmpstr(leaf, nb))
				matches = AddListItem(childWindow, matches, ";", Inf)
			endif
		endfor
	endfor

	return matches
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

/// @brief Get distinctive trace colors for a given index
///
/// Holds 21 different trace colors, code originally from
/// http://www.igorexchange.com/node/6532 but completely rewritten and bug-fixed.
///
/// The colors are "Twenty two colors of maximum contrast" by L. Kelly, see http://www.iscc.org/pdf/PC54_1724_001.pdf,
/// where the color white has been removed.
Function GetTraceColor(index, red, green, blue)
	variable index
	variable &red, &green, &blue

	index = mod(index, 21)
	switch(index)
		case 0:
			red = 7967; green=7710; blue=7710
			break

		case 1:
			red = 60395; green=52685; blue=15934
			break

		case 2:
			red = 28527; green=12336; blue=35723
			break

		case 3:
			red = 56283; green=27242; blue=10537
			break

		case 4:
			red = 38807; green=52942; blue=59110
			break

		case 5:
			red = 47545; green=8224; blue=13878
			break

		case 6:
			red = 49858; green=48316; blue=33410
			break

		case 7:
			red = 32639; green=32896; blue=33153
			break

		case 8:
			red = 25186; green=42662; blue=18247
			break

		case 9:
			red = 54227; green=34438; blue=45746
			break

		case 10:
			red = 17733; green=30840; blue=46003
			break

		case 11:
			red = 56540; green=33924; blue=25957
			break

		case 12:
			red = 18504; green=14392; blue=38550
			break

		case 13:
			red = 57825; green=41377; blue=12593
			break

		case 14:
			red = 37265; green=10023; blue=35723
			break

		case 15:
			red = 59881; green=59624; blue=22359
			break

		case 16:
			red = 32125; green=5911; blue=5654
			break

		case 17:
			red = 37779; green=44461; blue=15420
			break

		case 18:
			red = 28270; green=13621; blue=5397
			break

		case 19:
			red = 53713; green=11565; blue=10023
			break

		case 20:
			red = 11308; green=13878; blue=5911
			break

		default:
			ASSERT(0, "Invalid index")
			break
	endswitch
End

/// @brief Query the axis minimum and maximum values
///
/// For none existing graph or axis
/// NaN is returned for minimum and high.
///
/// @param[in]  graph    graph name
/// @param[in]  axis     axis name
/// @param[out] minimum  minimum value of the axis range
/// @param[out] maximum  maximum value of the axis range
/// @param[in] mode [optional:default 0] optional mode option, see @ref AxisRangeModeConstants
Function GetAxisRange(graph, axis, minimum, maximum[, mode])
	string graph, axis
	variable &minimum, &maximum, mode

	string info, flags


	if(!windowExists(graph))
		return NaN
	endif

	if(ParamIsDefault(mode))
		mode = 0
	endif

	minimum  = NaN
	maximum = NaN

	info  = AxisInfo(graph, axis)

	// only set the axis range if the specified axis exists
	if(!isEmpty(info))

		if(mode & AXIS_RANGE_INC_AUTOSCALED)

		elseif(mode == 0)
			flags = StringByKey("SETAXISFLAGS", info)
			if(!isEmpty(flags))
				// axis is in auto scale mode
				return 0
			endif
		else
			ASSERT(0, "Unknown mode from AxisRangeModeConstants for this function")
		endif

		GetAxis/W=$graph/Q $axis
		minimum = V_min
		maximum = V_max
	endif
End

/// @brief Return the orientation of the axis as numeric value
/// @returns one of @ref AxisOrientationConstants
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

	DoAbortNow("unknown axis type")
End

/// @brief Returns a wave with the minimum and maximum
/// values of each axis
///
/// Use SetAxesRanges to set the minimum and maximum values
/// @see GetAxisRange
/// @param[in] graph Name of graph
/// @param[in] axesRegexp [optional: default not set] filter axes names list by this optional regular expression
/// @param[in] orientation [optional: default not set] filter orientation of axes see @ref AxisOrientationConstants
/// @param[in] mode [optional: default 0] filter returned axis information by mode see @ref AxisRangeModeConstants
/// @return free wave with rows = axes, cols = axes info, dimlabel of rows is axis name
Function/Wave GetAxesRanges(graph[, axesRegexp, orientation, mode])
	string graph, axesRegexp
	variable orientation, mode

	string list, axis
	variable numAxes, i, countAxes, minimum, maximum, axisOrientation

	if(ParamIsDefault(mode))
		mode = 0
	endif

	list    = AxisList(graph)
	if(!ParamIsDefault(axesRegexp))
		list = GrepList(list, axesRegexp)
	endif
	list    = SortList(list)
	numAxes = ItemsInList(list)

	Make/FREE/D/N=(numAxes, 3) ranges = 0
	SetDimLabel COLS, 0, minimum , ranges
	SetDimLabel COLS, 1, maximum , ranges
	SetDimLabel COLS, 2, axisType, ranges

	for(i = 0; i < numAxes; i += 1)
		axis = StringFromList(i, list)
		axisOrientation = GetAxisOrientation(graph, axis)
		if(!ParamIsDefault(orientation) && axisOrientation != orientation)
			continue
		endif

		GetAxisRange(graph, axis, minimum, maximum, mode=mode)
		ranges[countAxes][%axisType] = axisOrientation
		ranges[countAxes][%minimum] = minimum
		ranges[countAxes][%maximum] = maximum
		SetDimLabel ROWS, countAxes, $axis, ranges
		countAxes += 1
	endfor
	if(countAxes != numAxes)
		Redimension/N=(countAxes, 3) ranges
	endif

	return ranges
End

/// @brief Set the range of all axes as stored by GetAxesRange
///
/// Includes a heuristic if the name of the axis changed after GetAxesRange.
/// The axis range is also restored if its index in the sorted axis list and its
/// orientation is the same.
/// @see GetAxisRange
/// @param[in] graph Name of graph
/// @param[in] ranges wave with graph ranges as set in @ref GetAxesRanges
/// @param[in] axesRegexp [optional: default not set] filter axes names list by this optional regular expression
/// @param[in] orientation [optional: default not set] filter orientation of axes see @ref AxisOrientationConstants
/// @param[in] mode [optional: default 0] axis set mode see @ref AxisRangeModeConstants
Function SetAxesRanges(graph, ranges[, axesRegexp, orientation, mode])
	string graph
	Wave ranges
	string axesRegexp
	variable orientation, mode

	variable numRows, numAxes, i, minimum, maximum, axisOrientation
	variable col, row, prevAxisMin, prevAxisMax
	string axis, list

	ASSERT(windowExists(graph), "Graph does not exist")

	if(ParamIsDefault(mode))
		mode = 0
	endif

	prevAxisMin = NaN

	numRows = DimSize(ranges, ROWS)

	list    = AxisList(graph)
	if(!ParamIsDefault(axesRegexp))
		list = GrepList(list, axesRegexp)
	endif
	list    = SortList(list)
	numAxes = ItemsInList(list)

	for(i = 0; i < numAxes; i += 1)
		axis = StringFromList(i, list)
		axisOrientation = GetAxisOrientation(graph, axis)
		if(!ParamIsDefault(orientation) && axisOrientation != orientation)
			continue
		endif

		row = FindDimLabel(ranges, ROWS, axis)

		if(row >= 0)
			minimum = ranges[row][%minimum]
			maximum = ranges[row][%maximum]
		else
			// axis does not exist
			if(mode & AXIS_RANGE_USE_MINMAX)
				// use MIN/MAX of previous axes
				if(isNaN(prevAxisMin))
					// need to retrieve once
					col = FindDimLabel(ranges, COLS, "maximum")
					WaveStats/Q/M=1/RMD=[][col] ranges
					prevAxisMax = V_Max
					col = FindDimLabel(ranges, COLS, "minimum")
					WaveStats/Q/M=1/RMD=[][col] ranges
					prevAxisMin = V_Min
				endif
				minimum = prevAxisMin
				maximum = prevAxisMax
			elseif(mode == 0)
				// probably just name has changed, try the axis at the current index and check if the orientation is correct
				if(i < numRows && axisOrientation == ranges[i][%axisType])
					minimum = ranges[i][%minimum]
					maximum = ranges[i][%maximum]
				else
					continue
				endif
			else
				ASSERT(0, "Unknown mode from AxisRangeModeConstants for this function")
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

/// @brief Return a unique axis name
Function/S GetUniqueAxisName(graph, axesBaseName)
	string graph, axesBaseName

	variable numAxes, count, i
	string list, axis

	list = AxisList(graph)
	axis = axesBaseName

	for(i = 0; i < 10000; i += 1)
		if(WhichListItem(axis, list) == -1)
			return axis
		endif

		axis = axesBaseName + num2str(count++)
	endfor

	ASSERT(0, "Could not find a free axis name")
End

/// @brief Generic wrapper for setting a control's value
/// pass in the value as a string, and then decide whether to change to a number based on the type of control
Function SetGuiControlValue(win, control, value)
	string win, control
	string value

	variable controlType, variableType

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	controlType = abs(V_flag)

	if(controlType == CONTROL_TYPE_CHECKBOX)
		SetCheckBoxState(win, control, str2num(value))
	elseif(controlType == CONTROL_TYPE_SETVARIABLE)
		variableType = GetInternalSetVariableType(S_recreation)
		if(variableType == SET_VARIABLE_BUILTIN_STR)
			SetSetVariableString(win, control, value)
		elseif(variableType == SET_VARIABLE_BUILTIN_NUM)
			SetSetVariable(win, control, str2num(value))
		else
			ASSERT(0, "SetVariable globals are not supported")
		endif
	elseif(controlType == CONTROL_TYPE_POPUPMENU)
		SetPopupMenuIndex(win, control, str2num(value))
	elseif(controlType == CONTROL_TYPE_SLIDER)
		Slider $control, value = str2num(value)		
	else
		ASSERT(0, "Unsupported control type") // if I get this, something's really gone pear shaped
	endif
End

/// @brief Generic wrapper for getting a control's value
Function/S GetGuiControlValue(win, control)
	string win, control

	string value
	variable controlType, variableType

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	controlType = abs(V_flag)

	if(controlType == CONTROL_TYPE_CHECKBOX)
		value = num2str(GetCheckBoxState(win, control))
	elseif(controlType == CONTROL_TYPE_SLIDER)
		value = num2str(V_value)
	elseif(controlType == CONTROL_TYPE_SETVARIABLE)
		variableType = GetInternalSetVariableType(S_recreation)
		if(variableType == SET_VARIABLE_BUILTIN_STR)
			value = GetSetVariableString(win, control)
		elseif(variableType == SET_VARIABLE_BUILTIN_NUM)
			value = num2str(GetSetVariable(win, control))
		else
			ASSERT(0, "SetVariable globals are not supported")
		endif
	elseif(controlType == CONTROL_TYPE_POPUPMENU)
		value = num2str(GetPopupMenuIndex(win, control))
	else
		value = ""
	endif

	return value
End

/// @brief Generic wrapper for getting a controls state (enabled, hidden, disabled)
Function/S GetGuiControlState(win, control)
    string win, control

    ControlInfo/W=$win $control
    ASSERT(V_flag != 0, "Non-existing control or window")

    return num2str(V_disable)
End

/// @brief Generic wrapper for setting a controls state (enabled, hidden, disabled)
Function SetGuiControlState(win, control, controlState)
    string win, control
    string controlState
    variable controlType

    ControlInfo/W=$win $control
    ASSERT(V_flag != 0, "Non-existing control or window")

    ModifyControl $control, win=$win, disable=str2num(controlState)
End

/// @brief Return one if the given control is disabled,
/// zero otherwise
Function IsControlDisabled(win, control)
	string win, control

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")

	return V_disable & DISABLE_CONTROL_BIT
End

/// @brief Return one if the given control is hidden,
/// zero otherwise
Function IsControlHidden(win, control)
	string win, control

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")

	return V_disable & HIDDEN_CONTROL_BIT
End

/// @brief Return the main window name from a full subwindow specification
///
/// @param subwindow window name including subwindows, e.g. `panel#subWin1#subWin2`
Function/S GetMainWindow(subwindow)
	string subwindow

	return StringFromList(0, subwindow, "#")
End

/// @brief Return the currently active window
Function/S GetCurrentWindow()

	GetWindow kwTopWin activesw
	return s_value
End

/// @brief Return a 1D text wave with all infos about the cursors
///
/// The data is sorted like `CURSOR_NAMES`.
Function/WAVE GetCursorInfos(graph)
	string graph

	Make/T/FREE/N=(ItemsInList(CURSOR_NAMES)) info = CsrInfo($StringFromList(p, CURSOR_NAMES), graph)

	return info
End

/// @brief Restore the cursors from the info of GetCursorInfos().
Function RestoreCursors(graph, cursorInfos)
	string graph
	WAVE/T cursorInfos

	string traceList, cursorTrace, info, replacementTrace
	variable i, numEntries, numTraces

	traceList = TraceNameList(graph, ";", 0 + 1)
	numTraces = ItemsInList(traceList)

	if(numTraces == 0)
		return NaN
	endif

	numEntries = DimSize(cursorInfos, ROWS)
	for(i = 0; i < numEntries; i += 1)
		info = cursorInfos[i]

		if(IsEmpty(info)) // cursor was not active
			continue
		endif

		cursorTrace = StringByKey("TNAME", info)

		if(FindListItem(cursorTrace, traceList) == -1)
			// trace is not present anymore, use the first one instead
			replacementTrace = StringFromList(0, traceList)
			info = ReplaceWordInString(cursorTrace, info, replacementTrace)
		endif

		Execute StringByKey("RECREATION", info)
	endfor
End

/// @brief Autoscale all vertical axes in the visible x range
Function AutoscaleVertAxisVisXRange(graph)
	string graph

	string axList, axis
	variable i, numAxes, axisOrient

	axList = AxisList(graph)
	numAxes = ItemsInList(axList)
	for(i = 0; i < numAxes; i += 1)
		axis = StringFromList(i, axList)

		axisOrient = GetAxisOrientation(graph, axis)
		if(axisOrient == AXIS_ORIENTATION_LEFT || axisOrient == AXIS_ORIENTATION_RIGHT)
			SetAxis/W=$graph/A=2 $axis
		endif
	endfor
End

/// @brief Return the type of the variable of the SetVariable control
///
/// @return one of @ref GetInternalSetVariableTypeReturnTypes
Function GetInternalSetVariableType(recMacro)
	string recMacro

	ASSERT(strsearch(recMacro, "SetVariable", 0) != -1, "recreation macro is not from a SetVariable")

	variable builtinString = (strsearch(recMacro, "_STR:\"", 0) != -1)
	variable builtinNumber = (strsearch(recMacro, "_NUM:", 0) != -1)

	ASSERT(builtinString + builtinNumber != 2, "SetVariable can not hold both numeric and string contents")

	if(builtinString)
		return SET_VARIABLE_BUILTIN_STR
	elseif(builtinNumber)
		return SET_VARIABLE_BUILTIN_NUM
	endif

	return SET_VARIABLE_GLOBAL
End

/// @brief Extract the limits specification of the control and return it in `minVal`, `maxVal` and `incVal`
///
/// @return 0 on success, 1 if no specification could be found
Function ExtractLimits(win, control, minVal, maxVal, incVal)
	string win, control
	variable &minVal, &maxVal, &incVal

	string minStr, maxStr, incStr

	minVal = NaN
	maxVal = NaN
	incVal = NaN

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "win or control does not exist")

	SplitString/E="(?i).*limits={([^,]+),([^,]+),([^,]+)}.*" S_recreation, minStr, maxStr, incStr

	if(V_flag != 3)
		return 1
	endif

	minVal = str2num(minStr)
	maxVal = str2num(maxStr)
	incVal = str2num(incStr)

	return 0
End

/// @brief Check if the given value is inside the limits defined by the control
///
/// @return - 0: outside limits
///         - 1: inside limits, i.e. val lies in the range [min, max]
///         - NaN: no limits could be found
///
Function CheckIfValueIsInsideLimits(win, control, val)
	string win, control
	variable val

	variable minVal, maxVal, incVal

	if(ExtractLimits(win, control, minVal, maxVal, incVal))
		return NaN
	endif

	return val >= minVal && val <= maxVal
End
/// @brief Returns a value that is constrained by the limits defined by the control
///
/// @return val <= control max and val >= contorl min
Function GetLimitConstrainedSetVar(win, control, val)
	string win
	string control
	variable val
	
	variable minVal, maxVal, incVal
	if(!ExtractLimits(win, control, minVal, maxVal, incVal))
		val = limit(val, minVal, maxVal)
   	endif
   	
   	return val
End

/// @brief Return the parameter type a function parameter
///
/// @param func       name of the function
/// @param paramIndex index of the parameter
Function GetFunctionParameterType(func, paramIndex)
	string func
	variable paramIndex

	string funcInfo, param
	variable numParams

	funcInfo = FunctionInfo(func, "")

	ASSERT(paramIndex < NumberByKey("N_PARAMS", funcInfo), "Requested parameter number does not exist.")
	sprintf param, "PARAM_%d_TYPE", paramIndex

	return NumberByKey(param, funcInfo)
End

/// @brief Return the control procedure for the given control
///
/// @returns name of control procedure or an empty string
Function/S GetControlProcedure(win, control)
	string win, control

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "invalid or non existing control")

	return GetValueFromRecMacro(REC_MACRO_PROCEDURE, S_recreation)
End

/// @brief Return an entry from the given recreation macro
///
/// The recreation macro of a single GUI control looks like:
/// \rst
/// .. code-block: igorpro
///
///		PopupMenu popup_ctrl,pos={1.00,1.00},size={55.00,19.00},proc=PGCT_PopMenuProc
///		PopupMenu popup_ctrl,mode=1,popvalue="Entry1",value= #"\"Entry1;Entry2;Entry3\""
/// \endrst
///
/// This function allows to extract key/value pairs from it.
///
/// @param key      non-empty string (must be followed by `=` in the recreation macro)
/// @param recMacro GUI control recreation macro as returned by `ControlInfo`
Function/S GetValueFromRecMacro(key, recMacro)
	string key, recMacro

	variable last, first
	variable comma, cr
	string procedure

	ASSERT(!IsEmpty(key), "Invalid key")

	key += "="

	first = strsearch(recMacro, key, 0)

	if(first == -1)
		return ""
	endif

	comma = strsearch(recMacro, ",", first + 1)
	cr    = strsearch(recMacro, "\r", first + 1)

	if(comma > 0 && cr > 0)
		last = min(comma, cr)
	elseif(comma == -1)
		last = cr
	elseif(cr == -1)
		last = comma
	else
		ASSERT(0, "impossible case")
	endif

	procedure = recMacro[first + strlen(key), last - 1]

	return procedure
End

/// @returns 1 on error, 0 if everything is fine.
Function SearchForInvalidControlProcs(win)
	string win

	string controlList, control, controlProc
	string subTypeStr
	variable result, numEntries, i, subType
	string funcList, subwindowList, subwindow

	if(!windowExists(win))
		printf "SearchForInvalidControlProcs: Panel \"%s\" does not exist.\r", win
		ControlWindowToFront()
		return 1
	endif

	if(WinType(win) != 7 && WinType(win) != 1) // ignore everything except panels and graphs
		return 0
	endif

	subwindowList = ChildWindowList(win)
	numEntries = ItemsInList(subwindowList)
	for(i = 0; i < numEntries; i += 1)
		subwindow = win + "#" + StringFromList(i, subWindowList)
		result = result || SearchForInvalidControlProcs(subwindow)
	endfor

	// we still have old style GUI control procedures so we can not restrict it to one parameter
	funcList    = FunctionList("*", ";", "KIND:2")
	controlList = ControlNameList(win)
	numEntries  = ItemsInList(controlList)

	for(i = 0; i < numEntries; i += 1)
		control = StringFromList(i, controlList)

		controlProc = GetControlProcedure(win, control)

		if(IsEmpty(controlProc))
			continue
		endif

		if(WhichListItem(controlProc, funcList, ";", 0, 0) == -1)
			printf "SearchForInvalidControlProcedures: Panel \"%s\" has the control \"%s\" which refers to the non-existing GUI procedure \"%s\".\r", win, control, controlProc
			ControlWindowToFront()
			result = 1
			continue
		endif

		subTypeStr = StringByKey("SUBTYPE", FunctionInfo(controlProc))
		subType    = GetNumericSubType(subTypeStr)
		ControlInfo/W=$win $control

		if(abs(V_Flag) != subType)
			printf "SearchForInvalidControlProcs: Panel \"%s\" has the control \"%s\" which refers to the GUI procedure \"%s\" which is of an incorrect subType \"%s\".\r", win, control, controlProc, subTypeStr
			ControlWindowToFront()
			result = 1
			continue
		endif
	endfor

	if(!result)
		printf "Congratulations! Panel \"%s\" references only valid GUI control procedures.\r", win
	endif

	return result
End

/// @brief Convert the function subType names for GUI control procedures
///        to a numeric value as used by `ControlInfo`
Function GetNumericSubType(subType)
	string subType

	strswitch(subType)
		case "ButtonControl":
			return CONTROL_TYPE_BUTTON
			break
		case "CheckBoxControl":
			return CONTROL_TYPE_CHECKBOX
			break
		case "ListBoxControl":
			return CONTROL_TYPE_LISTBOX
			break
		case "PopupMenuControl":
			return CONTROL_TYPE_POPUPMENU
			break
		case "SetVariableControl":
			return CONTROL_TYPE_SETVARIABLE
			break
		case "SliderControl":
			return CONTROL_TYPE_SLIDER
			break
		case "TabControl":
			return CONTROL_TYPE_TAB
			break
		default:
			ASSERT(0, "Unsupported control subType")
			break
	endswitch
End

///@brief Return the control type as string
///
/// @param win     window name
/// @param control name of control
/// @return type of control as string or empty string
Function/S GetControlTypeAsString(win, control)
	string win
	string control

	variable checkBoxMode

	switch(GetControlType(win, control))
		case 1:
			return "Button"
			break
		case 2:
			checkBoxMode = GetCheckBoxMode(win, control)
			if(!checkBoxMode)
				return "Check"
			elseif(checkBoxMode == 1)
				return "Radio"
			elseif(checkBoxMode == 2)
				return "Triangle"
			else
				ASSERT(0, "Impossible case")
			endif
			break
		case 3:
			return "PopUp"
			break
		case 4:
			return "ValDisp"
			break
		case 5:
			return "SetVar"
			break
		case 6:
			return "Chart"
			break
		case 7:
			return "Slider"
			break
		case 8:
			return "TabCtrl"
			break
		case 9:
			return "Group"
			break
		case 10:
			return "Title"
			break
		case 11:
			return "List"
			break
		case 12:
			return "Custom"
			break
		default:
			ASSERT(0, "Impossible case")
			break
	endswitch
End

/// @brief Return the numeric control type
///
/// @return one of @ref GUIControlTypes
Function GetControlType(win, control)
	string win, control

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	return abs(V_flag)
End

/// @brief Determines if control stores numeric or text data
Function DoesControlHaveInternalString(win, control)
	string win, control

	variable internalString
	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "invalid or non existing control")
	return strsearch(S_recreation, "_STR:", 0) != -1
End

/// @brief Returns checkbox mode
Function GetCheckBoxMode(win, checkBoxName)
	string win, checkBoxName

	variable first, mode
	string modeString
	ControlInfo/W=$win $checkBoxName
	ASSERT(V_flag == 2, "not a checkBox control")
	first = strsearch(S_recreation, "mode=", 0,2)
	if(first == -1)
		return 0
	else
		sscanf S_recreation[first, first + 5], "mode=%d", mode
	endif
	ASSERT(IsFinite(mode), "Unexpected checkbox mode")
	return mode
End

///@brief Returns formatted control name
Function/S GetFormattedControlName(win, control)
	string win, control

	string savedCtrlName = control
	string newPrefix = GetControlTypeAsString(Win, control)
	control = trimstring(control)
	variable stringLocation = strsearch(control,newPrefix,0,2)
	if(stringLocation == 0)
		control = replacestring(newPrefix, control, newPrefix) // returns case correct formatting
	elseif(stringLocation > 0)
		control = replacestring(newPrefix, control, "") // removes incorrectly placed ctrl type string
		control = newPrefix + control
		control = replacestring("__", control, "_") // remove double underscores
	elseif(stringLocation == -1)
		control = newPrefix + "_" + control // adds ctrl type string prefix to ctrl name with missing ctrl type string
	endif

	if(DoesControlHaveInternalString(win, savedCtrlName)) // adds txt suffix string to string setting ctrl
		control = control + "_txt"
	endif
	return control
End

/// @brief Returns the selected row of the ListBox for some modes
///        without selection waves
Function GetListBoxSelRow(win, ctrl)
	string win, ctrl

	ControlInfo/W=$win $ctrl
	ASSERT(V_flag == 11, "Not a listbox control")

	return V_Value
End

/// @brief Check if the location `loc` is inside the rectangle `r`
Function IsInsideRect(loc, r)
	STRUCT Point& loc
	STRUCT RectF& r

	return loc.h >= r.left      \
		   && loc.h <= r.right  \
		   && loc.v >= r.top    \
		   && loc.v <= r.bottom
End

/// @brief Return the coordinates of the control borders
///        relative to the top left corner in pixels
Function GetControlCoordinates(win, ctrl, s)
	string win, ctrl
	STRUCT RectF& s

	ControlInfo/W=$win $ctrl
	ASSERT(V_flag != 0, "Not an existing control")

	s.top    = V_top
	s.bottom = V_top + V_height
	s.left   = V_left
	s.right  = V_left + V_width
End

/// @brief Get the text (plain or formatted) from the notebook
Function/S GetNotebookText(win)
	string win

	ASSERT(WinType(win) == 5, "Passed win is not a notebook")

	Notebook $win getData=1

	return S_Value
End

/// @brief Replace the contents of the notebook
Function ReplaceNotebookText(win, text)
	string win, text

	ASSERT(WinType(win) == 5, "Passed win is not a notebook")

	Notebook $win selection={startOfFile, endOfFile}
	ASSERT(!V_Flag, "Illegal selection")

	Notebook $win setData=text
End

/// @brief Retrieves named userdata keys from a recreation macro string
///
/// @param recMacro recreation macro string
/// @returns List of userdata keys
Function/S GetUserdataKeys(recMacro)
	string recMacro

	string userKeys = ""
	string key
	variable pos1, pos2
	variable prefixLength = strlen(USERDATA_PREFIX)

	do
		pos1 = strsearch(recMacro, USERDATA_PREFIX, pos1)
		if(pos1 == -1)
			break
		endif
		pos2 = strsearch(recMacro, USERDATA_SUFFIX, pos1)
		key = recMacro[pos1 + prefixLength, pos2 - 1]
		userKeys = AddListItem(key, userKeys, ";", Inf)
		pos1 = pos2
	while(1)

	if(ItemsInList(userKeys) > 1)
		WAVE/T w = ListToTextWave(userKeys, ";")
		FindDuplicates/FREE /RT=wClean w
		wfprintf userKeys, "%s;", wClean
	endif

	return userKeys
End

/// @brief Converts an Igor control type number to control name
///
/// @param ctrlType ctrl type of Igor control
/// @returns Igor name of control type
Function/S ControlTypeToName(ctrlType)
	variable ctrlType

	variable pos
	if(numtype(ctrlType) == 2)
		return ""
	endif
	pos = WhichListItem(num2str(abs(ctrlType)), EXPCONFIG_GUI_CTRLTYPES)
	if(pos < 0)
	  return ""
	endif
	return StringFromList(pos, EXPCONFIG_GUI_CTRLLIST)
End

/// @brief Converts an Igor control name to control type number
///
/// @param ctrlName Name of Igor control
/// @returns Igor control type number
Function Name2ControlType(ctrlName)
	string ctrlName

	variable pos
	pos = WhichListItem(ctrlName, EXPCONFIG_GUI_CTRLLIST)
	if(pos < 0)
	  return NaN
	endif
	return str2num(StringFromList(pos, EXPCONFIG_GUI_CTRLTYPES))
End

/// @brief Checks if a certain window can act as valid host for subwindows
///        developer note: The only integrated Igor function that does this is ChildWindowList.
///        Though, ChildWindowList generates an RTE for non-valid windows, where this check function does not.
///
/// @param wName window name that should be checked to be a valid host for subwindows
/// @returns 1 if window is a valid host, 0 otherwise
Function WindowTypeCanHaveChildren(wName)
	string wName

	Make/FREE/I typeCanHaveChildren = {WINTYPE_GRAPH, WINTYPE_PANEL}
	FindValue/I=(WinType(wName)) typeCanHaveChildren

	return V_value != -1
End

/// @brief Recursively build a list of windows, including all child
///        windows, starting with wName.
///
/// @param wName parent window name to start with
/// @return A string containing names of windows.  This list is a semicolon separated list.  It will include the window
///         wName and all of its children and children of children, etc.
Function/S GetAllWindows(wName)
	string wName

	string windowList = ""
	GetAllWindowsImpl(wName, windowList)

	return windowList
End

static Function GetAllWindowsImpl(wName, windowList)
	string wName
	string &windowList

	string children
	variable i, numChildren, err

	windowList = AddListItem(wName, windowList, ";", inf)

	if(!WindowTypeCanHaveChildren(wName))
		return NaN
	endif

	children = ChildWindowList(wName)
	numChildren = ItemsInList(children, ";")
	for(i = 0; i < numChildren; i += 1)
		GetAllWindowsImpl(wName + "#" + StringFromList(i, children, ";"), windowList)
	endfor
End

/// @brief Checks if a window is tagged as certain type
///
/// @param[in] panelTitle Window name to check
/// @param[in] typeTag one of PANELTAG_* constants @sa panelTags
/// returns 1 if window is a DA_Ephys panel
Function PanelIsType(panelTitle, typeTag)
	string panelTitle
	string typeTag

	if(!WindowExists(panelTitle))
		return 0
	endif

	return !CmpStr(GetUserData(panelTitle, "", EXPCONFIG_UDATA_PANELTYPE), typeTag)
End
