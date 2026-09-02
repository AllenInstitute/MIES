import argparse
import sys

import pg8000
from pg8000.native import literal


# Return a list of network share paths which hold data for the given cell names
def limspath_from_cellname(
    user: str, password: str, host: str, database: str, cellnames: list
):

    if len(cellnames) == 1 and cellnames[0] == "fake":
        return [
            "/allen/programs/celltypes/production/mousecelltypes/prod174/Ephys_Roi_Result_1429085938/"
        ]

    with (
        pg8000.connect(
            user=user,
            password=password,
            host=host,
            database=database,
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

            if result is not None:
                paths.append(result[0])

    return paths


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--db_user", help="Name of the database user", type=str, required=True
    )
    parser.add_argument(
        "--db_password", help="Password for the database user", type=str, required=True
    )
    parser.add_argument(
        "--db_host", help="Host of the database server", type=str, required=True
    )
    parser.add_argument(
        "--db_name", help="Name of the database", type=str, required=True
    )
    parser.add_argument("cellnames", nargs="+", help="Cell names")
    args = parser.parse_args()

    paths = limspath_from_cellname(
        args.db_user, args.db_password, args.db_host, args.db_name, args.cellnames
    )

    for p in paths:
        if p is None:
            print("One of the returned paths is None")
            sys.exit(1)

    print(paths)

    # @todo Can't return zero here due to WM bug #8570
    # sys.exit(0)
