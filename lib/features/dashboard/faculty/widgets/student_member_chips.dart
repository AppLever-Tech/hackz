import 'package:flutter/material.dart';

class StudentMemberChips extends StatelessWidget {
  const StudentMemberChips({
    super.key,
    required this.names,
  });

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) {
      return const Text('No team members assigned', style: TextStyle(color: Color(0xFF64748B)));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: names.map(_chip).toList(growable: false),
    );
  }

  Widget _chip(String name) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFFEDE9FE),
            child: Text(initials.isEmpty ? '?' : initials, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF6A38FF))),
          ),
          const SizedBox(width: 7),
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
        ],
      ),
    );
  }
}
