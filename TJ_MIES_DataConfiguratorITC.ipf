#pragma rtGlobals=3		// Use modern global access method and strict wave access.


//=========================================================================================
Function ConfigureDataForITC(PanelTitle)// pass column into this function?
	string PanelTitle
	MakeITCConfigAllConfigWave(PanelTitle)  
	MakeITCConfigAllDataWave(PanelTitle)  
	MakeITCFIFOPosAllConfigWave(PanelTitle)
	MakeITCFIFOAvailAllConfigWave(PanelTitle)
	
	PlaceDataInITCChanConfigWave(PanelTitle)
	PlaceDataInITCDataWave(PanelTitle)
	PDInITCFIFOPositionAllCW(PanelTitle)// PD = Place Data
	PDInITCFIFOAvailAllCW(PanelTitle)
End

//==========================================================================================

Function TotalChannelsSelected(panelTitle) //DA_00 - DA_07 and AD_00-AD_15, 
	string panelTitle
	variable TotalNumOfChanSelected
	TotalNumOfChanSelected = NoOfChannelsSelected("DA", "Check",panelTitle) + NoOfChannelsSelected("AD", "Check",panelTitle) + NoOfChannelsSelected("TTL", "Check",panelTitle)
	return TotalNumOfChanSelected
End

//==========================================================================================

Function ITCMinSamplingInterval(panelTitle)// minimum sampling intervals are 5, 10, 15, 20 or 25 microseconds
	string panelTitle
	//The min sampling interval is determined by the rack with the most channels selected
	variable ITCMinSampInt, Rack0DAMinInt, Rack0ADMinInt, Rack1DAMinInt, Rack1ADMinInt
	
	Rack0DAMinInt = DAMinSampInt(0, panelTitle)
	Rack1DAMinInt = DAMinSampInt(1, panelTitle)
	
	Rack0ADMinInt = ADMinSampInt(0,panelTitle)
	Rack1ADMinInt = ADMinSampInt(1, panelTitle)
	
	ITCMinSampInt = max(max(Rack0DAMinInt,Rack1DAMinInt), max(Rack0ADMinInt,Rack1ADMinInt))

	return ITCMinSampInt
End


//==========================================================================================
Function NoOfChannelsSelected(ChannelType, ControlType, panelTitle)//ChannelType = DA, AD, or TTL; Control Type = check or wave
	string ChannelType, ControlType,panelTitle
	variable TotalPossibleChannels = TotNoOfControlType(ControlType, ChannelType,panelTitle)
	variable i = 0
	variable NoOfChannelsSelected = 0
	string CheckBoxName
	
		do
			CheckBoxName = "Check_"+ ChannelType +"_"
			
			if(i < 10)
				CheckBoxName += "0"+num2str(i)
				ControlInfo /w = $panelTitle $CheckBoxName
				NoOfChannelsSelected += v_value
			endif
	
			if(i >= 10)
				CheckBoxName += num2str(i)
				ControlInfo /w = $panelTitle $CheckBoxName
				NoOfChannelsSelected += v_value
			endif
		
		i += 1
		while(i <= (TotalPossibleChannels - 1))
	return NoOfChannelsSelected
End

//==========================================================================================

Function/S ControlStatusListString(ChannelType, ControlType,panelTitle)
	String ChannelType, panelTitle
	string ControlType
	variable TotalPossibleChannels = TotNoOfControlType(ControlType, ChannelType,panelTitle)
	
	String ControlStatusList = ""
	String ControlName
	variable i
	
	i=0
	
		do
			ControlName = ControlType + "_" + ChannelType + "_"		
			
			if(i < 10)
				ControlName += "0" + num2str(i)
				ControlInfo /w = $panelTitle $ControlName
				ControlStatusList += num2str(v_value) + ";"
			endif
	
			if(i >= 10)
				ControlName += num2str(i)
				ControlInfo /w = $panelTitle $ControlName
				ControlStatusList += num2str(v_value) + ";"
			endif
		
	
		i+=1
		while(i <= (TotalPossibleChannels - 1))
	
	return ControlStatusList
End

//==========================================================================================

