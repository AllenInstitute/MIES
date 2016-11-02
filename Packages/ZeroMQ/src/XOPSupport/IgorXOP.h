// IgorXOP.h -- Miscellaneous equates for interfacing XOP to Igor.

/*	These equates come from .h files used in compiling Igor and include
	various information that an XOP might need in communicating with Igor.
*/

#pragma pack(2)	// All structures passed between Igor and XOP are two-byte aligned.

typedef void* IgorWindowRef;				// Reference to an Igor-created or XOP-created window
typedef void* IgorContainerRef;				// Reference to an Igor-created or XOP-created container

// From WMMouseEvents.h

enum {
	kWMMouseDown=1,
	kWMMouseUp=2,
	kWMMouseDoubleClick=3,
	kWMMouseMove=4
};

enum {
	kWMMouseButtonNone=0,					// For kWMMouseMove
	kWMMouseButtonLeft=1,
	kWMMouseButtonMiddle=2,
	kWMMouseButtonRight=3,
	kWMMouseButtonX1=4,
	kWMMouseButtonX2=5
};

struct WMMouseEventRecord {
	short eventType;						// kWMMouseDown, kWMMouseUp, kWMMouseDoubleClick, kWMouseMove
	char reserved1[16];						// Reserved for future use

	// Button information
	char clickedButton;						// Which button caused the click - kWMMouseButtonNone, kWMMouseButtonLeft, kWMMouseButtonMiddle, kWMMouseButtonRight, kWMMouseButtonX1, kWMMouseButtonX2
	char leftButtonPressed;
	char middleButtonPressed;
	char rightButtonPressed;
	char xButton1Pressed;
	char xButton2Pressed;
	char reserved2[8];
	
	// Global coordinates
	UInt32 globalX;
	UInt32 globalY;
	char reserved3[16];						// Reserved for future use

	// Widget-relative coordinates
	UInt32 localX;
	UInt32 localY;
	char reserved4[16];						// Reserved for future use

	char reserved5[16];						// Reserved for future use
	
	UInt32 when;							// When click occurred in ticks (60th of a second)

	// Modifier key information
	char shiftKeyPressed;
	char cmdKeyPressed;						// Ctrl key on Windows
	char optionKeyPressed;					// Alt key on Windows
	char macControlKeyPressed;				// Control key on Macintosh, not used on Windows

	char reserved6[16];						// Reserved for future use
};
typedef struct WMMouseEventRecord WMMouseEventRecord;
typedef struct WMMouseEventRecord* WMMouseEventRecordPtr;

// From WMKeyboardEvents.h

enum WMKeyEventType {
	kWMKeydownEvent=1,
	kWMKeyupEvent=2,
};

enum WMKeyCode {
	kWMKeyCodeNone=0,
	
	// Function keys
	kWMKeyCodeF1=1,
	kWMKeyCodeF2=2,
	kWMKeyCodeF3=3,
	kWMKeyCodeF4=4,
	kWMKeyCodeF5=5,
	kWMKeyCodeF6=6,
	kWMKeyCodeF7=7,
	kWMKeyCodeF8=8,
	kWMKeyCodeF9=9,
	kWMKeyCodeF10=10,
	kWMKeyCodeF11=11,
	kWMKeyCodeF12=12,
	kWMKeyCodeF13=13,
	kWMKeyCodeF14=14,
	kWMKeyCodeF15=15,
	kWMKeyCodeF16=16,
	kWMKeyCodeF17=17,
	kWMKeyCodeF18=18,
	kWMKeyCodeF19=19,
	kWMKeyCodeF20=20,
	kWMKeyCodeF21=21,
	kWMKeyCodeF22=22,
	kWMKeyCodeF23=23,
	kWMKeyCodeF24=24,
	kWMKeyCodeF25=25,
	kWMKeyCodeF26=26,
	kWMKeyCodeF27=27,
	kWMKeyCodeF28=28,
	kWMKeyCodeF29=29,
	kWMKeyCodeF30=30,
	kWMKeyCodeF31=31,
	kWMKeyCodeF32=32,
	kWMKeyCodeF33=33,
	kWMKeyCodeF34=34,
	kWMKeyCodeF35=35,
	kWMKeyCodeF36=36,
	kWMKeyCodeF37=37,
	kWMKeyCodeF38=38,
	kWMKeyCodeF39=39,

