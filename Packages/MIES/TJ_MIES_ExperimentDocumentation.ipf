#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static StrConstant STIM_WAVE_NAME_KEY = "Stim Wave Name"

/// @brief Add notation of settings to an experiment DataWave.  This function
/// creates a keyWave, which spells out each parameter being saved, and a historyWave, which stores the settings for each headstage.
///
/// For the KeyWave, the wave dimensions are:
/// - row 0 - Parameter name
/// - row 1 - Unit
/// - row 2 - Text note
///
/// For the settings history, the wave dimensions are:
/// - Col 0 - Sweep Number
/// - Col 1 - Time Stamp
///
/// The history wave will use layers to report the different headstages.
///
/// Incoming parameters
/// @param incomingSettingsWave -- the settingsWave sent by the each reporting subsystem
/// @param incomingKeyWave -- the key wave that is used to reference the incoming settings wave
/// @param SaveDataWavePath -- the path to the data wave that will have the wave notes added to it
/// @param SweepNo -- the sweep number
/// @param panelTitle -- the calling panel name, used for saving the datawave information in the proper data folder
///
/// After the key wave and history settings waves are created and have new information appended to them, this function
/// will compare the new settings to the most recent settings, and will create the wave note indicating the change in states
///
//=============================================================================================================
Function ED_createWaveNotes(incomingSettingsWave, incomingKeyWave, SaveDataWavePath, SweepNo, panelTitle)
	wave incomingSettingsWave
	wave/T incomingKeyWave
	string saveDataWavePath
	string panelTitle
	variable SweepNo
	
	// Location for the saved datawave
	WAVE/Z saveDataWave = $saveDataWavePath
	variable idx
	
	DFREF settingsHistoryDFR = GetDevSpecLabNBSettHistFolder(panelTitle)
	WAVE/D/Z/SDFR=settingsHistoryDFR settingsHistory

	if(!WaveExists(settingsHistory))
		Make/D/N=(0, 2, NUM_HEADSTAGES) settingsHistoryDFR:settingsHistory/Wave=settingsHistory

		SetDimLabel COLS, 0, SweepNum, settingsHistory
		SetDimLabel COLS, 1, TimeStamp, settingsHistory
	endif

	ASSERT(DimSize(incomingSettingsWave, LAYERS) <= DimSize(settingsHistory, LAYERS), "Unexpected large layer count in the incoming settings wave")

	WAVE settingsHistoryDat = GetSettingsHistoryDateTime(settingsHistory)

	DFREF keyWaveDFR = GetDevSpecLabNBSettKeyFolder(panelTitle)
	Wave/T/Z/SDFR=keyWaveDFR keyWave

	if (!WaveExists(keyWave))
		Make/T/N=(4, 2) keyWaveDFR:keyWave/Wave=keyWave
		// row 0 - Parameter name
		// row 1 - Unit
		// row 2 - Tolerance
		
		// These will be permanent....will make it easier for everything to line up correctly
		// Col 0 - Sweep #		
		// Col 1 - Time
		
		keyWave[0][0] = "SweepNum"
		keyWave[0][1] = "TimeStamp"
	endif
	
	// get the size of the settingsHistory wave
	variable rowCount = DimSize(settingsHistory, 0)		// sweep
	variable colCount = DimSize(settingsHistory, 1)		// factor
	
	// get the size of the incoming Settings Wave
	variable incomingRowCount = DimSize(incomingSettingsWave, 0)			// sweep
	variable incomingColCount = DimSize(incomingSettingsWave, 1)			// factor
	variable incomingLayerCount = DimSize(incomingSettingsWave, 2)		// headstage
			
	// Now go through the incoming text wave and see if these factors are already being monitored
	// get the dimension of the existing keyWave
	variable keyColCount = DimSize(keyWave, 1) 					// factor
	variable incomingKeyColCount = DimSize(incomingKeyWave, 1)	// incoming factors
	variable keyColCounter
	variable incomingKeyColCounter

	// get the size of the incoming Key Wave
	variable keyMatchFound
	// if keyWave is just formed, just add the incoming KeyWave....
	if (keyColCount == 2)
		// have to redimension the keyWave to create the space for the new stuff
		Redimension/N= (4, (keyColCount + incomingKeyColCount)) keyWave
		// also redimension the settings History Wave to create row space to add new sweep data...
		Redimension/N=(-1, (2+incomingColCount), -1) settingsHistory
		
		// Add dimension labels to the keyWave
		SetDimLabel 0, 0, Parameter, keyWave
		SetDimLabel 0, 1, Units, keyWave
		SetDimLabel 0, 2, Tolerance, keyWave
		SetDimLabel 1, 0, SweepNum, keyWave
		SetDimLabel 1, 1, TimeStamp, keyWave
				
		rowCount = DimSize(settingsHistory, 0)		// sweep
		colCount = DimSize(settingsHistory, 1)		// factor
		
		for (keyColCounter = 0; keyColCounter < (incomingKeyColCount); keyColCounter += 1)
			keyWave[0][keyColCounter+2] = incomingKeyWave[0][keyColCounter] // copy the parameter name		
			keyWave[1][keyColCounter+2] = incomingKeyWave[1][keyColCounter] // copy the unit string		
			keyWave[2][keyColCounter+2] = incomingKeyWave[2][keyColCounter] // copy the tolerance factor
		endfor
		
		// set this so we don't do the matching bit down below
		keyMatchFound = 1
	else	 // scan through the keyWave to see where to stick the incomingKeyWave		
		for (incomingKeyColCounter = 0; incomingKeyColCounter < incomingKeyColCount; incomingKeyColCounter += 1)
			for (keyColCounter = 0; keyColCounter < keyColCount; keyColCounter += 1)
				if (stringmatch(incomingKeyWave[0][incomingKeyColCounter], keyWave[0][keyColCounter]) == 1)
					keyMatchFound = 1
				endif
			endfor
		endfor		
	endif
	
	variable  newSettingsHistoryRowSize
	if (keyMatchFound == 1)
		// just need to redimension the row size of the settingsHistory
		// only need to have this block of code once...
	else		// append the incoming keyWave to the existing keyWave
		print "extending the keyWave for new factors"
		// Need to resize the column part of the keyWave to accomodate the new factors being monitored
		Redimension/N=(-1, (keyColCount + incomingKeyColCount), -1) keyWave
		// need to redimension the column portion of the settingsHistory as well to make space for the incoming factors
		Redimension/N=(-1, (colCount + incomingColCount), -1) settingsHistory
	
		variable nanInsertCounter
		for (nanInsertCounter = colCount; nanInsertCounter < (colCount + incomingColCount); nanInsertCounter += 1)
			settingsHistory[][nanInsertCounter][] = NAN
		endfor
		
		variable keyWaveInsertPoint = keyColCount
		variable insertCounter 
		for (insertCounter = keyWaveInsertPoint; insertCounter < (keyWaveInsertPoint + incomingKeyColCount); insertCounter += 1)
			keyWave[0][insertCounter] = incomingKeyWave[0][(insertCounter - keyWaveInsertPoint)]
			keyWave[1][insertCounter] = incomingKeyWave[1][(insertCounter - keyWaveInsertPoint)]
			keyWave[2][insertCounter] = incomingKeyWave[2][(insertCounter - keyWaveInsertPoint)]
		endfor
	endif
	
	// Get the size of the new rejiggered keyWave
	keyColCount = DimSize(keyWave, 1)
	
	//define counters
	variable colCounter 
	variable layerCounter
		
	variable settingsRowCount = (DimSize(settingsHistory, 0))  // the new settingsRowCount
	variable rowIndex = settingsRowCount - 1 
	
	// Adding this section to handle the changing off the parameter names, units, and tolerances for the async factors
	// see if the incoming wave is the async wave
	if (stringmatch(incomingKeyWave[0][0], "Async AD 0*") == 1)	// this never changes...shows that the incoming keyWave is the Async stuff	
		// build up a string for comparison purposes
		string asyncParameterString
		variable adUnitCounter
		variable factorFound 
		for (adUnitCounter = 0; adUnitCounter < 8; adUnitCounter += 1)
			sprintf asyncParameterString, "Async AD %d*" adUnitCounter
			factorFound = 0
			for (keyColCounter = 0; keyColCounter < keyColCount; keyColCounter += 1)
				if (stringmatch(keyWave[0][keyColCounter], incomingKeyWave[0][adUnitCounter]) == 1) // the factor already exists
					factorFound = 1
					// copy the units and tol factors over into the keyWave...they can change without changing the parameter name...always do this since copying is more
					// time efficient then doing string matches
					keyWave[1][keyColCounter] = incomingKeyWave[1][adUnitCounter]  // units
					keyWave[2][keyColCounter] = incomingKeyWave[2][adUnitCounter]  // tolerance factor
				endif
			endfor
			if (factorFound == 0)
				// if the parameter name has changed, we need to create a new column for this
				// find the dimensions again for the keyWave (cols) and settingsHistory(rows, cols)
				keyColCount = DimSize(keyWave, 1)    // since we are doing this factor by factor for these, need to do this everytime through
				colCount = DimSize(settingsHistory, 1) // same with this
				rowCount = DimSize(settingsHistory, 0) // same with this
				// Need to resize the column part of the keyWave to accomodate the new factor being monitored...unlike above, need to do this one factor at a time
				Redimension/N=(-1, (keyColCount + 1), -1) keyWave
				// need to redimension the column portion of the settingsHistory as well to make space for the incoming factors...fill it with nan's
				Redimension/N=(-1, (colCount + 1), -1, -1) settingsHistory
				variable newSettingsColCount = DimSize(settingsHistory, 1)
				settingsHistory[][newSettingsColCount-1][] = NAN
		
				// put the new incoming factor at the end of keyWave
				keyWave[0][keyColCount] = incomingKeyWave[0][adUnitCounter]
				keyWave[1][keyColCount] = incomingKeyWave[1][adUnitCounter]
				keyWave[2][keyColCount] = incomingKeyWave[2][adUnitCounter]
			endif							
		endfor
	endif

	// Now need to redimension the row size of the settingsHistory
	newSettingsHistoryRowSize = rowCount + incomingRowCount
	Redimension/N=(newSettingsHistoryRowSize, -1, -1) settingsHistory
	idx = newSettingsHistoryRowSize - 1

	// need to fill the newly created row with NAN's....redimension autofills them with zeros
	settingsHistory[rowCount,][][] = NAN

	settingsHistory[idx][0] = sweepNo
	settingsHistory[idx][1] = datetime

	EnsureLargeEnoughWave(settingsHistoryDat, minimumSize=idx, dimension=ROWS, initialValue=NaN)

	settingsHistoryDat[idx] = settingsHistory[idx][1]

	// after doing all that, get the new dimension for the keyColCounter and the Settings History wave
	keyColCount = DimSize(keyWave, 1)    // since we are doing this factor by factor for these, need to do this everytime through
	colCount = DimSize(settingsHistory, 1) // same with this
	rowCount = DimSize(settingsHistory, 0) // same with this
	
	// need to make sure the incomingKeyColCount is correct
	incomingKeyColCount = DimSize(incomingKeyWave, 1)
	
	// Use the keyWave to see where to add the incomingWave factors to the ampSettingsHistory wave
	for (incomingKeyColCounter = 0; incomingKeyColCounter < incomingKeyColCount; incomingKeyColCounter += 1)
		for (keyColCounter = 0; keyColCounter < keyColCount; keyColCounter += 1)
			if (stringmatch(incomingKeyWave[0][incomingKeyColCounter], keyWave[0][keyColCounter]) == 1)
			// found the string match
				variable insertionPoint = keyColCounter
				// put this in to handle the async stuff that only has one layer
				if (incomingLayerCount == 0)
					settingsHistory[rowCount - 1][insertionPoint][0] = incomingSettingsWave[0][incomingkeyColCounter]
				else		
					for (layerCounter = 0; layerCounter < incominglayerCount; layerCounter += 1)
						// add all the values in that column to the settingsHistory wave
						settingsHistory[rowCount - 1][insertionPoint][layerCounter] = incomingSettingsWave[0][incomingkeyColCounter][layerCounter]
					endfor
				endif
			endif
		endfor
	endfor

	SetDimensionLabels(keyWave, settingsHistory)
	WriteChangedValuesToNote(saveDataWave, incomingKeyWave, settingsHistory, sweepNo)
