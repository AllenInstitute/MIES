#pragma rtGlobals=3		// Use modern global access method and strict wave access.


//=========================================================================================
Function ConfigureDataForITC()
MakeITCConfigAllConfigWave()
MakeITCConfigAllDataWave()
MakeITCFIFOPosAllConfigWave()
MakeITCFIFOAvailAllConfigWave()

PlaceDataInITCChanConfigWave()
PlaceDataInITCDataWave()
PDInITCFIFOPositionAllCW()// PD = Place Data
PDInITCFIFOAvailAllCW()
End


//==========================================================================================

Function TotalChannelsSelected() //DA_00 - DA_07 and AD_00-AD_15, 
variable TotalNumOfChanSelected
TotalNumOfChanSelected=NoOfChannelsSelected("DA", "Check")+ NoOfChannelsSelected("AD", "Check")+NoOfChannelsSelected("TTL", "Check")
return TotalNumOfChanSelected
End

//==========================================================================================

Function ITCMinSamplingInterval()// minimum sampling intervals are 5, 10, 15, 20 or 25 microseconds
//The min sampling interval is determined by the rack with the most channels selected
variable ITCMinSampInt, Rack0DAMinInt, Rack0ADMinInt, Rack1DAMinInt, Rack1ADMinInt

Rack0DAMinInt=DAMinSampInt(0)
Rack1DAMinInt=DAMinSampInt(1)

Rack0ADMinInt=ADMinSampInt(0)
Rack1ADMinInt=ADMinSampInt(1)

ITCMinSampInt=max(max(Rack0DAMinInt,Rack1DAMinInt),max(Rack0ADMinInt,Rack1ADMinInt))

//ITCMinSampInt+=(AreTTLsInRackChecked(0)*5)
//ITCMinSampInt+=(AreTTLsInRackChecked(1)*5)

return ITCMinSampInt
End


//==========================================================================================
Function NoOfChannelsSelected(ChannelType, ControlType)//ChannelType = DA, AD, or TTL; Control Type = check or wave
string ChannelType, ControlType
variable TotalPossibleChannels=TotNoOfControlType(ControlType, ChannelType)
variable i = 0
variable NoOfChannelsSelected=0
string CheckBoxName

	do
		CheckBoxName="Check_"+ ChannelType +"_"
		
		if(i<10)
		CheckBoxName+="0"+num2str(i)
		ControlInfo/w=DataPro_ITC1600 $CheckBoxName
		NoOfChannelsSelected+=v_value
		endif

		if(i>=10)
		CheckBoxName+=num2str(i)
		ControlInfo/w=DataPro_ITC1600 $CheckBoxName
		NoOfChannelsSelected+=v_value
		endif
	

	i+=1
	while(i<=(TotalPossibleChannels-1))
return NoOfChannelsSelected
End

//==========================================================================================

Function/S ControlStatusListString(ChannelType, ControlType)
String ChannelType
string ControlType
variable TotalPossibleChannels=TotNoOfControlType(ControlType, ChannelType)

String ControlStatusList = ""
String ControlName
variable i

i=0

	do
		ControlName=ControlType+"_"+ ChannelType +"_"		
		
		if(i<10)
		ControlName+="0"+num2str(i)
		ControlInfo/w=DataPro_ITC1600 $ControlName
		ControlStatusList+=num2str(v_value)+";"
		endif

		if(i>=10)
		ControlName+=num2str(i)
		ControlInfo/w=DataPro_ITC1600 $ControlName
		ControlStatusList+=num2str(v_value)+";"
		endif
	

	i+=1
	while(i<=(TotalPossibleChannels-1))

return ControlStatusList
End

//==========================================================================================

Function ChannelCalcForITCChanConfigWave()

Variable NoOfDAChannelsSelected = NoOfChannelsSelected("DA", "Check")
Variable NoOfADChannelsSelected = NoOfChannelsSelected("AD", "Check")
Variable AreRack0FrontTTLsUsed = AreTTLsInRackChecked(0)
Variable AreRack1FrontTTLsUsed = AreTTLsInRackChecked(1)
Variable ChannelCount

ChannelCount=NoOfDAChannelsSelected+NoOfADChannelsSelected+AreRack0FrontTTLsUsed+AreRack1FrontTTLsUsed

return ChannelCount

END
//==========================================================================================
Function AreTTLsInRackChecked(RackNo)
variable RackNo
variable a
variable b
string TTLsInUse = ControlStatusListString("TTL", "Check")
variable RackTTLStatus

