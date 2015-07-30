#pragma rtGlobals=1		// Use modern global access method.

// Taken from http://www.igorexchange.com/node/2755

// This disables the use of BitBlt (Windows) or ScrollRect (Macintosh) when scrolling
// text or tables. Normally it is not needed. Use it if your video card does not scroll right.

static Function IgorStartOrNewHook(igorApplicationNameStr)
	String igorApplicationNameStr

	if (IgorVersion() >= 6.23)
		String cmd = "SetIgorOption ScrollingMode=1"
		Execute cmd
	endif
End
