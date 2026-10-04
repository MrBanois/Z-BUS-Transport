# =============================================================================
# Error responses that name a field
# =============================================================================
# The Flutter client keys its form fields by name and can put a rejection beside
# the control that caused it. It decides that by reading `detail.field`, which is
# only present when the route builds its HTTPException through this helper. Every
# other route raises a plain string, and the client shows those as a banner above
# the form. See lib/data/api_client.dart, ApiException.field.

from fastapi import HTTPException


def field_error(status_code: int, message: str, field: str) -> HTTPException:
    """An error the client should render under `field` rather than as a banner.

    `detail` carries both keys. `message` is what a caller that only displays the
    detail shows, so this shape is a superset of the plain-string one rather than
    a different contract.

    Field names are the controller's keys: firstName, lastName, email,
    department, position, name, password, salary.
    """
    return HTTPException(
        status_code=status_code,
        detail={"message": message, "field": field},
    )
