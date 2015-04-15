#pragma rtGlobals=3		// Use modern global access method and strict Wave access.

static Constant MAX_SWEEP_DURATION_IN_MS = 1.8e6 // 30 minutes

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
						case 2:
							factor = amplitudeFactor
							break
						case 4:
							factor = offsetFactor
							break
						default:
							factor = durationFactor
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
End

static Function WB_MakeWaveBuilderWave(WP, stepCount, numEpochs, wvName)
	Wave WP
	variable stepCount
	variable numEpochs
	string wvName

	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight
	variable DeltaTauRise,DeltaTauDecay1,DeltaTauDecay2,DeltaTauDecay2Weight, CustomOffset, DeltaCustomOffset, LowPassCutOff, DeltaLowPassCutOff, HighPassCutOff, DeltaHighPassCutOff, EndFrequency, DeltaEndFrequency
	variable HighPassFiltCoefCount, DeltaHighPassFiltCoefCount, LowPassFiltCoefCount, DeltaLowPassFiltCoefCount, FIncrement

	dfref dfr = GetWaveBuilderDataPath()
	Wave/SDFR=dfr SegWvType
	Make/O/N=0 dfr:$wvName/Wave=WaveBuilderWave

	string customWaveName, debugMsg
	variable i, type, accumulatedDuration

	WAVE/T WPT = GetWaveBuilderWaveTextParam()

	for(i=0; i < numEpochs; i+=1)
		type = SegWvType[i]

		Duration                   = WP[0][i][type]
		DeltaDur                   = WP[1][i][type]
		Amplitude                  = WP[2][i][type]
		DeltaAmp                   = WP[3][i][type]
		Offset                     = WP[4][i][type]
		DeltaOffset                = WP[5][i][type]
		Frequency                  = WP[6][i][type]
		DeltaFreq                  = WP[7][i][type]
		PulseDuration              = WP[8][i][type]
		DeltaPulsedur              = WP[9][i][type]
		TauRise                    = WP[10][i][type]
		DeltaTauRise               = WP[11][i][type]
		TauDecay1                  = WP[12][i][type]
		DeltaTauDecay1             = WP[13][i][type]
		TauDecay2                  = WP[14][i][type]
		DeltaTauDecay2             = WP[15][i][type]
		TauDecay2Weight            = WP[16][i][type]
		DeltaTauDecay2Weight       = WP[17][i][type]
		CustomOffset               = WP[18][i][type]
		DeltaCustomOffset          = WP[19][i][type]
		LowPassCutOff              = WP[20][i][type]
		DeltaLowPassCutOff         = WP[21][i][type]
		HighPassCutOff             = WP[22][i][type]
		DeltaHighPassCutOff        = WP[23][i][type]
		EndFrequency               = WP[24][i][type]
		DeltaEndFrequency          = WP[25][i][type]
		HighPassFiltCoefCount      = WP[26][i][type]
		DeltaHighPassFiltCoefCount = WP[27][i][type]
		LowPassFiltCoefCount       = WP[28][i][type]
		DeltaLowPassFiltCoefCount  = WP[29][i][type]
		FIncrement                 = WP[30][i][type]

		sprintf debugMsg, "step count: %d, epoch: %d, duration: %g (delta %g), amplitude %d (delta %g)\r", stepCount, i, duration, DeltaDur, amplitude, DeltaAmp
		DEBUGPRINT("params", str=debugMsg)

		if(duration < 0 || !IsFinite(duration))
			Print "User input has generated a negative/non-finite epoch duration. Please adjust input. Duration for epoch has been reset to 1 ms."
			duration = 1
		endif

		switch(type)
			case 0:
				WB_SquareSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"          , var=i)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"           , str="Square pulse")
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude"      , var=Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta amplitude", var=DeltaAmp)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration"       , var=Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta duration" , var=DeltaDur)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"         , var=Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta offset"   , var=DeltaOffset, appendCR=1)
				break
			case 1:
				WB_RampSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"          , var=i)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"           , str="Ramp")
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Amplitude"      , var=Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta amplitude", var=DeltaAmp)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Duration"       , var=Duration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta duration" , var=DeltaDur)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"         , var=Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta offset"   , var=DeltaOffset, appendCR=1)
				break
			case 2:
				WB_NoiseSegment(Amplitude, Duration, OffSet, LowPassCutOff, LowPassFiltCoefCount, HighPassCutOff, HighPassFiltCoefCount, FIncrement)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"                  , var=i)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"                   , str="G-noise")
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "SD"                     , var=Amplitude)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "SD delta"               , var=DeltaAmp)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Low pass cut off"       , var=LowPassCutOff)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Low pass cut off delta" , var=DeltaLowPassCutOff)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "High pass cut off"      , var=HighPassCutOff)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "High pass cut off delta", var=DeltaHighPassCutOff)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"                 , var=Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta offset"           , var=DeltaOffset, appendCR=1)
				break
			case 3:
				WB_SinSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight, EndFrequency, DeltaEndFrequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"              , var=i)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"               , str="Sin Wave")
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency"          , var=Frequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency delta"    , var=DeltaFreq)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "End frequency"      , var=EndFrequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "End frequency delta", var=DeltaEndFrequency, appendCR=1)
				break
			case 4:
				WB_SawToothSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"          , var=i)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"           , str="Saw tooth")
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency"      , var=Frequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency delta", var=DeltaFreq)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"         , var=Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta offset"   , var=DeltaOffset, appendCR=1)
				break
			case 5:
				WB_SquarePulseTrainSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"               , var=i)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"                , str="SPT")
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency"           , var=Frequency)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Frequency delta"     , var=DeltaFreq)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Pulse duration"      , var=PulseDuration)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Pulse duration delta", var=DeltaPulsedur)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"              , var=Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta offset"        , var=DeltaOffset, appendCR=1)
				break
			case 6:
				WB_PSCSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"             , var=i)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"              , str="PSC")
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau rise"          , var=TauRise)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau decay 1"       , var=TauDecay1)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau decay 2"       , var=TauDecay2)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Tau decay 2 weight", var=TauDecay2Weight)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"            , var=Offset)
				AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta offset"      , var=DeltaOffset, appendCR=1)
				break
			case 7:
				customWaveName = WPT[0][i]

				Wave/Z/SDFR=WBP_GetFolderPath() customWave = $customWaveName

				if(WaveExists(customWave))
					WB_CustomWaveSegment(CustomOffset, customWave)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Epoch"       , var=i)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Type"        , str="Custom Wave")
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Name"        , str=customWaveName)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Offset"      , var=Offset)
					AddEntryIntoWaveNoteAsList(WaveBuilderWave, "Delta offset", var=DeltaOffset, appendCR=1)
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
			epochID[i][%timeEnd]   = accumulatedDuration + duration

			accumulatedDuration += duration
		endif

		WAVE/SDFR=dfr segmentWave
		Concatenate/NP=0 {segmentWave}, WaveBuilderWave
	endfor

	AddEntryIntoWaveNoteAsList(WaveBuilderWave, "ITI", var=SegWvType[99], appendCR=1)

	SetScale /P x 0, 0.005, "ms", WaveBuilderWave
	// although we are not creating these globals anymore, we still try to kill them
	KillVariables/Z ParameterHolder
	KillStrings/Z StringHolder
