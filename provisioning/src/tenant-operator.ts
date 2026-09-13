import type { DocumentData, Firestore } from 'firebase-admin/firestore';
import { normalizePhoneE164 } from './phone.js';
import { DEPARTMENT_ADMIN_ROLE, HKZ_USER_AUTH_MIRROR, HKZ_USERS } from './types.js';

export type TenantDecodedToken = {
  uid: string;
  phone_number?: string;
};

export type TenantDocSnapshot = {
  exists: boolean;
  data(): DocumentData | undefined;
};

export type TenantQuerySnapshot = {
  empty: boolean;
  docs: Array<{ data(): DocumentData | undefined }>;
};

/** Minimal tenant reads used to resolve a signed-in operator to `hkzUsers`. */
export type TenantUserLookup = {
  userById(id: string): Promise<TenantDocSnapshot>;
  authMirrorByUid(uid: string): Promise<TenantDocSnapshot>;
  userByPhone(phone: string): Promise<TenantQuerySnapshot>;
};

export function firestoreUserLookup(db: Firestore): TenantUserLookup {
  return {
    userById(id) {
      return db.collection(HKZ_USERS).doc(id).get();
    },
    authMirrorByUid(uid) {
      return db.collection(HKZ_USER_AUTH_MIRROR).doc(uid).get();
    },
    userByPhone(phone) {
      return db.collection(HKZ_USERS).where('phone', '==', phone).limit(1).get();
    },
  };
}

function roleCode(value: unknown): string {
  return String(value ?? '').trim().toUpperCase();
}

export function profileHasRole(data: DocumentData | undefined, role: string): boolean {
  if (data == null) return false;
  const wanted = roleCode(role);
  if (wanted.length === 0) return false;
  if (roleCode(data.role) === wanted) return true;
  const roles = data.roles;
  return Array.isArray(roles) && roles.some((entry) => roleCode(entry) === wanted);
}

export function isDepartmentAdmin(data: DocumentData | undefined): boolean {
  return profileHasRole(data, DEPARTMENT_ADMIN_ROLE);
}

export function profileOrganisationId(data: DocumentData | undefined): string {
  return String(data?.orgId ?? '').trim();
}

export function phoneLookupValues(phoneNumber?: string): string[] {
  const raw = String(phoneNumber ?? '').trim();
  if (raw.length === 0) return [];
  const normalized = normalizePhoneE164(raw);
  if (normalized.length === 0 || normalized === raw) return [raw];
  return [raw, normalized];
}

/**
 * Resolve the tenant `hkzUsers` row for a verified tenant Auth token.
 *
 * Hackz profiles use a generated Firestore id. Login matches by phone and writes
 * `hkzUserAuthMirror/{uid}.linkedProfileId`. Looking up `hkzUsers/{uid}` alone
 * treats a real Department Admin as missing.
 */
export async function loadTenantUserProfile(
  lookup: TenantUserLookup,
  decoded: TenantDecodedToken,
): Promise<DocumentData | undefined> {
  const uid = String(decoded.uid ?? '').trim();
  if (uid.length > 0) {
    const byUid = await lookup.userById(uid);
    if (byUid.exists) {
      const data = byUid.data();
      if (data != null) return data;
    }

    const mirror = await lookup.authMirrorByUid(uid);
    const linkedId = String(mirror.data()?.linkedProfileId ?? '').trim();
    if (linkedId.length > 0) {
      const linked = await lookup.userById(linkedId);
      if (linked.exists) {
        const data = linked.data();
        if (data != null) return data;
      }
    }
  }

  for (const phone of phoneLookupValues(decoded.phone_number)) {
    const snap = await lookup.userByPhone(phone);
    if (snap.empty) continue;
    const data = snap.docs[0]?.data();
    if (data != null) return data;
  }

  return undefined;
}
