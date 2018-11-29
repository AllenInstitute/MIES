#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SCOPE
#endif

/// @file MIES_Oscilloscope.ipf
/// @brief __SCOPE__ Scope window handling for data acquisition and testpulse results

static Constant SCOPE_TIMEAXIS_RESISTANCE_RANGE = 120
static Constant SCOPE_GREEN                     = 26122
static Constant SCOPE_BLUE                      = 39168
static StrConstant TAG_FORMAT_STR               = "\\[1\\K(%d, %d, %d)\\{\"%%s\", FloatWithMinSigDigits(TagVal(2), numMinSignDigits = 2)}\\]1\K(0, 0, 0)"
static Constant PRESSURE_SPECTRUM_PERCENT       = 0.05
static Constant ADDITIONAL_SPACE_AD_GRAPH       = 0.10 ///< percent of total axis range

Function/S SCOPE_GetGraph(panelTitle)
	string panelTitle

	return SCOPE_GetPanel(panelTitle) + "#oscilloscope"
End

Function/S SCOPE_GetPanel(panelTitle)
	string panelTitle

	return panelTitle + "#Scope"
End

Function SCOPE_OpenScopeWindow(panelTitle)
	string panelTitle

	string win, graph

	win = SCOPE_GetPanel(panelTitle)

	if(windowExists(win))
		return NaN
	endif

	graph = SCOPE_GetGraph(panelTitle)

	NewPanel/EXT=0/W=(0,0,460,880)/HOST=$panelTitle/N=Scope/K=2
	Display/W=(0,10,358,776)/HOST=$win/N=oscilloscope/FG=(FL,FT,FR,FB)
	ModifyPanel/W=$win fixedSize=0
	ModifyGraph/W=$graph gfSize=14
	ModifyGraph/W=$graph wbRGB=(60928,60928,60928),gbRGB=(60928,60928,60928)
	SetActiveSubWindow $paneltitle
End

Function SCOPE_KillScopeWindowIfRequest(panelTitle)
	string panelTitle

	string win = SCOPE_GetPanel(panelTitle)

	if(!GetCheckBoxState(panelTitle, "check_Settings_ShowScopeWindow") && windowExists(win))
		KillWindow $win
	endif
End

Function SCOPE_UpdateGraph(panelTitle)
	string panelTitle

	variable latest, count, i, numADCs, minVal, maxVal, range, numDACs, statsMin, statsMax
	variable axisMin, axisMax, spacing, adc, headstage
	variable relTimeAxisMin, relTimeAxisMax, showSteadyStateResistance, showPeakResistance
	variable showPowerSpectrum
	string graph, rightAxis, leftAxis, info

	SCOPE_GetCheckBoxesForAddons(panelTitle, showSteadyStateResistance, showPeakResistance, showPowerSpectrum)
	graph = SCOPE_GetGraph(panelTitle)
	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
	WAVE OscilloscopeData  = GetOscilloscopeWave(panelTitle)
	WAVE ADCs = GetADCListFromConfig(ITCChanConfigWave)
	WAVE DACs = GetDACListFromConfig(ITCChanConfigWave)
	numADCs = DimSize(ADCs, ROWS)
	numDACs = DimSize(DACs, ROWS)

	GetAxis/W=$graph/Q top
	if(!V_flag) // axis exists in graph
		Wave TPStorage = GetTPStorage(panelTitle)
		count  = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)
		latest = DimOffset(TPStorage, ROWS) + count * DimDelta(TPStorage, ROWS)
		relTimeAxisMin = latest - 0.5 * SCOPE_TIMEAXIS_RESISTANCE_RANGE
		relTimeAxisMax = latest + 0.5 * SCOPE_TIMEAXIS_RESISTANCE_RANGE

		if(latest >= V_max)
			SetAxis/W=$graph top, relTimeAxisMin, relTimeAxisMax
		endif
	endif

	if(showPowerSpectrum)
		return NaN
	endif

	// scale the left AD axes
	for(i = 0; i < numADCs; i += 1)

		leftAxis = "AD" + num2str(ADCs[i])

		WaveStats/M=1/Q/RMD=[][numDACs + i] OscilloscopeData

		statsMin = V_min
		statsMax = V_max

		// data is propably just zero, skip the axis
		if(statsMin == statsMax || (IsNaN(statsMin) && IsNaN(statsMax)))
			continue
		endif

		GetAxis/Q/W=$graph $leftAxis
		ASSERT(!V_Flag, "Expected axis does not exist")

		axisMin = V_min
		axisMax = V_max

		if(axisMax == axisMin || (axisMin == -1 && axisMax == 1))
			spacing = (statsMax - statsMin) * ADDITIONAL_SPACE_AD_GRAPH
		else
			spacing = (axisMax - axisMin) * ADDITIONAL_SPACE_AD_GRAPH
		endif

		if(axisMin < statsMin && abs(statsMin - axisMin) < spacing)
			if(axisMax > statsMax && abs(statsMax - axisMax) < spacing)
				continue
			endif
		endif

		SetAxis/W=$graph $leftAxis statsMin - spacing / 2.0, statsMax + spacing / 2.0
	endfor
