#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3	 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTF_SweepFormula

Function/S CreateFakeSweepBrowser_IGNORE()

	string win

	Display
	win = S_name
	DFREF dfr = GetDataFolderDFR()
	AddVersionToPanel(win, DATA_SWEEP_BROWSER_PANEL_VERSION)
	BSP_SetFolder(win, dfr, MIES_BSP_PANEL_FOLDER)
	BSP_SetSweepBrowser(win, BROWSER_MODE_USER)

	return win
End

/// @brief test two jsonIDs for equal content
static Function CHECK_EQUAL_JSON(jsonID0, jsonID1)
	variable jsonID0, jsonID1

	string jsonDump0, jsonDump1

	JSONXOP_Dump/IND=2 jsonID0
	jsonDump0 = S_Value
	JSONXOP_Dump/IND=2 jsonID1
	jsonDump1 = S_Value

	CHECK_EQUAL_STR(jsonDump0, jsonDump1)
End

static Function [string win, string device] CreateFakeDataBrowserWindow()

	device = HW_ITC_BuildDeviceString(StringFromList(0, DEVICE_TYPES_ITC), StringFromList(0, DEVICE_NUMBERS))
	win = DATABROWSER_WINDOW_NAME

	if(windowExists(win))
		DoWindow/K $win
	endif

	Display/N=$win as device
	AddVersionToPanel(win, DATA_SWEEP_BROWSER_PANEL_VERSION)
	BSP_SetDataBrowser(win, BROWSER_MODE_USER)
	BSP_SetDevice(win, device)
	MIES_DB#DB_SetUserData(win, device)
End

static Function/WAVE GetMultipleResults(string formula, string win)

	WAVE wTextRef = SF_FormulaExecutor(win, DirectToFormulaParser(formula))
	CHECK(IsTextWave(wTextRef))
	CHECK_EQUAL_VAR(DimSize(wTextRef, ROWS), 1)
	CHECK_EQUAL_VAR(DimSize(wTextRef, COLS), 0)
	return MIES_SF#SF_ParseArgument(win, wTextRef, "TestRun")
End

static Function/WAVE GetSingleResult(string formula, string win)

	WAVE/WAVE wRefResult = GetMultipleResults(formula, win)
	CHECK_EQUAL_VAR(DimSize(wRefResult, ROWS), 1)
	CHECK_EQUAL_VAR(DimSize(wRefResult, COLS), 0)

	return wRefResult[0]
End

static Function FailFormula(string code)

	try
		DirectToFormulaParser(code)
		FAIL()
	catch
		PASS()
	endtry
End

static Function DirectToFormulaParser(string code)

	code = MIES_SF#SF_PreprocessInput(code)
	code = MIES_SF#SF_FormulaPreParser(code)
	return MIES_SF#SF_FormulaParser(code)
End

static Function primitiveOperations()

	variable jsonID0, jsonID1
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	jsonID0 = JSON_Parse("null")
	jsonID1 = DirectToFormulaParser("")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	TestOperationMinMaxHelper(win, "1", "1", 1)
	TestOperationMinMaxHelper(win, "{\"+\":[1,2]}", "1+2", 1 + 2)
	TestOperationMinMaxHelper(win, "{\"*\":[1,2]}", "1*2", 1 * 2)
	TestOperationMinMaxHelper(win, "{\"-\":[1,2]}", "1-2", 1 - 2)
	TestOperationMinMaxHelper(win, "{\"/\":[1,2]}", "1/2", 1 / 2)
	TestOperationMinMaxHelper(win, "-1", "-1", -1)
	TestOperationMinMaxHelper(win, "1", "+1", +1)
	TestOperationMinMaxHelper(win, "{\"-\":[-1,1]}", "-1-1", -1 - 1)
	TestOperationMinMaxHelper(win, "{\"-\":[1,-1]}", "1--1", 1 - -1)
	TestOperationMinMaxHelper(win, "{\"+\":[1,1]}", "1++1", 1 + +1)
End

static Function Transitions()

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	// number calculation function
	TestOperationMinMaxHelper(win, "{\"+\": [1,{\"max\": [1]}]}", "1+max(1)", 2)
	TestOperationMinMaxHelper(win, "{\"+\": [1,{\"max\": [1]}]}", "1 + max ( 1 )", 2)
	TestOperationMinMaxHelper(win, "{\"+\": [1,{\"max\": [1]}]}", "1  +  max  (  1  )", 2)

	TestOperationMinMaxHelper(win, "{\"-\": [1,{\"max\": [1]}]}", "1-max(1)", 0)
	TestOperationMinMaxHelper(win, "{\"-\": [1,{\"max\": [1]}]}", "1 - max ( 1 )", 0)
	TestOperationMinMaxHelper(win, "{\"-\": [1,{\"max\": [1]}]}", "1  -  max  (  1  )", 0)

	TestOperationMinMaxHelper(win, "{\"*\": [1,{\"max\": [1]}]}", "1*max(1)", 1)
	TestOperationMinMaxHelper(win, "{\"*\": [1,{\"max\": [1]}]}", "1 * max ( 1 )", 1)
	TestOperationMinMaxHelper(win, "{\"*\": [1,{\"max\": [1]}]}", "1  *  max  (  1  )", 1)

	TestOperationMinMaxHelper(win, "{\"/\": [1,{\"max\": [1]}]}", "1/max(1)", 1)
	TestOperationMinMaxHelper(win, "{\"/\": [1,{\"max\": [1]}]}", "1 / max ( 1 )", 1)
	TestOperationMinMaxHelper(win, "{\"/\": [1,{\"max\": [1]}]}", "1  /  max  (  1  )", 1)

	// function calculation number
	TestOperationMinMaxHelper(win, "{\"+\": [{\"max\": [1]},1]}", "max(1)+1", 2)
	TestOperationMinMaxHelper(win, "{\"+\": [{\"max\": [1]},1]}", "max( 1 ) + 1", 2)
	TestOperationMinMaxHelper(win, "{\"+\": [{\"max\": [1]},1]}", "max(  1  )  +  1", 2)

	TestOperationMinMaxHelper(win, "{\"-\": [{\"max\": [1]},1]}", "max(1)-1", 0)
	TestOperationMinMaxHelper(win, "{\"-\": [{\"max\": [1]},1]}", "max( 1 ) - 1", 0)
	TestOperationMinMaxHelper(win, "{\"-\": [{\"max\": [1]},1]}", "max(  1  )  -  1", 0)

	TestOperationMinMaxHelper(win, "{\"*\": [{\"max\": [1]},1]}", "max(1)*1", 1)
	TestOperationMinMaxHelper(win, "{\"*\": [{\"max\": [1]},1]}", "max( 1 ) * 1", 1)
	TestOperationMinMaxHelper(win, "{\"*\": [{\"max\": [1]},1]}", "max(  1  )  *  1", 1)

	TestOperationMinMaxHelper(win, "{\"/\": [{\"max\": [1]},1]}", "max(1)/1", 1)
	TestOperationMinMaxHelper(win, "{\"/\": [{\"max\": [1]},1]}", "max( 1 ) / 1", 1)
	TestOperationMinMaxHelper(win, "{\"/\": [{\"max\": [1]},1]}", "max(  1  )  /  1", 1)

	// array calculation number
	CheckEqualFormulas("{\"+\": [[1,2,3],1]}", "[1,2,3]+1")
	CheckEqualFormulas("{\"+\": [[1,2,3],1]}", "[1,2,3] + 1")
	CheckEqualFormulas("{\"+\": [[1,2,3],1]}", "[1,2,3]  +  1")

	CheckEqualFormulas("{\"-\": [[1,2,3],1]}", "[1,2,3]-1")
	CheckEqualFormulas("{\"-\": [[1,2,3],1]}", "[1,2,3] - 1")
	CheckEqualFormulas("{\"-\": [[1,2,3],1]}", "[1,2,3]  -  1")

	CheckEqualFormulas("{\"*\": [[1,2,3],1]}", "[1,2,3]*1")
	CheckEqualFormulas("{\"*\": [[1,2,3],1]}", "[1,2,3] * 1")
	CheckEqualFormulas("{\"*\": [[1,2,3],1]}", "[1,2,3]  *  1")

	CheckEqualFormulas("{\"/\": [[1,2,3],1]}", "[1,2,3]/1")
	CheckEqualFormulas("{\"/\": [[1,2,3],1]}", "[1,2,3] / 1")
	CheckEqualFormulas("{\"/\": [[1,2,3],1]}", "[1,2,3]  /  1")

	// number calculation array
	CheckEqualFormulas("{\"+\": [1,[1,2,3]]}", "1+[1,2,3]")
	CheckEqualFormulas("{\"+\": [1,[1,2,3]]}", "1 + [1,2,3]")
	CheckEqualFormulas("{\"+\": [1,[1,2,3]]}", "1  +  [1,2,3]")

	CheckEqualFormulas("{\"-\": [1,[1,2,3]]}", "1-[1,2,3]")
	CheckEqualFormulas("{\"-\": [1,[1,2,3]]}", "1 - [1,2,3]")
	CheckEqualFormulas("{\"-\": [1,[1,2,3]]}", "1  -  [1,2,3]")

	CheckEqualFormulas("{\"*\": [1,[1,2,3]]}", "1*[1,2,3]")
	CheckEqualFormulas("{\"*\": [1,[1,2,3]]}", "1 * [1,2,3]")
	CheckEqualFormulas("{\"*\": [1,[1,2,3]]}", "1  *  [1,2,3]")

	CheckEqualFormulas("{\"/\": [1,[1,2,3]]}", "1/[1,2,3]")
	CheckEqualFormulas("{\"/\": [1,[1,2,3]]}", "1 / [1,2,3]")
	CheckEqualFormulas("{\"/\": [1,[1,2,3]]}", "1  /  [1,2,3]")
End

static Function stringHandling()
	Variable jsonID0, jsonID1

	// basic strings
	jsonID0 = JSON_Parse("\"abc\"")
	jsonID1 = DirectToFormulaParser("abc")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	// ignore white spaces
	jsonID0 = JSON_Parse("\"abcdef\"")
	jsonID1 = DirectToFormulaParser("abc def")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	// allow white space in strings
	jsonID0 = JSON_Parse("\"abc def\"")
	jsonID1 = DirectToFormulaParser("\"abc def\"")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	// ignore comments
	jsonID0 = JSON_Parse("null")
	jsonID1 = DirectToFormulaParser("# comment")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	// do not evaluate calculations in strings
	jsonID0 = JSON_Parse("\"1+1\"")
	jsonID1 = DirectToFormulaParser("\"1+1\"")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("\"\"")
	jsonID1 = DirectToFormulaParser("\"\"")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	// evil strings
	jsonID0 = JSON_Parse("\"-\"")
	jsonID1 = DirectToFormulaParser("-")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("\"+\"")
	jsonID1 = DirectToFormulaParser("+")

	CHECK_EQUAL_JSON(jsonID0, jsonID1)
	jsonID0 = JSON_Parse("\"-a\"")
	jsonID1 = DirectToFormulaParser("-a")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	CHECK_EQUAL_JSON(jsonID0, jsonID1)
	jsonID0 = JSON_Parse("\"+a\"")
	jsonID1 = DirectToFormulaParser("+a")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)
End

static Function arrayOperations(string win, string array2d, variable numeric)

	string str

	WAVE input = JSON_GetWave(JSON_Parse(array2d), "")
	// simulate simplified array expansion
	input[][] = IsNaN(input[p][q]) ? input[p][0] : input[p][q]

	str = array2d
	WAVE output = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Duplicate/FREE input input0
	input0[][][][] = input[p][q][r][s] - input[p][q][r][s]
	str = array2d + "-" + array2d
	WAVE output = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(input0, output, mode = WAVE_DATA)

	Duplicate/FREE input input1
	input1[][][][] = input[p][q][r][s] + input[p][q][r][s]
	str = array2d + "+" + array2d
	WAVE output = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(input1, output, mode = WAVE_DATA)

	Duplicate/FREE input input2
	input2[][][][] = input[p][q][r][s] / input[p][q][r][s]
	str = array2d + "/" + array2d
	WAVE output = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(input2, output, mode = WAVE_DATA)

	Duplicate/FREE input input3
	input3[][][][] = input[p][q][r][s] * input[p][q][r][s]
	str = array2d + "*" + array2d
	WAVE output = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(input3, output, mode = WAVE_DATA)

	Duplicate/FREE input input10
	input10 -= numeric
	str = array2d + "-" + num2str(numeric)
	WAVE output = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(input10, output, mode = WAVE_DATA)
	input10[][][][] = numeric - input[p][q][r][s]
	str = num2str(numeric) + "-" + array2d
	WAVE output = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(input10, output, mode = WAVE_DATA)

	Duplicate/FREE input input11
	input11 += numeric
	str = array2d + "+" + num2str(numeric)
	WAVE output = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(input11, output, mode = WAVE_DATA)
	input11[][][][] = numeric + input[p][q][r][s]
	str = num2str(numeric) + "+" + array2d
	WAVE output = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(input11, output, mode = WAVE_DATA)

	Duplicate/FREE input input12
	input12 /= numeric
	str = array2d + "/" + num2str(numeric)
	WAVE output = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(input12, output, mode = WAVE_DATA)
	input12[][][][] = numeric / input[p][q][r][s]
	str = num2str(numeric) + "/" + array2d
	WAVE output = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(input12, output, mode = WAVE_DATA)

	Duplicate/FREE input input13
	input13 *= numeric
	str = array2d + "*" + num2str(numeric)
	WAVE output = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(input13, output, mode = WAVE_DATA)
	input13[][][][] = numeric * input[p][q][r][s]
	str = num2str(numeric) + "*" + array2d
	WAVE output = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(input13, output, mode = WAVE_DATA)
End

static Function primitiveOperations2D()

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	arrayOperations(win, "[1,2]", 1)
	arrayOperations(win, "[[1,2],[3,4],[5,6]]", 1)
	arrayOperations(win, "[[1,2],[3,4],[5,6]]", 42)
	arrayOperations(win, "[[1],[3,4],[5,6]]", 1)
	arrayOperations(win, "[[1,2],[3],[5,6]]", 1)
	arrayOperations(win, "[[1,2],[3,4],[5]]", 1)
	arrayOperations(win, "[[1,2],[3,4],[5,6]]", 1.5)
