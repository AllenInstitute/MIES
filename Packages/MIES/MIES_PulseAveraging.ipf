#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

/// @file MIES_PulseAveraging.ipf
///
/// @brief __PA__ Routines for dealing with pulse averaging.
///
/// A pulse average (PA) plot allows to visualize multiple parts of data on different headstages.
///
/// Assume you have acquired a pulse train with oodDAQ on 5 different headstages.
/// This means you have 5 active headstages with each a DA and AD channel. We
/// only visualize the AD data in the PA plot.
///
/// The PA plot will then have 25 = 5 x 5 PA sets (either in one big graph or in multiple graphs).
///
/// Each set will have one source of pulse starting times (called "region")
/// and one source of the visualized data. The pulse starting times are always
/// extracted from the DA channel of the region.
///
/// That means the top left set is from the first region and the first
/// active headstage, the one to the right is from the second region and the
/// first active headstage. Or to put it differently, regions are the columns.
///
/// - Averaging is done for all pulses in a set
/// - Zeroing is done for all pulses
/// - Deconvolution is done for the average wave only
/// - See also PA_AutomaticTimeAlignment
///
/// The dDAQ slider in the Databrowse/Sweepbrowser is respected as is the
/// channel selection.

static StrConstant PA_GRAPH_PREFIX          = "PulseAverage"
static StrConstant PA_SOURCE_WAVE_TIMESTAMP = "SOURCE_WAVE_TS"

static StrConstant PA_AVERAGE_WAVE_PREFIX       = "average_"
static StrConstant PA_DECONVOLUTION_WAVE_PREFIX = "deconv_"

static StrConstant PA_SETTINGS = "PulseAverageSettings"

/// Only present for diagonal pulses
static StrConstant PA_NOTE_KEY_PULSE_FAILED = "PulseHasFailed"

static Constant PA_USE_WAVE_SCALES = 0x01
static Constant PA_USE_AXIS_SCALES = 0x02

static Constant PA_X_AXIS_OFFSET = 0.01

static Constant PA_PLOT_STEPPING = 16

static Constant PA_DISPLAYMODE_TRACES = 0x01
static Constant PA_DISPLAYMODE_IMAGES = 0x02
static Constant PA_DISPLAYMODE_ALL    = 0xFF

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

/// @brief Return the name of the pulse average graph
///
/// This function takes care of creating a graph if it does not exist, and laying it out correctly
///
/// Layout scheme for multiple graphs turned on:
/// - Positions the graphs right to `mainWin` in matrix form
/// - Columns: Regions (aka headstages with pulse starting time information respecting region selection in GUI)
/// - Rows:    Active unique channels
static Function/S PA_GetGraph(string mainWin, STRUCT PulseAverageSettings &pa, variable displayMode, variable channelNumber, variable region, variable activeRegionCount, variable activeChanCount)

	variable top, left, bottom, right, i
	variable width, height, width_spacing, height_spacing, width_offset, height_offset
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
		TUD_Init(win)

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

	variable level, delta
	string key
	ASSERT(totalOnsetDelay >= 0, "Invalid onsetDelay")

	key = CA_PulseStartTimes(DA, fullPath, channelNumber, totalOnsetDelay)
	WAVE/Z cache = CA_TryFetchingEntryFromCache(key)
	if(WaveExists(cache))
		return cache
	endif

	WaveStats/Q/M=1/R=(totalOnsetDelay, inf) DA
	level = V_min + (V_Max - V_Min) * 0.1

	MAKE/FREE/D levels
	FindLevels/Q/R=(totalOnsetDelay, inf)/EDGE=1/DEST=levels DA, level

	if(DimSize(levels, ROWS) == 0)
		return $""
	endif

	delta = DimDelta(DA, ROWS)

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

	fullPath = traceData[idx][%fullPath]
	DFREF singleSweepFolder = GetWavesDataFolderDFR($fullPath)
	ASSERT(DataFolderExistsDFR(singleSweepFolder), "Missing singleSweepFolder")

	// get the DA wave in that folder
	WAVE DACs = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)

	channel = DACs[region]
	if(IsNaN(channel))
		return $""
	endif

	WAVE DA = GetITCDataSingleColumnWave(singleSweepFolder, ITC_XOP_CHANNEL_TYPE_DAC, channel)
	WAVE/Z pulseStartTimes = PA_CalculatePulseStartTimes(DA, fullPath, channel, totalOnsetDelay)

	if(!WaveExists(pulseStartTimes))
		return $""
	endif

	sprintf str, "Calculated pulse starting times for headstage %d", region
	DEBUGPRINT(str)

	pulseStartTimes[] -= totalOnsetDelay

	return pulseStartTimes
End

