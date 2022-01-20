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
		newValue = GetLimitConstrainedSetVar(S_recreation, newValue)
	endif

	if(newValue != v_value)
		SetVariable $control, win = $win, value =_NUM:newValue
	endif

	return newValue
End

/// @brief Set the SetVariable contents as string
///
/// @param win     window
/// @param control control of type SetVariable
/// @param str     string to set
/// @param setHelp [optional, defaults to false] set the help string as well.
///                Allows to work around long text in small controls.
Function SetSetVariableString(string win, string control, string str, [variable setHelp])

	if(ParamIsDefault(setHelp))
		setHelp = 0
	else
		setHelp = !!setHelp
	endif

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_SETVARIABLE, "Control is not a setvariable")

	if(setHelp)
		SetVariable $control, win = $win, value =_STR:str, help={str}
	else
		SetVariable $control, win = $win, value =_STR:str
	endif
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
Function SetPopupMenuVal(string win, string control, [string list, string func])
	string output, allEntries

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_POPUPMENU, "Control is not a popupmenu")

	if(!ParamIsDefault(list))
		sprintf output, "\"%s\"" List
		ASSERT(strlen(output) < MAX_COMMANDLINE_LENGTH, "Popup menu list is greater than MAX_COMMANDLINE_LENGTH characters")
	elseif(!ParamIsDefault(func))
		output = func
		allEntries = GetPopupMenuList(func, POPUPMENULIST_TYPE_OTHER)
		ASSERT(!IsEmpty(allEntries), "func does not generate a non-empty string list.")
	endif

	PopupMenu $control win=$win, value=#output
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

	ASSERT(stringMatch(result, str), "str: \"" + str + "\" is not in the popupmenus \"" + control + "\" list")

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
	ASSERT(abs(V_flag) == CONTROL_TYPE_TAB, "Control is not a tab")
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
Function [STRUCT RGBColor s] GetTraceColor(variable index)

	index = mod(index, 21)
	switch(index)
		case 0:
			s.red = 7967; s.green=7710; s.blue=7710
			break

		case 1:
			s.red = 60395; s.green=52685; s.blue=15934
			break

		case 2:
			s.red = 28527; s.green=12336; s.blue=35723
			break

		case 3:
			s.red = 56283; s.green=27242; s.blue=10537
			break

		case 4:
			s.red = 38807; s.green=52942; s.blue=59110
			break

		case 5:
			s.red = 47545; s.green=8224; s.blue=13878
			break

		case 6:
			s.red = 49858; s.green=48316; s.blue=33410
			break

		case 7:
			s.red = 32639; s.green=32896; s.blue=33153
			break

		case 8:
			s.red = 25186; s.green=42662; s.blue=18247
			break

		case 9:
			s.red = 54227; s.green=34438; s.blue=45746
			break

		case 10:
			s.red = 17733; s.green=30840; s.blue=46003
			break

		case 11:
			s.red = 56540; s.green=33924; s.blue=25957
			break

		case 12:
			s.red = 18504; s.green=14392; s.blue=38550
			break

		case 13:
			s.red = 57825; s.green=41377; s.blue=12593
			break

		case 14:
			s.red = 37265; s.green=10023; s.blue=35723
			break

		case 15:
			s.red = 59881; s.green=59624; s.blue=22359
			break

		case 16:
			s.red = 32125; s.green=5911; s.blue=5654
			break

		case 17:
			s.red = 37779; s.green=44461; s.blue=15420
			break

		case 18:
			s.red = 28270; s.green=13621; s.blue=5397
			break

		case 19:
			s.red = 53713; s.green=11565; s.blue=10023
			break

		case 20:
			s.red = 11308; s.green=13878; s.blue=5911
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
/// The return value for autoscale axis depends on the mode flag:
/// AXIS_RANGE_INC_AUTOSCALED -> [0, 0]
/// AXIS_RANGE_DEFAULT -> [NaN, NaN]
///
/// @param[in] graph graph name
/// @param[in] axis  axis name
/// @param[in] mode  [optional:default #AXIS_RANGE_DEFAULT] optional mode option, see @ref AxisRangeModeConstants
///
/// @return minimum and maximum value of the axis range
Function [variable minimum, variable maximum] GetAxisRange(string graph, string axis, [variable mode])
	string info, flags

	if(!windowExists(graph))
		return [NaN, NaN]
	endif

	if(ParamIsDefault(mode))
		mode = AXIS_RANGE_DEFAULT
	endif

	info = AxisInfo(graph, axis)

	// axis does not exist
	if(isEmpty(info))
		return [NaN, NaN]
	endif

	if(mode == AXIS_RANGE_DEFAULT)
		flags = StringByKey("SETAXISFLAGS", info)
		if(!isEmpty(flags))
			// axis is in auto scale mode
			return [NaN, NaN]
		endif
	elseif(mode & AXIS_RANGE_INC_AUTOSCALED)
		// do nothing
	else
		ASSERT(0, "Unknown mode from AxisRangeModeConstants for this function")
	endif

	GetAxis/W=$graph/Q $axis
	return [V_min, V_max]
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
/// @param[in] mode [optional: default #AXIS_RANGE_DEFAULT] filter returned axis information by mode see @ref AxisRangeModeConstants
/// @return free wave with rows = axes, cols = axes info, dimlabel of rows is axis name
Function/Wave GetAxesRanges(graph[, axesRegexp, orientation, mode])
	string graph, axesRegexp
	variable orientation, mode

	string list, axis
	variable numAxes, i, countAxes, minimum, maximum, axisOrientation

	if(ParamIsDefault(mode))
		mode = AXIS_RANGE_DEFAULT
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

		[minimum, maximum] = GetAxisRange(graph, axis, mode=mode)
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
		mode = AXIS_RANGE_DEFAULT
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
			elseif(mode == AXIS_RANGE_DEFAULT)
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
	string recMacro

	[recMacro, controlType] = GetRecreationMacroAndType(win, control)

	if(controlType == CONTROL_TYPE_CHECKBOX)
		SetCheckBoxState(win, control, str2num(value))
	elseif(controlType == CONTROL_TYPE_SETVARIABLE)
		variableType = GetInternalSetVariableType(recMacro)
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
		Slider $control, win = $win, value = str2num(value)
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

