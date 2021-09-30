#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=PGC_Testing

static StrConstant PGCT_POPUPMENU_ENTRIES = "Entry1;Entry2;Entry3"

static Function TEST_CASE_BEGIN_OVERRIDE(testCase)
	string testCase

	CreatePGCTestPanel_IGNORE()

	CA_FlushCache()
End

static Function TEST_CASE_END_OVERRIDE(testCase)
	string testCase

	SVAR/Z/SDFR=root: panel
	if(SVAR_Exists(panel))
		KillWindow/Z $panel
	endif
End

Function CreatePGCTestPanel_IGNORE()

	NewPanel/K=1
	String/G root:panel = S_name

	PopupMenu popup_ctrl proc=PGCT_PopMenuProc,value=#("\"" + PGCT_POPUPMENU_ENTRIES + "\""), mode = 1
	PopupMenu popup_ctrl_colortable,pos={68.00,114.00},size={200.00,19.00},proc=PGCT_PopMenuProc
	PopupMenu popup_ctrl_colortable,mode=2,value= #"\"*COLORTABLEPOP*\""

	CheckBox checkbox_ctrl_mode_checkbox,pos={66.00,1.00},size={39.00,15.00},proc=PGCT_CheckProc
	CheckBox checkbox_ctrl_mode_checkbox,value= 0
	CheckBox checkbox_ctrl_disabled,value= 0,disable=DISABLE_CONTROL_BIT,proc=PGCT_CheckProc

	Slider slider_ctrl,pos={79.00,36.00},size={164.00,56.00}
	Slider slider_ctrl,limits={0,10,1},value=0,vert=0,proc=PGCT_SliderProc

	SetVariable setvar_str_ctrl,pos={184.00,151.00},size={50.00,18.00},proc=PGCT_SetVarProc
	SetVariable setvar_str_ctrl,value=_STR:"abcd"

	SetVariable setvar_num_ctrl,pos={120.00,151.00},size={50.00,18.00},proc=PGCT_SetVarProc
	SetVariable setvar_num_ctrl,value=_NUM:123

	Button button_ctrl,pos={20.00,148.00},size={50.00,20.00},proc=PGCT_ButtonProc

	ValDisplay valdisp_ctrl,pos={219.00,12.00},size={50.00,17.00}
	ValDisplay valdisp_ctrl,limits={0,0,0},barmisc={0,1000},value=_NUM:123

	TabControl tab_ctrl,pos={136.00,175.00},size={50.00,20.00},proc=PGCT_TabProc
	TabControl tab_ctrl,tabLabel(0)="Tab 0",tabLabel(1)="Tab 1",value=0

	KillVariables/Z popNum, checked
	KillStrings/Z popStr, called, curval, dval, sval, tab
End

Function PGCT_PopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch(pa.eventCode)
		case 2: // mouse up
			Variable/G popNum = pa.popNum
			String/G popStr   = pa.popStr
			variable/G called = 1
			break
	endswitch

	return 0
End

Function PGCT_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			Variable/G checked = cba.checked
			variable/G called = 1
			break
	endswitch

	return 0
End

Function PGCT_SliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch(sa.eventCode)
		default:
			if( sa.eventCode & 1 ) // value set
				Variable/G curval = sa.curval
				variable/G called = 1
			endif
			break
	endswitch

	return 0
End

Function PGCT_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable/G dval = sva.dval
			String/G sval = sva.sval
			variable/G called = 1
			break
	endswitch

	return 0
End

Function PGCT_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			variable/G called = 1
			break
	endswitch

	return 0
End

Function PGCT_TabProc(tca) : TabControl
	STRUCT WMTabControlAction &tca

	switch( tca.eventCode )
		case 2: // mouse up
			Variable/G tab = tca.tab
			variable/G called = 1
			break
	endswitch

	return 0
End

static Function/WAVE ControlTypesWhichOnlyAcceptVar()

	Make/T/FREE wv = {"checkbox_ctrl_mode_checkbox", "slider_ctrl", "tab_ctrl", "valdisp_ctrl", "button_ctrl"}

	return wv
End

static Function/WAVE ControlTypesWhichRequireOneParameter()

	// all except button
	Make/T/FREE wv = {"checkbox_ctrl_mode_checkbox", "slider_ctrl", "tab_ctrl", "valdisp_ctrl", "popup_ctrl", "setvar_str_ctrl", "setvar_num_ctrl"}

	return wv
End

static Function/WAVE ControlTypesWhichOnlyAcceptVarOrStr()

	Make/T/FREE wv = {"popup_ctrl", "setvar_str_ctrl", "setvar_num_ctrl"}

	return wv
End

// UTF_TD_GENERATOR ControlTypesWhichOnlyAcceptVar
static Function PGCT_AbortsWithStr([string str])

	SVAR/SDFR=root: panel

	try
		PGC_SetAndActivateControl(panel, str, str ="Entry1")
		FAIL()
	catch
		PASS()
	endtry

	NVAR/Z called
	CHECK(!NVAR_Exists(called))
End

// UTF_TD_GENERATOR ControlTypesWhichOnlyAcceptVar
static Function PGCT_SettingVarWorks([string str])
	SVAR/SDFR=root: panel

	PGC_SetAndActivateControl(panel, str, val = 0)

	ControlInfo/W=$panel $str
	CHECK_EQUAL_VAR(V_Value, 0)

	PGC_SetAndActivateControl(panel, str, val = 1)

	if(GetControlType(panel, str) != CONTROL_TYPE_BUTTON)
		ControlInfo/W=$panel $str
		CHECK_EQUAL_VAR(V_Value, 1)
	endif

	// ValDisplay does not have a GUI proc control
	if(GetControlType(panel, str) != CONTROL_TYPE_VALDISPLAY)
		NVAR/Z called
		CHECK(NVAR_Exists(called))
	endif
