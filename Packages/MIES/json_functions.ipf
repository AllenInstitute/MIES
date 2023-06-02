#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma IgorVersion=8.00

// This file describes the wrapper functions, mentioned in the API.

// Error constants for JSON XOP
Constant JSON_OLD_IGOR = 10001
Constant JSON_UNHANDLED_CPP_EXCEPTION = 10002
Constant JSON_CPP_EXCEPTION = 10003
Constant JSON_ERR_ASSERT = 10004
Constant JSON_ERR_CONVERT = 10012
Constant JSON_ERR_INVALID_TYPE = 10011

// Invalid JSON id.
Constant JSON_ERR_INVALID_ID = 10005

// Could not create object in path.
Constant JSON_ERR_INVALID_PATH = 10006

// Exactly one input value of either type /A /B /I /N /T or /V must be specified.
Constant JSON_ERR_NONE_MULTIPLE_INPUT = 10007

// JSON member object already exists
Constant JSON_ERR_OBJECT_EXISTS = 10008

// Error when parsing string to JSON
Constant JSON_ERR_PARSE = 10009

// Dumping JSON to string failed (This may happen if a string in a JSON value is not UTF8 encoded).
Constant JSON_ERR_DUMP = 10010

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
/// @{
Constant JSON_INVALID   = -1
Constant JSON_OBJECT    = 0
Constant JSON_ARRAY     = 1
Constant JSON_NUMERIC   = 2
Constant JSON_STRING    = 3
Constant JSON_BOOL      = 4
Constant JSON_NULL      = 5
/// @}

/// @addtogroup JSON_SYNC_OPTIONS
/// @{
// if element in source exists, but not in target, then add element in target
Constant JSON_SYNC_ADD_TO_TARGET = 0x0
// if element in target exists, but not in source, then remove element in target
Constant JSON_SYNC_REMOVE_IN_TARGET = 0x1
// if element in source exists and in target, then overwrite element in target
Constant JSON_SYNC_OVERWRITE_IN_TARGET = 0x2
/// @}

static Constant IGOR_STRING_MAX_SIZE = 2147483647

/// @addtogroup JSONXOP_Parse
/// @{
/// @brief Parse a JSON string with the XOP
///
/// @param jsonStr    string representation of the JSON object
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a numeric identifier of the JSON object on success
threadsafe Function JSON_Parse(jsonStr, [ignoreErr])
	String jsonStr
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_Parse/Z=1/Q=(JSON_QFLAG_DEFAULT) jsonStr
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return V_Value
End
/// @}

/// @addtogroup JSONXOP_Dump
/// @{

/// @brief Dump a JSON id to its string representation
///
/// @param jsonID     numeric identifier of the main object
/// @param indent     [optional, default 0] number of white spaces for pretty output indentation.
//                    Use -1 for compact output.
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a string representation of the JSON object
threadsafe Function/S JSON_Dump(jsonID, [indent, ignoreErr])
	Variable jsonID
	Variable indent, ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	indent = ParamIsDefault(indent) ? 0 : !!numtype(indent) ? -1 : round(indent)

	JSONXOP_Dump/IND=(indent)/Z=1/Q=(JSON_QFLAG_DEFAULT) jsonID
	if(V_flag)
		if(ignoreErr)
			return ""
		endif

		AbortOnValue 1, V_flag
	endif

	return S_Value
End
/// @}

/// @addtogroup JSONXOP_New
/// @{
/// @brief register a new object
///
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a numeric identifier of the JSON object on success
threadsafe Function JSON_New([ignoreErr])
	variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_New/Z=1/Q=(JSON_QFLAG_DEFAULT)
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return V_Value
End
/// @}

/// @addtogroup JSONXOP_Release
/// @{
/// @brief Release a JSON id from memory
///
/// @param jsonID     numeric identifier of the main object
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns 0 on success, NaN otherwise
threadsafe Function JSON_Release(jsonID, [ignoreErr])
	Variable jsonID
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_Release/Z=1/Q=(JSON_QFLAG_DEFAULT) jsonID
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End
/// @}

