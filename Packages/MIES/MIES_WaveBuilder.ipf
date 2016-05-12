#pragma rtGlobals=3		// Use modern global access method and strict Wave access.

/// @file MIES_WaveBuilder.ipf
/// @brief __WB__ Stimulus set creation

static Constant MAX_SWEEP_DURATION_IN_MS = 1.8e6 // 30 minutes

static Constant SQUARE_PULSE_TRAIN_MODE_DUR   = 0x01
static Constant SQUARE_PULSE_TRAIN_MODE_PULSE = 0x02

/// @brief Return the stim set wave and create it permanently
/// in the datafolder hierarchy
/// @return stimset wave ref or an invalid wave ref
Function/Wave WB_CreateAndGetStimSet(setName)
	string setName

	variable type, needToCreateStimSet

	if(isEmpty(setName))
		return $""
	endif

	type = GetStimSetType(setName)

	if(type == CHANNEL_TYPE_UNKNOWN)
		return $""
	endif

	DFREF dfr = GetSetFolder(type)
	WAVE/Z/SDFR=dfr stimSet = $setName

	if(!WaveExists(stimSet))
		needToCreateStimSet = 1
	elseif(WaveExists(stimSet) && WB_ParameterWvsNewerThanStim(setName))
		needToCreateStimSet = 1
	else
		needToCreateStimSet = 0
	endif

	if(needToCreateStimSet)
		WAVE/Z stimSet = WB_GetStimSet(setName=setName)
		if(!WaveExists(stimSet))
			return $""
		endif

		WAVE/Z/SDFR=dfr oldStimSet = $setName
		if(WaveExists(oldStimSet))
			KillOrMoveToTrash(wv=oldStimSet)
		endif

		MoveWave stimSet, dfr:$setName
		WAVE/SDFR=dfr stimSet = $setName
	endif

	return stimSet
End

/// @brief Return the wave `WP` for a stim set
///
/// @return valid/invalid wave reference
Function/Wave WB_GetWaveParamForSet(setName)
	string setName

	variable type

	type = GetStimSetType(setName)

	if(type == CHANNEL_TYPE_UNKNOWN)
		return $""
	endif

	DFREF dfr = GetSetParamFolder(type)

	WAVE/Z/SDFR=dfr wv = $("WP" + "_" + setName)

	return wv
End

/// @brief Return the wave `WPT` for a stim set
///
/// @return valid/invalid wave reference
Function/Wave WB_GetWaveTextParamForSet(setName)
	string setName

	variable type

	type = GetStimSetType(setName)

	if(type == CHANNEL_TYPE_UNKNOWN)
		return $""
	endif

	DFREF dfr = GetSetParamFolder(type)

	WAVE/Z/T/SDFR=dfr wv = $("WPT" + "_" + setName)

	return wv
End

/// @brief Return the wave `SegmentWvType` for a stim set
///
/// @return valid/invalid wave reference
Function/Wave WB_GetSegWvTypeForSet(setName)
	string setName

	variable type

	type = GetStimSetType(setName)

	if(type == CHANNEL_TYPE_UNKNOWN)
		return $""
	endif

	DFREF dfr = GetSetParamFolder(type)

	WAVE/Z/SDFR=dfr wv = $("SegWvType" + "_" + setName)

	return wv
End

/// @return One if one of the parameter waves is newer than the stim set wave, zero otherwise
static Function WB_ParameterWvsNewerThanStim(setName)
	string setName

	variable type, lastModStimSet

	WAVE/Z WP        = WB_GetWaveParamForSet(setName)
	WAVE/Z WPT       = WB_GetWaveTextParamForSet(setName)
	WAVE/Z SegWvType = WB_GetSegWvTypeForSet(setName)

	if(WaveExists(WP) && WaveExists(WPT) && WaveExists(SegWvType))

		type = GetStimSetType(setName)
		DFREF dfr = GetSetFolder(type)
		WAVE/Z/SDFR=dfr stimSet = $setName
		if(!WaveExists(stimSet))
			return 0
		endif

		lastModStimSet = modDate(stimSet)

		if(modDate(WP) > lastModStimSet || modDate(WPT) > lastModStimSet || modDate(SegWvType) > lastModStimSet)
			return 1
		endif
	endif

	return 0
End

