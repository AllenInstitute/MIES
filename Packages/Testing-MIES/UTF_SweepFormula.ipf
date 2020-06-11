#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3	 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTF_SweepFormula

Function/S CreateFakeSweepBrowser_IGNORE()

	string win

	Display
	win = S_name
	DFREF dfr = GetDataFolderDFR()
	AddVersionToPanel(win, SWEEPBROWSER_PANEL_VERSION)
	BSP_SetFolder(win, dfr, MIES_BSP_PANEL_FOLDER)
	BSP_SetSweepBrowser(win)

	return win
End

/// @brief test two jsonIDs for equal content
static Function WARN_EQUAL_JSON(jsonID0, jsonID1)
	variable jsonID0, jsonID1

	string jsonDump0, jsonDump1

	JSONXOP_Dump/IND=2 jsonID0
	jsonDump0 = S_Value
	JSONXOP_Dump/IND=2 jsonID1
	jsonDump1 = S_Value

	WARN_EQUAL_STR(jsonDump0, jsonDump1)
End

static Function primitiveOperations()
	Variable jsonID0, jsonID1

	jsonID0 = JSON_Parse("null")
	jsonID1 = SF_FormulaParser("")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("1")
	jsonID1 = SF_FormulaParser("1")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 1)

	jsonID0 = JSON_Parse("{\"+\":[1,2]}")
	jsonID1 = SF_FormulaParser("1+2")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 1+2)

	jsonID0 = JSON_Parse("{\"*\":[1,2]}")
	jsonID1 = SF_FormulaParser("1*2")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 1*2)

	jsonID0 = JSON_Parse("{\"-\":[1,2]}")
	jsonID1 = SF_FormulaParser("1-2")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 1-2)

	jsonID0 = JSON_Parse("{\"/\":[1,2]}")
	jsonID1 = SF_FormulaParser("1/2")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 1/2)

	jsonID0 = JSON_Parse("{\"-\":[1]}")
	jsonID1 = SF_FormulaParser("-1")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], -1)

	jsonID0 = JSON_Parse("{\"+\":[1]}")
	jsonID1 = SF_FormulaParser("+1")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], +1)
End

static Function stringHandling()
	Variable jsonID0, jsonID1

	// basic strings
	jsonID0 = JSON_Parse("\"abc\"")
	jsonID1 = SF_FormulaParser("abc")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	// ignore white spaces
	jsonID0 = JSON_Parse("\"abcdef\"")
	jsonID1 = SF_FormulaParser("abc def")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	// allow white space in strings
	jsonID0 = JSON_Parse("\"abc def\"")
	jsonID1 = SF_FormulaParser("\"abc def\"")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	// ignore comments
	jsonID0 = JSON_Parse("null")
	jsonID1 = SF_FormulaParser("# comment")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	// allow # inside strings
	jsonID0 = JSON_Parse("\"#\"")
	jsonID1 = SF_FormulaParser("\"#\"")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	// do not evaluate calculations in strings
	jsonID0 = JSON_Parse("\"1+1\"")
	jsonID1 = SF_FormulaParser("\"1+1\"")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("\"\"")
	jsonID1 = SF_FormulaParser("\"\"")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
End

static Function arrayOperations(array2d, numeric)
	String array2d
	Variable numeric

	Variable jsonID

	WAVE input = JSON_GetWave(JSON_Parse(array2d), "")
	REQUIRE_EQUAL_WAVES(input, SF_FormulaExecutor(SF_FormulaParser(array2d)), mode = WAVE_DATA)

	Duplicate/FREE input input0
	input0[][][][] = input[p][q][r][s] - input[p][q][r][s]
	REQUIRE_EQUAL_WAVES(input0, SF_FormulaExecutor(SF_FormulaParser(array2d + "-" + array2d)), mode = WAVE_DATA)

	Duplicate/FREE input input1
	input1[][][][] = input[p][q][r][s] + input[p][q][r][s]
	REQUIRE_EQUAL_WAVES(input1, SF_FormulaExecutor(SF_FormulaParser(array2d + "+" + array2d)), mode = WAVE_DATA)

	Duplicate/FREE input input2
	input2[][][][] = input[p][q][r][s] / input[p][q][r][s]
	REQUIRE_EQUAL_WAVES(input2, SF_FormulaExecutor(SF_FormulaParser(array2d + "/" + array2d)), mode = WAVE_DATA)

	Duplicate/FREE input input3
	input3[][][][] = input[p][q][r][s] * input[p][q][r][s]
	REQUIRE_EQUAL_WAVES(input3, SF_FormulaExecutor(SF_FormulaParser(array2d + "*" + array2d)), mode = WAVE_DATA)

	Duplicate/FREE input input10
	input10 -= numeric
	REQUIRE_EQUAL_WAVES(input10, SF_FormulaExecutor(SF_FormulaParser(array2d + "-" + num2str(numeric))), mode = WAVE_DATA)
	input10[][][][] = numeric - input[p][q][r][s]
	REQUIRE_EQUAL_WAVES(input10, SF_FormulaExecutor(SF_FormulaParser(num2str(numeric) + "-" + array2d)), mode = WAVE_DATA)

	Duplicate/FREE input input11
	input11 += numeric
	REQUIRE_EQUAL_WAVES(input11, SF_FormulaExecutor(SF_FormulaParser(num2str(numeric) + "+" + array2d)), mode = WAVE_DATA)
	REQUIRE_EQUAL_WAVES(input11, SF_FormulaExecutor(SF_FormulaParser(array2d + "+" + num2str(numeric))), mode = WAVE_DATA)

	Duplicate/FREE input input12
	input12 /= numeric
	REQUIRE_EQUAL_WAVES(input12, SF_FormulaExecutor(SF_FormulaParser(array2d + "/" + num2str(numeric))), mode = WAVE_DATA)
	input12[][][][] = 1 / input12[p][q][r][s]
	REQUIRE_EQUAL_WAVES(input12, SF_FormulaExecutor(SF_FormulaParser(num2str(numeric) + "/" + array2d)), mode = WAVE_DATA)

	Duplicate/FREE input input13
	input13 *= numeric
	REQUIRE_EQUAL_WAVES(input13, SF_FormulaExecutor(SF_FormulaParser(num2str(numeric) + "*" + array2d)), mode = WAVE_DATA)
	REQUIRE_EQUAL_WAVES(input13, SF_FormulaExecutor(SF_FormulaParser(array2d + "*" + num2str(numeric))), mode = WAVE_DATA)
