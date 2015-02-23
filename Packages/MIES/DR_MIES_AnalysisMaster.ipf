#pragma rtGlobals=3		// Use modern global access method and strict wave access.

static StrConstant amPanel = "analysisMaster"

/// @file DR_MIES_analysisMaster.ipf
/// @brief waveform analysis framework
/// Brief description of the function WA_analysisMaster
/// Function used to create a framework for calling post-sweep analysis functions
//===============================================================================
Function AM_analysisMasterPostSweep(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo
	
	Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(panelTitle)
	
	// Go through the analysisSettingsWave and decode the settings to invoke analysis routines
	variable headStageCounter
	for(headStageCounter = 0; headStageCounter < NUM_HEADSTAGES; headStageCounter += 1)
		if(str2num(analysisSettingsWave[headStageCounter][%PSAOnOff]) == 1) // do the post sweep analysis
			string analysisAction
			string editedAnalysisAction
			editedAnalysisAction = analysisSettingsWave[headStageCounter][%PSAType]
			
			sprintf analysisAction, "AM_PSA_%s", editedAnalysisAction
			
			// put the analysisAction into a form that can be used to call a function
			FUNCREF protoAnalysisFunc psaf = $analysisAction
			variable analysisResult = psaf(panelTitle, headStageCounter)
			analysisSettingsWave[headStageCounter][%PSAResult] = num2str(analysisResult)
				
			if(str2num(analysisSettingsWave[headStageCounter][%PAAOnOff]) == 1) // do the post analysis action		
				string postAnalysisFunction
				string editedPostAnalysisFunction
				editedPostAnalysisFunction = analysisSettingsWave[headStageCounter][%PAAType]
					
				sprintf postAnalysisFunction, "AM_PAA_%s", editedPostAnalysisFunction
				
				// put the analysisAction into a form that can be used to call a function
				FUNCREF protoAnalysisFunc paaf = $postAnalysisFunction
				variable postAnalysisResult = paaf(panelTitle, headStageCounter)
				analysisSettingsWave[headStageCounter][%PAAResult] = num2str(postAnalysisResult)
			endif					
		endif
	endfor
	
	return postAnalysisResult
End

Function AM_analysisMasterMidSweep(panelTitle)
	string panelTitle
	
	Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(panelTitle)
	Wave actionScaleSettingsWave =  GetActionScaleSettingsWaveRef(panelTitle)
	
	// Go through the analysisSettingsWave and decode the settings to invoke the midsweep analysis routine
	variable headStageCounter
	for(headStageCounter = 0; headStageCounter < NUM_HEADSTAGES; headStageCounter += 1)
		if(str2num(analysisSettingsWave[headStageCounter][%MSAOnOff]) == 1) // do the mid sweep analysis
			string analysisAction
			string editedAnalysisAction
			editedAnalysisAction = analysisSettingsWave[headStageCounter][%MSAType]
			
			sprintf analysisAction, "AM_MSA_%s", editedAnalysisAction
			
			// put the analysisAction into a form that can be used to call a function
			FUNCREF protoAnalysisFunc psaf = $analysisAction
			variable analysisResult = psaf(panelTitle, headStageCounter)
			analysisSettingsWave[headStageCounter][%MSAResult] = num2str(analysisResult)
		endif
	endfor
End

///@brief prototype Analysis function
Function protoAnalysisFunc(a,b)
	string a
	variable b
	
	print "in protoAnalysisFunc for", a
	variable result = 0
	return result
End

///@brief function that will search for an action potential during an ongoing sweep and abort the sweep if the AP fires
Function AM_MSA_midSweepFindAP(panelTitle, headStage)
	string panelTitle
	variable headStage
	
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	Wave currentCompleteDataWave = $WavePath + ":ITCDataWave"
	
	Wave actionScaleSettingsWave =  GetActionScaleSettingsWaveRef(panelTitle)
	
	variable sweepNo = GetSetVariable(panelTitle, "SetVar_Sweep")
	
	Wave/Z sweep = GetSweepWave(paneltitle, (sweepNo-1))
	if(!WaveExists(sweep))
     		Abort "***Error getting current sweep wave..."
	endif
	
	Wave config = GetConfigWave(sweep)
	
	variable x = TP_GetADChannelFromHeadstage(panelTitle, headStage)
	
	string ADChannelList = GetADCListFromConfig(config)
	string DAChannelList = GetDACListFromConfig(config)
	variable numDACs = ItemsInList(DAChannelList)
	variable idx = WhichListItem(num2str(x), ADChannelList)
	ASSERT(idx != -1, "Missing AD channel")
		
	matrixOp/FREE SingleAD = col(currentCompleteDataWave, numDACs + idx)
	
	Variable apLevelValue = actionScaleSettingsWave[headStage][%apThreshold]
	FindLevel/P/Q/EDGE=1 SingleAD, apLevelValue
	variable xPoint=V_LevelX
	if (V_flag == 0)
		print "AP level found at" , xPoint
		DAP_StopOngoingDataAcquisition(panelTitle)
	endif
End	
				
///@brief function will return a variable to indicate if the most recent wave fired an action potential.
Function AM_PSA_returnActionPotential(panelTitle, headStage)
	string panelTitle
	variable headStage
	
	string WavePath = HSU_DataFullFolderPathString(panelTitle)
	Wave currentCompleteDataWave = $WavePath + ":ITCDataWave"	
	
	Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(panelTitle)
	Wave actionScaleSettingsWave =  GetActionScaleSettingsWaveRef(panelTitle)
	
	variable sweepNo = GetSetVariable(panelTitle, "SetVar_Sweep")
	
	Wave/Z sweep = GetSweepWave(paneltitle, sweepNo)
	if(!WaveExists(sweep))
     		Abort "Error getting current sweep wave..."
	endif
	
	Wave config = GetConfigWave(sweep)
	
	variable x = TP_GetADChannelFromHeadstage(panelTitle, headStage)
	
	string ADChannelList = GetADCListFromConfig(config)
	string DAChannelList = GetDACListFromConfig(config)
	variable numDACs = ItemsInList(DAChannelList)
	variable idx = WhichListItem(num2str(x), ADChannelList)
	ASSERT(idx != -1, "Missing AD channel")
		
	matrixOp/FREE SingleAD = col(currentCompleteDataWave, numDACs + idx)
			
	variable tracePeakValue = WaveMax(singleAD)	
		
	// see if the tracePeakValue is greater then the apThreshold value...if so, indicate that the action potential fired
	if (tracePeakValue > actionScaleSettingsWave[headStage][%apThreshold])	
		print "AP Fired: HS#" + num2str(headStage)
		analysisSettingsWave[headStage][%PSAResult] = num2str(1)
		return 1
	else
		analysisSettingsWave[headStage][%PSAResult] = num2str(0)
		return 0
	endif
End	

///@brief function used to adjust the scale factor for adaptive stim cycling
Function AM_PAA_adjustScaleFactor(panelTitle, headStage)
	string panelTitle
	variable headStage
	
	Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(panelTitle)	
	Wave actionScaleSettingsWave = GetActionScaleSettingsWaveRef(panelTitle)
	
	// get the DA channel associated with the desired headstage
	variable daChannel = TP_GetDAChannelFromHeadstage(panelTitle, headStage)
	
	string scaleControlName
	sprintf scaleControlName, "Scale_DA_0%d", daChannel
	variable scaleFactor = GetSetVariable(panelTitle, scaleControlName)
	
	// for this, use the coarse scale factor for the adjustment	
	variable incValue = actionScaleSettingsWave[headStage][%coarseScaleValue]
	
	// Fetch the post sweep analysis result
	variable analysisResult = str2num(analysisSettingsWave[headStage][%PSAResult])
	
	if (analysisResult == 0)	// action potential did not fire
		scaleFactor = scaleFactor + incValue
		print "New scaleFactor: ", scaleFactor
		SetSetVariable(panelTitle, scaleControlName, scaleFactor)
		return 0
	else		
		// stop the ongoing acquisition
		DAP_StopOngoingDataAcquisition(panelTitle)	
		
		// return the scale factor that caused the AP to fire
		actionScaleSettingsWave[headStage][%result] = scaleFactor
		print "scale factor that caused AP: ", scaleFactor		
		return 1
	endif
End

///@brief function used to adjust the scale factor for adaptive stim cycling -- needs to be used with the returnActionPotential postSweep Analysis function
Function AM_PAA_bracketScaleFactor(panelTitle, headStage)
	string panelTitle
	variable headStage
	
	Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(panelTitle)	
	Wave actionScaleSettingsWave = GetActionScaleSettingsWaveRef(panelTitle)
	
	// get the DA channel associated with the desired headstage
	variable daChannel = TP_GetDAChannelFromHeadstage(panelTitle, headStage)
	
	string scaleControlName
	sprintf scaleControlName, "Scale_DA_0%d", daChannel
	variable scaleFactor = GetSetVariable(panelTitle, scaleControlName)
	variable initialScaleFactor = scaleFactor
	
	// Fetch the post sweep analysis result
	variable analysisResult = str2num(analysisSettingsWave[headStage][%PSAResult])
	
	if ((analysisResult == 0) && (actionScaleSettingsWave[headStage][%coarseTuneUse] == 1) && (actionScaleSettingsWave[headStage][%fineTuneUse] == 0))	 // action potential did not fire while using coarse tune
		scaleFactor = scaleFactor + actionScaleSettingsWave[headStage][%coarseScaleValue]
		SetSetVariable(panelTitle, scaleControlName, scaleFactor)
		return 0
	elseif ((analysisResult == 1) && (actionScaleSettingsWave[headStage][%coarseTuneUse] == 1) && (actionScaleSettingsWave[headStage][%fineTuneUse] == 0))	// action potential fired on the coarse tuning
		print "switching to fine factor..."
		// bump the scale back one step of the coarse incValue
		SetSetVariable(panelTitle, scaleControlName, (scaleFactor - actionScaleSettingsWave[headStage][%coarseScaleValue]))
		
		// turn off the coarseTuneUse
		actionScaleSettingsWave[headStage][%coarseTuneUse] = 0
		
		// turn on the fineTuneUse
		actionScaleSettingsWave[headStage][%fineTuneUse] = 1
		return 0
	elseif ((analysisResult == 0) && (actionScaleSettingsWave[headStage][%coarseTuneUse] == 0) && (actionScaleSettingsWave[headStage][%fineTuneUse] == 1))	// action potential didn't fire on the fine tuning			
		// bump up the scale factor by the fine Scale adjustment
		scaleFactor = scaleFactor + actionScaleSettingsWave[headStage][% fineScaleValue]
		
		SetSetVariable(panelTitle, scaleControlName, scaleFactor)
		return 0
	elseif ((analysisResult == 1) && (actionScaleSettingsWave[headStage][%coarseTuneUse] == 0) && (actionScaleSettingsWave[headStage][%fineTuneUse] == 1))	// action potential fired on the fine tuning
		print "found the AP!"
		// Stop the ongoing data acquisition
		DAP_StopOngoingDataAcquisition(panelTitle)
		
		// set things back to the starting point so that the next time this is used it will be in the correct state
		actionScaleSettingsWave[headStage][%fineTuneUse] = 0
		actionScaleSettingsWave[headStage][%coarseTuneUse] = 1
		
		// return the scale factor that caused the AP to fire
		actionScaleSettingsWave[headStage][%result] = scaleFactor
		print "scale factor that caused AP: ", scaleFactor	
		
		// Now put the scale factor back to 1.0
		SetSetVariable(panelTitle, scaleControlName, 1.0)
			
		return 1
	endif
End
	
Window analysisMaster() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1500,100,2300,400) as "analysisMaster"
	SetDrawLayer UserBack
	DrawText 15,70,"HeadStage 0"
	DrawText 120,50,"Mid Sweep Analysis"
	DrawText 300,50,"Post Sweep Analysis"
	DrawText 480,50,"Post Analysis Action"
	DrawText 15,95,"HeadStage 1"
	DrawText 15,120,"HeadStage 2"
	DrawText 15,145,"HeadStage 3"
	DrawText 15,170,"HeadStage 4"
	DrawText 15,195,"HeadStage 5"
	DrawText 15,220,"HeadStage 6"
	DrawText 15,245,"HeadStage 7"
	PopupMenu lockedDeviceMenu,pos={100,5},size={125,20},bodyWidth=125,title="Locked Device", proc=AM_LockedDeviceMenu
	PopupMenu lockedDeviceMenu,mode=1,popvalue="-None-",value= #"DAP_ListOfLockedDevs()"	
	CheckBox headStage0_midSweepAnalysisOn,pos={100,57},size={16,14},proc=AM_HeadStageMSCheckBox,title=""
	CheckBox headStage0_midSweepAnalysisOn,value= 0
	CheckBox headStage2_midSweepAnalysisOn,pos={100,82},size={16,14},proc=AM_HeadStageMSCheckBox,title=""
	CheckBox headStage2_midSweepAnalysisOn,value= 0
	CheckBox headStage1_midSweepAnalysisOn,pos={100,107},size={16,14},proc=AM_HeadStageMSCheckBox,title=""
	CheckBox headStage1_midSweepAnalysisOn,value= 0
	CheckBox headStage3_midSweepAnalysisOn,pos={100,132},size={16,14},proc=AM_HeadStageMSCheckBox,title=""
	CheckBox headStage3_midSweepAnalysisOn,value= 0
	CheckBox headStage4_midSweepAnalysisOn,pos={100,157},size={16,14},proc=AM_HeadStageMSCheckBox,title=""
	CheckBox headStage4_midSweepAnalysisOn,value= 0
	CheckBox headStage5_midSweepAnalysisOn,pos={100,182},size={16,14},proc=AM_HeadStageMSCheckBox,title=""
	CheckBox headStage5_midSweepAnalysisOn,value= 0
	CheckBox headStage6_midSweepAnalysisOn,pos={100,207},size={16,14},proc=AM_HeadStageMSCheckBox,title=""
	CheckBox headStage6_midSweepAnalysisOn,value= 0
	CheckBox headStage7_midSweepAnalysisOn,pos={100,232},size={16,14},proc=AM_HeadStageMSCheckBox,title=""
	CheckBox headStage7_midSweepAnalysisOn,value= 0
	PopupMenu MSA_headStage0,pos={120,53},size={125,21},bodyWidth=125,proc=AM_MS_PopMenuChk
	PopupMenu MSA_headStage0,mode=1,popvalue="-None-",value= #"AM_MS_sortFunctions()"
	PopupMenu MSA_headStage1,pos={120,78},size={125,21},bodyWidth=125,proc=AM_MS_PopMenuChk
	PopupMenu MSA_headStage1,mode=1,popvalue="-None-",value= #"AM_MS_sortFunctions()"
	PopupMenu MSA_headStage2,pos={120,103},size={125,21},bodyWidth=125,proc=AM_MS_PopMenuChk
	PopupMenu MSA_headStage2,mode=2,popvalue="-None-",value= #"AM_MS_sortFunctions()"
	PopupMenu MSA_headStage3,pos={120,128},size={125,21},bodyWidth=125,proc=AM_MS_PopMenuChk
	PopupMenu MSA_headStage3,mode=1,popvalue="-None-",value= #"AM_MS_sortFunctions()"
	PopupMenu MSA_headStage4,pos={120,153},size={125,21},bodyWidth=125,proc=AM_MS_PopMenuChk
	PopupMenu MSA_headStage4,mode=4,popvalue="-None-",value= #"AM_MS_sortFunctions()"
	PopupMenu MSA_headStage5,pos={120,178},size={125,21},bodyWidth=125,proc=AM_MS_PopMenuChk
	PopupMenu MSA_headStage5,mode=1,popvalue="-None-",value= #"AM_MS_sortFunctions()"
	PopupMenu MSA_headStage6,pos={120,203},size={125,21},bodyWidth=125,proc=AM_MS_PopMenuChk
	PopupMenu MSA_headStage6,mode=1,popvalue="-None-",value= #"AM_MS_sortFunctions()"
	PopupMenu MSA_headStage7,pos={119,228},size={125,21},bodyWidth=125,proc=AM_MS_PopMenuChk
	PopupMenu MSA_headStage7,mode=1,popvalue="-None-",value= #"AM_MS_sortFunctions()"
	CheckBox headStage0_postSweepAnalysisOn,pos={275,57},size={16,14},proc=AM_HeadStagePSCheckBox,title=""
	CheckBox headStage0_postSweepAnalysisOn,value= 0
	CheckBox headStage1_postSweepAnalysisOn,pos={275,82},size={16,14},proc=AM_HeadStagePSCheckBox,title=""
	CheckBox headStage1_postSweepAnalysisOn,value= 0
	CheckBox headStage2_postSweepAnalysisOn,pos={275,107},size={16,14},proc=AM_HeadStagePSCheckBox,title=""
	CheckBox headStage2_postSweepAnalysisOn,value= 0
	CheckBox headStage3_postSweepAnalysisOn,pos={275,132},size={16,14},proc=AM_HeadStagePSCheckBox,title=""
	CheckBox headStage3_postSweepAnalysisOn,value= 0
	CheckBox headStage4_postSweepAnalysisOn,pos={275,157},size={16,14},proc=AM_HeadStagePSCheckBox,title=""
	CheckBox headStage4_postSweepAnalysisOn,value= 0
	CheckBox headStage5_postSweepAnalysisOn,pos={275,182},size={16,14},proc=AM_HeadStagePSCheckBox,title=""
	CheckBox headStage5_postSweepAnalysisOn,value= 0
	CheckBox headStage6_postSweepAnalysisOn,pos={275,207},size={16,14},proc=AM_HeadStagePSCheckBox,title=""
	CheckBox headStage6_postSweepAnalysisOn,value= 0
	CheckBox headStage7_postSweepAnalysisOn,pos={275,232},size={16,14},proc=AM_HeadStagePSCheckBox,title=""
	CheckBox headStage7_postSweepAnalysisOn,value= 0
	PopupMenu PSA_headStage0,pos={300,53},size={125,21},bodyWidth=125,proc=AM_PS_PopMenuChk
	PopupMenu PSA_headStage0,mode=2,popvalue="-None-",value= #"AM_PS_sortFunctions()"
	PopupMenu PSA_headStage1,pos={300,78},size={125,21},bodyWidth=125,proc=AM_PS_PopMenuChk
	PopupMenu PSA_headStage1,mode=1,popvalue="-None-",value= #"AM_PS_sortFunctions()"
	PopupMenu PSA_headStage2,pos={300,103},size={125,21},bodyWidth=125,proc=AM_PS_PopMenuChk
	PopupMenu PSA_headStage2,mode=2,popvalue="-None-",value= #"AM_PS_sortFunctions()"
	PopupMenu PSA_headStage3,pos={300,128},size={125,21},bodyWidth=125,proc=AM_PS_PopMenuChk
	PopupMenu PSA_headStage3,mode=3,popvalue="-None-",value= #"AM_PS_sortFunctions()"
	PopupMenu PSA_headStage4,pos={300,153},size={125,21},bodyWidth=125,proc=AM_PS_PopMenuChk
	PopupMenu PSA_headStage4,mode=3,popvalue="-None-",value= #"AM_PS_sortFunctions()"
	PopupMenu PSA_headStage5,pos={300,178},size={125,21},bodyWidth=125,proc=AM_PS_PopMenuChk
	PopupMenu PSA_headStage5,mode=1,popvalue="-None-",value= #"AM_PS_sortFunctions()"
	PopupMenu PSA_headStage6,pos={300,203},size={125,21},bodyWidth=125,proc=AM_PS_PopMenuChk
	PopupMenu PSA_headStage6,mode=1,popvalue="-None-",value= #"AM_PS_sortFunctions()"
	PopupMenu PSA_headStage7,pos={300,228},size={125,21},bodyWidth=125,proc=AM_PS_PopMenuChk
	PopupMenu PSA_headStage7,mode=1,popvalue="-None-",value= #"AM_PS_sortFunctions()"
	CheckBox headStage0_postAnalysisActionOn,pos={450,57},size={16,14},proc=AM_HeadStagePACheckBox,title=""
	CheckBox headStage0_postAnalysisActionOn,value= 0
	CheckBox headStage1_postAnalysisActionOn,pos={450,82},size={16,14},proc=AM_HeadStagePACheckBox,title=""
	CheckBox headStage1_postAnalysisActionOn,value= 0
	CheckBox headStage2_postAnalysisActionOn,pos={450,107},size={16,14},proc=AM_HeadStagePACheckBox,title=""
	CheckBox headStage2_postAnalysisActionOn,value= 0
	CheckBox headStage3_postAnalysisActionOn,pos={450,132},size={16,14},proc=AM_HeadStagePACheckBox,title=""
	CheckBox headStage3_postAnalysisActionOn,value= 0
	CheckBox headStage4_postAnalysisActionOn,pos={450,157},size={16,14},proc=AM_HeadStagePACheckBox,title=""
	CheckBox headStage4_postAnalysisActionOn,value= 0
	CheckBox headStage5_postAnalysisActionOn,pos={450,182},size={16,14},proc=AM_HeadStagePACheckBox,title=""
	CheckBox headStage5_postAnalysisActionOn,value= 0
	CheckBox headStage6_postAnalysisActionOn,pos={450,207},size={16,14},proc=AM_HeadStagePACheckBox,title=""
	CheckBox headStage6_postAnalysisActionOn,value= 0
	CheckBox headStage7_postAnalysisActionOn,pos={450,232},size={16,14},proc=AM_HeadStagePACheckBox,title=""
	CheckBox headStage7_postAnalysisActionOn,value= 0
	PopupMenu PAA_headStage0,pos={475,53},size={125,21},bodyWidth=125,proc=AM_PA_PopMenuChk
	PopupMenu PAA_headStage0,mode=2,popvalue="-None-",value= #"AM_PA_sortFunctions()"
	PopupMenu PAA_headStage1,pos={475,78},size={125,21},bodyWidth=125,proc=AM_PA_PopMenuChk
	PopupMenu PAA_headStage1,mode=1,popvalue="-None-",value= #"AM_PA_sortFunctions()"
	PopupMenu PAA_headStage2,pos={475,103},size={125,21},bodyWidth=125,proc=AM_PA_PopMenuChk
	PopupMenu PAA_headStage2,mode=2,popvalue="-None-",value= #"AM_PA_sortFunctions()"
	PopupMenu PAA_headStage3,pos={475,128},size={125,21},bodyWidth=125,proc=AM_PA_PopMenuChk
	PopupMenu PAA_headStage3,mode=3,popvalue="-None-",value= #"AM_PA_sortFunctions()"
	PopupMenu PAA_headStage4,pos={475,153},size={125,21},bodyWidth=125,proc=AM_PA_PopMenuChk
	PopupMenu PAA_headStage4,mode=3,popvalue="-None-",value= #"AM_PA_sortFunctions()"
	PopupMenu PAA_headStage5,pos={475,178},size={125,21},bodyWidth=125,proc=AM_PA_PopMenuChk
	PopupMenu PAA_headStage5,mode=1,popvalue="-None-",value= #"AM_PA_sortFunctions()"
	PopupMenu PAA_headStage6,pos={475,203},size={125,21},bodyWidth=125,proc=AM_PA_PopMenuChk
	PopupMenu PAA_headStage6,mode=1,popvalue="-None-",value= #"AM_PA_sortFunctions()"
	PopupMenu PAA_headStage7,pos={475,228},size={125,21},bodyWidth=125,proc=AM_PA_PopMenuChk
	PopupMenu PAA_headStage7,mode=1,popvalue="-None-",value= #"AM_PA_sortFunctions()"
	Button PAA_headStage0Config, pos={625, 53},size={150, 21},proc=AM_configAnalysis, title="Config Analysis HS 0"
	Button PAA_headStage0Config, help={"Configure the Post Analysis Action routine"}, disable=2
	Button PAA_headStage1Config, pos={625, 78},size={150, 21},proc=AM_configAnalysis, title="Config Analysis HS 1"
	Button PAA_headStage1Config, help={"Configure the Post Analysis Action routine"}, disable=2
	Button PAA_headStage2Config, pos={625, 103},size={150, 21},proc=AM_configAnalysis, title="Config Analysis HS 2"
	Button PAA_headStage2Config, help={"Configure the Post Analysis Action routine"}, disable=2
	Button PAA_headStage3Config, pos={625, 128},size={150, 21},proc=AM_configAnalysis, title="Config Analysis HS 3"
	Button PAA_headStage3Config, help={"Configure the Post Analysis Action routine"}, disable=2
	Button PAA_headStage4Config, pos={625, 153},size={150, 21},proc=AM_configAnalysis, title="Config Analysis HS 4"
	Button PAA_headStage4Config, help={"Configure the Post Analysis Action routine"}, disable=2
	Button PAA_headStage5Config, pos={625, 178},size={150, 21},proc=AM_configAnalysis, title="Config Analysis HS 5"
	Button PAA_headStage5Config, help={"Configure the Post Analysis Action routine"}, disable=2
	Button PAA_headStage6Config, pos={625, 203},size={150, 21},proc=AM_configAnalysis, title="Config Analysis HS 6"
	Button PAA_headStage6Config, help={"Configure the Post Analysis Action routine"}, disable=2
	Button PAA_headStage7Config, pos={625, 228},size={150, 21},proc=AM_configAnalysis, title="Config Analysis HS 7"
	Button PAA_headStage7Config, help={"Configure the Post Analysis Action routine"}, disable=2
