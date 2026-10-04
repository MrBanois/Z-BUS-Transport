import 'package:flutter/material.dart';

import 'theme.dart';

// Re-exported so a feature only ever needs to import the design system to reach
// ZColors/ZTheme alongside the components.
export 'theme.dart';

class ZRule extends StatelessWidget {
  const ZRule({super.key});
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: ZColors.line);
}

class ZLabel extends StatelessWidget {
  const ZLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: ZTheme.mono(11, color: color ?? ZColors.muted),
  );
}

class ZButton extends StatefulWidget {
  const ZButton(
    this.text, {
    super.key,
    required this.onPressed,
    this.secondary = false,
    this.icon,
    this.compact = false,
  });
  final String text;
  final VoidCallback? onPressed;
  final bool secondary, compact;
  final IconData? icon;
  @override
  State<ZButton> createState() => _ZButtonState();
}

class _ZButtonState extends State<ZButton> {
  bool hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hover = true),
    onExit: (_) => setState(() => hover = false),
    child: AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 170),
      decoration: BoxDecoration(
        color: widget.secondary
            ? (hover ? ZColors.surface2 : Colors.transparent)
            : (hover ? ZColors.accent : ZColors.ink),
        border: Border.all(
          color: widget.secondary
              ? ZColors.line
              : (hover ? ZColors.accent : ZColors.ink),
        ),
      ),
      child: TextButton(
        onPressed: widget.onPressed,
        style: TextButton.styleFrom(
          foregroundColor: widget.secondary ? ZColors.ink : ZColors.bg,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 16 : 22,
            vertical: widget.compact ? 13 : 17,
          ),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.text.toUpperCase(),
              style: ZTheme.mono(
                11,
                color: widget.secondary ? ZColors.ink : ZColors.bg,
              ),
            ),
            if (widget.icon != null) ...[
              const SizedBox(width: 18),
              Icon(widget.icon, size: 15),
            ],
          ],
        ),
      ),
    ),
  );
}

class ZStatus extends StatelessWidget {
  const ZStatus(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final low = text.toLowerCase();
    final color =
        low.contains('cancel') ||
            low.contains('error') ||
            low.contains('conflict')
        ? ZColors.accent
        : low.contains('warn') ||
              low.contains('pending') ||
              low.contains('boarding')
        ? ZColors.warning
        : low.contains('active') ||
              low.contains('confirm') ||
              low.contains('check') ||
              low.contains('complete') ||
              low.contains('accept')
        ? ZColors.success
        : ZColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: .55)),
      ),
      child: Text(text.toUpperCase(), style: ZTheme.mono(9, color: color)),
    );
  }
}

class ZPanel extends StatelessWidget {
  const ZPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: ZColors.surface,
      border: Border.all(color: ZColors.line),
    ),
    child: child,
  );
}

class ZPageHeader extends StatelessWidget {
  const ZPageHeader({
    super.key,
    required this.index,
    required this.kicker,
    required this.title,
    required this.description,
    this.action,
  });
  final String index, kicker, title, description;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final small = width < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (small)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ZLabel('ZBUS / $index', color: ZColors.accent),
              const SizedBox(height: 7),
              ZLabel(kicker),
            ],
          )
        else
          Row(
            children: [
              ZLabel('ZBUS / $index', color: ZColors.accent),
              const Spacer(),
              ZLabel(kicker),
            ],
          ),
        const SizedBox(height: 30),
        Text(
          title.toUpperCase(),
          style: ZTheme.display(
            small
                ? 47
                : width < 1100
                ? 66
                : 82,
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Text(
            description,
            style: const TextStyle(
              color: ZColors.muted,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ),
        if (action != null) ...[const SizedBox(height: 23), action!],
        const SizedBox(height: 33),
        const ZRule(),
        const SizedBox(height: 32),
      ],
    );
  }
}

class ZField extends StatelessWidget {
  const ZField(
    this.label, {
    super.key,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscure = false,
    this.readOnly = false,
    this.error,
    this.onChanged,
  });
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscure, readOnly;
  final String? error;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ZLabel(label),
      const SizedBox(height: 9),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        readOnly: readOnly,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(hintText: hint, errorText: error),
      ),
    ],
  );
}

