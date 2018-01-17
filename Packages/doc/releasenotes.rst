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
- The new analysis functions write some labnotebook entries. See their
documentation for details.

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
  instead of "Async AD *: *". Same for the unit of the async entry itself.
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
