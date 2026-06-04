import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../utils/common_helpers.dart';
import 'problem_workspace.dart';

class ProblemMetadataSection extends StatelessWidget {
  const ProblemMetadataSection({
    super.key,
    required this.vm,
    this.onOpenCreator,
  });

  final ProblemWorkspaceViewModel vm;
  final VoidCallback? onOpenCreator;

  @override
  Widget build(BuildContext context) {
    final p = vm.problem;
    final String tagsText = vm.tags.isEmpty ? '' : vm.tags.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Other Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _row(AppIcons.orgType, 'Category', vm.category),
        _row(AppIcons.insights, 'Theme', vm.theme),
        _row(Icons.label_outline, 'Tags', tagsText),
        _row(AppIcons.organizations, 'Organization', vm.organizationName),
        _row(
          AppIcons.adminProfile,
          'Created by',
          vm.createdByName,
          onTap: onOpenCreator,
        ),
        _row(AppIcons.clock, 'Created', formatDateTime(p.createdAt)),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value, {VoidCallback? onTap}) {
    final String text = value.trim().isEmpty ? '—' : value.trim();
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
            child: InkWell(
              onTap: onTap,
              child: Text(
                text,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: onTap == null ? const Color(0xFF0F172A) : const Color(0xFF334155),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
