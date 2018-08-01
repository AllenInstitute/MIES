#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SI
#endif

/// @file MIES_SamplingInterval.ipf
///
/// @brief __SI__ Routines for calculating and handling the minimum sampling interval

#if exists("ITCSelectDevice2")
#define ITC_XOP_PRESENT
#endif

/// The consecutive check in #SI_TestSampInt enforces not only one sucessfull sampling
/// interval but also the multiples 2^x where x ranges from 1 to MIN_CONSECUTIVE_SAMPINT
/// Set to 0 to deactivate
static Constant MIN_CONSECUTIVE_SAMPINT = 6

/// @brief Helper struct for storing the number of active channels per rack
static Structure ActiveChannels
	int32 numDARack1
	int32 numADRack1
	int32 numTTLRack1
	int32 numDARack2
	int32 numADRack2
	int32 numTTLRack2
EndStructure

/// @brief Fill the passed wave to be used as ITCChanConfigWave
static Function SI_FillITCConfig(wv, results, idx, totalNumDA, totalNumAD, totalNumTTL)
	WAVE wv, results
	variable idx
	variable totalNumDA, totalNumAD, totalNumTTL

	variable first, last
	variable numDA, numAD, numTTL

	numDA = results[idx][%numDARack1] + results[idx][%numDARack2]
	if(numDA > 0)
		first = 0
		last  = numDA - 1
		wv[first, last][0] = ITC_XOP_CHANNEL_TYPE_DAC

		if(results[idx][%numDARack1]  > 0)
			last = results[idx][%numDARack1] - 1
			wv[first, last][1] = p - first
		endif

		if(results[idx][%numDARack2]  > 0)
			first = results[idx][%numDARack1]
			last  = numDA - 1
			wv[first, last][1] = totalNumDA/2 + (p - first)
		endif
	endif

	numAD = results[idx][%numADRack1] + results[idx][%numADRack2]
	if(numAD > 0)
		first = numDA
		last  = numDA + numAD - 1
		wv[first, last][0] = ITC_XOP_CHANNEL_TYPE_ADC

		if(results[idx][%numADRack1]  > 0)
			last = numDA + results[idx][%numADRack1] - 1
			wv[first, last][1] = p - first
		endif

		if(results[idx][%numADRack2]  > 0)
			first = numDA + results[idx][%numADRack1]
			last  = numDA + numAD - 1
			wv[first, last][1] = totalNumAD/2 + (p - first)
		endif
	endif

	numTTL = results[idx][%numTTLRack1] + results[idx][%numTTLRack2]
	if(numTTL > 0)
		first = numDA + numAD
		last  = numDA + numAD + numTTL - 1
		wv[first, last][0] = ITC_XOP_CHANNEL_TYPE_TTL

		if(results[idx][%numTTLRack1]  > 0)
			last = numDA + numAD + results[idx][%numTTLRack1] - 1
			wv[first, last][1] = p - first
		endif

		if(results[idx][%numTTLRack2]  > 0)
			first = numDA + numAD + results[idx][%numTTLRack1]
			last  = numDA + numAD + numTTL - 1
			wv[first, last][1] = totalNumTTL/2 + (p - first)
		endif
	endif
End

/// @brief Fill the passed wave to be used as ITCChanConfigWave for the exhaustive search
static Function SI_FillITCConfigWithPerms(wv, start, value, channelType)
	WAVE wv
	variable start, value, channelType

	variable idx = start
	variable count

	value = trunc(value)

	if(value == 0)
		return NaN
	endif

	do
		if(value & 1)
			wv[idx][0] = channelType
			wv[idx][1] = count
			count += 1
			idx += 1
		endif
		value = trunc(value / 2^1) // shift one to the right
	while(value > 0)
End

/// @brief Removes invalid and duplicated entries from the
/// generated table from #SI_CreateLookupWave
static Function SI_CompressWave(wv)
	Wave wv

	variable i, j

	CreateBackupWave(wv, forceCreation = 1)
	SI_SortWave(wv)

	for(i = 0; i < DimSize(wv, ROWS); i += 1)
		if(wv[i][%minSampInt] <= 0)
			DeletePoints/M=(ROWS) i, 1, wv
			i -= 1
			continue
		endif

		for(j = i + 1; j < DimSize(wv, ROWS); j += 1)
			if(wv[i][0] == wv[j][0] && wv[i][1] == wv[j][1] && wv[i][2] == wv[j][2])
				if(wv[i][3] == wv[j][3] && wv[i][4] == wv[j][4] && wv[i][5] == wv[j][5])
					if(wv[i][%minSampInt] == wv[j][%minSampInt])
						DeletePoints/M=(ROWS) j, 1, wv
						j -= 1
					endif
				endif
			endif
		endfor
	endfor
