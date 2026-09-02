#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_PY
#endif // AUTOMATED_TESTING

/// @brief Return the disc folder where our python scripts are located
Function/S PY_GetMIESPythonScriptsDiscLocation()

	return GetFolder(FunctionPath("")) + ":Python:"
End

/// @brief Return the disc folder where the MIES tools are located
Function/S PY_GetToolsDiscLocation()

	return GetFolder(FunctionPath("")) + "::" + "tools:"
End

/// @brief Return the disc folder below "Igor Pro XX User Files:Python Scripts" for the given package
///
/// This is also used to hold the virtual environment.
Function/S PY_GetPackageFolder(string packageName)

	return GetPythonScriptsFolder() + packageName
End

/// @brief Bootstrap a virtual environment for the given package
///
/// Use `tools:<packageName>:requirements.txt` to create a virtual
/// environment at `Igor Pro XX User Files:Python Scripts:<packageName>` using python 3.14.
///
/// The venv is completely recreated every time.
static Function/S PY_CreateVirtEnv(string packageName)

	string cmd, req_txt, pkgFolder, pyVersion
	string toolsFolder, uv, uvPythonDir
	variable ret

	pkgFolder   = PY_GetPackageFolder(packageName)
	toolsFolder = PY_GetToolsDiscLocation()
	uv          = toolsFolder + "uv.exe"
	req_txt     = toolsFolder + packageName + ":requirements.txt"
	// Security support ends on 31st Oct 2030
	pyVersion = "3.14"

	uvPythonDir = HFSPathToWindows(GetEnvironmentVariable("USERPROFILE") + ":.uv:python")
	ret         = SetEnvironmentVariable("UV_PYTHON_INSTALL_DIR", uvPythonDir)
	ASSERT(!ret, "Failed to set UV_PYTHON_INSTALL_DIR")

	sprintf cmd, "%s venv --clear --no-project --no-config --relocatable --managed-python --python %s \"%s\"", HFSPathToWindows(uv), pyVersion, HFSPathToWindows(pkgFolder)
	DEBUGPRINT(cmd)
	ExecuteScriptText/B/Z cmd
	DEBUGPRINT(S_Value)
	ASSERT(!V_Flag, "Could not create the python environment")

	sprintf cmd, "%s pip install --no-config --require-hashes --exact --directory \"%s\" --requirements \"%s\"", HFSPathToWindows(uv), HFSPathToWindows(pkgFolder), HFSPathToWindows(req_txt)
	DEBUGPRINT(cmd)
	ExecuteScriptText/B/Z cmd
	DEBUGPRINT(S_Value)
	ASSERT(!V_Flag, "Could not fill the python environment")

	return pkgFolder
End

/// @brief Activate the virtual environment for the given package
///
/// @return 0 on success, 1 if an IP restart is required
static Function PY_ActivateVirtEnv(string packageName)

	string venv, activeVenv
	variable isPythonRunning

	PythonEnv/Z=1
	activeVenv      = StringByKey("NAME", S_PythonEnvInfo, "=", ";")
	isPythonRunning = V_PythonRunning

	if(!cmpstr(activeVenv, packageName))
		return 0
	endif

	venv = PY_CreateVirtEnv(packageName)

	PythonEnv/Z activate=venv
	ASSERT(!V_flag, "Could not enable the venv for " + packageName)

	if(isPythonRunning)
		// python was running and we activated a new environment, warn the user
		print "Igor Pro needs to be restarted as a new Python virtual environment was activated."
		ControlWindowToFront()
		return 1
	endif

	return 0
End

static Function/S PY_GetLimsCredentials()

	string   result
	variable ret

	WAVE/Z/T credentials = QueryLIMSCredentials()

	if(!WaveExists(credentials))
		DFREF dfr = GetUniqueTempPath()

		WAVE/T credentials = GetLIMSCredentialsAsFree()
		MoveWave credentials, dfr:credentials

		Duplicate/FREE/T credentials, credentials_mock
		credentials_mock[] = "invalid"

		ret = ID_AskUserForSettings(ID_KVPAIRS_SETTINGS, "Please enter the credentials\r to access LIMS", credentials, credentials_mock)

		if(ret)
			KillOrMoveToTrash(dfr = dfr)
			return ""
		endif

		StoreLIMSCredentials(credentials)
	endif

	// pass TXOP_CASE_SENSE as there is no better default
	ASSERT(IsNaN(GetRowIndex(credentials, str = "\"", textOp = TXOP_CASE_SENSE)), "Can not handle quotes (\") in the credential")
	ASSERT(IsNaN(GetRowIndex(credentials, str = " ", textOp = TXOP_CASE_SENSE)), "Can not handle spaces ( ) in the credential")

	sprintf result, "--db_user %s --db_password %s --db_host %s --db_name %s", credentials[%$"Db User"], credentials[%$"Db Password"], credentials[%$"Db Host"], credentials[%$"Db Name"]

	KillOrMoveToTrash(dfr = dfr)

	return result
End

/// @brief Fetch the disc locations for the given cell names from the
///        Allen Institute for Brain Science' Lab Information System (LIMS)
Function/WAVE PY_FetchFilesFromLims(WAVE/T cellnames)

#if defined(MACINTOSH)
	FATAL_ERROR("Not yet supported on macosx")
#endif

	string list, loc, packageName
	variable ret

	packageName = "lims-query"

	ret = PY_ActivateVirtEnv(packageName)

	if(ret)
		return $""
	endif

	list = PY_GetLimsCredentials()

	if(IsEmpty(list))
		return $""
	endif

	list += " "
	list += TextWaveToList(cellnames, " ", trailSep = 0)
	Make/FREE/T/N=0 results
	loc = PY_GetMIESPythonScriptsDiscLocation() + "limspath_from_cellname.py"
	PythonFile/Z file=loc, array={"paths", results}, args=list
	ASSERT(!V_flag, "Error executing LIMS path querying:" + S_PythonError)

	// forward slashes to backward slashes
	// and UNC server prefix
	results[] = "\\" + ReplaceRegexInString("/", results[p], "\\")

	return results
End