	// Navigation keys
	kWMKeyCodeLeftArrow=100,
	kWMKeyCodeRightArrow=101,
	kWMKeyCodeUpArrow=102,
	kWMKeyCodeDownArrow=103,
	kWMKeyCodePageUp=104,
	kWMKeyCodePageDown=105,
	kWMKeyCodeHome=106,
	kWMKeyCodeEnd=107,

	// Control keys
	kWMKeyCodeReturn=200,
	kWMKeyCodeEnter=201,
	kWMKeyCodeTab=202,
	kWMKeyCodeBackTab=203,					// Qt produces this when the user presses shift and tab
	kWMKeyCodeEscape=204,
	
	// Editing keys
	kWMKeyCodeDelete=300,					// Also called backspace
	kWMKeyCodeForwardDelete=301,
	kWMKeyCodeClear=302,
	kWMKeyCodeInsert=303,					// Ins key on Windows

	// Miscellaneous keys
	kWMKeyCodeHelp=400,
	kWMKeyCodeBreak=401,					// Pause/Break key
	kWMKeyCodePrint=402,
	kWMKeyCodeSysReq=403,
	
	/*	Non-producing keys - pressing these keys does not send a keyPressEvent to Igor.
		They are either intercepted by the OS or used in conjunction with producing keys.
	*/
	kWMKeyCodeShift=500,
	kWMKeyCodeCommandOrCtrl=501,			// Command key on Macintosh, Ctrl key on Window
	kWMKeyCodeMacControl=502,				// Control key on Macintosh only
	kWMKeyCodeWindows=503,					// Windows key on Windows only
	kWMKeyCodeAlt=504,
	kWMKeyCodeAltGr=505,
	kWMKeyCodeCapsLock=506,
	kWMKeyCodeNumLock=507,
	kWMKeyCodeScrollLock=508,
};

#define KEY_EVENT_BUFFER_SIZE 64	// We can receive many characters in one event when Asian text is entered via IME
struct WMKeyboardEventRecord {
	short eventType;						// kWMKeydownEvent or kWMKeyupEvent

	char reserved0[16];						// Reserved for future use

	/*	On Windows Ctrl-<key> and Alt-<key> are intercepted by the system and Meta-<key> is
		usually intercepted by the OS so you will not see events for these combinations.
		On Macintosh Cmd-<key> is intercepted by the system so you will not see events
		for that combinations.
	*/
	char shiftKeyPressed;
	char cmdKeyPressed;						// Ctrl key on Windows
	char optionKeyPressed;					// Alt key on Windows
	char macControlKeyPressed;				// Control key on Macintosh, not used on Windows
	char keypadKeyPressed;					// Set if keypad key or arrow key is pressed
	char modeSwitchKeyPressed;				// X11 only - set if mode switch key is pressed

	char reserved1[16];						// Reserved for future use

	UInt16 specialKeyCode;					// WMKeyCode for special keys - e.g., arrow keys, navigation keys, control keys, function keys

	char reserved2[32];						// Reserved for future use

	char text[KEY_EVENT_BUFFER_SIZE];		// UTF-8 null-terminated C string - "" for special keys
};
typedef struct WMKeyboardEventRecord WMKeyboardEventRecord;
typedef struct WMKeyboardEventRecord* WMKeyboardEventRecordPtr;

