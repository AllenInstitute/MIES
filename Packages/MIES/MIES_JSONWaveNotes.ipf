#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_JSONWAVENOTE
#endif // AUTOMATED_TESTING

static Constant JWN_DEFAULT_RELEASE = 1

/// @brief Gets the JSON wave note part as string
threadsafe Function/S JWN_GetWaveNoteAsString(WAVE wv)

	variable pos, len
	string noteStr

	ASSERT_TS(WaveExists(wv), "Missing wave")
	noteStr = note(wv)
	pos     = strsearch(noteStr, WAVE_NOTE_JSON_SEPARATOR, 0)
	len     = strlen(WAVE_NOTE_JSON_SEPARATOR)
	if(pos >= 0 && strlen(noteStr) > (pos + len))
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

/// @brief Set the JSON json document as JSON wave note. Releases json if `release` is true (default).
threadsafe Function JWN_SetWaveNoteFromJSON(WAVE wv, variable jsonID, [variable release])

	ASSERT_TS(WaveExists(wv), "Missing wave")

	if(ParamIsDefault(release))
		release = JWN_DEFAULT_RELEASE
	else
		release = !!release
	endif

	JWN_WriteWaveNote(wv, JWN_GetWaveNoteHeader(wv), jsonID, release = release)
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
	val    = JSON_GetVariable(jsonID, jsonPath, ignoreErr = 1)
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
/// @returns the wave on success. null wave is returned if it could not be
///          found or the referenced entry contains non-numeric data
threadsafe Function/WAVE JWN_GetNumericWaveFromWaveNote(WAVE wv, string jsonPath)

	variable jsonID

	ASSERT_TS(WaveExists(wv), "Missing wave")

	jsonID = JWN_GetWaveNoteAsJSON(wv)
	WAVE/Z noteWave = JSON_GetWave(jsonID, jsonPath, waveMode = 1, ignoreErr = 1)
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
	WAVE/Z/T textWave = JSON_GetTextWave(jsonID, jsonPath, ignoreErr = 1)
	JSON_Release(jsonID)

	return textWave
End

/// @brief Return the wave reference wave at jsonPath found in the wave note
///
/// All contained waves must be numeric.
///
/// @param wv       wave reference where the WaveNote is taken from
/// @param jsonPath path to array
///
/// @returns the wave on success. null wave is returned if it could not be found
threadsafe Function/WAVE JWN_GetWaveRefNumericFromWaveNote(WAVE wv, string jsonPath)

	return JWN_GetWaveRefFromWaveNote_Impl(wv, jsonPath, IGOR_TYPE_NUMERIC_WAVE)
End

/// @brief Return the wave reference wave at jsonPath found in the wave note
///
/// All contained waves must be text.
///
/// @param wv       wave reference where the WaveNote is taken from
/// @param jsonPath path to array
///
/// @returns the wave on success. null wave is returned if it could not be found
threadsafe Function/WAVE JWN_GetWaveRefTextFromWaveNote(WAVE wv, string jsonPath)

	return JWN_GetWaveRefFromWaveNote_Impl(wv, jsonPath, IGOR_TYPE_TEXT_WAVE)
End

threadsafe static Function/WAVE JWN_GetWaveRefFromWaveNote_Impl(WAVE wv, string jsonPath, variable type)

	variable jsonID, numRows

	jsonID = JWN_GetWaveNoteAsJSON(wv)
	ASSERT_TS(JSON_GetType(jsonID, jsonPath, ignoreErr = 1) == JSON_ARRAY, "Expected array at jsonPath")
	WAVE/Z maxArraySizes = JSON_GetMaxArraySize(jsonID, jsonPath, ignoreErr = 1)
	ASSERT_TS(WaveExists(maxArraySizes), "Could not query array size")

	numRows = maxArraySizes[ROWS]
	if(numRows == 0)
		return $""
	endif

	Make/FREE/WAVE/N=(numRows) container

	switch(type)
		case IGOR_TYPE_NUMERIC_WAVE:
			container[] = JSON_GetWave(jsonID, jsonPath + "/" + num2str(p), ignoreErr = 1, waveMode = 1)
			break
		case IGOR_TYPE_TEXT_WAVE:
			container[] = JSON_GetTextWave(jsonID, jsonPath + "/" + num2str(p), ignoreErr = 1)
			break
		default:
			ASSERT_TS(0, "Invalid type")
	endswitch

	JSON_Release(jsonID)

	ASSERT_TS(IsNaN(GetRowIndex(container, refWave = $"")), "Encountered invalid waves in the container")

	return container
