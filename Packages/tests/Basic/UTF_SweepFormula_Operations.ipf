#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTF_SWEEPFORMULA_OPERATIONS

// IUTF_TD_GENERATOR DataGenerators#TestOperationAPFrequency2Gen
static Function TestOperationAPFrequency2([WAVE wv])

	string win, device, formula
	variable numResults

	formula = note(wv)

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0, sweepGen = FakeSweepDataGeneratorAPF0)
	win = CreateFakeSweepData(win, device, sweepNo = 1, sweepGen = FakeSweepDataGeneratorAPF1)

	WAVE/WAVE outputRef = SF_ExecuteFormula(formula, win, useVariables = 0)
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
	string win

	win = GetDataBrowserWithData()

	// requires at least one arguments
	str = "apfrequency()"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	// but no more than six
	str = "apfrequency([1], 0, 0.5, freq, nonorm, time, 3)"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	// requires valid method
	str = "apfrequency([1], 10)"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	// works with full
	str = "apfrequency(setscale([10, 20, 10, 20, 10, 20], x, 0, 5, ms), 0, 15)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE/D output_ref = {100}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with apcount
	str = "apfrequency(setscale([10, 20, 10, 20, 10, 20], x, 0, 5, ms), 2, 15)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE/D output_ref = {3}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with instantaneous
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 1, 15)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE/D output_ref = {57.14285714285714}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with instantaneous pair
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE/D output_ref = {100 * 2 / 3, 50}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15,freq)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with instantaneous pair time
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15, time)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE/D output_ref = {0.015, 0.02}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15, time, nonorm)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// returns 0 if nothing found for Full
	str = "apfrequency([10, 20, 30, 20], 0, 100)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE/D output_ref = {0}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// returns null wave if nothing found for Instantaneous
	str = "apfrequency([10, 20, 30, 20], 1, 100)"
	WAVE/Z output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	CHECK_WAVE(output, NULL_WAVE)

	// returns null wave if nothing found for Instantaneous Pair
	str = "apfrequency([10, 20, 30, 20], 3, 100)"
	WAVE/Z output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	CHECK_WAVE(output, NULL_WAVE)

	// returns null wave for single peak for Instantaneous Pair
	str = "apfrequency([10, 20, 30, 20], 3, 25)"
	WAVE/Z output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	CHECK_WAVE(output, NULL_WAVE)

	// check meta data
	str = "apfrequency([10, 20, 30, 20], 1, 100)"
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables = 0)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef   = SF_DATATYPE_APFREQUENCY
	CHECK_EQUAL_STR(strRef, dataType)

	// works with instantaneous pair time, norminsweepsmin
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15, time, norminsweepsmin)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE/D output_ref = {1, 0.02 / 0.015}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with instantaneous pair time, norminsweepsmax
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15, time, norminsweepsmax)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE/D output_ref = {0.015 / 0.02, 1}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with instantaneous pair time, norminsweepsavg
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15, time, norminsweepsavg)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE/D output_ref = {0.015 / 0.0175, 0.02 / 0.0175}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// works with instantaneous pair time, norminsweepsavg, time as x-axis
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15, time, norminsweepsavg, time)"
	WAVE/WAVE outputRef = SF_ExecuteFormula(str, win, useVariables = 0)
	Make/FREE/D output_ref = {2.5, 17.5}
	for(data : outputRef)
		WAVE/Z xValues = JWN_GetNumericWaveFromWaveNote(data, SF_META_XVALUES)
		CHECK_WAVE(xValues, NUMERIC_WAVE)
		CHECK_EQUAL_WAVES(xValues, output_Ref, mode = WAVE_DATA)
	endfor

	// works with instantaneous pair time, norminsweepsavg, count as x-axis
	str = "apfrequency(setscale([10, 20, 30, 10, 20, 30, 40, 10, 20], x, 0, 5, ms), 3, 15, time, norminsweepsavg, count)"
	WAVE/WAVE outputRef = SF_ExecuteFormula(str, win, useVariables = 0)
	Make/FREE/D/N=2 output_ref = p
	for(data : outputRef)
		WAVE/Z xValues = JWN_GetNumericWaveFromWaveNote(data, SF_META_XVALUES)
		CHECK_WAVE(xValues, NUMERIC_WAVE)
		CHECK_EQUAL_WAVES(xValues, output_Ref, mode = WAVE_DATA)
	endfor
End

// UTF_TD_GENERATOR DataGenerators#InvalidStoreFormulas
static Function StoreChecksParameters([string str])
	string win

	win = GetDataBrowserWithData()

	CHECK(!ExecuteSweepFormulaInDB(str, win))

	WAVE textualResultsValues = GetLogbookWaves(LBT_RESULTS, LBN_TEXTUAL_VALUES)
	CHECK_EQUAL_VAR(GetNumberFromWaveNote(textualResultsValues, NOTE_INDEX), 0)
End

// UTF_TD_GENERATOR DataGenerators#GetStoreWaves
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
	DFREF  dfr           = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)
	WAVE/Z sweepFormulaY = GetSweepFormulaY(dfr, 0)
	CHECK_EQUAL_VAR(DimSize(sweepFormulaY, COLS), 1)
	Redimension/N=(-1, 0) sweepFormulaY
	CHECK_EQUAL_WAVES(wv, sweepFormulaY, mode = WAVE_DATA)
End

static Function StoreWorksWithMultipleDataSets()
	string str, results

	string textKey   = LABNOTEBOOK_USER_PREFIX + "TEXTKEY"
	string textValue = "TestText"

	string win, device
	variable numSweeps, numChannels

	device = HW_ITC_BuildDeviceString("ITC18USB", "0")
	MarkDeviceAsLocked(device)

	win = DB_GetBoundDataBrowser(device)

	[numSweeps, numChannels, WAVE/U/I channels] = FillFakeDatabrowserWindow(win, device, XOP_CHANNEL_TYPE_ADC, textKey, textValue)

	str = "store(\"ABCD\", data(select(selrange(), selchannels(), selsweeps())))"
	CHECK(ExecuteSweepFormulaInDB(str, win))

	WAVE textualResultsValues = GetLogbookWaves(LBT_RESULTS, LBN_TEXTUAL_VALUES)

	results = GetLastSettingTextIndep(textualResultsValues, NaN, "Sweep Formula store [ABCD]", SWEEP_FORMULA_RESULT)
	CHECK_PROPER_STR(results)

	WAVE/Z resultsWave = JSONToWave(results)
	CHECK_WAVE(resultsWave, WAVE_WAVE)
End

static Function TestOperationWave()

	string str
	string win

	win = GetDataBrowserWithData()

	Make/N=(10) wave0 = p

	str = "wave(wave0)"
	WAVE wave1 = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	str = "range(0,10)"
	WAVE wave2 = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(wave0, wave2, mode = WAVE_DATA)
	REQUIRE_EQUAL_WAVES(wave1, wave2, mode = WAVE_DATA)

	str = "wave(does_not_exist)"
	WAVE/Z wave1 = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	CHECK(!WaveExists(wave1))

	str = "wave()"
	WAVE/Z wave1 = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	CHECK(!WaveExists(wave1))

	KillWaves/Z wave0
End

