#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_AB
#endif // AUTOMATED_TESTING

/// @file MIES_AnalysisBrowser.ipf
/// @brief __AB__ Analysis browser
///
/// Has no dependencies on any hardware related functions.

static Constant EXPERIMENT_TREEVIEW_COLUMN = 0
static Constant DEVICE_TREEVIEW_COLUMN     = 3

static Constant AB_LOAD_SWEEP          = 0
static Constant AB_LOAD_STIMSET        = 1
static Constant AB_LOAD_TP_STORAGE     = 2
static Constant AB_LOAD_HISTORYANDLOGS = 3

static Constant AB_LOADOPT_RESULTS  = 0x01
static Constant AB_LOADOPT_COMMENTS = 0x02

static StrConstant AB_UDATA_WORKINGDF = "datafolder"
static StrConstant AB_WORKFOLDER_NAME = "workFolder"

static Function AB_ResetListBoxWaves()

	variable col, val, newSize

	WAVE   expBrowserSel  = GetExperimentBrowserGUISel()
	WAVE/T expBrowserList = GetExperimentBrowserGUIList()
	newSize = GetNumberFromWaveNote(expBrowserList, NOTE_INDEX)
	Redimension/N=(newSize, -1, -1, -1) expBrowserList, expBrowserSel

	if(DimSize(expBrowserSel, ROWS) > 0)
		FastOp expBrowserSel = 0

		val = LISTBOX_TREEVIEW | LISTBOX_TREEVIEW_EXPANDED

		col = FindDimLabel(expBrowserList, COLS, "file")
		ASSERT(col >= 0, "invalid column index")
		expBrowserSel[][col - 1] = !cmpstr(expBrowserList[p][col], "") ? 0 : val

		col = FindDimLabel(expBrowserList, COLS, "device")
		ASSERT(col >= 0, "invalid column index")
		expBrowserSel[][col - 1] = !cmpstr(expBrowserList[p][col], "") ? 0 : val
	endif

	// backup initial state
	WAVE/T expBrowserSelBak  = CreateBackupWave(expBrowserSel, forceCreation = 1)
	WAVE/T expBrowserListBak = CreateBackupWave(expBrowserList, forceCreation = 1)
End

/// @brief Remove empty working DF from previous AB sessions
static Function AB_RemoveEmptyWorkingDF()

	string regEx = AB_WORKFOLDER_NAME + "*"
	DFREF dfrFolder

	DFREF  dfr         = GetAnalysisFolder()
	WAVE/T workFolders = ListToTextWave(GetListOfObjects(dfr, regEx, typeFlag = COUNTOBJECTS_DATAFOLDER, fullPath = 1), ";")
	Make/FREE/N=(DimSize(workFolders, ROWS))/DF dfrWork = $workFolders[p]
	for(dfrFolder : dfrWork)
		RemoveEmptyDataFolder(dfrFolder)
	endfor
End

/// @brief Reset all waves of the main experiment browser
static Function AB_InitializeAnalysisBrowserWaves()

	WAVE folderColors = GetAnalysisBrowserGUIFolderColors()

	WAVE/T folderList      = GetAnalysisBrowserGUIFolderList()
	WAVE   folderSelection = GetAnalysisBrowserGUIFolderSelection()
	Redimension/N=(0, -1, -1) folderList, folderSelection

	WAVE/T map = GetAnalysisBrowserMap()
	map = ""
	SetNumberInWaveNote(map, NOTE_INDEX, 0)

	WAVE/T list = GetExperimentBrowserGUIList()
	WAVE   sel  = GetExperimentBrowserGUISel()
	Redimension/N=(MINIMUM_WAVE_SIZE, -1, -1, -1) list, sel
	list = ""
	SetNumberInWaveNote(list, NOTE_INDEX, 0)
	FastOp sel = 0
End

/// @brief Create relation (map) between file on disk and datafolder in current experiment
///
/// @return index into mapping wave of the newly added entry or -1 if the file
///         is already in the map or an error occurred parsing the file
static Function AB_AddMapEntry(string baseFolder, string discLocation)

	variable nextFreeIndex, fileID, majorNWBVersion, dim, writeIndex
	string dataFolder, fileType, relativePath, extension, nwbVersionStr
	WAVE/T map = GetAnalysisBrowserMap()

	WAVE/Z indizes = FindIndizes(map, colLabel = "DiscLocation", str = discLocation)

	if(WaveExists(indizes))
		DEBUGPRINT("Skipping duplicated file: ", str = discLocation)
		return -1
	endif

	nextFreeIndex = GetNumberFromWaveNote(map, NOTE_INDEX)
	dim           = FindDimLabel(map, COLS, "DiscLocation")
	FindValue/TEXT=""/TXOP=4/RMD=[0, nextFreeIndex - 1][dim] map
	if(V_row >= 0)
		writeIndex = V_row
	else
		writeIndex = nextFreeIndex
		EnsureLargeEnoughWave(map, indexShouldExist = writeIndex, dimension = ROWS)
	endif

	// %DiscLocation = full path to file
	map[writeIndex][%DiscLocation] = discLocation

	// %FileName = filename + extension
	relativePath               = RemovePrefix(discLocation, start = baseFolder)
	map[writeIndex][%FileName] = relativePath

	extension = "." + GetFileSuffix(discLocation)

	// %FileType = igor
	strswitch(extension)
		case ".pxp": // fallthrough
		case ".uxp":
			fileType = ANALYSISBROWSER_FILE_TYPE_IGOR
			break
		case ".nwb":
			fileID        = H5_OpenFile(discLocation)
			nwbVersionStr = ReadNWBVersion(fileID)
			try
				majorNWBVersion = GetNWBMajorVersion(nwbVersionStr)
			catch
				printf "Could not parse read NWB version.\rFile: %s\rRead version: %s", discLocation, nwbVersionStr
				return -1
			endtry
			H5_CloseFile(fileID)
			switch(majorNWBVersion)
				case 1:
					fileType = ANALYSISBROWSER_FILE_TYPE_NWBv1
					break
				case 2:
					fileType = ANALYSISBROWSER_FILE_TYPE_NWBv2
					break
				default:
					FATAL_ERROR("Unknown NWB version")
			endswitch
			break
		default:
			FATAL_ERROR("invalid file type")
	endswitch
	map[writeIndex][%FileType] = fileType

	DFREF dfrAB     = GetAnalysisFolder()
	DFREF dfr       = dfrAB:$AB_GetUserData(AB_UDATA_WORKINGDF)
	DFREF expFolder = UniqueDataFolder(dfr, RemoveEnding(relativePath, extension))
	dataFolder                   = RemovePrefix(GetDataFolder(1, expFolder), start = GetDataFolder(1, dfrAB))
	map[writeIndex][%DataFolder] = RemoveEnding(dataFolder, ":")
	RefCounterDFIncrease(expFolder)

	if(writeIndex == nextFreeIndex)
		nextFreeIndex += 1
		SetNumberInWaveNote(map, NOTE_INDEX, nextFreeIndex)
	endif

	return writeIndex
End

static Function AB_RemoveMapEntry(variable index)

	string dfABPath, dfPath

	WAVE/T map = GetAnalysisBrowserMap()

	ASSERT(index < DimSize(map, ROWS), "row index out-of-bounds")

	dfABPath = GetDataFolder(1, GetAnalysisFolder())
	dfPath   = map[index][%DataFolder]
	if(!IsEmpty(dfPath))
		DFREF dfr = $(dfABPath + dfPath)
		RefCounterDFDecrease(dfr)
	endif
	map[index][] = ""

	if((index + 1) == GetNumberFromWaveNote(map, NOTE_INDEX))
		SetNumberInWaveNote(map, NOTE_INDEX, index)
	endif
End

/// @brief  Get single matching entry from GetAnalysisBrowserMap
/// @param  discLocation: first column. Path to file on disc
/// @return wave with 4 columns
/// Columns:
/// 0: %DiscLocation:  Path to Experiment on Disc
/// 1: %FileName:      Name of File in experiment column in ExperimentBrowser
/// 2: %DataFolder     Data folder inside current Igor experiment
/// 3: %FileType       File Type identifier for routing to loader functions, one of @ref AnalysisBrowserFileTypes
Function/WAVE AB_GetMap(string discLocation)

	variable dim

	WAVE/T map = GetAnalysisBrowserMap()
	dim = FindDimLabel(map, COLS, "DiscLocation")
	FindValue/TXOP=4/TEXT=(discLocation)/RMD=[][dim] map
	ASSERT(V_row >= 0, "invalid index")

	Make/FREE/N=4/T wv
	wv = map[V_row][p]

	SetDimLabel ROWS, 0, DiscLocation, wv
	SetDimLabel ROWS, 1, FileName, wv
	SetDimLabel ROWS, 2, DataFolder, wv
	SetDimLabel ROWS, 3, FileType, wv

	return wv
End

/// @brief save deviceList to wave
/// @return created wave.
Function/WAVE AB_SaveDeviceList(string deviceList, string dataFolder)

	variable numDevices
	WAVE/T wv = GetAnalysisDeviceWave(dataFolder)

	WAVE/T deviceListWave = ListToTextWave(deviceList, ";")
	numDevices = DimSize(deviceListWave, ROWS)
	if(numDevices > 0)
		EnsureLargeEnoughWave(wv, indexShouldExist = numDevices, dimension = ROWS)
		wv[0, numDevices - 1] = deviceListWave[p]
	endif

	SetNumberInWaveNote(wv, NOTE_INDEX, numDevices)

	return wv
End

/// @brief general loader for pxp, uxp and nwb files
///
/// @return 0 if the file was loaded, or 1 if not (usually due to an error
///         or because it was already loaded)
static Function AB_AddFile(string win, string discLocation, string sourceEntry, variable loadOpts)

	variable mapIndex
	variable firstMapped, lastMapped
	string baseFolder

	// This allows also that NWB and PXP is selected programmatically that is used in testing
	if(!((GetCheckBoxState(win, "check_load_pxp") && StringEndsWith(discLocation, ".pxp")) || \
	     (GetCheckBoxState(win, "check_load_nwb") && StringEndsWith(discLocation, ".nwb"))))
		return 1
	endif

	WAVE/T list = GetExperimentBrowserGUIList()

	baseFolder = SelectString(FileExists(sourceEntry), sourceEntry, GetFolder(sourceEntry))
	mapIndex   = AB_AddMapEntry(baseFolder, discLocation)

	if(mapIndex < 0)
		return 1
	endif

	firstMapped = GetNumberFromWaveNote(list, NOTE_INDEX)
	AB_LoadFile(discLocation, loadOpts)
	lastMapped = GetNumberFromWaveNote(list, NOTE_INDEX) - 1

	if(lastMapped >= firstMapped)
		list[firstMapped, lastMapped][%file][1] = num2str(mapIndex)
		list[firstMapped, lastMapped][%type][1] = sourceEntry
	else // experiment could not be loaded
		AB_RemoveMapEntry(mapIndex)
		return 1
	endif

	return 0
End

/// @brief from a list of extended stimset names with WP_, WPT_ or SegWvType_ prefix
///        return a boiled down list of unique stimset names without prefix
///        @sa NWB_SuffixExtendedStimsetNamesToStimsetNames
Function/S AB_PrefixExtendedStimsetNamesToStimsetNames(string stimsets)

	string prefix1, prefix2, prefix3
	string regexp, prefixRemovedList

	sprintf prefix1, "%s_", GetWaveBuilderParameterTypeName(STIMSET_PARAM_WP)
	sprintf prefix2, "%s_", GetWaveBuilderParameterTypeName(STIMSET_PARAM_WPT)
	sprintf prefix3, "%s_", GetWaveBuilderParameterTypeName(STIMSET_PARAM_SEGWVTYPE)

	regExp            = prefix1 + "|" + prefix2 + "|" + prefix3
	prefixRemovedList = RemovePrefixFromListItem(regExp, stimsets, regExp = 1)

	return GetUniqueTextEntriesFromList(prefixRemovedList, caseSensitive = 0)
End

/// @brief Returns a list of stimset names from an igor experiment file
static Function/S AB_GetStimsetListFromIgorFile(string fullPath)

	string list, wList

	DFREF tmpDFR = NewFreeDataFolder()
	AB_LoadDataWrapper(tmpDFR, fullPath, GetWBSvdStimSetParamPathAS(), "")
	wList = GetListOfObjects(tmpDFR, "*", recursive = 1, typeFlag = COUNTOBJECTS_WAVES, exprType = MATCH_WILDCARD)
	AB_LoadDataWrapper(tmpDFR, fullPath, GetWBSvdStimSetPathAsString(), "")
	list = GetListOfObjects(tmpDFR, "*", recursive = 1, typeFlag = COUNTOBJECTS_WAVES, exprType = MATCH_WILDCARD)

	list = AddListItem(RemoveEnding(wList, ";"), list)

	return AB_PrefixExtendedStimsetNamesToStimsetNames(list)
End

/// @brief returns 1 if the file has stimsets, 0 otherwise
static Function AB_FileHasStimsets(WAVE/T map)

	string   stimSetList
	variable h5_fileID

	strswitch(map[%FileType])
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			DFREF tmpDFR = NewFreeDataFolder()
			if(AB_LoadDataWrapper(tmpDFR, map[%DiscLocation], GetWBSvdStimSetParamPathAS(), ""))
				return 1
			endif

			return !!AB_LoadDataWrapper(tmpDFR, map[%DiscLocation], GetWBSvdStimSetPathAsString(), "")
		case ANALYSISBROWSER_FILE_TYPE_NWBv1: // fallthrough
		case ANALYSISBROWSER_FILE_TYPE_NWBv2:

			h5_fileID   = H5_OpenFile(map[%DiscLocation])
			stimSetList = ReadStimsets(h5_fileID)
			H5_CloseFile(h5_fileID)

			return !IsEmpty(stimSetList)
		default:
			FATAL_ERROR("invalid file type")
	endswitch

	return 0
End

/// @brief function tries to load Data From discLocation.
static Function AB_LoadFile(string discLocation, variable loadOpts)

	string device, deviceList
	variable numDevices, i, highestSweepNumber

	WAVE/T map = AB_GetMap(discLocation)

	if(!AB_HasCompatibleVersion(discLocation))
		return NaN
	endif

	if(loadOpts & AB_LOADOPT_RESULTS)
		strswitch(map[%FileType])
			case ANALYSISBROWSER_FILE_TYPE_IGOR:
				AB_LoadResultsFromIgor(map[%DiscLocation], map[%DataFolder])
				break
			case ANALYSISBROWSER_FILE_TYPE_NWBv1:
				// nothing to load
				break
			case ANALYSISBROWSER_FILE_TYPE_NWBv2:
				AB_LoadResultsFromNWB(map[%DiscLocation], map[%DataFolder])
				break
			default:
				FATAL_ERROR("invalid file type")
		endswitch
	endif

	deviceList = AB_LoadLabNotebook(discLocation)
	WAVE/T deviceWave = AB_SaveDeviceList(deviceList, map[%DataFolder])

	numDevices = GetNumberFromWaveNote(deviceWave, NOTE_INDEX)
	if(!numDevices && AB_FileHasStimsets(map))
		AB_FillListWave(map[%DiscLocation], map[%FileName], "", map[%DataFolder], map[%FileType], $"")
		return NaN
	endif
	for(i = 0; i < numDevices; i += 1)
		device = deviceWave[i]
		strswitch(map[%FileType])
			case ANALYSISBROWSER_FILE_TYPE_IGOR:
				AB_LoadSweepsConfigFromIgor(map[%DiscLocation], device)
				if(loadOpts & AB_LOADOPT_COMMENTS)
					AB_LoadUserCommentFromIgor(map[%DiscLocation], map[%DataFolder], device)
				endif
				break
			case ANALYSISBROWSER_FILE_TYPE_NWBv1: // fallthrough
			case ANALYSISBROWSER_FILE_TYPE_NWBv2:
				AB_LoadSweepsConfigFromNWB(map[%DiscLocation], map[%DataFolder], device)
				if(loadOpts & AB_LOADOPT_COMMENTS)
					AB_LoadUserCommentFromNWB(map[%DiscLocation], map[%DataFolder], device)
				endif
				break
			default:
				FATAL_ERROR("invalid file type")
		endswitch

		WAVE/I sweeps = GetAnalysisChannelSweepWave(map[%DataFolder], device)
		AB_FillListWave(map[%DiscLocation], map[%FileName], device, map[%DataFolder], map[%FileType], sweeps)
	endfor
End

/// @brief Check if the given file has a compatible version
///        which this version of the analysis browser can handle.
///
/// @param discLocation file to check, parameter to AB_GetMap()
static Function AB_HasCompatibleVersion(string discLocation)

	string   dataFolderPath
	variable numWavesLoaded

	WAVE/T map = AB_GetMap(discLocation)

	strswitch(map[%FileType])
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			DFREF targetDFR = GetAnalysisExpFolder(map[%DataFolder])
			dataFolderPath = GetMiesPathAsString()

			numWavesLoaded = AB_LoadDataWrapper(targetDFR, map[%DiscLocation], dataFolderPath, "pxpVersion", typeFlags = LOAD_DATA_TYPE_NUMBERS, recursive = 0)

			// no pxpVersion present
			// we can load the file
			if(numWavesLoaded == 0)
				DEBUGPRINT("Experiment has no pxp version so we can load it.")
				return 1
			endif

			NVAR/Z pxpVersion = targetDFR:pxpVersion
			ASSERT(NVAR_Exists(pxpVersion), "Expected existing pxpVersion")

			if(IsFinite(pxpVersion) && pxpVersion <= ANALYSIS_BROWSER_SUPP_VERSION)
				DEBUGPRINT("Experiment has a compatible pxp version.", var = pxpVersion)
				return 1
			endif

			printf "The experiment %s has the pxpVersion %d which this version of MIES can not handle.\r", map[%DiscLocation], pxpVersion
			ControlWindowToFront()
			return 0
			break
		case ANALYSISBROWSER_FILE_TYPE_NWBv1: // fallthrough
		case ANALYSISBROWSER_FILE_TYPE_NWBv2:
			return 1
		default:
			FATAL_ERROR("invalid file type")
	endswitch
End