static Function PA_GetPulseLength(pulseStartTimes, startingPulse, endingPulse, fallbackPulseLength)
	WAVE pulseStartTimes
	variable startingPulse, endingPulse, fallbackPulseLength

	variable numPulses, minimum

	numPulses = endingPulse - startingPulse + 1

	if(numPulses <= 1)
		return fallbackPulseLength
	endif

	Make/FREE/D/N=(numPulses) pulseLengths
	pulseLengths[0] = NaN
	pulseLengths[1, inf] = pulseStartTimes[p] - pulseStartTimes[p - 1]

	minimum = WaveMin(pulseLengths)

	if(minimum > 0)
		return minimum
	endif

	ASSERT(minimum == 0, "pulse length expected to be zero")

	return fallbackPulseLength
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

	KillOrMoveToTrash(wv = GetBackupWave(singlePulseWave))

	MultiThread singlePulseWave[] = wv[first + p]
	SetScale/P x, 0.0, DimDelta(wv, ROWS), WaveUnits(wv, ROWS), singlePulseWave
	SetScale/P d, 0.0, 0.0, WaveUnits(wv, -1), singlePulseWave

	SetNumberInWaveNote(singlePulseWave, NOTE_KEY_SEARCH_FAILED_PULSE, 0)
	SetNumberInWaveNote(singlePulseWave, NOTE_KEY_TIMEALIGN, 0)
	SetNumberInWaveNote(singlePulseWave, NOTE_KEY_ZEROED, 0)

	PA_UpdateMinAndMax(singlePulseWave)

	SetNumberInWaveNote(singlePulseWave, "PulseLength", length)

	SetNumberInWaveNote(wv, PA_SOURCE_WAVE_TIMESTAMP, ModDate(wv))

	CreateBackupWave(singlePulseWave)

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
static Function PA_GenerateAllPulseWaves(string win, STRUCT PulseAverageSettings &pa, variable constantSinglePulseSettings, variable mode)

	variable startingPulseSett, endingPulseSett, isDiagonalElement, pulseHasFailed, newChannel
	variable i, j, k, numHeadstages, region, sweepNo, idx, numPulsesTotal, numPulses, startingPulse, endingPulse
	variable headstage, pulseToPulseLength, totalOnsetDelay, numChannelTypeTraces, totalPulseCounter, jsonID, lastSweep
	variable activeRegionCount, activeChanCount, channelNumber, first, length, dictId, channelType, numChannels, numRegions
	string channelTypeStr, channelList, channelNumberStr, key, regionList, baseName, sweepList, sweepNoStr, experiment

	if(mode == POST_PLOT_CONSTANT_SWEEPS && constantSinglePulseSettings)
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

	KillorMoveToTrash(dfr = GetDevicePulseAverageHelperFolder(pa.dfr))

	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)
	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)
	WAVE/T propertiesText = GetPulseAveragePropertiesText(pulseAverageHelperDFR)
	WAVE/WAVE propertiesWaves = GetPulseAveragePropertiesWaves(pulseAverageHelperDFR)

	channelType = ITC_XOP_CHANNEL_TYPE_ADC
	channelTypeStr = StringFromList(channelType, ITC_CHANNEL_NAMES)

	WAVE/Z indizesChannelType = FindIndizes(traceData, colLabel="channelType", str=channelTypeStr)
	WAVE/Z headstages         = PA_GetUniqueHeadstages(traceData, indizesChannelType)

	if(!WaveExists(headstages))
		return NaN
	endif

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
			headstage = str2num(traceData[idx][%headstage])

			if(!IsFinite(headstage)) // ignore unassociated channels or duplicated headstages in traceData
				continue
			endif

			WAVE/Z pulseStartTimes = PA_GetPulseStartTimes(traceData, idx, region, channelTypeStr)

			if(!WaveExists(pulseStartTimes))
				continue
			endif

			sweepNoStr = traceData[idx][%SweepNumber]
			sweepNo = str2num(sweepNoStr)
			experiment = traceData[idx][%Experiment]
			channelNumberStr = traceData[idx][%channelNumber]
			channelNumber = str2num(channelNumberStr)
			experiment = traceData[idx][%Experiment]

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
			key = experiment + "_" + traceData[idx][%numericalValues]
			lastSweep = JSON_GetVariable(jsonID, key, ignoreErr = 1)
			if(IsNaN(lastSweep))
				WAVE numericalValues = $traceData[idx][%numericalValues]
				WAVE junkWave = GetLastSweepWithSetting(numericalValues, "Headstage Active", lastSweep)
				ASSERT(IsValidSweepNumber(lastSweep), "Could not find last sweep")
				JSON_SetVariable(jsonID, key, lastSweep)
			endif

			numPulsesTotal = DimSize(pulseStartTimes, ROWS)
			startingPulse  = max(0, startingPulseSett)
			endingPulse    = min(numPulsesTotal - 1, endingPulseSett)
			numPulses = endingPulse - startingPulse + 1

			pulseToPulseLength = PA_GetPulseLength(pulseStartTimes, startingPulse, endingPulse, pa.fallbackPulseLength)

			WAVE numericalValues = $traceData[idx][%numericalValues]
			DFREF singleSweepFolder = GetWavesDataFolderDFR($traceData[idx][%fullPath])
			ASSERT(DataFolderExistsDFR(singleSweepFolder), "Missing singleSweepFolder")
			WAVE wv = GetITCDataSingleColumnWave(singleSweepFolder, channelType, channelNumber)

			DFREF singlePulseFolder = GetSingleSweepFolder(pulseAverageDFR, sweepNo)
			totalOnsetDelay = GetTotalOnsetDelay(numericalValues, sweepNo)

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

				EnsureLargeEnoughWave(properties, minimumSize = totalPulseCounter, initialValue = NaN)
				EnsureLargeEnoughWave(propertiesText, minimumSize = totalPulseCounter)
				EnsureLargeEnoughWave(propertiesWaves, minimumSize = totalPulseCounter)

				properties[totalPulseCounter][%Sweep]                       = sweepNo
				properties[totalPulseCounter][%ChannelType]                 = channelType
				properties[totalPulseCounter][%ChannelNumber]               = channelNumber
				properties[totalPulseCounter][%Region]                      = region
				properties[totalPulseCounter][%Headstage]                   = headstage
				properties[totalPulseCounter][%Pulse]                       = k
				properties[totalPulseCounter][%DiagonalElement]             = IsDiagonalElement
				properties[totalPulseCounter][%ActiveRegionCount]           = activeRegionCount
				properties[totalPulseCounter][%ActiveChanCount]             = activeChanCount
				properties[totalPulseCounter][%LastSweep]                   = lastSweep

				propertiesText[totalPulseCounter][%Experiment] = experiment

				propertiesWaves[totalPulseCounter] = pulseWave

				// gather all pulses from one set (used for averaging)
				WAVE setIndizes = GetPulseAverageSetIndizes(pulseAverageHelperDFR, channelNumber, region)
				idx = GetNumberFromWaveNote(setIndizes, NOTE_INDEX)
				EnsureLargeEnoughWave(setIndizes, minimumSize = idx, initialValue = NaN)
				setIndizes[idx][%Index] = totalPulseCounter
				SetNumberInWaveNote(setIndizes, NOTE_INDEX, ++idx)

				totalPulseCounter += 1
			endfor
		endfor
	endfor

	SetNumberInWaveNote(properties, NOTE_INDEX, totalPulseCounter)
	SetNumberInWaveNote(propertiesText, NOTE_INDEX, totalPulseCounter)
	SetStringInWaveNote(properties, "Regions", ReplaceString(";", regionList, ","))
	SetStringInWaveNote(properties, "Channels", ReplaceString(";", channelList, ","))
	SetStringInWaveNote(properties, "Sweeps", ReplaceString(";", sweepList, ","))

	JSON_Release(jsonID)
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
	s.fallbackPulseLength  = GetSetVariable(extPanel, "setvar_pulseAver_fallbackLength")
	s.regionSlider         = GetSliderPositionIndex(extPanel, "slider_BrowserSettings_dDAQ")
	s.zeroPulses           = GetCheckboxState(extPanel, "check_pulseAver_zero")
	s.autoTimeAlignment    = GetCheckboxState(extPanel, "check_pulseAver_timeAlign")
	s.searchFailedPulses   = GetCheckboxState(extPanel, "check_pulseAver_searchFailedPulses")
	s.hideFailedPulses     = GetCheckboxState(extPanel, "check_pulseAver_hideFailedPulses")
	s.failedPulsesLevel    = GetSetVariable(extPanel, "setvar_pulseAver_failedPulses_level")
	s.yScaleBarLength      = GetSetVariable(extPanel, "setvar_pulseAver_vert_scale_bar")
	s.showImage            = GetCheckboxState(extPanel, "check_pulseAver_ShowImage")
	s.showTraces           = GetCheckboxState(extPanel, "check_pulseAver_ShowTraces")
	s.imageColorScale      = GetPopupMenuString(extPanel, "popup_pulseAver_colorscales")

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

	string graph, preExistingGraphs, usedTraceGraphs
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

	WAVE/WAVE/Z targetForAverage, sourceForAverage
	[targetForAverage, sourceForAverage, needsPlotting] = PA_PreProcessPulses(win, current, old, mode)

	if(!needsPlotting)
		return NaN
	endif

	preExistingGraphs = PA_GetGraphs(win, PA_DISPLAYMODE_ALL)

	usedTraceGraphs = PA_ShowPulses(graph, current, targetForAverage, sourceForAverage, mode, additionalData)

	KillWindows(RemoveFromList(usedTraceGraphs, preExistingGraphs))
