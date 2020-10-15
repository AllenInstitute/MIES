
#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_PA
#endif

/// @file MIES_PulseAveraging.ipf
///
/// @brief __PA__ Routines for dealing with pulse averaging.
///
///
/// - Averaging is done for all pulses in a set
/// - Zeroing is done for all pulses
/// - Deconvolution is done for the average wave only
/// - See also PA_AutomaticTimeAlignment
///
/// Drawing layers:
/// - ProgAxes: X=0 line for images
/// - ProgFront: Scale bars
/// - ProgBack: Failed pulses triangles
/// @{
static StrConstant PA_DRAWLAYER_XZEROLINE = "ProgAxes"
static StrConstant PA_DRAWLAYER_SCALEBAR = "ProgFront"
static StrConstant PA_DRAWLAYER_FAILED_PULSES = "ProgBack"
/// @}

static StrConstant PA_GRAPH_PREFIX          = "PulseAverage"
static StrConstant PA_SOURCE_WAVE_TIMESTAMP = "SOURCE_WAVE_TS"

static StrConstant PA_AVERAGE_WAVE_PREFIX       = "average_"
static StrConstant PA_DECONVOLUTION_WAVE_PREFIX = "deconv_"

static StrConstant PA_SETTINGS = "PulseAverageSettings"

/// Only present for diagonal pulses
static StrConstant PA_NOTE_KEY_PULSE_FAILED = "PulseHasFailed"

static StrConstant PA_NOTE_KEY_IMAGE_COL_OFFSET = "SinglePulseColumnOffset"

static Constant PA_USE_WAVE_SCALES = 0x01
static Constant PA_USE_AXIS_SCALES = 0x02

static Constant PA_X_AXIS_OFFSET = 0.01

static Constant PA_PLOT_STEPPING = 16

static Constant PA_DISPLAYMODE_TRACES = 0x01
static Constant PA_DISPLAYMODE_IMAGES = 0x02
static Constant PA_DISPLAYMODE_ALL    = 0xFF

static Constant PA_COLORSCALE_PANEL_WIDTH = 150

/// @name Pulse sort order
/// Popupmenu indizes for the PA plot controls
/// @{
static Constant PA_PULSE_SORTING_ORDER_SWEEP = 0x0
static Constant PA_PULSE_SORTING_ORDER_PULSE = 0x1
/// @}
///

static Constant PA_AVGERAGE_PLOT_LSIZE = 1.5
static Constant PA_DECONVOLUTION_PLOT_LSIZE = 2

// comment out to show all the axes, useful for debugging
#define PA_HIDE_AXIS

/// @brief Return a list of all graphs
static Function/S PA_GetGraphs(string win, variable displayMode)

	return WinList(PA_GetGraphPrefix(GetMainWindow(win), displayMode) + "*", ";", "WIN:1")
End

static Function/S PA_GetGraphName(string win, STRUCT PulseAverageSettings &pa, variable displayMode, variable channelNumber, variable activeRegionCount)

	string name = PA_GetGraphPrefix(win, displayMode)

	if(pa.multipleGraphs)
		return name + "_AD" + num2str(channelNumber) + "_R" + num2str(activeRegionCount)
	else
		return name
	endif
End

// @brief Return the window name prefix of all PA graphs for the given Browser window
static Function/S PA_GetGraphPrefix(string win, variable displayMode)

	switch(displayMode)
		case PA_DISPLAYMODE_TRACES:
			return GetMainWindow(win) + "_" + PA_GRAPH_PREFIX + "_traces"
		case PA_DISPLAYMODE_IMAGES:
			return GetMainWindow(win) + "_" + PA_GRAPH_PREFIX + "_images"
		case PA_DISPLAYMODE_ALL:
			return GetMainWindow(win) + "_" + PA_GRAPH_PREFIX
		default:
			ASSERT(0, "invalid display mode")
	endswitch
End

/// @brief Return the subwindow path to the panel which holds the graphs with the color scales
///
/// Only present for #PA_DISPLAYMODE_IMAGES graphs.
Function/S PA_GetColorScalePanel(string win)
	return win + "#P0"
End

/// @brief Return the subwindow path to the graph which holds the color scales
///
/// Only present for #PA_DISPLAYMODE_IMAGES graphs.
Function/S PA_GetColorScaleGraph(string win)
	return PA_GetColorScalePanel(win) + "#G0"
End

/// @brief Return the name of the pulse average graph
///
/// This function takes care of creating a graph if it does not exist, and laying it out correctly
///
/// Layout scheme for multiple graphs turned on:
/// - Positions the graphs right to `mainWin` in matrix form
/// - Columns: Regions (aka headstages with pulse starting time information respecting region selection in GUI)
/// - Rows:    Active unique channels
static Function/S PA_GetGraph(string mainWin, STRUCT PulseAverageSettings &pa, variable displayMode, variable channelNumber, variable region, variable activeRegionCount, variable activeChanCount, variable numRegions)

	variable top, left, bottom, right, i
	variable width, height, width_spacing, height_spacing, width_offset, height_offset, junk
	string win, winAbove

	win = PA_GetGraphName(mainWin, pa, displayMode, channelNumber, activeRegionCount)

	if(!WindowExists(win))

		if(pa.multipleGraphs)
			width          = 100
			height         = 80
			width_spacing  = 10
			height_spacing = 3.5
			width_offset   = (activeRegionCount - 1) * (width  + width_spacing)
			height_offset  = (activeChanCount   - 1) * (height + 2 * height_spacing)
		else
			width         = 400
			height        = 400
			width_spacing = 10
			// rest is zero already
		endif

		GetWindow $mainWin wsize
		left   = V_right + width_spacing
		top    = V_top
		right  = left + width
		bottom = top + height

		left   += width_offset
		right  += width_offset
		top    += height_offset
		bottom += height_offset
		Display/W=(left, top, right, bottom)/K=1/N=$win
		SetWindow $win, userdata($MIES_BSP_PA_MAINPANEL) = mainWin
		[junk, junk] = PA_GetTraceCountFromGraphData(win, clear = 1)
		if(displayMode == PA_DISPLAYMODE_IMAGES && (!pa.multipleGraphs || activeRegionCount == numRegions))
			SetWindow $win hook(marginResizeHook)=PA_ImageWindowHook
			NewPanel/HOST=#/EXT=0/W=(0, 0, PA_COLORSCALE_PANEL_WIDTH, bottom - top) as ""
			Display/FG=(FL,FT,FR,FB)/HOST=#
		endif

		if(pa.multipleGraphs)
			winAbove = PA_GetGraphName(mainWin, pa, displayMode, channelNumber - 1, activeRegionCount)

			for(i = channelNumber - 1; i >=0; i -= 1)
				winAbove = PA_GetGraphName(mainWin, pa, displayMode, i, activeRegionCount)

				if(WindowExists(winAbove))
					DoWindow/B=$winAbove $win
					break
				endif
			endfor
		endif
		NVAR JSONid = $GetSettingsJSONid()
		PS_InitCoordinates(JSONid, win, win)

		if(displayMode == PA_DISPLAYMODE_IMAGES)
			SetWindow $win hook(marginResizeHook)=PA_ImageWindowHook
		endif
	endif

	return win
End

/// @brief Return the names of the vertical and horizontal axes
static Function [string vertAxis, string horizAxis] PA_GetAxes(STRUCT PulseAverageSettings &pa, variable activeRegionCount, variable activeChanCount)

	if(pa.multipleGraphs)
		vertAxis  = "left"
		horizAxis = "bottom"
	else
		sprintf vertAxis,  "left_R%d_C%d", activeRegionCount, activeChanCount
		sprintf horizAxis, "bottom_R%d", activeRegionCount
	endif
End

/// @brief Derive the pulse starting times from a DA wave
///
/// Uses plain FindLevels after the onset delay using 10% of the full range
/// above the minimum as threshold
///
/// @return wave with pulse starting times, or an invalid wave reference if none could be found.
static Function/WAVE PA_CalculatePulseStartTimes(DA, fullPath, channelNumber, totalOnsetDelay)
	WAVE DA
	variable channelNumber
	string fullPath
	variable totalOnsetDelay

	variable level, delta, searchStart
	string key
	ASSERT(totalOnsetDelay >= 0, "Invalid onsetDelay")

	key = CA_PulseStartTimes(DA, fullPath, channelNumber, totalOnsetDelay)
	WAVE/Z cache = CA_TryFetchingEntryFromCache(key)
	if(WaveExists(cache))
		return cache
	endif

	WaveStats/Q/M=1/R=(totalOnsetDelay, inf) DA
	level = V_min + (V_Max - V_Min) * 0.1

	delta = DimDelta(DA, ROWS)
	if(totalOnsetDelay >= delta)
		searchStart = totalOnsetDelay - delta
	endif

	MAKE/FREE/D levels
	FindLevels/Q/R=(searchStart, inf)/EDGE=1/DEST=levels DA, level

	if(DimSize(levels, ROWS) == 0)
		return $""
	endif

	// FindLevels interpolates between two points and searches for a rising edge
	// so the returned value is commonly a bit too large
	// round to the last wave point
	levels[] = levels[p] - mod(levels[p], delta)

	CA_StoreEntryIntoCache(key, levels)
	return levels
End

/// @brief Return a wave with headstage numbers, duplicates replaced with NaN
///        so that the indizes still correspond the ones in traceData
///
///        Returns an invalid wave reference in case indizesChannelType does not exist.
static Function/WAVE PA_GetUniqueHeadstages(traceData, indizesChannelType)
	WAVE/T traceData
	WAVE/Z indizesChannelType

	if(!WaveExists(indizesChannelType))
		return $""
	endif

	Make/D/FREE/N=(DimSize(indizesChannelType, ROWS)) headstages = str2num(traceData[indizesChannelType[p]][%headstage])

	if(DimSize(headstages, ROWS) == 1)
		return headstages
	endif

	Make/FREE/D headstagesClean
	FindDuplicates/Z/SN=(NaN)/SNDS=headstagesClean headstages

	return headstagesClean
End

/// @brief Return the pulse starting times
///
/// @param traceData        2D wave with trace information, from GetTraceInfos()
/// @param idx              Index into traceData, used for determining sweep numbers, labnotebooks, etc.
/// @param region           Region (headstage) to get pulse starting times for
/// @param channelTypeStr   Type of the channel, one of @ref ITC_CHANNEL_NAMES
/// @param removeOnsetDelay [optional, defaults to true] Remove the onset delay from the starting times (true) or not (false)
Function/WAVE PA_GetPulseStartTimes(traceData, idx, region, channelTypeStr, [removeOnsetDelay])
	WAVE/T traceData
	variable idx, region
	string channelTypeStr
	variable removeOnsetDelay

	variable sweepNo, totalOnsetDelay, channel
	string str, fullPath

	if(ParamIsDefault(removeOnsetDelay))
		removeOnsetDelay = 1
	else
		removeOnsetDelay = !!removeOnsetDelay
	endif

	sweepNo = str2num(traceData[idx][%sweepNumber])

	WAVE/Z textualValues   = $traceData[idx][%textualValues]
	WAVE/Z numericalValues = $traceData[idx][%numericalValues]

	ASSERT(WaveExists(textualValues) && WaveExists(numericalValues), "Missing labnotebook waves")

	if(removeOnsetDelay)
		totalOnsetDelay = GetTotalOnsetDelay(numericalValues, sweepNo)
	endif

	WAVE/Z/T epochs = GetLastSetting(textualValues, sweepNo, EPOCHS_ENTRY_KEY, DATA_ACQUISITION_MODE)
	if(WaveExists(epochs))
		WAVE/Z pulseStartTimes = PA_RetrievePulseStartTimesFromEpochs(epochs[region])
	endif

#ifdef AUTOMATED_TESTING
	WAVE/Z DBG_pulseStartTimesEpochs = pulseStartTimes
	WAVE/Z pulseStartTimes = $""
#endif

	if(!WaveExists(pulseStartTimes))

		fullPath = traceData[idx][%fullPath]
		DFREF singleSweepFolder = GetWavesDataFolderDFR($fullPath)
		ASSERT(DataFolderExistsDFR(singleSweepFolder), "Missing singleSweepFolder")

		WAVE DACs = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)
		channel = DACs[region]
		if(IsNaN(channel))
			return $""
		endif

		WAVE DA = GetITCDataSingleColumnWave(singleSweepFolder, ITC_XOP_CHANNEL_TYPE_DAC, channel)
		WAVE/Z pulseStartTimes = PA_CalculatePulseStartTimes(DA, fullPath, channel, totalOnsetDelay)

#ifdef AUTOMATED_TESTING
		variable i
		variable warnDiffms = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval", DATA_ACQUISITION_MODE) * 2

		WAVE DBG_pulseStartTimesCalc = pulseStartTimes
		if(DimSize(DBG_pulseStartTimesEpochs, ROWS) != DimSize(DBG_pulseStartTimesCalc, ROWS))
			print/D "Warn: Pulse start time from epochs:\r", DBG_pulseStartTimesEpochs, "\r from Calculation:\r", DBG_pulseStartTimesCalc
		else
			for(i = 0; i < DimSize(DBG_pulseStartTimesEpochs, ROWS); i += 1)
				if(abs(DBG_pulseStartTimesEpochs[i] - DBG_pulseStartTimesCalc[i]) > warnDiffms)
					print/D "Warn: Pulse start time from epochs:\r", DBG_pulseStartTimesEpochs, "from Calculation:\r", DBG_pulseStartTimesCalc
					break
				endif
			endfor
		endif
#endif

		sprintf str, "Calculated pulse starting times for headstage %d", region
		DEBUGPRINT(str)

		if(!WaveExists(pulseStartTimes))
			return $""
		endif
	endif

	pulseStartTimes[] -= totalOnsetDelay

	return pulseStartTimes
End

/// @brief Extracts the pulse start times from the lab notebook and returns them as wave
/// @param[in] epochInfo epoch data to extract pulse starting times
/// @returns 1D wave with pulse starting times in [ms] or null wave
static Function/WAVE PA_RetrievePulseStartTimesFromEpochs(string epochInfo)

	variable numRawEpochs, numPulseStarts, i
	string epochStr, pulseInfo

	if(IsEmpty(epochInfo))
		return $""
	endif

	WAVE/T rawEpochs = ListToTextWave(epochInfo, ":")
	numRawEpochs = DimSize(rawEpochs, ROWS)
	Make/FREE/D/N=(numRawEpochs) pulseStartTimes
	for(i = 0; i < numRawEpochs; i += 1)
		epochStr = rawEpochs[i]

		epochInfo = StringFromList(EPOCH_COL_NAME, epochStr, ",")
		pulseInfo = StringByKey("Pulse", epochInfo, "=", ";")
		if(!IsEmpty(pulseInfo) && NumberByKey("Amplitude", epochInfo, "=", ";") > 0)
			pulseStartTimes[numPulseStarts] = str2num(StringFromList(EPOCH_COL_STARTTIME, epochStr, ";")) * 1E3
			numPulseStarts += 1
		endif
	endfor

	if(!numPulseStarts)
		return $""
	endif

	Redimension/N=(numPulseStarts) pulseStartTimes
	return pulseStartTimes
End

static Function PA_GetPulseLength(pulseStartTimes, startingPulse, endingPulse, overridePulseLength, fixedPulseLength)
	WAVE pulseStartTimes
	variable startingPulse, endingPulse, overridePulseLength, fixedPulseLength

	variable numPulses, minimum

	numPulses = DimSize(pulseStartTimes, ROWS)

	if(numPulses <= 1 || fixedPulseLength)
		return overridePulseLength
	endif

	Make/FREE/D/N=(numPulses) pulseLengths
	pulseLengths[0] = NaN
	pulseLengths[1, inf] = pulseStartTimes[p] - pulseStartTimes[p - 1]

	minimum = WaveMin(pulseLengths)

	if(minimum > 0)
		return minimum
	endif

	ASSERT(minimum == 0, "pulse length expected to be zero")

	return overridePulseLength
End

/// @brief Single pulse wave creator
///
/// The wave note is used for documenting the applied operations:
/// - `$NOTE_KEY_FAILED_PULSE_LEVEL`: Level used for failed pulse search
/// - `PulseHasFailed`: Search for failed pulses says that this pulse failed (Only present for pulses from diagonal sets)
/// - `PulseLength`: Length in points of the pulse wave (before any operations)
/// - `$NOTE_KEY_SEARCH_FAILED_PULSE`: Checkbox state of "Search failed pulses"
/// - `$NOTE_KEY_TIMEALIGN`: Time alignment was active and applied
/// - `TimeAlignmentTotalOffset`: Calculated offset from time alignment
/// - `$NOTE_KEY_ZEROED`: Zeroing was active and applied
/// - `WaveMinimum`: Minimum value of the data
/// - `WaveMaximum`: Maximum value of the data
static Function/WAVE PA_CreateAndFillPulseWaveIfReq(wv, singleSweepFolder, channelType, channelNumber, region, pulseIndex, first, length)
	WAVE/Z wv
	DFREF singleSweepFolder
	variable channelType, pulseIndex, first, length, channelNumber, region

	variable existingLength

	if(first < 0 || length <= 0 || (DimSize(wv, ROWS) - first) <= length)
		return $""
	endif

	length = limit(length, 1, DimSize(wv, ROWS) - first)

	WAVE singlePulseWave = GetPulseAverageWave(singleSweepFolder, length, channelType, channelNumber, region, pulseIndex)

	existingLength = GetNumberFromWaveNote(singlePulseWave, "PulseLength")

	if(existingLength != length)
		Redimension/N=(length) singlePulseWave
	elseif(GetNumberFromWaveNote(wv, PA_SOURCE_WAVE_TIMESTAMP) == ModDate(wv))
		return singlePulseWave
	endif

	MultiThread singlePulseWave[] = wv[first + p]
	SetScale/P x, 0.0, DimDelta(wv, ROWS), WaveUnits(wv, ROWS), singlePulseWave
	SetScale/P d, 0.0, 0.0, WaveUnits(wv, -1), singlePulseWave

	ClearWaveNoteExceptWaveVersion(singlePulseWave)

	SetNumberInWaveNote(singlePulseWave, NOTE_KEY_SEARCH_FAILED_PULSE, 0)
	SetNumberInWaveNote(singlePulseWave, NOTE_KEY_TIMEALIGN, 0)
	SetNumberInWaveNote(singlePulseWave, NOTE_KEY_ZEROED, 0)

	PA_UpdateMinAndMax(singlePulseWave)

	SetNumberInWaveNote(singlePulseWave, "PulseLength", length)

	SetNumberInWaveNote(wv, PA_SOURCE_WAVE_TIMESTAMP, ModDate(wv))

	CreateBackupWave(singlePulseWave, forceCreation = 1)

	return singlePulseWave
End

threadsafe static Function PA_UpdateMinAndMax(WAVE wv)

	variable minimum, maximum

	[minimum, maximum] = WaveMinAndMax(wv)
	SetNumberInWaveNote(wv, "WaveMinimum", minimum, format="%.15f")
	SetNumberInWaveNote(wv, "WaveMaximum", maximum, format="%.15f")
End

/// @brief Generate a key for a pulse
///
/// All pulses with that key are either failing or passing.
static Function/S PA_GenerateFailedPulseKey(variable sweep, variable region, variable pulse)
	string key

	sprintf key, "%d-%d-%d", sweep, region, pulse

	return key
End

