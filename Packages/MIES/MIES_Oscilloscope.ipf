#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SCOPE
#endif

/// @file MIES_Oscilloscope.ipf
/// @brief __SCOPE__ Scope window handling for data acquisition and testpulse results

static Constant    SCOPE_TIMEAXIS_RESISTANCE_RANGE = 120
static Constant    SCOPE_GREEN                     = 26122
static Constant    SCOPE_BLUE                      = 39168
static StrConstant RES_FORMAT_STR                  = "\\[1\\K(%d, %d, %d)\\{\"%%s\", FloatWithMinSigDigits(%s[%%%s][%d], numMinSignDigits = 2)}\\]1\\K(0, 0, 0)"
static Constant    PRESSURE_SPECTRUM_PERCENT       = 0.05

Function/S SCOPE_GetGraph(device)
	string device

	return SCOPE_GetPanel(device) + "#oscilloscope"
End

Function/S SCOPE_GetPanel(device)
	string device

	return device + "#Scope"
End

Function SCOPE_OpenScopeWindow(device)
	string device

	string win, graph

	win = SCOPE_GetPanel(device)

	if(windowExists(win))
		return NaN
	endif

	graph = SCOPE_GetGraph(device)

	NewPanel/EXT=0/W=(0, 0, 460, 880)/HOST=$device/N=Scope/K=2
	Display/W=(0, 10, 358, 776)/HOST=$win/N=oscilloscope/FG=(FL, FT, FR, FB)
	ModifyPanel/W=$win fixedSize=0
	ModifyGraph/W=$graph gfSize=14
	ModifyGraph/W=$graph wbRGB=(60928, 60928, 60928), gbRGB=(60928, 60928, 60928)
	SetActiveSubWindow $device
End

Function SCOPE_KillScopeWindowIfRequest(device)
	string device

	string win = SCOPE_GetPanel(device)

	if(!DAG_GetNumericalValue(device, "check_Settings_ShowScopeWindow") && windowExists(win))
		KillWindow $win
	endif
End

// @brief Finds the current minimum for the top time axis for TP graphs
// @param[in]  device title of panel
// @param[out] axisMin suggested new axis minimum
// @return 1 if axisMin has changed, 0 otherwise
Function SCOPE_GetTPTopAxisStart(device, axisMin)
	string    device
	variable &axisMin

	string graph
	variable count, latest

	graph = SCOPE_GetGraph(device)
	GetAxis/W=$graph/Q $AXIS_SCOPE_TP_TIME
	if(V_flag)
		return 0
	endif

	WAVE TPStorage = GetTPStorage(device)
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

Function SCOPE_UpdateGraph(device, dataAcqOrTP)
	string   device
	variable dataAcqOrTP

	variable i, numADCs, range, numDACs, statsMin, statsMax
	variable axisMin, axisMax, spacing, additionalSpacing
	variable showSteadyStateResistance, showPeakResistance, showPowerSpectrum
	variable updateInt, now
	string graph, leftAxis

	NVAR timestamp = $GetLastAcqHookCallTimeStamp(device)
	updateInt = DAG_GetNumericalValue(device, "setvar_Settings_OsciUpdInt")
	now       = DateTime
	if((now - timestamp) < updateInt * MILLI_TO_ONE)
		return 0
	endif
	timestamp = now

	graph = SCOPE_GetGraph(device)
	if(SCOPE_GetTPTopAxisStart(device, axisMin))
		SetAxis/W=$graph $AXIS_SCOPE_TP_TIME, axisMin, axisMin + SCOPE_TIMEAXIS_RESISTANCE_RANGE
	endif

	if(DAG_GetNumericalValue(device, "Popup_Settings_OsciUpdMode") != GUI_SETTING_OSCI_SCALE_INTERVAL)
		return 0
	endif

	[showSteadyStateResistance, showPeakResistance, showPowerSpectrum] = SCOPE_GetCheckBoxesForAddons(device, dataAcqOrTP)

	if(showPowerSpectrum)
		return NaN
	endif

	if(!GotTPChannelsOnADCs(device))
		return NaN
	endif

	WAVE config  = GetDAQConfigWave(device)
	WAVE ADCmode = GetADCTypesFromConfig(config)
	WAVE ADCs    = GetADCListFromConfig(config)
	WAVE DACs    = GetDACListFromConfig(config)
	numADCs = DimSize(ADCs, ROWS)
	numDACs = DimSize(DACs, ROWS)

	if(dataAcqOrTP == DATA_ACQUISITION_MODE)
		WAVE TPData = GetTPOscilloscopeWave(device)
	else
		WAVE TPData = GetOscilloscopeWave(device)
	endif

	additionalSpacing = DAG_GetNumericalValue(device, "setvar_Settings_OsciUpdExt") * PERCENT_TO_ONE

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

		SetAxis/W=$graph $leftAxis, statsMin - spacing / 2.0, statsMax + spacing / 2.0
	endfor
End

static Function [variable showSteadyStateResistance, variable showPeakResistance, variable showPowerSpectrum] SCOPE_GetCheckBoxesForAddons(string device, variable dataAcqOrTP)

	showPeakResistance        = DAG_GetNumericalValue(device, "check_settings_TP_show_peak")
	showSteadyStateResistance = DAG_GetNumericalValue(device, "check_settings_TP_show_steady")
	showPowerSpectrum         = DAG_GetNumericalValue(device, "check_settings_show_power")
