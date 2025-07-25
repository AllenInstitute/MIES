#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_GUI
#endif // AUTOMATED_TESTING

/// @file MIES_GuiUtilities.ipf
/// @brief Helper functions related to GUI controls

static StrConstant USERDATA_PREFIX = "userdata("
static StrConstant USERDATA_SUFFIX = ")"

static Constant AXIS_MODE_NO_LOG = 0

/// @brief Show a GUI control in the given window
Function ShowControl(string win, string control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")

	if((V_disable & HIDDEN_CONTROL_BIT) == 0)
		return NaN
	endif

	ModifyControl $control, win=$win, disable=(V_disable & ~HIDDEN_CONTROL_BIT)
End

/// @brief Show a list of GUI controls in the given window
Function ShowControls(string win, string controlList)

	variable i
	variable numItems = ItemsInList(controlList)
	string ctrl
	for(i = 0; i < numItems; i += 1)
		ctrl = StringFromList(i, controlList)
		ShowControl(win, ctrl)
	endfor
End

/// @brief Hide a GUI control in the given window
Function HideControl(string win, string control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")

	if(V_disable & HIDDEN_CONTROL_BIT)
		return NaN
	endif

	ModifyControl $control, win=$win, disable=(V_disable | HIDDEN_CONTROL_BIT)
End

/// @brief Hide a list of GUI controls in the given window
Function HideControls(string win, string controlList)

	variable i
	variable numItems = ItemsInList(controlList)
	string ctrl
	for(i = 0; i < numItems; i += 1)
		ctrl = StringFromList(i, controlList)
		HideControl(win, ctrl)
	endfor
End

/// @brief Enable a GUI control in the given window
Function EnableControl(string win, string control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")

	if((V_disable & DISABLE_CONTROL_BIT) == 0)
		return NaN
	endif

	ModifyControl $control, win=$win, disable=(V_disable & ~DISABLE_CONTROL_BIT)
End

/// @brief Enable a list of GUI controls in the given window
Function EnableControls(string win, string controlList)

	variable i
	variable numItems = ItemsInList(controlList)
	string ctrl
	for(i = 0; i < numItems; i += 1)
		ctrl = StringFromList(i, controlList)
		EnableControl(win, ctrl)
	endfor
End

/// @brief Disable a GUI control in the given window
Function DisableControl(string win, string control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")

	if(V_disable & DISABLE_CONTROL_BIT)
		return NaN
	endif

	ModifyControl $control, win=$win, disable=(V_disable | DISABLE_CONTROL_BIT)
End

/// @brief Disable a list of GUI controls in the given window
Function DisableControls(string win, string controlList)

	variable i
	variable numItems = ItemsInList(controlList)
	string ctrl
	for(i = 0; i < numItems; i += 1)
		ctrl = StringFromList(i, controlList)
		DisableControl(win, ctrl)
	endfor
End

/// @brief Set the title of a list of controls
Function SetControlTitles(string win, string controlList, string controlTitleList)

	variable i
	variable numItems = ItemsInList(controlList)
	ASSERT(numItems <= ItemsInList(controlTitleList), "List of control titles is too short")
	string controlName, newTitle
	for(i = 0; i < numItems; i += 1)
		controlName = StringFromList(i, controlList)
		newTitle    = StringFromList(i, controlTitleList)
		SetControlTitle(win, controlName, newTitle)
	endfor
End

/// @brief Set the title of a control
Function SetControlTitle(string win, string controlName, string newTitle)

	ControlInfo/W=$win $controlName
	ASSERT(V_flag != 0, "Non-existing control or window")

	ModifyControl $ControlName, WIN=$win, title=newTitle
End

/// @brief Set the procedure of a list of controls
Function SetControlProcedures(string win, string controlList, string newProcedure)

	variable i
	string   controlName
	variable numItems = ItemsInList(controlList)

	for(i = 0; i < numItems; i += 1)
		controlName = StringFromList(i, controlList)
		SetControlProcedure(win, controlName, newProcedure)
	endfor
End

/// @brief Set the procedure of a control
Function SetControlProcedure(string win, string controlName, string newProcedure)

	ControlInfo/W=$win $controlName
	ASSERT(V_flag != 0, "Non-existing control or window")

	ModifyControl $ControlName, WIN=$win, proc=$newProcedure
End

/// @brief Return the title of a control
///
/// @param recMacro     recreation macro for ctrl
/// @param supress      supress assertion that ctrl must have a title
/// @return Returns     the title or an empty string
Function/S GetTitle(string recMacro, [variable supress])

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
Function SetControlTitleColors(string win, string controlList, variable R, variable G, variable B)

	variable i
	variable numItems = ItemsInList(controlList)
	string controlName
	for(i = 0; i < numItems; i += 1)
		controlName = StringFromList(i, controlList)
		SetControlTitleColor(win, controlName, R, G, B)
	endfor
End

/// @brief Change color of a control
Function SetControlTitleColor(string win, string controlName, variable R, variable G, variable B) ///@todo store color in control user data, check for color change before applying change

	ControlInfo/W=$win $controlName
	ASSERT(V_flag != 0, "Non-existing control or window")

	ModifyControl $ControlName, WIN=$win, fColor=(R, G, B)
End

/// @brief Change color of a control
Function ChangeControlColor(string win, string controlName, variable R, variable G, variable B)

	ControlInfo/W=$win $controlName
	ASSERT(V_flag != 0, "Non-existing control or window")

	ModifyControl $ControlName, WIN=$win, fColor=(R, G, B)

End

/// @brief Change the font color of a control
Function ChangeControlValueColor(string win, string controlName, variable R, variable G, variable B)

	ControlInfo/W=$win $controlName
	ASSERT(V_flag != 0, "Non-existing control or window")

	ModifyControl $ControlName, WIN=$win, valueColor=(R, G, B)

End

/// @brief Change the font color of a list of controls
Function ChangeControlValueColors(string win, string controlList, variable R, variable G, variable B)

	variable i
	variable numItems = ItemsInList(controlList)
	string ctrl
	for(i = 0; i < numItems; i += 1)
		ctrl = StringFromList(i, controlList)
		ControlInfo/W=$win $ctrl
		ASSERT(V_flag != 0, "Non-existing control or window")
		//	ChangeControlValueColor(win, ctrl, R, G, B)
	endfor

	ModifyControlList controlList, WIN=$win, valueColor=(R, G, B)

End

/// @brief Changes the background color of a control
///
/// @param win         panel
/// @param controlName GUI control name
/// @param R           red
/// @param G           green
/// @param B           blue
/// @param Alpha defaults to opaque if not provided
Function SetControlBckgColor(string win, string controlName, variable R, variable G, variable B, [variable Alpha])

	if(paramIsDefault(Alpha))
		Alpha = 1
	endif
	ASSERT(Alpha > 0 && Alpha <= 1, "Alpha must be between 0 and 1")
	Alpha *= 65535
	ControlInfo/W=$win $controlName
	ASSERT(V_flag != 0, "Non-existing control or window")

	ModifyControl $ControlName, WIN=$win, valueBackColor=(R, G, B, Alpha)
End

/// @brief Change the background color of a list of controls
Function ChangeControlBckgColors(string win, string controlList, variable R, variable G, variable B)

	variable i
	variable numItems = ItemsInList(controlList)
	string ctrl
	for(i = 0; i < numItems; i += 1)
		ctrl = StringFromList(i, controlList)
		ControlInfo/W=$win $ctrl
		ASSERT(V_flag != 0, "Non-existing control or window")
		//	ChangeControlValueColor(win, ctrl, R, G, B)
	endfor

	ModifyControlList controlList, WIN=$win, valueBackColor=(R, G, B)

End

/// @brief Returns one if the checkbox is selected or zero if it is unselected
Function GetCheckBoxState(string win, string control)

	variable allowMissingControl

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(V_flag == CONTROL_TYPE_CHECKBOX, "Control is not a checkbox")
	return V_Value
End

/// @brief Set the internal number in a setvariable control
Function SetSetVariable(string win, string Control, variable newValue, [variable respectLimits])

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
		SetVariable $control, win=$win, value=_NUM:newValue
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
		SetVariable $control, win=$win, value=_STR:str, help={str}
	else
		SetVariable $control, win=$win, value=_STR:str
	endif
End

/// @brief Set the state of the checkbox
Function SetCheckBoxState(string win, string control, variable state)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_CHECKBOX, "Control is not a checkbox")

	state = !!state

	if(state != V_Value)
		CheckBox $control, win=$win, value=(state == CHECKBOX_SELECTED)
	endif

End

/// @brief Set the input limits for a setVariable control
Function SetSetVariableLimits(string win, string Control, variable low, variable high, variable increment)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_SETVARIABLE, "Control is not a setvariable")

	SetVariable $control, win=$win, limits={low, high, increment}
End

/// @brief Returns the contents of a SetVariable
///
/// UTF_NOINSTRUMENTATION
Function GetSetVariable(string win, string control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_SETVARIABLE, "Control is not a setvariable")
	return V_Value
End

/// @brief Returns the contents of a SetVariable with an internal string
Function/S GetSetVariableString(string win, string control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_SETVARIABLE, "Control is not a setvariable")
	if(IsNull(S_Value))
		return ""
	endif

	return S_Value
End

/// @brief Returns the current PopupMenu item as string
Function/S GetPopupMenuString(string win, string control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_POPUPMENU, "Control is not a popupmenu")
	if(IsNull(S_Value))
		return ""
	endif

	return S_Value
End

/// @brief Returns the zero-based index of a PopupMenu
Function GetPopupMenuIndex(string win, string control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_POPUPMENU, "Control is not a popupmenu")
	ASSERT(V_Value >= 1, "Invalid index")
	return V_Value - 1
End

/// @brief Sets the zero-based index of the PopupMenu
Function SetPopupMenuIndex(string win, string control, variable index)

	index += 1

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_POPUPMENU, "Control is not a popupmenu")
	ASSERT(index >= 0, "Invalid index")
	PopupMenu $control, win=$win, mode=index
End

/// @brief Sets the popupmenu value
Function SetPopupMenuVal(string win, string control, [string list, string func])

	string output, allEntries

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_POPUPMENU, "Control is not a popupmenu")

	if(!ParamIsDefault(list))
		sprintf output, "\"%s\"", List
		ASSERT(strlen(output) < MAX_COMMANDLINE_LENGTH, "Popup menu list is greater than MAX_COMMANDLINE_LENGTH characters")
	elseif(!ParamIsDefault(func))
		output     = func
		allEntries = GetPopupMenuList(func, POPUPMENULIST_TYPE_OTHER)
		ASSERT(!IsEmpty(allEntries), "func does not generate a non-empty string list.")
	endif

	PopupMenu $control, win=$win, value=#output
