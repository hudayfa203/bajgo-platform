/** Normalise Somali numbers to E.164 (+252…). Accepts 06x…, 6x…, 252…, +252…. */
export function normalisePhone(input: string): string | null {
  const digits = input.replace(/[^\d+]/g, '');
  let n = digits.startsWith('+') ? digits.slice(1) : digits;
  if (n.startsWith('00')) n = n.slice(2);
  if (n.startsWith('0')) n = '252' + n.slice(1);
  if (!n.startsWith('252') && n.length === 9) n = '252' + n;
  if (!/^252\d{8,9}$/.test(n)) return null;
  return '+' + n;
}

export function maskPhone(phone: string): string {
  return phone.replace(/^(\+\d{3})\d+(\d{3})$/, '$1•••••$2');
}
