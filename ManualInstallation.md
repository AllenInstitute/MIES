# Manual installation instructions

The manual installation instructions are here for historical/compatibility
reasons. Whenever possible users should install via the Installer package.

## Full Installation

Install the [Visual C++ Redistributable for Visual Studio 2015](https://www.microsoft.com/en-us/download/details.aspx?id=48145)
packages both for 32bit(x86) and 64bit(x64) in English.

### Igor Pro 7.0.4 or later

* Quit Igor Pro
* Create the following shortcuts in "C:\Users\$username\Documents\WaveMetrics\Igor Pro 7 User Files"
  * In "User Procedures" a shortcut pointing to
    * "Packages\Arduino"
    * "Packages\HDF-IP7"
    * "Packages\IPNWB"
    * "Packages\MIES"
    * "Packages\Tango"
  * In "Igor Procedures" a shortcut pointing to Packages\MIES_Include.ipf
  * In "Igor Extensions (64-bit)" a shortcut pointing to
    * "XOPs-IP7-64bit"
    * "XOP-tango-64bit"
  * In "Igor Extensions" a shortcut pointing to
    * "XOPs-IP7"
    * "XOP-tango-IP7"
  * In "Igor Help Files" a shortcut pointing to HelpFiles-IP7
* Start Igor Pro

## Installation without hardware dependencies/XOPs

In case you don't have the hardware connected/available a certain XOP requires
you can also install MIES without any hardware related XOPs present.

### Igor Pro 7.0.4 or later

* Quit Igor Pro
* Create the following shortcuts in "C:\Users\$username\Documents\WaveMetrics\Igor Pro 7 User Files"
  * In "User Procedures" a shortcut pointing to
    * "Packages\Arduino"
    * "Packages\HDF-IP7"
    * "Packages\IPNWB"
    * "Packages\MIES"
    * "Packages\Tango"
  * In "Igor Procedures" a shortcut pointing to Packages\MIES_Include.ipf
  * In "Igor Extensions (64-bit)" a shortcut pointing to
    * "XOPs-IP7-64bit\HDF5-64.xop"
  * In "Igor Extensions" a shortcut pointing to
    * "XOPs-IP7\HDF5.xop"
  * In "Igor Help Files" a shortcut pointing to HelpFiles-IP7
* Start Igor Pro