End

static Function SCOPE_GetCheckBoxesForAddons(panelTitle, showSteadyStateResistance, showPeakResistance, showPowerSpectrum)
	string panelTitle
	variable &showSteadyStateResistance, &showPeakResistance, &showPowerSpectrum

	showPeakResistance        = DAG_GetNumericalValue(panelTitle, "check_settings_TP_show_peak")
	showSteadyStateResistance = DAG_GetNumericalValue(panelTitle, "check_settings_TP_show_steady")
	showPowerSpectrum         = DAG_GetNumericalValue(panelTitle, "check_settings_show_power")
End

Function SCOPE_CreateGraph(panelTitle, dataAcqOrTP)
	string panelTitle
	variable dataAcqOrTP

	string graph, tagName, color, style
	variable i, adc, numActiveDACs, numADChannels, oneTimeInitDone
	variable showSteadyStateResistance, showPeakResistance, Red, Green, Blue
	string leftAxis, rightAxis, tagAxis, str, powerSpectrumTrace, oscilloscopeTrace
	string tagPeakTrace, tagSteadyStateTrace
	string steadyStateTrace, peakTrace, adcStr, anchor
	variable YaxisLow, YaxisHigh, YaxisSpacing, Yoffset, xPos, yPos
	variable testPulseLength, cutOff, sampInt
	variable headStage, activeHeadStage, showPowerSpectrum
	STRUCT RGBColor peakColor
	STRUCT RGBColor steadyColor

	SCOPE_OpenScopeWindow(panelTitle)
	graph = SCOPE_GetGraph(panelTitle)

	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
	WAVE SSResistance      = GetSSResistanceWave(panelTitle)
	WAVE InstResistance    = GetInstResistanceWave(panelTitle)
	WAVE TPStorage         = GetTPStorage(panelTitle)
	WAVE OscilloscopeData  = GetOscilloscopeWave(panelTitle)
	WAVE PressureData		= P_GetPressureDataWaveRef(panelTitle)

	WAVE ADCs = GetADCListFromConfig(ITCChanConfigWave)
	numADChannels = DimSize(ADCs, ROWS)
	numActiveDACs = DimSize(GetDACListFromConfig(ITCChanConfigWave), ROWS)
	graph = SCOPE_GetGraph(panelTitle)
	Yoffset = 40 / numADChannels
	YaxisSpacing = 1 / numADChannels
	YaxisHigh = 1
	YaxisLow = YaxisHigh - YaxisSpacing + 0.025
	peakColor.green = SCOPE_GREEN
	steadyColor.blue = SCOPE_BLUE
	activeHeadStage = GetDA_EphysGuiStateNum(panelTitle)[0][%slider_DataAcq_ActiveHeadstage]

	RemoveTracesFromGraph(graph)
	RemoveAnnotationsFromGraph(graph)

	SCOPE_GetCheckBoxesForAddons(panelTitle, showSteadyStateResistance, showPeakResistance, showPowerSpectrum)

	for(i = 0; i < numADChannels; i += 1)
		adc    = ADCs[i]
		adcStr = num2str(adc)
		leftAxis = "AD" + adcStr
		
		headStage = AFH_GetHeadstageFromADC(panelTitle, adc)

		if(dataAcqOrTP != TEST_PULSE_MODE || !showPowerSpectrum)
			oscilloscopeTrace = "osci" + adcStr
			AppendToGraph/W=$graph/L=$leftAxis OscilloscopeData[][numActiveDACs + i]/TN=$oscilloscopeTrace

