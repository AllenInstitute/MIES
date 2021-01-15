#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=PGC_Testing

static StrConstant PGCT_POPUPMENU_ENTRIES = "Entry1;Entry2;Entry3"

static Function TEST_CASE_BEGIN_OVERRIDE(testCase)
	string testCase

	NewPanel/K=1
	String/G root:panel = S_name

	PopupMenu popup_ctrl proc=PGCT_PopMenuProc,value=#("\"" + PGCT_POPUPMENU_ENTRIES + "\""), mode = 1
	PopupMenu popup_ctrl_colortable,pos={68.00,114.00},size={200.00,19.00},proc=PGCT_PopMenuProc
	PopupMenu popup_ctrl_colortable,mode=2,value= #"\"*COLORTABLEPOP*\""
	CheckBox checkbox_ctrl_mode_checkbox,pos={66.00,1.00},size={39.00,15.00},proc=PGCT_CheckProc
	CheckBox checkbox_ctrl_mode_checkbox,value= 0
	CheckBox checkbox_ctrl_disabled,value= 0,disable=DISABLE_CONTROL_BIT,proc=PGCT_CheckProc

	KillVariables/Z popNum, checked
	KillStrings/Z popStr

	CA_FlushCache()
End

static Function TEST_CASE_END_OVERRIDE(testCase)
	string testCase

	SVAR/Z/SDFR=root: panel
	if(SVAR_Exists(panel))
		KillWindow/Z $panel
	endif
End

static Function PGCT_PopupMenuAborts1()

	variable refValue, popNum
	string refString, popStr

	SVAR/SDFR=root: panel

	try
		PGC_SetAndActivateControl(panel, "popup_ctrl")
		FAIL()
	catch
		PASS()
	endtry

	// no changes
	DoUpdate
	ControlInfo/W=$panel popup_ctrl
	refValue  = V_Value
	refString = S_Value

	popStr = StringFromList(0, PGCT_POPUPMENU_ENTRIES)
	popNum = 1
	CHECK_EQUAL_VAR(refValue, popNum)
	CHECK_EQUAL_STR(refString, popStr)
End

static Function PGCT_PopupMenuAborts2()

	variable refValue, popNum
	string refString, popStr

	SVAR/SDFR=root: panel

	try
		PGC_SetAndActivateControl(panel, "popup_ctrl", val = 0, str = "Entry1")
		FAIL()
	catch
		PASS()
	endtry

	// no changes
	DoUpdate
	ControlInfo/W=$panel popup_ctrl
	refValue  = V_Value
	refString = S_Value

	popStr = StringFromList(0, PGCT_POPUPMENU_ENTRIES)
	popNum = 1
	CHECK_EQUAL_VAR(refValue, popNum)
	CHECK_EQUAL_STR(refString, popStr)
End

static Function PGCT_PopupMenuAborts3()

	variable refValue, popNum
	string refString, popStr

	SVAR/SDFR=root: panel

	try
		PGC_SetAndActivateControl(panel, "popup_ctrl", val = -1)
		FAIL()
	catch
		PASS()
	endtry

	// no changes
	DoUpdate
	ControlInfo/W=$panel popup_ctrl
	refValue  = V_Value
	refString = S_Value

	popStr = StringFromList(0, PGCT_POPUPMENU_ENTRIES)
	popNum = 1
	CHECK_EQUAL_VAR(refValue, popNum)
	CHECK_EQUAL_STR(refString, popStr)
End

static Function PGCT_PopupMenuAborts4()

	variable refValue, popNum
	string refString, popStr

	SVAR/SDFR=root: panel

	try
		PGC_SetAndActivateControl(panel, "popup_ctrl", str = "I_DONT_EXIST")
		FAIL()
	catch
		PASS()
	endtry

	// no changes
	DoUpdate
	ControlInfo/W=$panel popup_ctrl
	refValue  = V_Value
	refString = S_Value

	popStr = StringFromList(0, PGCT_POPUPMENU_ENTRIES)
	popNum = 1
	CHECK_EQUAL_VAR(refValue, popNum)
	CHECK_EQUAL_STR(refString, popStr)
End

