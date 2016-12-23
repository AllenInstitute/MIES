# General

## Full Installation

Pressure control may be implemented with ITC and/or NIDAQ hardware.  For NIDAQ
hardware, install the [NIDAQ Tool MX](https://www.wavemetrics.com/products/nidaqtools/nidaqtools.htm)
package from Wavemetrics.

Install the [Visual C++ Redistributable for Visual Studio 2015](https://www.microsoft.com/en-us/download/details.aspx?id=48145)
packages both for 32bit(x86) and 64bit(x64) in English.

### Igor Pro 7.0.1 or later (32bit)

* Quit Igor Pro
* Create the following shortcuts in "C:\Users\$username\Documents\WaveMetrics\Igor Pro 7 User Files"
	* In "User Procedures" a shortcut pointing to
		* "Packages\Arduino"
		* "Packages\HDF-IP7"
		* "Packages\IPNWB"
		* "Packages\MIES"
		* "Packages\Tango"
	* In "Igor Procedures" a shortcut pointing to Packages\MIES_Include.ipf
	* In "Igor Extensions" a shortcut pointing to
		* "XOPs-IP7"
		* "XOP-tango-IP7"
	* In "Igor Help Files"  a shortcut pointing to HelpFiles-IP7
* Start Igor Pro

### Igor Pro 7.0.1 or later (64bit)

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
	* In "Igor Help Files"  a shortcut pointing to HelpFiles-IP7
* Start Igor Pro

## Partial Installation without hardware dependencies
* There are currently four packages (Located in: "..\Packages\MIES") which can be installed on demand:
	* The Analysis Browser (MIES_AnalysisBrowser.ipf), requires the HDF5 XOP to be installed.
	* The Data Browser (MIES_DataBrowser.ipf)
	* The Wave Builder (MIES_WaveBuilderPanel.ipf)
	* The Downsample Panel (MIES_Downsample.ipf)
* To install one of them perform the following steps:
	* Quit Igor Pro
	* In "C:\Users\$username\Documents\WaveMetrics\Igor Pro 7 User Files\Igor Procedures" create a shortcut to the procedure file(s) (.ipf) for the desired package(s)
	* Restart Igor Pro

## Arduino

### Setup
Advanced measurement modes like Yoking require an Arduino for triggering the DAC hardware. The following steps have to be performed in order to get a working setup:

* Get an [Arduino UNO](https://www.arduino.cc/en/Main/ArduinoBoardUno), for easier PIN access a [screw shield](http://www.robotshop.com/en/dfrobot-arduino-compatible-screw-shield.html) comes in handy too
* Connect the device to the PC via USB
* Install the Arduino studio from "Packages\Arduino\arduino-1.6.8-windows.exe"
* Extract "Packages\Arduino\Arduino-libraries-and-sequencer.zip" into "C:\Users\$username\Documents\Arduino"
* Start Arduino studio and try connecting to the device
* Load and compile the installed sequence "Igor_Sequencer3.ino"
* Connect Pin 12 and GND to the trigger input of the DAC hardware

### Usage
* Connect Arduino
* Start Arduino studio and upload "Igor_Sequencer3.ino"
* Start Igor Pro
* Open the panel from the Arduino menu
* Connect
* Upload Sequence
* The start of DAQ is done by MIES itself

## Documentation

Within the Allen Institute, the documentation can be reached at the following locations:

* [Documentation for the master branch](http://10.128.24.29/master/index.html)
* [Documentation for the latest release branch](http://10.128.24.29/release/index.html)

### Building the documentation

#### Required 3rd party tools
* [Doxygen](http://doxygen.org) 1.8.12
* [Gawk](http://sourceforge.net/projects/ezwinports/files/gawk-4.1.3-w32-bin.zip/download) 4.1.3 or later
* [Dot](http://www.graphviz.org) 2.38 or later
* [pandoc](https://github.com/jgm/pandoc/releases) 1.17.1 or later
* [python](http://www.python.org) 2.7 or later
* [breathe](https://github.com/michaeljones/breathe) 4.20 or later, via `pip install -U breathe`
* [sphinx](http://www.sphinx-doc.org/en/stable) 1.4.6 or later, via `pip install -U sphinx`
* [sphinxcontrib-fulltoc](https://sphinxcontrib-fulltoc.readthedocs.io/en/latest/) via `pip install -U sphinxcontrib-fulltoc`

Execute `tools/build-documentation.sh`.

## Release Handling

If guidelines are not followed, the MIES version will be unknown, and data acquisition is blocked.

### Cutting a new release
* Checkout the master branch
* Check that main MIES and all separate modules compile
* Check that doxygen/sphinx/breathe returns neither errors nor warnings
* Adapt the release notes in `Packages\doc\releasenotes.rst`, `tools\create-changelog.sh` allows to generate a changelog as template
* Tag the current state with `git tag Release_X.Y_*`, see `git tag` for how the asterisk should look like
* Push the tag: `git push --tags`
* Create the release branches:
	* `git checkout -b release/X.Y`
	* `git push -u origin release/X.Y`
	* `git checkout -b release/X.Y-IVSCC`
	* Patch the IVSCC branch using a commit similiar to e0a9df52 (Remove unneeded NIDAQmx.XOP, 2016-11-10)
	* `git push -u origin release/X.Y-IVSCC`
* Change the bamboo jobs using release branches to use the branch release/X.Y

### Creating a release package manually
* Open a git bash terminal by choosing Actions->"Open in terminal" in SourceTree
* Checkout the release branch `git checkout release/$myVersion`
* If none exists create one with `git checkout -b release/$myVersion`
* Change to the `tools` directory in the worktree root folder
* Execute `./create-release.sh`
* The release package including the version information is then available as zip file

### Installing a release
* Extract the zip archive into a folder on the target machine
* Follow the steps outlined in the section "Full Installation"

## Continuous integration server
Our [CI server](http://bamboo.corp.alleninstitute.org/browse/MIES), called
bamboo, provides the following services for MIES:

### Automatic release package building
* The release branch, `release/$number` with the highest `$number`, is polled every 3 minutes for changes
* If changes are detected, a shallow clone is fetched, and inside a checked
  out git working tree, the release script `tools/create-release.sh` is executed.
* The result of the release script, called an artifact in CI-speech, is then
  available as zip package from the [Package section](http://bamboo.corp.alleninstitute.org/browse/MIES-RELEASE/latestSuccessful).
* The release packaging job can only be run on a linux box (or on a windows box with git for windows installed).
  This is ensured by a platform requirement for the job.

### Compilation testing (Igor Pro 7.x 32bit only)
The full MIES installation and the partial installations are IGOR Pro compiled
using a bamboo job. This allows to catch compile time errors early on.<br>
For testing compilation manually perform the following steps:

* Create in "User Procedures" a shortcut pointing to Packages\MIES_Include.ipf
* Remove the shortcut Packages\MIES_Include.ipf in "Igor Procedures"
* Close all Igor Pro instances
* Execute `tools\compilation-testing\check_mies_compilation.bat`
* Watch the output

### Documentation building
The documentation for the master and the latest release branch,
`release/$number`, are automatically built by
[MIES-BUILD](http://bamboo.corp.alleninstitute.org/browse/MIES-BUILD) and
[MIES-BUILDRELEASE](http://bamboo.corp.alleninstitute.org/browse/MIES-BUILDRELEASE).
