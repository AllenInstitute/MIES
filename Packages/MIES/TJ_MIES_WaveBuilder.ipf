#pragma rtGlobals=3		// Use modern global access method and strict Wave access.

Function WB_MakeStimSet()

	dfref dfr = GetWaveBuilderDataPath()
	Wave/SDFR=dfr WaveBuilderWave
	variable i
	Variable start = stopmstimer(-2)

	Wave/SDFR=dfr WP

	// duplicating starting parameter Waves so that they can be returned to start parameters at end of Wave making
	Duplicate/FREE WP, WP_orig

	ControlInfo setvar_WaveBuilder_baseName
	string setbasename = s_value[0,15]

	ControlInfo setvar_WaveBuilder_SetNumber
	variable setnumber = v_value

	ControlInfo SetVar_WaveBuilder_StepCount
	variable NoOfWavesInSet = v_value

	string OutputWaveName

	for(i=1; i <= NoOfWavesInSet; i+=1)
		WB_MakeWaveBuilderWave()
		WB_AddDelta()
		ControlInfo popup_WaveBuilder_OutputType
		string OutputWaveType = s_value

		OutputWaveName = num2str(i) + "_" + setbasename + "_" + OutputWaveType + "_" + num2str(setnumber)
		Duplicate/O WaveBuilderWave, dfr:$OutputWaveName
	endfor

	WP = WP_orig
	DEBUGPRINT("copying took (ms):", var=(stopmstimer(-2) - start) / 1000)
End

/// @brief Adds delta to appropriate parameter - relies on alternating sequence of parameter and delta's in parameter Waves
static Function WB_AddDelta()

	Wave/SDFR=GetWaveBuilderDataPath() WP
	variable i

	variable checked = GetCheckBoxState("WaveBuilder", "check_WaveBuilder_exp")

	for(i=0; i < 30; i += 2)
		WP[i][][0] = WP[i + 1][q][0] + WP[i][q][0]
		WP[i][][1] = WP[i + 1][q][1] + WP[i][q][1]
		WP[i][][2] = WP[i + 1][q][2] + WP[i][q][2]
		WP[i][][3] = WP[i + 1][q][3] + WP[i][q][3]
		WP[i][][4] = WP[i + 1][q][4] + WP[i][q][4]
		WP[i][][5] = WP[i + 1][q][5] + WP[i][q][5]
		WP[i][][6] = WP[i + 1][q][6] + WP[i][q][6]
		WP[i][][7] = WP[i + 1][q][7] + WP[i][q][7]

		if(checked)
			WP[i + 1][][0] += WP[i + 1][q][0]
			WP[i + 1][][1] += WP[i + 1][q][1]
			WP[i + 1][][2] += WP[i + 1][q][2]
			WP[i + 1][][3] += WP[i + 1][q][3]
			WP[i + 1][][4] += WP[i + 1][q][4]
			WP[i + 1][][5] += WP[i + 1][q][5]
			WP[i + 1][][6] += WP[i + 1][q][6]
			WP[i + 1][][7] += WP[i + 1][q][7]
		endif
	endfor
End

static Function WB_MakeWaveBuilderWave()
	variable Amplitude, DeltaAmp, Duration, DeltaDur, OffSet, DeltaOffset, Frequency, DeltaFreq, PulseDuration, DeltaPulsedur, TauRise,TauDecay1,TauDecay2,TauDecay2Weight
	variable DeltaTauRise,DeltaTauDecay1,DeltaTauDecay2,DeltaTauDecay2Weight, CustomOffset, DeltaCustomOffset, LowPassCutOff, DeltaLowPassCutOff, HighPassCutOff, DeltaHighPassCutOff, EndFrequency, DeltaEndFrequency
	variable HighPassFiltCoefCount, DeltaHighPassFiltCoefCount, LowPassFiltCoefCount, DeltaLowPassFiltCoefCount, FIncrement

	dfref dfr = GetWaveBuilderDataPath()
	Wave/SDFR=dfr SegWvType
	Make/O/N=0 dfr:WaveBuilderWave/Wave=WaveBuilderWave = 0
	Make/O/N=0 dfr:SegmentWave/Wave=SegmentWave = 0

	string customWaveName
	variable NumberOfSegments, i, type
	ControlInfo SetVar_WaveBuilder_NoOfSegments
	NumberOfSegments = v_value

	for(i=0; i < NumberOfSegments; i+=1)
		//Load in parameters
		Wave/SDFR=dfr WP
		Wave/T/SDFR=dfr WPT
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
		//row spacing changes here to leave room for addition of delta parameters in the future
		//also allows for universal delta parameter addition
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

		if(Duration < 0)
			Print "User input has generated a negative epoch duration. Please adjust input. Duration for epoch has been reset to 1 ms."
			Duration = 1
		endif

		//Make correct Wave segment with above parameters
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
		Concatenate/NP=0 {SegmentWave}, WaveBuilderWave
	endfor

	SetScale /P x 0, 0.005, "ms", WaveBuilderWave
	// although we are not creating these globals anymore, we still try to kill them
	KillVariables/Z ParameterHolder
	KillStrings/Z StringHolder
	KillWaves/F/Z SegmentWave
End

static Function/Wave WB_GetSegmentWave(duration)
	variable duration

	DFREF dfr = GetWaveBuilderDataPath()
	variable numPoints = duration / 0.005
	Wave/Z/SDFR=dfr SegmentWave

	// optimization: recreate the wave only if necessary or just resize it
	if(!WaveExists(SegmentWave))
		Make/N=(numPoints) dfr:SegmentWave/Wave=SegmentWave
	elseif(numPoints != DimSize(SegmentWave, ROWS))
		Redimension/N=(numPoints) SegmentWave
	endif

	SegmentWave = 0
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

	pinkCheck  = GetCheckBoxState("Wavebuilder", "check_Noise_Pink")
	brownCheck = GetCheckBoxState("Wavebuilder", "check_Noise_Brown")

	if(!brownCheck && !pinkCheck)
		SegmentWave = gnoise(Amplitude) // MultiThread didn't impact processing time for gnoise
		ASSERT(duration > 0, "negative duration")

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

	if(!GetCheckBoxState("Wavebuilder","check_Sin_Chirp"))
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
	EndPoint = NumberOfPulses

	if (!GetCheckBoxState("Wavebuilder", "check_SPT_Poisson"))
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
	variable scale = 1.2
	variable baseline, peak
	variable i

	Wave SegmentWave = WB_GetSegmentWave(duration)

	TauRise = 1 / TauRise
	TauRise *= 0.005
	TauDecay1 = 1 / TauDecay1
	TauDecay1 *= 0.005
	TauDecay2 = 1 / TauDecay2
	TauDecay2 *= 0.005

	MultiThread SegmentWave[] = ((1 - exp( - TauRise * p))) * amplitude
	MultiThread SegmentWave[] += (exp( - TauDecay1 * (p)) * (amplitude * (1 - TauDecay2Weight)))
	MultiThread SegmentWave[] += (exp( - TauDecay2 * (p)) * ((amplitude * (TauDecay2Weight))))

	baseline = WaveMin(SegmentWave)
	peak = WaveMax(SegmentWave)
	SegmentWave *= Amplitude/(Peak-Baseline)

	baseline = WaveMin(SegmentWave)
	SegmentWave -= baseline
	SegmentWave += OffSet
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
