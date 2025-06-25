#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_BROWSER_PLOTTER
#endif // AUTOMATED_TESTING

/// @file MIES_Browser_Plotter.ipf
/// @brief Functions for plotting DataBrowser/Sweepbrowser Graphs

static Constant NUM_CHANNEL_TYPES     = 3
static Constant ADC_SLOT_MULTIPLIER   = 4
static Constant EPOCH_SLOT_MULTIPLIER = 3

/// @brief Get all selected oodDAQ regions and the total X range in ms
static Function [string oodDAQRegionsAll, variable totalXRange] GetOodDAQFullRange(STRUCT TiledGraphSettings &tgs, WAVE/T oodDAQRegions)

	variable i, j, numEntries, numRangesPerEntry, xRangeStart, xRangeEnd
	string entry, range, str

	numEntries       = DimSize(oodDAQRegions, ROWS)
	oodDAQRegionsAll = ""
	totalXRange      = 0

	// Fixup buggy entries introduced since 88323d8d (Replacement of oodDAQ offset calculation routines, 2019-06-13)
	// The regions from the second active headstage are duplicated into the
	// first region in case we had more than two active headstages taking part in oodDAQ.
	WAVE/Z indizes = FindIndizes(oodDAQRegions, prop = PROP_EMPTY | PROP_NOT)
	if(WaveExists(indizes) && DimSize(indizes, ROWS) > 2)
		oodDAQRegions[indizes[0]] = ReplaceString(oodDAQRegions[indizes[1]], oodDAQRegions[indizes[0]], "")
	endif

	for(i = 0; i < numEntries; i += 1)

		// we still gather regions from deselected headstages to help overlaying multiple sweeps with the same
		// oodDAQ regions and removed headstages.
		// If we would remove them here the plotting would get messed up.

		// use only the selected region if requested
		if(tgs.dDAQHeadstageRegions >= 0 && tgs.dDAQHeadstageRegions < NUM_HEADSTAGES && tgs.dDAQHeadstageRegions != i)
			continue
		endif

		entry             = RemoveEnding(oodDAQRegions[i], ";")
		numRangesPerEntry = ItemsInList(entry)
		for(j = 0; j < numRangesPerEntry; j += 1)
			range            = StringFromList(j, entry)
			oodDAQRegionsAll = AddListItem(range, oodDAQRegionsAll, ";", Inf)

			xRangeStart  = NumberFromList(0, range, sep = "-")
			xRangeEnd    = NumberFromList(1, range, sep = "-")
			totalXRange += (xRangeEnd - XRangeStart)
		endfor
	endfor

	sprintf str, "oodDAQRegions (%d) concatenated: _%s_, totalRange=%g", ItemsInList(oodDAQRegionsAll), oodDAQRegionsAll, totalXRange
	DEBUGPRINT(str)

	return [oodDAQRegionsAll, totalXRange]
End

