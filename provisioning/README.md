# Hackz tenant provisioning

Small **Node.js + TypeScript** Firebase Admin job. It exists only because Control Plane Auth cannot sign a SysAdmin into a tenant Firebase project.

Normal Hackz traffic stays:

`Tenant Auth → Flutter → Tenant Firestore/Storage`

This job is:

`Hackz Control Plane → Provisioning Service → College Firebase`

It is not a Hackz business backend and not a path for problems, ideas, teams, events, payments, or evaluations. SysAdmin onboarding may invoke one privileged provision operation.

Production runs this same process on **Cloud Run** (scale to zero). SysAdmin does not start a local server when onboarding a college.

## Capability

`POST /provision-tenant-admin`

Creates the **first College Admin** on the tenant project:

1. Confirms the process can access the Control Plane Firebase project.
2. Resolves the organisation from Control Plane `hkzTenants` (not from caller-supplied config).
3. Initializes Admin SDK for that tenant project.
4. Confirms the college has granted this provisioning identity access (Firebase Auth Admin).
5. Creates the tenant Auth user (phone + email). No Storage.
6. Creates tenant `hkzUsers/{uid}` with the CADM fields Hackz already uses to sign in.
7. Sets Control Plane `initialAdminConfigured` only. **No CADM document on Control Plane.**

If several organisations share one Firebase project (hosted workspace), pass `organisationId`.

The request must include a Control Plane **SysAdmin** Firebase ID token (`Authorization: Bearer …`). Cloud Run reachability is not anonymous Hackz access: without that token the handler returns `UNAUTHORIZED`.

## College authorization

The college must add the Hackz provisioning service account on **their** Firebase project. Until that IAM grant exists, the job returns `PROVISIONING_NOT_AUTHORIZED`.

Do not put a tenant service-account JSON in the Flutter app. Do not collect college service-account keys.

The college grants the **same** provisioning identity on **their** Google Cloud project (IAM), whether the job runs locally or on Cloud Run:

`hackz-provisioning@hackz-a17b6.iam.gserviceaccount.com`

Minimum roles:

- `roles/firebaseauth.admin` — Firebase Authentication Admin
- `roles/datastore.user` — Cloud Datastore User (Firestore). Do **not** grant Storage, Owner, or Editor.

Hackz onboarding has a **College Controls Authorization** step. Validate in the UI confirms the project, Authentication, and Firestore are reachable. This job can re-check the provisioning identity itself:

```bash
npx tsx src/cli.ts --validate-authorization \
  --tenant-project-id college-one \
  --organisation-id <hkzOrganizations-id>
```

That command does not create users or business data. It writes only Control Plane `provisioningAuthorization` (`verified` or `revoked`).

## Local development

```bash
cd provisioning
cp .env.example .env
# Set HACKZ_CONTROL_PLANE_PROJECT_ID and GOOGLE_APPLICATION_CREDENTIALS
npm install
npm test
npm run serve
```

Local listen address: `http://localhost:8787` (Android emulator: `http://10.0.2.2:8787`).

Set Control Plane `hkzProvisioningConfig/hackz.invokeUrl` to that URL while developing. Production uses the Cloud Run URL in the same field — do not add a second config document.

CLI (same provisioner, no HTTP):

```bash
npx tsx src/cli.ts \
  --tenant-project-id college-one \
  --organisation-id <hkzOrganizations-id> \
  --first-name Asha \
  --last-name Nair \
  --email asha@college.edu \
  --phone 9876543210
```

Prints JSON. Exit `0` on success, `1` on failure.

## Production (Cloud Run) — one-time Hackz platform setup

Deploy **once** for the platform. Do not deploy per college.

Reuse the existing `hackz-provisioning` service account. Cloud Run uses that identity via Application Default Credentials. The container image must **not** include `.env` or `hackz-provisioning-sa.json`.

Prerequisites (deployer, once):

- `gcloud` authenticated to project `hackz-a17b6`
- permission to deploy Cloud Run and to act as `hackz-provisioning@hackz-a17b6.iam.gserviceaccount.com` (`roles/iam.serviceAccountUser` on that account)
- that service account already has Firebase Authentication Admin + Cloud Datastore User on the Control Plane project (same as local provisioning)

Region below is `asia-south1`. Change it only if the Control Plane is elsewhere.

