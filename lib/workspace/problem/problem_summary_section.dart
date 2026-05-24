import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import 'problem_workspace.dart';

class ProblemSummarySection extends StatelessWidget {
  const ProblemSummarySection({super.key, required this.vm});

  final ProblemWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final p = vm.problem;
    final String title = p.title.trim().isEmpty ? 'Untitled Problem' : p.title.trim();
    final String desc = p.description.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.15),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _chip(AppIcons.problems, p.problemNumber.trim().isEmpty ? p.problemId : p.problemNumber),
            _chip(AppIcons.departments, p.departmentDisplayName),
            _chip(p.isActive ? AppIcons.statusApproved : AppIcons.statusInactive, p.isActive ? 'Active' : 'Inactive'),
          ],
        ),
        if (desc.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            desc,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155), fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  static Widget _chip(IconData icon, String text) {
    final String value = text.trim().isEmpty ? '—' : text.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: const Color(0xFF57629A)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }
}
