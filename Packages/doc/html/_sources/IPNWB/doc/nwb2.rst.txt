NWB version 2
"""""""""""""

Recent NWB (version 2) schema specifications are `tracked in a separate
repository <https://github.com/NeurodataWithoutBorders/nwb-schema>`_.  The
schema is implemented in version 2.2.0
(62c73400565afc28f67ede4f2e86023c33167cf8).

The complete schema tree is described in a hdmf compatible format and
replicated in this repository under `namespace/{schema}/{yaml,json}/*`. The
JSON files are stored in the nwb file upon storage. A build script exists to
generate the JSON files from their YAML files: `update_specifications.sh`.

The following deviations from `NWB schema 2.2.0
<https://github.com/NeurodataWithoutBorders/nwb-schema/tree/2.2.0/core>`_ were
recorded:

.. literalinclude:: schema.diff
   :language: diff

The most important core properties are for intracellular ephys.

.. literalinclude:: ../namespace/core/yaml/nwb.icephys.yaml
   :language: yaml

The includes a Dynamic Table at `/general/intracellular_ephys/sweep_table` to
store the sweep numbers of a list of data sets.  The table is column centric
and consists of the two columns `sweep_number` and `series`. Series contains
links to datasets. The `sweep_number` for a dataset is stored under the same
row index, specified either by the Dataset `id` (zero-based indices) or by
`series_index` (one-based indices). The sweep_table is intended to easily find
datasets that belong to a given sweep number.  A sweep table is loaded by
`LoadSweepTable` and created using `AppendToSweepTable`

.. image:: sweep_table.png

   The structure of the sweep table dataset.
