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

#ifdef __cplusplus
}
#endif
