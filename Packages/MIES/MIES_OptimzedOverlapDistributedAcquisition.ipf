#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_OOD
#endif

/// @file MIES_OptimzedOverlapDistributedAcquisition.ipf
/// @brief __OOD__ This file holds functions related to oodDAQ.

static Constant OOD_BLOCK_SIZE = 1024

/// @brief Create a wave reference wave with the smeared stim sets including offsets
static Function/WAVE OOD_CreateStimSetWithSmear(params)
	STRUCT OOdDAQParams &params

	STRUCT OOdDAQParams tempParams
	tempParams = params
	WAVE tempParams.stimSets = params.stimSetsSmeared

	Duplicate/FREE params.setColumns, setColumns
	setColumns[] = 0
	WAVE tempParams.setColumns = setColumns

	WAVE/WAVE params.stimSetsSmearedAndOffset = OOD_CreateStimSet(tempParams)
End

/// @brief Generate the preload data
///
/// Preload data consists of all stimsets smeared, offsetted and summed up into
/// a 1D wave.
static Function/WAVE OOD_GeneratePreload(params)
	STRUCT OOdDAQParams &params

	variable i, numSets, maxLength, preloadLength, dataLength

	numSets = DimSize(params.stimSetsSmearedAndOffset, ROWS)
	Make/FREE/N=(numSets) lengths = DimSize(params.stimSetsSmearedAndOffset[p], ROWS)
	maxLength = WaveMax(lengths)

	if(WaveExists(params.preload))
		preloadLength = DimSize(params.preload, ROWS)
		maxLength = max(maxLength, preloadLength)
		Make/FREE/R/N=(maxLength) preload
		MultiThread preload[0, preloadLength - 1] = params.preload[p]
	else
		preloadLength = 0
		Make/FREE/R/N=(maxLength) preload
		FastOp preload = 0
	endif

	for(i = 0; i < numSets; i += 1)
		WAVE stimSet = params.stimSetsSmearedAndOffset[i]
		dataLength = DimSize(stimSet, ROWS)
		Multithread preload[0, dataLength - 1] += stimSet[p]
	endfor

	CopyScales/P stimSet, preload

	return preload
End

/// @brief Load the preload data into `params`
static Function OOD_LoadPreload(panelTitle, params)
	string panelTitle
	STRUCT OOdDAQParams &params

	DFREF dfr = GetDistDAQFolder()
	WAVE params.preload = GetDistDAQPreloadWave(panelTitle)
End

/// @brief Store the preload data so that the next device can use it.
static Function OOD_StorePreload(panelTitle, preload)
	string panelTitle
	WAVE preload

	string deviceNumberStr, deviceType, panelTitleNext
	variable deviceNumber

	ParseDeviceString(panelTitle, deviceType, deviceNumberStr)
	deviceNumber = str2num(deviceNumberStr) + 1
	panelTitleNext = BuildDeviceString(deviceType, num2str(deviceNumber))

	WAVE preloadPerm = GetDistDAQPreloadWave(panelTitleNext)

	Duplicate/O preload, preloadPerm
End

/// @brief Return a list with `$first-$last` added
static Function/S OOD_AddToRegionList(first, last, list)
	variable first, last
	string list

	string str

	sprintf str, "%g-%g", first * WAVEBUILDER_MIN_SAMPINT, last * WAVEBUILDER_MIN_SAMPINT

	return AddListItem(str, list, ";", INF)
End

