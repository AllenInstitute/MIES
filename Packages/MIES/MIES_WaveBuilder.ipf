#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict Wave access.

/// @file MIES_WaveBuilder.ipf
/// @brief __WB__ Stimulus set creation

static Constant MAX_SWEEP_DURATION_IN_MS = 1.8e6 // 30 minutes

static Constant PULSE_TRAIN_MODE_DUR   = 0x01
static Constant PULSE_TRAIN_MODE_PULSE = 0x02

static Constant WB_PULSE_TRAIN_TYPE_SQUARE   = 0
static Constant WB_PULSE_TRAIN_TYPE_TRIANGLE = 1

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

	variable i, numEpochs, numSweeps, updateEpochIDWave
	variable last, lengthOf1DWaves, length, channelType
	variable referenceTime = DEBUG_TIMER_START()

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

	numSweeps  = SegWvType[101]
	numEpochs  = SegWvType[100]

	ASSERT(numSweeps > 0, "Invalid number of sweeps")

	MAKE/WAVE/FREE/N=(numSweeps) data

	for(i=0; i < numSweeps; i+=1)
		data[i] = WB_MakeWaveBuilderWave(WPCopy, WPT, SegWvType, i, numEpochs, channelType, updateEpochIDWave)
		lengthOf1DWaves = max(DimSize(data[i], ROWS), lengthOf1DWaves)
		WB_AddDelta(WPCopy, numEpochs)
	endfor

	// copy the random seed value to WP in order to preserve it
	WP[48][][] = WPCopy[48][q][r]

	if(lengthOf1DWaves == 0)
		return $""
	endif

	Make/FREE/N=(lengthOf1DWaves, numSweeps) stimSet
	FastOp stimSet = 0

	SetScale/P x 0, HARDWARE_ITC_MIN_SAMPINT, "ms", stimset

	for(i = 0; i < numSweeps; i += 1)
		WAVE wv = data[i]

		length = DimSize(wv, ROWS)
		if(length == 0)
			continue
		endif

		last = length - 1
		Multithread stimSet[0, last][i] = wv[p]

		Note/NOCR stimSet, note(wv)
	endfor

	if(SegWvType[98])
		Duplicate/FREE stimset, stimsetFlipped
		for(i=0; i < numSweeps; i+=1)
			Duplicate/FREE/R=[][i] stimset, singleSweep
			WaveTransForm/O flip singleSweep
			Multithread stimSetFlipped[][i] = singleSweep[p]
		endfor
		WAVE stimset = stimsetFlipped
	endif

	DEBUGPRINT_ELAPSED(referenceTime)

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
	variable lowPassCutOff
	variable deltaLowPassCutOff
	variable highPassCutOff
	variable deltaHighPassCutOff
	variable filterOrder
	variable deltaFilterOrder
	variable endFrequency
	variable deltaEndFrequency
	variable numberOfPulses
	// checkboxes
	variable poisson
	variable sinChirp
	variable randomSeed
	// popupmenues
	variable trigFuncType // 0: sin, 1: cos
	variable noiseType // 0: white, 1: pink, 2:brown
	variable buildResolution // value, not the popup menu index
	variable pulseType // 0: square, 1: triangle
EndStructure

