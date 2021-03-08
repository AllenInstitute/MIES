.. This file is part of the `IPNWB` project and licensed under BSD-3-Clause.

Igor Pro module for reading and writing NeurodataWithoutBorder files
--------------------------------------------------------------------

This modules allows to easily write and read valid `NeurodataWithoutBorder
<https://nwb.org>`__ style HDF5 files. It encapsulates the most commonly used
parts of the specification in easy to use functions.

Main features
^^^^^^^^^^^^^

* Read and write NWB compliant files

  - `specification version 1.0.5, Aug 8 2016 <https://github.com/NeurodataWithoutBorders/specification/raw/master/version_1.0.5_beta/nwb_file_format_specification_1.0.5_beta.pdf>`__
  - `specification version 2.2.0 <NWB2HTML>`_, January 2020

* Compatible with Igor Pro 7 or later on Windows/MacOSX
* Requires the stock HDF5 XOP only

.. _NWB105HTML: https://htmlpreview.github.io/?https://raw.githubusercontent.com/NeurodataWithoutBorders/specification_nwbn_1_0_x/master/version_1.0.5_beta/nwb_file_format_specification_1.0.5_beta.html
.. _NWB105PDF: https://github.com/NeurodataWithoutBorders/specification/raw/master/version_1.0.5_beta/nwb_file_format_specification_1.0.5_beta.pdf
.. _NWB2HTML: https://nwb-schema.readthedocs.io/en/latest/format_description.html

Installation
^^^^^^^^^^^^

* Quit Igor Pro
* Install the HDF5 XOP and the HDF5 Browser as described in ``DisplayHelpTopic
  "Installing The HDF5 Package"``
* Create the following shortcut in
  ``C:\Users\$username\Documents\WaveMetrics\Igor Pro [78] User Files``

  * In "Igor Procedures" a shortcut pointing to the basefolder of the IPNWB
    package

* Restart Igor Pro

Examples
^^^^^^^^

The following examples show how to read and write into NWB version 1.0.5

writing into NWB
~~~~~~~~~~~~~~~~

.. literalinclude:: examples/IPNWB_Examples_Writer.ipf
   :language: igorpro

reading from NWB
~~~~~~~~~~~~~~~~

.. literalinclude:: examples/IPNWB_Examples_Reader.ipf
   :language: igorpro

NWB file format description
^^^^^^^^^^^^^^^^^^^^^^^^^^^

- Datasets which originate from Igor Pro waves have the special attributes
  IGORWaveScaling, IGORWaveType, IGORWaveUnits, IGORWaveNote. These attributes
  allow easy and convenient loading of the data into Igor Pro back.
- For AD/DA/TTL groups the naming scheme is data\_\ ``XXXXX``\ \_[AD/DA/TTL]
  ``suffix`` where ``XXXXX`` is a running number and ``suffix`` the channel
  number.  For some hardware types the ``suffix`` includes the TTL line as
  well. It is important to note that the number of digits in ``XXXXX`` is
  variable und subject to change, and that ``XXXXX`` is *not* the sweep number.
- In NWB v1, the sweep number is accessible from the source attribute only.
  Example source contents:
  ``Device=ITC18USB_Dev_0;Sweep=0;AD=0;ElectrodeNumber=0;ElectrodeName=0``
- For I=0 clamp mode neither the DA data nor the stimset is saved.
- Some entries in the following tree are specific to MIES, these are marked as
  custom entries. Users running MIES are encouraged to use the same NWB layout
  and extensions.

NWB File Organization
~~~~~~~~~~~~~~~~~~~~~

The current major version of the file format is 2. Version 1 is considered
supported but deprecated.

.. toctree::

   doc/nwb1.rst
   doc/nwb2.rst


Online Resources
~~~~~~~~~~~~~~~~

-  https://neurodatawithoutborders.github.io
-  https://crcns.org/NWB