End

static Function TestArrayExpansionText()

	string win, device, str

	[win, device] = CreateFakeDataBrowserWindow()

	str = "[[\"1\"],[\"3\",\"4\"],[\"5\",\"6\"]]"
	WAVE/T output = GetSingleResult(str, win)

	WAVE/T input = JSON_GetTextWave(JSON_Parse(str), "")
	// simulate simplified array expansion
	input[][] = SelectString(IsEmpty(input[p][q]), input[p][q], input[p][0])

	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)
End

static Function concatenationOfOperations()

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	TestOperationMinMaxHelper(win, "{\"+\":[1,2,3,4]}", "1+2+3+4", 1 + 2 + 3 + 4)
	TestOperationMinMaxHelper(win, "{\"-\":[1,2,3,4]}", "1-2-3-4", 1 - 2 - 3 - 4)
	TestOperationMinMaxHelper(win, "{\"/\":[1,2,3,4]}", "1/2/3/4", 1 / 2 / 3 / 4)
	TestOperationMinMaxHelper(win, "{\"*\":[1,2,3,4]}", "1*2*3*4", 1 * 2 * 3 * 4)
End

// + > - > * > /
static Function orderOfCalculation()

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	// + and -
	TestOperationMinMaxHelper(win, "{\"+\":[2,{\"-\":[3,4]}]}", "2+3-4", 2 + 3 - 4)
	TestOperationMinMaxHelper(win, "{\"+\":[{\"-\":[2,3]},4]}", "2-3+4", 2 - 3 + 4)

	// + and *
	TestOperationMinMaxHelper(win, "{\"+\":[2,{\"*\":[3,4]}]}", "2+3*4", 2 + 3 * 4)
	TestOperationMinMaxHelper(win, "{\"+\":[{\"*\":[2,3]},4]}", "2*3+4", 2 * 3 + 4)

	// + and /
	TestOperationMinMaxHelper(win, "{\"+\":[2,{\"/\":[3,4]}]}", "2+3/4", 2 + 3 / 4)
	TestOperationMinMaxHelper(win, "{\"+\":[{\"/\":[2,3]},4]}", "2/3+4", 2 / 3 + 4)

	// - and *
	TestOperationMinMaxHelper(win, "{\"-\":[2,{\"*\":[3,4]}]}", "2-3*4", 2 - 3 * 4)
	TestOperationMinMaxHelper(win, "{\"-\":[{\"*\":[2,3]},4]}", "2*3-4", 2 * 3 - 4)

	// - and /
	TestOperationMinMaxHelper(win, "{\"-\":[2,{\"/\":[3,4]}]}", "2-3/4", 2 - 3 / 4)
	TestOperationMinMaxHelper(win, "{\"-\":[{\"/\":[2,3]},4]}", "2/3-4", 2 / 3 - 4)

	// * and /
	TestOperationMinMaxHelper(win, "{\"*\":[2,{\"/\":[3,4]}]}", "2*3/4", 2 * 3 / 4)
	TestOperationMinMaxHelper(win, "{\"*\":[{\"/\":[2,3]},4]}", "2/3*4", 2 / 3 * 4)
	TestOperationMinMaxHelper(win, "{\"+\":[{\"+\":[{\"*\":[5,1]},{\"*\":[2,3]}]},4,{\"*\":[5,20]}]}", "5*1+2*3+4+5*20", 5 * 1 + 2 * 3 + 4 + 5 * 20)

	// using - as sign
	TestOperationMinMaxHelper(win, "{\"+\":[1,-1]}", "1+-1", 0)
	TestOperationMinMaxHelper(win, "{\"+\":[-1,2]}", "-1+2", 1)
	TestOperationMinMaxHelper(win, "{\"*\":[-1,2]}", "-1*2", -2)
	TestOperationMinMaxHelper(win, "{\"+\":[2,{\"*\":[-1,3]}]}", "2+-1*3", -1)
End

Function/WAVE InvalidInputs()

	Make/FREE/T wt = {",1", " ,1", "1,,", "1, ,", "(1), ,", "1,", "(1),", "1+", "1-", "1*", "1/", "1…", "(1-)", "(1+)", "(1*)", "(1/)"}

	return wt
End

// UTF_TD_GENERATOR InvalidInputs
static Function TestInvalidInput([str])
	string str

	try
		DirectToFormulaParser(str)
		FAIL()
	catch
		PASS()
	endtry
End

static Function brackets()

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	TestOperationMinMaxHelper(win, "{\"+\":[1,2]}", "(1+2)", 1 + 2)
	TestOperationMinMaxHelper(win, "{\"+\":[{\"+\":[1,2]},{\"+\":[3,4]}]}", "(1+2)+(3+4)", (1 + 2) + (3 + 4))
	TestOperationMinMaxHelper(win, "{\"+\":[{\"+\":[4,3]},{\"+\":[2,1]}]}", "(4+3)+(2+1)", (4 + 3) + (2 + 1))
	TestOperationMinMaxHelper(win, "{\"+\":[{\"+\":[1,{\"+\":[2,3]}]},4]}", "1+(2+3)+4", 1 + (2 + 3) + 4)
	TestOperationMinMaxHelper(win, "{\"+\":[{\"*\":[3,2]},1]}", "(3*2)+1", (3 * 2) + 1)
	TestOperationMinMaxHelper(win, "{\"+\":[1,{\"*\":[2,3]}]}", "1+(2*3)", 1 + (2 * 3))
	TestOperationMinMaxHelper(win, "{\"*\":[{\"+\":[1,2]},3]}", "(1+2)*3", (1 + 2) * 3)
	TestOperationMinMaxHelper(win, "{\"*\":[3,{\"+\":[2,1]}]}", "3*(2+1)", 3 * (2 + 1))
	TestOperationMinMaxHelper(win, "{\"*\":[{\"/\":[2,{\"+\":[3,4]}]},5]}", "2/(3+4)*5", 2 / (3 + 4) * 5)
	TestOperationMinMaxHelper(win, "{\"*\":[{\"*\":[5,{\"+\":[1,2]}]},{\"/\":[3,{\"+\":[4,{\"*\":[5,20]}]}]}]}", "5*(1+2)*3/(4+5*20)", 5 * (1 + 2) * 3 / (4 + 5 * 20))
	TestOperationMinMaxHelper(win, "{\"-\": [{\"-\": [{\"-\": [2,2]},2]},2]}", "(2)-(2)-(2)-(2)", (2) - (2) - (2) - (2))
	TestOperationMinMaxHelper(win, "{\"+\": [{\"+\": [{\"+\": [2,2]},2]},2]}", "(2)+(2)+(2)+(2)", (2) + (2) + (2) + (2))
	TestOperationMinMaxHelper(win, "{\"*\": [{\"*\": [{\"*\": [2,2]},2]},2]}", "(2)*(2)*(2)*(2)", (2) * (2) * (2) * (2))
	TestOperationMinMaxHelper(win, "{\"/\": [{\"/\": [{\"/\": [2,2]},2]},2]}", "(2)/(2)/(2)/(2)", (2) / (2) / (2) / (2))
	TestOperationMinMaxHelper(win, "{\"*\": [-1,2]}", "-(2)", -(2))
	TestOperationMinMaxHelper(win, "{\"-\": [{\"-\": [{\"-\": [2,{\"*\": [-1,2]}]},{\"*\": [-1,2]}]},{\"*\": [-1,2]}]}", "(2)--(2)--(2)--(2)", (2) - -(2) - -(2) - -(2))
	TestOperationMinMaxHelper(win, "{\"/\": [{\"/\": [{\"/\": [2,{\"*\": [-1,2]}]},{\"*\": [-1,2]}]},{\"*\": [-1,2]}]}", "(2)/-(2)/-(2)/-(2)", (2) / -(2) / -(2) / -(2))
	TestOperationMinMaxHelper(win, "{\"-\": [{\"-\": [{\"-\": [{\"*\": [-1,2]},{\"*\": [-1,2]}]},{\"*\": [-1,2]}]},{\"*\": [-1,2]}]}", "-(2)--(2)--(2)--(2)", -(2) - -(2) - -(2) - -(2))
End

static Function array()
	Variable jsonID0, jsonID1

	jsonID0 = JSON_Parse("[1]")
	jsonID1 = DirectToFormulaParser("[1]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[1]]")
	jsonID1 = DirectToFormulaParser("[[1]]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[[1]]]")
	jsonID1 = DirectToFormulaParser("[[[1]]]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[0, [1, 2], 3]]")
	jsonID1 = DirectToFormulaParser("[[0, [1, 2], 3]]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1,2,3]")
	jsonID1 = DirectToFormulaParser("1,2,3")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID1 = DirectToFormulaParser("[1,2,3]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[1,2],3,4]")
	jsonID1 = DirectToFormulaParser("[[1,2],3,4]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1,[2,3],4]")
	jsonID1 = DirectToFormulaParser("[1,[2,3],4]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1,2,[3,4]]")
	jsonID1 = DirectToFormulaParser("[1,2,[3,4]]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[0,1],[1,2],[2,3]]")
	jsonID1 = DirectToFormulaParser("[[0,1],[1,2],[2,3]]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[0,1],[2,3],[4,5]]")
	jsonID1 = DirectToFormulaParser("[[0,1],[2,3],[4,5]]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[0],[2,3],[4,5]]")
	jsonID1 = DirectToFormulaParser("[[0],[2,3],[4,5]]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[0,1],[2],[4,5]]")
	jsonID1 = DirectToFormulaParser("[[0,1],[2],[4,5]]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[0,1],[2,3],[5]]")
	jsonID1 = DirectToFormulaParser("[[0,1],[2,3],[5]]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1,{\"+\":[2,3]}]")
	jsonID1 = DirectToFormulaParser("1,2+3")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[{\"+\":[1,2]},3]")
	jsonID1 = DirectToFormulaParser("1+2,3")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1,{\"/\":[5,{\"+\":[6,7]}]}]")
	jsonID1 = DirectToFormulaParser("1,5/(6+7)")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	// failures that have to SF_ASSERT
	FailFormula("1]")
	FailFormula("[1")
	FailFormula("0[1]")
	FailFormula("[1]2")
	FailFormula("[0,[1]2]")
	FailFormula("[0[1],2]")
End

static Function whiteSpace()
	Variable jsonID0, jsonID1

	jsonID0 = DirectToFormulaParser("1+(2*3)")
	jsonID1 = DirectToFormulaParser(" 1 + (2 * 3) ")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = DirectToFormulaParser("(2+3)")
	jsonID1 = DirectToFormulaParser("(2+3)  ")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = DirectToFormulaParser("1+(2*3)")
	jsonID1 = DirectToFormulaParser("\r1\r+\r(\r2\r*\r3\r)\r")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID1 = DirectToFormulaParser("\t1\t+\t(\t2\t*\t3\t)\t")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID1 = DirectToFormulaParser("\r\t1+\r\t\t(2*3)")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID1 = DirectToFormulaParser("\r\t1+\r\t# this is a \t comment\r\t(2*3)")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID1 = DirectToFormulaParser("\r\t1+\r\t# this is a \t comment\n\t(2*3)#2")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID1 = DirectToFormulaParser("# this is a comment which does not calculate 1+1")
	CHECK_EQUAL_JSON(JSON_PARSE("null"), jsonID1)
End

static Function CheckEqualFormulas(string ref, string formula)

	variable jsonID0, jsonID1

	jsonID0 = JSON_Parse(ref)
	jsonID1 = DirectToFormulaParser(formula)
	CHECK_EQUAL_JSON(jsonID0, jsonID1)
End

static Function TestOperationMinMaxHelper(string win, string jsonRefText, string formula, variable refResult)

	CheckEqualFormulas(jsonRefText, formula)
	WAVE data = GetSingleResult(formula, win)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 1)
	CHECK_EQUAL_VAR(data[0], refResult)
End

// test static Functions with 1..N arguments
static Function TestOperationMinMax()

	string str, wavePath
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	TestOperationMinMaxHelper(win, "{\"min\":[1]}", "min(1)", 1)
	TestOperationMinMaxHelper(win, "{\"min\":[1,2]}", "min(1,2)", min(1, 2))
	TestOperationMinMaxHelper(win, "{\"min\":[1,-1]}", "min(1,-1)", min(1, -1))
	TestOperationMinMaxHelper(win, "{\"max\":[1,2]}", "max(1,2)", max(1, 2))
	TestOperationMinMaxHelper(win, "{\"min\":[1,2,3]}", "min(1,2,3)", min(1, 2, 3))
	TestOperationMinMaxHelper(win, "{\"max\":[1,{\"+\":[2,3]}]}", "max(1,(2+3))", max(1, (2 + 3)))
	TestOperationMinMaxHelper(win, "{\"min\":[{\"-\":[1,2]},3]}", "min((1-2),3)", min((1 - 2), 3))
	TestOperationMinMaxHelper(win, "{\"min\":[{\"max\":[1,2]},3]}", "min(max(1,2),3)", min(max(1, 2), 3))
	TestOperationMinMaxHelper(win, "{\"max\":[1,{\"+\":[2,3]},2]}", "max(1,2+3,2)", max(1, 2 + 3, 2))
	TestOperationMinMaxHelper(win, "{\"max\":[{\"+\":[1,2]},{\"+\":[3,4]},{\"+\":[5,{\"/\":[6,7]}]}]}", "max(1+2,3+4,5+6/7)", max(1 + 2, 3 + 4, 5 + 6 / 7))
	TestOperationMinMaxHelper(win, "{\"max\":[{\"+\":[1,2]},{\"+\":[3,4]},{\"+\":[5,{\"/\":[6,7]}]}]}", "max(1+2,3+4,5+(6/7))", max(1 + 2, 3 + 4, 5 + (6 / 7)))
	TestOperationMinMaxHelper(win, "{\"max\":[{\"max\":[1,{\"/\":[{\"+\":[2,3]},7]},4]},{\"min\":[3,4]}]}", "max(max(1,(2+3)/7,4),min(3,4))", max(max(1, (2 + 3) / 7, 4), min(3, 4)))
	TestOperationMinMaxHelper(win, "{\"+\":[{\"max\":[1,2]},1]}", "max(1,2)+1", max(1, 2) + 1)
	TestOperationMinMaxHelper(win, "{\"+\":[1,{\"max\":[1,2]}]}", "1+max(1,2)", 1 + max(1, 2))
	TestOperationMinMaxHelper(win, "{\"+\":[{\"+\":[1,{\"max\":[1,2]}]},1]}", "1+max(1,2)+1", 1 + max(1, 2) + 1)
	TestOperationMinMaxHelper(win, "{\"-\":[{\"max\":[1,2]},{\"max\":[1,2]}]}", "max(1,2)-max(1,2)", max(1, 2) - max(1, 2))

	// Explicit array in function
	TestOperationMinMaxHelper(win, "{\"min\":[[1]]}", "min([1])", 1)
	// note: TestOperationMinMaxHelper calls GetSingleResult that verifies that [1,2] is evaluated as single argument
	TestOperationMinMaxHelper(win, "{\"min\":[[1,2]]}", "min([1,2])", 1)

	// check limit to 2d waves for min, max, avg
	Make/O/D/N=(2, 2, 2) input = p + 2 * q + 4 * r
	wavePath = GetWavesDataFolder(input, 2)
	str = "min(wave(" + wavePath + "))"
	try
		WAVE data = GetSingleResult(str, win)
		FAIL()
	catch
		PASS()
	endtry

	str = "max(wave(" + wavePath + "))"
	try
		WAVE data = GetSingleResult(str, win)
		FAIL()
	catch
		PASS()
	endtry

	str = "avg(wave(" + wavePath + "))"
	try
		WAVE data = GetSingleResult(str, win)
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestOperationText()

	string str, strRef, wavePath
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	str = "text()"
	try
		WAVE output = GetSingleResult(str, win)
		FAIL()
	catch
		PASS()
	endtry

	str = "text([[5.1234567, 1], [2, 3]])"
	WAVE output = GetSingleResult(str, win)
	Make/FREE/T refData = {{"5.1234567", "2.0000000"},{"1.0000000", "3.0000000"}}
	REQUIRE_EQUAL_WAVES(refData, output, mode = WAVE_DATA)

	KillWaves/Z testData
	// check copy of wave note on text
	Make/O/D/N=1 testData
	strRef = "WaveNoteCopyTest"
	Note/K testData, strRef
	wavePath = GetWavesDataFolder(testData, 2)
	str = "text(wave(" + wavePath + "))"
	WAVE output = GetSingleresult(str, win)
	str = note(output)
	CHECK_EQUAL_STR(strRef, str)
