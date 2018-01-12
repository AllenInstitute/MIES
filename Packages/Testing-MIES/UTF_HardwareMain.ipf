#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "MIES_include"
#include "unit-testing"

#include "UTF_VeryBasicHardwareTests"
#include "UTF_TestingWithHardware"
#include "UTF_DAEphys"
#include "UTF_BasicHardwareTests"
#include "UTF_PatchSeqSubThreshold"
#include "UTF_PatchSeqSquarePulse"
#include "UTF_PatchSeqRheobase"

Function run()
//	DisableDebugOutput()
//	EnableDebugoutput()

	NWB_LoadAllStimsets(filename = GetFolder(FunctionPath("")) + "_2017_09_01_192934-compressed.nwb", overwrite = 1)
	KillDataFolder/Z root:WaveBuilder
	DuplicateDataFolder	root:MIES:WaveBuilder, root:WaveBuilder

	RunTest("UTF_VeryBasicHardwareTests.ipf;UTF_DAEphys.ipf", enableJU = 1)

	string list = ""
	list = AddListItem("DAQ_MD0_RA0_IDX0_LIDX0_BKG_0", list, ";", INF)
	list = AddListItem("Test_MD0_RA0_IDX0_LIDX0_BKG_0", list, ";", INF)
	list = AddListItem("DAQ_MD0_RA1_IDX0_LIDX0_BKG_0", list, ";", INF)
	list = AddListItem("Test_MD0_RA1_IDX0_LIDX0_BKG_0", list, ";", INF)
	list = AddListItem("DAQ_MD1_RA0_IDX0_LIDX0_BKG_1", list, ";", INF)
	list = AddListItem("Test_MD1_RA0_IDX0_LIDX0_BKG_1", list, ";", INF)
	list = AddListItem("DAQ_MD1_RA1_IDX0_LIDX0_BKG_1", list, ";", INF)
	list = AddListItem("Test_MD1_RA1_IDX0_LIDX0_BKG_1", list, ";", INF)
	list = AddListItem("DAQ_MD0_RA1_IDX1_LIDX0_BKG_0", list, ";", INF)
	list = AddListItem("Test_MD0_RA1_IDX1_LIDX0_BKG_0", list, ";", INF)
	list = AddListItem("DAQ_MD1_RA1_IDX1_LIDX0_BKG_1", list, ";", INF)
	list = AddListItem("Test_MD1_RA1_IDX1_LIDX0_BKG_1", list, ";", INF)
	list = AddListItem("DAQ_MD1_RA1_IDX1_LIDX1_BKG_1", list, ";", INF)
	list = AddListItem("Test_MD1_RA1_IDX1_LIDX1_BKG_1", list, ";", INF)
	list = AddListItem("DAQ_MD0_RA1_IDX1_LIDX1_BKG_0", list, ";", INF)
	list = AddListItem("Test_MD0_RA1_IDX1_LIDX1_BKG_0", list, ";", INF)
	list = AddListItem("DAQ_RepeatSets_1", list, ";", INF)
	list = AddListItem("Test_RepeatSets_1", list, ";", INF)
	list = AddListItem("DAQ_RepeatSets_2", list, ";", INF)
	list = AddListItem("Test_RepeatSets_2", list, ";", INF)
	list = AddListItem("DAQ_RepeatSets_3", list, ";", INF)
	list = AddListItem("Test_RepeatSets_3", list, ";", INF)

	list = AddListItem("DAQ_SkipSweepsDuringITI_SD", list, ";", INF)
	list = AddListItem("Test_SkipSweepsDuringITI_SD", list, ";", INF)
	list = AddListItem("DAQ_SkipSweepsDuringITI_MD", list, ";", INF)
	list = AddListItem("Test_SkipSweepsDuringITI_MD", list, ";", INF)

	list = AddListItem("DAQ_Abort_ITI_PressTP_SD", list, ";", INF)
	list = AddListItem("Test_Abort_ITI_PressTP_SD", list, ";", INF)
	list = AddListItem("DAQ_Abort_ITI_PressTP_MD", list, ";", INF)
	list = AddListItem("Test_Abort_ITI_PressTP_MD", list, ";", INF)
	list = AddListItem("DAQ_Abort_ITI_TP_A_PressTP_SD", list, ";", INF)
	list = AddListItem("Test_Abort_ITI_TP_A_PressTP_SD", list, ";", INF)
	list = AddListItem("DAQ_Abort_ITI_TP_A_PressTP_MD", list, ";", INF)
	list = AddListItem("Test_Abort_ITI_TP_A_PressTP_MD", list, ";", INF)

	list = AddListItem("DAQ_Abort_ITI_PressAcq_SD", list, ";", INF)
	list = AddListItem("Test_Abort_ITI_PressAcq_SD", list, ";", INF)
	list = AddListItem("DAQ_Abort_ITI_PressAcq_MD", list, ";", INF)
	list = AddListItem("Test_Abort_ITI_PressAcq_MD", list, ";", INF)
	list = AddListItem("DAQ_Abort_ITI_TP_A_PressAcq_SD", list, ";", INF)
	list = AddListItem("Test_Abort_ITI_TP_A_PressAcq_SD", list, ";", INF)
	list = AddListItem("DAQ_Abort_ITI_TP_A_PressAcq_MD", list, ";", INF)
	list = AddListItem("Test_Abort_ITI_TP_A_PressAcq_MD", list, ";", INF)

	list = AddListItem("PS_ST_Run1", list, ";", INF)
	list = AddListItem("PS_ST_Test1", list, ";", INF)
	list = AddListItem("PS_ST_Run2", list, ";", INF)
	list = AddListItem("PS_ST_Test2", list, ";", INF)
	list = AddListItem("PS_ST_Run3", list, ";", INF)
	list = AddListItem("PS_ST_Test3", list, ";", INF)
	list = AddListItem("PS_ST_Run4", list, ";", INF)
	list = AddListItem("PS_ST_Test4", list, ";", INF)
	list = AddListItem("PS_ST_Run5", list, ";", INF)
	list = AddListItem("PS_ST_Test5", list, ";", INF)
	list = AddListItem("PS_ST_Run6", list, ";", INF)
	list = AddListItem("PS_ST_Test6", list, ";", INF)
	list = AddListItem("PS_ST_Run7", list, ";", INF)
	list = AddListItem("PS_ST_Test7", list, ";", INF)

	list = AddListItem("PS_SP_Run1", list, ";", INF)
	list = AddListItem("PS_SP_Test1", list, ";", INF)
	list = AddListItem("PS_SP_Run2", list, ";", INF)
	list = AddListItem("PS_SP_Test2", list, ";", INF)
	list = AddListItem("PS_SP_Run3", list, ";", INF)
	list = AddListItem("PS_SP_Test3", list, ";", INF)
	list = AddListItem("PS_SP_Run4", list, ";", INF)
	list = AddListItem("PS_SP_Test4", list, ";", INF)
	list = AddListItem("PS_SP_Run5", list, ";", INF)
	list = AddListItem("PS_SP_Test5", list, ";", INF)

	list = AddListItem("PS_RB_Run1", list, ";", INF)
	list = AddListItem("PS_RB_Test1", list, ";", INF)
	list = AddListItem("PS_RB_Run2", list, ";", INF)
	list = AddListItem("PS_RB_Test2", list, ";", INF)
	list = AddListItem("PS_RB_Run3", list, ";", INF)
	list = AddListItem("PS_RB_Test3", list, ";", INF)
	list = AddListItem("PS_RB_Run4", list, ";", INF)
	list = AddListItem("PS_RB_Test4", list, ";", INF)
	list = AddListItem("PS_RB_Run5", list, ";", INF)
	list = AddListItem("PS_RB_Test5", list, ";", INF)
	list = AddListItem("PS_RB_Run6", list, ";", INF)
	list = AddListItem("PS_RB_Test6", list, ";", INF)

	// initialize everything
	CtrlNamedBackGround DAQWatchdog, stop, period=120, proc=WaitUntilDAQDone_IGNORE
	Initialize_IGNORE()
	SetupTestCases_IGNORE(list)
	ExecuteNextTestCase_IGNORE()
End