EndMacro

Function configureAnalysis(headStageNumber, itcPanel)
	variable headStageNumber
	string itcPanel

	Wave actionScaleSettingsWave = GetActionScaleSettingsWaveRef(itcPanel)	
	
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(1400,200,1675,320) as "configureAnalysis"
	SetDrawLayer UserBack
	DrawText 15, 15, "Configure Analysis Setup - Headstage: " + num2str(headStageNumber)
	SetVariable setCoarseValue, pos={25, 30}, size={180, 30}, title="Coarse Scale Adjustment:"
	SetVariable setCoarseValue, value=actionScaleSettingsWave[headStageNumber][%coarseScaleValue], live=1
	SetVariable setFineValue, pos={25, 55}, size={180, 30}, title="Fine Scale Adjustment:" 
	SetVariable setFineValue, value=actionScaleSettingsWave[headStageNumber][%fineScaleValue], live=1
	SetVariable setThresholdValue, pos={25, 80}, size={180, 30}, title="AP Threshold Adjustment:" 
	SetVariable setThresholdValue, value=actionScaleSettingsWave[headStageNumber][%apThreshold], live=1
	
End

///@brief procedure to pop up the window to configure the analysis stuff
Function AM_configAnalysis(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	switch(ba.eventcode)
		case EVENT_MOUSE_UP:
		
		// get the am panel name
		string itcPanel = GetPopupMenuString(amPanel, "lockedDeviceMenu")
		if (HSU_DeviceIsUnlocked(itcPanel, silentCheck=1))
			print "Please lock a device...."
			return NAN
		endif

		// decipher which headstage we are dealing with
		string controlName = ba.ctrlName
		variable headstageNumber
		sscanf controlName, "PAA_headStage%d", headStageNumber
		configureAnalysis(headStageNumber, itcPanel)
		break
	endswitch
End

///@brief procedure to handle the locked device and set the window title
Function AM_LockedDeviceMenu(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	
	Variable popNum = pa.popNum
	String popStr = pa.popStr
	String panel = pa.win		// window that hosts the popup menu
	
	switch( pa.eventCode )
		case 2: // mouse up
			DoWindow /T $panel, "AM_" + popStr
			break
		case -1: // control being killed
			break
	endswitch	
	
	return 0
End

///@brief procedure to handle the check box for the headstage PS check box
Function AM_HeadStagePSCheckBox(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	Variable checked = cba.checked
	string controlName = cba.ctrlName
	
	switch( cba.eventCode )
		case 2: // mouse up
			AM_PostSweepCheckBox(controlName, checked)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

///@brief procedure to to see if the post Sweep analysis stuff is turned on for a headstage
Function AM_PostSweepCheckBox(ctrlName, checked)
	string ctrlName
	Variable checked
	
	// get the am panel name
	string itcPanel = GetPopupMenuString(amPanel, "lockedDeviceMenu")
	if (HSU_DeviceIsUnlocked(itcPanel, silentCheck=1))
		print "Please lock a device...."
		return NAN
	endif
	
	Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(itcPanel)
		
	Variable headStageClicked
	sscanf ctrlName, "headStage%d_postSweepAnalysisOn", headStageClicked
	
	// check to see if the panel and control exist
	ControlInfo /w = $amPanel $ctrlName
	ASSERT(WindowExists(amPanel), "Analysis master panel must exist")
	
	//build up the string for enabling the config button
	string configButtonEnable
	sprintf configButtonEnable, "PAA_headStage%dConfig", headStageClicked
	
	//build up the strings for disabling the mid sweep checkbox
	string midSweepAnalysisCheck
	sprintf midSweepAnalysisCheck, "headStage%d_midSweepAnalysisOn", headStageClicked
	
	//build up the string for disabling the mid sweep pull down menu 
	string midSweepMenu
	sprintf midSweepMenu, "MSA_headStage%d", headStageClicked
	
	if (checked)	
		print "postSweepAnalysis turned on for headstage #", headStageClicked
		//enable the config button
		ModifyControl $configButtonEnable, disable=0
		// turn off the midSweep analysis
		SetCheckBoxState(amPanel, midSweepAnalysisCheck, 0)
		//disable the mid sweep check box
		ModifyControl $midSweepAnalysisCheck, disable=2	
		//disable the mid sweep menu
		ModifyControl $midSweepMenu, disable=2
	else
		print "postSweepAnalysis turned off for headstage #", headStageClicked
		//disable the config button
		ModifyControl $configButtonEnable, disable=2
		//enable the mid sweep check box
		ModifyControl $midSweepAnalysisCheck, disable=0
		//enable the mid sweep menu
		ModifyControl $midSweepMenu, disable=0		
	endif
	
	analysisSettingsWave[headStageClicked][%PSAOnOff] = num2str(checked)
	
	//enable the config button
	
end

///@brief function to handle the PA check box control
Function AM_HeadStagePACheckBox(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	Variable checked = cba.checked
	string controlName = cba.ctrlName
	
	switch( cba.eventCode )
		case 2: // mouse up
			AM_PostAnalysisCheckBox(cba)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

///@brief function to to see if the post analysis action stuff is turned on for a headstage
Function AM_PostAnalysisCheckBox(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	
	switch( cba.eventCode )
		case 2: // mouse up
			string ctrlName = cba.ctrlName
			Variable checked = cba.checked
	
			// get the da_ephys panel name
			string itcPanel = GetPopupMenuString(amPanel, "lockedDeviceMenu")
			if (HSU_DeviceIsUnlocked(itcPanel, silentCheck=1))
				print "Please lock a device...."
				return NAN
			endif
			
			Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(itcPanel)
			
			Variable headStageClicked
			sscanf ctrlName, "headStage%d_postAnalysisActionOn", headStageClicked 
			
			//build up the string for enabling the config button
			string configButtonEnable
			sprintf configButtonEnable, "PAA_headStage%dConfig", headStageClicked
			
			//build up the strings for disabling the mid sweep checkbox
			string midSweepAnalysisCheck
			sprintf midSweepAnalysisCheck, "headStage%d_midSweepAnalysisOn", headStageClicked
			
			//build up the string for disabling the mid sweep pull down menu 
			string midSweepMenu
			sprintf midSweepMenu, "MSA_headStage%d", headStageClicked
			
			//build up the string for enabling the post sweep analysis---the post analysis action needs the post sweep analysis enabled to work
			string postSweepAnalysisCheck
			sprintf postSweepAnalysisCheck, "headStage%d_postSweepAnalysisOn", headStageClicked
			
			// check to see if the panel and control exist
			ControlInfo /w = $amPanel $ctrlName
			ASSERT(V_flag != 0, "non-existing window or control")
			
			if (checked)	
				print "postAnalysisAction turned on for headstage #", headStageClicked	
				//enable the config button
				ModifyControl $configButtonEnable, disable=0
				//check on the postSweepAnalysis check box
				SetCheckBoxState(amPanel, postSweepAnalysisCheck, 1)
				//check off the midsweepAnalysis
				SetCheckBoxState(amPanel, midSweepAnalysisCheck, 0)
				//disable the mid sweep check box
				ModifyControl $midSweepAnalysisCheck, disable=2
				//disable the mid sweep menu
				ModifyControl $midSweepMenu, disable=2
			else
				print "postAnalysisAction turned off for headstage #", headStageClicked
				//disable the config button
				ModifyControl $configButtonEnable, disable=2
				//check off the postSweepAnalysis check box
				SetCheckBoxState(amPanel, postSweepAnalysisCheck, 0)
				//enable the mid sweep check box
				ModifyControl $midSweepAnalysisCheck, disable=0
				//enable the mid sweep menu
				ModifyControl $midSweepMenu, disable=0
			endif
			analysisSettingsWave[headStageClicked][%PAAOnOff] = num2str(checked)
		case -1: // control being killed
			break
	endswitch
	
	return 0
End

///@brief function to handle the midSweep Analysis check box control
Function AM_HeadStageMSCheckBox(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	Variable checked = cba.checked
	string controlName = cba.ctrlName
	Variable panelName = cba.win
	
	switch( cba.eventCode )
		case 2: // mouse up
			AM_midSweepAnalysisCheckBox(cba)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

///@brief function to to see if the midSweep analysis stuff is turned on for a headstage
Function AM_midSweepAnalysisCheckBox(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	
	switch( cba.eventCode )
		case 2: // mouse up
			string ctrlName = cba.ctrlName
			Variable checked = cba.checked
			
			string itcPanel = GetPopupMenuString(amPanel, "lockedDeviceMenu")
			if (HSU_DeviceIsUnlocked(itcPanel, silentCheck=1))
				print "Please lock a device...."
				return NAN
			endif
			
			Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(itcPanel)
			
			Variable headStageClicked
			sscanf ctrlName, "headStage%d_midSweepAnalysisActionOn", headStageClicked 
			
			//build up the string for enabling the config button
			string configButtonEnable
			sprintf configButtonEnable, "PAA_headStage%dConfig", headStageClicked
			
			//build up the strings for disabling the post sweep checkboxes
			string postSweepAnalysisCheck
			string postAnalysisActionCheck
			sprintf postSweepAnalysisCheck, "headStage%d_postSweepAnalysisOn", headStageClicked
			sprintf postAnalysisActionCheck, "headStage%d_postAnalysisActionOn", headStageClicked
			
			//build up the string for disabling the post sweep analysis pull down menu 
			string postSweepMenu
			sprintf postSweepMenu, "PSA_headStage%d", headStageClicked
			
			//build up the string for disabling the post sweep analysis pull down menu 
			string postAnalysisMenu
			sprintf postAnalysisMenu, "PAA_headStage%d", headStageClicked
			
			// check to see if the panel and control exist
			ControlInfo /w = $amPanel $ctrlName
			ASSERT(V_flag != 0, "non-existing window or control")
			
			if (checked)	
				print "midSweepAnalysisAction turned on for headstage #", headStageClicked
				//enable the config button
				ModifyControl $configButtonEnable, disable=0
				//disable the postSweep stuff
				ModifyControl $postSweepAnalysisCheck, disable=2
				ModifyControl $postAnalysisActionCheck, disable=2
				ModifyControl $postSweepMenu, disable=2
				ModifyControl $postAnalysisMenu, disable=2
			else
				print "midSweepAnalysisAction turned off for headstage #", headStageClicked
				//disable the config button
				ModifyControl $configButtonEnable, disable=2
				//enable the postSweep stuff
				ModifyControl $postSweepAnalysisCheck, disable=0
				ModifyControl $postAnalysisActionCheck, disable=0
				ModifyControl $postSweepMenu, disable=0
				ModifyControl $postAnalysisMenu, disable=0	
			endif
			analysisSettingsWave[headStageClicked][%MSAOnOff] = num2str(checked)
		case -1: // control being killed
			break
	endswitch
	
	return 0
End

///@brief function for putting the name of the PostSweepAnalysis function into the analysisMaster wave
Function AM_PS_PopMenuChk(pa) : PopupMenuControl  
	STRUCT WMPopupAction &pa
	
	switch( pa.eventCode )
		case 2: // mouse up
			variable popNum = pa.popNum
			String popStr = pa.popStr
			string  ctrlName = pa.ctrlName
				
			// get the da_ephys panel name
			string itcPanel = GetPopupMenuString(amPanel, "lockedDeviceMenu")
			if (HSU_DeviceIsUnlocked(itcPanel, silentCheck=1))
				print "Please lock a device...."
				return NAN
			endif
				
			Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(itcPanel)
			
			Variable headStageSelected
			sscanf ctrlName, "PSA_headStage%d", headStageSelected
			
			// check to see if the panel and control exist
			ControlInfo /w = $amPanel $ctrlName
			ASSERT(V_flag != 0, "non-existing window or control")
			
			analysisSettingsWave[headStageSelected][%PSAType] = popStr
			
		case -1: // control being killed
			break
	endswitch

	return 0
End	
			
///@brief function for putting the name of the PostAnalysisAction function into the analysisMaster wave
Function AM_PA_PopMenuChk(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			variable popNum = pa.popNum
			String popStr = pa.popStr
			string  ctrlName = pa.ctrlName
		
			// get the da_ephys panel name
			string itcPanel = GetPopupMenuString(amPanel, "lockedDeviceMenu")
			if (HSU_DeviceIsUnlocked(itcPanel, silentCheck=1))
				print "Please lock a device...."
				return NAN
			endif
			
			Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(itcPanel)
			
			Variable headStageSelected
			sscanf ctrlName, "PAA_headStage%d", headStageSelected
			
			// check to see if the panel and control exist
			ControlInfo /w = $amPanel $ctrlName
			ASSERT(V_flag != 0, "non-existing window or control")
			
			analysisSettingsWave[headStageSelected][%PAAType] = popStr		
		case -1: // control being killed
			break
	endswitch

	return 0
End

///@brief function for putting the name of the PostAnalysisAction function into the analysisMaster wave
Function AM_MS_PopMenuChk(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			variable popNum = pa.popNum
			String popStr = pa.popStr
			string  ctrlName = pa.ctrlName
		
			// get the da_ephys panel name
			string itcPanel = GetPopupMenuString(amPanel, "lockedDeviceMenu")
			if (HSU_DeviceIsUnlocked(itcPanel, silentCheck=1))
				print "Please lock a device...."
				return NAN
			endif
			
			Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(itcPanel)
			
			Variable headStageSelected
			sscanf ctrlName, "MSA_headStage%d", headStageSelected
			
			// check to see if the panel and control exist
			ControlInfo /w = $amPanel $ctrlName
			ASSERT(V_flag != 0, "non-existing window or control")
			
			analysisSettingsWave[headStageSelected][%MSAType] = popStr		
		case -1: // control being killed
			break
	endswitch

	return 0
End

///@brief function for making the list for PSA functions more readable...
Function/S AM_PS_sortFunctions()
	return AM_sortAMFunctions("PSA")
End	 

///@brief function for making the list for PAA functions more readable...
Function/S AM_PA_sortFunctions()	
	return AM_sortAMFunctions("PAA")
End	

///@brief function for making the list for MSA functions more readable...
Function/S AM_MS_sortFunctions()	
	return AM_sortAMFunctions("MSA")
End 	

///@brief function for sorting PA and PS function for populating pull down menus
static Function/S AM_sortAMFunctions(str)
	string str
	
	string funcList = FunctionList("*" + str + "*", ";", "")
	variable noFunctions = ItemsInList(funcList)
	string editedList = "-None-"
	string func, editedFunc
	string funcTemplate = "AM_" + str + "_%s"
	variable i
	
	for (i = 0; i < noFunctions; i += 1)
	    func = StringFromList(i, funcList)
	    sscanf func, funcTemplate, editedFunc
	    editedList = AddListItem(editedFunc, editedList, ";", INF)
	endfor

	return editedList
End