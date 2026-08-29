import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../core/responsive/responsive_filter_bar.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/inputs/hackz_select_field.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../utils/firestore_utils.dart';
import '../models/domain_model.dart';
import '../services/domain_service.dart';

/// College/Department Admin screen for managing Domains.
class DomainManagementScreen extends StatefulWidget {
  const DomainManagementScreen({
    super.key,
    required this.orgId,
    this.lockedDepartmentId,
    this.lockedDepartmentCode,
    this.lockedDepartmentName,
    this.compact = false,
  });

  final String orgId;
  /// When set (dept admin), domains are scoped to this department only.
  final String? lockedDepartmentId;
  final String? lockedDepartmentCode;
  final String? lockedDepartmentName;
  /// Compact chrome for dialog/workspace embedding (no page-sized title).
  final bool compact;

  @override
  State<DomainManagementScreen> createState() => _DomainManagementScreenState();
}

class _DomainManagementScreenState extends State<DomainManagementScreen> {
  late Future<List<DomainModel>> _future;
  List<Map<String, String>> _departments = <Map<String, String>>[];
  String? _filterDepartmentId;
  bool _loadingDeps = true;

  bool get _isDeptScoped => (widget.lockedDepartmentId ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _filterDepartmentId = widget.lockedDepartmentId?.trim().isEmpty == true ? null : widget.lockedDepartmentId?.trim();
    _future = DomainService.listByOrg(
      orgId: widget.orgId,
      departmentId: _isDeptScoped ? widget.lockedDepartmentId : _filterDepartmentId,
    );
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _loadingDeps = true);
    try {
      final List<Map<String, dynamic>> rows = await FirestoreUtils.getDepartmentsByCollege(widget.orgId);
      final List<Map<String, String>> mapped = rows
          .map((Map<String, dynamic> r) {
            final String id = ((r['id'] as String?) ?? '').trim();
            final String code = ((r['code'] as String?) ?? '').trim().toUpperCase();
            final String name = ((r['name'] as String?) ?? '').trim();
            return <String, String>{'id': id, 'code': code, 'name': name.isEmpty ? code : name};
          })
          .where((Map<String, String> d) => d['id']!.isNotEmpty)
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _departments = mapped;
        _loadingDeps = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDeps = false);
    }
  }

  void _reload() {
    setState(() {
      _future = DomainService.listByOrg(
        orgId: widget.orgId,
        departmentId: _isDeptScoped ? widget.lockedDepartmentId : _filterDepartmentId,
      );
    });
  }

  String _deptLabel(String departmentId) {
    for (final Map<String, String> d in _departments) {
      if (d['id'] == departmentId) {
        return '${d['name']} (${d['code']})';
      }
    }
    return departmentId;
  }

  Future<void> _openEditor({DomainModel? initial}) async {
    final DomainModel? saved = await showDomainEditorDialog(
      context: context,
      orgId: widget.orgId,
      departments: _departments,
      lockedDepartmentId: widget.lockedDepartmentId,
      lockedDepartmentName: widget.lockedDepartmentName,
      initial: initial,
    );
    if (saved != null && mounted) _reload();
  }

  Future<void> _toggleActive(DomainModel domain) async {
    await DomainService.setActive(domainId: domain.domainId, isActive: !domain.isActive);
    if (!mounted) return;
    FeedbackService.showSuccess(
      context,
      title: domain.isActive ? 'Deactivated' : 'Activated',
      message: '${domain.name} is now ${domain.isActive ? 'inactive' : 'active'}.',
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = widget.compact;
    final bool mobile = ResponsiveHelper.isMobile(context);
    final Widget list = FutureBuilder<List<DomainModel>>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<List<DomainModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Unable to load domains: ${snapshot.error}'));
        }
        final List<DomainModel> domains = snapshot.data ?? const <DomainModel>[];
        if (domains.isEmpty) {
          return const Center(
            child: Text('No domains yet. Add a domain to classify problem statements.'),
          );
        }
        return ListView.separated(
          itemCount: domains.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (BuildContext context, int index) {
            return _DomainListTile(
              domain: domains[index],
              departmentLabel: _deptLabel(domains[index].departmentId),
              compactRow: mobile,
              onEdit: () => _openEditor(initial: domains[index]),
              onToggleActive: () => _toggleActive(domains[index]),
            );
          },
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: <Widget>[
        ResponsiveWrapToolbar(
          alignment: WrapAlignment.spaceBetween,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (compact) ...<Widget>[
                  const Icon(AppIcons.domains, size: 18, color: Color(0xFF334155)),
                  const SizedBox(width: 8),
                ],
                Text(
                  'Domains',
                  style: TextStyle(
                    fontSize: compact ? 16 : 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            compact && mobile
                ? IconButton(
                    tooltip: 'Add Domain',
                    onPressed: _loadingDeps ? null : () => _openEditor(),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(AppIcons.add),
                  )
                : FilledButton.icon(
                    onPressed: _loadingDeps ? null : () => _openEditor(),
                    style: MobileToolbarButtonStyles.filled(compact: compact || mobile),
                    icon: const Icon(AppIcons.add, size: MobileToolbarButtonStyles.toolbarIconSize),
                    label: const Text('Add Domain'),
                  ),
          ],
        ),
        if (!_isDeptScoped) ...<Widget>[
          const SizedBox(height: 10),
          HackzSelectField<String>(
            value: _filterDepartmentId,
            hint: 'All departments',
            prefixIcon: AppIcons.departments,
            compact: compact,
            options: <String>[
              '',
              ..._departments.map((Map<String, String> d) => d['id']!),
            ],
            labelBuilder: (String id) {
              if (id.isEmpty) return 'All departments';
              return _deptLabel(id);
            },
            iconBuilder: (_) => AppIcons.departments,
            onChanged: (String id) {
              setState(() => _filterDepartmentId = id.isEmpty ? null : id);
              _reload();
            },
          ),
        ],
        const SizedBox(height: 12),
        if (compact)
          SizedBox(height: _compactListHeight(context), child: list)
        else
          Expanded(child: list),
      ],
    );
  }

  static double _compactListHeight(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    if (ResponsiveHelper.isMobile(context)) {
      return (screenHeight * 0.68).clamp(240.0, screenHeight);
    }
    return (screenHeight * 0.58).clamp(280.0, 520.0);
  }
}

