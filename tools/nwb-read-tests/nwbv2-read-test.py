#!/usr/bin/python

from pynwb import NWBHDF5IO
import h5py
import sys
import os
from subprocess import run, PIPE, STDOUT
from argparse import ArgumentParser

vers = sys.version_info
if vers < (3, 7):
    print("Unsupported python version: {}".format(vers), file=sys.stderr)
    sys.exit(1)

def to_str(s):
    if isinstance(s, bytes):
        return s.decode('utf-8')
    else:
        return s

def checkFile(path):

    if not os.path.isfile(path):
        print(f"The file {path} does not exist.", file=sys.stderr)
        return 1

    # 1.) Validation
    comp = run(["python", "-m", "pynwb.validate", "--cached-namespace", path],
               stdout=PIPE, stderr=STDOUT, universal_newlines=True, timeout=20)

    if comp.returncode != 0:
        print(f"Validation output: {comp.stdout}", file=sys.stderr)
        return 1

    print(f"Validation output: {comp.stdout}", file=sys.stdout)

    # 2.) Read test
    with NWBHDF5IO(path, mode='r', load_namespaces=True) as io:
        nwbfile = io.read()

        print(f"nwbfile: {nwbfile}")
        print(f"ic_electrodes: {nwbfile.ic_electrodes}")
        print(f"sweep_table: {nwbfile.sweep_table}")
        print(f"lab_meta_data: {nwbfile.lab_meta_data}")
        print(f"acquisition: {nwbfile.acquisition}")
        print(f"stimulus: {nwbfile.stimulus}")
        print(f"epochs: {nwbfile.epochs}")

        object_ids = nwbfile.objects.keys()
        print(f"object_ids: {object_ids}")

        if nwbfile.epochs and len(nwbfile.epochs) > 0:
            print(f"epochs.start_time: {nwbfile.epochs[:, 'start_time']}")
            print(f"epochs.stop_time: {nwbfile.epochs[:, 'stop_time']}")
            print(f"epochs.tags: {nwbfile.epochs[:, 'tags']}")
            print(f"epochs.treelevel: {nwbfile.epochs[:, 'treelevel']}")
            print(f"epochs.timeseries: {nwbfile.epochs[:, 'timeseries']}")

    # check that pynwb/hdmf can read our object IDs
    with h5py.File(path, 'r') as f:
        root_object_id_hdf5 = to_str(f["/"].attrs["object_id"])

    if root_object_id_hdf5 not in object_ids:
        print(f"object IDs don't match as {root_object_id_hdf5} could not be found.", file=sys.stderr)
        return 1

    return 0


def main():

    parser = ArgumentParser(description="Validate and read an NWB file")
    parser.add_argument("paths", type=str, nargs='+', help="NWB file paths")
    args = parser.parse_args()
    ret = 0

    for path in args.paths:
        ret = ret or checkFile(path)


    if ret == 0:
        print("Success!")

    return ret


if __name__ == '__main__':

    try:
        sys.exit(main())
    except Exception as e:
        print(e, file=sys.stderr)
        sys.exit(1)
