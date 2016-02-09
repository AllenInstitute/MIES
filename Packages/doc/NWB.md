## NWB file format description

- Datasets which originate from Igor Pro waves have the special attributes
  IGORWaveScaling, IGORWaveType, IGORWaveUnits, IGORWaveNote. These attributes
  allow easy and convenient loading of the data into Igor Pro.
- For AD/DA/TTL groups the naming scheme is data_`XXXXX`_[AD/TTL]`suffix` where
  `XXXXX` is a running number incremented for every sweep $suffix the
  channel number (TTL channels: plus TTL line).

### The following tree decsribes how MIES creates NWB files

~~~
acquisition:
	timeseries:
		data_XXXXX_ADY:
				stimulus_description : custom entry, name of the stimset
				data                 : 1D dataset with attributes unit, conversion and resolution
				electrode_name       : Name of the electrode headstage, more info in /general/intracellular_ephys/electrode_name
				gain                 : scaling factor
				num_samples          : Number of rows in data
				starting_time        : relative to /session_start_time with attributes rate and unit
                For Voltage Clamp (Missing entries are mentioned in missing_fields):
                capacitance_fast
                capacitance_slow
                resistance_comp_bandwidth
                resistance_comp_correction
                resistance_comp_prediction
                whole_cell_capacitance_comp
                whole_cell_series_resistance_comp

                For Current Clamp (Missing entries are mentioned in missing_fields):
                bias_current
                bridge_balance
                capacitance_compensation

                description    : Unused
                source         : Human readable description of the source of the data
                comment        : User comment for the sweep
                missing_fields : Entries missing for voltage clamp/current clamp data
                ancestry       : Class hierarchy defined by NWB spec, important members are
                                 CurrentClampSeries and VoltageClampSeries
                neurodata_type : TimeSeries

stimulus:
    presentation:
        data_XXXXX_DA_Y: DA data as sent to the neuron, including delays, scaling, initial TP, etc.
                data           : 1D dataset
                electrode_name : Name of the electrode headstage, more info in /general/intracellular_ephys/electrode_name
                gain           :
                num_samples    : Number of rows in data
                starting_time  : relative to /session_start_time with attributes rate and unit
                description    : Unused
                source         : Human readable description of the source of the data
                ancestry       : Class hierarchy defined by NWB spec, important members are
                                 CurrentClampStimulusSeries and VoltageClampStimulusSeries
                neurodata_type : TimeSeries
    templates:
            XXXXXX_DA_Y: Name of the stimset, referenced from stimulus_description
                data           : N-dimensional data
                num_samples    : Number of rows in data
                description    : Unused
                source         : Human readable description of the source of the data
                ancestry       : Class hierarchy defined by NWB spec, important members are CurrentClampStimulusSeries
                                 and VoltageClampStimulusSeries
                neurodata_type : TimeSeries

            XXXXXX_DA_Y_SegWvType/WP/WPT: The Wavebuilder parameter waves. These waves will not be available for
                                          "third party stimsets" created outside of MIES
                data           : N-dimensional dataset with attributes unit, conversion and resolution
                electrode_name : Name of the electrode headstage, more info in /general/intracellular_ephys/electrode_name
                gain           :
                num_samples    : Number of rows in data
                starting_time  : relative to /session_start_time with attributes rate and unit
                description    : Unused
                source         : Human readable description of the source of the data
                ancestry       : Class hierarchy defined by NWB spec, important members are
                                 CurrentClampStimulusSeries and VoltageClampStimulusSeries
                neurodata_type : TimeSeries

general:
    devices:
        device_XXX: Name of the DA_ephys device, something like "Harvard Bioscience ITC 18USB"
        intracellular_ephys:
                electrode_XXX: Holds the description of the electrode, something like Headstage 1
                filtering: Unused

    version: mies version string (custom entry)
    labnotebook: custom entry
		XXXX: Name of the device
			numericalKeys   : Numerical labnotebook
			numericalValues : Keys for numerical labnotebook
			textualKeys     : Keys for textual labnotebook
			textualValues   : Textual labnotebook

    testpulse: custom entry
		XXXX: Name of the device
            TPStorage_X: testpulse property waves
    user_comment:
		XXXX: Name of the device
            userComment: All user comments from this session

file_create_date    : text array with UTC modification timestamps as proposed in tentative NWB 1.0.1 spec
identifier          : SHA256 hash, ensured to be unique
neurodata_version   : NWB specification version
session_description : unused
session_start_time  : UTC timestamp defining when the recording session started

The following entries are only available if explicitly set by the user:
    data_collection
    experiment_description
    experimenter
    institution
    lab
    notes
    pharmacology
    protocol
    related_publications
    session_id
    slices
    stimulus:
            age
            description
            genotype
            sex
            species
            subject_id
            weight
    surgery
    virus
~~~

### Online Resources
* https://neurodatawithoutborders.github.io
* https://crcns.org/NWB
* http://nwb.org
