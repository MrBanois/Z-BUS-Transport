from pydantic import BaseModel

class Userdata(BaseModel):
    id: str
    f_name: str
    l_name: str
    email: str
    passwd: str
    pos: str
    dep: str
    isemp: bool
    salary: float

class Department(BaseModel):
    id: str
    name: str
    # ISEMP in the database: True when the department belongs to staff.
    # False marks a passenger facing department, which is the only kind public
    # registration is allowed to select.
    isemp: bool

class Position(BaseModel):
    id: str
    name: str
    permission: str
    # ISEMP in the database, same meaning as Department.isemp.
    isemp: bool

class Profile(BaseModel):
    """The signed-in member's own record, for the My account screen.

    Deliberately narrower than Userdata: there is no `passwd`. The management
    list endpoints still return the hash, but the self-service screen must not
    hand a signed-in user their own stored credential digest.
    """
    id: str
    f_name: str
    l_name: str
    email: str
    # IDs, which the dropdowns submit, plus the names, which the screen displays.
    dep: str
    dep_name: str
    pos: str
    pos_name: str
    isemp: bool

class ProfileUpdate(BaseModel):
    """Body of PUT /api/user/profile/{id}.

    `dep` and `pos` are optional and default to None, meaning "leave as stored".
    A member who cannot see those dropdowns must be able to rename themselves
    without having to resend their assignment.
    """
    f_name: str
    l_name: str
    dep: str | None = None
    pos: str | None = None