/// Squared search input. The label sits above the field so the control keeps the
/// same rhythm as every other input instead of showing a floating Material label.
class ZSearch extends StatelessWidget {
  const ZSearch({
    super.key,
    this.hint = 'Search',
    this.controller,
    this.onChanged,
  });
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const ZLabel('Search'),
      const SizedBox(height: 9),
      TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 18, color: ZColors.muted),
          prefixIconConstraints: const BoxConstraints(minWidth: 46),
        ),
      ),
    ],
  );
}

/// Label/value pair used inside panels; keeps the dotted baseline rhythm of the
/// master-file screens without pulling in a table.
class ZKeyValue extends StatelessWidget {
  const ZKeyValue(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 2, child: ZLabel(label)),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ],
  );
}

/// Responsive column grid. Collapses to one column on phones and two on
/// tablets, so panels keep their proportions instead of stretching full width.
class ZColumns extends StatelessWidget {
  const ZColumns({
    super.key,
    required this.children,
    this.desktopColumns = 3,
    this.spacing = 12,
  });
  final List<Widget> children;
  final int desktopColumns;
  final double spacing;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final available = constraints.maxWidth;
      if (!available.isFinite || available <= 0) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              children[i],
            ],
          ],
        );
      }
      final count = available < 650
          ? 1
          : available < 1050
          ? (desktopColumns < 2 ? 1 : 2)
          : desktopColumns;
      final width = (available - spacing * (count - 1)) / count;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

/// Vertical rhythm helper. Preferred over raw SizedBox so page spacing stays
/// consistent across features.
class ZGap extends StatelessWidget {
  // Positional args are kept for terse call sites. Dart forbids mixing optional
  // positional with named params, and adding `key` to a stateless spacing
  // primitive would be noise rather than a real reordering key.
  // ignore: use_key_in_widget_constructors
  const ZGap([this.height = 28, this.width = 0]);
  final double height, width;
  @override
  Widget build(BuildContext context) => SizedBox(height: height, width: width);
}

/// Square icon control. Material IconButton ships a circular ripple and rounded
/// hover target that break the hairline/box language of the rest of the UI.
class ZIconAction extends StatelessWidget {
  const ZIconAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.danger = false,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool danger;
  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = danger ? ZColors.accent : ZColors.ink;
    return Tooltip(
      message: tooltip ?? '',
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: enabled ? color.withValues(alpha: .5) : ZColors.line,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: enabled ? color : ZColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Boxed toggle. Replaces Material Switch, whose rounded track and pill thumb
/// are the single most visible Material artefact in the management screens.
class ZSwitch extends StatelessWidget {
  const ZSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor = ZColors.success,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;
  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final color = value ? activeColor : ZColors.line;
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: enabled ? () => onChanged!(!value) : null,
          child: Container(
            width: 50,
            height: 26,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(border: Border.all(color: color)),
            child: AnimatedAlign(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(width: 18, height: 18, color: value ? color : ZColors.muted),
            ),
          ),
        ),
      ),
    );
  }
}

/// Numeric stepper used for seat counts; keeps the minus/number/plus cluster on
/// a single hairline baseline.
class ZStepper extends StatelessWidget {
  const ZStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 4,
    this.hint,
  });
  final int value;
  final ValueChanged<int>? onChanged;
  final int min, max;
  final String? hint;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      ZIconAction(
        icon: Icons.remove,
        onPressed: onChanged != null && value > min
            ? () => onChanged!(value - 1)
            : null,
      ),
      Container(
        width: 68,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: ZColors.line)),
        child: Text('$value', style: ZTheme.display(34)),
      ),
      ZIconAction(
        icon: Icons.add,
        onPressed: onChanged != null && value < max
            ? () => onChanged!(value + 1)
            : null,
      ),
      if (hint != null) ...[
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            hint!,
            style: const TextStyle(color: ZColors.muted, fontSize: 12),
          ),
        ),
      ],
    ],
  );
}

