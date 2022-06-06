Release notes
*************

.. toctree::

Release 2.6
===========

Controls
--------

All added, removed or renamed controls of the main GUIs are listed. These lists are intended to help upgrading the JSON
configuration files. Controls, like GroupBox'es, which can not be read/written with the configuration code are not included.

DA\_Ephys
~~~~~~~~~

Added
^^^^^

None

Removed
^^^^^^^

None

Renamed
^^^^^^^

None

Databrowser
~~~~~~~~~~~

Added
^^^^^

None

Removed
^^^^^^^

None

Renamed
^^^^^^^

None

Wavebuilder
~~~~~~~~~~~

Added
^^^^^

None

Removed
^^^^^^^

None

Renamed
^^^^^^^

None

Sweep Formula
-------------

- Rework builtin help
  - Index with links at the bottom, with back buttons
  - In-Editor help via tooltip
  - Enhance it in various places
- Add basic syntax coloring to Editor
- Enhance test coverag

AnalysisBrowser
---------------

None

DataBrowser
-----------

None

DataBrowser/SweepBrowser
------------------------

- Fix ``Selected`` checkbox in Logbook panel

Dashboard
~~~~~~~~~

- Handle manually stopped sweeps better

DA\_Ephys
---------

None

JSON Configuration
------------------

- Add ``LPF primary output``

Downsample
----------

None

Analysis Functions
------------------

- ``PSQ_Chirp``:

  - Add ``UserOnsetDelay``/``UseTrueRestingMembranePotentialVoltage``/``AsyncQCChannels`` analysis parameter
  - Make ``SamplingMultiplier``/``NumberOfFailedSweeps`` an required analysis parameter

- ``PSQ_SealEvaluation``:

  - Make ``BaselineChunkLength`` a lower limit for WaveBuilder epoch length
    instead of an exact match. This allows to have longer epochs that what is
    used for baseline evaluation.
  - Made SweepFormula execution more robust
  - Make it work with other DACs than zero
  - Make ``SamplingMultiplier``/``BaselineRMSShortThreshold``/``BaselineRMSLongThreshold``
    required analysis parameters
  - Add ``NextIndexingEndStimSetName``/``AsyncQCChannels`` analysis parameter

- Add ``PSQ_AccessResistanceSmoke``

- Add ``PSQ_TrueRestingMembranePotential``

- ``PSQ_PipetteInBath``:

  - Made SweepFormula execution more robust
  - Make ``SamplingMultiplier``/``BaselineRMSShortThreshold``/``BaselineRMSLongThreshold``
    required analysis parameters
  - Add ``NextIndexingEndStimSetName``/``AsyncQCChannels`` analysis parameter

- Allow to change the indexing state in ``POST_DAQ_EVENT``

- ``PSQ_SquarePulse``:

  - Use the correct labnotebook prefix again and not the one for
    ``PSQ_SealEvaluation``. Broken since 1a64ca17 (PSQ_SealEvaluation: Add it,
    2022-02-22).
  - Add ``AsyncQCChannels`` analysis parameter

- ``PSQ_DAScale``:

  - Avoid warning from FitResistance about missing labnotebook keys if the sweep did not pass.
  - Add ``AsyncQCChannels`` analysis parameter

- ``PSQ_Rheobase``:

  - Add ``AsyncQCChannels`` analysis parameter

- ``PSQ_Ramp``:

  - Add ``AsyncQCChannels`` analysis parameter

Foreign Function interface
--------------------------

None

Publisher
---------

- Reorganize ZeroMQ publishing functions and move all of them into :ref:`File MIES_Publish.ipf`
- Add example output for each message
- Publish DAQ/TP start and stop, see also :cpp:func:`PUB_DAQStateChange`. There is no message sent for TP during ITI.

Pulse Average Plot
------------------

None

General
-------

- Fix invalid backup path syntax which newer IP9 versions don't accept
- Remove support for Igor Pro 8
- Use Xoshiro++256 as default pseudo random number generator
- Asynchronous channels: Make them work with NI hardware
- Output special error message on MCC bug where the DA gain is always zero

TUF XOP
-------

None

ITC XOP 2
----------

None

ZeroMQ XOP
----------

None

MCC XOP
-------

None

MIESUtils XOP
-------------

None

Labnotebook
-----------

- Added generic getter functions :cpp:func:`LBN_GetNumericWave` and
  :cpp:func:`LBN_GetTextWave` for input waves required by :cpp:func:`ED_AddEntryToLabnotebook`

New numerical keys
~~~~~~~~~~~~~~~~~~

- ``Get/Set Inter-trial interval``
- ``PSQ_FMT_LBN_AR_ACCESS_RESISTANCE``
- ``PSQ_FMT_LBN_AR_ACCESS_RESISTANCE_PASS``
- ``PSQ_FMT_LBN_AR_STEADY_STATE_RESISTANCE``
- ``PSQ_FMT_LBN_AR_RESISTANCE_RATIO``
- ``PSQ_FMT_LBN_AR_RESISTANCE_RATIO_PASS``
- ``PSQ_FMT_LBN_VM_FULL_AVG``
- ``PSQ_FMT_LBN_VM_FULL_AVG_ADIFF``
- ``PSQ_FMT_LBN_VM_FULL_AVG_ADIFF_PASS``
- ``PSQ_FMT_LBN_VM_FULL_AVG_RDIFF``
- ``PSQ_FMT_LBN_VM_FULL_AVG_RDIFF_PASS``
- ``PSQ_FMT_LBN_VM_FULL_AVG_PASS``
- ``PSQ_FMT_LBN_ASYNC_PASS``
- ``Async Alarm XX State``

New textual keys
~~~~~~~~~~~~~~~~

None

Changed numerical entries
~~~~~~~~~~~~~~~~~~~~~~~~~

None

Changed textual entries
~~~~~~~~~~~~~~~~~~~~~~~

None

Renamed numerical entries
~~~~~~~~~~~~~~~~~~~~~~~~~

None

Renamed textual entries
~~~~~~~~~~~~~~~~~~~~~~~

None

Epoch information
-----------------

- ``EP_GetEpochs``: Allow to query epoch information during ``MID_SWEEP_EVENT``

NWB/IPNWB
---------

None

File format
~~~~~~~~~~~

None

Pressure Control
----------------

None

WaveBuilder
-----------

- Use Xoshiro++266 as pseudo random number generator (PRNG) for new stimsets.
  For compatibility reasons the existing PRNGs are kept for existing stimsets.

Work Sequencing Engine
----------------------

None

Internal
--------

- Add new option ``PROP_GREP`` to :cpp:func:`FindIndizes`
- Update documentation toolchain

Tests
-----

None

Async Framework
---------------

None

Logging
-------

None

Installer
---------

- Remove support for IP8 and add support for IP10 (not yet available though at the time of writing)

Release 2.5
===========

Controls
--------

All added, removed or renamed controls of the main GUIs are listed. These lists are intended to help upgrading the JSON
configuration files. Controls, like GroupBox'es, which can not be read/written with the configuration code are not included.

DA\_Ephys
~~~~~~~~~

Added
^^^^^

None

Removed
^^^^^^^

None

Renamed
^^^^^^^

None

Databrowser
~~~~~~~~~~~

Added
^^^^^

- ``button_sweepformula_all_code``
- ``check_limit_x_selected_sweeps``
- ``popupext_resultsKeys``

Removed
^^^^^^^

- ``button_DataBrowser_setaxis``

Renamed
^^^^^^^

None

Wavebuilder
~~~~~~~~~~~

Added
^^^^^

None

Removed
^^^^^^^

- ``button_WaveBuilder_setaxisA``

Renamed
^^^^^^^

None

Sweep Formula
-------------

- Make ``tp`` more robust
- Add ``store`` operation, see `here <https://alleninstitute.github.io/MIES/SweepFormula.html#store>`__
- We now store all executed code in the results waves with metadata and allow browsing old code again
- Change argument order in ``epochs`` operation to match the order of the ``data`` operation
- Add ``select`` operation as replacement for passing ``channels`` and ``sweeps`` to various operations.
  This now also adds full support for accessing non-displayed sweeps.
- The operations ``data``, ``epochs``, ``tp`` and ``labnotebook`` now accept selections via ``select``.
  For convenience this parameter is optional, this means ``data([100-200])`` now
  returns all displayed data in the range from 100ms to 200ms.

AnalysisBrowser
---------------

None

DataBrowser
-----------

None

DataBrowser/SweepBrowser
------------------------

- Fix placement of textual entries in the logbook graph
- Add option to show only displayed sweeps in logbook graph
- Fix updating textual entries after each new sweep
- Use graph font size of 10 for logbook graph by default
- Always re-execute the sweep formula code when the current selection changes
- Show description of numerical labnotebook entries when hovering over the y-axis label
- Allow resetting the axis scaling via the wellknown ``Ctrl+A`` shortcut in all circumstances with subwindows.
  This makes the reset scaling button superfluous.

Dashboard
~~~~~~~~~

- ``PSQ_Chirp``: Handle missing spike pass wave gracefully
- Convert baseline voltage correctly in debug plotting routine for chirp bounds
- Output more detailed error message on baseline QC failures
- Handle aborted data acquisition better
- Ignore set but disabled analysis functions

DA\_Ephys
---------

- Check free memory when storing every TP
- Fix testpulse caching with NI hardware
- Handle corrupt package settings files and create a default one in this case
- Add optional daily logfile upload (defaults to off)
- Prevent saving incompatible sweep and config wave combinations gracefully
- Fix indexing error when restarting data acquisition during ``PSQ_Ramp`` execution
- Make restarting data acquisition more robust in case it asserts out due to
  lingering runtime errors
- Don't enable "Sweep rollback" on unlocking
- Make the TP power spectrum work again with odd number of rows in the DAQDataWave
- Add a new type of logbook: The results waves, ``textual`` and ``numerical``,
  hold analysis results from Sweep Formula. Their layout is the same as for the
  standard labnotebooks.

JSON Configuration
------------------

None

Downsample
----------

None

Analysis Functions
------------------

- ``PSQ_DAScale``/``PSQ_Rheobase``/``PSQ_Ramp``/``PSQ_Chirp``:

  - Store the ``PSQ_FMT_LBN_TARGETV`` value with the correct amplitude. Broken since
    0a86df51 (PSQ Analysis functions: Store the baseline voltage when
    evaluated, 2021-01-15).

- ``PSQ_Chirp``:

  - Handle scalingFactor of zero gracefully
  - Bugfix: Use correct conversion from V to mV in production code
  - Add support for setting autobias target voltage

- ``PSQ_PipetteInBath``:

  - Handle turned on overlay sweeps correctly
  - Use correct conversion value for storing ``PSQ_FMT_LBN_PB_RESISTANCE``.
    Broken since 6e32699f (PSQ_PipetteInBath: Add it, 2021-12-08).

- Add ``PSQ_SealEvaluation``

- Analysis functions can now read and write epoch information also during the post sweep and set event, see
  see :ref:`here <File MIES_AnalysisFunctions.ipf>`.

- Add ``PSQ_PipetteInBath``

Foreign Function interface
--------------------------

None

Pulse Average Plot
------------------

None

General
-------

- Require newer IP9 versions to fix some stability issues

TUF XOP
-------

- Add XOP

ITC XOP 2
---------

- Automatically retry opening devices with ITC1600 hardware in known error
  situations, see also `here <https://github.com/AllenInstitute/ITCXOP2/pull/16>`__.

ZeroMQ XOP
----------

None

MCC XOP
-------

None

MIESUtils XOP
-------------

None

Labnotebook
-----------

- The units of all user entries written in the analysis functions are now
  documented :ref:`here <File MIES_AnalysisFunctions_PatchSeq.ipf>` and
  :ref:`here <File MIES_AnalysisFunctions_MultiPatchSeq.ipf>`

- We now store additional values for each numerical labnotebook entry:
  - Description
  - Headstage contingency
  - Applicable clamp modes

  See :ref:`here <Table Numerical Labnotebook Description>` for the generated table with all stock numerical entries

New numerical keys
~~~~~~~~~~~~~~~~~~

- ``PSQ_FMT_LBN_LEAKCUR_PASS``
- ``PSQ_FMT_LBN_LEAKCUR``
- ``PSQ_FMT_LBN_PB_RESISTANCE_PASS``
- ``PSQ_FMT_LBN_PB_RESISTANCE``
- ``PSQ_FMT_LBN_SE_RESISTANCE_A``
- ``PSQ_FMT_LBN_SE_RESISTANCE_B``
- ``PSQ_FMT_LBN_SE_RESISTANCE_MAX``
- ``PSQ_FMT_LBN_SE_RESISTANCE_PASS``
- ``PSQ_FMT_LBN_SE_TESTPULSE_GROUP``

New textual keys
~~~~~~~~~~~~~~~~

- ``Follower Device``: Always add it, even if empty

Changed numerical entries
~~~~~~~~~~~~~~~~~~~~~~~~~

- ``PSQ_FMT_LBN_INITIAL_SCALE``: Remove unit
- ``MSQ_FMT_LBN_SPIKE_COUNTS``: Remove unit
- ``MSQ_FMT_LBN_ACTIVE_HS``: Add ``LABNOTEBOOK_BINARY_UNIT`` as unit

The following entries now have a correct ``-`` (LABNOTEBOOK_NO_TOLERANCE) as tolerance:

  - ``Serial Number``
  - ``Channel ID``
  - ``ComPort ID``
  - ``AxoBus ID``
  - ``Operating Mode``
  - ``Scaled Out Signal``
  - ``Alpha``
  - ``Scale Factor``
  - ``Scale Factor Units``
  - ``LPF Cutoff``
  - ``Membrane Cap``
  - ``Ext Cmd Sens``
  - ``Raw Out Signal``
  - ``Raw Scale Factor``
  - ``Raw Scale Factor Units``
  - ``Hardware Type``
  - ``Secondary Alpha``
  - ``Secondary LPF Cutoff``
  - ``Slow current injection settling time``
  - ``TP Amplitude VC``
  - ``TP Amplitude IC``
  - ``TP Pulse Duration``

Changed unit to ``MΩ`` from ``MOhm`` for the following entries:

  - ``TP Peak Resistance``
  - ``TP Steady State Resistance``
  - ``Whole Cell Comp Resist``
  - ``Bridge Bal Value``
  - ``Series Resistance``
  - ``Minimum TP resistance for tolerance``