Cloud Run `--source` builds with the Compute Engine default service account. Grant it Cloud Run Builder once, and allow the deployer to act as that account and the provisioning runtime account:

```bash
gcloud projects add-iam-policy-binding hackz-a17b6 \
  --member="serviceAccount:439535394674-compute@developer.gserviceaccount.com" \
  --role="roles/run.builder"

gcloud iam service-accounts add-iam-policy-binding \
  439535394674-compute@developer.gserviceaccount.com \
  --project=hackz-a17b6 \
  --member="user:YOUR_GOOGLE_ACCOUNT" \
  --role="roles/iam.serviceAccountUser"

gcloud iam service-accounts add-iam-policy-binding \
  hackz-provisioning@hackz-a17b6.iam.gserviceaccount.com \
  --project=hackz-a17b6 \
  --member="user:YOUR_GOOGLE_ACCOUNT" \
  --role="roles/iam.serviceAccountUser"
```

IAM can take a couple of minutes to propagate. This is platform setup, not a per-college step.

### 1. Build the service

From `provisioning/`:

```bash
cd provisioning
npm ci
npm test
npm run build
```

Cloud Run also builds the image from `Dockerfile` during deploy (`--source .`). The local `npm run build` step confirms TypeScript compiles before you ship.

### 2. Deploy to Cloud Run

```bash
cd provisioning
gcloud run deploy hackz-tenant-provisioning \
  --project hackz-a17b6 \
  --region asia-south1 \
  --source . \
  --service-account hackz-provisioning@hackz-a17b6.iam.gserviceaccount.com \
  --set-env-vars HACKZ_CONTROL_PLANE_PROJECT_ID=hackz-a17b6 \
  --allow-unauthenticated \
  --min-instances 0 \
  --max-instances 2 \
  --memory 512Mi \
  --cpu 1 \
  --timeout 120 \
  --concurrency 8
```

`--min-instances 0` scales to zero when unused and starts the service on the next SysAdmin invoke.

`--allow-unauthenticated` only lets the URL accept HTTPS. The handler still requires a Control Plane SysAdmin ID token. Flutter cannot present a Google Cloud IAM token without exposing privileged credentials.

### 3. Obtain the Cloud Run URL

```bash
gcloud run services describe hackz-tenant-provisioning \
  --project hackz-a17b6 \
  --region asia-south1 \
  --format="value(status.url)"
```

Example shape: `https://hackz-tenant-provisioning-xxxxx-xx.asia-south1.run.app`

### 4. Configure `hkzProvisioningConfig/hackz.invokeUrl`

On Control Plane project `hackz-a17b6`, Firestore document `hkzProvisioningConfig/hackz`:

- Set `invokeUrl` to the Cloud Run URL from step 3 (no trailing slash, no `/provision-tenant-admin` path)
- Leave `serviceAccountEmail` as `hackz-provisioning@hackz-a17b6.iam.gserviceaccount.com`

Firebase Console: Firestore → `hkzProvisioningConfig` → `hackz` → field `invokeUrl`.

For local development later, set the same field back to `http://localhost:8787` (or `http://10.0.2.2:8787` on the Android emulator) and run `npm run serve`.

### 5. Test provisioning from SysAdmin onboarding

1. Sign in as Control Plane SysAdmin.
2. Register Organisation → Connect Tenant Firebase → Validate Authorization → Enter College Admin → Activate.
3. Confirm the college has already granted `hackz-provisioning@hackz-a17b6.iam.gserviceaccount.com` Authentication Admin + Datastore User.
4. Activate should call `POST {invokeUrl}/provision-tenant-admin` on Cloud Run (no local `npm run serve`).
5. Success creates tenant Auth + `hkzUsers` only. Failure returns the existing codes (`TENANT_NOT_FOUND`, `PROVISIONING_NOT_AUTHORIZED`, `ADMIN_EXISTS`, `WRITE_FAILED`, …) and does not mark the organisation fully active.

The first request after idle may take longer (cold start). That is expected with scale-to-zero.

## What it will not do

- Organisation logos, admin photos, or any Storage
- Later users, departments, or business data
- Flutter login / RBAC changes
- Routing tenant traffic through this process
- Per-college Cloud Run deploys
- Collecting college service-account JSON keys
- Weakening tenant Firestore rules