End

/// @brief If the newly written values differ from the values in the last sweep, we write them to the wave note
///
/// Honours tolerances defined in the keywave and "On/Off" values
Function WriteChangedValuesToNote(saveDataWave, incomingKeyWave, settingsHistory, sweepNo)
	Wave/Z saveDataWave
	Wave/T incomingKeyWave
	Wave settingsHistory
	variable sweepNo

	string key, factor, unit, text
	string str = ""
	variable tolerance, i, j, numRows, numCols

	if(!WaveExists(saveDataWave))
		return NaN
	endif

	numCols = DimSize(incomingKeyWave, COLS)
	for (j = 0; j < numCols; j += 1)
		key    = incomingKeyWave[0][j]
		unit   = incomingKeyWave[1][j]
		factor = incomingKeyWave[2][j]
		Wave/Z currentSetting = GetLastSetting(settingsHistory, sweepNo, key)
		Wave/Z lastSetting = GetLastSetting(settingsHistory, sweepNo - 1, key)

		// We have four combinations for the current and the last setting:
		// 1. valid -> valid
		// 2. valid -> invalid
		// 3. invalid -> invalid
		// 4. invalid -> valid

		// In case 3. we have nothing to do, everyting else needs a closer look
		// for 2., 4. we create fake data set to NaN
		// and 1. needs no special treatment
		if(!WaveExists(currentSetting) && !WaveExists(lastSetting))
			continue
		elseif(!WaveExists(lastSetting))
			Duplicate/FREE currentSetting, lastSetting
			lastSetting = NaN
		elseif(!WaveExists(currentSetting))
			Duplicate/FREE lastSetting, currentSetting
			currentSetting = NaN
		endif

		ASSERT(DimSize(currentSetting, ROWS) == DimSize(lastSetting, ROWS), "last and current settings must have the same size")

		if(EqualWaves(currentSetting, lastSetting, 1))
			continue
		endif

		numRows = DimSize(currentSetting, ROWS)
		for(i = 0; i < numRows; i += 1)
			if(currentSetting[i] == lastSetting[i] || (NumType(currentSetting[i]) == 2 && NumType(lastSetting[i]) == 2))
				continue
			endif

			tolerance = str2num(factor)

			// in case we have tolerance as "-" we get tolerance == NaN
			// and the following check is false
			if(abs(currentSetting[i] - lastSetting[i]) < tolerance)
				continue
			endif

			if (!cmpstr(factor, "-"))
				sprintf text, "HS#%d:%s: %s\r" i, key, SelectString(currentSetting[i], "Off", "On")
			else
				sprintf text, "HS#%d:%s: %.2f %s\r" i, key, currentSetting[i], unit
			endif

			str += text
		endfor
	endfor

	if(!isEmpty(str))
		Note saveDataWave, str
	endif