/// @brief Create all single pulse waves
///
/// This function needs to be called when ever traces in the
/// databrowser/sweepbrowser are removed or added.
///
/// Idea:
/// - Gather all AD sweep traces in the databrowser/sweepbrowser (skipping duplicates from oodDAQ)
/// - Iterate over all regions (there are as many regions as unique headstages)
/// - Now gather the pulse starting time from the region and create single pulse waves for all of them
///
/// The result is feed into GetPulseAverageProperties() and GetPulseAveragepropertiesWaves() for further consumption.
static Function PA_GenerateAllPulseWaves(string win, STRUCT PulseAverageSettings &pa, STRUCT PA_ConstantSettings &cs, variable mode, WAVE/Z additionalData)

	variable startingPulseSett, endingPulseSett, isDiagonalElement, pulseHasFailed, newChannel
	variable i, j, k, numHeadstages, region, sweepNo, idx, numPulsesTotal, numPulses, startingPulse, endingPulse
	variable headstage, pulseToPulseLength, totalOnsetDelay, numChannelTypeTraces, totalPulseCounter, jsonID, lastSweep
	variable activeRegionCount, activeChanCount, channelNumber, first, length, dictId, channelType, numChannels, numRegions
	variable numPulseCreate, prevTotalPulseCounter, numNewSweeps, numNewIndicesSweep
	variable lblIndex, lblSweep, lblChannelType, lblChannelNumber, lblRegion, lblHeadstage, lblPulse, lblDiagonalElement, lblActiveRegionCount, lblActiveChanCount, lblLastSweep, lblExperiment
	variable lblTraceHeadstage, lblTraceExperiment, lblTraceSweepNumber, lblTraceChannelNumber, lblTracenumericalValues, lblTraceFullpath
	string channelTypeStr, channelList, channelNumberStr, key, regionList, baseName, sweepList, sweepNoStr, experiment

	if(mode == POST_PLOT_CONSTANT_SWEEPS && cs.singlePulse)
		// nothing to do
		return NaN
	endif

	WAVE/T/Z traceData = GetTraceInfos(GetMainWindow(win))

	if(!WaveExists(traceData))
		return NaN
	endif

	if(pa.startingPulse >= 0)
		startingPulseSett = pa.startingPulse
	endif

	if(pa.endingPulse >= 0)
		endingPulseSett = pa.endingPulse
	endif

	DFREF pulseAverageDFR = GetDevicePulseAverageFolder(pa.dfr)

	if(mode != POST_PLOT_ADDED_SWEEPS)
		KillorMoveToTrash(dfr = GetDevicePulseAverageHelperFolder(pa.dfr))
	endif

	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)
	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)
	WAVE/T propertiesText = GetPulseAveragePropertiesText(pulseAverageHelperDFR)
	WAVE/WAVE propertiesWaves = GetPulseAveragePropertiesWaves(pulseAverageHelperDFR)

	channelType = ITC_XOP_CHANNEL_TYPE_ADC
	channelTypeStr = StringFromList(channelType, ITC_CHANNEL_NAMES)

	WAVE/Z indizesChannelType = FindIndizes(traceData, colLabel="channelType", str=channelTypeStr)

	if(mode == POST_PLOT_ADDED_SWEEPS && WaveExists(additionalData))
		Make/FREE/N=(DimSize(indizesChannelType, ROWS)) indizesToAdd
		j = 0
		numNewSweeps = DimSize(additionalData, ROWS)
		for(i = 0; i < numNewSweeps; i += 1)
			WAVE/Z indizesNewSweep = FindIndizes(traceData, colLabel="SweepNumber", str=num2str(additionalData[i]))
			WAVE indizesToAddNewSweep = GetSetIntersection(indizesChannelType, indizesNewSweep)
			numNewIndicesSweep = DimSize(indizesToAddNewSweep, ROWS)
			indizesToAdd[j, j + numNewIndicesSweep - 1] = indizesToAddNewSweep[p - j]
			j += numNewIndicesSweep
		endfor
		Redimension/N=(j) indizesToAdd

		WAVE indizesChannelType = indizesToAdd
		totalPulseCounter = GetNumberFromWaveNote(properties, NOTE_INDEX)
		SetNumberInWaveNote(properties, NOTE_PA_NEW_PULSES_START, totalPulseCounter)
	endif

	WAVE/Z headstages         = PA_GetUniqueHeadstages(traceData, indizesChannelType)

	if(!WaveExists(headstages))
		return NaN
	endif

	lblIndex = -1

	lblSweep = FindDimLabel(properties, COLS, "Sweep")
	lblChannelType = FindDimLabel(properties, COLS, "ChannelType")
	lblChannelNumber = FindDimLabel(properties, COLS, "ChannelNumber")
	lblRegion = FindDimLabel(properties, COLS, "Region")
	lblHeadstage = FindDimLabel(properties, COLS, "Headstage")
	lblPulse = FindDimLabel(properties, COLS, "Pulse")
	lblDiagonalElement = FindDimLabel(properties, COLS, "DiagonalElement")
	lblActiveRegionCount = FindDimLabel(properties, COLS, "ActiveRegionCount")
	lblActiveChanCount = FindDimLabel(properties, COLS, "ActiveChanCount")
	lblLastSweep = FindDimLabel(properties, COLS, "LastSweep")

	lblExperiment = FindDimLabel(propertiesText, COLS, "Experiment")

	lblTraceHeadstage = FindDimLabel(traceData, COLS, "headstage")
	lblTraceSweepNumber = FindDimLabel(traceData, COLS, "SweepNumber")
	lblTraceChannelNumber = FindDimLabel(traceData, COLS, "ChannelNumber")
	lblTracenumericalValues = FindDimLabel(traceData, COLS, "numericalValues")
	lblTraceExperiment = FindDimLabel(traceData, COLS, "Experiment")
	lblTraceFullpath = FindDimLabel(traceData, COLS, "fullpath")

	numChannelTypeTraces = DimSize(indizesChannelType, ROWS)
	numHeadstages        = DimSize(headstages, ROWS)

	regionList = ""
	sweepList  = ""

	jsonID = JSON_New()

	// iterate over all headstages, ignores duplicates from overlay sweeps
	for(i = 0; i < numHeadstages; i += 1)

		region = headstages[i]

		if(!IsFinite(region)) // duplicated headstages in traceData
			continue
		endif

		activeRegionCount += 1

		regionList = AddListItem(num2str(region), regionList, ";", inf)

		activeChanCount = 0
		channelList = ""

		// we have the starting times for one channel type and headstage combination
		// iterate now over all channels of the same type and extract all
		// requested pulses for them
		for(j = 0; j < numChannelTypeTraces; j += 1)
			idx       = indizesChannelType[j]
			headstage = str2num(traceData[idx][lblTraceHeadstage])

			if(!IsFinite(headstage)) // ignore unassociated channels or duplicated headstages in traceData
				continue
			endif

			WAVE/Z pulseStartTimes = PA_GetPulseStartTimes(traceData, idx, region, channelTypeStr)

			if(!WaveExists(pulseStartTimes))
				continue
			endif

			sweepNoStr = traceData[idx][lblTraceSweepNumber]
			sweepNo = str2num(sweepNoStr)
			experiment = traceData[idx][lblTraceExperiment]
			channelNumberStr = traceData[idx][lblTraceChannelNumber]
			channelNumber = str2num(channelNumberStr)

			if(WhichListItem(channelNumberStr, channelList) == -1)
				activeChanCount += 1
				channelList = AddListItem(channelNumberStr, channelList, ";", inf)
				newChannel = 1
			else
				newChannel = 0
			endif

			if(WhichListItem(sweepNoStr, sweepList) == -1)
				sweepList = AddListItem(sweepNoStr, sweepList, ";", inf)
			endif

			isDiagonalElement = (activeRegionCount == activeChanCount)

			// we want to find the last acquired sweep from the experiment/device combination
			// by just using the path to the numerical labnotebook we can achieve that
			key = experiment + "_" + traceData[idx][lblTracenumericalValues]
			lastSweep = JSON_GetVariable(jsonID, key, ignoreErr = 1)
			if(IsNaN(lastSweep))
				WAVE numericalValues = $traceData[idx][lblTraceNumericalValues]
				WAVE junkWave = GetLastSweepWithSetting(numericalValues, "Headstage Active", lastSweep)
				ASSERT(IsValidSweepNumber(lastSweep), "Could not find last sweep")
				JSON_SetVariable(jsonID, key, lastSweep)
			endif

			numPulsesTotal = DimSize(pulseStartTimes, ROWS)
			startingPulse  = max(0, startingPulseSett)
			endingPulse    = min(numPulsesTotal - 1, endingPulseSett)
			numPulses = endingPulse - startingPulse + 1

			pulseToPulseLength = PA_GetPulseLength(pulseStartTimes, startingPulse, endingPulse, pa.overridePulseLength, pa.fixedPulseLength)

			WAVE numericalValues = $traceData[idx][lblTracenumericalValues]
			DFREF singleSweepFolder = GetWavesDataFolderDFR($traceData[idx][lblTraceFullpath])
			ASSERT(DataFolderExistsDFR(singleSweepFolder), "Missing singleSweepFolder")
			WAVE wv = GetITCDataSingleColumnWave(singleSweepFolder, channelType, channelNumber)

			DFREF singlePulseFolder = GetSingleSweepFolder(pulseAverageDFR, sweepNo)
			totalOnsetDelay = GetTotalOnsetDelay(numericalValues, sweepNo)
			// number of pulses that might be created
			numPulseCreate = endingPulse - startingPulse
			if(numPulseCreate)
				numPulseCreate += totalPulseCounter
				EnsureLargeEnoughWave(properties, minimumSize = numPulseCreate, initialValue = NaN)
				EnsureLargeEnoughWave(propertiesText, minimumSize = numPulseCreate)
				EnsureLargeEnoughWave(propertiesWaves, minimumSize = numPulseCreate)
			endif

			prevTotalPulseCounter = totalPulseCounter
			for(k = startingPulse; k <= endingPulse; k += 1)

				// ignore wave offset, as it is only used for display purposes
				// but use the totalOnsetDelay of this sweep
				first  = round((pulseStartTimes[k] + totalOnsetDelay) / DimDelta(wv, ROWS))
				length = round(pulseToPulseLength / DimDelta(wv, ROWS))

				WAVE/Z pulseWave = PA_CreateAndFillPulseWaveIfReq(wv, singlePulseFolder, channelType, channelNumber, \
				                                                  region, k, first, length)

				if(!WaveExists(pulseWave))
					continue
				endif

				properties[totalPulseCounter][lblSweep]                       = sweepNo
				properties[totalPulseCounter][lblChannelType]                 = channelType
				properties[totalPulseCounter][lblChannelNumber]               = channelNumber
				properties[totalPulseCounter][lblRegion]                      = region
				properties[totalPulseCounter][lblHeadstage]                   = headstage
				properties[totalPulseCounter][lblPulse]                       = k
				properties[totalPulseCounter][lblDiagonalElement]             = IsDiagonalElement
				properties[totalPulseCounter][lblActiveRegionCount]           = activeRegionCount
				properties[totalPulseCounter][lblActiveChanCount]             = activeChanCount
				properties[totalPulseCounter][lblLastSweep]                   = lastSweep

				propertiesText[totalPulseCounter][lblExperiment] = experiment

				propertiesWaves[totalPulseCounter] = pulseWave

				// gather all pulses from one set (used for averaging)
				totalPulseCounter += 1
			endfor

			// Actual number of created pulses
			numPulseCreate = totalPulseCounter - prevTotalPulseCounter
			WAVE setIndizes = GetPulseAverageSetIndizes(pulseAverageHelperDFR, channelNumber, region)
			if(lblIndex < 0)
				lblIndex = FindDimLabel(setIndizes, COLS, "Index")
			endif
			idx = GetNumberFromWaveNote(setIndizes, NOTE_INDEX)
			EnsureLargeEnoughWave(setIndizes, minimumSize = idx + numPulseCreate, initialValue = NaN)
			setIndizes[idx, idx + numPulseCreate - 1][lblIndex] = prevTotalPulseCounter + p - idx
			SetNumberInWaveNote(setIndizes, NOTE_INDEX, idx + numPulseCreate)
		endfor
	endfor

	SetNumberInWaveNote(properties, NOTE_INDEX, totalPulseCounter)
	SetNumberInWaveNote(propertiesText, NOTE_INDEX, totalPulseCounter)
	SetStringInWaveNote(properties, "Regions", ReplaceString(";", regionList, ","))
	SetStringInWaveNote(properties, "Channels", ReplaceString(";", channelList, ","))
	SetStringInWaveNote(properties, "Sweeps", ReplaceString(";", sweepList, ","))

	JSON_Release(jsonID)
End

static Function PA_ApplyPulseSortingOrder(string win, STRUCT PulseAverageSettings &pa)

	variable numRegions, numChannels, i, j, region, channelNumber, numEntries, pulseSortOrder

	DFREF pulseAverageDFR = GetDevicePulseAverageFolder(pa.dfr)
	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)
	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)

	WAVE channels = ListToNumericWave(GetStringFromWaveNote(properties, "Channels"), ",")
	numChannels = DimSize(channels, ROWS)

	WAVE regions = ListToNumericWave(GetStringFromWaveNote(properties, "Regions"), ",")
	numRegions = DimSize(regions, ROWS)

	Make/FREE/N=(0, 3) elems

	for(i = 0; i < numChannels; i += 1)
		channelNumber = channels[i]
		for(j = 0; j < numRegions; j += 1)
			region = regions[j]

			WAVE setIndizes = GetPulseAverageSetIndizes(pulseAverageHelperDFR, channelNumber, region)
			numEntries = GetNumberFromWaveNote(setIndizes, NOTE_INDEX)

			if(!numEntries)
				continue
			endif

			pulseSortOrder = GetNumberFromWaveNote(setIndizes, NOTE_KEY_PULSE_SORT_ORDER)

			if(IsFinite(pulseSortOrder) && pulseSortOrder == pa.pulseSortOrder)
				continue
			endif

			if(DimSize(elems, ROWS) != numEntries)
				Redimension/N=(numEntries, -1)/E=1 elems
			else
				// correct size
			endif

			Multithread elems[][0] = properties[setIndizes[p]][%Sweep]
			Multithread elems[][1] = properties[setIndizes[p]][%Pulse]
			Multithread elems[][2] = setIndizes[p]

			switch(pa.pulseSortOrder)
				case PA_PULSE_SORTING_ORDER_SWEEP:
					// first sweep than pulse
					SortColumns/KNDX={0, 1} sortWaves={elems}
					break
				case PA_PULSE_SORTING_ORDER_PULSE:
					// first pulse than sweep
					SortColumns/KNDX={1, 0} sortWaves={elems}
					break
				default:
					ASSERT(0, "Invalid sorting order")
			endswitch

			// copy sorted result back
			Multithread setIndizes[0, numEntries - 1] = elems[p][2]

			SetNumberInWaveNote(setIndizes, NOTE_KEY_PULSE_SORT_ORDER, pa.pulseSortOrder)
		endfor
	endfor
End

/// @brief Populates pps.pulseAverSett with the user selection from the panel
static Function PA_GatherSettings(win, s)
	string win
	STRUCT PulseAverageSettings &s

	string extPanel

	win      = GetMainWindow(win)
	extPanel = BSP_GetPanel(win)

	if(!BSP_IsActive(win, MIES_BSP_PA))
		InitPulseAverageSettings(s)
		return 0
	endif

	s.dfr                  = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)
	s.enabled              = GetCheckboxState(extPanel, "check_BrowserSettings_PA")
	s.showIndividualPulses = GetCheckboxState(extPanel, "check_pulseAver_indPulses")
	s.showAverage          = GetCheckboxState(extPanel, "check_pulseAver_showAver")
	s.multipleGraphs       = GetCheckboxState(extPanel, "check_pulseAver_multGraphs")
	s.startingPulse        = GetSetVariable(extPanel, "setvar_pulseAver_startPulse")
	s.endingPulse          = GetSetVariable(extPanel, "setvar_pulseAver_endPulse")
	s.overridePulseLength  = GetSetVariable(extPanel, "setvar_pulseAver_overridePulseLength")
	s.fixedPulseLength     = GetCheckboxState(extPanel, "check_pulseAver_fixedPulseLength")
	s.regionSlider         = GetSliderPositionIndex(extPanel, "slider_BrowserSettings_dDAQ")
	s.zeroPulses           = GetCheckboxState(extPanel, "check_pulseAver_zero")
	s.autoTimeAlignment    = GetCheckboxState(extPanel, "check_pulseAver_timeAlign")
	s.searchFailedPulses   = GetCheckboxState(extPanel, "check_pulseAver_searchFailedPulses")
	s.hideFailedPulses     = GetCheckboxState(extPanel, "check_pulseAver_hideFailedPulses")
	s.failedPulsesLevel    = GetSetVariable(extPanel, "setvar_pulseAver_failedPulses_level")
	s.yScaleBarLength      = GetSetVariable(extPanel, "setvar_pulseAver_vert_scale_bar")
	s.showImages           = GetCheckboxState(extPanel, "check_pulseAver_ShowImage")
	s.showTraces           = GetCheckboxState(extPanel, "check_pulseAver_ShowTraces")
	s.imageColorScale      = GetPopupMenuString(extPanel, "popup_pulseAver_colorscales")
	s.drawXZeroLine        = GetCheckboxState(extPanel, "check_pulseAver_timeAlign") && GetCheckboxState(extPanel, "check_pulseAver_drawXZeroLine")
	s.pulseSortOrder       = GetPopupMenuIndex(extPanel, "popup_pulseAver_pulseSortOrder")

	PA_DeconvGatherSettings(win, s.deconvolution)
End

/// @brief gather deconvolution settings from PA section in BSP
static Function PA_DeconvGatherSettings(win, deconvolution)
	string win
	STRUCT PulseAverageDeconvSettings &deconvolution

	string bsPanel = BSP_GetPanel(win)

	deconvolution.enable = GetCheckboxState(bsPanel, "check_pulseAver_deconv")
	deconvolution.smth   = GetSetVariable(bsPanel, "setvar_pulseAver_deconv_smth")
	deconvolution.tau    = GetSetVariable(bsPanel, "setvar_pulseAver_deconv_tau")
	deconvolution.range  = GetSetVariable(bsPanel, "setvar_pulseAver_deconv_range")
End

/// @brief Update the PA plot to accomodate changed settings
Function PA_Update(string win, variable mode, [WAVE/Z additionalData])

	string graph, preExistingGraphs, usedTraceGraphs, usedImageGraphs
	variable jsonIDOld, needsPlotting

	if(ParamIsDefault(additionalData))
		WAVE/Z additionalData = $""
	endif

	graph = GetMainWindow(win)

	STRUCT PulseAverageSettings old
	jsonIDOld = PA_DeSerializeSettings(graph, old)
	JSON_Release(jsonIDOld, ignoreErr=1)

	STRUCT PulseAverageSettings current
	PA_GatherSettings(graph, current)
	PA_SerializeSettings(graph, current)

	STRUCT PA_ConstantSettings cs
	[cs] = PA_DetermineConstantSettings(current, old, mode)

	WAVE/WAVE/Z targetForAverage, sourceForAverage
	[targetForAverage, sourceForAverage, needsPlotting] = PA_PreProcessPulses(win, current, cs, mode, additionalData)

	if(!needsPlotting)
		return NaN
	endif

	preExistingGraphs = PA_GetGraphs(win, PA_DISPLAYMODE_ALL)

	usedTraceGraphs = PA_ShowPulses(graph, current, cs, targetForAverage, sourceForAverage, mode, additionalData)

	try
		usedImageGraphs = PA_ShowImage(graph, current, cs, targetForAverage, sourceForAverage, mode, additionalData); AbortOnRTE
	catch
		ASSERT(V_AbortCode == -3, "Unexpected abort")
		usedImageGraphs = PA_ShowImage(graph, current, cs, targetForAverage, sourceForAverage, POST_PLOT_FULL_UPDATE, $"")
	endtry

	KillWindows(RemoveFromList(usedTraceGraphs + usedImageGraphs, preExistingGraphs))
End

static Function/WAVE PA_GetSetWaves(DFREF dfr, variable channelNumber, variable region, [variable mode, variable removeFailedPulses])

	mode = ParamIsDefault(mode) ? 0 : mode
	removeFailedPulses = ParamIsDefault(removeFailedPulses) ? 0 : !!removeFailedPulses

	WAVE setIndizes = GetPulseAverageSetIndizes(dfr, channelNumber, region)

	WAVE properties = GetPulseAverageProperties(dfr)
	WAVE/WAVE propertiesWaves = GetPulseAveragePropertiesWaves(dfr)

	return PA_GetSetWaves_TS(properties, propertiesWaves, setIndizes, mode, removeFailedPulses)
End

threadsafe static Function/WAVE PA_GetSetWaves_TS(WAVE properties, WAVE/WAVE propertiesWaves, WAVE setIndizes, variable mode, variable removeFailedPulses)

	variable numWaves, i, numNewPulses, startIndexNewPulses, index

	numWaves = GetNumberFromWaveNote(setIndizes, NOTE_INDEX)

	if(numWaves == 0)
		return $""
	endif

	if(mode == POST_PLOT_ADDED_SWEEPS)
		startIndexNewPulses = GetNumberFromWaveNote(properties, NOTE_PA_NEW_PULSES_START)
		Make/FREE/N=(numWaves)/WAVE setWaves

		if(removeFailedPulses)
			for(i = 0; i < numWaves; i += 1)
				index = setIndizes[i]
				if(index >= startIndexNewPulses && !properties[index][%PulseHasFailed])
					setWaves[numNewPulses] = propertiesWaves[index]
					numNewPulses += 1
				endif
			endfor
		else
			for(i = 0; i < numWaves; i += 1)
				index = setIndizes[i]
				if(index >= startIndexNewPulses)
					setWaves[numNewPulses] = propertiesWaves[index]
					numNewPulses += 1
				endif
			endfor
		endif
		Redimension/N=(numNewPulses) setWaves
	else
		Make/FREE/N=(numWaves)/WAVE setWaves = propertiesWaves[setIndizes[p]]

		if(!removeFailedPulses)
			return setWaves
		endif

		for(i = numWaves - 1; i >= 0; i -= 1)
			if(properties[setIndizes[i]][%PulseHasFailed])
				DeletePoints/M=(ROWS) i, 1, setWaves
			endif
		endfor
	endif

	if(DimSize(setWaves, ROWS) == 0)
		return $""
	endif

	return setWaves
End