// Mouse cursor codes used with SetXOPContainerMouseCursor
enum IgorMouseCursorCode {
	kFirstPublicCursor = 0,
	kArrowCursor = 0,
	kIBeamCursor,
	kWatchCursor,
	kCrosshairCursor,
	kLeftUpArrowsCursor,
	kLeftRightArrowsCursor,
	kUpDownArrowsCursor,
	kRightDownArrowsCursor,
	kLeftRightUpDownArrowsCursor,
	kContextualMenuCursor,				// Indicates that left-clicking will display a contextual menu
	kLeftDownArrowsCursor,
	kUpRightArrowsCursor,
	kSmallCrossCursor,					// Used when in drawing layers when a click creates or extends a drawing object
	kHandCursor,						// Used for dragging annotations
	kSquareWithXCursor,					// Used to represent graph cursor B when dragging that cursor
	kCircleWithCrossCursor,				// Used to represent graph cursor A when dragging that cursor
	kAttachTagCursor,					// Used for dragging tag annotations to attach to another wave point
	kQuestionMarkCursor,
	kEditPointCursor,					// Used for dragging points during wave editing
	kDeletePointCursor,					// Used for zapping points during wave editing
	kDrawPointCursor,					// Used for drawing points during wave editing
	kDragEdgeCursor,					// Used for dragging the edge of a polygon in drawing mode
	kDragVerticalAxisCursor,			// Used for dragging vertical axes and similar dragging
	kDragHorizontalAxisCursor,			// Used for dragging horizontal axes and similar dragging
	kClickCursor,						// Used with Sleep/B operation
	kPlacePictureCursor,				// Used for placing pictures in page layout windows
	kHelpBalloonCursor,
	kFingerCursor,						// Used when the mouse is over a help link or notebook action
	kFourArrowsCursor,
	kLeftRightArrowsCursor2,
	kUpDownArrowsCursor2,
	kNorthwestSoutheastArrowsCursor,
	kNortheastSouthwestArrowsCursor,
	kLastPublicCursor = kNortheastSouthwestArrowsCursor,
};

// Miscellaneous
typedef Handle TUStuffHandle;
typedef void** waveHndl;			// Was Handle in Igor Pro 6 and before. In Igor Pro 7 and after wave handles are not regular Handles.
typedef Handle DataFolderHandle;


// From DataFolderBits.h. Used by Data Browser to determine events of interest to it.
#define kDFCB_NewChildFolder	1
#define kDFCB_KillChildFolder	2
#define kDFCB_RenameChildFolder	4
#define kDFCB_NewWave			8
#define kDFCB_KillWave			0x10
#define kDFCB_RenameWave		0x20
#define kDFCB_NewVariable		0x40
#define kDFCB_KillVariable		0x80
#define kDFCB_RenameVariable	0x100
#define kDFCB_NewString			0x200
#define kDFCB_KillString		0x400
#define kDFCB_RenameString		0x800
#define kDFCD_LockWave			0x1000					// AG27MAY03, Igor Pro 5


// From WinGenMacs.c. Used for DoWindowRecreationDialog callback.
enum CloseWinAction {
	kCloseWinCancel = 0,
	kCloseWinSave = 1,
	kCloseWinReplace = 2,
	kCloseWinNoSave = 3
};


// From Igor.h
#ifndef NIL
	#define NIL 0L
#endif
#ifndef FALSE				// Conditional compilation is needed because Metrowerks
	#define FALSE 0			// defines TRUE and FALSE in their MacHeaders.c.
#endif
#ifndef TRUE
	#define TRUE -1
#endif

#define MAXCMDLEN 400		// HR, 10/2/93 -- changed from 200 to 400 for Igor 2.0.

#define WAVE_OBJECT 1
#define WAVEARRAY_OBJECT 2
#define VAR_OBJECT 3
#define STR_OBJECT 4
#define STRUCT_OBJECT 5
#define XOPTARGWIN_OBJECT 5		// HR, 980714. Igor Pro 3.13B03.
#define GRAPH_OBJECT 6
#define TABLE_OBJECT 7
#define LAYOUT_OBJECT 8
#define PANEL_OBJECT 9			// HR, 10/2/93. Igor Pro 2.0.
#define NOTEBOOK_OBJECT 10
#define DATAFOLDER_OBJECT 11	// HR, 7/7/95. Igor Pro 3.0.
#define PATH_OBJECT 12			// HR, 7/28/95. Igor Pro 3.0. Symbolic path.
#define PICT_OBJECT 13			// HR, 7/28/95. Igor Pro 3.0. Picture.
#define ANNOTATION_OBJECT 14	// JP, 4/24/98. Igor Pro 3.13.
#define CONTROL_OBJECT 15		// JP, 4/24/98. Igor Pro 3.13.

