import 'package:flutter/material.dart';

import '../../../shared/design_system.dart';
import '../../../shared/ui_fields.dart';

/// The parent owns ordered station rows and segment minutes. Null minutes mean
/// the first station. Calculate total duration in your use case, not in this UI.
class RouteStationInput {
  const RouteStationInput({
    this.stationId,
    this.minutes,
    this.onStationChanged,
    this.onMinutesChanged,
    this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
  });
  final String? stationId;
  final String? minutes;
  final ValueChanged<String?>? onStationChanged;
  final ValueChanged<String>? onMinutesChanged;
  final VoidCallback? onRemove, onMoveUp, onMoveDown;
}

class RouteStationsEditor extends StatelessWidget {
  const RouteStationsEditor({
    super.key,
    this.stations = const [],
    this.options = const [],
    this.onAdd,
    this.totalDuration,
  });
  final List<RouteStationInput> stations;
  final List<UiOption> options;
  final VoidCallback? onAdd;
  final String? totalDuration;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const ZLabel('Ordered stations', color: ZColors.accent),
      const ZGap(16),
      if (stations.isEmpty)
        const ZEmpty('No stations added', 'Add the first stop to this route.')
      else
        for (var i = 0; i < stations.length; i++) ...[
          if (i > 0) ...[const ZGap(20), const ZRule(), const ZGap(20)],
          _stationRow(context, i),
        ],
      const ZGap(20),
      Align(
        alignment: Alignment.centerLeft,
        child: ZButton('Add station', onPressed: onAdd, icon: Icons.add),
      ),
      const ZGap(20),
      const ZRule(),
      const ZGap(18),
      ZKeyValue('Total duration', '${totalDuration ?? '—'} min'),
    ],
  );

  Widget _stationRow(BuildContext context, int index) {
    final station = stations[index];
    final selected = options.any((o) => o.value == station.stationId)
        ? station.stationId
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ZLabel('Station ${(index + 1).toString().padLeft(2, '0')}'),
                  const SizedBox(height: 9),
                  DropdownButtonFormField<String>(
                    key: ValueKey('station:$index:${selected ?? ''}'),
                    initialValue: selected,
                    isExpanded: true,
                    dropdownColor: ZColors.surface2,
                    // See the note in ui_fields.dart: the closed state and the
                    // menu items need the colour set separately.
                    style: const TextStyle(fontSize: 14, color: ZColors.ink),
                    decoration: const InputDecoration(),
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
                    onChanged: station.onStationChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                ZIconAction(
                  icon: Icons.arrow_upward,
                  tooltip: 'Move up',
                  onPressed: index == 0 ? null : station.onMoveUp,
                ),
                const SizedBox(width: 8),
                ZIconAction(
                  icon: Icons.arrow_downward,
                  tooltip: 'Move down',
                  onPressed: index == stations.length - 1
                      ? null
                      : station.onMoveDown,
                ),
                const SizedBox(width: 8),
                ZIconAction(
                  icon: Icons.close,
                  tooltip: 'Remove station',
                  danger: true,
                  onPressed: station.onRemove,
                ),
              ],
            ),
          ],
        ),
        const ZGap(16),
        if (index == 0)
          const Text(
            'First station · no incoming travel time',
            style: TextStyle(color: ZColors.muted, fontSize: 12),
          )
        else ...[
          const ZLabel('Minutes from previous station'),
          const SizedBox(height: 9),
          TextFormField(
            key: ValueKey('minutes:$index:${station.minutes ?? ''}'),
            initialValue: station.minutes,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(),
            onChanged: station.onMinutesChanged,
          ),
        ],
      ],
    );
  }
}