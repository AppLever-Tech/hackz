import { applicationDefault, getApp, initializeApp, type App } from 'firebase-admin/app';
import { getAuth, type Auth } from 'firebase-admin/auth';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { ProvisionError } from './errors.js';

const CONTROL_PLANE_APP = 'hackz-control-plane';

function credentialOptions(projectId: string) {
  // Local: GOOGLE_APPLICATION_CREDENTIALS. Cloud Run: runtime service account ADC.
  return {
    credential: applicationDefault(),
    projectId,
  };
}

export function controlPlaneProjectId(): string {
  const id = (process.env.HACKZ_CONTROL_PLANE_PROJECT_ID ?? '').trim();
  if (id.length === 0) {
    throw new ProvisionError(
      'CONTROL_PLANE_UNAVAILABLE',
      'HACKZ_CONTROL_PLANE_PROJECT_ID is required.',
    );
  }
  return id;
}

function appNamed(name: string, projectId: string): App {
  try {
    return getApp(name);
  } catch {
    return initializeApp(credentialOptions(projectId), name);
  }
}

export function controlPlaneApp(): App {
  return appNamed(CONTROL_PLANE_APP, controlPlaneProjectId());
}

export function tenantApp(tenantId: string, projectId: string): App {
  return appNamed(`hackz-tenant-${tenantId.trim()}`, projectId.trim());
}

export function controlPlaneFirestore(): Firestore {
  return getFirestore(controlPlaneApp());
}

export function tenantAuth(app: App): Auth {
  return getAuth(app);
}

export function tenantFirestore(app: App): Firestore {
  return getFirestore(app);
}
