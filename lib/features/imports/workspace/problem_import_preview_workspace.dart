import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/workspace/workspace_controller.dart';
import '../../../core/workspace/workspace_route.dart';
import '../../problems/screens/authoring/problem_authoring_section.dart';
import '../../user/models/user_model.dart';
import '../constants/import_constants.dart';
import '../models/import_review_row.dart';
import '../services/import_description_presenter.dart';

/// Read-only Problem Preview for a normalized import row (no Firestore).
abstract final class ProblemImportPreviewWorkspace {
  static WorkspaceRoute _route(ImportReviewRow row, {UserModel? actor}) {
    final String title = row.valueFor(ImportConstants.titleColumnKey);
    return WorkspaceRoute(
      id: 'problem-import-preview:${row.rowNumber}',
      title: 'Problem Preview',
      subtitle: title.isEmpty ? 'Row ${row.rowNumber}' : title,
      helpPageId: 'csv-import',
      actor: actor,
      builder: (BuildContext context) => ProblemImportPreviewBody(row: row),
    );
  }

  /// Opens on [controller] so the preview stays inside the import dialog host.
  static void open(WorkspaceController controller, ImportReviewRow row, {UserModel? actor}) {
    final WorkspaceRoute route = _route(row, actor: actor);
    if (controller.current?.id == route.id) return;
    controller.open(route);
  }
}

class ProblemImportPreviewBody extends StatelessWidget {
  const ProblemImportPreviewBody({super.key, required this.row});

  final ImportReviewRow row;

  @override
  Widget build(BuildContext context) {
    final String title = row.valueFor(ImportConstants.titleColumnKey);
    final String description = row.valueFor(ImportConstants.descriptionColumnKey);
    final List<ImportDescriptionSection> sections = ImportDescriptionPresenter.present(description);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
      children: <Widget>[
        Text(
          title.isEmpty ? 'Untitled Problem' : title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _chip(AppIcons.info, row.statusLabel),
            if ((row.metadata['source'] ?? '').trim().isNotEmpty)
              _chip(AppIcons.docs, row.metadata['source']!.trim()),
            if (_sourceProblemId.isNotEmpty) _chip(AppIcons.key, _sourceProblemId),
            if (row.valueFor(ImportConstants.themeColumnKey).isNotEmpty)
              _chip(AppIcons.insights, row.valueFor(ImportConstants.themeColumnKey)),
            if ((row.metadata['category'] ?? '').trim().isNotEmpty)
              _chip(AppIcons.orgType, row.metadata['category']!.trim()),
          ],
        ),
        const SizedBox(height: 14),
        ..._descriptionCards(sections),
        if (_hasDetails) ...<Widget>[
          const SizedBox(height: 14),
          const Text('Other Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _detail(AppIcons.organizations, 'Issuing organisation', row.valueFor(ImportConstants.issuingOrganisationColumnKey)),
          _detail(AppIcons.departments, 'Issuing department', row.valueFor(ImportConstants.issuingDepartmentColumnKey)),
          _detail(AppIcons.key, 'Source problem ID', _sourceProblemId),
          _detail(AppIcons.insights, 'Theme', row.valueFor(ImportConstants.themeColumnKey)),
          _detail(AppIcons.orgType, 'Category', row.metadata['category'] ?? ''),
          _detail(AppIcons.attachments, 'Tags', row.valueFor('tags')),
        ],
        if (row.messages.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            row.messages.join('\n'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB45309), height: 1.4),
          ),
        ],
      ],
    );
  }

  String get _sourceProblemId =>
      (row.metadata['sourceProblemId'] ?? row.valueFor(ImportConstants.externalProblemIdColumnKey)).trim();

  bool get _hasDetails {
    return _sourceProblemId.isNotEmpty ||
        row.valueFor(ImportConstants.issuingOrganisationColumnKey).isNotEmpty ||
        row.valueFor(ImportConstants.issuingDepartmentColumnKey).isNotEmpty ||
        row.valueFor(ImportConstants.themeColumnKey).isNotEmpty ||
        (row.metadata['category'] ?? '').trim().isNotEmpty ||
        row.valueFor('tags').isNotEmpty;
  }

  List<Widget> _descriptionCards(List<ImportDescriptionSection> sections) {
    if (sections.isEmpty) {
      return <Widget>[_descriptionCard(title: 'Description', child: _bodyText('—'))];
    }
    final bool structured = sections.any((ImportDescriptionSection s) => (s.heading ?? '').isNotEmpty);
    if (!structured) {
      return <Widget>[
        _descriptionCard(
          title: 'Description',
          child: _paragraphs(sections.map((ImportDescriptionSection s) => s.body).toList(growable: false)),
        ),
      ];
    }
    final List<Widget> cards = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      final ImportDescriptionSection section = sections[i];
      if (i > 0) cards.add(const SizedBox(height: 12));
      cards.add(
        _descriptionCard(
          title: (section.heading ?? '').isEmpty ? 'Description' : section.heading!,
          child: _paragraphs(<String>[section.body]),
        ),
      );
    }
    return cards;
  }

  Widget _descriptionCard({required String title, required Widget child}) {
    return ProblemAuthoringSection(
      title: title,
      subtitle: 'Imported statement — presentation only',
      icon: AppIcons.problems,
      iconBg: const Color(0xFFFFF1E5),
      iconColor: const Color(0xFFEA580C),
      status: const AuthoringSectionStatus(completed: 0, total: 0),
      collapsible: false,
      expanded: true,
      onToggle: () {},
      child: child,
    );
  }

  static Widget _paragraphs(List<String> blocks) {
    final List<String> parts = <String>[
      for (final String block in blocks)
        ...block
            .split(RegExp(r'\n\s*\n'))
            .map((String part) => part.trim())
            .where((String part) => part.isNotEmpty),
    ];
    if (parts.isEmpty) return _bodyText('—');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var i = 0; i < parts.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 12),
          _bodyText(parts[i]),
        ],
      ],
    );
  }

  static Widget _bodyText(String body) {
    return Text(
      body,
      style: const TextStyle(
        fontSize: 14,
        height: 1.55,
        color: Color(0xFF1E293B),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  static Widget _chip(IconData icon, String label) {
    final String text = label.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  static Widget _detail(IconData icon, String label, String value) {
    final String text = value.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 20, child: Icon(icon, size: 16, color: const Color(0xFF64748B))),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
