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

Function [string win, string device] CreateFakeDataBrowserWindow()

	string extWin

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
	TUD_Clear(win)

	NewPanel/EXT=3/HOST=$win/N=$EXT_PANEL_SETTINGSHISTORY
	extWin = win + "#" + EXT_PANEL_SETTINGSHISTORY

	PopupMenu popup_experiment, win=$extWin, value="A;B",mode=1
	PopupMenu popup_device, win=$extWin, value="C;D", mode=2
End

static Function/S CreateFormulaGraphForBrowser(string browser)

	string win

	NewPanel/N=$CleanupName(SF_PLOT_NAME_TEMPLATE, 0)
	win = S_name

	SetWindow $win, userData($SFH_USER_DATA_BROWSER)=browser

	return win
End

/// Add 10 sweeps from various AD/DA channels to the fake databrowser
static Function [variable numSweeps, variable numChannels, WAVE/U/I channels] FillFakeDatabrowserWindow(string win, string device, variable channelTypeNumeric, string lbnTextKey, string lbnTextValue)

	variable i, j, channelNumber, sweepNumber, clampMode
	string name, trace

	numSweeps = 10
	numChannels = 4

	Variable dataSize = 128
	Variable mode = DATA_ACQUISITION_MODE

	String channelType = StringFromList(channelTypeNumeric, XOP_CHANNEL_NAMES)
	String channelTypeC = channelType + "C"

	WAVE/T numericalKeys = GetLBNumericalKeys(device)
	WAVE numericalValues = GetLBNumericalValues(device)
	KillWaves numericalKeys, numericalValues

	Make/FREE/T/N=(1, 1) keys = {{channelTypeC}}
	Make/U/I/N=(numChannels) connections = {7,5,3,1}
	Make/U/I/N=(numSweeps, numChannels) channels = q * 2
	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
	Make/T/FREE/N=(LABNOTEBOOK_LAYER_COUNT) valuesText = lbnTextValue
	Make/FREE/T/N=(1, 1) dacKeys = "DAC"
	Make/FREE/T/N=(1, 1) textKeys = lbnTextKey

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
			clampMode = mod(sweepNumber, 2) ? V_CLAMP_MODE : I_CLAMP_MODE
			Extract input, $name, q == i && r == j
			WAVE wv = $name
			AppendToGraph/W=$win wv/TN=$trace
			channelNumber = channels[i][j]
			TUD_SetUserDataFromWaves(win, trace, {"experiment", "fullPath", "traceType", "occurence", "channelType", "channelNumber", "sweepNumber", "GUIChannelNumber", "clampMode"},         \
									 {"blah", GetWavesDataFolder(wv, 2), "Sweep", "0", channelType, num2str(channelNumber), num2str(sweepNumber), num2istr(channelNumber), num2istr(clampMode)})
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

	return [numSweeps, numChannels, channels]
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
	return MIES_SF#SF_ParseFormulaToJSON(code)
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

static Function TestNonFiniteValues()

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	TestOperationMinMaxHelper(win, "\"inf\"", "inf", +inf)
	TestOperationMinMaxHelper(win, "\"-inf\"", "-inf", -inf)
	TestOperationMinMaxHelper(win, "\"NaN\"", "NaN", NaN)
End

// Fails with Abort
// UTF_TD_GENERATOR NonFiniteValues
//static Function TestNonFiniteValuesPrimitiveOperations([variable var])
//
//	string win, device, str
//
//	[win, device] = CreateFakeDataBrowserWindow()
//
//	str = "\"" + num2str(var) + "\""
//	TestOperationMinMaxHelper(win, "{\"+\":[1," + str + "]}", "1+" + str, 1 + var)
//	TestOperationMinMaxHelper(win, "{\"*\":[1," + str + "]}", "1*" + str, 1 * var)
//	TestOperationMinMaxHelper(win, "{\"-\":[1," + str + "]}", "1-" + str, 1 - var)
//	TestOperationMinMaxHelper(win, "{\"/\":[1," + str + "]}", "1/" + str, 1 / var)
//End

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
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Duplicate/FREE input input0
	input0[][][][] = input[p][q][r][s] - input[p][q][r][s]
	str = array2d + "-" + array2d
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input0, output, mode = WAVE_DATA)

	Duplicate/FREE input input1
	input1[][][][] = input[p][q][r][s] + input[p][q][r][s]
	str = array2d + "+" + array2d
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input1, output, mode = WAVE_DATA)

	Duplicate/FREE input input2
	input2[][][][] = input[p][q][r][s] / input[p][q][r][s]
	str = array2d + "/" + array2d
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input2, output, mode = WAVE_DATA)

	Duplicate/FREE input input3
	input3[][][][] = input[p][q][r][s] * input[p][q][r][s]
	str = array2d + "*" + array2d
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input3, output, mode = WAVE_DATA)

	Duplicate/FREE input input10
	input10 -= numeric
	str = array2d + "-" + num2str(numeric)
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input10, output, mode = WAVE_DATA)
	input10[][][][] = numeric - input[p][q][r][s]
	str = num2str(numeric) + "-" + array2d
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input10, output, mode = WAVE_DATA)

	Duplicate/FREE input input11
	input11 += numeric
	str = array2d + "+" + num2str(numeric)
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input11, output, mode = WAVE_DATA)
	input11[][][][] = numeric + input[p][q][r][s]
	str = num2str(numeric) + "+" + array2d
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input11, output, mode = WAVE_DATA)

	Duplicate/FREE input input12
	input12 /= numeric
	str = array2d + "/" + num2str(numeric)
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input12, output, mode = WAVE_DATA)
	input12[][][][] = numeric / input[p][q][r][s]
	str = num2str(numeric) + "/" + array2d
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input12, output, mode = WAVE_DATA)

	Duplicate/FREE input input13
	input13 *= numeric
	str = array2d + "*" + num2str(numeric)
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input13, output, mode = WAVE_DATA)
	input13[][][][] = numeric * input[p][q][r][s]
	str = num2str(numeric) + "*" + array2d
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
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
	WAVE/T output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)

	WAVE/T input = JSON_GetTextWave(JSON_Parse(str), "")
	// simulate simplified array expansion
	input[][] = SelectString(IsEmpty(input[p][q]), input[p][q], input[p][0])

	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)
End

static Function NoConcatenationOfOperations()

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	TestOperationMinMaxHelper(win, "{\"+\":[1,{\"+\":[2,{\"+\":[3,4]}]}]}", "1+2+3+4", 1 + 2 + 3 + 4)
	TestOperationMinMaxHelper(win, "{\"-\":[{\"-\":[{\"-\":[1,2]},3]},4]}", "1-2-3-4", 1 - 2 - 3 - 4)
	TestOperationMinMaxHelper(win, "{\"/\":[{\"/\":[{\"/\":[1,2]},3]},4]}", "1/2/3/4", 1 / 2 / 3 / 4)
	TestOperationMinMaxHelper(win, "{\"*\":[1,{\"*\":[2,{\"*\":[3,4]}]}]}", "1*2*3*4", 1 * 2 * 3 * 4)
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
	TestOperationMinMaxHelper(win, "{\"+\":[{\"+\":[{\"*\":[5,1]},{\"*\":[2,3]}]},{\"+\":[4,{\"*\":[5,20]}]}]}", "5*1+2*3+4+5*20", 5 * 1 + 2 * 3 + 4 + 5 * 20)
End

static Function TestSigns()

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	// using as sign after primitive operation
	TestOperationMinMaxHelper(win, "{\"+\":[1,1]}", "+1++1", +1+(+1))
	TestOperationMinMaxHelper(win, "{\"+\":[1,-1]}", "+1+-1", +1+-1)
	TestOperationMinMaxHelper(win, "{\"+\":[-1,1]}", "-1++1", -1+(+1))
	TestOperationMinMaxHelper(win, "{\"+\":[-1,-1]}", "-1+-1", -1+-1)

	TestOperationMinMaxHelper(win, "{\"-\":[1,1]}", "+1-+1", +1-+1)
	TestOperationMinMaxHelper(win, "{\"-\":[1,-1]}", "+1--1", +1-(-1))
	TestOperationMinMaxHelper(win, "{\"-\":[-1,1]}", "-1-+1", -1-+1)
	TestOperationMinMaxHelper(win, "{\"-\":[-1,-1]}", "-1--1", -1-(-1))

	TestOperationMinMaxHelper(win, "{\"*\":[1,1]}", "+1*+1", +1*+1)
	TestOperationMinMaxHelper(win, "{\"*\":[1,-1]}", "+1*-1", +1*-1)
	TestOperationMinMaxHelper(win, "{\"*\":[-1,1]}", "-1*+1", -1*+1)
	TestOperationMinMaxHelper(win, "{\"*\":[-1,-1]}", "-1*-1", -1*-1)

	TestOperationMinMaxHelper(win, "{\"/\":[1,1]}", "+1/+1", +1/+1)
	TestOperationMinMaxHelper(win, "{\"/\":[1,-1]}", "+1/-1", +1/-1)
	TestOperationMinMaxHelper(win, "{\"/\":[-1,1]}", "-1/+1", -1/+1)
	TestOperationMinMaxHelper(win, "{\"/\":[-1,-1]}", "-1/-1", -1/-1)
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

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	// using as sign for operations
	TestOperationMinMaxHelper(win, "{\"max\":[1]}", "+max(1)", 1)
	TestOperationMinMaxHelper(win, "{\"*\":[-1,{\"max\":[1]}]}", "-max(1)", -1)
	TestOperationMinMaxHelper(win, "{\"+\":[{\"max\":[1]},{\"max\":[1]}]}", "+max(1)++max(1)", 2)
	TestOperationMinMaxHelper(win, "{\"+\":[{\"max\":[1]},{\"*\":[-1,{\"max\":[1]}]}]}", "+max(1)+-max(1)", 0)
	TestOperationMinMaxHelper(win, "[{\"*\":[-1,{\"max\":[1]}]}]", "[-max(1)]", -1)
	TestOperationMinMaxHelper(win, "{\"*\":[-1,{\"max\":[1]}]}", "(-max(1))", -1)
End

