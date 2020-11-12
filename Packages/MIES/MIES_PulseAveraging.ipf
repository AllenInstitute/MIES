
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

static StrConstant PA_PROPERTIES_KEY_REGIONS = "Regions"
static StrConstant PA_PROPERTIES_KEY_CHANNELS = "Channels"
static StrConstant PA_PROPERTIES_KEY_PREVREGIONS = "PreviousRegions"
static StrConstant PA_PROPERTIES_KEY_PREVCHANNELS = "PreviousChannels"
static StrConstant PA_PROPERTIES_KEY_SWEEPS = "Sweeps"
static StrConstant PA_PROPERTIES_KEY_LAYOUTCHANGE = "LayoutChanged"
static StrConstant PA_PROPERTIES_STRLIST_SEP = ","
static StrConstant PA_SETINDICES_KEY_ACTIVECHANCOUNT = "ActiveChanCount"
static StrConstant PA_SETINDICES_KEY_ACTIVEREGIONCOUNT = "ActiveRegionCount"
static StrConstant PA_SETINDICES_KEY_DISPCHANGE = "DisplayChange"
static StrConstant PA_SETINDICES_KEY_DISPSTART = "DisplayStart"

static Constant PA_UPDATEINDICES_TYPE_PREV = 1
static Constant PA_UPDATEINDICES_TYPE_CURR = 2

static Constant PA_INDICESCHANGE_NONE = 0
static Constant PA_INDICESCHANGE_MOVED = 1
static Constant PA_INDICESCHANGE_REMOVED = 2
static Constant PA_INDICESCHANGE_ADDED = 3

static Constant PA_PASIINIT_BASE = 0x01
static Constant PA_PASIINIT_INDICEMETA = 0x02

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
		PA_GetTraceCountFromGraphData(win, clear = 1)
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
static Function/WAVE PA_GetAxes(STRUCT PulseAverageSettings &pa, variable channel, variable region)

	string vertAxis, horizAxis

	if(pa.multipleGraphs)
		Make/FREE/T w = {"left", "bottom"}
		return w
	endif

	// the vertical axes names must end numbered like auto generated waves, because they are sorted with sortOrder 16 + 1
	// in PA_LayoutGraphs (descending, like waves)
	sprintf vertAxis,  "left_R%d_C%d", region, channel
	sprintf horizAxis, "bottom_R%d", region
	Make/FREE/T w = {vertAxis, horizAxis}
	return w
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
static Function/WAVE PA_GetUniqueHeadstages(WAVE/T traceData)

	variable size

	size = DimSize(traceData, ROWS)
	if(size == 0)
		return $""
	endif

	Make/D/FREE/N=(size) headstages = str2num(traceData[p][%headstage])

	if(DimSize(headstages, ROWS) == 1)
		return headstages
	endif

	Make/FREE/D headstagesClean
	FindDuplicates/Z/RN=headstagesClean headstages

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
static Function [WAVE pulseWave, WAVE noteWave] PA_CreateAndFillPulseWaveIfReq(WAVE/Z wv, DFREF singleSweepFolder, variable channelType, variable channelNumber, variable region, variable pulseIndex, variable first, variable length)

	variable existingLength

	if(first < 0 || length <= 0 || (DimSize(wv, ROWS) - first) <= length)
		return [$"", $""]
	endif

	length = limit(length, 1, DimSize(wv, ROWS) - first)

	WAVE singlePulseWave = GetPulseAverageWave(singleSweepFolder, length, channelType, channelNumber, region, pulseIndex)
	WAVE singlePulseWaveNote = GetPulseAverageWaveNoteWave(singleSweepFolder, length, channelType, channelNumber, region, pulseIndex)

	existingLength = GetNumberFromWaveNote(singlePulseWaveNote, "PulseLength")

	if(existingLength != length)
		Redimension/N=(length) singlePulseWave
	elseif(GetNumberFromWaveNote(singlePulseWaveNote, PA_SOURCE_WAVE_TIMESTAMP) == ModDate(wv))
		return [singlePulseWave, singlePulseWaveNote]
	endif

	MultiThread singlePulseWave[] = wv[first + p]
	SetScale/P x, 0.0, DimDelta(wv, ROWS), WaveUnits(wv, ROWS), singlePulseWave
	SetScale/P d, 0.0, 0.0, WaveUnits(wv, -1), singlePulseWave

	ClearWaveNoteExceptWaveVersion(singlePulseWaveNote)

	SetNumberInWaveNote(singlePulseWaveNote, NOTE_KEY_SEARCH_FAILED_PULSE, 0)
	SetNumberInWaveNote(singlePulseWaveNote, NOTE_KEY_TIMEALIGN, 0)
	SetNumberInWaveNote(singlePulseWaveNote, NOTE_KEY_ZEROED, 0)

	PA_UpdateMinAndMax(singlePulseWave, singlePulseWaveNote)

	SetNumberInWaveNote(singlePulseWaveNote, "PulseLength", length)

	SetNumberInWaveNote(singlePulseWaveNote, PA_SOURCE_WAVE_TIMESTAMP, ModDate(wv))

	CreateBackupWave(singlePulseWave, forceCreation = 1)
	CreateBackupWave(singlePulseWaveNote, forceCreation = 1)

	return [singlePulseWave, singlePulseWaveNote]
End