End

static Function TestOperationLog()

	string histo, histoAfter, str, strRef
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	str = "log()"
	WAVE/WAVE outputRef = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(DimSize(outputRef, ROWS), 0)

	histo = GetHistoryNotebookText()
	str = "log(1, 10, 100)"
	WAVE output = GetSingleResult(str, win)
	histoAfter = GetHistoryNotebookText()
	Make/FREE/D refData = {1, 10, 100}
	histo = ReplaceString(histo, histoAfter, "")
	REQUIRE_EQUAL_WAVES(refData, output, mode = WAVE_DATA)
	strRef = "  1\r"
	REQUIRE_EQUAL_STR(strRef, histo)

	histo = GetHistoryNotebookText()
	str = "log(a, bb, ccc)"
	WAVE output = GetSingleResult(str, win)
	histoAfter = GetHistoryNotebookText()
	Make/FREE/T refDataT = {"a", "bb", "ccc"}
	histo = ReplaceString(histo, histoAfter, "")
	REQUIRE_EQUAL_WAVES(refDataT, output, mode = WAVE_DATA)
	strRef = "  a\r"
	REQUIRE_EQUAL_STR(strRef, histo)

	str = "log(1)"
	WAVE output = GetSingleResult(str, win)
	Make/FREE wRef = {1}
	CHECK_EQUAL_WAVES(wRef, output, mode=WAVE_DATA | DIMENSION_SIZES)

	str = "log(1, 2)"
	WAVE output = GetSingleResult(str, win)
	Make/FREE wRef = {1, 2}
	CHECK_EQUAL_WAVES(wRef, output, mode=WAVE_DATA | DIMENSION_SIZES)

	Make/O testData = {1, 2}
	str = "log(wave(" + GetWavesDataFolder(testData, 2)  + "))"
	WAVE output = GetSingleResult(str, win)
	Duplicate/FREE testData, refData
	CHECK_EQUAL_WAVES(refData, output, mode=WAVE_DATA | DIMENSION_SIZES)
End

static Function TestOperationButterworth()

	string str, strref, dataType
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	try
		WAVE output = GetSingleResult("butterworth()", win)
		FAIL()
	catch
		PASS()
	endtry
	try
		WAVE output = GetSingleResult("butterworth(1)", win)
		FAIL()
	catch
		PASS()
	endtry
	try
		WAVE output = GetSingleResult("butterworth(1, 1)", win)
		FAIL()
	catch
		PASS()
	endtry
	try
		WAVE output = GetSingleResult("butterworth(1, 1, 1)", win)
		FAIL()
	catch
		PASS()
	endtry

	try
		WAVE output = GetSingleResult("butterworth(1, 1, 1, 1, 1)", win)
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE/D refData = {0,0.863870777482797,0.235196115045368,0.692708791122301,0.359757805059761,0.602060073208013,0.425726643942363,0.554051807855231}
	str = "butterworth([0,1,0,1,0,1,0,1], 90E3, 100E3, 2)"
	WAVE output = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(refData, output, mode = WAVE_DATA, tol=1E-9)
	WAVE/WAVE dataRef = GetMultipleResults(str, win)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef = SF_DATATYPE_BUTTERWORTH
	CHECK_EQUAL_STR(strRef, dataType)
End

static Function TestOperationChannels()

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	Make/FREE input = {{0}, {NaN}}
	SetDimLabel COLS, 0, channelType, input
	SetDimLabel COLS, 1, channelNumber, input
	WAVE output = GetSingleResult("channels(AD)", win)
	REQUIRE_EQUAL_WAVES(input, output)

	Make/FREE input = {{0}, {0}}
	WAVE output = GetSingleResult("channels(AD0)", win)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{0, 0}, {0, 1}}
	WAVE output = GetSingleResult("channels(AD0,AD1)", win)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{0, 1}, {0, 1}}
	WAVE output = GetSingleResult("channels(AD0,DA1)", win)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{1, 1}, {0, 0}}
	WAVE output = GetSingleResult("channels(DA0,DA0)", win)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{0, 1}, {NaN, NaN}}
	WAVE output = GetSingleResult("channels(AD,DA)", win)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{NaN}, {1}}
	WAVE output = GetSingleResult("channels(1)", win)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{NaN, NaN}, {1, 3}}
	WAVE output = GetSingleResult("channels(1,3)", win)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{0,1,NaN},{1,2,3}}
	WAVE output = GetSingleResult("channels(AD1,DA2,3)", win)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{NaN}, {NaN}}
	WAVE output = GetSingleResult("channels()", win)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	try
		GetSingleResult("channels(unknown)", win)
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestOperationDifferentiateIntegrate()

	variable array
	string str, strRef, dataType, wavePath
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	// differentiate/integrate 1D waves along rows
	str = "derivative([0,1,4,9,16,25,36,49,64,81])"
	WAVE output = GetSingleresult(str, win)
	Make/N=10/U/I/FREE sourcewave = p^2
	Differentiate/EP=0 sourcewave/D=testwave
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)
	WAVE/WAVE dataRef = GetMultipleResults(str, win)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef = SF_DATATYPE_DERIVATIVE
	CHECK_EQUAL_STR(strRef, dataType)

	Make/N=10/U/I/FREE input = p^2
	wfprintf str, "%d,", input
	str = "derivative([" + RemoveEnding(str, ",") + "])"
	WAVE output = GetSingleresult(str, win)
	Make/N=10/FREE testwave = 2 * p
	Deletepoints 9, 1, testwave, output
	Deletepoints 0, 1, testwave, output
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	Make/N=10/U/I/FREE input = 2 * p
	wfprintf str, "%d,", input
	str = "integrate([" + RemoveEnding(str, ",") + "])"
	WAVE output = GetSingleresult(str, win)
	Make/N=10/FREE testwave = p^2
	Deletepoints 9, 1, testwave, output
	Deletepoints 0, 1, testwave, output
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)
	WAVE/WAVE dataRef = GetMultipleResults(str, win)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef = SF_DATATYPE_INTEGRATE
	CHECK_EQUAL_STR(strRef, dataType)

	Make/N=(128)/U/I/FREE input = p
	wfprintf str, "%d,", input
	str = "derivative(integrate([" + RemoveEnding(str, ",") + "]))"
	WAVE output = GetSingleresult(str, win)
	Deletepoints 127, 1, input, output
	Deletepoints   0, 1, input, output
	REQUIRE_EQUAL_WAVES(output, input, mode = WAVE_DATA)

	Make/N=(128)/U/I/FREE input = p^2
	wfprintf str, "%d,", input
	str = "integrate(derivative([" + RemoveEnding(str, ",") + "]))"
	WAVE output = GetSingleresult(str, win)
	output -= 0.5 // expected end point error from first point estimation
	Deletepoints 127, 1, input, output
	Deletepoints   0, 1, input, output
	REQUIRE_EQUAL_WAVES(output, input, mode = WAVE_DATA)

	// differentiate 2d waves along columns
	Make/N=(128,16)/U/I/FREE input = p + q
	array = JSON_New()
	JSON_AddWave(array, "", input)
	str = "derivative(integrate(" + JSON_Dump(array) + "))"
	JSON_Release(array)
	WAVE output = GetSingleresult(str, win)
	Deletepoints/M=(ROWS) 127, 1, input, output
	Deletepoints/M=(ROWS)   0, 1, input, output
	REQUIRE_EQUAL_WAVES(output, input, mode = WAVE_DATA)

	KillWaves/Z testData
	// check copy of wave note on integrate
	Make/O/D/N=1 testData
	strRef = "WaveNoteCopyTest"
	Note/K testData, strRef
	wavePath = GetWavesDataFolder(testData, 2)
	str = "integrate(wave(" + wavePath + "))"
	WAVE output = GetSingleresult(str, win)
	str = note(output)
	CHECK_EQUAL_STR(strRef, str)

	// check copy of wave note on derivative
	Make/O/D/N=2 testData
	strRef = "WaveNoteCopyTest"
	Note/K testData, strRef
	wavePath = GetWavesDataFolder(testData, 2)
	str = "derivative(wave(" + wavePath + "))"
	WAVE output = GetSingleresult(str, win)
	str = note(output)
	CHECK_EQUAL_STR(strRef, str)
End

static Function TestOperationArea()

	variable array
	string str, strref, dataType
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	// rectangular triangle has area 1/2 * a * b
	// non-zeroed
	str = "area([0,1,2,3,4], 0)"
	WAVE output = GetSingleresult(str, win)
	Make/FREE testwave = {8}
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	// zeroed
	str = "area([0,1,2,3,4], 1)"
	WAVE output = GetSingleresult(str, win)
	Make/FREE testwave = {4}
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	// x scaling is taken into account
	str = "area(setscale([0,1,2,3,4], x, 0, 2, unit), 0)"
	WAVE output = GetSingleresult(str, win)
	Make/FREE testwave = {16}
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	// does operate column wise
	Make/N=(5, 2) input
	input[][0] = p
	input[][1] = p + 1
	array = JSON_New()
	JSON_AddWave(array, "", input)
	str = "area(" + JSON_Dump(array) + ", 0)"
	JSON_Release(array)

	WAVE output = GetSingleresult(str, win)
	// 0th column: see above
	// 1st column: imagine 0...5 and remove 0..1 which gives 12.5 - 0.5
	Make/FREE testwave = {8, 12}
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	// check meta data
	str = "area([0,1,2,3,4], 0)"
	WAVE/WAVE dataRef = GetMultipleResults(str, win)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef = SF_DATATYPE_AREA
	CHECK_EQUAL_STR(strRef, dataType)
End

static Function TestOperationSetscale()

	string wavePath
	variable ref
	string refUnit, unit
	string str, strRef, dataScale
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	str = "setscale([0,1,2,3,4,5,6,7,8,9], x, 0, 2, unit)"
	WAVE wv = GetSingleresult(str, win)
	Make/N=(10) waveX = p
	SetScale x 0, 2, "unit", waveX
	REQUIRE_EQUAL_WAVES(waveX, wv, mode = WAVE_DATA)

	str = "setscale(setscale([range(10),range(10)+1,range(10)+2,range(10)+3,range(10)+4,range(10)+5,range(10)+6,range(10)+7,range(10)+8,range(10)+9], x, 0, 2, unitX), y, 0, 4, unitX)"
	WAVE wv = GetSingleresult(str, win)
	Make/N=(10, 10) waveXY = p + q
	SetScale/P x 0, 2, "unitX", waveXY
	SetScale/P y 0, 4, "unitX", waveXY
	REQUIRE_EQUAL_WAVES(waveXY, wv, mode = WAVE_DATA | WAVE_SCALING | DATA_UNITS)

	Make/O/D/N=(2, 2, 2, 2) input = p + 2 * q + 4 * r + 8 * s
	wavePath = GetWavesDataFolder(input, 2)
	refUnit = "unit"
	str = "setscale(wave(" + wavePath + "), z, 0, 2, " + refUnit + ")"
	WAVE data = GetSingleresult(str, win)
	ref = DimDelta(data, LAYERS)
	REQUIRE_EQUAL_VAR(ref, 2)
	unit = WaveUnits(data, LAYERS)
	REQUIRE_EQUAL_STR(refUnit, unit)

	Make/O/D/N=(2, 2, 2, 2) input = p + 2 * q + 4 * r + 8 * s
	wavePath = GetWavesDataFolder(input, 2)
	refUnit = "unit"
	str = "setscale(wave(" + wavePath + "), t, 0, 2, " + refUnit + ")"
	WAVE data = GetSingleresult(str, win)
	ref = DimDelta(data, CHUNKS)
	REQUIRE_EQUAL_VAR(ref, 2)
	unit = WaveUnits(data, CHUNKS)
	REQUIRE_EQUAL_STR(refUnit, unit)

	Make/O/D/N=0 input
	wavePath = GetWavesDataFolder(input, 2)
	refUnit = "unit"
	str = "setscale(wave(" + wavePath + "), d, 2, 0, " + refUnit + ")"
	WAVE data = GetSingleresult(str, win)
	unit = WaveUnits(data, -1)
	REQUIRE_EQUAL_STR(refUnit, unit)
	strRef = "1,2,0"
	dataScale = StringByKey("FULLSCALE", WaveInfo(data, 0))
	REQUIRE_EQUAL_STR(strRef, dataScale)