End

/// @brief Sets the popupmenu string
///
/// @param win     target window
/// @param control target control
/// @param str     popupmenu string to select. Supports wildcard character(*)
///
/// @return set string with wildcard expanded
Function/S SetPopupMenuString(string win, string control, string str)

	string result

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_POPUPMENU, "Control is not a popupmenu")
	PopupMenu $control, win=$win, popmatch=str

	result = GetPopupMenuString(win, control)

	ASSERT(stringMatch(result, str), "str: \"" + str + "\" is not in the popupmenus \"" + control + "\" list")

	return result
End

/// @brief Returns the contents of a ValDisplay
Function/S GetValDisplayAsString(string win, string control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_VALDISPLAY, "Control is not a val display")
	if(IsNull(S_Value))
		return ""
	endif

	return S_value
End

/// @brief Returns the contents of a ValDisplay as a number
Function GetValDisplayAsNum(string win, string control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_VALDISPLAY, "Control is not a val display")
	return V_Value
End

/// @brief Returns the slider position
Function GetSliderPositionIndex(string win, string control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_SLIDER, "Control is not a slider")
	return V_value
End

/// @brief Sets the slider position
Function SetSliderPositionIndex(string win, string control, variable index)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ASSERT(abs(V_flag) == CONTROL_TYPE_SLIDER, "Control is not a slider")
	Slider $control, win=$win, value=index
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
Function SetValDisplay(string win, string control, [variable var, string str, string format])

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
		FATAL_ERROR("Unexpected parameter combination")
	endif

	// Don't update if the content does not change, prevents flickering
	if(CmpStr(GetValDisplayAsString(win, control), formattedString) == 0)
		return NaN
	endif

	ValDisplay $control, win=$win, value=#formattedString
End

/// @brief Check if a given control exists
Function ControlExists(string win, string control)

	ControlInfo/W=$win $control
	return V_flag != 0
End

