#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_MIESUTILS_BACKUPWAVES
#endif // AUTOMATED_TESTING

/// @file MIES_MiesUtilities_BackupWaves.ipf
/// @brief This file holds MIES utility functions for wave backup

/// @brief Looks for backup waves in the datafolder and recreates the original waves from them.
///        The original waves do not need to be present. If present they are overwritten.
///        This is different to @ref RestoreFromBackupWavesForAll, where the original waves need
///        to be existing.
Function RestoreFromBackupWavesForAll(DFREF dfr)

	variable i, numWaves
	string origWaveName, wName

	numWaves = CountObjectsDFR(dfr, COUNTOBJECTS_WAVES)
	for(i = 0; i < numWaves; i += 1)
		wName = GetIndexedObjNameDFR(dfr, COUNTOBJECTS_WAVES, i)
		WAVE/SDFR=dfr wv = $wName
		if(!StringEndsWith(NameOfWave(wv), WAVE_BACKUP_SUFFIX))
			continue
		endif
		origWaveName = RemoveEnding(wName, WAVE_BACKUP_SUFFIX)
		WAVE/Z wvOrig = dfr:$origWaveName
		KillOrMoveToTrash(wv = wvOrig)
		Duplicate wv, dfr:$origWaveName
	endfor
End

/// @brief Create backup waves for all waves in the datafolder
threadsafe Function CreateBackupWavesForAll(DFREF dfr)

	variable i, numWaves

	numWaves = CountObjectsDFR(dfr, COUNTOBJECTS_WAVES)
	for(i = 0; i < numWaves; i += 1)
		WAVE/SDFR=dfr wv = $GetIndexedObjNameDFR(dfr, COUNTOBJECTS_WAVES, i)
		CreateBackupWave(wv)
	endfor
End

threadsafe static Function/S GetBackupNameOfWave(WAVE wv)

	return NameOfWave(wv) + WAVE_BACKUP_SUFFIX
End

threadsafe Function/WAVE GetBackupWave_TS(WAVE wv)

	DFREF           dfr    = GetWavesDataFolderDFR(wv)
	WAVE/Z/SDFR=dfr backup = $GetBackupNameOfWave(wv)

	return backup
End

/// @brief Create a backup of the wave wv if it does not already
/// exist or if `forceCreation` is true.
///
/// The backup wave will be located in the same data folder and
/// its name will be the original name with #WAVE_BACKUP_SUFFIX
/// appended. If the backup wave exists and the main type of the backup wave can be overridden by Duplicate/O
/// then the wave reference of the backup wave is kept. Otherwise the main type is changed and the wave reference
/// is not kept (e.g. backup wave is numerical, original wave is text)
threadsafe Function/WAVE CreateBackupWave(WAVE wv, [variable forceCreation])

	string backupname

	ASSERT_TS(IsGlobalWave(wv), "Wave Can Not Be A Null Wave Or A Free Wave")

	if(ParamIsDefault(forceCreation))
		forceCreation = 0
	else
		forceCreation = !!forceCreation
	endif

	WAVE/Z backup = GetBackupWave_TS(wv)

	if(WaveExists(backup) && !forceCreation)
		return backup
	endif
	if(WaveExists(backup) && WaveType(backup, 1) != WaveType(wv, 1) && (WaveType(backup, 1) == IGOR_TYPE_TEXT_WAVE || WaveType(wv, 1) == IGOR_TYPE_TEXT_WAVE))
		KillOrMoveToTrash(wv = backup)
	endif

	backupname = GetBackupNameOfWave(wv)
	DFREF dfr = GetWavesDataFolderDFR(wv)

	Duplicate/O wv, dfr:$backupname/WAVE=backup

	return backup
End

/// @brief Return a wave reference to the possibly not existing backup wave
Function/WAVE GetBackupWave(WAVE wv)

	string backupname

	ASSERT(IsGlobalWave(wv), "Wave Can Not Be A Null Wave Or A Free Wave")

	backupname = NameOfWave(wv) + WAVE_BACKUP_SUFFIX
	DFREF dfr = GetWavesDataFolderDFR(wv)

	WAVE/Z/SDFR=dfr backup = $backupname

	return backup
End

/// @brief Replace all waves from the datafolder with their backup
Function ReplaceWaveWithBackupForAll(DFREF dfr)

	variable numWaves, i

	numWaves = CountObjectsDFR(dfr, COUNTOBJECTS_WAVES)
	for(i = 0; i < numWaves; i += 1)
		WAVE/SDFR=dfr wv = $GetIndexedObjNameDFR(dfr, COUNTOBJECTS_WAVES, i)
		ReplaceWaveWithBackup(wv, nonExistingBackupIsFatal = 0, keepBackup = 1)
	endfor
End

/// @brief Replace the wave wv with its backup. If possible the backup wave will be killed afterwards.
///        If the backup wave exists then the wave reference of the restored wave stays the same.
///        Thus the returned wave reference equals the wv wave reference.
///
/// @param wv                       wave to replace by its backup
/// @param nonExistingBackupIsFatal [optional, defaults to true] behaviour for the case that there is no backup.
///                                 Passing a non-zero value will abort if the backup wave does not exist, with
///                                 zero it will just do nothing.
/// @param keepBackup               [optional, defaults to false] don't delete the backup after restoring from it
/// @returns wave reference to the restored data, in case of no backup an invalid wave reference
Function/WAVE ReplaceWaveWithBackup(WAVE wv, [variable nonExistingBackupIsFatal, variable keepBackup])

	if(ParamIsDefault(nonExistingBackupIsFatal))
		nonExistingBackupIsFatal = 1
	else
		nonExistingBackupIsFatal = !!nonExistingBackupIsFatal
	endif

	if(ParamIsDefault(keepBackup))
		keepBackup = 0
	else
		keepBackup = !!keepBackup
	endif

	WAVE/Z backup = GetBackupWave(wv)

	if(!WaveExists(backup))
		if(nonExistingBackupIsFatal)
			DoAbortNow("Backup wave does not exist")
		endif

		return $""
	endif

	Duplicate/O backup, wv

	if(!keepBackup)
		KillOrMoveToTrash(wv = backup)
	endif

	return wv
End
