﻿// External operations equates, data types, data structures

#ifndef XOP_H_INCLUDED
#define XOP_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

#pragma pack(2)	// All structures passed to Igor are two-byte aligned.

/*	Development System Codes - Use DEV_SYS_CODE in the second field of the
	XOPI resource and stored in the system field of the XOPStuff structure.
	These codes are also defined in XOPResources.h for use in .r and .rc files.
*/
#define DEV_SYS_CODE_ALL_OTHERS 0		// Use this for any type of development not listed below.
#define DEV_SYS_CODE_MAC_MPW 1			// Obsolete.
#define DEV_SYS_CODE_MAC_MACH 2			// Use this for Macintosh Mach-O XOPs.

#define XOP_VERSION 4					// Current XOP version; NOTE: This is in XOPResources.h also.
#define XOP_MAX_OBJ_NAME_31 31			// Used where names are limited to 31 bytes in XOPs that have not been updated to support long names

// *** Data Types ***

// These will be 32 bits in Igor32 and 64 bits in Igor64.
#ifdef IGOR64
	typedef SInt64 XOPIORecParam;	// Used for parameters passed to XOP in IORecHandle and for parameters passed in IORecHandle from XOP to Igor during callbacks.
	typedef SInt64 XOPIORecResult;	// Used for results passed to or from XOP in IORecHandle.
#else
	typedef SInt32 XOPIORecParam;	// Used for parameters passed to XOP in IORecHandle and for parameters passed in IORecHandle from XOP to Igor during callbacks.
	typedef SInt32 XOPIORecResult;	// Used for results passed to or from XOP in IORecHandle.
#endif

// Cast for passing an integer parameter as a void* to CallBack1, CallBack2, ... to avoid C4312 warning
#ifdef IGOR64
	#define XOP_CALLBACK_INT(x) (void*)(UInt64)x
#else
	#define XOP_CALLBACK_INT(x) (void*)(UInt32)x
#endif

/*	On Macintosh, we use a file reference number to identify an XOP (the xopRefNum
	field in XOPStuff. On Windows, we use a handle to a DLL module (the hModule field).
	We define the symbol XOP_MODULE_REF such that it can be used on either platform for
	the type of the thing that identifies a particular XOP.
*/	
#ifdef MACIGOR
	#define XOP_MODULE_REF int
	#define NULL_XOP_MODULE 0
#endif
#ifdef WINIGOR
	#define XOP_MODULE_REF HMODULE
	#define NULL_XOP_MODULE NULL
#endif

/*	We are now using standard C file I/O routines for file I/O.
	Using this #define instead of FILE* makes is easy to switch
	to native routines if desired in the future.
*/
#define XOP_FILE_REF FILE*


// *** Structures used for XOPs ***

/*	Private XOP information maintained by Igor
	Although this is private, the fields marked with *** are used in XOPSupport.c
	and XOPSupportMac.c. Therefore those fields and their offsets in the structure
	can not be changed without breaking existing XOPs.
*/
struct XOPStuff {					// Structure of private bookkeeping info
	struct XOPStuff **nextXOPHandle;// For linked list of open XOPs
	char wasXOPName[XOP_MAX_OBJ_NAME_31+1];	// Was name of XOP. Now this field is for Igor's private use. Must be 32 bytes for backward compatibility because XOPSupport routines access this structure.
	struct IORec **ioRecHandle;		// Handle to main ioRec for this XOP
	unsigned char flags;			// Private flags used by Igor; 10/28/93
	unsigned char developmentSystem;// Code for development system

	#ifdef MACIGOR					// Mac-specific fields [
		Handle mapHandle;			// Obsolete - always NULL
		UInt32 oldA4;				// Obsolete
		UInt32 oldA5;				// Obsolete
		short oldApRefNum;			// Igor's file reference number *** Used by IgorVersion ***
		UInt32 newA4;				// Obsolete
		UInt32 newA5;				// Obsolete
		short xopRefNum;			// XOP's file reference number *** Used by XOPRefNum ***
		short curResFile;			// XOP's curResFile
		
		// Everything below is private to Igor and may change from Igor version to Igor version
		CFBundleRef bundleInstance;	// Mach XOP bundle reference
	#endif							// End Mac-specific fields ]
	
	// Fields below here are private to Igor and can be changed from version to version
};
typedef struct XOPStuff XOPStuff;
typedef XOPStuff *XOPStuffPtr;
typedef XOPStuffPtr *XOPStuffHandle;

// For flags field in XOPStuff.
#define XOP_RUNNING 1				// Used by Igor to detect recursion.
#define XOP_MUST_STAY_RESIDENT 2	// Used by Igor to prevent unloading an XOP that adds a direct XFUNC or a direct operation.

/*	Bit-mask codes for system field in XOPStuff structure.
	These are used internally by Igor and are of no concern to the XOP programmer.
*/
#define MULTI_SEG 1					// XOP is MPW style multi-segment with standard Macintosh CODE 0.
#define NO_DOUBLE 2					// OBSOLETE: XOP uses extended instead of double. This was used in the days of THINK C 3.0.

