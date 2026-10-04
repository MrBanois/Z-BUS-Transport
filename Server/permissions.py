# =============================================================================
# POSITION.PERMISSION bit order
# =============================================================================
# POSITION.PERMISSION stores authorisation as a 16 character '0'/'1' string. Bit
# 0 is the LEFT-most character and maps to the screens below in this exact order.
#
# The order is canonical. It is mirrored by the Flutter client at
# lib/presentation/shared/permissions.dart and documented in
# SQL-Docs/SQL-Create-FULL-V2.txt. Changing the order here means changing it in
# both of those places, otherwise every stored mask silently unlocks the wrong
# screens.
#
# These helpers are pure and perform no I/O, so they are safe to unit test.

from typing import Iterable, Set

# =============================================================================
# Canonical bit order
# =============================================================================

PERMISSION_ORDER = (
    "Manage departments",   # bit 0
    "Manage positions",     # bit 1
    "Manage users",         # bit 2
    "Manage employees",     # bit 3
    "Manage routes",        # bit 4
    "Manage stations",      # bit 5
    "Manage schedules",     # bit 6
    "Manage vehicles",      # bit 7
    "Statistic reports",    # bit 8
    "Find a trip",          # bit 9
    "Reserve seats",        # bit 10
    "My reservations",      # bit 11
    "My driving schedule",  # bit 12
    "Active trip",          # bit 13
    "Scan passenger QR",    # bit 14
    "Completed trip",       # bit 15
)

PERMISSION_LENGTH = len(PERMISSION_ORDER)


# =============================================================================
# Mask helpers
# =============================================================================

def is_valid_mask(mask: str) -> bool:
    """
    Report whether a value is a well formed permission mask.

    A well formed mask is exactly PERMISSION_LENGTH characters and every
    character is '0' or '1'. The column is wider than the mask on purpose, so a
    shorter or longer value is malformed rather than merely padded.
    """
    if not isinstance(mask, str) or len(mask) != PERMISSION_LENGTH:
        return False
    return all(char in "01" for char in mask)


def normalize_mask(mask: str) -> str:
    """
    Coerce any value into a usable PERMISSION_LENGTH mask.

    Missing or unparseable bits become '0' rather than raising, so a legacy row
    with a short or corrupted mask still renders a complete permission matrix
    with the unknown bits reported as denied. Denying is the safe default: it
    never hands out access that was not stored.
    """
    raw = mask if isinstance(mask, str) else ""
    chars = list(raw[:PERMISSION_LENGTH].ljust(PERMISSION_LENGTH, "0"))
    return "".join(char if char in "01" else "0" for char in chars)


def mask_to_set(mask: str) -> Set[str]:
    """
    Decode a stored mask into the set of screen names it unlocks.

    Returns a subset of PERMISSION_ORDER. Never raises, so a corrupted row
    degrades to "fewer permissions" instead of a failed request.
    """
    return {
        PERMISSION_ORDER[index]
        for index, char in enumerate(normalize_mask(mask))
        if char == "1"
    }


def set_to_mask(screens: Iterable[str]) -> str:
    """
    Encode screen names into a PERMISSION_LENGTH mask.

    Names outside PERMISSION_ORDER are ignored, and the result is always exactly
    PERMISSION_LENGTH characters so it can be stored as-is.
    """
    wanted = set(screens)
    return "".join(
        "1" if name in wanted else "0" for name in PERMISSION_ORDER
    )
