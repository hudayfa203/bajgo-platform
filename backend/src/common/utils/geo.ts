export interface LatLng {
  lat: number;
  lng: number;
}

const R = 6371000;
export function haversineM(a: LatLng, b: LatLng): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const s =
    Math.sin(dLat / 2) ** 2 + Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(s));
}

export function bearingDeg(a: LatLng, b: LatLng): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const y = Math.sin(toRad(b.lng - a.lng)) * Math.cos(toRad(b.lat));
  const x =
    Math.cos(toRad(a.lat)) * Math.sin(toRad(b.lat)) -
    Math.sin(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.cos(toRad(b.lng - a.lng));
  return (((Math.atan2(y, x) * 180) / Math.PI) + 360) % 360;
}

/** Move `frac` (0..1) of the way from a to b along the straight line. */
export function interpolate(a: LatLng, b: LatLng, frac: number): LatLng {
  return { lat: a.lat + (b.lat - a.lat) * frac, lng: a.lng + (b.lng - a.lng) * frac };
}

/** Google encoded polyline (precision 5). */
export function encodePolyline(points: LatLng[]): string {
  let out = '';
  let prevLat = 0;
  let prevLng = 0;
  const enc = (v: number) => {
    let n = v < 0 ? ~(v << 1) : v << 1;
    let s = '';
    while (n >= 0x20) {
      s += String.fromCharCode((0x20 | (n & 0x1f)) + 63);
      n >>= 5;
    }
    return s + String.fromCharCode(n + 63);
  };
  for (const p of points) {
    const lat = Math.round(p.lat * 1e5);
    const lng = Math.round(p.lng * 1e5);
    out += enc(lat - prevLat) + enc(lng - prevLng);
    prevLat = lat;
    prevLng = lng;
  }
  return out;
}

export function decodePolyline(str: string): LatLng[] {
  const pts: LatLng[] = [];
  let i = 0;
  let lat = 0;
  let lng = 0;
  while (i < str.length) {
    for (const which of ['lat', 'lng'] as const) {
      let shift = 0;
      let result = 0;
      let b: number;
      do {
        b = str.charCodeAt(i++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      const delta = result & 1 ? ~(result >> 1) : result >> 1;
      if (which === 'lat') lat += delta;
      else lng += delta;
    }
    pts.push({ lat: lat / 1e5, lng: lng / 1e5 });
  }
  return pts;
}

/** Parse a PostGIS `ST_AsGeoJSON` / `{lat,lng}` / WKT-ish value into LatLng. */
export function parsePoint(v: unknown): LatLng | null {
  if (!v) return null;
  if (typeof v === 'object' && v !== null && 'lat' in v && 'lng' in v) {
    const o = v as { lat: unknown; lng: unknown };
    return { lat: Number(o.lat), lng: Number(o.lng) };
  }
  if (typeof v === 'string') {
    try {
      const g = JSON.parse(v);
      if (g?.type === 'Point') return { lat: g.coordinates[1], lng: g.coordinates[0] };
    } catch {
      const m = /POINT\(([-\d.]+) ([-\d.]+)\)/.exec(v);
      if (m) return { lat: Number(m[2]), lng: Number(m[1]) };
    }
  }
  return null;
}

/** Parse a PostGIS EWKB hex string for a Point (as returned by postgres.js for geography columns). */
export function parseEwkbPoint(hex: string): LatLng | null {
  if (!hex || hex.length < 42) return null;
  const buf = Buffer.from(hex, 'hex');
  const little = buf[0] === 1;
  const type = little ? buf.readUInt32LE(1) : buf.readUInt32BE(1);
  const hasSrid = (type & 0x20000000) !== 0;
  if ((type & 0xff) !== 1) return null; // not a point
  const off = 5 + (hasSrid ? 4 : 0);
  const x = little ? buf.readDoubleLE(off) : buf.readDoubleBE(off);
  const y = little ? buf.readDoubleLE(off + 8) : buf.readDoubleBE(off + 8);
  return { lat: y, lng: x };
}

export function toPoint(v: unknown): LatLng | null {
  if (v == null) return null;
  if (typeof v === 'string' && /^[0-9A-Fa-f]+$/.test(v)) return parseEwkbPoint(v);
  return parsePoint(v);
}
