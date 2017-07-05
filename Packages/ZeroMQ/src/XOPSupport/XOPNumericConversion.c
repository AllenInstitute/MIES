/*	XOPNumericConversion.c
	
	Numeric conversion routines.
	HR, 1/9/96: Moved these routines from XOPSupport.c.

	HR, 091001: Added casts to prevent VC warnings.
*/

#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h

/*	NumTypeToNumBytesAndFormat(numType, numBytesPerValuePtr, dataFormatPtr, isComplexPtr)
	
	This routine is useful in converting standard Igor number type codes (e.g., NT_FP64),
	which are defined in IgorXOP.h, into the XOP Toolkit number format codes (IEEE_FLOAT,
	SIGNED_INT, and UNSIGNED_INT), also defined in IgorXOP.h.
	
	This is sometimes needed because the XOP Toolkit codes were defined before
	the Igor codes included signed and unsigned numbers. Thus, some XOP Toolkit
	routines were defined to take XOP Toolkit codes whereas nowadays it would
	be more natural for them to take Igor number type codes.
	
	This routine is used in ConvertData2, below.
	
	Thread Safety: NumTypeToNumBytesAndFormat is thread-safe. It can be called from any thread.
*/
int
NumTypeToNumBytesAndFormat(int numType, int* numBytesPerValuePtr, int* dataFormatPtr, int* isComplexPtr)
{
	int err = 0;
	
	*isComplexPtr = numType & NT_CMPLX;
	
	switch (numType & ~NT_CMPLX) {
		case NT_FP64:
			*numBytesPerValuePtr = 8;		// Note that *numBytesPerValuePtr does not take complex into account.
			*dataFormatPtr = IEEE_FLOAT;
			break;
		case NT_FP32:
			*numBytesPerValuePtr = 4;
			*dataFormatPtr = IEEE_FLOAT;
			break;
		case NT_I64:						// Added in Igor Pro 7.00
			*numBytesPerValuePtr = 8;
			*dataFormatPtr = SIGNED_INT;
			break;
		case NT_I32:
			*numBytesPerValuePtr = 4;
			*dataFormatPtr = SIGNED_INT;
			break;
		case NT_I16:
			*numBytesPerValuePtr = 2;
			*dataFormatPtr = SIGNED_INT;
			break;
		case NT_I8:
			*numBytesPerValuePtr = 1;
			*dataFormatPtr = SIGNED_INT;
			break;
		case NT_I64 | NT_UNSIGNED:			// Added in Igor Pro 7.00
			*numBytesPerValuePtr = 8;
			*dataFormatPtr = UNSIGNED_INT;
			break;
		case NT_I32 | NT_UNSIGNED:
			*numBytesPerValuePtr = 4;
			*dataFormatPtr = UNSIGNED_INT;
			break;
		case NT_I16 | NT_UNSIGNED:
			*numBytesPerValuePtr = 2;
			*dataFormatPtr = UNSIGNED_INT;
			break;
		case NT_I8 | NT_UNSIGNED:
			*numBytesPerValuePtr = 1;
			*dataFormatPtr = UNSIGNED_INT;
			break;
		case TEXT_WAVE_TYPE:
			err = NO_TEXT_OP;
			break;
		default:
			err = NT_FNOT_AVAIL;
			break;
	}
	
	return err;
}

/*	NumBytesAndFormatToNumType(numBytesPerValue, dataFormat, numTypePtr)

	This routine is converts XOP Toolkit number format codes (IEEE_FLOAT, SIGNED_INT,
	and UNSIGNED_INT), defined in IgorXOP.h, into standard Igor number type codes (e.g., NT_FP64),
	also defined in IgorXOP.h.
	
	This is sometimes needed because the XOP Toolkit codes were defined before
	the Igor codes included signed and unsigned numbers. Thus, some XOP Toolkit
	routines were defined to take XOP Toolkit codes whereas nowadays it would
	be more natural for them to take Igor number type codes.
	
	Thread Safety: NumBytesAndFormatToNumType is thread-safe. It can be called from any thread.
*/
int
NumBytesAndFormatToNumType(int numBytesPerValue, int dataFormat, int* numTypePtr)
{
	int err = 0;
	
	switch (dataFormat) {
		case IEEE_FLOAT:
			switch (numBytesPerValue) {
				case 8:
					*numTypePtr = NT_FP64;
					break;
				case 4:
					*numTypePtr = NT_FP32;
					break;
				default:
					err = NT_FNOT_AVAIL;
					break;
			}
			break;

		case SIGNED_INT:
			switch (numBytesPerValue) {
				case 8:
					*numTypePtr = NT_I64;				// Added in Igor Pro 7.00
					break;
				case 4:
					*numTypePtr = NT_I32;
					break;
				case 2:
					*numTypePtr = NT_I16;
					break;
				case 1:
					*numTypePtr = NT_I8;
					break;
				default:
					err = NT_FNOT_AVAIL;
					break;
			}
			break;

		case UNSIGNED_INT:
			switch (numBytesPerValue) {
				case 8:
					*numTypePtr = NT_I64 | NT_UNSIGNED;	// Added in Igor Pro 7.00
					break;
				case 4:
					*numTypePtr = NT_I32 | NT_UNSIGNED;
					break;
				case 2:
					*numTypePtr = NT_I16 | NT_UNSIGNED;
					break;
				case 1:
					*numTypePtr = NT_I8 | NT_UNSIGNED;
					break;
				default:
					err = NT_FNOT_AVAIL;
					break;
			}
			break;
		
		default:
			err = NT_FNOT_AVAIL;
			break;
	}
	
	return err;
}


// Conversion from double.

void
DoubleToFloat(const double* inPtr, float* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (float)(*inPtr++);
}

void
DoubleToSInt64(const double* inPtr, SInt64* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (SInt64)(*inPtr++);
}

void
DoubleToSInt32(const double* inPtr, SInt32* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (SInt32)(*inPtr++);
}

void
DoubleToShort(const double* inPtr, short* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (short)(*inPtr++);
}

void
DoubleToByte(const double* inPtr, char* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (char)(*inPtr++);
}

void
DoubleToUInt64(const double* inPtr, UInt64* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (UInt64)(*inPtr++);
}

void
DoubleToUInt32(const double* inPtr, UInt32* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (UInt32)(*inPtr++);
}

void
DoubleToUnsignedShort(const double* inPtr, unsigned short* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (unsigned short)(*inPtr++);
}

void
DoubleToUnsignedByte(const double* inPtr, unsigned char* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (unsigned char)(*inPtr++);
}

