#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_SBE
#endif

/// @file MIES_AnalysisBrowser_SweepBrowser_Export.ipf
/// @brief __SBE__  Panel for exporting sweepbrowser traces to new graphs or existing graphs

/// @brief Duplicate the sweep browser graph to a user given folder and name
///
/// Only duplicates the main graph without external subwindows
Function SBE_DuplicateSweepBrowser(graph)
	string graph

	string trace, folder, newPrefix, analysisPrefix, relativeDest
	string newGraphName, graphMacro, saveDFR, traceList
	variable numTraces, i, pos, numLines, useCursorRange, resetWaveZero
	variable beginX, endX, xcsrA, xcsrB, beginXPerWave, endXPerWave
	variable manualRangeBegin, manualRangeEnd, clipXRange

	folder           = "myFolder"
	newGraphName     = "myGraph"
	useCursorRange   = 0
	resetWaveZero    = 0
	manualRangeBegin = NaN
	manualRangeEnd   = NaN

	Prompt folder,           "Datafolder: "
	Prompt newGraphName,     "Graph name: "
	Prompt useCursorRange,   "Duplicate only the cursor range: "
	Prompt manualRangeBegin, "Manual X range begin: "
	Prompt manualRangeEnd,   "Manual X range end: "
	Prompt resetWaveZero,    "Reset the wave's dim offset to zero: "

	DoPrompt/HELP="No help available" "Please provide some information for the duplicated graph", folder, newGraphName, useCursorRange, manualRangeBegin, manualRangeEnd, resetWaveZero
	if(V_flag)
		return NaN
	endif

	DFREF sweepBrowserDFR = $SB_GetSweepBrowserFolder(graph)
	newPrefix      = GetDataFolder(1, UniqueDataFolder($"root:", folder))
	newPrefix      = RemoveEnding(newPrefix, ":")
	analysisPrefix = GetAnalysisFolderAS()

	if(useCursorRange)
		xcsrA  = xcsr(A, graph)
		xcsrB  = xcsr(B, graph)
		beginX = min(xcsrA, xcsrB)
		endX   = max(xcsrA, xcsrB)
		clipXRange = 1
	elseif(isFinite(manualRangeBegin) && IsFinite(manualRangeEnd))
		beginX = manualRangeBegin
		endX   = manualRangeEnd
		clipXRange = 1
	endif

	traceList = TraceNameList(graph, ";", 0 + 1)
	numTraces = ItemsInList(traceList)
	for(i = 0; i < numTraces; i += 1)
		trace = StringFromList(i, traceList)
		WAVE wv = TraceNameToWaveRef(graph, trace)

		// the waves can be in two locations, either in root:$sweepBrowser
		// or done below in root:MIES:analysis:$Experiment:$Device:sweep:$X
		DFREF loc = GetWavesDataFolderDFR(wv)
		if(DataFolderRefsEqual(loc, sweepBrowserDFR))
			DFREF dfr = createDFWithAllParents(newPrefix)
		else
			relativeDest = RemovePrefix(GetDataFolder(1, loc), startStr=analysisPrefix)
			DFREF dfr = createDFWithAllParents(newPrefix + relativeDest)
		endif

		if(clipXRange)
			beginXPerWave = max(leftx(wv), beginX)
			endXPerWave   = min(rightx(wv), endX)
		else
			beginXPerWave = leftx(wv)
			endXPerWave   = rightx(wv)
		endif

		Duplicate/R=(beginXPerWave, endXPerWave) wv, dfr:$UniqueWaveName(dfr, NameOfWave(wv))/WAVE=dup
		WaveClear wv
		if(clipXRange)
			AddEntryIntoWaveNoteAsList(dup, "CursorA", var=beginX)
			AddEntryIntoWaveNoteAsList(dup, "CursorB", var=endX)
		endif
		if(resetWaveZero)
			AddEntryIntoWaveNoteAsList(dup, "OldDimOffset", var=DimOffset(dup, ROWS))
			SetScale/P x, 0, DimDelta(dup, ROWS), WaveUnits(dup, ROWS), dup
		endif
	endfor

	graphMacro = WinRecreation(graph, 0)

	// everything we don't need anymore starts in the line with SetWindow
	// ranging to the macro's end
	pos = strsearch(graphMacro, "SetWindow kwTopWin" , 0)
	if(pos != -1)
		graphMacro = graphMacro[0, pos - 2]
	endif
	// remove setting the CDF, we do that ourselves later on
	graphMacro = ListMatch(graphMacro, "!*SetDataFolder fldrSav*", "\r")

	// remove setting the bottom axis range, as this might be wrong
	graphMacro = ListMatch(graphMacro, "!*SetAxis bottom*", "\r")

	// replace the old data location with the new one
	graphMacro = ReplaceString(analysisPrefix, graphMacro, newPrefix)

	// replace relative reference to sweepBrowserDFR
	// with absolut ones to newPrefix
	folder = GetDataFolder(1, sweepBrowserDFR)
	folder = RemovePrefix(folder, startStr="root:")
	folder = ":::::::" + folder
	graphMacro = ReplaceString(folder, graphMacro, newPrefix + ":")

	saveDFR = GetDataFolder(1)
	// The first three lines are:
	// Window SweepBrowser1() : Graph
	//		PauseUpdate; Silent 1		// building window...
	// 		String fldrSav0= GetDataFolder(1)
	numLines = ItemsInList(graphMacro, "\r")
	for(i = 3; i < numLines; i += 1)
		string line = StringFromList(i, graphMacro, "\r")
		Execute/Q line
	endfor

	// rename the graph
	newGraphName = CleanUpName(newGraphName, 0)
	if(windowExists(newGraphName))
		newGraphName = UniqueName(newGraphName, 6, 0)
	endif
	SVAR S_name
	RenameWindow $S_name, $newGraphName

	Execute/P/Q "KillStrings/Z S_name"
	Execute/P/Q "SetDataFolder " + saveDFR
End
