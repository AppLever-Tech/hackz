import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  isDepartmentAdmin,
  loadTenantUserProfile,
  phoneLookupValues,
  profileHasRole,
  profileOrganisationId,
  type TenantUserLookup,
} from './tenant-operator.js';

function snapshot(data: Record<string, unknown> | undefined) {
  return {
    exists: data != null,
    data: () => data,
  };
}

function lookupFrom(state: {
  users?: Record<string, Record<string, unknown>>;
  mirrors?: Record<string, Record<string, unknown>>;
}): TenantUserLookup {
  const users = state.users ?? {};
  const mirrors = state.mirrors ?? {};
  return {
    async userById(id) {
      return snapshot(users[id]);
    },
    async authMirrorByUid(uid) {
      return snapshot(mirrors[uid]);
    },
    async userByPhone(phone) {
      const match = Object.values(users).find((row) => String(row.phone ?? '') === phone);
      return {
        empty: match == null,
        docs: match == null ? [] : [{ data: () => match }],
      };
    },
  };
}

test('isDepartmentAdmin matches DADM case-insensitively on role or roles', () => {
  assert.equal(isDepartmentAdmin({ role: 'DADM' }), true);
  assert.equal(isDepartmentAdmin({ role: ' dadm ' }), true);
  assert.equal(isDepartmentAdmin({ role: 'TMEM', roles: ['DADM'] }), true);
  assert.equal(isDepartmentAdmin({ role: 'CADM' }), false);
  assert.equal(isDepartmentAdmin(undefined), false);
});

test('profileHasRole and org id stay tenant-scoped', () => {
  assert.equal(profileHasRole({ role: 'coo' }, 'COO'), true);
  assert.equal(profileOrganisationId({ orgId: ' org-1 ' }), 'org-1');
  assert.equal(profileOrganisationId(undefined), '');
});

test('phoneLookupValues keeps token E.164 and adds +91 when missing', () => {
  assert.deepEqual(phoneLookupValues('+919876543210'), ['+919876543210']);
  assert.deepEqual(phoneLookupValues('9876543210'), ['9876543210', '+919876543210']);
  assert.deepEqual(phoneLookupValues(''), []);
});

test('loadTenantUserProfile uses Auth UID only when that document exists', async () => {
  const data = await loadTenantUserProfile(
    lookupFrom({
      users: { 'auth-uid': { role: 'DADM', orgId: 'org-1' } },
    }),
    { uid: 'auth-uid' },
  );
  assert.equal(data?.role, 'DADM');
});

test('loadTenantUserProfile follows hkzUserAuthMirror linkedProfileId', async () => {
  const data = await loadTenantUserProfile(
    lookupFrom({
      users: { 'profile-1': { role: 'DADM', orgId: 'org-1', phone: '+919876543210' } },
      mirrors: { 'auth-uid': { linkedProfileId: 'profile-1' } },
    }),
    { uid: 'auth-uid' },
  );
  assert.equal(data?.orgId, 'org-1');
  assert.equal(isDepartmentAdmin(data), true);
});

test('loadTenantUserProfile falls back to token phone when mirror is missing', async () => {
  const data = await loadTenantUserProfile(
    lookupFrom({
      users: { 'profile-1': { role: 'DADM', orgId: 'org-1', phone: '+919876543210' } },
    }),
    { uid: 'auth-uid', phone_number: '+919876543210' },
  );
  assert.equal(profileOrganisationId(data), 'org-1');
});

test('loadTenantUserProfile does not return another organisation by uid miss', async () => {
  const data = await loadTenantUserProfile(
    lookupFrom({
      users: { 'other': { role: 'DADM', orgId: 'org-2', phone: '+911111111111' } },
    }),
    { uid: 'auth-uid', phone_number: '+919876543210' },
  );
  assert.equal(data, undefined);
});