/// @brief Return the full subwindow path to the windows the control belongs to
Function/S FindControl(string control)

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
Function/S FindNotebook(string nb)

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
Function GetTabID(string win, string ctrl)

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
Function SetControlUserData(string win, string control, string key, string value)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	ModifyControl $control, win=$win, userdata($key)=value
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
			s.red = 7967; s.green = 7710; s.blue = 7710
			break

		case 1:
			s.red = 60395; s.green = 52685; s.blue = 15934
			break

		case 2:
			s.red = 28527; s.green = 12336; s.blue = 35723
			break

		case 3:
			s.red = 56283; s.green = 27242; s.blue = 10537
			break

		case 4:
			s.red = 38807; s.green = 52942; s.blue = 59110
			break

		case 5:
			s.red = 47545; s.green = 8224; s.blue = 13878
			break

		case 6:
			s.red = 49858; s.green = 48316; s.blue = 33410
			break

		case 7:
			s.red = 32639; s.green = 32896; s.blue = 33153
			break

		case 8:
			s.red = 25186; s.green = 42662; s.blue = 18247
			break

		case 9:
			s.red = 54227; s.green = 34438; s.blue = 45746
			break

		case 10:
			s.red = 17733; s.green = 30840; s.blue = 46003
			break

		case 11:
			s.red = 56540; s.green = 33924; s.blue = 25957
			break

		case 12:
			s.red = 18504; s.green = 14392; s.blue = 38550
			break

		case 13:
			s.red = 57825; s.green = 41377; s.blue = 12593
			break

		case 14:
			s.red = 37265; s.green = 10023; s.blue = 35723
			break

		case 15:
			s.red = 59881; s.green = 59624; s.blue = 22359
			break

		case 16:
			s.red = 32125; s.green = 5911; s.blue = 5654
			break

		case 17:
			s.red = 37779; s.green = 44461; s.blue = 15420
			break

		case 18:
			s.red = 28270; s.green = 13621; s.blue = 5397
			break

		case 19:
			s.red = 53713; s.green = 11565; s.blue = 10023
			break

		case 20:
			s.red = 11308; s.green = 13878; s.blue = 5911
			break

		default:
			FATAL_ERROR("Invalid index")
			break
	endswitch
End

/// @brief Returns the trace color used for avergae type traces
Function [STRUCT RGBColor s] GetTraceColorForAverage()

	[s] = GetTraceColor(NUM_HEADSTAGES + 1)

End

/// @brief Get colors from alternative color scheme
///
/// Uses 8 colors with maximum contrast for colorblind people, see
/// https://www.wavemetrics.com/code-snippet/distinguishable-color-index and
/// https:// jfly.iam.u-tokyo.ac.jp/color/
///
/// @sa GetTraceColor
Function [STRUCT RGBColor s] GetTraceColorAlternative(variable index)

	index = mod(index, 8)

	switch(index)
		case 0:
			s.red = 0; s.green = 0; s.blue = 0
			break
		case 1:
			s.red = 59110; s.green = 40863; s.blue = 0
			break
		case 2:
			s.red = 22102; s.green = 46260; s.blue = 59881
			break
		case 3:
			s.red = 0; s.green = 40606; s.blue = 29555
			break
		case 4:
			s.red = 61680; s.green = 58596; s.blue = 16962
			break
		case 5:
			s.red = 0; s.green = 29298; s.blue = 45746
			break
		case 6:
			s.red = 54741; s.green = 24158; s.blue = 0
			break
		case 7:
			s.red = 52428; s.green = 31097; s.blue = 42919
			break
		default:
			FATAL_ERROR("Invalid index")
	endswitch

	return [s]
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
/// @param[in] mode  [optional:default #AXIS_RANGE_DEFAULT] optional mode option, see @ref AxisPropModeConstants
///
/// @return minimum and maximum value of the axis range
Function [variable minimum, variable maximum] GetAxisRange(string graph, string axis, [variable mode])

	string info

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

	[minimum, maximum] = GetAxisRangeFromInfo(graph, info, axis, mode)
End

static Function [variable minimum, variable maximum] GetAxisRangeFromInfo(string graph, string info, string axis, variable mode)

	string flags

	if(mode == AXIS_RANGE_DEFAULT)
		flags = StringByKey("SETAXISFLAGS", info)
		if(!isEmpty(flags))
			// axis is in auto scale mode
			return [NaN, NaN]
		endif
	elseif(mode & AXIS_RANGE_INC_AUTOSCALED)
		// do nothing
	else
		FATAL_ERROR("Unknown mode from AxisPropModeConstants for this function")
	endif

	GetAxis/W=$graph/Q $axis
	return [V_min, V_max]
End

/// @brief Return the orientation of the axis as numeric value
/// @returns one of @ref AxisOrientationConstants
Function GetAxisOrientation(string graph, string axes)

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
		default:
			DoAbortNow("unknown axis type")
			break
	endswitch
End

/// @brief Return the recreation macro for an axis
static Function/S GetAxisRecreationMacro(string info)

	string   key
	variable index

	// straight from the AxisInfo help
	key   = ";RECREATION:"
	index = strsearch(info, key, 0)

	return info[index + strlen(key), Inf]
End

/// @brief Return the logmode of the axis
///
/// @return One of @ref ModifyGraphLogModes
Function GetAxisLogMode(string graph, string axis)

	string info

	info = AxisInfo(graph, axis)

	if(IsEmpty(info))
		return NaN
	endif

	return GetAxisLogModeFromInfo(info)
End

static Function GetAxisLogModeFromInfo(string info)

	string recMacro

	recMacro = GetAxisRecreationMacro(info)
	return NumberByKey("log(x)", recMacro, "=")
End

