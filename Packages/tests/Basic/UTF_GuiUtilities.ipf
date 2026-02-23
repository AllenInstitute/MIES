#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = TEST_GUIUTILITIES

/// GetNotebookText/ReplaceNotebookText
/// @{

Function GNT_Works()

	string expected, result
	string win = "nb0"
	expected = "abcd 123"

	KillWindow/Z $win

	NewNotebook/N=$win/F=0
	Notebook $win, setData=expected

	result = GetNotebookText("nb0")
	CHECK_EQUAL_STR(expected, result)

	expected = "hi there!"
	ReplaceNotebookText(win, expected)
	result = GetNotebookText("nb0")
	CHECK_EQUAL_STR(expected, result)
End

/// @}

/// RestoreCursors
/// @{

Function RC_WorksWithReplacementTrace()

	string info, graph

	Make data

	Display data
	graph = S_name

	Cursor A, data, 30
	WAVE/T cursorInfos = GetCursorInfos(graph)

	RemoveTracesFromGraph(graph)

	AppendToGraph data/TN=abcd
	RestoreCursors(graph, cursorInfos)

	info = CsrInfo(A, graph)
	CHECK_PROPER_STR(info)

	KillWindow/Z $graph
	KillWaves/Z data
End

/// @}

/// GetUserDataKeys
/// @{

Function GUD_ReturnsNullWaveIfNothingFound()

	string recMacro, win

	Display
	win = s_name

	recMacro = WinRecreation(win, 0)
	WAVE/Z/T userDataKeys = GetUserdataKeys(recMacro)

	CHECK_WAVE(userDataKeys, NULL_WAVE)
End

Function GUD_ReturnsFoundEntries()

	string recMacro, win

	Display
	win = s_name
	SetWindow $win, userdata(abcd)="123"
	SetWindow $win, userData(efgh)="456"

	recMacro = WinRecreation(win, 0)
	WAVE/T userDataKeys = GetUserdataKeys(recMacro)

	CHECK_EQUAL_TEXTWAVES(userDataKeys, {"abcd", "efgh"})
End

Function GUD_ReturnsFoundEntriesWithoutDuplicates()

	string recMacro, win

	Display
	win = s_name

	// create lines a la
	//
	//	SetWindow kwTopWin,userdata(abcd)=  "123456                                                                                              "
	//	SetWindow kwTopWin,userdata(abcd) +=  "                                                                                                    "
	SetWindow $win, userdata(abcd)="123"
	SetWindow $win, userData(abcd)+=PadString("456", 1e3, 0x20)

	recMacro = WinRecreation(win, 0)
	WAVE/T userDataKeys = GetUserdataKeys(recMacro)

	CHECK_EQUAL_TEXTWAVES(userDataKeys, {"abcd"})
End

/// @}

/// SearchForInvalidControlProcs
/// @{

Function SICP_EnsureValidGUIs()

	string   panel
	variable keepDebugPanel

	// avoid that the default TEST_CASE_BEGIN_OVERRIDE
	// hook keeps our debug panel open if it did not exist before
	keepDebugPanel = WindowExists("DebugPanel")

	panel = DAP_CreateDAEphysPanel()
	CHECK_EQUAL_VAR(SearchForInvalidControlProcs(panel), 0)

	panel = WBP_CreateWaveBuilderPanel()
	CHECK_EQUAL_VAR(SearchForInvalidControlProcs(panel), 0)

	panel = DB_OpenDataBrowser()
	CHECK_EQUAL_VAR(SearchForInvalidControlProcs(panel), 0)

	panel = AB_OpenAnalysisBrowser()
	CHECK_EQUAL_VAR(SearchForInvalidControlProcs(panel), 0)

	IVS_CreatePanel()
	panel = GetCurrentWindow()
	CHECK_EQUAL_VAR(SearchForInvalidControlProcs(panel), 0)

	panel = DP_OpenDebugPanel()
	CHECK_EQUAL_VAR(SearchForInvalidControlProcs(panel), 0)

	if(!keepDebugPanel)
		KillWindow/Z DebugPanel
	endif
End

/// @}

/// GetRecreationMacroAndType
/// GetControlSettingVar
/// GetControlSettingStr
/// @{

Function/S CreateTestPanel_IGNORE()

	string win

	NewPanel/K=1
	win = S_name

	SetVariable setVar0, noEdit=1, format="%g"

	return win