if(RackNo==0)
 a=0
 b=3
endif

if(RackNo==1)
 a=4
 b=7
endif

do
If(str2num(stringfromlist(a,TTLsInUse,";"))==1)
RackTTLStatus=1
return RackTTLStatus
endif
a+=1
while(a<=b)

RackTTLStatus=0
return RackTTLStatus

End

//=========================================================================================

Function TotNoOfControlType(ControlType, ChannelType)// Ex. ChannelType = "DA", ControlType = "Check"
string  ControlType, ChannelType
string SearchString = ControlType+"_"+ChannelType+"_*"
string ListString
variable CatTot//Category Total

ListString=ControlNameList("DataPro_ITC1600",";",SearchString)
CatTot=ItemsInlist(ListString,";")

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



Function TTLCodeCalculation1(RackNo)//
variable RackNo
variable a, i, TTLChannelStatus,Code
string TTLStatusString = ControlStatusListString("TTL", "Check")

if(RackNo==0)
 a=0
endif

if(RackNo==1)
 a=4
endif

code=0
i=0

do 
TTLChannelStatus=str2num(stringfromlist(a,TTLStatusString,";"))
Code+=(((2^i))*TTLChannelStatus)
a+=1
i+=1
while(i<4)

return Code

End


//=========================================================================================

Function/s PopMenuStringList(ChannelType, ControlType)
string ChannelType, ControlType

variable TotalPossibleChannels=TotNoOfControlType(ControlType, ChannelType)

String ControlWaveList = ""
String ControlName
variable i

i=0

	do
		ControlName=ControlType+"_"+ ChannelType +"_"		
		
		if(i<10)
		ControlName+="0"+num2str(i)
		ControlInfo/w=DataPro_ITC1600 $ControlName
		ControlWaveList+=s_value+";"
		endif

		if(i>=10)
		ControlName+=num2str(i)
		ControlInfo/w=DataPro_ITC1600 $ControlName
		ControlWaveList+=s_value+";"
		endif
	

	i+=1
	while(i<=(TotalPossibleChannels-1))

return ControlWaveList

End

//=========================================================================================
Function LongestOutputWave(ChannelType)//ttl and da channel types need to be passed into this and compared to determine longest wave
string ChannelType

string ControlType = "Check"

variable TotalPossibleChannels = TotNoOfControlType(ControlType, ChannelType)
variable wavelength, i
string ControlTypeStatus = ControlStatusListString(ChannelType, ControlType)
string WaveNameString

ControlType = "Wave"
string ChannelTypeWaveList = PopMenuStringList(ChannelType, ControlType)

//if da or ttl channels is active, query the wavelength of the active channel
i=0
wavelength = 0

do

if((str2num(stringfromlist(i,ControlTypeStatus,";")))==1)
WaveNameString = stringfromlist(i,ChannelTypeWaveList,";")
	if(stringmatch(WaveNameString,"-none-") ==0)//prevents error where check box is checked but no wave is selected. Update: the panel code actually prevents this possibility but I am leaving the code because I don't think the redundancy is harmful
	wavestats/q $WaveNameString
		if(v_npnts>WaveLength)
		WaveLength = v_npnts
		endif
	endif
endif

i+=1
while(i<=(TotalPossibleChannels-1))

return WaveLength

End



//==========================================================================================
Function CalculateITCDataWaveLength()// determines the longest output DA or DO wave. Divides it by the min sampling interval and quadruples its length (to prevent buffer overflow).
Variable LongestWaveLength
//Determine Longest Wave
if (LongestOutputWave("DA")>=LongestOutputWave("TTL"))
LongestWaveLength = LongestOutputWave("DA")
else
LongestWaveLength = LongestOutputWave("TTL")
endif

LongestWaveLength/=(ITCMinSamplingInterval()/5)
LongestWaveLength*=4

return round(LongestWaveLength)
end