// #defines for identifying windows.
#define GRAF_MASK 1
#define SS_MASK 2
#define PL_MASK 4
#define PICT_MASK 8
#define MW_MASK 16
#define TEXT_MASK 32
#define PANEL_MASK 64
#define PROC_MASK 128
#define MOVIE_MASK 256
#define HELP_MASK 512
#define XOP_MASK 2048				// HR, 2014-03-17: Added for XOP non-target windows.
#define XOP_TARGET_MASK 4096		// HR, 980706: Added for XOP target windows.
#define PLPAGE_MASK 8192			// A page of a page layout window
#define GIZMO_MASK 65536
#define ALL_MASK -1
#define ALL_TARGET_WINDOWS_MASK (GRAF_MASK | SS_MASK | PL_MASK | MW_MASK | PANEL_MASK | XOP_TARGET_MASK | GIZMO_MASK)
#define ALLOWED_HOST_MASK (PANEL_MASK | GRAF_MASK | PL_MASK | PLPAGE_MASK)	// These can host subwindows

#define CMDWIN 1
#define WMDIALOGWIN 2				// HR, 11/19/92 -- was 10.
#define OLD_PROCWIN 2				// HR, 11/19/92 -- PROCWIN is now 10.
#define GRAFWIN 3
#define SSWIN 4
#define PLWIN 5
#define PICTWIN 6
#define MWWIN 7						// Notebook window (may be plain or formatted text).
#define TEXTWIN 8
#define PANELWIN 9
#define PROCWIN 10					// HR, 11/19/92 -- was 2.
#define MOVIEWIN 11
#define HELPWIN 12
#define HELPDLOGWIN 13
#define XOPWIN 14
#define XOPTARGWIN 15				// To group all XOP target windows together in the windows menu.
#define PLPAGEID 16					// Page Layout page
#define GIZMOWIN 19

/*	Name space codes.
	For use with UniqueName2 callback (Igor Pro 2.0 or later)
	and CheckName callback (Igor Pro 3.0 or later).
*/
#define MAIN_NAME_SPACE 1			// Igor's main name space (waves, variables, windows).
#define PATHS_NAME_SPACE 2			// Igor's symbolic path name space.
#define PICTS_NAME_SPACE 3			// Igor's picture name space.
#define WINDOWS_NAME_SPACE 4		// Igor's windows name space. Added in Igor Pro 3.0.
#define DATAFOLDERS_NAME_SPACE 5	// Igor's data folders name space. Added in Igor Pro 3.0.

// From IgorMenus.h
// These are the menu IDs that you can use in XMI1 resources to attach menu items to Igor menus.
#define APPLEID 1
#define FILEID 2
#define EDITID 3
#define WAVEFORMID 4
#define DATAID 4					// HR, 10/2/93 -- old "Waves" menu is now called "Data"
#define ANALYSISID 5
#define MACROID 6
#define WINDOWSID 7
#define MISCID 8
#define LAYOUTID 10					// HR, 10/2/93 -- this was 9 prior to Igor 2.0
#define GRAPHID 12					// HR, 10/2/93 -- added for Igor Pro 2.0
#define PANELID 13					// HR, 10/2/93 -- added for Igor Pro 2.0
#define TABLEID 14					// HR, 10/2/93 -- added for Igor Pro 2.0
#define PROCEDUREID 15				// HR, 10/2/93 -- added for Igor Pro 2.0
#define NOTEBOOKID 16				// HR, 10/2/93 -- added for Igor Pro 2.0
#define LOAD_SUB_ID 50
#define SAVE_SUB_ID 51
// #define SAVEGRAPHICS_SUB_ID 52	// HR, 981105: The Save Graphics submenu was removed in Igor Pro 3.1.
#define OPEN_FILE_SUB_ID 55
#define CONTROL_WIN_SUB_ID 56
#define NEW_WIN_SUB_ID 58
#define MISC_OPS_SUB_ID 59
#define APPEND_TO_GRAPH_SUBID 89	// HR, 3/2/96 -- added for Igor Pro 3.0