threadsafe static Function PA_UpdateMinAndMax(WAVE wv, WAVE noteWave)

	variable minimum, maximum

	[minimum, maximum] = WaveMinAndMax(wv)
	SetNumberInWaveNote(noteWave, "WaveMinimum", minimum, format="%.15f")
	SetNumberInWaveNote(noteWave, "WaveMaximum", maximum, format="%.15f")
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
/// Returns the mode, because the mode may change from incremental to full update because incremental update fails due to layout changes
static Function [STRUCT PulseAverageSetIndices pasi] PA_GenerateAllPulseWaves(string win, STRUCT PulseAverageSettings &pa, variable mode, WAVE/Z additionalData)

	variable startingPulseSett, endingPulseSett, pulseHasFailed, numActive
	variable i, j, k, region, sweepNo, idx, numPulsesTotal, endingPulse
	variable headstage, pulseToPulseLength, totalOnsetDelay, numChannelTypeTraces, totalPulseCounter, jsonID, lastSweep
	variable activeChanCount, channelNumber, first, length, channelType, numChannels, numRegions
	variable numPulseCreate, prevTotalPulseCounter, numNewSweeps, numNewIndicesSweep, incrementalMode, layoutChanged
	variable lblIndex, lblSweep, lblChannelType, lblChannelNumber, lblRegion, lblHeadstage, lblPulse, lblLastSweep, lblExperiment
	variable lblTraceHeadstage, lblTraceExperiment, lblTraceSweepNumber, lblTraceChannelNumber, lblTracenumericalValues, lblTraceFullpath
	variable lblPWPULSE, lblPWPULSENOTE, lblACTIVEREGION, lblACTIVECHANNEL
	string channelTypeStr, channelList, regionChannelList, channelNumberStr, key, regionList, sweepList, sweepNoStr, experiment
	string oldRegionList, oldChannelList

	WAVE/T/Z traceData = GetTraceInfos(GetMainWindow(win))
	if(!WaveExists(traceData))
		KillorMoveToTrash(dfr = GetDevicePulseAverageHelperFolder(pa.dfr))
		return [pasi]
	endif
	numChannelTypeTraces = DimSize(traceData, ROWS)

	incrementalMode = mode == POST_PLOT_ADDED_SWEEPS && WaveExists(additionalData)

	if(pa.startingPulse >= 0)
		startingPulseSett = pa.startingPulse
	endif

	if(pa.endingPulse >= 0)
		endingPulseSett = pa.endingPulse
	endif

	DFREF pulseAverageDFR = GetDevicePulseAverageFolder(pa.dfr)
	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)
	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)
	oldRegionList = GetStringFromWaveNote(properties, PA_PROPERTIES_KEY_REGIONS)
	oldChannelList = GetStringFromWaveNote(properties, PA_PROPERTIES_KEY_CHANNELS)

	if(mode != POST_PLOT_ADDED_SWEEPS)
		KillorMoveToTrash(dfr = GetDevicePulseAverageHelperFolder(pa.dfr))
	endif

	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)
	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)
	WAVE/T propertiesText = GetPulseAveragePropertiesText(pulseAverageHelperDFR)
	WAVE/WAVE propertiesWaves = GetPulseAveragePropertiesWaves(pulseAverageHelperDFR)

	// Get regions of all traces
	WAVE/Z regions = PA_GetUniqueHeadstages(traceData)
	if(!WaveExists(regions))
		return [pasi]
	endif
	numRegions = DimSize(regions, ROWS)
	regionList = ""
	for(i = 0; i < numRegions; i += 1)
		regionList = AddListItem(num2istr(regions[i]), regionList, PA_PROPERTIES_STRLIST_SEP, inf)
	endfor

	// There is one case where we generate errorneous output:
	// If we have multiple sweeps that are acquired with more than 1 HS and
	// on a subsequent sweep the channels previously associated to the headstages are now swapped.
	// Then we have the same layout for both sweeps, but swapped data due to the new channel association.
	// Currently we accept that as an edge case.
	// A fix would be to find association changed by iterating over the sweeps and flag sweeps to be skipped.
	// Then get only traces for non-skipped sweeps.

	Make/FREE/N=(numChannelTypeTraces) indizesChannelType = p
	// In incremental mode get only new part of the indices
	if(incrementalMode)
		Make/FREE/N=(numChannelTypeTraces) indizesToAdd
		j = 0
		numNewSweeps = DimSize(additionalData, ROWS)
		ASSERT(numNewSweeps > 0, "Set POST_PLOT_ADDED_SWEEPS, but found no new sweep(s) in additionlData")
		for(i = 0; i < numNewSweeps; i += 1)
			WAVE/Z indizesNewSweep = FindIndizes(traceData, colLabel="SweepNumber", str=num2str(additionalData[i]))
			if(!WaveExists(indizesNewSweep))
				continue
			endif
			WAVE indizesToAddNewSweep = GetSetIntersection(indizesChannelType, indizesNewSweep)
			numNewIndicesSweep = DimSize(indizesToAddNewSweep, ROWS)
			indizesToAdd[j, j + numNewIndicesSweep - 1] = indizesToAddNewSweep[p - j]
			j += numNewIndicesSweep
		endfor
		Redimension/N=(j) indizesToAdd

		WAVE indizesChannelTypeAll = indizesChannelType
		WAVE indizesChannelType = indizesToAdd
		numChannelTypeTraces = DimSize(indizesChannelType, ROWS)

		totalPulseCounter = GetNumberFromWaveNote(properties, NOTE_INDEX)
		SetNumberInWaveNote(properties, NOTE_PA_NEW_PULSES_START, totalPulseCounter)

		WAVE/WAVE/Z setIndices
		WAVE/Z junk1, junk2, indexHelper
		[setIndices, junk1, junk2, indexHelper] = PA_GetSetIndicesHelper(pulseAverageHelperDFR, 0)
		if(WaveExists(setIndices))
			indexHelper[][] = PA_CopySetIndiceSizeDispRestart(setIndices[p][q])
		endif
	else
		SetNumberInWaveNote(properties, NOTE_PA_NEW_PULSES_START, 0)
	endif

	WAVE prevDisplayMapping = GetPulseAverageDisplayMapping(pulseAverageDFR)
	Duplicate/FREE prevDisplayMapping, currentDisplayMapping
	FastOp currentDisplayMapping = 0

	lblIndex = -1

	lblSweep = FindDimLabel(properties, COLS, "Sweep")
	lblChannelType = FindDimLabel(properties, COLS, "ChannelType")
	lblChannelNumber = FindDimLabel(properties, COLS, "ChannelNumber")
	lblRegion = FindDimLabel(properties, COLS, "Region")
	lblHeadstage = FindDimLabel(properties, COLS, "Headstage")
	lblPulse = FindDimLabel(properties, COLS, "Pulse")
	lblLastSweep = FindDimLabel(properties, COLS, "LastSweep")

	lblExperiment = FindDimLabel(propertiesText, COLS, "Experiment")

	lblTraceHeadstage = FindDimLabel(traceData, COLS, "headstage")
	lblTraceSweepNumber = FindDimLabel(traceData, COLS, "SweepNumber")
	lblTraceChannelNumber = FindDimLabel(traceData, COLS, "ChannelNumber")
	lblTracenumericalValues = FindDimLabel(traceData, COLS, "numericalValues")
	lblTraceExperiment = FindDimLabel(traceData, COLS, "Experiment")
	lblTraceFullpath = FindDimLabel(traceData, COLS, "fullpath")

	lblPWPULSE = FindDimLabel(propertiesWaves, COLS, "PULSE")
	lblPWPULSENOTE = FindDimLabel(propertiesWaves, COLS, "PULSENOTE")

	lblACTIVEREGION = FindDimLabel(prevDisplayMapping, LAYERS, "ACTIVEREGION")
	lblACTIVECHANNEL = FindDimLabel(prevDisplayMapping, LAYERS, "ACTIVECHANNEL")

	channelType = ITC_XOP_CHANNEL_TYPE_ADC
	channelTypeStr = StringFromList(channelType, ITC_CHANNEL_NAMES)
	sweepList  = ""
	channelList = ""

	jsonID = JSON_New()

	for(i = 0; i < numRegions; i += 1)
		region = regions[i]

		activeChanCount = 0
		regionChannelList = ""

		// we have the starting times for one channel type and headstage combination
		// iterate now over all channels of the same type and extract all
		// requested pulses for them
		for(j = 0; j < numChannelTypeTraces; j += 1)
			idx = indizesChannelType[j]

			// get channel number and update local and global list
			channelNumberStr = traceData[idx][lblTraceChannelNumber]
			channelNumber = str2num(channelNumberStr)
			if(WhichListItem(channelNumberStr, regionChannelList) == -1)
				activeChanCount += 1
				regionChannelList = AddListItem(channelNumberStr, regionChannelList, ";", inf)
			endif
			if(WhichListItem(channelNumberStr, channelList, PA_PROPERTIES_STRLIST_SEP) == -1)
				channelList = AddListItem(channelNumberStr, channelList, PA_PROPERTIES_STRLIST_SEP, inf)
			endif
			// get pulse start times and from that number of pulses
			WAVE/Z pulseStartTimes = PA_GetPulseStartTimes(traceData, idx, region, channelTypeStr)
			if(!WaveExists(pulseStartTimes))
				continue
			endif
			numPulsesTotal = DimSize(pulseStartTimes, ROWS)
			endingPulse    = min(numPulsesTotal - 1, endingPulseSett)
			numPulseCreate = endingPulse - startingPulseSett + 1
			if(numPulseCreate <= 0)
				continue
			endif
			// get sweep number
			sweepNoStr = traceData[idx][lblTraceSweepNumber]
			sweepNo = str2num(sweepNoStr)
			if(WhichListItem(sweepNoStr, sweepList, PA_PROPERTIES_STRLIST_SEP) == -1)
				sweepList = AddListItem(sweepNoStr, sweepList, PA_PROPERTIES_STRLIST_SEP, inf)
			endif

			experiment = traceData[idx][lblTraceExperiment]
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

			pulseToPulseLength = PA_GetPulseLength(pulseStartTimes, startingPulseSett, endingPulse, pa.overridePulseLength, pa.fixedPulseLength)

			WAVE numericalValues = $traceData[idx][lblTracenumericalValues]
			DFREF singleSweepFolder = GetWavesDataFolderDFR($traceData[idx][lblTraceFullpath])
			ASSERT(DataFolderExistsDFR(singleSweepFolder), "Missing singleSweepFolder")
			WAVE wv = GetITCDataSingleColumnWave(singleSweepFolder, channelType, channelNumber)

			DFREF singlePulseFolder = GetSingleSweepFolder(pulseAverageDFR, sweepNo)
			totalOnsetDelay = GetTotalOnsetDelay(numericalValues, sweepNo)
			// number of pulses that might be created
			if(numPulseCreate)
				numPulseCreate += totalPulseCounter
				EnsureLargeEnoughWave(properties, minimumSize = numPulseCreate, initialValue = NaN)
				EnsureLargeEnoughWave(propertiesText, minimumSize = numPulseCreate)
				EnsureLargeEnoughWave(propertiesWaves, minimumSize = numPulseCreate)
			endif

			headstage = str2num(traceData[idx][lblTraceHeadstage])
			prevTotalPulseCounter = totalPulseCounter
			for(k = startingPulseSett; k <= endingPulse; k += 1)

				// ignore wave offset, as it is only used for display purposes
				// but use the totalOnsetDelay of this sweep
				first  = round((pulseStartTimes[k] + totalOnsetDelay) / DimDelta(wv, ROWS))
				length = round(pulseToPulseLength / DimDelta(wv, ROWS))

				WAVE/Z pulseWave, pulseWaveNote
				[pulseWave, pulseWaveNote] = PA_CreateAndFillPulseWaveIfReq(wv, singlePulseFolder, channelType, channelNumber, \
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
				properties[totalPulseCounter][lblLastSweep]                   = lastSweep

				propertiesText[totalPulseCounter][lblExperiment] = experiment

				propertiesWaves[totalPulseCounter][lblPWPULSE] = pulseWave
				propertiesWaves[totalPulseCounter][lblPWPULSENOTE] = pulseWaveNote

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

			currentDisplayMapping[region][channelNumber][lblACTIVEREGION] = i + 1
			currentDisplayMapping[region][channelNumber][lblACTIVECHANNEL] = activeChanCount

		endfor
	endfor
	SetNumberInWaveNote(properties, NOTE_INDEX, totalPulseCounter)
	SetNumberInWaveNote(propertiesText, NOTE_INDEX, totalPulseCounter)

	if(incrementalMode)
		sweepList = GetStringFromWaveNote(properties, PA_PROPERTIES_KEY_SWEEPS) + sweepList
		// in traceData the sort order is channelType, channelNumber, Sweep, Headstage. With channelType always AD, we can say that
		// channelsNumbers are always sorted. This allows us to take the shortcut and sort the merged lists here.
		channelList = SortList(MergeLists(channelList, oldChannelList, sep = PA_PROPERTIES_STRLIST_SEP), PA_PROPERTIES_STRLIST_SEP, 2)
		layoutChanged = CmpStr(oldRegionList, regionList) || CmpStr(oldChannelList, channelList)
		if(layoutChanged)

			FastOp currentDisplayMapping = 0
			WAVE indizesChannelType = indizesChannelTypeAll
			numChannelTypeTraces = DimSize(indizesChannelType, ROWS)
			// the following loop must use the same logic as the upper loop to fill mapRegChanToActive
			for(i = 0; i < numRegions; i += 1)
				region = regions[i]

				activeChanCount = 0
				regionChannelList = ""
				for(j = 0; j < numChannelTypeTraces; j += 1)
					channelNumberStr = traceData[j][lblTraceChannelNumber]
					if(WhichListItem(channelNumberStr, regionChannelList) == -1)
						activeChanCount += 1
						regionChannelList = AddListItem(channelNumberStr, regionChannelList, ";", inf)
					endif

					channelNumber = str2num(channelNumberStr)
					currentDisplayMapping[region][channelNumber][lblACTIVEREGION] = i + 1
					currentDisplayMapping[region][channelNumber][lblACTIVECHANNEL] = activeChanCount
				endfor
			endfor
		endif
	else
		layoutChanged = CmpStr(oldRegionList, regionList) || CmpStr(oldChannelList, channelList)
	endif
	ASSERT(ItemsInList(regionList) == ItemsInList(channelList), "An AD or DA channel that was previously used on one headstage was used with a different headstage in a subsequent sweep. This is not supported.")

	SetStringInWaveNote(properties, PA_PROPERTIES_KEY_REGIONS, regionList)
	SetStringInWaveNote(properties, PA_PROPERTIES_KEY_CHANNELS, channelList)
	SetStringInWaveNote(properties, PA_PROPERTIES_KEY_PREVREGIONS, oldRegionList)
	SetStringInWaveNote(properties, PA_PROPERTIES_KEY_PREVCHANNELS, oldChannelList)
	SetStringInWaveNote(properties, PA_PROPERTIES_KEY_SWEEPS, sweepList)
	SetNumberInWaveNote(properties, PA_PROPERTIES_KEY_LAYOUTCHANGE, layoutChanged)

	[pasi] = PA_InitPASIInParts(pa, PA_PASIINIT_BASE, 0)
	if(WaveExists(pasi.setIndices))

		PA_UpdateIndiceNotes(currentDisplayMapping, prevDisplayMapping, pasi, layoutChanged)
		Duplicate/O currentDisplayMapping, prevDisplayMapping

		[pasi] = PA_InitPASIInParts(pa, PA_PASIINIT_INDICEMETA, 0)
	endif

	JSON_Release(jsonID)

	return [pasi]
End

static Function [STRUCT PulseAverageSetIndices pasi] PA_InitPASIInParts(STRUCT PulseAverageSettings &pa, variable part, variable disableIncremental)

	variable numActive

	disableIncremental = !!disableIncremental

	if(part & PA_PASIINIT_BASE)
		DFREF pasi.pulseAverageDFR = GetDevicePulseAverageFolder(pa.dfr)
		DFREF pasi.pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)

		WAVE pasi.properties = GetPulseAverageProperties(pasi.pulseAverageHelperDFR)
		WAVE/T pasi.propertiesText = GetPulseAveragePropertiesText(pasi.pulseAverageHelperDFR)
		WAVE/WAVE pasi.propertiesWaves = GetPulseAveragePropertiesWaves(pasi.pulseAverageHelperDFR)

		WAVE/WAVE/Z setIndices
		WAVE/Z channels, regions, indexHelper
		[setIndices, channels, regions, indexHelper] = PA_GetSetIndicesHelper(pasi.pulseAverageHelperDFR, 0)
		if(!WaveExists(setIndices))
			return [pasi]
		endif

		WAVE/WAVE pasi.setIndices = setIndices
		WAVE pasi.channels = channels
		WAVE pasi.regions = regions
		WAVE pasi.indexHelper = indexHelper

		numActive = DimSize(pasi.channels, ROWS)
		Make/FREE/WAVE/N=(numActive, numActive) setWaves2, axesNames

		setWaves2[][] = PA_GetSetWaves(pasi.pulseAverageHelperDFR, pasi.channels[p], pasi.regions[q])
		WAVE/WAVE pasi.setWaves2 = setWaves2

		axesNames[][] = PA_GetAxes(pa, pasi.channels[p], pasi.regions[q])
		WAVE/WAVE pasi.axesNames = axesNames

		Make/FREE/D/N=(numActive, numActive) ovlTracesAvg, ovlTracesDeconv
		WAVE pasi.ovlTracesAvg = ovlTracesAvg
		WAVE pasi.ovlTracesDeconv = ovlTracesDeconv
	endif

	if(part & PA_PASIINIT_INDICEMETA)
		if(!WaveExists(pasi.channels))
			return [pasi]
		endif
		numActive = DimSize(pasi.channels, ROWS)
		Make/FREE/D/N=(numActive, numActive) numEntries, startEntry
		numEntries[][] = GetNumberFromWaveNote(pasi.setIndices[p][q], NOTE_INDEX)
		if(!disableIncremental)
			startEntry[][] = GetNumberFromWaveNote(pasi.setIndices[p][q], PA_SETINDICES_KEY_DISPSTART)
			startEntry[][] = IsNaN(startEntry[p][q]) ? 0 : startEntry[p][q]
		endif
		WAVE pasi.numEntries = numEntries
		WAVE pasi.startEntry = startEntry
	endif

	return [pasi]
End

/// @brief For incremental display update copy current size of of setIndices to new display start
static Function PA_CopySetIndiceSizeDispRestart(WAVE/WAVE setIndices)

	variable displayStart

	displayStart = GetNumberFromWaveNote(setIndices, NOTE_INDEX)
	displayStart = IsNaN(displayStart) ? 0 : displayStart
	SetNumberInWaveNote(setIndices, PA_SETINDICES_KEY_DISPSTART, displayStart)
End