#if (IgorVersion() >= 8.00)
			// use fast line drawing
			ModifyGraph/W=$graph live($oscilloscopeTrace)=(2^1)
#endif

			ModifyGraph/W=$graph axisEnab($leftAxis) = {YaxisLow, YaxisHigh}, freepos($leftAxis) = {0, kwFraction}
			ModifyGraph/W=$graph lblPosMode($leftAxis)=4, lblPos($leftAxis) = 50
		endif

		// handles plotting of peak and steady state resistance curves in the oscilloscope window with the TP
		// add the also the trace for the current resistance values from the test pulse
		if(dataAcqOrTP == TEST_PULSE_MODE)

			if(showPowerSpectrum)
				powerSpectrumTrace = "powerSpectra" + adcStr
				WAVE powerSpectrum = GetTPPowerSpectrumWave(panelTitle)
				AppendToGraph/W=$graph/L=$leftAxis powerSpectrum[][numActiveDACs + i]/TN=$powerSpectrumTrace
				ModifyGraph/W=$graph lstyle=0, mode($powerSpectrumTrace)=0
				ModifyGraph/W=$graph rgb($powerSpectrumTrace)=(65535,0,0,13107)
				ModifyGraph/W=$graph freepos($leftAxis) = {0, kwFraction}, axisEnab($leftAxis)= {YaxisLow, YaxisHigh}
				ModifyGraph/W=$graph lblPosMode($leftAxis)=4, lblPos($leftAxis) = 50, log($leftAxis)=1
				SetAxis/W=$graph/A=2/N=2 $leftAxis
#if (IgorVersion() >= 8.00)
				// use fast line drawing
				ModifyGraph/W=$graph live($powerSpectrumTrace)=(2^1)
#endif
			endif

			rightAxis = "resistance" + adcStr

			if(showPeakResistance)
				peakTrace = "PeakResistance" + adcStr
				AppendToGraph/W=$graph/R=$rightAxis/T=top TPStorage[][headstage][%PeakResistance]/TN=$peakTrace vs TPStorage[][headstage][%DeltaTimeInSeconds]
				SetAxis/W=$graph/A=2/N=1 $rightAxis
				ModifyGraph/W=$graph fSize($rightAxis)=10,grid($rightAxis)=1,gridStyle($rightAxis)=4,gridRGB($rightAxis)=(0,0,0,3277)
#if (IgorVersion() >= 8.00)
				ModifyGraph/W=$graph live($peakTrace)=(2^1)