// UTF_TD_GENERATOR DataGenerators#TestOperationTPBase_TPSS_TPInst_FormulaGetter
static Function TestOperationTPBase_TPSS_TPInst([str])
	string str

	string func, formula, strRef, dataType, dataTypeRef
	string win

	win = GetDataBrowserWithData()

	func        = StringFromList(0, str)
	dataTypeRef = StringFromList(1, str)

	formula = func + "()"
	WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables = 0)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 0)
	dataType = JWN_GetStringFromWaveNote(output, SF_META_DATATYPE)
	CHECK_EQUAL_STR(dataTypeRef, dataType)

	try
		formula = func + "(1)"
		WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables = 0)
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
	strRef   = SF_DATATYPE_TPFIT
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
	string win

	win = GetDataBrowserWithData()

	formula = "tpfit(exp,tau)"
	WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables = 0)
	CheckTPFitResult(output, "exp", "tau", 250)

	formula = "tpfit(doubleexp,tau)"
	WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables = 0)
	CheckTPFitResult(output, "doubleexp", "tau", 250)

	formula = "tpfit(exp,tausmall)"
	WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables = 0)
	CheckTPFitResult(output, "exp", "tausmall", 250)

	formula = "tpfit(exp,amp)"
	WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables = 0)
	CheckTPFitResult(output, "exp", "amp", 250)

	formula = "tpfit(exp,minabsamp)"
	WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables = 0)
	CheckTPFitResult(output, "exp", "minabsamp", 250)

	formula = "tpfit(exp,fitq)"
	WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables = 0)
	CheckTPFitResult(output, "exp", "fitq", 250)

	formula = "tpfit(exp,tau,20)"
	WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables = 0)
	CheckTPFitResult(output, "exp", "tau", 20)

	try
		formula = "tpfit(exp)"
		WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		formula = "tpfit(exp,tau,250,1)"
		WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		formula = "tpfit(1,tau,250)"
		WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		formula = "tpfit(exp,1,250)"
		WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		formula = "tpfit(exp,tau,tau)"
		WAVE/WAVE output = SF_ExecuteFormula(formula, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

// UTF_TD_GENERATOR DataGenerators#FuncCommandGetter
static Function TestVariousFunctions([str])
	string str

	string func, oneDResult, twoDResult
	variable jsonIDOneD, jsonIDTwoD
	string win

	win = GetDataBrowserWithData()

	func       = StringFromList(0, str, ":")
	oneDResult = StringFromList(1, str, ":")
	twoDResult = StringFromList(2, str, ":")

	KillWaves/Z oneD, twoD
	Make/FREE/D/N=5 oneD = p
	Make/FREE/D/N=(5, 2) twoD = p + q

	jsonIDOneD = JSON_NEW()
	JSON_AddWave(jsonIDOneD, "", oneD)
	jsonIDTwoD = JSON_NEW()
	JSON_AddWave(jsonIDTwoD, "", twoD)

	// 1D
	str = func + "(" + JSON_Dump(jsonIDOneD) + ")"
	WAVE output1D = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Execute "Make output1D_mo = {" + oneDResult + "}"
	WAVE output1D_mo

	CHECK_EQUAL_WAVES(output1D, output1D_mo, mode = WAVE_DATA, tol = 1e-8)

	// 2D
	str = func + "(" + JSON_Dump(jsonIDTwoD) + ")"
	WAVE output2D = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Execute "Make output2D_mo = {" + twoDResult + "}"
	WAVE output2D_mo

	CHECK_EQUAL_WAVES(output2D, output2D_mo, mode = WAVE_DATA, tol = 1e-8)

	KillWaves/Z output1D_mo, output2D_mo
End

// test static Functions with 1..N arguments
static Function TestOperationMinMax()

	string str, wavePath
	string win

	win = GetDataBrowserWithData()

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
	Make/D/N=(2, 2, 2) input = p + 2 * q + 4 * r
	wavePath = GetWavesDataFolder(input, 2)
	str      = "min(wave(" + wavePath + "))"
	try
		WAVE data = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	str = "max(wave(" + wavePath + "))"
	try
		WAVE data = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	str = "avg(wave(" + wavePath + "))"
	try
		WAVE data = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	KillWaves input
End

static Function TestOperationText()

	string str, strRef, wavePath
	string win

	win = GetDataBrowserWithData()

	str = "text()"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	str = "text([[5.1234567, 1], [2, 3]])"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE/T refData = {{"5.1234567", "2.0000000"}, {"1.0000000", "3.0000000"}}
	REQUIRE_EQUAL_WAVES(refData, output, mode = WAVE_DATA)

	// check copy of wave note on text
	Make/D/N=1 testData
	strRef = "WaveNoteCopyTest"
	Note/K testData, strRef
	wavePath = GetWavesDataFolder(testData, 2)
	str      = "text(wave(" + wavePath + "))"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	str = note(output)
	CHECK_EQUAL_STR(strRef, str)

	KillWaves testData
End

static Function TestOperationLog()

	string histo, histoAfter, str, strRef
	string win

	win = GetDataBrowserWithData()

	str = "log()"
	WAVE/WAVE outputRef = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(DimSize(outputRef, ROWS), 0)

	histo = GetHistoryNotebookText()
	str   = "log(1, 10, 100)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	histoAfter = GetHistoryNotebookText()
	Make/FREE/D refData = {1, 10, 100}
	histo = ReplaceString(histo, histoAfter, "")
	REQUIRE_EQUAL_WAVES(refData, output, mode = WAVE_DATA)
	strRef = "  1\r"
	REQUIRE_EQUAL_STR(strRef, histo)

	histo = GetHistoryNotebookText()
	str   = "log(a, bb, ccc)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	histoAfter = GetHistoryNotebookText()
	Make/FREE/T refDataT = {"a", "bb", "ccc"}
	histo = ReplaceString(histo, histoAfter, "")
	REQUIRE_EQUAL_WAVES(refDataT, output, mode = WAVE_DATA)
	strRef = "  a\r"
	REQUIRE_EQUAL_STR(strRef, histo)

	str = "log(1)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE wRef = {1}
	CHECK_EQUAL_WAVES(wRef, output, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "log(1, 2)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE wRef = {1, 2}
	CHECK_EQUAL_WAVES(wRef, output, mode = WAVE_DATA | DIMENSION_SIZES)

	Make testData = {1, 2}
	str = "log(wave(" + GetWavesDataFolder(testData, 2) + "))"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Duplicate/FREE testData, refData
	CHECK_EQUAL_WAVES(refData, output, mode = WAVE_DATA | DIMENSION_SIZES)

	KillWaves/Z testData
End

static Function TestOperationButterworth()

	string str, strref, dataType
	string win

	win = GetDataBrowserWithData()

	str = "butterworth()"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
	str = "butterworth(1)"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
	str = "butterworth(1, 1)"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
	str = "butterworth(1, 1, 1)"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
	str = "butterworth(1, 1, 1, 1, 1)"
	try
		WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	Make/FREE/D refData = {0, 0.863870777482797, 0.235196115045368, 0.692708791122301, 0.359757805059761, 0.602060073208013, 0.425726643942363, 0.554051807855231}
	str = "butterworth([0,1,0,1,0,1,0,1], 90E3, 100E3, 2)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(refData, output, mode = WAVE_DATA, tol = 1E-9)
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables = 0)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef   = SF_DATATYPE_BUTTERWORTH
	CHECK_EQUAL_STR(strRef, dataType)
End

static Function TestOperationSelChannels()

	string win, str

	win = GetDataBrowserWithData()

	Make/FREE input = {{0}, {NaN}}
	SetDimLabel COLS, 0, channelType, input
	SetDimLabel COLS, 1, channelNumber, input
	str = "selchannels(AD)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input, output)

	Make/FREE input = {{0}, {0}}
	str = "selchannels(AD0)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{0, 0}, {0, 1}}
	str = "selchannels(AD0,AD1)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{0, 1}, {0, 1}}
	str = "selchannels(AD0,DA1)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{1, 1}, {0, 0}}
	str = "selchannels(DA0,DA0)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{0, 1}, {NaN, NaN}}
	str = "selchannels(AD,DA)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{NaN}, {1}}
	str = "selchannels(1)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{NaN, NaN}, {1, 3}}
	str = "selchannels(1,3)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{0, 1, NaN}, {1, 2, 3}}
	str = "selchannels(AD1,DA2,3)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	Make/FREE input = {{NaN}, {NaN}}
	str = "selchannels()"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(input, output, mode = WAVE_DATA)

	str = "selchannels(unknown)"
	try
		SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestOperationDifferentiateIntegrate()

	variable array
	string str, strRef, dataType, wavePath
	string win

	win = GetDataBrowserWithData()

	// differentiate/integrate 1D waves along rows
	str = "derivative([0,1,4,9,16,25,36,49,64,81])"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/N=10/U/I/FREE sourcewave = p^2
	Differentiate/EP=0 sourcewave / D=testwave
	MakeWaveFree(testwave)
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables = 0)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef   = SF_DATATYPE_DERIVATIVE
	CHECK_EQUAL_STR(strRef, dataType)

	Make/N=10/U/I/FREE input = p^2
	wfprintf str, "%d,", input
	str = "derivative([" + RemoveEnding(str, ",") + "])"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/N=10/FREE testwave = 2 * p
	Deletepoints 9, 1, testwave, output
	Deletepoints 0, 1, testwave, output
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	Make/N=10/U/I/FREE input = 2 * p
	wfprintf str, "%d,", input
	str = "integrate([" + RemoveEnding(str, ",") + "])"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/N=10/FREE testwave = p^2
	Deletepoints 9, 1, testwave, output
	Deletepoints 0, 1, testwave, output
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables = 0)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef   = SF_DATATYPE_INTEGRATE
	CHECK_EQUAL_STR(strRef, dataType)

	Make/N=(128)/U/I/FREE input = p
	wfprintf str, "%d,", input
	str = "derivative(integrate([" + RemoveEnding(str, ",") + "]))"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Deletepoints 127, 1, input, output
	Deletepoints 0, 1, input, output
	REQUIRE_EQUAL_WAVES(output, input, mode = WAVE_DATA)

	Make/N=(128)/U/I/FREE input = p^2
	wfprintf str, "%d,", input
	str = "integrate(derivative([" + RemoveEnding(str, ",") + "]))"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	output -= 0.5 // expected end point error from first point estimation
	Deletepoints 127, 1, input, output
	Deletepoints 0, 1, input, output
	REQUIRE_EQUAL_WAVES(output, input, mode = WAVE_DATA)

	// differentiate 2d waves along columns
	Make/N=(128, 16)/U/I/FREE input = p + q
	array = JSON_New()
	JSON_AddWave(array, "", input)
	str = "derivative(integrate(" + JSON_Dump(array) + "))"
	JSON_Release(array)
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Deletepoints/M=(ROWS) 127, 1, input, output
	Deletepoints/M=(ROWS) 0, 1, input, output
	REQUIRE_EQUAL_WAVES(output, input, mode = WAVE_DATA)

	// check copy of wave note on integrate
	Make/D/N=1 testData
	strRef = "WaveNoteCopyTest"
	Note/K testData, strRef
	wavePath = GetWavesDataFolder(testData, 2)
	str      = "integrate(wave(" + wavePath + "))"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	str = note(output)
	CHECK_EQUAL_STR(strRef, str)
	KillWaves/Z testData

	// check copy of wave note on derivative
	Make/D/N=2 testData
	strRef = "WaveNoteCopyTest"
	Note/K testData, strRef
	wavePath = GetWavesDataFolder(testData, 2)
	str      = "derivative(wave(" + wavePath + "))"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	str = note(output)
	CHECK_EQUAL_STR(strRef, str)
	KillWaves/Z testData
End

static Function TestOperationArea()

	variable array
	string str, strref, dataType
	string win

	win = GetDataBrowserWithData()

	// rectangular triangle has area 1/2 * a * b
	// non-zeroed
	str = "area([0,1,2,3,4], 0)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE testwave = {8}
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	// zeroed
	str = "area([0,1,2,3,4], 1)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE testwave = {4}
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	// x scaling is taken into account
	str = "area(setscale([0,1,2,3,4], x, 0, 2, unit), 0)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE testwave = {16}
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	// does operate column wise
	Make/FREE/N=(5, 2) input
	input[][0] = p
	input[][1] = p + 1
	array      = JSON_New()
	JSON_AddWave(array, "", input)
	str = "area(" + JSON_Dump(array) + ", 0)"
	JSON_Release(array)

	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	// 0th column: see above
	// 1st column: imagine 0...5 and remove 0..1 which gives 12.5 - 0.5
	Make/FREE testwave = {8, 12}
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	// check meta data
	str = "area([0,1,2,3,4], 0)"
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables = 0)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef   = SF_DATATYPE_AREA
	CHECK_EQUAL_STR(strRef, dataType)
End

static Function TestOperationSetscale()

	string   wavePath
	variable ref
	string refUnit, unit
	string str, strRef, dataScale
	string win

	win = GetDataBrowserWithData()

	str = "setscale([0,1,2,3,4,5,6,7,8,9], x, 0, 2, unit)"
	WAVE wv = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/N=(10)/FREE waveX = p
	SetScale x, 0, 2, "unit", waveX
	REQUIRE_EQUAL_WAVES(waveX, wv, mode = WAVE_DATA)

	str = "setscale(setscale([range(10),range(10)+1,range(10)+2,range(10)+3,range(10)+4,range(10)+5,range(10)+6,range(10)+7,range(10)+8,range(10)+9], x, 0, 2, unitX), y, 0, 4, unitX)"
	WAVE wv = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/N=(10, 10)/FREE waveXY = p + q
	SetScale/P x, 0, 2, "unitX", waveXY
	SetScale/P y, 0, 4, "unitX", waveXY
	REQUIRE_EQUAL_WAVES(waveXY, wv, mode = WAVE_DATA | WAVE_SCALING | DATA_UNITS)

	Make/O/D/N=(2, 2, 2, 2) input = p + 2 * q + 4 * r + 8 * s
	wavePath = GetWavesDataFolder(input, 2)
	refUnit  = "unit"
	str      = "setscale(wave(" + wavePath + "), z, 0, 2, " + refUnit + ")"
	WAVE data = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	ref = DimDelta(data, LAYERS)
	REQUIRE_EQUAL_VAR(ref, 2)
	unit = WaveUnits(data, LAYERS)
	REQUIRE_EQUAL_STR(refUnit, unit)

	Make/O/D/N=(2, 2, 2, 2) input = p + 2 * q + 4 * r + 8 * s
	wavePath = GetWavesDataFolder(input, 2)
	refUnit  = "unit"
	str      = "setscale(wave(" + wavePath + "), t, 0, 2, " + refUnit + ")"
	WAVE data = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	ref = DimDelta(data, CHUNKS)
	REQUIRE_EQUAL_VAR(ref, 2)
	unit = WaveUnits(data, CHUNKS)
	REQUIRE_EQUAL_STR(refUnit, unit)

	Make/O/D/N=0 input
	wavePath = GetWavesDataFolder(input, 2)
	refUnit  = "unit"
	str      = "setscale(wave(" + wavePath + "), d, 2, 0, " + refUnit + ")"
	WAVE data = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	unit = WaveUnits(data, -1)
	REQUIRE_EQUAL_STR(refUnit, unit)
	strRef    = "1,2,0"
	dataScale = StringByKey("FULLSCALE", WaveInfo(data, 0))
	REQUIRE_EQUAL_STR(strRef, dataScale)

	KillWaves/Z input