static Function/S AB_GetSettingNumFiniteVals(WAVE wv, string device, variable sweepNo, string name)

	variable numRows

	WAVE/Z settings = GetLastSetting(wv, sweepNo, name, DATA_ACQUISITION_MODE)
	if(!WaveExists(settings))
		printf "Could not query the labnotebook of device %s for the setting %s\r", device, name
		return "unknown"
	endif

	WaveStats/Q/M=1 settings
	return num2str(V_npnts)
End

/// @brief Returns the Session Start Time as ISO8601 timestamp string
///        The required data must have been loaded before.
///
/// @param device       device name
/// @param firstSweepNo first sweep number of experiment
/// @param dataFolder   dataFolder reference of the specific loaded experiment data in AB
/// @param fileType     file type @ref AnalysisBrowserFileTypes
///
/// @returns session Start Time as ISO8601 timestamp string, an empty string if this information is not present
static Function/S AB_GetSessionStartTime(string device, variable firstSweepNo, string dataFolder, string fileType)

	string sessionStartTime
	variable sweepNo, size

	strswitch(fileType)
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			WAVE textualValues = GetAnalysLBTextualValues(dataFolder, device)
			sessionStartTime = GetLastSettingTextIndep(textualValues, firstSweepNo, HIGH_PREC_SWEEP_START_KEY, DATA_ACQUISITION_MODE)
			if(IsEmpty(sessionStartTime))
				WAVE/I sweeps = GetAnalysisChannelSweepWave(dataFolder, device)
				size = GetNumberFromWaveNote(sweeps, NOTE_INDEX)
				if(size == 0)
					return ""
				endif

				sweepNo = sweeps[0]
				if(!IsValidSweepNumber(sweepNo))
					return ""
				endif

				DFREF  sweepConfigDFR   = GetAnalysisDeviceConfigFolder(dataFolder, device)
				WAVE/Z firstSweepConfig = sweepConfigDFR:$GetConfigWaveName(sweepNo)
				if(!WaveExists(firstSweepConfig))
					return ""
				endif
				sessionStartTime = GetISO8601TimeStamp(secondsSinceIgorEpoch = LocalTimeToUTC(CreationDate(firstSweepConfig)))
			endif
			return sessionStartTime
		case ANALYSISBROWSER_FILE_TYPE_NWBv1: // fallthrough
		case ANALYSISBROWSER_FILE_TYPE_NWBv2:
			sessionStartTime = ROStr(GetAnalysisExpSessionStartTime(dataFolder))
			return sessionStartTime
		default:
			FATAL_ERROR("invalid file type")
	endswitch
End

/// @brief Creates list-view for AnalysisBrowser
///
/// Depends on LabNoteBook to be loaded prior to call.
///
/// @param diskLocation full file path of Project file
/// @param fileName     current Project's filename
/// @param device       current device, if device is empty only the experiment name is added
/// @param dataFolder   current Project's Lab Notebook DataFolder reference
/// @param fileType     current Project's file type, one of @ref AnalysisBrowserFileTypes
/// @param sweepNums    Wave containing all sweeps actually present for device
static Function AB_FillListWave(string diskLocation, string fileName, string device, string dataFolder, string fileType, WAVE/Z sweepNums)

	variable index, startIndex, numWaves, i, j, sweepNo, numRows, numCols, setCount, dim
	string str

	WAVE/T list = GetExperimentBrowserGUIList()
	startIndex = GetNumberFromWaveNote(list, NOTE_INDEX)
	index      = startIndex

	dim = FindDimLabel(list, COLS, "device")
	FindValue/TXOP=4/TEXT=diskLocation/RMD=[0, index - 1][dim][1] list
	if(V_value == -1)
		EnsureLargeEnoughWave(list, indexShouldExist = index, dimension = ROWS)
		list[index][%file][0]   = fileName
		list[index][%type][0]   = fileType
		list[index][%device][1] = diskLocation
	endif

	if(IsEmpty(device))
		SetNumberInWaveNote(list, NOTE_INDEX, index + 1)
		return NaN
	endif

	ASSERT(WaveExists(sweepNums), "sweepNums wave is empty.")

	WAVE numericalValues = GetAnalysLBNumericalValues(dataFolder, device)
	WAVE textualValues   = GetAnalysLBTextualValues(dataFolder, device)

	EnsureLargeEnoughWave(list, indexShouldExist = index, dimension = ROWS)
	list[index][%device][0] = device

	numWaves = GetNumberFromWaveNote(sweepNums, NOTE_INDEX)

	list[index][%'#sweeps'][0]    = num2istr(numWaves)
	list[index][%'start time'][0] = AB_GetSessionStartTime(device, sweepNums[0], dataFolder, fileType)
	index                        += 1

	for(i = 0; i < numWaves; i += 1)
		EnsureLargeEnoughWave(list, indexShouldExist = index, dimension = ROWS)

		sweepNo                = sweepNums[i]
		list[index][%sweep][0] = num2str(sweepNo)

		str                     = AB_GetSettingNumFiniteVals(numericalValues, device, sweepNo, "DAC")
		list[index][%'#DAC'][0] = str

		str                     = AB_GetSettingNumFiniteVals(numericalValues, device, sweepNo, "ADC")
		list[index][%'#ADC'][0] = str

		WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "Headstage Active", DATA_ACQUISITION_MODE)
		numRows = WaveExists(settings) ? NUM_HEADSTAGES : 0
		if(numRows > 0)
			list[index][%'#headstages'][0] = num2str(Sum(settings, 0, NUM_HEADSTAGES - 1))
		else
			list[index][%'#headstages'][0] = "unknown"
		endif

		WAVE/Z/T settingsText = GetLastSetting(textualValues, sweepNo, "Stim Wave Name", DATA_ACQUISITION_MODE)
		numRows = WaveExists(settingsText) ? NUM_HEADSTAGES : 0

		WAVE/Z settings = GetLastSetting(numericalValues, sweepNo, "Set Sweep Count", DATA_ACQUISITION_MODE)

		if(!numRows)
			list[index][%'stim sets'][0] = "unknown"
			list[index][%'set count'][0] = "-"
			index                       += 1
		else
			for(j = 0; j < numRows; j += 1)
				str = settingsText[j]

				if(isEmpty(str))
					continue
				endif

				EnsureLargeEnoughWave(list, indexShouldExist = index, dimension = ROWS)
				list[index][%'stim sets'][0] = str

				if(WaveExists(settings))
					list[index][%'set count'][0] = num2istr(settings[j])
				else
					list[index][%'set count'][0] = "-"
				endif

				index += 1
			endfor
		endif
	endfor

	SetNumberInWaveNote(list, NOTE_INDEX, index)
	list[startIndex, index - 1][%sweep][1] = AB_GetRowHash(list, p)
End

static Function/S AB_GetRowHash(WAVE/T list, variable row)

	Duplicate/FREE/RMD=[row][][] list, rowWave

	return WaveHash(rowWave, 4)
End

/// @brief Load waves from a packed experiment file
///
/// This function is special as it does change the CDF!
///
/// @param tmpDFR         Temporary work folder, function returns with that folder as CDF
/// @param expFilePath    full path to the experiment file on disc
/// @param datafolderPath igor datafolder to look for the waves inside the experiment
/// @param listOfNames    list of names of waves/strings/numbers to load
/// @param typeFlags      [optional, defaults to 1 (waves)] data types to load, valid values
///                       are the same as for `LoadData`, see also @ref LoadDataConstants
/// @param recursive      [optional, defaults to 1] when set loads data recursive from the experiment file
/// @param regEx          [optional, defaults to ".*"] when set matches the given regular expression to the object names found for deciding what to load
///                       Can be combined with listOfNames. The matching is case insensitive.
///
/// @returns number of loaded items
static Function AB_LoadDataWrapper(DFREF tmpDFR, string expFilePath, string datafolderPath, string listOfNames, [variable typeFlags, variable recursive, string regEx])

	variable numEntries, i, debugOnError, objectTypeMask
	string cdf, fileNameWOExtension, baseFolder, extension, expFileOrFolder
	string str, list, regexp

	ASSERT(DataFolderExistsDFR(tmpDFR), "tmpDFR does not exist")
	ASSERT(!isEmpty(expFilePath), "empty path")
	ASSERT(!isEmpty(dataFolderPath), "empty datafolder path")
	ASSERT(strlen(listOfNames) < 1000, "LoadData limit for listOfNames length reached")

	if(ParamIsDefault(typeFlags))
		typeFlags = 1
	else
		ASSERT(typeFlags == COUNTOBJECTS_WAVES || typeFlags == COUNTOBJECTS_VAR || typeFlags == COUNTOBJECTS_STR || typeFlags == COUNTOBJECTS_DATAFOLDER, "Unknown typeFlags, bitmasks are not supported")
	endif
	recursive = ParamisDefault(recursive) ? 1 : !!recursive
	if(ParamIsDefault(regEx))
		regEx = ".*"
	else
		regEx = "(?i)" + regEx
	endif
	objectTypeMask = 1 << (typeFlags - 1)

	fileNameWOExtension = GetBaseName(expFilePath)
	baseFolder          = GetFolder(expFilePath)
	extension           = GetFileSuffix(expFilePath)

	ASSERT(cmpstr(extension, "uxp"), "No support for unpacked experiments")
	expFileOrFolder = expFilePath

	DFREF savedDF = GetDataFolderDFR()
	SetDataFolder tmpDFR

	// work around LoadData not respecting AbortOnRTE properly
	debugOnError = DisableDebugOnError()

	// also with "/Q" LoadData still complains if the subfolder path does not exist
	AssertOnAndClearRTError()
	try
		if(FileExists(expFileOrFolder))
			if(recursive)
				LoadData/Q/R/L=(typeFlags)/S=dataFolderPath/J=listOfNames/GREP={regEx, 1, objectTypeMask, 0}/O=1 expFileOrFolder; AbortOnRTE
			else
				LoadData/Q/L=(typeFlags)/S=dataFolderPath/J=listOfNames/GREP={regEx, 1, objectTypeMask, 0}/O=1 expFileOrFolder; AbortOnRTE
			endif
		elseif(FolderExists(expFileOrFolder))
			if(recursive)
				LoadData/Q/D/R/L=(typeFlags)/J=listOfNames/GREP={regEx, 1, objectTypeMask, 0}/O=1 expFileOrFolder + ":" + dataFolderPath; AbortOnRTE
			else
				LoadData/Q/D/L=(typeFlags)/J=listOfNames/GREP={regEx, 1, objectTypeMask, 0}/O=1 expFileOrFolder + ":" + dataFolderPath; AbortOnRTE
			endif
		else
			sprintf str, "The experiment file/folder \"%s\" could not be found!\r", ParseFilePath(5, expFileOrFolder, "\\", 0, 0)
			DoAlert/T="Error in AB_LoadDataWrapper" 0, str
			Abort
		endif
	catch
		ClearRTError()
		SetDataFolder savedDF
		ResetDebugOnError(debugOnError)
		return 0
	endtry

	SetDataFolder savedDF
	ResetDebugOnError(debugOnError)

	RemoveAllEmptyDataFolders(tmpDFR)
	if(!DataFolderExistsDFR(tmpDFR))
		return 0
	endif

	regexp = "(?i)" + ConvertListToRegexpWithAlternations(listOfNames)
	list   = GetListOfObjects(tmpDFR, regexp, recursive = recursive, typeFlag = typeFlags)

	return ItemsInList(list)
End

/// @brief Returns a wave containing all present sweep numbers
///
/// @param dataFolder    DataFolder of HDF5 or Experiment File where LabNoteBook is saved
/// @param device        device for which to get sweeps.
/// @param clean         Variable indicating if ouput can contain duplicate values
static Function/WAVE AB_GetSweepsFromLabNotebook(string dataFolder, string device, [variable clean])

	if(ParamIsDefault(clean))
		clean = 0
	endif

	DFREF dfr = GetAnalysisLabNBFolder(dataFolder, device)
	WAVE/SDFR=dfr $LBN_NUMERICAL_VALUES_NAME

	variable sweepCol = GetSweepColumn(numericalValues)
	MatrixOP/FREE sweepNums = col(numericalValues, sweepCol)
	Redimension/N=-1 sweepNums

	if(clean)
		return GetUniqueEntries(sweepNums)
	endif

	return sweepNums
End

/// @brief Returns a wave containing all present sweep numbers
///
/// Function uses Config Waves from Igor Experiment to determine present sweeps
///
/// @param discLocation  location of Experiment File on Disc.
///                      ID in AnalysisBrowserMap
/// @param device        device for which to get sweeps.
static Function AB_LoadSweepsConfigFromIgor(string discLocation, string device)

	variable sweepNumber, numSweeps, i, numConfigWaves
	string listSweepConfig, sweepConfig
	WAVE/T map            = AB_GetMap(discLocation)
	DFREF  SweepConfigDFR = GetAnalysisDeviceConfigFolder(map[%DataFolder], device)
	WAVE/I sweeps         = GetAnalysisChannelSweepWave(map[%DataFolder], device)

	// Load Sweep Config Waves
	numConfigWaves = AB_LoadSweepConfigData(map[%DiscLocation], map[%DataFolder], device)
	if(!numConfigWaves)
		return NaN
	endif
	listSweepConfig = GetListOfObjects(sweepConfigDFR, ".*")

	// store Sweep Numbers in wave
	numSweeps = ItemsInList(listSweepConfig)
	EnsureLargeEnoughWave(sweeps, indexShouldExist = numSweeps, dimension = ROWS, initialValue = -1)
	for(i = 0; i < numSweeps; i += 1)
		sweepConfig = StringFromList(i, listSweepConfig)
		sweepNumber = ExtractSweepNumber(sweepConfig)
		sweeps[i]   = sweepNumber
	endfor
	SetNumberInWaveNote(sweeps, NOTE_INDEX, numSweeps)
End

/// @brief Analyse data in NWB file and sort as sweeps.
///
/// @todo: Update this function for the use with SweepTable
///
/// @param discLocation  location of NWB File on Disc.
///                      ID in AnalysisBrowserMap
/// @param dataFolder    datafolder of the project
/// @param device        device for which to get sweeps.
static Function AB_LoadSweepsConfigFromNWB(string discLocation, string dataFolder, string device)

	variable h5_fileID, nwbVersion
	string channelList

	WAVE/I sweeps = GetAnalysisChannelSweepWave(dataFolder, device)

	// open hdf5 file
	h5_fileID = H5_OpenFile(discLocation)

	// load from /acquisition
	nwbVersion  = GetNWBMajorVersion(ReadNWBVersion(h5_fileID))
	channelList = ReadAcquisition(h5_fileID, nwbVersion)
	WAVE/T acquisition = GetAnalysisChannelAcqWave(dataFolder, device)
	AB_StoreChannelsBySweep(h5_fileID, nwbVersion, channelList, sweeps, acquisition)

	// load from /stimulus/presentation
	channelList = ReadStimulus(h5_fileID)
	WAVE/T stimulus = GetAnalysisChannelStimWave(dataFolder, device)
	AB_StoreChannelsBySweep(h5_fileID, nwbVersion, channelList, sweeps, stimulus)

	SVAR sessionStartTime = $GetAnalysisExpSessionStartTime(dataFolder)
	sessionStartTime = NWB_ReadSessionStartTimeImpl(h5_fileID)

	// close hdf5 file
	H5_CloseFile(h5_fileID)
End

/// @brief Store channelList in storage wave according to index in sweeps wave
///
/// @todo Update this function for the use with SweepTable
static Function AB_StoreChannelsBySweep(variable groupID, variable nwbVersion, string channelList, WAVE/I sweeps, WAVE/T storage)

	variable numChannels, numSweeps, i, sweepNo, sweep_table_id
	string channelString

	numChannels = ItemsInList(channelList)
	numSweeps   = GetNumberFromWaveNote(sweeps, NOTE_INDEX)

	EnsureLargeEnoughWave(storage, indexShouldExist = numSweeps, dimension = ROWS)
	storage = ""

	WAVE/Z   SweepTableNumber
	WAVE/Z/T SweepTableSeries
	if(nwbVersion == 2)
		[SweepTableNumber, SweepTableSeries] = LoadSweepTable(groupID, nwbVersion)
	endif

	for(i = 0; i < numChannels; i += 1)
		channelString = StringFromList(i, channelList)
		if(nwbVersion == 2)
			WAVE indices = FindIndizes(SweepTableSeries, str = channelString)
			ASSERT(DimSize(indices, ROWS) == 1, "Invalid Amount of Sweep Number Associated in " + channelString)
			sweepNo = SweepTableNumber[indices[0]]
		else
			sweepNo = LoadSweepNumber(groupID, channelString, nwbVersion)
		endif
		FindValue/I=(sweepNo)/S=0 sweeps
		ASSERT(isFinite(sweepNo), "Invalid Sweep Number Associated in " + channelString)
		if(V_Value == -1)
			numSweeps += 1
			EnsureLargeEnoughWave(sweeps, indexShouldExist = numSweeps, dimension = ROWS, initialValue = -1)
			EnsureLargeEnoughWave(storage, indexShouldExist = numSweeps, dimension = ROWS)
			sweeps[numSweeps - 1]  = sweepNo
			storage[numSweeps - 1] = AddListItem(channelString, "")
		else
			storage[V_Value] = AddListItem(channelString, storage[V_Value])
		endif
	endfor

	SetNumberInWaveNote(sweeps, NOTE_INDEX, numSweeps)
	SetNumberInWaveNote(storage, NOTE_INDEX, numSweeps)
End

static Function AB_LoadHistoryAndLogsFromFile(string discLocation, string dataFolder, string fileType, [variable overwrite])

	overwrite = ParamIsDefault(overwrite) ? 0 : !!overwrite

	DFREF targetDFR = GetAnalysisExpGeneralFolder(dataFolder)
	if(overwrite)
		KillOrMoveToTrash(dfr = targetDFR)
	else
		if(!IsDataFolderEmpty(targetDFR))
			AB_ShowHistoryAndLogs(discLocation, dataFolder)
			return 0
		endif
	endif

	strswitch(fileType)
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			if(!AlreadyCalledOnce(CO_AB_LOADHISTORYFROMPXP))
				print "Loading of history from Igor Pro PXP files is not supported."
				ControlWindowToFront()
			endif
			break
		case ANALYSISBROWSER_FILE_TYPE_NWBv1: // fallthrough
		case ANALYSISBROWSER_FILE_TYPE_NWBv2:
			AB_LoadHistoryAndLogsFromNWB(discLocation, dataFolder, fileType)
			break
		default:
			FATAL_ERROR("invalid file type")
	endswitch

	AB_ShowHistoryAndLogs(discLocation, dataFolder)
