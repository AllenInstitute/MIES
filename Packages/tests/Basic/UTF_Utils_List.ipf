#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = UTILSTEST_LIST

// AddPrefixToEachListItem
/// @{

Function APTEA_WorksWithList()

	string list, ref

	list = AddPrefixToEachListItem("ab-", "c;d")
	ref  = "ab-c;ab-d;"
	CHECK_EQUAL_STR(list, ref)
End

Function APTEA_WorksWithListAndCustomSep()

	string list, ref

	list = AddPrefixToEachListItem("ab-", "c|d", sep = "|")
	ref  = "ab-c|ab-d|"
	CHECK_EQUAL_STR(list, ref)
End

Function APTEA_WorksOnEmptyBoth()

	string list

	list = AddPrefixToEachListItem("", "")
	CHECK_EMPTY_STR(list)
End

/// @}

// AddSuffixToEachListItem
/// @{

Function ASTEA_WorksWithList()

	string list, ref

	list = AddSuffixToEachListItem("-ab", "c;d")
	ref  = "c-ab;d-ab;"
	CHECK_EQUAL_STR(list, ref)
End

Function ASTEA_WorksWithListAndCustomSep()

	string list, ref

	list = AddSuffixToEachListItem("-ab", "c|d", sep = "|")
	ref  = "c-ab|d-ab|"
	CHECK_EQUAL_STR(list, ref)
End

Function ASTEA_WorksOnEmptyBoth()

	string list

	list = AddSuffixToEachListItem("", "")
	CHECK_EMPTY_STR(list)
End

/// @}

/// RemovePrefixFromListItem
/// @{

Function RPFLI_Works()

	string ref, str

	// empty list
	str = RemovePrefixFromListItem("abcd", "")
	CHECK_EMPTY_STR(str)

	// empty prefix
	str = RemovePrefixFromListItem("", "abcd")
	ref = "abcd;"
	CHECK_EQUAL_STR(ref, str)

	// works
	str = RemovePrefixFromListItem("a", "aa;ab")
	ref = "a;b;"
	CHECK_EQUAL_STR(ref, str)

	// works with custom list sep
	str = RemovePrefixFromListItem("a", "aa|ab", listSep = "|")
	ref = "a|b|"
	CHECK_EQUAL_STR(ref, str)

	// regexp works
	str = RemovePrefixFromListItem("[a-z]*", "a12;bcdf45", regExp = 1)
	ref = "12;45;"
	CHECK_EQUAL_STR(ref, str)
End

/// @}

Function PrepareListForDisplay_Works()

	CHECK_EQUAL_STR("", PrepareListForDisplay(""))
	CHECK_EQUAL_STR("a", PrepareListForDisplay("a"))
	CHECK_EQUAL_STR("a;b", PrepareListForDisplay("a;b"))
	CHECK_EQUAL_STR("a\rb", PrepareListForDisplay("a;b;"))
End

Function NumberFromList_Works()

	variable num

	num = NumberFromList(0, "")
	CHECK_EQUAL_VAR(num, NaN)

	num = NumberFromList(0, "123")
	CHECK_EQUAL_VAR(num, 123)

	num = NumberFromList(1, "123;456")
	CHECK_EQUAL_VAR(num, 456)

	num = NumberFromList(2, "123;456")
	CHECK_EQUAL_VAR(num, NaN)

	// cuts off at first non-digit
	num = NumberFromList(1, "123;456a")
	CHECK_EQUAL_VAR(num, 456)

	num = NumberFromList(1, "123|456", sep = "|")
	CHECK_EQUAL_VAR(num, 456)
End

Function LastStringFromList_Works()

	string elem

	elem = LastStringFromList("")
	CHECK_EQUAL_STR(elem, "")

	elem = LastStringFromList("abc")
	CHECK_EQUAL_STR(elem, "abc")

	elem = LastStringFromList("abc;efg")
	CHECK_EQUAL_STR(elem, "efg")

	elem = LastStringFromList("abc|efg|hij", sep = "|")
	CHECK_EQUAL_STR(elem, "hij")