End

/// @brief If the newly written values differ from the values in the last sweep, we write them to the wave note
///
/// Honours tolerances defined in the keywave and "On/Off" values
Function WriteChangedValuesToNoteText(saveDataWave, incomingKeyWave, settingsHistory, sweepNo)
	Wave/Z saveDataWave
	Wave/T incomingKeyWave
	Wave/T settingsHistory
	variable sweepNo

	string key, factor, text
	string str = ""
	variable tolerance, i, j, numRows, numCols

	if(!WaveExists(saveDataWave))
		return NaN
	endif

	numCols = DimSize(incomingKeyWave, COLS)
	for (j = 0; j < numCols; j += 1)
		key    = incomingKeyWave[0][j]
		Wave/T/Z currentSetting = GetLastSettingText(settingsHistory, sweepNo, key)
		Wave/T/Z lastSetting = GetLastSettingText(settingsHistory, sweepNo - 1, key)

		// We have four combinations for the current and the last setting:
		// 1. valid -> valid
		// 2. valid -> invalid
		// 3. invalid -> invalid
		// 4. invalid -> valid

		// In case 3. we have nothing to do, everyting else needs a closer look
		// for 2., 4. we create fake data set to NaN
		// and 1. needs no special treatment
		if(!WaveExists(currentSetting) && !WaveExists(lastSetting))
			continue
		elseif(!WaveExists(lastSetting))
			Duplicate/T/FREE currentSetting, lastSetting
			lastSetting = ""
		elseif(!WaveExists(currentSetting))
			Duplicate/T/FREE lastSetting, currentSetting
			currentSetting = ""
		endif

		ASSERT(DimSize(currentSetting, ROWS) == DimSize(lastSetting, ROWS), "last and current settings must have the same size")

		if(EqualWaves(currentSetting, lastSetting, 1))
			continue
		endif

		numRows = DimSize(currentSetting, ROWS)
		for(i = 0; i < numRows; i += 1)
			if(!cmpstr(currentSetting[i], lastSetting[i]))
				continue
			endif

			sprintf text, "HS#%d:%s: %s\r" i, key, currentSetting[i]
			str += text
		endfor
	endfor

	if(!isEmpty(str))
		Note saveDataWave, str
	endif
