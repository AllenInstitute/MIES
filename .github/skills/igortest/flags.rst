.. vim: set et sts=3 sw=3 tw=79:

.. _flags:

Logical Flags
-------------

The following flags are binary set. One or more of them can apply at the same
time.

.. _flags_equalwave:

Equal Wave Flags
^^^^^^^^^^^^^^^^

These flags are used in :cpp:func:`CHECK_EQUAL_WAVES`

.. doxygengroup:: EqualWaveFlags
   :content-only:

.. _flags_testwave:

Test Wave Flags
^^^^^^^^^^^^^^^

The following flags are used in :cpp:func:`CHECK_WAVE`. Note that there is a
minor and a major wave type.

.. _flags_testwave_major:

MajorType
"""""""""

.. doxygengroup:: TestWaveFlagsMajor
   :content-only:

.. _flags_testwave_minor:

MinorType
"""""""""

.. doxygengroup:: TestWaveFlagsMinor
   :content-only:

.. _flags_IUTFBackgroundMonModes:

Background Monitor Modes
^^^^^^^^^^^^^^^^^^^^^^^^

The following constants are used with :cpp:func:`RegisterIUTFMonitor`. They define
the condition how multiple user tasks states are evaluated.

.. doxygengroup:: IUTFBackgroundMonModes
   :content-only:
