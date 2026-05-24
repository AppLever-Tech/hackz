import 'package:flutter/material.dart';

import 'settings_tile.dart';

class SettingsSliderTile extends StatefulWidget {
  const SettingsSliderTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.labelBuilder,
    required this.onChangedEnd,
    this.loading = false,
  });

  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double v) labelBuilder;
  final ValueChanged<double> onChangedEnd;
  final bool loading;

  @override
  State<SettingsSliderTile> createState() => _SettingsSliderTileState();
}

class _SettingsSliderTileState extends State<SettingsSliderTile> {
  late double _drag;

  @override
  void initState() {
    super.initState();
    _drag = widget.value;
  }

  @override
  void didUpdateWidget(covariant SettingsSliderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.loading && oldWidget.value != widget.value) {
      _drag = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: widget.title,
      subtitle: widget.subtitle,
      trailing: SizedBox(
        width: 200,
        child: widget.loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF6A38FF),
                      inactiveTrackColor: const Color(0xFFE8ECF8),
                      thumbColor: const Color(0xFF6A38FF),
                      overlayColor: const Color(0x226A38FF),
                    ),
                    child: Slider(
                      min: widget.min,
                      max: widget.max,
                      divisions: widget.divisions,
                      value: _drag.clamp(widget.min, widget.max),
                      label: widget.labelBuilder(_drag),
                      onChanged: widget.loading
                          ? null
                          : (double v) => setState(() => _drag = v),
                      onChangeEnd: widget.loading ? null : widget.onChangedEnd,
                    ),
                  ),
                  Text(
                    widget.labelBuilder(_drag),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                  ),
                ],
              ),
      ),
    );
  }
}