Function ChannelCalcForITCChanConfigWave(panelTitle)
	string panelTitle
	Variable NoOfDAChannelsSelected = NoOfChannelsSelected("DA", "Check",panelTitle)
	Variable NoOfADChannelsSelected = NoOfChannelsSelected("AD", "Check",panelTitle)
	Variable AreRack0FrontTTLsUsed = AreTTLsInRackChecked(0,panelTitle)
	Variable AreRack1FrontTTLsUsed = AreTTLsInRackChecked(1,panelTitle)
	Variable ChannelCount
	
	ChannelCount = NoOfDAChannelsSelected + NoOfADChannelsSelected + AreRack0FrontTTLsUsed + AreRack1FrontTTLsUsed
	
	return ChannelCount

END
//==========================================================================================
Function AreTTLsInRackChecked(RackNo, panelTitle)
	variable RackNo
	string panelTitle
	variable a
	variable b
	string TTLsInUse = ControlStatusListString("TTL", "Check",panelTitle)
	variable RackTTLStatus
	
	if(RackNo == 0)
		 a = 0
		 b = 3
	endif
	
	if(RackNo == 1)
		 a = 4
		 b = 7
	endif
	
	do
		If(str2num(stringfromlist(a,TTLsInUse,";")) == 1)
			RackTTLStatus = 1
			return RackTTLStatus
		endif
		a += 1
	while(a <= b)
	
	RackTTLStatus = 0
	return RackTTLStatus
End

//=========================================================================================

Function TotNoOfControlType(ControlType, ChannelType, panelTitle) // Ex. ChannelType = "DA", ControlType = "Check"
	string  ControlType, ChannelType, panelTitle
	string SearchString = ControlType + "_" + ChannelType + "_*"
	string ListString
	variable CatTot //Category Total
	
	ListString = ControlNameList(panelTitle,";",SearchString)
	CatTot = ItemsInlist(ListString,";")
	
	return CatTot
End


//=========================================================================================
// 1. TTL 1;0;0;0
// 2. TTL 0;1;0;0
// 3. TTL 1;1;0;0
// 4. TTL 0;0;1;0
// 5. TTL 1;0;1;0
// 6. TTL 0;1;1;0
// 7. TTL 1;1;1;0
// 8. TTL 0;0;0;1
// 9. TTL 1;0;0;1
// 10. TTL 0;1;0;1
// 11. TTL 1;1;0;1
// 12. TTL 0;0;1;1
// 13. TTL1;0;1;1
// 14. TTL 0;1;1;1
// 15. TTL 1;1;1;1

Function TTLCodeCalculation1(RackNo, panelTitle)//
	variable RackNo
	string panelTitle
	variable a, i, TTLChannelStatus,Code
	string TTLStatusString = ControlStatusListString("TTL", "Check",panelTitle)
	
	if(RackNo == 0)
		a = 0
	endif
	
	if(RackNo == 1)
		a = 4
	endif
	
	code = 0
	i = 0
	
	do 
		TTLChannelStatus = str2num(stringfromlist(a,TTLStatusString,";"))
		Code += (((2 ^ i)) * TTLChannelStatus)
		a += 1
		i += 1
	while(i < 4)
	
	return Code

End


//=========================================================================================

Function/s PopMenuStringList(ChannelType, ControlType, panelTitle)// returns the list of selected waves in pop up menus
	string ChannelType, ControlType, panelTitle
	variable TotalPossibleChannels = TotNoOfControlType(ControlType, ChannelType, panelTitle)
	String ControlWaveList = ""
	String ControlName
	variable i = 0
	
		do
			ControlName = ControlType + "_" + ChannelType + "_"		
			
			if(i < 10)
				ControlName += "0" + num2str(i)
				ControlInfo /w = $panelTitle $ControlName
				ControlWaveList += s_value + ";"
			endif
	
			if(i >= 10)
				ControlName += num2str(i)
				ControlInfo /w = $panelTitle $ControlName
				ControlWaveList += s_value + ";"
			endif
			
		i += 1
		while(i <= (TotalPossibleChannels - 1))
	
	return ControlWaveList

End