/// @brief Create a vertically tiled graph for displaying AD and DA channels
///
/// For preservering the axis scaling callers should do the following:
/// \rst
/// .. code-block:: igorpro
///
/// 	WAVE ranges = GetAxesRanges(graph)
///
/// 	CreateTiledChannelGraph()
///
///		SetAxesRanges(graph, ranges)
///	\endrst
///
/// @param graph           window
/// @param config          DAQ config wave
/// @param sweepNo         number of the sweep
/// @param numericalValues numerical labnotebook wave
/// @param textualValues   textual labnotebook wave
/// @param tgs             settings for tuning the display, see @ref TiledGraphSettings
/// @param sweepDFR        top datafolder to splitted 1D sweep waves
/// @param axisLabelCache  store existing vertical axis labels
/// @param traceIndex      [internal use only] set to zero on the first call in a row of successive calls
/// @param experiment      name of the experiment the sweep stems from
/// @param channelSelWave  channel selection wave
/// @param device          device name
/// @param bdi [optional, default = n/a] initialized BufferedDrawInfo structure, when given draw calls are buffered instead for later execution @sa OVS_EndIncrementalUpdate
/// @param mapIndex [optional, default = NaN] if the data originates from a sweepBrowser then the mapIndex is given here
Function CreateTiledChannelGraph(string graph, WAVE config, variable sweepNo, WAVE numericalValues, WAVE/T textualValues, STRUCT TiledGraphSettings &tgs, DFREF sweepDFR, WAVE/T axisLabelCache, variable &traceIndex, string experiment, WAVE channelSelWave, string device, [STRUCT BufferedDrawInfo &bdi, variable mapIndex])

	variable axisIndex, numChannels
	variable numDACs, numADCs, numTTLs, i, j, k, hasPhysUnit, hardwareType
	variable moreData, chan, guiChannelNumber, numHorizWaves, numVertWaves, idx
	variable numTTLBits, headstage, channelType, isTTLSplitted
	variable delayOnsetUser, delayOnsetAuto, delayTermination, delaydDAQ, dDAQEnabled, oodDAQEnabled
	variable stimSetLength, samplingIntDA, samplingIntSweep, samplingIntervalFactor, first, last, count, ttlBit
	variable numRegions, numRangesPerEntry, traceCounter
	variable xRangeStartMS, xRangeEndMS
	variable totalRangeDAPoints, rangeStartDAPoints, rangeEndDAPoints
	variable startIndexSweep, endIndexSweep
	variable totalOodRangeMS = NaN
	string trace, traceType, channelID, axisLabel, traceRange, traceColor
	string unit, name, str, vertAxis, oodDAQRegionsAll, dDAQActiveHeadstageAll, horizAxis, freeAxis, jsonPath
	STRUCT RGBColor s

	ASSERT(!isEmpty(graph), "Empty graph")
	ASSERT(IsFinite(sweepNo), "Non-finite sweepNo")
	mapIndex = ParamIsDefault(mapIndex) ? NaN : mapIndex

	Make/T/FREE userDataKeys = {"fullPath", "channelType", "channelNumber", "sweepNumber", "headstage",                                                    \
	                            "textualValues", "numericalValues", "clampMode", "TTLBit", "experiment", "traceType",                                      \
	                            "occurence", "XAXIS", "YAXIS", "YRANGE", "TRACECOLOR", "AssociatedHeadstage", "GUIChannelNumber", "Device", "SweepMapIndex"}

	WAVE ADCs = GetADCListFromConfig(config)
	WAVE DACs = GetDACListFromConfig(config)
	WAVE TTLs = GetTTLListFromConfig(config)

	// 602debb9 (Record the active headstage in the settingsHistory, 2014-11-04)
	WAVE/Z/D statusHS = GetLastSetting(numericalValues, sweepNo, "Headstage Active", DATA_ACQUISITION_MODE)
	if(!WaveExists(statusHS))
		// 5872e556 (Modified files: DR_MIES_TangoInteract:  changes recommended by Thomas ..., 2014-09-11)
		WAVE/Z DACsFromLBN = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)
		ASSERT_TS(WaveExists(DACsFromLBN), "Labnotebook is too old for workaround.")

		// 5872e556 (Modified files: DR_MIES_TangoInteract:  changes recommended by Thomas ..., 2014-09-11)
		WAVE/Z ADCsFromLBN = GetLastSetting(numericalValues, sweepNo, "ADC", DATA_ACQUISITION_MODE)
		ASSERT_TS(WaveExists(ADCsFromLBN), "Labnotebook is too old for workaround.")

		WAVE statusHS = LBN_GetNumericWave()
		// 562439857 (Introduce a nineth layer in the labnotebooks for storing headstage independent data, 2015-10-28)
		statusHS[0, NUM_HEADSTAGES - 1] = IsFinite(ADCsFromLBN[p]) && IsFinite(DACsFromLBN[p])
	endif

	BSP_RemoveDisabledChannels(channelSelWave, ADCs, DACs, statusHS, numericalValues, sweepNo)

	numDACs = DimSize(DACs, ROWS)
	numADCs = DimSize(ADCs, ROWS)
	numTTLs = DimSize(TTLs, ROWS)
	if(numTTLs > 0)
		WAVE/Z channelMapHWToGUI = GetActiveChannels(numericalValues, textualValues, sweepNo, XOP_CHANNEL_TYPE_TTL, TTLmode = TTL_HWTOGUI_CHANNEL)
		ASSERT(WaveExists(channelMapHWToGUI), "Can not find LNB entries for active TTL channels from config wave.")
	endif

	hardwareType = GetUsedHWDACFromLNB(numericalValues, sweepNo)
	WAVE/Z ttlRackZeroBits = GetLastSetting(numericalValues, sweepNo, "TTL rack zero bits", DATA_ACQUISITION_MODE)
	WAVE/Z ttlRackOneBits  = GetLastSetting(numericalValues, sweepNo, "TTL rack one bits", DATA_ACQUISITION_MODE)

	if(tgs.splitTTLBits && numTTLs > 0)
		if(!WaveExists(ttlRackZeroBits) && !WaveExists(ttlRackOneBits) && hardwareType == HARDWARE_ITC_DAC)
			print "Turning off tgs.splitTTLBits as some labnotebook entries could not be found"
			ControlWindowToFront()
			tgs.splitTTLBits = 0
		elseif(hardwareType == HARDWARE_NI_DAC || hardwareType == HARDWARE_SUTTER_DAC)
			// NI hardware does use one channel per bit so we don't need that here
			tgs.splitTTLBits = 0
		endif

		if(tgs.splitTTLBits)
			idx = GetIndexForHeadstageIndepData(numericalValues)
			if(WaveExists(ttlRackZeroBits))
				numTTLBits += PopCount(ttlRackZeroBits[idx])
			endif
			if(WaveExists(ttlRackOneBits))
				numTTLBits += PopCount(ttlRackOneBits[idx])
			endif
		endif
	endif

	dDAQEnabled   = GetLastSettingIndep(numericalValues, sweepNo, "Distributed DAQ", DATA_ACQUISITION_MODE, defValue = 0)
	oodDAQEnabled = GetLastSettingIndep(numericalValues, sweepNo, "Optimized Overlap dDAQ", DATA_ACQUISITION_MODE, defValue = 0)

	if(tgs.dDAQDisplayMode && !(dDAQEnabled || oodDAQEnabled))
		printf "Distributed DAQ display mode turned off as no dDAQ data could be found.\r"
		tgs.dDAQDisplayMode = 0
	endif

	WAVE/Z/T oodDAQRegions = GetLastSetting(textualValues, sweepNo, "oodDAQ regions", DATA_ACQUISITION_MODE)

	if(tgs.dDAQDisplayMode && oodDAQEnabled && !WaveExists(oodDAQRegions))
		printf "Distributed DAQ display mode turned off as no oodDAQ regions could be found in the labnotebook.\r"
		tgs.dDAQDisplayMode = 0
	endif

	samplingIntDA = GetSamplingInterval(config, XOP_CHANNEL_TYPE_DAC) * MICRO_TO_MILLI
	if(tgs.dDAQDisplayMode)

		// dDAQ data taken with versions prior to
		// 778969b0 (DC_PlaceDataInITCDataWave: Document all other settings from the DAQ groupbox, 2015-11-26)
		// does not have the delays stored in the labnotebook
		delayOnsetUser   = GetLastSettingIndep(numericalValues, sweepNo, "Delay onset user", DATA_ACQUISITION_MODE, defValue = 0) / samplingIntDA
		delayOnsetAuto   = GetLastSettingIndep(numericalValues, sweepNo, "Delay onset auto", DATA_ACQUISITION_MODE, defValue = 0) / samplingIntDA
		delayTermination = GetLastSettingIndep(numericalValues, sweepNo, "Delay termination", DATA_ACQUISITION_MODE, defValue = 0) / samplingIntDA
		delaydDAQ        = GetLastSettingIndep(numericalValues, sweepNo, "Delay distributed DAQ", DATA_ACQUISITION_MODE, defValue = 0) / samplingIntDA

		sprintf str, "delayOnsetUser=%g, delayOnsetAuto=%g, delayTermination=%g, delaydDAQ=%g", delayOnsetUser, delayOnsetAuto, delayTermination, delaydDAQ
		DEBUGPRINT(str)

		if(oodDAQEnabled)
			[oodDAQRegionsAll, totalOodRangeMS] = GetOodDAQFullRange(tgs, oodDAQRegions)
			totalRangeDAPoints                  = totalOodRangeMS / samplingIntDA
			numRegions                          = ItemsInList(oodDAQRegionsAll)
		else
			stimSetLength = GetLastSettingIndep(numericalValues, sweepNo, "Stim set length", DATA_ACQUISITION_MODE)
			DEBUGPRINT("Stim set length (labnotebook, NaN for oodDAQ)", var = stimSetLength)

			dDAQActiveHeadstageAll = ""

			for(i = 0; i < NUM_HEADSTAGES; i += 1)

				if(!statusHS[i])
					continue
				endif

				if(tgs.dDAQHeadstageRegions >= 0 && tgs.dDAQHeadstageRegions < NUM_HEADSTAGES && tgs.dDAQHeadstageRegions != i)
					continue
				endif

				dDAQActiveHeadstageAll = AddListItem(num2str(i), dDAQActiveHeadstageAll, ";", Inf)
			endfor

			numRegions = ItemsInList(dDAQActiveHeadstageAll)
			sprintf str, "dDAQRegions (%d) concatenated: _%s_", numRegions, dDAQActiveHeadstageAll
			DEBUGPRINT(str)
		endif
	endif

	// Added in a2220e9f (Add the clamp mode to the labnotebook for acquired data, 2015-04-26)
	WAVE/Z clampModes = GetLastSetting(numericalValues, sweepNo, CLAMPMODE_ENTRY_KEY, DATA_ACQUISITION_MODE)

	if(!WaveExists(clampModes))
		WAVE/Z clampModes = GetLastSetting(numericalValues, sweepNo, "Operating Mode", DATA_ACQUISITION_MODE)
		ASSERT(WaveExists(clampModes), "Labnotebook is too old for display.")
	endif

	WAVE/Z statusDAC = GetLastSetting(numericalValues, sweepNo, "DAC", DATA_ACQUISITION_MODE)
	WAVE/Z statusADC = GetLastSetting(numericalValues, sweepNo, "ADC", DATA_ACQUISITION_MODE)

	// introduced in 18e1406b (Labnotebook: Add DA/AD ChannelType, 2019-02-15)
	WAVE/Z daChannelType = GetLastSetting(numericalValues, sweepNo, "DA ChannelType", DATA_ACQUISITION_MODE)
	WAVE/Z adChannelType = GetLastSetting(numericalValues, sweepNo, "AD ChannelType", DATA_ACQUISITION_MODE)

	MAKE/FREE/B/N=(NUM_CHANNEL_TYPES) channelTypes
	channelTypes[0] = XOP_CHANNEL_TYPE_DAC
	channelTypes[1] = XOP_CHANNEL_TYPE_ADC
	channelTypes[2] = XOP_CHANNEL_TYPE_TTL

	MAKE/FREE/B/N=(NUM_CHANNEL_TYPES) activeChanCount = 0

	if(!ParamIsDefault(bdi))
		traceCounter = GetNumberFromWaveNote(bdi.traceWaves, NOTE_INDEX)
	endif

	do
		moreData = 0
		// iterate over all channel types in order DA, AD, TTL
		// and take the first active channel from the list of channels per type
		for(i = 0; i < NUM_CHANNEL_TYPES; i += 1)
			channelType = channelTypes[i]
			switch(channelType)
				case XOP_CHANNEL_TYPE_DAC:
					if(!tgs.displayDAC)
						continue
					endif

					WAVE/Z status      = statusDAC
					WAVE   channelList = DACs
					channelID     = "DA"
					hasPhysUnit   = 1
					numHorizWaves = tgs.dDAQDisplayMode ? numRegions : 1
					numVertWaves  = 1
					numChannels   = numDACs
					break
				case XOP_CHANNEL_TYPE_ADC:
					if(!tgs.displayADC)
						continue
					endif

					WAVE/Z status      = statusADC
					WAVE   channelList = ADCs
					channelID     = "AD"
					hasPhysUnit   = 1
					numHorizWaves = tgs.dDAQDisplayMode ? numRegions : 1
					numVertWaves  = 1
					numChannels   = numADCs
					break
				case XOP_CHANNEL_TYPE_TTL:
					if(!tgs.displayTTL                                      \
					   || (tgs.displayDAC && numDACs != activeChanCount[0]) \
					   || (tgs.displayADC && numADCs != activeChanCount[1]))
						continue
					endif

					WAVE/Z status      = $""
					WAVE   channelList = TTLs
					channelID     = "TTL"
					hasPhysUnit   = 0
					numHorizWaves = 1

					if(hardwareType == HARDWARE_ITC_DAC)
						numVertWaves  = tgs.splitTTLBits ? NUM_ITC_TTL_BITS_PER_RACK : 1
						isTTLSplitted = tgs.splitTTLBits
					else
						numVertWaves  = 1
						isTTLSplitted = 1
					endif

					numChannels = numTTLs
					break
				default:
					ASSERT(0, "Unsupported channel type")
					break
			endswitch

			if(DimSize(channelList, ROWS) == 0)
				continue
			endif

			moreData = 1
			chan     = channelList[0]
			DeletePoints/M=(ROWS) 0, 1, channelList

			if(WaveExists(status))
				headstage = GetRowIndex(status, val = chan)
			else
				headstage = NaN
			endif

			// ignore TP during DAQ channels
			if(WaveExists(status) && IsValidHeadstage(headstage))
				if(channelType == XOP_CHANNEL_TYPE_DAC                \
				   && WaveExists(daChannelType)                       \
				   && daChannelType[headstage] != DAQ_CHANNEL_TYPE_DAQ)
					activeChanCount[i] += 1
					continue
				elseif(channelType == XOP_CHANNEL_TYPE_ADC                \
				       && WaveExists(adChannelType)                       \
				       && adChannelType[headstage] != DAQ_CHANNEL_TYPE_DAQ)
					activeChanCount[i] += 1
					continue
				endif
			endif

			if(!ParamIsDefault(bdi))
				EnsureLargeEnoughWave(bdi.traceWaves, indexShouldExist = traceCounter + numVertWaves * numHorizWaves)
			endif

			// number of vertically distributed
			// waves per channel type
			for(j = 0; j < numVertWaves; j += 1)

				ttlBit = (channelType == XOP_CHANNEL_TYPE_TTL && tgs.splitTTLBits) ? j : NaN

				if(channelType == XOP_CHANNEL_TYPE_TTL)
					guiChannelNumber = channelMapHWToGUI[chan][IsNaN(ttlBit) ? 0 : ttlBit]
				else
					guiChannelNumber = chan
				endif
				name = channelID + num2istr(guiChannelNumber)

				DFREF singleSweepDFR = GetSingleSweepFolder(sweepDFR, sweepNo)

				ASSERT(DataFolderExistsDFR(singleSweepDFR), "Missing singleSweepDFR")

				WAVE/Z wv = GetDAQDataSingleColumnWave(singleSweepDFR, channelType, chan, splitTTLBits = tgs.splitTTLBits, ttlBit = j)
				if(!WaveExists(wv))
					continue
				endif
				samplingIntSweep = GetSamplingInterval(config, channelType) * MICRO_TO_MILLI

				// Color scheme:
				// 0-7:   Different headstages
				// 8:     Unknown headstage
				// 9:     Averaged trace
				// 10:    TTL bits (sum) rack zero
				// 11-14: TTL bits (single) rack zero
				// 15:    TTL bits (sum) rack one
				// 16-19: TTL bits (single) rack one

				[s]   = GetHeadstageColor(headstage, channelType = channelType, channelNumber = guiChannelNumber, isSplitted = isTTLSplitted)
				first = 0

				// number of horizontally distributed
				// waves per channel type
				for(k = 0; k < numHorizWaves; k += 1)

					vertAxis = VERT_AXIS_BASE_NAME + num2str(j) + "_" + HORIZ_AXIS_BASE_NAME + num2str(k) + "_" + channelID

					if(!tgs.overlayChannels)
						vertAxis += "_" + num2str(chan)
						traceType = name
						if(!cmpstr(channelID, "TTL"))
							if(tgs.splitTTLBits)
								vertAxis += "_" + num2str(j)
							else
								vertAxis += "_NaN"
							endif
						endif
					else
						traceType = channelID
					endif

					if(!tgs.overlayChannels)
						vertAxis += "_HS_" + num2str(headstage)
					endif

					if(tgs.dDAQDisplayMode && channelType != XOP_CHANNEL_TYPE_TTL) // TTL channels don't have dDAQ mode

						if(dDAQEnabled)
							// fallback to manual calculation
							// for versions prior to bb2d2bd6 (DC_PlaceDataInITCDataWave: Document stim set length, 2016-05-12)
							if(!IsFinite(stimSetLength))
								stimSetLength = (DimSize(wv, ROWS) - (delayOnsetUser + delayOnsetAuto + delayTermination + delaydDAQ * (numADCs - 1))) / numADCs
								DEBUGPRINT("Stim set length (manually calculated)", var = stimSetLength)
							endif

							rangeStartDAPoints = delayOnsetUser + delayOnsetAuto + NumberFromList(k, dDAQActiveHeadstageAll) * (stimSetLength + delaydDAQ)
							rangeEndDAPoints   = rangeStartDAPoints + stimSetLength

							// initial total x range once, the stimsets have all the same length for dDAQ
							if(!IsFinite(totalRangeDAPoints))
								totalRangeDAPoints = (rangeEndDAPoints - rangeStartDAPoints) * numHorizWaves
							endif
						elseif(oodDAQEnabled)
							/// @sa GetSweepSettingsTextKeyWave for the format
							/// we need points here with taking the onset delays into account
							xRangeStartMS = NumberFromList(0, StringFromList(k, oodDAQRegionsAll, ";"), sep = "-")
							xRangeEndMS   = NumberFromList(1, StringFromList(k, oodDAQRegionsAll, ";"), sep = "-")

							sprintf str, "begin[ms] = %g, end[ms] = %g", xRangeStartMS, xRangeEndMS
							DEBUGPRINT(str)

							rangeStartDAPoints = delayOnsetUser + delayOnsetAuto + xRangeStartMS / samplingIntDA
							rangeEndDAPoints   = delayOnsetUser + delayOnsetAuto + xRangeEndMS / samplingIntDA
						endif

						rangeStartDAPoints = floor(rangeStartDAPoints)
						rangeEndDAPoints   = ceil(rangeEndDAPoints)
					else
						rangeStartDAPoints = NaN
						rangeEndDAPoints   = NaN
					endif

					trace       = GetTraceNamePrefix(traceIndex)
					traceIndex += 1

					sprintf str, "i=%d, j=%d, k=%d, vertAxis=%s, traceType=%s, name=%s", i, j, k, vertAxis, traceType, name
					DEBUGPRINT(str)

					sprintf traceColor, "(%d, %d, %d, %d)", s.red, s.green, s.blue, 65535

					if(!IsFinite(rangeStartDAPoints) && !IsFinite(rangeEndDAPoints))
						horizAxis  = "bottom"
						traceRange = "[][0]"

						if(ParamIsDefault(bdi))
							AppendToGraph/W=$graph/B=$horizAxis/L=$vertAxis/C=(s.red, s.green, s.blue, 65535) wv[][0]/TN=$trace
						else
							bdi.traceWaves[traceCounter] = wv
							jsonPath                     = BUFFEREDDRAWAPPEND + "/" + graph + "/" + vertAxis + "/" + horizAxis + "/" + num2str(s.red) + "/" + num2str(s.green) + "/" + num2str(s.blue) + "/"
							JSON_AddTreeArray(bdi.jsonID, jsonPath + "index")
							JSON_AddTreeArray(bdi.jsonID, jsonPath + "traceName")
							JSON_AddVariable(bdi.jsonID, jsonPath + "index", traceCounter)
							JSON_AddString(bdi.jsonID, jsonPath + "traceName", trace)
							traceCounter += 1
						endif
					else
						samplingIntervalFactor = samplingIntDA / samplingIntSweep
						startIndexSweep        = rangeStartDAPoints * samplingIntervalFactor
						endIndexSweep          = rangeEndDAPoints * samplingIntervalFactor

						horizAxis = vertAxis + "_b"
						sprintf traceRange, "[%d,%d][0]", startIndexSweep, endIndexSweep
						AppendToGraph/W=$graph/L=$vertAxis/B=$horizAxis/C=(s.red, s.green, s.blue, 65535) wv[startIndexSweep, endIndexSweep][0]/TN=$trace
						first = first
						last  = first + (rangeEndDAPoints - rangeStartDAPoints) / totalRangeDAPoints
						ModifyGraph/W=$graph axisEnab($horizAxis)={first, min(last, 1.0)}
						first += (rangeEndDAPoints - rangeStartDAPoints) / totalRangeDAPoints

						sprintf str, "horiz axis: stimset=[%d, %d] aka (%g, %g)", rangeStartDAPoints, rangeEndDAPoints, pnt2x(wv, rangeStartDAPoints), pnt2x(wv, rangeEndDAPoints)
						DEBUGPRINT(str)
					endif

					if(k == 0) // first column, add labels
						if(hasPhysUnit)
							unit = AFH_GetChannelUnit(config, chan, channelType)
						else
							unit = "logical"
						endif

						axisLabel = "\Zr085" + traceType + "\r(" + unit + ")"

						FindValue/TXOP=4/TEXT=(vertAxis) axisLabelCache
						axisIndex = V_Value
						if(axisIndex != -1 && cmpstr(axisLabelCache[axisIndex][%Lbl], axisLabel))
							axisLabel                    = channelID + "?\r(a. u.)"
							axisLabelCache[axisIndex][1] = axisLabel
						endif

						if(axisIndex == -1) // create new entry
							count = GetNumberFromWaveNote(axisLabelCache, NOTE_INDEX)
							EnsureLargeEnoughWave(axisLabelCache, indexShouldExist = count)
							axisLabelCache[count][%Axis] = vertAxis
							axisLabelCache[count][%Lbl]  = axisLabel
							SetNumberInWaveNote(axisLabelCache, NOTE_INDEX, count + 1)
						endif
					else
						axisLabel = "\\u#2"
					endif

					if(ParamIsDefault(bdi))
						Label/W=$graph $vertAxis, axisLabel
					else
						jsonPath = BUFFEREDDRAWLABEL + "/" + graph + "/" + vertAxis + "/" + axisLabel
						JSON_AddTreeObject(bdi.jsonID, jsonPath)
					endif

					if(tgs.dDAQDisplayMode)
						if(ParamIsDefault(bdi))
							ModifyGraph/W=$graph freePos($vertAxis)={1 / numHorizWaves * k, kwFraction}, freePos($horizAxis)={0, $vertAxis}
						else
							jsonPath = BUFFEREDDRAWDDAQAXES + "/" + graph + "/" + vertAxis + "/" + horizAxis + "/" + num2str(1 / numHorizWaves * k)
							JSON_AddTreeObject(bdi.jsonID, jsonPath)
						endif
					endif

					if(tgs.hideSweep)
						if(ParamIsDefault(bdi))
							ModifyGraph/W=$graph hideTrace($trace)=1
						else
							jsonPath = BUFFEREDDRAWHIDDENTRACES + "/" + graph
							JSON_AddTreeArray(bdi.jsonID, jsonPath)
							JSON_AddString(bdi.jsonID, jsonPath, trace)
						endif
					endif

					TUD_SetUserDataFromWaves(graph, trace, userDataKeys,                                                                                \
					                         {GetWavesDataFolder(wv, 2), channelID, num2str(chan), num2str(sweepNo), num2str(headstage),                \
					                          GetWavesDataFolder(textualValues, 2), GetWavesDataFolder(numericalValues, 2),                             \
					                          num2str(IsValidHeadstage(headstage) ? clampModes[headstage] : NaN), num2str(ttlBit), experiment, "Sweep", \
					                          num2str(k), horizAxis, vertAxis, traceRange, traceColor, num2istr(IsValidHeadstage(headstage)),           \
					                          num2istr(guiChannelNumber), device, num2str(mapIndex)})
				endfor
			endfor

			activeChanCount[i] += 1
		endfor
	while(moreData)

	if(!ParamIsDefault(bdi))
		SetNumberInWaveNote(bdi.traceWaves, NOTE_INDEX, traceCounter)
	endif
