#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_TS
#endif

/// @file MIES_ThreadsafeUtilities.ipf
/// @brief __TS__ Helper functions for threadsafe code and main/worker function interactions.

/// @brief Return the newest variable named `varName` from the thread queue
///
/// Throws away anything else in the datafolder from the thread queue.
threadsafe Function TS_GetNewestFromThreadQueue(tgID, varName)
	variable tgID
	string varName

	variable var = NaN

	ASSERT_TS(!isEmpty(varName), "varName must not be empty")

	for(;;)
		DFREF dfr = ThreadGroupGetDFR(tgID, 0)

		if(!DataFolderExistsDFR(dfr))
			if(IsFinite(var))
				return var
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