#endif
				ModifyGraph/W=$graph lstyle($peakTrace)=1, rgb($peakTrace)=(peakColor.red, peakColor.green, peakColor.blue)
				ModifyGraph/W=$graph mode($peakTrace)=2
			endif

			if(showSteadyStateResistance)
				steadyStateTrace = "SteadyStateResistance" + adcStr
				AppendToGraph/W=$graph/R=$rightAxis/T=top TPStorage[][headstage][%SteadyStateResistance]/TN=$steadyStateTrace vs TPStorage[][headstage][%DeltaTimeInSeconds]
				SetAxis/W=$graph/A=2/N=1 $rightAxis
				ModifyGraph/W=$graph fSize($rightAxis)=10,grid($rightAxis)=1,gridStyle($rightAxis)=4,gridRGB($rightAxis)=(0,0,0,3277)
				ASSERT(isFinite(headStage), "invalid headStage")
				if(isFinite(PressureData[headStage][%DAC_DevID])) // Check if pressure is enabled
					ModifyGraph/W=$graph marker($steadyStateTrace)=19, mode($steadyStateTrace)=4
					ModifyGraph/W=$graph msize($steadyStateTrace)=1, gaps($steadyStateTrace)=0
					ModifyGraph/W=$graph useMrkStrokeRGB($steadyStateTrace)=1, mrkStrokeRGB($steadyStateTrace)=(65535,65535,65535)
					ModifyGraph/W=$graph zColor($steadyStateTrace)={TPStorage[*][headstage][%Pressure],   \
											(PRESSURE_SPECTRUM_PERCENT * MIN_REGULATOR_PRESSURE), \
											(PRESSURE_SPECTRUM_PERCENT * MAX_REGULATOR_PRESSURE), BlueBlackRed,0}
					ModifyGraph/W=$graph zmrkSize($steadyStateTrace)={TPStorage[*][headstage][%PressureChange],0,1,1,4}
				else
					ModifyGraph/W=$graph lstyle($steadyStateTrace)=1, rgb($steadyStateTrace)=(steadyColor.red, steadyColor.green, steadyColor.blue)
				endif
#if (IgorVersion() >= 8.00)
				ModifyGraph/W=$graph live($steadyStateTrace)=(2^1)
#endif
				ModifyGraph/W=$graph mode($steadyStateTrace)=2

			endif

			if(showPeakResistance ||showSteadyStateResistance)
				ModifyGraph/W=$graph axisEnab($rightAxis) = {YaxisLow, YaxisLow + (YaxisHigh - YaxisLow) * 0.3}, freePos($rightAxis)={0, kwFraction}
				ModifyGraph/W=$graph lblPosMode($rightAxis) = 4, lblPos($rightAxis) = 60, lblRot($rightAxis) = 180
				ModifyGraph/W=$graph nticks($rightAxis) = 2, tickUnit(top)=1
				Label/W=$graph $rightAxis "(MΩ)"

				if(!oneTimeInitDone)
					sprintf str, "\\[1\\K(%d, %d, %d)R\\Bss\\M(MΩ)\\]1\\K(%d, %d,%d)\r\\[1\\K(0, 26122, 0)R\\Bpeak\\M(MΩ)\\]1\\K(0, 0, 0)", steadyColor.red, steadyColor.green, steadyColor.blue, peakColor.red, peakColor.green, peakColor.blue
					TextBox/W=$graph/F=0/B=1/X=0.62/Y=0.36/E=2  str

					Label/W=$graph top "Relative time (s)"
					SetAxis/W=$graph/A=2 $rightAxis
					SetAxis/W=$graph top, 0, SCOPE_TIMEAXIS_RESISTANCE_RANGE
					oneTimeInitDone = 1
				endif
			endif

			tagAxis = rightAxis + "_tags"

			tagSteadyStateTrace = "SSR" + adcStr
			AppendToGraph/W=$graph/R=$tagAxis SSResistance[][i]/TN=$tagSteadyStateTrace
			ModifyGraph/W=$graph mode($tagSteadyStateTrace) = 2, lsize($tagSteadyStateTrace) = 0

			if(showPeakResistance || showSteadyStateResistance)
				xPos = 40
				yPos = 2
				anchor = "RB"
			else
				XPos = 0
				yPos = -yOffset
				anchor = "MC"
			endif

			tagName = "SSR" + adcStr
			sprintf str, TAG_FORMAT_STR, steadyColor.red, steadyColor.green, steadyColor.blue
			Tag/W=$graph/C/N=$tagName/F=0/B=1/A=$anchor/X=(xPos)/Y=(yPos)/L=0/I=1 $tagSteadyStateTrace, 0, str

			tagPeakTrace = "InstR" + adcStr
			AppendToGraph/W=$graph/R=$tagAxis InstResistance[][i]/TN=$tagPeakTrace
			ModifyGraph/W=$graph mode($tagPeakTrace) = 2, lsize($tagPeakTrace) = 0

			if(showPeakResistance || showSteadyStateResistance)
				xPos = 90
				yPos = 0
				anchor = "RB"
			else
				xPos = -15
				yPos = -yOffset
				anchor = "LT"
			endif

			tagName = "InstR" + adcStr
			sprintf str, TAG_FORMAT_STR, peakColor.red, peakColor.green, peakColor.blue
			Tag/W=$graph/C/N=$tagName/F=0/B=1/A=$anchor/X=(xPos)/Y=(yPos)/L=0/I=1 $tagPeakTrace, 0, str

			ModifyGraph/W=$graph noLabel($tagAxis) = 2, axThick($tagAxis) = 0, width = 25
			ModifyGraph/W=$graph axisEnab($tagAxis) = {YaxisLow, YaxisHigh}, freePos($tagAxis)={1, kwFraction}

			SetAxis/W=$graph/A=2/N=2/E=2 $tagAxis -20000000, 20000000
		endif

		YaxisHigh -= YaxisSpacing
		YaxisLow -= YaxisSpacing
	endfor

	SCOPE_SetADAxisLabel(panelTitle,activeHeadStage)

	if(dataAcqOrTP == TEST_PULSE_MODE)
		if(showPowerSpectrum)
			Label/W=$graph bottom "Frequency (\\U)"
			SetAxis/W=$graph/A bottom
		else
			Label/W=$graph bottom "Time (\\U)"
			sampInt = DAP_GetSampInt(panelTitle, TEST_PULSE_MODE) / 1000
			testPulseLength = TP_GetTestPulseLengthInPoints(panelTitle, TEST_PULSE_MODE) * sampInt
			NVAR duration = $GetTestpulseDuration(panelTitle)
			NVAR baselineFrac = $GetTestpulseBaselineFraction(panelTitle)
			cutOff = max(0, baseLineFrac * testPulseLength - duration/2 * sampInt)
			SetAxis/W=$graph bottom cutOff, testPulseLength - cutOff
		endif
	else
		Label/W=$graph bottom "Time (\\U)"
		NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
		sampInt = DAP_GetSampInt(panelTitle, DATA_ACQUISITION_MODE) / 1000
		SetAxis/W=$graph bottom 0, stopCollectionPoint * sampInt
	endif