End

static Function AB_ShowHistoryAndLogs(string discLocation, string expFolder)

	string win, title, fName

	DFREF targetDFR = GetAnalysisExpGeneralFolder(expFolder)
	fName = ParseFilePath(0, discLocation, ":", 1, 0)

	WAVE/T w = targetDFR:HistoryAndLogs
	win = CleanupName(discLocation, 0)
	if(!WindowExists(win))
		title = fName + "->HistoryAndLogs"
		NewNotebook/F=0/K=1/OPTS=8/N=$win as title
		Notebook $win, text=w[0]
	else
		DoWindow/F $win
	endif
End

static Function AB_LoadHistoryAndLogsFromNWB(string nwbFilePath, string expFolder, string fileType)

	variable h5_fileID, generalGroup
	string historyName, groupName

	h5_fileID = H5_OpenFile(nwbFilePath)

	groupName    = "/general"
	generalGroup = H5_OpenGroup(h5_fileID, groupName)

	DFREF targetDFR = GetAnalysisExpGeneralFolder(expFolder)
	strswitch(fileType)
		case ANALYSISBROWSER_FILE_TYPE_NWBv1:
			historyName = GetHistoryAndLogFileDatasetName(1)
			break
		case ANALYSISBROWSER_FILE_TYPE_NWBv2:
			historyName = GetHistoryAndLogFileDatasetName(2)
			break
		default:
			FATAL_ERROR("Unknown NWB file type")
	endswitch

	WAVE wv = H5_LoadDataset(generalGroup, historyName)
	MoveWave wv, targetDFR:HistoryAndLogs

	HDF5CloseGroup/Z generalGroup
	H5_CloseFile(h5_fileID)
End

static Function AB_LoadTPStorageFromFile(string discLocation, string dataFolder, string fileType, string device, [variable overwrite])

	if(ParamIsDefault(overwrite))
		overwrite = 0
	else
		overwrite = !!overwrite
	endif

	DFREF targetDFR = GetAnalysisDeviceTestpulse(dataFolder, device)

	if(overwrite)
		KillOrMoveToTrash(dfr = targetDFR)
	else
		if(!IsDataFolderEmpty(targetDFR))
			return 0
		endif
	endif

	strswitch(fileType)
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			return AB_LoadTPStorageFromIgor(discLocation, dataFolder, device)
			break
		case ANALYSISBROWSER_FILE_TYPE_NWBv1: // fallthrough
		case ANALYSISBROWSER_FILE_TYPE_NWBv2:
			return AB_LoadTPStorageFromNWB(discLocation, dataFolder, device)
			break
		default:
			FATAL_ERROR("Invalid file type")
	endswitch
End

static Function AB_LoadTPStorageFromIgor(string expFilePath, string expFolder, string device)

	string dataFolderPath

	DFREF targetDFR = GetAnalysisDeviceTestpulse(expFolder, device)
	dataFolderPath = GetDeviceTestPulseAsString(device)
	dataFolderPath = AB_TranslatePath(dataFolderPath, expFolder)

	return AB_LoadDataWrapper(targetDFR, expFilePath, dataFolderPath, "", regex = TP_STORAGE_REGEXP, recursive = 0)
End

static Function AB_LoadTPStorageFromNWB(string nwbFilePath, string expFolder, string device)

	variable h5_fileID, testpulseGroup, numEntries, i
	string dataFolderPath, list, name, groupName

	h5_fileID = H5_OpenFile(nwbFilePath)

	groupName      = "/general/testpulse/" + device
	testpulseGroup = H5_OpenGroup(h5_fileID, groupName)

	list = H5_ListGroupMembers(testpulseGroup, groupName)
	list = GrepList(list, TP_STORAGE_REGEXP)

	DFREF targetDFR = GetAnalysisDeviceTestpulse(expFolder, device)

	numEntries = ItemsInList(list)
	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, list)
		WAVE wv = H5_LoadDataset(testpulseGroup, name)
		MoveWave wv, targetDFR
	endfor

	HDF5CloseGroup/Z testpulseGroup
	H5_CloseFile(h5_fileID)
End

static Function AB_LoadStoredTestpulsesFromNWB(string nwbFilePath, string expFolder, string device)

	variable h5_fileID, testpulseGroup, numEntries, i
	string dataFolderPath, list, name, groupName

	WAVE/WAVE wv = GetAnalysisStoredTestPulses(expFolder, device)

	if(DimSize(wv, ROWS) > 0)
		return NaN
	endif

	h5_fileID = H5_OpenFile(nwbFilePath)

	groupName      = "/general/testpulse/" + device
	testpulseGroup = H5_OpenGroup(h5_fileID, groupName)

	list = H5_ListGroupMembers(testpulseGroup, groupName)
	list = GrepList(list, STORED_TESTPULSES_REGEXP)

	numEntries = ItemsInList(list)
	Redimension/N=(numEntries) wv

	for(i = 0; i < numEntries; i += 1)
		name  = StringFromList(i, list)
		wv[i] = H5_LoadDataset(testpulseGroup, name)
	endfor

	SetNumberInWaveNote(wv, NOTE_INDEX, numEntries)

	HDF5CloseGroup/Z testpulseGroup
	H5_CloseFile(h5_fileID)
End

static Function AB_LoadResultsFromIgor(string expFilePath, string expFolder)

	string   dataFolderPath
	variable numWavesLoaded

	DFREF targetDFR = GetAnalysisResultsFolder(expFolder)
	dataFolderPath = GetResultsFolderAsString()

	numWavesLoaded = AB_LoadDataWrapper(targetDFR, expFilePath, dataFolderPath, "")

	return numWavesLoaded
End

static Function AB_LoadResultsFromNWB(string nwbFilePath, string expFolder)

	variable h5_fileID, resultsGroup, numEntries, i
	string list, name, groupName

	DFREF dfr = GetAnalysisResultsFolder(expFolder)

	if(!IsDataFolderEmpty(dfr))
		return NaN
	endif

	h5_fileID = H5_OpenFile(nwbFilePath)

	groupName    = NWB_RESULTS
	resultsGroup = H5_OpenGroup(h5_fileID, groupName)

	if(IsNaN(resultsGroup))
		// results waves do not exist
		return NaN
	endif

	list = H5_ListGroupMembers(resultsGroup, groupName)

	numEntries = ItemsInList(list)

	for(i = 0; i < numEntries; i += 1)
		name = StringFromList(i, list)
		WAVE/Z wv = H5_LoadDataset(resultsGroup, name)

		if(!WaveExists(wv))
			continue
		endif

		MoveWave wv, dfr
	endfor

	HDF5CloseGroup/Z resultsGroup
	H5_CloseFile(h5_fileID)
End

static Function AB_LoadUserCommentFromIgor(string expFilePath, string expFolder, string device)

	string   dataFolderPath
	variable numStringsLoaded

	DFREF targetDFR = GetAnalysisDeviceFolder(expFolder, device)
	dataFolderPath = GetDevicePathAsString(device)
	dataFolderPath = AB_TranslatePath(dataFolderPath, expFolder)

	numStringsLoaded = AB_LoadDataWrapper(targetDFR, expFilePath, dataFolderPath, "userComment", typeFlags = LOAD_DATA_TYPE_STRING, recursive = 0)

	return numStringsLoaded
End

static Function AB_LoadUserCommentFromNWB(string nwbFilePath, string expFolder, string device)

	string groupName, comment, datasetName
	variable h5_fileID, commentGroup

	DFREF targetDFR = GetAnalysisDeviceFolder(expFolder, device)
	h5_fileID = H5_OpenFile(nwbFilePath)

	groupName    = "/general/user_comment/" + device
	commentGroup = H5_OpenGroup(h5_fileID, groupName)

	comment = ReadTextDataSetAsString(commentGroup, "userComment")
	HDF5CloseGroup/Z commentGroup

	H5_CloseFile(h5_fileID)

	string/G targetDFR:userComment = comment
End

static Function/S AB_LoadLabNotebook(string discLocation)

	string device, deviceList, err
	string deviceListChecked = ""
	variable numDevices, i

	WAVE/T map = AB_GetMap(discLocation)
	deviceList = AB_LoadLabNoteBookFromFile(discLocation)

	numDevices = ItemsInList(deviceList)
	for(i = 0; i < numDevices; i += 1)
		device = StringFromList(i, deviceList)

		// check if data was loaded
		DFREF dfr = GetAnalysisLabNBFolder(map[%DataFolder], device)
		if(!AB_checkLabNotebook(dfr))
			KillOrMoveToTrash(dfr = dfr)
			continue
		endif

		AB_updateLabelsInLabNotebook(dfr)

		deviceListChecked = AddListItem(device, deviceListchecked, ";", Inf)
	endfor

	numDevices -= ItemsInList(deviceListChecked)
	if(numDevices > 0)
		sprintf err, "Dropped %d Loaded Items\r", numDevices
		DEBUGPRINT(err)
	endif

	return deviceListChecked
End

static Function/S AB_LoadLabNotebookFromFile(string discLocation)

	string deviceList = ""
	WAVE/T map        = AB_GetMap(discLocation)

	strswitch(map[%FileType])
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			deviceList = AB_LoadLabNotebookFromIgor(map[%DiscLocation])
			break
		case ANALYSISBROWSER_FILE_TYPE_NWBv1: // fallthrough
		case ANALYSISBROWSER_FILE_TYPE_NWBv2:
			deviceList = AB_LoadLabNotebookFromNWB(map[%DiscLocation])
			break
		default:
			FATAL_ERROR("Unsupported file type")
			break
	endswitch

	return deviceList
End

static Function/S AB_LoadLabNotebookFromIgor(string discLocation)

	string labNotebookWaves, labNotebookPath, type, number, path, basepath, device, str
	string deviceList = ""
	variable numEntries, i, j, numWavesLoaded, numNumbers

	WAVE/T experiment = AB_GetMap(discLocation)

	if(cmpstr(experiment[%FileType], ANALYSISBROWSER_FILE_TYPE_IGOR))
		return "" // can not load file
	endif

	// load notebook waves from file to (temporary) data folder
	labNotebookWaves  = "settingsHistory;keyWave;txtDocWave;txtDocKeyWave;"
	labNotebookWaves += "numericalKeys;textualKeys;numericalValues;textualValues"
	labNotebookPath   = GetLabNotebookFolderAsString()
	DFREF newDFR = UniqueDataFolder(GetAnalysisFolder(), "igorLoadNote")
	numWavesLoaded = AB_LoadDataWrapper(newDFR, discLocation, labNotebookPath, labNotebookWaves)

	if(numWavesLoaded <= 0)
		KillOrMoveToTrash(dfr = newDFR)
		return ""
	endif

	numEntries = CountObjectsDFR(newDFR, COUNTOBJECTS_DATAFOLDER)
	numNumbers = ItemsInList(DEVICE_NUMBERS)
	for(i = 0; i < numEntries; i += 1)

		type = GetIndexedObjNameDFR(newDFR, COUNTOBJECTS_DATAFOLDER, i)

		if(GrepString(type, ITC_DEVICE_REGEXP))
			// ITC hardware is in a specific subfolder
			for(j = 0; j < numNumbers; j += 1)
				number = StringFromList(j, DEVICE_NUMBERS)
				device = HW_ITC_BuildDeviceString(type, number)
				path   = GetDataFolder(1, newDFR) + type + ":Device" + number

				AB_LoadLabNotebookFromIgorLow(discLocation, path, device, deviceList)
			endfor
		else // other hardware not
			device = type
			path   = GetDataFolder(1, newDFR) + device
			AB_LoadLabNotebookFromIgorLow(discLocation, path, device, deviceList)
		endif
	endfor

	KillOrMoveToTrash(dfr = newDFR)

	return deviceList
End

/// @brief Try loading the four labnotebooks from path
///
/// @param[in] discLocation    experiment location on disc
/// @param[in] path            datafolder path which holds the labnotebooks (might not exist)
/// @param[in] device          name of the device
/// @param[in, out] deviceList list of loaded devices, for successful loads we add to that list
static Function AB_LoadLabNotebookFromIgorLow(string discLocation, string path, string device, string &deviceList)

	string basepath

	if(!DataFolderExists(path))
		return NaN
	endif

	WAVE/T experiment = AB_GetMap(discLocation)

	// search for Loaded labNotebookWaves
	// first try the new wave names and then as fallback
	// the old ones
	// Supports old/new wavename mixes although these should not
	// exist in the wild.

	WAVE/Z/SDFR=$path $LBN_NUMERICAL_KEYS_NAME

	if(!WaveExists(numericalKeys))
		basepath = path + ":KeyWave"
		if(DataFolderExists(basepath))
			WAVE/Z/SDFR=$basepath numericalKeys = keyWave
		endif
	endif

	WAVE/Z/SDFR=$path $LBN_NUMERICAL_VALUES_NAME

	if(!WaveExists(numericalValues))
		basepath = path + ":settingsHistory"
		if(DataFolderExists(basepath))
			WAVE/Z/SDFR=$basepath numericalValues = settingsHistory
		endif
	endif

	WAVE/Z/SDFR=$path $LBN_TEXTUAL_KEYS_NAME

	if(!WaveExists(textualKeys))
		basepath = path + ":TextDocKeyWave"
		if(DataFolderExists(basepath))
			WAVE/Z/SDFR=$basepath textualKeys = txtDocKeyWave
		endif
	endif

	WAVE/Z/SDFR=$path $LBN_TEXTUAL_VALUES_NAME

	if(!WaveExists(textualValues))
		basepath = path + ":textDocumentation"
		if(DataFolderExists(basepath))
			WAVE/Z/SDFR=$basepath textualValues = txtDocWave
		endif
	endif

	if(!WaveExists(numericalKeys) || !WaveExists(numericalValues) || !WaveExists(textualKeys) || !WaveExists(textualValues))
		printf "Could not find all four labnotebook waves, dropping all data from device %s in file %s\r", device, discLocation
		return NaN
	endif

	// copy and rename loaded waves to Analysisbrowser directory
	DFREF dfr = GetAnalysisLabNBFolder(experiment[%DataFolder], device)
	Duplicate/O numericalKeys, dfr:numericalKeys/WAVE=numericalKeys
	Duplicate/O numericalValues, dfr:numericalValues/WAVE=numericalValues
	Duplicate/O textualKeys, dfr:textualKeys/WAVE=textualKeys
	Duplicate/O textualValues, dfr:textualValues

	DEBUGPRINT("Loaded Igor labnotebook for device: ", str = device)
	deviceList = AddListItem(device, deviceList, ";", Inf)
End

static Function/S AB_LoadLabNotebookFromNWB(string discLocation)

	variable numDevices, numLoaded, i
	variable h5_fileID, h5_notebooksID
	string notebookList, deviceList, device

	WAVE/T nwb = AB_GetMap(discLocation)

	AssertOnAndClearRTError()
	try
		h5_fileID = H5_OpenFile(nwb[%DiscLocation])
	catch
		ClearRTError()
		printf "Could not open the NWB file %s.\r", nwb[%DiscLocation]
		H5_CloseFile(h5_fileID)
		return ""
	endtry

	notebookList   = ReadLabNoteBooks(h5_fileID)
	h5_notebooksID = H5_OpenGroup(h5_fileID, "/general/labnotebook")

	numDevices = ItemsInList(notebookList)
	devicelist = ""
	for(i = 0; i < numDevices; i += 1)
		device = StringFromList(i, notebookList)

		DFREF notebookDFR = GetAnalysisLabNBFolder(nwb[%DataFolder], device)
		numLoaded = NWB_LoadLabNoteBook(h5_notebooksID, device, notebookDFR)
		if(numLoaded != 4)
			printf "Could not find four labnotebook waves in nwb file for device %s\r", device
			KillOrMoveToTrash(dfr = NotebookDFR)
			continue
		endif

		/// add current device to output devicelist
		DEBUGPRINT("Loaded NWB labnotebook for device: ", str = device)
		devicelist = AddListItem(device, devicelist, ";", Inf)
	endfor

	// H5_CloseFile closes all associated open groups.
	HDF5CloseGroup/Z h5_notebooksID
	H5_CloseFile(h5_fileID)

	return devicelist
End

///@brief function checks if LabNoteBook Waves do exist.
///@param  dfr path to labNoteBook dataFolder reference.
///@return 0 labNotebook does not exist.
///        1 labNoteBook exists. also update dimension lables
static Function AB_checkLabNotebook(DFREF dfr)

	WAVE/Z/SDFR=dfr $LBN_NUMERICAL_KEYS_NAME
	WAVE/Z/SDFR=dfr $LBN_NUMERICAL_VALUES_NAME
	WAVE/Z/SDFR=dfr $LBN_TEXTUAL_KEYS_NAME
	WAVE/Z/SDFR=dfr $LBN_TEXTUAL_VALUES_NAME

	if(!WaveExists(numericalKeys) || !WaveExists(numericalValues) || !WaveExists(textualKeys) || !WaveExists(textualValues))
		printf "Data is not in correct Format for %s\r", GetDataFolder(0, dfr)
		return 0
	endif

	return 1
End

/// @brief add dimension labels in older versions of igor-MIES and hdf5-loaded data
///        overwrite invalid dim labels (labnotebook waves created with versions prior to a8f0f43)
static Function AB_updateLabelsInLabNotebook(DFREF dfr)

	string str

	WAVE/Z/SDFR=dfr $LBN_NUMERICAL_KEYS_NAME
	WAVE/Z/SDFR=dfr $LBN_NUMERICAL_VALUES_NAME
	WAVE/Z/SDFR=dfr $LBN_TEXTUAL_KEYS_NAME
	WAVE/Z/SDFR=dfr $LBN_TEXTUAL_VALUES_NAME

	str = GetDimLabel(textualValues, COLS, 0)
	if(isEmpty(str) || !cmpstr(str, "dimLabelText"))
		LBN_SetDimensionLabels(textualKeys, textualValues)
	endif

	str = GetDimLabel(numericalKeys, COLS, 0)
	if(isEmpty(str) || !cmpstr(str, "dimLabelText"))
		LBN_SetDimensionLabels(numericalKeys, numericalValues)
	endif

	return 1
End

