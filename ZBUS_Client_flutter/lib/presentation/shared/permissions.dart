/// Canonical decoding for the 16-bit permission mask.
///
/// `POSITION.PERMISSION` stores authorisation as a 16 character `'0'`/`'1'`
/// string. Bit 0 is the left-most character and maps to [kPermissionOrder] in
/// that exact order.
///
/// The order is canonical and shared with the backend: it is mirrored by
/// `Production/Server/permissions.py` and documented in
/// `Production/SQL-Docs/SQL-Create-FULL-V2.txt`. Change it in all three places
/// together, or every stored mask silently unlocks the wrong screens.
///
/// These helpers are pure and perform no I/O, so they are safe to unit test and
/// safe to call from a presenter while assembling form state.
library;

/// Screen names in bit order. Index in this list is the bit index.
const List<String> kPermissionOrder = <String>[
  'Manage departments', // bit 0
  'Manage positions', // bit 1
  'Manage users', // bit 2
  'Manage employees', // bit 3
  'Manage routes', // bit 4
  'Manage stations', // bit 5
  'Manage schedules', // bit 6
  'Manage vehicles', // bit 7
  'Statistic reports', // bit 8
  'Find a trip', // bit 9
  'Reserve seats', // bit 10
  'My reservations', // bit 11
  'My driving schedule', // bit 12
  'Active trip', // bit 13
  'Scan passenger QR', // bit 14
  'Completed trip', // bit 15
];

/// Length of a well formed mask. Matches `Server/permissions.PERMISSION_LENGTH`.
const int kPermissionLength = 16;

/// The all-deny mask. Use as the default for a position that grants nothing.
const String kEmptyPermissionMask = '0000000000000000';

/// Whether [mask] is exactly [kPermissionLength] characters of `'0'` and `'1'`.
///
/// The database column is wider than the mask on purpose, so a value of the
/// wrong length is malformed rather than merely padded.
bool isValidPermissionMask(String? mask) {
  if (mask == null || mask.length != kPermissionLength) return false;
  for (final code in mask.codeUnits) {
    if (code != 0x30 && code != 0x31) return false; // '0' / '1'
  }
  return true;
}

/// Coerce any value into a usable [kPermissionLength] mask.
///
/// Anything that is not already a well formed mask becomes all-deny:
/// `POSITION.PERMISSION` is wider than 16 characters so a short or over-long
/// value is malformed, not padded, and an unparseable bit is denied.
///
/// This is deliberately stricter than it needs to be for display. Padding a
/// short mask would invent grants for the bits it does not mention, and
/// truncating a long one would grant whatever its first 16 characters said.
/// Neither is a value this server would ever write, so neither should ever
/// produce access: malformed input denies everything.
String normalizePermissionMask(String? mask) {
  if (!isValidPermissionMask(mask)) return kEmptyPermissionMask;
  final raw = mask!;
  final buffer = StringBuffer();
  for (var i = 0; i < kPermissionLength; i++) {
    buffer.write(raw[i] == '1' ? '1' : '0');
  }
  return buffer.toString();
}

/// Decode a stored mask into the set of screen names it unlocks.
///
/// The result is always a subset of [kPermissionOrder]. Never throws.
Set<String> permissionMaskToSet(String? mask) {
  final normalized = normalizePermissionMask(mask);
  final granted = <String>{};
  for (var i = 0; i < kPermissionLength; i++) {
    if (normalized[i] == '1') granted.add(kPermissionOrder[i]);
  }
  return granted;
}

/// Encode screen names into a [kPermissionLength] mask.
///
/// Names outside [kPermissionOrder] are ignored, and the result is always
/// exactly [kPermissionLength] characters so it can be stored as-is.
String permissionSetToMask(Set<String> screens) {
  final buffer = StringBuffer();
  for (final name in kPermissionOrder) {
    buffer.write(screens.contains(name) ? '1' : '0');
  }
  return buffer.toString();
}

/// Decode a mask into a map keyed by screen name, for widgets that render one
/// row per screen.
///
/// Every screen in [kPermissionOrder] is present, so the caller can rely on
/// [kPermissionOrder] length without counting the map.
Map<String, bool> permissionMaskToMap(String? mask) {
  final normalized = normalizePermissionMask(mask);
  return <String, bool>{
    for (var i = 0; i < kPermissionLength; i++)
      kPermissionOrder[i]: normalized[i] == '1',
  };
}

/// Whether [screen] is granted by [mask].
///
/// [screen] must be in [kPermissionOrder]; an unknown name is denied rather
/// than throwing, so a stale screen reference cannot fail open.
bool permissionGranted(String? mask, String screen) {
  final index = kPermissionOrder.indexOf(screen);
  if (index < 0) return false;
  return normalizePermissionMask(mask)[index] == '1';
}

/// The canonical label for a single bit, for display as `07 / Manage users`.
String permissionBitLabel(int bit) {
  if (bit < 0 || bit >= kPermissionLength) return '-- / --';
  final n = (bit + 1).toString().padLeft(2, '0');
  return '$n / ${kPermissionOrder[bit]}';
}
