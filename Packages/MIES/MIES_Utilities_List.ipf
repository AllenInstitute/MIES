#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_UTILS_LIST
#endif // AUTOMATED_TESTING

/// @file MIES_Utilities_List.ipf
/// @brief utility functions for lists

/// @brief Matches `list` against the expression `matchExpr` using the given
///        convention in `exprType`
threadsafe Function/S ListMatchesExpr(string list, string matchExpr, variable exprType)

	switch(exprType)
		case MATCH_REGEXP:
			return GrepList(list, matchExpr)
		case MATCH_WILDCARD:
			return ListMatch(list, matchExpr)
		default:
			FATAL_ERROR("invalid exprType")
	endswitch
End

/// @brief return a subset of the input list
///
/// @param list       input list
/// @param itemBegin  first item
/// @param itemEnd    last item
/// @param listSep    [optional] list Separation character. default is ";"
///
/// @return a list with elements ranging from itemBegin to itemEnd of the input list
Function/S ListFromList(string list, variable itemBegin, variable itemEnd, [string listSep])

	variable i, numItems, start, stop

	if(ParamIsDefault(listSep))
		listSep = ";"
	endif

	ASSERT(itemBegin <= itemEnd, "SubSet missmatch")

	numItems = ItemsInList(list, listSep)
	if(itemBegin >= numItems)
		return ""
	endif
	if(itemEnd >= numItems)
		itemEnd = numItems - 1
	endif

	if(itemBegin == itemEnd)
		return StringFromList(itemBegin, list, listSep) + listSep
	endif

	for(i = 0; i < itemBegin; i += 1)
		start = strsearch(list, listSep, start) + 1
	endfor

	stop = start
	for(i = itemBegin; i < (itemEnd + 1); i += 1)
		stop = strsearch(list, listSep, stop) + 1
	endfor

	return list[start, stop - 1]
End

/// @brief Create a list of strings using the given format in the given range
///
/// @param format   formatting string, must have exactly one specifier which accepts a number
/// @param start	first point of the range
/// @param step	    step size for iterating over the range
/// @param stop 	last point of the range
Function/S BuildList(string format, variable start, variable step, variable stop)

	string str
	string list = ""
	variable i

	ASSERT(start < stop, "Invalid range")
	ASSERT(step > 0, "Invalid step")

	for(i = start; i < stop; i += step)
		sprintf str, format, i
		list = AddListItem(str, list, ";", Inf)
	endfor

	return list
End

/// @brief Checks wether the wave names of all waves in the list are equal
/// Returns 1 if true, 0 if false and NaN for empty lists
///
/// @param      listOfWaves list of waves with full path
/// @param[out] baseName    Returns the common baseName if the list has one,
///                         otherwise this will be an empty string.
Function WaveListHasSameWaveNames(string listOfWaves, string &baseName)

	baseName = ""

	string str, firstBaseName
	variable numWaves, i
	numWaves = ItemsInList(listOfWaves)

	if(numWaves == 0)
		return NaN
	endif

	firstBaseName = GetBaseName(StringFromList(0, listOfWaves))
	for(i = 1; i < numWaves; i += 1)
		str = GetBaseName(StringFromList(i, listOfWaves))
		if(cmpstr(firstBaseName, str))
			return 0
		endif
	endfor

	baseName = firstBaseName
	return 1
End

/// @brief Add a string prefix to each list item and
/// return the new list
threadsafe Function/S AddPrefixToEachListItem(string prefix, string list, [string sep])

	string result = ""
	variable numEntries, i

	if(ParamIsDefault(sep))
		sep = ";"
	endif

	numEntries = ItemsInList(list, sep)
	for(i = 0; i < numEntries; i += 1)
		result = AddListItem(prefix + StringFromList(i, list, sep), result, sep, Inf)
	endfor

	return result
End

/// @brief Add a string suffix to each list item and
/// return the new list
threadsafe Function/S AddSuffixToEachListItem(string suffix, string list, [string sep])

	string result = ""
	variable numEntries, i

	if(ParamIsDefault(sep))
		sep = ";"
	endif

	numEntries = ItemsInList(list, sep)
	for(i = 0; i < numEntries; i += 1)
		result = AddListItem(StringFromList(i, list, sep) + suffix, result, sep, Inf)
	endfor

	return result
End

/// @brief Remove a string prefix from each list item and
///        return the new list
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/S RemovePrefixFromListItem(string prefix, string list, [string listSep, variable regExp])

	string result, entry
	variable numEntries, i

	if(ParamIsDefault(listSep))
		listSep = ";"
	endif

	if(ParamIsDefault(regExp))
		regExp = 0
	else
		regExp = !!regExp
	endif

	result     = ""
	numEntries = ItemsInList(list, listSep)
	for(i = 0; i < numEntries; i += 1)
		entry  = StringFromList(i, list, listSep)
		result = AddListItem(RemovePrefix(entry, start = prefix, regExp = regExp), result, listSep, Inf)
	endfor

	return result
End

/// @brief Merges list l1 into l2. Double entries in l2 are kept.
/// "a;b;c;" with "a;d;d;f;" -> "a;d;d;f;b;c;"
Function/S MergeLists(string l1, string l2, [string sep])

	variable numL1, i
	string item

	if(ParamIsDefault(sep))
		sep = ";"
	else
		ASSERT(!IsEmpty(sep), "separator string is empty")
	endif

	numL1 = ItemsInList(l1, sep)
	for(i = 0; i < numL1; i += 1)
		item = StringFromList(i, l1, sep)
		if(WhichListItem(item, l2, sep) == -1)
			l2 = AddListItem(item, l2, sep, Inf)
		endif
	endfor

	return l2
End

/// @brief Replace the list separator (semicolon) by a CR
Function/S PrepareListForDisplay(string list)

	if(StringEndsWith(list, ";"))
		list = ReplaceString(";", list, "\r")
		list = RemoveEnding(list, "\r")
	endif

	return list
End

/// @brief Return the nth list element as number
threadsafe Function NumberFromList(variable index, string list, [string sep])

	if(ParamIsDefault(sep))
		sep = ";"
	endif

	return str2num(StringFromList(index, list, sep))
End
