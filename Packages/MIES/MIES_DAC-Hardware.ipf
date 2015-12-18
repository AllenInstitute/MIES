#pragma rtGlobals=3		// Use modern global access method and strict wave access.

/// @file MIES_DAC-Hardware.ipf
/// @brief __HW__ Low level hardware configuration and querying functions
///
/// Naming scheme of the functions is `HW_$TYPE_$Suffix` where `$TYPE` is one of `ITC` or `NI`.

/// @name Utility functions not interacting with hardware
/// @{

/// @brief Return the `first` and `last` TTL bits/channels for the given `rack`
Function HW_ITC_GetRackRange(rack, first, last)
	variable rack
	variable &first, &last

	if(rack == RACK_ZERO)
		first = 0
		last = NUM_TTL_BITS_PER_RACK - 1
	elseif(rack == RACK_ONE)
		first = NUM_TTL_BITS_PER_RACK
		last = 2 * NUM_TTL_BITS_PER_RACK - 1
	else
		ASSERT(0, "Invalid rack parameter")
	endif
End

/// @brief Clip the ttlBit to adapt for differences in notation
///
/// The DA_Ephys panel e.g. labels the first ttlBit of #RACK_ONE as 4, but the
/// ITC XOP treats that as 0.
Function HW_ITC_ClipTTLBit(panelTitle, ttlBit)
	string panelTitle
	variable ttlBit

	if(HW_ITC_GetRackForTTLBit(panelTitle, ttlBit) == RACK_ONE)
		return ttlBit - NUM_TTL_BITS_PER_RACK
	else
		return ttlBit
	endif
End

/// @brief Return the rack number for the given ttlBit (the ttlBit is
/// called `TTL channel` in the DA Ephys panel)
Function HW_ITC_GetRackForTTLBit(panelTitle, ttlBit)
	string panelTitle
	variable ttlBit

	string deviceType, deviceNumber
	variable ret

	ASSERT(ttlBit < NUM_DA_TTL_CHANNELS, "Invalid channel index")

	if(ttlBit >= NUM_TTL_BITS_PER_RACK)
		ret = ParseDeviceString(panelTitle, deviceType, deviceNumber)
		ASSERT(ret, "Could not parse device string")
		ASSERT(!cmpstr(deviceType, "ITC1600"), "Only the ITC1600 has multiple racks")

		return RACK_ONE
	else
		return RACK_ZERO
	endif
End

/// @brief Return the ITC XOP channel for the given rack
///
/// Only the ITC1600 has two racks. The channel numbers differ for the
/// different ITC device types.
Function HW_ITC_GetITCXOPChannelForRack(panelTitle, rack)
	string panelTitle
	variable rack

	string deviceType, deviceNumber
	variable ret

	ret = ParseDeviceString(panelTitle, deviceType, deviceNumber)
	ASSERT(ret, "Could not parse device string")

	if(rack == RACK_ZERO)
		if(!cmpstr(deviceType, "ITC18USB") || !cmpstr(deviceType, "ITC18"))
			return HARDWARE_ITC_TTL_DEF_RACK_ZERO
		else
			return HARDWARE_ITC_TTL_1600_RACK_ZERO
		endif
	elseif(rack == RACK_ONE)
		ASSERT(!cmpstr(deviceType, "ITC1600"), "Only the ITC1600 has multiple racks")
		return HARDWARE_ITC_TTL_1600_RACK_ONE
	endif
End
/// @}
