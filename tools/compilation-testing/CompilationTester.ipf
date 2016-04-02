#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IndependentModule=CompilationTester

/// @file CompilationTester.ipf
///
/// @brief Compilation Testing
///
/// How it works:
///  - Read the file `input.txt` and include the file given there.
///    This assumes that the procedure file to include is located in
///    the Igor Pro "User Procedure".
///  - Try to "Compile procedures"
///  - Write the result into the file compilationState.txt
///
/// File locations are the folder of the Igor experiment.

/// @brief Perform compilation testing
///
/// This function should be called by a Function named `run` without arguments in ProcGlobal.
/// See chapter 1.5 in the unit testing framework [documentation](../Manual-UnitTestingFramework-v1.03.pdf).
Function run()
	string includeFile

	NVAR compilationState = $GetCompilationState()
	compilationState = 0x0
	CompilationTester#WriteStateToDisk()

	LoadTextFile("input.txt", includeFile)
	includeFile = RemoveTrailingWhitespace(includeFile)
	if(!(strlen(includeFile) > 0))
		return NaN
	endif

	compilationState = 0x1
	CompilationTester#WriteStateToDisk()

	Execute/P "INSERTINCLUDE \"" + includeFile + "\""
	Execute/P "compilationState = 0x2"
	Execute/P "CompilationTester#WriteStateToDisk()"
	Execute/P "COMPILEPROCEDURES "
	Execute/P "compilationState = CompilationTester#IsProcGlobalCompiled() ? 0x4 : 0x8"
	Execute/P "CompilationTester#WriteStateToDisk()"
	Execute/P "DELETEINCLUDE \"" + includeFile + "\""
	Execute/P "COMPILEPROCEDURES "
End

/// @brief Removes all whitespace characters from the end of `str`
Function/S RemoveTrailingWhitespace(str)
	string str

	string contents

	SplitString/E=("(\\S*).*") str, contents
	AbortOnValue V_Flag != 1, 0

	return contents
End

/// @brief Load the contents of the given file into data
///
/// @param[in]  filePath absolute path to a text file
/// @param[out] data     holds the contents on return
Function LoadTextFile(filePath, data)
	string filePath
	string &data

	variable refnum

	Open/Z/R/P=home refnum as filePath
	AbortOnValue V_Flag, 1

	FStatus refnum
	data = ""
	data = PadString(data, V_logEOF, 0)

	FBinRead/B=3 refnum, data
	Close refnum
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
/// -0x8: Compilation was *not* successfull (usually not ecountered due to Igor Pro limitations)
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

/// @brief Write the `compilationState.txt` global variable to disc
Function WriteStateToDisk()
	variable refNum
	NVAR compilationState = $GetCompilationState()

	PathInfo home
	if(V_Flag == 0)
		Abort "Can not work with untitled experiments"
	endif

	Open/P=home/Z refNum as "compilationState.txt"
	if(V_Flag)
		Abort "Could not create compilation state file"
	endif

	fprintf refNum, "%d", compilationState
	Close refNum
End
