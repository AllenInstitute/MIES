#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_PA
#endif // AUTOMATED_TESTING

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
///@{
static StrConstant PA_DRAWLAYER_XZEROLINE     = "ProgAxes"
static StrConstant PA_DRAWLAYER_SCALEBAR      = "ProgFront"
static StrConstant PA_DRAWLAYER_FAILED_PULSES = "ProgBack"
///@}

static StrConstant PA_GRAPH_PREFIX          = "PulseAverage"
static StrConstant PA_SOURCE_WAVE_TIMESTAMP = "SOURCE_WAVE_TS"

static StrConstant PA_SETTINGS = "PulseAverageSettings"

static StrConstant PA_USER_DATA_X_START_RELATIVE_PREFIX = "XAxisStartPlotRelative_"
static StrConstant PA_USER_DATA_CALC_XLENGTH            = "CalculatedXBarLength"
static StrConstant PA_USER_DATA_CALC_YLENGTH            = "CalculatedYBarLength"
static StrConstant PA_USER_DATA_USER_YLENGTH            = "UserYBarLength"

static Constant PA_USE_WAVE_SCALES = 0x01
static Constant PA_USE_AXIS_SCALES = 0x02

static Constant PA_X_AXIS_OFFSET = 0.01

static Constant PA_PLOT_STEPPING = 16

static Constant PA_DISPLAYMODE_TRACES = 0x01
static Constant PA_DISPLAYMODE_IMAGES = 0x02
static Constant PA_DISPLAYMODE_ALL    = 0xFF

static Constant PA_COLORSCALE_PANEL_WIDTH = 150

static Constant PA_PEAK_BOX_AVERAGE = 5

/// @name Pulse sort order
/// Popupmenu indizes for the PA plot controls
///@{
static Constant PA_PULSE_SORTING_ORDER_SWEEP = 0x0
static Constant PA_PULSE_SORTING_ORDER_PULSE = 0x1
///@}
///

static Constant PA_AVGERAGE_PLOT_LSIZE      = 1.5
static Constant PA_DECONVOLUTION_PLOT_LSIZE = 2

static StrConstant PA_PROPERTIES_KEY_REGIONS           = "Regions"
static StrConstant PA_PROPERTIES_KEY_CHANNELS          = "Channels"
static StrConstant PA_PROPERTIES_KEY_PREVREGIONS       = "PreviousRegions"
static StrConstant PA_PROPERTIES_KEY_PREVCHANNELS      = "PreviousChannels"
static StrConstant PA_PROPERTIES_KEY_SWEEPS            = "Sweeps"
static StrConstant PA_PROPERTIES_KEY_LAYOUTCHANGE      = "LayoutChanged"
static StrConstant PA_PROPERTIES_STRLIST_SEP           = ","
static StrConstant PA_SETINDICES_KEY_ACTIVECHANCOUNT   = "ActiveChanCount"
static StrConstant PA_SETINDICES_KEY_ACTIVEREGIONCOUNT = "ActiveRegionCount"
static StrConstant PA_SETINDICES_KEY_DISPCHANGE        = "DisplayChange"
static StrConstant PA_SETINDICES_KEY_DISPSTART         = "DisplayStart"

static Constant PA_UPDATEINDICES_TYPE_PREV = 1
static Constant PA_UPDATEINDICES_TYPE_CURR = 2

static Constant PA_INDICESCHANGE_NONE    = 0
static Constant PA_INDICESCHANGE_MOVED   = 1
static Constant PA_INDICESCHANGE_REMOVED = 2
static Constant PA_INDICESCHANGE_ADDED   = 3

static Constant PA_PASIINIT_BASE       = 0x01
static Constant PA_PASIINIT_INDICEMETA = 0x02

static Constant PA_MINIMUM_SPIKE_WIDTH = 0.2 // ms

// comment out to show all the axes, useful for debugging
#define PA_HIDE_AXIS

// comment out to show execution times in debugging mode
#define PA_HIDE_EXECUTION_TIME

/// @brief Return a list of all graphs
static Function/S PA_GetGraphs(string win, variable displayMode)

	return WinList(PA_GetGraphPrefix(GetMainWindow(win), displayMode) + "*", ";", "WIN:1")
End

static Function/S PA_GetGraphName(string win, STRUCT PulseAverageSettings &pa, variable displayMode, variable channelNumber, variable activeRegionCount)

	string name = PA_GetGraphPrefix(win, displayMode)

	if(pa.multipleGraphs)
		return name + "_AD" + num2str(channelNumber) + "_R" + num2str(activeRegionCount)
	endif

	return name
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
			FATAL_ERROR("invalid display mode")
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
	variable width, height, width_spacing, height_spacing, width_offset, height_offset
	string win, winAbove

	win = PA_GetGraphName(mainWin, pa, displayMode, channelNumber, activeRegionCount)

	if(!WindowExists(win))

		if(pa.multipleGraphs)
			width          = 100
			height         = 80
			width_spacing  = 10
			height_spacing = 3.5
			width_offset   = (activeRegionCount - 1) * (width + width_spacing)
			height_offset  = (activeChanCount - 1) * (height + 2 * height_spacing)
		else
			width         = 400
			height        = 400
			width_spacing = 10
			// rest is zero already
		endif

		GetWindow $mainWin, wsize
		left   = V_right + width_spacing
		top    = V_top
		right  = left + width
		bottom = top + height

		left   += width_offset
		right  += width_offset
		top    += height_offset
		bottom += height_offset
		Display/W=(left, top, right, bottom)/K=1/N=$win
		SetWindow $win, userdata($MIES_BSP_PA_MAINPANEL)=mainWin
		PA_GetTraceCountFromGraphData(win, clear = 1)
		if(displayMode == PA_DISPLAYMODE_IMAGES && (!pa.multipleGraphs || activeRegionCount == numRegions))
			NewPanel/HOST=#/EXT=0/W=(0, 0, PA_COLORSCALE_PANEL_WIDTH, bottom - top) as ""
			Display/FG=(FL, FT, FR, FB)/HOST=#
		endif

		if(pa.multipleGraphs)
			winAbove = PA_GetGraphName(mainWin, pa, displayMode, channelNumber - 1, activeRegionCount)

			for(i = channelNumber - 1; i >= 0; i -= 1)
				winAbove = PA_GetGraphName(mainWin, pa, displayMode, i, activeRegionCount)

				if(WindowExists(winAbove))
					DoWindow/B=$winAbove $win
					break
				endif
			endfor
		endif
		NVAR JSONid = $GetSettingsJSONid()
		PS_InitCoordinates(JSONid, win, win)

		switch(displayMode)
			case PA_DISPLAYMODE_IMAGES:
				SetWindow $win, hook(resizeHookAndScalebar)=PA_ImageWindowHook
				break
			case PA_DISPLAYMODE_TRACES:
				SetWindow $win, hook(resizeHookAndScalebar)=PA_TraceWindowHook
				break
			default:
				FATAL_ERROR("Invalid display mode")
		endswitch
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

	sprintf vertAxis, "left_R%d_C%d", region, channel
	sprintf horizAxis, "bottom_R%d", region
	Make/FREE/T w = {vertAxis, horizAxis}
	return w
End

/// @brief Derive the pulse infos from a DA wave
///
/// Uses plain FindLevels after the onset delay using 10% of the full range
/// above the minimum as threshold
///
/// @return pulse info wave or if nothing could be found, an invalid wave reference
static Function/WAVE PA_CalculatePulseInfos(WAVE DA, string fullPath, variable channelNumber, variable totalOnsetDelay)

	variable level, delta, searchStart, numLevels, numPulses
	string key

	variable first

	ASSERT(totalOnsetDelay >= 0, "Invalid onsetDelay")

	key = CA_PulseTimes(DA, fullPath, channelNumber, totalOnsetDelay)
	WAVE/Z cache = CA_TryFetchingEntryFromCache(key)
	if(WaveExists(cache))
		return cache
	endif

	WaveStats/Q/M=1/R=(totalOnsetDelay, Inf) DA
	level = V_min + (V_Max - V_Min) * 0.1

	delta = DimDelta(DA, ROWS)
	if(totalOnsetDelay >= delta)
		searchStart = totalOnsetDelay - delta
	endif

	MAKE/FREE/D levels
	FindLevels/Q/R=(searchStart, Inf)/EDGE=(FINDLEVEL_EDGE_BOTH)/DEST=levels DA, level

	if(DimSize(levels, ROWS) == 0)
		return $""
	endif

	// FindLevels interpolates between two points and searches for a rising edge
	// so the returned value is commonly a bit too large
	// round to the last wave point
	levels[] = levels[p] - mod(levels[p], delta)

	numLevels = DimSize(levels, ROWS)

	if(IsOdd(numLevels))
		// no baseline at the begin or end
		// let's fake it so that we have an even number of edges

		first = ScaleToIndex(DA, levels[0], ROWS)

		// determine edge type of first level
		if(DA[first] < DA[first + 1])
			// rising
			// fake trailing falling edge
			Redimension/N=(++numLevels) levels
			levels[numLevels - 1] = IndexToScale(DA, DimSize(DA, ROWS) - 1, ROWS)
		else
			// falling
			// fake leading rising edge
			InsertPoints/M=(ROWS) 0, 1, levels
			levels[0]  = IndexToScale(DA, 0, ROWS)
			numLevels += 1
		endif
	endif

	numPulses = numLevels / 2
	ASSERT(IsInteger(numPulses), "Odd number of values (literally).")

	WAVE pulseInfos = GetPulseInfoWave()
	Redimension/N=(numPulses, -1) pulseInfos

	pulseInfos[][%PulseStart] = levels[p * 2]
	pulseInfos[][%PulseEnd]   = levels[p * 2 + 1]

	if(numPulses > 1)
		pulseInfos[0, numPulses - 2][%Length] = pulseInfos[p + 1][%PulseStart] - pulseInfos[p][%PulseStart]
	endif
	pulseInfos[numPulses - 1][%Length] = IndexToScale(DA, DimSize(DA, ROWS) - 1, ROWS) - pulseInfos[numPulses - 1][%PulseStart]

	CA_StoreEntryIntoCache(key, pulseInfos)

	return pulseInfos
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

	return GetUniqueEntries(headstages)
End

/// @brief Return pulse infos
///
/// @param traceData        2D wave with trace information, from GetTraceInfos()
/// @param idx              Index into traceData, used for determining sweep numbers, labnotebooks, etc.
/// @param region           Region (headstage) to get pulse starting times for
/// @param channelTypeStr   Type of the channel, one of @ref XOP_CHANNEL_NAMES
///
/// @return invalid wave reference if no pulses could be found or 2D wave see GetPulseInfoWave()
Function/WAVE PA_GetPulseInfos(WAVE/T traceData, variable idx, variable region, string channelTypeStr)

	variable sweepNo, totalOnsetDelay, channel
	string str, fullPath

	sweepNo = str2num(traceData[idx][%sweepNumber])

	WAVE/Z textualValues   = $traceData[idx][%textualValues]
	WAVE/Z numericalValues = $traceData[idx][%numericalValues]

	ASSERT(WaveExists(textualValues) && WaveExists(numericalValues), "Missing labnotebook waves")

	sprintf str, "Calculated pulse starting times for headstage %d", region
	DEBUGPRINT(str)

	WAVE/Z/T epochs = GetLastSetting(textualValues, sweepNo, EPOCHS_ENTRY_KEY, DATA_ACQUISITION_MODE)
	if(WaveExists(epochs))
		WAVE/Z pulseInfosEpochs = PA_RetrievePulseInfosFromEpochs(epochs[region])
	endif

	if(!WaveExists(pulseInfosEpochs) || defined(AUTOMATED_TESTING))
		fullPath = traceData[idx][%fullPath]
		DFREF singleSweepFolder = GetWavesDataFolderDFR($fullPath)
		ASSERT(DataFolderExistsDFR(singleSweepFolder), "Missing singleSweepFolder")

		WAVE DACs = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)
		channel = DACs[region]
		if(IsNaN(channel))
			return $""
		endif

		totalOnsetDelay = GetTotalOnsetDelay(numericalValues, sweepNo)

		WAVE DA = GetDAQDataSingleColumnWave(singleSweepFolder, XOP_CHANNEL_TYPE_DAC, channel)
		totalOnsetDelay = GetTotalOnsetDelay(numericalValues, sweepNo)
		WAVE/Z pulseInfosCalc = PA_CalculatePulseInfos(DA, fullPath, channel, totalOnsetDelay)
	endif

#ifdef AUTOMATED_TESTING
	PA_DiffPulseInfos(numericalValues, sweepNo, pulseInfosEpochs, pulseInfosCalc)
#endif // AUTOMATED_TESTING

	if(WaveExists(pulseInfosEpochs))
		return pulseInfosEpochs
	endif

	return pulseInfosCalc
End

/// @brief Compare epoch and calculated pulse infos
static Function PA_DiffPulseInfos(WAVE numericalValues, variable sweepNo, WAVE/Z pulseInfosEpochs, WAVE/Z pulseInfosCalc)

	variable i, j, numRowsEpochs, numColsEpochs

	variable warnDiffms = GetLastSettingIndep(numericalValues, sweepNo, "Sampling interval DA", DATA_ACQUISITION_MODE) * 2

	if(WaveExists(pulseInfosEpochs) && WaveExists(pulseInfosCalc))
		numRowsEpochs = DimSize(pulseInfosEpochs, ROWS)
		numColsEpochs = DimSize(pulseInfosEpochs, COLS)

		if(numRowsEpochs != DimSize(pulseInfosCalc, ROWS))
			print/D "Warn: Differing dimensions in pulse infos from epochs:\r", pulseInfosEpochs, "\r from Calculation:\r", pulseInfosCalc
		else
			for(i = 0; i < numRowsEpochs; i += 1)
				for(j = 0; j < numColsEpochs; j += 1)
					if(abs(pulseInfosEpochs[i][j] - pulseInfosCalc[i][j]) > warnDiffms                            \
					   && j == (DimSize(pulseInfosEpochs, COLS) - 1) && i == (DimSize(pulseInfosEpochs, ROWS) - 1))
						print/D "Warn: Differing pulse infos in [" + num2str(i) + ", " + GetDimLabel(pulseInfosEpochs, COLS, j) + "], from epochs:\r", pulseInfosEpochs, "from Calculation:\r", pulseInfosCalc
						break
					endif
				endfor
			endfor
		endif
	endif

	if(WaveExists(pulseInfosEpochs) && !WaveExists(pulseInfosCalc))
		print/D "Warn: Returned pulse start times from Epochs but got none from Calculation. From Epochs:\r", pulseInfosEpochs
	endif
End

/// @brief Extracts the pulse info from the lab notebook and returns them as wave
///
/// @param[in] epochInfo epoch data to extract pulse starting times
/// @returns pulse info, see GetPulseInfoWave() or an invalid wave reference on error
static Function/WAVE PA_RetrievePulseInfosFromEpochs(string epochInfo)

	variable numEpochs, idx, pulseNo, epoch, i, first, last, level, hasPerPulseInfo, numWrittenEpochs, hasOneValidEntry
	string tags

	if(IsEmpty(epochInfo))
		return $""
	endif

	WAVE/T epochs = EP_EpochStrToWave(epochInfo)

	numEpochs = DimSize(epochs, ROWS)
	WAVE/D pulseInfos = GetPulseInfoWave()
	Redimension/N=(numEpochs, -1) pulseInfos

	Make/FREE/N=(WB_TOTAL_NUMBER_OF_EPOCHS) pulsesPerStimsetEpoch

	pulseInfos = NaN

	for(i = 0; i < numEpochs; i += 1)
		first = str2num(epochs[i][EPOCH_COL_STARTTIME])
		last  = str2num(epochs[i][EPOCH_COL_ENDTIME])
		tags  = epochs[i][EPOCH_COL_TAGS]
		level = str2num(epochs[i][EPOCH_COL_TREELEVEL])

		switch(level)
			case 2: // fallthrough
			case 3:
				pulseNo = NumberByKey("Pulse", tags, "=")

				if(IsNaN(pulseNo))
					continue
				endif

				epoch = NumberByKey("Epoch", tags, "=")
				ASSERT(IsValidEpochNumber(epoch), "Invalid epoch")

				pulsesPerStimsetEpoch[epoch] = max(pulsesPerStimsetEpoch[epoch], pulseNo)

				// readout pulse indizes are per epoch, so we need to sum up all the pulse counts from previous epochs
				if(epoch > 0)
					idx = Sum(pulsesPerStimsetEpoch, 0, epoch - 1) + pulseNo
				else
					idx = pulseNo
				endif

				if(level == 2)
					pulseInfos[idx][%Length] = (last - first) * ONE_TO_MILLI

					hasOneValidEntry = 1
				elseif((level == 3 && (strsearch(tags, "Active", 0) != -1)) || (strsearch(tags, "SubType=Pulse;", 0) != -1))
					pulseInfos[idx][%PulseStart] = first * ONE_TO_MILLI
					pulseInfos[idx][%PulseEnd]   = last * ONE_TO_MILLI

					hasPerPulseInfo  = 1
					hasOneValidEntry = 1
				endif
				break
			default:
				// do nothing
				continue
		endswitch
	endfor

	if(!hasPerPulseInfo || !hasOneValidEntry)
		return $""
	endif

	numWrittenEpochs = Sum(pulsesPerStimsetEpoch) + 1

	Redimension/N=(numWrittenEpochs, -1) pulseInfos

	return pulseInfos
End

static Function PA_GetPulseLength(WAVE pulseInfos, variable pulseIndex, variable overridePulseLength, variable fixedPulseLength)

	variable numPulses, minimum, lastPulseForMin

	if(fixedPulseLength)
		return overridePulseLength
	endif

	numPulses = DimSize(pulseInfos, ROWS)

	if(numPulses <= 1)
		return pulseInfos[pulseIndex][%Length]
	endif

	// we ignore the pulse lengths for the last one if we can
	lastPulseForMin = min(0, DimSize(pulseInfos, ROWS) - 2)
	Duplicate/FREE/RMD=[0, lastPulseForMin][FindDimLabel(pulseInfos, COLS, "Length")] pulseInfos, pulseLengths

	minimum = WaveMin(pulseLengths)

	if(minimum > 0)
		return minimum
	endif

	ASSERT(minimum == 0, "pulse length expected to be zero")

	return overridePulseLength
End

