from pydantic import BaseModel


class Userdata(BaseModel):
    """A row of USER as the management screens see it.

    There is no `passwd`. The listing endpoints used to return the MD5 digest to
    any caller, which handed every account's stored credential to the browser and
    to anything in front of it. No screen needs it: an administrator cannot read
    a password, and cannot reverse a hash to recover one either, so the only
    thing it enabled was offline cracking of the whole table at once.
    """
    id: str
    f_name: str
    l_name: str
    email: str
    # Ids, which the dropdowns submit. The `-linked` variant fills the `_name`
    # fields below; the plain one leaves them null and the client resolves them
    # from the department and position lists it already holds.
    pos: str
    dep: str
    isemp: bool
    salary: float
    pos_name: str | None = None
    dep_name: str | None = None


class UserCreate(BaseModel):
    """Body of POST /api/user.

    `password` is required here, unlike on [UserUpdate]. Creating an account is a
    deliberate act by someone who is handing over a credential, so the credential
    is part of the request rather than something the server invents: a predictable
    starting password is guessable from the public, sequential USER.ID, which made
    every account created that way readable by anyone who could list accounts.

    Its length is checked in the route, not here, so the rejection arrives as a
    named-field error the management screen can render under the password box.
    """
    f_name: str
    l_name: str
    email: str
    dep: str
    pos: str
    isemp: bool
    sal: float = 0.0
    password: str


class UserUpdate(BaseModel):
    """Body of PUT /api/user/{id}.

    `password` is optional and defaults to None, meaning "leave the stored hash
    alone". That is the whole point of this body: the previous signature took a
    password parameter, which forced every caller to either know the account's
    current password or destroy it, since the digest is MD5(ID + password) and
    cannot be reconstructed from the stored value.

    Supplying a password resets it. Supplying None, which is what an edit of a
    name or a department sends, changes nothing about the credential.
    """
    f_name: str
    l_name: str
    email: str
    dep: str
    pos: str
    isemp: bool
    sal: float = 0.0
    password: str | None = None


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

    Deliberately narrower than Userdata in one respect that matters: this route
    is reachable by anyone who knows an id, so it is the one place worth being
    explicit that no credential material crosses it. Neither shape carries
    `passwd`.
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
