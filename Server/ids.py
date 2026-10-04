# =============================================================================
# USER ID generation
# =============================================================================
# USER.ID is CHAR(10): the letter 'U' followed by 9 zero padded digits, which
# makes the ID the same length as the MD5 hash input in hash_password and keeps
# MAX(ID) ordering equal to numeric ordering.
#
# The table name is a module constant rather than an argument so no caller can
# interpolate arbitrary SQL into the lookup.

from oracledb import Connection

_USER_TABLE = '"USER"'
_USER_PREFIX = "U"
_USER_DIGITS = 9


def generate_user_id(connection: Connection) -> str:
    """
    Return the next unused USER.ID in the form U000000001.

    MAX over a fixed width zero padded ID sorts numerically, so the next value
    is always MAX + 1. Deleting the highest row therefore reuses its ID, which
    is safe because the password hash is derived from the ID and is rewritten
    on insert.

    Note: this is a read-then-insert sequence with no lock, so two registrations
    committed at the same instant could compute the same ID. One of them fails
    on the primary key rather than corrupting data. A sequence or a serial would
    remove the race entirely if concurrent sign-up ever matters.
    """
    with connection.cursor() as cur:
        result = cur.execute(
            f"SELECT MAX(ID) FROM {_USER_TABLE}"
        ).fetchone()
        max_id = result[0] if result else None

    # Table is empty, or holds no rows in the expected format.
    if max_id is None or not str(max_id).startswith(_USER_PREFIX):
        return f"{_USER_PREFIX}{1:0{_USER_DIGITS}d}"

    try:
        next_num = int(str(max_id).strip()[1:]) + 1
    except ValueError:
        # A malformed ID would otherwise crash registration outright.
        next_num = 1

    # Refuse to overflow the fixed width column, e.g. past U999999999.
    if next_num >= 10 ** _USER_DIGITS:
        raise ValueError("USER.ID space is exhausted")

    return f"{_USER_PREFIX}{next_num:0{_USER_DIGITS}d}"