/// @brief Single pulse wave creator
///
/// The wave note for the pulse waves is stored in a separate empty wave. This speeds up the caching
/// logic for the pulse waves a lot.
///
/// The wave note is used for documenting the applied operations:
/// - `$NOTE_KEY_FAILED_PULSE_LEVEL`: Level used for failed pulse search
/// - `$NOTE_KEY_NUMBER_OF_SPIKES`: Number of spikes used for failed pulse search
/// - `$NOTE_KEY_PULSE_LENGTH`: Length in points of the pulse wave (before any operations)
/// - `$NOTE_KEY_SEARCH_FAILED_PULSE`: Checkbox state of "Search failed pulses"
/// - `$NOTE_KEY_TIMEALIGN`: Time alignment was active and applied
/// - `$NOTE_KEY_TIMEALIGN_TOTAL_OFFSET`: Calculated offset from time alignment
/// - `$NOTE_KEY_ZEROED`: Zeroing was active and applied
/// - `$NOTE_KEY_WAVE_MINIMUM`: Minimum value of the data
/// - `$NOTE_KEY_WAVE_MAXIMUM`: Maximum value of the data
/// - `$NOTE_KEY_TIMEALIGN_FEATURE_POS`: Position where the feature for time alignment was found
/// - `$NOTE_KEY_PULSE_IS_DIAGONAL`: Stores if pulse is shown in the diagonal of the output layout
/// - `$PA_SOURCE_WAVE_TIMESTAMP`: Last modification time of the pulse wave before creation.
/// - `$NOTE_KEY_PULSE_START`: ms coordinates where the pulse starts
/// - `$NOTE_KEY_PULSE_END`: ms coordinates where the pulse ends
/// - `$NOTE_KEY_PULSE_CLAMPMODE`: Clamp mode of the pulse data, one of @ref AmplifierClampModes
///
/// Diagonal pulses only with failed pulse search enabled:
/// - `$NOTE_KEY_PULSE_HAS_FAILED`: Pulse has failed
/// - `$NOTE_KEY_PULSE_SPIKE_POSITIONS`: Comma separated list of spike positions in ms. `0` is the start of the pulse.
static Function [WAVE pulseWave, WAVE noteWave] PA_CreateAndFillPulseWaveIfReq(WAVE/Z wv, DFREF singleSweepFolder, variable channelType, variable channelNumber, variable clampMode, variable region, variable pulseIndex, variable first, variable length, WAVE pulseInfos)

	variable existingLength

	if(first < 0 || length <= 0 || (DimSize(wv, ROWS) - first) <= length)
		return [$"", $""]
	endif

	length = limit(length, 1, DimSize(wv, ROWS) - first)

	WAVE singlePulseWave     = GetPulseAverageWave(singleSweepFolder, length, channelType, channelNumber, region, pulseIndex)
	WAVE singlePulseWaveNote = GetPulseAverageWaveNoteWave(singleSweepFolder, length, channelType, channelNumber, region, pulseIndex)

	existingLength = GetNumberFromWaveNote(singlePulseWaveNote, NOTE_KEY_PULSE_LENGTH)

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
	// by definition the pulse wave starts with the rising edge of the active pulse
	SetNumberInWaveNote(singlePulseWaveNote, NOTE_KEY_PULSE_START, 0)
	SetNumberInWaveNote(singlePulseWaveNote, NOTE_KEY_PULSE_END, pulseInfos[pulseIndex][%PulseEnd] - pulseInfos[pulseIndex][%PulseStart])

	PA_UpdateMinAndMax(singlePulseWave, singlePulseWaveNote)

	SetNumberInWaveNote(singlePulseWaveNote, NOTE_KEY_PULSE_LENGTH, length)
	SetNumberInWaveNote(singlePulseWaveNote, NOTE_KEY_CLAMP_MODE, clampMode)

	SetNumberInWaveNote(singlePulseWaveNote, PA_SOURCE_WAVE_TIMESTAMP, ModDate(wv))

	CreateBackupWave(singlePulseWave, forceCreation = 1)
	CreateBackupWave(singlePulseWaveNote, forceCreation = 1)

	return [singlePulseWave, singlePulseWaveNote]
End

threadsafe static Function PA_UpdateMinAndMax(WAVE wv, WAVE noteWave)

	variable minimum, maximum

	[minimum, maximum] = WaveMinAndMax(wv)
	SetNumberInWaveNote(noteWave, NOTE_KEY_WAVE_MINIMUM, minimum, format = PERCENT_F_MAX_PREC)
	SetNumberInWaveNote(noteWave, NOTE_KEY_WAVE_MAXIMUM, maximum, format = PERCENT_F_MAX_PREC)
End

/// @brief Generate a key for a pulse
///
/// All pulses with that key are either failing or passing.
static Function/S PA_GenerateFailedPulseKey(variable sweep, variable region, variable pulse)

	string key

	sprintf key, "%d-%d-%d", sweep, region, pulse

	return key
End

static Function [WAVE/D sweeps, WAVE/T experiments] PA_GetSweepsAndExperimentsFromIndices(string win, WAVE/Z additionalData)

	variable i, numIndices, sweepNo
	string experiment

	if(!WaveExists(additionalData))
		Make/FREE/D/N=0 sweeps
		Make/FREE/T/N=0 experiments
		return [sweeps, experiments]
	endif

	numIndices = DimSize(additionalData, ROWS)
	Make/FREE/D/N=(numIndices) sweeps
	Make/FREE/T/N=(numIndices) experiments

	for(i = 0; i < numIndices; i += 1)
		[sweepNo, experiment] = OVS_GetSweepAndExperiment(win, additionalData[i])
		sweeps[i]             = sweepNo
		experiments[i]        = experiment
	endfor

	return [sweeps, experiments]
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
///
/// Fast path for incremental update:
/// - The previous list of regions/channels is saved
/// - We get the indizes of the new sweep (from additionalData)
/// - Only these indizes are added to the properties wave, as well as the setIndice waves at the end
/// - information is stored where the new data begins
/// - The region/channels of the new Sweep(s) are merged with the old ones.
/// - In case the layout changed compared to the old regions/channels it is calculated again.
static Function [STRUCT PulseAverageSetIndices pasi] PA_GenerateAllPulseWaves(string win, STRUCT PulseAverageSettings &pa, variable mode, WAVE/Z additionalData)

	variable startingPulseSett, endingPulseSett, pulseHasFailed, numActive, clampMode
	variable i, j, k, region, sweepNo, idx, numPulsesTotal, endingPulse
	variable headstage, pulseToPulseLength, totalOnsetDelay, numChannelTypeTraces, totalPulseCounter, jsonID, lastSweep
	variable activeChanCount, channelNumber, first, length, channelType, numChannels, numRegions
	variable numPulseCreate, prevTotalPulseCounter, numNewSweeps, numNewIndicesSweep, incrementalMode, layoutChanged
	variable lblIndex, lblClampMode
	variable lblTraceHeadstage, lblTraceExperiment, lblTraceSweepNumber, lblTraceChannelNumber, lblTracenumericalValues, lblTraceFullpath
	variable lblACTIVEREGION, lblACTIVECHANNEL
	string channelTypeStr, channelList, regionChannelList, channelNumberStr, key, regionList, sweepList, sweepNoStr, experiment
	string oldRegionList, oldChannelList

	WAVE/Z/T traceData = GetTraceInfos(GetMainWindow(win), addFilterKeys = {"channelType", "AssociatedHeadstage"}, addFilterValues = {"AD", "1"})
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

	DFREF pulseAverageDFR       = GetDevicePulseAverageFolder(pa.dfr)
	DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)
	WAVE  properties            = GetPulseAverageProperties(pulseAverageHelperDFR)
	oldRegionList  = GetStringFromWaveNote(properties, PA_PROPERTIES_KEY_REGIONS)
	oldChannelList = GetStringFromWaveNote(properties, PA_PROPERTIES_KEY_CHANNELS)

	if(mode != POST_PLOT_ADDED_SWEEPS)
		KillorMoveToTrash(dfr = GetDevicePulseAverageHelperFolder(pa.dfr))
	endif

	DFREF     pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)
	WAVE      properties            = GetPulseAverageProperties(pulseAverageHelperDFR)
	WAVE/WAVE propertiesWaves       = GetPulseAveragePropertiesWaves(pulseAverageHelperDFR)

	// Get regions of all traces
	WAVE/Z regions = PA_GetUniqueHeadstages(traceData)
	if(!WaveExists(regions))
		return [pasi]
	endif
	numRegions = DimSize(regions, ROWS)
	regionList = ""
	for(i = 0; i < numRegions; i += 1)
		regionList = AddListItem(num2istr(regions[i]), regionList, PA_PROPERTIES_STRLIST_SEP, Inf)
	endfor

	Make/FREE/N=(MINIMUM_WAVE_SIZE)/WAVE headstageRemovalPerSweep

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
		j            = 0
		numNewSweeps = DimSize(additionalData, ROWS)
		ASSERT(numNewSweeps > 0, "Set POST_PLOT_ADDED_SWEEPS, but found no new sweep(s) in additionlData")
		[WAVE/D newSweeps, WAVE/T newExperiments] = PA_GetSweepsAndExperimentsFromIndices(win, additionalData)

		for(i = 0; i < numNewSweeps; i += 1)
			WAVE/Z indizesNewSweep = FindIndizes(traceData, colLabel = "SweepNumber", str = num2str(newSweeps[i]))
			if(!WaveExists(indizesNewSweep))
				continue
			endif
			numNewIndicesSweep                          = DimSize(indizesNewSweep, ROWS)
			indizesToAdd[j, j + numNewIndicesSweep - 1] = indizesNewSweep[p - j]
			j                                          += numNewIndicesSweep

			// This assertion check is a workaround for the case that we have multiple sweeps with the same SweepNo from different experiments.
			FindValue/Z/V=(newSweeps[i])/T=(GetMachineEpsilon(WaveType(properties)))/RMD=[][PA_PROPERTIES_INDEX_SWEEP] properties
			ASSERT(V_Value == -1, "A sweep with the same number is already plotted. Multiple sweeps with the same number from different experiments is currently not supported.")

		endfor
		Redimension/N=(j) indizesToAdd

		WAVE indizesChannelTypeAll = indizesChannelType
		WAVE indizesChannelType    = indizesToAdd
		numChannelTypeTraces = DimSize(indizesChannelType, ROWS)

		totalPulseCounter = GetNumberFromWaveNote(properties, NOTE_INDEX)
		SetNumberInWaveNote(properties, NOTE_PA_NEW_PULSES_START, totalPulseCounter)

		WAVE/Z/WAVE setIndices
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

	lblTraceHeadstage       = FindDimLabel(traceData, COLS, "headstage")
	lblTraceSweepNumber     = FindDimLabel(traceData, COLS, "SweepNumber")
	lblTraceChannelNumber   = FindDimLabel(traceData, COLS, "ChannelNumber")
	lblTracenumericalValues = FindDimLabel(traceData, COLS, "numericalValues")
	lblTraceExperiment      = FindDimLabel(traceData, COLS, "Experiment")
	lblTraceFullpath        = FindDimLabel(traceData, COLS, "fullpath")
	lblClampMode            = FindDimLabel(traceData, COLS, "ClampMode")

	lblACTIVEREGION  = FindDimLabel(prevDisplayMapping, LAYERS, "ACTIVEREGION")
	lblACTIVECHANNEL = FindDimLabel(prevDisplayMapping, LAYERS, "ACTIVECHANNEL")

	channelType    = XOP_CHANNEL_TYPE_ADC
	channelTypeStr = StringFromList(channelType, XOP_CHANNEL_NAMES)
	sweepList      = ""
	channelList    = ""

	jsonID = JSON_New()

	for(i = 0; i < numRegions; i += 1)
		region = regions[i]

		activeChanCount   = 0
		regionChannelList = ""

		// we have the starting times for one channel type and headstage combination
		// iterate now over all channels of the same type and extract all
		// requested pulses for them
		for(j = 0; j < numChannelTypeTraces; j += 1)
			idx = indizesChannelType[j]

			// get channel number and update local and global list
			channelNumberStr = traceData[idx][lblTraceChannelNumber]
			channelNumber    = str2num(channelNumberStr)
			if(WhichListItem(channelNumberStr, regionChannelList) == -1)
				activeChanCount  += 1
				regionChannelList = AddListItem(channelNumberStr, regionChannelList, ";", Inf)
			endif
			if(WhichListItem(channelNumberStr, channelList, PA_PROPERTIES_STRLIST_SEP) == -1)
				channelList = AddListItem(channelNumberStr, channelList, PA_PROPERTIES_STRLIST_SEP, Inf)
			endif

			// get pulse start times and from that number of pulses
			WAVE/Z pulseInfos = PA_GetPulseInfos(traceData, idx, region, channelTypeStr)
			if(!WaveExists(pulseInfos))
				continue
			endif

			numPulsesTotal = DimSize(pulseInfos, ROWS)
			endingPulse    = min(numPulsesTotal - 1, endingPulseSett)
			numPulseCreate = endingPulse - startingPulseSett + 1
			if(numPulseCreate <= 0)
				continue
			endif
			// get sweep number
			sweepNoStr = traceData[idx][lblTraceSweepNumber]
			sweepNo    = str2num(sweepNoStr)
			if(WhichListItem(sweepNoStr, sweepList, PA_PROPERTIES_STRLIST_SEP) == -1)
				sweepList = AddListItem(sweepNoStr, sweepList, PA_PROPERTIES_STRLIST_SEP, Inf)

				EnsureLargeEnoughWave(headstageRemovalPerSweep, indexShouldExist = sweepNo)
				headstageRemovalPerSweep[sweepNo] = OVS_GetHeadstageRemoval(win, sweepNo = sweepNo)
			endif

			WAVE/Z activeHS = headstageRemovalPerSweep[sweepNo]
			if(WaveExists(activeHS) && activeHS[region] == 0)
				continue
			endif

			experiment = traceData[idx][lblTraceExperiment]
			// we want to find the last acquired sweep from the experiment/device combination
			// by just using the path to the numerical labnotebook we can achieve that
			key       = experiment + "_" + traceData[idx][lblTracenumericalValues]
			lastSweep = JSON_GetVariable(jsonID, key, ignoreErr = 1)
			if(IsNaN(lastSweep))
				WAVE numericalValues = $traceData[idx][lblTraceNumericalValues]
				WAVE junkWave        = GetLastSweepWithSetting(numericalValues, "Headstage Active", lastSweep)
				ASSERT(IsValidSweepNumber(lastSweep), "Could not find last sweep")
				JSON_SetVariable(jsonID, key, lastSweep)
			endif

			WAVE  numericalValues   = $traceData[idx][lblTracenumericalValues]
			DFREF singleSweepFolder = GetWavesDataFolderDFR($traceData[idx][lblTraceFullpath])
			ASSERT(DataFolderExistsDFR(singleSweepFolder), "Missing singleSweepFolder")
			WAVE wv = GetDAQDataSingleColumnWave(singleSweepFolder, channelType, channelNumber)

			DFREF singlePulseFolder = GetSingleSweepFolder(pulseAverageDFR, sweepNo)
			totalOnsetDelay = GetTotalOnsetDelay(numericalValues, sweepNo)
			// number of pulses that might be created
			if(numPulseCreate)
				numPulseCreate += totalPulseCounter
				EnsureLargeEnoughWave(properties, indexShouldExist = numPulseCreate, initialValue = NaN)
				EnsureLargeEnoughWave(propertiesWaves, indexShouldExist = numPulseCreate)
			endif

			clampMode             = str2num(traceData[idx][lblClampMode])
			headstage             = str2num(traceData[idx][lblTraceHeadstage])
			prevTotalPulseCounter = totalPulseCounter
			for(k = startingPulseSett; k <= endingPulse; k += 1)

				pulseToPulseLength = PA_GetPulseLength(pulseInfos, k, pa.overridePulseLength, pa.fixedPulseLength)

				first  = round(pulseInfos[k][%PulseStart] / DimDelta(wv, ROWS))
				length = round(pulseToPulseLength / DimDelta(wv, ROWS))

				[WAVE pulseWave, WAVE pulseWaveNote] = PA_CreateAndFillPulseWaveIfReq(wv, singlePulseFolder, channelType, channelNumber, \
				                                                                      clampMode, region, k, first, length, pulseInfos)

				if(!WaveExists(pulseWave))
					continue
				endif

				properties[totalPulseCounter][PA_PROPERTIES_INDEX_SWEEP]         = sweepNo
				properties[totalPulseCounter][PA_PROPERTIES_INDEX_CHANNELNUMBER] = channelNumber
				properties[totalPulseCounter][PA_PROPERTIES_INDEX_REGION]        = region
				properties[totalPulseCounter][PA_PROPERTIES_INDEX_HEADSTAGE]     = headstage
				properties[totalPulseCounter][PA_PROPERTIES_INDEX_PULSE]         = k
				properties[totalPulseCounter][PA_PROPERTIES_INDEX_LASTSWEEP]     = lastSweep
				properties[totalPulseCounter][PA_PROPERTIES_INDEX_CLAMPMODE]     = clampMode

				propertiesWaves[totalPulseCounter][PA_PROPERTIESWAVES_INDEX_PULSE]     = pulseWave
				propertiesWaves[totalPulseCounter][PA_PROPERTIESWAVES_INDEX_PULSENOTE] = pulseWaveNote

				// gather all pulses from one set (used for averaging)
				totalPulseCounter += 1
			endfor

			// Actual number of created pulses
			numPulseCreate = totalPulseCounter - prevTotalPulseCounter
			WAVE setIndizes = GetPulseAverageSetIndizes(pulseAverageHelperDFR, channelNumber, region)
			if(lblIndex < 0)
				lblIndex = FindDimLabel(setIndizes, COLS, "Index")
			endif
			if(numPulseCreate > 0)
				idx = GetNumberFromWaveNote(setIndizes, NOTE_INDEX)
				EnsureLargeEnoughWave(setIndizes, indexShouldExist = idx + numPulseCreate, initialValue = NaN)
				setIndizes[idx, idx + numPulseCreate - 1][lblIndex] = prevTotalPulseCounter + p - idx
				SetNumberInWaveNote(setIndizes, NOTE_INDEX, idx + numPulseCreate)
			endif

			currentDisplayMapping[region][channelNumber][lblACTIVEREGION]  = i + 1
			currentDisplayMapping[region][channelNumber][lblACTIVECHANNEL] = activeChanCount

		endfor
	endfor
	SetNumberInWaveNote(properties, NOTE_INDEX, totalPulseCounter)

	if(incrementalMode)
		sweepList = GetStringFromWaveNote(properties, PA_PROPERTIES_KEY_SWEEPS) + sweepList
		// in traceData the sort order is channelType, channelNumber, Sweep, Headstage. With channelType always AD, we can say that
		// channelsNumbers are always sorted. This allows us to take the shortcut and sort the merged lists here.
		channelList   = SortList(MergeLists(channelList, oldChannelList, sep = PA_PROPERTIES_STRLIST_SEP), PA_PROPERTIES_STRLIST_SEP, 2)
		layoutChanged = CmpStr(oldRegionList, regionList) || CmpStr(oldChannelList, channelList)
		if(layoutChanged)

			FastOp currentDisplayMapping = 0
			WAVE indizesChannelType = indizesChannelTypeAll
			numChannelTypeTraces = DimSize(indizesChannelType, ROWS)
			// the following loop must use the same logic as the upper loop to fill mapRegChanToActive
			for(i = 0; i < numRegions; i += 1)
				region = regions[i]

				activeChanCount   = 0
				regionChannelList = ""
				for(j = 0; j < numChannelTypeTraces; j += 1)
					channelNumberStr = traceData[j][lblTraceChannelNumber]
					if(WhichListItem(channelNumberStr, regionChannelList) == -1)
						activeChanCount  += 1
						regionChannelList = AddListItem(channelNumberStr, regionChannelList, ";", Inf)
					endif

					channelNumber                                                  = str2num(channelNumberStr)
					currentDisplayMapping[region][channelNumber][lblACTIVEREGION]  = i + 1
					currentDisplayMapping[region][channelNumber][lblACTIVECHANNEL] = activeChanCount
				endfor
			endfor
		endif
	else
		layoutChanged = CmpStr(oldRegionList, regionList) || CmpStr(oldChannelList, channelList)
	endif
	ASSERT(ItemsInList(regionList, PA_PROPERTIES_STRLIST_SEP) == ItemsInList(channelList, PA_PROPERTIES_STRLIST_SEP), "An AD or DA channel that was previously used on one headstage was used with a different headstage in a subsequent sweep. This is not supported.")

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

	WAVE indexHelper = pasi.indexHelper
	Multithread indexHelper[][] = PA_SetDiagonalityNote(pasi.setIndices[p][q], layoutChanged ? 0 : pasi.startEntry[p][q], pasi.numEntries[p][q], pasi.propertiesWaves, p == q)

	JSON_Release(jsonID)

	return [pasi]
End

threadsafe static Function PA_SetDiagonalityNote(WAVE indices, variable startIndex, variable numEntries, WAVE/WAVE propertiesWaves, variable isDiagonal)

	if(startIndex < numEntries)
		Duplicate/FREE indices, indexHelper
		indexHelper[startIndex, numEntries - 1] = SetNumberInWaveNote(propertiesWaves[indices[p]][1], NOTE_KEY_PULSE_IS_DIAGONAL, isDiagonal)
	endif