/// @brief Handle marking pulses as failed/passed if required
static Function PA_MarkFailedPulses(WAVE properties, WAVE/WAVE propertiesWaves, STRUCT PulseAverageSettings &pa)
	variable numTotalPulses, i, isDiagonalElement, sweepNo
	variable region, pulse, pulseHasFailed, jsonID, referencePulseHasFailed
	string key

	numTotalPulses = GetNumberFromWaveNote(properties, NOTE_INDEX)

	if(numTotalPulses == 0)
		return NaN
	endif

	// update the wave notes
	Make/FREE/N=(numTotalPulses) junkWave
	Multithread junkWave[] = SetNumberInWaveNote(propertiesWaves[p], NOTE_KEY_SEARCH_FAILED_PULSE, pa.searchFailedPulses)

	if(!pa.searchFailedPulses)
		Multithread properties[][%PulseHasFailed] = NaN
		return NaN
	endif

	jsonID = JSON_New()

	// mark pulses in the diagonal elements for failed/passed
	// this is done by PA_PulseHasFailed which either uses the wave note
	// or uses FindLevel if required.
	for(i = 0; i < numTotalPulses; i += 1)

		isDiagonalElement = properties[i][%DiagonalElement]

		if(!isDiagonalElement)
			continue
		endif

		sweepNo = properties[i][%Sweep]
		region  = properties[i][%Region]
		pulse   = properties[i][%Pulse]

		WAVE wv = propertiesWaves[i]

		pulseHasFailed = PA_PulseHasFailed(wv, pa)
		properties[i][%PulseHasFailed] = pulseHasFailed

		key = PA_GenerateFailedPulseKey(sweepNo, region, pulse)
		JSON_SetVariable(jsonID, key, pulseHasFailed)
	endfor

	// mark all other failed pulses
	// this uses the JSON document for fast lookup
	for(i = 0; i < numTotalPulses; i += 1)
		sweepNo = properties[i][%Sweep]
		region  = properties[i][%Region]
		pulse   = properties[i][%Pulse]

		if(properties[i][%DiagonalElement])
			continue
		endif

		key = PA_GenerateFailedPulseKey(sweepNo, region, pulse)
		referencePulseHasFailed = JSON_GetVariable(jsonID, key, ignoreErr = 1)
		// NaN: reference trace could not be found, this happens
		// when a headstage is not displayed (channel selection, OVS HS removal)
		properties[i][%PulseHasFailed] = IsNaN(referencePulseHasFailed) ? 0 : referencePulseHasFailed
	endfor

	JSON_Release(jsonID)

	// need to do that at the end, as PA_PulseHasFailed uses that entry for checking if it needs to rerun
	Multithread junkWave[] = SetNumberInWaveNote(propertiesWaves[p], NOTE_KEY_FAILED_PULSE_LEVEL, pa.failedPulsesLevel)
End

/// @brief This function returns data from the light-weight data storage for PA graph data
/// @param[in] graph name of PA graph
/// @param[in] clear [optional, default = 0] when set reinitializes the data for the given graph
/// @retval idx row index of the wave where the graph data is stored
/// @retval traceCount traceCount for this graph
static Function [variable idx, variable traceCount] PA_GetTraceCountFromGraphData(string graph, [variable clear])

	clear = ParamIsDefault(clear) ? 0 : !!clear

	WAVE/T graphData = GetPAGraphData()
	idx = FindDimLabel(graphData, ROWS, graph)
	if(idx >= 0)
		if(clear)
			graphData[idx][%TRACECOUNT] = "0"
			graphData[idx][%TRACES_AVERAGE] = ""
			graphData[idx][%TRACES_DECONV] = ""
			graphData[idx][%TRACES_AVERAGEFORDECONV] = ""
			graphData[idx][%TRACES_AVERAGE_XAXIS] = ""
			graphData[idx][%TRACES_AVERAGE_YAXIS] = ""
			graphData[idx][%TRACES_AVERAGE_WAVES] = ""
			graphData[idx][%IMAGELIST] = ""
		endif
		return [idx, str2num(graphData[idx][0])]
	endif

	idx = DimSize(graphData, ROWS)
	Redimension/N=(idx + 1, -1) graphData
	SetDimLabel ROWS, idx, $graph, graphData
	graphData[idx][%TRACECOUNT] = "0"

	return [idx, 0]
End

static Function/S PA_ShowPulses(string win, STRUCT PulseAverageSettings &pa, STRUCT PA_ConstantSettings &cs, WAVE/Z targetForAverageGeneric, WAVE/Z sourceForAverageGeneric, variable mode, WAVE/Z additionalData)

	string pulseTrace, str, graph, key
	variable numChannels, i, j, sweepNo, headstage, numTotalPulses, pulse, xPos, yPos
	variable first, numEntries, startingPulse, endingPulse, traceCount, step, isDiagonalElement
	variable channelNumber, region, channelType, length, newSweepCount
	variable numChannelTypeTraces, activeRegionCount, activeChanCount, totalOnsetDelay, pulseHasFailed
	variable numRegions, hideTrace, lastSweep, alpha, constantSinglePulseSettings
	variable hiddenTracesCount, userDataCount, avgPlotCount, deconPlotCount
	variable jsonID, hideTraceJsonID, graphDataIndex, numHiddenTracesGraphs, graphHasChanged, tmpVal
	variable startIndexNewPulses, numPlotPulses
	variable lblSweep, lblExperiment, lblChannelNumber, lblRegion, lblHeadstage, lblPulse
	variable lblDiagonalElement, lblActiveRegionCount, lblActiveChanCount, lblPulseHasFailed, lblLastSweep, lblTRACES_AVERAGE, lblTRACECOUNT, lblTRACES_DECONV
	variable lblTRACES_AVERAGE_XAXIS, lblTRACES_AVERAGE_YAXIS, lblTRACES_AVERAGE_WAVES, lblTRACES_AVERAGEFORDECONV
	string jsonPath
	string vertAxis, horizAxis, experiment
	string baseName, traceName, tagName
	string usedGraphs = ""
	string previousGraph = ""

	if(!pa.showTraces)
		return usedGraphs
	elseif(cs.traces)
		return PA_GetGraphs(win, PA_DISPLAYMODE_TRACES)
	endif

	WAVE/WAVE/Z targetForAverage = targetForAverageGeneric
	WAVE/WAVE/Z sourceForAverage = sourceForAverageGeneric

	DFREF pulseAverageDFR = GetDevicePulseAverageFolder(pa.dfr)
	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)

	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)
	WAVE/T propertiesText = GetPulseAveragePropertiesText(pulseAverageHelperDFR)
	WAVE/WAVE propertiesWaves = GetPulseAveragePropertiesWaves(pulseAverageHelperDFR)

	WAVE channels = ListToNumericWave(GetStringFromWaveNote(properties, "Channels"), ",")
	numChannels = DimSize(channels, ROWS)

	WAVE regions = ListToNumericWave(GetStringFromWaveNote(properties, "Regions"), ",")
	numRegions = DimSize(regions, ROWS)

	numTotalPulses = GetNumberFromWaveNote(properties, NOTE_INDEX)

	if(mode == POST_PLOT_ADDED_SWEEPS)
		startIndexNewPulses = GetNumberFromWaveNote(properties, NOTE_PA_NEW_PULSES_START)
		ASSERT(!IsNaN(startIndexNewPulses), "Add sweep plots mode is missing new pulse start information.")
	endif
	numPlotPulses = numTotalPulses - startIndexNewPulses

	WAVE/T paGraphData = GetPAGraphData()

	lblSweep = FindDimLabel(properties, COLS, "Sweep")
	lblExperiment = FindDimLabel(propertiesText, COLS, "Experiment")
	lblChannelNumber = FindDimLabel(properties, COLS, "ChannelNumber")
	lblRegion = FindDimLabel(properties, COLS, "Region")
	lblHeadstage = FindDimLabel(properties, COLS, "Headstage")
	lblPulse = FindDimLabel(properties, COLS, "Pulse")
	lblDiagonalElement = FindDimLabel(properties, COLS, "DiagonalElement")
	lblActiveRegionCount = FindDimLabel(properties, COLS, "ActiveRegionCount")
	lblActiveChanCount = FindDimLabel(properties, COLS, "ActiveChanCount")
	lblPulseHasFailed = FindDimLabel(properties, COLS, "PulseHasFailed")
	lblLastSweep = FindDimLabel(properties, COLS, "LastSweep")
	lblTRACECOUNT = FindDimLabel(paGraphData, COLS, "TRACECOUNT")
	lblTRACES_AVERAGE = FindDimLabel(paGraphData, COLS, "TRACES_AVERAGE")
	lblTRACES_DECONV = FindDimLabel(paGraphData, COLS, "TRACES_DECONV")
	lblTRACES_AVERAGE_XAXIS = FindDimLabel(paGraphData, COLS, "TRACES_AVERAGE_XAXIS")
	lblTRACES_AVERAGE_YAXIS = FindDimLabel(paGraphData, COLS, "TRACES_AVERAGE_YAXIS")
	lblTRACES_AVERAGE_WAVES = FindDimLabel(paGraphData, COLS, "TRACES_AVERAGE_WAVES")
	lblTRACES_AVERAGEFORDECONV = FindDimLabel(paGraphData, COLS, "TRACES_AVERAGEFORDECONV")

	Make/T/FREE/N=(numTotalPulses) plotTraces, hiddenTraces
	jsonID = JSON_Parse("{}")
	if(pa.multipleGraphs)
		hideTraceJsonID = JSON_Parse("{}")
	endif

	for(i = startIndexNewPulses; i < numTotalPulses; i += 1)

		sweepNo = properties[i][lblSweep]
		experiment = propertiesText[i][lblExperiment]
		channelNumber = properties[i][lblChannelNumber]
		region = properties[i][lblRegion]
		headstage = properties[i][lblHeadstage]
		pulse = properties[i][lblPulse]
		isDiagonalElement = properties[i][lblDiagonalElement]
		activeRegionCount = properties[i][lblActiveRegionCount]
		activeChanCount = properties[i][lblActiveChanCount]
		pulseHasFailed = properties[i][lblPulseHasFailed]
		lastSweep = properties[i][lblLastSweep]

		if(!pa.multipleGraphs && i == startIndexNewPulses || pa.multipleGraphs)
			graph = PA_GetGraph(win, pa, PA_DISPLAYMODE_TRACES, channelNumber, region, activeRegionCount, activeChanCount, numRegions)
			graphHasChanged = CmpStr(graph, previousGraph)
			if(graphHasChanged)
				if(!IsEmpty(previousGraph))
					paGraphData[graphDataIndex][lblTRACECOUNT] = num2istr(traceCount)
				endif
				[graphDataIndex, traceCount] = PA_GetTraceCountFromGraphData(graph)
				previousGraph = graph
			endif
		endif

		if(pa.regionSlider != -1 && pa.regionSlider != region) // unselected region in ddaq viewing mode
			continue
		endif

		[vertAxis, horizAxis] = PA_GetAxes(pa, activeRegionCount, activeChanCount)

		if(WhichListItem(graph, usedGraphs) == -1)
			if(mode != POST_PLOT_ADDED_SWEEPS)
				RemoveTracesFromGraph(graph)
				[graphDataIndex, traceCount] = PA_GetTraceCountFromGraphData(graph, clear = 1)
			endif
			RemoveAnnotationsFromGraph(graph)
			usedGraphs = AddListItem(graph, usedGraphs, ";", inf)
		endif

		STRUCT RGBColor s

		if(pa.showIndividualPulses)

			step = isDiagonalElement ? 1 : PA_PLOT_STEPPING

			if(pulseHasFailed)
				hideTrace = pa.hideFailedPulses
				s.red   = 65535
				s.green = 0
				s.blue  = 0
				alpha = 65535
			else
				hideTrace = 0
				[s] = GetTraceColor(headstage)
				alpha = 65535 * 0.2
			endif

			WAVE plotWave = propertiesWaves[i]
			sprintf pulseTrace, "T%0*d%s", TRACE_NAME_NUM_DIGITS, traceCount, NameOfWave(plotWave)
			traceCount += 1

			jsonPath = graph + "/" + vertAxis + "/" + horizAxis + "/" + num2str(s.red) + "/" + num2str(s.green) + "/" + num2str(s.blue) + "/" + num2str(alpha) + "/" + num2str(step) + "/"
			JSON_AddTreeArray(jsonID, jsonPath + "index")
			JSON_AddTreeArray(jsonID, jsonPath + "traceName")
			JSON_AddVariable(jsonID, jsonPath + "index", i)
			JSON_AddString(jsonID, jsonPath + "traceName", pulseTrace)

			if(hideTrace)
				if(pa.multipleGraphs)
					jsonPath = graph + "/hiddenTraces"
					JSON_AddTreeArray(hideTraceJsonID, jsonPath)
					JSON_AddString(hideTraceJsonID, jsonPath, pulseTrace)
				else
					hiddenTraces[hiddenTracesCount] = pulseTrace
					hiddenTracesCount += 1
				endif
			endif

			if(pulseHasFailed && isDiagonalElement && (sweepNo == lastSweep))
				sprintf tagName "tag_%s_AD%d_R%d", vertAxis, channelNumber, region
				if(WhichListItem(tagName, AnnotationList(graph)) == -1)
					xPos = (activeRegionCount / numRegions) * 100 - 2
					yPos = (activeChanCount / numChannels) * 100  - (1 / numChannels) * 100 / 2
					Textbox/W=$graph/K/N=$tagName
					Textbox/W=$graph/N=$tagName/F=0/A=LT/L=0/X=(xPos)/Y=(ypos)/E=2 "☣️"
				endif
			endif
		endif
	endfor
	paGraphData[graphDataIndex][lblTRACECOUNT] = num2istr(traceCount)

	PA_AccelerateAppendTraces(jsonID, propertiesWaves)
	if(pa.multipleGraphs)
		WAVE/T hiddenTracesGraphs = JSON_GetKeys(hideTraceJsonID, "")
		numHiddenTracesGraphs = DimSize(hiddenTracesGraphs, ROWS)
		for(j = 0; j < numHiddenTracesGraphs; j += 1)
			WAVE/T hiddenTracesNames = JSON_GetTextWave(hideTraceJsonID, hiddenTracesGraphs[j] + "/hiddenTraces")
			AccelerateHideTraces(hiddenTracesGraphs[j], hiddenTracesNames, DimSize(hiddenTracesNames, ROWS))
		endfor
		JSON_Release(hideTraceJsonID)
	else
		AccelerateHideTraces(graph, hiddenTraces, hiddenTracesCount)
	endif
	JSON_Release(jsonID)

	Make/T/FREE/N=(numChannels * numRegions) avgPlotTraces, deconPlotTraces
	for(i = 0; i < numChannels; i += 1)
		channelNumber = channels[i]
		for(j = 0; j < numRegions; j += 1)
			region = regions[j]

			isDiagonalElement = (i == j)

			if(WaveExists(targetForAverage))
				WAVE/Z freeAverageWave = targetForAverage[i][j]

				if(!WaveExists(freeAverageWave))
					continue
				endif

				baseName = PA_BaseName(channelNumber, region)
				WAVE averageWave = PA_Average(sourceForAverage[i][j], pulseAverageDFR, PA_AVERAGE_WAVE_PREFIX + baseName, \
				                              inputAverage = freeAverageWave)
				WaveClear freeAverageWave
			else
				WAVE/WAVE/Z setWaves = PA_GetSetWaves(pulseAverageHelperDFR, channelNumber, region, removeFailedPulses = 1)

				if(!WaveExists(setWaves))
					continue
				endif

				baseName = PA_BaseName(channelNumber, region)
				WAVE averageWave = PA_Average(setWaves, pulseAverageDFR, PA_AVERAGE_WAVE_PREFIX + baseName)
			endif

			activeChanCount = i + 1
			activeRegionCount = j + 1
			[vertAxis, horizAxis] = PA_GetAxes(pa, activeRegionCount, activeChanCount)

			if(!pa.multipleGraphs && i == 0 && j == 0 || pa.multipleGraphs)
				graph = PA_GetGraph(win, pa, PA_DISPLAYMODE_TRACES, channelNumber, region, activeRegionCount, activeChanCount, numRegions)
				[graphDataIndex, traceCount] = PA_GetTraceCountFromGraphData(graph)
				WAVE/T averageTraceNames = ListToTextWave(paGraphData[graphDataIndex][lblTRACES_AVERAGE], ";")
				WAVE/T deconvolutionTraceNames = ListToTextWave(paGraphData[graphDataIndex][lblTRACES_DECONV], ";")
			endif

			if(pa.showAverage)
				if(WaveExists(averageTraceNames))
					WAVE/Z foundAverageTraces = GrepTextWave(averageTraceNames, ".*\\E" + PA_AVERAGE_WAVE_PREFIX + basename + "\\Q" + "$")
				else
					WAVE/Z foundAverageTraces = $""
				endif

				if(!WaveExists(foundAverageTraces))
					sprintf traceName, "T%0*d%s%s", TRACE_NAME_NUM_DIGITS, traceCount, PA_AVERAGE_WAVE_PREFIX, baseName
					traceCount += 1
					paGraphData[graphDataIndex][lblTRACECOUNT] = num2istr(traceCount)

					[s] = GetTraceColor(NUM_HEADSTAGES + 1)
					AppendToGraph/Q/W=$graph/L=$vertAxis/B=$horizAxis/C=(s.red, s.green, s.blue) averageWave/TN=$traceName

					if(pa.multipleGraphs)
						ModifyGraph/W=$graph lsize($traceName)=PA_AVGERAGE_PLOT_LSIZE
					else
						avgPlotTraces[avgPlotCount] = traceName
						avgPlotCount += 1
					endif

					paGraphData[graphDataIndex][lblTRACES_AVERAGE] = AddListItem(traceName, paGraphData[graphDataIndex][lblTRACES_AVERAGE], ";", Inf)
					if(!isDiagonalElement)
						paGraphData[graphDataIndex][lblTRACES_AVERAGEFORDECONV] = AddListItem(traceName, paGraphData[graphDataIndex][lblTRACES_AVERAGEFORDECONV], ";", Inf)
						paGraphData[graphDataIndex][lblTRACES_AVERAGE_XAXIS] = AddListItem(horizAxis, paGraphData[graphDataIndex][lblTRACES_AVERAGE_XAXIS], ";", Inf)
						paGraphData[graphDataIndex][lblTRACES_AVERAGE_YAXIS] = AddListItem(vertAxis, paGraphData[graphDataIndex][lblTRACES_AVERAGE_YAXIS], ";", Inf)
						paGraphData[graphDataIndex][lblTRACES_AVERAGE_WAVES] = AddListItem(GetWavesDataFolder(averageWave, 2), paGraphData[graphDataIndex][lblTRACES_AVERAGE_WAVES], ";", Inf)
					endif
				endif
			endif

			if(pa.deconvolution.enable && !isDiagonalElement)

				if(WaveExists(deconvolutionTraceNames))
					WAVE/Z foundDeconvolution = GrepTextWave(deconvolutionTraceNames, ".*\\E" + PA_DECONVOLUTION_WAVE_PREFIX + basename + "\\Q" + "$")
				else
					WAVE/Z foundDeconvolution = $""
				endif

				WAVE deconv = PA_Deconvolution(averageWave, pulseAverageDFR, PA_DECONVOLUTION_WAVE_PREFIX + baseName, pa.deconvolution)

				if(!WaveExists(foundDeconvolution))

					sprintf traceName, "T%0*d%s%s", TRACE_NAME_NUM_DIGITS, traceCount, PA_DECONVOLUTION_WAVE_PREFIX, baseName
					traceCount += 1
					paGraphData[graphDataIndex][lblTRACECOUNT] = num2istr(traceCount)

					AppendToGraph/Q/W=$graph/L=$vertAxis/B=$horizAxis/C=(0,0,0) deconv[0,inf;PA_PLOT_STEPPING]/TN=$traceName

					if(pa.multipleGraphs)
						ModifyGraph/W=$graph lsize($traceName)=PA_DECONVOLUTION_PLOT_LSIZE
					else
						deconPlotTraces[deconPlotCount] = traceName
						deconPlotCount += 1
					endif

					paGraphData[graphDataIndex][lblTRACES_DECONV] = AddListItem(traceName, paGraphData[graphDataIndex][lblTRACES_DECONV], ";", Inf)
				endif
			endif
		endfor
	endfor
	if(!pa.multipleGraphs)
		AccelerateModLineSizeTraces(graph, avgPlotTraces, avgPlotCount, PA_AVGERAGE_PLOT_LSIZE)
		AccelerateModLineSizeTraces(graph, deconPlotTraces, deconPlotCount, PA_DECONVOLUTION_PLOT_LSIZE)
	endif

	PA_DrawScaleBars(win, pa, PA_DISPLAYMODE_TRACES, PA_USE_WAVE_SCALES)
	PA_LayoutGraphs(win, PA_DISPLAYMODE_TRACES, regions, channels, pa)
	PA_DrawXZeroLines(win, PA_DISPLAYMODE_TRACES, regions, channels, pa)

	return usedGraphs
End