End

/// @brief Sort the lookup wave
static Function SI_SortWave(wv)
	WAVE wv

	variable type = WaveType(wv)
	variable numRows = DimSize(wv, ROWS)

	Make/Y=(type)/Free/N=(numRows) key0, key1, key2, key3, key4, key5, key6
	Make/Free/N=(numRows)/I/U valindex = p

	MultiThread key0[] = wv[p][0]
	MultiThread key1[] = wv[p][1]
	MultiThread key2[] = wv[p][2]
	MultiThread key3[] = wv[p][3]
	MultiThread key4[] = wv[p][4]
	MultiThread key5[] = wv[p][5]
	MultiThread key6[] = wv[p][6]

	Sort/A {key0, key1, key2, key3, key4, key5, key6}, valindex

	Duplicate/FREE wv, newtoInsert
	MultiThread newtoinsert[][][][] = wv[valindex[p]][q][r][s]
	MultiThread wv = newtoinsert
End

/// @brief Search the given active channel combination in the lookup wave
static Function SI_FindMatchingTableEntry(wv, ac)
	WAVE wv
	STRUCT ActiveChannels &ac

	variable i, numRows, start

	numRows = DimSize(wv, ROWS)
	FindValue/I=(ac.numDARack1) wv
	start = V_Value
	ASSERT(start < numRows, "Could not find ac.numDARack1 channels in the first column")

	for(i = start; i < numRows; i += 1)
		if(wv[i][0] == ac.numDARack1 && wv[i][1] == ac.numADRack1 && wv[i][2] == ac.numTTLRack1)
			if(wv[i][3] == ac.numDARack2 && wv[i][4] == ac.numADRack2 && wv[i][5] == ac.numTTLRack2)
				return wv[i][%minSampInt]
			endif
		endif
	endfor

	printf "Warning! Could not find a matching entry for the channel combination!\r"
	print ac
	printf "Using a sampling interval of %g micoseconds\r", SAMPLING_INTERVAL_FALLBACK * 1000
	ControlWindowToFront()

	return SAMPLING_INTERVAL_FALLBACK * 1000
End

/// @brief Try to load the lookup wave for the minimum sampling
/// interval from disk for the given deviceType
///
/// @returns a lookup wave or an invalid wave ref
/// if it could not be loaded from disk
static Function/WAVE SI_LoadMinSampIntFromDisk(deviceType)
	string deviceType

	string path = GetFolder(FunctionPath("")) + "SampInt_" + deviceType + ".itx"
	LoadWave/Q/C/T path
	if(!V_flag)
		return $""
	endif

	WAVE wv = $StringFromList(0, S_waveNames)

	DFREF dfr = GetStaticDataFolder()
	MoveWave wv, dfr

	return wv
End

/// @brief Query the DA_EPhys panel for the active channels and
/// fill it in the passed structure
///
/// @return number of active channels
static Function SI_FillActiveChannelsStruct(panelTitle, ac)
	string panelTitle
	STRUCT ActiveChannels &ac

	ASSERT(mod(NUM_DA_TTL_CHANNELS, 2) == 0, "Expected even number of DA/TTL channels")
	ASSERT(mod(NUM_AD_CHANNELS, 2) == 0, "Expected even number of AD channels")

	WAVE statusDA  = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_DAC)
	WAVE statusAD  = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_ADC)
	WAVE statusTTL = DAG_GetChannelState(panelTitle, CHANNEL_TYPE_TTL)

	ac.numDARack1 = sum(statusDA, 0, NUM_DA_TTL_CHANNELS/2 - 1)
	ac.numDARack2 = sum(statusDA, NUM_DA_TTL_CHANNELS/2, inf)

	ac.numADRack1 = sum(statusAD, 0, NUM_AD_CHANNELS/2 - 1)
	ac.numADRack2 = sum(statusAD, NUM_AD_CHANNELS/2, inf)

	ac.numTTLRack1 = sum(statusTTL, 0, NUM_DA_TTL_CHANNELS/2 - 1)
	ac.numTTLRack2 = sum(statusTTL, NUM_DA_TTL_CHANNELS/2, inf)

	return sum(statusDA) + sum(statusAD) + sum(statusTTL)
