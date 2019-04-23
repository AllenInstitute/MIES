#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma IndependentModule=CompilationTester

/// @brief Load the contents of the given file into data
///
/// @param filePath absolute path to a text file
/// @param required [optional, defaults to false] decides if we abort on a
///                 failure to load the file (true) or return an empty string
Function/S LoadTextFile(filePath, [required])
	string filePath
	variable required

	variable refnum
	string data

	if(ParamIsDefault(required))
		required = 1
	else
		required = !!required
	endif

	Open/Z/R/P=home refnum as filePath

	if(V_flag) // error opening file
		if(required)
			Abort
		else
			return ""
		endif
	endif

	FStatus refnum
	data = PadString("", V_logEOF, 0)

	FBinRead/B=3 refnum, data
	Close refnum

	return data
End

/// @brief Returns the full path to a global variable
///
/// @param dfr           location of the global variable, must exist
/// @param globalVarName name of the global variable
/// @param initialValue  initial value of the variable. Will only be used if
///                      it is created. 0 by default.
static Function/S GetNVARAsString(dfr, globalVarName, [initialValue])
	dfref dfr
	string globalVarName
	variable initialValue

	NVAR/Z/SDFR=dfr var = $globalVarName
	if(!NVAR_Exists(var))
		variable/G dfr:$globalVarName

		NVAR/SDFR=dfr var = $globalVarName

		if(!ParamIsDefault(initialValue))
			var = initialValue
		endif
	endif

	return GetDataFolder(1, dfr) + globalVarName
End

/// @brief Return the compilation state variable
///
/// -NaN: Not initialized
/// -0x0: Initialization done
/// -0x1: input.txt could be read from disk and has contents
/// -0x2: Compilation was started
/// -0x4: Compilation was successfull
/// -0x8: Compilation was *not* successfull (Requires Igor Pro 7, build 30097)
Function/S GetCompilationState()

	DFREF dfr = root:
	return GetNVARAsString(dfr, "compilationState", initialValue=NaN)
End

/// @brief Return true if ProcGlobal is compiled, false if not
///
/// Observed behaviour:
/// - ProcGlobal is compiled after all independent modules
/// - FunctionInfo returns an empty string for a non existing function,
///   but an error message if ProcGlobal is not compiled
Function IsProcGlobalCompiled()

	string funcInfo = FunctionInfo("ProcGlobal#NON_EXISTING_FUNCTION")
	return !cmpstr(funcInfo, "")
End

/// @brief Returns one if str is empty or null, zero otherwise.
/// @param str must not be a SVAR
///
/// @hidecallgraph
/// @hidecallergraph
threadsafe Function IsEmpty(str)
	string& str

	variable len = strlen(str)
	return numtype(len) == 2 || len <= 0
End

/// @brief Normalize the line endings in the given string to either classic Mac OS/Igor Pro EOLs (`\r`)
///        or Unix EOLs (`\n`)
Function/S NormalizeToEOL(str, eol)
	string str, eol

	str = ReplaceString("\r\n", str, eol)

	if(!cmpstr(eol, "\r"))
		return ReplaceString("\n", str, eol)
	elseif(!cmpstr(eol, "\n"))
		return ReplaceString("\r", str, eol)
	else
		return str
	endif
End