/// @brief Remove all traces, image and annotations from the graph and clears its trace user data
static Function PA_ClearGraphs(string graphs)

	string graph
	variable numEntries, i
	variable junk

	numEntries = ItemsInList(graphs)
	for(i = 0; i < numEntries; i += 1)
		graph = StringFromList(i, graphs)

		RemoveTracesFromGraph(graph)
		RemoveImagesFromGraph(graph)
		RemoveAnnotationsFromGraph(graph)
		[junk, junk] = PA_GetTraceCountFromGraphData(graph, clear = 1)
	endfor
End

/// @brief Helper structure to store the constantness of various categories of settings.
static Structure PA_ConstantSettings
	variable singlePulse
	variable traces // includes general and single pulse settings
	variable images // includes general and single pulse settings
EndStructure

/// @brief Returns a filled structure #PA_ConstantSettings which has 1 for all
///        constant entries of the given category.
static Function [STRUCT PA_ConstantSettings cs] PA_DetermineConstantSettings(STRUCT PulseAverageSettings &pa, STRUCT PulseAverageSettings &paOld, variable mode)

	variable generalSettings

	if(mode != POST_PLOT_CONSTANT_SWEEPS)
		cs.singlePulse = 0
		cs.traces = 0
		cs.images = 0
		return [cs]
	endif

	cs.singlePulse = (pa.startingPulse == paOld.startingPulse                \
	                  && pa.endingPulse == paOld.endingPulse                 \
	                  && pa.overridePulseLength == paOld.overridePulseLength \
	                  && pa.fixedPulseLength == paOld.fixedPulseLength)

	generalSettings = (pa.showIndividualPulses == paOld.showIndividualPulses    \
	                   && pa.drawXZeroLine == paOld.drawXZeroLine               \
	                   && pa.showAverage == paOld.showAverage                   \
	                   && pa.regionSlider == paOld.regionSlider                 \
	                   && pa.multipleGraphs == paOld.multipleGraphs             \
	                   && pa.zeroPulses == paOld.zeroPulses                     \
	                   && pa.autoTimeAlignment == paOld.autoTimeAlignment       \
	                   && pa.enabled == paOld.enabled                           \
	                   && pa.hideFailedPulses == paOld.hideFailedPulses         \
	                   && pa.failedPulsesLevel ==  paOld.failedPulsesLevel      \
	                   && pa.searchFailedPulses == paOld.searchFailedPulses     \
	                   && pa.deconvolution.enable == paOld.deconvolution.enable \
	                   && pa.deconvolution.smth == paOld.deconvolution.smth     \
	                   && pa.deconvolution.tau == paOld.deconvolution.tau       \
	                   && pa.deconvolution.range == paOld.deconvolution.range)

	cs.traces = (generalSettings == 1                            \
	             && cs.singlePulse == 1                          \
	             && pa.showTraces == paOld.showTraces            \
	             && pa.yScaleBarLength == paOld.yScaleBarLength)

	cs.images = (generalSettings == 1                          \
	             && cs.singlePulse == 1                        \
	             && pa.showImages == paOld.showImages          \
	             && pa.pulseSortOrder == paOld.pulseSortOrder)

	return [cs]
End

/// @brief Gather and pre-process the single pulses for display
///
/// This function is display-type agnostic and only does preparational steps.
/// No graphs are created or killed.
///
/// The work with pulses is done in the following order:
/// - Gather pulses
/// - Sort pulses (in setIndizes)
/// - Reset pulses to backup
/// - Failed pulse marking
/// - Zeroing
/// - Time alignment
/// - Averaging
///
/// @retval dest          wave reference wave with average data for each set or $""
/// @retval source        wave reference wave with the data for each set or $""
/// @retval needsPlotting boolean denoting if there are pulses to plot
static Function [WAVE/WAVE dest, WAVE/WAVE source, variable needsPlotting] PA_PreProcessPulses(string win, STRUCT PulseAverageSettings &pa, STRUCT PA_ConstantSettings &cs, variable mode, WAVE/Z additionalData)

	variable numChannels, numRegions, i, j, region, channelNumber
	variable constantSinglePulseSettings, numTotalPulses
	variable graphDataIndex, traceCount
	string preExistingGraphs, graph

	preExistingGraphs = PA_GetGraphs(win, PA_DISPLAYMODE_ALL)
	graph = GetMainWindow(win)

	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)

	if(!pa.enabled)
		KillWindows(preExistingGraphs)
		KillOrMoveToTrash(dfr = pulseAverageHelperDFR)
		return [$"", $"", 0]
	endif

	PA_GenerateAllPulseWaves(win, pa, cs, mode, additionalData)

	PA_ApplyPulseSortingOrder(win, pa)

	DFREF pulseAverageDFR = GetDevicePulseAverageFolder(pa.dfr)

	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)
	WAVE/T propertiesText = GetPulseAveragePropertiesText(pulseAverageHelperDFR)
	WAVE/WAVE propertiesWaves = GetPulseAveragePropertiesWaves(pulseAverageHelperDFR)

	WAVE channels = ListToNumericWave(GetStringFromWaveNote(properties, "Channels"), ",")
	numChannels = DimSize(channels, ROWS)

	WAVE regions = ListToNumericWave(GetStringFromWaveNote(properties, "Regions"), ",")
	numRegions = DimSize(regions, ROWS)

	if(numChannels != numRegions)
		return [$"", $"", 0]
	endif

	numTotalPulses = GetNumberFromWaveNote(properties, NOTE_INDEX)

	if(numTotalPulses == 0)
		PA_ClearGraphs(preExistingGraphs)
		return [$"", $"", 0]
	endif

	for(i = 0; i < numChannels; i += 1)
		channelNumber = channels[i]
		for(j = 0; j < numRegions; j += 1)
			region = regions[j]

			WAVE/WAVE/Z setWaves = PA_GetSetWaves(pulseAverageHelperDFR, channelNumber, region)

			if(!WaveExists(setWaves))
				continue
			endif

			PA_ResetWavesIfRequired(setWaves, pa)
		endfor
	endfor

	PA_MarkFailedPulses(properties, propertiesWaves, pa)

	for(i = 0; i < numChannels; i += 1)
		channelNumber = channels[i]
		for(j = 0; j < numRegions; j += 1)
			region = regions[j]

			WAVE/WAVE/Z setWaves = PA_GetSetWaves(pulseAverageHelperDFR, channelNumber, region)

			if(!WaveExists(setWaves))
				continue
			endif

			PA_ZeroPulses(setWaves, pa)
		endfor
	endfor

	PA_AutomaticTimeAlignment(win, pa)

	if(mode != POST_PLOT_CONSTANT_SWEEPS || !cs.singlePulse)
		WAVE/WAVE/Z dest, source
		[dest, source] = PA_CalculateAllAverages(pa, mode)
		return [dest, source, 1]
	endif

	return [$"", $"", 1]
End

static Function [WAVE/WAVE dest, WAVE/WAVE source] PA_CalculateAllAverages(STRUCT PulseAverageSettings &pa, variable mode)

	variable numChannels, numRegions, i, j, channelNumber, region, numThreads

	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)

	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)
	WAVE/WAVE propertiesWaves = GetPulseAveragePropertiesWaves(pulseAverageHelperDFR)
	WAVE channels = ListToNumericWave(GetStringFromWaveNote(properties, "Channels"), ",")
	numChannels = DimSize(channels, ROWS)
	WAVE regions = ListToNumericWave(GetStringFromWaveNote(properties, "Regions"), ",")
	numRegions = DimSize(regions, ROWS)

	Make/FREE/WAVE/N=(numChannels, numRegions) source, dest, setIndices
	numThreads = min(numRegions * numChannels, ThreadProcessorCount)

	setIndices[][] = GetPulseAverageSetIndizes(pulseAverageHelperDFR, channels[p], regions[q])
	Multithread/NT=(numThreads) source[][] = PA_GetSetWaves_TS(properties, propertiesWaves, setIndices[p][q], mode, 1)

	WAVE/WAVE avgBuffer = GetPAAverageBuffer()

	if(mode == POST_PLOT_ADDED_SWEEPS)
		Multithread/NT=(numThreads) avgBuffer[][] = MIES_fWaveAverage(source[p][q], 0, IGOR_TYPE_32BIT_FLOAT, getComponents = 1, prevAvgData = PA_ExtractSumsCountsOnly(avgBuffer[p][q]))
	else
		Redimension/N=(numChannels, numRegions) avgBuffer
		Multithread/NT=(numThreads) avgBuffer[][] = MIES_fWaveAverage(source[p][q], 0, IGOR_TYPE_32BIT_FLOAT, getComponents = 1)
	endif
	dest[][] = PA_ExtractAverageOnly(avgBuffer[p][q])

	return [dest, source]
End

threadsafe static Function/WAVE PA_ExtractAverageOnly(WAVE/WAVE w)
	return w[0]
End

threadsafe static Function/WAVE PA_ExtractSumsCountsOnly(WAVE/WAVE w)
	Make/FREE/WAVE result = {w[1], w[2]}
	return result
End

Function PA_AxisHook(s)
	STRUCT WMAxisHookStruct &s

	// Called during experiment load
	// so it needs to be robust
	try
		ClearRTError()
		PA_UpdateScaleBars(s.win); AbortOnRTE
	catch
		printf "Encountered error/abort (%s)\r", GetRTErrMessage()
		ClearRTError()
	endtry

	return 0
End

static Function PA_UpdateScaleBars(string win)

	variable displayMode
	string bsPanel

	if(GrepString(win, PA_GRAPH_PREFIX))
		bsPanel = GetUserData(win, "", MIES_BSP_PA_MAINPANEL)
	else
		bsPanel = BSP_GetPanel(win)
	endif

	ASSERT(WindowExists(win), "Missing window")

	displayMode = ItemsInList(ImageNameList(win, ";")) > 0 ? PA_DISPLAYMODE_IMAGES : PA_DISPLAYMODE_TRACES

	STRUCT PulseAverageSettings pa
	PA_GatherSettings(bsPanel, pa)
	PA_DrawScaleBars(bsPanel, pa, displayMode, PA_USE_AXIS_SCALES)
End

static Function PA_DrawScaleBars(string win, STRUCT PulseAverageSettings &pa, variable displayMode, variable axisMode)

	variable i, j, numChannels, numRegions, region, channelNumber, drawXScaleBarOverride
	variable activeChanCount, activeRegionCount, maximum, length, drawYScaleBarOverride
	string graph, vertAxis, horizAxis, baseName, xUnit, yUnit

	if((!pa.showIndividualPulses && !pa.showAverage && !pa.deconvolution.enable) \
	   || (!pa.showTraces && displayMode == PA_DISPLAYMODE_TRACES)               \
	   || (!pa.showImages && displayMode == PA_DISPLAYMODE_IMAGES))
		// blank graph
		return NaN
	endif

	DFREF pulseAverageDFR = GetDevicePulseAverageFolder(pa.dfr)
	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)

	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)

	WAVE channels = ListToNumericWave(GetStringFromWaveNote(properties, "Channels"), ",")
	numChannels = DimSize(channels, ROWS)

	WAVE regions = ListToNumericWave(GetStringFromWaveNote(properties, "Regions"), ",")
	numRegions = DimSize(regions, ROWS)

	numChannels = DimSize(channels, ROWS)
	numRegions = DimSize(regions, ROWS)
	for(i = 0; i < numChannels; i += 1)
		channelNumber = channels[i]
		for(j = 0; j < numRegions; j += 1)
			region = regions[j]

			activeChanCount = i + 1
			activeRegionCount = j + 1
			graph = PA_GetGraph(win, pa, displayMode, channelNumber, region, activeRegionCount, activeChanCount, numRegions)
			[vertAxis, horizAxis] = PA_GetAxes(pa, activeRegionCount, activeChanCount)

			if(!pa.multipleGraphs && activeChanCount == 1 && activeRegionCount == 1 || pa.multipleGraphs)
				NewFreeAxis/R/O/W=$graph fakeAxis
				ModifyFreeAxis/W=$graph fakeAxis, master=$horizAxis, hook=PA_AxisHook
				ModifyGraph/W=$graph nticks(fakeAxis)=0, noLabel(fakeAxis)=2, axthick(fakeAxis)=0
				SetDrawLayer/K/W=$graph $PA_DRAWLAYER_SCALEBAR
			endif

			WAVE/WAVE/Z setWaves = PA_GetSetWaves(pulseAverageHelperDFR, channelNumber, region)

			if(!WaveExists(setWaves))
				continue
			endif

			baseName = PA_BaseName(channelNumber, region)
			WAVE/Z averageWave = PA_Average(setWaves, pulseAverageDFR, PA_AVERAGE_WAVE_PREFIX + baseName, noCalculation=1)

			if(WaveExists(averageWave))
				maximum = GetNumberFromWaveNote(averageWave, "WaveMaximum")
				length  = pa.yScaleBarLength * (IsFinite(maximum) ? sign(maximum) : +1)
				xUnit   = WaveUnits(averageWave, ROWS)
				yUnit   = WaveUnits(averageWave, -1)
			else
				length = pa.yScaleBarLength
				xUnit  = "n. a."
				yUnit  = "n. a."
			endif

			PA_DrawScaleBarsHelper(graph, axisMode, displayMode, setWaves, vertAxis, horizAxis, length, xUnit, yUnit, \
			                       activeChanCount, numChannels, activeRegionCount, numRegions)
		endfor
	endfor
End

static Function	[variable vert_min, variable vert_max, variable horiz_min, variable horiz_max] PA_GetMinAndMax(WAVE/WAVE setWaves)

	Make/D/FREE/N=(DimSize(setWaves, ROWS)) vertDataMin = GetNumberFromWaveNote(setWaves[p], "WaveMinimum")
	Make/D/FREE/N=(DimSize(setWaves, ROWS)) vertDataMax = GetNumberFromWaveNote(setWaves[p], "WaveMaximum")

	Make/D/FREE/N=(DimSize(setWaves, ROWS)) horizDataMin = leftx(setWaves[p])
	Make/D/FREE/N=(DimSize(setWaves, ROWS)) horizDataMax = pnt2x(setWaves[p], DimSize(setWaves[p], ROWS) - 1)

	return [WaveMin(vertDataMin), WaveMax(vertDataMax), WaveMin(horizDataMin), WaveMax(horizDataMax)]
End

static Function PA_DrawScaleBarsHelper(string win, variable axisMode, variable displayMode, WAVE/WAVE setWaves, string vertAxis, string horizAxis, variable ylength, string xUnit, string yUnit, variable activeChanCount, variable numChannels, variable activeRegionCount, variable numRegions)

	string graph, msg, str, axList
	variable vertAxis_y, vertAxis_x, xLength
	variable vert_min, vert_max, horiz_min, horiz_max, drawLength
	variable xBarBottom, xBarTop, yBarBottom, yBarTop, labelOffset
	variable xBarLeft, xBarRight, yBarLeft, yBarRight, drawXScaleBar, drawYScaleBar

	drawXScaleBar = (activeChanCount == numChannels)
	drawYScaleBar = (activeChanCount != activeRegionCount) && (displayMode != PA_DISPLAYMODE_IMAGES)

	if(!drawXScaleBar && !drawYScaleBar)
		return NaN
	endif

	graph = GetMainWindow(win)

	switch(axisMode)
		case PA_USE_WAVE_SCALES:
			switch(displayMode)
				case PA_DISPLAYMODE_TRACES:
					[vert_min, vert_max, horiz_min, horiz_max] = PA_GetMinAndMax(setWaves)
					break
				case PA_DISPLAYMODE_IMAGES:
					[vert_min, vert_max, horiz_min, horiz_max] = PA_GetMinAndMax(setWaves)
					vert_min = -0.5
					vert_max = NaN
					break
				default:
					ASSERT(0, "Invalid display mode")
			endswitch
			break
		case PA_USE_AXIS_SCALES:
			[vert_min, vert_max] = GetAxisRange(graph, vertAxis, mode=AXIS_RANGE_INC_AUTOSCALED)
			[horiz_min, horiz_max] = GetAxisRange(graph, horizAxis, mode=AXIS_RANGE_INC_AUTOSCALED)
			break
		default:
			ASSERT(0, "Unknown mode")
	endswitch

	SetDrawEnv/W=$graph push
	SetDrawEnv/W=$graph linefgc=(0,0,0), textrgb=(0,0,0), fsize=10, linethick=1.5

	if(drawYScaleBar)
		// only for non-diagonal elements

		// Y scale

		SetDrawEnv/W=$graph xcoord=prel, ycoord=$vertAxis
		SetDrawEnv/W=$graph save

		labelOffset = 0.005

		sprintf str, "scalebar_Y_R%d_C%d", activeRegionCount, activeChanCount
		SetDrawEnv/W=$graph gstart, gname=$str

		xBarBottom = GetNumFromModifyStr(AxisInfo(graph, horizAxis), "axisEnab", "{", 0) - PA_X_AXIS_OFFSET
		xBarTop    = xBarBottom
		yBarBottom = 0
		yBarTop    = ylength

		sprintf msg, "Y: (R%d, C%d)\r", activeRegionCount, activeChanCount
		DEBUGPRINT(msg)

		drawLength = (activeChanCount == numChannels) && (activeRegionCount == 1)

		DrawScaleBar(graph, xBarBottom, yBarBottom, xBarTop, yBarTop, unit=yUnit, drawLength=drawLength, labelOffset=labelOffset, newlineBeforeUnit=1)

		SetDrawEnv/W=$graph gstop
	endif

	if(drawXScaleBar)

		axList = AxisList(graph)
		ASSERT(WhichListItem(horizAxis, axList) != -1, "Missing horizontal axis")
		ASSERT(WhichListItem(vertAxis, axList) != -1, "Missing vertical axis")

		SetDrawEnv/W=$graph xcoord=$horizAxis, ycoord=$vertAxis
		SetDrawEnv/W=$graph save

		// X scale

		sprintf str, "scalebar_X_R%d_C%d", activeRegionCount, activeChanCount
		SetDrawEnv/W=$graph gstart, gname=$str

		xLength = CalculateNiceLength(0.10 * abs(horiz_max - horiz_min), 5)

		xBarRight = horiz_max
		xBarLeft  = horiz_max - xLength
		yBarLeft  = vert_min
		yBarRight = yBarLeft

		sprintf msg, "X: (R%d, C%d)\r", activeRegionCount, activeChanCount
		DEBUGPRINT(msg)

		drawLength = (activeChanCount == numChannels) && (activeRegionCount == numRegions)

		DrawScaleBar(graph, xBarLeft, yBarLeft, xBarRight, yBarRight, unit=xUnit, drawLength=drawLength)

		SetDrawEnv/W=$graph gstop
	endif

	SetDrawEnv/W=$graph pop
End

static Function PA_PulseHasFailed(WAVE singlePulseWave, STRUCT PulseAverageSettings &s)

	variable level, hasFailed

	if(!s.searchFailedPulses)
		return 0
	endif

	level     = GetNumberFromWaveNote(singlePulseWave, NOTE_KEY_FAILED_PULSE_LEVEL)
	hasFailed = GetNumberFromWaveNote(singlePulseWave, PA_NOTE_KEY_PULSE_FAILED)

	if(level == s.failedPulsesLevel && IsFinite(hasFailed))
		// already investigated
		return hasFailed
	endif

	ASSERT(GetNumberFromWaveNote(singlePulseWave, NOTE_KEY_ZEROED) != 1, "Single pulse wave must not be zeroed here")

	level = s.failedPulsesLevel

	hasFailed = !(level >= GetNumberFromWaveNote(singlePulseWave, "WaveMinimum")     \
	              && level <= GetNumberFromWaveNote(singlePulseWave, "WaveMaximum"))

	SetNumberInWaveNote(singlePulseWave, PA_NOTE_KEY_PULSE_FAILED, hasFailed)
	// NOTE_KEY_FAILED_PULSE_LEVEL is written in PA_MarkFailedPulses for all pulses

	return hasFailed
End

/// @brief Generate the wave name for a single pulse
Function/S PA_GeneratePulseWaveName(variable channelType, variable channelNumber, variable region, variable pulseIndex)
	ASSERT(channelType < ItemsInList(ITC_CHANNEL_NAMES), "Invalid channel type")
	ASSERT(channelNumber < GetNumberFromType(itcVar=channelType) , "Invalid channel number")
	ASSERT(IsInteger(pulseIndex) && pulseIndex >= 0, "Invalid pulseIndex")

	return StringFromList(channelType, ITC_CHANNEL_NAMES) + num2str(channelNumber) + \
	       "_R" + num2str(region) + "_P" + num2str(pulseIndex)
End

/// @brief Generate a static base name for objects in the current averaging folder
static Function/S PA_BaseName(channelNumber, headStage)
	variable channelNumber, headStage

	string baseName
	baseName = "AD" + num2str(channelNumber)
	baseName += "_HS" + num2str(headStage)

	return baseName
End