End

static Function/WAVE PA_GetSetWaves(DFREF dfr, variable channelNumber, variable region, [variable removeFailedPulses])

	variable numWaves, i

	if(ParamIsDefault(removeFailedPulses))
		removeFailedPulses = 0
	else
		removeFailedPulses = !!removeFailedPulses
	endif

	WAVE setIndizes = GetPulseAverageSetIndizes(dfr, channelNumber, region)

	WAVE properties = GetPulseAverageProperties(dfr)
	WAVE/WAVE propertiesWaves = GetPulseAveragePropertiesWaves(dfr)

	numWaves = GetNumberFromWaveNote(setIndizes, NOTE_INDEX)

	if(numWaves == 0)
		return $""
	endif

	Make/FREE/N=(numWaves)/WAVE setWaves = propertiesWaves[setIndizes[p]]

	if(!removeFailedPulses)
		return setWaves
	endif

	for(i = numWaves - 1; i >= 0; i -= 1)
		if(properties[setIndizes[i]][%PulseHasFailed])
			DeletePoints/M=(ROWS) i, 1, setWaves
		endif
	endfor

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

static Function/S PA_ShowPulses(string win, STRUCT PulseAverageSettings &pa, WAVE/Z targetForAverageGeneric, WAVE/Z sourceForAverageGeneric, variable mode, WAVE/Z additionalData)

	string pulseTrace, channelTypeStr, str, graph, key
	variable numChannels, i, j, sweepNo, headstage, numTotalPulses, pulse, xPos, yPos, needsPlotting
	variable first, numEntries, startingPulse, endingPulse, traceCount, step, isDiagonalElement
	variable red, green, blue, channelNumber, region, channelType, length, newSweepCount
	variable numChannelTypeTraces, activeRegionCount, activeChanCount, totalOnsetDelay, pulseHasFailed
	variable numRegions, hideTrace, lastSweep, alpha, constantSinglePulseSettings
	string vertAxis, horizAxis, channelNumberStr, experiment
	string baseName, traceName, fullPath, tagName
	string usedGraphs = ""

	if(!pa.showTraces)
		return usedGraphs
	endif

	WAVE/WAVE/Z targetForAverage = targetForAverageGeneric
	WAVE/WAVE/Z sourceForAverage = sourceForAverageGeneric

	Make/FREE/T userDataKeys = {"fullPath", "sweepNumber", "headstage", "region", "channelNumber", "channelType",                           \
	                            "pulseIndex", "traceType", "occurence", "XAXIS", "YAXIS", "DiagonalElement"}

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
		newSweepCount = DimSize(additionalData, ROWS)
		Make/R/FREE/N=(newSweepCount) newSweeps
		Make/T/FREE/N=(newSweepCount) newExperiments

		for(i = 0; i < newSweepCount; i += 1)
			[sweepNo, experiment] = OVS_GetSweepAndExperiment(win, additionalData[i])
			newSweeps[i] = sweepNo
			newExperiments[i] = experiment
		endfor
	endif

	for(i = 0; i < numTotalPulses; i += 1)

		sweepNo = properties[i][%Sweep]
		experiment = propertiesText[i][%Experiment]
		channelType = properties[i][%ChannelType]
		channelTypeStr = StringFromList(channelType, ITC_CHANNEL_NAMES)
		channelNumber = properties[i][%ChannelNumber]
		channelNumberStr = num2str(channelNumber)
		region = properties[i][%Region]
		headstage = properties[i][%Headstage]
		pulse = properties[i][%Pulse]
		isDiagonalElement = properties[i][%DiagonalElement]
		activeRegionCount = properties[i][%ActiveRegionCount]
		activeChanCount = properties[i][%ActiveChanCount]
		pulseHasFailed = properties[i][%PulseHasFailed]
		lastSweep = properties[i][%LastSweep]

		if(!pa.multipleGraphs && i == 0 || pa.multipleGraphs)
			graph = PA_GetGraph(win, pa, PA_DISPLAYMODE_TRACES, channelNumber, region, activeRegionCount, activeChanCount)
			traceCount = TUD_GetTraceCount(graph)
		endif

		if(pa.regionSlider != -1 && pa.regionSlider != region) // unselected region in ddaq viewing mode
			continue
		endif

		if(mode == POST_PLOT_ADDED_SWEEPS)
			if(DimSize(newSweeps, ROWS) == 1)
				ASSERT(DimSize(newExperiments, ROWS) == 1, "Invalid new wave combination")
				needsPlotting = (newSweeps[0] == sweepNo && !cmpstr(newExperiments[0], experiment))
			else
				needsPlotting = IsFinite(GetRowIndex(newSweeps, val=sweepNo)) && IsFinite(GetRowIndex(newExperiments, str=experiment))
			endif
		else
			needsPlotting = 1
		endif

		[vertAxis, horizAxis] = PA_GetAxes(pa, activeRegionCount, activeChanCount)

		if(WhichListItem(graph, usedGraphs) == -1)
			if(mode != POST_PLOT_ADDED_SWEEPS)
				RemoveTracesFromGraph(graph)
				TUD_Clear(graph)
			endif
			RemoveAnnotationsFromGraph(graph)
			usedGraphs = AddListItem(graph, usedGraphs, ";", inf)
		endif

		WAVE plotWave = propertiesWaves[i]
		fullPath = GetWavesDataFolder(plotWave, 2)

		if(pa.showIndividualPulses)

			step = isDiagonalElement ? 1 : PA_PLOT_STEPPING

			if(pulseHasFailed)
				hideTrace = pa.hideFailedPulses
				red   = 65535
				green = 0
				blue  = 0
				alpha = 65535
			else
				hideTrace = 0
				GetTraceColor(headstage, red, green, blue)
				alpha = 65535 * 0.2
			endif

			if(needsPlotting)
				sprintf pulseTrace, "T%0*d%s", TRACE_NAME_NUM_DIGITS, traceCount, NameOfWave(plotWave)
				traceCount += 1

				AppendToGraph/Q/W=$graph/L=$vertAxis/B=$horizAxis/C=(red, green, blue, alpha) plotWave[0,inf;step]/TN=$pulseTrace

				if(hideTrace)
					ModifyGraph/W=$graph hideTrace($pulseTrace)=hideTrace
				endif

				TUD_SetUserDataFromWaves(graph, pulseTrace, userDataKeys,                                                       \
							             {fullPath, num2str(sweepNo), num2str(headstage), num2str(region), channelNumberStr,    \
							             channelTypeStr, num2str(pulse), "Sweep", "0",                                          \
							             horizAxis, vertAxis, num2str(isDiagonalElement)})
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

			if(!pa.multipleGraphs && i == 0 && j == 0 || pa.multipleGraphs)
				graph = PA_GetGraph(win, pa, PA_DISPLAYMODE_TRACES, channelNumber, region, activeRegionCount, activeChanCount)
				traceCount = TUD_GetTraceCount(graph)
				WAVE/T/Z averageTraceNames = TUD_GetUserDataAsWave(graph, "traceName", keys = {"traceType"}, values = {"Average"})
				WAVE/T/Z deconvolutionTraceNames = TUD_GetUserDataAsWave(graph, "traceName", keys = {"traceType"}, values = {"Deconvolution"})
			endif
			[vertAxis, horizAxis] = PA_GetAxes(pa, activeRegionCount, activeChanCount)

			if(pa.showAverage)
				if(WaveExists(averageTraceNames))
					WAVE/Z foundAverageTraces = GrepTextWave(averageTraceNames, ".*\\E" + PA_AVERAGE_WAVE_PREFIX + basename + "\\Q" + "$")
				else
					WAVE/Z foundAverageTraces = $""
				endif

				if(!WaveExists(foundAverageTraces))
					sprintf traceName, "T%0*d%s%s", TRACE_NAME_NUM_DIGITS, traceCount, PA_AVERAGE_WAVE_PREFIX, baseName
					traceCount += 1

					GetTraceColor(NUM_HEADSTAGES + 1, red, green, blue)
					AppendToGraph/Q/W=$graph/L=$vertAxis/B=$horizAxis/C=(red, green, blue) averageWave/TN=$traceName
					ModifyGraph/W=$graph lsize($traceName)=1.5

					TUD_SetUserDataFromWaves(graph, traceName, {"traceType", "occurence", "XAXIS", "YAXIS", "DiagonalElement"}, \
					                         {"Average", "0", horizAxis, vertAxis, num2str(isDiagonalElement)})
					TUD_SetUserData(graph, traceName, "fullPath", GetWavesDataFolder(averageWave, 2))
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

					AppendToGraph/Q/W=$graph/L=$vertAxis/B=$horizAxis/C=(0,0,0) deconv[0,inf;PA_PLOT_STEPPING]/TN=$traceName
					ModifyGraph/W=$graph lsize($traceName)=2

					TUD_SetUserDataFromWaves(graph, traceName, {"traceType", "occurence", "XAXIS", "YAXIS", "DiagonalElement"}, \
					                         {"Deconvolution", "0", horizAxis, vertAxis, num2str(isDiagonalElement)})
					TUD_SetUserData(graph, traceName, "fullPath", GetWavesDataFolder(deconv, 2))
				endif
			endif
		endfor
	endfor

	PA_DrawScaleBars(win, pa, PA_USE_WAVE_SCALES)
	PA_LayoutGraphs(win, pulseAverageHelperDFR, PA_DISPLAYMODE_TRACES, regions, channels, pa)

	return usedGraphs
