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
  });

  final String orgId;
  final String departmentCode;
  final String departmentName;

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
          return const Center(child: CircularProgressIndicator());
        }
        final String? departmentId = snapshot.data;
        if (departmentId == null || departmentId.isEmpty) {
          return const Center(
            child: Text(
              'Your department record was not found. Ask the college admin to create it first.',
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
        );
      },
    );
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
