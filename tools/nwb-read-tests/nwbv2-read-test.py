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

        print(nwbfile)
        print(nwbfile.ic_electrodes)
        print(nwbfile.sweep_table)
        print(nwbfile.lab_meta_data)
        print(nwbfile.devices)
        print(nwbfile.acquisition)
        print(nwbfile.stimulus)
        print(nwbfile.epochs)

        object_ids = nwbfile.objects.keys()
        print(object_ids)

        if nwbfile.epochs and len(nwbfile.epochs) > 0:
            print(nwbfile.epochs[:, 'start_time'])
            print(nwbfile.epochs[:, 'stop_time'])
            print(nwbfile.epochs[:, 'tags'])
            print(nwbfile.epochs[:, 'treelevel'])
            print(nwbfile.epochs[:, 'timeseries'])

    # check that pynwb/hdmf can read our object IDs
    with h5py.File(path, 'r') as f:
        root_object_id_hdf5 = f["/"].attrs["object_id"]

    if root_object_id_hdf5 not in object_ids:
        print(f"object IDs don't match", file=sys.stderr)
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
