import { createServer, type IncomingMessage, type ServerResponse } from 'node:http';
import { AnalysisError } from './errors.js';
import {
  handleClearCredentials,
  handleSaveProviderCredentials,
  handleTestConnection,
} from './handlers/provider-config.js';
import { handleTurnitinWebhook } from './handlers/webhook-turnitin.js';

function listenPort(): number {
  for (const raw of [process.env.PORT, process.env.HACKZ_ANALYSIS_PORT]) {
    const value = Number(String(raw ?? '').trim());
    if (Number.isInteger(value) && value > 0 && value < 65536) return value;
  }
  return 8788;
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
    throw new AnalysisError('INVALID_INPUT', 'Request body must be JSON.');
  }
  if (parsed == null || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new AnalysisError('INVALID_INPUT', 'Request body must be a JSON object.');
  }
  return parsed as Record<string, unknown>;
}

function bearerToken(req: IncomingMessage): string {
  const header = String(req.headers.authorization ?? '');
  const match = /^Bearer\s+(.+)$/i.exec(header);
  return (match?.[1] ?? '').trim();
}

const server = createServer((req, res) => {
  void (async () => {
    if (req.method === 'OPTIONS') {
      send(res, 204, {});
      return;
    }
    const url = new URL(req.url ?? '/', 'http://localhost');
    if (req.method !== 'POST') {
      send(res, 404, { ok: false, code: 'NOT_FOUND', message: 'Unknown analysis operation.' });
      return;
    }
    try {
      const body = await readJson(req);
      const token = bearerToken(req);
      if (url.pathname === '/save-provider-credentials') {
        const result = await handleSaveProviderCredentials({
          organisationId: String(body.organisationId ?? ''),
          idToken: token,
          provider: body.provider,
          credentials: (body.credentials as Record<string, unknown>) ?? {},
          enabled: body.enabled !== false,
        });
        send(res, 200, result);
        return;
      }
      if (url.pathname === '/test-connection') {
        const result = await handleTestConnection({
          organisationId: String(body.organisationId ?? ''),
          idToken: token,
          provider: body.provider,
          credentials: body.credentials as Record<string, unknown> | undefined,
        });
        send(res, result.ok ? 200 : 409, { ok: result.ok, message: result.message, config: result.config });
        return;
      }
      if (url.pathname === '/clear-provider-credentials') {
        const result = await handleClearCredentials({
          organisationId: String(body.organisationId ?? ''),
          idToken: token,
        });
        send(res, 200, result);
        return;
      }
      if (url.pathname === '/webhooks/turnitin') {
        const result = await handleTurnitinWebhook(body);
        send(res, result.ok ? 200 : 404, result);
        return;
      }
      send(res, 404, { ok: false, code: 'NOT_FOUND', message: 'Unknown analysis operation.' });
    } catch (error) {
      if (error instanceof AnalysisError) {
        const status =
          error.code === 'UNAUTHORIZED'
            ? 401
            : error.code === 'FORBIDDEN'
              ? 403
              : error.code === 'INVALID_INPUT'
                ? 400
                : 409;
        send(res, status, { ok: false, code: error.code, message: error.message });
        return;
      }
      send(res, 500, { ok: false, code: 'INTERNAL', message: 'Analysis service error.' });
    }
  })();
});

server.listen(PORT, () => {
  console.log(`Hackz analysis service listening on port ${PORT}`);
});
