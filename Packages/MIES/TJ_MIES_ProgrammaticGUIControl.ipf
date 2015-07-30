#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static StrConstant PROCEDURE_START = "proc="

/// @name Return types of @ref PGC_GetInternalSetVariableType
/// @anchor PGC_GetInternalSetVariableTypeReturnTypes
/// @{
static Constant SET_VARIABLE_BUILTIN_NUM = 0x01
static Constant SET_VARIABLE_BUILTIN_STR = 0x02
static Constant SET_VARIABLE_GLOBAL      = 0x04
/// @}

/// @brief Return the parameter type a function parameter
///
/// @param func       name of the function
/// @param paramIndex index of the parameter
static Function GetFunctionParameterType(func, paramIndex)
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
static Function/S GetControlProcedure(win, control)
	string win, control

	variable last, first
	variable comma, cr
	string procedure, list

	ControlInfo/W=$win $control
	ASSERT(V_flag != 0, "invalid or non existing control")
	first = strsearch(S_recreation, "proc=", 0)

	if(first == -1)
		return ""
	endif

	comma = strsearch(S_recreation, ",", first + 1)
	cr    = strsearch(S_recreation, "\r", first + 1)

	if(comma > 0 && cr > 0)
		last = min(comma, cr)
	elseif(comma == -1)
		last = cr
	elseif(cr == -1)
		last = comma
	else
		ASSERT(0, "impossible case")
	endif

	procedure = S_recreation[first + strlen(PROCEDURE_START), last - 1]
	list = FunctionList(procedure, ";", "")

	ASSERT(!isEmpty(procedure) && !isEmpty(list), "no or invalid procedure")

	return procedure
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
	ASSERT(paramType & STRUCT_PARAMETER_TYPE, "No support for old style control procedures")

	return procedure
End

/// @brief Return one the type of the variable of the SetVariable control
///
/// @return one of @ref PGC_GetInternalSetVariableTypeReturnTypes
static Function PGC_GetInternalSetVariableType(recMacro)
	string recMacro

	ASSERT(strsearch(recMacro, "SetVariable", 0) != -1, "recreation macro is not from a SetVariable")

	variable builtinString = (strsearch(recMacro, "_STR:\"", 0) != -1)
	variable builtinNumber = (strsearch(recMacro, "_NUM:\"", 0) != -1)

	ASSERT(builtinString + builtinNumber != 2, "SetVariable can not hold both numeric and string contents")

	if(builtinString)
		return SET_VARIABLE_BUILTIN_STR
	elseif(builtinNumber)
		return SET_VARIABLE_BUILTIN_NUM
	endif

	return SET_VARIABLE_GLOBAL
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

/// @brief Set the control's value and execute the control procedure
/// of the given control (if it exists)
///
/// `val` and `string` are ignored for unappropriate controls.
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
			pa.popNum    = val

			if(!ParamIsDefault(str))
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
			ASSERT(!ParamIsDefault(val), "Needs a variable argument")

			variableType = PGC_GetInternalSetVariableType(S_recreation)

			if(variableType == SET_VARIABLE_BUILTIN_NUM)
				SetSetVariable(win, control, val)
			elseif(variableType == SET_VARIABLE_BUILTIN_STR)
				SetSetVariableString(win, control, str)
			else
				// nothing to do for globals
			endif

			if(isEmpty(procedure))
				break
			endif

			struct WMSetVariableAction sva
			sva.ctrlName  = control
			sva.win       = win
			sva.eventCode = 2
			sva.dval      = val

			if(!ParamIsDefault(str) && variableType == SET_VARIABLE_BUILTIN_STR)
				sva.sval  = str
				sva.isStr = 1
			endif

			FUNCREF PGC_SetVariableControlProcedure SetVariableProc = $procedure
			SetVariableProc(sva)
			break
		case CONTROL_TYPE_VALDISPLAY:
			ASSERT(!ParamIsDefault(val), "Needs a variable argument")
			SetValDisplaySingleVariable(win, control, val)
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