/*	ConvertDouble(src, dest, numValues, destFormat, destBytes)

	Returns -1 if no conversion needed or 0 otherwise.

	Thread Safety: ConvertDouble is thread-safe. It can be called from any thread.
*/
int
ConvertDouble(const double* src, void* dest, CountInt numValues, int destFormat, int destBytes)
{
	int result = 0;
	
	switch (destFormat) {
		case IEEE_FLOAT:
			switch (destBytes) {
				case 8:
					if (src != dest)
						memcpy((char*)dest, (char*)src, destBytes*numValues);
					result = -1;
					break;
				
				case 4:
					DoubleToFloat(src, (float*)dest, numValues);
					break;
			}
			break;
		
		case SIGNED_INT:
			switch (destBytes) {
				case 8:
					DoubleToSInt64(src, (SInt64*)dest, numValues);
					break;
				
				case 4:
					DoubleToSInt32(src, (SInt32*)dest, numValues);
					break;
				
				case 2:
					DoubleToShort(src, (short*)dest, numValues);
					break;
				
				case 1:
					DoubleToByte(src, (char*)dest, numValues);
					break;
			}
			break;
	
		case UNSIGNED_INT:
			switch (destBytes) {
				case 8:
					DoubleToUInt64(src, (UInt64*)dest, numValues);
					break;
				
				case 4:
					DoubleToUInt32(src, (UInt32*)dest, numValues);
					break;
				
				case 2:
					DoubleToUnsignedShort(src, (unsigned short*)dest, numValues);
					break;
				
				case 1:
					DoubleToUnsignedByte(src, (unsigned char*)dest, numValues);
					break;
			}
			break;
	}
	return result;
}


// Conversion from float.

void
FloatToDouble(const float* inPtr, double* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (double)*inPtr--;
}

void
FloatToSInt64(const float* inPtr, SInt64* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (SInt64)*inPtr--;
}

void
FloatToSInt32(const float* inPtr, SInt32* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (SInt32)(*inPtr++);
}

void
FloatToShort(const float* inPtr, short* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (short)(*inPtr++);
}

void
FloatToByte(const float* inPtr, char* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (char)(*inPtr++);
}

void
FloatToUInt64(const float* inPtr, UInt64* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (UInt64)*inPtr--;
}

void
FloatToUInt32(const float* inPtr, UInt32* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (UInt32)(*inPtr++);
}

void
FloatToUnsignedShort(const float* inPtr, unsigned short* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (unsigned short)(*inPtr++);
}

void
FloatToUnsignedByte(const float* inPtr, unsigned char* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (unsigned char)(*inPtr++);
}

/*	ConvertFloat(src, dest, numValues, destFormat, destBytes)

	Returns -1 if no conversion needed or 0 otherwise.

	Thread Safety: ConvertFloat is thread-safe. It can be called from any thread.
*/
int
ConvertFloat(const float* src, void* dest, CountInt numValues, int destFormat, int destBytes)
{
	int result = 0;
	
	switch (destFormat) {
		case IEEE_FLOAT:
			switch (destBytes) {
				case 8:
					FloatToDouble(src, (double*)dest, numValues);
					break;
				
				case 4:
					if (src != dest)
						memcpy((char*)dest, (char*)src, destBytes*numValues);
					result = -1;
					break;
			}
			break;
		
		case SIGNED_INT:
			switch (destBytes) {
				case 8:
					FloatToSInt64(src, (SInt64*)dest, numValues);
					break;
				
				case 4:
					FloatToSInt32(src, (SInt32*)dest, numValues);
					break;
				
				case 2:
					FloatToShort(src, (short*)dest, numValues);
					break;
				
				case 1:
					FloatToByte(src, (char*)dest, numValues);
					break;
			}
			break;
	
		case UNSIGNED_INT:
			switch (destBytes) {
				case 8:
					FloatToUInt64(src, (UInt64*)dest, numValues);
					break;
				
				case 4:
					FloatToUInt32(src, (UInt32*)dest, numValues);
					break;
				
				case 2:
					FloatToUnsignedShort(src, (unsigned short*)dest, numValues);
					break;
				
				case 1:
					FloatToUnsignedByte(src, (unsigned char*)dest, numValues);
					break;
			}
			break;
	}
	return result;
}


// Conversion from SInt64.

void
SInt64ToDouble(const SInt64* inPtr, double* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (double)(*inPtr++);
}

void
SInt64ToFloat(const SInt64* inPtr, float* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (float)(*inPtr++);
}

void
SInt64ToSInt32(const SInt64* inPtr, SInt32* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (SInt32)(*inPtr++);
}

void
SInt64ToShort(const SInt64* inPtr, short* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (short)(*inPtr++);
}

void
SInt64ToByte(const SInt64* inPtr, char* outPtr, CountInt numValues)			// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (char)(*inPtr++);
}

void	// SInt64ToUInt64 conflicts with an Apple macro
WMSInt64ToUInt64(const SInt64* inPtr, UInt64* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (UInt64)*inPtr++;
}

void
SInt64ToUInt32(const SInt64* inPtr, UInt32* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (UInt32)*inPtr++;
}

void
SInt64ToUnsignedShort(const SInt64* inPtr, unsigned short* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (unsigned short)(*inPtr++);
}

void
SInt64ToUnsignedByte(const SInt64* inPtr, unsigned char* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (unsigned char)(*inPtr++);
}

/*	ConvertSInt64(src, dest, numValues, destFormat, destBytes)

	Returns -1 if no conversion needed or 0 otherwise.

	Thread Safety: ConvertSInt64 is thread-safe. It can be called from any thread.
*/
int
ConvertSInt64(const SInt64* src, void* dest, CountInt numValues, int destFormat, int destBytes)
{
	int result = 0;
	
	switch (destFormat) {
		case IEEE_FLOAT:
			switch (destBytes) {
				case 8:
					SInt64ToDouble(src, (double*)dest, numValues);
					break;
				
				case 4:
					SInt64ToFloat(src, (float*)dest, numValues);
					break;
			}
			break;
		
		case SIGNED_INT:
			switch (destBytes) {
				case 8:
					if (src != dest)
						memcpy((char*)dest, (char*)src, destBytes*numValues);
					result = -1;
					break;
				
				case 4:
					SInt64ToSInt32(src, (SInt32*)dest, numValues);
					break;
				
				case 2:
					SInt64ToShort(src, (short*)dest, numValues);
					break;
				
				case 1:
					SInt64ToByte(src, (char*)dest, numValues);
					break;
			}
			break;
	
		case UNSIGNED_INT:
			switch (destBytes) {
				case 8:
					WMSInt64ToUInt64(src, (UInt64*)dest, numValues);
					break;
				
				case 4:
					SInt64ToUInt32(src, (UInt32*)dest, numValues);
					break;
				
				case 2:
					SInt64ToUnsignedShort(src, (unsigned short*)dest, numValues);
					break;
				
				case 1:
					SInt64ToUnsignedByte(src, (unsigned char*)dest, numValues);
					break;
			}
			break;
	}
	return result;
}


// Conversion from SInt32.

void
SInt32ToDouble(const SInt32* inPtr, double* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (double)*inPtr--;
}

void
SInt32ToFloat(const SInt32* inPtr, float* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (float)(*inPtr++);
}

void
SInt32ToSInt64(const SInt32* inPtr, SInt64* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (SInt64)*inPtr--;
}

void
SInt32ToShort(const SInt32* inPtr, short* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (short)(*inPtr++);
}

void
SInt32ToByte(const SInt32* inPtr, char* outPtr, CountInt numValues)			// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (char)(*inPtr++);
}

