import 'package:flutter/material.dart';

import '../../../core/ui/feedback/feedback.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../constants/app_metadata_keys.dart';
import '../models/app_metadata_document.dart';
import '../services/app_metadata_service.dart';

/// System-admin workspace for editing global app metadata.
class AppMetadataManagementScreen extends StatefulWidget {
  const AppMetadataManagementScreen({super.key});

  @override
  State<AppMetadataManagementScreen> createState() => _AppMetadataManagementScreenState();
}

class _AppMetadataManagementScreenState extends State<AppMetadataManagementScreen> {
  late Future<List<AppMetadataDocument>> _future;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = AppMetadataService.fetchAll();
    });
  }

  Future<void> _save(AppMetadataDocument document) async {
    if (_saving) return;
    setState(() => _saving = true);
    await AppMetadataService.save(document);
    if (!mounted) return;
    setState(() => _saving = false);
    _reload();
    FeedbackService.showSuccess(context, title: 'Saved', message: '${document.title} updated.');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        FutureBuilder<List<AppMetadataDocument>>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<List<AppMetadataDocument>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Unable to load metadata: ${snapshot.error}'));
            }
            final List<AppMetadataDocument> docs = snapshot.data ?? const <AppMetadataDocument>[];
            final Map<String, AppMetadataDocument> byId = <String, AppMetadataDocument>{
              for (final AppMetadataDocument d in docs) d.id: d,
            };

            return ListView(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
              children: <Widget>[
                _TextMetadataEditor(
                  docId: AppMetadataKeys.about,
                  document: byId[AppMetadataKeys.about],
                  emptyTitle: 'About Hackz',
                  onSave: _save,
                ),
                const SizedBox(height: 12),
                _TeamMetadataEditor(
                  document: byId[AppMetadataKeys.projectTeam],
                  onSave: _save,
                ),
                const SizedBox(height: 12),
                _TextMetadataEditor(
                  docId: AppMetadataKeys.privacyPolicy,
                  document: byId[AppMetadataKeys.privacyPolicy],
                  emptyTitle: 'Privacy Policy',
                  onSave: _save,
                ),
                const SizedBox(height: 12),
                _TextMetadataEditor(
                  docId: AppMetadataKeys.terms,
                  document: byId[AppMetadataKeys.terms],
                  emptyTitle: 'Terms & Conditions',
                  onSave: _save,
                ),
                const SizedBox(height: 12),
                _AppInfoMetadataEditor(
                  document: byId[AppMetadataKeys.appInfo],
                  onSave: _save,
                ),
              ],
            );
          },
        ),
        if (_saving)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33FFFFFF),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _MetadataSectionCard extends StatelessWidget {
  const _MetadataSectionCard({
    required this.title,
    required this.child,
    required this.onSave,
  });

  final String title;
  final Widget child;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          child,
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: onSave, child: const Text('Save')),
          ),
        ],
      ),
    );
  }
}

class _TextMetadataEditor extends StatefulWidget {
  const _TextMetadataEditor({
    required this.docId,
    required this.document,
    required this.emptyTitle,
    required this.onSave,
  });

  final String docId;
  final AppMetadataDocument? document;
  final String emptyTitle;
  final Future<void> Function(AppMetadataDocument) onSave;

  @override
  State<_TextMetadataEditor> createState() => _TextMetadataEditorState();
}

