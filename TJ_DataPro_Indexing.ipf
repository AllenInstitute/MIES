#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function MakeIndexingStorageWaves(panelTitle)
string panelTitle
variable NoOfTTLs = TotNoOfControlType("check", "TTL",panelTitle)
variable NoOfDACs = TotNoOfControlType("check", "DA",panelTitle)

make/o/n=(4,NoOfTTLs) TTLIndexingStorageWave
make/o/n=(4,NoOfDACs) DACIndexingStorageWave

End

Function StoreStartFinishForIndexing(panelTitle)
string panelTitle
//Wave_DA_00
//Popup_DA_IndexEnd_00
wave DACIndexingStorageWave
wave TTLIndexingStorageWave
variable i 
variable NoOfTTLs = TotNoOfControlType("check", "TTL",panelTitle)
variable NoOfDACs = TotNoOfControlType("check", "DA",panelTitle)
string TTLPopUpNameIndexStart, DACPopUpNameIndexStart, TTLPopUpNameIndexEnd, DACPopUpNameIndexEnd

For(i=0;i<NoOfDACS;i+=1)

if(i<10)
DACPopUpNameIndexStart = "Wave_DA_0"+num2str(i)
controlInfo/w=$panelTitle $DACPopUpNameIndexStart
DACIndexingStorageWave[0][i]=v_value
DACPopUpNameIndexEnd = "Popup_DA_IndexEnd_0"+num2str(i)
controlInfo/w=$panelTitle $DACPopUpNameIndexEnd
DACIndexingStorageWave[1][i]=v_value
else
DACPopUpNameIndexStart = "Wave_DA_"+num2str(i)
controlInfo/w=$panelTitle $DACPopUpNameIndexStart
DACIndexingStorageWave[0][i]=v_value
DACPopUpNameIndexEnd = "Popup_DA_IndexEnd_"+num2str(i)
controlInfo/w=$panelTitle $DACPopUpNameIndexEnd
DACIndexingStorageWave[1][i]=v_value
endif
endfor 

For(i=0;i<NoOfTTLs;i+=1)
if(i<10)
TTLPopUpNameIndexStart = "Wave_TTL_0"+num2str(i)
controlInfo/w=$panelTitle $TTLPopUpNameIndexStart
TTLIndexingStorageWave[0][i]=v_value
TTLPopUpNameIndexEnd = "Popup_TTL_IndexEnd_0"+num2str(i)
controlInfo/w=$panelTitle $TTLPopUpNameIndexEnd
TTLIndexingStorageWave[1][i]=v_value
else
TTLPopUpNameIndexStart = "Wave_TTL_"+num2str(i)
controlInfo/w=$panelTitle $TTLPopUpNameIndexStart
TTLIndexingStorageWave[0][i]=v_value
TTLPopUpNameIndexEnd = "Popup_TTL_IndexEnd_"+num2str(i)
controlInfo/w=$panelTitle $TTLPopUpNameIndexEnd
TTLIndexingStorageWave[1][i]=v_value
endif
endfor


End

Function IndexingDoIt(panelTitle)
string panelTitle
wave DACIndexingStorageWave
wave TTLIndexingStorageWave
variable i 
variable NoOfTTLs = TotNoOfControlType("check", "TTL", panelTitle)
variable NoOfDACs = TotNoOfControlType("check", "DA",panelTitle)
variable CurrentPopUpMenuNo
string DACPopUpName, TTLPopUpName


for(i=0;i<NoOfDACS;i+=1)
	if(DACIndexingStorageWave[1][i]>DACIndexingStorageWave[0][i])
		if(i<10)
		DACPopUpName="Wave_DA_0"+num2str(i)
		controlinfo/w=$panelTitle $DACPopUpName
			if(v_value<DACIndexingStorageWave[1][i])
			PopUpMenu $DACPopUpName win=$panelTitle, mode=(v_value+1)
			else
			PopUpMenu $DACPopUpName win=$panelTitle, mode=DACIndexingStorageWave[0][i]
			endif
		else
		DACPopUpName="Wave_DA_"+num2str(i)
		controlinfo/w=$panelTitle $DACPopUpName
			if(v_value<DACIndexingStorageWave[1][i])
			PopUpMenu $DACPopUpName win=$panelTitle, mode=(v_value+1)
			else
			PopUpMenu $DACPopUpName win=$panelTitle, mode=DACIndexingStorageWave[0][i]
			endif
		endif
	endif
	
	if(DACIndexingStorageWave[1][i]<DACIndexingStorageWave[0][i])
		if(i<10)
		DACPopUpName="Wave_DA_0"+num2str(i)
		controlinfo/w=$panelTitle $DACPopUpName
			if(v_value>DACIndexingStorageWave[1][i])
			PopUpMenu $DACPopUpName win=$panelTitle, mode=(v_value-1)
			else
			PopUpMenu $DACPopUpName win=$panelTitle, mode=DACIndexingStorageWave[0][i]
			endif
		else
		DACPopUpName="Wave_DA_"+num2str(i)
		controlinfo/w=$panelTitle $DACPopUpName
			if(v_value>DACIndexingStorageWave[1][i])
			PopUpMenu $DACPopUpName win=$panelTitle, mode=(v_value-1)
			else
			PopUpMenu $DACPopUpName win=$panelTitle, mode=DACIndexingStorageWave[0][i]
			endif
		endif
	endif
endfor

for(i=0;i<NoOfTTLS;i+=1)
	if(TTLIndexingStorageWave[1][i]>TTLIndexingStorageWave[0][i])
		if(i<10)
		TTLPopUpName="Wave_TTL_0"+num2str(i)
		controlinfo/w=$panelTitle $TTLPopUpName
			if(v_value<TTLIndexingStorageWave[1][i])
			PopUpMenu $TTLPopUpName win=$panelTitle, mode=(v_value+1)
			else
			PopUpMenu $TTLPopUpName win=$panelTitle, mode=TTLIndexingStorageWave[0][i]
			endif
		else
		TTLPopUpName="Wave_TTL_"+num2str(i)
		controlinfo/w=$panelTitle $TTLPopUpName
			if(v_value<TTLIndexingStorageWave[1][i])
			PopUpMenu $TTLPopUpName win=$panelTitle, mode=(v_value+1)
			else
			PopUpMenu $TTLPopUpName win=$panelTitle, mode=TTLIndexingStorageWave[0][i]
			endif
		endif
	endif
	
	if(TTLIndexingStorageWave[1][i]<TTLIndexingStorageWave[0][i])
		if(i<10)
		TTLPopUpName="Wave_TTL_0"+num2str(i)
		controlinfo/w=$panelTitle $TTLPopUpName
			if(v_value>TTLIndexingStorageWave[1][i])
			PopUpMenu $TTLPopUpName win=$panelTitle, mode=(v_value-1)
			else
			PopUpMenu $TTLPopUpName win=$panelTitle, mode=TTLIndexingStorageWave[0][i]
			endif
		else
		TTLPopUpName="Wave_TTL_"+num2str(i)
		controlinfo/w=$panelTitle $TTLPopUpName
			if(v_value>TTLIndexingStorageWave[1][i])
			PopUpMenu $TTLPopUpName win=$panelTitle, mode=(v_value-1)
			else
			PopUpMenu $TTLPopUpName win=$panelTitle, mode=TTLIndexingStorageWave[0][i]
			endif
		endif
	endif
endfor

End