#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_UTILS_NUMERIC
#endif

/// @file MIES_Utilities_Numeric.ipf
/// @brief utility functions for numerical operations

/// @brief Initializes the random number generator with a new seed between (0,1]
/// The time base is assumed to be at least 0.1 microsecond precise, so a new seed
/// is available every 0.1 microsecond.
///
/// Usage example for the case that one needs n non reproducible random numbers.
/// Whenever the following code block is executed a new seed is set, resulting in a different series of numbers
///
/// \rst
/// .. code-block:: igorpro
///
///		Make/D/N=(n) newRandoms
///		NewRandomSeed() // Initialize random number series with a new seed
///		newRandoms[] = GetReproducibleRandom() // Get n randoms from the new series
///
/// \endrst
Function NewRandomSeed()

	SetRandomSeed/BETR=1 ((stopmstimer(-2) * 10) & 0xffffffff) / 2^32 // NOLINT

End

/// @brief Return a random value in the range (0,1] which can be used as a seed for `SetRandomSeed`
///
/// Return a reproducible random number depending on the RNG seed.
threadsafe Function GetReproducibleRandom([variable noiseGenMode])
	variable randomSeed

	if(ParamIsDefault(noiseGenMode))
		noiseGenMode = NOISE_GEN_XOSHIRO
	endif

	do
		randomSeed = abs(enoise(1, noiseGenMode))
	while(randomSeed == 0)

	return randomSeed
End

/// @brief Return a unique integer
///
/// The returned values can *not* be used for statistical purposes
/// as the distribution is not uniform anymore.
Function GetUniqueInteger()
	return (GetReproducibleRandom() * 2^33) & 0xFFFFFFFF
End

/// @brief Set the given bit mask in var
threadsafe Function SetBit(var, bit)
	variable var, bit

	return var | bit
End

/// @brief Clear the given bit mask in var
threadsafe Function ClearBit(var, bit)
	variable var, bit

	return var & ~bit
End

/// @brief Count the number of ones in `value`
///
/// @param value will be truncated to an integer value
Function PopCount(value)
	variable value

	variable count

	value = trunc(value)
	do
		if(value & 1)
			count += 1
		endif
		value = trunc(value / 2^1) // shift one to the right
	while(value > 0)

	return count
End

/// @brief Return the minimum and maximum of both values
Function [variable minimum, variable maximum] MinMax(variable a, variable b)

	minimum = min(a, b)
	maximum = max(a, b)
End

/// @brief Find an integer `x` which is larger than `a` but the
/// smallest possible power of `p`.
///
/// @f$ x > a @f$ where @f$ x = c^p @f$ holds and @f$ x @f$ is
/// the smallest possible value.
threadsafe Function FindNextPower(a, p)
	variable a, p

	ASSERT_TS(p > 1, "Invalid power")
	ASSERT_TS(a > 0, "Invalid value")
	ASSERT_TS(IsInteger(a), "Value has to be an integer")

	return ceil(log(a) / log(p))
End

/// @brief Find an integer `x` which is smaller than `a` but the
/// largest possible power of `p`.
///
/// @f$ x < a @f$ where @f$ x = c^p @f$ holds and @f$ x @f$ is
/// the largest possible value.
Function FindPreviousPower(a, p)
	variable a, p

	ASSERT(p > 1, "Invalid power")
	ASSERT(a > 0, "Invalid value")
	ASSERT(IsInteger(a), "Value has to be an integer")

	return floor(log(a) / log(p))
End

/// @brief Return the alignment of the decimal number (usually a 32bit/64bit pointer)
Function GetAlignment(val)
	variable val

	variable i

	for(i = 1; i < 64; i += 1)
		if(mod(val, 2^i) != 0)
			return 2^(i - 1)
		endif
	endfor
End

/// @brief Compute the least common multiplier of two variables
Function CalculateLCM(a, b)
	variable a, b

	return (a * b) / gcd(a, b)
End

/// @brief Round the given number to the given number of decimal digits
threadsafe Function RoundNumber(variable val, variable precision)

	return str2num(num2strHighPrec(val, precision = precision))
End

/// @brief Helper structure for GenerateRFC4122UUID()
static Structure Uuid
	uint32 time_low
	uint16 time_mid
	uint16 time_hi_and_version
	uint16 clock_seq
	uint16 node0
	uint16 node1
	uint16 node2
EndStructure

