#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_MIESUTILS_CONVERSION
#endif

/// @file MIES_MiesUtilities_Conversion.ipf
/// @brief This file holds MIES utility functions for conversions

/// @brief Convert a channel type constant from @ref ChannelTypeAndControlConstants to a string
Function/S ChannelTypeToString(variable channelType)

	switch(channelType)
		case CHANNEL_TYPE_HEADSTAGE:
			return "DataAcqHS"
		case CHANNEL_TYPE_DAC:
			return "DA"
		case CHANNEL_TYPE_ADC:
			return "AD"
		case CHANNEL_TYPE_TTL:
			return "TTL"
		case CHANNEL_TYPE_ALARM:
			return "AsyncAlarm"
		case CHANNEL_TYPE_ASYNC:
			return "AsyncAD"
		default:
			ASSERT(0, "Invalid channelType")
	endswitch
End

/// @brief Convert a channel type string from ChannelTypeToString to one of the constants from @ref ChannelTypeAndControlConstants
///
/// @param channelType channel type
/// @param allowFail   [optional, defaults to false] return NaN on unknown channel types (true) or assert (false)
///
/// UTF_NOINSTRUMENTATION
Function ParseChannelTypeFromString(string channelType, [variable allowFail])

	allowFail = ParamIsDefault(allowFail) ? 0 : !!allowFail

	strswitch(channelType)
		case "DataAcqHS":
			return CHANNEL_TYPE_HEADSTAGE
		case "DA":
			return CHANNEL_TYPE_DAC
		case "AD":
			return CHANNEL_TYPE_ADC
		case "TTL":
			return CHANNEL_TYPE_TTL
		case "AsyncAlarm":
			return CHANNEL_TYPE_ALARM
		case "AsyncAD":
			return CHANNEL_TYPE_ASYNC
		default:
			ASSERT(allowFail, "Invalid channelType")
			return NaN
	endswitch
End

/// @brief Return the maximum count of the given type
///
/// @param var    numeric channel types
/// @param str    string channel types
/// @param xopVar numeric XOP channel types
threadsafe Function GetNumberFromType([var, str, xopVar])
	variable var
	string   str
	variable xopVar

	ASSERT_TS(ParamIsDefault(var) + ParamIsDefault(str) + ParamIsDefault(xopVar) == 2, "Expected exactly one parameter")

	if(!ParamIsDefault(str))
		strswitch(str)
			case "AsyncAD":
				return NUM_ASYNC_CHANNELS
				break
			case "DA":
			case "TTL":
				return NUM_DA_TTL_CHANNELS
				break
			case "DataAcqHS":
			case "Headstage":
				return NUM_HEADSTAGES
				break
			case "AD":
				return NUM_AD_CHANNELS
				break
			case "Async_Alarm":
				return NUM_ASYNC_CHANNELS
				break
			default:
				ASSERT_TS(0, "invalid type")
				break
		endswitch
	elseif(!ParamIsDefault(var))
		switch(var)
			case CHANNEL_TYPE_ASYNC:
			case CHANNEL_TYPE_ALARM:
				return NUM_ASYNC_CHANNELS
				break
			case CHANNEL_TYPE_TTL:
			case CHANNEL_TYPE_DAC:
				return NUM_DA_TTL_CHANNELS
				break
			case CHANNEL_TYPE_HEADSTAGE:
				return NUM_HEADSTAGES
				break
			case CHANNEL_TYPE_ADC:
				return NUM_AD_CHANNELS
				break
			default:
				ASSERT_TS(0, "invalid type")
				break
		endswitch
	elseif(!ParamIsDefault(xopVar))
		switch(xopVar)
			case XOP_CHANNEL_TYPE_ADC:
				return NUM_AD_CHANNELS
				break
			case XOP_CHANNEL_TYPE_DAC:
			case XOP_CHANNEL_TYPE_TTL:
				return NUM_DA_TTL_CHANNELS
				break
			default:
				ASSERT_TS(0, "Invalid type")
				break
		endswitch
	endif
End

