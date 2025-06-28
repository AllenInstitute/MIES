#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_PGC
#endif // AUTOMATED_TESTING

/// @file MIES_ProgrammaticGUIControl.ipf
/// @brief __PGC__ Control GUI controls from code

/// @brief Bring all tabs which hold the control to the front (recursively).
///
/// Requires that these are managed by `ACL_TabUtilities.ipf`.
static Function PGC_ShowControlInTab(string win, string control)

	variable idx, numEntries, i, tab
	string tabnum, tabctrl

	if(!WindowExists(win))
		return NaN
	endif

	Make/FREE/N=(2, MINIMUM_WAVE_SIZE)/T tabs

	for(;;)
		tabnum  = GetUserData(win, control, "tabnum")
		tabctrl = GetUserData(win, control, "tabcontrol")

		if(IsEmpty(tabnum) || IsEmpty(tabctrl))
			break
		endif

		EnsureLargeEnoughWave(tabs, indexShouldExist = idx)
		tabs[idx][0] = tabnum
		tabs[idx][1] = tabctrl

		idx += 1

		// search parent tab recursively
		control = tabctrl
	endfor

	// `tabs` has the outer most tab at the end

	numEntries = idx
	for(i = numEntries - 1; i >= 0; i -= 1)
		tab = str2num(tabs[i][0])

		if(GetTabID(win, tabs[i][1]) == tab)
			continue
		endif

		PGC_SetAndActivateControl(win, tabs[i][1], val = tab, switchTab = 0)
	endfor
End

static Function/S PGC_GetProcAndCheckParamType(string recMacro)

	variable paramType
	string   procedure

	procedure = GetValueFromRecMacro(REC_MACRO_PROCEDURE, recMacro)
	if(isEmpty(procedure))
		return ""
	endif

	paramType = GetFunctionParameterType(procedure, 0)
	ASSERT(paramType & IGOR_TYPE_STRUCT_PARAMETER, "No support for old style control procedures")

	return procedure
End

/// @name Prototype functions for #PGC_SetAndActivateControl
/// @anchor PGC_SetAndActivateControlPrototypeFunctions
///@{
Function PGC_ButtonControlProcedure(STRUCT WMButtonAction &ba) : ButtonControl

	FATAL_ERROR("Prototype function which must not be called")
End

Function PGC_PopupActionControlProcedure(STRUCT WMPopupAction &pa) : PopupMenuControl

	FATAL_ERROR("Prototype function which must not be called")
End

Function PGC_CheckboxControlProcedure(STRUCT WMCheckBoxAction &cba) : CheckBoxControl

	FATAL_ERROR("Prototype function which must not be called")
End

Function PGC_TabControlProcedure(STRUCT WMTabControlAction &tca) : TabControl

	FATAL_ERROR("Prototype function which must not be called")
End

Function PGC_SetVariableControlProcedure(STRUCT WMSetVariableAction &tca) : SetVariableControl

	FATAL_ERROR("Prototype function which must not be called")
End

Function PGC_SliderControlProcedure(STRUCT WMSliderAction &sla) : SliderControl

	FATAL_ERROR("Prototype function which must not be called")
End

Function PGC_ListBoxControlProcedure(STRUCT WMListBoxAction &lba) : ListBoxControl

	FATAL_ERROR("Prototype function which must not be called")
End
///@}

/// @brief Wrapper for PGC_SetAndActivateControl()
Function PGC_SetAndActivateControlStr(string win, string control, string str)

	return PGC_SetAndActivateControl(win, control, str = str)
End

/// @brief Wrapper for PGC_SetAndActivateControl()
Function PGC_SetAndActivateControlVar(string win, string control, variable var)

	return PGC_SetAndActivateControl(win, control, val = var)
End