End

static Function TestOperationRange()

	variable jsonID0, jsonID1

	string str, strRef, dataType
	string win

	win = GetDataBrowserWithData()

	jsonID0 = DirectToFormulaParser("1…10")
	jsonID1 = JSON_Parse("{\"…\":[1,10]}")
	CHECK_EQUAL_JSON(jsonID0, jsonID1)

	str = "1…10"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/N=9/U/I/FREE testwave = 1 + p
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	str = "range(1,10)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	str = "range(10)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/N=10/U/I/FREE testwave = p
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	str = "range(1,10,2)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/N=5/U/I/FREE testwave = 1 + p * 2
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	str = "1.5…10.5"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/N=9/FREE floatwave = 1.5 + p
	REQUIRE_EQUAL_WAVES(output, floatwave, mode = WAVE_DATA)

	// check meta data
	str = "range(1,10)"
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables = 0)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef   = SF_DATATYPE_RANGE
	CHECK_EQUAL_STR(strRef, dataType)
End

static Function TestOperationFindLevel()

	string str, strRef, dataType
	string win

	win = GetDataBrowserWithData()

	// requires at least two arguments
	try
		str = "findlevel()"
		WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "findlevel([1])"
		WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	// but no more than three
	try
		str = "findlevel([1], 2, 3, 4)"
		WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	// works
	str = "findlevel([10, 20, 30, 20], 25)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE output_ref = {1.5}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// supports rising edge only
	str = "findlevel([10, 20, 30, 20], 25, 1)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE output_ref = {1.5}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// supports falling edge only
	str = "findlevel([10, 20, 30, 20], 25, 2)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE output_ref = {2.5}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// errors out on invalid edge
	try
		str = "findlevel([10, 20, 30, 20], 25, 3)"
		WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	// works with 2D data
	str = "findlevel([[10, 10], [20, 20], [30, 30]], 15)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE output_ref = {0.5, 0.5}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// returns x coordinates and not indizes
	str = "findlevel(setscale([[10, 10], [20, 20], [30, 30]], x, 4, 0.5), 15)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE output_ref = {4.25, 4.25}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// returns NaN if nothing found
	str = "findlevel([10, 20, 30, 20], 100)"
	WAVE output = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE output_ref = {NaN}
	REQUIRE_EQUAL_WAVES(output, output_ref, mode = WAVE_DATA)

	// check meta data
	str = "findlevel([10, 20, 30, 20], 25)"
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables = 0)
	dataType = JWN_GetStringFromWaveNote(dataRef, SF_META_DATATYPE)
	strRef   = SF_DATATYPE_FINDLEVEL
	CHECK_EQUAL_STR(strRef, dataType)
End

static Function TestOperationAverage()

	string win, device
	string          str
	STRUCT RGBColor s

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)
	win = CreateFakeSweepData(win, device, sweepNo = 1)

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

	str = "avg(data(select(selrange(),selchannels(AD),selsweeps(),selvis(all))), in)"
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win)
	CHECK_EQUAL_VAR(DimSize(dataRef, ROWS), 4)
	Make/FREE/D ref = {4.5}
	for(data : dataRef)
		CHECK_EQUAL_WAVES(data, ref, mode = WAVE_DATA)
	endfor

	str = "avg(data(select(selrange(),selchannels(AD),selsweeps(),selvis(all))), over)"
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

static Function CheckSweepsFromData(WAVE/WAVE dataWref, WAVE sweepRef, variable numResults, WAVE chanIndex, [WAVE ranges])

	variable i

	REQUIRE_EQUAL_VAR(DimSize(dataWref, ROWS), numResults)
	for(i = 0; i < numResults; i += 1)
		WAVE sweepData = dataWref[i]
		Duplicate/FREE/RMD=[][chanIndex[i]] sweepRef, sweepDataRef
		Redimension/N=(-1) sweepDataRef
		if(!ParamIsDefault(ranges))
			Duplicate/FREE/RMD=[ranges[i][0], ranges[i][1] - 1] sweepDataRef, sweepDataRanged
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
		sweepNo       = JWN_GetNumberFromWaveNote(sweepData, SF_META_SWEEPNO)
		channelNumber = JWN_GetNumberFromWaveNote(sweepData, SF_META_CHANNELNUMBER)
		channelType   = JWN_GetNumberFromWaveNote(sweepData, SF_META_CHANNELTYPE)
		CHECK_EQUAL_VAR(sweepNumbers[i], sweepNo)
		CHECK_EQUAL_VAR(channelTypes[i], channelType)
		CHECK_EQUAL_VAR(channelNumbers[i], channelNumber)
	endfor
End

