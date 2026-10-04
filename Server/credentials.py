# =============================================================================
# Stored credentials
# =============================================================================
# Both routers that create accounts need to agree on how a password is turned
# into a stored value and on how long one has to be. Auth.py handles
# self-registration; CRUD/User.py handles accounts an administrator creates or
# resets. Keeping those rules in two places already let them drift, so they live
# here instead.

import hashlib

from columns import MIN_PASSWORD_LENGTH


# =============================================================================
# Hashing
# =============================================================================

def hash_password(user_id: str, password: str) -> str:
    """Return the stored form of a password: MD5(ID + password).

    The ID is part of the input, which is why a password hash cannot be moved
    between accounts and why resetting one account's password requires rewriting
    it rather than copying a value across.
    """
    return hashlib.md5(f"{user_id}{password}".encode()).hexdigest()


def verify_password(user_id: str, password: str, stored_hash: str) -> bool:
    """Check a login attempt against the stored hash."""
    return hashlib.md5(
        f"{user_id}{password}".encode()
    ).hexdigest() == stored_hash


# =============================================================================
# Choosing a password
# =============================================================================
# There is deliberately no server-invented starting password. One used to exist:
# a new account was given `f"{user_id}@zbus"`, which anyone who could list
# accounts could derive for any other account from the public, sequential
# USER.ID. A creator now supplies the password, so the credential is chosen by
# the person handing it over rather than guessed by everyone else.


def validate_password(password: str) -> str | None:
    """Return an error message for an unacceptable password, or None if it is fine.

    Only length is checked. There is no complexity rule: composition rules push
    people toward predictable substitutions, and the stored form is a plain MD5
    digest either way.
    """
    if len(password) < MIN_PASSWORD_LENGTH:
        return f"Password must be at least {MIN_PASSWORD_LENGTH} characters"
    return None
