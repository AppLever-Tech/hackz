export function normalizePhoneE164(raw: string): string {
  const compact = raw.replace(/\s+/g, '').trim();
  if (compact.startsWith('+')) return compact;
  const digits = compact.replace(/\D/g, '');
  if (digits.length === 0) return '';
  return `+91${digits}`;
}

export function isValidEmail(raw: string): boolean {
  const email = raw.trim();
  if (email.length === 0) return false;
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export function isValidE164(phone: string): boolean {
  return /^\+[1-9]\d{7,14}$/.test(phone);
}
