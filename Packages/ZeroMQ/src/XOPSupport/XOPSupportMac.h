// This file contains equates and prototypes that are needed on Macintosh only.


#ifdef __cplusplus
extern "C" {						/* This allows C++ to call the XOPSupport routines */
#endif

// Misc utilities.
// IsMacOSX has been removed. Use #ifdef MACIGOR.
#ifdef IGOR64
	/*	These are defined in TextUtils.h and in the CarbonCore framework but
		is not available in 64 bits. So this is a version of it for 64 bits.
	*/
	void CopyPascalStringToC(ConstStr255Param source, char* dest);
	void CopyCStringToPascal(const char* source, Str255 dest);
#endif
void debugstr(const char* text);


/* Resource routines (in XOPSupportMac.c) */
int XOPRefNum(void);
#ifdef IGOR64
	// In 32-bits this is provided by the CarbonCore framework and declared in TextUtils.h
	void GetIndString(Str255 theString, short strListID, short index);
#endif
Handle GetXOPResource(int resType, int resID);
Handle GetXOPNamedResource(int resType, const char* name);

#if !defined(ALLOW_MAC_OS_NATIVE_MEMORY_ROUTINES)
	/*	This causes a link error when compiling an for Macintosh if you use Mac OS native
		memory management routines. To run with 64-bit MacIGOR 8.00 or later, you need to
		make source code changes and recompile.
		
		For details, See "WM Memory XOPSupport Routines" in XOPMemory.c.
	*/
	#define NewHandle XOP_using_obsolete_memory_routines
	#define GetHandleSize XOP_using_obsolete_memory_routines
	#define SetHandleSize XOP_using_obsolete_memory_routines
	#define HandToHand XOP_using_obsolete_memory_routines
	#define HandAndHand XOP_using_obsolete_memory_routines
	#define DisposeHandle XOP_using_obsolete_memory_routines
	#define NewPtr XOP_using_obsolete_memory_routines
	#define GetPtrSize XOP_using_obsolete_memory_routines
	#define SetPtrSize XOP_using_obsolete_memory_routines
	#define PtrToHand XOP_using_obsolete_memory_routines
	#define PtrAndHand XOP_using_obsolete_memory_routines
	#define DisposePtr XOP_using_obsolete_memory_routines
	#define MemError XOP_using_obsolete_memory_routines
#endif

#ifdef __cplusplus
}
#endif
