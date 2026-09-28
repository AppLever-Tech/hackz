import type { ProvisionTenantAdminRequest } from './types.js';
import { isValidE164, isValidEmail, normalizePhoneE164 } from './phone.js';
import { ProvisionError } from './errors.js';

export type NormalizedAdminInput = {
  tenantProjectId: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  organisationId: string;
};

function required(value: string | undefined, label: string): string {
  const text = (value ?? '').trim();
  if (text.length === 0) {
    throw new ProvisionError('INVALID_INPUT', `${label} is required.`);
  }
  return text;
}

export function normalizeProvisionRequest(
  input: ProvisionTenantAdminRequest,
): NormalizedAdminInput {
  const tenantProjectId = required(input.tenantProjectId, 'tenantProjectId');
  const firstName = required(input.firstName, 'firstName');
  const lastName = required(input.lastName, 'lastName');
  const email = required(input.email, 'email').toLowerCase();
  if (!isValidEmail(email)) {
    throw new ProvisionError('INVALID_INPUT', 'email is not valid.');
  }
  const phone = normalizePhoneE164(required(input.phone, 'phone'));
  if (!isValidE164(phone)) {
    throw new ProvisionError('INVALID_INPUT', 'phone must be a valid E.164 number.');
  }
  return {
    tenantProjectId,
    firstName,
    lastName,
    email,
    phone,
    organisationId: (input.organisationId ?? '').trim(),
  };
}
