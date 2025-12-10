.. include:: installation_subst.txt

Installation instructions
=========================

Installing Igor Pro
-------------------

Requirements: Windows 11 64bit or MaxOSX 64bit (analysis only)

- Install `Igor Pro <https://www.wavemetrics.com/downloads/current>`__

Igor Pro Update Nightly
-----------------------

We rely on a fixed intermediate Igor Pro version. This is not available as
installer package but only as zip file.

Update steps
~~~~~~~~~~~~

- When you open a new MIES version you might get the following message in the history:

   .. code:: text

      Your Igor Pro version is too old to be usable for MIES.

and a dialog appears with a button which opens this documentation.

In that case please perform the following steps:

- Download the package for |IgorPro9WindowsNightly| or |IgorPro9MacOSXNightly|.
  Either from within Igor Pro or from a web browser.
- Close Igor Pro
- Windows: Replace the folders ``IgorBinaries_x64`` and ``IgorBinaries_Win32``
           in ``C:\Program Files\WaveMetrics\Igor Pro 9`` with the ones from the
           downloaded zip package. This requires admin access.
- MacOSX: Install from image as usual
- Restart Igor Pro

For Igor Pro 10, download the installer for |IgorPro10WindowsNightly|. This requires access to the beta
program of WaveMetrics.

Installation using the installer (preferred)
--------------------------------------------

Select the installer for the latest release from `here <https://github.com/AllenInstitute/MIES/releases/tag/latest>`__.

Pressure control may be implemented with ITC and/or NIDAQ hardware. For
NIDAQ hardware, install the `NIDAQ Tool
MX <https://www.wavemetrics.com/products/nidaqtools/nidaqtools.htm>`__
package from Wavemetrics.

Install version 2.2.2 of the Multiclamp Commander (64bit) from `here
<http://mdc.custhelp.com/app/answers/detail/a_id/20059>`__.

When using ITC hardware it is necessary to disable ASLR for Igor64.exe.

The installer does include a signed PowerShell script to do so. But this
requires that signed scripts are allowed. You can enable this by running the following command in a PowerShell window, which sets the execution policy to allow only signed scripts for the current user:

.. code:: powershell

   Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope CurrentUser

and that the certificate in `tools/installer/public-key.cer` is added to the certificate store as trusted publisher.

Signed installer
~~~~~~~~~~~~~~~~

Starting with release 2.3 the installer executable is signed with an Extended
Validation (EV) Code Signing certificate. See `Wikipedia
<https://en.wikipedia.org/wiki/Code_signing#Extended_validation_(EV)_code_signing>`__
for more information. Signing the installer should avoid most issues with
antivirus software treating the MIES installer as potentially malicious. The
public key of the certificate can be downloaded from :download:`here
<../../tools/installer/public-key.cer>`.

Silent installation
~~~~~~~~~~~~~~~~~~~

The installer is developed using `NSIS <https://nsis.sourceforge.io>`__ which also
supports silent installation.

To perform a silent installation pass the `/S` command line option which will
install with the following settings:

- Install for Igor Pro 9 64bit
- Admin installation into `%PROGRAMFILES%\MIES` for the current user, pass `/ALLUSER` to install for all users
- Install all Hardware XOPs

Previously existing MIES installations of the admin will be silently uninstalled.

Installer details and limitations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The installer uses the Nullsoft Installer System `NSIS <https://nsis.sourceforge.io>`__.
NSIS allows to create installers that require admin privileges and installers that
run with user privileges only. When executing ``tools/create-installer.sh`` from a MingW64 bash
an installer is build that requests elevated privileges when run.
With an additional argument, like ``tools/create-installer.sh 1``, a user mode installer is created.

It is recommended to use the user mode installer, that is also provided in the regular MIES release.
Elevation can be achieved by running the user mode installer as a user with admin privileges.

The installer tries to detect if and where the required Igor Pro versions are is installed.
If in silent mode no Igor Pro installations are detected then only the main MIES files get installed.

Installing with admin privileges
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

For installation with admin privileges the installer needs to be run as user that is admin.

Thus, the default user mode installer must be run as admin.
If an admin installer was created then it will ask for privilege elevation if required.

Installs by default to the admin user folder e.g. `\\Users\\Admin\\Documents\\MIES folder`.
Igor Pro integration through shortcuts is put to the user Igor Pro procedures/extensions folders in
`\\Users\\Admin\\Documents\\WaveMetrics\\Igor Pro X Folder`.

