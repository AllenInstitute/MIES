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
/// - Time alignment is done for all pulses of a region against the reference
///   pulse which is the first pulse from the set where `activeRegionCount
///   == activeChannelCount` (aka the diagonal trace set). The graph user data
///   `REFERENCE` denotes if the graph has references pulses and
///   `REFERENCE_TRACES` holds the names of the reference traces.
///
/// The dDAQ slider in the Databrowse/Sweepbrowser is respected as is the
/// channel selection.

static StrConstant PULSE_AVERAGE_GRAPH_PREFIX = "PulseAverage"
static StrConstant SOURCE_WAVE_TIMESTAMP      = "SOURCE_WAVE_TS"

static StrConstant PA_AVERAGE_WAVE_PREFIX       = "average_"
static StrConstant PA_DECONVOLUTION_WAVE_PREFIX = "deconv_"

static StrConstant PA_USERDATA_REFERENCE_TRACES = "REFERENCE_TRACES"
static StrConstant PA_USERDATA_REFERENCE_GRAPH  = "REFERENCE"

static Constant PA_PLOT_STEPPING = 16

/// @brief Return a list of all average graphs
Function/S PA_GetAverageGraphs()
	return WinList(PULSE_AVERAGE_GRAPH_PREFIX + "*", ";", "WIN:1")
End

static Function/S PA_GetGraphName(multipleGraphs, channelTypeStr, channelNumber, activeRegionCount)
	variable multipleGraphs, channelNumber, activeRegionCount
	string channelTypeStr

	if(multipleGraphs)
		return PULSE_AVERAGE_GRAPH_PREFIX + "_" + channelTypeStr + num2str(channelNumber) + "_R" + num2str(activeRegionCount)
	else
		return PULSE_AVERAGE_GRAPH_PREFIX
	endif
End

/// @brief Return the name of the pulse average graph
///
/// This function takes care of creating a graph if it does not exist, and laying it out correctly
///
/// Layout scheme for multiple graphs turned on:
/// - Positions the graphs right to `mainWin` in matrix form
/// - Columns: Regions (aka headstages with pulse starting time information respecting region selection in GUI)
/// - Rows:    Active unique channels
static Function/S PA_GetGraph(mainWin, multipleGraphs, channelTypeStr, channelNumber, region, activeRegionCount, activeChanCount)
	string mainWin, channelTypeStr
	variable multipleGraphs, channelNumber, region, activeRegionCount, activeChanCount

	variable top, left, bottom, right, i
	variable width, height, width_spacing, height_spacing, width_offset, height_offset
	string win, winAbove

	win = PA_GetGraphName(multipleGraphs, channelTypeStr, channelNumber, activeRegionCount)

	if(!WindowExists(win))

		if(multipleGraphs)
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
		SetWindow $win, userdata($PA_USERDATA_REFERENCE_GRAPH) = num2str(activeRegionCount == activeChanCount)

		if(multipleGraphs)
			winAbove = PA_GetGraphName(multipleGraphs, channelTypeStr, channelNumber - 1, activeRegionCount)

			for(i = channelNumber - 1; i >=0; i -= 1)
				winAbove = PA_GetGraphName(multipleGraphs, channelTypeStr, i, activeRegionCount)

				if(WindowExists(winAbove))
					DoWindow/B=$winAbove $win
					break
				endif
			endfor
		endif
	endif

	return win
End

/// @brief Return the names of the vertical and horizontal axes
static Function PA_GetAxes(multipleGraphs, activeRegionCount, activeChanCount, vertAxis, horizAxis)
	variable multipleGraphs, activeRegionCount, activeChanCount
	string &vertAxis, &horizAxis

	if(multipleGraphs)
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
	elseif(GetNumberFromWaveNote(wv, SOURCE_WAVE_TIMESTAMP) == ModDate(wv))
		return singlePulseWave
	endif

	KillOrMoveToTrash(wv = GetBackupWave(singlePulseWave))

	MultiThread singlePulseWave[] = wv[first + p]
	SetScale/P x, 0.0, DimDelta(wv, ROWS), WaveUnits(wv, ROWS), singlePulseWave
	SetNumberInWaveNote(singlePulseWave, NOTE_KEY_ZEROED, 0)
	SetNumberInWaveNote(singlePulseWave, NOTE_KEY_TIMEALIGN, 0)
	SetNumberInWaveNote(singlePulseWave, "PulseLength", length)

	SetNumberInWaveNote(wv, SOURCE_WAVE_TIMESTAMP, ModDate(wv))

	return singlePulseWave
