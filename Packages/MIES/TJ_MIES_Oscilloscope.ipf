#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static Constant SCOPE_TIMEAXIS_RESISTANCE_RANGE = 120
static Constant SCOPE_GREEN                     = 26122
static Constant SCOPE_BLUE                      = 39168
static StrConstant TAG_FORMAT_STR               = "\\[1\\K(%d, %d, %d)R\\B%s\\M(\\Z10M\\F'Symbol'W\\M)\\]1\K(0, 0, 0) = \\{\"%%.01#f\", TagVal(2)}"

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

	NewPanel/EXT=0/W=(0,0,434,784)/HOST=$panelTitle/N=Scope/K=2
	Display/W=(0,10,358,776)/HOST=$win/N=oscilloscope/FG=(FL,FT,FR,FB)
	ModifyPanel/W=$win fixedSize=0
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

	variable latest
	string graph

	graph = SCOPE_GetGraph(panelTitle)

	GetAxis/W=$graph/Q top
	if(!V_flag) // axis exists in graph
		Wave TPStorage = GetTPStorage(panelTitle)
		variable count = GetNumberFromWaveNote(TPStorage, TP_CYLCE_COUNT_KEY)
		latest = count > 0 ? TPStorage[count - 1][0][%DeltaTimeInSeconds] : 0

		if(latest >= V_max)
			SetAxis/W=$graph top, latest -  0.5 * SCOPE_TIMEAXIS_RESISTANCE_RANGE, latest + 0.5 * SCOPE_TIMEAXIS_RESISTANCE_RANGE
		endif
	endif

	ModifyGraph/W=$graph live = 0
	ModifyGraph/W=$graph live = 1
End

