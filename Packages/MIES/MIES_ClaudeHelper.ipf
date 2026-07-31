#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_CH
#endif // AUTOMATED_TESTING

/// @file MIES_ClaudeHelper.ipf
/// @brief Helper functions for the Igor Pro Bridge MCP server (tools/igor-mcp-bridge)

#ifdef IGOR_PRO_BRIDGE

// PE (Portable Executable) format constants used by the CH_PE* helpers below to
// parse a compiled .xop's headers and resource directory. Offsets/sizes are
// per the documented Microsoft PE/COFF format (IMAGE_DOS_HEADER,
// IMAGE_FILE_HEADER, IMAGE_OPTIONAL_HEADER64, IMAGE_SECTION_HEADER,
// IMAGE_RESOURCE_DIRECTORY(_ENTRY), IMAGE_RESOURCE_DATA_ENTRY) unless noted as
// XOP Toolkit-specific.
static Constant CH_PE_DOS_SIGNATURE                      = 0x5A4D     // "MZ" -- IMAGE_DOS_HEADER.e_magic
static Constant CH_PE_SIGNATURE                          = 0x00004550 // "PE\0\0"
static Constant CH_PE_SIGNATURE_SIZE                     = 4          // sizeof(uint32), size of the "PE\0\0" signature itself
static Constant CH_PE_E_LFANEW_OFFSET                    = 0x3C       // IMAGE_DOS_HEADER offset to e_lfanew (PE header file offset)
static Constant CH_PE_OPTIONAL_HEADER_MAGIC_PE32PLUS     = 0x20B      // IMAGE_OPTIONAL_HEADER64.Magic
static Constant CH_PE_FILE_HEADER_SIZE                   = 20         // sizeof(IMAGE_FILE_HEADER)
static Constant CH_PE_FILE_HEADER_NUM_SECTIONS_OFFSET    = 2          // offset within IMAGE_FILE_HEADER
static Constant CH_PE_FILE_HEADER_SIZE_OF_OPT_HDR_OFFSET = 16         // offset within IMAGE_FILE_HEADER
static Constant CH_PE_OPT_HEADER_DATA_DIR_OFFSET         = 112        // PE32+ Optional Header offset to the Data Directory array
static Constant CH_PE_DATA_DIRECTORY_ENTRY_SIZE          = 8          // sizeof(IMAGE_DATA_DIRECTORY): uint32 RVA + uint32 Size
static Constant CH_PE_RESOURCE_TABLE_DIR_INDEX           = 2          // index of the Resource Table entry within the Data Directory array
static Constant CH_PE_SECTION_HEADER_SIZE                = 40         // sizeof(IMAGE_SECTION_HEADER)
static Constant CH_PE_SECTION_VIRTUAL_SIZE_OFFSET        = 8          // offset within IMAGE_SECTION_HEADER
static Constant CH_PE_SECTION_VIRTUAL_ADDRESS_OFFSET     = 12         // offset within IMAGE_SECTION_HEADER
static Constant CH_PE_SECTION_RAW_DATA_PTR_OFFSET        = 20         // offset within IMAGE_SECTION_HEADER
static Constant CH_PE_RESDIR_NUM_NAMED_ENTRIES_OFFSET    = 12         // offset within IMAGE_RESOURCE_DIRECTORY
static Constant CH_PE_RESDIR_NUM_ID_ENTRIES_OFFSET       = 14         // offset within IMAGE_RESOURCE_DIRECTORY
static Constant CH_PE_RESDIR_ENTRIES_OFFSET              = 16         // offset within IMAGE_RESOURCE_DIRECTORY to its entry array
static Constant CH_PE_RESDIR_ENTRY_SIZE                  = 8          // sizeof(IMAGE_RESOURCE_DIRECTORY_ENTRY)
static Constant CH_PE_RESDIR_ENTRY_OFFSET_FIELD_OFFSET   = 4          // offset within IMAGE_RESOURCE_DIRECTORY_ENTRY to its Offset field
static Constant CH_PE_RESOURCE_HIGH_BIT_FLAG             = 0x80000000 // marks a named Name field, or a subdirectory Offset field
static Constant CH_PE_RESOURCE_OFFSET_MASK               = 0x7FFFFFFF // strips CH_PE_RESOURCE_HIGH_BIT_FLAG off a Name/Offset field
static Constant CH_PE_DATA_ENTRY_SIZE_FIELD_OFFSET       = 4          // offset within IMAGE_RESOURCE_DATA_ENTRY to its Size field
static Constant CH_XOP_RESOURCE_ID                       = 1100       // resource ID the XOP Toolkit uses for XOPI/XOPC/XOPF (XOPMan8.pdf)
static Constant CH_PE_PAD_CHAR                           = 0x20       // ASCII space, used to pre-size a string buffer for FBinRead
static Constant CH_UINT16_BYTE_SIZE                      = 2          // bytes per uint16 field (also one UTF-16LE code unit)
static Constant CH_BYTE_SHIFT_8BIT                       = 256        // multiplier for the high byte of a little-endian uint16
static Constant CH_CSTRING_SEARCH_INITIAL_CHUNK          = 256        // initial read size when hunting for a null terminator
static Constant CH_CSTRING_SEARCH_MAX_CHUNK              = 8192       // give up (return -1) once search size exceeds this many bytes
static Constant CH_CMPSTR_CASE_SENSITIVE                 = 1          // CmpStr's caseSensitive flag (1 = case-sensitive, per Igor Reference)