End

// ListMatchesExpr
/// @{

Function LME_WorksWithRegexp()

	string result, list

	// Test with MATCH_REGEXP
	list   = "abc;def;ghi;jkl"
	result = ListMatchesExpr(list, "^abc$", MATCH_REGEXP)
	CHECK_EQUAL_STR(result, "abc;")

	result = ListMatchesExpr(list, "^d.*", MATCH_REGEXP)
	CHECK_EQUAL_STR(result, "def;")

	result = ListMatchesExpr(list, ".*[ik].*", MATCH_REGEXP)
	CHECK_EQUAL_STR(result, "ghi;jkl;")

	// Empty list
	result = ListMatchesExpr("", ".*", MATCH_REGEXP)
	CHECK_EMPTY_STR(result)

	// No match
	result = ListMatchesExpr(list, "xyz", MATCH_REGEXP)
	CHECK_EMPTY_STR(result)
End

Function LME_WorksWithWildcard()

	string result, list

	// Test with MATCH_WILDCARD
	list   = "abc;def;ghi;jkl"
	result = ListMatchesExpr(list, "abc", MATCH_WILDCARD)
	CHECK_EQUAL_STR(result, "abc;")

	result = ListMatchesExpr(list, "d*", MATCH_WILDCARD)
	CHECK_EQUAL_STR(result, "def;")

	result = ListMatchesExpr(list, "*h*", MATCH_WILDCARD)
	CHECK_EQUAL_STR(result, "ghi;")

	// Empty list
	result = ListMatchesExpr("", "*", MATCH_WILDCARD)
	CHECK_EMPTY_STR(result)

	// No match
	result = ListMatchesExpr(list, "xyz", MATCH_WILDCARD)
	CHECK_EMPTY_STR(result)
End

Function LME_InvalidExprType()

	string result

	try
		result = ListMatchesExpr("abc;def", ".*", 999); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

/// @}

// ListFromList
/// @{

Function LFL_WorksBasic()

	string result

	// Get single item
	result = ListFromList("a;b;c;d", 0, 0)
	CHECK_EQUAL_STR(result, "a;")

	result = ListFromList("a;b;c;d", 2, 2)
	CHECK_EQUAL_STR(result, "c;")

	// Get range
	result = ListFromList("a;b;c;d", 1, 2)
	CHECK_EQUAL_STR(result, "b;c;")

	result = ListFromList("a;b;c;d", 0, 2)
	CHECK_EQUAL_STR(result, "a;b;c;")

	// Get all
	result = ListFromList("a;b;c;d", 0, 3)
	CHECK_EQUAL_STR(result, "a;b;c;d;")
End

Function LFL_WorksWithCustomSep()

	string result

	result = ListFromList("a|b|c|d", 1, 2, listSep = "|")
	CHECK_EQUAL_STR(result, "b|c|")
End

Function LFL_WorksWithEndBeyondList()

	string result

	// itemEnd beyond list should return up to end
	result = ListFromList("a;b;c", 1, 10)
	CHECK_EQUAL_STR(result, "b;c;")
End

Function LFL_WorksWithStartBeyondList()

	string result

	// itemBegin beyond list should return empty
	result = ListFromList("a;b;c", 10, 20)
	CHECK_EMPTY_STR(result)
End

Function LFL_InvalidRangeAsserts()

	string result

	try
		result = ListFromList("a;b;c", 2, 1); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

/// @}

// BuildList
/// @{

Function BL_WorksBasic()

	string result

	result = BuildList("item_%d", 0, 1, 3)
	CHECK_EQUAL_STR(result, "item_0;item_1;item_2;")

	result = BuildList("val_%d", 1, 1, 4)
	CHECK_EQUAL_STR(result, "val_1;val_2;val_3;")

	result = BuildList("x%d", 5, 2, 11)
	CHECK_EQUAL_STR(result, "x5;x7;x9;")