End

static Function TestOperationRange()

	variable jsonID0, jsonID1

	string str, strRef, dataType
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	jsonID0 = DirectToFormulaParser("1…10")
	jsonID1 = JSON_Parse("{\"…\":[1,10]}")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	str = "1…10"
	WAVE output = GetSingleresult(str, win)
	Make/N=9/U/I/FREE testwave = 1 + p
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	str = "range(1,10)"
	WAVE output = GetSingleresult(str, win)
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	str = "range(10)"
	WAVE output = GetSingleresult(str, win)
	Make/N=10/U/I/FREE testwave = p
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	str = "range(1,10,2)"
	WAVE output = GetSingleresult(str, win)
	Make/N=5/U/I/FREE testwave = 1 + p * 2
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	str = "1.5…10.5"
	WAVE output = GetSingleresult(str, win)
	Make/N=9/FREE floatwave = 1.5 + p
	REQUIRE_EQUAL_WAVES(output, floatwave, mode = WAVE_DATA)

	// check meta data
	str = "range(1,10)"
	WAVE/WAVE dataRef = GetMultipleResults(str, win)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef = SF_DATATYPE_RANGE
	CHECK_EQUAL_STR(strRef, dataType)
End

static Function TestOperationFindLevel()

	string str, strRef, dataType
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	// requires at least two arguments
	try
		str = "findlevel()"
		WAVE output = GetSingleresult(str, win)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "findlevel([1])"
		WAVE output = GetSingleresult(str, win)
		FAIL()
	catch
		PASS()
	endtry

	// but no more than three
	try
		str = "findlevel([1], 2, 3, 4)"
		WAVE output = GetSingleresult(str, win)
		FAIL()
	catch
		PASS()
	endtry

	// works
	str = "findlevel([10, 20, 30, 20], 25)"
	WAVE output = GetSingleresult(str, win)
	Make/FREE output_ref = {1.5}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// supports rising edge only
	str = "findlevel([10, 20, 30, 20], 25, 1)"
	WAVE output = GetSingleresult(str, win)
	Make/FREE output_ref = {1.5}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// supports falling edge only
	str = "findlevel([10, 20, 30, 20], 25, 2)"
	WAVE output = GetSingleresult(str, win)
	Make/FREE output_ref = {2.5}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// errors out on invalid edge
	try
		str = "findlevel([10, 20, 30, 20], 25, 3)"
		WAVE output = GetSingleresult(str, win)
		FAIL()
	catch
		PASS()
	endtry

	// works with 2D data
	str = "findlevel([[10, 10], [20, 20], [30, 30]], 15)"
	WAVE output = GetSingleresult(str, win)
	Make/FREE output_ref = {0.5, 0.5}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// returns x coordinates and not indizes
	str = "findlevel(setscale([[10, 10], [20, 20], [30, 30]], x, 4, 0.5), 15)"
	WAVE output = GetSingleresult(str, win)
	Make/FREE output_ref = {4.25, 4.25}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// returns NaN if nothing found
	str = "findlevel([10, 20, 30, 20], 100)"
	WAVE output = GetSingleresult(str, win)
	Make/FREE output_ref = {NaN}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// check meta data
	str = "findlevel([10, 20, 30, 20], 25)"
	WAVE/WAVE dataRef = GetMultipleResults(str, win)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef = SF_DATATYPE_FINDLEVEL
	CHECK_EQUAL_STR(strRef, dataType)
End

static Function TestOperationAPFrequency()

	string str, strRef, dataType
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	// requires at least one arguments
	str = "apfrequency()"
	try
		WAVE output = GetSingleResult(str, win)
		FAIL()
	catch
		PASS()
	endtry

	// but no more than three
	str = "apfrequency([1], 0, 3, 4)"
	try
		WAVE output = GetSingleResult(str, win)
		FAIL()
	catch
		PASS()
	endtry

	// requires valid method
	str = "apfrequency([1], 3)"
	try
		WAVE output = GetSingleResult(str, win)
		FAIL()
	catch
		PASS()
	endtry

	// works with full
	str = "apfrequency(setscale([10, 20, 10, 20, 10, 20], x, 0, 5, ms), 0, 15)"
	WAVE output = GetSingleResult(str, win)
	Make/FREE/D output_ref = {100}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with apcount
	str = "apfrequency(setscale([10, 20, 10, 20, 10, 20], x, 0, 5, ms), 2, 15)"
	WAVE output = GetSingleResult(str, win)
	Make/FREE/D output_ref = {3}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with 2D data and instantaneous
	str = "apfrequency(setscale([[10, 5], [20, 40], [10, 5], [20, 30]], x, 0, 5, ms), 0, 15)"
	WAVE output = GetSingleResult(str, win)
	Make/FREE/D output_ref = {100, 100}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with instantaneous
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 1, 15)"
	WAVE output = GetSingleResult(str, win)
	Make/FREE/D output_ref = {57.14285714285714}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with 2D data and instantaneous
	str = "apfrequency(setscale([[10, 5], [20, 40], [10, 5], [20, 30]], x, 0, 5, ms), 1, 15)"
	WAVE output = GetSingleResult(str, win)
	Make/FREE/D output_ref = {100, 94.59459459459457}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// x offset does not play any role
	str = "apfrequency(setscale([[10, 5], [20, 40], [10, 5], [20, 30]], x, 0, 5, ms), 1, 15)"
	WAVE output = GetSingleResult(str, win)
	Make/FREE/D output_ref = {100, 94.59459459459457}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// returns 0 if nothing found for Full
	str = "apfrequency([10, 20, 30, 20], 0, 100)"
	WAVE output = GetSingleResult(str, win)
	Make/FREE/D output_ref = {0}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// returns 0 if nothing found for Instantaneous
	str = "apfrequency([10, 20, 30, 20], 1, 100)"
	WAVE output = GetSingleResult(str, win)
	Make/FREE/D output_ref = {0}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// check meta data
	str = "apfrequency([10, 20, 30, 20], 1, 100)"
	WAVE/WAVE dataRef = GetMultipleResults(str, win)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef = SF_DATATYPE_APFREQUENCY
	CHECK_EQUAL_STR(strRef, dataType)
End

static Function TestOperationWave()

	string str
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	KillWaves/Z wave0
	Make/O/N=(10) wave0 = p

	str = "wave(wave0)"
	WAVE wave1 = GetSingleResult(str, win)
	str = "range(0,10)"
	WAVE wave2 = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(wave0, wave2, mode = WAVE_DATA)
	REQUIRE_EQUAL_WAVES(wave1, wave2, mode = WAVE_DATA)

	str = "wave(does_not_exist)"
	WAVE/Z wave1 = GetSingleResult(str, win)
	CHECK(!WaveExists(wave1))
End

static Function/WAVE FuncCommandGetter()

	variable i, numEntries
	string name

	// Operation: Result 1D: Result 2D
	Make/T/FREE data = {                                                                                                                                                                                                \
						"min:0:0,1",                                                                                                                                                                                                  \
						"max:4:4,5",                                                                                                                                                                                                  \
						"avg:2:2,3",                                                                                                                                                                                                  \
						"mean:2:2,3",                                                                                                                                                                                                 \
						"rms:2.449489742783178:2.449489742783178,3.3166247903554",                                                                                                                                                    \
						"variance:2.5:2.5,2.5",                                                                                                                                                                                       \
						"stdev:1.58113883008419:1.58113883008419,1.58113883008419",                                                                                                                                                   \
						"derivative:1,1,1,1,1:{1,1,1,1,1},{1,1,1,1,1}",                                                                                                                                                               \
						"integrate:0,0.5,2,4.5,8:{0,0.5,2,4.5,8},{0,1.5,4,7.5,12}",                                                                                                                                                   \
						"log10:-inf,0,0.301029995663981,0.477121254719662,0.602059991327962:{-inf,0,0.301029995663981,0.477121254719662,0.602059991327962},{0,0.301029995663981,0.477121254719662,0.602059991327962,0.698970004336019}" \
					   }

	numEntries = DimSize(data, ROWS)
	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(0, data[i], ":")
		SetDimLabel ROWS, i, $name, data
	endfor

	return data
End

// UTF_TD_GENERATOR FuncCommandGetter
static Function TestVariousFunctions([str])
	string str

	string func, oneDResult, twoDResult
	variable jsonIDOneD, jsonIDTwoD
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	func = StringFromList(0, str, ":")
	oneDResult = StringFromList(1, str, ":")
	twoDResult = StringFromList(2, str, ":")

	KillWaves/Z oneD, twoD
	Make/D/N=5 oneD = p
	Make/D/N=(5, 2) twoD = p + q

	jsonIDOneD = JSON_NEW()
	JSON_AddWave(jsonIDOneD, "", oneD)
	jsonIDTwoD = JSON_NEW()
	JSON_AddWave(jsonIDTwoD, "", twoD)

	// 1D
	str = func + "(" + JSON_Dump(jsonIDOneD) + ")"
	WAVE output1D = GetSingleResult(str, win)
	Execute "Make/O output1D_mo = {" + oneDResult + "}"
	WAVE output1D_mo

	CHECK_EQUAL_WAVES(output1D, output1D_mo, mode = WAVE_DATA, tol = 1e-8)

	// 2D
	str = func + "(" + JSON_Dump(jsonIDTwoD) + ")"
	WAVE output2D = GetSingleResult(str, win)
	Execute "Make/O output2D_mo = {" + twoDResult + "}"
	WAVE output2D_mo

	CHECK_EQUAL_WAVES(output2D, output2D_mo, mode = WAVE_DATA, tol = 1e-8)
End