End

/// @brief Function used to add text notation to an experiment DataWave.  This function creates a keyWave to reference
/// the text wave, which spells out each parameter being saved, and a textWave, which stores text notation.
///
/// For the KeyWave, the wave dimensions are:
/// - row 0 - Parameter name
/// - row 1 - Units
/// - row 2 - Text note Placeholder
///
/// For the text documentation wave, the wave dimensions are:
/// - Col 0 - Sweep Number
/// - Col 1 - Time Stamp
///
/// The text documentation wave will use layers to report the different headstages.
///
/// Incoming parameters
/// @param incomingTextDocWave -- the incoming Text Documentation Wave sent by the each reporting subsystem
/// @param incomingTextDocKeyWave -- the incoming Text Documentation key wave that is used to reference the incoming settings wave
/// @param SaveDataWavePath -- the path to the data wave that will have the wave notes added to it
/// @param sweepNo -- the sweep number
/// @param panelTitle -- the calling panel name, used for saving the datawave information in the proper data folder
///
/// After the key wave and history settings waves are created and have new information appended to them, this function
/// will compare the new settings to the most recent settings, and will create the wave note indicating the change in states
///
//=============================================================================================================
Function ED_createTextNotes(incomingTextDocWave, incomingTextDocKeyWave, SaveDataWavePath, sweepNo, panelTitle)
	wave/T incomingTextDocWave
	wave/T incomingTextDocKeyWave
	string saveDataWavePath
	string panelTitle
	variable sweepNo

	string changedDocText
	variable keyColCount, incomingKeyColCounter, rowCount, colCount, incomingRowCount, incomingColCount
	variable keyColCounter, keyMatchFound, rowIndex
	variable i, j, k

	// Location for the saved datawave
	wave saveDataWave = $saveDataWavePath
	Wave/T textDocWave = GetTextDocWave(panelTitle)
	Wave/T textDocKeyWave = GetTextDocKeyWave(panelTitle)

	rowCount = DimSize(textDocWave, ROWS)
	colCount = DimSize(textDocWave, COLS)
	incomingRowCount = DimSize(incomingTextDocWave, ROWS)
	incomingColCount = DimSize(incomingTextDocWave, COLS)

	ASSERT(DimSize(incomingTextDocWave, LAYERS) == NUM_HEADSTAGES, "Mismatched layer counts")
	ASSERT(DimSize(incomingTextDocWave, COLS)   == DimSize(incomingTextDocKeyWave, COLS), "Mismatched column counts")

	keyColCount = DimSize(textDocKeyWave, COLS)

	if(keyColCount != INITIAL_KEY_WAVE_COL_COUNT)
		// scan through the keyWave to see where to stick the incomingKeyWave
		/// @todo the logic here is flawed as it does not handle a keyWave properly with entries
		/// unknownEntry | knownEntry
		/// in that case it would set keyMatchFound to 1 although there is a unknown entry in the first row
		for (incomingKeyColCounter = 0; incomingKeyColCounter < incomingColCount; incomingKeyColCounter += 1)
			for (keyColCounter = 0; keyColCounter < keyColCount; keyColCounter += 1)
				if (!cmpstr(incomingTextDocKeyWave[0][incomingKeyColCounter], textDocKeyWave[0][keyColCounter]))
					keyMatchFound = 1
				endif
			endfor
		endfor
	endif

	if(keyMatchFound)
		///@todo rework to use EnsureLargeEnoughWave to minimize the calls to Redimension
		Redimension/N=((rowCount + 1), -1, -1) textDocWave
	else
		// append the incoming keyWave to the existing keyWave
		// Need to resize the waves to accomodate the new factors being monitored
		Redimension/N=(-1, (keyColCount + incomingColCount), -1) textDocKeyWave
		Redimension/N=((rowCount + 1), (colCount + incomingColCount), -1) textDocWave

		textDocKeyWave[0][keyColCount,] = incomingTextDocKeyWave[0][q - keyColCount]
	endif

	rowCount = DimSize(textDocWave, ROWS)
	colCount = DimSize(textDocWave, COLS)
	keyColCount = DimSize(textDocKeyWave, COLS)
	rowIndex = rowCount -1

	textDocWave[rowIndex][0] = num2istr(sweepNo)
	textDocWave[rowIndex][1] = num2istr(DateTime)

	SetDimensionLabels(textDocKeyWave, textDocWave)

	// Use the keyWave to see where to add the incomingTextDoc factors to the textDoc wave
	for(i = 0; i < incomingColCount; i += 1)
		 for(j = INITIAL_KEY_WAVE_COL_COUNT; j < keyColCount; j += 1)
			  if(!cmpstr(incomingTextDocKeyWave[0][i], textDocKeyWave[0][j]))
				   textDocWave[rowIndex][j][] = incomingTextDocWave[0][i][r]
			  endif
		 endfor
	endfor

	WriteChangedValuesToNoteText(saveDataWave, incomingTextDocKeyWave, textDocWave, sweepNo)