//=========================================================================================
Function LongestOutputWave(ChannelType, panelTitle)//ttl and da channel types need to be passed into this and compared to determine longest wave
	string ChannelType, panelTitle
	string ControlType = "Check"
	variable TotalPossibleChannels = TotNoOfControlType(ControlType, ChannelType, panelTitle)
	variable wavelength = 0, i = 0
	string ControlTypeStatus = ControlStatusListString(ChannelType, ControlType, panelTitle)
	string WaveNameString
	ControlType = "Wave"
	string ChannelTypeWaveList = PopMenuStringList(ChannelType, ControlType, panelTitle)
	
	//if da or ttl channels is active, query the wavelength of the active channel
	i = 0
	wavelength = 0
	
	do
	
	if((str2num(stringfromlist(i,ControlTypeStatus,";"))) == 1)
		WaveNameString = stringfromlist(i,ChannelTypeWaveList,";")
		if(stringmatch(WaveNameString,"-none-") == 0)//prevents error where check box is checked but no wave is selected. Update: the panel code actually prevents this possibility but I am leaving the code because I don't think the redundancy is harmful
			WaveNameString = "root:WaveBuilder:savedStimulusSets:" + ChannelType + ":" + WaveNameString
//			if(cmpstr(WaveNameString, "root:WaveBuilder:savedStimulusSets:DA:TestPulse") == 0)// checks to see if test pulse is the wave being run, if yes, changes path
//			WaveNameString = HSU_DataFullFolderPathString(PanelTitle) + ":TestPulse:TestPulse"
//			endif
			if(DimSize($WaveNameString, 0 ) > WaveLength)
				WaveLength = DimSize($WaveNameString, 0 )
			endif
		endif
	endif
	
	i += 1
	while(i <= (TotalPossibleChannels - 1))
	return WaveLength
End



//==========================================================================================
Function CalculateITCDataWaveLength(panelTitle)// determines the longest output DA or DO wave. Divides it by the min sampling interval and quadruples its length (to prevent buffer overflow).
	string panelTitle
	Variable LongestWaveLength
	//Determine Longest Wave
	if (LongestOutputWave("DA", panelTitle) >= LongestOutputWave("TTL", panelTitle))
		LongestWaveLength = LongestOutputWave("DA", panelTitle)
	else
		LongestWaveLength = LongestOutputWave("TTL", panelTitle)
	endif
	
	LongestWaveLength /= (ITCMinSamplingInterval(panelTitle) / 5)
	LongestWaveLength *= 4
	
	return round(LongestWaveLength)
end

//==========================================================================================
Function MakeITCConfigAllConfigWave(PanelTitle)
	string PanelTitle
	string ITCChanConfigPath = HSU_DataFullFolderPathString(PanelTitle) + ":ITCChanConfigWave"
	Make /I /o /n = (ChannelCalcForITCChanConfigWave(panelTitle), 4) $ITCChanConfigPath
	wave /z ITCChanConfigWave = $ITCChanConfigPath
	ITCChanConfigWave = 0
End
//==========================================================================================
Function MakeITCConfigAllDataWave(PanelTitle)
	string PanelTitle
	string ITCDataWavePath = HSU_DataFullFolderPathString(PanelTitle) + ":ITCDataWave"
	make /w /o /n = (CalculateITCDataWaveLength(panelTitle), ChannelCalcForITCChanConfigWave(panelTitle)) $ITCDataWavePath
	wave/z ITCDataWave = $ITCDataWavePath
	ITCDataWave = 0
	SetScale/P x 0,(ITCMinSamplingInterval(panelTitle)) / 1000,"ms", ITCDataWave
End
//==========================================================================================
Function MakeITCFIFOPosAllConfigWave(PanelTitle)//MakeITCUpdateFIFOPosAllConfigWave
	string panelTitle
	string ITCFIFOPosAllConfigWavePath = HSU_DataFullFolderPathString(PanelTitle) + ":ITCFIFOPositionAllConfigWave"
	Make /I /o /n = (ChannelCalcForITCChanConfigWave(panelTitle), 4) $ITCFIFOPosAllConfigWavePath
	wave /z ITCFIFOPositionAllConfigWave = $ITCFIFOPosAllConfigWavePath
	ITCFIFOPositionAllConfigWave = 0