End

/// @brief Returns the segment wave which stores the stimulus set of one segment/epoch
/// @param duration time of the stimulus in ms
static Function/Wave WB_GetSegmentWave(duration)
	variable duration

	DFREF dfr = GetWaveBuilderDataPath()
	variable numPoints = duration / 0.005
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

	SetScale/P x 0,0.005, "ms", SegmentWave

	return SegmentWave
End

/// @name Functions that build wave types
/// @{
static Function WB_SquareSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight

	Wave SegmentWave = WB_GetSegmentWave(duration)
	SegmentWave = Amplitude
End

static Function WB_RampSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight

	variable AmplitudeIncrement = Amplitude/(Duration/0.005)

	Wave SegmentWave = WB_GetSegmentWave(duration)
	MultiThread SegmentWave = AmplitudeIncrement * p
	SegmentWave += Offset
End

static Function WB_NoiseSegment(Amplitude, Duration, OffSet, LowPassCutOff, LowPassFiltCoefCount HighPassCutOff,HighPassFiltCoefCount, FIncrement)
	variable Amplitude, Duration, OffSet, LowPassCutOff, LowPassFiltCoefCount, HighPassCutOff, HighPassFiltCoefCount, FIncrement

	variable brownCheck, pinkCheck, PinkOrBrown

	Wave SegmentWave = WB_GetSegmentWave(duration)

	pinkCheck  = GetCheckBoxState("Wavebuilder", "check_Noise_Pink_P41")
	brownCheck = GetCheckBoxState("Wavebuilder", "Check_Noise_Brown_P42")

	if(!brownCheck && !pinkCheck)
		SegmentWave = gnoise(Amplitude) // MultiThread didn't impact processing time for gnoise
		if(duration <= 0)
			print "WB_NoiseSegment: Can not proceed with non-positive duration"
			return NaN
		endif

		if(LowPassCutOff <= 100000 && LowPassCutOff != 0)
			FilterFIR /DIM = 0 /LO = {(LowPassCutOff / 200000), (LowPassCutOff / 200000), LowPassFiltCoefCount} SegmentWave
		endif

		if(HighPassCutOff > 0 && HighPassCutOff < 100000)
			FilterFIR /DIM = 0 /Hi = {(HighPassCutOff/200000), (HighPassCutOff/200000), HighPassFiltCoefCount} SegmentWave
		endif
	elseif(pinkCheck)
		WB_PinkAndBrownNoise(Amplitude, Duration, LowPassCutOff, HighPassCutOff, Fincrement, 0)
	elseif(brownCheck)
		WB_PinkAndBrownNoise(Amplitude, Duration, LowPassCutOff, HighPassCutOff, Fincrement, 1)
	endif

	SegmentWave += offset
