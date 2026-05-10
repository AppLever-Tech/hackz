import 'package:flutter/material.dart';

import '../../constants/default_platform_settings.dart';
import '../../constants/platform_settings_sections.dart';
import '../../models/platform_setting_definition.dart';
import '../../models/user_model.dart';
import '../../utils/platform_settings_service.dart';
import '../../widgets/platformsettings/platform_setting_value_tile.dart';
import '../../widgets/platformsettings/settings_group_widget.dart';
import '../../widgets/platformsettings/settings_section_card.dart';
import '../../constants/app_icons.dart';

/// SysAdmin: centralized platform rules (`hkzPlatformSettings/config`).
class PlatformSettingsDashboard extends StatefulWidget {
  const PlatformSettingsDashboard({super.key, required this.user});

  final UserModel user;

  @override
  State<PlatformSettingsDashboard> createState() => _PlatformSettingsDashboardState();
}

class _PlatformSettingsDashboardState extends State<PlatformSettingsDashboard> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = PlatformSettingsService.instance.ensureLoaded();
  }

  void _retry() {
    setState(() {
      _loadFuture = PlatformSettingsService.instance.ensureLoaded(force: true);
    });
  }

  List<Widget> _buildSections() {
    final Map<String, List<PlatformSettingDefinition>> bySection = <String, List<PlatformSettingDefinition>>{};
    for (final PlatformSettingDefinition d in defaultPlatformSettingDefinitions) {
      bySection.putIfAbsent(d.sectionKey, () => <PlatformSettingDefinition>[]).add(d);
    }

    final List<Widget> out = <Widget>[];
    for (final String sectionKey in kPlatformSettingsSectionOrder) {
      final List<PlatformSettingDefinition>? defs = bySection[sectionKey];
      if (defs == null || defs.isEmpty) continue;

      final List<String> groupOrder = <String>[];
      for (final PlatformSettingDefinition d in defs) {
        if (!groupOrder.contains(d.groupKey)) {
          groupOrder.add(d.groupKey);
        }
      }
      final Map<String, List<PlatformSettingDefinition>> byGroup = <String, List<PlatformSettingDefinition>>{};
      for (final PlatformSettingDefinition d in defs) {
        byGroup.putIfAbsent(d.groupKey, () => <PlatformSettingDefinition>[]).add(d);
      }

      final String sectionTitle = defs.first.sectionTitle;
      out.add(
        SettingsSectionCard(
          title: sectionTitle,
          icon: platformSettingsSectionIcon(sectionKey),
          children: <Widget>[
            for (final String gk in groupOrder) ...<Widget>[
              SettingsGroupWidget(
                title: byGroup[gk]!.first.groupTitle,
                children: <Widget>[
                  for (final PlatformSettingDefinition d in byGroup[gk]!)
                    PlatformSettingValueTile(definition: d),
                ],
              ),
              if (gk != groupOrder.last) const SizedBox(height: 14),
            ],
          ],
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final PlatformSettingsService svc = PlatformSettingsService.instance;
        if (svc.lastError != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(AppIcons.settings, size: 40, color: Colors.grey.shade600),
                const SizedBox(height: 12),
                Text(
                  'Could not load platform settings',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    svc.lastError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return ListenableBuilder(
          listenable: svc,
          builder: (BuildContext context, Widget? _) {
            final String? hint = svc.weightsHint();
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final double maxW = c.maxWidth;
                return SingleChildScrollView(
                  key: ValueKey<String>('platform-settings-${widget.user.userId}'),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW > 1100 ? 1040 : maxW),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (hint != null) ...<Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFFDBA74)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Icon(AppIcons.insights, size: 20, color: Colors.orange.shade800),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      hint,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          ..._buildSections(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