class _TextMetadataEditorState extends State<_TextMetadataEditor> {
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _body = TextEditingController(text: widget.document?.body ?? '');
  }

  @override
  void didUpdateWidget(covariant _TextMetadataEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document?.body != widget.document?.body) {
      _body.text = widget.document?.body ?? '';
    }
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppMetadataDocument base = widget.document ??
        AppMetadataDocument(
          id: widget.docId,
          type: AppMetadataType.text,
          title: widget.emptyTitle,
        );

    return _MetadataSectionCard(
      title: base.title.isEmpty ? widget.emptyTitle : base.title,
      onSave: () => widget.onSave(base.copyWith(body: _body.text)),
      child: TextField(
        controller: _body,
        maxLines: 8,
        decoration: const InputDecoration(
          labelText: 'Content',
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _TeamMetadataEditor extends StatefulWidget {
  const _TeamMetadataEditor({
    required this.document,
    required this.onSave,
  });

  final AppMetadataDocument? document;
  final Future<void> Function(AppMetadataDocument) onSave;

  @override
  State<_TeamMetadataEditor> createState() => _TeamMetadataEditorState();
}

class _TeamMetadataEditorState extends State<_TeamMetadataEditor> {
  late List<ProjectTeamMember> _members;

  @override
  void initState() {
    super.initState();
    _members = List<ProjectTeamMember>.from(widget.document?.members ?? const <ProjectTeamMember>[]);
  }

  @override
  void didUpdateWidget(covariant _TeamMetadataEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document?.members != widget.document?.members) {
      _members = List<ProjectTeamMember>.from(widget.document?.members ?? const <ProjectTeamMember>[]);
    }
  }

  void _addMember() {
    setState(() {
      _members = <ProjectTeamMember>[
        ..._members,
        const ProjectTeamMember(name: '', designation: ''),
      ];
    });
  }

  void _removeAt(int index) {
    setState(() => _members.removeAt(index));
  }

  void _updateAt(int index, ProjectTeamMember member) {
    setState(() => _members[index] = member);
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final ProjectTeamMember item = _members.removeAt(oldIndex);
      _members.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppMetadataDocument base = widget.document ??
        const AppMetadataDocument(
          id: AppMetadataKeys.projectTeam,
          type: AppMetadataType.projectTeam,
          title: 'Project Team',
        );

    return _MetadataSectionCard(
      title: 'Project Team',
      onSave: () => widget.onSave(base.copyWith(members: _members)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: _addMember,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('Add Member'),
          ),
          const SizedBox(height: 10),
          if (_members.isEmpty)
            const Text('No members yet.', style: TextStyle(color: Color(0xFF64748B)))
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _members.length,
              onReorder: _reorder,
              itemBuilder: (BuildContext context, int index) {
                final ProjectTeamMember member = _members[index];
                return _TeamMemberRow(
                  key: ValueKey<String>('member_$index'),
                  index: index,
                  member: member,
                  onChanged: (ProjectTeamMember updated) => _updateAt(index, updated),
                  onRemove: () => _removeAt(index),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TeamMemberRow extends StatefulWidget {
  const _TeamMemberRow({
    super.key,
    required this.index,
    required this.member,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final ProjectTeamMember member;
  final ValueChanged<ProjectTeamMember> onChanged;
  final VoidCallback onRemove;

  @override
  State<_TeamMemberRow> createState() => _TeamMemberRowState();
}

class _TeamMemberRowState extends State<_TeamMemberRow> {
  late final TextEditingController _name;
  late final TextEditingController _designation;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.member.name);
    _designation = TextEditingController(text: widget.member.designation);
  }

  @override
  void didUpdateWidget(covariant _TeamMemberRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.member.name != widget.member.name) {
      _name.text = widget.member.name;
    }
    if (oldWidget.member.designation != widget.member.designation) {
      _designation.text = widget.member.designation;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _designation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECF6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ReorderableDragStartListener(
            index: widget.index,
            child: const Padding(
              padding: EdgeInsets.only(top: 10, right: 8),
              child: Icon(Icons.drag_handle_rounded, color: Color(0xFF94A3B8)),
            ),
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                TextField(
                  decoration: const InputDecoration(labelText: 'Name', isDense: true),
                  controller: _name,
                  onChanged: (String value) => widget.onChanged(widget.member.copyWith(name: value)),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: 'Designation', isDense: true),
                  controller: _designation,
                  onChanged: (String value) => widget.onChanged(widget.member.copyWith(designation: value)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: widget.onRemove,
            icon: const Icon(Icons.close_rounded, color: Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }
}

class _AppInfoMetadataEditor extends StatefulWidget {
  const _AppInfoMetadataEditor({
    required this.document,
    required this.onSave,
  });

  final AppMetadataDocument? document;
  final Future<void> Function(AppMetadataDocument) onSave;

  @override
  State<_AppInfoMetadataEditor> createState() => _AppInfoMetadataEditorState();
}

class _AppInfoMetadataEditorState extends State<_AppInfoMetadataEditor> {
  late final TextEditingController _version;
  late final TextEditingController _build;
  late final TextEditingController _releaseNotes;
  late final TextEditingController _additionalInfo;

  @override
  void initState() {
    super.initState();
    final AppInfoPayload info = widget.document?.appInfo ?? const AppInfoPayload(version: '', buildNumber: '');
    _version = TextEditingController(text: info.version);
    _build = TextEditingController(text: info.buildNumber);
    _releaseNotes = TextEditingController(text: info.releaseNotes);
    _additionalInfo = TextEditingController(text: info.additionalInfo);
  }

  @override
  void dispose() {
    _version.dispose();
    _build.dispose();
    _releaseNotes.dispose();
    _additionalInfo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppMetadataDocument base = widget.document ??
        const AppMetadataDocument(
          id: AppMetadataKeys.appInfo,
          type: AppMetadataType.appInfo,
          title: 'App Version',
        );

    return _MetadataSectionCard(
      title: 'App Version',
      onSave: () => widget.onSave(
        base.copyWith(
          appInfo: AppInfoPayload(
            version: _version.text,
            buildNumber: _build.text,
            releaseNotes: _releaseNotes.text,
            additionalInfo: _additionalInfo.text,
          ),
        ),
      ),
      child: Column(
        children: <Widget>[
          TextField(controller: _version, decoration: const InputDecoration(labelText: 'Version')),
          const SizedBox(height: 10),
          TextField(controller: _build, decoration: const InputDecoration(labelText: 'Build number')),
          const SizedBox(height: 10),
          TextField(
            controller: _releaseNotes,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Release notes', alignLabelWithHint: true),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _additionalInfo,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Additional info', alignLabelWithHint: true),
          ),
        ],
      ),
    );
  }
}
