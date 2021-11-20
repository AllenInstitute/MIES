#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_OOD
#endif

/// @file MIES_OptimzedOverlapDistributedAcquisition.ipf
/// @brief __OOD__ This file holds functions related to oodDAQ.

/// Signal threshold level in parts of dynamic range above minimum
/// @sa OOD_GetThresholdLevel()
static Constant OOD_SIGNAL_THRESHOLD = 0.1

/// @brief returns the threshold level for ood region detection from a single column stimset
/// @param[in] stimset 1d wave containing stimset data
/// @return threshold level defining signal above baseline
static Function OOD_GetThresholdLevel(stimset)
	WAVE stimset

	variable minVal, maxVal

	[minVal, maxVal] = WaveMinAndMaxWrapper(stimset)
	return minVal + (maxVal - minVal) * OOD_SIGNAL_THRESHOLD
End

/// @brief retrieves regions with signal from a 1D data wave, used for stimsets
/// @param[in] stimset 1D wave containing stimset data
/// @param[in] prePoints oodDAQ pre delay in points the regions get expanded at the rising edge
/// @param[in] postPoints oodDAQ post delay in points the regions get expanded at the falling edge
/// @return 2D wave with region information
static Function/WAVE OOD_GetRegionsFromStimset(stimset, prePoints, postPoints)
	WAVE stimset
	variable prePoints, postPoints

	variable size, level, expectFalling, position, rIndex

	size = DimSize(stimset, ROWS)

	level = OOD_GetThresholdLevel(stimset)
	Make/FREE/D/N=(MINIMUM_WAVE_SIZE, 2) regions
	SetDimLabel COLS, 0, STARTPOINT, regions
	SetDimLabel COLS, 1, ENDPOINT, regions

	for(;;)
		FindLevel/Q/P/R=[position] stimSet, level

		if(V_flag)

			if(expectFalling)
				regions[rIndex][%ENDPOINT] = size
				rIndex += 1
			endif
			break

		endif

		position = ceil(V_levelx)

		if(V_rising)

			EnsureLargeEnoughWave(regions, minimumSize = rIndex + 1)
			regions[rIndex][%STARTPOINT] = max(position - prePoints, 0)

		else

			if(!expectFalling)
				EnsureLargeEnoughWave(regions, minimumSize = rIndex + 1)
				regions[rIndex][%STARTPOINT] = 0
			endif
			regions[rIndex][%ENDPOINT] = min(position + postPoints, size)
			rIndex += 1

		endif

		expectFalling = V_rising

	endfor
	Redimension/N=(rIndex, -1) regions

	return regions
End

/// @brief Reduces a 2D region wave by joining overlapping regions to one
/// @param[in] regions 2D wave containing region data
/// @return 2D wave with compacted regions
static Function/WAVE OOD_CompactRegions(regions)
	WAVE regions

	variable regionNr, size, rIndex, endPoint, startPoint

	size = DimSize(regions, ROWS)
	if(size < 2)
		return regions
	endif

	Make/FREE/D/N=(size, 2) regionsComp
	SetDimLabel COLS, 0, STARTPOINT, regionsComp
	SetDimLabel COLS, 1, ENDPOINT, regionsComp

	regionsComp[0][%STARTPOINT] = regions[0][%STARTPOINT]
	endPoint = regions[0][%ENDPOINT]
	for(regionNr = 1; regionNr < size; regionNr += 1)
		startPoint = regions[regionNr][%STARTPOINT]
		if(startPoint <= endPoint)
			endPoint = regions[regionNr][%ENDPOINT]
		else
			regionsComp[rIndex][%ENDPOINT] = endPoint
			rIndex += 1
			regionsComp[rIndex][%STARTPOINT] = startPoint
			endPoint = regions[regionNr][%ENDPOINT]
		endif
	endfor
	regionsComp[rIndex][%ENDPOINT] = endPoint

	Redimension/N=(rIndex + 1, -1) regionsComp

	return regionsComp
End

