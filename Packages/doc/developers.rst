Developer
=========

Getting MIES
------------

Latest development version from master branch
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  ``git clone https://github.com/AllenInstitute/MIES``
-  ``./tools/initial-repo-config.sh`` (Requires a Git Bash shell, named
   Git terminal in SourceTree)

Installation
------------

Select the installer for the latest release in the next section (Support
statement). For manual installation instructions see `here <manualinstallation>`_.

Pressure control may be implemented with ITC and/or NIDAQ hardware. For
NIDAQ hardware, install the `NIDAQ Tool
MX <https://www.wavemetrics.com/products/nidaqtools/nidaqtools.htm>`__
package from Wavemetrics.

Depending on the bitness (64 or 32) of the Igor Pro version you plan to
use (64-bit is recommended) install either version 2.2.2 of the
Multiclamp Commander (64bit) or version 2.1.0.16 (32-bit). Both can be
downloaded from
`here <http://mdc.custhelp.com/app/answers/detail/a_id/20059>`__.

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

Arduino
-------

Setup
~~~~~

Advanced measurement modes like Yoking require an Arduino for triggering
the DAC hardware. The following steps have to be performed in order to
get a working setup:

-  Get an `Arduino
   UNO <https://www.arduino.cc/en/Main/ArduinoBoardUno>`__, for easier
   PIN access a `screw
   shield <http://www.robotshop.com/en/dfrobot-arduino-compatible-screw-shield.html>`__
   comes in handy too
-  Connect the device to the PC via USB
-  Install the Arduino studio from
   "Packages\\Arduino\\arduino-1.6.8-windows.exe"
-  Extract "Packages\\Arduino\\Arduino-libraries-and-sequencer.zip" into
   "C:\\Users\\$username\\Documents\\Arduino"
-  Start Arduino studio and try connecting to the device
-  Load and compile the installed sequence "Igor\_Sequencer3.ino"
-  Connect Pin 12 and GND to the trigger input of the DAC hardware

Usage
~~~~~

-  Connect Arduino
-  Start Arduino studio and upload "Igor\_Sequencer3.ino"
-  Start Igor Pro
-  Open the panel from the Arduino menu
-  Connect
-  Upload Sequence
-  The start of DAQ is done by MIES itself

Building the documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~

Required 3rd party tools
^^^^^^^^^^^^^^^^^^^^^^^^

-  `Doxygen <http://doxygen.org>`__ 1.8.15
-  `Gawk <http://sourceforge.net/projects/ezwinports/files/gawk-4.1.3-w32-bin.zip/download>`__
   4.1.3 or later
-  `Dot <http://www.graphviz.org>`__ 2.38 or later
-  `python <http://www.python.org>`__ 2.7 or later
-  ``pip install -r Packages\doc\requirements-doc.txt``

Execute ``tools/build-documentation.sh``.

Release Handling
----------------

If guidelines are not followed, the MIES version will be unknown, and
data acquisition is blocked.

Cutting a new release
~~~~~~~~~~~~~~~~~~~~~

-  Checkout the master branch
-  Check that MIES compiles
-  Check that doxygen/sphinx/breathe returns neither errors nor warnings
-  Paste the contents of ``Packages\doc\releasenotes_template.rst`` to
   the top of ``Packages\doc\releasenotes.rst``
-  Call ``tools\create-changelog.sh`` which generate a raw changelog and
   fill ``releasenotes.rst`` with a cleaned up version of it.
-  Tag the current state with ``git tag Release_X.Y_*``, see ``git tag``
   for how the asterisk should look like
-  Push the tag: ``git push --tags``
-  Create the release branches:

   -  ``git checkout -b release/X.Y``
   -  ``git push -u origin release/X.Y``

-  Change the bamboo jobs using release branches to use the branch
   release/X.Y

Creating a release package manually
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Open a git bash terminal by choosing Actions->"Open in terminal" in
   SourceTree
-  Checkout the release branch ``git checkout release/$myVersion``
-  If none exists create one with ``git checkout -b release/$myVersion``
-  Change to the ``tools`` directory in the worktree root folder
-  Execute ``./create-release.sh``
-  The release package including the version information is then
   available as zip file

Installing a release
~~~~~~~~~~~~~~~~~~~~

-  Extract the zip archive into a folder on the target machine
-  Follow the steps outlined in the section "Full Installation"

Continuous integration server
-----------------------------

Our `CI server <http://bamboo.corp.alleninstitute.org/browse/MIES>`__,
called bamboo, provides the following services for MIES:

Automatic release package building
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  The release branch, ``release/$number`` with the highest ``$number``,
   is polled every 3 minutes for changes
-  If changes are detected, a clone is fetched, and inside a checked out
   git working tree, the release script ``tools/create-release.sh`` is
   executed.
-  The result of the release script, called an artifact in CI-speech, is
   then available as zip package from the `Package
   section <http://bamboo.corp.alleninstitute.org/browse/MIES-RELEASE/latestSuccessful>`__.
-  The release packaging job can be run on a linux box or on a windows
   box with git for windows installed. This is ensured by a platform
   requirement for the job.

Compilation testing
~~~~~~~~~~~~~~~~~~~

The full MIES installation and the partial installations are IGOR Pro
compiled using a bamboo job. This allows to catch compile time errors
early on. For testing compilation manually perform the following steps:

-  Create in ``User Procedures`` a shortcut pointing to
   ``Packages\MIES_Include.ipf`` and ``Packages\unit-testing``