End

/// @brief Populates pps.pulseAverSett with the user selection from the panel
static Function PA_GatherSettings(win, s)
	string win
	STRUCT PulseAverageSettings &s

	string extPanel

	win      = GetMainWindow(win)
	extPanel = BSP_GetPanel(win)

	if(!PA_IsActive(win))
		InitPulseAverageSettings(s)
		return 0
	endif

	s.dfr                  = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)
	s.enabled              = GetCheckboxState(extPanel, "check_BrowserSettings_PA")
	s.showIndividualTraces = GetCheckboxState(extPanel, "check_pulseAver_indTraces")
	s.showAverageTrace     = GetCheckboxState(extPanel, "check_pulseAver_showAver")
	s.multipleGraphs       = GetCheckboxState(extPanel, "check_pulseAver_multGraphs")
	s.startingPulse        = GetSetVariable(extPanel, "setvar_pulseAver_startPulse")
	s.endingPulse          = GetSetVariable(extPanel, "setvar_pulseAver_endPulse")
	s.fallbackPulseLength  = GetSetVariable(extPanel, "setvar_pulseAver_fallbackLength")
	s.regionSlider         = BSP_GetDDAQ(win)
	s.zeroTraces           = GetCheckboxState(extPanel, "check_pulseAver_zeroTrac")
	s.autoTimeAlignment    = GetCheckboxState(extPanel, "check_pulseAver_timeAlign")

	PA_DeconvGatherSettings(win, s.deconvolution)
End

/// @brief gather deconvolution settings from PA section in BSP
static Function PA_DeconvGatherSettings(win, deconvolution)
	string win
	STRUCT PulseAverageDeconvSettings &deconvolution

	string bsPanel = BSP_GetPanel(win)

	deconvolution.enable = GetCheckboxState(bsPanel, "check_pulseAver_deconv") \
	                       && GetCheckboxState(bsPanel, "check_pulseAver_showAver")
	deconvolution.smth   = GetSetVariable(bsPanel, "setvar_pulseAver_deconv_smth")
	deconvolution.tau    = GetSetVariable(bsPanel, "setvar_pulseAver_deconv_tau")
	deconvolution.range  = GetSetVariable(bsPanel, "setvar_pulseAver_deconv_range")
End

/// @brief Update the PA plot to accomodate changed settings
Function PA_Update(string win)

	string graph = GetMainWindow(win)

	STRUCT PulseAverageSettings s
	PA_GatherSettings(graph, s)
	PA_ShowPulses(graph, s)
End