End

Function SCOPE_CreateGraph(device, dataAcqOrTP)
	string   device
	variable dataAcqOrTP

	string graph, color, style
	variable i, adc, numActiveDACs, numADChannels, oneTimeInitDone, chanTPmode, scopeScaleMode
	variable showSteadyStateResistance, showPeakResistance, Red, Green, Blue, gotTPChan, gotDAQChan
	string leftAxis, rightAxis, str, powerSpectrumTrace, oscilloscopeTrace
	string steadyStateTrace, peakTrace, adcStr
	variable YaxisLow, YaxisHigh, YaxisSpacing, Yoffset, resPosPercY
	variable testPulseLength, cutOff, sampInt, axisMinTop, axisMaxTop
	variable headStage, activeHeadStage, showPowerSpectrum, baselineFrac, pulseLength, pointsAcq
	STRUCT RGBColor peakColor
	STRUCT RGBColor steadyColor

	SCOPE_OpenScopeWindow(device)
	graph          = SCOPE_GetGraph(device)
	scopeScaleMode = DAG_GetNumericalValue(device, "Popup_Settings_OsciUpdMode")

	WAVE DAQConfigWave      = GetDAQConfigWave(device)
	WAVE TPStorage          = GetTPStorage(device)
	WAVE OscilloscopeData   = GetOscilloscopeWave(device)
	WAVE TPOscilloscopeData = GetTPOscilloscopeWave(device)
	WAVE PressureData       = P_GetPressureDataWaveRef(device)
	WAVE TPSettings         = GetTPSettings(device)
	WAVE TPResults          = GetTPResults(device)

	WAVE ADCmode = GetADCTypesFromConfig(DAQConfigWave)
	WAVE ADCs    = GetADCListFromConfig(DAQConfigWave)
	WAVE DACs    = GetDACListFromConfig(DAQConfigWave)
	numADChannels    = DimSize(ADCs, ROWS)
	numActiveDACs    = DimSize(DACs, ROWS)
	graph            = SCOPE_GetGraph(device)
	Yoffset          = 40 / numADChannels
	YaxisSpacing     = 0.95 / numADChannels
	YaxisHigh        = 1
	YaxisLow         = YaxisHigh - YaxisSpacing + 0.025
	peakColor.green  = SCOPE_GREEN
	steadyColor.blue = SCOPE_BLUE
	activeHeadStage  = DAG_GetNumericalValue(device, "slider_DataAcq_ActiveHeadstage")

	[axisMinTop, axisMaxTop] = GetAxisRange(graph, AXIS_SCOPE_TP_TIME, mode = AXIS_RANGE_INC_AUTOSCALED)
	if(dataAcqOrTP != TEST_PULSE_MODE || !showPowerSpectrum && scopeScaleMode == GUI_SETTING_OSCI_SCALE_FIXED)
		WAVE previousADAxesProperties = GetAxesProperties(graph, axesRegexp = AXIS_SCOPE_AD_REGEXP, orientation = AXIS_ORIENTATION_LEFT, mode = AXIS_RANGE_INC_AUTOSCALED)
	endif

	RemoveTracesFromGraph(graph)
	RemoveAnnotationsFromGraph(graph)

	[showSteadyStateResistance, showPeakResistance, showPowerSpectrum] = SCOPE_GetCheckBoxesForAddons(device, dataAcqOrTP)

	for(i = 0; i < numADChannels; i += 1)
		chanTPmode = (ADCmode[i] == DAQ_CHANNEL_TYPE_TP)

		adc      = ADCs[i]
		adcStr   = num2str(adc)
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
			ModifyGraph/W=$graph axisEnab($leftAxis)={YaxisLow, YaxisHigh}, freepos($leftAxis)={0, kwFraction}
			ModifyGraph/W=$graph lblPosMode($leftAxis)=4, lblPos($leftAxis)=50
		endif

		// handles plotting of peak and steady state resistance curves in the oscilloscope window with the TP
		// add the also the trace for the current resistance values from the test pulse
		if(chanTPmode)

			headStage = AFH_GetHeadstageFromADC(device, adc)

			if(showPowerSpectrum)
				powerSpectrumTrace = "powerSpectra" + adcStr
				AppendToGraph/W=$graph/L=$leftAxis/B=bottomPS TPOscilloscopeData[][numActiveDACs + i]/TN=$powerSpectrumTrace
				ModifyGraph/W=$graph lstyle=0, mode($powerSpectrumTrace)=0
				ModifyGraph/W=$graph rgb($powerSpectrumTrace)=(65535, 0, 0, 13107)
				ModifyGraph/W=$graph freepos($leftAxis)={0, kwFraction}, axisEnab($leftAxis)={YaxisLow, YaxisHigh}
				ModifyGraph/W=$graph lblPosMode($leftAxis)=4, lblPos($leftAxis)=50, log($leftAxis)=1
				SetAxis/W=$graph/A=2/N=2 $leftAxis
				// use fast line drawing
				ModifyGraph/W=$graph live($powerSpectrumTrace)=(2^1)
			endif

			rightAxis = "resistance" + adcStr

			if(showPeakResistance)
				peakTrace = "PeakResistance" + adcStr
				AppendToGraph/W=$graph/R=$rightAxis/T=$AXIS_SCOPE_TP_TIME TPStorage[][headstage][%PeakResistance]/TN=$peakTrace vs TPStorage[][headstage][%DeltaTimeInSeconds]
				SetAxis/W=$graph/A=2/N=1 $rightAxis
				ModifyGraph/W=$graph fSize($rightAxis)=10, grid($rightAxis)=1, gridStyle($rightAxis)=4, gridRGB($rightAxis)=(0, 0, 0, 3277)
				ModifyGraph/W=$graph live($peakTrace)=(2^1)
				ModifyGraph/W=$graph lstyle($peakTrace)=1, rgb($peakTrace)=(peakColor.red, peakColor.green, peakColor.blue)
				ModifyGraph/W=$graph mode($peakTrace)=2
			endif

			if(showSteadyStateResistance)
				steadyStateTrace = "SteadyStateResistance" + adcStr
				AppendToGraph/W=$graph/R=$rightAxis/T=$AXIS_SCOPE_TP_TIME TPStorage[][headstage][%SteadyStateResistance]/TN=$steadyStateTrace vs TPStorage[][headstage][%DeltaTimeInSeconds]
				SetAxis/W=$graph/A=2/N=1 $rightAxis
				ModifyGraph/W=$graph fSize($rightAxis)=10, grid($rightAxis)=1, gridStyle($rightAxis)=4, gridRGB($rightAxis)=(0, 0, 0, 3277)
				ASSERT(isFinite(headStage), "invalid headStage")
				if(isFinite(PressureData[headStage][%DAC_DevID])) // Check if pressure is enabled
					ModifyGraph/W=$graph marker($steadyStateTrace)=19, mode($steadyStateTrace)=4
					ModifyGraph/W=$graph msize($steadyStateTrace)=1, gaps($steadyStateTrace)=0
					ModifyGraph/W=$graph useMrkStrokeRGB($steadyStateTrace)=1, mrkStrokeRGB($steadyStateTrace)=(65535, 65535, 65535)
					ModifyGraph/W=$graph zColor($steadyStateTrace)={TPStorage[*][headstage][%Pressure],                                  \
					                                                (PRESSURE_SPECTRUM_PERCENT * MIN_REGULATOR_PRESSURE),                \
					                                                (PRESSURE_SPECTRUM_PERCENT * MAX_REGULATOR_PRESSURE), BlueBlackRed, 0}
					ModifyGraph/W=$graph zmrkSize($steadyStateTrace)={TPStorage[*][headstage][%PressureChange], 0, 1, 1, 4}
				else
					ModifyGraph/W=$graph lstyle($steadyStateTrace)=1, rgb($steadyStateTrace)=(steadyColor.red, steadyColor.green, steadyColor.blue)
				endif

				ModifyGraph/W=$graph live($steadyStateTrace)=(2^1)
				ModifyGraph/W=$graph mode($steadyStateTrace)=2
			endif

			if(showPeakResistance || showSteadyStateResistance)
				ModifyGraph/W=$graph axisEnab($rightAxis)={YaxisLow, YaxisLow + (YaxisHigh - YaxisLow) * 0.3}, freePos($rightAxis)={0, kwFraction}
				ModifyGraph/W=$graph lblPosMode($rightAxis)=4, lblPos($rightAxis)=60, lblRot($rightAxis)=180
				ModifyGraph/W=$graph nticks($rightAxis)=2, tickUnit($AXIS_SCOPE_TP_TIME)=1
				Label/W=$graph $rightAxis, "(MΩ)"

				if(!oneTimeInitDone)
					sprintf str, "\\[1\\K(%d, %d, %d)R\\Bss\\M(MΩ)\\]1\\K(%d, %d,%d)\r\\[1\\K(0, 26122, 0)R\\Bpeak\\M(MΩ)\\]1\\K(0, 0, 0)", steadyColor.red, steadyColor.green, steadyColor.blue, peakColor.red, peakColor.green, peakColor.blue
					TextBox/W=$graph/F=0/B=1/X=0.62/Y=0.36/E=2 str

					Label/W=$graph $AXIS_SCOPE_TP_TIME, "Relative time (s)"
					SetAxis/W=$graph/A=2 $rightAxis

					if(!isNaN(axisMinTop))
						SetAxis/W=$graph $AXIS_SCOPE_TP_TIME, axisMinTop, axisMinTop + SCOPE_TIMEAXIS_RESISTANCE_RANGE
					endif
					if(SCOPE_GetTPTopAxisStart(device, axisMinTop))
						SetAxis/W=$graph $AXIS_SCOPE_TP_TIME, axisMinTop, axisMinTop + SCOPE_TIMEAXIS_RESISTANCE_RANGE
					endif

					oneTimeInitDone = 1
				endif
			endif

			resPosPercY = 100 * (1 - ((YaxisHigh - YaxisLow) / 2 + YaxisLow))
			sprintf str, RES_FORMAT_STR, steadyColor.red, steadyColor.green, steadyColor.blue, GetWavesDataFolder(TPResults, 2), "ResistanceSteadyState", headstage
			TextBox/W=$graph/A=RT/B=1/F=0/X=-10/Y=(resPosPercY - 1) str
			sprintf str, RES_FORMAT_STR, peakColor.red, peakColor.green, peakColor.blue, GetWavesDataFolder(TPResults, 2), "ResistanceInst", headstage
			TextBox/W=$graph/A=RT/B=1/F=0/X=-10/Y=(resPosPercY + 1) str

		endif

		YaxisHigh -= YaxisSpacing
		YaxisLow  -= YaxisSpacing
	endfor

	if(WaveExists(previousADAxesProperties))
		SetAxesProperties(graph, previousADAxesProperties, axesRegexp = AXIS_SCOPE_AD_REGEXP, orientation = AXIS_ORIENTATION_LEFT, mode = AXIS_RANGE_USE_MINMAX)
	endif

	SCOPE_SetADAxisLabel(device, dataAcqOrTP, activeHeadStage)

	if(showPowerSpectrum)
		Label/W=$graph bottomPS, "Frequency (\\U)"
		SetAxis/W=$graph/A bottomPS
		ModifyGraph/W=$graph freePos(bottomPS)=0
	elseif(gotTPChan)
		Label/W=$graph bottomTP, "Time TP (\\U)"
		WAVE TPSettingsCalc = GetTPSettingsCalculated(device)
		testPulseLength = TPSettingsCalc[%totalLengthMS]
		pulseLength     = TPSettingsCalc[%pulseLengthMS]
		baselineFrac    = TPSettingsCalc[%baselineFrac]
		cutOff          = max(0, baseLineFrac * testPulseLength - pulseLength / 2)
		SetAxis/W=$graph bottomTP, cutOff, testPulseLength - cutOff
		ModifyGraph/W=$graph freePos(bottomTP)=0
	endif
	if(gotDAQChan)
		Label/W=$graph bottomDAQ, "Time DAQ (\\U)"
		pointsAcq = HW_GetEffectiveADCWaveLength(device, dataAcqOrTP)
		sampInt   = DAP_GetSampInt(device, DATA_ACQUISITION_MODE, XOP_CHANNEL_TYPE_ADC) * MICRO_TO_MILLI
		SetAxis/W=$graph bottomDAQ, 0, pointsAcq * sampInt
		ModifyGraph/W=$graph freePos(bottomDAQ)=-35
	endif