Remove ``a. u.`` units for the following entries:

  - ``Sweep Rollback``
  - ``Skip Sweeps``
  - ``DAC``
  - ``ADC``
  - ``Set Sweep Count``
  - ``TTL rack zero channel``
  - ``TTL rack one channel``
  - ``Repeat Sets``
  - ``Sampling interval multiplier``
  - ``Stim set length``
  - ``Repeated Acq Cycle ID``
  - ``Stim Wave Checksum``
  - ``Sampling interval multiplier``
  - ``Set Cycle Count``
  - ``Stimset Acq Cycle ID``
  - ``Digitizer Hardware Type``
  - ``Clamp Mode``
  - ``Igor Pro bitness``
  - ``DA ChannelType``
  - ``AD ChannelType``
  - ``Autobias %``
  - ``Epochs version``

Changed textual entries
~~~~~~~~~~~~~~~~~~~~~~~

None

Renamed numerical entries
~~~~~~~~~~~~~~~~~~~~~~~~~

None

Renamed textual entries
~~~~~~~~~~~~~~~~~~~~~~~

None

Epoch information
-----------------

- Always shorten too long user epoch entries, even if acquisition finished as planned
- Clip oodDAQ region epochs to the available stimset length
- Fix the unacquired epoch length when too long user epochs are present

NWB/IPNWB
---------

- Export results waves into NWBv2

File format
~~~~~~~~~~~

None

Pressure Control
----------------

None

WaveBuilder
-----------

- Make saving stimsets faster by avoiding duplicated update calls
- Avoid deleting existing stimsets on save errors due to analysis function parameter checks
- Keep selected x-axis range on display update
- Allow resetting the axis scaling via the wellknown ``Ctrl+A`` shortcut in all circumstances with subwindows.
  This makes the reset scaling button superfluous.

Work Sequencing Engine
----------------------

- Add wrappers for toggling ``Store every testpulse``
- ``IVS_RunGigOhmSealQC`` now runs the ``PSQ_SealEvaluation`` analysis function
- ``IVS_runBaselineCheckQC`` now runs the ``PSQ_PipetteInBath`` analysis function
- Fix returned sweep number in published zeromq messages

Internal
--------

- Upgrade IUTF to a version which also support code coverage for macros
- Add development hints for writing analysis functions, see :ref:`here <File analysis-function-writing.rst>`
- Add linting tool in ``tools/check-code.sh`` to avoid common issues
- Add the full stacktrace to the log entries for ``BUG`` and ``BUG_TS``
- Add threadsafe variant ``BUG_TS``
- Make the extended GUI popup menu names work also with non-liberal input names
- Add constants XXX_TO_YYY for converting between different decimal
  multipliers for values with units :ref:`here <File MIES_ConversionConstants.ipf>`.
  Using that is also enforced with additional checks in ``tools/check-code.sh``.

Tests
-----

- Add tests for TPStorage wave
- Add generic range checks for USER labnotebook entries in the PSQ analysis functions
- Skip outdated deployment on main branch
- Make the tests work with a real amplifier and model cell
- Check amplifier presence before locking
- Only perform expensive checks in CI
- Create code coverage reports from tests on the main branch

Async Framework
---------------

None

Logging
-------

None

Installer
---------

- Install TUF XOP without hardware XOPs

Release 2.4
===========

Controls
--------

All added, removed or renamed controls of the main GUIs are listed. These lists are intended to help upgrading the JSON
configuration files. Controls, like GroupBox'es, which can not be read/written with the configuration code are not included.

DA\_Ephys
~~~~~~~~~

Added
^^^^^

- ``check_TP_SendToAllHS``
- ``check_DataAcq_AutoTP``
- ``setvar_DataAcq_IinjMax``
- ``setvar_DataAcq_targetVoltage``
- ``setvar_DataAcq_targetVoltageRange``
- ``setvar_Settings_autoTP_int``
- ``setvar_Settings_autoTP_perc``

Removed
^^^^^^^

None

Renamed
^^^^^^^

None

Databrowser
~~~~~~~~~~~

Added
^^^^^

- ``button_sweepFormula_tofront``

Removed
^^^^^^^

None

Renamed
^^^^^^^

None

Wavebuilder
~~~~~~~~~~~

Added
^^^^^

None

Removed
^^^^^^^

None

Renamed
^^^^^^^

None

Sweep Formula
-------------

- Allow ``=`` in strings
- Add ``epoch`` command to extract epoch information, see the `documentation
  <https://alleninstitute.github.io/MIES/SweepFormula.html#epochs>`__
