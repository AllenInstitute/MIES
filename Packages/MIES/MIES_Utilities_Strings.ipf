#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_UTILS_STRINGS
#endif // AUTOMATED_TESTING

/// @file MIES_Utilities_Strings.ipf
/// @brief utility functions for string handling

/// @brief Same functionality as GetStringFromWaveNote() but accepts a string
///
/// @sa GetStringFromWaveNote()
threadsafe Function/S ExtractStringFromPair(string str, string key, [string keySep, string listSep])

	if(ParamIsDefault(keySep))
		keySep = DEFAULT_KEY_SEP
	endif

	if(ParamIsDefault(listSep))
		listSep = DEFAULT_LIST_SEP
	endif

	ASSERT_TS(!IsEmpty(key), "Empty key")

	// AddEntryIntoWaveNoteAsList creates whitespaces "key = value;"
	str = ReplaceString(" " + keySep + " ", str, keySep)

	return StringByKey(key, str, keySep, listSep)
End

/// @brief Remove the surrounding quotes from the string if they are present
Function/S PossiblyUnquoteName(string name, string quote)

	variable len

	if(isEmpty(name))
		return name
	endif

	len = strlen(name)

	ASSERT(strlen(quote) == 1, "Invalid quote string")

	if(!CmpStr(name[0], quote) && !CmpStr(name[len - 1], quote))
		ASSERT(len > 1, "name is too short")
		return name[1, len - 2]
	endif

	return name
End

/// @brief Break a string into multiple lines
///
/// All spaces and tabs which are not followed by numbers are
/// replace by carriage returns (\\r) if the minimum width was reached.
///
/// A generic solution would either implement the real deal
///
/// Knuth, Donald E.; Plass, Michael F. (1981),
/// Breaking paragraphs into lines
/// Software: Practice and Experience 11 (11):
/// 1119-1184, doi:10.1002/spe.4380111102.
///
/// or translate [1] from C++ to Igor Pro.
///
/// [1]: http://api.kde.org/4.x-api/kdelibs-apidocs/kdeui/html/classKWordWrap.html
///
/// @param str          string to break into lines
/// @param minimumWidth [optional, defaults to zero] Each line, except the last one,
///                     will have at least this length
Function/S LineBreakingIntoPar(string str, [variable minimumWidth])

	variable len, i, width
	string output = ""
	string curr, next

	if(ParamIsDefault(minimumWidth))
		minimumWidth = 0
	else
		ASSERT(IsFinite(minimumWidth), "Non finite minimum width")
	endif

	len = strlen(str)
	for(i = 0; i < len; i += 1, width += 1)
		curr = str[i]
		next = SelectString(i < len, "", str[i + 1])

		// str2num skips leading spaces and tabs
		if((!cmpstr(curr, " ") || !cmpstr(curr, "\t"))                            \
		   && IsNaN(str2numSafe(next)) && cmpstr(next, " ") && cmpstr(next, "\t") \
		   && width >= minimumWidth)
			output += "\r"
			width   = 0
			continue
		endif

		output += curr
	endfor

	return output
End

/// @brief Remove a prefix from a string
///
/// Same semantics as the RemoveEnding builtin for regExp == 0.
///
/// @param str    string to potentially remove something from its beginning
/// @param start  [optional, defaults to the first character] Remove this from
///               the begin of str
/// @param regExp [optional, defaults to false] If start is a simple string (false)
///               or a regular expression (true)
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/S RemovePrefix(string str, [string start, variable regExp])

	variable length, pos, skipLength, err
	string regExpResult

	if(ParamIsDefault(regExp))
		regExp = 0
	else
		regExp = !!regExp
	endif

	length = strlen(str)

	if(ParamIsDefault(start))
		if(length <= 0)
			return str
		endif

		return str[1, length - 1]
	endif

	if(regExp)
		AssertOnAndClearRTError()
		SplitString/E=("^(" + start + ")") str, regExpResult; err = GetRTError(1) // see developer docu section Preventing Debugger Popup

		if(V_flag == 1 && err == 0)
			skipLength = strlen(regExpResult)
		else
			return str
		endif
	else
		pos = strsearch(str, start, 0)

		if(pos != 0)
			return str
		endif

		skipLength = strlen(start)
	endif

	return str[skipLength, length - 1]
