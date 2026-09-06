# Hackz tenant provisioning

Small **Node.js + TypeScript** Firebase Admin job. It exists only because Control Plane Auth cannot sign a SysAdmin into a tenant Firebase project.

Normal Hackz traffic stays:

`Tenant Auth → Flutter → Tenant Firestore/Storage`

This job is:

`Control Plane registry → Provisioning identity → College Firebase Auth + hkzUsers`

It is not a Hackz business backend and not a path for problems, ideas, teams, events, payments, or evaluations. SysAdmin onboarding may invoke one privileged provision operation.

## Capability

`provisionTenantAdmin(tenantProjectId, firstName, lastName, email, phone)`

Creates the **first College Admin** on the tenant project:

1. Confirms the process can access the Control Plane Firebase project.
2. Resolves the organisation from Control Plane `hkzTenants` (not from caller-supplied config).
3. Initializes Admin SDK for that tenant project.
4. Confirms the college has granted this provisioning identity access (Firebase Auth Admin).
5. Creates the tenant Auth user (phone + email). No Storage.
6. Creates tenant `hkzUsers/{uid}` with the CADM fields Hackz already uses to sign in.
7. Sets Control Plane `initialAdminConfigured` only. **No CADM document on Control Plane.**

If several organisations share one Firebase project (hosted workspace), pass `organisationId`.

## College authorization

The college must add the Hackz provisioning service account on **their** Firebase project (for example Firebase Admin / Authentication Admin + Cloud Datastore User). Until that IAM grant exists, the job returns `PROVISIONING_NOT_AUTHORIZED`.

Do not put a tenant service-account JSON in the Flutter app.

The college grants the provisioning identity on **their** Google Cloud project (IAM). Minimum roles:

- `roles/firebaseauth.admin` — Firebase Authentication Admin
- `roles/datastore.user` — Cloud Datastore User (Firestore). Do **not** grant Storage, Owner, or Editor.

Hackz onboarding has a **College Controls Authorization** step. Validate in the UI confirms the project, Authentication, and Firestore are reachable. This job can re-check the provisioning identity itself:

```bash
npx tsx src/cli.ts --validate-authorization \
  --tenant-project-id college-one \
  --organisation-id <hkzOrganizations-id>
```

That command does not create users or business data. It writes only Control Plane `provisioningAuthorization` (`verified` or `revoked`).

## Run

```bash
cd provisioning
cp .env.example .env
# Set HACKZ_CONTROL_PLANE_PROJECT_ID and GOOGLE_APPLICATION_CREDENTIALS
npm install
npm test
npx tsx src/cli.ts \
  --tenant-project-id college-one \
  --organisation-id <hkzOrganizations-id> \
  --first-name Asha \
  --last-name Nair \
  --email asha@college.edu \
  --phone 9876543210
```

Prints JSON. Exit `0` on success, `1` on failure.

SysAdmin onboarding invokes the same capability over one authenticated POST (`/provision-tenant-admin`) with a Control Plane ID token. It is not a business API.

```bash
npm run serve
```

Set `hkzProvisioningConfig/hackz.invokeUrl` on the Control Plane (for example `http://localhost:8787`).

## What it will not do

- Organisation logos, admin photos, or any Storage
- Later users, departments, or business data
- Flutter login / RBAC changes
- Routing tenant traffic through this process
