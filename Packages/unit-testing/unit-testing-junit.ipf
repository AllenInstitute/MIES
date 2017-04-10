#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma version=1.06

// Licensed under 3-Clause BSD, see License.txt

Structure strTestSuite
	// exported attributes, * = requires, XML type
	string package // *xs:token
	variable id // *xs:int
	string name // *xs:token
	string timestamp // *xs:dateTime
	string hostname // *xs:token
	variable tests // *xs:int
	variable failures // *xs:int
	variable errors // *xs:int
	variable skipped // xs:int
	variable disabled // xs:int
	variable timeTaken // *xs:decimal
	string systemErr // pre-string with preserved whitespaces
	string systemOut // pre-string with preserved whitespaces
	// for internal use
	variable timeStart
EndStructure

Structure strSuiteProperties
	string propNameList // xs:token, min length 1
	string propValueList // xs:string
EndStructure

Structure strTestCase
	string name // *xs:token
	string className // *xs:token
	variable timeTaken // *xs:decimal
	variable assertions // xs:int
	string status // xs:int
	string message // xs:string
	string type // *xs-string
	string systemErr // pre-string with preserved whitespaces
	string systemOut // pre-string with preserved whitespaces
	// for internal use
	variable timeStart
	variable error_count
	string history
	// 0 ok, 1 failure, 2 error, 3 skipped
	variable testResult
EndStructure

#if (IgorVersion() >= 7.0)
#else
/// trimstring function for Igor 6
Function/S trimstring(str)
	string str

	variable s, e
	s = -1
	do
		s += 1
	while(!cmpstr(" ", str[s]) || !cmpstr("\t", str[s]) || !cmpstr("\r", str[s]) || !cmpstr("\n", str[s]))
	e = strlen(str)
	do
		e -= 1
	while(!cmpstr(" ", str[e]) || !cmpstr("\t", str[e]) || !cmpstr("\r", str[e]) || !cmpstr("\n", str[e]))
	return (str[s, e])
End
#endif

/// XML properties
/// New Line is \n
/// The xs:int signed 32 bit Integer
/// The xs:decimal generic fp with max. 18 digits, exponential or scientific notation not supported.
/// The xs:string data type can contain characters, line feeds, carriage returns, and tab characters, needs also entity escapes.
/// The xs:token data type also contains characters, but the XML processor will remove
/// line feeds, carriage returns, tabs, leading and trailing spaces, and multiple spaces.
/// it is a subtype of xs:string, entity escapes apply here
/// XML: Reduces a string to a xs:token
Function/S JU_ToXMLToken(str)
	string str
	variable i

	str = ReplaceString("\n", str, "")
	str = ReplaceString("\r", str, "")
	str = ReplaceString("\t", str, "")
#if (IgorVersion() >= 7.0)
	return (TrimString(str, 1))
#else
	for(i = 0; strsearch(str, "  ", 0) >= 0;)
		str = ReplaceString("  ", str, " ")
	endfor
	return (TrimString(str))
#endif
End

/// entity references
/// &lt; 	< 	less than
/// &gt; 	> 	greater than
/// &amp; 	& 	ampersand
/// &apos; 	' 	apostrophe
/// &quot; 	" 	quotation mark
/// XML: Escape Entity Replacer for strings
Function/S JU_ToXMLCharacters(str)
	string str

	str = ReplaceString("&", str, "&amp;")
	str = ReplaceString("<", str, "&lt;")
	str = ReplaceString(">", str, "&gt;")
	str = ReplaceString("'", str, "&apos;")
	str = ReplaceString("\"", str, "&quot;")

	return str
End

/// Returns the current TimeStamp in the form yyyy-mm-ddThh:mm:ssZ±hh:mm in UTC + time zone
Function/S JU_GetISO8601TimeStamp()
	variable timezone, utctime
	variable tzmin, tzhour
	string tz
	
	timezone = Date2Secs(-1,-1,-1)
	utctime = DateTime - timezone
	sprintf tz, "%+03d:%02d", trunc(timezone / 3600), abs(mod(timezone / 60, 60))
	return (Secs2Date(utctime, -2) + "T" + Secs2Time(utctime, 3) + "Z" + tz)
End