void
SInt32ToUInt64(const SInt32* inPtr, UInt64* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (UInt64)*inPtr--;
}

void
SInt32ToUInt32(const SInt32* inPtr, UInt32* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (UInt32)*inPtr++;
}

void
SInt32ToUnsignedShort(const SInt32* inPtr, unsigned short* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (unsigned short)(*inPtr++);
}

void
SInt32ToUnsignedByte(const SInt32* inPtr, unsigned char* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (unsigned char)(*inPtr++);
}

/*	ConvertSInt32(src, dest, numValues, destFormat, destBytes)

	Returns -1 if no conversion needed or 0 otherwise.

	Thread Safety: ConvertSInt32 is thread-safe. It can be called from any thread.
*/
int
ConvertSInt32(const SInt32* src, void* dest, CountInt numValues, int destFormat, int destBytes)
{
	int result = 0;
	
	switch (destFormat) {
		case IEEE_FLOAT:
			switch (destBytes) {
				case 8:
					SInt32ToDouble(src, (double*)dest, numValues);
					break;
				
				case 4:
					SInt32ToFloat(src, (float*)dest, numValues);
					break;
			}
			break;
		
		case SIGNED_INT:
			switch (destBytes) {
				case 8:
					SInt32ToSInt64(src, (SInt64*)dest, numValues);
					break;
				
				case 4:
					if (src != dest)
						memcpy((char*)dest, (char*)src, destBytes*numValues);
					result = -1;
					break;
				
				case 2:
					SInt32ToShort(src, (short*)dest, numValues);
					break;
				
				case 1:
					SInt32ToByte(src, (char*)dest, numValues);
					break;
			}
			break;
	
		case UNSIGNED_INT:
			switch (destBytes) {
				case 8:
					SInt32ToUInt64(src, (UInt64*)dest, numValues);
					break;
				
				case 4:
					SInt32ToUInt32(src, (UInt32*)dest, numValues);
					break;
				
				case 2:
					SInt32ToUnsignedShort(src, (unsigned short*)dest, numValues);
					break;
				
				case 1:
					SInt32ToUnsignedByte(src, (unsigned char*)dest, numValues);
					break;
			}
			break;
	}
	return result;
}


// Conversion from Short.

void
ShortToDouble(const short* inPtr, double* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (double)*inPtr--;
}

void
ShortToFloat(const short* inPtr, float* outPtr, CountInt numValues)			// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (float)*inPtr--;
}

void
ShortToSInt64(const short* inPtr, SInt64* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (SInt64)*inPtr--;
}

void
ShortToSInt32(const short* inPtr, SInt32* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (SInt32)*inPtr--;
}

void
ShortToByte(const short* inPtr, char* outPtr, CountInt numValues)			// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (char)(*inPtr++);
}

void
ShortToUInt64(const short* inPtr, UInt64* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (UInt64)*inPtr--;
}

void
ShortToUInt32(const short* inPtr, UInt32* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (UInt32)*inPtr--;
}

void
ShortToUnsignedShort(const short* inPtr, unsigned short* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (unsigned short)*inPtr++;
}

void
ShortToUnsignedByte(const short* inPtr, unsigned char* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (unsigned char)(*inPtr++);
}

/*	ConvertShort(src, dest, numValues, destFormat, destBytes)

	Returns -1 if no conversion needed or 0 otherwise.

	Thread Safety: ConvertShort is thread-safe. It can be called from any thread.
*/
int
ConvertShort(const short* src, void* dest, CountInt numValues, int destFormat, int destBytes)
{
	int result = 0;
	
	switch (destFormat) {
		case IEEE_FLOAT:
			switch (destBytes) {
				case 8:
					ShortToDouble(src, (double*)dest, numValues);
					break;
				
				case 4:
					ShortToFloat(src, (float*)dest, numValues);
					break;
			}
			break;
		
		case SIGNED_INT:
			switch (destBytes) {
				case 8:
					ShortToSInt64(src, (SInt64*)dest, numValues);
					break;
				
				case 4:
					ShortToSInt32(src, (SInt32*)dest, numValues);
					break;
				
				case 2:
					if (src != dest)
						memcpy((char*)dest, (char*)src, destBytes*numValues);
					result = -1;
					break;
				
				case 1:
					ShortToByte(src, (char*)dest, numValues);
					break;
			}
			break;
	
		case UNSIGNED_INT:
			switch (destBytes) {
				case 8:
					ShortToUInt64(src, (UInt64*)dest, numValues);
					break;
				
				case 4:
					ShortToUInt32(src, (UInt32*)dest, numValues);
					break;
				
				case 2:
					ShortToUnsignedShort(src, (unsigned short*)dest, numValues);
					break;
				
				case 1:
					ShortToUnsignedByte(src, (unsigned char*)dest, numValues);
					break;
			}
			break;
	}
	return result;
}


// Conversion from Byte.

void
ByteToDouble(const char* inPtr, double* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (double)*inPtr--;
}

void
ByteToFloat(const char* inPtr, float* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;
	
	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (float)*inPtr--;
}

void
ByteToSInt64(const char* inPtr, SInt64* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (SInt64)*inPtr--;
}

void
ByteToSInt32(const char* inPtr, SInt32* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (SInt32)*inPtr--;
}

void
ByteToShort(const char* inPtr, short* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (short)*inPtr--;
}

void
ByteToUInt64(const char* inPtr, UInt64* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (UInt64)*inPtr--;
}

void
ByteToUInt32(const char* inPtr, UInt32* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (UInt32)*inPtr--;
}

void
ByteToUnsignedShort(const char* inPtr, unsigned short* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (unsigned short)*inPtr--;
}

void
ByteToUnsignedByte(const char* inPtr, unsigned char* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (unsigned char)*inPtr++;
}

/*	ConvertByte(src, dest, numValues, destFormat, destBytes)

	Returns -1 if no conversion needed or 0 otherwise.

	Thread Safety: ConvertByte is thread-safe. It can be called from any thread.
*/
int
ConvertByte(const char* src, void* dest, CountInt numValues, int destFormat, int destBytes)
{
	int result = 0;
	
	switch (destFormat) {
		case IEEE_FLOAT:
			switch (destBytes) {
				case 8:
					ByteToDouble(src, (double*)dest, numValues);
					break;
				
				case 4:
					ByteToFloat(src, (float*)dest, numValues);
					break;
			}
			break;
		
		case SIGNED_INT:
			switch (destBytes) {
				case 8:
					ByteToSInt64(src, (SInt64*)dest, numValues);
					break;
				
				case 4:
					ByteToSInt32(src, (SInt32*)dest, numValues);
					break;
				
				case 2:
					ByteToShort(src, (short*)dest, numValues);
					break;
				
				case 1:
					if (src != dest)
						memcpy((char*)dest, (char*)src, destBytes*numValues);
					result = -1;
					break;
			}
			break;
	
		case UNSIGNED_INT:
			switch (destBytes) {
				case 8:
					ByteToUInt64(src, (UInt64*)dest, numValues);
					break;
				
				case 4:
					ByteToUInt32(src, (UInt32*)dest, numValues);
					break;
				
				case 2:
					ByteToUnsignedShort(src, (unsigned short*)dest, numValues);
					break;
				
				case 1:
					ByteToUnsignedByte(src, (unsigned char*)dest, numValues);
					break;
			}
			break;
	}
	return result;
}


