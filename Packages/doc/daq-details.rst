DAQ details
===========

.. _Figure Repeated Acquisition Explained:

.. figure:: acquisition-repeated-indexing-explained.svg
   :align: center

   Data acquisition modes

.. _Figure Normal Delays:

.. figure:: normal-delays.svg
   :align: center

   Normal delays

.. _Figure dDAQ Delays:

.. figure:: ddaq-delay.svg
   :align: center

   Ddaq delay

.. _Figure oodDAQ Delays:

.. figure:: oodDAQ-delays.svg
   :align: center

   oodDAQ delays

.. _Figure Testpulse Visualization:

.. figure:: testPulse-visualization.svg
   :align: center

   Testpulse visualization

Indexing definition
-------------------

In MIES we have different modes in which a given stimset or multiple stimsets
can be repeated.  The following is a human readable, and authorative
description, how these modes work.

Indexing is a mode which allows to acquire a range of stimsets across mutiple
channels and channel types (DA and TTL).

As these stimsets can have a different number of sweeps the natural question
arises when to switch to the next stimset. Locked indexing switches stimsets
when the stimset with the most sweeps (currently acquiring, not globally) on
all active channels is finished. Unlocked indexing switches stimset on each
channel independently. In both modes the currently active stimset is repeated
in one channel if there is some space left.

With repetitions larger than 1 the difference is even more pronounced as locked
indexing first repeats and then indexes and unlocked indexing indexes and then
repeats.

Inner-Set randomization is currently broken with indexing.
Set randomization with indexing is not implemented.