/// @brief Return the stim set wave
///
/// As opposed to #WB_CreateAndGetStimSet this function returns a free wave only
///
/// All external callers, outside the Wavebuilder, must call #WB_CreateAndGetStimSet
/// instead of this function.
///
/// @param setName [optional, defaults to WaveBuilderPanel GUI settings] name of the set
/// @return free wave with the stim set, invalid wave ref if the `WP*` parameter waves could
/// not be found.
Function/Wave WB_GetStimSet([setName])
	string setName

	variable i, numEpochs, numSteps, updateEpochIDWave
	variable last, lengthOf1DWaves, length, channelType
	string wvName
	variable start = stopmstimer(-2)

	if(ParamIsDefault(setName))
		updateEpochIDWave = 1

		WAVE WP        = GetWaveBuilderWaveParam()
		WAVE/T WPT     = GetWaveBuilderWaveTextParam()
		WAVE SegWvType = GetSegmentTypeWave()
		channelType    = WBP_GetOutputType()
	else
		WAVE WP        = WB_GetWaveParamForSet(setName)
		WAVE/T WPT     = WB_GetWaveTextParamForSet(setName)
		WAVE SegWvType = WB_GetSegWvTypeForSet(setName)
		channelType    = GetStimSetType(setName)

		if(!WaveExists(WP) || !WaveExists(WPT) || !WaveExists(SegWvType))
			return $""
		endif

		UpgradeWaveParam(WP)
		UpgradeWaveTextParam(WPT)
		UpgradeSegWvType(SegWvType)
	endif

	// WB_AddDelta modifies WP so we pass a copy instead
	Duplicate/FREE WP, WPCopy

	numSteps   = SegWvType[101]
	numEpochs  = SegWvType[100]

	ASSERT(numSteps > 0, "Invalid number of steps")

	MAKE/WAVE/FREE/N=(numSteps) stepData

	for(i=0; i < numSteps; i+=1)
		stepData[i] = WB_MakeWaveBuilderWave(WPCopy, WPT, SegWvType, i, numEpochs, channelType, updateEpochIDWave)
		lengthOf1DWaves = max(DimSize(stepData[i], ROWS), lengthOf1DWaves)
		WB_AddDelta(WPCopy, numEpochs)
	endfor

	// copy the random seed value to WP in order to preserve it
	WP[48][][] = WPCopy[48][q][r]

	if(lengthOf1DWaves == 0)
		return $""
	endif

	Make/FREE/O/N=(lengthOf1DWaves, numSteps) stimSet
	FastOp stimSet = 0

	for(i = 0; i < numSteps; i += 1)
		WAVE wv = stepData[i]

		length = DimSize(wv, ROWS)
		if(length == 0)
			continue
		endif

		last = length - 1
		stimSet[0, last][i] = wv[p]

		if(i == 0)
			Note stimSet, note(wv)
			CopyScales/P wv, stimset
		endif
	endfor

	if(SegWvType[98])
		WaveTransForm/O flip stimset
	endif

	DEBUGPRINT("copying took (ms):", var=(stopmstimer(-2) - start) / 1000)

	return stimSet
End

/// @brief Add delta to appropriate parameters
///
/// Relies on alternating sequence of parameter and delta's in parameter waves as documented in WB_MakeWaveBuilderWave()
///
/// @param WP         wavebuilder parameter wave (temporary copy)
/// @param numEpochs  number of epochs
static Function WB_AddDelta(WP, numEpochs)
	Wave WP
	variable numEpochs

	variable i, j, k
	variable offsetFactor, durationFactor, amplitudeFactor
	variable operation, factor
	variable numEpochTypes

	numEpochTypes = DimSize(WP, LAYERS)

	for(i = 0; i < 30; i += 2)
		for(j = 0; j < numEpochs; j += 1)
			for(k = 0; k < numEpochTypes; k += 1)

				WP[i][j][k] += WP[i + 1][j][k]

				operation = WP[40][j][k]
				if(operation)
					durationFactor  = WP[52][j][k]
					amplitudeFactor = WP[50][j][k]
					offsetFactor    = WP[51][j][k]
					switch(i)
						case 0:
							factor = durationFactor
							break
						case 2:
							factor = amplitudeFactor
							break
						case 4:
							factor = offsetFactor
							break
						default:
							factor = 1
							break
					endswitch

					switch(operation)
						case 1: // Simple factor
							WP[i + 1][j][k] = WP[i + 1][j][k] * factor
							break
						case 2: // Log
							// ignore a delta value of exactly zero
							WP[i + 1][j][k] = WP[i + 1][j][k] == 0 ? 0 : log(WP[i + 1][j][k])
							break
						case 3: // Squared
							WP[i + 1][j][k] = (WP[i + 1][j][k])^2
							break
						case 4: // Power
							WP[i + 1][j][k] = (WP[i + 1][j][k])^factor
							break
						case 5: // Alternate
							WP[i + 1][j][k] *= -1
							break
						default:
							ASSERT(0, "Unkonwn operation")
							break
					endswitch
				endif
			endfor
		endfor
	endfor

	// number of pulses has a non-standard delta position
	for(j = 0; j < numEpochs; j += 1)
		for(k = 0; k < numEpochTypes; k += 1)
			if(WP[46][j][k]) // use pulses checkbox
				WP[45][j][k] += WP[47][j][k]
			endif
		endfor
	endfor
End

