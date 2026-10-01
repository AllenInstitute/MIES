.. _amplifier_interaction:

Amplifier interaction
=====================

MIES supports two amplifier families: the Molecular Devices MultiClamp 700B (MCC), controlled via the MCC and
Axon Telegraph XOPs and the MultiClamp Commander, and the amplifiers integrated in the Sutter Instrument IPA
and double IPA devices, controlled via the Sutter XOP and the IPA control procedures from Sutter. See
:ref:`sutter_amplifier` for the user documentation of the Sutter amplifiers.

Code structure
--------------

.. list-table::
   :header-rows: 1
   :widths: 35 10 55

   * - File
     - Prefix
     - Content
   * - ``MIES_AmplifierInteraction.ipf``
     - ``AI_``
     - Amplifier independent code and the public interface. The public functions dispatch to the
       implementation of the amplifier type.
   * - ``MIES_AmplifierInteraction_MolecularDevices.ipf``
     - ``AI_MCC_``
     - MCC implementation. Hardware accessing functions are only compiled with the MCC XOPs present
       (``AMPLIFIER_XOPS_PRESENT``), otherwise placeholders are used.
   * - ``MIES_AmplifierInteraction_Sutter.ipf``
     - ``AI_SU_``
     - Sutter implementation. Functions using ``IPA_Control.ipf`` are only compiled with the Sutter XOP present
       (``SUTTER_AMPLIFIER_PRESENT``), otherwise placeholders are used.
   * - ``IPA_Control.ipf``
     - ``IPA_``
     - IPA control procedures from Sutter Instrument, only included with the Sutter XOP present, see
       :ref:`ipa_control`.

Amplifier types
---------------

Each headstage has an amplifier type, one of ``AMPLIFIER_TYPE_NONE``, ``AMPLIFIER_TYPE_MCC`` or
``AMPLIFIER_TYPE_SUTTER``. It is stored in the ``AmpType`` row of :cpp:func:`GetChanAmpAssign`, together with
the serial number and channel of MCC amplifiers or the probe index of Sutter amplifiers in ``AmpChannelID``.
Waves created before the amplifier type existed are upgraded to MCC for headstages with a valid serial number
and channel and to no amplifier otherwise.

- :cpp:func:`AI_GetAmplifierType` and :cpp:func:`AI_HasAmplifier` are the only places to query the amplifier
  association of a headstage.
- Each device supports amplifiers of a single type, see :cpp:func:`AI_GetAmplifierTypeOfDevice`. Sutter
  devices have integrated amplifiers, all other devices use MCC amplifiers.
- The allowed amplifier types of the headstages of a device are defined in
  :cpp:func:`AI_GetAllowedAmplifierTypes`: MCC or none for MCC devices, only Sutter for Sutter devices.
  Allowing headstages without amplifier for Sutter devices only requires to change this function.

Dispatching
^^^^^^^^^^^

The public ``AI_`` functions dispatch to the ``AI_MCC_``/``AI_SU_`` implementations:

- Functions working on a single headstage dispatch by the amplifier type of that headstage. Headstages
  without amplifier return the same values as the MCC implementation did for them, e.g. ``NaN`` for
  :cpp:func:`AI_ReadFromAmplifier`.
- Functions working on multiple headstages, or not related to a headstage, dispatch by the amplifier type
  of the device.

Functions which use the amplifier only via :cpp:func:`AI_SelectMultiClamp`, :cpp:func:`AI_SendToAmp` and
``AI_EnsureCorrectMode``, like ``AI_UpdateAmpModel`` or ``AI_ZeroAmps``, are amplifier independent and live in
``MIES_AmplifierInteraction.ipf``. Side effects of writing a setting which depend on the amplifier, e.g. the
Sutter pipette offset being shared between the clamp modes, are handled by the ``UpdateDependentSettings``
functions of each implementation, which ``AI_UpdateAmpModel`` calls after writing.

Amplifier list entries
^^^^^^^^^^^^^^^^^^^^^^

:cpp:func:`AI_GetAmplifierList`, :cpp:func:`AI_GetAmplifierDef` and :cpp:func:`AI_ParseAmplifierDef` create
and parse the entries of the amplifier popup in the Hardware tab. MCC entries contain serial number and
channel, Sutter entries the IPA device serial and the headstage on that device, e.g. ``IPA_E_100170 HS 1``.
Devices with integrated amplifiers have a fixed amplifier per headstage, see
:cpp:func:`AI_GetFixedAmplifierDef`, which DA_Ephys assigns when locking.

