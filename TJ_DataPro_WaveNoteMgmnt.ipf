#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function WriteWaveNote(theWave, theNote, theValue)
	Wave theWave
	String theNote, theValue
	Variable start, first, last
	String oldnote, newnote
	oldnote=note(theWave)
	start=strsearch(oldnote,theNote,0)
	first=strsearch(oldnote,"=",start)
	last=strsearch(oldnote,"\r", first)
	if (start<0)
		sprintf newnote, "%s=%s", theNote, theValue
	else
		sprintf newnote, "%s%s%s", oldnote[0,first], theValue,oldnote[last,strlen(oldnote)]
		Note /K theWave
	endif
	Note theWave, newnote
End

Function GetWaveNoteNumber(theWave, theNote)
	Wave theWave
	String theNote
	Variable start, theValue
	String oldnote, newnote
	oldnote=note(theWave)
	start=strsearch(oldnote,theNote,0)
	if (start<0)
		if (cmpstr(theNote,"BASELINE")==0)
			Wavestats /Q/R=[0,100] theWave
			theValue=V_avg
		else
			theValue=0
		endif
		sprintf newnote, "%s=%f", theNote, theValue
		Note theWave, newnote
	endif
	theValue=NumberByKey(theNote, Note(theWave), "=", "\r")
	return theValue
End

Function /S GetWaveNoteString(theWave, theNote)
	Wave theWave
	String theNote
	Variable start
	String theValue, oldnote, newnote
	oldnote=note(theWave)
	start=strsearch(oldnote,theNote,0)
	if (start<0)
		sprintf newnote, "%s=0", theNote
		Note theWave, newnote
	endif
	theValue=StringByKey(theNote, Note(theWave), "=", "\r")
	return theValue
End