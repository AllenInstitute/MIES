import igorpro

# File needs to be copied into "Python Scripts", reported as #7232

import ipfx

from ipfx.feature_extractor import SpikeFeatureExtractor


def extract_spikes(t_path: str, v_path: str, out_folder: str):

    t_ip = igorpro.wave(t_path)
    v_ip = igorpro.wave(v_path)

    t = t_ip.asarray()
    v = v_ip.asarray()

    folder = igorpro.folder(out_folder)

    ext = SpikeFeatureExtractor()
    spikes = ext.process(t, v, None)

    # empty list are not handled correctly, reported as #7234
    if spikes.empty:
        return ""

    # creating a 2D text wave throws, reported as #7225
    resultName = "spikes_output"
    spikes_text = igorpro.wave.create(
        resultName, 0, "", igorpro.WaveType.text, folder, True
    )

    # written with wrong shape, already reported to WaveMetrics as #7227, use transpose as workaround
    spikes_text.set_data(spikes.to_numpy().transpose().tolist())

    # spikes.columns.array hangs in IP, reported as #7230
    col_labels = spikes.columns.tolist()
    for i in range(len(col_labels)):
        spikes_text.set_label("y", i, col_labels[i])

    return resultName
