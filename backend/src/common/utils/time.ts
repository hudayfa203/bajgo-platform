/** Local wall-clock parts for an instant in an IANA timezone (default Africa/Mogadishu, UTC+3, no DST). */
export function localParts(at: Date, timeZone = 'Africa/Mogadishu'): { minutes: number; weekday: number; hhmm: string } {
  const f = new Intl.DateTimeFormat('en-US', {
    timeZone,
    hour12: false,
    hour: '2-digit',
    minute: '2-digit',
    weekday: 'short',
  });
  const parts = Object.fromEntries(f.formatToParts(at).map((p) => [p.type, p.value]));
  const hour = Number(parts.hour) % 24;
  const minute = Number(parts.minute);
  const weekday = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].indexOf(parts.weekday);
  return { minutes: hour * 60 + minute, weekday, hhmm: `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}` };
}

export function hhmmToMinutes(s: string): number {
  const [h, m] = s.split(':').map(Number);
  return h * 60 + (m || 0);
}

/** true when `minutes` is inside [start,end) — handles windows that wrap midnight. */
export function inWindow(minutes: number, start: string, end: string): boolean {
  const s = hhmmToMinutes(start);
  const e = hhmmToMinutes(end);
  if (s === e) return false;
  return s < e ? minutes >= s && minutes < e : minutes >= s || minutes < e;
}

export const sleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));
