#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#if (IgorVersion() >= 8.00)
#pragma IgorVersion=8.02
#else
#pragma IgorVersion=7.08
#endif

/// @file MIES_Include.ipf
/// @brief Main include

// stock igor
#include <Resize Controls>
#include <ZoomBrowser>
#include <FunctionProfiling>
#include <Readback ModifyStr>
#include <HDF5 Browser>

// third party includes
#include "ACL_TabUtilities"
#include "ACL_UserdataEditor"
#include "Arduino_Sequencer_Vs1"

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
#include "MIES_AnalysisMaster"
#include "MIES_ArtefactRemoval"
#include "MIES_AsynchronousData"
#include "MIES_Blowout"
#include "MIES_BrowserSettingsPanel"
#include "MIES_BackgroundWatchdog"
#include "MIES_Cache"
#include "MIES_CheckInstallation"
#include "MIES_Constants"
#include "MIES_DAC-Hardware"
#include "MIES_DAEphys"
#include "MIES_DAEphys_Macro"
#include "MIES_DAEphys_GuiState"
#include "MIES_DataBrowser"
#include "MIES_DataAcquisition"
#include "MIES_DataAcquisition_Single"
#include "MIES_DataAcquisition_Multi"
#include "MIES_DataConfiguratorITC"
#include "MIES_Debugging"
#include "MIES_DebugPanel"
#include "MIES_Downsample"
#include "MIES_EnhancedWMRoutines"
#include "MIES_EventDetectionCode"
#include "MIES_ExperimentConfig"
#include "MIES_ExperimentDocumentation"
#include "MIES_ForeignFunctionInterface"
#include "MIES_GlobalStringAndVariableAccess"
#include "MIES_GuiUtilities"
#include "MIES_HDF5Ops"
#include "MIES_IgorHooks"
#include "MIES_Indexing"
#include "MIES_Menu"
#include "MIES_MiesUtilities"
#include "MIES_NeuroDataWithoutBorders"
#include "MIES_OptimzedOverlapDistributedAcquisition"
#include "MIES_Oscilloscope"
#include "MIES_OverlaySweeps"
#include "MIES_PressureControl"
#include "MIES_ProgrammaticGuiControl"
#include "MIES_PulseAveraging"
#include "MIES_RepeatedAcquisition"
#include "MIES_SamplingInterval"
#include "MIES_Structures"
#include "MIES_SweepSaving"
#include "MIES_ThreadedFIFOHandling"
#include "MIES_ThreadsafeUtilities"
#include "MIES_TangoInteract"
#include "MIES_TestPulse"
#include "MIES_TestPulse_Single"
#include "MIES_TestPulse_Multi"
#include "MIES_Utilities"
#include "MIES_WaveBuilder"
#include "MIES_WaveBuilderPanel"
#include "MIES_WaveDataFolderGetters"