/// @brief Return 1 if there are cursors on the graph, 0 if not
Function GraphHasCursors(graph)
	string graph

	Make/FREE/N=(ItemsInList(CURSOR_NAMES)) info = WaveExists(CsrWaveRef($StringFromList(p, CURSOR_NAMES), graph))

	return WaveMax(info) > 0
End

/// @brief Return a 1D text wave with all infos about the cursors
///
/// Returns an invalid wave reference when no cursors are present. Counterpart
/// to RestoreCursors().
///
/// The data is sorted like `CURSOR_NAMES`.
Function/WAVE GetCursorInfos(graph)
	string graph

	if(!GraphHasCursors(graph))
		return $""
	endif

	Make/T/FREE/N=(ItemsInList(CURSOR_NAMES)) info = CsrInfo($StringFromList(p, CURSOR_NAMES), graph)

	return info
End

/// @brief Restore the cursors from the info of GetCursorInfos().
Function RestoreCursors(graph, cursorInfos)
	string graph
	WAVE/T/Z cursorInfos

	string traceList, cursorTrace, info, replacementTrace
	variable i, numEntries, numTraces

	if(!WaveExists(cursorInfos))
		return NaN
	endif

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

Function ExtractLimitsFromRecMacro(string recMacro, variable& minVal, variable& maxVal, variable& incVal)
	string minStr, maxStr, incStr

	minVal = NaN
	maxVal = NaN
	incVal = NaN

	SplitString/E="(?i).*limits={([^,]+),([^,]+),([^,]+)}.*" recMacro, minStr, maxStr, incStr

	if(V_flag != 3)
		return 1
	endif

	minVal = str2num(minStr)
	maxVal = str2num(maxStr)
	incVal = str2num(incStr)

	return 0
End

/// @brief Extract the limits specification of the control and return it in `minVal`, `maxVal` and `incVal`
///
/// @return 0 on success, 1 if no specification could be found
///
/// @sa ExtractLimitsFromRecMacro for a faster way if you already have the recreation macro
Function ExtractLimits(string win, string control, variable& minVal, variable& maxVal, variable& incVal)
	string minStr, maxStr, incStr

	string recMacro
	variable controlType
	[recMacro, controlType] = GetRecreationMacroAndType(win, control)

	return ExtractLimitsFromRecMacro(recMacro, minVal, maxVal, incVal)
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
Function GetLimitConstrainedSetVar(string recMacro, variable val)

	variable minVal, maxVal, incVal
	if(!ExtractLimitsFromRecMacro(recMacro, minVal, maxVal, incVal))
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

/// @brief Search for invalid control procedures in the given panel or graph
///
/// Searches recursively in all subwindows.
///
/// @param win         panel or graph
/// @param warnOnEmpty [optional, default to false] print out controls which don't have a control procedure
///                    but can have one.
///
/// @returns 1 on error, 0 if everything is fine.
Function SearchForInvalidControlProcs(win, [warnOnEmpty])
	string win
	variable warnOnEmpty

	string controlList, control, controlProc
	string subTypeStr, helpEntry, recMacro
	variable result, numEntries, i, subType, controlType
	string funcList, subwindowList, subwindow

	if(!windowExists(win))
		printf "SearchForInvalidControlProcs: Panel \"%s\" does not exist.\r", win
		ControlWindowToFront()
		return 1
	endif

	if(ParamIsDefault(warnOnEmpty))
		warnOnEmpty = 0
	else
		warnOnEmpty = !!	warnOnEmpty
	endif

	if(WinType(win) != 7 && WinType(win) != 1) // ignore everything except panels and graphs
		return 0
	endif

	subwindowList = ChildWindowList(win)
	numEntries = ItemsInList(subwindowList)
	for(i = 0; i < numEntries; i += 1)
		subwindow = win + "#" + StringFromList(i, subWindowList)
		result = result || SearchForInvalidControlProcs(subwindow, warnOnEmpty = warnOnEmpty)
	endfor

	funcList    = FunctionList("*", ";", "NPARAMS:1,KIND:2")
	controlList = ControlNameList(win)
	numEntries  = ItemsInList(controlList)

	for(i = 0; i < numEntries; i += 1)
		control = StringFromList(i, controlList)

		[recMacro, controlType] = GetRecreationMacroAndType(win, control)

		if(controlType == CONTROL_TYPE_VALDISPLAY || controlType == CONTROL_TYPE_GROUPBOX)
			continue
		endif

		helpEntry = GetValueFromRecMacro("help", recMacro)

		if(IsEmpty(helpEntry))
			printf "SearchForInvalidControlProcs: Panel \"%s\" has the control \"%s\" which does not have a help entry.\r", win, control
		endif

		controlProc = GetValueFromRecMacro(REC_MACRO_PROCEDURE, recMacro)

		if(IsEmpty(controlProc))
			if(warnOnEmpty)
				printf "SearchForInvalidControlProcs: Panel \"%s\" has the control \"%s\" which does not have a GUI procedure.\r", win, control
			endif
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
Function DoesControlHaveInternalString(string recMacro)
	return strsearch(recMacro, "_STR:", 0) != -1
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
Function/S GetNotebookText(string win, [variable mode])

	ASSERT(WinType(win) == 5, "Passed win is not a notebook")

	if(ParamIsDefault(mode))
		mode = 1
	endif

	Notebook $win getData=mode

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

/// @brief Append to a notebook
Function AppendToNotebookText(win, text)
	string win, text

	ASSERT(WinType(win) == 5, "Passed win is not a notebook")

	Notebook $win selection={endOfFile, endOfFile}
	ASSERT(!V_Flag, "Illegal selection")

	Notebook $win setData=text
End

