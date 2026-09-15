import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/hackz_firebase.dart';
import '../../../ideathons/models/ideathon_model.dart';
import '../../../organization/models/enums/organization_commercial_plan.dart';
import '../../../organization/models/organization_model.dart';
import '../../../organization/services/commercial_access.dart';
import '../../../organization/services/organisation_access.dart';
import '../../../user/models/enums/user_role.dart';
import '../../../user/models/enums/user_status.dart';
import '../../../../utils/firestore_utils.dart';
import '../org_admin_primary_menu.dart';

/// Opens an orgAdmin sidebar module from the setup panel.
class TenantSetupNavAction {
  const TenantSetupNavAction({
    required this.menuIndex,
    required this.label,
  });

  final int menuIndex;
  final String label;
}

/// One derived setup check — not persisted on any tenant document.
class TenantSetupCheckItem {
  const TenantSetupCheckItem({
    required this.label,
    required this.done,
    this.requiredForReady = true,
    this.detail,
    this.navAction,
  });

  final String label;
  final bool done;

  /// When false, shown for guidance only and does not block [TenantSetupReadiness.isReady].
  final bool requiredForReady;
  final String? detail;
  final TenantSetupNavAction? navAction;
}

/// Derived tenant counts for orgAdmin operational snapshot (same queries as readiness).
class TenantOperationalCounts {
  const TenantOperationalCounts({
    this.departments = 0,
    this.teams = 0,
    this.problems = 0,
    this.activeEvents = 0,
  });

  final int departments;
  final int teams;
  final int problems;
  final int activeEvents;
}

/// Tenant onboarding readiness computed from live Firestore data.
class TenantSetupReadiness {
  const TenantSetupReadiness({
    required this.items,
    required this.commercialPlan,
    this.organizationName = '',
    this.counts = const TenantOperationalCounts(),
    this.organisationAccessGranted = false,
  });

  final List<TenantSetupCheckItem> items;
  final OrganizationCommercialPlan commercialPlan;
  final String organizationName;
  final TenantOperationalCounts counts;
  final bool organisationAccessGranted;

  bool get isReady => TenantSetupReadinessLogic.isReady(items);

  List<TenantSetupCheckItem> get incompleteRequired =>
      items.where((TenantSetupCheckItem i) => i.requiredForReady && !i.done).toList(growable: false);
}

abstract final class TenantSetupReadinessLogic {
  TenantSetupReadinessLogic._();

  static bool isReady(List<TenantSetupCheckItem> items) {
    for (final TenantSetupCheckItem item in items) {
      if (item.requiredForReady && !item.done) return false;
    }
    return true;
  }
}

/// Loads orgAdmin tenant setup status from existing collections (no setup flags).
abstract final class TenantSetupReadinessService {
  TenantSetupReadinessService._();

  static Future<TenantSetupReadiness> load(String orgId) async {
    final String id = orgId.trim();
    if (id.isEmpty) {
      return const TenantSetupReadiness(
        items: <TenantSetupCheckItem>[
          TenantSetupCheckItem(label: 'Organisation', done: false, detail: 'Missing organisation id.'),
        ],
        commercialPlan: OrganizationCommercialPlan.perIdea,
      );
    }

    final FirebaseFirestore db = HackzFirebase.current.firestore;
    final OrganizationModel? org = await OrganisationAccess.fetch(id);
    final OrganizationCommercialPlan plan = CommercialAccess.planOf(org);
    final bool orgAccessGranted = org != null && OrganisationAccess.isGranted(org);

    final List<QuerySnapshot<Map<String, dynamic>>> snaps =
        await Future.wait<QuerySnapshot<Map<String, dynamic>>>(<Future<QuerySnapshot<Map<String, dynamic>>>>[
      db.collection(FirestoreUtils.hkzUsers).where('orgId', isEqualTo: id).get(),
      db.collection(FirestoreUtils.hkzDepartments).where('orgId', isEqualTo: id).get(),
      db.collection(FirestoreUtils.hkzProblems).where('orgId', isEqualTo: id).get(),
      db.collection(FirestoreUtils.hkzTeams).where('orgId', isEqualTo: id).get(),
      db.collection(FirestoreUtils.hkzIdeathons).where('orgId', isEqualTo: id).get(),
    ]);

    final QuerySnapshot<Map<String, dynamic>> usersSnap = snaps[0];
    final int departmentCount = snaps[1].docs.length;
    final int problemCount = snaps[2].docs.length;
    final int teamCount = snaps[3].docs.length;
    final bool hasTeams = teamCount > 0;

    bool collegeAdminActive = false;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in usersSnap.docs) {
      final Map<String, dynamic> data = doc.data();
      if ((data['role'] as String?)?.trim() != UserRole.collegeAdmin.code) continue;
      if (UserStatus.fromRaw((data['status'] as String?) ?? '') == UserStatus.active) {
        collegeAdminActive = true;
        break;
      }
    }