End

/// @brief This function fills a structure with information we need in most further processing functions,
/// e.g. PA DFs, references to properties, setIndice waves, regions, channels, axes, a.s.o.
/// Since not every information might be available at the time this structure is filled there are two steps defined,
/// that are enabled by setting 'part' with PA_PASIINIT_BASE and/or PA_PASIINIT_INDICEMETA.
/// @param pa PulseAverageSettings structure
/// @param part filling step for the returned structure, set depending on available data
/// @param disableIncremental When set then the meta information for incremental updates is just initialized with zero.
static Function [STRUCT PulseAverageSetIndices pasi] PA_InitPASIInParts(STRUCT PulseAverageSettings &pa, variable part, variable disableIncremental)

	variable numActive

	disableIncremental = !!disableIncremental

	if(part & PA_PASIINIT_BASE)
		DFREF pasi.pulseAverageDFR       = GetDevicePulseAverageFolder(pa.dfr)
		DFREF pasi.pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)

		WAVE      pasi.properties      = GetPulseAverageProperties(pasi.pulseAverageHelperDFR)
		WAVE/WAVE pasi.propertiesWaves = GetPulseAveragePropertiesWaves(pasi.pulseAverageHelperDFR)

		WAVE/Z/WAVE setIndices
		WAVE/Z channels, regions, indexHelper
		[setIndices, channels, regions, indexHelper] = PA_GetSetIndicesHelper(pasi.pulseAverageHelperDFR, 0)
		if(!WaveExists(setIndices))
			return [pasi]
		endif

		WAVE pasi.channels    = channels
		WAVE pasi.regions     = regions
		WAVE pasi.indexHelper = indexHelper

		numActive = DimSize(pasi.channels, ROWS)
		Make/FREE/WAVE/N=(numActive, numActive) setWaves2, axesNames, setIndicesUnsorted

		WAVE/WAVE pasi.setIndices = setIndices
		Multithread setIndicesUnsorted[][] = DuplicateWaveToFree(setIndices[p][q])
		WAVE/WAVE pasi.setIndicesUnsorted = setIndicesUnsorted

		setWaves2[][] = PA_GetSetWaves(pasi.pulseAverageHelperDFR, pasi.channels[p], pasi.regions[q])
		WAVE/WAVE pasi.setWaves2Unsorted = setWaves2

		axesNames[][] = PA_GetAxes(pa, pasi.channels[p], pasi.regions[q])
		WAVE/WAVE pasi.axesNames = axesNames

		Make/FREE/D/N=(numActive, numActive) ovlTracesAvg, ovlTracesDeconv, imageAvgDataPresent, imageDeconvDataPresent
		WAVE pasi.ovlTracesAvg           = ovlTracesAvg
		WAVE pasi.ovlTracesDeconv        = ovlTracesDeconv
		WAVE pasi.imageAvgDataPresent    = imageAvgDataPresent
		WAVE pasi.imageDeconvDataPresent = imageDeconvDataPresent
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

/// @brief Retrieve setIndices, channels and regions of the current or the previous layout, as is saved in the properties wave wave note.
/// @param[in] pulseAverageHelperDFR Reference to pulse average helper DF
/// @param[in] prevIndices When set then the indices, channels and regions of the previous layout are returned, otherwise the current layout is returned.
///                        Note that only the layout is considered, the returned indices always contain the current indices for each channel/region at the time of calling this function.
static Function [WAVE/WAVE setIndices, WAVE channels, WAVE regions, WAVE indexHelper] PA_GetSetIndicesHelper(DFREF pulseAverageHelperDFR, variable prevIndices)

	variable numChannels, numRegions
	string keyChannels, keyRegions

	WAVE properties = GetPulseAverageProperties(pulseAverageHelperDFR)
	prevIndices = !!prevIndices

	if(prevIndices)
		keyChannels = PA_PROPERTIES_KEY_PREVCHANNELS
		keyRegions  = PA_PROPERTIES_KEY_PREVREGIONS
	else
		keyChannels = PA_PROPERTIES_KEY_CHANNELS
		keyRegions  = PA_PROPERTIES_KEY_REGIONS
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

/// @brief Updates the setIndices notes with information about the layout and layout changes.
///        Therefore the function compares the previous display mapping and the current display mapping for each region/channel in the layout and
///        determines if the setIndices at this region/channel are added as new/moved/stayed at the same position or were removed.
///        In the setIndices wave note the following keys are set:
///        '$PA_SETINDICES_KEY_DISPCHANGE': change in the layout for this set
///        '$PA_SETINDICES_KEY_ACTIVEREGIONCOUNT': grid location on the vertical where this set is displayed
///        '$PA_SETINDICES_KEY_ACTIVECHANCOUNT': grid location on the horizontal where this set is displayed
///        (this data is currently not used, but created for further PA plot extension)
/// @param[in] currentDisplayMapping 3D wave, rows and columns map the region/channels, in the two layers the associated activeRegion and activeChannel are stored.
///                                  The layer information is the position in the grid of the layout.
/// @param[in] prevDisplayMapping Technically the same wave as currentDisplayMapping, but it stores the information about the previous layout.
/// @param[in] pasi Pulse Average structure storing PA information
/// @param[in] layoutChanged when set then the layout has changed compared to the previous one displayed. This is directly related to a region/channel change.
static Function PA_UpdateIndiceNotes(WAVE currentDisplayMapping, WAVE prevDisplayMapping, STRUCT PulseAverageSetIndices &pasi, variable layoutChanged)

	if(layoutChanged)
		WAVE/Z/WAVE setIndices
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
			FATAL_ERROR("unknown indiceType")
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

	numEntries = GetNumberFromWaveNote(setIndices, NOTE_INDEX)
	if(!numEntries)
		return NaN
	endif

	pulseSortOrder = GetNumberFromWaveNote(setIndices, NOTE_KEY_PULSE_SORT_ORDER)
	if(IsFinite(pulseSortOrder) && pulseSortOrder == pa.pulseSortOrder)
		return NaN
	endif

	Make/FREE/N=(numEntries, 3) elems

	elems[][0] = properties[setIndices[p]][PA_PROPERTIES_INDEX_SWEEP]
	elems[][1] = properties[setIndices[p]][PA_PROPERTIES_INDEX_PULSE]
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
			FATAL_ERROR("Invalid sorting order")
	endswitch

	// copy sorted result back
	setIndices[0, numEntries - 1] = elems[p][2]

	SetNumberInWaveNote(setIndices, NOTE_KEY_PULSE_SORT_ORDER, pa.pulseSortOrder)
End

/// @brief Populates pps.pulseAverSett with the user selection from the panel
static Function PA_GatherSettings(string win, STRUCT PulseAverageSettings &s)

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
	s.failedNumberOfSpikes = GetSetVariable(extPanel, "setvar_pulseAver_numberOfSpikes")
	s.yScaleBarLength      = GetSetVariable(extPanel, "setvar_pulseAver_vert_scale_bar")
	s.showImages           = GetCheckboxState(extPanel, "check_pulseAver_ShowImage")
	s.showTraces           = GetCheckboxState(extPanel, "check_pulseAver_ShowTraces")
	s.imageColorScale      = GetPopupMenuString(extPanel, "popup_pulseAver_colorscales")
	s.drawXZeroLine        = GetCheckboxState(extPanel, "check_pulseAver_timeAlign") && GetCheckboxState(extPanel, "check_pulseAver_drawXZeroLine")
	s.pulseSortOrder       = GetPopupMenuIndex(extPanel, "popup_pulseAver_pulseSortOrder")

	PA_DeconvGatherSettings(win, s.deconvolution)
End

/// @brief gather deconvolution settings from PA section in BSP
static Function PA_DeconvGatherSettings(string win, STRUCT PulseAverageDeconvSettings &deconvolution)

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

#ifndef PA_HIDE_EXECUTION_TIME
	variable execTime_StartLocal, execTime_PreProcess, execTime_ShowPulses, execTime_ShowImage, execTime_Update
	variable execTime_Start = stopmstimer(-2)
	string execTime_outStr
#endif // !PA_HIDE_EXECUTION_TIME

	if(ParamIsDefault(additionalData))
		WAVE/Z additionalData = $""
	endif

	graph = GetMainWindow(win)

	STRUCT PulseAverageSettings old
	jsonIDOld = PA_DeSerializeSettings(graph, old)
	JSON_Release(jsonIDOld, ignoreErr = 1)

	STRUCT PulseAverageSettings current
	PA_GatherSettings(graph, current)
	PA_SerializeSettings(graph, current)

	STRUCT PA_ConstantSettings cs
	[cs] = PA_DetermineConstantSettings(current, old, mode)

#ifndef PA_HIDE_EXECUTION_TIME
	execTime_StartLocal = stopmstimer(-2)
#endif // !PA_HIDE_EXECUTION_TIME
	[pasi, needsPlotting] = PA_PreProcessPulses(win, current, cs, mode, additionalData)
#ifndef PA_HIDE_EXECUTION_TIME
	execTime_PreProcess = stopmstimer(-2) - execTime_StartLocal
#endif // !PA_HIDE_EXECUTION_TIME
	if(!needsPlotting)
		return NaN
	endif

	preExistingGraphs = PA_GetGraphs(win, PA_DISPLAYMODE_ALL)

#ifndef PA_HIDE_EXECUTION_TIME
	execTime_StartLocal = stopmstimer(-2)
#endif // !PA_HIDE_EXECUTION_TIME
	usedTraceGraphs = PA_ShowPulses(graph, current, cs, pasi, mode)
#ifndef PA_HIDE_EXECUTION_TIME
	execTime_ShowPulses = stopmstimer(-2) - execTime_StartLocal
#endif // !PA_HIDE_EXECUTION_TIME

#ifndef PA_HIDE_EXECUTION_TIME
	execTime_StartLocal = stopmstimer(-2)
#endif // !PA_HIDE_EXECUTION_TIME
	usedImageGraphs = PA_ShowImage(graph, current, cs, pasi, mode, additionalData)
#ifndef PA_HIDE_EXECUTION_TIME
	execTime_ShowImage = stopmstimer(-2) - execTime_StartLocal
#endif // !PA_HIDE_EXECUTION_TIME

	KillWindows(RemoveFromList(usedTraceGraphs + usedImageGraphs, preExistingGraphs))

#ifndef PA_HIDE_EXECUTION_TIME
	execTime_Update = stopmstimer(-2) - execTime_Start
	sprintf execTime_outStr, "PA exec time: PA_PreProcessPulses %.3f s.\r", execTime_PreProcess * MICRO_TO_ONE
	DEBUGPRINT(execTime_outStr)
	sprintf execTime_outStr, "PA exec time: PA_ShowPulses %.3f s.\r", execTime_ShowPulses * MICRO_TO_ONE
	DEBUGPRINT(execTime_outStr)
	sprintf execTime_outStr, "PA exec time: PA_ShowImage %.3f s.\r", execTime_ShowImage * MICRO_TO_ONE
	DEBUGPRINT(execTime_outStr)
	sprintf execTime_outStr, "PA exec time: PA_Update %.3f s.\r", execTime_Update * MICRO_TO_ONE
	DEBUGPRINT(execTime_outStr)
#endif // !PA_HIDE_EXECUTION_TIME
End

/// @brief Returns the two column setWave with pulse/pulsenote
static Function/WAVE PA_GetSetWaves(DFREF dfr, variable channelNumber, variable region, [variable removeFailedPulses])

	removeFailedPulses = ParamIsDefault(removeFailedPulses) ? 0 : !!removeFailedPulses

	WAVE setIndizes = GetPulseAverageSetIndizes(dfr, channelNumber, region)

	WAVE      properties      = GetPulseAverageProperties(dfr)
	WAVE/WAVE propertiesWaves = GetPulseAveragePropertiesWaves(dfr)

	return WaveRef(PA_GetSetWaves_TS(properties, propertiesWaves, setIndizes, PA_GETSETWAVES_ALL, removeFailedPulses), row = 0)
End

/// @brief Returns a 1D wave ref wave containing the refs to the setwave2 refs of {all, new, old} sets, depending on the mode constant given in getModes.
///        For mode constants @sa PAGetSetWavesModes, they can be combined by ORing the bits.
///        Each setWave2 component wave entry in the returned wave is a 2D wave ref wave that refrences the pulse data in col 0, and the pulse note in col 1.
///        The rows count the pulses.
threadsafe static Function/WAVE PA_GetSetWaves_TS(WAVE properties, WAVE/WAVE propertiesWaves, WAVE setIndizes, variable getMode, variable removeFailedPulses)

	variable numWaves, i, startIndexNewPulses, index
	variable numNewPulses, numOldPulses, numAllPulses

	numWaves = GetNumberFromWaveNote(setIndizes, NOTE_INDEX)

	if(numWaves == 0)
		return $""
	endif

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
		if((getMode & PA_GETSETWAVES_NEW) && index >= startIndexNewPulses && !(properties[index][PA_PROPERTIES_INDEX_PULSEHASFAILED] == 1 && removeFailedPulses))
			setWavesNew[numNewPulses][0] = propertiesWaves[index][PA_PROPERTIESWAVES_INDEX_PULSE]
			setWavesNew[numNewPulses][1] = propertiesWaves[index][PA_PROPERTIESWAVES_INDEX_PULSENOTE]
			numNewPulses                += 1
		endif
		if((getMode & PA_GETSETWAVES_OLD) && index < startIndexNewPulses && !(properties[index][PA_PROPERTIES_INDEX_PULSEHASFAILED] == 1 && removeFailedPulses))
			setWavesOld[numOldPulses][0] = propertiesWaves[index][PA_PROPERTIESWAVES_INDEX_PULSE]
			setWavesOld[numOldPulses][1] = propertiesWaves[index][PA_PROPERTIESWAVES_INDEX_PULSENOTE]
			numOldPulses                += 1
		endif
		if((getMode & PA_GETSETWAVES_ALL) && !(properties[index][PA_PROPERTIES_INDEX_PULSEHASFAILED] == 1 && removeFailedPulses))
			setWavesAll[numAllPulses][0] = propertiesWaves[index][PA_PROPERTIESWAVES_INDEX_PULSE]
			setWavesAll[numAllPulses][1] = propertiesWaves[index][PA_PROPERTIESWAVES_INDEX_PULSENOTE]
			numAllPulses                += 1
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
	variable region, pulse, jsonID, referencePulseHasFailed
	variable numActive, numEntries, i, j, k, idx, startEntry, entriesToUpdate
	string key

	WAVE properties = pasi.properties
	numTotalPulses = GetNumberFromWaveNote(properties, NOTE_INDEX)
	if(numTotalPulses == 0)
		return NaN
	endif
	WAVE/WAVE propertiesWaves = pasi.propertiesWaves

	// update the wave notes
	Make/FREE/N=(numTotalPulses) indexHelper
	Multithread indexHelper[] = SetNumberInWaveNote(propertiesWaves[p][PA_PROPERTIESWAVES_INDEX_PULSENOTE], NOTE_KEY_SEARCH_FAILED_PULSE, pa.searchFailedPulses)

	if(!pa.searchFailedPulses)
		Multithread properties[][PA_PROPERTIES_INDEX_PULSEHASFAILED] = NaN
		return NaN
	endif

	jsonID = JSON_New()

	numActive = DimSize(pasi.channels, ROWS)

	// mark pulses in the diagonal elements for failed/passed
	// this is done by PA_PulseHasFailed which either uses the wave note
	// or uses FindLevel if required.
	for(i = 0; i < numActive; i += 1)
		region = pasi.regions[i]

		WAVE indices = pasi.setIndicesUnsorted[i][i]
		numEntries = pasi.numEntries[i][i]
		startEntry = pasi.startEntry[i][i]

		// startEntry is the first valid index, numEntries past the last valid index
		entriesToUpdate = numEntries - startEntry

		if(entriesToUpdate > 0)
			Make/FREE/N=(entriesToUpdate) pulseHasFailed
			Multithread pulseHasFailed[] = PA_PulseHasFailed(propertiesWaves[indices[startEntry + p]][PA_PROPERTIESWAVES_INDEX_PULSE],       \
			                                                 propertiesWaves[indices[startEntry + p]][PA_PROPERTIESWAVES_INDEX_PULSENOTE], pa)
		endif

		for(j = startEntry; j < numEntries; j += 1)
			idx = indices[j]

			properties[idx][PA_PROPERTIES_INDEX_PULSEHASFAILED] = pulseHasFailed[j - startEntry]

			sweepNo = properties[idx][PA_PROPERTIES_INDEX_SWEEP]
			pulse   = properties[idx][PA_PROPERTIES_INDEX_PULSE]
			key     = PA_GenerateFailedPulseKey(sweepNo, region, pulse)
			JSON_SetVariable(jsonID, key, properties[idx][PA_PROPERTIES_INDEX_PULSEHASFAILED])
		endfor
	endfor

	for(i = 0; i < numActive; i += 1)
		region = pasi.regions[i]
		for(j = 0; j < numActive; j += 1)
			if(i == j)
				continue
			endif

			WAVE indices = pasi.setIndicesUnsorted[j][i]
			numEntries = pasi.numEntries[j][i]
			startEntry = pasi.startEntry[j][i]
			for(k = startEntry; k < numEntries; k += 1)
				idx     = indices[k]
				sweepNo = properties[idx][PA_PROPERTIES_INDEX_SWEEP]
				pulse   = properties[idx][PA_PROPERTIES_INDEX_PULSE]

				key                     = PA_GenerateFailedPulseKey(sweepNo, region, pulse)
				referencePulseHasFailed = JSON_GetVariable(jsonID, key, ignoreErr = 1)
				// NaN: reference trace could not be found, this happens
				// when a headstage is not displayed (channel selection, OVS HS removal)
				properties[idx][PA_PROPERTIES_INDEX_PULSEHASFAILED] = IsNaN(referencePulseHasFailed) ? 0 : referencePulseHasFailed
			endfor
		endfor
	endfor

	JSON_Release(jsonID)

	// Set current level and number of spikes, need to do that at the end, as
	// PA_PulseHasFailed uses that entry for checking if it needs to rerun
	Multithread indexHelper[] = PA_TagSearchedPulses(pa, propertiesWaves[p][PA_PROPERTIESWAVES_INDEX_PULSENOTE])
End

