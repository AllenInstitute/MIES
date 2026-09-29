#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = PGC_Testing

static Function TEST_CASE_BEGIN_OVERRIDE(string testCase)

	SVAR/Z/SDFR=root: panel
	if(SVAR_Exists(panel))
		KillWindow/Z $panel
	endif

	TestCaseBeginCommon(testCase)

	CreatePGCTestPanel_IGNORE()

	CA_FlushCache()
End

static Function TEST_CASE_END_OVERRIDE(string testCase)

	TestCaseEndCommon(testCase, emptyFolderCheck = 0)
End

Function CreatePGCTestPanel_IGNORE()

	NewPanel/K=1/W=(265, 784, 820, 987)
	string/G root:panel = S_name

	PopupMenu popup_ctrl, proc=PGCT_PopMenuProc, value=#("\"" + PGCT_POPUPMENU_ENTRIES + "\""), mode=1
	PopupMenu popup_ctrl_colortable, pos={68.00, 114.00}, size={200.00, 19.00}, proc=PGCT_PopMenuProc
	PopupMenu popup_ctrl_colortable, mode=2, value=#"\"*COLORTABLEPOP*\""

	CheckBox checkbox_ctrl_mode_checkbox, pos={66.00, 1.00}, size={39.00, 15.00}, proc=PGCT_CheckProc
	CheckBox checkbox_ctrl_mode_checkbox, value=0
	CheckBox checkbox_ctrl_disabled, value=0, disable=DISABLE_CONTROL_BIT, proc=PGCT_CheckProc

	Slider slider_ctrl, pos={79.00, 36.00}, size={164.00, 56.00}
	Slider slider_ctrl, limits={0, 10, 1}, value=0, vert=0, proc=PGCT_SliderProc

	SetVariable setvar_str_ctrl, pos={184.00, 151.00}, size={50.00, 18.00}, proc=PGCT_SetVarProc
	SetVariable setvar_str_ctrl, value=_STR:"abcd"

	SetVariable setvar_num_ctrl, pos={120.00, 151.00}, size={50.00, 18.00}, proc=PGCT_SetVarProc
	SetVariable setvar_num_ctrl, value=_NUM:123

	Button button_ctrl, pos={20.00, 148.00}, size={50.00, 20.00}, proc=PGCT_ButtonProc

	ValDisplay valdisp_ctrl, pos={219.00, 12.00}, size={50.00, 17.00}
	ValDisplay valdisp_ctrl, limits={0, 0, 0}, barmisc={0, 1000}, value=_NUM:123

	TabControl tab_ctrl, pos={136.00, 175.00}, size={50.00, 20.00}, proc=PGCT_TabProc
	TabControl tab_ctrl, tabLabel(0)="Tab 0", tabLabel(1)="Tab 1", value=0

	KillVariables/Z popNum, checked
	KillStrings/Z popStr, called, curval, dval, sval, tab, eventCode

	Make/T/O listWave = {"elem A", "elem B"}
	Make/N=2/O selWave
	Make/N=(3, 2)/O colorWave
	Make/T/O titleWave = {"title"}

	ListBox listbox_ctrl, pos={290.00, 11.00}, size={252.00, 168.00}, listWave=listWave, colorWave=colorWave
	ListBox listbox_ctrl, selWave=selWave, titleWave=titleWave, mode=1, proc=PGCT_ListBoxProc
End