/// @brief Return the name short String of the Parameter Wave used in the WaveBuilder
///
/// @param type One of @ref ParameterWaveTypes
///
/// @return name as string
Function/S GetWaveBuilderParameterTypeName(type)
	variable type

	string shortname

	switch(type)
		case STIMSET_PARAM_WP:
			shortname = "WP"
			break
		case STIMSET_PARAM_WPT:
			shortname = "WPT"
			break
		case STIMSET_PARAM_SEGWVTYPE:
			shortname = "SegWvType"
			break
		default:
			break
	endswitch

	return shortname
End

/// @brief Stringified short version of the clamp mode
Function/S ConvertAmplifierModeShortStr(mode)
	variable mode

	switch(mode)
		case V_CLAMP_MODE:
			return "VC"
			break
		case I_CLAMP_MODE:
			return "IC"
			break
		case I_EQUAL_ZERO_MODE:
			return "IZ"
			break
		default:
			return "Unknown mode (" + num2str(mode) + ")"
			break
	endswitch
End

/// @brief Stringified version of the clamp mode
Function/S ConvertAmplifierModeToString(mode)
	variable mode

	switch(mode)
		case V_CLAMP_MODE:
			return "V_CLAMP_MODE"
			break
		case I_CLAMP_MODE:
			return "I_CLAMP_MODE"
			break
		case I_EQUAL_ZERO_MODE:
			return "I_EQUAL_ZERO_MODE"
			break
		default:
			return "Unknown mode (" + num2str(mode) + ")"
			break
	endswitch
End

/// @brief Return the short/abbreviated analysis function name used in the tables
Function/S GetAbbreviationForAnalysisFunction(string anaFunc)

	strswitch(anaFunc)
		case "PSQ_Ramp":
			return "RA"
		case "PSQ_Chirp":
			return "CR"
		case "PSQ_DaScale":
			return "DA"
		case "PSQ_PipetteInBath":
			return "PB"
		case "PSQ_SealEvaluation":
			return "SE"
		case "PSQ_TrueRestingMembranePotential":
			return "VM"
		case "PSQ_AccessResistanceSmoke":
			return "AR"
		case "PSQ_Rheobase":
			return "RB"
		case "PSQ_SquarePulse":
			return "SP"
		case "MSQ_FastRheoEst":
			return "FR"
		case "MSQ_DAScale":
			return "DS"
		case "SC_SpikeControl":
			return "SC"
		default:
			ASSERT(0, "Unknown")
	endswitch
End

/// @brief Map from analysis function name to numeric constant
///
/// @return One of @ref SpecialAnalysisFunctionTypes which includes
///         #INVALID_ANALYSIS_FUNCTION and for CI testing #TEST_ANALYSIS_FUNCTION
Function MapAnaFuncToConstant(anaFunc)
	string anaFunc

	strswitch(anaFunc)
		case "PSQ_Ramp":
			return PSQ_RAMP
		case "PSQ_Chirp":
			return PSQ_CHIRP
		case "PSQ_DaScale":
			return PSQ_DA_SCALE
		case "PSQ_PipetteInBath":
			return PSQ_PIPETTE_BATH
		case "PSQ_SealEvaluation":
			return PSQ_SEAL_EVALUATION
		case "PSQ_TrueRestingMembranePotential":
			return PSQ_TRUE_REST_VM
		case "PSQ_AccessResistanceSmoke":
			return PSQ_ACC_RES_SMOKE
		case "PSQ_Rheobase":
			return PSQ_RHEOBASE
		case "PSQ_SquarePulse":
			return PSQ_SQUARE_PULSE
		case "MSQ_FastRheoEst":
			return MSQ_FAST_RHEO_EST
		case "MSQ_DAScale":
			return MSQ_DA_SCALE
		case "SC_SpikeControl":
			return SC_SPIKE_CONTROL
		default:
#ifdef AUTOMATED_TESTING
			return TEST_ANALYSIS_FUNCTION
#else
			return INVALID_ANALYSIS_FUNCTION
#endif
	endswitch
End

/// @brief returns the unit string for the AD channel depending on clampmode
threadsafe Function/S GetADChannelUnit(variable clampMode)

	return SelectString(clampMode == V_CLAMP_MODE, "mV", "pA")
End

/// @brief returns the unit string for the DA channel depending on clampmode
threadsafe Function/S GetDAChannelUnit(variable clampMode)

	return SelectString(clampMode == V_CLAMP_MODE, "pA", "mV")
End
