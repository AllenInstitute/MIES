#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_PY
#endif // AUTOMATED_TESTING

Function/S PY_GetPackageFolder(string packageName)

	return GetPythonScriptsFolder() + packageName
End

Function/S PY_GetVirtEnvFolder(string packageName)

	return PY_GetPackageFolder(packageName) + ":.venv"
End

Function/S PY_CreateVirtEnv()

	string venv, cmd, folder, reqFolder, packageName, pkgFolder

	packageName = "lims-query"

	venv      = PY_GetVirtEnvFolder(packageName)
	pkgFolder = PY_GetPackageFolder(packageName)
	reqFolder = GetFolder(FunctionPath("")) + "::" + "tools:" + packageName + ":"

	sprintf cmd, "uv venv --clear --no-project --no-config --relocatable --managed-python --python 3.14 \"%s\"", HFSPathToWindows(venv)
	//	print cmd
	ExecuteScriptText/B/Z cmd
	ASSERT(!V_Flag, "Could not create the python environment")

	sprintf cmd, "uv pip install --no-config --require-hashes --exact --directory \"%s\" --requirements \"%srequirements.txt\"", HFSPathToWindows(pkgFolder), HFSPathToWindows(reqFolder)
	//	print cmd
	ExecuteScriptText/B/Z cmd
	ASSERT(!V_Flag, "Could not fill the python environment")
End

Function/S PY_ActivateVirtEnv()

	string venv, packageName

	packageName = "lims-query"

	venv = PY_GetVirtEnvFolder(packageName)

	PythonEnv/Z activate=venv
	ASSERT(!V_flag, "Could not enable the venv for " + packageName)
End

Function/WAVE PY_FetchFilesFromLims(WAVE/T cellnames)

	string list

	// test without having access to LIMS
	list = TextWaveToList(cellnames, " ", trailSep = 0)
	Make/FREE/T results
	PythonFile/Z file="e:/projekte/mies-igor/Packages/Python/limspath_from_cellname.py", array={"paths", results}, args=list
	ASSERT(!V_flag, "Error executing LIMS path querying:" + S_PythonError)

	// @todo convert to UNC path

	return results
End
