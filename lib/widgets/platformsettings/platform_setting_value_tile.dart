import 'package:flutter/material.dart';

import '../../models/enums/platform_setting_value_type.dart';
import '../../models/platform_setting_definition.dart';
import '../../utils/platform_settings_service.dart';
import 'settings_number_stepper.dart';
import 'settings_slider_tile.dart';
import 'settings_string_list_tile.dart';
import 'settings_switch_tile.dart';
import 'settings_tile.dart';

class PlatformSettingValueTile extends StatefulWidget {
  const PlatformSettingValueTile({
    super.key,
    required this.definition,
  });

  final PlatformSettingDefinition definition;

  @override
  State<PlatformSettingValueTile> createState() => _PlatformSettingValueTileState();
}

class _PlatformSettingValueTileState extends State<PlatformSettingValueTile> {
  bool _busy = false;

  Future<void> _persist(Object? value) async {
    setState(() => _busy = true);
    final String? err = await PlatformSettingsService.instance.updateValue(widget.definition.key, value);
    setState(() => _busy = false);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  int _sliderDivisions(double min, double max, double step) {
    if (step <= 0) return 20;
    final int n = ((max - min) / step).round();
    return n.clamp(1, 200);
  }

  @override
  Widget build(BuildContext context) {
    final PlatformSettingDefinition d = widget.definition;
    final Object? raw = PlatformSettingsService.instance.valuesSnapshot[d.key] ?? d.defaultValue;

    switch (d.type) {
      case PlatformSettingValueType.boolean:
        final bool v = raw is bool ? raw : (d.defaultValue as bool);
        return SettingsSwitchTile(
          title: d.displayName,
          subtitle: d.description,
          value: v,
          loading: _busy,
          onChanged: (bool next) => _persist(next),
        );
      case PlatformSettingValueType.integer:
        final int min = (d.min ?? 0).toInt();
        final int max = (d.max ?? 999).toInt();
        final int step = (d.step ?? 1).toInt().clamp(1, max);
        int v = raw is int ? raw : (raw is num ? raw.toInt() : min);
        v = v.clamp(min, max);
        return SettingsTile(
          title: d.displayName,
          subtitle: d.description,
          trailing: SettingsNumberStepper(
            value: v,
            min: min,
            max: max,
            step: step,
            loading: _busy,
            onChanged: (int next) => _persist(next),
          ),
        );
      case PlatformSettingValueType.double:
        final double min = (d.min ?? 0).toDouble();
        final double max = (d.max ?? 1).toDouble();
        final double step = (d.step ?? 0.05).toDouble();
        double v = raw is double ? raw : (raw is num ? raw.toDouble() : min);
        v = v.clamp(min, max);
        return SettingsSliderTile(
          title: d.displayName,
          subtitle: d.description,
          value: v,
          min: min,
          max: max,
          divisions: _sliderDivisions(min, max, step),
          labelBuilder: (double x) => '${(x * 100).round()}%',
          loading: _busy,
          onChangedEnd: (double x) {
            final double snapped = (x / step).round() * step;
            _persist(snapped.clamp(min, max));
          },
        );
      case PlatformSettingValueType.stringList:
        final List<String> list = raw is List
            ? raw.map((e) => e.toString()).toList(growable: false)
            : List<String>.from(
                (d.defaultValue is List ? (d.defaultValue as List) : const <Never>[]).map((e) => e.toString()),
              );
        return SettingsStringListTile(
          title: d.displayName,
          subtitle: d.description,
          value: list,
          loading: _busy,
          onCommit: (List<String> next) async {
            setState(() => _busy = true);
            final String? err = await PlatformSettingsService.instance.updateValue(d.key, next);
            setState(() => _busy = false);
            return err;
          },
        );
    }
  }
}
