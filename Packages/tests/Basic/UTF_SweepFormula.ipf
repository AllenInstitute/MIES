#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTF_SweepFormula

Function/S CreateFakeSweepBrowser_IGNORE()

	string win

	Display
	win = S_name
	DFREF dfr = GetUniqueTempPath()
	AddVersionToPanel(win, DATA_SWEEP_BROWSER_PANEL_VERSION)
	BSP_SetFolder(win, dfr, MIES_BSP_PANEL_FOLDER)
	BSP_SetSweepBrowser(win, BROWSER_MODE_USER)

	return win
End

static Function/S CreateFormulaGraphForBrowser(string browser)

	string win

	win = CleanupName(SF_PLOT_NAME_TEMPLATE, 0)
	NewPanel/N=$win
	win = S_name

	SetWindow $win, userData($SFH_USER_DATA_BROWSER)=browser

	return win
End

static Function FailFormula(string code)

	try
		DirectToFormulaParser(code)
		FAIL()
	catch
		PASS()
	endtry
End

Function DirectToFormulaParser(string code)

	variable jsonId, srcLocId

	code               = MIES_SF#SF_PreprocessInput(code)
	[jsonId, srcLocId] = MIES_SFP#SFP_ParseFormulaToJSON(code)
	JSON_Release(srcLocId)

	return jsonId
End

Function TestOperationMinMaxHelper(string win, string jsonRefText, string formula, variable refResult)

	CheckEqualFormulas(jsonRefText, formula)
	WAVE data = SFE_ExecuteFormula(formula, win, singleResult = 1, useVariables = 0)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 1)

	if(IsNumericWave(data))
		CHECK_EQUAL_VAR(data[0], refResult)
	else
		WAVE/T dataText = data
		CHECK_EQUAL_STR(dataText[0], num2str(refResult))
	endif
End

static Function primitiveOperations()

	variable jsonID0, jsonID1
	string win

	win = GetDataBrowserWithData()

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

static Function TestNonFiniteValues()

	string win

	win = GetDataBrowserWithData()

	TestOperationMinMaxHelper(win, "\"inf\"", "inf", +Inf)
	TestOperationMinMaxHelper(win, "\"-inf\"", "-inf", -Inf)
	TestOperationMinMaxHelper(win, "\"NaN\"", "NaN", NaN)
End

// Fails with Abort
// UTF_TD_GENERATOR DataGenerators#NonFiniteValues
//static Function TestNonFiniteValuesPrimitiveOperations([variable var])
//
//	string win, device, str
//
//	[win, device] = CreateEmptyUnlockedDataBrowserWindow()
//
//	str = "\"" + num2str(var) + "\""
//	TestOperationMinMaxHelper(win, "{\"+\":[1," + str + "]}", "1+" + str, 1 + var)
//	TestOperationMinMaxHelper(win, "{\"*\":[1," + str + "]}", "1*" + str, 1 * var)
//	TestOperationMinMaxHelper(win, "{\"-\":[1," + str + "]}", "1-" + str, 1 - var)
//	TestOperationMinMaxHelper(win, "{\"/\":[1," + str + "]}", "1/" + str, 1 / var)
//End

static Function Transitions()

	string win

	win = GetDataBrowserWithData()

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

	variable jsonID0, jsonID1

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
	WAVE output = SFE_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Duplicate/FREE input, input0
	input0[][][][] = input[p][q][r][s] - input[p][q][r][s]
	str            = array2d + "-" + array2d
	WAVE output = SFE_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input0, output, mode = WAVE_DATA)

	Duplicate/FREE input, input1
	input1[][][][] = input[p][q][r][s] + input[p][q][r][s]
	str            = array2d + "+" + array2d
	WAVE output = SFE_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input1, output, mode = WAVE_DATA)

	Duplicate/FREE input, input2
	input2[][][][] = input[p][q][r][s] / input[p][q][r][s]
	str            = array2d + "/" + array2d
	WAVE output = SFE_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input2, output, mode = WAVE_DATA)

	Duplicate/FREE input, input3
	input3[][][][] = input[p][q][r][s] * input[p][q][r][s]
	str            = array2d + "*" + array2d
	WAVE output = SFE_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input3, output, mode = WAVE_DATA)

	Duplicate/FREE input, input10
	input10 -= numeric
	str      = array2d + "-" + num2str(numeric)
	WAVE output = SFE_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input10, output, mode = WAVE_DATA)
	input10[][][][] = numeric - input[p][q][r][s]
	str             = num2str(numeric) + "-" + array2d
	WAVE output = SFE_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input10, output, mode = WAVE_DATA)

	Duplicate/FREE input, input11
	input11 += numeric
	str      = array2d + "+" + num2str(numeric)
	WAVE output = SFE_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input11, output, mode = WAVE_DATA)
	input11[][][][] = numeric + input[p][q][r][s]
	str             = num2str(numeric) + "+" + array2d
	WAVE output = SFE_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input11, output, mode = WAVE_DATA)

	Duplicate/FREE input, input12
	input12 /= numeric
	str      = array2d + "/" + num2str(numeric)
	WAVE output = SFE_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input12, output, mode = WAVE_DATA)
	input12[][][][] = numeric / input[p][q][r][s]
	str             = num2str(numeric) + "/" + array2d
	WAVE output = SFE_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input12, output, mode = WAVE_DATA)

	Duplicate/FREE input, input13
	input13 *= numeric
	str      = array2d + "*" + num2str(numeric)
	WAVE output = SFE_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input13, output, mode = WAVE_DATA)
	input13[][][][] = numeric * input[p][q][r][s]
	str             = num2str(numeric) + "*" + array2d
	WAVE output = SFE_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input13, output, mode = WAVE_DATA)
End

static Function primitiveOperations2D()

	string win

	win = GetDataBrowserWithData()

	arrayOperations(win, "[1,2]", 1)
	arrayOperations(win, "[[1,2],[3,4],[5,6]]", 1)
	arrayOperations(win, "[[1,2],[3,4],[5,6]]", 42)
	arrayOperations(win, "[[1],[3,4],[5,6]]", 1)
	arrayOperations(win, "[[1,2],[3],[5,6]]", 1)
	arrayOperations(win, "[[1,2],[3,4],[5]]", 1)
	arrayOperations(win, "[[1,2],[3,4],[5,6]]", 1.5)
End

static Function TestArrayExpansionText()

	string win, str

	win = GetDataBrowserWithData()

	str = "[[\"1\"],[\"3\",\"4\"],[\"5\",\"6\"]]"
	WAVE/T output = SFE_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)

	WAVE/T input = JSON_GetTextWave(JSON_Parse(str), "")
	// simulate simplified array expansion
	input[][] = SelectString(IsEmpty(input[p][q]), input[p][q], input[p][0])

	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)
End

static Function NoConcatenationOfOperations()

	string win

	win = GetDataBrowserWithData()

	TestOperationMinMaxHelper(win, "{\"+\":[1,{\"+\":[2,{\"+\":[3,4]}]}]}", "1+2+3+4", 1 + 2 + 3 + 4)
	TestOperationMinMaxHelper(win, "{\"-\":[{\"-\":[{\"-\":[1,2]},3]},4]}", "1-2-3-4", 1 - 2 - 3 - 4)
	TestOperationMinMaxHelper(win, "{\"/\":[{\"/\":[{\"/\":[1,2]},3]},4]}", "1/2/3/4", 1 / 2 / 3 / 4)
	TestOperationMinMaxHelper(win, "{\"*\":[1,{\"*\":[2,{\"*\":[3,4]}]}]}", "1*2*3*4", 1 * 2 * 3 * 4)
End

// + > - > * > /
static Function orderOfCalculation()

	string win

	win = GetDataBrowserWithData()

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
	TestOperationMinMaxHelper(win, "{\"+\":[{\"+\":[{\"*\":[5,1]},{\"*\":[2,3]}]},{\"+\":[4,{\"*\":[5,20]}]}]}", "5*1+2*3+4+5*20", 5 * 1 + 2 * 3 + 4 + 5 * 20)
End

static Function TestSigns()

	string win

	win = GetDataBrowserWithData()

	// using as sign after primitive operation
	TestOperationMinMaxHelper(win, "{\"+\":[1,1]}", "+1++1", +1 + (+1))
	TestOperationMinMaxHelper(win, "{\"+\":[1,-1]}", "+1+-1", +1 + -1)
	TestOperationMinMaxHelper(win, "{\"+\":[-1,1]}", "-1++1", -1 + (+1))
	TestOperationMinMaxHelper(win, "{\"+\":[-1,-1]}", "-1+-1", -1 + -1)

	TestOperationMinMaxHelper(win, "{\"-\":[1,1]}", "+1-+1", +1 - +1)
	TestOperationMinMaxHelper(win, "{\"-\":[1,-1]}", "+1--1", +1 - (-1))
	TestOperationMinMaxHelper(win, "{\"-\":[-1,1]}", "-1-+1", -1 - +1)
	TestOperationMinMaxHelper(win, "{\"-\":[-1,-1]}", "-1--1", -1 - (-1))

	TestOperationMinMaxHelper(win, "{\"*\":[1,1]}", "+1*+1", +1 * +1)
	TestOperationMinMaxHelper(win, "{\"*\":[1,-1]}", "+1*-1", +1 * -1)
	TestOperationMinMaxHelper(win, "{\"*\":[-1,1]}", "-1*+1", -1 * +1)
	TestOperationMinMaxHelper(win, "{\"*\":[-1,-1]}", "-1*-1", -1 * -1)

	TestOperationMinMaxHelper(win, "{\"/\":[1,1]}", "+1/+1", +1 / +1)
	TestOperationMinMaxHelper(win, "{\"/\":[1,-1]}", "+1/-1", +1 / -1)
	TestOperationMinMaxHelper(win, "{\"/\":[-1,1]}", "-1/+1", -1 / +1)
	TestOperationMinMaxHelper(win, "{\"/\":[-1,-1]}", "-1/-1", -1 / -1)
End