    bool eventOpenForTeamLeaders = false;
    int activeEventCount = 0;
    String? eventCommercialDetail;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snaps[4].docs) {
      final IdeathonModel event = IdeathonModel.fromMap(doc.id, doc.data());
      if (!event.isAcceptingSubmissions) continue;
      if (!CommercialAccess.allowsEventParticipation(event)) {
        if (plan == OrganizationCommercialPlan.perEvent && !event.commercialAccess.isEnabled) {
          eventCommercialDetail ??=
              'At least one scheduled event is waiting for Control Plane commercial activation (PER_EVENT).';
        }
        continue;
      }
      activeEventCount++;
      eventOpenForTeamLeaders = true;
    }

    final List<TenantSetupCheckItem> items = <TenantSetupCheckItem>[
      TenantSetupCheckItem(
        label: 'Organisation commercially active',
        done: orgAccessGranted,
        detail: orgAccessGranted
            ? null
            : 'Organisation must be ACTIVE (and within contract dates for ANNUAL) on the Control Plane.',
      ),
      TenantSetupCheckItem(
        label: 'College Admin provisioned',
        done: collegeAdminActive,
        detail: collegeAdminActive ? null : 'An active College Admin user is required in this tenant.',
      ),
      TenantSetupCheckItem(
        label: 'Departments configured',
        done: departmentCount > 0,
        detail: departmentCount > 0 ? null : 'Add at least one department (Manage College).',
        navAction: departmentCount > 0
            ? null
            : const TenantSetupNavAction(
                menuIndex: OrgAdminPrimaryMenu.manageCollege,
                label: 'Manage College',
              ),
      ),
      TenantSetupCheckItem(
        label: 'Problem statements available',
        done: problemCount > 0,
        detail: problemCount > 0 ? null : 'Import or create problems (Problem Statements).',
        navAction: problemCount > 0
            ? null
            : const TenantSetupNavAction(
                menuIndex: OrgAdminPrimaryMenu.problemStatements,
                label: 'Problem Statements',
              ),
      ),
      TenantSetupCheckItem(
        label: 'Teams registered',
        done: hasTeams,
        requiredForReady: false,
        detail: hasTeams ? null : 'Import teams when ready via team CSV (Manage College).',
        navAction: hasTeams
            ? null
            : const TenantSetupNavAction(
                menuIndex: OrgAdminPrimaryMenu.manageCollege,
                label: 'Manage College',
              ),
      ),
      TenantSetupCheckItem(
        label: 'Event open for team submissions',
        done: eventOpenForTeamLeaders,
        detail: eventOpenForTeamLeaders
            ? null
            : (eventCommercialDetail ??
                'Create/configure an event (Events) with a future submission window and commercial access.'),
        navAction: eventOpenForTeamLeaders
            ? null
            : const TenantSetupNavAction(
                menuIndex: OrgAdminPrimaryMenu.events,
                label: 'Events',
              ),
      ),
    ];

    if (plan == OrganizationCommercialPlan.perIdea) {
      items.add(
        const TenantSetupCheckItem(
          label: 'PER_IDEA: orgAdmin validates idea payments',
          done: true,
          requiredForReady: false,
          detail: 'After team leaders submit ideas and pay, use Payment Verification to approve eligibility.',
        ),
      );
    }

    return TenantSetupReadiness(
      items: items,
      commercialPlan: plan,
      organizationName: org?.name.trim() ?? '',
      organisationAccessGranted: orgAccessGranted,
      counts: TenantOperationalCounts(
        departments: departmentCount,
        teams: teamCount,
        problems: problemCount,
        activeEvents: activeEventCount,
      ),
    );
  }
}