End

Function SCOPE_SetADAxisLabel(panelTitle,activeHeadStage)
	string panelTitle
	variable activeHeadStage

	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
	WAVE ADCs = GetADCListFromConfig(ITCChanConfigWave)
	variable adc, i, headStage, red, green, blue
	variable numADChannels = DimSize(ADCs, ROWS)
	string leftAxis, style, color, unit, labelStr
	string graph = SCOPE_GetGraph(panelTitle)

	if(!windowExists(graph))
		return NaN
	endif

	string axList = AxisList(graph)

	for(i = 0; i < numADChannels; i += 1)
		adc    = ADCs[i]
		leftAxis = "AD" + num2str(adc)

		if(WhichListItem(leftAxis, axList) == -1)
			continue
		endif

		headStage = AFH_GetHeadstageFromADC(panelTitle, adc)
		if(isFinite(headStage))
			labelStr = "HS" + num2str(headstage)
			GetTraceColor(headStage, red, green, blue)
		else
			labelStr = "AD" + num2str(adc)
			GetTraceColor(NUM_HEADSTAGES, red, green, blue)
		endif

		sprintf color, "\K(%d,%d,%d)" red, green, blue
		if(activeHeadStage == headStage)
			style = "\f05"
		else
			style = ""
		endif

		if(DAG_GetNumericalValue(panelTitle, "check_settings_show_power"))
			unit = "a. u."
		else
			unit = AFH_GetChannelUnit(ITCChanConfigWave, adc, ITC_XOP_CHANNEL_TYPE_ADC)
		endif
		Label/W=$Graph $leftAxis, style + color + labelStr + " (" + unit + ")"
	endfor