static Function PA_ShowPulses(win, pa)
	string win
	STRUCT PulseAverageSettings &pa

	string graph, preExistingGraphs
	string averageWaveName, convolutionWaveName, pulseTrace, channelTypeStr, str, traceList, traceFullPath
	variable numChannels, i, j, k, l, idx, numTraces, sweepNo, headstage, numPulsesTotal, numPulses
	variable first, numEntries, startingPulse, endingPulse, numGraphs, traceCount, step, isDiagonalElement
	variable startingPulseSett, endingPulseSett, ret, pulseToPulseLength, numSweeps, numRegions
	variable red, green, blue, channelNumber, region, channelType, numHeadstages, length
	variable numChannelTypeTraces, activeRegionCount, activeChanCount, totalOnsetDelay
	string listOfWaves, channelList, vertAxis, horizAxis, channelNumberStr
	string baseName, traceName, fullPath
	string newlyCreatedGraphs = ""
	string referenceTraceList = ""

	win = GetMainWindow(win)

	preExistingGraphs = PA_GetAverageGraphs()

	if(!pa.enabled)
		KillWindows(preExistingGraphs)
		return NaN
	endif

	if(pa.startingPulse >= 0)
		startingPulseSett = pa.startingPulse
	endif

	if(pa.endingPulse >= 0)
		endingPulseSett = pa.endingPulse
	endif

	WAVE/T/Z traceData = GetTraceInfos(win)

	if(!WaveExists(traceData)) // no traces
		KillWindows(preExistingGraphs)
		return NaN
	endif

	numEntries = ItemsInList(preExistingGraphs)
	for(i = 0; i < numEntries; i += 1)
		graph = StringFromList(i, preExistingGraphs)
		TUD_Clear(graph)
	endfor

	DFREF pulseAverageDFR = GetDevicePulseAverageFolder(pa.dfr)
	Make/FREE/T userDataKeys = {"fullPath", "sweepNumber", "region", "channelNumber", "channelType",         \
								"pulseIndex", "traceType", "occurence", "XAXIS", "YAXIS", "DiagonalElement"}

	// iterate over all channel types we want to have pulse averaging for
	for(i = 0; i < 2; i += 1)
		channelType    = i
		channelTypeStr = StringFromList(channelType, ITC_CHANNEL_NAMES)

		WAVE/Z indizesChannelType = FindIndizes(traceData, colLabel="channelType", str=channelTypeStr)
		WAVE/Z headstages         = PA_GetUniqueHeadstages(traceData, indizesChannelType)

		if(!WaveExists(headstages))
			continue
		endif

		numChannelTypeTraces = DimSize(indizesChannelType, ROWS)
		numHeadstages        = DimSize(headstages, ROWS)

		activeRegionCount = 0

		WaveStats/M=1/Q headstages
		numRegions = V_npnts

		// iterate over all headstages, ignores duplicates from overlay sweeps
		for(j = 0; j < numHeadstages; j += 1)

			region = headstages[j]

			if(!IsFinite(region)) // duplicated headstages in traceData
				continue
			endif

			if(pa.regionSlider != -1 && pa.regionSlider != region) // unselected region in ddaq viewing mode
				continue
			endif

			activeRegionCount += 1
			activeChanCount    = 0
			channelList        = ""

			Make/FREE/T/N=(NUM_HEADSTAGES) wavesToAverage
			Make/T/FREE/N=(GetNumberFromType(itcvar=channelType)) listOfWavesPerChannel = ""

			// we have the starting times for one channel type and headstage combination
			// iterate now over all channels of the same type and extract all
			// requested pulses for them
			for(k = 0; k < numChannelTypeTraces; k += 1)
				idx       = indizesChannelType[k]
				headstage = str2num(traceData[idx][%headstage])

				if(!IsFinite(headstage)) // ignore unassociated channels or duplicated headstages in traceData
					continue
				endif

				sweepNo              = str2num(traceData[idx][%sweepNumber])
				channelNumberStr     = traceData[idx][%channelNumber]
				channelNumber        = str2num(channelNumberStr)
				WAVE numericalValues = $traceData[idx][%numericalValues]

				WAVE/Z pulseStartTimes = PA_GetPulseStartTimes(traceData, idx, region, channelTypeStr)

				if(!WaveExists(pulseStartTimes))
					continue
				endif

				numPulsesTotal = DimSize(pulseStartTimes, ROWS)
				startingPulse  = max(0, startingPulseSett)
				endingPulse    = min(numPulsesTotal - 1, endingPulseSett)
				numPulses = endingPulse - startingPulse + 1

				pulseToPulseLength = PA_GetPulseLength(pulseStartTimes, startingPulse, endingPulse, pa.fallbackPulseLength)

				if(WhichListItem(channelNumberStr, channelList) == -1)
					activeChanCount += 1
					channelList = AddListItem(channelNumberStr, channelList, ";", inf)
				endif

				isDiagonalElement = (activeRegionCount == activeChanCount)

				DFREF singleSweepFolder = GetWavesDataFolderDFR($traceData[idx][%fullPath])
				ASSERT(DataFolderExistsDFR(singleSweepFolder), "Missing singleSweepFolder")
				WAVE wv = GetITCDataSingleColumnWave(singleSweepFolder, channelType, channelNumber)

				DFREF singlePulseFolder = GetSingleSweepFolder(pulseAverageDFR, sweepNo)

				totalOnsetDelay = GetTotalOnsetDelay(numericalValues, sweepNo)

				graph = PA_GetGraph(win, pa.multipleGraphs, channelTypeStr, channelNumber, region, activeRegionCount, activeChanCount)
				PA_GetAxes(pa.multipleGraphs, activeRegionCount, activeChanCount, vertAxis, horizAxis)
				traceCount = TUD_GetTraceCount(graph)

				if(WhichListItem(graph, newlyCreatedGraphs) == -1)
					WAVE/T/Z cursorInfos = GetCursorInfos(graph)

					RemoveTracesFromGraph(graph)
					SetWindow $graph, userData($PA_USERDATA_REFERENCE_TRACES) = ""
					newlyCreatedGraphs = AddListItem(graph, newlyCreatedGraphs, ";", inf)
				else
					Wave/T/Z cursorInfos =  $""
				endif

				for(l = startingPulse; l <= endingPulse; l += 1)

					// ignore wave offset, as it is only used for display purposes
					// but use the totalOnsetDelay of this sweep
					first  = round((pulseStartTimes[l] + totalOnsetDelay) / DimDelta(wv, ROWS))
					length = round(pulseToPulseLength / DimDelta(wv, ROWS))

					WAVE/Z plotWave = PA_CreateAndFillPulseWaveIfReq(wv, singlePulseFolder, channelType, channelNumber, region, l, first, length)

					if(!WaveExists(plotWave))
						continue
					endif

					fullPath = GetWavesDataFolder(plotWave, 2)

					if(pa.showIndividualTraces)
						sprintf pulseTrace, "T%0*d%s_IDX%d", TRACE_NAME_NUM_DIGITS, traceCount, NameOfWave(plotWave), idx
						traceCount += 1

						step = isDiagonalElement ? 1 : PA_PLOT_STEPPING

						GetTraceColor(headstage, red, green, blue)
						AppendToGraph/Q/W=$graph/L=$vertAxis/B=$horizAxis/C=(red, green, blue, 65535 * 0.2) plotWave[0,inf;step]/TN=$pulseTrace

						TUD_SetUserDataFromWaves(graph, pulseTrace, userDataKeys,                                \
						                         {fullPath, num2str(sweepNo), num2str(region), channelNumberStr, \
												  channelTypeStr, num2str(l), "Sweep", "0",                      \
                                                  horizAxis, vertAxis, num2str(isDiagonalElement)})

						if(l == startingPulse && IsDiagonalElement && WhichListItem(channelNumberStr, referenceTraceList) == -1)
							SetWindow $graph, userData($PA_USERDATA_REFERENCE_TRACES) += pulseTrace + ";"
							referenceTraceList = AddListItem(channelNumberStr, referenceTraceList)
						endif
					endif

					listOfWavesPerChannel[channelNumber] = AddListItem(fullPath, listOfWavesPerChannel[channelNumber], ";", inf)
				endfor

				RestoreCursors(graph, cursorInfos)
			endfor

			activeChanCount = 0
			channelList     = ""

			// do calculations on traces
			String testList = ""
			for(k = 0; k < numChannelTypeTraces; k += 1)
				idx = indizesChannelType[k]

				channelNumberStr = traceData[idx][%channelNumber]
				channelNumber    = str2num(channelNumberStr)

				if(WhichListItem(channelNumberStr, channelList) != -1)
					continue
				endif
				activeChanCount += 1
				channelList = AddListItem(channelNumberStr, channelList, ";", inf)

				// reset waves
				listOfWaves = listOfWavesPerChannel[channelNumber]
				PA_ResetWavesIfRequired(listOfWaves, pa)

				// Zero Traces
				PA_ZeroTraces(listOfWaves, pa.zeroTraces)

				// Automatic Time Alignment with Reference Trace
				if(pa.autoTimeAlignment && pa.multipleGraphs)
					graph = PA_GetGraphName(pa.multipleGraphs, channelTypeStr, channelNumber, activeRegionCount)
					PA_AutomaticTimeAlignment(PA_GetReferenceTracesFromGraph(graph))
				endif
			endfor

			if(pa.autoTimeAlignment && !pa.multipleGraphs)
				PA_AutomaticTimeAlignment(PA_GetReferenceTracesFromGraph(PULSE_AVERAGE_GRAPH_PREFIX))
			endif

			activeChanCount = 0
			channelList     = ""

			if(pa.showAverageTrace || pa.deconvolution.enable || pa.multipleGraphs)
				// handle graph legends and average calculation
				for(k = 0; k < numChannelTypeTraces; k += 1)
					idx       = indizesChannelType[k]
					headstage = str2num(traceData[idx][%headstage])

					if(!IsFinite(headstage)) // ignore unassociated channels or duplicated headstages in traceData
						continue
					endif

					sweepNo          = str2num(traceData[idx][%sweepNumber])
					channelNumberStr = traceData[idx][%channelNumber]
					channelNumber    = str2num(channelNumberStr)

					if(WhichListItem(channelNumberStr, channelList) == -1)
						activeChanCount += 1
						channelList = AddListItem(channelNumberStr, channelList, ";", inf)
					endif

					isDiagonalElement = (activeRegionCount == activeChanCount)

					listOfWaves = listOfWavesPerChannel[channelNumber]
					numSweeps   = ItemsInList(listOfWaves) / numPulses

					graph = PA_GetGraph(win, pa.multipleGraphs, channelTypeStr, channelNumber, region, activeRegionCount, activeChanCount)
					PA_GetAxes(pa.multipleGraphs, activeRegionCount, activeChanCount, vertAxis, horizAxis)
					traceCount = TUD_GetTraceCount(graph)

					baseName = PA_BaseName(channelTypeStr, channelNumber, region)
					WAVE/Z averageWave = $""
					if(pa.showAverageTrace && !IsEmpty(listOfWaves))
						WAVE averageWave = PA_Average(listOfWaves, pulseAverageDFR, PA_AVERAGE_WAVE_PREFIX + baseName)

						sprintf traceName, "T%0*d%s%s", TRACE_NAME_NUM_DIGITS, traceCount, PA_AVERAGE_WAVE_PREFIX, baseName
						traceCount += 1

						GetTraceColor(NUM_HEADSTAGES + 1, red, green, blue)
						AppendToGraph/Q/W=$graph/L=$vertAxis/B=$horizAxis/C=(red, green, blue) averageWave/TN=$traceName
						ModifyGraph/W=$graph lsize($traceName)=1.5

						TUD_SetUserDataFromWaves(graph, traceName, {"traceType", "occurence", "XAXIS", "YAXIS", "DiagonalElement"}, \
									             {"Average", "0", horizAxis, vertAxis, num2str(isDiagonalElement)})
						TUD_SetUserData(graph, traceName, "fullPath", GetWavesDataFolder(averageWave, 2))

						listOfWavesPerChannel[channelNumber] = ""
					endif

					if(pa.deconvolution.enable && !isDiagonalElement && !IsEmpty(listOfWaves))
						if(!WaveExists(averageWave))
							WAVE averageWave = PA_Average(listOfWaves, pulseAverageDFR, PA_AVERAGE_WAVE_PREFIX + baseName)
						endif

						WAVE deconv = PA_Deconvolution(averageWave, pulseAverageDFR, traceName, pa.deconvolution)

						sprintf traceName, "T%0*d%s%s", TRACE_NAME_NUM_DIGITS, traceCount, PA_DECONVOLUTION_WAVE_PREFIX, baseName
						traceCount += 1

						AppendToGraph/Q/W=$graph/L=$vertAxis/B=$horizAxis/C=(0,0,0) deconv[0,inf;PA_PLOT_STEPPING]/TN=$traceName
						ModifyGraph/W=$graph lsize($traceName)=2

						TUD_SetUserDataFromWaves(graph, traceName, {"traceType", "occurence", "XAXIS", "YAXIS", "DiagonalElement"}, \
									             {"Deconvolution", "0", horizAxis, vertAxis, num2str(isDiagonalElement)})
						TUD_SetUserData(graph, traceName, "fullPath", GetWavesDataFolder(deconv, 2))
					endif

					if(pa.multipleGraphs)
						sprintf str, "\\Z08\\Zr075#Pulses %g / #Swps. %d", numPulses, numSweeps
						Legend/W=$graph/C/N=leg/X=-5.00/Y=-5.00 str

						GetTraceColor(headstage, red, green, blue)
						sprintf str, "\\k(%d, %d, %d)\\K(%d, %d, %d)\\W555\\k(0, 0, 0)\\K(0, 0, 0)", red, green, blue, red, green, blue

						sprintf str, "%s%d / Reg. %d HS%s", channelTypeStr, channelNumber, region, str
						AppendText/W=$graph str

						ModifyGraph/W=$graph mode=0, nticks=0, noLabel=2, axthick=0, margin=5
					endif
				endfor // channels
			endif

			if(!pa.multipleGraphs)
				EquallySpaceAxis(graph, axisRegExp="left_R" + num2str(activeRegionCount) + ".*", sortOrder=1)
				EquallySpaceAxis(graph, axisRegExp="bottom.*", sortOrder=0)
			endif
		endfor // headstages
	endfor // channelType

	if(!pa.multipleGraphs)
		ModifyGraph/W=$graph mode=0, nticks=0, noLabel=2, axthick=0, margin=5
	endif

	// kill all graphs from earlier runs which were not created anymore
	numGraphs = ItemsInList(preExistingGraphs)
	for(i = 0; i < numGraphs; i += 1)
		graph = StringFromList(i, preExistingGraphs)
		if(WhichListItem(graph, newlyCreatedGraphs) == -1)
			KillWindow/Z $graph
		endif
	endfor
