# Phase 0 — Firebase dependency inventory

Hackz today is a **single Firebase project** (`hackz-a17b6`). All organisations share one Auth, one Firestore, and one Storage bucket. Isolation is `orgId` on documents, not project boundaries.

Phase 1 wires access through `HackzFirebase.current`. Phase 2 adds the Control Plane tenant registry (`hkzTenants`) on this same project. College business data is unchanged.

## Configuration / initialization (single-project assumptions)

| Location | Role | Classification |
| --- | --- | --- |
| `lib/core/firebase/firebase_bootstrap.dart` | Hard-coded `FirebaseOptions` + `Firebase.initializeApp` (web + Android only); binds Control Plane + current | **Shared/Application** init; also **Control Plane** bind |
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

SysAdmin whitelist (`hkzSysAdminWhitelist`) is looked up in the **same** Firestore. Control Plane also owns `hkzTenants`. Organisation-code login is not implemented yet; `TenantResolver.resolveByOrganisationCode` is the lookup API.

## Central Firestore helper

`lib/utils/firestore_utils.dart` — `HackzFirebase.current.firestore` and all `hkz*` **business** collection names. Used across features. **Tenant Data** except collections listed as Control Plane / Shared below. Tenant registry is **not** accessed through this helper.

## Firestore collections (same project today)

### Control Plane (tenant registry / onboarding — currently co-located)

| Collection | Notes |
| --- | --- |
| `hkzTenants` | Phase 2 registry: `tenantId`, `organisationCode` (`HKZ-XXXXXX`), `organisationName`, `firebaseProjectId`, `status`, `createdAt`. Document id = organisation code. |
| `hkzOrganizations` | Org records + `settings/org_settings` subcollection (**tenant business**, not registry fields) |
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

## Feature services using Firestore

Direct access goes through `HackzFirebase.current.firestore` (tenant) or `HackzFirebase.controlPlane.firestore` (registry):

- Control Plane: `tenant_registry`
- Team, Idea, Problems, Ideathons, Evaluations, Payment, Requests, User, Dashboards, Imports, Org settings, Attachments, App metadata, Domain, Feedback: **Tenant / Shared** via `HackzFirebase.current`

Models import `cloud_firestore` only for `Timestamp` / map parsing — **not** live Firebase access.

## Firebase Storage (`HackzFirebase.current.storage`)

| Location | Classification |
| --- | --- |
| `attachment_service.dart` | **Tenant Data** |
| `attachment_workspace_loader.dart` | **Tenant Data** |
| `user_photo_service.dart` | **Tenant Data** |
| `org_photo_service.dart` | **Tenant Data** |
| `problem_utils.dart` | **Tenant Data** |

## Architecture note

- Do **not** add `tenantId` to Problem, Idea, Team, Event, Payment, Evaluation, User, Organization, or other business models.
- Tenant isolation = Firebase project (Auth + Firestore + Storage).
- Control Plane catalog (`ApprovedTenantFirebase`) is the only source of tenant Firebase options. Never trust user-supplied project config.
- `TenantResolver.controlPlane` binds the Hackz project. `TenantResolver.resolveByOrganisationCode` reads `hkzTenants` for exactly one active, approved tenant. Feature services keep using `HackzFirebase.current`.
- Organisation codes are generated as `HKZ-XXXXXX` (no `0/O`/`1/I`), globally unique, case-insensitive, stable, not derived from the organisation name.