struct IORec {
	short XOPProtocolVersion;		// XOP protocol version as specified by the first field in the XOP's XOPI resource
	int XOPType;					// Transient/resident, idle/no idle and other info
	XOPIORecResult result;			// Result code from XOP or from callback -- inited to 0
	int status;						// Various status info depending on operation
	void (*callBackProc)(void*);	// Address of routine for calling back to Igor
	void (*XOPEntry)(void);			// Address for calling XOP from Igor
	XOPStuffHandle stuffHandle;		// Used by Igor for bookkeeping purposes
	XOPIORecParam refCon;			// For use by XOP --initially zero
	short message;					// Bidirectional message passed between host and XOP
	short menuID;					// ID of menu for XOP or 0 if none
	short itemID;					// Number of menu item for XOP of 0 if none
	short subMenuID;				// ID of submenu for XOP or 0 if none
	short numItems;					// Total number of items in list
	XOPIORecParam items[1];			// List of items to operate on -- variable length array
};
typedef struct IORec IORec;
typedef IORec *IORecPtr;
typedef IORecPtr *IORecHandle;

#define NUM_IOREC_ITEMS 16			// Maximum number of XOPIORecParam items in IORecHandle. Used in SetRecHandle.

// XOPCallRec is used for threadsafe callbacks to Igor.
#define kXOPCallRecVersion 1000
struct XOPCallRec {	// Information used in a call from Igor to an XOP or from an XOP to Igor
	SInt32 version;						// XOPCallRec version.
	IORecHandle ioRecHandle;
	SInt32 message;						// Callback code from XOP
	SInt32 numParameters;				// Number of parameters
	XOPIORecParam* parametersP;			// Pointer to array of parameters
	void* reserved1;					// Reserved for future use - must be set to zero
	void* reserved2;					// Reserved for future use - must be set to zero
	void* reserved3;					// Reserved for future use - must be set to zero
	void* reserved4;					// Reserved for future use - must be set to zero
	XOPIORecResult result;				// Result
};
typedef struct XOPCallRec XOPCallRec;
typedef struct XOPCallRec *XOPCallRecPtr;

// *** Miscellanous ***

// XOP type codes identify capabilities of XOP -- used to set XOPType field.
#define TRANSIENT 0
#define RESIDENT 1					// XOP wants to stick around indefinitely.
#define IDLES 2						// XOP has idle routine to be called periodically.
#define ADDS_TARGET_WINDOWS 4		// XOP has the capability of adding one or more target windows to Igor. For Igor Pro 3.13B03.

/* XOP status codes used by Igor to inform XOP */
#define INFOREGROUND 0				/* Igor is in foreground */
#define INBACKGROUND 1				/* Igor is in background */
#define XOPINITING 2				/* XOP is being inited */

/* XOP error #defines */
#define XOP_ERRS_ID 1100			/* resource ID for STR# resource for custom XOP errors */
#define FIRST_XOP_ERR 10000
#define LAST_XOP_ERR 11999

/* Flags used in XOP menus and XOP menu item resources. */
/* A copy of these is in XOPTypes.r so they can be used in .r files */
#define SHOW_MENU_AT_LAUNCH 1				/* for XMN1 resource menuFlags field */
#define SHOW_MENU_WHEN_ACTIVE 2				/* for XMN1 resource menuFlags field */
#define ITEM_REQUIRES_WAVES 1				/* for XMI1 resource itemFlags field */
#define ITEM_REQUIRES_GRAPH 2				/* for XMI1 resource itemFlags field */
#define ITEM_REQUIRES_TABLE 4				/* for XMI1 resource itemFlags field */
#define ITEM_REQUIRES_LAYOUT 8				/* for XMI1 resource itemFlags field */
#define ITEM_REQUIRES_GRAPH_OR_TABLE 16		/* for XMI1 resource itemFlags field */
#define ITEM_REQUIRES_TARGET 32				/* for XMI1 resource itemFlags field */
#define ITEM_REQUIRES_PANEL 64				/* for XMI1 resource itemFlags field; added for Igor version 2.0 */
#define ITEM_REQUIRES_NOTEBOOK 128			/* for XMI1 resource itemFlags field; added for Igor version 2.0 */
#define ITEM_REQUIRES_GRAPH_OR_PANEL 256	/* for XMI1 resource itemFlags field; added for Igor version 2.0 */
#define ITEM_REQUIRES_DRAW_WIN 512			/* for XMI1 resource itemFlags field; added for Igor version 2.0 */
#define ITEM_REQUIRES_PROC_WIN 1024			/* for XMI1 resource itemFlags field; added for Igor version 2.0 */


// *** XOP Message Codes -- Codes passed from Igor to XOP ***

// Basic messages
#define INIT 1
#define IDLE 2
#define CMD 3
#define NEW 4
#define LOAD 5
#define SAVE 6
#define SAVESETTINGS 7
#define LOADSETTINGS 8
#define MODIFIED 9
#define MENUITEM 10
#define MENUENABLE 11
#define CLEANUP 12
#define OBJINUSE 13
#define FUNCTION 14						// Added in Igor Pro 2.0D54.		
#define FUNCADDRS 15					// Added in Igor Pro 2.0D54.
// Messages 16 through 20 were used for target windows in Igor Pro 6 and before. New messages are now defined in XOPWindows.h.
#define CLEAR_MODIFIED 21				// Added in Igor Pro 3.13B03.
#define EXECUTE_OPERATION 22			// Added in Igor Pro 5.00.