// Conversion from UInt64.

void
UInt64ToDouble(const UInt64* inPtr, double* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (double)(*inPtr++);
}

void
UInt64ToFloat(const UInt64* inPtr, float* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (float)(*inPtr++);
}

void	// UInt64ToSInt64 conflicts with an Apple macro
WMUInt64ToSInt64(const UInt64* inPtr, SInt64* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (SInt64)*inPtr++;
}

void
UInt64ToSInt32(const UInt64* inPtr, SInt32* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (SInt32)*inPtr++;
}

void
UInt64ToShort(const UInt64* inPtr, short* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (short)(*inPtr++);
}

void
UInt64ToByte(const UInt64* inPtr, char* outPtr, CountInt numValues)			// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (char)(*inPtr++);
}

void
UInt64ToUInt32(const UInt64* inPtr, UInt32* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (UInt32)*inPtr++;
}

void
UInt64ToUnsignedShort(const UInt64* inPtr, unsigned short* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (unsigned short)(*inPtr++);
}

void
UInt64ToUnsignedByte(const UInt64* inPtr, unsigned char* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (unsigned char)(*inPtr++);
}

/*	ConvertUInt64(src, dest, numValues, destFormat, destBytes)

	Returns -1 if no conversion needed or 0 otherwise.

	Thread Safety: ConvertUInt64 is thread-safe. It can be called from any thread.
*/
int
ConvertUInt64(const UInt64* src, void* dest, CountInt numValues, int destFormat, int destBytes)
{
	int result = 0;
	
	switch (destFormat) {
		case IEEE_FLOAT:
			switch (destBytes) {
				case 8:
					UInt64ToDouble(src, (double*)dest, numValues);
					break;
				
				case 4:
					UInt64ToFloat(src, (float*)dest, numValues);
					break;
			}
			break;
		
		case SIGNED_INT:
			switch (destBytes) {
				case 8:
					WMUInt64ToSInt64(src, (SInt64*)dest, numValues);
					break;
				
				case 4:
					UInt64ToSInt32(src, (SInt32*)dest, numValues);
					break;
				
				case 2:
					UInt64ToShort(src, (short*)dest, numValues);
					break;
				
				case 1:
					UInt64ToByte(src, (char*)dest, numValues);
					break;
			}
			break;
	
		case UNSIGNED_INT:
			switch (destBytes) {
				case 8:
					if (src != dest)
						memcpy((char*)dest, (char*)src, destBytes*numValues);
					result = -1;
					break;
				
				case 4:
					UInt64ToUInt32(src, (UInt32*)dest, numValues);
					break;
				
				case 2:
					UInt64ToUnsignedShort(src, (unsigned short*)dest, numValues);
					break;
				
				case 1:
					UInt64ToUnsignedByte(src, (unsigned char*)dest, numValues);
					break;
			}
			break;
	}
	return result;
}


// Conversion from UInt32.

void
UInt32ToDouble(const UInt32* inPtr, double* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (double)*inPtr--;
}

void
UInt32ToFloat(const UInt32* inPtr, float* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (float)(*inPtr++);
}

void
UInt32ToSInt64(const UInt32* inPtr, SInt64* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (SInt64)*inPtr--;
}

void
UInt32ToSInt32(const UInt32* inPtr, SInt32* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (SInt32)*inPtr++;
}

void
UInt32ToShort(const UInt32* inPtr, short* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (short)(*inPtr++);
}

void
UInt32ToByte(const UInt32* inPtr, char* outPtr, CountInt numValues)			// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (char)(*inPtr++);
}

void
UInt32ToUInt64(const UInt32* inPtr, UInt64* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (UInt64)*inPtr--;
}

void
UInt32ToUnsignedShort(const UInt32* inPtr, unsigned short* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (unsigned short)(*inPtr++);
}

void
UInt32ToUnsignedByte(const UInt32* inPtr, unsigned char* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (unsigned char)(*inPtr++);
}

/*	ConvertUInt32(src, dest, numValues, destFormat, destBytes)

	Returns -1 if no conversion needed or 0 otherwise.

	Thread Safety: ConvertUInt32 is thread-safe. It can be called from any thread.
*/
int
ConvertUInt32(const UInt32* src, void* dest, CountInt numValues, int destFormat, int destBytes)
{
	int result = 0;
	
	switch (destFormat) {
		case IEEE_FLOAT:
			switch (destBytes) {
				case 8:
					UInt32ToDouble(src, (double*)dest, numValues);
					break;
				
				case 4:
					UInt32ToFloat(src, (float*)dest, numValues);
					break;
			}
			break;
		
		case SIGNED_INT:
			switch (destBytes) {
				case 8:
					UInt32ToSInt64(src, (SInt64*)dest, numValues);
					break;
				
				case 4:
					UInt32ToSInt32(src, (SInt32*)dest, numValues);
					break;
				
				case 2:
					UInt32ToShort(src, (short*)dest, numValues);
					break;
				
				case 1:
					UInt32ToByte(src, (char*)dest, numValues);
					break;
			}
			break;
	
		case UNSIGNED_INT:
			switch (destBytes) {
				case 8:
					UInt32ToUInt64(src, (UInt64*)dest, numValues);
					break;
				
				case 4:
					if (src != dest)
						memcpy((char*)dest, (char*)src, destBytes*numValues);
					result = -1;
					break;
				
				case 2:
					UInt32ToUnsignedShort(src, (unsigned short*)dest, numValues);
					break;
				
				case 1:
					UInt32ToUnsignedByte(src, (unsigned char*)dest, numValues);
					break;
			}
			break;
	}
	return result;
}


// Conversion from Unsigned Short.

void
UnsignedShortToDouble(const unsigned short* inPtr, double* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (double)*inPtr--;
}

void
UnsignedShortToFloat(const unsigned short* inPtr, float* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (float)*inPtr--;
}

void
UnsignedShortToSInt64(const unsigned short* inPtr, SInt64* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (SInt64)*inPtr--;
}

void
UnsignedShortToSInt32(const unsigned short* inPtr, SInt32* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (SInt32)*inPtr--;
}

void
UnsignedShortToShort(const unsigned short* inPtr, short* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (short)*inPtr++;
}

void
UnsignedShortToByte(const unsigned short* inPtr, char* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (char)(*inPtr++);
}

void
UnsignedShortToUInt64(const unsigned short* inPtr, UInt64* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (UInt64)*inPtr--;
}

void
UnsignedShortToUInt32(const unsigned short* inPtr, UInt32* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (UInt32)*inPtr--;
}

void
UnsignedShortToUnsignedByte(const unsigned short* inPtr, unsigned char* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (unsigned char)(*inPtr++);
}