static Function/WAVE WB_MakeWaveBuilderWave(WP, WPT, SegWvType, stepCount, numEpochs, channelType, updateEpochIDWave)
	Wave WP
	Wave/T WPT
	Wave SegWvType
	variable stepCount, numEpochs, channelType, updateEpochIDWave

	Make/FREE/N=0 WaveBuilderWave

	string customWaveName, debugMsg, defMode, formula, formula_version
	string formula_for_note
	variable i, j, type, accumulatedDuration, pulseToPulseLength
	STRUCT SegmentParameters params

	for(i=0; i < numEpochs; i+=1)
		type = SegWvType[i]

		params.duration             = WP[0][i][type]
		params.deltaDur             = WP[1][i][type]
		params.amplitude            = WP[2][i][type]
		params.deltaAmp             = WP[3][i][type]
		params.offset               = WP[4][i][type]
		params.deltaOffset          = WP[5][i][type]
		params.frequency            = WP[6][i][type]
		params.deltaFreq            = WP[7][i][type]
		params.pulseDuration        = WP[8][i][type]
		params.deltaPulsedur        = WP[9][i][type]
		params.tauRise              = WP[10][i][type]
		params.deltaTauRise         = WP[11][i][type]
		params.tauDecay1            = WP[12][i][type]
		params.deltaTauDecay1       = WP[13][i][type]
		params.tauDecay2            = WP[14][i][type]
		params.deltaTauDecay2       = WP[15][i][type]
		params.tauDecay2Weight      = WP[16][i][type]
		params.deltaTauDecay2Weight = WP[17][i][type]
		params.lowPassCutOff        = WP[20][i][type]
		params.deltaLowPassCutOff   = WP[21][i][type]
		params.highPassCutOff       = WP[22][i][type]
		params.deltaHighPassCutOff  = WP[23][i][type]
		params.endFrequency         = WP[24][i][type]
		params.deltaEndFrequency    = WP[25][i][type]
		params.filterOrder          = WP[26][i][type]
		params.deltaFilterOrder     = WP[27][i][type]
		params.sinChirp             = WP[43][i][type]
		params.poisson              = WP[44][i][type]
		params.numberOfPulses       = WP[45][i][type]
		params.trigFuncType         = WP[53][i][type]
		params.noiseType            = WP[54][i][type]
		params.buildResolution      = str2num(StringFromList(WP[55][i][type], WBP_GetNoiseBuildResolution()))
		params.pulseType            = WP[56][i][type]

		sprintf debugMsg, "step count: %d, epoch: %d, duration: %g (delta %g), amplitude %d (delta %g)\r", stepCount, i, params.duration, params.DeltaDur, params.amplitude, params.DeltaAmp
		DEBUGPRINT("params", str=debugMsg)

		if(params.duration < 0 || !IsFinite(params.duration))
			Print "User input has generated a negative/non-finite epoch duration. Please adjust input. Duration for epoch has been reset to 1 ms."
			params.duration = 1
		elseif(params.duration == 0 && type != EPOCH_TYPE_CUSTOM && type != EPOCH_TYPE_COMBINE && type != EPOCH_TYPE_PULSE_TRAIN)
			continue
		endif

		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Sweep", var=stepCount)
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch", var=i)
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type" , str=WB_ToEpochTypeString(type))

		switch(type)
			case EPOCH_TYPE_SQUARE_PULSE:
				WB_SquareSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration" , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude", var=params.Amplitude)
				break
			case EPOCH_TYPE_RAMP:
				WB_RampSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration" , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude", var=params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"   , var=params.Offset)
				break
			case EPOCH_TYPE_NOISE:
				params.randomSeed = WB_InitializeSeed(WP, i, type, stepCount)

				WB_NoiseSegment(params)
				WAVE segmentWave = WB_GetSegmentWave()
				WBP_ShowFFTSpectrumIfReq(segmentWave, stepCount)

				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration"          , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude"         , var=params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"            , var=params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Noise Type"        , \
															str=StringFromList(params.noiseType, NOISE_TYPES_STRINGS))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Low pass cut off"  , var=params.LowPassCutOff)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "High pass cut off" , var=params.HighPassCutOff)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Filter order"      , var=params.filterOrder)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Build resolution"  , var=params.buildResolution)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Random seed"       , var=params.randomSeed)
				break
			case EPOCH_TYPE_SIN_COS:
				WB_TrigSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration"     , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude"    , var=params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"       , var=params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency"    , var=params.Frequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "End frequency", var=params.EndFrequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Log chirp"    , str=SelectString(params.SinChirp, "True", "False"))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "FunctionType" , str=SelectString(params.trigFuncType, "Sin", "Cos"))
				break
			case EPOCH_TYPE_SAW_TOOTH:
				WB_SawToothSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration" , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude", var=params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency", var=params.Frequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"   , var=params.Offset)
				break
			case EPOCH_TYPE_PULSE_TRAIN:
				params.randomSeed = WB_InitializeSeed(WP, i, type, stepCount)

				Make/FREE/D/N=(MINIMUM_WAVE_SIZE) pulseStartTimes

				if(WP[46][i][type]) // "Number of pulses" checkbox
					WB_PulseTrainSegment(params, PULSE_TRAIN_MODE_PULSE, pulseStartTimes, pulseToPulseLength)
					if(windowExists("WaveBuilder") && GetTabID("WaveBuilder", "WBP_WaveType") == EPOCH_TYPE_PULSE_TRAIN)
						WBP_UpdateControlAndWP("SetVar_WaveBuilder_P0", params.duration)
					endif
					defMode = "Pulse"
				else
					WB_PulseTrainSegment(params, PULSE_TRAIN_MODE_DUR, pulseStartTimes, pulseToPulseLength)
					if(windowExists("WaveBuilder") && GetTabID("WaveBuilder", "WBP_WaveType") == EPOCH_TYPE_PULSE_TRAIN)
						WBP_UpdateControlAndWP("SetVar_WaveBuilder_P45", params.numberOfPulses)
					endif
					defMode = "Duration"
				endif

				pulseStartTimes[] += accumulatedDuration

				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration"               , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude"              , var=params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"                 , var=params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Pulse Type"             , \
							               str=StringFromList(params.pulseType, PULSE_TYPES_STRINGS))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency"              , var=params.Frequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, PULSE_TO_PULSE_LENGTH_KEY, var=pulseToPulseLength)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Pulse duration"         , var=params.PulseDuration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Number of pulses"       , var=params.NumberOfPulses)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Poisson distribution"   , str=SelectString(params.poisson, "False", "True"))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Random seed"            , var=params.randomSeed)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, PULSE_START_TIMES_KEY    , str=NumericWaveToList(pulseStartTimes, ",", format="%.15g"))
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Definition mode"        , str=defMode)
				break
			case EPOCH_TYPE_PSC:
				WB_PSCSegment(params)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration"          , var=params.Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude"         , var=params.Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"            , var=params.Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau rise"          , var=params.TauRise)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau decay 1"       , var=params.TauDecay1)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau decay 2"       , var=params.TauDecay2)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau decay 2 weight", var=params.TauDecay2Weight)
				break
			case EPOCH_TYPE_CUSTOM:
				WAVE/Z customWave = $""
				customWaveName = WPT[0][i]

				// old style entries with only the wave name
				if(strsearch(customWaveName, ":", 0) == -1)
					printf "Warning: Legacy format for custom wave epochs detected.\r"

					if(windowExists("Wavebuilder"))
						DFREF customWaveDFR = WBP_GetFolderPath()
						Wave/Z/SDFR=customWaveDFR customWave = $customWaveName
					endif

					if(!WaveExists(customWave))
						DFREF customWaveDFR = GetSetFolder(channelType)
						Wave/Z/SDFR=customWaveDFR customWave = $customWaveName
					endif

					if(WaveExists(customWave))
						printf "Upgraded custom wave format successfully.\r"
						WPT[0][i] = GetWavesDataFolder(customWave, 2)
						customWaveName = WPT[0][i]
					endif
				else
					// try new style entries with full path
					WAVE/Z customWave = $customWaveName
				endif

				if(WaveExists(customWave))
					WB_CustomWaveSegment(params, customWave)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration"    , var=params.Duration)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"      , var=params.Offset)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "CustomWavePath", str=customWaveName)
				elseif(!isEmpty(customWaveName))
					printf "Failed to recreate custom wave epoch %d as the referenced wave %s is missing\r", i, customWaveName
				endif
				break
			case EPOCH_TYPE_COMBINE:
				WAVE segmentWave = WB_GetSegmentWave(duration=0)

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

				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Formula"         , str=formula_for_note)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Formula Version" , str=formula_version)
				break
			default:
				printf "Ignoring unknown epoch type %d\r", type
				continue
		endswitch

		// add CR as we have finished an epoch
		Note/NOCR WaveBuilderWave, "\r"

		if(type != EPOCH_TYPE_COMBINE)
			WB_ApplyOffset(params)
		endif

		if(updateEpochIDWave)
			if(stepCount == 0)
				WAVE epochID = GetEpochID()
				if(i == 0)
					epochID = 0
				endif
				epochID[i][%timeBegin] = accumulatedDuration
				epochID[i][%timeEnd]   = accumulatedDuration + params.duration
			endif
		endif

		WAVE segmentWave = WB_GetSegmentWave()
		accumulatedDuration += DimSize(segmentWave, ROWS) * HARDWARE_ITC_MIN_SAMPINT

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

	// add stimset entries at last step
	if(stepCount + 1 == SegWvType[101])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Stimset")
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "ITI", var=SegWvType[99])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(PRE_DAQ_EVENT, EVENT_NAME_LIST), str=WPT[1][99])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(MID_SWEEP_EVENT, EVENT_NAME_LIST), str=WPT[2][99])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(POST_SWEEP_EVENT, EVENT_NAME_LIST), str=WPT[3][99])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(POST_SET_EVENT, EVENT_NAME_LIST), str=WPT[4][99])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, StringFromList(POST_DAQ_EVENT, EVENT_NAME_LIST), str=WPT[5][99])
		AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Flip", var=SegWvType[98], appendCR=1)
	endif

	return WaveBuilderWave
