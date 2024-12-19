#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UTILSTEST_GUI

// Missing Tests for:
// IsWaveDisplayedOnGraph
// KillCursorInGraphs
// FindCursorInGraphs
// GetCursorXPositionAB
// RemoveAnnotationsFromGraph
// UniqueTraceName
// GetMarkerSkip
// KillWindows
// GetAllAxesWithOrientation
// SortAxisList
// GetPlotArea
// ParseColorSpec
// StoreCurrentPanelsResizeInfo
// GetNotebookCRC
// IsValidTraceLineStyle
// IsValidTraceDisplayMode
// UpdateInfoButtonHelp
// HorizExpandWithVisX
// EquallySpaceAxis
// EquallySpaceAxisPA
// RemoveFreeAxisFromGraph
// RemoveDrawLayers
// RemoveTracesFromGraph
// AddVersionToPanel
// HasPanelLatestVersion
// GetPanelVersion
// ToggleCheckBoxes
// EqualizeCheckBoxes

/// GetNumFromModifyStr
/// @{
/// Example string
///
/// AXTYPE:left;AXFLAG:/L=row0_col0_AD_0;CWAVE:trace1;UNITS:pA;CWAVEDF:root:MIES:HardwareDevices:ITC18USB:Device0:Data:X_3:;ISCAT:0;CATWAVE:;CATWAVEDF:;ISTFREE:0;MASTERAXIS:;HOOK:;
/// SETAXISFLAGS:/A=2/E=0/N=0;SETAXISCMD:SetAxis/A=2 row0_col0_AD_0;FONT:Arial;FONTSIZE:10;FONTSTYLE:0;RECREATION:catGap(x)=0.1;barGap(x)=0.1;grid(x)=0;log(x)=0;tick(x)=0;zero(x)=0;mirror(x)=0;
/// nticks(x)=5;font(x)="default";minor(x)=0;sep(x)=5;noLabel(x)=0;fSize(x)=0;fStyle(x)=0;highTrip(x)=10000;lowTrip(x)=0.1;logLabel(x)=3;lblMargin(x)=0;standoff(x)=0;axOffset(x)=0;axThick(x)=1;
/// gridRGB(x)=(24576,24576,65535);notation(x)=0;logTicks(x)=0;logHTrip(x)=10000;logLTrip(x)=0.0001;axRGB(x)=(0,0,0);tlblRGB(x)=(0,0,0);alblRGB(x)=(0,0,0);gridStyle(x)=0;gridHair(x)=2;zeroThick(x)=0;
/// lblPosMode(x)=1;lblPos(x)=0;lblLatPos(x)=0;lblRot(x)=0;lblLineSpacing(x)=0;tkLblRot(x)=0;useTSep(x)=0;ZisZ(x)=0;zapTZ(x)=0;zapLZ(x)=0;loglinear(x)=0;btLen(x)=0;btThick(x)=0;stLen(x)=0;stThick(x)=0;
/// ttLen(x)=0;ttThick(x)=0;ftLen(x)=0;ftThick(x)=0;tlOffset(x)=0;tlLatOffset(x)=0;freePos(x)=0;tickEnab(x)={-inf,inf};tickZap(x)={};axisEnab(x)={0.4478,0.8656};manTick(x)=0;userticks(x)=0;
/// dateInfo(x)={0,0,0};prescaleExp(x)=0;tickExp(x)=0;tickUnit(x)=1;linTkLabel(x)=0;axisOnTop(x)=0;axisEnab(x)={0.447778,0.865556};gridEnab(x)={0,1};mirrorPos(x)=1;
Function GNMS_Works1()

	string str = "abcd(efgh)={123.456}"

	CHECK_EQUAL_VAR(MIES_UTILS_GUI#GetNumFromModifyStr(str, "abcd", "{", 0), 123.456)
End

Function GNMS_Works2()

	string str = "abcd(efgh)=(123.456, 789.10)"

	CHECK_EQUAL_VAR(MIES_UTILS_GUI#GetNumFromModifyStr(str, "abcd", "(", 1), 789.10)
End

Function GNMS_Works3()

	string str = "abcdefgh(ijjk)=(1),efgh(ijk)=(2)"

	CHECK_EQUAL_VAR(MIES_UTILS_GUI#GetNumFromModifyStr(str, "efgh", "(", 0), 2)
End

/// @}

/// FormatTextWaveForLegend
/// @{

Function FTWWorks()

	string result, expected

	Make/FREE/T/N=(2, 3) input = num2istr(p) + num2istr(q) + PadString("", p + q, char2num("x"))

	result   = FormatTextWaveForLegend(input)
	expected = "00   01x   02xx \r10x  11xx  12xxx"

	CHECK_EQUAL_STR(result, expected)
End

/// @}

Function TestRemoveControls()

	string win

	NewPanel
	win = S_name

	Button abcd
	PopupMenu efgh

	CHECK_EQUAL_STR(ControlNameList(win), "abcd;efgh;")
	RemoveAllControls(win)
	CHECK_EQUAL_STR(ControlNameList(win), "")
End

Function TestRemoveDrawLayers()

	string win
	Display
	win = S_name

	DrawText/W=$win 47, 475, "my text"

	DrawAction/W=$win commands
	CHECK_GT_VAR(strlen(S_recreation), 0)
	RemoveAllDrawLayers(win)
	DrawAction/W=$win commands
	CHECK_EQUAL_VAR(strlen(S_recreation), 0)
End
