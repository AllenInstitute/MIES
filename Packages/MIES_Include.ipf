#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

// Igor Pro nightly installation:
// - Download from https://www.byte-physics.de/Downloads/WinIgor8_06MAY2020.zip
// - Close Igor Pro 8
// - Extract the contents into C:\Program Files\WaveMetrics\Igor Pro 8 Folder (overwriting existing files, requires Administrator access)
// - Restart Igor Pro 8
//
// By ignoring the error and *commenting out* the below check you will certainly break MIES.
#if (NumberByKey("BUILD", IgorInfo(0)) < 35712)
#define *** Too old Igor Pro 8 version, click "Edit procedure" for instructions
#pragma IgorVersion=8.04
#endif

#if IgorVersion() >= 9.0
#if (NumberByKey("BUILD", IgorInfo(0)) < 36145)
#define *** Too old Igor Pro 9 version, click "Edit procedure" for instructions
#pragma IgorVersion=9.00
#endif
#endif

/// @file MIES_Include.ipf
/// @brief Main include

// stock igor
#include <Resize Controls>
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
#include "MIES_AnalysisFunctionPrototypes"
#include "MIES_AnalysisFunctions"
#include "MIES_ArtefactRemoval"
#include "MIES_AsynchronousData"
#include "MIES_Async"
#include "MIES_Blowout"
#include "MIES_BrowserSettingsPanel"
#include "MIES_BackgroundWatchdog"
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
#include "MIES_DataConfiguratorITC"
#include "MIES_Debugging"
#include "MIES_DebugPanel"
#include "MIES_Downsample"
#include "MIES_EnhancedWMRoutines"
#include "MIES_ExperimentConfig"
#include "MIES_ExperimentDocumentation"
#include "MIES_ForeignFunctionInterface"
#include "MIES_GlobalStringAndVariableAccess"
#include "MIES_GuiPopupMenuExt"
#include "MIES_GuiUtilities"
#include "MIES_IgorHooks"
#include "MIES_Indexing"
#include "MIES_IVSCC"
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
