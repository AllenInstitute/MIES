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