static Function [WAVE/WAVE setIndices, WAVE channels, WAVE regions, WAVE indexHelper] PA_GetSetIndicesHelper(DFREF pulseAverageHelperDFR, variable prevIndices)

	variable numChannels, numRegions
	string keyChannels, keyRegions

	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)
	prevIndices = !!prevIndices

	if(prevIndices)
		keyChannels = PA_PROPERTIES_KEY_PREVCHANNELS
		keyRegions = PA_PROPERTIES_KEY_PREVREGIONS
	else
		keyChannels = PA_PROPERTIES_KEY_CHANNELS
		keyRegions = PA_PROPERTIES_KEY_REGIONS
	endif

	WAVE channels = ListToNumericWave(GetStringFromWaveNote(properties, keyChannels), PA_PROPERTIES_STRLIST_SEP)
	numChannels = DimSize(channels, ROWS)
	if(!numChannels)
		return [$"", $"", $"", $""]
	endif
	WAVE regions = ListToNumericWave(GetStringFromWaveNote(properties, keyRegions), PA_PROPERTIES_STRLIST_SEP)
	numRegions = DimSize(regions, ROWS)
	Make/FREE/WAVE/N=(numChannels, numRegions) setIndices
	Make/FREE/N=(numChannels, numRegions) indexHelper
	setIndices[][] = GetPulseAverageSetIndizes(pulseAverageHelperDFR, channels[p], regions[q])

	return [setIndices, channels, regions, indexHelper]
End

static Function PA_UpdateIndiceNotes(WAVE currentDisplayMapping, WAVE prevDisplayMapping, STRUCT PulseAverageSetIndices &pasi, variable layoutChanged)

	if(layoutChanged)
		WAVE/WAVE/Z setIndices
		WAVE/Z channels, regions, indexHelper
		[setIndices, channels, regions, indexHelper] = PA_GetSetIndicesHelper(pasi.pulseAverageHelperDFR, 1)
		if(WaveExists(setIndices))
			indexHelper[][] = PA_UpdateIndiceNotesImpl(setIndices[p][q], currentDisplayMapping, prevDisplayMapping, channels[p], regions[q], layoutChanged, PA_UPDATEINDICES_TYPE_PREV)
		endif
	endif
	pasi.indexHelper[][] = PA_UpdateIndiceNotesImpl(pasi.setIndices[p][q], currentDisplayMapping, prevDisplayMapping, pasi.channels[p], pasi.regions[q], layoutChanged, PA_UPDATEINDICES_TYPE_CURR)
End

/// @brief Evaluate the previous and current mapping and set the display change in the wave note of the indice sets as well as activeChanCount, activeRegionCount.
///        IMPORTANT: To have a consistent state for the case the layout changed the function must be called with the current and the previous indices. Otherwise removed sets wont be flagged properly.
static Function PA_UpdateIndiceNotesImpl(WAVE indices, WAVE currentMap, WAVE oldMap, variable channel, variable region, variable layoutChanged, variable indiceType)

	string debugMsg
	sprintf debugMsg, "channel: %d region: %d", channel, region

	if(layoutChanged)
		if(indiceType == PA_UPDATEINDICES_TYPE_CURR)
			// currentMap is here always valid
			if(oldMap[region][channel][0])
				if(!(oldMap[region][channel][0] == currentMap[region][channel][0] && oldMap[region][channel][1] == currentMap[region][channel][1]))
					// it is in prev and current but has moved
					SetNumberInWaveNote(indices, PA_SETINDICES_KEY_DISPCHANGE, PA_INDICESCHANGE_MOVED)
					DEBUGPRINT("Layout: Move " + debugMsg)
				else
					SetNumberInWaveNote(indices, PA_SETINDICES_KEY_DISPCHANGE, PA_INDICESCHANGE_NONE)
					DEBUGPRINT("Layout: Stay " + debugMsg)
				endif
			else
				// set got added in display
				SetNumberInWaveNote(indices, PA_SETINDICES_KEY_DISPCHANGE, PA_INDICESCHANGE_ADDED)
				DEBUGPRINT("Layout: Add " + debugMsg)
			endif
		elseif(indiceType == PA_UPDATEINDICES_TYPE_PREV)
			// prevMap is here always valid
			if(!currentMap[region][channel][0])
				// set got removed in display
				SetNumberInWaveNote(indices, PA_SETINDICES_KEY_DISPCHANGE, PA_INDICESCHANGE_REMOVED)
				SetNumberInWaveNote(indices, PA_SETINDICES_KEY_ACTIVEREGIONCOUNT, NaN)
				SetNumberInWaveNote(indices, PA_SETINDICES_KEY_ACTIVECHANCOUNT, NaN)
				DEBUGPRINT("Layout: Remove " + debugMsg)
			endif
		else
			ASSERT_TS(0, "unknown indiceType")
		endif
	else
		SetNumberInWaveNote(indices, PA_SETINDICES_KEY_DISPCHANGE, PA_INDICESCHANGE_NONE)
	endif

	if(indiceType == PA_UPDATEINDICES_TYPE_CURR)
		SetNumberInWaveNote(indices, PA_SETINDICES_KEY_ACTIVEREGIONCOUNT, currentMap[region][channel][0])
		SetNumberInWaveNote(indices, PA_SETINDICES_KEY_ACTIVECHANCOUNT, currentMap[region][channel][1])
		SetNumberInWaveNote(indices, NOTE_KEY_PULSE_SORT_ORDER, NaN)
	endif
End

threadsafe static Function PA_ApplyPulseSortingOrder(WAVE setIndices, variable channelNumber, variable region, WAVE properties, STRUCT PulseAverageSettings &pa)

	variable numEntries, pulseSortOrder
	variable lblSweep, lblPulse

	numEntries = GetNumberFromWaveNote(setIndices, NOTE_INDEX)
	if(!numEntries)
		return NaN
	endif

	pulseSortOrder = GetNumberFromWaveNote(setIndices, NOTE_KEY_PULSE_SORT_ORDER)
	if(IsFinite(pulseSortOrder) && pulseSortOrder == pa.pulseSortOrder)
		return NaN
	endif

	lblSweep = FindDimLabel(properties, COLS, "Sweep")
	lblPulse = FindDimLabel(properties, COLS, "Pulse")

	Make/FREE/N=(numEntries, 3) elems

	elems[][0] = properties[setIndices[p]][lblSweep]
	elems[][1] = properties[setIndices[p]][lblPulse]
	elems[][2] = setIndices[p]

	switch(pa.pulseSortOrder)
		case PA_PULSE_SORTING_ORDER_SWEEP:
			// first sweep then pulse
			SortColumns/KNDX={0, 1} sortWaves={elems}
			break
		case PA_PULSE_SORTING_ORDER_PULSE:
			// first pulse then sweep
			SortColumns/KNDX={1, 0} sortWaves={elems}
			break
		default:
			ASSERT_TS(0, "Invalid sorting order")
	endswitch

	// copy sorted result back
	setIndices[0, numEntries - 1] = elems[p][2]

	SetNumberInWaveNote(setIndices, NOTE_KEY_PULSE_SORT_ORDER, pa.pulseSortOrder)
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
	STRUCT PulseAverageSetIndices pasi

	variable s1, e1, s2, e2
	variable s = stopmstimer(-2)

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

	s1 = stopmstimer(-2)
	[pasi, needsPlotting] = PA_PreProcessPulses(win, current, cs, mode, additionalData)
	if(!needsPlotting)
		return NaN
	endif
	e1 = stopmstimer(-2)

	preExistingGraphs = PA_GetGraphs(win, PA_DISPLAYMODE_ALL)

	s2 = stopmstimer(-2)
	usedTraceGraphs = PA_ShowPulses(graph, current, cs, pasi, mode)
	e2 = stopmstimer(-2)

	usedImageGraphs = PA_ShowImage(graph, current, cs, pasi, mode, additionalData)

	KillWindows(RemoveFromList(usedTraceGraphs + usedImageGraphs, preExistingGraphs))
	print/D "Preprocess", (e1 - s1) / 1E6
	print/D "Showpulses", (e2 - s2) / 1E6
	print/D "All", (stopmstimer(-2) - s) / 1E6, "\r---"
End

/// @brief Returns the two column setWave with pulse/pulsenote
static Function/WAVE PA_GetSetWaves(DFREF dfr, variable channelNumber, variable region, [variable removeFailedPulses])

	removeFailedPulses = ParamIsDefault(removeFailedPulses) ? 0 : !!removeFailedPulses

	WAVE setIndizes = GetPulseAverageSetIndizes(dfr, channelNumber, region)

	WAVE properties = GetPulseAverageProperties(dfr)
	WAVE/WAVE propertiesWaves = GetPulseAveragePropertiesWaves(dfr)

	return WaveRef(PA_GetSetWaves_TS(properties, propertiesWaves, setIndizes, PA_GETSETWAVES_ALL, removeFailedPulses), row = 0)
End

/// @brief returns a 1D wave ref wave containing the refs to the setwave refs of all / new / old sets, depending on combined getModes.
/// a setWave wave is 2D containing the ref to the pulse and the note in col 0 and 1.
threadsafe static Function/WAVE PA_GetSetWaves_TS(WAVE properties, WAVE/WAVE propertiesWaves, WAVE setIndizes, variable getMode, variable removeFailedPulses)

	variable numWaves, i, startIndexNewPulses, index
	variable numNewPulses, numOldPulses, numAllPulses
	variable lblPulseHasFailed, lblPULSE, lblPULSENOTE

	// Since we have pasi now we can assemble the parts directly from using the information in pasi.setIndices[p][q]
	// and index into properties, instead of going through properties
	numWaves = GetNumberFromWaveNote(setIndizes, NOTE_INDEX)

	if(numWaves == 0)
		return $""
	endif

	lblPulseHasFailed = FindDimLabel(properties, COLS, "PulseHasFailed")
	lblPULSE = FindDimLabel(propertiesWaves, COLS, "PULSE")
	lblPULSENOTE = FindDimLabel(propertiesWaves, COLS, "PULSENOTE")

	if(getMode & PA_GETSETWAVES_NEW)
		Make/FREE/N=(numWaves, 2)/WAVE setWavesNew
	endif
	if(getMode & PA_GETSETWAVES_OLD)
		Make/FREE/N=(numWaves, 2)/WAVE setWavesOld
	endif
	if(getMode & PA_GETSETWAVES_ALL)
		Make/FREE/N=(numWaves, 2)/WAVE setWavesAll
	endif

	startIndexNewPulses = GetNumberFromWaveNote(properties, NOTE_PA_NEW_PULSES_START)

	for(i = 0; i < numWaves; i += 1)
		index = setIndizes[i]
		if(getMode & PA_GETSETWAVES_NEW && index >= startIndexNewPulses && !(properties[index][lblPulseHasFailed] == 1 && removeFailedPulses))
			setWavesNew[numNewPulses][0] = propertiesWaves[index][lblPULSE]
			setWavesNew[numNewPulses][1] = propertiesWaves[index][lblPULSENOTE]
			numNewPulses += 1
		endif
		if(getMode & PA_GETSETWAVES_OLD && index < startIndexNewPulses && !(properties[index][lblPulseHasFailed] == 1 && removeFailedPulses))
			setWavesOld[numOldPulses][0] = propertiesWaves[index][lblPULSE]
			setWavesOld[numOldPulses][1] = propertiesWaves[index][lblPULSENOTE]
			numOldPulses += 1
		endif
		if(getMode & PA_GETSETWAVES_ALL && !(properties[index][lblPulseHasFailed] == 1 && removeFailedPulses))
			setWavesAll[numAllPulses][0] = propertiesWaves[index][lblPULSE]
			setWavesAll[numAllPulses][1] = propertiesWaves[index][lblPULSENOTE]
			numAllPulses += 1
		endif
	endfor
	if(numNewPulses)
		Redimension/N=(numNewPulses, -1) setWavesNew
	else
		WAVE/Z setWavesNew = $""
	endif
	if(numOldPulses)
		Redimension/N=(numOldPulses, -1) setWavesOld
	else
		WAVE/Z setWavesOld = $""
	endif
	if(numAllPulses)
		Redimension/N=(numAllPulses, -1) setWavesAll
	else
		WAVE/Z setWavesAll = $""
	endif

	Make/FREE/WAVE setWavesComponents = {setWavesAll, setWavesNew, setWavesOld}
	return setWavesComponents
End

