#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma ModuleName=ConfigurationTest

// If this moves to an independend test, uncomment the following line
//#include "unit-testing"

/// @file UTF_ConfigurationTest.ipf
/// @brief __CONFIG_Test__ This file holds the tests for the Configuration saving/loading

static StrConstant REF_CONFIG_FILE = "ConfigurationTest.txt"
static StrConstant REF_CONFIG_FILE_RELEVANT = "ConfigurationTest_Relevant.txt"
static StrConstant REF_TMP1_CONFIG_FILE = "ConfigurationTest_temp1.txt"
static StrConstant REF_TMP2_CONFIG_FILE = "ConfigurationTest_temp2.txt"
static StrConstant REF_DUP1_CONFIG_FILE = "ConfigurationTest_DupCheck1.txt"
static StrConstant REF_DUP2_CONFIG_FILE = "ConfigurationTest_DupCheck2.txt"
static Constant CHECKBOX_CLICKED = 1
static Constant RADIO3_CLICKED = 2

/// @brief Open a fresh template panel
static Function TEST_CASE_BEGIN_OVERRIDE(testCase)
	string testCase

	Execute "MainPanel()"
	variable/G priorityFlag = 0
End

/// @brief Cleans up failing tests
static Function TEST_CASE_END_OVERRIDE(testCase)
	string testCase

	KillWindow/Z MainPanel
End

Window MainPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1113,368,1711,766)
	ShowTools/A
	SetDrawLayer UserBack
	Button button,pos={0.00,0.00},size={50.00,20.00},title="button"
	Button button,userdata(Config_PushButtonOnRestore)=  "1"
	CheckBox CheckBox,pos={60.00,0.00},size={68.00,15.00},title="CheckBox",value= 1
	CheckBox CheckBox,userdata(Config_RestorePriority)=  "10"
	CheckBox CheckBox,userdata(Config_NiceName)=  "Check Me"
	CheckBox CheckBox,userdata(Config_JSONPath)=  "The real important controls"
	CheckBox CheckBox proc=TCONF_CheckProc
	PopupMenu popup,pos={138.00,0.00},size={77.00,19.00},title="popup"
	PopupMenu popup,mode=1,popvalue="Yes",value= #"\"Yes;No;Maybe\""
	ValDisplay valdisp,pos={225.00,0.00},size={93.00,17.00},title="valdisp"
	ValDisplay valdisp,limits={0,0,0},barmisc={0,1000},value=1337
	ValDisplay valdisp,userdata(Config_RestorePriority)=  "10"
	SetVariable setvar,pos={328.00,0.00},size={137.00,18.00},title="setvar"
	Slider slider,pos={0.00,25.00},size={589.00,56.00},labelBack=(65535,49151,55704)
	Slider slider,fColor=(19729,1,39321)
	Slider slider,userdata(Config_GroupPath)="level1;level2;"
	Slider slider,limits={0,100,1},value= 25,side= 2,vert= 0,ticks= 7,thumbColor= (65535,0,0)
	TabControl tab,pos={1.00,86.00},size={266.00,25.00}
	TabControl tab,labelBack=(49151,65535,49151),fColor=(1,3,39321)
	TabControl tab,tabLabel(0)="Tab 0",tabLabel(1)="Tab 1",tabLabel(2)="Tab 2"
	TabControl tab,tabLabel(3)="Tab 3",tabLabel(4)="Tab 4",value= 3
	TitleBox titlebox,pos={4.00,113.00},size={47.00,23.00},title="titlebox"
	TitleBox titlebox,labelBack=(49151,65535,49151)
	GroupBox groupbox,pos={61.00,113.00},size={131.00,73.00},title="groupbox"
	GroupBox groupbox,labelBack=(65535,65534,49151)
	ListBox listbox,pos={202.00,113.00},size={159.00,73.00}
	Chart chart,pos={371.00,113.00},size={108.00,74.00}
	CustomControl customcontrol,pos={489.00,113.00},size={102.00,74.00}
	CheckBox Radio1,pos={288.00,206.00},size={52.00,15.00},title="Radio1"
	CheckBox Radio1,value= 0,mode=1
	CheckBox Radio2,pos={290.00,232.00},size={52.00,15.00},title="Radio2"
	CheckBox Radio2,value= 0,mode=1
	CheckBox Radio3,pos={290.00,259.00},size={52.00,15.00},title="Radio3"
	CheckBox Radio3,value= 1,mode=1
	CheckBox Radio3 proc=TCONF_CheckProc
	NewPanel/W=(11,203,273,387)/HOST=# 
	ModifyPanel cbRGB=(32768,40777,65535)
	CheckBox checkbox1,pos={10.00,10.00},size={70.00,15.00},title="TrueColor"
	CheckBox checkbox1,userdata(ControlArray)=  "ctrlArray"
	CheckBox checkbox1,userdata(ControlArrayIndex)=  "0",fStyle=1,fColor=(1,3,39321)
	CheckBox checkbox1,value= 0
	CheckBox checkbox2,pos={10.00,36.00},size={81.00,15.00},title="Accelerator"
	CheckBox checkbox2,userdata(ControlArray)=  "ctrlArray"
	CheckBox checkbox2,userdata(ControlArrayIndex)=  "1",fStyle=1,fColor=(1,3,39321)
	CheckBox checkbox2,value= 0
	CheckBox checkbox3,pos={11.00,63.00},size={78.00,15.00},title="superscalar"
	CheckBox checkbox3,userdata(ControlArray)=  "ctrlArray"
	CheckBox checkbox3,userdata(ControlArrayIndex)=  "2",fStyle=1,fColor=(1,3,39321)
	CheckBox checkbox3,value= 0
	CheckBox checkbox4,pos={11.00,91.00},size={106.00,15.00},title="next generation"
	CheckBox checkbox4,userdata(ControlArray)=  "ctrlArray"
	CheckBox checkbox4,userdata(ControlArrayIndex)=  "3",fStyle=1,fColor=(1,3,39321)
	CheckBox checkbox4,value= 0
	Button button1,pos={18.00,125.00},size={104.00,55.00},title="Select Best"
	Button button1,userdata(ControlArray)=  "ctrlArray"
	Button button1,userdata(ControlArrayIndex)=  "4",labelBack=(65535,0,0)
	Button button1,font="Trebuchet MS",fSize=18,fStyle=1,fColor=(65535,0,0)
	Button button1,valueColor=(65535,65535,0)
	PopupMenu popup,pos={135.00,14.00},size={116.00,19.00},title="Computer"
	PopupMenu popup,userdata(ControlArray)=  "ctrlArray"
	PopupMenu popup,userdata(ControlArrayIndex)=  "6",fStyle=1,fColor=(1,3,39321)
	PopupMenu popup,mode=1,popvalue="Amiga",value= #"\"Amiga;Atari ST\""
	RenameWindow #,SubPanel
	SetActiveSubwindow ##
	SetWindow kwTopWin,userdata(Config_RadioCouplingFunc)=  "ConfigurationTest#TCONF_RadioCoupling"
