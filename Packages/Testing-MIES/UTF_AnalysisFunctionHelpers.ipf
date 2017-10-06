﻿#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=UTF_AnalyisFunctionHelpers

static StrConstant device = "ITC18USB_Dev_0"

static Function TEST_CASE_BEGIN_OVERRIDE(testCase)
	string testCase

	KillDataFolder/Z root:MIES

	if(DataFolderExists("root:MIES"))
		Abort "Cleanup did not work"
	endif

	// fake one existing sweep
	DFREF dfr = GetDeviceDataPath(device)
	Make/N=(2, 2) dfr:Sweep_0
	Make/N=(2, 2) dfr:Config_0
End

/// BEGIN ED_AddEntryToLabnotebook
/// @{

Function AE_ThrowsWithWrongWaveType()

	try
		Make/I/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values
		ED_AddEntryToLabnotebook(device, "a", values)
		FAIL()
	catch
		PASS()
	endtry
End

Function AE_ThrowsWithEmptyKey()

	try
		Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values
		ED_AddEntryToLabnotebook(device, "", values)
		FAIL()
	catch
		PASS()
	endtry
End

Function AE_ThrowsWithInvalidNumRows1()

	try
		Make/D/FREE/N=(1) values
		ED_AddEntryToLabnotebook(device, "a", values)
		FAIL()
	catch
		PASS()
	endtry
End

Function AE_ThrowsWithInvalidNumRows2()

	try
		Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT, 1) values
		ED_AddEntryToLabnotebook(device, "a", values)
		FAIL()
	catch
		PASS()
	endtry
End