/// AfterCompiledHook() is a predefined Igor hook: Igor calls it after ALL procedure
/// windows have compiled successfully (confirmed from Igor Pro Folder/Igor Help
/// Files/Advanced Topics.ihf). It is declared static so it coexists with any other
/// file's own static AfterCompiledHook() (e.g. the one in MIES_Include.ipf used only
/// for the too-old-Igor warning panel) without colliding.
///
/// It records a monotonically increasing counter in root:gClaudeHelperCompileCounter
/// each time it fires. This gives the Igor Pro Bridge a compile confirmation
/// driven by Igor itself, rather than only inferred by polling FunctionInfo() for a
/// non-existing function -- which can read stale state before Igor's operation queue
/// (RELOAD CHANGED PROCS / COMPILEPROCEDURES) has actually drained. There is no
/// equivalent Igor hook for a *failed* compile, so this only helps confirm success,
/// not detect failure.

static Function AfterCompiledHook()

	variable modifiedBefore

	// Creating/incrementing a global marks the experiment as modified, same as any
	// other data change. Captured/restored here so this hook never flips an
	// otherwise-unmodified experiment to modified, matching the existing convention
	// in MIES_IgorHooks.ipf's own AfterCompiledHook -- flagged by a Copilot PR
	// review as a real risk otherwise: an experiment spuriously marked modified can
	// trigger a "Save changes?" prompt later, which is exactly the kind of dialog
	// this bridge (built around unattended operation) cannot dismiss remotely.
	ExperimentModified
	modifiedBefore = V_flag

	// Bare Variable/G (no initializer) is safe to call unconditionally: per Igor
	// Reference.ihf, /G "overwrites any existing variable" but "the variable is
	// initialized when it is created if you supply the initial value" -- i.e. the
	// overwrite-to-a-value only happens when an initializer is given. Without one,
	// this creates the global at 0 the first time and leaves an existing value
	// alone on every call after that, so no NVAR_Exists guard is needed.
	variable/G root:gClaudeHelperCompileCounter
	NVAR gClaudeHelperCompileCounter = root:gClaudeHelperCompileCounter

	gClaudeHelperCompileCounter += 1

	if(!modifiedBefore)
		ExperimentModified 0
	endif

	return 0
End