static Function/S AB_TranslatePath(string path, string expFolder)

	DFREF dfr        = GetAnalysisExpFolder(expFolder)
	NVAR  pxpVersion = $GetPxpVersionForAB(dfr)

	if(isNaN(pxpVersion) || pxpVersion == 1)
		// old data in expFolder still uses ITCDevices but
		// path already uses the new name
		return ReplaceString(":HardwareDevices", path, ":ITCDevices")
	endif

	// pxpVersion 2
	// HardwareDevices is used consistently

	return path
End

/// @brief Load all `Config_Sweep_*` waves from the given experiment file or folder and the given device
static Function AB_LoadSweepConfigData(string expFilePath, string expFolder, string device)

	string dataFolderPath

	DFREF targetDFR = GetAnalysisDeviceConfigFolder(expFolder, device)
	dataFolderPath = GetDeviceDataPathAsString(device)
	dataFolderPath = AB_TranslatePath(dataFolderPath, expFolder)

	return AB_LoadDataWrapper(targetDFR, expFilePath, dataFolderPath, "", regEx = DATA_CONFIG_REGEXP, recursive = 0)
End

/// @brief Expand all tree views in the given column
static Function AB_ExpandListColumn(variable col)

	variable numRows, row, i, mask

	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	WAVE   selBits = AB_ReturnAndClearGUISelBits()
	WAVE/Z indizes = FindIndizes(expBrowserSel, col = col, var = LISTBOX_TREEVIEW)
	AB_SetGUISelBits(selBits)

	if(!WaveExists(indizes))
		return NaN
	endif

	numRows = DimSize(indizes, ROWS)
	for(i = numRows - 1; i >= 0; i -= 1)

		row  = indizes[i]
		mask = expBrowserSel[row][col]
		if(mask & LISTBOX_TREEVIEW_EXPANDED)
			continue
		endif

		expBrowserSel[row][col] = SetBit(mask, LISTBOX_TREEVIEW_EXPANDED)
		AB_ExpandListEntry(row, col)
	endfor
End

/// @brief Collapse all tree views in the given column
static Function AB_CollapseListColumn(variable col)

	variable numRows, row, i, mask

	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	WAVE   selBits = AB_ReturnAndClearGUISelBits()
	WAVE/Z indizes = FindIndizes(expBrowserSel, col = col, var = LISTBOX_TREEVIEW | LISTBOX_TREEVIEW_EXPANDED)
	AB_SetGUISelBits(selBits)

	if(!WaveExists(indizes))
		return NaN
	endif

	numRows = DimSize(indizes, ROWS)
	for(i = numRows - 1; i >= 0; i -= 1)

		row  = indizes[i]
		mask = expBrowserSel[row][col]
		if(mask & LISTBOX_TREEVIEW_EXPANDED)
			expBrowserSel[row][col] = ClearBit(mask, LISTBOX_TREEVIEW_EXPANDED)
			AB_CollapseListEntry(row, col)
		endif
	endfor
End

/// @brief Set the selection bits of the experiment browser ListBox selection wave
///
/// @param selBits wave returned by AB_ReturnAndClearGUISelBits
static Function AB_SetGUISelBits(WAVE selBits)

	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	expBrowserSel[][0] = expBrowserSel[p][0] | selBits[p]
End

/// @brief Return the selection bits from the experiment browser ListBox selection wave and clear them
static Function/WAVE AB_ReturnAndClearGUISelBits()

	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	Make/FREE/N=(DimSize(expBrowserSel, ROWS)) selBits = expBrowserSel[p][0] & LISTBOX_SELECT_OR_SHIFT_SELECTION
	expBrowserSel[][0] = expBrowserSel[p][0] & ~LISTBOX_SELECT_OR_SHIFT_SELECTION

	return selBits
End

/// @brief Collapse the given treeview
static Function AB_CollapseListEntry(variable row, variable col)

	variable mask, last, i, j, colSize, hasTreeView

	WAVE/T expBrowserList    = GetExperimentBrowserGUIList()
	WAVE   expBrowserSel     = GetExperimentBrowserGUISel()
	WAVE/T expBrowserListBak = CreateBackupWave(expBrowserList)
	WAVE   expBrowserSelBak  = CreateBackupWave(expBrowserSel)

	mask = expBrowserSel[row][col]
	ASSERT((mask & LISTBOX_TREEVIEW) && !(mask & LISTBOX_TREEVIEW_EXPANDED), "listbox entry is not a treeview expansion node or is already collapsed")

	last    = AB_GetRowWithNextTreeView(expBrowserSel, row, col)
	colSize = DimSize(expBrowserSel, COLS)
	for(i = last - 1; i >= row; i -= 1)
		hasTreeView = i == row
		for(j = col + 1; j < colSize; j += 1)
			mask = expBrowserSel[i][j]
			if(mask & (LISTBOX_TREEVIEW | LISTBOX_TREEVIEW_EXPANDED))
				expBrowserSel[i][j] = ClearBit(mask, LISTBOX_TREEVIEW_EXPANDED)
				hasTreeView         = 1
			endif
		endfor
		if(!hasTreeView)
			DeleteWavePoint(expBrowserSel, ROWS, index = i)
			DeleteWavePoint(expBrowserList, ROWS, index = i)
		endif
	endfor
End

/// @brief Expand the given treeview
static Function AB_ExpandListEntry(variable row, variable col)

	variable mask, last, length
	variable sourceRowStart, sourceRowEnd, targetRow
	variable i, j, colSize, val, lastExpandedRow

	WAVE/T expBrowserList    = GetExperimentBrowserGUIList()
	WAVE   expBrowserSel     = GetExperimentBrowserGUISel()
	WAVE/T expBrowserListBak = CreateBackupWave(expBrowserList)
	WAVE   expBrowserSelBak  = CreateBackupWave(expBrowserSel)

	mask = expBrowserSel[row][col]
	ASSERT((mask & LISTBOX_TREEVIEW) && (mask & LISTBOX_TREEVIEW_EXPANDED), "listbox entry is not a treeview expansion node or already expanded")

	lastExpandedRow = NaN
	last            = AB_GetRowWithNextTreeView(expBrowserSel, row, col)
	colSize         = DimSize(expBrowserSel, COLS)
	for(i = last - 1; i >= row; i -= 1)
		for(j = colSize - 1; j >= col; j -= 1)
			val = (i == row && j == col) ? ClearBit(mask, LISTBOX_TREEVIEW_EXPANDED) : expBrowserSel[i][j]
			if(!(val & LISTBOX_TREEVIEW))
				continue
			endif

			if(val & LISTBOX_TREEVIEW_EXPANDED)
				lastExpandedRow = i
				continue
			endif

			if(lastExpandedRow != i)
				sourceRowStart = AB_GetListRowWithSameHash(expBrowserListBak, expBrowserList[i][%sweep][1]) + 1
				sourceRowEnd   = AB_GetRowWithNextTreeView(expBrowserSelBak, sourceRowStart - 1, j) - 1
				length         = sourceRowEnd - sourceRowStart + 1
				if(length > 0)
					targetRow = i + 1
					InsertPoints targetRow, length, expBrowserList, expBrowserSel
					expBrowserList[targetRow, targetRow + length - 1][][] = expBrowserListBak[sourceRowStart - targetRow + p][q][r]
					expBrowserSel[targetRow, targetRow + length - 1][]    = expBrowserSelBak[sourceRowStart - targetRow + p][q]
				endif
				lastExpandedRow = i
			endif
			expBrowserSel[i][j] = SetBit(val, LISTBOX_TREEVIEW_EXPANDED)
		endfor
	endfor
End

static Function AB_GetListRowWithSameHash(WAVE/T list, string h)

	variable dim = FindDimLabel(list, COLS, "sweep")
	FindValue/TXOP=4/TEXT=h/RMD=[][dim][1] list
	ASSERT(V_row >= 0, "List row not found")

	return V_row
End

/// @returns 0 if the treeview could be expanded, zero otherwise
static Function AB_ExpandIfCollapsed(variable row, variable subSectionColumn)

	WAVE expBrowserSel = GetExperimentBrowserGUISel()

	ASSERT(subSectionColumn == EXPERIMENT_TREEVIEW_COLUMN || subSectionColumn == DEVICE_TREEVIEW_COLUMN, "Invalid subsection column")
	if(!(expBrowserSel[row][subSectionColumn] & LISTBOX_TREEVIEW))
		// entry is not a tree view
		return 1
	endif

	if(!(expBrowserSel[row][subSectionColumn] & LISTBOX_TREEVIEW_EXPANDED))
		expBrowserSel[row][subSectionColumn] = expBrowserSel[row][subSectionColumn] | LISTBOX_TREEVIEW_EXPANDED
		AB_ExpandListEntry(row, subSectionColumn)
		return 0
	endif
End

/// @brief get indizes from AB window while successive expanding all columns
///
/// @returns valid indizes wave on success
static Function/WAVE AB_GetExpandedIndices()

	variable i, row

	WAVE expBrowserSel = GetExperimentBrowserGUISel()
	// Our mode for the listbox stores the selection bit only in the first column
	WAVE/Z wv = FindIndizes(expBrowserSel, col = 0, var = LISTBOX_SELECT_OR_SHIFT_SELECTION, prop = PROP_MATCHES_VAR_BIT_MASK)
	if(!WaveExists(wv))
		Make/FREE/N=0 wv
		return wv
	endif

	// expand all selected treeviews
	// as indizes might change during the loop run we have to determine the
	// dimension size in the loop condition
	for(i = 0; i < DimSize(wv, ROWS); i += 1) // NOLINT
		row = wv[i]

		// we have to refetch the selected entries
		if(!AB_ExpandIfCollapsed(row, EXPERIMENT_TREEVIEW_COLUMN))
			WAVE wv = FindIndizes(expBrowserSel, col = 0, var = LISTBOX_SELECT_OR_SHIFT_SELECTION, prop = PROP_MATCHES_VAR_BIT_MASK)
			i = 0
		endif

		if(!AB_ExpandIfCollapsed(row, DEVICE_TREEVIEW_COLUMN))
			WAVE wv = FindIndizes(expBrowserSel, col = 0, var = LISTBOX_SELECT_OR_SHIFT_SELECTION, prop = PROP_MATCHES_VAR_BIT_MASK)
			i = 0
		endif
	endfor

	return wv
End

static Function AB_GUIRowIsStimsetsOnly(variable row)

	WAVE/T expBrowserList = GetExperimentBrowserGUIList()

	return !IsEmpty(expBrowserList[row][%file]) && IsEmpty(expBrowserList[row][%device])
End

/// @returns 0 if at least one sweep or stimset could be loaded, 1 otherwise
static Function AB_LoadFromExpandedRange(variable row, variable subSectionColumn, variable loadType, [variable overwrite, DFREF sweepBrowserDFR, WAVE/T dfCollect])

	variable j, endRow, mapIndex, sweep, oneValidLoad, index, err, sweepLoadError
	string device, discLocation, dataFolder, fileName, fileType, errMsg

	WAVE   expBrowserSel  = GetExperimentBrowserGUISel()
	WAVE/T expBrowserList = GetExperimentBrowserGUIList()
	WAVE/T map            = GetAnalysisBrowserMap()

	if(ParamIsDefault(overwrite))
		overwrite = 0
	endif

	ASSERT(subSectionColumn == EXPERIMENT_TREEVIEW_COLUMN || subSectionColumn == DEVICE_TREEVIEW_COLUMN, "Invalid subsection column")
	if(!(expBrowserSel[row][subSectionColumn] & LISTBOX_TREEVIEW))
		// entry is not a tree view
		return 1
	endif

	endRow = AB_GetRowWithNextTreeView(expBrowserSel, row, subSectionColumn)

	for(j = row; j < endRow; j += 1)

		if(AB_GUIRowIsStimsetsOnly(row))
			if(loadType == AB_LOAD_SWEEP)
				return 1
			endif
			device = ""
		else
			if((expBrowserSel[j][EXPERIMENT_TREEVIEW_COLUMN] & LISTBOX_TREEVIEW) || (expBrowserSel[j][DEVICE_TREEVIEW_COLUMN] & LISTBOX_TREEVIEW))
				// ignore rows with tree view icons, we have them already in our list
				continue
			endif

			sweep = str2num(expBrowserList[j][%sweep])

			// sweeps with multiple DA channels occupy multiple rows,
			// ignore them as they all stem from the same sweep
			if(!IsFinite(sweep))
				continue
			endif

			device = GetLastNonEmptyEntry(expBrowserList, "device", j)
		endif
		mapIndex     = str2num(expBrowserList[j][%file][1])
		dataFolder   = map[mapIndex][%DataFolder]
		discLocation = map[mapIndex][%DiscLocation]
		fileType     = map[mapIndex][%FileType]
		fileName     = map[mapIndex][%FileName]

		switch(loadType)
			case AB_LOAD_STIMSET:
				if(AB_LoadStimsetFromFile(discLocation, dataFolder, fileType, device, sweep, overwrite = overwrite) == 1)
					continue
				endif
				oneValidLoad = 1
				break
			case AB_LOAD_TP_STORAGE:
				if(AB_LoadTPStorageFromFile(discLocation, dataFolder, fileType, device, overwrite = overwrite) == 1)
					continue
				endif
				oneValidLoad = 1
				break
			case AB_LOAD_HISTORYANDLOGS:
				if(AB_LoadHistoryAndLogsFromFile(discLocation, dataFolder, fileType, overwrite = overwrite) == 1)
					continue
				endif
				oneValidLoad = 1
				break
			case AB_LOAD_SWEEP:
				err    = 0
				errMsg = ""
				try
					err = AB_LoadSweepFromFile(discLocation, dataFolder, fileType, device, sweep, overwrite = overwrite)
				catch
					errMsg = GetRTErrMessage()
					ClearRTError()
					err = 1
				endtry
				if(err)
					printf "Error loading file: %s\r", discLocation
					if(!IsEmpty(errMsg))
						printf "with error: %s\r", errMsg
					endif
					sweepLoadError = 1
					continue
				endif
				oneValidLoad = 1

				index = GetNumberFromWaveNote(dfCollect, NOTE_INDEX)
				EnsureLargeEnoughWave(dfCollect, indexShouldExist = index)
				dfCollect[index] = dataFolder
				SetNumberInWaveNote(dfCollect, NOTE_INDEX, index + 1)

				SB_AddToSweepBrowser(sweepBrowserDFR, fileName, dataFolder, device, sweep)
				break
			default:
				FATAL_ERROR("Unexpected loadType")
		endswitch
	endfor

	if(oneValidLoad)
		return 0
	endif
	if(sweepLoadError)
		printf "There occurred errors when loading sweep data. See history output for details.\r"
		ControlWindowToFront()
	endif

	return 1
End

/// @brief Return the row with treeview in the column col starting from startRow
static Function AB_GetRowWithNextTreeView(WAVE selWave, variable startRow, variable col)

	variable numRows, i
	Make/FREE/N=(DimSize(selWave, COLS)) status

	numRows = DimSize(selWave, ROWS)
	for(i = startRow + 1; i < numRows; i += 1)
		status[] = ((selWave[i][p] & LISTBOX_TREEVIEW) ? 1 : 0)

		if(Sum(status, 0, col) > 0)
			return i
		endif
	endfor

	return numRows
End

static Function AB_LoadFromFile(variable loadType, [DFREF sweepBrowserDFR])

	variable mapIndex, sweep, numRows, i, row, overwrite, oneValidLoad, index
	string dataFolder, fileName, discLocation, fileType, device

	if(loadType == AB_LOAD_SWEEP)
		ASSERT(!ParamIsDefault(sweepBrowserDFR), "create sweepBrowser DataFolder with SB_OpenSweepBrowser() prior")
		ASSERT(IsGlobalDataFolder(sweepBrowserDFR), "sweepBrowser DataFolder does not exist")
	endif

	WAVE indizes = AB_GetExpandedIndices()
	numRows = DimSize(indizes, ROWS)
	if(numRows == 0)
		return 0
	endif

	WAVE/T expBrowserList = GetExperimentBrowserGUIList()
	WAVE/T map            = GetAnalysisBrowserMap()
	overwrite = GetCheckBoxState("AnalysisBrowser", "checkbox_load_overwrite")
	Make/FREE/T/N=(MINIMUM_WAVE_SIZE) dfCollect
	SetNumberInWaveNote(dfCollect, NOTE_INDEX, 0)

	for(i = 0; i < numRows; i += 1)
		row = indizes[i]

		// handle not expanded EXPERIMENT and DEVICE COLUMNS
		switch(loadType)
			case AB_LOAD_STIMSET: // fallthrough
			case AB_LOAD_TP_STORAGE: // fallthrough
			case AB_LOAD_HISTORYANDLOGS:
				if(!AB_LoadFromExpandedRange(row, EXPERIMENT_TREEVIEW_COLUMN, loadType, overwrite = overwrite))
					oneValidLoad = 1
					continue
				endif
				if(!AB_LoadFromExpandedRange(row, DEVICE_TREEVIEW_COLUMN, loadType, overwrite = overwrite))
					oneValidLoad = 1
					continue
				endif
				break
			case AB_LOAD_SWEEP:
				if(!AB_LoadFromExpandedRange(row, EXPERIMENT_TREEVIEW_COLUMN, loadType, sweepBrowserDFR = sweepBrowserDFR, overwrite = overwrite, dfCollect = dfCollect))
					oneValidLoad = 1
					continue
				endif
				if(!AB_LoadFromExpandedRange(row, DEVICE_TREEVIEW_COLUMN, loadType, sweepBrowserDFR = sweepBrowserDFR, overwrite = overwrite, dfCollect = dfCollect))
					oneValidLoad = 1
					continue
				endif
				break
			default:
				FATAL_ERROR("Invalid loadType")
		endswitch

		sweep = str2num(GetLastNonEmptyEntry(expBrowserList, "sweep", row))
		if(!IsFinite(sweep))
			continue
		endif
		device = GetLastNonEmptyEntry(expBrowserList, "device", row)

		mapIndex     = str2num(expBrowserList[row][%file][1])
		fileName     = map[mapIndex][%FileName]
		dataFolder   = map[mapIndex][%DataFolder]
		discLocation = map[mapIndex][%DiscLocation]
		fileType     = map[mapIndex][%FileType]

		switch(loadType)
			case AB_LOAD_STIMSET:
				if(AB_LoadStimsetFromFile(discLocation, dataFolder, fileType, device, sweep, overwrite = overwrite))
					continue
				endif
				oneValidLoad = 1
				break
			case AB_LOAD_SWEEP:
				if(AB_LoadSweepFromFile(discLocation, dataFolder, fileType, device, sweep, overwrite = overwrite))
					continue
				endif
				oneValidLoad = 1

				SB_AddToSweepBrowser(sweepBrowserDFR, fileName, dataFolder, device, sweep)

				index = GetNumberFromWaveNote(dfCollect, NOTE_INDEX)
				EnsureLargeEnoughWave(dfCollect, indexShouldExist = index)
				dfCollect[index] = dataFolder
				SetNumberInWaveNote(dfCollect, NOTE_INDEX, index + 1)
				break
			case AB_LOAD_TP_STORAGE:
				if(AB_LoadTPStorageFromFile(discLocation, dataFolder, fileType, device, overwrite = overwrite))
					continue
				endif
				oneValidLoad = 1
				break
			case AB_LOAD_HISTORYANDLOGS:
				if(AB_LoadHistoryAndLogsFromFile(discLocation, dataFolder, fileType, overwrite = overwrite) == 1)
					continue
				endif
				oneValidLoad = 1
				break
			default:
				FATAL_ERROR("Invalid loadType")
		endswitch
	endfor

	index = GetNumberFromWaveNote(dfCollect, NOTE_INDEX)
	AB_AllocWorkingDFs(dfCollect, index)

	return oneValidLoad
