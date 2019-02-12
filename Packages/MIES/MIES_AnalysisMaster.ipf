#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_AM
#endif

/// @file MIES_AnalysisMaster.ipf
/// @brief __AM__ Waveform analysis framework

///@brief Function used to create a framework for calling post-sweep analysis functions
Function AM_analysisMasterPostSweep(panelTitle, sweepNo)
	string panelTitle
	variable sweepNo
	
	variable headStageCounter
	string analysisAction
	string editedAnalysisAction
	variable analysisResult
	string postAnalysisFunction
	string editedPostAnalysisFunction
	variable postAnalysisResult
			
	Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(panelTitle)
	
	// Go through the analysisSettingsWave and decode the settings to invoke analysis routines
	for(headStageCounter = 0; headStageCounter < NUM_HEADSTAGES; headStageCounter += 1)
		if(str2num(analysisSettingsWave[headStageCounter][%PSAOnOff]) == 1) // do the post sweep analysis
			editedAnalysisAction = analysisSettingsWave[headStageCounter][%PSAType]
			
			sprintf analysisAction, "AM_PSA_%s", editedAnalysisAction
			
			// put the analysisAction into a form that can be used to call a function
			FUNCREF protoAnalysisFunc psaf = $analysisAction
			analysisResult = psaf(panelTitle, headStageCounter)
			analysisSettingsWave[headStageCounter][%PSAResult] = num2str(analysisResult)
				
			if(str2num(analysisSettingsWave[headStageCounter][%PAAOnOff]) == 1) // do the post analysis action		
				editedPostAnalysisFunction = analysisSettingsWave[headStageCounter][%PAAType]
					
				sprintf postAnalysisFunction, "AM_PAA_%s", editedPostAnalysisFunction
				
				// put the analysisAction into a form that can be used to call a function
				FUNCREF protoAnalysisFunc paaf = $postAnalysisFunction
				postAnalysisResult = paaf(panelTitle, headStageCounter)
				analysisSettingsWave[headStageCounter][%PAAResult] = num2str(postAnalysisResult)
			endif					
		endif
	endfor
	
	return postAnalysisResult
End

///@brief function for invoking analysis functions in midSweep
Function AM_analysisMasterMidSweep(panelTitle)
	string panelTitle
	
	string analysisAction
	string editedAnalysisAction
	variable analysisResult
	
	Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(panelTitle)
	Wave actionScaleSettingsWave =  GetActionScaleSettingsWaveRef(panelTitle)
	
	// Go through the analysisSettingsWave and decode the settings to invoke the midsweep analysis routine
	variable headStageCounter
	for(headStageCounter = 0; headStageCounter < NUM_HEADSTAGES; headStageCounter += 1)
		if(str2num(analysisSettingsWave[headStageCounter][%MSAOnOff]) == 1) // do the mid sweep analysis
			editedAnalysisAction = analysisSettingsWave[headStageCounter][%MSAType]
			
			sprintf analysisAction, "AM_MSA_%s", editedAnalysisAction
			
			// put the analysisAction into a form that can be used to call a function
			FUNCREF protoAnalysisFunc psaf = $analysisAction
			analysisResult = psaf(panelTitle, headStageCounter)
			analysisSettingsWave[headStageCounter][%MSAResult] = num2str(analysisResult)
		endif
	endfor
End

///@brief prototype Analysis function
Function protoAnalysisFunc(a,b)
	string a
	variable b
	
	print "in protoAnalysisFunc for", a
	print "in protoAnalysisFunc for", b
	variable result = 0
	return result
End

///@brief function that will search for an action potential during an ongoing sweep and abort the sweep if the AP fires
Function AM_MSA_midSweepFindAP(panelTitle, headStage)
	string panelTitle
	variable headStage

	Variable apLevelValue
	variable xPoint

	Wave/SDFR=GetDevicePath(panelTitle) currentCompleteDataWave = ITCDataWave
	
	Wave actionScaleSettingsWave =  GetActionScaleSettingsWaveRef(panelTitle)	
	Wave/Z sweep = AFH_GetLastSweepWaveAcquired(panelTitle)	
	if(!WaveExists(sweep))
		DoAbortNow("***Error getting current sweep wave...")
	endif

	WAVE singleAD = AFH_ExtractOneDimDataFromSweep(panelTitle, sweep, headstage, ITC_XOP_CHANNEL_TYPE_ADC)

	apLevelValue = actionScaleSettingsWave[headStage][%apThreshold]
	FindLevel/P/Q/EDGE=1 SingleAD, apLevelValue
	xPoint=V_LevelX
	if (V_flag == 0)
		print "AP level found at" , xPoint
		DQ_StopOngoingDAQ(panelTitle)
	endif
End	

