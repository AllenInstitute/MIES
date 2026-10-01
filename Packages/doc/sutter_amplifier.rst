.. _sutter_amplifier:

Sutter IPA amplifiers
=====================

The Sutter Instrument IPA and double IPA (dIPA) devices combine the data acquisition hardware and the
amplifiers in one device. MIES controls these amplifiers from the :ref:`daephys` panel in the same way as
MultiClamp 700B amplifiers, with the differences described below.

Requirements
------------

- The Sutter XOP (``SutterXOP``, version 2.60) must be installed. Without it MIES can not use Sutter devices
  and the amplifier control procedures ``IPA_Control.ipf`` from Sutter Instrument are not loaded.
- There is no separate amplifier control software like the MultiClamp Commander. The amplifiers are
  initialized when the device is locked in the DA_Ephys panel and released when it is unlocked. Locking
  resets the amplifier settings, see :ref:`sutter_settings_reset`.
- If the amplifiers can not be initialized, e.g. due to an incompatible Sutter XOP or a missing connection,
  a message is printed and the device is still locked, as for MCC amplifiers without a running MultiClamp
  Commander. The amplifiers can then not be used, test pulse and data acquisition on their headstages are
  refused. Unlock and lock the device again to retry the initialization.

Headstages and amplifier assignment
-----------------------------------

Each probe of the connected IPA devices is one MIES headstage, in the order of the devices and, for a double
IPA, its first and second headstage. The DA channel, AD channel and amplifier of each headstage are fixed and
assigned automatically when locking the device. Therefore the following controls of the Hardware tab are
disabled for Sutter devices: the DA/AD channel popups, ``Amplfier (700B)``, ``Clear Associations`` and
``Query connected Amp(s)``.

Gains and units
^^^^^^^^^^^^^^^

The Sutter XOP outputs and acquires the headstage signals in SI units, so the gains and units of the
headstages are fixed:

.. list-table::
   :header-rows: 1

   * - Clamp mode
     - DA gain and unit
     - AD gain and unit
   * - V-Clamp
     - 1000 mV/V, command in mV
     - 1e-12 A/pA, current in pA
   * - I-Clamp
     - 1e12 pA/A, command in pA
     - 1e-3 V/mV, voltage in mV

``Auto Fill`` in the Hardware tab fills in these fixed values. The gain setting of the amplifier does not
change them, it only selects the input range and resolution, see :ref:`sutter_settings_without_gui`.

Clamp modes
-----------

V-Clamp and I-Clamp are supported. I=0 is not supported by the Sutter amplifiers, its controls and
``Mode switch via I=0`` are disabled for Sutter devices.

In I-Clamp the command output range of the headstages is +/-20 nA. The DAScale of a stimulus set is limited
accordingly, analysis functions report a future DAScale value out of that range, as the output range of the
Sutter amplifiers can not be changed.

Amplifier controls
------------------

The amplifier controls of the Data Acquisition tab work for Sutter amplifiers, with these differences:

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Control
     - Behaviour with Sutter amplifiers
   * - Holding potential (V-Clamp)
     - 1 mV resolution.
   * - Holding current (I-Clamp)
     - 1 pA resolution, limited to +/-20 nA.
   * - Pipette offset
     - The amplifier has **one** pipette offset for both clamp modes, changing it in one clamp mode also
       changes it in the other one. The range is -250 mV to +249.98 mV. The automatic pipette offset
       (``Auto``) is meant to be used with the pipette in the bath.
   * - Bridge balance
     - 0 to 200 MΩ. There is no automatic bridge balance, its ``Auto`` button is disabled.
   * - Capacitance neutralization (I-Clamp)
     - 0 to 25 pF. The amplifier uses **the same value** as the fast capacitance compensation in V-Clamp,
       changing one of them also changes the other one.
   * - ``Cp Fast``
     - Automatic fast (electrode) capacitance compensation, to be used in the cell attached configuration.
       The amplifier applies the result immediately.
   * - ``Cp Slow``
     - Not available, the button is disabled.
   * - Whole cell compensation
     - Capacitance 0 to 100 pF, resistance 0 to 100 MΩ, only active in V-Clamp. The automatic whole cell
       compensation (``Auto``) requires the fast capacitance compensation (``Cp Fast``) first. It also sets
       the bridge balance to the resulting series resistance.
   * - Rs compensation
     - The enable checkbox enables correction and prediction together. ``Chain`` works as for MCC
       amplifiers.
   * - ``Auto Bias``
     - Works as for MCC amplifiers.