Function/WAVE InvalidInputs()

	Make/FREE/T wt = {",1", " ,1", "1,,", "1, ,", "(1), ,", "1,", "(1),", \
						"1+", "1-", "1*", "1/", "1…", "(1-)", "(1+)", "(1*)", "(1/)", \
						"*1", "*[1]", "*(1)", "(*1)", "[1,*1]", \
						"/1", "/[1]", "/(1)", "(/1)", "[1,/1]", \
						"1**1", "1//1", \
						"*max(1)", "max(1)**max(1)", "/max(1)", "max(1)//max(1)"}

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

	// failures that have to SFH_ASSERT
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
	WAVE data = SF_ExecuteFormula(formula, win, singleResult=1, useVariables=0)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 1)

	if(IsNumericWave(data))
		CHECK_EQUAL_VAR(data[0], refResult)
	else
		WAVE/T dataText = data
		CHECK_EQUAL_STR(dataText[0], num2str(refResult))
	endif
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
		WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	str = "max(wave(" + wavePath + "))"
	try
		WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	str = "avg(wave(" + wavePath + "))"
	try
		WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
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
		WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	str = "text([[5.1234567, 1], [2, 3]])"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE/T refData = {{"5.1234567", "2.0000000"},{"1.0000000", "3.0000000"}}
	REQUIRE_EQUAL_WAVES(refData, output, mode = WAVE_DATA)

	KillWaves/Z testData
	// check copy of wave note on text
	Make/O/D/N=1 testData
	strRef = "WaveNoteCopyTest"
	Note/K testData, strRef
	wavePath = GetWavesDataFolder(testData, 2)
	str = "text(wave(" + wavePath + "))"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	str = note(output)
	CHECK_EQUAL_STR(strRef, str)
End

static Function TestOperationLog()

	string histo, histoAfter, str, strRef
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	str = "log()"
	WAVE/WAVE outputRef = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(DimSize(outputRef, ROWS), 0)

	histo = GetHistoryNotebookText()
	str = "log(1, 10, 100)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	histoAfter = GetHistoryNotebookText()
	Make/FREE/D refData = {1, 10, 100}
	histo = ReplaceString(histo, histoAfter, "")
	REQUIRE_EQUAL_WAVES(refData, output, mode = WAVE_DATA)
	strRef = "  1\r"
	REQUIRE_EQUAL_STR(strRef, histo)

	histo = GetHistoryNotebookText()
	str = "log(a, bb, ccc)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	histoAfter = GetHistoryNotebookText()
	Make/FREE/T refDataT = {"a", "bb", "ccc"}
	histo = ReplaceString(histo, histoAfter, "")
	REQUIRE_EQUAL_WAVES(refDataT, output, mode = WAVE_DATA)
	strRef = "  a\r"
	REQUIRE_EQUAL_STR(strRef, histo)

	str = "log(1)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE wRef = {1}
	CHECK_EQUAL_WAVES(wRef, output, mode=WAVE_DATA | DIMENSION_SIZES)

	str = "log(1, 2)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE wRef = {1, 2}
	CHECK_EQUAL_WAVES(wRef, output, mode=WAVE_DATA | DIMENSION_SIZES)

	Make/O testData = {1, 2}
	str = "log(wave(" + GetWavesDataFolder(testData, 2)  + "))"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Duplicate/FREE testData, refData
	CHECK_EQUAL_WAVES(refData, output, mode=WAVE_DATA | DIMENSION_SIZES)
End

static Function TestOperationButterworth()

	string str, strref, dataType
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	str = "butterworth()"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry
	str = "butterworth(1)"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry
	str = "butterworth(1, 1)"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry
	str = "butterworth(1, 1, 1)"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry
	str = "butterworth(1, 1, 1, 1, 1)"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE/D refData = {0,0.863870777482797,0.235196115045368,0.692708791122301,0.359757805059761,0.602060073208013,0.425726643942363,0.554051807855231}
	str = "butterworth([0,1,0,1,0,1,0,1], 90E3, 100E3, 2)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(refData, output, mode = WAVE_DATA, tol=1E-9)
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables=0)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef = SF_DATATYPE_BUTTERWORTH
	CHECK_EQUAL_STR(strRef, dataType)
End

static Function TestOperationChannels()

	string win, device, str

	[win, device] = CreateFakeDataBrowserWindow()

	Make/FREE input = {{0}, {NaN}}
	SetDimLabel COLS, 0, channelType, input
	SetDimLabel COLS, 1, channelNumber, input
	str = "channels(AD)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input, output)

	Make/FREE input = {{0}, {0}}
	str = "channels(AD0)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{0, 0}, {0, 1}}
	str = "channels(AD0,AD1)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{0, 1}, {0, 1}}
	str = "channels(AD0,DA1)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{1, 1}, {0, 0}}
	str = "channels(DA0,DA0)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{0, 1}, {NaN, NaN}}
	str = "channels(AD,DA)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{NaN}, {1}}
	str = "channels(1)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{NaN, NaN}, {1, 3}}
	str = "channels(1,3)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{0,1,NaN},{1,2,3}}
	str = "channels(AD1,DA2,3)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{NaN}, {NaN}}
	str = "channels()"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	str = "channels(unknown)"
	try
		SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
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
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/N=10/U/I/FREE sourcewave = p^2
	Differentiate/EP=0 sourcewave/D=testwave
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables=0)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef = SF_DATATYPE_DERIVATIVE
	CHECK_EQUAL_STR(strRef, dataType)

	Make/N=10/U/I/FREE input = p^2
	wfprintf str, "%d,", input
	str = "derivative([" + RemoveEnding(str, ",") + "])"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/N=10/FREE testwave = 2 * p
	Deletepoints 9, 1, testwave, output
	Deletepoints 0, 1, testwave, output
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	Make/N=10/U/I/FREE input = 2 * p
	wfprintf str, "%d,", input
	str = "integrate([" + RemoveEnding(str, ",") + "])"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/N=10/FREE testwave = p^2
	Deletepoints 9, 1, testwave, output
	Deletepoints 0, 1, testwave, output
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables=0)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef = SF_DATATYPE_INTEGRATE
	CHECK_EQUAL_STR(strRef, dataType)

	Make/N=(128)/U/I/FREE input = p
	wfprintf str, "%d,", input
	str = "derivative(integrate([" + RemoveEnding(str, ",") + "]))"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Deletepoints 127, 1, input, output
	Deletepoints   0, 1, input, output
	REQUIRE_EQUAL_WAVES(output, input, mode = WAVE_DATA)

	Make/N=(128)/U/I/FREE input = p^2
	wfprintf str, "%d,", input
	str = "integrate(derivative([" + RemoveEnding(str, ",") + "]))"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
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
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
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
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	str = note(output)
	CHECK_EQUAL_STR(strRef, str)

	// check copy of wave note on derivative
	Make/O/D/N=2 testData
	strRef = "WaveNoteCopyTest"
	Note/K testData, strRef
	wavePath = GetWavesDataFolder(testData, 2)
	str = "derivative(wave(" + wavePath + "))"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
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
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE testwave = {8}
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	// zeroed
	str = "area([0,1,2,3,4], 1)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE testwave = {4}
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	// x scaling is taken into account
	str = "area(setscale([0,1,2,3,4], x, 0, 2, unit), 0)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
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

	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	// 0th column: see above
	// 1st column: imagine 0...5 and remove 0..1 which gives 12.5 - 0.5
	Make/FREE testwave = {8, 12}
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	// check meta data
	str = "area([0,1,2,3,4], 0)"
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables=0)
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
	WAVE wv = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/N=(10) waveX = p
	SetScale x, 0, 2, "unit", waveX
	REQUIRE_EQUAL_WAVES(waveX, wv, mode = WAVE_DATA)

	str = "setscale(setscale([range(10),range(10)+1,range(10)+2,range(10)+3,range(10)+4,range(10)+5,range(10)+6,range(10)+7,range(10)+8,range(10)+9], x, 0, 2, unitX), y, 0, 4, unitX)"
	WAVE wv = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/N=(10, 10) waveXY = p + q
	SetScale/P x, 0, 2, "unitX", waveXY
	SetScale/P y, 0, 4, "unitX", waveXY
	REQUIRE_EQUAL_WAVES(waveXY, wv, mode = WAVE_DATA | WAVE_SCALING | DATA_UNITS)

	Make/O/D/N=(2, 2, 2, 2) input = p + 2 * q + 4 * r + 8 * s
	wavePath = GetWavesDataFolder(input, 2)
	refUnit = "unit"
	str = "setscale(wave(" + wavePath + "), z, 0, 2, " + refUnit + ")"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	ref = DimDelta(data, LAYERS)
	REQUIRE_EQUAL_VAR(ref, 2)
	unit = WaveUnits(data, LAYERS)
	REQUIRE_EQUAL_STR(refUnit, unit)

	Make/O/D/N=(2, 2, 2, 2) input = p + 2 * q + 4 * r + 8 * s
	wavePath = GetWavesDataFolder(input, 2)
	refUnit = "unit"
	str = "setscale(wave(" + wavePath + "), t, 0, 2, " + refUnit + ")"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	ref = DimDelta(data, CHUNKS)
	REQUIRE_EQUAL_VAR(ref, 2)
	unit = WaveUnits(data, CHUNKS)
	REQUIRE_EQUAL_STR(refUnit, unit)

	Make/O/D/N=0 input
	wavePath = GetWavesDataFolder(input, 2)
	refUnit = "unit"
	str = "setscale(wave(" + wavePath + "), d, 2, 0, " + refUnit + ")"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
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
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/N=9/U/I/FREE testwave = 1 + p
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	str = "range(1,10)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	str = "range(10)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/N=10/U/I/FREE testwave = p
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	str = "range(1,10,2)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/N=5/U/I/FREE testwave = 1 + p * 2
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	str = "1.5…10.5"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/N=9/FREE floatwave = 1.5 + p
	REQUIRE_EQUAL_WAVES(output, floatwave, mode = WAVE_DATA)

	// check meta data
	str = "range(1,10)"
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables=0)
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
		WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "findlevel([1])"
		WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	// but no more than three
	try
		str = "findlevel([1], 2, 3, 4)"
		WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	// works
	str = "findlevel([10, 20, 30, 20], 25)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE output_ref = {1.5}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// supports rising edge only
	str = "findlevel([10, 20, 30, 20], 25, 1)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE output_ref = {1.5}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// supports falling edge only
	str = "findlevel([10, 20, 30, 20], 25, 2)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE output_ref = {2.5}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// errors out on invalid edge
	try
		str = "findlevel([10, 20, 30, 20], 25, 3)"
		WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	// works with 2D data
	str = "findlevel([[10, 10], [20, 20], [30, 30]], 15)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE output_ref = {0.5, 0.5}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// returns x coordinates and not indizes
	str = "findlevel(setscale([[10, 10], [20, 20], [30, 30]], x, 4, 0.5), 15)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE output_ref = {4.25, 4.25}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// returns NaN if nothing found
	str = "findlevel([10, 20, 30, 20], 100)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE output_ref = {NaN}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// check meta data
	str = "findlevel([10, 20, 30, 20], 25)"
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables=0)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef = SF_DATATYPE_FINDLEVEL
	CHECK_EQUAL_STR(strRef, dataType)
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

	return sweep
End

// IUTF_TD_GENERATOR TestOperationAPFrequency2Gen
static Function TestOperationAPFrequency2([WAVE wv])

	string win, device, formula
	variable numResults

	formula = note(wv)

	[win, device] = CreateFakeDataBrowserWindow()

	CreateFakeSweepData(win, device, sweepNo=0, sweepGen=FakeSweepDataGeneratorAPF0)
	CreateFakeSweepData(win, device, sweepNo=1, sweepGen=FakeSweepDataGeneratorAPF1)

	WAVE/WAVE outputRef = SF_ExecuteFormula(formula, win, useVariables=0)
	numResults = DimSize(wv, ROWS)
	CHECK_EQUAL_VAR(numResults, DimSize(outputRef, ROWS))
	WAVE/WAVE results = wv

	Make/FREE/N=(numResults) idxHelper
	idxHelper = TestOperationAPFrequency2Checks(formula, results[p], outputRef[p])
End

static Function TestOperationAPFrequency2Checks(string formula, WAVE w1, WAVE w2)

	INFO("Formula: %s", s0 = formula)
	REQUIRE_EQUAL_WAVES(w1, w2, mode = WAVE_DATA, tol = 1E-12)
End

static Function TestOperationAPFrequency()

	string str, strRef, dataType
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	// requires at least one arguments
	str = "apfrequency()"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	// but no more than six
	str = "apfrequency([1], 0, 0.5, freq, nonorm, time, 3)"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	// requires valid method
	str = "apfrequency([1], 10)"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	// works with full
	str = "apfrequency(setscale([10, 20, 10, 20, 10, 20], x, 0, 5, ms), 0, 15)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE/D output_ref = {100}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with apcount
	str = "apfrequency(setscale([10, 20, 10, 20, 10, 20], x, 0, 5, ms), 2, 15)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE/D output_ref = {3}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with instantaneous
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 1, 15)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE/D output_ref = {57.14285714285714}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with instantaneous pair
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE/D output_ref = {100 * 2 / 3, 50}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15,freq)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with instantaneous pair time
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15, time)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE/D output_ref = {0.015, 0.02}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15, time, nonorm)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// returns 0 if nothing found for Full
	str = "apfrequency([10, 20, 30, 20], 0, 100)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE/D output_ref = {0}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// returns null wave if nothing found for Instantaneous
	str = "apfrequency([10, 20, 30, 20], 1, 100)"
	WAVE/Z output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	CHECK_WAVE(output, NULL_WAVE)

	// returns null wave if nothing found for Instantaneous Pair
	str = "apfrequency([10, 20, 30, 20], 3, 100)"
	WAVE/Z output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	CHECK_WAVE(output, NULL_WAVE)

	// returns null wave for single peak for Instantaneous Pair
	str = "apfrequency([10, 20, 30, 20], 3, 25)"
	WAVE/Z output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	CHECK_WAVE(output, NULL_WAVE)

	// check meta data
	str = "apfrequency([10, 20, 30, 20], 1, 100)"
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables=0)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef = SF_DATATYPE_APFREQUENCY
	CHECK_EQUAL_STR(strRef, dataType)

	// works with instantaneous pair time, norminsweepsmin
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15, time, norminsweepsmin)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE/D output_ref = {1, 0.02 / 0.015}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with instantaneous pair time, norminsweepsmax
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15, time, norminsweepsmax)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE/D output_ref = {0.015 / 0.02, 1}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with instantaneous pair time, norminsweepsavg
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15, time, norminsweepsavg)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE/D output_ref = {0.015 / 0.0175, 0.02 / 0.0175}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with instantaneous pair time, norminsweepsavg, time as x-axis
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15, time, norminsweepsavg, time)"
	WAVE/WAVE outputRef = SF_ExecuteFormula(str, win, useVariables=0)
	Make/FREE/D output_ref = {2.5, 17.5}
	for(data : outputRef)
		WAVE/Z xValues = JWN_GetNumericWaveFromWaveNote(data, SF_META_XVALUES)
		CHECK_WAVE(xValues, NUMERIC_WAVE)
		CHECK_EQUAL_WAVES(xValues, output_Ref, mode = WAVE_DATA)
	endfor

	// works with instantaneous pair time, norminsweepsavg, count as x-axis
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15, time, norminsweepsavg, count)"
	WAVE/WAVE outputRef = SF_ExecuteFormula(str, win, useVariables=0)
	Make/FREE/D/N=2 output_ref = p
	for(data : outputRef)
		WAVE/Z xValues = JWN_GetNumericWaveFromWaveNote(data, SF_META_XVALUES)
		CHECK_WAVE(xValues, NUMERIC_WAVE)
		CHECK_EQUAL_WAVES(xValues, output_Ref, mode = WAVE_DATA)
	endfor
End

static Function TestOperationWave()

	string str
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	KillWaves/Z wave0
	Make/O/N=(10) wave0 = p

	str = "wave(wave0)"
	WAVE wave1 = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	str = "range(0,10)"
	WAVE wave2 = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(wave0, wave2, mode = WAVE_DATA)
	REQUIRE_EQUAL_WAVES(wave1, wave2, mode = WAVE_DATA)

	str = "wave(does_not_exist)"
	WAVE/Z wave1 = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	CHECK(!WaveExists(wave1))

	str = "wave()"
	WAVE/Z wave1 = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	CHECK(!WaveExists(wave1))
End

static Function/WAVE TestOperationTPBase_TPSS_TPInst_FormulaGetter()

	Make/FREE/T data = {"tpbase;" + SF_DATATYPE_TPBASE, "tpss;" + SF_DATATYPE_TPSS, "tpinst;" + SF_DATATYPE_TPINST}

	return data
End

// UTF_TD_GENERATOR TestOperationTPBase_TPSS_TPInst_FormulaGetter
static Function TestOperationTPBase_TPSS_TPInst([str])
	string str

	string func, formula, strRef, dataType, dataTypeRef
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	func = StringFromList(0, str)
	dataTypeRef = StringFromList(1, str)

	formula = func + "()"
	WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables=0)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 0)
	dataType = JWN_GetStringFromWaveNote(output, SF_META_DATATYPE)
	CHECK_EQUAL_STR(dataTypeRef, dataType)

	try
		formula = func + "(1)"
		WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function CheckTPFitResult(WAVE/WAVE wv, string fit, string result, variable maxLength)

	string dataType, strRef
	variable trailLength

	CHECK_EQUAL_VAR(DimSize(wv, ROWS), 2)
	dataType = JWN_GetStringFromWaveNote(wv, SF_META_DATATYPE)
	strRef = SF_DATATYPE_TPFIT
	CHECK_EQUAL_STR(strRef, dataType)

	WAVE/T part1 = wv[0]
	CHECK_EQUAL_VAR(DimSize(part1, ROWS), 2)

	strRef = part1[%FITFUNCTION]
	CHECK_EQUAL_STR(strRef, fit)
	strRef = part1[%RETURNWHAT]
	CHECK_EQUAL_STR(strRef, result)

	WAVE part2 = wv[1]
	CHECK_EQUAL_VAR(DimSize(part2, ROWS), 1)
	trailLength = part2[%MAXTRAILLENGTH]
	CHECK_EQUAL_VAR(trailLength, maxlength)
End

static Function TestOperationTPfit()

	string formula, strRef, dataType, dataTypeRef
	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	formula = "tpfit(exp,tau)"
	WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables=0)
	CheckTPFitResult(output, "exp", "tau", 250)

	formula = "tpfit(doubleexp,tau)"
	WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables=0)
	CheckTPFitResult(output, "doubleexp", "tau", 250)

	formula = "tpfit(exp,tausmall)"
	WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables=0)
	CheckTPFitResult(output, "exp", "tausmall", 250)

	formula = "tpfit(exp,amp)"
	WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables=0)
	CheckTPFitResult(output, "exp", "amp", 250)

	formula = "tpfit(exp,minabsamp)"
	WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables=0)
	CheckTPFitResult(output, "exp", "minabsamp", 250)

	formula = "tpfit(exp,fitq)"
	WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables=0)
	CheckTPFitResult(output, "exp", "fitq", 250)

	formula = "tpfit(exp,tau,20)"
	WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables=0)
	CheckTPFitResult(output, "exp", "tau", 20)

	try
		formula = "tpfit(exp)"
		WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	try
		formula = "tpfit(exp,tau,250,1)"
		WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	try
		formula = "tpfit(1,tau,250)"
		WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	try
		formula = "tpfit(exp,1,250)"
		WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	try
		formula = "tpfit(exp,tau,tau)"
		WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry
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
	WAVE output1D = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Execute "Make/O output1D_mo = {" + oneDResult + "}"
	WAVE output1D_mo

	CHECK_EQUAL_WAVES(output1D, output1D_mo, mode = WAVE_DATA, tol = 1e-8)

	// 2D
	str = func + "(" + JSON_Dump(jsonIDTwoD) + ")"
	WAVE output2D = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Execute "Make/O output2D_mo = {" + twoDResult + "}"
	WAVE output2D_mo

	CHECK_EQUAL_WAVES(output2D, output2D_mo, mode = WAVE_DATA, tol = 1e-8)
End