End

Function SCOPE_SetADAxisLabel(device, dataAcqOrTP, activeHeadStage)
	string device
	variable dataAcqOrTP, activeHeadStage

	variable adc, i, headStage
	variable numADChannels
	string leftAxis, style, color, unit, labelStr, graph, axList
	STRUCT RGBColor s

	graph = SCOPE_GetGraph(device)

	if(!windowExists(graph))
		return NaN
	endif

	WAVE DAQConfigWave = GetDAQConfigWave(device)
	WAVE ADCs          = GetADCListFromConfig(DAQConfigWave)

	numADChannels = DimSize(ADCs, ROWS)

	axList = AxisList(graph)

	for(i = 0; i < numADChannels; i += 1)
		adc      = ADCs[i]
		leftAxis = AXIS_SCOPE_AD + num2str(adc)

		if(WhichListItem(leftAxis, axList) == -1)
			continue
		endif

		headStage = AFH_GetHeadstageFromADC(device, adc)
		if(isFinite(headStage))
			labelStr = "HS" + num2str(headstage)
		else
			labelStr = AXIS_SCOPE_AD + num2str(adc)
		endif

		[s] = GetHeadstageColor(headstage)

		sprintf color, "\K(%d,%d,%d)", s.red, s.green, s.blue
		if(activeHeadStage == headStage)
			style = "\f05"
		else
			style = ""
		endif

		if(DAG_GetNumericalValue(device, "check_settings_show_power") && dataAcqOrTP == TEST_PULSE_MODE)
			unit = "a. u."
		else
			unit = AFH_GetChannelUnit(DAQConfigWave, adc, XOP_CHANNEL_TYPE_ADC)
		endif
		Label/W=$Graph $leftAxis, style + color + labelStr + " (" + unit + ")"
	endfor