End

///@brief Runs through all graph groups in the json and appends them to the graph
Function TiledGraphAccelerateDraw(STRUCT BufferedDrawInfo &bdi)

	string graph, vertAxis, horizAxis, redStr, greenStr, blueStr, axisLabel
	variable numGraphs, numVertAxis, numHorizAxis, numRed, numGreen, numBlue, numAxisLabel, numFractions
	variable red, green, blue
	variable i0, i1, i2, i3, i4, i5
	string i0Path, i1Path, i2Path, i3Path, i4Path, i5Path

	WAVE/T wGraphs = JSON_GetKeys(bdi.jsonID, BUFFEREDDRAWAPPEND)
	numGraphs = DimSize(wGraphs, ROWS)
	for(i0 = 0; i0 < numGraphs; i0 += 1)
		graph  = wGraphs[i0]
		i0Path = BUFFEREDDRAWAPPEND + "/" + graph
		WAVE/T wVertAxis = JSON_GetKeys(bdi.jsonID, i0Path)
		numVertAxis = DimSize(wVertAxis, ROWS)
		for(i1 = 0; i1 < numVertAxis; i1 += 1)
			vertAxis = wVertAxis[i1]
			i1Path   = i0Path + "/" + vertAxis
			WAVE/T wHorizAxis = JSON_GetKeys(bdi.jsonID, i1Path)
			numHorizAxis = DimSize(wHorizAxis, ROWS)
			for(i2 = 0; i2 < numHorizAxis; i2 += 1)
				horizAxis = wHorizAxis[i2]
				i2Path    = i1Path + "/" + horizAxis
				WAVE/T wRed = JSON_GetKeys(bdi.jsonID, i2Path)
				numRed = DimSize(wRed, ROWS)
				for(i3 = 0; i3 < numRed; i3 += 1)
					redStr = wRed[i3]
					red    = str2num(redStr)
					i3Path = i2Path + "/" + redStr
					WAVE/T wGreen = JSON_GetKeys(bdi.jsonID, i3Path)
					numGreen = DimSize(wGreen, ROWS)
					for(i4 = 0; i4 < numGreen; i4 += 1)
						greenStr = wGreen[i4]
						green    = str2num(greenStr)
						i4Path   = i3Path + "/" + greenStr
						WAVE/T wBlue = JSON_GetKeys(bdi.jsonID, i4Path)
						numBlue = DimSize(wBlue, ROWS)
						for(i5 = 0; i5 < numBlue; i5 += 1)
							blueStr = wBlue[i5]
							blue    = str2num(blueStr)
							i5Path  = i4Path + "/" + blueStr
							WAVE   indices    = JSON_GetWave(bdi.jsonID, i5Path + "/index")
							WAVE/T traceNames = JSON_GetTextWave(bdi.jsonID, i5Path + "/traceName")
							TiledGraphAccelerateAppendTracesImpl(graph, vertAxis, horizAxis, red, green, blue, indices, traceNames, bdi.traceWaves)
						endfor
					endfor
				endfor
			endfor
		endfor
	endfor

	WAVE/T wGraphs = JSON_GetKeys(bdi.jsonID, BUFFEREDDRAWDDAQAXES)
	numGraphs = DimSize(wGraphs, ROWS)
	for(i0 = 0; i0 < numGraphs; i0 += 1)
		graph  = wGraphs[i0]
		i0Path = BUFFEREDDRAWDDAQAXES + "/" + graph
		WAVE/T wVertAxis = JSON_GetKeys(bdi.jsonID, i0Path)
		numVertAxis = DimSize(wVertAxis, ROWS)
		for(i1 = 0; i1 < numVertAxis; i1 += 1)
			vertAxis = wVertAxis[i1]
			i1Path   = i0Path + "/" + vertAxis
			WAVE/T wHorizAxis = JSON_GetKeys(bdi.jsonID, i1Path)
			numHorizAxis = DimSize(wHorizAxis, ROWS)
			for(i2 = 0; i2 < numHorizAxis; i2 += 1)
				horizAxis = wHorizAxis[i2]
				i2Path    = i1Path + "/" + horizAxis
				WAVE/T wFractions = JSON_GetKeys(bdi.jsonID, i2Path)
				numFractions = DimSize(wHorizAxis, ROWS)
				for(i3 = 0; i3 < numFractions; i3 += 1)
					ModifyGraph/W=$graph freePos($vertAxis)={str2num(wFractions[i3]), kwFraction}, freePos($horizAxis)={0, $vertAxis}
				endfor
			endfor
		endfor
	endfor

	WAVE/T wGraphs = JSON_GetKeys(bdi.jsonID, BUFFEREDDRAWHIDDENTRACES)
	numGraphs = DimSize(wGraphs, ROWS)
	for(i0 = 0; i0 < numGraphs; i0 += 1)
		graph  = wGraphs[i0]
		i0Path = BUFFEREDDRAWHIDDENTRACES + "/" + graph
		WAVE/T hiddenTracesNames = JSON_GetTextWave(bdi.jsonID, i0Path)
		ACC_HideTraces(graph, hiddenTracesNames, DimSize(hiddenTracesNames, ROWS), 1)
	endfor

	WAVE/T wGraphs = JSON_GetKeys(bdi.jsonID, BUFFEREDDRAWLABEL)
	numGraphs = DimSize(wGraphs, ROWS)
	for(i0 = 0; i0 < numGraphs; i0 += 1)
		graph  = wGraphs[i0]
		i0Path = BUFFEREDDRAWLABEL + "/" + graph
		WAVE/T wVertAxis = JSON_GetKeys(bdi.jsonID, i0Path)
		numVertAxis = DimSize(wVertAxis, ROWS)
		for(i1 = 0; i1 < numVertAxis; i1 += 1)
			vertAxis = wVertAxis[i1]
			i1Path   = i0Path + "/" + vertAxis
			WAVE/T wAxisLabel = JSON_GetKeys(bdi.jsonID, i1Path)
			numAxisLabel = DimSize(wAxisLabel, ROWS)
			for(i2 = 0; i2 < numAxisLabel; i2 += 1)
				axisLabel = wAxisLabel[i2]
				Label/W=$graph $vertAxis, axisLabel
			endfor
		endfor
	endfor

	JSON_Release(bdi.jsonID)