End

/// @brief Remove all traces, image and annotations from the graph and clears its trace user data
static Function PA_ClearGraphs(string graphs)

	string graph
	variable numEntries, i

	numEntries = ItemsInList(graphs)
	for(i = 0; i < numEntries; i += 1)
		graph = StringFromList(i, graphs)

		RemoveTracesFromGraph(graph)
		RemoveImagesFromGraph(graph)
		RemoveAnnotationsFromGraph(graph)
		TUD_Clear(graph)
	endfor
End

/// @brief Gather and pre-process the single pulses for display
///
/// This function is display-type agnostic and only does preparational steps.
/// No graphs are created or killed.
///
/// The work with pulses is done in the following order:
/// - Gather pulses
/// - Reset pulses to backup
/// - Failed pulse marking
/// - Zeroing
/// - Time alignment
/// - Averaging
///
/// @retval dest          wave reference wave with average data for each set or $""
/// @retval source        wave reference wave with the data for each set or $""
/// @retval needsPlotting boolean denoting if there are pulses to plot
static Function [WAVE/WAVE dest, WAVE/WAVE source, variable needsPlotting] PA_PreProcessPulses(string win, STRUCT PulseAverageSettings &pa, STRUCT PulseAverageSettings &paOld, variable mode)

	variable numChannels, numRegions, i, j, region, channelNumber
	variable constantSinglePulseSettings, numTotalPulses
	string preExistingGraphs, graph

	preExistingGraphs = PA_GetGraphs(win, PA_DISPLAYMODE_ALL)
	graph = GetMainWindow(win)

	if(!pa.enabled)
		KillWindows(preExistingGraphs)
		return [$"", $"", 0]
	endif

	if(TUD_GetTraceCount(graph) == 0) // no traces
		// fake one graph
		if(IsEmpty(preExistingGraphs))
			preExistingGraphs = PA_GetGraph(win, pa, PA_DISPLAYMODE_TRACES, 1, 1, 1, 1)
		endif

		PA_ClearGraphs(preExistingGraphs)

		return [$"", $"", 0]
	endif

	constantSinglePulseSettings = (pa.startingPulse == paOld.startingPulse                \
	                               && pa.endingPulse == paOld.endingPulse                 \
	                               && pa.fallbackPulseLength == paOld.fallbackPulseLength)

	PA_GenerateAllPulseWaves(win, pa, constantSinglePulseSettings, mode)

	DFREF pulseAverageDFR = GetDevicePulseAverageFolder(pa.dfr)
	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)

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

	if(mode != POST_PLOT_CONSTANT_SWEEPS || !constantSinglePulseSettings)
		WAVE/WAVE/Z dest, source
		[dest, source] = PA_CalculateAllAverages(pa)
		return [dest, source, 1]
	endif

	return [$"", $"", 1]