static Structure SegmentParameters
	variable duration
	variable deltaDur
	variable amplitude
	variable deltaAmp
	variable offset
	variable deltaOffset
	variable frequency
	variable deltaFreq
	variable pulseDuration
	variable deltaPulsedur
	variable tauRise
	variable deltaTauRise
	variable tauDecay1
	variable deltaTauDecay1
	variable tauDecay2
	variable deltaTauDecay2
	variable tauDecay2Weight
	variable deltaTauDecay2Weight
	variable customOffset
	variable deltaCustomOffset
	variable lowPassCutOff
	variable deltaLowPassCutOff
	variable highPassCutOff
	variable deltaHighPassCutOff
	variable endFrequency
	variable deltaEndFrequency
	variable highPassFiltCoefCount
	variable deltaHighPassFiltCoefCount
	variable lowPassFiltCoefCount
	variable deltaLowPassFiltCoefCount
	variable fIncrement
	variable numberOfPulses
	// checkboxes
	variable poisson
	variable brownNoise, pinkNoise
	variable sinChirp
	variable randomSeed
	// popupmenues
	variable trigFuncType // 0: sin, 1: cos
EndStructure

static Function/WAVE WB_MakeWaveBuilderWave(WP, WPT, SegWvType, stepCount, numEpochs, channelType, updateEpochIDWave)
	Wave WP
	Wave/T WPT
	Wave SegWvType
	variable stepCount, numEpochs, channelType, updateEpochIDWave

	DFREF dfr = GetWaveBuilderDataPath()

	Make/FREE/N=0 WaveBuilderWave

	string customWaveName, debugMsg, defMode, formula, formula_version
	string formula_for_note
	variable i, j, type, accumulatedDuration
	STRUCT SegmentParameters params

	for(i=0; i < numEpochs; i+=1)
		type = SegWvType[i]

		params.duration                   = WP[0][i][type]
		params.deltaDur                   = WP[1][i][type]
		params.amplitude                  = WP[2][i][type]
		params.deltaAmp                   = WP[3][i][type]
		params.offset                     = WP[4][i][type]
		params.deltaOffset                = WP[5][i][type]
		params.frequency                  = WP[6][i][type]
		params.deltaFreq                  = WP[7][i][type]
		params.pulseDuration              = WP[8][i][type]
		params.deltaPulsedur              = WP[9][i][type]
		params.tauRise                    = WP[10][i][type]
		params.deltaTauRise               = WP[11][i][type]
		params.tauDecay1                  = WP[12][i][type]
		params.deltaTauDecay1             = WP[13][i][type]
		params.tauDecay2                  = WP[14][i][type]
		params.deltaTauDecay2             = WP[15][i][type]
		params.tauDecay2Weight            = WP[16][i][type]
		params.deltaTauDecay2Weight       = WP[17][i][type]
		params.customOffset               = WP[18][i][type]
		params.deltaCustomOffset          = WP[19][i][type]
		params.lowPassCutOff              = WP[20][i][type]
		params.deltaLowPassCutOff         = WP[21][i][type]
		params.highPassCutOff             = WP[22][i][type]
		params.deltaHighPassCutOff        = WP[23][i][type]
		params.endFrequency               = WP[24][i][type]
		params.deltaEndFrequency          = WP[25][i][type]
		params.highPassFiltCoefCount      = WP[26][i][type]
		params.deltaHighPassFiltCoefCount = WP[27][i][type]
		params.lowPassFiltCoefCount       = WP[28][i][type]
		params.deltaLowPassFiltCoefCount  = WP[29][i][type]
		params.fIncrement                 = WP[30][i][type]
		params.pinkNoise                  = WP[41][i][type]
		params.brownNoise                 = WP[42][i][type]
		params.sinChirp                   = WP[43][i][type]
		params.poisson                    = WP[44][i][type]
		params.numberOfPulses             = WP[45][i][type]
		params.trigFuncType               = WP[53][i][type]

		sprintf debugMsg, "step count: %d, epoch: %d, duration: %g (delta %g), amplitude %d (delta %g)\r", stepCount, i, params.duration, params.DeltaDur, params.amplitude, params.DeltaAmp
		DEBUGPRINT("params", str=debugMsg)

		if(params.duration < 0 || !IsFinite(params.duration))
			Print "User input has generated a negative/non-finite epoch duration. Please adjust input. Duration for epoch has been reset to 1 ms."
			params.duration = 1
		endif

		switch(type)
			case 0:
				WB_SquareSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"          , var=i)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"           , str="Square pulse")
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude"      , var=params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta amplitude", var=params.DeltaAmp)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration"       , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta duration" , var=params.DeltaDur)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"         , var=params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta offset"   , var=params.DeltaOffset, appendCR=1)
				break
			case 1:
				WB_RampSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"          , var=i)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"           , str="Ramp")
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude"      , var=params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta amplitude", var=params.DeltaAmp)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration"       , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta duration" , var=params.DeltaDur)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"         , var=params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta offset"   , var=params.DeltaOffset, appendCR=1)
				break
			case 2:
				// initialize the random seed value if not already done
				if(WP[48][i][type] == 0)
					WP[48][i][type] = GetNonReproducibleRandom()
				endif
				params.randomSeed = WP[48][i][type]
				SetRandomSeed/BETR=1 params.randomSeed

				if(WP[49][i][type])
					// the stored seed value is the seed value for the *generation*
					// of the individual seed values for each step
					// Procedure:
					// - Initialize RNG with stored seed
					// - Query as many random numbers as current step count
					// - Use the *last* random number as seed value for the new epoch
					// In this way we get a different seed value for each step, but all are reproducibly
					// derived from one seed value. And we still have different values for different epochs.
					for(j = 1; j <= stepCount; j += 1)
						params.randomSeed = GetReproducibleRandom()
					endfor
					SetRandomSeed/BETR=1 params.randomSeed
				endif

				WB_NoiseSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"                  , var=i)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"                   , str="G-noise")
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "SD"                     , var=params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "SD delta"               , var=params.DeltaAmp)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Low pass cut off"       , var=params.LowPassCutOff)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Low pass cut off delta" , var=params.DeltaLowPassCutOff)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "High pass cut off"      , var=params.HighPassCutOff)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "High pass cut off delta", var=params.DeltaHighPassCutOff)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"                 , var=params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Random seed"            , var=params.randomSeed)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta offset"           , var=params.DeltaOffset, appendCR=1)
				break
			case 3:
				WB_TrigSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"              , var=i)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"               , str="Sin Wave")
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency"          , var=params.Frequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency delta"    , var=params.DeltaFreq)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "End frequency"      , var=params.EndFrequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "End frequency delta", var=params.DeltaEndFrequency, appendCR=1)
				break
			case 4:
				WB_SawToothSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"          , var=i)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"           , str="Saw tooth")
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency"      , var=params.Frequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency delta", var=params.DeltaFreq)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"         , var=params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta offset"   , var=params.DeltaOffset, appendCR=1)
				break
			case 5:
				if(WP[46][i][type]) // "Number of pulses" checkbox
					WB_SquarePulseTrainSegment(params, SQUARE_PULSE_TRAIN_MODE_PULSE)
					if(windowExists("WaveBuilder") && GetTabID("WaveBuilder", "WBP_WaveType") == 5)
						WBP_UpdateControlAndWP("SetVar_WaveBuilder_P0", params.duration)
					endif
					defMode = "Pulse"
				else
					WB_SquarePulseTrainSegment(params, SQUARE_PULSE_TRAIN_MODE_DUR)
					if(windowExists("WaveBuilder") && GetTabID("WaveBuilder", "WBP_WaveType") == 5)
						WBP_UpdateControlAndWP("SetVar_WaveBuilder_P45", params.numberOfPulses)
					endif
					defMode = "Duration"
				endif

				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"               , var=i)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"                , str="SPT")
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency"           , var=params.Frequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency delta"     , var=params.DeltaFreq)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Pulse duration"      , var=params.PulseDuration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Pulse duration delta", var=params.DeltaPulsedur)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"              , var=params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta offset"        , var=params.DeltaOffset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Number of pulses"    , var=params.NumberOfPulses)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Definition mode"     , str=defMode, appendCR=1)
				break
			case 6:
				WB_PSCSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"             , var=i)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"              , str="PSC")
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau rise"          , var=params.TauRise)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau decay 1"       , var=params.TauDecay1)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau decay 2"       , var=params.TauDecay2)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau decay 2 weight", var=params.TauDecay2Weight)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"            , var=params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta offset"      , var=params.DeltaOffset, appendCR=1)
				break
			case 7:
				customWaveName = WPT[0][i]

				if(windowExists("Wavebuilder") && strsearch(customWaveName, ":", 0) == -1)
					// old style entries with only the wave name
					Wave/Z/SDFR=WBP_GetFolderPath() customWave = $customWaveName
				else
					// try new style entries with full path
					WAVE/Z customWave = $customWaveName
				endif

				if(WaveExists(customWave))
					WB_CustomWaveSegment(params.customOffset, customWave)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"       , var=i)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"        , str="Custom Wave")
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Name"        , str=customWaveName)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"      , var=params.Offset)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta offset", var=params.DeltaOffset, appendCR=1)
				elseif(!isEmpty(customWaveName))
					print "Wave currently selected no longer exists. Please select a new Wave from the pull down menu"
				endif
				break
			case 8:
				WAVE segmentWave = WB_GetSegmentWave(0)

				formula_for_note = WPT[6][i]
				formula          = WB_FormulaSwitchToShorthand(formula_for_note)
				formula_version  = WPT[7][i]

				if(isEmpty(formula))
					printf "Skipping combine epoch with empty formula\r"
					break
				endif

				if(cmpstr(formula_version, WAVEBUILDER_COMBINE_FORMULA_VER))
					printf "Could not create the wave from formula of version %s\r", WAVEBUILDER_COMBINE_FORMULA_VER
					break
				endif

				WAVE/Z combinedWave = WB_FillWaveFromFormula(formula, channelType, stepCount)

				if(!WaveExists(combinedWave))
					print "Could not create the wave from the formula"
					break
				endif

				Duplicate/O combinedWave, segmentWave

				params.Duration = DimSize(segmentWave, ROWS) * HARDWARE_ITC_MIN_SAMPINT

				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"           , var=i)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"            , str="Combine")
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration"        , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Formula"         , str=formula_for_note)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Formula Version" , str=formula_version)

				break
			default:
				printf "Ignoring unknown epoch type %d\r", type
				continue
		endswitch

		if(updateEpochIDWave)
			if(stepCount == 0)
				WAVE epochID = GetEpochID()
				if(i == 0)
					epochID = 0
				endif
				epochID[i][%timeBegin] = accumulatedDuration
				epochID[i][%timeEnd]   = accumulatedDuration + params.duration

				accumulatedDuration += params.duration
			endif
		endif

		WAVE/SDFR=dfr segmentWave
		Concatenate/NP=0 {segmentWave}, WaveBuilderWave
	endfor

	// adjust epochID timestamps for stimset flipping
	if(updateEpochIDWave && SegWvType[98])
		if(stepCount == 0)
			for(i = 0; i < numEpochs; i += 1)
				epochID[i][%timeBegin] = accumulatedDuration - epochID[i][%timeBegin]
				epochID[i][%timeEnd]   = accumulatedDuration - epochID[i][%timeEnd]
			endfor
		endif
	endif

	AddEntryIntoWaveNoteAsList(WaveBuilderWave, "ITI", var=SegWvType[99])
	AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST), str=WPT[1][99])
	AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST), str=WPT[2][99])
	AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST), str=WPT[3][99])
	AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(POST_SET_EVENT, EVENT_NAME_LIST), str=WPT[4][99])
	AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST), str=WPT[5][99])
	AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Flip", var=SegWvType[98], appendCR=1)

	SetScale /P x 0, HARDWARE_ITC_MIN_SAMPINT, "ms", WaveBuilderWave
	// although we are not creating these globals anymore, we still try to kill them
	KillVariables/Z ParameterHolder
	KillStrings/Z StringHolder

	return WaveBuilderWave