/// @brief Handle marking pulses as failed/passed if required
static Function PA_MarkFailedPulses(STRUCT PulseAverageSettings &pa, STRUCT PulseAverageSetIndices &pasi)
	variable numTotalPulses, sweepNo
	variable region, pulse, pulseHasFailed, jsonID, referencePulseHasFailed
	variable lblPWPULSENOTE, lblSweep, lblPulse, lblPulseHasFailed
	variable numActive, numEntries, i, j, k, idx, startEntry
	string key

	WAVE properties = pasi.properties
	WAVE/WAVE propertiesWaves = pasi.propertiesWaves

	lblPWPULSENOTE = FindDimLabel(propertiesWaves, COLS, "PULSENOTE")
	// update the wave notes
	numTotalPulses = GetNumberFromWaveNote(properties, NOTE_INDEX)
	Make/FREE/N=(numTotalPulses) indexHelper
	Multithread indexHelper[] = SetNumberInWaveNote(propertiesWaves[p][lblPWPULSENOTE], NOTE_KEY_SEARCH_FAILED_PULSE, pa.searchFailedPulses)

	lblPulseHasFailed = FindDimLabel(properties, COLS, "PulseHasFailed")
	if(!pa.searchFailedPulses)
		Multithread properties[][lblPulseHasFailed] = NaN
		return NaN
	endif

	lblSweep = FindDimLabel(properties, COLS, "Sweep")
	lblPulse = FindDimLabel(properties, COLS, "Pulse")

	jsonID = JSON_New()

	numActive = DimSize(pasi.channels, ROWS)

	// mark pulses in the diagonal elements for failed/passed
	// this is done by PA_PulseHasFailed which either uses the wave note
	// or uses FindLevel if required.
	for(i = 0; i < numActive; i += 1)
		region = pasi.regions[i]

		WAVE indices = pasi.setIndices[i][i]
		numEntries = pasi.numEntries[i][i]
		startEntry = pasi.startEntry[i][i]
		for(j = startEntry; j < numEntries; j += 1)
			idx = indices[j]

			WAVE noteWave = propertiesWaves[idx][lblPWPULSENOTE]
			pulseHasFailed = PA_PulseHasFailed(noteWave, pa)
			properties[idx][lblPulseHasFailed] = pulseHasFailed

			sweepNo = properties[idx][lblSweep]
			pulse   = properties[idx][lblPulse]
			key = PA_GenerateFailedPulseKey(sweepNo, region, pulse)
			JSON_SetVariable(jsonID, key, pulseHasFailed)
		endfor
	endfor

	for(i = 0; i < numActive; i += 1)
		region = pasi.regions[i]
		for(j = 0; j < numActive; j += 1)
			if(i == j)
				continue
			endif

			WAVE indices = pasi.setIndices[j][i]
			numEntries = pasi.numEntries[j][i]
			startEntry = pasi.startEntry[j][i]
			for(k = startEntry; k < numEntries; k += 1)
				idx = indices[k]
				sweepNo = properties[idx][lblSweep]
				pulse   = properties[idx][lblPulse]

				key = PA_GenerateFailedPulseKey(sweepNo, region, pulse)
				referencePulseHasFailed = JSON_GetVariable(jsonID, key, ignoreErr = 1)
				// NaN: reference trace could not be found, this happens
				// when a headstage is not displayed (channel selection, OVS HS removal)
				properties[idx][lblPulseHasFailed] = IsNaN(referencePulseHasFailed) ? 0 : referencePulseHasFailed
			endfor
		endfor
	endfor

	JSON_Release(jsonID)

	// Set current level, need to do that at the end, as PA_PulseHasFailed uses that entry for checking if it needs to rerun
	Multithread indexHelper[] = SetNumberInWaveNote(propertiesWaves[p][lblPWPULSENOTE], NOTE_KEY_FAILED_PULSE_LEVEL, pa.failedPulsesLevel)
End

/// @brief This function returns data from the light-weight data storage for PA graph data
/// @param[in] graph name of PA graph
/// @param[in] clear [optional, default = 0] when set reinitializes the data for the given graph
/// @return row index of the wave where the graph data is stored
static Function PA_GetTraceCountFromGraphData(string graph, [variable clear])

	variable idx

	clear = ParamIsDefault(clear) ? 0 : !!clear

	WAVE/T graphData = GetPAGraphData()
	idx = FindDimLabel(graphData, ROWS, graph)
	if(idx >= 0)
		if(clear)
			graphData[idx][%TRACES_AVERAGE] = ""
			graphData[idx][%TRACES_DECONV] = ""
			graphData[idx][%IMAGELIST] = ""
		endif
		return idx
	endif

	idx = DimSize(graphData, ROWS)
	Redimension/N=(idx + 1, -1) graphData
	SetDimLabel ROWS, idx, $graph, graphData

	return idx
End

static Function/S PA_ShowPulses(string win, STRUCT PulseAverageSettings &pa, STRUCT PA_ConstantSettings &cs, STRUCT PulseAverageSetIndices &pasi, variable mode)

	string pulseTrace, graph
	variable numActive, i, j, k, sweepNo, numTotalPulses, numPlotPulses, xPos, yPos, numTraces
	variable step, graphWasReset
	variable channelNumber, region
	variable pulseHasFailed
	variable hideTrace, lastSweep, alpha
	variable hiddenTracesCount, avgPlotCount, deconPlotCount, plottedAvgTraces
	variable jsonID, hideTraceJsonID, graphDataIndex, numHiddenTracesGraphs, graphHasChanged
	variable startEntry, numEntries, idx, layoutChanged
	variable lblSweep, lblChannelNumber, lblRegion, lblHeadstage
	variable lblPulseHasFailed, lblLastSweep, lblTRACES_AVERAGE, lblTRACES_DECONV, lblPWPULSE
	STRUCT RGBColor s
	string jsonPath
	string vertAxis, horizAxis
	string baseName, traceName, tagName
	string usedGraphs = ""
	string resetGraphs = ""

	if(!pa.showTraces)
		return ""
	elseif(cs.traces)
		return PA_GetGraphs(win, PA_DISPLAYMODE_TRACES)
	endif

	WAVE properties = pasi.properties
	WAVE/WAVE propertiesWaves = pasi.propertiesWaves

	numActive = DimSize(pasi.channels, ROWS)

	numTotalPulses = GetNumberFromWaveNote(properties, NOTE_INDEX)
	numPlotPulses = numTotalPulses - GetNumberFromWaveNote(properties, NOTE_PA_NEW_PULSES_START)

	WAVE/T paGraphData = GetPAGraphData()

	lblSweep = FindDimLabel(properties, COLS, "Sweep")
	lblChannelNumber = FindDimLabel(properties, COLS, "ChannelNumber")
	lblRegion = FindDimLabel(properties, COLS, "Region")
	lblHeadstage = FindDimLabel(properties, COLS, "Headstage")
	lblPulseHasFailed = FindDimLabel(properties, COLS, "PulseHasFailed")
	lblLastSweep = FindDimLabel(properties, COLS, "LastSweep")

	lblTRACES_AVERAGE = FindDimLabel(paGraphData, COLS, "TRACES_AVERAGE")
	lblTRACES_DECONV = FindDimLabel(paGraphData, COLS, "TRACES_DECONV")

	lblPWPULSE = FindDimLabel(propertiesWaves, COLS, "PULSE")

	Make/T/FREE/N=(numPlotPulses) hiddenTraces
	Duplicate/FREE/RMD=[][lblPWPULSE] propertiesWaves, pulseWaves
	jsonID = JSON_Parse("{}")
	if(pa.multipleGraphs)
		hideTraceJsonID = JSON_Parse("{}")
	endif

	if(mode == POST_PLOT_CONSTANT_SWEEPS && cs.failedPulses && cs.multipleGraphs && cs.hideFailedPulses && cs.showIndividualPulses && cs.showTraces)
		usedGraphs = PA_GetGraphs(win, PA_DISPLAYMODE_TRACES)
	else
		for(i = 0; i < numActive; i += 1)
			region = pasi.regions[i]
			if(pa.regionSlider != -1 && pa.regionSlider != region) // unselected region in ddaq viewing mode
				continue
			endif

			for(j = 0; j < numActive; j += 1)
				channelNumber = pasi.channels[j]
				// graph change logic
				if(!pa.multipleGraphs && j == 0 && i == 0 || pa.multipleGraphs)
					graph = PA_GetGraph(win, pa, PA_DISPLAYMODE_TRACES, channelNumber, region, i + 1, j + 1, numActive)
				endif
				// build list of used graphs, when not incremental we clear it on first encounter
				if(WhichListItem(graph, usedGraphs) == -1)
					// we want to keep the graphs for ADDED_SWEEPS or we have a change of hideFailedPulses
					if(!(mode == POST_PLOT_ADDED_SWEEPS || (mode == POST_PLOT_CONSTANT_SWEEPS && !cs.hideFailedPulses)))
						RemoveTracesFromGraph(graph)
						RemoveAnnotationsFromGraph(graph)
						graphDataIndex = PA_GetTraceCountFromGraphData(graph, clear = 1)
						resetGraphs = AddListItem(graph, resetGraphs, ";", inf)
					endif
					usedGraphs = AddListItem(graph, usedGraphs, ";", inf)
				endif

				if(!pa.showIndividualPulses)
					continue
				endif

				WAVE/T axesNames = pasi.axesNames[j][i]
				vertAxis = axesNames[0]
				horizAxis = axesNames[1]

				step = (i == j) ? 1 : PA_PLOT_STEPPING

				WAVE indices = pasi.setIndices[j][i]
				numEntries = pasi.numEntries[j][i]
				startEntry = pasi.startEntry[j][i]
				if(mode == POST_PLOT_CONSTANT_SWEEPS && !cs.hideFailedPulses)
					// Change hidden state only, maybe we can gather failed pulses already in the analysis routine?
					for(k = startEntry; k < numEntries; k += 1)
						idx = indices[k]
						if(properties[idx][lblPulseHasFailed])
							sprintf pulseTrace, "T%0*d%s", TRACE_NAME_NUM_DIGITS, idx, NameOfWave(propertiesWaves[idx][lblPWPULSE])
							if(pa.multipleGraphs)
								jsonPath = graph + "/hiddenTraces"
								JSON_AddTreeArray(hideTraceJsonID, jsonPath)
								JSON_AddString(hideTraceJsonID, jsonPath, pulseTrace)
							else
								hiddenTraces[hiddenTracesCount] = pulseTrace
								hiddenTracesCount += 1
							endif
						endif
					endfor
				else

					for(k = startEntry; k < numEntries; k += 1)
						idx = indices[k]
						pulseHasFailed = properties[idx][lblPulseHasFailed]
						if(pulseHasFailed)
							hideTrace = pa.hideFailedPulses
							s.red   = 65535
							s.green = 0
							s.blue  = 0
							alpha = 65535
						else
							hideTrace = 0
							[s] = GetTraceColor(properties[idx][lblHeadstage])
							alpha = 65535 * 0.2
						endif

						WAVE plotWave = propertiesWaves[idx][lblPWPULSE]
						sprintf pulseTrace, "T%0*d%s", TRACE_NAME_NUM_DIGITS, idx, NameOfWave(plotWave)

						jsonPath = graph + "/" + vertAxis + "/" + horizAxis + "/" + num2str(s.red) + "/" + num2str(s.green) + "/" + num2str(s.blue) + "/" + num2str(alpha) + "/" + num2str(step) + "/"
						JSON_AddTreeArray(jsonID, jsonPath + "index")
						JSON_AddTreeArray(jsonID, jsonPath + "traceName")
						JSON_AddVariable(jsonID, jsonPath + "index", idx)
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

						sweepNo = properties[idx][lblSweep]
						lastSweep = properties[idx][lblLastSweep]
						if(pulseHasFailed && (i == j) && (sweepNo == lastSweep))
							sprintf tagName "tag_%s_AD%d_R%d", vertAxis, channelNumber, region
							if(WhichListItem(tagName, AnnotationList(graph)) == -1)
								xPos = ((i + 1) / numActive) * 100 - 2
								yPos = ((j + 1) / numActive) * 100  - (1 / numActive) * 100 / 2
								Textbox/W=$graph/K/N=$tagName
								Textbox/W=$graph/N=$tagName/F=0/A=LT/L=0/X=(xPos)/Y=(ypos)/E=2 "☣️"
							endif
						endif

					endfor
				endif
			endfor
		endfor
	endif

	// Execute Append of traces and hide/unhide
	if(mode == POST_PLOT_CONSTANT_SWEEPS && !cs.hideFailedPulses)
		hideTrace = pa.hideFailedPulses
	else
		PA_AccelerateAppendTraces(jsonID, pulseWaves)
		hideTrace = 1
	endif

	if(pa.multipleGraphs)
		WAVE/T hiddenTracesGraphs = JSON_GetKeys(hideTraceJsonID, "")
		numHiddenTracesGraphs = DimSize(hiddenTracesGraphs, ROWS)
		for(j = 0; j < numHiddenTracesGraphs; j += 1)
			WAVE/T hiddenTracesNames = JSON_GetTextWave(hideTraceJsonID, hiddenTracesGraphs[j] + "/hiddenTraces")
			AccelerateHideTraces(hiddenTracesGraphs[j], hiddenTracesNames, DimSize(hiddenTracesNames, ROWS), hideTrace)
		endfor
		JSON_Release(hideTraceJsonID)
	elseif(!IsEmpty(graph))
		AccelerateHideTraces(graph, hiddenTraces, hiddenTracesCount, hideTrace)
	endif

	JSON_Release(jsonID)

	// We need this information for the deconvolution plots, since the diagonality might have changed
	layoutChanged = GetNumberFromWaveNote(properties, PA_PROPERTIES_KEY_LAYOUTCHANGE) && mode != POST_PLOT_CONSTANT_SWEEPS
	Make/T/FREE/N=(numActive * numActive) avgPlotTraces, deconPlotTraces
	for(i = 0; i < numActive; i += 1)
		region = pasi.regions[i]
		for(j = 0; j < numActive; j += 1)
			channelNumber = pasi.channels[j]

			plottedAvgTraces = 0

			WAVE/T axesNames = pasi.axesNames[j][i]
			vertAxis = axesNames[0]
			horizAxis = axesNames[1]

			if(!pa.multipleGraphs && i == 0 && j == 0 || pa.multipleGraphs)
				graph = PA_GetGraph(win, pa, PA_DISPLAYMODE_TRACES, channelNumber, region, i + 1, j + 1, numActive)
				graphDataIndex = PA_GetTraceCountFromGraphData(graph)
				WAVE/T averageTraceNames = ListToTextWave(paGraphData[graphDataIndex][lblTRACES_AVERAGE], ";")
				WAVE/T deconvolutionTraceNames = ListToTextWave(paGraphData[graphDataIndex][lblTRACES_DECONV], ";")
				graphWasReset = WhichListItem(graph, resetGraphs, ";") != -1
			endif

			WAVE/Z averageWave
			[averageWave, baseName] = PA_GetPermanentAverageWave(pasi.pulseAverageDFR, channelNumber, region)

			sprintf traceName, "Ovl_%s%s", PA_AVERAGE_WAVE_PREFIX, baseName

			if(WaveExists(averageTraceNames))
				WAVE/T/Z foundTraces = GrepTextWave(averageTraceNames, "^.*" + PA_AVERAGE_WAVE_PREFIX + basename + "$")
			else
				WAVE/T/Z foundTraces = $""
			endif

			if(!(cs.showAverage && cs.multipleGraphs) || graphWasReset)

				if(WaveExists(foundTraces))
					RemoveFromGraph/W=$graph $foundTraces[0]
					paGraphData[graphDataIndex][lblTRACES_AVERAGE] = RemoveFromList(foundTraces[0], paGraphData[graphDataIndex][lblTRACES_AVERAGE], ";")
					pasi.ovlTracesAvg[j][i] = 0
				endif

				if(pa.showAverage && WaveExists(averageWave))

					[s] = GetTraceColor(NUM_HEADSTAGES + 1)
					AppendToGraph/Q/W=$graph/L=$vertAxis/B=$horizAxis/C=(s.red, s.green, s.blue) averageWave/TN=$traceName
					pasi.ovlTracesAvg[j][i] = 1
					plottedAvgTraces = 1

					if(pa.multipleGraphs)
						ModifyGraph/W=$graph lsize($traceName)=PA_AVGERAGE_PLOT_LSIZE
					else
						avgPlotTraces[avgPlotCount] = traceName
						avgPlotCount += 1
					endif

					paGraphData[graphDataIndex][lblTRACES_AVERAGE] = AddListItem(traceName, paGraphData[graphDataIndex][lblTRACES_AVERAGE], ";", Inf)
				endif
			endif

			if((	graphwasReset		\
				|| layoutChanged			\
				|| !cs.multipleGraphs	\
				|| !cs.deconvolution   \
				|| !cs.failedPulses    \
				|| plottedAvgTraces) && (i != j))

				sprintf traceName, "Ovl_%s%s", PA_DECONVOLUTION_WAVE_PREFIX, baseName

				if(WaveExists(deconvolutionTraceNames))
					WAVE/T/Z foundTraces = GrepTextWave(deconvolutionTraceNames, "^.*" + PA_DECONVOLUTION_WAVE_PREFIX + basename + "$")
				else
					WAVE/T/Z foundTraces = $""
				endif

				if(WaveExists(foundTraces))
					RemoveFromGraph/W=$graph $foundTraces[0]
					paGraphData[graphDataIndex][lblTRACES_DECONV] = RemoveFromList(foundTraces[0], paGraphData[graphDataIndex][lblTRACES_DECONV], ";")
					pasi.ovlTracesDeconv[j][i] = 0
				endif

				if(pa.deconvolution.enable && WaveExists(averageWave))
					WAVE deconv = PA_Deconvolution(averageWave, pasi.pulseAverageDFR, PA_DECONVOLUTION_WAVE_PREFIX + baseName, pa.deconvolution)
					AppendToGraph/Q/W=$graph/L=$vertAxis/B=$horizAxis/C=(0,0,0) deconv[0,inf;PA_PLOT_STEPPING]/TN=$traceName
					pasi.ovlTracesDeconv[j][i] = 1

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

	PA_DrawScaleBars(win, pa, pasi, PA_DISPLAYMODE_TRACES, PA_USE_WAVE_SCALES)
	PA_LayoutGraphs(win, pa, pasi, PA_DISPLAYMODE_TRACES)
	PA_DrawXZeroLines(win, pa, pasi, PA_DISPLAYMODE_TRACES)

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
		PA_GetTraceCountFromGraphData(graph, clear = 1)
	endfor