End

static Function [WAVE/WAVE dest, WAVE/WAVE source] PA_CalculateAllAverages(STRUCT PulseAverageSettings &pa)

	variable numChannels, numRegions, i, j, channelNumber, region, numThreads

	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)

	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)

	WAVE channels = ListToNumericWave(GetStringFromWaveNote(properties, "Channels"), ",")
	numChannels = DimSize(channels, ROWS)

	WAVE regions = ListToNumericWave(GetStringFromWaveNote(properties, "Regions"), ",")
	numRegions = DimSize(regions, ROWS)

	Make/FREE/WAVE/N=(numChannels, numRegions) source, dest

	for(i = 0; i < numChannels; i += 1)
		channelNumber = channels[i]
		for(j = 0; j < numRegions; j += 1)
			region = regions[j]

			WAVE/WAVE/Z setWaves = PA_GetSetWaves(pulseAverageHelperDFR, channelNumber, region, removeFailedPulses = 1)

			if(!WaveExists(setWaves))
				continue
			endif

			source[i][j] = setWaves
		endfor
	endfor

	numThreads = min(numRegions * numChannels, ThreadProcessorCount)
	Multithread/NT=(numThreads) dest[][] = MIES_fWaveAverage(source[p][q], 0, IGOR_TYPE_32BIT_FLOAT)

	return [dest, source]
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

	if(GrepString(win, PA_GRAPH_PREFIX))
		win = GetUserData(win, "", MIES_BSP_PA_MAINPANEL)
	endif

	STRUCT PulseAverageSettings pa
	PA_GatherSettings(win, pa)
	PA_DrawScaleBars(win, pa, PA_USE_AXIS_SCALES)
