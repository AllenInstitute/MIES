#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_PUB
#endif

/// @brief Get a template for publishing messages
///
/// Publishers in MIES should in general supply additional information like device/sweep number/timestamp.
/// This function allows to autofill these entries.
static Function PUB_GetJSONTemplate(string device, variable headstage)
	variable jsonID

	jsonID = JSON_New()
	JSON_AddTreeObject(jsonID, "")
	JSON_AddString(jsonID, "device", device)
	JSON_AddVariable(jsonID, "headstage", headstage)
	JSON_AddString(jsonID, "timestamp", GetISO8601TimeStamp())
	JSON_AddVariable(jsonID, "sweep number", AS_GetSweepNumber(device, allowFallback = 1))

	return jsonID
End

/// @brief Publish the given message as given by the JSON and the filter
threadsafe Function PUB_Publish(variable jsonID, string messageFilter, [variable releaseJSON])
	variable err
	string   payload

	releaseJSON = ParamIsDefault(releaseJSON) ? 1 : !!releaseJSON
	payload     = JSON_Dump(jsonID)
	if(releaseJSON)
		JSON_Release(jsonID)
	endif

	AssertOnAndClearRTError()
	try
		zeromq_pub_send(messageFilter, payload); AbortOnRTE
	catch
		err = ClearRTError()
		BUG_TS("Could not publish " + messageFilter + " due to: " + num2str(err))
	endtry
End

static Function PUB_AddLabnotebookEntriesToJSON(variable jsonID, WAVE values, WAVE keys, variable sweepNo, string key, variable headstage, variable labnotebookLayer)
	variable result, col
	string unit, path

	ASSERT(IsNumericWave(values), "Only supporting numeric values for now")

	if(labnotebookLayer == INDEP_HEADSTAGE)
		WAVE/Z settings = GetLastSettingIndepEachSCI(values, sweepNo, key, headstage, UNKNOWN_MODE)
	else
		WAVE/Z settings = GetLastSettingEachSCI(values, sweepNo, key, headstage, UNKNOWN_MODE)
	endif

	if(!WaveExists(settings))
		WAVE/Z sweeps = AFH_GetSweepsFromSameSCI(values, sweepNo, headstage)
		ASSERT(WaveExists(sweeps), "No sweeps in current SCI")

		Make/FREE/N=(DimSize(sweeps, ROWS)) settings = NaN
	endif

	path = "/results/" + key

	JSON_AddTreeObject(jsonID, path)
	JSON_AddWave(jsonID, path + "/value", settings)

	[result, unit, col] = LBN_GetEntryProperties(keys, key)
	JSON_AddString(jsonID, path + "/unit", SelectString(result, unit, ""))
End

/// Filter: #AMPLIFIER_AUTO_BRIDGE_BALANCE
///
/// Example:
///
/// \rst
/// .. code-block:: json
///
///    {
///      "bridge balance resistance": {
///        "unit": "Ohm",
///        "value": 4711
///      },
///      "device": "my_device",
///      "headstage": 0,
///      "sweep number": "NaN",
///      "timestamp": "2022-05-13T18:56:39Z"
///    }
///
/// \endrst
Function PUB_AutoBridgeBalance(string device, variable headstage, variable resistance)
	variable jsonID

	jsonID = PUB_GetJSONTemplate(device, headstage)
	JSON_AddTreeObject(jsonID, "bridge balance resistance")
	JSON_AddVariable(jsonID, "bridge balance resistance/value", resistance)
	JSON_AddString(jsonID, "bridge balance resistance/unit", "Ohm")

	PUB_Publish(jsonID, AMPLIFIER_AUTO_BRIDGE_BALANCE)
End