End

/// @brief Generate a static base name for objects in the current averaging folder
static Function/S PA_BaseName(channelTypeStr, channelNumber, headStage)
	string channelTypeStr
	variable channelNumber, headStage

	string baseName
	baseName = channelTypeStr + num2str(channelNumber)
	baseName += "_HS" + num2str(headStage)

	return baseName
End

/// @brief Zero pulse averaging traces using @c ZeroWave
///
/// This function has to be the first function to call before altering waves
/// from listofWaves.
///
/// @param listOfWaves   a list with full wave paths where to apply zeroing
/// @param setZero       add/remove zeroing from the wave
static Function PA_ZeroTraces(listOfWaves, setZero)
	string listOfWaves
	variable setZero

	variable i, numWaves

	if(IsEmpty(listOfWaves))
		return NaN
	endif

	setZero = !!setZero

	if(!setZero)
		return NaN
	endif

	numWaves = ItemsInList(listOfWaves)
	for(i = 0; i < numWaves; i += 1)
		WAVE wv = $StringFromList(i, listOfWaves)
		ZeroWave(wv)
	endfor
End

/// @brief calculate the average wave from a @p listOfWaves
///
/// Note: MIES_fWaveAverage() usually takes 5 times longer than CA_AveragingKey()
///
/// @returns wave reference to the average wave specified by @p outputDFR and @p outputWaveName
static Function/WAVE PA_Average(listOfWaves, outputDFR, outputWaveName)
	string listOfWaves
	DFREF outputDFR
	string outputWaveName

	WAVE wv = CalculateAverage(listOfWaves, outputDFR, outputWaveName, skipCRC = 1)

	return wv
