
Function StimsetAPIExample()
	string setName, stimsets
	variable numEpochs

	// create new stimulus set
	setName = ST_CreateStimSet("myset", CHANNEL_TYPE_DAC)

	// check that it is there
	stimsets = ST_GetStimsetList(channelType = CHANNEL_TYPE_DAC, searchString = "my*")
	printf "Stimsets %s\r", stimsets

	// inspect global stimulus parameters
	WAVE globalParams = ST_GetStimsetParameters(setName)
	print globalParams

	// use two epochs
	ST_SetStimsetParameter(setName, "Total number of epochs", var = 2)

	// and three steps/sweeps
	ST_SetStimsetParameter(setName, "Total number of steps", var = 3)

	// inspect the just set entry
	numEpochs = ST_GetStimSetParameterAsVariable(setName, "Total number of epochs")
	printf "Number of epochs: %d\r", numEpochs

	ST_SetStimsetParameter(setName, "Type of Epoch 0", var = EPOCH_TYPE_SQUARE_PULSE)
	ST_SetStimsetParameter(setName, "Type of Epoch 1", var = EPOCH_TYPE_PULSE_TRAIN)

	// get the list of possible parameters for the square pulse
	WAVE epochParams = ST_GetStimsetParameters(setName, epochType = EPOCH_TYPE_SQUARE_PULSE)
	print epochParams

	// and pulse train
	WAVE epochParams = ST_GetStimsetParameters(setName, epochType = EPOCH_TYPE_PULSE_TRAIN)
	print epochParams

	// configure square pulse
	ST_SetStimsetParameter(setName, "Duration", epochIndex = 0, var = 500)
	ST_SetStimsetParameter(setName, "Amplitude", epochIndex = 0, var = 0)

	// configure pulse train
	ST_SetStimsetParameter(setName, "Duration", epochIndex = 1, var = 1500)
	ST_SetStimsetParameter(setName, "Amplitude", epochIndex = 1, var = 1)
	ST_SetStimsetParameter(setName, "Sin/chirp/saw frequency", epochIndex = 1, var = 10)
	ST_SetStimsetParameter(setName, "Train pulse duration", epochIndex = 1, var = 20)

	// set an analysis function
	ST_SetStimsetParameter(setName, "Analysis function (generic)", str = "TestAnalysisFunction_V3")

	// add analysis parameter
	AFH_AddAnalysisParameter(setName, "myVarParam", var = 1.23456)

	// use an explicit delta list for the ITI
	ST_SetStimsetParameter(setName, "Inter trial interval op", str = "Explicit")
	ST_SetStimsetParameter(setName, "Inter trial interval ldel", str = "5;7")
End