End

static Function WB_ApplyOffset(pa)
	struct SegmentParameters &pa

	if(pa.offset == 0)
		return NaN
	endif

	WAVE SegmentWave = WB_GetSegmentWave()

	MultiThread segmentWave[] += pa.offset
End

/// @brief Initialize the seed value of the pseudo random number generator
static Function WB_InitializeSeed(WP, epoch, type, stepCount)
	WAVE WP
	variable epoch, type, stepCount

	variable j, randomSeed

	// initialize the random seed value if not already done
	if(WP[48][epoch][type] == 0)
		WP[48][epoch][type] = GetNonReproducibleRandom()
	endif

	randomSeed = WP[48][epoch][type]
	SetRandomSeed/BETR=1 randomSeed

	if(WP[49][epoch][type])
		// the stored seed value is the seed value for the *generation*
		// of the individual seed values for each step
		// Procedure:
		// - Initialize RNG with stored seed
		// - Query as many random numbers as current step count
		// - Use the *last* random number as seed value for the new epoch
		// In this way we get a different seed value for each step, but all are reproducibly
		// derived from one seed value. And we still have different values for different epochs.
		for(j = 1; j <= stepCount; j += 1)
			randomSeed = GetReproducibleRandom()
		endfor

		SetRandomSeed/BETR=1 randomSeed
	endif

	return randomSeed