/// @brief Published message in POST_SET_EVENT for the analysis function PSQ_PipetteInBath()
///
/// Keys under `/results` are labnotebook keys. The arrays under
/// `/results/XXX/values` are the values for each sweep in the stimset cycle.
/// This array has currently always one entry as #PSQ_PB_NUM_SWEEPS_PASS is one.
/// The encoding is UTF-8.
///
/// Example:
///
/// \rst
/// .. code-block:: json
///
///    {
///     "device": "my_device",
///     "headstage": 0,
///     "results": {
///       "USER_Pipette in Bath Chk0 Leak Current BL": {
///         "unit": "Amperes",
///         "value": [
///           123.0
///         ]
///       },
///       "USER_Pipette in Bath Chk0 Leak Current BL QC": {
///         "unit": "On/Off",
///         "value": [
///           0.0
///         ]
///       },
///       "USER_Pipette in Bath Set QC": {
///         "unit": "On/Off",
///         "value": [
///           1.0
///         ]
///       },
///       "USER_Pipette in Bath pipette resistance": {
///         "unit": "Ω",
///         "value": [
///           456.0
///         ]
///       },
///       "USER_Pipette in Bath pipette resistance QC": {
///         "unit": "On/Off",
///         "value": [
///           1.0
///         ]
///       }
///     },
///     "sweep number": "NaN",
///     "timestamp": "2022-02-10T20:48:22Z"
///    }
///
/// .. Output created with Tests/CheckPipetteInBathPublishing.
///
/// \endrst
Function PUB_PipetteInBath(string device, variable sweepNo, variable headstage)
	variable jsonID
	string   key

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE numericalKeys   = GetLBNumericalKeys(device)

	jsonID = PUB_GetJSONTemplate(device, headstage)

	JSON_AddTreeObject(jsonID, "/results")

	key = CreateAnaFuncLBNKey(PSQ_PIPETTE_BATH, PSQ_FMT_LBN_SET_PASS, query = 1)
	PUB_AddLabnotebookEntriesToJSON(jsonID, numericalValues, numericalKeys, sweepNo, key, headstage, INDEP_HEADSTAGE)

	key = CreateAnaFuncLBNKey(PSQ_PIPETTE_BATH, PSQ_FMT_LBN_LEAKCUR_PASS, chunk = 0, query = 1)
	PUB_AddLabnotebookEntriesToJSON(jsonID, numericalValues, numericalKeys, sweepNo, key, headstage, headstage)

	// assumes that we only have one chunk
	key = CreateAnaFuncLBNKey(PSQ_PIPETTE_BATH, PSQ_FMT_LBN_LEAKCUR, chunk = 0, query = 1)
	PUB_AddLabnotebookEntriesToJSON(jsonID, numericalValues, numericalKeys, sweepNo, key, headstage, headstage)

	key = CreateAnaFuncLBNKey(PSQ_PIPETTE_BATH, PSQ_FMT_LBN_PB_RESISTANCE, query = 1)
	PUB_AddLabnotebookEntriesToJSON(jsonID, numericalValues, numericalKeys, sweepNo, key, headstage, INDEP_HEADSTAGE)

	key = CreateAnaFuncLBNKey(PSQ_PIPETTE_BATH, PSQ_FMT_LBN_PB_RESISTANCE_PASS, query = 1)
	PUB_AddLabnotebookEntriesToJSON(jsonID, numericalValues, numericalKeys, sweepNo, key, headstage, INDEP_HEADSTAGE)

	PUB_Publish(jsonID, ANALYSIS_FUNCTION_PB)
End

/// @brief Published message in POST_SET_EVENT for the analysis function PSQ_SealEvaluation()
///
/// Keys under `/results` are labnotebook keys. The arrays under
/// `/results/XXX/values` are the values for each sweep in the stimset cycle.
/// This array has currently always one entry as #PSQ_SE_NUM_SWEEPS_PASS is one.
/// The encoding is UTF-8.
///
/// Example:
///
/// \rst
/// .. code-block:: json
///
///  {
///    "device": "my_device",
///    "headstage": 0,
///    "results": {
///      "USER_Seal evaluation Set QC": {
///      "unit": "On/Off",
///      "value": [
///       1.0
///        ]
///       },
///       "USER_Seal evaluation seal resistance max": {
///         "unit": "Ω",
///         "value": [
///           123.0
///         ]
///       }
///    },
///    "sweep number": "NaN",
///    "timestamp": "2022-02-22T12:27:07Z"
///  }
///
/// .. Output created with Tests/CheckSealEvaluationPublishing.
///
/// \endrst
Function PUB_SealEvaluation(string device, variable sweepNo, variable headstage)
	variable jsonID
	string   key

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE numericalKeys   = GetLBNumericalKeys(device)

	jsonID = PUB_GetJSONTemplate(device, headstage)

	JSON_AddTreeObject(jsonID, "/results")

	key = CreateAnaFuncLBNKey(PSQ_SEAL_EVALUATION, PSQ_FMT_LBN_SET_PASS, query = 1)
	PUB_AddLabnotebookEntriesToJSON(jsonID, numericalValues, numericalKeys, sweepNo, key, headstage, INDEP_HEADSTAGE)

	key = CreateAnaFuncLBNKey(PSQ_SEAL_EVALUATION, PSQ_FMT_LBN_SE_RESISTANCE_MAX, query = 1)
	PUB_AddLabnotebookEntriesToJSON(jsonID, numericalValues, numericalKeys, sweepNo, key, headstage, INDEP_HEADSTAGE)

	PUB_Publish(jsonID, ANALYSIS_FUNCTION_SE)