End

#ifdef ITC_XOP_PRESENT

/// @brief Creates a sampling interval lookup wave by brute forcing all possible combinations
/// The setting `ignoreChannelOrder = 1` reduces the search space from `2^(a + b + c)` to
/// `(a + 1) * (b + 1) * (c + 1)` by ignoring the order of the active channels. `a`/`b`/`c` are
/// here the total number of DA/AD/TTL channels
///
/// @param panelTitle device, must be locked
/// @param ignoreChannelOrder [optional: defaults to false] ignore the order of the active channels
Function SI_CreateLookupWave(panelTitle, [ignoreChannelOrder])
	string panelTitle
	variable ignoreChannelOrder

	variable i, j, k, numChannels, numPerms, ret, idx, numRows
	variable totalNumDA, totalNumAD, totalNumTTL, totalNumRacks, calcSampInt
	variable numDA, numAD, numTTL, DA, AD, TTL
	variable DAMask, ADMask, TTLMask
	string deviceType, deviceNumber

	if(ParamIsDefault(ignoreChannelOrder))
		ignoreChannelOrder = 0
	else
		ignoreChannelOrder = !!ignoreChannelOrder
	endif

	NVAR raCycleID = $GetRepeatedAcquisitionCycleID(panelTitle)
	raCycleID = 1

	DC_ConfigureDataForITC(panelTitle, DATA_ACQUISITION_MODE)

	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)

	NVAR ITCDeviceIDGlobal = $GetITCDeviceIDGlobal(panelTitle)

	ret = ParseDeviceString(panelTitle, deviceType, deviceNumber)
	ASSERT(ret, "Could not parse panelTitle")

	if(!cmpstr(deviceType, "ITC18USB"))
		totalNumDA    = 4
		totalNumAD    = 8
		totalNumTTL   = 4
		totalNumRacks = 1
	elseif(!cmpstr(deviceType, "ITC1600"))
		totalNumDA    = 4
		totalNumAD    = 8
		totalNumTTL   = 4
		totalNumRacks = 2
	else
		ASSERT(0, "please fill in the void")
	endif

	if(ignoreChannelOrder)
		numPerms = ((totalNumDA + 1) * (totalNumAD + 1) * (totalNumTTL + 1))^totalNumRacks

		Make/FREE/B/N=(sqrt(numPerms), 3) resultsOneRack = -1
		SetDimLabel COLS, 0, numDA,  resultsOneRack
		SetDimLabel COLS, 1, numAD,  resultsOneRack
		SetDimLabel COLS, 2, numTTL, resultsOneRack

		Make/O/B/N=(numPerms, 7) results = -1
		SetDimLabel COLS, 0, numDARack1,  results
		SetDimLabel COLS, 1, numADRack1,  results
		SetDimLabel COLS, 2, numTTLRack1, results
		SetDimLabel COLS, 3, numDARack2,  results
		SetDimLabel COLS, 4, numADRack2,  results
		SetDimLabel COLS, 5, numTTLRack2, results
		SetDimLabel COLS, 6, minSampInt,  results

		idx = 0
		for(i = 0; i <= totalNumDA; i += 1)
			for(j = 0; j <= totalNumAD; j += 1)
				for(k = 0; k <= totalNumTTL; k += 1)
					resultsOneRack[idx][%numDA]  = i
					resultsOneRack[idx][%numAD]  = j
					resultsOneRack[idx][%numTTL] = k
					idx += 1
				endfor
			endfor
		endfor

		ASSERT(DimSize(resultsOneRack, ROWS) == idx, "Forgotten entries")

		ASSERT(totalNumRacks == 2, "Only implemented for two racks")

		idx = 0
		numRows = DimSize(resultsOneRack, ROWS)
		for(i = 0; i < numRows; i += 1)
			for(j = 0; j < numRows; j += 1)
				results[idx][%numDARack1]  = resultsOneRack[i][%numDA]
				results[idx][%numADRack1]  = resultsOneRack[i][%numAD]
				results[idx][%numTTLRack1] = resultsOneRack[i][%numTTL]
				results[idx][%numDARack2]  = resultsOneRack[j][%numDA]
				results[idx][%numADRack2]  = resultsOneRack[j][%numAD]
				results[idx][%numTTLRack2] = resultsOneRack[j][%numTTL]

				numChannels  = results[idx][%numDARack1]  + results[idx][%numDARack2]
				numChannels += results[idx][%numADRack1]  + results[idx][%numADRack2]
				numChannels += results[idx][%numTTLRack1] + results[idx][%numTTLRack2]

				Redimension/N=(-1, numChannels) ITCDataWave
				Redimension/N=(numChannels, -1) ITCChanConfigWave

				if(!mod(idx,1000))
					printf "idx= %d\r", idx
				endif

				SI_FillITCConfig(ITCChanConfigWave, results, idx, totalNumDA, totalNumAD, totalNumTTL)

				results[idx][%minSampInt] = SI_TestSampInt(panelTitle)
				idx += 1
			endfor
		endfor
	else // exhaustive sampling interval brute forcing
		ASSERT(totalNumRacks == 1, "Only tested with one rack")

		numPerms = 2^(totalNumDA + totalNumAD + totalNumTTL)

		Make/O/B/N=(numPerms, 7) results = -1
		SetDimLabel COLS, 0, numDARack1, results
		SetDimLabel COLS, 1, numADRack1, results
		SetDimLabel COLS, 2, numTTLRack1, results
		SetDimLabel COLS, 3, numDARack2, results
		SetDimLabel COLS, 4, numADRack2, results
		SetDimLabel COLS, 5, numTTLRack2, results
		SetDimLabel COLS, 6, minSampInt  , results

		DAMask  = (2^(totalNumDA)  - 1) * 2^(totalNumAD + totalNumTTL)
		ADMask  = (2^(totalNumAD)  - 1) * 2^(totalNumTTL)
		TTLMask = (2^(totalNumTTL) - 1) * 2^(0)

		for(i = 0; i < numPerms; i += 1)
			DA  = (i & DAMask)  / 2^(totalNumAD + totalNumTTL)
			AD  = (i & ADMask)  / 2^(totalNumTTL)
			TTL = (i & TTLMask) / 2^(0)
			numChannels = PopCount(i)

			if(numChannels == 0)
				continue
			endif

			Redimension/N=(-1, numChannels) ITCDataWave
			Redimension/N=(numChannels, -1) ITCChanConfigWave

			numDA  = PopCount(DA)
			numAD  = PopCount(AD)
			numTTL = PopCount(TTL)

			if(!mod(i,1000))
				printf "i= %d\r", i
			endif

			SI_FillITCConfigWithPerms(ITCChanConfigWave, 0, DA, ITC_XOP_CHANNEL_TYPE_DAC)
			SI_FillITCConfigWithPerms(ITCChanConfigWave, numDA, AD, ITC_XOP_CHANNEL_TYPE_ADC)
			SI_FillITCConfigWithPerms(ITCChanConfigWave, numDA + numAD, TTL, ITC_XOP_CHANNEL_TYPE_TTL)

			results[i][0]   = numDA
			results[i][1]   = numAD
			results[i][2]   = numTTL
			results[i][3,5] = 0
			results[i][6] = SI_TestSampInt(panelTitle)
		endfor
	endif

	ITCConfigChannelReset2

	SI_CompressWave(results)
