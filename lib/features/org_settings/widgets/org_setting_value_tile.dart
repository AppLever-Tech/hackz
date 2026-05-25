import 'package:flutter/material.dart';

import '../models/enums/org_setting_value_type.dart';
import '../models/org_setting_definition.dart';
import '../services/org_settings_service.dart';
import '../services/org_settings_validators.dart';
import 'settings_number_stepper.dart';
import 'settings_slider_tile.dart';
import 'settings_string_list_tile.dart';
import 'settings_switch_tile.dart';
import 'settings_tile.dart';

class OrgSettingValueTile extends StatefulWidget {
  const OrgSettingValueTile({
    super.key,
    required this.definition,
    this.persistImmediately = true,
    /// When [persistImmediately] is false, use this as the displayed value (draft over server).
    this.resolvedValue,
    /// When [persistImmediately] is false, called with validated coerced values instead of persisting.
    this.onLocalCoerced,
  }) : assert(
          persistImmediately || onLocalCoerced != null,
          'onLocalCoerced is required when persistImmediately is false',
        );

  final OrgSettingDefinition definition;
  final bool persistImmediately;
  final Object? resolvedValue;
  final void Function(Object? coerced)? onLocalCoerced;

  @override
  State<OrgSettingValueTile> createState() => _OrgSettingValueTileState();
}

class _OrgSettingValueTileState extends State<OrgSettingValueTile> {
  bool _busy = false;

  Future<void> _persist(Object? value) async {
    setState(() => _busy = true);
    final String? err = await OrgSettingsService.instance.updateValue(widget.definition.key, value);
    setState(() => _busy = false);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  void _applyLocalOrPersist(Object? value) {
    final OrgSettingDefinition d = widget.definition;
    Object? coerced;
    final String? err = OrgSettingsValidators.validateAndCoerce(d, value, (c) => coerced = c);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (widget.persistImmediately) {
      _persist(coerced);
    } else {
      widget.onLocalCoerced?.call(coerced);
    }
  }

  Object? _rawForDisplay() {
    final OrgSettingDefinition d = widget.definition;
    if (!widget.persistImmediately) {
      return widget.resolvedValue ?? OrgSettingsService.instance.valuesSnapshot[d.key] ?? d.defaultValue;
    }
    return OrgSettingsService.instance.valuesSnapshot[d.key] ?? d.defaultValue;
  }

  int _sliderDivisions(double min, double max, double step) {
    if (step <= 0) return 20;
    final int n = ((max - min) / step).round();
    return n.clamp(1, 200);
  }

  @override
  Widget build(BuildContext context) {
    final OrgSettingDefinition d = widget.definition;
    final Object? raw = _rawForDisplay();

    switch (d.type) {
      case OrgSettingValueType.boolean:
        final bool v = raw is bool ? raw : (d.defaultValue as bool);
        return SettingsSwitchTile(
          title: d.displayName,
          subtitle: d.description,
          value: v,
          loading: _busy,
          onChanged: (bool next) => _applyLocalOrPersist(next),
        );
      case OrgSettingValueType.integer:
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
            onChanged: (int next) => _applyLocalOrPersist(next),
          ),
        );
      case OrgSettingValueType.double:
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
            _applyLocalOrPersist(snapped.clamp(min, max));
          },
        );
      case OrgSettingValueType.stringList:
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
            if (widget.persistImmediately) {
              setState(() => _busy = true);
              final String? err = await OrgSettingsService.instance.updateValue(d.key, next);
              setState(() => _busy = false);
              return err;
            }
            Object? coerced;
            final String? validationErr = OrgSettingsValidators.validateAndCoerce(d, next, (c) => coerced = c);
            if (validationErr != null) return validationErr;
            widget.onLocalCoerced?.call(coerced);
            return null;
          },
        );
    }
  }
}