Function AE_ThrowsWithTooLongKey()

	try
		Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT, 1) values
		ED_AddEntryToLabnotebook(device, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" , values)
		FAIL()
	catch
		PASS()
	endtry
End

Function AE_Works1()

	variable row, col
	string unit, unitRef, tolerance, toleranceRef
	string key = "someKey"

	unitRef   = ""
	toleranceRef = LABNOTEBOOK_NO_TOLERANCE

	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
	values[0] = 4711
	ED_AddEntryToLabnotebook(device, key , values)

	WAVE/T numericalKeys   = root:MIES:LabNoteBook:ITC18USB:Device0:numericalKeys
	WAVE   numericalValues = root:MIES:LabNoteBook:ITC18USB:Device0:numericalValues

	// key is added with prefix, so there is no full match
	FindValue/TXOP=4/TEXT=key numericalKeys
	CHECK_EQUAL_VAR(V_Value, -1)

	FindValue/TEXT=key numericalKeys
	col = floor(V_Value / DimSize(numericalKeys, ROWS))
	row = V_Value - col * DimSize(numericalKeys, ROWS)
	CHECK_EQUAL_VAR(row, 0)
	CHECK_EQUAL_VAR(col, 4)

	unit = numericalKeys[1][col]
	CHECK_EQUAL_STR(unit, unitRef)

	tolerance = numericalKeys[2][col]
	CHECK_EQUAL_STR(tolerance, toleranceRef)

	// entry can be found
	CHECK_EQUAL_VAR(numericalValues[0][col][0], 4711)
	WaveStats/Q/RMD=[0][col] numericalValues
	CHECK_EQUAL_VAR(V_numNaNs, 8)

	// inserted under correct sweep number
	CHECK_EQUAL_VAR(numericalValues[0][0][0], 0)
End

Function AE_Works2()

	variable row, col
	string unit, unitRef, tolerance, toleranceRef
	string key = "someKey"

	unitRef   = "hi there"
	toleranceRef = "123"

	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
	values[0] = 4711
	ED_AddEntryToLabnotebook(device, key , values, unit = unitRef, tolerance = str2num(toleranceRef))

	WAVE/T numericalKeys   = root:MIES:LabNoteBook:ITC18USB:Device0:numericalKeys
	WAVE   numericalValues = root:MIES:LabNoteBook:ITC18USB:Device0:numericalValues

	// key is added with prefix, so there is no full match
	FindValue/TXOP=4/TEXT=key numericalKeys
	CHECK_EQUAL_VAR(V_Value, -1)

	FindValue/TEXT=key numericalKeys
	col = floor(V_Value / DimSize(numericalKeys, ROWS))
	row = V_Value - col * DimSize(numericalKeys, ROWS)
	CHECK_EQUAL_VAR(row, 0)
	CHECK_EQUAL_VAR(col, 4)

	unit = numericalKeys[1][col]
	CHECK_EQUAL_STR(unit, unitRef)

	tolerance = numericalKeys[2][col]
	CHECK_EQUAL_STR(tolerance, toleranceRef)

	// entry can be found
	CHECK_EQUAL_VAR(numericalValues[0][col][0], 4711)
	WaveStats/Q/RMD=[0][col] numericalValues
	CHECK_EQUAL_VAR(V_numNaNs, 8)

	// inserted under correct sweep number
	CHECK_EQUAL_VAR(numericalValues[0][0][0], 0)
End

Function AE_Works3()

	variable row, col
	string unit, unitRef, tolerance, toleranceRef
	string key = "someKey"

	unitRef = ""
	toleranceRef = LABNOTEBOOK_NO_TOLERANCE

	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
	values[0] = 4711
	// internally NaN is translated to -
	ED_AddEntryToLabnotebook(device, key, values, tolerance = NaN)

	WAVE/T numericalKeys   = root:MIES:LabNoteBook:ITC18USB:Device0:numericalKeys
	WAVE   numericalValues = root:MIES:LabNoteBook:ITC18USB:Device0:numericalValues

	// key is added with prefix, so there is no full match
	FindValue/TXOP=4/TEXT=key numericalKeys
	CHECK_EQUAL_VAR(V_Value, -1)

	FindValue/TEXT=key numericalKeys
	col = floor(V_Value / DimSize(numericalKeys, ROWS))
	row = V_Value - col * DimSize(numericalKeys, ROWS)
	CHECK_EQUAL_VAR(row, 0)
	CHECK_EQUAL_VAR(col, 4)

	unit = numericalKeys[1][col]
	CHECK_EQUAL_STR(unit, unitRef)

	tolerance = numericalKeys[2][col]
	CHECK_EQUAL_STR(tolerance, toleranceRef)

	// entry can be found
	CHECK_EQUAL_VAR(numericalValues[0][col][0], 4711)
	WaveStats/Q/RMD=[0][col] numericalValues
	CHECK_EQUAL_VAR(V_numNaNs, 8)

	// inserted under correct sweep number
	CHECK_EQUAL_VAR(numericalValues[0][0][0], 0)
End

Function AE_Works4()

	variable row, col
	string unit, unitRef, tolerance, toleranceRef
	string key = "someKey"

	unitRef = ""
	toleranceRef = LABNOTEBOOK_NO_TOLERANCE

	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
	values[0] = 4711
	ED_AddEntryToLabnotebook(device, key, values)

	WAVE/T numericalKeys   = root:MIES:LabNoteBook:ITC18USB:Device0:numericalKeys
	WAVE   numericalValues = root:MIES:LabNoteBook:ITC18USB:Device0:numericalValues

	// key is added with prefix, so there is no full match
	FindValue/TXOP=4/TEXT=key numericalKeys
	CHECK_EQUAL_VAR(V_Value, -1)

	FindValue/TEXT=key numericalKeys
	col = floor(V_Value / DimSize(numericalKeys, ROWS))
	row = V_Value - col * DimSize(numericalKeys, ROWS)
	CHECK_EQUAL_VAR(row, 0)
	CHECK_EQUAL_VAR(col, 4)

	unit = numericalKeys[1][col]
	CHECK_EQUAL_STR(unit, unitRef)

	tolerance = numericalKeys[2][col]
	CHECK_EQUAL_STR(tolerance, toleranceRef)

	// entry can be found
	CHECK_EQUAL_VAR(numericalValues[0][col][0], 4711)
	WaveStats/Q/RMD=[0][col] numericalValues
	CHECK_EQUAL_VAR(V_numNaNs, 8)

	// inserted under correct sweep number
	CHECK_EQUAL_VAR(numericalValues[0][0][0], 0)
End

Function AE_WorksMultiValues()

	variable row, col
	string unit, unitRef, tolerance, toleranceRef
	string key = "someKey"

	unitRef = ""
	toleranceRef = LABNOTEBOOK_NO_TOLERANCE

	Make/D/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
	values[] = p^2
	ED_AddEntryToLabnotebook(device, key, values)

	WAVE/T numericalKeys   = root:MIES:LabNoteBook:ITC18USB:Device0:numericalKeys
	WAVE   numericalValues = root:MIES:LabNoteBook:ITC18USB:Device0:numericalValues

	// key is added with prefix, so there is no full match
	FindValue/TXOP=4/TEXT=key numericalKeys
	CHECK_EQUAL_VAR(V_Value, -1)

	FindValue/TEXT=key numericalKeys
	col = floor(V_Value / DimSize(numericalKeys, ROWS))
	row = V_Value - col * DimSize(numericalKeys, ROWS)
	CHECK_EQUAL_VAR(row, 0)
	CHECK_EQUAL_VAR(col, 4)

	unit = numericalKeys[1][col]
	CHECK_EQUAL_STR(unit, unitRef)

	tolerance = numericalKeys[2][col]
	CHECK_EQUAL_STR(tolerance, toleranceRef)

	// entries can be found
	Duplicate/FREE/RMD=[0][col][] numericalValues, found
	Redimension/N=(LABNOTEBOOK_LAYER_COUNT) found
	CHECK_EQUAL_WAVES(found, values, mode = WAVE_DATA)

	WAVE/Z settings = GetLastSetting(numericalValues, 0, LABNOTEBOOK_USER_PREFIX + key, UNKNOWN_MODE)
	CHECK(WaveExists(settings))
	CHECK_EQUAL_WAVES(settings, values, mode = WAVE_DATA)

	// inserted under correct sweep number
	CHECK_EQUAL_VAR(numericalValues[0][0][0], 0)
End

Function AE_WorksIndepHeadstage()

	variable row, col, i
	string unit, unitRef, tolerance, toleranceRef
	string key = "someKey"

	unitRef = ""
	toleranceRef = LABNOTEBOOK_NO_TOLERANCE

	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
	values[LABNOTEBOOK_LAYER_COUNT - 1] = 4711
	ED_AddEntryToLabnotebook(device, key, values)

	WAVE/T numericalKeys   = root:MIES:LabNoteBook:ITC18USB:Device0:numericalKeys
	WAVE   numericalValues = root:MIES:LabNoteBook:ITC18USB:Device0:numericalValues

	// key is added with prefix, so there is no full match
	FindValue/TXOP=4/TEXT=key numericalKeys
	CHECK_EQUAL_VAR(V_Value, -1)

	FindValue/TEXT=key numericalKeys
	col = floor(V_Value / DimSize(numericalKeys, ROWS))
	row = V_Value - col * DimSize(numericalKeys, ROWS)
	CHECK_EQUAL_VAR(row, 0)
	CHECK_EQUAL_VAR(col, 4)

	unit = numericalKeys[1][col]
	CHECK_EQUAL_STR(unit, unitRef)

	tolerance = numericalKeys[2][col]
	CHECK_EQUAL_STR(tolerance, toleranceRef)

	// entry can be found
	CHECK_EQUAL_VAR(numericalValues[0][col][8], 4711)
	WaveStats/Q/RMD=[0][col] numericalValues
	CHECK_EQUAL_VAR(V_numNaNs, 8)

	// inserted under correct sweep number
	CHECK_EQUAL_VAR(numericalValues[0][0][0], 0)
End

Function AE_OverrideSweepNoAborts()

	variable row, col, i
	string unit, unitRef, tolerance, toleranceRef
	string key = "someKey"

	unitRef = ""
	toleranceRef = LABNOTEBOOK_NO_TOLERANCE

	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
	values[LABNOTEBOOK_LAYER_COUNT - 1] = 4711

	try
		ED_AddEntryToLabnotebook(device, key, values, overrideSweepNo = inf)
		FAIL()
	catch
		PASS()
	endtry

	try
		ED_AddEntryToLabnotebook(device, key, values, overrideSweepNo = -1)
		FAIL()
	catch
		PASS()
	endtry
End

Function AE_OverrideSweepNoWorks()

	variable row, col, i
	string unit, unitRef, tolerance, toleranceRef
	string key = "someKey"

	unitRef = ""
	toleranceRef = LABNOTEBOOK_NO_TOLERANCE

	Make/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values = NaN
	values[LABNOTEBOOK_LAYER_COUNT - 1] = 4711
	ED_AddEntryToLabnotebook(device, key, values, overrideSweepNo = 1234)

	WAVE/T numericalKeys   = root:MIES:LabNoteBook:ITC18USB:Device0:numericalKeys
	WAVE   numericalValues = root:MIES:LabNoteBook:ITC18USB:Device0:numericalValues

	// key is added with prefix, so there is no full match
	FindValue/TXOP=4/TEXT=key numericalKeys
	CHECK_EQUAL_VAR(V_Value, -1)

	FindValue/TEXT=key numericalKeys
	col = floor(V_Value / DimSize(numericalKeys, ROWS))
	row = V_Value - col * DimSize(numericalKeys, ROWS)
	CHECK_EQUAL_VAR(row, 0)
	CHECK_EQUAL_VAR(col, 4)

	unit = numericalKeys[1][col]
	CHECK_EQUAL_STR(unit, unitRef)

	tolerance = numericalKeys[2][col]
	CHECK_EQUAL_STR(tolerance, toleranceRef)

	// entry can be found
	CHECK_EQUAL_VAR(numericalValues[0][col][8], 4711)
	WaveStats/Q/RMD=[0][col] numericalValues
	CHECK_EQUAL_VAR(V_numNaNs, 8)

	// inserted under correct sweep number
	CHECK_EQUAL_VAR(numericalValues[0][0][0], 1234)
End

Function ATE_TextWorks1()

	variable row, col, i
	string unit, unitRef, tolerance, toleranceRef, str, strRef
	string key = "someKey"

	unitRef   = ""
	toleranceRef = LABNOTEBOOK_NO_TOLERANCE

	Make/T/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values
	strRef    = "4711"
	values[0] = strRef
	ED_AddEntryToLabnotebook(device, key, values)

	WAVE/T textualKeys   = root:MIES:LabNoteBook:ITC18USB:Device0:textualKeys
	WAVE/T textualValues = root:MIES:LabNoteBook:ITC18USB:Device0:textualValues

	// key is added with prefix, so there is no full match
	FindValue/TXOP=4/TEXT=key textualKeys
	CHECK_EQUAL_VAR(V_Value, -1)

	FindValue/TEXT=key textualKeys
	col = floor(V_Value / DimSize(textualKeys, ROWS))
	row = V_Value - col * DimSize(textualKeys, ROWS)
	CHECK_EQUAL_VAR(row, 0)
	CHECK_EQUAL_VAR(col, 4)

	unit = textualKeys[1][col]
	CHECK_EQUAL_STR(unit, unitRef)

	tolerance = textualKeys[2][col]
	CHECK_EQUAL_STR(tolerance, toleranceRef)

	// entry can be found
	str = textualValues[0][col][0]
	CHECK_EQUAL_STR(str, strRef)
	CHECK_EQUAL_STR(str, strRef)
	for(i = 1; i < 9; i += 1)
		str = textualValues[0][col][i]
		CHECK_EMPTY_STR(str)
	endfor

	// inserted under correct sweep number
	CHECK_EQUAL_VAR(str2num(textualValues[0][0][0]), 0)
End

Function AE_TextWorksIndepHeadstage()

	variable row, col, i
	string unit, unitRef, tolerance, toleranceRef, str, strRef
	string key = "someKey"

	unitRef   = ""
	toleranceRef = LABNOTEBOOK_NO_TOLERANCE

	Make/T/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values
	strRef    = "4711"
	values[LABNOTEBOOK_LAYER_COUNT - 1] = strRef
	ED_AddEntryToLabnotebook(device, key, values)

	WAVE/T textualKeys   = root:MIES:LabNoteBook:ITC18USB:Device0:textualKeys
	WAVE/T textualValues = root:MIES:LabNoteBook:ITC18USB:Device0:textualValues

	// key is added with prefix, so there is no full match
	FindValue/TXOP=4/TEXT=key textualKeys
	CHECK_EQUAL_VAR(V_Value, -1)

	FindValue/TEXT=key textualKeys
	col = floor(V_Value / DimSize(textualKeys, ROWS))
	row = V_Value - col * DimSize(textualKeys, ROWS)
	CHECK_EQUAL_VAR(row, 0)
	CHECK_EQUAL_VAR(col, 4)

	unit = textualKeys[1][col]
	CHECK_EQUAL_STR(unit, unitRef)

	tolerance = textualKeys[2][col]
	CHECK_EQUAL_STR(tolerance, toleranceRef)

	// entry can be found
	str = textualValues[0][col][8]
	CHECK_EQUAL_STR(str, strRef)
	for(i = 0; i < 8; i += 1)
		str = textualValues[0][col][i]
		CHECK_EMPTY_STR(str)
	endfor

	// inserted under correct sweep number
	CHECK_EQUAL_VAR(str2num(textualValues[0][0][0]), 0)
End

Function AE_NormalizesEOLs()

	variable row, col, i
	string unit, unitRef, tolerance, toleranceRef, str, strRef, normalizedStr
	string key = "someKey"

	unitRef   = ""
	toleranceRef = LABNOTEBOOK_NO_TOLERANCE

	Make/T/FREE/N=(LABNOTEBOOK_LAYER_COUNT) values
	strRef    = "123\r456\r\n"
	values[LABNOTEBOOK_LAYER_COUNT - 1] = strRef
	ED_AddEntryToLabnotebook(device, key, values)

	WAVE/T textualKeys   = root:MIES:LabNoteBook:ITC18USB:Device0:textualKeys
	WAVE/T textualValues = root:MIES:LabNoteBook:ITC18USB:Device0:textualValues

	// key is added with prefix, so there is no full match
	FindValue/TXOP=4/TEXT=key textualKeys
	CHECK_EQUAL_VAR(V_Value, -1)

	FindValue/TEXT=key textualKeys
	col = floor(V_Value / DimSize(textualKeys, ROWS))
	row = V_Value - col * DimSize(textualKeys, ROWS)
	CHECK_EQUAL_VAR(row, 0)
	CHECK_EQUAL_VAR(col, 4)

	unit = textualKeys[1][col]
	CHECK_EQUAL_STR(unit, unitRef)

	tolerance = textualKeys[2][col]
	CHECK_EQUAL_STR(tolerance, toleranceRef)

	// entry can be found
	str = textualValues[0][col][8]
	normalizedStr = "123\n456\n"
	CHECK_EQUAL_STR(str, normalizedStr)
	for(i = 0; i < 8; i += 1)
		str = textualValues[0][col][i]
		CHECK_EMPTY_STR(str)
	endfor

	// inserted under correct sweep number
	CHECK_EQUAL_VAR(str2num(textualValues[0][0][0]), 0)
End

/// END ED_AddEntryToLabnotebook
/// @}