/*	ConvertUnsignedShort(src, dest, numValues, destFormat, destBytes)

	Returns -1 if no conversion needed or 0 otherwise.

	Thread Safety: ConvertUnsignedShort is thread-safe. It can be called from any thread.
*/
int
ConvertUnsignedShort(const unsigned short* src, void* dest, CountInt numValues, int destFormat, int destBytes)
{
	int result = 0;
	
	switch (destFormat) {
		case IEEE_FLOAT:
			switch (destBytes) {
				case 8:
					UnsignedShortToDouble(src, (double*)dest, numValues);
					break;
				
				case 4:
					UnsignedShortToFloat(src, (float*)dest, numValues);
					break;
			}
			break;
		
		case SIGNED_INT:
			switch (destBytes) {
				case 8:
					UnsignedShortToSInt64(src, (SInt64*)dest, numValues);
					break;
				
				case 4:
					UnsignedShortToSInt32(src, (SInt32*)dest, numValues);
					break;
				
				case 2:
					UnsignedShortToShort(src, (short*)dest, numValues);
					break;
				
				case 1:
					UnsignedShortToByte(src, (char*)dest, numValues);
					break;
			}
			break;
	
		case UNSIGNED_INT:
			switch (destBytes) {
				case 8:
					UnsignedShortToUInt64(src, (UInt64*)dest, numValues);
					break;
				
				case 4:
					UnsignedShortToUInt32(src, (UInt32*)dest, numValues);
					break;
				
				case 2:
					if (src != dest)
						memcpy((char*)dest, (char*)src, destBytes*numValues);
					result = -1;
					break;
				
				case 1:
					UnsignedShortToUnsignedByte(src, (unsigned char*)dest, numValues);
					break;
			}
			break;
	}
	return result;
}


// Conversion from Unsigned Byte.

void
UnsignedByteToDouble(const unsigned char* inPtr, double* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (double)*inPtr--;
}

void
UnsignedByteToFloat(const unsigned char* inPtr, float* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;
	
	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (float)*inPtr--;
}

void
UnsignedByteToSInt64(const unsigned char* inPtr, SInt64* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (SInt64)*inPtr--;
}

void
UnsignedByteToSInt32(const unsigned char* inPtr, SInt32* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (SInt32)*inPtr--;
}

void
UnsignedByteToShort(const unsigned char* inPtr, short* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (short)*inPtr--;
}

void
UnsignedByteToByte(const unsigned char* inPtr, char* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++)
		*outPtr++ = (char)*inPtr++;
}

void
UnsignedByteToUInt64(const unsigned char* inPtr, UInt64* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (UInt64)*inPtr--;
}

void
UnsignedByteToUInt32(const unsigned char* inPtr, UInt32* outPtr, CountInt numValues)	// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (UInt32)*inPtr--;
}

void
UnsignedByteToUnsignedShort(const unsigned char* inPtr, unsigned short* outPtr, CountInt numValues)		// Thread-safe
{
	CountInt p;

	inPtr += numValues-1;				// Start from the end of the data.
	outPtr += numValues-1;

	for (p = numValues; p > 0; p--)
		*outPtr-- = (unsigned short)*inPtr--;
}

/*	ConvertUnsignedByte(src, dest, numValues, destFormat, destBytes)

	Returns -1 if no conversion needed or 0 otherwise.

	Thread Safety: ConvertUnsignedByte is thread-safe. It can be called from any thread.
*/
int
ConvertUnsignedByte(const unsigned char* src, void* dest, CountInt numValues, int destFormat, int destBytes)
{
	int result = 0;
	
	switch (destFormat) {
		case IEEE_FLOAT:
			switch (destBytes) {
				case 8:
					UnsignedByteToDouble(src, (double*)dest, numValues);
					break;
				
				case 4:
					UnsignedByteToFloat(src, (float*)dest, numValues);
					break;
			}
			break;
		
		case SIGNED_INT:
			switch (destBytes) {
				case 8:
					UnsignedByteToSInt64(src, (SInt64*)dest, numValues);
					break;
				
				case 4:
					UnsignedByteToSInt32(src, (SInt32*)dest, numValues);
					break;
				
				case 2:
					UnsignedByteToShort(src, (short*)dest, numValues);
					break;
				
				case 1:
					UnsignedByteToByte(src, (char*)dest, numValues);
					break;
			}
			break;
	
		case UNSIGNED_INT:
			switch (destBytes) {
				case 8:
					UnsignedByteToUInt64(src, (UInt64*)dest, numValues);
					break;
				
				case 4:
					UnsignedByteToUInt32(src, (UInt32*)dest, numValues);
					break;
				
				case 2:
					UnsignedByteToUnsignedShort(src, (unsigned short*)dest, numValues);
					break;
				
				case 1:
					if (src != dest)
						memcpy((char*)dest, (char*)src, destBytes*numValues);
					result = -1;
					break;
			}
			break;
	}
	return result;
}

/*	FixByteOrder(p, bytesPerPoint, numValues)

	Reverses byte order.

	Thread Safety: FixByteOrder is thread-safe. It can be called from any thread.
*/
void
FixByteOrder(void* p, int bytesPerPoint, CountInt numValues)
{
	unsigned char ch, *p1, *p2, *pEnd;
	
	pEnd = (unsigned char *)p + numValues*bytesPerPoint;
	while (p < (void*)pEnd) {
		p1 = (unsigned char *)p;
		p2 = (unsigned char *)p + bytesPerPoint-1;
		while (p1 < p2) {
			ch = *p1;
			*p1++ = *p2;
			*p2-- = ch;
		}
		p = (unsigned char *)p + bytesPerPoint;
	}
}

