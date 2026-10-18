import { customType } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { LatLng, parseEwkbPoint } from '../../../common/utils/geo';

/** geography(Point,4326) ⇄ {lat,lng} */
export const geoPoint = customType<{ data: LatLng; driverData: string }>({
  dataType() {
    return 'geography(Point,4326)';
  },
  toDriver(v: LatLng) {
    return sql`ST_SetSRID(ST_MakePoint(${v.lng}, ${v.lat}), 4326)::geography` as unknown as string;
  },
  fromDriver(v: string) {
    return parseEwkbPoint(v) ?? { lat: 0, lng: 0 };
  },
});

export const geoMultiPolygon = customType<{ data: string; driverData: string }>({
  dataType() {
    return 'geography(MultiPolygon,4326)';
  },
});

export const citext = customType<{ data: string }>({
  dataType() {
    return 'citext';
  },
});
export const inet = customType<{ data: string }>({
  dataType() {
    return 'inet';
  },
});