End

static Function SCOPE_UpdatePowerSpectrum(string device, WAVE columns, [WAVE osci])

	if(DAG_GetNumericalValue(device, "check_settings_show_power"))
		if(ParamIsDefault(osci))
			WAVE OscilloscopeData = GetOscilloscopeWave(device)
		else
			WAVE OscilloscopeData = osci
		endif
		WAVE TPOscilloscopeData = GetTPOscilloscopeWave(device)

		// FFT knows how to transform units without prefix so transform them temporarly
		SetScale/P x, DimOffset(OscilloscopeData, ROWS) * MILLI_TO_ONE, DimDelta(OscilloscopeData, ROWS) * MILLI_TO_ONE, "s", OscilloscopeData

		MultiThread columns[] = DoPowerSpectrum(OscilloscopeData, TPOscilloscopeData, columns[p])

		SetScale/P x, DimOffset(OscilloscopeData, ROWS) * ONE_TO_MILLI, DimDelta(OscilloscopeData, ROWS) * ONE_TO_MILLI, "ms", OscilloscopeData
	endif
End

/// @brief Prepares a subset/copy of `DAQDataWave` for displaying it in the
/// oscilloscope panel
///
/// @param device  panel title
/// @param dataAcqOrTP One of #DATA_ACQUISITION_MODE or #TEST_PULSE_MODE
/// @param chunk       Only for #TEST_PULSE_MODE and multi device mode; Selects
///                    the testpulse to extract
/// @param fifoPos     Position of the hardware DAQ fifo to keep track of
///                    the position which will be written next
/// @param deviceID    device ID
Function SCOPE_UpdateOscilloscopeData(device, dataAcqOrTP, [chunk, fifoPos, deviceID])
	string device
	variable dataAcqOrTP, chunk, fifoPos, deviceID

	STRUCT TPAnalysisInput tpInput
	variable i, j
	variable tpChannels, numADCs, numDACs, tpLengthPointsADC, tpStart, tpEnd, tpStartPos
	variable TPChanIndex, saveTP, clampAmp
	variable headstage, fifoLatest, channelIndex
	string hsList

	variable hardwareType = GetHardwareType(device)
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
				fifopos = SCOPE_ITC_AdjustFIFOPos(device, fifopos)
				ASSERT(IsFinite(fifopos), "Invalid fifo position")
			endif
			SCOPE_ITC_UpdateOscilloscope(device, dataAcqOrTP, chunk, fifoPos)
			break
		case HARDWARE_NI_DAC:
			ASSERT(!ParamIsDefault(deviceID), "optional parameter deviceID missing (required for NI devices in TP mode)")
			SCOPE_NI_UpdateOscilloscope(device, dataAcqOrTP, deviceID, fifoPos)
			break
		case HARDWARE_SUTTER_DAC:
			if(dataAcqOrTP == TEST_PULSE_MODE)
				ASSERT(!ParamIsDefault(chunk), "optional parameter chunk is missing with TEST_PULSE_MODE")
				ASSERT(ParamIsDefault(fifoPos), "optional parameter fifoPos is not possible with TEST_PULSE_MODE")
			elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)
				ASSERT(!ParamIsDefault(fifoPos), "optional parameter fifoPos missing")
				ASSERT(ParamIsDefault(chunk), "optional parameter chunk is not possible with DATA_ACQUISITION_MODE")
			endif
			SCOPE_SU_UpdateOscilloscope(device, dataAcqOrTP, chunk, fifoPos)
			break
		default:
			ASSERT(0, "Unsupported hardware type")
	endswitch

	WAVE config  = GetDAQConfigWave(device)
	WAVE ADCmode = GetADCTypesFromConfig(config)
	tpChannels = GetNrOfTypedChannels(ADCmode, DAQ_CHANNEL_TYPE_TP)

	// send data to TP Analysis if TP present
	NVAR fifoPosGlobal = $GetFifoPosition(device)

	if(tpChannels)
		saveTP = DAG_GetNumericalValue(device, "check_Settings_TP_SaveTP")
		WAVE TPSettings     = GetTPSettings(device)
		WAVE TPSettingsCalc = GetTPSettingsCalculated(device)

		tpLengthPointsADC = (dataAcqOrTP == TEST_PULSE_MODE) ? TPSettingsCalc[%totalLengthPointsTP_ADC] : TPSettingsCalc[%totalLengthPointsDAQ_ADC]

		// use a 'virtual' end position for fifoLatest for TP Mode since the input data contains one TP only
		fifoLatest = (dataAcqOrTP == TEST_PULSE_MODE) ? tpLengthPointsADC : fifoPos

		WAVE ADCs   = GetADCListFromConfig(config)
		WAVE DACs   = GetDACListFromConfig(config)
		WAVE hsProp = GetHSProperties(device)

		WAVE/WAVE scaledDataWave = GetScaledDataWave(device)
		numDACs = DimSize(DACs, ROWS)
		numADCs = DimSize(ADCs, ROWS)

		// note: currently this works for multiplier = 1 only, see DC_PlaceDataInDAQDataWave
		Make/FREE/N=(tpLengthPointsADC) channelData
		WAVE tpInput.data = channelData

		tpInput.device               = device
		tpInput.tpLengthPointsADC    = tpLengthPointsADC
		tpInput.pulseLengthPointsADC = (dataAcqOrTP == TEST_PULSE_MODE) ? TPSettingsCalc[%pulseLengthPointsTP_ADC] : TPSettingsCalc[%pulseLengthPointsDAQ_ADC]
		tpInput.pulseStartPointsADC  = (dataAcqOrTP == TEST_PULSE_MODE) ? TPSettingsCalc[%pulseStartPointsTP_ADC] : TPSettingsCalc[%pulseStartPointsDAQ_ADC]
		tpInput.samplingIntervalADC  = DimDelta(scaledDataWave[numDACs], ROWS)
		tpInput.tpLengthPointsDAC    = (dataAcqOrTP == TEST_PULSE_MODE) ? TPSettingsCalc[%totalLengthPointsTP] : TPSettingsCalc[%totalLengthPointsDAQ]
		tpInput.pulseLengthPointsDAC = (dataAcqOrTP == TEST_PULSE_MODE) ? TPSettingsCalc[%pulseLengthPointsTP] : TPSettingsCalc[%pulseLengthPointsDAQ]
		tpInput.pulseStartPointsDAC  = (dataAcqOrTP == TEST_PULSE_MODE) ? TPSettingsCalc[%pulseStartPointsTP] : TPSettingsCalc[%pulseStartPointsDAQ]
		tpInput.samplingIntervalDAC  = DimDelta(scaledDataWave[0], ROWS)
		tpInput.baselineFrac         = TPSettingsCalc[%baselineFrac]
		tpInput.readTimeStamp        = ticks * TICKS_TO_SECONDS
		tpInput.activeADCs           = tpChannels
		tpInput.cycleId              = ROVAR(GetTestpulseCycleID(device))

		tpStart = trunc(fifoPosGlobal / tpLengthPointsADC)
		tpEnd   = trunc(fifoLatest / tpLengthPointsADC)
		ASSERT(tpStart <= tpEnd, "New fifopos is smaller than previous fifopos")
		Make/FREE/D/N=(tpEnd - tpStart) tpMarker
		NewRandomSeed()
		tpMarker[] = GetUniqueInteger()

		DEBUGPRINT("tpChannels: ", var = tpChannels)
		DEBUGPRINT("tpLength: ", var = tpLengthPointsADC)

		for(i = tpStart; i < tpEnd; i += 1)

			tpInput.measurementMarker = tpMarker[i - tpStart]
			tpStartPos                = i * tpLengthPointsADC

			if(saveTP)
				Make/FREE/N=(tpLengthPointsADC, tpChannels) StoreTPWave
				for(j = 0; j < tpChannels; j += 1)
					WAVE scaledChannel = scaledDataWave[numDACs + j]
					Multithread StoreTPWave[][j] = scaledChannel[tpStartPos + p]
				endfor
				CopyScales/P scaledChannel, StoreTPWave
				TPChanIndex = 0
				hsList      = ""
			endif

			// Use same time for all headstages
			tpInput.timeStamp    = DateTime
			tpInput.timeStampUTC = DateTimeInUTC()

			for(j = 0; j < numADCs; j += 1)
				if(ADCmode[j] == DAQ_CHANNEL_TYPE_TP)

					WAVE scaledChannel = scaledDataWave[numDACs + j]
					MultiThread channelData[] = scaledChannel[tpStartPos + p]
					CopyScales/P scaledChannel, channelData

					headstage = AFH_GetHeadstageFromADC(device, ADCs[j])
					if(hsProp[headstage][%ClampMode] == I_CLAMP_MODE)
						clampAmp = TPSettings[%amplitudeIC][headstage]
					else
						clampAmp = TPSettings[%amplitudeVC][headstage]
					endif
					tpInput.clampAmp  = clampAmp
					tpInput.clampMode = hsProp[headstage][%ClampMode]
					tpInput.hsIndex   = headstage

					DEBUGPRINT("headstage: ", var = headstage)
					DEBUGPRINT("channel: ", var = numDACs + j)

					TP_SendToAnalysis(device, tpInput)

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
				TP_StoreTP(device, StoreTPWave, tpInput.measurementMarker, hsList)
				WaveClear StoreTPWave
			endif

		endfor

		if(dataAcqOrTP == DATA_ACQUISITION_MODE && tpEnd > tpStart)
			tpStartPos = (tpEnd - 1) * tpLengthPointsADC
			if(DAG_GetNumericalValue(device, "check_settings_show_power"))
				WAVE tpOsciForPowerSpectrum = GetScaledTPTempWave(device)
				Make/FREE/D/N=(numADCs) tpColumns
				j = 0
				for(i = 0; i < numADCs; i += 1)
					if(ADCmode[i] == DAQ_CHANNEL_TYPE_TP)
						channelIndex = numDACs + i
						WAVE scaledChannel = scaledDataWave[channelIndex]
						MultiThread tpOsciForPowerSpectrum[][channelIndex] = scaledChannel[tpStartPos + p]
						tpColumns[j] = channelIndex
						j           += 1
					endif
					CopyScales/P scaledChannel, tpOsciForPowerSpectrum
				endfor
				Redimension/N=(j) tpColumns
				SCOPE_UpdatePowerSpectrum(device, tpColumns, osci = tpOsciForPowerSpectrum)
			else
				WAVE TPOscilloscopeData = GetTPOscilloscopeWave(device)
				for(i = 0; i < numADCs; i += 1)
					if(ADCmode[i] == DAQ_CHANNEL_TYPE_TP)
						channelIndex = numDACs + i
						WAVE scaledChannel = scaledDataWave[channelIndex]
						MultiThread TPOscilloscopeData[][channelIndex] = scaledChannel[tpStartPos + p]
					endif
				endfor
			endif
		endif
	endif

	// Sync fifo position
	fifoPosGlobal = fifoPos

	ASYNC_ThreadReadOut()