End

// UTF_TD_GENERATOR ControlTypesWhichRequireOneParameter
static Function PGCT_AbortsWithoutVarAndStrOrBoth([string str])

	SVAR/SDFR=root: panel

	try
		PGC_SetAndActivateControl(panel, str)
		FAIL()
	catch
		PASS()
	endtry

	NVAR/Z called
	CHECK(!NVAR_Exists(called))

	try
		PGC_SetAndActivateControl(panel, str, val = 0, str ="Entry1")
		FAIL()
	catch
		PASS()
	endtry

	NVAR/Z called
	CHECK(!NVAR_Exists(called))
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

Function/WAVE InvalidPopupMenuOtherIndizes()

	Make/FREE wv = {-1, NaN, Inf, -Inf, ItemsInList(PGCT_POPUPMENU_ENTRIES)}

	return wv
End

Function/WAVE InvalidPopupMenuColorTableIndizes()

	Make/FREE wv = {-1, NaN, Inf, -Inf, ItemsInList(CTabList())}

	return wv
End

// UTF_TD_GENERATOR InvalidPopupMenuOtherIndizes
static Function PGCT_PopupMenuOtherAbortsWithOutOfRangeVar([variable var])
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

	try
		PGC_SetAndActivateControl(panel, "popup_ctrl", val = var)
		FAIL()
	catch
		PASS()
	endtry

	ControlInfo/W=$panel popup_ctrl
	refValue  = V_Value
	refString = S_Value
	CHECK_EQUAL_VAR(refValue, popNum)
	CHECK_EQUAL_STR(refString, popStr)
End

// UTF_TD_GENERATOR InvalidPopupMenuColorTableIndizes
static Function PGCT_PopupMenuColorAbortsWithOutOfRangeVar([variable var])
	variable refValue, popNum, i
	string refString, popStr

	SVAR/SDFR=root: panel

	ControlInfo/W=$panel popup_ctrl_colortable
	refValue  = V_Value
	refString = S_Value

	popStr = StringFromList(1, CTabList())
	popNum = 2
	CHECK_EQUAL_VAR(refValue, popNum)
	CHECK_EQUAL_STR(refString, popStr)

	try
		PGC_SetAndActivateControl(panel, "popup_ctrl_colortable", val = var)
		FAIL()
	catch
		PASS()
	endtry

	ControlInfo/W=$panel popup_ctrl_colortable
	refValue  = V_Value
	refString = S_Value
	CHECK_EQUAL_VAR(refValue, popNum)
	CHECK_EQUAL_STR(refString, popStr)

	NVAR/Z popNumNVAR = popNum
	SVAR/Z popStrSVAR = popStr

	CHECK(!NVAR_Exists(popNumNVAR))
	CHECK(!SVAR_Exists(popStrSVAR))
End

static Function PGCT_PopupMenuAbortsWithOutRangeStr()

	variable refValue, popNum
	string refString, popStr

	SVAR/SDFR=root: panel

	try
		PGC_SetAndActivateControl(panel, "popup_ctrl", str = "Entry4")
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

static Function PGCT_ModeFlagDefault()

	variable refState, state

	SVAR/SDFR=root: panel

	// defaults to assert
	try
		PGC_SetAndActivateControl(panel, "checkbox_ctrl_disabled", val = 1)
		FAIL()
	catch
		PASS()
	endtry

	// no changes
	DoUpdate
	ControlInfo/W=$panel checkbox_ctrl_disabled
	state = V_Value

	NVAR/Z checkedSVAR = checked
	CHECK(!NVAR_Exists(checkedSVAR))

	refState = 0
	CHECK_EQUAL_VAR(refState, state)
End

static Function/WAVE VariousModeFlags()

	Make/FREE/D modes = {-1, PGC_MODE_ASSERT_ON_DISABLED, PGC_MODE_FORCE_ON_DISABLED, PGC_MODE_SKIP_ON_DISABLED}

	return modes
End

// UTF_TD_GENERATOR VariousModeFlags
static Function PGCT_ModeFlag([variable var])
	variable refState, state

	SVAR/SDFR=root: panel

	if(var != PGC_MODE_FORCE_ON_DISABLED && var != PGC_MODE_SKIP_ON_DISABLED)
		try
			PGC_SetAndActivateControl(panel, "checkbox_ctrl_disabled", val = 1, mode = var)
			FAIL()
		catch
			PASS()
		endtry
	else
		PGC_SetAndActivateControl(panel, "checkbox_ctrl_disabled", val = 1, mode = var)
	endif

	DoUpdate
	ControlInfo/W=$panel checkbox_ctrl_disabled
	state = V_Value

	if(var == PGC_MODE_FORCE_ON_DISABLED)

		NVAR/Z checkedSVAR = checked
		CHECK(NVAR_Exists(checkedSVAR))

		refState = 1
		CHECK_EQUAL_VAR(refState, state)
	else
		NVAR/Z checkedSVAR = checked
		CHECK(!NVAR_Exists(checkedSVAR))

		refState = 0
		CHECK_EQUAL_VAR(refState, state)
	endif
End

static Function PGCT_SliderOutOfRange()

	variable refState, state

	SVAR/SDFR=root: panel

	try
		PGC_SetAndActivateControl(panel, "slider_ctrl", val = 11)
		FAIL()
	catch
		PASS()
	endtry

	NVAR/Z called
	CHECK(!NVAR_Exists(called))
End
