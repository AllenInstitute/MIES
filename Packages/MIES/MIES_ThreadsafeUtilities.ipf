#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_TS
#endif

static Constant TS_GET_REPEAT_TIMEOUT_IN_MS = 1

/// @file MIES_ThreadsafeUtilities.ipf
/// @brief __TS__ Helper functions for threadsafe code and main/worker function interactions.

/// @brief Return the newest variable named `varName` from the thread queue
///
/// Return `NaN` if the thread is not running anymore.
///
/// Throws away anything else in the datafolder from the thread queue.
Function TS_GetNewestFromThreadQueue(tgID, varName)
	variable tgID
	string varName

	variable var = NaN
	variable err

	ASSERT_TS(!isEmpty(varName), "varName must not be empty")

	if(IsNaN(tgID))
		return NaN
	endif

	for(;;)
		try
			DFREF dfr = ThreadGroupGetDFR(tgID, TS_GET_REPEAT_TIMEOUT_IN_MS); AbortOnRTE
		catch
			err = GetRTError(1)
			return NaN
		endtry

		if(!DataFolderExistsDFR(dfr))
			if(IsFinite(var))
				return var
			elseif(TS_ThreadGroupFinished(tgID))
				return NaN
			else
				continue
			endif
		endif

		NVAR/Z/SDFR=dfr var_thread = $varName

		ASSERT_TS(NVAR_Exists(var_thread), "Expected variable from thread does not exist: " + varName)

		// overwrite old values
		var = var_thread
	endfor

	return var
End

/// @brief Return the newest variables from the thread queue
///
/// The function returns if it received at least one variable from the thread queue.
/// Return an invalid wave reference if the thread is not running anymore.
///
/// Throws away anything else in the datafolder from the thread queue.
Function/WAVE TS_GetNewestFromThreadQueueMult(tgID, varNames)
	variable tgID
	Wave/T varNames

	variable numEntries, i, oneValidEntry, err
	string varName

	ASSERT_TS(DimSize(varNames, COLS) == 0, "Expected a 1D wave")
	ASSERT_TS(IsTextWave(varNames), "Expected a text wave")

	if(IsNaN(tgID))
		return $""
	endif

	numEntries = DimSize(varNames, ROWS)
	Make/D/N=(numEntries)/FREE result = NaN

	for(i = 0; i < numEntries; i += 1)
		varName = varNames[i]
		ASSERT_TS(!isEmpty(varName), "varName must not be empty")
		SetDimLabel Rows, i, $varName, result
	endfor

	for(;;)
		try
			DFREF dfr = ThreadGroupGetDFR(tgID, TS_GET_REPEAT_TIMEOUT_IN_MS); AbortOnRTE
		catch
			err = GetRTError(1)
			return $""
		endtry

		if(!DataFolderExistsDFR(dfr))
			if(TS_ThreadGroupFinished(tgID))
				return $""
			elseif(!oneValidEntry)
				continue
			endif

			return result
		endif

		for(i = 0; i < numEntries; i += 1)
			NVAR/Z/SDFR=dfr var = $GetDimLabel(result, ROWS, i)

			if(NVAR_Exists(var))
				oneValidEntry = 1
				result[i]     = var
			endif
		endfor
	endfor

	return result
End

/// @brief Return the variable named `varName` from the thread queue or `NaN`
///        if there is none.
///
/// Throws away anything else in the datafolder from the thread queue.
threadsafe Function TS_ThreadGroupGetVariable(tgID, varName)
	variable tgID
	string varName

	ASSERT_TS(!isEmpty(varName), "varName must not be empty")

	DFREF dfr = ThreadGroupGetDFR(tgID, 0)

	if(!DataFolderExistsDFR(dfr))
		return NaN
	endif

	NVAR/Z/SDFR=dfr var = $varName

	if(!NVAR_Exists(var)) // we got something different
		return NaN
	endif

	return var
End

/// @brief Push a single variable named `varName` with value `varValue` to the
/// thread queue
threadsafe Function TS_ThreadGroupPutVariable(tgID, varName, varValue)
	variable tgID
	string varName
	variable varValue

	string datafolder

	datafolder = UniqueDataFolderName($":", "temp")
	NewDataFolder/S/O datafolder
	variable/G $varName = varValue
	ThreadGroupPutDF tgID, :
End

/// @brief Push a datafolder to the thread queue
///
/// Accepts a free datafolder for `dfr` unlike `ThreadGroupPutDF`.
threadsafe Function TS_ThreadGroupPutDFR(tgID, dfr)
	variable tgID
	DFREF dfr

	string dataFolder

	ASSERT_TS(DataFolderExistsDFR(dfr), "ThreadGroupPutDFR: dfr does not exist")

	if(DataFolderRefStatus(dfr) == 3)
		dataFolder = UniqueDataFolderName($":", "temp")
		MoveDataFolder dfr, $dataFolder
		dfr = $""
	else
		dataFolder = GetDataFolder(1, dfr)
	endif

	SetDataFolder $dataFolder
	ThreadGroupPutDF tgId, :
End

/// @brief Returns 1 if all worker threads have finished
Function TS_ThreadGroupFinished(tgID)
	variable tgID

	return !ThreadGroupWait(tgID, 0)
End