End

/// @brief Published message in POST_SET_EVENT for the analysis function PSQ_TrueRestingMembranePotential()
///
/// Keys under `/results` are labnotebook keys. The arrays under
/// `/results/XXX/values` are the values for each sweep in the stimset cycle.
/// This array has currently always one entry as #PSQ_VM_NUM_SWEEPS_PASS is one.
/// The encoding is UTF-8.
///
/// Example:
///
/// \rst
/// .. code-block:: json
///
///  {
///    "device": "my_device",
///    "headstage": 0,
///    "results": {
///      "USER_True Rest Memb. Full Average": {
///        "unit": "Volt",
///        "value": [
///          123.0
///        ]
///      },
///      "USER_True Rest Memb. Set QC": {
///        "unit": "On/Off",
///        "value": [
///          1.0
///        ]
///      }
///    },
///    "sweep number": "NaN",
///    "timestamp": "2022-04-27T16:52:28Z"
///  }
///
/// .. Output created with Tests/CheckTrueRestMembPotPublishing.
///
/// \endrst
Function PUB_TrueRestingMembranePotential(string device, variable sweepNo, variable headstage)
	variable jsonID
	string   key

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE numericalKeys   = GetLBNumericalKeys(device)

	jsonID = PUB_GetJSONTemplate(device, headstage)

	JSON_AddTreeObject(jsonID, "/results")

	key = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_SET_PASS, query = 1)
	PUB_AddLabnotebookEntriesToJSON(jsonID, numericalValues, numericalKeys, sweepNo, key, headstage, INDEP_HEADSTAGE)

	key = CreateAnaFuncLBNKey(PSQ_TRUE_REST_VM, PSQ_FMT_LBN_VM_FULL_AVG, query = 1)
	PUB_AddLabnotebookEntriesToJSON(jsonID, numericalValues, numericalKeys, sweepNo, key, headstage, INDEP_HEADSTAGE)

	PUB_Publish(jsonID, ANALYSIS_FUNCTION_VM)
End

/// Filter: #AMPLIFIER_CLAMP_MODE_FILTER
///
/// Example:
///
/// \rst
/// .. code-block:: json
///
///    {
///      "clamp mode": {
///        "new": "V_CLAMP_MODE",
///        "old": "I_CLAMP_MODE"
///      },
///      "device": "my_device",
///      "headstage": 0,
///      "sweep number": "NaN",
///      "timestamp": "2022-05-13T18:54:39Z"
///    }
///
/// \endrst
Function PUB_ClampModeChange(string device, variable headstage, variable oldClampMode, variable newClampMode)
	variable jsonID
	string   payload

	if(oldClampMode == newClampMode)
		return NaN
	endif

	jsonID = PUB_GetJSONTemplate(device, headstage)
	JSON_AddTreeObject(jsonID, "clamp mode")
	JSON_AddString(jsonID, "clamp mode/old", ConvertAmplifierModeToString(oldClampMode))
	JSON_AddString(jsonID, "clamp mode/new", ConvertAmplifierModeToString(newClampMode))

	PUB_Publish(jsonID, AMPLIFIER_CLAMP_MODE_FILTER)
End

/// Filter: #PRESSURE_STATE_FILTER
///
/// Example:
///
/// \rst
/// .. code-block:: json
///
///    {
///      "device": "my_device",
///      "headstage": 0,
///      "pressure method": {
///        "new": "Approach",
///        "old": "Atmosphere"
///      },
///      "sweep number": "NaN",
///      "timestamp": "2022-05-13T18:45:38Z"
///    }
///
/// \endrst
Function PUB_PressureMethodChange(string device, variable headstage, variable oldMethod, variable newMethod)
	variable jsonID

	if(EqualValuesOrBothNaN(oldMethod, newMethod))
		return NaN
	endif

	jsonID = PUB_GetJSONTemplate(device, headstage)
	JSON_AddTreeObject(jsonID, "pressure method")
	JSON_AddString(jsonID, "pressure method/old", P_PressureMethodToString(oldMethod))
	JSON_AddString(jsonID, "pressure method/new", P_PressureMethodToString(newMethod))

	PUB_Publish(jsonID, PRESSURE_STATE_FILTER)