/*	ConvertData(src, dest, numValues, srcBytes, srcFormat, destBytes, destFormat)

	Converts data between various formats.
	It uses the math coprocessor if it is present.
	All combinations of the following data types are supported:
		double, float
		int64, int32, int16, int8
		unsigned int64, unsigned int32, unsigned int16, unsigned int8
	
	Returns
		zero if everything is OK
		1 if conversion not supported (typically caused by an invalid parameter)
		-1 if no conversion is needed (source format == dest format). 
	
	src is a pointer to the data to convert.

	dest is a pointer to where the converted data should go.

	numValues is the number of data values to be converted.

	srcBytes is the number of bytes per point in the source data:
		1, 2, 4, or 8

	srcFormat is the numeric format of the source data:
		1 = signed integer, 2 = unsigned integer, 3 = IEEE floating point.

	destBytes is the number of bytes per point in the destination data:
		1, 2, 4, or 8

	destFormat is the numeric format of the destination data:
		SIGNED_INT, UNSIGNED_INT, IEEE_FLOAT
	
	The source and destination can point to the same array of numbers but ONLY IF the
	array is big enough to hold all of the data in the destination format.
	
	Thread Safety: ConvertData is thread-safe. It can be called from any thread.
*/
int
ConvertData(const void* src, void* dest, CountInt numValues, int srcBytes, int srcFormat, int destBytes, int destFormat)
{
	int result=0;
	
	// make sure src and dest formats valid.
	
	if (srcBytes!=1 && srcBytes!=2 && srcBytes!=4 && srcBytes!=8)
		return(1);
	if (srcFormat<SIGNED_INT || srcFormat>IEEE_FLOAT)
		return(1);
	
	if (destBytes!=1 && destBytes!=2 && destBytes!=4 && destBytes!=8)
		return(1);
	if (destFormat<SIGNED_INT || destFormat>IEEE_FLOAT)
		return(1);
	
	switch(srcFormat) {
		case IEEE_FLOAT:
			if (srcBytes < 4)
				return 1;
			break;
		case SIGNED_INT:
		case UNSIGNED_INT:
			// srcBytes was tested above
			break;
	}
	
	switch(destFormat) {
		case IEEE_FLOAT:
			if (destBytes < 4)
				return 1;
			break;
		case SIGNED_INT:
		case UNSIGNED_INT:
			// srcBytes was tested above
			break;
	}
	
	switch (srcFormat) {
		case IEEE_FLOAT:
			switch (srcBytes) {
				case 8:
					result = ConvertDouble((double*)src, dest, numValues, destFormat, destBytes);
					break;
				
				case 4:
					result = ConvertFloat((float*)src, dest, numValues, destFormat, destBytes);
					break;
			}
			break;
		
		case SIGNED_INT:
			switch (srcBytes) {
				case 8:
					result = ConvertSInt64((SInt64*)src, dest, numValues, destFormat, destBytes);
					break;

				case 4:
					result = ConvertSInt32((SInt32*)src, dest, numValues, destFormat, destBytes);
					break;
				
				case 2:
					result = ConvertShort((short*)src, dest, numValues, destFormat, destBytes);
					break;
				
				case 1:
					result = ConvertByte((char*)src, dest, numValues, destFormat, destBytes);
					break;
			}
			break;
	
		case UNSIGNED_INT:
			switch (srcBytes) {
				case 8:
					result = ConvertUInt64((UInt64*)src, dest, numValues, destFormat, destBytes);
					break;
				
				case 4:
					result = ConvertUInt32((UInt32*)src, dest, numValues, destFormat, destBytes);
					break;
				
				case 2:
					result = ConvertUnsignedShort((unsigned short*)src, dest, numValues, destFormat, destBytes);
					break;
				
				case 1:
					result = ConvertUnsignedByte((unsigned char*)src, dest, numValues, destFormat, destBytes);
					break;
			}
			break;
	}
		
	return(result);
}

/*	ConvertData2(src, dest, numValues, srcDataType, destDataType)

	This does the same thing as ConvertData (see above) except that it
	takes the standard Igor number type codes as parameters. These are
		NT_FP64, NT_FP32
		NT_I64, NT_I32, NT_I16, NT_I8
		NT_I32 | NT_UNSIGNED, NT_I16 | NT_UNSIGNED, NT_I8 | NT_UNSIGNED

	The number type should NOT include NT_CMPLX. If the data is complex,
	the numValues parameter should reflect that.
	
	See ConvertData above for a description of the return value and for other comments.
	
	Thread Safety: ConvertData2 is thread-safe. It can be called from any thread.
*/
int
ConvertData2(const void* src, void* dest, CountInt numValues, int srcDataType, int destDataType)
{
	int srcNumBytesPerPoint, srcDataFormat, srcIsComplex;
	int destNumBytesPerPoint, destDataFormat, destIsComplex;
	
	if (NumTypeToNumBytesAndFormat(srcDataType, &srcNumBytesPerPoint, &srcDataFormat, &srcIsComplex))
		return 1;			// Conversion not supported.
	if (srcIsComplex)
		return 1;			// See note about complex above.
	
	if (NumTypeToNumBytesAndFormat(destDataType, &destNumBytesPerPoint, &destDataFormat, &destIsComplex))
		return 1;			// Conversion not supported.
	if (destIsComplex)
		return 1;			// See note about complex above.

	return ConvertData(src, dest, numValues, srcNumBytesPerPoint, srcDataFormat, destNumBytesPerPoint, destDataFormat);
}


// Scaling.

void
ScaleDouble(double* dPtr, double* offset, double* multiplier, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++) {
		*dPtr = (*dPtr + *offset) * *multiplier;
		dPtr++;
	}
}

void
ScaleFloat(float* fPtr, double* offset, double* multiplier, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++) {
		*fPtr = (float)((*fPtr + *offset) * *multiplier);
		fPtr++;
	}
}

/*	ScaleSInt64 is subject to inaccuracies for values exceeding 2^53 in magnitude
	because calculations are done in double-precision and double-precision can not
	precisely represent the full range of 64-integer values. See "64-bit Integer Issues"
	in the XOP Toolkit manual for further discussion.
*/
void
ScaleSInt64(SInt64* iPtr, double* offset, double* multiplier, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++) {
		*iPtr = (SInt64)((*iPtr + *offset) * *multiplier);
		iPtr++;
	}
}

void
ScaleSInt32(SInt32* iPtr, double* offset, double* multiplier, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++) {
		*iPtr = (SInt32)((*iPtr + *offset) * *multiplier);
		iPtr++;
	}
}

void
ScaleShort(short *sPtr, double* offset, double* multiplier, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++) {
		*sPtr = (short)((*sPtr + *offset) * *multiplier);
		sPtr++;
	}
}

void
ScaleByte(char* cPtr, double* offset, double* multiplier, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++) {
		*cPtr = (char)((*cPtr + *offset) * *multiplier);
		cPtr++;
	}
}

/*	ScaleUInt64 is subject to inaccuracies for values exceeding 2^53 in magnitude
	because calculations are done in double-precision and double-precision can not
	precisely represent the full range of 64-integer values. See "64-bit Integer Issues"
	in the XOP Toolkit manual for further discussion.
*/
void
ScaleUInt64(UInt64* iPtr, double* offset, double* multiplier, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++) {
		*iPtr = (UInt64)((*iPtr + *offset) * *multiplier);
		iPtr++;
	}
}

void
ScaleUInt32(UInt32* iPtr, double* offset, double* multiplier, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++) {
		*iPtr = (UInt32)((*iPtr + *offset) * *multiplier);
		iPtr++;
	}
}

void
ScaleUnsignedShort(unsigned short* sPtr, double* offset, double *multiplier, CountInt numValues)	// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++) {
		*sPtr = (unsigned short)((*sPtr + *offset) * *multiplier);
		sPtr++;
	}
}

void
ScaleUnsignedByte(unsigned char* cPtr, double* offset, double *multiplier, CountInt numValues)		// Thread-safe
{
	CountInt p;

	for (p = 0; p < numValues; p++) {
		*cPtr = (unsigned char)((*cPtr + *offset) * *multiplier);
		cPtr++;
	}
}

