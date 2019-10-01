#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SCOPE
#endif

/// @file MIES_Oscilloscope.ipf
/// @brief __SCOPE__ Scope window handling for data acquisition and testpulse results

static Constant SCOPE_TIMEAXIS_RESISTANCE_RANGE = 120
static Constant SCOPE_GREEN                     = 26122
static Constant SCOPE_BLUE                      = 39168
static StrConstant RES_FORMAT_STR               = "\\[1\\K(%d, %d, %d)\\{\"%%s\", FloatWithMinSigDigits(%s[%d], numMinSignDigits = 2)}\\]1\K(0, 0, 0)"
static Constant PRESSURE_SPECTRUM_PERCENT       = 0.05

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

// @brief Finds the current minimum for the top time axis for TP graphs
// @param[in]  panelTitle title of panel
// @param[out] axisMin suggested new axis minimum
// @return 1 if axisMin has changed, 0 otherwise
Function SCOPE_GetTPTopAxisStart(panelTitle, axisMin)
	string panelTitle
	variable &axisMin

	string graph
	variable count, latest

	graph = SCOPE_GetGraph(panelTitle)
	GetAxis/W=$graph/Q $AXIS_SCOPE_TP_TIME
	if(V_flag)
		return 0
	endif

	Wave TPStorage = GetTPStorage(panelTitle)
	count = GetNumberFromWaveNote(TPStorage, NOTE_INDEX)

	if(count > 0)
		latest = TPStorage[count - 1][0][%DeltaTimeInSeconds]
		if(latest >= V_max)
			axisMin = latest - 0.5 * SCOPE_TIMEAXIS_RESISTANCE_RANGE
			return 1
		else
			axisMin = V_min
			return 0
		endif
	else
		axisMin = 0
		return V_Min != 0
	endif
End

