#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IgorVersion=6.3
#pragma IndependentModule=IPNWB
#pragma version=0.1

/// @file IPNWB_Utils.ipf
/// @brief Utility functions

/// @brief Returns 1 if var is a finite/normal number, 0 otherwise
///
/// @hidecallgraph
/// @hidecallergraph
Function IsFinite(var)
	variable var

	return numType(var) == 0
End

/// @brief Returns 1 if str is null, 0 otherwise
/// @param str must not be a SVAR
///
/// @hidecallgraph
/// @hidecallergraph
Function isNull(str)
	string& str

	variable len = strlen(str)
	return numtype(len) == 2
End

/// @brief Returns one if str is empty or null, zero otherwise.
/// @param str must not be a SVAR
///
/// @hidecallgraph
/// @hidecallergraph
Function isEmpty(str)
	string& str

	variable len = strlen(str)
	return numtype(len) == 2 || len <= 0
End

/// @brief Return the seconds since Igor Pro epoch (1/1/1904) in UTC time zone
Function DateTimeInUTC()
	return DateTime - date2secs(-1, -1, -1)
End

/// @brief Return a string in ISO 8601 format with timezone UTC
/// @param secondsSinceIgorEpoch [optional, defaults to number of seconds until now] Seconds since the Igor Pro epoch (1/1/1904) in UTC
Function/S GetISO8601TimeStamp([secondsSinceIgorEpoch])
	variable secondsSinceIgorEpoch

	string str

	if(ParamIsDefault(secondsSinceIgorEpoch))
		secondsSinceIgorEpoch = DateTimeInUTC()
	endif

	sprintf str, "%s %sZ", Secs2Date(secondsSinceIgorEpoch, -2), Secs2Time(secondsSinceIgorEpoch, 3, 0)

	return str
End

/// @brief Parse a simple unit with prefix into its prefix and unit.
///
/// Note: The currently allowed units are the SI base units [1] and other
/// common derived units.  And in accordance to SI definitions, "kg" is a
/// *base* unit. "Simple" unit means means one unit with prefix, not e.g.
/// "km/s".
///
/// @param[in]  unitWithPrefix string to parse, examples are "ms" or "kHz"
/// @param[out] prefix         symbol of decimal multipler of the unit,
///                            see below or [1] chapter 3 for the full list
/// @param[out] numPrefix      numerical value of the decimal multiplier
/// @param[out] unit           unit
///
/// Prefixes:
///
/// Name   | Symbol | Numerical value
/// ------ |--------|---------------
/// yotta  | Y      |  1e24
/// zetta  | Z      |  1e21
/// exa    | E      |  1e18
/// peta   | P      |  1e15
/// tera   | T      |  1e12
/// giga   | G      |  1e9
/// mega   | M      |  1e6
/// kilo   | k      |  1e3
/// hecto  | h      |  1e2
/// deca   | da     |  1e1
/// deci   | d      |  1e-1
/// centi  | c      |  1e-2
/// milli  | m      |  1e-3
/// micro  | mu     |  1e-6
/// nano   | n      |  1e-9
/// pico   | p      |  1e-12
/// femto  | f      |  1e-15
/// atto   | a      |  1e-18
/// zepto  | z      |  1e-21
/// yocto  | y      |  1e-24
///
/// [1]: 8th edition of the SI Brochure (2014), http://www.bipm.org/en/publications/si-brochure
Function ParseUnit(unitWithPrefix, prefix, numPrefix, unit)
	string unitWithPrefix
	string &prefix
	variable &numPrefix
	string &unit

	string expr

	ASSERT(!isEmpty(unitWithPrefix), "empty unit")

	prefix    = ""
	numPrefix = NaN
	unit      = ""

	expr = "(Y|Z|E|P|T|G|M|k|h|d|c|m|mu|n|p|f|a|z|y)?[[:space:]]*(m|kg|s|A|K|mol|cd|Hz|V|N|W|J|a.u.)"

	SplitString/E=(expr) unitWithPrefix, prefix, unit
	ASSERT(V_flag >= 1, "Could not parse unit string")

	numPrefix = GetDecimalMultiplierValue(prefix)
End

/// @brief Return the numerical value of a SI decimal multiplier
///
/// @see ParseUnit
Function GetDecimalMultiplierValue(prefix)
	string prefix

	if(isEmpty(prefix))
		return 1
	endif

	Make/FREE/T prefixes = {"Y", "Z", "E", "P", "T", "G", "M", "k", "h", "da", "d", "c", "m", "mu", "n", "p", "f", "a", "z", "y"}
	Make/FREE/D values   = {1e24, 1e21, 1e18, 1e15, 1e12, 1e9, 1e6, 1e3, 1e2, 1e1, 1e-1, 1e-2, 1e-3, 1e-6, 1e-9, 1e-12, 1e-15, 1e-18, 1e-21, 1e-24}

	FindValue/Z/TXOP=(1 + 4)/TEXT=(prefix) prefixes
	ASSERT(V_Value != -1, "Could not find prefix")

	ASSERT(DimSize(prefixes, ROWS) == DimSize(values, ROWS), "prefixes and values wave sizes must match")
	return values[V_Value]
End
