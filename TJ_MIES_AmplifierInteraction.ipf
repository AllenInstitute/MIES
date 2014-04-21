#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function /t AI_ReturnListOf700BChannels(panelTitle)
	string panelTitle
	Variable TotalNoChannels
	Variable i = 0
	String ChannelList = ""
	String Value
	String AmpAndChannel
	//make/o/n=0 W_TelegraphServers
	//AxonTelegraphFindServers
	wave /z W_TelegraphServers = root:MIES:Amplifiers:W_TelegraphServers
	TotalNoChannels = DimSize(W_TelegraphServers, 0 )// 0 is for rows, 1 for columns, 2 for layers, 3 for chunks
		
		if(TotalNoChannels > 0)
			do
			sprintf Value, "%g" W_TelegraphServers[i][0]
			sprintf AmpAndChannel, "AmpNo %s Chan %g", Value, W_TelegraphServers[i][1]
			ChannelList = addListItem(AmpAndChannel, ChannelList, ";", i)
		//	ChannelList += "AmpNo " + Value + " Chan " + num2str(W_TelegraphServers[i][1]) + ";"
			i += 1
			while(i < TotalNoChannels)
		endif
	
	if(cmpstr(ChannelList, "") == 0)
		ChannelList = "MC not available;"
		print "Activate Multiclamp Commander software to populate list of available amplifiers"
	endif
	
	return ChannelList

End