static Function TestPlotting()
	String traces

	Variable minimum, maximum, i, pos
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
	string strWith = "[1, 2] vs [3, 4] \rwith\r[2, 3] vs [3, 4]\rand\r[5, 6]  vs [7, 8] \rwith\r[2, 3] vs [7, 8] \rwith\r[4, 5] vs [7, 8]\rand\r[9, 10]"

	// Reference data waves must be moved out of the working DF for the further tests as
	// calling the FormulaPlotter later kills the working DF
	WAVE globalarray2D = SF_ExecuteFormula(strArray2D, sweepBrowser, singleResult=1, useVariables=0)
	Duplicate/FREE globalarray2D, array2D
	WAVE globalarray1D = SF_ExecuteFormula(strArray1D, sweepBrowser, singleResult=1, useVariables=0)
	Duplicate/FREE globalarray1D, array1D
	WAVE globalarray0D = SF_ExecuteFormula(strArray0D, sweepBrowser, singleResult=1, useVariables=0)
	Duplicate/FREE globalarray0D, array0D
	WAVE globalscale1D = SF_ExecuteFormula(strScale1D, sweepBrowser, singleResult=1, useVariables=0)
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

	CreateFakeSweepData(win, device, sweepNo=sweepNo)
	CreateFakeSweepData(win, device, sweepNo=sweepNo + 1)
	CreateFakeSweepData(win, device, sweepNo=sweepNo + 2)
	CreateFakeSweepData(win, device, sweepNo=sweepNo + 3)

	numChannels = 4 // from LBN creation in CreateFakeSweepData->PrepareLBN_IGNORE -> DA2, AD6, DA3, AD7
	Make/FREE/N=0 sweepTemplate
	WAVE sweepRef = FakeSweepDataGeneratorDefault(sweepTemplate, numChannels)

	Make/FREE/N=(4, 3) dataRef
	dataRef[][0] = sweepNo
	dataRef[0, 1][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[2, 3][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7, 2, 3} // AD6, AD7, DA2, DA3
	str = "select(channels(),[" + num2istr(sweepNo) + "],all)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(2, 3) dataRef
	dataRef[][0] = sweepNo
	dataRef[0][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[1][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 2} // AD6, DA2
	str = "select(channels(2, 6),[" + num2istr(sweepNo) + "],all)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(2, 3) dataRef
	dataRef[][0] = sweepNo
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7} // AD6, AD7
	str = "select(channels(AD),[" + num2istr(sweepNo) + "],all)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	// non-existing sweeps are ignored
	str = "select(channels(AD),[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1337) + "],all)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(1, 3) dataRef
	dataRef[][0] = 3
	dataRef[][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[][2] = {0} // DA0 (unassoc)
	str = "select(channels(DA0),[" + num2istr(3) + "],all)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(1, 3) dataRef
	dataRef[][0] = 3
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {1} // AD1 (unassoc)
	str = "select(channels(AD1),[" + num2istr(3) + "],all)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(1, 3) dataRef
	dataRef[][0] = 3
	dataRef[][1] = WhichListItem("TTL", XOP_CHANNEL_NAMES)
	dataRef[][2] = {2} // TTL2
	str = "select(channels(TTL2),[" + num2istr(3) + "],all)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	// clamp mode set filters has no effect on TTL
	str = "select(channels(TTL2),[" + num2istr(3) + "],all,vc)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	// clamp mode set filters on DA/AD
	str = "select(channels(AD1),[" + num2istr(3) + "],all,vc)"
	WAVE/Z data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	CHECK_WAVE(data, NULL_WAVE)
	str = "select(channels(DA0),[" + num2istr(3) + "],all,vc)"
	WAVE/Z data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	CHECK_WAVE(data, NULL_WAVE)

	Make/FREE/N=(4, 3) dataRef
	dataRef[][0] = {sweepNo, sweepNo, sweepNo + 1, sweepNo + 1} // sweep 0, 1 with 2 AD channels each
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7, 6, 7} // AD6, AD7, AD6, AD7
	str = "select(channels(AD),[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "],all)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(2, 3) dataRef
	dataRef[][0] = {sweepNo, sweepNo + 1}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 6} // AD6, AD6
	str = "select(channels(AD6),[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "],all)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(6, 3) dataRef
	dataRef[][0] = {sweepNo, sweepNo, sweepNo, sweepNo + 1, sweepNo + 1, sweepNo + 1}
	chanList = "AD;DA;DA;AD;DA;DA;"
	dataRef[][1] = WhichListItem(StringFromList(p, chanList), XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 2, 3, 6, 2, 3} // AD6, DA2, DA3, AD6, DA2, DA3
	str = "select(channels(AD6, DA),[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "],all)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	// No existing sweeps
	str = "select(channels(AD6, DA),[" + num2istr(sweepNo + 1337) + "],all)"
	WAVE/Z data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE(!WaveExists(data))

	// No existing channels
	str = "select(channels(AD0),[" + num2istr(sweepNo) + "],all)"
	WAVE/Z data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE(!WaveExists(data))

	// Invalid channels
	try
		str = "select([0, 6],[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "],all)"
		WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
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
			TUD_SetUserDataFromWaves(win, trace, {"experiment", "fullPath", "traceType", "occurence", "channelType", "channelNumber", "sweepNumber", "clampMode", "GUIChannelNumber"},         \
									 {"blah", GetWavesDataFolder(wv, 2), "Sweep", "0", StringFromList(j, channelTypeList), StringFromList(j, channelNumberList), num2istr(sweepNo), num2istr(clampMode), StringFromList(j, channelNumberList)})
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
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(4, 3) dataRef
	dataRef[][0] = {sweepNo, sweepNo, sweepNo + 1, sweepNo + 1}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7, 6, 7}
	str = "select(channels(AD),sweeps(),displayed)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "select(channels(AD),sweeps())"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(2, 3) dataRef
	dataRef[][0] = {sweepNo, sweepNo + 1}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 6}
	str = "select(channels(AD6),sweeps(),displayed,all)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(1, 3) dataRef
	dataRef[][0] = {sweepNo}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6}
	str = "select(channels(AD6),sweeps(),displayed, ic)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(1, 3) dataRef
	dataRef[][0] = {sweepNo + 1}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6}
	str = "select(channels(AD6),sweeps(),displayed, vc)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "select(channels(AD6),sweeps(),displayed, izero)"
	WAVE/Z data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	CHECK(!WaveExists(data))

	dataRef[][0] = {sweepNo, sweepNo, sweepNo + 1, sweepNo + 1}
	dataRef[][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[][2] = {2, 3, 2, 3}
	str = "select(channels(DA),sweeps())"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(6, 3) dataRef
	dataRef[][0] = {sweepNo, sweepNo, sweepNo, sweepNo + 1, sweepNo + 1, sweepNo + 1}
	chanList = "AD;AD;DA;AD;AD;DA;"
	dataRef[][1] = WhichListItem(StringFromList(p, chanList), XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7, 2, 6, 7, 2}
	str = "select(channels(DA2, AD),sweeps())" // note: channels are sorted AD, DA...
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	// No existing sweeps
	str = "select(channels(AD6, DA),[" + num2istr(sweepNo + 1337) + "])"
	WAVE/Z data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE(!WaveExists(data))

	// No existing channels
	str = "select(channels(AD0),[" + num2istr(sweepNo) + "])"
	WAVE/Z data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE(!WaveExists(data))

	// Invalid channels
	try
		str = "select([0, 6],[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "])"
		WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	str = "select(1)"
	try
		WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	str = "select(channels(AD), sweeps(), 1)"
	try
		WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	str = "select(channels(AD), sweeps(), all, 1)"
	try
		WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	// Setup graph for unassoc DA/AD and TTL
	numSweeps = 1
	channelTypeList = "DA;AD;TTL;"
	channelNumberList = "0;1;2;"

	RemoveTracesFromGraph(win)
	TUD_Clear(win)

	Make/FREE/N=(dataSize, numSweeps, numChannels) input = q + p^r // + gnoise(1)
	for(i = 0; i < numSweeps; i += 1)
		sweepNo = i
		for(j = 0; j < numChannels; j += 1)
			name = UniqueName("data", 1, 0)
			trace = "trace_" + name
			clampMode = NaN
			Extract input, $name, q == i && r == j
			WAVE wv = $name
			AppendToGraph/W=$win wv/TN=$trace
			TUD_SetUserDataFromWaves(win, trace, {"experiment", "fullPath", "traceType", "occurence", "channelType", "channelNumber", "sweepNumber", "clampMode", "GUIChannelNumber", "AssociatedHeadstage"},         \
									 {"blah", GetWavesDataFolder(wv, 2), "Sweep", "0", StringFromList(j, channelTypeList), StringFromList(j, channelNumberList), num2istr(sweepNo), num2istr(clampMode), StringFromList(j, channelNumberList), num2istr(0)})
		endfor
	endfor

	Make/FREE/N=(1, 3) dataRef
	dataRef[][0] = {0}
	dataRef[][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[][2] = {0}
	str = "select(channels(DA0),sweeps(),displayed)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(1, 3) dataRef
	dataRef[][0] = {0}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {1}
	str = "select(channels(AD1),sweeps(),displayed)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	Make/FREE/N=(1, 3) dataRef
	dataRef[][0] = {0}
	dataRef[][1] = WhichListItem("TTL", XOP_CHANNEL_NAMES)
	dataRef[][2] = {2}
	str = "select(channels(TTL2),sweeps(),displayed)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)
	// clamp mode set filters has no effect on TTL
	str = "select(channels(TTL2),sweeps(),displayed,vc)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA | DIMENSION_SIZES)

	// clamp mode set filters on DA/AD
	str = "select(channels(AD1),sweeps(),displayed,vc)"
	WAVE/Z data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	CHECK_WAVE(data, NULL_WAVE)
	str = "select(channels(DA0),sweeps(),displayed,vc)"
	WAVE/Z data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	CHECK_WAVE(data, NULL_WAVE)
End

static Function CheckSweepsFromData(WAVE/WAVE dataWref, WAVE sweepRef, variable numResults, WAVE chanIndex, [WAVE ranges])

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

static Function TestOperationAverage()

	string win, device
	string str
	STRUCT RGBColor s

	[win, device] = CreateFakeDataBrowserWindow()

	CreateFakeSweepData(win, device, sweepNo=0)
	CreateFakeSweepData(win, device, sweepNo=1)

	str = "avg()"
	try
		WAVE/Z data = SF_ExecuteFormula(str, win, singleResult = 1)
		FAIL()
	catch
		PASS()
	endtry

	str = "avg(1, 2, 3)"
	try
		WAVE/Z data = SF_ExecuteFormula(str, win, singleResult = 1)
		FAIL()
	catch
		PASS()
	endtry

	str = "avg(1, 2)"
	try
		WAVE/Z data = SF_ExecuteFormula(str, win, singleResult = 1)
		FAIL()
	catch
		PASS()
	endtry

	str = "avg(2, in)"
	WAVE/Z data = SF_ExecuteFormula(str, win, singleResult = 1, checkExist = 1)
	CHECK_WAVE(data, IUTF_WAVETYPE1_NUM)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 1)
	CHECK_EQUAL_VAR(data[0], 2)

	str = "avg([1, 2, 3], in)"
	WAVE/Z data = SF_ExecuteFormula(str, win, singleResult = 1, checkExist = 1)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 1)
	CHECK_EQUAL_VAR(data[0], 2)
	str = "avg([1, 2, 3])"
	WAVE/Z data = SF_ExecuteFormula(str, win, singleResult = 1, checkExist = 1)
	CHECK_EQUAL_VAR(DimSize(data, ROWS), 1)
	CHECK_EQUAL_VAR(data[0], 2)

	str = "avg(data(cursors(A,B), select(channels(AD), sweeps(), all)), in)"
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win)
	CHECK_EQUAL_VAR(DimSize(dataRef, ROWS), 4)
	Make/FREE/D ref = {4.5}
	for(data : dataRef)
		CHECK_EQUAL_WAVES(data, ref, mode = WAVE_DATA)
	endfor

	str = "avg(data(cursors(A,B), select(channels(AD), sweeps(), all)), over)"
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win)
	CHECK_EQUAL_VAR(DimSize(dataRef, ROWS), 1)

	[s] = GetTraceColorForAverage()
	Make/FREE/D ref = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
	WAVE data = dataRef[0]
	CHECK_EQUAL_WAVES(data, ref, mode = WAVE_DATA)
	CHECK_EQUAL_VAR(JWN_GetNumberFromWaveNote(data, SF_META_TRACETOFRONT), 1)
	CHECK_EQUAL_VAR(JWN_GetNumberFromWaveNote(data, SF_META_LINESTYLE), 0)
	WAVE/Z tColor = JWN_GetNumericWaveFromWaveNote(data, SF_META_TRACECOLOR)
	CHECK_EQUAL_WAVES(tColor, {s.red, s.green, s.blue}, mode = WAVE_DATA)