Function SCOPE_UpdateGraph(panelTitle, dataAcqOrTP)
	string panelTitle
	variable dataAcqOrTP

	variable i, numADCs, range, numDACs, statsMin, statsMax
	variable axisMin, axisMax, spacing, additionalSpacing
	variable showSteadyStateResistance, showPeakResistance, showPowerSpectrum
	variable updateInt, now
	string graph, leftAxis

	NVAR timestamp = $GetLastAcqHookCallTimeStamp(panelTitle)
	updateInt = DAG_GetNumericalValue(panelTitle, "setvar_Settings_OsciUpdInt")
	now = DateTime
	if((now - timestamp) < updateInt / 1000)
		return 0
	endif
	timestamp = now

	graph = SCOPE_GetGraph(panelTitle)
	if(SCOPE_GetTPTopAxisStart(panelTitle, axisMin))
		SetAxis/W=$graph $AXIS_SCOPE_TP_TIME, axisMin, axisMin + SCOPE_TIMEAXIS_RESISTANCE_RANGE
	endif

	if(DAG_GetNumericalValue(panelTitle, "Popup_Settings_OsciUpdMode") != GUI_SETTING_OSCI_SCALE_INTERVAL)
		return 0
	endif

	SCOPE_GetCheckBoxesForAddons(panelTitle, showSteadyStateResistance, showPeakResistance, showPowerSpectrum)
	if(showPowerSpectrum)
		return NaN
	endif

	if(!GotTPChannelsOnADCs(paneltitle))
		return NaN
	endif

	WAVE config = GetITCChanConfigWave(panelTitle)
	WAVE ADCmode = GetADCTypesFromConfig(config)
	WAVE ADCs = GetADCListFromConfig(config)
	WAVE DACs = GetDACListFromConfig(config)
	numADCs = DimSize(ADCs, ROWS)
	numDACs = DimSize(DACs, ROWS)

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		WAVE TPData = GetTPOscilloscopeWave(panelTitle)
	else
		WAVE TPData = GetOscilloscopeWave(panelTitle)
	endif

	additionalSpacing = DAG_GetNumericalValue(panelTitle, "setvar_Settings_OsciUpdExt") / 100

	// scale the left AD axes
	for(i = 0; i < numADCs; i += 1)

		if(ADCmode[i] != DAQ_CHANNEL_TYPE_TP)
			continue
		endif

		leftAxis = AXIS_SCOPE_AD + num2str(ADCs[i])

		WaveStats/M=1/Q/RMD=[][numDACs + i] TPData

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
			spacing = (statsMax - statsMin) * additionalSpacing
		else
			spacing = (axisMax - axisMin) * additionalSpacing
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

	string graph, color, style
	variable i, adc, numActiveDACs, numADChannels, oneTimeInitDone, chanTPmode, scopeScaleMode
	variable showSteadyStateResistance, showPeakResistance, Red, Green, Blue, gotTPChan, gotDAQChan
	string leftAxis, rightAxis, str, powerSpectrumTrace, oscilloscopeTrace
	string steadyStateTrace, peakTrace, adcStr
	variable YaxisLow, YaxisHigh, YaxisSpacing, Yoffset, resPosPercY
	variable testPulseLength, cutOff, sampInt, axisMinTop, axisMaxTop
	variable headStage, activeHeadStage, showPowerSpectrum
	STRUCT RGBColor peakColor
	STRUCT RGBColor steadyColor

	SCOPE_OpenScopeWindow(panelTitle)
	graph = SCOPE_GetGraph(panelTitle)
	scopeScaleMode = DAG_GetNumericalValue(panelTitle, "Popup_Settings_OsciUpdMode")

	WAVE ITCChanConfigWave  = GetITCChanConfigWave(panelTitle)
	WAVE SSResistance       = GetSSResistanceWave(panelTitle)
	WAVE InstResistance     = GetInstResistanceWave(panelTitle)
	WAVE TPStorage          = GetTPStorage(panelTitle)
	WAVE OscilloscopeData   = GetOscilloscopeWave(panelTitle)
	WAVE TPOscilloscopeData = GetTPOscilloscopeWave(panelTitle)
	WAVE PressureData	= P_GetPressureDataWaveRef(panelTitle)

	WAVE ADCmode = GetADCTypesFromConfig(ITCChanConfigWave)
	WAVE ADCs = GetADCListFromConfig(ITCChanConfigWave)
	numADChannels = DimSize(ADCs, ROWS)
	numActiveDACs = DimSize(GetDACListFromConfig(ITCChanConfigWave), ROWS)
	graph = SCOPE_GetGraph(panelTitle)
	Yoffset = 40 / numADChannels
	YaxisSpacing = 0.95 / numADChannels
	YaxisHigh = 1
	YaxisLow = YaxisHigh - YaxisSpacing + 0.025
	peakColor.green = SCOPE_GREEN
	steadyColor.blue = SCOPE_BLUE
	activeHeadStage = GetDA_EphysGuiStateNum(panelTitle)[0][%slider_DataAcq_ActiveHeadstage]

	GetAxisRange(graph, AXIS_SCOPE_TP_TIME, axisMinTop, axisMaxTop, mode=AXIS_RANGE_INC_AUTOSCALED)
	if(dataAcqOrTP != TEST_PULSE_MODE || !showPowerSpectrum && scopeScaleMode == GUI_SETTING_OSCI_SCALE_FIXED)
		WAVE previousADAxesRanges = GetAxesRanges(graph, axesRegexp=AXIS_SCOPE_AD_REGEXP, orientation=AXIS_ORIENTATION_LEFT, mode=AXIS_RANGE_INC_AUTOSCALED)
	endif

	RemoveTracesFromGraph(graph)
	RemoveAnnotationsFromGraph(graph)

	SCOPE_GetCheckBoxesForAddons(panelTitle, showSteadyStateResistance, showPeakResistance, showPowerSpectrum)

	for(i = 0; i < numADChannels; i += 1)
		chanTPmode = (ADCmode[i] == DAQ_CHANNEL_TYPE_TP)

		adc    = ADCs[i]
		adcStr = num2str(adc)
		leftAxis = AXIS_SCOPE_AD + adcStr
		
		if((chanTPmode && !showPowerSpectrum) || !chanTPmode)

			oscilloscopeTrace = "osci" + adcStr
			if(chanTPmode && !showPowerSpectrum)
				gotTPChan = 1
				if(dataAcqOrTP == DATA_ACQUISITION_MODE)
					AppendToGraph/W=$graph/L=$leftAxis/B=bottomTP TPOscilloscopeData[][numActiveDACs + i]/TN=$oscilloscopeTrace
				else
					AppendToGraph/W=$graph/L=$leftAxis/B=bottomTP OscilloscopeData[][numActiveDACs + i]/TN=$oscilloscopeTrace
				endif
			else
				gotDAQChan = 1
				AppendToGraph/W=$graph/L=$leftAxis/B=bottomDAQ OscilloscopeData[][numActiveDACs + i]/TN=$oscilloscopeTrace
			endif

			// use fast line drawing
			ModifyGraph/W=$graph live($oscilloscopeTrace)=(2^1)
			ModifyGraph/W=$graph axisEnab($leftAxis) = {YaxisLow, YaxisHigh}, freepos($leftAxis) = {0, kwFraction}
			ModifyGraph/W=$graph lblPosMode($leftAxis)=4, lblPos($leftAxis) = 50
		endif

		// handles plotting of peak and steady state resistance curves in the oscilloscope window with the TP
		// add the also the trace for the current resistance values from the test pulse
		if(chanTPmode)

			headStage = AFH_GetHeadstageFromADC(panelTitle, adc)

			if(showPowerSpectrum)
				powerSpectrumTrace = "powerSpectra" + adcStr
				WAVE powerSpectrum = GetTPPowerSpectrumWave(panelTitle)
				AppendToGraph/W=$graph/L=$leftAxis/B=bottomPS powerSpectrum[][numActiveDACs + i]/TN=$powerSpectrumTrace
				ModifyGraph/W=$graph lstyle=0, mode($powerSpectrumTrace)=0
				ModifyGraph/W=$graph rgb($powerSpectrumTrace)=(65535,0,0,13107)
				ModifyGraph/W=$graph freepos($leftAxis) = {0, kwFraction}, axisEnab($leftAxis)= {YaxisLow, YaxisHigh}
				ModifyGraph/W=$graph lblPosMode($leftAxis)=4, lblPos($leftAxis) = 50, log($leftAxis)=1
				SetAxis/W=$graph/A=2/N=2 $leftAxis
				// use fast line drawing
				ModifyGraph/W=$graph live($powerSpectrumTrace)=(2^1)
			endif

			rightAxis = "resistance" + adcStr

			if(showPeakResistance)
				peakTrace = "PeakResistance" + adcStr
				AppendToGraph/W=$graph/R=$rightAxis/T=$AXIS_SCOPE_TP_TIME TPStorage[][headstage][%PeakResistance]/TN=$peakTrace vs TPStorage[][headstage][%DeltaTimeInSeconds]
				SetAxis/W=$graph/A=2/N=1 $rightAxis
				ModifyGraph/W=$graph fSize($rightAxis)=10,grid($rightAxis)=1,gridStyle($rightAxis)=4,gridRGB($rightAxis)=(0,0,0,3277)
				ModifyGraph/W=$graph live($peakTrace)=(2^1)
				ModifyGraph/W=$graph lstyle($peakTrace)=1, rgb($peakTrace)=(peakColor.red, peakColor.green, peakColor.blue)
				ModifyGraph/W=$graph mode($peakTrace)=2
			endif

			if(showSteadyStateResistance)
				steadyStateTrace = "SteadyStateResistance" + adcStr
				AppendToGraph/W=$graph/R=$rightAxis/T=$AXIS_SCOPE_TP_TIME TPStorage[][headstage][%SteadyStateResistance]/TN=$steadyStateTrace vs TPStorage[][headstage][%DeltaTimeInSeconds]
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

				ModifyGraph/W=$graph live($steadyStateTrace)=(2^1)
				ModifyGraph/W=$graph mode($steadyStateTrace)=2
			endif

			if(showPeakResistance || showSteadyStateResistance)
				ModifyGraph/W=$graph axisEnab($rightAxis) = {YaxisLow, YaxisLow + (YaxisHigh - YaxisLow) * 0.3}, freePos($rightAxis)={0, kwFraction}
				ModifyGraph/W=$graph lblPosMode($rightAxis) = 4, lblPos($rightAxis) = 60, lblRot($rightAxis) = 180
				ModifyGraph/W=$graph nticks($rightAxis) = 2, tickUnit($AXIS_SCOPE_TP_TIME)=1
				Label/W=$graph $rightAxis "(MΩ)"

				if(!oneTimeInitDone)
					sprintf str, "\\[1\\K(%d, %d, %d)R\\Bss\\M(MΩ)\\]1\\K(%d, %d,%d)\r\\[1\\K(0, 26122, 0)R\\Bpeak\\M(MΩ)\\]1\\K(0, 0, 0)", steadyColor.red, steadyColor.green, steadyColor.blue, peakColor.red, peakColor.green, peakColor.blue
					TextBox/W=$graph/F=0/B=1/X=0.62/Y=0.36/E=2  str

					Label/W=$graph $AXIS_SCOPE_TP_TIME "Relative time (s)"
					SetAxis/W=$graph/A=2 $rightAxis

					if(!isNaN(axisMinTop))
						SetAxis/W=$graph $AXIS_SCOPE_TP_TIME, axisMinTop, axisMinTop + SCOPE_TIMEAXIS_RESISTANCE_RANGE
					endif
					if(SCOPE_GetTPTopAxisStart(panelTitle, axisMinTop))
						SetAxis/W=$graph $AXIS_SCOPE_TP_TIME, axisMinTop, axisMinTop + SCOPE_TIMEAXIS_RESISTANCE_RANGE
					endif

					oneTimeInitDone = 1
				endif
			endif

			resPosPercY = 100 * (1 - ((YaxisHigh - YaxisLow) / 2 + YaxisLow))
			sprintf str, RES_FORMAT_STR, steadyColor.red, steadyColor.green, steadyColor.blue, GetWavesDataFolder(SSResistance, 2), headstage
			TextBox/W=$graph/A=RT/B=1/F=0/X=-10 /Y=(resPosPercY - 1) str
			sprintf str, RES_FORMAT_STR, peakColor.red, peakColor.green, peakColor.blue, GetWavesDataFolder(InstResistance, 2), headstage
			TextBox/W=$graph/A=RT/B=1/F=0/X=-10 /Y=(resPosPercY + 1) str

		endif

		YaxisHigh -= YaxisSpacing
		YaxisLow -= YaxisSpacing
	endfor

	if(WaveExists(previousADAxesRanges))
		SetAxesRanges(graph, previousADAxesRanges, axesRegexp=AXIS_SCOPE_AD_REGEXP, orientation=AXIS_ORIENTATION_LEFT, mode=AXIS_RANGE_USE_MINMAX)
	endif

	SCOPE_SetADAxisLabel(panelTitle,activeHeadStage)

	if(showPowerSpectrum)
			Label/W=$graph bottomPS "Frequency (\\U)"
			SetAxis/W=$graph/A bottomPS
			ModifyGraph/W=$graph freePos(bottomPS)=0
	elseif(gotTPChan)
			Label/W=$graph bottomTP "Time TP (\\U)"
			sampInt = DAP_GetSampInt(panelTitle, TEST_PULSE_MODE) / 1000
			testPulseLength = ROVar(GetTestPulseLengthInPoints(panelTitle, TEST_PULSE_MODE)) * sampInt
			NVAR duration = $GetTestpulseDuration(panelTitle)
			NVAR baselineFrac = $GetTestpulseBaselineFraction(panelTitle)
			cutOff = max(0, baseLineFrac * testPulseLength - duration/2 * sampInt)
			SetAxis/W=$graph bottomTP cutOff, testPulseLength - cutOff
			ModifyGraph/W=$graph freePos(bottomTP)=0
	endif
	if(gotDAQChan)
		Label/W=$graph bottomDAQ "Time DAQ (\\U)"
		NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
		sampInt = DAP_GetSampInt(panelTitle, DATA_ACQUISITION_MODE) / 1000
		SetAxis/W=$graph bottomDAQ 0, stopCollectionPoint * sampInt
		ModifyGraph/W=$graph freePos(bottomDAQ)=-35
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
		leftAxis = AXIS_SCOPE_AD + num2str(adc)

		if(WhichListItem(leftAxis, axList) == -1)
			continue
		endif

		headStage = AFH_GetHeadstageFromADC(panelTitle, adc)
		if(isFinite(headStage))
			labelStr = "HS" + num2str(headstage)
			GetTraceColor(headStage, red, green, blue)
		else
			labelStr = AXIS_SCOPE_AD + num2str(adc)
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
/// @param fifoPos     Position of the hardware DAQ fifo to keep track of
///                    the position which will be written next
/// @param deviceID    device ID
Function SCOPE_UpdateOscilloscopeData(panelTitle, dataAcqOrTP, [chunk, fifoPos, deviceID])
	string panelTitle
	variable dataAcqOrTP, chunk, fifoPos, deviceID

	STRUCT TPAnalysisInput tpInput
	string osciUnits
	variable i, j
	variable tpChannels, numADCs, numDACs, tpLengthPoints, tpStart, tpEnd, tpStartPos
	variable TPChanIndex, saveTP, sampleInt
	variable headstage, fifoLatest
	string hsList

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
				fifopos = SCOPE_ITC_AdjustFIFOPos(panelTitle, fifopos)
				ASSERT(IsFinite(fifopos), "Invalid fifo position")
			endif
			SCOPE_ITC_UpdateOscilloscope(panelTitle, dataAcqOrTP, chunk, fifoPos)
			break;
		case HARDWARE_NI_DAC:
			ASSERT(!ParamIsDefault(deviceID), "optional parameter deviceID missing (required for NI devices in TP mode)")
			SCOPE_NI_UpdateOscilloscope(panelTitle, dataAcqOrTP, deviceID, fifoPos)
			break;
	endswitch

	WAVE config = GetITCChanConfigWave(panelTitle)
	WAVE ADCmode = GetADCTypesFromConfig(config)
	tpChannels = GetNrOfTypedChannels(ADCmode, DAQ_CHANNEL_TYPE_TP)

	// send data to TP Analysis if TP present
	NVAR fifoPosGlobal = $GetFifoPosition(panelTitle)

	if(tpChannels)
		WAVE GUIState = GetDA_EphysGuiStateNum(panelTitle)
		saveTP = GUIState[0][%check_Settings_TP_SaveTP]

		tpLengthPoints = ROVAR(GetTestPulseLengthInPoints(panelTitle, dataAcqOrTP))
		// use a 'virtual' end position for fifoLatest for TP Mode since the input data contains one TP only
		fifoLatest = (dataAcqOrTP == TEST_PULSE_MODE) ? tpLengthPoints : fifoPos

		WAVE ADCs = GetADCListFromConfig(config)
		WAVE hsProp = GetHSProperties(panelTitle)
		NVAR duration = $GetTestpulseDuration(panelTitle)
		NVAR baselineFrac = $GetTestpulseBaselineFraction(panelTitle)

		WAVE scaledDataWave = GetScaledDataWave(panelTitle)
		sampleInt = DimDelta(scaledDataWave, ROWS)
		osciUnits = WaveUnits(scaledDataWave, ROWS)
		numDACs = DimSize(GetDACListFromConfig(config), ROWS)
		numADCs = DimSize(ADCs, ROWS)

		// note: currently this works for multiplier = 1 only, see DC_PlaceDataInHardwareDataWave
		Make/FREE/N=(tpLengthPoints) channelData
		WAVE tpInput.data = channelData
		SetScale/P x, 0, sampleInt, osciUnits, channelData

		tpInput.panelTitle = panelTitle
		tpInput.duration = duration
		tpInput.baselineFrac = baselineFrac
		tpInput.tpLengthPoints = tpLengthPoints
		tpInput.readTimeStamp = ticks * TICKS_TO_SECONDS
		tpInput.activeADCs = tpChannels

		tpStart = trunc(fifoPosGlobal / tpLengthPoints)
		tpEnd = trunc(fifoLatest / tpLengthPoints)
		ASSERT(tpStart <= tpEnd, "New fifopos is smaller than previous fifopos")
		Make/FREE/D/N=(tpEnd - tpStart) tpMarker
		NewRandomSeed()
		tpMarker[] = GetUniqueInteger()

		DEBUGPRINT("tpChannels: ", var = tpChannels)
		DEBUGPRINT("tpLength: ", var = tpLengthPoints)

		for(i = tpStart;i < tpEnd; i += 1)

			tpInput.measurementMarker = tpMarker[i - tpStart]
			tpStartPos = i * tpLengthPoints

			if(saveTP)
				Duplicate/FREE/R=[tpStartPos, tpStartPos + tpLengthPoints - 1][numDACs, numDACs + tpChannels - 1] scaledDataWave, StoreTPWave
				SetScale/P x, 0, sampleInt, osciUnits, StoreTPWave
				TPChanIndex = 0
				hsList = ""
			endif

			for(j = 0; j < numADCs; j += 1)
				if(ADCmode[j] == DAQ_CHANNEL_TYPE_TP)

					MultiThread channelData[] = scaledDataWave[tpStartPos + p][numDACs + j]

					headstage = AFH_GetHeadstageFromADC(panelTitle, ADCs[j])
					if(hsProp[headstage][%ClampMode] == I_CLAMP_MODE)
						NVAR clampAmp=$GetTPAmplitudeIC(panelTitle)
					else
						NVAR clampAmp=$GetTPAmplitudeVC(panelTitle)
					endif
					tpInput.clampAmp = clampAmp
					tpInput.clampMode = hsProp[headstage][%ClampMode]
					tpInput.hsIndex = headstage

					DEBUGPRINT("headstage: ", var = headstage)
					DEBUGPRINT("channel: ", var = numDACs + j)

					TP_SendToAnalysis(tpInput)

					if(saveTP)
						hsList = AddListItem(num2str(headstage), hsList, ",", Inf)
						if(TPChanIndex != j)
							MultiThread StoreTPWave[][TPChanIndex] = channelData[p]
						endif
						TPChanIndex += 1
					endif

				endif
			endfor

			if(saveTP)
				DEBUGPRINT("Storing TP with marker: ", var = tpInput.measurementMarker)
				TP_StoreTP(panelTitle, StoreTPWave, tpInput.measurementMarker, hsList)
				WaveClear StoreTPWave
			endif

		endfor

		if(dataAcqOrTP == DATA_ACQUISITION_MODE)
			WAVE TPOscilloscopeData = GetTPOscilloscopeWave(panelTitle)
			Duplicate/O/R=[tpStartPos, tpStartPos + tpLengthPoints - 1][] scaledDataWave TPOscilloscopeData
			SetScale/P x, 0, sampleInt, osciUnits, TPOscilloscopeData
		endif

	endif

	// Sync fifo position
	fifoPosGlobal = fifoPos

	ASYNC_ThreadReadOut()