Function PGCT_PopMenuProc(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		default:
			variable/G popNum = pa.popNum
			string/G   popStr = pa.popStr
			variable/G eventCode = pa.eventCode
			variable/G called = 1
			break
	endswitch

	return 0
End

Function PGCT_CheckProc(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	switch(cba.eventCode)
		default:
			variable/G checked = cba.checked
			variable/G eventCode = cba.eventCode
			variable/G called  = 1
			break
	endswitch

	return 0
End

Function PGCT_SliderProc(STRUCT WMSliderAction &sa) : SliderControl

	switch(sa.eventCode)
		default:
			variable/G curval = sa.curval
			variable/G eventCode = sa.eventCode
			variable/G called = 1
			break
	endswitch

	return 0
End

Function PGCT_SetVarProc(STRUCT WMSetVariableAction &sva) : SetVariableControl

	switch(sva.eventCode)
		default:
			variable/G dval   = sva.dval
			string/G   sval   = sva.sval
			variable/G eventCode = sva.eventCode
			variable/G called = 1
			break
	endswitch

	return 0
End

Function PGCT_ButtonProc(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		default:
			variable/G eventCode = ba.eventCode
			variable/G called = 1
			break
	endswitch

	return 0
End

Function PGCT_TabProc(STRUCT WMTabControlAction &tca) : TabControl

	switch(tca.eventCode)
		default:
			variable/G tab    = tca.tab
			variable/G eventCode = tca.eventCode
			variable/G called = 1
			break
	endswitch

	return 0
End

Function PGCT_ListBoxProc(STRUCT WMListboxAction &lba) : ListBoxControl

	switch(lba.eventCode)
		default:
			variable/G eventCode = lba.eventCode
			variable/G called = 1

			variable/G row = lba.row
			
			if(lba.eventCode != EVENT_LISTBOXACTION_BEING_KILLED)
				CHECK_EQUAL_VAR(lba.col, -1)
			endif

			CHECK_WAVE(lba.listWave, TEXT_WAVE)
			CHECK_WAVE(lba.selWave, NUMERIC_WAVE)
			CHECK_WAVE(lba.colorWave, NUMERIC_WAVE)
			CHECK_WAVE(lba.titleWave, TEXT_WAVE)
			break
	endswitch

	return 0
End

// UTF_TD_GENERATOR DataGenerators#ControlTypesWhichOnlyAcceptVar
static Function PGCT_AbortsWithStr([string str])

	SVAR/SDFR=root: panel

	try
		PGC_SetAndActivateControl(panel, str, str = "Entry1")
		FAIL()
	catch
		PASS()
	endtry

	NVAR/Z called
	CHECK(!NVAR_Exists(called))
End

// UTF_TD_GENERATOR DataGenerators#ControlTypesWhichOnlyAcceptVar
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

	NVAR/Z eventCode

	switch(GetControlType(panel, str))
		case CONTROL_TYPE_VALDISPLAY:
			CHECK(!NVAR_Exists(eventCode))
			break
		case CONTROL_TYPE_LISTBOX:
			CHECK(NVAR_Exists(eventCode))
			CHECK_EQUAL_VAR(eventCode, 3)
			break
		case CONTROL_TYPE_SLIDER:
			CHECK(NVAR_Exists(eventCode))
			CHECK_EQUAL_VAR(eventCode, 1)
			break
		default:
			CHECK(NVAR_Exists(eventCode))
			CHECK_EQUAL_VAR(eventCode, 2)
			break
	endswitch
End

// UTF_TD_GENERATOR DataGenerators#ControlTypesWhichRequireOneParameter
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
		PGC_SetAndActivateControl(panel, str, val = 0, str = "Entry1")
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

	variable refValue, popNum, i, eventCode
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
		NVAR eventCodeSVAR = eventCode
		eventCode = eventCodeSVAR

		CHECK_EQUAL_VAR(refValue, popNum)
		CHECK_EQUAL_STR(refString, popStr)
		CHECK_EQUAL_VAR(eventCode, 2)
	endfor
End

// UTF_TD_GENERATOR DataGenerators#InvalidPopupMenuOtherIndizes
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

// UTF_TD_GENERATOR DataGenerators#InvalidPopupMenuColorTableIndizes
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

// UTF_TD_GENERATOR DataGenerators#VariousModeFlags
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

static Function PGCT_NonExistingWindow()

	try
		PGC_SetAndActivateControl("I DON'T EXIST", "slider_ctrl", val = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function PGCT_NonExistingControl()

	SVAR/SDFR=root: panel

	try
		PGC_SetAndActivateControl(panel, "I DON'T EXIST", val = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function PGCT_SetVariableVarWorks()

	variable refValue, setVarNum, eventCode
	string refString, setVarStr

	SVAR/SDFR=root: panel

	ControlInfo/W=$panel setvar_num_ctrl
	refValue  = V_Value
	refString = S_Value
	CHECK_EMPTY_STR(refString)

	refValue += 1

	PGC_SetAndActivateControl(panel, "setvar_num_ctrl", val = refValue)

	NVAR setVarNumNVAR = dVal
	setVarNum = setVarNumNVAR

	SVAR setVarStrSVAR = sVal
	setVarStr = setVarStrSVAR
	refString = num2str(setVarNum)

	CHECK_EQUAL_VAR(refValue, setVarNum)
	CHECK_EQUAL_STR(refString, setVarStr)

	// and now with str parameter

	refValue += 1

	PGC_SetAndActivateControl(panel, "setvar_num_ctrl", str = num2str(refValue))

	NVAR setVarNumNVAR = dVal
	setVarNum = setVarNumNVAR

	SVAR setVarStrSVAR = sVal
	setVarStr = setVarStrSVAR
	refString = num2str(setVarNum)

	NVAR eventCodeSVAR = eventCode
	eventCode = eventCodeSVAR

	CHECK_EQUAL_VAR(refValue, setVarNum)
	CHECK_EQUAL_STR(refString, setVarStr)
	CHECK_EQUAL_VAR(eventCode, 2)
End

static Function PGCT_SetVariableStrWorks()

	variable refValue, setVarNum, eventCode
	string refString, setVarStr

	SVAR/SDFR=root: panel

	ControlInfo/W=$panel setvar_str_ctrl
	refValue  = V_Value
	refString = S_Value
	CHECK_EQUAL_VAR(refValue, NaN)

	refString += "some stuff"

	PGC_SetAndActivateControl(panel, "setvar_str_ctrl", str = refString)

	NVAR setVarNumNVAR = dVal
	setVarNum = setVarNumNVAR

	SVAR setVarStrSVAR = sVal
	setVarStr = setVarStrSVAR

	CHECK_EQUAL_VAR(0, setVarNum)
	CHECK_EQUAL_STR(refString, setVarStr)

	// and now with var parameter

	refValue = 123

	PGC_SetAndActivateControl(panel, "setvar_str_ctrl", val = refValue)

	NVAR setVarNumNVAR = dVal
	setVarNum = setVarNumNVAR

	SVAR setVarStrSVAR = sVal
	setVarStr = setVarStrSVAR

	refString = num2str(refValue)

	NVAR eventCodeSVAR = eventCode
	eventCode = eventCodeSVAR

	CHECK_EQUAL_VAR(0, setVarNum)
	CHECK_EQUAL_STR(refString, setVarStr)
	CHECK_EQUAL_VAR(eventCode, 2)
End

static Function PGCT_SetVariableChecksNoEdit()

	variable refValue

	SVAR/SDFR=root: panel

	ControlInfo/W=$panel setvar_num_ctrl
	refValue = V_Value
	CHECK_EMPTY_STR(S_Value)

	SetVariable setvar_num_ctrl, win=$panel, noEdit=1

	// default
	try
		PGC_SetAndActivateControl(panel, "setvar_num_ctrl", val = refValue + 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	ControlInfo/W=$panel setvar_num_ctrl
	CHECK_EQUAL_VAR(refValue, V_Value)

	// assert
	try
		PGC_SetAndActivateControl(panel, "setvar_num_ctrl", val = refValue + 1, mode = PGC_MODE_ASSERT_ON_DISABLED)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	ControlInfo/W=$panel setvar_num_ctrl
	CHECK_EQUAL_VAR(refValue, V_Value)

	// force
	try
		PGC_SetAndActivateControl(panel, "setvar_num_ctrl", val = refValue + 1, mode = PGC_MODE_FORCE_ON_DISABLED)
		PASS()
	catch
		FAIL()
	endtry

	refValue += 1

	ControlInfo/W=$panel setvar_num_ctrl
	CHECK_EQUAL_VAR(refValue, V_Value)

	// skip
	try
		PGC_SetAndActivateControl(panel, "setvar_num_ctrl", val = refValue + 1, mode = PGC_MODE_SKIP_ON_DISABLED)
		PASS()
	catch
		FAIL()
	endtry

	ControlInfo/W=$panel setvar_num_ctrl
	CHECK_EQUAL_VAR(refValue, V_Value)
End

static Function PGCT_ListboxWorks()

	variable eventCode

	SVAR/SDFR=root: panel

	PGC_SetAndActivateControl(panel, "listbox_ctrl", val = 0)

	NVAR/Z row
	CHECK(NVAR_Exists(row))
	CHECK_EQUAL_VAR(row, 0)

	PGC_SetAndActivateControl(panel, "listbox_ctrl", val = 1)
	CHECK_EQUAL_VAR(row, 1)

	NVAR eventCodeSVAR = eventCode
	eventCode = eventCodeSVAR
	CHECK_EQUAL_VAR(eventCode, 3)

	try
		PGC_SetAndActivateControl(panel, "listbox_ctrl", val = 2)
		FAIL()
	catch
		PASS()
	endtry
End
