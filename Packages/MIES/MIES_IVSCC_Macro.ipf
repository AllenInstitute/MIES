#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_IVSCCM
#endif // AUTOMATED_TESTING

Window IVSCCControlPanel() : Panel
	PauseUpdate; Silent 1 // building window...
	NewPanel/K=1/W=(392, 734, 683, 925) as "IVSCC control panel"
	Button button_ivs_setup, pos={86.00, 19.00}, size={130.00, 30.00}, proc=IVS_ButtonProc_Setup, title="Setup DAEphys panel"
	Button button_runGigOhmSealQC, pos={48.00, 103.00}, size={190.00, 30.00}, proc=IVS_ButtonProc_GOhmSeal, title="Run GΩ seal check"
	Button button_runBaselineQC, pos={48.00, 61.00}, size={190.00, 30.00}, proc=IVS_ButtonProc_BaselineQC, title="Run baseline QC"
	Button button_runAccessResisQC, pos={48.00, 145.00}, size={190.00, 30.00}, proc=IVS_ButtonProc_AccessResist, title="Run access resistance QC check"
	SetWindow kwTopWin, userdata(Config_PanelType)="IVSCControlPanel"
EndMacro