EndMacro

/// @brief RadioCoupling function for MainPanel, referred checkboxes are not actually implemented coupled.
Function/WAVE TCONF_RadioCoupling()
	
	Make/FREE/T/N=1 w
	w[0] = "Radio1;Radio2;Radio3;"
	return w
End

/// @brief CheckBox proc helper to check Config_RestorePriority
Function TCONF_CheckProc(cba) : CheckBoxControl
	struct WMCheckboxAction &cba

	string ctrlName

	switch( cba.eventCode )
		case 2: // mouse up
			NVAR priorityFlag
			ctrlName = cba.ctrlName
			if(!CmpStr(ctrlName, "CheckBox"))
				priorityFlag = CHECKBOX_CLICKED
			elseif(!CmpStr(ctrlName, "Radio3"))
				priorityFlag = RADIO3_CLICKED
			endif
			break
	endswitch

	return 0
End

static Function TCONF_ChangeGUIValues_IGNORE()
	CheckBox CheckBox value=0
	PopupMenu popup popvalue="Maybe"
	ValDisplay valdisp value= _NUM:0
	TabControl tab value=1
	CheckBox Radio3 value=0
	SetVariable setvar value=setvarTest
	CheckBox checkbox3 win=#SubPanel, value=0
	PopupMenu popup win=#SubPanel, popvalue="Atari ST"
End

/// @brief Saves a json to a text file in home path
static Function TCONF_SaveJSON(jsonID, fName)
	variable jsonID
	string fName

	string out
	variable fnum

	out = JSON_Dump(jsonID, indent = 2)
	SaveTextFile(out, fName)
End

/// @brief helper function to compare two text files
static Function TCONF_CompareTextFiles(fName1, fName2)
	string fName1, fName2

	string s1, s2

	[s1, fName1] = LoadTextFile(fName1)
	[s2, fName2] = LoadTextFile(fName2)

	Make/FREE/T w1 = { TrimString(s1) }
	Make/FREE/T w2 = { TrimString(s2) }

	CHECK_EQUAL_WAVES(w1, w2)
End

/// @brief Save Test Panel and check against reference template
static Function TCONF_Save()

	string fName1 = "ConfigurationTest_compare1.txt"
	
	CONF_SaveWindow(fName1)

	TCONF_CompareTextFiles(fName1, REF_CONFIG_FILE)
End