threadsafe static Function PA_TagSearchedPulses(STRUCT PulseAverageSettings &pa, WAVE wv)

	SetNumberInWaveNote(wv, NOTE_KEY_FAILED_PULSE_LEVEL, pa.failedPulsesLevel)
	SetNumberInWaveNote(wv, NOTE_KEY_NUMBER_OF_SPIKES, pa.failedNumberOfSpikes)
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
			graphData[idx][%TRACES_DECONV]  = ""
			graphData[idx][%IMAGELIST]      = ""
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
	variable firstActiveRegionIndex = NaN
	variable hiddenTracesCount, avgPlotCount, deconPlotCount, plottedAvgTraces
	variable jsonID, hideTraceJsonID, graphDataIndex, numHiddenTracesGraphs, graphHasChanged
	variable startEntry, numEntries, idx, layoutChanged
	variable lblTRACES_AVERAGE, lblTRACES_DECONV
	STRUCT RGBColor s
	string          jsonPath
	string vertAxis, horizAxis
	string baseName, traceName, tagName
	string usedGraphs  = ""
	string resetGraphs = ""

	if(!pa.showTraces)
		return ""
	elseif(cs.traces)
		return PA_GetGraphs(win, PA_DISPLAYMODE_TRACES)
	endif

	WAVE      properties      = pasi.properties
	WAVE/WAVE propertiesWaves = pasi.propertiesWaves

	numActive = DimSize(pasi.channels, ROWS)

	numTotalPulses = GetNumberFromWaveNote(properties, NOTE_INDEX)
	numPlotPulses  = numTotalPulses - GetNumberFromWaveNote(properties, NOTE_PA_NEW_PULSES_START)

	WAVE/T paGraphData = GetPAGraphData()

	lblTRACES_AVERAGE = FindDimLabel(paGraphData, COLS, "TRACES_AVERAGE")
	lblTRACES_DECONV  = FindDimLabel(paGraphData, COLS, "TRACES_DECONV")

	Make/T/FREE/N=(numTotalPulses) hiddenTraces
	Duplicate/FREE/RMD=[][PA_PROPERTIESWAVES_INDEX_PULSE] propertiesWaves, pulseWaves
	jsonID = JSON_Parse("{}")
	if(pa.multipleGraphs)
		hideTraceJsonID = JSON_Parse("{}")
	endif

	if(mode == POST_PLOT_CONSTANT_SWEEPS && cs.failedPulses && cs.multipleGraphs && cs.hideFailedPulses && cs.showIndividualPulses && cs.showTraces && cs.singlePulse)
		usedGraphs = PA_GetGraphs(win, PA_DISPLAYMODE_TRACES)
	else
		for(i = 0; i < numActive; i += 1)
			region = pasi.regions[i]
			if(pa.regionSlider != -1 && pa.regionSlider != region) // unselected region in ddaq viewing mode
				continue
			endif

			if(IsNaN(firstActiveRegionIndex))
				firstActiveRegionIndex = i
			endif

			for(j = 0; j < numActive; j += 1)
				channelNumber = pasi.channels[j]
				// graph change logic
				if((!pa.multipleGraphs && j == 0 && i == firstActiveRegionIndex) || pa.multipleGraphs)
					graph = PA_GetGraph(win, pa, PA_DISPLAYMODE_TRACES, channelNumber, region, i + 1, j + 1, numActive)
				endif
				// build list of used graphs, when not incremental we clear it on first encounter
				if(WhichListItem(graph, usedGraphs) == -1)
					// we want to keep the graphs for ADDED_SWEEPS or we have a change of hideFailedPulses
					if(!(mode == POST_PLOT_ADDED_SWEEPS || (mode == POST_PLOT_CONSTANT_SWEEPS && !cs.hideFailedPulses)))
						RemoveTracesFromGraph(graph)
						RemoveAnnotationsFromGraph(graph)
						graphDataIndex = PA_GetTraceCountFromGraphData(graph, clear = 1)
						resetGraphs    = AddListItem(graph, resetGraphs, ";", Inf)
					endif
					usedGraphs = AddListItem(graph, usedGraphs, ";", Inf)
				endif

				if(!pa.showIndividualPulses)
					continue
				endif

				WAVE/T axesNames = pasi.axesNames[j][i]
				vertAxis  = axesNames[0]
				horizAxis = axesNames[1]

				step = (i == j) ? 1 : PA_PLOT_STEPPING

				WAVE indices = pasi.setIndicesUnsorted[j][i]
				numEntries = pasi.numEntries[j][i]
				startEntry = pasi.startEntry[j][i]
				if(mode == POST_PLOT_CONSTANT_SWEEPS && !cs.hideFailedPulses)
					// Change hidden state only, maybe we can gather failed pulses already in the analysis routine?
					for(k = startEntry; k < numEntries; k += 1)
						idx = indices[k]
						if(properties[idx][PA_PROPERTIES_INDEX_PULSEHASFAILED])
							sprintf pulseTrace, "%s%s", GetTraceNamePrefix(idx), NameOfWave(propertiesWaves[idx][PA_PROPERTIESWAVES_INDEX_PULSE])
							if(pa.multipleGraphs)
								jsonPath = graph + "/hiddenTraces"
								JSON_AddTreeArray(hideTraceJsonID, jsonPath)
								JSON_AddString(hideTraceJsonID, jsonPath, pulseTrace)
							else
								hiddenTraces[hiddenTracesCount] = pulseTrace
								hiddenTracesCount              += 1
							endif
						endif
					endfor
				else

					for(k = startEntry; k < numEntries; k += 1)
						idx            = indices[k]
						pulseHasFailed = properties[idx][PA_PROPERTIES_INDEX_PULSEHASFAILED]
						if(pulseHasFailed)
							hideTrace = pa.hideFailedPulses
							s.red     = 65535
							s.green   = 0
							s.blue    = 0
							alpha     = 65535
						else
							hideTrace = 0
							[s]       = GetTraceColor(properties[idx][PA_PROPERTIES_INDEX_HEADSTAGE])
							alpha     = 65535 * 0.2
						endif

						WAVE plotWave = propertiesWaves[idx][PA_PROPERTIESWAVES_INDEX_PULSE]
						sprintf pulseTrace, "%s%s", GetTraceNamePrefix(idx), NameOfWave(plotWave)

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
								hiddenTracesCount              += 1
							endif
						endif

						sweepNo   = properties[idx][PA_PROPERTIES_INDEX_SWEEP]
						lastSweep = properties[idx][PA_PROPERTIES_INDEX_LASTSWEEP]
						if(pulseHasFailed && (i == j) && (sweepNo == lastSweep))
							sprintf tagName, "tag_%s_AD%d_R%d", vertAxis, channelNumber, region
							if(WhichListItem(tagName, AnnotationList(graph)) == -1)
								xPos = ((i + 1) / numActive) * ONE_TO_PERCENT - 2
								yPos = ((j + 1) / numActive) * ONE_TO_PERCENT - (1 / numActive) * ONE_TO_PERCENT / 2
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
			ACC_HideTraces(hiddenTracesGraphs[j], hiddenTracesNames, DimSize(hiddenTracesNames, ROWS), hideTrace)
		endfor
		JSON_Release(hideTraceJsonID)
	elseif(!IsNull(graph) && !IsEmpty(graph))
		ACC_HideTraces(graph, hiddenTraces, hiddenTracesCount, hideTrace)
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
			vertAxis  = axesNames[0]
			horizAxis = axesNames[1]

			if((!pa.multipleGraphs && i == 0 && j == 0) || pa.multipleGraphs)
				graph          = PA_GetGraph(win, pa, PA_DISPLAYMODE_TRACES, channelNumber, region, i + 1, j + 1, numActive)
				graphDataIndex = PA_GetTraceCountFromGraphData(graph)
				WAVE/T averageTraceNames       = ListToTextWave(paGraphData[graphDataIndex][lblTRACES_AVERAGE], ";")
				WAVE/T deconvolutionTraceNames = ListToTextWave(paGraphData[graphDataIndex][lblTRACES_DECONV], ";")
				graphWasReset = WhichListItem(graph, resetGraphs, ";") != -1
			endif

			[WAVE averageWave, baseName] = GetPAPermanentAverageWave(pasi.pulseAverageDFR, channelNumber, region)

			sprintf traceName, "Ovl_%s%s", PA_AVERAGE_WAVE_PREFIX, baseName

			if(WaveExists(averageTraceNames))
				WAVE/Z/T foundTraces = GrepTextWave(averageTraceNames, "^.*" + PA_AVERAGE_WAVE_PREFIX + basename + "$")
			else
				WAVE/Z/T foundTraces = $""
			endif

			if(!(cs.showAverage && cs.multipleGraphs) || graphWasReset)

				if(WaveExists(foundTraces))
					RemoveFromGraph/W=$graph $foundTraces[0]
					paGraphData[graphDataIndex][lblTRACES_AVERAGE] = RemoveFromList(foundTraces[0], paGraphData[graphDataIndex][lblTRACES_AVERAGE], ";")
					pasi.ovlTracesAvg[j][i]                        = 0
				endif

				if(pa.showAverage && WaveExists(averageWave))

					[s] = GetTraceColorForAverage()
					AppendToGraph/Q/W=$graph/L=$vertAxis/B=$horizAxis/C=(s.red, s.green, s.blue) averageWave/TN=$traceName
					pasi.ovlTracesAvg[j][i] = 1
					plottedAvgTraces        = 1

					if(pa.multipleGraphs)
						ModifyGraph/W=$graph lsize($traceName)=PA_AVGERAGE_PLOT_LSIZE
					else
						avgPlotTraces[avgPlotCount] = traceName
						avgPlotCount               += 1
					endif

					paGraphData[graphDataIndex][lblTRACES_AVERAGE] = AddListItem(traceName, paGraphData[graphDataIndex][lblTRACES_AVERAGE], ";", Inf)
				endif
			endif

			if((graphwasReset                   \
			    || layoutChanged                \
			    || !cs.multipleGraphs           \
			    || !cs.deconvolution            \
			    || !cs.failedPulses             \
			    || plottedAvgTraces) && (i != j))

				sprintf traceName, "Ovl_%s%s", PA_DECONVOLUTION_WAVE_PREFIX, baseName

				if(WaveExists(deconvolutionTraceNames))
					WAVE/Z/T foundTraces = GrepTextWave(deconvolutionTraceNames, "^.*" + PA_DECONVOLUTION_WAVE_PREFIX + basename + "$")
				else
					WAVE/Z/T foundTraces = $""
				endif

				if(WaveExists(foundTraces))
					RemoveFromGraph/W=$graph $foundTraces[0]
					paGraphData[graphDataIndex][lblTRACES_DECONV] = RemoveFromList(foundTraces[0], paGraphData[graphDataIndex][lblTRACES_DECONV], ";")
					pasi.ovlTracesDeconv[j][i]                    = 0
				endif

				if(pa.deconvolution.enable && WaveExists(averageWave))
					WAVE deconv = PA_Deconvolution(averageWave, pasi.pulseAverageDFR, PA_DECONVOLUTION_WAVE_PREFIX + baseName, pa.deconvolution)
					AppendToGraph/Q/W=$graph/L=$vertAxis/B=$horizAxis/C=(0, 0, 0) deconv[0, Inf; PA_PLOT_STEPPING]/TN=$traceName
					pasi.ovlTracesDeconv[j][i] = 1

					if(pa.multipleGraphs)
						ModifyGraph/W=$graph lsize($traceName)=PA_DECONVOLUTION_PLOT_LSIZE
					else
						deconPlotTraces[deconPlotCount] = traceName
						deconPlotCount                 += 1
					endif

					paGraphData[graphDataIndex][lblTRACES_DECONV] = AddListItem(traceName, paGraphData[graphDataIndex][lblTRACES_DECONV], ";", Inf)
				endif
			endif

		endfor
	endfor
	if(!pa.multipleGraphs)
		ACC_ModLineSizeTraces(graph, avgPlotTraces, avgPlotCount, PA_AVGERAGE_PLOT_LSIZE)
		ACC_ModLineSizeTraces(graph, deconPlotTraces, deconPlotCount, PA_DECONVOLUTION_PLOT_LSIZE)
	endif

	PA_LayoutGraphs(win, pa, pasi, PA_DISPLAYMODE_TRACES)
	PA_DrawScaleBars(win, pa, pasi, PA_DISPLAYMODE_TRACES, PA_USE_WAVE_SCALES, resetToUserLength = 1)
	PA_DrawXZeroLines(win, pa, pasi, PA_DISPLAYMODE_TRACES)

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
		RemoveImage/ALL/W=$graph
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
		cs.singlePulse          = 0
		cs.traces               = 0
		cs.images               = 0
		cs.dontResetWaves       = 0
		cs.failedPulses         = 0
		cs.multipleGraphs       = 0
		cs.showAverage          = 0
		cs.deconvolution        = 0
		cs.hideFailedPulses     = 0
		cs.showIndividualPulses = 0
		cs.showTraces           = 0
		return [cs]
	endif

	cs.singlePulse = (pa.startingPulse == paOld.startingPulse                \
	                  && pa.endingPulse == paOld.endingPulse                 \
	                  && pa.overridePulseLength == paOld.overridePulseLength \
	                  && pa.fixedPulseLength == paOld.fixedPulseLength)

	cs.failedPulses = (pa.searchFailedPulses == paOld.searchFailedPulses                           \
	                   && pa.failedPulsesLevel == paOld.failedPulsesLevel                          \
	                   && EqualValuesOrBothNaN(pa.failedNumberOfSpikes, paOld.failedNumberOfSpikes))

	cs.deconvolution = (pa.deconvolution.enable == paOld.deconvolution.enable \
	                    && pa.deconvolution.smth == paOld.deconvolution.smth  \
	                    && pa.deconvolution.tau == paOld.deconvolution.tau    \
	                    && pa.deconvolution.range == paOld.deconvolution.range)

	generalSettings = (pa.showIndividualPulses == paOld.showIndividualPulses \
	                   && pa.drawXZeroLine == paOld.drawXZeroLine            \
	                   && pa.showAverage == paOld.showAverage                \
	                   && pa.regionSlider == paOld.regionSlider              \
	                   && pa.multipleGraphs == paOld.multipleGraphs          \
	                   && pa.zeroPulses == paOld.zeroPulses                  \
	                   && pa.autoTimeAlignment == paOld.autoTimeAlignment    \
	                   && pa.enabled == paOld.enabled                        \
	                   && pa.hideFailedPulses == paOld.hideFailedPulses      \
	                   && cs.failedPulses == 1                               \
	                   && cs.deconvolution == 1)

	cs.traces = (generalSettings == 1                          \
	             && cs.singlePulse == 1                        \
	             && pa.showTraces == paOld.showTraces          \
	             && pa.yScaleBarLength == paOld.yScaleBarLength)

	cs.images = (generalSettings == 1                        \
	             && cs.singlePulse == 1                      \
	             && pa.showImages == paOld.showImages        \
	             && pa.pulseSortOrder == paOld.pulseSortOrder)

	cs.dontResetWaves = (pa.zeroPulses == paOld.zeroPulses                  \
	                     && pa.autoTimeAlignment == paOld.autoTimeAlignment \
	                     && cs.failedPulses == 1)

	cs.multipleGraphs = pa.multipleGraphs == paOld.multipleGraphs

	cs.showAverage = pa.showAverage == paOld.showAverage

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

#ifndef PA_HIDE_EXECUTION_TIME
	variable execTime_startLocal, execTime_GenerateAllPulseWaves, execTime_ApplyPulseSortingOrder, execTime_ResetWavesIfRequired
	variable execTime_MarkFailedPulses, execTime_ZeroPulses, execTime_AutomaticTimeAlignment, execTime_CalculateAllAverages
	string execTime_outStr
#endif // !PA_HIDE_EXECUTION_TIME

	preExistingGraphs = PA_GetGraphs(win, PA_DISPLAYMODE_ALL)
	graph             = GetMainWindow(win)

	if(!pa.enabled)
		KillWindows(preExistingGraphs)
		if(DataFolderExistsDFR(pa.dfr))
			DFREF pulseAverageHelperDFR = GetDevicePulseAverageHelperFolder(pa.dfr)
			KillOrMoveToTrash(dfr = pulseAverageHelperDFR)
		endif
		return [pasi, 0]
	endif

	if(mode == POST_PLOT_CONSTANT_SWEEPS && cs.singlePulse)
		[pasi] = PA_InitPASIInParts(pa, PA_PASIINIT_BASE | PA_PASIINIT_INDICEMETA, 1)
	else

#ifndef PA_HIDE_EXECUTION_TIME
		execTime_StartLocal = stopmstimer(-2)
#endif // !PA_HIDE_EXECUTION_TIME
		[pasi] = PA_GenerateAllPulseWaves(win, pa, mode, additionalData)
#ifndef PA_HIDE_EXECUTION_TIME
		execTime_GenerateAllPulseWaves = stopmstimer(-2) - execTime_StartLocal
#endif // !PA_HIDE_EXECUTION_TIME
	endif

	if(!WaveExists(pasi.setIndices))
		PA_ClearGraphs(preExistingGraphs)
		return [pasi, 0]
	endif

	if(!(mode == POST_PLOT_CONSTANT_SWEEPS && cs.images))
#ifndef PA_HIDE_EXECUTION_TIME
		execTime_StartLocal = stopmstimer(-2)
#endif // !PA_HIDE_EXECUTION_TIME
		// if CONSTANT_SWEEPS and not changed or no image shown, no need to call
		WAVE indexHelper = pasi.indexHelper
		Multithread indexHelper[][] = PA_ApplyPulseSortingOrder(pasi.setIndices[p][q], pasi.channels[p], pasi.regions[q], pasi.properties, pa)
#ifndef PA_HIDE_EXECUTION_TIME
		execTime_ApplyPulseSortingOrder = stopmstimer(-2) - execTime_StartLocal
#endif // !PA_HIDE_EXECUTION_TIME
	endif

	if(!(mode == POST_PLOT_CONSTANT_SWEEPS && cs.dontResetWaves) || (!cs.singlePulse && pa.searchFailedPulses))
#ifndef PA_HIDE_EXECUTION_TIME
		execTime_StartLocal = stopmstimer(-2)
#endif // !PA_HIDE_EXECUTION_TIME
		pasi.indexHelper[][] = PA_ResetWavesIfRequired(pasi.setWaves2Unsorted[p][q], pa, mode)
#ifndef PA_HIDE_EXECUTION_TIME
		execTime_ResetWavesIfRequired = stopmstimer(-2) - execTime_StartLocal
#endif // !PA_HIDE_EXECUTION_TIME
	endif

	if(!(mode == POST_PLOT_CONSTANT_SWEEPS && cs.failedPulses) || (!cs.singlePulse && pa.searchFailedPulses))
#ifndef PA_HIDE_EXECUTION_TIME
		execTime_StartLocal = stopmstimer(-2)
#endif // !PA_HIDE_EXECUTION_TIME
		PA_MarkFailedPulses(pa, pasi)
#ifndef PA_HIDE_EXECUTION_TIME
		execTime_MarkFailedPulses = stopmstimer(-2) - execTime_StartLocal
#endif // !PA_HIDE_EXECUTION_TIME
	endif

	// cs.dontResetWaves contains that zeroPulse setting did not change
	if(!(mode == POST_PLOT_CONSTANT_SWEEPS && cs.dontResetWaves && cs.singlePulse) && pa.zeroPulses)
#ifndef PA_HIDE_EXECUTION_TIME
		execTime_StartLocal = stopmstimer(-2)
#endif // !PA_HIDE_EXECUTION_TIME
		pasi.indexHelper[][] = PA_ZeroPulses(pasi.setWaves2Unsorted[p][q])
#ifndef PA_HIDE_EXECUTION_TIME
		execTime_ZeroPulses = stopmstimer(-2) - execTime_StartLocal
#endif // !PA_HIDE_EXECUTION_TIME
	endif

	// cs.dontResetWaves contains that autoTimeAlignment setting did not change
	if(!(mode == POST_PLOT_CONSTANT_SWEEPS && cs.dontResetWaves && cs.singlePulse) && pa.autoTimeAlignment)
#ifndef PA_HIDE_EXECUTION_TIME
		execTime_StartLocal = stopmstimer(-2)
#endif // !PA_HIDE_EXECUTION_TIME
		PA_AutomaticTimeAlignment(pasi)
#ifndef PA_HIDE_EXECUTION_TIME
		execTime_AutomaticTimeAlignment = stopmstimer(-2) - execTime_StartLocal
#endif // !PA_HIDE_EXECUTION_TIME
	endif

	if(!(mode == POST_PLOT_CONSTANT_SWEEPS && cs.dontResetWaves && cs.failedPulses && cs.singlePulse))
#ifndef PA_HIDE_EXECUTION_TIME
		execTime_StartLocal = stopmstimer(-2)
#endif // !PA_HIDE_EXECUTION_TIME
		PA_CalculateAllAverages(pa, pasi, mode)
#ifndef PA_HIDE_EXECUTION_TIME
		execTime_CalculateAllAverages = stopmstimer(-2) - execTime_StartLocal
#endif // !PA_HIDE_EXECUTION_TIME
	endif