/// @addtogroup JSONXOP_Remove
/// @{
/// @brief Remove a path element from a JSON string representation
///
/// @param jsonID     numeric identifier of the main object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns 0 on success, NaN otherwise
threadsafe Function JSON_Remove(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_Remove/Z=1/Q=(JSON_QFLAG_DEFAULT) jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End
/// @}

/// @addtogroup JSONXOP_AddTree
/// @{

/// @brief Recursively add new objects to the tree
///
/// Non-existing path elements are recursively created.
/// @see JSON_AddTreeArray JSON_OBJECT
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns 0 on success
threadsafe Function JSON_AddTreeObject(jsonID, jsonPath, [ignoreErr])
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
threadsafe Function JSON_AddTreeArray(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	return JSON_AddTree(jsonID, jsonPath, JSON_ARRAY, ignoreErr)
End

threadsafe static Function JSON_AddTree(jsonID, jsonPath, type, ignoreErr)
	Variable jsonID
	String jsonPath
	Variable type, ignoreErr

	JSONXOP_AddTree/Z=1/Q=(JSON_QFLAG_DEFAULT)/T=(type) jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End

/// @}
/// @addtogroup JSONXOP_GetKeys
/// @{
/// @brief Get the name of all object members of the specified path
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @param esc        [optional, 0 or 1] set to ignore RFC 6901 path escaping standards
/// @returns a free text wave with all elements as rows.
threadsafe Function/WAVE JSON_GetKeys(jsonID, jsonPath, [esc, ignoreErr])
	Variable jsonID
	String jsonPath
	Variable esc, ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	if(ParamIsDefault(esc))
		JSONXOP_GetKeys/Z=1/Q=(JSON_QFLAG_DEFAULT)/FREE jsonID, jsonPath, result
	else
		esc = !!esc
		JSONXOP_GetKeys/Z=1/Q=(JSON_QFLAG_DEFAULT)/ESC=(esc)/FREE jsonID, jsonPath, result
	endif

	if(V_flag)
		if(ignoreErr)
			return $""
		endif

		AbortOnValue 1, V_flag
	endif

	return result
End
/// @}

/// @addtogroup JSONXOP_GetType
/// @{
/// @brief get the JSON Type for an element at the given path.
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a numeric value representing one of the defined @see JSON_TYPES
threadsafe Function JSON_GetType(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_GetType/Z=1/Q=(JSON_QFLAG_DEFAULT) jsonID, jsonPath

	if(V_flag)
		if(ignoreErr)
			return JSON_INVALID
		endif

		AbortOnValue 1, V_flag
	endif

	return V_Value
End
/// @}

/// @addtogroup JSONXOP_GetArraySize
/// @{
/// @brief Get the number of elements in an array.
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a numeric variable with the number of elements the array at jsonPath
threadsafe Function JSON_GetArraySize(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_GetArraySize/Z=1/Q=(JSON_QFLAG_DEFAULT) jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return V_Value
End
/// @}

/// @addtogroup JSONXOP_GetMaxArraySize
/// @{
/// @brief Get the maximum element size for each dimension in an array
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a free numeric wave with the size for each dimension as rows
threadsafe Function/WAVE JSON_GetMaxArraySize(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_GetMaxArraySize/Z=1/Q=(JSON_QFLAG_DEFAULT)/FREE jsonID, jsonPath, w
	if(V_flag)
		if(ignoreErr)
			return $""
		endif

		AbortOnValue 1, V_flag
	endif

	return w
End
/// @}

/// @addtogroup JSONXOP_GetValue
/// @{

/// @brief Get new JSON object from a json path of an existing JSON object.
///        The original jsonID is not freed and stays valid.
///        The new jsonID contains a copy of the JSON object referenced by jsonpath in the existing jsonID.
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a new jsonID containing a copy of the JSON object referenced by jsonpath in jsonID
threadsafe Function JSON_GetJSON(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : ignoreErr

	JSONXOP_GetValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/J jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return V_Value
End

/// @brief Get a text entity as string variable from a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a string containing the entity
threadsafe Function/S JSON_GetString(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : ignoreErr

	JSONXOP_GetValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/T jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return ""
		endif

		AbortOnValue 1, V_flag
	endif

	return S_Value
End

/// @brief Get a numeric, boolean or null entity as variable from a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a numeric variable containing the entity
threadsafe Function JSON_GetVariable(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : ignoreErr

	JSONXOP_GetValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/V jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return V_Value
End

/// @brief Get an array as text wave from a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a free text wave with the elements of the array
threadsafe Function/WAVE JSON_GetTextWave(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : ignoreErr

	JSONXOP_GetValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/TWAV=wv/FREE jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return $""
		endif

		AbortOnValue 1, V_flag
	endif

	return wv
End

/// @brief Get an array as numeric wave from a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a free numeric double precision wave with the elements of the array
threadsafe Function/WAVE JSON_GetWave(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : ignoreErr

	JSONXOP_GetValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/WAVE=wv/FREE jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return $""
		endif

		AbortOnValue 1, V_flag
	endif

	return wv
End

/// @brief Get a 64bit integer from a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
/// @returns a 64bit variable
threadsafe Function [Int64 result] JSON_GetInt64(Variable jsonID, String jsonPath, [Variable ignoreErr])

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : ignoreErr

	Make/FREE/L/N=1 wv
	JSONXOP_GetValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/L=wv/FREE jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			result = 0
			return [result]
		endif

		AbortOnValue 1, V_flag
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
threadsafe Function [UInt64 result] JSON_GetUInt64(Variable jsonID, String jsonPath, [Variable ignoreErr])

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : ignoreErr

	Make/FREE/L/U/N=1 wv
	JSONXOP_GetValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/L=wv/FREE jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			result = 0
			return [result]
		endif

		AbortOnValue 1, V_flag
	endif

	result = wv[0]
	return [result]
End

/// @}

/// @addtogroup JSONXOP_AddValue
/// @{

/// @brief Add a string entity to a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param value      string value to add
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
threadsafe Function JSON_AddString(jsonID, jsonPath, value, [ignoreErr])
	Variable jsonID
	String jsonPath
	String value
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/T=(value) jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
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
threadsafe Function JSON_AddVariable(jsonID, jsonPath, value, [significance, ignoreErr])
	Variable jsonID
	String jsonPath
	Variable value
	Variable significance
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	if(trunc(value) == value && !numtype(value))
		JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/I=(value) jsonID, jsonPath
	elseif(ParamIsDefault(significance))
		JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/V=(value) jsonID, jsonPath
	else
		JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/V=(value)/S=(significance) jsonID, jsonPath
	endif
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End

/// @brief Add a `null` entity to a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
threadsafe Function JSON_AddNull(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/N jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End

/// @brief Add a numeric value as boolean to a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param value      boolean value to add
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
threadsafe Function JSON_AddBoolean(jsonID, jsonPath, value, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable value
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	if(!!numtype(value))
		JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/N jsonID, jsonPath
	else
		JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/B=(!!value) jsonID, jsonPath
	endif
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End

/// @brief Add a WAVE as array entity to a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param wv         WAVE reference to the wave to add
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
threadsafe Function JSON_AddWave(jsonID, jsonPath, wv, [ignoreErr])
	Variable jsonID
	String jsonPath
	WAVE wv
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/WAVE=wv jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End

/// @brief Add a 64bit integer to a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param value      int64 value to add
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
threadsafe Function JSON_AddInt64(jsonID, jsonPath, value, [ignoreErr])
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
threadsafe Function JSON_AddUInt64(jsonID, jsonPath, value, [ignoreErr])
	Variable jsonID
	String jsonPath
	UInt64 value
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	Make/FREE/L/U/N=1 w
	w = value
	return AddValueI64(jsonID, jsonPath, w, ignoreErr)
End

threadsafe static Function AddValueI64(jsonID, jsonPath, w, ignoreErr)
	Variable jsonID
	String jsonPath
	WAVE w
	Variable ignoreErr

	JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/L=w jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End

/// @brief Add a specified number of objects to a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param objCount   [optional, default 1] number of objects
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
threadsafe Function JSON_AddObjects(jsonID, jsonPath, [objCount, ignoreErr])
	Variable jsonID
	String jsonPath
	Variable objCount, ignoreErr

	objCount = ParamIsDefault(objCount) ? 1 : objCount
	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/OBJ=(objCount) jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End

/// @brief Merge a JSON object to another object
///
/// @param jsonID     numeric identifier of the main object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param jsonID2    numeric identifier of the merged object, the merged JSON object is NOT freed by JSON_AddJSON. The caller keeps ownership of it.
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
threadsafe Function JSON_AddJSON(jsonID, jsonPath, jsonID2, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable jsonID2
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/JOIN=(jsonID2) jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End

/// @brief Replace with a string entity at the given location in a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param value      new string value
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
threadsafe Function JSON_SetString(jsonID, jsonPath, value, [ignoreErr])
	Variable jsonID
	String jsonPath
	String value
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/O/T=(value) jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
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
threadsafe Function JSON_SetVariable(jsonID, jsonPath, value, [significance, ignoreErr])
	Variable jsonID
	String jsonPath
	Variable value
	Variable significance
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	if(trunc(value) == value && !numtype(value))
		JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/O/I=(value) jsonID, jsonPath
	elseif(ParamIsDefault(significance))
		JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/O/V=(value) jsonID, jsonPath
	else
		JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/O/V=(value)/S=(significance) jsonID, jsonPath
	endif
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End

/// @brief Replace with a `null` entity at the given location in a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
threadsafe Function JSON_SetNull(jsonID, jsonPath, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/O/N jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End

/// @brief Replace with a boolean value at the given location in a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param value      new boolean value
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
threadsafe Function JSON_SetBoolean(jsonID, jsonPath, value, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable value
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	if(!!numtype(value))
		JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/O/N jsonID, jsonPath
	else
		JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/O/B=(!!value) jsonID, jsonPath
	endif
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End

/// @brief Replace with a WAVE as array entity at the given location in a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param wv         WAVE reference to the new wave
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
threadsafe Function JSON_SetWave(jsonID, jsonPath, wv, [ignoreErr])
	Variable jsonID
	String jsonPath
	WAVE wv
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/O/WAVE=wv jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End

/// @brief Replace with a 64bit integer at the given location in a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param value      new int64 value
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
threadsafe Function JSON_SetInt64(jsonID, jsonPath, value, [ignoreErr])
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
threadsafe Function JSON_SetUInt64(jsonID, jsonPath, value, [ignoreErr])
	Variable jsonID
	String jsonPath
	UInt64 value
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr
	Make/FREE/L/U/N=1 w
	w = value
	return SetValueI64(jsonID, jsonPath, w, ignoreErr)
End

threadsafe static Function SetValueI64(jsonID, jsonPath, w, ignoreErr)
	Variable jsonID
	String jsonPath
	WAVE w
	Variable ignoreErr

	JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/O/L=w jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End

/// @brief Replace with a specified number of objects at the giveln location in a JSON object
///
/// @param jsonID     numeric identifier of the JSON object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param objCount   [optional, default 1] number of objects
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
threadsafe Function JSON_SetObjects(jsonID, jsonPath, [objCount, ignoreErr])
	Variable jsonID
	String jsonPath
	Variable objCount, ignoreErr

	objCount = ParamIsDefault(objCount) ? 1 : objCount
	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/O/OBJ=(objCount) jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End

/// @brief Replace an entity with the given JSON object at the specified location in the main object
///
/// @param jsonID     numeric identifier of the main object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @param jsonID2    numeric identifier of the merged object
/// @param ignoreErr  [optional, default 0] set to ignore runtime errors
threadsafe Function JSON_SetJSON(jsonID, jsonPath, jsonID2, [ignoreErr])
	Variable jsonID
	String jsonPath
	Variable jsonID2
	Variable ignoreErr

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	JSONXOP_AddValue/Z=1/Q=(JSON_QFLAG_DEFAULT)/O/JOIN=(jsonID2) jsonID, jsonPath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	return 0
End

/// @}

threadsafe static Function JSON_KVPairsToJSON(jsonID, jsonPath, str, ignoreErr)
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
threadsafe Function JSON_GetIgorInfo([ignoreErr])
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

/// @addtogroup JSONXOP_Exists
/// @{

/// @brief Check if the jsonID/jsonPath is valid
///
/// @param jsonID     numeric identifier of the main object
/// @param jsonPath   RFC 6901 compliant JSON Pointer
/// @returns 1 if object at jsonPath exists in JSON object, 0 otherwise
threadsafe Function JSON_Exists(jsonID, jsonPath)
	Variable jsonID
	String jsonPath

	return JSON_GetType(jsonID, jsonPath, ignoreErr = 1) != JSON_INVALID
End

/// @}

/// @addtogroup JSONXOP_Options
/// @{

/// @brief Disables quiet mode
Function JSON_DisableQuietMode()
	Execute/P/Q "SetIgorOption poundDefine=JSON_UNQUIET"
	Execute/P/Q "COMPILEPROCEDURES "
End

/// @brief Enables quiet mode
Function JSON_EnableQuietMode()
	Execute/P/Q "SetIgorOption poundUnDefine=JSON_UNQUIET"
	Execute/P/Q "COMPILEPROCEDURES "
End

/// @brief Sets the ignore errors define for the json wrapper functions
Function JSON_SetIgnoreErrors()
	Execute/P/Q "SetIgorOption poundDefine=JSON_IGNORE_ERRORS"
	Execute/P/Q "COMPILEPROCEDURES "
End

/// @brief Undefines the ignore errors define for the json wrapper functions
Function JSON_UnsetIgnoreErrors()
	Execute/P/Q "SetIgorOption poundUnDefine=JSON_IGNORE_ERRORS"
	Execute/P/Q "COMPILEPROCEDURES "
End

/// @}

/// @addtogroup JSON_SyncJSON
/// @{

/// @brief Syncs data from a source json into a target json.
///
/// @param[in] srcJsonId    json Id of source object
/// @param[in] tgtJsonId    json Id of target object
/// @param[in] srcPath root path for sync in source
/// @param[in] tgtPath root path for sync in target
/// @param[in] syncOptions  defines how source-target differences are handled by the synchronisation @sa JSON_SYNC_OPTIONS
/// @param[in] ignoreErr    [optional, default 0] set to ignore runtime errors
threadsafe Function JSON_SyncJSON(variable srcJsonId, variable tgtJsonId, string srcPath, string tgtPath, variable syncOptions, [variable ignoreErr])

	variable srcExists, tgtExists, srcType, tgtType, arraySize
	variable valSrc, valTgt
	variable i, size
	string strSrc, strTgt

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	if(!(syncOptions >= 0 && syncOptions <= JSON_SYNC_ADD_TO_TARGET | JSON_SYNC_REMOVE_IN_TARGET | JSON_SYNC_OVERWRITE_IN_TARGET) || \
		numtype(strlen(srcPath)) == 2 || \
		numtype(strlen(tgtPath)) == 2)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, 1
	endif

	srcExists = JSON_Exists(srcJsonId, srcPath)
	tgtExists = JSON_Exists(tgtJsonId, tgtPath)
	if(srcExists && !tgtExists)
		JSON_AddArrayElementToParentIfArray(tgtJsonId, tgtPath)
		JSON_CopyJSON(srcJsonId, tgtJsonId, srcPath, tgtPath)
		return 0
	elseif(!srcExists && !tgtExists)
		return 0
	elseif(!srcExists && tgtExists)
		if(syncOptions & JSON_SYNC_REMOVE_IN_TARGET)
			JSON_Remove(tgtJsonId, tgtPath)
		endif
		return 0
	endif

	srcType = JSON_GetType(srcJsonId, srcPath)
	tgtType = JSON_GetType(tgtJsonId, tgtPath)
	if(srcType != tgtType)
		if(syncOptions & JSON_SYNC_OVERWRITE_IN_TARGET)
			JSON_CopyJSON(srcJsonId, tgtJsonId, srcPath, tgtPath)
		endif
		return 0
	endif

	switch(srcType)
		case JSON_OBJECT:
			WAVE/T srcKeys = JSON_GetKeys(srcJsonId, srcPath)
			size = DimSize(srcKeys, 0)
			for(i = 0; i < size; i += 1)
				JSON_SyncJSON(srcJsonId, tgtJsonId, srcPath + "/" + srcKeys[i], tgtPath + "/" + srcKeys[i], syncOptions, ignoreErr=ignoreErr)
			endfor

			if(syncOptions & JSON_SYNC_REMOVE_IN_TARGET)
				WAVE/T tgtKeys = JSON_GetKeys(tgtJsonId, tgtPath)
				size = DimSize(tgtKeys, 0)
				for(i = 0; i < size; i += 1)
					JSON_SyncJSON(srcJsonId, tgtJsonId, srcPath + "/" + tgtKeys[i], tgtPath + "/" + tgtKeys[i], syncOptions, ignoreErr=ignoreErr)
				endfor
			endif

			break
		case JSON_ARRAY:
			arraySize = max(JSON_GetArraySize(srcJsonId, srcPath), JSON_GetArraySize(tgtJsonId, tgtPath))
			for(i = 0; i < arraySize; i += 1)
				JSON_SyncJSON(srcJsonId, tgtJsonId, srcPath + "/" + num2istr(i), tgtPath + "/" + num2istr(i), syncOptions, ignoreErr=ignoreErr)
			endfor

			break
		case JSON_STRING:
			if(syncOptions & JSON_SYNC_OVERWRITE_IN_TARGET)
				strSrc = JSON_GetString(srcJsonId, srcPath)
				strTgt = JSON_GetString(tgtJsonId, tgtPath)
				if(CmpStr(strSrc, strTgt, 1))
					JSON_CopyJSON(srcJsonId, tgtJsonId, srcPath, tgtPath)
				endif
			endif
			break
		case JSON_NUMERIC: // fallthrough-by-design
		case JSON_BOOL:
			if(syncOptions & JSON_SYNC_OVERWRITE_IN_TARGET)
				valSrc = JSON_GetVariable(srcJsonId, srcPath)
				valTgt = JSON_GetVariable(tgtJsonId, tgtPath)
				if(valSrc != valTgt)
					JSON_CopyJSON(srcJsonId, tgtJsonId, srcPath, tgtPath)
				endif
			endif
			break
		case JSON_NULL:
			return 0
			break
		case JSON_INVALID: // fallthrough-by-design
		default:
			if(ignoreErr)
				return NaN
			endif

			AbortOnValue 1, 1
	endswitch

	return 0
End

/// @}

threadsafe static Function JSON_AddArrayElementToParentIfArray(variable jsonId, string jsonPath)

	string parentPath = jsonPath[0, strsearch(jsonPath, "/", Inf, 1) - 1]
	if(JSON_GetType(jsonId, parentPath) == JSON_ARRAY)
		JSON_AddNull(jsonId, parentPath)
	endif
End

threadsafe static Function JSON_CopyJSON(variable srcJsonId, variable tgtJsonId, string srcPath, string tgtPath)

	variable jsonTmp

	jsonTmp = JSON_GetJSON(srcJsonId, srcPath)
	JSON_SetJSON(tgtJsonId, tgtPath, jsonTmp)
	JSON_Release(jsonTmp)
End

/// @addtogroup JSON_LoadSave
/// @{

/// @brief Loads a text file and parses it to JSON, then returns jsonId
///
/// @param[in] fullFilepath full file path of the text file
/// @param[in] ignoreErr    [optional, default 0] set to ignore runtime errors
/// @returns jsonId of the parsed text data or NaN if unsuccessful
threadsafe Function JSON_Load(string fullFilepath, [variable ignoreErr])

	variable fNum
	string data

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	if(numtype(strlen(fullFilePath)) == 2)
		if(ignoreErr)
			return NaN
		endif
		AbortOnValue 1, 1
	endif

	Open/R/Z fNum as fullFilepath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	FStatus fNum
	if(numtype(V_logEOF) == 2 || V_logEOF > IGOR_STRING_MAX_SIZE)
		Close fNum
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, 1
	endif
	if(V_logEOF == 0)
		Close fNum
		return NaN
	endif

	data = PadString("", V_logEOF, 0x20)
	FBinRead fnum, data
	Close fNum

	return JSON_Parse(data, ignoreErr=ignoreErr)
End

/// @brief Saves a JSON to a text file. If the target file exists it is overwritten.
///
/// @param[in] jsonId       jsonId of the json data to save
/// @param[in] fullFilepath full file path of a file to be written
/// @param[in] ignoreErr    [optional, default 0] set to ignore runtime errors
/// @returns 0 if the save was successful or NaN if there was an error
threadsafe Function JSON_Save(variable jsonId, string fullFilepath, [variable ignoreErr])

	variable fNum
	string data

	ignoreErr = ParamIsDefault(ignoreErr) ? JSON_ZFLAG_DEFAULT : !!ignoreErr

	data = JSON_Dump(jsonId, ignoreErr=ignoreErr)
	if(!(strlen(data) > 0) && ignoreErr)
		return NaN
	endif

	Open/Z fNum as fullFilepath
	if(V_flag)
		if(ignoreErr)
			return NaN
		endif

		AbortOnValue 1, V_flag
	endif

	FBinWrite fnum, data
	Close fNum

	return 0
End

/// @}