End

static Function TestOperationData()

	variable i, j, numChannels, sweepNo, sweepCnt, numResultsRef, clampMode
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
	Make/FREE/T/N=(3, 1, 1) epochKeys, epochTTLKeys
	epochKeys[0][0][0] = EPOCHS_ENTRY_KEY
	epochKeys[2][0][0] = LABNOTEBOOK_NO_TOLERANCE

	[win, device] = CreateFakeDataBrowserWindow()

	sweepNo = 0

	CreateFakeSweepData(win, device, sweepNo=sweepNo)
	CreateFakeSweepData(win, device, sweepNo=sweepNo + 1)
	CreateFakeSweepData(win, device, sweepNo=sweepNo + 2)
	CreateFakeSweepData(win, device, sweepNo=sweepNo + 3)

	epochStr = "0.00" + num2istr(rangeStart0) + ",0.00" + num2istr(rangeEnd0) + ",ShortName=TestEpoch,0,:"
	epochStr += "0.00" + num2istr(rangeStart1) + ",0.00" + num2istr(rangeEnd0) + ",ShortName=TestEpoch1,0,:"
	epochStr += "0.00" + num2istr(rangeStart0) + ",0.00" + num2istr(rangeEnd1) + ",NoShortName,0,:"
	Make/FREE/T/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) epochInfo = epochStr
	ED_AddEntriesToLabnotebook(epochInfo, epochKeys, sweepNo, device, mode)
	epochStr = "0.00" + num2istr(rangeStart1) + ",0.00" + num2istr(rangeEnd1) + ",ShortName=TestEpoch,0"
	Make/FREE/T/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) epochInfo = epochStr
	ED_AddEntriesToLabnotebook(epochInfo, epochKeys, sweepNo + 1, device, mode)

	epochStr = "0.00" + num2istr(rangeStart1) + ",0.00" + num2istr(rangeEnd1) + ",ShortName=TestEpoch2,0"
	Make/FREE/T/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) epochInfo = epochStr
	epochTTLKeys[0][0][0] = "TTL Epochs Channel " + num2istr(2)
	epochTTLKeys[2][0][0] = LABNOTEBOOK_NO_TOLERANCE
	ED_AddEntriesToLabnotebook(epochInfo, epochTTLKeys, sweepNo + 3, device, mode)

	numChannels = 4 // from LBN creation in CreateFakeSweepData->PrepareLBN_IGNORE -> DA2, AD6, DA3, AD7
	Make/FREE/N=0 sweepTemplate
	WAVE sweepRef = FakeSweepDataGeneratorDefault(sweepTemplate, numChannels)
	WAVE sweepRef3 = FakeSweepDataGeneratorDefault(sweepTemplate, 5)
	sweepRef3[][4] = (sweepRef3[p][4] & 1 << 2) != 0

	sweepCnt = 1
	str = "data(TestEpoch2,select(channels(TTL2),[" + num2istr(3) + "],all))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	numResultsRef = sweepCnt * 1
	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[][0] = rangeStart1
	ranges[][1] = rangeEnd1
	CheckSweepsFromData(dataWref, sweepRef3, numResultsref, {5}, ranges=ranges)
	CheckSweepsMetaData(dataWref, {3}, {2}, {3}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str = "data(cursors(A,B),select(channels(AD),[" + num2istr(sweepNo) + "],all))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	numResultsRef = sweepCnt * numChannels / 2
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3})
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {0, 0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str = "data([0, inf],select(channels(AD),[" + num2istr(sweepNo) + "],all))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	numResultsRef = sweepCnt * numChannels / 2
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3})
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {0, 0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str = "data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	numResultsRef = sweepCnt * 1
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1})
	CheckSweepsMetaData(dataWref, {0}, {6}, {0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str = "data(TestEpoch,select(channels(AD),[" + num2istr(sweepNo) + "],all))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	numResultsRef = sweepCnt * numChannels / 2
	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[][0] = rangeStart0
	ranges[][1] = rangeEnd0
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3}, ranges=ranges)
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {0, 0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str = "data(\"Test*\",select(channels(AD),[" + num2istr(sweepNo) + "],all))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	numResultsRef = sweepCnt * numChannels / 2 * 2 // 2 epochs starting with Test...

	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[0][0] = rangeStart1
	ranges[0][1] = rangeEnd0
	ranges[1][0] = rangeStart0
	ranges[1][1] = rangeEnd0
	ranges[2][0] = rangeStart1
	ranges[2][1] = rangeEnd0
	ranges[3][0] = rangeStart0
	ranges[3][1] = rangeEnd0
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {3, 1, 3, 1}, ranges=ranges)
	CheckSweepsMetaData(dataWref, {0, 0, 0, 0}, {6, 6, 7, 7}, {0, 0, 0, 0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str = "data([\"TestEpoch\",\"TestEpoch1\"],select(channels(AD),[" + num2istr(sweepNo) + "],all))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	numResultsRef = sweepCnt * numChannels / 2 * 2 // 2 epochs in array

	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[0][0] = rangeStart0
	ranges[0][1] = rangeEnd0
	ranges[1][0] = rangeStart1
	ranges[1][1] = rangeEnd0
	ranges[2][0] = rangeStart0
	ranges[2][1] = rangeEnd0
	ranges[3][0] = rangeStart1
	ranges[3][1] = rangeEnd0
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {3, 1, 3, 1}, ranges=ranges)
	CheckSweepsMetaData(dataWref, {0, 0, 0, 0}, {6, 6, 7, 7}, {0, 0, 0, 0}, SF_DATATYPE_SWEEP)

	// Finds the NoShortName epoch
	sweepCnt = 1
	str = "data(\"!TestEpoch*\",select(channels(AD),[" + num2istr(sweepNo) + "],all))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	numResultsRef = sweepCnt * numChannels / 2

	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[][0] = rangeStart0
	ranges[][1] = rangeEnd1
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {3, 1}, ranges=ranges)
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {0, 0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str = "data(TestEpoch,select(channels(AD),[" + num2istr(sweepNo + 1) + "],all))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	numResultsRef = sweepCnt * numChannels / 2
	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[][0] = rangeStart1
	ranges[][1] = rangeEnd1
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3}, ranges=ranges)
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {1, 1}, SF_DATATYPE_SWEEP)

	sweepCnt = 2
	str = "data(TestEpoch,select(channels(AD),[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "],all))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	numResultsRef = sweepCnt * numChannels / 2
	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[][0] = p >= 2 ? rangeStart1 : rangeStart0
	ranges[][1] = p >= 2 ? rangeEnd1 : rangeEnd0
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3, 1, 3}, ranges=ranges)
	CheckSweepsMetaData(dataWref, {0, 0, 0, 0}, {6, 7, 6, 7}, {0, 0, 1, 1}, SF_DATATYPE_SWEEP)

	// FAIL Tests
	// non existing channel
	str = "data(TestEpoch,select(channels(AD4),[" + num2istr(sweepNo) + "],all))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	REQUIRE_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// non existing sweep
	str = "data(TestEpoch,select(channels(AD4),[" + num2istr(sweepNo + 1337) + "],all))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	REQUIRE_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// non existing epoch
	str = "data(WhatEpochIsThis,select(channels(AD4),[" + num2istr(sweepNo) + "],all))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	REQUIRE_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// range begin
	str = "data([12, 10],select(channels(AD),[" + num2istr(sweepNo) + "],all))"
	try
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	// range end
	str = "data([0, 11],select(channels(AD),[" + num2istr(sweepNo) + "],all))"
	try
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	// One sweep does not exist, it is not result of select, we end up with one sweep
	sweepCnt = 1
	str = "data(cursors(A,B),select(channels(AD),[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1337) + "],all))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
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
			clampMode = mod(sweepNo, 2) ? V_CLAMP_MODE : I_CLAMP_MODE
			Extract input, $name, q == i && r == j
			WAVE wv = $name
			AppendToGraph/W=$win wv/TN=$trace
			TUD_SetUserDataFromWaves(win, trace, {"experiment", "fullPath", "traceType", "occurence", "channelType", "channelNumber", "sweepNumber", "GUIChannelNumber", "clampMode"},         \
									 {"blah", GetWavesDataFolder(wv, 2), "Sweep", "0", StringFromList(j, channelTypeList), StringFromList(j, channelNumberList), num2istr(sweepNo), StringFromList(j, channelNumberList), num2istr(clampMode)})
		endfor
	endfor

	Make/FREE/N=(DimSize(sweepRef, ROWS), 2, numChannels) dataRef
	dataRef[][][] = sweepRef[p]

	sweepCnt = 2
	str = "data(cursors(A,B),select())"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	numResultsRef = sweepCnt * numChannels
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3, 0, 2, 1, 3, 0, 2})
	CheckSweepsMetaData(dataWref, {0, 0, 1, 1, 0, 0, 1, 1}, {6, 7, 2, 3, 6, 7, 2, 3}, {0, 0, 0, 0, 1, 1, 1, 1}, SF_DATATYPE_SWEEP)
	str = "data(cursors(A,B))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3, 0, 2, 1, 3, 0, 2})
	CheckSweepsMetaData(dataWref, {0, 0, 1, 1, 0, 0, 1, 1}, {6, 7, 2, 3, 6, 7, 2, 3}, {0, 0, 0, 0, 1, 1, 1, 1}, SF_DATATYPE_SWEEP)

	// Using the setup from data we also test cursors operation
	Cursor/W=$win/A=1/P A, $trace, 0
	Cursor/W=$win/A=1/P B, $trace, trunc(dataSize / 2)
	Make/FREE dataRef = {0, trunc(dataSize / 2)}
	str = "cursors(A,B)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA)
	str = "cursors()"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA)

	try
		str = "cursors(X,Y)"
		WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
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

	CreateFakeSweepData(win, device, sweepNo=sweepNo, sweepGen=FakeSweepDataGeneratorPS)
	CreateFakeSweepData(win, device, sweepNo=sweepNo + 1, sweepGen=FakeSweepDataGeneratorPS)

	str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
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
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WaveStats/Q/M=1 data
	CHECK_CLOSE_VAR(V_maxLoc, 100, tol=0.01)
	CHECK_CLOSE_VAR(V_max, 88, tol=0.01)
	str = WaveUnits(data, -1)
	strRef = "dB"
	CHECK_EQUAL_STR(strRef, str)

	str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)),normalized)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WaveStats/Q/M=1 data
	CHECK_CLOSE_VAR(V_maxLoc, 100, tol=0.01)
	CHECK_CLOSE_VAR(V_max, 129, tol=0.01)
	str = WaveUnits(data, -1)
	strRef = "mean(^2)"
	CHECK_EQUAL_STR(strRef, str)

	str = "powerspectrum(data(cursors(A,B),select(channels(AD),[" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "],all)),dB,avg)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
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
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WaveStats/Q/M=1 data
	CHECK_EQUAL_VAR(1, DimSize(data, ROWS))
	CHECK_CLOSE_VAR(data[0], 1.32, tol=0.01)

	str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)),dB,noavg,0,2000)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	val = IndexToScale(data, DimSize(data, ROWS), ROWS)
	CHECK_CLOSE_VAR(val, 2000, tol=0.001)

	str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)),dB,noavg,0,1000,HFT248D)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WaveStats/Q/M=1 data
	CHECK_CLOSE_VAR(V_maxLoc, 100, tol=0.01)
	CHECK_CLOSE_VAR(V_max, 94, tol=0.01)

	try
		str = "powerspectrum()"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)), not_exist)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)), dB, not_exist)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)), dB, avg, -1)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)), dB, avg, 0, -1)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)), dB, avg, 0, 1000, not_exist)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(cursors(A,B),select(channels(AD6),[" + num2istr(sweepNo) + "],all)), dB, avg, 0, 1000, Bartlet, not_exist)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestOperationLabNotebook()
	Variable i, j, sweepNumber, channelNumber, numSweeps, numChannels
	String str, key

	string textKey = LABNOTEBOOK_USER_PREFIX + "TEXTKEY"
	string textValue = "TestText"

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	[numSweeps, numChannels, WAVE/U/I channels] = FillFakeDatabrowserWindow(win, device, XOP_CHANNEL_TYPE_ADC, textKey, textValue)

	ModifyGraph/W=$win log(left)=1

	Make/FREE/N=(numSweeps * numChannels) channelsRef
	channelsRef[] = channels[trunc(p / numChannels)][mod(p, numChannels)]
	str = "labnotebook(ADC)"
	TestOperationLabnotebookHelper(win, str, channelsRef)
	str = "labnotebook(ADC,select(channels(AD),0..." + num2istr(numSweeps) + "))"
	TestOperationLabnotebookHelper(win, str, channelsRef)
	str = "labnotebook(" + LABNOTEBOOK_USER_PREFIX + "ADC, select(channels(AD),0..." + num2istr(numSweeps) + "),UNKNOWN_MODE)"
	TestOperationLabnotebookHelper(win, str, channelsRef)

	str = "labnotebook(ADC, select(channels(AD12),-1))"
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(DimSize(dataRef, ROWS), 0)

	str = "labnotebook(" + textKey + ")"
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables=0)
	Make/FREE/T textRefData = {textValue}
	for(WAVE/T dataT : dataRef)
		CHECK_EQUAL_WAVES(dataT, textRefData, mode = WAVE_DATA)
	endfor