/// Dialog shell with a display headline and square actions. AlertDialog defaults
/// (rounded 4dp corners, Material text buttons, floating title) do not belong to
/// this design language.
class ZDialog extends StatelessWidget {
  const ZDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.width = 480,
  });
  final String title;
  final Widget child;
  final List<Widget> actions;
  final double width;
  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: ZColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
      side: BorderSide(color: ZColors.line),
    ),
    titlePadding: const EdgeInsets.fromLTRB(28, 26, 28, 0),
    contentPadding: const EdgeInsets.fromLTRB(28, 22, 28, 6),
    actionsPadding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
    title: Text(title.toUpperCase(), style: ZTheme.display(30)),
    content: SizedBox(width: width, child: child),
    actions: [...actions],
  );
}

class ZSelect extends StatelessWidget {
  const ZSelect(
    this.label, {
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabels = const {},
  });
  final String label, value;
  final List<String> items;
  final Map<String, String> itemLabels;
  final ValueChanged<String?>? onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ZLabel(label),
      const SizedBox(height: 9),
      DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        dropdownColor: ZColors.surface2,
        decoration: const InputDecoration(),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  itemLabels[e] ?? e,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    ],
  );
}

class ZStat extends StatelessWidget {
  const ZStat(this.label, this.value, this.note, {super.key});
  final String label, value, note;
  @override
  Widget build(BuildContext context) => ZPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZLabel(label),
        const SizedBox(height: 30),
        Text(value, style: ZTheme.display(48)),
        const SizedBox(height: 12),
        Text(note, style: const TextStyle(color: ZColors.muted, fontSize: 12)),
      ],
    ),
  );
}

class ZNotice extends StatelessWidget {
  const ZNotice(
    this.title,
    this.message, {
    super.key,
    this.color = ZColors.warning,
    this.icon = Icons.info_outline,
  });
  final String title, message;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .07),
      border: Border.all(color: color.withValues(alpha: .6)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(), style: ZTheme.mono(11, color: color)),
              const SizedBox(height: 7),
              Text(
                message,
                style: const TextStyle(
                  color: ZColors.ink,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ZEmpty extends StatelessWidget {
  const ZEmpty(this.title, this.message, {super.key, this.action});
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => ZPanel(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const ZLabel('No records / 00'),
          const SizedBox(height: 18),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: ZTheme.display(36),
          ),
          const SizedBox(height: 13),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ZColors.muted),
          ),
          if (action != null) ...[const SizedBox(height: 23), action!],
        ],
      ),
    ),
  );
}

class ZSectionTitle extends StatelessWidget {
  const ZSectionTitle(this.number, this.title, {super.key, this.trailing});
  final String number, title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        ZLabel(number, color: ZColors.accent),
        const SizedBox(width: 14),
        Expanded(child: Text(title.toUpperCase(), style: ZTheme.display(26))),
        ?trailing,
      ],
    ),
  );
}

class ZRecord extends StatelessWidget {
  const ZRecord({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fields,
    this.status,
    this.action,
    this.onTap,
  });
  final String title, subtitle;
  final Map<String, String> fields;
  final String? status;
  final Widget? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 750;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: mobile ? 21 : 17,
          horizontal: mobile ? 0 : 12,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: ZColors.line)),
        ),
        child: mobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (status != null) ZStatus(status!),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(subtitle, style: ZTheme.mono(10)),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 24,
                    runSpacing: 14,
                    children: fields.entries
                        .map(
                          (e) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ZLabel(e.key),
                              const SizedBox(height: 5),
                              Text(
                                e.value,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                  if (action != null) ...[const SizedBox(height: 18), action!],
                ],
              )
            : Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle, style: ZTheme.mono(10)),
                      ],
                    ),
                  ),
                  ...fields.values.map(
                    (e) => Expanded(
                      flex: 2,
                      child: Text(e, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                  if (status != null)
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ZStatus(status!),
                      ),
                    ),
                  ?action,
                ],
              ),
      ),
    );
  }
}

class ZTable extends StatelessWidget {
  const ZTable({super.key, required this.headers, required this.rows});
  final List<String> headers;
  final List<ZRecord> rows;
  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 750;
    return Column(
      children: [
        if (!mobile)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ZColors.ink)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: ZLabel(headers.first)),
                ...headers
                    .skip(1)
                    .take(headers.length - 2)
                    .map((h) => Expanded(flex: 2, child: ZLabel(h))),
                Expanded(flex: 2, child: ZLabel(headers.last)),
              ],
            ),
          ),
        ...rows,
      ],
    );
  }
}
