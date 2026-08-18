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

/// @brief Return the disc folder below "Igor Pro XX User Files" for the given package
Function/S PY_GetPackageFolder(string packageName)

	return GetPythonScriptsFolder() + packageName
End

/// @brief Return the disc folder to store the virtual environment for the given package
Function/S PY_GetVirtEnvFolder(string packageName)

	return PY_GetPackageFolder(packageName)
End

/// @brief Bootstrap a virtual environment for the given package
///
/// Use requirements.txt from `tools:<packageName>` to create a virtual
/// environment at `Igor Pro XX User Files:Python Scripts:<packageName>`.
///
/// The venv is completely recreated every time.
static Function/S PY_CreateVirtEnv(string packageName)

	string venv, cmd, folder, reqFolder, pkgFolder, pyVersion
	string toolsFolder, uv

	venv        = PY_GetVirtEnvFolder(packageName)
	pkgFolder   = PY_GetPackageFolder(packageName)
	toolsFolder = PY_GetToolsDiscLocation()
	uv          = toolsFolder + "uv.exe"
	reqFolder   = toolsFolder + packageName + ":"
	pyVersion   = "3.14"

	sprintf cmd, "%s venv --clear --no-project --no-config --relocatable --managed-python --python %s \"%s\"", HFSPathToWindows(uv), pyVersion, HFSPathToWindows(venv)
	print cmd
	ExecuteScriptText/B/Z cmd
	ASSERT(!V_Flag, "Could not create the python environment")

	sprintf cmd, "%s pip install --no-config --require-hashes --exact --directory \"%s\" --requirements \"%srequirements.txt\"", HFSPathToWindows(uv), HFSPathToWindows(pkgFolder), HFSPathToWindows(reqFolder)
	print cmd
	ExecuteScriptText/B/Z cmd
	ASSERT(!V_Flag, "Could not fill the python environment")

	return venv
End

/// @brief Activate the virtual environment for the given package
///
/// @return 0 on success, 1 if an IP restart is required
Function PY_ActivateVirtEnv(string packageName)

	string venv, activeVenv
	variable isPythonRunning

	PythonEnv
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
		print "Igo Pro needs to be restarted as a new Python virtual environment was activated."
		ControlWindowToFront()
		return 1
	endif

	return 0
End

/// @brief Fetch the disc locations for the given cell names from the
///        Allen Institute for Brain Science' Lab Information System (LIMS)
Function/WAVE PY_FetchFilesFromLims(WAVE/T cellnames)

	string list, loc, packageName
	variable ret

	packageName = "lims-query"

	ret = PY_ActivateVirtEnv(packageName)

	if(ret)
		return $""
	endif

	// test without having access to LIMS
	list = TextWaveToList(cellnames, " ", trailSep = 0)
	Make/FREE/T/N=0 results
	loc = PY_GetMIESPythonScriptsDiscLocation() + "limspath_from_cellname.py"
	PythonFile/Z file=loc, array={"paths", results}, args=list
	ASSERT(!V_flag, "Error executing LIMS path querying:" + S_PythonError)

	// see DisplayHelpTopic "UNC Paths"
	results[] = ReplaceRegexInString("^/allen/programs", results[p], "\\\\\\\\allen\\\\programs")

	// forward slashes to backward slashes
	results[] = ReplaceRegexInString("/", results[p], "\\\\")

	return results
End

Function dostuff()

	WAVE/T results = PY_FetchFilesFromLims({"fake"})
	print results
End