End

static Function PA_DrawScaleBars(string win, STRUCT PulseAverageSettings &pa, variable mode)

	variable i, j, numChannels, numRegions, region, channelNumber
	variable activeChanCount, activeRegionCount, maximum, length
	string graph, vertAxis, horizAxis, baseName

	if(!pa.showIndividualPulses && !pa.showAverage && !pa.deconvolution.enable)
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
			graph = PA_GetGraph(win, pa, PA_DISPLAYMODE_TRACES, channelNumber, region, activeRegionCount, activeChanCount)
			[vertAxis, horizAxis] = PA_GetAxes(pa, activeRegionCount, activeChanCount)

			if(!pa.multipleGraphs && activeChanCount == 1 && activeRegionCount == 1 || pa.multipleGraphs)
				NewFreeAxis/R/O/W=$graph fakeAxis
				ModifyFreeAxis/W=$graph fakeAxis, master=$horizAxis, hook=PA_AxisHook
				ModifyGraph/W=$graph nticks(fakeAxis)=0, noLabel(fakeAxis)=2, axthick(fakeAxis)=0
				SetDrawLayer/K/W=$graph ProgFront
			endif

			WAVE/WAVE/Z setWaves = PA_GetSetWaves(pulseAverageHelperDFR, channelNumber, region, removeFailedPulses = 1)

			if(!WaveExists(setWaves))
				continue
			endif

			baseName = PA_BaseName(channelNumber, region)
			WAVE/Z averageWave = PA_Average(setWaves, pulseAverageDFR, PA_AVERAGE_WAVE_PREFIX + baseName, noCalculation=1)

			if(WaveExists(averageWave))
				maximum = GetNumberFromWaveNote(averageWave, "WaveMaximum")
				length = pa.yScaleBarLength * (IsFinite(maximum) ? sign(maximum) : +1)
			else
				length = pa.yScaleBarLength
			endif
			PA_DrawScaleBarsHelper(graph, mode, setWaves, vertAxis, horizAxis, length, WaveUnits(averageWave, ROWS), WaveUnits(averageWave, -1), activeChanCount, numChannels, activeRegionCount, numRegions)
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

