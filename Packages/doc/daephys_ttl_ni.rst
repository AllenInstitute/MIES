.. _daephys_ttl_ni:

TTL channels on NI DAC devices
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

MIES supports up to 8 TTL output channels on NI DAC devices. On NI hardware
these TTL channels are delivered through Digital I/O (DIO) Port 0.

Physical connections
^^^^^^^^^^^^^^^^^^^^

The mapping between MIES TTL channel numbers, NI DAQmx channel names, and the
connector labels used on NI hardware is:

.. list-table::
   :header-rows: 1

   * - MIES TTL channel
     - NI DAQmx channel name
     - Physical connector label
   * - TTL0
     - ``/{DeviceName}/port0/line0``
     - ``P0.0``
   * - TTL1
     - ``/{DeviceName}/port0/line1``
     - ``P0.1``
   * - TTL2
     - ``/{DeviceName}/port0/line2``
     - ``P0.2``
   * - TTL3
     - ``/{DeviceName}/port0/line3``
     - ``P0.3``
   * - TTL4
     - ``/{DeviceName}/port0/line4``
     - ``P0.4``
   * - TTL5
     - ``/{DeviceName}/port0/line5``
     - ``P0.5``
   * - TTL6
     - ``/{DeviceName}/port0/line6``
     - ``P0.6``
   * - TTL7
     - ``/{DeviceName}/port0/line7``
     - ``P0.7``

- ``{DeviceName}`` is the NI-assigned device name shown in NI MAX, for example
  ``Dev1``.
- The exact physical pin number for each ``P0.x`` label depends on the device
  model and the terminal block accessory in use. Consult the NI device pinout
  diagram and the documentation for the connected terminal block.
- MIES always uses Port 0 (``HARDWARE_NI_TTL_PORT = 0``). This is fixed in the
  source code and cannot be changed from the GUI.

PFI pins
^^^^^^^^

NI devices also provide PFI (Programmable Function Interface) pins such as
``PFI0`` and ``PFI1``. These pins are digital lines, but they are not the TTL
data channels exposed by MIES on Port 0.

MIES utilizes PFI pins internally to manage timing and triggering tasks.
Specifically, MIES uses PFI pins to synchronize data acquisition across
multiple NI boards. For example, two NI PCIe-6343 boards can be combined to
obtain 8 analog output channels by sharing start triggers and the sample
clock over PFI lines.

The ``P0.x`` pins listed above are the MIES TTL output channels and are
controlled from the DA_Ephys TTL tab.

Pipette pressure control
^^^^^^^^^^^^^^^^^^^^^^^^

The MIES TTL output channels on Port 0 serve as control lines for actuating
solenoid valves that regulate pipette pressure, enabling switching of the
pipette tip between user-applied pressure, the pressure regulator, and
atmospheric pressure.

Enabling TTL channels in MIES
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To enable TTL output channels in MIES:

#. Open the DA_Ephys panel.
#. Go to the TTL tab.
#. Check the TTL channel that you want to enable.
#. Select a stimulus set for that channel from the drop-down menu.

Hardware notes
^^^^^^^^^^^^^^

- MIES uses Port 0 exclusively on all supported NI devices.
- The NI USB-6356 provides 8 DIO lines on Port 0 (``P0.0`` to ``P0.7``),
  supporting all 8 MIES TTL channels.
- TTL channels are output-only during data acquisition. Do not drive these pins
  externally while MIES is running.
- Each TTL channel is independent and can carry a different stimulus waveform.