/// @brief Select the end in the given notebook.
///
/// The selection is the place where the user would naïvely enter new text.
Function NotebookSelectionAtEnd(win)
	string win

	ASSERT(WinType(win) == 5, "Passed win is not a notebook")

	Notebook $win selection={endOfFile,endOfFile}, findText={"",1}
End

/// @brief Retrieves named userdata keys from a recreation macro string
///
/// @param recMacro recreation macro string
///
/// @returns Textwave with all unqiue entries or `$""` if nothing could be found.
Function/WAVE GetUserdataKeys(string recMacro)

	variable pos1, pos2, count
	variable prefixLength = strlen(USERDATA_PREFIX)

	Make/T/FREE userKeys

	do
		pos1 = strsearch(recMacro, USERDATA_PREFIX, pos1)

		if(pos1 == -1)
			break
		endif

		pos2 = strsearch(recMacro, USERDATA_SUFFIX, pos1)
		ASSERT(pos2 != -1, "Invalid recreation macro")

		EnsureLargeEnoughWave(userKeys, minimumSize = count)
		userKeys[count++] = recMacro[pos1 + prefixLength, pos2 - 1]

		pos1 = pos2
	while(1)

	if(count == 0)
		return $""
	endif

	Redimension/N=(count) userKeys

	return GetUniqueEntries(userKeys)
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
/// @param[in] device Window name to check
/// @param[in] typeTag one of PANELTAG_* constants @sa panelTags
/// returns 1 if window is a DA_Ephys panel
Function PanelIsType(device, typeTag)
	string device
	string typeTag

	if(!WindowExists(device))
		return 0
	endif

	return !CmpStr(GetUserData(device, "", EXPCONFIG_UDATA_PANELTYPE), typeTag)
End

/// @brief Show a contextual popup menu which allows the user to change the set variable limit's increment
///
/// - Expects the ctrl to have the named user data "DefaultIncrement"
/// - Works only on right mouse click on the title or the value field, *not* the up/down arrow buttons
Function ShowSetVariableLimitsSelectionPopup(sva)
	STRUCT WMSetVariableAction &sva

	string win, ctrl, items, defaultIncrementStr, elem
	variable minVal, maxVal, incVal, defaultIncrement, index

	win = sva.win
	ctrl = sva.ctrlName

	ASSERT(sva.eventCode == 9, "Unexpected event code")

	if(sva.eventMod != 16)
		// not the right mouse button
		return NaN
	endif

	if(sva.mousePart == 1 || sva.mousePart == 2)
		// clicked at the up/down arrow buttons
		return NaN
	endif

	defaultIncrementStr = GetUserData(win, ctrl, "DefaultIncrement")
	defaultIncrement = str2numSafe(defaultIncrementStr)
	ASSERT(IsFinite(defaultIncrement), "Missing DefaultIncrement user data")

	Make/D/FREE increments = {1e-3, 1e-2, 0.1, 1.0, 10, 1e2, 1e3}

	// find the default value or add it
	FindValue/V=(defaultIncrement) increments
	index = V_Value

	items = NumericWaveToList(increments, ";")

	if(index != -1)
		elem  = StringFromList(index, items)
		items = RemoveFromList(elem, items)
	else
		index = Inf
	endif

	items = AddListItem(defaultIncrementStr + " (default)", items, ";", index)

	// highlight the current value
	ExtractLimits(win, ctrl, minVal, maxVal, incVal)
	ASSERT(!IsNaN(minVal) && !IsNaN(maxVal) && !IsNaN(incVal), "Invalid limits")
	FindValue/V=(incVal) increments
	index = V_Value

	if(index != -1)
		elem  = StringFromList(index, items)
		items = RemoveFromList(elem, items)
		items = AddListItem("\\M1! " + elem, items, ";", index)
	endif

	PopupContextualMenu items
	if(V_flag != 0)
		SetSetVariableLimits(win, ctrl, minVal, maxVal, increments[V_flag - 1])
	endif
End

/// @brief Draw a scale bar on a graph
///
/// @param graph graph
/// @param x0                horizontal coordinate of first point
/// @param y0                vertical coordinate of first point
/// @param x1                horizontal coordinate of second point
/// @param y1                vertical coordinate of second point
/// @param unit              [optional] data unit when drawing the label
/// @param drawLength        [optional, defaults to false] true/false for outputting the label
/// @param labelOffset       [optional] offset in current coordinates of the label
/// @param newlineBeforeUnit [optional] Use a newline before the unit instead of a space
Function DrawScaleBar(string graph, variable x0, variable y0, variable x1, variable y1, [string unit, variable drawLength, variable labelOffset, variable newlineBeforeUnit])

	string msg, str
	variable length, xPos, yPos, subDigits

	if(ParamIsDefault(drawLength))
		drawLength = 0
	else
		drawLength = !!drawLength

		if(ParamIsDefault(unit))
			unit = ""
		endif

		if(ParamIsDefault(labelOffset))
			labelOffset = 0
		endif

		if(ParamIsDefault(newlineBeforeUnit))
			newlineBeforeUnit = 0
		endif
	endif

	sprintf msg, "(%g, %g), (%g, %g)\r", x0, y0, x1, y1
	DEBUGPRINT(msg)

	if(drawLength)

		if(x0 == x1)
			length = abs(y0 - y1)

			ASSERT(!IsEmpty(unit), "empty unit")
			subDigits = length > 1 ? 0 : abs(floor(log(length)/log(10)))
			sprintf str, "%.*f%s%s", subDigits, length, SelectString(newlineBeforeUnit, NUMBER_UNIT_SPACE, "\r"), unit

			xPos = x0 - labelOffset
			yPos = min(y0, y1) + abs(y0 - y1) / 2

			sprintf msg, "Text: (%g, %g)\r", xPos, yPos
			DEBUGPRINT(msg)

			SetDrawEnv/W=$graph textxjust = 2,textyjust = 1
		elseif(y0 == y1)
			length = abs(x0 - x1)

			ASSERT(!IsEmpty(unit), "empty unit")
			subDigits = length > 1 ? 0 : abs(floor(log(length)/log(10)))
			sprintf str, "%.*f%s%s", subDigits, length, SelectString(newlineBeforeUnit, NUMBER_UNIT_SPACE, "\r"), unit

			xPos = min(x0, x1) + abs(x0 - x1) / 2
			yPos = y0 - labelOffset

			sprintf msg, "Text: (%g, %g)\r", xPos, yPos
			DEBUGPRINT(msg)

			SetDrawEnv/W=$graph textxjust = 1,textyjust = 2
		else
			ASSERT(0, "Unexpected combination")
		endif

		DrawText/W=$graph xPos, yPos, str
	endif

	DrawLine/W=$graph x0, y0, x1, y1
