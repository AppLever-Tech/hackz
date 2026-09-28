import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizeCapabilities } from './capabilities.js';

test('normalizeCapabilities maps Turnitin-like feature names', () => {
  const caps = normalizeCapabilities(['SIMILARITY', 'AI_WRITING', 'matching_sources']);
  assert.deepEqual(caps.sort(), ['aiWriting', 'matchingSources', 'similarity'].sort());
});