End

Function GCP_Var_Works()

	string win, recMacro
	variable var, controlType

	win                     = CreateTestPanel_IGNORE()
	[recMacro, controlType] = GetRecreationMacroAndType(win, "setVar0")
	CHECK_EQUAL_VAR(controlType, CONTROL_TYPE_SETVARIABLE)

	// existing
	var = GetControlSettingVar(recMacro, "noEdit")
	CHECK_EQUAL_VAR(var, 1)

	// non-present, default defValue
	var = GetControlSettingVar(recMacro, "I DONT EXIST")
	CHECK_EQUAL_VAR(var, NaN)

	// non-present, custom defValue
	var = GetControlSettingVar(recMacro, "I DONT EXIST", defValue = 123)
	CHECK_EQUAL_VAR(var, 123)
End

Function GCP_Str_Works()

	string win, ref, str, recMacro
	variable controlType

	win                     = CreateTestPanel_IGNORE()
	[recMacro, controlType] = GetRecreationMacroAndType(win, "setVar0")
	CHECK_EQUAL_VAR(controlType, CONTROL_TYPE_SETVARIABLE)

	// existing
	str = GetControlSettingStr(recMacro, "format")
	ref = "%g"
	CHECK_EQUAL_STR(str, ref)

	// non-present, default defValue
	str = GetControlSettingStr(recMacro, "I DONT EXIST")
	CHECK_EMPTY_STR(str)

	// non-present, custom defValue
	str = GetControlSettingStr(recMacro, "I DONT EXIST", defValue = "123")
	ref = "123"
	CHECK_EQUAL_STR(str, ref)
End

/// @}

/// GetMarqueeHelper
/// @{

Function GetMarqueeHelperWorks()

	string win, refWin
	variable first, last

	Make/N=1000 data = 0.1 * p
	SetScale/P x, 0, 0.5, data
	Display/K=1 data
	refWin = S_name

	DoUpdate/W=$refWin
	SetMarquee/HAX=bottom/VAX=left/W=$refWin 10, 2, 30, 4

	// non-existing axis
	try
		[first, last] = GetMarqueeHelper("I_DONT_EXIST", horiz = 1)
		FAIL()
	catch
		CHECK_EQUAL_VAR(first, NaN)
		CHECK_EQUAL_VAR(last, NaN)
	endtry

	// non-existing axis without assert
	[first, last] = GetMarqueeHelper("I_DONT_EXIST", horiz = 1, doAssert = 0)
	CHECK_EQUAL_VAR(first, NaN)
	CHECK_EQUAL_VAR(last, NaN)

	// missing horiz/vert
	try
		[first, last] = GetMarqueeHelper("left")
		FAIL()
	catch
		CHECK_EQUAL_VAR(first, NaN)
		CHECK_EQUAL_VAR(last, NaN)
	endtry

	// both horiz/vert
	try
		[first, last] = GetMarqueeHelper("left", horiz = 1, vert = 1)
		FAIL()
	catch
		CHECK_EQUAL_VAR(first, NaN)
		CHECK_EQUAL_VAR(last, NaN)
	endtry

	// querying without kill (default)
	[first, last] = GetMarqueeHelper("bottom", horiz = 1)
	CHECK_CLOSE_VAR(first, 10, tol = 1)
	CHECK_CLOSE_VAR(last, 30, tol = 1)

	// querying without kill (explicit)
	[first, last] = GetMarqueeHelper("bottom", horiz = 1, kill = 0)
	CHECK_CLOSE_VAR(first, 10, tol = 1)
	CHECK_CLOSE_VAR(last, 30, tol = 1)

	// query with kill and win
	[first, last] = GetMarqueeHelper("left", vert = 1, kill = 1, win = win)
	CHECK_CLOSE_VAR(first, 2, tol = 1)
	CHECK_CLOSE_VAR(last, 4, tol = 1)
	CHECK_EQUAL_STR(win, refWin)

	// marquee is gone
	[first, last] = GetMarqueeHelper("left", horiz = 1, doAssert = 0)
	CHECK_EQUAL_VAR(first, NaN)
	CHECK_EQUAL_VAR(last, NaN)

	KillWindow $refWin
	KillWaves/Z data
End

/// @}

/// GetAxesProperties
/// SetAxesProperties
/// @{

static Function/S ConvertMacroToPlainCommands(string recMacro)

	// remove first two and last line
	variable numLines

	numLines = ItemsInList(recMacro, "\r")
	CHECK_GT_VAR(numLines, 0)

	Make/FREE/T/N=(numLines) contents = StringFromList(p, recMacro, "\r")

	contents[0, 1]         = ""
	contents[numLines - 1] = ""

	return ReplaceString("\r", TextWaveToList(contents, "\r"), ";")
End

/// UTF_TD_GENERATOR DataGenerators#GetDifferentGraphs
Function StoreRestoreAxisProps([string str])

	string win, actual, commands

	DFREF saveDFR = GetDataFolderDFR()

	NewDataFolder/O/S root:temp_test
	KillWaves/A
	KillStrings/A
	KillVariables/A
	Make data = p

	// execute recreation macro
	commands = ConvertMacroToPlainCommands(str)
	Execute commands
	DoUpdate
	win = GetCurrentWindow()

	WAVE props = GetAxesProperties(win)
	RemoveTracesFromGraph(win)

	WAVE/Z/SDFR=root data
	CHECK_WAVE(data, NORMAL_WAVE)
	AppendToGraph/W=$win data

	SetAxesProperties(win, props)
	actual = Winrecreation(win, 0)
	CHECK_EQUAL_STR(str, actual)

	KillWindow $win

	SetDataFolder saveDFR
End

/// @}

/// GetValDisplayAsString
/// @{

static Function NoNullReturnFromGetValDisplayAsString()

	NewPanel/N=testpanelVal
	ValDisplay vdisp, win=testpanelVal

	GetValDisplayAsString("testpanelVal", "vdisp")
	PASS()
End

/// @}

/// GetPopupMenuString
/// @{

static Function NoNullReturnFromGetPopupMenuString()

	NewPanel/N=testpanelPM
	PopupMenu pmenu, win=testpanelPM

	GetPopupMenuString("testpanelPM", "pmenu")
	PASS()
End

/// @}

/// GetSetVariableString
/// @{

static Function NoNullReturnFromGetSetVariableString()

	NewPanel/N=testpanelSV
	SetVariable svari, win=testpanelSV

	GetSetVariableString("testpanelSV", "svari")
	PASS()
End

/// @}

/// ScrollListboxIntoView
/// @{

static Function GetTopRow_IGNORE(string win, string ctrl)

	Controlinfo/W=$win $ctrl

	return V_startRow
End

static Function TestScrollListboxIntoView()

	string win, ctrl
	variable topRow, ret

	Make/T listWave = num2str(p)

	NewPanel/N=testpanelLB
	win = S_name

	ListBox list, listWave=listWave, size={300, 100}
	ctrl = "list"
	DoUpdate/W=$win

	try
		ScrollListboxIntoView(win, ctrl, NaN)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	DoUpdate/W=$win
	topRow = GetTopRow_IGNORE(win, ctrl)
	CHECK_EQUAL_VAR(topRow, 0)

	// clips to zero
	ret = ScrollListboxIntoView(win, ctrl, -1)
	CHECK_EQUAL_VAR(ret, 1)

	DoUpdate/W=$win
	topRow = GetTopRow_IGNORE(win, ctrl)
	CHECK_EQUAL_VAR(topRow, 0)

	// clips to available rows
	ret = ScrollListboxIntoView(win, ctrl, 500)
	CHECK_EQUAL_VAR(ret, 0)

	DoUpdate/W=$win
	topRow = GetTopRow_IGNORE(win, ctrl)
	CHECK_EQUAL_VAR(topRow, 124)

	// moves to the top if lower than current
	ret = ScrollListboxIntoView(win, ctrl, 50)
	CHECK_EQUAL_VAR(ret, 0)

	DoUpdate/W=$win
	topRow = GetTopRow_IGNORE(win, ctrl)
	CHECK_EQUAL_VAR(topRow, 50)

	// and to the bottom if larger
	ret = ScrollListboxIntoView(win, ctrl, 75)
	CHECK_EQUAL_VAR(ret, 0)

	DoUpdate/W=$win
	topRow = GetTopRow_IGNORE(win, ctrl)
	CHECK_EQUAL_VAR(topRow, 71)

	KillOrMoveToTrash(wv = listWave)
End

/// @}
