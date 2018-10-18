Important MIES concepts for developers
**************************************

This document should help new developers understand some of the guiding
principles behind MIES.

Coding Guidelines
-----------------

Can be found `here <http://www.igorexchange.com/project/CodingConventions>`_.

Documentation
-------------

Our documentation toolchain consists of doxygen/breathe/sphinx. All
documentation for the code should be in procedure files. All public accessible
functions should have a documentation block, for complex interfaces the use of
`@param` is recommended. See :cpp:func:`AFH_ExtractOneDimDataFromSweep` for an
example.

Caller/Callee graphs can be created by executing `doxygen` in `Packages/doc`
and can be browsed at `Packages/doc/html/index.html`.

The full documentation can be generated with `tools/build-documentation.sh`.

Global objects
--------------

Global objects like variables, strings, waves and datafolders should only be
used if necessary. Local variables, strings, free waves and free datafolders
should therefore be preferred if possible.

Reasons to use global objects:

* Persistent storage
* Performance reasons

All access to global objects *must* be handled via getter functions in
:ref:`File MIES_WaveDataFolderGetters.ipf` or :ref:`File MIES_GlobalStringAndVariableAccess.ipf`.
The documentation for these getter functions must include the wave layout, and
purpose of the object. This documentation should be the primary, and only,
source for finding out what the object holds. Using a single access point for
global objects allows to quickly find all users of that object.

For waves we use wave versioning, see :ref:`Group WaveVersioningSupport`. This is
done in order to enable a smooth upgrade when the wave layout changes and old
experiments are loaded with the old wave layout.

The use of dimension labels in waves for better readability is recommended.

User data on GUI objects or traces should only be used sparingly.

Convenience Wrapper
-------------------

Some Igor Pro functionality is wrapped in separate functions for better
readability and error checking. These include interacting with GUI controls,
see :ref:`File MIES_GuiUtilities.ipf`, checking strings :cpp:func:`IsEmpty` or numbers
:cpp:func:`IsFinite`.

Setting GUI values programmatically must always be done via
:cpp:func:`PGC_SetAndActivateControl` as that calls the GUI procedure as well.

Assertions
----------

We employ assertions to check function `invariants
<https://en.wikipedia.org/wiki/Invariant_(computer_science)>`_ . The relevant
functions are :cpp:func:`ASSERT` and :cpp:func:`ASSERT_TS`. Adding assertions
to the code greatly improves the error reporting capabilities of MIES and
should be used where appropriate.

Debug output
------------

MIES uses the `DEBUGGING_ENABLED` symbol for toggling compilation with and
without debug output. The relevant functions are :cpp:func:`DEBUGPRINT()`,
:cpp:func:`DEBUGPRINT_TS()`, :cpp:func:`DEBUGPRINTv()`,
:cpp:func:`DEBUGPRINTs()` and :cpp:func:`DEBUGPRINTSTACKINFO()`. The debug mode
can be toggled on a per-file basis from `MIES Panels->Advanced->Open debug
panel` or globally via :cpp:func:`EnableDebugMode()`/:cpp:func:`DisableDebugMode()`.

Dynamically growing waves
-------------------------

Often one is adding entries to a wave one at a time. In order to minimize the
performance cost one can employ a technique where the actual size of the wave
and the used size differ in order to minimize the number of resize operations.
The relevant functions are :cpp:func:`EnsureLargeEnoughWave` (with example
code), :cpp:func:`SetNumberInWaveNote` and :cpp:func:`GetNumberFromWaveNote`.

Datafolders
-----------

The current data folder (`cdf`) should never be set or expected to be something
fixed. For dealing with that environment the following functions have been
created: :cpp:func:`UniqueWaveName`, :cpp:func:`UniqueDataFolder`,
:cpp:func:`createDFWithAllParents` and :cpp:func:`GetListOfObjects`.

Deleting waves and datafolders
------------------------------

Due to the way Igor Pro works deleting a datafolder/wave may not succeed as the
object is currently in use. Use :cpp:func:`KillOrMoveToTrash` to work around
that issue.

Wave cache
----------

In order to avoid having to do the same lengthy calculation over and over again
MIES has a wave cache.  To use that cache you have to implement a function
which derives a key from all the input parameters and is unique for the
combination of parameters and different for all other combinations. This key is
then used to store and retrieve the wave from the cache. See :ref:`File
MIES_Cache.ipf` for further examples.

Background functions
--------------------

For DAQ we use a variety of background functions, all are listed at :ref:`Group
BackgroundFunctions`. For debugging purposes the background watchdog panel
from `MIES Panels->Advanced->Start Background ...` allows to view the state of
the background functions during execution.

Structured wave metadata
------------------------

Structured metadata can be stored and retrieved into/from the wave note using
:cpp:func:`GetNumberFromWaveNote`/:cpp:func:`SetNumberInWaveNote`,
:cpp:func:`GetStringFromWaveNote`/:cpp:func:`SetStringInWaveNote` and
:cpp:func:`AddEntryIntoWaveNoteAsList`/:cpp:func:`HasEntryInWaveNoteList`.

DA_Ephys panel
--------------

The main data acquisition panel is created via the window macro
:cpp:func:`DA_Ephys`. After changing it, be sure to call `MIES
Panels->Advanced->Reset And Store ...` for setting the default values and
recreating the window macro.

Access to the GUI control settings is done via the GUI state wave which caches
the settings for performance reasons. The functions
:cpp:func:`DAG_GetNumericalValue` and :cpp:func:`DAG_GetTextualValue` can be used to
query the values of (nearly) all GUI controls.

The names of GUI controls which come in groups, like headstages, DA/AD/TTL
channels must be derived by calling :cpp:func:`GetPanelControl`. Their state can be
queried with :cpp:func:`DAG_GetChannelState`.

Versioned panels
----------------

All panels are versioned. The version number must be increased if a stored
panel in an old experiment would misbehave with new code. The relevant
constants are :cpp:var:`DA_EPHYS_PANEL_VERSION`, :cpp:var:`DATABROWSER_PANEL_VERSION`,
:cpp:var:`SWEEPBROWSER_PANEL_VERSION` and :cpp:var:`WAVEBUILDER_PANEL_VERSION`.

Tabbed panels
-------------

For `TabControl` GUI elements we use routines from `ACL_TabUtilities.ipf` and
`ACL_UserdataEditor.ipf` for convenient programming.