End
//==========================================================================================
Function MakeITCFIFOAvailAllConfigWave(panelTitle)//MakeITCFIFOAvailAllConfigWave
	string panelTitle
	string ITCFIFOAvailAllConfigWavePath = HSU_DataFullFolderPathString(panelTitle) + ":ITCFIFOAvailAllConfigWave"
	Make /I /o /n = (ChannelCalcForITCChanConfigWave(panelTitle), 4) $ITCFIFOAvailAllConfigWavePath
	wave /z ITCFIFOAvailAllConfigWave = $ITCFIFOAvailAllConfigWavePath
	ITCFIFOAvailAllConfigWave = 0
End
//==========================================================================================


Function PlaceDataInITCChanConfigWave(PanelTitle)
	string panelTitle
	variable i = 0// 
	variable j = 0//used to keep track of row of ITCChanConfigWave which config data is loaded into
	variable ChannelType // = 0 for AD, = 1 for DA, = 3 for TTL
	string ChannelStatus
	string WavePath = HSU_DataFullFolderPathString(PanelTitle) 
	wave ITCChanConfigWave = $WavePath + ":ITCChanConfigWave"
	wave /T ChanAmpAssignUnit = $WavePath + ":ChanAmpAssignUnit"
	string UnitString = ""
	
	string UnitSetVarName = "Unit_DA_0"
	ChannelType = 1
	ChannelStatus = ControlStatusListString("DA", "Check", panelTitle)
	
	//Place DA config data
	do
		if(str2num(stringfromlist(i,ChannelStatus,";")) == 1)
			ITCChanConfigWave[j][0] = ChannelType
			ITCChanConfigWave[j][1] = i
			controlinfo /w = $panelTitle $UnitSetVarName + num2str(i)
			UnitString += s_value + ";"// a string with a unit for each column
			j += 1
		endif
		i += 1
	while(i < (itemsinlist(ChannelStatus,";")))
	
	//Place AD config data
	i = 0
	ChannelStatus = ControlStatusListString("AD", "Check", panelTitle)
	ChannelType = 0
	UnitSetVarName = "Unit_AD_0"
	do
		if(str2num(stringfromlist(i,ChannelStatus,";")) == 1)
			ITCChanConfigWave[j][0] = ChannelType
			ITCChanConfigWave[j][1] = i
			controlinfo /w = $panelTitle $UnitSetVarName + num2str(i)
			UnitString += s_value + ";"
			j += 1
		endif
		i+=1
	while(i<(itemsinlist(ChannelStatus,";")))
	
	note ITCChanConfigWave, UnitString
	//Place TTL config data
	i = 0
	ChannelType = 3
	
	if(AreTTLsInRackChecked(0, panelTitle) == 1)
		ITCChanConfigWave[j][0] = ChannelType
		ITCChanConfigWave[j][1] = 0
	j += 1
	endif
	
	if(AreTTLsInRackChecked(1, panelTitle) == 1)
		ITCChanConfigWave[j][0] = ChannelType
		ITCChanConfigWave[j][1] = 3
	
	endif
	
	ITCChanConfigWave[][2] = ITCMinSamplingInterval(panelTitle)//
	ITCChanConfigWave[][3] = 0

