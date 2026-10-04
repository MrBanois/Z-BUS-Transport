/// A department or position row, as offered by the reference dropdown format.
///
/// Lives outside `auth_repository.dart` because two repositories produce these:
/// the passenger-facing lists on the registration screen and the assignment
/// lists on the account screen. Sharing the type keeps the `UiOption` mapping in
/// the presentation layer written once.
class ChoiceOption {
  const ChoiceOption({required this.id, required this.name});

  final String id;
  final String name;

  /// `D0011 / Passenger`.
  String get label => '$id / $name';

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) =>
      other is ChoiceOption && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