//==========================================================================================
Function MakeITCConfigAllConfigWave()
Make/I/o/n=(ChannelCalcForITCChanConfigWave(), 4) ITCChanConfigWave
ITCChanConfigWave=0
End
//==========================================================================================
Function MakeITCConfigAllDataWave()
make/w/o/n=(CalculateITCDataWaveLength(), ChannelCalcForITCChanConfigWave()) ITCDataWave
ITCDataWave=0
SetScale/P x 0,(ITCMinSamplingInterval())/1000,"ms", ITCDataWave
End
//==========================================================================================
Function MakeITCFIFOPosAllConfigWave()//MakeITCUpdateFIFOPosAllConfigWave
Make/I/o/n=(ChannelCalcForITCChanConfigWave(), 4) ITCFIFOPositionAllConfigWave
ITCFIFOPositionAllConfigWave=0
End
//==========================================================================================
Function MakeITCFIFOAvailAllConfigWave()//MakeITCFIFOAvailAllConfigWave
Make/I/o/n=(ChannelCalcForITCChanConfigWave(), 4) ITCFIFOAvailAllConfigWave
ITCFIFOAvailAllConfigWave=0
End
//==========================================================================================


Function PlaceDataInITCChanConfigWave()
variable i=0// 
variable j=0//used to keep track of row of ITCChanConfigWave which config data is loaded into
variable ChannelType// = 0 for AD, = 1 for DA, = 3 for TTL
string ChannelStatus
wave ITCChanConfigWave

MakeITCConfigAllConfigWave()

//Place DA config data
ChannelType = 1
ChannelStatus=ControlStatusListString("DA", "Check")
do
	if(str2num(stringfromlist(i,ChannelStatus,";"))==1)
	ITCChanConfigWave[j][0]=ChannelType
	ITCChanConfigWave[j][1]=i
	j+=1
	endif
i+=1
while(i<(itemsinlist(ChannelStatus,";")))



//Place AD config data
i=0
ChannelStatus=ControlStatusListString("AD", "Check")
ChannelType = 0

do
	if(str2num(stringfromlist(i,ChannelStatus,";"))==1)
	ITCChanConfigWave[j][0]=ChannelType
	ITCChanConfigWave[j][1]=i
	j+=1
	endif
i+=1
while(i<(itemsinlist(ChannelStatus,";")))

//Place TTL config data
i=0
ChannelType = 3

if(AreTTLsInRackChecked(0)==1)
	ITCChanConfigWave[j][0]=ChannelType
	ITCChanConfigWave[j][1]=0
j+=1
endif

if(AreTTLsInRackChecked(1)==1)

	ITCChanConfigWave[j][0]=ChannelType
	ITCChanConfigWave[j][1]=3

endif

ITCChanConfigWave[][2]=ITCMinSamplingInterval()//
//ITCChanConfigWave[j][2]=ITCMinSamplingInterval()*2
ITCChanConfigWave[][3]=0

End
//==========================================================================================
Function PlaceDataInITCDataWave()
variable i=0// 
variable j=0//
string ChannelStatus
wave ITCDataWave
string ChanTypeWaveNameList, ChanTypeWaveName
string ResampledWaveName="ResampledWave"
string cmd
string SetvarDAGain, SetVarDAScale
variable DAGain, DAScale

//Place DA waves into ITCDataWave
variable DecimationFactor = (ITCMinSamplingInterval()/5)
ChannelStatus=ControlStatusListString("DA", "Check")
ChanTypeWaveNameList=PopMenuStringList("DA", "Wave")
do
	if(str2num(stringfromlist(i,ChannelStatus,";"))==1)//Checks if DA channel checkbox is checked (ON)
	SetVarDAGain = "gain_DA_0" + num2str(i)
	SetVarDAScale = "scale_DA_0" + num2str(i)
	ControlInfo/w=DataPro_ITC1600 $SetVarDAGain
	DAGain=(3200/v_value)//3200 = 1V
	ControlInfo/w=DataPro_ITC1600 $SetVarDAScale
	DAScale=v_value
	//get the wave name
	ChanTypeWaveName=stringfromlist(i,ChanTypeWaveNameList,";")
	//resample the wave to min samp interval and place in ITCDataWave
	//sprintf cmd, "ITCDataWave[0,round((numpnts(%s)/(%d))-1)][%d]=%s[(%d)*p]",ChanTypeWaveName,DecimationFactor, j, ChanTypeWaveName, DecimationFactor
	sprintf cmd, "ITCDataWave[0,round((numpnts('%s')/(%d))-1)][%d]=(%d*%d)*('%s'[(%d)*p])",ChanTypeWaveName,DecimationFactor, j, DAGain, DAScale, ChanTypeWaveName, DecimationFactor
	execute cmd

	j+=1// j determines what column of the ITCData wave the DAC wave is inserted into 
	endif
i+=1
while(i<(itemsinlist(ChannelStatus,";")))



//Leave room for AD data 
i=0
ChannelStatus=ControlStatusListString("AD", "Check")

