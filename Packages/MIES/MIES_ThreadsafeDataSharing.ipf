#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_TSDS
#endif

/// @file MIES_ThreadsafeDataSharing.ipf
///
/// @brief Helper functions for accessing global objects from all threads

/// @brief Creates/Overwrites a threadstorage and puts a numerical value in
threadsafe static Function TSDS_Create(string name, variable var)

	ASSERT_TS(!IsEmpty(name), "name can not be empty")

	TUFXOP_Init/Z/N=name
	TUFXOP_GetStorage/Z/N=name wv

	Make/FREE/D data = {var}
	wv[0] = data
End

/// @brief Reads a numerical value from a threadstorage
///
/// @param name     name of threadstorage
/// @param defValue [optional: default NaN] default value used when storage is created, create flag must be set
/// @param create   [optional: default 0] when set the threadstorage is created if it did not exist or had an incompatible format, defValue must be given
threadsafe Function TSDS_ReadVar(string name, [variable defValue, variable create])

	variable argCheck = ParamIsDefault(defValue) + ParamIsDefault(create)
	ASSERT_TS(argCheck == 2 || argCheck == 0, "defaul value and create must be either both set or both default.")
	ASSERT_TS(!IsEmpty(name), "name can not be empty")

	defValue = ParamIsDefault(defValue) ? NaN : defValue
	create   = ParamIsDefault(create) ? 0 : !!create

	WAVE/Z data = TSDS_Read(name)
	if(WaveExists(data) && IsNumericWave(data) && DimSize(data, ROWS) == 1)
		return data[0]
	endif

	ASSERT_TS(create == 1, "Error reading from threadstorage:" + name)

	TSDS_Create(name, defValue)

	return defValue
End

/// @brief Reads a single wave ref wave from a named threadstorage
threadsafe static Function/WAVE TSDS_Read(string name)

	TUFXOP_GetStorage/Q/N=name/Z wv
	if(!V_flag && WaveExists(wv) && IsWaveRefWave(wv) && DimSize(wv, ROWS) == 1)
		return wv[0]
	endif

	return $""
End

/// @brief Writes a numerical value to a threadstorage, if the threadstorage does not exist it is automatically created.
///
/// @param name   name of threadstorage
/// @param var    numerical value that should be written
/// @returns 0 if write was successful, 1 if write was not successful
threadsafe Function TSDS_WriteVar(string name, variable var)

	ASSERT_TS(!IsEmpty(name), "name can not be empty")

	WAVE/Z data = TSDS_Read(name)
	if(WaveExists(data) && IsNumericWave(data) && DimSize(data, ROWS) == 1)
		data[0] = var

		return NaN
	endif

	TSDS_Create(name, var)
End