static Function TestSigns2()

	variable jsonID0, jsonID1

	jsonID0 = JSON_Parse("[1,1]")
	jsonID1 = DirectToFormulaParser("[+1,+1]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1,-1]")
	jsonID1 = DirectToFormulaParser("[+1,-1]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[-1,1]")
	jsonID1 = DirectToFormulaParser("[-1,+1]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[-1,-1]")
	jsonID1 = DirectToFormulaParser("[-1,-1]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)
End

static Function TestSigns3()

	variable jsonID0, jsonID1

	jsonID0 = JSON_Parse("[-1,-1]")
	jsonID1 = DirectToFormulaParser("[ -1,-1]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[-1,-1], -1]")
	jsonID1 = DirectToFormulaParser("[[\r -1,\r -1], -1]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[1,1], 1]")
	jsonID1 = DirectToFormulaParser("[[\r +1,\r +1], +1]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("{\"-\":[-1,-1]}")
	jsonID1 = DirectToFormulaParser("(\r -1)\r --1")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("{\"+\":[-1,-1]}")
	jsonID1 = DirectToFormulaParser("(\r -1)\r +-1")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("{\"+\":[1,1]}")
	jsonID1 = DirectToFormulaParser("(\r +1)\r ++1")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("{\"*\":[-1,[1]]}")
	jsonID1 = DirectToFormulaParser("-[1]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("{\"-\":[[1],{\"*\":[-1,[1]]}]}")
	jsonID1 = DirectToFormulaParser("[1]--[1]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1]")
	jsonID1 = DirectToFormulaParser("+[1]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("{\"-\":[[1],[1]]}")
	jsonID1 = DirectToFormulaParser("[1]-+[1]")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)
End

static Function TestSigns4()

	string win

	win = GetDataBrowserWithData()

	// using as sign for operations
	TestOperationMinMaxHelper(win, "{\"max\":[1]}", "+max(1)", 1)
	TestOperationMinMaxHelper(win, "{\"*\":[-1,{\"max\":[1]}]}", "-max(1)", -1)
	TestOperationMinMaxHelper(win, "{\"+\":[{\"max\":[1]},{\"max\":[1]}]}", "+max(1)++max(1)", 2)
	TestOperationMinMaxHelper(win, "{\"+\":[{\"max\":[1]},{\"*\":[-1,{\"max\":[1]}]}]}", "+max(1)+-max(1)", 0)
	TestOperationMinMaxHelper(win, "[{\"*\":[-1,{\"max\":[1]}]}]", "[-max(1)]", -1)
	TestOperationMinMaxHelper(win, "{\"*\":[-1,{\"max\":[1]}]}", "(-max(1))", -1)
End

// UTF_TD_GENERATOR DataGenerators#InvalidInputs
static Function TestInvalidInput([string str])

	try
		DirectToFormulaParser(str)
		FAIL()
	catch
		PASS()
	endtry
End

static Function brackets()

	string win

	win = GetDataBrowserWithData()

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

	variable jsonID0, jsonID1

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

	// failures that have to SFH_ASSERT
	FailFormula("1]")
	FailFormula("[1")
	FailFormula("0[1]")
	FailFormula("[1]2")
	FailFormula("[0,[1]2]")
	FailFormula("[0[1],2]")
End

static Function whiteSpace()

	variable jsonID0, jsonID1

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

Function CheckEqualFormulas(string ref, string formula)

	variable jsonID0, jsonID1

	jsonID0 = JSON_Parse(ref)
	jsonID1 = DirectToFormulaParser(formula)
	CHECK_EQUAL_JSON(jsonID0, jsonID1)
End

Function/WAVE FakeSweepDataGeneratorAPF0(WAVE sweep, variable numChannels)

	variable pnts = 9

	Redimension/D/N=(pnts, numChannels) sweep
	sweep[0][] = 10
	sweep[1][] = 20
	sweep[2][] = 30
	sweep[3][] = 10
	sweep[4][] = 20
	sweep[5][] = 30
	sweep[6][] = 10
	sweep[7][] = 20
	sweep[8][] = 30

	SetScale x, 0, 0, "ms", sweep

	return sweep
End

Function/WAVE FakeSweepDataGeneratorAPF1(WAVE sweep, variable numChannels)

	variable pnts = 9

	Redimension/D/N=(pnts, numChannels) sweep
	sweep[0][] = 30
	sweep[1][] = 10
	sweep[2][] = 30
	sweep[3][] = 10
	sweep[4][] = 30
	sweep[5][] = 10
	sweep[6][] = 30
	sweep[7][] = 10
	sweep[8][] = 30

	SetScale x, 0, 0, "ms", sweep

	return sweep
End

static Function TestPlotting()

	string traces

	variable minimum, maximum, i, pos
	string win, gInfo, tmpStr, refStr

	string sweepBrowser = CreateFakeSweepBrowser_IGNORE()
	DFREF  dfr          = BSP_GetFolder(sweepBrowser, MIES_BSP_PANEL_FOLDER)
	string winBase      = BSP_GetFormulaGraph(sweepBrowser)

	string strArray2D         = "[range(10), range(10,20), range(10), range(10,20)]"
	string strArray1D         = "range(4)"
	string strScale1D         = "time(setscale(range(4),x,1,0.1))"
	string strArray0D         = "1"
	string strCombined        = "[1, 2] vs [3, 4]\rand\r[5, 6] vs [7, 8]\rand\r[9, 10]\rand\r"
	string strCombinedPartial = "[1, 2] vs [1, 2]\rand\r[1?=*, 2] vs [1, 2]"
	string strWith            = "[1, 2] vs [3, 4] \rwith\r[2, 3] vs [3, 4]\rand\r[5, 6]  vs [7, 8] \rwith\r[2, 3] vs [7, 8] \rwith\r[4, 5] vs [7, 8]\rand\r[9, 10]"

	// Reference data waves must be moved out of the working DF for the further tests as
	// calling the FormulaPlotter later kills the working DF
	WAVE globalarray2D = SFE_ExecuteFormula(strArray2D, sweepBrowser, singleResult = 1, useVariables = 0)
	Duplicate/FREE globalarray2D, array2D, array2Dvs, array2DAsX
	JWN_SetStringInWaveNote(array2D, SF_META_FORMULA, strArray2D)
	JWN_SetStringInWaveNote(array2Dvs, SF_META_FORMULA, strArray2D + " ")
	WAVE globalarray1D = SFE_ExecuteFormula(strArray1D, sweepBrowser, singleResult = 1, useVariables = 0)
	Duplicate/FREE globalarray1D, array1D, array1Dvs, array1DAsX
	JWN_SetStringInWaveNote(array1D, SF_META_FORMULA, strArray1D)
	JWN_SetStringInWaveNote(array1Dvs, SF_META_FORMULA, strArray1D + " ")
	WAVE globalarray0D = SFE_ExecuteFormula(strArray0D, sweepBrowser, singleResult = 1, useVariables = 0)
	Duplicate/FREE globalarray0D, array0D
	JWN_SetStringInWaveNote(array0D, SF_META_FORMULA, strArray0D)
	WAVE globalscale1D = SFE_ExecuteFormula(strScale1D, sweepBrowser, singleResult = 1, useVariables = 0)
	Duplicate/FREE globalscale1D, scale1D
	JWN_SetStringInWaveNote(scale1D, SF_META_FORMULA, strScale1D)

	win = winBase + "_#Graph" + "0"

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
	REQUIRE_EQUAL_WAVES(wvX, array2DAsX)
	WAVE wvY = TraceNameToWaveRef(win, StringFromList(0, traces))
	Redimension/N=(-1, 0) wvY
	REQUIRE_EQUAL_WAVES(wvY, array1Dvs)
	[minimum, maximum] = GetAxisRange(win, "bottom", mode = AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array2D))
	REQUIRE_EQUAL_VAR(maximum, WaveMax(array2D))
	[minimum, maximum] = GetAxisRange(win, "left", mode = AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array1D))
	REQUIRE_EQUAL_VAR(maximum, WaveMax(array1D))
	MIES_SF#SF_FormulaPlotter(sweepBrowser, strScale1D + " vs " + strArray2D); DoUpdate
	[minimum, maximum] = GetAxisRange(win, "left", mode = AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(scale1D))
	REQUIRE_CLOSE_VAR(maximum, WaveMax(scale1D))

	// many to one
	MIES_SF#SF_FormulaPlotter(sweepBrowser, strArray2D + " vs " + strArray1D); DoUpdate
	traces = TraceNameList(win, ";", 0x1)
	REQUIRE_EQUAL_VAR(ItemsInList(traces), DimSize(array2D, COLS))
	WAVE wvY = TraceNameToWaveRef(win, StringFromList(0, traces))
	REQUIRE_EQUAL_WAVES(wvY, array2Dvs)
	WAVE wvX = XWaveRefFromTrace(win, StringFromList(0, traces))
	Redimension/N=(-1, 0) wvX
	REQUIRE_EQUAL_WAVES(wvX, array1DAsX)
	[minimum, maximum] = GetAxisRange(win, "bottom", mode = AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array1D))
	REQUIRE_EQUAL_VAR(maximum, WaveMax(array1D))
	[minimum, maximum] = GetAxisRange(win, "left", mode = AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array2D))
	REQUIRE_EQUAL_VAR(maximum, WaveMax(array2D))

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strArray2D + " vs range(3)"); DoUpdate
	traces = TraceNameList(win, ";", 0x1)
	REQUIRE_EQUAL_VAR(ItemsInList(traces), DimSize(array2D, COLS))
	[minimum, maximum] = GetAxisRange(win, "bottom", mode = AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(maximum, array1D[2])

	MIES_SF#SF_FormulaPlotter(sweepBrowser, "time(setscale(range(4),x,1,0.1)) vs [range(10), range(10,20), range(10), range(10,20)]"); DoUpdate
	[minimum, maximum] = GetAxisRange(win, "left", mode = AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(scale1D))
	REQUIRE_CLOSE_VAR(maximum, WaveMax(scale1D))

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strArray1D + " vs " + strArray1D); DoUpdate
	traces = TraceNameList(win, ";", 0x1)
	REQUIRE_EQUAL_VAR(ItemsInList(traces), 1)
	[minimum, maximum] = GetAxisRange(win, "left", mode = AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array1D))
	REQUIRE_CLOSE_VAR(maximum, WaveMax(array1D))
	[minimum, maximum] = GetAxisRange(win, "bottom", mode = AXIS_RANGE_INC_AUTOSCALED)
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
	DFREF dfr = SF_GetBrowserDF(sweepBrowser)

	WAVE wvY0 = GetSweepFormulaY(dfr, 0)
	WAVE wvX0 = GetSweepFormulaX(dfr, 0)
	WAVE wvY1 = GetSweepFormulaY(dfr, 1)
	WAVE wvX1 = GetSweepFormulaX(dfr, 1)
	Make/FREE/D wvY0ref = {{1, 2}}
	CHECK_EQUAL_WAVES(wvY0, wvY0ref, mode = WAVE_DATA)
	Make/FREE/D wvX0ref = {{3, 4}}
	CHECK_EQUAL_WAVES(wvX0, wvX0ref)
	Make/FREE/D wvY1ref = {{5, 6}}
	CHECK_EQUAL_WAVES(wvY1, wvY1ref, mode = WAVE_DATA)
	Make/FREE/D wvX1ref = {{7, 8}}
	CHECK_EQUAL_WAVES(wvX1, wvX1ref)

	win = winBase + "_0"
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)
	KillWindow/Z $win
	win = winBase + "_1"
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)
	KillWindow/Z $win
	win = winBase + "_2"
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)
	KillWindow/Z $win

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
	REQUIRE_EQUAL_VAR(WindowExists(win), 0)

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strCombined, dmMode = SF_DM_SUBWINDOWS); DoUpdate
	win = winBase + "_"
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)
	for(i = 0; i < 4; i += 1)
		gInfo = GuideInfo(win, "HOR" + num2istr(i))
		CHECK_NON_EMPTY_STR(gInfo)
		pos = NumberByKey("RELPOSITION", gInfo)
		CHECK_CLOSE_VAR(pos, i / 3, tol = 0.01)
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
		CHECK_NO_RTE()
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
	WAVE wvY0     = GetSweepFormulaY(dfr, 0)
	WAVE wvX0     = GetSweepFormulaX(dfr, 0)
	WAVE wvY1     = GetSweepFormulaY(dfr, 1)
	WAVE wvX1     = GetSweepFormulaX(dfr, 1)
	WAVE wvY2     = GetSweepFormulaY(dfr, 2)
	WAVE wvX2     = GetSweepFormulaX(dfr, 2)
	WAVE wvY3     = GetSweepFormulaY(dfr, 3)
	WAVE wvX3     = GetSweepFormulaX(dfr, 3)
	WAVE wvY4     = GetSweepFormulaY(dfr, 4)
	WAVE wvX4     = GetSweepFormulaX(dfr, 4)
	WAVE wvY5     = GetSweepFormulaY(dfr, 5)
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
	CHECK_EQUAL_WAVES(wvY0, wvYref, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(wvWin0Y0, wvY0)
	Make/FREE/D wvYref = {{2, 3}}
	CHECK_EQUAL_WAVES(wvY1, wvYref, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(wvWin0Y1, wvY1)
	Make/FREE/D wvYref = {{5, 6}}
	CHECK_EQUAL_WAVES(wvY2, wvYref, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(wvWin1Y0, wvY2)
	Make/FREE/D wvYref = {{2, 3}}
	CHECK_EQUAL_WAVES(wvY3, wvYref, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(wvWin1Y1, wvY3)
	Make/FREE/D wvYref = {{4, 5}}
	CHECK_EQUAL_WAVES(wvY4, wvYref, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(wvWin1Y2, wvY4)
	Make/FREE/D wvYref = {{9, 10}}
	CHECK_EQUAL_WAVES(wvY5, wvYref, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(wvWin2Y0, wvY5)
End

static Function TestPlottingWithTablesSubWindows()

	string win, winBaseTable

	string sweepBrowser = CreateFakeSweepBrowser_IGNORE()
	DFREF  dfr          = BSP_GetFolder(sweepBrowser, MIES_BSP_PANEL_FOLDER)
	string winBase      = MIES_SF#SF_GetFormulaWinNameTemplate(sweepBrowser)

	string strSimpleTable          = "table(1)"
	string strSimpleTableWithTable = "table(1)\rwith\rtable(2)"
	string strSimpleTableWithPlot  = "table(1)\rwith\r2"
	string strSimpleTableVsX       = "table(1) vs 2"
	string strSimpleTableAndTable  = "table(1)\rand\rtable(2)"
	string strSimpleTableAndPlot   = "table(1)\rand\r2"
	string strSimpleTableDataset   = "table(dataset(1,2))"

	winBaseTable = winBase + "table"

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strSimpleTable)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "#Table0"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "#Table1"), 0)
	CHECK_EQUAL_VAR(WindowExists(winBase), 0)
	WAVE wv = WaveRefIndexed(winBaseTable + "#Table0", 0, 3) // data column
	CHECK_EQUAL_WAVES(wv, {{1}}, mode = WAVE_DATA)
	WAVE/Z wv = WaveRefIndexed(winBaseTable + "#Table0", 1, 3)
	CHECK_WAVE(wv, NULL_WAVE)

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strSimpleTableWithTable)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "#Table0"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "#Table1"), 0)
	CHECK_EQUAL_VAR(WindowExists(winBase), 0)
	WAVE wv = WaveRefIndexed(winBaseTable + "#Table0", 0, 3) // data column first table
	CHECK_EQUAL_WAVES(wv, {{1}}, mode = WAVE_DATA)
	WAVE wv = WaveRefIndexed(winBaseTable + "#Table0", 1, 3) // data column second table
	CHECK_EQUAL_WAVES(wv, {{2}}, mode = WAVE_DATA)
	WAVE/Z wv = WaveRefIndexed(winBaseTable + "#Table0", 2, 3)
	CHECK_WAVE(wv, NULL_WAVE)

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strSimpleTableWithPlot)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "#Table0"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "#Table1"), 0)
	CHECK_EQUAL_VAR(WindowExists(winBase), 1)
	CHECK_EQUAL_VAR(WindowExists(winBase + "#Graph0"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBase + "#Graph1"), 0)

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strSimpleTableVsX)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "#Table0"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "#Table1"), 0)
	CHECK_EQUAL_VAR(WindowExists(winBase), 0)

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strSimpleTableAndTable)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "#Table0"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "#Table1"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "#Table2"), 0)
	CHECK_EQUAL_VAR(WindowExists(winBase), 0)
	WAVE wv = WaveRefIndexed(winBaseTable + "#Table0", 0, 3) // data column
	CHECK_EQUAL_WAVES(wv, {{1}}, mode = WAVE_DATA)
	WAVE/Z wv = WaveRefIndexed(winBaseTable + "#Table0", 1, 3)
	CHECK_WAVE(wv, NULL_WAVE)
	WAVE wv = WaveRefIndexed(winBaseTable + "#Table1", 0, 3) // data column
	CHECK_EQUAL_WAVES(wv, {{2}}, mode = WAVE_DATA)
	WAVE/Z wv = WaveRefIndexed(winBaseTable + "#Table1", 1, 3)
	CHECK_WAVE(wv, NULL_WAVE)

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strSimpleTableAndPlot)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "#Table0"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "#Table1"), 0)
	CHECK_EQUAL_VAR(WindowExists(winBase), 1)
	CHECK_EQUAL_VAR(WindowExists(winBase + "#Graph0"), 0)
	CHECK_EQUAL_VAR(WindowExists(winBase + "#Graph1"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBase + "#Graph2"), 0)

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strSimpleTableDataset)
	WAVE wv = WaveRefIndexed(winBaseTable + "#Table0", 0, 3) // data column
	CHECK_EQUAL_WAVES(wv, {{1}}, mode = WAVE_DATA)
	WAVE wv = WaveRefIndexed(winBaseTable + "#Table0", 1, 3) // data column
	CHECK_EQUAL_WAVES(wv, {{2}}, mode = WAVE_DATA)
	WAVE/Z wv = WaveRefIndexed(winBaseTable + "#Table0", 2, 3)
	CHECK_WAVE(wv, NULL_WAVE)

	KillWaves/Z waveWithDimlabels
	Make/N=1 waveWithDimlabels = 1
	SetDimLabel ROWS, 0, LABEL, waveWithDimlabels
	string wPath = GetWavesDataFolder(waveWithDimlabels, 2)
	MIES_SF#SF_FormulaPlotter(sweepBrowser, "table(wave(\"" + wPath + "\"))")
	WAVE wv = WaveRefIndexed(winBaseTable + "#Table0", 0, 3) // dimlabel column
	CHECK_EQUAL_WAVES(wv, {{1}}, mode = WAVE_DATA)
	WAVE wv = WaveRefIndexed(winBaseTable + "#Table0", 1, 3) // data column
	CHECK_EQUAL_WAVES(wv, {{1}}, mode = WAVE_DATA)
	WAVE wv = WaveRefIndexed(winBaseTable + "#Table0", 2, 3) // end of data
	CHECK_WAVE(wv, NULL_WAVE)

	KillWaves/Z waveWithDimlabels
