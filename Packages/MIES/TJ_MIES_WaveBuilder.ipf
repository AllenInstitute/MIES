#pragma rtGlobals=3		// Use modern global access method and strict Wave access.

static Constant MAX_SWEEP_DURATION_IN_MS = 1.8e6 // 30 minutes

static Constant SQUARE_PULSE_TRAIN_MODE_DUR   = 0x01
static Constant SQUARE_PULSE_TRAIN_MODE_PULSE = 0x02

/// @brief Return the stim set wave and create it permanently
/// in the datafolder hierarchy
/// @return stimset wave ref or an invalid wave ref
Function/Wave WB_CreateAndGetStimSet(setName)
	string setName

	variable type, needToCreateStimSet

	type = GetStimSetType(setName)
	DFREF dfr = GetSetFolder(type)
	WAVE/Z/SDFR=dfr stimSet = $setName

	if(!WaveExists(stimSet))
		needToCreateStimSet = 1
	elseif(WaveExists(stimSet) && WBP_ParameterWvsNewerThanStim(setName))
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
			KillOrMoveToTrash(GetWavesDataFolder(oldStimSet, 2))
		endif

		MoveWave stimSet, dfr:$setName
		WAVE/SDFR=dfr stimSet = $setName
	endif

	return stimSet
End

/// @return One if one of the parameter waves is newer than the stim set wave, zero otherwise
static Function WBP_ParameterWvsNewerThanStim(setName)
	string setName

	variable type, lastModStimSet

	type = GetStimSetType(setName)
	DFREF dfr = GetSetParamFolder(type)
	WAVE/Z/SDFR=dfr   WP        = $("WP"        + "_" + setName)
	WAVE/Z/T/SDFR=dfr WPT       = $("WPT"       + "_" + setName)
	WAVE/Z/SDFR=dfr   SegWvType = $("SegWvType" + "_" + setName)

	if(WaveExists(WP) && WaveExists(WPT) && WaveExists(SegWvType))

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
/// @param setName [optional, defaults to WaveBuilderPanel GUI settings] name of the set
/// @return free wave with the stim set, invalid wave ref if the `WP*` parameter waves could
/// not be found.
Function/Wave WB_GetStimSet([setName])
	string setName

	variable i, numEpochs, numSteps, updateEpochIDWave
	variable last, lengthOf1DWaves, type, length
	string wvName
	variable start = stopmstimer(-2)

	if(ParamIsDefault(setName))
		updateEpochIDWave = 1

		WAVE WP        = GetWaveBuilderWaveParam()
		WAVE/T WPT     = GetWaveBuilderWaveTextParam()
		WAVE SegWvType = GetSegmentTypeWave()
	else
		type = GetStimSetType(setName)
		DFREF dfr = GetSetParamFolder(type)

		WAVE/Z/SDFR=dfr   WP        = $("WP"        + "_" + setName)
		WAVE/Z/T/SDFR=dfr WPT       = $("WPT"       + "_" + setName)
		WAVE/Z/SDFR=dfr   SegWvType = $("SegWvType" + "_" + setName)

		if(!WaveExists(WP) || !WaveExists(WPT) || !WaveExists(SegWvType))
			return $""
		endif
	endif

	// WB_AddDelta modifies WP so we pass a copy instead
	Duplicate/FREE WP, WPCopy

	numSteps   = SegWvType[101]
	numEpochs  = SegWvType[100]

	MAKE/WAVE/FREE/N=(numSteps) stepData

	for(i=0; i < numSteps; i+=1)
		stepData[i] = WB_MakeWaveBuilderWave(WPCopy, WPT, SegWvType, i, numEpochs, updateEpochIDWave)
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
EndStructure