End

/// @brief Returns the segment wave which stores the stimulus set of one segment/epoch
/// @param duration time of the stimulus in ms
static Function/Wave WB_GetSegmentWave(duration)
	variable duration

	DFREF dfr = GetWaveBuilderDataPath()
	variable numPoints = duration / HARDWARE_ITC_MIN_SAMPINT
	Wave/Z/SDFR=dfr SegmentWave

	if(duration > MAX_SWEEP_DURATION_IN_MS)
		Abort "Sweeps are currently limited to 30 minutes in duration.\rAdjust MAX_SWEEP_DURATION_IN_MS to change that!"
	endif

	// optimization: recreate the wave only if necessary or just resize it
	if(!WaveExists(SegmentWave))
		Make/N=(numPoints) dfr:SegmentWave/Wave=SegmentWave
	elseif(numPoints != DimSize(SegmentWave, ROWS))
		Redimension/N=(numPoints) SegmentWave
	endif

	SetScale/P x 0, HARDWARE_ITC_MIN_SAMPINT, "ms", SegmentWave

	return SegmentWave
End

/// @name Functions that build wave types
/// @{
static Function WB_SquareSegment(pa)
	struct SegmentParameters &pa

	Wave SegmentWave = WB_GetSegmentWave(pa.duration)
	SegmentWave = pa.amplitude