End

Function/WAVE PA_SmoothDeconv(input, deconvolution)
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
			PA_Update(cba.win)
			break
	endswitch

	return 0
End

Function PA_CheckProc_Individual(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			PA_Update(cba.win)
			break
	endswitch

	return 0
End

Function PA_CheckProc_Average(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch(cba.eventCode)
		case 2: // mouse up
			PA_Update(cba.win)
			break
	endswitch

	return 0
End

Function PA_CheckProc_Deconvolution(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			PA_UpdateSweepPlotDeconvolution(cba.win)
			break
		case -1: // control being killed
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
			PA_Update(sva.win)
			break
	endswitch

	return 0
End

/// @brief checks if PA is active.
Function PA_IsActive(win)
	string win

	return BSP_IsActive(win, MIES_BSP_PA)
End

/// @brief Update deconvolution traces in Sweep Plots
static Function PA_UpdateSweepPlotDeconvolution(win)
	string win

	string graph, graphs, horizAxis, vertAxis
	string traceName, fullPath, avgTrace
	string baseName, bsPanel
	variable i, numGraphs, j, numTraces, traceIndex
	STRUCT PulseAverageDeconvSettings deconvolution

	if(!PA_IsActive(win))
		return 0
	endif

	bsPanel = BSP_GetPanel(win)
	PA_DeconvGatherSettings(bsPanel, deconvolution)

	graphs = PA_GetAverageGraphs()
	numGraphs = ItemsInList(graphs)
	for(i = 0; i < numGraphs; i += 1)
		graph = StringFromList(i, graphs)

		if(deconvolution.enable)
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

				WAVE deconv = PA_Deconvolution(averageWave, pulseAverageDFR, traceName, deconvolution)

				AppendToGraph/Q/W=$graph/L=$vertAxis/B=$horizAxis/C=(0,0,0) deconv/TN=$traceName
				ModifyGraph/W=$graph lsize($traceName)=2

				TUD_SetUserDataFromWaves(graph, traceName, {"traceType", "occurence", "XAXIS", "YAXIS", "DiagonalElement"}, \
							             {"Deconvolution", "0", horizAxis, vertAxis, "0"})
				TUD_SetUserData(graph, traceName, "fullPath", GetWavesDataFolder(deconv, 2))
			endfor
		else // !deconvolution.enable
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

/// @brief use reference trace from graph for time alignment
///
/// A reference trace for automatic time alignment is usually the first trace
/// added to a graph where region and channelnumber have the same counter. These
/// traces are plotted on the diagonal graphs/axes of the PA graph(s).
///
/// @param refTraces list of graph#trace entries as reference for time alignment
static Function PA_AutomaticTimeAlignment(refTraces)
	string refTraces

	string graphtrace
	variable i, numTraces

	numTraces = ItemsInList(refTraces)
	for(i = 0; i < numTraces; i += 1)
		graphtrace = StringFromList(i, refTraces)
		TimeAlignmentIfReq(graphtrace, TIME_ALIGNMENT_MAX, 0, -inf, inf)
	endfor
End

/// @brief Get all traces marked as reference traces for the current graph.
///
/// @param graph  Pulse Averaging Reference Graph (diagonal elements when multiple graphs)
/// @returns graphtraces in the form graph#trace if the graph is a valid reference graph
static Function/S PA_GetReferenceTracesFromGraph(graph)
	string graph

	string trace, traces
	variable i, numTraces
	string graphTraces = ""

	ASSERT(WindowExists(graph), "specified PA graph does not exist")

	if(!str2num(GetUserData(graph, "", PA_USERDATA_REFERENCE_GRAPH)))
		return ""
	endif

	traces = GetUserData(graph, "", PA_USERDATA_REFERENCE_TRACES)
	numTraces = ItemsInList(traces)
	for(i = 0; i < numTraces; i += 1)
		trace = StringFromList(i, traces)
		graphtraces = AddListItem(graph + "#" + trace, graphtraces)
	endfor

	return graphtraces
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
static Function PA_ResetWavesIfRequired(listOfWaves, pa)
	string listOfWaves
	STRUCT PulseAverageSettings &pa

	variable i, statusZero, statusTimeAlign, numEntries
	WAVE/WAVE wv = ListToWaveRefWave(listOfWaves, 1)

	numEntries = DimSize(wv, ROWS)
	for(i = 0; i < numEntries; i += 1)
		statusZero = GetNumberFromWaveNote(wv[i], NOTE_KEY_ZEROED)
		statusTimeAlign = GetNumberFromWaveNote(wv[i], NOTE_KEY_TIMEALIGN)

		if(statusZero == 0 && statusTimeAlign == 0)
			continue // wave is unmodified
		endif

		if(statusZero == pa.zeroTraces && statusTimeAlign == pa.autoTimeAlignment)
			continue // wave is up to date
		endif
		ReplaceWaveWithBackup(wv[i], nonExistingBackupIsFatal = 1, keepBackup = 1)
	endfor
End