// Window messages - messages related to windows are defined in XOPWindows.h
// Container messages - messages related to containers are defined in XOPContainers.h

// *** Callback operation codes -- codes passed from XOP to Igor ***

#define WAVEMODIFIED 1
#define WAVEHANDLEMODIFIED 2
#define FETCHNUMVAR 3
#define FETCHSTRVAR 4
#define STORENUMVAR 5
#define STORESTRVAR 6
#define FETCHWAVE 7
#define NOTICE 8
#define COMMAND 9
#define NEXTSYMB 10
#define GETSYMB 11
#define GETFLAG 12
#define GETFLAGNUM 13
#define GETNAME 14
#define GETVAR 15
#define GETNUM 16
#define GETLONG 17
#define GETSTRING 18
#define GETWAVE 19
#define GETWAVELIST 20
#define CHECKTERM 21
#define UNIQUENAME 22
#define GETPATH 23
#define GETFORMAT 24
#define GETWRITESTRING 25		/* OBSOLETE -- use CHIO instead */
#define GETWRITEWAVES 26		/* OBSOLETE -- use CHIO instead */
#define WRITEWAVES 27			/* OBSOLETE -- use CHIO instead */
#define GETREAD 28				/* OBSOLETE -- use CHIO instead */
#define PAUSEUPDATE 29
#define RESUMEUPDATE 30
#define SILENT 31				/* OBSOLETE -- does nothing */
#define UNSILENT 32				/* OBSOLETE -- does nothing */
#define SETCURSOR 33
#define WAVETYPE 34
#define WAVEPOINTS 35
#define WAVENAME 36
#define WAVEDATA 37
#define DEFAULTMENUS 38
#define CHIO 39
#define GETWAVERANGE 40
#define CALCWAVERANGE 41
#define MAKEWAVE 42
#define CHANGEWAVE 43
#define KILLWAVE 44
#define VARIABLE 45
#define IGORERROR 46
#define WAVESMODIFIED 47
#define SPINPROCESS 48
#define PUTCMDLINE 49
#define WAVESCALING 50
#define SETWAVESCALING 51		/* added in Igor 1.20 */
#define WAVEUNITS 52
#define SETWAVEUNITS 53
#define WAVENOTE 54				// Not supported in XOP Toolkit 7 and later - see WAVENOTECOPY
#define SETWAVENOTE 55
#define WAVELIST 56				/* added in Igor 1.24 */
#define WINLIST 57
#define PATHLIST 58
#define FETCHSTRHANDLE 59
#define GETNUM2 60
#define ACTUALMENUID 61
#define RESOURCEMENUID 62
#define ACTUALITEMNUM 63
#define RESOURCEITEMNUM 64
#define WININFO 65
#define PATHINFO 66				/* added in Igor 1.25 */
#define GETNAMEDFIFO 67			/* added in Igor Pro 2.0D54 */
#define MARKFIFOUPDATED 68
#define SETIGORMENUITEM 69
#define SILENT_COMMAND 70
#define DOUPDATE 71
#define XOPMENUHANDLE 72
#define GETSTRINGINHANDLE 73
#define VARIABLELIST 74
#define STRINGLIST 75
#define UNIQUENAME2 76
#define MD_MAKEWAVE 77			/* added in Igor Pro 3.0 */
#define MD_GETWAVEDIMENSIONS 78
#define MD_CHANGEWAVE 79
#define MD_GETWAVESCALING 80
#define MD_SETWAVESCALING 81
#define MD_GETWAVEUNITS 82
#define MD_SETWAVEUNITS 83
#define MD_GETDIMLABELS 84
#define MD_SETDIMLABELS 85
#define MD_ACCESSNUMERICWAVEDATA 86
#define MD_GETWAVEPOINTVALUE 87
#define MD_SETWAVEPOINTVALUE 88
#define MD_GETDPDATAFROMNUMERICWAVE 89
#define MD_STOREDPDATAINNUMERICWAVE 90
#define MD_GETTEXTWAVEPOINTVALUE 91
#define MD_SETTEXTWAVEPOINTVALUE 92
#define WAVEMODDATE 93						// Added in Igor Pro 3.01
#define WAVEMODSTATE 94						// Added in Igor Pro 4.0D08 but works with all versions of Igor.
#define WAVEMODCOUNT 95						// Added in Igor Pro 4.0D08
#define MD_CHANGEWAVE2 96					// Added in Igor Pro 5.04B06
#define WAVENOTECOPY 97						// Added in Igor7
/* 98 - 99 are reserved. */