class _DomainListTile extends StatelessWidget {
  const _DomainListTile({
    required this.domain,
    required this.departmentLabel,
    required this.compactRow,
    required this.onEdit,
    required this.onToggleActive,
  });

  final DomainModel domain;
  final String departmentLabel;
  final bool compactRow;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final Widget status = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: domain.isActive
            ? const Color(0xFF059669).withValues(alpha: 0.12)
            : const Color(0xFF94A3B8).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        domain.isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: domain.isActive ? const Color(0xFF059669) : const Color(0xFF64748B),
        ),
      ),
    );
    final Widget actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          tooltip: 'Edit',
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: onEdit,
          icon: const Icon(AppIcons.edit, size: 18),
        ),
        IconButton(
          tooltip: domain.isActive ? 'Deactivate' : 'Activate',
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: onToggleActive,
          icon: Icon(
            domain.isActive ? Icons.toggle_on_rounded : Icons.toggle_off_outlined,
            color: domain.isActive ? const Color(0xFF6A38FF) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
    final Widget identity = Row(
      children: <Widget>[
        Container(
          width: compactRow ? 36 : 40,
          height: compactRow ? 36 : 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF6A38FF).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            domain.icon.trim().isEmpty ? AppIcons.problems : Icons.category_rounded,
            color: const Color(0xFF6A38FF),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                domain.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                '${domain.code} · $departmentLabel'
                '${domain.description.trim().isEmpty ? '' : ' · ${domain.description.trim()}'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.fromLTRB(14, 12, compactRow ? 10 : 8, 12),
      decoration: kDashboardCardDecoration,
      child: compactRow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                identity,
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    status,
                    const Spacer(),
                    actions,
                  ],
                ),
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(child: identity),
                const SizedBox(width: 8),
                status,
                actions,
              ],
            ),
    );
  }
}

Future<DomainModel?> showDomainEditorDialog({
  required BuildContext context,
  required String orgId,
  required List<Map<String, String>> departments,
  String? lockedDepartmentId,
  String? lockedDepartmentName,
  DomainModel? initial,
}) {
  return showAppDialog<DomainModel>(
    context: context,
    width: DialogWidthPreset.standard,
    child: _DomainEditorForm(
      orgId: orgId,
      departments: departments,
      lockedDepartmentId: lockedDepartmentId,
      lockedDepartmentName: lockedDepartmentName,
      initial: initial,
    ),
  );
}