#ifndef PA_HIDE_EXECUTION_TIME
	sprintf execTime_outStr, "PA exec time: PA_GenerateAllPulseWaves %.3f s.\r", execTime_GenerateAllPulseWaves * MICRO_TO_ONE
	DEBUGPRINT(execTime_outStr)
	sprintf execTime_outStr, "PA exec time: PA_ApplyPulseSortingOrder %.3f s.\r", execTime_ApplyPulseSortingOrder * MICRO_TO_ONE
	DEBUGPRINT(execTime_outStr)
	sprintf execTime_outStr, "PA exec time: PA_ResetWavesIfRequired %.3f s.\r", execTime_ResetWavesIfRequired * MICRO_TO_ONE
	DEBUGPRINT(execTime_outStr)
	sprintf execTime_outStr, "PA exec time: PA_MarkFailedPulses %.3f s.\r", execTime_MarkFailedPulses * MICRO_TO_ONE
	DEBUGPRINT(execTime_outStr)
	sprintf execTime_outStr, "PA exec time: PA_ZeroPulses %.3f s.\r", execTime_ZeroPulses * MICRO_TO_ONE
	DEBUGPRINT(execTime_outStr)
	sprintf execTime_outStr, "PA exec time: PA_AutomaticTimeAlignment %.3f s.\r", execTime_AutomaticTimeAlignment * MICRO_TO_ONE
	DEBUGPRINT(execTime_outStr)
	sprintf execTime_outStr, "PA exec time: PA_CalculateAllAverages %.3f s.\r", execTime_CalculateAllAverages * MICRO_TO_ONE
	DEBUGPRINT(execTime_outStr)
#endif // !PA_HIDE_EXECUTION_TIME

	return [pasi, 1]
End

static Function PA_CalculateAllAverages(STRUCT PulseAverageSettings &pa, STRUCT PulseAverageSetIndices &pasi, variable mode)

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
	WAVE/Z/WAVE cache = CA_TryFetchingEntryFromCache(keyAll, options = CA_OPTS_NO_DUPLICATE)
	if(!WaveExists(cache))
		DEBUGPRINT("Cache miss all data:", str = keyAll)
		// we have to calculate
		if(mode == POST_PLOT_ADDED_SWEEPS)
			Multithread/NT=(numThreads) setWavesOld[][] = PA_ExtractPulseSetFromSetWaves2(WaveRef(setWaves2AllNewOld[p][q], row = 2))
			keyOld = CA_AveragingWaveModKey(setWavesOld)
			WAVE/Z/WAVE cache = CA_TryFetchingEntryFromCache(keyOld, options = CA_OPTS_NO_DUPLICATE)
			if(WaveExists(cache))
				DEBUGPRINT("Cache hit old data (for incremental):", str = keyOld)
				Multithread/NT=(numThreads) setWavesNew[][] = PA_ExtractPulseSetFromSetWaves2(WaveRef(setWaves2AllNewOld[p][q], row = 1))
				Multithread/NT=(numThreads) avg[][] = MIES_fWaveAverage(setWavesNew[p][q], 0, IGOR_TYPE_32BIT_FLOAT, getComponents = 1, prevAvgData = PA_ExtractSumsCountsOnly(cache[p][q]))
			else
				DEBUGPRINT("Cache miss old data (for incremental):", str = keyOld)
				Multithread/NT=(numThreads) avg[][] = MIES_fWaveAverage(setWavesAll[p][q], 0, IGOR_TYPE_32BIT_FLOAT, getComponents = 1)
			endif
		else
			Multithread/NT=(numThreads) avg[][] = MIES_fWaveAverage(setWavesAll[p][q], 0, IGOR_TYPE_32BIT_FLOAT, getComponents = 1)
		endif

		if(pa.autoTimeAlignment)
			Multithread indexHelper[][] = PA_TAAdaptAverageWave(WaveRef(avg[p][q], row = 0), setWavesAll[p][q])
		endif

		Multithread indexHelper[][] = PA_StoreMaxAndUnitsInWaveNote(WaveRef(avg[p][q], row = 0), WaveRef(setWavesAll[p][q], row = 0))
		CA_StoreEntryIntoCache(keyAll, avg, options = CA_OPTS_NO_DUPLICATE)
	else
		DEBUGPRINT("Cache hit all data:", str = keyAll)
		WAVE/WAVE avg = cache
	endif

	indexHelper[][] = PA_MakeAverageWavePermanent(pasi.pulseAverageDFR, WaveRef(avg[p][q], row = 0), pasi.channels[p], pasi.regions[q])
End

threadsafe static Function PA_TAAdaptAverageWave(WAVE/Z avg, WAVE/WAVE set)

	variable numPulses, l, r
	variable dOffset, dDelta

	if(!WaveExists(avg))
		return NaN
	endif

	numPulses = DimSize(set, ROWS)
	if(numPulses == 0)
		return NaN
	endif

	Make/FREE/N=(numPulses) left, right
	left[]  = leftx(set[p])
	right[] = rightx(set[p])
	// since ScaleToIndexWrapper uses round(...) we can not use it here
	dOffset = DimOffset(avg, ROWS)
	dDelta  = DimDelta(avg, ROWS)
	l       = (WaveMax(left) - dOffset) / dDelta
	l       = IsInteger(l) ? l : (trunc(l) + 1)
	r       = (WaveMin(right) - dOffset) / dDelta
	r       = IsInteger(r) ? r : trunc(r)
	if(l >= r)
		avg[] = NaN
	else
		if(l > 0)
			avg[0, l] = NaN
		endif
		if(r < DimSize(avg, ROWS))
			avg[r, Inf] = NaN
		endif
	endif
End

static Function PA_MakeAverageWavePermanent(DFREF dfr, WAVE/Z avg, variable channel, variable region)

	string baseName

	if(WaveExists(avg))
		ConvertFreeWaveToPermanent(avg, dfr, PA_AVERAGE_WAVE_PREFIX + PA_BaseName(channel, region))
	else
		// no data, we remove permanent wave
		[avg, baseName] = GetPAPermanentAverageWave(dfr, channel, region)
		KillOrMoveToTrash(wv = avg)
	endif
End

threadsafe static Function/WAVE PA_ExtractPulseSetFromSetWaves2(WAVE/Z/WAVE setWave2)

	if(!WaveExists(setWave2))
		return $""
	endif

	// Maybe SplitWave is faster
	Duplicate/FREE/RMD=[][0] setWave2, setWave
	Redimension/N=(-1) setWave
	return setWave
End

/// @brief Stores the WaveMaximum in the wave note of the given wave and sets the wave unit to the same as from unitSource
/// @param[in] w Wave where the maximum is determined and written to the wave note, the wave unit determiend from unitSource is also set for w
/// @param[in] unitSource a source wave for wave unit information for w
threadsafe static Function PA_StoreMaxAndUnitsInWaveNote(WAVE/Z w, WAVE/Z unitSource)

	if(!WaveExists(w))
		return 1
	endif

	if(!WaveExists(unitSource))
		FATAL_ERROR("Attempt to set data units in existing wave, but data unit source wave is null.")
	endif

	SetScale d, 0, 0, WaveUnits(unitSource, -1), w
	SetNumberInWaveNote(w, NOTE_KEY_WAVE_MAXIMUM, WaveMax(w), format = PERCENT_F_MAX_PREC)
	return 0
End

threadsafe static Function/WAVE PA_ExtractSumsCountsOnly(WAVE/WAVE w)

	Make/FREE/WAVE result = {w[1], w[2]}
	return result
End

/// @brief Update the scale bars of the passed plot
///
/// @param win               PA trace or image plot
/// @param resetToUserLength Reset the scale bars to the user upplied values
///
/// This functions is non-statc as it is called from the operation queue.  This
/// is necessary as the window hooks listen to the mouse wheel event, and we
/// want to update only after the mouse wheel triggered the axis range change.
/// And that is only possible with the operation queue.
Function PA_UpdateScaleBars(string win, variable resetToUserLength)

	variable                      displayMode
	string                        bsPanel
	STRUCT PulseAverageSetIndices pasi

	if(!WindowExists(win))
		DEBUGPRINT("Warning: Window from parameter does not exist.")
		return NaN
	endif

	bsPanel = GetUserData(win, "", MIES_BSP_PA_MAINPANEL)

	displayMode = (ItemsInList(ImageNameList(win, ";")) > 0) ? PA_DISPLAYMODE_IMAGES : PA_DISPLAYMODE_TRACES

	STRUCT PulseAverageSettings pa
	PA_GatherSettings(bsPanel, pa)
	[pasi] = PA_InitPASIInParts(pa, PA_PASIINIT_BASE | PA_PASIINIT_INDICEMETA, 1)
	PA_DrawScaleBars(bsPanel, pa, pasi, displayMode, PA_USE_AXIS_SCALES, resetToUserLength = resetToUserLength)
End

static Function PA_DrawScaleBars(string win, STRUCT PulseAverageSettings &pa, STRUCT PulseAverageSetIndices &pasi, variable displayMode, variable axisMode, [variable resetToUserLength])

	variable i, j, numActive, region, channelNumber, drawXScaleBarOverride
	variable firstActiveRegionIndex = NaN
	variable maximum, length, drawYScaleBarOverride
	string graph, vertAxis, horizAxis, xUnit, yUnit, baseName

	if(ParamIsDefault(resetToUserLength))
		resetToUserLength = 0
	else
		resetToUserLength = !!resetToUserLength
	endif

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

			if(!PA_IsDataOnSubPlot(pa, pasi, j, i, displayMode))
				continue
			endif

			if(IsNaN(firstActiveRegionIndex))
				firstActiveRegionIndex = j
			endif

			graph = PA_GetGraph(win, pa, displayMode, channelNumber, region, j + 1, i + 1, numActive)

			WAVE/T axesNames = pasi.axesNames[i][j]
			vertAxis  = axesNames[0]
			horizAxis = axesNames[1]

			if((!pa.multipleGraphs && i == 0 && j == firstActiveRegionIndex) || pa.multipleGraphs)
				SetDrawLayer/K/W=$graph $PA_DRAWLAYER_SCALEBAR
			endif

			[WAVE averageWave, baseName] = GetPAPermanentAverageWave(pasi.pulseAverageDFR, channelNumber, region)
			if(WaveExists(averageWave))
				maximum = GetNumberFromWaveNote(averageWave, NOTE_KEY_WAVE_MAXIMUM)
				length  = pa.yScaleBarLength * (IsFinite(maximum) ? sign(maximum) : +1)
				xUnit   = WaveUnits(averageWave, ROWS)
				yUnit   = WaveUnits(averageWave, -1)
			else
				length = pa.yScaleBarLength
				xUnit  = "n. a."
				yUnit  = "n. a."
			endif

			PA_DrawScaleBarsHelper(graph, axisMode, displayMode, pasi.setWaves2Unsorted[i][j],                          \
			                       vertAxis, horizAxis, length, xUnit, yUnit, i + 1, j + 1, numActive, resetToUserLength)
		endfor
	endfor
End

static Function [variable vert_min, variable vert_max, variable horiz_min, variable horiz_max] PA_GetMinAndMax(WAVE/WAVE setWaves2)

	variable numPulses = DimSize(setWaves2, ROWS)

	Make/D/FREE/N=(numPulses) vertDataMin = GetNumberFromWaveNote(setWaves2[p][1], NOTE_KEY_WAVE_MINIMUM)
	Make/D/FREE/N=(numPulses) vertDataMax = GetNumberFromWaveNote(setWaves2[p][1], NOTE_KEY_WAVE_MAXIMUM)

	Make/D/FREE/N=(numPulses) horizDataMin = leftx(setWaves2[p][0])
	Make/D/FREE/N=(numPulses) horizDataMax = pnt2x(setWaves2[p][0], DimSize(setWaves2[p][0], ROWS) - 1)

	return [WaveMin(vertDataMin), WaveMax(vertDataMax), WaveMin(horizDataMin), WaveMax(horizDataMax)]
End

/// @brief Determine if we need a scale bar label
///
/// Without any optional parameters we always need a label if we have a stored entry
/// `userDataName` and that differs from `physicalLength`.
///
/// With the optional parameters we prioritize `userLength` if it has changed compared to the
/// stored value `userLengthName` or if it needs resetting on a new plot. Otherwise we use the same approach as above.
static Function [variable forceScaleBar, variable physicalLengthCorr] PA_NeedsForcedScaleBar(string win, string userDataName, variable physicalLength, variable axisMinimum, variable axisMaximum, [variable userLength, string userLengthName, variable resetToUserLength])

	variable originalBarLength, userLengthStored
	string msg

	originalBarLength = str2num(GetUserData(win, "", userDataName))

	if(!ParamIsDefault(userLength) && !ParamIsDefault(userLengthName) && !ParamIsDefault(resetToUserLength))
		userLengthStored = str2num(GetUserData(win, "", userLengthName))

		// - first run
		// - new user length
		// - complete reset, mostly due to Strg+A
		if(IsNaN(userLengthStored)                        \
		   || !CheckIfClose(userLengthStored, userLength) \
		   || resetToUserLength)
			SetWindow $win, userdata($userLengthName)=num2str(userLength)
			SetWindow $win, userdata($userDataName)=num2str(physicalLength)
			return [0, userLength]
		endif

		sprintf msg, "%s, min_axis %d, max_axis %d, physicalLength %g, userLength %g\r", userDataName, axisMinimum, axisMaximum, physicalLength, userLength
		DEBUGPRINT(msg)

		if(CheckIfClose(originalBarLength, physicalLength))
			return [0, userLength]
		endif
	else
		userLength = NaN
	endif

	if(IsNaN(originalBarLength))
		SetWindow $win, userdata($userDataName)=num2str(physicalLength)
	endif

	forceScaleBar      = !CheckIfClose(originalBarLength, physicalLength) && !CheckIfClose(userLength, physicalLength) && !IsNaN(originalBarLength)
	physicalLengthCorr = physicalLength
End

static Function PA_DrawScaleBarsHelper(string win, variable axisMode, variable displayMode, WAVE/WAVE setWaves2, string vertAxis, string horizAxis, variable ylength, string xUnit, string yUnit, variable activeChanCount, variable activeRegionCount, variable numActive, variable resetToUserLength)

	string graph, msg, str, name, userLengthName
	variable vertAxis_y, vertAxis_x, xLength
	variable vert_min, vert_max, horiz_min, horiz_max, drawLength
	variable xBarBottom, xBarTop, yBarBottom, yBarTop, labelOffset
	variable xBarLeft, xBarRight, yBarLeft, yBarRight, drawXScaleBar, drawYScaleBar
	variable userLength, forceScaleBar

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
					vert_min                                   = -0.5
					vert_max                                   = NaN
					break
				default:
					FATAL_ERROR("Invalid display mode")
			endswitch
			break
		case PA_USE_AXIS_SCALES:
			[vert_min, vert_max]   = GetAxisRange(graph, vertAxis, mode = AXIS_RANGE_INC_AUTOSCALED)
			[horiz_min, horiz_max] = GetAxisRange(graph, horizAxis, mode = AXIS_RANGE_INC_AUTOSCALED)
			break
		default:
			FATAL_ERROR("Unknown mode")
	endswitch

	SetDrawEnv/W=$graph push
	SetDrawEnv/W=$graph linefgc=(0, 0, 0), textrgb=(0, 0, 0), fsize=10, linethick=1.5

	sprintf msg, "win %s, horizAxis %s [%g, %g], vertAxis %s [%g, %g]\r", win, horizAxis, horiz_min, horiz_max, vertAxis, vert_min, vert_max
	DEBUGPRINT(msg)

	if(drawYScaleBar)
		// only for non-diagonal elements

		// Y scale

		SetDrawEnv/W=$graph xcoord=prel, ycoord=$vertAxis
		SetDrawEnv/W=$graph save

		labelOffset = 0.005

		sprintf str, "scalebar_Y_R%d_C%d", activeRegionCount, activeChanCount
		SetDrawEnv/W=$graph gstart, gname=$str

		userLength = ylength
		yLength    = sign(userLength) * CalculateNiceLength(0.10 * abs(vert_max - vert_min), abs(userLength))

		name                     = PA_USER_DATA_CALC_YLENGTH + "_" + vertAxis
		userLengthName           = PA_USER_DATA_USER_YLENGTH + "_" + vertAxis
		[forceScaleBar, yLength] = PA_NeedsForcedScaleBar(win, name, ylength, vert_min, vert_max, userLength = userLength, userLengthName = userLengthName, resetToUserLength = resetToUserLength)

		xBarBottom = str2num(GetUserData(win, "", PA_USER_DATA_X_START_RELATIVE_PREFIX + horizAxis))
		xBarTop    = xBarBottom

		if(sign(vert_min) != sign(vert_max))
			yBarBottom = 0
		else
			// zero is not in range, use vert_min
			yBarBottom = vert_min
		endif

		yBarTop = yBarBottom + ylength

		sprintf msg, "Y: (R%d, C%d), xBarBottom %g, xBarTop %g\r", activeRegionCount, activeChanCount, xBarBottom, xBarTop
		DEBUGPRINT(msg)

		drawLength = forceScaleBar || ((activeChanCount == numActive) && (activeRegionCount == 1))

		DrawScaleBar(graph, xBarBottom, yBarBottom, xBarTop, yBarTop, unit = yUnit, drawLength = drawLength, labelOffset = labelOffset, newlineBeforeUnit = 1)

		SetDrawEnv/W=$graph gstop
	endif

	if(drawXScaleBar)

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

		name                     = PA_USER_DATA_CALC_XLENGTH + "_" + horizAxis
		[forceScaleBar, xLength] = PA_NeedsForcedScaleBar(win, name, xlength, horiz_min, horiz_max)

		drawLength = forceScaleBar || ((activeChanCount == numActive) && (activeRegionCount == numActive))

		DrawScaleBar(graph, xBarLeft, yBarLeft, xBarRight, yBarRight, unit = xUnit, drawLength = drawLength)

		SetDrawEnv/W=$graph gstop
	endif

	SetDrawEnv/W=$graph pop
End

/// @brief Calculate the number of spikes in the given wave for IC and I=0 data
threadsafe Function/WAVE PA_SpikePositionsForNonVC(WAVE wv, variable failedPulsesLevel)

	variable numLevels, maxNumLevels, numSpikes
	variable first, last, i, idx

	// allow at most 1 pulse per ms, but at least 1
	maxNumLevels = max(1, round(DimSize(wv, ROWS) * DimDelta(wv, ROWS)) * 2)
	WAVE/Z levels = FindLevelWrapper(wv, failedPulsesLevel, FINDLEVEL_EDGE_BOTH, FINDLEVEL_MODE_MULTI, \
	                                 maxNumLevels = maxNumLevels)

	ASSERT_TS(WaveExists(levels), "FindLevelWrapper returned a non-existing wave")
	ASSERT_TS(DimSize(levels, ROWS) == 1, "Unexpected number of rows")

	numLevels = str2num(GetDimLabel(levels, ROWS, 0))
	ASSERT_TS(IsFinite(numLevels), "Number of levels is not finite")

	if(IsOdd(numLevels))
		// throw away the last level
		Redimension/N=(1, --numLevels) levels
	endif

	numSpikes = numLevels / 2
	ASSERT_TS(IsInteger(numSpikes), "Expected an integer number of peaks")

	Make/D/FREE/N=(numSpikes) spikePositions

	// now we use FindPeak between two consecutive edges (rising and falling) in a loop
	for(i = 0; i < numSpikes; i += 1)
		first = levels[i * 2]
		last  = levels[i * 2 + 1]

		if((last - first) < PA_MINIMUM_SPIKE_WIDTH)
			continue
		endif

		FindPeak/B=(PA_PEAK_BOX_AVERAGE)/M=(failedPulsesLevel)/R=(first, last)/Q wv

		if(!V_Flag)
			spikePositions[idx++] = V_PeakLoc
		endif
	endfor

	numSpikes = idx
	Redimension/N=(numSpikes) spikePositions

	return spikePositions