End

///@brief Appends a group of traces to a graph, properties w to b must be constant for the group
///@param[in] w name of graph window
///@param[in] v name of vertical axis
///@param[in] h name of horizontal axis
///@param[in] r red color component
///@param[in] g green color component
///@param[in] b blue color component
///@param[in] y 1D wave with indices into wave d for the actual plot data
///@param[in] t 1D wave with trace names, same size as y
///@param[in] d wave reference wave with plot data
static Function TiledGraphAccelerateAppendTracesImpl(string w, string v, string h, variable r, variable g, variable b, WAVE y, WAVE/T t, WAVE/WAVE d)

	// IPT_FORMAT_OFF

	variable step, i
	i = DimSize(y, ROWS)
	do
		step = min(2 ^ trunc(log(i) / log(2)), 100)
		i -= step
		switch(step)
			case 100:
				AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, 65535) d[y[i]]/TN=$t[i],d[y[i+1]]/TN=$t[i+1],d[y[i+2]]/TN=$t[i+2],d[y[i+3]]/TN=$t[i+3],d[y[i+4]]/TN=$t[i+4],d[y[i+5]]/TN=$t[i+5],d[y[i+6]]/TN=$t[i+6],d[y[i+7]]/TN=$t[i+7],d[y[i+8]]/TN=$t[i+8],d[y[i+9]]/TN=$t[i+9],d[y[i+10]]/TN=$t[i+10],d[y[i+11]]/TN=$t[i+11],d[y[i+12]]/TN=$t[i+12],d[y[i+13]]/TN=$t[i+13],d[y[i+14]]/TN=$t[i+14],d[y[i+15]]/TN=$t[i+15],d[y[i+16]]/TN=$t[i+16],d[y[i+17]]/TN=$t[i+17],d[y[i+18]]/TN=$t[i+18],d[y[i+19]]/TN=$t[i+19],d[y[i+20]]/TN=$t[i+20],d[y[i+21]]/TN=$t[i+21],d[y[i+22]]/TN=$t[i+22],d[y[i+23]]/TN=$t[i+23],d[y[i+24]]/TN=$t[i+24],d[y[i+25]]/TN=$t[i+25],d[y[i+26]]/TN=$t[i+26],d[y[i+27]]/TN=$t[i+27],d[y[i+28]]/TN=$t[i+28],d[y[i+29]]/TN=$t[i+29],d[y[i+30]]/TN=$t[i+30],d[y[i+31]]/TN=$t[i+31],d[y[i+32]]/TN=$t[i+32],d[y[i+33]]/TN=$t[i+33],d[y[i+34]]/TN=$t[i+34],d[y[i+35]]/TN=$t[i+35],d[y[i+36]]/TN=$t[i+36],d[y[i+37]]/TN=$t[i+37],d[y[i+38]]/TN=$t[i+38],d[y[i+39]]/TN=$t[i+39],d[y[i+40]]/TN=$t[i+40],d[y[i+41]]/TN=$t[i+41],d[y[i+42]]/TN=$t[i+42],d[y[i+43]]/TN=$t[i+43],d[y[i+44]]/TN=$t[i+44],d[y[i+45]]/TN=$t[i+45],d[y[i+46]]/TN=$t[i+46],d[y[i+47]]/TN=$t[i+47],d[y[i+48]]/TN=$t[i+48],d[y[i+49]]/TN=$t[i+49],d[y[i+50]]/TN=$t[i+50],d[y[i+51]]/TN=$t[i+51],d[y[i+52]]/TN=$t[i+52],d[y[i+53]]/TN=$t[i+53],d[y[i+54]]/TN=$t[i+54],d[y[i+55]]/TN=$t[i+55],d[y[i+56]]/TN=$t[i+56],d[y[i+57]]/TN=$t[i+57],d[y[i+58]]/TN=$t[i+58],d[y[i+59]]/TN=$t[i+59],d[y[i+60]]/TN=$t[i+60],d[y[i+61]]/TN=$t[i+61],d[y[i+62]]/TN=$t[i+62],d[y[i+63]]/TN=$t[i+63],d[y[i+64]]/TN=$t[i+64],d[y[i+65]]/TN=$t[i+65],d[y[i+66]]/TN=$t[i+66],d[y[i+67]]/TN=$t[i+67],d[y[i+68]]/TN=$t[i+68],d[y[i+69]]/TN=$t[i+69],d[y[i+70]]/TN=$t[i+70],d[y[i+71]]/TN=$t[i+71],d[y[i+72]]/TN=$t[i+72],d[y[i+73]]/TN=$t[i+73],d[y[i+74]]/TN=$t[i+74],d[y[i+75]]/TN=$t[i+75],d[y[i+76]]/TN=$t[i+76],d[y[i+77]]/TN=$t[i+77],d[y[i+78]]/TN=$t[i+78],d[y[i+79]]/TN=$t[i+79],d[y[i+80]]/TN=$t[i+80],d[y[i+81]]/TN=$t[i+81],d[y[i+82]]/TN=$t[i+82],d[y[i+83]]/TN=$t[i+83],d[y[i+84]]/TN=$t[i+84],d[y[i+85]]/TN=$t[i+85],d[y[i+86]]/TN=$t[i+86],d[y[i+87]]/TN=$t[i+87],d[y[i+88]]/TN=$t[i+88],d[y[i+89]]/TN=$t[i+89],d[y[i+90]]/TN=$t[i+90],d[y[i+91]]/TN=$t[i+91],d[y[i+92]]/TN=$t[i+92],d[y[i+93]]/TN=$t[i+93],d[y[i+94]]/TN=$t[i+94],d[y[i+95]]/TN=$t[i+95],d[y[i+96]]/TN=$t[i+96],d[y[i+97]]/TN=$t[i+97],d[y[i+98]]/TN=$t[i+98],d[y[i+99]]/TN=$t[i+99]
				break
			case 64:
				AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, 65535) d[y[i]]/TN=$t[i],d[y[i+1]]/TN=$t[i+1],d[y[i+2]]/TN=$t[i+2],d[y[i+3]]/TN=$t[i+3],d[y[i+4]]/TN=$t[i+4],d[y[i+5]]/TN=$t[i+5],d[y[i+6]]/TN=$t[i+6],d[y[i+7]]/TN=$t[i+7],d[y[i+8]]/TN=$t[i+8],d[y[i+9]]/TN=$t[i+9],d[y[i+10]]/TN=$t[i+10],d[y[i+11]]/TN=$t[i+11],d[y[i+12]]/TN=$t[i+12],d[y[i+13]]/TN=$t[i+13],d[y[i+14]]/TN=$t[i+14],d[y[i+15]]/TN=$t[i+15],d[y[i+16]]/TN=$t[i+16],d[y[i+17]]/TN=$t[i+17],d[y[i+18]]/TN=$t[i+18],d[y[i+19]]/TN=$t[i+19],d[y[i+20]]/TN=$t[i+20],d[y[i+21]]/TN=$t[i+21],d[y[i+22]]/TN=$t[i+22],d[y[i+23]]/TN=$t[i+23],d[y[i+24]]/TN=$t[i+24],d[y[i+25]]/TN=$t[i+25],d[y[i+26]]/TN=$t[i+26],d[y[i+27]]/TN=$t[i+27],d[y[i+28]]/TN=$t[i+28],d[y[i+29]]/TN=$t[i+29],d[y[i+30]]/TN=$t[i+30],d[y[i+31]]/TN=$t[i+31],d[y[i+32]]/TN=$t[i+32],d[y[i+33]]/TN=$t[i+33],d[y[i+34]]/TN=$t[i+34],d[y[i+35]]/TN=$t[i+35],d[y[i+36]]/TN=$t[i+36],d[y[i+37]]/TN=$t[i+37],d[y[i+38]]/TN=$t[i+38],d[y[i+39]]/TN=$t[i+39],d[y[i+40]]/TN=$t[i+40],d[y[i+41]]/TN=$t[i+41],d[y[i+42]]/TN=$t[i+42],d[y[i+43]]/TN=$t[i+43],d[y[i+44]]/TN=$t[i+44],d[y[i+45]]/TN=$t[i+45],d[y[i+46]]/TN=$t[i+46],d[y[i+47]]/TN=$t[i+47],d[y[i+48]]/TN=$t[i+48],d[y[i+49]]/TN=$t[i+49],d[y[i+50]]/TN=$t[i+50],d[y[i+51]]/TN=$t[i+51],d[y[i+52]]/TN=$t[i+52],d[y[i+53]]/TN=$t[i+53],d[y[i+54]]/TN=$t[i+54],d[y[i+55]]/TN=$t[i+55],d[y[i+56]]/TN=$t[i+56],d[y[i+57]]/TN=$t[i+57],d[y[i+58]]/TN=$t[i+58],d[y[i+59]]/TN=$t[i+59],d[y[i+60]]/TN=$t[i+60],d[y[i+61]]/TN=$t[i+61],d[y[i+62]]/TN=$t[i+62],d[y[i+63]]/TN=$t[i+63]
				break
			case 32:
				AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, 65535) d[y[i]]/TN=$t[i],d[y[i+1]]/TN=$t[i+1],d[y[i+2]]/TN=$t[i+2],d[y[i+3]]/TN=$t[i+3],d[y[i+4]]/TN=$t[i+4],d[y[i+5]]/TN=$t[i+5],d[y[i+6]]/TN=$t[i+6],d[y[i+7]]/TN=$t[i+7],d[y[i+8]]/TN=$t[i+8],d[y[i+9]]/TN=$t[i+9],d[y[i+10]]/TN=$t[i+10],d[y[i+11]]/TN=$t[i+11],d[y[i+12]]/TN=$t[i+12],d[y[i+13]]/TN=$t[i+13],d[y[i+14]]/TN=$t[i+14],d[y[i+15]]/TN=$t[i+15],d[y[i+16]]/TN=$t[i+16],d[y[i+17]]/TN=$t[i+17],d[y[i+18]]/TN=$t[i+18],d[y[i+19]]/TN=$t[i+19],d[y[i+20]]/TN=$t[i+20],d[y[i+21]]/TN=$t[i+21],d[y[i+22]]/TN=$t[i+22],d[y[i+23]]/TN=$t[i+23],d[y[i+24]]/TN=$t[i+24],d[y[i+25]]/TN=$t[i+25],d[y[i+26]]/TN=$t[i+26],d[y[i+27]]/TN=$t[i+27],d[y[i+28]]/TN=$t[i+28],d[y[i+29]]/TN=$t[i+29],d[y[i+30]]/TN=$t[i+30],d[y[i+31]]/TN=$t[i+31]
				break
			case 16:
				AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, 65535) d[y[i]]/TN=$t[i],d[y[i+1]]/TN=$t[i+1],d[y[i+2]]/TN=$t[i+2],d[y[i+3]]/TN=$t[i+3],d[y[i+4]]/TN=$t[i+4],d[y[i+5]]/TN=$t[i+5],d[y[i+6]]/TN=$t[i+6],d[y[i+7]]/TN=$t[i+7],d[y[i+8]]/TN=$t[i+8],d[y[i+9]]/TN=$t[i+9],d[y[i+10]]/TN=$t[i+10],d[y[i+11]]/TN=$t[i+11],d[y[i+12]]/TN=$t[i+12],d[y[i+13]]/TN=$t[i+13],d[y[i+14]]/TN=$t[i+14],d[y[i+15]]/TN=$t[i+15]
				break
			case 8:
				AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, 65535) d[y[i]]/TN=$t[i],d[y[i+1]]/TN=$t[i+1],d[y[i+2]]/TN=$t[i+2],d[y[i+3]]/TN=$t[i+3],d[y[i+4]]/TN=$t[i+4],d[y[i+5]]/TN=$t[i+5],d[y[i+6]]/TN=$t[i+6],d[y[i+7]]/TN=$t[i+7]
				break
			case 4:
				AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, 65535) d[y[i]]/TN=$t[i],d[y[i+1]]/TN=$t[i+1],d[y[i+2]]/TN=$t[i+2],d[y[i+3]]/TN=$t[i+3]
				break
			case 2:
				AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, 65535) d[y[i]]/TN=$t[i],d[y[i+1]]/TN=$t[i+1]
				break
			case 1:
				AppendToGraph/Q/W=$w/L=$v/B=$h/C=(r, g, b, 65535) d[y[i]]/TN=$t[i]
				break
			default:
				ASSERT(0, "Fail")
				break
		endswitch
	while(i)

	// IPT_FORMAT_ON

