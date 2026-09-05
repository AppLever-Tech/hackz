# Phase 8 — Tenant Storage isolation

Organisation files use **`TenantContext → HackzFirebase.current.storage → Tenant Firebase Storage`**. Paths and file names are unchanged. Isolation is the Storage bucket of the bound Firebase project, not `tenantId` on models or metadata.

`HackzFirebase.current.storage` is resolved per call (`FirebaseStorage.instanceFor(app:)`). Services use getters, not constructor-captured `Reference`s. `HackzFirebase.bind` / `runWithCurrent` replace `current`, so a tenant switch cannot keep writing to the previous bucket.

Live two-tenant verification (upload / read / delete on Tenant A vs Tenant B) requires two registered projects.

| Access point | Operations | Tenant Storage | Notes |
| --- | --- | --- | --- |
| `AttachmentService` | upload (`putData`/`putFile`), download URL, Firestore metadata | `HackzFirebase.current.storage` | Problems, ideas, payments, org logos require `assertOrganisationStorage`. Feedback may use Control Plane when SysAdmin is on the platform console. Soft-deactivate does not delete blobs (existing behaviour). |
| `attachment_workspace_loader` | `getDownloadURL` by `storagePath` | `current.storage` | Falls back to stored URL if the object is missing. |
| `UserPhotoService` | upload + download URL | `current.storage` | `users/{orgId}/{userId}/profile_*`. CADM photos during onboarding use `runAsOrganisation`. |
| `OrgPhotoService` | upload + download URL | `current.storage` | `orgs/{orgId}/logos/logo_*`. Platform console uploads only after a workspace is connected, via `runAsOrganisation`. Never writes logos to Control Plane for a remote tenant. |
| `ProblemUtils.uploadAttachments` | upload + download URL | `current.storage` | `problems/{problemNumber}/…`. Guarded. Prefer `AttachmentService` for new problem files. |
| Callers | Idea files (`TeamService`), payment screenshots (`payment_dialog`), problem authoring | `AttachmentService` | Same tenant bucket as the bound session. |
| Control Plane | None for organisation files | `HackzFirebase.controlPlane.storage` unused for business files | Workspace probe only checks that a bucket is configured; it does not bind `current`. |

Setup tenants (onboarding before Activate) can still receive files because `TenantResolver.workspaceByTenantId` allows setup|active workspaces for platform-admin `runAsOrganisation` / `withOrganisationFirestore`. Opening an organisation for the dashboard still requires an **active** tenant.
