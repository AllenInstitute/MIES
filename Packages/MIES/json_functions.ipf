#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma IgorVersion=8.00

// This file describes the wrapper functions, mentioned in the API.

// If user creates the specific defines JSON_IGNORE_ERRORS or JSON_UNQUIET
// he can change the defaults for error handling (/Z flag) and output (/Q flag)
// Original defaults are /Z=0 and /Q=1
#ifdef JSON_IGNORE_ERRORS
static Constant JSON_ZFLAG_DEFAULT = 1
#else
static Constant JSON_ZFLAG_DEFAULT = 0
#endif

#ifdef JSON_UNQUIET
static Constant JSON_QFLAG_DEFAULT = 0
#else
static Constant JSON_QFLAG_DEFAULT = 1
#endif

/// @addtogroup JSON_TYPES
///@{
Constant JSON_INVALID   = -1
Constant JSON_OBJECT    = 0
Constant JSON_ARRAY     = 1
Constant JSON_NUMERIC   = 2
Constant JSON_STRING    = 3
Constant JSON_BOOL      = 4
Constant JSON_NULL      = 5
///@}

/// @addtogroup JSONXOP_Parse
///@{
/// @brief Parse a JSON string with the XOP
///
/// @param jsonStr    string representation of the JSON object
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a numeric identifier of the JSON object on success
Function JSON_Parse(jsonStr, [ignoreErr])
	String jsonStr
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_Parse/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT) jsonStr; AbortOnRTE
	if(V_flag)
		return NaN
	endif
	return V_Value
End
///@}

/// @addtogroup JSONXOP_Dump
///@{

/// @brief Dump a JSON id to its string representation
///
/// @param jsonID     numeric identifier of the main object
/// @param indent     [optional, default 0] number of white spaces for pretty output indentation.
//                    Use -1 for compact output.
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a string representation of the JSON object
Function/S JSON_Dump(jsonID, [indent, ignoreErr])
	Variable jsonID
	Variable indent, ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	indent = ParamIsDefault(indent) ? 0 : !!numtype(indent) ? -1 : round(indent)

	JSONXOP_Dump/IND=(indent)/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT) jsonID; AbortOnRTE
	if(V_flag)
		return ""
	endif
	return S_Value
End
///@}

/// @addtogroup JSONXOP_New
///@{
/// @brief register a new object
///
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a numeric identifier of the JSON object on success
Function JSON_New([ignoreErr])
	variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_New/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT); AbortOnRTE
	if(V_flag)
		return NaN
	endif
	return V_Value
End
///@}

/// @addtogroup JSONXOP_Release
///@{
/// @brief Release a JSON id from memory
///
/// @param jsonID     numeric identifier of the main object
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns 0 on success, NaN otherwise
Function JSON_Release(jsonID, [ignoreErr])
	Variable jsonID
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_Release/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT) jsonID; AbortOnRTE
	if(V_flag)
		return NaN
	endif
	return 0
End
///@}

