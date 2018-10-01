Labnotebook documentation for developers
****************************************

Overview
========

In MIES we store all metadata of the sweeps and the testpulse in a data
structure we call the "labnotebook". The general handling
is like an old-school paper lab journal where each entry has a date and time and
nothing is ever erased. Our digital version consists of four multi dimensional
arrays, one pair of `key`/`value` arrays for numerical data and another for
textual data.

Assuming you read the data from NWB files these arrays are located in
`/general/labnotebook/$device` and are called `numericalKeys`,
`numericalValues`, `textualKeys` and `textualValues`. Each pair, the `key` and
`value` array, is used to describe all metadata entries and also hold the value
of each entry.

Layout
======

The `key` array is two dimensional and has 3 rows

* 0: Parameter Name
* 1: Parameter Unit
* 2: Parameter Tolerance

and an arbitrary number of columns. Each column in the `key` array describes
one metadata entry in each column of the `value` array. The `value` array is
three dimensional and has an arbitrary number of rows (one row for each added
labnotebook entry) an arbitrary number of columns (one for each metadata entry)
and nine layers (the first eight hold headstage dependent data, the nineth
headstage independent data).

Encoding
========

The numerical arrays are IEEE-754 64bit floating point values, the textual
arrays are UTF-8 encoded.

Example `key` array
~~~~~~~~~~~~~~~~~~~

Rows are vertical, columns are horizontal.

+----------+----------------------------+-----------------+-----------------------+-----+
| SweepNum | TimeStampSinceIgorEpochUTC | EntrySourceType | V-Clamp Holding Level | ... |
+----------+----------------------------+-----------------+-----------------------+-----+
|          |                            |                 |  mV                   | ... |
+----------+----------------------------+-----------------+-----------------------+-----+
|          |                            |                 |  0.9                  | ... |
+----------+----------------------------+-----------------+-----------------------+-----+

Specification of the entries
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Parameter Name: Non-empty string
* Parameter Unit: SI/imperial unit with prefix or `%` or `On/Off` or empty
* Parameter Tolerance: Smallest meaningful difference or empty/`-` if it does not apply.

Example `value` array
~~~~~~~~~~~~~~~~~~~~~

Rows are vertical, columns are horizontal and only showing the first layer.

+----------+----------------------------+-----------------+-----------------------+-----+
| 0        | 3548850546.923             | 0               | 0.0004854951403103769 | ... |
+----------+----------------------------+-----------------+-----------------------+-----+
| 0        | 3548850566.0               | 1               | NaN                   | ... |
+----------+----------------------------+-----------------+-----------------------+-----+

Addition of new entries
~~~~~~~~~~~~~~~~~~~~~~~

When writing a new value into the labnotebook a new row is appended/filled in
the `value` array. This means we never overwrite old entries. Due to sweep
rollback (aka deleting existing sweeps and acquiring new sweeps) it can happen
that duplicated sweep numbers are present in the labnotebook. Each row holds
the entry source type, which tells you about the subsystem the entry originated
from, the possible values are

* 0: data acquisition
* 1: test pulse
* NaN: all other subsystems including user entries.

Caveats
=======

* Due to the design of the labnotebook you can *never* rely on the exact column
  number of an entry being constant or meaningful. Just because it is in the
  current version in row `5` does not mean it will be in the same row in the
  next version or in the next dataset.
* The dimensions of the arrays given above are minimum dimensions, they can
  anytime increase but will never decrease.
* Although we strive to not remove entries from the labnotebook, you should
  handle non-existing values gracefully or abort.
* Entries which are not present are either `NaN` or an empty string.
* Some entries are, for historical reasons, present in both the first layer and
  the headstage independent layer (nineth layer). New code should query the data
  from the headstage independent layer only.
* In case unassociated DA/AD channels were used during acquisition there are
  additional entries present which are formatted like `$entry UNASSOC_$channelNumber`
  and only have entries in the nineth layer (as it is by definition headstage
  independent data).
* One important concept is valid entries vs placeholder entries. All non-`NaN`
  or non-empty string entries are valid entries. Therefore only valid entries
  override other placeholder entries. But placeholder entries never override
  valid entries.
* This document describes the latest version of the labnotebook only. Some
  things will be different for older versions. In case you need to read these
  and got into trouble please contact `MIES@alleninstitute.org` for
  assistance.
* For internal technical reasons the `value` arrays will have some empty rows at the
  end.

Common Tasks
============

Getting a list of all available labnotebook entries
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Iterate over the columns of each `key` array and extract the name from the
first row.

Searching a labnotebook entry for a given sweep number
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Search the first row of the `key` arrays for the desired entry, remember the column
  index and which array holds the entry. Abort if it could not be found.
* Search the first row of the `key` array for the `SweepNum` entry and remember
  the column index. Abort if it could not be found.
* Search in the column of the sweep number in the corresponding `value` array
  *from back to front* for the desired sweep number. The result of that search is a
  *consecutive range* of rows.
* (Optional) Extract from the row range the entries with the desired entry
  source type.
* Search in the row range and the entry's column *from back to front* for the latest
  value of the desired entry. If the entry is present in the nineth layer the
  setting is headstage independent, otherwise the layer index with a
  non-empty/`NaN` entry denotes the headstage.
* Get the unit of the entry from the `key` arrays third row.

Searching the last sweep which has a given labnotebook entry
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Search the first row of the `key` arrays for the desired entry, remember the column
  index and which array holds the entry. Abort if it could not be found.
* Search the first row of the `key` array for the `SweepNum` entry and remember
  the column index. Abort if it could not be found.
* Search the corresponding `value` array *from back to front* for a
  non-empty/`NaN` entry in the given column. If the entry is present in the
  nineth layer the setting is headstage independent, otherwise the layer index
  with a non-empty/`NaN` entry denotes the headstage. Depending on your needs
  you might want to filter depending on entry source type as well.
* Read out the sweep number for the match from the sweep number column.

Getting all sweeps of a repeated acquisition cycle `RAC`
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* The entry named `Repeated Acq Cycle ID` is the same for sweeps which stem
  from the same repeated acquisition cycle.
* Search the first row of the `key` arrays for the `Repeated Acq Cycle ID`
  entry, remember the column index and which array holds the entry. Abort if it
  could not be found.
* Search the first row of the `key` array for the `SweepNum` entry and remember
  the column index. Abort if it could not be found.
* Search the corresponding `value` array *from back to front* for a
  non-empty/`NaN` entry in the given sweep number column. The result of that
  search is a *consecutive range* of rows.
* Search in this row range and the `RAC` column *from back to front* for a
  non-empty entry.
* Now collect all sweep numbers which have that `RAC` value

The related entry `Stimset Acq Cycle ID` (`SCI`) is an identifier which is
constant for a given headstage if the data stems from the same stimset, the
same RAC and had the same stimset cycle count.

Existing code
=============

Igor Pro
~~~~~~~~

See :ref:`Group LabnotebookQueryFunctions` for a list of all functions for querying the labnotebook.

Python
~~~~~~

An example on how to query the labnotebook can be found
`here <https://github.com/AllenInstitute/neuroanalysis/blob/master/neuroanalysis/miesnwb.py>`_
in the method `MiesNwb.notebook`.