End

///@brief Accelerated setting of multiple traces in a graph to un/hidden
///@param[in] graph name of graph window
///@param[in] w 1D text wave with trace names
///@param[in] h number of traces in text wave
///@param[in] s new hidden state
Function AccelerateHideTraces(string graph, WAVE/T w, variable h, variable s)

	variable step

	if(h)
		s = !!s
		do
			step = min(2 ^ trunc(log(h) / log(2)), 112)
			h -= step
			switch(step)
				case 112:
					ModifyGraph/W=$graph hideTrace($w[h])=s,hideTrace($w[h+1])=s,hideTrace($w[h+2])=s,hideTrace($w[h+3])=s,hideTrace($w[h+4])=s,hideTrace($w[h+5])=s,hideTrace($w[h+6])=s,hideTrace($w[h+7])=s,hideTrace($w[h+8])=s,hideTrace($w[h+9])=s,hideTrace($w[h+10])=s,hideTrace($w[h+11])=s,hideTrace($w[h+12])=s,hideTrace($w[h+13])=s,hideTrace($w[h+14])=s,hideTrace($w[h+15])=s,hideTrace($w[h+16])=s,hideTrace($w[h+17])=s,hideTrace($w[h+18])=s,hideTrace($w[h+19])=s,hideTrace($w[h+20])=s,hideTrace($w[h+21])=s,hideTrace($w[h+22])=s,hideTrace($w[h+23])=s,hideTrace($w[h+24])=s,hideTrace($w[h+25])=s,hideTrace($w[h+26])=s,hideTrace($w[h+27])=s,hideTrace($w[h+28])=s,hideTrace($w[h+29])=s,hideTrace($w[h+30])=s,hideTrace($w[h+31])=s,hideTrace($w[h+32])=s,hideTrace($w[h+33])=s,hideTrace($w[h+34])=s,hideTrace($w[h+35])=s,hideTrace($w[h+36])=s,hideTrace($w[h+37])=s,hideTrace($w[h+38])=s,hideTrace($w[h+39])=s,hideTrace($w[h+40])=s,hideTrace($w[h+41])=s,hideTrace($w[h+42])=s,hideTrace($w[h+43])=s,hideTrace($w[h+44])=s,hideTrace($w[h+45])=s,hideTrace($w[h+46])=s,hideTrace($w[h+47])=s,hideTrace($w[h+48])=s,hideTrace($w[h+49])=s,hideTrace($w[h+50])=s,hideTrace($w[h+51])=s,hideTrace($w[h+52])=s,hideTrace($w[h+53])=s,hideTrace($w[h+54])=s,hideTrace($w[h+55])=s,hideTrace($w[h+56])=s,hideTrace($w[h+57])=s,hideTrace($w[h+58])=s,hideTrace($w[h+59])=s,hideTrace($w[h+60])=s,hideTrace($w[h+61])=s,hideTrace($w[h+62])=s,hideTrace($w[h+63])=s,hideTrace($w[h+64])=s,hideTrace($w[h+65])=s,hideTrace($w[h+66])=s,hideTrace($w[h+67])=s,hideTrace($w[h+68])=s,hideTrace($w[h+69])=s,hideTrace($w[h+70])=s,hideTrace($w[h+71])=s,hideTrace($w[h+72])=s,hideTrace($w[h+73])=s,hideTrace($w[h+74])=s,hideTrace($w[h+75])=s,hideTrace($w[h+76])=s,hideTrace($w[h+77])=s,hideTrace($w[h+78])=s,hideTrace($w[h+79])=s,hideTrace($w[h+80])=s,hideTrace($w[h+81])=s,hideTrace($w[h+82])=s,hideTrace($w[h+83])=s,hideTrace($w[h+84])=s,hideTrace($w[h+85])=s,hideTrace($w[h+86])=s,hideTrace($w[h+87])=s,hideTrace($w[h+88])=s,hideTrace($w[h+89])=s,hideTrace($w[h+90])=s,hideTrace($w[h+91])=s,hideTrace($w[h+92])=s,hideTrace($w[h+93])=s,hideTrace($w[h+94])=s,hideTrace($w[h+95])=s,hideTrace($w[h+96])=s,hideTrace($w[h+97])=s,hideTrace($w[h+98])=s,hideTrace($w[h+99])=s,hideTrace($w[h+100])=s,hideTrace($w[h+101])=s,hideTrace($w[h+102])=s,hideTrace($w[h+103])=s,hideTrace($w[h+104])=s,hideTrace($w[h+105])=s,hideTrace($w[h+106])=s,hideTrace($w[h+107])=s,hideTrace($w[h+108])=s,hideTrace($w[h+109])=s,hideTrace($w[h+110])=s,hideTrace($w[h+111])=s
					break
				case 64:
					ModifyGraph/W=$graph hideTrace($w[h])=s,hideTrace($w[h+1])=s,hideTrace($w[h+2])=s,hideTrace($w[h+3])=s,hideTrace($w[h+4])=s,hideTrace($w[h+5])=s,hideTrace($w[h+6])=s,hideTrace($w[h+7])=s,hideTrace($w[h+8])=s,hideTrace($w[h+9])=s,hideTrace($w[h+10])=s,hideTrace($w[h+11])=s,hideTrace($w[h+12])=s,hideTrace($w[h+13])=s,hideTrace($w[h+14])=s,hideTrace($w[h+15])=s,hideTrace($w[h+16])=s,hideTrace($w[h+17])=s,hideTrace($w[h+18])=s,hideTrace($w[h+19])=s,hideTrace($w[h+20])=s,hideTrace($w[h+21])=s,hideTrace($w[h+22])=s,hideTrace($w[h+23])=s,hideTrace($w[h+24])=s,hideTrace($w[h+25])=s,hideTrace($w[h+26])=s,hideTrace($w[h+27])=s,hideTrace($w[h+28])=s,hideTrace($w[h+29])=s,hideTrace($w[h+30])=s,hideTrace($w[h+31])=s,hideTrace($w[h+32])=s,hideTrace($w[h+33])=s,hideTrace($w[h+34])=s,hideTrace($w[h+35])=s,hideTrace($w[h+36])=s,hideTrace($w[h+37])=s,hideTrace($w[h+38])=s,hideTrace($w[h+39])=s,hideTrace($w[h+40])=s,hideTrace($w[h+41])=s,hideTrace($w[h+42])=s,hideTrace($w[h+43])=s,hideTrace($w[h+44])=s,hideTrace($w[h+45])=s,hideTrace($w[h+46])=s,hideTrace($w[h+47])=s,hideTrace($w[h+48])=s,hideTrace($w[h+49])=s,hideTrace($w[h+50])=s,hideTrace($w[h+51])=s,hideTrace($w[h+52])=s,hideTrace($w[h+53])=s,hideTrace($w[h+54])=s,hideTrace($w[h+55])=s,hideTrace($w[h+56])=s,hideTrace($w[h+57])=s,hideTrace($w[h+58])=s,hideTrace($w[h+59])=s,hideTrace($w[h+60])=s,hideTrace($w[h+61])=s,hideTrace($w[h+62])=s,hideTrace($w[h+63])=s
					break
				case 32:
					ModifyGraph/W=$graph hideTrace($w[h])=s,hideTrace($w[h+1])=s,hideTrace($w[h+2])=s,hideTrace($w[h+3])=s,hideTrace($w[h+4])=s,hideTrace($w[h+5])=s,hideTrace($w[h+6])=s,hideTrace($w[h+7])=s,hideTrace($w[h+8])=s,hideTrace($w[h+9])=s,hideTrace($w[h+10])=s,hideTrace($w[h+11])=s,hideTrace($w[h+12])=s,hideTrace($w[h+13])=s,hideTrace($w[h+14])=s,hideTrace($w[h+15])=s,hideTrace($w[h+16])=s,hideTrace($w[h+17])=s,hideTrace($w[h+18])=s,hideTrace($w[h+19])=s,hideTrace($w[h+20])=s,hideTrace($w[h+21])=s,hideTrace($w[h+22])=s,hideTrace($w[h+23])=s,hideTrace($w[h+24])=s,hideTrace($w[h+25])=s,hideTrace($w[h+26])=s,hideTrace($w[h+27])=s,hideTrace($w[h+28])=s,hideTrace($w[h+29])=s,hideTrace($w[h+30])=s,hideTrace($w[h+31])=s
					break
				case 16:
					ModifyGraph/W=$graph hideTrace($w[h])=s,hideTrace($w[h+1])=s,hideTrace($w[h+2])=s,hideTrace($w[h+3])=s,hideTrace($w[h+4])=s,hideTrace($w[h+5])=s,hideTrace($w[h+6])=s,hideTrace($w[h+7])=s,hideTrace($w[h+8])=s,hideTrace($w[h+9])=s,hideTrace($w[h+10])=s,hideTrace($w[h+11])=s,hideTrace($w[h+12])=s,hideTrace($w[h+13])=s,hideTrace($w[h+14])=s,hideTrace($w[h+15])=s
					break
				case 8:
					ModifyGraph/W=$graph hideTrace($w[h])=s,hideTrace($w[h+1])=s,hideTrace($w[h+2])=s,hideTrace($w[h+3])=s,hideTrace($w[h+4])=s,hideTrace($w[h+5])=s,hideTrace($w[h+6])=s,hideTrace($w[h+7])=s
					break
				case 4:
					ModifyGraph/W=$graph hideTrace($w[h])=s,hideTrace($w[h+1])=s,hideTrace($w[h+2])=s,hideTrace($w[h+3])=s
					break
				case 2:
					ModifyGraph/W=$graph hideTrace($w[h])=s,hideTrace($w[h+1])=s
					break
				case 1:
					ModifyGraph/W=$graph hideTrace($w[h])=s
					break
				default:
					ASSERT(0, "Fail")
					break
			endswitch
		while(h)
	endif
