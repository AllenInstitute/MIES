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


//===================================================================================
//NEW INDEXING FUNCTIONS FOR USE WITH 2D SETS
//===================================================================================
Function Index_MaxNoOfTrials(PanelTitle)
	string panelTitle
	variable MaxNoOfTrials = 0
	string DAChannelStatusList = ControlStatusListString("DA", "check",panelTitle)
	string TTLChannelStatusList = ControlStatusListString("TTL", "check",panelTitle)
	variable i = 0
	
	do
		if(str2num(stringfromlist(i,DAChannelStatusList,";"))==1)
		MaxNoOfTrials=max(MaxNoOfTrials, Index_NumberOfTrialsAcrossSets(PanelTitle, i, 0))
		endif
	
	i+=1
	while(i<itemsinlist(DAChannelStatusList,";"))
	
	do
		if(str2num(stringfromlist(i,TTLChannelStatusList,";"))==1)
		MaxNoOfTrials=max(MaxNoOfTrials, Index_NumberOfTrialsAcrossSets(PanelTitle, i, 1))
		endif
	
	i+=1
	while(i<itemsinlist(TTLChannelStatusList,";"))
	
	return MaxNoOfTrials
End

Function Index_NumberOfTrialsAcrossSets(PanelTitle, PopUpMenuNumber, DAorTTL)// determines the number of trials for a DA or TTL channel
	string PanelTitle
	variable PopUpMenuNumber, DAorTTL//DA = 0, TTL = 1	
	variable NumberOfTrialsAcrossSets
	variable IndexStart, IndexEnd
	string DAorTTL_cntrlName = "", DAorTTL_indexEndName = "", setname = ""
	
	if(DAorTTL==0)// determine control names based on DA or TTL 
		DAorTTL_cntrlName = "Wave_DA_0" + num2str(PopUpMenuNumber)
		DAorTTL_indexEndName = "Popup_DA_IndexEnd_0" + num2str(PopUpMenuNumber)
	endif

	if(DAorTTL==1)
		DAorTTL_cntrlName = "Wave_TTL_0" + num2str(PopUpMenuNumber)
		DAorTTL_indexEndName = "Popup_TTL_IndexEnd_0" + num2str(PopUpMenuNumber)
	endif
	controlinfo/w=$panelTitle $DAorTTL_cntrlName// check if indexing is activated
	IndexStart=v_value
	
	controlinfo/w=$panelTitle Check_DataAcq1_Indexing
	if(v_value==0)
		IndexEnd=indexStart
	else
		controlinfo/w=$panelTitle $DAorTTL_indexEndName
		IndexEnd=v_value 
	endif
	
	string setList = getuserdata(PanelTitle, DAorTTL_cntrlName, "menuexp")
	variable i = (min(indexstart, indexend)-3)
	do
		Setname=stringfromlist(i, setList,";")
		NumberOfTrialsAcrossSets+=Index_NumberOfTrialsInSet(PanelTitle, SetName, DAorTTL)
		i+=1
	while(i<(max(indexstart, indexend)-2))
	return NumberOfTrialsAcrossSets

End

Function Index_NumberOfTrialsInSet(PanelTitle, SetName, DAorTTL)
	string PanelTitle, SetName
	variable DAorTTL//DA = 0, TTL = 1
	string WavePath 
	
	if(DAorTTL==0)// to determine location
	WavePath="root:WaveBuilder:SavedStimulusSets:DA:"
	endif
	
	if(DAorTTL==1)
	WavePath="root:WaveBuilder:SavedStimulusSets:TTL:"
	endif
	
	string NameOfWaveSelectedInPopUP = WavePath + setName
	variable NumberOfTrialsInSet= DimSize($NameOfWaveSelectedInPopUP, 1 )
	return NumberOfTrialsInSet
End