///@brief function to run QC functions after a sweep completes.  Will check bridge balance, bias current injection, high frequency noise/patch instability RMS noise
/// and voltage stability
Function AM_PSA_sweepLevelQC(panelTitle, headStage)
	string panelTitle
	variable headStage

	variable sweepNo
	variable numDACs
	variable idx
	variable tracePeakValue
	variable bridgeBalance
	variable biasCurrent
	variable sampIntMult
	variable hertzRate
	variable idx0, idx1
	variable segMean
	variable segRMS
	variable upValsSize
	variable downValsSize
	variable i
	variable first
	variable preStimMean
	variable postStimMean
	string currentClampControl
	variable currentClampState
	variable upIdx
	variable downIdx
	variable clampMode

	Make/D/FREE upVals, downVals

	Wave/SDFR=GetDevicePath(panelTitle) currentCompleteDataWave = ITCDataWave
	Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(panelTitle)
	Wave actionScaleSettingsWave =  GetActionScaleSettingsWaveRef(panelTitle)

	Wave/Z sweepWave = AFH_GetLastSweepWaveAcquired(panelTitle)
	if(!WaveExists(sweepWave))
		DoAbortNow("Error getting most recent sweepWave wave...")
	endif

	WAVE singleAD = AFH_ExtractOneDimDataFromSweep(panelTitle, sweepWave, headstage, ITC_XOP_CHANNEL_TYPE_ADC)

	// check that the bridge balance is less than 20MOhms....will also need to check that its 15% of Rinput...
	bridgeBalance = str2num(GetGuiControlValue(panelTitle, "setVar_DataAcq_BB"))
	if(bridgeBalance>20)
		print "Bridge Balance Check failed..."
		analysisSettingsWave[headStage][%PSAResult] = "0"
		return 0
	endif

	// check that the bias current injection is less than +/100 pA
	clampMode = DAG_GetHeadstageMode(panelTitle, headstage)
	biasCurrent = AI_SendToAmp(panelTitle, headStage, clampMode, MCC_GETHOLDING_FUNC, NaN)
	if(abs(biasCurrent) > 100)
		print "Bias Current Check failed..."
		analysisSettingsWave[headStage][%PSAResult] = "0"
		return 0
	endif

	// check the high frequency noise/patch instability RMS in a short (1.5 ms) window
	// get the sampling interval multiplier
	sampIntMult = str2num(GetGuiControlValue(panelTitle, "Popup_Settings_SampIntMult"))
	hertzRate = 200200/sampIntMult

	// get the last vm epoch
	idx1 = dimSize(singleAD, COLS)
	idx0 = idx1 - (0.500*hertzRate)

	// measure vm of the segment
	Duplicate/FREE/R=[idx0,(idx1-1)] singleAD, sweepSegment
	segMean = mean(sweepSegment)
	sweepSegment -= segMean
	sweepSegment = sweepSegment^2
	segRMS = sqrt(mean(sweepSegment))

	// check the RMS against the QC criteria
	if(segRMS>0.05)
		print "Post Noise Long RMS check failed..."
		analysisSettingsWave[headStage][%PSAResult] = "0"
		return 0
	endif

	// now do that same check with a shorter window
	idx1 = dimSize(singleAD, ROWS)
	idx0 = idx1 - (0.0015*hertzRate)

	// measure vm of the shorter segment
	Duplicate/FREE/R=[idx0,(idx1-1)] singleAD, sweepSegment
	segMean = mean(sweepSegment)
	sweepSegment -= segMean
	sweepSegment = sweepSegment^2
	segRMS = sqrt(mean(sweepSegment))

	// check the RMS against the QC criteria
	if(segRMS>0.07)
		print "Post Noise Short RMS check failed..."
		analysisSettingsWave[headStage][%PSAResult] = "0"
		return 0
	endif

	// Check the voltage stability
	Duplicate/FREE singleAD, sweepDiff
	Differentiate/METH=1 sweepDiff

	idx1 = dimSize(sweepDiff, ROWS)
	for(i=0;i<idx1;i+=1)
		if(sweepDiff[i]>0.0)
			EnsureLargeEnoughWave(upVals, minimumsize=upIdx, dimension=ROWS)
			upVals[upIdx] = i
			upIdx += 1
		elseif(sweepDiff[i]<0.0)
			EnsureLargeEnoughWave(downVals, minimumsize=downIdx, dimension=ROWS)
			downVals[downIdx] = i
			downIdx += 1
		endif
   endfor


	upValsSize=dimSize(upVals, ROWS)
	downValsSize = dimSize(downVals, ROWS)

	FindLevel/EDGE=1/P/Q upVals, first

	 for(i=0;i<downValsSize;i+=1)
		if((downVals[i]>=0) && (downVals[i] < first))
			first=downVals[i]
			break
		endif
	endfor

	// find the voltage immediately before the stimulus
	idx0 = first-(0.5*hertzRate)
	Duplicate/O/R=[idx0,first] singleAD, sweepSegment
	preStimMean = mean(sweepSegment)

	idx1=dimSize(singleAD, ROWS)
	idx0=idx1-(0.5*hertzRate)
	Duplicate/O/R=[idx0,idx1] singleAD, sweepSegment
	postStimMean=mean(sweepSegment)

	// check the Voltage Stability -- things have to have been run in current clamp mode to get the voltage value
	currentClampState=DAG_GetHeadstageMode(panelTitle, headStage)
	if(currentClampState == V_CLAMP_MODE)
		print "Must be in current clamp mode...please set and try again..."
		analysisSettingsWave[headStage][%PSAResult] = "0"
		return 0
	elseif((abs(postStimMean-preStimMean))>1.0)
		print "Failed voltage stability QC check..."
		analysisSettingsWave[headStage][%PSAResult] = "0"
		return 0
	else // success!
		print "Sweep Level QC passed..."
		analysisSettingsWave[headStage][%PSAResult] = "1"
		return 1
	endif
End

///@brief function will return a variable to indicate if the value at the start of the stimulus wave is more than 1mv different from the end of the stimulus wave, and then checks the average versus
/// the elapsed time..  To be used during the electrode drift QC check
Function AM_PSA_electrodeBaselineQC(panelTitle, headStage)
	string panelTitle
	variable headStage
	
	variable x
	variable numDACs
	variable idx
	variable tracePeakValue
	variable preVm
	variable postVm
	variable sampIntMult
	variable numRows
	variable meanValue
	variable elapsedTime
	variable returnValue
	variable len
	string responseString
	
	Wave/SDFR=GetDevicePath(panelTitle) currentCompleteDataWave = ITCDataWave	
	Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(panelTitle)
	Wave actionScaleSettingsWave =  GetActionScaleSettingsWaveRef(panelTitle)
	elapsedTime = actionScaleSettingsWave[headStage][%elapsedTime]	
	Wave/Z sweep = AFH_GetLastSweepWaveAcquired(panelTitle)
	if(!WaveExists(sweep))
		DoAbortNow("Error getting current sweep wave...")
	endif
	
	Wave config = GetConfigWave(sweep)
	x = AFH_GetADCFromHeadstage(panelTitle, headStage)
	ASSERT(x >= 0, "Could not query AD channel")

	WAVE ADCs = GetADCListFromConfig(config)
	WAVE DACs = GetDACListFromConfig(config)
	numDACs = DimSize(DACs, ROWS)
	idx = GetRowIndex(ADCs, val=x)
	ASSERT(IsFinite(idx), "Missing AD channel")

	matrixOp/FREE SingleAD = col(currentCompleteDataWave, numDACs + idx)
	
	// get the sampling interval multipler from the gui
	sampIntMult = str2num(GetPopupMenuString(panelTitle, "popup_Settings_SampIntMult"))	
	
	preVm = mean(SingleAD, (100100/sampIntMult), (200200/sampIntMult)) // gives the average of the pre-stimulus trace from 0.5 seconds to 1 seconds
	print "preVm: ", preVm
	numRows = DimSize(SingleAD, ROWS)
	postVm = mean(SingleAD, (numRows - (100100/sampIntMult)), (numRows - 1))
	print "postVm: ", postVm
		
	// see if the diff between the endValue is more than 1mv different than initValue
	if((abs(preVm - postVm)) < 1) 	
		print "baseline Diff check passed" + num2str(headStage)
		// get the mean value of the wave
		meanValue = mean(SingleAD)
	
		if (meanValue > (elapsedTime/10))
			print "Electrode Drift QC check failed..."
			analysisSettingsWave[headStage][%PSAResult] = "0"
		else
			print "Electrode Drift QC check passed..."
			analysisSettingsWave[headStage][%PSAResult] = "1"
			returnValue = 1
		endif
	else
		print "baseline Diff QC check failed..."
		analysisSettingsWave[headStage][%PSAResult] = "0"
	endif
	
	//  See if we need to send a response string to the WSE
	// get the reference to the asyn response wave ref 
	Wave/T asynRespWave = GetAsynRspWaveRef(panelTitle)
	
	//  See if there is anything in the cmdID space
	len = strlen(asynRespWave[headstage][%cmdID])
	
	if(len >= 1)
		// build up the response string
		sprintf responseString, "ElectrodeDriftQC:%f", returnValue
		writeAsyncResponseWrapper(asynRespWave[headstage][%cmdID], responseString)
	else
		print "No asyn response required..."
	endif 
	
	// kill the asynRespWave
	KillWaves asynRespWave
	
	return 1