End

static Function SCOPE_NI_UpdateOscilloscope(panelTitle, dataAcqOrTP, deviceiD, fifoPos)
	string panelTitle
	variable dataAcqOrTP, deviceID, fifoPos

	variable i, channel, decMethod, decFactor
	string fifoName

	WAVE scaledDataWave    = GetScaledDataWave(panelTitle)
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
			Multithread scaledDataWave[][] = OscilloscopeData
		endfor
		SCOPE_UpdatePowerSpectrum(panelTitle)
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)
		// it is in this moment the previous fifo position, so the new data goes from here to fifoPos-1
		NVAR fifoPosGlobal = $GetFifoPosition(panelTitle)

		WAVE allGain = SWS_GetChannelGains(panelTitle, timing = GAIN_AFTER_DAQ)
		Multithread scaledDataWave[fifoPosGlobal, fifoPos - 1][] = MapWaveRefWave(NIDataWave, q)[p] / allGain[q]

		decMethod = GetNumberFromWaveNote(OscilloscopeData, "DecimationMethod")
		decFactor = GetNumberFromWaveNote(OscilloscopeData, "DecimationFactor")

		for(i = 0; i < V_FIFOnchans; i += 1)
			channel = str2num(StringByKey("NAME" + num2str(i), S_Info))
			WAVE NIChannel = NIDataWave[channel]

			switch(decMethod)
				case DECIMATION_NONE:
					Multithread OscilloscopeData[fifoPosGlobal, fifoPos - 1][channel] = NIChannel[p]
					break
				default:
					DecimateWithMethod(NIChannel, OscilloscopeData, decFactor, decMethod, firstRowInp = fifoPosGlobal, lastRowInp = fifoPos - 1, firstColInp = 0, lastColInp = 0, firstColOut = channel, lastColOut = channel)
					break
			endswitch
		endfor
	endif
