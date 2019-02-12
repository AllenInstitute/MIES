#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_FFI
#endif

/// @file MIES_ForeignFunctionInterface.ipf
/// @brief __FFI__ ACQ4 accessible functions

///@brief Function to return Peak Resistance, Steady State Resistance to ACQ4 (Neurophysiology Acquisition and Analysis System.
/// See http://acq4.org/ for more details)
///
///The function will pull the values (PeakResistance, SteadyStateResistance, and TimeStamp) out of
///the TP storage wave and put them in a 3x8 wave, in a designated location where ACQ4 can then find them
Function/WAVE FFI_ReturnTPValues()
	string lockedDevList
	variable noLockedDevs
	variable n
	string currentPanel
	variable tpCycleCount

	//Get the active panelTitle
	// get the da_ephys panel names
	lockedDevList=GetListOfLockedDevices()
	noLockedDevs=ItemsInList(lockedDevList)

	// Create the wave to hold values that will be queried by the ACQ4 process
	Wave acqStorageWave=GetAcqTPStorage()

	// put the list of locked devices in the wave note
	NOTE/K acqStorageWave, "LockedDevToWvLayerMapping:" + lockedDevList

	for(n=0; n<noLockedDevs; n+= 1)
		currentPanel=StringFromList(n, lockedDevList)

		// Get the tpStorageWave
		Wave tpStorageWave=GetTPStorage(currentPanel)

		//we want the last row of the column in question
		tpCycleCount = GetNumberFromWaveNote(tpStorageWave, NOTE_INDEX) // used to pull most recent values from TP

		//make sure we get a valid TPCycleCount value
		if (TPCycleCount == 0)
			return $""	
		endif

		acqStorageWave[%PeakResistance][][n]        = tpStorageWave[tpCycleCount-1][q][%PeakResistance]
		acqStorageWave[%SteadyStateResistance][][n] = tpStorageWave[tpCycleCount-1][q][%SteadyStateResistance]
		acqStorageWave[%TimeStamp][][n]             = tpStorageWave[tpCycleCount-1][q][%TimeStamp]
	endfor

	return acqStorageWave
End