End

static Function SCOPE_SU_UpdateOscilloscope(string device, variable dataAcqOrTP, variable chunk, variable fifoPos)

	variable i, decMethod, decFactor, gain, numCols, lastRow
	variable startOfADColumns, endOfADColumns, first, last, length
	string msg

	WAVE/WAVE scaledDataWave   = GetScaledDataWave(device)
	WAVE      OscilloscopeData = GetOscilloscopeWave(device)
	WAVE/WAVE SUDataWave       = GetDAQDataWave(device, dataAcqOrTP)
	WAVE      config           = GetDAQConfigWave(device)
	WAVE      ADCs             = GetADCListFromConfig(config)
	WAVE      DACs             = GetDACListFromConfig(config)
	startOfADColumns = DimSize(DACs, ROWS)
	endOfADColumns   = startOfADColumns + DimSize(ADCs, ROWS)

	if(dataAcqOrTP == TEST_PULSE_MODE)
		WAVE TPSettingsCalc = GetTPSettingsCalculated(device)
		length = TPSettingsCalc[%totalLengthPointsTP_ADC]
		first  = chunk * length
		last   = first + length - 1

		ASSERT(first >= 0 && first < last, "Invalid wave subrange")
		// update a full pulse
		for(i = startOfADColumns; i < endOfADColumns; i += 1)
			WAVE SUChannel     = SUDataWave[i]
			WAVE scaledChannel = scaledDataWave[i]
			ASSERT(last < DimSize(SUChannel, ROWS), "Invalid wave subrange")

			Multithread OscilloscopeData[][i] = SUChannel[first + p]
			Multithread scaledChannel[] = SUChannel[first + p]
		endfor
		Make/FREE/N=(DimSize(ADCs, ROWS)) tpColumns
		tpColumns[] = startOfADColumns + p
		SCOPE_UpdatePowerSpectrum(device, tpColumns)
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)

		if(fifoPos == 0)
			return NaN
		endif

		NVAR fifoPosGlobal = $GetFifoPosition(device)

		for(i = startOfADColumns; i < endOfADColumns; i += 1)
			WAVE SUChannel     = SUDataWave[i]
			WAVE scaledChannel = scaledDataWave[i]

			AssertOnAndClearRTError()
			try
				Multithread scaledChannel[fifoPosGlobal, fifoPos - 1] = SUChannel[p]; AbortOnRTE
			catch
				sprintf msg, "Writing scaledDataWave failed, please save the experiment and file a bug report: scaledDataWave rows %g\r", DimSize(scaledDataWave, ROWS)
				ASSERT(0, msg)
			endtry
		endfor

		decMethod = GetNumberFromWaveNote(OscilloscopeData, "DecimationMethod")
		decFactor = GetNumberFromWaveNote(OscilloscopeData, "DecimationFactor")

		for(i = startOfADColumns; i < endOfADColumns; i += 1)
			WAVE SUChannel = SUDataWave[i]

			switch(decMethod)
				case DECIMATION_NONE:
					Multithread OscilloscopeData[fifoPosGlobal, fifoPos - 1][i] = SUChannel[p]
					break
				default:
					DecimateWithMethod(SUChannel, OscilloscopeData, decFactor, decMethod, firstRowInp = fifoPosGlobal, lastRowInp = fifoPos - 1, firstColInp = 0, lastColInp = 0, firstColOut = i, lastColOut = i)
					break
			endswitch
		endfor
	endif