#define T_COMMA		1			// terminator codes
#define T_RPAREN 	2
#define T_SEMI		4
#define T_RBRACK	8
#define T_RCBRACE	16
#define T_NORM		(T_COMMA | T_SEMI)
#define T_CRP		(T_COMMA | T_RPAREN)
#define T_CRB		(T_COMMA | T_RCBRACE)
#define T_CRBRACK	(T_COMMA | T_RBRACK)


// From IgorMath.h
#define NT_CMPLX 1				// complex numbers
#define NT_FP32 2				// 32 bit fp numbers
#define NT_FP64 4				// 64 bit fp numbers
#define NT_I8 8					// 8 bit signed integer
#define NT_I16 	0x10			// 16 bit integer numbers
#define NT_I32 	0x20			// 32 bit integer numbers
#define NT_I64 	0x80			// 64 bit integer numbers - requires Igor7 or later
#define NT_UNSIGNED 0x40		// Makes above signed integers unsigned.
#define DATAFOLDER_TYPE 0x100	// Data type for DFREF waves (waves containing data folder references)
#define WAVE_TYPE 0x4000		// Data type for wave-reference waves (waves containing wave references)


// From wave.h
#define MAX_WAVE_NAME 31		// maximum length of wave name -- not including the null
								//	NOTE: Prior to Igor 3.0, this was 18 and we recommended that you use MAX_OBJ_NAME (31) instead of MAX_WAVE_NAME.

#define TEXT_WAVE_TYPE 0		// The wave type code for text waves. Added in Igor Pro 3.0.

#define MAX_DIMENSIONS 10		// Maximum number of dimensions in a multi-dimension object.
								// In Igor 3.0, the max is actually 4 but this may increase in the future.
#define ROWS 0					// Dimension 0 is the row dimension.
#define COLUMNS 1				// Dimension 1 is the column dimension.
#define LAYERS 2				// Dimension 2 is the layer dimension.
#define CHUNKS 3				// Dimension 3 is the chunk dimension.

#define MAX_UNIT_CHARS 49		// Max number of characters in a units string, not including trailing null, in Igor Pro 3.0 or later.
								// Prior to Igor Pro 3.0, the maximum was 3 characters.

#define MAX_DIM_LABEL_CHARS 31	// Max chars in a dimension label, not including trailing null.
								
#define kMDWaveAccessMode0 0	// Access code for MDAccessNumericWaveData. Used by Igor for future compatibility check.

// From WM.h
#define UNKNOWNCURSOR 0
#define ARROWCURSOR 1
#define WATCHCURSOR 2
#define IBEAMCURSOR 3
#define HANDCURSOR 4
#define SPINNINGCURSOR 5
#define CROSSHAIRCURSOR 6
#define MAX_OBJ_NAME 31			// maximum length of: variables,macros,annotations.
#define MAX_LONG_NAME 255		// Added in 6.00D00. Used for double names.

#ifdef MACIGOR
	// HR, 080728: XOP Toolkit 5.09 - Support long file names on Macintosh.
	#define MAX_VOLUMENAME_LEN 255			// Maximum length of volume name
	#define MAX_DIRNAME_LEN 255				// Maximum length of directory name
	#define MAX_FILENAME_LEN 255			// Maximum length of file name
	#define MAX_PATH_LEN 511				// Maximum length of path name. This was 511 in Igor 3.0 so I am leaving it as 511 even though it is not clear whether the Mac OS support more than 255.
#endif
#ifdef WINIGOR
	#define MAX_VOLUMENAME_LEN 255			// Maximum length of volume name (e.g., "C:")
	#define MAX_DIRNAME_LEN 255				// Maximum length of directory name
	#define MAX_FILENAME_LEN 255			// maximum length of file name
	#define MAX_PATH_LEN 259				// maximum length of path name
#endif


/*	This is used to select one of two ways of doing something or to allow both.
	For an example, see VolumeNameLength() in WMFileUtils.c.
*/
typedef enum PlatformCode {
	kMacPlatform=1,				// This is stored on disk. The value must not be changed.
	kWinPlatform,				// This is stored on disk. The value must not be changed.
	kMacOrWinPlatform,
	#ifdef MACIGOR
		kCurrentPlatform=kMacPlatform
	#endif
	#ifdef WINIGOR
		kCurrentPlatform=kWinPlatform
	#endif
} PlatformCode;