End

/// @brief Returns the segment wave which stores the stimulus set of one segment/epoch
/// @param duration time of the stimulus in ms
static Function/Wave WB_GetSegmentWave([duration])
	variable duration

	DFREF dfr = GetWaveBuilderDataPath()
	variable numPoints = duration / HARDWARE_ITC_MIN_SAMPINT
	Wave/Z/SDFR=dfr SegmentWave

	if(ParamIsDefault(duration))
		return segmentWave
	endif

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

	Wave SegmentWave = WB_GetSegmentWave(duration=pa.duration)
	MultiThread SegmentWave = pa.amplitude
End

static Function WB_RampSegment(pa)
	struct SegmentParameters &pa

	variable amplitudeIncrement = pa.amplitude * HARDWARE_ITC_MIN_SAMPINT / pa.duration

	Wave SegmentWave = WB_GetSegmentWave(duration=pa.duration)
	MultiThread SegmentWave = amplitudeIncrement * p
End

/// @brief Check if the given frequency is a valid setting for the noise epoch
Function WB_IsValidCutoffFrequency(freq)
	variable freq

	return WB_IsValidScaledCutoffFrequency(freq / HARDWARE_ITC_MIN_SAMPINT_HZ)
End

/// @brief Check if the given frequency is a valid setting for the noise epoch
///
/// Requires a scaled frequency as input, see `DisplayHelpTopic "FilterIIR"`
Function WB_IsValidScaledCutoffFrequency(freq)
	variable freq

	return freq > 0 && freq <= 0.5
End

