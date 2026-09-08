import { createServer, type IncomingMessage, type ServerResponse } from 'node:http';
import { getAuth } from 'firebase-admin/auth';
import { ProvisionError } from './errors.js';
import { controlPlaneApp, controlPlaneFirestore } from './firebase-apps.js';
import { provisionTenantAdmin } from './provision-tenant-admin.js';

function listenPort(): number {
  for (const raw of [process.env.PORT, process.env.HACKZ_PROVISIONING_PORT]) {
    const value = Number(String(raw ?? '').trim());
    if (Number.isInteger(value) && value > 0 && value < 65536) return value;
  }
  return 8787;
}

const PORT = listenPort();
const CORS = (process.env.HACKZ_CORS_ORIGIN ?? '*').trim() || '*';

function send(res: ServerResponse, status: number, body: unknown): void {
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': CORS,
    'Access-Control-Allow-Headers': 'Authorization, Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  });
  res.end(JSON.stringify(body));
}

async function readJson(req: IncomingMessage): Promise<Record<string, unknown>> {
  const chunks: Buffer[] = [];
  for await (const chunk of req) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  const raw = Buffer.concat(chunks).toString('utf8').trim();
  if (raw.length === 0) return {};
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new ProvisionError('INVALID_INPUT', 'Request body must be JSON.');
  }
  if (parsed == null || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new ProvisionError('INVALID_INPUT', 'Request body must be a JSON object.');
  }
  return parsed as Record<string, unknown>;
}

function bearerToken(req: IncomingMessage): string {
  const header = String(req.headers.authorization ?? '');
  const match = /^Bearer\s+(.+)$/i.exec(header);
  return (match?.[1] ?? '').trim();
}

async function assertControlPlaneSysAdmin(idToken: string): Promise<void> {
  if (idToken.length === 0) {
    throw new ProvisionError('UNAUTHORIZED', 'Sign in as SysAdmin to provision a College Admin.');
  }
  let uid = '';
  let phone = '';
  try {
    const decoded = await getAuth(controlPlaneApp()).verifyIdToken(idToken);
    uid = decoded.uid;
    phone = String(decoded.phone_number ?? '').trim();
  } catch {
    throw new ProvisionError('UNAUTHORIZED', 'Sign in as SysAdmin to provision a College Admin.');
  }

  const db = controlPlaneFirestore();
  const profile = await db.collection('hkzUsers').doc(uid).get();
  const data = profile.data() ?? {};
  const role = String(data.role ?? '').trim();
  const roles = Array.isArray(data.roles) ? data.roles.map((value) => String(value).trim()) : [];
  if (role === 'SADM' || roles.includes('SADM')) return;

  if (phone.length > 0) {
    const whitelist = await db
      .collection('hkzSysAdminWhitelist')
      .where('phone', '==', phone)
      .where('isActive', '==', true)
      .limit(1)
      .get();
    if (!whitelist.empty) return;
  }

  throw new ProvisionError('UNAUTHORIZED', 'Only a Control Plane SysAdmin can provision a College Admin.');
}

const server = createServer((req, res) => {
  void (async () => {
    if (req.method === 'OPTIONS') {
      send(res, 204, {});
      return;
    }
    const url = new URL(req.url ?? '/', 'http://localhost');
    if (req.method !== 'POST' || url.pathname !== '/provision-tenant-admin') {
      send(res, 404, { ok: false, code: 'INVALID_INPUT', message: 'Unknown provisioning operation.' });
      return;
    }
    try {
      await assertControlPlaneSysAdmin(bearerToken(req));
      const body = await readJson(req);
      const result = await provisionTenantAdmin({
        tenantProjectId: String(body.tenantProjectId ?? ''),
        organisationId: String(body.organisationId ?? ''),
        firstName: String(body.firstName ?? ''),
        lastName: String(body.lastName ?? ''),
        email: String(body.email ?? ''),
        phone: String(body.phone ?? ''),
      });
      send(res, result.ok ? 200 : 409, result);
    } catch (error) {
      if (error instanceof ProvisionError) {
        send(res, error.code === 'UNAUTHORIZED' ? 401 : 400, error.toResult());
        return;
      }
      send(res, 500, {
        ok: false,
        code: 'WRITE_FAILED',
        message: error instanceof Error ? error.message : 'Provisioning failed.',
      });
    }
  })();
});

server.listen(PORT, '0.0.0.0', () => {
  process.stdout.write(`Hackz provisioning invoke listening on ${PORT}\n`);
});