/// @brief Zero single pulses using @c ZeroWave
static Function PA_ZeroPulses(WAVE/WAVE set, STRUCT PulseAverageSettings &pa)

	if(!pa.zeroPulses)
		return NaN
	endif

	Make/FREE/N=(DimSize(set, ROWS)) junkWave
	MultiThread junkWave = ZeroWave(set[p]) && PA_UpdateMinAndMax(set[p])
End

/// @brief calculate the average wave from a @p listOfWaves
///
/// Note: MIES_fWaveAverage() usually takes 5 times longer than CA_AveragingKey()
///
/// @returns wave reference to the average wave specified by @p outputDFR and @p outputWaveName
static Function/WAVE PA_Average(WAVE/WAVE set, DFREF outputDFR, string outputWaveName, [WAVE inputAverage, variable noCalculation])

	if(!ParamIsDefault(noCalculation))
		WAVE/Z/SDFR=outputDFR averageWave = $outputWaveName
		return averageWave
	endif

	if(ParamIsDefault(inputAverage))
		return CalculateAverage(set, outputDFR, outputWaveName, skipCRC = 1, writeSourcePaths = 0)
	else
		return CalculateAverage(set, outputDFR, outputWaveName, skipCRC = 1, writeSourcePaths = 0, inputAverage = inputAverage)
	endif
End

static Function/WAVE PA_SmoothDeconv(input, deconvolution)
	WAVE input
	STRUCT PulseAverageDeconvSettings &deconvolution

	variable range_pnts, smoothingFactor
	string key

	range_pnts = deconvolution.range / DimDelta(input, ROWS)
	smoothingFactor = max(min(deconvolution.smth, 32767), 1)

	key = CA_SmoothDeconv(input, smoothingFactor, range_pnts)
	WAVE/Z cache = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)
	if(WaveExists(cache))
		return cache
	endif

	Duplicate/FREE/R=[0, range_pnts] input wv
	Smooth smoothingFactor, wv

	CA_StoreEntryIntoCache(key, wv)
	return wv
End

static Function/WAVE PA_Deconvolution(average, outputDFR, outputWaveName, deconvolution)
	WAVE average
	DFREF outputDFR
	string outputWaveName
	STRUCT PulseAverageDeconvSettings &deconvolution

	variable step
	string key

	WAVE smoothed = PA_SmoothDeconv(average, deconvolution)

	key = CA_Deconv(smoothed, deconvolution.tau)
	WAVE/Z cache = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)
	if(WaveExists(cache))
		Duplicate/O cache outputDFR:$outputWaveName/WAVE=wv
		return wv
	endif

	Duplicate/O/R=[0, DimSize(smoothed, ROWS) - 2] smoothed outputDFR:$outputWaveName/WAVE=wv
	step = deconvolution.tau / DimDelta(average, 0)
	MultiThread wv = step * (smoothed[p + 1] - smoothed[p]) + smoothed[p]

	CA_StoreEntryIntoCache(key, wv)
	return wv
End

Function PA_CheckProc_Common(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			PA_Update(cba.win, POST_PLOT_CONSTANT_SWEEPS)
			break
	endswitch

	return 0
End

Function PA_CheckProc_Deconvolution(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			PA_UpdateDeconvolution(cba.win)
			break
	endswitch

	return 0
End

Function PA_SetVarProc_Common(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch(sva.eventCode)
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			PA_Update(sva.win, POST_PLOT_CONSTANT_SWEEPS)
			break
	endswitch

	return 0
End

Function PA_PopMenuProc_ColorScale(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch(pa.eventCode)
		case 2: // mouse up
			PA_SetColorScale(pa.win, pa.popStr)
			break
	endswitch

	return 0
End

Function PA_PopMenuProc_Common(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch(pa.eventCode)
		case 2: // mouse up
			PA_Update(pa.win, POST_PLOT_CONSTANT_SWEEPS)
			break
	endswitch

	return 0
End

static Function PA_UpdateDeconvolution(win)
	string win

	string graph, graphs, horizAxis, vertAxis
	string traceName, fullPath, avgTrace
	string baseName
	variable i, numGraphs, j, numTraces, traceIndex
	variable graphDataIndex, lblTRACES_DECONV, lblTRACECOUNT
	STRUCT PulseAverageSettings pa
	PA_GatherSettings(win, pa)

	if(!pa.enabled)
		return NaN
	endif

	if(pa.showImages)
		STRUCT PA_ConstantSettings cs
		PA_ShowImage(win, pa, cs, $"", $"", POST_PLOT_FULL_UPDATE, $"")
	endif

	if(!pa.showTraces)
		return NaN
	endif

	graphs = PA_GetGraphs(win, PA_DISPLAYMODE_TRACES)

	WAVE/T graphData = GetPAGraphData()
	lblTRACES_DECONV = FindDimLabel(graphData, COLS, "TRACES_DECONV")
	lblTRACECOUNT = FindDimLabel(graphData, COLS, "TRACECOUNT")
	numGraphs = ItemsInList(graphs)
	for(i = 0; i < numGraphs; i += 1)
		graph = StringFromList(i, graphs)

		if(pa.deconvolution.enable)
			[graphDataIndex, traceIndex] = PA_GetTraceCountFromGraphData(graph)
			WAVE/T traces = ListToTextWave(graphData[graphDataIndex][%TRACES_AVERAGEFORDECONV], ";")
			WAVE/T horizAxes = ListToTextWave(graphData[graphDataIndex][%TRACES_AVERAGE_XAXIS], ";")
			WAVE/T vertAxes = ListToTextWave(graphData[graphDataIndex][%TRACES_AVERAGE_YAXIS], ";")
			WAVE/T avgWaves = ListToTextWave(graphData[graphDataIndex][%TRACES_AVERAGE_WAVES], ";")
			numTraces = DimSize(traces, ROWS)
			graphData[graphDataIndex][lblTRACES_DECONV] = ""
			for(j = 0; j < numTraces; j += 1)
				avgTrace = traces[j]

				vertAxis = vertAxes[j]
				horizAxis = horizAxes[j]
				fullPath = avgWaves[j]
				WAVE averageWave = $fullPath
				DFREF pulseAverageDFR = GetWavesDataFolderDFR(averageWave)

				SplitString/E=(PA_AVERAGE_WAVE_PREFIX + "(.*)") NameOfWave(averageWave), baseName
				ASSERT(V_flag == 1, "Unexpected Trace Name")

				sprintf traceName, "T%0*d%s%s", TRACE_NAME_NUM_DIGITS, traceIndex, PA_DECONVOLUTION_WAVE_PREFIX, baseName
				traceIndex += 1

				WAVE deconv = PA_Deconvolution(averageWave, pulseAverageDFR, traceName, pa.deconvolution)

				AppendToGraph/Q/W=$graph/L=$vertAxis/B=$horizAxis/C=(0,0,0) deconv/TN=$traceName
				ModifyGraph/W=$graph lsize($traceName)=2

				graphData[graphDataIndex][lblTRACECOUNT] = num2istr(traceIndex)
				graphData[graphDataIndex][lblTRACES_DECONV] = AddListItem(traceName, graphData[graphDataIndex][lblTRACES_DECONV], ";", Inf)
			endfor
		else // !pa.deconvolution.enable
			WAVE/T traces = ListToTextWave(graphData[%$graph][lblTRACES_DECONV], ";")
			numTraces = DimSize(traces, ROWS)
			for(j = 0; j < numTraces; j += 1)
				traceName = traces[j]

				RemoveFromGraph/W=$graph $traceName
			endfor
			graphData[graphDataIndex][lblTRACECOUNT] = num2istr(str2num(graphData[graphDataIndex][lblTRACECOUNT]) - numTraces)
			graphData[%$graph][lblTRACES_DECONV] = ""
		endif
	endfor
End

/// @brief Time alignment for PA single pulses
///
/// \rst
/// See :ref:`db_paplot_timealignment` for an explanation of the algorithm.
/// \endrst
static Function PA_AutomaticTimeAlignment(string win, STRUCT PulseAverageSettings& pa)

	variable i, j, numChannels, numRegions, jsonID, numEntries
	variable region, channelNumber

	if(!pa.autoTimeAlignment)
		return NaN
	endif

	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)
	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)
	WAVE/WAVE propertiesWaves = GetPulseAveragePropertiesWaves(pulseAverageHelperDFR)

	WAVE channels = ListToNumericWave(GetStringFromWaveNote(properties, "Channels"), ",")
	numChannels = DimSize(channels, ROWS)

	WAVE regions = ListToNumericWave(GetStringFromWaveNote(properties, "Regions"), ",")
	numRegions = DimSize(regions, ROWS)

	ASSERT(numChannels == numRegions, "Non-square input")

	jsonID = JSON_New()

	for(i = 0; i < numRegions; i += 1)
		region = regions[i]
		// diagonal element for the given region
		channelNumber = channels[i]

		// gather feature positions for all pulses diagonal set
		WAVE setIndizes = GetPulseAverageSetIndizes(pulseAverageHelperDFR, channelNumber, region)

		numEntries = GetNumberFromWaveNote(setIndizes, NOTE_INDEX)

		if(numEntries == 0)
			continue
		endif

		Make/D/FREE/N=(numEntries) featurePos, junk

		Multithread featurePos[] = PA_GetFeaturePosition(propertiesWaves[setIndizes[p]])

		Make/FREE/T/N=(numEntries) keys = "/" + num2str(properties[setIndizes[p]][%Sweep]) + "-" + num2str(properties[setIndizes[p]][%Pulse])

		// store featurePos using sweep and pulse combination as key
		junk[] = JSON_SetVariable(jsonID, keys[p], featurePos[p])

		for(j = 0; j < numChannels; j += 1)
			channelNumber = channels[j]
			WAVE setIndizes = GetPulseAverageSetIndizes(pulseAverageHelperDFR, channelNumber, region)

			numEntries = GetNumberFromWaveNote(setIndizes, NOTE_INDEX)

			if(numEntries == 0)
				continue
			endif

			Redimension/N=(numEntries) keys, junk

			Multithread keys[] = "/" + num2str(properties[setIndizes[p]][%Sweep]) + "-" + num2str(properties[setIndizes[p]][%Pulse])
			Multithread junk[] = PA_SetFeaturePosition(propertiesWaves[setIndizes[p]], JSON_GetVariable(jsonID, keys[p], ignoreErr=1))
		endfor
	endfor

	JSON_Release(jsonID)
End

threadsafe static Function PA_GetFeaturePosition(WAVE wv)

	variable featurePos

	featurePos = GetNumberFromWaveNote(wv, "TimeAlignmentFeaturePosition")

	if(IsFinite(featurePos))
		return featurePos
	endif

	WaveStats/M=1/Q wv
	featurePos = V_maxLoc
	SetNumberInWaveNote(wv, "TimeAlignmentFeaturePosition", featurePos, format="%.15g")
	return featurePos
End

threadsafe static Function PA_SetFeaturePosition(WAVE wv, variable featurePos)

	variable offset
	string name

	if(GetNumberFromWaveNote(wv, NOTE_KEY_TIMEALIGN) == 1)
		return NaN
	endif

	name = NameOfWave(wv)

	if(IsNaN(featurePos))
		return NaN
	endif

	offset = -featurePos
	DEBUGPRINT_TS("pulse", str=name)
	DEBUGPRINT_TS("old DimOffset", var=DimOffset(wv, ROWS))
	DEBUGPRINT_TS("new DimOffset", var=DimOffset(wv, ROWS) + offset)
	SetScale/P x, DimOffset(wv, ROWS) + offset, DimDelta(wv, ROWS), wv
	SetNumberInWaveNote(wv, "TimeAlignmentTotalOffset", offset, format="%.15g")
	SetNumberInWaveNote(wv, NOTE_KEY_TIMEALIGN, 1)
End

/// @brief Reset All Waves from a list of waves to its original state if they are outdated
///
// PA waves get an entry to their wave note as soon as they are modified. If
// this entry does not match the current panel selection, they are resetted to
// redo the calculation from the beginning.
//
// @param listOfWaves  A semicolon separated list of full paths to the waves that need to
//                     get tested
// @param pa           Filled PulseAverageSettings structure. @see PA_GatherSettings
static Function PA_ResetWavesIfRequired(WAVE/WAVE wv, STRUCT PulseAverageSettings &pa)
	variable i, statusZero, statusTimeAlign, numEntries, statusSearchFailedPulse
	variable failedPulseLevel

	numEntries = DimSize(wv, ROWS)
	for(i = 0; i < numEntries; i += 1)
		statusZero = GetNumberFromWaveNote(wv[i], NOTE_KEY_ZEROED)
		statusTimeAlign = GetNumberFromWaveNote(wv[i], NOTE_KEY_TIMEALIGN)
		statusSearchFailedPulse = GetNumberFromWaveNote(wv[i], NOTE_KEY_SEARCH_FAILED_PULSE)
		failedPulseLevel = GetNumberFromWaveNote(wv[i], NOTE_KEY_FAILED_PULSE_LEVEL)

		if(statusZero == 0 && statusTimeAlign == 0 && statusSearchFailedPulse == 0)
			continue // wave is unmodified
		endif

		if(statusZero == pa.zeroPulses                          \
		   && statusTimeAlign == pa.autoTimeAlignment           \
		   && statusSearchFailedPulse == pa.searchFailedPulses)

			// when zeroing and failed pulse search is enabled, we always
			// need to reset the waves when the level changes
			if(!(pa.zeroPulses && pa.searchFailedPulses && pa.failedPulsesLevel != failedPulseLevel))
				continue // wave is up to date
			endif
		endif

		ReplaceWaveWithBackup(wv[i], nonExistingBackupIsFatal = 1, keepBackup = 1)
	endfor
End

static Function PA_LayoutGraphs(string win, variable displayMode, WAVE regions, WAVE channels, STRUCT PulseAverageSettings &pa)

	variable i, j, numRegions, numChannels, activeRegionCount, activeChanCount, numPulsesInSet
	variable channelNumber, headstage, region, xStart
	string graph, str, horizAxis, vertAxis
	STRUCT RGBColor s

	numRegions = DimSize(regions, ROWS)
	numChannels = DimSize(channels, ROWS)

	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)

	if(!pa.multipleGraphs)
		graph = PA_GetGraphName(win, pa, displayMode, NaN, NaN)

#ifdef PA_HIDE_AXIS
		ModifyGraph/W=$graph mode=0, nticks=0, noLabel=2, axthick=0
#endif

		if(displayMode == PA_DISPLAYMODE_TRACES)
			ModifyGraph/W=$graph margin(left)=30, margin(top)=20, margin(right)=14, margin(bottom)=14
		elseif(displayMode == PA_DISPLAYMODE_IMAGES)
			ModifyGraph/W=$graph margin=2, margin(right)=10, margin(bottom)=14
		endif

		EquallySpaceAxis(graph, axisRegExp="bottom.*", sortOrder=0, axisOffset=PA_X_AXIS_OFFSET)

		for(i = 0; i < numRegions; i += 1)
			activeRegionCount = i + 1

			EquallySpaceAxis(graph, axisRegExp="left_R" + num2str(activeRegionCount) + ".*", sortOrder=1)

			for(j = 0; j < numChannels; j += 1)

				activeChanCount = j + 1
				[vertAxis, horizAxis] = PA_GetAxes(pa, activeRegionCount, activeChanCount)

				xStart = GetNumFromModifyStr(AxisInfo(graph, horizAxis), "axisEnab", "{", 0)
				ModifyGraph/W=$graph/Z freePos($vertAxis)={xStart - PA_X_AXIS_OFFSET,kwFraction}
			endfor

			ModifyGraph/W=$graph/Z freePos($horizAxis)=0
		endfor

		return NaN
	endif

	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)

	for(i = 0; i < numChannels; i += 1)
		channelNumber = channels[i]
		for(j = 0; j < numRegions; j += 1)
			region = regions[j]

			activeRegionCount = j + 1
			graph = PA_GetGraphName(win, pa, displayMode, channelNumber, activeRegionCount)

			WAVE setIndizes = GetPulseAverageSetIndizes(pulseAverageHelperDFR, channelNumber, region)
			numPulsesInSet = GetnumberFromWaveNote(setIndizes, NOTE_INDEX)

			Make/FREE/N=(numPulsesInSet) pulsesNonUnique = properties[setIndizes[p]][%Pulse]
			WAVE pulses = GetUniqueEntries(pulsesNonUnique)

			Make/FREE/N=(numPulsesInSet) sweepsNonUnique = properties[setIndizes[p]][%Sweep]
			WAVE sweeps = GetUniqueEntries(sweepsNonUnique)

			Make/FREE/N=(numPulsesInSet) headstagesNonUnique = properties[setIndizes[p]][%Headstage]
			WAVE headstages = GetUniqueEntries(headstagesNonUnique)
			ASSERT(DimSize(headstages, ROWS) == 1, "Invalid number of distinct headstages")

			headstage = headstages[0]

			sprintf str, "\\Z08\\Zr075#Pulses %g / #Swps. %d", DimSize(pulses, ROWS), DimSize(sweeps, ROWS)
			Textbox/W=$graph/C/N=leg/X=-5.00/Y=-5.00 str

			[s] = GetTraceColor(headstage)
			sprintf str, "\\k(%d, %d, %d)\\K(%d, %d, %d)\\W555\\k(0, 0, 0)\\K(0, 0, 0)", s.red, s.green, s.blue, s.red, s.green, s.blue

			sprintf str, "AD%d / Reg. %d HS%s", channelNumber, region, str
			AppendText/W=$graph str

#ifdef PA_HIDE_AXIS
			ModifyGraph/W=$graph mode=0, nticks=0, noLabel=2, axthick=0, margin=5
#endif
			ModifyGraph/W=$graph/Z freePos(bottom)=0
		endfor
	endfor
End

static Function PA_AddColorScales(string win, WAVE regions, WAVE channels, STRUCT PulseAverageSettings &pa)

	string name, text, graph, vertAxis, horizAxis, traceName, msg, colorScaleGraph, imageGraph
	variable i, j, numRegions, numChannels, scaleDiag, scaleRows, region, channelNumber, activeRegionCount, activeChanCount
	variable minimumDiag, maximumDiag, minimum, maximum, isDiagonalElement, yPos, lastEntry
	variable numSlots, numEntries, headstage
	string graphsToResize = ""

	numRegions = DimSize(regions, ROWS)
	numChannels = DimSize(channels, ROWS)

	DFREF pulseAverageDFR = GetDevicePulseAverageFolder(pa.dfr)
	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)
	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)

	minimumDiag = Inf
	maximumDiag = -Inf

	Make/FREE/D/N=(numChannels) minimumRows = Inf
	Make/FREE/D/N=(numChannels) maximumRows = -Inf

	for(i = 0; i < numRegions; i += 1)
		region = regions[i]
		activeRegionCount = i + 1

		for(j = 0; j < numChannels; j += 1)
			channelNumber = channels[j]
			activeChanCount = j + 1

			isDiagonalElement = (activeRegionCount == activeChanCount)

			if(!pa.multipleGraphs && i == 0 && j == 0 || pa.multipleGraphs)
				graph = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, activeRegionCount)
			endif

			[vertAxis, horizAxis] = PA_GetAxes(pa, activeRegionCount, activeChanCount)

			// only show filled in pulses for the vertical axis
			WAVE img = GetPulseAverageSetImageWave(pulseAverageDFR, channelNumber, region)
			lastEntry = GetNumberFromWaveNote(img, NOTE_INDEX)
			GetAxis/Q/W=$graph $vertAxis
			ASSERT(V_flag == 0, "Missing axis")
			SetAxis/W=$graph $vertAxis, -0.5, lastEntry - 0.5

			minimum = GetNumberFromWaveNote(img, "PulsesMinimum")
			maximum = GetNumberFromWaveNote(img, "PulsesMaximum")

			// gather min/max for diagonal and off-diagonal elements
			if(isDiagonalElement)
				minimumDiag = min(minimum, minimumDiag)
				maximumDiag = max(maximum, maximumDiag)
			else
				minimumRows[j] = min(minimum, minimumRows[j])
				maximumRows[j] = max(maximum, maximumRows[j])
			endif
		endfor
	endfor

	if(pa.zeroPulses)
		[minimumDiag, maximumDiag] = SymmetrizeRangeAroundZero(minimumDiag, maximumDiag)

		for(i = 0; i < numChannels; i += 1)
			[minimum, maximum] = SymmetrizeRangeAroundZero(minimumRows[i], maximumRows[i])
			minimumRows[i] = minimum
			maximumRows[i] = maximum
		endfor
	endif

	for(i = 0; i < numRegions; i += 1)
		region = regions[i]
		activeRegionCount = i + 1

		for(j = 0; j < numChannels; j += 1)
			channelNumber = channels[j]
			activeChanCount = j + 1

			if(!pa.multipleGraphs && i == 0 && j == 0 || pa.multipleGraphs)
				graph = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, activeRegionCount)
				graphsToResize = AddListItem(graph, graphsToResize, ";", Inf)
				colorScaleGraph = PA_GetColorScaleGraph(graph)
				if(WindowExists(colorScaleGraph))
					RemoveAnnotationsFromGraph(colorScaleGraph)
				endif
			endif

			isDiagonalElement = (activeRegionCount == activeChanCount)

			if(isDiagonalElement)
				minimum = minimumDiag
				maximum = maximumDiag
			else
				minimum = minimumRows[j]
				maximum = maximumRows[j]
			endif

			WAVE img = GetPulseAverageSetImageWave(pulseAverageDFR, channelNumber, region)
			traceName = NameOfWave(img)

			sprintf msg, "traceName %s, minimum %g, maximum %g\r", traceName, minimum, maximum
			DEBUGPRINT(msg)

			ModifyImage/W=$graph $traceName ctab= {minimum, maximum, $(pa.imageColorScale), 0}, minRGB=0,maxRGB=(65535,0,0)
		endfor
	endfor

	if(pa.showIndividualPulses)
		// add color scale bars

		// Order of color scale bars (from top to bottom)
		//
		// single graph:
		// - first row color scale
		// - second second row color scale
		// - ...
		// - diagonal color scale
		//
		// multiple graphs:
		// - graphs of last region have each one row color scale
		// - but the bottom right graph has also the diagonal color scale

		if(!pa.multipleGraphs)

			// we have numRegions + 1 color scales but only require numRegions slots
			numSlots = numRegions

			for(i = 0; i < numChannels; i += 1)
				channelNumber = channels[i]

				// we always take the last region except for the last channel as that would be diagonal again
				if(i == numChannels - 1)
					region = regions[0]
					activeRegionCount = 1
				else
					region = regions[numRegions - 1]
					activeRegionCount = numRegions
				endif

				WAVE img = GetPulseAverageSetImageWave(pulseAverageDFR, channelNumber, region)
				traceName = NameOfWave(img)

				if(i == 0)
					graph = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, activeRegionCount)
					colorScaleGraph = PA_GetColorScaleGraph(graph)
				endif

				WAVE setIndizes = GetPulseAverageSetIndizes(pulseAverageHelperDFR, channelNumber, region)
				// assume that all pulses are from the same headstage
				headstage = properties[setIndizes[0]][%Headstage]
				ASSERT(IsFinite(headstage), "Invalid headstage")

				name = "colorScale_AD_" + num2str(channelNumber)
				text = "HS" + num2str(headstage) + " (\\U)"
				PA_AddColorScale(graph, colorScaleGraph, name, text, i, numSlots, traceName)
			endfor

			// diagonal color scale
			channelNumber = channels[0]
			region = regions[0]
			activeRegionCount = 1
			graph = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, activeRegionCount)
			colorScaleGraph = PA_GetColorScaleGraph(graph)
			WAVE img = GetPulseAverageSetImageWave(pulseAverageDFR, channelNumber, region)
			traceName = NameOfWave(img)

			name = "colorScaleDiag"
			text = "Diagonal (\\U)"
			PA_AddColorScale(graph, colorScaleGraph, name, text, i - 0.5, numSlots, traceName)
		else
			for(i = 0; i < numChannels; i += 1)
				channelNumber = channels[i]

				// we always take the last region for attaching the color scale bars
				// except for the last channel as that would be diagonal again
				// for the last channel we choose the first region
				// and in that case the color scale bar is also attached to the image from the first region
				// but it is placed in the external subwindow from the last region

				graph = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, numRegions)
				colorScaleGraph = PA_GetColorScaleGraph(graph)
				ASSERT(WindowExists(colorScaleGraph), "Missing external subwindow for color scale")

				if(i == numChannels - 1)
					region = regions[0]
					imageGraph = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, 1)
					numSlots = 2
				else
					region = regions[numRegions - 1]
					graph = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, numRegions)
					imageGraph = graph
					numSlots = 1
				endif

				WAVE setIndizes = GetPulseAverageSetIndizes(pulseAverageHelperDFR, channelNumber, region)
				// assume that all pulses are from the same headstage
				headstage = properties[setIndizes[0]][%Headstage]
				ASSERT(IsFinite(headstage), "Invalid headstage")

				WAVE img = GetPulseAverageSetImageWave(pulseAverageDFR, channelNumber, region)
				traceName = NameOfWave(img)

				name = "colorScale_HS_" + num2str(headstage)
				text = "HS" + num2str(headstage) + "\r(\\U)"
				PA_AddColorScale(imageGraph, colorScaleGraph, name, text, 0, numSlots, traceName)
			endfor

			name = "colorScaleDiag"
			text = "Diagonal\r(\\U)"
			numSlots = 2
			PA_AddColorScale(imageGraph, colorScaleGraph, name, text, 1, numSlots, traceName)
		endif
	endif

	numEntries = ItemsInList(graphsToResize)
	for(i = 0; i < numEntries; i += 1)
		graph = StringFromList(i, graphsToResize)
		PA_ResizeColorScalePanel(graph)
	endfor