End

static Function primitiveOperations2D()
	arrayOperations("[1,2]", 1)
	arrayOperations("[[1,2],[3,4],[5,6]]", 1)
	arrayOperations("[[1,2],[3,4],[5,6]]", 42)
	arrayOperations("[[1],[3,4],[5,6]]", 1)
	arrayOperations("[[1,2],[3],[5,6]]", 1)
	arrayOperations("[[1,2],[3,4],[5]]", 1)
	arrayOperations("[[1,2],[3,4],[5,6]]", 1.5)
End

static Function concatenationOfOperations()
	Variable jsonID0, jsonID1

	jsonID0 = JSON_Parse("{\"+\":[1,2,3,4]}")
	jsonID1 = SF_FormulaParser("1+2+3+4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 1+2+3+4)

	jsonID0 = JSON_Parse("{\"-\":[1,2,3,4]}")
	jsonID1 = SF_FormulaParser("1-2-3-4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 1-2-3-4)

	jsonID0 = JSON_Parse("{\"/\":[1,2,3,4]}")
	jsonID1 = SF_FormulaParser("1/2/3/4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 1/2/3/4)

	jsonID0 = JSON_Parse("{\"*\":[1,2,3,4]}")
	jsonID1 = SF_FormulaParser("1*2*3*4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 1*2*3*4)
End

// + > - > * > /
static Function orderOfCalculation()
	Variable jsonID0, jsonID1

	// + and -
	jsonID0 = JSON_Parse("{\"+\":[2,{\"-\":[3,4]}]}")
	jsonID1 = SF_FormulaParser("2+3-4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 2+3-4)

	jsonID0 = JSON_Parse("{\"+\":[{\"-\":[2,3]},4]}")
	jsonID1 = SF_FormulaParser("2-3+4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 2-3+4)

	// + and *
	jsonID0 = JSON_Parse("{\"+\":[2,{\"*\":[3,4]}]}")
	jsonID1 = SF_FormulaParser("2+3*4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 2+3*4)

	jsonID0 = JSON_Parse("{\"+\":[{\"*\":[2,3]},4]}")
	jsonID1 = SF_FormulaParser("2*3+4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 2*3+4)

	// + and /
	jsonID0 = JSON_Parse("{\"+\":[2,{\"/\":[3,4]}]}")
	jsonID1 = SF_FormulaParser("2+3/4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 2+3/4)

	jsonID0 = JSON_Parse("{\"+\":[{\"/\":[2,3]},4]}")
	jsonID1 = SF_FormulaParser("2/3+4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 2/3+4)

	// - and *
	jsonID0 = JSON_Parse("{\"-\":[2,{\"*\":[3,4]}]}")
	jsonID1 = SF_FormulaParser("2-3*4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 2-3*4)

	jsonID0 = JSON_Parse("{\"-\":[{\"*\":[2,3]},4]}")
	jsonID1 = SF_FormulaParser("2*3-4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 2*3-4)

	// - and /
	jsonID0 = JSON_Parse("{\"-\":[2,{\"/\":[3,4]}]}")
	jsonID1 = SF_FormulaParser("2-3/4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 2-3/4)

	jsonID0 = JSON_Parse("{\"-\":[{\"/\":[2,3]},4]}")
	jsonID1 = SF_FormulaParser("2/3-4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 2/3-4)

	// * and /
	jsonID0 = JSON_Parse("{\"*\":[2,{\"/\":[3,4]}]}")
	jsonID1 = SF_FormulaParser("2*3/4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 2*3/4)

	jsonID0 = JSON_Parse("{\"*\":[{\"/\":[2,3]},4]}")
	jsonID1 = SF_FormulaParser("2/3*4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 2/3*4)

	jsonID1 = SF_FormulaParser("5*1+2*3+4+5*10")
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 5*1+2*3+4+5*10)
End

static Function brackets()
	Variable jsonID0, jsonID1

	jsonID0 = JSON_Parse("{\"+\":[1,2]}")
	jsonID1 = SF_FormulaParser("(1+2)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 1+2)

	jsonID0 = JSON_Parse("{\"+\":[1,2]}")
	jsonID1 = SF_FormulaParser("((1+2))")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 1+2)

	jsonID0 = JSON_Parse("{\"+\":[{\"+\":[1,2]},{\"+\":[3,4]}]}")
	jsonID1 = SF_FormulaParser("(1+2)+(3+4)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], (1+2)+(3+4))

	jsonID0 = JSON_Parse("{\"+\":[{\"+\":[4,3]},{\"+\":[2,1]}]}")
	jsonID1 = SF_FormulaParser("(4+3)+(2+1)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], (4+3)+(2+1))

	jsonID0 = JSON_Parse("{\"+\":[1,{\"+\":[2,3]},4]}")
	jsonID1 = SF_FormulaParser("1+(2+3)+4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 1+(2+3)+4)

	jsonID0 = JSON_Parse("{\"+\":[{\"*\":[3,2]},1]}")
	jsonID1 = SF_FormulaParser("(3*2)+1")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], (3*2)+1)

	jsonID0 = JSON_Parse("{\"+\":[1,{\"*\":[2,3]}]}")
	jsonID1 = SF_FormulaParser("1+(2*3)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 1+(2*3))

	jsonID0 = JSON_Parse("{\"*\":[{\"+\":[1,2]},3]}")
	jsonID1 = SF_FormulaParser("(1+2)*3")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], (1+2)*3)

	jsonID0 = JSON_Parse("{\"*\":[3,{\"+\":[2,1]}]}")
	jsonID1 = SF_FormulaParser("3*(2+1)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 3*(2+1))

	jsonID0 = JSON_Parse("{\"*\":[{\"/\":[2,{\"+\":[3,4]}]},5]}")
	jsonID1 = SF_FormulaParser("2/(3+4)*5")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 2/(3+4)*5)

	jsonID1 = SF_FormulaParser("5*(1+2)*3/(4+5*10)")
	REQUIRE_CLOSE_VAR(SF_FormulaExecutor(jsonID1)[0], 5*(1+2)*3/(4+5*10))
End

static Function array()
	Variable jsonID0, jsonID1

	jsonID0 = JSON_Parse("[1]")
	jsonID1 = SF_FormulaParser("[1]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1,2,3]")
	jsonID1 = SF_FormulaParser("1,2,3")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID1 = SF_FormulaParser("[1,2,3]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[1,2],3,4]")
	jsonID1 = SF_FormulaParser("[[1,2],3,4]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1,[2,3],4]")
	jsonID1 = SF_FormulaParser("[1,[2,3],4]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1,2,[3,4]]")
	jsonID1 = SF_FormulaParser("[1,2,[3,4]]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[0,1],[1,2],[2,3]]")
	jsonID1 = SF_FormulaParser("[[0,1],[1,2],[2,3]]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[0,1],[2,3],[4,5]]")
	jsonID1 = SF_FormulaParser("[[0,1],[2,3],[4,5]]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[0],[2,3],[4,5]]")
	jsonID1 = SF_FormulaParser("[[0],[2,3],[4,5]]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[0,1],[2],[4,5]]")
	jsonID1 = SF_FormulaParser("[[0,1],[2],[4,5]]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[0,1],[2,3],[5]]")
	jsonID1 = SF_FormulaParser("[[0,1],[2,3],[5]]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1,{\"+\":[2,3]}]")
	jsonID1 = SF_FormulaParser("1,2+3")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[{\"+\":[1,2]},3]")
	jsonID1 = SF_FormulaParser("1+2,3")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1,{\"/\":[5,{\"+\":[6,7]}]}]")
	jsonID1 = SF_FormulaParser("1,5/(6+7)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
End

static Function whiteSpace()
	Variable jsonID0, jsonID1

	jsonID0 = SF_FormulaParser("1+(2*3)")
	jsonID1 = SF_FormulaParser(" 1 + (2 * 3) ")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = SF_FormulaParser("(2+3)")
	jsonID1 = SF_FormulaParser("(2+3)  ")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = SF_FormulaParser("1+(2*3)")
	jsonID1 = SF_FormulaParser("\r1\r+\r(\r2\r*\r3\r)\r")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID1 = SF_FormulaParser("\t1\t+\t(\t2\t*\t3\t)\t")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID1 = SF_FormulaParser("\r\t1+\r\t\t(2*3)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID1 = SF_FormulaParser("\r\t1+\r\t# this is a \t comment\r\t(2*3)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID1 = SF_FormulaParser("\r\t1+\r\t# this is a \t comment\n\t(2*3)#2")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID1 = SF_FormulaParser("# this is a comment which does not calculate 1+1")
	WARN_EQUAL_JSON(JSON_PARSE("null"), jsonID1)
End

// test static Functions with 1..N arguments
static Function minimaximu()
	Variable jsonID0, jsonID1

	jsonID0 = JSON_Parse("{\"min\":[1]}")
	jsonID1 = SF_FormulaParser("min(1)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 1)

	jsonID0 = JSON_Parse("{\"min\":[1,2]}")
	jsonID1 = SF_FormulaParser("min(1,2)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], min(1,2))

	jsonID0 = JSON_Parse("{\"max\":[1,2]}")
	jsonID1 = SF_FormulaParser("max(1,2)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], max(1,2))

	jsonID0 = JSON_Parse("{\"min\":[1,2,3]}")
	jsonID1 = SF_FormulaParser("min(1,2,3)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], min(1,2,3))

	jsonID0 = JSON_Parse("{\"max\":[1,{\"+\":[2,3]}]}")
	jsonID1 = SF_FormulaParser("max(1,(2+3))")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], max(1,(2+3)))

	jsonID0 = JSON_Parse("{\"min\":[{\"-\":[1,2]},3]}")
	jsonID1 = SF_FormulaParser("min((1-2),3)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], min((1-2),3))

	jsonID0 = JSON_Parse("{\"min\":[{\"max\":[1,2]},3]}")
	jsonID1 = SF_FormulaParser("min(max(1,2),3)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], min(max(1,2),3))

	jsonID0 = JSON_Parse("{\"max\":[1,{\"+\":[2,3]},2]}")
	jsonID1 = SF_FormulaParser("max(1,2+3,2)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], max(1,2+3,2))

	jsonID0 = JSON_Parse("{\"max\":[{\"+\":[1,2]},{\"+\":[3,4]},{\"+\":[5,{\"/\":[6,7]}]}]}")
	jsonID1 = SF_FormulaParser("max(1+2,3+4,5+6/7)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], max(1+2,3+4,5+6/7))

	jsonID0 = JSON_Parse("{\"max\":[{\"+\":[1,2]},{\"+\":[3,4]},{\"+\":[5,{\"/\":[6,7]}]}]}")
	jsonID1 = SF_FormulaParser("max(1+2,3+4,5+(6/7))")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], max(1+2,3+4,5+(6/7)))

	jsonID0 = JSON_Parse("{\"max\":[{\"max\":[1,{\"/\":[{\"+\":[2,3]},7]},4]},{\"min\":[3,4]}]}")
	jsonID1 = SF_FormulaParser("max(max(1,(2+3)/7,4),min(3,4))")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], max(max(1,(2+3)/7,4),min(3,4)))

	jsonID0 = JSON_Parse("{\"+\":[{\"max\":[1,2]},1]}")
	jsonID1 = SF_FormulaParser("max(1,2)+1")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], max(1,2)+1)

	jsonID0 = JSON_Parse("{\"+\":[1,{\"max\":[1,2]}]}")
	jsonID1 = SF_FormulaParser("1+max(1,2)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 1+max(1,2))

	jsonID0 = JSON_Parse("{\"+\":[1,{\"max\":[1,2]},1]}")
	jsonID1 = SF_FormulaParser("1+max(1,2)+1")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], 1+max(1,2)+1)

	jsonID0 = JSON_Parse("{\"-\":[{\"max\":[1,2]},{\"max\":[1,2]}]}")
	jsonID1 = SF_FormulaParser("max(1,2)-max(1,2)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[0], max(1,2)-max(1,2))
End

// test static Functions with aribitrary length array returns
static Function merge()
	Variable jsonID0, jsonID1

	jsonID0 = JSON_Parse("{\"merge\":[1,[2,3],4]}")
	jsonID1 = SF_FormulaParser("merge(1,[2,3],4)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[2], 3)
	REQUIRE_EQUAL_VAR(SF_FormulaExecutor(jsonID1)[3], 4)
	WAVE output = SF_FormulaExecutor(jsonID1)
	Make/FREE/N=4/U/I numeric = p + 1
	REQUIRE_EQUAL_WAVES(numeric, output, mode = WAVE_DATA)

	jsonID0 = SF_FormulaParser("[1,2,3,4]")
	jsonID1 = SF_FormulaParser("merge(1,[2,3],4)")
	REQUIRE_EQUAL_WAVES(SF_FormulaExecutor(jsonID0), SF_FormulaExecutor(jsonID1))

	jsonID1 = SF_FormulaParser("merge([1,2],[3,4])")
	REQUIRE_EQUAL_WAVES(SF_FormulaExecutor(jsonID0), SF_FormulaExecutor(jsonID1))

	jsonID1 = SF_FormulaParser("merge(1,2,[3,4])")
	REQUIRE_EQUAL_WAVES(SF_FormulaExecutor(jsonID0), SF_FormulaExecutor(jsonID1))

	jsonID1 = SF_FormulaParser("merge(4/4,4/2,9/3,4*1)")
	REQUIRE_EQUAL_WAVES(SF_FormulaExecutor(jsonID0), SF_FormulaExecutor(jsonID1))
End

static Function MIES_channel()

	Make/FREE input = {{0}, {NaN}}
	SetDimLabel COLS, 0, channelType, input
	SetDimLabel COLS, 1, channelNumber, input
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("channels(AD)"))
	REQUIRE_EQUAL_WAVES(input, output)

	Make/FREE input = {{0}, {0}}
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("channels(AD0)"))
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{0, 0}, {0, 1}}
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("channels(AD0,AD1)"))
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{0, 1}, {0, 1}}
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("channels(AD0,DA1)"))
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{1, 1}, {0, 0}}
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("channels(DA0,DA0)"))
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{0, 1}, {NaN, NaN}}
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("channels(AD,DA)"))
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{2}, {1}}
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("channels(1)"))
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{2, 2}, {1, 3}}
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("channels(1,3)"))
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{0,1,2},{1,2,3}}
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("channels(AD1,DA2,3)"))
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)
End

static Function testDifferentiales()
	Variable jsonID, array
	String str

	// differntiate/integrate 1D waves along rows
	jsonID = SF_FormulaParser("derivative([0,1,4,9,16,25,36,49,64,81])")
	WAVE output = SF_FormulaExecutor(jsonID)
	Make/N=10/U/I/FREE sourcewave = p^2
	Differentiate/EP=0 sourcewave/D=testwave
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	Make/N=10/U/I/FREE input = p^2
	wfprintf str, "%d,", input
	jsonID = SF_FormulaParser("derivative([" + RemoveEnding(str, ",") + "])")
	WAVE output = SF_FormulaExecutor(jsonID)
	Make/N=10/FREE testwave = 2 * p
	Deletepoints 9, 1, testwave, output
	Deletepoints 0, 1, testwave, output
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	Make/N=10/U/I/FREE input = 2 * p
	wfprintf str, "%d,", input
	jsonID = SF_FormulaParser("integrate([" + RemoveEnding(str, ",") + "])")
	WAVE output = SF_FormulaExecutor(jsonID)
	Make/N=10/FREE testwave = p^2
	Deletepoints 9, 1, testwave, output
	Deletepoints 0, 1, testwave, output
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	Make/N=(128)/U/I/FREE input = p
	wfprintf str, "%d,", input
	jsonID = SF_FormulaParser("derivative(integrate([" + RemoveEnding(str, ",") + "]))")
	WAVE output = SF_FormulaExecutor(jsonID)
	Deletepoints 127, 1, input, output
	Deletepoints   0, 1, input, output
	REQUIRE_EQUAL_WAVES(output, input, mode = WAVE_DATA)

	Make/N=(128)/U/I/FREE input = p^2
	wfprintf str, "%d,", input
	jsonID = SF_FormulaParser("integrate(derivative([" + RemoveEnding(str, ",") + "]))")
	WAVE output = SF_FormulaExecutor(jsonID)
	output -= 0.5 // expected end point error from first point estimation
	Deletepoints 127, 1, input, output
	Deletepoints   0, 1, input, output
	REQUIRE_EQUAL_WAVES(output, input, mode = WAVE_DATA)

	// differentiate 2d waves along columns
	Make/N=(128,16)/U/I/FREE input = p + q
	array = JSON_New()
	JSON_AddWave(array, "", input)
	jsonID = SF_FormulaParser("derivative(integrate(" + JSON_Dump(array) + "))")
	JSON_Release(array)
	WAVE output = SF_FormulaExecutor(jsonID)
	Deletepoints/M=(ROWS) 127, 1, input, output
	Deletepoints/M=(ROWS)   0, 1, input, output
	REQUIRE_EQUAL_WAVES(output, input, mode = WAVE_DATA)
End

static Function testArea()
	Variable jsonID, array

	// rectangular triangle has area 1/2 * a * b
	// non-zeroed
	jsonID = SF_FormulaParser("area([0,1,2,3,4], 0)")
	WAVE output = SF_FormulaExecutor(jsonID)
	Make/FREE testwave = {8}
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	// zeroed
	jsonID = SF_FormulaParser("area([0,1,2,3,4], 1)")
	WAVE output = SF_FormulaExecutor(jsonID)
	Make/FREE testwave = {4}
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	// x scaling is taken into account
	jsonID = SF_FormulaParser("area(setscale([0,1,2,3,4], x, 0, 2, unit), 0)")
	WAVE output = SF_FormulaExecutor(jsonID)
	Make/FREE testwave = {16}
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	// does operate column wise
	Make/N=(5, 2) input
	input[][0] = p
	input[][1] = p + 1
	array = JSON_New()
	JSON_AddWave(array, "", input)
	jsonID = SF_FormulaParser("area(" + JSON_Dump(array) + ", 0)")
	JSON_Release(array)
	WAVE output = SF_FormulaExecutor(jsonID)
	// 0th column: see above
	// 1st column: imagine 0...5 and remove 0..1 which gives 12.5 - 0.5
	Make/FREE testwave = {8, 12}
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)
End

static Function waveScaling()
	Make/N=(10) waveX = p
	SetScale x 0, 2, "unit", waveX
	WAVE wv = SF_FormulaExecutor(SF_FormulaParser("setscale([0,1,2,3,4,5,6,7,8,9], x, 0, 2, unit)"))
	REQUIRE_EQUAL_WAVES(waveX, wv, mode = WAVE_DATA)

	Make/N=(10, 10) waveXY = p + q
	SetScale/P x 0, 2, "unitX", waveXY
	SetScale/P y 0, 4, "unitX", waveXY
	WAVE wv = SF_FormulaExecutor(SF_FormulaParser("setscale(setscale([range(10),range(10)+1,range(10)+2,range(10)+3,range(10)+4,range(10)+5,range(10)+6,range(10)+7,range(10)+8,range(10)+9], x, 0, 2, unitX), y, 0, 4, unitX)"))
	REQUIRE_EQUAL_WAVES(waveXY, wv, mode = WAVE_DATA | WAVE_SCALING | DATA_UNITS)
End

static Function arrayExpansion()
	Variable jsonID0, jsonID1

	jsonID0 = SF_FormulaParser("1…10")
	jsonID1 = JSON_Parse("{\"…\":[1,10]}")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	WAVE output = SF_FormulaExecutor(jsonID0)
	Make/N=9/U/I/FREE testwave = 1 + p
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	WAVE output = SF_FormulaExecutor(SF_FormulaParser("range(1,10)"))
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	WAVE output = SF_FormulaExecutor(SF_FormulaParser("range(10)"))
	Make/N=10/U/I/FREE testwave = p
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	WAVE output = SF_FormulaExecutor(SF_FormulaParser("range(1,10,2)"))
	Make/N=5/U/I/FREE testwave = 1 + p * 2
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	WAVE output = SF_FormulaExecutor(SF_FormulaParser("1.5…10.5"))
	Make/N=9/FREE floatwave = 1.5 + p
	REQUIRE_EQUAL_WAVES(output, floatwave, mode = WAVE_DATA)
End

static Function TestFindLevel()

	// requires at least two arguments
	try
		WAVE output = SF_FormulaExecutor(SF_FormulaParser("findlevel()")); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	try
		WAVE output = SF_FormulaExecutor(SF_FormulaParser("findlevel([1])")); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	// but no more than three
	try
		WAVE output = SF_FormulaExecutor(SF_FormulaParser("findlevel([1], 2, 3, 4)")); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	// works
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("findlevel([10, 20, 30, 20], 25)"))
	Make/FREE output_ref = {1.5}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// supports rising edge only
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("findlevel([10, 20, 30, 20], 25, 1)"))
	Make/FREE output_ref = {1.5}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// supports falling edge only
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("findlevel([10, 20, 30, 20], 25, 2)"))
	Make/FREE output_ref = {2.5}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with 2D data
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("findlevel([[10, 10], [20, 20], [30, 30]], 15)"))
	Make/FREE output_ref = {0.5, 0.5}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// returns x coordinates and not indizes
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("findlevel(setscale([[10, 10], [20, 20], [30, 30]], x, 4, 0.5), 15)"))
	Make/FREE output_ref = {4.25, 4.25}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// returns NaN if nothing found
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("findlevel([10, 20, 30, 20], 100)"))
	Make/FREE output_ref = {NaN}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)