#define CR_STR "\015"			// Can be used as follows: XOPNotice("Test" CR_STR);
#define CR_CHAR '\015'
#define LF_STR "\012"
#define LF_CHAR '\012'

// From Functions.h

// These are used to identify parameters to external functions as waves, data folder references, strings or names
#define WAVE_TYPE 0x4000		// Added to number types above to signify parameter is wave
#define DATAFOLDER_TYPE 0x100	// Signifies parameter is a DFREF
#define HSTRING_TYPE 0x2000		// Signifies parameter is a handle to a string

// These are used to test parameter types returned by GetUserFunctionInfo.
#define FV_REF_TYPE 0x1000		// Signifies pass-by-reference
#define FV_FUNC_TYPE 0x0400		// Signifies a function reference
#define WAVE_Z_TYPE	0x8000		// Identifies WAVE/Z argument
#define FV_STRUCT_TYPE 0x0200	// Requires Igor Pro 5.03 or later

struct NVARRec {				// Used for NVAR structure fields.
	PSInt urH;					// 32 bits in Igor32, 64 bits in Igor64
	IndexInt index;				// 32 bits in Igor32, 64 bits in Igor64
};
typedef struct NVARRec NVARRec;

struct SVARRec {				// Used for SVAR structure fields.
	PSInt urH;					// 32 bits in Igor32, 64 bits in Igor64
	IndexInt index;				// 32 bits in Igor32, 64 bits in Igor64
};
typedef struct SVARRec SVARRec;

typedef PSInt FUNCREF;			// Used for FUNCREF structure fields.

struct FunctionInfo {			// Used by GetUserFunctionInfo.
	char name[MAX_OBJ_NAME+1];
	int compilationIndex;
	int functionID;
	int subType;
	int isExternalFunction;
	int returnType;
	int imIndex;				// Reserved for WaveMetrics use
	int moduleSerialNum;		// Reserved for WaveMetrics use
	int isThreadSafe;			// If you are running in a thread, any function you call must be threadsafe. Check this field to make sure.
	int reserved[22];			// Do not use. Reserved for future use.
	int numOptionalParameters;
	int numRequiredParameters;
	int totalNumParameters;
	int parameterTypes[100];
};
typedef struct FunctionInfo FunctionInfo;
typedef FunctionInfo* FunctionInfoPtr;

typedef void* UserFunctionThreadInfoPtr;

// From TextUtils.h

// structure for getting info about text utility document
struct TUDocInfo {			// 10/23/93: added for Igor Pro 2.0D83
	short version;						// version number of this structure
	short permission;					// 0 = read only, 1 = read/write
	short fileType;						// for future use
	int paragraphs;						// total number of paragraphs in document
	char reserved[256];					// for future use
};
typedef struct TUDocInfo TUDocInfo;
typedef struct TUDocInfo *TUDocInfoPtr;
#define TUDOCINFO_VERSION 1

struct TULoc {							// identifies a location in a text utility document
	int paragraph;						// location's paragraph
	unsigned short pos;					// character offset in paragraph for text paragraph
};
typedef struct TULoc TULoc;
typedef struct TULoc *TULocPtr;

/*	When to erase message in status area.
	This is a bitwise parameter used with the TUSetStatus() callback.
	The status is always changed if a new message comes along.
	This controls if and when it will be erased before a new message comes.
*/
#define TU_ERASE_STATUS_NEVER 0
#define TU_ERASE_STATUS_WHEN_SELECTION_CHANGES 1
#define TU_ERASE_STATUS_WHEN_WINDOW_ACTIVATED 2
#define TU_ERASE_STATUS_WHEN_WINDOW_DEACTIVATED 4
#define TU_ERASE_STATUS_WHEN_DOC_MODIFIED 8
#define TU_ERASE_STATUS_WHEN_ANYTHING_HAPPENS -1