/// CH_ListXOPExports(xopPath) reads the operations and functions a compiled .xop
/// file (a Windows DLL) adds to Igor, straight from the file's own bytes -- no
/// vendor documentation or source needed, and no live Igor Pro instance needs to
/// have that XOP loaded.
///
/// Background (confirmed this session against WaveMetrics' own XOP Toolkit 8.01
/// manual, XOPMan8.pdf, and cross-checked live against real, closed-source .xop
/// files including this repo's own XOPs-64bit/JSON-64.xop and .../ZeroMQ-64.xop,
/// whose decoded names matched FunctionList/OperationList's live results exactly):
/// every .xop declares the operations and functions it adds via two custom
/// resources, XOPC (operations) and XOPF (functions), each with resource ID 1100.
/// On Windows these are ordinary named Windows PE resources (resource TYPE name
/// literally "XOPC"/"XOPF", not a numeric type, and not a proprietary format) --
/// the standard Windows resource compiler embeds them directly in the .xop/DLL's
/// own .rsrc section, the same mechanism used for any other named Win32 resource.
///
/// Binary layout of the resource data itself (confirmed from the manual's Windows
/// .rc source examples for XOPC/XOPF):
///   XOPC: repeating {null-terminated name string; little-endian uint16 category
///     bitmask}, terminated by an empty-name (single 0x00 byte) record.
///   XOPF: repeating {null-terminated name string; uint16 category bitmask; uint16
///     return-type code; uint16 parameter-type code * N; uint16 0 to terminate that
///     function's parameter list}, terminated the same way as XOPC.
/// This implementation only extracts the name lists (category/type bit values are
/// documented in the manual but not decoded here, since the name list is what's
/// actually useful for "what does this XOP add").
///
/// Only supports 64-bit (PE32+) XOPs -- true of every XOP actually in use in this
/// repo (all "-64.xop"/"64.xop" files) -- and aborts with a clear message for a
/// 32-bit (PE32) XOP rather than silently misreading it.
///
/// Returns "operations:op1;op2;...\rfunctions:func1;func2;..." (either list may be
/// empty -- not every XOP adds both kinds).

Function/S CH_ListXOPExports(string xopPath)

	string ops, funcs, result

	ops   = CH_PEListXOPResource(xopPath, "XOPC")
	funcs = CH_PEListXOPResource(xopPath, "XOPF")

	sprintf result, "operations:%s\rfunctions:%s", ops, funcs

	return result
End

static Function CH_PEReadU16(variable refNum, variable pos)

	variable v

	FSetPos refNum, pos
	FBinRead/F=2/U/B=3 refNum, v

	return v
End

static Function CH_PEReadU32(variable refNum, variable pos)

	variable v

	FSetPos refNum, pos
	FBinRead/F=3/U/B=3 refNum, v

	return v
End

static Function/S CH_PEReadBytes(variable refNum, variable pos, variable numBytes)

	string s = PadString("", numBytes, CH_PE_PAD_CHAR)

	FSetPos refNum, pos
	FBinRead refNum, s

	return s
End

// Returns the length (not including the terminator) of a null-terminated string
// starting at pos, or -1 if no null byte turns up within a generous search cap
// (CH_CSTRING_SEARCH_MAX_CHUNK bytes -- far more than any real operation/function
// name).
static Function CH_PECStringLen(variable refNum, variable pos)

	string nul = num2char(0)
	string chunk
	variable chunkSize = CH_CSTRING_SEARCH_INITIAL_CHUNK
	variable idx

	do
		chunk = CH_PEReadBytes(refNum, pos, chunkSize)
		idx   = strsearch(chunk, nul, 0)
		if(idx >= 0)
			return idx
		endif
		chunkSize *= 2
	while(chunkSize <= CH_CSTRING_SEARCH_MAX_CHUNK)

	return -1
End

// Interprets two bytes at 0-based index offset within s as a little-endian uint16.
static Function CH_BytesToU16(string s, variable offset)

	return char2num(s[offset]) + char2num(s[offset + 1]) * CH_BYTE_SHIFT_8BIT
End