End

static Function TestPlottingWithTablesNormal()

	string win, winBaseTable

	string sweepBrowser = CreateFakeSweepBrowser_IGNORE()
	DFREF  dfr          = BSP_GetFolder(sweepBrowser, MIES_BSP_PANEL_FOLDER)
	string winBase      = MIES_SF#SF_GetFormulaWinNameTemplate(sweepBrowser)

	string strSimpleTable          = "table(1)"
	string strSimpleTableWithTable = "table(1)\rwith\rtable(2)"
	string strSimpleTableWithPlot  = "table(1)\rwith\r2"
	string strSimpleTableVsX       = "table(1) vs 2"
	string strSimpleTableAndTable  = "table(1)\rand\rtable(2)"
	string strSimpleTableAndPlot   = "table(1)\rand\r2"

	winBaseTable = winBase + "table"

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strSimpleTable, dmMode = SF_DM_NORMAL)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable), 0)
	CHECK_EQUAL_VAR(WindowExists(winBase), 0)

	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "0"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "1"), 0)
	CHECK_EQUAL_VAR(WindowExists(winBase + "0"), 0)

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strSimpleTableWithTable, dmMode = SF_DM_NORMAL)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "0"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "1"), 0)
	CHECK_EQUAL_VAR(WindowExists(winBase + "0"), 0)

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strSimpleTableWithPlot, dmMode = SF_DM_NORMAL)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "0"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "1"), 0)
	CHECK_EQUAL_VAR(WindowExists(winBase + "0"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBase + "1"), 0)

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strSimpleTableVsX, dmMode = SF_DM_NORMAL)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "0"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "1"), 0)
	CHECK_EQUAL_VAR(WindowExists(winBase + "1"), 0)

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strSimpleTableAndTable, dmMode = SF_DM_NORMAL)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "0"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "1"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "2"), 0)
	CHECK_EQUAL_VAR(WindowExists(winBase + "0"), 0)

	MIES_SF#SF_FormulaPlotter(sweepBrowser, strSimpleTableAndPlot, dmMode = SF_DM_NORMAL)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "0"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBaseTable + "1"), 0)
	CHECK_EQUAL_VAR(WindowExists(winBase + "0"), 0)
	CHECK_EQUAL_VAR(WindowExists(winBase + "1"), 1)
	CHECK_EQUAL_VAR(WindowExists(winBase + "2"), 0)
End

static Function TestSFPreprocessor()

	string input, output
	string refOutput

	input     = ""
	refOutput = ""
	output    = MIES_SF#SF_PreprocessInput(input)
	CHECK_EQUAL_STR(output, refOutput)

	input     = "\r\r\r"
	refOutput = "\r\r\r"
	output    = MIES_SF#SF_PreprocessInput(input)
	CHECK_EQUAL_STR(output, refOutput)

	input     = "text\rtext\r"
	refOutput = "text\rtext\r"
	output    = MIES_SF#SF_PreprocessInput(input)
	CHECK_EQUAL_STR(output, refOutput)

	input     = "# comment"
	refOutput = ""
	output    = MIES_SF#SF_PreprocessInput(input)
	CHECK_EQUAL_STR(output, refOutput)

	input     = "text#comment"
	refOutput = "text"
	output    = MIES_SF#SF_PreprocessInput(input)
	CHECK_EQUAL_STR(output, refOutput)

	input     = "text####comment"
	refOutput = "text"
	output    = MIES_SF#SF_PreprocessInput(input)
	CHECK_EQUAL_STR(output, refOutput)

	input     = "text####comment#comment#comment##comment"
	refOutput = "text"
	output    = MIES_SF#SF_PreprocessInput(input)
	CHECK_EQUAL_STR(output, refOutput)

	input     = "text#comment\rtext#comment\rtext"
	refOutput = "text\rtext\rtext"
	output    = MIES_SF#SF_PreprocessInput(input)
	CHECK_EQUAL_STR(output, refOutput)
End

