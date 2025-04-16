
.. _analysisbrowser:

AnalysisBrowser
===============

The AnalysisBrowser allows browsing and loading acquired data from Igor Experiment files
(pxp and uxp) and NeuroDataWithoutBorders files (NWB, v1 and v2) into one Igor
Experiment. The user can also combine sweeps from multiple experiments in one
SweepBrowser, see :ref:`DataBrowser`, inspect the labnotebook entries of these
sweeps and view the :ref:`TPStorage` data.

.. _Figure Analysis Browser panel:

.. figure:: ScreenShots/AnalysisBrowser.png
   :align: center

   AnalysisBrowser panel

User Interface
--------------

The upper listbox shows folders and files where the analysis browser looks for data files.
Folders are searched recursively including all subfolders.

* Button "Add folder": Opens a file dialog where a folder can be selected that is added to the list
* Button "Add file(s)": Opens a file dialog where file(s) can be selected that are added to the list
* Button "Remove": Removes the selected elements from the list
* Button "Refresh": Indexes the listed folder(s) and file(s) again
* Button "Open": Shows the last selected list element in the Windows Explorer
* Checkbox "NWB": When selected the file search looks for .nwb files
* Checkbox "PXP": When selected the file search looks for .pxp and .uxp files
* Checkbox "Load results": When selected the result waves of the data files get also loaded
* Checkbox "Load comments": When selected the comments of the data files get also loaded

Only PXP or NWB can be selected. When the selected file type is changed the list is automatically refreshed.

The lower listbox shows by default a collapsed tree view with meta information of the data files.
By clicking the "+" the tree view can be expanded. The leftmost "+" expands the tree view for a whole experiment file.
The "+" in front of the device name expands a single device.
The meta-information includes file name, file type, device name, number of sweeps per device, sweep number,
headstage, stimset name, set count, number of DAC channels, number of ADC channels.

* Button "Select same stim sets sweeps": Selects all sweeps with the same stim set from all files.
* Button "Collapse all": Collapses all tree branches
* Button "Expand all": Expands all tree branches
* Button "Open comment": Shows the user comment of a sweep in a notebook. This requires that only a single row is selected.
* Button "Resave as NWBv2": For all NWBv1 files in the list, resaves as NWBv2. This is independent of any selection.
* Checkbox "Overwrite": When selected existing files get overwritten.
* Popupmenu "New": Here a target SweepBrowser can be selected. Sweeps are loaded to that SweepBrowser. Select "New" to load to a new SweepBrowser.
* Button "Load Sweeps": Loads the selected sweeps to the SweepBrowser chosen in the popupmenu. If a file was selected all sweeps of that file are loaded.
* Button "Load Stimsets": Loads the Stimsets of the selected sweeps.  If a file was selected all stimsets of that file are loaded.
* Button "Load both": Loads sweeps and stimsets.
* Button "Load TPStorage": Loads TP storage data.
* Button "Load History": Loads experiment history and shows it in a notebook.

The tree view is collapsed after loading sweeps/stimsets or refreshing the list.

Known Limitations
-----------------

If the experiment file contains acquisitions from multiple devices, e.g. ITC18 and Dev1 then for NWBv1 and NWBv2 files
an under certain circumstances sweeps can not be loaded. The loading attempt results in an Asssertion where multiple waves with the same name are present in the experiment file.
This is related to `issue 978 <https://github.com/AllenInstitute/MIES/issues/978>`__ and
`issue 1710 <https://github.com/AllenInstitute/MIES/issues/1710>`__.
This limitation does not apply when loading sweeps from Igor Pro experiment files (pxp).