End

static Function TestAPFrequency()

	// requires at least one arguments
	try
		WAVE output = SF_FormulaExecutor(SF_FormulaParser("apfrequency()")); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	// but no more than three
	try
		WAVE output = SF_FormulaExecutor(SF_FormulaParser("apfrequency([1], 0, 3, 4)")); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	// requires valid method
	try
		WAVE output = SF_FormulaExecutor(SF_FormulaParser("apfrequency([1], 3)")); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	// works with full
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("apfrequency(setscale([10, 20, 10, 20, 10, 20], x, 0, 5, ms), 0, 15)"))
	Make/FREE/D output_ref = {100}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with apcount
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("apfrequency(setscale([10, 20, 10, 20, 10, 20], x, 0, 5, ms), 2, 15)"))
	Make/FREE/D output_ref = {3}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with 2D data and instantaneous
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("apfrequency(setscale([[10, 5], [20, 40], [10, 5], [20, 30]], x, 0, 5, ms), 0, 15)"))
	Make/FREE/D output_ref = {100, 100}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with instantaneous
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 1, 15)"))
	Make/FREE/D output_ref = {57.14285714285714}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with 2D data and instantaneous
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("apfrequency(setscale([[10, 5], [20, 40], [10, 5], [20, 30]], x, 0, 5, ms), 1, 15)"))
	Make/FREE/D output_ref = {100, 94.59459459459458}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// x offset does not play any role
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("apfrequency(setscale([[10, 5], [20, 40], [10, 5], [20, 30]], x, 0, 5, ms), 1, 15)"))
	Make/FREE/D output_ref = {100, 94.59459459459458}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// returns 0 if nothing found for Full
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("apfrequency([10, 20, 30, 20], 0, 100)"))
	Make/FREE/D output_ref = {0}

	// returns 0 if nothing found for Instantaneous
	WAVE output = SF_FormulaExecutor(SF_FormulaParser("apfrequency([10, 20, 30, 20], 1, 100)"))
	Make/FREE/D output_ref = {0}

	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)
