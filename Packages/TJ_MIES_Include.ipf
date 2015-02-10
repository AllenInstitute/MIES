#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion=6.3

// third party includes
#include "ACL_TabUtilities"
#include "ACL_UserdataEditor"
#include "Arduino_Sequencer_Vs1"
#include "FixScrolling"

// our includes
#include "TJ_MIES_AmplifierInteraction"
#include "TJ_MIES_BackgroundMD"
#include "TJ_MIES_BackgroundTimerMD"
#include "TJ_MIES_Constants"
#include "TJ_MIES_DataAcqITC"
#include "TJ_MIES_DataAcqMgmt"
#include "TJ_MIES_DataBrowser" menus=0
#include "TJ_MIES_DataConfiguratorITC"
#include "TJ_MIES_DataManagementNew"
#include "TJ_MIES_Debugging"
#include "TJ_MIES_Downsample" menus=0
#include "TJ_MIES_ExperimentDocumentation"
#include "TJ_MIES_GlobalStringAndVariableAccess"
#include "TJ_MIES_GuiUtilities"
#include "TJ_MIES_HardwareSetUp"
#include "TJ_MIES_Indexing"
#include "TJ_MIES_InitiateMIES"
#include "TJ_MIES_MiesUtilities"
#include "TJ_MIES_Oscilloscope"
#include "TJ_MIES_PanelITC"
#include "TJ_MIES_RepeatedAcquisition"
#include "TJ_MIES_TestPulse"
#include "TJ_MIES_TPBackgroundMD"
#include "TJ_MIES_Utilities"
#include "TJ_MIES_WaveBuilder"
#include "TJ_MIES_WaveBuilderPanel" menus=0
#include "TJ_MIES_WaveDataFolderGetters"
#include "TJ_MIES_PressureControl"



// Menu includes
#include "DR_MIES_Menu"
#include "DR_MIES_HDF5Ops"
