import { pgTable, uuid, text, timestamp, boolean, smallint, integer, numeric, date, jsonb } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { driverVerification, driverAvailability, documentType, documentStatus, zoneKind, serviceType } from './enums';
import { geoPoint, geoMultiPolygon } from './types';
import { users } from './identity';

export const vehicles = pgTable('vehicles', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  fleetCode: text('fleet_code').unique(),
  plateNumber: text('plate_number').unique(),
  makeModel: text('make_model').notNull().default('Bajaj RE'),
  colour: text('colour'),
  year: smallint('year'),
  seats: smallint('seats').notNull().default(3),
  maxParcelKg: numeric('max_parcel_kg', { precision: 5, scale: 1 }).notNull().default('30'),
  livery: text('livery').notNull().default('none'),
  active: boolean('active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const driverProfiles = pgTable('driver_profiles', {
  userId: uuid('user_id').primaryKey().references(() => users.id, { onDelete: 'cascade' }),
  vehicleId: uuid('vehicle_id').references(() => vehicles.id),
  verification: driverVerification('verification').notNull().default('pending'),
  verificationNotes: text('verification_notes'),
  verifiedBy: uuid('verified_by').references(() => users.id),
  verifiedAt: timestamp('verified_at', { withTimezone: true }),
  availability: driverAvailability('availability').notNull().default('offline'),
  acceptsRides: boolean('accepts_rides').notNull().default(true),
  acceptsDeliveries: boolean('accepts_deliveries').notNull().default(true),
  ratingAvg: numeric('rating_avg', { precision: 3, scale: 2 }).notNull().default('5.00'),
  ratingCount: integer('rating_count').notNull().default(0),
  totalRides: integer('total_rides').notNull().default(0),
  totalDeliveries: integer('total_deliveries').notNull().default(0),
  acceptanceRate: numeric('acceptance_rate', { precision: 5, scale: 2 }).notNull().default('100'),
  commissionPct: numeric('commission_pct', { precision: 5, scale: 2 }),
  emergencyContactName: text('emergency_contact_name'),
  emergencyContactPhone: text('emergency_contact_phone'),
  payoutMethod: text('payout_method'),
  payoutAccount: text('payout_account'),
  lastLocation: geoPoint('last_location'),
  lastLocationAt: timestamp('last_location_at', { withTimezone: true }),
  heading: smallint('heading'),
  onlineSince: timestamp('online_since', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const driverDocuments = pgTable('driver_documents', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  driverId: uuid('driver_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  type: documentType('type').notNull(),
  fileUrl: text('file_url').notNull(),
  status: documentStatus('status').notNull().default('pending'),
  expiresAt: date('expires_at'),
  reviewedBy: uuid('reviewed_by').references(() => users.id),
  reviewedAt: timestamp('reviewed_at', { withTimezone: true }),
  reviewNote: text('review_note'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const driverLocationHistory = pgTable('driver_location_history', {
  driverId: uuid('driver_id').notNull(),
  bookingId: uuid('booking_id'),
  location: geoPoint('location').notNull(),
  speedKmh: numeric('speed_kmh', { precision: 5, scale: 1 }),
  heading: smallint('heading'),
  recordedAt: timestamp('recorded_at', { withTimezone: true }).notNull(),
});

export const zones = pgTable('zones', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  key: text('key').unique().notNull(),
  name: text('name').notNull(),
  kind: zoneKind('kind').notNull().default('service_area'),
  geom: geoMultiPolygon('geom').notNull(),
  active: boolean('active').notNull().default(true),
  dispatchRadiusStepsM: integer('dispatch_radius_steps_m').array().notNull().default(sql`'{2000,4000,7000}'`),
  maxSearchSeconds: integer('max_search_seconds').notNull().default(180),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const pricingVersions = pgTable('pricing_versions', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  version: integer('version').notNull(),
  service: serviceType('service').notNull(),
  zoneId: uuid('zone_id').references(() => zones.id),
  name: text('name').notNull(),
  currency: text('currency').notNull().default('USD'),
  ratePerKmCents: integer('rate_per_km_cents').notNull(),
  minimumFareCents: integer('minimum_fare_cents').notNull(),
  baseFeeCents: integer('base_fee_cents').notNull().default(0),
  waitingFeePerMinCents: integer('waiting_fee_per_min_cents').notNull().default(0),
  freeWaitingMinutes: smallint('free_waiting_minutes').notNull().default(3),
  cancellationFeeCents: integer('cancellation_fee_cents').notNull().default(0),
  cancellationFreeSeconds: integer('cancellation_free_seconds').notNull().default(120),
  surgeMultiplier: numeric('surge_multiplier', { precision: 4, scale: 2 }).notNull().default('1.00'),
  nightMultiplier: numeric('night_multiplier', { precision: 4, scale: 2 }).notNull().default('1.00'),
  nightStart: text('night_start').notNull().default('22:00'),
  nightEnd: text('night_end').notNull().default('05:00'),
  peakMultiplier: numeric('peak_multiplier', { precision: 4, scale: 2 }).notNull().default('1.00'),
  peakWindows: jsonb('peak_windows').notNull().default([]),
  distanceBrackets: jsonb('distance_brackets').notNull().default([]),
  deliveryExtras: jsonb('delivery_extras').notNull().default({}),
  commissionPct: numeric('commission_pct', { precision: 5, scale: 2 }).notNull().default('15.00'),
  roundingCents: smallint('rounding_cents').notNull().default(10),
  effectiveFrom: timestamp('effective_from', { withTimezone: true }).notNull().defaultNow(),
  effectiveTo: timestamp('effective_to', { withTimezone: true }),
  createdBy: uuid('created_by').references(() => users.id),
  note: text('note'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});
