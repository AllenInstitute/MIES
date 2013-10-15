#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function MakeIndexingStorageWaves()
variable NoOfTTLs = TotNoOfControlType("check", "TTL")
variable NoOfDACs = TotNoOfControlType("check", "DA")

make/o/n=(4,NoOfTTLs) TTLIndexingStorageWave
make/o/n=(4,NoOfDACs) DACIndexingStorageWave

End

Function StoreStartFinishForIndexing()
//Wave_DA_00
//Popup_DAC_IndexEnd_00
wave DACIndexingStorageWave
wave TTLIndexingStorageWave
variable i 
variable NoOfTTLs = TotNoOfControlType("check", "TTL")
variable NoOfDACs = TotNoOfControlType("check", "DA")
string TTLPopUpNameIndexStart, DACPopUpNameIndexStart, TTLPopUpNameIndexEnd, DACPopUpNameIndexEnd

For(i=0;i<NoOfDACS;i+=1)

if(i<10)
DACPopUpNameIndexStart = "Wave_DA_0"+num2str(i)
controlInfo/w=DataPro_ITC1600 $DACPopUpNameIndexStart
DACIndexingStorageWave[0][i]=v_value
DACPopUpNameIndexEnd = "Popup_DAC_IndexEnd_0"+num2str(i)
controlInfo/w=DataPro_ITC1600 $DACPopUpNameIndexEnd
DACIndexingStorageWave[1][i]=v_value
else
DACPopUpNameIndexStart = "Wave_DA_"+num2str(i)
controlInfo/w=DataPro_ITC1600 $DACPopUpNameIndexStart
DACIndexingStorageWave[0][i]=v_value
DACPopUpNameIndexEnd = "Popup_DAC_IndexEnd_"+num2str(i)
controlInfo/w=DataPro_ITC1600 $DACPopUpNameIndexEnd
DACIndexingStorageWave[1][i]=v_value
endif
endfor 

For(i=0;i<NoOfTTLs;i+=1)
if(i<10)
TTLPopUpNameIndexStart = "Wave_TTL_0"+num2str(i)
controlInfo/w=DataPro_ITC1600 $TTLPopUpNameIndexStart
TTLIndexingStorageWave[0][i]=v_value
TTLPopUpNameIndexEnd = "Popup_TTL_IndexEnd_0"+num2str(i)
controlInfo/w=DataPro_ITC1600 $TTLPopUpNameIndexEnd
TTLIndexingStorageWave[1][i]=v_value
else
TTLPopUpNameIndexStart = "Wave_TTL_"+num2str(i)
controlInfo/w=DataPro_ITC1600 $TTLPopUpNameIndexStart
TTLIndexingStorageWave[0][i]=v_value
TTLPopUpNameIndexEnd = "Popup_TTL_IndexEnd_"+num2str(i)
controlInfo/w=DataPro_ITC1600 $TTLPopUpNameIndexEnd
TTLIndexingStorageWave[1][i]=v_value
endif
endfor


End

Function IndexingDoIt()
wave DACIndexingStorageWave
wave TTLIndexingStorageWave
variable i 
variable NoOfTTLs = TotNoOfControlType("check", "TTL")
variable NoOfDACs = TotNoOfControlType("check", "DA")
variable CurrentPopUpMenuNo
string DACPopUpName, TTLPopUpName


for(i=0;i<NoOfDACS;i+=1)
	if(DACIndexingStorageWave[1][i]>DACIndexingStorageWave[0][i])
		if(i<10)
		DACPopUpName="Wave_DA_0"+num2str(i)
		controlinfo/w=DataPro_ITC1600 $DACPopUpName
			if(v_value<DACIndexingStorageWave[1][i])
			PopUpMenu $DACPopUpName win=DataPro_ITC1600, mode=(v_value+1)
			else
			PopUpMenu $DACPopUpName win=DataPro_ITC1600, mode=DACIndexingStorageWave[0][i]
			endif
		else
		DACPopUpName="Wave_DA_"+num2str(i)
		controlinfo/w=DataPro_ITC1600 $DACPopUpName
			if(v_value<DACIndexingStorageWave[1][i])
			PopUpMenu $DACPopUpName win=DataPro_ITC1600, mode=(v_value+1)
			else
			PopUpMenu $DACPopUpName win=DataPro_ITC1600, mode=DACIndexingStorageWave[0][i]
			endif
		endif
	endif
	
	if(DACIndexingStorageWave[1][i]<DACIndexingStorageWave[0][i])
		if(i<10)
		DACPopUpName="Wave_DA_0"+num2str(i)
		controlinfo/w=DataPro_ITC1600 $DACPopUpName
			if(v_value>DACIndexingStorageWave[1][i])
			PopUpMenu $DACPopUpName win=DataPro_ITC1600, mode=(v_value-1)
			else
			PopUpMenu $DACPopUpName win=DataPro_ITC1600, mode=DACIndexingStorageWave[0][i]
			endif
		else
		DACPopUpName="Wave_DA_"+num2str(i)
		controlinfo/w=DataPro_ITC1600 $DACPopUpName
			if(v_value>DACIndexingStorageWave[1][i])
			PopUpMenu $DACPopUpName win=DataPro_ITC1600, mode=(v_value-1)
			else
			PopUpMenu $DACPopUpName win=DataPro_ITC1600, mode=DACIndexingStorageWave[0][i]
			endif
		endif
	endif
endfor

for(i=0;i<NoOfTTLS;i+=1)
	if(TTLIndexingStorageWave[1][i]>TTLIndexingStorageWave[0][i])
		if(i<10)
		TTLPopUpName="Wave_TTL_0"+num2str(i)
		controlinfo/w=DataPro_ITC1600 $TTLPopUpName
			if(v_value<TTLIndexingStorageWave[1][i])
			PopUpMenu $TTLPopUpName win=DataPro_ITC1600, mode=(v_value+1)
			else
			PopUpMenu $TTLPopUpName win=DataPro_ITC1600, mode=TTLIndexingStorageWave[0][i]
			endif
		else
		TTLPopUpName="Wave_TTL_"+num2str(i)
		controlinfo/w=DataPro_ITC1600 $TTLPopUpName
			if(v_value<TTLIndexingStorageWave[1][i])
			PopUpMenu $TTLPopUpName win=DataPro_ITC1600, mode=(v_value+1)
			else
			PopUpMenu $TTLPopUpName win=DataPro_ITC1600, mode=TTLIndexingStorageWave[0][i]
			endif
		endif
	endif
	
	if(TTLIndexingStorageWave[1][i]<TTLIndexingStorageWave[0][i])
		if(i<10)
		TTLPopUpName="Wave_TTL_0"+num2str(i)
		controlinfo/w=DataPro_ITC1600 $TTLPopUpName
			if(v_value>TTLIndexingStorageWave[1][i])
			PopUpMenu $TTLPopUpName win=DataPro_ITC1600, mode=(v_value-1)
			else
			PopUpMenu $TTLPopUpName win=DataPro_ITC1600, mode=TTLIndexingStorageWave[0][i]
			endif
		else
		TTLPopUpName="Wave_TTL_"+num2str(i)
		controlinfo/w=DataPro_ITC1600 $TTLPopUpName
			if(v_value>TTLIndexingStorageWave[1][i])
			PopUpMenu $TTLPopUpName win=DataPro_ITC1600, mode=(v_value-1)
			else
			PopUpMenu $TTLPopUpName win=DataPro_ITC1600, mode=TTLIndexingStorageWave[0][i]
			endif
		endif
	endif
endfor

End