End

static Function waveGetterFunction()
	Make/O/N=(10) wave0 = p

	WAVE wave1 = SF_FormulaExecutor(SF_FormulaParser("wave(wave0)"))
	WAVE wave2 = SF_FormulaExecutor(SF_FormulaParser("range(0,10)"))
	REQUIRE_EQUAL_WAVES(wave0, wave2, mode = WAVE_DATA)
	REQUIRE_EQUAL_WAVES(wave1, wave2, mode = WAVE_DATA)
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

	string func, command, oneDResult, twoDResult
	variable jsonIDOneD, jsonIDTwoD

	func = StringFromList(0, str, ":")
	oneDResult = StringFromList(1, str, ":")
	twoDResult = StringFromList(2, str, ":")

	Make/D/N=5 oneD = p
	Make/D/N=(5, 2) twoD = p + q

	jsonIDOneD = JSON_NEW()
	JSON_AddWave(jsonIDOneD, "", oneD)
	jsonIDTwoD = JSON_NEW()
	JSON_AddWave(jsonIDTwoD, "", twoD)

	// 1D
	WAVE output1D = SF_FormulaExecutor(SF_FormulaParser(func + "(" + JSON_Dump(jsonIDOneD) + ")" ))
	Execute "Make/O output1D_mo = {" + oneDResult + "}"
	WAVE output1D_mo

	CHECK_EQUAL_WAVES(output1D, output1D_mo, mode = WAVE_DATA, tol = 1e-8)

	// 2D
	WAVE output2D = SF_FormulaExecutor(SF_FormulaParser(func + "(" + JSON_Dump(jsonIDTwoD) + ")" ))
	Execute "Make/O output2D_mo = {" + twoDResult + "}"
	WAVE output2D_mo

	CHECK_EQUAL_WAVES(output2D, output2D_mo, mode = WAVE_DATA, tol = 1e-8)
