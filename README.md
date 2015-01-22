# General

## Full Installation

* Quit Igor Pro
* Make the VTD2.xop available in Igor Pro
* Create the following shortcuts in "C:\Users\<username>\Documents\WaveMetrics\Igor Pro 6 User Files"
  * In "User Procedures" a shortcut pointing to "Packages\MIES", one to "Packages\Arduino" and one to "Packages\HDF"
  * In "Igor Procedures" a shortcut pointing to Packages\TJ_MIES_Include.ipf
  * In "Igor Extensions" a shortcut pointing to XOPs
  * In "Igor Help File"  a shortcut pointing to HelpFiles
* Start Igor Pro

## Partial Installation without hardware dependencies

There are currently three packages which can be installed on demand:

* The Data Browser (TJ_MIES_DataBrowser.ipf)
* The Wave Builder (TJ_MIES_WaveBuilderPanel.ipf)
* The Downsample Panel (TJ_MIES_Downsample.ipf)

To install one of them perform the following steps:

* Quit Igor Pro
* Create a shortcut to the mentioned procedure file (.ipf) in "C:\Users\<username>\Documents\WaveMetrics\Igor Pro 6 User Files\Igor Procedures"
* Restart Igor Pro

## Building the documentation

### Required 3rd party tools
* [Doxygen](http://doxygen.org) 1.8.7 (exactly this version)
* [Gawk](http://gnuwin32.sourceforge.net/packages/gawk.htm) 3.1.6 or later
* [Dot](http://www.graphviz.org) 2.38 or later

Remember to add all paths with executables from these tools to your `PATH` variable.<br>
You can test that by executing the following statements in a cmd window:

* `doxygen --version`
* `gawk --version`
* `dot -V`
