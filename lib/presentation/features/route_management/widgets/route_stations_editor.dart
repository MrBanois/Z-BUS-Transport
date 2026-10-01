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
      const ZLabel('Ordered stations'),
      const SizedBox(height: 12),
      for (var i = 0; i < stations.length; i++)
        Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: stations[i].stationId,
              isExpanded: true,
              decoration: InputDecoration(labelText: 'Station ${i + 1}'),
              items: [
                for (final o in options)
                  DropdownMenuItem(value: o.value, child: Text(o.label)),
              ],
              onChanged: stations[i].onStationChanged,
            ),
            const SizedBox(height: 12),
            if (i == 0)
              const Text('First station · no incoming travel time')
            else
              TextFormField(
                initialValue: stations[i].minutes,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minutes from previous station',
                ),
                onChanged: stations[i].onMinutesChanged,
              ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Move up',
                  onPressed: stations[i].onMoveUp,
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Move down',
                  onPressed: stations[i].onMoveDown,
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  tooltip: 'Remove station',
                  onPressed: stations[i].onRemove,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ],
        ),
      if (stations.isEmpty) const Text('No stations added'),
      const SizedBox(height: 12),
      ZButton('Add station', onPressed: onAdd),
      const SizedBox(height: 12),
      Text('Total duration: ${totalDuration ?? '—'}'),
    ],
  );
}