Initialization
^^^^^^^^^^^^^^

:cpp:func:`AI_InitializeAmplifiers` and :cpp:func:`AI_ShutdownAmplifiers` are called when locking and unlocking a
device. MCC amplifiers are independent of the device and need no initialization. For Sutter devices the IPA
control procedures are initialized, switched to live mode and the clamp modes of MIES are sent, as the
stored control values of the package do not reflect the amplifier state.

Settings and labnotebook
^^^^^^^^^^^^^^^^^^^^^^^^

:cpp:func:`AI_SendToAmp` accepts the MCC function constants (``MCC_*_FUNC``) for all amplifier types. The
Sutter implementation maps them to the keywords of the IPA control procedures, including the unit
conversion, and returns ``NaN`` for functions without Sutter counterpart. Values are set with
``IPA_MIES_SetValue``, which does not change the enable state of a setting, and read from the stored
values of the package, as the amplifier can not be read back except for the clamp mode and the gain.

:cpp:func:`AI_FillAndSendAmpliferSettings` documents the amplifier settings in the labnotebook. Sutter settings
with an MCC counterpart use the existing keys, the others get their own keys in
:cpp:func:`GetSutterAmplifierSettingsKeyWave` and ``GetSutterAmplifierSettingsTextKeyWave`` so that the
labnotebooks of MCC amplifiers stay unchanged.

The Sutter headstage outputs are in Ampere in current clamp, so :cpp:func:`HW_GetDataRange` requires the
clamp mode for associated DA channels of Sutter devices.

Configuration
^^^^^^^^^^^^^

The headstage association of a configuration stores the amplifier type. Configurations without amplifier
type are read as MCC, as only MCC amplifiers existed for them. See :ref:`sutter_amplifier` for the restore
behaviour of Sutter amplifiers.

.. _ipa_control:

IPA control procedures
----------------------

``IPA_Control.ipf`` is the amplifier control package provided by Sutter Instrument. It is kept as close as
possible to the original:

- Changes to the original code follow its coding style and are kept minimal. Each fix of a bug in Sutter's
  code is a separate commit which states that it is a fix in Sutter's code.
- Functions needed by MIES are added in a separate section at the end of the file with the prefix
  ``IPA_MIES_`` and follow the MIES coding conventions, e.g. ``IPA_MIES_SetClampMode``, which uses the probe
  index over all IPA devices, or ``IPA_MIES_SetValue``/``IPA_MIES_GetValue``.
- The package addresses the headstages by the one based probe number over all IPA devices, MIES uses the
  zero based headstage number.
- The package stores its control values, including gain and filter, in its package preferences. These
  survive restarts of Igor Pro and are not reset by MIES or the tests.
- The file is only included with the Sutter XOP present, so all MIES code calling it must be guarded with
  ``#if exists("SutterDAQScanWave")``. The CI has no Sutter XOP and no Sutter hardware.
- The file is excluded from the doxygen documentation.

Testing
-------

- The hardware tests run with Sutter hardware via the experiments ``HardwareBasic-SUTTER.pxp`` and
  ``HardwareAnalysisFunctions-SUTTER.pxp``, which define ``TESTS_WITH_SUTTER_HARDWARE``.
- ``UTF_IPAControl.ipf`` tests the functions of ``IPA_Control.ipf`` which MIES does not use directly.
- As the CI has no Sutter hardware, changes to the Sutter support or to shared amplifier, configuration or
  analysis function code must be tested locally with an IPA.
- Check the gain and filter of the IPA control procedures before a test run, see above. With a large
  current clamp gain the input is clipped, e.g. to +/-20 mV with ``VGain`` 500.

Amplifier feature comparison
----------------------------

The following tables compare the amplifier settings of MCC and Sutter amplifiers and how MIES maps them.
The MCC columns are taken from the MIES implementation, the MCC behaviour itself is taken from the MCC
documentation. The Sutter columns are taken from ``IPA_Control.ipf`` and were checked with a single IPA and a
model cell with the positions "Cell" (about 12 MΩ, 29 pF, 520 MΩ), "Seal" (above 1.7 GΩ, 9 pF) and "Bath"
(10 MΩ).