static Function TestPlotting()
	String traces

	Variable minimum, maximum, i, pos, offset
	string win, gInfo, tmpStr, refStr
	DFREF dfr

	string sweepBrowser = CreateFakeSweepBrowser_IGNORE()
	String winBase = BSP_GetFormulaGraph(sweepBrowser)

	String strArray2D = "[range(10), range(10,20), range(10), range(10,20)]"
	String strArray1D = "range(4)"
	String strScale1D = "time(setscale(range(4),x,1,0.1))"
	String strArray0D = "1"
	String strCombined = "[1, 2] vs [3, 4]\rand\r[5, 6] vs [7, 8]\rand\r[9, 10]\rand\r"
	String strCombinedPartial = "[1, 2] vs [1, 2]\rand\r[1?=*, 2] vs [1, 2]"
	string strWith = "[1, 2]\rwith\r[2, 3] vs [3, 4]\rand\r[5, 6]\rwith\r[2, 3]\rwith\r[4, 5] vs [7, 8]\rand\r[9, 10]\rwith\r\rand\r"

	// Reference data waves must be moved out of the working DF for the further tests as
	// calling the FormulaPlotter later kills the working DF
	WAVE globalarray2D = GetSingleresult(strArray2D, sweepBrowser)
	Duplicate/FREE globalarray2D, array2D
	WAVE globalarray1D = GetSingleresult(strArray1D, sweepBrowser)
	Duplicate/FREE globalarray1D, array1D
	WAVE globalarray0D = GetSingleresult(strArray0D, sweepBrowser)
	Duplicate/FREE globalarray0D, array0D
	WAVE globalscale1D = GetSingleresult(strScale1D, sweepBrowser)
	Duplicate/FREE globalscale1D, scale1D

	win = winBase + "_#Graph" + "0"
	dfr = GetDataFolderDFR()

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strArray2D)
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)
	traces = TraceNameList(win, ";", 0x1)
	REQUIRE_EQUAL_VAR(ItemsInList(traces), DimSize(array2D, COLS))
	WAVE wvY = TraceNameToWaveRef(win, StringFromList(0, traces))
	REQUIRE_EQUAL_WAVES(array2D, wvY)

	// one to many
	MIES_SF#SF_FormulaPlotter(sweepBrowser, strArray1D + " vs " + strArray2D); DoUpdate
	traces = TraceNameList(win, ";", 0x1)
	REQUIRE_EQUAL_VAR(ItemsInList(traces), DimSize(array2D, COLS))
	WAVE wvX = XWaveRefFromTrace(win, StringFromList(0, traces))
	REQUIRE_EQUAL_WAVES(wvX, array2D)
	WAVE wvY = TraceNameToWaveRef(win, StringFromList(0, traces))
	Redimension/N=(-1, 0) wvY
	REQUIRE_EQUAL_WAVES(wvY, array1D)
	[minimum, maximum] = GetAxisRange(win, "bottom", mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array2D))
	REQUIRE_EQUAL_VAR(maximum, WaveMax(array2D))
	[minimum, maximum] = GetAxisRange(win, "left", mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array1D))
	REQUIRE_EQUAL_VAR(maximum, WaveMax(array1D))
	MIES_SF#SF_FormulaPlotter(sweepBrowser, strScale1D + " vs " + strArray2D); DoUpdate
	[minimum, maximum] = GetAxisRange(win, "left", mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(scale1D))
	REQUIRE_CLOSE_VAR(maximum, WaveMax(scale1D))

	// many to one
	MIES_SF#SF_FormulaPlotter(sweepBrowser, strArray2D + " vs " + strArray1D); DoUpdate
	traces = TraceNameList(win, ";", 0x1)
	REQUIRE_EQUAL_VAR(ItemsInList(traces), DimSize(array2D, COLS))
	WAVE wvY = TraceNameToWaveRef(win, StringFromList(0, traces))
	REQUIRE_EQUAL_WAVES(wvY, array2D)
	WAVE wvX = XWaveRefFromTrace(win, StringFromList(0, traces))
	Redimension/N=(-1, 0) wvX
	REQUIRE_EQUAL_WAVES(wvX, array1D)
	[minimum, maximum] = GetAxisRange(win, "bottom", mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array1D))
	REQUIRE_EQUAL_VAR(maximum, WaveMax(array1D))
	[minimum, maximum] = GetAxisRange(win, "left", mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array2D))
	REQUIRE_EQUAL_VAR(maximum, WaveMax(array2D))

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strArray2D + " vs range(3)"); DoUpdate
	traces = TraceNameList(win, ";", 0x1)
	REQUIRE_EQUAL_VAR(ItemsInList(traces), DimSize(array2D, COLS))
	[minimum, maximum] = GetAxisRange(win, "bottom", mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(maximum, array1D[2])

	MIES_SF#SF_FormulaPlotter(sweepBrowser, "time(setscale(range(4),x,1,0.1)) vs [range(10), range(10,20), range(10), range(10,20)]"); DoUpdate
	[minimum, maximum] = GetAxisRange(win, "left", mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(scale1D))
	REQUIRE_CLOSE_VAR(maximum, WaveMax(scale1D))

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strArray1D + " vs " + strArray1D); DoUpdate
	traces = TraceNameList(win, ";", 0x1)
	REQUIRE_EQUAL_VAR(ItemsInList(traces), 1)
	[minimum, maximum] = GetAxisRange(win, "left", mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array1D))
	REQUIRE_CLOSE_VAR(maximum, WaveMax(array1D))
	[minimum, maximum] = GetAxisRange(win, "bottom", mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array1D))
	REQUIRE_CLOSE_VAR(maximum, WaveMax(array1D))

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strArray2D + " vs " + strArray2D); DoUpdate
	traces = TraceNameList(win, ";", 0x1)
	REQUIRE_EQUAL_VAR(ItemsInList(traces), DimSize(array2D, COLS))

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strArray1D + " vs " + strArray1D); DoUpdate
	REQUIRE_EQUAL_VAR(ItemsInList(TraceNameList(win, ";", 0x1)), 1)

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strArray1D + " vs " + strArray0D); DoUpdate
	REQUIRE_EQUAL_VAR(ItemsInList(TraceNameList(win, ";", 0x1)), DimSize(array1D, ROWS))

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strArray0D + " vs " + strArray1D); DoUpdate
	REQUIRE_EQUAL_VAR(ItemsInList(TraceNameList(win, ";", 0x1)), DimSize(array1D, ROWS))

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strArray0D + " vs " + strArray0D); DoUpdate
	REQUIRE_EQUAL_VAR(ItemsInList(TraceNameList(win, ";", 0x1)), DimSize(array0D, ROWS))

	// plotting of unaligned data
	MIES_SF#SF_FormulaPlotter(sweepBrowser, "range(10) vs range(5)"); DoUpdate
	REQUIRE_EQUAL_VAR(ItemsInList(TraceNameList(win, ";", 0x1)), floor(10 / 5))
	MIES_SF#SF_FormulaPlotter(sweepBrowser, "range(5) vs range(10)"); DoUpdate
	REQUIRE_EQUAL_VAR(ItemsInList(TraceNameList(win, ";", 0x1)), floor(10 / 5))
	MIES_SF#SF_FormulaPlotter(sweepBrowser, "range(3) vs range(90)"); DoUpdate
	REQUIRE_EQUAL_VAR(ItemsInList(TraceNameList(win, ";", 0x1)), floor(90 / 3))
	MIES_SF#SF_FormulaPlotter(sweepBrowser, "range(3) vs range(7)"); DoUpdate
	REQUIRE_EQUAL_VAR(ItemsInList(TraceNameList(win, ";", 0x1)), floor(7 / 3))

	MIES_SF#SF_FormulaPlotter(sweepBrowser, "[0...3],[1...4] vs 1"); DoUpdate
	WAVE wvX = WaveRefIndexed(win, 0, 2)
	CHECK_EQUAL_VAR(DimSize(wvX, ROWS), 2)

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strCombined, dmMode = SF_DM_NORMAL); DoUpdate
	win = winBase + "_0"
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)
	KillWindow/Z $win
	win = winBase + "_1"
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)
	KillWindow/Z $win
	win = winBase + "_2"
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)
	KillWindow/Z $win

	WAVE wvY0 = GetSweepFormulaY(dfr, 0)
	WAVE wvX0 = GetSweepFormulaX(dfr, 0)
	WAVE wvY1 = GetSweepFormulaY(dfr, 1)
	WAVE wvX1 = GetSweepFormulaX(dfr, 1)
	Make/FREE/D wvY0ref = {{1, 2}}
	CHECK_EQUAL_WAVES(wvY0, wvY0ref)
	Make/FREE/D wvX0ref = {{3, 4}}
	CHECK_EQUAL_WAVES(wvX0, wvX0ref)
	Make/FREE/D wvY1ref = {{5, 6}}
	CHECK_EQUAL_WAVES(wvY1, wvY1ref)
	Make/FREE/D wvX1ref = {{7, 8}}
	CHECK_EQUAL_WAVES(wvX1, wvX1ref)

	try
		MIES_SF#SF_FormulaPlotter(sweepBrowser, strCombinedPartial, dmMode = SF_DM_NORMAL)
		FAIL()
	catch
		PASS()
	endtry
	DoUpdate
	win = winBase + "_0"
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)
	win = winBase + "_1"
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)

	offset = 0.1 // workaround for IUTF issue https://github.com/byte-physics/igor-unit-testing-framework/issues/216
	MIES_SF#SF_FormulaPlotter(sweepBrowser, strCombined, dmMode = SF_DM_SUBWINDOWS); DoUpdate
	win = winBase + "_"
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)
	for(i = 0; i < 4; i += 1)
		gInfo = GuideInfo(win, "HOR" + num2istr(i))
		CHECK_NON_EMPTY_STR(gInfo)
		pos = NumberByKey("RELPOSITION", gInfo)
		CHECK_CLOSE_VAR(pos + offset, i / 3 + offset, tol = 0.01)
		pos = NumberByKey("HORIZONTAL", gInfo)
		CHECK_EQUAL_VAR(pos, 1)
		tmpStr = StringByKey("GUIDE1", gInfo)
		refStr = "FT"
		CHECK_EQUAL_STR(tmpStr, refStr)
		tmpStr = StringByKey("GUIDE2", gInfo)
		refStr = "FB"
		CHECK_EQUAL_STR(tmpStr, refStr)
	endfor
	win = winBase + "_#Graph" + "0"
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)
	win = winBase + "_#Graph" + "1"
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)
	win = winBase + "_#Graph" + "2"
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)

	try
		MIES_SF#SF_FormulaPlotter(sweepBrowser, "[abc,def]")
		FAIL()
	catch
		PASS()
	endtry

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strWith)
	win = winBase + "_#Graph" + "0"
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)
	WAVE wvWin0Y0 = WaveRefIndexed(win, 0, 1)
	WAVE wvWin0Y1 = WaveRefIndexed(win, 1, 1)
	WAVE wvWin0X0 = WaveRefIndexed(win, 0, 2)
	WAVE wvWin0X1 = WaveRefIndexed(win, 1, 2)
	win = winBase + "_#Graph" + "1"
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)
	WAVE wvWin1Y0 = WaveRefIndexed(win, 0, 1)
	WAVE wvWin1Y1 = WaveRefIndexed(win, 1, 1)
	WAVE wvWin1Y2 = WaveRefIndexed(win, 2, 1)
	WAVE wvWin1X0 = WaveRefIndexed(win, 0, 2)
	WAVE wvWin1X1 = WaveRefIndexed(win, 1, 2)
	WAVE wvWin1X2 = WaveRefIndexed(win, 2, 2)
	win = winBase + "_#Graph" + "2"
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)
	WAVE wvWin2Y0 = WaveRefIndexed(win, 0, 1)
	WAVE wvY0 = GetSweepFormulaY(dfr, 0)
	WAVE wvX0 = GetSweepFormulaX(dfr, 0)
	WAVE wvY1 = GetSweepFormulaY(dfr, 1)
	WAVE wvX1 = GetSweepFormulaX(dfr, 1)
	WAVE wvY2 = GetSweepFormulaY(dfr, 2)
	WAVE wvX2 = GetSweepFormulaX(dfr, 2)
	WAVE wvY3 = GetSweepFormulaY(dfr, 3)
	WAVE wvX3 = GetSweepFormulaX(dfr, 3)
	WAVE wvY4 = GetSweepFormulaY(dfr, 4)
	WAVE wvX4 = GetSweepFormulaX(dfr, 4)
	WAVE wvY5 = GetSweepFormulaY(dfr, 5)
	Make/FREE/D wvXref = {{3, 4}}
	CHECK_EQUAL_WAVES(wvX0, wvXref)
	CHECK_EQUAL_WAVES(wvX1, wvXref)
	CHECK_EQUAL_WAVES(wvWin0X0, wvX0)
	CHECK_EQUAL_WAVES(wvWin0X1, wvX1)
	Make/FREE/D wvXref = {{7, 8}}
	CHECK_EQUAL_WAVES(wvX2, wvXref)
	CHECK_EQUAL_WAVES(wvX3, wvXref)
	CHECK_EQUAL_WAVES(wvX4, wvXref)
	CHECK_EQUAL_WAVES(wvWin1X0, wvX2)
	CHECK_EQUAL_WAVES(wvWin1X1, wvX3)
	CHECK_EQUAL_WAVES(wvWin1X2, wvX4)
	Make/FREE/D wvYref = {{1, 2}}
	CHECK_EQUAL_WAVES(wvY0, wvYref)
	CHECK_EQUAL_WAVES(wvWin0Y0, wvY0)
	Make/FREE/D wvYref = {{2, 3}}
	CHECK_EQUAL_WAVES(wvY1, wvYref)
	CHECK_EQUAL_WAVES(wvWin0Y1, wvY1)
	Make/FREE/D wvYref = {{5, 6}}
	CHECK_EQUAL_WAVES(wvY2, wvYref)
	CHECK_EQUAL_WAVES(wvWin1Y0, wvY2)
	Make/FREE/D wvYref = {{2, 3}}
	CHECK_EQUAL_WAVES(wvY3, wvYref)
	CHECK_EQUAL_WAVES(wvWin1Y1, wvY3)
	Make/FREE/D wvYref = {{4, 5}}
	CHECK_EQUAL_WAVES(wvY4, wvYref)
	CHECK_EQUAL_WAVES(wvWin1Y2, wvY4)
	Make/FREE/D wvYref = {{9, 10}}
	CHECK_EQUAL_WAVES(wvY5, wvYref)
	CHECK_EQUAL_WAVES(wvWin2Y0, wvY5)
End

static Function TestOperationSelect()

	variable numChannels, sweepNo
	string str, chanList

	variable numSweeps = 2
	variable dataSize = 10
	variable i, j, clampMode
	string trace, name
	string channelTypeList = "DA;AD;DA;AD;"
	string channelNumberList = "2;6;3;7;"

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	sweepNo = 0

	CreateFakeSweepData(device, sweepNo=sweepNo)
	MIES_DB#DB_SplitSweepsIfReq(win, sweepNo)
	CreateFakeSweepData(device, sweepNo=sweepNo + 1)
	MIES_DB#DB_SplitSweepsIfReq(win, sweepNo + 1)

	numChannels = 4 // from LBN creation in CreateFakeSweepData->PrepareLBN_IGNORE -> DA2, AD6, DA3, AD7
	Make/FREE/N=0 sweepTemplate
	WAVE sweepRef = FakeSweepDataGeneratorDefault(sweepTemplate, numChannels)

	Make/FREE/N=(4, 3) dataRef
	dataRef[][0] = sweepNo
	dataRef[0, 1][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[2, 3][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7, 2, 3} // AD6, AD7, DA2, DA3
	str = "select(channels(),[" + num2istr(sweepNo) + "],all)"
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(2, 3) dataRef
	dataRef[][0] = sweepNo
	dataRef[0][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[1][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 2} // AD6, DA2
	str = "select(channels(2, 6),[" + num2istr(sweepNo) + "],all)"
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(2, 3) dataRef
	dataRef[][0] = sweepNo
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7} // AD6, AD7
	str = "select(channels(AD),[" + num2istr(sweepNo) + "],all)"
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	// non-existing sweeps are ignored
	str = "select(channels(AD),[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 2) + "],all)"
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(4, 3) dataRef
	dataRef[][0] = {sweepNo, sweepNo, sweepNo + 1, sweepNo + 1} // sweep 0, 1 with 2 AD channels each
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7, 6, 7} // AD6, AD7, AD6, AD7
	str = "select(channels(AD),[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "],all)"
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(2, 3) dataRef
	dataRef[][0] = {sweepNo, sweepNo + 1}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 6} // AD6, AD6
	str = "select(channels(AD6),[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "],all)"
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(6, 3) dataRef
	dataRef[][0] = {sweepNo, sweepNo, sweepNo, sweepNo + 1, sweepNo + 1, sweepNo + 1}
	chanList = "AD;DA;DA;AD;DA;DA;"
	dataRef[][1] = WhichListItem(StringFromList(p, chanList), XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 2, 3, 6, 2, 3} // AD6, DA2, DA3, AD6, DA2, DA3
	str = "select(channels(AD6, DA),[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "],all)"
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	// No existing sweeps
	str = "select(channels(AD6, DA),[" + num2istr(sweepNo + 2) + "],all)"
	WAVE/Z data = GetSingleResult(str, win)
	REQUIRE(!WaveExists(data))

	// No existing channels
	str = "select(channels(AD0),[" + num2istr(sweepNo) + "],all)"
	WAVE/Z data = GetSingleResult(str, win)
	REQUIRE(!WaveExists(data))

	// Invalid channels
	try
		str = "select([0, 6],[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "],all)"
		WAVE data = GetSingleResult(str, win)
		FAIL()
	catch
		PASS()
	endtry

	// Setup graph with equivalent data for displayed parameter
	TUD_Clear(win)

	Make/FREE/N=(dataSize, numSweeps, numChannels) input = q + p^r // + gnoise(1)
	for(i = 0; i < numSweeps; i += 1)
		sweepNo = i
		for(j = 0; j < numChannels; j += 1)
			name = UniqueName("data", 1, 0)
			trace = "trace_" + name
			clampMode = mod(sweepNo, 2) ? V_CLAMP_MODE : I_CLAMP_MODE
			Extract input, $name, q == i && r == j
			WAVE wv = $name
			AppendToGraph/W=$win wv/TN=$trace
			TUD_SetUserDataFromWaves(win, trace, {"experiment", "fullPath", "traceType", "occurence", "channelType", "channelNumber", "sweepNumber", "clampMode"},         \
									 {"blah", GetWavesDataFolder(wv, 2), "Sweep", "0", StringFromList(j, channelTypeList), StringFromList(j, channelNumberList), num2istr(sweepNo), num2istr(clampMode)})
		endfor
	endfor

	sweepNo = 0
	Make/FREE/N=(8, 3) dataRef
	dataRef[0, 3][0] = sweepNo
	dataRef[4, 7][0] = sweepNo + 1
	dataRef[0, 1][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[2, 3][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[4, 5][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[6, 7][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7, 2, 3, 6, 7, 2, 3}
	str = "select()"
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(4, 3) dataRef
	dataRef[][0] = {sweepNo, sweepNo, sweepNo + 1, sweepNo + 1}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7, 6, 7}
	str = "select(channels(AD),sweeps(),displayed)"
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "select(channels(AD),sweeps())"
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(2, 3) dataRef
	dataRef[][0] = {sweepNo, sweepNo + 1}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 6}
	str = "select(channels(AD6),sweeps(),displayed,all)"
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(1, 3) dataRef
	dataRef[][0] = {sweepNo}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6}
	str = "select(channels(AD6),sweeps(),displayed, ic)"
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(1, 3) dataRef
	dataRef[][0] = {sweepNo + 1}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6}
	str = "select(channels(AD6),sweeps(),displayed, vc)"
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "select(channels(AD6),sweeps(),displayed, izero)"
	WAVE/Z data = GetSingleResult(str, win)
	CHECK(!WaveExists(data))

	dataRef[][0] = {sweepNo, sweepNo, sweepNo + 1, sweepNo + 1}
	dataRef[][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[][2] = {2, 3, 2, 3}
	str = "select(channels(DA),sweeps())"
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(6, 3) dataRef
	dataRef[][0] = {sweepNo, sweepNo, sweepNo, sweepNo + 1, sweepNo + 1, sweepNo + 1}
	chanList = "AD;AD;DA;AD;AD;DA;"
	dataRef[][1] = WhichListItem(StringFromList(p, chanList), XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7, 2, 6, 7, 2}
	str = "select(channels(DA2, AD),sweeps())" // note: channels are sorted AD, DA...
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	// No existing sweeps
	str = "select(channels(AD6, DA),[" + num2istr(sweepNo + 2) + "])"
	WAVE/Z data = GetSingleResult(str, win)
	REQUIRE(!WaveExists(data))

	// No existing channels
	str = "select(channels(AD0),[" + num2istr(sweepNo) + "])"
	WAVE/Z data = GetSingleResult(str, win)
	REQUIRE(!WaveExists(data))

	// Invalid channels
	try
		str = "select([0, 6],[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "])"
		WAVE data = GetSingleResult(str, win)
		FAIL()
	catch
		PASS()
	endtry

	str = "select(1)"
	try
		WAVE data = GetSingleResult(str, win)
		FAIL()
	catch
		PASS()
	endtry

	str = "select(channels(AD), sweeps(), 1)"
	try
		WAVE data = GetSingleResult(str, win)
		FAIL()
	catch
		PASS()
	endtry

	str = "select(channels(AD), sweeps(), all, 1)"
	try
		WAVE data = GetSingleResult(str, win)
		FAIL()
	catch
		PASS()
	endtry