End

/// @brief Perform common transformations on the graphs traces
///
/// Keeps track of all internal details wrt. to the order of
/// the operations, backups, etc.
///
/// Needs to be called after adding/removing/updating sweeps via
/// AddSweepToGraph(), RemoveSweepFromGraph(), UpdateSweepInGraph().
///
/// @param win  graph with sweep traces
/// @param mode update mode, one of @ref PostPlotUpdateModes
/// @param additionalData [optional, defaults to invalid wave reference] additional data for subsequent users.
///                        Currently supported:
///                        - POST_PLOT_REMOVED_SWEEPS -> OVS indizes of the removed sweep
///                        - POST_PLOT_ADDED_SWEEPS   -> OVS indizes of the added sweep
///                        Use OVS_GetSweepAndExperiment() to convert an index into a sweep/experiment pair.
Function PostPlotTransformations(string win, variable mode, [WAVE/Z additionalData])

	STRUCT TiledGraphSettings tgs
	string                    graph

	switch(mode)
		case POST_PLOT_ADDED_SWEEPS:
		case POST_PLOT_REMOVED_SWEEPS:
			ASSERT(!ParamIsDefault(additionalData), "Missing optional additionalData")
			break
		case POST_PLOT_FULL_UPDATE:
		case POST_PLOT_CONSTANT_SWEEPS:
			ASSERT(ParamIsDefault(additionalData), "Not supported optional additionalData")
			WAVE/Z additionalData = $""
			break
		default:
			ASSERT(0, "Invalid mode")
	endswitch

	graph = GetMainWindow(win)

	STRUCT PostPlotSettings pps
	InitPostPlotSettings(graph, pps)

	if(pps.zeroTraces)
		WAVE/Z/T traces = GetAllSweepTraces(graph, prefixTraces = 0)
	else
		WAVE/Z/T traces = $""
	endif

	ZeroTracesIfReq(graph, traces, pps.zeroTraces)
	TimeAlignMainWindow(graph, pps)

	AverageWavesFromSameYAxisIfReq(graph, pps.averageTraces, pps.averageDataFolder, pps.hideSweep)
	AR_HighlightArtefactsEntry(graph)

	if(ParamIsDefault(additionalData))
		PA_Update(graph, mode)
	else
		PA_Update(graph, mode, additionalData = additionalData)
	endif

	if(pps.visualizeEpochs)
		BSP_AddTracesForEpochs(graph)
	endif

	SF_Update(graph)

	BSP_ScaleAxes(graph)

	[tgs] = BSP_GatherTiledGraphSettings(graph)
	LayoutGraph(graph, tgs)

	LBV_Update(win)
