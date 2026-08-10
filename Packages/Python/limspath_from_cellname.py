import pg8000
from pg8000.native import identifier, literal


def limspath_from_cellname(cellname):

    with pg8000.connect(
        user="limsreader",
        host="limsdb2",
        database="lims2",
        password="limsro",
        port=5432,
    ) as conn:
        with conn.cursor() as cur:
            cur.execute(
                f"""SELECT err.storage_directory AS path
            FROM specimens cell
            JOIN ephys_roi_results err ON err.id = cell.ephys_roi_result_id
            WHERE cell.name LIKE {literal(cellname)}"""
            )

            result = cur.fetchone()

            if result != None:
                return result[0]

    return None


if __name__ == "__main__":
    cellname = "Pvalb-IRES-Cre;Ai14-791953.03.03.01"  # Replace with the actual cell name you want to search for

    path = limspath_from_cellname(cellname)
    if path != None:
        print(path)
    else:
        print("No path found for cell {}".format(cellname))