End

/// @brief Return the string value at jsonPath found in the wave note
///
/// @param wv       wave reference where the WaveNote is taken from
/// @param jsonPath path to string
///
/// @returns the value on success. An empty string is returned if it could not be found
threadsafe Function/S JWN_GetStringFromWaveNote(WAVE wv, string jsonPath)

	variable jsonID
	string   str

	ASSERT_TS(!IsEmpty(jsonPath), "Empty jsonPath")

	jsonID = JWN_GetWaveNoteAsJSON(wv)
	str    = JSON_GetString(jsonID, jsonPath, ignoreErr = 1)
	JSON_Release(jsonID)

	return str
End

/// @brief Gets the non-JSON wave note part
threadsafe Function/S JWN_GetWaveNoteHeader(WAVE/Z wv)

	ASSERT_TS(WaveExists(wv), "Missing wave")
	return StringFromList(0, note(wv), WAVE_NOTE_JSON_SEPARATOR)
End

/// @brief Writes a wave note from header string and json back. Releases json if `release` is true (default).
threadsafe static Function JWN_WriteWaveNote(WAVE wv, string header, variable jsonID, [variable release])

	if(ParamIsDefault(release))
		release = JWN_DEFAULT_RELEASE
	else
		release = !!release
	endif

	ASSERT_TS(WaveExists(wv), "Missing wave")
	Note/K wv, header + WAVE_NOTE_JSON_SEPARATOR + JSON_Dump(jsonID)

	if(release)
		JSON_Release(jsonID)
	endif
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

	variable jsonID, idx
	string jsonPathArray

	ASSERT_TS(WaveExists(wv), "Missing wave to attach JSON wave note")
	ASSERT_TS(WaveExists(noteWave), "Missing wave to add into the JSON wave note")

	ASSERT_TS(!IsEmpty(jsonPath), "Empty jsonPath")

	ASSERT_TS(IsWaveRefWave(noteWave) || IsNumericWave(noteWave) || IsTextWave(noteWave),                \
	          "Only wave references waves, numeric and text waves are supported as JSON wave note entry.")

	if(IsWaveRefWave(noteWave))
		ASSERT_TS(DimSize(noteWave, COLS) <= 1, "Expected only a 1D wave reference wave")

		// create an array at jsonPath with noteWave ROWS entries
		jsonID = JWN_GetWaveNoteAsJSON(wv)
		Make/FREE/N=(DimSize(noteWave, ROWS)) junk
		JSON_SetWave(jsonID, jsonPath, junk)
		JWN_WriteWaveNote(wv, JWN_GetWaveNoteHeader(wv), jsonID)

		WAVE/WAVE waveRef = noteWave

		for(WAVE/Z elem : waveRef)
			ASSERT_TS(WaveExists(elem), "Contained wave must exist")
			// and now write at each array index the contained wave
			jsonPathArray = jsonPath + "/" + num2str(idx)
			JWN_SetWaveInWaveNote(wv, jsonPathArray, elem)
			idx += 1
		endfor

		return NaN
	endif

	jsonID = JWN_GetWaveNoteAsJSON(wv)
	JSON_SetWave(jsonID, jsonPath, noteWave)
	JWN_WriteWaveNote(wv, JWN_GetWaveNoteHeader(wv), jsonID)
End

/// @brief Create a JSON object at the specified path
///
/// Non-existing path elements are recursively created.
///
/// @param wv       wave reference where the WaveNote is taken from
/// @param jsonPath path to create as object
threadsafe Function/WAVE JWN_CreatePath(WAVE wv, string jsonPath)

	variable jsonID

	ASSERT_TS(WaveExists(wv), "Missing wave")

	jsonID = JWN_GetWaveNoteAsJSON(wv)
	JSON_AddTreeObject(jsonID, jsonPath)
	JWN_WriteWaveNote(wv, JWN_GetWaveNoteHeader(wv), jsonID)
End