#define GET_DATAFOLDER_NAMEORPATH 100		/* added in Igor Pro 3.0 */
#define GET_DATAFOLDER_IDNUMBER 101
#define GET_DATAFOLDER_PROPERTIES 102
#define SET_DATAFOLDER_PROPERTIES 103
#define GET_DATAFOLDER_LISTING 104
#define GETROOT_DATAFOLDER 105
#define GETCURRENT_DATAFOLDER 106
#define SETCURRENT_DATAFOLDER 107
#define GETNAMED_DATAFOLDER 108
#define GET_DATAFOLDER_BYIDNUMBER 109
#define GETPARENT_DATAFOLDER 110
#define GETNUMCHILD_DATAFOLDERS 111
#define GETINDEXEDCHILD_DATAFOLDER 112
#define GETWAVES_DATAFOLDER 113
#define NEW_DATAFOLDER 114
#define KILL_DATAFOLDER 115
#define DUPLICATE_DATAFOLDER 116
#define MOVE_DATAFOLDER 117
#define RENAME_DATAFOLDER 118
#define GETNUM_DATAFOLDER_OBJECTS 119
#define GETINDEXED_DATAFOLDER_OBJECT 120
#define KILL_DATAFOLDER_OBJECT 121
#define MOVE_DATAFOLDER_OBJECT 122
#define RENAME_DATAFOLDER_OBJECT 123
#define GET_DATAFOLDER_AND_NAME 124
#define CLEAR_DATAFOLDER_FLAGS 125
#define GET_DATAFOLDER_CHANGESCOUNT 126
#define GET_DATAFOLDER_CHANGEFLAGS 127
#define DUPLICATE_DATAFOLDER_OBJECT 128

#define CHECKNAME 150						/* Added in Igor Pro 3.0. */
#define POSSIBLY_QUOTE_NAME 151				/* Added in Igor Pro 3.0. */
#define CLEANUP_NAME 152					/* Added in Igor Pro 3.0. */
#define PREPARE_LOAD_IGOR_DATA 153			/* Obsolete and not supported as of Igor7 and XOP Toolkit 7 */
#define DO_LOAD_IGOR_DATA 154				/* Obsolete and not supported as of Igor7 and XOP Toolkit 7 */
#define END_LOAD_IGOR_DATA 155				/* Obsolete and not supported as of Igor7 and XOP Toolkit 7 */
#define IS_STRING_EXPRESSION 156			/* Added in Igor Pro 3.0. */
#define FETCHWAVE_FROM_DATAFOLDER 157		/* Added in Igor Pro 3.0. */
#define GET_DATAFOLDER 158					/* Added in Igor Pro 3.0. */
#define GET_DATAFOLDER_OBJECT 159			/* Added in Igor Pro 3.0. */
#define SET_DATAFOLDER_OBJECT 160			/* Added in Igor Pro 3.0. */

#define SAVE_XOP_PREFS 161					// Added in IGOR Pro 3.10.
#define GET_XOP_PREFS 162					// Added in IGOR Pro 3.10.
#define GET_PREFS_STATE 163					// Added in IGOR Pro 3.10.

#define GET_INDEXED_IGORCOLORTABLE_NAME 164	// Added in IGOR Pro 3.10.
#define GET_NAMED_IGORCOLORTABLE_HANDLE 165	// Added in IGOR Pro 3.10.
#define GET_IGORCOLORTABLE_INFO 166			// Added in IGOR Pro 3.10.
#define GET_IGORCOLORTABLE_VALUES 167		// Added in IGOR Pro 3.10.

#define PATHINFO2 168						// Added in Igor Pro 3.13.
#define GET_DIR_AND_FILE_FROM_FULL_PATH 169	// Added in Igor Pro 3.13.
#define CONCATENATE_PATHS 170				// Added in Igor Pro 3.13.
#define WIN_TO_MAC_PATH 171					// Added in Igor Pro 3.13.
#define MAC_TO_WIN_PATH 172					// Added in Igor Pro 3.13.
#define STRCHR2 173							// Added in Igor Pro 3.13.
#define STRRCHR2 174						// Added in Igor Pro 3.13.

#define DISPLAY_HELP_TOPIC 175				// Added in Igor Pro 3.13.

#define WINDOW_RECREATION_DIALOG 176		// Added in Igor Pro 3.13.
#define GET_IGOR_PROCEDURE_LIST 177			// Added in Igor Pro 3.13.
#define GET_IGOR_PROCEDURE 178				// Added in Igor Pro 3.13.
#define SET_IGOR_PROCEDURE 179				// Added in Igor Pro 3.13.
#define GET_IGOR_ERROR_MESSAGE 180			// Added in Igor Pro 3.14.

#define COMMAND2 181						// Added in Igor Pro 4.0D04.
#define AT_END_OF_COMMAND 182				// Added in Igor Pro 4.0D11.

#define SET_CONTEXTUAL_HELP_DIALOG_ID 183	// Added in Igor Pro 5.0. This is a NOP on Windows.
#define SHOW_HIDE_CONTEXTUAL_HELP 184		// Added in Igor Pro 5.0. This is a NOP on Windows.
#define SET_CONTEXTUAL_HELP_MESSAGE 185		// Added in Igor Pro 5.0. Works on Macintosh and Windows.

#define DO_SAVE_IGOR_DATA 186				// Obsolete and not supported as of Igor7 and XOP Toolkit 7

#define REGISTER_OPERATION 187					// Added in Igor Pro 5.0.
#define SET_RUNTIME_NUMERIC_VARIABLE 188		// Added in Igor Pro 5.0.
#define SET_RUNTIME_STRING_VARIABLE 189			// Added in Igor Pro 5.0.
#define VAR_NAME_TO_DATA_TYPE 190				// Added in Igor Pro 5.0.
#define STORE_NUMERIC_DATA_USING_VAR_NAME 191	// Added in Igor Pro 5.0.
#define STORE_STRING_DATA_USING_VAR_NAME 192	// Added in Igor Pro 5.0.