/// @brief generates regions data waves from stimsets taking the pre and post delay into account
/// @param[in] params OOdDAQParams structure
/// @return wave reference wave holding the 2D region waves for each stimset
static Function/WAVE OOD_GetRegionsFromStimsets(params)
	STRUCT OOdDAQParams &params

	variable stimsetNr, numSets, stimsetCol
	variable level, expectRising, position

	numSets = DimSize(params.stimSets, ROWS)
	Make/FREE/WAVE/N=(numSets) regions
	WAVE/WAVE singleColumnStimsets = DeepCopyWaveRefWave(params.stimSets, dimension=COLS, indexWave=params.setColumns)

	regions[] = OOD_CompactRegions(OOD_GetRegionsFromStimset(singleColumnStimsets[p], params.preFeaturePoints, params.postFeaturePoints))

	return regions
End

/// @brief returns a 1D wave with regions as lists from the input regions waves, is used for the LNB
/// @param[in] setRegions wave reference wave of 2D region waves
/// @param[in] offsets offset wave storing the offsets per stimset
/// @return 1D text wave with lists of regions
static Function/WAVE OOD_GetFeatureRegions(setRegions, offsets)
	WAVE/WAVE setRegions
	WAVE offsets

	string list
	variable setNr, regNr, regCnt
	variable numSets = DimSize(setRegions, ROWS)

	Make/FREE/T/N=(numSets) lists
	for(setNr = 0; setNr < numSets; setNr += 1)
		WAVE region = setRegions[setNr]
		regCnt = DimSize(region, ROWS)

		list = ""
		for(regNr = 0; regNr < regCnt; regNr += 1)
			list = OOD_AddToRegionList(region[regNr][%STARTPOINT] + offsets[setNr], region[regNr][%ENDPOINT] + offsets[setNr], list)
		endfor
		lists[setNr] = list
	endfor

	return lists
End

/// @brief Calculates offsets for each stimset for OOD
///
/// @param[in]      setRegions wave reference wave of 2D region waves for each stimset
/// @param[in, out] baseRegions 2D region wave that contains initial reserved regions,
///                 e.g. when using with yoking the caller function can preload from the previous device
///                 For the lead device where no previous regions are reserved, the wave can be 1D but must have zero rows
/// @param[in]      yoked 1 if yoked operation, 0 if not
///
/// @return 1D wave with offsets for each stimset in points
static Function/WAVE OOD_CalculateOffsets(setRegions, baseRegions, yoked)
	WAVE/WAVE setRegions
	WAVE &baseRegions
	variable yoked

	variable setNr, regNr, regCnt, baseRegCnt, baseRegNr, newOff, resAdjust
	variable bStart, bEnd, rStart, rEnd, noInitialRegion, overlap
	variable numSets = DimSize(setRegions, ROWS)

	yoked = !!yoked

	Make/FREE/D/N=(numSets) offsets

	if(DimSize(baseRegions, ROWS) == 0)
		Duplicate/FREE setRegions[0], baseRegions
		noInitialRegion = 1
	endif

	for(setNr = noInitialRegion; setNr < numSets; setNr += 1)

		baseRegCnt = DimSize(baseRegions, ROWS)
		WAVE regions = setRegions[setNr]
		regCnt = DimSize(regions, ROWS)

		offsets[setNr] = offsets[setNr - 1]
		do
			overlap = 0
			for(baseRegNr = 0; baseRegNr < baseRegCnt; baseRegNr += 1)

				bStart = baseRegions[baseRegNr][%STARTPOINT]
				bEnd   = baseRegions[baseRegNr][%ENDPOINT]
				newOff = 0
				for(regNr = 0; regNr < regCnt; regNr += 1)
					rStart = regions[regNr][%STARTPOINT] + offsets[setNr]
					rEnd   = regions[regNr][%ENDPOINT]   + offsets[setNr]

					if(bEnd <= rStart)
						break
					elseif(rEnd <= bStart)
						continue
					elseif(bStart < rEnd && rStart < bEnd)
						newOff = max(newOff, bEnd - rStart)
					endif
				endfor
				offsets[setNr] += newOff
				overlap = overlap | newOff
			endfor
		while(overlap)

		if(yoked || setNr < numSets - 1)
			Redimension/N=(baseRegCnt + regCnt, -1) baseRegions
			baseRegions[baseRegCnt,][] = regions[p - baseRegCnt][q] + offsets[setNr]
			SortColumns/KNDX={0} sortWaves={baseRegions}
			WAVE baseRegions1 = OOD_CompactRegions(baseRegions)
			WAVE baseRegions = baseRegions1
		endif
	endfor

	return offsets