do
if(str2num(stringfromlist(i,ChannelStatus,";"))==1)
	j+=1
	endif
i+=1
while(i<(itemsinlist(ChannelStatus,";")))

//Place DA waves into ITCDataWave
i=0

make/o/n=1 TTLwave
if(AreTTLsInRackChecked(0)==1)
	MakeITCTTLWave(0)
	ITCDataWave[0,round((numpnts(TTLWave)/DecimationFactor))-1][j]=TTLWave[(DecimationFactor)*p]
	j+=1
endif

if(AreTTLsInRackChecked(1)==1)
	MakeITCTTLWave(1)
	ITCDataWave[0,round((numpnts(TTLWave)/DecimationFactor))-1][j]=TTLWave[(DecimationFactor)*p]

endif

End

//=========================================================================================
Function PDInITCFIFOPositionAllCW()//PlaceDataInITCFIFOPositionAllConfigWave()
wave ITCFIFOPositionAllConfigWave, ITCChanConfigWave
ITCFIFOPositionAllConfigWave[][0,1] = ITCChanConfigWave
ITCFIFOPositionAllConfigWave[][2]=-1
ITCFIFOPositionAllConfigWave[][3]=0
End
//=========================================================================================

Function PDInITCFIFOAvailAllCW()//PlaceDataInITCFIFOAvailAllConfigWave()
wave ITCFIFOAvailAllConfigWave, ITCChanConfigWave
ITCFIFOAvailAllConfigWave[][0,1] = ITCChanConfigWave
ITCFIFOAvailAllConfigWave[][2]=0
ITCFIFOAvailAllConfigWave[][3]=0
End

//=========================================================================================
Function MakeITCTTLWave(RackNo)//makes single ttl wave for each rack. each ttl wave is added to the next after being multiplied by its bit number
variable RackNo
variable a, i, TTLChannelStatus,Code
string TTLStatusString = ControlStatusListString("TTL", "Check")
string TTLWaveList = PopMenuStringList("TTL", "Wave")
string TTLWaveName
string cmd
//make/o/n=(CalculateITCDataWaveLength()) TTLWave =0

if(RackNo==0)
 a=0
endif

if(RackNo==1)
 a=4
endif

code=0
i=0

do 
TTLChannelStatus=str2num(stringfromlist(a,TTLStatusString,";"))
Code=(((2^i))*TTLChannelStatus)
TTLWaveName = stringfromlist(a,TTLWaveList,";")
	if(i==0)
	make/o/n=(numpnts($TTLWaveName)) TTLWave = 0
	endif
	
	if(TTLChannelStatus==1)
	sprintf cmd, "TTLWave+=(%d*%s)", code, TTLWaveName
	execute cmd
	endif
a+=1
i+=1
while(i<4)

End






//=========================================================================================
Function DAMinSampInt(RackNo)
variable RackNo
variable a, i, DAChannelStatus,SampInt
string DAStatusString = ControlStatusListString("DA", "Check")


a=RackNo*4

SampInt=0
i=0

do 
DAChannelStatus=str2num(stringfromlist(a,DAStatusString,";"))
SampInt+=5*DAChannelStatus
a+=1
i+=1
while(i<4)

//SampInt += ((AreTTLsInRackChecked(RackNo))*5)//DO channels always add a sample interval!!!!!!!!!!!!!!!!!!!

//if(RackNo==0)
//	if(AreTTLsInRackChecked(1)==1)
//	SampInt*=2
//	endif
//else
//	if(AreTTLsInRackChecked(0)==1)
//	SampInt*=2
//	endif
//endif

return SampInt
End
//=========================================================================================
Function ADMinSampInt(RackNo)
variable RackNo
variable a, i, ADChannelStatus,ADSampInt, Bank1SampInt, Bank2SampInt
string ADStatusString = ControlStatusListString("AD", "Check")


a=RackNo*8

Bank1SampInt=0
Bank2SampInt=0
ADSampInt=0
i=0

do 
ADChannelStatus=str2num(stringfromlist(a,ADStatusString,";"))
Bank1SampInt+=5*ADChannelStatus
a+=1
i+=1
while(i<4)


i=0
do 
ADChannelStatus=str2num(stringfromlist(a,ADStatusString,";"))
Bank2SampInt+=5*ADChannelStatus
a+=1
i+=1
while(i<4)

ADSampInt=max(Bank1SampInt,Bank2SampInt)
return ADSampInt


End
//=========================================================================================