End

Function SCOPE_UpdatePowerSpectrum(panelTitle)
	String panelTitle

	if(GetDA_EphysGuiStateNum(panelTitle)[0][%check_settings_show_power])
		WAVE OscilloscopeData = GetOscilloscopeWave(panelTitle)
		WAVE powerSpectrum = GetTPPowerSpectrumWave(panelTitle)
		// FFT knows how to transform units without prefix so transform them it temporarly
		SetScale/P x, DimOffset(OscilloscopeData, ROWS) / 1000, DimDelta(OscilloscopeData, ROWS) / 1000, "s", OscilloscopeData
		FFT/OUT=4/DEST=powerSpectrum/COLS/PAD={2^ceil(log(DimSize(OscilloscopeData, ROWS)) / log(2))} OscilloscopeData
		SetScale/P x, DimOffset(OscilloscopeData, ROWS) * 1000, DimDelta(OscilloscopeData, ROWS) * 1000, "ms", OscilloscopeData
	endif
End

/// @brief Prepares a subset/copy of `ITCDataWave` for displaying it in the
/// oscilloscope panel
///
/// @param panelTitle  panel title
/// @param dataAcqOrTP One of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param chunk       Only for #TEST_PULSE_MODE and multi device mode; Selects
///                    the testpulse to extract
/// @param fifoPos     Position of the fifo used by the ITC XOP to keep track of
///                    the position which will be written next
/// @param deviceID    device ID
Function SCOPE_UpdateOscilloscopeData(panelTitle, dataAcqOrTP, [chunk, fifoPos, deviceID])
	string panelTitle
	variable dataAcqOrTP, chunk, fifoPos, deviceID

	variable hardwareType = GetHardwareType(panelTitle)
	switch(hardwareType)
		case HARDWARE_ITC_DAC:
			if(dataAcqOrTP == TEST_PULSE_MODE)
				if(ParamIsDefault(chunk))
					chunk = 0
				endif
				ASSERT(ParamIsDefault(fifoPos), "optional parameter fifoPos is not possible with TEST_PULSE_MODE")
			elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)
				ASSERT(!ParamIsDefault(fifoPos), "optional parameter fifoPos missing")
				ASSERT(ParamIsDefault(chunk), "optional parameter chunk is not possible with DATA_ACQUISITION_MODE")
			endif
			SCOPE_ITC_UpdateOscilloscope(panelTitle, dataAcqOrTP, chunk, fifoPos)
			break;
		case HARDWARE_NI_DAC:
			ASSERT(!ParamIsDefault(deviceID), "optional parameter deviceID missing (required for NI devices in TP mode)")
			SCOPE_NI_UpdateOscilloscope(panelTitle, dataAcqOrTP, deviceID, fifoPos)
			break;
	endswitch
End

static Function SCOPE_NI_UpdateOscilloscope(panelTitle, dataAcqOrTP, deviceiD, fifoPos)
	string panelTitle
	variable dataAcqOrTP, deviceID, fifoPos

	variable i, channel
	string fifoName
	WAVE OscilloscopeData = GetOscilloscopeWave(panelTitle)
	WAVE/WAVE NIDataWave = GetHardwareDataWave(panelTitle)

	fifoName = GetNIFIFOName(deviceID)
	FIFOStatus/Q $fifoName
	ASSERT(V_Flag != 0, "FIFO does not exist!")
	if(dataAcqOrTP == TEST_PULSE_MODE)
		// update a full pulse
		for(i = 0; i < V_FIFOnchans; i += 1)
			channel = str2num(StringByKey("NAME" + num2str(i), S_Info))
			WAVE NIChannel = NIDataWave[channel]
			multithread OscilloscopeData[][channel] = NIChannel[p]
		endfor
		SCOPE_UpdatePowerSpectrum(panelTitle)
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)
		// it is in this moment the previous fifo position, so the new data goes from here to fifoPos-1
		NVAR fifoPosGlobal = $GetFifoPosition(panelTitle)
		for(i = 0; i < V_FIFOnchans; i += 1)
			channel = str2num(StringByKey("NAME" + num2str(i), S_Info))
			WAVE NIChannel = NIDataWave[channel]
			Multithread OscilloscopeData[fifoPosGlobal, fifoPos - 1][channel] = NIChannel[p]
		endfor
	endif
	SetScale/P y, DimOffset(NIChannel, ROWS), DimDelta(NIChannel, ROWS), "" OscilloscopeData