End

/// @brief Calculated the offsets for normal acquisition and yoked mode
/// @param[in] device title of the device panel
/// @param[in] params     OOdDAQParams structure with oodDAQ setup data
static Function OOD_CalculateOffsetsYoked(device, params)
	string device
	STRUCT OOdDAQParams &params

	variable resolution

	WAVE setRegions = OOD_GetRegionsFromStimsets(params)
	Make/FREE/N=0 preload

	// normal acquisition
	if(!DeviceHasFollower(device) && !DeviceIsFollower(device))
		WAVE params.offsets = OOD_CalculateOffsets(setRegions, preload, 0)

	else

		if(DeviceHasFollower(device))
			KillOrMoveToTrash(dfr=GetDistDAQFolder())
		elseif(DeviceIsFollower(device))
			OOD_LoadPreload(device, params)
		else
			ASSERT(0, "Impossible case")
		endif

		WAVE params.offsets = OOD_CalculateOffsets(setRegions, preload, 1)
		OOD_StorePreload(device, preload)
	endif
	WAVE/T params.regions = OOD_GetFeatureRegions(setRegions, params.offsets)
	WAVE params.preload = preload

#if defined(DEBUGGING_ENABLED)
	if(DP_DebuggingEnabledForCaller())
		OOD_Debugging(params)
	endif
#endif

End

/// @brief Load the preload data into `params.preload`
/// @param[in] device title of the device panel
/// @param[in] params     OOdDAQParams structure where the data is preloaded into
static Function OOD_LoadPreload(device, params)
	string device
	STRUCT OOdDAQParams &params

	DFREF dfr = GetDistDAQFolder()
	WAVE params.preload = GetDistDAQPreloadWave(device)
End

/// @brief Store the preload data so that the next device can use it.
/// @param[in] device title of the device panel
/// @param[in] preload    wave that is stored containing the preload data
static Function OOD_StorePreload(device, preload)
	string device
	WAVE preload

	string deviceNumberStr, deviceType, panelTitleNext
	variable deviceNumber

	ParseDeviceString(device, deviceType, deviceNumberStr)
	deviceNumber = str2num(deviceNumberStr) + 1
	panelTitleNext = HW_ITC_BuildDeviceString(deviceType, num2str(deviceNumber))

	WAVE preloadPerm = GetDistDAQPreloadWave(panelTitleNext)

	Duplicate/O preload, preloadPerm
End

/// @brief Return a list with `$first-$last` added at the end with `;` as separator
/// @param[in] first sample point number in wavebuilder scale with start of region
/// @param[in] last sample point number in wavebuilder scale with end of region
/// @param[in] list list string where the element is added
/// @return list string with added element
static Function/S OOD_AddToRegionList(first, last, list)
	variable first, last
	string list

	string str

	sprintf str, "%g-%g", first * WAVEBUILDER_MIN_SAMPINT, last * WAVEBUILDER_MIN_SAMPINT

	return AddListItem(str, list, ";", INF)
End

