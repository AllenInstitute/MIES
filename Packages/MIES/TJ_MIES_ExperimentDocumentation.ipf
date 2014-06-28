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

//=============================================================================================================
Function ED_createWaveNotes(incomingSettingsWave, incomingKeyWave, SaveDataWavePath, SweepCounter, panelTitle)
	wave incomingSettingsWave
	wave/T incomingKeyWave
	string saveDataWavePath
	string panelTitle
	variable SweepCounter
	
	// Location for the saved datawave
	wave saveDataWave = $saveDataWavePath
	
	// Location for the settings wave
	String settingsHistoryPath
	sprintf settingsHistoryPath, "%s:%s" Path_LabNoteBookFolder(panelTitle), "settingsHistory"
	//print "settingsHistoryPath: ", settingsHistoryPath
	
	wave/Z settingsHistory = $settingsHistoryPath
	// see if the wave exists....if so, append to it...if not, create it
	if (WaveExists($settingsHistoryPath) == 0)
		//print "creating settingsHistoryPath..."
		// create the wave...just set the dimensions to give it something to build on
		make/N = (0,0,0) $settingsHistoryPath
		Wave settingsHistory = $settingsHistoryPath
	endif
	
	// Locating for the keyWave
	String keyWavePath
	sprintf keyWavePath, "%s:%s" Path_LabNoteBookFolder(panelTitle), "keyWave"
	
	
	// see if the wave exists....if so, append to it...if not, create it
	Wave/T /Z keyWave = $keyWavePath
	if (WaveExists($keyWavePath) == 0)
		// create the wave...just set the dimensions to give it something to build on
		make /T /N=(0,0,0)  $keyWavePath
		Wave/t keyWave = $keyWavePath
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
	
	print "keyWaveSize: ", keyColCount
	print "incoming keyWave size: ", incomingKeyColCount
	variable keyMatchFound = 0
	// if keyWave is just formed, just add the incoming KeyWave....
	if (keyColCount == 0)
		//print "setting up inital keyWave..."
		// have to redimension the keyWave to create the space for the new stuff
		Redimension/N= (1, incomingKeyColCount) keyWave
		// also redimension the settings History Wave to create row space to add new sweep data...
		Redimension/N=(-1, incomingColCount, incomingLayerCount) settingsHistory
		keyWave = "#"
		//print "after key wave redimension..."
		//print "key wave row size ", DimSize(settingsHistory, 0)		// sweep
		//print "key wave col size ", DimSize(settingsHistory, 1)		// factor
		
		//print "after settings history redimension..."
		rowCount = DimSize(settingsHistory, 0)		// sweep
		//print "rowCount: ", rowCount
		colCount = DimSize(settingsHistory, 1)		// factor
		//print "colCount: ", colCount
		layerCount = DimSize(settingsHistory, 2)	// headstage-+ 	
		//print "layerCount: ", layerCount
		
		for (keyColCounter = 0; keyColCounter < incomingKeyColCount; keyColCounter += 1)
//			print "copying incomingKeyWave factor to keyWave at ", keyColCounter
//			print "incoming KeyWave factor text: ", incomingKeyWave[0][keyColCounter]
			keyWave[0][keyColCounter] = incomingKeyWave[0][keyColCounter]
//			print "after copy step, keyWaveText: ", keyWave[0][keyColCounter]			
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
	// redimension to add another row...leave the other stuff alone
	Redimension/N=((settingsRowCount + 1), -1, -1) settingsHistory
	settingsRowCount = (DimSize(settingsHistory, 0))
	//print "after the row redimension, settingsRowCount = ", settingsRowCount
	variable rowIndex = settingsRowCount -1
	//print "adding the new stuff at rowIndex: ", rowIndex
	
	// Use the keyWave to see where to add the incomingWave factors to the ampSettingsHistory wave
	for (incomingKeyColCounter = 0; incomingKeyColCounter < incomingKeyColCount; incomingKeyColCounter += 1)
		//print "doing the factor addition step at ", incomingKeyColCounter
		//print "factor: ", incomingKeyWave[0][incomingKeyColCounter]
		for (keyColCounter = 0; keyColCounter < keyColCount; keyColCounter += 1)
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
	rowIndex = rowCount - 1
	//print "rowIndex: ", rowIndex
	
	// just do this to indicate that yes, we did actually create a wave note...this will not be needed in final production version
	//Note saveDataWave "Hey Mate...we made a wave note!"
	
	if (rowCount > 1)	
		for ( colCounter = 0; colCounter < colCount; colCounter += 1)
			for (layerCounter = 0; layerCounter < layerCount; layerCounter += 1)
				settingsHistory[rowIndex][colCounter][layerCounter] = incomingSettingsWave[0][colCounter][layerCounter]
				// and then see if the factor has changed from the previous saved setting
//				print "Comparing factors..."
//				print "new setting value: ", settingsHistory[rowIndex][colCounter][layerCounter]
//				print "old setting value: ", settingsHistory[rowIndex-1][colCounter][layerCounter]
				if (settingsHistory[rowIndex][colCounter][layerCounter] != settingsHistory[rowIndex-1][colCounter][layerCounter])
					//print "Factor Changed! ", keyWave[0][colCounter]
					
					
					// build up the string for the report
					String changedFactorText
					changedFactorText = "Factor Change:Sweep#" + num2str(SweepCounter) + ":" + keyWave[0][colCounter] + ":" + num2str(settingsHistory[rowIndex][colCounter][layerCounter])
					print changedFactorText
					
					
					// make the waveNote
					//Note saveDataWave "Factor Changed!"
					//Note saveDataWave "Sweep#" + num2str(SweepCounter)
					Note saveDataWave "Factor:" + keyWave[0][colCounter]
					Note saveDataWave num2str(settingsHistory[rowIndex][colCounter][layerCounter])
					//Note saveDataWave changedFactorText
				endif
			endfor
		endfor
	endif
End			
	
	
	
	
	