static Function WB_NoiseSegment(pa)
	STRUCT SegmentParameters &pa

	variable samples, filterOrder
	variable lowPassCutoffScaled, highPassCutoffScaled
	variable referenceTime = DEBUG_TIMER_START()

	ASSERT(IsInteger(pa.buildResolution) && pa.buildResolution > 0, "Invalid build resolution")

	// duration is in ms
	samples = pa.duration * pa.buildResolution * HARDWARE_ITC_MIN_SAMPINT_HZ * 1e-3

	// even number of points for IFFT
	samples = 2 * ceil(samples / 2)

	Make/FREE/D/C/N=(samples / 2 + 1) magphase
	FastOp magphase = 0
	SetScale/P x 0, HARDWARE_ITC_MIN_SAMPINT_HZ/samples, "Hz" magphase

	// we can't use Multithread here as this creates non-reproducible data
	switch(pa.noiseType)
		case NOISE_TYPE_WHITE:
			magphase[1, inf] = cmplx(1, enoise(Pi, NOISE_GEN_MERSENNE_TWISTER))
			break
		case NOISE_TYPE_PINK: // drops with 10db per decade
			magphase[1, inf] = cmplx(1/sqrt(x), enoise(Pi, NOISE_GEN_MERSENNE_TWISTER))
			break
		case NOISE_TYPE_BROWN: // drops with 20db per decade
			magphase[1, inf] = cmplx(1/x, enoise(Pi, NOISE_GEN_MERSENNE_TWISTER))
			break
		default:
			ASSERT(0, "Invalid noise type")
			break
	endswitch

	WAVE SegmentWave = WB_GetSegmentWave(duration=pa.duration)

#ifdef DEBUGGING_ENABLED
	Duplicate/O magphase, noiseEpochMagnitude
	Redimension/R noiseEpochMagnitude
	Duplicate/O magphase, noiseEpochPhase
	Redimension/R noiseEpochPhase

	MultiThread noiseEpochPhase = imag(magphase[p]) * 180 / Pi
	MultiThread noiseEpochMagnitude = 20 * log(real(magphase[p]))
#endif // DEBUGGING_ENABLED

	MultiThread magphase = p2Rect(magphase)
	IFFT/R/DEST=SegmentWave magphase

	ASSERT(!cmpstr(WaveUnits(segmentWave, ROWS), "s"), "Unexpect wave unit")
	ASSERT(DimOffset(segmentWave, ROWS) == 0, "Unexpected wave rows offset")
	SetScale/P x, 0, DimDelta(segmentWave, ROWS) * 1000, "ms", segmentWave

	Redimension/N=(DimSize(segmentWave, ROWS) / pa.buildResolution) segmentWave

	lowPassCutoffScaled  = pa.lowpasscutoff  / HARDWARE_ITC_MIN_SAMPINT_HZ
	highPassCutoffScaled = pa.highpasscutoff / HARDWARE_ITC_MIN_SAMPINT_HZ

	if(WB_IsValidScaledCutoffFrequency(lowPassCutoffScaled) && WB_IsValidScaledCutoffFrequency(highPassCutoffScaled))
		FilterIIR/CASC/LO=(lowPassCutoffScaled)/HI=(highPassCutoffScaled)/ORD=(pa.filterOrder) segmentWave
	elseif(WB_IsValidScaledCutoffFrequency(lowPassCutoffScaled))
		FilterIIR/CASC/LO=(lowPassCutoffScaled)/ORD=(pa.filterOrder) segmentWave
	elseif(WB_IsValidScaledCutoffFrequency(highPassCutoffScaled))
		FilterIIR/CASC/HI=(highPassCutoffScaled)/ORD=(pa.filterOrder) segmentWave
	else
		// do nothing
	endif

	MatrixOp/FREE scaleFactor = pa.amplitude / (maxVal(segmentWave) - minVal(segmentWave)))
	MultiThread segmentWave[] = segmentWave[p] * scaleFactor[0] // ScaleFactor is a 1x1 matrix

	DEBUGPRINT_ELAPSED(referenceTime)
End

static Function WB_TrigSegment(pa)
	struct SegmentParameters &pa

	variable k0, k1, k2, k3

	if(pa.trigFuncType != 0 && pa.trigFuncType != 1)
		printf "Ignoring unknown trigonometric function"
		Wave SegmentWave = WB_GetSegmentWave(duration=0)
		return NaN
	endif

	Wave SegmentWave = WB_GetSegmentWave(duration=pa.duration)

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
End

