import type { ProvisionFailureCode, ProvisionTenantAdminFailure } from './types.js';

export class ProvisionError extends Error {
  readonly code: ProvisionFailureCode;

  constructor(code: ProvisionFailureCode, message: string) {
    super(message);
    this.name = 'ProvisionError';
    this.code = code;
  }

  toResult(): ProvisionTenantAdminFailure {
    return { ok: false, code: this.code, message: this.message };
  }
}

export function isPermissionDenied(error: unknown): boolean {
  if (error == null || typeof error !== 'object') return false;
  const code = 'code' in error ? String(error.code) : '';
  const message = 'message' in error ? String(error.message) : '';
  return (
    code === 'permission-denied' ||
    code === '7' ||
    code.includes('PERMISSION_DENIED') ||
    message.includes('PERMISSION_DENIED') ||
    message.toLowerCase().includes('permission denied')
  );
}
