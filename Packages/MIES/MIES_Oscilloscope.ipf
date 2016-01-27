#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_Oscilloscope.ipf
/// @brief __SCOPE__ Scope window handling for data acquisition and testpulse results

static Constant SCOPE_TIMEAXIS_RESISTANCE_RANGE = 120
static Constant SCOPE_GREEN                     = 26122
static Constant SCOPE_BLUE                      = 39168
static StrConstant TAG_FORMAT_STR               = "\\[1\\K(%d, %d, %d)\\{\"%%.01#f\", TagVal(2)}\\]1\K(0, 0, 0)"

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

	NewPanel/EXT=0/W=(0,0,460,784)/HOST=$panelTitle/N=Scope/K=2
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

	variable latest, count, i, numADCs, minVal, maxVal, range
	variable relTimeAxisMin, relTimeAxisMax, showSteadyStateResistance, showPeakResistance
	string graph, rightAxis, info

	GetResistanceCheckBoxes(panelTitle, showSteadyStateResistance, showPeakResistance)
	graph = SCOPE_GetGraph(panelTitle)
	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)

	GetAxis/W=$graph/Q top
	if(!V_flag) // axis exists in graph
		Wave TPStorage = GetTPStorage(panelTitle)
		count  = GetNumberFromWaveNote(TPStorage, TP_CYLCE_COUNT_KEY)
		latest = DimOffset(TPStorage, ROWS) + count * DimDelta(TPStorage, ROWS)
		relTimeAxisMin = latest - 0.5 * SCOPE_TIMEAXIS_RESISTANCE_RANGE
		relTimeAxisMax = latest + 0.5 * SCOPE_TIMEAXIS_RESISTANCE_RANGE

		if(latest >= V_max)
			SetAxis/W=$graph top, relTimeAxisMin, relTimeAxisMax
		endif

		WAVE ADCs = GetADCListFromConfig(ITCChanConfigWave)
		numADCs = DimSize(ADCs, ROWS)

		for(i = 0; i < numADCs; i += 1)

			rightAxis = "resistance" + num2str(ADCs[i])

			info = AxisInfo(graph, rightAxis)

			if(isEmpty(info))
				continue
			endif

			minVal = +Inf
			maxVal = -Inf

			/// @todo switch to WaveStats/RMD once IP7 is mandatory

			if(showPeakResistance)
				Duplicate/FREE/R=(relTimeAxisMin, relTimeAxisMax)[i][1] TPStorage, peak
				WaveStats/M=1/Q peak
				minVal = min(V_min, minVal)
				maxVal = max(V_max, maxVal)
			endif

			if(showSteadyStateResistance)
				Duplicate/FREE/R=(relTimeAxisMin, relTimeAxisMax)[i][2] TPStorage, steady
				WaveStats/M=1/Q steady
				minVal = min(V_min, minVal)
				maxVal = max(V_max, maxVal)
			endif

			range = maxVal - minVal

			if(!IsFinite(range) || range == 0)
				continue
			endif

			minVal = minVal + 0.02 * range
			range *= 0.98

			ModifyGraph/W=$graph manTick($rightAxis)={minVal,range,0,1}
			ModifyGraph/W=$graph manMinor($rightAxis)={3,0}
		endfor
	endif

	ModifyGraph/W=$graph live = 0
	ModifyGraph/W=$graph live = 1
End

static Function GetResistanceCheckBoxes(panelTitle, showSteadyStateResistance, showPeakResistance)
	string panelTitle
	variable &showSteadyStateResistance, &showPeakResistance

	variable showResistanceCurve = GetCheckboxState(panelTitle, "check_settings_TP_show_resist", allowMissingControl=1)

	if(IsFinite(showResistanceCurve)) // control from old panel
		showPeakResistance        = showResistanceCurve
		showSteadyStateResistance = showResistanceCurve
	else // old control does not exist ->  new panel
		showPeakResistance        = GetCheckboxState(panelTitle, "check_settings_TP_show_peak")
		showSteadyStateResistance = GetCheckboxState(panelTitle, "check_settings_TP_show_steady")
	endif
End

