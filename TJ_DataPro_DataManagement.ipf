#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#pragma IndependentModule=imDataPro

Function SaveITCData()
	Wave ITCDataWave, ITCChanConfigWave
	Variable SweepNo
	ControlInfo/w=DataPro_ITC1600 SetVar_Sweep
	SweepNo=v_value
	string SavedDataWaveName="Sweep_"+ num2str(SweepNo)
	string SavedSetUpWaveName="Config_Sweep_"+ num2str(SweepNo)
	
	Duplicate/o/r=[0,(CalculateITCDataWaveLength()/2)][] ITCDataWave $SavedDataWaveName
	Duplicate/o ITCChanConfigWave $SavedSetUpWaveName
	SetVariable SetVar_Sweep, Value=_NUM:(SweepNo+1)
End