End	

				
///@brief function will return a variable to indicate if the most recent wave fired an action potential.
Function AM_PSA_returnActionPotential(panelTitle, headStage)
	string panelTitle
	variable headStage

	variable tracePeakValue

	Wave/SDFR=GetDevicePath(panelTitle) currentCompleteDataWave = ITCDataWave	
	Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(panelTitle)
	Wave actionScaleSettingsWave =  GetActionScaleSettingsWaveRef(panelTitle)	
	Wave/Z sweep = AFH_GetLastSweepWaveAcquired(panelTitle)
	if(!WaveExists(sweep))
		DoAbortNow("Error getting current sweep wave...")
	endif

	WAVE singleAD = AFH_ExtractOneDimDataFromSweep(panelTitle, sweep, headstage, ITC_XOP_CHANNEL_TYPE_ADC)

	tracePeakValue = WaveMax(singleAD)	

	// see if the tracePeakValue is greater then the apThreshold value...if so, indicate that the action potential fired
	if(tracePeakValue > actionScaleSettingsWave[headStage][%apThreshold])	
		print "AP Fired: HS#" + num2str(headStage)
		analysisSettingsWave[headStage][%PSAResult] = "1"
		return 1
	else
		analysisSettingsWave[headStage][%PSAResult] = "0"
		return 0
	endif
End	

///@brief function used to adjust the scale factor for adaptive stim cycling
Function AM_PAA_adjustScaleFactor(panelTitle, headStage)
	string panelTitle
	variable headStage
	
	Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(panelTitle)	
	Wave actionScaleSettingsWave = GetActionScaleSettingsWaveRef(panelTitle)
	
	variable len 
	string responseString
	variable daChannel
	string scaleControlName
	variable scaleFactor
	variable incValue
	variable analysisResult
	
	// get the DA channel associated with the desired headstage
	daChannel = AFH_GetDACFromHeadstage(panelTitle, headStage)
	sprintf scaleControlName, "Scale_DA_0%d", daChannel
	scaleFactor = GetSetVariable(panelTitle, scaleControlName)
	
	// for this, use the coarse scale factor for the adjustment	
	incValue = actionScaleSettingsWave[headStage][%coarseScaleValue]
	
	// Fetch the post sweep analysis result
	analysisResult = str2num(analysisSettingsWave[headStage][%PSAResult])
	
	if(analysisResult == 0)	// action potential did not fire
		scaleFactor = scaleFactor + incValue
		print "New scaleFactor: ", scaleFactor
		PGC_SetAndActivateControl(panelTitle, scaleControlName, val = scaleFactor)
		return 0
	else		
		// stop the ongoing acquisition
		DQ_StopOngoingDAQ(panelTitle)
		
		// return the scale factor that caused the AP to fire
		actionScaleSettingsWave[headStage][%result] = scaleFactor
		print "scale factor that caused AP: ", scaleFactor	
		
		//  See if we need to send a response string to the WSE
		// get the reference to the asyn response wave ref 
		Wave/T asynRespWave = GetAsynRspWaveRef(panelTitle)
		
		//  See if there is anything in the cmdID space
		len = strlen(asynRespWave[headstage][%cmdID])
		
		if(len >= 1)
			// build up the response string
			sprintf responseString, "scaleFactor:%f", scaleFactor
			writeAsyncResponseWrapper(asynRespWave[headstage][%cmdID], responseString)
		else
			print "No asyn response required..."
		endif 
		
		// kill the asynRespWave
		KillWaves asynRespWave
		
		// Now put the scale factor back to 1.0
		PGC_SetAndActivateControl(panelTitle, scaleControlName, val = 1.0)
		return 1
	endif
End