End
//==========================================================================================
Function PlaceDataInITCDataWave(PanelTitle)
	string panelTitle
	variable i = 0// 
	variable j = 0//
	string ChannelStatus
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCDataWave = $WavePath + ":ITCDataWave"
	string ITCDataWavePath = WavePath + ":ITCDataWave"
	//string testPulsePath = HSU_DataFullFolderPathString(PanelTitle) + ":TestPulse:TestPulse"
	string ChanTypeWaveNameList, ChanTypeWaveName
	string ResampledWaveName = "ResampledWave"
	string cmd
	string SetvarDAGain, SetVarDAScale
	variable DAGain, DAScale,column, insertStart, insertEnd, EndRow
	string CountPath = HSU_DataFullFolderPathString(PanelTitle)+":count" //%%
	wave ChannelClampMode = $WavePath + ":ChannelClampMode"

	if(exists(CountPath) == 2)
		NVAR count = $CountPath
		column = count-1
	else
		column = 0
	endif
	
	//Place DA waves into ITCDataWave
	variable DecimationFactor = (ITCMinSamplingInterval(panelTitle)/5)
	ChannelStatus = ControlStatusListString("DA", "Check", panelTitle)
	ChanTypeWaveNameList = PopMenuStringList("DA", "Wave", panelTitle)
	do
		if(str2num(stringfromlist(i,ChannelStatus,";")) == 1)//Checks if DA channel checkbox is checked (ON)
			SetVarDAGain = "gain_DA_0" + num2str(i)
			SetVarDAScale = "scale_DA_0" + num2str(i)
			ControlInfo /w = $panelTitle $SetVarDAGain
			if(ChannelClampMode[i][0] == 0) // V-clamp
				DAGain = (3200 / v_value) // 3200 = 1V, 3200/gain = bits per unit
			endif
			
			if(ChannelClampMode[i][0] == 1) // I-clamp
				DAGain = (3200 / v_value) // 3200 = 1V, 3200/gain = bits per unit
			endif		
			
			ControlInfo /w = $panelTitle $SetVarDAScale
			DAScale = v_value
	
			//get the wave name
			ChanTypeWaveName = "root:WaveBuilder:SavedStimulusSets:DA:"+ stringfromlist(i,ChanTypeWaveNameList,";")
			//check to see if it is a test pulse or user specified da wave
			if(cmpstr(ChanTypeWaveName,"root:WaveBuilder:SavedStimulusSets:DA:testpulse") == 0)
				column = 0
				insertStart = 0
				insertEnd = 0
			else
				column = real(CalculateChannelColumnNo(panelTitle, stringfromlist(i,ChanTypeWaveNameList,";"), i,0))// CalculateChannelColumnNo also returns a 0 or 1 in the imaginary componet. 1 = set has cycled once already
				if(i == 0)
					InsertStart = GlobalChangesToITCDataWave(panelTitle) 
					InsertEnd = InsertStart 
				endif
			endif
		// checks if user wants to set scaling to 0 on sets that have already cycled once
		ControlInfo /w = $panelTitle check_Settings_ScalingZero 
		//print "v_value = "+ num2str(v_value)
		if(v_value == 1)
			ControlInfo /w = $panelTitle Check_DataAcq1_IndexingLocked
			if(v_value == 1)// shutting off DA by setting scaling to zero is only required when indexing is locked
				if(cmpstr(ChanTypeWaveName,"root:WaveBuilder:SavedStimulusSets:DA:testpulse")!=0)// makes sure test pulse wave scaling is maintained
					if(imag(CalculateChannelColumnNo(panelTitle, stringfromlist(i,ChanTypeWaveNameList,";"),i,0)) == 1)
						DAScale = 0
					endif
				endif
			endif
		endif
			//resample the wave to min samp interval and place in ITCDataWave
			EndRow = (((round(dimsize($ChanTypeWaveName, 0)) / DecimationFactor) - 1) + InsertEnd)
			//sprintf cmd, "%s[%d, ((round((dimsize(%s,0) / (%d)) - 1)) + %d)][%d] = (%d*%d) * (%s[((%d) * p) - %d][%d])" ITCDataWavePath, InsertStart, ChanTypeWaveName,DecimationFactor, InsertEnd, j, DAGain, DAScale, ChanTypeWaveName, DecimationFactor, InsertStart, Column
			sprintf cmd,  "%s[%d, %d][%d] = (%d*%d) * (%s[(%d * (p - %d))][%d])" ITCDataWavePath, InsertStart, EndRow, j, DAGain, DAScale, ChanTypeWaveName, DecimationFactor, InsertStart, Column
			execute cmd
	
			j += 1// j determines what column of the ITCData wave the DAC wave is inserted into 
		endif
		i += 1
	while(i < (itemsinlist(ChannelStatus,";")))
		
	//Leave room for AD data 
		i = 0
		ChannelStatus = ControlStatusListString("AD", "Check", panelTitle)
	
	do
		if(str2num(stringfromlist(i,ChannelStatus,";")) == 1)
			j += 1
		endif
		i += 1
	while(i < (itemsinlist(ChannelStatus,";")))
	
	//Place DA waves into ITCDataWave
	i = 0
	wave /z TTLwave = $HSU_DataFullFolderPathString(PanelTitle) + ":TTLwave"//= root:WaveBuilder:SavedStimulusSets:TTL:TTLWave
	if(AreTTLsInRackChecked(0, panelTitle) == 1)
		MakeITCTTLWave(0, panelTitle)
		ITCDataWave[0,round((dimsize(TTLWave,0) / DecimationFactor)) - 1][j] = TTLWave[(DecimationFactor) * p]
		j += 1
	endif
	
	if(AreTTLsInRackChecked(1, panelTitle) == 1)
		MakeITCTTLWave(1, panelTitle)
		ITCDataWave[0,round((dimsize(TTLWave,0) / DecimationFactor)) - 1][j]=TTLWave[(DecimationFactor) * p]
	endif