End

Function AB_FreeWorkingDFs(WAVE/T relativeDFPaths, variable actualSize)

	AB_FreeOrAllocWorkingDF(relativeDFPaths, actualSize, 1)
End

Function AB_AllocWorkingDFs(WAVE/T relativeDFPaths, variable actualSize)

	AB_FreeOrAllocWorkingDF(relativeDFPaths, actualSize, 0)
End

static Function AB_FreeOrAllocWorkingDF(WAVE/T relativeDFPaths, variable actualSize, variable free)

	string dfABPath = GetDataFolder(1, GetAnalysisFolder())

	Redimension/N=(actualSize) relativeDFPaths
	WAVE/T uniqueDF = GetUniqueEntries(relativeDFPaths, dontDuplicate = 1)
	uniqueDF[] = dfABPath + uniqueDF[p]
	if(free)
		for(dfPath : uniqueDF)
			RefCounterDFDecrease($dfPath)
		endfor

		return NaN
	endif

	for(dfPath : uniqueDF)
		RefCounterDFIncrease($dfPath)
	endfor
End

Function AB_LoadStimsetForSweep(string device, variable index, variable sweep)

	string dataFolder, discLocation, fileType

	WAVE/T map = GetAnalysisBrowserMap()

	dataFolder   = map[index][%DataFolder]
	discLocation = map[index][%DiscLocation]
	fileType     = map[index][%FileType]

	return AB_LoadStimsetFromFile(discLocation, dataFolder, fileType, device, sweep, overwrite = 0)
End

// @brief common ASSERT statements for AB_LoadSweepFromFile and AB_LoadStimsetFromFile
static Function AB_LoadFromFileASSERT(string discLocation, string dataFolder, string fileType, string device, variable sweep, variable overwrite)

	ASSERT(!isEmpty(discLocation), "Empty file or Folder name on disc")
	ASSERT(!isEmpty(dataFolder), "Empty dataFolder")
	ASSERT(cmpstr(fileType, "unknown"), "unknown file format")
	if(!IsEmpty(device))
		ASSERT(isFinite(sweep), "Non-finite sweep")
	endif
	ASSERT(overwrite == 0 || overwrite == 1, "overwrite can either be one or zero")
End

/// @returns 0 if the sweeps could be loaded, or already exists, and 1 on error
static Function AB_LoadSweepFromFile(string discLocation, string dataFolder, string fileType, string device, variable sweep, [variable overwrite])

	string sweepFolder, sweeps, msg
	variable h5_fileID, h5_groupID, err

	if(ParamIsDefault(overwrite))
		overwrite = 0
	endif

	ASSERT(!IsEmpty(device), "Empty device.")
	AB_LoadFromFileASSERT(discLocation, dataFolder, fileType, device, sweep, overwrite)

	sweepFolder = GetAnalysisSweepDataPathAS(dataFolder, device, sweep)

	// sweep already loaded
	if(DataFolderExists(sweepFolder))
		if(!overwrite)
			return 0
		endif

		KillOrMoveToTrash(dfr = $sweepFolder)
		KillOrMoveToTrash(wv = GetAnalysisConfigWave(dataFolder, device, sweep))
	endif

	DFREF sweepDFR = createDFWithAllParents(sweepFolder)

	strswitch(fileType)
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			err = AB_LoadSweepFromIgor(discLocation, dataFolder, sweepDFR, device, sweep)
			if(err)
				return 1
			endif
			break
		case ANALYSISBROWSER_FILE_TYPE_NWBv1: // fallthrough
		case ANALYSISBROWSER_FILE_TYPE_NWBv2:
			if(AB_LoadSweepFromNWB(discLocation, sweepDFR, device, sweep))
				return 1
			endif
			break
		default:
			FATAL_ERROR("fileType not handled")
	endswitch

	sprintf msg, "Loaded sweep %d of device %s and %s\r", sweep, device, discLocation
	DEBUGPRINT(msg)

	return 0
End

static Function AB_LoadStimsetFromFile(string discLocation, string dataFolder, string fileType, string device, variable sweep, [variable overwrite])

	string loadedStimsets, msg
	variable h5_fileID, h5_groupID
	string stimsets = ""

	if(ParamIsDefault(overwrite))
		overwrite = 0
	endif
	AB_LoadFromFileASSERT(discLocation, dataFolder, fileType, device, sweep, overwrite)

	strswitch(fileType)
		case ANALYSISBROWSER_FILE_TYPE_IGOR:
			stimsets       = AB_GetStimsetList(fileType, discLocation, dataFolder, device, sweep)
			loadedStimsets = AB_LoadStimsets(discLocation, stimsets, overwrite)
			loadedStimsets = AB_LoadCustomWaves(discLocation, loadedStimsets, overwrite)
			stimsets       = GetListDifference(stimsets, loadedStimsets)
			if(AB_LoadStimsetsRAW(discLocation, stimsets, overwrite))
				return 1
			endif
			break
		case ANALYSISBROWSER_FILE_TYPE_NWBv1: // fallthrough
		case ANALYSISBROWSER_FILE_TYPE_NWBv2:
			stimsets  = AB_GetStimsetList(fileType, discLocation, dataFolder, device, sweep)
			h5_fileID = H5_OpenFile(discLocation)
			if(!StimsetPathExists(h5_fileID))
				H5_CloseFile(h5_fileID)
				return 1
			endif
			h5_groupID = OpenStimset(h5_fileID)
			if(NWB_LoadStimsets(h5_groupID, stimsets, overwrite))
				H5_CloseFile(h5_fileID)
				return 1
			endif
			if(NWB_LoadCustomWaves(h5_groupID, stimsets, overwrite))
				H5_CloseFile(h5_fileID)
				return 1
			endif
			H5_CloseFile(h5_fileID)
			break
		default:
			FATAL_ERROR("fileType not handled")
	endswitch

	sprintf msg, "Loaded stimsets %s of device %s and %s\r", stimsets, device, discLocation
	DEBUGPRINT(msg)

	WB_UpdateChangedStimsets()

	return 0
End

static Function AB_LoadSweepFromNWB(string discLocation, DFREF sweepDFR, string device, variable sweep)

	string channelList
	variable h5_fileID, h5_groupID, numSweeps, version

	WAVE/T nwb = AB_GetMap(discLocation)

	// find sweep in map
	WAVE/T devices = GetAnalysisDeviceWave(nwb[%DataFolder])
	FindValue/S=0/TEXT=(device) devices
	ASSERT(V_Value >= 0, "device not found")
	WAVE/I sweeps = GetAnalysisChannelSweepWave(nwb[%DataFolder], device)
	FindValue/S=0/I=(sweep) sweeps
	ASSERT(V_Value >= 0, "sweep not found")

	// load sweep info wave
	WAVE/WAVE channelStorage = GetAnalysisChannelStorage(nwb[%DataFolder], device)
	numSweeps = GetNumberFromWaveNote(sweeps, NOTE_INDEX)
	if(numSweeps != GetNumberFromWaveNote(channelStorage, NOTE_INDEX))
		EnsureLargeEnoughWave(channelStorage, indexShouldExist = numSweeps, dimension = ROWS)
	endif
	WAVE/Z/I configSweep = channelStorage[V_Value][%configSweep]
	if(!WaveExists(configSweep))
		WAVE/I configSweep = GetAnalysisConfigWave(nwb[%DataFolder], device, sweep)
		channelStorage[V_Value][%configSweep] = configSweep
	endif

	// open NWB file
	h5_fileID = H5_OpenFile(discLocation)
	version   = GetNWBMajorVersion(ReadNWBVersion(h5_fileID))

	// load acquisition (AD channels)
	WAVE/T acquisition = GetAnalysisChannelAcqWave(nwb[%DataFolder], device)
	channelList = acquisition[V_Value]
	h5_groupID  = OpenAcquisition(h5_fileID, version)
	if(AB_LoadSweepFromNWBgeneric(h5_groupID, version, channelList, sweepDFR, configSweep))
		return 1
	endif

	// load stimulus (DA channels)
	WAVE/T stimulus = GetAnalysisChannelStimWave(nwb[%DataFolder], device)
	channelList = stimulus[V_Value]
	h5_groupID  = OpenStimulus(h5_fileID)
	if(AB_LoadSweepFromNWBgeneric(h5_groupID, version, channelList, sweepDFR, configSweep))
		return 1
	endif

	// close NWB file
	H5_CloseFile(h5_fileID)

	return 0
End

static Function AB_LoadSweepFromNWBgeneric(variable h5_groupID, variable nwbVersion, string channelList, DFREF sweepDFR, WAVE/I configSweep)

	string channel, channelName
	variable numChannels, numEntries, i
	STRUCT ReadChannelParams p
	variable waveNoteLoaded, fakeConfigWave

	numChannels = ItemsInList(channelList)

	for(i = 0; i < numChannels; i += 1)
		channel = StringFromList(i, channelList)
		AnalyseChannelName(channel, p)

		switch(p.channelType)
			case XOP_CHANNEL_TYPE_DAC:
				channelName = "DA"
				WAVE loaded = LoadStimulus(h5_groupID, channel)
				channelName   += "_" + num2str(p.channelNumber)
				fakeConfigWave = 1
				break
			case XOP_CHANNEL_TYPE_ADC:
				channelName = "AD"
				WAVE loaded = LoadTimeseries(h5_groupID, channel, nwbVersion)
				channelName   += "_" + num2str(p.channelNumber)
				fakeConfigWave = 1
				break
			case XOP_CHANNEL_TYPE_TTL:
				channelName = "TTL"
				WAVE loaded = LoadStimulus(h5_groupID, channel)
				channelName += "_" + num2str(p.channelNumber)

				if(IsFinite(p.ttlBit))
					// always fake TTL base wave (bitwise sum of all TTL channels)
					WAVE/Z/I base = sweepDFR:$channelName
					if(!WaveExists(base))
						Duplicate loaded, sweepDFR:$channelName/WAVE=base
						base           = 0
						fakeConfigWave = 1
						SetNumberInWaveNote(base, "fake", 1)
					endif

					if(WaveMax(loaded) < 2)
						base += 2^(p.ttlBit) * loaded
					else
						base += loaded
					endif

					channelName += "_" + num2str(NWB_ConvertToStandardTTLBit(p.ttlBit))
				else
					// for non-ITC hardware we don't have multiple bits in one channel
					// so we don't need to fake a base wave
					fakeConfigWave = 1
				endif

				break
			default:
				FATAL_ERROR("unknown channel type " + num2str(p.channelType))
		endswitch
		ASSERT(WaveExists(loaded), "No Wave loaded")

		if(waveNoteLoaded == 0)
			SVAR/Z test = sweepDFR:note
			if(!SVAR_EXISTS(test))
				string/G sweepDFR:note = note(loaded)
			endif
			waveNoteLoaded = 1
		endif

		// fake Config_Sweeps Wave
		if(fakeConfigWave)
			numEntries = DimSize(configSweep, ROWS)
			Redimension/N=((numEntries + 1), -1) configSweep

			configSweep[numEntries][%type]   = p.channelType
			configSweep[numEntries][%number] = p.channelNumber
			configSweep[numEntries][%timeMS] = trunc(DimDelta(loaded, ROWS) * ONE_TO_MILLI)
			configSweep[numEntries][3]       = -1 // -1 for faked Config_Sweeps Waves

			// set unit in config_wave from WaveNote of loaded dataset
			Note/K configSweep, AddListItem(WaveUnits(loaded, COLS), Note(configSweep), ";", Inf)

			fakeConfigWave = 0
		endif

		WAVE/Z/SDFR=sweepDFR targetName = $channelName
		// nwb files created prior to 901428b might have duplicated datasets
		if(WaveExists(targetName) && WaveCRC(0, targetName) != WaveCRC(0, loaded))
			KillOrMoveToTrash(dfr = sweepDFR)
			FATAL_ERROR("wave with same name, but different content, already exists: " + channelName)
		endif
		Duplicate/O loaded, sweepDFR:$channelName/WAVE=targetRef
		CreateBackupWave(targetRef)
		WaveClear loaded
	endfor

	AB_SortConfigSweeps(configSweep)

	if(!waveNoteLoaded)
		return 1 // nothing was loaded
	endif

	return 0 // no error
End

/// @brief Sorts the faked Config Sweeps Wave to get correct display order in Sweep Browser
///
/// function is oriented at MDSort()
static Function AB_SortConfigSweeps(WAVE/I config)

	string   wavenote = Note(config)
	variable numRows  = DimSize(config, ROWS)

	ASSERT(IsValidConfigWave(config, version = 0), "Invalid config wave")
	ASSERT(FindDimLabel(config, COLS, "type") != -2, "Config Wave has no column labels")
	ASSERT(FindDimLabel(config, COLS, "number") != -2, "Config Wave has no column labels")

	WAVE/T units = AFH_GetChannelUnits(config)
	Make/I/FREE/N=(numRows) keyPrimary, keySecondary
	Make/FREE/N=(numRows)/I/U valindex = p

	//sort order: XOP_CHANNEL_TYPE_DAC = 1, XOP_CHANNEL_TYPE_ADC = 0, XOP_CHANNEL_TYPE_TTL = 3
	MultiThread keyPrimary[] = (config[p][%type] == XOP_CHANNEL_TYPE_ADC) ? 2 : config[p][%type]
	MultiThread keySecondary[] = config[p][%number]
	Sort/A {keyPrimary, keySecondary}, valindex

	Duplicate/FREE/I config, config_temp
	Duplicate/FREE/T units, units_temp
	MultiThread config[][] = config_temp[valindex[p]][q]
	units[] = units_temp[valindex[p]]

	Note/K config, TextWaveToList(units, ";")
End

/// @brief Load specified device/sweep combination from Igor experiment file to sweepDFR
///
/// @returns name of loaded sweep
static Function AB_LoadSweepFromIgor(string discLocation, string expFolder, DFREF sweepDFR, string device, variable sweep)

	variable i, numWavesLoaded, numComponentsLoaded, numChannels
	string sweepWaveList = ""
	string sweepWaveName, sweepWaveNameBak, dataPath, componentsDataPath, sweepComponent
	string channelName, channelWaveList

	// we load the backup wave also
	// in case it exists, it holds the original unmodified data
	sweepWaveName    = "sweep_" + num2str(sweep)
	sweepWaveNameBak = sweepWaveName + WAVE_BACKUP_SUFFIX
	sweepWaveList    = AddListItem(sweepWaveList, sweepWaveName, ";", Inf)
	sweepWaveList    = AddListItem(sweepWaveList, sweepWaveNameBak, ";", Inf)

	dataPath = GetDeviceDataPathAsString(device)
	dataPath = AB_TranslatePath(dataPath, expFolder)
	DFREF newDFR = NewFreeDataFolder()
	numWavesLoaded = AB_LoadDataWrapper(newDFR, discLocation, dataPath, sweepWaveList)

	if(numWavesLoaded <= 0)
		printf "Could not load sweep %d of device %s and %s\r", sweep, device, discLocation
		KillOrMoveToTrash(dfr = newDFR)
		KillOrMoveToTrash(dfr = sweepDFR)
		return 1
	endif

	WAVE sweepWave = newDFR:$sweepWaveName
	if(IsTextWave(sweepWave) && DimSize(sweepWave, ROWS) > 0)
		WAVE/Z/T sweepT = newDFR:$sweepWaveNameBak
		if(!WaveExists(sweepT))
			printf "Could not find original sweep wave in pxp (only working copy). Sweep %d of device %s and %s\r", sweep, device, discLocation
			return 1
		endif

		numChannels = DimSize(sweepT, ROWS)
		for(i = 0; i < numChannels; i += 1)
			[componentsDataPath, channelName] = SplitTextSweepElement(sweepT[i])
			sweepT[i]                         = channelName
		endfor
		channelWaveList = TextWaveToList(sweepT, ";")
		DFREF sweepComponentsDFR = NewFreeDataFolder()
		numComponentsLoaded = AB_LoadDataWrapper(sweepComponentsDFR, discLocation, dataPath + ":" + componentsDataPath, channelWaveList, recursive = 0)
		if(numComponentsLoaded != DimSize(sweepT, ROWS))
			printf "Error loading all sweep components. Sweep %d of device %s and %s\r", sweep, device, discLocation
			return 1
		endif

		for(sweepComponent : sweepT)
			WAVE wv = sweepComponentsDFR:$sweepComponent
			MoveWave wv, sweepDFR
		endfor
		RestoreFromBackupWavesForAll(sweepDFR)
	else
		// old sweep format
		if(numWavesLoaded == 2)
			ReplaceWaveWithBackup(sweepWave)
		endif

		MoveWave sweepWave, sweepDFR
		if(AB_SplitSweepIntoComponents(expFolder, device, sweep, sweepWave))
			return 1
		endif
	endif

	return 0
End