/// @brief Returns a wave with the minimum and maximum
/// values of each axis
///
/// Use SetAxesRanges to set the minimum and maximum values
/// @see GetAxisRange
/// @param[in] graph Name of graph
/// @param[in] axesRegexp [optional: default not set] filter axes names list by this optional regular expression
/// @param[in] orientation [optional: default not set] filter orientation of axes see @ref AxisOrientationConstants
/// @param[in] mode [optional: default #AXIS_RANGE_DEFAULT] filter returned axis information by mode see @ref AxisPropModeConstants
/// @return free wave with rows = axes, cols = axes info, dimlabel of rows is axis name
Function/WAVE GetAxesProperties(string graph, [string axesRegexp, variable orientation, variable mode])

	string list, axis, recMacro, info
	variable numAxes, i, countAxes, minimum, maximum, axisOrientation, logMode

	if(ParamIsDefault(mode))
		mode = AXIS_RANGE_DEFAULT
	endif

	list = AxisList(graph)

	if(!ParamIsDefault(axesRegexp))
		list = GrepList(list, axesRegexp)
	endif

	list    = SortList(list)
	numAxes = ItemsInList(list)

	Make/FREE/D/N=(numAxes, 4) props = 0
	SetDimLabel COLS, 0, minimum, props
	SetDimLabel COLS, 1, maximum, props
	SetDimLabel COLS, 2, axisType, props
	SetDimLabel COLS, 3, logMode, props

	for(i = 0; i < numAxes; i += 1)
		axis            = StringFromList(i, list)
		axisOrientation = GetAxisOrientation(graph, axis)
		if(!ParamIsDefault(orientation) && !(axisOrientation & orientation))
			continue
		endif

		info = AxisInfo(graph, axis)

		[minimum, maximum]          = GetAxisRangeFromInfo(graph, info, axis, mode)
		props[countAxes][%axisType] = axisOrientation
		props[countAxes][%minimum]  = minimum
		props[countAxes][%maximum]  = maximum

		props[countAxes][%logMode] = GetAxisLogModeFromInfo(info)

		SetDimLabel ROWS, countAxes, $axis, props
		countAxes += 1
	endfor

	if(countAxes != numAxes)
		Redimension/N=(countAxes, -1) props
	endif

	return props
End

/// @brief Set the properties of all axes as stored by GetAxesProperties
///
/// Includes a heuristic if the name of the axis changed after GetAxesProperties.
/// The axis range is also restored if its index in the sorted axis list and its
/// orientation is the same.
///
/// @see GetAxisProps
/// @param[in] graph Name of graph
/// @param[in] props wave with graph props as set in @ref GetAxesProperties
/// @param[in] axesRegexp [optional: default not set] filter axes names list by this optional regular expression
/// @param[in] orientation [optional: default not set] filter orientation of axes see @ref AxisOrientationConstants
/// @param[in] mode [optional: default 0] axis set mode see @ref AxisPropModeConstants
Function SetAxesProperties(string graph, WAVE props, [string axesRegexp, variable orientation, variable mode])

	variable numRows, numAxes, i, minimum, maximum, axisOrientation
	variable col, row, prevAxisMin, prevAxisMax, logMode
	string axis, list

	ASSERT(windowExists(graph), "Graph does not exist")

	if(ParamIsDefault(mode))
		mode = AXIS_RANGE_DEFAULT
	endif

	prevAxisMin = NaN

	numRows = DimSize(props, ROWS)

	list = AxisList(graph)

	if(!ParamIsDefault(axesRegexp))
		list = GrepList(list, axesRegexp)
	endif

	list    = SortList(list)
	numAxes = ItemsInList(list)

	for(i = 0; i < numAxes; i += 1)
		axis            = StringFromList(i, list)
		axisOrientation = GetAxisOrientation(graph, axis)
		if(!ParamIsDefault(orientation) && axisOrientation != orientation)
			continue
		endif

		row = FindDimLabel(props, ROWS, axis)

		if(row >= 0)
			minimum = props[row][%minimum]
			maximum = props[row][%maximum]
			logMode = props[row][%logMode]
		else
			// axis does not exist
			if(mode & AXIS_RANGE_USE_MINMAX)
				// use MIN/MAX of previous axes
				if(isNaN(prevAxisMin))
					// need to retrieve once
					col = FindDimLabel(props, COLS, "maximum")
					WaveStats/Q/M=1/RMD=[][col] props
					prevAxisMax = V_Max
					col         = FindDimLabel(props, COLS, "minimum")
					WaveStats/Q/M=1/RMD=[][col] props
					prevAxisMin = V_Min
				endif
				minimum = prevAxisMin
				maximum = prevAxisMax
				logMode = AXIS_MODE_NO_LOG
			elseif(mode == AXIS_RANGE_DEFAULT)
				// probably just name has changed, try the axis at the current index and check if the orientation is correct
				if(i < numRows && axisOrientation == props[i][%axisType])
					minimum = props[i][%minimum]
					maximum = props[i][%maximum]
					logMode = props[i][%logMode]
				else
					continue
				endif
			else
				FATAL_ERROR("Unknown mode from AxisPropModeConstants for this function")
			endif
		endif

		if(IsFinite(minimum) && IsFinite(maximum))
			SetAxis/W=$graph $axis, minimum, maximum
		endif

		ModifyGraph/W=$graph log($axis)=logMode
	endfor
End

/// @brief Returns the next axis name in a row of *consecutive*
/// and already existing axis names
Function/S GetNextFreeAxisName(string graph, string axesBaseName)

	variable numAxes

	numAxes = ItemsInList(ListMatch(AxisList(graph), axesBaseName + "*"))

	return axesBaseName + num2str(numAxes)
End

/// @brief Return a unique axis name
Function/S GetUniqueAxisName(string graph, string axesBaseName)

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

	FATAL_ERROR("Could not find a free axis name")
End

/// @brief Generic wrapper for setting a control's value
/// pass in the value as a string, and then decide whether to change to a number based on the type of control
Function SetGuiControlValue(string win, string control, string value)

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
			FATAL_ERROR("SetVariable globals are not supported")
		endif
	elseif(controlType == CONTROL_TYPE_POPUPMENU)
		SetPopupMenuIndex(win, control, str2num(value))
	elseif(controlType == CONTROL_TYPE_SLIDER)
		Slider $control, win=$win, value=str2num(value)
	else
		FATAL_ERROR("Unsupported control type") // if I get this, something's really gone pear shaped
	endif
End

/// @brief Generic wrapper for getting a control's value
Function/S GetGuiControlValue(string win, string control)

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
			FATAL_ERROR("SetVariable globals are not supported")
		endif
	elseif(controlType == CONTROL_TYPE_POPUPMENU)
		value = num2str(GetPopupMenuIndex(win, control))
	elseif(controlType == CONTROL_TYPE_TAB)
		value = num2istr(V_value)
	else
		value = ""
	endif

	return value
End