// UTF_TD_GENERATOR DataGenerators#SweepFormulaFunctionsWithSweepsArgument
static Function AvoidAssertingOutWithNoSweeps([string str])

	string win, device

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()
	MIES_DB#DB_LockToDevice(win, device)
	win = GetCurrentWindow()

	WAVE/WAVE dataRef = SFE_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(DimSize(dataRef, ROWS), 0)
End

// UTF_TD_GENERATOR DataGenerators#TestHelpNotebookGetter_IGNORE
static Function TestHelpNotebook([string str])

	string browser, headLine, helpText, sfHelpWin

	browser = DB_OpenDataBrowser()

	sfHelpWin = BSP_GetSFHELP(browser)
	headLine  = MIES_BSP#BSP_GetHelpOperationHeadline(str)

	INFO("Op: %s", s0 = str)

	helpText = MIES_BSP#BSP_RetrieveSFHelpTextImpl(sfHelpWin, headLine, "to_top_" + str)
	CHECK_PROPER_STR(helpText)

	CHECK_EQUAL_VAR(DB_SFHelpJumpToLine(headLine), 0)
End

static Function NonExistingOperation()

	string win, str

	win = GetDataBrowserWithData()

	str = "bogusOp(1,2,3)"
	try
		// this is currently caught by an additional check specifically for automated testing
		// but it would also cause an Abort in the main code
		WAVE output = SFE_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function ZeroSizedSubArrayTest()

	STRUCT SF_ExecutionData exd

	exd.graph  = GetDataBrowserWithData()
	exd.jsonId = JSON_Parse("[]")
	WAVE wTextRef = MIES_SFE#SFE_FormulaExecutor(exd)
	CHECK(IsTextWave(wTextRef))
	CHECK_EQUAL_VAR(DimSize(wTextRef, ROWS), 1)
	CHECK_EQUAL_VAR(DimSize(wTextRef, COLS), 0)
	WAVE/WAVE wRefResult = MIES_SF#SF_ResolveDataset(wTextRef)
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

	WAVE/WAVE output = MIES_SFO#SFO_AverageDataOverSweeps(input)
	CHECK_EQUAL_VAR(3, DimSize(output, ROWS))
	WAVE data = output[0]
	Make/FREE dataRef = 2
	CHECK_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA)
	TestAverageOverSweeps_CheckMeta(data, 1, 1, 0)

	WAVE data = output[1]
	Make/FREE dataRef = 4
	CHECK_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA)
	TestAverageOverSweeps_CheckMeta(data, 2, 1, 2)

	WAVE data = output[2]
	Make/FREE dataRef = 6
	CHECK_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA)
	TestAverageOverSweeps_CheckMeta(data, NaN, NaN, NaN)

End

static Function TestLegendShrink()

	string str, result
	string strRef

	str    = "\s(T000000d0_Sweep_0_AD1) Sweep 0 AD1\r\s(T000000d1_Sweep_1_AD1) Sweep 1 AD1\r\s(T000000d2_Sweep_2_AD1) Sweep 2 AD1"
	strref = "\s(T000000d0_Sweep_0_AD1)Sweeps 0-2 AD1"
	result = MIES_SF#SF_ShrinkLegend(str)
	CHECK_EQUAL_STR(strRef, result)

	str    = "\s(T000000d0_Sweep_0_AD1) Sweep 0 AD1\r\s(T000000d1_Sweep_1_AD1) Sweep 1 AD1\r\s(T000000d2_Sweep_2_AD1) Sweep 2 AD2"
	strref = str
	result = MIES_SF#SF_ShrinkLegend(str)
	CHECK_EQUAL_STR(strRef, result)

	str    = "\s(T000000d0_Sweep_0_AD1) Sweep 0 AD1\r\s(T000000d1_Sweep_1_AD1) Sweep 1 AD1\r\s(T000000d2_Sweep_2_AD1) operation Sweep 2 AD1"
	strref = "\s(T000000d0_Sweep_0_AD1)Sweeps 0-1 AD1\r\s(T000000d2_Sweep_2_AD1)operation Sweep 2 AD1"
	result = MIES_SF#SF_ShrinkLegend(str)
	CHECK_EQUAL_STR(strRef, result)

	str    = "\s(T000000d0_Sweep_0_AD1) Sweep 0 AD1\r\s(T000000d1_Sweep_1_AD1) Sweep 1 AD1\r\s(T000000d2_Sweep_2_AD1) Sweep 23 AD1"
	strref = "\s(T000000d0_Sweep_0_AD1)Sweeps 0-1,23 AD1"
	result = MIES_SF#SF_ShrinkLegend(str)
	CHECK_EQUAL_STR(strRef, result)

	str    = "some other Sweep legend"
	strref = str
	result = MIES_SF#SF_ShrinkLegend(str)
	CHECK_EQUAL_STR(strRef, result)
End

static Function BrowserGraphConnectionWorks()

	string formulaGraph, browser, result

	browser = GetDataBrowserWithData()

	formulaGraph = CreateFormulaGraphForBrowser(browser)

	result = SFH_GetBrowserForFormulaGraph(formulaGraph)
	CHECK_EQUAL_STR(result, browser)

	result = SFH_GetFormulaGraphForBrowser(browser)
	CHECK_EQUAL_STR(result, formulaGraph)

	result = SFH_GetFormulaGraphForBrowser("I don't exist")
	CHECK_EMPTY_STR(result)
End

static Function TestArgSetup()

	string win, device, formula, argSetupStack, argSetup, str
	variable numResults, jsonId, jsonId1

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0, sweepGen = FakeSweepDataGeneratorAPF0)
	win = CreateFakeSweepData(win, device, sweepNo = 1, sweepGen = FakeSweepDataGeneratorAPF1)

	formula = "apfrequency(data(select(selrange(cursors(A,B)),selchannels(AD),selsweeps(0,1),selvis(all))), 3, 15, time, normoversweepsmin,time)"
	WAVE/WAVE outputRef = SFE_ExecuteFormula(formula, win, useVariables = 0)
	argSetupStack = JWN_GetStringFromWaveNote(outputRef, SF_META_ARGSETUPSTACK)
	jsonId        = JSON_Parse(argSetupStack)
	CHECK_NEQ_VAR(jsonId, NaN)

	argSetup = JSON_GetString(jsonId, "/0")
	jsonId1  = JSON_Parse(argSetup)
	CHECK_NEQ_VAR(jsonId1, NaN)

	str = JSON_GetString(jsonId1, "/Operation")
	CHECK_EQUAL_STR(str, "data")
	JSON_Release(jsonId1)

	argSetup = JSON_GetString(jsonId, "/1")
	jsonId1  = JSON_Parse(argSetup)
	CHECK_NEQ_VAR(jsonId1, NaN)

	str = JSON_GetString(jsonId1, "/Operation")
	CHECK_EQUAL_STR(str, "apfrequency")
	str = JSON_GetString(jsonId1, "/Level")
	CHECK_EQUAL_STR(str, "15")
	str = JSON_GetString(jsonId1, "/Method")
	CHECK_EQUAL_STR(str, "Instantaneous Pair")
	str = JSON_GetString(jsonId1, "/Normalize")
	CHECK_EQUAL_STR(str, "normoversweepsmin")
	str = JSON_GetString(jsonId1, "/ResultType")
	CHECK_EQUAL_STR(str, "time")
	str = JSON_GetString(jsonId1, "/XAxisType")
	CHECK_EQUAL_STR(str, "time")
	JSON_Release(jsonId1)

	JSON_Release(jsonId)

	Make/FREE/T wAnnotations = {"\s(T000000d0_apfrequency_data_Sweep_0_AD0)apfrequency data Sweeps 0-8,145 AD0", "\s(T000010d0_apfrequency_data_Sweep_0_AD0)apfrequency data Sweeps 0-8,145 AD0"}
	Make/FREE/T formulaArgSetup = {"{\n\"0\": \"{\\n\\\"Operation\\\": \\\"data\\\"\\n}\",\n\"1\": \"{\\n\\\"Level\\\": \\\"100\\\",\\n\\\"Method\\\": \\\"Instantaneous Pair\\\",\\n\\\"Normalize\\\": \\\"normoversweepsavg\\\",\\n\\\"Operation\\\": \\\"apfrequency\\\",\\n\\\"ResultType\\\": \\\"freq\\\",\\n\\\"XAxisType\\\": \\\"count\\\"\\n}\"}", \
	                               "{\n\"0\": \"{\\n\\\"Operation\\\": \\\"data\\\"\\n}\",\n\"1\": \"{\\n\\\"Level\\\": \\\"100\\\",\\n\\\"Method\\\": \\\"Instantaneous Pair\\\",\\n\\\"Normalize\\\": \\\"norminsweepsavg\\\",\\n\\\"Operation\\\": \\\"apfrequency\\\",\\n\\\"ResultType\\\": \\\"time\\\",\\n\\\"XAxisType\\\": \\\"count\\\"\\n}\"}"}
	Make/FREE/T result = {"\s(T000000d0_apfrequency_data_Sweep_0_AD0)apfrequency(Normalize:normoversweepsavg ResultType:freq) data Sweeps 0-8,145 AD0", "\s(T000010d0_apfrequency_data_Sweep_0_AD0)apfrequency(Normalize:norminsweepsavg ResultType:time) data Sweeps 0-8,145 AD0"}
	CHECK_EQUAL_VAR(SFH_EnrichAnnotations(wAnnotations, formulaArgSetup), 1)
	CHECK_EQUAL_WAVES(result, wAnnotations, mode = WAVE_DATA)
End