Function SCOPE_CreateGraph(plotData, panelTitle)
	wave plotData
	string panelTitle

	string dataName, graph, tagName
	variable i, adc, showResistanceCurve, numActiveDACs, numADChannels
	string leftAxis, rightAxis, tagAxis, ADChannelList, str
	string tagPeakTrace, tagSteadyStateTrace
	string unitWaveNote, unit, steadyStateTrace, peakTrace, adcStr, anchor
	variable YaxisLow, YaxisHigh, YaxisSpacing, Yoffset, xPos, yPos
	STRUCT RGBColor peakColor
	STRUCT RGBColor steadyColor

	SCOPE_OpenScopeWindow(panelTitle)
	graph = SCOPE_GetGraph(panelTitle)

	DFREF testPulseDFR = GetDeviceTestPulse(panelTitle)
	DFREF dataDFR      = GetDevicePath(panelTitle)
	WAVE/SDFR=dataDFR ITCChanConfigWave
	WAVE/SDFR=testPulseDFR SSResistance
	WAVE/SDFR=testPulseDFR InstResistance
	Wave TPStorage = GetTPStorage(panelTitle)

	dataName = NameOfWave(plotData)
	ADChannelList = ITC_GetADCList(ITCChanConfigWave)
	unitWaveNote = note(ITCChanConfigWave)
	graph = SCOPE_GetGraph(panelTitle)
	numADChannels = ItemsInList(ADChannelList)
	Yoffset = 40 / numADChannels
	YaxisSpacing = 1 / numADChannels
	YaxisHigh = 1
	YaxisLow = YaxisHigh - YaxisSpacing + 0.025
	peakColor.green = SCOPE_GREEN
	steadyColor.blue = SCOPE_BLUE

	RemoveTracesFromGraph(graph)
	RemoveAnnotationsFromGraph(graph)

	numActiveDACs = ItemsInList(ITC_GetDACList(ITCChanConfigWave))
	showResistanceCurve = GetCheckboxState(panelTitle, "check_settings_TP_show_resist")

	for(i = 0; i < numADChannels; i += 1)
		adcStr = StringFromList(i, ADChannelList)
		adc = str2num(adcStr)
		leftAxis = "AD" + adcStr
		AppendToGraph/W=$graph/L=$leftAxis plotData[][numActiveDACs + i]

		ModifyGraph/W=$graph axisEnab($leftAxis) = {YaxisLow, YaxisHigh}, freepos($leftAxis) = {0, kwFraction}
		SetAxis/W=$graph/A=2/N=2 $leftAxis

		// extracts unit from string list that contains units in same sequence as columns in the ITCDatawave
		unit = StringFromList(numActiveDACs + i, unitWaveNote)
		Label/W=$graph $leftAxis, leftAxis + " (" + unit + ")"

		// handles plotting of peak and steady state resistance curves in the oscilloscope window with the TP
		// add the also the trace for the current resistance values from the test pulse
		if(!cmpstr(dataName, "TestPulseITC"))

			rightAxis = "resistance" + adcStr

			peakTrace = "PeakResistance" + adcStr
			AppendToGraph/W=$graph/R=$rightAxis/T=top TPStorage[][i][%PeakResistance]/TN=$peakTrace
			ModifyGraph/W=$graph lstyle($peakTrace)=1, rgb($peakTrace)=(peakColor.red, peakColor.green, peakColor.blue)

			steadyStateTrace = "SteadyStateResistance" + adcStr
			AppendToGraph/W=$graph/R=$rightAxis/T=top TPStorage[][i][%SteadyStateResistance]/TN=$steadyStateTrace
			ModifyGraph/W=$graph lstyle($steadyStateTrace)=1, rgb($steadyStateTrace)=(steadyColor.red, steadyColor.green, steadyColor.blue)

			ModifyGraph/W=$graph axisEnab($rightAxis) = {YaxisLow, YaxisLow + (YaxisHigh - YaxisLow) * 0.2}, freePos($rightAxis)={0, kwFraction}
			ModifyGraph/W=$graph lblPos($rightAxis) = 70, lblRot($rightAxis) = 180


			tagAxis = rightAxis + "_tags"

			tagSteadyStateTrace = "SSR" + adcStr
			AppendToGraph/W=$graph/R=$tagAxis SSResistance[][i]/TN=$tagSteadyStateTrace
			ModifyGraph/W=$graph mode($tagSteadyStateTrace) = 2, lsize($tagSteadyStateTrace) = 0

			if(showResistanceCurve)
				xPos = 50
				yPos = 5
				anchor = "RB"
			else
				XPos = 0
				yPos = -yOffset
				anchor = "MC"
			endif

			tagName = "SSR" + adcStr
			sprintf str, TAG_FORMAT_STR, steadyColor.red, steadyColor.green, steadyColor.blue, "ss"
			Tag/W=$graph/C/N=$tagName/F=0/B=1/A=$anchor/X=(xPos)/Y=(yPos)/L=0/I=1 $tagSteadyStateTrace, 0, str

			tagPeakTrace = "InstR" + adcStr
			AppendToGraph/W=$graph/R=$tagAxis InstResistance[][i]/TN=$tagPeakTrace
			ModifyGraph/W=$graph mode($tagPeakTrace) = 2, lsize($tagPeakTrace) = 0

			if(showResistanceCurve)
				xPos = 100
				yPos = 3
				anchor = "RB"
			else
				xPos = -15
				yPos = -yOffset
				anchor = "LT"
			endif

			tagName = "InstR" + adcStr
			sprintf str, TAG_FORMAT_STR, peakColor.red, peakColor.green, peakColor.blue, "peak"
			Tag/W=$graph/C/N=$tagName/F=0/B=1/A=$anchor/X=(xPos)/Y=(yPos)/L=0/I=1 $tagPeakTrace, 0, str

			ModifyGraph/W=$graph noLabel($tagAxis) = 2, axThick($tagAxis) = 0, width = 25
			ModifyGraph/W=$graph axisEnab($tagAxis) = {YaxisLow, YaxisHigh}, freePos($tagAxis)={1, kwFraction}

			SetAxis/W=$graph/A=2/N=2/E=2 $tagAxis -20000000, 20000000


			if(showResistanceCurve)
				Label/W=$graph $rightAxis "Resistance \\Z10(M\\F'Symbol'W\\M)"
				Label/W=$graph top "Relative time (s)"
				SetAxis/W=$graph top, 0, SCOPE_TIMEAXIS_RESISTANCE_RANGE
			else
				ModifyGraph/W=$graph lsize($peakTrace) = 0, lsize($steadyStateTrace) = 0
				ModifyGraph/W=$graph noLabel($rightAxis) = 2, noLabel(top) = 2
				ModifyGraph/W=$graph axThick($rightAxis) = 0, axThick(top) = 0
			endif
		endif

		YaxisHigh -= YaxisSpacing
		YaxisLow -= YaxisSpacing
	endfor

	Label/W=$graph bottom "Time (\\U)"

	if(!cmpstr(dataName, "TestPulseITC"))
		NVAR/SDFR=testPulseDFR Duration
		SetAxis/W=$graph bottom 0, Duration * (DC_ITCMinSamplingInterval(panelTitle) / 1000) * 2 // use for MD TP plotting
	else
		SetAxis/W=$graph bottom 0, (ITC_CalcDataAcqStopCollPoint(panelTitle)) * (DC_ITCMinSamplingInterval(panelTitle) / 1000)
	endif
End