End

///@brief Accelerated setting of line size of multiple traces in a graph
///@param[in] graph name of graph window
///@param[in] w 1D text wave with trace names
///@param[in] h number of traces in text wave
///@param[in] l new line size
Function AccelerateModLineSizeTraces(string graph, WAVE/T w, variable h, variable l)

	variable step

	if(h)
		do
			step = min(2 ^ trunc(log(h) / log(2)), 136)
			h -= step
			switch(step)
				case 136:
					ModifyGraph/W=$graph lsize($w[h])=l,lsize($w[h+1])=l,lsize($w[h+2])=l,lsize($w[h+3])=l,lsize($w[h+4])=l,lsize($w[h+5])=l,lsize($w[h+6])=l,lsize($w[h+7])=l,lsize($w[h+8])=l,lsize($w[h+9])=l,lsize($w[h+10])=l,lsize($w[h+11])=l,lsize($w[h+12])=l,lsize($w[h+13])=l,lsize($w[h+14])=l,lsize($w[h+15])=l,lsize($w[h+16])=l,lsize($w[h+17])=l,lsize($w[h+18])=l,lsize($w[h+19])=l,lsize($w[h+20])=l,lsize($w[h+21])=l,lsize($w[h+22])=l,lsize($w[h+23])=l,lsize($w[h+24])=l,lsize($w[h+25])=l,lsize($w[h+26])=l,lsize($w[h+27])=l,lsize($w[h+28])=l,lsize($w[h+29])=l,lsize($w[h+30])=l,lsize($w[h+31])=l,lsize($w[h+32])=l,lsize($w[h+33])=l,lsize($w[h+34])=l,lsize($w[h+35])=l,lsize($w[h+36])=l,lsize($w[h+37])=l,lsize($w[h+38])=l,lsize($w[h+39])=l,lsize($w[h+40])=l,lsize($w[h+41])=l,lsize($w[h+42])=l,lsize($w[h+43])=l,lsize($w[h+44])=l,lsize($w[h+45])=l,lsize($w[h+46])=l,lsize($w[h+47])=l,lsize($w[h+48])=l,lsize($w[h+49])=l,lsize($w[h+50])=l,lsize($w[h+51])=l,lsize($w[h+52])=l,lsize($w[h+53])=l,lsize($w[h+54])=l,lsize($w[h+55])=l,lsize($w[h+56])=l,lsize($w[h+57])=l,lsize($w[h+58])=l,lsize($w[h+59])=l,lsize($w[h+60])=l,lsize($w[h+61])=l,lsize($w[h+62])=l,lsize($w[h+63])=l,lsize($w[h+64])=l,lsize($w[h+65])=l,lsize($w[h+66])=l,lsize($w[h+67])=l,lsize($w[h+68])=l,lsize($w[h+69])=l,lsize($w[h+70])=l,lsize($w[h+71])=l,lsize($w[h+72])=l,lsize($w[h+73])=l,lsize($w[h+74])=l,lsize($w[h+75])=l,lsize($w[h+76])=l,lsize($w[h+77])=l,lsize($w[h+78])=l,lsize($w[h+79])=l,lsize($w[h+80])=l,lsize($w[h+81])=l,lsize($w[h+82])=l,lsize($w[h+83])=l,lsize($w[h+84])=l,lsize($w[h+85])=l,lsize($w[h+86])=l,lsize($w[h+87])=l,lsize($w[h+88])=l,lsize($w[h+89])=l,lsize($w[h+90])=l,lsize($w[h+91])=l,lsize($w[h+92])=l,lsize($w[h+93])=l,lsize($w[h+94])=l,lsize($w[h+95])=l,lsize($w[h+96])=l,lsize($w[h+97])=l,lsize($w[h+98])=l,lsize($w[h+99])=l,lsize($w[h+100])=l,lsize($w[h+101])=l,lsize($w[h+102])=l,lsize($w[h+103])=l,lsize($w[h+104])=l,lsize($w[h+105])=l,lsize($w[h+106])=l,lsize($w[h+107])=l,lsize($w[h+108])=l,lsize($w[h+109])=l,lsize($w[h+110])=l,lsize($w[h+111])=l,lsize($w[h+112])=l,lsize($w[h+113])=l,lsize($w[h+114])=l,lsize($w[h+115])=l,lsize($w[h+116])=l,lsize($w[h+117])=l,lsize($w[h+118])=l,lsize($w[h+119])=l,lsize($w[h+120])=l,lsize($w[h+121])=l,lsize($w[h+122])=l,lsize($w[h+123])=l,lsize($w[h+124])=l,lsize($w[h+125])=l,lsize($w[h+126])=l,lsize($w[h+127])=l,lsize($w[h+128])=l,lsize($w[h+129])=l,lsize($w[h+130])=l,lsize($w[h+131])=l,lsize($w[h+132])=l,lsize($w[h+133])=l,lsize($w[h+134])=l,lsize($w[h+135])=l
					break
				case 128:
					ModifyGraph/W=$graph lsize($w[h])=l,lsize($w[h+1])=l,lsize($w[h+2])=l,lsize($w[h+3])=l,lsize($w[h+4])=l,lsize($w[h+5])=l,lsize($w[h+6])=l,lsize($w[h+7])=l,lsize($w[h+8])=l,lsize($w[h+9])=l,lsize($w[h+10])=l,lsize($w[h+11])=l,lsize($w[h+12])=l,lsize($w[h+13])=l,lsize($w[h+14])=l,lsize($w[h+15])=l,lsize($w[h+16])=l,lsize($w[h+17])=l,lsize($w[h+18])=l,lsize($w[h+19])=l,lsize($w[h+20])=l,lsize($w[h+21])=l,lsize($w[h+22])=l,lsize($w[h+23])=l,lsize($w[h+24])=l,lsize($w[h+25])=l,lsize($w[h+26])=l,lsize($w[h+27])=l,lsize($w[h+28])=l,lsize($w[h+29])=l,lsize($w[h+30])=l,lsize($w[h+31])=l,lsize($w[h+32])=l,lsize($w[h+33])=l,lsize($w[h+34])=l,lsize($w[h+35])=l,lsize($w[h+36])=l,lsize($w[h+37])=l,lsize($w[h+38])=l,lsize($w[h+39])=l,lsize($w[h+40])=l,lsize($w[h+41])=l,lsize($w[h+42])=l,lsize($w[h+43])=l,lsize($w[h+44])=l,lsize($w[h+45])=l,lsize($w[h+46])=l,lsize($w[h+47])=l,lsize($w[h+48])=l,lsize($w[h+49])=l,lsize($w[h+50])=l,lsize($w[h+51])=l,lsize($w[h+52])=l,lsize($w[h+53])=l,lsize($w[h+54])=l,lsize($w[h+55])=l,lsize($w[h+56])=l,lsize($w[h+57])=l,lsize($w[h+58])=l,lsize($w[h+59])=l,lsize($w[h+60])=l,lsize($w[h+61])=l,lsize($w[h+62])=l,lsize($w[h+63])=l,lsize($w[h+64])=l,lsize($w[h+65])=l,lsize($w[h+66])=l,lsize($w[h+67])=l,lsize($w[h+68])=l,lsize($w[h+69])=l,lsize($w[h+70])=l,lsize($w[h+71])=l,lsize($w[h+72])=l,lsize($w[h+73])=l,lsize($w[h+74])=l,lsize($w[h+75])=l,lsize($w[h+76])=l,lsize($w[h+77])=l,lsize($w[h+78])=l,lsize($w[h+79])=l,lsize($w[h+80])=l,lsize($w[h+81])=l,lsize($w[h+82])=l,lsize($w[h+83])=l,lsize($w[h+84])=l,lsize($w[h+85])=l,lsize($w[h+86])=l,lsize($w[h+87])=l,lsize($w[h+88])=l,lsize($w[h+89])=l,lsize($w[h+90])=l,lsize($w[h+91])=l,lsize($w[h+92])=l,lsize($w[h+93])=l,lsize($w[h+94])=l,lsize($w[h+95])=l,lsize($w[h+96])=l,lsize($w[h+97])=l,lsize($w[h+98])=l,lsize($w[h+99])=l,lsize($w[h+100])=l,lsize($w[h+101])=l,lsize($w[h+102])=l,lsize($w[h+103])=l,lsize($w[h+104])=l,lsize($w[h+105])=l,lsize($w[h+106])=l,lsize($w[h+107])=l,lsize($w[h+108])=l,lsize($w[h+109])=l,lsize($w[h+110])=l,lsize($w[h+111])=l,lsize($w[h+112])=l,lsize($w[h+113])=l,lsize($w[h+114])=l,lsize($w[h+115])=l,lsize($w[h+116])=l,lsize($w[h+117])=l,lsize($w[h+118])=l,lsize($w[h+119])=l,lsize($w[h+120])=l,lsize($w[h+121])=l,lsize($w[h+122])=l,lsize($w[h+123])=l,lsize($w[h+124])=l,lsize($w[h+125])=l,lsize($w[h+126])=l,lsize($w[h+127])=l
					break
				case 64:
					ModifyGraph/W=$graph lsize($w[h])=l,lsize($w[h+1])=l,lsize($w[h+2])=l,lsize($w[h+3])=l,lsize($w[h+4])=l,lsize($w[h+5])=l,lsize($w[h+6])=l,lsize($w[h+7])=l,lsize($w[h+8])=l,lsize($w[h+9])=l,lsize($w[h+10])=l,lsize($w[h+11])=l,lsize($w[h+12])=l,lsize($w[h+13])=l,lsize($w[h+14])=l,lsize($w[h+15])=l,lsize($w[h+16])=l,lsize($w[h+17])=l,lsize($w[h+18])=l,lsize($w[h+19])=l,lsize($w[h+20])=l,lsize($w[h+21])=l,lsize($w[h+22])=l,lsize($w[h+23])=l,lsize($w[h+24])=l,lsize($w[h+25])=l,lsize($w[h+26])=l,lsize($w[h+27])=l,lsize($w[h+28])=l,lsize($w[h+29])=l,lsize($w[h+30])=l,lsize($w[h+31])=l,lsize($w[h+32])=l,lsize($w[h+33])=l,lsize($w[h+34])=l,lsize($w[h+35])=l,lsize($w[h+36])=l,lsize($w[h+37])=l,lsize($w[h+38])=l,lsize($w[h+39])=l,lsize($w[h+40])=l,lsize($w[h+41])=l,lsize($w[h+42])=l,lsize($w[h+43])=l,lsize($w[h+44])=l,lsize($w[h+45])=l,lsize($w[h+46])=l,lsize($w[h+47])=l,lsize($w[h+48])=l,lsize($w[h+49])=l,lsize($w[h+50])=l,lsize($w[h+51])=l,lsize($w[h+52])=l,lsize($w[h+53])=l,lsize($w[h+54])=l,lsize($w[h+55])=l,lsize($w[h+56])=l,lsize($w[h+57])=l,lsize($w[h+58])=l,lsize($w[h+59])=l,lsize($w[h+60])=l,lsize($w[h+61])=l,lsize($w[h+62])=l,lsize($w[h+63])=l
					break
				case 32:
					ModifyGraph/W=$graph lsize($w[h])=l,lsize($w[h+1])=l,lsize($w[h+2])=l,lsize($w[h+3])=l,lsize($w[h+4])=l,lsize($w[h+5])=l,lsize($w[h+6])=l,lsize($w[h+7])=l,lsize($w[h+8])=l,lsize($w[h+9])=l,lsize($w[h+10])=l,lsize($w[h+11])=l,lsize($w[h+12])=l,lsize($w[h+13])=l,lsize($w[h+14])=l,lsize($w[h+15])=l,lsize($w[h+16])=l,lsize($w[h+17])=l,lsize($w[h+18])=l,lsize($w[h+19])=l,lsize($w[h+20])=l,lsize($w[h+21])=l,lsize($w[h+22])=l,lsize($w[h+23])=l,lsize($w[h+24])=l,lsize($w[h+25])=l,lsize($w[h+26])=l,lsize($w[h+27])=l,lsize($w[h+28])=l,lsize($w[h+29])=l,lsize($w[h+30])=l,lsize($w[h+31])=l
					break
				case 16:
					ModifyGraph/W=$graph lsize($w[h])=l,lsize($w[h+1])=l,lsize($w[h+2])=l,lsize($w[h+3])=l,lsize($w[h+4])=l,lsize($w[h+5])=l,lsize($w[h+6])=l,lsize($w[h+7])=l,lsize($w[h+8])=l,lsize($w[h+9])=l,lsize($w[h+10])=l,lsize($w[h+11])=l,lsize($w[h+12])=l,lsize($w[h+13])=l,lsize($w[h+14])=l,lsize($w[h+15])=l
					break
				case 8:
					ModifyGraph/W=$graph lsize($w[h])=l,lsize($w[h+1])=l,lsize($w[h+2])=l,lsize($w[h+3])=l,lsize($w[h+4])=l,lsize($w[h+5])=l,lsize($w[h+6])=l,lsize($w[h+7])=l
					break
				case 4:
					ModifyGraph/W=$graph lsize($w[h])=l,lsize($w[h+1])=l,lsize($w[h+2])=l,lsize($w[h+3])=l
					break
				case 2:
					ModifyGraph/W=$graph lsize($w[h])=l,lsize($w[h+1])=l
					break
				case 1:
					ModifyGraph/W=$graph lsize($w[h])=l
					break
				default:
					ASSERT(0, "Fail")
					break
			endswitch
		while(h)
	endif
