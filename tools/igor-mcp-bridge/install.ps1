<#
.SYNOPSIS
    Installs the pinned Python dependencies for the Igor Pro Bridge MCP server
    (tools/igor-mcp-bridge/server.py) into the same Python environment Claude Desktop
    itself resolves when it launches the bridge.

.DESCRIPTION
    Claude Desktop's manifest.json invokes the bridge as the bare command "python",
    resolved via whatever PATH Claude Desktop's own process environment has at launch
    time. That is NOT guaranteed to be the same Python an interactive console session
    resolves -- e.g. a PowerShell profile script activating a conda environment only
    for that session, or a per-user Microsoft Store "app execution alias" stub (a
    placeholder python.exe that just opens the Store) which is known to behave
    differently once elevated. Installing packages into whatever Python a
    manually-opened console happens to find can therefore silently install into the
    wrong environment.

    This script instead resolves python.exe from the Machine and then User PATH
    registry values directly (via [Environment]::GetEnvironmentVariable(..., target)),
    the same two sources and order Windows composes into a freshly created process's
    environment block regardless of that process's elevation state -- deliberately
    ignoring this session's own possibly-customized $env:Path, to mirror what a
    freshly launched Claude Desktop process actually sees, whether or not it happens
    to be elevated. Pass -PythonPath explicitly to skip this resolution entirely if
    you already know the right interpreter (e.g. from a prior get_bridge_version()
    call -- see below).

    Steps performed, in order:
      1. Confirm this script itself is running elevated. This is required only for
         step 5 below (pywin32's post-install step, which registers COM-support DLLs
         into protected system locations, even though this bridge no longer uses COM
         itself as of v2.0.0 -- see below) -- it is NOT because Claude Desktop or Igor
         Pro themselves need to be elevated at runtime. As of v2.0.0, the bridge talks
         to Igor Pro over a plain localhost ZeroMQ socket, which has NO privilege-
         matching requirement at all (unlike the old COM transport, which needed
         Claude Desktop and Igor Pro to run at the same privilege level) -- this
         script needing elevation is purely a one-time, install-time requirement of
         its own (pywin32's DLL registration), unrelated to how you run the bridge or
         Igor Pro afterward.
      2. Resolve python.exe (or use -PythonPath).
      3. `<python> -m pip install --upgrade pip`
      4. `<python> -m pip install --require-hashes -r requirements.txt` (pinned,
         hash-verified versions -- see that file's own comments, notably why "mcp" is
         pinned below its new v2 line, and why every transitive dependency is listed
         and hashed too, not just mcp/pyzmq/pywin32 themselves).
      5. Run pywin32's required post-install step
         (Scripts\pywin32_postinstall.py -install), which `pip install pywin32` alone
         does not do -- it registers pywin32's COM-support DLLs. This bridge itself no
         longer uses COM (v2.0.0+), but pywin32 is still a dependency for
         dismiss_compile_error_dialog's window enumeration and for process launching,
         and skipping this step can still leave the install in a broken state.
      6. Import-check mcp, zmq, and win32api/win32gui with the same interpreter, and
         print its full path/version (plus pyzmq's version) for you to cross-check.

    After this script finishes, fully restart Claude Desktop, then call the bridge's
    get_bridge_version tool from a conversation -- its "python_executable" field is
    the authoritative answer for which interpreter Claude Desktop actually launched.
    If it doesn't match what this script installed into, re-run this script with
    -PythonPath pointing at that reported path.

.PARAMETER PythonPath
    Full path to a specific python.exe to install into, bypassing auto-resolution
    entirely. Use this if auto-resolution picks the wrong interpreter, or if you
    already know the right one (e.g. from get_bridge_version()'s "python_executable").

.PARAMETER RequirementsFile
    Path to the requirements.txt to install from. Defaults to requirements.txt next to
    this script.

.EXAMPLE
    .\install.ps1
    Auto-resolve python.exe and install.

.EXAMPLE
    .\install.ps1 -PythonPath 'C:\Python312\python.exe'
    Install into a specific, already-known-correct interpreter.
#>

[CmdletBinding()]
param(
    [string]$PythonPath,
    [string]$RequirementsFile = (Join-Path $PSScriptRoot 'requirements.txt')
)

$ErrorActionPreference = 'Stop'

function Test-IsElevated {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-IsWindowsAppsStub {
    <#
        Detects the Microsoft Store "app execution alias" placeholder for python.exe
        (typically under %LOCALAPPDATA%\Microsoft\WindowsApps\python.exe): a small
        reparse-point stub that, when run without a real Store Python install behind
        it, just opens the Store instead of running anything. A real install (Store
        Python or otherwise) landing in that same folder is not rejected -- only the
        tiny placeholder is, distinguished here by file size.
    #>
    param([string]$Path)

    if ($Path -notlike '*\WindowsApps\*') {
        return $false
    }

    $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    return ($item -and $item.Length -lt 100KB)
}

function Resolve-ClaudeDesktopPython {
    <#
        Mirrors how Claude Desktop's own process resolves the bare command "python"
        from its manifest.json (regardless of whether that process happens to be
        elevated or not -- Machine/User PATH registry values are the same either way),
        without trusting this interactive PowerShell session's own $env:Path -- see
        the script's top-level comment-based help for the full rationale. Returns the
        first matching python.exe found by
        searching the Machine PATH, then the User PATH, in that order (the same
        composition order Windows uses to build a fresh process's environment block),
        or $null if none is found.
    #>
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $combined = @($machinePath, $userPath) -join ';'
    $dirs = $combined -split ';' | Where-Object { $_ }

    foreach ($dir in $dirs) {
        $candidate = Join-Path $dir 'python.exe'
        if ((Test-Path -LiteralPath $candidate) -and -not (Test-IsWindowsAppsStub $candidate)) {
            return (Resolve-Path -LiteralPath $candidate).ProviderPath
        }
    }

    return $null
}

function Invoke-Checked {
    <#
        Runs an external executable and throws if it exits nonzero. Needed because
        PowerShell's $ErrorActionPreference does not apply to native command exit
        codes -- only to PowerShell-native errors -- so failures here would otherwise
        be silently ignored and the script would carry on as if each step succeeded.
    #>
    param(
        [Parameter(Mandatory)][string]$Exe,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    & $Exe @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed (exit code $LASTEXITCODE): `"$Exe`" $($Arguments -join ' ')"
    }
}

# --- 1. Elevation check -----------------------------------------------------------

if (-not (Test-IsElevated)) {
    Write-Error (
        "This script must run elevated (as Administrator) because the pywin32 " +
        "post-install step below registers COM-support DLLs into protected system " +
        "locations, which requires admin rights regardless of how you plan to run " +
        "Claude Desktop/Igor Pro afterward. This is a one-time, install-time " +
        "requirement only -- as of v2.0.0 the bridge talks to Igor Pro over " +
        "ZeroMQ, which has no privilege-matching requirement at all, so neither " +
        "Claude Desktop nor Igor Pro need to be elevated at runtime (see " +
        "igor-pro-bridge.rst, 'Requirements'). Re-run this script from an " +
        "elevated PowerShell (right-click PowerShell -> Run as administrator)."
    )
    exit 1
}

# --- 2. Resolve the target python.exe ----------------------------------------------

if ($PythonPath) {
    if (-not (Test-Path -LiteralPath $PythonPath)) {
        throw "Specified -PythonPath does not exist: $PythonPath"
    }
    $python = (Resolve-Path -LiteralPath $PythonPath).ProviderPath
    Write-Host "Using explicitly specified python: $python"
} else {
    $python = Resolve-ClaudeDesktopPython
    if (-not $python) {
        throw (
            "Could not find python.exe on either the Machine or User PATH " +
            "(registry-level, not this session's own `$env:Path). Install Python " +
            "first, or pass -PythonPath explicitly."
        )
    }
    Write-Host "Auto-resolved python (Machine/User PATH): $python"
    Write-Host (
        "If Claude Desktop actually uses a different interpreter (e.g. one only " +
        "available via a shell profile/conda environment, not the registry PATH " +
        "searched here), re-run this script with -PythonPath after confirming the " +
        "real one via the bridge's get_bridge_version tool (its " +
        "'python_executable' field)."
    )
}

& $python --version
if ($LASTEXITCODE -ne 0) {
    throw "`"$python`" --version failed (exit code $LASTEXITCODE) -- is this a valid Python interpreter?"
}

# --- 3./4. Install pinned requirements ----------------------------------------------

if (-not (Test-Path -LiteralPath $RequirementsFile)) {
    throw "requirements.txt not found at: $RequirementsFile"
}

Write-Host "`nUpgrading pip..."
Invoke-Checked -Exe $python -Arguments @('-m', 'pip', 'install', '--upgrade', 'pip')

Write-Host "`nInstalling pinned, hash-verified packages from $RequirementsFile ..."
# --require-hashes is passed explicitly (pip would already enter hash-checking mode
# automatically the moment any requirement has a --hash) so that if requirements.txt
# is ever accidentally edited down to unhashed entries, this fails loudly with a clear
# pip error instead of silently installing an unverified package.
Invoke-Checked -Exe $python -Arguments @('-m', 'pip', 'install', '--require-hashes', '-r', $RequirementsFile)

# --- 5. pywin32 post-install ---------------------------------------------------------

# Scripts\ is a sibling of python.exe's own directory for both a full Python install
# and a virtual environment -- the standard Windows layout pywin32's installer targets.
$scriptsDir = Join-Path (Split-Path -Parent $python) 'Scripts'
$postInstall = Join-Path $scriptsDir 'pywin32_postinstall.py'

if (-not (Test-Path -LiteralPath $postInstall)) {
    throw (
        "pywin32_postinstall.py not found at expected path: $postInstall -- the " +
        "pywin32 install above may have failed, or landed in an unexpected layout " +
        "for this Python installation."
    )
}

Write-Host "`nRunning pywin32 post-install step ($postInstall -install)..."
Invoke-Checked -Exe $python -Arguments @($postInstall, '-install')

# --- 6. Verify -------------------------------------------------------------------------

Write-Host "`nVerifying the installed packages import correctly..."
# Written to a temp .py file and run as a script, rather than passed via `python -c
# <string>`: PowerShell's argument-quoting for native executables is unreliable for a
# single argument that itself contains both embedded double quotes and newlines (a
# multi-line Python snippet with f-strings hits both) -- confirmed for real, this
# mangled the double quotes around the f-strings below into a Python SyntaxError when
# first tried as `-c $verifyScript`. A temp file sidesteps command-line
# quoting/escaping entirely.
$verifyScript = @'
import importlib.metadata
import sys
import mcp
import zmq
import win32api
import win32gui

print(f"python_executable: {sys.executable}")
print(f"python_version: {sys.version.split()[0]}")
print(f"mcp_package_version: {importlib.metadata.version('mcp')}")
print(f"pyzmq_version: {importlib.metadata.version('pyzmq')}")
print(f"pywin32_build: {importlib.metadata.version('pywin32')}")
print("zmq / win32api / win32gui imports OK")
'@
$verifyScriptPath = Join-Path ([System.IO.Path]::GetTempPath()) "igor-bridge-verify-$([guid]::NewGuid()).py"
try {
    Set-Content -LiteralPath $verifyScriptPath -Value $verifyScript -Encoding utf8
    Invoke-Checked -Exe $python -Arguments @($verifyScriptPath)
} finally {
    Remove-Item -LiteralPath $verifyScriptPath -ErrorAction SilentlyContinue
}

Write-Host (
    "`nDone. Fully restart Claude Desktop, then call the bridge's get_bridge_version " +
    "tool and confirm its 'python_executable' field matches: $python`n" +
    "If it does not match, re-run this script with -PythonPath set to the path " +
    "get_bridge_version() actually reports."
)