End

/// @brief Helper structure to store the constantness of various categories of settings.
static Structure PA_ConstantSettings
	variable singlePulse
	variable traces // includes general and single pulse settings
	variable images // includes general and single pulse settings
	variable failedPulses // includes search on/off and level change and mode == POST_PLOT_CONSTANT_SWEEPS
	variable dontResetWaves
	variable multipleGraphs
	variable showAverage
	variable deconvolution
	variable hideFailedPulses
	variable showIndividualPulses
	variable showTraces
EndStructure

/// @brief Returns a filled structure #PA_ConstantSettings which has 1 for all
///        constant entries of the given category.
static Function [STRUCT PA_ConstantSettings cs] PA_DetermineConstantSettings(STRUCT PulseAverageSettings &pa, STRUCT PulseAverageSettings &paOld, variable mode)

	variable generalSettings

	if(mode != POST_PLOT_CONSTANT_SWEEPS)
		cs.singlePulse = 0
		cs.traces = 0
		cs.images = 0
		cs.dontResetWaves = 0
		cs.failedPulses = 0
		cs.multipleGraphs = 0
		cs.showAverage = 0
		cs.deconvolution = 0
		cs.hideFailedPulses = 0
		cs.showIndividualPulses = 0
		cs.showTraces = 0
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

	cs.failedPulses = (		pa.searchFailedPulses == paOld.searchFailedPulses \
							&& pa.failedPulsesLevel ==  paOld.failedPulsesLevel)

	cs.dontResetWaves = (pa.zeroPulses == paOld.zeroPulses                 \
							&& pa.autoTimeAlignment == paOld.autoTimeAlignment \
							&& cs.failedPulses)

	cs.multipleGraphs = pa.multipleGraphs == paOld.multipleGraphs

	cs.showAverage = pa.showAverage == paOld.showAverage

	cs.deconvolution = (pa.deconvolution.enable == paOld.deconvolution.enable \
							&& pa.deconvolution.smth == paOld.deconvolution.smth   \
							&& pa.deconvolution.tau == paOld.deconvolution.tau     \
							&& pa.deconvolution.range == paOld.deconvolution.range)

	cs.hideFailedPulses = pa.hideFailedPulses == paOld.hideFailedPulses

	cs.showIndividualPulses = pa.showIndividualPulses == paOld.showIndividualPulses

	cs.showTraces = pa.showTraces == paOld.showTraces

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
/// @retval pasi structure keeping references to current PA data set
/// @retval needsPlotting dest boolean denoting if there are pulses to plot
static Function [STRUCT PulseAverageSetIndices pasi, variable needsPlotting] PA_PreProcessPulses(string win, STRUCT PulseAverageSettings &pa, STRUCT PA_ConstantSettings &cs, variable mode, WAVE/Z additionalData)

	string preExistingGraphs, graph

	variable s

	preExistingGraphs = PA_GetGraphs(win, PA_DISPLAYMODE_ALL)
	graph = GetMainWindow(win)

	if(!pa.enabled)
		KillWindows(preExistingGraphs)
		DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)
		KillOrMoveToTrash(dfr = pulseAverageHelperDFR)
		return [pasi, 0]
	endif

	if(mode == POST_PLOT_CONSTANT_SWEEPS && cs.singlePulse)
		[pasi] = PA_InitPASIInParts(pa, PA_PASIINIT_BASE | PA_PASIINIT_INDICEMETA, 1)
	else
		s = stopmstimer(-2)
		[pasi] = PA_GenerateAllPulseWaves(win, pa, mode, additionalData)
		print/D "PA_GenerateAllPulseWaves", (stopmstimer(-2) - s) / 1E6
	endif

	if(!WaveExists(pasi.setIndices))
		PA_ClearGraphs(preExistingGraphs)
		return [pasi, 0]
	endif

	if(!(mode == POST_PLOT_CONSTANT_SWEEPS && cs.images))
		s = stopmstimer(-2)
		// if CONSTANT_SWEEPS and not changed or no image shown, no need to call
		WAVE indexHelper = pasi.indexHelper
		Multithread indexHelper[][] = PA_ApplyPulseSortingOrder(pasi.setIndices[p][q], pasi.channels[p], pasi.regions[q], pasi.properties, pa)
		print/D "PA_ApplyPulseSortingOrder", (stopmstimer(-2) - s) / 1E6
	endif

	if(!(mode == POST_PLOT_CONSTANT_SWEEPS && cs.dontResetWaves))
		s = stopmstimer(-2)
		pasi.indexHelper[][] = PA_ResetWavesIfRequired(pasi.setWaves2[p][q], pa)
		print/D "PA_ResetWavesIfRequired", (stopmstimer(-2) - s) / 1E6
	endif

	if(!(mode == POST_PLOT_CONSTANT_SWEEPS && cs.failedPulses))
		s = stopmstimer(-2)
		PA_MarkFailedPulses(pa, pasi)
		print/D "PA_MarkFailedPulses", (stopmstimer(-2) - s) / 1E6
	endif

	// cs.dontResetWaves contains that zeroPulse setting did not change
	if(!(mode == POST_PLOT_CONSTANT_SWEEPS && cs.dontResetWaves) && pa.zeroPulses)
		s = stopmstimer(-2)
		pasi.indexHelper[][] = PA_ZeroPulses(pasi.setWaves2[p][q])
		print/D "PA_ZeroPulses", (stopmstimer(-2) - s) / 1E6
	endif

	// cs.dontResetWaves contains that autoTimeAlignment setting did not change
	if(!(mode == POST_PLOT_CONSTANT_SWEEPS && cs.dontResetWaves) && pa.autoTimeAlignment)
		s = stopmstimer(-2)
		PA_AutomaticTimeAlignment(pasi)
		print/D "PA_AutomaticTimeAlignment", (stopmstimer(-2) - s) / 1E6
	endif

	if(!(mode == POST_PLOT_CONSTANT_SWEEPS && cs.dontResetWaves && cs.failedPulses))
		s = stopmstimer(-2)
		PA_CalculateAllAverages(pasi, mode)
		print/D "PA_CalculateAllAverages", (stopmstimer(-2) - s) / 1E6
	endif

	return [pasi, 1]
End