// Reads a UTF-16LE resource name (as used for named PE resource directory
// entries, e.g. the "XOPC"/"XOPF" type names themselves) and returns it as a
// plain ASCII string -- sufficient here since every name this code looks for is
// pure ASCII.
static Function/S CH_PEReadUnicodeName(variable refNum, variable pos, variable numChars)

	string result = ""
	variable i, code

	for(i = 0; i < numChars; i += 1)
		code    = CH_PEReadU16(refNum, pos + i * CH_UINT16_BYTE_SIZE)
		result += num2char(code)
	endfor

	return result
End

// Converts an RVA (relative virtual address, relative to the module's load
// address) to a file offset, by finding which section contains it. Returns -1 if
// no section contains rva.
static Function CH_PERVAToFileOffset(variable refNum, variable sectionTableOffset, variable numSections, variable rva)

	variable i, secPos, secVA, secVirtSize, secRawPtr

	for(i = 0; i < numSections; i += 1)
		secPos      = sectionTableOffset + i * CH_PE_SECTION_HEADER_SIZE
		secVirtSize = CH_PEReadU32(refNum, secPos + CH_PE_SECTION_VIRTUAL_SIZE_OFFSET)
		secVA       = CH_PEReadU32(refNum, secPos + CH_PE_SECTION_VIRTUAL_ADDRESS_OFFSET)
		secRawPtr   = CH_PEReadU32(refNum, secPos + CH_PE_SECTION_RAW_DATA_PTR_OFFSET)
		if(rva >= secVA && rva < secVA + secVirtSize)
			return secRawPtr + (rva - secVA)
		endif
	endfor

	return -1
End

// Walks the PE resource directory tree (Type -> ID -> Language, 3 levels) rooted
// at resourceSectionFileOffset, looking for a named type entry matching typeName
// containing a numeric-ID entry matching resourceID. All offsets inside the
// resource directory tree itself (including the string offsets for named
// entries) are relative to resourceSectionFileOffset -- confirmed from the PE
// format's own documented convention; only the leaf IMAGE_RESOURCE_DATA_ENTRY's
// own OffsetToData field is a true RVA (handled by the caller via
// CH_PERVAToFileOffset, not here). Returns the file offset of the matching
// IMAGE_RESOURCE_DATA_ENTRY structure, or -1 if typeName/resourceID isn't present
// (not every XOP has both XOPC and XOPF).
static Function CH_PEFindResourceOffset(variable refNum, variable resourceSectionFileOffset, string typeName, variable resourceID)

	variable numNamed, numIds, numEntries, i
	variable entryPos, nameField, offsetField
	variable subdirOffset, level2Base, level3SubdirOffset, level3Base
	variable nameLen, strPos, dataEntryOffset
	string entryName

	// --- Level 1: resource TYPE directory ---
	numNamed   = CH_PEReadU16(refNum, resourceSectionFileOffset + CH_PE_RESDIR_NUM_NAMED_ENTRIES_OFFSET)
	numIds     = CH_PEReadU16(refNum, resourceSectionFileOffset + CH_PE_RESDIR_NUM_ID_ENTRIES_OFFSET)
	numEntries = numNamed + numIds

	subdirOffset = -1
	for(i = 0; i < numEntries; i += 1)
		entryPos    = resourceSectionFileOffset + CH_PE_RESDIR_ENTRIES_OFFSET + i * CH_PE_RESDIR_ENTRY_SIZE
		nameField   = CH_PEReadU32(refNum, entryPos)
		offsetField = CH_PEReadU32(refNum, entryPos + CH_PE_RESDIR_ENTRY_OFFSET_FIELD_OFFSET)

		if(nameField & CH_PE_RESOURCE_HIGH_BIT_FLAG)
			strPos    = resourceSectionFileOffset + (nameField & CH_PE_RESOURCE_OFFSET_MASK)
			nameLen   = CH_PEReadU16(refNum, strPos)
			entryName = CH_PEReadUnicodeName(refNum, strPos + CH_UINT16_BYTE_SIZE, nameLen)
			if(CmpStr(entryName, typeName, CH_CMPSTR_CASE_SENSITIVE) == 0)
				subdirOffset = offsetField
				break
			endif
		endif
	endfor

	if(subdirOffset < 0 || !(subdirOffset & CH_PE_RESOURCE_HIGH_BIT_FLAG))
		return -1
	endif

	// --- Level 2: resource ID directory ---
	level2Base = resourceSectionFileOffset + (subdirOffset & CH_PE_RESOURCE_OFFSET_MASK)
	numNamed   = CH_PEReadU16(refNum, level2Base + CH_PE_RESDIR_NUM_NAMED_ENTRIES_OFFSET)
	numIds     = CH_PEReadU16(refNum, level2Base + CH_PE_RESDIR_NUM_ID_ENTRIES_OFFSET)
	numEntries = numNamed + numIds

	level3SubdirOffset = -1
	for(i = 0; i < numEntries; i += 1)
		entryPos    = level2Base + CH_PE_RESDIR_ENTRIES_OFFSET + i * CH_PE_RESDIR_ENTRY_SIZE
		nameField   = CH_PEReadU32(refNum, entryPos)
		offsetField = CH_PEReadU32(refNum, entryPos + CH_PE_RESDIR_ENTRY_OFFSET_FIELD_OFFSET)

		if(!(nameField & CH_PE_RESOURCE_HIGH_BIT_FLAG) && nameField == resourceID)
			level3SubdirOffset = offsetField
			break
		endif
	endfor

	if(level3SubdirOffset < 0 || !(level3SubdirOffset & CH_PE_RESOURCE_HIGH_BIT_FLAG))
		return -1
	endif

	// --- Level 3: language directory -- take the first (only, in every case seen
	// so far) entry regardless of its language ID ---
	level3Base = resourceSectionFileOffset + (level3SubdirOffset & CH_PE_RESOURCE_OFFSET_MASK)
	numNamed   = CH_PEReadU16(refNum, level3Base + CH_PE_RESDIR_NUM_NAMED_ENTRIES_OFFSET)
	numIds     = CH_PEReadU16(refNum, level3Base + CH_PE_RESDIR_NUM_ID_ENTRIES_OFFSET)
	numEntries = numNamed + numIds

	if(numEntries == 0)
		return -1
	endif

	entryPos        = level3Base + CH_PE_RESDIR_ENTRIES_OFFSET
	dataEntryOffset = CH_PEReadU32(refNum, entryPos + CH_PE_RESDIR_ENTRY_OFFSET_FIELD_OFFSET)

	return resourceSectionFileOffset + dataEntryOffset