/// @brief Generate a version 4 UUID according to https://tools.ietf.org/html/rfc4122
///
/// \rst
/// .. code-block:: text
///
///     4.4.  Algorithms for Creating a UUID from Truly Random or
///           Pseudo-Random Numbers
///
///        The version 4 UUID is meant for generating UUIDs from truly-random or
///        pseudo-random numbers.
///
///        The algorithm is as follows:
///
///        o  Set the two most significant bits (bits 6 and 7) of the
///           clock_seq_hi_and_reserved to zero and one, respectively.
///
///        o  Set the four most significant bits (bits 12 through 15) of the
///           time_hi_and_version field to the 4-bit version number from
///           Section 4.1.3.
///
///        o  Set all the other bits to randomly (or pseudo-randomly) chosen
///           values.
///
///     See Section 4.5 for a discussion on random numbers.
///
///     [...]
///
///      In the absence of explicit application or presentation protocol
///      specification to the contrary, a UUID is encoded as a 128-bit object,
///      as follows:
///
///      The fields are encoded as 16 octets, with the sizes and order of the
///      fields defined above, and with each field encoded with the Most
///      Significant Byte first (known as network byte order).  Note that the
///      field names, particularly for multiplexed fields, follow historical
///      practice.
///
///      0                   1                   2                   3
///       0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
///      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///      |                          time_low                             |
///      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///      |       time_mid                |         time_hi_and_version   |
///      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///      |clk_seq_hi_res |  clk_seq_low  |         node (0-1)            |
///      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///      |                         node (2-5)                            |
///      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///
///     [...]
///
///     4.1.3.  Version
///
///        The version number is in the most significant 4 bits of the time
///        stamp (bits 4 through 7 of the time_hi_and_version field).
///
///        The following table lists the currently-defined versions for this
///        UUID variant.
///
///        Msb0  Msb1  Msb2  Msb3   Version  Description
///
///         0     0     0     1        1     The time-based version
///                                          specified in this document.
///
///         0     0     1     0        2     DCE Security version, with
///                                          embedded POSIX UIDs.
///
///         0     0     1     1        3     The name-based version
///                                          specified in this document
///                                          that uses MD5 hashing.
///
///         0     1     0     0        4     The randomly or pseudo-
///                                          randomly generated version
///                                          specified in this document.
///
///         0     1     0     1        5     The name-based version
///                                          specified in this document
///                                          that uses SHA-1 hashing.
///
///        The version is more accurately a sub-type; again, we retain the term
///        for compatibility.
///
/// \endrst
///
/// See also https://www.rfc-editor.org/errata/eid3546 and https://www.rfc-editor.org/errata/eid1957
/// for some clarifications.
threadsafe Function/S GenerateRFC4122UUID()

	string str, randomness
	STRUCT Uuid uu

	randomness = Hash(num2strHighPrec(GetReproducibleRandom(), precision = 15), 1)

	WAVE binary = HexToBinary(randomness)

	uu.time_low            = binary[0] | (binary[1] << 8) | (binary[2] << 16) | (binary[3] << 24)
	uu.time_mid            = binary[4] | (binary[5] << 8)
	uu.time_hi_and_version = binary[6] | (binary[7] << 8)
	uu.clock_seq           = binary[8] | (binary[9] << 8)

	uu.node0 = binary[10] | (binary[11] << 8)
	uu.node1 = binary[12] | (binary[13] << 8)
	uu.node2 = binary[14] | (binary[15] << 8)

	// set the version
	uu.clock_seq           = (uu.clock_seq & 0x3FFF) | 0x8000
	uu.time_hi_and_version = (uu.time_hi_and_version & 0x0FFF) | 0x4000

	sprintf str, "%8.8x-%4.4x-%4.4x-%4.4x-%4.4x%4.4x%4.4x", uu.time_low, uu.time_mid, uu.time_hi_and_version, uu.clock_seq, uu.node0, uu.node1, uu.node2

	return str
End

/// @brief Given a range `[a, b]` this returns a symmetric range around zero including both elements
Function [variable minSym, variable maxSym] SymmetrizeRangeAroundZero(variable minimum, variable maximum)

	variable maxVal

	maxVal = max(abs(minimum), abs(maximum))
	return [-maxVal, +maxVal]
End

/// @brief Acts like the `limit` builtin but replaces values outside the valid range instead of clipping them
threadsafe Function LimitWithReplace(variable val, variable low, variable high, variable replacement)
	return (val >= low && val <= high) ? val : replacement
End

/// @brief Calculated the size of Base64 encoded data from the unencoded size
///
/// @param unencodedSize unencoded size
/// @returns encoded size
threadsafe Function Base64EncodeSize(variable unencodedSize)

	return (unencodedSize + 2 - mod(unencodedSize + 2, 3)) / 3 * 4
End

/// @brief Find the right most high bit
///
/// @param value integer value in the range [0, 2^64]
///
/// @return right most high bit or NaN in case nothing could be found
threadsafe Function FindRightMostHighBit(uint64 value)

	variable i
	uint64   bit

	for(i = 0; i < 64; i += 1)

		bit = value & (1 << i)

		if(bit)
			return i
		endif
	endfor

	return NaN
End

/// @brief Returns the integer result and the difference of it to the original value
threadsafe Function [variable intResult, variable rest] RoundAndDelta(variable val)

	intResult = round(val)

	return [intResult, intResult - val]
End

/// @brief Returns the integer result and the difference of it to the original value
threadsafe Function [variable intResult, variable rest] CeilAndDelta(variable val)

	intResult = ceil(val)

	return [intResult, intResult - val]
End

/// @brief Returns the integer result and the difference of it to the original value
threadsafe Function [variable intResult, variable rest] FloorAndDelta(variable val)

	intResult = floor(val)

	return [intResult, intResult - val]
End

/// @brief Returns the target index closer to zero of a given source index for a decimation in the form
///        target[] = source[round(p * decimationFactor)]
///        Note:
///          For a decimationFactor < 1 a point in source may be decimated to multiple points in target,
///          thus a resulting index in target of sourceIndex + 1 may be equal to the index retrieved for sourceindex.
///          For a decimationFactor > 1 points in source may be skipped on decimation,
///          thus a resulting index in target of sourceIndex + 1 may increase the result by more than 1.
threadsafe Function IndexAfterDecimation(variable sourceIndex, variable decimationFactor)

	ASSERT_TS(IsInteger(sourceIndex) && sourceIndex >= 0, "sourceIndex must be integer & >= 0")
	return sourceIndex == 0 ? -1 : floor((sourceIndex - 0.5) / decimationFactor)
End
