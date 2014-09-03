/// @file TJ_MIES_ExperimentDocumentation.ipf
/// @brief Brief description of Experiment Documentation 

#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//=============================================================================================================
Function ED_MakeSettingsHistoryWave(panelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	Wave ChanAmpAssign = GetChanAmpAssign(panelTitle)
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
//=============================================================================================================
Function ED_AppendTPparamToDataWave(panelTitle, DataWaveName)
	string panelTitle
	wave DataWaveName
	
	
End
//=============================================================================================================

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
	wave /z saveDataWave = $saveDataWavePath //  " /z " allow for no path to be provided
	
	// local variable for the sweep number
	variable SweepNo = SweepCounter
	
	string FullFolderPath = HSU_DataFullFolderPathString(panelTitle)
//	print "fullfolderPath: ", FullFolderPath
	string DeviceType = stringfromlist(itemsinlist(FullFolderPath, ":") - 2,  FullFolderPath, ":")
	string DeviceNum = stringfromlist(itemsinlist(FullFolderPath, ":") - 1,  FullFolderPath, ":")
	
	// New place for all the data wave
	string labNoteBookFolder 
	sprintf labNoteBookFolder, "root:mies:LabNoteBook:%s:%s" DeviceType, DeviceNum
	
	// Location for the settings wave
	String settingsHistoryPath
	sprintf settingsHistoryPath, "%s:%s" labNoteBookFolder, "settingsHistory:settingsHistory"
//	print "settingsHistoryPath: ", settingsHistoryPath
	
	wave/Z settingsHistory = $settingsHistoryPath
	// see if the wave exists....if so, append to it...if not, create it
	if (!WaveExists(settingsHistory) )
		//print "creating settingsHistoryPath..."
		// create the wave...just set the dimensions to give it something to build on
		make/N = (0,2,0) $settingsHistoryPath
		// Col 0 - Sweep Number
		// Col 1 - Time Stamp
		Wave settingsHistory = $settingsHistoryPath
		SetDimLabel 1, 0, SweepNumber, settingsHistory
		SetDimLabel 1, 1, TimeStamp, settingsHistory
	endif
	
	// Locating for the keyWave
	String keyWavePath
	sprintf keyWavePath, "%s:%s"  labNoteBookFolder, "keyWave:keyWave"
//	print "keyWavePath: ", keyWavePath
	
	
	// see if the wave exists....if so, append to it...if not, create it
	Wave/T /Z keyWave = $keyWavePath
	if (!WaveExists(keyWave))
		// create the wave...just set the dimensions to give it something to build on
		make /T /N=(4,2,0)  $keyWavePath		
		// row 0 - Parameter name
		// row 1 - Unit
		// row 2 - Tolerance
		
		// These will be permanent....will make it easier for everything to line up correctly
		// Col 0 - Sweep #		
		// Col 1 - Time
		
		Wave/t keyWave = $keyWavePath
		keyWave[0][0] = "SweepNum"
		keyWave[0][1] = "TimeStamp"
	endif
	
	
	
	// get the size of the settingsHistory wave
	//print "Existing settingsHistory dimensions:"
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
	//print "keyColCount = ", keyColCount
	variable incomingKeyColCount = DimSize(incomingKeyWave, 1)	// incoming factors
	//print "incomingKeyColCount = ", incomingKeyColCount
	variable keyColCounter
	variable incomingKeyColCounter
	
	// get the size of the incoming Key Wave
	variable incomingKeyRowCount = DimSize(incomingKeyWave, 0)			// rows...should be 3
	// print "incomingKeyRowCount: ", incomingKeyRowCount
	
	//print "keyWaveSize: ", keyColCount
	//print "incoming keyWave size: ", incomingKeyColCount
	variable keyMatchFound = 0
	// if keyWave is just formed, just add the incoming KeyWave....
	if (keyColCount == 2)
		// print "setting up inital keyWave..."
		// have to redimension the keyWave to create the space for the new stuff
		Redimension/N= (4, (keyColCount + incomingKeyColCount)) keyWave
		// also redimension the settings History Wave to create row space to add new sweep data...
		Redimension/N=(-1, (2+incomingColCount), incomingLayerCount) settingsHistory
		
		 
		//print "after key wave redimension..."
		//print "key wave row size ", DimSize(keyWave, 0)		
		//print "key wave col size ", DimSize(keyWave, 1)		
		
		// Add dimension labels to the keyWave
		SetDimLabel 0, 0, Parameter, keyWave
		SetDimLabel 0, 1, Units, keyWave
		SetDimLabel 0, 2, Tolerance, keyWave
		SetDimLabel 1, 0, SweepNum, keyWave
		SetDimLabel 1, 1, TimeStamp, keyWave
				
		//print "after settings history redimension..."
		rowCount = DimSize(settingsHistory, 0)		// sweep
		//print "rowCount: ", rowCount
		colCount = DimSize(settingsHistory, 1)		// factor
		//print "colCount: ", colCount
		layerCount = DimSize(settingsHistory, 2)	// headstage	
		//print "layerCount: ", layerCount		
		
		for (keyColCounter = 0; keyColCounter < (incomingKeyColCount); keyColCounter += 1)
//			print "copying incomingKeyWave factor to keyWave at ", keyColCounter
//			print "incoming KeyWave factor text: ", incomingKeyWave[0][keyColCounter]
			keyWave[0][keyColCounter+2] = incomingKeyWave[0][keyColCounter] // copy the parameter name
//			print "after copy step, keyWaveText: ", keyWave[0][keyColCounter]			
			keyWave[1][keyColCounter+2] = incomingKeyWave[1][keyColCounter] // copy the unit string		
			keyWave[2][keyColCounter+2] = incomingKeyWave[2][keyColCounter] // copy the tolerance factor
		endfor
		
		// set this so we don't do the matching bit down below
		keyMatchFound = 1
		//print "done creating the initial keyWave..."
	else	 // scan through the keyWave to see where to stick the incomingKeyWave
		// print "checking to see if incoming factors are already monitored..."		
		for (incomingKeyColCounter = 0; incomingKeyColCounter < incomingKeyColCount; incomingKeyColCounter += 1)
			// print "checking for incoming key at : ", incomingKeyColCounter
			for (keyColCounter = 0; keyColCounter < keyColCount; keyColCounter += 1)
				// print "looking in existing keyWave at ", keyColCounter
				if (stringmatch(incomingKeyWave[0][incomingKeyColCounter], keyWave[0][keyColCounter]) == 1)
					// print "Match Found!"
					keyMatchFound = 1
				endif
			endfor
		endfor		
	endif
	
	variable  newSettingsHistoryRowSize
	if (keyMatchFound == 1)
		//print "key Match Found...these incoming factors are already being monitored..."
		// just need to redimension the row size of the settingsHistory
		Redimension/N=((rowCount + incomingRowCount), -1, -1) settingsHistory
		// need to fill the newly created row with NAN's....redimension autofills them with zeros
		newSettingsHistoryRowSize = DimSize(settingsHistory, 0)
		settingsHistory[newSettingsHistoryRowSize - 1][][] = NAN
	else		// append the incoming keyWave to the existing keyWave
		print "extending the keyWave for new factors"
		// Need to resize the column part of the keyWave to accomodate the new factors being monitored
		// print "before extension..."
		// print "keyColCount: ", keyColCount
		// print "incomingKeyColCount: ", incomingKeyColCount
		Redimension/N=(-1, (keyColCount + incomingKeyColCount), -1) keyWave
		// Also need to redimension the row size of the settingsHistory
		Redimension/N=((rowCount + incomingRowCount), -1, -1) settingsHistory
		// need to redimension the column portion of the settingsHistory as well to make space for the incoming factors
		Redimension/N=(-1, (colCount + incomingColCount), -1, -1) settingsHistory
		// need to fill the newly created row with NAN's....redimension autofills them with zeros
		newSettingsHistoryRowSize = DimSize(settingsHistory, 0)
		settingsHistory[newSettingsHistoryRowSize - 1][][] = NAN
		
		//print "appending incoming key wave..."
		variable keyWaveInsertPoint = keyColCount
		variable insertCounter 
		//print "adding incoming keyWave at ", keyWaveInsertPoint
		for (insertCounter = keyWaveInsertPoint; insertCounter < (keyWaveInsertPoint + incomingKeyColCount); insertCounter += 1)
			//print "inserting factor at ", insertCounter
			keyWave[0][insertCounter] = incomingKeyWave[0][(insertCounter - keyWaveInsertPoint)]
			keyWave[1][insertCounter] = incomingKeyWave[1][(insertCounter - keyWaveInsertPoint)]
			keyWave[2][insertCounter] = incomingKeyWave[2][(insertCounter - keyWaveInsertPoint)]
		endfor
	endif
	
	// Get the size of the new rejiggered keyWave
	keyColCount = DimSize(keyWave, 1)
	//print "new keyColCount: ", keyColCount
	
	//define counters
	variable rowCounter
	variable colCounter 
	variable layerCounter
		
	variable settingsRowCount = (DimSize(settingsHistory, 0))  // the new settingsRowCount
	//print "after the row redimension, settingsRowCount = ", settingsRowCount
	variable rowIndex = settingsRowCount - 1 
	//print "adding the new stuff at rowIndex: ", rowIndex
	
	// put the sweep number in col 0
	settingsHistory[rowIndex][0] = sweepNo
	
	// put the timestamp in col 1
	//string timeStamp = secs2time(datetime, 1)
	//settingsHistory[rowIndex][1] = timeStamp
	//doing this as just the seconds for now....
	//print "datetime value: ", datetime
	settingsHistory[rowIndex][1] = datetime
	
	//print "incomingKeyColCount: ", incomingKeyColCount
	// Use the keyWave to see where to add the incomingWave factors to the ampSettingsHistory wave
	for (incomingKeyColCounter = 0; incomingKeyColCounter < incomingKeyColCount; incomingKeyColCounter += 1)
		//print "incoming key--doing the factor addition step at ", incomingKeyColCounter
		//print "looking for factor: ", incomingKeyWave[0][incomingKeyColCounter]
		for (keyColCounter = 0; keyColCounter < keyColCount; keyColCounter += 1)
			//print "looking in keyWave at ", keyColCounter
			if (stringmatch(incomingKeyWave[0][incomingKeyColCounter], keyWave[0][keyColCounter]) == 1)
			// found the string match
//				print "******found a matching factor!*****",  keyWave[0][keyColCounter]
//				print "at keyColCounter: ", keyColCounter
//				print "at incomingKeyColCounter: ", incomingKeyColCounter
				variable insertionPoint = keyColCounter		
				for (layerCounter = 0; layerCounter < incominglayerCount; layerCounter += 1)
					// add all the values in that column to the settingsHistory wave
//					print "for existing Key column: ", keyColCounter
//					print "for incoming Key column: ", incomingKeyColCounter
//					print "for layer: ", layerCounter
//					print "factor value in incoming Settings: ", incomingSettingsWave[0][incomingKeyColCounter][layerCounter]
//					print "insertionPoint: ", insertionPoint
					settingsHistory[rowIndex][insertionPoint][layerCounter] = incomingSettingsWave[0][incomingkeyColCounter][layerCounter]
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
//	print "new Col Count: ", colCount
	rowIndex = rowCount - 1
	//print "rowIndex: ", rowIndex
	
	// set dimlabels for every column of the settingsHistory wave and the key wave
	// define dimLabel counter
	variable dimLabelCounter
	for (dimLabelCounter = 0; dimLabelCounter < colCount; dimLabelCounter += 1)
		string dimLabelText = 	keyWave[0][dimLabelCounter]
		SetDimLabel 1, dimLabelCounter, dimLabelText, keyWave
		SetDimLabel 1, dimLabelCounter, dimLabelText, settingsHistory
	endfor
	
	// since we have now de-coupled the row number from the sweep number to facilitate the addition of factors from other places besides the amp settings (like the test pulse, for example)
	// we may now have "open" spaces in the settings history.  Because of this we can't just compare the [rowIndex] values against the [rowIndex-1] values.  We have to search back through 
	// the rows to find where the most recent previous value was saved...
	variable rowSearchCounter	 	// used to look back through the rows to find the most recent saved value
	variable recentRowIndex 		// used to save the rowIndex where the most recent set of values will be found
	variable recentRowIndexFound  // boolean to get out of the searching loop
	variable foundValue
	
	variable valueDiff		
		
	if (rowIndex >= 1)	// only need to do this if there are more then 2 sweeps to compare
		for (layerCounter = 0; layerCounter < layerCount; layerCounter += 1)
//			print "for layer #: ", layerCounter
			for ( colCounter = 2; colCounter < colCount; colCounter += 1) // start at 2...otherwise you get wavenotes for every new sweep # and time stamp
				// only do this if there is a valid recent value
				foundValue = settingsHistory[rowIndex][colCounter][layerCounter]
				if (numtype(foundValue) == 2) //most recent value is a NAN...meaning there's no reason to scan back to look for changes
//					print "not a valid value.............."
				else
	//				print "for column: ", colCounter
					rowSearchCounter = rowIndex - 1		
					do
	//					print "searching for recent row index!"
	//					print "rowSearchCounter: ", rowSearchCounter
	//					print "at that space, found value: ", settingsHistory[rowSearchCounter][colCounter][layerCounter]
						foundValue = settingsHistory[rowSearchCounter][colCounter][layerCounter]
						if (numtype(foundValue) == 0)
							recentRowIndex = rowSearchCounter
							recentRowIndexFound = 1
	//						print "recentRow Found!"
	//						print "recentRowIndex: ", recentRowIndex
						else			// didn't find a valid number there!
							rowSearchCounter = rowSearchCounter - 1
						endif
					while ((recentRowIndexFound != 1) && (rowSearchCounter > 0))
					
	//				print "*************broke out of finding recent row...."
					// need to reset the recentRowIndexFound
					recentRowIndexFound = 0
					
//					print " "
//					print "................................................................................................................."	
//					print "for column: ", colCounter
//					print "layer #: ", layerCounter
//					print "Comparing factor...", keyWave[0][colCounter]
//					print "in Row #: ", rowIndex
//					print "new setting value: ", settingsHistory[rowIndex][colCounter][layerCounter]
//					print "in Row #: ", recentRowIndex
//					print "old setting value: ", settingsHistory[recentRowIndex][colCounter][layerCounter]
					if(cmpstr(saveDataWavePath,"") != 0) // prevents attempting to add note to data wave if no data wave path has been provided
						if (stringmatch(keyWave[2][colCounter],"-")) 		// if the factor is an on/off, don't do the tolerance checking
	//						print "This is an enable setting...."
							if (settingsHistory[rowIndex][colCounter][layerCounter] != settingsHistory[recentRowIndex][colCounter][layerCounter]) // see if the enable setting has changed
								print "****Enable setting changed!"
								String changedEnableText
								String onOffText
								if (settingsHistory[rowIndex][colCounter][layerCounter] == 0)
									onOffText = "Off"
								else
									onOffText = "On"
								endif
								
								sprintf changedEnableText, "HeadStage#%d:%s: %s" layerCounter, keyWave[0][colCounter], onOffText
								print changedEnableText
								Note saveDataWave changedEnableText						
							endif				
						elseif (abs(settingsHistory[rowIndex][colCounter][layerCounter] - settingsHistory[recentRowIndex][colCounter][layerCounter]) >= str2num(keyWave[2][colCounter])) // is the change greater then the tolerance?
							print "Factor change!"
	//						print "col: ", colCounter
	//						print "layer: ", layerCounter
	//						print "Factor Changed! ", keyWave[0][colCounter]
							
							
							// build up the string for the report
							String changedFactorText
							sprintf changedFactorText, "HeadStage#%d:%s: %.2f %s" layerCounter, keyWave[0][colCounter], settingsHistory[rowIndex][colCounter][layerCounter], keyWave[1][colCounter]
							//changedFactorText = "Factor Change:Sweep#" + num2str(SweepCounter) + ":" + keyWave[0][colCounter] + ":" + num2str(settingsHistory[rowIndex][colCounter][layerCounter])
							print changedFactorText
							
							
							// make the waveNote
							//Note saveDataWave "Factor Changed!"
							//Note saveDataWave "Sweep#" + num2str(SweepCounter)
							//Note saveDataWave "Factor:" + keyWave[0][colCounter]
							//Note saveDataWave num2str(settingsHistory[rowIndex][colCounter][layerCounter])
							Note saveDataWave changedFactorText
						endif
					endif
				endif
			endfor
		endfor
	endif
End			
	
/// Brief description of the function ED_createTextNotes
/// Function used to add text notation to an experiment DataWave.  This function
/// creates a keyWave to reference the text wave, which spells out each parameter being saved, and a textWave, which stores text notation.  
/// 
/// For the KeyWave, the wave dimensions are:
/// row 0 - Parameter name
/// row 1 - Units
/// row 2 - Text note Placeholder
///
/// For the text documentation wave, the wave dimensions are:
/// Col 0 - Sweep Number
/// Col 1 - Time Stamp
///
/// The text documentation wave will use layers to report the different headstages.
///
/// Incoming parameters
/// @param incomingTextDocWave -- the incoming Text Documentation Wave sent by the each reporting subsystem
/// @param incomingTextDocKeyWave -- the incoming Text Documentation key wave that is used to reference the incoming settings wave
/// @param SaveDataWavePath -- the path to the data wave that will have the wave notes added to it
/// @param SweepCounter -- the sweep number
/// @param panelTitle -- the calling panel name, used for saving the datawave information in the proper data folder
///
/// After the key wave and history settings waves are created and have new information appended to them, this function
/// will compare the new settings to the most recent settings, and will create the wave note indicating the change in states
/// 
//=============================================================================================================
Function ED_createTextNotes(incomingTextDocWave, incomingTextDocKeyWave, SaveDataWavePath, SweepCounter, panelTitle)
	wave/T incomingTextDocWave
	wave/T incomingTextDocKeyWave
	string saveDataWavePath
	string panelTitle
	variable SweepCounter
	
	// Location for the saved datawave
	wave saveDataWave = $saveDataWavePath
	
	// local variable for the sweep number
	variable SweepNo = SweepCounter
	
	string FullFolderPath = HSU_DataFullFolderPathString(panelTitle)
//	print "fullfolderPath: ", FullFolderPath
	string DeviceType = stringfromlist(itemsinlist(FullFolderPath, ":") - 2,  FullFolderPath, ":")
	string DeviceNum = stringfromlist(itemsinlist(FullFolderPath, ":") - 1,  FullFolderPath, ":")

	// New place for all the data wave
	string labNoteBookFolder
	sprintf labNoteBookFolder, "root:mies:LabNoteBook:%s:%s" DeviceType, DeviceNum

	// Location for the text documentation wave
	String textDocPath
	sprintf textDocPath, "%s:%s" labNoteBookFolder, "textDocumentation:textDocumentation"
	
	wave/Z /T textDocWave = $textDocPath
	// see if the wave exists....if so, append to it...if not, create it
	if (!WaveExists(textDocWave) )
		// create the wave...just set the dimensions to give it something to build on
		make/T /N = (0,2,0) $textDocPath
		// Col 0 - Sweep Number
		// Col 1 - Time Stamp
		Wave/T textDocWave = $textDocPath
		SetDimLabel 1, 0, SweepNumber, textDocWave
		SetDimLabel 1, 1, TimeStamp, textDocWave
	endif
	
	// Locating for the textDocKeyWave
	String textDocKeyWavePath
	sprintf textDocKeyWavePath, "%s:%s" labNoteBookFolder, "textDocKeyWave:textDocKeyWave"
	
	
	// see if the wave exists....if so, append to it...if not, create it
	Wave/T /Z textDocKeyWave = $textDocKeyWavePath
	if (!WaveExists(textDocKeyWave))
		// create the wave...just set the dimensions to give it something to build on
		make /T /N=(3,2,0)  $textDocKeyWavePath
		// row 0 - Parameter name
		// row 1 - Unit
		// row 2 - Text note
		
		// col 0 - Sweep Number
		// col 1 - Time Stamp
		Wave/T textDocKeyWave = $textDocKeyWavePath
		textDocKeyWave[0][0] = "SweepNum"
		textDocKeyWave[0][1] = "TimeStamp"
	endif
	
	
	//print "building up the text doc key..."
	
	// get the size of the ampSettingsHistory wave
	variable rowCount = DimSize(textDocWave, 0)		// sweep
	//print "rowCount: ", rowCount
	variable colCount = DimSize(textDocWave, 1)		// factor
	//print "colCount: ", colCount
	variable layerCount = DimSize(textDocWave, 2)		// headstage
	//print "layerCount: ", layerCount
	
	// get the size of the incoming Settings Wave
	variable incomingRowCount = DimSize(incomingTextDocWave, 0)			// sweep
//	print "incomingRowCount: ", incomingRowCount
	variable incomingColCount = DimSize(incomingTextDocWave, 1)			// factor
//	print "incomingColCount: ", incomingColCount
	variable incomingLayerCount = DimSize(incomingTextDocWave, 2)			// headstage
//	print "incomingLayerCount: ", incomingLayerCount
		
	
	// Now go through the incoming text wave and see if these factors are already being monitored
	// get the dimension of the existing keyWave
	variable keyColCount = DimSize(textDocKeyWave, 1) 					// factor
	variable incomingKeyColCount = DimSize(incomingTextDocKeyWave, 1)	// incoming factors
	variable keyColCounter
	variable incomingKeyColCounter
	
	// get the size of the incoming Key Wave
	variable incomingKeyRowCount = DimSize(incomingTextDocKeyWave, 0)	// rows...should be 3
	variable keyMatchFound = 0
	
	// if keyWave is just formed, just add the incoming KeyWave....
	if (keyColCount == 2)
		//print "setting up inital keyWave..."
		// have to redimension the keyWave to create the space for the new stuff
		Redimension/N= (3, incomingKeyColCount+2) textDocKeyWave
		// also redimension the settings History Wave to create row space to add new sweep data...
		Redimension/N=(-1, incomingColCount+2, incomingLayerCount) textDocWave
		//print "after key wave redimension..."
		//print "key wave row size ", DimSize(keyWave, 0)		// sweep
		//print "key wave col size ", DimSize(keyWave, 1)		// factor
		
		//print "after settings history redimension..."
		rowCount = DimSize(textDocWave, 0)		// sweep
		//print "rowCount: ", rowCount
		colCount = DimSize(textDocWave, 1)		// factor
		//print "colCount: ", colCount
		layerCount = DimSize(textDocWave, 2)	// headstage-+ 	
		//print "layerCount: ", layerCount		
		
		for (keyColCounter = 0; keyColCounter < (incomingKeyColCount); keyColCounter += 1)
//			print "copying incomingKeyWave factor to keyWave at ", keyColCounter
//			print "incoming KeyWave factor text: ", incomingTextDocKeyWave[0][keyColCounter]
			textDocKeyWave[0][keyColCounter+2] = incomingTextDocKeyWave[0][keyColCounter] // copy the parameter name
//			print "after copy step, keyWaveText: ", textDocKeyWave[0][keyColCounter]			
			textDocKeyWave[1][keyColCounter+2] = incomingTextDocKeyWave[1][keyColCounter] // copy the unit string
		endfor
		
		// set this so we don't do the matching bit down below
		keyMatchFound = 1
//		print "done creating the initial keyWave..."
	else	 // scan through the keyWave to see where to stick the incomingKeyWave
		//print "checking to see if incoming factors are already monitored..."		
		for (incomingKeyColCounter = 0; incomingKeyColCounter < incomingKeyColCount; incomingKeyColCounter += 1)
			for (keyColCounter = 0; keyColCounter < keyColCount; keyColCounter += 1)
				if (stringmatch(incomingTextDocKeyWave[0][incomingKeyColCounter], textDocKeyWave[0][keyColCounter]) == 1)
					keyMatchFound = 1
				endif
			endfor
		endfor		
	endif
	
	// Add dimension labels to the textDocKeyWave
	SetDimLabel 0, 0, Parameter, textDocKeyWave
	SetDimLabel 0, 1, Units, textDocKeyWave
	
	if (keyMatchFound == 1)
		//print "key Match Found...these incoming factors are already being monitored..."
		// just need to redimension the row size....
		Redimension/N=((rowCount + incomingRowCount), -1, -1) textDocWave
	else		// append the incoming keyWave to the existing keyWave
		// Need to resize the column part of the wave to accomodate the new factors being monitored
		Redimension/N=(-1, (colCount + incomingColCount), incomingLayerCount) textDocWave
		//print "appending incoming key wave..."
		variable keyWaveInsertPoint = keyColCount
		variable insertCounter 
		//print "adding incoming keyWave at ", keyWaveInsertPoint
		for (insertCounter = keyWaveInsertPoint; insertCounter < (keyWaveInsertPoint + incomingKeyColCount); insertCounter += 1)
			//print "inserting factor at ", insertCounter
			textDocKeyWave[0][insertCounter] = incomingTextDocKeyWave[0][(insertCounter - keyWaveInsertPoint)]
			textDocKeyWave[1][insertCounter] = incomingTextDocKeyWave[1][(insertCounter - keyWaveInsertPoint)]
		endfor
	endif
	
	// Get the size of the new rejiggered keyWave
	keyColCount = DimSize(textDocKeyWave, 1)
	//print "new keyColCount: ", keyColCount
	
	//define counters
	variable rowCounter
	variable colCounter 
	variable layerCounter
	
	variable settingsRowCount = (DimSize(textDocWave, 0))  // the new settingsRowCount
	//print "after the row redimension, settingsRowCount = ", settingsRowCount
	variable rowIndex = settingsRowCount - 1
	//print "adding the new stuff at rowIndex: ", rowIndex

	// put the sweep number in col 0
	textDocWave[rowIndex][0] = num2str(sweepNo)
	
	// put the timestamp in col 1
	string timeStamp = secs2time(datetime, 1)
	textDocWave[rowIndex][1] = timeStamp	
	
	// Use the keyWave to see where to add the incomingTextDoc factors to the textDoc wave
	for (incomingKeyColCounter = 0; incomingKeyColCounter < incomingKeyColCount; incomingKeyColCounter += 1)
		for (keyColCounter = 0; keyColCounter < keyColCount; keyColCounter += 1)
			if (stringmatch(incomingTextDocKeyWave[0][incomingKeyColCounter], textDocKeyWave[0][keyColCounter]) == 1)
			// found the string match
				for (layerCounter = 0; layerCounter < incominglayerCount; layerCounter += 1)
//					print "for layer: ", layerCounter
//					print "for column: ", keyColCounter
//					print "text to add: ", incomingTextDocWave[0][keyColCounter-2][layerCounter]
					// add all the values in that column to the settingsHistory wave
					textDocWave[rowIndex][keyColCounter][layerCounter] = incomingTextDocWave[0][keyColCounter-2][layerCounter]
//					print "after the copy, textDocWave: ", textDocWave[rowIndex][keyColCounter][layerCounter]
				endfor
			endif
		endfor
	endfor
	
	// And now....add a wave note for the text Doc Wave
	rowCount = DimSize(textDocWave, 0)
	colCount = DimSize(textDocWave, 1)
	layerCount = DimSize(textDocWave, 2)

//	print "new Row Count: ", rowCount
//	print "new Col Count: ", colCount
	rowIndex = rowCount - 1
//	print "rowIndex: ", rowIndex
	
//	print "layerCount: ", layerCount

	for (layerCounter = 0; layerCounter < layerCount; layerCounter += 1)
		for ( colCounter = 2; colCounter < colCount; colCounter += 1) // start at 2...otherwise you get wavenotes for every new sweep # and time stamp
			// textDocWave[rowIndex][colCounter][layerCounter] = incomingTextDocWave[0][colCounter][layerCounter]
			// and then see if the factor has changed from the previous saved setting
//				if (StringMatch(textDocWave[rowIndex][colCounter][layerCounter], textDocWave[rowIndex-1][colCounter-2][layerCounter]) != 1)
			// build up the string for the report
			if (StringMatch(textDocWave[rowIndex][colCounter][layerCounter], "!"))
				String changedDocText
				sprintf changedDocText, "HeadStage#%d:%s: %s" layerCounter, textDocKeyWave[0][colCounter], textDocWave[rowIndex][colCounter][layerCounter]
				//changedFactorText = "Factor Change:Sweep#" + num2str(SweepCounter) + ":" + keyWave[0][colCounter] + ":" + num2str(settingsHistory[rowIndex][colCounter][layerCounter])
//				print changedDocText
				Note saveDataWave changedDocText
			endif
		endfor
	endfor

End		
	
	
//======================================================================================

Function ED_SetDocumenting(panelTitle)
	string panelTitle
	
	string ChannelStatus = DC_ControlStatusListString("DA", "Check", panelTitle)
	string ChanTypeWaveNameList = DC_PopMenuStringList("DA", "Wave", panelTitle)
	
	
	ChannelStatus = DC_ControlStatusListString("TTL", "Check", panelTitle)
	ChanTypeWaveNameList = DC_PopMenuStringList("TTL", "Wave", panelTitle)
End
//======================================================================================
Function ED_HeadStageDocumenting(panelTitle)
	string panelTitle
	string DataFolderPath = HSU_DataFullFolderPathString(panelTitle)
	dfref DataFolderRef = $DataFolderPath
	
	wave /SDFR = DataFolderRef ChanAmpAssign
End
//======================================================================================
Function ED_CommentDocumenting(panelTitle)
	string panelTitle
End
//======================================================================================
/// Requested by the MAT team...
/// always create a WaveNote for each sweep that indicates the Stim Wave Name and the Stim scale factor
// a function to create waveNote tags for the stim wave name and scale factor
function ED_createWaveNoteTags(panelTitle, savedDataWaveName, SweepNo)
	string panelTitle
	string SavedDataWaveName
	Variable SweepNo

	// sweep count
	Variable sweepCount = SweepNo

	Wave/SDFR=$HSU_DataFullFolderPathString(panelTitle) ChannelClampMode

	// get all the Amp connection information
	String controlledHeadStage = DC_ControlStatusListString("DataAcq_HS", "check",panelTitle)
	// get the number of headStages...used for building up the ampSettingsWave
	variable noHeadStages = itemsinlist(controlledHeadStage, ";")

	// Location for the settings wave
	String stimSettingsWavePath
	sprintf stimSettingsWavePath, "%s:%s" Path_AmpSettingsFolder(panelTitle), "stimSettings"

	// see if the wave exists....if so, append to it...if not, create it
	wave /T /z stimSettingsWave = $stimSettingsWavePath
	//print "Does the settings wave exist?..."
	if (!WaveExists(stimSettingsWave))
		//print "making stimSettingsWave..."
		// create the 3 dimensional wave
		make /T /o /n = (1, 2, noHeadStages) $stimSettingsWavePath
		Wave /T /z stimSettingsWave = $stimSettingsWavePath
	endif

	// make the amp settings key wave
	String stimSettingsKeyPath
	sprintf stimSettingsKeyPath, "%s:%s" Path_AmpSettingsFolder(panelTitle), "stimSettingsKey"

	// see if the wave exists....if so, skip this part..if not, create it
	//print "Does the key wave exist?"
	wave/T stimSettingsKey = $stimSettingsKeyPath
	if (!WaveExists(stimSettingsKey))
		//print "making settingsKey Wave...."
		// create the 2 dimensional wave
		make /T /o  /n = (3, 2) $stimSettingsKeyPath
		Wave/T /z stimSettingsKey = $stimSettingsKeyPath

		// Row 0: Parameter
		// Row 1: Units
		// Row 2: Tolerance factor

		// Add dimension labels to the stimSettingsKey wave
		SetDimLabel 0, 0, Parameter, stimSettingsKey
		SetDimLabel 0, 1, Units, stimSettingsKey
		SetDimLabel 0, 2, Tolerance, stimSettingsKey

		// And now populate the wave
		stimSettingsKey[0][0] =  "Stim Wave Name"
		stimSettingsKey[1][0] =  ""
		stimSettingsKey[2][0] =  ""

		stimSettingsKey[0][1] =   "Stim Scale Factor"
		stimSettingsKey[1][1] =  ""
		stimSettingsKey[2][1] =  ""
	endif

	string stimWaveName
	variable stimScaleFactor
	string getWaveNameString
	string getStimScaleString
	string getDACheckBoxString
	variable checkBoxState

	// Now populate the Settings Wave
	// first...determine if the head stage is being controlled
	variable headStageControlledCounter
	for(headStageControlledCounter = 0;headStageControlledCounter < noHeadStages ;headStageControlledCounter += 1)
		// build up the string to get the DA check box to see if the DA is enabled
		sprintf getDACheckBoxString, "Check_DA_0%d" headStageControlledCounter
		checkBoxState = GetCheckBoxState(panelTitle, getDACheckBoxString)
		if (checkBoxState == 1)		// Only make the waveNote if the DA is enabled
		// build up the string to get the waveName
			sprintf getWaveNameString, "Wave_DA_0%d" headStageControlledCounter
			// get the stimWaveName
			stimWaveName = GetPopupMenuString(panelTitle, getWaveNameString)
			// build up the string to get the scale factor
			sprintf getStimScaleString, "Scale_DA_0%d" headStageControlledCounter
			// get the scale factor
			stimScaleFactor = GetSetVariable(panelTitle, getStimScaleString)

			// Save that into the stimSettingsWave
			stimSettingsWave[0][0][headStageControlledCounter] = stimWaveName
			stimSettingsWave[0][1][headStageControlledCounter] = num2str(stimScaleFactor)
		endif
	endfor

	// now call the function that will create the wave notes
//	print "calling createWaveNotes..."
	ED_createTextNotes(stimSettingsWave, stimSettingsKey, SavedDataWaveName, SweepCount, panelTitle)

End