End

static Function WB_RampSegment(pa)
	struct SegmentParameters &pa

	variable amplitudeIncrement = pa.amplitude * HARDWARE_ITC_MIN_SAMPINT / pa.duration

	Wave SegmentWave = WB_GetSegmentWave(pa.duration)
	MultiThread SegmentWave = amplitudeIncrement * p
	SegmentWave += pa.offset
End

static Function WB_NoiseSegment(pa)
	struct SegmentParameters &pa

	variable PinkOrBrown

	Wave SegmentWave = WB_GetSegmentWave(pa.duration)

	if(!pa.brownNoise && !pa.pinkNoise)
		SegmentWave = gnoise(pa.amplitude) // MultiThread didn't impact processing time for gnoise
		if(pa.duration <= 0)
			print "WB_NoiseSegment: Can not proceed with non-positive duration"
			return NaN
		endif

		if(pa.lowPassCutOff <= 100000 && pa.lowPassCutOff != 0)
			FilterFIR /DIM = 0 /LO = {(pa.lowPassCutOff / 200000), (pa.lowPassCutOff / 200000), pa.lowPassFiltCoefCount} SegmentWave
		endif

		if(pa.highPassCutOff > 0 && pa.highPassCutOff < 100000)
			FilterFIR /DIM = 0 /Hi = {(pa.highPassCutOff/200000), (pa.highPassCutOff/200000), pa.highPassFiltCoefCount} SegmentWave
		endif
	elseif(pa.pinkNoise)
		WB_PinkAndBrownNoise(pa, 0)
	elseif(pa.brownNoise)
		WB_PinkAndBrownNoise(pa, 1)
	endif

	SegmentWave += pa.offset
End

