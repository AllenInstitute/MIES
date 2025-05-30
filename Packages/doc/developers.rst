Developer
=========

.. _getting MIES:

Getting MIES
------------

Cloning the MIES repository
~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  ``git clone --recurse-submodules https://github.com/AllenInstitute/MIES``
-  ``./tools/initial-repo-config.sh`` (Requires a Git Bash/Terminal)

If you only want to **use** MIES and not **develop** it, you can also get the source
code via the `release package <https://github.com/AllenInstitute/MIES/releases>`__ as zip file.

Building the documentation
~~~~~~~~~~~~~~~~~~~~~~~~~~

- The script ``tools/build-documentation.sh`` allows to build the documentation locally
- This command also installs the required pip packages, so using a dedicated virtual environment is advised
- Linux users might directly execute the docker version in ``tools/documentation/run.sh``

Updating documentation
~~~~~~~~~~~~~~~~~~~~~~

Due to our excessive use of the breathe sphinx extension which feeds from
doxygen, a full documentation build takes around 10 minutes. It is also not
possible to use the sphinx autobuild feature, as it rebuilds all everything from
scratch due to breathe.

For fast read-write-view cycles while writing the user documentation do the following:

- Start with a clean ``Packages/doc`` folder
- Apply the :download:`patch <0001-WIP-fast-sphinx-rst-update-cycle.patch>`
  which temporarily removes breathe via ``git am ...``
- Call ``make autobuild`` which opens a local webbrowser and rebuilds after
  every change. This time incremental updates work.

Updating requirements files
---------------------------

All python package requirements.txt files we ship must have package hashes
included for improved security.

These files are generated from requirements.in via

  .. code:: text

    pip-compile --generate-hashes --output-file=requirements.txt --strip-extras requirements.in

Therefore updates should be done directly in requirements.in and then calling pip-compile. The platform/OS
needs to be the same when generating the requirements.txt and running them. We currently run all python code
in debian bookworm docker containers. On Windows you can get a debian bookworm with WSL.

Release Handling
----------------

If guidelines are not followed, the MIES version will be unknown, and
data acquisition is blocked.

Cutting a new release
~~~~~~~~~~~~~~~~~~~~~

-  Checkout a new branch ``git checkout -b feature/XXXX-release-notes main``
-  Paste the contents of ``Packages\doc\releasenotes_template.rst`` to
   the top of ``Packages\doc\releasenotes.rst``
-  Call ``tools\create-changelog.sh`` which generate a raw changelog and
   fill ``releasenotes.rst`` with a cleaned up version of it.
   Work from bottom to top.
-  Propose a pull request and get it merged
-  Checkout the main branch
-  Tag the current state with ``git tag Release_X.Y_*``, see ``git tag``
   for how the asterisk should look like
-  Push the tag: ``git push origin $tag``. You can pass ``--dry-run`` for
   testing out what is getting pushed without pushing anything.
-  Create the release branch:

   -  ``git checkout -b release/X.Y``
   -  ``git push --no-verify -u origin release/X.Y``
   -  ``git commit --allow-empty -m "Start of the release X.Y"``

-  Create a new release on github and check that the Github Actions job
   correctly uploads the artifacts

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

Continuous integration server
-----------------------------

Our `CI server <https://github.com/AllenInstitute/MIES/actions>`__, called
Github Actions, provides the following services for MIES:

Automatic release package building
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  If a commit is added to the ``main`` or any ``release/*`` branch a CI
   pipeline is started
-  In this pipeline are some basic tests executed and a new installer is build.
   The installer is uploaded to the corresponging release (``latest`` for
   ``main``).
-  If the commit is added to the ``main`` branch the CI will also create a new
   version of the documentation and deploy it to Github Pages.

Compilation testing
~~~~~~~~~~~~~~~~~~~

The full MIES installation with and without hardware XOPs are IGOR Pro compile
tested using a Github Actions job. This allows to catch compile time errors
early on.

For testing compilation manually perform the following steps:

-  Create in ``User Procedures`` a shortcut pointing to
   ``Packages\MIES_Include.ipf`` and ``Packages\tests``
-  Remove the shortcut ``Packages\MIES_Include.ipf`` in
   ``Igor Procedures``
-  Close all Igor Pro instances
-  Execute ``tools\autorun-test.sh``
-  Watch the output

Unit and integration testing
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A couple of our Github Actions jobs are responsible for executing tests. All
tests are written using the `Igor Pro Universal Testing Framework
<https://docs.byte-physics.de/igortest>`__.

The folders in ``Packages\tests`` follow a common naming scheme. Each folder
holds a separate Igor Experiment with tests. The tests in folders starting with
``Hardware`` requires present hardware, the others don't. In each folder an Igor
Experiment named like the folder with ``.pxp``-suffix is present which allows
to execute all the tests from that folder.

For executing the tests manually perform the followings steps:

- Create in ``User Procedures`` a shortcut pointing to
  ``Packages\MIES_Include.ipf`` and ``Packages\tests``
- Remove the shortcut ``Packages\MIES_Include.ipf`` in ``Igor Procedures``
- Open one of the test experiments in ``Packages\tests``
- Call ``RunWithOpts()``
- Watch the output

The environment variables ``CI_INSTRUMENT_TESTS``/``CI_EXPENSIVE_CHECKS`` allow
to tweak test execution. By default we do expensive tests in CI and
instrumentation in CI for the main branch. Accepted are all numbers but the
values ``0``/``1`` are suggested.

Documentation building
~~~~~~~~~~~~~~~~~~~~~~

The documentation for the main branch is automatically built and uploaded by
`this <https://github.com/AllenInstitute/MIES/actions/workflows/build-main.yml>`__
Github Actions job.

Setting up a continuous integration server (Linux)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Install required software
^^^^^^^^^^^^^^^^^^^^^^^^^

-  Install `Docker <https://docker.io>`__
-  Misc required software: ``dnf install git rg``

Setup Github Actions runner
^^^^^^^^^^^^^^^^^^^^^^^^^^^

-  Install the Github Actions runner according to the
   `instructions <https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners>`__
-  Don't install the runner as a service but use the local user
-  Add a fitting label to the agent in the repository settings at
   Github (see `detailed description <https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/using-labels-with-self-hosted-runners>`)

Setting up a continuous integration runner (Windows, ``ITC`` and ``NI``)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Windows 10 with "Remote Desktop" enabled user
-  Install the folllowing programs:

   -  Git (choose the installer option which will make the Unix tools
      available in cmd as well)
   -  Multiclamp Commander
   -  NIDAQ-mx driver package 19.0 or later
   -  NIDAQ-mx XOP from WaveMetrics
   -  HEKA Harware Drivers 2014-03 Windows.zip
   -  Igor Pro (latest required versions), the binary folder needs to be named ``IgorBinaries_x64_r$revision``
   -  Github Actions runner as described above
   -  VC Redistributable package from ``tools/installer/vc_redist.x64.exe``

-  Start Igor Pro and open a DA\_Ephys panel, lock the device. This will
   not work, so follow the posted suggestions to get it working (registry fix and ASLR fix).
-  Add shortcuts to ``MC700B.exe`` into ``C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp``

Setting up a continuous integration runner (Windows, ``IgorPro``)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  Windows 10 with "Remote Desktop" enabled user
-  Install the folllowing programs:

   -  Git (choose the installer option which will make the Unix tools
      available in cmd as well)
   -  Igor Pro (latest required versions), the binary folder needs to be named ``IgorBinaries_x64_r$revision``
   -  Multiclamp Commander (the MCC library is required to run the non-hardware tests,
      but the application itself does not have to run)
   -  Github Actions runner as described above
   -  VC Redistributable package from ``tools/installer/vc_redist.x64.exe``

Available CI servers
~~~~~~~~~~~~~~~~~~~~

Distributing jobs to agents in Github Actions is done via runner labels. A
runner can have more than one label at the same time and the runner capabilities
is described by the sum of its labels.

The following labels are in use:

- ``self-hosted``: Always use this label to use our own runners

- ``Linux``: Agents run on Linux with

  - Rocky Linux release 8.6 (Green Obsidian)
  - No Hardware
  - No Igor Pro

- ``Docker``: Agents can run docker containers

- ``Windows``: Agents run on Windows with

  - Windows 10

- ``Certificate``: Agent can sign installer packages

  - EV certificate on USB stick

- ``IgorPro``: Can run Igor Pro

  - Igor Pro (latest required versions)

- ``ITC``: Agent can execute hardware tests with ITC18USB hardware

  - ITC18-USB hardware, 2 AD/DA channels are looped
  - MCC demo amplifier only

- ``ITC1600``: Agent can execute hardware tests with ITC1600 hardware

  - ITC-1600 hardware with one rack, 2 AD/DA channels are looped
  - MCC demo amplifier only

- ``NI``: Agent can execute hardware tests with NI hardware

  - NI PCIe-6343, 2 AD/DA channels are looped
  - MCC demo amplifier only

Setting up/Renewing EV certificate
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Our installer is signed with an EV (extended validation) certificate. This is done to pass through antivirus software.
These certificates come on USB tokens which are usable for three years.

The idea for the automation part is from [here](https://stackoverflow.com/a/54439759).
Remember that you have only three tries with a false password!

Renewal process
---------------

- Ask Tim to get a new certificate. Takes around 4 weeks due to heavy administration involvement.
- Exchange the old USB token with the new one
- Physically destroy the old USB token
- Install SafeNet on the machine if not yet done
- As you can't see the token when logged in via Remote Desktop (RDP) you need to workaround that:
- Install Anydesk
- Enable Unattended Access with a strong password
  - Disconnect with RDP
  - Connect with Anydesk
  - Open SafeNet
  - Change the password (the initial one came via email, it needs to be strong but at most 15 characters long)
  - Don't try to change the admin password or unlock the token.
  - Export the public certificate from the `Advanced View -> Tokens -> User certificates` and save in tools/installer/public-key.cer
  - Get the "Container name" as well
  - Store the new password and the new container name in a secure place
  - Checkout the MIES branch with the new public key/certificate
  - `./tools/create-installer.sh`
  - `./tools/sign-installer.sh -p '[]=name'` (name is the "Container name")
  - You should now get asked for the password in a GUI prompt, enter it.
  - Now this should have created a signed installer, if not check the previous steps.
  - Try with `./tools/sign-installer.sh -p '[{{password}}]=name'` this now includes also the password.
  - Now this should have created a signed installer again, but this time without password prompt.
  - If the last step worked, update the `GHA_MIES_CERTIFICATE_PIN` in github and make a PR.
- Disable `Unattended Access` in Anydesk again
- Add a calendar entry for expiration date minus 6 weeks for the certificate renewal

Branch naming scheme
~~~~~~~~~~~~~~~~~~~~

For making code review easier we try to follow a naming scheme for branches behind PRs.

Scheme: ``$prefix/$pr-$text``

Where ``$prefix`` is one of ``feature``/``bugfix``, ``$pr`` is the number of the soon-to-be-created pull request and
``$text`` a user defined descriptive text.

Contributers are encouraged to install the ``pre-push`` git hook from the tools
directory. This hook handles inserting the correct PR number automatically if
the current branch follows the naming scheme ``$prefix/XXXX-$text``.

Continuous Integration Hints
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

As part of the continuous integration pipeline tests are run. A full test run including the hardware tests
tales several hours. Thus, if a lot of pull requests are updated pending test runs could queue up and
it might take rather long until results are available.

Thus, for changes where the commits are in a state where no full test run by the CI makes sense it is
possible to inhibit the automatic tests. Typically this is the case if the developer commits changes
in progress and pushes these for the purpose of a secondary backup or further commit organization.
Inhibiting tests for these cases frees testing resources for other pull requests.

To inhibit test runs the key ``[SKIP CI]`` has to be added to the commit message.

The key can be removed later easily through a rebase with rewording the commit message.
After pushing to the repository the CI queues the tests again for this pull request.

Debugging threadsafe functions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The function ``DisableThreadsafeSupport()`` allows to turn off threadsafe support globally. This allows to use the
debugger in threadsafe functions. Every MIES features which does not complain via ``ASSERT()`` or ``BUG()`` is supposed
to work without threadsafe support as well.

Preventing Debugger Popup
~~~~~~~~~~~~~~~~~~~~~~~~~

There exist critical function calls that raise a runtime error. In well-defined circumstances the error condition is evaluated properly afterwards.
When debugger is enabled and options are set to "Debug On Error", then the Debugger will popup on the line where such functions calls take place.
This is inconvenient for debugging because the error is intended and properly handled. To prevent the debugger to open the coding convention is:

.. code-block:: igorpro

   AssertOnAndClearRTError()
   CriticalFunction(); err = getRTError(1)

Notable the second part that clears the RTE must be in the same line and can not be moved to an own function.
This coding convention is only valid, if the critical function is expected to raise an runtime error.

Runtime Error / Abort Handling Conventions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Here a coding convention for try / catch / endtry constructs is introduced to
prevent common issues like silently clearing unexpected runtime error conditions
by using these.

A try / catch / endtry construct catches by specification either

- Runtime errors when AbortOnRTE is encountered between try / catch
- Aborts when encountered between try / catch

The code must take into account the possibility of runtime errors generated
by bad code. These unexpected RTEs must not be silently cleared.

For the case, where an RTE is expected from CriticalFunction, the common approach is:

.. code-block:: igorpro

   AssertOnAndClearRTError()
   try
       CriticalFunction(); AbortOnRTE
   catch
       err = ClearRTError()
       ...
   endtry

Here pending RTEs are handled before the try. By convention the AbortOnRTE must be
placed in the same function as the try / catch / endtry construct.
The code between try / catch should only include critical function calls and be
kept minimal. The expected RTE condition should be cleared directly after catch.

For the case, where an Abort is expected from CriticalFunction, the common approach is:

.. code-block:: igorpro

   try
       CriticalFunction()
   catch
       ...
   endtry

As Abort does not generate an RTE condition the try / catch / endtry construct
leaves any possible unexpected RTE condition pending and no RTE condition is cleared.
The programmer might consider evaluating ``V_AbortCode`` after catch.

It is recommended to comment in the code before the try what the construct is
intended to handle (RTE, Abort or both).

Retrieving Headstage / Channel Information from the LBN
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you would like to retrieve the settings from the last acquisition then look up function like ``AFH_GetHeadstageFromDAC``.
It retrieves the correct information under the following conditions:

- Data Acquisition is ongoing or
- Data Acquisition has finished and DAEphys panel was not changed.

This function returns NaN if the active DAC had no associated headstage.
The same applies for ``AFH_GetHeadstageFromADC``.

In contrast the functions AFH_GetDACFromHeadstage and AFH_GetADCFromHeadstage return DAC/ADC numbers only for active headstages.

One of the most used functions to retrieve specific information from the LBN is
``GetLastSettingChannel``. The returned wave has NUM_HEADSTAGES + 1 entries.
The first NUM_HEADSTAGES entries refer to the headstages whereas the last entry contains
all headstage independent data.
This is related to the general layout of the LBN, where the headstage is an index of the wave.
In the numerical LBN (``GetLBNumericalValues``) there are columns with DAC/ADC channel information identified by their respective dimension label.
For associated DAC <-> ADC channels the number of the DAC and ADC is present in the layers. The first NUM_HEADSTAGES layers refer to the headstages.

Thus, if headstage 3 uses DAC channel 5 and ADC channel 1 for a sweep then in the LBN
at index 3 in the DAC column a 3 is present and in the ADC column a 1.
Details of the internal data format of the LBN are not required for correct retrieval
of that information as MIES provides functions for that:

.. code-block:: igorpro

   WAVE/Z numericalValues = BSP_GetLBNWave(graph, LBN_NUMERICAL_VALUES, sweepNumber = sweep)
   if(!WaveExists(numericalValues))
      // fitting handling code
   endif
   [WAVE/Z settings, index] = GetLastSettingChannel(numericalValues, $"", sweep, "Indexing", channelNumber, channelType, entrySourceType)

This call specifies a sweep number, a channel type and a channel number and asks for information from the "Indexing" field.
It returns a 1D wave settings and an index, where settings[index] is a Boolean entry telling if indexing was off or on.
The value index itself is the headstage number. The index value can also equal NUM_HEADSTAGES when it refers to a headstage independent value.

To find the ``ADC`` channel from a ``DAC`` channel, the example above can also be setup with channelType = XOP_CHANNEL_TYPE_DAC and LBN entry name "ADC".
This works the same for finding the ``DAC`` channel from a ``ADC`` channel.

If one just wants the headstage number there is an utility function ``GetHeadstageForChannel`` that returns the active headstage for a channel.

The LBN entry ``Headstage Active`` is a Boolean entry and marks which headstage was active in a sweep.
The ``Headstage Active`` can only be set (1) for a headstage that has an associated ``DAC`` and ``ADC`` channel.

Creating LBN entries for tests
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: igorpro

   Make/FREE/N=(1, 1, LABNOTEBOOK_LAYER_COUNT) valuesHSA, valuesDAC, valuesADC
   Make/T/FREE/N=(1, 1, 1) keys

   sweepNo = 0

   // HS 0: DAC 2 and ADC 6
   // HS 1: DAC 3 and ADC 7
   // HS 2+: No DAC/ADC set
   valuesDAC[]  = NaN
   valuesDAC[0][0][0] = 2 // The layer refers to the headstage number
   valuesDAC[0][0][1] = 3
   keys[] = "DAC"
   ED_AddEntriesToLabnotebook(valuesDAC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

   valuesADC[]  = NaN
   valuesADC[0][0][0] = 6
   valuesADC[0][0][1] = 7
   keys[] = "ADC"
   ED_AddEntriesToLabnotebook(valuesADC, keys, sweepNo, device, DATA_ACQUISITION_MODE)

   valuesHSA[]  = 0
   valuesHSA[0][0][0] = 1 // the only valid option here is to set HS 0 and 1 active
   valuesHSA[0][0][1] = 1 // because we did not set ADC/DAC channels for the other HS.
   keys[] = "Headstage Active"
   ED_AddEntriesToLabnotebook(valuesHSA, keys, sweepNo, device, DATA_ACQUISITION_MODE)

The key function here is ``ED_AddEntriesToLabnotebook``. There are no checks applied for this
way of creating LBN entries for tests that guarantee a consistent LBN. e.g. setting headstage 2 to active
in the upper code would violate LBN format schema.
Note that in contrast ``ED_AddEntryToLabnotebook`` is used to add specific user entries to the LBN
and **is not suited** for setting up generic test LBN entries.
More example code can be found in ``PrepareLBN_IGNORE`` in UTF_Labnotebook.ipf.

Adding support for new NI hardware
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Newly added NI hardware must fulfill the following properties:

  - Allow 500kHz sampling rate for one AI/AO channel
  - At least one port of each type: AI/AO/DIO
  - Supported by the NIDAQmx XOP and our use of it

To add new hardware:

  - Visit the `NI <https://ni.com>`__ website and check if the device fullfills our minimum requirements
  - Ask the user to send you the output of :cpp:func:`HW_NI_PrintPropertiesOfDevices()`
  - Add that info to :cpp:var:`NI_DAC_PATTERNS`
  - Update Readme.md
