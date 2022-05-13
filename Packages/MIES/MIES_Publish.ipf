#pragma TextEncoding = "UTF-8"
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
static Function PUB_Publish(variable jsonID, string messageFilter)
	variable err
	string payload

	payload = JSON_Dump(jsonID)
	JSON_Release(jsonID)

	AssertOnAndClearRTError()
	try
		zeromq_pub_send(messageFilter, payload); AbortOnRTE
	catch
		err = ClearRTError()
		BUG("Could not publish " + messageFilter + " due to: " + num2str(err))
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
	string key

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
	string key

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
	string key

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
	string payload

	if(oldClampMode == newClampMode)
		return NaN
	endif

	jsonID = PUB_GetJSONTemplate(device, headstage)
	JSON_AddTreeObject(jsonID, "clamp mode")
	JSON_AddString(jsonID, "clamp mode/old", ConvertAmplifierModeToString(oldClampMode))
	JSON_AddString(jsonID, "clamp mode/new", ConvertAmplifierModeToString(newClampMode))

	PUB_Publish(jsonID, AMPLIFIER_CLAMP_MODE_FILTER)
End

/// @brief Push QC results onto ZeroMQ Publisher socket
///
/// Filter: #IVS_PUB_FILTER
///
/// Payload: JSON-encoded string with three elements in the top-level object
///
/// Example:
///
/// \rst
/// .. code-block:: json
///
///    {
///      "Description": "some text",
///      "Issuer": "My QC Function",
///      "Value": 123
///    }
///
/// \endrst
Function PUB_IVS_QCState(variable result, string description)
	variable jsonID

	jsonID = JSON_New()
	JSON_AddTreeObject(jsonID, "")
	JSON_AddString(jsonID, "Issuer", GetRTStackInfo(2))
	JSON_AddVariable(jsonID, "Value", result)
	JSON_AddString(jsonID, "Description", description)

	PUB_Publish(jsonID, IVS_PUB_FILTER)
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
	WAVE TPStorage = GetTPStorage(device)

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