Installs with `/ALLUSER` or corresponding dialog selection to the `\\Program Files\\MIES` folder.
Igor Pro integration through shortcuts is put to the global Igor Pro procedures/extensions folders in
`\\Program Files\\Wavemetrics\\Igor Pro X Folder`.

Prior installation it is detected by checking the installed programs list of windows (Apps & Features)
if MIES is already installed. If MIES is already installed then the uninstaller is called first without user interaction.
If the installation was run silent then the uninstaller is also called silent.

A limitation is that the installer can not detect if another user has a user installation of MIES.
Thus, such installation will remain in parallel and result in a double installation for that user (global and local).
The local installation of this user has to be uninstalled. This can be done when the user is logged in through
windows Apps & Features or Administrative Templates.

Installing with user privileges
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Installs by default to the user folder e.g. `\\Users\\User\\Documents\\MIES` folder.
Igor Pro integration through shortcuts is put to the users Igor Pro procedures/extensions folders in
`\\Users\\User\\Documents\\WaveMetrics\\Igor Pro X Folder`.

Installation for all users is not supported as it would require administrative privileges.
Thus, the dialog option is greyed out. When `/ALLUSER` is specified an error message is shown.
If `/ALLUSER` and `/S` for silent installation is specified the installer silently quits.

Prior installation it is detected by checking the installed programs list of windows (Apps & Features)
if MIES is already installed. If MIES is already installed then the uninstaller is called first.
If the installation was run silent then the uninstaller is also called silent.
The user can only uninstall previous installations from himself. If the previous installation
was done by an admin for all users the uninstaller quits without uninstalling due to insufficient rights.

List of Installer Return Codes
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

+-------------+---------------------------------------------------------------------------------------------------------------------------------+
| Return Code | Description                                                                                                                     |
+=============+=================================================================================================================================+
| 0           | No Error                                                                                                                        |
| 1           | Another instance of the installer is already running                                                                            |
| 2           | Another instance of the uninstaller is already running                                                                          |
| 3           | Can not retrieve list of currently running processes                                                                            |
| 4           | The installation is run as non-admin user but a MIES installation that was installed with admin privileges is already present.  |
| 5           | Igor.exe is currently running                                                                                                   |
| 6           | Igor64.exe is currently running                                                                                                 |
| 7           | MIES requires a 64-bit operating system                                                                                         |
| 8           | Admin privileges required                                                                                                       |
| 9           | MIES was already manually installed. It needs a manual deinstallation before it can be installed.                               |
| 10          | Could not determine path to Igor 9 executable.                                                                                  |
| 11          | Could not determine path to Igor 10 executable.                                                                                 |
| 12          | The file list for deinstallation could not be written                                                                           |
| 13          | An error occurred when trying to disable ASLR for Igor64.exe (requires for ITC XOP)                                             |
| 14          | The installation configuration could not be written                                                                             |
| 740         | Admin privileges required. The installer was run as regular user with the argument /ALLUSER                                     |
+-------------+---------------------------------------------------------------------------------------------------------------------------------+

Corrupted installations
^^^^^^^^^^^^^^^^^^^^^^^

After the installer has called a potential uninstaller it checks if the target Igor Pro procedures folder
for the MIES integration has no shortcut to MIES. If there still exists a shortcut to MIES then further installation
is aborted. The graphical installer gives a message box requesting a manual cleanup.
Such case typically happens if shortcuts in the Igor Pro folders for integrating MIES were created manually.
Then the shortcuts have to be removed manually first before a MIES installation is run.

Manual Installation
-------------------

The manual installation instructions are here for historical/compatibility
reasons or in case you are on MacOSX. Windows users should always prefer to
install via the Installer package.

Windows (with hardware support)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Install the `Visual C++ Redistributable package
   <https://github.com/AllenInstitute/MIES/blob/main/tools/installer/vc_redist.x64.exe>`__
-  Quit Igor Pro. If you have never opened it, open it once and then close it.
-  Get the MIES source code and initialize the repo, see :ref:`getting MIES`
-  Create the following shortcuts in ``C:\Users\$username\Documents\WaveMetrics\Igor Pro 9 User Files``

   -  In ``User Procedures`` a shortcut pointing to

      -  ``Packages\IPNWB``
      -  ``Packages\MIES``

   -  In ``Igor Procedures`` a shortcut pointing to ``Packages\MIES_Include.ipf``
   -  In ``Igor Extensions (64-bit)`` a shortcut pointing to ``XOPs-IP9-64bit``
   -  In ``Igor Help Files`` a shortcut pointing to ``HelpFiles-IP9``