End

/// @brief Remove the given reguluar expression from the end of the string
///
/// In case the regular expression does not match, the string is returned unaltered.
///
/// See also `DisplayHelpTopic "Regular Expressions"`.
threadsafe Function/S RemoveEndingRegExp(string str, string endingRegExp)

	string   endStr
	variable err

	if(isEmpty(str) || isEmpty(endingRegExp))
		return str
	endif

	AssertOnAndClearRTError()
	SplitString/E=("(" + endingRegExp + ")$") str, endStr; err = GetRTError(1)
	ASSERT_TS((V_flag == 0 || V_flag == 1) && err == 0, "Unexpected number of matches or invalid regex")

	return RemoveEnding(str, endStr)
End

/// @brief Search for a Word inside a String
///
/// @param[in]  str    input text in which word should be searched
/// @param[in]  word   searchpattern (non-regex-sensitive)
/// @param[out] prefix (optional) string preceding word. ("" for unmatched pattern)
/// @param[out] suffix (optional) string succeeding word.
///
/// example of the usage of SearchStringBase (basically the same as WM GrepString())
/// \rst
/// .. code-block:: igorpro
///
/// 	Function SearchString(str, substring)
/// 		string str, substring
///
/// 		ASSERT(!IsEmpty(substring), "supplied substring is empty")
/// 		WAVE/Z/T wv = SearchStringBase(str, "(.*)\\Q" + substring + "\\E(.*)")
///
/// 		return WaveExists(wv)
/// 	End
/// \endrst
///
/// @return 1 if word was found in str and word was not "". 0 if not.
Function SearchWordInString(string str, string word, [string &prefix, string &suffix])

	string prefixParam, suffixParam
	variable ret

	[ret, prefixParam, suffixParam] = SearchRegexInString(str, "\\b\\Q" + word + "\\E\\b")

	if(!ret)
		return ret
	endif

	if(!ParamIsDefault(prefix))
		prefix = prefixParam
	endif

	if(!ParamIsDefault(suffix))
		suffix = suffixParam
	endif

	return ret
End

static Function [variable ret, string prefix, string suffix] SearchRegexInString(string str, string regex)

	ASSERT(IsValidRegexp(regex), "Empty regex")

	WAVE/Z/T wv = SearchStringBase(str, "(.*)" + regex + "(.*)")

	if(!WaveExists(wv))
		return [0, "", ""]
	endif

	return [1, wv[0], wv[1]]
End

/// @brief More advanced version of SplitString
///
/// supports 6 subpatterns, specified by curly brackets in regex
///
/// @returns text wave containing subpatterns of regex call
Function/WAVE SearchStringBase(string str, string regex)

	string command
	variable i, numBrackets
	string str0, str1, str2, str3, str4, str5

	// create wave for storing parsing results
	ASSERT(!GrepString(regex, "\\\\[\\(|\\)]"), "unsupported escaped brackets in regex pattern")
	numBrackets = CountSubstrings(regex, "(")
	ASSERT(numBrackets == CountSubstrings(regex, ")"), "missing bracket in regex pattern")
	ASSERT(numBrackets < 7, "maximum 6 subpatterns are supported")
	Make/N=(6)/FREE/T wv

	// call SplitString
	SplitString/E=regex str, str0, str1, str2, str3, str4, str5
	wv[0] = str0
	wv[1] = str1
	wv[2] = str2
	wv[3] = str3
	wv[4] = str4
	wv[5] = str5

	// return wv on success
	if(V_flag == numBrackets)
		Redimension/N=(numbrackets) wv
		return wv
	endif
	return $""
End

/// @brief Search for the occurence of pattern in string
///
/// @returns number of occurences
Function CountSubstrings(string str, string pattern)

	variable i        = -1
	variable position = -1

	do
		i        += 1
		position += 1
		position  = strsearch(str, pattern, position)
	while(position != -1)

	return i
End

