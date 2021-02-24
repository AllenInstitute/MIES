#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

/// @file MIES_Include.ipf
/// @brief Main include
///
/// Developer instructions for raising the required nightly versions:
///
/// - Update the revision numbers for IP8 and or IP9 below in the expression involving "BUILD"
/// - Upload the nightly zip package to the FTP (Thomas' job). Don't delete the
///   old zip packages, we still need them.
/// - Update the below URLs

// These are sphinx substitutions destined for Packages/doc/installation_subst.txt.
// They are defined here so that we can parse them from within IP.
//
// .. |IgorPro8Nightly| replace:: `Igor Pro 8 <https://www.byte-physics.de/Downloads/WinIgor8_06MAY2020.zip>`__
// .. |IgorPro9Nightly| replace:: `Igor Pro 9 <https://www.byte-physics.de/Downloads/WinIgor9_02FEB2021.zip>`__

#pragma IgorVersion=8.04

#if IgorVersion() >= 9.0
#if (NumberByKey("BUILD", IgorInfo(0)) < 37086)
#define TOO_OLD_IGOR
#endif
#else
#if (NumberByKey("BUILD", IgorInfo(0)) < 35712)
#define TOO_OLD_IGOR
#endif
#endif

#ifdef TOO_OLD_IGOR

Window OpenPanelWithDocumentationLink() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1 /W=(435,461,735,661) as "OpenPanelWithDocumentationLink"
	Button button0,pos={38.00,14.00},size={223.00,89.00},proc=ButtonProc_OpenMiesDocuUpdateNightly,title="Open MIES documentation for\r update instructions"
	Button button1,pos={51.00,133.00},size={195.00,29.00},proc=ButtonProc_DownloadNightly,title="Download Igor Pro nightly build"
EndMacro

Function ButtonProc_OpenMiesDocuUpdateNightly(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch(ba.eventCode)
		case 2: // mouse up
			BrowseURL "https://alleninstitute.github.io/MIES/installation.html#igor-pro-update-nightly"
			break
	endswitch

	return 0
End

static Function/S GetDownloadLink()

	string igorMajorVersion, text, lineWithLink, url

	igorMajorVersion = StringByKey("IGORVERS", IgorInfo(0))[0]

	text = ProcedureText("", 0, "MIES_Include.ipf")
	lineWithLink = GrepList(text, "\\Q|IgorPro" + igorMajorVersion + "Nightly|\\E", 0, "\r")
	SplitString/E=".*<(.*)>.*" lineWithLink, url

	if(V_Flag != 1)
		Abort "Please manually download the nightly build from the documentation link."
	endif

	return url
End

static Function/S GetFileNameFromURL(string url)

	variable pos

	pos = strsearch(url, "/", inf, 1)

	return url[pos + 1, inf]
End

static Function/S GetDestinationIgorPath()

	string path = "tmpPath"
	NewPath/C/O $path, SpecialDirPath("Temporary", 0, 0, 1) + ":IgorNightlyDownloads"

	return path
End

Function ButtonProc_DownloadNightly(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	string url, filename, path

	switch(ba.eventCode)
		case 2: // mouse up
			url = GetDownloadLink()
			path = GetDestinationIgorPath()
			printf "Please wait while we download %s.\r", url
			filename = GetFileNameFromURL(url)
			URLRequest/O/P=$path/FILE=filename url=url
			PathInfo/SHOW $path
			break
	endswitch

	return 0
End

static Function AfterCompiledHook()

	string igorMajorVersion

	igorMajorVersion = StringByKey("IGORVERS", IgorInfo(0))[0]
	printf "Your Igor Pro %s version is too old to be usable for MIES.\r", igorMajorVersion
	Execute "OpenPanelWithDocumentationLink()"
End

#else

// stock igor
#include <Resize Controls>
#include <Resize Controls Panel>
#include <ZoomBrowser>
#include <FunctionProfiling>

#if IgorVersion() < 9.0
#include <HDF5 Browser>
#endif

// third party includes
#include "ACL_TabUtilities"
#include "ACL_UserdataEditor"
#include "Arduino_Sequencer_Vs1"

// JSON XOP
#include "json_functions"

// NWB for Igor Pro
#include "IPNWB_Include"

// ZeroMQ procedures
#include ":ZeroMQ:procedures:ZeroMQ_Interop"

// our includes
#include "MIES_AmplifierInteraction"
#include "MIES_AnalysisBrowser"
#include "MIES_AnalysisBrowser_LabNotebookTPStorageBrowser"
#include "MIES_AnalysisBrowser_SweepBrowser"
#include "MIES_AnalysisBrowser_SweepBrowser_Export"
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
#include "MIES_BrowserSettingsPanel"

#if defined(BACKGROUND_TASK_DEBUGGING)
#include "MIES_BackgroundWatchdog"
#endif

#include "MIES_Cache"
#include "MIES_CheckInstallation"
#include "MIES_Configuration"
#include "MIES_Constants"
#include "MIES_DAC-Hardware"
#include "MIES_DAEphys"
#include "MIES_DAEphys_Macro"
#include "MIES_DAEphys_GuiState"
#include "MIES_DataBrowser"
#include "MIES_DataBrowser_Macro"
#include "MIES_DataAcquisition"
#include "MIES_DataAcquisition_Single"
#include "MIES_DataAcquisition_Multi"
#include "MIES_DataConfigurator"
#include "MIES_Debugging"
#include "MIES_DebugPanel"
#include "MIES_Downsample"
#include "MIES_EnhancedWMRoutines"
#include "MIES_ExperimentDocumentation"
#include "MIES_ForeignFunctionInterface"
#include "MIES_GlobalStringAndVariableAccess"
#include "MIES_GuiPopupMenuExt"
#include "MIES_GuiUtilities"
#include "MIES_IgorHooks"
#include "MIES_Indexing"
#include "MIES_IVSCC"
#include "MIES_Labnotebook"
#include "MIES_Menu"
#include "MIES_MiesUtilities"
#include "MIES_NeuroDataWithoutBorders"
#include "MIES_OptimzedOverlapDistributedAcquisition"
#include "MIES_Oscilloscope"
#include "MIES_OverlaySweeps"
#include "MIES_PackageSettings"
#include "MIES_Pictures"
#include "MIES_PressureControl"
#include "MIES_ProgrammaticGuiControl"
#include "MIES_PulseAveraging"
#include "MIES_RepeatedAcquisition"
#include "MIES_SamplingInterval"
#include "MIES_Structures"
#include "MIES_SweepFormula"
#include "MIES_SweepSaving"
#include "MIES_ThreadedFIFOHandling"
#include "MIES_ThreadsafeUtilities"
#include "MIES_TestPulse"
#include "MIES_TestPulse_Single"
#include "MIES_TestPulse_Multi"
#include "MIES_TraceUserData"
#include "MIES_Utilities"
#include "MIES_WaveBuilder"
#include "MIES_WaveBuilderPanel"
#include "MIES_WaveBuilder_Macro"
#include "MIES_WaveDataFolderGetters"

#endif
