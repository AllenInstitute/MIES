#pragma rtGlobals=1		// Use modern global access method.

//
//*******************************************************************
// 

Macro ReadAllHDFRaster8()
	SetHDFSource()
	if(strlen(gHDF_src_file)==0)
		return
	endif
	
	PauseUpdate; silent 1
	variable i=0
	variable num
	String 	theImage,baseName="Image",paletteRefs="palettes"
	make/o	theCtab
	
	// Get a list of reference number for the raster8 images in the file 
	HDFInfo mode=5,tag=202,gHDF_src_file
	
	// Move the list to a local wave in case the default wave gets overwritten later
	Duplicate/o hdf_list,refsList

	num=numPnts(refsList)					// find the number of raster8 pictures in the file
	
	do
		theImage=baseName+num2str(i)		// build a name for the image wave
		Make /o $theImage
		HDFInfo mode=256,ref=refsList[i],tag=201,gHDF_src_file
		
		if(hdf_flag==1)						// if there was no error in reading the image
		
			hdfReadImage ref=refsList[i],IMAGENAME=$theImage,PALNAME=theCtab,gHDF_src_file
			HDFInfo 	Image8Dim,ref=refsList[i],tag=202,gHDF_src_file
			
			display;								// create a window and set its size for the image
			ModifyGraph width=hdf_image_width,height=hdf_image_height
			 appendimage $theImage				
			modifyimage $theImage cindex=theCtab
			
		else										// if there are no color palettes
			hdfReadImage ref=refsList[i],imagename=theImage,gHDF_src_file
			display; appendimage $theImage
		endif
		i+=1
	while(i<num)
	
	KillStrings gHDF_src_file,gHDF_src_path
end

//
//	Display specified images from an HDF file
//	

Macro DisplayHDFImages()

	SetHDFSource()
	if(strlen(gHDF_src_file)==0)
		return
	endif

	PauseUpdate; silent 1
	Variable/G	gImageIndex=1
	String/G	gRefList
	
	//  Before we ask for the reference number we find which references are in the specified
	//  file.  The references are stored into a wave HDF_List which we will convert into
	//  a global string to be used in getImageIndex()
	
	if(Exists("HDF_List"))
		KillWaves HDF_List
	endif
	
	HDFInfo mode=5,tag=202,gHDF_src_file
	if(numpnts(HDF_List)<1)
		print  "There are no raster8 images in this file"
	else
		gRefList=wave2String(HDF_List)
		if(strlen(gRefList)>0)
			getImageIndex()
			
			if(gImageIndex>0)
				Hdfreadimage/P=$gHDF_src_path 	ref=gImageIndex,imageName=jj,gHDF_src_file
				HDFreadImage/P=$gHDF_src_path 	ref=gImageIndex,Mode=16,palname=jp,gHDF_src_file
				HDFInfo/P=$gHDF_src_path 		Image8Dim,ref=gImageIndex,tag=202,gHDF_src_file
				
				display; 
				ModifyGraph 	width=hdf_image_width,height=hdf_image_height
				appendimage jj; modifyimage jj cindex=jp;
			endif
		else
			print "There are no raster8 images in this file"
		endif
	endif
	
	//  cleanup name space
	KillVariables gImageIndex
	KillStrings gRefList
end

//
//*******************************************************************
//

Proc getImageIndex(indexStr)
	String indexStr
	prompt indexStr,"References:" ,popup,gRefList
	Variable index=str2num(indexStr)
	gImageIndex=index
end


//
//*******************************************************************
//



Macro Translate_Tags(tagID)
	Variable tagID=0;
	prompt tagID,"Tag Number:"
	
	HDFInfo tag2text=tagID
end

//
//	The following proc gets from the user the path and the file name for the HDF source
//
// 

Proc SetHDFSource(pathName, srcFile)
	String pathName
	Prompt pathName "Symbolic Path", popup "_Create New Path_;" + PathList("*",";","")
	String srcFile
	Prompt srcFile,"File name or \"\" to choose file from a dialog"
	PauseUpdate;silent 1
	Variable dummyFileRefNum
	String/G  gHDF_src_file,gHDF_src_path
	
	gHDF_src_path=pathName
	if ((strlen(pathName)==0) %| (CmpStr(pathName, "_Create New Path_")==0))
		NewPath/O hdfPath
		gHDF_src_path = "hdfPath"
	endif
	
	if (strlen(srcFile)==0)
		Open/R/D/T="????"/P=$gHDF_src_path/M="Choose an HDF file" dummyFileRefNum
		gHDF_src_file = S_fileName
	endif
	