- AmpStorage: row label in :cpp:func:`GetAmplifierParamStorageWave`
- Labnotebook key: entry of :cpp:func:`GetAmplifierSettingsKeyWave` or
  :cpp:func:`GetAmplifierSettingsTextKeyWave`
- Sutter storage: field of the stored control values of ``IPA_Control.ipf``. Only the clamp mode and the
  gain can be read back from the hardware, all other values are the stored ones.

Settings available for MCC and Sutter amplifiers
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. list-table::
   :header-rows: 1
   :widths: 10 5 17 10 12 14 16 16

   * - Concept
     - Mode
     - MCC function / control
     - AmpStorage
     - Labnotebook key
     - Sutter keyword / storage
     - Differences MCC and Sutter
     - Hardware check
   * - Clamp mode
     - all
     - :cpp:func:`AI_SetClampMode`, ``Radio_ClampMode_*``
     - --
     - ``Operating Mode``, ``OperatingModeString``, generic ``Clamp Mode``
     - ``VCMode``/``CCMode``, ``IPA_MIES_SetClampMode``; ``vc`` (0 VC, 2 CC), read back via
       ``SutterDAQRead(unit, 0)``
     - No I=0 for Sutter. A mode switch sends all stored settings of the probe.
     - Works, read back matches.
   * - Holding potential
     - VC
     - ``MCC_HOLDING_FUNC``, ``setvar_DataAcq_Hold_VC``
     - ``HoldingPotential``
     - ``V-Clamp Holding Level``
     - ``VHold``; ``hpot`` (mV)
     - 1 mV resolution. ``VHold`` also enables the holding. ``IPA_GetValue`` returns 0 when disabled.
     - 20 mV give 38.5 pA in "Cell", 1 mV steps.
   * - Holding potential enable
     - VC
     - ``MCC_HOLDINGENABLE_FUNC``, ``check_DatAcq_HoldEnableVC``
     - ``HoldingPotentialEnable``
     - ``V-Clamp Holding Enable``
     - ``VHoldOn``; ``hpoton``
     - --
     - Works.
   * - Holding current
     - IC
     - ``MCC_HOLDING_FUNC``, ``setvar_DataAcq_Hold_IC``
     - ``BiasCurrent``
     - ``I-Clamp Holding Level``
     - ``IHold``; ``hcurr`` (pA), +/-20 nA
     - 1 pA resolution. ``IHold`` also enables the holding.
     - 100 pA give 51 mV in "Cell".
   * - Holding current enable
     - IC
     - ``MCC_HOLDINGENABLE_FUNC``, ``check_DatAcq_HoldEnable``
     - ``BiasCurrentEnable``
     - ``I-Clamp Holding Enable``
     - ``IHoldOn``; ``hcurron``
     - --
     - Works.
   * - Pipette offset
     - VC, IC
     - ``MCC_PIPETTEOFFSET_FUNC``, ``setvar_DataAcq_PipetteOffset_VC``/``_IC``
     - ``PipetteOffsetVC``, ``PipetteOffsetIC``
     - ``Pipette Offset``
     - ``Offset``; ``offset`` (DAC value, 2^16/V), -250 to +249.98 mV
     - **One value for both clamp modes** for Sutter, MIES stores two. VC: added to the command, IC:
       subtracted from the measured voltage.
     - Works.
   * - Auto pipette offset
     - VC, IC
     - ``MCC_AUTOPIPETTEOFFSET_FUNC``, ``button_DataAcq_AutoPipOffset_VC``/``_IC``
     - --
     - --
     - ``AutoOffset``; writes ``offset``
     - Adds the liquid junction potential, refused with ``OffsetLock``. Meant for the bath.
     - In "Bath" -0.2 to -0.5 mV within 1 to 2 s, in "Cell" unreliable.
   * - Bridge balance
     - IC
     - ``MCC_BRIDGEBALRESIST_FUNC``, ``setvar_DataAcq_BB``
     - ``BridgeBalance``
     - ``Bridge Bal Value``
     - ``Bridge``; ``bridge`` (MΩ), 0 to 200 MΩ
     - ``Bridge`` also enables it. ``AutoCellComp`` sets it to the series resistance.
     - 50 MΩ at 100 pA: -5.05 mV.
   * - Bridge balance enable
     - IC
     - ``MCC_BRIDGEBALENABLE_FUNC``, ``check_DatAcq_BBEnable``
     - ``BridgeBalanceEnable``
     - ``Bridge Bal Enable``
     - ``BridgeOn``; ``bridgeon``
     - --
     - Works.
   * - Capacitance neutralization
     - IC
     - ``MCC_NEUTRALIZATIONCAP_FUNC``, ``setvar_DataAcq_CN``
     - ``CapNeut``
     - ``Neut Cap Value``
     - ``ECompMag``; ``fastmag`` (pF), 0 to 25 pF
     - **Shared with the fast capacitance compensation** for Sutter, MCC has separate values. In IC 0.4 pF
       are added when sending.
     - "Cell" oscillates from 11 pF.
   * - Capacitance neutralization enable
     - IC
     - ``MCC_NEUTRALIZATIONENABL_FUNC``, ``check_DatAcq_CNEnable``
     - ``CapNeutEnable``
     - ``Neut Cap Enabled``
     - ``ECompOn``; ``capneuton``
     - Only effective in IC.
     - Works.
   * - Whole cell compensation
     - VC
     - ``MCC_WHOLECELLCOMPCAP_FUNC``, ``MCC_WHOLECELLCOMPRESIST_FUNC``, ``MCC_WHOLECELLCOMPENABLE_FUNC``;
       ``setvar_DataAcq_WCC``, ``setvar_DataAcq_WCR``, ``check_DatAcq_WholeCellEnable``
     - ``WholeCellCap``, ``WholeCellRes``, ``WholeCellEnable``
     - ``Whole Cell Comp Cap``, ``Whole Cell Comp Resist``, ``Whole Cell Comp Enable``
     - ``CmComp``, ``RsComp``, ``RsCompOn``; ``cmcomp`` (pF, 0 to 100), ``rscomp`` (MΩ, 0 to 100), ``compon``
     - ``RsCompOn`` is the whole cell compensation enable, not the Rs compensation enable. ``CmComp`` and
       ``RsComp`` also enable it. Off in IC.
     - Best cancellation at 29 pF and 10 to 12 MΩ in "Cell".
   * - Fast capacitance compensation
     - VC
     - ``MCC_FASTCOMPCAP_FUNC``, ``MCC_FASTCOMPTAU_FUNC`` (no GUI)
     - --
     - ``Fast compensation capacitance``, ``Fast compensation time``
     - ``ECompMag``, ``ECompTau``; ``fastmag`` (pF), ``fastphase`` (µs, 0.1 to 4.5)
     - Shared with the capacitance neutralization.
     - "Seal": 8.96 pF and 1.14 µs reduce the 3.4 nA spike to 35 pA.
   * - Auto fast compensation
     - VC
     - ``MCC_AUTOFASTCOMP_FUNC``, ``button_DataAcq_FastComp_VC``
     - ``FastCapacitanceComp``
     - --
     - ``AutoEComp``; result read back from the hardware
     - The amplifier applies the result immediately. Must be done in the cell attached configuration.
     - Works in "Seal", wrong in "Cell".
   * - Auto whole cell compensation
     - VC
     - ``MCC_AUTOWHOLECELLCOMP_FUNC``, ``button_DataAcq_WCAuto``
     - --
     - --
     - ``AutoCellComp``; result read back from the hardware
     - The amplifier applies the result immediately. Requires the fast compensation first. Also sets the
       bridge balance to the series resistance.
     - After ``AutoEComp``: 27.2 pF and 10.3 MΩ in "Cell", without it wrong.
   * - Rs compensation enable
     - VC
     - ``MCC_RSCOMPENABLE_FUNC``, ``check_DatAcq_RsCompEnable``
     - ``RsCompEnable``
     - ``RsComp Enable``
     - ``RsCorrOn``; ``corron``
     - Enables prediction and correction together.
     - Effect visible, not quantified.
   * - Rs correction
     - VC
     - ``MCC_RSCOMPCORRECTION_FUNC``, ``setvar_DataAcq_RsCorr``
     - ``Correction``
     - ``RsComp Correction``
     - ``RsCorr``; ``rscorr``
     - Sutter takes a fraction, MIES uses %. ``RsCorr`` also enables ``corron``. Uses ``rscomp`` of the whole
       cell compensation.
     - Effect visible, not quantified.
   * - Rs prediction
     - VC
     - ``MCC_RSCOMPPREDICTION_FUNC``, ``setvar_DataAcq_RsPred``
     - ``Prediction``
     - ``RsComp Prediction``
     - ``RsPred``; ``rspred``
     - Fraction vs. %. ``RsPred`` also enables ``corron`` and ``compon``.
     - Not checked separately.
   * - Rs compensation bandwidth / lag
     - VC
     - ``MCC_RSCOMPBANDWIDTH_FUNC`` (no GUI)
     - --
     - ``RsComp Bandwidth``; Sutter: ``RsComp Lag``
     - ``RsLag``; ``lag`` (µs, 20 to 200)
     - Bandwidth (Hz) vs. lag time (s), related but not identical.
     - No difference between the lag values 1023 and 1024.
   * - Primary output gain
     - VC, IC
     - ``MCC_PRIMARYSIGNALGAIN_FUNC`` (no GUI), telegraph
     - --
     - ``Alpha``, ``Scale Factor``, ``Scale Factor Units``, ``ScaleFactorUnitsString``; Sutter:
       ``V-Clamp Output Gain``, ``I-Clamp Output Gain``
     - ``IGain`` (VC, 0.5 to 25 mV/pA), ``VGain`` (IC, 10 to 500 mV/mV); ``gainvc``, ``gaincc``, read back
       via ``SutterDAQRead(unit, 0)``
     - The Sutter data is always in SI units, the MIES gains are fixed. The gain only selects the input range
       (10 V / gain) and the resolution.
     - Works, read back matches the set gain.
   * - Primary output low pass filter
     - VC, IC
     - ``MCC_PRIMARYSIGNALLPF_FUNC`` (no GUI), telegraph
     - --
     - ``LPF Cutoff``
     - ``Filter``; ``filter`` (500 Hz to 20 kHz)
     - One filter for both clamp modes for Sutter, no bypass.
     - Rise times of 500 Hz and 1 kHz as expected.
   * - Serial number
     - --
     - telegraph
     - --
     - ``Serial Number``; Sutter: ``Amplifier Serial Number`` (text)
     - ``AmpSN``
     - The Sutter serial is a string, e.g. ``IPA_E_100170``. ``AmpSN`` omits the device type digit and returns
       170, MIES stores 100170 in ``Serial Number`` and the string in ``Amplifier Serial Number``.
     - --
   * - Channel
     - --
     - telegraph
     - --
     - ``Channel ID``
     - --; ``HSindex`` (0/1 on dIPA)
     - --
     - --
   * - Hardware type
     - --
     - telegraph
     - --
     - ``Hardware Type``, ``HardwareTypeString``
     - ``AmpType``
     - IPA or dIPA.
     - --
   * - Membrane capacitance, series resistance (telegraph)
     - VC
     - telegraph
     - --
     - ``Membrane Cap``, ``Series Resistance``
     - ``CmComp``, ``RsComp``
     - The MCC telegraph reports the whole cell compensation values.
     - --
   * - Slow holding / dynamic hold
     - IC
     - ``MCC_SLOWCURRENTINJENABL_FUNC``, ``MCC_SLOWCURRENTINJLEVEL_FUNC``, ``MCC_SLOWCURRENTINJSETLT_FUNC``
       (no GUI)
     - --
     - ``Slow current injection``, ``Slow current injection level``, ``Slow current injection settling time``;
       Sutter: ``Dynamic Hold Enable``, ``Dynamic Hold Level``
     - ``DynHoldOn``, ``DynHold``; ``trackon``, ``track`` (mV)
     - Both keep the membrane potential at a level by a slow current injection. Sutter has no settling time.
       The hardware keeps the dynamic hold across mode switches.
     - -50 mV reached within about 1 s.