End

static Function InitPostPlotSettings(string win, STRUCT PostPlotSettings &pps)

	string bsPanel = BSP_GetPanel(win)

	pps.averageDataFolder = BSP_GetFolder(win, MIES_BSP_PANEL_FOLDER)
	pps.averageTraces     = GetCheckboxState(bsPanel, "check_Calculation_AverageTraces")
	pps.zeroTraces        = GetCheckBoxState(bsPanel, "check_Calculation_ZeroTraces")
	pps.hideSweep         = GetCheckBoxState(bsPanel, "check_SweepControl_HideSweep")

	pps.timeAlignment     = GetCheckBoxState(bsPanel, "check_BrowserSettings_TA")
	pps.timeAlignMode     = GetPopupMenuIndex(bsPanel, "popup_TimeAlignment_Mode")
	pps.timeAlignLevel    = GetSetVariable(bsPanel, "setvar_TimeAlignment_LevelCross")
	pps.timeAlignRefTrace = GetPopupMenuString(bsPanel, "popup_TimeAlignment_Master")
	pps.timeAlignment     = GetCheckBoxState(bsPanel, "check_BrowserSettings_TA")
	pps.visualizeEpochs   = GetCheckBoxState(bsPanel, "check_BrowserSettings_VisEpochs")
End

/// @brief Average traces in the graph from the same y-axis and append them to the graph
///
/// @param graph             graph with traces create by #CreateTiledChannelGraph
/// @param averagingEnabled  switch if averaging is enabled or not
/// @param averageDataFolder permanent datafolder where the average waves can be stored
/// @param hideSweep         are normal channel traces hidden or not
static Function AverageWavesFromSameYAxisIfReq(string graph, variable averagingEnabled, DFREF averageDataFolder, variable hideSweep)

	variable referenceTime, traceIndex
	string averageWaveName, listOfWaves, listOfChannelTypes, listOfChannelNumbers, listOfHeadstages
	string range, listOfRanges, firstXAxis, listOfClampModes, xAxis, yAxis
	variable i, j, k, l, numAxes, numTraces, numWaves, ret
	variable column, first, last, orientation
	string axis, trace, axList, baseName, clampMode, traceName, headstage
	string channelType, channelNumber, fullPath, panel
	STRUCT RGBColor s

	referenceTime = DEBUG_TIMER_START()

	if(!averagingEnabled)
		listOfWaves = GetListOfObjects(averageDataFolder, "average.*", fullPath = 1)
		CallFunctionForEachListItem_TS(KillOrMoveToTrashPath, listOfWaves)
		RemoveEmptyDataFolder(averageDataFolder)
		return NaN
	endif

	// remove existing average traces
	WAVE/Z/T averageTraces = TUD_GetUserDataAsWave(graph, "traceName", keys = {"traceType"}, values = {"Average"})
	numTraces = WaveExists(averageTraces) ? DimSize(averageTraces, ROWS) : 0
	for(i = 0; i < numTraces; i += 1)
		trace = averageTraces[i]
		RemoveFromGraph/W=$graph $trace
		TUD_RemoveUserData(graph, trace)
	endfor

	WAVE/Z/T traces = TUD_GetUserDataAsWave(graph, "traceName", keys = {"traceType"}, values = {"sweep"})

	if(!WaveExists(traces))
		return NaN
	endif

	axList    = AxisList(graph)
	numAxes   = ItemsInList(axList)
	numTraces = DimSize(traces, ROWS)

	for(i = 0; i < numAxes; i += 1)
		axis                 = StringFromList(i, axList)
		listOfWaves          = ""
		listOfChannelTypes   = ""
		listOfChannelNumbers = ""
		listOfRanges         = ""
		listOfClampModes     = ""
		listOfHeadstages     = ""
		firstXAxis           = ""

		orientation = GetAxisOrientation(graph, axis)
		if(orientation == AXIS_ORIENTATION_BOTTOM || orientation == AXIS_ORIENTATION_TOP)
			continue
		endif

		for(j = 0; j < numTraces; j += 1)
			trace = traces[j]
			yAxis = TUD_GetUserData(graph, trace, "YAXIS")

			if(cmpstr(axis, yaxis))
				continue
			endif

			fullPath      = TUD_GetUserData(graph, trace, "fullPath")
			channelType   = TUD_GetUserData(graph, trace, "channelType")
			channelNumber = TUD_GetUserData(graph, trace, "channelNumber")
			clampMode     = TUD_GetUserData(graph, trace, "clampMode")
			headstage     = TUD_GetUserData(graph, trace, "headstage")
			range         = TUD_GetUserData(graph, trace, "YRANGE")

			listOfWaves          = AddListItem(fullPath, listOfWaves, ";", Inf)
			listOfChannelTypes   = AddListItem(channelType, listOfChannelTypes, ";", Inf)
			listOfChannelNumbers = AddListItem(channelNumber, listOfChannelNumbers, ";", Inf)
			listOfRanges         = AddListItem(range, listOfRanges, "_", Inf)
			listOfClampModes     = AddListItem(clampMode, listOfClampModes, ";", Inf)
			listOfHeadstages     = AddListItem(headstage, listOfHeadstages, ";", Inf)

			if(IsEmpty(firstXAxis))
				firstXAxis = TUD_GetUserData(graph, trace, "XAXIS")
			endif
		endfor

		numWaves = ItemsInList(listOfWaves)
		if(numWaves <= 1)
			continue
		endif

		if(WaveListHasSameWaveNames(listOfWaves, baseName))
			// add channel type suffix if they are all equal
			if(ListHasOnlyOneUniqueEntry(listOfChannelTypes))
				sprintf averageWaveName, "average_%s", baseName
			else
				sprintf averageWaveName, "average_%s_%d", baseName, k
				k += 1
			endif
		elseif(StringMatch(axis, VERT_AXIS_BASE_NAME + "*"))
			averageWaveName = "average" + RemovePrefix(axis, start = VERT_AXIS_BASE_NAME)
		else
			sprintf averageWaveName, "average_%d", k
			k += 1
		endif

		sprintf traceName, "%s%s", GetTraceNamePrefix(numTraces + traceIndex++), averageWaveName

		WAVE ranges = ExtractFromSubrange(listOfRanges, ROWS)

		// convert ranges from points to ms
		Redimension/D ranges

		MatrixOP/FREE rangeStart = col(ranges, 0)
		MatrixOP/FREE rangeStop = col(ranges, 1)

		rangeStart[] = IndexToScale($StringFromList(p, listOfWaves), rangeStart[p], ROWS)
		rangeStop[]  = IndexToScale($StringFromList(p, listOfWaves), rangeStop[p], ROWS)

		if(WaveMin(rangeStart) != -1 && WaveMin(rangeStop) != -1)
			first = WaveMin(rangeStart)
			last  = WaveMax(rangeStop)
		else
			first = NaN
			last  = NaN
		endif
		WaveClear rangeStart, rangeStop

		WAVE/WAVE wavesToAverage = ListToWaveRefWave(listOfWaves)
		WAVE      averageWave    = CalculateAverage(wavesToAverage, averageDataFolder, averageWaveName)

		if(WaveListHasSameWaveNames(listOfHeadstages, headstage) && hideSweep)
			[s] = GetTraceColor(str2num(headstage))
		else
			[s] = GetTraceColorForAverage()
		endif

		if(IsFinite(first) && IsFinite(last))
			// and now convert it back to points in the average wave
			first = ScaleToIndex(averageWave, first, ROWS)
			last  = ScaleToIndex(averageWave, last, ROWS)

			AppendToGraph/Q/W=$graph/L=$axis/B=$firstXAxis/C=(s.red, s.green, s.blue, 0.80 * 65535) averageWave[first, last]/TN=$traceName
		else
			AppendToGraph/Q/W=$graph/L=$axis/B=$firstXAxis/C=(s.red, s.green, s.blue, 0.80 * 65535) averageWave/TN=$traceName
		endif

		if(ListHasOnlyOneUniqueEntry(listOfClampModes))
			TUD_SetUserData(graph, traceName, "clampMode", StringFromList(0, listOfClampModes))
			TUD_SetUserData(graph, traceName, "fullPath", GetWavesDataFolder(averageWave, 2))
			TUD_SetUserData(graph, traceName, "traceType", "Average")
			TUD_SetUserData(graph, traceName, "XAXIS", firstXAxis)
			TUD_SetUserData(graph, traceName, "YAXIS", axis)
		endif
	endfor

	DEBUGPRINT_ELAPSED(referenceTime)
