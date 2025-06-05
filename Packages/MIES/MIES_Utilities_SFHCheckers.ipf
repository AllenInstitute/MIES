#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_SFHCheckers
#endif // AUTOMATED_TESTING

/// @file MIES_Utilities_SFHCheckers.ipf
/// @brief Threadsafe check functions which comply with either SFH_NumericChecker_Prototype or SFH_StringChecker_Prototype

/// @brief Check if a name for an object adheres to the strict naming rules
///
/// @see `DisplayHelpTopic "Standard Object Names"`
///
/// UTF_NOINSTRUMENTATION
threadsafe Function IsValidObjectName(string name)

	return NameChecker(name, 0)
End

/// @brief Check if a name for an object adheres to the liberal naming rules
///
/// @see `DisplayHelpTopic "Liberal Object Names"`
///
/// UTF_NOINSTRUMENTATION
threadsafe Function IsValidLiberalObjectName(string name)

	return NameChecker(name, 1)
End

/// UTF_NOINSTRUMENTATION
threadsafe static Function NameChecker(string name, variable liberal)

	return !cmpstr(name, CleanupName(name, !!liberal, MAX_OBJECT_NAME_LENGTH_IN_BYTES))
End

/// UTF_NOINSTRUMENTATION
threadsafe Function IsStrictlyPositiveAndFinite(variable var)

	return var > 0 && var < Inf
End

/// UTF_NOINSTRUMENTATION
threadsafe Function IsNullOrPositiveAndFinite(variable var)

	return var >= 0 && var < Inf
End

/// @brief Return the truth if `val` is in the range `]0, 1[`
///
/// UTF_NOINSTRUMENTATION
threadsafe Function BetweenZeroAndOneExc(variable val)

	return val > 0.0 && val < 1.0
End

/// @brief Return the truth if `val` is in the range `[0, 1]`
///
/// UTF_NOINSTRUMENTATION
threadsafe Function BetweenZeroAndOne(variable val)

	return val >= 0.0 && val <= 1.0
End

/// @brief Return the truth if `val` is in the range `]0, 100[`
///
/// UTF_NOINSTRUMENTATION
threadsafe Function BetweenZeroAndOneHoundredExc(variable val)

	return val > 0.0 && val < 100.0
End

/// @brief Return the truth if `val` is in the range `[0, 100]`
///
/// UTF_NOINSTRUMENTATION
threadsafe Function BetweenZeroAndOneHoundred(variable val)

	return val >= 0.0 && val <= 100.0
End