/// @brief Parses a simple unit with prefix into its prefix and unit.
///
/// Note: The currently allowed units are the SI base units [1] and other common derived units.
/// And in accordance to SI definitions, "kg" is a *base* unit.
///
/// @param[in]  unitWithPrefix string to parse, examples are "ms" or "kHz"
/// @param[out] prefix         symbol of decimal multipler of the unit,
///                            see below or [1] chapter 3 for the full list
/// @param[out] numPrefix      numerical value of the decimal multiplier
/// @param[out] unit           unit
threadsafe Function ParseUnit(string unitWithPrefix, string &prefix, variable &numPrefix, string &unit)

	string expr, unitInt, prefixInt

	prefix    = ""
	numPrefix = NaN
	unit      = ""

	ASSERT_TS(!isEmpty(unitWithPrefix), "empty unit")

	expr = "^(Y|Z|E|P|T|G|M|k|h|d|c|m|mu|μ|n|p|f|a|z|y)?[[:space:]]*(m|kg|s|A|K|mol|cd|Hz|V|N|W|J|F|Ω|a.u.)$"

	SplitString/E=(expr) unitWithPrefix, prefixInt, unitInt
	ASSERT_TS(V_flag >= 1, "Could not parse unit string")
	ASSERT_TS(!IsEmpty(unitInt), "Could not find a unit")

	prefix    = prefixInt
	numPrefix = GetDecimalMultiplierValue(prefix)
	unit      = unitInt
End

/// @brief Return the numerical value of a SI decimal multiplier
///
/// @see ParseUnit
threadsafe Function GetDecimalMultiplierValue(string prefix)

	if(isEmpty(prefix))
		return 1
	endif

	WAVE/T prefixes = ListToTextWave(PREFIX_SHORT_LIST, ";")
	WAVE/D values   = ListToNumericWave(PREFIX_VALUE_LIST, ";")

	FindValue/Z/TXOP=(1 + 4)/TEXT=(prefix) prefixes
	ASSERT_TS(V_Value != -1, "Could not find prefix")

	ASSERT_TS(DimSize(prefixes, ROWS) == DimSize(values, ROWS), "prefixes and values wave sizes must match")
	return values[V_Value]
End

Function/S ReplaceWordInString(string word, string str, string replacement)

	ASSERT(!IsEmpty(word), "Empty word")

	if(!cmpstr(word, replacement, 0))
		return str
	endif

	return ReplaceRegexInString("\\b\\Q" + word + "\\E\\b", str, replacement)
End

/// @brief Replaces all occurences of the regular expression `regex` in `str` with `replacement`
Function/S ReplaceRegexInString(string regex, string str, string replacement)

	variable ret
	string result, prefix, suffix

	result = str

	for(;;)
		[ret, prefix, suffix] = SearchRegexInString(result, regex)

		if(!ret)
			break
		endif

		result = prefix + replacement + suffix
	endfor

	return result
End

/// @brief Normalize the line endings in the given string to either classic Mac OS/Igor Pro EOLs (`\r`)
///        or Unix EOLs (`\n`)
///
/// UTF_NOINSTRUMENTATION
threadsafe Function/S NormalizeToEOL(string str, string eol)

	str = ReplaceString("\r\n", str, eol)

	if(!cmpstr(eol, "\r"))
		str = ReplaceString("\n", str, eol)
	elseif(!cmpstr(eol, "\n"))
		str = ReplaceString("\r", str, eol)
	else
		FATAL_ERROR("unsupported EOL character")
	endif

	return str
End

/// @brief Elide the given string to the requested length
Function/S ElideText(string str, variable returnLength)

	variable length, totalLength, i, first, suffixLength
	string ch, suffix

	totalLength = strlen(str)

	ASSERT(IsInteger(returnLength), "Invalid return length")

	if(totalLength <= returnLength)
		return str
	endif

	suffix       = "..."
	suffixLength = strlen(suffix)

	ASSERT(returnLength > suffixLength, "Invalid return length")

	first = returnLength - suffixLength - 1

	for(i = first; i > 0; i -= 1)
		ch = str[i]
		if(GrepString(ch, "^[[:space:]]$"))
			return str[0, i - 1] + suffix
		endif
	endfor

	// could not find any whitespace
	// just cut it off
	return str[0, first] + suffix
End