End

//=========================================================================================
Function PDInITCFIFOPositionAllCW(panelTitle)//PlaceDataInITCFIFOPositionAllConfigWave()
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCFIFOPositionAllConfigWave = $WavePath+":ITCFIFOPositionAllConfigWave" , ITCChanConfigWave = $WavePath+":ITCChanConfigWave"
	ITCFIFOPositionAllConfigWave[][0,1] = ITCChanConfigWave
	ITCFIFOPositionAllConfigWave[][2]=-1
	ITCFIFOPositionAllConfigWave[][3]=0
End
//=========================================================================================
Function PDInITCFIFOAvailAllCW(PanelTitle)//PlaceDataInITCFIFOAvailAllConfigWave()
	string panelTitle
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	wave ITCFIFOAvailAllConfigWave = $WavePath+":ITCFIFOAvailAllConfigWave", ITCChanConfigWave = $WavePath+":ITCChanConfigWave"
	ITCFIFOAvailAllConfigWave[][0,1] = ITCChanConfigWave
	ITCFIFOAvailAllConfigWave[][2] = 0
	ITCFIFOAvailAllConfigWave[][3] = 0
End
//=========================================================================================
Function MakeITCTTLWave(RackNo, panelTitle)//makes single ttl wave for each rack. each ttl wave is added to the next after being multiplied by its bit number
	variable RackNo
	string panelTitle
	variable a, i, TTLChannelStatus,Code
	string TTLStatusString = ControlStatusListString("TTL", "Check", panelTitle)
	string TTLWaveList = PopMenuStringList("TTL", "Wave", panelTitle)
	string TTLWaveName
	string cmd
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)+":"//"root:WaveBuilder:savedStimulusSets:TTL:"// the ttl wave should really be located in the device folder not the wavebuilder folder
	string TTLWavePath = "root:WaveBuilder:savedStimulusSets:TTL:"
	if(RackNo == 0)
		a = 0
	endif
	
	if(RackNo == 1)
		a = 4
	endif
	
	code = 0
	i = 0
	
	do 
		TTLChannelStatus = str2num(stringfromlist(a,TTLStatusString,";"))
		Code = (((2 ^ i)) * TTLChannelStatus)
		TTLWaveName = stringfromlist(a,TTLWaveList,";")
		if(i == 0)
			TTLWaveName = TTLWavePath + TTLWaveName// 
			make /o /n = (dimsize($TTLWaveName,0)) $WavePath+"TTLWave" = 0// 
		endif
		
		if(TTLChannelStatus == 1)
			sprintf cmd, "%sTTLWave+=(%d)*(%s%s%d%s)" wavepath, code, TTLWaveName,"[p][",CalculateChannelColumnNo(panelTitle, stringfromlist(a,TTLWaveList,";"),i,1),"]"

//		controlinfo/w=$panelTitle check_DataAcq_RepAcqRandom//checks to see if radom intra set sequencing is selected
//			if(v_value==0)
//				sprintf cmd, "%sTTLWave+=(%d)*(%s%s%d%s)" wavepath, code, TTLWaveName,"[p][",CalculateTTLColumnNo(panelTitle, stringfromlist(a,TTLWaveList,";")),"]"
//			else
//				sprintf cmd, "%sTTLWave+=(%d)*(%s%s%d%s)" wavepath, code, TTLWaveName,"[p][",CalculateShuffledTTLColumnNo(panelTitle, stringfromlist(a,TTLWaveList,";")),"]"
//			endif
		execute cmd
		endif
		a += 1
		i += 1
	while( i <4)