End

threadsafe static Function PA_PulseHasFailed(WAVE pulseWave, WAVE noteWave, STRUCT PulseAverageSettings &s)

	variable level, hasFailed, numSpikes, failedNumberOfSpikes, clampMode

	if(!s.searchFailedPulses)
		return 0
	endif

	level                = GetNumberFromWaveNote(noteWave, NOTE_KEY_FAILED_PULSE_LEVEL)
	failedNumberOfSpikes = GetNumberFromWaveNote(noteWave, NOTE_KEY_NUMBER_OF_SPIKES)

	hasFailed = GetNumberFromWaveNote(noteWave, NOTE_KEY_PULSE_HAS_FAILED)

	if(level == s.failedPulsesLevel && EqualValuesOrBothNaN(failedNumberOfSpikes, s.failedNumberOfSpikes) && IsFinite(hasFailed))
		// already investigated
		return hasFailed
	endif

	ASSERT_TS(GetNumberFromWaveNote(noteWave, NOTE_KEY_ZEROED) != 1, "Single pulse wave must not be zeroed here")

	clampMode = GetNumberFromWaveNote(noteWave, NOTE_KEY_CLAMP_MODE)

	switch(clampMode)
		case V_CLAMP_MODE: // fallthrough
		case I_EQUAL_ZERO_MODE:
			numSpikes = 0
			Make/D/FREE/N=(numSpikes) spikePositions

			hasFailed = 0 // always passes
			break
		case I_CLAMP_MODE:
			WAVE spikePositions = PA_SpikePositionsForNonVC(pulseWave, s.failedPulsesLevel)
			numSpikes = DimSize(spikePositions, ROWS)

			hasFailed = !((numSpikes == s.failedNumberOfSpikes) || (numSpikes > 0 && IsNaN(s.failedNumberOfSpikes)))
			break
		default:
			FATAL_ERROR("Invalid clamp mode:" + num2str(clampMode))
	endswitch

	SetStringInWaveNote(noteWave, NOTE_KEY_PULSE_SPIKE_POSITIONS, NumericWaveToList(spikePositions, ","))
	SetNumberInWaveNote(noteWave, NOTE_KEY_PULSE_FOUND_SPIKES, numSpikes)
	SetNumberInWaveNote(noteWave, NOTE_KEY_PULSE_HAS_FAILED, hasFailed)

	// NOTE_KEY_FAILED_PULSE_LEVEL and NOTE_KEY_NUMBER_OF_SPIKES is written in PA_MarkFailedPulses for all pulses

	return hasFailed
End

/// @brief Generate the wave name for a single pulse
Function/S PA_GeneratePulseWaveName(variable channelType, variable channelNumber, variable region, variable pulseIndex)

	ASSERT(channelType < ItemsInList(XOP_CHANNEL_NAMES), "Invalid channel type")
	ASSERT(channelNumber < GetNumberFromType(xopVar = channelType), "Invalid channel number")
	ASSERT(IsInteger(pulseIndex) && pulseIndex >= 0, "Invalid pulseIndex")

	return StringFromList(channelType, XOP_CHANNEL_NAMES) + num2str(channelNumber) + \
	       "_R" + num2str(region) + "_P" + num2str(pulseIndex)
End

/// @brief Generate a static base name for objects in the current averaging folder
Function/S PA_BaseName(variable channelNumber, variable headStage)

	string baseName
	baseName  = "AD" + num2str(channelNumber)
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

static Function/WAVE PA_SmoothDeconv(WAVE input, STRUCT PulseAverageDeconvSettings &deconvolution)

	variable range_pnts, smoothingFactor
	string key

	range_pnts      = deconvolution.range / DimDelta(input, ROWS)
	smoothingFactor = max(min(deconvolution.smth, 32767), 1)

	key = CA_SmoothDeconv(input, smoothingFactor, range_pnts)
	WAVE/Z cache = CA_TryFetchingEntryFromCache(key, options = CA_OPTS_NO_DUPLICATE)
	if(WaveExists(cache))
		if(DimOffset(input, ROWS) != DimOffset(cache, ROWS))
			CopyScales/P input, cache
		endif
		return cache
	endif

	Duplicate/FREE/R=[0, range_pnts] input, wv
	Smooth smoothingFactor, wv

	CA_StoreEntryIntoCache(key, wv)
	return wv
End

static Function/WAVE PA_Deconvolution(WAVE average, DFREF outputDFR, string outputWaveName, STRUCT PulseAverageDeconvSettings &deconvolution)

	variable step
	string   key

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
		Duplicate/O cache, outputDFR:$outputWaveName/WAVE=wv
		return wv
	endif

	Duplicate/O/R=[0, DimSize(smoothed, ROWS) - 2] smoothed, outputDFR:$outputWaveName/WAVE=wv
	step = deconvolution.tau / DimDelta(average, 0)
	MultiThread wv = step * (smoothed[p + 1] - smoothed[p]) + smoothed[p]

	CA_StoreEntryIntoCache(key, wv)

	return wv
End

Function PA_CheckProc_Common(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	switch(cba.eventCode)
		case 2: // mouse up
			PA_Update(cba.win, POST_PLOT_CONSTANT_SWEEPS)
			break
		default:
			break
	endswitch

	return 0
End

Function PA_SetVarProc_Common(STRUCT WMSetVariableAction &sva) : SetVariableControl

	switch(sva.eventCode)
		case 1: // fallthrough, mouse up
		case 2: // fallthrough, Enter key
		case 3: // Live update
			if(!cmpstr(sva.ctrlName, "setvar_pulseAver_numberOfSpikes"))
				// switch to 1 on up/down buttons only
				if(IsNaN(sva.dVal) && sva.eventCode == 1)
					SetSetVariable(sva.win, sva.ctrlName, 1)
				endif
			endif
			PA_Update(sva.win, POST_PLOT_CONSTANT_SWEEPS)
			break
		default:
			break
	endswitch

	return 0
End

Function PA_PopMenuProc_ColorScale(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 2: // mouse up
			PA_SetColorScale(pa.win, pa.popStr)
			break
		default:
			break
	endswitch

	return 0
End

Function PA_PopMenuProc_Common(STRUCT WMPopupAction &pa) : PopupMenuControl

	switch(pa.eventCode)
		case 2: // mouse up
			PA_Update(pa.win, POST_PLOT_CONSTANT_SWEEPS)
			break
		default:
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

	variable i, j, numActive, jsonID, numEntries, oldSetMode

	MultiThreadingControl getMode
	oldSetMode = V_AutoMultiThread

	// require serial execution for WaveStats in PA_GetFeaturePosition
	MultiThreadingControl setMode=0

	WAVE      properties      = pasi.properties
	WAVE/WAVE propertiesWaves = pasi.propertiesWaves

	numActive = DimSize(pasi.channels, ROWS)

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
		Multithread featurePos[] = PA_GetFeaturePosition(propertiesWaves[setIndizes[p]][PA_PROPERTIESWAVES_INDEX_PULSE], propertiesWaves[setIndizes[p]][PA_PROPERTIESWAVES_INDEX_PULSENOTE])
		Multithread keys = "/" + num2str(properties[setIndizes[p]][PA_PROPERTIES_INDEX_SWEEP]) + "-" + num2str(properties[setIndizes[p]][PA_PROPERTIES_INDEX_PULSE])
		// store featurePos using sweep and pulse combination as key
		junk[] = JSON_SetVariable(jsonID, keys[p], featurePos[p])

		for(j = 0; j < numActive; j += 1)
			WAVE setIndizes = pasi.setIndices[j][i]
			numEntries = pasi.numEntries[j][i]
			if(numEntries == 0)
				continue
			endif

			Redimension/N=(numEntries) keys, junk
			Multithread keys[] = "/" + num2str(properties[setIndizes[p]][PA_PROPERTIES_INDEX_SWEEP]) + "-" + num2str(properties[setIndizes[p]][PA_PROPERTIES_INDEX_PULSE])
			Multithread junk[] = PA_SetFeaturePosition(propertiesWaves[setIndizes[p]][PA_PROPERTIESWAVES_INDEX_PULSE], propertiesWaves[setIndizes[p]][PA_PROPERTIESWAVES_INDEX_PULSENOTE], JSON_GetVariable(jsonID, keys[p], ignoreErr = 1))
		endfor
	endfor

	MultiThreadingControl setMode=oldSetMode

	JSON_Release(jsonID)
End

threadsafe static Function PA_GetFeaturePosition(WAVE wv, WAVE noteWave)

	variable featurePos

	featurePos = GetNumberFromWaveNote(noteWave, NOTE_KEY_TIMEALIGN_FEATURE_POS)

	if(IsFinite(featurePos))
		return featurePos
	endif

	WaveStats/M=1/Q wv
	featurePos = V_maxLoc
	SetNumberInWaveNote(noteWave, NOTE_KEY_TIMEALIGN_FEATURE_POS, featurePos, format = "%.15g")
	return featurePos
End

threadsafe static Function PA_SetFeaturePosition(WAVE wv, WAVE noteWave, variable featurePos)

	variable offset
	string   name

	if(GetNumberFromWaveNote(noteWave, NOTE_KEY_TIMEALIGN) == 1)
		return NaN
	endif

	name = NameOfWave(wv)

	if(IsNaN(featurePos))
		return NaN
	endif

	offset = -featurePos
	DEBUGPRINT_TS("pulse", str = name)
	DEBUGPRINT_TS("old DimOffset", var = DimOffset(wv, ROWS))
	DEBUGPRINT_TS("new DimOffset", var = DimOffset(wv, ROWS) + offset)
	SetScale/P x, DimOffset(wv, ROWS) + offset, DimDelta(wv, ROWS), wv
	SetNumberInWaveNote(noteWave, NOTE_KEY_TIMEALIGN_TOTAL_OFFSET, offset, format = "%.15g")
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
static Function PA_ResetWavesIfRequired(WAVE/Z setWave2, STRUCT PulseAverageSettings &pa, variable mode)

	variable i, statusZero, statusTimeAlign, numEntries, statusSearchFailedPulse
	variable failedPulseLevel, failedNumberOfSpikes

	if(!WaveExists(setWave2))
		return NaN
	endif

	WAVE/WAVE set2 = setWave2

	numEntries = DimSize(set2, ROWS)
	for(i = 0; i < numEntries; i += 1)

		WAVE noteWave = set2[i][1]

		statusZero              = GetNumberFromWaveNote(noteWave, NOTE_KEY_ZEROED)
		statusTimeAlign         = GetNumberFromWaveNote(noteWave, NOTE_KEY_TIMEALIGN)
		statusSearchFailedPulse = GetNumberFromWaveNote(noteWave, NOTE_KEY_SEARCH_FAILED_PULSE)

		if(statusZero == 0 && statusTimeAlign == 0 && statusSearchFailedPulse == 0)
			continue // wave is unmodified
		endif

		if(statusZero == pa.zeroPulses                        \
		   && statusTimeAlign == pa.autoTimeAlignment         \
		   && statusSearchFailedPulse == pa.searchFailedPulses)

			failedPulseLevel     = GetNumberFromWaveNote(noteWave, NOTE_KEY_FAILED_PULSE_LEVEL)
			failedNumberOfSpikes = GetNumberFromWaveNote(noteWave, NOTE_KEY_NUMBER_OF_SPIKES)

			// when zeroing and failed pulse search is enabled, we always
			// need to reset the waves when the level or the number of spike changes
			if(!pa.zeroPulses                                                             \
			   || !pa.searchFailedPulses                                                  \
			   || (pa.failedPulsesLevel == failedPulseLevel                               \
			       && EqualValuesOrBothNaN(failedNumberOfSpikes, pa.failedNumberOfSpikes)))
				continue // wave is up to date
			endif
		endif

		ReplaceWaveWithBackup(set2[i][0], nonExistingBackupIsFatal = 1, keepBackup = 1)
		ReplaceWaveWithBackup(set2[i][1], nonExistingBackupIsFatal = 1, keepBackup = 1)
	endfor
End

static Function PA_LayoutGraphs(string win, STRUCT PulseAverageSettings &pa, STRUCT PulseAverageSetIndices &pasi, variable displayMode)

	variable i, j, numActive, numEntries
	variable channelNumber, headstage, region, xStart, xAxisPlotRelative
	string graph, str, horizAxis, vertAxis, allAxes, vertAxes, horizAxes
	STRUCT RGBColor s

	numActive = DimSize(pasi.channels, ROWS)

	if(!pa.multipleGraphs)
		graph   = PA_GetGraphName(win, pa, displayMode, NaN, NaN)
		allAxes = AxisList(graph)

#ifdef PA_HIDE_AXIS
		ModifyGraph/W=$graph nticks=0, noLabel=2, axthick=0
#endif // PA_HIDE_AXIS

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
		EquallySpaceAxisPA(graph, allAxes, horizAxes, axisOffset = PA_X_AXIS_OFFSET)

		for(i = 0; i < numActive; i += 1)
			axisWaveRef[] = pasi.axesNames[p][i]
			for(j = 0; j < numActive; j += 1)
				WAVE/T wt = axisWaveRef[j]
				axisWave[numActive - j - 1] = wt[0]
			endfor
			vertAxes = TextWaveToList(axisWave, ";")
			EquallySpaceAxisPA(graph, allAxes, vertAxes)
			for(j = 0; j < numActive; j += 1)

				WAVE/T axesNames = pasi.axesNames[j][i]
				vertAxis  = axesNames[0]
				horizAxis = axesNames[1]

				xAxisPlotRelative = PA_GetSetXAxisUserData(graph, horizAxis)
				ModifyGraph/W=$graph/Z freePos($vertAxis)={xAxisPlotRelative, kwFraction}
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

			Make/FREE/N=(numEntries) pulsesNonUnique = properties[setIndizes[p]][PA_PROPERTIES_INDEX_PULSE]
			WAVE pulses = GetUniqueEntries(pulsesNonUnique)

			Make/FREE/N=(numEntries) sweepsNonUnique = properties[setIndizes[p]][PA_PROPERTIES_INDEX_SWEEP]
			WAVE sweeps = GetUniqueEntries(sweepsNonUnique)

			Make/FREE/N=(numEntries) headstagesNonUnique = properties[setIndizes[p]][PA_PROPERTIES_INDEX_HEADSTAGE]
			WAVE headstages = GetUniqueEntries(headstagesNonUnique)
			ASSERT(DimSize(headstages, ROWS) == 1, "Invalid number of distinct headstages")

			headstage = headstages[0]

			sprintf str, "\\Zr075#Pulses %g / #Swps. %d", DimSize(pulses, ROWS), DimSize(sweeps, ROWS)
			Textbox/W=$graph/C/N=leg/X=-5.00/Y=-5.00 str

			[s] = GetTraceColor(headstage)
			sprintf str, "\\k(%d, %d, %d)\\K(%d, %d, %d)\\W555\\k(0, 0, 0)\\K(0, 0, 0)", s.red, s.green, s.blue, s.red, s.green, s.blue

			sprintf str, "AD%d / Reg. %d HS%s", channelNumber, region, str
			AppendText/W=$graph str

			WAVE/T axisWave = pasi.axesNames[i][j]
			horizAxis = axisWave[1]
			PA_GetSetXAxisUserData(graph, horizAxis)

#ifdef PA_HIDE_AXIS
			ModifyGraph/W=$graph nticks=0, noLabel=2, axthick=0, margin=5
#endif // PA_HIDE_AXIS
			ModifyGraph/W=$graph/Z freePos(bottom)=0
		endfor
	endfor
End

static Function PA_GetSetXAxisUserData(string graph, string horizAxis)

	variable xStart, xAxisPlotRelative

	xStart            = GetNumFromModifyStr(AxisInfo(graph, horizAxis), "axisEnab", "{", 0)
	xAxisPlotRelative = xStart - PA_X_AXIS_OFFSET
	SetWindow $graph, userData($(PA_USER_DATA_X_START_RELATIVE_PREFIX + horizAxis))=num2str(xAxisPlotRelative)

	return xAxisPlotRelative
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

			if((!pa.multipleGraphs && i == 0 && j == 0) || pa.multipleGraphs)
				graph = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, i + 1)
			endif

			WAVE/T axesNames = pasi.axesNames[j][i]
			vertAxis  = axesNames[0]
			horizAxis = axesNames[1]

			// only show filled in pulses for the vertical axis
			WAVE img = GetPulseAverageSetImageWave(pasi.pulseAverageDFR, channelNumber, region)
			lastEntry = GetNumberFromWaveNote(img, NOTE_INDEX)
			GetAxis/Q/W=$graph $vertAxis
			ASSERT(V_flag == 0, "Missing axis")
			SetAxis/W=$graph $vertAxis, lastEntry - 0.5, -0.5

			minimum = GetNumberFromWaveNote(img, NOTE_KEY_IMG_PMIN)
			maximum = GetNumberFromWaveNote(img, NOTE_KEY_IMG_PMAX)

			// gather min/max for diagonal and off-diagonal elements
			if(i == j)
				if(!IsNaN(minimum))
					minimumDiag = min(minimum, minimumDiag)
				endif
				if(!IsNaN(maximum))
					maximumDiag = max(maximum, maximumDiag)
				endif
			else
				if(!IsNaN(minimum))
					minimumRows[j] = min(minimum, minimumRows[j])
				endif
				if(!IsNaN(maximum))
					maximumRows[j] = max(maximum, maximumRows[j])
				endif
			endif
		endfor
	endfor

	if(pa.zeroPulses)
		[minimumDiag, maximumDiag] = SymmetrizeRangeAroundZero(minimumDiag, maximumDiag)

		for(i = 0; i < numActive; i += 1)
			[minimum, maximum] = SymmetrizeRangeAroundZero(minimumRows[i], maximumRows[i])
			minimumRows[i]     = minimum
			maximumRows[i]     = maximum
		endfor
	endif

	for(i = 0; i < numActive; i += 1)
		region = pasi.regions[i]

		for(j = 0; j < numActive; j += 1)
			channelNumber = pasi.channels[j]

			if((!pa.multipleGraphs && i == 0 && j == 0) || pa.multipleGraphs)
				graph           = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, i + 1)
				graphsToResize  = AddListItem(graph, graphsToResize, ";", Inf)
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

			ModifyImage/W=$graph $traceName, ctab={minimum, maximum, $(pa.imageColorScale), 0}, minRGB=0, maxRGB=(65535, 0, 0)
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
				if(i == (numActive - 1))
					regionTaken = 0
					region      = pasi.regions[regionTaken]
				else
					regionTaken = numActive - 1
					region      = pasi.regions[regionTaken]
				endif

				WAVE img = GetPulseAverageSetImageWave(pasi.pulseAverageDFR, channelNumber, region)
				traceName = NameOfWave(img)

				if(i == 0)
					graph           = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, regionTaken + 1)
					colorScaleGraph = PA_GetColorScaleGraph(graph)
				endif

				WAVE setIndizes = pasi.setIndices[i][regionTaken]
				if(GetNumberFromWaveNote(setIndizes, NOTE_INDEX) == 0)
					continue
				endif
				// assume that all pulses are from the same headstage
				headstage = properties[setIndizes[0]][PA_PROPERTIES_INDEX_HEADSTAGE]
				ASSERT(IsValidHeadstage(headstage), "Invalid headstage")

				name = "colorScale_AD_" + num2str(channelNumber)
				text = "HS" + num2str(headstage) + " (\\U)"
				PA_AddColorScale(graph, colorScaleGraph, name, text, i, numSlots, traceName)
			endfor

			// diagonal color scale
			channelNumber   = pasi.channels[0]
			regionTaken     = 0
			region          = pasi.regions[regionTaken]
			graph           = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, regionTaken + 1)
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

				graph           = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, numActive)
				colorScaleGraph = PA_GetColorScaleGraph(graph)
				ASSERT(WindowExists(colorScaleGraph), "Missing external subwindow for color scale")

				if(i == (numActive - 1))
					regionTaken = 0
					region      = pasi.regions[regionTaken]
					imageGraph  = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, 1)
					numSlots    = 2
				else
					regionTaken = numActive - 1
					region      = pasi.regions[regionTaken]
					graph       = PA_GetGraphName(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, numActive)
					imageGraph  = graph
					numSlots    = 1
				endif

				WAVE setIndizes = pasi.setIndices[i][regionTaken]
				// assume that all pulses are from the same headstage
				if(GetNumberFromWaveNote(setIndizes, NOTE_INDEX) == 0)
					continue
				endif
				headstage = properties[setIndizes[0]][PA_PROPERTIES_INDEX_HEADSTAGE]
				ASSERT(IsValidHeadstage(headstage), "Invalid headstage")

				WAVE img = GetPulseAverageSetImageWave(pasi.pulseAverageDFR, channelNumber, region)
				traceName = NameOfWave(img)

				name = "colorScale_HS_" + num2str(headstage)
				text = "HS" + num2str(headstage) + "\r(\\U)"
				PA_AddColorScale(imageGraph, colorScaleGraph, name, text, 0, numSlots, traceName)
			endfor

			name     = "colorScaleDiag"
			text     = "Diagonal\r(\\U)"
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

	[WAVE start, WAVE stop] = DistributeElements(numSlots)

	intIndex = trunc(index)
	length   = stop[intIndex] - start[intIndex]
	yPos     = start[intIndex] + abs(index - intIndex) * length
	yPos    *= ONE_TO_PERCENT

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
	string   datafolder

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
	JSON_AddVariable(jsonID, "/failedNumberOfSpikes", pa.failedNumberOfSpikes)
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

	jsonID = JSON_Parse(GetUserData(win, "", PA_SETTINGS), ignoreErr = 1)

	if(!JSON_IsValid(jsonID))
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

	DFREF pa.dfr = $JSON_GetString(jsonID, "/dfr")
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
	pa.failedNumberOfSpikes = JSON_GetVariable(jsonID, "/failedNumberOfSpikes")
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

	variable channelNumber, region, numActive, i, j, k, err, val
	variable requiredEntries, specialEntryHeight, numPulses, numAllPulsesInSet
	variable failedMarkerStartRow, xPos, yPos, newSweep, numGraphs
	variable vert_min, vert_max, horiz_min, horiz_max, firstPulseIndex, layoutChanged
	variable graphDataIndex, junk, lblIMAGELIST, resetImage, gotNewPulsesToDraw
	variable colStart, colEnd
	variable refScaleLeft, refScaleRight, refScalePoints, refScaleDelta, scaleChanged, pulseScaleLeft, pulseScaleRight
	string vertAxis, horizAxis, graph, basename, imageName, msg, graphWithImage, xUnits
	string image
	string usedGraphs       = ""
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

			resetImage = 0

			[WAVE averageWave, baseName] = GetPAPermanentAverageWave(pasi.pulseAverageDFR, channelNumber, region)

			if((!pa.multipleGraphs && i == 0 && j == 0) || pa.multipleGraphs)
				graph             = PA_GetGraph(win, pa, PA_DISPLAYMODE_IMAGES, channelNumber, region, j + 1, i + 1, numActive)
				graphsWithImages += AddPrefixToEachListItem(graph + "#", ImageNameList(graph, ";"))
				SetDrawLayer/W=$graph/K $PA_DRAWLAYER_FAILED_PULSES
				usedGraphs = AddListItem(graph, usedGraphs, ";", Inf)
			endif

			numPulses          = pasi.numEntries[i][j]
			gotNewPulsesToDraw = numPulses != 0
			WAVE img = GetPulseAverageSetImageWave(pasi.pulseAverageDFR, channelNumber, region)

			// bottom to top:
			// pulses
			// average
			// deconvolution
			//
			// we reserve 5% of the total columns for average and 5% for deconvolution
			specialEntryHeight = trunc((1 / (1 - 2 * PA_IMAGE_SPECIAL_ENTRIES_RANGE) - 1) * numPulses / 2)
			specialEntryHeight = limit(specialEntryHeight, 1, specialEntryHeight)
			requiredEntries    = numPulses + 2 * specialEntryHeight

			firstPulseIndex = 0

			if(numPulses == 0)
				Multithread img[][] = NaN
			else

				// Determine common wave scales
				WAVE/WAVE set2 = WaveRef(pasi.setWaves2Unsorted[i][j])
				numAllPulsesInSet = DimSize(set2, ROWS)
				Make/FREE/D/N=(numAllPulsesInSet) scaleLeft, scaleRight, scalePoints
				Multithread scaleLeft = leftx(set2[p][0])
				Multithread scaleRight = rightx(set2[p][0])
				Multithread scalePoints = DimSize(set2[p][0], ROWS)
				refScaleLeft   = WaveMin(scaleLeft)
				refScaleRight  = WaveMax(scaleRight)
				refScalePoints = WaveMax(scalePoints)
				refScaleDelta  = (refScaleRight - refScaleLeft) / refScalePoints
				scaleChanged   = (DimOffset(img, ROWS) != refScaleLeft) || ((DimOffset(img, ROWS) + (DimSize(img, ROWS) - 1) * DimDelta(img, ROWS)) != refScaleRight)
				xUnits         = WaveUnits(set2[0][0], ROWS)

				WAVE oldSizes = GetWaveDimensions(img)
				EnsureLargeEnoughWave(img, indexShouldExist = requiredEntries, dimension = COLS, initialValue = NaN)
				Redimension/N=(refScalePoints, -1) img
				// inclusive scale must be set after redimension
				SetScale/P x, refScaleLeft, refScaleDelta, xUnits, img
				WAVE newSizes = GetWaveDimensions(img)

				if(!(mode != POST_PLOT_ADDED_SWEEPS                       \
				     || !EqualWaves(oldSizes, newSizes, EQWAVES_DATA)     \
				     || pa.pulseSortOrder != PA_PULSE_SORTING_ORDER_SWEEP \
				     || scaleChanged                                      \
				     || layoutChanged))

					[WAVE/D newSweeps, WAVE/T newExperiments] = PA_GetSweepsAndExperimentsFromIndices(win, additionalData)

					newSweep = WaveMin(newSweeps)
					WAVE setIndizes = pasi.setIndices[i][j]
					Make/FREE/N=(numPulses) sweeps = properties[setIndizes[p]][PA_PROPERTIES_INDEX_SWEEP]
					FindValue/Z/V=(newSweep) sweeps
					if(V_Value >= 0)
						firstPulseIndex = V_Value
					else
						// The current sweep has no pulses in this channel/region
						gotNewPulsesToDraw = 0
					endif
					WaveClear sweeps
				else
					resetImage = 1
				endif
				if(resetImage)
					Multithread img[][] = NaN
				endif
			endif

			if(pa.showIndividualPulses && gotNewPulsesToDraw)
				// pasi stores only the unsorted sets, but specifically here we need the sorted ones. Thus, we have to retrieve it from the now sorted setIndices.
				WAVE/WAVE set2 = PA_GetSetWaves(pasi.pulseAverageHelperDFR, channelNumber, region)
				colStart = firstPulseIndex
				colEnd   = numPulses
				AssertOnAndClearRTError()
				Multithread img[][colStart, colEnd - 1] = WaveRef(set2[q][0])(x); err = GetRTError(1) // see developer docu section Preventing Debugger Popup
				for(k = colStart; k < colEnd; k += 1)
					pulseScaleLeft = scaleLeft[k]
					if(refScaleLeft != pulseScaleLeft && pulseScaleLeft > (refScaleLeft + refScaleDelta))
						// fill left side with NaN
						img[0, ScaleToIndexWrapper(img, pulseScaleLeft, ROWS)][k] = NaN
					endif
					pulseScaleRight = scaleRight[k]
					if(refScaleRight != pulseScaleRight && pulseScaleRight < (refScaleRight - refScaleDelta))
						// fill right side with NaN
						img[ScaleToIndexWrapper(img, pulseScaleRight, ROWS), Inf][k] = NaN
					endif
				endfor
			endif

			if(numPulses > 0)
				// write min and max of the single pulses into the wave note
				[vert_min, vert_max, horiz_min, horiz_max] = PA_GetMinAndMax(pasi.setWaves2Unsorted[i][j])
			else
				vert_min = NaN
				vert_max = NaN
			endif

			SetNumberInWaveNote(img, NOTE_KEY_IMG_PMIN, vert_min)
			SetNumberInWaveNote(img, NOTE_KEY_IMG_PMAX, vert_max)

			if(pa.showAverage && WaveExists(averageWave))
				// when all pulses from the set fail, we don't have an average wave
				colStart = numPulses
				colEnd   = numPulses + specialEntryHeight
				AssertOnAndClearRTError()
				Multithread img[][colStart, colEnd - 1] = averageWave(x); err = GetRTError(1) // see developer docu section Preventing Debugger Popup
				val = leftx(averageWave)
				if(refScaleLeft != val && val > (refScaleLeft + refScaleDelta))
					img[0, ScaleToIndexWrapper(img, val, ROWS)][colStart, colEnd - 1] = NaN
				endif
				val = rightx(averageWave)
				if(refScaleRight != val && val < (refScaleRight - refScaleDelta))
					img[ScaleToIndexWrapper(img, val, ROWS), Inf][colStart, colEnd - 1] = NaN
				endif
				pasi.imageAvgDataPresent[i][j] = 1
			else
				pasi.imageAvgDataPresent[i][j] = 0
			endif

			if(pa.deconvolution.enable && !(i == j) && WaveExists(averageWave))
				baseName = PA_BaseName(channelNumber, region)
				WAVE deconv = PA_Deconvolution(averageWave, pasi.pulseAverageDFR, PA_DECONVOLUTION_WAVE_PREFIX + baseName, pa.deconvolution)
				colStart = numPulses + specialEntryHeight
				colEnd   = numPulses + 2 * specialEntryHeight
				AssertOnAndClearRTError()
				Multithread img[][colStart, colEnd - 1] = limit(deconv(x), vert_min, vert_max); err = GetRTError(1) // see developer docu section Preventing Debugger Popup
				val = leftx(deconv)
				if(refScaleLeft != val && val > (refScaleLeft + refScaleDelta))
					img[0, ScaleToIndexWrapper(img, val, ROWS)][colStart, colEnd - 1] = NaN
				endif
				val = rightx(deconv)
				if(refScaleRight != val && val < (refScaleRight - refScaleDelta))
					img[ScaleToIndexWrapper(img, val, ROWS), Inf][colStart, colEnd - 1] = NaN
				endif
				pasi.imageDeconvDataPresent[i][j] = 1
			else
				pasi.imageDeconvDataPresent[i][j] = 0
			endif

			SetNumberInWaveNote(img, NOTE_INDEX, requiredEntries)

			imageName = NameOfWave(img)

			sprintf msg, "imageName %s, specialEntryHeight %d, requiredEntries %d, firstPulseIndex %d, numPulses %d\r", imageName, specialEntryHeight, requiredEntries, firstPulseIndex, numPulses
			DEBUGPRINT(msg)

			graphsWithImages = RemoveFromList(graph + "#" + imageName, graphsWithImages)

			WAVE/T axesNames = pasi.axesNames[i][j]
			vertAxis  = axesNames[0]
			horizAxis = axesNames[1]

			graphDataIndex = PA_GetTraceCountFromGraphData(graph)
			if(WhichListItem(imageName, paGraphData[graphDataIndex][lblIMAGELIST]) == -1)
				AppendImage/W=$graph/L=$vertAxis/B=$horizAxis img
				paGraphData[graphDataIndex][lblIMAGELIST] = AddListItem(imageName, paGraphData[graphDataIndex][lblIMAGELIST])
			endif

			PA_HighligthFailedPulsesInImage(graph, pa, vertAxis, horizAxis, img, pasi.properties, pasi.setIndices[i][j], numPulses)
		endfor
	endfor

	PA_LayoutGraphs(win, pa, pasi, PA_DISPLAYMODE_IMAGES)

	// now remove all images which were left over from previous plots but not referenced anymore
	numGraphs = ItemsInList(graphsWithImages)
	for(i = 0; i < numGraphs; i += 1)
		graphWithImage = StringFromList(i, graphsWithImages)
		graph          = StringFromList(0, graphWithImage, "#")
		image          = StringFromList(1, graphWithImage, "#")
		RemoveImage/W=$graph $image
		paGraphData[graphDataIndex][lblIMAGELIST] = RemoveFromList(image, paGraphData[graphDataIndex][lblIMAGELIST], ";")
	endfor

	PA_DrawScaleBars(win, pa, pasi, PA_DISPLAYMODE_IMAGES, PA_USE_WAVE_SCALES)
	PA_AddColorScales(win, pa, pasi)
	PA_DrawXZeroLines(win, pa, pasi, PA_DISPLAYMODE_IMAGES)

	return usedGraphs
