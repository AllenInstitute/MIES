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

Compilation testing (Igor Pro 7.x 64bit only)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The full MIES installation and the partial installations are IGOR Pro
compiled using a bamboo job. This allows to catch compile time errors
early on. For testing compilation manually perform the following steps:

-  Create in ``User Procedures`` a shortcut pointing to
   ``Packages\MIES_Include.ipf`` and ``Packages\unit-testing``
-  Remove the shortcut ``Packages\MIES_Include.ipf`` in
   ``Igor Procedures``
-  Close all Igor Pro instances
-  Execute ``tools\compilation-testing\check_mies_compilation.bat``
-  Watch the output

Unit testing
~~~~~~~~~~~~

One of the bamboo jobs is responsible for executing our unit tests. All
tests must be written using the `Igor Unit Testing
Framework <http://www.igorexchange.com/project/unitTesting>`__ and
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
uploaded by
`this <http://bamboo.corp.alleninstitute.org/browse/MIES-CM>`__ bamboo
job.

Setting up a continous integration server (Linux)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Preliminaries
^^^^^^^^^^^^^

-  Linux box with fixed IP
-  Choose a user, here named ``john``, for running the tests.

Enable remote access and auto login
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

-  Setup autologin into X for this user. E.g. for ``mdm`` add the
   following lines to ``/etc/mdm/mdm.conf``:

   .. code:: text

       [daemon]
       AutomaticLoginEnable=true
       AutomaticLogin=john

-  Restart the PC and test that autologin works.
-  Setup remote SSH access with public keys. On the client (your PC!)
   try logging into using SSH. Enable port forwarding
   (``local: 5900 to localhost:5900``).
-  ``apt-get install  gawk graphviz pandoc apache2 texlive-full tmux git x11vnc wget``.
-  Checkout the mies repository
-  Copy the scripts ``tools/start*.sh`` to ``/home/john``.
-  Open a ssh terminal, execute ``~/start_x11vnc.sh`` and try connecting
   to the remote X session using e.g. TightVNC and ``localhost:5900`` as
   destination address.
-  Install Multi Clamp Commander from
   `here <http://mdc.custhelp.com/app/answers/detail/a_id/20059/session/L2F2LzIvdGltZS8xNTIyMTU1MzY1L3NpZC9jc3NxKkZJbg%3D%3D>`__
   via ``env WINEPREFIX=$HOME/.wine-igor wine MultiClamp_2_2_2.exe``

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
-  Download and install doxygen (version 1.8.12 or later) from
   `here <http://www.doxygen.org>`__.
-  ``pip install -U breathe sphinx sphinxcontrib-fulltoc``
-  Test if building the mies documentation works.
-  Install the script ``tools/mies_deploy_documentation.sh`` as
   described in its file header comment.

Install Igor Pro
^^^^^^^^^^^^^^^^

-  Install Igor Pro 7 using wine as described
   `here <http://www.igorexchange.com/node/1098#comment-12432>`__. The
   last tested version was 7.01.

Setup bamboo agent
^^^^^^^^^^^^^^^^^^

-  ``wget http://bamboo.corp.alleninstitute.org/agentServer/agentInstaller/atlassian-bamboo-agent-installer-5.14.1.jar``
-  ``~/start_bamboo_agent.sh``
-  In the bamboo web app search the agents list and add the capability
   ``Igor`` to the newly created agent.
-  Add the line ``su -c /home/john/start_bamboo_agent_wrapper.sh john``
   to ``/etc/rc.local``. This ensures that the bamboo agent
   automatically starts after a reboot.
-  Reboot the PC and check that ``tmux attach bamboo-agent`` opens an
   existing tmux session and that the bamboo agent is running.

Bamboo jobs
^^^^^^^^^^^

-  Add bamboo jobs requiring the capability ``Igor``.
-  Done!

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
-  Igor Pro 7 and 8
-  Install bamboo remote agent according to
   http://bamboo.corp.alleninstitute.org/admin/agent/addRemoteAgent.action.
-  Start Igor Pro and open a DA\_Ephys panel, lock the device. This will
   not work, so follow the posted suggestions to get it working.
-  Start the bamboo agent as normal user (not using the NT service)
-  Add a new "Igor Pro" style capability to the agent in bamboo
-  Be sure that the "git" capability and the "bash" capability are
   present as well
