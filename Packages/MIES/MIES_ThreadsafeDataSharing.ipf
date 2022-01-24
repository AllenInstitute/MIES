#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_TSDS
#endif

/// @file MIES_ThreadsafeDataSharing.ipf
///
/// @brief Helper functions for accessing global objects from all threads

#if IgorVersion() >= 9.0

threadsafe Function TSDS_Write(string name, [variable var])
	ASSERT_TS(!ParamIsDefault(var), "Missing var parameter")
	ASSERT_TS(!IsEmpty(name), "name can not be empty")

	TUFXOP_Init/N=name/Z
	TUFXOP_GetStorage/N=name/Z wv

	Make/FREE/N=(1)/D data = var
	wv[0] = data
End

threadsafe Function TSDS_ReadVar(string name, [variable defValue, variable create])
	ASSERT_TS(!IsEmpty(name), "name can not be empty")

	if(ParamIsDefault(defValue))
		defValue = NaN
	endif

	if(ParamIsDefault(create))
		create = 0
	else
		create = !!create
	endif

	WAVE/Z data = TSDS_Read(name)

	if(!WaveExists(data))
		if(create)
			TSDS_Write(name, var = defValue)
		endif

		return defValue
	endif

	return data[0]
End

threadsafe static Function/WAVE TSDS_Read(string name)
	TUFXOP_GetStorage/Q/N=name/Z wv

	if(V_flag)
		return $""
	endif

	if(!WaveExists(wv) || !IsWaveRefWave(wv) || DimSize(wv, ROWS) != 1)
		return $""
	endif

	WAVE/Z data = wv[0]

	if(!WaveExists(data) || !IsNumericWave(data) || DimSize(wv, ROWS) != 1)
		return $""
	endif

	return data
End

#endif