End

/// @brief Zero all given traces
static Function ZeroTracesIfReq(string graph, WAVE/Z/T traces, variable zeroTraces)

	string trace
	variable numTraces, i

	if(!zeroTraces || !WaveExists(traces))
		return NaN
	endif

	numTraces = DimSize(traces, ROWS)
	for(i = 0; i < numTraces; i += 1)
		trace = traces[i]
		WAVE wv = $TUD_GetUserData(graph, trace, "fullPath")
		ZeroWave(wv)
	endfor
End

static Function AddFreeAxis(string graph, string name, string lbl, variable first, variable last)

	NewFreeAxis/W=$graph $name
	ModifyGraph/W=$graph standoff($name)=0, lblPosMode($name)=2, axRGB($name)=(65535, 65535, 65535, 0), tlblRGB($name)=(65535, 65535, 65535, 0), alblRGB($name)=(0, 0, 0), lblMargin($name)=0, lblLatPos($name)=0
	ModifyGraph/W=$graph axisEnab($name)={first, last}
	Label/W=$graph $name, lbl
End

/// @brief Layout the DataBrowser/SweepBrowser graph
///
/// Takes also care of adding free axis for the headstage display.
///
/// Concept:
/// - Block [#]: One axis with surrounded GRAPH_DIV_SPACING space
/// - Slot [#]: Unit of vertical space, a block can occupy multiple slots
/// - We have 100% space for all axes
/// - AD axes should occupy four times the space of DA/TTL channels
/// - So DA/TTL occupy one slot, AD occupy four slots
/// - Between each axes we want GRAPH_DIV_SPACING clear space
/// - Count the number of vertical blocks and slots to be used
/// - Derive the space per slot
/// - For overlay channels we reserve only one slot times slot multiplier
///   per channel
///
/// The display order from top to bottom:
/// - Associated channels (above: DA, below: AD) with increasing headstage number
/// - Unassociated channels (above: DA, below: AD)
/// - TTL channels
///
/// For overlayed channels we have up to three blocks (DA, AD, TTL) in that order.
static Function LayoutGraph(string win, STRUCT TiledGraphSettings &tgs)

	variable i, numSlots, headstage, numBlocksTTL, numBlocks, numBlocksEpochDA, numBlocksEpochTTL, spacePerSlot
	variable numBlocksDA, numBlocksAD, first, firstFreeAxis, lastFreeAxis, orientation
	variable numBlocksUnassocDA, numBlocksUnassocAD, numBlocksHS
	string graph, regex, freeAxis, axis, lbl
	variable last = 1.0

	graph = GetMainWindow(win)
	RemoveFreeAxisFromGraph(graph)

	WAVE/Z/T allVerticalAxesNonUnique = TUD_GetUserDataAsWave(graph, "YAXIS")

	if(!WaveExists(allVerticalAxesNonUnique))
		// empty graph
		return NaN
	endif

	WAVE/T allVerticalAxes = GetUniqueEntries(allVerticalAxesNonUnique)

	WAVE/T allHorizontalAxesNonUnique = TUD_GetUserDataAsWave(graph, "XAXIS")
	WAVE/T allHorizontalAxes          = GetUniqueEntries(allHorizontalAxesNonUnique)

	if(tgs.overLayChannels)
		// up to three blocks

		// (?<! is a negative look behind assertion
		sprintf regex, ".*(?<!%s_)DA$", DB_AXIS_PART_EPOCHS
		WAVE/Z/T DAaxes = GrepWave(allVerticalAxes, regex)
		numBlocksDA = WaveExists(DAaxes) ? DimSize(DAaxes, ROWS) : 0

		sprintf regex, ".*%s_DA$", DB_AXIS_PART_EPOCHS
		WAVE/Z/T Epochaxes = GrepWave(allVerticalAxes, regex)
		numBlocksEpochDA = WaveExists(Epochaxes) ? DimSize(Epochaxes, ROWS) : 0

		regex = ".*AD$"
		WAVE/Z/T ADaxes = GrepWave(allVerticalAxes, regex)
		numBlocksAD = WaveExists(ADaxes) ? DimSize(ADaxes, ROWS) : 0

		sprintf regex, ".*(?<!%s)_TTL$", DB_AXIS_PART_EPOCHS
		WAVE/Z/T TTLaxes = GrepWave(allVerticalAxes, regex)
		numBlocksTTL = WaveExists(TTLaxes) ? DimSize(TTLaxes, ROWS) : 0

		sprintf regex, ".*%s_TTL$", DB_AXIS_PART_EPOCHS
		WAVE/Z/T Epochaxes = GrepWave(allVerticalAxes, regex)
		numBlocksEpochTTL = WaveExists(Epochaxes) ? DimSize(Epochaxes, ROWS) : 0

		numBlocks = numBlocksAD + numBlocksDA + numBlocksTTL + numBlocksEpochDA + numBlocksEpochTTL
		numSlots  = ADC_SLOT_MULTIPLIER * numBlocksAD + numBlocksDA + numBlocksTTL + EPOCH_SLOT_MULTIPLIER * (numBlocksEpochDA + numBlocksEpochTTL)

		spacePerSlot = (1.0 - (numBlocks - 1) * GRAPH_DIV_SPACING) / numSlots

		if(WaveExists(DAaxes))
			EnableAxis(graph, DAaxes, spacePerSlot, first, last)
		endif

		if(WaveExists(Epochaxes))
			EnableAxis(graph, Epochaxes, EPOCH_SLOT_MULTIPLIER * spacePerSlot, first, last)
		endif

		if(WaveExists(ADaxes))
			EnableAxis(graph, ADaxes, ADC_SLOT_MULTIPLIER * spacePerSlot, first, last)
		endif

		if(WaveExists(TTLaxes))
			EnableAxis(graph, TTLaxes, spacePerSlot, first, last)
		endif

		ASSERT(first < 1e-15, "Left over space")
		TweakAxes(graph, tgs, allVerticalAxes, allHorizontalAxes)

		return NaN
	endif

	// unassociated DA

	WAVE/Z/T unassocDANonUnique = TUD_GetUserDataAsWave(graph, "channelNumber", keys = {"channelType", "headstage"}, values = {"DA", "NaN"})
	if(WaveExists(unassocDANonUnique))
		WAVE/Z unassocDA = ConvertToUniqueNumber(unAssocDANonUnique, doSort = 1)
	endif

	numBlocksUnassocDA = WaveExists(unassocDA) ? DimSize(unassocDA, ROWS) : 0

	// unassociated AD

	WAVE/Z/T unassocADNonUnique = TUD_GetUserDataAsWave(graph, "channelNumber", keys = {"channelType", "headstage"}, values = {"AD", "NaN"})
	if(WaveExists(unassocADNonUnique))
		WAVE/Z unassocAD = ConvertToUniqueNumber(unassocADNonUnique, doSort = 1)
	endif

	numBlocksUnassocAD = WaveExists(unassocAD) ? DimSize(unassocAD, ROWS) : 0

	// number of headstages
	WAVE/Z/T headstagesNonUnique = TUD_GetUserDataAsWave(graph, "headstage")
	WAVE/Z   headstages          = ConvertToUniqueNumber(headstagesNonUnique, doZapNaNs = 1, doSort = 1)

	numBlocksHS = WaveExists(headstages) ? DimSize(headstages, ROWS) : 0

	// associated DA channels
	regex = ".*col0_DA_(?:[[:digit:]]{1,2})_HS_(?:[[:digit:]]{1,2})$"
	WAVE/Z/T axes = GrepWave(allVerticalAxes, regex)
	numBlocksDA = WaveExists(axes) ? DimSize(axes, ROWS) : 0

	// epoch info slots for associated and unassociated DA channels
	sprintf regex, ".*col0%s_DA_(?:[[:digit:]]{1,2})_HS_(?:([[:digit:]]{1,2}|NaN))$", DB_AXIS_PART_EPOCHS
	WAVE/Z/T axes = GrepWave(allVerticalAxes, regex)
	numBlocksEpochDA = WaveExists(axes) ? DimSize(axes, ROWS) : 0

	// epoch info for TTL channels
	if(tgs.visualizeEpochs && tgs.splitTTLbits)
		sprintf regex, ".*col0%s_TTL_(?:[[:digit:]]{1,2})_(?:[[:digit:]])_HS_NaN$", DB_AXIS_PART_EPOCHS
		WAVE/Z/T axes = GrepWave(allVerticalAxes, regex)
		numBlocksEpochTTL = WaveExists(axes) ? DimSize(axes, ROWS) : 0
		if(!numBlocksEpochTTL)
			// NI Hardware
			sprintf regex, ".*col0%s_TTL_(?:[[:digit:]]{1,2})_NaN_HS_NaN$", DB_AXIS_PART_EPOCHS
			WAVE/Z/T axes = GrepWave(allVerticalAxes, regex)
			numBlocksEpochTTL = WaveExists(axes) ? DimSize(axes, ROWS) : 0
		endif
	endif

	// associated AD channels
	regex = ".*col0_AD_(?:[[:digit:]]{1,2})_HS_(?:[[:digit:]]{1,2})$"
	WAVE/Z/T axes = GrepWave(allVerticalAxes, regex)
	numBlocksAD = WaveExists(axes) ? DimSize(axes, ROWS) : 0

	// create a text wave with all plotted TTL data in the form `TTL_$channel(_$ttlBit)?`
	WAVE/Z TTLsIndizes = TUD_GetUserDataAsWave(graph, "channelNumber", keys = {"channelType"}, values = {"TTL"}, returnIndizes = 1)

	if(WaveExists(TTLsIndizes))
		WAVE/T graphUserData = GetGraphUserData(graph)
		Make/FREE/T/N=(DimSize(TTLsIndizes, ROWS)) ttlsWithBitsUnsorted = "TTL_" + graphUserData[TTLsIndizes[p]][%channelNumber] + \
		                                                                  "_" + graphUserData[TTLsIndizes[p]][%TTLBit]
		WAVE/T ttlsWithBits = GetUniqueEntries(ttlsWithBitsUnsorted)
	endif

	numBlocksTTL = WaveExists(ttlsWithBits) ? DimSize(ttlsWithBits, ROWS) : 0

	// Headstage: 5 slots
	// Unassoc DA: 1 slot
	// Unassoc DA: 4 slots
	// TTL: 1 slot per ttlsWithBits

	numBlocks = numBlocksAD + numBlocksDA + numBlocksUnassocDA + numBlocksUnassocAD + numBlocksTTL + numBlocksEpochDA + numBlocksEpochTTL
	numSlots  = ADC_SLOT_MULTIPLIER * numBlocksAD + numBlocksDA + numBlocksUnassocDA + ADC_SLOT_MULTIPLIER * numBlocksUnassocAD + numBlocksTTL + EPOCH_SLOT_MULTIPLIER * (numBlocksEpochDA + numBlocksEpochTTL)

	spacePerSlot = (1.0 - (numBlocks - 1) * GRAPH_DIV_SPACING) / numSlots

	// starting from the top
	// headstages with associated channels
	for(i = 0; i < numBlocksHS; i += 1)
		lastFreeAxis = last

		headstage = headstages[i]
		// (?<! is a negative look behind assertion
		sprintf regex, ".*(?<!%s_)DA_(?:[[:digit:]]{1,2})_HS_%d", DB_AXIS_PART_EPOCHS, headstage
		WAVE/Z/T axes = GrepWave(allVerticalAxes, regex)

		if(WaveExists(axes))
			EnableAxis(graph, axes, spacePerSlot, first, last)
		endif

		sprintf regex, ".*%s_DA_(?:[[:digit:]]{1,2})_HS_%d", DB_AXIS_PART_EPOCHS, headstage
		WAVE/Z/T axes = GrepWave(allVerticalAxes, regex)

		if(WaveExists(axes))
			EnableAxis(graph, axes, EPOCH_SLOT_MULTIPLIER * spacePerSlot, first, last)
		endif

		regex = ".*AD_(?:[[:digit:]]{1,2})_HS_" + num2str(headstage)
		WAVE/Z/T axes = GrepWave(allVerticalAxes, regex)
		if(WaveExists(axes))
			EnableAxis(graph, axes, ADC_SLOT_MULTIPLIER * spacePerSlot, first, last)
		endif

		firstFreeAxis = first
		freeAxis      = "freeaxis_hs" + num2str(headstage)
		lbl           = "HS" + num2str(headstage)
		AddFreeAxis(graph, freeAxis, lbl, firstFreeAxis, lastFreeAxis)
	endfor

	// unassoc DA
	for(i = 0; i < numBlocksUnassocDA; i += 1)
		sprintf regex, ".*(?<!%s)_DA_%d_HS_NaN", DB_AXIS_PART_EPOCHS, unassocDA[i]
		WAVE/Z/T axes = GrepWave(allVerticalAxes, regex)
		ASSERT(WaveExists(axes), "Unexpected number of matches")
		EnableAxis(graph, axes, spacePerSlot, first, last)

		sprintf regex, ".*%s_DA_%d_HS_NaN", DB_AXIS_PART_EPOCHS, unassocDA[i]
		WAVE/Z/T axes = GrepWave(allVerticalAxes, regex)

		if(WaveExists(axes))
			EnableAxis(graph, axes, EPOCH_SLOT_MULTIPLIER * spacePerSlot, first, last)
		endif
	endfor

	// unassoc AD
	for(i = 0; i < numBlocksUnassocAD; i += 1)
		regex = ".*AD_" + num2str(unassocAD[i]) + "_HS_NaN"
		WAVE/Z/T axes = GrepWave(allVerticalAxes, regex)
		ASSERT(WaveExists(axes), "Unexpected number of matches")
		EnableAxis(graph, axes, ADC_SLOT_MULTIPLIER * spacePerSlot, first, last)
	endfor

	// TTLs
	for(i = 0; i < numBlocksTTL; i += 1)

		if(tgs.visualizeEpochs && tgs.splitTTLBits && numBlocksEpochTTL > 0)
			regex = DB_AXIS_PART_EPOCHS + "_" + ttlsWithBits[i]
			WAVE/Z/T axes = GrepWave(allVerticalAxes, regex)
			ASSERT(WaveExists(axes), "Unexpected number of matches")
			EnableAxis(graph, axes, EPOCH_SLOT_MULTIPLIER * spacePerSlot, first, last)
		endif

		sprintf regex, ".*(?<!%s)_%s", DB_AXIS_PART_EPOCHS, ttlsWithBits[i]
		WAVE/Z/T axes = GrepWave(allVerticalAxes, regex)
		ASSERT(WaveExists(axes), "Unexpected number of matches")
		EnableAxis(graph, axes, spacePerSlot, first, last)

		axis = axes[0]
		ModifyGraph/W=$graph nticks($axis)=2, manTick($axis)={0, 1, 0, 0}, manMinor($axis)={0, 50}, zapTZ($axis)=1
	endfor

	ASSERT(first < 1e-15, "Left over space")
	TweakAxes(graph, tgs, allVerticalAxes, allHorizontalAxes)
