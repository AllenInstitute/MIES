Installation instructions
=========================

Installing Igor Pro 8
---------------------

Requirements: Windows 10 64bit

- Install `Igor Pro <https://www.wavemetrics.com/downloads/current>`__
- Install the required nightly build: Replace the folders ``IgorBinaries_x64`` and
  ``IgorBinaries_Win32`` in ``C:\Program Files\WaveMetrics\Igor Pro 8`` with the
  ones from `here <https://www.byte-physics.de/Downloads/WinIgor8_24FEB2020.zip>`__

Installation using the installer (preferred)
--------------------------------------------

- Install MIES via the installer from `here <https://github.com/AllenInstitute/MIES/releases/tag/latest>`__

Manual Installation
-------------------

The manual installation instructions are here for
historical/compatibility reasons. Whenever possible users should install
via the Installer package.

Install the `Visual C++ Redistributable for Visual Studio
2015 <https://www.microsoft.com/en-us/download/details.aspx?id=48145>`__
packages both for 32bit(x86) and 64bit(x64) in English.

Igor Pro 8
~~~~~~~~~~

-  Quit Igor Pro
-  Create the following shortcuts in
   ``C:\Users\$username\Documents\WaveMetrics\Igor Pro 8 User Files``

   -  In ``User Procedures`` a shortcut pointing to

      -  ``Packages\Arduino``
      -  ``Packages\IPNWB``
      -  ``Packages\MIES``

   -  In ``Igor Procedures`` a shortcut pointing to
      Packages\MIES_Include.ipf
   -  In ``Igor Extensions (64-bit)`` a shortcut pointing to

      -  ``XOPs-IP8-64bit``

   -  In ``Igor Extensions`` a shortcut pointing to

      -  ``XOPs-IP8``

   -  In ``Igor Help Files`` a shortcut pointing to HelpFiles-IP8

-  Start Igor Pro

Manual Installation without hardware dependencies/XOPs
------------------------------------------------------

In case you don't have the hardware connected/available a certain XOP
requires you can also install MIES without any hardware related XOPs
present.

-  Quit Igor Pro
-  Create the following shortcuts in
   ``C:\Users\$username\Documents\WaveMetrics\Igor Pro 8 User Files``

   -  In ``User Procedures`` a shortcut pointing to

      -  ``Packages\Arduino``
      -  ``Packages\IPNWB``
      -  ``Packages\MIES``

   -  In ``Igor Procedures`` a shortcut pointing to
      ``Packages\MIES_Include.ipf``
   -  In ``Igor Extensions (64-bit)`` a shortcut pointing to

      -  ``XOPs-IP8-64bit\HDF5-64.xop``

   -  In ``Igor Extensions`` a shortcut pointing to

      -  ``XOPs-IP8\HDF5.xop``

   -  In ``Igor Help Files`` a shortcut pointing to HelpFiles-IP8

-  Start Igor Pro