// From CmdWin.h
// modes for PutCmdLine()
#define INSERTCMD 1					// insert text at current insertion point
#define FIRSTCMD 2					// insert text in front of cmd buffer
#define FIRSTCMDCRHIT 3				// insert text in front of cmd buffer and set crHit
#define REPLACEFIRSTCMD 4			// replace first line of cmd buffer with text
#define REPLACEALLCMDSCRHIT 5 		// replace all lines of cmd buffer with text and set crHit
#define REPLACEALLCMDS 6			// replace all lines of cmd buffer with text


// From ColorTables.h
typedef Handle IgorColorTableHandle;
typedef struct IgorColorSpec {
	UInt32 value;					// index or other value
	RGBColor rgb;					// true color
} IgorColorSpec;


// From CommandUtils.h
// structure for getting and passing wave range information
struct WaveRangeRec {
	// the following fields are set by GetWaveRange based on command line
	double x1, x2;	// *** 4/21/90 -- changed from float to double
	int rangeMode;					// bit 0 set if start specified, bit 1 set if end specified
	int isBracket;					// true if range specified by [] instead of ()
	int gotRange;					// true if /R=range was present

	// next, you setup these fields
	Handle waveHandle;
	CountInt minPoints;				// min number of points in acceptable range
	
	// Then, following fields are setup by CalcWaveRange
	IndexInt p1, p2;
	int wasBackwards;				// truth p1 > p2 before being swapped
};
typedef struct WaveRangeRec WaveRangeRec;
typedef struct WaveRangeRec *WaveRangeRecPtr;


// From Variables.h
#define VAR_GLOBAL	0x4000				// bit flag for type parameter of Variable XOP callback

struct NumVarValue{						// Used in Get/SetDataFolderObject call.
	int numType;			// NT_FP64 possibly ORed with NT_CMPLX (if variable is complex).
	int spare;				// For future use - set to zero.
	double realValue;
	double imagValue;
};
typedef struct NumVarValue NumVarValue;
typedef NumVarValue* NumVarValuePtr;

union DataObjectValue {
	waveHndl waveH;						// Use this if the object is a wave.
	NumVarValue nv;						// Use this if the object is a numeric variable.
	Handle strH;						// Use this if the object is a string variable.
	DataFolderHandle dfH;				// Use this if the object is a data folder.
	char spare[64];						// For possible future use.
};
typedef union DataObjectValue DataObjectValue;
typedef DataObjectValue* DataObjectValuePtr;


// From Save.h
#define SAVE_TYPE_SAVE 1				// experiment save type codes
#define SAVE_TYPE_SAVEAS 2
#define SAVE_TYPE_SAVEACOPY 3
#define SAVE_TYPE_STATIONERY 4

#define LOAD_TYPE_NEW 1					// experiment load type codes
#define LOAD_TYPE_OPEN 2
#define LOAD_TYPE_REVERT 3
#define LOAD_TYPE_STATIONERY 4
#define LOAD_TYPE_MERGE 5				// Added in Igor Pro 5.

#define EXP_UNPACKED 0					// experiment file type codes
#define EXP_PACKED 1


// From OperationHandler.h
#define kUseCMDMessageForInterpreting 1
#define kOperationIsThreadSafe 2		// HR, 070507: Pass to RegisterOperation if operation is thread safe.

struct DataFolderAndName {
	DataFolderHandle dfH;
	char name[MAX_OBJ_NAME+1];
};
typedef struct DataFolderAndName DataFolderAndName;
typedef struct DataFolderAndName *DataFolderAndNamePtr;

// Options used with GetOperationDestWave.
enum {
	kOpDestWaveOverwriteOK = 1,
	kOpDestWaveChangeExistingWave = 2,
	kOpDestWaveOverwriteExistingWave = 4,
	kOpDestWaveMakeFreeWave = 8,
	kOpDestWaveMustAlreadyExist = 16
};

struct WaveRange {
	waveHndl waveH;
	double startCoord;					// Start point number or x value
	double endCoord;					// End point number or x value
	int rangeSpecified;					// 0 if user specified no range. 1 if user specified range.
	int isPoint;						// 0 if user specified range using X values. 1 if user specified range using points.
};
typedef struct WaveRange WaveRange;
typedef struct WaveRange *WaveRangePtr;