End

/// Filter: #PRESSURE_SEALED_FILTER
///
/// Example:
///
/// \rst
/// .. code-block:: json
///
///    {
///      "device": "my_device",
///      "headstage": 0,
///      "sealed": true,
///      "sweep number": "NaN",
///      "timestamp": "2022-05-13T18:52:14Z"
///    }
///
/// \endrst
Function PUB_PressureSealedState(string device, variable headstage)
	variable jsonID

	jsonID = PUB_GetJSONTemplate(device, headstage)
	JSON_AddBoolean(jsonID, "/sealed", 1)

	PUB_Publish(jsonID, PRESSURE_SEALED_FILTER)
End

/// Filter: #PRESSURE_BREAKIN_FILTER
///
/// Example:
///
/// \rst
/// .. code-block:: json
///
///    {
///      "break in": true,
///      "device": "my_device",
///      "headstage": 0,
///      "sweep number": "NaN",
///      "timestamp": "2022-05-13T18:58:04Z"
///    }
///
/// \endrst
Function PUB_PressureBreakin(string device, variable headstage)
	variable jsonID

	jsonID = PUB_GetJSONTemplate(device, headstage)
	JSON_AddBoolean(jsonID, "/break in", 1)

	PUB_Publish(jsonID, PRESSURE_BREAKIN_FILTER)
End

/// Filter: #AUTO_TP_FILTER
///
/// Example:
///
/// \rst
/// .. code-block:: json
///
///    {
///      "device": "my_device",
///      "headstage": 0,
///      "results": {
///        "QC": true,
///        "amplitude IC": {
///          "unit": "pA",
///          "value": 456
///        },
///        "amplitude VC": {
///          "unit": "mV",
///          "value": 789
///        },
///        "baseline": {
///          "unit": "%",
///          "value": 123
///        },
///        "delta V": {
///          "unit": "mV",
///          "value": 0.5
///        }
///      },
///      "sweep number": "NaN",
///      "timestamp": "2022-05-13T18:59:44Z"
///    }
///
/// \endrst
Function PUB_AutoTPResult(string device, variable headstage, variable result)

	variable jsonID, err
	string payload, path

	WAVE TPSettings = GetTPSettings(device)
	WAVE TPStorage  = GetTPStorage(device)

	WAVE/Z autoTPDeltaV = TP_GetValuesFromTPStorage(TPStorage, headstage, "AutoTPDeltaV", 1)
	ASSERT(WaveExists(autoTPDeltaV), "Missing auto TP delta V")

	jsonID = PUB_GetJSONTemplate(device, headstage)
	JSON_AddTreeObject(jsonID, "results")
	JSON_AddBoolean(jsonID, "results/QC", result)

	path = "results/baseline"
	JSON_AddTreeObject(jsonID, path)
	JSON_AddVariable(jsonID, path + "/value", TPSettings[%baselinePerc][INDEP_HEADSTAGE])
	JSON_AddString(jsonID, path + "/unit", "%")

	path = "results/amplitude IC"
	JSON_AddTreeObject(jsonID, path)
	JSON_AddVariable(jsonID, path + "/value", TPSettings[%amplitudeIC][headstage])
	JSON_AddString(jsonID, path + "/unit", "pA")

	path = "results/amplitude VC"
	JSON_AddTreeObject(jsonID, path)
	JSON_AddVariable(jsonID, path + "/value", TPSettings[%amplitudeVC][headstage])
	JSON_AddString(jsonID, path + "/unit", "mV")

	path = "results/delta V"
	JSON_AddTreeObject(jsonID, path)
	JSON_AddVariable(jsonID, path + "/value", autoTPDeltaV[0])
	JSON_AddString(jsonID, path + "/unit", "mV")

	PUB_Publish(jsonID, AUTO_TP_FILTER)
End