/// @brief Return a text wave with a list marking the feature regions, see
/// #OOdDAQParams.regions for more info.
static Function/WAVE OOD_ExtractFeatureRegions(stimSets)
	WAVE/WAVE stimSets

	variable numSets, start, foundLevel, first, last, i, pLevel
	variable dataLength, level, minVal, maxVal
	string list, str

	numSets = DimSize(stimSets, ROWS)
	Make/FREE/T/N=(numSets) regions

	for(i = 0; i < numSets; i += 1)

		WAVE stimSet = stimSets[i]
		dataLength = DimSize(stimSet, ROWS)
		ASSERT(DimSize(stimSet, COLS) <= 1, "stimSet must be a 1D wave")

		minVal = WaveMin(stimSet)
		maxVal = WaveMax(stimSet)
		level = minVal + (maxVal - minVal) * 0.10

		list  = ""
		first = 0
		last  = NaN
		start = 0
		do
			FindLevel/Q/P/R=[start] stimSet, level
			foundLevel = !V_Flag
			pLevel     = ceil(V_levelX)

			if(!foundLevel || start >= dataLength || pLevel >= dataLength)
				break
			endif

			if(V_rising)
				first = pLevel
			else
				last  = pLevel
				ASSERT(IsFinite(first), "Expected to have found an rising edge already")
				list  = OOD_AddToRegionList(first, last, list)
				first = NaN
				last  = NaN
			endif

			start = pLevel
		while(1)

		// no falling edge as last level crossing
		if(IsFinite(first))
			last = dataLength - 1
			list = OOD_AddToRegionList(first, last, list)
		endif

		regions[i] = list
	endfor

	return regions
End

/// @brief Find the offsets for the optimized overlap dDAQ mode
///
/// Given are `n` stimsets to align.
///
/// Classic dDAQ:
/// 	- One set after another
/// 	- The sets can have vertical space in between, configured with the dDAQ delay
/// 	- Not possible to shift the sets so that they overlap
///
/// Optimized overlap dDAQ:
///    - Allow sets to overlap
///    - User determines how much space in ms (pre and post feature time) should be between various
///      features of the sets
///    - Find the total offset in points of each set which minimizes the total length of the combined
///      sets
static Function OOD_CalculateOffsets(params)
	STRUCT OOdDAQParams &params

	variable offset, i, j, numSets, maxDataLength, stimSetFeaturePos
	variable dataLength, previousOffset, step, offsetToTest, accLength, preLoadLength
	string msg, key

	numSets = DimSize(params.stimSets, ROWS)
	ASSERT(numSets >= 1, "Unexpected number of sets")

	WAVEClear params.offsets

	Make/D/FREE/N=(numSets) offsets = 0

	Make/FREE/N=(numSets) dataLengths = DimSize(params.stimSets[p], ROWS)
	maxDataLength = WaveMax(dataLengths)

	if(WaveExists(params.preload))
		preloadLength = DimSize(params.preload, ROWS)
		maxDataLength = max(maxDataLength, preLoadLength)
	endif

	accLength = (numSets + 1) * maxDataLength
	Make/FREE/R/N=(accLength) acc
	FastOp acc = 0

	WAVE smearedStimSet = params.stimSetsSmeared[0]
	// all stim sets have the same delta x
	step = 1 / DimDelta(smearedStimSet, ROWS) * params.resolution

	// try to place the i-th smearedStimset into the (i - 1)-th smearedStimset
	for(i = 0; i < numSets; i += 1)

		WAVE smearedStimSet = params.stimSetsSmeared[i]
		ASSERT(DimSize(smearedStimSet, COLS) <= 1, "Stim set must have only one column")

		WAVE/Z smearedStimSetPrevious = $""

		if(i > 0)
			WAVE smearedStimSetPrevious = params.stimSetsSmeared[i - 1]
			previousOffset = offsets[i - 1]
		elseif(WaveExists(params.preload))
			WAVE smearedStimSetPrevious = params.preload
			previousOffset = 0
		endif

		if(WaveExists(smearedStimSetPrevious))
			dataLength = DimSize(smearedStimSetPrevious, ROWS)
			Multithread acc[previousOffset, previousOffset + dataLength - 1] += smearedStimSetPrevious[p - previousOffset]
		endif

		// ignore the feature-less begin of the stim set if present
		FindValue/V=1/T=0.1/Z smearedStimSet
		if(V_Value < 1)
			stimSetFeaturePos = 0
		else
			stimSetFeaturePos = V_Value - 1
		endif

		offset = NaN
		// 0th optimization: coarse search in steps of `params.resolution` ms
		for(j = 0; j < accLength; j += step)

			// 1st optimization: Search continues at the next zero
			FindValue/V=0/S=(j)/T=0.1/Z acc
			ASSERT(V_Value != -1, "Invalid acc without zero")
			j = V_Value

			if(j > stimSetFeaturePos)
				offsetToTest = j - stimSetFeaturePos
			else
				offsetToTest = j
			endif

			if(!OOD_Optimizer(acc, smearedStimSet, offsetToTest))
				// found a good offset in ms
				offset = offsetToTest
				break
			endif
		endfor

		sprintf msg, "Found good offset at %g\r", offset
		DEBUGPRINT(msg)

		offsets[i] = offset
	endfor

	WAVE params.offsets = offsets
