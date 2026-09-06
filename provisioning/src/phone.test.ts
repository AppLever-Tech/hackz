import assert from 'node:assert/strict';
import { test } from 'node:test';
import { isValidE164, isValidEmail, normalizePhoneE164 } from './phone.js';

test('normalizePhoneE164 matches Hackz E.164 lookup', () => {
  assert.equal(normalizePhoneE164('+919876543210'), '+919876543210');
  assert.equal(normalizePhoneE164('9876543210'), '+919876543210');
  assert.equal(normalizePhoneE164(' 98765 43210 '), '+919876543210');
});

test('isValidE164 rejects incomplete numbers', () => {
  assert.equal(isValidE164('+919876543210'), true);
  assert.equal(isValidE164('9876543210'), false);
  assert.equal(isValidE164('+91'), false);
});

test('isValidEmail', () => {
  assert.equal(isValidEmail('cadm@college.edu'), true);
  assert.equal(isValidEmail('not-an-email'), false);
});