/// @brief a failsave alternative for AB_LoadStimsets() to load RAW stimsets
///
/// If a stimset could not get loaded using AB_LoadStimsets()
/// this function is used in addition to try to load the
/// stimset without its corresponding Parameter Waves.
/// overwrite is not supported
///
/// @param expFilePath    Path on disc to igor experiment
/// @param stimsets       ";" separated list of all stimsets
/// @param overwrite      overwrite flag
///
/// @return 1 on error and 0 on success
static Function AB_LoadStimsetsRAW(string expFilePath, string stimsets, variable overwrite)

	string stimset
	variable numStimsets, i
	variable error = 0

	numStimsets = ItemsInList(stimsets)
	for(i = 0; i < numStimsets; i += 1)
		stimset = StringFromList(i, stimsets)
		if(AB_LoadStimsetRAW(expFilePath, stimset, overwrite))
			printf "experiment: \t%s \tstimset: \t%s \tload failed for complete stimset\r", expFilePath, stimset
			error = 1
			continue
		endif
		printf "experiment: \t%s \tstimset: \t%s \tloaded complete stimset\r", expFilePath, stimset
	endfor

	return error
End

/// @brief Load specified stimsets from Igor experiment file
///
/// recurses into all dependent stimsets as soon as they have been loaded.
/// the list of stimsets is extended "on the left side": new items are added left.
/// use numEnd to indicate unto which item the list was already processed.
/// see StimsetRecursion() for a similar structure
///
/// @param expFilePath Path on disc to igor experiment
/// @param stimsets           ";" separated list of all stimsets of the current sweep.
/// @param processedStimsets  [optional] input a list of already processed stimsets
/// @param overwrite          overwrite flag
///
/// @return 1 on error and 0 on success
static Function/S AB_LoadStimsets(string expFilePath, string stimsets, variable overwrite, [string processedStimsets])

	string stimset, totalStimsets, newStimsets, oldStimsets
	variable numBefore, numMoved, numAfter, numNewStimsets, i
	string loadedStimsets = ""

	if(ParamIsDefault(processedStimsets))
		processedStimsets = ""
	endif

	totalStimsets = stimsets + processedStimsets
	numBefore     = ItemsInList(totalStimsets)

	// load first order stimsets
	numNewStimsets = ItemsInList(stimsets)
	for(i = 0; i < numNewStimsets; i += 1)
		stimset = StringFromList(i, stimsets)
		if(AB_LoadStimset(expFilePath, stimset, overwrite))
			if(ItemsInList(processedStimsets) == 0)
				// parent corrupt
				// load other parents, no children needed.
				continue
			endif

			// if a (dependent) stimset is missing
			// the corresponding parent can not be created with Parameter Waves
			return loadedStimsets
		endif
		loadedStimsets = AddListItem(stimset, loadedStimsets)
		numMoved      += WB_StimsetFamilyNames(totalStimsets, parent = stimset)
	endfor
	numAfter = ItemsInList(totalStimsets)

	// load next order stimsets
	numNewStimsets = numAfter - numBefore + numMoved
	if(numNewStimsets > 0)
		newStimsets = ListFromList(totalStimsets, 0, numNewStimsets - 1)
		oldStimsets = ListFromList(totalStimsets, numNewStimsets, Inf)
		return loadedStimsets + AB_LoadStimsets(expFilePath, newStimsets, overwrite, processedStimsets = oldStimsets)
	endif

	return loadedStimsets
End

/// @brief Load specified stimset from Igor experiment file
///
/// @return 1 on error and 0 on success
static Function AB_LoadStimset(string expFilePath, string stimset, variable overwrite)

	if(overwrite)
		WB_KillParameterWaves(stimset)
		WB_KillStimset(stimset)
	endif

	if(WB_ParameterWavesExist(stimset))
		return 0
	endif
	if(WB_StimsetExists(stimset))
		return 0
	endif

	if(overwrite)
		WB_KillParameterWaves(stimset)
	endif
	if(!AB_LoadStimsetTemplateWaves(expFilePath, stimset))
		return 0
	endif
	if(!AB_LoadStimsetRAW(expFilePath, stimset, overwrite))
		return 0
	endif

	printf "experiment: \t%s \tstimset: \t%s \tfailed to recreate stimset\r", expFilePath, stimset
	return 1
End

static Function AB_LoadStimsetRAW(string expFilePath, string stimset, variable overwrite)

	string dataPath, data
	variable numWavesLoaded, channelType

	WB_KillParameterWaves(stimset)
	if(overwrite)
		WB_KillStimset(stimset)
	endif

	channelType = WB_GetStimSetType(stimset)

	if(channeltype == CHANNEL_TYPE_UNKNOWN)
		return 1
	endif

	DFREF newDFR = UniqueDataFolder(GetAnalysisFolder(), "temp")
	DFREF setDFR = GetSetFolder(channelType)

	WAVE/Z/SDFR=setDFR wv = $stimset
	if(WaveExists(wv))
		return 0
	endif

	dataPath = GetDataFolder(1, setDFR)
	data     = AddListItem(stimset, "")

	numWavesLoaded = AB_LoadDataWrapper(newDFR, expFilePath, dataPath, data, recursive = 0)

	if(numWavesLoaded != 1)
		KillOrMoveToTrash(dfr = newDFR)
		return 1
	endif

	MoveWave newDFR:$stimset, setDFR
	KillOrMoveToTrash(dfr = newDFR)

	return 0
End

/// @brief Load template waves for a specific stimset from Igor experiment file
///
/// @return 1 on error and 0 on success
static Function AB_LoadStimsetTemplateWaves(string expFilePath, string stimset)

	variable channelType, numWavesLoaded, numStimsets, i
	string dataPath
	string parameterWaves = ""

	// load parameter waves
	DFREF newDFR = UniqueDataFolder(GetAnalysisFolder(), "temp")

	parameterWaves = AddListItem(WB_GetParameterWaveName(stimset, STIMSET_PARAM_WP), parameterWaves)
	parameterWaves = AddListItem(WB_GetParameterWaveName(stimset, STIMSET_PARAM_WPT), parameterWaves)
	parameterWaves = AddListItem(WB_GetParameterWaveName(stimset, STIMSET_PARAM_SEGWVTYPE), parameterWaves)

	channelType = WB_GetStimSetType(stimset)

	if(channeltype == CHANNEL_TYPE_UNKNOWN)
		return 1
	endif

	dataPath = GetSetParamFolderAsString(channelType)

	numWavesLoaded = AB_LoadDataWrapper(newDFR, expFilePath, dataPath, parameterWaves, recursive = 0)

	if(numWavesLoaded != 3)
		KillOrMoveToTrash(dfr = newDFR)
		return 1
	endif

	// move loaded waves to stimset parameter dataFolder
	WAVE   WP        = newDFR:$(WB_GetParameterWaveName(stimset, STIMSET_PARAM_WP))
	WAVE/T WPT       = newDFR:$(WB_GetParameterWaveName(stimset, STIMSET_PARAM_WPT))
	WAVE   SegWvType = newDFR:$(WB_GetParameterWaveName(stimset, STIMSET_PARAM_SEGWVTYPE))

	DFREF paramDFR = GetSetParamFolder(channelType)

	MoveWave WP, paramDFR
	MoveWave WPT, paramDFR
	MoveWave SegWvType, paramDFR

	KillOrMoveToTrash(dfr = newDFR)

	if(WB_ParameterWavesExist(stimset))
		return 0
	endif

	return 1
End

/// @brief Load custom waves for specified stimset from Igor experiment file
///
/// @return 1 on error and 0 on success
static Function/S AB_LoadCustomWaves(string expFilePath, string stimsets, variable overwrite)

	string dependentStimsets, stimset, custom_waves, path, customWaveName
	variable numWaves, numStimsets, i, j, valid
	string loadedStimsets = ""

	WAVE/T cw = WB_CustomWavesPathFromStimSet(stimsets)

	numWaves = DimSize(cw, ROWS)
	Make/FREE/I/N=(numWaves) loaded = 1
	for(i = 0; i < numWaves; i += 1)
		customWaveName = cw[i]

		// handle legacy custom wave format
		if(!isEmpty(customWaveName) && strsearch(customWaveName, ":", 0) == -1)
			path = GetSetFolderAsString(CHANNEL_TYPE_DAC) + ":" + customWaveName
			if(!AB_LoadWave(expFilePath, path, overwrite))
				continue
			endif
			path = GetSetFolderAsString(CHANNEL_TYPE_TTL) + ":" + customWaveName
			if(!AB_LoadWave(expFilePath, path, overwrite))
				continue
			endif
		endif

		// load standard wave format
		if(!AB_LoadWave(expFilePath, customWaveName, overwrite))
			continue
		endif

		// indicate error
		loaded[i] = 0
	endfor

	if(numWaves == 0 || sum(loaded) == numWaves)
		return stimsets
	endif

	// search for uncorrupt stimsets
	numStimsets = ItemsInList(stimsets)
	for(i = 0; i < numStimsets; i += 1)
		valid   = 1
		stimset = StringFromList(i, stimsets)
		WAVE/T single_cw = WB_CustomWavesPathFromStimSet(stimset)
		numWaves = DimSize(single_cw, 0)
		for(j = 0; j < numWaves; j += 1)
			FindValue/TEXT=(single_cw[j]) cw
			if(V_Value == -1)
				continue
			endif
			if(loaded[V_Value] == 0)
				valid = 0
				break
			endif
		endfor
		if(valid)
			loadedStimsets = AddListItem(stimset, loadedStimsets)
		endif
	endfor

	return loadedStimsets
End

/// @brief Load specified wave from Igor Experiment file.
///
/// @return 1 on error and 0 on success
static Function AB_LoadWave(string expFilePath, string fullPath, variable overwrite)

	variable numWavesLoaded
	string   dataFolder
	string loadList = ""

	WAVE/Z wv = $fullPath
	if(overwrite)
		KillOrMoveToTrash(wv = wv)
	endif
	if(WaveExists(wv))
		return 0
	endif

	DFREF newDFR = UniqueDataFolder(GetAnalysisFolder(), "temp")

	dataFolder = GetFolder(fullPath)
	loadList   = AddListItem(RemovePrefix(fullPath, start = dataFolder), loadList)
	if(isEmpty(dataFolder))
		dataFolder = "root:"
	endif
	numWavesLoaded = AB_LoadDataWrapper(newDFR, expFilePath, dataFolder, loadList, recursive = 0)

	if(numWavesLoaded == 0)
		KillOrMoveToTrash(dfr = newDFR)
		KillOrMoveToTrash(dfr = sweepDFR)
		return 1
	endif

	WAVE/SDFR=newDFR wv = $(GetIndexedObjNameDFR(newDFR, COUNTOBJECTS_WAVES, 0))
	createDFWithAllParents(dataFolder)
	MoveWave wv, $fullPath

	KillOrMoveToTrash(dfr = newDFR)

	return 0
End

static Function AB_SplitSweepIntoComponents(string expFolder, string device, variable sweep, WAVE sweepWave)

	DFREF sweepFolder = GetAnalysisSweepDataPath(expFolder, device, sweep)
	WAVE  configSweep = GetAnalysisConfigWave(expFolder, device, sweep)

	if(!IsValidSweepAndConfig(sweepWave, configSweep, configVersion = 0))
		printf "The sweep %d of device %s in experiment %s does not match its configuration data. Therefore we ignore it.\r", sweep, device, expFolder
		return 1
	endif

	DFREF dfr = GetAnalysisLabNBFolder(expFolder, device)
	WAVE/SDFR=dfr $LBN_NUMERICAL_VALUES_NAME

	SplitAndUpgradeSweep(numericalValues, sweep, sweepWave, configSweep, TTL_RESCALE_ON, 1, targetDFR = sweepFolder)
	KillOrMoveToTrash(wv = sweepWave)

	return 0
End

static Function AB_RemoveExperimentEntry(string win, string entry)

	variable i, size, mapIndex, cnt

	PGC_SetAndActivateControl(win, "button_expand_all", val = 1)

	WAVE/T list = GetExperimentBrowserGUIList()
	WAVE   sel  = GetExperimentBrowserGUISel()

	size = GetNumberFromWaveNote(list, NOTE_INDEX)
	for(i = size - 1; i >= 0; i -= 1)
		if(!CmpStr(list[i][%type][1], entry, 1))
			mapIndex = str2num(list[i][%file][1])
			AB_RemoveMapEntry(mapIndex)
			DeleteWavePoint(list, ROWS, index = i)
			DeleteWavePoint(sel, ROWS, index = i)
			cnt += 1
		endif
	endfor
	SetNumberInWaveNote(list, NOTE_INDEX, size - cnt)

	AB_ResetListBoxWaves()
End

/// @brief returns currently open NWB files for data export. If no file is open returns a zero sized text wave.
static Function/WAVE AB_GetCurrentlyOpenNWBFiles()

	WAVE/T devicesWithContent = ListToTextWave(GetAllDevicesWithContent(contentType = CONTENT_TYPE_ALL), ";")
	Duplicate/FREE/T devicesWithContent, activeFiles
	activeFiles[] = ROStr(GetNWBFilePathExport(devicesWithContent[p]))
	RemoveTextWaveEntry1D(activeFiles, "", all = 1)

	return activeFiles
End

static Function AB_GetLoadSettings(string win)

	variable loadResults, loadComments

	loadResults  = GetCheckBoxState(win, "check_load_results")
	loadComments = GetCheckBoxState(win, "check_load_comment")

	return (loadResults * AB_LOADOPT_RESULTS) | (loadComments * AB_LOADOPT_COMMENTS)
End

static Function AB_AddExperimentEntries(string win, WAVE/T entries)

	string entry, symbPath, fName, panel
	string pxpList, uxpList, nwbList, title
	variable sTime, loadOpts, i, size

	WAVE/T activeFiles = AB_GetCurrentlyOpenNWBFiles()

	panel = AB_GetPanelName()
	DoUpdate/W=$panel

	PGC_SetAndActivateControl(win, "button_expand_all", val = 1)
	loadOpts = AB_GetLoadSettings(win)

	sTime = stopMSTimer(-2) * MICRO_TO_ONE + 1
	for(entry : entries)

		if(FolderExists(entry))
			sprintf title, "%s, Looking for files in %s", panel, entry
			DoWindow/T $panel, title
			symbPath = GetUniqueSymbolicPath()
			NewPath/O/Q/Z $symbPath, entry
			if(GetCheckBoxState(win, "check_load_pxp"))
				WAVE/Z/T pxps = GetAllFilesRecursivelyFromPath(symbPath, regex = "(?i)\.(pxp|uxp)$")
			endif
			if(GetCheckBoxState(win, "check_load_nwb"))
				WAVE/Z/T nwbs = GetAllFilesRecursivelyFromPath(symbPath, regex = "(?i)\.nwb$")
			endif
			KillPath/Z $symbPath

			if(WaveExists(pxps) && WaveExists(nwbs))
				Concatenate/NP=(ROWS)/FREE/T {nwbs, pxps}, fileList
			elseif(WaveExists(pxps))
				WAVE/T fileList = pxps
			elseif(WaveExists(nwbs))
				WAVE/T fileList = nwbs
			else
				break
			endif

			Sort fileList, fileList
		elseif(FileExists(entry))
			Make/FREE/T fileList = {entry}
		else
			printf "AnalysisBrowser: Can not find location %s. Skipped it.\r", entry
			continue
		endif
		size = DimSize(filelist, ROWS)
		for(i = 0; i < size; i += 1)
			fName = fileList[i]
			if(!IsNaN(GetRowIndex(activeFiles, str = fName)))
				printf "Ignore %s for adding into the analysis browser\ras we currently export data into it!\r", fName
				ControlWindowToFront()
				continue
			endif
			if(sTime < (stopMSTimer(-2) * MICRO_TO_ONE))
				sprintf title, "%s, Reading %d / %d -> %s", panel, i, size, GetFile(fName)
				DoWindow/T $panel, title
				sTime = stopMSTimer(-2) * MICRO_TO_ONE + 1
			endif
			AB_AddFile(win, fName, entry, loadOpts)
		endfor
	endfor
	DoWindow/T $panel, panel

	AB_ResetListBoxWaves()
End

Function/S AB_GetPanelName()

	return ANALYSIS_BROWSER_NAME
End

static Function AB_SetUserData(string key, string value)

	string panel = AB_GetPanelName()

	ASSERT(WindowExists(panel), "AnalysisBrowser is not open.")

	SetWindow $panel, userData($key)=value
End

static Function/S AB_GetUserData(string key)

	string panel = AB_GetPanelName()

	ASSERT(WindowExists(panel), "AnalysisBrowser is not open.")

	return GetUserData(panel, "", key)
End

Function/S AB_OpenAnalysisBrowser([variable restoreSettings])

	variable oldFolderListSize, i
	string workingDF
	string panel = AB_GetPanelName()

	restoreSettings = ParamisDefault(restoreSettings) ? 1 : !!restoreSettings

	if(WindowExists(panel))
		if(HasPanelLatestVersion(panel, ANALYSISBROWSER_PANEL_VERSION))
			DoWindow/F $panel
			return panel
		endif

		KillWindow/Z $panel
	endif

	AB_InitializeAnalysisBrowserWaves()
	AB_RemoveEmptyWorkingDF()

	WAVE/T folderList      = GetAnalysisBrowserGUIFolderList()
	WAVE   folderSelection = GetAnalysisBrowserGUIFolderSelection()
	WAVE   folderColors    = GetAnalysisBrowserGUIFolderColors()
	if(restoreSettings)
		NVAR   JSONid        = $GetSettingsJSONid()
		WAVE/T oldFolderList = JSON_GetTextWave(jsonID, SETTINGS_AB_FOLDER)
		oldFolderListSize = DimSize(oldFolderList, ROWS)
		Redimension/N=(oldFolderListSize, -1, -1) folderList, folderSelection
		folderList[] = oldFolderList[p]
		FastOp folderSelection = 0
	endif

	Execute "AnalysisBrowser()"
	GetMiesVersion()

	AddVersionToPanel(panel, ANALYSISBROWSER_PANEL_VERSION)

	DFREF dfrAB      = GetAnalysisFolder()
	DFREF workingDFR = UniqueDataFolder(dfrAB, AB_WORKFOLDER_NAME)
	workingDF = RemovePrefix(GetDataFolder(1, workingDFR), start = GetDataFolder(1, dfrAB))
	AB_SetUserData(AB_UDATA_WORKINGDF, RemoveEnding(workingDF, ":"))

	ListBox listbox_AB_Folders, win=$panel, listWave=folderList, selWave=folderSelection, colorWave=folderColors

	WAVE/T list = GetExperimentBrowserGUIList()
	WAVE   sel  = GetExperimentBrowserGUISel()
	ListBox list_experiment_contents, win=$panel, listWave=list, selWave=sel

	PS_InitCoordinates(JSONid, panel, "analysisbrowser")
	SetWindow $panel, hook(cleanup)=AB_WindowHook

	if(restoreSettings)
		DoUpdate/W=$panel
		PGC_SetAndActivateControl(panel, "button_AB_refresh")
	endif

	return panel