End

/// @brief Prints various internals useful for oodDAQ debugging
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

		WAVE smearedOrig = params.stimSetsSmeared[i]
		Duplicate smearedOrig, dfr:$("smeared" + num2str(i))/Wave=smeared
		CopyScales/P params.stimSets[i], smeared

		WAVE smearedAndOffsetOrig = params.stimSetsSmearedAndOffset[i]
		Duplicate smearedAndOffsetOrig, dfr:$("smearedAndOffset" + num2str(i))/Wave=smearedAndOffset
		CopyScales/P params.stimSets[i], smearedAndOffset

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
End

/// @brief Fitting function for optimized overlap dDAQ
///
/// Determines if `stimSet` can be placed without overlap into `baseStimSet`
/// with the given `offset` in points. For performance reason a length of
/// #OOD_BLOCK_SIZE points is checked at a time.
///
/// @return 1 if the stimsets would overlap, 0 if there is no overlap
threadsafe static Function OOD_Optimizer(baseStimSet, stimSet, offset)
	WAVE baseStimSet, stimSet
	variable offset

	variable dataLength, endIndex, first, last, i

	dataLength = DimSize(stimSet, ROWS)

	first = round(offset)
	last  = first + dataLength

	endIndex = OOD_BLOCK_SIZE - 1
	for(i = first; i < last; i += OOD_BLOCK_SIZE)

		// check for the last iteration
		// endIndex can be different if BLOCK_SIZE is not a divider of dataLength
		if(i + OOD_BLOCK_SIZE - first >= dataLength)
			endIndex = mod(dataLength, OOD_BLOCK_SIZE) - 1
		endif

		MatrixOP/FREE maxValue = maxval(subrange(baseStimSet, i, i + endIndex, 0, 0) + subrange(stimSet, i - first, i + endIndex - first, 0, 0))

		if(maxValue[0] > 1)
			return 1
		endif
	endfor

	return 0
End


/// @brief Find the offsets for the optimized overlap dDAQ mode including
/// support for yoking
///
/// @sa OOD_CalculateOffsets()
///
/// For yoking we sort the lead and follower devices according to their device number.
/// Each device will use the result of the previous device offset calculation as preloaded data.
static Function OOD_CalculateOffsetsYoked(panelTitle, params)
	string panelTitle
	STRUCT OOdDAQParams &params

	OOD_SmearStimSet(params)

	// normal acquisition
	if(!DeviceHasFollower(panelTitle) && !DeviceIsFollower(panelTitle))
		OOD_CalculateOffsets(params)

		OOD_CreateStimSetWithSmear(params)
		WAVE/T params.regions = OOD_ExtractFeatureRegions(params.stimSetsSmearedAndOffset)

#if defined(DEBUGGING_ENABLED)
	OOD_Debugging(params)
#endif
		return NaN
	endif

	if(DeviceHasFollower(panelTitle))
		KillOrMoveToTrash(dfr=GetDistDAQFolder())
	elseif(DeviceIsFollower(panelTitle))
		OOD_LoadPreload(panelTitle, params)
	else
		ASSERT(0, "Impossible case")
	endif

	OOD_CalculateOffsets(params)

	OOD_CreateStimSetWithSmear(params)
	WAVE/T params.regions = OOD_ExtractFeatureRegions(params.stimSetsSmearedAndOffset)

	WAVE preload = OOD_GeneratePreload(params)
	OOD_StorePreload(panelTitle, preload)

#if defined(DEBUGGING_ENABLED)
	OOD_Debugging(params)
#endif

End