static Function TestOperationSelsweeps()

	string win, device, str
	variable i
	variable numSweeps = 4

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	for(i = 0; i < numSweeps; i += 1)
		win = CreateFakeSweepData(win, device, sweepNo = i)
	endfor

	str = "selsweeps()"
	WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_WAVE(wref, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(wref, ROWS), 1)
	WAVE array = wref[0]
	CHECK_EQUAL_WAVES(array, {0, 1, 2, 3}, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selsweeps(2,3)"
	WAVE/WAVE wref  = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE      array = wref[0]
	CHECK_EQUAL_WAVES(array, {2, 3}, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selsweeps(1...4)"
	WAVE/WAVE wref  = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE      array = wref[0]
	CHECK_EQUAL_WAVES(array, {1, 2, 3}, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selsweeps(1...4, 0)"
	WAVE/WAVE wref  = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE      array = wref[0]
	CHECK_EQUAL_WAVES(array, {1, 2, 3, 0}, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selsweeps(abc)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestOperationSelvis()

	string win, device, str

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	str = "selvis()"
	WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_WAVE(wref, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(wref, ROWS), 1)
	WAVE/T array = wref[0]
	Make/FREE/T ref = {"displayed"}
	CHECK_EQUAL_WAVES(array, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selvis(displayed)"
	WAVE/WAVE wref  = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/T    array = wref[0]
	Make/FREE/T ref = {"displayed"}
	CHECK_EQUAL_WAVES(array, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selvis(all)"
	WAVE/WAVE wref  = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/T    array = wref[0]
	Make/FREE/T ref = {"all"}
	CHECK_EQUAL_WAVES(array, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selvis(invalid_option)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	str = "selvis(123)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestOperationSelcm()

	string win, device, str

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	str = "selcm()"
	WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_WAVE(wref, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(wref, ROWS), 1)
	WAVE array = wref[0]
	CHECK_EQUAL_WAVES(array, {SF_OP_SELECT_CLAMPCODE_ALL}, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selcm(all)"
	WAVE/WAVE wref  = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE      array = wref[0]
	CHECK_EQUAL_WAVES(array, {SF_OP_SELECT_CLAMPCODE_ALL}, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selcm(ic)"
	WAVE/WAVE wref  = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE      array = wref[0]
	CHECK_EQUAL_WAVES(array, {SF_OP_SELECT_CLAMPCODE_IC}, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selcm(vc)"
	WAVE/WAVE wref  = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE      array = wref[0]
	CHECK_EQUAL_WAVES(array, {SF_OP_SELECT_CLAMPCODE_VC}, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selcm(izero)"
	WAVE/WAVE wref  = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE      array = wref[0]
	CHECK_EQUAL_WAVES(array, {SF_OP_SELECT_CLAMPCODE_IZERO}, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selcm(none)"
	WAVE/WAVE wref  = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE      array = wref[0]
	CHECK_EQUAL_WAVES(array, {SF_OP_SELECT_CLAMPCODE_NONE}, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selcm(ic, vc)"
	WAVE/WAVE wref  = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE      array = wref[0]
	CHECK_EQUAL_WAVES(array, {SF_OP_SELECT_CLAMPCODE_IC | SF_OP_SELECT_CLAMPCODE_VC}, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selcm(none, ic, vc, izero)"
	WAVE/WAVE wref  = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE      array = wref[0]
	CHECK_EQUAL_WAVES(array, {SF_OP_SELECT_CLAMPCODE_ALL}, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selcm(invalid_option)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	str = "selcm(123)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestOperationSelstimset()

	string win, device, str

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	str = "selstimset()"
	WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_WAVE(wref, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(wref, ROWS), 1)
	WAVE/T array = wref[0]
	Make/FREE/T ref = {"*"}
	CHECK_EQUAL_WAVES(array, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selstimset(enjoy, the, silence)"
	WAVE/WAVE wref  = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/T    array = wref[0]
	Make/FREE/T ref = {"enjoy", "the", "silence"}
	CHECK_EQUAL_WAVES(array, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selstimset(123)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

// IUTF_TD_GENERATOR DataGenerators#SF_TestOperationSelSingleText
static Function TestOperationSelSingleText([string str])

	string win, device, formula

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	formula = str + "(AKAelectricRG28)"
	WAVE/WAVE wref  = SF_ExecuteFormula(formula, win, useVariables = 0)
	WAVE/T    array = wref[0]
	Make/FREE/T ref = {"AKAelectricRG28"}
	CHECK_EQUAL_WAVES(array, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	formula = str + "()"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(formula, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
	formula = str + "(123)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(formula, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
	formula = str + "(dev1, dev2)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(formula, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

// IUTF_TD_GENERATOR DataGenerators#SF_TestOperationSelNoArg
static Function TestOperationSelNoArg([string str])

	string win, device, formula

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	formula = str + "()"
	WAVE/WAVE wref  = SF_ExecuteFormula(formula, win, useVariables = 0)
	WAVE/T    array = wref[0]
	Make/FREE ref = {1}
	CHECK_EQUAL_WAVES(array, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	formula = str + "(123)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(formula, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
	formula = str + "(exp1, exp2)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(formula, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

// IUTF_TD_GENERATOR DataGenerators#SF_TestOperationSelSingleNumber
static Function TestOperationSelSingleNumber([string str])

	string win, device, formula

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	formula = "selsetcyclecount(123)"
	WAVE/WAVE wref  = SF_ExecuteFormula(formula, win, useVariables = 0)
	WAVE/T    array = wref[0]
	Make/FREE ref = {123}
	CHECK_EQUAL_WAVES(array, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	formula = str + "()"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(formula, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
	formula = str + "(text)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(formula, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
	formula = str + "(1, 2)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(formula, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestOperationSelIVSCCSweepQC()

	string win, device, str

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	str = "selivsccsweepqc(passed)"
	WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_WAVE(wref, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(wref, ROWS), 1)
	WAVE/T array = wref[0]
	Make/FREE ref = {SF_OP_SELECT_IVSCCSWEEPQC_PASSED}
	CHECK_EQUAL_WAVES(array, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selivsccsweepqc(failed)"
	WAVE/WAVE wref  = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/T    array = wref[0]
	Make/FREE ref = {SF_OP_SELECT_IVSCCSWEEPQC_FAILED}
	CHECK_EQUAL_WAVES(array, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selivsccsweepqc(invalid_option)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	str = "selivsccsweepqc(123)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestOperationSelRange()

	string win, device, str

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	str = "selrange()"
	WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_WAVE(wref, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(wref, ROWS), 1)
	WAVE/WAVE set = wref[0]
	CHECK_WAVE(set, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(set, ROWS), 1)
	WAVE array = set[0]
	WAVE ref   = SFH_GetFullRange()
	CHECK_EQUAL_WAVES(array, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selrange([1,2])"
	WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/WAVE set  = wref[0]
	CHECK_WAVE(set, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(set, ROWS), 1)
	WAVE array = set[0]
	CHECK_EQUAL_WAVES(array, {1, 2}, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selrange(abc)"
	WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/WAVE set  = wref[0]
	CHECK_WAVE(set, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(set, ROWS), 1)
	WAVE/T arrayT = set[0]
	Make/FREE/T refT = {"abc"}
	CHECK_EQUAL_WAVES(arrayT, refT, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selrange(abc, def)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	str = "selrange(123,456)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestOperationSelIVSCCSetQC()

	string win, device, str

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	str = "selivsccsetqc(passed)"
	WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_WAVE(wref, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(wref, ROWS), 1)
	WAVE/T array = wref[0]
	Make/FREE ref = {SF_OP_SELECT_IVSCCSWEEPQC_PASSED}
	CHECK_EQUAL_WAVES(array, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selivsccsetqc(failed)"
	WAVE/WAVE wref  = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/T    array = wref[0]
	Make/FREE ref = {SF_OP_SELECT_IVSCCSWEEPQC_FAILED}
	CHECK_EQUAL_WAVES(array, ref, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "selivsccsetqc(invalid_option)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	str = "selivsccsetqc(123)"
	try
		WAVE/WAVE wref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestOperationData()

	variable i, j, numChannels, sweepNo, sweepCnt, numResultsRef, clampMode
	string str, strSelect, epochStr, name, trace, wvList
	string win, device
	variable mode              = DATA_ACQUISITION_MODE
	variable numSweeps         = 2
	variable dataSize          = 10
	variable rangeStart0       = 3
	variable rangeEnd0         = 6
	variable rangeStart1       = 1
	variable rangeEnd1         = 8
	string   channelTypeList   = "DA;AD;DA;AD;"
	string   channelNumberList = "2;6;3;7;"
	Make/FREE/T/N=(3, 1, 1) epochKeys, epochTTLKeys
	epochKeys[0][0][0] = EPOCHS_ENTRY_KEY
	epochKeys[2][0][0] = LABNOTEBOOK_NO_TOLERANCE

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	sweepNo = 0

	win = CreateFakeSweepData(win, device, sweepNo = sweepNo)
	win = CreateFakeSweepData(win, device, sweepNo = sweepNo + 1)
	win = CreateFakeSweepData(win, device, sweepNo = sweepNo + 2)
	win = CreateFakeSweepData(win, device, sweepNo = sweepNo + 3)

	epochStr  = "0.00" + num2istr(rangeStart0) + ",0.00" + num2istr(rangeEnd0) + ",ShortName=TestEpoch,0,:"
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
	WAVE sweepRef  = FakeSweepDataGeneratorDefault(sweepTemplate, numChannels)
	WAVE sweepRef3 = FakeSweepDataGeneratorDefault(sweepTemplate, 5)
	sweepRef3[][4] = (sweepRef3[p][4] & 1 << 2) != 0

	sweepCnt = 1
	str      = "data(select(selrange(TestEpoch2),selchannels(TTL2),selsweeps(" + num2istr(3) + "),selvis(all)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	numResultsRef = sweepCnt * 1
	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[][0] = rangeStart1
	ranges[][1] = rangeEnd1
	CheckSweepsFromData(dataWref, sweepRef3, numResultsref, {5}, ranges = ranges)
	CheckSweepsMetaData(dataWref, {3}, {2}, {3}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str      = "data(select(selrange(),selchannels(AD),selsweeps(" + num2istr(sweepNo) + "),selvis(all)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	numResultsRef = sweepCnt * numChannels / 2
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3})
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {0, 0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str      = "data(select(selrange([0, inf]),selchannels(AD),selsweeps(" + num2istr(sweepNo) + "),selvis(all)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	numResultsRef = sweepCnt * numChannels / 2
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3})
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {0, 0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str      = "data(select(selrange(),selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "),selvis(all)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	numResultsRef = sweepCnt * 1
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1})
	CheckSweepsMetaData(dataWref, {0}, {6}, {0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str      = "data(select(selrange(TestEpoch),selchannels(AD),selsweeps(" + num2istr(sweepNo) + "),selvis(all)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	numResultsRef = sweepCnt * numChannels / 2
	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[][0] = rangeStart0
	ranges[][1] = rangeEnd0
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3}, ranges = ranges)
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {0, 0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str      = "data(select(selrange(\"Test*\"),selchannels(AD),selsweeps(" + num2istr(sweepNo) + "),selvis(all)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
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
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {3, 1, 3, 1}, ranges = ranges)
	CheckSweepsMetaData(dataWref, {0, 0, 0, 0}, {6, 6, 7, 7}, {0, 0, 0, 0}, SF_DATATYPE_SWEEP)

	// this part specifies to numerical range 0,2 and 0,4
	// Selected is sweep 0, AD, channel 6 and sweep 0, AD, channel 7
	sweepCnt  = 1
	strSelect = "select(selrange([[0,0],[2,4]]),selchannels(AD),selsweeps(" + num2istr(sweepNo) + "),selvis(all))"
	str       = "data(" + strSelect + ")"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	numResultsRef = sweepCnt * numChannels / 2 * 2 // 2 ranges specified

	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[0][0] = 0
	ranges[0][1] = 2
	ranges[1][0] = 0
	ranges[1][1] = 4
	ranges[2][0] = 0
	ranges[2][1] = 2
	ranges[3][0] = 0
	ranges[3][1] = 4
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3, 1, 3}, ranges = ranges)
	CheckSweepsMetaData(dataWref, {0, 0, 0, 0}, {6, 6, 7, 7}, {0, 0, 0, 0}, SF_DATATYPE_SWEEP)

	// This part uses a epochs operation with offset to retrieve ranges
	// Selected is sweep 0, AD, channel 6 and sweep 0, AD, channel 7
	// The epoch "TestEpoch" is retrieved for both and offsetted by zero.
	sweepCnt = 1
	str      = "sel = select(selchannels(AD),selsweeps(" + num2istr(sweepNo) + "),selvis(all))\r"
	str      = str + "ep = epochs(\"TestEpoch\",$sel)+[0,0]\r"
	str      = str + "data(select(selrange($ep),$sel))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 1)
	numResultsRef = sweepCnt * numChannels / 2

	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[0][0] = rangeStart0
	ranges[0][1] = rangeEnd0
	ranges[1][0] = rangeStart0
	ranges[1][1] = rangeEnd0
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3}, ranges = ranges)
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {0, 0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str      = "data(select(selrange([\"TestEpoch\",\"TestEpoch1\"]),selchannels(AD),selsweeps(" + num2istr(sweepNo) + "),selvis(all)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
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
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {3, 1, 3, 1}, ranges = ranges)
	CheckSweepsMetaData(dataWref, {0, 0, 0, 0}, {6, 6, 7, 7}, {0, 0, 0, 0}, SF_DATATYPE_SWEEP)

	// Finds the NoShortName epoch
	sweepCnt = 1
	str      = "data(select(selrange(\"!TestEpoch*\"),selchannels(AD),selsweeps(" + num2istr(sweepNo) + "),selvis(all)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	numResultsRef = sweepCnt * numChannels / 2

	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[][0] = rangeStart0
	ranges[][1] = rangeEnd1
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {3, 1}, ranges = ranges)
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {0, 0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str      = "data(select(selrange(TestEpoch),selchannels(AD),selsweeps(" + num2istr(sweepNo + 1) + "),selvis(all)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	numResultsRef = sweepCnt * numChannels / 2
	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[][0] = rangeStart1
	ranges[][1] = rangeEnd1
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3}, ranges = ranges)
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {1, 1}, SF_DATATYPE_SWEEP)

	sweepCnt = 2
	str      = "data(select(selrange(TestEpoch),selchannels(AD),selsweeps(" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "),selvis(all)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	numResultsRef = sweepCnt * numChannels / 2
	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[][0] = p >= 2 ? rangeStart1 : rangeStart0
	ranges[][1] = p >= 2 ? rangeEnd1 : rangeEnd0
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3, 1, 3}, ranges = ranges)
	CheckSweepsMetaData(dataWref, {0, 0, 0, 0}, {6, 7, 6, 7}, {0, 0, 1, 1}, SF_DATATYPE_SWEEP)

	// FAIL Tests
	// non existing channel
	str = "data(select(selrange(TestEpoch),selchannels(AD4),selsweeps(" + num2istr(sweepNo) + "),selvis(all)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	REQUIRE_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// non existing sweep
	str = "data(select(selrange(TestEpoch),selchannels(AD),selsweeps(" + num2istr(sweepNo + 1337) + "),selvis(all)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	REQUIRE_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// non existing epoch
	str = "data(select(selrange(WhatEpochIsThis),selchannels(AD),selsweeps(" + num2istr(sweepNo) + "),selvis(all)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	REQUIRE_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// empty range from epochs
	str = "sel = select(selchannels(AD),selsweeps(" + num2istr(sweepNo) + "),selvis(all))\r"
	str = str + "ep = epochs(WhatEpochIsThis, $sel)\r"
	str = str + "data(select(selrange($ep),$sel))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 1)
	REQUIRE_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// one null range from epochs as TestEpoch1 only exists for sweepNo
	str = "sel = select(selchannels(AD6),selsweeps(" + num2istr(sweepNo) + ", " + num2istr(sweepNo + 1) + "),selvis(all))\r"
	str = str + "ep = epochs(TestEpoch1, $sel)\r"
	str = str + "data(select(selrange($ep),$sel))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 1)
	REQUIRE_EQUAL_VAR(DimSize(dataWref, ROWS), 1)
	REQUIRE_EQUAL_VAR(DimSize(dataWref[0], ROWS), 5)

	str = "data(1, 2)"
	try
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	// range begin
	str = "data(select(selrange([12, 10]),selchannels(AD),selsweeps(" + num2istr(sweepNo) + "),selvis(all)))"
	try
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	// range end
	str = "data(select(selrange([0, 11]),selchannels(AD),selsweeps(" + num2istr(sweepNo) + "),selvis(all)))"
	try
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	// One sweep does not exist, it is not result of select, we end up with one sweep
	sweepCnt = 1
	str      = "data(select(selrange(),selchannels(AD),selsweeps(" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1337) + "),selvis(all)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	numResultsRef = sweepCnt * numChannels / 2
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3})
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {0, 0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str      = "sel1 = select(selrange(),selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "),selvis(all))\r"
	str      = str + "sel2 = select(selrange(),selchannels(AD7),selsweeps(" + num2istr(sweepNo) + "),selvis(all))\r"
	str      = str + "data([$sel1, $sel2])"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 1)
	numResultsRef = sweepCnt * numChannels / 2
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3})
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 7}, {0, 0}, SF_DATATYPE_SWEEP)

	sweepCnt = 1
	str      = "sel1 = select(selrange([0, 2]),selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "),selvis(all))\r"
	str      = str + "sel2 = select(selrange([0, 4]),selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "),selvis(all))\r"
	str      = str + "data([$sel1, $sel2])"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 1)
	numResultsRef = sweepCnt * numChannels / 2

	Make/FREE/N=(numResultsRef, 2) ranges
	ranges[][0]  = 0
	ranges[][1]  = {2, 4}
	ranges[0][0] = 0
	ranges[0][1] = 2
	ranges[1][0] = 0
	ranges[1][1] = 4
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3}, ranges = ranges)
	CheckSweepsMetaData(dataWref, {0, 0}, {6, 6}, {0, 0}, SF_DATATYPE_SWEEP)

	// Setup graph with equivalent data
	TUD_Clear(win)

	Make/FREE/N=(dataSize, numSweeps, numChannels) input = q + p^r
	for(i = 0; i < numSweeps; i += 1)
		sweepNo = i
		for(j = 0; j < numChannels; j += 1)
			name      = UniqueName("data", 1, 0)
			trace     = "trace_" + name
			clampMode = mod(sweepNo, 2) ? V_CLAMP_MODE : I_CLAMP_MODE
			Extract input, $name, q == i && r == j
			WAVE wv = $name
			AppendToGraph/W=$win wv/TN=$trace
			WAVE numericalValues = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweepNo)
			WAVE textualValues   = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = sweepNo)
			TUD_SetUserDataFromWaves(win, trace, {"experiment", "textualValues", "numericalValues", "fullPath", "traceType", "occurence", "channelType", "channelNumber", "sweepNumber", "GUIChannelNumber", "clampMode", "SweepMapIndex"},                                                                                        \
			                         {"blah", GetWavesDataFolder(textualValues, 2), GetWavesDataFolder(numericalValues, 2), GetWavesDataFolder(wv, 2), "Sweep", "0", StringFromList(j, channelTypeList), StringFromList(j, channelNumberList), num2istr(sweepNo), StringFromList(j, channelNumberList), num2istr(clampMode), "NaN"})
		endfor
	endfor

	Make/FREE/N=(DimSize(sweepRef, ROWS), 2, numChannels) dataRef
	dataRef[][][] = sweepRef[p]

	sweepCnt = 2
	str      = "data(select())"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	numResultsRef = sweepCnt * numChannels
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3, 0, 2, 1, 3, 0, 2})
	CheckSweepsMetaData(dataWref, {0, 0, 1, 1, 0, 0, 1, 1}, {6, 7, 2, 3, 6, 7, 2, 3}, {0, 0, 0, 0, 1, 1, 1, 1}, SF_DATATYPE_SWEEP)
	str = "data()"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CheckSweepsFromData(dataWref, sweepRef, numResultsref, {1, 3, 0, 2, 1, 3, 0, 2})
	CheckSweepsMetaData(dataWref, {0, 0, 1, 1, 0, 0, 1, 1}, {6, 7, 2, 3, 6, 7, 2, 3}, {0, 0, 0, 0, 1, 1, 1, 1}, SF_DATATYPE_SWEEP)

	// Using the setup from data we also test cursors operation
	Cursor/W=$win/A=1/P A, $trace, 0
	Cursor/W=$win/A=1/P B, $trace, trunc(dataSize / 2)
	Make/FREE dataRef = {0, trunc(dataSize / 2)}
	str = "cursors(A,B)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA)
	str = "cursors()"
	WAVE data = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	REQUIRE_EQUAL_WAVES(dataRef, data, mode = WAVE_DATA)

	try
		str = "cursors(X,Y)"
		WAVE data = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	// workaround permanent waves being present
	wvList = GetListOfObjects(GetDataFolderDFR(), "data*")
	CallFunctionForEachListItem_TS(KillOrMoveToTrashPath, wvList)