End

static Function AB_CheckPanelVersion(string panel)

	if(!HasPanelLatestVersion(panel, ANALYSISBROWSER_PANEL_VERSION))
		DoAbortNow("The Analysisbrowser is too old to be usable. Please close it and open a new one.")
	endif
End

Function AB_BrowserStartupSettings()

	string panel

	panel = AB_GetPanelName()

	HideTools/W=$panel/A
	SetWindow $panel, userData(panelVersion)=""
	SetWindow $panel, userData(datafolder)=""

	SetCheckBoxState(panel, "checkbox_load_overwrite", CHECKBOX_UNSELECTED)

	StoreCurrentPanelsResizeInfo(panel)

	SearchForInvalidControlProcs(panel)
	print "Do not forget to increase ANALYSISBROWSER_PANEL_VERSION."

	ListBox list_experiment_contents, win=$panel, listWave=$"", selWave=$"", colorWave=$""
	ListBox listbox_AB_Folders, win=$panel, listWave=$"", selWave=$"", colorWave=$""
	SetCheckBoxState(panel, "check_load_nwb", CHECKBOX_SELECTED)
	SetCheckBoxState(panel, "check_load_pxp", CHECKBOX_UNSELECTED)
	SetCheckBoxState(panel, "check_load_results", CHECKBOX_UNSELECTED)
	SetCheckBoxState(panel, "check_load_comment", CHECKBOX_UNSELECTED)

	Execute/P/Z "DoWindow/R " + panel
	Execute/P/Q/Z "COMPILEPROCEDURES "
	CleanupOperationQueueResult()
End