End

static Function WB_SinSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight, EndFrequency, EndFrequencyDelta)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight, EndFrequency, EndFrequencyDelta
	variable k0, k1, k2, k3
	string cmd

	Wave SegmentWave = WB_GetSegmentWave(duration)

	if(!GetCheckBoxState("Wavebuilder","check_Sin_Chirp_P43"))
		MultiThread SegmentWave = Amplitude * sin(2 * Pi * (Frequency * 1000) * (5 / 1000000000) * p)
		SegmentWave += Offset
	else
		 k0 = ln(frequency / 1000)
		 k1 = (ln(endFrequency / 1000) - k0) / (duration)
		 k2 = 2 * pi * e^k0 / k1
		 k3 = mod(k2, 2 * pi)		// LH040117: start on rising edge of sin and don't try to round.
		 MultiThread SegmentWave = Amplitude * sin(k2 * e^(k1 * x) - k3)
		 SegmentWave += Offset
	endif
End

static Function WB_SawToothSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight

	Wave SegmentWave = WB_GetSegmentWave(duration)

	SegmentWave = 1 * Amplitude * sawtooth(2 * Pi * (Frequency * 1000) * (5 / 1000000000) * p)
	SegmentWave += Offset
End

static Function WB_SquarePulseTrainSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight

	Variable i = 1
	Variable PulseStartTime = 0
	Variable EndPoint
	Variable SegmentDuration
	Variable NumberOfPulses = Frequency * (Duration / 1000)
	Variable TotalPulseTime = PulseDuration * NumberOfPulses
	Variable TotalBaselineTime = Duration - TotalPulseTime
	Variable NumberOfInterPulseIntervals = NumberOfPulses - 1
	Variable InterPulseInterval = TotalBaselineTime/NumberOfInterPulseIntervals
	Variable PoissonIntPulseInt

	Wave SegmentWave = WB_GetSegmentWave(duration)
	SegmentWave = 0

	EndPoint = NumberOfPulses

	if (!GetCheckBoxState("Wavebuilder", "check_SPT_Poisson_P44"))
		do
			SegmentWave[(PulseStartTime / 0.005), ((PulseStartTime / 0.005) + (PulseDuration / 0.005))] = Amplitude
			if(i + 1 == EndPoint)
				PulseStartTime += ((InterPulseInterval + PulseDuration))
			else
				PulseStartTime += ((InterPulseInterval + PulseDuration))
			endif
		i += 1
		while (i < Endpoint)
	else
		do
			PoissonIntPulseInt = (-ln(abs(enoise(1))) / Frequency) * 1000
			PulseStartTime += (PoissonIntPulseInt)
			if(((PulseStartTime + PulseDuration) / 0.005) < numpnts(segmentWave))
				SegmentWave[(PulseStartTime / 0.005), ((PulseStartTime / 0.005) + (PulseDuration / 0.005))] = Amplitude
			endif
		while (((PulseStartTime + PulseDuration) / 0.005) < numpnts(segmentWave))
	endif

	SegmentWave += Offset