End

//======================================================================================
/// always create a WaveNote for each sweep that indicates the Stim Wave Name and the Stim scale factor
// a function to create waveNote tags for the stim wave name and scale factor
function ED_createWaveNoteTags(panelTitle, savedDataWaveName, sweepCount)
	string panelTitle
	string SavedDataWaveName
	Variable sweepCount

	variable i

	Wave statusHS = DC_ControlStatusWave(panelTitle, "DataAcq_HS")

	// Create the numerical wave for saving the settings
	Wave sweepSettingsWave = GetSweepSettingsWave(panelTitle)
	Wave/T sweepSettingsKey = GetSweepSettingsKeyWave(panelTitle)

	// Create the txt wave to be used for saving the sweep set name
	Wave/T sweepSettingsTxtWave = GetSweepSettingsTextWave(panelTitle)
	Wave/T sweepSettingsTxtKey = GetSweepSettingsTextKeyWave(panelTitle)
	sweepSettingsTxtWave = ""
	sweepSettingsWave    = NaN

	// And now populate the wave
	sweepSettingsTxtKey[0][0] =  STIM_WAVE_NAME_KEY
	sweepSettingsTxtKey[0][1] =  "User Comment"

	// Get the wave reference to the new Sweep Data wave
	Wave sweepDataWave      = DC_SweepDataWvRef(panelTitle)
	Wave/T sweepDataTxtWave = DC_SweepDataTxtWvRef(panelTitle)

	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		if (!statusHS[i])
			continue
		endif

		// Save info into the stimSettingsWave
		// set name
		sweepSettingsTxtWave[0][0][i] = sweepDataTxtWave[0][0][i]
		// user comment
		sweepSettingsTxtWave[0][1][i] = sweepDataTxtWave[0][1][i]
		// scale factor
		sweepSettingsWave[0][0][i] = sweepDataWave[0][4][i]
		// DAC
		sweepSettingsWave[0][1][i] = sweepDataWave[0][0][i]
		// ADC
		sweepSettingsWave[0][2][i] = sweepDataWave[0][1][i]
		// DA Gain
		sweepSettingsWave[0][3][i] = sweepDataWave[0][2][i]
		// AD Gain
		sweepSettingsWave[0][4][i] = sweepDataWave[0][3][i]
		// Set Sweep Count
		sweepSettingsWave[0][5][i] = sweepDataWave[0][5][i]
		// TP Insert Checkbox
		sweepSettingsWave[0][6][i] = sweepDataWave[0][6][i]
	endfor

	// call the function that will create the text wave notes
	ED_createTextNotes(sweepSettingsTxtWave, sweepSettingsTxtKey, SavedDataWaveName, SweepCount, panelTitle)

	// after writing the text notes, clear the user comment
	SetSetVariableString(panelTitle, "SetVar_DataAcq_Comment", "")

	// call the function that will create the numerical wave notes
	ED_createWaveNotes(sweepSettingsWave, sweepSettingsKey, SavedDataWaveName, SweepCount, panelTitle)

	// document active headstages
	Make/FREE/N=(3, 1)/T headstagesKey
	headstagesKey = ""

	headstagesKey[0][0] =  "Headstage Active"
	headstagesKey[1][0] =  "On/Off"
	headstagesKey[2][0] =  "-"

	Make/FREE/N=(1, 1, NUM_HEADSTAGES) headstagesWave
	headStagesWave[0][0][] = statusHS[r]

	ED_createWaveNotes(headstagesWave, headstagesKey, SavedDataWaveName, SweepCount, panelTitle)

	Make/FREE/T/N=(3, 2) keys
	keys = ""

	keys[0][0] = "Follower Device"
	keys[1][0] = "On/Off"
	keys[2][0] = "-"

	keys[0][1] = "MIES version"
	keys[1][1] = "On/Off"
	keys[2][1] = "-"

	Make/FREE/T/N=(1, 2, NUM_HEADSTAGES) values
	values = ""

	if(DAP_DeviceCanLead(panelTitle))
		SVAR/Z listOfFollowerDevices = $GetFollowerList(doNotCreateSVAR=1)
		if(SVAR_Exists(listOfFollowerDevices))
			values[0][0][] = listOfFollowerDevices
		endif
	endif

	SVAR miesVersion = $GetMiesVersion()
	values[0][1][] = miesVersion

	ED_createTextNotes(values, keys, SavedDataWaveName, SweepCount, panelTitle)
