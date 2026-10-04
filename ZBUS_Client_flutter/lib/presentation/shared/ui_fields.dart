import 'package:flutter/material.dart';

import 'design_system.dart';

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
///
/// Labels are rendered above the control (ZLabel) rather than as Material
/// floating labels, so forms inherit the mono/uppercase rhythm of the design
/// system instead of the stock Material look.
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
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final field in fields)
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: switch (field.kind) {
            UiFieldKind.toggle => Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ZLabel(field.label),
                      if (field.hint != null) ...[
                        const ZGap(6, 8),
                        Text(
                          field.hint!,
                          style: const TextStyle(
                            color: ZColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                ZSwitch(
                  value: values[field.name] == true,
                  onChanged: onChanged == null || field.readOnly
                      ? null
                      : (v) => onChanged!(field.name, v),
                ),
              ],
            ),
            UiFieldKind.select => _UiSelect(
              label: field.label,
              hint: field.hint,
              error: errors[field.name],
              value: values[field.name]?.toString(),
              options: options[field.name] ?? const <UiOption>[],
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

/// Dropdown matching ZSelect: mono label above, flat border, squared corners.
/// The selected value is only forwarded when it exists in the option list, which
/// keeps an out-of-date presenter value from tripping the FormField assertion.
class _UiSelect extends StatelessWidget {
  const _UiSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint,
    this.error,
  });
  final String label;
  final String? value;
  final List<UiOption> options;
  final ValueChanged<String?>? onChanged;
  final String? hint, error;
  @override
  Widget build(BuildContext context) {
    final selected = options.any((o) => o.value == value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZLabel(label),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          key: ValueKey('$label:${selected ?? ''}'),
          initialValue: selected,
          isExpanded: true,
          dropdownColor: ZColors.surface2,
          // Material's default dropdown text is black on this dark surface, and
          // the item widgets sit outside the button's style, so the colour has
          // to be set in both places rather than inherited.
          style: const TextStyle(fontSize: 14, color: ZColors.ink),
          decoration: InputDecoration(hintText: hint, errorText: error),
          items: [
            for (final option in options)
              DropdownMenuItem(
                value: option.value,
                child: Text(
                  option.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: ZColors.ink),
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ZLabel(widget.field.label),
      const SizedBox(height: 9),
      TextFormField(
        controller: controller,
        readOnly: widget.field.readOnly,
        obscureText: widget.field.kind == UiFieldKind.password,
        keyboardType: widget.field.kind == UiFieldKind.number
            ? TextInputType.number
            : TextInputType.text,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.field.hint,
          errorText: widget.error,
        ),
        onChanged: widget.onChanged,
      ),
    ],
  );
}