/*	ScaleData(dataType, dataPtr, offsetPtr, multiplierPtr, numValues)

	Scales the data pointed to by dataPtr by adding the offset and multiplying
	by the multiplier.
	
	dataType is one of the Igor numeric type codes defined in IgorXOP.h.
	The NT_CMPLX bit should NOT be set. If the data is complex, this
	should be reflected in the numValues parameter.
	
	All calculations are done in double precision.
	
	Scaling of signed and unsigned 64-bit integer values is subject to inaccuracies
	for values exceeding 2^53 in magnitude because calculations are done in double-precision
	and double-precision can not precisely represent the full range of 64-integer values.
	In evaluating the result, if any value exceeds 2^53 in magnitude, the result is undefined.
	See "64-bit Integer Issues" in the XOP Toolkit manual for further discussion.
	
	Thread Safety: ScaleData is thread-safe. It can be called from any thread.
*/
void
ScaleData(int dataType, void* dataPtr, double* offsetPtr, double* multiplierPtr, CountInt numValues)
{
	if (*offsetPtr==0.0 && *multiplierPtr==1.0)
		return;			// No need to scale.
	
	switch(dataType) {
		case NT_FP64:
			ScaleDouble((double*)dataPtr, offsetPtr, multiplierPtr, numValues);
			break;
		case NT_FP32:
			ScaleFloat((float*)dataPtr, offsetPtr, multiplierPtr, numValues);
			break;
		case NT_I64:						// Added in Igor Pro 7.00
			ScaleSInt64((SInt64*)dataPtr, offsetPtr, multiplierPtr, numValues);
			break;
		case NT_I32:
			ScaleSInt32((SInt32*)dataPtr, offsetPtr, multiplierPtr, numValues);
			break;
		case NT_I16:
			ScaleShort((short*)dataPtr, offsetPtr, multiplierPtr, numValues);
			break;
		case NT_I8:
			ScaleByte((char*)dataPtr, offsetPtr, multiplierPtr, numValues);
			break;
		case NT_I64 | NT_UNSIGNED:			// Added in Igor Pro 7.00
			ScaleUInt64((UInt64*)dataPtr, offsetPtr, multiplierPtr, numValues);
			break;
		case NT_I32 | NT_UNSIGNED:
			ScaleUInt32((UInt32*)dataPtr, offsetPtr, multiplierPtr, numValues);
			break;
		case NT_I16 | NT_UNSIGNED:
			ScaleUnsignedShort((unsigned short*)dataPtr, offsetPtr, multiplierPtr, numValues);
			break;
		case NT_I8 | NT_UNSIGNED:
			ScaleUnsignedByte((unsigned char*)dataPtr, offsetPtr, multiplierPtr, numValues);
			break;
	}
}


static double
dround(double x)		// Thread-safe
{
	return (x<0) ? ceil(x-0.5) : floor(x+0.5);
}

static void
ScaleClipAndRoundDouble(double* dPtr, CountInt numValues, double offset, double multiplier, double dMin, double dMax, int doScale, int doClip, int doRound)	// Thread-safe
{
	CountInt p;
	double val;

	for (p = 0; p < numValues; p++) {
		val = *dPtr;
		
		if (doScale)
			val = (val + offset) * multiplier;

		if (doClip) {
			if (val < dMin)
				val = dMin;
			if (val > dMax)
				val = dMax;
		}
		
		if (doRound)
			val = dround(val);
			
		*dPtr = val;
		dPtr++;
	}
}

static void
ScaleClipAndRoundFloat(float* fPtr, CountInt numValues, double offset, double multiplier, double dMin, double dMax, int doScale, int doClip, int doRound)	// Thread-safe
{
	CountInt p;
	double val;

	for (p = 0; p < numValues; p++) {
		val = *fPtr;
		
		if (doScale)
			val = (val + offset) * multiplier;

		if (doClip) {
			if (val < dMin)
				val = dMin;
			if (val > dMax)
				val = dMax;
		}
		
		if (doRound)
			val = dround(val);
			
		*fPtr = (float)val;
		fPtr++;
	}
}

static void
ScaleClipAndRoundSInt64(SInt64* iPtr, CountInt numValues, double offset, double multiplier, double dMin, double dMax, int doScale, int doClip, int doRound)	// Thread-safe
{
	CountInt p;
	double val;

	for (p = 0; p < numValues; p++) {
		val = (double)*iPtr;
		
		if (doScale)
			val = (val + offset) * multiplier;

		if (doClip) {
			if (val < dMin)
				val = dMin;
			if (val > dMax)
				val = dMax;
		}
		
		if (doRound)
			val = dround(val);
			
		*iPtr = (SInt64)val;
		iPtr++;
	}
}

static void
ScaleClipAndRoundSInt32(SInt32* iPtr, CountInt numValues, double offset, double multiplier, double dMin, double dMax, int doScale, int doClip, int doRound)	// Thread-safe
{
	CountInt p;
	double val;

	for (p = 0; p < numValues; p++) {
		val = *iPtr;
		
		if (doScale)
			val = (val + offset) * multiplier;

		if (doClip) {
			if (val < dMin)
				val = dMin;
			if (val > dMax)
				val = dMax;
		}
		
		if (doRound)
			val = dround(val);
			
		*iPtr = (SInt32)val;
		iPtr++;
	}
}

static void
ScaleClipAndRoundShort(short* sPtr, CountInt numValues, double offset, double multiplier, double dMin, double dMax, int doScale, int doClip, int doRound)	// Thread-safe
{
	CountInt p;
	double val;

	for (p = 0; p < numValues; p++) {
		val = *sPtr;
		
		if (doScale)
			val = (val + offset) * multiplier;

		if (doClip) {
			if (val < dMin)
				val = dMin;
			if (val > dMax)
				val = dMax;
		}
		
		if (doRound)
			val = dround(val);
			
		*sPtr = (short)val;
		sPtr++;
	}
}

static void
ScaleClipAndRoundByte(char* cPtr, CountInt numValues, double offset, double multiplier, double dMin, double dMax, int doScale, int doClip, int doRound)	// Thread-safe
{
	CountInt p;
	double val;

	for (p = 0; p < numValues; p++) {
		val = *cPtr;
		
		if (doScale)
			val = (val + offset) * multiplier;

		if (doClip) {
			if (val < dMin)
				val = dMin;
			if (val > dMax)
				val = dMax;
		}
		
		if (doRound)
			val = dround(val);
			
		*cPtr = (char)val;
		cPtr++;
	}
}

static void
ScaleClipAndRoundUInt64(UInt64* iPtr, CountInt numValues, double offset, double multiplier, double dMin, double dMax, int doScale, int doClip, int doRound)	// Thread-safe
{
	CountInt p;
	double val;

	for (p = 0; p < numValues; p++) {
		val = (double)*iPtr;
		
		if (doScale)
			val = (val + offset) * multiplier;

		if (doClip) {
			if (val < dMin)
				val = dMin;
			if (val > dMax)
				val = dMax;
		}
		
		if (doRound)
			val = dround(val);
			
		*iPtr = (UInt64)val;
		iPtr++;
	}
}

static void
ScaleClipAndRoundUInt32(UInt32* iPtr, CountInt numValues, double offset, double multiplier, double dMin, double dMax, int doScale, int doClip, int doRound)	// Thread-safe
{
	CountInt p;
	double val;

	for (p = 0; p < numValues; p++) {
		val = *iPtr;
		
		if (doScale)
			val = (val + offset) * multiplier;

		if (doClip) {
			if (val < dMin)
				val = dMin;
			if (val > dMax)
				val = dMax;
		}
		
		if (doRound)
			val = dround(val);
			
		*iPtr = (UInt32)val;
		iPtr++;
	}
}

