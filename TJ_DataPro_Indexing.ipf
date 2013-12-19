#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function MakeIndexingStorageWaves(panelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)// determines ITC device 
	variable NoOfTTLs = TotNoOfControlType("check", "TTL",panelTitle)
	variable NoOfDACs = TotNoOfControlType("check", "DA",panelTitle)
	make/o/n=(4,NoOfTTLs) $WavePath+":TTLIndexingStorageWave"
	make/o/n=(4,NoOfDACs) $WavePath+":DACIndexingStorageWave"
End

Function StoreStartFinishForIndexing(panelTitle)
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)// determines ITC device 
	wave DACIndexingStorageWave = $wavePath+":DACIndexingStorageWave"
	wave TTLIndexingStorageWave = $wavePath+":TTLIndexingStorageWave"
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

Function IndexingDoIt(panelTitle)// for locked indexing, indexes all active channels at once
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)// determines ITC device 
	wave DACIndexingStorageWave = $wavePath+":DACIndexingStorageWave"
	wave TTLIndexingStorageWave = $wavePath+":TTLIndexingStorageWave"
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

Function IndexSingleChannel(panelTitle, DAorTTL, ChannelNo)// indexes a single channel - used when indexing is unlocked
	string panelTitle
	variable DAorTTL, ChannelNo
	variable i = ChannelNo
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)// determines ITC device 
	wave DACIndexingStorageWave = $wavePath+":DACIndexingStorageWave"
	wave TTLIndexingStorageWave = $wavePath+":TTLIndexingStorageWave"
	string DACPopUpName, TTLPopUpName
	
	if(DAorTTL==0)
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
	endif
	
	if(DAorTTL==1)
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
	endif
End
//===================================================================================
//NEW INDEXING FUNCTIONS FOR USE WITH 2D SETS
//===================================================================================

Function Index_MaxNoOfSweeps(PanelTitle, IndexOverRide)// determine the max number of sweeps in the largest start set on active (checked) DA or TTL channels
	string panelTitle
	variable IndexOverRide// some Functions that call this function only want the max number of steps in the start (active) set, when indexing is on. 1 = over ride ON
	variable MaxNoOfSweeps = 0
	string DAChannelStatusList = ControlStatusListString("DA", "check",panelTitle)
	string TTLChannelStatusList = ControlStatusListString("TTL", "check",panelTitle)
	variable i = 0
	
	do
		if(str2num(stringfromlist(i,DAChannelStatusList,";"))==1)
		MaxNoOfSweeps=max(MaxNoOfSweeps, Index_NumberOfTrialsAcrossSets(PanelTitle, i, 0, IndexOverRide))
		endif
	
	i+=1
	while(i<itemsinlist(DAChannelStatusList,";"))
	
	i=0
	do
		if(str2num(stringfromlist(i,TTLChannelStatusList,";"))==1)
		MaxNoOfSweeps=max(MaxNoOfSweeps, Index_NumberOfTrialsAcrossSets(PanelTitle, i, 1, IndexOverRide))
		endif
	
	i+=1
	while(i<itemsinlist(TTLChannelStatusList,";"))
	
	return MaxNoOfSweeps
End

Function Index_NumberOfTrialsAcrossSets(PanelTitle, PopUpMenuNumber, DAorTTL, IndexOverRide)// determines the number of trials for a DA or TTL channel
	string PanelTitle
	variable PopUpMenuNumber, DAorTTL, IndexOverRide//DA = 0, TTL = 1	
	variable NumberOfTrialsAcrossSets
	variable IndexStart, IndexEnd, ListOffset
	string DAorTTL_cntrlName = "", DAorTTL_indexEndName = "", setname = ""
	
	if(DAorTTL==0)// determine control names based on DA or TTL 
		DAorTTL_cntrlName = "Wave_DA_0" + num2str(PopUpMenuNumber)
		DAorTTL_indexEndName = "Popup_DA_IndexEnd_0" + num2str(PopUpMenuNumber)
		ListOffset=3// accounts for first two options in DA popup menu list
	endif

	if(DAorTTL==1)
		DAorTTL_cntrlName = "Wave_TTL_0" + num2str(PopUpMenuNumber)
		DAorTTL_indexEndName = "Popup_TTL_IndexEnd_0" + num2str(PopUpMenuNumber)
		ListOffset=2//SHOULD BE TWO BUT TEST PULSE IS PRESENTLY POPULATING THE TTL POPUP MENU LIST
	endif
	
	controlinfo/w=$panelTitle $DAorTTL_cntrlName// check if indexing is activated
	IndexStart=v_value
	
	controlinfo/w=$panelTitle Check_DataAcq_Indexing// checks to if indexing is activated
	if(v_value==0)
		IndexEnd=indexStart
	else
		controlinfo/w=$panelTitle $DAorTTL_indexEndName
		IndexEnd=v_value 
	endif
	
	If(IndexOverRide==1)
		IndexEnd=indexStart
	endIF
	
	string setList = getuserdata(PanelTitle, DAorTTL_cntrlName, "menuexp")
	variable i = (min(indexstart, indexend)-ListOffset)
	
	do
		Setname=stringfromlist(i, setList,";")
		NumberOfTrialsAcrossSets+=Index_NumberOfTrialsInSet(PanelTitle, SetName, DAorTTL)
		i+=1
	while(i<(max(indexstart, indexend)-(ListOffset-1)))
	
	return NumberOfTrialsAcrossSets

End

Function Index_NumberOfTrialsInSet(PanelTitle, SetName, DAorTTL)// set name is the wave name, does not include wave path
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