// This is what is in the runtime parameter structure for a mode 1 structure parameter.
// For a mode 0 structure parameter, the runtime parameter structure contains just a pointer to the structure.
struct IgorStructInfo {
	void* structPtr;					// Pointer to the structure.
	unsigned int structSize;			// Size of structure in bytes.
	char structTypeName[MAX_OBJ_NAME+1];
	int moduleSerialNumber;				// Used by Igor to determine the procedure file in which structure is defined.
	unsigned char reserved[32];			// Reserved for future use.
};
typedef struct IgorStructInfo IgorStructInfo;
typedef struct IgorStructInfo *IgorStructInfoPtr;

// WM text encoding codes used by WaveTextEncoding and ConvertTextEncoding
enum WMTextEncodingCode {
	/*	kWMTextEncodingUnspecified acts like NaN - that is, the code is missing or unspecified.
		It is not a valid text encoding code.
	*/
	kWMTextEncodingUnspecified = -1,
	
	kWMTextEncodingNone=0,							// Unknown or unsupported text encoding
	kWMTextEncodingUTF8=1,
	kWMTextEncodingMacRoman=2,
	kWMTextEncodingWindows1252=3,					// a.k.a., Windows Western

	kWMTextEncodingJIS=4,							// Shift-JIS
	kWMTextEncodingEUCJP=5,
	
	kWMTextEncodingTraditionalChinese=20,
	kWMTextEncodingSimplifiedChinese=21,
	kWMTextEncodingISO2022CN=22,
	kWMTextEncodingChineseGB18030=23,
	
	kWMTextEncodingMacKorean=40,
	kWMTextEncodingWinKorean=41,
	kWMTextEncodingISOKorean=42,
	
	kWMTextEncodingUTF16BE=100,
	kWMTextEncodingUTF16LE=101,
	kWMTextEncodingUTF32BE=102,
	kWMTextEncodingUTF32LE=103,
	
	/*	kWMTextEncodingBinary is not a real text encoding code. It is used ONLY to mark
		a text wave's data as containing binary data, to say that the text wave is not
		really a text wave but is really a binary data wave.
		This is different from kWMTextEncodingNone which means "we don't know what is stored
		in the wave". This means "we know what it is and it is binary".
	*/
	kWMTextEncodingBinary = 255,
};
typedef enum WMTextEncodingCode WMTextEncodingCode;

/*	WMTextEncodingConversionErrorMode is used by ConvertTextEncoding.
	It controls what happens if the conversion can not be performed because
	there is no mapping from the source to the destination text encoding.
	For most purposes you should use kWMTextEncodingConversionErrorModeFail.
*/
enum WMTextEncodingConversionErrorMode {
	kWMTextEncodingConversionErrorModeFail=1,			// Return error if there is no mapping from source to target
	
	/*	Each ICU converter has a substitution character. For Unicode destinations it is
		Unicode substitution character (U+FFFD). For non-Unicode destinations it is usually
		0x1A (Ctrl-Z).
	*/
	kWMTextEncodingConversionErrorModeSubstitute=2,		// Substitute substitution character for unmappable characters
	
	kWMTextEncodingConversionErrorModeSkip=3,			// Skip unmappable characters - they will be missing in output
	
	kWMTextEncodingConversionErrorModeEscape=4			// Replace unmappable characters with escape codes
};
typedef enum WMTextEncodingConversionErrorMode WMTextEncodingConversionErrorMode;

// These enums are used with WMTextEncodingConversionOptions to provide additional control over the conversion process
enum WMTextEncodingConversionOptionFlag {
	kTECOptionFlagDontAllowNulls = 0,
	kTECOptionFlagAllowNulls = 1,
	kTECOptionFlagDoConversionEvenIfEncodingsAreTheSame = 2,
	kTECOptionFlagIsProcedureCode = 4,
};

// WMTextEncodingConversionOptions is a collection of WMTextEncodingConversionOptionFlag by ORing
typedef int WMTextEncodingConversionOptions;

#pragma pack()	// Restore default structure packing