static Function PGCT_PopupMenuVarWorks1()

	variable refValue, popNum, i
	string refString, popStr

	SVAR/SDFR=root: panel

	ControlInfo/W=$panel popup_ctrl
	refValue  = V_Value
	refString = S_Value

	popStr = StringFromList(0, PGCT_POPUPMENU_ENTRIES)
	popNum = 1
	CHECK_EQUAL_VAR(refValue, popNum)
	CHECK_EQUAL_STR(refString, popStr)

	for(i = 0; i < ItemsInList(PGCT_POPUPMENU_ENTRIES); i += 1)
		refString = StringFromList(i, PGCT_POPUPMENU_ENTRIES)
		refValue  = i + 1

		PGC_SetAndActivateControl(panel, "popup_ctrl", val = i)

		DoUpdate
		ControlInfo/W=$panel popup_ctrl
		CHECK_EQUAL_STR(refString, S_Value)
		CHECK_EQUAL_VAR(refValue, V_Value)
		NVAR popNumSVAR = popNum
		popNum = popNumSVAR
		SVAR popStrSVAR = popStr
		popStr = popStrSVAR

		CHECK_EQUAL_VAR(refValue, popNum)
		CHECK_EQUAL_STR(refString, popStr)
	endfor
End

static Function PGCT_PopupMenuStrWorks1()

	variable refValue, popNum, i
	string refString, popStr

	SVAR/SDFR=root: panel

	ControlInfo/W=$panel popup_ctrl
	refValue  = V_Value
	refString = S_Value

	popStr = StringFromList(0, PGCT_POPUPMENU_ENTRIES)
	popNum = 1
	CHECK_EQUAL_VAR(refValue, popNum)
	CHECK_EQUAL_STR(refString, popStr)

	for(i = 0; i < ItemsInList(PGCT_POPUPMENU_ENTRIES); i += 1)
		refString = StringFromList(i, PGCT_POPUPMENU_ENTRIES)
		refValue  = i + 1

		PGC_SetAndActivateControl(panel, "popup_ctrl", str = refString)

		DoUpdate
		ControlInfo/W=$panel popup_ctrl
		CHECK_EQUAL_STR(refString, S_Value)
		CHECK_EQUAL_VAR(refValue, V_Value)
		NVAR popNumSVAR = popNum
		popNum = popNumSVAR
		SVAR popStrSVAR = popStr
		popStr = popStrSVAR

		CHECK_EQUAL_VAR(refValue, popNum)
		CHECK_EQUAL_STR(refString, popStr)
	endfor
End

static Function PGCT_PopupMenuStrWorksWithWC()

	variable refValue, popNum
	string refString, popStr

	SVAR/SDFR=root: panel

	ControlInfo/W=$panel popup_ctrl
	refValue  = V_Value
	refString = S_Value

	popStr = StringFromList(0, PGCT_POPUPMENU_ENTRIES)
	popNum = 1
	CHECK_EQUAL_VAR(refValue, popNum)
	CHECK_EQUAL_STR(refString, popStr)

	refString = StringFromList(1, PGCT_POPUPMENU_ENTRIES)
	refValue  = 2

	PGC_SetAndActivateControl(panel, "popup_ctrl", str = "*2")

	DoUpdate
	ControlInfo/W=$panel popup_ctrl
	CHECK_EQUAL_STR(refString, S_Value)
	CHECK_EQUAL_VAR(refValue, V_Value)
	NVAR popNumSVAR = popNum
	popNum = popNumSVAR
	SVAR popStrSVAR = popStr
	popStr = popStrSVAR

	CHECK_EQUAL_VAR(refValue, popNum)
	CHECK_EQUAL_STR(refString, popStr)
End