static Function WB_TrigSegment(pa)
	struct SegmentParameters &pa

	variable k0, k1, k2, k3

	if(pa.trigFuncType != 0 && pa.trigFuncType != 1)
		printf "Ignoring unknown trigonometric function"
		Wave SegmentWave = WB_GetSegmentWave(0)
		return NaN
	endif

	Wave SegmentWave = WB_GetSegmentWave(pa.duration)

	if(!pa.sinChirp)
		if(pa.trigFuncType == 0)
			MultiThread SegmentWave = pa.amplitude * sin(2 * Pi * (pa.frequency * 1000) * (5 / 1000000000) * p)
		else
			MultiThread SegmentWave = pa.amplitude * cos(2 * Pi * (pa.frequency * 1000) * (5 / 1000000000) * p)
		endif
	else
		k0 = ln(pa.frequency / 1000)
		k1 = (ln(pa.endFrequency / 1000) - k0) / (pa.duration)
		k2 = 2 * pi * e^k0 / k1
		k3 = mod(k2, 2 * pi)		// LH040117: start on rising edge of sin and don't try to round.
		if(pa.trigFuncType == 0)
			MultiThread SegmentWave = pa.amplitude * sin(k2 * e^(k1 * x) - k3)
		else
			MultiThread SegmentWave = pa.amplitude * cos(k2 * e^(k1 * x) - k3)
		endif
	endif

	SegmentWave += pa.offset
End

static Function WB_SawToothSegment(pa)
	struct SegmentParameters &pa

	Wave SegmentWave = WB_GetSegmentWave(pa.duration)

	SegmentWave = 1 * pa.amplitude * sawtooth(2 * Pi * (pa.frequency * 1000) * (5 / 1000000000) * p)
	SegmentWave += pa.offset
End

static Function WB_SquarePulseTrainSegment(pa, mode)
	struct SegmentParameters &pa
	variable mode

	variable i, pulseStartTime, endIndex, startIndex
	variable numRows, interPulseInterval

	if(!(pa.frequency > 0))
		printf "Resetting invalid frequency of %gHz to 1Hz\r", pa.frequency
		pa.frequency = 1.0
	endif

	if(mode == SQUARE_PULSE_TRAIN_MODE_PULSE)
		// user defined number of pulses
		pa.duration = pa.numberOfPulses / pa.frequency * 1000
	elseif(mode == SQUARE_PULSE_TRAIN_MODE_DUR)
		// user defined duration
		pa.numberOfPulses = pa.frequency * pa.duration / 1000
	else
		ASSERT(0, "Invalid mode")
	endif

	if(!(pa.duration > 0))
		printf "Resetting invalid duration of %gms to 1ms\r", pa.duration
		pa.duration = 1.0
	endif

	// we want always to have the correct interpulse interval
	// independent of the duration
	interPulseInterval = (1 / pa.frequency) * 1000 - pa.pulseDuration

	WAVE segmentWave = WB_GetSegmentWave(pa.duration)
	segmentWave = 0
	numRows = DimSize(segmentWave, ROWS)

	if(!pa.poisson)
		for(;;)
			endIndex = floor((pulseStartTime + pa.pulseDuration) / HARDWARE_ITC_MIN_SAMPINT)

			if(endIndex >= numRows || endIndex < 0)
				break
			endif

			startIndex = floor(pulseStartTime / HARDWARE_ITC_MIN_SAMPINT)
			segmentWave[startIndex, endIndex] = pa.amplitude
			pulseStartTime += interPulseInterval + pa.pulseDuration
		endfor
	else
		for(;;)
			pulseStartTime += -ln(abs(enoise(1))) / pa.frequency * 1000
			endIndex = floor((pulseStartTime + pa.pulseDuration) / HARDWARE_ITC_MIN_SAMPINT)

			if(endIndex >= numRows || endIndex < 0)
				break
			endif

			startIndex = floor(pulseStartTime / HARDWARE_ITC_MIN_SAMPINT)
			segmentWave[startIndex, endIndex] = pa.amplitude
		endfor
	endif

	// remove the zero part at the end
	FindValue/V=(0)/S=(startIndex) segmentWave
	if(V_Value != -1)
		DEBUGPRINT("Removal of points:", var=(DimSize(segmentWave, ROWS) - V_Value))
		Redimension/N=(V_Value) segmentWave
		pa.duration = V_Value * HARDWARE_ITC_MIN_SAMPINT
	else
		DEBUGPRINT("No removal of points")
	endif

	segmentWave += pa.offset

	DEBUGPRINT("interPulseInterval", var=interPulseInterval)
	DEBUGPRINT("numberOfPulses", var=pa.numberOfPulses)
	DEBUGPRINT("Real duration", var=DimSize(segmentWave, ROWS) * HARDWARE_ITC_MIN_SAMPINT, format="%.6f")
End