MCC only
^^^^^^^^

.. list-table::
   :header-rows: 1
   :widths: 30 10 35 25

   * - Concept
     - Mode
     - MCC function / control
     - Labnotebook key
   * - Slow capacitance compensation, tau x20, auto
     - VC
     - ``MCC_SLOWCOMPCAP_FUNC``, ``MCC_SLOWCOMPTAU_FUNC``, ``MCC_SLOWCOMPTAUX20ENAB_FUNC``,
       ``MCC_AUTOSLOWCOMP_FUNC``, ``button_DataAcq_SlowComp_VC``
     - ``Slow compensation capacitance``, ``Slow compensation time``
   * - Auto bridge balance
     - IC
     - ``MCC_AUTOBRIDGEBALANCE_FUNC``, ``button_DataAcq_AutoBridgeBal_IC``
     - --
   * - Oscillation killer
     - VC
     - ``MCC_OSCKILLERENABLE_FUNC``
     - ``Osc Killer Enable``
   * - Secondary output gain and low pass filter, primary output high pass filter
     - all
     - ``MCC_SECONDARYSIGNALGAIN_FUNC``, ``MCC_SECONDARYSIGNALLPF_FUNC``, ``MCC_PRIMARYSIGNALHPF_FUNC``
     - ``Secondary Alpha``, ``Secondary LPF Cutoff``
   * - Separate fast compensation and capacitance neutralization values
     - VC, IC
     - ``MCC_FASTCOMPCAP_FUNC``, ``MCC_NEUTRALIZATIONCAP_FUNC``
     - ``Fast compensation capacitance``, ``Neut Cap Value``
   * - Telegraph metadata
     - --
     - telegraph
     - ``ComPort ID``, ``AxoBus ID``, ``Scaled Out Signal``, ``Ext Cmd Sens``, ``Raw Out Signal``,
       ``Raw Scale Factor``, ``Raw Scale Factor Units``
   * - I=0
     - I=0
     - :cpp:func:`AI_SetClampMode`
     - --