static Function PGCT_PopupMenuStrWorksWithColorTable()

	variable refValue, popNum
	string refString, popStr

	SVAR/SDFR=root: panel

	ControlInfo/W=$panel popup_ctrl_colortable
	refValue  = V_Value
	refString = S_Value

	popStr = "Rainbow"
	popNum = 2
	CHECK_EQUAL_VAR(refValue, popNum)
	CHECK_EQUAL_STR(refString, popStr)

	refString = "YellowHot"
	refValue  = 3

	PGC_SetAndActivateControl(panel, "popup_ctrl_colortable", str = "YellowHot")

	DoUpdate
	ControlInfo/W=$panel popup_ctrl_colortable
	CHECK_EQUAL_STR(refString, S_Value)
	CHECK_EQUAL_VAR(refValue, V_Value)
	NVAR popNumSVAR = popNum
	popNum = popNumSVAR
	SVAR popStrSVAR = popStr
	popStr = popStrSVAR

	CHECK_EQUAL_VAR(refValue, popNum)
	CHECK_EQUAL_STR(refString, popStr)
End

Function PGCT_PopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch(pa.eventCode)
		case 2: // mouse up
			Variable/G popNum = pa.popNum
			String/G popStr   = pa.popStr
			break
	endswitch

	return 0
End

static Function PGCT_CheckboxAborts1()

	variable refState, state

	SVAR/SDFR=root: panel

	try
		PGC_SetAndActivateControl(panel, "checkbox_ctrl_mode_checkbox")
		FAIL()
	catch
		PASS()
	endtry

	// no changes
	DoUpdate
	ControlInfo/W=$panel checkbox_ctrl_mode_checkbox
	state = V_Value

	NVAR/Z checkedSVAR = checked
	CHECK(!NVAR_Exists(checkedSVAR))

	refState = 0
	CHECK_EQUAL_VAR(refState, state)
End

static Function PGCT_CheckboxAborts2()

	variable refState, state

	SVAR/SDFR=root: panel

	try
		PGC_SetAndActivateControl(panel, "checkbox_ctrl_mode_checkbox", str = "invalid")
		FAIL()
	catch
		PASS()
	endtry

	// no changes
	DoUpdate
	ControlInfo/W=$panel checkbox_ctrl_mode_checkbox
	state = V_Value

	NVAR/Z checkedSVAR = checked
	CHECK(!NVAR_Exists(checkedSVAR))

	refState = 0
	CHECK_EQUAL_VAR(refState, state)
End

static Function PGCT_CheckboxWorks1()

	variable refState, state

	SVAR/SDFR=root: panel

	PGC_SetAndActivateControl(panel, "checkbox_ctrl_mode_checkbox", val = 1)

	// checked
	DoUpdate
	ControlInfo/W=$panel checkbox_ctrl_mode_checkbox
	state = V_Value

	NVAR/Z checkedSVAR = checked
	CHECK(NVAR_Exists(checkedSVAR))

	refState = 1
	CHECK_EQUAL_VAR(refState, checkedSVAR)
	CHECK_EQUAL_VAR(refState, state)
End

static Function PGCT_CheckboxWorks2()

	variable refState, state

	SVAR/SDFR=root: panel

	PGC_SetAndActivateControl(panel, "checkbox_ctrl_mode_checkbox", val = 0)

	// does nothing if already in the same state
	DoUpdate
	ControlInfo/W=$panel checkbox_ctrl_mode_checkbox
	state = V_Value

	NVAR/Z checkedSVAR = checked
	CHECK(!NVAR_Exists(checkedSVAR))

	refState = 0
	CHECK_EQUAL_VAR(refState, state)
End

Function PGCT_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			Variable/G checked = cba.checked
			break
	endswitch

	return 0
End

static Function PGCT_CheckboxDisabled()

	variable refState, state

	SVAR/SDFR=root: panel

	PGC_SetAndActivateControl(panel, "checkbox_ctrl_disabled", val = 1)

	// no changes
	DoUpdate
	ControlInfo/W=$panel checkbox_ctrl_disabled
	state = V_Value

	NVAR/Z checkedSVAR = checked
	CHECK(!NVAR_Exists(checkedSVAR))

	refState = 0
	CHECK_EQUAL_VAR(refState, state)

	// now it is set
	PGC_SetAndActivateControl(panel, "checkbox_ctrl_disabled", val = 1, ignoreDisabledState = 1)

	DoUpdate
	ControlInfo/W=$panel checkbox_ctrl_disabled
	state = V_Value

	NVAR/Z checkedSVAR = checked
	CHECK(NVAR_Exists(checkedSVAR))

	refState = 1
	CHECK_EQUAL_VAR(refState, state)

End