-  ITC hardware:

   -  Open a powershell console as administrator and execute the following script:

      -  ``Packages\ITCXOP2\tools\Disable-ASLR-for-Igor64.ps1``. This script can also be executed from within
         Igor Pro via ``Mies Panels->Advanced->Turn off ASLR (requires UAC elevation)`` which as the name
         suggests needs an Igor Pro instance started as Administrator.

   -  Install the ITC drivers from Heka
   -  Execute their ``ITCDemoG64.exe`` program as administrator. You should see some cute sinuses.
   -  Open regedit, go to ``HKEY_LOCAL_MACHINE\SOFTWARE\Instrutech``, select ``Permissions...`` from the
      context menu. In the opened window select ``Full Control`` in the ``Allow`` column for ``ALL APPLICATION
      PACKAGES`` for this key and close with ``OK``.

-  NI hardware:

  -  Install the `NI-DAQ mx
     <https://www.ni.com/de/support/downloads/drivers/download.ni-daq-mx.html#559060>`__ package from NI.
  -  Get and install the `NIDAQ Tool MX <https://www.wavemetrics.com/products/nidaqtools/nidaqtools.htm>`__
     package from Wavemetrics.

-  Install version 2.2.2 of the Multiclamp Commander (64bit) from `here <http://mdc.custhelp.com/app/answers/detail/a_id/20059>`__.
-  Start Igor Pro

Windows (without hardware)
~~~~~~~~~~~~~~~~~~~~~~~~~~

In case you don't have the hardware connected/available which some XOPs
require, you can also install MIES without any hardware related XOPs present.

-  Install the `Visual C++ Redistributable package <https://github.com/AllenInstitute/MIES/blob/main/tools/installer/vc_redist.x64.exe>`__
-  Quit Igor Pro
-  Get the MIES source code, see :ref:`getting MIES`
-  Create the following shortcuts in
   ``C:\Users\$username\Documents\WaveMetrics\Igor Pro 9 User Files``

   -  In ``User Procedures`` a shortcut pointing to

      -  ``Packages\IPNWB``
      -  ``Packages\MIES``

   -  In ``Igor Procedures`` a shortcut pointing to ``Packages\MIES_Include.ipf``

   -  In ``Igor Extensions (64-bit)`` a shortcut pointing to

      -  ``XOPs-IP9-64bit\JSON-64.xop``
      -  ``XOPs-IP9-64bit\MIESUtils-64.xop``
      -  ``XOPs-IP9-64bit\ZeroMQ-64.xop``
      -  ``XOPs-IP9-64bit\TUFXOP-64.xop``
      -  ``XOPs-IP9-64bit\mies-nwb2-compound-XOP-64.xop``

   -  In ``Igor Help Files`` a shortcut pointing to HelpFiles-IP9

-  Start Igor Pro

MacOSX (without hardware)
~~~~~~~~~~~~~~~~~~~~~~~~~

Analysis support only. Data acquisition and NWBv2 export are not supported on MacOSx.

-  Quit Igor Pro
-  Get the MIES source code, see :ref:`getting MIES`
-  Create the following symlinks in
   ``/Users/$username/Documents/WaveMetrics/Igor Pro 9 User Files``

   -  In ``User Procedures`` a symlink pointing to

      -  ``Packages/IPNWB``
      -  ``Packages/MIES``

   -  In ``Igor Procedures`` a symlink pointing to ``Packages\MIES_Include.ipf``

   -  In ``Igor Extensions (64-bit)`` a symlink pointing to

      -  ``XOPs-MacOSX-IP9-64bit``

   -  In ``Igor Help Files`` a shortcut pointing to HelpFiles-IP9

-  Start Igor Pro

JSON Configuration folders
~~~~~~~~~~~~~~~~~~~~~~~~~~

MIES supports JSON files for loading and storing panel configurations. Although it is
possible to load files from arbitrary paths manually, one can also put the
files into one of the following folders

-  ``Packages/Settings`` in the installation location

-  ``C:/ProgramData/AllenInstitute/MIES/Settings``

to execute all of them via :menuselection:`MIES Panels --> Automation --> Load standard configuration`
or by pressing :kbd:`CONTROL-1`.
