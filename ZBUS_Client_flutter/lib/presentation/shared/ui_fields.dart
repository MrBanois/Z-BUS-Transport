import 'package:flutter/material.dart';

import 'design_system.dart';

/// Labels may change independently of backend identifiers.
class UiOption {
  const UiOption(this.value, this.label);
  final String value, label;
}

enum UiFieldKind { text, number, password, select, toggle, date }

/// `YYYY-MM-DD`, the shape both ends of the API parse and the shape the calendar
/// writes. Also the shape `DateTime.tryParse` accepts, so a value typed by hand
/// can be opened in the picker without a second date format to keep in step.
final RegExp kIsoDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Format a date the way [kIsoDatePattern] expects.
String isoDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

class UiFieldSpec {
  const UiFieldSpec(
    this.name,
    this.label, {
    this.kind = UiFieldKind.text,
    this.readOnly = false,
    this.hint,
    this.help,
    this.error,
  });
  final String name, label;
  final UiFieldKind kind;

  /// Fixed by something other than this screen. Kept focusable and selectable so
  /// it can still be read and copied, and marked as not editable for every kind,
  /// not just text.
  final bool readOnly;

  /// The placeholder shown while the field is empty.
  final String? hint;

  /// Why this field cannot be edited, or a rule about its value.
  ///
  /// Under the control rather than as the placeholder, because a locked field's
  /// placeholder is usually still occupied by the value it holds.
  final String? help;

  /// The rejection to show under this field. Attached to the spec rather than
  /// passed separately so a caller cannot render a control without its error.
  final String? error;
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

  /// The spec with this field's rejection attached, so the control and the message
  /// about it cannot be built from different sources.
  ///
  /// Returns the original instance unchanged when there is no error, which is the
  /// common case: rebuilding every spec on every keystroke would rebuild every
  /// control, and the text fields hold their own controllers across that.
  UiFieldSpec _withError(UiFieldSpec field, Map<String, String> errors) {
    final error = errors[field.name];
    if (error == null) return field;
    return UiFieldSpec(
      field.name,
      field.label,
      kind: field.kind,
      readOnly: field.readOnly,
      hint: field.hint,
      help: field.help,
      error: error,
    );
  }

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ZLabel(field.label),
                      if (field.help != null) ...[
                        const ZGap(6, 8),
                        Text(
                          field.help!,
                          style: const TextStyle(
                            color: ZColors.muted,
                            fontSize: 12,
                            height: 1.4,
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
              field: _withError(field, errors),
              value: values[field.name]?.toString(),
              options: options[field.name] ?? const <UiOption>[],
              onChanged: onChanged == null
                  ? null
                  : (v) => onChanged!(field.name, v),
            ),
            _ => _BoundTextField(
              key: ValueKey(field.name),
              field: _withError(field, errors),
              value: values[field.name]?.toString(),
              calendar: field.kind == UiFieldKind.date,
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
///
/// The selected value is only forwarded when it exists in the option list, which
/// keeps an out-of-date presenter value from tripping the FormField assertion. That
/// is also what makes narrowing the list safe: a value the caller has just made
/// ineligible shows as unselected rather than as a choice that is not on offer.
class _UiSelect extends StatelessWidget {
  const _UiSelect({
    required this.field,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final UiFieldSpec field;
  final String? value;
  final List<UiOption> options;
  final ValueChanged<String?>? onChanged;
  @override
  Widget build(BuildContext context) {
    final selected = options.any((o) => o.value == value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZLabel(field.label),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          key: ValueKey('${field.name}:${selected ?? ''}'),
          initialValue: selected,
          isExpanded: true,
          dropdownColor: ZColors.surface2,
          // Material's default dropdown text is black on this dark surface, and
          // the item widgets sit outside the button's style, so the colour has to
          // be set in both places rather than inherited.
          style: TextStyle(
            fontSize: 14,
            color: field.readOnly ? ZColors.muted : ZColors.ink,
          ),
          decoration: InputDecoration(
            hintText: field.hint,
            errorText: field.error,
            helperText: field.readOnly ? field.help : null,
            helperStyle: const TextStyle(color: ZColors.muted, fontSize: 12),
          ),
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
          onChanged: field.readOnly ? null : onChanged,
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
    this.onChanged,
    this.calendar = false,
  });
  final UiFieldSpec field;
  final String? value;
  final ValueChanged<String>? onChanged;

  /// Adds a picker button. Typing stays allowed, so a date can be corrected
  /// without opening a dialog and a field can still be filled by paste.
  final bool calendar;
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

  /// Open the calendar and write back what was picked.
  ///
  /// The value travels through [widget.onChanged] like any other edit, so the
  /// presenter ends up with the same string it would have got from typing and
  /// needs no separate path for a picked date.
  Future<void> _pickDate(BuildContext context) async {
    final shown = DateTime.tryParse(widget.value ?? '');
    final picked = await showDatePicker(
      context: context,
      initialDate: shown ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    widget.onChanged?.call(isoDate(picked));
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ZLabel(widget.field.label),
      const SizedBox(height: 9),
      TextFormField(
        controller: controller,
        // readOnly rather than enabled: false, so a locked value can still be
        // selected and copied. Nobody can type over a value that is set from
        // elsewhere.
        readOnly: widget.field.readOnly,
        obscureText: widget.field.kind == UiFieldKind.password,
        keyboardType: widget.field.kind == UiFieldKind.number
            ? TextInputType.number
            : TextInputType.text,
        style: TextStyle(
          fontSize: 14,
          color: widget.field.readOnly ? ZColors.muted : ZColors.ink,
        ),
        decoration: InputDecoration(
          hintText: widget.field.hint,
          errorText: widget.field.error,
          helperText: widget.field.readOnly ? widget.field.help : null,
          helperStyle: const TextStyle(color: ZColors.muted, fontSize: 12),
          suffixIcon: widget.calendar
              ? IconButton(
                  icon: const Icon(Icons.calendar_month_outlined, size: 17),
                  color: ZColors.muted,
                  tooltip: 'Pick a date',
                  onPressed: widget.field.readOnly || widget.onChanged == null
                      ? null
                      : () => _pickDate(context),
                )
              : null,
        ),
        onChanged: widget.field.readOnly ? null : widget.onChanged,
      ),
    ],
  );
}