end

//
//*******************************************************************
//

Function/S wave2string(w)
	Wave w
	
	PauseUpdate; silent 1
	Variable num=numpnts(w)
	Variable i=0
	String	str="",tmp=""
		
	do
		if(w[i]<1)								// allow only valid reference values
			return tmp
		endif
		str=str+num2str(w[i])+";"
		i+=1
	while(i<num)

	return str
end

//
//*******************************************************************
//

Macro ReadHDFSDS()

	SetHDFSource()
	if(strlen(gHDF_src_file)==0)
		return
	endif

	PauseUpdate; silent 1
	Variable/G	gImageIndex=1
	String/G	gRefList
	
	//  Before we ask for the reference number we find which references are in the specified
	//  file.  The references are stored into a wave HDF_List which we will convert into
	//  a global string to be used in getImageIndex()
	
	if(Exists("HDF_List"))
		KillWaves HDF_List
	endif
	
	HDFInfo		ListSDS,mode=4,gHDF_src_file
	
	if(numpnts(HDF_List)<1)
		print  "There are no SDS objects in this file"
	else
		gRefList=wave2String(HDF_List)
		if(strlen(gRefList)>0)
			getImageIndex()
			
			if(gImageIndex>0)
				HDFReadSDS Ref=gImageIndex,gHDF_src_file
			endif
		else
			print "There are no SDS objects in this file"
		endif
	endif
	
	//  cleanup name space
	KillVariables gImageIndex
	KillStrings gRefList
end

//
//*******************************************************************
//

Macro ListHDFVgroups()

	SetHDFSource()
	if(strlen(gHDF_src_file)==0)
		return
	endif
	
	PauseUpdate; silent 1
	HDFInfo vgroupsrefs,gHDF_src_file
	Variable numRefs=numpnts(HDF_VGroupRefs)
	if(numRefs>0)
		print "Group Name		No. of objects"
		Variable i=0
		do
			HDFInfo VGroupName,ref=HDF_VGroupRefs[i], gHDF_src_file
			HDFInfo ref=HDF_VGroupRefs[i],numvobjects, gHDF_src_file
			printf "%d)  %s:\t\t%d\r",i+1, HDF_VGroupName,HDF_NumVObjects
			i+=1
		while(i<numRefs)
		
		KillStrings gHDF_src_file,gHDF_src_path,HDF_VGroupName
	endif
	KillWaves HDF_VGroupRefs
end

//
//*******************************************************************
//

Macro HDFsdsInfo()

	SetHDFSource()
	if(strlen(gHDF_src_file)==0)
		return
	endif
	
	PauseUpdate; silent 1
	
	HDFInfo ListSDS,mode=4,gHDF_src_file
	Variable numRefs=numpnts(HDF_List)
	if(numRefs>0)
		Variable/G	gImageIndex=1
		String/G	gRefList
		
		gRefList=wave2String(HDF_List)
		if(strlen(gRefList)>0)
			getImageIndex()
			if(gImageIndex>0)
				HDFInfo SDSInfo,SDSRange,SDSCal,ref=gImageIndex,gHDF_src_file
				printf "SDS Information for reference %g:\r",gImageIndex
				printf "\tRank=%g\t HDF Number type=%g Number of sets=%g\r",HDF_SDS_Rank,HDF_SDS_NumType,HDF_SDS_NumSets
				if(Exists("HDF_SDS_Max"))
					printf "\tRange: \t Max=%g\tMin=%g\tFill=%g\r" HDF_SDS_Max,HDF_SDS_Min,HDF_SDS_Fill
					endif
				if(Exists("HDF_SDS_Cal"))
					printf "\tCalibration:\t Cal=%g\tcal_error=%gcal_offset=%g\tcal_offset_error=%g\r", HDF_SDS_Cal,HDF_SDS_CalError,HDF_SDS_CalOffset,HDF_SDS_CalOffsetError
				endif
			else
				print "Could not find specified SDS"
			endif
		else
			print "Could not find specified SDS"
		endif
	endif
	
	KillWaves HDF_List
	KillStrings gHDF_src_file,gHDF_src_path
end

//
//*******************************************************************
//