End

static Function CheckSweepsFromData(WAVE/WAVE dataWref, WAVE sweepRef, variable numResults, WAVE chanIndex[, WAVE ranges])

	variable i

	REQUIRE_EQUAL_VAR(DimSize(dataWref, ROWS), numResults)
	for(i = 0; i < numResults; i += 1)
		WAVE sweepData = dataWref[i]
		Duplicate/FREE/RMD=[][chanIndex[i]] sweepRef, sweepDataRef
		Redimension/N=(-1) sweepDataRef
		if(!ParamIsDefault(ranges))
			Duplicate/FREE/RMD=[ranges[i][0], ranges[i][1]] sweepDataRef, sweepDataRanged
			WAVE sweepDataRef = sweepDataRanged
		endif

		REQUIRE_EQUAL_WAVES(sweepDataRef, sweepData, mode = WAVE_DATA)
	endfor
End

static Function CheckSweepsMetaData(WAVE/WAVE dataWref, WAVE channelTypes, WAVE channelNumbers, WAVE sweepNumbers, string dataTypeRef)

	variable i, numResults
	string dataType
	variable channelNumber, channelType, sweepNo

	dataType = JWN_GetStringFromWaveNote(dataWref, SF_META_DATATYPE)
	CHECK_EQUAL_STR(dataTypeRef, dataType)
	numResults = DimSize(dataWref, ROWS)
	for(i = 0; i < numResults; i += 1)
		WAVE sweepData = dataWref[i]
		sweepNo = JWN_GetNumberFromWaveNote(sweepData, SF_META_SWEEPNO)
		channelNumber = JWN_GetNumberFromWaveNote(sweepData, SF_META_CHANNELNUMBER)
		channelType = JWN_GetNumberFromWaveNote(sweepData, SF_META_CHANNELTYPE)
		CHECK_EQUAL_VAR(sweepNumbers[i], sweepNo)
		CHECK_EQUAL_VAR(channelTypes[i], channelType)
		CHECK_EQUAL_VAR(channelNumbers[i], channelNumber)
	endfor
End

static Function TestOperationData()

	variable i, j, numChannels, sweepNo, sweepCnt, numResultsRef
	string str, epochStr, name, trace
	string win, device
	variable mode = DATA_ACQUISITION_MODE
	variable numSweeps = 2
	variable dataSize = 10
	variable rangeStart0 = 3
	variable rangeEnd0 = 6
	variable rangeStart1 = 1
	variable rangeEnd1 = 8
	string channelTypeList = "DA;AD;DA;AD;"
	string channelNumberList = "2;6;3;7;"
	Make/FREE/T/N=(1, 1) epochKeys = EPOCHS_ENTRY_KEY

	[win, device] = CreateFakeDataBrowserWindow()

	sweepNo = 0

	CreateFakeSweepData(device, sweepNo=sweepNo)
	CreateFakeSweepData(device, sweepNo=sweepNo + 1)

	epochStr = "0.00" + num2istr(rangeStart0) + ",0.00" + num2istr(rangeEnd0) + ",ShortName=TestEpoch,0"
	Make/FREE/T/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) epochInfo = epochStr
	ED_AddEntriesToLabnotebook(epochInfo, epochKeys, sweepNo, device, mode)
	epochStr = "0.00" + num2istr(rangeStart1) + ",0.00" + num2istr(rangeEnd1) + ",ShortName=TestEpoch,0"
	Make/FREE/T/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) epochInfo = epochStr
	ED_AddEntriesToLabnotebook(epochInfo, epochKeys, sweepNo + 1, device, mode)

	numChannels = 4 // from LBN creation in CreateFakeSweepData->PrepareLBN_IGNORE -> DA2, AD6, DA3, AD7
	Make/FREE/N=0 sweepTemplate
	WAVE sweepRef = FakeSweepDataGeneratorDefault(sweepTemplate, numChannels)

	sweepCnt = 1
	str = "data(cursors(A,B),select(channels(AD),[" + num2istr(sweepNo) + "],all))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	numResultsRef = sweepCnt * numChannels / 2
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3})
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {0, 0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str = "data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	numResultsRef = sweepCnt * 1
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1})
	CheckSweepsMetaData(dataWref, {0}, {6}, {0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str = "data(TestEpoch,select(channels(AD),[" + num2istr(sweepNo) + "],all))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	numResultsRef = sweepCnt * numChannels / 2
	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[][0] = rangeStart0
	ranges[][1] = rangeEnd0
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3}, ranges=ranges)
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {0, 0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str = "data(TestEpoch,select(channels(AD),[" + num2istr(sweepNo + 1) + "],all))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	numResultsRef = sweepCnt * numChannels / 2
	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[][0] = rangeStart1
	ranges[][1] = rangeEnd1
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3}, ranges=ranges)
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {1, 1}, SF_DATATYPE_SWEEP)

	sweepCnt = 2
	str = "data(TestEpoch,select(channels(AD),[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "],all))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	numResultsRef = sweepCnt * numChannels / 2
	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[][0] = p >= 2 ? rangeStart1 : rangeStart0
	ranges[][1] = p >= 2 ? rangeEnd1 : rangeEnd0
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3, 1, 3}, ranges=ranges)
	CheckSweepsMetaData(dataWref, {0, 0, 0, 0}, {6, 7, 6, 7}, {0, 0, 1, 1}, SF_DATATYPE_SWEEP)

	// FAIL Tests
	// non existing channel
	str = "data(TestEpoch,select(channels(AD4),[" + num2istr(sweepNo) + "],all))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	REQUIRE_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// non existing sweep
	str = "data(TestEpoch,select(channels(AD4),[" + num2istr(sweepNo + 2) + "],all))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	REQUIRE_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// non existing epoch
	str = "data(WhatEpochIsThis,select(channels(AD4),[" + num2istr(sweepNo) + "],all))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	REQUIRE_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// range begin
	str = "data([12, 10],select(channels(AD),[" + num2istr(sweepNo) + "],all))"
	try
		WAVE/WAVE dataWref = GetMultipleResults(str, win)
		FAIL()
	catch
		PASS()
	endtry

	// range end
	str = "data([0, 11],select(channels(AD),[" + num2istr(sweepNo) + "],all))"
	try
		WAVE/WAVE dataWref = GetMultipleResults(str, win)
		FAIL()
	catch
		PASS()
	endtry

	// One sweep does not exist, it is not result of select, we end up with one sweep
	sweepCnt = 1
	str = "data(cursors(A,B),select(channels(AD),[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 2) + "],all))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	numResultsRef = sweepCnt * numChannels / 2
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3})
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {0, 0}, SF_DATATYPE_SWEEP)

	// Setup graph with equivalent data
	TUD_Clear(win)

	Make/FREE/N=(dataSize, numSweeps, numChannels) input = q + p^r
	for(i = 0; i < numSweeps; i += 1)
		sweepNo = i
		for(j = 0; j < numChannels; j += 1)
			name = UniqueName("data", 1, 0)
			trace = "trace_" + name
			Extract input, $name, q == i && r == j
			WAVE wv = $name
			AppendToGraph/W=$win wv/TN=$trace
			TUD_SetUserDataFromWaves(win, trace, {"experiment", "fullPath", "traceType", "occurence", "channelType", "channelNumber", "sweepNumber"},         \
									 {"blah", GetWavesDataFolder(wv, 2), "Sweep", "0", StringFromList(j, channelTypeList), StringFromList(j, channelNumberList), num2istr(sweepNo)})
		endfor
	endfor

	Make/FREE/N=(DimSize(sweepRef, ROWS), 2, numChannels) dataRef
	dataRef[][][] = sweepRef[p]

	sweepCnt = 2
	str = "data(cursors(A,B),select())"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	numResultsRef = sweepCnt * numChannels
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3, 0, 2, 1, 3, 0, 2})
	CheckSweepsMetaData(dataWref, {0, 0, 1, 1, 0, 0, 1, 1}, {6, 7, 2, 3, 6, 7, 2, 3}, {0, 0, 0, 0, 1, 1, 1, 1}, SF_DATATYPE_SWEEP)
	str = "data(cursors(A,B))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3, 0, 2, 1, 3, 0, 2})
	CheckSweepsMetaData(dataWref, {0, 0, 1, 1, 0, 0, 1, 1}, {6, 7, 2, 3, 6, 7, 2, 3}, {0, 0, 0, 0, 1, 1, 1, 1}, SF_DATATYPE_SWEEP)

	// Using the setup from data we also test cursors operation
	Cursor/W=$win/A=1/P A, $trace, 0
	Cursor/W=$win/A=1/P B, $trace, trunc(dataSize / 2)
	Make/FREE dataRef = {0, trunc(dataSize / 2)}
	str = "cursors(A,B)"
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA)
	str = "cursors()"
	WAVE data = GetSingleResult(str, win)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA)

	try
		str = "cursors(X,Y)"
		WAVE data = GetSingleResult(str, win)
		FAIL()
	catch
		PASS()
	endtry

End

Function/WAVE FakeSweepDataGeneratorPS(WAVE sweep, variable numChannels)

	variable pnts = 100000
	variable targetFreq = 100
	variable divisor

	Redimension/D/N=(pnts, numChannels) sweep
	SetScale/P x, 0, HARDWARE_NI_DAC_MIN_SAMPINT, "ms", sweep
	divisor = targetFreq / 2 * pnts * HARDWARE_NI_DAC_MIN_SAMPINT * MILLI_TO_ONE
	MultiThread sweep = sin(2 * Pi * IndexToScale(sweep, p, ROWS) / divisor)

	return sweep
End