End

Function BL_WorksWithFloatingPoint()

	string result

	// Format string can use different specifiers
	result = BuildList("%.1f", 0, 0.5, 2)
	CHECK_EQUAL_STR(result, "0.0;0.5;1.0;1.5;")
End

Function BL_InvalidRangeAsserts()

	string result

	try
		result = BuildList("item_%d", 10, 1, 5); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

Function BL_InvalidStepAsserts()

	string result

	try
		result = BuildList("item_%d", 0, 0, 10); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry

	try
		result = BuildList("item_%d", 0, -1, 10); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

/// @}

// WaveListHasSameWaveNames
/// @{

Function WLHSWN_WorksWithSameNames()

	string   baseName
	variable result

	result = WaveListHasSameWaveNames("root:folder1:wave1;root:folder2:wave1;root:folder3:wave1", baseName)
	CHECK_EQUAL_VAR(result, 1)
	CHECK_EQUAL_STR(baseName, "wave1")
End

Function WLHSWN_WorksWithDifferentNames()

	string   baseName
	variable result

	result = WaveListHasSameWaveNames("root:folder1:wave1;root:folder2:wave2", baseName)
	CHECK_EQUAL_VAR(result, 0)
	CHECK_EMPTY_STR(baseName)
End

Function WLHSWN_WorksWithSingleWave()

	string   baseName
	variable result

	result = WaveListHasSameWaveNames("root:myWave", baseName)
	CHECK_EQUAL_VAR(result, 1)
	CHECK_EQUAL_STR(baseName, "myWave")
End

Function WLHSWN_WorksWithEmptyList()

	string   baseName
	variable result

	result = WaveListHasSameWaveNames("", baseName)
	CHECK_EQUAL_VAR(result, NaN)
	CHECK_EMPTY_STR(baseName)
End

Function WLHSWN_WorksWithPathVariations()

	string   baseName
	variable result

	// Test with different path depths
	result = WaveListHasSameWaveNames("wave1;root:wave1;root:a:b:c:wave1", baseName)
	CHECK_EQUAL_VAR(result, 1)
	CHECK_EQUAL_STR(baseName, "wave1")
End

/// @}

// MergeLists
/// @{

Function ML_WorksBasic()

	string result

	result = MergeLists("a;b;c", "d;e;f")
	CHECK_EQUAL_STR(result, "d;e;f;a;b;c;")

	result = MergeLists("a;b", "c;d")
	CHECK_EQUAL_STR(result, "c;d;a;b;")
End

Function ML_WorksWithDuplicates()

	string result

	// Duplicates in l2 are kept, items from l1 not added if in l2
	result = MergeLists("a;b;c", "a;d;d;f")
	CHECK_EQUAL_STR(result, "a;d;d;f;b;c;")

	result = MergeLists("x;y", "x;x;z")
	CHECK_EQUAL_STR(result, "x;x;z;y;")
End

Function ML_WorksWithEmptyLists()

	string result

	result = MergeLists("", "a;b")
	CHECK_EQUAL_STR(result, "a;b;")

	result = MergeLists("a;b", "")
	CHECK_EQUAL_STR(result, "a;b;")

	result = MergeLists("", "")
	CHECK_EMPTY_STR(result)
End

Function ML_WorksWithCustomSep()

	string result

	result = MergeLists("a|b", "c|d", sep = "|")
	CHECK_EQUAL_STR(result, "c|d|a|b|")

	result = MergeLists("a|b", "a|c", sep = "|")
	CHECK_EQUAL_STR(result, "a|c|b|")
End

Function ML_EmptySepAsserts()

	string result

	try
		result = MergeLists("a;b", "c;d", sep = ""); AbortOnRTE
		FAIL()
	catch
		PASS()
	endtry
End

/// @}
