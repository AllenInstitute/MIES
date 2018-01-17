# General

Our Coding Conventions can be found
[here](http://www.igorexchange.com/project/CodingConventions). Contributions
following these are especially welcome.

## Getting MIES

### Latest development version

* `git clone --recurse-submodules --jobs 2 http://stash.corp.alleninstitute.org/scm/eng/mies-igor.git`

### Latest released version

* Download from [bamboo](http://bamboo.corp.alleninstitute.org/browse/MIES-RELEASE/latestSuccessful) in the "Artifacts" menu.

## Supported versions

* master
* 1.4
* 1.5

For supported versions we fix all critical bugs.

## Bug reporting

Please have a look at ReportingBugs.md.

## Full Installation

Pressure control may be implemented with ITC and/or NIDAQ hardware. For NIDAQ
hardware, install the [NIDAQ Tool MX](https://www.wavemetrics.com/products/nidaqtools/nidaqtools.htm)
package from Wavemetrics.

Install the [Visual C++ Redistributable for Visual Studio 2015](https://www.microsoft.com/en-us/download/details.aspx?id=48145)
packages both for 32bit(x86) and 64bit(x64) in English.

### Igor Pro 7.0.4 or later (64bit only)

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
* Paste the contents of `Packages\doc\releasenotes_template.rst` to the top of `Packages\doc\releasenotes.rst`
* Call `tools\create-changelog.sh` which generate a raw changelog and fill `releasenotes.rst` with a cleaned up version of it.
* Tag the current state with `git tag Release_X.Y_*`, see `git tag` for how the asterisk should look like
* Push the tag: `git push --tags`
* Create the release branches:
	* `git checkout -b release/X.Y`
	* `git push -u origin release/X.Y`
	* `git checkout -b release/X.Y-IVSCC`
	* Patch the IVSCC branch using a commit similiar to e0a9df52 (Remove unneeded NIDAQmx.XOP, 2016-11-10)
	* `git push -u origin release/X.Y-IVSCC`
* Change the bamboo jobs using release branches to use the branch release/X.Y
* Adapt the list of supported versions above

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

### Compilation testing (Igor Pro 7.x 64bit only)
The full MIES installation and the partial installations are IGOR Pro compiled
using a bamboo job. This allows to catch compile time errors early on.<br>
For testing compilation manually perform the following steps:

* Create in `User Procedures` a shortcut pointing to `Packages\MIES_Include.ipf` and `Packages\unit-testing`
* Remove the shortcut `Packages\MIES_Include.ipf` in `Igor Procedures`
* Close all Igor Pro instances
* Execute `tools\compilation-testing\check_mies_compilation.bat`
* Watch the output

### Unit testing
One of the bamboo jobs is responsible for executing our unit tests.
All tests must be written using the [Igor Unit Testing
Framework](http://www.igorexchange.com/project/unitTesting) and referenced in
the main test experiment located in `tools\unit-testing\RunAllTests.pxp`
For executing the tests manually perform the followings steps:

* Create in `User Procedures` a shortcut pointing to `Packages\MIES_Include.ipf`, `Packages\unit-testing` and `Packages\Testing-MIES`
* Remove the shortcut `Packages\MIES_Include.ipf` in `Igor Procedures`
* Close all Igor Pro instances
* Execute `tools\unit-testing\autorun-test.bat`
* Watch the output

### Documentation building
The documentation for the master and the latest release branch,
`release/$number`, are automatically built by
[MIES-BUILD](http://bamboo.corp.alleninstitute.org/browse/MIES-BUILD) and
[MIES-BUILDRELEASE](http://bamboo.corp.alleninstitute.org/browse/MIES-BUILDRELEASE).

### Setting up a continous integration server

#### Preliminaries
* Linux box with fixed IP
* Choose a user, here named `john`, for running the tests.

#### Enable remote access and auto login
* Setup autologin into X for this user. E.g. for `mdm` add the following lines to `/etc/mdm/mdm.conf`:

    ~~~text
    [daemon]
    AutomaticLoginEnable=true
    AutomaticLogin=john
    ~~~

* Restart the PC and test that autologin works.
* Setup remote SSH access with public keys. On the client (your PC!) try logging into using SSH.
  Enable port forwarding (`local: 5900 to localhost:5900`).
* `apt-get install  gawk graphviz pandoc apache2 texlive-full tmux git x11vnc wget`.
* Checkout the mies repository
* Copy the scripts `tools/start*.sh` to `/home/john`.
* Open a ssh terminal, execute `~/start_x11vnc.sh` and try connecting to the remote X session using e.g.
  TightVNC and `localhost:5900` as destination address.

#### Install required software
* (Relevant for Linux Mint 17 Qiana only) Add a file with the following sources in `/etc/apt/sources.list.d/`:

    ~~~text
    deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main
    deb-src http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main
    deb http://ppa.launchpad.net/ubuntu-wine/ppa/ubuntu trusty main
    deb-src http://ppa.launchpad.net/ubuntu-wine/ppa/ubuntu trusty main
    ~~~

* `sudo apt-get update`
* `sudo apt-get install wine openjdk-8-jre`
* Download and install doxygen (version 1.8.12 or later) from [here](http://www.doxygen.org).
* `pip install -U breathe sphinx sphinxcontrib-fulltoc`
* Test if building the mies documentation works.
* Install the script `tools/mies_deploy_documentation.sh` as described in its file header comment.

#### Install Igor Pro
* Install Igor Pro 7 using wine as described [here](http://www.igorexchange.com/node/1098#comment-12432).
  The last tested version was 7.01.

#### Setup bamboo agent
* `wget http://bamboo.corp.alleninstitute.org/agentServer/agentInstaller/atlassian-bamboo-agent-installer-5.14.1.jar`
* `~/start_bamboo_agent.sh`
* In the bamboo web app search the agents list and add the capability `Igor` to the newly created agent.
* Add the line `su -c /home/john/start_bamboo_agent_wrapper.sh john` to `/etc/rc.local`.
  This ensures that the bamboo agent automatically starts after a reboot.
* Reboot the PC and check that `tmux attach bamboo-agent` opens an existing tmux session and that the bamboo agent is running.

#### Bamboo jobs
* Add bamboo jobs requiring the capability `Igor`.
* Done!