/// @brief Set the control's value and execute the control procedure of the given control
///
/// The function tries to mimick interactive operation as closely as possible.
/// Therefore interacting with disabled controls results in an assertion. See `mode`
/// for a way to avoid that.
///
/// @param win       window name or path, when referring to subwindows in a window hierarchy
///                  a full subwindow specification with `#` is required
/// @param control   GUI control
/// @param val       [optionality depends on control type] Numeric value to set
/// @param str       [optionality depends on control type] String value to set
/// @param switchTab [optional, defaults to false] Switches tabs so that the control is shown
/// @param mode      [optional, defaults to #PGC_MODE_ASSERT_ON_DISABLED] One of @ref PGC_MODES.
///                  Allows to fine tune the behaviour for disabled controls.
///
/// PopupMenus:
/// - Only one of `val` or `str` can be supplied
/// - `val` is 0-based
/// - `str` must be the name of an entry, can include `*` using wildcard syntax.
///
/// ValDisp:
/// - Setting this control always changes its mode from 'internal number' to 'global expression'
///
/// SetVariable:
/// - Both `str` and `val` are accepted and converted to the target type.
///   Read-only controls can only be set with `mode = PGC_MODE_FORCE_ON_DISABLED`.
///
/// ListBox:
/// - Setting the column is not supported
/// - Simulated event code is 3 (double click)
///
/// @return 1 if the numeric value was modified by control limits, 0 if not (only relevant for SetVariable controls)
///
/// @hidecallgraph
/// @hidecallergraph
Function PGC_SetAndActivateControl(string win, string control, [variable val, string str, variable switchTab, variable mode])

	string procedure, popupMenuList, popupMenuValue
	variable paramType, controlType, variableType, inputWasModified, limitedVal
	variable isCheckbox, checkBoxMode, popupMenuType, index

	if(ParamIsDefault(switchTab))
		switchTab = 0
	else
		switchTab = !!switchTab
	endif

	if(ParamIsDefault(mode))
		mode = PGC_MODE_ASSERT_ON_DISABLED
	else
		ASSERT(mode == PGC_MODE_ASSERT_ON_DISABLED || mode == PGC_MODE_FORCE_ON_DISABLED || mode == PGC_MODE_SKIP_ON_DISABLED, "Invalid mode")
	endif

	// call only once
	ControlInfo/W=$win $control
	if(!V_flag)
		ASSERT(WindowExists(win), "The panel " + win + " does not exist.")
		FATAL_ERROR("The control " + control + " in the panel " + win + " does not exist.")
	endif
	controlType = abs(V_flag)

	if(V_disable & DISABLE_CONTROL_BIT)
		switch(mode)
			case PGC_MODE_SKIP_ON_DISABLED:
				// compatibility behaviour for old code
				return NaN
				break
			case PGC_MODE_ASSERT_ON_DISABLED:
				FATAL_ERROR("The control " + control + " in the panel " + win + " is disabled. The control state cannot be changed when disabled.")
				break
			case PGC_MODE_FORCE_ON_DISABLED:
				// just continue
				break
			default:
				FATAL_ERROR("Invalid mode")
				break
		endswitch
	endif

	procedure = PGC_GetProcAndCheckParamType(S_recreation)

	switch(controlType)
		case CONTROL_TYPE_BUTTON:
			// we accept a var just that PGC_SetAndActivateControlVar keeps working
			ASSERT(ParamIsDefault(str), "Does not accept str argument.")

			if(isEmpty(procedure))
				break
			endif

			STRUCT WMButtonAction ba
			ba.ctrlName  = control
			ba.win       = win
			ba.eventCode = 2

			FUNCREF PGC_ButtonControlProcedure ButtonProc = $procedure
			ButtonProc(ba)
			break
		case CONTROL_TYPE_POPUPMENU:
			ASSERT((ParamIsDefault(val) + ParamIsDefault(str)) == 1, "Needs an argument")

			[popupMenuValue, popupMenuType] = ParsePopupMenuValue(S_recreation)

			popupMenuList = GetPopupMenuList(popupMenuValue, popupMenuType)

			if(!ParamIsDefault(val))
				ASSERT(val >= 0 && val < ItemsInList(popupMenuList), "Invalid value for popupmenu: " + num2str(val))
				PopupMenu $control, win=$win, mode=(val + 1)
			elseif(!ParamIsDefault(str))
				switch(popupMenuType)
					case POPUPMENULIST_TYPE_BUILTIN:
						val = WhichListItem(str, popupMenuList)
						ASSERT(val >= 0 && val < ItemsInList(popupMenuList), "Invalid value for popupmenu: " + num2str(val))

						// popmatch does not work with these
						PopupMenu $control, win=$win, mode=(WhichListItem(str, popupMenuList) + 1)
						break
					case POPUPMENULIST_TYPE_OTHER:
						// the return value might be different due to wildcard expansion
						str = SetPopupMenuString(win, control, str)

						val = WhichListItem(str, popupMenuList)
						ASSERT(val >= 0 && val < ItemsInList(popupMenuList), "Invalid value for popupmenu: " + num2str(val))
						break
					default:
						FATAL_ERROR("Invalid popup menu type")
				endswitch
			endif

			if(isEmpty(procedure))
				break
			endif

			STRUCT WMPopupAction pa
			pa.ctrlName  = control
			pa.win       = win
			pa.eventCode = 2

			pa.popNum = val + 1
			pa.popStr = StringFromList(val, popupMenuList)

			FUNCREF PGC_PopupActionControlProcedure PopupProc = $procedure
			PopupProc(pa)
			break
		case CONTROL_TYPE_CHECKBOX:
			ASSERT(!ParamIsDefault(val) && ParamIsDefault(str), "Needs a variable argument")

			val = !!val

			checkBoxMode = str2numSafe(GetValueFromRecMacro(REC_MACRO_MODE, S_recreation))
			isCheckBox   = IsNan(checkBoxMode) || checkBoxMode == 1

			// emulate the real user experience and do nothing
			if(isCheckBox && val == V_Value)
				break
			endif

			CheckBox $control, win=$win, value=(val == CHECKBOX_SELECTED)

			if(isEmpty(procedure))
				break
			endif

			STRUCT WMCheckBoxAction cba
			cba.ctrlName  = control
			cba.win       = win
			cba.eventCode = 2
			cba.checked   = val

			FUNCREF PGC_CheckboxControlProcedure CheckboxProc = $procedure
			CheckboxProc(cba)
			break
		case CONTROL_TYPE_TAB:
			ASSERT(!ParamIsDefault(val) && ParamIsDefault(str), "Needs a variable argument")
			TabControl $control, win=$win, value=val

			// @todo add range check

			if(isEmpty(procedure))
				break
			endif

			STRUCT WMTabControlAction tca
			tca.ctrlName  = control
			tca.win       = win
			tca.eventCode = 2
			tca.tab       = val

			FUNCREF PGC_TabControlProcedure TabProc = $procedure
			TabProc(tca)
			break
		case CONTROL_TYPE_SETVARIABLE:
			ASSERT((ParamIsDefault(val) + ParamIsDefault(str)) == 1, "Needs a variable or string argument")

			if(GetControlSettingVar(S_recreation, "noEdit") == 1)
				switch(mode)
					case PGC_MODE_SKIP_ON_DISABLED:
						return NaN
					case PGC_MODE_ASSERT_ON_DISABLED:
						FATAL_ERROR("The setvariable control " + control + " in the panel " + win + " is read-only. The control state cannot be changed.")
						break
					case PGC_MODE_FORCE_ON_DISABLED:
						// just continue
						break
					default:
						FATAL_ERROR("Invalid mode")
						break
				endswitch
			endif

			variableType = GetInternalSetVariableType(S_recreation)

			if(ParamIsDefault(val))
				val = str2numSafe(str)
			endif

			if(ParamIsDefault(str))
				str = num2str(val)
			endif

			if(variableType == SET_VARIABLE_BUILTIN_NUM)
				limitedVal       = SetSetVariable(win, control, val, respectLimits = 1)
				inputWasModified = limitedVal != val
			elseif(variableType == SET_VARIABLE_BUILTIN_STR)
				SetSetVariableString(win, control, str)
			else
				// @todo handle globals as well
			endif

			if(isEmpty(procedure))
				break
			endif

			STRUCT WMSetVariableAction sva
			sva.ctrlName  = control
			sva.win       = win
			sva.eventCode = 2
			sva.sval      = str
			sva.dval      = limitedVal
			sva.isStr     = (variableType == SET_VARIABLE_BUILTIN_STR)

			FUNCREF PGC_SetVariableControlProcedure SetVariableProc = $procedure
			SetVariableProc(sva)
			break
		case CONTROL_TYPE_VALDISPLAY:
			ASSERT(!ParamIsDefault(val) && ParamIsDefault(str), "Needs a variable argument")
			SetValDisplay(win, control, var = val)
			// Value displays don't have control procedures
			break
		case CONTROL_TYPE_SLIDER:
			ASSERT(!ParamIsDefault(val) && ParamIsDefault(str), "Needs a variable argument")
			ASSERT(GetLimitConstrainedSetVar(S_recreation, val) == val, "Value " + num2str(val) + " is out of range.")

			Slider $control, win=$win, value=val

			if(isEmpty(procedure))
				break
			endif

			STRUCT WMSliderAction sla
			sla.ctrlName  = control
			sla.win       = win
			sla.eventCode = 1
			sla.curval    = val

			FUNCREF PGC_SliderControlProcedure SliderProc = $procedure
			SliderProc(sla)
			break
		case CONTROL_TYPE_LISTBOX:
			ASSERT(!ParamIsDefault(val) && ParamIsDefault(str), "Needs a variable argument")

			WAVE/Z/T listWave = $GetValueFromRecMacro("listWave", S_recreation)
			ASSERT(WaveExists(listWave), "Can't call ListBox without list wave")

			// all optional
			WAVE/Z   selWave   = $GetValueFromRecMacro("selWave", S_recreation)
			WAVE/Z   colorWave = $GetValueFromRecMacro("colorWave", S_recreation)
			WAVE/Z/T titleWave = $GetValueFromRecMacro("titleWave", S_recreation)

			ASSERT(val >= 0 && val < DimSize(listWave, ROWS), "val is out of range")

			ListBox $control, win=$win, row=val, selRow=val

			if(IsEmpty(procedure))
				break
			endif

			STRUCT WMListBoxAction lba
			lba.ctrlName  = control
			lba.win       = win
			lba.eventCode = 3 // double click
			WAVE/Z   lba.colorWave = colorWave
			WAVE/Z/T lba.listWave  = listWave
			WAVE/Z   lba.selWave   = selWave
			WAVE/Z/T lba.titleWave = titleWave
			lba.row = val
			lba.col = -1

			FUNCREF PGC_ListBoxControlProcedure ListProc = $procedure
			ListProc(lba)
			break
		default:
			FATAL_ERROR("Unsupported control type")
			break
	endswitch

	if(switchTab)
		PGC_ShowControlInTab(win, control)
	endif

	return inputWasModified
End