#define GET_FUNCTION_INFO 193					// Added in Igor Pro 5.0.
#define CHECK_FUNCTION_FORM 194					// Added in Igor Pro 5.0.
#define CALL_FUNCTION 195						// Added in Igor Pro 5.0.

#define WAVELOCK 196							// Added in Igor Pro 5.0.
#define SETWAVELOCK 197							// Added in Igor Pro 5.0.
#define DATE_TO_IGOR_DATE 198					// Added in Igor Pro 5.0.
#define IGOR_DATE_TO_DATE 199					// Added in Igor Pro 5.0.

#define GET_NVAR 200							// Added in Igor Pro 5.03.
#define SET_NVAR 201							// Added in Igor Pro 5.03.
#define GET_SVAR 202							// Added in Igor Pro 5.03.
#define SET_SVAR 203							// Added in Igor Pro 5.03.
#define GET_FUNCTION_INFO_FROM_FUNCREF 204		// Added in Igor Pro 5.03.

#define GET_TEXT_WAVE_DATA 205					// Added in Igor Pro 5.04.
#define SET_TEXT_WAVE_DATA 206					// Added in Igor Pro 5.04.
#define GET_WAVE_DIMENSION_LABELS 207			// Added in Igor Pro 5.04.
#define SET_WAVE_DIMENSION_LABELS 208			// Added in Igor Pro 5.04.

#define SET_OPERATION_WAVE_REF 209				// Added in Igor Pro 5.04.

// #define TELL_IGOR_WINDOW_STATUS 210			// Removed in XOP Toolkit 7 because the functionality is now handled internally by Igor Pro 7

// HR, 091202: These never worked and were never documented. They are not supported.
#define INCREMENT_WAVE_REF_COUNT 211			// Added in Igor Pro 6.00D00.
#define DECREMENT_WAVE_REF_COUNT 212			// Added in Igor Pro 6.00D00.

#define NOTICE2 213								// Added in Igor Pro 6.00B09.
#define GET_IGOR_CALLER_INFO 214				// Added in Igor Pro 6.00B09.
#define COMMAND3 215							// Added in Igor Pro 6.00B10.

#define GET_IGOR_RT_STACK_INFO 216				// Added in Igor Pro 6.02B01.

#define FETCH_NUMERIC_DATA_USING_VAR_NAME 217	// Added in Igor Pro 6.10B01.
#define FETCH_STRING_DATA_USING_VAR_NAME 218	// Added in Igor Pro 6.10B01.

#define SET_RUNTIME_STRING_VARIABLE_V2 219		// Added in Igor Pro 6.10B02.

#define NOTICE3 220								// Added in Igor Pro 6.10B04 for Bela Farago.

#define SET_IGOR_CALLBACK_METHOD 221			// Added in Igor Pro 6.20. For use by XOPSupport only.

#define GET_OPERATION_WAVE_REF 222				// Added in Igor Pro 6.20.
#define GET_OPERATION_DEST_WAVE 223				// Added in Igor Pro 6.20.

#define HOLD_WAVE 224							// Added in Igor Pro 6.20.
#define RELEASE_WAVE 225						// Added in Igor Pro 6.20.
	
#define SPECIAL_DIR_PATH 226					// Added in Igor Pro 6.20B03.
#define PARSE_FILE_PATH 227						// Added in Igor Pro 6.20B03.

#define HOLD_DATAFOLDER 228						// Added in Igor Pro 6.20B04.
#define RELEASE_DATAFOLDER 229					// Added in Igor Pro 6.20B04.

#define THREAD_PROCESSOR_COUNT 230				// Added in Igor Pro 6.23B01 but currently not implemented.
#define THREAD_GROUP_CREATE 231					// Added in Igor Pro 6.23B01 but currently not implemented.
#define THREAD_START 232						// Added in Igor Pro 6.23B01 but currently not implemented.
#define THREAD_GROUP_PUT_DF 233					// Added in Igor Pro 6.23B01.
#define THREAD_GROUP_GET_DF 234					// Added in Igor Pro 6.23B01.
#define THREAD_GROUP_WAIT 235					// Added in Igor Pro 6.23B01 but currently not implemented.
#define THREAD_GROUP_RETURN_VALUE 236			// Added in Igor Pro 6.23B01 but currently not implemented.
#define THREAD_GROUP_RELEASE 237				// Added in Igor Pro 6.23B01 but currently not implemented.

#define GET_IGOR_VERSION 238					// Added in Igor Pro 6.32B01