End

static Function PA_HighligthFailedPulsesInImage(string graph, STRUCT PulseAverageSettings &pa, string vertAxis, string horizAxis, WAVE img, WAVE properties, WAVE setIndizes, variable numPulses)

	variable failedMarkerStartRow, i, xPos, fillValue, numFailedPulses

	if(!pa.searchFailedPulses || !pa.showIndividualPulses)
		return NaN
	endif

	if(pa.hideFailedPulses)
		failedMarkerStartRow = 0
		fillValue            = NaN
	else
		failedMarkerStartRow = trunc(DimSize(img, ROWS) * PA_IMAGE_FAILEDMARKERSTART)
		fillValue            = Inf
	endif

	for(i = 0; i < numPulses; i += 1)
		if(!properties[setIndizes[i]][PA_PROPERTIES_INDEX_PULSEHASFAILED])
			continue
		endif

		Multithread img[failedMarkerStartRow, Inf][i] = fillValue

		if(!pa.hideFailedPulses)
			if(numFailedPulses == 0)
				SetDrawEnv/W=$graph push
				SetDrawLayer/W=$graph $PA_DRAWLAYER_FAILED_PULSES
				SetDrawEnv/W=$graph xcoord=$horizAxis, ycoord=$vertAxis, textxjust=0, textyjust=1
				SetDrawEnv/W=$graph save
			endif

			xPos = rightx(img)
			DrawText/W=$graph xPos, i, "◅"
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

	graphs    = PA_GetGraphs(win, PA_DISPLAYMODE_IMAGES)
	numGraphs = ItemsInList(graphs)

	for(i = 0; i < numGraphs; i += 1)
		graph = StringFromList(i, graphs)

		images    = ImageNameList(graph, ";")
		numImages = ItemsInList(images)
		for(j = 0; j < numImages; j += 1)
			image = StringFromList(j, images)
			ModifyImage/W=$graph $image, ctab={,, $colScale, 0}
		endfor
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
	graphHeight = V_bottom - V_top + SUBWINDOW_MOVE_CORRECTION

	MoveSubWindow/W=$colorScalePanel fnum=(0, 0, PA_COLORSCALE_PANEL_WIDTH, graphHeight)
End

Function PA_TraceWindowHook(STRUCT WMWinHookStruct &s)

	string traceGraph

	switch(s.eventcode)
		case EVENT_WINDOW_HOOK_MOUSEWHEEL: // fallthrough
		case EVENT_WINDOW_HOOK_RESIZE:
			traceGraph = s.winName
			Execute/P/Q/Z "PA_UpdateScaleBars(\"" + traceGraph + "\", 0)"
			CleanupOperationQueueResult()
			break
		case EVENT_WINDOW_HOOK_MENU:
			if(!cmpstr(s.menuName, "Graph") && !cmpstr(s.menuItem, "Autoscale Axes"))
				traceGraph = s.winName
				Execute/P/Q/Z "PA_UpdateScaleBars(\"" + traceGraph + "\", 1)"
				CleanupOperationQueueResult()
			endif
			break
		default:
			break
	endswitch

	return 0
End

Function PA_ImageWindowHook(STRUCT WMWinHookStruct &s)

	string imageGraph

	switch(s.eventcode)
		case EVENT_WINDOW_HOOK_RESIZE:
			imageGraph = s.winName
			PA_ResizeColorScalePanel(imageGraph)
			Execute/P/Q/Z "PA_UpdateScaleBars(\"" + imageGraph + "\", 0)"
			CleanupOperationQueueResult()
			break
		case EVENT_WINDOW_HOOK_MENU:
			if(!cmpstr(s.menuName, "Graph") && !cmpstr(s.menuItem, "Autoscale Axes"))
				imageGraph = s.winName
				Execute/P/Q/Z "PA_UpdateScaleBars(\"" + imageGraph + "\", 1)"
				CleanupOperationQueueResult()
			endif
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Returns 1 if data is displayed on the given layout grid location.
///        When data is displayed in PA_ShowPulses and PA_ShowImage then in PulseAverageSetIndices this is tagged.
/// @param[in] pa Pulse Average Setting information
/// @param[in] pasi Pulse Average Set Indices information
/// @param[in] xLoc x location on display grid, typically the channel index
/// @param[in] yLoc y location on display grid, typically the region index
/// @param[in] displayMode Return data for either trace plot (PA_DISPLAYMODE_TRACES) or image plot (PA_DISPLAYMODE_IMAGES)
/// @returns 1 if data is displayed on this grid location, 0 if no data is displayed
static Function PA_IsDataOnSubPlot(STRUCT PulseAverageSettings &pa, STRUCT PulseAverageSetIndices &pasi, variable xLoc, variable yLoc, variable displayMode)

	if(displayMode == PA_DISPLAYMODE_TRACES)
		return !!(pa.showIndividualPulses * pasi.numEntries[yLoc][xLoc] + pasi.ovlTracesAvg[yLoc][xLoc] + pasi.ovlTracesDeconv[yLoc][xLoc])
	endif
	if(displayMode == PA_DISPLAYMODE_IMAGES)
		return !!(pa.showIndividualPulses * pasi.numEntries[yLoc][xLoc] + pasi.imageAvgDataPresent[yLoc][xLoc] + pasi.imageDeconvDataPresent[yLoc][xLoc])
	endif
	FATAL_ERROR("Unknown display mode")
End