-  Remove the shortcut ``Packages\MIES_Include.ipf`` in
   ``Igor Procedures``
-  Close all Igor Pro instances
-  Execute ``tools\unit-testing\check_mies_compilation.sh``
-  Watch the output

Unit testing
~~~~~~~~~~~~

One of the bamboo jobs is responsible for executing our unit tests. All
tests must be written using the `Igor Unit Testing
Framework <https://docs.byte-physics.de/igor-unit-testing-framework>`__ and
referenced in the main test experiment located in
``tools\unit-testing\RunAllTests.pxp`` For executing the tests manually
perform the followings steps:

-  Create in ``User Procedures`` a shortcut pointing to
   ``Packages\MIES_Include.ipf``, ``Packages\unit-testing`` and
   ``Packages\Testing-MIES``
-  Remove the shortcut ``Packages\MIES_Include.ipf`` in
   ``Igor Procedures``
-  Close all Igor Pro instances
-  Execute ``tools\unit-testing\autorun-test.bat``
-  Watch the output

Documentation building
~~~~~~~~~~~~~~~~~~~~~~

The documentation for the master branch is automatically built and
uploaded by `this <http://bamboo.corp.alleninstitute.org/browse/MIES-CM>`__ bamboo job.

Setting up a continous integration server (Linux)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Preliminaries
^^^^^^^^^^^^^

-  Linux box with fixed IP
-  Choose a user, here named ``john``, for running the tests.

Enable SSH access
^^^^^^^^^^^^^^^^^

-  Setup remote SSH access with public keys. On the client (your PC!)
   try logging into using SSH.
-  ``apt-get install python gawk graphviz pandoc texlive-full tmux git wget``.
-  Checkout the mies repository
-  Copy the scripts ``tools/start-bamboo-agent-linux*.sh`` to ``/home/john``.

Install required software
^^^^^^^^^^^^^^^^^^^^^^^^^

-  (Relevant for Linux Mint 17 Qiana only) Add a file with the following
   sources in ``/etc/apt/sources.list.d/``:

   .. code:: text

       deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main
       deb-src http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main
       deb http://ppa.launchpad.net/ubuntu-wine/ppa/ubuntu trusty main
       deb-src http://ppa.launchpad.net/ubuntu-wine/ppa/ubuntu trusty main

-  ``sudo apt-get update``
-  ``sudo apt-get install wine openjdk-8-jre``
-  Download and install doxygen (version 1.8.15 or later) from
   `here <http://www.doxygen.org>`__.
-  ``pip install -r Packages\doc\requirements-doc.txt``
-  Test if building the mies documentation works.

Setup bamboo agent
^^^^^^^^^^^^^^^^^^

-  ``wget http://bamboo.corp.alleninstitute.org/agentServer/agentInstaller/atlassian-bamboo-agent-installer-5.14.1.jar``
-  ``~/start-bamboo-agent.sh``
-  In the bamboo web app search the agents list and add the capability
   ``Igor Pro (new)`` to the newly created agent.
-  Add the line ``su -c /home/john/start_bamboo_agent_wrapper.sh john``
   to ``/etc/rc.local``. This ensures that the bamboo agent
   automatically starts after a reboot.
-  Reboot the PC and check that ``tmux attach bamboo-agent`` opens an
   existing tmux session and that the bamboo agent is running.

Setting up a continous integration server (Windows)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Windows 10 with "Remote Desktop" enabled user
-  Install the folllowing programs:

   -  Java 8
   -  Git (choose the installer option which will make the Unix tools
      available in cmd as well)
   -  Multiclamp Commander (see above for specifics)
   -  NIDAQ-mx driver package 19.0 or later
   -  NIDAQ-mx XOP from WaveMetrics
   -  HEKA Harware Drivers 2014-03 Windows.zip
   -  Igor Pro 8 (and a possible nightly version on top of it)
   -  Install bamboo remote agent according to
      http://bamboo.corp.alleninstitute.org/admin/agent/addRemoteAgent.action.

-  Start Igor Pro and open a DA\_Ephys panel, lock the device. This will
   not work, so follow the posted suggestions to get it working (registry fix and ASLR fix).
-  Add a fitting ``Igor Pro (new)`` capability to the agent in bamboo.
-  Make the agent dedicated to the ``MIES-Igor`` project.
-  Be sure that the "git" capability and the "bash" executable capability are
   present as well
-  Create the folder ``$HOME/.credentials`` and place the file ``github_api_token`` from an existing CI machine there
-  Copy ``tools/start-bamboo-agent-windows.sh`` and ``tools/start-bamboo-agent-windows.bat`` to ``$HOME``
-  Edit ``tools/start-bamboo-agent-windows.bat`` so that is points to the existing Git location
-  Add shortcuts to ``$HOME/start-bamboo-agent-windows.bat`` and ``MC700B.exe`` into ``C:\Users\$User\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup``

Available CI servers
~~~~~~~~~~~~~~~~~~~~

Linux:

- Used for documentation building only
- No Hardware
- No Igor Pro

Windows 10 (1):

- ITC-1600 hardware with one rack, 2 AD/DA channels are looped
- NI PCIe-6343, 2 AD/DA channels are looped
- MCC demo amplifier only
- Latest required nightly version of Igor Pro 8

Windows 10 (2):

- ITC18-USB hardware, 2 AD/DA channels are looped
- MCC demo amplifier only
- Latest required nightly version of Igor Pro 8