End

static Function TestOperationLabnotebookHelper(string win, string formula, WAVE wRef)

	variable i

	WAVE/WAVE dataRef = SF_ExecuteFormula(formula, win, useVariables=0)
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

	variable i, j, sweepNumber, channelNumber, numResultsRef, numSweeps, numChannels
	string str, trace, key, name, win, device, epoch2, textKey, textValue, epochLongName
	variable activeChannelsDA = 4

	[win, device] = CreateFakeDataBrowserWindow()

	textKey   = EPOCHS_ENTRY_KEY
	textValue = "0.5000000,0.5100000,Epoch=0;Type=Pulse Train;Amplitude=1;Pulse=48;ShortName=E0_PT_P48;,2,:"
	textValue += "0.5030000,0.5100000,Epoch=0;Type=Pulse Train;Pulse=48;Baseline;ShortName=E0_PT_P48_B;,3,:"
	textValue += "0.6000000,0.7000000,NoShortName,3,:"
	epoch2 = "Epoch=0;Type=Pulse Train;Pulse=49;Baseline;"
	textValue += "0.5100000,0.5200000," + epoch2 + ",2,"

	[numSweeps, numChannels, WAVE/U/I channels] = FillFakeDatabrowserWindow(win, device, XOP_CHANNEL_TYPE_DAC, textKey, textValue)

	str = "epochs(\"E0_PT_P48\")"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
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
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 1)
	Make/FREE/D refData = {500, 510}
	WAVE data = dataWref[0]
	REQUIRE_EQUAL_WAVES(data, refData, mode = WAVE_DATA)

	str = "epochs(\"E0_PT_P48_B\", select(channels(DA4), 0))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 1)
	Make/FREE/D refData = {503, 510}
	WAVE data = dataWref[0]
	REQUIRE_EQUAL_WAVES(data, refData, mode = WAVE_DATA)

	str = "epochs(\"E0_PT_P48_B\", select(channels(DA4), 0), range)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE/D refData = {503, 510}
	REQUIRE_EQUAL_WAVES(data, refData, mode = WAVE_DATA)

	str = "epochs(\"E0_PT_P48_B\", select(channels(DA4),0), treelevel)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE/D refData = {3}
	REQUIRE_EQUAL_WAVES(data, refData, mode = WAVE_DATA)

	str = "epochs(\"E0_PT_P48_B\", select(channels(DA4), 9), name)"
	WAVE/T dataT = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE/T refDataT = {"E0_PT_P48_B"}
	REQUIRE_EQUAL_WAVES(dataT, refDataT, mode = WAVE_DATA)

	str = "epochs(\"NoShortName\", select(channels(DA4), 9), name)"
	WAVE/T dataT = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE/T refDataT = {"NoShortName"}
	REQUIRE_EQUAL_WAVES(dataT, refDataT, mode = WAVE_DATA)

	// works case-insensitive
	str = "epochs(\"e0_pt_p48_B\", select(channels(DA4), 9), name)"
	WAVE/T dataT = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
	Make/FREE/T refDataT = {"E0_PT_P48_B"}
	REQUIRE_EQUAL_WAVES(dataT, refDataT, mode = WAVE_DATA)

	str = "epochs(\"E0_PT_P48_B\", select(channels(DA), 0..." + num2istr(numSweeps) + "))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
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

	str = "epochs(\"E0_PT_P48_*\", select(channels(DA), 0))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), activeChannelsDA)
	Make/FREE/D refData = {503, 510}
	for(data : dataWref)
		 CHECK_EQUAL_WAVES(data, refData, mode = WAVE_DATA)
	endfor

	// find epoch without shortname
	epochLongName = RemoveEnding(epoch2, ";")
	str = "epochs(\"" + epochLongName + "\", select(channels(DA), 0))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), activeChannelsDA)

	// finds only epoch without shortname from test epochs
	str = "epochs(\"!E0_PT_P48*\", select(channels(DA), 0))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), activeChannelsDA * 2)

	// the first wildcard matches both setup epochs, the second only the first setup epoch
	// only unique epochs are returned, thus two
	str = "epochs([\"E0_PT_*\",\"E0_PT_P48*\"], select(channels(DA), 0))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 8)
	Make/FREE/D refData1 = {500, 510}
	Make/FREE/D refData2 = {503, 510}
	i = 0
	for(data : dataWref)
		if(!i)
			CHECK_EQUAL_WAVES(data, refData1, mode = WAVE_DATA)
		else
			CHECK_EQUAL_WAVES(data, refData2, mode = WAVE_DATA)
		endif
		i = 1 - i
	endfor

	// channel(s) with no epochs
	str = "epochs(\"E0_PT_P48_B\", select(channels(AD), 0..." + num2istr(numSweeps) + "))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// channels with epochs, but name that does not match any epoch
	str = "epochs(\"does_not_exist\", select(channels(DA), 0..." + num2istr(numSweeps) + "))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// invalid sweep
	str = "epochs(\"E0_PT_P48_B\", select(channels(DA), " + num2istr(numSweeps) + "))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// invalid type
	str = "epochs(\"E0_PT_P48_B\", select(channels(DA), 0..." + num2istr(numSweeps) + "), invalid_type)"
	try
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables=0)
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

	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables=0)
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

	WAVE/WAVE/Z container = JSONToWave(results)
	CHECK_WAVE(container, WAVE_WAVE)
	WAVE/Z resultsWave = container[0]
	CHECK_EQUAL_TEXTWAVES(wv, resultsWave, mode = WAVE_DATA)

	// check sweep formula y wave
	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)
	WAVE/Z sweepFormulaY = GetSweepFormulaY(dfr, 0)
	CHECK_EQUAL_VAR(DimSize(sweepFormulaY, COLS), 1)
	Redimension/N=(-1, 0) sweepFormulaY
	CHECK_EQUAL_WAVES(wv, sweepFormulaY, mode = WAVE_DATA)
End

