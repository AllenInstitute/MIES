# General

## Full Installation

### Igor Pro 6.3.x (32bit only)

* Quit Igor Pro
* Create the following shortcuts in "C:\Users\<username>\Documents\WaveMetrics\Igor Pro 6 User Files"
	* In "User Procedures" a shortcut pointing to
		* "Packages\Arduino"
		* "Packages\HDF"
		* "Packages\IPNWB"
		* "Packages\MIES"
		* "Packages\Tango"
	* In "Igor Procedures" a shortcut pointing to Packages\MIES_Include.ipf
	* In "Igor Extensions" a shortcut pointing to XOPs
	* In "Igor Extensions" a shortcut pointing to XOP-tango
	* In "Igor Help File"  a shortcut pointing to HelpFiles
* Start Igor Pro

### Igor Pro 7.0.x (32bit)

* Quit Igor Pro
* Create the following shortcuts in "C:\Users\<username>\Documents\WaveMetrics\Igor Pro 7 User Files"
	* In "User Procedures" a shortcut pointing to
		* "Packages\Arduino"
		* "Packages\HDF"
		* "Packages\IPNWB"
		* "Packages\MIES"
		* "Packages\Tango"
	* In "Igor Procedures" a shortcut pointing to Packages\MIES_Include.ipf
	* In "Igor Extensions" a shortcut pointing to XOPs-IP7
	* In "Igor Extensions" a shortcut pointing to XOP-tango
	* In "Igor Help File"  a shortcut pointing to HelpFiles-IP7
* Start Igor Pro

### Igor Pro 7.0.x (64bit)

* Quit Igor Pro
* Create the following shortcuts in "C:\Users\<username>\Documents\WaveMetrics\Igor Pro 7 User Files"
	* In "User Procedures" a shortcut pointing to
		* "Packages\Arduino"
		* "Packages\HDF"
		* "Packages\IPNWB"
		* "Packages\MIES"
		* "Packages\Tango"
	* In "Igor Procedures" a shortcut pointing to Packages\MIES_Include.ipf
	* In "Igor Extensions" a shortcut pointing to XOPs-IP7-64bit
	* Tango XOP is not yet available in 64bit
	* In "Igor Help File"  a shortcut pointing to HelpFiles-IP7
* Start Igor Pro
* Please note that data acquisition is currently not possible with the 64bit version.

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

## Doxygen documentation

The documentation of the master branch is available [here](http://10.128.24.29/master/index.html)

### Building the documentation

#### Required 3rd party tools
* [Doxygen](http://doxygen.org) 1.8.10
* [Gawk](http://sourceforge.net/projects/ezwinports/files/gawk-4.1.3-w32-bin.zip/download) 4.1.3 or later
* [Dot](http://www.graphviz.org) 2.38 or later

Remember to add all paths with executables from these tools to your `PATH` variable.<br>
You can test that by executing the following statements in a cmd window:

* `doxygen --version`
* `gawk --version`
* `dot -V`

## Releasing to non-developer machines

If guidelines are not followed, the MIES version will be unknown, and data acquisition is blocked.

### Creating a release package
- Open a git bash terminal by choosing Actions->"Open in terminal" in SourceTree
- Checkout the release branch `git checkout release/$myVersion`
- If none exists create one with `git checkout -b release/$myVersion`
- Change to the `tools` directory in the worktree root folder
- Execute `./create-release.sh`
- The release package including the version information is then available as zip file

### Installing it
- Extract the zip archive into a folder on the target machine
- Follow the steps outlined in the section "Full Installation"

## Continuous integration server
Our CI server, called bamboo, can be reached [here](http://bamboo.corp.alleninstitute.org/browse/MIES)
and provides the following services for MIES.

### Automatic release package building
* The release branch, `release/$number` with the highest `$number`, is polled every 3 minutes for changes
* If changes are detected, a shallow clone is fetched, and inside a checked
  out git working tree, the release script `tools/create-release.sh` is executed.
* The result of the release script, called an artifact in CI-speech, is then
  available as zip package from the [Package section](http://bamboo.corp.alleninstitute.org/browse/MIES-RELEASE/latestSuccessful).
* The release packaging job can only be run on a linux box (or on a windows box with git for windows installed).
  This is ensured by a platform requirement for the job.