End

static Function TestPlotting()
	String traces

	Variable minimum, maximum
	string sweepBrowser = CreateFakeSweepBrowser_IGNORE()
	String win = BSP_GetFormulaGraph(sweepBrowser)

	String strArray2D = "[range(10), range(10,20), range(10), range(10,20)]"
	String strArray1D = "range(4)"
	String strScale1D = "time(setscale(range(4),x,1,0.1))"
	String strArray0D = "1"

	WAVE array2D = SF_FormulaExecutor(SF_FormulaParser(strArray2D))
	WAVE array1D = SF_FormulaExecutor(SF_FormulaParser(strArray1D))
	WAVE scale1D = SF_FormulaExecutor(SF_FormulaParser(strScale1D))
	WAVE array0D = SF_FormulaExecutor(SF_FormulaParser(strArray0D))

	SF_FormulaPlotter(sweepBrowser, strArray2D)
	REQUIRE_EQUAL_VAR(WindowExists(win), 1)
	traces = TraceNameList(win, ";", 0x1)
	REQUIRE_EQUAL_VAR(ItemsInList(traces), DimSize(array2D, COLS))
	WAVE wvY = TraceNameToWaveRef(win, StringFromList(0, traces))
	REQUIRE_EQUAL_WAVES(array2D, wvY)

	// one to many
	SF_FormulaPlotter(sweepBrowser, strArray1D + " vs " + strArray2D); DoUpdate
	traces = TraceNameList(win, ";", 0x1)
	REQUIRE_EQUAL_VAR(ItemsInList(traces), DimSize(array2D, COLS))
	WAVE wvX = XWaveRefFromTrace(win, StringFromList(0, traces))
	REQUIRE_EQUAL_WAVES(wvX, array2D)
	WAVE wvY = TraceNameToWaveRef(win, StringFromList(0, traces))
	Redimension/N=(-1, 0) wvY
	REQUIRE_EQUAL_WAVES(wvY, array1D)
	GetAxisRange(win, "bottom", minimum, maximum, mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array2D))
	REQUIRE_EQUAL_VAR(maximum, WaveMax(array2D))
	GetAxisRange(win, "left", minimum, maximum, mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array1D))
	REQUIRE_EQUAL_VAR(maximum, WaveMax(array1D))
	SF_FormulaPlotter(sweepBrowser, strScale1D + " vs " + strArray2D); DoUpdate
	GetAxisRange(win, "left", minimum, maximum, mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(scale1D))
	REQUIRE_CLOSE_VAR(maximum, WaveMax(scale1D))

	// many to one
	SF_FormulaPlotter(sweepBrowser, strArray2D + " vs " + strArray1D); DoUpdate
	traces = TraceNameList(win, ";", 0x1)
	REQUIRE_EQUAL_VAR(ItemsInList(traces), DimSize(array2D, COLS))
	WAVE wvY = TraceNameToWaveRef(win, StringFromList(0, traces))
	REQUIRE_EQUAL_WAVES(wvY, array2D)
	WAVE wvX = XWaveRefFromTrace(win, StringFromList(0, traces))
	Redimension/N=(-1, 0) wvX
	REQUIRE_EQUAL_WAVES(wvX, array1D)
	GetAxisRange(win, "bottom", minimum, maximum, mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array1D))
	REQUIRE_EQUAL_VAR(maximum, WaveMax(array1D))
	GetAxisRange(win, "left", minimum, maximum, mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array2D))
	REQUIRE_EQUAL_VAR(maximum, WaveMax(array2D))

	SF_FormulaPlotter(sweepBrowser, strArray2D + " vs range(3)"); DoUpdate
	traces = TraceNameList(win, ";", 0x1)
	REQUIRE_EQUAL_VAR(ItemsInList(traces), DimSize(array2D, COLS))
	GetAxisRange(win, "bottom", minimum, maximum, mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(maximum, array1D[2])

	SF_FormulaPlotter(sweepBrowser, "time(setscale(range(4),x,1,0.1)) vs [range(10), range(10,20), range(10), range(10,20)]"); DoUpdate
	GetAxisRange(win, "left", minimum, maximum, mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(scale1D))
	REQUIRE_CLOSE_VAR(maximum, WaveMax(scale1D))

	SF_FormulaPlotter(sweepBrowser, strArray1D + " vs " + strArray1D); DoUpdate
	traces = TraceNameList(win, ";", 0x1)
	REQUIRE_EQUAL_VAR(ItemsInList(traces), 1)
	GetAxisRange(win, "left", minimum, maximum, mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array1D))
	REQUIRE_CLOSE_VAR(maximum, WaveMax(array1D))
	GetAxisRange(win, "bottom", minimum, maximum, mode=AXIS_RANGE_INC_AUTOSCALED)
	REQUIRE_EQUAL_VAR(minimum, WaveMin(array1D))
	REQUIRE_CLOSE_VAR(maximum, WaveMax(array1D))

	SF_FormulaPlotter(sweepBrowser, strArray2D + " vs " + strArray2D); DoUpdate
	traces = TraceNameList(win, ";", 0x1)
	REQUIRE_EQUAL_VAR(ItemsInList(traces), DimSize(array2D, COLS))

	SF_FormulaPlotter(sweepBrowser, strArray1D + " vs " + strArray1D); DoUpdate
	REQUIRE_EQUAL_VAR(ItemsInList(TraceNameList(win, ";", 0x1)), 1)

	SF_FormulaPlotter(sweepBrowser, strArray1D + " vs " + strArray0D); DoUpdate
	REQUIRE_EQUAL_VAR(ItemsInList(TraceNameList(win, ";", 0x1)), DimSize(array1D, ROWS))

	SF_FormulaPlotter(sweepBrowser, strArray0D + " vs " + strArray1D); DoUpdate
	REQUIRE_EQUAL_VAR(ItemsInList(TraceNameList(win, ";", 0x1)), DimSize(array1D, ROWS))

	SF_FormulaPlotter(sweepBrowser, strArray0D + " vs " + strArray0D); DoUpdate
	REQUIRE_EQUAL_VAR(ItemsInList(TraceNameList(win, ";", 0x1)), DimSize(array0D, ROWS))

	// plotting of unaligned data
	SF_FormulaPlotter(sweepBrowser, "range(10) vs range(5)"); DoUpdate
	REQUIRE_EQUAL_VAR(ItemsInList(TraceNameList(win, ";", 0x1)), floor(10 / 5))
	SF_FormulaPlotter(sweepBrowser, "range(5) vs range(10)"); DoUpdate
	REQUIRE_EQUAL_VAR(ItemsInList(TraceNameList(win, ";", 0x1)), floor(10 / 5))
	SF_FormulaPlotter(sweepBrowser, "range(3) vs range(90)"); DoUpdate
	REQUIRE_EQUAL_VAR(ItemsInList(TraceNameList(win, ";", 0x1)), floor(90 / 3))
	SF_FormulaPlotter(sweepBrowser, "range(3) vs range(7)"); DoUpdate
	REQUIRE_EQUAL_VAR(ItemsInList(TraceNameList(win, ";", 0x1)), floor(7 / 3))
