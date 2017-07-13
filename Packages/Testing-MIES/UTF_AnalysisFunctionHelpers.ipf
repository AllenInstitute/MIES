#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma ModuleName=UTF_AnalyisFunctionHelpers

static StrConstant device = "ITC18USB_Dev_0"

static Function TEST_CASE_BEGIN_OVERRIDE(testCase)
	string testCase

	KillDataFolder/Z root:MIES

	if(DataFolderExists("root:MIES"))
		Abort "Cleanup did not work"
	endif
End

/// BEGIN ED_AddEntryToLabnotebook
/// @{

Function AE_ThrowsWithEmptyKey()

	try
		ED_AddEntryToLabnotebook(device, 0, "", value = 0)
		FAIL()
	catch
		PASS()
	endtry
End

Function AE_ThrowsWithInvalidHS1()

	try
		ED_AddEntryToLabnotebook(device, -1, "a", value = 0)
		FAIL()
	catch
		PASS()
	endtry
End

Function AE_ThrowsWithInvalidHS2()

	try
		ED_AddEntryToLabnotebook(device, NUM_HEADSTAGES, "a", value = 0)
		FAIL()
	catch
		PASS()
	endtry
End

Function AE_ThrowsWithTooLongKey()

	try
		ED_AddEntryToLabnotebook(device, 0, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" , value = 0)
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
	ED_AddEntryToLabnotebook(device, 0, key , value = 4711)

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
End

Function AE_Works2()

	variable row, col
	string unit, unitRef, tolerance, toleranceRef
	string key = "someKey"

	unitRef   = "hi there"
	toleranceRef = "123"
	ED_AddEntryToLabnotebook(device, 0, key , value = 4711, unit = unitRef, tolerance = str2num(toleranceRef))

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
End

Function AE_Works3()

	variable row, col
	string unit, unitRef, tolerance, toleranceRef
	string key = "someKey"

	unitRef = ""
	toleranceRef = LABNOTEBOOK_NO_TOLERANCE
	// internally NaN is translated to -
	ED_AddEntryToLabnotebook(device, 0, key , value = 4711, tolerance = NaN)

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
End

Function AE_Works4()

	variable row, col
	string unit, unitRef, tolerance, toleranceRef
	string key = "someKey"

	unitRef = ""
	toleranceRef = LABNOTEBOOK_NO_TOLERANCE
	ED_AddEntryToLabnotebook(device, 0, key , value = 4711)

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
End

Function AE_WorksIndepHeadstage()

	variable row, col, i
	string unit, unitRef, tolerance, toleranceRef
	string key = "someKey"

	unitRef = ""
	toleranceRef = LABNOTEBOOK_NO_TOLERANCE
	ED_AddEntryToLabnotebook(device, NaN, key , value = 4711)

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
End

Function ATE_TextWorks1()

	variable row, col, i
	string unit, unitRef, tolerance, toleranceRef, str, strRef
	string key = "someKey"

	unitRef   = ""
	toleranceRef = LABNOTEBOOK_NO_TOLERANCE
	strRef    = "4711"
	ED_AddEntryToLabnotebook(device, 0, key , str = strRef)

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
End

Function AE_TextWorksIndepHeadstage()

	variable row, col, i
	string unit, unitRef, tolerance, toleranceRef, str, strRef
	string key = "someKey"

	unitRef   = ""
	toleranceRef = LABNOTEBOOK_NO_TOLERANCE
	strRef    = "4711"
	ED_AddEntryToLabnotebook(device, NaN, key, str = strRef)

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
End

/// END ED_AddEntryToLabnotebook
/// @}