static Function PA_DrawScaleBarsHelper(string win, variable mode, WAVE/WAVE setWaves, string vertAxis, string horizAxis, variable ylength, string xUnit, string yUnit, variable activeChanCount, variable numChannels, variable activeRegionCount, variable numRegions)

	string graph, msg, str
	variable vertAxis_y, vertAxis_x, xLength
	variable vert_min, vert_max, horiz_min, horiz_max, drawLength
	variable xBarBottom, xBarTop, yBarBottom, yBarTop, labelOffset
	variable xBarLeft, xBarRight, yBarLeft, yBarRight, drawXScaleBar, drawYScaleBar

	drawXScaleBar = (activeChanCount == numChannels)
	drawYScaleBar = (activeChanCount != activeRegionCount)

	if(!drawXScaleBar && !drawYScaleBar)
		return NaN
	endif

	graph = GetMainWindow(win)

	switch(mode)
		case PA_USE_WAVE_SCALES:
			[vert_min, vert_max, horiz_min, horiz_max] = PA_GetMinAndMax(setWaves)
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

		SetDrawEnv/W=$graph xcoord=$horizAxis, ycoord=$vertAxis
		SetDrawEnv/W=$graph save

		// X scale

		sprintf str, "scalebar_X_R%d_C%d", activeRegionCount, activeChanCount
		SetDrawEnv/W=$graph gstart, gname=$str

		// find a multiple of 5 which is closest to 10% of the full range
		xLength = round(0.10 * abs(horiz_max - horiz_min) / 5) * 5
		xLength = xLength == 0 ? 5 : xLength

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

	FindLevel/Q singlePulseWave, level
	hasFailed = (V_flag == 1)

	SetNumberInWaveNote(singlePulseWave, PA_NOTE_KEY_PULSE_FAILED, hasFailed)

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
	MultiThread junkWave = ZeroWave(set[p]) + PA_UpdateMinAndMax(set[p])
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

static Function PA_UpdateDeconvolution(win)
	string win

	string graph, graphs, horizAxis, vertAxis
	string traceName, fullPath, avgTrace
	string baseName
	variable i, numGraphs, j, numTraces, traceIndex
	STRUCT PulseAverageSettings pa
	PA_GatherSettings(win, pa)

	if(!pa.enabled)
		return NaN
	endif

	graphs = PA_GetGraphs(win, PA_DISPLAYMODE_TRACES)
	numGraphs = ItemsInList(graphs)
	for(i = 0; i < numGraphs; i += 1)
		graph = StringFromList(i, graphs)

		if(pa.deconvolution.enable)
			WAVE/T/Z traces = TUD_GetUserDataAsWave(graph, "traceName", keys = {"traceType", "DiagonalElement"}, values = {"Average", "0"})

			traceIndex = TUD_GetTraceCount(graph)

			numTraces = WaveExists(traces) ? DimSize(traces, ROWS) : 0
			for(j = 0; j < numTraces; j += 1)
				avgTrace = traces[j]

				vertAxis  = TUD_GetUserData(graph, avgTrace, "YAXIS")
				horizAxis = TUD_GetUserData(graph, avgTrace, "XAXIS")

				fullPath = TUD_GetUserData(graph, avgTrace, "fullPath")
				WAVE averageWave = $fullPath
				DFREF pulseAverageDFR = GetWavesDataFolderDFR(averageWave)

				SplitString/E=(PA_AVERAGE_WAVE_PREFIX + "(.*)") NameOfWave(averageWave), baseName
				ASSERT(V_flag == 1, "Unexpected Trace Name")

				sprintf traceName, "T%0*d%s%s", TRACE_NAME_NUM_DIGITS, traceIndex, PA_DECONVOLUTION_WAVE_PREFIX, baseName
				traceIndex += 1

				WAVE deconv = PA_Deconvolution(averageWave, pulseAverageDFR, traceName, pa.deconvolution)

				AppendToGraph/Q/W=$graph/L=$vertAxis/B=$horizAxis/C=(0,0,0) deconv/TN=$traceName
				ModifyGraph/W=$graph lsize($traceName)=2

				TUD_SetUserDataFromWaves(graph, traceName, {"traceType", "occurence", "XAXIS", "YAXIS", "DiagonalElement"}, \
							             {"Deconvolution", "0", horizAxis, vertAxis, "0"})
				TUD_SetUserData(graph, traceName, "fullPath", GetWavesDataFolder(deconv, 2))
			endfor
		else // !pa.deconvolution.enable
			WAVE/T/Z traces = TUD_GetUserDataAsWave(graph, "traceName", keys = {"traceType"}, values = {"Deconvolution"})

			numTraces = WaveExists(traces) ? DimSize(traces, ROWS) : 0
			for(j = 0; j < numTraces; j += 1)
				traceName = traces[j]

				RemoveFromGraph/W=$graph $traceName
				TUD_RemoveUserData(graph, traceName)
			endfor
		endif
	endfor