End

static Function PA_AddColorScale(string graph, string colorScaleGraph, string name, string text, variable index, variable numSlots, string traceName)

	variable yPos, intIndex, length

	WAVE/Z start, stop
	[start, stop] = DistributeElements(numSlots)

	intIndex = trunc(index)
	length = stop[intIndex] - start[intIndex]
	yPos = start[intIndex] + abs(index - intIndex) * length
	yPos *= 100

	ColorScale/W=$colorScaleGraph/C/N=$name/F=0/A=MT/X=(0)/Y=(yPos)/E=0 vert=0, image={$graph, $traceName}
	ColorScale/W=$colorScaleGraph/C/N=$name heightPct=(5), widthPct=95, lblMargin=0
	AppendText/W=$colorScaleGraph/N=$name text
End

/// @brief Write the PA settings `pa` to the panel user data
/// and return a JSON id with the settings.
///
///
/// @return Valid JSON id, caller must release memory.
static Function PA_SerializeSettings(string win, STRUCT PulseAverageSettings &pa)

	variable jsonID
	string datafolder

	jsonID = JSON_New()

	JSON_AddVariable(jsonID, "/version", PA_SETTINGS_STRUCT_VERSION)

	if(DataFolderExistsDFR(pa.dfr))
		datafolder = GetDataFolder(1, pa.dfr)
	else
		datafolder = ""
	endif

	JSON_AddString(jsonID, "/dfr", datafolder)
	JSON_AddVariable(jsonID, "/enabled", pa.enabled)
	JSON_AddVariable(jsonID, "/showIndividualPulses", pa.showIndividualPulses)
	JSON_AddVariable(jsonID, "/showAverage", pa.showAverage)
	JSON_AddVariable(jsonID, "/startingPulse", pa.startingPulse)
	JSON_AddVariable(jsonID, "/endingPulse", pa.endingPulse)
	JSON_AddVariable(jsonID, "/regionSlider", pa.regionSlider)
	JSON_AddVariable(jsonID, "/overridePulseLength", pa.overridePulseLength)
	JSON_AddVariable(jsonID, "/fixedPulseLength", pa.fixedPulseLength)
	JSON_AddVariable(jsonID, "/multipleGraphs", pa.multipleGraphs)
	JSON_AddVariable(jsonID, "/zeroPulses", pa.zeroPulses)
	JSON_AddVariable(jsonID, "/autoTimeAlignment", pa.autoTimeAlignment)
	JSON_AddVariable(jsonID, "/hideFailedPulses", pa.hideFailedPulses)
	JSON_AddVariable(jsonID, "/searchFailedPulses", pa.searchFailedPulses)
	JSON_AddVariable(jsonID, "/failedPulsesLevel", pa.failedPulsesLevel)
	JSON_AddVariable(jsonID, "/yScaleBarLength", pa.yScaleBarLength)
	JSON_AddVariable(jsonID, "/showImage", pa.showImages)
	JSON_AddVariable(jsonID, "/drawXZeroLine", pa.drawXZeroLine)
	JSON_AddVariable(jsonID, "/pulseSortOrder", pa.pulseSortOrder)
	JSON_AddVariable(jsonID, "/showTraces", pa.showTraces)
	JSON_AddString(jsonID, "/imageColorScale", pa.imageColorScale)
	JSON_AddTreeObject(jsonID, "/deconvolution")
	JSON_AddVariable(jsonID, "/deconvolution/enable", pa.deconvolution.enable)
	JSON_AddVariable(jsonID, "/deconvolution/smth", pa.deconvolution.smth)
	JSON_AddVariable(jsonID, "/deconvolution/tau", pa.deconvolution.tau)
	JSON_AddVariable(jsonID, "/deconvolution/range", pa.deconvolution.range)

	SetWindow $win, userdata($PA_SETTINGS)=JSON_Dump(jsonID, indent = -1)
	return jsonID
End

/// @brief Read the PA settings from the panel user data into
/// `pa` and return a JSON id with the settings.
///
///
/// @return Valid JSON id, caller must release memory, or NaN on error/incompatible struct
static Function PA_DeserializeSettings(string win, STRUCT PulseAverageSettings &pa)

	variable jsonID, version

	jsonID = JSON_Parse(GetUserData(win,"", PA_SETTINGS), ignoreErr=1)

	if(IsNaN(jsonID))
		InitPulseAverageSettings(pa)
		return NaN
	endif

	version = JSON_GetVariable(jsonID, "/version")

	// incompatible version
	if(version != PA_SETTINGS_STRUCT_VERSION)
		JSON_Release(jsonID)
		InitPulseAverageSettings(pa)
		return NaN
	endif

	DFREF pa.dfr            = $JSON_GetString(jsonID, "/dfr")
	pa.enabled              = JSON_GetVariable(jsonID, "/enabled")
	pa.showIndividualPulses = JSON_GetVariable(jsonID, "/showIndividualPulses")
	pa.showAverage          = JSON_GetVariable(jsonID, "/showAverage")
	pa.startingPulse        = JSON_GetVariable(jsonID, "/startingPulse")
	pa.endingPulse          = JSON_GetVariable(jsonID, "/endingPulse")
	pa.regionSlider         = JSON_GetVariable(jsonID, "/regionSlider")
	pa.overridePulseLength  = JSON_GetVariable(jsonID, "/overridePulseLength")
	pa.fixedPulseLength     = JSON_GetVariable(jsonID, "/fixedPulseLength")
	pa.multipleGraphs       = JSON_GetVariable(jsonID, "/multipleGraphs")
	pa.zeroPulses           = JSON_GetVariable(jsonID, "/zeroPulses")
	pa.autoTimeAlignment    = JSON_GetVariable(jsonID, "/autoTimeAlignment")
	pa.hideFailedPulses     = JSON_GetVariable(jsonID, "/hideFailedPulses")
	pa.searchFailedPulses   = JSON_GetVariable(jsonID, "/searchFailedPulses")
	pa.failedPulsesLevel    = JSON_GetVariable(jsonID, "/failedPulsesLevel")
	pa.yScaleBarLength      = JSON_GetVariable(jsonID, "/yScaleBarLength")
	pa.showImages           = JSON_GetVariable(jsonID, "/showImage")
	pa.drawXZeroLine        = JSON_GetVariable(jsonID, "/drawXZeroLine")
	pa.pulseSortOrder       = JSON_GetVariable(jsonID, "/pulseSortOrder")
	pa.showTraces           = JSON_GetVariable(jsonID, "/showTraces")
	pa.imageColorScale      = JSON_GetString(jsonID, "/imageColorScale")
	pa.deconvolution.enable = JSON_GetVariable(jsonID, "/deconvolution/enable")
	pa.deconvolution.smth   = JSON_GetVariable(jsonID, "/deconvolution/smth")
	pa.deconvolution.tau    = JSON_GetVariable(jsonID, "/deconvolution/tau")
	pa.deconvolution.range  = JSON_GetVariable(jsonID, "/deconvolution/range")

	return jsonID
End

static Function/S PA_ShowImage(string win, STRUCT PulseAverageSettings &pa, STRUCT PA_ConstantSettings &cs, WAVE/Z targetForAverageGeneric, WAVE/Z sourceForAverageGeneric, variable mode, WAVE/Z additionalData)

	variable channelNumber, region, numChannels, numRegions, i, j, k, err, isDiagonalElement
	variable activeRegionCount, activeChanCount, requiredEntries, specialEntries, numPulses
	variable singlePulseColumnOffset, failedMarkerStartRow, xPos, yPos, newSweep, numGraphs
	variable vert_min, vert_max, horiz_min, horiz_max, firstPulseIndex
	variable graphDataIndex, junk, lblIMAGELIST
	string vertAxis, horizAxis, graph, basename, imageName, msg, graphWithImage
	string image
	string usedGraphs = ""
	string graphsWithImages = ""

	if(!pa.showImages)
		return usedGraphs
	elseif(cs.images)
		return PA_GetGraphs(win, PA_DISPLAYMODE_IMAGES)
	endif

	WAVE/WAVE/Z targetForAverage = targetForAverageGeneric
	WAVE/WAVE/Z sourceForAverage = sourceForAverageGeneric

	DFREF pulseAverageDFR = GetDevicePulseAverageFolder(pa.dfr)
	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)

	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)
	WAVE/WAVE propertiesWaves = GetPulseAveragePropertiesWaves(pulseAverageHelperDFR)

	WAVE channels = ListToNumericWave(GetStringFromWaveNote(properties, "Channels"), ",")
	numChannels = DimSize(channels, ROWS)

	WAVE regions = ListToNumericWave(GetStringFromWaveNote(properties, "Regions"), ",")
	numRegions = DimSize(regions, ROWS)

	WAVE/T paGraphData = GetPAGraphData()
	lblIMAGELIST = FindDimLabel(paGraphData, COLS, "IMAGELIST")

	for(i = 0; i < numChannels; i += 1)
		channelNumber = channels[i]
		activeChanCount = i + 1

		for(j = 0; j < numRegions; j += 1)
			region = regions[j]
			activeRegionCount = j + 1

			if(WaveExists(targetForAverage))
				WAVE/Z freeAverageWave = targetForAverage[i][j]

				if(WaveExists(freeAverageWave))
					baseName = PA_BaseName(channelNumber, region)
					WAVE averageWave = PA_Average(sourceForAverage[i][j], pulseAverageDFR, PA_AVERAGE_WAVE_PREFIX + baseName, \
					                              inputAverage = freeAverageWave)
				endif

				WaveClear freeAverageWave
			else
				WAVE/WAVE/Z setWaves = PA_GetSetWaves(pulseAverageHelperDFR, channelNumber, region, removeFailedPulses = 1)

				baseName = PA_BaseName(channelNumber, region)
				if(WaveExists(setWaves))
					WAVE averageWave = PA_Average(setWaves, pulseAverageDFR, PA_AVERAGE_WAVE_PREFIX + baseName)
				endif
			endif

			WAVE/WAVE/Z setWaves = PA_GetSetWaves(pulseAverageHelperDFR, channelNumber, region)

			isDiagonalElement = (activeRegionCount == activeChanCount)

			if(!pa.multipleGraphs && i == 0 && j == 0 || pa.multipleGraphs)
				graph = PA_GetGraph(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, region, activeRegionCount, activeChanCount, numRegions)
				graphsWithImages += AddPrefixToEachListItem(graph + "#", ImageNameList(graph, ";"))
				SetDrawLayer/W=$graph/K $PA_DRAWLAYER_FAILED_PULSES
				usedGraphs = AddListItem(graph, usedGraphs, ";", inf)
			endif

			[vertAxis, horizAxis] = PA_GetAxes(pa, activeRegionCount, activeChanCount)

			numPulses = WaveExists(setWaves) ? DimSize(setWaves, ROWS) : 0

			WAVE setIndizes = GetPulseAverageSetIndizes(pulseAverageHelperDFR, channelNumber, region)
			WAVE img = GetPulseAverageSetImageWave(pulseAverageDFR, channelNumber, region)

			// top to bottom:
			// pulses
			// deconvolution
			// average
			//
			// we reserve 5% of the total columns for average and 5% for deconvolution
			singlePulseColumnOffset = GetNumberFromWaveNote(img, PA_NOTE_KEY_IMAGE_COL_OFFSET)
			if(IsNaN(singlePulseColumnOffset) || mode == POST_PLOT_FULL_UPDATE)
				specialEntries  = limit(round(PA_IMAGE_SPECIAL_ENTRIES_RANGE * numPulses), 1, inf)
				singlePulseColumnOffset = 2 * specialEntries
			else
				// keep the existing singlePulseColumnOffset when doing an incremental update
				specialEntries = singlePulseColumnOffset / 2
				ASSERT(IsInteger(specialEntries), "singlePulseColumnOffset is not even.")
			endif

			firstPulseIndex = 0
			requiredEntries = singlePulseColumnOffset + numPulses

			if(numPulses == 0)
				Multithread img[][] = NaN
			else
				WAVE firstPulse = setWaves[0]
				CopyScales/P firstPulse, img

				Make/FREE/N=(MAX_DIMENSION_COUNT) oldSizes = DimSize(img, p)
				EnsureLargeEnoughWave(img, minimumSize = requiredEntries, dimension = COLS, initialValue=NaN)
				Redimension/N=(DimSize(firstPulse, ROWS), -1) img
				Make/FREE/N=(MAX_DIMENSION_COUNT) newSizes = DimSize(img, p)

				if(mode != POST_PLOT_ADDED_SWEEPS                                        \
				   || !EqualWaves(oldSizes, newSizes, 1)                                 \
				   || pa.pulseSortOrder != PA_PULSE_SORTING_ORDER_SWEEP)
					Multithread img[][] = NaN
				else
					// algorithm:
					// we search the entry in setIndizes which has smallest of the new sweeps
					// this does *not* require properties to be sorted,
					// only setIndizes must be sorted in ascending sweep order
					// and then copy everything from firstPulseIndex to requiredEntries - 1 into img
					newSweep = WaveMin(additionalData)
					Make/FREE/N=(numPulses) sweeps = properties[setIndizes[p]][%Sweep]
					FindValue/Z/V=(newSweep) sweeps
					if(V_Value > 0)
						firstPulseIndex = V_Value
					else
						// we can have no match with removed headstages on the new sweep
						// caller needs to retry with POST_PLOT_FULL_UPDATE
						Abort
					endif
					WaveClear sweeps
				endif
			endif

			// @todo axis naming needs to be based on channel numbers and regions and not active indizes
			// when adding a new sweep with more headstages this currently messes up everything

			if(WaveExists(setWaves))
				if(pa.showIndividualPulses && numPulses > 0)
					// img has average and deconvolution in the first singlePulseColumnOffset columns
					// setWaves starts immediately with the pulses
					Multithread img[][singlePulseColumnOffset + firstPulseIndex, requiredEntries - 1] = WaveRef(setWaves[q - singlePulseColumnOffset])(x); err = GetRTError(1)
				endif

				// write min and max of the single pulses into the wave note
				[vert_min, vert_max, horiz_min, horiz_max] = PA_GetMinAndMax(setWaves)
			else
				vert_min = NaN
				vert_max = NaN
			endif

			SetNumberInWaveNote(img, "PulsesMinimum", vert_min)
			SetNumberInWaveNote(img, "PulsesMaximum", vert_max)

			if(pa.showAverage && WaveExists(averageWave))
				// when all pulses from the set fail, we don't have an average wave
				Multithread img[][0, specialEntries - 1] = averageWave(x); err = GetRTError(1)
			endif

			if(pa.deconvolution.enable && !isDiagonalElement && WaveExists(averageWave))
				baseName = PA_BaseName(channelNumber, region)
				WAVE deconv = PA_Deconvolution(averageWave, pulseAverageDFR, PA_DECONVOLUTION_WAVE_PREFIX + baseName, pa.deconvolution)
				Multithread img[][specialEntries, 2 * specialEntries - 1] = limit(deconv(x), vert_min, vert_max); err = GetRTError(1)
			endif

			SetNumberInWaveNote(img, NOTE_INDEX, requiredEntries)
			SetNumberInWaveNote(img, PA_NOTE_KEY_IMAGE_COL_OFFSET, singlePulseColumnOffset)

			imageName = NameOfWave(img)

			sprintf msg, "imageName %s, specialEntries %d, singlePulseColumnOffset %d, requiredEntries %d, firstPulseIndex %d, numPulses %d\r", imageName, specialEntries, singlePulseColumnOffset, requiredEntries, firstPulseIndex, numPulses
			DEBUGPRINT(msg)

			graphsWithImages = RemoveFromList(graph + "#" + imageName, graphsWithImages)

			[graphDataIndex, junk] = PA_GetTraceCountFromGraphData(graph)
			if(WhichListItem(imageName, paGraphData[graphDataIndex][lblIMAGELIST]) == -1)
				AppendImage/W=$graph/L=$vertAxis/B=$horizAxis img
				paGraphData[graphDataIndex][lblIMAGELIST] = AddListItem(imageName, paGraphData[graphDataIndex][lblIMAGELIST])
			endif

			PA_HighligthFailedPulsesInImage(graph, pa, vertAxis, horizAxis, img, properties, setIndizes, numPulses, singlePulseColumnOffset)
		endfor
	endfor

	PA_LayoutGraphs(win, PA_DISPLAYMODE_IMAGES, regions, channels, pa)

	// now remove all images which were left over from previous plots but not referenced anymore
	numGraphs = ItemsInList(graphsWithImages)
	for(i = 0; i < numGraphs; i += 1)
		graphWithImage = StringFromList(i, graphsWithImages)
		graph = StringFromList(0, graphWithImage, "#")
		image = StringFromList(1, graphWithImage, "#")
		RemoveImage/W=$graph $image
	endfor

	PA_DrawScaleBars(win, pa, PA_DISPLAYMODE_IMAGES, PA_USE_WAVE_SCALES)
	PA_AddColorScales(win, regions, channels, pa)
	PA_DrawXZeroLines(win, PA_DISPLAYMODE_IMAGES, regions, channels, pa)

	return usedGraphs