class _DomainEditorForm extends StatefulWidget {
  const _DomainEditorForm({
    required this.orgId,
    required this.departments,
    this.lockedDepartmentId,
    this.lockedDepartmentName,
    this.initial,
  });

  final String orgId;
  final List<Map<String, String>> departments;
  final String? lockedDepartmentId;
  final String? lockedDepartmentName;
  final DomainModel? initial;

  @override
  State<_DomainEditorForm> createState() => _DomainEditorFormState();
}

class _DomainEditorFormState extends State<_DomainEditorForm> {
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _icon;
  late String _departmentId;
  late bool _isActive;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;
  bool get _lockDept => (widget.lockedDepartmentId ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final DomainModel? initial = widget.initial;
    _code = TextEditingController(text: initial?.code ?? '');
    _name = TextEditingController(text: initial?.name ?? '');
    _description = TextEditingController(text: initial?.description ?? '');
    _icon = TextEditingController(text: initial?.icon ?? '');
    _departmentId = (widget.lockedDepartmentId ?? initial?.departmentId ?? '').trim();
    if (_departmentId.isEmpty && widget.departments.isNotEmpty) {
      _departmentId = widget.departments.first['id'] ?? '';
    }
    _isActive = initial?.isActive ?? true;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    _icon.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final String code = _code.text.trim().toUpperCase();
    final String name = _name.text.trim();
    if (_departmentId.isEmpty) {
      FeedbackService.showWarning(context, title: 'Department required', message: 'Select a department.');
      return;
    }
    if (code.isEmpty || name.isEmpty) {
      FeedbackService.showWarning(context, title: 'Required fields', message: 'Code and name are required.');
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final DomainModel updated = widget.initial!.copyWith(
          code: code,
          name: name,
          description: _description.text,
          icon: _icon.text,
          isActive: _isActive,
        );
        await DomainService.update(updated);
        if (!mounted) return;
        Navigator.of(context).pop(updated);
      } else {
        final DomainModel created = await DomainService.create(
          orgId: widget.orgId,
          departmentId: _departmentId,
          code: code,
          name: name,
          description: _description.text,
          icon: _icon.text,
          isActive: _isActive,
        );
        if (!mounted) return;
        Navigator.of(context).pop(created);
      }
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Could not save domain', message: '$e');
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          _isEdit ? 'Edit Domain' : 'Add Domain',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        if (_lockDept)
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Department'),
            child: Text(
              widget.lockedDepartmentName?.trim().isNotEmpty == true
                  ? widget.lockedDepartmentName!.trim()
                  : _departmentId,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          )
        else
          HackzSelectField<String>(
            value: _departmentId.isEmpty ? null : _departmentId,
            hint: 'Select department',
            prefixIcon: AppIcons.departments,
            enabled: !_saving && !_isEdit,
            options: widget.departments.map((Map<String, String> d) => d['id']!).toList(growable: false),
            labelBuilder: (String id) {
              final Map<String, String> match = widget.departments.firstWhere(
                (Map<String, String> d) => d['id'] == id,
                orElse: () => <String, String>{'name': id, 'code': ''},
              );
              final String code = match['code'] ?? '';
              return code.isEmpty ? (match['name'] ?? id) : '${match['name']} ($code)';
            },
            iconBuilder: (_) => AppIcons.departments,
            onChanged: (String id) => setState(() => _departmentId = id),
          ),
        const SizedBox(height: 10),
        TextField(
          controller: _code,
          enabled: !_saving,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Code', hintText: 'e.g. CLOUDSEC'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _name,
          enabled: !_saving,
          decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Cloud Security'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _description,
          enabled: !_saving,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _icon,
          enabled: !_saving,
          decoration: const InputDecoration(labelText: 'Icon (optional)', hintText: 'e.g. cloud'),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Active', style: TextStyle(fontWeight: FontWeight.w700)),
          value: _isActive,
          onChanged: _saving ? null : (bool value) => setState(() => _isActive = value),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            OutlinedButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ],
    );
  }
}
