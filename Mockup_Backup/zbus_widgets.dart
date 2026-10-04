import 'package:flutter/material.dart';

import 'zbus_theme.dart';

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
    this.onChanged,
  });
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscure;
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
        onChanged: onChanged,
        decoration: InputDecoration(hintText: hint),
      ),
    ],
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
