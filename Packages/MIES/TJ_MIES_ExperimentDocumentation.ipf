/// @file TJ_MIES_ExperimentDocumentation.ipf
/// @brief Brief description of Experiment Documentation 

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//=============================================================================================================
Function ED_MakeSettingsHistoryWave(panelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	wave ChanAmpAssign = $WavePath + ":ChanAmpAssign"
	variable NextSweep
	controlinfo /w = $panelTitle SetVar_Sweep
	NextSweep = v_value
	string NewWaveName = WavePath + ":ChanAmpAssign_Sweep_" + num2str(NextSweep)//sweep name has these new settings
	string cmd
	duplicate /o ChanAmpAssign $NewWaveName
	wave SettingsHistoryWave = $NewWaveName
	SettingsHistoryWave[11][] = NextSweep
	note SettingsHistoryWave, time()
End

//=============================================================================================================
Function ED_AppendCommentToDataWave(DataWaveName, panelTitle)
	wave DataWaveName
	string panelTitle
	controlinfo /w = $panelTitle SetVar_DataAcq_Comment
	if(strlen(s_value) != 0)
		Note DataWaveName, s_value
		SetVariable SetVar_DataAcq_Comment value = _STR:""
	endif
End

/// Brief description of the function ED_createWaveNotes
/// Function used to add notation of settings to an experiment DataWave.  This function
/// creates a keyWave, which spells out each parameter being saved, and a historyWave, which stores the settings for each headstage.  
/// 
/// For the KeyWave, the wave dimensions are:
/// row 0 - Parameter name
/// row 1 - Unit
/// row 2 - Text note
///
/// For the settings history, the wave dimensions are:
/// Col 0 - Sweep Number
/// Col 1 - Time Stamp
///
/// The history wave will use layers to report the different headstages.
///
/// Incoming parameters
/// @param incomingSettingsWave -- the settingsWave sent by the each reporting subsystem
/// @param incomingKeyWave -- the key wave that is used to reference the incoming settings wave
/// @param SaveDataWavePath -- the path to the data wave that will have the wave notes added to it
/// @param SweepCounter -- the sweep number
/// @param panelTitle -- the calling panel name, used for saving the datawave information in the proper data folder
///
/// After the key wave and history settings waves are created and have new information appended to them, this function
/// will compare the new settings to the most recent settings, and will create the wave note indicating the change in states
/// 
//=============================================================================================================
Function ED_createWaveNotes(incomingSettingsWave, incomingKeyWave, SaveDataWavePath, SweepCounter, panelTitle)
	wave incomingSettingsWave
	wave/T incomingKeyWave
	string saveDataWavePath
	string panelTitle
	variable SweepCounter
	
	// Location for the saved datawave
	wave saveDataWave = $saveDataWavePath
	
	// local variable for the sweep number
	variable SweepNo = SweepCounter
	
	// Location for the settings wave
	String settingsHistoryPath
	sprintf settingsHistoryPath, "%s:%s" Path_LabNoteBookFolder(panelTitle), "settingsHistory"
	//print "settingsHistoryPath: ", settingsHistoryPath
	
	wave/Z settingsHistory = $settingsHistoryPath
	// see if the wave exists....if so, append to it...if not, create it
	if (!WaveExists(settingsHistory) )
		//print "creating settingsHistoryPath..."
		// create the wave...just set the dimensions to give it something to build on
		make/N = (1,2,0) $settingsHistoryPath
		// Col 0 - Sweep Number
		// Col 1 - Time Stamp
		Wave settingsHistory = $settingsHistoryPath
		SetDimLabel 1, 0, SweepNumber, settingsHistory
		SetDimLabel 1, 1, TimeStamp, settingsHistory
	endif
	
	// Locating for the keyWave
	String keyWavePath
	sprintf keyWavePath, "%s:%s" Path_LabNoteBookFolder(panelTitle), "keyWave"
	
	
	// see if the wave exists....if so, append to it...if not, create it
	Wave/T /Z keyWave = $keyWavePath
	if (!WaveExists(keyWave))
		// create the wave...just set the dimensions to give it something to build on
		make /T /N=(0,0,0)  $keyWavePath		
		// row 0 - Parameter name
		// row 1 - Unit
		// row 2 - Text note
		
		Wave/t keyWave = $keyWavePath
		// Add dimension labels to the keyWave
		SetDimLabel 0, 0, Parameter, keyWave
		SetDimLabel 0, 1, Units, keyWave
		SetDimLabel 0, 2, TextNotation, KeyWave
	endif
	
	
	
	// get the size of the ampSettingsHistory wave
	variable rowCount = DimSize(settingsHistory, 0)		// sweep
	//print "rowCount: ", rowCount
	variable colCount = DimSize(settingsHistory, 1)		// factor
	//print "colCount: ", colCount
	variable layerCount = DimSize(settingsHistory, 2)		// headstage
	//print "layerCount: ", layerCount
	
	// get the size of the incoming Settings Wave
	variable incomingRowCount = DimSize(incomingSettingsWave, 0)			// sweep
	//print "incomingRowCount: ", incomingRowCount
	variable incomingColCount = DimSize(incomingSettingsWave, 1)			// factor
	//print "incomingColCount: ", incomingColCount
	variable incomingLayerCount = DimSize(incomingSettingsWave, 2)		// headstage
	//print "incomingLayerCount: ", incomingLayerCount
		
	
	// Now go through the incoming text wave and see if these factors are already being monitored
	// get the dimension of the existing keyWave
	variable keyColCount = DimSize(keyWave, 1) 					// factor
	variable incomingKeyColCount = DimSize(incomingKeyWave, 1)	// incoming factors
	variable keyColCounter
	variable incomingKeyColCounter
	
	// get the size of the incoming Key Wave
	variable incomingKeyRowCount = DimSize(incomingKeyWave, 0)			// rows...should be 3
	//print "incomingKeyRowCount: ", incomingKeyRowCount

	
	//print "keyWaveSize: ", keyColCount
	//print "incoming keyWave size: ", incomingKeyColCount
	variable keyMatchFound = 0
	// if keyWave is just formed, just add the incoming KeyWave....
	if (keyColCount == 0)
		//print "setting up inital keyWave..."
		// have to redimension the keyWave to create the space for the new stuff
		Redimension/N= (3, incomingKeyColCount) keyWave
		// also redimension the settings History Wave to create row space to add new sweep data...
		Redimension/N=(-1, incomingColCount, incomingLayerCount) settingsHistory
		//print "after key wave redimension..."
		//print "key wave row size ", DimSize(keyWave, 0)		// sweep
		//print "key wave col size ", DimSize(keyWave, 1)		// factor
		
		//print "after settings history redimension..."
		rowCount = DimSize(settingsHistory, 0)		// sweep
		//print "rowCount: ", rowCount
		colCount = DimSize(settingsHistory, 1)		// factor
		//print "colCount: ", colCount
		layerCount = DimSize(settingsHistory, 2)	// headstage-+ 	
		//print "layerCount: ", layerCount		
		
		for (keyColCounter = 0; keyColCounter < (incomingKeyColCount); keyColCounter += 1)
			//print "copying incomingKeyWave factor to keyWave at ", keyColCounter
			//print "incoming KeyWave factor text: ", incomingKeyWave[0][keyColCounter]
			keyWave[0][keyColCounter] = incomingKeyWave[0][keyColCounter] // copy the parameter name
			//print "after copy step, keyWaveText: ", keyWave[0][keyColCounter]			
			keyWave[1][keyColCounter] = incomingKeyWave[1][keyColCounter] // copy the unit string			
		endfor
		
		// set this so we don't do the matching bit down below
		keyMatchFound = 1
		//print "done creating the initial keyWave..."
	else	 // scan through the keyWave to see where to stick the incomingKeyWave
		//print "checking to see if incoming factors are already monitored..."		
		for (incomingKeyColCounter = 0; incomingKeyColCounter < incomingKeyColCount; incomingKeyColCounter += 1)
//			print "checking for incoming key at : ", incomingKeyColCounter
			for (keyColCounter = 0; keyColCounter < keyColCount; keyColCounter += 1)
//				print "looking in existing keyWave at ", keyColCounter
				if (stringmatch(incomingKeyWave[0][incomingKeyColCounter], keyWave[0][keyColCounter]) == 1)
					//print "Match Found!"
					keyMatchFound = 1
				endif
			endfor
		endfor		
	endif
	
	if (keyMatchFound == 1)
		//print "key Match Found...these incoming factors are already being monitored..."
		// just need to redimension the row size....
		// Redimension/N=((rowCount + incomingRowCount), -1, -1) settingsHistory
	else		// append the incoming keyWave to the existing keyWave
		// Need to resize the column part of the wave to accomodate the new factors being monitored
		Redimension/N=(-1, (colCount + incomingColCount), incomingLayerCount) settingsHistory
		//print "appending incoming key wave..."
		variable keyWaveInsertPoint = keyColCount
		variable insertCounter 
		//print "adding incoming keyWave at ", keyWaveInsertPoint
		for (insertCounter = keyWaveInsertPoint; insertCounter < (keyWaveInsertPoint + incomingKeyColCount); insertCounter += 1)
			//print "inserting factor at ", insertCounter
			keyWave[0][insertCounter] = incomingKeyWave[0][(insertCounter - keyWaveInsertPoint)]
			keyWave[0][insertCounter] = incomingKeyWave[1][(insertCounter - keyWaveInsertPoint)]
		endfor
	endif
	
	// Get the size of the new rejiggered keyWave
	keyColCount = DimSize(keyWave, 1)
	//print "new keyColCount: ", keyColCount
	
	//define counters
	variable rowCounter
	variable colCounter 
	variable layerCounter
	
	// where are we adding the new stuff?
	variable settingsRowCount = (DimSize(settingsHistory, 0)
	//print "settingsRowCount: ", settingsRowCount
	// set the rowredimension to add another row...leave the other stuff alone
	// Do we need to redimension to accomodate this sweep #?
	if ((settingsRowCount -1) >= SweepNo)
		print "no redimension needed ... "  // already have a row for this 
	else
		Redimension/N=((sweepNo + 1), -1, -1) settingsHistory
		settingsRowCount = (DimSize(settingsHistory, 0))
		//print "after the row redimension, settingsRowCount = ", settingsRowCount
		//variable rowIndex = sweepNo
		//print "adding the new stuff at rowIndex: ", rowIndex
	endif
	
	variable rowIndex = sweepNo
	//print "adding the new stuff at rowIndex: ", rowIndex
	
	// put the sweep number in col 0
	settingsHistory[rowIndex][0] = sweepNo
	
	// put the timestamp in col 1
	//string timeStamp = secs2time(datetime, 1)
	//settingsHistory[rowIndex][1] = timeStamp
	//doing this as just the seconds for now....
	//print "datetime value: ", datetime
	settingsHistory[rowIndex][1] = datetime
	
	// Use the keyWave to see where to add the incomingWave factors to the ampSettingsHistory wave
	for (incomingKeyColCounter = 0; incomingKeyColCounter < incomingKeyColCount; incomingKeyColCounter += 1)
		//print "doing the factor addition step at ", incomingKeyColCounter
		//print "factor: ", incomingKeyWave[0][incomingKeyColCounter]
		for (keyColCounter = 2; keyColCounter < keyColCount; keyColCounter += 1)
			//print "looking in keyWave at ", keyColCounter
			//print "keyWave factor", keyWave[0][keyColCounter]
			if (stringmatch(incomingKeyWave[0][incomingKeyColCounter], keyWave[0][keyColCounter]) == 1)
			// found the string match
				//print "******found a matching factor!*****",  keyWave[0][keyColCounter]
				for (layerCounter = 0; layerCounter < incominglayerCount; layerCounter += 1)
					// add all the values in that column to the settingsHistory wave
//					print "for column: ", keyColCounter
//					print "for layer: ", layerCounter
//					print "factor value in incoming Settings: ", incomingSettingsWave[0][keyColCounter][layerCounter]
					settingsHistory[rowIndex][keyColCounter][layerCounter] = incomingSettingsWave[0][keyColCounter][layerCounter]
//					print "after the copy..."
//					print "at row: ", rowIndex
//					print "at column: ", keyColCounter
//					print "at layer: ", layerCounter
//					print "settingsHistory is now: ", settingsHistory[rowIndex][keyColCounter][layerCounter]
				endfor
			endif
		endfor
	endfor
	
	// And now....see if the factor has changed...and if it has, add a wave note indicating the factor that changed
	// only do this if there are 2 or more rows
	rowCount = DimSize(settingsHistory, 0)
	colCount = DimSize(settingsHistory, 1)	
	//print "new Row Count: ", rowCount
	//print "new Col Count: ", colCount
	rowIndex = SweepNo
	//print "rowIndex: ", rowIndex
	
	// just do this to indicate that yes, we did actually create a wave note...this will not be needed in final production version
	//Note saveDataWave "Hey Mate...we made a wave note!"
	
	if (rowIndex >= 1)	// only need to do this if there are more then 2 sweeps to compare
		for (layerCounter = 0; layerCounter < layerCount; layerCounter += 1)
			for ( colCounter = 2; colCounter < colCount; colCounter += 1) // start at 2...otherwise you get wavenotes for every new sweep # and time stamp
				settingsHistory[rowIndex][colCounter][layerCounter] = incomingSettingsWave[0][colCounter][layerCounter]
				// and then see if the factor has changed from the previous saved setting
//				print "Comparing factors..."
//				print "new setting value: ", settingsHistory[rowIndex][colCounter][layerCounter]
//				print "old setting value: ", settingsHistory[rowIndex-1][colCounter][layerCounter]
				if (settingsHistory[rowIndex][colCounter][layerCounter] != settingsHistory[rowIndex-1][colCounter][layerCounter])
					//print "factor change!"
					//print "col: ", colCounter
					//print "layer: ", layerCounter
					//print "Factor Changed! ", keyWave[0][colCounter]
					
					
					// build up the string for the report
					String changedFactorText
					sprintf changedFactorText, ":HeadStage#%d:%s: %d:" layerCounter, keyWave[0][colCounter], settingsHistory[rowIndex][colCounter][layerCounter]
					//changedFactorText = "Factor Change:Sweep#" + num2str(SweepCounter) + ":" + keyWave[0][colCounter] + ":" + num2str(settingsHistory[rowIndex][colCounter][layerCounter])
					print changedFactorText
					
					
					// make the waveNote
					//Note saveDataWave "Factor Changed!"
					//Note saveDataWave "Sweep#" + num2str(SweepCounter)
					//Note saveDataWave "Factor:" + keyWave[0][colCounter]
					//Note saveDataWave num2str(settingsHistory[rowIndex][colCounter][layerCounter])
					Note saveDataWave changedFactorText
				endif
			endfor
		endfor
	endif
End			
	
	
	
	
	

