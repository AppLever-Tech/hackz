import test from 'node:test';
import assert from 'node:assert/strict';
import { providerFor, supportedProviderIds } from './registry.js';

test('registry exposes turnitin and drillbit adapters', () => {
  assert.deepEqual(supportedProviderIds(), ['turnitin', 'drillbit']);
  assert.equal(providerFor('turnitin').id, 'turnitin');
  assert.equal(providerFor('drillbit').id, 'drillbit');
});