static Function PA_DrawXZeroLines(string win, STRUCT PulseAverageSettings &pa, STRUCT PulseAverageSetIndices &pasi, variable displayMode)

	variable i, j, numActive, channelNumber, region
	string vertAxis, horizAxis, graph

	numActive = DimSize(pasi.channels, ROWS)

	for(i = 0; i < numActive; i += 1)
		channelNumber = pasi.channels[i]

		for(j = 0; j < numActive; j += 1)
			region = pasi.regions[j]

			if((!pa.multipleGraphs && i == 0 && j == 0) || pa.multipleGraphs)
				graph = PA_GetGraph(win, pa, displayMode, channelNumber, region, j + 1, i + 1, numActive)
				SetDrawLayer/W=$graph/K $PA_DRAWLAYER_XZEROLINE
			endif

			if(!PA_IsDataOnSubPlot(pa, pasi, j, i, displayMode))
				continue
			endif

			if(!pa.drawXZeroLine)
				if(!pa.multipleGraphs)
					return NaN
				endif

				continue
			endif

			WAVE/T axesNames = pasi.axesNames[i][j]
			vertAxis  = axesNames[0]
			horizAxis = axesNames[1]

			SetDrawEnv/W=$graph push
			SetDrawEnv/W=$graph xcoord=$horizAxis, ycoord=rel, dash=1
			SetDrawEnv/W=$graph save
			DrawLine/W=$graph 0, 0, 0, 1
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
		graph  = wGraphs[i0]
		i0Path = "/" + graph
		WAVE/T wVertAxis = JSON_GetKeys(jsonID, i0Path)
		numVertAxis = DimSize(wVertAxis, ROWS)
		for(i1 = 0; i1 < numVertAxis; i1 += 1)
			vertAxis = wVertAxis[i1]
			i1Path   = i0Path + "/" + vertAxis
			WAVE/T wHorizAxis = JSON_GetKeys(jsonID, i1Path)
			numHorizAxis = DimSize(wHorizAxis, ROWS)
			for(i2 = 0; i2 < numHorizAxis; i2 += 1)
				horizAxis = wHorizAxis[i2]
				i2Path    = i1Path + "/" + horizAxis
				WAVE/T wRed = JSON_GetKeys(jsonID, i2Path)
				numRed = DimSize(wRed, ROWS)
				for(i3 = 0; i3 < numRed; i3 += 1)
					redStr = wRed[i3]
					red    = str2num(redStr)
					i3Path = i2Path + "/" + redStr
					WAVE/T wGreen = JSON_GetKeys(jsonID, i3Path)
					numGreen = DimSize(wGreen, ROWS)
					for(i4 = 0; i4 < numGreen; i4 += 1)
						greenStr = wGreen[i4]
						green    = str2num(greenStr)
						i4Path   = i3Path + "/" + greenStr
						WAVE/T wBlue = JSON_GetKeys(jsonID, i4Path)
						numBlue = DimSize(wBlue, ROWS)
						for(i5 = 0; i5 < numBlue; i5 += 1)
							blueStr = wBlue[i5]
							blue    = str2num(blueStr)
							i5Path  = i4Path + "/" + blueStr
							WAVE/T wAlpha = JSON_GetKeys(jsonID, i5Path)
							numAlpha = DimSize(wAlpha, ROWS)
							for(i6 = 0; i6 < numAlpha; i6 += 1)
								alphaStr = wAlpha[i6]
								alpha    = str2num(alphaStr)
								i6Path   = i5Path + "/" + alphaStr
								WAVE/T wStep = JSON_GetKeys(jsonID, i6Path)
								numStep = DimSize(wStep, ROWS)
								for(i7 = 0; i7 < numStep; i7 += 1)
									stepStr = wStep[i7]
									i7Path  = i6Path + "/" + stepStr
									WAVE   indices    = JSON_GetWave(jsonID, i7Path + "/index")
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

	// IPT_FORMAT_OFF

	variable step, i
	i = DimSize(y, ROWS)
	if(s > 1)
		do
			step = min(2 ^ trunc(log(i) / log(2)), 100)
			i -= step
			switch(step)
				case 100:
					WAVE aa=d[y[i]];WAVE ab=d[y[i+1]];WAVE ac=d[y[i+2]];WAVE ad=d[y[i+3]];WAVE ae=d[y[i+4]];WAVE af=d[y[i+5]];WAVE ag=d[y[i+6]];WAVE ah=d[y[i+7]];WAVE ai=d[y[i+8]];WAVE aj=d[y[i+9]];WAVE ak=d[y[i+10]];WAVE al=d[y[i+11]];WAVE am=d[y[i+12]];WAVE an=d[y[i+13]];WAVE ap=d[y[i+14]];WAVE aq=d[y[i+15]];WAVE ar=d[y[i+16]];WAVE a_=d[y[i+17]];WAVE at=d[y[i+18]];WAVE au=d[y[i+19]];WAVE av=d[y[i+20]];WAVE aw=d[y[i+21]];WAVE ax=d[y[i+22]];WAVE ay=d[y[i+23]];WAVE az=d[y[i+24]];WAVE ba=d[y[i+25]];WAVE bb=d[y[i+26]];WAVE bc=d[y[i+27]];WAVE bd=d[y[i+28]];WAVE be=d[y[i+29]];WAVE bf=d[y[i+30]];WAVE bg=d[y[i+31]];WAVE bh=d[y[i+32]];WAVE bi=d[y[i+33]];WAVE bj=d[y[i+34]];WAVE bk=d[y[i+35]];WAVE bl=d[y[i+36]];WAVE bm=d[y[i+37]];WAVE bn=d[y[i+38]];WAVE bp=d[y[i+39]];WAVE bq=d[y[i+40]];WAVE br=d[y[i+41]];WAVE bs=d[y[i+42]];WAVE bt=d[y[i+43]];WAVE bu=d[y[i+44]];WAVE bv=d[y[i+45]];WAVE bw=d[y[i+46]];WAVE bx=d[y[i+47]];WAVE by=d[y[i+48]];WAVE bz=d[y[i+49]];WAVE ca=d[y[i+50]];WAVE cb=d[y[i+51]];WAVE cc=d[y[i+52]];WAVE cd=d[y[i+53]];WAVE ce=d[y[i+54]];WAVE cf=d[y[i+55]];WAVE cg=d[y[i+56]];WAVE ch=d[y[i+57]];WAVE ci=d[y[i+58]];WAVE cj=d[y[i+59]];WAVE ck=d[y[i+60]];WAVE cl=d[y[i+61]];WAVE cm=d[y[i+62]];WAVE cn=d[y[i+63]];WAVE cp=d[y[i+64]];WAVE cq=d[y[i+65]];WAVE cr=d[y[i+66]];WAVE cs=d[y[i+67]];WAVE ct=d[y[i+68]];WAVE cu=d[y[i+69]];WAVE cv=d[y[i+70]];WAVE cw=d[y[i+71]];WAVE cx=d[y[i+72]];WAVE cy=d[y[i+73]];WAVE cz=d[y[i+74]];WAVE da=d[y[i+75]];WAVE db=d[y[i+76]];WAVE dc=d[y[i+77]];WAVE dd=d[y[i+78]];WAVE de=d[y[i+79]];WAVE df=d[y[i+80]];WAVE dg=d[y[i+81]];WAVE dh=d[y[i+82]];WAVE di=d[y[i+83]];WAVE dj=d[y[i+84]];WAVE dk=d[y[i+85]];WAVE dl=d[y[i+86]];WAVE dm=d[y[i+87]];WAVE dn=d[y[i+88]];WAVE dp=d[y[i+89]];WAVE dq=d[y[i+90]];WAVE dr=d[y[i+91]];WAVE ds=d[y[i+92]];WAVE dt=d[y[i+93]];WAVE du=d[y[i+94]];WAVE dv=d[y[i+95]];WAVE dw=d[y[i+96]];WAVE dx=d[y[i+97]];WAVE dy=d[y[i+98]];WAVE dz=d[y[i+99]]
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) aa[0,*;s]/TN=$t[i],ab[0,*;s]/TN=$t[i+1],ac[0,*;s]/TN=$t[i+2],ad[0,*;s]/TN=$t[i+3],ae[0,*;s]/TN=$t[i+4],af[0,*;s]/TN=$t[i+5],ag[0,*;s]/TN=$t[i+6],ah[0,*;s]/TN=$t[i+7],ai[0,*;s]/TN=$t[i+8],aj[0,*;s]/TN=$t[i+9],ak[0,*;s]/TN=$t[i+10],al[0,*;s]/TN=$t[i+11],am[0,*;s]/TN=$t[i+12],an[0,*;s]/TN=$t[i+13],ap[0,*;s]/TN=$t[i+14],aq[0,*;s]/TN=$t[i+15],ar[0,*;s]/TN=$t[i+16],a_[0,*;s]/TN=$t[i+17],at[0,*;s]/TN=$t[i+18],au[0,*;s]/TN=$t[i+19],av[0,*;s]/TN=$t[i+20],aw[0,*;s]/TN=$t[i+21],ax[0,*;s]/TN=$t[i+22],ay[0,*;s]/TN=$t[i+23],az[0,*;s]/TN=$t[i+24],ba[0,*;s]/TN=$t[i+25],bb[0,*;s]/TN=$t[i+26],bc[0,*;s]/TN=$t[i+27],bd[0,*;s]/TN=$t[i+28],be[0,*;s]/TN=$t[i+29],bf[0,*;s]/TN=$t[i+30],bg[0,*;s]/TN=$t[i+31],bh[0,*;s]/TN=$t[i+32],bi[0,*;s]/TN=$t[i+33],bj[0,*;s]/TN=$t[i+34],bk[0,*;s]/TN=$t[i+35],bl[0,*;s]/TN=$t[i+36],bm[0,*;s]/TN=$t[i+37],bn[0,*;s]/TN=$t[i+38],bp[0,*;s]/TN=$t[i+39],bq[0,*;s]/TN=$t[i+40],br[0,*;s]/TN=$t[i+41],bs[0,*;s]/TN=$t[i+42],bt[0,*;s]/TN=$t[i+43],bu[0,*;s]/TN=$t[i+44],bv[0,*;s]/TN=$t[i+45],bw[0,*;s]/TN=$t[i+46],bx[0,*;s]/TN=$t[i+47],by[0,*;s]/TN=$t[i+48],bz[0,*;s]/TN=$t[i+49],ca[0,*;s]/TN=$t[i+50],cb[0,*;s]/TN=$t[i+51],cc[0,*;s]/TN=$t[i+52],cd[0,*;s]/TN=$t[i+53],ce[0,*;s]/TN=$t[i+54],cf[0,*;s]/TN=$t[i+55],cg[0,*;s]/TN=$t[i+56],ch[0,*;s]/TN=$t[i+57],ci[0,*;s]/TN=$t[i+58],cj[0,*;s]/TN=$t[i+59],ck[0,*;s]/TN=$t[i+60],cl[0,*;s]/TN=$t[i+61],cm[0,*;s]/TN=$t[i+62],cn[0,*;s]/TN=$t[i+63],cp[0,*;s]/TN=$t[i+64],cq[0,*;s]/TN=$t[i+65],cr[0,*;s]/TN=$t[i+66],cs[0,*;s]/TN=$t[i+67],ct[0,*;s]/TN=$t[i+68],cu[0,*;s]/TN=$t[i+69],cv[0,*;s]/TN=$t[i+70],cw[0,*;s]/TN=$t[i+71],cx[0,*;s]/TN=$t[i+72],cy[0,*;s]/TN=$t[i+73],cz[0,*;s]/TN=$t[i+74],da[0,*;s]/TN=$t[i+75],db[0,*;s]/TN=$t[i+76],dc[0,*;s]/TN=$t[i+77],dd[0,*;s]/TN=$t[i+78],de[0,*;s]/TN=$t[i+79],df[0,*;s]/TN=$t[i+80],dg[0,*;s]/TN=$t[i+81],dh[0,*;s]/TN=$t[i+82],di[0,*;s]/TN=$t[i+83],dj[0,*;s]/TN=$t[i+84],dk[0,*;s]/TN=$t[i+85],dl[0,*;s]/TN=$t[i+86],dm[0,*;s]/TN=$t[i+87],dn[0,*;s]/TN=$t[i+88],dp[0,*;s]/TN=$t[i+89],dq[0,*;s]/TN=$t[i+90],dr[0,*;s]/TN=$t[i+91],ds[0,*;s]/TN=$t[i+92],dt[0,*;s]/TN=$t[i+93],du[0,*;s]/TN=$t[i+94],dv[0,*;s]/TN=$t[i+95],dw[0,*;s]/TN=$t[i+96],dx[0,*;s]/TN=$t[i+97],dy[0,*;s]/TN=$t[i+98],dz[0,*;s]/TN=$t[i+99]
					break
				case 64:
					WAVE aa=d[y[i]];WAVE ab=d[y[i+1]];WAVE ac=d[y[i+2]];WAVE ad=d[y[i+3]];WAVE ae=d[y[i+4]];WAVE af=d[y[i+5]];WAVE ag=d[y[i+6]];WAVE ah=d[y[i+7]];WAVE ai=d[y[i+8]];WAVE aj=d[y[i+9]];WAVE ak=d[y[i+10]];WAVE al=d[y[i+11]];WAVE am=d[y[i+12]];WAVE an=d[y[i+13]];WAVE ap=d[y[i+14]];WAVE aq=d[y[i+15]];WAVE ar=d[y[i+16]];WAVE a_=d[y[i+17]];WAVE at=d[y[i+18]];WAVE au=d[y[i+19]];WAVE av=d[y[i+20]];WAVE aw=d[y[i+21]];WAVE ax=d[y[i+22]];WAVE ay=d[y[i+23]];WAVE az=d[y[i+24]];WAVE ba=d[y[i+25]];WAVE bb=d[y[i+26]];WAVE bc=d[y[i+27]];WAVE bd=d[y[i+28]];WAVE be=d[y[i+29]];WAVE bf=d[y[i+30]];WAVE bg=d[y[i+31]];WAVE bh=d[y[i+32]];WAVE bi=d[y[i+33]];WAVE bj=d[y[i+34]];WAVE bk=d[y[i+35]];WAVE bl=d[y[i+36]];WAVE bm=d[y[i+37]];WAVE bn=d[y[i+38]];WAVE bp=d[y[i+39]];WAVE bq=d[y[i+40]];WAVE br=d[y[i+41]];WAVE bs=d[y[i+42]];WAVE bt=d[y[i+43]];WAVE bu=d[y[i+44]];WAVE bv=d[y[i+45]];WAVE bw=d[y[i+46]];WAVE bx=d[y[i+47]];WAVE by=d[y[i+48]];WAVE bz=d[y[i+49]];WAVE ca=d[y[i+50]];WAVE cb=d[y[i+51]];WAVE cc=d[y[i+52]];WAVE cd=d[y[i+53]];WAVE ce=d[y[i+54]];WAVE cf=d[y[i+55]];WAVE cg=d[y[i+56]];WAVE ch=d[y[i+57]];WAVE ci=d[y[i+58]];WAVE cj=d[y[i+59]];WAVE ck=d[y[i+60]];WAVE cl=d[y[i+61]];WAVE cm=d[y[i+62]];WAVE cn=d[y[i+63]]
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) aa[0,*;s]/TN=$t[i],ab[0,*;s]/TN=$t[i+1],ac[0,*;s]/TN=$t[i+2],ad[0,*;s]/TN=$t[i+3],ae[0,*;s]/TN=$t[i+4],af[0,*;s]/TN=$t[i+5],ag[0,*;s]/TN=$t[i+6],ah[0,*;s]/TN=$t[i+7],ai[0,*;s]/TN=$t[i+8],aj[0,*;s]/TN=$t[i+9],ak[0,*;s]/TN=$t[i+10],al[0,*;s]/TN=$t[i+11],am[0,*;s]/TN=$t[i+12],an[0,*;s]/TN=$t[i+13],ap[0,*;s]/TN=$t[i+14],aq[0,*;s]/TN=$t[i+15],ar[0,*;s]/TN=$t[i+16],a_[0,*;s]/TN=$t[i+17],at[0,*;s]/TN=$t[i+18],au[0,*;s]/TN=$t[i+19],av[0,*;s]/TN=$t[i+20],aw[0,*;s]/TN=$t[i+21],ax[0,*;s]/TN=$t[i+22],ay[0,*;s]/TN=$t[i+23],az[0,*;s]/TN=$t[i+24],ba[0,*;s]/TN=$t[i+25],bb[0,*;s]/TN=$t[i+26],bc[0,*;s]/TN=$t[i+27],bd[0,*;s]/TN=$t[i+28],be[0,*;s]/TN=$t[i+29],bf[0,*;s]/TN=$t[i+30],bg[0,*;s]/TN=$t[i+31],bh[0,*;s]/TN=$t[i+32],bi[0,*;s]/TN=$t[i+33],bj[0,*;s]/TN=$t[i+34],bk[0,*;s]/TN=$t[i+35],bl[0,*;s]/TN=$t[i+36],bm[0,*;s]/TN=$t[i+37],bn[0,*;s]/TN=$t[i+38],bp[0,*;s]/TN=$t[i+39],bq[0,*;s]/TN=$t[i+40],br[0,*;s]/TN=$t[i+41],bs[0,*;s]/TN=$t[i+42],bt[0,*;s]/TN=$t[i+43],bu[0,*;s]/TN=$t[i+44],bv[0,*;s]/TN=$t[i+45],bw[0,*;s]/TN=$t[i+46],bx[0,*;s]/TN=$t[i+47],by[0,*;s]/TN=$t[i+48],bz[0,*;s]/TN=$t[i+49],ca[0,*;s]/TN=$t[i+50],cb[0,*;s]/TN=$t[i+51],cc[0,*;s]/TN=$t[i+52],cd[0,*;s]/TN=$t[i+53],ce[0,*;s]/TN=$t[i+54],cf[0,*;s]/TN=$t[i+55],cg[0,*;s]/TN=$t[i+56],ch[0,*;s]/TN=$t[i+57],ci[0,*;s]/TN=$t[i+58],cj[0,*;s]/TN=$t[i+59],ck[0,*;s]/TN=$t[i+60],cl[0,*;s]/TN=$t[i+61],cm[0,*;s]/TN=$t[i+62],cn[0,*;s]/TN=$t[i+63]
					break
				case 32:
					WAVE aa=d[y[i]];WAVE ab=d[y[i+1]];WAVE ac=d[y[i+2]];WAVE ad=d[y[i+3]];WAVE ae=d[y[i+4]];WAVE af=d[y[i+5]];WAVE ag=d[y[i+6]];WAVE ah=d[y[i+7]];WAVE ai=d[y[i+8]];WAVE aj=d[y[i+9]];WAVE ak=d[y[i+10]];WAVE al=d[y[i+11]];WAVE am=d[y[i+12]];WAVE an=d[y[i+13]];WAVE ap=d[y[i+14]];WAVE aq=d[y[i+15]];WAVE ar=d[y[i+16]];WAVE a_=d[y[i+17]];WAVE at=d[y[i+18]];WAVE au=d[y[i+19]];WAVE av=d[y[i+20]];WAVE aw=d[y[i+21]];WAVE ax=d[y[i+22]];WAVE ay=d[y[i+23]];WAVE az=d[y[i+24]];WAVE ba=d[y[i+25]];WAVE bb=d[y[i+26]];WAVE bc=d[y[i+27]];WAVE bd=d[y[i+28]];WAVE be=d[y[i+29]];WAVE bf=d[y[i+30]];WAVE bg=d[y[i+31]]
					AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, a) aa[0,*;s]/TN=$t[i],ab[0,*;s]/TN=$t[i+1],ac[0,*;s]/TN=$t[i+2],ad[0,*;s]/TN=$t[i+3],ae[0,*;s]/TN=$t[i+4],af[0,*;s]/TN=$t[i+5],ag[0,*;s]/TN=$t[i+6],ah[0,*;s]/TN=$t[i+7],ai[0,*;s]/TN=$t[i+8],aj[0,*;s]/TN=$t[i+9],ak[0,*;s]/TN=$t[i+10],al[0,*;s]/TN=$t[i+11],am[0,*;s]/TN=$t[i+12],an[0,*;s]/TN=$t[i+13],ap[0,*;s]/TN=$t[i+14],aq[0,*;s]/TN=$t[i+15],ar[0,*;s]/TN=$t[i+16],a_[0,*;s]/TN=$t[i+17],at[0,*;s]/TN=$t[i+18],au[0,*;s]/TN=$t[i+19],av[0,*;s]/TN=$t[i+20],aw[0,*;s]/TN=$t[i+21],ax[0,*;s]/TN=$t[i+22],ay[0,*;s]/TN=$t[i+23],az[0,*;s]/TN=$t[i+24],ba[0,*;s]/TN=$t[i+25],bb[0,*;s]/TN=$t[i+26],bc[0,*;s]/TN=$t[i+27],bd[0,*;s]/TN=$t[i+28],be[0,*;s]/TN=$t[i+29],bf[0,*;s]/TN=$t[i+30],bg[0,*;s]/TN=$t[i+31]
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
					FATAL_ERROR( "Fail")
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
					FATAL_ERROR( "Fail")
					break
			endswitch
		while(i)
	endif

	// IPT_FORMAT_ON

End