Sutter only
^^^^^^^^^^^

These settings are not used by MIES.

.. list-table::
   :header-rows: 1
   :widths: 25 25 15 35

   * - Concept
     - Sutter keyword
     - Sutter storage
     - Remarks
   * - Liquid junction potential
     - --
     - ``LJP``
     - Added by ``AutoOffset``.
   * - Offset lock
     - ``OffsetLock``
     - ``offsetlock``
     - Blocks ``AutoOffset``.
   * - Seal test
     - ``SealTest``
     - ``seal``
     - Amplifier internal, 100 ms, not on the second headstage of a dIPA. Works in VC.
   * - Buzz
     - ``Buzz``
     - --
     - IC only, +/-1 V for about 2 ms.
   * - Digital outputs
     - ``DigOutWord``, ``DigOut1`` to ``DigOut8``
     - ``dout``
     - Per device, not per headstage.
   * - Aux outputs and inputs
     - ``AuxOut1``, ``AuxOut2``, ``AuxIn1`` to ``AuxIn4``
     - ``analogOut``, ``analogIn``
     - --
   * - DAC offset trim
     - --
     - ``DACOffset``
     - Only used at reset.
   * - Reset, reconnect
     - ``Reset``, ``Reconnect``
     - --
     - ``Reset`` only resets the stored values.