static Function WB_SawToothSegment(pa)
	struct SegmentParameters &pa

	Wave SegmentWave = WB_GetSegmentWave(duration=pa.duration)

#if (IgorVersion() >= 7.02)
	MultiThread SegmentWave = 1 * pa.amplitude * sawtooth(2 * Pi * (pa.frequency * 1000) * (5 / 1000000000) * p)
#else
	SegmentWave = 1 * pa.amplitude * sawtooth(2 * Pi * (pa.frequency * 1000) * (5 / 1000000000) * p)
#endif

End

static Function WB_CreatePulse(wv, pulseType, amplitude, first, last)
	WAVE wv
	variable pulseType, amplitude, first, last

	if(pulseType == WB_PULSE_TRAIN_TYPE_SQUARE)
		wv[first, last] = amplitude
	elseif(pulseType == WB_PULSE_TRAIN_TYPE_TRIANGLE)
		wv[first, last] = amplitude * (p - first) / (last - first)
	else
		ASSERT(0, "unknown pulse type")
	endif
End

/// @brief Convert the numeric epoch type to a stringified version
Function/S WB_ToEpochTypeString(epochType)
	variable epochType

	switch(epochType)
		case EPOCH_TYPE_SQUARE_PULSE:
			return "Square pulse"
		case EPOCH_TYPE_RAMP:
			return "Ramp"
		case EPOCH_TYPE_NOISE:
			return "Noise"
		case EPOCH_TYPE_SIN_COS:
			return "Sin Wave"
		case EPOCH_TYPE_SAW_TOOTH:
			return "Saw tooth"
		case EPOCH_TYPE_PULSE_TRAIN:
			return "Pulse Train"
		case EPOCH_TYPE_PSC:
			return "PSC"
		case EPOCH_TYPE_CUSTOM:
			return "Custom Wave"
		case EPOCH_TYPE_COMBINE:
			return "Combine"
		default:
			ASSERT(0, "Unknown epoch: " + num2str(epochType))
			return ""
	endswitch
End

/// @brief Convert the stringified epoch type to a numerical one
Function WB_ToEpochType(epochTypeStr)
	string epochTypeStr

	strswitch(epochTypeStr)
		case "Square pulse":
			return EPOCH_TYPE_SQUARE_PULSE
		case "Ramp":
			return EPOCH_TYPE_RAMP
		case "Noise":
			return EPOCH_TYPE_NOISE
		case "Sin Wave":
			return EPOCH_TYPE_SIN_COS
		case "Saw tooth":
			return EPOCH_TYPE_SAW_TOOTH
		case "Pulse Train":
			return EPOCH_TYPE_PULSE_TRAIN
		case "PSC":
			return EPOCH_TYPE_PSC
		case "Custom Wave":
			return EPOCH_TYPE_CUSTOM
		case "Combine":
			return EPOCH_TYPE_COMBINE
		default:
			ASSERT(0, "Unknown epoch: " + epochTypeStr)
			return NaN
	endswitch
End