static Function TestInputCodeCheck()

	string win
	string formula, jsonRef, jsonTxt
	string srcLocPath    = "/graph_0/pair_0/source_location"
	string srcLocPathVar = "/variables"

	win = GetDataBrowserWithData()

	DFREF dfr    = SF_GetBrowserDF(win)
	NVAR  jsonID = $GetSweepFormulaJSONid(dfr)

	formula = "1"
	jsonRef = "{\n\"graph_0\": {\n\"pair_0\": {\n\"formula_y\": 1\n}\n}\n}"
	MIES_SF#SF_CheckInputCode(formula, win)
	JSON_Remove(jsonId, srcLocPath)
	jsonTxt = JSON_Dump(jsonId)
	JSON_Release(jsonId)
	CHECK_EQUAL_STR(jsonRef, jsonTxt)

	formula = "1 vs 1"
	jsonRef = "{\n\"graph_0\": {\n\"pair_0\": {\n\"formula_x\": 1,\n\"formula_y\": 1\n}\n}\n}"
	MIES_SF#SF_CheckInputCode(formula, win)
	JSON_Remove(jsonId, srcLocPath)
	jsonTxt = JSON_Dump(jsonId)
	JSON_Release(jsonId)
	CHECK_EQUAL_STR(jsonRef, jsonTxt)

	formula = "1\rwith\r1 vs 1"
	jsonRef = "{\n\"graph_0\": {\n\"pair_0\": {\n\"formula_y\": 1\n},\n\"pair_1\": {\n\"formula_x\": 1,\n\"formula_y\": 1\n}\n}\n}"
	MIES_SF#SF_CheckInputCode(formula, win)
	JSON_Remove(jsonId, srcLocPath)
	JSON_Remove(jsonId, "/graph_0/pair_1/source_location")
	jsonTxt = JSON_Dump(jsonId)
	JSON_Release(jsonId)
	CHECK_EQUAL_STR(jsonRef, jsonTxt)

	formula = "v = 1\r1"
	jsonRef = "{\n\"graph_0\": {\n\"pair_0\": {\n\"formula_y\": 1\n}\n},\n\"variable:v\": 1\n}"
	MIES_SF#SF_CheckInputCode(formula, win)
	JSON_Remove(jsonId, srcLocPath)
	JSON_Remove(jsonId, srcLocPathVar)
	jsonTxt = JSON_Dump(jsonId)
	JSON_Release(jsonId)
	CHECK_EQUAL_STR(jsonRef, jsonTxt)

	formula = "# comment\r var = 1\r\r $var"
	jsonRef = "{\n\"graph_0\": {\n\"pair_0\": {\n\"formula_y\": \"$var\"\n}\n},\n\"variable:var\": 1\n}"
	MIES_SF#SF_CheckInputCode(formula, win)
	JSON_Remove(jsonId, srcLocPath)
	JSON_Remove(jsonId, srcLocPathVar)
	jsonTxt = JSON_Dump(jsonId)
	JSON_Release(jsonId)
	CHECK_EQUAL_STR(jsonRef, jsonTxt)

	formula = "[*]"
	try
		MIES_SF#SF_CheckInputCode(formula, win)
		FAIL()
	catch
		PASS()
	endtry
End

// IUTF_TD_GENERATOR DataGenerators#SF_TestVariablesGen
static Function TestVariables1([WAVE wv])

	string win, device
	string str, code
	variable dim, i

	WAVE/WAVE wRef = wv

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()
	win           = CreateFakeSweepData(win, device, sweepNo = 0)
	win           = CreateFakeSweepData(win, device, sweepNo = 1)

	WAVE/T formulaAndRest = wRef[0]

	code = MIES_SFE#SFE_ExecuteVariableAssignments(win, formulaAndRest[0])
	CHECK_EQUAL_STR(formulaAndRest[1], code)

	WAVE/T    dimLbl     = wRef[1]
	WAVE/WAVE varStorage = GetSFVarStorage(win)
	CHECK_EQUAL_VAR(DimSize(dimLbl, ROWS), DimSize(varStorage, ROWS))
	i = 0
	for(lbl : dimLbl)
		dim = FindDimLabel(varStorage, ROWS, lbl)
		CHECK_NEQ_VAR(dim, -2)
		CHECK_LT_VAR(dim, DimSize(varStorage, ROWS))
		CHECK_EQUAL_VAR(dim, i)
		WAVE varContent = varStorage[dim]
		WAVE data       = MIES_SF#SF_ResolveDataset(varContent)
		CHECK_GT_VAR(DimSize(data, ROWS), 0)
		i += 1
	endfor

	WAVE/Z refData = wRef[2]
	if(WaveExists(refData))
		WAVE/Z result = SFE_ExecuteFormula(formulaAndRest[0], win, singleresult = 1)
		CHECK_WAVE(result, WaveType(refData, 1))
		CHECK_EQUAL_WAVES(result, refData, mode = WAVE_DATA)
	endif

End

static Function TestVariables2()

	string win, device
	string str, code

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)
	win = CreateFakeSweepData(win, device, sweepNo = 1)
	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)

	// reuse of the same variable name
	str = "c=cursors(A,B)\rC=select(channels(AD),[0,1],all)\rd=data($c,$C)\r\r$d"
	try
		code = MIES_SFE#SFE_ExecuteVariableAssignments(win, str)
		FAIL()
	catch
		PASS()
	endtry

	// variable with invalid expression
	str = "c=[*#]"
	try
		code = MIES_SFE#SFE_ExecuteVariableAssignments(win, str)
		FAIL()
	catch
		PASS()
	endtry

	// No valid varName
	str  = "12c=cursors(A,B)"
	code = MIES_SFE#SFE_ExecuteVariableAssignments(win, str)
	CHECK_EQUAL_STR(str, code)

	// No variables defined
	str  = "cursors(A,B)"
	code = MIES_SFE#SFE_ExecuteVariableAssignments(win, str)
	CHECK_EQUAL_STR(str, code)

	// varName with all chars
	str  = "abcdefghijklmnopqrstuvwxyz0123456789_=cursors(A,B)\r"
	code = MIES_SFE#SFE_ExecuteVariableAssignments(win, str)
	CHECK_EQUAL_STR("", code)

	// WhiteSpaces are ok
	str  = " \ta \t= \tcursors(A,B)\r"
	code = MIES_SFE#SFE_ExecuteVariableAssignments(win, str)
	CHECK_EQUAL_STR("", code)
End

static Function TestDefaultFormula()

	string win, bsPanel, winRec, str

	win     = GetDataBrowserWithData()
	bsPanel = BSP_GetPanel(win)

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_SF", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display")

	CHECK_EQUAL_VAR(stringmatch(WinRecreation("", 0), "*Display*"), 1)
End