End

static Function SCOPE_NI_UpdateOscilloscope(device, dataAcqOrTP, deviceiD, fifoPos)
	string device
	variable dataAcqOrTP, deviceID, fifoPos

	variable i, channel, decMethod, decFactor, numCols, numFifoChannels
	string fifoName, msg, fifoInfo

	WAVE/WAVE scaledDataWave   = GetScaledDataWave(device)
	WAVE      OscilloscopeData = GetOscilloscopeWave(device)
	WAVE/WAVE NIDataWave       = GetDAQDataWave(device, dataAcqOrTP)

	fifoName = GetNIFIFOName(deviceID)
	FIFOStatus/Q $fifoName
	ASSERT(V_Flag != 0, "FIFO does not exist!")
	numFifoChannels = V_FIFOnchans
	fifoInfo        = S_info
	if(dataAcqOrTP == TEST_PULSE_MODE)
		// update a full pulse
		Make/FREE/N=(numFifoChannels) tpColumns
		for(i = 0; i < numFifoChannels; i += 1)
			channel = NumberByKey("NAME" + num2istr(i), fifoInfo)
			WAVE NIChannel     = NIDataWave[channel]
			WAVE scaledChannel = scaledDataWave[channel]
			Multithread OscilloscopeData[][channel] = NIChannel[p]
			Multithread scaledChannel[] = NIChannel[p]
			tpColumns[i] = channel
		endfor
		SCOPE_UpdatePowerSpectrum(device, tpColumns)
	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)

		if(fifoPos == 0)
			return NaN
		endif

		// it is in this moment the previous fifo position, so the new data goes from here to fifoPos-1
		NVAR fifoPosGlobal = $GetFifoPosition(device)

		numCols = DimSize(scaledDataWave, COLS)
		for(i = 0; i < numFifoChannels; i += 1)
			channel = NumberByKey("NAME" + num2istr(i), fifoInfo)
			WAVE NIChannel     = NIDataWave[channel]
			WAVE scaledChannel = scaledDataWave[channel]

			AssertOnAndClearRTError()
			try
				Multithread scaledChannel[fifoPosGlobal, fifoPos - 1] = NIChannel[p]; AbortOnRTE
			catch
				sprintf msg, "Writing scaledDataWave failed, please save the experiment and file a bug report: fifoPosGlobal %g, fifoPos %g, scaledDataWave rows %g, stopCollectionPoint %g\r", fifoPosGlobal, fifoPos, DimSize(scaledDataWave, ROWS), ROVAR(GetStopCollectionPoint(device))
				ASSERT(0, msg)
			endtry
		endfor

		decMethod = GetNumberFromWaveNote(OscilloscopeData, "DecimationMethod")
		decFactor = GetNumberFromWaveNote(OscilloscopeData, "DecimationFactor")

		for(i = 0; i < numFifoChannels; i += 1)
			channel = NumberByKey("NAME" + num2str(i), fifoInfo)
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