/// @brief Change Test Panel and Load, then save and check against reference template
static Function TCONF_Load()

	string fName1 = "ConfigurationTest_compare1.txt"
	
	variable/G setvarTest
	
	TCONF_ChangeGUIValues_IGNORE()
	
	CONF_RestoreWindow(REF_CONFIG_FILE)

	NVAR priorityFlag
	CHECK_EQUAL_VAR(priorityFlag, RADIO3_CLICKED)

	CONF_SaveWindow(fName1)

	TCONF_CompareTextFiles(fName1, REF_CONFIG_FILE)
End


/// @brief Save Window with all relevant mask bits - Change Window - Restore it, compare to initial state
static Function TCONF_AllStates()

	string wName
	variable jsonID, jsonID2, saveMask

	wName = GetMainWindow(GetCurrentWindow())
	saveMask = EXPCONFIG_SAVE_VALUE | EXPCONFIG_SAVE_POSITION | EXPCONFIG_SAVE_USERDATA | EXPCONFIG_SAVE_DISABLED | EXPCONFIG_SAVE_CTRLTYPE
	ModifyControl valdisp win=$wName, userdata(testdata)="testdata"
	ModifyControl valdisp win=$wName, userdata(testdatabase64)="\u0000"
	jsonID = CONF_AllWindowsToJSON(wName, saveMask)

	ModifyControl valdisp win=$wName, align=1, size={100, 100}, pos={10, 10}
	DisableControl(wName, "valdisp")
	CONF_JSONToWindow(wName, saveMask, jsonID)
	jsonID2 = CONF_AllWindowsToJSON(wName, saveMask)
	TCONF_SaveJSON(jsonID, REF_TMP1_CONFIG_FILE)
	TCONF_SaveJSON(jsonID2, REF_TMP2_CONFIG_FILE)
	TCONF_CompareTextFiles(REF_TMP2_CONFIG_FILE, REF_TMP1_CONFIG_FILE)
End

/// @brief RoundTrip with Save Only Relevant, compared to initial template file
static Function TCONF_RelevantValues()

	string wName
	variable jsonID, jsonID2, saveMask

	wName = GetMainWindow(GetCurrentWindow())
	saveMask = EXPCONFIG_SAVE_ONLY_RELEVANT | EXPCONFIG_SAVE_VALUE
	jsonID = CONF_AllWindowsToJSON(wName, saveMask)

	TCONF_ChangeGUIValues_IGNORE()

	CONF_JSONToWindow(wName, saveMask, jsonID)
	jsonID2 = CONF_AllWindowsToJSON(wName, saveMask)
	TCONF_SaveJSON(jsonID, REF_TMP1_CONFIG_FILE)
	TCONF_SaveJSON(jsonID2, REF_TMP2_CONFIG_FILE)
	TCONF_CompareTextFiles(REF_TMP2_CONFIG_FILE, REF_CONFIG_FILE_RELEVANT)
End

/// @brief Check for Duplicate NiceNames on Save
static Function TCONF_DupNiceName()

	string wName

	wName = GetMainWindow(GetCurrentWindow())
	CheckBox CheckBox win=$wName, userdata(Config_NiceName)=  "BUTTON"
	try
		CONF_SaveWindow(REF_TMP1_CONFIG_FILE)
		FAIL()
	catch
		PASS()
	endtry
End

/// @brief Check for Reserved NiceNames - CtrlGroup Suffix on Save
static Function TCONF_ReservedNiceName()

	string wName

	wName = GetMainWindow(GetCurrentWindow())
	CheckBox CheckBox win=$wName, userdata(Config_NiceName)=  "BUTTON ControlGroup"
	try
		CONF_SaveWindow(REF_TMP1_CONFIG_FILE)
		FAIL()
	catch
		PASS()
	endtry
End

/// @brief Check for Duplicate CtrlArrayNames on Save
static Function TCONF_DupCtrlArrayName()

	string wName

	wName = GetMainWindow(GetCurrentWindow())
	CheckBox CheckBox win=$wName, userdata(ControlArray)=  "BUTTON"
	try
		CONF_SaveWindow(REF_TMP1_CONFIG_FILE)
		FAIL()
	catch
		PASS()
	endtry
End

/// @brief Check for Duplicate NiceNames on Restore
static Function TCONF_DupNiceNameRestore()

	try
		CONF_RestoreWindow(REF_DUP1_CONFIG_FILE)
		FAIL()
	catch
		PASS()
	endtry
End

/// @brief Check for Duplicate CtrlArrayNames on Restore
static Function TCONF_DupCtrlArrayNameRestore()

	try
		CONF_RestoreWindow(REF_DUP2_CONFIG_FILE)
		FAIL()
	catch
		PASS()
	endtry
End