End

static Function TweakAxes(string graph, STRUCT TiledGraphSettings &tgs, WAVE/T allVerticalAxes, WAVE/T allHorizontalAxes)

	variable i, numAxes
	string axis

	numAxes = DimSize(allVerticalAxes, ROWS)
	for(i = 0; i < numAxes; i += 1)
		axis = allVerticalAxes[i]

		ModifyGraph/W=$graph tickUnit($axis)=1
		ModifyGraph/W=$graph lblPosMode($axis)=2, standoff($axis)=0, freePos($axis)=0
		ModifyGraph/W=$graph lblLatPos($axis)=3, lblMargin($axis)=15

		if(tgs.dDAQDisplayMode)
			ModifyGraph/W=$graph freePos($axis)=20
		endif
	endfor

	if(tgs.dDAQDisplayMode)
		numAxes = DimSize(allHorizontalAxes, ROWS)
		for(i = 0; i < numAxes; i += 1)
			axis = allHorizontalAxes[i]

			ModifyGraph/W=$graph alblRGB($axis)=(65535, 65535, 65535)
			Label/W=$graph $axis, "\u#2"
		endfor

		ModifyGraph/W=$graph axRGB=(65535, 65535, 65535), tlblRGB=(65535, 65535, 65535)
		ModifyGraph/W=$graph axThick=0
		ModifyGraph/W=$graph margin(left)=40, margin(bottom)=1
	else
		ModifyGraph/W=$graph margin(left)=0, margin(bottom)=0
	endif
End

/// @brief Helper function for LayoutGraph()
///
/// Enables the given axis between [last - spacePerSlot, last] and updates both on return.
/// Expects `last` to be 1.0 on the first call.
static Function EnableAxis(string graph, WAVE/T axes, variable spacePerSlot, variable &first, variable &last)

	string axis
	variable i, numAxes

	first = last - spacePerSlot

	first = max(0.0, first)
	last  = min(1.0, last)

	ASSERT(first < last, "Invalid order")

	numAxes = DimSize(axes, ROWS)
	ASSERT(numAxes >= 0, "Invalid number of axes")
	for(i = 0; i < numAxes; i += 1)
		ModifyGraph/W=$graph axisEnab($axes[i])={first, last}
	endfor

	last = first - GRAPH_DIV_SPACING
End