End

/// @brief Time alignment for PA single pulses
///
/// - Get the feature position also for all pulses which belong to the same set. Store these
///   feature positions using their sweep number and pulse index as key.
/// - Now shift *all* pulses in all sets from the same region by `- featurePos`
///   where `featurePos` is used from the same sweep and pulse index.
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

static Function PA_LayoutGraphs(string win, DFREF dfr, variable displayMode, WAVE regions, WAVE channels, STRUCT PulseAverageSettings &pa)

	variable i, j, numRegions, numChannels, activeRegionCount, activeChanCount, numPulsesInSet
	variable channelNumber, headstage, red, green, blue, region, xStart
	string graph, str, horizAxis, vertAxis

	numRegions = DimSize(regions, ROWS)
	numChannels = DimSize(channels, ROWS)

	if(!pa.multipleGraphs)
		graph = PA_GetGraphName(win, pa, displayMode, NaN, NaN)

#ifdef PA_HIDE_AXIS
		ModifyGraph/W=$graph mode=0, nticks=0, noLabel=2, axthick=0, margin(left)=30, margin(top)=20, margin(right)=14, margin(bottom)=14
#endif
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

	WAVE properties = GetPulseAverageProperties(dfr)

	for(i = 0; i < numChannels; i += 1)
		channelNumber = channels[i]
		for(j = 0; j < numRegions; j += 1)
			region = regions[j]

			activeRegionCount = j + 1
			graph = PA_GetGraphName(win, pa, PA_DISPLAYMODE_TRACES, channelNumber, activeRegionCount)

			WAVE setIndizes = GetPulseAverageSetIndizes(dfr, channelNumber, region)
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

			GetTraceColor(headstage, red, green, blue)
			sprintf str, "\\k(%d, %d, %d)\\K(%d, %d, %d)\\W555\\k(0, 0, 0)\\K(0, 0, 0)", red, green, blue, red, green, blue

			sprintf str, "AD%d / Reg. %d HS%s", channelNumber, region, str
			AppendText/W=$graph str

#ifdef PA_HIDE_AXIS
			ModifyGraph/W=$graph mode=0, nticks=0, noLabel=2, axthick=0, margin=5
#endif
			ModifyGraph/W=$graph/Z freePos(bottom)=0
		endfor
	endfor
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
	JSON_AddVariable(jsonID, "/fallbackPulseLength", pa.fallbackPulseLength)
	JSON_AddVariable(jsonID, "/multipleGraphs", pa.multipleGraphs)
	JSON_AddVariable(jsonID, "/zeroPulses", pa.zeroPulses)
	JSON_AddVariable(jsonID, "/autoTimeAlignment", pa.autoTimeAlignment)
	JSON_AddVariable(jsonID, "/hideFailedPulses", pa.hideFailedPulses)
	JSON_AddVariable(jsonID, "/searchFailedPulses", pa.searchFailedPulses)
	JSON_AddVariable(jsonID, "/failedPulsesLevel", pa.failedPulsesLevel)
	JSON_AddVariable(jsonID, "/yScaleBarLength", pa.yScaleBarLength)
	JSON_AddVariable(jsonID, "/showImage", pa.showImage)
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
	pa.fallbackPulseLength  = JSON_GetVariable(jsonID, "/fallbackPulseLength")
	pa.multipleGraphs       = JSON_GetVariable(jsonID, "/multipleGraphs")
	pa.zeroPulses           = JSON_GetVariable(jsonID, "/zeroPulses")
	pa.autoTimeAlignment    = JSON_GetVariable(jsonID, "/autoTimeAlignment")
	pa.hideFailedPulses     = JSON_GetVariable(jsonID, "/hideFailedPulses")
	pa.searchFailedPulses   = JSON_GetVariable(jsonID, "/searchFailedPulses")
	pa.failedPulsesLevel    = JSON_GetVariable(jsonID, "/failedPulsesLevel")
	pa.yScaleBarLength      = JSON_GetVariable(jsonID, "/yScaleBarLength")
	pa.showImage            = JSON_GetVariable(jsonID, "/showImage")
	pa.showTraces           = JSON_GetVariable(jsonID, "/showTraces")
	pa.imageColorScale      = JSON_GetString(jsonID, "/imageColorScale")
	pa.deconvolution.enable = JSON_GetVariable(jsonID, "/deconvolution/enable")
	pa.deconvolution.smth   = JSON_GetVariable(jsonID, "/deconvolution/smth")
	pa.deconvolution.tau    = JSON_GetVariable(jsonID, "/deconvolution/tau")
	pa.deconvolution.range  = JSON_GetVariable(jsonID, "/deconvolution/range")

	return jsonID
End
