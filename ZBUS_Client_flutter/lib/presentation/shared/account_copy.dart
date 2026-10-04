/// Copy the two account forms share.
///
/// This lives in presentation rather than beside the controllers because it is
/// wording on a form: the app layer holds the rules, and a widget that imports
/// the app layer to read a sentence would be reaching upwards for no reason.
library;

/// What an empty password box means on an edit.
///
/// An empty box is not an omission to complain about here — it is the instruction
/// "leave the stored hash alone" — so the form has to say so, or a rename looks
/// like it needs the current password, which nobody can read.
const String kPasswordKeptHint =
    'Leave blank to keep the current password, or type a new one to reset it.';

/// What the same box means on a create.
///
/// A new account has no password to keep, so there is nothing for an empty box to
/// mean: it is incomplete, and the form says so rather than leaving the value to
/// the server. Mirrors `credentials.MIN_PASSWORD_LENGTH`.
const String kNewPasswordHint = 'Required. At least 6 characters.';