End

Function/WAVE FakeSweepDataGeneratorPS(WAVE sweep, variable numChannels)

	variable pnts       = 100000
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
	string channelTypeList   = "DA;AD;DA;AD;"
	string channelNumberList = "2;6;3;7;"

	variable sweepNo, val
	string str, strRef

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	sweepNo = 0
	FUNCREF FakeSweepDataGeneratorProto sweepGen = FakeSweepDataGeneratorPS

	win = CreateFakeSweepData(win, device, sweepNo = sweepNo, sweepGen = FakeSweepDataGeneratorPS)
	win = CreateFakeSweepData(win, device, sweepNo = sweepNo + 1, sweepGen = FakeSweepDataGeneratorPS)

	str = "powerspectrum(data(select(selrange(),selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "),selvis(all))))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WaveStats/Q/M=1 data
	CHECK_CLOSE_VAR(V_maxLoc, 100, tol = 0.01)
	CHECK_EQUAL_VAR(trunc(V_min), 0)
	CHECK_CLOSE_VAR(V_max, 603758976, tol = 0.01)
	val = IndexToScale(data, DimSize(data, ROWS), ROWS)
	CHECK_CLOSE_VAR(val, 1000, tol = 0.001)
	str    = WaveUnits(data, -1)
	strRef = "^2"
	CHECK_EQUAL_STR(strRef, str)

	str = "powerspectrum(data(select(selrange(),selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "),selvis(all))),dB)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WaveStats/Q/M=1 data
	CHECK_CLOSE_VAR(V_maxLoc, 100, tol = 0.01)
	CHECK_CLOSE_VAR(V_max, 88, tol = 0.01)
	str    = WaveUnits(data, -1)
	strRef = "dB"
	CHECK_EQUAL_STR(strRef, str)

	str = "powerspectrum(data(select(selrange(),selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "),selvis(all))),normalized)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WaveStats/Q/M=1 data
	CHECK_CLOSE_VAR(V_maxLoc, 100, tol = 0.01)
	CHECK_CLOSE_VAR(V_max, 129, tol = 0.01)
	str    = WaveUnits(data, -1)
	strRef = "mean(^2)"
	CHECK_EQUAL_STR(strRef, str)

	str = "powerspectrum(data(select(selrange(),selchannels(AD),selsweeps(" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "),selvis(all))),dB,avg)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(2, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WaveStats/Q/M=1 data
	CHECK_CLOSE_VAR(V_maxLoc, 100, tol = 0.01)
	CHECK_CLOSE_VAR(V_max, 88, tol = 0.01)
	WAVE data = dataWref[1]
	WaveStats/Q/M=1 data
	CHECK_CLOSE_VAR(V_maxLoc, 100, tol = 0.01)
	CHECK_CLOSE_VAR(V_max, 88, tol = 0.01)

	str = "powerspectrum(data(select(selrange(),selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "),selvis(all))),dB,noavg,100)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WaveStats/Q/M=1 data
	CHECK_EQUAL_VAR(1, DimSize(data, ROWS))
	CHECK_CLOSE_VAR(data[0], 1.32, tol = 0.01)

	str = "powerspectrum(data(select(selrange(),selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "),selvis(all))),dB,noavg,0,2000)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	val = IndexToScale(data, DimSize(data, ROWS), ROWS)
	CHECK_CLOSE_VAR(val, 2000, tol = 0.001)

	str = "powerspectrum(data(select(selrange(),selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "),selvis(all))),dB,noavg,0,1000,HFT248D)"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE      data     = dataWref[0]
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(1, DimSize(dataWref, ROWS))
	WAVE data = dataWref[0]
	WaveStats/Q/M=1 data
	CHECK_CLOSE_VAR(V_maxLoc, 100, tol = 0.01)
	CHECK_CLOSE_VAR(V_max, 94, tol = 0.01)

	try
		str = "powerspectrum()"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(select(selrange(),selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "),selvis(all))), not_exist)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(select(selrange(),selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "),selvis(all))), dB, not_exist)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(select(selrange(),selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "),selvis(all))), dB, avg, -1)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(select(selrange(),selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "),selvis(all))), dB, avg, 0, -1)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(select(selrange(),selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "),selvis(all))), dB, avg, 0, 1000, not_exist)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		str = "powerspectrum(data(select(selrange(),selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "),selvis(all))), dB, avg, 0, 1000, Bartlet, not_exist)"
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestOperationLabNotebook()
	variable i, j, sweepNumber, channelNumber, numSweeps, numChannels
	string str, key

	string textKey   = LABNOTEBOOK_USER_PREFIX + "TEXTKEY"
	string textValue = "TestText"

	string win, device

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	[numSweeps, numChannels, WAVE/U/I channels] = FillFakeDatabrowserWindow(win, device, XOP_CHANNEL_TYPE_ADC, textKey, textValue)
	win = GetCurrentWindow()

	Make/FREE/N=(numSweeps * numChannels) channelsRef
	channelsRef[] = channels[trunc(p / numChannels)][mod(p, numChannels)]
	str           = "labnotebook(ADC)"
	TestOperationLabnotebookHelper(win, str, channelsRef)
	str = "labnotebook(ADC,select(selchannels(AD),selsweeps(0..." + num2istr(numSweeps) + ")))"
	TestOperationLabnotebookHelper(win, str, channelsRef)
	str = "labnotebook(" + LABNOTEBOOK_USER_PREFIX + "ADC, select(selchannels(AD),selsweeps(0..." + num2istr(numSweeps) + ")),UNKNOWN_MODE)"
	TestOperationLabnotebookHelper(win, str, channelsRef)

	str = "labnotebook(ADC, select(selchannels(AD12),selsweeps(-1)))"
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(DimSize(dataRef, ROWS), 0)

	str = "labnotebook(" + textKey + ")"
	WAVE/WAVE dataRef = SF_ExecuteFormula(str, win, useVariables = 0)
	Make/FREE/T textRefData = {textValue}
	for(WAVE/T dataT : dataRef)
		CHECK_EQUAL_WAVES(dataT, textRefData, mode = WAVE_DATA)
	endfor
End

static Function TestOperationLabnotebookHelper(string win, string formula, WAVE wRef)

	variable i

	WAVE/WAVE dataRef = SF_ExecuteFormula(formula, win, useVariables = 0)
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

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	textKey    = EPOCHS_ENTRY_KEY
	textValue  = "0.5000000,0.5100000,Epoch=0;Type=Pulse Train;Amplitude=1;Pulse=48;ShortName=E0_PT_P48;,2,:"
	textValue += "0.5030000,0.5100000,Epoch=0;Type=Pulse Train;Pulse=48;Baseline;ShortName=E0_PT_P48_B;,3,:"
	textValue += "0.6000000,0.7000000,NoShortName,3,:"
	epoch2     = "Epoch=0;Type=Pulse Train;Pulse=49;Baseline;"
	textValue += "0.5100000,0.5200000," + epoch2 + ",2,"

	[numSweeps, numChannels, WAVE/U/I channels] = FillFakeDatabrowserWindow(win, device, XOP_CHANNEL_TYPE_DAC, textKey, textValue)
	win = GetCurrentWindow()

	str = "epochs(\"E0_PT_P48\")"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
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

	str = "epochs(\"E0_PT_P48\", select(selchannels(DA0), selsweeps(0)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 1)
	Make/FREE/D refData = {500, 510}
	WAVE data = dataWref[0]
	REQUIRE_EQUAL_WAVES(data, refData, mode = WAVE_DATA)

	str = "epochs(\"E0_PT_P48_B\", select(selchannels(DA4), selsweeps(0)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 1)
	Make/FREE/D refData = {503, 510}
	WAVE data = dataWref[0]
	REQUIRE_EQUAL_WAVES(data, refData, mode = WAVE_DATA)

	str = "epochs(\"E0_PT_P48_B\", select(selchannels(DA4), selsweeps(0)), range)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE/D refData = {503, 510}
	REQUIRE_EQUAL_WAVES(data, refData, mode = WAVE_DATA)

	str = "epochs(\"E0_PT_P48_B\", select(selchannels(DA4), selsweeps(0)), treelevel)"
	WAVE data = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE/D refData = {3}
	REQUIRE_EQUAL_WAVES(data, refData, mode = WAVE_DATA)

	str = "epochs(\"E0_PT_P48_B\", select(selchannels(DA4), selsweeps(9)), name)"
	WAVE/T dataT = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE/T refDataT = {"E0_PT_P48_B"}
	REQUIRE_EQUAL_WAVES(dataT, refDataT, mode = WAVE_DATA)

	str = "epochs(\"NoShortName\", select(selchannels(DA4), selsweeps(9)), name)"
	WAVE/T dataT = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE/T refDataT = {"NoShortName"}
	REQUIRE_EQUAL_WAVES(dataT, refDataT, mode = WAVE_DATA)

	// works case-insensitive
	str = "epochs(\"e0_pt_p48_B\", select(selchannels(DA4), selsweeps(9)), name)"
	WAVE/T dataT = SF_ExecuteFormula(str, win, singleResult = 1, useVariables = 0)
	Make/FREE/T refDataT = {"E0_PT_P48_B"}
	REQUIRE_EQUAL_WAVES(dataT, refDataT, mode = WAVE_DATA)

	str = "epochs(\"E0_PT_P48_B\", select(selchannels(DA), selsweeps(0..." + num2istr(numSweeps) + ")))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), numSweeps * activeChannelsDA)
	Make/FREE/D refData = {503, 510}
	for(data : dataWref)
		REQUIRE_EQUAL_WAVES(data, refData, mode = WAVE_DATA)
	endfor
	// check Meta data
	Make/FREE/D/N=(numSweeps * activeChannelsDA) channelTypes, channelNumbers, sweepNumbers
	channelTypes   = XOP_CHANNEL_TYPE_DAC
	channelNumbers = mod(p, activeChannelsDA) * 2
	sweepNumbers   = trunc(p / activeChannelsDA)
	CheckSweepsMetaData(dataWref, channelTypes, channelNumbers, sweepNumbers, SF_DATATYPE_EPOCHS)

	str = "epochs(\"E0_PT_P48_*\", select(selchannels(DA), selsweeps(0)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), activeChannelsDA)
	Make/FREE/D refData = {503, 510}
	for(data : dataWref)
		CHECK_EQUAL_WAVES(data, refData, mode = WAVE_DATA)
	endfor

	// find epoch without shortname
	epochLongName = RemoveEnding(epoch2, ";")
	str           = "epochs(\"" + epochLongName + "\", select(selchannels(DA), selsweeps(0)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), activeChannelsDA)

	// finds only epoch without shortname from test epochs
	str = "epochs(\"!E0_PT_P48*\", select(selchannels(DA), selsweeps(0)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), activeChannelsDA)
	CHECK_EQUAL_VAR(DimSize(dataWref, COLS), 0)

	for(WAVE/Z data : dataWref)
		CHECK_WAVE(data, NUMERIC_WAVE)
		CHECK_EQUAL_VAR(DimSize(data, ROWS), 2)
		CHECK_EQUAL_VAR(DimSize(data, COLS), 2)
	endfor

	// the first wildcard matches both setup epochs, the second only the first setup epoch
	// only unique epochs are returned, thus two
	str = "epochs([\"E0_PT_*\",\"E0_PT_P48*\"], select(selchannels(DA), selsweeps(0)))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 4)
	Make/FREE/D refData = {{500, 510}, {503, 510}}
	for(WAVE/Z data : dataWref)
		CHECK_WAVE(data, NUMERIC_WAVE)
		CHECK_EQUAL_WAVES(data, refData, mode = WAVE_DATA)
	endfor

	// channel(s) with no epochs
	str = "epochs(\"E0_PT_P48_B\", select(selchannels(AD), selsweeps(0..." + num2istr(numSweeps) + ")))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// channels with epochs, but name that does not match any epoch
	str = "epochs(\"does_not_exist\", select(selchannels(DA), selsweeps(0..." + num2istr(numSweeps) + ")))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// invalid sweep
	str = "epochs(\"E0_PT_P48_B\", select(selchannels(DA), selsweeps(" + num2istr(numSweeps) + ")))"
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), 0)

	// invalid type
	str = "epochs(\"E0_PT_P48_B\", select(selchannels(DA), selsweeps(0..." + num2istr(numSweeps) + ")), invalid_type)"
	try
		WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry
End

static Function TestOperationDataset()

	string win, device, code

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	code = "dataset()"
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 0)

	code = "dataset(1)"
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1)
	CHECK_EQUAL_WAVES(output[0], {1}, mode = WAVE_DATA)

	code = "dataset(1, [2, 3], \"abcd\")"
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 3)
	CHECK_EQUAL_WAVES(output[0], {1}, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(output[1], {2, 3}, mode = WAVE_DATA)
	CHECK_EQUAL_TEXTWAVES(output[2], {"abcd"}, mode = WAVE_DATA)
End

static Function TestOperationFit()

	string win, device, code

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	// straight line with slope 1 and offset 0
	code = "fit([1, 3], [1, 3], fitline())"
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables = 0)
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
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1)
	WAVE wv = output[0]

	variable/G K0 = 3

	Make/FREE/D xData = {0, 1, 2}
	Make/FREE/D yData = {4, 5, 6}
	CurveFit/Q/H="10" line, yData/X=xData/D

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
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables = 0)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 1)
	CHECK(!WaveExists(output[0]))

	// unknown fit function
	code = "fit([1, 2], [3, 4], dataset(3))"
	try
		WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// mismatched dataset sizes
	code = "fit(dataset([1]), dataset([1], [2]), fitline())"
	try
		WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