static Function StoreWorksWithMultipleDataSets()
	string str, results

	string textKey = LABNOTEBOOK_USER_PREFIX + "TEXTKEY"
	string textValue = "TestText"

	string win, device
	variable numSweeps, numChannels

	device = HW_ITC_BuildDeviceString("ITC18USB", "0")

	SVAR lockedDevices = $GetLockedDevices()
	lockedDevices = device
	win = DB_GetBoundDataBrowser(device)

	[numSweeps, numChannels, WAVE/U/I channels] = FillFakeDatabrowserWindow(win, device, XOP_CHANNEL_TYPE_ADC, textKey, textValue)

	str = "store(\"ABCD\", data(cursors(A, B), select(channels(), sweeps())))"
	CHECK(ExecuteSweepFormulaInDB(str, win))

	WAVE textualResultsValues = GetLogbookWaves(LBT_RESULTS, LBN_TEXTUAL_VALUES)

	results = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula store [ABCD]", SWEEP_FORMULA_RESULT)
	CHECK_PROPER_STR(results)

	WAVE/Z resultsWave = JSONToWave(results)
	CHECK_WAVE(resultsWave, WAVE_WAVE)
End

static Function/WAVE TestHelpNotebookGetter_IGNORE()

	WAVE/T wt = SF_GetNamedOperations()

	SetDimensionLabels(wt, TextWaveToList(wt, ";"), ROWS)

	return wt
End

// UTF_TD_GENERATOR TestHelpNotebookGetter_IGNORE
static Function TestHelpNotebook([string str])

	string browser, headLine, helpText, sfHelpWin

	browser = DB_OpenDataBrowser()

	sfHelpWin = BSP_GetSFHELP(browser)
	headLine = MIES_BSP#BSP_GetHelpOperationHeadline(str)

	helpText = MIES_BSP#BSP_RetrieveSFHelpTextImpl(sfHelpWin, headLine, "to_top_" + str)
	CHECK_PROPER_STR(helpText)

	CHECK_EQUAL_VAR(DB_SFHelpJumpToLine(headLine), 0)
End

// data acquired with model cell, 45% baseline
// the data is the inserted TP plus 10ms flat stimset
static Function TPWithModelCell()
	string win, device, str

	device = HW_ITC_BuildDeviceString("ITC18USB", "0")

	DFREF dfr = GetDevicePath(device)
	DuplicateDataFolder root:SF_TP:Data, dfr

	DFREF dfr = GetMIESPath()
	DuplicateDataFolder root:SF_TP:LabNoteBook, dfr

	GetDAQDeviceID(device)

	win = DB_GetBoundDataBrowser(device)

	CHECK(ExecuteSweepFormulaInDB("store(\"inst\",tp(tpinst()))\n and \nstore(\"ss\",tp(tpss()))", win))

	WAVE textualResultsValues = GetLogbookWaves(LBT_RESULTS, LBN_TEXTUAL_VALUES)

	str = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula store [ss]", SWEEP_FORMULA_RESULT)
	WAVE/WAVE/Z container = JSONToWave(str)
	CHECK_WAVE(container, WAVE_WAVE)
	WAVE/Z results = container[0]
	CHECK_WAVE(results, NUMERIC_WAVE)
	Make/D/FREE ref = {183.037718204489}
	CHECK_EQUAL_WAVES(ref, results, mode = WAVE_DATA)

	str = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula store [inst]", SWEEP_FORMULA_RESULT)
	WAVE/WAVE/Z container = JSONToWave(str)
	CHECK_WAVE(container, WAVE_WAVE)
	WAVE/Z results = container[0]
	CHECK_WAVE(results, NUMERIC_WAVE)
	Make/D/FREE ref = {17.3667394014963}
	CHECK_EQUAL_WAVES(ref, results, mode = WAVE_DATA)
End

static Function NonExistingOperation()

	string win, device, str

	[win, device] = CreateFakeDataBrowserWindow()

	str = "bogusOp(1,2,3)"
	try
		// this is currently caught by an additional check specifically for automated testing
		// but it would also cause an Abort in the main code
		WAVE output = SF_ExecuteFormula(str, win, singleResult=1, useVariables=0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function ZeroSizedSubArrayTest()

	string win, device

	[win, device] = CreateFakeDataBrowserWindow()

	WAVE wTextRef = MIES_SF#SF_FormulaExecutor(win, JSON_Parse("[]"))
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

static Function BrowserGraphConnectionWorks()

	string formulaGraph, browser, device, result

	[browser, device] = CreateFakeDataBrowserWindow()

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

	[win, device] = CreateFakeDataBrowserWindow()

	CreateFakeSweepData(win, device, sweepNo=0, sweepGen=FakeSweepDataGeneratorAPF0)
	CreateFakeSweepData(win, device, sweepNo=1, sweepGen=FakeSweepDataGeneratorAPF1)

	formula = "apfrequency(data(cursors(A,B),select(channels(AD),[0,1],all)), 3, 15, time, normoversweepsmin,time)"
	WAVE/WAVE outputRef = SF_ExecuteFormula(formula, win, useVariables=0)
	argSetupStack = JWN_GetStringFromWaveNote(outputRef, SF_META_ARGSETUPSTACK)
	jsonId = JSON_Parse(argSetupStack)
	CHECK_NEQ_VAR(jsonId, NaN)

	argSetup = JSON_GetString(jsonId, "/0")
	jsonId1 = JSON_Parse(argSetup)
	CHECK_NEQ_VAR(jsonId1, NaN)

	str = JSON_GetString(jsonId1, "/Operation")
	CHECK_EQUAL_STR(str, "data")
	JSON_Release(jsonId1)

	argSetup = JSON_GetString(jsonId, "/1")
	jsonId1 = JSON_Parse(argSetup)
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
	Make/FREE/T formulaArgSetup = { "{\n\"0\": \"{\\n\\\"Operation\\\": \\\"data\\\"\\n}\",\n\"1\": \"{\\n\\\"Level\\\": \\\"100\\\",\\n\\\"Method\\\": \\\"Instantaneous Pair\\\",\\n\\\"Normalize\\\": \\\"normoversweepsavg\\\",\\n\\\"Operation\\\": \\\"apfrequency\\\",\\n\\\"ResultType\\\": \\\"freq\\\",\\n\\\"XAxisType\\\": \\\"count\\\"\\n}\"}", \
	"{\n\"0\": \"{\\n\\\"Operation\\\": \\\"data\\\"\\n}\",\n\"1\": \"{\\n\\\"Level\\\": \\\"100\\\",\\n\\\"Method\\\": \\\"Instantaneous Pair\\\",\\n\\\"Normalize\\\": \\\"norminsweepsavg\\\",\\n\\\"Operation\\\": \\\"apfrequency\\\",\\n\\\"ResultType\\\": \\\"time\\\",\\n\\\"XAxisType\\\": \\\"count\\\"\\n}\"}"}
	Make/FREE/T result = {"\s(T000000d0_apfrequency_data_Sweep_0_AD0)apfrequency(Normalize:normoversweepsavg ResultType:freq) data Sweeps 0-8,145 AD0", "\s(T000010d0_apfrequency_data_Sweep_0_AD0)apfrequency(Normalize:norminsweepsavg ResultType:time) data Sweeps 0-8,145 AD0"}
	CHECK_EQUAL_VAR(SFH_EnrichAnnotations(wAnnotations, formulaArgSetup), 1)
	CHECK_EQUAL_WAVES(result, wAnnotations, mode = WAVE_DATA)
End

static Function TestInputCodeCheck()

	string win, device
	string formula, jsonRef, jsonTxt

	[win, device] = CreateFakeDataBrowserWindow()

	DFREF dfr = SF_GetBrowserDF(win)
	NVAR jsonID = $GetSweepFormulaJSONid(dfr)

	formula = "1"
	jsonRef = "{\n\"graph_0\": {\n\"pair_0\": {\n\"formula_y\": 1\n}\n}\n}"
	MIES_SF#SF_CheckInputCode(formula, win)
	jsonTxt = JSON_Dump(jsonId)
	JSON_Release(jsonId)
	CHECK_EQUAL_STR(jsonRef, jsonTxt)

	formula = "1 vs 1"
	jsonRef = "{\n\"graph_0\": {\n\"pair_0\": {\n\"formula_x\": 1,\n\"formula_y\": 1\n}\n}\n}"
	MIES_SF#SF_CheckInputCode(formula, win)
	jsonTxt = JSON_Dump(jsonId)
	JSON_Release(jsonId)
	CHECK_EQUAL_STR(jsonRef, jsonTxt)

	formula = "1\rwith\r1 vs 1"
	jsonRef = "{\n\"graph_0\": {\n\"pair_0\": {\n\"formula_y\": 1\n},\n\"pair_1\": {\n\"formula_x\": 1,\n\"formula_y\": 1\n}\n}\n}"
	MIES_SF#SF_CheckInputCode(formula, win)
	jsonTxt = JSON_Dump(jsonId)
	JSON_Release(jsonId)
	CHECK_EQUAL_STR(jsonRef, jsonTxt)

	formula = "v = 1\r1"
	jsonRef = "{\n\"graph_0\": {\n\"pair_0\": {\n\"formula_y\": 1\n}\n},\n\"variable:v\": 1\n}"
	MIES_SF#SF_CheckInputCode(formula, win)
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

	[win, device] = CreateFakeDataBrowserWindow()
	CreateFakeSweepData(win, device, sweepNo=0)
	CreateFakeSweepData(win, device, sweepNo=1)

	WAVE/T formulaAndRest = wRef[0]

	code = MIES_SF#SF_ExecuteVariableAssignments(win, formulaAndRest[0])
	CHECK_EQUAL_STR(formulaAndRest[1], code)

	WAVE/T dimLbl = wRef[1]
	WAVE/WAVE varStorage = GetSFVarStorage(win)
	CHECK_EQUAL_VAR(DimSize(dimLbl, ROWS), DimSize(varStorage, ROWS))
	i = 0
	for(lbl : dimLbl)
		dim = FindDimLabel(varStorage, ROWS, lbl)
		CHECK_NEQ_VAR(dim, -2)
		CHECK_LT_VAR(dim, DimSize(varStorage, ROWS))
		CHECK_EQUAL_VAR(dim, i)
		WAVE varContent = varStorage[dim]
		WAVE data = MIES_SF#SF_ResolveDataset(varContent)
		CHECK_GT_VAR(DimSize(data, ROWS), 0)
		i += 1
	endfor

	WAVE/Z refData = wRef[2]
	if(WaveExists(refData))
		WAVE/Z result = SF_ExecuteFormula(formulaAndRest[0], win, singleresult=1)
		CHECK_WAVE(result, WaveType(refData, 1))
		CHECK_EQUAL_WAVES(result, refData, mode = WAVE_DATA)
	endif

End

static Function TestVariables2()

	string win, device
	string str, code

	[win, device] = CreateFakeDataBrowserWindow()

	CreateFakeSweepData(win, device, sweepNo=0)
	CreateFakeSweepData(win, device, sweepNo=1)
	DFREF dfr = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)

	// reuse of the same variable name
	str = "c=cursors(A,B)\rC=select(channels(AD),[0,1],all)\rd=data($c,$C)\r\r$d"
	try
		code = MIES_SF#SF_ExecuteVariableAssignments(win, str)
		FAIL()
	catch
		PASS()
	endtry

	// variable with invalid expression
	str = "c=[*#]"
	try
		code = MIES_SF#SF_ExecuteVariableAssignments(win, str)
		FAIL()
	catch
		PASS()
	endtry

	// No valid varName
	str = "12c=cursors(A,B)"
	code = MIES_SF#SF_ExecuteVariableAssignments(win, str)
	CHECK_EQUAL_STR(str, code)

	// No variables defined
	str = "cursors(A,B)"
	code = MIES_SF#SF_ExecuteVariableAssignments(win, str)
	CHECK_EQUAL_STR(str, code)

	// varName with all chars
	str = "abcdefghijklmnopqrstuvwxyz0123456789_=cursors(A,B)\r"
	code = MIES_SF#SF_ExecuteVariableAssignments(win, str)
	CHECK_EQUAL_STR("", code)

	// WhiteSpaces are ok
	str = " \ta \t= \tcursors(A,B)\r"
	code = MIES_SF#SF_ExecuteVariableAssignments(win, str)
	CHECK_EQUAL_STR("", code)