End
//=========================================================================================
Function DAMinSampInt(RackNo, panelTitle)
	variable RackNo
	string panelTitle
	variable a, i, DAChannelStatus,SampInt
	string DAStatusString = ControlStatusListString("DA", "Check", panelTitle)
	
	a = RackNo*4
	
	SampInt = 0
	i = 0
	
	do 
		DAChannelStatus = str2num(stringfromlist(a,DAStatusString,";"))
		SampInt += 5*DAChannelStatus
		a += 1
		i += 1
	while(i < 4)
	
	return SampInt
End
//=========================================================================================
Function ADMinSampInt(RackNo,panelTitle)
	variable RackNo
	string panelTitle
	variable a, i, ADChannelStatus,ADSampInt, Bank1SampInt, Bank2SampInt
	string ADStatusString = ControlStatusListString("AD", "Check",panelTitle)
	
	a = RackNo*8
	
	Bank1SampInt = 0
	Bank2SampInt = 0
	ADSampInt = 0
	i = 0
	
	do 
		ADChannelStatus = str2num(stringfromlist(a,ADStatusString,";"))
		Bank1SampInt += 5 * ADChannelStatus
		a += 1
		i += 1
	while(i < 4)
	
	i = 0
	do 
		ADChannelStatus = str2num(stringfromlist(a,ADStatusString,";"))
		Bank2SampInt += 5 * ADChannelStatus
		a += 1
		i += 1
	while(i < 4)
	
	ADSampInt = max(Bank1SampInt,Bank2SampInt)
	return ADSampInt
End
//=========================================================================================

// returns column number, independent of the times the set is being cycled through (as defined by SetVar_DataAcq_SetRepeats)
Function/c CalculateChannelColumnNo(panelTitle, SetName, channelNo, DAorTTL)// setname is a string that contains the full wave path
	string panelTitle, SetName
	variable ChannelNo, DAorTTL
	variable ColumnsInSet = Index_NumberOfTrialsInSet(PanelTitle, SetName, DAorTTL)
	variable column
	variable CycleCount // when cycleCount = 1 the set has already cycled once.
	variable /c column_CycleCount
	variable localCount
	string WavePath = HSU_DataFullFolderPathString(PanelTitle)
	string CountPath = WavePath +":Count"
	string AcitveSetCountPath = WavePath +":ActiveSetCount"
	//following string and wave apply when random set sequence is selected
	string SequenceWaveName = WavePath + ":" + SetName + num2str(daorttl) + num2str(channelNo) + "_S"//s is for sequence
	wave/z WorkingSequenceWave = $SequenceWaveName	
	// Below code calculates the variable local count which is then used to determine what column to select from a particular set
		if(exists(CountPath) == 2)// the global variable count is created at the initiation of the repeated aquisition functions and killed at their completion, 
							//thus the vairable "count" is used to determine if acquisition is on the first cycle
			NVAR count = $CountPath
			controlinfo /w = $panelTitle Check_DataAcq_Indexing// check indexing status
			if(v_value == 0)// if indexing is off...
				localCount = count
				cycleCount = 0
			else // else is used when indexing is on. The local count is now set length dependent
				controlinfo /w = $panelTitle Check_DataAcq1_IndexingLocked// check locked status. locked = popup menus on channels idex in lock - step
				if(v_value == 1)// indexing is locked
					NVAR ActiveSetCount=$AcitveSetCountPath
					controlinfo /w = $panelTitle valdisp_DataAcq_SweepsActiveSet// how many columns in the largest currently selected set on all active channels
					localCount = v_value
					controlinfo /w = $panelTitle SetVar_DataAcq_SetRepeats// how many times does the user want the sets to repeat
					localCount *= v_value
					localCount -= ActiveSetCount// active set count keeps track of how many steps of the largest currently selected set on all active channels has been taken
				else //indexing is unlocked
					// calculate where in list global count is
					localCount = UnlockedIndexingStepNo(panelTitle, channelNo, DAorTTL, count)
				endif
			endif

	//Below code uses local count to determine  what step to use from the set based on the sweeps in cycle and sweeps in active set
			if(((localCount) / ColumnsInSet) < 1 || (localCount) == 0)// if remainder is less than 1, count is on 1st cycle
				controlinfo /w = $panelTitle check_DataAcq_RepAcqRandom
				if(v_value == 0) // set step sequence is not random
					column = localCount
					cycleCount = 0
				else // set step sequence is random
					column = WorkingSequenceWave[localcount]
					cycleCount = 0
				endif	
			else
				controlinfo /w = $panelTitle check_DataAcq_RepAcqRandom
				if(v_value == 0) // set step sequence is not random
					column = mod((localCount), columnsInSet)// set has been cyled through once or more, uses remainder to determine correct column
					cycleCount = 1
				else
					if(mod((localCount), columnsInSet) == 0)
						Shuffle(WorkingSequenceWave)
					endif
					column = WorkingSequenceWave[mod((localCount), columnsInSet)]
					cycleCount = 1
				endif
			endif
		else
			controlinfo /w = $panelTitle check_DataAcq_RepAcqRandom
			if(v_value == 0) // set step sequence is not random
				column = 0
			else
				make /o /n = (ColumnsInSet) $SequenceWaveName
				wave WorkingSequenceWave = $SequenceWaveName
				WorkingSequenceWave = x
				Shuffle(WorkingSequenceWave)
				column = WorkingSequenceWave[0]
			endif
		endif
	
	if(channelNo == 1)
		if(DAorTTL == 0)
		print "DA channel 1 column = " + num2str(column)
		else
		print "TTL channel 1 column = " + num2str(column)
		endif
		//print setname
	endif
	if(channelNo == 0)
		if(DAorTTL == 0)
		print "DA channel 0 column = " + num2str(column)
		else
		print "TTL channel 0 column = " + num2str(column)
		endif
		//print setname
	endif
	
	column_CycleCount = cmplx(column, cycleCount)
	return column_CycleCount