/// @brief Extract a list of [begin, end] ranges in milliseconds denoting
///        all pulses from all pulse train epochs in that sweep of the stimset
Function/WAVE WB_GetPulsesFromPulseTrains(stimset, sweep, pulseToPulseLength)
	WAVE stimset
	variable sweep
	variable &pulseToPulseLength

	string str, matches, startTimesList, line, epochTypeStr, pulseToPulseLengthStr
	variable i, numMatches, epochType, flipping, length, pulseDuration

	Make/FREE/D/N=(0) allStartTimes

	str = note(stimset)

	pulseToPulseLength = NaN

	// passed stimset is from the testpulse
	if(IsEmpty(str))
		return allStartTimes
	endif

	matches = GrepList(str, "^Stimset;", 0, "\r")
	ASSERT(!IsEmpty(matches), "Could not find stimset settings entry in note")
	line = matches

	flipping = NumberByKey("Flip", line, " = ", ";")
	ASSERT(flipping == 0 || flipping == 1, "Invalid flipping value")

	ASSERT(IsInteger(sweep) && sweep >= 0, "Invalid sweep")
	matches = GrepList(str, "^Sweep = " + num2str(sweep), 0, "\r")

	numMatches = ItemsInList(matches, "\r")
	for(i = 0; i < numMatches; i += 1)
		line = trimstring(StringFromList(i, matches, "\r"), 1)

		epochTypeStr = StringByKey("Type", line, " = ", ";")
		epochType = WB_ToEpochType(epochTypeStr)

		/// @todo support combine stimsets as soon as mk/save/stimset is merged
		if(epochType != EPOCH_TYPE_PULSE_TRAIN)
			continue
		endif

		startTimesList = StringByKey(PULSE_START_TIMES_KEY, line, " = ", ";")
		ASSERT(!IsEmpty(startTimesList), "Could not find pulse start times entry")

		pulseToPulseLengthStr = StringByKey(PULSE_TO_PULSE_LENGTH_KEY, line, " = ", ";")
		ASSERT(!IsEmpty(pulseToPulseLengthStr), "Could not find pulse to pulse lengths")

		pulseToPulseLength = str2num(pulseToPulseLengthStr)

		WAVE/Z/D startTimes = ListToNumericWave(startTimesList, ",")
		ASSERT(WaveExists(startTimes) && DimSize(startTimes, ROWS) > 0, "Found no starting times")

		FindValue/V=(NaN) startTimes
		ASSERT(V_Value == -1, "Unexpected NaN found in starting times")

		if(flipping)
			pulseDuration = NumberByKey("Pulse Duration", line, " = ", ";")
			ASSERT(IsFinite(pulseDuration) && pulseDuration > 0, "Invalid pulse duration")

			length = rightx(stimset)
			// mirroring must also move the startTimes by the pulseDuration
			startTimes[] = length - startTimes[p] - pulseDuration
		endif

		Concatenate/NP=0 {startTimes}, allStartTimes
	endfor

	Sort allStartTimes, allStartTimes

	return allStartTimes
End

static Function/WAVE WB_PulseTrainSegment(pa, mode, pulseStartTimes, pulseToPulseLength)
	struct SegmentParameters &pa
	variable mode
	WAVE pulseStartTimes
	variable &pulseToPulseLength

	variable pulseStartTime, endIndex, startIndex
	variable numRows, interPulseInterval, idx
	string str

	if(!(pa.frequency > 0))
		printf "Resetting invalid frequency of %gHz to 1Hz\r", pa.frequency
		pa.frequency = 1.0
	endif

	if(mode == PULSE_TRAIN_MODE_PULSE)
		// user defined number of pulses
		pa.duration = pa.numberOfPulses / pa.frequency * 1000
	elseif(mode == PULSE_TRAIN_MODE_DUR)
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

	WAVE segmentWave = WB_GetSegmentWave(duration=pa.duration)
	FastOp segmentWave = 0
	numRows = DimSize(segmentWave, ROWS)

	if(!pa.poisson)

		pulseToPulseLength = interPulseInterval + pa.pulseDuration

		for(;;)
			endIndex = floor((pulseStartTime + pa.pulseDuration) / HARDWARE_ITC_MIN_SAMPINT)

			if(endIndex >= numRows || endIndex < 0)
				break
			endif

			startIndex = floor(pulseStartTime / HARDWARE_ITC_MIN_SAMPINT)
			WB_CreatePulse(segmentWave, pa.pulseType, pa.amplitude, startIndex, endIndex)

			EnsureLargeEnoughWave(pulseStartTimes, minimumSize=idx)
			pulseStartTimes[idx++] = pulseStartTime

			pulseStartTime += interPulseInterval + pa.pulseDuration
		endfor
	else

		pulseToPulseLength = 0

		for(;;)
			pulseStartTime += -ln(abs(enoise(1, NOISE_GEN_MERSENNE_TWISTER))) / pa.frequency * 1000
			endIndex = floor((pulseStartTime + pa.pulseDuration) / HARDWARE_ITC_MIN_SAMPINT)

			if(endIndex >= numRows || endIndex < 0)
				break
			endif

			startIndex = floor(pulseStartTime / HARDWARE_ITC_MIN_SAMPINT)
			WB_CreatePulse(segmentWave, pa.pulseType, pa.amplitude, startIndex, endIndex)

			EnsureLargeEnoughWave(pulseStartTimes, minimumSize=idx)
			pulseStartTimes[idx++] = pulseStartTime
		endfor
	endif

	Redimension/N=(idx) pulseStartTimes

	// remove the zero part at the end
	FindValue/V=(0)/S=(pa.pulseType == WB_PULSE_TRAIN_TYPE_SQUARE ? startIndex : startIndex + 1) segmentWave
	if(V_Value != -1)
		DEBUGPRINT("Removal of points:", var=(DimSize(segmentWave, ROWS) - V_Value))
		Redimension/N=(V_Value) segmentWave
		pa.duration = V_Value * HARDWARE_ITC_MIN_SAMPINT
	else
		DEBUGPRINT("No removal of points")
	endif

	sprintf str, "interPulseInterval=%g ms, numberOfPulses=%g [a.u.], pulseDuration=%g [ms], real duration=%.6f [a.u.]\r", \
	 			  interPulseInterval, pa.numberOfPulses, pa.pulseDuration, DimSize(segmentWave, ROWS) * HARDWARE_ITC_MIN_SAMPINT

	DEBUGPRINT(str)