/// @brief Extend the edges of the stimsets by the requested time spans.
///
/// This can be used for "optimized overlap dDAQ" if you want to have more space
/// between the features in the stim sets.
///
/// Normalizes the returned stimsets to 1 (feature present) and 0 (no feature present).
static Function OOD_SmearStimSet(params)
	STRUCT OOdDAQParams &params

	variable i, numLevels, foundLevel, pLevel, preDelayWarnCount, postDelayWarnCount
	variable dataLength, first, last, start, numSets
	variable level = 0.25
	string msg

	numSets = DimSize(params.stimSets, ROWS)

	WAVE/WAVE singleColumnStimsets = DeepCopyWaveRefWave(params.stimSets, dimension=COLS, indexWave=params.setColumns)
	WAVE/WAVE stimSetsSmeared      = DeepCopyWaveRefWave(singleColumnStimsets)

	for(i = 0; i < numSets; i += 1)

		WAVE stimSetSmeared = stimSetsSmeared[i]
		// normalize stimsets to 1/0
		Multithread stimSetSmeared[] = (stimSetSmeared[p] != 0)

		sprintf msg, "Smearing stimSet %s[%d]\r", NameOfWave(params.stimSets[i]), (params.setColumns[i])
		DEBUGPRINT(msg)

		if(params.preFeaturePoints != 0 || params.postFeaturePoints != 0)

			WAVE stimSet = singleColumnStimsets[i]
			WaveStats/M=1/Q stimSet
			level = V_min + 0.10 * (V_max - V_min)
			dataLength = DimSize(stimSet, ROWS)
			start = 0

			ASSERT(DimSize(stimSetSmeared, ROWS) == DimSize(stimSet, ROWS), "Row length mismatch")
			ASSERT(DimSize(stimSet, COLS) <= 1, "StimSet must have only one column")

			do
				FindLevel/Q/P/R=[start] stimSet, level
				foundLevel = !V_Flag
				pLevel     = V_levelX

				if(!foundLevel || start >= dataLength || pLevel >= dataLength)
					break
				endif

				if(V_rising)
					if(pLevel - params.preFeaturePoints < 0 && preDelayWarnCount == 0)
						printf "Warning: Requested oodDAQ pre delay is longer than the baseline leading up to the pulse train.\r"
						printf "         Either reduce the duration of the pre delay or (in the WaveBuilder) add more leading baseline.\r"
						ControlWindowToFront()
						preDelayWarnCount += 1
					endif

					first = max(pLevel - params.preFeaturePoints, 0)
					last  = pLevel
				else
					if(pLevel + params.postFeaturePoints > dataLength - 1 && postDelayWarnCount == 0)
						printf "Warning: Requested oodDAQ post delay is longer than the trailing baseline at the end of the pulse train.\r"
						printf "         Either reduce the duration of the post delay or (in the WaveBuilder) add more trailing baseline at the end of the pulse train.\r"
						ControlWindowToFront()
						postDelayWarnCount += 1
					endif

					first = pLevel
					last  = min(pLevel + params.postFeaturePoints, dataLength - 1)
				endif
				Multithread stimSetSmeared[first, last] = 1.0
				start = pLevel + 1

				sprintf msg, "Searched [%g, %g] and found level at %g and %s and will smear from [%g, %g]\r", start, inf, pLevel, SelectString(V_rising, "decreasing", "rising"), first, last
				DEBUGPRINT(msg)
			while(1)
		endif
	endfor

	WAVE/WAVE params.stimSetsSmeared = stimSetsSmeared
End

/// @brief Return the oodDAQ optimized stimsets
///
/// The offsets and the regions are returned in `params` and all results are
/// cached.
Function/WAVE OOD_GetResultWaves(panelTitle, params)
	string panelTitle
	STRUCT OOdDAQParams &params

	string key

	key = CA_DistDAQCreateCacheKey(params)

	WAVE/WAVE/Z cache = CA_TryFetchingEntryFromCache(key)

	if(WaveExists(cache))
		WAVE params.offsets = cache[%offsets]
		WAVE/T params.regions = cache[%regions]
		return cache[%stimSetsWithOffset]
	endif

	OOD_CalculateOffsetsYoked(panelTitle, params)
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
/// @return stimset with offsets, one wave per offset
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