End

//======================================================================================
/// @brief This function is used to create wave notes for the informations found in the Asynchronous tab in the DA_Ephys panel
function ED_createAsyncWaveNoteTags(panelTitle, savedDataWaveName, sweepCount)
	string panelTitle
	string SavedDataWaveName
	Variable sweepCount

	string ctrl

	// Create the numerical wave for saving the numerical settings
	Wave asyncSettingsWave = GetAsyncSettingsWave(panelTitle)
	Wave/T asyncSettingsKey = GetAsyncSettingsKeyWave(panelTitle)

	// Create the txt wave to be used for saving the txt settings
	Wave/T asyncSettingsTxtWave = GetAsyncSettingsTextWave(panelTitle)
	Wave/T asyncSettingsTxtKey = GetAsyncSettingsTextKeyWave(panelTitle)
	
	// Create the measurement wave that will hold the measurement values
	Wave asyncMeasurementWave = GetAsyncMeasurementWave(panelTitle)
	Wave/T asyncMeasurementKey = GetAsyncMeasurementKeyWave(panelTitle)
	
	// fill the settings wave with NAN's...the asyncMeasurementWave will be filled with NAN's in another function
	asyncSettingsWave[0][] = NAN

	// Now populate the aync Settings and measurement Waves
	// first...determine if the head stage is being controlled
	variable asyncVariablesCounter
	for(asyncVariablesCounter = 0;asyncVariablesCounter < NUM_ASYNC_CHANNELS ;asyncVariablesCounter += 1)
	// build up the string to get the DA check box to see if the DA is enabled
		sprintf ctrl, "Check_AsyncAD_0%d" asyncVariablesCounter
		variable adOnOffValue = GetCheckBoxState(panelTitle, ctrl)
		if (adOnOffValue == 1)
			// Save info into the ayncSettingsWave
			// Async AD OnOff
			sprintf ctrl, "Check_AsyncAD_0%d" asyncVariablesCounter
			asyncSettingsWave[0][asyncVariablesCounter] = GetCheckBoxState(panelTitle, ctrl)
			
			// Async AD Gain
			sprintf ctrl, "SetVar_AsyncAD_Gain_0%d" asyncVariablesCounter
			asyncSettingsWave[0][asyncVariablesCounter + 8] = GetSetVariable(panelTitle, ctrl)
			
			// Async Alarm OnOff
			sprintf ctrl, "Check_Async_Alarm_0%d" asyncVariablesCounter
			asyncSettingsWave[0][asyncVariablesCounter + 16] = GetCheckBoxState(panelTitle, ctrl)
			
			// Async Alarm Min
			sprintf ctrl, "SetVar_Async_Min_0%d" asyncVariablesCounter
			variable maxSettingValue = GetSetVariable(panelTitle, ctrl)
			asyncSettingsWave[0][asyncVariablesCounter + 24] = maxSettingValue
			
			// Async Alarm Max
			sprintf ctrl, "SetVar_Async_Max_0%d" asyncVariablesCounter
			variable minSettingValue = GetSetVariable(panelTitle, ctrl)
			asyncSettingsWave[0][asyncVariablesCounter + 32] = minSettingValue
	
			// Take the Min and Max values and use them for setting the tolerance value in the measurement key wave
			variable tolSettingValue = (maxSettingValue - minSettingValue)/2
			asyncMeasurementKey[%Tolerance][asyncVariablesCounter] = num2str(abs(tolSettingValue))
	
			//Now do the text stuff...
			// Async Title
			sprintf ctrl, "SetVar_Async_Title_0%d" asyncVariablesCounter
			string titleStringValue = GetSetVariableString(panelTitle, ctrl)
			string adTitleStringValue 
			sprintf adTitleStringValue, "Async AD %d: %s" asyncVariablesCounter, titleStringValue
			asyncSettingsTxtWave[0][asyncVariablesCounter] = titleStringValue
			// add the text unit value into the measurementKey Wave
			asyncMeasurementKey[%Parameter][asyncVariablesCounter] = adTitleStringValue
			
			// Async Unit
			sprintf ctrl, "SetVar_Async_Unit_0%d" asyncVariablesCounter
			string unitStringValue = GetSetVariableString(panelTitle, ctrl)
			string adUnitStringValue
			sprintf adUnitStringValue, "Async AD %d: %s" asyncVariablesCounter, unitStringValue
			asyncSettingsTxtWave[0][asyncVariablesCounter + 8] = adUnitStringValue
			// add the unit value into the settingsKey Wave
			asyncMeasurementKey[%Units][asyncVariablesCounter] = adUnitStringValue
		endif
	endfor

	// create the async wave notes if the Append Async readings to wave note
	variable appendAsync = GetCheckBoxState(panelTitle, "Check_Settings_Append")
	if (appendAsync == 1)
		// call the function that will create the numerical wave notes
		ED_createWaveNotes(asyncSettingsWave, asyncSettingsKey, SavedDataWaveName, SweepCount, panelTitle)
	
		// call the function that will create the measurement wave notes
		ED_createWaveNotes(asyncMeasurementWave, asyncMeasurementKey, SavedDataWaveName, SweepCount, panelTitle)
	endif
End
