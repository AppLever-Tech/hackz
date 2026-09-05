# Stage 7 — Tenant Firebase business data access

Organisation business data uses **`TenantContext → HackzFirebase.current → Tenant Firebase`**. Isolation is the Firebase project, not `tenantId` on models. Control Plane stays for registry, SysAdmin whitelist, App Metadata, and the organisation onboarding catalog.

Caches clear on every `HackzFirebase.bind` via `TenantSessionHooks` → `TenantBusinessCaches`. Constructor-captured Firestore is not used; services resolve `_db` through a getter.

Live two-tenant verification (Tenant A vs Tenant B login, listeners after switch, SysAdmin open-organisation) requires two registered tenant projects and is not covered by unit tests.

| Module | Firebase access points | Tenant Firebase | Isolation |
| --- | --- | --- | --- |
| **Users** | `FirestoreUtils` hkzUsers / invite codes / auth mirror; `UserService`; `UserPhotoService`; `user_workspace_loader`; `manage_users_screen`; `user_import_handler`; `evaluator_catalog_service`; `auth_status_resolver` (org users) | `HackzFirebase.current` after connect / `enterAsPlatformAdmin`. SysAdmin CADM create uses `TenantFirebase.runAsOrganisation` without switching Auth. Platform console peeks use `withOrganisationFirestore`. | Named tenant apps (`tenant-{id}`). Caches reset on bind. Phone lookup is tenant Auth + tenant `hkzUsers`. |
| **Problems** | `ProblemQueryService`; `problem_utils` (Firestore + Storage); `problem_workspace_loader`; `problems_import_handler`; `problem_authoring_workspace` | `HackzFirebase.current` getter | Same project as bound tenant; no Control Plane writes |
| **Teams** | `TeamService`; `TeamsWorkspaceService`; `coordinator_team_registration_service`; `team_workspace_loader`; `team_change_request_service`; `TeamMemberDashboardService` | `HackzFirebase.current` getter (dashboard no longer captures Firestore at construct) | `TeamsWorkspaceService` cache cleared on tenant rebind |
| **Ideas** | `IdeaQueryService`; `idea_workspace_loader`; `idea_event_participation_loader`; dashboards | `HackzFirebase.current` | Queries/writes/listeners go to bound tenant |
| **Events** | `ideathon_*` services; `EventPaymentsService` → `IdeathonPaymentService`; create ideathon coordinator queries | `HackzFirebase.current` | Participations, payments, judges on the same tenant project |
| **Payments** | `DepartmentPaymentsService`; `payment_workspace_loader`; `ideathon_payment_service`; `FirestoreUtils` payment helpers | `HackzFirebase.current` | Payment cache included in `TenantBusinessCaches.clear` |
| **Evaluation** | `JudgeDashboardService`; `JudgeEvaluationService`; assignment / aggregation / ranking / results; `evaluate_idea_dialog` | `HackzFirebase.current` getter; batches/transactions on `_db` | Judge evaluation cache cleared on rebind |
| **Leaderboard / Winners / Reports** | Ranking engine is in-memory over ideas/payments/problems already loaded from tenant services; ideathon/event tabs use those loaders | No extra Firebase client | Data set is whatever the tenant query returned |
| **Remaining org data** | Attachments, domains, org settings, departments, requests, coordinators | `HackzFirebase.current` | Org settings cache cleared on rebind. Onboarding mirrors `hkzOrganizations` (+ settings seed) into the tenant project so Manage College works after Open organisation. |
| **Platform (unchanged)** | `TenantRegistry`; `ApprovedTenantFirebase`; SysAdmin whitelist; `AppMetadataService`; `SysAdminDashboardService` overview | `HackzFirebase.controlPlane` | Opening an organisation does not feed tenant rows into platform analytics |

SysAdmin Auth remains Control Plane Auth (`sessionAuth`). Opening an organisation rebinds **data** only (`notifySession: false`) and bumps `tenantGeneration` so dashboards resubscribe.