static Function/WAVE WB_MakeWaveBuilderWave(WP, WPT, SegWvType, stepCount, numEpochs, updateEpochIDWave)
	Wave WP
	Wave/T WPT
	Wave SegWvType
	variable stepCount, numEpochs, updateEpochIDWave

	DFREF dfr = GetWaveBuilderDataPath()

	Make/FREE/N=0 WaveBuilderWave

	string customWaveName, debugMsg, defMode
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
				WB_SinSegment(params)
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

				Wave/Z/SDFR=WBP_GetFolderPath() customWave = $customWaveName

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
			default:
				ASSERT(0, "Unknown Wave type to create")
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

	AddEntryIntoWaveNoteAsList(WaveBuilderWave, "ITI", var=SegWvType[99], appendCR=1)

	SetScale /P x 0, MINIMUM_SAMPLING_INTERVAL, "ms", WaveBuilderWave
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
	variable numPoints = duration / MINIMUM_SAMPLING_INTERVAL
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

	SetScale/P x 0, MINIMUM_SAMPLING_INTERVAL, "ms", SegmentWave

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

	variable amplitudeIncrement = pa.amplitude * MINIMUM_SAMPLING_INTERVAL / pa.duration

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

static Function WB_SinSegment(pa)
	struct SegmentParameters &pa

	variable k0, k1, k2, k3
	string cmd

	Wave SegmentWave = WB_GetSegmentWave(pa.duration)

	if(!pa.sinChirp)
		MultiThread SegmentWave = pa.amplitude * sin(2 * Pi * (pa.frequency * 1000) * (5 / 1000000000) * p)
	else
		 k0 = ln(pa.frequency / 1000)
		 k1 = (ln(pa.endFrequency / 1000) - k0) / (pa.duration)
		 k2 = 2 * pi * e^k0 / k1
		 k3 = mod(k2, 2 * pi)		// LH040117: start on rising edge of sin and don't try to round.
		 MultiThread SegmentWave = pa.amplitude * sin(k2 * e^(k1 * x) - k3)
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
			endIndex = floor((pulseStartTime + pa.pulseDuration) / MINIMUM_SAMPLING_INTERVAL)

			if(endIndex >= numRows || endIndex < 0)
				break
			endif

			startIndex = floor(pulseStartTime / MINIMUM_SAMPLING_INTERVAL)
			segmentWave[startIndex, endIndex] = pa.amplitude
			pulseStartTime += interPulseInterval + pa.pulseDuration
		endfor
	else
		for(;;)
			pulseStartTime += -ln(abs(enoise(1))) / pa.frequency * 1000
			endIndex = floor((pulseStartTime + pa.pulseDuration) / MINIMUM_SAMPLING_INTERVAL)

			if(endIndex >= numRows || endIndex < 0)
				break
			endif

			startIndex = floor(pulseStartTime / MINIMUM_SAMPLING_INTERVAL)
			segmentWave[startIndex, endIndex] = pa.amplitude
		endfor
	endif

	// remove the zero part at the end
	FindValue/V=(0)/S=(startIndex) segmentWave
	if(V_Value != -1)
		DEBUGPRINT("Removal of points:", var=(DimSize(segmentWave, ROWS) - V_Value))
		Redimension/N=(V_Value) segmentWave
		pa.duration = V_Value * MINIMUM_SAMPLING_INTERVAL
	else
		DEBUGPRINT("No removal of points")
	endif

	segmentWave += pa.offset

	DEBUGPRINT("interPulseInterval", var=interPulseInterval)
	DEBUGPRINT("numberOfPulses", var=pa.numberOfPulses)
	DEBUGPRINT("Real duration", var=DimSize(segmentWave, ROWS) * MINIMUM_SAMPLING_INTERVAL, format="%.6f")
End

static Function WB_PSCSegment(pa)
	struct SegmentParameters &pa

	variable baseline, peak

	Wave SegmentWave = WB_GetSegmentWave(pa.duration)

	pa.TauRise = 1 / pa.TauRise
	pa.TauRise *= MINIMUM_SAMPLING_INTERVAL
	pa.TauDecay1 = 1 / pa.TauDecay1
	pa.TauDecay1 *= MINIMUM_SAMPLING_INTERVAL
	pa.TauDecay2 = 1 / pa.TauDecay2
	pa.TauDecay2 *= MINIMUM_SAMPLING_INTERVAL

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

	Make/FREE/n=(pa.duration / MINIMUM_SAMPLING_INTERVAL, NumberOfBuildWaves) BuildWave
	SetScale/P x 0, MINIMUM_SAMPLING_INTERVAL, "ms", BuildWave

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
	SetScale/P x 0, MINIMUM_SAMPLING_INTERVAL, "ms", SegmentWave

	WaveStats/Q SegmentWave
	SegmentWave *= pa.amplitude / V_sdev
End
/// @}