static Function TestParseFitConstraints()

	Make/FREE/D/N=0 emptyWave

	[WAVE holdWave, WAVE initialWave] = MIES_SFO#SFO_ParseFitConstraints($"", 0)
	CHECK_EQUAL_WAVES(holdWave, emptyWave)
	CHECK_EQUAL_WAVES(initialWave, emptyWave)

	[WAVE holdWave, WAVE initialWave] = MIES_SFO#SFO_ParseFitConstraints($"", 1)
	CHECK_EQUAL_WAVES(holdWave, {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(initialWave, {NaN}, mode = WAVE_DATA)

	[WAVE holdWave, WAVE initialWave] = MIES_SFO#SFO_ParseFitConstraints({"K0=1.23", "K1=4.56"}, 3)
	CHECK_EQUAL_WAVES(holdWave, {1, 1, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(initialWave, {1.23, 4.56, NaN}, mode = WAVE_DATA, tol = 1e-3)

	// too many elements in constraints wave
	try
		[WAVE holdWave, WAVE initialWave] = MIES_SFO#SFO_ParseFitConstraints({"abcd"}, 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// invalid constraints wave format, as the regexp does not match
	try
		[WAVE holdWave, WAVE initialWave] = MIES_SFO#SFO_ParseFitConstraints({"abcd"}, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// invalid constraints wave format, as the index, K1, is too large
	try
		[WAVE holdWave, WAVE initialWave] = MIES_SFO#SFO_ParseFitConstraints({"K1=1"}, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// invalid constraints wave format, as the value is not a number
	try
		[WAVE holdWave, WAVE initialWave] = MIES_SFO#SFO_ParseFitConstraints({"K0=abcd"}, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

static Function TestOperationOrVariableInArray()

	string win, device, code

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	// operation with simple numeric return - channels returns a (2, 1) array
	// as elements in an outer array -> (2, 1, 2) array
	code = "[selchannels(AD2), selchannels(DA3)]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return

	WAVE arrayNum = output[0]
	Make/FREE/D ref = {{{XOP_CHANNEL_TYPE_ADC, XOP_CHANNEL_TYPE_DAC}}, {{2, 3}}}
	CHECK_EQUAL_WAVES(arrayNum, ref, mode = WAVE_DATA)

	code = "[123, selchannels(DA3)]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return

	WAVE arrayNum = output[0]
	Make/FREE/D ref = {{{123, XOP_CHANNEL_TYPE_DAC}}, {{123, 3}}}
	CHECK_EQUAL_WAVES(arrayNum, ref, mode = WAVE_DATA)

	code = "[selchannels(AD2), 123]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return

	WAVE arrayNum = output[0]
	Make/FREE/D ref = {{{XOP_CHANNEL_TYPE_ADC, 123}}, {{2, 123}}}
	CHECK_EQUAL_WAVES(arrayNum, ref, mode = WAVE_DATA)

	code = "[\"abc\", selchannels(DA3)]"
	try
		WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	code = "[selchannels(DA3), \"abc\"]"
	try
		WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	// operation with simple text return - channels returns a (2, 1) array
	// as elements in an outer array -> (2, 1, 2) array
	code = "[text(123), text(456)]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return

	WAVE/T array = output[0]
	Make/FREE/T refT = {"123.0000000", "456.0000000"}
	CHECK_EQUAL_WAVES(array, refT, mode = WAVE_DATA)

	code = "[\"123\", text(456)]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return

	WAVE/T array = output[0]
	Make/FREE/T refT = {"123", "456.0000000"}
	CHECK_EQUAL_WAVES(array, refT, mode = WAVE_DATA)

	code = "[text(123), \"456\"]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return

	WAVE/T array = output[0]
	Make/FREE/T refT = {"123.0000000", "456"}
	CHECK_EQUAL_WAVES(array, refT, mode = WAVE_DATA)

	code = "[123, text(123)]"
	try
		WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	code = "[text(123), 123]"
	try
		WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	// operation with dataset return
	code = "[dataset(1, \"abcd\"), dataset(2, \"cdef\")]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return
	WAVE/T array = output[0]
	CHECK_WAVE(array, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(array, ROWS), 2) // array elements wrapped

	Make/FREE/T wrap = {array[0]}
	WAVE/WAVE element0 = MIES_SF#SF_ResolveDataset(wrap)
	CHECK_WAVE(element0, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(element0, ROWS), 2)
	CHECK_EQUAL_WAVES(element0[0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(element0[1], {"abcd"}, mode = WAVE_DATA)

	Make/FREE/T wrap = {array[1]}
	WAVE/WAVE element1 = MIES_SF#SF_ResolveDataset(wrap)
	CHECK_WAVE(element1, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(element1, ROWS), 2)
	CHECK_EQUAL_WAVES(element1[0], {2}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(element1[1], {"cdef"}, mode = WAVE_DATA)

	code = "[\"text\", dataset(2, \"cdef\")]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return
	WAVE/T array = output[0]
	CHECK_WAVE(array, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(array, ROWS), 2) // array elements wrapped

	CHECK_EQUAL_STR(array[0], "text")

	Make/FREE/T wrap = {array[1]}
	WAVE/WAVE element1 = MIES_SF#SF_ResolveDataset(wrap)
	CHECK_WAVE(element1, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(element1, ROWS), 2)
	CHECK_EQUAL_WAVES(element1[0], {2}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(element1[1], {"cdef"}, mode = WAVE_DATA)

	code = "[dataset(1, \"abcd\"), \"text\"]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return
	WAVE/T array = output[0]
	CHECK_WAVE(array, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(array, ROWS), 2) // array elements wrapped

	Make/FREE/T wrap = {array[0]}
	WAVE/WAVE element0 = MIES_SF#SF_ResolveDataset(wrap)
	CHECK_WAVE(element0, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(element0, ROWS), 2)
	CHECK_EQUAL_WAVES(element0[0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(element0[1], {"abcd"}, mode = WAVE_DATA)

	CHECK_EQUAL_STR(array[1], "text")

	code = "[123, dataset(1, \"abcd\")]"
	try
		WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	code = "[dataset(1, \"abcd\"), 123]"
	try
		WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	// with variables
	code = "var1 = selchannels(AD2)\r[$var1, selchannels(DA3)]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return

	WAVE arrayNum = output[0]
	Make/FREE/D ref = {{{XOP_CHANNEL_TYPE_ADC, XOP_CHANNEL_TYPE_DAC}}, {{2, 3}}}
	CHECK_EQUAL_WAVES(arrayNum, ref, mode = WAVE_DATA)

	code = "var1 = selchannels(DA3)\r[selchannels(AD2), $var1]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return

	WAVE arrayNum = output[0]
	Make/FREE/D ref = {{{XOP_CHANNEL_TYPE_ADC, XOP_CHANNEL_TYPE_DAC}}, {{2, 3}}}
	CHECK_EQUAL_WAVES(arrayNum, ref, mode = WAVE_DATA)

	code = "var1 = selchannels(AD2)\r[$var1, 123]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return

	WAVE arrayNum = output[0]
	Make/FREE/D ref = {{{XOP_CHANNEL_TYPE_ADC, 123}}, {{2, 123}}}
	CHECK_EQUAL_WAVES(arrayNum, ref, mode = WAVE_DATA)

	code = "var1 = selchannels(DA3)\r[123, $var1]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return

	WAVE arrayNum = output[0]
	Make/FREE/D ref = {{{123, XOP_CHANNEL_TYPE_DAC}}, {{123, 3}}}
	CHECK_EQUAL_WAVES(arrayNum, ref, mode = WAVE_DATA)

	code = "var1 = selchannels(DA3)\r[$var1, \"abc\"]"
	try
		WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
		FAIL()
	catch
		PASS()
	endtry

	code = "var1 = selchannels(DA3)\r[\"abc\", $var1]"
	try
		WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
		FAIL()
	catch
		PASS()
	endtry

	code = "var1 = text(123)\r[$var1, text(456)]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return

	WAVE/T array = output[0]
	Make/FREE/T refT = {"123.0000000", "456.0000000"}
	CHECK_EQUAL_WAVES(array, refT, mode = WAVE_DATA)

	code = "var1 = text(456)\r[text(123), $var1]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return

	WAVE/T array = output[0]
	Make/FREE/T refT = {"123.0000000", "456.0000000"}
	CHECK_EQUAL_WAVES(array, refT, mode = WAVE_DATA)

	code = "var1 = text(123)\r[$var1, \"456\"]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return

	WAVE/T array = output[0]
	Make/FREE/T refT = {"123.0000000", "456"}
	CHECK_EQUAL_WAVES(array, refT, mode = WAVE_DATA)

	code = "var1 = text(456)\r[\"123\", $var1]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return

	WAVE/T array = output[0]
	Make/FREE/T refT = {"123", "456.0000000"}
	CHECK_EQUAL_WAVES(array, refT, mode = WAVE_DATA)

	code = "var1 = text(123)\r[$var1, 456]"
	try
		WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
		FAIL()
	catch
		PASS()
	endtry

	code = "var1 = text(123)\r[123, $var1]"
	try
		WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
		FAIL()
	catch
		PASS()
	endtry

	code = "var1 = dataset(1, \"abcd\")\r[$var1, dataset(2, \"cdef\")]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return
	WAVE/T array = output[0]
	CHECK_WAVE(array, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(array, ROWS), 2) // array elements wrapped

	Make/FREE/T wrap = {array[0]}
	WAVE/WAVE element0 = MIES_SF#SF_ResolveDataset(wrap)
	CHECK_WAVE(element0, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(element0, ROWS), 2)
	CHECK_EQUAL_WAVES(element0[0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(element0[1], {"abcd"}, mode = WAVE_DATA)

	Make/FREE/T wrap = {array[1]}
	WAVE/WAVE element1 = MIES_SF#SF_ResolveDataset(wrap)
	CHECK_WAVE(element1, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(element1, ROWS), 2)
	CHECK_EQUAL_WAVES(element1[0], {2}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(element1[1], {"cdef"}, mode = WAVE_DATA)

	code = "var1 = dataset(2, \"cdef\")\r[dataset(1, \"abcd\"), $var1]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return
	WAVE/T array = output[0]
	CHECK_WAVE(array, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(array, ROWS), 2) // array elements wrapped

	Make/FREE/T wrap = {array[0]}
	WAVE/WAVE element0 = MIES_SF#SF_ResolveDataset(wrap)
	CHECK_WAVE(element0, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(element0, ROWS), 2)
	CHECK_EQUAL_WAVES(element0[0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(element0[1], {"abcd"}, mode = WAVE_DATA)

	Make/FREE/T wrap = {array[1]}
	WAVE/WAVE element1 = MIES_SF#SF_ResolveDataset(wrap)
	CHECK_WAVE(element1, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(element1, ROWS), 2)
	CHECK_EQUAL_WAVES(element1[0], {2}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(element1[1], {"cdef"}, mode = WAVE_DATA)

	code = "var1 = dataset(2, \"cdef\")\r[\"text\", $var1]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return
	WAVE/T array = output[0]
	CHECK_WAVE(array, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(array, ROWS), 2) // array elements wrapped

	CHECK_EQUAL_STR(array[0], "text")

	Make/FREE/T wrap = {array[1]}
	WAVE/WAVE element1 = MIES_SF#SF_ResolveDataset(wrap)
	CHECK_WAVE(element1, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(element1, ROWS), 2)
	CHECK_EQUAL_WAVES(element1[0], {2}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(element1[1], {"cdef"}, mode = WAVE_DATA)

	code = "var1 = dataset(1, \"abcd\")\r[$var1, \"text\"]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return
	WAVE/T array = output[0]
	CHECK_WAVE(array, TEXT_WAVE)
	CHECK_EQUAL_VAR(DimSize(array, ROWS), 2) // array elements wrapped

	Make/FREE/T wrap = {array[0]}
	WAVE/WAVE element0 = MIES_SF#SF_ResolveDataset(wrap)
	CHECK_WAVE(element0, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(element0, ROWS), 2)
	CHECK_EQUAL_WAVES(element0[0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(element0[1], {"abcd"}, mode = WAVE_DATA)

	CHECK_EQUAL_STR(array[1], "text")

	code = "var1 = dataset(1, \"abcd\")\r[123, $var1]"
	try
		WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
		FAIL()
	catch
		PASS()
	endtry

	code = "var1 = dataset(1, \"abcd\")\r[$var1, 123]"
	try
		WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
		FAIL()
	catch
		PASS()
	endtry
End

static Function CheckMixingNonFiniteAndText()

	string win, device, code

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	code = "[abc,abc]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return
	WAVE/T array = output[0]
	Make/FREE/T refT = {"abc", "abc"}
	CHECK_EQUAL_WAVES(array, refT, mode = WAVE_DATA)

	code = "[inf,abc]"
	try
		WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	code = "[abc,inf]"
	try
		WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	code = "[inf,inf]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return
	WAVE/T array = output[0]
	CHECK_EQUAL_WAVES(array, {Inf, Inf}, mode = WAVE_DATA)

	code = "[inf,-INF, NAN, -nan]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return
	WAVE/T array = output[0]
	CHECK_EQUAL_WAVES(array, {Inf, -Inf, NaN, NaN}, mode = WAVE_DATA)
End

static Function CheckAddArraysInArray()

	string win, device, code

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	code = "[[1, 2] + [3, 4] + 1]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return
	WAVE/T array = output[0]
	Make/FREE ref = {{5}, {7}}
	CHECK_EQUAL_WAVES(array, ref, mode = WAVE_DATA)

	code = "[selsweeps() + [3, 4] + 1]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return
	WAVE/T array = output[0]
	Make/FREE ref = {{4}, {5}}
	CHECK_EQUAL_WAVES(array, ref, mode = WAVE_DATA)

	code = "[[dataset(dataset(1) + [3, 4] + 1) + dataset(2) + [5, 6] + 1, dataset(3)] + dataset(4) + [[5, 6],[7,8]] + 1]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return
	WAVE arrayNum = output[0]
	Make/FREE ref = {{{23}, {15}}, {{26}, {16}}}
	CHECK_EQUAL_WAVES(arrayNum, ref, mode = WAVE_DATA)

	code = "var1 = dataset(0)\r[[dataset($var1 + [3, 4] + 1) + $var1 + [5, 6] + 1, $var1] + $var1 + [[5, 6],[7,8]] + 1]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 1)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1) // array return
	WAVE arrayNum = output[0]
	Make/FREE ref = {{{16}, {8}}, {{19}, {9}}}
	CHECK_EQUAL_WAVES(arrayNum, ref, mode = WAVE_DATA)
End

static Function DataTypePromotionInPrimitiveOperations()

	string win, device, code, type

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	code = "max(1,5) + 1"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	type = JWN_GetStringFromWaveNote(output, SF_META_DATATYPE)
	CHECK_EQUAL_STR(type, SF_DATATYPE_MAX)

	code = "max(1,5) - 1"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	type = JWN_GetStringFromWaveNote(output, SF_META_DATATYPE)
	CHECK_EQUAL_STR(type, SF_DATATYPE_MAX)

	code = "max(1,5) * 1"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	type = JWN_GetStringFromWaveNote(output, SF_META_DATATYPE)
	CHECK_EQUAL_STR(type, SF_DATATYPE_MAX)

	code = "max(1,5) / 1"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	type = JWN_GetStringFromWaveNote(output, SF_META_DATATYPE)
	CHECK_EQUAL_STR(type, SF_DATATYPE_MAX)

	code = "max(1,5) + max(1,5)"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	type = JWN_GetStringFromWaveNote(output, SF_META_DATATYPE)
	CHECK_EQUAL_STR(type, SF_DATATYPE_MAX)

	code = "max(1,5) * max(1,5)"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	type = JWN_GetStringFromWaveNote(output, SF_META_DATATYPE)
	CHECK_EQUAL_STR(type, "")

	code = "max(1,5) / max(1,5)"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	type = JWN_GetStringFromWaveNote(output, SF_META_DATATYPE)
	CHECK_EQUAL_STR(type, "")

	code = "max(1,5) + min(1,5)"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	type = JWN_GetStringFromWaveNote(output, SF_META_DATATYPE)
	CHECK_EQUAL_STR(type, "")

	code = "min(1,5) + max(1,5)"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	type = JWN_GetStringFromWaveNote(output, SF_META_DATATYPE)
	CHECK_EQUAL_STR(type, "")
End

static Function HelperMoveDatasetToHigherIfCompatible()

	string win, device, code, type

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	code = "[dataset(1, 2), dataset(3, 4)]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK(SFH_IsArray(output))
	WAVE/WAVE moved = SFH_MoveDatasetHigherIfCompatible(output)
	CHECK_WAVE(moved, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(moved, ROWS), 2)
	WAVE set0 = moved[0]
	Make/FREE/D ref = {1, 3}
	CHECK_EQUAL_WAVES(set0, ref, mode = WAVE_DATA | DIMENSION_SIZES)
	WAVE set1 = moved[1]
	Make/FREE/D ref = {2, 4}
	CHECK_EQUAL_WAVES(set1, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	code = "[dataset(1, 2, 3), dataset(4, 5, 6)]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK(SFH_IsArray(output))
	WAVE/WAVE moved = SFH_MoveDatasetHigherIfCompatible(output)
	CHECK_WAVE(moved, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(moved, ROWS), 3)
	WAVE set0 = moved[0]
	Make/FREE/D ref = {1, 4}
	CHECK_EQUAL_WAVES(set0, ref, mode = WAVE_DATA | DIMENSION_SIZES)
	WAVE set1 = moved[1]
	Make/FREE/D ref = {2, 5}
	CHECK_EQUAL_WAVES(set1, ref, mode = WAVE_DATA | DIMENSION_SIZES)
	WAVE set2 = moved[2]
	Make/FREE/D ref = {3, 6}
	CHECK_EQUAL_WAVES(set2, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	code = "[dataset(1, 2), dataset(3, 4), dataset(5, 6)]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK(SFH_IsArray(output))
	WAVE/WAVE moved = SFH_MoveDatasetHigherIfCompatible(output)
	CHECK_WAVE(moved, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(moved, ROWS), 2)
	WAVE set0 = moved[0]
	Make/FREE/D ref = {1, 3, 5}
	CHECK_EQUAL_WAVES(set0, ref, mode = WAVE_DATA | DIMENSION_SIZES)
	WAVE set1 = moved[1]
	Make/FREE/D ref = {2, 4, 6}
	CHECK_EQUAL_WAVES(set1, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	code = "[dataset([1, 2], [3, 4]), dataset([5, 6], [7, 8])]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK(SFH_IsArray(output))
	WAVE/WAVE moved = SFH_MoveDatasetHigherIfCompatible(output)
	CHECK_WAVE(moved, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(moved, ROWS), 2)
	WAVE set0 = moved[0]
	Make/FREE/D ref = {{1, 5}, {2, 6}}
	CHECK_EQUAL_WAVES(set0, ref, mode = WAVE_DATA | DIMENSION_SIZES)
	WAVE set1 = moved[1]
	Make/FREE/D ref = {{3, 7}, {4, 8}}
	CHECK_EQUAL_WAVES(set1, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	code = "[dataset([a, b], [c, d]), dataset([e, f], [g, h])]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK(SFH_IsArray(output))
	WAVE/WAVE moved = SFH_MoveDatasetHigherIfCompatible(output)
	CHECK_WAVE(moved, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(moved, ROWS), 2)
	WAVE set0 = moved[0]
	Make/FREE/T refT = {{"a", "e"}, {"b", "f"}}
	CHECK_EQUAL_WAVES(set0, refT, mode = WAVE_DATA | DIMENSION_SIZES)
	WAVE set1 = moved[1]
	Make/FREE/T refT = {{"c", "g"}, {"d", "h"}}
	CHECK_EQUAL_WAVES(set1, refT, mode = WAVE_DATA | DIMENSION_SIZES)

	code = "[dataset(1, 2), dataset(3, abc)]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK(SFH_IsArray(output))
	WAVE/WAVE moved = SFH_MoveDatasetHigherIfCompatible(output)
	CHECK(SFH_IsArray(moved))

	code = "[dataset(1, 2), dataset(3, 4, 5)]"
	WAVE/WAVE output = SFE_ExecuteFormula(code, win, useVariables = 0)
	CHECK(SFH_IsArray(output))
	WAVE/WAVE moved = SFH_MoveDatasetHigherIfCompatible(output)
	CHECK(SFH_IsArray(moved))
End

static Function TestVariablePlottingDoesNotModifyData()

	string graphBase, win, graph, code

	code = "data=wave(root:testData)\r$data"

	KillWaves/Z root:testData
	Make/N=10 root:testData

	win = GetDataBrowserWithData()

	graphBase = BSP_GetFormulaGraph(win)
	graph     = graphBase + "_#Graph" + "0"

	ExecuteSweepFormulaCode(win, code)
	REQUIRE_EQUAL_VAR(WindowExists(graph), 1)

	WAVE/WAVE varStorage = GetSFVarStorage(win)
	WAVE/WAVE dataRef    = SFH_AttemptDatasetResolve(WaveText(WaveRef(varStorage, row = FindDimLabel(varStorage, ROWS, "data")), row = 0))
	WAVE      data       = dataRef[0]

	WAVE dataOrig = root:testData
	CHECK_EQUAL_WAVES(dataOrig, data)

	KillWaves/Z root:testData
End

static Function TestVariablePlottingDifferentSubsequentBaseTypes()

	string graphBase, win, graph, code

	KillWaves/Z root:testData
	Make/T root:testData = {"a", "b", "c"}

	code = "data=wave(root:testData)\r$data vs [1,2,3]"

	win       = GetDataBrowserWithData()
	graphBase = BSP_GetFormulaGraph(win)
	graph     = graphBase + "_#Graph" + "0"

	ExecuteSweepFormulaCode(win, code)
	REQUIRE_EQUAL_VAR(WindowExists(graph), 1)
	WAVE/WAVE varStorage = GetSFVarStorage(win)
	WAVE/WAVE dataRef    = SFH_AttemptDatasetResolve(WaveText(WaveRef(varStorage, row = FindDimLabel(varStorage, ROWS, "data")), row = 0))
	WAVE      data       = dataRef[0]
	WAVE/T    dataRT     = root:testData
	CHECK_EQUAL_VAR(WaveRefsEqual(data, dataRT), 1)

	KillWaves/Z root:testData

	Make/N=3 root:testData = p

	code = "data=wave(root:testData)\r$data"
	ExecuteSweepFormulaCode(win, code)

	WAVE/WAVE varStorage = GetSFVarStorage(win)
	WAVE/WAVE dataRef    = SFH_AttemptDatasetResolve(WaveText(WaveRef(varStorage, row = FindDimLabel(varStorage, ROWS, "data")), row = 0))
	WAVE      data       = dataRef[0]
	WAVE      dataRN     = root:testData
	CHECK_EQUAL_VAR(WaveRefsEqual(data, dataRN), 1)

	KillWaves/Z root:testData
End

static Function TestVariableReadOnly()

	string graphBase, win, graph, code
	variable offset = 10

	win       = GetDataBrowserWithData()
	graphBase = BSP_GetFormulaGraph(win)
	graph     = graphBase + "_#Graph" + "0"

	KillWaves/Z root:testData
	Make/N=100 root:testData = p + offset

	code = "data=wave(root:testData)\rpowerspectrum($data)"
	ExecuteSweepFormulaCode(win, code)

	WAVE/WAVE varStorage = GetSFVarStorage(win)
	WAVE/WAVE dataRef    = SFH_AttemptDatasetResolve(WaveText(WaveRef(varStorage, row = FindDimLabel(varStorage, ROWS, "data")), row = 0))
	WAVE      data       = dataRef[0]
	WAVE      dataRN     = root:testData
	CHECK_EQUAL_VAR(WaveRefsEqual(data, dataRN), 1)

	Make/FREE/N=100 refData = p + offset
	CHECK_EQUAL_WAVES(data, refData, mode = WAVE_DATA)

	KillWaves/Z root:testData
End

static Function TestKeepsUnitsWhenMappingMultipleYToOne()

	string win, graph, xAxis, yAxis, code

	win   = GetDataBrowserWithData()
	graph = SFH_GetFormulaGraphForBrowser(win)

	Make/O data1 = {1}
	SetScale/P x, 0, 1, "x1", data1
	SetScale/P y, 0, 1, "y1", data1

	Make/O data2 = {2, 3}
	SetScale/P x, 0, 1, "x2", data2
	SetScale/P y, 0, 1, "y2", data2

	code = "dataset(wave(data1), wave(data1)) vs dataset(wave(data2))"
	ExecuteSweepFormulaCode(win, code)
	yAxis = AxisLabel(graph, "left")
	CHECK_EQUAL_STR(yAxis, "(y1)")
	xAxis = AxisLabel(graph, "bottom")
	CHECK_EQUAL_STR(xAxis, "(x2)")

	KillWaves/Z data1, data2
End

static Function TestAxisLabelGathering()

	string win, graph, xAxis, yAxis, code

	win   = GetDataBrowserWithData()
	graph = SFH_GetFormulaGraphForBrowser(win)

	Make/O data1 = {1}
	SetScale/P x, 0, 1, "x1", data1
	SetScale/P y, 0, 1, "y1", data1

	Make/O data2 = {2}
	SetScale/P x, 0, 1, "x2", data2
	SetScale/P y, 0, 1, "y2", data2

	Make/O data3 = {3}
	SetScale/P x, 0, 1, "x3", data3
	SetScale/P y, 0, 1, "y3", data3

	code = "wave(data1)\r"            + \
	       "with \r"                  + \
	       "wave(data2) vs wave(data3)\r"
	ExecuteSweepFormulaCode(win, code)
	yAxis = AxisLabel(graph, "left")
	CHECK_EQUAL_STR(yAxis, "(y1) / (y2)")
	xAxis = AxisLabel(graph, "bottom")
	CHECK_EQUAL_STR(xAxis, "(x1) / (x3)")

	KillWaves/Z data1, data2, data3
End

static Function TestTraceColor(string graph, string traces, variable index, WAVE colors)

	string info, trace

	trace = StringFromList(index, traces)
	CHECK_PROPER_STR(trace)

	info = TraceInfo(graph, trace, 0)
	CHECK_PROPER_STR(info)

	WAVE traceColors = NumericWaveByKey("rgb(x)", info, keySep = "=", listSep = ";")
	CHECK_EQUAL_WAVES(traceColors, colors, mode = WAVE_DATA)
End

static Function TestTraceColors()

	string win, device, code, graph, winBase, traces, trace, info

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)
	win = CreateFakeSweepData(win, device, sweepNo = 1)

	code    = "data()"
	winBase = ExecuteSweepFormulaCode(win, code)

	graph = winBase + "#Graph0"

	traces = TraceNameList(graph, ";", 1 + 2)
	CHECK_EQUAL_VAR(ItemsInList(traces), 2)

	// these are the per headstage colors
	TestTraceColor(graph, traces, 0, {7967, 7710, 7710})
	TestTraceColor(graph, traces, 1, {60395, 52685, 15934})

	code    = "data(select(selchannels(AD6)))\r with\r data(select(selchannels(AD6)))\r with\r 1"
	winBase = ExecuteSweepFormulaCode(win, code)

	graph = winBase + "#Graph0"

	traces = TraceNameList(graph, ";", 1 + 2)
	CHECK_EQUAL_VAR(ItemsInList(traces), 3)

	// color groups:
	// black
	TestTraceColor(graph, traces, 0, {0, 0, 0})

	// and
	// yellow
	TestTraceColor(graph, traces, 1, {59110, 40863, 0})

	// and red (as default color) as `1` does not have a color group
	TestTraceColor(graph, traces, 2, {65535, 0, 0})
End

// UTF_TD_GENERATOR DataGenerators#DG_SourceLocationsBrackets
static Function TestSourceLocationTrackingBrackets([string str])

	variable sweepNo, numChannels
	string win, device

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	sweepNo = 0
	win     = CreateFakeSweepData(win, device, sweepNo = sweepNo)

	try
		WAVE/WAVE dataWref = SFE_ExecuteFormula(str, win, useVariables = 1)
		FAIL()
	catch
		WAVE/T assertData = GetSFAssertData()
		CHECK_EQUAL_VAR(str2numSafe(assertData[%STEP]), SF_STEP_PARSER)
		CHECK_EQUAL_VAR(str2numSafe(assertData[%INFORMULAOFFSET]), 3)
	endtry
End

static Function TestSourceLocationTrackingVariables()

	variable sweepNo, numChannels
	string win, device, str

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	sweepNo = 0
	win     = CreateFakeSweepData(win, device, sweepNo = sweepNo)

	str = "a = 1 +"
	try
		WAVE/WAVE dataWref = SFE_ExecuteFormula(str, win, useVariables = 1)
		FAIL()
	catch
		WAVE/T assertData = GetSFAssertData()
		CHECK_EQUAL_VAR(str2numSafe(assertData[%STEP]), SF_STEP_PARSER)
		CHECK_EQUAL_STR(assertData[%FORMULA], " 1 +")
		CHECK_EQUAL_VAR(str2numSafe(assertData[%LINE]), 0)
		CHECK_EQUAL_VAR(str2numSafe(assertData[%OFFSET]), 3)
		CHECK_EQUAL_VAR(str2numSafe(assertData[%INFORMULAOFFSET]), 4)
	endtry

	str = "a = [1]a"
	try
		WAVE/WAVE dataWref = SFE_ExecuteFormula(str, win, useVariables = 1)
		FAIL()
	catch
		WAVE/T assertData = GetSFAssertData()
		CHECK_EQUAL_VAR(str2numSafe(assertData[%STEP]), SF_STEP_PARSER)
		CHECK_EQUAL_STR(assertData[%FORMULA], " [1]a")
		CHECK_EQUAL_VAR(str2numSafe(assertData[%LINE]), 0)
		CHECK_EQUAL_VAR(str2numSafe(assertData[%OFFSET]), 3)
		CHECK_EQUAL_VAR(str2numSafe(assertData[%INFORMULAOFFSET]), 4)
	endtry

	str = "a = [a,b,,]"
	try
		WAVE/WAVE dataWref = SFE_ExecuteFormula(str, win, useVariables = 1)
		FAIL()
	catch
		WAVE/T assertData = GetSFAssertData()
		CHECK_EQUAL_VAR(str2numSafe(assertData[%STEP]), SF_STEP_PARSER)
		CHECK_EQUAL_STR(assertData[%FORMULA], " [a,b,,]")
		CHECK_EQUAL_VAR(str2numSafe(assertData[%LINE]), 0)
		CHECK_EQUAL_VAR(str2numSafe(assertData[%OFFSET]), 3)
		CHECK_EQUAL_VAR(str2numSafe(assertData[%INFORMULAOFFSET]), 6)
	endtry

	str = "a = [10,a]"
	try
		WAVE/WAVE dataWref = SFE_ExecuteFormula(str, win, useVariables = 1)
		FAIL()
	catch
		WAVE/T assertData = GetSFAssertData()
		CHECK_EQUAL_VAR(str2numSafe(assertData[%STEP]), SF_STEP_EXECUTOR)
		CHECK_EQUAL_STR(assertData[%FORMULA], " [10,a]")
		CHECK_EQUAL_VAR(str2numSafe(assertData[%LINE]), 0)
		CHECK_EQUAL_VAR(str2numSafe(assertData[%OFFSET]), 3)
		CHECK_EQUAL_VAR(str2numSafe(assertData[%INFORMULAOFFSET]), 5)
	endtry

	str = "a = [[[[[10]]]]]"
	try
		WAVE/WAVE dataWref = SFE_ExecuteFormula(str, win, useVariables = 1)
		FAIL()
	catch
		WAVE/T assertData = GetSFAssertData()
		CHECK_EQUAL_VAR(str2numSafe(assertData[%STEP]), SF_STEP_EXECUTOR)
		CHECK_EQUAL_STR(assertData[%FORMULA], " [[[[[10]]]]]")
		CHECK_EQUAL_VAR(str2numSafe(assertData[%LINE]), 0)
		CHECK_EQUAL_VAR(str2numSafe(assertData[%OFFSET]), 3)
		CHECK_EQUAL_VAR(str2numSafe(assertData[%INFORMULAOFFSET]), 0)
	endtry

	str = "a = selchannels(AB)\r"
	try
		WAVE/WAVE dataWref = SFE_ExecuteFormula(str, win, useVariables = 1)
		FAIL()
	catch
		WAVE/T assertData = GetSFAssertData()
		CHECK_EQUAL_VAR(str2numSafe(assertData[%STEP]), SF_STEP_EXECUTOR)
		CHECK_EQUAL_STR(assertData[%FORMULA], " selchannels(AB)")
		CHECK_EQUAL_VAR(str2numSafe(assertData[%LINE]), 0)
		CHECK_EQUAL_VAR(str2numSafe(assertData[%OFFSET]), 3)
		CHECK_EQUAL_VAR(str2numSafe(assertData[%INFORMULAOFFSET]), 13)
	endtry
End

static Function TestSourceLocationTrackingPosition()

	variable sweepNo, numChannels, paragraph, charposition
	string win, device, str, prefix

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	sweepNo = 0
	win     = CreateFakeSweepData(win, device, sweepNo = sweepNo)
	PGC_SetAndActivateControl(BSP_GetPanel(win), "check_BrowserSettings_SF", val = CHECKBOX_SELECTED)

	prefix = "# comment\ra = 1 # comment\rb  =  2#comment\r\r1\rand\r1\rwith\r1\rand\r 1 +  #comment \r 1 vs 1 + \r"

	str = prefix + "selchannels(AB)"
	SF_SetFormula(win, str)
	PGC_SetAndActivateControl(BSP_GetPanel(win), "button_sweepFormula_display")
	[paragraph, charPosition] = MIES_SF#SF_CalculateErrorLocationInNotebook(win)
	CHECK_EQUAL_VAR(paragraph, 12)
	CHECK_EQUAL_VAR(charPosition, 12)
End

// UTF_TD_GENERATOR DataGenerators#DG_SourceLocationsVarious
static Function TestSourceLocationTrackingPosition2([WAVE/WAVE wv])

	variable sweepNo, numChannels, paragraph, charposition
	string win, device, str, prefix

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	sweepNo = 0
	win     = CreateFakeSweepData(win, device, sweepNo = sweepNo)
	PGC_SetAndActivateControl(BSP_GetPanel(win), "check_BrowserSettings_SF", val = CHECKBOX_SELECTED)

	WAVE   wvPos     = wv[0]
	WAVE/T wvFormula = wv[1]

	prefix = "# comment\ra = 1 # comment\rb  =  2#comment\r\r1\rand\r1\rwith\r1\rand\r 1 +  #comment \r 1 vs 1 + \r"
	str    = prefix + wvFormula[0]
	SF_SetFormula(win, str)
	PGC_SetAndActivateControl(BSP_GetPanel(win), "button_sweepFormula_display")
	[paragraph, charPosition] = MIES_SF#SF_CalculateErrorLocationInNotebook(win)
	CHECK_EQUAL_VAR(charPosition, wvPos[0])
End

// UTF_TD_GENERATOR DataGenerators#DG_SourceLocationsJSON
static Function TestSourceLocationJSON([WAVE/WAVE wv])

	variable sweepNo, numChannels, jsonId
	string win, device, str, prefix, srcPath

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	sweepNo = 0
	win     = CreateFakeSweepData(win, device, sweepNo = sweepNo)
	PGC_SetAndActivateControl(BSP_GetPanel(win), "check_BrowserSettings_SF", val = CHECKBOX_SELECTED)

	WAVE   wvPos     = wv[0]
	WAVE/T wvFormula = wv[1]

	prefix = "# comment\ra = 1 # comment\rb  =  2#comment\r\r1\rand\r1\rwith\r1\rand\r 1 +  #comment \r 1 vs 1 + \r"
	str    = prefix + wvFormula[0]
	SF_SetFormula(win, str)
	PGC_SetAndActivateControl(BSP_GetPanel(win), "button_sweepFormula_check")
	jsonId = ROVar(GetSweepFormulaJSONid(SF_GetBrowserDF(win)))
	CHECK_EQUAL_VAR(JSON_Exists(jsonId, "/variables/source_location/variable:a"), 1)
	CHECK_EQUAL_VAR(JSON_Exists(jsonId, "/variables/source_location/variable:b"), 1)
	CHECK_EQUAL_VAR(JSON_Exists(jsonId, "/graph_2/pair_0/source_location/formula_x"), 1)
	CHECK_EQUAL_VAR(JSON_Exists(jsonId, "/graph_2/pair_0/source_location/formula_y"), 1)

	CHECK_EQUAL_VAR(JSON_Exists(jsonId, "/graph_2/pair_0/source_location/formula_x/source_map"), 1)
	CHECK_EQUAL_VAR(JSON_Exists(jsonId, "/graph_2/pair_0/source_location/formula_x/line"), 1)
	CHECK_EQUAL_VAR(JSON_Exists(jsonId, "/graph_2/pair_0/source_location/formula_x/start_offset"), 1)
	CHECK_EQUAL_VAR(JSON_Exists(jsonId, "/graph_2/pair_0/source_location/formula_x/source"), 1)
	CHECK_EQUAL_VAR(JSON_Exists(jsonId, "/graph_2/pair_0/source_location/formula_x/source_map/"), 1)
	srcPath = SF_EscapeJsonPath("/+")
	CHECK_EQUAL_VAR(JSON_Exists(jsonId, "/graph_2/pair_0/source_location/formula_x/source_map/" + srcPath), 1)
	srcPath = SF_EscapeJsonPath("/+/0")
	CHECK_EQUAL_VAR(JSON_Exists(jsonId, "/graph_2/pair_0/source_location/formula_x/source_map/" + srcPath), 1)
	srcPath = SF_EscapeJsonPath("/+/1")
	CHECK_EQUAL_VAR(JSON_Exists(jsonId, "/graph_2/pair_0/source_location/formula_x/source_map/" + srcPath), 1)
End

// UTF_TD_GENERATOR DataGenerators#DG_SourceLocationsContent
static Function TestSourceLocationContent([WAVE/WAVE wv])

	variable jsonId, size

	WAVE/T wFormula = wv[0]
	WAVE/T wSrcLocs = wv[1]

	[jsonId, WAVE/T srcLocs] = SFP_FormulaParser(wFormula[0], 0)
	JSON_Release(jsonId)
	size = GetNumberFromWaveNote(srcLocs, NOTE_INDEX)
	Redimension/N=(size, -1) srcLocs
	CHECK_EQUAL_WAVES(srcLocs, wSrcLocs, mode = WAVE_DATA)
End