static Function TestOperationSelectCompareWithFullRange(string win, string formula, WAVE/Z dataRef)

	WAVE/WAVE comp = SF_ExecuteFormula(formula, win, useVariables = 0)
	CHECK_WAVE(comp, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(comp, ROWS), 2)
	WAVE/Z    dataSel = comp[0]
	WAVE/WAVE rngSet  = comp[1]
	CHECK_WAVE(rngSet, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(rngSet, ROWS), 1)
	WAVE dataRng = rngSet[0]
	WAVE rngRef  = SFH_GetFullRange()
	if(WaveExists(dataRef) || WaveExists(dataSel))
		CHECK_EQUAL_WAVES(dataRef, dataSel, mode = WAVE_DATA | DIMENSION_SIZES)
	endif
	CHECK_EQUAL_WAVES(rngRef, dataRng, mode = WAVE_DATA | DIMENSION_SIZES)
End

// UTF_TD_GENERATOR DataGenerators#SF_TestOperationSelectFails
static Function TestOperationSelectFails([string str])

	string win, device

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()
	win = CreateFakeSweepData(win, device, sweepNo = 0)

	try
		WAVE/WAVE comp = SF_ExecuteFormula(str, win, useVariables = 0)
		FAIL()
	catch
		PASS()
	endtry

End