End

// Parses raw XOPC/XOPF resource bytes (already read into memory) into a
// semicolon-separated list of names, per the binary layout documented above
// CH_ListXOPExports.
static Function/S CH_ParseXOPResourceBlob(string raw, string resourceType)

	variable pos   = 0
	variable len   = strlen(raw)
	string   nul   = num2char(0)
	string   names = ""
	variable nameEnd, nameLen
	string name
	variable category, retType, paramType

	do
		nameEnd = strsearch(raw, nul, pos)
		if(nameEnd < 0)
			break
		endif
		nameLen = nameEnd - pos
		if(nameLen == 0)
			break
		endif
		name = raw[pos, nameEnd - 1]
		pos  = nameEnd + 1

		category = CH_BytesToU16(raw, pos)
		pos     += CH_UINT16_BYTE_SIZE

		if(CmpStr(resourceType, "XOPF", CH_CMPSTR_CASE_SENSITIVE) == 0)
			retType = CH_BytesToU16(raw, pos)
			pos    += CH_UINT16_BYTE_SIZE
			do
				paramType = CH_BytesToU16(raw, pos)
				pos      += CH_UINT16_BYTE_SIZE
			while(paramType != 0)
		endif

		if(strlen(names) > 0)
			names += ";"
		endif
		names += name
	while(pos < len)

	return names
End