/// Evaluates last Test Case and returns JUNIT XML Output from Test Case
Function/S JU_CaseToOut(juTC)
	STRUCT strTestCase &juTC

	string sout, s

	juTC.name = JU_ToXMLToken( JU_ToXMLCharacters(juTC.name))
	juTC.classname = JU_ToXMLToken( JU_ToXMLCharacters(juTC.classname))
	juTC.message = JU_ToXMLCharacters(juTC.message)
	juTC.type = JU_ToXMLCharacters(juTC.type)

	sprintf sout, "\t\t<testcase name=\"%s\" classname=\"%s\" time=\"%.3f\">\n", juTC.name, juTC.classname, juTC.timeTaken
	s = ""
	switch(juTC.testResult)
		case 3:
			s = "\t\t\t<skipped/>\n"
			break
		case 1:
			sprintf s, "\t\t\t<failure message=\"%s\" type=\"%s\"></failure>\n", juTC.message, juTC.type
			break
		case 2:
			sprintf s, "\t\t\t<error message=\"%s\" type=\"%s\"></error>\n", juTC.message, juTC.type
			break
		default:
			break
	endswitch
	sout += s

	if(strlen(juTC.systemOut))
		juTC.systemOut = JU_ToXMLCharacters(juTC.systemOut)
		sprintf s, "\t\t\t<system-out>%s</system-out>\n", juTC.systemOut
		sout += s
	endif
	if(strlen(juTC.systemErr))
		juTC.systemErr = JU_ToXMLCharacters(juTC.systemErr)
		sprintf s, "\t\t\t<system-err>%s</system-err>\n", juTC.systemErr
		sout += s
	endif

	return (sout + "\t\t</testcase>\n")
End

/// Adds a JUNIT Test Suite property to the list of properties for current Suite
Function JU_AddTSProp(juTSProp, propName, propValue)
	STRUCT strSuiteProperties &juTSProp
	string propName
	string propValue

	if(strlen(propName))
		propName = JU_ToXMLToken( JU_ToXMLCharacters(propName))
		propValue = JU_ToXMLCharacters(propValue)
		juTSProp.propNameList = AddListItem(propName, juTSProp.propNameList, "<")
		juTSProp.propValueList = AddListItem(propValue, juTSProp.propValueList, "<")
	endif
End

/// Returns combined JUNIT XML Output for TestSuite consisting of all TestCases run in Suite
Function/S JU_CaseListToSuiteOut(juTestCaseListOut, juTS, juTSProp)
	string juTestCaseListOut
	STRUCT strTestSuite &juTS
	STRUCT strSuiteProperties &juTSProp

	string propName, propValue
	string sout, sformat, s
	variable i, numEntries

	juTS.hostname = JU_ToXMLToken( JU_ToXMLCharacters(juTS.hostname))
	juTS.name = JU_ToXMLToken( JU_ToXMLCharacters(juTS.name))
	juTS.package = JU_ToXMLToken( JU_ToXMLCharacters(juTS.package))

	sformat = "\t<testsuite package=\"%s\" id=\"%d\" name=\"%s\" timestamp=\"%s\" hostname=\"%s\" tests=\"%d\" failures=\"%d\" errors=\"%d\" skipped=\"%d\" disabled=\"%d\" time=\"%.3f\">\n"
	sprintf sout, sformat, juTS.package, juTS.id, juTS.name, juTS.timestamp, juTS.hostname, juTS.tests, juTS.failures, juTS.errors, juTS.skipped, juTS.disabled, juTS.timeTaken

	if(ItemsInList(juTSProp.propNameList, "<"))
		sout += "\t\t<properties>\n"

		numEntries = ItemsInList(juTSProp.propNameList, "<")
		for(i = 0; i < numEntries; i += 1)
			propName = StringFromList(i, juTSProp.propNameList, "<")
			propValue = StringFromList(i, juTSProp.propValueList, "<")
			sprintf s, "\t\t\t<property name=\"%s\" value=\"%s\"/>\n", propName, propValue
			sout += s
		endfor
		sout += "\t\t</properties>\n"
	endif

	sout += juTestCaseListOut

	if(strlen(juTS.systemOut))
		juTS.systemOut = JU_ToXMLCharacters(juTS.systemOut)
		sprintf s, "\t\t<system-out>%s</system-out>\n", juTS.systemOut
		sout += s
	endif
	if(strlen(juTS.systemErr))
		juTS.systemErr = JU_ToXMLCharacters(juTS.systemErr)
		sprintf s, "\t\t<system-err>%s</system-err>\n", juTS.systemErr
		sout += s
	endif

	return (sout + "\t</testsuite>\n")
End

/// Replaces all chars >= 0x80 by "?" in str and returns the resulting string
Function/S JU_UTF8Filter(str)
	string str

	string sret
	variable i,len

	sret = ""
	len = strlen(str)
	for(i = 0;i < len; i += 1)
		if(char2num(str[i]) < 0)
			sret += "?"
		else
			sret += str[i]
		endif
	endfor
	return sret
End

/// Writes JUNIT XML output to juFileName
Function JU_WriteOutput(enableJU, juTestSuitesOut, juFileName)
	variable enableJU
	string juTestSuitesOut
	string juFileName

	variable fnum
	string sout

	if(!enableJU)
		return NaN
	endif

	sout = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<testsuites>\n"
	sout += juTestSuitesOut
	sout += "</testsuites>\n"
#if (IgorVersion() >= 7.0)
// UTF-8 support
#else
	sout = JU_UTF8Filter(sout)
