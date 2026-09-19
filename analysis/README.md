# Hackz Analysis Service

Small **Node.js + TypeScript** integration service for originality / AI-writing providers (Turnitin Core API first).

Normal Hackz traffic remains:

`Tenant Auth → Flutter → Tenant Firestore/Storage`

This service is:

`Tenant Auth (College Admin) → Analysis Service → Provider API`

Credentials live in **Google Cloud Secret Manager** (Control Plane project by default). Flutter never receives secret values after save.

## Endpoints

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/save-provider-credentials` | Tenant CADM Bearer token | Store secrets + test + write public config |
| POST | `/test-connection` | Tenant CADM Bearer token | Test stored or inline credentials |
| POST | `/clear-provider-credentials` | Tenant CADM Bearer token | Delete secret + reset public config |
| POST | `/webhooks/turnitin` | Provider webhook (configure in Turnitin admin) | Async status updates |

Public (non-secret) provider state is written to tenant Firestore `hkzAnalysisProviderConfig/{organisationId}` using Admin SDK.

## Local development

```bash
cd analysis
cp .env.example .env
npm install
npm test
npm run serve
```

Set Control Plane `hkzAnalysisConfig/hackz.invokeUrl` to `http://localhost:8788` (production: Cloud Run URL).

## IAM (Analysis runtime service account)

Minimum permissions on **Control Plane** project:

- `secretmanager.admin` or scoped secret accessor + creator on `hackz-analysis-*` secrets
- Firestore/Datastore access to read `hkzTenants`
- Firebase Admin ability to verify tenant ID tokens and write tenant Firestore (same pattern as provisioning identity on college projects)

College grants are **not** required for analysis credentials — secrets are Hackz-platform scoped per organisation id.

## Turnitin college inputs

College Turnitin administrator provides:

1. **TCA API base URL** for the institution (region-specific, e.g. `https://app-us.turnitin.com/api/v1`)
2. **API key secret** from Turnitin Administrator → Integrations → Generate TCA Scope → Create key (copy once)
3. **Integration name** — use `Hackz` (not Live/Test)
4. **Integration version** — Hackz app version (defaults to `1.0.2` in service env)
5. Configure Turnitin **webhook URL** (when submissions are enabled) → `https://<analysis-service>/webhooks/turnitin`

Similarity and optional AI-writing capabilities are discovered from `GET /features` when licensed; otherwise Hackz exposes similarity only.
