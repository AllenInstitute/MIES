﻿/*
**	The data structures here are the same as those used internally by
**	Igor Pro.  Unlike wave handles you deal with these structures directly.
**	Thus you have to be careful to verify version numbers
**	before using.
**	NOTE:
**		as of 8-17-94, this structure def was changed to be ansii compliant.
**		Previously, the fifoData item at the end of the struct was a [0]
**		and is now a [1]. We still think of it as [0] and use the follow
**		to determine the base size:
**			ZSIZEOF(NamedFIFO,fifoData)
**		where ZSIZEOF is defined like so:
**			#define ZSIZEOF(x,y) ((size_t)&( (x *) 0)->y)
**
**	LH951230: Made sneaky change to struct ChartChanInfo. First element
**		was a long and is now two shorts. Old code should contine to work
**		without change.
**
**	JW980205: Made another sneaky change. In NamedFIFO structure, shortened
**		the fifoVersion field to unsigned char in order to use the high byte
**		for bitwise flags. So far, only one bit is used: bit 0 on means that
**		bytes must be swapped when reading the FIFO's file. An XOP that gets
**		this new version won't be affected as long as it either only writes
**		to FIFO files, or if it only works with FIFO's written on the same platform.
**		An XOP that really needs to handle cross-platform FIFO's must be re-written
**		to use the new field.
*/

#pragma pack(2)		// All structures passed to Igor are two-byte aligned.

#define FIFO_VERSION_NUM 0x03
#define FIFO_SWAP_BYTES 1		// for use in the flags field
#define MAX_FIFO_NAME 31

typedef struct NamedFIFO{
	struct NamedFIFO **next;	// linked list of these thingies
	char fifoName[MAX_FIFO_NAME+1];	// name of this fifo
	
	int fifoTot;				// total chunks written to fifo so far
	int diskTot;				// total chunks written to disk so far
	int fifoSize;				// size of FIFO in chunks
	
	int fifoWrite;				// byte offset into fifo data for next write
	int diskRead;				// byte offset into fifo data for next disk read
	int fifoBytes;				// size of FIFO in bytes
	
	short frefnum;				// refnum of open file or zero
	unsigned char flags;		// for up to 8 flags... 980205: bit 0 on indicates that bytes must be swapped when reading from the FIFO's data
	unsigned char fifoVersion;	// version number of this data structure
	
	short running;				// non-zero if in running state
	short valid;				// set true when everything is jake; false when not
	short fileDataStart;		// position in disk file of start of data area
	short error;				// error number for runtime error.  (disk overflow, fifo overflow)
	
	int chunkSize;				// how many bytes in a chunk
	void **chunkInfo;			// defines the structure of a chunk + other info
	
	short usageCount;			// handle can be killed or resized only if this is zero
	short offsetToData;			// add contents to address of this field to get to start of data

	int did;					// dependency id number
	
	char fifoData[1];			// the data (really [0]) *** see NOTE: above
}NamedFIFO;


#define DEF_FIFO_SIZE 10000

#define MAX_NOTESIZE 255
#define FIFO_CHAN_VERSION_NUM 0x01
#define MAX_FIFO_CHANNEL_NAME 31

typedef struct ChartChanInfo{
	short vectpnts;				// if not zero, makes this channel a color strip of this number of points
	short ntype;				// number type -- NT_FP32 or NT_I16 or ...
	double offset,gain;			// result= (measval-offset)*gain
	double fsPlus,fsMinus;		// value of + & - full scale
	char fifoChannelName[MAX_FIFO_CHANNEL_NAME+1];	// name of this channel
	char units[4];				// SU abbrev of units
	int chanRefcon;				// for use by data acquisition sw
}ChartChanInfo;

typedef struct ChartChunkInfo{
	int type;					// 'chrt'
	short version;				// version number of this data structure
	short pad1;					// maintain 32 bit alignment
	unsigned long startDate;	// datetime of start command
	char note[MAX_NOTESIZE+1];	// room for a short note from user
	double deltaT;				// data acquisition speed (if known,in seconds)
	int xopRefcon;				// for use by data acquisition sw
	int nchan;					// number of channels
	ChartChanInfo info[1];		// info for each channel (really [0]) *** see note about ZSIZEOF above
}ChartChunkInfo;


#define CUR_FIFOFILE_VERSION 0
typedef struct FIFOFileHeader{
	int typeP1,typeP2;			// 'IGOR','fifo'
	int version;				// CUR_FIFOFILE_VERSION
	int datasize;				// bytes of data following ChartChunkInfo field if known
	int hsize;					// size of following ChartChunkInfo field; data follows that
}FIFOFileHeader;


#define CUR_FIFOSplitFILE_VERSION (CUR_FIFOFILE_VERSION+1)
typedef struct FIFOSplitFileHeader{
	int typeP1,typeP2;			// 'IGOR','fifo'
	int version;				// CUR_FIFOSplitFILE_VERSION

	/*
	**	The split file header differs from the unified by the insertion of
	**	the following 3 fields.
	*/
	char datafile[256];			// c-string containing relative path to file containing data
	int dataoffset;				// offset into data file
	int dsize;					// number of bytes of data or zero to use entire rest of file

	int datasize;				// bytes of data following ChartChunkInfo field if known
	int hsize;					// size of following ChartChunkInfo field; data follows that
}FIFOSplitFileHeader;


#pragma pack()		// Reset structure alignment to default.
