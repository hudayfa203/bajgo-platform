import { pgTable, uuid, text, timestamp, boolean, smallint, integer, numeric, primaryKey } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { userRole, userStatus, language, otpPurpose } from './enums';
import { citext, inet, geoPoint } from './types';

export const users = pgTable('users', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  role: userRole('role').notNull(),
  phoneE164: text('phone_e164').unique(),
  email: citext('email').unique(),
  passwordHash: text('password_hash'),
  fullName: text('full_name').notNull(),
  language: language('language').notNull().default('so'),
  avatarUrl: text('avatar_url'),
  status: userStatus('status').notNull().default('active'),
  phoneVerifiedAt: timestamp('phone_verified_at', { withTimezone: true }),
  lastSeenAt: timestamp('last_seen_at', { withTimezone: true }),
  marketingConsent: boolean('marketing_consent').notNull().default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  deletedAt: timestamp('deleted_at', { withTimezone: true }),
});

export const otpCodes = pgTable('otp_codes', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  phoneE164: text('phone_e164').notNull(),
  purpose: otpPurpose('purpose').notNull(),
  codeHash: text('code_hash').notNull(),
  attempts: smallint('attempts').notNull().default(0),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  consumedAt: timestamp('consumed_at', { withTimezone: true }),
  ip: inet('ip'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const devices = pgTable('devices', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  platform: text('platform').notNull(),
  deviceName: text('device_name'),
  pushToken: text('push_token'),
  appVersion: text('app_version'),
  lastActiveAt: timestamp('last_active_at', { withTimezone: true }).notNull().defaultNow(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const sessions = pgTable('sessions', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  deviceId: uuid('device_id').references(() => devices.id, { onDelete: 'set null' }),
  refreshTokenHash: text('refresh_token_hash').notNull().unique(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  revokedAt: timestamp('revoked_at', { withTimezone: true }),
  ip: inet('ip'),
  userAgent: text('user_agent'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const roles = pgTable('roles', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  key: text('key').unique().notNull(),
  name: text('name').notNull(),
  permissions: text('permissions').array().notNull().default(sql`'{}'`),
  isSystem: boolean('is_system').notNull().default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const userRoles = pgTable(
  'user_roles',
  {
    userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
    roleId: uuid('role_id').notNull().references(() => roles.id, { onDelete: 'cascade' }),
  },
  (t) => [primaryKey({ columns: [t.userId, t.roleId] })],
);

export const customerProfiles = pgTable('customer_profiles', {
  userId: uuid('user_id').primaryKey().references(() => users.id, { onDelete: 'cascade' }),
  ratingAvg: numeric('rating_avg', { precision: 3, scale: 2 }).notNull().default('5.00'),
  ratingCount: integer('rating_count').notNull().default(0),
  totalRides: integer('total_rides').notNull().default(0),
  totalDeliveries: integer('total_deliveries').notNull().default(0),
  referralCode: text('referral_code').unique(),
  referredBy: uuid('referred_by').references(() => users.id),
  notes: text('notes'),
});

export const savedPlaces = pgTable('saved_places', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  label: text('label').notNull(),
  kind: text('kind').notNull().default('custom'),
  address: text('address'),
  landmark: text('landmark'),
  location: geoPoint('location').notNull(),
  useCount: integer('use_count').notNull().default(0),
  lastUsedAt: timestamp('last_used_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});
