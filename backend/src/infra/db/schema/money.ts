import { pgTable, uuid, text, timestamp, smallint, integer, jsonb, bigserial, bigint, boolean } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { paymentMethod, paymentStatus, ledgerAccount, payoutStatus, promoType, serviceType } from './enums';
import { users } from './identity';
import { bookings } from './bookings';

export const payments = pgTable('payments', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  bookingId: uuid('booking_id').notNull().references(() => bookings.id),
  customerId: uuid('customer_id').notNull().references(() => users.id),
  driverId: uuid('driver_id').references(() => users.id),
  method: paymentMethod('method').notNull(),
  provider: text('provider').notNull(),
  providerRef: text('provider_ref'),
  status: paymentStatus('status').notNull().default('pending'),
  amountCents: integer('amount_cents').notNull(),
  currency: text('currency').notNull().default('USD'),
  idempotencyKey: text('idempotency_key').unique(),
  failureReason: text('failure_reason'),
  rawResponse: jsonb('raw_response'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});
export type PaymentRow = typeof payments.$inferSelect;

export const paymentAttempts = pgTable('payment_attempts', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  paymentId: uuid('payment_id').notNull().references(() => payments.id, { onDelete: 'cascade' }),
  attemptNo: smallint('attempt_no').notNull(),
  request: jsonb('request'),
  response: jsonb('response'),
  status: paymentStatus('status').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const paymentWebhooks = pgTable('payment_webhooks', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  provider: text('provider').notNull(),
  eventId: text('event_id').notNull(),
  signatureOk: boolean('signature_ok').notNull(),
  payload: jsonb('payload').notNull(),
  processedAt: timestamp('processed_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const ledgerTransactions = pgTable('ledger_transactions', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  kind: text('kind').notNull(),
  bookingId: uuid('booking_id').references(() => bookings.id),
  paymentId: uuid('payment_id').references(() => payments.id),
  payoutId: uuid('payout_id'),
  description: text('description'),
  createdBy: uuid('created_by').references(() => users.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const ledgerEntries = pgTable('ledger_entries', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  transactionId: uuid('transaction_id').notNull().references(() => ledgerTransactions.id, { onDelete: 'cascade' }),
  account: ledgerAccount('account').notNull(),
  ownerId: uuid('owner_id').references(() => users.id),
  amountCents: bigint('amount_cents', { mode: 'number' }).notNull(),
  currency: text('currency').notNull().default('USD'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const driverWallets = pgTable('driver_wallets', {
  driverId: uuid('driver_id').primaryKey().references(() => users.id, { onDelete: 'cascade' }),
  balanceCents: bigint('balance_cents', { mode: 'number' }).notNull().default(0),
  grossEarnedCents: bigint('gross_earned_cents', { mode: 'number' }).notNull().default(0),
  commissionDueCents: bigint('commission_due_cents', { mode: 'number' }).notNull().default(0),
  cashCollectedCents: bigint('cash_collected_cents', { mode: 'number' }).notNull().default(0),
  paidOutCents: bigint('paid_out_cents', { mode: 'number' }).notNull().default(0),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const payouts = pgTable('payouts', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  driverId: uuid('driver_id').notNull().references(() => users.id),
  amountCents: bigint('amount_cents', { mode: 'number' }).notNull(),
  method: text('method').notNull(),
  account: text('account'),
  status: payoutStatus('status').notNull().default('requested'),
  providerRef: text('provider_ref'),
  requestedAt: timestamp('requested_at', { withTimezone: true }).notNull().defaultNow(),
  approvedBy: uuid('approved_by').references(() => users.id),
  approvedAt: timestamp('approved_at', { withTimezone: true }),
  paidAt: timestamp('paid_at', { withTimezone: true }),
  note: text('note'),
});

export const refunds = pgTable('refunds', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  paymentId: uuid('payment_id').notNull().references(() => payments.id),
  bookingId: uuid('booking_id').notNull().references(() => bookings.id),
  amountCents: integer('amount_cents').notNull(),
  reason: text('reason').notNull(),
  status: paymentStatus('status').notNull().default('pending'),
  providerRef: text('provider_ref'),
  requestedBy: uuid('requested_by').references(() => users.id),
  approvedBy: uuid('approved_by').references(() => users.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  processedAt: timestamp('processed_at', { withTimezone: true }),
});

export const promotions = pgTable('promotions', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  code: text('code').unique().notNull(),
  name: text('name').notNull(),
  type: promoType('type').notNull(),
  value: integer('value').notNull(),
  maxDiscountCents: integer('max_discount_cents'),
  minFareCents: integer('min_fare_cents').notNull().default(0),
  service: serviceType('service'),
  firstNBookings: smallint('first_n_bookings'),
  maxUsesTotal: integer('max_uses_total'),
  maxUsesPerUser: smallint('max_uses_per_user').notNull().default(1),
  usesCount: integer('uses_count').notNull().default(0),
  startsAt: timestamp('starts_at', { withTimezone: true }).notNull().defaultNow(),
  endsAt: timestamp('ends_at', { withTimezone: true }),
  active: boolean('active').notNull().default(true),
  createdBy: uuid('created_by').references(() => users.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});
export type PromotionRow = typeof promotions.$inferSelect;

export const promotionRedemptions = pgTable('promotion_redemptions', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  promotionId: uuid('promotion_id').notNull().references(() => promotions.id),
  userId: uuid('user_id').notNull().references(() => users.id),
  bookingId: uuid('booking_id').notNull().references(() => bookings.id),
  discountCents: integer('discount_cents').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});
