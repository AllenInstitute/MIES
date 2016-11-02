/*	This file contains routines that are Macintosh-specific.
	This file is used only when compiling for Macintosh.
*/

#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h

// IsMacOSX has been removed. Use #ifdef MACIGOR.

#ifdef IGOR64	// [
/*	CopyPascalStringToC is defined in TextUtils.h and in the CarbonCore framework but
	is not available in 64 bits. So this is a version of it for 64 bits.
*/
void
CopyPascalStringToC(ConstStr255Param source, char* dest)
{
	int count, i;
	char* p;
	
	count = *source++;
	p = dest;
	for(i=0; i<count; i+=1)
		*p++ = *source++;
	*p = 0;
}

/*	CopyCStringToPascal is defined in TextUtils.h and in the CarbonCore framework but
	is not available in 64 bits. So this is a version of it for 64 bits.
*/
void
CopyCStringToPascal(const char* source, Str255 dest)
{
	int count, i;
	unsigned char* p;
	
	count = strlen(source);
	if (count > 255)
		count = 255;
	p = dest;
	*p++ = count;
	for(i=0; i<count; i+=1)
		*p++ = *source++;
}
#endif			// IGOR64 ]

void
debugstr(const char* message)			// Sends debug message to low level debugger (e.g., Macsbug).
{
	char ctemp[256];
	unsigned char ptemp[256];
	int len;
	
	len = strlen(message);
	if (len >= sizeof(ctemp))
		len = sizeof(ctemp)-1;
	strncpy(ctemp, message, len);
	ctemp[len] = 0;
	CopyCStringToPascal(ctemp, ptemp);
	DebugStr(ptemp);
}

/*	Resource Routines -- for dealing with resources

	These routines are for accessing Macintosh resource forks.
	There are no Windows equivalent routines, so these routines can't be used in
	Windows or cross-platform XOPs.
*/

/*	XOPRefNum()

	Returns XOP's resource file reference number.
	
	Thread Safety: XOPRefNum is thread-safe but there is little that you can do with it that is thread-safe.
*/
int
XOPRefNum(void)
{
	return((*(*XOPRecHandle)->stuffHandle)->xopRefNum);
}

#ifdef IGOR64	// [
/*	GetIndString is defined in TextUtils.h and in the CarbonCore framework but
	is not available in 64 bits. So this is a version of it for 64 bits.
*/
void
GetIndString(Str255 theString, short strListID, short index)
{
	Handle h;
	int numStrings;
	char* p;
	
	*theString = 0;
	h = GetResource('STR#', strListID);
	if (h == NULL)
		return;
	
	numStrings = *(short*)(*h);				// First short in resource is count of strings.
	if (index<1 || index>numStrings)
		return;
	p = *h + 2;								// Points to first Pascal string.
	while(index > 1) {
		p += *p + 1;						// Skip this string.
		index -= 1;
	}
	memcpy(theString, p, *p + 1);
}
#endif			// IGOR64 ]

/*	GetXOPResource(resType, resID)

	Tries to get specified handle from XOP's resource fork.
	Does not search any other resource forks and does not change curResFile.
	
	Thread Safety: GetXOPResource is not thread-safe.
*/
Handle
GetXOPResource(int resType, int resID)
{
	Handle rHandle;
	int curResNum;
	
	curResNum = CurResFile();
	UseResFile(XOPRefNum());
	rHandle = Get1Resource(resType, resID);
	UseResFile(curResNum);
	return(rHandle);
}

/*	GetXOPNamedResource(resType, name)

	Tries to get specified handle from XOP's resource fork.
	Does not search any other resource forks and does not change curResFile.
	
	Thread Safety: GetXOPNamedResource is not thread-safe.
*/
Handle
GetXOPNamedResource(int resType, const char* name)
{
	Handle rHandle;
	unsigned char pName[256];
	int curResNum;
	
	curResNum = CurResFile();
	UseResFile(XOPRefNum());
	CopyCStringToPascal(name, pName);
	rHandle = Get1NamedResource(resType, pName);
	UseResFile(curResNum);
	return rHandle;
}
