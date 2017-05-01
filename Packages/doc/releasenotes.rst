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
