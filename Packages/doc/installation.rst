.. include:: installation_subst.txt

Installation instructions
=========================

Installing Igor Pro
-------------------

Requirements: Windows 10 64bit

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

- Download the zip package for |IgorPro8Nightly| or |IgorPro9Nightly|. Either
  from within Igor Pro or from the browser.
- Close Igor Pro
- Replace the folders ``IgorBinaries_x64`` and
  ``IgorBinaries_Win32`` in ``C:\Program Files\WaveMetrics\Igor Pro 8/9`` with the
  ones from the downloaded zip package. This requires admin access.
- Restart Igor Pro

Installation using the installer (preferred)
--------------------------------------------

Select the installer for the latest release from `here <https://github.com/AllenInstitute/MIES/releases/tag/latest>`__.

Pressure control may be implemented with ITC and/or NIDAQ hardware. For
NIDAQ hardware, install the `NIDAQ Tool
MX <https://www.wavemetrics.com/products/nidaqtools/nidaqtools.htm>`__
package from Wavemetrics.

Install version 2.2.2 of the Multiclamp Commander (64bit) from `here
<http://mdc.custhelp.com/app/answers/detail/a_id/20059>`__.

Silent installation
~~~~~~~~~~~~~~~~~~~

The installer is developed using `NSIS <https://nsis.sourceforge.io>`__ which also
supports silent installation. The installer requires admin privileges also with
silent installation.

To perform a silent installation pass the `/S` command line option which will
install with the following settings:

- Install for Igor Pro 8 64bit
- Admin installation into `%PROGRAMFILES%\MIES` for the current user, pass `/ALLUSER` to install for all users
- Install all Hardware XOPs

Previously existing MIES installations of the admin will be silently uninstalled.

Installer details and limitations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The installer uses the Nullsoft Installer System `NSIS <https://nsis.sourceforge.io>`__.
NSIS allows to create installers that require admin privileges and installers that
run with user privileges only. By default an installer requiring admin privileges
is created by executing ``tools/create-installer.sh`` from a MingW64 bash.
With ``tools/create-installer.sh 1`` a user mode installer can be created.

The installer tries to detect if and where Igor Pro 8 and/or Igor Pro 9 is installed.
It defaults then to the 64-bit version if the found Igor Pro(s) which is reflected
in the default selection of the corresponding installer dialog. In silent mode the
found defaults are automatically used. If in silent mode no Igor Pro installations are
detected then only the main MIES files get installed.

Installer with admin privileges
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

When run as user the installer asks for privilege elevation.

Installs by default to the user folder e.g. `\\Users\\Admin\\Documents\\MIES folder`.
Igor Pro integration through shortcuts is put to the user Igor Pro procedures/extension folders in
`\\Users\\Admin\\Documents\\WaveMetrics\\Igor Pro X Folder`.

Installs with `/ALLUSER` or corresponding dialog selection to the `\\Program Files\\MIES folder`.
Igor Pro integration through shortcuts is put to the global Igor Pro procedures/extension folders in
`\\Program Files\\Wavemetrics\\Igor Pro X Folder`.

Prior installation it is detected by checking the installed programs list of windows (Apps & Features)
if MIES is already installed. If it is installed then the uninstaller is called first.
If the installation was run silent then the uninstaller is also called silent.

A limitation is that the installer can not detect if another user has a user installation of MIES.
Thus such installation will remain in parallel and result in a double installation for that user (global and local).
The local installation of this user has to be uninstalled. This can be done when the user is logged in through
windows Apps & Features.

Installer with user privileges
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Installs by default to the user folder e.g. `\\Users\\User\\Documents\\MIES folder`.
Igor Pro integration through shortcuts is put to the user Igor Pro procedures/extension folders in
`\\Users\\User\\Documents\\WaveMetrics\\Igor Pro X Folder`.

Installation for all users is not supported as it would require administrative privileges.
Thus the dialog option is greyed out. When `/ALLUSER` is specified an error message is shown.
If `/ALLUSER` and `/S` for silent installation is specified the installer silently quits.

Prior installation it is detected by checking the installed programs list of windows (Apps & Features)
if MIES is already installed. If it is installed then the uninstaller is called first.
If the installation was run silent then the uninstaller is also called silent.
The user can only uninstall previous installations from himself. If the previous installation
was done by an admin the uninstaller will ask for privilege elevation.

Corrupted installations
^^^^^^^^^^^^^^^^^^^^^^^

After the installer has called a potential uninstaller it checks if the target Igor Pro procedures folder
for the MIES integration has no shortcut to MIES. If there still exists a shortcut to MIES then further installation
is aborted. The graphical installer gives a message box requesting a manual cleanup.
Such case typically happens if shortcuts in the Igor Pro folders for integrating MIES were created manually.
Then the shortcuts have to be removed manually first before a MIES installation is run.

Manual Installation
-------------------

The manual installation instructions are here for
historical/compatibility reasons. Whenever possible users should install
via the Installer package.

Install the `Visual C++ Redistributable for Visual Studio 2019
<https://support.microsoft.com/en-us/topic/the-latest-supported-visual-c-downloads-2647da03-1eea-4433-9aff-95f26a218cc0>`__
package for 64bit (x64) in English.

-  Quit Igor Pro
-  Create the following shortcuts in ``C:\Users\$username\Documents\WaveMetrics\Igor Pro 9 User Files``

   -  In ``User Procedures`` a shortcut pointing to

      -  ``Packages\Arduino``
      -  ``Packages\IPNWB``
      -  ``Packages\MIES``

   -  In ``Igor Procedures`` a shortcut pointing to ``Packages\MIES_Include.ipf``

   -  In ``Igor Extensions (64-bit)`` a shortcut pointing to ``XOPs-IP9-64bit``

   -  In ``Igor Help Files`` a shortcut pointing to ``HelpFiles-IP9``

-  Start Igor Pro

Manual Installation without hardware dependencies
-------------------------------------------------

In case you don't have the hardware connected/available which some XOPs require, you can also install MIES without any
hardware related XOPs present.

-  Quit Igor Pro
-  Create the following shortcuts in
   ``C:\Users\$username\Documents\WaveMetrics\Igor Pro 9 User Files``

   -  In ``User Procedures`` a shortcut pointing to

      -  ``Packages\Arduino``
      -  ``Packages\IPNWB``
      -  ``Packages\MIES``

   -  In ``Igor Procedures`` a shortcut pointing to ``Packages\MIES_Include.ipf``

   -  In ``Igor Extensions (64-bit)`` a shortcut pointing to

      -  ``XOPs-IP9-64bit\JSON-64.xop``
      -  ``XOPs-IP9-64bit\MIESUtils-64.xop``
      -  ``XOPs-IP9-64bit\ZeroMQ-64.xop``

   -  In ``Igor Help Files`` a shortcut pointing to HelpFiles-IP9

-  Start Igor Pro