#endif
	PathInfo home
	juFileName = getUnusedFileName(S_path + juFileName)
	if(!strlen(juFileName))
		printf "Error: Unable to determine unused file name for JUNIT output in path %s !", S_path
		return NaN
	endif
	
	open/Z/P=home fnum as juFileName
	if(!V_flag)
		fBinWrite fnum, sout
		close fnum
	else
		PathInfo home
		printf "Error: Could not create JUNIT output file at %s\r", S_path + juFileName
	endif
End

/// Prepares JUNIT Test Suite structure for a new Test Suite
Function JU_TestSuiteBegin(enableJU, juTS, juTSProp, procWin, testCaseList, name, testSuiteNum)
	variable enableJU
	STRUCT strTestSuite &juTS
	STRUCT strSuiteProperties &juTSProp
	string procWin
	string testCaseList
	string name
	variable testSuiteNum

	if(!enableJU)
		return NaN
	endif
	juTS.package = procWin
	juTS.id = testSuiteNum
	juTS.name = name
	juTS.timestamp = JU_GetISO8601TimeStamp()
	juTS.hostname = "localhost"
	juTS.tests = ItemsInList(testCaseList)
	juTS.timeStart = DateTime
	juTS.failures = 0
	juTS.errors = 0
	juTS.skipped = 0
	juTS.disabled = 0
	juTS.systemOut = ""
	juTS.systemErr = ""
	juTSProp.propNameList = ""
	juTSProp.propValueList = ""
	JU_AddTSProp(juTSProp, "IgorInfo", IgorInfo(0))
	JU_AddTSProp(juTSProp, "Experiment", IgorInfo(1))
	JU_AddTSProp(juTSProp, "System", IgorInfo(3))
#if (IgorVersion() >= 7.00)
	strswitch(IgorInfo(2))
		case "Windows":
			juTS.hostname = GetEnvironmentVariable("COMPUTERNAME")
			break
		case "Macintosh":
			juTS.hostname = GetEnvironmentVariable("HOSTNAME")
			break
		default:
			break
	endswitch
	JU_AddTSProp(juTSProp, "User", IgorInfo(7))
#endif
End

/// Prepares JUNIT Test Case structure for a new Test Case
Function JU_TestCaseBegin(enableJU, juTC, funcName, fullfuncName, procWin)
	variable enableJU
	STRUCT strTestCase &juTC
	string funcName
	string fullfuncName
	string procWin

	NVAR/SDFR=GetPackageFolder() error_count

	if(!enableJU)
		return NaN
	endif
	juTC.name = funcName + " in " + procWin
	juTC.className = fullfuncName
	juTC.timeStart = DateTime
	juTC.error_count = error_count
	Notebook HistoryCarbonCopy, getData = 1
	juTC.history = S_Value
	juTC.message = ""
	juTC.type = ""
	juTC.systemOut = ""
	juTC.systemErr = ""
End

/// Evaluate status of previously run Test Case and returns XML output from TestCase
Function/S JU_TestCaseEnd(enableJU, juTS, juTC, funcName, procWin)
	variable enableJU
	STRUCT strTestSuite &juTS
	STRUCT strTestCase &juTC
	string funcName, procWin

	dfref dfr = GetPackageFolder()
	NVAR/SDFR=dfr error_count
	NVAR/SDFR=dfr assert_count
	SVAR/SDFR=dfr message
	SVAR/SDFR=dfr type
	SVAR/SDFR=dfr systemErr

	if(!enableJU)
		return ""
	endif
	juTC.timeTaken = DateTime - juTC.timeStart
	juTC.error_count = error_count - juTC.error_count
	// skip code 3, disabled code 4 is currently not implemented
	if(shouldDoAbort())
		juTC.testResult = 2
		juTS.errors += 1
	else
		juTC.testResult = (juTC.error_count != 0)
		juTS.failures += (juTC.error_count != 0)
	endif
	if(juTC.testResult)
		juTC.message = message
		juTC.type = type
	else
		if(!assert_count)
			juTC.systemOut += "No Assertions found in Test Case " + funcName + ", procedure file " + procWin + "\r"
		endif
	endif
	Notebook HistoryCarbonCopy, getData = 1
	juTC.systemOut += S_Value[strlen(juTC.history), Inf]
	juTS.systemOut += juTC.systemOut
	juTC.systemErr += systemErr
	juTS.systemErr += systemErr
	return JU_CaseToOut(juTC)
End

/// return XML output for TestSuite
Function/S JU_TestSuiteEnd(enableJU, juTS, juTSProp, juTestCaseListOut)
	variable enableJU
	STRUCT strTestSuite &juTS
	STRUCT strSuiteProperties &juTSProp
	string juTestCaseListOut

	if(!enableJU)
		return ""
	endif
	juTS.timeTaken = DateTime - juTS.timeStart
	return JU_CaseListToSuiteOut(juTestCaseListOut, juTS, juTSProp)
End