///@brief function used to adjust the scale factor for adaptive stim cycling -- needs to be used with the returnActionPotential postSweep Analysis function
Function AM_PAA_bracketScaleFactor(panelTitle, headStage)
	string panelTitle
	variable headStage
	
	Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(panelTitle)	
	Wave actionScaleSettingsWave = GetActionScaleSettingsWaveRef(panelTitle)
	
	variable len
	string responseString
	variable daChannel
	string scaleControlName
	variable scaleFactor
	variable initialScaleFactor
	variable analysisResult
	
	// get the DA channel associated with the desired headstage
	daChannel = AFH_GetDACFromHeadstage(panelTitle, headStage)
	
	sprintf scaleControlName, "Scale_DA_0%d", daChannel
	scaleFactor = GetSetVariable(panelTitle, scaleControlName)
	initialScaleFactor = scaleFactor
	
	// Fetch the post sweep analysis result
	analysisResult = str2num(analysisSettingsWave[headStage][%PSAResult])

	if((analysisResult == 0)                                         \
	   && (actionScaleSettingsWave[headStage][%coarseTuneUse] == 1)  \
	   && (actionScaleSettingsWave[headStage][%fineTuneUse] == 0))
		// action potential did not fire while using coarse tune
		scaleFactor = scaleFactor + actionScaleSettingsWave[headStage][%coarseScaleValue]
		PGC_SetAndActivateControl(panelTitle, scaleControlName, val = scaleFactor)
		return 0
	elseif((analysisResult == 1)                                        \
		   && (actionScaleSettingsWave[headStage][%coarseTuneUse] == 1) \
		   && (actionScaleSettingsWave[headStage][%fineTuneUse] == 0))
		   // action potential fired on the coarse tuning
		print "switching to fine factor..."
		// bump the scale back one step of the coarse incValue
		PGC_SetAndActivateControl(panelTitle, scaleControlName, val = (scaleFactor - actionScaleSettingsWave[headStage][%coarseScaleValue]))
		
		// turn off the coarseTuneUse
		actionScaleSettingsWave[headStage][%coarseTuneUse] = 0
		
		// turn on the fineTuneUse
		actionScaleSettingsWave[headStage][%fineTuneUse] = 1
		
		return 0
	elseif((analysisResult == 0)                                        \
		   && (actionScaleSettingsWave[headStage][%coarseTuneUse] == 0) \
		   && (actionScaleSettingsWave[headStage][%fineTuneUse] == 1))
		   // action potential didn't fire on the fine tuning
		// bump up the scale factor by the fine Scale adjustment
		scaleFactor = scaleFactor + actionScaleSettingsWave[headStage][% fineScaleValue]
		
		PGC_SetAndActivateControl(panelTitle, scaleControlName, val = scaleFactor)
		return 0
	elseif((analysisResult == 1)                                        \
		   && (actionScaleSettingsWave[headStage][%coarseTuneUse] == 0) \
		   && (actionScaleSettingsWave[headStage][%fineTuneUse] == 1))
		   // action potential fired on the fine tuning
		print "found the AP!"
		// Stop the ongoing data acquisition
		DQ_StopOngoingDAQ(panelTitle)
		
		// set things back to the starting point so that the next time this is used it will be in the correct state
		actionScaleSettingsWave[headStage][%fineTuneUse] = 0
		actionScaleSettingsWave[headStage][%coarseTuneUse] = 1
		
		// return the scale factor that caused the AP to fire
		actionScaleSettingsWave[headStage][%result] = scaleFactor
		print "scale factor that caused AP: ", scaleFactor	
		
		//  See if we need to send a response string to the WSE
		// get the reference to the asyn response wave ref 
		Wave/T asynRespWave = GetAsynRspWaveRef(panelTitle)
		
		//  See if there is anything in the cmdID space
		len = strlen(asynRespWave[headstage][%cmdID])
		
		if(len >= 1)
			// build up the response string
			sprintf responseString, "scaleFactor:%f", scaleFactor
			writeAsyncResponseWrapper(asynRespWave[headstage][%cmdID], responseString)
		else
			print "No asyn response required..."
		endif 
		
		// kill the asynRespWave
		KillWaves asynRespWave
		
		// Now put the scale factor back to 1.0
		PGC_SetAndActivateControl(panelTitle, scaleControlName, val = 1.0)
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
	PopupMenu lockedDeviceMenu,mode=1,popvalue="-None-",value= #"GetListOfLockedDevices()", help={"List of locked ITC panels"}
	CheckBox headStage0_midSweepAnalysisOn,pos={100,57},size={16,14},proc=AM_HeadStageMSCheckBox,title=""
	CheckBox headStage0_midSweepAnalysisOn,value= 0, help={"Select a mid sweep action routine for headstage 0"}
	CheckBox headStage2_midSweepAnalysisOn,pos={100,82},size={16,14},proc=AM_HeadStageMSCheckBox,title=""
	CheckBox headStage2_midSweepAnalysisOn,value= 0, help={"Select a mid sweep action routine for headstage 1"}
	CheckBox headStage1_midSweepAnalysisOn,pos={100,107},size={16,14},proc=AM_HeadStageMSCheckBox,title=""
	CheckBox headStage1_midSweepAnalysisOn,value= 0, help={"Select a mid sweep action routine for headstage 2"}
	CheckBox headStage3_midSweepAnalysisOn,pos={100,132},size={16,14},proc=AM_HeadStageMSCheckBox,title=""
	CheckBox headStage3_midSweepAnalysisOn,value= 0, help={"Select a mid sweep action routine for headstage 3"}
	CheckBox headStage4_midSweepAnalysisOn,pos={100,157},size={16,14},proc=AM_HeadStageMSCheckBox,title=""
	CheckBox headStage4_midSweepAnalysisOn,value= 0, help={"Select a mid sweep action routine for headstage 4"}
	CheckBox headStage5_midSweepAnalysisOn,pos={100,182},size={16,14},proc=AM_HeadStageMSCheckBox,title=""
	CheckBox headStage5_midSweepAnalysisOn,value= 0, help={"Select a mid sweep action routine for headstage 5"}
	CheckBox headStage6_midSweepAnalysisOn,pos={100,207},size={16,14},proc=AM_HeadStageMSCheckBox,title=""
	CheckBox headStage6_midSweepAnalysisOn,value= 0, help={"Select a mid sweep action routine for headstage 6"}
	CheckBox headStage7_midSweepAnalysisOn,pos={100,232},size={16,14},proc=AM_HeadStageMSCheckBox,title=""
	CheckBox headStage7_midSweepAnalysisOn,value= 0, help={"Select a mid sweep action routine for headstage 7"}
	PopupMenu MSA_headStage0,pos={120,53},size={125,21},bodyWidth=125,proc=AM_MS_PopMenuChk
	PopupMenu MSA_headStage0,mode=1,popvalue="-None-",value= #"AM_MS_sortFunctions()", help={"Select a post sweep action routine for headstage 0"}
	PopupMenu MSA_headStage1,pos={120,78},size={125,21},bodyWidth=125,proc=AM_MS_PopMenuChk
	PopupMenu MSA_headStage1,mode=1,popvalue="-None-",value= #"AM_MS_sortFunctions()", help={"Select a post sweep action routine for headstage 1"}
	PopupMenu MSA_headStage2,pos={120,103},size={125,21},bodyWidth=125,proc=AM_MS_PopMenuChk
	PopupMenu MSA_headStage2,mode=2,popvalue="-None-",value= #"AM_MS_sortFunctions()", help={"Select a post sweep action routine for headstage 2"}
	PopupMenu MSA_headStage3,pos={120,128},size={125,21},bodyWidth=125,proc=AM_MS_PopMenuChk
	PopupMenu MSA_headStage3,mode=1,popvalue="-None-",value= #"AM_MS_sortFunctions()", help={"Select a post sweep action routine for headstage 3"}
	PopupMenu MSA_headStage4,pos={120,153},size={125,21},bodyWidth=125,proc=AM_MS_PopMenuChk
	PopupMenu MSA_headStage4,mode=4,popvalue="-None-",value= #"AM_MS_sortFunctions()", help={"Select a post sweep action routine for headstage 4"}
	PopupMenu MSA_headStage5,pos={120,178},size={125,21},bodyWidth=125,proc=AM_MS_PopMenuChk
	PopupMenu MSA_headStage5,mode=1,popvalue="-None-",value= #"AM_MS_sortFunctions()", help={"Select a post sweep action routine for headstage 5"}
	PopupMenu MSA_headStage6,pos={120,203},size={125,21},bodyWidth=125,proc=AM_MS_PopMenuChk
	PopupMenu MSA_headStage6,mode=1,popvalue="-None-",value= #"AM_MS_sortFunctions()", help={"Select a post sweep action routine for headstage 6"}
	PopupMenu MSA_headStage7,pos={119,228},size={125,21},bodyWidth=125,proc=AM_MS_PopMenuChk
	PopupMenu MSA_headStage7,mode=1,popvalue="-None-",value= #"AM_MS_sortFunctions()", help={"Select a post sweep action routine for headstage 7"}
	CheckBox headStage0_postSweepAnalysisOn,pos={275,57},size={16,14},proc=AM_HeadStagePSCheckBox,title=""
	CheckBox headStage0_postSweepAnalysisOn,value= 0, help={"Activate post analysis action routine for headstage 0"}
	CheckBox headStage1_postSweepAnalysisOn,pos={275,82},size={16,14},proc=AM_HeadStagePSCheckBox,title=""
	CheckBox headStage1_postSweepAnalysisOn,value= 0, help={"Activate post analysis action routine for headstage 1"}
	CheckBox headStage2_postSweepAnalysisOn,pos={275,107},size={16,14},proc=AM_HeadStagePSCheckBox,title=""
	CheckBox headStage2_postSweepAnalysisOn,value= 0, help={"Activate post analysis action routine for headstage 2"}
	CheckBox headStage3_postSweepAnalysisOn,pos={275,132},size={16,14},proc=AM_HeadStagePSCheckBox,title=""
	CheckBox headStage3_postSweepAnalysisOn,value= 0, help={"Activate post analysis action routine for headstage 3"}
	CheckBox headStage4_postSweepAnalysisOn,pos={275,157},size={16,14},proc=AM_HeadStagePSCheckBox,title=""
	CheckBox headStage4_postSweepAnalysisOn,value= 0, help={"Activate post analysis action routine for headstage 4"}
	CheckBox headStage5_postSweepAnalysisOn,pos={275,182},size={16,14},proc=AM_HeadStagePSCheckBox,title=""
	CheckBox headStage5_postSweepAnalysisOn,value= 0, help={"Activate post analysis action routine for headstage 5"}
	CheckBox headStage6_postSweepAnalysisOn,pos={275,207},size={16,14},proc=AM_HeadStagePSCheckBox,title=""
	CheckBox headStage6_postSweepAnalysisOn,value= 0, help={"Activate post analysis action routine for headstage 6"}
	CheckBox headStage7_postSweepAnalysisOn,pos={275,232},size={16,14},proc=AM_HeadStagePSCheckBox,title=""
	CheckBox headStage7_postSweepAnalysisOn,value= 0, help={"Activate post analysis action routine for headstage 7"}
	PopupMenu PSA_headStage0,pos={300,53},size={125,21},bodyWidth=125,proc=AM_PS_PopMenuChk
	PopupMenu PSA_headStage0,mode=2,popvalue="-None-",value= #"AM_PS_sortFunctions()", help={"Select a post sweep analysis routine for headstage 0"}
	PopupMenu PSA_headStage1,pos={300,78},size={125,21},bodyWidth=125,proc=AM_PS_PopMenuChk
	PopupMenu PSA_headStage1,mode=1,popvalue="-None-",value= #"AM_PS_sortFunctions()", help={"Select a post sweep analysis routine for headstage 1"}
	PopupMenu PSA_headStage2,pos={300,103},size={125,21},bodyWidth=125,proc=AM_PS_PopMenuChk
	PopupMenu PSA_headStage2,mode=2,popvalue="-None-",value= #"AM_PS_sortFunctions()", help={"Select a post sweep analysis routine for headstage 2"}
	PopupMenu PSA_headStage3,pos={300,128},size={125,21},bodyWidth=125,proc=AM_PS_PopMenuChk
	PopupMenu PSA_headStage3,mode=3,popvalue="-None-",value= #"AM_PS_sortFunctions()", help={"Select a post sweep analysis routine for headstage 3"}
	PopupMenu PSA_headStage4,pos={300,153},size={125,21},bodyWidth=125,proc=AM_PS_PopMenuChk
	PopupMenu PSA_headStage4,mode=3,popvalue="-None-",value= #"AM_PS_sortFunctions()", help={"Select a post sweep analysis routine for headstage 4"}
	PopupMenu PSA_headStage5,pos={300,178},size={125,21},bodyWidth=125,proc=AM_PS_PopMenuChk
	PopupMenu PSA_headStage5,mode=1,popvalue="-None-",value= #"AM_PS_sortFunctions()", help={"Select a post sweep analysis routine for headstage 5"}
	PopupMenu PSA_headStage6,pos={300,203},size={125,21},bodyWidth=125,proc=AM_PS_PopMenuChk
	PopupMenu PSA_headStage6,mode=1,popvalue="-None-",value= #"AM_PS_sortFunctions()", help={"Select a post sweep analysis routine for headstage 6"}
	PopupMenu PSA_headStage7,pos={300,228},size={125,21},bodyWidth=125,proc=AM_PS_PopMenuChk
	PopupMenu PSA_headStage7,mode=1,popvalue="-None-",value= #"AM_PS_sortFunctions()", help={"Select a post sweep analysis routine for headstage 7"}
	CheckBox headStage0_postAnalysisActionOn,pos={450,57},size={16,14},proc=AM_HeadStagePACheckBox,title=""
	CheckBox headStage0_postAnalysisActionOn,value= 0, help={"Activate post analysis action routine for headstage 0"}
	CheckBox headStage1_postAnalysisActionOn,pos={450,82},size={16,14},proc=AM_HeadStagePACheckBox,title=""
	CheckBox headStage1_postAnalysisActionOn,value= 0, help={"Activate post analysis action routine for headstage 1"}
	CheckBox headStage2_postAnalysisActionOn,pos={450,107},size={16,14},proc=AM_HeadStagePACheckBox,title=""
	CheckBox headStage2_postAnalysisActionOn,value= 0, help={"Activate post analysis action routine for headstage 2"}
	CheckBox headStage3_postAnalysisActionOn,pos={450,132},size={16,14},proc=AM_HeadStagePACheckBox,title=""
	CheckBox headStage3_postAnalysisActionOn,value= 0, help={"Activate post analysis action routine for headstage 3"}
	CheckBox headStage4_postAnalysisActionOn,pos={450,157},size={16,14},proc=AM_HeadStagePACheckBox,title=""
	CheckBox headStage4_postAnalysisActionOn,value= 0, help={"Activate post analysis action routine for headstage 4"}
	CheckBox headStage5_postAnalysisActionOn,pos={450,182},size={16,14},proc=AM_HeadStagePACheckBox,title=""
	CheckBox headStage5_postAnalysisActionOn,value= 0, help={"Activate post analysis action routine for headstage 5"}
	CheckBox headStage6_postAnalysisActionOn,pos={450,207},size={16,14},proc=AM_HeadStagePACheckBox,title=""
	CheckBox headStage6_postAnalysisActionOn,value= 0, help={"Activate post analysis action routine for headstage 6"}
	CheckBox headStage7_postAnalysisActionOn,pos={450,232},size={16,14},proc=AM_HeadStagePACheckBox,title=""
	CheckBox headStage7_postAnalysisActionOn,value= 0, help={"Activate post analysis action routine for headstage 7"}
	PopupMenu PAA_headStage0,pos={475,53},size={125,21},bodyWidth=125,proc=AM_PA_PopMenuChk
	PopupMenu PAA_headStage0,mode=2,popvalue="-None-",value= #"AM_PA_sortFunctions()", help={"Select a post analysis action routine for headstage 0"}
	PopupMenu PAA_headStage1,pos={475,78},size={125,21},bodyWidth=125,proc=AM_PA_PopMenuChk
	PopupMenu PAA_headStage1,mode=1,popvalue="-None-",value= #"AM_PA_sortFunctions()", help={"Select a post analysis action routine for headstage 1"}
	PopupMenu PAA_headStage2,pos={475,103},size={125,21},bodyWidth=125,proc=AM_PA_PopMenuChk
	PopupMenu PAA_headStage2,mode=2,popvalue="-None-",value= #"AM_PA_sortFunctions()", help={"Select a post analysis action routine for headstage 2"}
	PopupMenu PAA_headStage3,pos={475,128},size={125,21},bodyWidth=125,proc=AM_PA_PopMenuChk
	PopupMenu PAA_headStage3,mode=3,popvalue="-None-",value= #"AM_PA_sortFunctions()", help={"Select a post analysis action routine for headstage 3"}
	PopupMenu PAA_headStage4,pos={475,153},size={125,21},bodyWidth=125,proc=AM_PA_PopMenuChk
	PopupMenu PAA_headStage4,mode=3,popvalue="-None-",value= #"AM_PA_sortFunctions()", help={"Select a post analysis action routine for headstage 4"}
	PopupMenu PAA_headStage5,pos={475,178},size={125,21},bodyWidth=125,proc=AM_PA_PopMenuChk
	PopupMenu PAA_headStage5,mode=1,popvalue="-None-",value= #"AM_PA_sortFunctions()", help={"Select a post analysis action routine for headstage 5"}
	PopupMenu PAA_headStage6,pos={475,203},size={125,21},bodyWidth=125,proc=AM_PA_PopMenuChk
	PopupMenu PAA_headStage6,mode=1,popvalue="-None-",value= #"AM_PA_sortFunctions()", help={"Select a post analysis action routine for headstage 6"}
	PopupMenu PAA_headStage7,pos={475,228},size={125,21},bodyWidth=125,proc=AM_PA_PopMenuChk
	PopupMenu PAA_headStage7,mode=1,popvalue="-None-",value= #"AM_PA_sortFunctions()", help={"Select a post analysis action routine for headstage 7"}
	Button PAA_headStage0Config, pos={625, 53},size={150, 21},proc=AM_configAnalysis, title="Config Analysis HS 0"
	Button PAA_headStage0Config, help={"Configure the Post Analysis Action routine for headstage 0"}, disable=2
	Button PAA_headStage1Config, pos={625, 78},size={150, 21},proc=AM_configAnalysis, title="Config Analysis HS 1"
	Button PAA_headStage1Config, help={"Configure the Post Analysis Action routine for headstage 1"}, disable=2
	Button PAA_headStage2Config, pos={625, 103},size={150, 21},proc=AM_configAnalysis, title="Config Analysis HS 2"
	Button PAA_headStage2Config, help={"Configure the Post Analysis Action routine for headstage 2"}, disable=2
	Button PAA_headStage3Config, pos={625, 128},size={150, 21},proc=AM_configAnalysis, title="Config Analysis HS 3"
	Button PAA_headStage3Config, help={"Configure the Post Analysis Action routine for headstage 3"}, disable=2
	Button PAA_headStage4Config, pos={625, 153},size={150, 21},proc=AM_configAnalysis, title="Config Analysis HS 4"
	Button PAA_headStage4Config, help={"Configure the Post Analysis Action routine for headstage 4"}, disable=2
	Button PAA_headStage5Config, pos={625, 178},size={150, 21},proc=AM_configAnalysis, title="Config Analysis HS 5"
	Button PAA_headStage5Config, help={"Configure the Post Analysis Action routine for headstage 5"}, disable=2
	Button PAA_headStage6Config, pos={625, 203},size={150, 21},proc=AM_configAnalysis, title="Config Analysis HS 6"
	Button PAA_headStage6Config, help={"Configure the Post Analysis Action routine for headstage 6"}, disable=2
	Button PAA_headStage7Config, pos={625, 228},size={150, 21},proc=AM_configAnalysis, title="Config Analysis HS 7"
	Button PAA_headStage7Config, help={"Configure the Post Analysis Action routine for headstage 7"}, disable=2
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
	
	string itcPanel
	string controlName
	variable headstageNumber
	
	switch(ba.eventcode)
		case 2: // mouse up
			itcPanel = GetPopupMenuString(amPanel, "lockedDeviceMenu")
			DAP_AbortIfUnlocked(itcPanel)

			// decipher which headstage we are dealing with
			controlName = ba.ctrlName
			sscanf controlName, "PAA_headStage%d", headStageNumber
			ASSERT(V_flag == 1, "unexpected number of sscanf reads")
			configureAnalysis(headStageNumber, itcPanel)
			break
	endswitch