#define XOP_ACTUAL_MENUID_TO_MENUREF 239		// Added in Igor Pro 6.32B01
#define XOP_GET_MENU_INFO 240					// Added in Igor Pro 6.32B01
#define XOP_COUNT_MENU_ITEMS 241				// Added in Igor Pro 6.32B01
#define XOP_SHOW_MAIN_MENU 242					// Added in Igor Pro 6.32B01
#define XOP_HIDE_MAIN_MENU 243					// Added in Igor Pro 6.32B01
#define XOP_GET_MENU_ITEM_INFO 244				// Added in Igor Pro 6.32B01
#define XOP_GET_MENU_ITEM_TEXT 245				// Added in Igor Pro 6.32B01
#define XOP_SET_MENU_ITEM_TEXT 246				// Added in Igor Pro 6.32B01
#define XOP_APPEND_MENU_ITEM 247				// Added in Igor Pro 6.32B01
#define XOP_INSERT_MENU_ITEM 248				// Added in Igor Pro 6.32B01
#define XOP_DELETE_MENU_ITEM 249				// Added in Igor Pro 6.32B01
#define XOP_DELETE_MENU_ITEM_RANGE 250			// Added in Igor Pro 6.32B01
#define XOP_ENABLE_MENU_ITEM 251				// Added in Igor Pro 6.32B01
#define XOP_DISABLE_MENU_ITEM 252				// Added in Igor Pro 6.32B01
#define XOP_CHECK_MENU_ITEM 253					// Added in Igor Pro 6.32B01
#define XOP_FILL_MENU 254						// Added in Igor Pro 6.32B01
#define XOP_FILL_MENU_NO_META 255				// Added in Igor Pro 6.32B01

#define WAVE_TEXT_ENCODING 275					// Added in Igor Pro 7.00, requires XOP Toolkit 7 and Igor7
#define WAVE_MEMORY_SIZE 276					// Added in XOP Toolkit 6.40. Works with Igor Pro 3 or later.
#define CONVERT_TEXT_ENCODING 277				// Added in Igor Pro 7.00, requires XOP Toolkit 7 and Igor7
#define XOP_OPEN_FILE_DIALOG_2 288				// Added in Igor Pro 7.00, requires XOP Toolkit 7 and Igor7
#define XOP_SAVE_FILE_DIALOG_2 289				// Added in Igor Pro 7.00, requires XOP Toolkit 7 and Igor7
#define XOP_GET_CLIPBOARD_DATA 290				// Added in Igor Pro 7.00, requires XOP Toolkit 7 and Igor7
#define XOP_SET_CLIPBOARD_DATA 291				// Added in Igor Pro 7.00, requires XOP Toolkit 7 and Igor7

#define GET_IGOR_INTERNAL_INFO 292				// Added in Igor Pro 8.00, requires XOP Toolkit 7.03 and Igor8

#define MD_GETWAVEPOINTVALUE_SINT64 293			// Added in Igor Pro 7.03, requires XOP Toolkit 7.01
#define MD_SETWAVEPOINTVALUE_SINT64 294			// Added in Igor Pro 7.03, requires XOP Toolkit 7.01
#define MD_GETWAVEPOINTVALUE_UINT64 295			// Added in Igor Pro 7.03, requires XOP Toolkit 7.01
#define MD_SETWAVEPOINTVALUE_UINT64 296			// Added in Igor Pro 7.03, requires XOP Toolkit 7.01


/*	Text utility callback operation codes -- callback codes passed from XOP to host  */
#define XOPTUCODE 512
#define TUNEW 1 + XOPTUCODE
#define TUDISPOSE 2 + XOPTUCODE
#define TUDISPLAYSELECTION 3 + XOPTUCODE
#define TUGROW 4 + XOPTUCODE
#define TUZOOM 5 + XOPTUCODE
#define TUDRAWWINDOW 6 + XOPTUCODE
#define TUUPDATE 7 + XOPTUCODE
#define TUFIND 8 + XOPTUCODE
#define TUREPLACE 9 + XOPTUCODE
#define TUINDENTLEFT 10 + XOPTUCODE
#define TUINDENTRIGHT 11 + XOPTUCODE
#define TUCLICK 12 + XOPTUCODE
#define TUACTIVATE 13 + XOPTUCODE
#define TUIDLE 14 + XOPTUCODE
#define TUNULL 15 + XOPTUCODE
#define TUCOPY 16 + XOPTUCODE
#define TUCUT 17 + XOPTUCODE
#define TUPASTE 18 + XOPTUCODE
#define TUCLEAR 19 + XOPTUCODE
#define TUKEY 20 + XOPTUCODE
#define TUINSERT 21 + XOPTUCODE
#define TUDELETE 22 + XOPTUCODE
#define TUSETSELECT 23 + XOPTUCODE
#define TUFIXEDITMENU 24 + XOPTUCODE
#define TUFIXFILEMENU 25 + XOPTUCODE
#define TUUNDO 26 + XOPTUCODE
#define TUPRINT 27 + XOPTUCODE
#define TULENGTH 28 + XOPTUCODE
#define TULINES 29 + XOPTUCODE
#define TUSELSTART 30 + XOPTUCODE
#define TUSELEND 31 + XOPTUCODE
#define TUSELLENGTH 32 + XOPTUCODE
#define TUGETTEXT 33 + XOPTUCODE
#define TUFETCHTEXT 34 + XOPTUCODE
#define TUINSERTFILE 35 + XOPTUCODE
#define TUWRITEFILE 36 + XOPTUCODE
#define TUSFINSERTFILE 37 + XOPTUCODE
#define TUSFWRITEFILE 38 + XOPTUCODE
#define TUPAGESETUPDIALOG 39 + XOPTUCODE	/* added in Igor Pro 2.0D82 */
#define TUSELECTALL 40 + XOPTUCODE			/* added in Igor Pro 2.0D82 */
#define TUGETDOCINFO 41 + XOPTUCODE			/* added in Igor Pro 2.0D83 */
#define TUGETSELLOCS 42 + XOPTUCODE			/* added in Igor Pro 2.0D83 */
#define TUSETSELLOCS 43 + XOPTUCODE			/* added in Igor Pro 2.0D83 */
#define TUFETCHPARAGRAPHTEXT 44 + XOPTUCODE	/* added in Igor Pro 2.0D83 */
#define TUFETCHSELECTEDTEXT 45 + XOPTUCODE	/* added in Igor Pro 2.0D83 */
#define TUSETSTATUSAREA 46 + XOPTUCODE		/* added in Igor Pro 2.0D83 */
#define TUMOVE_TO_PREFERRED_POSITION 47 + XOPTUCODE	// Added in Igor Pro 3.10B03.
#define TUMOVE_TO_FULL_POSITION 48 + XOPTUCODE		// Added in Igor Pro 3.10B03.
#define TURETRIEVE 49 + XOPTUCODE					// Added in Igor Pro 3.10B03.
#define TUNEW2 50 + XOPTUCODE						// Added in Igor Pro 3.13B01.
#define TUFETCHTEXT2 51 + XOPTUCODE					// Added in Igor Pro 6.20.