static Function TestOperationPowerSpectrum()

	string win, device
	string channelTypeList = "DA;AD;DA;AD;"
	string channelNumberList = "2;6;3;7;"

	variable sweepNo, val
	string str, strRef

	[win, device] = CreateFakeDataBrowserWindow()

	sweepNo = 0
	FUNCREF FakeSweepDataGeneratorProto sweepGen = FakeSweepDataGeneratorPS

	CreateFakeSweepData(device, sweepNo=sweepNo, sweepGen=FakeSweepDataGeneratorPS)
	CreateFakeSweepData(device, sweepNo=sweepNo + 1, sweepGen=FakeSweepDataGeneratorPS)

	str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WaveStats/Q/M=1 data
	CHECK_CLOSE_VAR(V_maxLoc, 100, tol=0.01)
	CHECK_EQUAL_VAR(trunc(V_min), 0)
	CHECK_CLOSE_VAR(V_max, 603758976, tol=0.01)
	val = IndexToScale(data, DimSize(data, ROWS), ROWS)
	CHECK_CLOSE_VAR(val, 1000, tol=0.001)
	str = WaveUnits(data, -1)
	strRef = "^2"
	CHECK_EQUAL_STR(strRef, str)

	str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)),dB)"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WaveStats/Q/M=1 data
	CHECK_CLOSE_VAR(V_maxLoc, 100, tol=0.01)
	CHECK_CLOSE_VAR(V_max, 88, tol=0.01)
	str = WaveUnits(data, -1)
	strRef = "dB"
	CHECK_EQUAL_STR(strRef, str)

	str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)),normalized)"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WaveStats/Q/M=1 data
	CHECK_CLOSE_VAR(V_maxLoc, 100, tol=0.01)
	CHECK_CLOSE_VAR(V_max, 129, tol=0.01)
	str = WaveUnits(data, -1)
	strRef = "mean(^2)"
	CHECK_EQUAL_STR(strRef, str)

	str = "powerspectrum(data(cursors(A,B),select(channels(AD),[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "],all)),dB,avg)"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(2, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WaveStats/Q/M=1 data
	CHECK_CLOSE_VAR(V_maxLoc, 100, tol=0.01)
	CHECK_CLOSE_VAR(V_max, 88, tol=0.01)
	WAVE data = dataWref[1]
	WaveStats/Q/M=1 data
	CHECK_CLOSE_VAR(V_maxLoc, 100, tol=0.01)
	CHECK_CLOSE_VAR(V_max, 88, tol=0.01)

	str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)),dB,noavg,100)"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WaveStats/Q/M=1 data
	CHECK_EQUAL_VAR(1, DimSize(data, ROWS))
	CHECK_CLOSE_VAR(data[0], 1.32, tol=0.01)

	str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)),dB,noavg,0,2000)"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	val = IndexToScale(data, DimSize(data, ROWS), ROWS)
	CHECK_CLOSE_VAR(val, 2000, tol=0.001)

	str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)),dB,noavg,0,1000,HFT248D)"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WaveStats/Q/M=1 data
	CHECK_CLOSE_VAR(V_maxLoc, 100, tol=0.01)
	CHECK_CLOSE_VAR(V_max, 94, tol=0.01)

	try
		str = "powerspectrum()"
		WAVE/WAVE dataWref = GetMultipleResults(str, win)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)), not_exist)"
		WAVE/WAVE dataWref = GetMultipleResults(str, win)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)), dB, not_exist)"
		WAVE/WAVE dataWref = GetMultipleResults(str, win)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)), dB, avg, -1)"
		WAVE/WAVE dataWref = GetMultipleResults(str, win)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)), dB, avg, 0, -1)"
		WAVE/WAVE dataWref = GetMultipleResults(str, win)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)), dB, avg, 0, 1000, not_exist)"
		WAVE/WAVE dataWref = GetMultipleResults(str, win)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)), dB, avg, 0, 1000, Bartlet, not_exist)"
		WAVE/WAVE dataWref = GetMultipleResults(str, win)
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestOperationLabNotebook()
	Variable i, j, sweepNumber, channelNumber
	String str, trace, key, name, epochStr

	Variable numSweeps = 10
	Variable numChannels = 5
	Variable dataSize = 128
	Variable mode = DATA_ACQUISITION_MODE
	String channelType = StringFromList(XOP_CHANNEL_TYPE_ADC, XOP_CHANNEL_NAMES)
	string textKey = "TEXTKEY"
	string textValue = "TestText"

	String channelTypeC = channelType + "C"

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()
	TUD_Clear(win)

	WAVE/T numericalKeys = GetLBNumericalKeys(device)
	WAVE numericalValues = GetLBNumericalValues(device)
	KillWaves numericalKeys, numericalValues

	Make/FREE/T/N=(1, 1) keys = {{channelTypeC}}
	Make/U/I/N=(numChannels) connections = {7,5,3,1,0}
	Make/U/I/N=(numSweeps, numChannels) channels = q * 2
	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
	Make/T/FREE/N=(LABNOTEBOOK_LAYER_COUNT) valuesText = textValue
	Make/FREE/T/N=(1, 1) dacKeys = "DAC"
	Make/FREE/T/N=(1, 1) textKeys = textKey

	Make/FREE/N=(dataSize, numSweeps, numChannels) input = q + p^r // + gnoise(1)

	DFREF dfr = GetDeviceDataPath(device)
	for(i = 0; i < numSweeps; i += 1)
		sweepNumber = i
		WAVE sweepTemplate = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
		WAVE sweep = FakeSweepDataGeneratorDefault(sweepTemplate, numChannels)
		WAVE config = GetDAQConfigWave(device)
		Redimension/N=(numChannels, -1) config
		for(j = 0; j < numChannels; j += 1)
			name = UniqueName("data", 1, 0)
			trace = "trace_" + name
			Extract input, $name, q == i && r == j
			WAVE wv = $name
			AppendToGraph/W=$win wv/TN=$trace
			channelNumber = channels[i][j]
			TUD_SetUserDataFromWaves(win, trace, {"experiment", "fullPath", "traceType", "occurence", "channelType", "channelNumber", "sweepNumber"},         \
									 {"blah", GetWavesDataFolder(wv, 2), "Sweep", "0", channelType, num2str(channelNumber), num2str(sweepNumber)})
			values[connections[j]] = channelNumber
			config[j][%ChannelType]   = XOP_CHANNEL_TYPE_ADC
			config[j][%ChannelNumber] = channelNumber
		endfor

		// create sweeps with dummy data for sweeps() operation thats called when omitting select
		MoveWave sweep, dfr:$GetSweepWaveName(sweepNumber)
		MoveWave config, dfr:$GetConfigWaveName(sweepNumber)
		MIES_DB#DB_SplitSweepsIfReq(win, sweepNumber)

		Redimension/N=(1, 1, LABNOTEBOOK_LAYER_COUNT)/E=1 values
		Redimension/N=(1, 1, LABNOTEBOOK_LAYER_COUNT)/E=1 valuesText
		ED_AddEntriesToLabnotebook(values, keys, sweepNumber, device, mode)
		ED_AddEntriesToLabnotebook(values, dacKeys, sweepNumber, device, mode)
		Redimension/N=(LABNOTEBOOK_LAYER_COUNT)/E=1 values
		ED_AddEntryToLabnotebook(device, keys[0], values, overrideSweepNo = sweepNumber)
		ED_AddEntriesToLabnotebook(valuesText, textKeys, sweepNumber, device, mode)
	endfor
	ModifyGraph/W=$win log(left)=1

	Make/FREE/N=(numSweeps * numChannels) channelsRef
	channelsRef[] = channels[trunc(p / numChannels)][mod(p, numChannels)]
	str = "labnotebook(" + channelTypeC + ")"
	TestOperationLabnotebookHelper(win, str, channelsRef)
	str = "labnotebook(" + channelTypeC + ",select(channels(AD),0..." + num2istr(numSweeps) + "))"
	TestOperationLabnotebookHelper(win, str, channelsRef)
	str = "labnotebook(" + LABNOTEBOOK_USER_PREFIX + channelTypeC + ",select(channels(AD),0..." + num2istr(numSweeps) + "),UNKNOWN_MODE)"
	TestOperationLabnotebookHelper(win, str, channelsRef)

	str = "labnotebook(" + channelTypeC + ",select(channels(AD12),-1))"
	WAVE/WAVE dataRef = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(DimSize(dataRef, ROWS), 0)

	str = "labnotebook(" + textKey + ")"
	WAVE/WAVE dataRef = GetMultipleResults(str, win)
	Make/FREE/T textRefData = {textValue}
	for(WAVE/T dataT : dataRef)
		CHECK_EQUAL_WAVES(dataT, textRefData, mode = WAVE_DATA)
	endfor
End

static Function TestOperationLabnotebookHelper(string win, string formula, WAVE wRef)

	variable i

	WAVE/WAVE dataRef = GetMultipleResults(formula, win)
	CHECK_GT_VAR(DimSize(dataRef, ROWS), 0)
	i = 0
	for(WAVE/D data : dataRef)
		CHECK_EQUAL_VAR(DimSize(data, ROWS), 1)
		CHECK_EQUAL_VAR(data[0], wRef[i])
		i += 1
	endfor
End

/// @brief Test Epoch operation of SweepFormula
static Function TestOperationEpochs()

	variable i, j, sweepNumber, channelNumber, numResultsRef
	string str, trace, key, name, win, device

	variable numSweeps = 10
	variable numChannels = 5
	variable activeChannelsDA = 4
	variable mode = DATA_ACQUISITION_MODE
	string channelType = StringFromList(XOP_CHANNEL_TYPE_DAC, XOP_CHANNEL_NAMES)

	string channelTypeC = channelType + "C"

	[win, device] = CreateFakeDataBrowserWindow()
	TUD_Clear(win)

	WAVE/T numericalKeys = GetLBNumericalKeys(device)
	WAVE numericalValues = GetLBNumericalValues(device)
	KillWaves numericalKeys, numericalValues

	Make/FREE/T/N=(1, 1) keys = {{channelTypeC}}
	Make/U/I/N=(numChannels) connections = {7,5,3,1,0}
	Make/U/I/N=(numSweeps, numChannels) channels = q * 2 // 0, 2, 4, 6, 8 used for all sweeps
	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN

	Make/FREE/N=(128, numSweeps, numChannels) input = q + p^r

	Make/FREE/T/N=(1, 1) keysEpochs = {{EPOCHS_ENTRY_KEY}}
	Make/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT)/T wEpochStr
	wEpochStr = "0.5000000,0.5100000,Epoch=0;Type=Pulse Train;Amplitude=1;Pulse=48;ShortName=E0_PT_P48;,2,:0.5030000,0.5100000,Epoch=0;Type=Pulse Train;Pulse=48;Baseline;ShortName=E0_PT_P48_B;,3,"

	DFREF dfr = GetDeviceDataPath(device)
	for(i = 0; i < numSweeps; i += 1)
		sweepNumber = i

		WAVE sweepTemplate = GetDAQDataWave(device, DATA_ACQUISITION_MODE)
		WAVE sweep = FakeSweepDataGeneratorDefault(sweepTemplate, numChannels)
		WAVE config = GetDAQConfigWave(device)
		Redimension/N=(numChannels, -1) config

		for(j = 0; j < numChannels; j += 1)
			name = UniqueName("data", 1, 0)
			trace = "trace_" + name
			Extract input, $name, q == i && r == j
			WAVE wv = $name
			AppendToGraph/W=$win wv/TN=$trace
			channelNumber = channels[i][j]
			TUD_SetUserDataFromWaves(win, trace, {"experiment", "fullPath", "traceType", "occurence", "channelType", "channelNumber", "sweepNumber"},         \
									 {"blah", GetWavesDataFolder(wv, 2), "Sweep", "0", channelType, num2istr(channelNumber), num2istr(sweepNumber)})
			values[connections[j]] = channelNumber
			config[j][%ChannelType]   = XOP_CHANNEL_TYPE_DAC
			config[j][%ChannelNumber] = channelNumber
		endfor

		// create sweeps with dummy data for sweeps() operation thats called when omitting select
		MoveWave sweep, dfr:$GetSweepWaveName(sweepNumber)
		MoveWave config, dfr:$GetConfigWaveName(sweepNumber)
		MIES_DB#DB_SplitSweepsIfReq(win, sweepNumber)

		// channels setup DA: 8, 6, NaN, 4, NaN, 2, NaN, 0, NaN
		// -> 4 active channels for DAC, because DAC knows only 8 channels from 0 to 7.

		Redimension/N=(1, 1, LABNOTEBOOK_LAYER_COUNT)/E=1 values
		ED_AddEntriesToLabnotebook(values, keys, sweepNumber, device, mode)
		Redimension/N=(LABNOTEBOOK_LAYER_COUNT)/E=1 values
		ED_AddEntryToLabnotebook(device, keys[0], values, overrideSweepNo = sweepNumber)

		ED_AddEntriesToLabnotebook(wEpochStr, keysEpochs, sweepNumber, device, mode)
	endfor

	str = "epochs(\"E0_PT_P48\")"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	Make/FREE/D refData = {500, 510}
	numResultsRef = numSweeps * activeChannelsDA
	REQUIRE_EQUAL_VAR(numResultsRef, DimSize(dataWref, ROWS))
	for(i = 0; i < numResultsRef; i += 1)
		WAVE epochData = dataWref[i]
		REQUIRE_EQUAL_WAVES(refData, epochData, mode = WAVE_DATA)
	endfor
	Make/FREE/D/N=(numResultsRef) sweeps, chanNr, chanType
	FastOp chanType = (XOP_CHANNEL_TYPE_DAC)
	sweeps[] = trunc(p / activeChannelsDA)
	chanNr[] = mod(p, activeChannelsDA) * 2
	CheckSweepsMetaData(dataWref, chanType, chanNr, sweeps, SF_DATATYPE_EPOCHS)

	str = "epochs(\"E0_PT_P48\", select(channels(DA0), 0))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 1)
	Make/FREE/D refData = {500, 510}
	WAVE data = dataWref[0]
	REQUIRE_EQUAL_WAVES(data, refData, mode = WAVE_DATA)

	str = "epochs(\"E0_PT_P48_B\", select(channels(DA4), 0))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 1)
	Make/FREE/D refData = {503, 510}
	WAVE data = dataWref[0]
	REQUIRE_EQUAL_WAVES(data, refData, mode = WAVE_DATA)

	str = "epochs(\"E0_PT_P48_B\", select(channels(DA4), 0), range)"
	WAVE data = GetSingleResult(str, win)
	Make/FREE/D refData = {503, 510}
	REQUIRE_EQUAL_WAVES(data, refData, mode = WAVE_DATA)

	str = "epochs(\"E0_PT_P48_B\", select(channels(DA4),0), treelevel)"
	WAVE data = GetSingleResult(str, win)
	Make/FREE/D refData = {3}
	REQUIRE_EQUAL_WAVES(data, refData, mode = WAVE_DATA)

	str = "epochs(\"E0_PT_P48_B\", select(channels(DA4), 9), name)"
	WAVE/T dataT = GetSingleResult(str, win)
	Make/FREE/T refDataT = {"Epoch=0;Type=Pulse Train;Pulse=48;Baseline;ShortName=E0_PT_P48_B;"}
	REQUIRE_EQUAL_WAVES(dataT, refDataT, mode = WAVE_DATA)

	// works case-insensitive
	str = "epochs(\"e0_pt_p48_B\", select(channels(DA4), 9), name)"
	WAVE/T dataT = GetSingleResult(str, win)
	Make/FREE/T refDataT = {"Epoch=0;Type=Pulse Train;Pulse=48;Baseline;ShortName=E0_PT_P48_B;"}
	REQUIRE_EQUAL_WAVES(dataT, refDataT, mode = WAVE_DATA)

	str = "epochs(\"E0_PT_P48_B\", select(channels(DA), 0..." + num2istr(numSweeps) + "))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), numSweeps * activeChannelsDA)
	Make/FREE/D refData = {503, 510}
	for(data : dataWref)
		REQUIRE_EQUAL_WAVES(data, refData, mode = WAVE_DATA)
	endfor
	// check Meta data
	Make/FREE/D/N=(numSweeps * activeChannelsDA) channelTypes, channelNumbers, sweepNumbers
	channelTypes = XOP_CHANNEL_TYPE_DAC
	channelNumbers = mod(p, activeChannelsDA) * 2
	sweepNumbers = trunc(p / activeChannelsDA)
	CheckSweepsMetaData(dataWref, channelTypes, channelNumbers, sweepNumbers, SF_DATATYPE_EPOCHS)

	// channel(s) with no epochs
	str = "epochs(\"E0_PT_P48_B\", select(channels(AD), 0..." + num2istr(numSweeps) + "))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// channels with epochs, but name that does not match any epoch
	str = "epochs(\"does_not_exist\", select(channels(DA), 0..." + num2istr(numSweeps) + "))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// invalid sweep
	str = "epochs(\"E0_PT_P48_B\", select(channels(DA), " + num2istr(numSweeps) + "))"
	WAVE/WAVE dataWref = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// invalid type
	str = "epochs(\"E0_PT_P48_B\", select(channels(DA), 0..." + num2istr(numSweeps) + "), invalid_type)"
	try
		WAVE/WAVE dataWref = GetMultipleResults(str, win)
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestSFPreprocessor()

	string input, output
	string refOutput

	input = ""
	refOutput = ""
	output = MIES_SF#SF_PreprocessInput(input)
	CHECK_EQUAL_STR(output, refOutput)

	input = "\r\r\r"
	refOutput = "\r\r\r"
	output = MIES_SF#SF_PreprocessInput(input)
	CHECK_EQUAL_STR(output, refOutput)

	input = "text\rtext\r"
	refOutput = "text\rtext\r"
	output = MIES_SF#SF_PreprocessInput(input)
	CHECK_EQUAL_STR(output, refOutput)

	input = "# comment"
	refOutput = ""
	output = MIES_SF#SF_PreprocessInput(input)
	CHECK_EQUAL_STR(output, refOutput)

	input = "text#comment"
	refOutput = "text"
	output = MIES_SF#SF_PreprocessInput(input)
	CHECK_EQUAL_STR(output, refOutput)

	input = "text####comment"
	refOutput = "text"
	output = MIES_SF#SF_PreprocessInput(input)
	CHECK_EQUAL_STR(output, refOutput)

	input = "text####comment#comment#comment##comment"
	refOutput = "text"
	output = MIES_SF#SF_PreprocessInput(input)
	CHECK_EQUAL_STR(output, refOutput)

	input = "text#comment\rtext#comment\rtext"
	refOutput = "text\rtext\rtext"
	output = MIES_SF#SF_PreprocessInput(input)
	CHECK_EQUAL_STR(output, refOutput)
