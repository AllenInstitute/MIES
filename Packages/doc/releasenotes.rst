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
