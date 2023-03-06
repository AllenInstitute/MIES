#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_JSONWAVENOTE
#endif

/// @name Constants used in the wave note JSON support
/// @anchor WaveNoteJSONSupportConstants
/// @{
static StrConstant WAVE_NOTE_JSON_SEPARATOR = "\rJSON_BEGIN\r"
static StrConstant WAVE_NOTE_EMPTY_JSON = "{}"
/// @}

/// @brief Gets the JSON wave note part as string
threadsafe Function/S JWN_GetWaveNoteAsString(WAVE wv)

	variable pos, len
	string noteStr

	ASSERT_TS(WaveExists(wv), "Missing wave")
	noteStr = note(wv)
	pos = strsearch(noteStr, WAVE_NOTE_JSON_SEPARATOR, 0)
	len = strlen(WAVE_NOTE_JSON_SEPARATOR)
	if(pos >= 0 && strlen(noteStr) > pos + len)
		return noteStr[pos + len, Inf]
	endif

	return WAVE_NOTE_EMPTY_JSON
End

/// @brief Gets the JSON wave note part as JSON object
///        The caller is responsible to release the returned jsonId after use.
threadsafe Function JWN_GetWaveNoteAsJSON(WAVE wv)

	ASSERT_TS(WaveExists(wv), "Missing wave")

	return JSON_Parse(JWN_GetWaveNoteAsString(wv))
End

/// @brief Set the JSON json document as JSON wave note. Releases json.
threadsafe Function JWN_SetWaveNoteFromJSON(WAVE wv, variable jsonID)

	ASSERT_TS(WaveExists(wv), "Missing wave")

	JWN_WriteWaveNote(wv, JWN_GetWaveNoteHeader(wv), jsonID)
End

/// @brief Return the numerical value at jsonPath found in the wave note
///
/// @param wv       wave reference where the WaveNote is taken from
/// @param jsonPath path to string
///
/// @returns the value on success. NaN is returned if it could not be found
threadsafe Function JWN_GetNumberFromWaveNote(WAVE wv, string jsonPath)

	variable jsonID, val

	ASSERT_TS(WaveExists(wv), "Missing wave")

	jsonID = JWN_GetWaveNoteAsJSON(wv)
	val = JSON_GetVariable(jsonID, jsonPath, ignoreErr = 1)
	JSON_Release(jsonID)

	return val
End

/// @brief Return the numeric wave value at jsonPath found in the wave note
///        Note that for numeric waves the data type of the returned wave
///        is double precision.
///
/// @param wv       wave reference where the WaveNote is taken from
/// @param jsonPath path to string
///
/// @returns the wave on success. null wave is returned if it could not be found
threadsafe Function/WAVE JWN_GetNumericWaveFromWaveNote(WAVE wv, string jsonPath)

	variable jsonID

	ASSERT_TS(WaveExists(wv), "Missing wave")

	jsonID = JWN_GetWaveNoteAsJSON(wv)
	WAVE/Z noteWave = JSON_GetWave(jsonID, jsonPath, ignoreErr = 1)
	JSON_Release(jsonID)

	return noteWave
End

/// @brief Return the text wave value at jsonPath found in the wave note
///
/// @param wv       wave reference where the WaveNote is taken from
/// @param jsonPath path to string
///
/// @returns the wave on success. null wave is returned if it could not be found
threadsafe Function/WAVE JWN_GetTextWaveFromWaveNote(WAVE wv, string jsonPath)

	variable jsonID

	ASSERT_TS(WaveExists(wv), "Missing wave")

	jsonID = JWN_GetWaveNoteAsJSON(wv)
	WAVE/T/Z textWave = JSON_GetTextWave(jsonID, jsonPath, ignoreErr = 1)
	JSON_Release(jsonID)

	return textWave
End

/// @brief Return the string value at jsonPath found in the wave note
///
/// @param wv       wave reference where the WaveNote is taken from
/// @param jsonPath path to string
///
/// @returns the value on success. An empty string is returned if it could not be found
threadsafe Function/S JWN_GetStringFromWaveNote(WAVE wv, string jsonPath)

	variable jsonID
	string str

	ASSERT_TS(!IsEmpty(jsonPath), "Empty jsonPath")

	jsonID = JWN_GetWaveNoteAsJSON(wv)
	str = JSON_GetString(jsonID, jsonPath, ignoreErr = 1)
	JSON_Release(jsonID)

	return str
End

/// @brief Gets the non-JSON wave note part
threadsafe Function/S JWN_GetWaveNoteHeader(WAVE/Z wv)

	ASSERT_TS(WaveExists(wv), "Missing wave")
	return StringFromList(0, note(wv), WAVE_NOTE_JSON_SEPARATOR)
End

/// @brief Writes a wave note from header string and json back. Releases json.
threadsafe static Function JWN_WriteWaveNote(WAVE wv, string header, variable jsonID)

	ASSERT_TS(WaveExists(wv), "Missing wave")
	Note/K wv, header + WAVE_NOTE_JSON_SEPARATOR + JSON_Dump(jsonID)
	JSON_Release(jsonID)
End

/// @brief Updates the numeric value of `key` found in the wave note as jsonPath
///
/// @param wv       wave
/// @param jsonPath path in json
/// @param val      new numerical value
threadsafe Function JWN_SetNumberInWaveNote(WAVE wv, string jsonPath, variable val)

	variable jsonID

	ASSERT_TS(WaveExists(wv), "Missing wave")
	ASSERT_TS(!IsEmpty(jsonPath), "Empty jsonPath")

	jsonID = JWN_GetWaveNoteAsJSON(wv)
	JSON_SetVariable(jsonID, jsonPath, val)
	JWN_WriteWaveNote(wv, JWN_GetWaveNoteHeader(wv), jsonID)
End

/// @brief Update the string value at jsonPath found in the wave note at jsonPath
///
/// @param wv       wave
/// @param jsonPath path in json
/// @param str      new string value
threadsafe Function JWN_SetStringInWaveNote(WAVE wv, string jsonPath, string str)

	variable jsonID

	ASSERT_TS(WaveExists(wv), "Missing wave")
	ASSERT_TS(!IsEmpty(jsonPath), "Empty jsonPath")

	jsonID = JWN_GetWaveNoteAsJSON(wv)
	JSON_SetString(jsonID, jsonPath, str)
	JWN_WriteWaveNote(wv, JWN_GetWaveNoteHeader(wv), jsonID)
End

/// @brief Update the wave value at jsonPath found in the wave note at jsonPath
///        Note that only wave data and dimensions are stored.
///
/// @param wv       wave
/// @param jsonPath path in json
/// @param noteWave new wave value
threadsafe Function JWN_SetWaveInWaveNote(WAVE wv, string jsonPath, WAVE noteWave)

	variable jsonID

	ASSERT_TS(WaveExists(wv), "Missing wave")
	ASSERT_TS(!IsEmpty(jsonPath), "Empty jsonPath")
	ASSERT_TS(IsNumericWave(noteWave) || IsTextWave(noteWave), "Only numeric and text waves are supported as JSON wave note entry.")

	jsonID = JWN_GetWaveNoteAsJSON(wv)
	JSON_SetWave(jsonID, jsonPath, noteWave)
	JWN_WriteWaveNote(wv, JWN_GetWaveNoteHeader(wv), jsonID)
End
