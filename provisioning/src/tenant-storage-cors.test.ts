import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { HACKZ_STORAGE_CORS_ORIGINS, mergeHackzStorageCors } from './tenant-storage-cors.js';

describe('mergeHackzStorageCors', () => {
  it('adds a GET rule when bucket has no CORS', () => {
    const { cors, unchanged } = mergeHackzStorageCors(undefined, HACKZ_STORAGE_CORS_ORIGINS);
    assert.equal(unchanged, false);
    assert.equal(cors.length, 1);
    assert.deepEqual(cors[0]?.method, ['GET', 'HEAD']);
    assert.ok(cors[0]?.origin?.includes('https://hackze.web.app'));
  });

  it('is idempotent when origins already present', () => {
    const existing = [
      {
        origin: [...HACKZ_STORAGE_CORS_ORIGINS],
        method: ['GET'],
        responseHeader: ['Content-Type'],
        maxAgeSeconds: 3600,
      },
    ];
    const { unchanged } = mergeHackzStorageCors(existing, HACKZ_STORAGE_CORS_ORIGINS);
    assert.equal(unchanged, true);
  });

  it('merges missing Hackz origins into an existing GET rule', () => {
    const existing = [
      {
        origin: ['https://example.edu'],
        method: ['GET', 'HEAD'],
        responseHeader: ['Content-Type'],
        maxAgeSeconds: 600,
      },
    ];
    const { cors, unchanged } = mergeHackzStorageCors(existing, ['https://hackze.web.app']);
    assert.equal(unchanged, false);
    assert.ok(cors[0]?.origin?.includes('https://example.edu'));
    assert.ok(cors[0]?.origin?.includes('https://hackze.web.app'));
  });
});
