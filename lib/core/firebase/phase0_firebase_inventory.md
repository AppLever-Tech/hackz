# Phase 0 — Firebase dependency inventory

Hackz today is a **single Firebase project** (`hackz-a17b6`). All organisations share one Auth, one Firestore, and one Storage bucket. Isolation is `orgId` on documents, not project boundaries.

Phase 1 wires access through `HackzFirebase.current` without changing that runtime. Phase 2 (not implemented) is the Control Plane + Tenant Registry that can bind a different Firebase app.

## Configuration / initialization (single-project assumptions)

| Location | Role | Classification |
| --- | --- | --- |
| `lib/core/firebase/firebase_bootstrap.dart` | Hard-coded `FirebaseOptions` + `Firebase.initializeApp` (web + Android only) | **Shared/Application** init; options are the current tenant project |
| `lib/main.dart` | Calls `FirebaseBootstrap.initialize()` then `AuthGate` | **Shared/Application** |
| `.firebaserc` | `"default": "hackz-a17b6"` | **Shared/Application** (CLI/hosting) |
| `firebase.json` | Hosting site `hackze`; Firestore indexes | **Shared/Application** |
| `google-services.json`, `android/app/google-services.json` | Android client for `hackz-a17b6` | **Tenant Data** project (current) |
| `pubspec.yaml` | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` | **Shared/Application** |
| `firestore.indexes.json` | Composite indexes for the one Firestore | **Tenant Data** (current) |

There is no `firebase_options.dart` from FlutterFire CLI; options live in `FirebaseBootstrap`. iOS / macOS / Windows / Linux are explicitly unsupported.

## Authentication / login

| Location | Access | Classification |
| --- | --- | --- |
| `lib/features/auth/screens/auth_gate.dart` | `authStateChanges`, `signOut` | **Tenant Data** Auth |
| `lib/features/auth/services/auth_utils.dart` | Phone OTP (`verifyPhoneNumber` / web `signInWithPhoneNumber`) | **Tenant Data** Auth |
| `lib/features/auth/screens/sign_in_screen.dart` | `signOut` | **Tenant Data** Auth |
| `lib/features/auth/screens/sign_up_screen.dart` | `signOut` | **Tenant Data** Auth |
| `lib/features/auth/services/auth_status_resolver.dart` | Uses Auth `User` + Firestore profile | **Tenant Data** |
| `lib/features/dashboard/chrome/dashboard_page_template.dart` | Logout `signOut` | **Tenant Data** Auth |
| `lib/features/payment/widgets/payment_dialog.dart` | `currentUser?.uid` | **Tenant Data** Auth |

SysAdmin whitelist (`hkzSysAdminWhitelist`) is looked up in the **same** Firestore. Future Control Plane will own whitelist / tenant registry; today it is co-located.

## Central Firestore helper

`lib/utils/firestore_utils.dart` — `FirebaseFirestore.instance` and all `hkz*` collection names. Used across features. **Tenant Data** except collections listed as Control Plane / Shared below.

## Firestore collections (same project today)

### Control Plane (future tenant registry / onboarding — currently co-located)

| Collection | Notes |
| --- | --- |
| `hkzOrganizations` | Org records + `settings/org_settings` subcollection |
| `hkzSysAdminWhitelist` | First-time SysAdmin bootstrap |
| `hkzDomains` | Org/department domain catalog (`DomainService`) |

### Shared / Application (product-global, not org workflow)

| Collection | Notes |
| --- | --- |
| `hkzAppMetadata` | About, terms, privacy, app info (`AppMetadataService`) |
| `hkzFeedback` | Product feedback (has `orgId` but is app-level tooling) |

### Tenant Data (organisation-specific)

`hkzUsers`, `hkzUserAuthMirror`, `hkzTeams`, `hkzIdeas`, `hkzProblems`, `hkzPayments`, `hkzScores`, `hkzDepartments`, `hkzInviteCodes`, `hkzCounters`, `hkzAttachments`, `hkzRequests`, `hkzEvaluationGroups`, `hkzEvaluationAssignments`, `hkzIdeathons`, `hkzIdeathonParticipations`.

Storage paths for attachments, user photos, org logos, and problem files are **Tenant Data**.

## Feature services using `FirebaseFirestore.instance`

Direct default-instance access (Phase 1 routes these through `HackzFirebase.current.firestore`):

- Team: `team_service`, `teams_workspace_service`, `coordinator_team_registration_service`, `team_workspace_loader`
- Idea: `idea_query_service`, `idea_workspace_loader`, `idea_event_participation_loader`
- Problems: `problem_query_service`, `problem_utils`, `problem_workspace_loader`, `problem_authoring_workspace`
- Ideathons: `ideathon_service`, `ideathon_query_service`, `ideathon_participation_service`, `ideathon_payment_service`, `ideathon_prototype_service`, `ideathon_evaluation_sync_service`, `ideathon_judge_assignment_service`, `ideathon_readiness_service`, `ideathon_details_loader`, `ideathon_workspace_loader`, `create_ideathon_workspace`
- Evaluations: `judge_evaluation_service`, `judge_dashboard_service`, `evaluation_aggregation_sync_service`, `evaluation_details_loader`, `evaluation_results_query_service`, `evaluation_ranking_service`, `evaluation_assignment_service`, `evaluator_catalog_service`, `evaluation_workspace_loader`, `evaluate_idea_dialog`
- Payment: `department_payments_service`, `payment_workspace_loader`
- Requests: `workflow_request_service`, `team_change_request_service`
- User: `manage_users_screen`, `user_workspace_loader`
- Dashboards: `sysadmin_dashboard_service`, `department_dashboard_service`, `coordinator_dashboard_service`, `coordinator_dashboard`, `team_member_dashboard_service`
- Imports: `user_import_handler`, `team_registration_import_handler`, `problems_import_handler`
- Org settings: `org_settings_service`
- Attachments: `attachment_service`, `attachment_workspace_loader`
- Other: `app_metadata_service`, `domain_service`, `hackz_feedback_service`

Models import `cloud_firestore` only for `Timestamp` / map parsing — **not** live Firebase access.

## Firebase Storage (`FirebaseStorage.instance`)

| Location | Classification |
| --- | --- |
| `attachment_service.dart` | **Tenant Data** |
| `attachment_workspace_loader.dart` | **Tenant Data** |
| `user_photo_service.dart` | **Tenant Data** |
| `org_photo_service.dart` | **Tenant Data** |
| `problem_utils.dart` | **Tenant Data** |

## Architecture note for later phases

- Do **not** add `tenantId` to Problem, Idea, Team, Event, Payment, Evaluation, User, or other business models.
- Tenant isolation = Firebase project (Auth + Firestore + Storage).
- `TenantResolver.bootstrap` is the Phase 2 hook: replace with Control Plane registry lookup, then `HackzFirebase.bind` on a named `FirebaseApp`.
- Feature services keep a single implementation; they read `HackzFirebase.current`.