Function SCOPE_CreateGraph(panelTitle, dataAcqOrTP)
	string panelTitle
	variable dataAcqOrTP

	string graph, tagName
	variable i, adc, numActiveDACs, numADChannels, oneTimeInitDone
	variable showSteadyStateResistance, showPeakResistance
	string leftAxis, rightAxis, tagAxis, str
	string tagPeakTrace, tagSteadyStateTrace
	string unitWaveNote, unit, steadyStateTrace, peakTrace, adcStr, anchor
	variable YaxisLow, YaxisHigh, YaxisSpacing, Yoffset, xPos, yPos
	variable testPulseLength, cutOff, sampInt
	STRUCT RGBColor peakColor
	STRUCT RGBColor steadyColor

	SCOPE_OpenScopeWindow(panelTitle)
	graph = SCOPE_GetGraph(panelTitle)

	WAVE ITCChanConfigWave = GetITCChanConfigWave(panelTitle)
	WAVE SSResistance      = GetSSResistanceWave(panelTitle)
	WAVE InstResistance    = GetInstResistanceWave(panelTitle)
	Wave TPStorage         = GetTPStorage(panelTitle)
	WAVE OscilloscopeData  = GetOscilloscopeWave(panelTitle)

	WAVE ADCs = GetADCListFromConfig(ITCChanConfigWave)
	numADChannels = DimSize(ADCs, ROWS)
	numActiveDACs = DimSize(GetDACListFromConfig(ITCChanConfigWave), ROWS)
	unitWaveNote = note(ITCChanConfigWave)
	graph = SCOPE_GetGraph(panelTitle)
	Yoffset = 40 / numADChannels
	YaxisSpacing = 1 / numADChannels
	YaxisHigh = 1
	YaxisLow = YaxisHigh - YaxisSpacing + 0.025
	peakColor.green = SCOPE_GREEN
	steadyColor.blue = SCOPE_BLUE

	RemoveTracesFromGraph(graph)
	RemoveAnnotationsFromGraph(graph)

	GetResistanceCheckBoxes(panelTitle, showSteadyStateResistance, showPeakResistance)

	for(i = 0; i < numADChannels; i += 1)
		adc    = ADCs[i]
		adcStr = num2str(adc)
		leftAxis = "AD" + adcStr
		AppendToGraph/W=$graph/L=$leftAxis OscilloscopeData[][numActiveDACs + i]

		ModifyGraph/W=$graph axisEnab($leftAxis) = {YaxisLow, YaxisHigh}, freepos($leftAxis) = {0, kwFraction}
		SetAxis/W=$graph/A=2/N=2 $leftAxis

		// extracts unit from string list that contains units in same sequence as columns in the ITCDatawave
		unit = StringFromList(numActiveDACs + i, unitWaveNote)
		Label/W=$graph $leftAxis, leftAxis + " (" + unit + ")"
		ModifyGraph/W=$graph lblPosMode($leftAxis)=4, lblPos($leftAxis) = 50

		// handles plotting of peak and steady state resistance curves in the oscilloscope window with the TP
		// add the also the trace for the current resistance values from the test pulse
		if(dataAcqOrTP == TEST_PULSE_MODE)

			rightAxis = "resistance" + adcStr

			if(showPeakResistance)
				peakTrace = "PeakResistance" + adcStr
				AppendToGraph/W=$graph/R=$rightAxis/T=top TPStorage[][i][%PeakResistance]/TN=$peakTrace
				ModifyGraph/W=$graph lstyle($peakTrace)=1, rgb($peakTrace)=(peakColor.red, peakColor.green, peakColor.blue)
			endif

			if(showSteadyStateResistance)
				steadyStateTrace = "SteadyStateResistance" + adcStr
				AppendToGraph/W=$graph/R=$rightAxis/T=top TPStorage[][i][%SteadyStateResistance]/TN=$steadyStateTrace
				ModifyGraph/W=$graph lstyle($steadyStateTrace)=1, rgb($steadyStateTrace)=(steadyColor.red, steadyColor.green, steadyColor.blue)
			endif

			if(showPeakResistance ||showSteadyStateResistance)
				ModifyGraph/W=$graph axisEnab($rightAxis) = {YaxisLow, YaxisLow + (YaxisHigh - YaxisLow) * 0.3}, freePos($rightAxis)={0, kwFraction}
				ModifyGraph/W=$graph lblPosMode($rightAxis) = 4, lblPos($rightAxis) = 60, lblRot($rightAxis) = 180
				ModifyGraph/W=$graph nticks($rightAxis) = 2, tickUnit(top)=1
				Label/W=$graph $rightAxis "(M" + GetSymbolOhm() + ")"

				if(!oneTimeInitDone)
					sprintf str, "\\[1\\K(%d, %d, %d)R\\Bss\\M(M%s)\\]1\\K(%d, %d,%d)\r\\[1\\K(0, 26122, 0)R\\Bpeak\\M(M%s)\\]1\\K(0, 0, 0)", steadyColor.red, steadyColor.green, steadyColor.blue, GetSymbolOhm(), peakColor.red, peakColor.green, peakColor.blue, GetSymbolOhm()
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

	Label/W=$graph bottom "Time (\\U)"

	if(dataAcqOrTP == TEST_PULSE_MODE)
		sampInt = DAP_GetITCSampInt(panelTitle, TEST_PULSE_MODE) / 1000
		testPulseLength = TP_GetTestPulseLengthInPoints(panelTitle) * sampInt
		NVAR duration = $GetTestpulseDuration(panelTitle)
		NVAR baselineFrac = $GetTestpulseBaselineFraction(panelTitle)
		cutOff = max(0, baseLineFrac * testPulseLength - duration/2 * sampInt)
		SetAxis/W=$graph bottom cutOff, testPulseLength - cutOff
	else
		NVAR stopCollectionPoint = $GetStopCollectionPoint(panelTitle)
		sampInt = DAP_GetITCSampInt(panelTitle, DATA_ACQUISITION_MODE) / 1000
		SetAxis/W=$graph bottom 0, stopCollectionPoint * sampInt
	endif
End