end

//below function was taken from: http://www.igorexchange.com/node/1614
//author s.r.chinn
Function shuffle(inwave)	//	in-place random permutation of input wave elements
	wave inwave
	variable N	=	numpnts(inwave)
	variable i, j, emax, temp
	for(i = N; i>1; i-=1)
		emax = i / 2
		j =  floor(emax + enoise(emax))		//	random index
// 		emax + enoise(emax) ranges in random value from 0 to 2*emax = i
		temp		= inwave[j]
		inwave[j]		= inwave[i-1]
		inwave[i-1]	= temp
	endfor
end

Function GlobalChangesToITCDataWave(panelTitle) // adjust the length of the ITCdataWave according to the global changes on the data acquisition tab - should only get called for not TP data acquisition cycles
	string panelTitle
	controlinfo /w = $panelTitle setvar_DataAcq_OnsetDelay
	variable OnsetDelay = v_value / (ITCMinSamplingInterval(panelTitle) / 1000)
	controlinfo /w = $panelTitle setvar_DataAcq_TerminationDelay
	variable TerminationDelay = v_value / (ITCMinSamplingInterval(panelTitle) / 1000)
	variable NewRows = round((OnsetDelay + TerminationDelay) * 4)
	string WavePath = HSU_DataFullFolderPathString(PanelTitle) + ":"
	wave ITCDataWave = $WavePath + "ITCDataWave"
	variable ITCDataWaveRows = dimsize(ITCDataWave, 0)
	redimension /N = (ITCDataWaveRows + NewRows, -1, -1, -1) ITCDataWave
	return OnsetDelay
End

Function ReturnTotalLengthIncrease(PanelTitle)
	string panelTitle
	controlinfo /w = $panelTitle setvar_DataAcq_OnsetDelay
	variable OnsetDelay = v_value / (ITCMinSamplingInterval(panelTitle) / 1000)
	controlinfo /w = $panelTitle setvar_DataAcq_TerminationDelay
	variable TerminationDelay = v_value / (ITCMinSamplingInterval(panelTitle) / 1000)
	variable NewRows = round((OnsetDelay + TerminationDelay) * 4)
	return OnsetDelay + TerminationDelay
end
	