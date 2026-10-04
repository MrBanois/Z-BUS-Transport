# =============================================================================
# Request bodies for the reference tables
# =============================================================================
# DEPARTMENT and POSITION are reference data: a short, fixed set of rows that
# every account points at. Their write bodies are here rather than in
# schemas/user.py because neither is a user record; they only share a table with
# one.
#
# These replace query parameters. FastAPI accepted `?name=X&isemp=true` on the
# POST and PUT routes, which put user-supplied values in access logs and browser
# history and made every caller build its own encoding. The body form matches
# /api/login, /api/register and /api/user/profile/{id}.

from pydantic import BaseModel

from columns import MAX_REFERENCE_NAME_LENGTH
from permissions import PERMISSION_LENGTH


class DepartmentCreate(BaseModel):
    name: str
    # Defaults to a staff department. A passenger-facing one must be asked for
    # explicitly, so an administrator cannot accidentally publish a department to
    # the public registration form.
    isemp: bool = True


class DepartmentUpdate(BaseModel):
    name: str
    # No default here: an update replaces the row, and defaulting this to True
    # would silently turn a passenger department into a staff one on every edit
    # that forgot to mention it.
    isemp: bool


class PositionCreate(BaseModel):
    name: str
    # POSITION.PERMISSION: exactly PERMISSION_LENGTH characters of '0'/'1', in
    # the canonical order documented in permissions.py.
    perms: str
    isemp: bool = True


class PositionUpdate(BaseModel):
    name: str
    perms: str
    # No default, for the same reason as DepartmentUpdate.isemp.
    isemp: bool


# Re-exported so a router can validate against the same numbers the columns were
# declared with, without importing two modules for one constant.
__all__ = [
    "DepartmentCreate",
    "DepartmentUpdate",
    "PositionCreate",
    "PositionUpdate",
    "MAX_REFERENCE_NAME_LENGTH",
    "PERMISSION_LENGTH",
]