/// @brief Button "Expand all"
Function AB_ButtonProc_ExpandAll(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventcode)
		case 2:
			AB_CheckPanelVersion(ba.win)
			AB_ExpandListColumn(EXPERIMENT_TREEVIEW_COLUMN)
			AB_ExpandListColumn(DEVICE_TREEVIEW_COLUMN)
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Button "Collapse all"
Function AB_ButtonProc_CollapseAll(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2:
			AB_CheckPanelVersion(ba.win)
			AB_CollapseAll()
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Button "Load Sweeps"
Function AB_ButtonProc_LoadSweeps(STRUCT WMButtonAction &ba) : ButtonControl

	variable oneValidSweep
	string panel, sbTitle, sbWin

	switch(ba.eventcode)
		case 2:
			AB_CheckPanelVersion(ba.win)

			sbTitle = GetPopupMenuString(ANALYSIS_BROWSER_NAME, "popup_SweepBrowserSelect")
			if(!CmpStr(sbTitle, "New"))
				DFREF dfr = SB_OpenSweepBrowser()
			else
				sbWin = AB_GetSweepBrowserWindowFromTitle(sbTitle)
				DFREF dfr = SB_GetSweepBrowserFolder(sbWin)
			endif
			oneValidSweep = AB_LoadFromFile(AB_LOAD_SWEEP, sweepBrowserDFR = dfr)
			SVAR/SDFR=dfr graph
			if(oneValidSweep)
				AD_Update(graph)
				panel = BSP_GetSweepControlsPanel(graph)
				PGC_SetAndActivateControl(panel, "button_SweepControl_PrevSweep")
				LBV_SelectExperimentAndDevice(graph)
			else
				KillWindow $graph
			endif
			AB_CollapseAll()
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Button "Load Both"
Function AB_ButtonProc_LoadBoth(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventcode)
		case 2:
			PGC_SetAndActivateControl(ba.win, "button_load_stimsets")
			PGC_SetAndActivateControl(ba.win, "button_load_sweeps")
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Button "Load Stimsets"
Function AB_ButtonProc_LoadStimsets(STRUCT WMButtonAction &ba) : ButtonControl

	variable oneValidStimset

	switch(ba.eventcode)
		case 2:
			AB_CheckPanelVersion(ba.win)

			oneValidStimset = AB_LoadFromFile(AB_LOAD_STIMSET)
			if(oneValidStimset)
				WBP_CreateWaveBuilderPanel()
			endif
			AB_CollapseAll()
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Button "Refresh"
Function AB_ButtonProc_Refresh(STRUCT WMButtonAction &ba) : ButtonControl

	variable size, index, refreshIndex
	string entry

	switch(ba.eventCode)
		case 2: // mouse up
			AB_CheckPanelVersion(ba.win)

			WAVE/T folderList      = GetAnalysisBrowserGUIFolderList()
			WAVE   folderSelection = GetAnalysisBrowserGUIFolderSelection()
			WAVE/Z indices         = FindIndizes(folderSelection, col = 0, var = LISTBOX_SELECT_OR_SHIFT_SELECTION, prop = PROP_MATCHES_VAR_BIT_MASK)
			if(!WaveExists(indices))
				size = DimSize(folderList, ROWS)
				Make/FREE/N=(size) indices
				indices = size - 1 - p
			else
				Sort/R indices, indices
			endif

			Make/FREE/T/N=(DimSize(indices, ROWS)) refreshList

			for(index : indices)
				entry = folderList[index]
				if(!FileExists(entry) && !FolderExists(entry))
					AB_RemoveExperimentEntry(ba.win, folderList[index])
					DeleteWavePoint(folderSelection, ROWS, index = index)
					DeleteWavePoint(folderList, ROWS, index = index)
				else
					refreshList[refreshIndex] = entry
					refreshIndex             += 1
				endif
			endfor
			AB_SaveSourceListInSettings()
			Redimension/N=(refreshIndex) refreshList

			for(entry : refreshList)
				AB_RemoveExperimentEntry(ba.win, entry)
			endfor
			Duplicate/FREE/T refreshList, refreshInverted
			refreshInverted = refreshList[refreshIndex - 1 - p]
			AB_AddExperimentEntries(ba.win, refreshInverted)

			AB_UpdateColors()
			AB_CollapseAll()
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Button "Open folder(s)"
Function AB_ButtonProc_OpenFolders(STRUCT WMButtonAction &ba) : ButtonControl

	string symbPath, folder
	variable size, i

	switch(ba.eventCode)
		case 2: // mouse up
			AB_CheckPanelVersion(ba.win)

			WAVE/T folderList      = GetAnalysisBrowserGUIFolderList()
			WAVE   folderSelection = GetAnalysisBrowserGUIFolderSelection()
			size     = DimSize(folderSelection, ROWS)
			symbPath = GetUniqueSymbolicPath()
			for(i = 0; i < size; i += 1)
				if(folderSelection[i] == 1)
					if(FileExists(folderList[i]))
						folder = GetFolder(folderList[i])
					elseif(FolderExists(folderList[i]))
						folder = folderList[i]
					else
						continue
					endif
					NewPath/O/Q/Z $symbPath, folder
					PathInfo/SHOW $symbPath
				endif
			endfor
			KillPath/Z $symbPath
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Button "Remove folder(s)"
Function AB_ButtonProc_Remove(STRUCT WMButtonAction &ba) : ButtonControl

	variable size, i, selCode

	switch(ba.eventCode)
		case 2: // mouse up
			AB_CheckPanelVersion(ba.win)

			WAVE/T folderList      = GetAnalysisBrowserGUIFolderList()
			WAVE   folderSelection = GetAnalysisBrowserGUIFolderSelection()
			size = DimSize(folderSelection, ROWS)
			for(i = size - 1; i >= 0; i -= 1)
				selCode = folderSelection[i]
				if(selCode & LISTBOX_SELECT_OR_SHIFT_SELECTION)
					AB_RemoveExperimentEntry(ba.win, folderList[i])
					DeleteWavePoint(folderSelection, ROWS, index = i)
					DeleteWavePoint(folderList, ROWS, index = i)
				endif
			endfor
			AB_SaveSourceListInSettings()
			AB_CollapseAll()
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Button "Add folder"
/// Display dialog box for choosing a folder and call AB_ScanFolder()
Function AB_ButtonProc_AddFolder(STRUCT WMButtonAction &ba) : ButtonControl

	string baseFolder, folder
	variable size

	switch(ba.eventCode)
		case 2: // mouse up
			AB_CheckPanelVersion(ba.win)

			NVAR   JSONid        = $GetSettingsJSONid()
			WAVE/T setFolderList = JSON_GetTextWave(jsonID, SETTINGS_AB_FOLDER)
			size = DimSize(setFolderList, ROWS)
			if(size)
				baseFolder = GetFolder(setFolderList[size - 1])
			else
				baseFolder = GetUserDocumentsFolderPath()
			endif
			folder = AskUserForExistingFolder(baseFolder)
			if(IsEmpty(folder))
				break
			endif
			FindValue/TEXT=folder/TXOP=4 setFolderList
			if(V_Value >= 0)
				break
			endif

			AB_AddElementToSourceList(folder)

			Make/FREE/T wFolder = {folder}
			AB_AddExperimentEntries(ba.win, wFolder)
			AB_CollapseAll()
			break
		default:
			break
	endswitch

	return 0
End

/// @brief Button "Add files"
/// Display dialog box for choosing files and call AB_AddFolder()
Function AB_ButtonProc_AddFiles(STRUCT WMButtonAction &ba) : ButtonControl

	string baseFolder, symbPath, fileFilters, fNum, message, fileList
	variable i, size, index

	switch(ba.eventCode)
		case 2: // mouse up
			AB_CheckPanelVersion(ba.win)

			WAVE/T folderList = GetAnalysisBrowserGUIFolderList()
			size = DimSize(folderList, ROWS)
			if(size)
				baseFolder = GetFolder(folderList[size - 1])
			else
				baseFolder = GetUserDocumentsFolderPath()
			endif

			symbPath = GetUniqueSymbolicPath()
			NewPath/O/Q/Z $symbPath, baseFolder

			fileFilters = "Data Files (*.pxp,*.nwb,*.uxp):.pxp,.nwb,.uxp;All Files:.*;"
			message     = "Select data file(s)"
			Open/D/R/MULT=1/F=fileFilters/M=message/P=$symbPath fnum
			fileList = S_fileName
			KillPath/Z $symbPath
			if(IsEmpty(fileList))
				break
			endif
			WAVE/T selFiles = ListToTextWave(fileList, "\r")
			AB_AddFiles(ba.win, selFiles)
			AB_CollapseAll()
			break
		default:
			break
	endswitch

	return 0
End

static Function AB_AddFiles(string win, WAVE/T selFiles)

	variable i, index, size

	Duplicate/FREE/T selFiles, newFiles

	WAVE/T folderList = GetAnalysisBrowserGUIFolderList()
	size = DimSize(selFiles, ROWS)
	for(i = 0; i < size; i += 1)
		FindValue/TEXT=selFiles[i]/TXOP=4 folderList
		if(V_Value >= 0)
			continue
		endif
		AB_AddElementToSourceList(selFiles[i])
		newFiles[index] = selFiles[i]
		index          += 1
	endfor
	Redimension/N=(index) newFiles

	AB_AddExperimentEntries(win, newFiles)
End

Function AB_AddElementToSourceList(string entry)

	variable size

	WAVE/T entryList = GetAnalysisBrowserGUIFolderList()
	size = DimSize(entryList, ROWS)
	Redimension/N=(size + 1) entryList
	entryList[size] = entry
	WAVE folderSelection = GetAnalysisBrowserGUIFolderSelection()
	Redimension/N=(size + 1, -1, -1) folderSelection

	AB_SaveSourceListInSettings()
End

static Function AB_SaveSourceListInSettings()

	WAVE/T entryList = GetAnalysisBrowserGUIFolderList()

	Make/FREE/T/N=(DimSize(entryList, ROWS)) setFolderList
	setFolderList[] = entryList[p]
	NVAR JSONid = $GetSettingsJSONid()
	JSON_SetWave(jsonID, SETTINGS_AB_FOLDER, setFolderList)
End

Function AB_CheckboxProc_NWB(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	switch(cba.eventCode)
		case 2: // mouse up
			AB_CheckPanelVersion(cba.win)
			SetCheckBoxState(cba.win, "check_load_pxp", !cba.checked)
			PGC_SetAndActivateControl(cba.win, "button_AB_refresh")
			break
		default:
			break
	endswitch

	return 0
End

Function AB_CheckboxProc_PXP(STRUCT WMCheckboxAction &cba) : CheckBoxControl

	switch(cba.eventCode)
		case 2: // mouse up
			AB_CheckPanelVersion(cba.win)
			SetCheckBoxState(cba.win, "check_load_nwb", !cba.checked)
			PGC_SetAndActivateControl(cba.win, "button_AB_refresh")
			break
		default:
			break
	endswitch

	return 0
End

Function/S AB_GetSweepBrowserTitles()

	string wName
	string sbList = ""

	WAVE/T wList = ListToTextWave(WinList(SWEEPBROWSER_WINDOW_NAME + "*", ";", "WIN:1"), ";")
	for(wName : wList)
		GetWindow $wName, title
		sbList = AddListItem(S_Value, sbList, ";", Inf)
	endfor

	return sbList
End

Function/S AB_GetSweepBrowserListForPopup()

	string sbList

	sbList = AB_GetSweepBrowserTitles()
	sbList = AddListItem("New", sbList)

	return sbList
End

static Function/S AB_GetSweepBrowserWindowFromTitle(string winTitle)

	WAVE/T wList = ListToTextWave(WinList(SWEEPBROWSER_WINDOW_NAME + "*", ";", "WIN:1"), ";")
	for(wName : wList)
		GetWindow $wName, title
		if(!CmpStr(winTitle, S_Value, 1))
			return wName
		endif
	endfor

	FATAL_ERROR("Could not find SweepBrowser with given title: " + winTitle)
End

/// @brief Button "Select same stim set sweeps"
Function AB_ButtonProc_SelectStimSets(STRUCT WMButtonAction &ba) : ButtonControl

	variable numEntries, i
	string selectedStimSet

	switch(ba.eventCode)
		case 2: // mouse up
			AB_CheckPanelVersion(ba.win)

			WAVE/T expBrowserList = GetExperimentBrowserGUIList()
			WAVE   expBrowserSel  = GetExperimentBrowserGUISel()

			WAVE/Z indizes = FindIndizes(expBrowserSel, col = 0, var = LISTBOX_SELECT_OR_SHIFT_SELECTION, prop = PROP_MATCHES_VAR_BIT_MASK)

			if(!WaveExists(indizes) || DimSize(indizes, ROWS) != 1)
				print "Please select exactly one row to use this feature"
				ControlWindowToFront()
				break
			endif

			selectedStimSet = expBrowserList[indizes[0]][%$"stim sets"]

			if(isEmpty(selectedStimSet))
				print "Can not work with an empty stim set in the selection"
				ControlWindowToFront()
				break
			endif

			WAVE indizes = FindIndizes(expBrowserList, colLabel = "stim sets", str = selectedStimSet)
			expBrowserSel[][] = expBrowserSel[p][q] & ~(LISTBOX_SELECT_OR_SHIFT_SELECTION)

			numEntries = DimSize(indizes, ROWS)
			for(i = 0; i < numEntries; i += 1)
				expBrowserSel[indizes[i]][] = expBrowserSel[p][q] | LISTBOX_SELECT_OR_SHIFT_SELECTION
			endfor

			break
		default:
			break
	endswitch

	return 0
End

/// @brief main ListBox list_experiment_contents
Function AB_ListBoxProc_ExpBrowser(STRUCT WMListboxAction &lba) : ListBoxControl

	variable mask, numRows, row, col

	switch(lba.eventCode)
		case 2:
			if(!(lba.eventMod & WINDOW_HOOK_EMOD_RIGHTCLICK))
				return 0
			endif
			AB_ShowFileContextMenu(AB_GetFilePathFromExpBrowserListboxRow(lba.row))
			break
		case 5: // fallthrough, cell selection + shift key
		case 4: // cell selection
			AB_CheckPanelVersion(lba.win)
			AB_UpdateColors()
			break

		case 13: // sel wave update
			AB_CheckPanelVersion(lba.win)

			row = lba.row
			col = lba.col

			WAVE/T expBrowserList    = GetExperimentBrowserGUIList()
			WAVE   expBrowserSel     = GetExperimentBrowserGUISel()
			WAVE/T expBrowserListBak = CreateBackupWave(expBrowserList)
			WAVE   expBrowserSelBak  = CreateBackupWave(expBrowserSel)

			numRows = DimSize(expBrowserSel, ROWS)
			if(row < 0 || row >= numRows || col < 0 || col >= DimSize(expBrowserSel, COLS))
				// clicked outside the list
				AB_UpdateColors()
				break
			endif
			mask = expBrowserSel[row][col]
			if(!(mask & LISTBOX_TREEVIEW)) // clicked cell is not a treeview expansion node
				AB_UpdateColors()
				break
			endif

			if(mask & LISTBOX_TREEVIEW_EXPANDED)
				AB_ExpandListEntry(row, col)
			else
				AB_CollapseListEntry(row, col)
			endif
			AB_UpdateColors()

			break
		default:
			break
	endswitch

	return 0
End

static Function/S AB_GetFilePathFromExpBrowserListboxRow(variable row)

	variable mapIndex

	WAVE/T expBrowserList = GetExperimentBrowserGUIList()
	WAVE/T map            = GetAnalysisBrowserMap()
	mapIndex = str2num(expBrowserList[row][%file][1])

	return map[mapIndex][%DiscLocation]
End

static Function AB_UpdateColors()

	variable size, index
	string fName

	WAVE/T expBrowserList  = GetExperimentBrowserGUIList()
	WAVE   expBrowserSel   = GetExperimentBrowserGUISel()
	WAVE/T folderList      = GetAnalysisBrowserGUIFolderList()
	WAVE   folderSelection = GetAnalysisBrowserGUIFolderSelection()

	MultiThread folderSelection[][0][%$LISTBOX_LAYER_BACKGROUND] = 0
	size = min(GetNumberFromWaveNote(expBrowserList, NOTE_INDEX), DimSize(expBrowserList, ROWS))
	if(!size)
		return NaN
	endif
	WAVE/Z indizes = FindIndizes(expBrowserSel, col = 0, var = 0x1, prop = PROP_MATCHES_VAR_BIT_MASK, endRow = size - 1)
	if(!WaveExists(indizes))
		return NaN
	endif
	for(index : indizes)
		fName = expBrowserList[index][%type][1]
		if(IsEmpty(fName))
			continue
		endif
		FindValue/TEXT=fName/TXOP=4 folderList
		ASSERT(V_row >= 0, "Source file not found in folderlist")
		folderSelection[V_row][0][%$LISTBOX_LAYER_BACKGROUND] = 2
	endfor
End

/// @brief Button "Open comment NB"
Function AB_ButtonProc_OpenCommentNB(STRUCT WMButtonAction &ba) : ButtonControl

	variable row, mapIndex
	string device, fileName, dataFolder, discLocation
	string titleString, commentNotebook, comment

	switch(ba.eventCode)
		case 2: // mouse up
			AB_CheckPanelVersion(ba.win)

			WAVE/T expBrowserList = GetExperimentBrowserGUIList()
			WAVE   expBrowserSel  = GetExperimentBrowserGUISel()
			WAVE/T map            = GetAnalysisBrowserMap()

			WAVE/Z indizes = FindIndizes(expBrowserSel, col = 0, var = LISTBOX_SELECT_OR_SHIFT_SELECTION, prop = PROP_MATCHES_VAR_BIT_MASK)

			if(!WaveExists(indizes) || DimSize(indizes, ROWS) != 1)
				print "Please select a sweep belonging to a device to use this feature"
				ControlWindowToFront()
				break
			endif

			row      = indizes[0]
			mapIndex = str2num(expBrowserList[row][%file][1])

			device = GetLastNonEmptyEntry(expBrowserList, "device", row)
			if(isEmpty(device))
				print "Please select a sweep belonging to a device to use this feature"
				ControlWindowToFront()
				break
			endif

			fileName     = map[mapIndex][%FileName]
			dataFolder   = map[mapIndex][%DataFolder]
			discLocation = map[mapIndex][%DiscLocation]

			SVAR/Z/SDFR=GetAnalysisDeviceFolder(dataFolder, device) userComment
			if(!SVAR_Exists(userComment))
				comment = "The user comment string was not loaded or does not exist for the given device!"
			else
				comment = userComment
			endif

			sprintf titleString, "Experiment %s and Device %s", fileName, device
			commentNotebook = UniqueName("EB_UserComment", 10, 0)
			NewNoteBook/K=1/F=0/OPTS=(2^2 + 2^3)/N=$commentNotebook/W=(0, 0, 300, 400) as titleString
			ReplaceNotebookText(commentNotebook, comment)
			break
		default:
			break
	endswitch

	return 0
End

Function AB_ButtonProc_ResaveAsNWB(STRUCT WMButtonAction &ba) : ButtonControl

	variable row, i, index, overwrite
	string fileType, discLocation, experiment, win

	switch(ba.eventCode)
		case 2: // mouse up
			win = ba.win
			AB_CheckPanelVersion(ba.win)
			WAVE/T map = GetAnalysisBrowserMap()

			index = GetNumberFromWaveNote(map, NOTE_INDEX)

			if(!index)
				printf "No experiments loaded, aborting.\r"
				ControlWindowToFront()
				break
			endif

			overwrite = GetCheckBoxState(win, "checkbox_load_overwrite")

			for(i = 0; i < index; i += 1)
				experiment   = map[i][%FileName]
				fileType     = map[i][%FileType]
				discLocation = map[i][%DiscLocation]

				if(cmpstr(fileType, ANALYSISBROWSER_FILE_TYPE_NWBv1))
					printf "Skipping %s: Resaving to NWBv2 only works for NWBv1 files.\r", experiment
					ControlWindowToFront()
					continue
				endif

				AB_ReExport(i, overwrite)
			endfor
			break
		default:
			break
	endswitch
End

static Function AB_LoadAllSweepsAndStimsets(string discLocation, string dataFolder, string fileType, string device)

	variable i, sweep, numEntries

	// load all sweeps and stimsets
	WAVE/Z sweeps = GetAnalysisChannelSweepWave(dataFolder, device)

	if(!WaveExists(sweeps))
		return NaN
	endif

	numEntries = DimSize(sweeps, ROWS)
	for(i = 0; i < numEntries; i += 1)
		sweep = sweeps[i]

		if(!IsValidSweepNumber(sweep))
			continue
		endif

		AB_LoadStimsetFromFile(discLocation, dataFolder, fileType, device, sweep, overwrite = 1)
		AB_LoadSweepFromFile(discLocation, dataFolder, fileType, device, sweep, overwrite = 1)
	endfor
End

static Function/S AB_ReExportGetNewFullFilePath(string fullFilePath, variable numDevices, string device)

	string suffix, name

	suffix = "." + GetFileSuffix(fullFilePath)
	name   = GetFile(fullFilePath)
	sprintf name, "%s%s-converted%s", RemoveEnding(name, suffix), SelectString(numDevices > 1, "", "-" + device), suffix
	return GetFolder(fullFilePath) + name
End

static Function AB_ReExport(variable index, variable overwrite)

	string fileName, discLocation, dataFolder, experiment, path, name, suffix
	string folder, devices, device, list, fileType
	variable numDevices, i, j, numEntries, sweep, ret

	WAVE/T map = GetAnalysisBrowserMap()

	fileType     = map[index][%FileType]
	discLocation = map[index][%DiscLocation]
	dataFolder   = map[index][%DataFolder]
	experiment   = map[index][%FileName]

	// Iterate over all devices
	devices    = AB_GetAllDevicesForExperiment(dataFolder)
	numDevices = ItemsInList(devices)

	for(i = 0; i < numDevices; i += 1)
		device = StringFromList(i, devices)

		// load all sweeps and stimsets into the analysis browser
		AB_LoadAllSweepsAndStimsets(discLocation, dataFolder, fileType, device)

		// load stored testpulses
		AB_LoadStoredTestpulsesFromNWB(discLocation, dataFolder, device)

		// Move HardwareDevices out of the way
		path = GetDAQDevicesFolderAsString()
		RenameDataFolderToUniqueName(path, "_old")

		// Move LabNoteBook out of the way
		path = GetLabNotebookFolderAsString()
		RenameDataFolderToUniqueName(path, "_old")

		// Move NWB out of the way
		path = GetNWBFolderAS()
		RenameDataFolderToUniqueName(path, "_old")

		// Create folders
		DFREF dfr = GetDeviceDataPath(device)
		DFREF dfr = GetDeviceTestPulse(device)
		DFREF dfr = GetLabNotebookFolder()
		DFREF dfr = GetDevSpecLabNBFolder(device)

		// Copy labnotebooks
		// root:MIES:Analysis:HardwareTests_compressed_V1_example:ITC18USB_Dev_0:labnotebook:
		// ↓
		// root:MIES:LabNoteBook:ITC18USB:Device0:
		DFREF source = GetAnalysisLabNBFolder(dataFolder, device)
		path = GetDevSpecLabNBFolderAsString(device)
		path = path + "::" + GetFile(path)
		DuplicateDataFolder/O=2 source, $path

		// Copy TPStorage and StoredTestPulses waves
		// root:MIES:Analysis:HardwareTests_compressed_V1_example:ITC18USB_Dev_0:testpulse:
		// ↓
		// root:MIES:HardwareDevices:ITC18USB:Device0:TestPulse:
		DFREF source = GetAnalysisDeviceTestPulse(dataFolder, device)
		path = GetDeviceTestPulseAsString(device) + "::"
		DuplicateDataFolder/O=2 source, $path

		// Copy DAQConfig waves
		// root:MIES:Analysis:HardwareTests_compressed_V1_example:ITC18USB_Dev_0:config:
		// ↓
		// root:MIES:HardwareDevices:ITC18USB:Device0:Data:
		DFREF source = GetAnalysisDeviceConfigFolder(dataFolder, device)
		path = GetDeviceDataPathAsString(device)
		path = path + "::" + GetFile(path)
		DuplicateDataFolder/O=2 source, $path

		// Copy sweeps
		// root:MIES:Analysis:HardwareTests_compressed_V1_example:ITC18USB_Dev_0:sweep:
		// ↓
		// root:MIES:HardwareDevices:ITC18USB:Device0:Data:
		DFREF source = GetAnalysisSweepPath(dataFolder, device)
		path = GetDeviceDataPathAsString(device)
		path = path + "::" + GetFile(path)
		DuplicateDataFolder/O=2 source, $path

		// Mock deviceID for GetAllDevices
		NVAR deviceID = $GetDAQDeviceID(device)

		DFREF dfr = GetDeviceDataPath(device)

		if(!IsDataFolderEmpty(dfr))
			// Copy reconstructed 2D sweep waves
			// Because we only have 1D sweep waves from the NWB file
			RecreateMissingSweepAndConfigWaves(device, dfr)
			//
			// root:reconstructed
			// ↓
			// root:MIES:HardwareDevices:ITC18USB:Device0:Data:
			DFREF source = root:reconstructed
			path = GetDeviceDataPathAsString(device)
			path = path + "::" + GetFile(path)
			DuplicateDataFolder/O=2 source, $path
		endif

		// Place history in override location
		DFREF source = GetAnalysisDeviceFolder(dataFolder, device)
		SVAR/Z/SDFR=source historyAndLogFile
		if(SVAR_Exists(historyAndLogFile))
			SVAR overrideHistoryAndLogFile = $GetNwbOverrideHistoryAndLogFile()
			overrideHistoryAndLogFile = historyAndLogFile
		endif

		// Now export all that data into NWBv2
		path = AB_ReExportGetNewFullFilePath(discLocation, numDevices, device)

		ret = NWB_ExportAllData(NWB_VERSION_LATEST, overrideFullFilePath = path, writeStoredTestPulses = 1, overwrite = overwrite)

		if(!ret)
			printf "####\r"
			printf "Folder: %s\r", GetWindowsPath(GetFolder(discLocation))
			printf "NWbv1: %s\r", GetFile(discLocation)
			printf "NWbv2 (new): %s\r", GetFile(path)
			printf "####\r"
		endif
	endfor
End

/// @brief Load dropped NWB files into the analysis browser
static Function BeforeFileOpenHook(variable refNum, string file, string pathName, string type, string creator, variable kind)

	string baseFolder, fileSuffix, entry, win
	variable numEntries, loadOpts

	LOG_AddEntry(PACKAGE_MIES, "start")

	fileSuffix = GetFileSuffix(file)
	if(cmpstr(fileSuffix, "nwb"))
		LOG_AddEntry(PACKAGE_MIES, "end")
		return 0
	endif

	Pathinfo $pathName
	baseFolder = S_path

	win = AB_OpenAnalysisBrowser(restoreSettings = 0)
	// we can not add files to the map if some entries are collapsed
	// so we have to expand all first.
	PGC_SetAndActivateControl(win, "button_expand_all", val = 1)
	loadOpts = AB_GetLoadSettings(win)

	entry = basefolder + file

	WAVE/T activeFiles = AB_GetCurrentlyOpenNWBFiles()
	if(!IsNaN(GetRowIndex(activeFiles, str = entry)))
		printf "Can not add dropped file because it is currently open for data export: %s\rTo close the file unlock the device in the respective acquisition panel.", entry
		ControlWindowToFront()
		LOG_AddEntry(PACKAGE_MIES, "end")
		return 1
	endif

	if(AB_AddFile(win, entry, entry, loadOpts))
		// already loaded or error
		LOG_AddEntry(PACKAGE_MIES, "end")
		return 1
	endif
	AB_AddElementToSourceList(entry)

	AB_ResetListBoxWaves()

	LOG_AddEntry(PACKAGE_MIES, "end")

	return 1
End

Function/S AB_GetAllDevicesForExperiment(string dataFolder)

	DFREF dfr = GetAnalysisExpFolder(dataFolder)

	return GetListOfObjects(dfr, ".*", typeFlag = COUNTOBJECTS_DATAFOLDER)
End

/// @brief Return all experiments the analysis browser knows about
Function/S AB_GetAllExperiments()

	variable i, index
	string list = ""

	WAVE/T map = GetAnalysisBrowserMap()
	index = GetNumberFromWaveNote(map, NOTE_INDEX)

	for(i = 0; i < index; i += 1)
		list = AddListItem(map[i][%DataFolder], list, ";", Inf)
	endfor

	return list
End

/// @brief Get stimset list either by analysing dataFolder of loaded sweep or if device is empty, get all stimsets
///
/// numericalValues and textualValues are generated from previously loaded data.
/// used in the context of loading from a stored experiment file.
/// on load a sweep is stored in a device/dataFolder hierarchy.
///
/// @returns list of stimsets
Function/S AB_GetStimsetList(string fileType, string discLocation, string dataFolder, string device, variable sweep)

	if(IsEmpty(device))
		strswitch(fileType)
			case ANALYSISBROWSER_FILE_TYPE_IGOR:
				return AB_GetStimsetListFromIgorFile(discLocation)
			case ANALYSISBROWSER_FILE_TYPE_NWBv1: // fallthrough
			case ANALYSISBROWSER_FILE_TYPE_NWBv2:
				return NWB_ReadStimSetList(discLocation)
			default:
				FATAL_ERROR("fileType not handled")
		endswitch
	endif

	DFREF dfr = GetAnalysisLabNBFolder(dataFolder, device)
	WAVE/SDFR=dfr   $LBN_NUMERICAL_VALUES_NAME
	WAVE/T/SDFR=dfr $LBN_TEXTUAL_VALUES_NAME

	return AB_GetStimsetFromSweepGeneric(sweep, numericalValues, textualValues)
End

/// @brief Get related Stimsets by corresponding sweep
///
/// input numerical and textual values storage waves for current sweep
///
/// @returns list of stimsets
static Function/S AB_GetStimsetFromSweepGeneric(variable sweep, WAVE numericalValues, WAVE/T textualValues)

	variable i, j, numEntries
	string ttlList, name
	string stimsetList = ""

	WAVE/Z/T stimsets = GetLastSetting(textualValues, sweep, STIM_WAVE_NAME_KEY, DATA_ACQUISITION_MODE)
	if(!WaveExists(stimsets))
		return ""
	endif

	// handle AD/DA channels
	for(i = 0; i < NUM_HEADSTAGES; i += 1)
		name = stimsets[i]
		if(isEmpty(name))
			continue
		endif
		stimsetList = AddListItem(name, stimsetList)
	endfor

	WAVE/Z/T ttlStimSets = GetTTLLabnotebookEntry(textualValues, LABNOTEBOOK_TTL_STIMSETS, sweep)

	// handle TTL channels
	for(i = 0; i < NUM_DA_TTL_CHANNELS; i += 1)

		if(!WaveExists(ttlStimsets))
			break
		endif

		name = ttlStimSets[i]
		if(isEmpty(name))
			continue
		endif
		stimsetList = AddListItem(name, stimsetList)
	endfor

	return stimsetList
End

/// @brief Get stimsets by analysing currently loaded sweep
///
/// numericalValues and textualValues are generated from device
///
/// @returns list of stimsets
Function/S AB_GetStimsetFromPanel(string device, variable sweep)

	WAVE   numericalValues = GetLBNumericalValues(device)
	WAVE/T textualValues   = GetLBTextualValues(device)

	return AB_GetStimsetFromSweepGeneric(sweep, numericalValues, textualValues)
End

Function AB_WindowHook(STRUCT WMWinHookStruct &s)

	switch(s.eventCode)
		case EVENT_WINDOW_HOOK_KILLVOTE:
			AB_SaveSourceListInSettings()
			break
		case EVENT_WINDOW_HOOK_KILL:

			AB_MemoryFreeMappedDF()
			AB_RemoveEmptyWorkingDF()

			break
		default:
			break
	endswitch

	// return zero so that other hooks are called as well
	return 0
End

static Function AB_MemoryFreeMappedDF()

	variable i, size

	WAVE/T map = GetAnalysisBrowserMap()
	size = GetNumberFromWaveNote(map, NOTE_INDEX)
	for(i = 0; i < size; i += 1)
		AB_RemoveMapEntry(i)
	endfor
End

Function AB_ButtonProc_LoadTPStorage(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventcode)
		case 2:
			AB_CheckPanelVersion(ba.win)
			AB_LoadFromFile(AB_LOAD_TP_STORAGE)
			break
		default:
			break
	endswitch

	return 0
End

Function AB_ButtonProc_LoadHistoryAndLogs(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventcode)
		case 2:
			AB_CheckPanelVersion(ba.win)
			AB_LoadFromFile(AB_LOAD_HISTORYANDLOGS)
			break
		default:
			break
	endswitch

	return 0
End

static Function AB_CollapseAll()

	AB_CollapseListColumn(DEVICE_TREEVIEW_COLUMN)
	AB_CollapseListColumn(EXPERIMENT_TREEVIEW_COLUMN)
End

Function AB_OnCloseSweepBrowserUpdatePopup(string closingSweepBrowser)

	string sbTitle, sbWin

	if(!WindowExists(ANALYSIS_BROWSER_NAME))
		return NaN
	endif
	sbTitle = GetPopupMenuString(ANALYSIS_BROWSER_NAME, "popup_SweepBrowserSelect")
	if(!CmpStr(sbTitle, "New"))
		return NaN
	endif

	sbWin = AB_GetSweepBrowserWindowFromTitle(sbTitle)
	if(!CmpStr(sbWin, closingSweepBrowser))
		SetPopupMenuIndex(ANALYSIS_BROWSER_NAME, "popup_SweepBrowserSelect", 0)
	endif
End

static Function AB_ShowFileContextMenu(string filePath)

	string symbPath

	PopupContextualMenu "Show in explorer;Path to clipboard;"
	switch(V_flag)
		case 1:
			OpenExplorerAtFile(filePath)
			break
		case 2:
			PutScrapText GetWindowsPath(filePath)
			break
		default:
			return NaN
	endswitch
End

Function AB_ListBoxProc_FileFolderList(STRUCT WMListboxAction &lba) : ListBoxControl

	switch(lba.eventCode)
		case 2: // mouse up
			if(!(lba.eventMod & WINDOW_HOOK_EMOD_RIGHTCLICK))
				return 0
			endif
			WAVE/T folderList = GetAnalysisBrowserGUIFolderList()
			AB_ShowFileContextMenu(folderList[lba.row])
			break
		default:
			break
	endswitch

	return 0
End