Settings which the amplifier changes as a side effect, like the pipette offset of the other clamp mode, are
updated in the DA_Ephys panel after writing a setting.

.. _sutter_settings_without_gui:

Settings without GUI controls
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The following amplifier settings have no control in the DA_Ephys panel yet. They can be set with
``IPA_SetValue(probe, setting, value)`` of the IPA control procedures on the Igor Pro command line, where
``probe`` is the headstage number plus one. They are documented in the labnotebook with every sweep.

.. list-table::
   :header-rows: 1
   :widths: 20 20 60

   * - Setting
     - ``IPA_SetValue`` keyword
     - Remarks
   * - Primary output low pass filter
     - ``Filter``
     - 500 Hz, 1 kHz, 2 kHz, 5 kHz, 10 kHz or 20 kHz, one filter for both clamp modes. Other values are
       rounded to the next one, there is no bypass.
   * - Primary output gain
     - ``IGain`` (V-Clamp), ``VGain`` (I-Clamp)
     - 0.5 to 25 mV/pA in V-Clamp and 10 to 500 mV/mV in I-Clamp. As the data is acquired in SI units, the
       gain only selects the input range of +/-10 V divided by the gain and the resolution. Large gains
       therefore clip the signal, e.g. with ``VGain`` 500 the I-Clamp input is limited to +/-20 mV.
   * - Dynamic hold
     - ``DynHoldOn``, ``DynHold``
     - I-Clamp only, keeps the membrane potential at the given level by a slow current injection.

.. _sutter_settings_reset:

Settings when locking
^^^^^^^^^^^^^^^^^^^^^

The IPA control procedures store the amplifier settings in their package preferences on disk. To start
with a defined state, MIES resets all amplifier settings to their defaults when locking a Sutter device,
instead of applying the settings of the previous session:

- holding potential and holding current, pipette offset, bridge balance, capacitance neutralization, whole
  cell compensation and Rs compensation are zero and disabled, the fast capacitance compensation is 0.1 pF
- dynamic hold is off
- the primary output filter is 5 kHz, the gain is 5 mV/pA in V-Clamp and 100 mV/mV in I-Clamp

The amplifier controls of the DA_Ephys panel are updated to this state, so that the panel shows the
settings of the amplifier. Settings changed with ``IPA_SetValue`` during a session therefore have to be set
again after locking the device.

Labnotebook
-----------

Settings of Sutter amplifiers with an MCC counterpart use the existing amplifier labnotebook entries, see
:doc:`labnotebook-descriptions`. The following entries are only written for Sutter amplifiers:

- ``V-Clamp Output Gain``, ``I-Clamp Output Gain``
- ``RsComp Lag``
- ``Dynamic Hold Enable``, ``Dynamic Hold Level``
- ``Amplifier Serial Number`` (text)

The entries only available for MCC amplifiers, like the slow capacitance compensation, are not written.
Except for the clamp mode, which is read back from the amplifier, the values are the settings sent to the
amplifier, as the Sutter amplifiers can not report their settings.

Configuration files
-------------------

The headstage association of a DA_Ephys configuration stores the amplifier type of each headstage. For
Sutter amplifiers only the amplifier type and the probe are stored, as the amplifier settings can not be
restored yet. When restoring a configuration:

- The Sutter amplifiers keep their fixed assignment. A configuration with MCC amplifiers can therefore be
  restored on a Sutter device, the headstages then keep their Sutter amplifier and a message is printed.
- The restore aborts if the Sutter probe stored for a headstage does not match the connected IPA devices.

Analysis functions
------------------

- The analysis function parameter ``AmpBesselFilter`` of :cpp:func:`PSQ_Chirp` only accepts the low pass
  filter values of the Sutter amplifiers listed above and no ``Bypass``.
- Sutter devices have four asynchronous channels.
- Requesting the automatic bridge balance via the foreign function interface aborts for Sutter amplifiers.

Known limitations
-----------------

- The double IPA is supported by the headstage assignment, but has not been tested with hardware yet.