End

static Function/WAVE SweepFormulaFunctionsWithSweepsArgument()

	Make/FREE/T wv = {"data(cursors(A,B), select(channels(AD), sweeps()))",           \
							"epochs(\"I DONT EXIST\", select(channels(DA), sweeps()))",     \
							"labnotebook(\"I DONT EXIST\", select(channels(DA), sweeps()))"}

	SetDimensionLabels(wv, "data;epochs;labnotebook", ROWS)

	return wv
End

// UTF_TD_GENERATOR SweepFormulaFunctionsWithSweepsArgument
static Function AvoidAssertingOutWithNoSweeps([string str])

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	WAVE/WAVE dataRef = GetMultipleResults(str, win)
	CHECK_EQUAL_VAR(DimSize(dataRef, ROWS), 0)
End

static Function ExecuteSweepFormulaInDB(string code, string win)
	string sfFormula, bsPanel

	bsPanel = BSP_GetPanel(win)

	sfFormula = BSP_GetSFFormula(win)
	ReplaceNotebookText(sfFormula, code)

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_SF", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display")

	return GetValDisplayAsNum(bsPanel, "status_sweepFormula_parser")
End

static Function/WAVE InvalidStoreFormulas()

	Make/T/N=3/FREE wv

	// invalid name
	wv[0] = "store(\"\", [0])"

	// array as name
	wv[1] = "store([\"a\", \"b\"], [0])"

	// numeric value as name
	wv[2] = "store([1], [0])"

	return wv
End

// UTF_TD_GENERATOR InvalidStoreFormulas
static Function StoreChecksParameters([string str])
	string win

	win = GetDataBrowserWithData()

	CHECK(!ExecuteSweepFormulaInDB(str, win))

	WAVE textualResultsValues = GetLogbookWaves(LBT_RESULTS, LBN_TEXTUAL_VALUES)
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(textualResultsValues, NOTE_INDEX), 0)
End

static Function/WAVE GetStoreWaves()

	Make/WAVE/N=3/FREE wv

	Make/FREE/D wv0 = {1234.5678}
	wv[0]= wv0

	Make/FREE wv1 = {1, 2}
	wv[1]= wv1

	Make/FREE/T wv2 = {"a", "b"}
	wv[2]= wv2

	return wv
End

// UTF_TD_GENERATOR GetStoreWaves
static Function StoreWorks([WAVE wv])
	string win, results, ref
	variable array

	win = GetDataBrowserWithData()

	array = JSON_New()
	JSON_AddWave(array, "", wv)
	ref = "store(\"ABCD\", " + JSON_Dump(array) + " ) vs 0"
	JSON_Release(array)

	CHECK(ExecuteSweepFormulaInDB(ref, win))

	WAVE textualResultsValues = GetLogbookWaves(LBT_RESULTS, LBN_TEXTUAL_VALUES)

	// one for store and one for code execution
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(textualResultsValues, NOTE_INDEX), 2)

	// only check SWEEP_FORMULA_RESULT entry source type, other entries are checked in TestSweepFormulaCodeResults
	results = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula code", SWEEP_FORMULA_RESULT)
	CHECK_EQUAL_STR(results, ref)

	// check serialized wave
	results = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula store [ABCD]", SWEEP_FORMULA_RESULT)
	CHECK_PROPER_STR(results)

	if(IsTextWave(wv))
		WAVE/T/Z resultsTextWave = ListToTextWaveMD(results, 1)
		CHECK_EQUAL_TEXTWAVES(wv, resultsTextWave, mode = WAVE_DATA)
	else
		WAVE/Z resultsWave = ListToNumericWave(results, ";")
		CHECK_EQUAL_WAVES(wv, resultsWave, mode = WAVE_DATA)
	endif

	// check sweep formula y wave
	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)
	WAVE/Z sweepFormulaY = GetSweepFormulaY(dfr, 0)
	CHECK_EQUAL_VAR(DimSize(sweepFormulaY, COLS), 1)
	Redimension/N=(-1, 0) sweepFormulaY
	CHECK_EQUAL_WAVES(wv, sweepFormulaY, mode = WAVE_DATA)
End

static Function/WAVE TestHelpNotebookGetter_IGNORE()

	WAVE/T wt = SF_GetNamedOperations()

	return wt
End

// UTF_TD_GENERATOR TestHelpNotebookGetter_IGNORE
static Function TestHelpNotebook([string str])

	DB_OpenDataBrowser()
	CHECK_EQUAL_VAR(DB_SFHelpJumpToLine("operation - " + str), 0)
End

// data acquired with model cell, 45% baseline
// the data is the inserted TP plus 10ms flat stimset
static Function TPWithModelCell()
	string win, device, bsPanel, results, ref

	device = HW_ITC_BuildDeviceString("ITC18USB", "0")

	DFREF dfr = GetDevicePath(device)
	DuplicateDataFolder root:SF_TP:Data, dfr

	DFREF dfr = GetMIESPath()
	DuplicateDataFolder root:SF_TP:LabNoteBook, dfr

	GetDAQDeviceID(device)

	win = DB_GetBoundDataBrowser(device)

	CHECK(ExecuteSweepFormulaInDB("store(\"inst\",tp(inst))\n and \nstore(\"ss\",tp(ss))", win))

	WAVE textualResultsValues = GetLogbookWaves(LBT_RESULTS, LBN_TEXTUAL_VALUES)

	results = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula store [ss]", SWEEP_FORMULA_RESULT)
	ref = "183.03771820448884;"
	CHECK_EQUAL_STR(ref, results)

	results = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula store [inst]", SWEEP_FORMULA_RESULT)
	ref = "17.366739401496286;"
	CHECK_EQUAL_STR(ref, results)
End

static Function NonExistingOperation()

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	try
		// this is currently caught by an additional check specifically for automated testing
		// but it would also cause an Abort in the main code
		WAVE output = GetSingleResult("bogusOp(1,2,3)", win)
		FAIL()
	catch
		PASS()
	endtry
End

static Function ZeroSizedSubArrayTest()

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	WAVE wTextRef = SF_FormulaExecutor(win, JSON_Parse("[]"))
	CHECK(IsTextWave(wTextRef))
	CHECK_EQUAL_VAR(DimSize(wTextRef, ROWS), 1)
	CHECK_EQUAL_VAR(DimSize(wTextRef, COLS), 0)
	WAVE/WAVE wRefResult = MIES_SF#SF_ParseArgument(win, wTextRef, "TestRun")
	CHECK_EQUAL_VAR(DimSize(wRefResult, ROWS), 1)
	CHECK_EQUAL_VAR(DimSize(wRefResult, COLS), 0)
	WAVE wv = wRefResult[0]
	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 0)
End

static Function/WAVE TestAverageOverSweeps_CreateData(variable val, variable channelNumber, variable channelType, variable sweepNo)

	Make/FREE data = val
	JWN_SetNumberInWaveNote(data, SF_META_CHANNELNUMBER, channelNumber)
	JWN_SetNumberInWaveNote(data, SF_META_CHANNELTYPE, channelType)
	JWN_SetNumberInWaveNote(data, SF_META_SWEEPNO, sweepNo)

	return data
End

static Function/WAVE TestAverageOverSweeps_CheckMeta(WAVE data, variable channelNumber, variable channelType, variable firstSweep)

	variable val

	val = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELNUMBER)
	CHECK_EQUAL_VAR(channelNumber, val)
	val = JWN_GetNumberFromWaveNote(data, SF_META_CHANNELTYPE)
	CHECK_EQUAL_VAR(channelType, val)
	val = JWN_GetNumberFromWaveNote(data, SF_META_AVERAGED_FIRST_SWEEP)
	CHECK_EQUAL_VAR(firstSweep, val)
	val = JWN_GetNumberFromWaveNote(data, SF_META_ISAVERAGED)
	CHECK_EQUAL_VAR(1, val)

	return data
End

static Function TestAverageOverSweeps()

	Make/FREE/WAVE/N=6 input

	WAVE data0 = TestAverageOverSweeps_CreateData(1, 1, 1, 0)
	WAVE data1 = TestAverageOverSweeps_CreateData(3, 1, 1, 1)

	WAVE data2 = TestAverageOverSweeps_CreateData(3, 2, 1, 2)
	WAVE data3 = TestAverageOverSweeps_CreateData(5, 2, 1, 3)

	WAVE data4 = TestAverageOverSweeps_CreateData(5, 1, 1, NaN)
	WAVE data5 = TestAverageOverSweeps_CreateData(7, 1, 1, NaN)

	input[0] = data0
	input[1] = data1
	input[2] = data2
	input[3] = data3
	input[4] = data4
	input[5] = data5

	WAVE/WAVE output = MIES_SF#SF_AverageDataOverSweeps(input)
	CHECK_EQUAL_VAR(3, DimSize(output, ROWS))
	WAVE data = output[0]
	Make/FREE dataRef = 2
	CHECK_EQUAL_WAVES(dataRef, data, mode=WAVE_DATA)
	TestAverageOverSweeps_CheckMeta(data, 1, 1, 0)

	WAVE data = output[1]
	Make/FREE dataRef = 4
	CHECK_EQUAL_WAVES(dataRef, data, mode=WAVE_DATA)
	TestAverageOverSweeps_CheckMeta(data, 2, 1, 2)

	WAVE data = output[2]
	Make/FREE dataRef = 6
	CHECK_EQUAL_WAVES(dataRef, data, mode=WAVE_DATA)
	TestAverageOverSweeps_CheckMeta(data, NaN, NaN, NaN)

End

static function TestLegendShrink()

	string str, result
	string strRef

	str = "\s(T000000d0_Sweep_0_AD1) Sweep 0 AD1\r\s(T000000d1_Sweep_1_AD1) Sweep 1 AD1\r\s(T000000d2_Sweep_2_AD1) Sweep 2 AD1"
	strref = "\s(T000000d0_Sweep_0_AD1)Sweeps 0-2 AD1"
	result = MIES_SF#SF_ShrinkLegend(str)
	CHECK_EQUAL_STR(strRef, result)

	str = "\s(T000000d0_Sweep_0_AD1) Sweep 0 AD1\r\s(T000000d1_Sweep_1_AD1) Sweep 1 AD1\r\s(T000000d2_Sweep_2_AD1) Sweep 2 AD2"
	strref = str
	result = MIES_SF#SF_ShrinkLegend(str)
	CHECK_EQUAL_STR(strRef, result)

	str = "\s(T000000d0_Sweep_0_AD1) Sweep 0 AD1\r\s(T000000d1_Sweep_1_AD1) Sweep 1 AD1\r\s(T000000d2_Sweep_2_AD1) operation Sweep 2 AD1"
	strref = str
	result = MIES_SF#SF_ShrinkLegend(str)
	CHECK_EQUAL_STR(strRef, result)

	str = "\s(T000000d0_Sweep_0_AD1) Sweep 0 AD1\r\s(T000000d1_Sweep_1_AD1) Sweep 1 AD1\r\s(T000000d2_Sweep_2_AD1) Sweep 23 AD1"
	strref = "\s(T000000d0_Sweep_0_AD1)Sweeps 0-1,23 AD1"
	result = MIES_SF#SF_ShrinkLegend(str)
	CHECK_EQUAL_STR(strRef, result)

	str = "some other Sweep legend"
	strref = str
	result = MIES_SF#SF_ShrinkLegend(str)
	CHECK_EQUAL_STR(strRef, result)
End