/// From DisplayHelpTopic "Character-by-Character Operations"
/// @brief Returns the number of bytes in the UTF-8 character that starts byteOffset
///        bytes from the start of str.
///        NOTE: If byteOffset is invalid this routine returns 0.
///              Also, if str is not valid UTF-8 text, this routine return 1.
Function NumBytesInUTF8Character(string str, variable byteOffset)

	variable firstByte
	variable numBytesInString = strlen(str)

	ASSERT(byteOffset >= 0 || byteOffset < numBytesInString, "Invalid byte offset")

	firstByte = char2num(str[byteOffset]) & 0x00FF

	if(firstByte < 0x80)
		return 1
	endif

	if(firstByte >= 0xC2 && firstByte <= 0xDF)
		return 2
	endif

	if(firstByte >= 0xE0 && firstByte <= 0xEF)
		return 3
	endif

	if(firstByte >= 0xF0 && firstByte <= 0xF4)
		return 4
	endif

	// If we are here, str is not valid UTF-8. Treat the first byte as a 1-byte character.
	return 1
End

/// From DisplayHelpTopic "Character-by-Character Operations"
/// @brief Returns the number of UTF8 characters in a string
Function UTF8CharactersInString(string str)

	variable numCharacters, byteOffset, numBytesInCharacter
	variable length = strlen(str)

	do
		if(byteOffset >= length)
			break
		endif
		numBytesInCharacter = NumBytesInUTF8Character(str, byteOffset)
		ASSERT(numBytesInCharacter > 0, "Bug in CharactersInUTF8String")
		numCharacters += 1
		byteOffset    += numBytesInCharacter
	while(1)

	return numCharacters
End

/// From DisplayHelpTopic "Character-by-Character Operations"
/// @brief Returns the UTF8 characters in a string at position charPos
Function/S UTF8CharacterAtPosition(string str, variable charPos)

	variable length, byteOffset, numBytesInCharacter

	if(charPos < 0)
		return ""
	endif

	length = strlen(str)
	do
		if(byteOffset >= length)
			return ""
		endif
		if(charPos == 0)
			break
		endif
		numBytesInCharacter = NumBytesInUTF8Character(str, byteOffset)
		byteOffset         += numBytesInCharacter
		charPos            -= 1
	while(1)

	numBytesInCharacter = NumBytesInUTF8Character(str, byteOffset)
	return str[byteOffset, byteOffset + numBytesInCharacter - 1]
End

/// @brief Upper case the first character in an ASCII string
threadsafe Function/S UpperCaseFirstChar(string str)

	variable len

	len = strlen(str)

	if(len == 0)
		return str
	endif

	return UpperStr(str[0]) + str[1, len - 1]
End

/// @brief Human readable name for possible return values of WaveType(wv, 0)
///
/// We don't do any error checking if the given type really exists.
threadsafe Function/S WaveTypeToStringSelectorZero(variable type)

	string result = ""
	variable trim

	if(type == IGOR_TYPE_TEXT_WREF_DFR)
		return "non-numeric (text, wave ref, dfref)"
	endif

	if(type & IGOR_TYPE_COMPLEX)
		result += "complex "
	endif

	if(type & IGOR_TYPE_32BIT_FLOAT)
		result += "32-bit float"
	elseif(type & IGOR_TYPE_64BIT_FLOAT)
		result += "64-bit float"
	elseif(type & IGOR_TYPE_8BIT_INT)
		result += "8-bit int"
	elseif(type & IGOR_TYPE_16BIT_INT)
		result += "16-bit int"
	elseif(type & IGOR_TYPE_32BIT_INT)
		result += "32-bit int"
	elseif(type & IGOR_TYPE_64BIT_INT)
		result += "64-bit int"
	else
		// do nothing here
		trim = 1
	endif

	if(type & IGOR_TYPE_UNSIGNED)
		result += " unsigned"
	endif

	if(trim)
		return trimstring(result)
	endif

	return result
End

/// @brief Human readable name for possible return values of WaveType(wv, 1)
threadsafe Function/S WaveTypeToStringSelectorOne(variable type)

	switch(type)
		case IGOR_TYPE_NULL_WAVE:
			return "null"
		case IGOR_TYPE_NUMERIC_WAVE:
			return "numeric"
		case IGOR_TYPE_TEXT_WAVE:
			return "text"
		case IGOR_TYPE_DFREF_WAVE:
			return "datafolder reference"
		case IGOR_TYPE_WAVEREF_WAVE:
			return "wave reference"
		default:
			FATAL_ERROR("Unknown constant: " + num2str(type, "%d"))
	endswitch
End
