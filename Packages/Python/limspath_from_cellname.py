import argparse

import pg8000
from pg8000.native import literal


# Return a list of network share paths which hold data for the given cell names
def limspath_from_cellname(
    user: str, password: str, host: str, database: str, cell_specimens: list
):

    if len(cell_specimens) == 1 and cell_specimens[0] == "fake":
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

        for cell in cell_specimens:
            cur.execute(
                f"""SELECT err.storage_directory AS path
                FROM specimens cell
                JOIN ephys_roi_results err ON err.id = cell.ephys_roi_result_id
                WHERE cell.name LIKE {literal(cell)}"""
            )

            result = cur.fetchone()

            if result is None:
                # append an empty string as None can not be converted to an igor type
                paths.append("")
            else:
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
    parser.add_argument("cell_specimens", nargs="+", help="Cell names")
    args = parser.parse_args()

    paths = limspath_from_cellname(
        args.db_user, args.db_password, args.db_host, args.db_name, args.cell_specimens
    )

    # @todo Can't return zero here due to WM bug #8570
    # sys.exit(0)
