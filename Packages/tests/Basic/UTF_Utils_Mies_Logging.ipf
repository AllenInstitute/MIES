#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTILSTEST_MIES_LOGGING

// Missing Tests for:
// GetZeroMQXOPLogfile
// GetITCXOP2Logfile
// ArchiveLogFilesOnceAndKeepMonth

/// FilterByDate
/// @{

static Function FBD_CheckParams()

	variable lastIndex

	Make/FREE/N=0/T input = {""}

	WAVE/Z/T filtered = $""

	try
		[filtered, lastIndex] = FilterByDate(input, NaN, 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		[filtered, lastIndex] = FilterByDate(input, 0, NaN)
		FAIL()
	catch
		PASS()
	endtry

	try
		[filtered, lastIndex] = FilterByDate(input, 0, -1)
		FAIL()
	catch
		PASS()
	endtry

	try
		[filtered, lastIndex] = FilterByDate(input, -1, 0)
		FAIL()
	catch
		PASS()
	endtry

	try
		[filtered, lastIndex] = FilterByDate(input, 2, 1)
		FAIL()
	catch
		PASS()
	endtry
End

static Function FBD_Works()
	variable last, first

	variable lastIndex

	WAVE/Z/T result = $""

	// empty gives null
	Make/FREE/T/N=0 input
	[result, lastIndex] = FilterByDate(input, 0, 1)
	CHECK_WAVE(result, NULL_WAVE)

	Make/FREE/T input = {"{\"ts\" : \"2021-12-24T00:00:00Z\", \"stuff\" : \"abcd\"}", \
	                     "{\"ts\" : \"2022-01-20T00:00:00Z\", \"stuff\" : \"efgh\"}", \
	                     "{\"ts\" : \"2022-01-25T00:00:00Z\", \"stuff\" : \"ijkl\"}"}

	// borders are included (1)
	Make/FREE/T ref = {"{\"ts\" : \"2021-12-24T00:00:00Z\", \"stuff\" : \"abcd\"}", \
	                   "{\"ts\" : \"2022-01-20T00:00:00Z\", \"stuff\" : \"efgh\"}"}

	first = 0
	last  = ParseIsO8601TimeStamp("2022-01-20T00:00:00Z")
	[result, lastIndex] = FilterByDate(input, first, last)
	CHECK_EQUAL_TEXTWAVES(result, ref)
	CHECK_EQUAL_VAR(lastIndex, 1)

	// borders are included (2)
	Make/FREE/T ref = {"{\"ts\" : \"2021-12-24T00:00:00Z\", \"stuff\" : \"abcd\"}", \
	                   "{\"ts\" : \"2022-01-20T00:00:00Z\", \"stuff\" : \"efgh\"}"}

	first = ParseIsO8601TimeStamp("2021-12-24T00:00:00Z")
	last  = ParseIsO8601TimeStamp("2022-01-20T00:00:00Z")
	[result, lastIndex] = FilterByDate(input, first, last)
	CHECK_EQUAL_TEXTWAVES(result, ref)
	CHECK_EQUAL_VAR(lastIndex, 1)

	// will result null if nothing is in range (1)
	first = ParseIsO8601TimeStamp("2021-12-24T00:00:00Z") + 1
	last  = ParseIsO8601TimeStamp("2022-01-20T00:00:00Z") - 1
	[result, lastIndex] = FilterByDate(input, first, last)
	CHECK_WAVE(result, NULL_WAVE)

	// will result null if nothing is in range (2)
	first = ParseIsO8601TimeStamp("2020-01-01T00:00:00Z")
	last  = ParseIsO8601TimeStamp("2020-12-31T00:00:00Z")
	[result, lastIndex] = FilterByDate(input, first, last)
	CHECK_WAVE(result, NULL_WAVE)
End

static Function FBD_WorksWithInvalidTimeStamp()

	variable last, first
	variable lastIndex

	WAVE/Z/T result = $""

	Make/FREE/T input2 = {"{}", "{}", "{\"ts\" : \"2021-12-24T00:00:00Z\"}", \
	                      "{}", "{}", "{\"ts\" : \"2022-01-20T00:00:00Z\"}", \
	                      "{}", "{}", "{\"ts\" : \"2022-01-25T00:00:00Z\"}", \
	                      "{}", "{}"}

	Make/FREE/T input3 = {"{}", "{}", "{}", "{}", "{}", "{}", "{}", "{}"}

	// invalid ts at borders are included (2)
	Make/FREE/T ref = {"{}", "{}", "{\"ts\" : \"2021-12-24T00:00:00Z\"}", \
	                   "{}", "{}", "{\"ts\" : \"2022-01-20T00:00:00Z\"}", \
	                   "{}", "{}"}

	first = ParseIsO8601TimeStamp("2021-12-24T00:00:00Z")
	last  = ParseIsO8601TimeStamp("2022-01-20T00:00:00Z")
	[result, lastIndex] = FilterByDate(input2, first, last)
	CHECK_EQUAL_TEXTWAVES(result, ref)
	CHECK_EQUAL_VAR(lastIndex, 7)

	// left boundary
	first = 0
	last  = ParseIsO8601TimeStamp("2022-01-20T00:00:00Z")
	[result, lastIndex] = FilterByDate(input2, first, last)
	CHECK_EQUAL_TEXTWAVES(result, ref)
	CHECK_EQUAL_VAR(lastIndex, 7)

	// right boundary
	Make/FREE/T ref = {"{}", "{}", "{\"ts\" : \"2021-12-24T00:00:00Z\"}", \
	                   "{}", "{}", "{\"ts\" : \"2022-01-20T00:00:00Z\"}", \
	                   "{}", "{}", "{\"ts\" : \"2022-01-25T00:00:00Z\"}", \
	                   "{}", "{}"}

	first = ParseIsO8601TimeStamp("2021-12-24T00:00:00Z")
	last  = Inf
	[result, lastIndex] = FilterByDate(input2, first, last)
	CHECK_EQUAL_TEXTWAVES(result, ref)
	CHECK_EQUAL_VAR(lastIndex, DimSize(input2, ROWS) - 1)

	// all invalid ts
	first = 0
	last  = ParseIsO8601TimeStamp("2021-12-24T00:00:00Z")
	[result, lastIndex] = FilterByDate(input3, first, last)
	CHECK_EQUAL_TEXTWAVES(result, input3)
	CHECK_EQUAL_VAR(lastIndex, DimSize(input3, ROWS) - 1)

	first = ParseIsO8601TimeStamp("2021-12-24T00:00:00Z")
	last  = ParseIsO8601TimeStamp("2022-01-20T00:00:00Z")
	[result, lastIndex] = FilterByDate(input3, first, last)
	CHECK_EQUAL_TEXTWAVES(result, input3)
	CHECK_EQUAL_VAR(lastIndex, DimSize(input3, ROWS) - 1)

	first = ParseIsO8601TimeStamp("2021-12-24T00:00:00Z")
	last  = Inf
	[result, lastIndex] = FilterByDate(input3, first, last)
	CHECK_EQUAL_TEXTWAVES(result, input3)
	CHECK_EQUAL_VAR(lastIndex, DimSize(input3, ROWS) - 1)

	// right boundary with invalid ts
	Make/FREE/T input4 = {"{\"ts\" : \"2021-12-24T00:00:00Z\"}",       \
	                      "{}", "{\"ts\" : \"2022-01-20T00:00:00Z\"}", \
	                      "{}", "{\"ts\" : \"2022-01-25T00:00:00Z\"}", \
	                      "{}"}

	first = 0
	last  = ParseIsO8601TimeStamp("2022-01-25T00:00:00Z")
	[result, lastIndex] = FilterByDate(input4, first, last)
	CHECK_EQUAL_TEXTWAVES(result, input4)
	CHECK_EQUAL_VAR(lastIndex, DimSize(input4, ROWS) - 1)
End

/// @}

// More generic test that checks logfile preparation
static Function CheckLogFiles()

	string file, line
	variable foundFiles, jsonID

	// ensure that the ZeroMQ logfile exists as well
	// and also have the right layout
	PrepareForPublishTest()

	WAVE/T filesAndOther = GetLogFileNames()
	Duplicate/RMD=[][0]/FREE/T filesAndOther, files

	for(file : files)
		if(!FileExists(file))
			continue
		endif

		WAVE/T contents = LoadTextFileToWave(file, "\n")
		CHECK_WAVE(contents, TEXT_WAVE)
		CHECK_GT_VAR(DimSize(contents, ROWS), 0)

		for(line : contents)
			if(cmpstr(line, "{}"))
				break
			endif
		endfor

		if(!cmpstr(line, "{}"))
			// only {} inside the file, no need to check for timestamp
			continue
		endif

		jsonID = JSON_Parse(line)
		CHECK(JSON_IsValid(jsonID))

		INFO("File: \"%s\", Line: \"%s\"", s0 = file, s1 = line)

		CHECK(MIES_LOG#LOG_HasRequiredKeys(jsonID))
		WAVE/T keys = JSON_GetKeys(jsonID, "")
		FindValue/TEXT="ts" keys

		INFO("File: \"%s\", Line: \"%s\"", s0 = file, s1 = line)

		CHECK_GE_VAR(V_Value, 0)

		foundFiles += 1
	endfor

	CHECK_GT_VAR(foundFiles, 0)
End