- Fix bugs in comment character (``#``) handling
- Add ``and`` keyword to create multiple graphs from one session, see the
  `documentation <https://alleninstitute.github.io/MIES/SweepFormula.html#multiple-graphs>`__
- Improved error handling and made parsing more robust
- Fixed handling of ``,`` and use a more consistent parsing strategy
- Fix plotting of 2D vs 0D data
- Heavily revised the documentation
- ``data`` now accepts an epoch short name as range

AnalysisBrowser
---------------

None

DataBrowser
-----------

None

DataBrowser/SweepBrowser
------------------------

- Make browsing old labnotebooks prior to 5c9a5e4c (Add "Acquisition State" as
  default labnotebook entry, 2020-11-27) work again
- Show the tree level in epoch visualization tooltips as well
- Require the modifier key ``ALT`` for changing sweeps with the mouse wheel
- Use a separate axis for displaying epoch information and don't require DA data to be shown anymore
- Make overlay sweeps selections faster
- Allow selecting sweeps and set sweep/cycle counts
- Select a better default x axis when displaying TPStorage data without any acquired sweeps
- Preselect device and experiment in the SweepBrowser for enhanced usability

Dashboard
~~~~~~~~~

- Support sampling frequency QC failure

DA\_Ephys
---------

- Fix updating indexing metadata on changing stimsets in the DA tab with the ALL popup menues
- Handle adding new stimsets when the DA/TTL tabs already had some selected better
- Use the correct GUI procedure for Popup_Settings_DecMethod
- Fix some edge cases where pending comments in the SetVariable or the comment
  notebook were not handled correctly. The fallout was that these comments were
  not saved to NWB.
- Use 35% as default baseline for the Testpulse
- Added Auto testpulse adaptation, see the `documentation
  <https://alleninstitute.github.io/MIES/auto_testpulse_tuning.html>`__. This
  also added the following new entries to TPStorage: ``TPCycleID``,
  ``AutoTPAmplitude``, ``AutoTPBaseline``, ``AutoTPBaselineRangeExceeded``,
  ``AutoTPCycleID``, ``AutoTPBaselineFitResult``, ``AutoTPDeltaV``
- Avoid creating the ITC1600 Device 0 path for yoking if not needed

JSON Configuration
------------------

- Switch back to Headstage 0 after configuration
- Assert out on missing or invalid stimulus set file

Downsample
----------

None

Analysis Functions
------------------

- ``PSQ_DAScale``/``PSQ_SquarePulse``/``PSQ_Rheobase``/``PSQ_Ramp``/``PSQ_Chirp``:

  - Enforce that we have the expected sampling frequency of 50kHz. See the
    analysis function parameters ``SamplingMultiplier`` and
    ``SamplingFrequency`` to accomodate other hardware than ITC.

  - Make setting the ``SamplingMultiplier`` more robust. Previously it was not
    always set due to a combination of three unrelated bugs.

  - Make the baseline QC RMS long/short thresholds configurable via the
    analysis parameters ``BaselineRMSShortThreshold`` and ``BaselineRMSLongThreshold``.
    The used values are written into the labnotebook as well.

  - The time slices used for baseline QC (called chunks in MIES) are now stored
    as user epochs with the tag ``Name=Baseline Chunk;Index=<X>;ShortName=U_BLC<X>``.

- It is now possible to add user epochs in the ``PRE_SWEEP_CONFIG_EVENT`` and
  the ``PRE_SET_EVENT`` events in addition to the ``MID_SWEEP_EVENT``.

- ``PSQ_Ramp``: Add user epochs for the unacquired data region due to the restart during DAQ

- ``PSQ_Chirp``:

  - Fix pulse retrieval for certain edge cases of epoch information
  - Baseline QC is now always done, even if the spike check fails
  - Complain if ``NumberOfFailedSweeps`` is larger than the number of sweeps in the stimset
  - Add ``BoundsEvaluationMode`` to selectively evaluate only lower or upper parts of the chirp
  - Rename ``LowerRelativeBound``/``UpperRelativeBound`` to ``InnerRelativeBound``/``OuterRelativeBound``

- ``SC_SpikeControl``: Enhance reaction to too-many failed spikes and add
  the new ``DaScaleTooManySpikesOperator`` and ``DaScaleTooManySpikesModifier``
  analysis parameters.

- Introduce a new signature for ``XXX_CheckParam`` functions. The old signature
  is still supported, see also `here <https://alleninstitute.github.io/MIES/file/_m_i_e_s___analysis_functions_8ipf.html>`__.

Foreign Function interface
--------------------------

- New ZeroMQ messages on clamp mode switch, auto TP success/fail, pressure breakin, amplifier auto bridge balance

Pulse Average Plot
------------------

None

General
-------

- Remove support for 32bit Igor Pro versions
- Better inform users about the next steps when trying to turn of ASLR for ITC hardware
- PGC_SetAndActivateControl: Require valid values for popup menus and sliders
- PGC_SetAndActivateControl: Make setting a disabled control an error by default
- Nicified the HTML documentation a bit

ITC XOP 2
----------

None

ZeroMQ XOP
----------

None

MCC XOP
-------

None

MIESUtils XOP
-------------

None

Labnotebook
-----------

New numerical keys
~~~~~~~~~~~~~~~~~~

- ``PSQ_FMT_LBN_SAMPLING_PASS``: Pass/Fail state of the sampling interval check
- ``PSQ_FMT_LBN_RMS_SHORT_PASS``: Short RMS baseline threshold [V]
- ``PSQ_FMT_LBN_RMS_LONG_PASS``: Long RMS baseline threshold [V]
- ``TP Auto On/Off``
- ``TP Auto max current``
- ``TP Auto voltage``
- ``TP Auto voltage range``
- ``TP buffer size`` (INDEP_HEADSTAGE)
- ``Minimum TP resistance for tolerance`` (INDEP_HEADSTAGE)
- ``Send TP settings to all headstages`` (INDEP_HEADSTAGE)
- ``TP Auto percentage`` (INDEP_HEADSTAGE)
- ``TP Auto interval`` (INDEP_HEADSTAGE)
- ``TP Auto QC``
- ``TP Cycle ID``

New textual keys
~~~~~~~~~~~~~~~~

None

Changed numerical entries
~~~~~~~~~~~~~~~~~~~~~~~~~

- ``Set Cycle Count``: This was previously erroneously set to ``0`` for TP
  channels, it is now always ``NaN`` in this case.
- ``TP buffer size``: Is now only present when the TP ran and therefore uses
  ``TEST_PULSE_MODE`` as entrySourceType
- ``TP Amplitude IC``: New unit ``mV``
- ``TP Amplitude VC``: New unit ``pA``

Changed textual entries
~~~~~~~~~~~~~~~~~~~~~~~

None

Renamed numerical entries
~~~~~~~~~~~~~~~~~~~~~~~~~

None

Renamed textual entries
~~~~~~~~~~~~~~~~~~~~~~~

None

Epoch information
-----------------

- Add short names for all stock epochs in the format ``ShortName=XX``. This allows to use names like ``TP`` in
  the sweepformula ``epochs`` command instead of the complete tag. See `here
  <https://alleninstitute.github.io/MIES/epoch_information.html#naming>`__ for the detailed documentation.
- Don't add epoch information for third-party stimsets or for TP during DAQ simsets
- Handle prematurely stopped sweeps better. The epochs are now shortend to only
  cover really acquired data. Epochs which are completely outside the acquired
  data are dropped. Unacquired data is now also properly tagged with the
  special epoch ``Unacquired data``.
- Disallow some characters in epoch tags
- Add support for user epochs via ``EP_AddUserEpoch``, see the `documentation
  <https://alleninstitute.github.io/MIES/file/_m_i_e_s___epochs_8ipf.html#_CPPv415EP_AddUserEpoch6string8variable8variable8variable8variable6string6string>`__.
- Revise naming so that we now have always key value pairs like ``A=B`` and also a more uniform naming.

NWB/IPNWB
---------

- Export MIES epoch information into NWBv2 files. The epoch information is
  stored in ``/intervals/epochs``. See :ref:`epoch_information_doc` for the
  epoch documentation and code examples how to read it.
- Store the Zero MQ XOP logfile as well if present
- Only store logfile entries from the same day and not the whole files

File format
~~~~~~~~~~~

None

Pressure Control
----------------

None

WaveBuilder
-----------

- Fixed recreation of third party stimsets

Work Sequencing Engine
----------------------

- Return success/fail state from ``IVS_ExportAllData``

Internal
--------

- Added mies-nwb2-compound XOP for writting epoch information into NWBv2 files
- Fixed and documented the best approach for try/catch situations
- GetLastSettingChannel: Make returning INDEP_HEADSTAGE entries work again
- GetSweepsWithSetting: Don't return invalid sweep numbers
- Updated JSON XOP
- Rewrote much of the testpulse settings code during testpulse runs for auto testpulse
- Upgraded documentation toolchain
- Use a proper name for the DAQ device in the code instead of panelTitle

Tests
-----

- Add epoch consistency checks to all tests with hardware
- Use the best test assertion for each case and avoid constructs like CHECK(1 == i)
- Some test cases were failing with ITC1600 hardware

Async Framework
---------------

None

Logging
-------

None

Installer
---------

- Sign the installer with an EV code signing certificate. This should avoid
  most problems with antivirus and security software. See `here
  <https://alleninstitute.github.io/MIES/installation.html#signed-installer>`_
  for details.
- Always install the ZeroMQ XOP

Release 2.3
===========

Controls
--------

All added, removed or renamed controls of the main GUIs are listed. These lists are intended to help upgrading the JSON
configuration files. Controls, like GroupBox'es, which can not be read/written with the configuration code are not included.

DA\_Ephys
~~~~~~~~~

None

Databrowser/Sweepbrowser
~~~~~~~~~~~~~~~~~~~~~~~~

Added
^^^^^

- ``check_BrowserSettings_VisEpochs``
- ``popup_Device``
- ``popup_experiment``
- ``popupext_TPStorageKeys``

Removed
^^^^^^^

None

Renamed
^^^^^^^

None

Wavebuilder
~~~~~~~~~~~

Added
^^^^^

None

Removed
^^^^^^^

- ``setvar_explDeltaValues_T12``

Renamed
^^^^^^^

None

Sweep Formula
-------------

None

AnalysisBrowser
---------------

- Display the exact file type in the listbox
- Allow resaving an NWBv1 file as NWBv2

DataBrowser
-----------

- Make selecting the first existing sweep on locking more robust

DataBrowser/SweepBrowser
------------------------

- Make deleting the datafolder on panel close more reliable
- Allow browsing TPStorage/Labnotebook waves. This also makes the dedicated
  panels for the sweepbrowser unnecessary and these have been removed.
- Make the labnotebook key menues better viewable with a lot (> 400) of entries
- Make epoch viewing generally available for users (IP9 only)
- Revamp settings tab

Dashboard
~~~~~~~~~

- Make the failure messages for PSQ analysis functions more robust and include per sweep information
- Disable/Enable the Passed Sweeps/Failed Sweeps checkboxes with the Dashboard Enable checkbox
- Handle bogus sweep data without "Baseline QC" entry better
- Show result message for prematurely stopped sweeps

DA\_Ephys
---------

- Allow `PCIe-6341` as new NI device for data acquisition
- Read NWB version correctly for per-sweep NWB export
- Try restarting DAQ/TP automatically on mismatched MCC gains instead of telling the user to do it

JSON Configuration
------------------

None

Downsample
----------

None

Analysis Functions
------------------

- Fix ``PSQ_DAScale``/``PSQ_Chirp`` failing to work with headstage numbers different than zero
- Remove ``PRE_SWEEP_EVENT`` and repurpose it as ``PRE_SWEEP_CONFIG_EVENT``. Users
  had difficulties using ``PRE_SWEEP_EVENT`` as that happened after configuring
  the sweep and thus did not allow tweaking settings for the current sweep
  anymore. We therefore decided to remove that event and repurpose it as
  ``PRE_SWEEP_CONFIG_EVENT`` which is now issued before the sweep is configured.
  See the `analysis function <https://alleninstitute.github.io/MIES/file/_m_i_e_s___analysis_functions_8ipf.html>`_
  documentation.
- Teach ````SetControlInEvent```` to accept ````Pre Sweep```` entries as ````Pre Sweep Config```` entries but warn users
- ````PSQ_DAScale````: Find the correct last passing rheobase sweep
- Add ````AFH_GetHeadstageFromActiveADC````
- Rework decision logic for post pulse baseline chunks. These could have been erroneously failed in edge cases.
- ````PSQ_Chirp````: Use the fitted resistance instead of the resistance at a single point

Foreign Function interface
--------------------------

None

Pulse Average Plot
------------------

- Make updating the scale bars more robust

General
-------

- Update manual installation instructions
- Add a pull request template for github
- Check also some common debug defines in the installation check
- Allow downloading stimsets from `DANDI <https://gui.dandiarchive.org>`_
- Add new acquisition state ``AS_PRE_SWEEP_CONFIG``
- MIES now requires the released version of Igor Pro 9, instead of supporting
  an intermediate beta version. Igor Pro 8 is still supported but
  support for it will be removed in one of the next releases.
- Add cell state as new entry into TPStorage

ITC XOP 2
----------

None

ZeroMQ XOP
----------

None

MCC XOP
-------

None

MIESUtils XOP
-------------

None

Labnotebook
-----------

- The labnotebook waves are upgraded so that all keys are valid liberal object names (required by Igor Pro 9). This
  required invalid keys to be renamed. See below for a list of renamed stock entries.
  Also user entries are renamed as well.
- Error out when trying to add labnotebook entries with invalid keys

New numerical keys
~~~~~~~~~~~~~~~~~~

- ``TP after DAQ``: If the testpulse is run after data acquisition or not
- ``DAQ stop reason``: Enumeration value explaining why data acquisition was stopped, see `DQ_STOP_REASON
  <https://alleninstitute.github.io/MIES/file/_m_i_e_s___constants_8ipf.html#_CPPv425DQ_STOP_REASON_DAQ_BUTTON>`__ for
  all possible values.
- ``Epochs Version``: Version of the epoch information
- Add the version of the major builtin analysis functions to the labnotebook:

  - ``USER_Chirp version``
  - ``USER_DA Scale version``
  - ``USER_F Rheo E version``
  - ``USER_Ramp version``
  - ``USER_Rheobase version``
  - ``USER_Spike Control version``
  - ``USER_Squ. Pul. version``

New textual keys
~~~~~~~~~~~~~~~~

- ``Indexing End Stimset``: The ending stimset for locked/unlocked indexing of DA channels
- The following entries are now also available for TTL channels. These are
  stored hardware agnostic with ``NUM_DA_TTL_CHANNELS`` entries in the
  ``INDEP_HEADSTAGE`` layer:

  - ``TTL Indexing End Stimset``
  - ``TTL Stimset length``
  - ``TTL Stimset checksum``
  - ``TTL Stimset wave note`` (URL encoded)

- Set cycle counts for TTL channels:

  - ``TTL rack zero set cycle counts`` (ITC hardware)
  - ``TTL rack one set cycle counts`` (ITC hardware)
  - ``TTL set cycle counts`` (NI hardware)

Changed numerical entries
~~~~~~~~~~~~~~~~~~~~~~~~~

- ``Delta I``: Use the correct unit ``A`` (amperes)

Renamed numerical entries
~~~~~~~~~~~~~~~~~~~~~~~~~

- ``Async AD $Channel: $Title`` -> ``Async AD $Channel [$Title]``

Changed textual entries
~~~~~~~~~~~~~~~~~~~~~~~~~

None

Renamed textual entries
~~~~~~~~~~~~~~~~~~~~~~~

- ``JSON config file: path`` -> ``JSON config file [path]``
- ``JSON config file: stimset nwb file path`` -> ``JSON config file [stimset nwb file path]``
- ``JSON config file: SHA-256 hash`` -> ``JSON config file [SHA-256 hash]``

Epoch information
-----------------

- Add missing trailing baseline for:

   - Stimsets when acquiring on multiple headstages with different length stimsets
   - Pulse train epochs in edge cases

NWB/IPNWB
---------

- Make per-sweep NWB export faster by pushing it into the ASYNC framework. This
  makes the overhead smaller than 20ms on recent PCs. Please note that the
  stimsets are not written anymore to the NWB in this mode.
- We now save again always all four labnotebook waves in NWB. The previous
  optimization which skipped empty ones turned out to be harmful
  to downstream users which were not prepared for this.
- ``/general/generated_by``: Store the HDF5 library version and sweep epoch version
- Store the correct device name for NI devices

File format
~~~~~~~~~~~

None

Pressure Control
----------------

- Fix gathering pressure changes in ``TPStorage``
- Publish pressure method changes and sealed state via ZeroMQ. See
  `FFI_GetAvailableMessageFilters
  <https://alleninstitute.github.io/MIES/file/_m_i_e_s___foreign_function_interface_8ipf.html#_CPPv430FFI_GetAvailableMessageFiltersv>`_
  for all available message filters

WaveBuilder
-----------

- Rename function for adding analysis parameters programmatically: ``WBP_AddAnalysisParameter`` -> ``AFH_AddAnalysisParameter``
- Create an API for creating, modifying and deleting stimsets programmatically.
  See `Simset API
  <https://alleninstitute.github.io/MIES/group/group___stimset_a_p_i_functions.html#group-stimsetapifunctions>`_
  for examples and documentation.
- Make all parameter waves have valid liberal object names as dimension labels (required for Igor Pro 9)

Work Sequencing Engine
----------------------

None

Internal
--------

- Many more functions are now marked as threadsafe. In addition the labnotebook
  getters now also work in preemptive threads.
- Add a convenient way to debug threadsafe functions. See `Debugging threadsafe functions
  <https://alleninstitute.github.io/MIES/developers.html?highlight=threadsafe#debugging-threadsafe-functions>`_
  for instructions. This introduced the `THREADING_DISABLED` define which allows code to handle this case gracefully.
- Fix compile errors with Igor Pro 9 due to duplicated case labels
- Make dimension labels valid liberal names (required for Igor Pro 9)
- Rework LBN getters for the databrowser/sweepbrowser completely
- Add menu entry for resetting the analysis browser
- Make the release package work as installation source again
- DC_PlaceDataInDAQDataWave was refactored to be readable and maintainable again
- Postpone writing the epoch information into the sweep settings wave to after finishing the sweeps

Tests
-----

- Add tests to execute all window macros
- Add tests to check that all GUIs don't have invalid control procedures
- Other fixes and additions all over the place

Async Framework
---------------

- Enhance ``ASYN_AddParam`` to allow for user defined parameter names and add
  ``ASYNC_FetchWave``/``ASYNC_FetchVariable``/``ASYNC_FetchString`` for convenient
  readout.

Logging
-------

- Add log entries in failures cases of ``DAQ stop reason``

Installer
---------

None

Release 2.2
===========

This version is the first version of MIES with support for upcoming Igor Pro 9. And it will also be the last with
support for Igor Pro 8.

Controls
--------

All added, removed or renamed controls of the main GUIs are listed here. These lists are intended to help upgrading the JSON
configuration files manually. Controls which can not be read/written with the configuration code, like GroupBox'es, are not included.

DA\_Ephys
~~~~~~~~~

Added
^^^^^

None

Removed
^^^^^^^

- ``Check_Settings_Append``
- ``setvar_Settings_DecMethodFac``
- ``title_hardware_Follow``
- ``title_hardware_Release``

Renamed
^^^^^^^

None

Databrowser
~~~~~~~~~~~

Added
^^^^^

- ``check_BrowserSettings_DS``
- ``check_pulseAver_ShowImage``
- ``check_pulseAver_drawXZeroLine``
- ``check_pulseAver_fixedPulseLength``
- ``check_pulseAver_hideFailedPulses``
- ``check_pulseAver_searchFailedPulses``
- ``check_pulseAver_showTraces``
- ``popup_pulseAver_colorscales``
- ``popup_pulseAver_pulseSortOrder``
- ``setvar_pulseAver_failedPulses_level``
- ``setvar_pulseAver_numberOfSpikes``
- ``setvar_pulseAver_vert_scale_bar``

Removed
^^^^^^^

None

Renamed
^^^^^^^

- ``check_pulseAver_indTraces`` → ``check_pulseAver_indPulses``
- ``check_pulseAver_zeroTrac`` → ``check_pulseAver_zero``
- ``setvar_pulseAver_fallbackLength`` → ``setvar_pulseAver_overridePulseLength``

Wavebuilder
~~~~~~~~~~~

Added
^^^^^

None

Removed
^^^^^^^

None

Renamed
^^^^^^^

None

Sweep Formula
-------------

- Add ``area`` operation
- Fix most cases of ignored minus signs in formulas
- Make it more user friendly on errors by not just asserting out

AnalysisBrowser
---------------

None

DataBrowser
-----------

Dashboard
~~~~~~~~~

- Display the headstages for each sweep
- Add support for multipatch seq analysis functions
- Add "enable checkbox" for the dashboard
- Show the dashboard result message as tooltip
- Add support for all sweeps even without having an analysis function attached to the stimulus set

DataBrowser/SweepBrowser
------------------------

- Fix restoring from backup so that it works again and also restore all sweeps and not only the displayed ones
- The axes' locations are now more predictable for zooming in/out via mouse wheel
- Don't display data from TP during DAQ channels
- Always create backup waves when splitting the sweep
- Speedup plotting of many traces by grouping AppendToGraph calls. This is mostly noticable in Igor Pro 8, less in
  Igor Pro 9.
- Make overlay sweeps with headstage removal faster
- Select the current sweep when enabling overlay sweeps
- Add new trace popup for convenient stimulus set opening in the wavebuilder
- Fix displaying TTL data with only "TP during DAQ" data
- Use a different marker for the first headstage. ``+`` can be easily hidden by axis ticks, but ``#`` not

SweepBrowser
------------

- Add dashboard support
- Show the sweep number in the sweep control and not the index into the list of sweeps

DA\_Ephys
---------

- Closing the DAEphys panel that is running TP now waits for the TP analysis to finish before closing
- Ignore TP during DAQ channels for locked indexing
- Prevent sweep skipping from crossing stimulus set borders
- Handle relocking a device with data better. We now don't start at sweep zero but at the next sweep after the last acquired
- Remove decimation factor control
- Make rerunning the TP with the same settings faster
- Don't disable dDAQ and oodDAQ checkboxes during data aquisition anymore
- Don't allow dialogs during background function execution, this should prevent Igor Pro crashes
- Add new trace popup for convenient stimulus set opening
- Warn users about permanent data loss when using sweep rollback
- Fix TP during DAQ channels with TTL channels
- Fix auto pipette offset taking "Apply on mode switch" into account
- Remove the "Enable async acquisition" checkbox from the settings panel. Enable async from the async tab of the DA_Ephys panel.
- Change sweep rollback to move the data to an archive folder instead of deleting it

JSON Configuration
------------------

- Remove the old experiment configuration. The new JSON based configuration now completely replaces it.
- Add menu option to open all JSON configuration files in a notebook
- Add entry "Sweep Rollback allowed" defaulting to false. This means users who are configuring MIES must explicitly
  allow sweep rollback. This was done to make the chance of misuse smaller

Downsample
----------

None

Analysis Functions
------------------

- SetControlInEvent: Warn when trying to set a control which can not be set
- Add ``SC_SpikeControl``
- Convert ReachTargetVoltage to V3 format
- Use correct labnotebook prefix for headstage active entry in MSQ_DAScale
- Make MSQ_FastRheoEst/MSQ_DAScale/MSQ_SpikeControl/ReachTargetVoltage compatible with locked indexing
- Add option to query the autobias target voltage from the user in ReachTargetVoltage
- Make execution faster by not trying to redo baseline QC when it was already done

Pulse Average Plot
------------------

- Completely rework it for better performance
- Add documentation for time align code
- Add support for failed spike detection. Failed spikes can be highlighted or hidden in the PA plot.
- Allow one PA plot per browser window
- Add X/Y scale bars with zoom support
- Make averaging faster by adding support for incremental updates and parallelizing the calculations
- Make adding new sweeps during data acquisition much faster
- Nicify GUI controls and add more help entries
- Rework the time alignment code for faster execution
- Allow displaying deconvoluted pulses without visualized average wave
- Add image plot mode with external subwindows for the color scales and the option to
  choose the pulse sorting order
- Add option ``Draw X zero line`` to draw a line crossing the plots at ``x == 0``
- Add option to always use a fixed pulse length
- Read pulse starting times from the labnotebook if present and only fallback to calculating them
- Add Tests
- Ignore spikes which are narrower than 0.2 ms

Foreign Function interface
--------------------------

- Add ``FFI_GetAvailableMessageFilters`` to query all available subscriber message filters

General
-------

- Add a menu option for resetting the package settings to their default
- Adapt ``Check Installation`` for Igor Pro 9
- Make querying the labnotebok faster by adding support for incremental updates for the cache waves
- An early version of MIES user documentation
- Make the Igor Pro version check much more user friendly to use. We now don't bug out on old Igor Pro
  versions anymore but display a dialog and allow direct download of the new version.
  This also includes up-to-date links in the documentation.
- Sweep Rollback: Fix and avoid deleting the wrong sweeps. In some cases deleted sweeps can be reconstructed via
  ``RecreateSweepWaveFromBackupAndLBN``. Please create an issue if you need help with that.
- Enhance the user experience when old NIDAQ-mx XOP versions are used with MIES
- Make unlocked indexing work with TP during DAQ
- Add menu option for opening the package settings in a notebook
- Add sub sub epoch information for pulse train pulses
- Fix POST_SET_EVENT/PRE_SET_EVENT determination in DC_PlaceDataInDAQDataWave for headstages in special cases.
- Add option to upload the MIES and ZeroMQ log files

ITC XOP 2
---------

None

ZeroMQ XOP
----------

- Add support for logging in JSONL-format on disk. This is used for debugging and performance gathering. Enabled by default.
- Add support for publisher/subscriber sockets

MCC XOP
-------

None

MIESUtils XOP
-------------

None

Labnotebook
-----------

- Set the exact same timestamps for all entries added with one call. Previously these could differ in the
  sub-millisecond range.
- Store timestamps with enough resolution in textual labnotebook, so instead of 3.6968e+09 we now store 3696770484.463
- Fix storing the wrong value for the alarm checkbox for the asynchronous tab
- With asynchronous acquisition unused channels don't result in empty labnotebook entries anymore

New numerical keys
~~~~~~~~~~~~~~~~~~

- ``Autobias %``: Autobias percentage as set in DAEphys
- ``Autobias Interval``: Autobias interval as set in DAEphys
- ``Acquisition State``: Add new standard entry which defines at which point during data acquisition an entry was
  added. See also :ref:`File MIES_AcquisitionStateHandling.ipf`
- ``Skip Sweeps``: Store the number of performed sweep skips
- ``PSQ_FMT_LBN_DA_OPMODE``: Operation mode for ``PSQ_DAScale`` analysis function
- ``PSQ_FMT_LBN_TARGETV``: Target voltage baseline
- New entries for ``SC_SpikeControl``, see :ref:`File MIES_AnalysisFunctions_MultiPatchSeq.ipf`
- New entries for ``PSQ_Chirp``, see :ref:`File MIES_AnalysisFunctions_PatchSeq.ipf`

New textual keys
~~~~~~~~~~~~~~~~

- ``Igor Pro build``: Igor Pro build revision
- ``JSON config file: stimset nwb file path``: Stimulus set path from the configuration file
- New entries for ``SC_SpikeControl``, see :ref:`File MIES_AnalysisFunctions_MultiPatchSeq.ipf`
- New entries for ``PSQ_Chirp``, see :ref:`File MIES_AnalysisFunctions_PatchSeq.ipf`

Changed numerical entries
~~~~~~~~~~~~~~~~~~~~~~~~~

None

Changed textual entries
~~~~~~~~~~~~~~~~~~~~~~~

None

NWB/IPNWB
---------

- Add the Igor Pro build version to the ``generated_by`` dataset from ndx-MIES
- Make it faster by only saving the filled rows for the labnotebook and TP storage waves
- Skip sweeps on export which don't have a config wave
- Store the MIES log file in the same place as the Igor Pro history

File format
~~~~~~~~~~~

None

Pressure Control
----------------

- We now enforce that NI hardware uses differential setup for the AI channels

WaveBuilder
-----------

- Use WP and SegWvType with double precision for new waves. We keep the existing single precision waves
  as we want to generate the exact stimulus sets again.
- Jump to the selected analysis function if possible when "Open" is pressed
- Make selecting epochs with the mouse work with flipping enabled
- Add help entry for delta modes
- Warn on too long explicit delta value list

Work Sequencing Engine
----------------------

- Remove existing file first when exporting into NWB
- Publish QC results from background functions via ZeroMQ publisher socket

Internal
--------

- Enhance error reporting in ``ASSERT_TS`` with  outputting the stacktrace in IP9
- Make NumericWaveToList faster by using wfprintf
- Make ``GetAllDevices`` faster
- Fix various corner cases in ``RA_SkipSweeps``
- Unify naming for HardwareDataWave/ITCDataWave to DAQDataWave
- Minor fixes for Igor Pro 9
- Make compiling slightly faster by not compiling the background watchter panel by default
- Add debug visualization for epochs in the Databrowser/Sweepbrowser
- Fix GetSweepSettings for the textual labnotebook
- Add ``GetActiveChannels`` which allow to determine which channels were active for a given sweep

Tests
-----

- Cleanup initialization code and add ``RunWithOpts``
- Add basic dashboard testing

Async Framework
---------------

- Add tracking jobs by ``workload`` parameters. This allows to check if all jobs of a given workload are finished.

Logging
-------

- Add support for logging in JSONL-format on disk. This is used for debugging and performance gathering.
- Store assertions, Igor starting/stopping/quitting/compiling, NWB export and device/pressure locking

Installer
---------

- Skip vc_redist installation as non-admin
- Use latest 2019 vc_redist package

Release 2.1
===========

Sweep Formula
-------------

- Add an easy to use scripting language to evaluate acquired data termed `Sweep Formula <https://alleninstitute.github.io/MIES/SweepFormula.html#the-sweep-formula-module>`_

AnalysisBrowser
---------------

- Load user comments from NWB files
- Store the starting directory in the package settings

DataBrowser
-----------

- Use a per-instance folder. Now users can have multiple databrowsers open with
  different settings as each databrowser graph has its own folder.
- Enable resizing for BrowserHistorySettings Panel
- Properly select NONE with multiple devices with data
- Make all axes scaling options available from SweepBrowser

DataBrowser/SweepBrowser
------------------------

- Fix loading and displaying of old experiments
- Make it much faster by custom trace user data handling, incremental sweep
  updates and avoiding full updates when they are not necessary.
- The graph is now always plotted correctly even when using overlay sweeps with
  headstage removal and special sweeps.
- Make the highlightning for overlay sweeps much more responsive.
- Allow to only overlay the sweeps from the current RAC/SCI
- Adapt tick labels for splitted TTL axis
- Pulse Average:

   - Fetch the pulse times for each sweep
   - Make it much faster
   - Never grey out controls, this allows tweaking the settings while it is disabled

- Restore always all cursors
- Show the headstage number in the graph as well
- Replace Labnotebook popup menus with our own cascaded solution which avoids
  long menues.
- Add all channel checkboxes
- Default "Display last sweep acquired" to ON
- Ignore invalid headstages in removal list of overlay sweeps

DA\_Ephys
---------

- Fix oodDAQ offset bug introduced in 88323d8d (Replacement of oodDAQ offset
  calculation routines, 2019-06-13) with more than two stimsets.
- Cache the HardwareDataWave for the Testpulse
- Initialize all channel data to NaN
- Fix AD unit querying bug for ADs above 8
- Allow TP during DAQ for Indexing
- Fix an off-by-one error for the fifo position
- Rework device selection logic: This is now more intuitive.
- Add a button for rescanning the list of changed hardware devices. This is
  required as that list is now cached.
- Add support for decimated oscilloscope wave which greatly speeds up the display
- Handle stopped DAQ properly and avoid "Uninitialized raCycleID detected" assertions
- Fix that with TP during DAQ all test pulse channels are stored
- Apply search string for all controls as well
- Rework oodDAQ algorithm: The new algorithm is much faster and does not require a resolution parameter anymore
- Make I=0 clamp mode work again
- Reset the session start time on "Save and Clear Experiment"
- Perform analysis parameter checks very early (even before "PRE DAQ" event)
- Add increment selection to "DA Scale" and manual pressure set variables via context menu
- Avoid using async channels for DAQ as well
- Make it usable with lots of sweeps much better
- Handle changing power spectrum checkbox during TP
- Parallelize curve fits on TPStorage data

ExperimentConfig
----------------

- Introduce `new configuration management <https://alleninstitute.github.io/MIES/file/_m_i_e_s___configuration_8ipf.html?highlight=json#file-mies-configuration-ipf>`__:

  - Support all panels and controls
  - Support setting all amplifier entries per headstage
  - Configuration files are in standard JSON format
  - Support for global and rig specific config files which complement each other

- Fix MCC opening bug in demo mode
- Add configuration field Amplifier Channel to specify channel explicitly
- Support multiple locations for the json settings files

Downsample
----------

None

Analysis Functions
------------------

- Parameters now have no restrictions anymore on the type of content.
  Previously some characters were not allowed.
- Explicitly ignore TP during DAQ channels
- Fix an off-by-one issue as we use the lastKnownRowIndex/lastValidRowIndex as
  zero-based indizes and not as length. We now also pass these values as NaN
  if they do not make sense for the current event.
- AnalysisFunction_V3: Introduce scaledDataWave member
- Add an analysis function for measuring the mid sweep event timings
- Fix level calculation for NI hardware in ``PSQ_Ramp``
- Adapt Supra mode for ``PSQ_DAScale``:
   - Plot the spike frequency vs DAScale
   - Add new LBN entry of the slope of that plot
   - Support new FinalSlopePercent parameter as additional set passing
     criteria
   - Add new LBN entry which denotes if the FinalSlopePercent was reached
     or not
   - Store pulse duration in LBN
- SetControlInEvent: Add support setting notebook contents
- Add support for check and help functions. Port the existing analysis
  functions to use that new feature.
- Fixed the analysis function parameter check routine

Foreign Function interface
--------------------------

None

General
-------

- Drop support for Igor Pro 7
- Enhance the first time usage ITC error message
- Added ``MIES_MassExperimentProcessing.ipf`` for batch converting Igor experiment files to NWBv2.
- Upload Igor Pro crash dumps every day
- Nicify About MIES dialog
- Add MIES settings which are persistent across restarts
- Add menu option to open the diagnostics directory
- Switch the default branch to ``main`` from ``master`` to foster inclusive
  terminology. For existing clones execute ``git remote set-head origin main``
  to switch the remote HEAD to ``main`` as well.

ITC XOP 2
----------

- Remove unnecessary ITCMM DLLs
- Add powershell scripts for disabling ASLR

ZeroMQ XOP
----------

- Don't restart the message handler if not required. This makes it possible to
  create a new experiment via ZeroMQ.

MCC XOP
-------

None

MIESUtils XOP
-------------

None

Labnotebook
-----------

- Add functions for querying labnotebook data via channel number and type
- Change naming scheme of unassociated channels:

   We support two types of unassociated keys. Old style, prior to 403c8ec2
   (Merge pull request #370 from AllenInstitute/feature/sweepformula_enable,
   2019-11-13) but after its introduction in ad8dc8ec (Allow AD/DA channels
   not associated with a headstage again, 2015-10-22) are written as ``$Name UNASSOC_$ChannelNumber``.
   New style has the format ``$Name u_(AD|DA)$ChannelNumber``, this includes
   the channel type to make them more self explaining.
- Remove "Pulse Train Pulses" and "Pulse to Pulse Length" labnotebook entries due severe bugs in the calculation
- Fix too short dimension labels
- Some units and tolerances were fixed for the numerical labnotebook

New numerical keys
~~~~~~~~~~~~~~~~~~

- ``PSQ_FMT_LBN_DA_fI_SLOPE`` for fitted slope in the f-I plot for ``PSQ_DAScale``
- ``PSQ_FMT_LBN_DA_fI_SLOPE_REACHED`` for fitted slope in the f-I plot exceeds target value for ``PSQ_DAScale``
- ``PSQ_FMT_LBN_PULSE_DUR`` for ``PSQ_DAScale``
- ``PSQ_FMT_LBN_SPIKE_DETECT`` for ``PSQ_DAScale``

New textual keys
~~~~~~~~~~~~~~~~

- ``JSON config file: path``: List of absolute paths to the JSON configuration files
- ``JSON config file: SHA-256 hash``: List of hash values
- ``Epochs``: , `Add epoch information from the stimulus set into the labnotebook <https://alleninstitute.github.io/MIES/epoch_information.html#epoch-information>`__.

Changed numerical entries
~~~~~~~~~~~~~~~~~~~~~~~~~

- ``oodDAQ regions``: Now uses floating point numbers instead of intergers

Changed textual entries
~~~~~~~~~~~~~~~~~~~~~~~

- ``Function params`` -> ``Function params (encoded)``: This entry now holds the serialized analysis function
  parameter strings where the values are `percent encoded <https://en.wikipedia.org/wiki/Percent-encoding>`__.

NWB/IPNWB
---------

- Write the Igor Pro history by default
- Add support for exporting into NWBv2 (2.2.4 to be exact). Additional MIES
  data and metadata is tagged using `ndx-MIES <https://github.com/t-b/ndx-MIES>`__.
  Export support into NWBv1 is unchanged.
- Various bugfixes for exporting really old or buggy MIES data into NWB.
- Support export of I=0 data better
- Don't delete third party stimsets after exporting into NWB.
- Mark ``/general/stimsets`` as custom for NWBv1

File format
~~~~~~~~~~~

None

Pressure Control
----------------

- Allow adjusting the pressure with the mouse wheel

WaveBuilder
-----------

- Raise the stimset wave note version
- Make the analysis function paramter panel nicer and resizable
- Changed encoding of the analysis function parameters to use percent-encoding
- Add duration entry for combined stimset
- Add a search string for the wavebuilder stimsets for loading
- Add wave note entry for mixed frequency shuffle
- Force stimset rebuilding on too old wave note version
- Fix forgotten delta mode for pulse duration for pulse train pulse

Work Sequencing Engine
----------------------

- Remove AnalyaisMaster panel and HDF5 operations

Internal
--------

- Packages/doc/developers.rst: Update CI section
- Add JSON-XOP
- Add preliminary support for Igor Pro 9
- Use mathjax instead of images for the documentation
- Fix version generation with latest tag
- CreateMiesVersion: Support more git install locations
- Started cleanup of DC_PlaceDataInHardwareDataWave
- Check that ASLR is turned off on Windows 10 64-bit. This is required for ITC hardware to work, see https://github.com/AllenInstitute/ITCXOP2/#windows-10.
- Add generic wave cache accessor ``CA_TemporaryWaveKey`` for using the returned wave in multihread statements as target junk wave
- Add ROVar/ROStr for mapping global variables and strings to a read-only version
- Update our documentation toolchain to sphinx 3
- Remove Tango procedure files
- Fixed some minor memory leaks

Tango
-----

- Remove it completely
- Add empty ``MIES_TangoInteract.ipf`` to avoid compile errors on old experiments

Tests
-----

- Lots of additions and fixes
- TTL channels are now much more checked on ITC1600
- Switch to Windows 10 on CI server and greatly cleanup the test scripts
- Perform compile testing on 32bit and 64bit Igor Pro
- Added test and pynwb validation tests for NWBV2
- Port tests to use rtFunctionErrors=1

Async Framework
---------------

- Make ``ASYNC_Start`` and ``ASYNC_Stop`` idempotent
- Start and Stop of ASYNC framework is now globally done by CompileHooks

Installer
---------

- Add more documentation for admins how it works
- Added support for ``/ALLUSER`` parameter to installer
- Switch installer to support Igor Pro 8 and 9
- Add special installation mode for CI server via ``/CIS`` and ``/SKIPHWXOP`` flags
- Fix edge case of user vs admin installations due to NSIS ShellLink plugin
- Enhance deinstallation logic to catch more edge cases
- Make ITC hardware work out of the box on new Windowses. Requires that
  unsigned powershell scripts can be executed.

Release 2.0
===========

AnalysisBrowser
---------------

- Labnotebook browser: Fixes for new TPStorage wave layout
- Add support for loading TPStorage waves from NWB
- Make it possible to load version 2 PXP files, i.e. PXP files with NI hardware
  acquired data can now be loaded
- Allow loading TTL channel data from NI hardware

DataBrowser
-----------

DataBrowser/SweepBrowser
------------------------

- Pulse Average:

  - Use inf as default range for the PA deconvolution
  - Use full resolution for diagonal traces only, show the other traces with
    reduced resolution for speedup reasons
  - Don't change the x axis range for deconvolution
  - Automatic Time Alignment for Pulse Averaging
  - Adapt individual traces' opacity and line size
  - Speedup plot creation and resize behaviour
  - Allow zeroing individual traces
  - Add deconvolution support
- Move TTL channel display to the bottom

DA\_Ephys
---------

- Allow TP stopping/restarting to be much faster for special cases
- Make "Pipette Offset" faster, especially for a large number of active headstages
- Add "TP during DAQ" feature which allows to have a testpulse on some
  headstages and DAQ on other headstages
- TestPulseMarker is now saved in TPStorage as well as in the stored TPWaves
- TestPulse: Implemented handling of Oscilloscope scaling depending of GUI setting
- Minimize the number of amplifier select calls
- Allow but delay clamp mode changes during DAQ
- Add entries to DA_Ephys to record User Pressure during TP
- GetTPStorage: Raise version to hold user pressure value and type as well
- Use the correct order for testpulse stopping and calling DAP_CheckSettings
  which fires the PRE_DAQ analysis event
- SCOPE_CreateGraph replaced Tag approach for TP Resistance values
- Testpulse analysis is now done in a separate thread
- Add possibility to acquire data with fixed frequency
- Fix inserted TP length with active TTL channels
- When synchronizing MIES to the MCC we now ignore sendToAll state
- Use one GUI control procedure for TP and DAQ
- SWS_SweepSaving: Call SCOPE_UpdateOscilloscopeData with correct fifo position
- Optimization: PowerSpectrum uses fast line draw on Igor Pro 8
- oodDAQ: Make the optimizing code faster and cache everything possible and
  nicify interface for callers
- Enabled live view for peak+steadystate resistance graph in IP8
- Ensure that the ITI is always reached for manual sweep starts as well

ExperimentConfig
----------------

- Add user pressure settings
- Add "Respect ITI for manual initialization"

Downsample
----------

- Nothing

Analysis Functions
------------------

- PSQ_Ramp: Added support for NI hardware
- PSQ_Rheobase:

  - Handle DaScale of zero better
  - Search again with small DAScale values
- PSQ_DAScale:

  - Add optional analysis parameter to choose operator for Supra
  - Fix average calculation for NI hardware
  - Enable "TP inserting"
  - Add optional support adjusting DAScale when out of band
- PSQ_SquarePulse:

  - Catch spiking with DAScale of zero
  - Handle known case better in Dashboard
- Add support for optional parameters in `_GetParams`
- Add MSQ_DA_SCALE analysis function
- Add SetControlInEvent analysis function
- Add PSQ_FastRheoEstimate
- Better checks for analysis parameters before DAQ
- PSQ_EvaluateBaselineProperties: Fix incorrect fifo time usage
- Dashboard: Fix querying the scale exceeded value for Rheobase

Foreign Function interface
--------------------------

- Nothing

General
-------

- Make the repository `publically <https://github.com/AllenInstitute/MIES>`_
  available. Due to restrictions on github's side we have compressed the NWB
  and PXP files. See the README.md for instructions when checking out the
  repository.
- Making stopping the async framework more robust
- ExtractOneDimDataFromSweep:

  - Create a copy for NI hardware as well
  - Make it compatible with mid-sweep NI layout
- AFH_GetAnalysisParam*: Tighten logic and add tests
- AFH_GetAnalysisParamType: Add support for requesting a specific type
- GetListOfObjects: Return never empty list elements
- Add support for NI PXI-6259 devices
- Restore IP7 style responsive behaviour in IP8
- ASSERT: Enhance diagnostic output
- Use zero as TP amplitude for unassociated DACs
- GetChannelClampMode: Extend to also hold headstage information
- DAP_CheckHeadStage: Check AD/DA headstages more thorough
- DQ_ApplyAutoBias: Modernize code
- Query the values for the labnotebook earlier before starting the sweep
- ToggleCheckBoxes/EqualizeCheckBoxes: Update GUI state wave as well
- Documentation: Make all graphs zoomable
- Change of InstResistance, SSResistance, BaseLineAverage to be double precision
- Fixed a bug which resulted in a RTE for long stimsets with NI hardware
- Enhance fWaveAveraging with MatrixOP
- SCOPE_UpdateGraph: Use more accurate relative time axis update
- Bugfix: Sweep SkipAhead resets to -1 in GUI on DAQ, following DAQ fails
- DAP_CheckStimset: Check all reachable stimsets
- Only stop the TP if we can start DAQ
- DAP_CheckHeadStage: Check for empty waves in analysis parameters as well
- Device Map: Drop internal device name
- TP_RecordTP: Avoid erroring out on low memory condition
- EnsureLargeEnoughWave: Add support for checking free memory before increasing the size of the wave
- Rework TPStorage completly: Holds now NUM_HEADSTAGES columns and also holds
  every Testpulse result. We now also always append to the current TPStorage
  wave so there is only one now.
- Acquisition support for NI DAC devices in multi device mode
- DC_PlaceDataInITCDataWave: Don't use interpolation for gathering data from TTL stimsets
- CheckInstallation: More thorough checks for NIDAQ XOP version
- SI_CalculateMinSampInterval: Fix minimum sampling interval for ITC hardware with PCI cards
- HW_ITC_MoreData/HW_ITC_MoreData_TS: Fix return value for offset usage
- CalculateTPLikePropsFromSweep: Fix some edge cases found during evaluation
- Add documentation for how the testpulse properties are calculated
- Fix RTE at end of blowout protocol

ITC XOP 2
----------

- Update help file

ZeroMQ XOP
----------

- Nothing

MCC XOP
-------

- Nothing

MIESUtils XOP
-------------

- Update help file

Labnotebook
-----------

New numerical keys
~~~~~~~~~~~~~~~~~~

- "oodDAQ member": This entry is a true/false entry denoting if a
  headstage takes part in oodDAQ or not.
- "DA ChannelType" and "AD ChannelType": Denotes if the channel was used
  for TP or DAQ.
- "Fixed Frequency acquisition"
- "Igor Pro bitness"

New textual keys
~~~~~~~~~~~~~~~~

- "TTL rack zero set sweep counts"
- "TTL rack one set sweep counts"
- "TTL set sweep counts (NI hardware)"
- "TTL stim sets (NI hardware)"
- "TTL channels (NI hardware)"
- "Digitizer Hardware Name"
- "Digitizer Serial Numbers"

Changed numerical entries
~~~~~~~~~~~~~~~~~~~~~~~~~

- Change "Minimum Sampling Interval" to "Sampling Interval"
- Document the correct TTL bits for RACK_ONE

Changed textual entries
~~~~~~~~~~~~~~~~~~~~~~~

- Nothing

NWB/IPNWB
---------

- Write the correct stimulus set for TTL channels for ITC hardware
- Add more functions for reading NWB file information
- Rename chunkedLayout parameter and add single chunk compression option
- Clarify group naming in Readme.rst
- Add an error message when loading NWB v2 files
- NWB_ExportAllData: Make compression mode configurable
- Set correct electrode number for associated DA/AD:
  Bug introduced in 7c37bf08 (NWB: Use Labnotebook property electrodeName
  if available, 2016-08-06).

  With default electrode names, which are just strings with the electrode
  numbers, the buggy source attributes are

  ITC1600_Dev_0;Sweep=0;AD=10;ElectrodeNumber=0;ElectrodeName=6

  (note the difference between the ElectrodeName and the ElectrodeNumber)

  where as it should be

  ITC1600_Dev_0;Sweep=0;AD=10;ElectrodeNumber=6;ElectrodeName=6

  One side effect of that bug is also that all TimeSeries attributes
  written by NWB_GetTimeSeriesProperties are fetched for the first
  headstage and not for the correct ones.
- Handle deleted stimsets gracefully when exporting the experiment
- Flush file after every sweep in a separate thread
- Compress stored testpulses using "single chunk compression" to make the NWB
  files smaller

File format
~~~~~~~~~~~

- Fix NWB group for unassociated DA channels. We need to store them
  in /stimulus/presentation and not in /acquisition/timeseries as ADC data.

Pressure Control
----------------

- Make manual mode respect user access (during TP)
- P_UpdateSSRSlopeAndSSR: Extract correct layer from TPStorage
- Only call P_PressureControl every 90ms during TP

WaveBuilder
-----------

- Add required column to the analysis parameter panel
- Add the required setting for all analysis parameters and don't loose it on
  user changes.
- Add wave note entry for empty epoch as well
- Fix wave recreation logic for multiple modifications done in under a second
- Invert log chirp setting written to wave note
- Call WBP_UpdateITCPanelPopUps from all stimset loading functions
- Update DAQ GUI controls on sampling interval change

Work Sequencing Engine
----------------------

- Nothing

Internal
--------

- Allow using NI USB 6001 devices in evil mode
- Documentation: Make sphinx build pass without unexpected errors

Tests
-----

- Hardware Tests:

  - Make the test suite pass with NI hardware and ITC-1600
  - Use multi data test case feature to run the tests for each device
    see also `here <https://docs.byte-physics.de/igor-unit-testing-framework/advanced.html#multi-data-test-cases>`__
  - Check the created NWB file thoroughly
  - Use the new UTF reentry functionality, thus making the tests much easier
    to understand, adapt and run for debugging.
  - Add a test to ensure that TP is stopped before PRE_DAQ_EVENT
  - Check that the sweep numbers are ascending in TEST_CASE_END_OVERRIDE
  - Perform common checks after every test case
  - Add tests which check the sampling interval for various combinations
- Compilation Testing: Test evil mode as well
- AI_QueryGainsFromMCC: Override safety check for holding potential during automated testing
- BUG: Assert out during automated testing

Async Framework
---------------

- Added a generic framework for executing code in a separate thread

Installer
---------

- vc_redist package was not installed by the installer

Tango
-----

- Nothing

Release 1.7
===========

DA\_Ephys
---------

- Support stimsets with per-sweep ITI. This also changes how the ITI is
  calculated for a set of sweeps, as now only the active sets are taken into
  account and not all sets in range anymore.
- Complain if the calculated number of sweeps in the set is zero
- Check free disc space before acquisition
- Add minimum sampling interval table for ITC16/ITC16USB
- Complain better on known ITC issues for first time users
- Fix acquisition order when changing tabs during DAQ with indexing turned on
- Avoid indexing errors when changing Repeat Sets/Lists during DAQ
- Apply on mode switch: Fix cases where the headstage and the DA/AD
  numerical values don't match
- Apply on mode switch: Fix some edge cases with indexing
- Make TPStorage resizing faster
- Testpulse Multi Device: Try selecting the device first
  This handles some edge case experiments better which have the TP stored as
  running and are then reopened.

ExperimentConfig
----------------

- Changed I-Clamp primary gain to 5 from 1
- Recursively create the folders to save the experiment

General
-------

- Support stopping Igor Pro via `Quit/N` while the testpulse is running. We
  now don't crash anymore.
- Save and clear: Delete Databrowser, Cache and reset history capturing

ITC XOP 2
----------

- Use current version of ITCXOP2 for IP8 as well

MCC XOP
-------
- The XOP now works on a real 32bit Windows

MIESUtils XOP
-------------

- New function MU_GetFreeDiskSpace

Labnotebook
-----------

New numerical keys
~~~~~~~~~~~~~~~~~~

- Digitizer Hardware Type

Pressure Control
----------------

- Make breakin work again with NI hardware
- P_SetAndGetPressure now returns the real psi and not the calibrated one

WaveBuilder
-----------

- Reorganize controls and add per sweep ITI controls
- Due to the new per-sweep ITI the version of the stimset wave note has changed as well
- Create a newly saved stimset in the stimset folder so that it can be used
  immediately without the need to recreate it.
- Speedup delta calculation

Internal
--------

- Fix the bitrotted sampling interval calculation code
- Documentation: Don't syntax highlight verbatim blocks
- Enhance the debug panel
- DEBUGPRINT/DEBUGPRINTw: Add support for outputting waves
- Updated BackgroundWatchdog: New Panel Design, works with any background task
  shows up to 15 tasks

Tango
-----

- Changed the delimiter character from ; to | for the cmdID passing

Release 1.6
===========

AnalysisBrowser
---------------

- Use try/catch for opening the HDF5 file. This allows us to continue on
  corrupt HDF5 files.
- Properly update all sweep controls on sweep loading

DataBrowser
-----------

- Auto assign locked devices as well on panel creation
- Add dashboard for inspecting analysis function results

DataBrowser/SweepBrowser
------------------------

- Enhance vertical axis ticks for on/off entries
- Don't plot anything if no sweeps are selected with OVS
- Nicify visualization of textual entries

DA\_Ephys
---------

- Update the calculated onset delay during DAQ
- Allow only one of dDAQ/oodDAQ being checked at a time
- Fix the stimset search controls for single channel controls
- Load builtin stimsets on first device locking
- Implement "Repeat sweep on async alarm" checkbox
- Allow stopping DAQ with ESC
- Allow stopping the testpulse always with ESC
- Fix DAQ restart logic when changing the stimset and TP after DAQ is enabled
- Fix forgotten update of stimsets in GUI with unlocked indexing
- Fix indexing with reversed stimset order
- Fix locked indexing bug. When the first stimset is not the one with the most
  sweeps we fail to produce the correct acquisition order.
- Document the really used ITI when it is changed mid sweep
- Fix TP settings change if TP is running, no more bugging out

ExperimentConfig
----------------

- Add Testpulse amplitude in current clamp (IC) to configuration
- Close the user config notebook immediately if it is not used anymore

Downsample
----------

None

Analysis Functions
------------------

- Patch Seq:

  - Skip only to the end of the currently active set
  - PSQ_Rheobase: Add labnotebook entry if the DAScale range was exceeded
  - Make the sampling multiplier a required analysis parameter
  - PSQ_SquarePulse: Add sweep/set pass/fail entries
  - Shorten overlong keys
  - PSQ_SPIKE_LEVEL: Change to 0.01mV
  - PSQ_DeterminePulseDuration: Handle pulses with negative amplitude properly
  - Disallow TTL channels
  - Force RA to true
  - PSQ_DAScale: Only calculate/store/display resistance in sub threshold mode
  - PSQ_DAScale: Enforce I-Clamp mode
  - PSQ_DAScale: Add test for supra mode
  - PSQ_DAScale: Check also the DAScale values
  - PSQ_DaScale: Add new operation mode
  - Force dDAQ/oodDAQ to off
  - Force settings instead of complaining if possible
  - Rename SubThreshold to DAScale
  - Enfore minimum stimset length in PRE_DAQ_EVENT
  - PSQ_Rheobase: Stop the sweep early if baseline QC passed
  - PSQ_Rheobase: Handle failing baseline QC properly
  - Add `PSQ_Ramp <http://10.128.24.29/master/file/_m_i_e_s___analysis_functions___patch_seq_8ipf.html?highlight=psq_ramp#_CPPv28PSQ_Ramp6stringP19AnalysisFunction_V3>`__ with tests, documentation and flow chart
  - Port to V3 API
  - Fix spike detection logic
  - Support indexing
  - PSQ_SearchForSpikes: Fix searching for multiple spikes and finding none
  - Patch Seq Rheobase: Increase post pulse baseline chunk size to 500ms
  - PSQ_Rheobase: Fix stimset length check

- Introduce Analysis functions V3. All new analysis functions should use this format.
- Add support for analysis parameters which can be attached to stimsets and are passed into the analysis function.
- Set realDataLength to NaN for PRE_DAQ_EVENT
- Explain behaviour on early aborting
- Allow switching multi device/single device in PRE_DAQ_EVENT
- Don't start DAQ if Abort happened during PRE_DAQ_EVENT
- Ensure that MID_SWEEP_EVENT is always reached
- Analysis parameters: Add method to request the types as well
  A breaking change is that the names now must be separated with commas
  (,) as that is more in line how we store the entries in the stimset.
- Add PRE_SET_EVENT and fix POST_SET_EVENT for indexing

Foreign Function interface
--------------------------

None

General
-------

- Readd 32-bit support. Users should *always* prefer 64-bit as we *will* phase out 32-bit support.
- Add support for Igor Pro 8
- PGC_SetAndActivateControl: Do nothing if the checkbox is already in the desired state
- Stimset wave note: Store sweep and epoch count as well
- Add document explaining some MIES coding concepts for new developers
- IgorBeforeNewHook: Save experiment after cleaning up
- AFH_ExtractOneDimDataFromSweep: More documentation and add support for TTL channels
- All hardware dependent XOPs are now not a compilation requirement anymore
- Reorganize menu
- Add a cache for the labnotebook queries, this speeds up reading out the
  labnotebook by around two orders of magnitude
- Add shortcuts to most common MIES panels
- Use fast line drawing for oscilloscope traces (Igor Pro 8 only)
- Make Multi Device DAQ the default
- Let NWB_ExportAllData use the given NWB via overrideFilePath and not use the
  standard NWB file derived from the experiment name

Installer
---------
- Add 32bit support, auto uninstall, add support for installing without hardware XOPs instead of modules
- Remove module support

ITC XOP 2
----------

- Modularize the repository and use submodules
- ITCConfigAllChannels2/ITCConfigChannel2: Add possibility to offset into data
  wave. This changes the ITCChanConfigWave format.
- Add matching PDBs

ZeroMQ XOP
----------

- Modularize the repository and use submodules
- Fix a crash with long function names from Igor Pro 8 (XOP is still compiled
  without long name support)

MCC XOP
-------

- The XOP now searches the AxMultiClampMsg.dll in the default installation
  folder. So we don't need to ship it.

Labnotebook
-----------

- GetLastSetting*: Return an invalid wave reference if nothing could be found
- Fix labnotebook getter for text entries using RAC logic
- Enhance documentation of the labnotebook querying functions
- Add documentation for developers on how to use the labnotebook
- DC_DocumentChannelProperty: Initialize sweep settings wave properly for
  unassociated channels The labnotebook entries for in these cases does not
  follow our standard scheme as zeros where used as placeholders instead of
  NaNs.

  Detecting invalid data entries:

  - Only labnotebook entries with UNASSOC in the name are concerned.
  - These labnotebook entries never have entries in the headstage
    dependent layers so these layers can alywas be ignored.
  - The only valid entry is in the INDEP_HEADSTAGE (9th) layer.
  - Write only valid analysis functions into the labnotebook

New numerical keys
~~~~~~~~~~~~~~~~~~

- "Sweep Rollback": Documents the sweep where the user used sweep rollback
- "Multi Device mode": On/Off
- "Background Testpulse": On/Off
- "Background DAQ": On/Off
- "Sampling interval multiplier": (Integer value) Factor used for reducing the sampling rate
- "TP buffer size": (Integer value) Size of the TP buffer used for averaging
- "TP during ITI": On/Off
- "Amplifier change via I=0": On/Off
- "Skip analysis functions": On/Off
- "Repeat sweep on async alarm": On/Off
- "Autobias Vcom": Voltage [mV]
- "Autobias Vcom variance": Voltage variance [mV]
- "Autobias Ibias max": Maximum current [pA]
- "Autobias": On/Off
- "Set Cycle count": Number of times a stimset was completely acquired in a row
- "Stimset acquisition cycle ID": Unique identifier which is constant for all
  sweeps of an RAC with the same stimset and set cycle count.

New textual keys
~~~~~~~~~~~~~~~~

- "Stim Wave Note": The stimset wave note, useful for querying epoch specific settings

Changed numerical entries
~~~~~~~~~~~~~~~~~~~~~~~~~

- Fix casing of "Stim Wave Checksum"
- Nearly all patch seq entries were fine tuned.

Changed textual entries
~~~~~~~~~~~~~~~~~~~~~~~

- Nearly all patch seq entries were fine tuned.
- The analysis function entries now have consistent casing:

  - "Pre DAQ function"
  - "Mid Sweep function"
  - "Post Sweep function"
  - "Post Set function"
  - "Post DAQ function"

NWB/IPNWB
---------

- Store the Igor Pro history in NWB on interactive export

File format
~~~~~~~~~~~

None

Pressure Control
----------------

- MAX/MIN_REGULATOR_PRESSURE: Unify constants

WaveBuilder
-----------

- Remove deprecated analysis functions if possible on stimset saving
- Delete intermediate waves on panel close
- Support stimsets with more than 20 sweeps
- Add GUI for handling analysis parameters
- Sort the list of shown stimsets across channel types
- Add stimset checksum to the stimset wavenote
- Fail with a good error message on unknown delta modes on stimset creation
- Upgrade WP/WPT waves to hold per entry delta operations and multipliers
- WPT now gained layers for epoch type specific data
- Add a new delta operation named "Explicit delta values" which allows to set
  the delta value for each sweep
- Don't error out on the combine epoch tab with no stimsets available

Work Sequencing Engine
----------------------

- Added support for WSE to interact with patchSeq Wave Set

Internal
--------

- Add cache statistics
- FindIndizes: Support input waves with layers
- AFH_GetChannelUnit/AFH_GetChannelUnits: Add functions for querying the channel units from the ITCChanConfigWave
- DAP_CheckSettings: Add checks for asynchronous acquisition
- Mies Version: Add date and time of last commit
- Remove stale wrapper functions
- Removed stock XOPs/Procedures/HelpFiles with shortcuts to their original location
- Add MIESUtils XOP with MU_WaveModCount, WaveModCount is available in IP8
- Unify GetLastSetting and GetLastSettingText
- Wave cache: Allow to operate on a non-duplicated wave
- Enhance indexing documentation, add a human readable description how indexing should work

Tango
-----

- Add upstream license file

Release 1.5
===========

AnalysisBrowser
---------------

- Accept dropped NWB files
- Make initial scanning of NWB files much faster

DataBrowser
-----------

- Default to sweeps axis type for labnotebook browsing
- Make "Export Traces" work

DataBrowser/SweepBrowser
------------------------

- Artefact removal: Handle no AD channels in graph gracefully
- Rework and unify UI
- Use correct trace color for unassociated channels

DA\_Ephys
---------

- Don't stop and restart TP if DAQ is ongoing
- Oscilloscope resistance values: Use sub MOhm for < 10MOhm
- Fix error on stopping single device DAQ during repeated acquisition
- Stop single device DAQ properly if aborted during ITI
- Zero ITC channels if DAQ is stopped during ITI
- Enable analysis functions by default
- Properly support "TP after DAQ" when aborting currently running DAQ
- Unify stopping for single/multi device
- Make DAQ faster for short stimsets (100ms) with less overhead
- Store only the AD data when storing the full testpulses
- Store nearly all GUI controls value in a numerical/textual GUI state
  immediately on change. This allows much faster querying and makes RA faster by around 100ms.
- Fix skipping sweeps when called during ITI
- Implement foreground single device RA. This gives a more accurate ITI for short (< 100ms) stimsets.
- Add automated blowout feature
- Amplifier: Set stored clamp mode instead of complaining only if the stored and the one active in the MCC panel differ
- Avoid endless loop in case the monitoring thread dies for multi device testpulse
- Cache used waves for multi device test pulse
- Open Arduino panel and initialize it for yoked DAQ automatically

ExperimentConfig
----------------
None

Downsample
----------
None

Analysis Functions
------------------

- Add central storage wave to make calling them faster
- Add `PSQ_Rheobase <http://10.128.24.29/master/file/_m_i_e_s___analysis_functions___patch_seq_8ipf.html?highlight=rheobase#_CPPv212PSQ_Rheobase6string8variable4wave8variable8variable>`__ with tests, documentation and flow chart
- Add `PSQ_SquarePulse <http://10.128.24.29/master/file/_m_i_e_s___analysis_functions___patch_seq_8ipf.html?highlight=square%20pulse#_CPPv215PSQ_SquarePulse6string8variable4wave8variable8variable>`__ with tests, documentation and flow chart

Foreign Function interface
--------------------------
None

General
-------

- Reorganize the MIES menu entries
- Enhance the mies version information to include submodule information as well
- Add many more labnotebook querying functions which respects RA cycle ID
- PGC_SetAndActivateControl: Send the limited val for SetVariable controls
- TPStorageWave: Store the validity of the entries
- Add windows installer based on NSIS
- Adapt sweep wave note layout
- Add manual tests for yoked DAQ
- Disable Indexing and "TP after DAQ" for yoked DAQ as it is currently broken

ITC XOP 2
----------
None

ZeroMQ XOP
----------
None

Labnotebook
-----------
- Textual Labnotebook: Normalize EOLs in entries to `\n`
- The new analysis functions write some labnotebook entries. See their documentation for details.

New numerical keys
~~~~~~~~~~~~~~~~~~
None

New textual keys
~~~~~~~~~~~~~~~~

- "Igor Pro version": Igor Pro version
- "High precision sweep start": ISO8601 timestamp of the sweep start with sub-second precision

Changed numerical entries
~~~~~~~~~~~~~~~~~~~~~~~~~
None

Changed textual entries
~~~~~~~~~~~~~~~~~~~~~~~

- "Async Unit": The textual entry for the "Async Unit" should be the plain unit
  instead of "Async AD \*: \*". Same for the unit of the async entry itself.
- "Timestamp": Store sub-second precision in Timestamp columns

NWB/IPNWB
---------

- Add option to export all stimsets into NWB on interactive export
- Use labnotebook high precision timestamp for starting_time calculation
- Fix NWB export naming and metadata for unassociated channels and TTL channels
- Export full testpulses into NWB on interactive export

File format
~~~~~~~~~~~
- Unassociatetd channels now neither have a channel suffix (`_$num`) for the
  group name if TTL channels are present.

Pressure Control
----------------
None

WaveBuilder
-----------

- Introduce builtin stimset concepts: All stimsets starting with `MIES_` are
  considered to be builtin and should not be created by users.
- Fix epoch selection by mouse for really short epochs

Work Sequencing Engine
----------------------
More general check for test pulse running in QC functions

Internal
--------

- Reorganize repository: Move all separate projects into their own repository
  and include them via git submodules.
- Add automated testing with hardware on windows
- Enhance wording of failed assertions. It now also includes a backtrace and the MIES version.
- Reorganized procedure files to enhance function grouping and naming
- Make PGC_SetAndActivateControl faster
- PGC_SetAndActivateControl: Allow to switch tabs
- PGC_SetAndActivateControl: Allow setting popup menues by string
- HW ITC: Support interactive mode
- Upgrade documentation generation toolchain to latest versions

Tango
-----
None

Release 1.4
===========

AnalysisBrowser
---------------

- SweepBrowser Export:
    - Fix x range determination by number of pulses
    - Use correct region for pulse range calculation
    - Fix operation on zoomed in graphs
- SweepBrowser: Remove both unused sub panels on the right

DataBrowser
-----------
- Rework UI to use much less horizontal space and make it more compact
- Fix overlay sweeps for experiments with non-standard sweep ordering

DataBrowser/SweepBrowser
------------------------

- Pulse Average:
    - Make individual traces more transparent
    - Enhance display of poisson distributed pulses
- Overlay Sweeps: Add mode for overlaying sweeps in a non-commulative way

DA\_Ephys
---------

- Avoid complaining into the history if the ITI is too short
- Speedup repeated acqusition in case no ITI is left for the background function
- Testpulse Multidevice: Extract the first chunk only after it is finished
- Disable more GUI controls during DAQ
- Set DA channels to zero on normal stop as well (required if analysis function aborts early)
- TP_Delta:
    - Prefer a fixed time period for the instantaneous calculation
    - Fix Steady state resistance calculation for non-default baselines
- Avoid inifite loop in DAQ Multidevice (hard to trigger though)
- New User settings for All V-clamp or I-clamp settings
- Add jump ahead feature which allows the user to skip future sweeps
- Make the autobias percentage and the interval configurable

Analysis Functions
------------------

- Added `AdjustDAScale <http://10.128.24.29/master/file/_m_i_e_s___analysis_functions_8ipf.html#_CPPv213AdjustDAScale6string8variable4wave8variable8variable>`__, `ReachTargetVoltage <http://10.128.24.29/master/file/_m_i_e_s___analysis_functions_8ipf.html#_CPPv218ReachTargetVoltage6string8variable4wave8variable8variable>`__ and `PatchSeqSubThreshold <http://10.128.24.29/master/file/_m_i_e_s___analysis_functions_8ipf.html#_CPPv220PatchSeqSubThreshold6string8variable4wave8variable8variable>`__
- Add "early abort without repurposing time" return value for Mid Sweep Event

ExperimentConfig
----------------

- Added some more config fields

Downsample
----------
None

Foreign Function interface
--------------------------
None

General
-------

- Avoid calling analysis functions twice on mid sweep event
- Allow skipping the last sweep with repeated acquisition on

ITC XOP 2
----------
None

ZeroMQ XOP
----------
None

Labnotebook
-----------
None. The new analysis functions write some labnotebook entries. See their
documentation for details.

New numerical keys
~~~~~~~~~~~~~~~~~~
None

New textual keys
~~~~~~~~~~~~~~~~
None

Changed numerical entries
~~~~~~~~~~~~~~~~~~~~~~~~~
None

Changed textual entries
~~~~~~~~~~~~~~~~~~~~~~~
None

NWB/IPNWB
---------
None

File format
~~~~~~~~~~~
None

Pressure Control
----------------
None

WaveBuilder
-----------

- Fix combine stimset creation without Wavebuilder panel open
- Pulse Train epoch:
    - Adjust pulse positions relative to the begin of the stimset
    - Fix number of pulses control updating with multiple pulse train epochs in one stimset
    - Add mixed frequency mode
- Noise epoch:
    - Fix high/low filter values and document them properly
    - Add the possibility to create multiple epochs using the exact same RNG seed
- Avoid runtime error on custom wave epoch on empty folder selection
- Add automated regression tests

Work Sequencing Engine
----------------------
None

Internal
--------

- Convert Abort with message to DoAbortNow to facilitate automated testing with hardware in future versions.
- Fix skipped documentation for DAP\_EphysPanelStartUpSettings() due to buggy code conversion script.
- ED_AddEntryToLabnotebook: Add optional overrideSweepNo parameter
- Get rid of some ITC hardware related waves

Tango
-----
None

Release 1.3
===========

AnalysisBrowser
---------------
- Make the NWB menu entries available when only this module is loaded

DataBrowser
-----------
- Reset overlay sweep folder on device locking
- Labnotebook entry graph: Make the vertical axis scale to the visible data by default

DataBrowser/SweepBrowser
------------------------
- Pulse averaging: Fix work preventing logic again
- PulseAveraging: Handle invalid pulse coordinates more gracefully
- Fix Display of TTL waves

DA\_Ephys
---------
- Testpulse Multidevice:
  - Use the correct testpulse length for the cutoff at the end (minor)
  - Fix invalid extracted chunks for special baseline values
  - Push stopCollection point further to the end
  - Rewrite fifo handling logic to always extract the last chunk
  - Remove device restarting logic
- Fix the total number of sweeps calculation for locked indexing. Broken since 0.9.
- Prevent locking a ITC device which is not present
- Repeated Acquisition: Don't try starting TP during ITI if there is no time left
- Oscilloscope: Prevent sub MOhm values for Rss and Rpeak
- Oscilloscope: Don't use autoscaling in DAQ mode.
- Background functions: Unify DAQ/TP bkg functions period to 5 ticks (12/60s = 83ms)
- Speedup DAQ via optimizing the way we write into the oscilloscope wave
- Experiment Documentation: Rework and speedup the sweep wave note creation with changed entries
- Turn off analysis functions by default
- Analysis Functions: Implement support for new mid sweep return type
- Add support for skipping forward and back some sweeps during data acquisition
- Repeated Acquisition: Immediately finish if we have only one trial
- Analysis Functions: Prevent Post Sweep/Set/DAQ event execution on forced DAQ stopping
- Experiment Documentation: Avoid bugging out on very long text entries
- Pulse averaging: Fix fallback logic for non existing pulse lengths
- Correct the default channels and other settings for device 1 to 9 of the type ITC1600
- Handle non-active headstage gracefully if the user presses Approach (pressure mode)
- Try out all possible MultiClampCommander paths
- Add possibility to store each testpulse

ExperimentConfig
----------------
- Remove workaround for buggy MultiClampCommander 64-bit App (Requires latest beta version of MCC App)
- Fixed incorrect `GetPanelControl` constants to set the Min/Max Temp alarm. Fixed now
- Add User Config field to save each TP sweep
- Added new fields to User Configuration:
  - Enable/Disable Autobias current
  - Enable/Disable Cap Neutralization
  - Set User onset and termination delay
  - Select initial stim set and amplitude to begin data acquisition

Downsample
----------
- Avoid erroring out on invalid target rate

Foreign Function interface
--------------------------
None

General
-------
- Remove 32bit, Manipulator and RemoteControl support
- Avoid gossiping (aka printing messages) too much during operation instead use ControlWindowToFront when it is really important
- Prevent erroneous save dialog when quitting MIES when nothing has changed
- Readme.md: Unify full installation instructions for 32/64 bit
- Readme.md: Enhance installation instructions without hardware
- Raise required Igor Pro version to 7.04

Labnotebook
-----------
- Fix adding the basic entries to all layers. Broken since the switch to Igor Pro 7.

ITC XOP 2
----------
- Fix some erroneous tests
- Add BSD-3-Clause License

ZeroMQ XOP
----------
- Add help file in Igor Pro Help format
- Nicify documentation and enhance compilation instructions
- Add example C++ client
- Add MacOSX XOPs
- Upgrade to new XOPSupport 7.01
- Recompile XOP support libraries with runtime DLL setting
- Fix some compilation warnings found by clang on MacOSX
- Remove dependency of the tests on MIES
- Add BSD-3-Clause License

New numerical keys
~~~~~~~~~~~~~~~~~~
- "Stim Wave Checksum", 32bit CRC of the stimset and its parameter waves (if present)
- "Repeated Acq Cycle ID" holds an integer value which is unique for every
  repeated acquisition cycle. This allows to determine if two sweeps belong to
  the same repeaqted acquisition. Before this was only possible via an
  heuristic which could not be correct all the time.

New textual keys
~~~~~~~~~~~~~~~~
None

Changed numerical entries
~~~~~~~~~~~~~~~~~~~~~~~~~
- Write "TTL rack zero/one channel" only in the headstage independent layer
- Write asyn entries also in the headstage independent layer (For backwards compatibility we keep it in the zeroth layer)

Changed textual entries
~~~~~~~~~~~~~~~~~~~~~~~
- Write asyn entries also in the headstage independent layer (For backwards compatibility we keep it in the zeroth layer)

NWB/IPNWB
---------
- Link to the specification we implement
- Nicify documentation
- Add BSD-3-Clause License
- Add example code for reading as well
- H5_LoadDataset: Use HDF5 Error and dump routine in case of error
- CreateCommonGroups: Write required datasets always
- GeneralInfo: Include all other root folder elements as well

Pressure Control
----------------
None

WaveBuilder
-----------
- Fix loading default stimset values for DA type
- Fix loading of TTL stimsets
- Update the stimset related DA_EPHYS panel controls if only the number of sweeps of stimset changed
- Prevent keeping non-existing analysis functions attached to a stimset during load and save cycle
- Warn the user if the stimset references a non existing analysis function on loading

Work Sequencing Engine
----------------------
None

File format
~~~~~~~~~~~
None

Internal
--------
- Switch continuous integration server to use Igor Pro 64-bit for unit and compilation testing
- GetLastSetting: Return a double precision wave
- EnsureLargeEnoughWave: Avoid enlarging minimum sized waves immediately
- DA_EPHYS: Introduce a RNG seed value for each locked device
- ExtractOneDimDataFromSweep: Add assertion for catching sweep <-> config mixups
- ED_AddEntriesToLabnotebook: Add convenience function for easy addition of user labnotebook entries
- FindIndizes: Simplify interface
- Count global initializes at zero instead of NaN
- FindRange: Make it possible to search for NaNs
- DeepCopyWaveRefWave: Avoid claiming to support multi dimensional src waves
- ParseISO8601TimeStamp: Accept more format variations written by the api-python code

Tango
-----
None. But be aware that now the 64-bit version of the Tango XOP always is used.

Release 1.2
===========

General
-------
- Add menu entry for loading stimsets from an NWB file
- Entry type heuristic: Handle old labnotebooks without entry source type and no TP data properly
- Rework TPStorage contents
- Don't allow aborting SaveExperimentWrapper in SAVE_AND_SPLIT mode
- Keep the NWB file open on SAVE_AND_SPLIT
- Averaging: Fix rounding error due to single precision intermediate wave
- Upgrade to NIDAQ XOPs version 1.10 final

DA\_Ephys
---------
- oodDAQ:

  - Fix some edge cases (works around a FindLevel limitation in older Igor 7 versions)
  - Allow to use analysis functions in this mode as well
  - Inform the user if the pre/post oodDAQ delays are out of range
- Make clamp mode changing faster and add controls for changing the clamp mode once for all active headstages
- Change inital onset user delay to 0ms
- Added checkbox control to de/activate all headstages simultaneously
- Complain and abort DAQ/TP if the requested settings would exceed the signed 16bit range of the ITCDataWave
- Remove backup waves as well on sweep rollback
- Move the free memory check into DC_ConfigureDataForITC and make it
  non-skippable. This should make it less likely that Igor crashes due to out
  of memory during DAQ.
- Move the FIFO checking to a separate thread for DAQ MD in order to prevent a
  crash on heavy load on the Igor main thread
- Disable active headstage checkboxes during DAQ
- Disable background/multi device checkboxes during DAQ/TP
- Add support for stopping and restarting DAQ on stimset change
- Prevent foreground DAQ with RA
- Stop DAQ/TP before unlocking the device

AnalysisBrowser
---------------
- Better code for deriving the initial filesystem folder
- Allow loading stimsets, including dependent stimsets and custom waves, from NWB/PXP

DataBrowser/SweepBrowser
------------------------
- Fix oodDAQ display with only TTL data shown
- Unify oodDAQ and dDAQ display. The region slider can now be used to select
  oodDAQ regions or dDAQ headstage regions.
- Add new overlay sweeps functionality with the following features:

  - Select sweeps by popup menu (stimset and stimset plus clamp mode), checkbox
    clicking or "prev"/"next" buttons
  - The user can choose the offset and the stepping for all popupmenu
    selections except "none".
  - Allow to ignore headstages per sweep by context menu selection or
    listbox entries
  - Regenerate the graph of overlayed sweeps on every change, this also
    makes it possible to allow all other settings to be available while
    overlay sweeps is active
- Make averaging work in dDAQ mode
- Speedup displaying lots of sweeps a lot (by more than one magnitude for averaging turned on)
- ArtefactRemoval:
  - Make range highlightning optional
  - Speed it up and fix some edge cases
  - Replace range with first value instead of NaN
- Zero traces: Skip superfluous invocations
- Add pulse averaging

  - Allow the user to average pulses from a pulse train stimset.
  - New graphs are created for each region and active channel to the right
    hand side of the databrowser/sweep browser.
- Adjust waves for onset delay for oodDAQ view
- Enhance axis positioning in dDAQ mode
- Time alignment: Make it usable again
- Add checkbox for hiding normal sweeps:

  - Use our headstage colors if normal sweeps are hidden

SweepBrowser
------------
- SweepBrowser: Enhance export functionality

  - Use a real panel for querying user input instead of DoPrompt
  - Add new options:

    - Source graph
    - Target graph
    - Target left/bottom axis
    - Target left/bottom axis name

DataBrowser
-----------
- Add panel versioning
- Lock to device on panel opening if we only have data from one.
- Unify all settings to use checkboxes

Labnotebook
-----------
- Document the train pulse starting times and pulse lengths
- GetLastSetting/GetLastSettingText/... learned to treat edge cases including
  DAQ/TP and sweep number rollback properly. This is a change in the
  labnotebook reading routines only.

New numerical keys
~~~~~~~~~~~~~~~~~~
- ``Pulse To Pulse Length``: Distance in ms of two pulses in pulse train stimsets

New textual keys
~~~~~~~~~~~~~~~~
- ``Pulse Train Pulses``: List of pulse train starting times in ms (relative to the stimset start)

NWB/IPNWB
---------
- Raise version to 0.16
- Truncate the written wave notes to avoid triggering the "64k" limit on attribute sizes.
- Add rtFunctionErrors pragma
- ReadLabNoteBooks: Don't assert out if we could not find the labnotebook
- Require Igor Pro 7
- Allow exporting unassociated channel data of all channel types
- Add generic routines for loading datasets into free waves
- Flush the NWB file to disc on Igor experiment save

File format
~~~~~~~~~~~
- Allow creating NWB files with only TPStorage waves or stimsets
- Store dependent stimsets, due to formula epochs, and referenced custom waves
  in NWB as well when storing the stimset of a sweep.

Pressure Control
----------------
- Fix NI device resetting code on device close

User Config
-----------
- Add a config file and code to allow setting the required MIES settings in an
  automated way.

WaveBuilder
-----------
- Square Pulse Train:

  - Rename Square Pulse Train to Pulse Train
  - The pulse type can now be either square (as before) or triangle.
  - Add amplitude related entries to wave note
  - Make poisson distributed pulses reproducible. This also adds "New Seed" and
    a "Seed / Sweep" controls.
  - Add the pulse starting times to the stimset wave notes
- Fix flipping with multi sweep stimsets
- Speedup sawtooth on Igor Pro 7.02 and later
- CustomWave: Use the same offset than all other epoch types. This also fixes
  the problem that the wrong "offset"/"delta offset" was added to the
  segment wave note.
- More use of the magical speedup keywords
- Use differnt colors for sweeps in the wavebuilder
- Show the delta mode also for the custom wave
- Show user analysis functions from UserAnalysisFunctions.ipf as well in the popup menues
- Prevent RTE due to non existing bottom axis on empty graph
- Improved detection of the need to regenerate the stimset from the parameter
  waves. Recreate the stimsets if one of the following elements changed:

  - any custom wave has changed
  - any stimsets within a formula have changed
- Rework stimset wave note generation:
  We now document the settings of each sweep (aka step) and not only of the first
  including delta. This also changes the format of the sweep wave note.

  Example of the new stimset wave note format:

  .. code-block:: text

    Sweep = 0;Epoch = 0;Type = Square pulse;Duration = 1000;Amplitude = 0;
    Sweep = 0;Epoch = 1;Type = Pulse Train;Duration = 1840.01;Amplitude = 1;Offset = 0;Pulse Type = Square;Frequency = 5;Pulse duration = 40;Number of pulses = 10;Poisson distribution = False;Random seed = 0.943029;Definition mode = Duration;
    Stimset;ITI = 0;Pre DAQ = ;Mid Sweep = ;Post Sweep = ;Post Set = ;Post DAQ = ;Flip = 0;

Work Sequencing Engine
----------------------
None

Downsample
----------
None

Foreign Function interface
--------------------------
- FFI_ReturnTPValues: Return a null wave if the testpulse has not yet been running

ITC XOP 2
----------
- Change /V flag handling of ITCSetDAC2 to match the documentation
- Fix a potential crash in ITCInitialize2/U (we don't use this flag)
- Add PDB files

ZeroMQ XOP
----------
- Return a newly added and more specific error message on catching ``std::bad_alloc`` exceptions.
- Try handling out of memory cases more gracefully, in some cases caller are even responed to with a specific error message.
- Update to latest libzmq version (84d94b4f)
- Add PDB files

Internal
--------
- GetTPStorage: Fix wave note formatting on upgrade
- Replace GetClampModeString by a more versatile solution, namely the GetActiveHSProperties wave
- Fix sweep splitting for changed sweep waves
- PGC_SetAndActivateControl: Set popStr for PopupMenues if not supplied
- Prevent storing sweep data with differing channel number in ``config`` and ``sweep``
- PGC_SetAndActivateControl: Respect the valid data range for ``SetVariable`` controls
- Add rtFunctionErrors pragma which should catch more programming errors
- Finalize transition to always existing count variable
- Add infrastructure and bamboo jobs for automated unit testing
- Update to latest version of the igor unit testing framework and enable JUNIT output for the tests
- Use the parent experiment name for deriving the NWB filename. The result is
  that sibling experiments now use the same NWB file as the parent
  experiment.

Tango
-----
- TI_ConfigureMCCforIVSCC: Use correct clamp mode
- TI_saveNWBFile: Take the full path

Release 1.1
===========

General
-------
-  Add more user analysis functions

DA\_Ephys
---------
-  DA Tab: Add controls for changing all channels in a given clamp mode
-  Bugfix: Use existing GUI procedures for DA1-7 search controls

WaveBuilder
-----------
-  Add panel versioning
-  WP/WPT waves received a wave version upgrade and changed dimensions labels
-  Custom epoch: Enhance GUI usability for wave selection
-  Bugfix: Use existing GUI procedure for delta type controls
-  Avoid useless stimset recreation on epoch selection by mouse
-  Fix minor GUI layout issues
-  GPB-Noise: Complete rewrite epoch generation
   The old approach had the user-visible drawback that it was very very slow
   for durations larger than 1000ms.

   The new approach has the following properties:

   - Fast creation, at least a magnitude faster, by using IFFT and FilterIIR
   - Unified approach for white, pink and brown noise
   - Fix interchanged definitions for pink and brown noise
   - Only one filter coefficient, ranging from 1 to 100, with delta remains
   - ``1/f increment`` was replaced by the experimental build resolution option
   - The amplitude is now peak-to-peak and not standard deviation
   - The phase is now uniform distributed between [-pi, pi) using the
     Mersenne-Twister as pseudo random number generator
   - epoch noise tab cleanup
   - FFT phase and spectrum is displayed for each sweep

   Keeping the old method for compatibility with existing parameter stimset waves was deemed
   not worth the effort.

DataBrowser
-----------
- Bugfix: Use correct location for channel selection wave

DataBrowser/SweepBrowser
------------------------
- Add Artefact removal panel

Pressure Control
----------------
- Set pressure to atmosphere on disabling the headstage
- Bugfix: Avoid spurious control on unrelated windows

Labnotebook
-----------
- Enhance ``EntrySourceType`` heuristics for very old labnotebooks

New numerical keys
~~~~~~~~~~~~~~~~~~
None

New textual keys
~~~~~~~~~~~~~~~~
None

NWB/IPNWB
---------
None

File format
~~~~~~~~~~~
None

Internal
--------
- Add script to build documentation on Linux using docker
- Bugfix: Add missing files to the release package
- Add panel for tuning debug mode on a per-file level

Release 1.0
===========

General
-------

-  Require Igor Pro 7.01
-  Switch to completely rewritten ITC XOP
-  Ignore errors on closing the experiment
-  Status message displays saved file name after saving config
-  Avoid runtime error after DAQ in edge cases
-  Avoid RTE on DAQ with RA
-  Fix indexing with stimsets with multiple steps
-  Yoking: Sync dDAQ settings properly
-  Make TP MD testpulse creation faster
-  Enhance data saving speed
-  Add new data acquisition mode: Optimized overlap distributed
   acquisition
-  CheckInstallation: Look for a valid MIES version too
-  Testpulse MD: Streamline ITC XOP calling sequence
-  Stop device before closing
-  TP MD: Rework and fix crashes with 64bit XOP

DA\_Ephys
---------

-  Generalize controls for setting multiple channel values
-  Propagate amplifier settings before DAQ/TP
-  Add checks for DA/AD gain and unit in pre DAQ/TP checks
-  Read the pressure settings from the waves on device locking
-  Prevent impossible clamp mode switch
-  Fixes bug where positive going fast capacitative artifact could lead
   to incorrect peak R calculation
-  Increase performance on oscilloscope update
-  Fix MIES auto pipette offset for overload edge case
-  Delete data waves before TP if requested
-  Allow to increase the sweep counter again on rollback
-  Remove the "Overwrite data waves" checkbox
-  Fix graph updating logic in corner case for TP MD
-  Fix restarting the test pulse for multiple headstage on settings
   change
-  Allow to display the power spectrum of the TP as an option
-  Fail locking on device open error
-  Fix auto pipette offset buttons for unsychronized clamp mode
-  Try to regenerate root:mies:version more eagerly
-  Autobias: Initialize actualCurrent properly
-  Autobias: Correct indexing of TP result waves
-  Fix Autopipette offset with MIES->MCC syncing
-  Use double precision for TPStorage
-  Create the Acqusition TPSTorage wave with double precision as well
-  Check for mismatched clamp mode early enough that we can complain
   properly to the user
-  Prevent Random Acq together with Indexing
-  Increased ``MINIMUM_ITCDATAWAVE_EXPONENT`` from 17 to 20. This means
   the acquired data will now always be at least 2^20 points long
-  Bring command window to front on most common setup verification
   errors

NWB/IPNWB
---------

-  Honour overrideFilePath for export in all cases
-  Prevent duplicated datasets on export
-  Allow to export older experiments
-  Raise IPNWB version to 0.15
-  Support writing unassociated AD channels
-  Add support for reading NWB files we created ourselves

File format
~~~~~~~~~~~
-  Raise version to 1.0.5
-  Add ``/general/generated_by``
-  Add mandatory tags attribute to ``/epochs``
-  Change source attributes from TimeSeries
-  Document the channel suffix as TTLBit using source attribute
-  Skip writing ``/general/version``
-  Add device to ``/general/intracellular_ephys/electrode_X``
-  Fix type of ``/general/intracellular_ephys/electrode_x``
-  Use Labnotebook property ``electrodeName`` if available for the
   ``electrode_name``
-  Change stimset writing logic (skips writing the raw stimset waves for
   most cases)
-  Use plain TimeSeries for unknown clamp modes

Wavebuilder
-----------

-  Combined epoch: Fix accessing third party stim sets
-  Combined epoch: Fix wrong formula generation in edge case
-  Custom epoch: Update epoch controls
-  Custom epoch: Enhance upgrade path
-  Custom epoch: Highlight them in the preview
-  Fix window hook for epoch selection
-  Make stimset handling logic more robust

AnalysisBrowser
---------------

-  Fix reading experiments without "Set Sweep Count" entries
-  Ignore LoadData errors
-  Handle experiments with no data gracefully
-  Don't add duplicated experiment names
-  Handle multiple experiments with the same name properly
-  Don't error out on non-existing datafolders
-  Fix "Scan folder" cleanup logic

Databrowser/Sweepbrowser
------------------------

-  Add dedicated support for viewing dDAQ/oodDAQ data
-  Speedup wave averaging a bit
-  Add support displaying textual labnotebook data

Databrowser
-----------

-  Remove the lock button
-  Add channel/headstage selection dialog

SweepBrowser
------------

- Add headstage controls in selection dialog

Work Sequencing Engine
----------------------

-  Various fixes
-  Support pulling of TP values out of the TP storage wave

Downsample
----------

-  Fix not finding any device data

Labnotebook
-----------

-  Raise version to 6
-  Write forgotten async text settings to the labnotebook
-  Streamline labnotebook naming with the new names being:

   -  numericalValues
   -  numericalKeys
   -  textualValues
   -  textualKeys

-  Avoid wasted memory in textual labnotebook
-  Fix units and tolerance of "Repeat Sets" for new entries
-  Upgrade labnotebook to correct "Repeat Sets" units and tolerance
-  Upgrade labnotebook to hold a "EntrySourceType" column

New numerical keys
~~~~~~~~~~~~~~~~~~

-  "Sampling interval multiplier"
-  "Minimum sampling interval"
-  "Stim set length"
-  "oodDAQ Pre Feature"
-  "oodDAQ Post Feature"
-  "oodDAQ Resolution"
-  "Optimized Overlap dDAQ"
-  "Delay onset oodDAQ"
-  "EntrySourceType"

New textual keys
~~~~~~~~~~~~~~~~

-  "Electrode" (defaults to headstage number)
-  "oodDAQ regions"

Pressure control
----------------

-  Set the initial seal pressure to -0.2
-  P\_LoadPressureButtonState: Use headstage value from wave instead of
   GUI query
-  Allow the user to offset the applied pressure
-  Update to seal and break method
-  Fix "all" usage for Manual pressure
-  Initialize pressure waves with correct defaults
-  Don't overwrite pressure wave data on upgrade
-  Create P\_SetPressureMode to allow external processes to use pressure
   controls in MIES/Igor.
-  Set pressure to 0 psi at disable
-  Add user pressure
-  Use DAP\_AbortIfUnlocked for pressure related controls
-  Fixed bug where displayed pressure included the calibration constant

Internal
--------

-  Upgrade HDF5 XOP to a version which allows to force the dimension
   space to SIMPLE for attributes
-  Remove unnecessary files from Release package
-  DAP\_EphysPanelStartUpSettings: Make it more usable
-  Update Packages/unit-testing to 26f3f77f9
-  AI\_SendToAmp: Add option for setting/getting values in MIES units
-  Rework follower/leader check functions
-  Remove doNotCreateSVAR hack for ListOfFollowerITC1600s
-  Add HDF5 Browser ipf from IP7
-  Update Helpfiles from IP7 final
-  Add EVIL\ *KITTEN*\ EATING\_MODE for turning off all safety checks
-  Add script for generating a changelog (which the author of these lines
   forgot about)
-  Add wave caching framework
-  doxygen-filter-ipf: Make output sphinx compatible
-  Switch to doxygen/breathe/sphinx for developer documentation
-  ED\_createTextNotes: Accept incoming waves with only one layer
-  Disambiguate labnotebook entry search for TP/DAQ keys
-  Add ZeroMQ.XOP
-  Autostart ZeroMQ Message Handler on Igor Start
-  Foreground DAQ/TP: Do Idle Processing in loop
-  Convert procedures to UTF8-encoding

Tango
-----

-  Avoid using "MS Shell Dlg" font

For older releases use ``git log``!