End

static Function PA_HighligthFailedPulsesInImage(string graph, STRUCT PulseAverageSettings &pa, string vertAxis, string horizAxis, WAVE img, WAVE properties, WAVE setIndizes, variable numPulses, variable singlePulseColumnOffset)

	variable failedMarkerStartRow, i, xPos, yPos, fillValue, numFailedPulses

	if(!pa.searchFailedPulses || !pa.showIndividualPulses)
		return NaN
	endif

	if(pa.hideFailedPulses)
		failedMarkerStartRow = 0
		fillValue = NaN
	else
		failedMarkerStartRow = trunc(DimSize(img, ROWS) * 0.9)
		fillValue = Inf
	endif

	for(i = 0; i < numPulses; i += 1)
		if(!properties[setIndizes[i]][%PulseHasFailed])
			continue
		endif

		Multithread img[failedMarkerStartRow, inf][singlePulseColumnOffset + i] = fillValue

		if(!pa.hideFailedPulses)
			if(numFailedPulses == 0)
				SetDrawEnv/W=$graph push
				SetDrawLayer/W=$graph $PA_DRAWLAYER_FAILED_PULSES
				SetDrawEnv/W=$graph xcoord=$horizAxis, ycoord=$vertAxis, textxjust=0, textyjust=1
				SetDrawEnv/W=$graph save
			endif

			xPos = rightx(img)
			yPos = singlePulseColumnOffset + i
			DrawText/W=$graph xPos, yPos, "◅"
		endif

		numFailedPulses += 1
	endfor

	if(numFailedPulses > 0)
		SetDrawEnv/W=$graph pop
	endif
End

/// @brief Apply the given color scale to all PA plot images
static Function PA_SetColorScale(string win, string colScale)

	string graphs, graph, image, images, colorScaleGraph
	string colorScales, annotation, str
	variable i, j, numGraphs, numImages, numAnnotations

	graphs = PA_GetGraphs(win, PA_DISPLAYMODE_IMAGES)
	numGraphs = ItemsInList(graphs)

	for(i = 0; i < numGraphs; i += 1)
		graph = StringFromList(i, graphs)

		images = ImageNameList(graph, ";")
		numImages = ItemsInList(images)
		for(j = 0; j < numImages; j += 1)
			image = StringFromList(j, images)
			ModifyImage/W=$graph $image ctab={,,$colScale,0}
		endfor

#if (NumberByKey("BUILD", IgorInfo(0)) < 36300)
		// workaround IP bug where the color scale is not updated
		colorScaleGraph = PA_GetColorScaleGraph(graph)
		colorScales = AnnotationList(colorScaleGraph)
		numAnnotations = ItemsInList(colorScales)
		for(j = 0; j < numAnnotations; j += 1)
			str = StringFromList(j, colorScales)
			ColorScale/C/N=$str/W=$colorScaleGraph
		endfor
#endif
	endfor
End

/// @brief Adjust the size of the panel with the color scale graph
static Function PA_ResizeColorScalePanel(string imageGraph)

	variable numColorScales, graphHeight
	string colorScalePanel, colorScaleGraph

	colorScalePanel = PA_GetColorScalePanel(imageGraph)

	// for multiple graphs not every graph has a color scale panel
	if(!WindowExists(colorScalePanel))
		return NaN
	endif

	colorScaleGraph = PA_GetColorScaleGraph(imageGraph)

	numColorScales = ItemsInList(AnnotationList(colorScaleGraph))

	if(!numColorScales)
		return NaN
	endif

	GetWindow $imageGraph, wsizeDC

	// height in points of image graph
	// 5 compensates for a poorly understood difference
	graphHeight = V_bottom - V_top + 5

	MoveSubWindow/W=$colorScalePanel fnum=(0, 0, PA_COLORSCALE_PANEL_WIDTH, graphHeight)
End

Function PA_ImageWindowHook(s)
	STRUCT WMWinHookStruct &s

	string imageGraph, browser

	switch(s.eventcode)
		case 6: // resize
			imageGraph = s.winName
			PA_ResizeColorScalePanel(imageGraph)
			return 1
			break
	endswitch

	return 0
End

static Function PA_DrawXZeroLines(string win, variable displayMode, WAVE regions, WAVE channels, STRUCT PulseAverageSettings &pa)

	variable i, j, numChannels, numRegions, channelNumber, activeChanCount, activeRegionCount, region
	string vertAxis, horizAxis, graph

	numChannels = DimSize(channels, ROWS)
	numRegions = DimSize(regions, ROWS)

	for(i = 0; i < numChannels; i += 1)
		channelNumber = channels[i]
		activeChanCount = i + 1

		for(j = 0; j < numRegions; j += 1)
			region = regions[j]
			activeRegionCount = j + 1

			if(!pa.multipleGraphs && i == 0 && j == 0 || pa.multipleGraphs)
				graph = PA_GetGraph(win, pa, displayMode, channelNumber, region, activeRegionCount, activeChanCount, numRegions)
				SetDrawLayer/W=$graph/K $PA_DRAWLAYER_XZEROLINE
			endif

			if(!pa.drawXZeroLine)
				if(!pa.multipleGraphs)
					return NaN
				endif

				continue
			endif

			[vertAxis, horizAxis] = PA_GetAxes(pa, activeRegionCount, activeChanCount)

			SetDrawEnv/W=$graph push
			SetDrawEnv/W=$graph xcoord=$horizAxis, ycoord=rel, dash=1
			SetDrawEnv/W=$graph save
			DrawLine/W=$graph 0,0,0,1
			SetDrawEnv/W=$graph pop
		endfor
	endfor
End

///@brief Runs through all graph groups in the json and appends them to the graph
static Function PA_AccelerateAppendTraces(variable jsonID, WAVE/WAVE plotWaves)

	string graph, vertAxis, horizAxis, redStr, greenStr, blueStr, alphaStr, stepStr
	variable numGraphs, numVertAxis, numHorizAxis, numRed, numGreen, numBlue, numAlpha, numStep
	variable red, green, blue, alpha, step
	variable i0, i1, i2, i3, i4, i5, i6, i7
	string i0Path, i1Path, i2Path, i3Path, i4Path, i5Path, i6Path, i7Path

	WAVE/T wGraphs = JSON_GetKeys(jsonID, "")
	numGraphs = DimSize(wGraphs, ROWS)
	for(i0 = 0; i0 < numGraphs; i0 += 1)
		graph = wGraphs[i0]
		i0Path = "/" + graph
		WAVE/T wVertAxis = JSON_GetKeys(jsonID, i0Path)
		numVertAxis = DimSize(wVertAxis, ROWS)
		for(i1 = 0; i1 < numVertAxis; i1 += 1)
			vertAxis = wVertAxis[i1]
			i1Path = i0Path + "/" + vertAxis
			WAVE/T wHorizAxis = JSON_GetKeys(jsonID, i1Path)
			numHorizAxis = DimSize(wHorizAxis, ROWS)
			for(i2 = 0; i2 < numHorizAxis; i2 += 1)
				horizAxis = wHorizAxis[i2]
				i2Path = i1Path + "/" + horizAxis
				WAVE/T wRed = JSON_GetKeys(jsonID, i2Path)
				numRed = DimSize(wRed, ROWS)
				for(i3 = 0; i3 < numRed; i3 += 1)
					redStr = wRed[i3]
					red = str2num(redStr)
					i3Path = i2Path + "/" + redStr
					WAVE/T wGreen = JSON_GetKeys(jsonID, i3Path)
					numGreen = DimSize(wGreen, ROWS)
					for(i4 = 0; i4 < numGreen; i4 += 1)
						greenStr = wGreen[i4]
						green = str2num(greenStr)
						i4Path = i3Path + "/" + greenStr
						WAVE/T wBlue = JSON_GetKeys(jsonID, i4Path)
						numBlue = DimSize(wBlue, ROWS)
						for(i5 = 0; i5 < numBlue; i5 += 1)
							blueStr = wBlue[i5]
							blue = str2num(blueStr)
							i5Path = i4Path + "/" + blueStr
							WAVE/T wAlpha = JSON_GetKeys(jsonID, i5Path)
							numAlpha = DimSize(wAlpha, ROWS)
							for(i6 = 0; i6 < numAlpha; i6 += 1)
								alphaStr = wAlpha[i6]
								alpha = str2num(alphaStr)
								i6Path = i5Path + "/" + alphaStr
								WAVE/T wStep = JSON_GetKeys(jsonID, i6Path)
								numStep = DimSize(wStep, ROWS)
								for(i7 = 0; i7 < numStep; i7 += 1)
									stepStr = wStep[i7]
									i7Path = i6Path + "/" + stepStr
									WAVE indices = JSON_GetWave(jsonID, i7Path + "/index")
									WAVE/T traceNames = JSON_GetTextWave(jsonID, i7Path + "/traceName")
									PA_AccelerateAppendTracesImpl(graph, vertAxis, horizAxis, red, green, blue, alpha, str2num(stepStr), indices, traceNames, plotWaves)
								endfor
							endfor
						endfor
					endfor
				endfor
			endfor
		endfor
	endfor
End

