#pragma rtGlobals=3		// Use modern global access method and strict Wave access.

static Constant MAX_SWEEP_DURATION_IN_MS = 1.8e6 // 30 minutes

static Constant SQUARE_PULSE_TRAIN_MODE_DUR   = 0x01
static Constant SQUARE_PULSE_TRAIN_MODE_PULSE = 0x02

Function WB_MakeStimSet()

	variable i, numEpochs, numSteps, setNumber
	string basename, outputType, outputWaveName
	variable start = stopmstimer(-2)

	WAVE WP = GetWaveBuilderWaveParam()

	// WB_AddDelta modifies WP so we pass a copy instead
	Duplicate/FREE WP, WPCopy

	basename = GetSetVariableString("WaveBuilder", "setvar_WaveBuilder_baseName")
	basename = basename[0,15]

	setNumber  = GetSetVariable("WaveBuilder", "setvar_WaveBuilder_SetNumber")
	numSteps   = GetSetVariable("WaveBuilder", "setVar_WaveBuilder_StepCount")
	outputType = GetPopupMenuString("WaveBuilder", "popup_WaveBuilder_OutputType")
	numEpochs  = GetSetVariable("WaveBuilder", "SetVar_WaveBuilder_NoOfEpochs")

	for(i=0; i < numSteps; i+=1)
		outputWaveName = "X" + num2str(i + 1) + "_" + basename + "_" + outputType + "_" + num2str(setNumber)
		WB_MakeWaveBuilderWave(WPCopy, i, numEpochs, outputWaveName)
		WB_AddDelta(WPCopy, numEpochs)
	endfor

	DEBUGPRINT("copying took (ms):", var=(stopmstimer(-2) - start) / 1000)
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

Structure SegmentParameters
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
EndStructure

static Function WB_MakeWaveBuilderWave(WP, stepCount, numEpochs, wvName)
	Wave WP
	variable stepCount
	variable numEpochs
	string wvName

	dfref dfr = GetWaveBuilderDataPath()
	Wave/SDFR=dfr SegWvType
	Make/O/N=0 dfr:$wvName/Wave=WaveBuilderWave

	string customWaveName, debugMsg, defMode
	variable i, type, accumulatedDuration, tabID
	STRUCT SegmentParameters params

	WAVE/T WPT = GetWaveBuilderWaveTextParam()

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
				tabID = GetTabID("WaveBuilder", "WBP_WaveType")
				if(WP[46][i][type]) // "Number of pulses" checkbox
					WB_SquarePulseTrainSegment(params, SQUARE_PULSE_TRAIN_MODE_PULSE)
					if(tabID == 5)
						WBP_UpdateControlAndWP("SetVar_WaveBuilder_P0", params.duration)
					endif
					defMode = "Pulse"
				else
					WB_SquarePulseTrainSegment(params, SQUARE_PULSE_TRAIN_MODE_DUR)
					if(tabID == 5)
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

		if(stepCount == 0)
			WAVE epochID = GetEpochID()
			epochID[i][%timeBegin] = accumulatedDuration
			epochID[i][%timeEnd]   = accumulatedDuration + params.duration

			accumulatedDuration += params.duration
		endif

		WAVE/SDFR=dfr segmentWave
		Concatenate/NP=0 {segmentWave}, WaveBuilderWave
	endfor

	AddEntryIntoWaveNoteAsList(WaveBuilderWave, "ITI", var=SegWvType[99], appendCR=1)

	SetScale /P x 0, MINIMUM_SAMPLING_INTERVAL, "ms", WaveBuilderWave
	// although we are not creating these globals anymore, we still try to kill them
	KillVariables/Z ParameterHolder
	KillStrings/Z StringHolder
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

	variable brownCheck, pinkCheck, PinkOrBrown

	Wave SegmentWave = WB_GetSegmentWave(pa.duration)

	pinkCheck  = GetCheckBoxState("Wavebuilder", "check_Noise_Pink_P41")
	brownCheck = GetCheckBoxState("Wavebuilder", "Check_Noise_Brown_P42")

	if(!brownCheck && !pinkCheck)
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
	elseif(pinkCheck)
		WB_PinkAndBrownNoise(pa, 0)
	elseif(brownCheck)
		WB_PinkAndBrownNoise(pa, 1)
	endif

	SegmentWave += pa.offset
