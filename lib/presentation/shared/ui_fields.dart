import 'package:flutter/material.dart';

/// Labels may change independently of backend identifiers.
class UiOption {
  const UiOption(this.value, this.label);
  final String value, label;
}

enum UiFieldKind { text, number, password, select, toggle }

class UiFieldSpec {
  const UiFieldSpec(
    this.name,
    this.label, {
    this.kind = UiFieldKind.text,
    this.readOnly = false,
    this.hint,
  });
  final String name, label;
  final UiFieldKind kind;
  final bool readOnly;
  final String? hint;
}

/// Controlled fields. Supply values/options/errors and forward changes to your
/// presenter or state management layer. Validation and generated IDs belong there.
/// Text entry without callbacks is allowed for layout preview; it is never saved.
class UiFields extends StatelessWidget {
  const UiFields({
    super.key,
    required this.fields,
    this.values = const {},
    this.options = const {},
    this.errors = const {},
    this.onChanged,
  });
  final List<UiFieldSpec> fields;
  final Map<String, Object?> values;
  final Map<String, List<UiOption>> options;
  final Map<String, String> errors;
  final void Function(String, Object?)? onChanged;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final field in fields)
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: switch (field.kind) {
            UiFieldKind.toggle => Row(
              children: [
                Expanded(child: Text(field.label)),
                Switch(
                  value: values[field.name] == true,
                  onChanged: onChanged == null || field.readOnly
                      ? null
                      : (v) => onChanged!(field.name, v),
                ),
              ],
            ),
            UiFieldKind.select => DropdownButtonFormField<String>(
              key: ValueKey('${field.name}:${values[field.name]}'),
              initialValue: values[field.name] as String?,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: field.label,
                hintText: field.hint,
                errorText: errors[field.name],
              ),
              items: [
                for (final option in options[field.name] ?? const <UiOption>[])
                  DropdownMenuItem(
                    value: option.value,
                    child: Text(option.label, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: field.readOnly || onChanged == null
                  ? null
                  : (v) => onChanged!(field.name, v),
            ),
            _ => _BoundTextField(
              key: ValueKey(field.name),
              field: field,
              value: values[field.name]?.toString(),
              error: errors[field.name],
              onChanged: onChanged == null
                  ? null
                  : (v) => onChanged!(field.name, v),
            ),
          },
        ),
    ],
  );
}

// Controller lifecycle is view state, not business state. Synchronizing external
// values here keeps focus/cursor stable when a presenter rebuilds after typing.
class _BoundTextField extends StatefulWidget {
  const _BoundTextField({
    super.key,
    required this.field,
    this.value,
    this.error,
    this.onChanged,
  });
  final UiFieldSpec field;
  final String? value, error;
  final ValueChanged<String>? onChanged;
  @override
  State<_BoundTextField> createState() => _BoundTextFieldState();
}

class _BoundTextFieldState extends State<_BoundTextField> {
  late final controller = TextEditingController(text: widget.value);
  @override
  void didUpdateWidget(covariant _BoundTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value &&
        controller.text != (widget.value ?? '')) {
      final text = widget.value ?? '';
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    readOnly: widget.field.readOnly,
    obscureText: widget.field.kind == UiFieldKind.password,
    keyboardType: widget.field.kind == UiFieldKind.number
        ? TextInputType.number
        : TextInputType.text,
    decoration: InputDecoration(
      labelText: widget.field.label,
      hintText: widget.field.hint,
      errorText: widget.error,
    ),
    onChanged: widget.onChanged,
  );
}