End

Function TestLabNotebook()
	Variable i, j, sweepNumber, channelNumber
	String str, trace, key, name

	Variable numSweeps = 10
	Variable numChannels = 5
	Variable mode = DATA_ACQUISITION_MODE
	String channelType = StringFromList(ITC_XOP_CHANNEL_TYPE_ADC, ITC_CHANNEL_NAMES)
	String win = DATABROWSER_WINDOW_TITLE
	String device = BuildDeviceString(StringFromList(0, DEVICE_TYPES_ITC), StringFromList(0, DEVICE_NUMBERS))

	String channelTypeC = channelType + "C"

	if(windowExists(win))
		DoWindow/K $win
	endif

	Display/N=$win as device
	BSP_SetDataBrowser(win)
	BSP_SetDevice(win, device)

	TUD_Clear(win)

	WAVE/T numericalKeys = GetLBNumericalKeys(device)
	WAVE numericalValues = GetLBNumericalValues(device)
	KillWaves numericalKeys, numericalValues

	Make/FREE/T/N=(1, 1) keys = {{channelTypeC}}
	Make/U/I/N=(numChannels) connections = {7,5,3,1,0}
	Make/U/I/N=(numSweeps, numChannels) channels = q * 2
	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN

	Make/FREE/N=(128, numSweeps, numChannels) input = q + p^r // + gnoise(1)

	for(i = 0; i < numSweeps; i += 1)
		sweepNumber = i
		for(j = 0; j < numChannels; j += 1)
			name = UniqueName("data", 1, 0)
			trace = "trace_" + name
			Extract input, $name, q == i && r == j
			WAVE wv = $name
			AppendToGraph/W=$win wv/TN=$trace
			TUD_SetUserDataFromWaves(win, trace, {"experiment", "fullPath", "traceType", "occurence", "channelType", "channelNumber", "sweepNumber"},         \
						             {"blah", GetWavesDataFolder(wv, 2), "Sweep", "0", channelType, num2str(channels[i][j]), num2str(sweepNumber)})
			values[connections[j]] = channels[i][j]
		endfor

		Redimension/N=(1, 1, LABNOTEBOOK_LAYER_COUNT)/E=1 values
		ED_AddEntriesToLabnotebook(values, keys, sweepNumber, device, mode)
		Redimension/N=(LABNOTEBOOK_LAYER_COUNT)/E=1 values
		ED_AddEntryToLabnotebook(device, keys[0], values, overrideSweepNo = sweepNumber)
	endfor
	ModifyGraph/W=$win log(left)=1

	str = "labnotebook(" + channelTypeC + ",channels(AD),sweeps())"
	WAVE data = SF_FormulaExecutor(SF_FormulaParser(str), graph = win)
	REQUIRE_EQUAL_WAVES(data, channels, mode = WAVE_DATA)

	str = "labnotebook(" + LABNOTEBOOK_USER_PREFIX + channelTypeC + ",channels(AD),sweeps(),UNKNOWN_MODE)"
	WAVE data = SF_FormulaExecutor(SF_FormulaParser(str), graph = win)
	REQUIRE_EQUAL_WAVES(data, channels, mode = WAVE_DATA)

	str = "data(cursors(A,B),channels(AD),sweeps())"
	WAVE data = SF_FormulaExecutor(SF_FormulaParser(str), graph = win)
	REQUIRE_EQUAL_WAVES(input, data, mode = WAVE_DATA)
End
