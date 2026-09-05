# Phase 10 — Final tenant reference & isolation audit

This is the last multi-tenancy implementation phase. Isolation is **one Firebase project per organisation**, routed as:

`Organisation Code → TenantResolver → TenantContext → HackzFirebase.current`

There is no `tenantId` on business models. Control Plane and tenant stay separate. No new tenancy abstraction.

Live two-tenant verification (login on A vs B, SysAdmin Open organisation A then B) still requires two registered tenant projects.

## Result

No live-path Firebase access used `FirebaseAuth.instance` / `FirebaseFirestore.instance` / `FirebaseStorage.instance`. Feature modules already resolve through getters on `HackzFirebase.current` or an explicit Control Plane handle. **No production routing change was required.**

Unused leftover screens (`EditOrgScreen`, `OrganizationManagementCard`) still call `FirestoreUtils` without a tenant database argument. They are not on the Organisations console path and were left unchanged.

## Isolation guarantees already in place

| Concern | Mechanism |
| --- | --- |
| Tenant A vs Tenant B | Named apps `tenant-{tenantId}`; `HackzFirebase.bind` replaces `current`; `runWithCurrent` restores the previous bind |
| No Control Plane fallback for org data | Getters use `HackzFirebase.current`; org Storage is guarded by `assertOrganisationStorage` |
| Cached repositories | Services use `_db` **getters**, not constructor-captured Firestore/Storage |
| Listeners after switch | `AuthGate` resubscribes on `generation`; dashboards rebuild on `tenantGeneration`; live `.snapshots()` helpers are unused in UI |
| Storage refs | Resolved per call via `HackzFirebase.current.storage.ref(...)` |
| Caches | `TenantSessionHooks` → `TenantBusinessCaches.clear` on every bind |
| Logout / login | `TenantFirebase.releaseSession` signs out `sessionAuth`, clears OTP challenge, rebinds Control Plane |
| SysAdmin Open organisation | `enterAsPlatformAdmin` rebinds **data** only (`notifySession: false`); Auth stays Control Plane |
| Browser / app restart | `AuthGate` restores last org code or platform-admin flag, then listens to `sessionAuth` |
| OTP across tenants | `PhoneAuthChallenge.clear` on bind / disconnect / logout |

## Control Plane

Leave these on `HackzFirebase.controlPlane` (or `sessionAuth` while `isPlatformAdminSession`).

| Access point | Role |
| --- | --- |
| `FirebaseBootstrap` | Default `Firebase.initializeApp` — Control Plane app only |
| `HackzFirebase.bindControlPlane` | Holds the platform app |
| `TenantRegistry` (`hkzTenants`) | Organisation code routing |
| `ApprovedTenantFirebase` (`hkzApprovedFirebaseProjects`) | Approved workspace catalog |
| `OrganisationOnboardingService` | College catalog on Control Plane; mirrors org doc into tenant via `runAsOrganisation` / `withOrganisationFirestore` |
| `TenantWorkspaceValidator` / `TenantFirebase.probe` | Probe a workspace **without** binding `current` |
| SysAdmin whitelist + `ensureSysAdminUserFromWhitelist` | Control Plane Auth + `hkzSysAdminWhitelist` / SysAdmin `hkzUsers` |
| `AuthStatusResolver._resolvePlatformAdmin` | SysAdmin profile on Control Plane Firestore |
| `AppMetadataService` | Platform About / legal / app info |
| `SysAdminDashboardService` | Platform analytics from Control Plane collections |
| Create/edit organisation catalog (`create_org_screen`) | `upsertOrganization(..., database: controlPlane)` |
| Delete organisation from onboarding card | Control Plane `hkzOrganizations` + registry inactivate |
| `HackzFirebase.sessionAuth` (SysAdmin) | Control Plane Auth even when `current` is a tenant |
| Feedback while SysAdmin is on the platform console | `HackzFirebase.current` is Control Plane in that session |

## Tenant

Must use the active organisation: `HackzFirebase.current` after `TenantFirebase.connect` / `enterAsPlatformAdmin`, or `runAsOrganisation` / `withOrganisationFirestore` for a one-shot platform peek/write.

| Module | Access points | Routing |
| --- | --- | --- |
| Auth (org users) | `AuthUtils._auth`, OTP, `sign_in_screen` tenant sign-out | `current.auth` after connect |
| Users | `FirestoreUtils` hkzUsers / invite / auth mirror; `UserService`; `UserPhotoService`; loaders; `manage_users_screen`; imports; `evaluator_catalog_service` | `current` getter. CADM create from onboarding: `runAsOrganisation` |
| Problems | `ProblemQueryService`; `problem_utils`; loaders; import; authoring | `current` (Storage guarded) |
| Teams | `TeamService`; `TeamsWorkspaceService`; coordinator registration; loaders; team-change requests; team-member dashboard | `current` getter |
| Ideas | `IdeaQueryService`; loaders; participation loader; dashboards | `current` |
| Events | `ideathon_*` services; `EventPaymentsService` → `IdeathonPaymentService`; create-ideathon queries | `current` |
| Payments | `DepartmentPaymentsService`; `payment_workspace_loader`; payment dialog attachments | `current` |
| Evaluation | Judge dashboard/evaluation; assignments; aggregation; ranking; results; evaluate dialog | `current` getter; optional `_dbOverride` unused in production |
| Leaderboard / winners / reports | In-memory over tenant-loaded ideas/events | No extra Firebase client |
| Org settings / domains / departments / requests | `OrgSettingsService`; `DomainService`; `FirestoreUtils` departments; `WorkflowRequestService` | `current`; org-settings cache cleared on rebind |
| Attachments / photos | `AttachmentService`; loaders; `UserPhotoService`; `OrgPhotoService` | `current.storage`; org files require `assertOrganisationStorage` |
| Dashboards (CADM / DADM / COO / JUD / TMEM) | Role services + `FirestoreUtils` | `current`; caches in `TenantBusinessCaches` |
| SysAdmin inside an organisation | Manage College / problems / ideas / org settings | `enterAsPlatformAdmin` then `current` |
| Platform peeks of one college | `OrgManagementService.loadOperationalData` | `withOrganisationFirestore` when `tenantId` is known |

## Not a Firebase client

Models import `cloud_firestore` only for `Timestamp` / `FieldValue` (`UserModel`, `ProblemModel`, `IdeaModel`, `TeamModel`, `PaymentModel`, `ScoreModel`, `IdeathonModel`, attachments, assignments, `TenantRecord`, etc.). `DefaultMetadataSeed` builds payloads; writes go through `AppMetadataService` (Control Plane). Leaderboard/event report widgets have no Firebase import.

## Intentionally unused (not modified)

| File | Notes |
| --- | --- |
| `edit_org_screen.dart` | Stream of CADM users via `FirestoreUtils` default (`current`). Not referenced. |
| `organization_management_card.dart` / grid | `deleteUser` / `deleteOrganization` on `current`. Not on the onboarding console. |
| `FirestoreUtils.watchPendingUsers` | `.snapshots()` on `current`; no callers. |
| `RoleDashboardDataView` | `fetchDashboardStats`; no callers. |

## End state

One Hackz codebase + one Hackz UI + Control Plane + isolated Firebase project per organisation.