End

static Function SCOPE_ITC_UpdateOscilloscope(panelTitle, dataAcqOrTP, chunk, fifoPos)
	string panelTitle
	variable dataAcqOrTP, chunk, fifoPos

	WAVE OscilloscopeData = GetOscilloscopeWave(panelTitle)
	variable length, first, last
	variable startOfADColumns, numEntries
	WAVE ITCDataWave      = GetHardwareDataWave(panelTitle)
	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
	WAVE ADCs = GetADCListFromConfig(ITCChanConfigWave)
	WAVE DA_EphysGuiState = GetDA_EphysGuiStateNum(panelTitle)
	startOfADColumns = DimSize(GetDACListFromConfig(ITCChanConfigWave), ROWS)
	numEntries = DimSize(ADCs, ROWS)

	//do the AD scaling here manually so that is can be as fast as possible
	Make/FREE/N=(numEntries) gain = DA_EphysGuiState[ADCs[p]][%$GetSpecialControlLabel(CHANNEL_TYPE_ADC, CHANNEL_CONTROL_GAIN)] * HARDWARE_ITC_BITS_PER_VOLT

	if(dataAcqOrTP == TEST_PULSE_MODE)
		length = TP_GetTestPulseLengthInPoints(panelTitle, TEST_PULSE_MODE)
		first  = chunk * length
		last   = first + length - 1
		ASSERT(first >= 0 && last < DimSize(ITCDataWave, ROWS) && first < last, "Invalid wave subrange")

#ifdef DEBUGGING_ENABLED
		if(DP_DebuggingEnabledForFile(GetFile(FunctionPath(""))))

			ITCDataWave[0][0] += 0
			if(!WindowExists("ITCDataWaveTPMD"))
				Display/N=ITCDataWaveTPMD ITCDataWave[][1]
			endif

			Cursor/W=ITCDataWaveTPMD/H=2/P A ITCDataWave first
			Cursor/W=ITCDataWaveTPMD/H=2/P B ITCDataWave last
		endif
#endif
		Multithread OscilloscopeData[][startOfADColumns, startOfADColumns + numEntries - 1] = ITCDataWave[first + p][q] / gain[q - startOfADColumns]
		SCOPE_UpdatePowerSpectrum(panelTitle)

	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)

		ASSERT(EqualWaves(ITCDataWave, OscilloscopeData, 512), "ITCDataWave and OscilloscopeData have differing dimensions")
		fifoPos += GetDataOffset(ITCChanConfigWave)

		if(fifoPos == 0 || !IsFinite(fifoPos))
			// nothing to do
			return NaN
		elseif(fifoPos < 0)
			printf "fifoPos was clipped to zero, old value %g\r", fifoPos
			return NaN
		elseif(fifoPos >= DimSize(OscilloscopeData, ROWS))
			printf "fifoPos was clipped to row size of OscilloscopeData, old value %g\r", fifoPos
			fifoPos = DimSize(OscilloscopeData, ROWS) - 1
		endif

		NVAR fifoPosGlobal = $GetFifoPosition(panelTitle)

		if(fifoPosGlobal == fifoPos)
			return NaN
		endif

		Multithread OscilloscopeData[fifoPosGlobal, fifoPos - 1][startOfADColumns, startOfADColumns + numEntries - 1] = ITCDataWave[p][q] / gain[q - startOfADColumns]

		fifoPosGlobal = fifoPos
	else
		ASSERT(0, "Invalid dataAcqOrTP value")
	endif
End