static Function TestOperationSelect()

	variable numChannels, sweepNo
	string str, chanList, wvList

	variable numSweeps = 2
	variable dataSize  = 10
	variable i, j, clampMode
	string trace, name
	string channelTypeList   = "DA;AD;DA;AD;"
	string channelNumberList = "2;6;3;7;"

	string win, device

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	sweepNo = 0

	win = CreateFakeSweepData(win, device, sweepNo = sweepNo)

	numChannels = 4 // from LBN creation in CreateFakeSweepData->PrepareLBN_IGNORE -> DA2, AD6, DA3, AD7
	Make/FREE/N=0 sweepTemplate
	WAVE sweepRef = FakeSweepDataGeneratorDefault(sweepTemplate, numChannels)

	Make/FREE/N=(4, 4) dataRef
	dataRef[][0]     = sweepNo
	dataRef[0, 1][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[2, 3][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[][2]     = {6, 7, 2, 3}                           // AD6, AD7, DA2, DA3
	dataRef[][3]     = NaN
	str              = "select(selvis(all))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	win = CreateFakeSweepData(win, device, sweepNo = sweepNo + 1)
	win = CreateFakeSweepData(win, device, sweepNo = sweepNo + 2)
	win = CreateFakeSweepData(win, device, sweepNo = sweepNo + 3)

	Make/FREE/N=(2, 4) dataRef
	dataRef[][0]  = sweepNo
	dataRef[0][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[1][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[][2]  = {6, 2}                                                                       // AD6, DA2
	dataRef[][3]  = NaN
	str           = "select(selchannels(2, 6),selsweeps(" + num2istr(sweepNo) + "),selvis(all))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	Make/FREE/N=(2, 4) dataRef
	dataRef[][0] = sweepNo
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7}                                                                     // AD6, AD7
	dataRef[][3] = NaN
	str          = "select(selchannels(AD),selsweeps(" + num2istr(sweepNo) + "),selvis(all))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	// non-existing sweeps are ignored
	str = "select(selchannels(AD),selsweeps(" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1337) + "),selvis(all))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	Make/FREE/N=(1, 4) dataRef
	dataRef[][0] = 3
	dataRef[][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[][2] = {0}                                                                   // DA0 (unassoc)
	dataRef[][3] = NaN
	str          = "select(selchannels(DA0),selsweeps(" + num2istr(3) + "),selvis(all))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	Make/FREE/N=(1, 4) dataRef
	dataRef[][0] = 3
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {1}                                                                   // AD1 (unassoc)
	dataRef[][3] = NaN
	str          = "select(selchannels(AD1),selsweeps(" + num2istr(3) + "),selvis(all))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	Make/FREE/N=(1, 4) dataRef
	dataRef[][0] = 3
	dataRef[][1] = WhichListItem("TTL", XOP_CHANNEL_NAMES)
	dataRef[][2] = {2}                                                                    // TTL2
	dataRef[][3] = NaN
	str          = "select(selchannels(TTL2),selsweeps(" + num2istr(3) + "),selvis(all))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	// clamp mode set filters has no effect on TTL
	str = "select(selchannels(TTL2),selsweeps(" + num2istr(3) + "),selvis(all),selcm(vc))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	// clamp mode set filters on DA/AD
	str = "select(selchannels(AD1),selsweeps(" + num2istr(3) + "),selvis(all),selcm(vc))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)
	str = "select(selchannels(DA0),selsweeps(" + num2istr(3) + "),selvis(all),selcm(vc))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)

	Make/FREE/N=(4, 4) dataRef
	dataRef[][0] = {sweepNo, sweepNo, sweepNo + 1, sweepNo + 1}                                                             // sweep 0, 1 with 2 AD channels each
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7, 6, 7}                                                                                             // AD6, AD7, AD6, AD7
	dataRef[][3] = NaN
	str          = "select(selchannels(AD),selsweeps(" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "),selvis(all))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	Make/FREE/N=(2, 4) dataRef
	dataRef[][0] = {sweepNo, sweepNo + 1}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 6}                                                                                                    // AD6, AD6
	dataRef[][3] = NaN
	str          = "select(selchannels(AD6),selsweeps(" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "),selvis(all))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	Make/FREE/N=(6, 4) dataRef
	dataRef[][0] = {sweepNo, sweepNo, sweepNo, sweepNo + 1, sweepNo + 1, sweepNo + 1}
	chanList     = "AD;DA;DA;AD;DA;DA;"
	dataRef[][1] = WhichListItem(StringFromList(p, chanList), XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 2, 3, 6, 2, 3}                                                                                            // AD6, DA2, DA3, AD6, DA2, DA3
	dataRef[][3] = NaN
	str          = "select(selchannels(AD6, DA),selsweeps(" + num2istr(sweepNo) + "," + num2istr(sweepNo + 1) + "),selvis(all))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	// No existing sweeps
	str = "select(selchannels(AD6, DA),selsweeps(" + num2istr(sweepNo + 1337) + "),selvis(all))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)

	// No existing channels
	str = "select(selchannels(AD0),selsweeps(" + num2istr(sweepNo) + "),selvis(all))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)

	str = "select(selvis(all),selrange([1,2]))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/WAVE rngSet  = comp[1]
	WAVE      dataRng = rngSet[0]
	CHECK_EQUAL_WAVES(dataRng, {1, 2}, mode = WAVE_DATA | DIMENSION_SIZES)

	str = "select(selvis(all),select(selrange([1,2])))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/WAVE rngSet  = comp[1]
	WAVE      dataRng = rngSet[0]
	CHECK_EQUAL_WAVES(dataRng, {-Inf, Inf}, mode = WAVE_DATA | DIMENSION_SIZES)

	// Setup graph with equivalent data for displayed parameter
	TUD_Clear(win)

	Make/FREE/N=(dataSize, numSweeps, numChannels) input = q + p^r // + gnoise(1)
	for(i = 0; i < numSweeps; i += 1)
		sweepNo = i
		for(j = 0; j < numChannels; j += 1)
			name      = UniqueName("data", 1, 0)
			trace     = "trace_" + name
			clampMode = mod(sweepNo, 2) ? V_CLAMP_MODE : I_CLAMP_MODE
			Extract input, $name, q == i && r == j
			WAVE wv = $name
			AppendToGraph/W=$win wv/TN=$trace
			WAVE numericalValues = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweepNo)
			WAVE textualValues   = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = sweepNo)
			TUD_SetUserDataFromWaves(win, trace, {"experiment", "textualValues", "numericalValues", "fullPath", "traceType", "occurence", "channelType", "channelNumber", "sweepNumber", "clampMode", "GUIChannelNumber", "SweepMapIndex"},                                                                                        \
			                         {"blah", GetWavesDataFolder(textualValues, 2), GetWavesDataFolder(numericalValues, 2), GetWavesDataFolder(wv, 2), "Sweep", "0", StringFromList(j, channelTypeList), StringFromList(j, channelNumberList), num2istr(sweepNo), num2istr(clampMode), StringFromList(j, channelNumberList), "NaN"})
		endfor
	endfor

	sweepNo = 0
	Make/FREE/N=(8, 4) dataRef
	dataRef[0, 3][0] = sweepNo
	dataRef[4, 7][0] = sweepNo + 1
	dataRef[0, 1][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[2, 3][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[4, 5][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[6, 7][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[][2]     = {6, 7, 2, 3, 6, 7, 2, 3}
	dataRef[][3]     = NaN
	str              = "select()"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(select())"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	Make/FREE/N=(4, 4) dataRef
	dataRef[][0] = {sweepNo, sweepNo, sweepNo + 1, sweepNo + 1}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7, 6, 7}
	dataRef[][3] = NaN
	str          = "select(selchannels(AD),selsweeps(),selvis(displayed))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(selchannels(AD),selsweeps())"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	Make/FREE/N=(2, 4) dataRef
	dataRef[][0] = {sweepNo, sweepNo + 1}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 6}
	dataRef[][3] = NaN
	str          = "select(selchannels(AD6),selsweeps(),selvis(displayed),selcm(all))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(select(selchannels(AD6)),selchannels(AD))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(select(selchannels(AD6)),selchannels(6))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(select(selchannels(AD6)),selchannels(5))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)
	str = "select(select(selchannels(AD6)),selchannels(DA))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)
	str = "select(select(selchannels(AD6),selsweeps()),selsweeps(0,1))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(select(selchannels(AD6),selsweeps()),selsweeps(2))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)
	str = "select(select(selchannels(AD6)),selvis(displayed))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(select(selchannels(AD6)),selvis(all))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	Make/FREE/N=(1, 4) dataRef
	dataRef[][0] = {sweepNo}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6}
	dataRef[][3] = NaN
	str          = "select(select(selchannels(AD6),selcm(all)),selcm(ic))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	dataRef[][0] = {sweepNo + 1}
	str          = "select(select(selchannels(AD6),selcm(all)),selcm(vc))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	dataRef[][0] = {sweepNo}
	str          = "select(select(selchannels(AD)),selstimset(stimsetSweep0HS0),selsweeps(0))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(select(selchannels(AD),selstimset(\"stimset*\")),selstimset(stimsetSweep0HS0),selsweeps(0))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(select(selchannels(AD),selstimset(\"stimsetSweep1*\")),selstimset(\"stimsetSweep0*\"),selsweeps(0))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)

	Make/FREE/N=(2, 4) dataRef
	dataRef[][0] = {sweepNo, sweepNo + 1}                           // both sweeps have the same SCI
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 6}
	dataRef[][3] = NaN
	str          = "select(selchannels(AD6),selivsccsetqc(passed))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(select(selchannels(AD6)),selivsccsetqc(passed))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(selchannels(AD6),selsweeps(0),selivsccsetqc(failed))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)
	str = "select(select(selchannels(AD6),selivsccsetqc(passed)),selivsccsetqc(failed))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)

	Make/FREE/N=(1, 4) dataRef
	dataRef[][0] = {sweepNo + 1}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6}
	dataRef[][3] = NaN
	str          = "select(selchannels(AD6),selivsccsweepqc(passed))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(select(selchannels(AD6)),selivsccsweepqc(passed))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(selchannels(AD6),selsweeps(1),selivsccsweepqc(failed))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)
	str = "select(select(selchannels(AD6),selivsccsweepqc(passed)),selivsccsweepqc(failed))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)

	Make/FREE/N=(2, 4) dataRef
	dataRef[][0] = {sweepNo, sweepNo + 1}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 6}
	dataRef[][3] = NaN
	str          = "select(selchannels(AD6),selexp(" + GetExperimentName() + "))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(selchannels(AD6),seldev(ITC16_Dev_0))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	Make/FREE/N=(2, 4) dataRef
	dataRef[][0]  = {sweepNo}
	dataRef[0][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[1][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[][2]  = {6, 2}
	dataRef[][3]  = NaN
	str           = "select(selsetcyclecount(711))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(selsetsweepcount(635))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	// sweep 0 and sweep 1 are set to the same SCI and the same RAC
	Make/FREE/N=(2, 4) dataRef
	dataRef[][0] = {sweepNo, sweepNo + 1}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 6}
	dataRef[][3] = NaN
	str          = "select(selsweeps(0), selchannels(AD6), selexpandrac())"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(selsweeps(0), selchannels(AD6), selexpandsci())"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	// sweepNr ChannelNumber RAC
	// 0 6 49
	// 0 7 49
	// 1 6 49
	// 1 7 49
	// 2 6 50
	// 2 7 50

	Make/FREE/N=(4, 4) dataRef
	dataRef[][0] = {sweepNo, sweepNo, sweepNo + 1, sweepNo + 1}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7, 6, 7}
	dataRef[][3] = NaN
	str          = "select(selsweeps([0, 1, 2]), selvis(all), selchannels(AD), selracindex(0))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	Make/FREE/N=(2, 4) dataRef
	dataRef[][0] = {sweepNo + 2, sweepNo + 2}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7}
	dataRef[][3] = NaN
	str          = "select(selsweeps([0, 1, 2]), selvis(all), selchannels(AD), selracindex(1))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	str = "select(selsweeps([0, 1, 2]), selvis(all), selchannels(AD), selracindex(999))"
	TestOperationSelectCompareWithFullRange(win, str, $"")

	str = "select(selsweeps(3), selvis(all), selchannels(AD), selracindex(0))"
	TestOperationSelectCompareWithFullRange(win, str, $"")

	// sweepNr ChannelNumber Headstage SCI
	// 0 6 0 43
	// 0 7 1 45
	// 1 6 0 43
	// 1 7 1 46 <- index 1 for HS1
	// 2 6 0 44 <- index 1 for HS0
	// 2 7 1 46 <- index 1 for HS1 (same SCI 46)

	Make/FREE/N=(3, 4) dataRef
	dataRef[][0] = {sweepNo + 2, sweepNo + 1, sweepNo + 2}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7, 7}
	dataRef[][3] = NaN
	str          = "select(selsweeps([0, 1, 2]), selvis(all), selchannels(AD), selsciindex(1))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	Make/FREE/N=(3, 4) dataRef
	dataRef[][0] = {sweepNo, sweepNo + 1, sweepNo}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 6, 7}
	dataRef[][3] = NaN
	str          = "select(selsweeps([0, 1, 2]), selvis(all), selchannels(AD), selsciindex(0))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	str = "select(selsweeps([0, 1, 2]), selvis(all), selchannels(AD), selsciindex(999))"
	TestOperationSelectCompareWithFullRange(win, str, $"")

	str = "select(selsweeps([0, 1, 2]), selvis(all), selchannels(AD), selsciindex(0),select(selsweeps([0, 1, 2]), selvis(all), selchannels(AD), selsciindex(999)))"
	TestOperationSelectCompareWithFullRange(win, str, $"")

	str = "select(selsweeps(3), selvis(all), selchannels(AD), selsciindex(0))"
	TestOperationSelectCompareWithFullRange(win, str, $"")

	Make/FREE/N=(1, 4) dataRef
	dataRef[][0] = {sweepNo}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6}
	dataRef[][3] = NaN
	str          = "select(selchannels(AD6),selsweeps(),selvis(displayed), selcm(ic))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	Make/FREE/N=(1, 4) dataRef
	dataRef[][0] = {sweepNo + 1}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {6}
	dataRef[][3] = NaN
	str          = "select(selchannels(AD6),selsweeps(),selvis(displayed), selcm(vc))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	str = "select(selchannels(AD6),selsweeps(),selvis(displayed), selcm(izero))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)

	dataRef[][0] = {sweepNo, sweepNo, sweepNo + 1, sweepNo + 1}
	dataRef[][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[][2] = {2, 3, 2, 3}
	dataRef[][3] = NaN
	str          = "select(selchannels(DA),selsweeps())"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	Make/FREE/N=(6, 4) dataRef
	dataRef[][0] = {sweepNo, sweepNo, sweepNo, sweepNo + 1, sweepNo + 1, sweepNo + 1}
	chanList     = "AD;AD;DA;AD;AD;DA;"
	dataRef[][1] = WhichListItem(StringFromList(p, chanList), XOP_CHANNEL_NAMES)
	dataRef[][2] = {6, 7, 2, 6, 7, 2}
	dataRef[][3] = NaN
	str          = "select(selchannels(DA2, AD),selsweeps())"                         // note: channels are sorted AD, DA...
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	// No existing sweeps
	str = "select(selchannels(AD6, DA),selsweeps(" + num2istr(sweepNo + 1337) + "))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)

	// No existing channels
	str = "select(selchannels(AD0),selsweeps(" + num2istr(sweepNo) + "))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)

	// Setup graph for unassoc DA/AD and TTL
	numSweeps         = 1
	channelTypeList   = "DA;AD;TTL;"
	channelNumberList = "0;1;2;"

	RemoveTracesFromGraph(win)
	TUD_Clear(win)

	Make/FREE/N=(dataSize, numSweeps, numChannels) input = q + p^r // + gnoise(1)
	for(i = 0; i < numSweeps; i += 1)
		sweepNo = i
		for(j = 0; j < numChannels; j += 1)
			name      = UniqueName("data", 1, 0)
			trace     = "trace_" + name
			clampMode = NaN
			Extract input, $name, q == i && r == j
			WAVE wv = $name
			AppendToGraph/W=$win wv/TN=$trace
			WAVE numericalValues = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_NUMERICAL_VALUES, sweepNumber = sweepNo)
			WAVE textualValues   = BSP_GetLogbookWave(win, LBT_LABNOTEBOOK, LBN_TEXTUAL_VALUES, sweepNumber = sweepNo)
			TUD_SetUserDataFromWaves(win, trace, {"experiment", "textualValues", "numericalValues", "fullPath", "traceType", "occurence", "channelType", "channelNumber", "sweepNumber", "clampMode", "GUIChannelNumber", "AssociatedHeadstage", "SweepMapIndex"},                                                                              \
			                         {"blah", GetWavesDataFolder(textualValues, 2), GetWavesDataFolder(numericalValues, 2), GetWavesDataFolder(wv, 2), "Sweep", "0", StringFromList(j, channelTypeList), StringFromList(j, channelNumberList), num2istr(sweepNo), num2istr(clampMode), StringFromList(j, channelNumberList), num2istr(0), "NaN"})
		endfor
	endfor

	Make/FREE/N=(1, 4) dataRef
	dataRef[][0] = {0}
	dataRef[][1] = WhichListItem("DA", XOP_CHANNEL_NAMES)
	dataRef[][2] = {0}
	dataRef[][3] = NaN
	str          = "select(selchannels(DA0),selsweeps(),selvis(displayed))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(selchannels(DA0),selsweeps(),selvis(displayed),selcm(none))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(selchannels(DA0),selsweeps(),selvis(displayed),selcm(vc))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)

	Make/FREE/N=(1, 4) dataRef
	dataRef[][0] = {0}
	dataRef[][1] = WhichListItem("AD", XOP_CHANNEL_NAMES)
	dataRef[][2] = {1}
	dataRef[][3] = NaN
	str          = "select(selchannels(AD1),selsweeps(),selvis(displayed))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(selchannels(AD1),selsweeps(),selvis(displayed),selcm(none))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	str = "select(selchannels(AD1),selsweeps(),selvis(displayed),selcm(vc))"
	WAVE/WAVE comp    = SF_ExecuteFormula(str, win, useVariables = 0)
	WAVE/Z    dataSel = comp[0]
	CHECK_WAVE(dataSel, NULL_WAVE)

	Make/FREE/N=(1, 4) dataRef
	dataRef[][0] = {0}
	dataRef[][1] = WhichListItem("TTL", XOP_CHANNEL_NAMES)
	dataRef[][2] = {2}
	dataRef[][3] = NaN
	str          = "select(selchannels(TTL2),selsweeps(),selvis(displayed))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)
	// clamp mode set filters has no effect on TTL
	str = "select(selchannels(TTL2),selsweeps(),selvis(displayed),selcm(vc))"
	TestOperationSelectCompareWithFullRange(win, str, dataRef)

	// workaround permanent waves being present
	wvList = GetListOfObjects(GetDataFolderDFR(), "data*")
	CallFunctionForEachListItem_TS(KillOrMoveToTrashPath, wvList)