/// @addtogroup JSONXOP_Remove
///@{
/// @brief Remove a path element from a JSON string representation
///
/// @param jsonID     numeric identifier of the main object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns 0 on success, NaN otherwise
Function JSON_Remove(jsonID, jsonPath [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_Remove/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT) jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return NaN
	endif
	return 0
End
///@}

/// @addtogroup JSONXOP_AddTree
///@{

/// @brief Recursively add new objects to the tree
///
/// Non-existing path elements are recursively created.
/// @see JSON_AddTreeArray JSON_OBJECT
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns 0 on success
Function JSON_AddTreeObject(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	return JSON_AddTree(jsonID, jsonPath, JSON_OBJECT, ignoreErr)
End

/// @brief Recursively add a new array to the tree.
///
/// Non-existing path elements are created as objects.
/// @see JSON_AddTreeObject JSON_ARRAY
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_AddTreeArray(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	return JSON_AddTree(jsonID, jsonPath, JSON_ARRAY, ignoreErr)
End

static Function JSON_AddTree(jsonID, jsonPath, type, ignoreErr)
	Variable jsonID
	String jsonPath
	Variable type, ignoreErr

	JSONXOP_AddTree/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/T=(type) jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return NaN
	endif
	return 0
End

///@}
/// @addtogroup JSONXOP_GetKeys
///@{
/// @brief Get the name of all object members of the specified path
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @param esc        [optional, 0 or 1] set to ignore RFC 6901 path escaping standards
/// @returns a free text wave with all elements as rows.
Function/WAVE JSON_GetKeys(jsonID, jsonPath, [esc, ignoreErr])
	Variable jsonID
	String jsonPath
	Variable esc, ignoreErr
	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	Make/FREE/N=0/T result
	if(ParamIsDefault(esc))
		JSONXOP_GetKeys/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT) jsonID, jsonPath, result; AbortOnRTE
	else
		esc = !!esc
		JSONXOP_GetKeys/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/ESC=(esc) jsonID, jsonPath, result; AbortOnRTE
	endif
	if(V_flag)
		return $""
	endif
	return result
End
///@}

///@}
/// @addtogroup JSONXOP_GetType
///@{
/// @brief get the JSON Type for an element at the given path.
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a numeric value representing one of the defined @see JSON_TYPES
Function JSON_GetType(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr
	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	JSONXOP_GetType/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT) jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return JSON_INVALID
	endif
	return V_Value
End
///@}

/// @addtogroup JSONXOP_GetArraySize
///@{
/// @brief Get the number of elements in an array.
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a numeric variable with the number of elements the array at jsonPath
Function JSON_GetArraySize(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_GetArraySize/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT) jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return NaN
	endif
	return V_Value
End
///@}

/// @addtogroup JSONXOP_GetMaxArraySize
///@{
/// @brief Get the maximum element size for each dimension in an array
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a free numeric wave with the size for each dimension as rows
Function/WAVE JSON_GetMaxArraySize(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr
	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	Make/FREE/N=0 w
	JSONXOP_GetMaxArraySize/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT) jsonID, jsonPath, w; AbortOnRTE
	if(V_flag)
		return $""
	endif
	return w
End
///@}

/// @addtogroup JSONXOP_GetValue
///@{

/// @brief Get a text entity as string variable from a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a string containing the entity
Function/S JSON_GetString(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : ignoreErr
	JSONXOP_GetValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/T jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return ""
	endif

	return S_Value
End

/// @brief Get a numeric, boolean or null entity as variable from a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a numeric variable containing the entity
Function JSON_GetVariable(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : ignoreErr
	JSONXOP_GetValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/V jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return NaN
	endif

	return V_Value
End

/// @brief Get an array as text wave from a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a free text wave with the elements of the array
Function/WAVE JSON_GetTextWave(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : ignoreErr
	Make/FREE/T/N=0 wv
	JSONXOP_GetValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/TWAV=wv jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return $""
	endif

	return wv
End

/// @brief Get an array as numeric wave from a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a free numeric double precision wave with the elements of the array
Function/WAVE JSON_GetWave(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : ignoreErr
	Make/FREE/D/N=0 wv
	JSONXOP_GetValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/WAVE=wv jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return $""
	endif

	return wv
End

/// @brief Get a 64bit integer from a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a 64bit variable
Function [Int64 result] JSON_GetInt64(Variable jsonID, String jsonPath, [Variable ignoreErr])

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : ignoreErr
	Make/FREE/L/N=1 wv
	JSONXOP_GetValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/L=wv jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		result = 0
		return [result]
	endif

	result = wv[0]
	return [result]
End

/// @brief Get an unsigned 64bit integer from a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns an unsigned 64bit variable
Function [UInt64 result] JSON_GetUInt64(Variable jsonID, String jsonPath, [Variable ignoreErr])

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : ignoreErr
	Make/FREE/L/U/N=1 wv
	JSONXOP_GetValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/L=wv jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		result = 0
		return [result]
	endif

	result = wv[0]
	return [result]
End

///@}

/// @addtogroup JSONXOP_AddValue
///@{

/// @brief Add a string entity to a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param value      string value to add
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_AddString(jsonID, jsonPath, value, [ignoreErr])
	Variable jsonID
	String jsonPath
	String value
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/T=(value) jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return NaN
	endif

	return 0
End

/// @brief Add a numeric entity to a JSON object
///
/// @param jsonID        numeric identifier of the JSON object
/// @param jsonPath      RFC 6901 compliant JSON Pointer
/// @param value         numeric value to add
/// @param significance  [optional] number of digits after the decimal sign
/// @param ignoreErr     [optional, default 0] set to ignore runtime errors
Function JSON_AddVariable(jsonID, jsonPath, value, [significance, ignoreErr])
	Variable jsonID
	String jsonPath
	Variable value
	Variable significance
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	if(trunc(value) == value && !numtype(value))
		JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/I=(value) jsonID, jsonPath; AbortOnRTE
	elseif(ParamIsDefault(significance))
		JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/V=(value) jsonID, jsonPath; AbortOnRTE
	else
		JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/V=(value)/S=(significance) jsonID, jsonPath; AbortOnRTE
	endif
	if(V_flag)
		return NaN
	endif

	return 0
End

/// @brief Add a `null` entity to a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_AddNull(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/N jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return NaN
	endif

	return 0
End

/// @brief Add a numeric value as boolean to a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param value      boolean value to add
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_AddBoolean(jsonID, jsonPath, value, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable value
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	if(!!numtype(value))
		JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/N jsonID, jsonPath; AbortOnRTE
	else
		JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/B=(!!value) jsonID, jsonPath; AbortOnRTE
	endif
	if(V_flag)
		return NaN
	endif

	return 0
End

/// @brief Add a WAVE as array entity to a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param wv         WAVE reference to the wave to add
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_AddWave(jsonID, jsonPath, wv, [ignoreErr])
	Variable jsonID
	String jsonPath
	WAVE wv
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/WAVE=wv jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return NaN
	endif

	return 0
End

/// @brief Add a 64bit integer to a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param value      int64 value to add
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_AddInt64(jsonID, jsonPath, value, [ignoreErr])
	Variable jsonID
	String jsonPath
	Int64 value
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	Make/FREE/L/N=1 w
	w = value
	return AddValueI64(jsonID, jsonPath, w, ignoreErr)
End

/// @brief Add an unsigned 64bit integer to a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param value      uint64 value to add
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_AddUInt64(jsonID, jsonPath, value, [ignoreErr])
	Variable jsonID
	String jsonPath
	UInt64 value
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	Make/FREE/L/U/N=1 w
	w = value
	return AddValueI64(jsonID, jsonPath, w, ignoreErr)
End

static Function AddValueI64(jsonID, jsonPath, w, ignoreErr)
	Variable jsonID
	String jsonPath
	WAVE w
	Variable ignoreErr

	JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/L=w jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return NaN
	endif

	return 0
End

/// @brief Add a specified number of objects to a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param objCount   [optional, default 1] number of objects
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_AddObjects(jsonID, jsonPath, [objCount, ignoreErr])
	Variable jsonID
	String jsonPath
	Variable objCount, ignoreErr

	objCount = ParamIsDefault(objCount) ? 1 : objCount
	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/OBJ=(objCount) jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return NaN
	endif

	return 0
End

/// @brief Merge a JSON object to another object
///
/// @param jsonID     numeric identifier of the main object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param jsonID2    numeric identifier of the merged object
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_AddJSON(jsonID, jsonPath, jsonID2, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable jsonID2
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/JOIN=(jsonID2) jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return NaN
	endif

	return 0
End

/// @brief Replace with a string entity at the given location in a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param value      new string value
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_SetString(jsonID, jsonPath, value, [ignoreErr])
	Variable jsonID
	String jsonPath
	String value
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/O/T=(value) jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return NaN
	endif

	return 0
End

/// @brief Replace with a numeric entity at the given location in a JSON object
///
/// @param jsonID        numeric identifier of the JSON object
/// @param jsonPath      RFC 6901 compliant JSON Pointer
/// @param value         new numeric value
/// @param significance  [optional] number of digits after the decimal sign
/// @param ignoreErr     [optional, default 0] set to ignore runtime errors
Function JSON_SetVariable(jsonID, jsonPath, value, [significance, ignoreErr])
	Variable jsonID
	String jsonPath
	Variable value
	Variable significance
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	if(trunc(value) == value)
		JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/O/I=(value) jsonID, jsonPath; AbortOnRTE
	elseif(ParamIsDefault(significance))
		JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/O/V=(value) jsonID, jsonPath; AbortOnRTE
	else
		JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/O/V=(value)/S=(significance) jsonID, jsonPath; AbortOnRTE
	endif
	if(V_flag)
		return NaN
	endif

	return 0
End

/// @brief Replace with a `null` entity at the given location in a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_SetNull(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/O/N jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return NaN
	endif

	return 0
End

/// @brief Replace with a boolean value at the given location in a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param value      new boolean value
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_SetBoolean(jsonID, jsonPath, value, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable value
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	if(!!numtype(value))
		JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/O/N jsonID, jsonPath; AbortOnRTE
	else
		JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/O/B=(!!value) jsonID, jsonPath; AbortOnRTE
	endif
	if(V_flag)
		return NaN
	endif

	return 0
End

/// @brief Replace with a WAVE as array entity at the given location in a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param wv         WAVE reference to the new wave
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_SetWave(jsonID, jsonPath, wv, [ignoreErr])
	Variable jsonID
	String jsonPath
	WAVE wv
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/O/WAVE=wv jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return NaN
	endif

	return 0
End

/// @brief Replace with a 64bit integer at the given location in a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param value      new int64 value
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_SetInt64(jsonID, jsonPath, value, [ignoreErr])
	Variable jsonID
	String jsonPath
	Int64 value
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	Make/FREE/L/N=1 w
	w = value
	return SetValueI64(jsonID, jsonPath, w, ignoreErr)
End

/// @brief Replace with an unsigned 64bit integer at the given location in a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param value      new uint64 value
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_SetUInt64(jsonID, jsonPath, value, [ignoreErr])
	Variable jsonID
	String jsonPath
	UInt64 value
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	Make/FREE/L/U/N=1 w
	w = value
	return SetValueI64(jsonID, jsonPath, w, ignoreErr)
End

static Function SetValueI64(jsonID, jsonPath, w, ignoreErr)
	Variable jsonID
	String jsonPath
	WAVE w
	Variable ignoreErr

	JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/O/L=w jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return NaN
	endif

	return 0
End

/// @brief Replace with a specified number of objects at the giveln location in a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param objCount   [optional, default 1] number of objects
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_SetObjects(jsonID, jsonPath, [objCount, ignoreErr])
	Variable jsonID
	String jsonPath
	Variable objCount, ignoreErr

	objCount = ParamIsDefault(objCount) ? 1 : objCount
	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/O/OBJ=(objCount) jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return NaN
	endif

	return 0
End

/// @brief Replace an entity with the given JSON object at the specified location in the main object
///
/// @param jsonID     numeric identifier of the main object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param jsonID2    numeric identifier of the merged object
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_SetJSON(jsonID, jsonPath, jsonID2, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable jsonID2
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	JSONXOP_AddValue/Z=(ignoreErr)/Q=(JSON_QFLAG_DEFAULT)/O/JOIN=(jsonID2) jsonID, jsonPath; AbortOnRTE
	if(V_flag)
		return NaN
	endif

	return 0
End

///@}

static Function JSON_KVPairsToJSON(jsonID, jsonPath, str, ignoreErr)
	variable jsonID, ignoreErr
	string jsonPath, str

	variable i, pos, numEntries
	string value, key, entry

	numEntries = ItemsInList(str)
	for(i = 0; i < numEntries; i += 1)
		entry = StringFromList(i, str)
		pos = strsearch(entry, ":", 0)
		AbortOnValue pos == -1, 1
		key = entry[0, pos - 1]
		value  = entry[pos + 1, inf]
		JSON_AddString(jsonID, LowerStr(jsonPath + key), value, ignoreErr = ignoreErr)
	endfor
End

/// @addtogroup JSON_GetIgorInfo
/// @{

/// @brief Return JSON with Igor information
///
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function JSON_GetIgorInfo([ignoreErr])
	variable ignoreErr

	variable jsonID

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	jsonID = JSON_New(ignoreErr = ignoreErr)

	JSON_AddTreeObject(jsonID, "igorpro", ignoreErr = ignoreErr)
	JSON_KVPairsToJSON(jsonID, "igorpro/", IgorInfo(0), ignoreErr)

	JSON_AddTreeObject(jsonID, "operatingsystem", ignoreErr = ignoreErr)
	JSON_KVPairsToJSON(jsonID, "operatingsystem/", IgorInfo(3), ignoreErr)

	return jsonID
End

/// @}

/// @addtogroup JSONXOP_Version
/// @{

/// @brief Output version information useful for issue reports
///
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
Function/S JSON_Version([ignoreErr])
	variable ignoreErr

	variable jsonID, jsonID2
	string rep

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_Version/Z
	jsonID2 = JSON_Parse(S_Value, ignoreErr = ignoreErr)

	jsonID = JSON_GetIgorInfo(ignoreErr = ignoreErr)
	JSON_AddJSON(jsonID, "/XOP", jsonID2, ignoreErr=ignoreErr)
	JSONXOP_Release/Z=(ignoreErr) jsonID2

	rep = JSON_Dump(jsonID, indent = 2, ignoreErr = ignoreErr)
	JSONXOP_Release/Z=(ignoreErr) jsonID

	if(!strlen(GetRTStackInfo(2)))
		print/LEN=2500 rep
	endif

	return rep
End

/// @}

/// @brief check if the given jsonID is valid
Function JSON_Exists(jsonID, jsonPath)
	Variable jsonID
	String jsonPath

	Variable jsonType, err

	try
		jsonType = JSON_GetType(jsonID, jsonPath); AbortOnRTE
	catch
		err = GetRTError(1)
		jsonType = -1
	endtry

	return jsonType != -1
End