End

/// @brief Return the value and type of the popupmenu list
///
/// @retval value extracted string with the contents of `value` from the recreation macro
/// @retval type  popup menu list type, one of @ref PopupMenuListTypes
Function [string value, variable type] ParsePopupMenuValue(string recMacro)

	string listOrFunc, path, cmd, builtinPopupMenu

	SplitString/E="\\s*,\\s*value\\s*=\\s*(.*)$" recMacro, listOrFunc
	if(V_Flag != 1)
		Bug("Could not find popupmenu \"value\" entry")
		return ["", NaN]
	endif

	listOrFunc = trimstring(listOrFunc, 1)

	// unescape quotes
	listOrFunc = ReplaceString("\\\"", listOrFunc, "\"")

	// misc cleanup
	listOrFunc = RemovePrefix(listOrFunc, start = "#")
	listOrFunc = RemovePrefix(listOrFunc, start = "\"")
	listOrFunc = RemoveEnding(listOrFunc, "\"")

	SplitString/E="^\"\*([A-Z]{1,})\*\"$" listOrFunc, builtinPopupMenu

	if(V_flag == 1)
		return [builtinPopupMenu, POPUPMENULIST_TYPE_BUILTIN]
	endif

	return [listOrFunc, POPUPMENULIST_TYPE_OTHER]