static Function SCOPE_ITC_UpdateOscilloscope(device, dataAcqOrTP, chunk, fifoPos)
	string device
	variable dataAcqOrTP, chunk, fifoPos

	WAVE OscilloscopeData = GetOscilloscopeWave(device)
	variable length, first, last
	variable startOfADColumns, endOfADColumns, decMethod, decFactor, i
	string msg
	WAVE/WAVE scaledDataWave = GetScaledDataWave(device)
	WAVE      DAQDataWave    = GetDAQDataWave(device, dataAcqOrTP)
	WAVE      DAQConfigWave  = GetDAQConfigWave(device)
	WAVE      ADCs           = GetADCListFromConfig(DAQConfigWave)
	WAVE      DACs           = GetDACListFromConfig(DAQConfigWave)
	startOfADColumns = DimSize(DACs, ROWS)
	endOfADColumns   = startOfADColumns + DimSize(ADCs, ROWS)

	WAVE allGain = SWS_GETChannelGains(device, timing = GAIN_AFTER_DAQ)

	if(dataAcqOrTP == TEST_PULSE_MODE)
		WAVE TPSettingsCalc = GetTPSettingsCalculated(device)
		length = TPSettingsCalc[%totalLengthPointsTP_ADC]
		first  = chunk * length
		last   = first + length - 1
		ASSERT(first >= 0 && last < DimSize(DAQDataWave, ROWS) && first < last, "Invalid wave subrange")

