from pydantic import BaseModel

# =============================================================================
# Request bodies
# =============================================================================
# These arrive as a JSON body rather than query parameters. Login previously
# took ?user=&passwd=, which puts the password in the URL where it lands in
# browser history, proxy logs and server access logs.

class Credentials(BaseModel):
    """Body of POST /api/login."""
    email: str
    password: str

class RegisterRequest(BaseModel):
    """
    Body of POST /api/register.

    Field names follow the existing /api/user POST convention (f_name, l_name,
    dep, pos) rather than the Flutter form keys, so the client presenter does
    the mapping in one place.

    dep and pos must reference DEPARTMENT and POSITION rows whose ISEMP is 'F'.
    The new account is always created with ISEMP = 'F'; employees are provisioned
    through /api/user, not through public sign-up.
    """
    f_name: str
    l_name: str
    email: str
    password: str
    dep: str
    pos: str

# =============================================================================
# Response bodies
# =============================================================================

class LoginUser(BaseModel):
    id: str
    name: str
    email: str
    permission: str

class LoginResponse(BaseModel):
    """
    Shape matches the pre-existing /api/login contract exactly, so existing
    clients keep working.

    permission is the raw 16 bit mask. Decode it with the client's
    permissions.dart (or server permissions.py) rather than treating it as a
    list of names.
    """
    message: str
    user: LoginUser