// Opens xopPath, parses its PE headers, locates the named resourceType
// (CH_XOP_RESOURCE_ID) resource if present, and returns its decoded name list
// ("" if that XOP has no resource of that type).
static Function/S CH_PEListXOPResource(string xopPath, string resourceType)

	variable refNum
	variable dosSig, peOffset, peSig
	variable fileHeaderOffset, numSections, sizeOfOptHeader, optHeaderOffset, magic
	variable resourceEntryOffset, resourceRVA, sectionTableOffset, resourceSectionFileOffset
	variable dataEntryFileOffset, dataRVA, dataSize, dataFileOffset
	string raw

	Open/R/Z refNum as xopPath
	if(V_flag != 0)
		Abort "CH_ListXOPExports: could not open file: " + xopPath
	endif

	dosSig = CH_PEReadU16(refNum, 0)
	if(dosSig != CH_PE_DOS_SIGNATURE) // "MZ"
		Close refNum
		Abort "CH_ListXOPExports: missing MZ/DOS signature, not a PE file: " + xopPath
	endif

	peOffset = CH_PEReadU32(refNum, CH_PE_E_LFANEW_OFFSET)
	peSig    = CH_PEReadU32(refNum, peOffset)
	if(peSig != CH_PE_SIGNATURE) // "PE\0\0"
		Close refNum
		Abort "CH_ListXOPExports: missing PE signature: " + xopPath
	endif

	fileHeaderOffset = peOffset + CH_PE_SIGNATURE_SIZE
	numSections      = CH_PEReadU16(refNum, fileHeaderOffset + CH_PE_FILE_HEADER_NUM_SECTIONS_OFFSET)
	sizeOfOptHeader  = CH_PEReadU16(refNum, fileHeaderOffset + CH_PE_FILE_HEADER_SIZE_OF_OPT_HDR_OFFSET)
	optHeaderOffset  = fileHeaderOffset + CH_PE_FILE_HEADER_SIZE
	magic            = CH_PEReadU16(refNum, optHeaderOffset)

	if(magic != CH_PE_OPTIONAL_HEADER_MAGIC_PE32PLUS)
		Close refNum
		Abort "CH_ListXOPExports: only 64-bit (PE32+) XOPs are supported; magic=0x" + num2istr(magic) + " for " + xopPath
	endif

	// PE32+ Data Directory array starts at offset CH_PE_OPT_HEADER_DATA_DIR_OFFSET
	// within the Optional Header; CH_PE_RESOURCE_TABLE_DIR_INDEX (0-based) is the
	// Resource Table entry -- confirmed from the PE format's own documented
	// Optional Header layout.
	resourceEntryOffset = optHeaderOffset + CH_PE_OPT_HEADER_DATA_DIR_OFFSET + CH_PE_RESOURCE_TABLE_DIR_INDEX * CH_PE_DATA_DIRECTORY_ENTRY_SIZE
	resourceRVA         = CH_PEReadU32(refNum, resourceEntryOffset)

	sectionTableOffset        = optHeaderOffset + sizeOfOptHeader
	resourceSectionFileOffset = CH_PERVAToFileOffset(refNum, sectionTableOffset, numSections, resourceRVA)
	if(resourceSectionFileOffset < 0)
		Close refNum
		Abort "CH_ListXOPExports: could not locate the .rsrc section: " + xopPath
	endif

	dataEntryFileOffset = CH_PEFindResourceOffset(refNum, resourceSectionFileOffset, resourceType, CH_XOP_RESOURCE_ID)
	if(dataEntryFileOffset < 0)
		Close refNum
		return ""
	endif

	dataRVA  = CH_PEReadU32(refNum, dataEntryFileOffset)
	dataSize = CH_PEReadU32(refNum, dataEntryFileOffset + CH_PE_DATA_ENTRY_SIZE_FIELD_OFFSET)

	dataFileOffset = CH_PERVAToFileOffset(refNum, sectionTableOffset, numSections, dataRVA)
	if(dataFileOffset < 0)
		Close refNum
		Abort "CH_ListXOPExports: could not locate raw " + resourceType + " data: " + xopPath
	endif

	raw = CH_PEReadBytes(refNum, dataFileOffset, dataSize)
	Close refNum

	return CH_ParseXOPResourceBlob(raw, resourceType)
End
#endif // IGOR_PRO_BRIDGE