MIES only
^^^^^^^^^

These features have no amplifier function and work for both amplifier types.

.. list-table::
   :header-rows: 1
   :widths: 30 35 20 15

   * - Concept
     - Control
     - AmpStorage
     - Labnotebook key
   * - Rs correction/prediction chaining
     - ``check_DataAcq_Amp_Chain`` (``MCC_NO_AMPCHAIN_FUNC``)
     - ``RSCompChaining``
     - --
   * - Autobias
     - ``check_DataAcq_AutoBias``, ``setvar_DataAcq_AutoBiasV``, ``setvar_DataAcq_AutoBiasVrange``,
       ``setvar_DataAcq_IbiasMax`` (``MCC_NO_AUTOBIAS_*``)
     - ``AutoBias*``
     - ``Autobias``, ``Autobias Vcom``, ``Autobias Vcom variance``, ``Autobias Ibias max``
   * - Pipette offset zeroing from the test pulse baseline
     - ``AI_ZeroAmps``
     - --
     - --

Consequences for the implementation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

- Only the clamp mode and the gain of Sutter amplifiers can be read back from the hardware. The labnotebook
  therefore documents the stored values of ``IPA_Control.ipf``.
- The pipette offset and the fast compensation/capacitance neutralization are one value per probe for
  Sutter amplifiers, MIES has separate controls for them. Writing one of them updates the other one.
- Setting several Sutter values also enables them (``VHold``, ``IHold``, ``Bridge``, ``CmComp``, ``RsComp``,
  ``RsCorr``, ``RsPred``), while MIES sends value and enable state separately. ``IPA_MIES_SetValue`` sets the
  value without changing the enable state.
- ``AutoEComp`` needs the cell attached configuration and ``AutoCellComp`` needs the fast compensation first.
  ``AutoCellComp`` also overwrites the bridge balance.