End

/// @brief Test the preset sampling interval
static Function SI_TestSampInt(panelTitle)
	string panelTitle

	variable i, sampInt, ret, sampIntRead, numChannels, sampIntRef, iLast
	variable numConsecutive = -1
	variable numTries = 1001

	WAVE ITCDataWave = GetITCDataWave(panelTitle)
	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
	numChannels = DimSize(ITCChanConfigWave, ROWS)

	Make/I/FREE/N=(2, numChannels) ReqWave
	ReqWave[0][] = ITCChanConfigWave[q][0]
	ReqWave[1][] = ITCChanConfigWave[q][1]
	Make/D/FREE/N=(20, numChannels) ResultWave

	for(i=1; i < numTries; i += 1)
		if(numConsecutive == -1)
			sampInt  = HARDWARE_ITC_MIN_SAMPINT * i * 1000
		else
			sampInt *= 2
		endif

		ITCChanConfigWave[][2] = sampInt
		ITCConfigAllChannels2/Z ITCChanConfigWave, ITCDataWave

		if(!ret)
			// we could set the sampling interval
			// so we try to read it back and check if it is the same
			ITCConfigChannelUpload2
			HW_ITC_HandleReturnValues(HARDWARE_ABORT_ON_ERROR, V_ITCError, V_ITCXOPError)

			ITCGetAllChannelsConfig2/O ReqWave, ResultWave
			HW_ITC_HandleReturnValues(HARDWARE_ABORT_ON_ERROR, V_ITCError, V_ITCXOPError)

			WaveStats/Q/R=[12,12] ResultWave
			ASSERT(V_min == V_max, "Unexpected differing sampling interval")
			// ITCGetAllChannelsConfig2 returns the sampling interval in Hz
			// but we want it in microseconds
			sampIntRead = 1/V_min * 1e6

			if(sampIntRead == sampInt)
				if(numConsecutive == -1)
					sampIntRef     = sampIntRead
					numConsecutive = 0
					iLast          = i
				endif

				if(numConsecutive == MIN_CONSECUTIVE_SAMPINT)
					return sampIntRef
				else
					ASSERT(numConsecutive == 0 || iLast == i - 1, "Expected consecutive hits")
					iLast = i
					numConsecutive += 1
				endif
			endif
		endif
	endfor

	return NaN
