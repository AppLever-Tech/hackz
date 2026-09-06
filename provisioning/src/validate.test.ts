import assert from 'node:assert/strict';
import { test } from 'node:test';
import { ProvisionError } from './errors.js';
import { normalizeProvisionRequest } from './validate.js';

test('normalizeProvisionRequest requires identity fields', () => {
  assert.throws(
    () =>
      normalizeProvisionRequest({
        tenantProjectId: '',
        firstName: 'Asha',
        lastName: 'Nair',
        email: 'asha@college.edu',
        phone: '9876543210',
      }),
    (error: unknown) => error instanceof ProvisionError && error.code === 'INVALID_INPUT',
  );
});

test('normalizeProvisionRequest returns CADM identity for Hackz', () => {
  const input = normalizeProvisionRequest({
    tenantProjectId: 'college-one',
    firstName: ' Asha ',
    lastName: ' Nair ',
    email: 'Asha@College.EDU',
    phone: '9876543210',
    organisationId: ' org-1 ',
  });
  assert.equal(input.tenantProjectId, 'college-one');
  assert.equal(input.firstName, 'Asha');
  assert.equal(input.lastName, 'Nair');
  assert.equal(input.email, 'asha@college.edu');
  assert.equal(input.phone, '+919876543210');
  assert.equal(input.organisationId, 'org-1');
});