#define HISTORY_DISPLAYSELECTION 100 + XOPTUCODE		// Added in Igor Pro 6.00B10.
#define HISTORY_INSERT 101 + XOPTUCODE					// Added in Igor Pro 6.00B10.
#define HISTORY_DELETE 102 + XOPTUCODE					// Added in Igor Pro 6.00B10.
#define HISTORY_LINES 103 + XOPTUCODE					// Added in Igor Pro 6.00B10.
#define HISTORY_GETSELLOCS 104 + XOPTUCODE				// Added in Igor Pro 6.00B10.
#define HISTORY_SETSELLOCS 105 + XOPTUCODE				// Added in Igor Pro 6.00B10.
#define HISTORY_FETCHPARAGRAPHTEXT 106 + XOPTUCODE		// Added in Igor Pro 6.00B10.
#define HISTORY_FETCHTEXT 107 + XOPTUCODE				// Added in Igor Pro 6.00B10.
#define FIRST_XOP_HISTORY_MESSAGE 100 + XOPTUCODE
#define LAST_XOP_HISTORY_MESSAGE 107 + XOPTUCODE

// Window callback operation codes
enum {
	XOP_WINDOW_CALLBACK_START=1000,
	CREATE_XOP_WINDOW=1000,						// Added in Igor Pro 7 and XOP Toolkit 7
	KILL_XOP_WINDOW,							// Added in Igor Pro 7 and XOP Toolkit 7
	GET_IGOR_WINDOW_INFO,						// Added in Igor Pro 7 and XOP Toolkit 7
	SET_XOP_WINDOW_INFO,						// Added in Igor Pro 7 and XOP Toolkit 7
	GET_INDEXED_XOP_WINDOW,						// Added in Igor Pro 7 and XOP Toolkit 7
	GET_NEXT_XOP_WINDOW,						// Added in Igor Pro 7 and XOP Toolkit 7
	GET_ACTIVE_IGOR_WINDOW,						// Added in Igor Pro 7 and XOP Toolkit 7
	GET_NAMED_IGOR_WINDOW,						// Added in Igor Pro 7 and XOP Toolkit 7
	IS_IGOR_WINDOW_ACTIVE,						// Added in Igor Pro 7 and XOP Toolkit 7
	IS_IGOR_WINDOW_VISIBLE,						// Added in Igor Pro 7 and XOP Toolkit 7
	SHOW_IGOR_WINDOW,							// Added in Igor Pro 7 and XOP Toolkit 7
	HIDE_IGOR_WINDOW,							// Added in Igor Pro 7 and XOP Toolkit 7
	SHOW_AND_ACTIVATE_IGOR_WINDOW,				// Added in Igor Pro 7 and XOP Toolkit 7
	HIDE_AND_DEACTIVATE_IGOR_WINDOW,			// Added in Igor Pro 7 and XOP Toolkit 7
	GET_IGOR_WINDOW_TITLE,						// Added in Igor Pro 7 and XOP Toolkit 7
	SET_IGOR_WINDOW_TITLE,						// Added in Igor Pro 7 and XOP Toolkit 7
	GET_IGOR_WINDOW_POSITION_AND_STATE,			// Added in Igor Pro 7 and XOP Toolkit 7
	SET_IGOR_WINDOW_POSITION_AND_STATE,			// Added in Igor Pro 7 and XOP Toolkit 7
	GET_IGOR_WINDOW_IGOR_POSITION_AND_STATE,	// Added in Igor Pro 7 and XOP Toolkit 7
	SET_IGOR_WINDOW_IGOR_POSITION_AND_STATE,	// Added in Igor Pro 7 and XOP Toolkit 7
	TRANSFORM_IGOR_WINDOW_COORDINATES,			// Added in Igor Pro 7 and XOP Toolkit 7
	XOP_WINDOW_CALLBACK_END,
};

