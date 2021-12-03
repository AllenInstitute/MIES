Automatic test pulse tuning
===========================

Automatic test pulse (TP) tuning. TP tuning, when activated, automatically
adjusts the frequency (~ % baseline) and the amplitude of the TP. TP tuning
works in C-clamp, not V-clamp. TP tuning does not work during data acquisition,
including TP during ITI.

TP tuning will standardize the TP voltage response across experiments and
ensure that the cell membrane potential returns to rest before the next TP.

TP tuning is intended for use after switching to current-clamp and before
activating auto-bias (the latter is not critical). It can be applied before
and/or after bridge balance and capacitance compensation.

By tuning the TP, errors in auto-bias observed in neurons with long membrane
time constants should now be mitigated.

The TP tuning parameters are settable from the TP control on the main tab and
the settings tab of the DA_ephys panel.

The TP tuning parameters are:

- Vm = the target TP voltage (main tab)
- Vm +/- = the allowable error in TP voltage (main tab)
- max i inj = the max current that may be used to achieve the target Vm (main tab)
- TP amp % = how big a step in current amplitude is taken relative to the
  calculated amplitude (settings tab)
- Auto TP interval = how often the auto TP attempts to adjust the TP (settings tab)

Set the starting values of the controls via the experiment configuration (JSON).

To activate TP tuning, check the TP tuning checkbox. When TP tuning is active,
the checkbox background turns green. When TP tuning is complete, the checkbox
automatically unchecks, and the background of the checkbox returns to the
default coloring. The background color change is intended to inform users when
TP tuning is running headstages other than the (slider) selected headstage.
When only 1 headstage is in use, the background color and unchecking change
will always coincide.

TP tuning can fail if the signal-to-noise ratio (SNR) is poor. SNR depends on
the rig noise and cell noise as well as the target TP voltage. 60Hz noise, for
example, can slow or make TP tuning fail. So might a target TP amplitude of 1
mV. If tuning fails, try a bigger TP target voltage (or fix the noise).

Demonstration:

.. raw:: html

  <video controls width="75%" src="_static/videos/auto_testpulse.mp4"></video>