End

#else

Function SI_CreateLookupWave(panelTitle, [ignoreChannelOrder])
	string panelTitle
	variable ignoreChannelOrder

	DEBUGPRINT("Unimplemented")
End

static Function SI_TestSampInt(panelTitle)
	string panelTitle

	DEBUGPRINT("Unimplemented")
End

#endif

/// @brief Calculate the minimum sampling interval using the lookup waves on disk
///
/// @param panelTitle  device
/// @param dataAcqOrTP one of @ref DataAcqModes, ignores TTL channels for #TEST_PULSE_MODE
///
/// @returns sampling interval in microseconds (1e-6)
Function SI_CalculateMinSampInterval(panelTitle, dataAcqOrTP)
	string panelTitle
	variable dataAcqOrTP

	variable numActiveChannels

	WAVE/Z lut = SI_GetMinSampIntWave(panelTitle)
	if(!WaveExists(lut))
		printf "Warning: Could not load the minimum sampling interval table from disk\r"
		printf "Falling back to %g microseconds as sampling interval\r", SAMPLING_INTERVAL_FALLBACK * 1000
		return SAMPLING_INTERVAL_FALLBACK * 1000
	endif

	STRUCT ActiveChannels ac
	numActiveChannels = SI_FillActiveChannelsStruct(panelTitle, ac)

	if(dataAcqOrTP == TEST_PULSE_MODE) // disregard TTL channels for testpulse
		numActiveChannels -= ac.numTTLRack1
		numActiveChannels -= ac.numTTLRack2
		ac.numTTLRack1     = 0
		ac.numTTLRack2     = 0
	endif

	if(numActiveChannels == 0)
		return HARDWARE_ITC_MIN_SAMPINT * 1000
	endif

	return SI_FindMatchingTableEntry(lut, ac)
End

/// @brief Return a wave ref with the lookup wave for the sampling interval
///
/// This functions tries to load the wave from disk on the first
/// call so this function might take a while to execute.
static Function/WAVE SI_GetMinSampIntWave(panelTitle)
	string panelTitle

	variable ret
	string deviceType, deviceNumber

	ret = ParseDeviceString(panelTitle, deviceType, deviceNumber)
	ASSERT(ret, "Could not parse device string")

	DFREF dfr = GetStaticDataFolder()

	strswitch(deviceType)
		case "ITC18USB":
		case "ITC18":
			WAVE/SDFR=dfr/Z wv = SampInt_ITC18USB

			if(!WaveExists(wv))
				return SI_LoadMinSampIntFromDisk("ITC18USB")
			endif

			return wv
			break
		case "ITC1600":
			WAVE/SDFR=dfr/Z wv = SampInt_ITC1600
			if(!WaveExists(wv))
				return SI_LoadMinSampIntFromDisk(deviceType)
			endif

			return wv
			break
		default:
			DEBUGPRINT("There is no lookup wave available for the device type", str=deviceType)
			break
	endswitch

	return $""
End