/// @brief Generic wrapper for getting a controls state (enabled, hidden, disabled)
Function/S GetGuiControlState(string win, string control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")

	return num2str(V_disable)
End

/// @brief Generic wrapper for setting a controls state (enabled, hidden, disabled)
Function SetGuiControlState(string win, string control, string controlState)

	variable controlType

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")

	ModifyControl $control, win=$win, disable=str2num(controlState)
End

/// @brief Return one if the given control is disabled,
/// zero otherwise
Function IsControlDisabled(string win, string control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")

	return (V_disable & DISABLE_CONTROL_BIT) == DISABLE_CONTROL_BIT
End

/// @brief Return one if the given control is hidden,
/// zero otherwise
Function IsControlHidden(string win, string control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")

	return (V_disable & HIDDEN_CONTROL_BIT) == HIDDEN_CONTROL_BIT
End

/// @brief Return the main window name from a full subwindow specification
///
/// @param subwindow window name including subwindows, e.g. `panel#subWin1#subWin2`
///
/// UTF_NOINSTRUMENTATION
Function/S GetMainWindow(string subwindow)

	return StringFromList(0, subwindow, "#")
End

/// @brief Return the currently active window
///
/// UTF_NOINSTRUMENTATION
Function/S GetCurrentWindow()

	GetWindow kwTopWin, activesw
	return s_value
End

/// @brief Return a 1D text wave with all infos about the cursors
///
/// Returns an invalid wave reference when no cursors are present. Counterpart
/// to RestoreCursors().
///
/// The data is sorted like `CURSOR_NAMES`.
Function/WAVE GetCursorInfos(string graph)

	Make/T/FREE/N=(ItemsInList(CURSOR_NAMES)) wv = CsrInfo($StringFromList(p, CURSOR_NAMES), graph)

	if(!HasOneValidEntry(wv))
		return $""
	endif

	return wv
End

/// @brief Restore the cursors from the info of GetCursorInfos().
Function RestoreCursors(string graph, WAVE/Z/T cursorInfos)

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
			info             = ReplaceWordInString(cursorTrace, info, replacementTrace)
		endif

		Execute StringByKey("RECREATION", info)
	endfor
End

/// @brief Return the infos for all annotations on the graph
Function/WAVE GetAnnotationInfo(string graph)

	variable numEntries
	string   annotations

	annotations = AnnotationList(graph)
	numEntries  = ItemsInList(annotations)

	if(numEntries == 0)
		return $""
	endif

	Make/FREE/N=(numEntries)/T annoInfo = AnnotationInfo(graph, StringFromList(p, annotations))

	SetDimensionLabels(annoInfo, annotations, ROWS)

	return annoInfo
End

/// @brief Restore annotation positions
Function RestoreAnnotationPositions(string graph, WAVE/T annoInfo)

	variable i, idx, numEntries, xPos, yPos
	string annotations, name, infoStr, flags, anchor

	annotations = AnnotationList(graph)
	numEntries  = ItemsInList(annotations)

	if(numEntries == 0)
		return NaN
	endif

	for(i = 0; i < numEntries; i += 1)

		name = StringFromList(i, annotations)
		idx  = FindDimLabel(annoInfo, ROWS, name)

		if(idx < 0)
			continue
		endif

		infoStr = annoInfo[idx]

		flags = StringByKey("FLAGS", infoStr)

		xPos   = NumberByKey("X", flags, "=", "/")
		yPos   = NumberByKey("Y", flags, "=", "/")
		anchor = StringByKey("A", flags, "=", "/")

		TextBox/W=$graph/N=$name/C/X=(xPos)/Y=(yPos)/A=$anchor
	endfor
End

/// @brief Remove the annotations given by the `regexp` from annoInfo and return the filtered wave
Function/WAVE FilterAnnotations(WAVE/T annoInfo, string regexp)

	variable i, numEntries
	string name

	Duplicate/FREE/T annoInfo, annoInfoResult
	WaveClear annoInfo

	numEntries = DimSize(annoInfoResult, ROWS)
	for(i = numEntries - 1; i >= 0; i -= 1)
		name = GetDimLabel(annoInfoResult, ROWS, i)
		if(GrepString(name, regexp))
			DeletePoints/M=(ROWS) i, 1, annoInfoResult
		endif
	endfor

	return annoInfoResult
End

/// @brief Autoscale all vertical axes in the visible x range
Function AutoscaleVertAxisVisXRange(string graph)

	string axList, axis
	variable i, numAxes, axisOrient

	axList  = AxisList(graph)
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
Function GetInternalSetVariableType(string recMacro)

	ASSERT(strsearch(recMacro, "SetVariable", 0) != -1, "recreation macro is not from a SetVariable")

	variable builtinString = (strsearch(recMacro, "_STR:\"", 0) != -1)
	variable builtinNumber = (strsearch(recMacro, "_NUM:", 0) != -1)

	ASSERT((builtinString + builtinNumber) != 2, "SetVariable can not hold both numeric and string contents")

	if(builtinString)
		return SET_VARIABLE_BUILTIN_STR
	elseif(builtinNumber)
		return SET_VARIABLE_BUILTIN_NUM
	endif

	return SET_VARIABLE_GLOBAL
End

Function ExtractLimitsFromRecMacro(string recMacro, variable &minVal, variable &maxVal, variable &incVal)

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
Function ExtractLimits(string win, string control, variable &minVal, variable &maxVal, variable &incVal)

	string minStr, maxStr, incStr

	string   recMacro
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
Function CheckIfValueIsInsideLimits(string win, string control, variable val)

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
Function GetFunctionParameterType(string func, variable paramIndex)

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
/// .. code-block:: igorpro
///
///		PopupMenu popup_ctrl,pos={1.00,1.00},size={55.00,19.00},proc=PGCT_PopMenuProc
///		PopupMenu popup_ctrl,mode=1,popvalue="Entry1",value= #"\"Entry1;Entry2;Entry3\""
/// \endrst
///
/// This function allows to extract key/value pairs from it.
///
/// @param key      non-empty string (must be followed by `=` in the recreation macro)
/// @param recMacro GUI control recreation macro as returned by `ControlInfo`
Function/S GetValueFromRecMacro(string key, string recMacro)

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
		FATAL_ERROR("impossible case")
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
Function SearchForInvalidControlProcs(string win, [variable warnOnEmpty])

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
		warnOnEmpty = !!warnOnEmpty
	endif

	if(WinType(win) != 7 && WinType(win) != 1) // ignore everything except panels and graphs
		return 0
	endif

	subwindowList = ChildWindowList(win)
	numEntries    = ItemsInList(subwindowList)
	for(i = 0; i < numEntries; i += 1)
		subwindow = win + "#" + StringFromList(i, subWindowList)
		result    = result || SearchForInvalidControlProcs(subwindow, warnOnEmpty = warnOnEmpty)
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
Function GetNumericSubType(string subType)

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
			FATAL_ERROR("Unsupported control subType")
			break
	endswitch
End

/// @brief Return the numeric control type
///
/// @return one of @ref GUIControlTypes
Function GetControlType(string win, string control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	return abs(V_flag)
End

/// @brief Determines if control stores numeric or text data
Function DoesControlHaveInternalString(string recMacro)

	return strsearch(recMacro, "_STR:", 0) != -1
End

/// @brief Returns checkbox mode
Function GetCheckBoxMode(string win, string checkBoxName)

	variable first, mode
	string modeString
	ControlInfo/W=$win $checkBoxName
	ASSERT(V_flag == 2, "not a checkBox control")
	first = strsearch(S_recreation, "mode=", 0, 2)
	if(first == -1)
		return 0
	endif

	sscanf S_recreation[first, first + 5], "mode=%d", mode
	ASSERT(IsFinite(mode), "Unexpected checkbox mode")
	return mode
End

/// @brief Returns the selected row of the ListBox for some modes
///        without selection waves
Function GetListBoxSelRow(string win, string ctrl)

	ControlInfo/W=$win $ctrl
	ASSERT(V_flag == 11, "Not a listbox control")

	return V_Value
End

/// @brief Set the listbox selection
///
/// @param win  panel
/// @param ctrl control
/// @param val  One of @ref ListBoxSelectionWaveFlags
/// @param row  row index
/// @param col  [optional, defaults to all columns] column index
Function SetListBoxSelection(string win, string ctrl, variable val, variable row, [variable col])

	variable colStart, colEnd

	if(ParamIsDefault(col))
		colStart = 0
		colEnd   = Inf
	else
		colStart = col
		colEnd   = col
	endif

	ControlInfo/W=$win $ctrl
	ASSERT(V_flag == 11, "Not a listbox control")
	WAVE/Z selWave = $GetValueFromRecMacro("selWave", S_recreation)
	ASSERT(WaveExists(selWave), "Missing selection wave")

	ASSERT(row < DimSize(selWave, ROWS), "Invalid row")
	ASSERT(col < DimSize(selWave, COLS), "Invalid col")

	selWave[row][colStart, colEnd][0][0] = val
End

/// @brief Check if the location `loc` is inside the rectangle `r`
Function IsInsideRect(STRUCT Point &loc, STRUCT RectF &r)

	return loc.h >= r.left     \
	       && loc.h <= r.right \
	       && loc.v >= r.top   \
	       && loc.v <= r.bottom
End

/// @brief Return the coordinates of the control borders
///        relative to the top left corner in pixels
Function GetControlCoordinates(string win, string ctrl, STRUCT RectF &s)

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

	Notebook $win, getData=mode

	return S_Value
End

/// @brief Replace the contents of the notebook
Function ReplaceNotebookText(string win, string text)

	ASSERT(WinType(win) == 5, "Passed win is not a notebook")

	Notebook $win, selection={startOfFile, endOfFile}
	ASSERT(!V_Flag, "Illegal selection")

	Notebook $win, setData=text
End

/// @brief Append to a notebook
Function AppendToNotebookText(string win, string text)

	ASSERT(WinType(win) == 5, "Passed win is not a notebook")

	Notebook $win, selection={endOfFile, endOfFile}
	ASSERT(!V_Flag, "Illegal selection")

	Notebook $win, setData=text
End

/// @brief Select the end in the given notebook.
///
/// The selection is the place where the user would naïvely enter new text.
Function NotebookSelectionAtEnd(string win)

	ASSERT(WinType(win) == 5, "Passed win is not a notebook")

	Notebook $win, selection={endOfFile, endOfFile}, findText={"", 1}
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

		EnsureLargeEnoughWave(userKeys, indexShouldExist = count)
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
Function/S ControlTypeToName(variable ctrlType)

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
Function Name2ControlType(string ctrlName)

	variable pos
	pos = WhichListItem(ctrlName, EXPCONFIG_GUI_CTRLLIST)
	if(pos < 0)
		return NaN
	endif
	return NumberFromList(pos, EXPCONFIG_GUI_CTRLTYPES)
End

/// @brief Checks if a certain window can act as valid host for subwindows
///        developer note: The only integrated Igor function that does this is ChildWindowList.
///        Though, ChildWindowList generates an RTE for non-valid windows, where this check function does not.
///
/// @param wName window name that should be checked to be a valid host for subwindows
/// @returns 1 if window is a valid host, 0 otherwise
Function WindowTypeCanHaveChildren(string wName)

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
Function/S GetAllWindows(string wName)

	string windowList = ""
	GetAllWindowsImpl(wName, windowList)

	return windowList
End

static Function GetAllWindowsImpl(string wName, string &windowList)

	string children
	variable i, numChildren, err

	windowList = AddListItem(wName, windowList, ";", Inf)

	if(!WindowTypeCanHaveChildren(wName))
		return NaN
	endif

	children    = ChildWindowList(wName)
	numChildren = ItemsInList(children, ";")
	for(i = 0; i < numChildren; i += 1)
		GetAllWindowsImpl(wName + "#" + StringFromList(i, children, ";"), windowList)
	endfor
End

Function IsSubwindow(string win)

	return ItemsInList(win, "#") > 1
End

/// @brief Conversion between pixel <-> points
///
///@{
Function PointsToPixel(variable var)

	return var * (ScreenResolution / 72)
End

Function PixelToPoints(variable var)

	return var * (72 / ScreenResolution)
End
///@}

/// @brief Checks if a window is tagged as certain type
///
/// @param[in] device Window name to check
/// @param[in] typeTag one of PANELTAG_* constants @sa panelTags
/// returns 1 if window is a DA_Ephys panel
Function PanelIsType(string device, string typeTag)

	if(!WindowExists(device))
		return 0
	endif

	return !CmpStr(GetUserData(device, "", EXPCONFIG_UDATA_PANELTYPE), typeTag)
End

/// @brief Show a contextual popup menu which allows the user to change the set variable limit's increment
///
/// - Expects the ctrl to have the named user data "DefaultIncrement"
/// - Works only on right mouse click on the title or the value field, *not* the up/down arrow buttons
Function ShowSetVariableLimitsSelectionPopup(STRUCT WMSetVariableAction &sva)

	string win, ctrl, items, defaultIncrementStr, elem
	variable minVal, maxVal, incVal, defaultIncrement, index

	win  = sva.win
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
	defaultIncrement    = str2numSafe(defaultIncrementStr)
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
			subDigits = (length > 1) ? 0 : abs(floor(log(length) / log(10)))
			sprintf str, "%.*f%s%s", subDigits, length, SelectString(newlineBeforeUnit, NUMBER_UNIT_SPACE, "\r"), unit

			xPos = x0 - labelOffset
			yPos = min(y0, y1) + abs(y0 - y1) / 2

			sprintf msg, "Text: (%g, %g)\r", xPos, yPos
			DEBUGPRINT(msg)

			SetDrawEnv/W=$graph textxjust=2, textyjust=1
		elseif(y0 == y1)
			length = abs(x0 - x1)

			ASSERT(!IsEmpty(unit), "empty unit")
			subDigits = (length > 1) ? 0 : abs(floor(log(length) / log(10)))
			sprintf str, "%.*f%s%s", subDigits, length, SelectString(newlineBeforeUnit, NUMBER_UNIT_SPACE, "\r"), unit

			xPos = min(x0, x1) + abs(x0 - x1) / 2
			yPos = y0 - labelOffset

			sprintf msg, "Text: (%g, %g)\r", xPos, yPos
			DEBUGPRINT(msg)

			SetDrawEnv/W=$graph textxjust=1, textyjust=2
		else
			FATAL_ERROR("Unexpected combination")
		endif

		DrawText/W=$graph xPos, yPos, str
	endif

	DrawLine/W=$graph x0, y0, x1, y1
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
		case POPUPMENULIST_TYPE_BUILTIN: // fallthrough
			strswitch(value)
				case "COLORTABLEPOP":
					return CTabList()
				default:
					FATAL_ERROR("Not implemented")
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
			FATAL_ERROR("Missing popup menu list type")
	endswitch
End

/// @brief Enable show trace info tags globally
Function ShowTraceInfoTags()

	Display
	// Window must not be hidden
	// Returns in S_value the state before toggling
	DoIgorMenu/OVRD "Graph", "Show Trace Info Tags"
	if(IsNull(S_value))
		KillWindow/Z $S_name
		return NaN
	endif
	if(IsEmpty(S_value))
		KillWindow/Z $S_name
		return NaN
	endif
	if(CmpStr(S_value, "Show Trace Info Tags"))
		// toggled to "Show Trace Info Tags", need to toggle back
		DoIgorMenu/OVRD "Graph", "Show Trace Info Tags"
	endif
	KillWindow/Z $S_name
End

/// @brief Return the recreation macro and the type of the given control
Function [string recMacro, variable type] GetRecreationMacroAndType(string win, string control)

	ControlInfo/W=$win $control
	if(!V_flag)
		ASSERT(WindowExists(win), "The panel " + win + " does not exist.")
		FATAL_ERROR("The control " + control + " in the panel " + win + " does not exist.")
	endif

	return [S_recreation, abs(V_flag)]
End

/// @brief Query a numeric GUI control property
Function GetControlSettingVar(string recMacro, string setting, [variable defValue])

	string   match
	variable found

	if(ParamIsDefault(defValue))
		defValue = NaN
	endif

	[match, found] = GetControlSettingImpl(recMacro, setting)

	if(!found)
		return defValue
	endif

	return str2numSafe(match)
End

/// @brief Query a string GUI control property
Function/S GetControlSettingStr(string recMacro, string setting, [string defValue])

	string   match
	variable found

	if(ParamIsDefault(defValue))
		defValue = ""
	endif

	[match, found] = GetControlSettingImpl(recMacro, setting)

	if(!found)
		return defValue
	endif

	return PossiblyUnquoteName(match, "\"")
End

static Function [string match, variable found] GetControlSettingImpl(string recMacro, string setting)

	string str

	SplitString/E=("(?i)\\Q" + setting + "\\E[[:space:]]*=[[:space:]]*([^,]+)") recMacro, str

	ASSERT(V_Flag == 0 || V_Flag == 1, "Unexpected number of matches")

	return [str, !!V_flag]
End

/// @brief Dependent on a control state set the state of a list of checkboxes
///
/// newMainState: state of the main control after the user interaction, in an event handler typically the cba.checked value
/// restoreOnState: If the newMainState is different from the restoreOnState then the states of the dependent checkboxes is saved.
///                 If the newMainState is the same as the restoreOnState then the states of the dependent checkboxes are restored
/// mode: DEP_CTRLS_SAME or DEP_CTRLS_INVERT, defines if the dependent checkbox state follows the newMainState or the inverted newMainState
///
/// When the dependent checkboxes are in the dependent state they are disabled.
/// Example: if checkbox A is on, then checkbox B must be on as well and if checkbox A is off, then any state of checkbox B is valid
///          and if checkbox A is changed to off then the state of checkbox B when A was in the off state before should be restored.
///          results in: newMainState -> CHECKBOX_SELECTED (when A is switched on, then B is also switched according to mode and gets disabled, as a dependent checkbox)
///                      mode -> DEP_CTRLS_SAME (A -> on then B -> on)
///                      restoreOnState -> CHECKBOX_UNSELECTED (A -> off then B gets independent and restored, A -> on then B gets dependent and B's state saved)
///
/// \rst
///
/// ================== ========== ================== ==================================
///  Restore on State   Main new   Mode               Action on dependent checkboxes
/// ================== ========== ================== ==================================
///      ON               OFF      DEP_CTRLS_SAME     state saved, unchecked, disabled
///      ON               OFF      DEP_CTRLS_INVERT   state saved, checked, disabled
///      ON               ON        ignored           state restored, enabled
/// ------------------ ---------- ------------------ ----------------------------------
///      OFF              ON       DEP_CTRLS_SAME     state saved, checked, disabled
///      OFF              ON       DEP_CTRLS_INVERT   state saved, unchecked, disabled
///      OFF              OFF       ignored           state restored, enabled
/// ================== ========== ================== ==================================
///
/// \endrst
Function AdaptDependentControls(string win, string controls, variable restoreOnState, variable newMainState, variable mode)

	variable numControls, oldState, i, newState
	string ctrl

	restoreOnState = !!restoreOnState
	newMainState   = !!newMainState
	numControls    = ItemsInList(controls)

	if(restoreOnState == newMainState)
		// enabled controls and restore the previous state
		EnableControls(win, controls)

		for(i = 0; i < numControls; i += 1)
			ctrl = StringFromList(i, controls)

			// and read old state
			oldState = str2num(GetUserData(win, ctrl, "oldState"))

			// invalidate old state
			SetControlUserData(win, ctrl, "oldState", "")
			if(IsNaN(oldState))
				continue
			endif

			// set old state
			PGC_SetAndActivateControl(win, ctrl, val = oldState, mode = PGC_MODE_SKIP_ON_DISABLED)
		endfor

		return NaN
	endif

	newState = (mode == DEP_CTRLS_SAME) ? newMainState : !newMainState

	for(i = 0; i < numControls; i += 1)
		ctrl = StringFromList(i, controls)
		// store current state
		oldState = GetCheckBoxState(win, ctrl)
		SetControlUserData(win, ctrl, "oldState", num2str(oldState))

		// and apply new state
		PGC_SetAndActivateControl(win, ctrl, val = newState, mode = PGC_MODE_SKIP_ON_DISABLED)
	endfor

	// and disable
	DisableControls(win, controls)
End

/// @brief Adjust the "Normal" ruler in the notebook so that all text is visible.
Function ReflowNotebookText(string win)

	variable width

	GetWindow $win, wsizeDC
	width = V_right - V_left
	// make it a bit shorter
	width -= 10
	// pixel -> points
	width = width * (72 / ScreenResolution)
	// redefine ruler
	Notebook $win, ruler=Normal, rulerUnits=0, margins={0, 0, width}
	// select everything
	Notebook $win, selection={startOfFile, endOfFile}
	// apply ruler to selection
	Notebook $win, ruler=Normal
	// deselect selection
	Notebook $win, selection={endOfFile, endOfFile}
End

/// @brief In a formatted notebook sets a location where keyWord appear to the given color
Function ColorNotebookKeywords(string win, string keyWord, variable r, variable g, variable b)

	if(IsEmpty(keyWord))
		return NaN
	endif

	Notebook $win, selection={startOfFile, startOfFile}
	Notebook $win, findText={"", 0}

	do
		Notebook $win, findText={keyWord, 2^0 + 2^2}
		if(V_flag == 1)
			Notebook $win, textRGB=(r, g, b)
		endif
	while(V_flag == 1)
End

/// @brief Marquee helper
///
/// @param[in]  axisName coordinate system to use for returned values
/// @param[in]  kill     [optional, defaults to false] should the marquee be killed afterwards
/// @param[in]  doAssert [optional, defaults to true] ASSERT out if nothing can be returned
/// @param[in]  horiz    [optional] direction to return, exactly one of horiz/vert must be defined
/// @param[in]  vert     [optional] direction to return, exactly one of horiz/vert must be defined
/// @param[out] win      [optional] allows to query the window as returned by GetMarquee
///
/// @retval first start of the range
/// @retval last  end of the range
Function [variable first, variable last] GetMarqueeHelper(string axisName, [variable kill, variable doAssert, variable horiz, variable vert, string &win])

	first = NaN
	last  = NaN

	if(!ParamIsDefault(win))
		win = ""
	endif

	if(ParamIsDefault(kill))
		kill = 0
	else
		kill = !!kill
	endif

	if(ParamIsDefault(doAssert))
		doAssert = 1
	else
		doAssert = !!doAssert
	endif

	ASSERT((ParamIsDefault(horiz) + ParamIsDefault(vert)) == 1, "Required exactly one of horiz/vert")

	if(ParamIsDefault(horiz))
		horiz = 0
	else
		horiz = !!horiz
	endif

	if(ParamIsDefault(vert))
		vert = 0
	else
		vert = !!vert
	endif

	AssertOnAndClearRTError()
	try
		if(kill)
			GetMarquee/K/Z $axisName; AbortOnRTE
		else
			GetMarquee/Z $axisName; AbortOnRTE
		endif
	catch
		ClearRTError()
		ASSERT(!doAssert, "Missing axis")

		return [first, last]
	endtry

	if(!V_Flag)
		ASSERT(!doAssert, "Missing marquee")
		return [first, last]
	endif

	if(!ParamIsDefault(win))
		win = S_MarqueeWin
	endif

	if(horiz)
		return [V_left, V_right]
	elseif(vert)
		return [V_bottom, V_top]
	else
		FATAL_ERROR("Impossible state")
	endif
End

/// @brief Wrapper for ResizeControlsHook which handles a free datafolder as CDF
///
/// @todo reported as #5100 to WM
Function ResizeControlsSafe(STRUCT WMWinHookStruct &s)

	variable isFreeDFR

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_RESIZE:
			DFREF dfr = GetDataFolderDFR()
			isFreeDFR = IsFreeDataFolder(dfr)
			if(isFreeDFR)
				SetDataFolder root:
			endif

			ResizeControls#ResizeControlsHook(s)

			if(isFreeDFR)
				SetDataFolder dfr
			endif
			break
		default:
			break
	endswitch

	// return zero so that other hooks are called as well
	return 0
End

/// @brief Scroll in the given ListBox the row into view
///
/// @retval 0 if scrolling was done, 1 if not
Function ScrollListboxIntoView(string win, string ctrl, variable row)

	variable startRow, numVisRows

	ControlInfo/W=$win $ctrl
	ASSERT(V_flag == CONTROL_TYPE_LISTBOX, "Expected a listbox")

	WAVE/Z/SDFR=$S_DataFolder listWave = $S_Value
	ASSERT(WaveExists(listWave), "Missing list wave")

	ASSERT(!IsNaN(row), "Expected row to be not NaN")
	row = limit(row, 0, DimSize(listWave, ROWS))

	numVisRows = trunc(V_height / V_rowHeight)

	if(row < V_startRow)
		// move row to the first visible row
		ListBox $ctrl, row=row, win=$win

		return 0
	endif

	if(row >= (V_startRow + numVisRows))
		// move row to the last visible row
		ListBox $ctrl, row=(row - numVisRows + 1), win=$win

		return 0
	endif

	return 1
End