End

static Function SCOPE_ITC_UpdateOscilloscope(panelTitle, dataAcqOrTP, chunk, fifoPos)
	string panelTitle
	variable dataAcqOrTP, chunk, fifoPos

	WAVE OscilloscopeData = GetOscilloscopeWave(panelTitle)
	variable length, first, last
	variable startOfADColumns, numEntries, decMethod, decFactor
	WAVE scaledDataWave    = GetScaledDataWave(panelTitle)
	WAVE ITCDataWave       = GetHardwareDataWave(panelTitle)
	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
	WAVE ADCs = GetADCListFromConfig(ITCChanConfigWave)
	startOfADColumns = DimSize(GetDACListFromConfig(ITCChanConfigWave), ROWS)
	numEntries = DimSize(ADCs, ROWS)

	WAVE allGain = SWS_GETChannelGains(panelTitle, timing = GAIN_AFTER_DAQ)

	if(dataAcqOrTP == TEST_PULSE_MODE)
		length = ROVAR(GetTestPulseLengthInPoints(panelTitle, TEST_PULSE_MODE))
		first  = chunk * length
		last   = first + length - 1
		ASSERT(first >= 0 && last < DimSize(ITCDataWave, ROWS) && first < last, "Invalid wave subrange")

#ifdef DEBUGGING_ENABLED
		if(DP_DebuggingEnabledForFile(GetFile(FunctionPath(""))))

			ITCDataWave[0][0] += 0
			if(!WindowExists("ITCDataWaveTPMD"))
				Display/N=ITCDataWaveTPMD ITCDataWave[][1]
			endif

			Cursor/W=ITCDataWaveTPMD/H=2/P A HardwareDataWave first
			Cursor/W=ITCDataWaveTPMD/H=2/P B HardwareDataWave last
		endif