End

static Function WB_SinSegment(pa)
	struct SegmentParameters &pa

	variable k0, k1, k2, k3
	string cmd

	Wave SegmentWave = WB_GetSegmentWave(pa.duration)

	if(!GetCheckBoxState("Wavebuilder","check_Sin_Chirp_P43"))
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
		pa.numberOfPulses = round(pa.frequency * pa.duration / 1000)
	else
		ASSERT(0, "Invalid mode")
	endif

	// We want the segment starting and ending with a pulse.
	// With the following definitions
	//
	// duration:             t
	// pulse duration:       p
	// inter pulse interval: x
	// number of pulses:     n
	// frequency:            f
	//
	// we know that
	//
	// (p + x)(n - 1) + p = t
	//
	// which gives
	//
	// x = t - np / (n - 1)

	// We remove one point from the duration.
	// This is done in order to create, for situations with t = 1000, f = 5, p = 100, the expected five pulses (n = 5)
	interPulseInterval = ((pa.duration/MINIMUM_SAMPLING_INTERVAL - 1) * MINIMUM_SAMPLING_INTERVAL - pa.numberOfPulses * pa.pulseDuration) / (pa.numberOfPulses - 1)

	WAVE segmentWave = WB_GetSegmentWave(pa.duration)
	segmentWave = 0
	numRows = DimSize(segmentWave, ROWS)

	if(!GetCheckBoxState("Wavebuilder", "check_SPT_Poisson_P44"))
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
		Redimension/N=(V_Value) segmentWave
		pa.duration = V_Value * MINIMUM_SAMPLING_INTERVAL
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

/// PinkOrBrown Pink = 0, Brown = 1
static Function WB_PinkAndBrownNoise(pa, pinkOrBrown)
	struct SegmentParameters &pa
	variable pinkOrBrown

	variable phase = abs(enoise(2)) * Pi
	variable numberOfBuildWaves = floor((pa.lowPassCutOff - pa.highPassCutOff) / pa.fIncrement)

	if(!IsFinite(phase) || !IsFinite(pa.duration) || !IsFinite(numberOfBuildWaves) || pa.highPassCutOff == 0)
		print "Could not create a new pink/brown noise Wave as the input values were non-finite or zero."
		return NaN
	endif

	Make/FREE/n=(pa.duration / MINIMUM_SAMPLING_INTERVAL, NumberOfBuildWaves) BuildWave
	SetScale/P x 0, MINIMUM_SAMPLING_INTERVAL, "ms", BuildWave
	variable frequency = pa.highPassCutOff
	variable i
	variable localAmplitude

	for(i = 0; i < numberOfBuildWaves; i += 1)
		phase = ((abs(enoise(2))) * Pi) // random phase generator
		if(PinkOrBrown == 0)
			localAmplitude = 1 / frequency
		else
			localAmplitude = 1 / (frequency ^ .5)
		endif

		// factoring out Pi * 1e-05 actually makes it a tiny bit slower
		MultiThread BuildWave[][i] = localAmplitude * sin( Pi * pa.frequency * 1e-05 * p + phase)
		Frequency += pa.fIncrement
	endfor

	MatrixOp/O/NTHR=0   SegmentWave = sumRows(BuildWave)
	SetScale/P x 0, MINIMUM_SAMPLING_INTERVAL, "ms", SegmentWave

	WaveStats/Q SegmentWave
	SegmentWave *= pa.amplitude / V_sdev
End
/// @}