static Function WB_PSCSegment(pa)
	struct SegmentParameters &pa

	variable baseline, peak

	Wave SegmentWave = WB_GetSegmentWave(pa.duration)

	pa.TauRise = 1 / pa.TauRise
	pa.TauRise *= HARDWARE_ITC_MIN_SAMPINT
	pa.TauDecay1 = 1 / pa.TauDecay1
	pa.TauDecay1 *= HARDWARE_ITC_MIN_SAMPINT
	pa.TauDecay2 = 1 / pa.TauDecay2
	pa.TauDecay2 *= HARDWARE_ITC_MIN_SAMPINT

	MultiThread SegmentWave[] = pa.amplitude * ((1 - exp(-pa.TauRise * p)) + exp(-pa.TauDecay1 * p) * (1 - pa.TauDecay2Weight) + exp(-pa.TauDecay2 * p) * pa.TauDecay2Weight)

	baseline = WaveMin(SegmentWave)
	peak = WaveMax(SegmentWave)
	SegmentWave *= abs(pa.amplitude)/(peak - baseline)

	baseline = WaveMin(SegmentWave)
	SegmentWave -= baseline
	SegmentWave += pa.offset
End

static Function WB_CustomWaveSegment(CustomOffset, wv)
	variable CustomOffset
	Wave wv

	DFREF dfr = GetWaveBuilderDataPath()

	Duplicate/O wv, dfr:SegmentWave/Wave=SegmentWave
	SegmentWave += CustomOffSet
End

/// @brief Create a pink or brown noise segment
///
/// @param pa Segment parameters
/// @param pinkOrBrown Pink = 0, Brown = 1
static Function WB_PinkAndBrownNoise(pa, pinkOrBrown)
	struct SegmentParameters &pa
	variable pinkOrBrown

	variable i, localAmplitude
	variable phase, frequency, numberOfBuildWaves

	frequency = pa.highPassCutOff
	numberOfBuildWaves = floor((pa.lowPassCutOff - pa.highPassCutOff) / pa.fIncrement)

	if(!IsFinite(pa.duration) || !IsFinite(numberOfBuildWaves) || pa.highPassCutOff == 0)
		print "Could not create a new pink/brown noise Wave as the input values were non-finite or zero."
		return NaN
	endif

	Make/FREE/n=(pa.duration / HARDWARE_ITC_MIN_SAMPINT, NumberOfBuildWaves) BuildWave
	SetScale/P x 0, HARDWARE_ITC_MIN_SAMPINT, "ms", BuildWave

	for(i = 0; i < numberOfBuildWaves; i += 1)
		phase = abs(enoise(2)) * Pi // random phase generator
		if(PinkOrBrown == 0)
			localAmplitude = 1 / frequency
		else
			localAmplitude = 1 / (frequency ^ 0.5)
		endif

		// factoring out Pi * 1e-05 actually makes it a tiny bit slower
		MultiThread BuildWave[][i] = localAmplitude * sin( Pi * pa.frequency * 1e-05 * p + phase)
		frequency += pa.fIncrement
	endfor

	MatrixOp/O/NTHR=0   SegmentWave = sumRows(BuildWave)
	SetScale/P x 0, HARDWARE_ITC_MIN_SAMPINT, "ms", SegmentWave

	WaveStats/Q SegmentWave
	SegmentWave *= pa.amplitude / V_sdev
End

/// @brief Create a wave segment as combination of existing stim sets
static Function/WAVE WB_FillWaveFromFormula(formula, channelType, sweep)
	string formula
	variable channelType
	variable sweep

	STRUCT FormulaProperties fp

	WB_UpdateEpochCombineList(channelType)

	if(WB_ParseCombinerFormula(formula, sweep, fp))
		return $""
	endif

	DEBUGPRINT("Formula:", str=fp.formula)

	DFREF dfr       = GetDataFolderDFR()
	DFREF targetDFR = GetSetFolder(channelType)

	SetDataFolder targetDFR
	Make/O/D/N=(fp.numRows) d
	Execute/Q/Z fp.formula

	if(V_Flag)
		printf "WB_FillWaveFromFormula: Error executing the formula \"%s\"\r", formula
		KillOrMoveToTrash(wv=d)
		SetDataFolder dfr
		return $""
	endif

	SetDataFolder dfr

	return MakeWaveFree(d)
End
/// @}

/// @brief Update the shorthand/stimset wave for the epoch type `Combine`
///
/// The rows are sorted by creationDate of the WP/stimset wave to try to keep
/// the shorthands constants even when new stimsets are added.
Function WB_UpdateEpochCombineList(channelType)
	variable channelType

	string list, setPath, setParamPath, entry
	variable numEntries, i

	list = ReturnListOfAllStimSets(channelType, "*")
	list = RemoveFromList("TestPulse", list)

	numEntries = ItemsInList(list)
	Make/D/FREE/N=(numEntries) creationDates
	Make/T/FREE/N=(numEntries) stimsets = StringFromList(p, list)

	DFREF dfr = GetSetFolder(channelType)

	for(i = 0; i < numEntries; i += 1)
		entry = StringFromList(i, list)
		WAVE/SDFR=dfr/Z stimset = $entry
		WAVE/Z WP = WB_GetWaveParamForSet(entry)

		if(WaveExists(WP))
			creationDates[i] = CreationDate(WP)
		elseif(WaveExists(stimset))
			creationDates[i] = CreationDate(stimset)
		else
			ASSERT(0, "Missing stimset/param wave")
		endif
	endfor

	Sort creationDates, stimsets

	Wave/T epochCombineList = GetWBEpochCombineList()
	Redimension/N=(numEntries, -1) epochCombineList

	epochCombineList[][%StimSet]   = stimsets[p]
	epochCombineList[][%Shorthand] = WB_GenerateUniqueLabel(p)
