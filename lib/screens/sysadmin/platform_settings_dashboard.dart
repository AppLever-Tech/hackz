import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../constants/default_platform_settings.dart';
import '../../constants/platform_settings_sections.dart';
import '../../models/platform_setting_definition.dart';
import '../../models/user_model.dart';
import '../../utils/platform_settings_service.dart';
import '../../widgets/platformsettings/platform_setting_value_tile.dart';
import '../../widgets/platformsettings/settings_group_widget.dart';
import '../../constants/app_icons.dart';

/// SysAdmin: centralized platform rules (`hkzPlatformSettings/config`).
class PlatformSettingsDashboard extends StatefulWidget {
  const PlatformSettingsDashboard({super.key, required this.user});

  final UserModel user;

  @override
  State<PlatformSettingsDashboard> createState() => _PlatformSettingsDashboardState();
}

class _SectionVm {
  const _SectionVm({
    required this.sectionKey,
    required this.title,
    required this.icon,
    required this.groupOrder,
    required this.byGroup,
  });

  final String sectionKey;
  final String title;
  final IconData icon;
  final List<String> groupOrder;
  final Map<String, List<PlatformSettingDefinition>> byGroup;
}

List<_SectionVm> _computeSectionViewModels() {
  final Map<String, List<PlatformSettingDefinition>> bySection = <String, List<PlatformSettingDefinition>>{};
  for (final PlatformSettingDefinition d in defaultPlatformSettingDefinitions) {
    bySection.putIfAbsent(d.sectionKey, () => <PlatformSettingDefinition>[]).add(d);
  }
  final List<_SectionVm> out = <_SectionVm>[];
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
    out.add(
      _SectionVm(
        sectionKey: sectionKey,
        title: defs.first.sectionTitle,
        icon: platformSettingsSectionIcon(sectionKey),
        groupOrder: groupOrder,
        byGroup: byGroup,
      ),
    );
  }
  return out;
}

bool _definitionMatchesQuery(PlatformSettingDefinition d, String sectionTitle, String groupTitle, String q) {
  if (q.isEmpty) return true;
  return d.displayName.toLowerCase().contains(q) ||
      (d.description ?? '').toLowerCase().contains(q) ||
      d.key.toLowerCase().contains(q) ||
      groupTitle.toLowerCase().contains(q) ||
      sectionTitle.toLowerCase().contains(q);
}

class _PlatformSettingsDashboardState extends State<PlatformSettingsDashboard> {
  late Future<void> _loadFuture;
  final TextEditingController _searchController = TextEditingController();
  final List<_SectionVm> _sections = _computeSectionViewModels();
  String? _selectedSectionKey;
  final Map<String, Object?> _draft = <String, Object?>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = PlatformSettingsService.instance.ensureLoaded();
    if (_sections.isNotEmpty) {
      _selectedSectionKey = _sections.first.sectionKey;
    }
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _loadFuture = PlatformSettingsService.instance.ensureLoaded(force: true);
    });
  }

  _SectionVm? get _selectedSection {
    final String? key = _selectedSectionKey;
    if (key == null) return null;
    for (final _SectionVm s in _sections) {
      if (s.sectionKey == key) return s;
    }
    return null;
  }

  String get _searchQuery => _searchController.text.trim().toLowerCase();

  Object? _resolvedValue(PlatformSettingDefinition d) {
    final PlatformSettingsService svc = PlatformSettingsService.instance;
    if (_draft.containsKey(d.key)) {
      return _draft[d.key];
    }
    return svc.valuesSnapshot[d.key] ?? d.defaultValue;
  }

  void _onDraftCoerced(String key, Object? coerced) {
    setState(() {
      _draft[key] = coerced;
    });
  }

  bool _valueEqualsBaseline(String key, Object? draftValue) {
    final PlatformSettingsService svc = PlatformSettingsService.instance;
    final Object? baseline = svc.valuesSnapshot[key];
    return _platformSettingsValueEquals(draftValue, baseline);
  }

  bool get _hasDirtyDraft {
    for (final MapEntry<String, Object?> e in _draft.entries) {
      if (!_valueEqualsBaseline(e.key, e.value)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _saveDraft() async {
    if (!_hasDirtyDraft || _saving) return;
    final PlatformSettingsService svc = PlatformSettingsService.instance;
    final List<String> keysToSave = _draft.keys.where((String k) => !_valueEqualsBaseline(k, _draft[k])).toList(growable: false);
    if (keysToSave.isEmpty) return;

    setState(() => _saving = true);
    String? firstError;
    for (final String key in keysToSave) {
      final String? err = await svc.updateValue(key, _draft[key]);
      if (err != null) {
        firstError = err;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (firstError == null) {
        _draft.clear();
      } else {
        _draft.removeWhere((String k, Object? v) => _valueEqualsBaseline(k, v));
      }
    });
    if (!mounted) return;
    if (firstError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(firstError)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Platform settings saved.')));
    }
  }

  void _discardDraft() {
    if (!_hasDirtyDraft) return;
    setState(_draft.clear);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes discarded.')));
    }
  }

  static const double _kSettingsLeftIndent = 12;

  BoxDecoration _settingsCardDecoration(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE8ECF8), width: 1.2),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Color(0x0C000000), blurRadius: 14, offset: Offset(0, 6)),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search all platform settings',
              prefixIcon: Icon(AppIcons.search, size: 20, color: cs.onSurfaceVariant),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cs.primary, width: 1.4),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 6),
        FilledButton.icon(
          onPressed: (!_hasDirtyDraft || _saving) ? null : () => _saveDraft(),
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_outlined, size: 18),
          label: Text(_saving ? 'Saving' : 'Save'),
        ),
        const SizedBox(width: 6),
        OutlinedButton.icon(
          onPressed: (!_hasDirtyDraft || _saving) ? null : _discardDraft,
          icon: const Icon(AppIcons.remove, size: 18),
          label: const Text('Discard'),
        ),
      ],
    );
  }

  Widget _buildLoadedBody(BuildContext context, String? weightsHint) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final bool twoColumn = c.maxWidth >= 900;
        final Widget? hintBanner = weightsHint == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                          weightsHint,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

        final Widget leftNav = _PlatformSettingsLeftNav(
          sections: _sections,
          selectedKey: _selectedSectionKey,
          onSelect: (String key) => setState(() => _selectedSectionKey = key),
        );

        final Widget rightPane = _PlatformSettingsRightPane(
          sections: _sections,
          selectedSection: _selectedSection,
          searchQuery: _searchQuery,
          cardDecoration: _settingsCardDecoration(context),
          settingsLeftIndent: _kSettingsLeftIndent,
          resolvedValue: _resolvedValue,
          onDraftCoerced: _onDraftCoerced,
        );

        final Widget panes = twoColumn
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(width: (c.maxWidth * 0.24).clamp(200.0, 260.0), child: leftNav),
                  const SizedBox(width: 6),
                  Expanded(child: rightPane),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(height: 160, child: leftNav),
                  const SizedBox(height: 6),
                  Expanded(child: rightPane),
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (hintBanner != null) hintBanner,
            _buildToolbar(context),
            const SizedBox(height: 4),
            Expanded(child: panes),
          ],
        );
      },
    );
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
                Icon(AppIcons.settings, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(
                  'Could not load platform settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    svc.lastError!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _retry,
                  icon: const Icon(AppIcons.refresh),
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
              builder: (BuildContext context, BoxConstraints outer) {
                final double bodyHeight = outer.maxHeight.isFinite
                    ? outer.maxHeight
                    : (MediaQuery.sizeOf(context).height - 72).clamp(480.0, 1600.0);
                final double w = outer.maxWidth.isFinite ? outer.maxWidth : MediaQuery.sizeOf(context).width;
                return SizedBox(
                  width: w,
                  height: bodyHeight,
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: _buildLoadedBody(context, hint),
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

bool _platformSettingsValueEquals(Object? a, Object? b) {
  if (a is List && b is List) {
    return listEquals(
      a.map((Object? e) => e.toString()).toList(growable: false),
      b.map((Object? e) => e.toString()).toList(growable: false),
    );
  }
  return a == b;
}

class _PlatformSettingsLeftNav extends StatelessWidget {
  const _PlatformSettingsLeftNav({
    required this.sections,
    required this.selectedKey,
    required this.onSelect,
  });

  final List<_SectionVm> sections;
  final String? selectedKey;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: sections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (BuildContext context, int index) {
        final _SectionVm s = sections[index];
        final bool selected = s.sectionKey == selectedKey;
        return _PlatformSettingsNavTile(
          title: s.title,
          icon: s.icon,
          selected: selected,
          onTap: () => onSelect(s.sectionKey),
        );
      },
    );
  }
}

class _PlatformSettingsNavTile extends StatelessWidget {
  const _PlatformSettingsNavTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  cs.primaryContainer.withValues(alpha: 0.55),
                  cs.secondaryContainer.withValues(alpha: 0.35),
                ],
              )
            : null,
        color: selected ? null : Colors.transparent,
        border: Border.all(
          color: selected ? cs.primary.withValues(alpha: 0.65) : cs.outline.withValues(alpha: 0.25),
          width: selected ? 1.3 : 1,
        ),
        boxShadow: selected
            ? <BoxShadow>[
                BoxShadow(color: cs.primary.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4)),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.outline.withValues(alpha: selected ? 0.4 : 0.2)),
                  ),
                  child: Icon(icon, color: selected ? cs.primary : cs.onSurfaceVariant, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                          color: selected ? cs.onPrimaryContainer : cs.onSurface,
                          height: 1.2,
                        ),
                  ),
                ),
                if (selected)
                  Icon(AppIcons.onboardingNext, color: cs.primary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlatformSettingsRightPane extends StatelessWidget {
  const _PlatformSettingsRightPane({
    required this.sections,
    required this.selectedSection,
    required this.searchQuery,
    required this.cardDecoration,
    required this.settingsLeftIndent,
    required this.resolvedValue,
    required this.onDraftCoerced,
  });

  final List<_SectionVm> sections;
  final _SectionVm? selectedSection;
  final String searchQuery;
  final BoxDecoration cardDecoration;
  final double settingsLeftIndent;
  final Object? Function(PlatformSettingDefinition) resolvedValue;
  final void Function(String key, Object? coerced) onDraftCoerced;

  List<Widget> _buildSectionModeBody(_SectionVm s, double settingsLeftIndent) {
    final Map<String, List<PlatformSettingDefinition>> byGroup = <String, List<PlatformSettingDefinition>>{};
    for (final String gk in s.groupOrder) {
      final List<PlatformSettingDefinition>? group = s.byGroup[gk];
      if (group == null) continue;
      byGroup[gk] = List<PlatformSettingDefinition>.from(group);
    }

    final List<Widget> blocks = <Widget>[];
    for (final String gk in s.groupOrder) {
      final List<PlatformSettingDefinition>? defs = byGroup[gk];
      if (defs == null || defs.isEmpty) continue;
      blocks.add(
        SettingsGroupWidget(
          title: defs.first.groupTitle,
          children: <Widget>[
            for (final PlatformSettingDefinition d in defs)
              Padding(
                padding: EdgeInsets.only(left: settingsLeftIndent),
                child: PlatformSettingValueTile(
                  definition: d,
                  persistImmediately: false,
                  resolvedValue: resolvedValue(d),
                  onLocalCoerced: (Object? coerced) => onDraftCoerced(d.key, coerced),
                ),
              ),
          ],
        ),
      );
      blocks.add(const SizedBox(height: 8));
    }
    if (blocks.isNotEmpty) {
      blocks.removeLast();
    }
    return blocks;
  }

  List<Widget> _buildGlobalSearchBody(double settingsLeftIndent) {
    final String q = searchQuery;
    final List<Widget> blocks = <Widget>[];
    for (final _SectionVm sec in sections) {
      for (final String gk in sec.groupOrder) {
        final List<PlatformSettingDefinition>? group = sec.byGroup[gk];
        if (group == null) continue;
        final String groupTitle = group.first.groupTitle;
        final List<PlatformSettingDefinition> matched = group
            .where((PlatformSettingDefinition d) => _definitionMatchesQuery(d, sec.title, groupTitle, q))
            .toList(growable: false);
        if (matched.isEmpty) continue;
        blocks.add(
          SettingsGroupWidget(
            title: '${sec.title} — $groupTitle',
            children: <Widget>[
              for (final PlatformSettingDefinition d in matched)
                Padding(
                  padding: EdgeInsets.only(left: settingsLeftIndent),
                  child: PlatformSettingValueTile(
                    definition: d,
                    persistImmediately: false,
                    resolvedValue: resolvedValue(d),
                    onLocalCoerced: (Object? coerced) => onDraftCoerced(d.key, coerced),
                  ),
                ),
            ],
          ),
        );
        blocks.add(const SizedBox(height: 8));
      }
    }
    if (blocks.isNotEmpty) {
      blocks.removeLast();
    }
    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    final _SectionVm? s = selectedSection;
    if (s == null) {
      return const Center(child: Text('No platform setting sections defined.'));
    }

    final bool globalSearch = searchQuery.isNotEmpty;
    final List<Widget> bodyChildren =
        globalSearch ? _buildGlobalSearchBody(settingsLeftIndent) : _buildSectionModeBody(s, settingsLeftIndent);

    final Widget scrollContent = bodyChildren.isEmpty
        ? Center(
            child: Text(
              globalSearch ? 'No settings match your search.' : 'No settings in this section.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
            children: bodyChildren,
          );

    return Container(
      decoration: cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    globalSearch ? AppIcons.search : s.icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    globalSearch ? 'Search results (all sections)' : s.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
          Expanded(child: scrollContent),
        ],
      ),
    );
  }
}
