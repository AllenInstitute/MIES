#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_WBRMACRO
#endif // AUTOMATED_TESTING

/// @file MIES_WaverefBrowser_Macro.ipf
/// @brief __WBRMACRO__ Wavereference Wave Browser Macro

Window WaverefBrowser() : Panel
	PauseUpdate; Silent 1 // building window...
	NewPanel/K=1/W=(374, 170, 706, 602) as "Waveref Wave Browser"
	ListBox wrefList, pos={1.00, 1.00}, size={108.00, 432.00}, proc=WRB_ListBoxProc_WrefBrowser
	ListBox wrefList, userdata(ResizeControlsInfo)=A"!!,<7!!#66!!#@<!!#C=z!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	ListBox wrefList, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	ListBox wrefList, userdata(ResizeControlsInfo)+=A"zzz!!#?(FEDG<zzzzzzzzzzzzzz!!!"
	ListBox wrefList, mode=2, selRow=0
	Button ShowWrefWave, pos={111.00, 3.00}, size={50.00, 20.00}, proc=WRB_ButtonProc_WrefBrowserShow
	Button ShowWrefWave, title="Show"
	Button ShowWrefWave, userdata(ResizeControlsInfo)=A"!!,FC!!#8L!!#>V!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button ShowWrefWave, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button ShowWrefWave, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	Button BackWrefWave, pos={161.00, 3.00}, size={50.00, 20.00}, disable=2, proc=WRB_ButtonProc_WrefBrowserBack
	Button BackWrefWave, title="Back"
	Button BackWrefWave, userdata(ResizeControlsInfo)=A"!!,G1!!#8L!!#>V!!#<Xz!!#](Aon\"Qzzzzzzzzzzzzzz!!#](Aon\"Qzz"
	Button BackWrefWave, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzz!!#u:Du]k<zzzzzzzzzzz"
	Button BackWrefWave, userdata(ResizeControlsInfo)+=A"zzz!!#u:Duafnzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin, hook(cleanup)=WRB_BrowserWindowHook
	SetWindow kwTopWin, hook(ResizeControls)=ResizeControls#ResizeControlsHook
	SetWindow kwTopWin, userdata(ResizeControlsInfo)=A"!!*'\"z!!#B`!!#C=zzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzzzzzzzz"
	SetWindow kwTopWin, userdata(ResizeControlsInfo)+=A"zzzzzzzzzzzzzzzzzzz!!!"
	SetWindow kwTopWin, userdata(Config_PanelType)="WavereferenceBrowser"
	Execute/Q/Z "SetWindow kwTopWin sizeLimit={249,324,inf,inf}" // sizeLimit requires Igor 7 or later
	NewNotebook/F=1/N=WrefBrowserWaveInfo/W=(109, 23, 378, 358)/FG=($"", $"", FR, FB)/HOST=#/OPTS=12
	Notebook kwTopWin, defaultTab=10, autoSave=1, magnification=1, writeProtect=1, showRuler=0, rulerUnits=2
	Notebook kwTopWin, newRuler=Normal, justification=0, margins={0, 0, 145}, spacing={0, 0, 0}, tabs={}, rulerDefaults={"Arial", 11, 0, (0, 0, 0)}
	Notebook kwTopWin, zdata="GaqDU%ejN7!Z)uN!lU$_bQPl[Mu2-DL]iZ-,W[?i6\"=EJ6f#P.7,n?m$on`U$niG;M_Yre(nC3hMXtm%Mh-i8U<M+2\"pP&1'+ng"
	Notebook kwTopWin, zdataEnd=1
	RenameWindow #, WrefBrowserWaveInfo
	SetActiveSubwindow ##
EndMacro
