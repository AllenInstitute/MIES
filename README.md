# General

## Full Installation

* Quit Igor Pro
* Make the VTD2.xop available in Igor Pro
* Create the following shortcuts in "C:\Users\<username>\Documents\WaveMetrics\Igor Pro 6 User Files"
	* In "User Procedures" a shortcut pointing to
		* "Packages\Arduino"
		* "Packages\HDF"
		* "Packages\MIES"
		* "Packages\Tango"
	* In "Igor Procedures" a shortcut pointing to Packages\MIES_Include.ipf
	* In "Igor Extensions" a shortcut pointing to XOPs and XOP-tango
	* In "Igor Help File"  a shortcut pointing to HelpFiles
* Start Igor Pro

## Partial Installation without hardware dependencies
* There are currently four packages (Located in: "....\MIES-Igor-Master\Packages\MIES") which can be installed on demand:
	* The Analysis Browser (MIES_AnalysisBrowser.ipf)
	* The Data Browser (MIES_DataBrowser.ipf)
	* The Wave Builder (MIES_WaveBuilderPanel.ipf)
	* The Downsample Panel (MIES_Downsample.ipf)
* To install one of them perform the following steps:
	* Quit Igor Pro
	* In "C:\Users\<username>\Documents\WaveMetrics\Igor Pro 6 User Files\Igor Procedures" create a shortcut to the procedure file(s) (.ipf) for the desired package(s) 
	* Restart Igor Pro

## Building the documentation

### Required 3rd party tools
* [Doxygen](http://doxygen.org) 1.8.10
* [Gawk](http://gnuwin32.sourceforge.net/packages/gawk.htm) 3.1.6 or later
* [Dot](http://www.graphviz.org) 2.38 or later

Remember to add all paths with executables from these tools to your `PATH` variable.<br>
You can test that by executing the following statements in a cmd window:

* `doxygen --version`
* `gawk --version`
* `dot -V`