End

/// @brief Return the popupmenu list entries
///
/// @param value String with a list or function (what you enter with PopupMenu value=\#XXX)
/// @param type  One of @ref PopupMenuListTypes
Function/S GetPopupMenuList(string value, variable type)
	string path, cmd

	switch(type)
		case POPUPMENULIST_TYPE_BUILTIN:
			strswitch(value)
				case "COLORTABLEPOP":
					return CTabList()
				default:
					ASSERT(0, "Not implemented")
			endswitch
		case POPUPMENULIST_TYPE_OTHER:
			path = GetTemporaryString()

			sprintf cmd, "%s = %s", path, value
			Execute/Z/Q cmd

			if(V_Flag)
				Bug("Execute returned an error :(")
				return ""
			endif

			SVAR str = $path
			return str
		default:
			ASSERT(0, "Missing popup menu list type")
	endswitch
End

#if IgorVersion() >= 9.0

/// @brief Enable show trace info tags for the current top graph
Function ShowTraceInfoTags()

	DoIgorMenu/C "Graph", "Show Trace Info Tags"

	if(cmpStr(S_value,"Hide Trace Info Tags"))
		DoIgorMenu/OVRD "Graph", "Show Trace Info Tags"
	endif
End

#endif

/// @brief Return the recreation macro and the type of the given control
Function [string recMacro, variable type] GetRecreationMacroAndType(string win, string control)

	ControlInfo/W=$win $control
	if(!V_flag)
		ASSERT(WindowExists(win), "The panel " + win + " does not exist.")
		ASSERT(0, "The control " + control + " in the panel " + win + " does not exist.")
	endif

	return [S_recreation, abs(V_flag)]