End

///@brief procedure to handle the locked device and set the window title
Function AM_LockedDeviceMenu(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	
	Variable popNum
	String popStr
	String panel
	
	popNum = pa.popNum
	popStr = pa.popStr
	panel = pa.win		// window that hosts the popup menu
	
	switch(pa.eventCode)
		case 2: // mouse up
			DoWindow /T $panel, "AM_" + popStr
			break
	endswitch		
	return 0
End

///@brief procedure to handle the check box for the headstage PS check box
Function AM_HeadStagePSCheckBox(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	Variable checked
	string controlName
	
	checked = cba.checked
	controlName = cba.ctrlName
	
	switch(cba.eventCode)
		case 2: // mouse up
			AM_PostSweepCheckBox(controlName, checked)
			break
	endswitch
	return 0
End

///@brief procedure to to see if the post Sweep analysis stuff is turned on for a headstage
Function AM_PostSweepCheckBox(ctrlName, checked)
	string ctrlName
	Variable checked
	
	string itcPanel
	Variable headStageClicked
	string configButton
	string midSweepAnalysisCheck
	string midSweepMenu
	
	itcPanel = GetPopupMenuString(amPanel, "lockedDeviceMenu")
	DAP_AbortIfUnlocked(itcPanel)
	
	Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(itcPanel)
		
	sscanf ctrlName, "headStage%d_postSweepAnalysisOn", headStageClicked
	ASSERT(V_flag == 1, "unexpected number of sscanf reads")
	
	// check to see if the panel and control exist
	ControlInfo /w = $amPanel $ctrlName
	ASSERT(WindowExists(amPanel), "Analysis master panel must exist")
	
	//build up the string for enabling the config button
	sprintf configButton, "PAA_headStage%dConfig", headStageClicked
	
	//build up the strings for disabling the mid sweep checkbox
	sprintf midSweepAnalysisCheck, "headStage%d_midSweepAnalysisOn", headStageClicked
	
	//build up the string for disabling the mid sweep pull down menu 
	sprintf midSweepMenu, "MSA_headStage%d", headStageClicked
	
	if(checked)	
		print "postSweepAnalysis turned on for headstage #", headStageClicked
		//enable the config button
		EnableControl(amPanel, configButton)
		// turn off the midSweep analysis		
		SetCheckBoxState(amPanel, midSweepAnalysisCheck, 0)
		//disable the mid sweep check box
		DisableControl(amPanel, midSweepAnalysisCheck)	
		//disable the mid sweep menu
		DisableControl(amPanel, midSweepMenu)
	else
		print "postSweepAnalysis turned off for headstage #", headStageClicked
		//disable the config button
		DisableControl(amPanel, configButton)
		//enable the mid sweep check box
		EnableControl(amPanel, midSweepAnalysisCheck)
		//enable the mid sweep menu
		EnableControl(amPanel, midSweepMenu)		
	endif
	
	analysisSettingsWave[headStageClicked][%PSAOnOff] = num2str(checked)	
end

///@brief function to handle the PA check box control
Function AM_HeadStagePACheckBox(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	
	Variable checked
	string controlName
	
	checked = cba.checked
	controlName = cba.ctrlName
	
	switch(cba.eventCode)
		case 2: // mouse up
			AM_PostAnalysisCheckBox(cba)
			break
	endswitch
	return 0
End

///@brief function to to see if the post analysis action stuff is turned on for a headstage
Function AM_PostAnalysisCheckBox(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	
	Variable headStageClicked
	string configButtonEnable
	string midSweepAnalysisCheck
	string midSweepMenu
	string postSweepAnalysisCheck
	
	switch(cba.eventCode)
		case 2: // mouse up
			string ctrlName = cba.ctrlName
			Variable checked = cba.checked	
			// get the da_ephys panel name
			string itcPanel = GetPopupMenuString(amPanel, "lockedDeviceMenu")
			DAP_AbortIfUnlocked(itcPanel)
			
			Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(itcPanel)
			
			sscanf ctrlName, "headStage%d_postAnalysisActionOn", headStageClicked 
			ASSERT(V_flag == 1, "unexpected number of sscanf reads")
						
			//build up the string for enabling the config button
			sprintf configButtonEnable, "PAA_headStage%dConfig", headStageClicked
			
			//build up the strings for disabling the mid sweep checkbox
			sprintf midSweepAnalysisCheck, "headStage%d_midSweepAnalysisOn", headStageClicked
			
			//build up the string for disabling the mid sweep pull down menu 
			sprintf midSweepMenu, "MSA_headStage%d", headStageClicked
			
			//build up the string for enabling the post sweep analysis---the post analysis action needs the post sweep analysis enabled to work
			sprintf postSweepAnalysisCheck, "headStage%d_postSweepAnalysisOn", headStageClicked
			
			// check to see if the panel and control exist
			ControlInfo /w = $amPanel $ctrlName
			ASSERT(V_flag != 0, "non-existing window or control")
			
			if(checked)	
				print "postAnalysisAction turned on for headstage #", headStageClicked	
				//enable the config button
				EnableControl(amPanel, configButtonEnable)
				//check on the postSweepAnalysis check box
				SetCheckBoxState(amPanel, postSweepAnalysisCheck, 1)
				//check off the midsweepAnalysis
				SetCheckBoxState(amPanel, midSweepAnalysisCheck, 0)
				//disable the mid sweep check box
				DisableControl(amPanel, midSweepAnalysisCheck)
				//disable the mid sweep menu
				DisableControl(amPanel, midSweepMenu)
			else
				print "postAnalysisAction turned off for headstage #", headStageClicked
				//disable the config button
				DisableControl(amPanel, configButtonEnable)
				//check off the postSweepAnalysis check box
				SetCheckBoxState(amPanel, postSweepAnalysisCheck, 0)
				//enable the mid sweep check box
				EnableControl(amPanel, midSweepAnalysisCheck)
				//enable the mid sweep menu
				EnableControl(amPanel, midSweepMenu)
			endif
			analysisSettingsWave[headStageClicked][%PAAOnOff] = num2str(checked)
			break
	endswitch
	
	return 0
End

///@brief function to handle the midSweep Analysis check box control
Function AM_HeadStageMSCheckBox(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	
	switch(cba.eventCode)
		case 2: // mouse up
			AM_midSweepAnalysisCheckBox(cba)
			break
	endswitch

	return 0
End

///@brief function to to see if the midSweep analysis stuff is turned on for a headstage
Function AM_midSweepAnalysisCheckBox(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	
	string ctrlName 
	Variable checked
	string itcPanel
	Variable headStageClicked
	string configButtonEnable
	string postSweepAnalysisCheck
	string postAnalysisActionCheck
	string postSweepMenu
	string postAnalysisMenu
	
	switch(cba.eventCode)
		case 2: // mouse up
			ctrlName = cba.ctrlName
			checked = cba.checked
			
			itcPanel = GetPopupMenuString(amPanel, "lockedDeviceMenu")
			DAP_AbortIfUnlocked(itcPanel)

			Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(itcPanel)
			
			sscanf ctrlName, "headStage%d_midSweepAnalysisOn", headStageClicked 
			ASSERT(V_flag == 1, "unexpected number of sscanf reads")
			
			//build up the string for enabling the config button
			sprintf configButtonEnable, "PAA_headStage%dConfig", headStageClicked
			
			//build up the strings for disabling the post sweep checkboxes
			sprintf postSweepAnalysisCheck, "headStage%d_postSweepAnalysisOn", headStageClicked
			sprintf postAnalysisActionCheck, "headStage%d_postAnalysisActionOn", headStageClicked
			
			//build up the string for disabling the post sweep analysis pull down menu 
			sprintf postSweepMenu, "PSA_headStage%d", headStageClicked
			
			//build up the string for disabling the post sweep analysis pull down menu 
			sprintf postAnalysisMenu, "PAA_headStage%d", headStageClicked
			
			// check to see if the panel and control exist
			ControlInfo /w = $amPanel $ctrlName
			ASSERT(V_flag != 0, "non-existing window or control")
			
			if(checked)	
				print "midSweepAnalysisAction turned on for headstage #", headStageClicked
				//enable the config button
				EnableControl(amPanel, configButtonEnable)
				//disable the postSweep stuff
				DisableControl(amPanel, postSweepAnalysisCheck)
				DisableControl(amPanel, postAnalysisActionCheck)
				DisableControl(amPanel, postSweepMenu)
				DisableControl(amPanel, postAnalysisMenu)
			else
				print "midSweepAnalysisAction turned off for headstage #", headStageClicked
				//disable the config button
				DisableControl(amPanel, configButtonEnable)
				//enable the postSweep stuff
				EnableControl(amPanel, postSweepAnalysisCheck)
				EnableControl(amPanel, postAnalysisActionCheck)
				EnableControl(amPanel, postSweepMenu)
				EnableControl(amPanel, postAnalysisMenu)	
			endif
			analysisSettingsWave[headStageClicked][%MSAOnOff] = num2str(checked)
			break
	endswitch
	return 0
End

///@brief function for putting the name of the PostSweepAnalysis function into the analysisMaster wave
Function AM_PS_PopMenuChk(pa) : PopupMenuControl  
	STRUCT WMPopupAction &pa
	
	variable popNum
	String popStr
	string  ctrlName
	string itcPanel
	Variable headStageSelected
	
	switch(pa.eventCode)
		case 2: // mouse up
			popNum = pa.popNum
			popStr = pa.popStr
			ctrlName = pa.ctrlName
				
			itcPanel = GetPopupMenuString(amPanel, "lockedDeviceMenu")
			DAP_AbortIfUnlocked(itcPanel)
				
			Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(itcPanel)
			
			sscanf ctrlName, "PSA_headStage%d", headStageSelected
			ASSERT(V_flag == 1, "unexpected number of sscanf reads")
			
			// check to see if the panel and control exist
			ControlInfo /w = $amPanel $ctrlName
			ASSERT(V_flag != 0, "non-existing window or control")
			
			analysisSettingsWave[headStageSelected][%PSAType] = popStr			
			break
	endswitch
	return 0
End	
			
///@brief function for putting the name of the PostAnalysisAction function into the analysisMaster wave
Function AM_PA_PopMenuChk(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	variable popNum
	String popStr
	string  ctrlName
	string itcPanel
	Variable headStageSelected
	
	switch(pa.eventCode)
		case 2: // mouse up
			popNum = pa.popNum
			popStr = pa.popStr
			ctrlName = pa.ctrlName
		
			itcPanel = GetPopupMenuString(amPanel, "lockedDeviceMenu")
			DAP_AbortIfUnlocked(itcPanel)
			
			Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(itcPanel)
			
			sscanf ctrlName, "PAA_headStage%d", headStageSelected
			ASSERT(V_flag == 1, "unexpected number of sscanf reads")
			
			// check to see if the panel and control exist
			ControlInfo /w = $amPanel $ctrlName
			ASSERT(V_flag != 0, "non-existing window or control")			
			analysisSettingsWave[headStageSelected][%PAAType] = popStr
			break
	endswitch

	return 0
End

///@brief function for putting the name of the PostAnalysisAction function into the analysisMaster wave
Function AM_MS_PopMenuChk(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	variable popNum
	String popStr
	string  ctrlName
	string itcPanel
	Variable headStageSelected

	switch(pa.eventCode)
		case 2: // mouse up
			popNum = pa.popNum
			popStr = pa.popStr
			ctrlName = pa.ctrlName
		
			itcPanel = GetPopupMenuString(amPanel, "lockedDeviceMenu")
			DAP_AbortIfUnlocked(itcPanel)
			
			Wave/T analysisSettingsWave = GetAnalysisSettingsWaveRef(itcPanel)
			
			sscanf ctrlName, "MSA_headStage%d", headStageSelected
			ASSERT(V_flag == 1, "unexpected number of sscanf reads")
			
			// check to see if the panel and control exist
			ControlInfo /w = $amPanel $ctrlName
			ASSERT(V_flag != 0, "non-existing window or control")	
			analysisSettingsWave[headStageSelected][%MSAType] = popStr
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

///@brief function for sorting MS, PA and PS functions for populating pull down menus
static Function/S AM_sortAMFunctions(str)
	string str
	
	string funcList
	variable noFunctions
	string editedList
	string func, editedFunc
	string funcTemplate
	
	variable i
	
	funcList = FunctionList("AM_" + str + "*", ";", "")
	noFunctions = ItemsInList(funcList)
	editedList = "-None-"
	funcTemplate = "AM_" + str + "_%s"
		
	for(i = 0; i < noFunctions; i += 1)
	    func = StringFromList(i, funcList)
	    sscanf func, funcTemplate, editedFunc
	    ASSERT(V_flag == 1, "unexpected number of sscanf reads")
	    editedList = AddListItem(editedFunc, editedList, ";", INF)
	endfor

	return editedList
End

Function AM_writeAsyncResponseProto(cmdID, returnString)
	string cmdID, returnString

	DoAbortNow("Impossible to find the function TI_WriteAsyncResponse\rWas the tango XOP and the includes loaded?")
End

/// @brief Wrapper for the optional tango related function #writeAsyncResponseWrapper
/// The approach here using a function reference and an interpreted string like `$""` allows
/// to convert the dependency on the function writeAsyncResponse from compile time to runtime.
/// This function will call TI_writeAsyncResponse if it can be found, otherwise AM_writeAsyncResponseProto is called.
Static Function writeAsyncResponseWrapper(cmdID, returnString)
	string cmdID, returnString

	FUNCREF AM_writeAsyncResponseProto f = $"TI_WriteAsyncResponse"

	return f(cmdID, returnString)
End