End

static Function TestDefaultFormula()

	string win, bsPanel

	win = GetDataBrowserWithData()
	bsPanel = BSP_GetPanel(win)

	PGC_SetAndActivateControl(bsPanel, "check_BrowserSettings_SF", val = CHECKBOX_SELECTED)
	PGC_SetAndActivateControl(bsPanel, "button_sweepFormula_display")
End

static Function TestParseFitConstraints()

	Make/D/N=0 emptyWave

	[WAVE holdWave, WAVE initialWave] = MIES_SF#SF_ParseFitConstraints($"", 0)
	CHECK_EQUAL_WAVES(holdWave, emptyWave)
	CHECK_EQUAL_WAVES(initialWave, emptyWave)

	[WAVE holdWave, WAVE initialWave] = MIES_SF#SF_ParseFitConstraints($"", 1)
	CHECK_EQUAL_WAVES(holdWave, {0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(initialWave, {NaN}, mode = WAVE_DATA)

	[WAVE holdWave, WAVE initialWave] = MIES_SF#SF_ParseFitConstraints({"K0=1.23", "K1=4.56"}, 3)
	CHECK_EQUAL_WAVES(holdWave, {1, 1, 0}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(initialWave, {1.23, 4.56, NaN}, mode = WAVE_DATA, tol = 1e-3)

	// too many elements in constraints wave
	try
		[WAVE holdWave, WAVE initialWave] = MIES_SF#SF_ParseFitConstraints({"abcd"}, 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// invalid constraints wave format, as the regexp does not match
	try
		[WAVE holdWave, WAVE initialWave] = MIES_SF#SF_ParseFitConstraints({"abcd"}, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// invalid constraints wave format, as the index, K1, is too large
	try
		[WAVE holdWave, WAVE initialWave] = MIES_SF#SF_ParseFitConstraints({"K1=1"}, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// invalid constraints wave format, as the value is not a number
	try
		[WAVE holdWave, WAVE initialWave] = MIES_SF#SF_ParseFitConstraints({"K0=abcd"}, 1)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

static Function TestOperationMerge()

	string win, device, code

	[win, device] = CreateFakeDataBrowserWindow()

	// no input
	code = "merge()"
	try
		WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables=0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// too many points (2) in the input datasets
	code = "merge(dataset([1, 2]))"
	try
		WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables=0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// mixed input wave types
	code = "merge(dataset([1], [\"a\"]))"
	try
		WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables=0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	code = "merge(dataset([1], [2]))"
	WAVE wv = SF_ExecuteFormula(code, win, useVariables=0, singleResult = 1)
	CHECK_WAVE(wv, FREE_WAVE, minorType = DOUBLE_WAVE)
	Make/FREE/D refWv = {1, 2}
	CHECK_EQUAL_WAVES(wv, refWv)

	code = "merge(dataset([\"a\"], [\"b\"]))"
	WAVE wv = SF_ExecuteFormula(code, win, useVariables=0, singleResult = 1)
	CHECK_WAVE(wv, TEXT_WAVE)
	Make/FREE/T refWvTxt = {"a", "b"}
	CHECK_EQUAL_WAVES(wv, refWvTxt)

	code = "merge(dataset())"
	WAVE/WAVE/Z output = SF_ExecuteFormula(code, win, useVariables=0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 0)

	code = "merge(dataset(wave(I_DONT_EXIST)))"
	WAVE/WAVE/Z output = SF_ExecuteFormula(code, win, useVariables=0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 0)
End

static Function TestOperationFitLine()

	string win, device, code

	[win, device] = CreateFakeDataBrowserWindow()

	code = "fitline()"
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables=0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 3)
	WAVE/T fitType = output[%fitType]
	CHECK_EQUAL_STR(fitType[0], "line")
	WAVE holdWave = output[%holdWave]
	CHECK_EQUAL_WAVES(holdWave, {0, 0}, mode = WAVE_DATA)
	WAVE initialValues = output[%initialValues]
	CHECK_EQUAL_WAVES(initialValues, {NaN, NaN}, mode = WAVE_DATA)

	code = "fitline([\"K0=17\"])"
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables=0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 3)
	WAVE/T fitType = output[%fitType]
	CHECK_EQUAL_STR(fitType[0], "line")
	WAVE holdWave = output[%holdWave]
	CHECK_EQUAL_WAVES(holdWave, {1, 0}, mode = WAVE_DATA)
	WAVE initialValues = output[%initialValues]
	CHECK_EQUAL_WAVES(initialValues, {17, NaN}, mode = WAVE_DATA)

	code = "fitline([\"K0=1\", \"K1=3\"])"
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables=0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 3)
	WAVE/T fitType = output[%fitType]
	CHECK_EQUAL_STR(fitType[0], "line")
	WAVE holdWave = output[%holdWave]
	CHECK_EQUAL_WAVES(holdWave, {1, 1}, mode = WAVE_DATA)
	WAVE initialValues = output[%initialValues]
	CHECK_EQUAL_WAVES(initialValues, {1, 3}, mode = WAVE_DATA)

	code = "fitline(1, 2)"
	try
		WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables=0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

static Function TestOperationFit()

	string win, device, code

	[win, device] = CreateFakeDataBrowserWindow()

	// straight line with slope 1 and offset 0
	code = "fit([1, 3], [1, 3], fitline())"
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables=0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1)
	WAVE wv = output[0]
	Make/FREE/D wvRef = {1, 3}
	SetScale/P x, 1, 2, wvRef
	CHECK_EQUAL_WAVES(wvRef, wv, mode = WAVE_DATA | WAVE_DATA_TYPE | WAVE_SCALING)

	WAVE/Z fitCoeff = JWN_GetNumericWaveFromWaveNote(wv, SF_META_USER_GROUP + SF_META_FIT_COEFF)
	CHECK_WAVE(fitCoeff, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK_EQUAL_WAVES(fitCoeff, {0, 1}, mode = WAVE_DATA)

	WAVE/Z fitSigma = JWN_GetNumericWaveFromWaveNote(wv, SF_META_USER_GROUP + SF_META_FIT_SIGMA)
	CHECK_WAVE(fitSigma, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK_EQUAL_WAVES(fitSigma, {NaN, NaN}, mode = WAVE_DATA)

	WAVE/Z/T fitParams = JWN_GetTextWaveFromWaveNote(wv, SF_META_USER_GROUP + SF_META_FIT_PARAMETER)
	CHECK_WAVE(fitParams, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(fitParams, {"Offset;Slope"}, mode = WAVE_DATA)

	// more complex, use CurveFit for generating reference values
	code = "fit([0, 1, 2], [4, 5, 6], fitline([K0=3]))"
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables=0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1)
	WAVE wv = output[0]

	variable/G K0 = 3

	Make/FREE/D xData = {0, 1, 2}
	Make/FREE/D yData = {4, 5, 6}
	CurveFit/Q/H="10" line yData/X=xData/D

	WAVE/Z fitRef = fit__free_
	MakeWaveFree(fitRef)
	CHECK_EQUAL_WAVES(fitRef, wv, mode = WAVE_DATA | WAVE_DATA_TYPE | WAVE_SCALING)

	WAVE W_coef
	MakeWaveFree(W_coef)

	WAVE/Z fitCoeff = JWN_GetNumericWaveFromWaveNote(wv, SF_META_USER_GROUP + SF_META_FIT_COEFF)
	CHECK_WAVE(fitCoeff, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK_EQUAL_WAVES(fitCoeff, W_coef, mode = WAVE_DATA)

	WAVE W_sigma
	MakeWaveFree(W_sigma)

	WAVE/Z fitSigma = JWN_GetNumericWaveFromWaveNote(wv, SF_META_USER_GROUP + SF_META_FIT_SIGMA)
	CHECK_WAVE(fitSigma, NUMERIC_WAVE, minorType = DOUBLE_WAVE)
	CHECK_EQUAL_WAVES(fitSigma, W_sigma, mode = WAVE_DATA)

	WAVE/Z/T fitParams = JWN_GetTextWaveFromWaveNote(wv, SF_META_USER_GROUP + SF_META_FIT_PARAMETER)
	CHECK_WAVE(fitParams, TEXT_WAVE)
	CHECK_EQUAL_TEXTWAVES(fitParams, {"Offset;Slope"}, mode = WAVE_DATA)

	// non-matching x and y sizes
	code = "fit([1, 2], [3, 4, 5], fitline())"
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables=0)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1)
	CHECK(!WaveExists(output[0]))

	// unknown fit function
	code = "fit([1, 2], [3, 4], dataset(3))"
	try
		WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables=0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// mismatched dataset sizes
	code = "fit(dataset([1]), dataset([1], [2]), fitline())"
	try
		WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables=0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

static Function TestOperationDataset()

	string win, device, code

	[win, device] = CreateFakeDataBrowserWindow()

	code = "dataset()"
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables=0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 0)

	code = "dataset(1)"
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables=0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1)
	CHECK_EQUAL_WAVES(output[0], {1}, mode = WAVE_DATA)

	code = "dataset(1, [2, 3], \"abcd\")"
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables=0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 3)
	CHECK_EQUAL_WAVES(output[0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(output[1], {2, 3}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(output[2], {"abcd"}, mode = WAVE_DATA)
End
