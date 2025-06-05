#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

/// @file MIES_Include.ipf
/// @brief Main include
///
/// Developer instructions for raising the required nightly versions:
///
/// - Update the revision numbers for IP9 below in the expression involving
///   `BUILD`, and also `CI_IGOR_REVISION` in .github/workflows/test-igor-workflow.yml
/// - Upload the nightly zip packages to the FTP (Thomas' job). Don't delete the
///   old zip packages, we still need them.
/// - Update the below URLs
/// - Update Igor Pro on the CI boxes (Thomas' job).
/// - Remove old workarounds marked with `@todo`

// These are sphinx substitutions destined for Packages/doc/installation_subst.txt.
// They are defined here so that we can parse them from within IP.
//
// .. |IgorPro9WindowsNightly| replace:: `Igor Pro 9 (Windows) <https://www.byte-physics.de/Downloads/WinIgor9_01Dec2023.zip>`__
// .. |IgorPro9MacOSXNightly| replace:: `Igor Pro 9 (MacOSX) <https://www.byte-physics.de/Downloads/MacIgor9_01Dec2023.dmg>`__

#pragma IgorVersion = 9.00

#if IgorVersion() < 10 && (NumberByKey("BUILD", IgorInfo(0)) < 56565)
#define TOO_OLD_IGOR
#endif

///@cond HIDDEN_SYMBOL
#if !defined(IGOR64)
#define TOO_OLD_IGOR
#endif
///@endcond // HIDDEN_SYMBOL

#ifdef TOO_OLD_IGOR

static StrConstant IP_DOCU_UPDATE_URL = "https://alleninstitute.github.io/MIES/installation.html#igor-pro-update-nightly"

Window OpenPanelWithDocumentationLink() : Panel
	PauseUpdate; Silent 1 // building window...
	NewPanel/K=1/W=(841, 378, 1150, 576) as "OpenPanelWithDocumentationLink"
	DrawText 20, 60, "\\JC\\Zr200\\f01 MIES requires a newer \r version of Igor Pro"
	Button button0, pos={74.00, 70.00}, size={150.00, 50.00}, proc=ButtonProc_OpenMiesDocuUpdateNightly, title="Open Igor \r update instructions"
	Button button1, pos={74.00, 130.00}, size={150.00, 50.00}, proc=ButtonProc_DownloadNightly, title="Download approved \r Igor Pro version"
EndMacro

Function ButtonProc_OpenMiesDocuUpdateNightly(STRUCT WMButtonAction &ba) : ButtonControl

	switch(ba.eventCode)
		case 2: // mouse up
			BrowseURL IP_DOCU_UPDATE_URL
			break
		default:
			break
	endswitch

	return 0
End

static Function/S GetDownloadLink()

	string igorMajorVersion, text, lineWithLink, url, os

	igorMajorVersion = num2istr(IgorVersion())

#if defined(WINDOWS)
	os = "Windows"
#elif defined(MACINTHOSH)
	os = "MacOSX"
#else
	ASSERT_TS(0, "Unsupported OS")
#endif

	text         = ProcedureText("", 0, "MIES_Include.ipf")
	lineWithLink = GrepList(text, "\\Q|IgorPro" + igorMajorVersion + os + "Nightly|\\E", 0, "\r")
	SplitString/E=".*<(.*)>.*" lineWithLink, url

	if(V_Flag != 1)
		Abort "Please manually download the nightly build from the documentation link."
	endif

	return url
End

static Function/S GetFileNameFromURL(string url)

	variable pos

	pos = strsearch(url, "/", Inf, 1)

	return url[pos + 1, Inf]
End

static Function/S GetDestinationIgorPath()

	string path = "tmpPath"
	NewPath/C/O $path, SpecialDirPath("Temporary", 0, 0, 1) + ":IgorNightlyDownloads"

	return path
End

Function ButtonProc_DownloadNightly(STRUCT WMButtonAction &ba) : ButtonControl

	string url, filename, path

	switch(ba.eventCode)
		case 2: // mouse up
			url  = GetDownloadLink()
			path = GetDestinationIgorPath()
			printf "Please wait while we download %s.\r", url
			filename = GetFileNameFromURL(url)
			URLRequest/O/P=$path/FILE=filename url=url
			PathInfo/SHOW $path
			break
		default:
			break
	endswitch

	return 0
End

static Function AfterCompiledHook()

	string igorMajorVersion

#if defined(IGOR64)
	igorMajorVersion = num2istr(IgorVersion())
	printf "Your Igor Pro %s version is too old to be usable for MIES. Please follow the download instructions at: %s\r", igorMajorVersion, IP_DOCU_UPDATE_URL
	Execute "OpenPanelWithDocumentationLink()"
#else
	printf "The 32bit version of Igor Pro is not supported anymore.\r"
#endif
End

#else

// stock igor
#include <Resize Controls>
#include <Resize Controls Panel>
#include <ZoomBrowser>

#ifndef THREADING_DISABLED
#include <FunctionProfiling>
#endif // !THREADING_DISABLED

// third party includes
#include "ACL_TabUtilities"
#include "ACL_UserdataEditor"

// JSON XOP
#include "json_functions"

// NWB for Igor Pro
#include "IPNWB_Include"

#if exists("SutterDAQScanWave")
#include "IPA_Control"
#endif

// ZeroMQ procedures
#include "ZeroMQ_Interop"