static void
ScaleClipAndRoundUnsignedShort(unsigned short* sPtr, CountInt numValues, double offset, double multiplier, double dMin, double dMax, int doScale, int doClip, int doRound)	// Thread-safe
{
	CountInt p;
	double val;

	for (p = 0; p < numValues; p++) {
		val = *sPtr;
		
		if (doScale)
			val = (val + offset) * multiplier;

		if (doClip) {
			if (val < dMin)
				val = dMin;
			if (val > dMax)
				val = dMax;
		}
		
		if (doRound)
			val = dround(val);
			
		*sPtr = (unsigned short)val;
		sPtr++;
	}
}

static void
ScaleClipAndRoundUnsignedByte(unsigned char* cPtr, CountInt numValues, double offset, double multiplier, double dMin, double dMax, int doScale, int doClip, int doRound)	// Thread-safe
{
	CountInt p;
	double val;

	for (p = 0; p < numValues; p++) {
		val = *cPtr;
		
		if (doScale)
			val = (val + offset) * multiplier;

		if (doClip) {
			if (val < dMin)
				val = dMin;
			if (val > dMax)
				val = dMax;
		}
		
		if (doRound)
			val = dround(val);
			
		*cPtr = (unsigned char)val;
		cPtr++;
	}
}

/*	ScaleClipAndRoundData(dataType, dataPtr, numValues, offset, multiplier, dMin, dMax, doRound)
	
	dataType is one of the Igor numeric type codes defined in IgorXOP.h.
	The NT_CMPLX bit should NOT be set. If the data is complex, this
	should be reflected in the numValues parameter.

	Scales the data pointed to by dataPtr by adding the offset and multiplying
	by the multiplier. If offset is 0.0 and multiplier is 1.0, no scaling is done.
	
	Clips to the specified min and max. If min is -INF and max is +INF, no clipping is done.
	
	If min and max are both zero, integer data is clipped to the minimum and maximum values
	that can be represented by the data type except for signed and unsigned 64-bit integer.
	The largest integer value that can be precisely represented in double-precision floating
	point is 2^53 = 9007199254740992. For signed 64-bit integer (NT_I64), the minimum is
	-9007199254740992 and the maximum is 9007199254740992. For unsigned 64-bit integer
	(NT_I64 | NT_UNSIGNED), the minimum is 0 and the maximum is 9007199254740992.
	
	If doRound is non-zero, the data is rounded to the nearest integer.
	
	All calculations are done in double precision.
	
	Scaling of signed and unsigned 64-bit integer values is subject to inaccuracies
	for values exceeding 2^53 in magnitude because calculations are done in double-precision
	and double-precision can not precisely represent the full range of 64-integer values.
	In evaluating the result, if any value exceeds 2^53 in magnitude, the result is undefined.
	See "64-bit Integer Issues" in the XOP Toolkit manual for further discussion.
	
	Thread Safety: ScaleClipAndRoundData is thread-safe. It can be called from any thread.
*/
void
ScaleClipAndRoundData(int dataType, void* dataPtr, CountInt numValues, double offset, double multiplier, double dMin, double dMax, int doRound)
{
	int doScale, doClip;
	
	doScale = 1;
	if (offset==0.0 && multiplier==1.0)
		doScale = 0;
	
	doClip = 1;
	if (dMin<0 && IsINF64(&dMin)) {
		if (dMax>0 && IsINF64(&dMax))
			doClip = 0;
	}
		
	if (dMin==0.0 && dMax==0.0) {					// This means we want to clip to the limits of the data type of the data.
		switch(dataType) {
			case NT_FP64:
				doClip = 0;							// Does not apply to floating point.
				break;

			case NT_FP32:
				doClip = 0;							// Does not apply to floating point.
				break;

			case NT_I64:							// Added in Igor Pro 7.00
				/*	The largest integer that can be precisely represented in double-precision floating point
					is 2^53 = 9007199254740992
				*/
				dMin = -9007199254740992.0;
				dMax = 9007199254740992.0;
				break;

			case NT_I32:
				dMin = -2147483648.0;
				dMax = 2147483647.0;
				break;

			case NT_I16:
				dMin = -32768.0;
				dMax = 32767.0;
				break;

			case NT_I8:
				dMin = -128.0;
				dMax = 127.0;
				break;

			case NT_I64 | NT_UNSIGNED:				// Added in Igor Pro 7.00
				/*	The largest integer that can be precisely represented in double-precision floating point
					is 2^53 = 9007199254740992
				*/
				dMin = 0.0;
				dMax = 9007199254740992.0;
				break;

			case NT_I32 | NT_UNSIGNED:
				dMin = 0.0;
				dMax = 4294967295.0;
				break;

			case NT_I16 | NT_UNSIGNED:
				dMin = 0.0;
				dMax = 65535.0;
				break;

			case NT_I8 | NT_UNSIGNED:
				dMin = 0;
				dMax = 255;
				break;
		}
	}
	
	if (!doScale && !doClip && !doRound)
		return;

	switch(dataType) {
		case NT_FP64:
			ScaleClipAndRoundDouble((double*)dataPtr, numValues, offset, multiplier, dMin, dMax, doScale, doClip, doRound);
			break;

		case NT_FP32:
			ScaleClipAndRoundFloat((float*)dataPtr, numValues, offset, multiplier, dMin, dMax, doScale, doClip, doRound);
			break;

		case NT_I64:						// Added in Igor Pro 7.00
			ScaleClipAndRoundSInt64((SInt64*)dataPtr, numValues, offset, multiplier, dMin, dMax, doScale, doClip, doRound);
			break;

		case NT_I32:
			ScaleClipAndRoundSInt32((SInt32*)dataPtr, numValues, offset, multiplier, dMin, dMax, doScale, doClip, doRound);
			break;

		case NT_I16:
			ScaleClipAndRoundShort((short*)dataPtr, numValues, offset, multiplier, dMin, dMax, doScale, doClip, doRound);
			break;

		case NT_I8:
			ScaleClipAndRoundByte((char*)dataPtr, numValues, offset, multiplier, dMin, dMax, doScale, doClip, doRound);
			break;

		case NT_I64 | NT_UNSIGNED:			// Added in Igor Pro 7.00
			ScaleClipAndRoundUInt64((UInt64*)dataPtr, numValues, offset, multiplier, dMin, dMax, doScale, doClip, doRound);
			break;

		case NT_I32 | NT_UNSIGNED:
			ScaleClipAndRoundUInt32((UInt32*)dataPtr, numValues, offset, multiplier, dMin, dMax, doScale, doClip, doRound);
			break;

		case NT_I16 | NT_UNSIGNED:
			ScaleClipAndRoundUnsignedShort((unsigned short*)dataPtr, numValues, offset, multiplier, dMin, dMax, doScale, doClip, doRound);
			break;

		case NT_I8 | NT_UNSIGNED:
			ScaleClipAndRoundUnsignedByte((unsigned char*)dataPtr, numValues, offset, multiplier, dMin, dMax, doScale, doClip, doRound);
			break;
	}
}