static Function PA_CalculateAllAverages(STRUCT PulseAverageSetIndices &pasi, variable mode)

	variable numThreads, numActive
	string keyAll, keyOld

	WAVE indexHelper = pasi.indexHelper
	numActive = DimSize(pasi.channels, ROWS)

	Make/FREE/WAVE/N=(numActive, numActive) setWavesOld, setWavesAll, setWavesNew, setWaves2AllNewOld, avg
	numThreads = min(numActive * numActive, ThreadProcessorCount)

	// We need the setWaves without failedPulses that were marked previously. So we can not use the setWave2 from pasi, as these are including ALL pulses.
	Multithread/NT=(numThreads) setWaves2AllNewOld[][] = PA_GetSetWaves_TS(pasi.properties, pasi.propertiesWaves, pasi.setIndices[p][q], PA_GETSETWAVES_ALL | PA_GETSETWAVES_NEW | PA_GETSETWAVES_OLD, 1)
	Multithread/NT=(numThreads) setWavesAll[][] = PA_ExtractPulseSetFromSetWaves2(WaveRef(setWaves2AllNewOld[p][q], row = 0))
	keyAll = CA_AveragingWaveModKey(setWavesAll)
	WAVE/WAVE/Z cache = CA_TryFetchingEntryFromCache(keyAll, options = CA_OPTS_NO_DUPLICATE)
	if(!WaveExists(cache))
		print "Cache Miss All"
		// we have to calculate
		if(mode == POST_PLOT_ADDED_SWEEPS)
			Multithread/NT=(numThreads) setWavesOld[][] = PA_ExtractPulseSetFromSetWaves2(WaveRef(setWaves2AllNewOld[p][q], row = 2))
			keyOld = CA_AveragingWaveModKey(setWavesOld)
			WAVE/WAVE/Z cache = CA_TryFetchingEntryFromCache(keyOld, options = CA_OPTS_NO_DUPLICATE)
			if(WaveExists(cache))
				Multithread/NT=(numThreads) setWavesNew[][] = PA_ExtractPulseSetFromSetWaves2(WaveRef(setWaves2AllNewOld[p][q], row = 1))
				Multithread/NT=(numThreads) avg[][] = MIES_fWaveAverage(setWavesNew[p][q], 0, IGOR_TYPE_32BIT_FLOAT, getComponents = 1, prevAvgData = PA_ExtractSumsCountsOnly(cache[p][q]))
			else
				Multithread/NT=(numThreads) avg[][] = MIES_fWaveAverage(setWavesAll[p][q], 0, IGOR_TYPE_32BIT_FLOAT, getComponents = 1)
			endif
		else
			Multithread/NT=(numThreads) avg[][] = MIES_fWaveAverage(setWavesAll[p][q], 0, IGOR_TYPE_32BIT_FLOAT, getComponents = 1)
		endif

		Multithread indexHelper[][] = PA_StoreMaxAndUnitsInWaveNote(WaveRef(avg[p][q], row = 0), WaveRef(setWavesAll[p][q], row = 0))
		CA_StoreEntryIntoCache(keyAll, avg, options = CA_OPTS_NO_DUPLICATE)
	else
		print "Cache Hit All"
		WAVE/WAVE avg = cache
	endif

	indexHelper[][] = PA_MakeAverageWavePermanent(pasi.pulseAverageDFR, WaveRef(avg[p][q], row = 0), pasi.channels[p], pasi.regions[q])
End

static Function PA_MakeAverageWavePermanent(DFREF dfr, WAVE/Z avg, variable channel, variable region)

	string baseName

	if(WaveExists(avg))
		ConvertFreeWaveToPermanent(avg, dfr, PA_AVERAGE_WAVE_PREFIX + PA_BaseName(channel, region))
	else
		// no data, we remove permanent wave
		[avg, baseName] = PA_GetPermanentAverageWave(dfr, channel, region)
		if(WaveExists(avg))
			KillOrMoveToTrash(wv = avg)
		endif
	endif
End

static Function [WAVE avg_, string baseName_] PA_GetPermanentAverageWave(DFREF dfr, variable channel, variable region)

	string baseName, wName

	baseName = PA_BaseName(channel, region)
	wName = PA_AVERAGE_WAVE_PREFIX + baseName
	WAVE/Z avg = dfr:$wName

	return [avg, baseName]
End

threadsafe static Function/WAVE PA_ExtractPulseSetFromSetWaves2(WAVE/WAVE setWave2)

	if(!WaveExists(setWave2))
		return $""
	endif
	// Maybe SplitWave is faster
	Duplicate/FREE/RMD=[][0] setWave2, setWave
	Redimension/N=(-1) setWave
	return setWave
End

threadsafe static Function PA_StoreMaxAndUnitsInWaveNote(WAVE/Z w, WAVE/Z unitSource)

	if(!WaveExists(w))
		return 1
	endif

	if(!WaveExists(unitSource))
		ASSERT_TS(0, "Attempt to set data units in existing wave, but data unit source wave is null.")
	endif

	SetScale d, 0, 0, WaveUnits(unitSource, -1), w
	SetNumberInWaveNote(w, "WaveMaximum", WaveMax(w), format = "%.15f")
	return 0
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
	STRUCT PulseAverageSetIndices pasi

	if(GrepString(win, PA_GRAPH_PREFIX))
		bsPanel = GetUserData(win, "", MIES_BSP_PA_MAINPANEL)
	else
		bsPanel = BSP_GetPanel(win)
	endif

	ASSERT(WindowExists(win), "Missing window")

	displayMode = ItemsInList(ImageNameList(win, ";")) > 0 ? PA_DISPLAYMODE_IMAGES : PA_DISPLAYMODE_TRACES

	STRUCT PulseAverageSettings pa
	PA_GatherSettings(bsPanel, pa)
	[pasi] = PA_InitPASIInParts(pa, PA_PASIINIT_BASE | PA_PASIINIT_INDICEMETA, 1)
	PA_DrawScaleBars(bsPanel, pa, pasi, displayMode, PA_USE_AXIS_SCALES)
End

static Function PA_DrawScaleBars(string win, STRUCT PulseAverageSettings &pa, STRUCT PulseAverageSetIndices &pasi, variable displayMode, variable axisMode)

	variable i, j, numActive, region, channelNumber, drawXScaleBarOverride
	variable maximum, length, drawYScaleBarOverride
	string graph, vertAxis, horizAxis, xUnit, yUnit, baseName

	if((!pa.showIndividualPulses && !pa.showAverage && !pa.deconvolution.enable) \
	   || (!pa.showTraces && displayMode == PA_DISPLAYMODE_TRACES)               \
	   || (!pa.showImages && displayMode == PA_DISPLAYMODE_IMAGES))
		// blank graph
		// This check is only relevant when called from the AxisHook?
		return NaN
	endif

	numActive = DimSize(pasi.channels, ROWS)

	for(i = 0; i < numActive; i += 1)
		channelNumber = pasi.channels[i]
		for(j = 0; j < numActive; j += 1)
			region = pasi.regions[j]

			if(!(pa.showIndividualPulses * pasi.numEntries[i][j] + pasi.ovlTracesAvg[i][j] + pasi.ovlTracesDeconv[i][j]))
				continue
			endif

			graph = PA_GetGraph(win, pa, displayMode, channelNumber, region, j + 1, i + 1, numActive)

			WAVE/T axesNames = pasi.axesNames[i][j]
			vertAxis = axesNames[0]
			horizAxis = axesNames[1]

			if(!pa.multipleGraphs && i == 0 && j == 0 || pa.multipleGraphs)
				NewFreeAxis/R/O/W=$graph fakeAxis
				ModifyFreeAxis/W=$graph fakeAxis, master=$horizAxis, hook=PA_AxisHook
				ModifyGraph/W=$graph nticks(fakeAxis)=0, noLabel(fakeAxis)=2, axthick(fakeAxis)=0
				SetDrawLayer/K/W=$graph $PA_DRAWLAYER_SCALEBAR
			endif

			WAVE/Z averageWave
			[averageWave, baseName] = PA_GetPermanentAverageWave(pasi.pulseAverageDFR, channelNumber, region)
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

			PA_DrawScaleBarsHelper(graph, axisMode, displayMode, pasi.setWaves2[i][j], vertAxis, horizAxis, length, xUnit, yUnit, i + 1, j + 1, numActive)
		endfor
	endfor
End

static Function	[variable vert_min, variable vert_max, variable horiz_min, variable horiz_max] PA_GetMinAndMax(WAVE/WAVE setWaves2)

	variable numPulses = DimSize(setWaves2, ROWS)

	Make/D/FREE/N=(numPulses) vertDataMin = GetNumberFromWaveNote(setWaves2[p][1], "WaveMinimum")
	Make/D/FREE/N=(numPulses) vertDataMax = GetNumberFromWaveNote(setWaves2[p][1], "WaveMaximum")

	Make/D/FREE/N=(numPulses) horizDataMin = leftx(setWaves2[p][0])
	Make/D/FREE/N=(numPulses) horizDataMax = pnt2x(setWaves2[p][0], DimSize(setWaves2[p][0], ROWS) - 1)

	return [WaveMin(vertDataMin), WaveMax(vertDataMax), WaveMin(horizDataMin), WaveMax(horizDataMax)]
End

static Function PA_DrawScaleBarsHelper(string win, variable axisMode, variable displayMode, WAVE/WAVE setWaves2, string vertAxis, string horizAxis, variable ylength, string xUnit, string yUnit, variable activeChanCount, variable activeRegionCount, variable numActive)

	string graph, msg, str, axList
	variable vertAxis_y, vertAxis_x, xLength
	variable vert_min, vert_max, horiz_min, horiz_max, drawLength
	variable xBarBottom, xBarTop, yBarBottom, yBarTop, labelOffset
	variable xBarLeft, xBarRight, yBarLeft, yBarRight, drawXScaleBar, drawYScaleBar

	drawXScaleBar = (activeChanCount == numActive)
	drawYScaleBar = (activeChanCount != activeRegionCount) && (displayMode != PA_DISPLAYMODE_IMAGES)

	if(!drawXScaleBar && !drawYScaleBar)
		return NaN
	endif

	graph = GetMainWindow(win)

	switch(axisMode)
		case PA_USE_WAVE_SCALES:
			switch(displayMode)
				case PA_DISPLAYMODE_TRACES:
					[vert_min, vert_max, horiz_min, horiz_max] = PA_GetMinAndMax(setWaves2)
					break
				case PA_DISPLAYMODE_IMAGES:
					[vert_min, vert_max, horiz_min, horiz_max] = PA_GetMinAndMax(setWaves2)
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

		drawLength = (activeChanCount == numActive) && (activeRegionCount == 1)

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

		drawLength = (activeChanCount == numActive) && (activeRegionCount == numActive)

		DrawScaleBar(graph, xBarLeft, yBarLeft, xBarRight, yBarRight, unit=xUnit, drawLength=drawLength)

		SetDrawEnv/W=$graph gstop
	endif

	SetDrawEnv/W=$graph pop
End

static Function PA_PulseHasFailed(WAVE noteWave, STRUCT PulseAverageSettings &s)

	variable level, hasFailed

	if(!s.searchFailedPulses)
		return 0
	endif

	level     = GetNumberFromWaveNote(noteWave, NOTE_KEY_FAILED_PULSE_LEVEL)
	hasFailed = GetNumberFromWaveNote(noteWave, PA_NOTE_KEY_PULSE_FAILED)

	if(level == s.failedPulsesLevel && IsFinite(hasFailed))
		// already investigated
		return hasFailed
	endif

	ASSERT(GetNumberFromWaveNote(noteWave, NOTE_KEY_ZEROED) != 1, "Single pulse wave must not be zeroed here")

	level = s.failedPulsesLevel

	hasFailed = !(level >= GetNumberFromWaveNote(noteWave, "WaveMinimum")     \
				  && level <= GetNumberFromWaveNote(noteWave, "WaveMaximum"))

	SetNumberInWaveNote(noteWave, PA_NOTE_KEY_PULSE_FAILED, hasFailed)
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
threadsafe static Function PA_ZeroPulses(WAVE/Z setWave2)

	if(!WaveExists(setWave2))
		return NaN
	endif

	WAVE/WAVE set2 = setWave2

	Make/FREE/N=(DimSize(set2, ROWS)) junk
	Multithread junk = PA_ZeroWave(set2[p][0], set2[p][1])
End

/// @brief Zero the wave using differentiation and integration
///
/// Overwrites the input wave
/// Preserves the WaveNote and adds the entry NOTE_KEY_ZEROED
///
/// 2D waves are zeroed along each row
threadsafe static Function PA_ZeroWave(WAVE wv, WAVE noteWave)

	if(GetNumberFromWaveNote(noteWave, NOTE_KEY_ZEROED) == 1)
		return 0
	endif

	ZeroWaveImpl(wv)

	PA_UpdateMinAndMax(wv, noteWave)

	SetNumberInWaveNote(noteWave, NOTE_KEY_ZEROED, 1)

	return 1
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
		if(DimOffset(input, ROWS) != DimOffset(cache, ROWS))
			CopyScales/P input, cache
		endif
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
		// CA_Deconv relies on data content and DimDelta of input
		// In the case where time alignment changed the DimOffset of input (based on averaging of the pulses),
		// we can reuse the cached wave, but we need to transfer the DimOffset.
		if(DimOffset(average, ROWS) != DimOffset(cache, ROWS))
			CopyScales/P average, cache
		endif
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

