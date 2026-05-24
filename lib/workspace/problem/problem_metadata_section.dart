import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../utils/common_helpers.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Metadata', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _row(AppIcons.organizations, 'Organization', vm.organizationName),
        _row(AppIcons.departments, 'Department', p.departmentDisplayName),
        _row(AppIcons.info, 'Category', vm.category),
        _row(AppIcons.insights, 'Theme', vm.theme),
        if (vm.difficulty.isNotEmpty) _row(AppIcons.statusUnderReview, 'Difficulty', vm.difficulty),
        if (vm.priority.isNotEmpty) _row(AppIcons.pendingUsers, 'Priority', vm.priority),
        _row(
          AppIcons.adminProfile,
          'Created by',
          vm.createdByName,
          onTap: onOpenCreator,
        ),
        _row(AppIcons.clock, 'Created', formatDateTime(p.createdAt)),
        if (vm.tags.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: vm.tags
                .take(10)
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
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
                maxLines: 2,
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