/// Filter: #DAQ_TP_STATE_CHANGE_FILTER
///
/// DAQ:
///
/// \rst
/// .. code-block:: json
///
///    {
///      "daq": "starting",
///      "device": "my_device",
///      "headstage": "NaN",
///      "sweep number": "NaN",
///      "timestamp": "2022-05-16T17:12:24Z",
///      "tp": null
///    }
///
/// \endrst
///
/// TP:
///
/// \rst
/// .. code-block:: json
///
///    {
///      "daq": null,
///      "device": "my_device",
///      "headstage": "NaN",
///      "sweep number": "NaN",
///      "timestamp": "2022-05-16T17:12:29Z",
///      "tp": "stopping"
///    }
///
/// \endrst
///
/// The strings for `daq`/`tp` are either `starting` or `stopping`.
Function PUB_DAQStateChange(string device, variable mode, variable oldState, variable newState)
	variable jsonID
	string name, name_null

	ASSERT(oldState != newState, "Unexpected old/new state combination")
	ASSERT(IsFinite(oldState) && IsFinite(newState), "Both oldState and newState must be finite")

	// here we also force the states to 0/1
	// as we are only interested in the on/off state

	switch(mode)
		case DATA_ACQUISITION_MODE:
			name      = "daq"
			name_null = "tp"
			oldState  = !(oldState == DAQ_NOT_RUNNING)
			newState  = !(newState == DAQ_NOT_RUNNING)
			break
		case TEST_PULSE_MODE:
			name      = "tp"
			name_null = "daq"
			oldState  = !(oldState == TEST_PULSE_NOT_RUNNING)
			newState  = !(newState == TEST_PULSE_NOT_RUNNING)
			break
		default:
			ASSERT(0, "Invalid mode")
	endswitch

	jsonID = PUB_GetJSONTemplate(device, NaN)

	if(oldState == 0 && newState == 1)
		JSON_AddString(jsonID, name, "starting")
	else
		JSON_AddString(jsonID, name, "stopping")
	endif

	JSON_AddNull(jsonID, name_null)

	PUB_Publish(jsonID, DAQ_TP_STATE_CHANGE_FILTER)
End

/// @brief Published message in POST_SET_EVENT for the analysis function PSQ_AccessResistanceSmoke()
///
/// Keys under `/results` are labnotebook keys. The arrays under
/// `/results/XXX/values` are the values for each sweep in the stimset cycle.
/// This array has currently always one entry as #PSQ_AR_NUM_SWEEPS_PASS is one.
/// The encoding is UTF-8.
///
/// Example:
///
/// \rst
/// .. code-block:: json
///
///    {
///      "device": "my_device",
///      "headstage": 0,
///      "results": {
///        "USER_Access Res. Smoke Set QC": {
///          "unit": "On/Off",
///          "value": [
///            1.0
///          ]
///        },
///        "USER_Access Res. Smoke access resistance": {
///          "unit": "Ω",
///          "value": [
///            123.0
///          ]
///        },
///        "USER_Access Res. Smoke access resistance QC": {
///          "unit": "On/Off",
///          "value": [
///            0.0
///          ]
///        },
///        "USER_Access Res. Smoke access vs steady state ratio": {
///          "unit": "",
///          "value": [
///            0.5
///          ]
///        },
///        "USER_Access Res. Smoke access vs steady state ratio QC": {
///          "unit": "On/Off",
///          "value": [
///            1.0
///          ]
///        }
///      },
///      "sweep number": "NaN",
///      "timestamp": "2022-05-07T13:59:39Z"
///    }
///
/// .. Output created with Tests/CheckAccessResSmoke.
///
/// \endrst
Function PUB_AccessResistanceSmoke(string device, variable sweepNo, variable headstage)
	variable jsonID
	string   key

	WAVE numericalValues = GetLBNumericalValues(device)
	WAVE numericalKeys   = GetLBNumericalKeys(device)

	jsonID = PUB_GetJSONTemplate(device, headstage)

	JSON_AddTreeObject(jsonID, "/results")

	key = CreateAnaFuncLBNKey(PSQ_ACC_RES_SMOKE, PSQ_FMT_LBN_SET_PASS, query = 1)
	PUB_AddLabnotebookEntriesToJSON(jsonID, numericalValues, numericalKeys, sweepNo, key, headstage, INDEP_HEADSTAGE)

	key = CreateAnaFuncLBNKey(PSQ_ACC_RES_SMOKE, PSQ_FMT_LBN_AR_ACCESS_RESISTANCE, query = 1)
	PUB_AddLabnotebookEntriesToJSON(jsonID, numericalValues, numericalKeys, sweepNo, key, headstage, INDEP_HEADSTAGE)

	key = CreateAnaFuncLBNKey(PSQ_ACC_RES_SMOKE, PSQ_FMT_LBN_AR_RESISTANCE_RATIO, query = 1)
	PUB_AddLabnotebookEntriesToJSON(jsonID, numericalValues, numericalKeys, sweepNo, key, headstage, INDEP_HEADSTAGE)

	key = CreateAnaFuncLBNKey(PSQ_ACC_RES_SMOKE, PSQ_FMT_LBN_AR_ACCESS_RESISTANCE_PASS, query = 1)
	PUB_AddLabnotebookEntriesToJSON(jsonID, numericalValues, numericalKeys, sweepNo, key, headstage, INDEP_HEADSTAGE)

	key = CreateAnaFuncLBNKey(PSQ_ACC_RES_SMOKE, PSQ_FMT_LBN_AR_RESISTANCE_RATIO_PASS, query = 1)
	PUB_AddLabnotebookEntriesToJSON(jsonID, numericalValues, numericalKeys, sweepNo, key, headstage, INDEP_HEADSTAGE)

	PUB_Publish(jsonID, ANALYSIS_FUNCTION_AR)