#ifdef DEBUGGING_ENABLED
		if(DP_DebuggingEnabledForCaller())

			DAQDataWave[0][0] += 0
			if(!WindowExists("DAQDataWaveTPMD"))
				Display/N=DAQDataWaveTPMD DAQDataWave[][1]
			endif

			Cursor/W=DAQDataWaveTPMD/H=2/P A, $NameOfWave(DAQDataWave), first
			Cursor/W=DAQDataWaveTPMD/H=2/P B, $NameOfWave(DAQDataWave), last
		endif
#endif

		Multithread OscilloscopeData[][startOfADColumns, endOfADColumns - 1] = DAQDataWave[first + p][q] / allGain[q]
		for(i = startOfADColumns; i < endOfADColumns; i += 1)
			WAVE scaledChannel = scaledDataWave[i]
			Multithread scaledChannel[] = OscilloscopeData[p][i]
		endfor

		Make/FREE/N=(DimSize(ADCs, ROWS)) tpColumns
		tpColumns[] = startOfADColumns + p
		SCOPE_UpdatePowerSpectrum(device, tpColumns)

	elseif(dataAcqOrTP == DATA_ACQUISITION_MODE)

		if(fifopos <= 0)
			return NaN
		endif

		NVAR fifoPosGlobal = $GetFifoPosition(device)

		if(fifoPosGlobal == fifoPos)
			return NaN
		endif

		AssertOnAndClearRTError()
		try
			for(i = startOfADColumns; i < endOfADColumns; i += 1)
				WAVE scaledChannel = scaledDataWave[i]
				Multithread scaledChannel[fifoPosGlobal, fifoPos - 1] = DAQDataWave[p][i] / allGain[i]; AbortOnRTE
			endfor
		catch
			sprintf msg, "Writing scaledDataWave failed, please save the experiment and file a bug report: fifoPosGlobal %g, fifoPos %g, Channel Index %d, scaledChannelWave rows %g, stopCollectionPoint %g\r", fifoPosGlobal, fifoPos, i, DimSize(scaledChannel, ROWS), ROVAR(GetStopCollectionPoint(device))
			ASSERT(0, msg)
		endtry

		decMethod = GetNumberFromWaveNote(OscilloscopeData, "DecimationMethod")
		decFactor = GetNumberFromWaveNote(OscilloscopeData, "DecimationFactor")

		switch(decMethod)
			case DECIMATION_NONE:
				Multithread OscilloscopeData[fifoPosGlobal, fifoPos - 1][startOfADColumns, endOfADColumns - 1] = DAQDataWave[p][q] / allGain[q]
				break
			default:
				Duplicate/FREE/RMD=[startOfADColumns, endOfADColumns - 1] allGain, gain
				gain[] = 1 / gain[p]
				DecimateWithMethod(DAQDataWave, OscilloscopeData, decFactor, decMethod, firstRowInp = fifoPosGlobal, lastRowInp = fifoPos - 1, firstColInp = startOfADColumns, lastColInp = endOfADColumns - 1, factor = gain)
		endswitch
	else
		ASSERT(0, "Invalid dataAcqOrTP value")
	endif
End

/// @brief Adjusts the fifo position when using ITC
///
/// @param device device
/// @param fifopos    fifo position
///
/// @return adjusted fifo position
static Function SCOPE_ITC_AdjustFIFOPos(device, fifopos)
	string   device
	variable fifopos

	variable stopCollectionPoint

	WAVE DAQConfigWave = GetDAQConfigWave(device)
	fifopos += GetDataOffset(DAQConfigWave)

	if(fifoPos == 0)
		return 0
	elseif(IsNaN(fifoPos))
		// we are done
		// return the total length we wanted to acquire
		stopCollectionPoint = ROVAR(GetStopCollectionPoint(device))
		fifoPos             = stopCollectionPoint
	elseif(fifoPos < 0)
		printf "fifoPos was clipped to zero, old value %g\r", fifoPos
		return 0
	endif

	WAVE/WAVE scaledDataWave = GetScaledDataWave(device)
	WAVE      channel        = scaledDataWave[0]

	return min(fifoPos, DimSize(channel, ROWS))
End