/// @brief Time alignment for PA single pulses
///
/// \rst
/// See :ref:`db_paplot_timealignment` for an explanation of the algorithm.
/// \endrst
static Function PA_AutomaticTimeAlignment(STRUCT PulseAverageSetIndices &pasi)

	variable i, j, numActive, jsonID, numEntries
	variable lblPWPULSE, lblPWPULSENOTE, lblSweep, lblPulse

	WAVE properties = pasi.properties
	WAVE/WAVE propertiesWaves = pasi.propertiesWaves

	numActive = DimSize(pasi.channels, ROWS)

	lblPWPULSE = FindDimLabel(propertiesWaves, COLS, "PULSE")
	lblPWPULSENOTE = FindDimLabel(propertiesWaves, COLS, "PULSENOTE")
	lblSweep = FindDimLabel(properties, COLS, "Sweep")
	lblPulse = FindDimLabel(properties, COLS, "Pulse")

	jsonID = JSON_New()
	Make/D/FREE/N=0 featurePos, junk
	Make/T/FREE/N=0 keys

	for(i = 0; i < numActive; i += 1)
		// diagonal element for the given region
		// gather feature positions for all pulses diagonal set
		WAVE setIndizes = pasi.setIndices[i][i]
		numEntries = pasi.numEntries[i][i]
		if(numEntries == 0)
			continue
		endif

		Redimension/N=(numEntries) featurePos, junk, keys
		Multithread featurePos[] = PA_GetFeaturePosition(propertiesWaves[setIndizes[p]][lblPWPULSE], propertiesWaves[setIndizes[p]][lblPWPULSENOTE])
		Multithread keys = "/" + num2str(properties[setIndizes[p]][lblSweep]) + "-" + num2str(properties[setIndizes[p]][lblPulse])
		// store featurePos using sweep and pulse combination as key
		junk[] = JSON_SetVariable(jsonID, keys[p], featurePos[p])

		for(j = 0; j < numActive; j += 1)
			WAVE setIndizes = pasi.setIndices[j][i]
			numEntries = pasi.numEntries[j][i]
			if(numEntries == 0)
				continue
			endif

			Redimension/N=(numEntries) keys, junk
			Multithread keys[] = "/" + num2str(properties[setIndizes[p]][lblSweep]) + "-" + num2str(properties[setIndizes[p]][lblPulse])
			Multithread junk[] = PA_SetFeaturePosition(propertiesWaves[setIndizes[p]][lblPWPULSE], propertiesWaves[setIndizes[p]][lblPWPULSENOTE], JSON_GetVariable(jsonID, keys[p], ignoreErr=1))
		endfor
	endfor

	JSON_Release(jsonID)
End

threadsafe static Function PA_GetFeaturePosition(WAVE wv, WAVE noteWave)

	variable featurePos

	featurePos = GetNumberFromWaveNote(noteWave, "TimeAlignmentFeaturePosition")

	if(IsFinite(featurePos))
		return featurePos
	endif

	WaveStats/M=1/Q wv
	featurePos = V_maxLoc
	SetNumberInWaveNote(noteWave, "TimeAlignmentFeaturePosition", featurePos, format="%.15g")
	return featurePos
End

threadsafe static Function PA_SetFeaturePosition(WAVE wv, WAVE noteWave, variable featurePos)

	variable offset
	string name

	if(GetNumberFromWaveNote(noteWave, NOTE_KEY_TIMEALIGN) == 1)
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
	SetNumberInWaveNote(noteWave, "TimeAlignmentTotalOffset", offset, format="%.15g")
	SetNumberInWaveNote(noteWave, NOTE_KEY_TIMEALIGN, 1)
End

/// @brief Reset All pulse and pulse note waves from a set to its original state if they are outdated
///
// PA waves get an entry to their wave note as soon as they are modified. If
// this entry does not match the current panel selection, they are resetted to
// redo the calculation from the beginning.
//
// @param setWave2  a set of waves that need to be tested
// @param pa       Filled PulseAverageSettings structure. @see PA_GatherSettings
static Function PA_ResetWavesIfRequired(WAVE/Z setWave2, STRUCT PulseAverageSettings &pa)
	variable i, statusZero, statusTimeAlign, numEntries, statusSearchFailedPulse
	variable failedPulseLevel

	if(!WaveExists(setWave2))
		return NaN
	endif

	WAVE/WAVE set2 = setWave2

	numEntries = DimSize(set2, ROWS)
	for(i = 0; i < numEntries; i += 1)
		WAVE noteWave = set2[i][1]

		statusZero = GetNumberFromWaveNote(noteWave, NOTE_KEY_ZEROED)
		statusTimeAlign = GetNumberFromWaveNote(noteWave, NOTE_KEY_TIMEALIGN)
		statusSearchFailedPulse = GetNumberFromWaveNote(noteWave, NOTE_KEY_SEARCH_FAILED_PULSE)

		if(statusZero == 0 && statusTimeAlign == 0 && statusSearchFailedPulse == 0)
			continue // wave is unmodified
		endif

		if(statusZero == pa.zeroPulses                          \
		   && statusTimeAlign == pa.autoTimeAlignment           \
		   && statusSearchFailedPulse == pa.searchFailedPulses)

			failedPulseLevel = GetNumberFromWaveNote(noteWave, NOTE_KEY_FAILED_PULSE_LEVEL)

			// when zeroing and failed pulse search is enabled, we always
			// need to reset the waves when the level changes
			if(!(pa.zeroPulses && pa.searchFailedPulses && pa.failedPulsesLevel != failedPulseLevel))
				continue // wave is up to date
			endif
		endif

		ReplaceWaveWithBackup(set2[i][0], nonExistingBackupIsFatal = 1, keepBackup = 1)
		ReplaceWaveWithBackup(set2[i][1], nonExistingBackupIsFatal = 1, keepBackup = 1)
	endfor
End

/// @brief This is a light weight adapted version of @sa EquallySpaceAxis
///        It allows to give a list of distAxes that do not require to exist.
///        Non-existing axes are taken into account on the distribution, but are skipped when the graph is accessed.
///        Also removing images from a graph does not update AxisList until the graph is updated,
///        so we can not rely on Axislist here as we do the Layout after pending changes
static Function PA_EquallySpaceAxis(string graph, string allAxes, string distAxes, [variable axisOffset])

	variable numAxes, i
	string axis

	if(ParamIsDefault(axisOffset))
		axisOffset = 0
	else
		ASSERT(axisOffset >=0 && axisOffset <= 1.0, "Invalid axis offset")
	endif

	numAxes = ItemsInList(distAxes, ";")
	if(numAxes > 0)
		WAVE/Z axisStart, axisEnd
		[axisStart, axisEnd] = DistributeElements(numAxes, offset = axisOffset)
		for(i = 0; i < numAxes; i += 1)
			axis = StringFromList(i, distAxes)
			if(WhichListItem(axis, allAxes, ";") != -1)
				ModifyGraph/Z/W=$graph axisEnab($axis) = {axisStart[i], axisEnd[i]}
			endif
		endfor
	endif
End

static Function PA_LayoutGraphs(string win, STRUCT PulseAverageSettings &pa, STRUCT PulseAverageSetIndices &pasi, variable displayMode)

	variable i, j, numActive, numEntries
	variable channelNumber, headstage, red, green, blue, region, xStart
	string graph, str, horizAxis, vertAxis, allAxes, vertAxes, horizAxes
	STRUCT RGBColor s

	numActive = DimSize(pasi.channels, ROWS)

	if(!pa.multipleGraphs)
		graph = PA_GetGraphName(win, pa, displayMode, NaN, NaN)
		allAxes = AxisList(graph)

#ifdef PA_HIDE_AXIS
		ModifyGraph/W=$graph mode=0, nticks=0, noLabel=2, axthick=0
#endif

		if(displayMode == PA_DISPLAYMODE_TRACES)
			ModifyGraph/W=$graph margin(left)=30, margin(top)=20, margin(right)=14, margin(bottom)=14
		elseif(displayMode == PA_DISPLAYMODE_IMAGES)
			ModifyGraph/W=$graph margin=2, margin(right)=10, margin(bottom)=14
		endif

		Make/FREE/T/N=(numActive) axisWave
		Make/FREE/WAVE/N=(numActive) axisWaveRef
		axisWaveRef[] = pasi.axesNames[0][p]
		for(j = 0; j < numActive; j += 1)
			WAVE/T wt = axisWaveRef[j]
			axisWave[j] = wt[1]
		endfor
		horizAxes = TextWaveToList(axisWave, ";")
		PA_EquallySpaceAxis(graph, allAxes, horizAxes, axisOffset=PA_X_AXIS_OFFSET)

		for(i = 0; i < numActive; i += 1)
			axisWaveRef[] = pasi.axesNames[p][i]
			for(j = 0; j < numActive; j += 1)
				WAVE/T wt = axisWaveRef[j]
				axisWave[numActive - j - 1] = wt[0]
			endfor
			vertAxes = TextWaveToList(axisWave, ";")
			PA_EquallySpaceAxis(graph, allAxes, vertAxes)
			for(j = 0; j < numActive; j += 1)

				WAVE/T axesNames = pasi.axesNames[j][i]
				vertAxis = axesNames[0]
				horizAxis = axesNames[1]

				xStart = GetNumFromModifyStr(AxisInfo(graph, horizAxis), "axisEnab", "{", 0)
				ModifyGraph/W=$graph/Z freePos($vertAxis)={xStart - PA_X_AXIS_OFFSET,kwFraction}
			endfor

			ModifyGraph/W=$graph/Z freePos($horizAxis)=0
		endfor

		return NaN
	endif

	WAVE properties = pasi.properties
	for(i = 0; i < numActive; i += 1)
		channelNumber = pasi.channels[i]
		for(j = 0; j < numActive; j += 1)
			region = pasi.regions[j]

			graph = PA_GetGraphName(win, pa, displayMode, channelNumber, j + 1)

			WAVE setIndizes = pasi.setIndices[i][j]
			numEntries = GetnumberFromWaveNote(setIndizes, NOTE_INDEX)

			Make/FREE/N=(numEntries) pulsesNonUnique = properties[setIndizes[p]][%Pulse]
			WAVE pulses = GetUniqueEntries(pulsesNonUnique)

			Make/FREE/N=(numEntries) sweepsNonUnique = properties[setIndizes[p]][%Sweep]
			WAVE sweeps = GetUniqueEntries(sweepsNonUnique)

			Make/FREE/N=(numEntries) headstagesNonUnique = properties[setIndizes[p]][%Headstage]
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