///@brief Appends a group of traces to a graph, properties v to s must be constant for the group
///@param[in] w name of graph window
///@param[in] v name of vertical axis
///@param[in] h name of horizontal axis
///@param[in] r red color component
///@param[in] g green color component
///@param[in] b blue color component
///@param[in] a alpha component
///@param[in] s step width of graph display
///@param[in] y 1D wave with indices into wave d for the actual plot data
///@param[in] t 1D wave with trace names, same size as y
///@param[in] d wave reference wave with plot data
static Function PA_AccelerateAppendTracesImpl(string w, string v, string h, variable r, variable g, variable b, variable a, variable s, WAVE y, WAVE/T t, WAVE/WAVE d)

	variable step, i
	i = DimSize(y, ROWS)
	if(s > 1)
		do
			step = min(2 ^ trunc(log(i) / log(2)), 100)
			i -= step
			switch(step)
				case 100:
					WAVE aa=d[y[i]];WAVE ab=d[y[i+1]];WAVE ac=d[y[i+2]];WAVE ad=d[y[i+3]];WAVE ae=d[y[i+4]];WAVE af=d[y[i+5]];WAVE ag=d[y[i+6]];WAVE ah=d[y[i+7]];WAVE ai=d[y[i+8]];WAVE aj=d[y[i+9]];WAVE ak=d[y[i+10]];WAVE al=d[y[i+11]];WAVE am=d[y[i+12]];WAVE an=d[y[i+13]];WAVE ap=d[y[i+14]];WAVE aq=d[y[i+15]];WAVE ar=d[y[i+16]];WAVE as=d[y[i+17]];WAVE at=d[y[i+18]];WAVE au=d[y[i+19]];WAVE av=d[y[i+20]];WAVE aw=d[y[i+21]];WAVE ax=d[y[i+22]];WAVE ay=d[y[i+23]];WAVE az=d[y[i+24]];WAVE ba=d[y[i+25]];WAVE bb=d[y[i+26]];WAVE bc=d[y[i+27]];WAVE bd=d[y[i+28]];WAVE be=d[y[i+29]];WAVE bf=d[y[i+30]];WAVE bg=d[y[i+31]];WAVE bh=d[y[i+32]];WAVE bi=d[y[i+33]];WAVE bj=d[y[i+34]];WAVE bk=d[y[i+35]];WAVE bl=d[y[i+36]];WAVE bm=d[y[i+37]];WAVE bn=d[y[i+38]];WAVE bp=d[y[i+39]];WAVE bq=d[y[i+40]];WAVE br=d[y[i+41]];WAVE bs=d[y[i+42]];WAVE bt=d[y[i+43]];WAVE bu=d[y[i+44]];WAVE bv=d[y[i+45]];WAVE bw=d[y[i+46]];WAVE bx=d[y[i+47]];WAVE by=d[y[i+48]];WAVE bz=d[y[i+49]];WAVE ca=d[y[i+50]];WAVE cb=d[y[i+51]];WAVE cc=d[y[i+52]];WAVE cd=d[y[i+53]];WAVE ce=d[y[i+54]];WAVE cf=d[y[i+55]];WAVE cg=d[y[i+56]];WAVE ch=d[y[i+57]];WAVE ci=d[y[i+58]];WAVE cj=d[y[i+59]];WAVE ck=d[y[i+60]];WAVE cl=d[y[i+61]];WAVE cm=d[y[i+62]];WAVE cn=d[y[i+63]];WAVE cp=d[y[i+64]];WAVE cq=d[y[i+65]];WAVE cr=d[y[i+66]];WAVE cs=d[y[i+67]];WAVE ct=d[y[i+68]];WAVE cu=d[y[i+69]];WAVE cv=d[y[i+70]];WAVE cw=d[y[i+71]];WAVE cx=d[y[i+72]];WAVE cy=d[y[i+73]];WAVE cz=d[y[i+74]];WAVE da=d[y[i+75]];WAVE db=d[y[i+76]];WAVE dc=d[y[i+77]];WAVE dd=d[y[i+78]];WAVE de=d[y[i+79]];WAVE df=d[y[i+80]];WAVE dg=d[y[i+81]];WAVE dh=d[y[i+82]];WAVE di=d[y[i+83]];WAVE dj=d[y[i+84]];WAVE dk=d[y[i+85]];WAVE dl=d[y[i+86]];WAVE dm=d[y[i+87]];WAVE dn=d[y[i+88]];WAVE dp=d[y[i+89]];WAVE dq=d[y[i+90]];WAVE dr=d[y[i+91]];WAVE ds=d[y[i+92]];WAVE dt=d[y[i+93]];WAVE du=d[y[i+94]];WAVE dv=d[y[i+95]];WAVE dw=d[y[i+96]];WAVE dx=d[y[i+97]];WAVE dy=d[y[i+98]];WAVE dz=d[y[i+99]]
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) aa[0,*;s]/TN=$t[i],ab[0,*;s]/TN=$t[i+1],ac[0,*;s]/TN=$t[i+2],ad[0,*;s]/TN=$t[i+3],ae[0,*;s]/TN=$t[i+4],af[0,*;s]/TN=$t[i+5],ag[0,*;s]/TN=$t[i+6],ah[0,*;s]/TN=$t[i+7],ai[0,*;s]/TN=$t[i+8],aj[0,*;s]/TN=$t[i+9],ak[0,*;s]/TN=$t[i+10],al[0,*;s]/TN=$t[i+11],am[0,*;s]/TN=$t[i+12],an[0,*;s]/TN=$t[i+13],ap[0,*;s]/TN=$t[i+14],aq[0,*;s]/TN=$t[i+15],ar[0,*;s]/TN=$t[i+16],as[0,*;s]/TN=$t[i+17],at[0,*;s]/TN=$t[i+18],au[0,*;s]/TN=$t[i+19],av[0,*;s]/TN=$t[i+20],aw[0,*;s]/TN=$t[i+21],ax[0,*;s]/TN=$t[i+22],ay[0,*;s]/TN=$t[i+23],az[0,*;s]/TN=$t[i+24],ba[0,*;s]/TN=$t[i+25],bb[0,*;s]/TN=$t[i+26],bc[0,*;s]/TN=$t[i+27],bd[0,*;s]/TN=$t[i+28],be[0,*;s]/TN=$t[i+29],bf[0,*;s]/TN=$t[i+30],bg[0,*;s]/TN=$t[i+31],bh[0,*;s]/TN=$t[i+32],bi[0,*;s]/TN=$t[i+33],bj[0,*;s]/TN=$t[i+34],bk[0,*;s]/TN=$t[i+35],bl[0,*;s]/TN=$t[i+36],bm[0,*;s]/TN=$t[i+37],bn[0,*;s]/TN=$t[i+38],bp[0,*;s]/TN=$t[i+39],bq[0,*;s]/TN=$t[i+40],br[0,*;s]/TN=$t[i+41],bs[0,*;s]/TN=$t[i+42],bt[0,*;s]/TN=$t[i+43],bu[0,*;s]/TN=$t[i+44],bv[0,*;s]/TN=$t[i+45],bw[0,*;s]/TN=$t[i+46],bx[0,*;s]/TN=$t[i+47],by[0,*;s]/TN=$t[i+48],bz[0,*;s]/TN=$t[i+49],ca[0,*;s]/TN=$t[i+50],cb[0,*;s]/TN=$t[i+51],cc[0,*;s]/TN=$t[i+52],cd[0,*;s]/TN=$t[i+53],ce[0,*;s]/TN=$t[i+54],cf[0,*;s]/TN=$t[i+55],cg[0,*;s]/TN=$t[i+56],ch[0,*;s]/TN=$t[i+57],ci[0,*;s]/TN=$t[i+58],cj[0,*;s]/TN=$t[i+59],ck[0,*;s]/TN=$t[i+60],cl[0,*;s]/TN=$t[i+61],cm[0,*;s]/TN=$t[i+62],cn[0,*;s]/TN=$t[i+63],cp[0,*;s]/TN=$t[i+64],cq[0,*;s]/TN=$t[i+65],cr[0,*;s]/TN=$t[i+66],cs[0,*;s]/TN=$t[i+67],ct[0,*;s]/TN=$t[i+68],cu[0,*;s]/TN=$t[i+69],cv[0,*;s]/TN=$t[i+70],cw[0,*;s]/TN=$t[i+71],cx[0,*;s]/TN=$t[i+72],cy[0,*;s]/TN=$t[i+73],cz[0,*;s]/TN=$t[i+74],da[0,*;s]/TN=$t[i+75],db[0,*;s]/TN=$t[i+76],dc[0,*;s]/TN=$t[i+77],dd[0,*;s]/TN=$t[i+78],de[0,*;s]/TN=$t[i+79],df[0,*;s]/TN=$t[i+80],dg[0,*;s]/TN=$t[i+81],dh[0,*;s]/TN=$t[i+82],di[0,*;s]/TN=$t[i+83],dj[0,*;s]/TN=$t[i+84],dk[0,*;s]/TN=$t[i+85],dl[0,*;s]/TN=$t[i+86],dm[0,*;s]/TN=$t[i+87],dn[0,*;s]/TN=$t[i+88],dp[0,*;s]/TN=$t[i+89],dq[0,*;s]/TN=$t[i+90],dr[0,*;s]/TN=$t[i+91],ds[0,*;s]/TN=$t[i+92],dt[0,*;s]/TN=$t[i+93],du[0,*;s]/TN=$t[i+94],dv[0,*;s]/TN=$t[i+95],dw[0,*;s]/TN=$t[i+96],dx[0,*;s]/TN=$t[i+97],dy[0,*;s]/TN=$t[i+98],dz[0,*;s]/TN=$t[i+99]
					break
				case 64:
					WAVE aa=d[y[i]];WAVE ab=d[y[i+1]];WAVE ac=d[y[i+2]];WAVE ad=d[y[i+3]];WAVE ae=d[y[i+4]];WAVE af=d[y[i+5]];WAVE ag=d[y[i+6]];WAVE ah=d[y[i+7]];WAVE ai=d[y[i+8]];WAVE aj=d[y[i+9]];WAVE ak=d[y[i+10]];WAVE al=d[y[i+11]];WAVE am=d[y[i+12]];WAVE an=d[y[i+13]];WAVE ap=d[y[i+14]];WAVE aq=d[y[i+15]];WAVE ar=d[y[i+16]];WAVE as=d[y[i+17]];WAVE at=d[y[i+18]];WAVE au=d[y[i+19]];WAVE av=d[y[i+20]];WAVE aw=d[y[i+21]];WAVE ax=d[y[i+22]];WAVE ay=d[y[i+23]];WAVE az=d[y[i+24]];WAVE ba=d[y[i+25]];WAVE bb=d[y[i+26]];WAVE bc=d[y[i+27]];WAVE bd=d[y[i+28]];WAVE be=d[y[i+29]];WAVE bf=d[y[i+30]];WAVE bg=d[y[i+31]];WAVE bh=d[y[i+32]];WAVE bi=d[y[i+33]];WAVE bj=d[y[i+34]];WAVE bk=d[y[i+35]];WAVE bl=d[y[i+36]];WAVE bm=d[y[i+37]];WAVE bn=d[y[i+38]];WAVE bp=d[y[i+39]];WAVE bq=d[y[i+40]];WAVE br=d[y[i+41]];WAVE bs=d[y[i+42]];WAVE bt=d[y[i+43]];WAVE bu=d[y[i+44]];WAVE bv=d[y[i+45]];WAVE bw=d[y[i+46]];WAVE bx=d[y[i+47]];WAVE by=d[y[i+48]];WAVE bz=d[y[i+49]];WAVE ca=d[y[i+50]];WAVE cb=d[y[i+51]];WAVE cc=d[y[i+52]];WAVE cd=d[y[i+53]];WAVE ce=d[y[i+54]];WAVE cf=d[y[i+55]];WAVE cg=d[y[i+56]];WAVE ch=d[y[i+57]];WAVE ci=d[y[i+58]];WAVE cj=d[y[i+59]];WAVE ck=d[y[i+60]];WAVE cl=d[y[i+61]];WAVE cm=d[y[i+62]];WAVE cn=d[y[i+63]]
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) aa[0,*;s]/TN=$t[i],ab[0,*;s]/TN=$t[i+1],ac[0,*;s]/TN=$t[i+2],ad[0,*;s]/TN=$t[i+3],ae[0,*;s]/TN=$t[i+4],af[0,*;s]/TN=$t[i+5],ag[0,*;s]/TN=$t[i+6],ah[0,*;s]/TN=$t[i+7],ai[0,*;s]/TN=$t[i+8],aj[0,*;s]/TN=$t[i+9],ak[0,*;s]/TN=$t[i+10],al[0,*;s]/TN=$t[i+11],am[0,*;s]/TN=$t[i+12],an[0,*;s]/TN=$t[i+13],ap[0,*;s]/TN=$t[i+14],aq[0,*;s]/TN=$t[i+15],ar[0,*;s]/TN=$t[i+16],as[0,*;s]/TN=$t[i+17],at[0,*;s]/TN=$t[i+18],au[0,*;s]/TN=$t[i+19],av[0,*;s]/TN=$t[i+20],aw[0,*;s]/TN=$t[i+21],ax[0,*;s]/TN=$t[i+22],ay[0,*;s]/TN=$t[i+23],az[0,*;s]/TN=$t[i+24],ba[0,*;s]/TN=$t[i+25],bb[0,*;s]/TN=$t[i+26],bc[0,*;s]/TN=$t[i+27],bd[0,*;s]/TN=$t[i+28],be[0,*;s]/TN=$t[i+29],bf[0,*;s]/TN=$t[i+30],bg[0,*;s]/TN=$t[i+31],bh[0,*;s]/TN=$t[i+32],bi[0,*;s]/TN=$t[i+33],bj[0,*;s]/TN=$t[i+34],bk[0,*;s]/TN=$t[i+35],bl[0,*;s]/TN=$t[i+36],bm[0,*;s]/TN=$t[i+37],bn[0,*;s]/TN=$t[i+38],bp[0,*;s]/TN=$t[i+39],bq[0,*;s]/TN=$t[i+40],br[0,*;s]/TN=$t[i+41],bs[0,*;s]/TN=$t[i+42],bt[0,*;s]/TN=$t[i+43],bu[0,*;s]/TN=$t[i+44],bv[0,*;s]/TN=$t[i+45],bw[0,*;s]/TN=$t[i+46],bx[0,*;s]/TN=$t[i+47],by[0,*;s]/TN=$t[i+48],bz[0,*;s]/TN=$t[i+49],ca[0,*;s]/TN=$t[i+50],cb[0,*;s]/TN=$t[i+51],cc[0,*;s]/TN=$t[i+52],cd[0,*;s]/TN=$t[i+53],ce[0,*;s]/TN=$t[i+54],cf[0,*;s]/TN=$t[i+55],cg[0,*;s]/TN=$t[i+56],ch[0,*;s]/TN=$t[i+57],ci[0,*;s]/TN=$t[i+58],cj[0,*;s]/TN=$t[i+59],ck[0,*;s]/TN=$t[i+60],cl[0,*;s]/TN=$t[i+61],cm[0,*;s]/TN=$t[i+62],cn[0,*;s]/TN=$t[i+63]
					break
				case 32:
					WAVE aa=d[y[i]];WAVE ab=d[y[i+1]];WAVE ac=d[y[i+2]];WAVE ad=d[y[i+3]];WAVE ae=d[y[i+4]];WAVE af=d[y[i+5]];WAVE ag=d[y[i+6]];WAVE ah=d[y[i+7]];WAVE ai=d[y[i+8]];WAVE aj=d[y[i+9]];WAVE ak=d[y[i+10]];WAVE al=d[y[i+11]];WAVE am=d[y[i+12]];WAVE an=d[y[i+13]];WAVE ap=d[y[i+14]];WAVE aq=d[y[i+15]];WAVE ar=d[y[i+16]];WAVE as=d[y[i+17]];WAVE at=d[y[i+18]];WAVE au=d[y[i+19]];WAVE av=d[y[i+20]];WAVE aw=d[y[i+21]];WAVE ax=d[y[i+22]];WAVE ay=d[y[i+23]];WAVE az=d[y[i+24]];WAVE ba=d[y[i+25]];WAVE bb=d[y[i+26]];WAVE bc=d[y[i+27]];WAVE bd=d[y[i+28]];WAVE be=d[y[i+29]];WAVE bf=d[y[i+30]];WAVE bg=d[y[i+31]]
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) aa[0,*;s]/TN=$t[i],ab[0,*;s]/TN=$t[i+1],ac[0,*;s]/TN=$t[i+2],ad[0,*;s]/TN=$t[i+3],ae[0,*;s]/TN=$t[i+4],af[0,*;s]/TN=$t[i+5],ag[0,*;s]/TN=$t[i+6],ah[0,*;s]/TN=$t[i+7],ai[0,*;s]/TN=$t[i+8],aj[0,*;s]/TN=$t[i+9],ak[0,*;s]/TN=$t[i+10],al[0,*;s]/TN=$t[i+11],am[0,*;s]/TN=$t[i+12],an[0,*;s]/TN=$t[i+13],ap[0,*;s]/TN=$t[i+14],aq[0,*;s]/TN=$t[i+15],ar[0,*;s]/TN=$t[i+16],as[0,*;s]/TN=$t[i+17],at[0,*;s]/TN=$t[i+18],au[0,*;s]/TN=$t[i+19],av[0,*;s]/TN=$t[i+20],aw[0,*;s]/TN=$t[i+21],ax[0,*;s]/TN=$t[i+22],ay[0,*;s]/TN=$t[i+23],az[0,*;s]/TN=$t[i+24],ba[0,*;s]/TN=$t[i+25],bb[0,*;s]/TN=$t[i+26],bc[0,*;s]/TN=$t[i+27],bd[0,*;s]/TN=$t[i+28],be[0,*;s]/TN=$t[i+29],bf[0,*;s]/TN=$t[i+30],bg[0,*;s]/TN=$t[i+31]
					break
				case 16:
					WAVE aa=d[y[i]];WAVE ab=d[y[i+1]];WAVE ac=d[y[i+2]];WAVE ad=d[y[i+3]];WAVE ae=d[y[i+4]];WAVE af=d[y[i+5]];WAVE ag=d[y[i+6]];WAVE ah=d[y[i+7]];WAVE ai=d[y[i+8]];WAVE aj=d[y[i+9]];WAVE ak=d[y[i+10]];WAVE al=d[y[i+11]];WAVE am=d[y[i+12]];WAVE an=d[y[i+13]];WAVE ap=d[y[i+14]];WAVE aq=d[y[i+15]]
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) aa[0,*;s]/TN=$t[i],ab[0,*;s]/TN=$t[i+1],ac[0,*;s]/TN=$t[i+2],ad[0,*;s]/TN=$t[i+3],ae[0,*;s]/TN=$t[i+4],af[0,*;s]/TN=$t[i+5],ag[0,*;s]/TN=$t[i+6],ah[0,*;s]/TN=$t[i+7],ai[0,*;s]/TN=$t[i+8],aj[0,*;s]/TN=$t[i+9],ak[0,*;s]/TN=$t[i+10],al[0,*;s]/TN=$t[i+11],am[0,*;s]/TN=$t[i+12],an[0,*;s]/TN=$t[i+13],ap[0,*;s]/TN=$t[i+14],aq[0,*;s]/TN=$t[i+15]
					break
				case 8:
					WAVE aa=d[y[i]];WAVE ab=d[y[i+1]];WAVE ac=d[y[i+2]];WAVE ad=d[y[i+3]];WAVE ae=d[y[i+4]];WAVE af=d[y[i+5]];WAVE ag=d[y[i+6]];WAVE ah=d[y[i+7]]
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) aa[0,*;s]/TN=$t[i],ab[0,*;s]/TN=$t[i+1],ac[0,*;s]/TN=$t[i+2],ad[0,*;s]/TN=$t[i+3],ae[0,*;s]/TN=$t[i+4],af[0,*;s]/TN=$t[i+5],ag[0,*;s]/TN=$t[i+6],ah[0,*;s]/TN=$t[i+7]
					break
				case 4:
					WAVE aa=d[y[i]];WAVE ab=d[y[i+1]];WAVE ac=d[y[i+2]];WAVE ad=d[y[i+3]]
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) aa[0,*;s]/TN=$t[i],ab[0,*;s]/TN=$t[i+1],ac[0,*;s]/TN=$t[i+2],ad[0,*;s]/TN=$t[i+3]
					break
				case 2:
					WAVE aa=d[y[i]];WAVE ab=d[y[i+1]]
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) aa[0,*;s]/TN=$t[i],ab[0,*;s]/TN=$t[i+1]
					break
				case 1:
					WAVE aa=d[y[i]]
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) aa[0,*;s]/TN=$t[i]
					break
				default:
					ASSERT(0, "Fail")
					break
			endswitch
		while(i)
	else
		do
			step = min(2 ^ trunc(log(i) / log(2)), 100)
			i -= step
			switch(step)
				case 100:
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) d[y[i]]/TN=$t[i],d[y[i+1]]/TN=$t[i+1],d[y[i+2]]/TN=$t[i+2],d[y[i+3]]/TN=$t[i+3],d[y[i+4]]/TN=$t[i+4],d[y[i+5]]/TN=$t[i+5],d[y[i+6]]/TN=$t[i+6],d[y[i+7]]/TN=$t[i+7],d[y[i+8]]/TN=$t[i+8],d[y[i+9]]/TN=$t[i+9],d[y[i+10]]/TN=$t[i+10],d[y[i+11]]/TN=$t[i+11],d[y[i+12]]/TN=$t[i+12],d[y[i+13]]/TN=$t[i+13],d[y[i+14]]/TN=$t[i+14],d[y[i+15]]/TN=$t[i+15],d[y[i+16]]/TN=$t[i+16],d[y[i+17]]/TN=$t[i+17],d[y[i+18]]/TN=$t[i+18],d[y[i+19]]/TN=$t[i+19],d[y[i+20]]/TN=$t[i+20],d[y[i+21]]/TN=$t[i+21],d[y[i+22]]/TN=$t[i+22],d[y[i+23]]/TN=$t[i+23],d[y[i+24]]/TN=$t[i+24],d[y[i+25]]/TN=$t[i+25],d[y[i+26]]/TN=$t[i+26],d[y[i+27]]/TN=$t[i+27],d[y[i+28]]/TN=$t[i+28],d[y[i+29]]/TN=$t[i+29],d[y[i+30]]/TN=$t[i+30],d[y[i+31]]/TN=$t[i+31],d[y[i+32]]/TN=$t[i+32],d[y[i+33]]/TN=$t[i+33],d[y[i+34]]/TN=$t[i+34],d[y[i+35]]/TN=$t[i+35],d[y[i+36]]/TN=$t[i+36],d[y[i+37]]/TN=$t[i+37],d[y[i+38]]/TN=$t[i+38],d[y[i+39]]/TN=$t[i+39],d[y[i+40]]/TN=$t[i+40],d[y[i+41]]/TN=$t[i+41],d[y[i+42]]/TN=$t[i+42],d[y[i+43]]/TN=$t[i+43],d[y[i+44]]/TN=$t[i+44],d[y[i+45]]/TN=$t[i+45],d[y[i+46]]/TN=$t[i+46],d[y[i+47]]/TN=$t[i+47],d[y[i+48]]/TN=$t[i+48],d[y[i+49]]/TN=$t[i+49],d[y[i+50]]/TN=$t[i+50],d[y[i+51]]/TN=$t[i+51],d[y[i+52]]/TN=$t[i+52],d[y[i+53]]/TN=$t[i+53],d[y[i+54]]/TN=$t[i+54],d[y[i+55]]/TN=$t[i+55],d[y[i+56]]/TN=$t[i+56],d[y[i+57]]/TN=$t[i+57],d[y[i+58]]/TN=$t[i+58],d[y[i+59]]/TN=$t[i+59],d[y[i+60]]/TN=$t[i+60],d[y[i+61]]/TN=$t[i+61],d[y[i+62]]/TN=$t[i+62],d[y[i+63]]/TN=$t[i+63],d[y[i+64]]/TN=$t[i+64],d[y[i+65]]/TN=$t[i+65],d[y[i+66]]/TN=$t[i+66],d[y[i+67]]/TN=$t[i+67],d[y[i+68]]/TN=$t[i+68],d[y[i+69]]/TN=$t[i+69],d[y[i+70]]/TN=$t[i+70],d[y[i+71]]/TN=$t[i+71],d[y[i+72]]/TN=$t[i+72],d[y[i+73]]/TN=$t[i+73],d[y[i+74]]/TN=$t[i+74],d[y[i+75]]/TN=$t[i+75],d[y[i+76]]/TN=$t[i+76],d[y[i+77]]/TN=$t[i+77],d[y[i+78]]/TN=$t[i+78],d[y[i+79]]/TN=$t[i+79],d[y[i+80]]/TN=$t[i+80],d[y[i+81]]/TN=$t[i+81],d[y[i+82]]/TN=$t[i+82],d[y[i+83]]/TN=$t[i+83],d[y[i+84]]/TN=$t[i+84],d[y[i+85]]/TN=$t[i+85],d[y[i+86]]/TN=$t[i+86],d[y[i+87]]/TN=$t[i+87],d[y[i+88]]/TN=$t[i+88],d[y[i+89]]/TN=$t[i+89],d[y[i+90]]/TN=$t[i+90],d[y[i+91]]/TN=$t[i+91],d[y[i+92]]/TN=$t[i+92],d[y[i+93]]/TN=$t[i+93],d[y[i+94]]/TN=$t[i+94],d[y[i+95]]/TN=$t[i+95],d[y[i+96]]/TN=$t[i+96],d[y[i+97]]/TN=$t[i+97],d[y[i+98]]/TN=$t[i+98],d[y[i+99]]/TN=$t[i+99]
					break
				case 64:
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) d[y[i]]/TN=$t[i],d[y[i+1]]/TN=$t[i+1],d[y[i+2]]/TN=$t[i+2],d[y[i+3]]/TN=$t[i+3],d[y[i+4]]/TN=$t[i+4],d[y[i+5]]/TN=$t[i+5],d[y[i+6]]/TN=$t[i+6],d[y[i+7]]/TN=$t[i+7],d[y[i+8]]/TN=$t[i+8],d[y[i+9]]/TN=$t[i+9],d[y[i+10]]/TN=$t[i+10],d[y[i+11]]/TN=$t[i+11],d[y[i+12]]/TN=$t[i+12],d[y[i+13]]/TN=$t[i+13],d[y[i+14]]/TN=$t[i+14],d[y[i+15]]/TN=$t[i+15],d[y[i+16]]/TN=$t[i+16],d[y[i+17]]/TN=$t[i+17],d[y[i+18]]/TN=$t[i+18],d[y[i+19]]/TN=$t[i+19],d[y[i+20]]/TN=$t[i+20],d[y[i+21]]/TN=$t[i+21],d[y[i+22]]/TN=$t[i+22],d[y[i+23]]/TN=$t[i+23],d[y[i+24]]/TN=$t[i+24],d[y[i+25]]/TN=$t[i+25],d[y[i+26]]/TN=$t[i+26],d[y[i+27]]/TN=$t[i+27],d[y[i+28]]/TN=$t[i+28],d[y[i+29]]/TN=$t[i+29],d[y[i+30]]/TN=$t[i+30],d[y[i+31]]/TN=$t[i+31],d[y[i+32]]/TN=$t[i+32],d[y[i+33]]/TN=$t[i+33],d[y[i+34]]/TN=$t[i+34],d[y[i+35]]/TN=$t[i+35],d[y[i+36]]/TN=$t[i+36],d[y[i+37]]/TN=$t[i+37],d[y[i+38]]/TN=$t[i+38],d[y[i+39]]/TN=$t[i+39],d[y[i+40]]/TN=$t[i+40],d[y[i+41]]/TN=$t[i+41],d[y[i+42]]/TN=$t[i+42],d[y[i+43]]/TN=$t[i+43],d[y[i+44]]/TN=$t[i+44],d[y[i+45]]/TN=$t[i+45],d[y[i+46]]/TN=$t[i+46],d[y[i+47]]/TN=$t[i+47],d[y[i+48]]/TN=$t[i+48],d[y[i+49]]/TN=$t[i+49],d[y[i+50]]/TN=$t[i+50],d[y[i+51]]/TN=$t[i+51],d[y[i+52]]/TN=$t[i+52],d[y[i+53]]/TN=$t[i+53],d[y[i+54]]/TN=$t[i+54],d[y[i+55]]/TN=$t[i+55],d[y[i+56]]/TN=$t[i+56],d[y[i+57]]/TN=$t[i+57],d[y[i+58]]/TN=$t[i+58],d[y[i+59]]/TN=$t[i+59],d[y[i+60]]/TN=$t[i+60],d[y[i+61]]/TN=$t[i+61],d[y[i+62]]/TN=$t[i+62],d[y[i+63]]/TN=$t[i+63]
					break
				case 32:
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) d[y[i]]/TN=$t[i],d[y[i+1]]/TN=$t[i+1],d[y[i+2]]/TN=$t[i+2],d[y[i+3]]/TN=$t[i+3],d[y[i+4]]/TN=$t[i+4],d[y[i+5]]/TN=$t[i+5],d[y[i+6]]/TN=$t[i+6],d[y[i+7]]/TN=$t[i+7],d[y[i+8]]/TN=$t[i+8],d[y[i+9]]/TN=$t[i+9],d[y[i+10]]/TN=$t[i+10],d[y[i+11]]/TN=$t[i+11],d[y[i+12]]/TN=$t[i+12],d[y[i+13]]/TN=$t[i+13],d[y[i+14]]/TN=$t[i+14],d[y[i+15]]/TN=$t[i+15],d[y[i+16]]/TN=$t[i+16],d[y[i+17]]/TN=$t[i+17],d[y[i+18]]/TN=$t[i+18],d[y[i+19]]/TN=$t[i+19],d[y[i+20]]/TN=$t[i+20],d[y[i+21]]/TN=$t[i+21],d[y[i+22]]/TN=$t[i+22],d[y[i+23]]/TN=$t[i+23],d[y[i+24]]/TN=$t[i+24],d[y[i+25]]/TN=$t[i+25],d[y[i+26]]/TN=$t[i+26],d[y[i+27]]/TN=$t[i+27],d[y[i+28]]/TN=$t[i+28],d[y[i+29]]/TN=$t[i+29],d[y[i+30]]/TN=$t[i+30],d[y[i+31]]/TN=$t[i+31]
					break
				case 16:
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) d[y[i]]/TN=$t[i],d[y[i+1]]/TN=$t[i+1],d[y[i+2]]/TN=$t[i+2],d[y[i+3]]/TN=$t[i+3],d[y[i+4]]/TN=$t[i+4],d[y[i+5]]/TN=$t[i+5],d[y[i+6]]/TN=$t[i+6],d[y[i+7]]/TN=$t[i+7],d[y[i+8]]/TN=$t[i+8],d[y[i+9]]/TN=$t[i+9],d[y[i+10]]/TN=$t[i+10],d[y[i+11]]/TN=$t[i+11],d[y[i+12]]/TN=$t[i+12],d[y[i+13]]/TN=$t[i+13],d[y[i+14]]/TN=$t[i+14],d[y[i+15]]/TN=$t[i+15]
					break
				case 8:
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) d[y[i]]/TN=$t[i],d[y[i+1]]/TN=$t[i+1],d[y[i+2]]/TN=$t[i+2],d[y[i+3]]/TN=$t[i+3],d[y[i+4]]/TN=$t[i+4],d[y[i+5]]/TN=$t[i+5],d[y[i+6]]/TN=$t[i+6],d[y[i+7]]/TN=$t[i+7]
					break
				case 4:
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) d[y[i]]/TN=$t[i],d[y[i+1]]/TN=$t[i+1],d[y[i+2]]/TN=$t[i+2],d[y[i+3]]/TN=$t[i+3]
					break
				case 2:
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) d[y[i]]/TN=$t[i],d[y[i+1]]/TN=$t[i+1]
					break
				case 1:
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) d[y[i]]/TN=$t[i]
					break
				default:
					ASSERT(0, "Fail")
					break
			endswitch
		while(i)
	endif

End