End

static Function WB_PSCSegment(pa)
	struct SegmentParameters &pa

	variable baseline, peak

	Wave SegmentWave = WB_GetSegmentWave(duration=pa.duration)

	pa.TauRise = 1 / pa.TauRise
	pa.TauRise *= HARDWARE_ITC_MIN_SAMPINT
	pa.TauDecay1 = 1 / pa.TauDecay1
	pa.TauDecay1 *= HARDWARE_ITC_MIN_SAMPINT
	pa.TauDecay2 = 1 / pa.TauDecay2
	pa.TauDecay2 *= HARDWARE_ITC_MIN_SAMPINT

	MultiThread SegmentWave[] = pa.amplitude * ((1 - exp(-pa.TauRise * p)) + exp(-pa.TauDecay1 * p) * (1 - pa.TauDecay2Weight) + exp(-pa.TauDecay2 * p) * pa.TauDecay2Weight)

	baseline = WaveMin(SegmentWave)
	peak = WaveMax(SegmentWave)
	MultiThread SegmentWave *= abs(pa.amplitude)/(peak - baseline)

	baseline = WaveMin(SegmentWave)
	MultiThread SegmentWave -= baseline
End

static Function WB_CustomWaveSegment(pa, customWave)
	struct SegmentParameters &pa
	WAVE customWave

	pa.duration = DimSize(customWave, ROWS) * HARDWARE_ITC_MIN_SAMPINT
	WAVE segmentWave = WB_GetSegmentWave(duration=pa.duration)
	MultiThread segmentWave[] = customWave[p]
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

	string stimset, shorthand, stimsetSpec, prefix, suffix
	variable numSets, i, stimsetFound
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
	// iterate the stimset list from bottom to top, so that we replace first the shorthands
	// with numeric prefix and only later on the ones without
	numSets = DimSize(epochCombineList, ROWS)
	for(i = numSets - 1; i >= 0; i -= 1)
		shorthand   = epochCombineList[i][%Shorthand]
		stimset     = epochCombineList[i][%stimset]
		stimsetSpec = LowerStr(stimset) + "?"
		stimsetFound = 0

		// search and replace until shorthand isn't found in formula anymore.
		ASSERT(!SearchWordInString(stimsetSpec, shorthand), "circle reference: shorthand is part of stimset. prevented infinite loop")
		do
			if(!SearchWordInString(formula, shorthand, prefix = prefix, suffix = suffix))
				break
			endif
			formula = prefix + stimsetSpec + suffix
			stimsetFound = 1
		while(1)

		// create the stimset if it is part of the formula
		if(stimsetFound)
			WAVE/Z wv = WB_CreateAndGetStimSet(stimset)
			ASSERT(WaveExists(wv), "Could not recreate a required stimset")
			numRows = min(numRows, DimSize(wv, ROWS))
			numCols = min(numCols, DimSize(wv, COLS))
		endif
	endfor

	fp.formula = formula
	fp.numRows = numRows
	fp.numCols = numCols
End

/// @brief Add wave ranges to every stimset (location marked by `?`) and
///        add a left hand side to the formula
static Function WB_PrepareFormulaForExecute(fp, sweep)
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