#endif

		Multithread OscilloscopeData[][startOfADColumns, startOfADColumns + numEntries - 1] = ITCDataWave[first + p][q] / allGain[q]
		Multithread scaledDataWave[][] = OscilloscopeData

		SCOPE_UpdatePowerSpectrum(panelTitle)

	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)

		if(fifopos <= 0)
			return NaN
		endif

		NVAR fifoPosGlobal = $GetFifoPosition(panelTitle)

		if(fifoPosGlobal == fifoPos)
			return NaN
		endif

		Multithread scaledDataWave[fifoPosGlobal, fifoPos][] = ITCDataWave[p][q] / allGain[q]

		decMethod = GetNumberFromWaveNote(OscilloscopeData, "DecimationMethod")
		decFactor = GetNumberFromWaveNote(OscilloscopeData, "DecimationFactor")

		switch(decMethod)
			case DECIMATION_NONE:
				Multithread OscilloscopeData[fifoPosGlobal, fifoPos - 1][startOfADColumns, startOfADColumns + numEntries - 1] = ITCDataWave[p][q] / allGain[q]
				break
			default:
				Duplicate/FREE/RMD=[startOfADColumns, startOfADColumns + numEntries - 1] allGain, gain
				gain[] = 1 / gain[p]
				DecimateWithMethod(ITCDataWave, OscilloscopeData, decFactor, decMethod, firstRowInp = fifoPosGlobal, lastRowInp = fifoPos - 1, firstColInp = startOfADColumns, lastColInp = startOfADColumns + numEntries - 1, factor = gain)
		endswitch
	else
		ASSERT(0, "Invalid dataAcqOrTP value")
	endif
End

/// @brief Adjusts the fifo position when using ITC
///
/// @param panelTitle device
/// @param fifopos    fifo position
///
/// @return adjusted fifo position
static Function SCOPE_ITC_AdjustFIFOPos(panelTitle, fifopos)
	string panelTitle
	variable fifopos

	variable stopCollectionPoint

	WAVE scaledDataWave = GetScaledDataWave(panelTitle)

	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
	fifopos += GetDataOffset(ITCChanConfigWave)

	if(fifoPos == 0)
		return 0
	elseif(IsNaN(fifoPos))
		// we are done
		// return the last valid point in the HardwareDataWave
		stopCollectionPoint = ROVAR(GetStopCollectionPoint(panelTitle))
		fifoPos = stopCollectionPoint - GetDataOffset(ITCChanConfigWave) - 1
	elseif(fifoPos < 0)
		printf "fifoPos was clipped to zero, old value %g\r", fifoPos
		return 0
	endif

	return min(fifoPos, DimSize(scaledDataWave, ROWS) - 1)
End