/// @brief Prints various internals useful for oodDAQ debugging, called when DEBUGGING_ENABLED is set
/// @param[in] params OOdDAQParams structure with oodDAQ internals
static Function OOD_Debugging(params)
	STRUCT OOdDAQParams &params

	variable i, numSets

	numSets = DimSize(params.stimSets, ROWS)

	DFREF dfr = GetUniqueTempPath()

	WAVE/WAVE stimSetsSingleColumn = DeepCopyWaveRefWave(params.stimSets, dimension=COLS, indexWave=params.setColumns)

	Duplicate params.offsets, dfr:offsets

	WAVE/WAVE wv = OOD_CreateStimSet(params)
	for(i = 0; i < numSets; i += 1)
		Duplicate wv[i], dfr:$("stimSetAndOffset" + num2str(i))/Wave=result
		CopyScales/P params.stimSets[i], result

		Duplicate stimSetsSingleColumn[i], dfr:$("stimSet" + num2str(i))/Wave=stimSetCopy
		CopyScales/P params.stimSets[i], stimSetCopy
	endfor

	printf "Optimized overlap dDAQ generation placed waves in %s\r", GetDataFolder(1, dfr)
	printf "params\r"
	print params
	printf "offsets\r"
	print params.offsets
	printf "regions\r"
	print params.regions
	printf "setColumns\r"
	print params.setColumns
	printf "preload\r"
	print params.preload
End

/// @brief Return the oodDAQ optimized stimsets
///
/// The offsets and the regions are returned in `params` and all results are
/// cached.
///
/// @param[in] device title of the device panel
/// @param[in] params     OOdDAQParams structure with the initial settings
/// @return one dimensional numberic wave with the offsets in points for each stimset
Function/WAVE OOD_GetResultWaves(device, params)
	string device
	STRUCT OOdDAQParams &params

	string key

	key = CA_DistDAQCreateCacheKey(params)

	WAVE/WAVE/Z cache = CA_TryFetchingEntryFromCache(key)

	if(WaveExists(cache))
		WAVE params.offsets = cache[%offsets]
		WAVE/T params.regions = cache[%regions]
		return cache[%stimSetsWithOffset]
	endif

	OOD_CalculateOffsetsYoked(device, params)
	WAVE stimSetsWithOffset = OOD_CreateStimSet(params)

	Make/FREE/WAVE/N=3 cache
	SetDimLabel ROWS, 0, offsets, cache
	SetDimLabel ROWS, 1, regions, cache
	SetDimLabel ROWS, 2, stimSetsWithOffset, cache

	cache[%offsets] = params.offsets
	cache[%regions] = params.regions
	cache[%stimSetsWithOffset] = stimSetsWithOffset

	CA_StoreEntryIntoCache(key, cache)

	return stimSetsWithOffset
End

/// @brief Generate a stimset for "overlapped dDAQ" from the calculated offsets
///        by OOD_CalculateOffsets().
///
/// @param[in] params OOdDAQParams structure with the stimsets and offset information
///
/// @return stimsets with offsets, one wave per offset
static Function/Wave OOD_CreateStimSet(params)
	STRUCT OOdDAQParams &params

	variable i, numSets, length
	variable offset, cutoff, column
	variable level = 1e-3

	numSets = DimSize(params.stimSets, ROWS)
	ASSERT(numSets == DimSize(params.offsets, ROWS), "Mismatched offsets wave size")

	Make/WAVE/FREE/N=(numSets) stimSetsWithOffset

	for(i = 0; i < numSets ; i += 1)
		WAVE stimSet = params.stimSets[i]
		offset = params.offsets[i]
		ASSERT(offset >= 0 , "Invalid offset")
		length = DimSize(stimSet, ROWS) + offset
		column = params.setColumns[i]
		Make/FREE/N=(length) acc

		Multithread acc[offset, *] = stimSet[p - offset][column]
		CopyScales/P stimSet, acc
		Note acc, note(stimSet)

		// remove empty space beyond `postFeatureTime` at the end
		FindLevel/P/EDGE=2/Q/R=[DimSize(acc, ROWS) - 1, 0] acc, level

		if(!V_flag && acc[length - 1] < level)
			cutoff = V_levelX + params.postFeaturePoints
			Redimension/N=(cutoff) acc
		endif

		stimSetsWithOffset[i] = acc
	endfor

	return stimSetsWithOffset
End