static Function PA_AddColorScales(string win, STRUCT PulseAverageSettings &pa, STRUCT PulseAverageSetIndices &pasi)

	string name, text, graph, vertAxis, horizAxis, traceName, msg, colorScaleGraph, imageGraph
	variable i, j, numActive, scaleDiag, scaleRows, region, channelNumber, regionTaken
	variable minimumDiag, maximumDiag, minimum, maximum, yPos, lastEntry
	variable numSlots, numEntries, headstage
	string graphsToResize = ""

	numActive = DimSize(pasi.channels, ROWS)

	WAVE properties = pasi.properties

	minimumDiag = Inf
	maximumDiag = -Inf

	Make/FREE/D/N=(numActive) minimumRows = Inf
	Make/FREE/D/N=(numActive) maximumRows = -Inf

	for(i = 0; i < numActive; i += 1)
		region = pasi.regions[i]

		for(j = 0; j < numActive; j += 1)
			channelNumber = pasi.channels[j]

			if(!pa.multipleGraphs && i == 0 && j == 0 || pa.multipleGraphs)
				graph = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, i + 1)
			endif

			WAVE/T axesNames = pasi.axesNames[j][i]
			vertAxis = axesNames[0]
			horizAxis = axesNames[1]

			// only show filled in pulses for the vertical axis
			WAVE img = GetPulseAverageSetImageWave(pasi.pulseAverageDFR, channelNumber, region)
			lastEntry = GetNumberFromWaveNote(img, NOTE_INDEX)
			GetAxis/Q/W=$graph $vertAxis
			ASSERT(V_flag == 0, "Missing axis")
			SetAxis/W=$graph $vertAxis, -0.5, lastEntry - 0.5

			minimum = GetNumberFromWaveNote(img, "PulsesMinimum")
			maximum = GetNumberFromWaveNote(img, "PulsesMaximum")

			// gather min/max for diagonal and off-diagonal elements
			if(i == j)
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

		for(i = 0; i < numActive; i += 1)
			[minimum, maximum] = SymmetrizeRangeAroundZero(minimumRows[i], maximumRows[i])
			minimumRows[i] = minimum
			maximumRows[i] = maximum
		endfor
	endif

	for(i = 0; i < numActive; i += 1)
		region = pasi.regions[i]

		for(j = 0; j < numActive; j += 1)
			channelNumber = pasi.channels[j]

			if(!pa.multipleGraphs && i == 0 && j == 0 || pa.multipleGraphs)
				graph = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, i + 1)
				graphsToResize = AddListItem(graph, graphsToResize, ";", Inf)
				colorScaleGraph = PA_GetColorScaleGraph(graph)
				if(WindowExists(colorScaleGraph))
					RemoveAnnotationsFromGraph(colorScaleGraph)
				endif
			endif

			if(i == j)
				minimum = minimumDiag
				maximum = maximumDiag
			else
				minimum = minimumRows[j]
				maximum = maximumRows[j]
			endif

			WAVE img = GetPulseAverageSetImageWave(pasi.pulseAverageDFR, channelNumber, region)
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
			numSlots = numActive

			for(i = 0; i < numActive; i += 1)
				channelNumber = pasi.channels[i]

				// we always take the last region except for the last channel as that would be diagonal again
				if(i == numActive - 1)
					regionTaken = 0
					region = pasi.regions[regionTaken]
				else
					regionTaken = numActive - 1
					region = pasi.regions[regionTaken]
				endif

				WAVE img = GetPulseAverageSetImageWave(pasi.pulseAverageDFR, channelNumber, region)
				traceName = NameOfWave(img)

				if(i == 0)
					graph = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, regionTaken + 1)
					colorScaleGraph = PA_GetColorScaleGraph(graph)
				endif

				WAVE setIndizes = GetPulseAverageSetIndizes(pasi.pulseAverageHelperDFR, channelNumber, region)
				// assume that all pulses are from the same headstage
				headstage = properties[setIndizes[0]][%Headstage]
				ASSERT(IsFinite(headstage), "Invalid headstage")

				name = "colorScale_AD_" + num2str(channelNumber)
				text = "HS" + num2str(headstage) + " (\\U)"
				PA_AddColorScale(graph, colorScaleGraph, name, text, i, numSlots, traceName)
			endfor

			// diagonal color scale
			channelNumber = pasi.channels[0]
			regionTaken = 0
			region = pasi.regions[regionTaken]
			graph = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, regionTaken + 1)
			colorScaleGraph = PA_GetColorScaleGraph(graph)
			WAVE img = GetPulseAverageSetImageWave(pasi.pulseAverageDFR, channelNumber, region)
			traceName = NameOfWave(img)

			name = "colorScaleDiag"
			text = "Diagonal (\\U)"
			PA_AddColorScale(graph, colorScaleGraph, name, text, i - 0.5, numSlots, traceName)
		else
			for(i = 0; i < numActive; i += 1)
				channelNumber = pasi.channels[i]

				// we always take the last region for attaching the color scale bars
				// except for the last channel as that would be diagonal again
				// for the last channel we choose the first region
				// and in that case the color scale bar is also attached to the image from the first region
				// but it is placed in the external subwindow from the last region

				graph = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, numActive)
				colorScaleGraph = PA_GetColorScaleGraph(graph)
				ASSERT(WindowExists(colorScaleGraph), "Missing external subwindow for color scale")

				if(i == numActive - 1)
					regionTaken = 0
					region = pasi.regions[regionTaken]
					imageGraph = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, 1)
					numSlots = 2
				else
					regionTaken = numActive - 1
					region = pasi.regions[regionTaken]
					graph = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, numActive)
					imageGraph = graph
					numSlots = 1
				endif

				WAVE setIndizes = pasi.setIndices[i][regionTaken]
				// assume that all pulses are from the same headstage
				headstage = properties[setIndizes[0]][%Headstage]
				ASSERT(IsFinite(headstage), "Invalid headstage")

				WAVE img = GetPulseAverageSetImageWave(pasi.pulseAverageDFR, channelNumber, region)
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

static Function/S PA_ShowImage(string win, STRUCT PulseAverageSettings &pa, STRUCT PA_ConstantSettings &cs, STRUCT PulseAverageSetIndices &pasi, variable mode, WAVE/Z additionalData)

	variable channelNumber, region, numActive, i, j, k, err
	variable requiredEntries, specialEntries, numPulses
	variable singlePulseColumnOffset, failedMarkerStartRow, xPos, yPos, newSweep, numGraphs
	variable vert_min, vert_max, horiz_min, horiz_max, firstPulseIndex, layoutChanged
	variable graphDataIndex, junk, lblIMAGELIST, resetImage
	string vertAxis, horizAxis, graph, basename, imageName, msg, graphWithImage
	string image
	string usedGraphs = ""
	string graphsWithImages = ""

	if(!pa.showImages)
		return usedGraphs
	elseif(cs.images)
		return PA_GetGraphs(win, PA_DISPLAYMODE_IMAGES)
	endif

	numActive = DimSize(pasi.channels, ROWS)
	WAVE properties = pasi.properties
	layoutChanged = GetNumberFromWaveNote(properties, PA_PROPERTIES_KEY_LAYOUTCHANGE)

	WAVE/T paGraphData = GetPAGraphData()
	lblIMAGELIST = FindDimLabel(paGraphData, COLS, "IMAGELIST")

	for(i = 0; i < numActive; i += 1)
		channelNumber = pasi.channels[i]

		for(j = 0; j < numActive; j += 1)
			region = pasi.regions[j]

			WAVE/Z averageWave
			[averageWave, baseName] = PA_GetPermanentAverageWave(pasi.pulseAverageDFR, channelNumber, region)

			if(!pa.multipleGraphs && i == 0 && j == 0 || pa.multipleGraphs)
				graph = PA_GetGraph(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, region, j + 1, i + 1, numActive)
				graphsWithImages += AddPrefixToEachListItem(graph + "#", ImageNameList(graph, ";"))
				SetDrawLayer/W=$graph/K $PA_DRAWLAYER_FAILED_PULSES
				usedGraphs = AddListItem(graph, usedGraphs, ";", inf)
			endif

			numPulses = pasi.numEntries[i][j]
			WAVE setIndizes = pasi.setIndices[i][j]
			WAVE img = GetPulseAverageSetImageWave(pasi.pulseAverageDFR, channelNumber, region)

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
				CopyScales/P averageWave, img

				Make/FREE/N=(MAX_DIMENSION_COUNT) oldSizes = DimSize(img, p)
				EnsureLargeEnoughWave(img, minimumSize = requiredEntries, dimension = COLS, initialValue=NaN)
				Redimension/N=(DimSize(averageWave, ROWS), -1) img
				Make/FREE/N=(MAX_DIMENSION_COUNT) newSizes = DimSize(img, p)

				if(!(mode != POST_PLOT_ADDED_SWEEPS                                        \
				   || !EqualWaves(oldSizes, newSizes, 1)                                 \
				   || pa.pulseSortOrder != PA_PULSE_SORTING_ORDER_SWEEP						\
				   || layoutChanged))

					newSweep = WaveMin(additionalData)
					Make/FREE/N=(numPulses) sweeps = properties[setIndizes[p]][%Sweep]
					FindValue/Z/V=(newSweep) sweeps
					if(V_Value > 0)
						firstPulseIndex = V_Value
					else
						// we can have no match with removed headstages on the new sweep
						// caller needs to retry with POST_PLOT_FULL_UPDATE
						resetImage = 1
					endif
					WaveClear sweeps
				else
					resetImage = 1
				endif
				if(resetImage)
					Multithread img[][] = NaN
				endif
			endif

			if(pa.showIndividualPulses && numPulses > 0)
				WAVE/WAVE set = WaveRef(pasi.setWaves2[i][j])
				Multithread img[][singlePulseColumnOffset + firstPulseIndex, requiredEntries - 1] = WaveRef(set[q - singlePulseColumnOffset][0])(x); err = GetRTError(1)
			endif

			if(numPulses > 0)
				// write min and max of the single pulses into the wave note
				[vert_min, vert_max, horiz_min, horiz_max] = PA_GetMinAndMax(pasi.setWaves2[i][j])
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

			if(pa.deconvolution.enable && !(i == j) && WaveExists(averageWave))
				baseName = PA_BaseName(channelNumber, region)
				WAVE deconv = PA_Deconvolution(averageWave, pasi.pulseAverageDFR, PA_DECONVOLUTION_WAVE_PREFIX + baseName, pa.deconvolution)
				Multithread img[][specialEntries, 2 * specialEntries - 1] = limit(deconv(x), vert_min, vert_max); err = GetRTError(1)
			endif

			SetNumberInWaveNote(img, NOTE_INDEX, requiredEntries)
			SetNumberInWaveNote(img, PA_NOTE_KEY_IMAGE_COL_OFFSET, singlePulseColumnOffset)

			imageName = NameOfWave(img)

			sprintf msg, "imageName %s, specialEntries %d, singlePulseColumnOffset %d, requiredEntries %d, firstPulseIndex %d, numPulses %d\r", imageName, specialEntries, singlePulseColumnOffset, requiredEntries, firstPulseIndex, numPulses
			DEBUGPRINT(msg)

			graphsWithImages = RemoveFromList(graph + "#" + imageName, graphsWithImages)

			WAVE/T axesNames = pasi.axesNames[i][j]
			vertAxis = axesNames[0]
			horizAxis = axesNames[1]

			graphDataIndex = PA_GetTraceCountFromGraphData(graph)
			if(WhichListItem(imageName, paGraphData[graphDataIndex][lblIMAGELIST]) == -1)
				AppendImage/W=$graph/L=$vertAxis/B=$horizAxis img
				paGraphData[graphDataIndex][lblIMAGELIST] = AddListItem(imageName, paGraphData[graphDataIndex][lblIMAGELIST])
			endif

			PA_HighligthFailedPulsesInImage(graph, pa, vertAxis, horizAxis, img, pasi.properties, pasi.setIndices[i][j], numPulses, singlePulseColumnOffset)
		endfor
	endfor

	PA_LayoutGraphs(win, pa, pasi, PA_DISPLAYMODE_IMAGES)

	// now remove all images which were left over from previous plots but not referenced anymore
	numGraphs = ItemsInList(graphsWithImages)
	for(i = 0; i < numGraphs; i += 1)
		graphWithImage = StringFromList(i, graphsWithImages)
		graph = StringFromList(0, graphWithImage, "#")
		image = StringFromList(1, graphWithImage, "#")
		RemoveImage/W=$graph $image
		paGraphData[graphDataIndex][lblIMAGELIST] = RemoveFromList(image, paGraphData[graphDataIndex][lblIMAGELIST], ";")
	endfor

	PA_DrawScaleBars(win, pa, pasi, PA_DISPLAYMODE_IMAGES, PA_USE_WAVE_SCALES)
	PA_AddColorScales(win, pa, pasi)
	PA_DrawXZeroLines(win, pa, pasi, PA_DISPLAYMODE_IMAGES)

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

static Function PA_DrawXZeroLines(string win, STRUCT PulseAverageSettings &pa, STRUCT PulseAverageSetIndices &pasi, variable displayMode)

	variable i, j, numActive, channelNumber, region
	string vertAxis, horizAxis, graph

	numActive = DimSize(pasi.channels, ROWS)

	for(i = 0; i < numActive; i += 1)
		channelNumber = pasi.channels[i]

		for(j = 0; j < numActive; j += 1)
			region = pasi.regions[j]

			if(!pa.multipleGraphs && i == 0 && j == 0 || pa.multipleGraphs)
				graph = PA_GetGraph(win, pa, displayMode, channelNumber, region, j + 1, i + 1, numActive)
				SetDrawLayer/W=$graph/K $PA_DRAWLAYER_XZEROLINE
			endif

			if(!pa.drawXZeroLine)
				if(!pa.multipleGraphs)
					return NaN
				endif

				continue
			endif

			WAVE/T axesNames = pasi.axesNames[i][j]
			vertAxis = axesNames[0]
			horizAxis = axesNames[1]

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
