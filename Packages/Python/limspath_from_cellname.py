import sys

import pg8000
from pg8000.native import literal


def limspath_from_cellname(cellnames: list):

    with (
        pg8000.connect(
            user="limsreader",
            host="limsdb2",
            database="lims2",
            password="limsro",
            port=5432,
        ) as conn,
        conn.cursor() as cur,
    ):
        paths = []

        for cell in cellnames:
            cur.execute(
                f"""SELECT err.storage_directory AS path
                FROM specimens cell
                JOIN ephys_roi_results err ON err.id = cell.ephys_roi_result_id
                WHERE cell.name LIKE {literal(cell)}"""
            )

            result = cur.fetchone()

            if result != None:
                paths.append(result[0])

    return paths


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Expected at least one argument: cellnameA cellNameB ...")
        sys.exit(1)

    cellnames = []
    paths = []

    # cellnames.append("Pvalb-IRES-Cre;Ai14-791953.03.03.01")
    cellnames = sys.argv[1:]

    if len(cellnames) == 1 and cellnames[0] == "fake":
        paths.append(
            "/allen/programs/celltypes/production/mousecelltypes/prod174/Ephys_Roi_Result_1429085938/"
        )
    else:
        paths = limspath_from_cellname(cellnames)

    for p in paths:
        if p is None:
            print("One of the returned paths is None")
            sys.exit(1)

    print(paths)
    # @todo Not return zero here due to WM bug #8570
    # sys.exit(0)
