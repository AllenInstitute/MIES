#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file TJ_MIES_GlobalStringAndVariableAccess.ipf
///
/// @brief Helper functions for accessing global variables and strings.
///
/// The functions GetNVARAsString and GetSVARAsString are static as they should
/// not be used directly.
///
/// Instead if you have a global variable named `iceCreamCounter` in `root:myfood` you
/// would write in this file here a function like
///@code
///Function/S GetIceCreamCounterAsVariable()
///	return GetNVARAsString(createDFWithAllParents("root:myfood"), "iceCreamCounter")
///End
///@endcode
/// and then use it in your code as
///@code
///Function doStuff()
///	NVAR iceCreamCounter = $GetIceCreamCounterAsVariable()
///
///	iceCreamCounter += 1
///End
///@endcode

/// @brief Returns the full path to a global variable
///
/// @param dfr           location of the global variable, must exist
/// @param globalVarName name of the global variable
/// @param initialValue  initial value of the variable. Will only be used if
/// 					 it is created. 0 by default.
static Function/S GetNVARAsString(dfr, globalVarName, [initialValue])
	dfref dfr
	string globalVarName
	variable initialValue

	ASSERT(DataFolderExistsDFR(dfr), "Missing dfr")

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

/// @brief Returns the full path to a global string
///
/// @param dfr           location of the global string, must exist
/// @param globalStrName name of the global string
/// @param initialValue  initial value of the string. Will only be used if
/// 					 it is created. null by default.
static Function/S GetSVARAsString(dfr, globalStrName, [initialValue])
	dfref dfr
	string globalStrName
	string initialValue

	ASSERT(DataFolderExistsDFR(dfr), "Missing dfr")

	SVAR/Z/SDFR=dfr str = $globalStrName
	if(!SVAR_Exists(str))
		String/G dfr:$globalStrName

		SVAR/SDFR=dfr str = $globalStrName

		if(!ParamIsDefault(initialValue))
			str = initialValue
		endif
	endif

	return GetDataFolder(1, dfr) + globalStrName
End

/// @brief Returns the full path to the mies-igor version string. Creating it when necessary.
///
/// Never ever write this string!
Function/S GetMiesVersion()

	string path = GetSVARAsString(createDFWithAllParents(Path_MiesFolder("")), "version")
	SVAR str = $path

	if(!CmpStr(str,""))
		str = CreateMiesVersion()
	endif

	return path
End

/// @brief Return the version string for the mies-igor project
///
/// @returns the mies version (e.g. Release_0.3.0.0_20141007-3-gdf4bb1e-dirty) or "unknown version"
static Function/S CreateMiesVersion()

	string path, cmd, topDir, gitPath, version
	variable refNum

	// set path to the toplevel directory in the mies folder structure
	path = ParseFilePath(1, FunctionPath(""), ":", 1, 2)
	gitPath = "c:\\Program Files (x86)\\Git\\bin\\git.exe"
	GetFileFolderInfo/Z/Q gitPath
	if(!V_flag) // git is installed, try to regenerate version.txt
		topDir = ParseFilePath(5, path, "*", 0, 0)
		GetFileFolderInfo/Z/Q topDir + ".git"
		if(!V_flag) // topDir is a git repository
			sprintf cmd "\"%stools\\gitVersion.bat\"", topDir
			ExecuteScriptText/Z/B/W=5 cmd
			ASSERT(!V_flag, "We have git installed but could not regenerate version.txt")
		endif
	endif

	open/R/Z refNum as path + "version.txt"
	if(V_flag != 0)
		return "unknown version"
	endif

	FReadLine refNum, version
	Close refNum

	if(IsEmpty(version))
		return "unknown version"
	endif

	return version
End