End

threadsafe static Function PUB_AddTPResultEntry(variable jsonId, string path, variable value, string unit)

	if(IsEmpty(unit))
		JSON_AddVariable(jsonID, path, value)
	else
		JSON_AddTreeObject(jsonID, path)
		JSON_AddVariable(jsonID, path + "/value", value)
		JSON_AddString(jsonID, path + "/unit", unit)
	endif
End

/// Filter: #ZMQ_FILTER_TPRESULT_NOW
/// Filter: #ZMQ_FILTER_TPRESULT_1S
/// Filter: #ZMQ_FILTER_TPRESULT_5S
/// Filter: #ZMQ_FILTER_TPRESULT_10S
///
/// Example:
///
/// \rst
/// .. code-block:: json
///
///    {
///      "properties": {
///        "baseline fraction": {
///          "unit": "%",
///          "value": 35
///        },
///        "clamp amplitude": {
///          "unit": "mV",
///          "value": 10
///        },
///        "clamp mode": 0,
///        "device": "TestDevice",
///        "headstage": 1,
///        "pulse duration ADC": {
///          "unit": "points",
///          "value": 500
///        },
///        "pulse duration DAC": {
///          "unit": "points",
///          "value": 600
///        },
///        "pulse start point ADC": {
///          "unit": "point",
///          "value": 500
///        },
///        "pulse start point DAC": {
///          "unit": "point",
///          "value": 600
///        },
///        "sample interval ADC": {
///          "unit": "ms",
///          "value": 0.002
///        },
///        "sample interval DAC": {
///          "unit": "ms",
///          "value": 0.002
///        },
///        "time of tp acquisition": {
///          "unit": "s",
///          "value": 1000000
///        },
///        "timestamp": {
///          "unit": "s",
///          "value": 2000000
///        },
///        "timestampUTC": {
///          "unit": "s",
///          "value": 3000000
///        },
///        "tp cycle id": 456,
///        "tp length ADC": {
///          "unit": "points",
///          "value": 1500
///        },
///        "tp length DAC": {
///          "unit": "points",
///          "value": 1800
///        },
///        "tp marker": 1234
///      },
///      "results": {
///        "average baseline steady state": {
///          "unit": "pA",
///          "value": 2
///        },
///        "average tp steady state": {
///          "unit": "pA",
///          "value": 10
///        },
///        "instantaneous": {
///          "unit": "pA",
///          "value": 11
///        },
///        "instantaneous resistance": {
///          "unit": "MΩ",
///          "value": 2345
///        },
///        "steady state resistance": {
///          "unit": "MΩ",
///          "value": 1234
///        }
///      }
///    }
///
/// \endrst
threadsafe Function PUB_TPResult(string device, WAVE tpData)

	string path
	variable jsonId = JSON_New()
	string   adUnit = GetADChannelUnit(tpData[%CLAMPMODE])
	string   daUnit = GetDAChannelUnit(tpData[%CLAMPMODE])

	path = "properties"
	JSON_AddTreeObject(jsonID, path)
	JSON_AddString(jsonID, path + "/device", device)
	JSON_AddVariable(jsonID, path + "/tp marker", tpData[%MARKER])
	JSON_AddVariable(jsonID, path + "/headstage", tpData[%HEADSTAGE])
	JSON_AddVariable(jsonID, path + "/clamp mode", tpData[%CLAMPMODE])

	PUB_AddTPResultEntry(jsonId, path + "/time of tp acquisition", tpData[%NOW], "s")
	PUB_AddTPResultEntry(jsonId, path + "/clamp amplitude", tpData[%CLAMPAMP], daUnit)
	PUB_AddTPResultEntry(jsonId, path + "/tp length ADC", tpData[%TPLENGTHPOINTSADC], "points")
	PUB_AddTPResultEntry(jsonId, path + "/pulse duration ADC", tpData[%PULSELENGTHPOINTSADC], "points")
	PUB_AddTPResultEntry(jsonId, path + "/pulse start point ADC", tpData[%PULSESTARTPOINTSADC], "point")
	PUB_AddTPResultEntry(jsonId, path + "/sample interval ADC", tpData[%SAMPLINGINTERVALADC], "ms")
	PUB_AddTPResultEntry(jsonId, path + "/tp length DAC", tpData[%TPLENGTHPOINTSDAC], "points")
	PUB_AddTPResultEntry(jsonId, path + "/pulse duration DAC", tpData[%PULSELENGTHPOINTSDAC], "points")
	PUB_AddTPResultEntry(jsonId, path + "/pulse start point DAC", tpData[%PULSESTARTPOINTSDAC], "point")
	PUB_AddTPResultEntry(jsonId, path + "/sample interval DAC", tpData[%SAMPLINGINTERVALDAC], "ms")
	PUB_AddTPResultEntry(jsonId, path + "/baseline fraction", tpData[%BASELINEFRAC] * ONE_TO_PERCENT, "%")
	PUB_AddTPResultEntry(jsonId, path + "/timestamp", tpData[%TIMESTAMP], "s")
	PUB_AddTPResultEntry(jsonId, path + "/timestampUTC", tpData[%TIMESTAMPUTC], "s")
	PUB_AddTPResultEntry(jsonId, path + "/tp cycle id", tpData[%CYCLEID], "")

	path = "results"
	JSON_AddTreeObject(jsonID, path)
	PUB_AddTPResultEntry(jsonId, path + "/average baseline steady state", tpData[%BASELINE], adUnit)
	PUB_AddTPResultEntry(jsonId, path + "/average tp steady state", tpData[%ELEVATED_SS], adUnit)
	PUB_AddTPResultEntry(jsonId, path + "/instantaneous", tpData[%ELEVATED_INST], adUnit)
	PUB_AddTPResultEntry(jsonId, path + "/steady state resistance", tpData[%STEADYSTATERES], "MΩ")
	PUB_AddTPResultEntry(jsonId, path + "/instantaneous resistance", tpData[%INSTANTRES], "MΩ")

	PUB_Publish(jsonID, ZMQ_FILTER_TPRESULT_NOW, releaseJSON = 0)
	if(PUB_CheckPublishingTime(ZMQ_FILTER_TPRESULT_1S, 1))
		PUB_Publish(jsonID, ZMQ_FILTER_TPRESULT_1S, releaseJSON = 0)
	endif
	if(PUB_CheckPublishingTime(ZMQ_FILTER_TPRESULT_5S, 5))
		PUB_Publish(jsonID, ZMQ_FILTER_TPRESULT_5S, releaseJSON = 0)
	endif
	if(PUB_CheckPublishingTime(ZMQ_FILTER_TPRESULT_10S, 10))
		PUB_Publish(jsonID, ZMQ_FILTER_TPRESULT_10S, releaseJSON = 0)
	endif
	JSON_Release(jsonID)
End

/// @brief Updates the publishing timestamp in the TUFXOP storage and returns 1 if an update is due (0 otherwise)
threadsafe static Function PUB_CheckPublishingTime(string pubFilter, variable period)

	variable lastTime
	variable curTime = DateTime

	TUFXOP_AcquireLock/N=(pubFilter)
	lastTime = TSDS_ReadVar(pubFilter, defValue = 0, create = 1)
	if(lastTime + period < curTime)
		TSDS_WriteVar(pubFilter, curTime + period)
		TUFXOP_ReleaseLock/N=(pubFilter)
		return 1
	endif
	TUFXOP_ReleaseLock/N=(pubFilter)

	return 0
End