End

/// @brief Query a numeric GUI control property
Function GetControlSettingVar(string win, string control, string setting, [variable defValue])
	string match
	variable found

	if(ParamIsDefault(defValue))
		defValue = NaN
	endif

	[match, found] = GetControlSettingImpl(win, control, setting)

	if(!found)
		return defValue
	endif

	return str2numSafe(match)
End

/// @brief Query a string GUI control property
Function/S GetControlSettingStr(string win, string control, string setting, [string defValue])
	string match
	variable found

	if(ParamIsDefault(defValue))
		defValue = ""
	endif

	[match, found] = GetControlSettingImpl(win, control, setting)

	if(!found)
		return defValue
	endif

	return PossiblyUnquoteName(match, "\"")
End

static Function [string match, variable found] GetControlSettingImpl(string win, string control, string setting)
	string recMacro, str
	variable controlType

	[recMacro, controlType] = GetRecreationMacroAndType(win, control)

	SplitString/E=("(?i)\\Q" + setting + "\\E[[:space:]]*=[[:space:]]*([^,]+)") recMacro, str

	ASSERT(V_Flag == 0 || V_Flag == 1, "Unexpected number of matches")

	return [str, !!V_flag]
End

/// @brief Check and disable dependent controls
///
/// Enables a list of checkbox controls and stores their
/// current values as user data before disabling them. On switching back their
/// previous values are restored and they are also enabled again.
Function AdaptDependentControls(string device, string controls, variable newState)

	variable numControls, oldState, i
	string ctrl

	newState = !!newState
	numControls = ItemsInList(controls)

	if(newState)
		for(i = 0; i < numControls; i += 1)
			ctrl = StringFromList(i, controls)
			// store current state
			oldState = DAG_GetNumericalValue(device, ctrl)
			SetControlUserData(device, ctrl, "oldState", num2str(oldState))

			// and check
			PGC_SetAndActivateControl(device, ctrl, val = CHECKBOX_SELECTED)
		endfor

		// and disable
		DisableControls(device, controls)
	else
		// enable
		EnableControls(device, controls)

		for(i = 0; i < numControls; i += 1)
			ctrl = StringFromList(i, controls)

			// and read old state
			oldState = str2num(GetUserData(device, ctrl, "oldState"))

			// invalidate old state
			SetControlUserData(device, ctrl, "oldState", "")

			// set old state
			PGC_SetAndActivateControl(device, ctrl, val = oldState)
		endfor
	endif
End
