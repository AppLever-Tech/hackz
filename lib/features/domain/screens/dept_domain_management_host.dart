import 'package:flutter/material.dart';

import '../models/domain_model.dart';
import '../services/domain_department_resolver.dart';
import '../services/domain_service.dart';
import 'domain_management_screen.dart';

/// Loads department Firestore id for dept-admin, then shows [DomainManagementScreen].
class DeptDomainManagementHost extends StatefulWidget {
  const DeptDomainManagementHost({
    super.key,
    required this.orgId,
    required this.departmentCode,
    required this.departmentName,
    this.compact = false,
  });

  final String orgId;
  final String departmentCode;
  final String departmentName;
  final bool compact;

  @override
  State<DeptDomainManagementHost> createState() => _DeptDomainManagementHostState();
}

class _DeptDomainManagementHostState extends State<DeptDomainManagementHost> {
  late Future<String?> _departmentIdFuture;

  @override
  void initState() {
    super.initState();
    _departmentIdFuture = DomainDepartmentResolver.departmentIdForCode(
      orgId: widget.orgId,
      departmentCode: widget.departmentCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _departmentIdFuture,
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _statusPane(const CircularProgressIndicator());
        }
        final String? departmentId = snapshot.data;
        if (departmentId == null || departmentId.isEmpty) {
          return _statusPane(
            const Text(
              'Your department record was not found. Ask the college admin to create it first.',
              textAlign: TextAlign.center,
            ),
          );
        }
        return DomainManagementScreen(
          orgId: widget.orgId,
          lockedDepartmentId: departmentId,
          lockedDepartmentCode: widget.departmentCode,
          lockedDepartmentName: widget.departmentName.trim().isEmpty
              ? widget.departmentCode
              : widget.departmentName,
          compact: widget.compact,
        );
      },
    );
  }

  Widget _statusPane(Widget child) {
    final Widget centered = Center(child: child);
    if (!widget.compact) return centered;
    return SizedBox(height: 240, width: double.infinity, child: centered);
  }
}

/// Prefetches domains for problem list / search enrichment.
abstract final class DomainLookupCache {
  DomainLookupCache._();

  static Future<Map<String, DomainModel>> loadOrgDomains(String orgId) async {
    final List<DomainModel> domains = await DomainService.listByOrg(orgId: orgId);
    return <String, DomainModel>{
      for (final DomainModel d in domains) d.domainId: d,
    };
  }
}