// Container callback operation codes
enum {
	XOP_CONTAINER_CALLBACK_START=1100,
	CREATE_XOP_CONTAINER=1100,					// Added in Igor Pro 7 and XOP Toolkit 7
	KILL_XOP_CONTAINER,							// Added in Igor Pro 7 and XOP Toolkit 7
	GET_ACTIVE_IGOR_CONTAINER,					// Added in Igor Pro 7 and XOP Toolkit 7
	SET_ACTIVE_IGOR_CONTAINER,					// Added in Igor Pro 7 and XOP Toolkit 7
	GET_NAMED_IGOR_CONTAINER,					// Added in Igor Pro 7 and XOP Toolkit 7
	GET_PARENT_IGOR_CONTAINER,					// Added in Igor Pro 7 and XOP Toolkit 7
	GET_CHILD_IGOR_CONTAINER,					// Added in Igor Pro 7 and XOP Toolkit 7
	GET_INDEXED_XOP_CONTAINER,					// Added in Igor Pro 7 and XOP Toolkit 7
	GET_IGOR_CONTAINER_PATH,					// Added in Igor Pro 7 and XOP Toolkit 7
	GET_IGOR_CONTAINER_INFO,					// Added in Igor Pro 7 and XOP Toolkit 7
	SET_IGOR_CONTAINER_INFO,					// Added in Igor Pro 7 and XOP Toolkit 7
	SEND_CONTAINER_NSEVENT_TO_IGOR,				// Added in Igor Pro 7 and XOP Toolkit 7
	SEND_CONTAINER_HWND_EVENT_TO_IGOR,			// Added in Igor Pro 7 and XOP Toolkit 7
	SET_XOP_CONTAINER_MOUSE_CURSOR,				// Added in Igor Pro 7 and XOP Toolkit 7
	XOP_CONTAINER_CALLBACK_END,
};


// *** File loader flag bit definitions ***
#define FILE_LOADER_OVERWRITE 1				/* /O means overwrite */
#define FILE_LOADER_DOUBLE_PRECISION 2		/* /D means double precision */
#define FILE_LOADER_COMPLEX 4				/* /C means complex */
#define FILE_LOADER_INTERACTIVE 8			/* /I means interactive -- use open dialog */
#define FILE_LOADER_AUTONAME 16				/* /A means autoname wave (/N is equivalent to /O/A) */
#define FILE_LOADER_PATH 32					/* /P means use symbolic path */
#define FILE_LOADER_QUIET 64				/* /Q means quiet -- no messages in history */
#define FILE_LOADER_LAST_FLAG 64			/* This allows an XOP to use other bits in flag for its own purposes */


/* Miscellaneous #defines */
#define MENU_STRINGS 1101					/* STR# defining XOPs menu entry if any */
#define XOP_INFO 1100						/* XOPI resource of various XOP info */
#define XOP_WIND 1100						/* start XOP window resource IDs from here */
#define XOP_SUBMENU 100						/* start XOP menu resource IDs from here */
#define XOP_CMDS 1100						/* ID for XOPC resource describing commands */
#define XOP_MENUS 1100						/* ID for XOPM resource describing menus */
#define XSET_ID 1100						/* ID for XSET resource containing settings */

// These relate to an optional STR# 1101 resource in which IGOR may look for certain strings.
#define XOP_MISC_STR_ID 1101
#define XOP_MISC_STR_MENU_ID_INDEX 1		// Menu ID number if XOP is adding menu item via STR# 1101 method.
#define XOP_MISC_STR_MENU_ITEM_INDEX 2		// Menu item text if XOP is adding menu item via STR# 1101 method.
#define XOP_MISC_STR_HELPFILE_NAME_INDEX 3	// Name of XOP's help file (including ".ihf" index on Windows).

// This relates to the optional STR# 1160 resource which defines a target window type.
#define XOP_TARGET_WINDOW_TYPE_ID 1160
#define XOP_TARGET_WINDOW_SINGULAR_INDEX 1	// Human friendly singular name of the window type (e.g., Surface Plot).
#define XOP_TARGET_WINDOW_PLURAL_INDEX 2	// Human friendly plural name of the window type (e.g., Surface Plots).
#define XOP_TARGET_WINDOW_KEYWORD_INDEX 3	// Keyword used for window recreation macro declaration (e.g., SurfacePlot) or "" if none.
#define XOP_TARGET_STYLE_KEYWORD_INDEX 4	// Keyword used for window style macro declaration (e.g., SurfacePlotStyle) or "" if none.

// Status codes used with TellIgorWindowStatus
#define WINDOW_STATUS_DID_HIDE 1
#define WINDOW_STATUS_DID_SHOW 2
#define WINDOW_STATUS_ACTIVATED 3
#define WINDOW_STATUS_DEACTIVATED 4
#define WINDOW_STATUS_ABOUT_TO_KILL 5
#define WINDOW_STATUS_DID_KILL 6			// Added in 6.04B01. JP080401.

#pragma pack()	// Reset structure alignment to default.

#ifdef __cplusplus
}
#endif

#endif	// XOP_H_INCLUDED