End

static Function WB_PSCSegment(Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight)
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight

	variable first, last
	variable baseline, peak

	Wave SegmentWave = WB_GetSegmentWave(duration)

	TauRise = 1 / TauRise
	TauRise *= 0.005
	TauDecay1 = 1 / TauDecay1
	TauDecay1 *= 0.005
	TauDecay2 = 1 / TauDecay2
	TauDecay2 *= 0.005

	MultiThread SegmentWave[] = amplitude * ((1 - exp(-TauRise * p)) + exp(-TauDecay1 * p) * (1 - TauDecay2Weight) + exp(-TauDecay2 * p) * TauDecay2Weight)

	baseline = WaveMin(SegmentWave)
	peak = WaveMax(SegmentWave)
	SegmentWave *= abs(amplitude)/(peak - baseline)

	baseline = WaveMin(SegmentWave)
	SegmentWave -= baseline
	SegmentWave += offset
End

static Function WB_CustomWaveSegment(CustomOffset, wv)
	variable CustomOffset
	Wave wv

	DFREF dfr = GetWaveBuilderDataPath()

	Duplicate/O wv, dfr:SegmentWave/Wave=SegmentWave
	SegmentWave += CustomOffSet
End

/// PinkOrBrown Pink = 0, Brown = 1
static Function WB_PinkAndBrownNoise(Amplitude, Duration, LowPassCutOff, HighPassCutOff, FrequencyIncrement, PinkOrBrown)
		variable Amplitude, Duration, LowPassCutOff, HighPassCutOff, frequencyIncrement, PinkOrBrown

		variable phase = abs(enoise(2)) * Pi
		variable numberOfBuildWaves = floor((LowPassCutOff - HighPassCutOff) / FrequencyIncrement)

		if(!IsFinite(phase) || !IsFinite(Duration) || !IsFinite(numberOfBuildWaves) || HighPassCutOff == 0)
			print "Could not create a new pink/brown noise Wave as the input values were non-finite or zero."
			return NaN
		endif

		Make/FREE/n=(Duration / 0.005, NumberOfBuildWaves) BuildWave
		SetScale/P x 0,0.005,"ms", BuildWave
		variable Frequency = HighPassCutOff
		variable i = 0
		variable localAmplitude

		for(i = 0; i < numberOfBuildWaves; i += 1)
			phase = ((abs(enoise(2))) * Pi) // random phase generator
			if(PinkOrBrown == 0)
				localAmplitude = 1 / Frequency
			else
				localAmplitude = 1 / (Frequency ^ .5)
			endif

			// factoring out Pi * 1e-05 actually makes it a tiny bit slower
			MultiThread BuildWave[][i] = localAmplitude * sin( Pi * Frequency * 1e-05 * p + phase)
			Frequency += FrequencyIncrement
		endfor

		MatrixOp/O/NTHR=0   SegmentWave = sumRows(BuildWave)
		SetScale/P x 0, 0.005,"ms", SegmentWave

		WaveStats/Q SegmentWave
		SegmentWave *= Amplitude / V_sdev
End
/// @}
