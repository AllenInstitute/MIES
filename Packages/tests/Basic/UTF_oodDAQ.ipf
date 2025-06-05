#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1
#pragma ModuleName       = TESTOODDAQ

/// @{
/// oodDAQ regression tests

static Function oodDAQStore_IGNORE(WAVE/WAVE stimset, WAVE offsets, WAVE regions, variable index)

	variable i

	DFREF dfr = root:oodDAQ

	for(i = 0; i < DimSize(stimset, ROWS); i += 1)
		WAVE singleStimset = stimset[i]
		Duplicate/O singleStimset, dfr:$("stimset_oodDAQ_" + num2str(index) + "_" + num2str(i))
	endfor

	Duplicate/O offsets, dfr:$("offsets_" + num2str(index))
	Duplicate/O regions, dfr:$("regions_" + num2str(index))
End

static Function/WAVE GetoodDAQ_RefWaves_IGNORE(variable index)

	variable i

	Make/FREE/WAVE/N=(64, 3) wv

	SetDimLabel COLS, 0, stimset, wv
	SetDimLabel COLS, 1, offset, wv
	SetDimLabel COLS, 2, region, wv

	DFREF dfr = root:oodDAQ

	for(i = 0; i < DimSize(wv, ROWS); i += 1)
		WAVE/Z/SDFR=dfr ref_stimset = $("stimset_oodDAQ_" + num2str(index) + "_" + num2str(i))

		if(!WaveExists(ref_stimset))
			break
		endif

		wv[i][%stimset] = ref_stimset
	endfor

	WAVE/Z/SDFR=dfr ref_offsets = $("offsets_" + num2str(index))
	WAVE/Z/SDFR=dfr ref_regions = $("regions_" + num2str(index))

	wv[0][%offset] = ref_offsets
	wv[0][%region] = ref_regions

	return wv
End

Function oodDAQRegTests_0()

	variable            index
	STRUCT OOdDAQParams params
	DFREF  dfr           = root:oodDAQ
	string device        = "ITC18USB_Dev_0"
	WAVE   singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 0
	InitOOdDAQParams(params, stimSet, {0, 0}, 0, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(device, params)

	//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_1()

	variable            index
	STRUCT OOdDAQParams params
	DFREF  dfr           = root:oodDAQ
	string device        = "ITC18USB_Dev_0"
	WAVE   singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 1
	InitOOdDAQParams(params, stimSet, {1, 0}, 0, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(device, params)

	//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_2()

	variable            index
	STRUCT OOdDAQParams params
	DFREF  dfr           = root:oodDAQ
	string device        = "ITC18USB_Dev_0"
	WAVE   singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 2
	InitOOdDAQParams(params, stimSet, {0, 1}, 0, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(device, params)

	//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_3()

	variable            index
	STRUCT OOdDAQParams params
	DFREF  dfr           = root:oodDAQ
	string device        = "ITC18USB_Dev_0"
	WAVE   singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 3
	InitOOdDAQParams(params, stimSet, {0, 0}, 20, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(device, params)

	//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_4()

	variable            index
	STRUCT OOdDAQParams params
	DFREF  dfr           = root:oodDAQ
	string device        = "ITC18USB_Dev_0"
	WAVE   singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 4
	InitOOdDAQParams(params, stimSet, {0, 0}, 0, 20)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(device, params)

	//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_5()

	variable            index
	STRUCT OOdDAQParams params
	DFREF  dfr           = root:oodDAQ
	string device        = "ITC18USB_Dev_0"
	WAVE   singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 5
	InitOOdDAQParams(params, stimSet, {0, 0}, 0, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(device, params)

	//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_6()

	variable            index
	STRUCT OOdDAQParams params
	DFREF  dfr           = root:oodDAQ
	string device        = "ITC18USB_Dev_0"
	WAVE   singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=2/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 6
	InitOOdDAQParams(params, stimSet, {0, 1}, 20, 30)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(device, params)

	//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

Function oodDAQRegTests_7()

	variable            index
	STRUCT OOdDAQParams params
	DFREF  dfr           = root:oodDAQ
	string device        = "ITC18USB_Dev_0"
	WAVE   singleStimset = root:oodDAQ:input:StimSetoodDAQ_DA_0
	Make/FREE/N=3/WAVE stimset = singleStimset

	// BEGIN CHANGE ME
	index = 7
	InitOOdDAQParams(params, stimSet, {0, 0, 0}, 0, 0)
	// END CHANGE ME

	WAVE/WAVE stimSet = OOD_GetResultWaves(device, params)

	//	oodDAQStore_IGNORE(stimSet, params.offsets, params.regions, index)
	WAVE/WAVE refWave = GetoodDAQ_RefWaves_IGNORE(index)
	CHECK_EQUAL_WAVES(refWave[0][%stimset], stimset[0])
	CHECK_EQUAL_WAVES(refWave[1][%stimset], stimset[1])
	CHECK_EQUAL_WAVES(refWave[2][%stimset], stimset[2])
	CHECK_EQUAL_WAVES(refWave[0][%offset], params.offsets)
	CHECK_EQUAL_WAVES(refWave[0][%region], params.regions)
End

/// @}