End

static Function TestOperationMerge()

	string win, device, code

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	// no input
	code = "merge()"
	try
		WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// too many points (2) in the input datasets
	code = "merge(dataset([1, 2]))"
	try
		WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	// mixed input wave types
	code = "merge(dataset([1], [\"a\"]))"
	try
		WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	code = "merge(dataset([1], [2]))"
	WAVE wv = SF_ExecuteFormula(code, win, useVariables = 0, singleResult = 1)
	CHECK_WAVE(wv, FREE_WAVE, minorType = DOUBLE_WAVE)
	Make/FREE/D refWv = {1, 2}
	CHECK_EQUAL_WAVES(wv, refWv)

	code = "merge(dataset([\"a\"], [\"b\"]))"
	WAVE wv = SF_ExecuteFormula(code, win, useVariables = 0, singleResult = 1)
	CHECK_WAVE(wv, TEXT_WAVE)
	Make/FREE/T refWvTxt = {"a", "b"}
	CHECK_EQUAL_WAVES(wv, refWvTxt)

	code = "merge(dataset())"
	WAVE/WAVE/Z output = SF_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 0)

	code = "merge(dataset(wave(I_DONT_EXIST)))"
	WAVE/WAVE/Z output = SF_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 0)
End

static Function TestOperationFitLine()

	string win, device, code

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	win = CreateFakeSweepData(win, device, sweepNo = 0)

	code = "fitline()"
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 3)
	WAVE/T fitType = output[%fitType]
	CHECK_EQUAL_STR(fitType[0], "line")
	WAVE holdWave = output[%holdWave]
	CHECK_EQUAL_WAVES(holdWave, {0, 0}, mode = WAVE_DATA)
	WAVE initialValues = output[%initialValues]
	CHECK_EQUAL_WAVES(initialValues, {NaN, NaN}, mode = WAVE_DATA)

	code = "fitline([\"K0=17\"])"
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables = 0)
	CHECK_WAVE(output, WAVE_WAVE)
	CHECK_EQUAL_VAR(DimSize(output, ROWS), 3)
	WAVE/T fitType = output[%fitType]
	CHECK_EQUAL_STR(fitType[0], "line")
	WAVE holdWave = output[%holdWave]
	CHECK_EQUAL_WAVES(holdWave, {1, 0}, mode = WAVE_DATA)
	WAVE initialValues = output[%initialValues]
	CHECK_EQUAL_WAVES(initialValues, {17, NaN}, mode = WAVE_DATA)

	code = "fitline([\"K0=1\", \"K1=3\"])"
	WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables = 0)
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
		WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry
End

// Complex Tests

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

// IUTF_TD_GENERATOR DataGenerators#GetBasicMathOperations
static Function BasicMathMismatchedWaves([string str])

	string code, win, opShort, error

	win = GetDataBrowserWithData()

	sprintf code, "[1, 2] %s [[1, 2]]", str
	try
		WAVE/WAVE output = SF_ExecuteFormula(code, win, useVariables = 0)
		FAIL()
	catch
		CHECK_NO_RTE()
	endtry

	strswitch(str)
		case "*":
			opShort = "mult"
			break
		case "/":
			opShort = "div"
			break
		case "+":
			opShort = "plus"
			break
		case "-":
			opShort = "minus"
			break
		default:
			FAIL()
	endswitch

	error = ROStr(GetSweepFormulaParseErrorMessage())
	CHECK_EQUAL_STR(error, opShort + ": wave size mismatch [2, 0, 0, 0] vs [1, 2, 0, 0]")
End

static Function DefaultFormulaWorks()

	variable sweepNo, numChannels
	string str
	string win, device

	[win, device] = CreateEmptyUnlockedDataBrowserWindow()

	sweepNo = 0
	win     = CreateFakeSweepData(win, device, sweepNo = sweepNo)

	numChannels = 4 // from LBN creation in CreateFakeSweepData->PrepareLBN_IGNORE -> DA2, AD6, DA3, AD7
	Make/FREE/N=0 sweepTemplate
	WAVE sweepRef = FakeSweepDataGeneratorDefault(sweepTemplate, numChannels)

	str = SF_GetDefaultFormula()
	WAVE/WAVE dataWref = SF_ExecuteFormula(str, win, useVariables = 1)
	CHECK_WAVE(dataWref, WAVE_WAVE)
	// If the default formula changes the following checks need to be adapted
	CHECK_EQUAL_VAR(DimSize(dataWref, ROWS), numChannels / 2)
	WAVE chan1 = dataWref[0]
	WAVE chan3 = dataWref[1]
	Duplicate/FREE/RMD=[][1] sweepRef, chan1Ref
	Redimension/N=(-1) chan1Ref
	Duplicate/FREE/RMD=[][3] sweepRef, chan3Ref
	Redimension/N=(-1) chan3Ref
	CHECK_EQUAL_WAVES(chan1, chan1Ref, mode = WAVE_DATA)
	CHECK_EQUAL_WAVES(chan3, chan3Ref, mode = WAVE_DATA)
End
