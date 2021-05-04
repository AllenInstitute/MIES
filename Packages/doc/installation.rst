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
  from the within Igor Pro or from the browser.
- Close Igor Pro
- Replace the folders ``IgorBinaries_x64`` and
  ``IgorBinaries_Win32`` in ``C:\Program Files\WaveMetrics\Igor Pro 8/9`` with the
  ones from the downloaded zip package. This requires admin access.
- Restart Igor Pro

Installation using the installer (preferred)
--------------------------------------------

- Install MIES via the installer from `here <https://github.com/AllenInstitute/MIES/releases/tag/latest>`__

Manual Installation
-------------------

The manual installation instructions are here for
historical/compatibility reasons. Whenever possible users should install
via the Installer package.

Install the `Visual C++ Redistributable for Visual Studio 2019
<https://support.microsoft.com/en-us/topic/the-latest-supported-visual-c-downloads-2647da03-1eea-4433-9aff-95f26a218cc0>`__
packages both for 32bit (x86) and 64bit (x64) in English.

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

Manual Installation without hardware dependencies
-------------------------------------------------

In case you don't have the hardware connected/available which some XOPs require, you can also install MIES without any
hardware related XOPs present.

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
      -  ``XOPs-IP8-64bit\JSON-64.xop``
      -  ``XOPs-IP8-64bit\MIESUtils-64.xop``
      -  ``XOPs-IP8-64bit\ZeroMQ-64.xop``

   -  In ``Igor Extensions`` a shortcut pointing to

      -  ``XOPs-IP8\HDF5.xop``
      -  ``XOPs-IP8\JSON.xop``
      -  ``XOPs-IP8\MIESUtils.xop``
      -  ``XOPs-IP8\ZeroMQ.xop``

   -  In ``Igor Help Files`` a shortcut pointing to HelpFiles-IP8

-  Start Igor Pro
