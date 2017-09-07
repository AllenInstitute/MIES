# Manual installation instructions

## Full Installation

The manual installation instructions are here for historical/compatibility
reasons. Whenever possible users should install via the Installer package.

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

## Partial Installation without hardware dependencies
* There are currently four packages located in "Packages\MIES" which can be installed on demand.

### Analysis Browser
* Quit Igor Pro
* Create the following shortcuts in "C:\Users\$username\Documents\WaveMetrics\Igor Pro 7 User Files"
  * In "User Procedures" a shortcut pointing to
    * "Packages\HDF-IP7"
    * "Packages\IPNWB"
  * In "Igor Procedures" a shortcut pointing to
    * "Packages\MIES\MIES_AnalysisBrowser.ipf"
  * In "Igor Extensions (64-bit)" a shortcut pointing to
    * "XOPs-IP7-64bit\HDF5-64.xop"
* Restart Igor Pro

### Data Browser
* Quit Igor Pro
* Create the following shortcuts in "C:\Users\$username\Documents\WaveMetrics\Igor Pro 7 User Files"
  * In "Igor Procedures" a shortcut pointing to
    * "Packages\MIES\MIES_DataBrowser.ipf"
* Restart Igor Pro

### Wave Builder
* Quit Igor Pro
* Create the following shortcuts in "C:\Users\$username\Documents\WaveMetrics\Igor Pro 7 User Files"
  * In "Igor Procedures" a shortcut pointing to
    * "Packages\MIES\MIES_WaveBuilderPanel.ipf"
* Restart Igor Pro

### Downsample
* Quit Igor Pro
* Create the following shortcuts in "C:\Users\$username\Documents\WaveMetrics\Igor Pro 7 User Files"
  * In "Igor Procedures" a shortcut pointing to
    * "Packages\MIES\MIES_Downsample.ipf"
* Restart Igor Pro