// our includes
#include "MIES_AcceleratedModifyGraph"
#include "MIES_AcquisitionStateHandling"
#include "MIES_AmplifierInteraction"
#include "MIES_AnalysisBrowser"
#include "MIES_AnalysisBrowser_Macro"
#include "MIES_AnalysisBrowser_SweepBrowser"
#include "MIES_AnalysisBrowser_SweepBrowser_Export"
#include "MIES_AnalysisBrowser_SweepBrowser_Export_Macro"
#include "MIES_AnalysisFunctionHelpers"
#include "MIES_AnalysisFunctionManagement"
#include "MIES_AnalysisFunctions_PatchSeq"
#include "MIES_AnalysisFunctions_Dashboard"
#include "MIES_AnalysisFunctions_MultiPatchSeq"
#include "MIES_AnalysisFunctions_MultiPatchSeq_SpikeControl"
#include "MIES_AnalysisFunctionPrototypes"
#include "MIES_AnalysisFunctions"
#include "MIES_ArtefactRemoval"
#include "MIES_AsynchronousData"
#include "MIES_Async"
#include "MIES_Blowout"
#include "MIES_Browser_Plotter"
#include "MIES_BrowserSettingsPanel"

#if defined(BACKGROUND_TASK_DEBUGGING)
#include "MIES_BackgroundWatchdog"
#endif

#include "MIES_Cache"
#include "MIES_CheckInstallation"
#include "MIES_Configuration"
#include "MIES_ConversionConstants"
#include "MIES_Constants"
#include "MIES_DAC-Hardware"
#include "MIES_DAEphys"
#include "MIES_DAEphys_Macro"
#include "MIES_DAEphys_GuiState"
#include "MIES_DANDI"
#include "MIES_DataBrowser"
#include "MIES_DataBrowser_Macro"
#include "MIES_DataAcquisition"
#include "MIES_DataAcquisition_Single"
#include "MIES_DataAcquisition_Multi"
#include "MIES_DataConfigurator"
#include "MIES_DataConfiguratonRecreation"
#include "MIES_Debugging"
#include "MIES_DebugPanel"
#include "MIES_DebugPanel_Macro"
#include "MIES_Downsample"
#include "MIES_Epochs"
#include "MIES_EnhancedWMRoutines"
#include "MIES_ExperimentDocumentation"
#include "MIES_ForeignFunctionInterface"
#include "MIES_GlobalStringAndVariableAccess"
#include "MIES_GuiPopupMenuExt"
#include "MIES_GuiUtilities"
#include "MIES_IgorHooks"
#include "MIES_Indexing"
#include "MIES_InputDialog"
#include "MIES_InputDialog_Macro"
#include "MIES_IVSCC"
#include "MIES_IVSCC_Macro"
#include "MIES_JSONWaveNotes"
#include "MIES_Labnotebook"
#include "MIES_LogbookViewer"
#include "MIES_Logging"
#include "MIES_Menu"
#include "MIES_MiesUtilities_Algorithm"
#include "MIES_MiesUtilities_BackupWaves"
#include "MIES_MiesUtilities_Channels"
#include "MIES_MiesUtilities_Checks"
#include "MIES_MiesUtilities_Config"
#include "MIES_MiesUtilities_Conversion"
#include "MIES_MiesUtilities_DataManagement"
#include "MIES_MiesUtilities_Device"
#include "MIES_MiesUtilities_Getter"
#include "MIES_MiesUtilities_GUI"
#include "MIES_MiesUtilities_Logbook"
#include "MIES_MiesUtilities_Logging"
#include "MIES_MiesUtilities_Recreation"
#include "MIES_MiesUtilities_Settings"
#include "MIES_MiesUtilities_Sweep"
#include "MIES_MiesUtilities_System"
#include "MIES_MiesUtilities_Uploads"
#include "MIES_MiesUtilities_ZeroMQ"
#include "MIES_NeuroDataWithoutBorders"
#include "MIES_OptimzedOverlapDistributedAcquisition"
#include "MIES_Oscilloscope"
#include "MIES_OverlaySweeps"
#include "MIES_PackageSettings"
#include "MIES_Pictures"
#include "MIES_PressureControl"
#include "MIES_ProgrammaticGuiControl"
#include "MIES_Publish"
#include "MIES_PulseAveraging"
#include "MIES_RepeatedAcquisition"
#include "MIES_SamplingInterval"
#include "MIES_StimsetAPI"
#include "MIES_Structures"
#include "MIES_SweepFormula"
#include "MIES_SweepFormula_Helpers"
#include "MIES_SweepFormula_PSX"
#include "MIES_SweepFormula_PSX_Macro"
#include "MIES_SweepSaving"
#include "MIES_ThreadedFIFOHandling"
#include "MIES_ThreadsafeDataSharing"
#include "MIES_ThreadsafeUtilities"
#include "MIES_TestPulse"
#include "MIES_TestPulse_Single"
#include "MIES_TestPulse_Multi"
#include "MIES_TraceUserData"
#include "MIES_Utilities_Algorithm"
#include "MIES_Utilities_Debugger"
#include "MIES_Utilities_Checks"
#include "MIES_Utilities_Conversions"
#include "MIES_Utilities_DataFolder"
#include "MIES_Utilities_File"
#include "MIES_Utilities_JSON"
#include "MIES_Utilities_Generators"
#include "MIES_Utilities_GUI"
#include "MIES_Utilities_List"
#include "MIES_Utilities_Numeric"
#include "MIES_Utilities_ProgramFlow"
#include "MIES_Utilities_SFHCheckers"
#include "MIES_Utilities_Strings"
#include "MIES_Utilities_System"
#include "MIES_Utilities_Time"
#include "MIES_Utilities_WaveHandling"
#include "MIES_WaveBuilder"
#include "MIES_WaveBuilderPanel"
#include "MIES_WaveBuilder_Macro"
#include "MIES_WaveDataFolderGetters"
#include "MIES_WaverefBrowser"
#include "MIES_WaverefBrowser_Macro"

#endif // TOO_OLD_IGOR
