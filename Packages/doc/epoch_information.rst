.. _epoch_information_doc:

=================
Epoch Information
=================

Description
-----------

At acquisition time, sweep epoch metadata is generated.
Epochs are time ranges in the input signal that feature certain signal shapes, such as e.g. pulse trains.
This information is exported with each data acquisition to the lab notebook with the key "Epochs" for each DA channel.

Retrieving Epoch Information from the Lab Notebook
--------------------------------------------------

The epoch information can be retrieved from the lab notebook with

 .. code-block:: igorpro

    WAVE/T textualValues   = GetLBTextualValues(device)
    WAVE/T epochLBEntries = GetLastSetting(textualValues, sweepNumber, EPOCHS_ENTRY_KEY, DATA_ACQUISITION_MODE)
    WAVE/T epochChannel = ListToTextWaveMD(epochLBEntries[channelNumber], 2, rowSep = ":", colSep = ",")

The epochChannel wave for this sweep and channel has four columns for start time, end time, name of the epoch and level.
Each row is an epoch entry.

Format
------

The times are in seconds where 0 is the beginning of the signal input. The reference signal is the DA input wave.
The wave can contain several entries with different levels covering the same time range.
Epochs with a level of zero name the main components of the input signal.
Typical epochs with zero level are 'Inserted Test Pulse' and 'StimSet'.

A level of one designates circumstantial epochs of level zero epochs.
For example for 'Inserted Test Pulse' level one epochs are the preceding base line part, the pulse part and the subsequent base line part.
For 'StimSet's that are level zero, the associated Stimset-Epochs like Ramp, Pulse Train and so on are level one.

Accordingly level two epochs are circumstantial epochs of level one epochs.
For example for a Pulse Train epoch the level two epochs are each single pulse.

The start time of a level n epoch equals the start time of the first level n+1 epoch within the level n epochs time interval.

All epochs between 0 and end of the input signal are consecutive and without holes.
All level n+1 epochs are consecutive in time and without wholes covering exactly the associated level n epoch.

The following table sketches how epochs of different levels could be distributed in the range of the full output data:

+-------------------------------------------------------------------------------------------------------------------------+
|                                         output data time series range   0 - 100 [s]                                     |
+===============================================================================================+=========================+
|                              level 0: 0 - 60                                                  |level 0: 60 - 100        |
+-----------------------+-----------------------------------------------------------------------+-------------------------+
|level 1: 0 - 20        |level 1: 20 - 60                                                       |                         |
+-----------------------+-----------------+-----------------+-----------------+-----------------+-------------------------+
|                       |level 2:  20 - 30|level 2:  30 - 45|level 2:  45 - 51|level 2:  51 - 60|                         |
+-----------------------+-----------------+-----------------+-----------------+-----------------+-------------------------+

The entries in the wave are sorted by increasing start times and secondary by decreasing end times.

oodDAQ Regions
--------------

oodDAQ regions are also saved as level two epochs with the name oodDAQRegion. While regular epochs are generated from the stimset note,
oodDAQ regions are a result from the oodDAQ optimizer. Thus the oodDAQRegion epochs are not bound to the constraints described in the previous section.
The oodDAQ regions are added 'as is' to the epochs.

Naming
------

The following table describes how components of different origins are named:

+-------+-------+-------+---------------------------------------+---------------------------------------------------------+
| Level | Level | Level | Name                                  | Origin                                                  |
+=======+=======+=======+=======================================+=========================================================+
|   0   |       |       | Baseline                              | Onset Delay                                             |
+-------+-------+-------+---------------------------------------+---------------------------------------------------------+
|   0   |       |       | Baseline                              | Delay of channel due to Distributed DAQ [OptOv]         |
+-------+-------+-------+---------------------------------------+---------------------------------------------------------+
|   0   |       |       | Inserted TP;Test Pulse;               | Inserted TP                                             |
+-------+-------+-------+---------------------------------------+---------------------------------------------------------+
|       |   1   |       | Baseline                              | preceding baseline of inserted TP                       |
+-------+-------+-------+---------------------------------------+---------------------------------------------------------+
|       |   1   |       | +pulse;Amplitude=x;                   | pulse time of inserted TP                               |
+-------+-------+-------+---------------------------------------+---------------------------------------------------------+
|       |   1   |       | Baseline                              | subsequent baseline of inserted TP                      |
+-------+-------+-------+---------------------------------------+---------------------------------------------------------+
|   0   |       |       | Stimset                               | Stimset                                                 |
+-------+-------+-------+---------------------------------------+---------------------------------------------------------+
|       |   1   |       | Epoch=x;Type=x;Amplitude=x;Details=x; | Stimset-Epoch                                           |
+-------+-------+-------+---------------------------------------+---------------------------------------------------------+
|       |       |   2   | Baseline                              | Stimset-Epoch baseline before first pulse (pulse train) |
+-------+-------+-------+---------------------------------------+---------------------------------------------------------+
|       |       |   2   | +Pulse=x;                             | Stimset-Epoch component, example pulse train            |
+-------+-------+-------+---------------------------------------+---------------------------------------------------------+
|       |       |   2   | oodDAQRegion=x                        | oodDAQ region                                           |
+-------+-------+-------+---------------------------------------+---------------------------------------------------------+
|   0   |       |       | Baseline                              | trailing baseline from Distributed DAQ [OptOv]          |
+-------+-------+-------+---------------------------------------+---------------------------------------------------------+
|   0   |       |       | Baseline                              | Termination Delay                                       |
+-------+-------+-------+---------------------------------------+---------------------------------------------------------+

If the name entry in the table starts with '+' then it is appended to the higher-level name. The 'x' is a place holder where additional information is included in the names, such as
Stimset-Epoch numbering or amplitudes.
Currently only pulse trains are supported with level two detail for Stimset-Epochs.
Depending on the setup of the data acquisition not every entry listed in the table has to appear in the epochs table.

The 'Details' key for the Stimset-Epoch can contain a combination of 'Mixed frequency' or 'Poisson distribution' with 'shuffled' as originally configured for the Stimset in WaveBuilder.

Pulse Trains
------------

Pulse Trains are a type of Stimset-Epochs which is widely used and covered in high detail in the epochs table. For pulse trains each pulse gets an level two epoch entry.
The time interval of a pulse begins when the signal is above base line level. It covers the time when the pulse is active and the signal at base line level until the next
pulse begins (or the Stimset-Epoch ends).
If the first pulse does not begin at the begin of the Stimset-Epoch an epoch named 'Baseline' is inserted.

This also applies for flipped Stimsets containing Stimset-Epochs with type pulse train.