End

/// @brief Generate a unique textual representation of an index
///
/// Returns the alphabet for 1-26, and then A1, B1, ..., Z1000
static Function/S WB_GenerateUniqueLabel(idx)
	variable idx

	variable number, charNum
	string str

	charNum = mod(idx, 26)
	number  = floor(idx / 26)

	if(!number)
		return num2char(65 + charNum)
	endif

	sprintf str, "%s%d", num2char(65 + charNum), number
	return str
End

/// @brief Parse the formula from the epoch type `Combine`
///
/// @param[in]  formula  math formula to execute, all operators which Igor can grok are allowed
/// @param      sweep    current sweep (aka step)
/// @param[out] fp       parsed formula structure, with shorthands replaced by stimsets,
///                      empty on parse error, ready to be executed by WB_FillWaveFromFormula()
///
/// @returns 0 on success, 1 on parse errors (currently not many are found)
Function WB_ParseCombinerFormula(formula, sweep, fp)
	string formula
	variable sweep
	struct FormulaProperties &fp

	struct FormulaProperties trans
	WB_FormulaSwitchToStimset(formula, trans)

	InitFormulaProperties(fp)

	// and now we look for shorthand-like strings not referring to existing stimsets
	if(GrepString(trans.formula, "\\b[A-Z][0-9]*\\b"))
		printf "WBP_ParseCombinerFormula: Parse error in the formula \"%s\": Non-existing shorthand found\r", formula
		return 1
	endif

	if(sweep >= trans.numCols)
		printf "Requested step %d is larger as the minimum number of sweeps in the referenced stim sets\r", sweep
		return 1
	endif

	WB_PrepareFormulaForExecute(trans, sweep)

	if(strlen(trans.formula) >= MAX_COMMANDLINE_LENGTH)
		printf "WBP_ParseCombinerFormula: Parsed formula is too long to be executed in one step. Please shorten it and perform the desired task in two steps.\r"
		return 1
	endif

	fp = trans

	return 0
End

/// @brief Replace shorthands with the real stimset names suffixed with `?`
Function WB_FormulaSwitchToStimset(formula, fp)
	string formula
	struct FormulaProperties &fp

	string stimset, shorthand, replacedFormula, stimsetSpec
	variable numSets, i
	variable numRows = Inf
	variable numCols = Inf

	InitFormulaProperties(fp)

	if(isEmpty(formula))
		return NaN
	endif

	WAVE/T epochCombineList = GetWBEpochCombineList()

	formula = UpperStr(formula)

	// we replace, case sensitive!, all upper case shorthands with lower case
	// stimsets in that way we don't mess up the formula
	numSets = DimSize(epochCombineList, ROWS)
	for(i = 0; i < numSets; i += 1)
		shorthand   = epochCombineList[i][%Shorthand]
		stimset     = epochCombineList[i][%stimset]
		stimsetSpec = LowerStr(stimset) + "?"

		replacedFormula = ReplaceString(shorthand, formula, stimsetSpec, 1)

		if(cmpstr(replacedFormula, formula))
			// create the stimset as it is part of the formula
			WAVE/Z wv = WB_CreateAndGetStimSet(stimset)
			ASSERT(WaveExists(wv), "Could not recreate a required stimset")
			numRows = min(numRows, DimSize(wv, ROWS))
			numCols = min(numCols, DimSize(wv, COLS))
		endif

		formula = replacedFormula
	endfor

	fp.formula = formula
	fp.numRows = numRows
	fp.numCols = numCols
End

/// @brief Add wave ranges to every stimset (location marked by `?`) and
///        add a left hand side to the formula
Function WB_PrepareFormulaForExecute(fp, sweep)
	struct FormulaProperties &fp
	variable sweep

	string spec
	sprintf spec, "[p][%d]", sweep

	fp.formula = "d[]=" + ReplaceString("?", fp.formula, spec)
End

/// @brief Replace all stimsets suffixed with `?` by their shorthands
Function/S WB_FormulaSwitchToShorthand(formula)
	string formula

	variable numSets, i
	string stimset, shorthand

	if(isEmpty(formula))
		return ""
	endif

	WAVE/T epochCombineList = GetWBEpochCombineList()

	numSets = DimSize(epochCombineList, ROWS)
	for(i = 0; i < numSets; i += 1)
		shorthand = epochCombineList[i][%Shorthand]
		stimset   = epochCombineList[i][%stimset]

		formula = ReplaceString(stimset + "?", formula, shorthand)
	endfor

	return formula
End
