#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_PGC
#endif

/// @file MIES_ProgrammaticGUIControl.ipf
/// @brief __PGC__ Control GUI controls from code

/// @brief Return the popupmenu list entries
///
/// Parses the recreation macro and possibly executes
/// the function referenced therein.
///
/// Does not work with builtin popup menu lists like `*COLORPOP*`.
static Function/S PGC_GetPopupMenuList(win, control)
	string win, control

	string listOrFunc, path, cmd

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "invalid or non existing control")

	SplitString/E="\\s*,\\s*value\\s*=\\s*(.*)$" S_recreation, listOrFunc
	if(V_Flag != 1)
		Bug("Could not find popupmenu \"value\" entry")
		return ""
	endif

	listOrFunc = trimstring(listOrFunc, 1)

	// unescape quotes
	listOrFunc = ReplaceString("\\\"", listOrFunc, "\"")

	// misc cleanup
	listOrFunc = RemovePrefix(listOrFunc, startStr="#")
	listOrFunc = RemovePrefix(listOrFunc, startStr="\"")
	listOrFunc = RemoveEnding(listOrFunc, "\"")

	path = GetTemporaryString()

	sprintf cmd, "%s = %s", path, listOrFunc
	Execute/Z/Q cmd

	if(V_Flag)
		Bug("Execute returned an error :(")
		return ""
	endif

	SVAR str = $path
	return str
End

static Function/S PGC_GetProcAndCheckParamType(win, control)
	string win, control

	string procedure
	variable paramType

	procedure = GetControlProcedure(win, control)
	if(isEmpty(procedure))
		return ""
	endif

	paramType = GetFunctionParameterType(procedure, 0)
	ASSERT(paramType & IGOR_TYPE_STRUCT_PARAMETER, "No support for old style control procedures")

	return procedure
End

/// @name Prototype functions for #PGC_SetAndActivateControl
/// @anchor PGC_SetAndActivateControlPrototypeFunctions
/// @{
Function PGC_ButtonControlProcedure(ba) : ButtonControl
	struct WMButtonAction& ba

	ASSERT(0, "Prototype function which must not be called")
End

Function PGC_PopupActionControlProcedure(pa) : PopupMenuControl
	struct WMPopupAction& pa

	ASSERT(0, "Prototype function which must not be called")
End

Function PGC_CheckboxControlProcedure(cba) : CheckBoxControl
	struct WMCheckBoxAction& cba

	ASSERT(0, "Prototype function which must not be called")
End

Function PGC_TabControlProcedure(tca) : TabControl
	struct WMTabControlAction& tca

	ASSERT(0, "Prototype function which must not be called")
End

Function PGC_SetVariableControlProcedure(tca) : SetVariableControl
	struct WMSetVariableAction& tca

	ASSERT(0, "Prototype function which must not be called")
End

Function PGC_SliderControlProcedure(sla) : SliderControl
	struct WMSliderAction& sla

	ASSERT(0, "Prototype function which must not be called")
End
/// @}

/// @brief Wrapper for PGC_SetAndActivateControl()
Function PGC_SetAndActivateControlStr(win, control, str)
	string win, control, str

	return PGC_SetAndActivateControl(win, control, str=str)
End

/// @brief Wrapper for PGC_SetAndActivateControl()
Function PGC_SetAndActivateControlVar(win, control, var)
	string win, control
	variable var

	return PGC_SetAndActivateControl(win, control, val=var)
End

/// @brief Set the control's value and execute the control procedure
/// of the given control (if it exists)
///
/// `val` and `string` are ignored for unappropriate controls.
///
/// PopupMenus:
/// - `val` is mandatory and 0-based.
/// - `str` must be supplied if the GUI control procedure requires it.
Function PGC_SetAndActivateControl(win, control, [val, str])
	string win, control
	variable val
	string str

	string procedure
	variable paramType, controlType, variableType

	if(IsControlDisabled(win, control))
		DEBUGPRINT("Can't click a disabled control (or better should not)")
		return NaN
	endif

	procedure = PGC_GetProcAndCheckParamType(win, control)

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "Non-existing control or window")
	controlType = abs(V_flag)

	switch(controlType)
		case CONTROL_TYPE_BUTTON:

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
			ASSERT(!ParamIsDefault(val), "Needs a variable argument")
			SetPopupMenuIndex(win, control, val)

			if(isEmpty(procedure))
				break
			endif

			struct WMPopupAction pa
			pa.ctrlName  = control
			pa.win       = win
			pa.eventCode = 2
			pa.popNum    = val + 1

			if(ParamIsDefault(str))
				pa.popStr = StringFromList(val, PGC_GetPopupMenuList(win, control))
			else
				pa.popStr = str
			endif

			FUNCREF PGC_PopupActionControlProcedure PopupProc = $procedure
			PopupProc(pa)
			break
		case CONTROL_TYPE_CHECKBOX:
			ASSERT(!ParamIsDefault(val), "Needs a variable argument")
			SetCheckboxState(win, control, val)

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
			ASSERT(!ParamIsDefault(val), "Needs a variable argument")
			TabControl $control win=$win, value=val

			if(isEmpty(procedure))
				break
			endif

			struct WMTabControlAction tca
			tca.ctrlName  = control
			tca.win       = win
			tca.eventCode = 2
			tca.tab       = val

			FUNCREF PGC_TabControlProcedure TabProc = $procedure
			TabProc(tca)
			break
		case CONTROL_TYPE_SETVARIABLE:
			ASSERT(ParamIsDefault(val) + ParamIsDefault(str) == 1, "Needs a variable or string argument")
			variableType = GetInternalSetVariableType(S_recreation)

			if(ParamIsDefault(val))
				val = str2num(str)
			endif

			if(ParamIsDefault(str))
				str = num2str(val)
			endif

			if(variableType == SET_VARIABLE_BUILTIN_NUM)
				SetSetVariable(win, control, val)
			elseif(variableType == SET_VARIABLE_BUILTIN_STR)
				SetSetVariableString(win, control, str)
			else
				// @todo handle globals as well
			endif

			if(isEmpty(procedure))
				break
			endif

			struct WMSetVariableAction sva
			sva.ctrlName  = control
			sva.win       = win
			sva.eventCode = 2
			sva.sval      = str
			sva.dval      = val
			sva.isStr     = (variableType == SET_VARIABLE_BUILTIN_STR)

			FUNCREF PGC_SetVariableControlProcedure SetVariableProc = $procedure
			SetVariableProc(sva)
			break
		case CONTROL_TYPE_VALDISPLAY:
			ASSERT(!ParamIsDefault(val), "Needs a variable argument")
			SetValDisplay(win, control, var=val)
			// Value displays don't have control procedures
			break
		case CONTROL_TYPE_SLIDER:
			ASSERT(!ParamIsDefault(val), "Needs a variable argument")
			SetSliderPositionIndex(win, control, val)

			if(isEmpty(procedure))
				break
			endif

			struct WMSliderAction sla
			sla.ctrlName  = control
			sla.win       = win
			sla.eventCode = 1
			sla.curval    = val

			FUNCREF PGC_SliderControlProcedure SliderProc = $procedure
			SliderProc(sla)
			break
		default:
			ASSERT(0, "Unsupported control type")
			break
	endswitch
End
