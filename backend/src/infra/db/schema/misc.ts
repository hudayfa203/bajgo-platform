import { pgTable, uuid, text, timestamp, smallint, integer, jsonb, bigserial, boolean } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import { notificationChannel, ticketStatus, ticketCategory } from './enums';
import { geoPoint, inet } from './types';
import { users } from './identity';
import { bookings } from './bookings';

export const notifications = pgTable('notifications', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  channel: notificationChannel('channel').notNull(),
  template: text('template').notNull(),
  title: text('title'),
  body: text('body').notNull(),
  data: jsonb('data').notNull().default({}),
  readAt: timestamp('read_at', { withTimezone: true }),
  sentAt: timestamp('sent_at', { withTimezone: true }),
  deliveryStatus: text('delivery_status'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const smsLog = pgTable('sms_log', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  phoneE164: text('phone_e164').notNull(),
  provider: text('provider').notNull(),
  purpose: text('purpose').notNull(),
  status: text('status').notNull(),
  providerRef: text('provider_ref'),
  costCents: integer('cost_cents'),
  error: text('error'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const supportTickets = pgTable('support_tickets', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  reference: text('reference').notNull(),
  userId: uuid('user_id').notNull().references(() => users.id),
  bookingId: uuid('booking_id').references(() => bookings.id),
  category: ticketCategory('category').notNull(),
  subject: text('subject').notNull(),
  status: ticketStatus('status').notNull().default('open'),
  priority: smallint('priority').notNull().default(2),
  assignedTo: uuid('assigned_to').references(() => users.id),
  isIncident: boolean('is_incident').notNull().default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  resolvedAt: timestamp('resolved_at', { withTimezone: true }),
});

export const supportMessages = pgTable('support_messages', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  ticketId: uuid('ticket_id').notNull().references(() => supportTickets.id, { onDelete: 'cascade' }),
  authorId: uuid('author_id').notNull().references(() => users.id),
  body: text('body').notNull(),
  attachments: jsonb('attachments').notNull().default([]),
  internal: boolean('internal').notNull().default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const incidentReports = pgTable('incident_reports', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  bookingId: uuid('booking_id').references(() => bookings.id),
  reporterId: uuid('reporter_id').notNull().references(() => users.id),
  kind: text('kind').notNull(),
  description: text('description'),
  location: geoPoint('location'),
  status: text('status').notNull().default('open'),
  handledBy: uuid('handled_by').references(() => users.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  resolvedAt: timestamp('resolved_at', { withTimezone: true }),
});

export const settings = pgTable('settings', {
  key: text('key').primaryKey(),
  value: jsonb('value').notNull(),
  updatedBy: uuid('updated_by').references(() => users.id),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const cmsPages = pgTable('cms_pages', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  slug: text('slug').unique().notNull(),
  titleSo: text('title_so').notNull(),
  titleEn: text('title_en').notNull(),
  blocks: jsonb('blocks').notNull().default([]),
  seo: jsonb('seo').notNull().default({}),
  published: boolean('published').notNull().default(false),
  updatedBy: uuid('updated_by').references(() => users.id),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const cmsFaqs = pgTable('cms_faqs', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  category: text('category').notNull(),
  questionSo: text('question_so').notNull(),
  answerSo: text('answer_so').notNull(),
  questionEn: text('question_en').notNull(),
  answerEn: text('answer_en').notNull(),
  sortOrder: integer('sort_order').notNull().default(0),
  published: boolean('published').notNull().default(true),
});

export const cmsBanners = pgTable('cms_banners', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  placement: text('placement').notNull(),
  titleSo: text('title_so'),
  titleEn: text('title_en'),
  bodySo: text('body_so'),
  bodyEn: text('body_en'),
  imageUrl: text('image_url'),
  linkUrl: text('link_url'),
  startsAt: timestamp('starts_at', { withTimezone: true }),
  endsAt: timestamp('ends_at', { withTimezone: true }),
  sortOrder: integer('sort_order').notNull().default(0),
  published: boolean('published').notNull().default(true),
});

export const cmsTestimonials = pgTable('cms_testimonials', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  author: text('author').notNull(),
  role: text('role'),
  quoteSo: text('quote_so'),
  quoteEn: text('quote_en'),
  approved: boolean('approved').notNull().default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const contactMessages = pgTable('contact_messages', {
  id: uuid('id').primaryKey().default(sql`uuid_generate_v4()`),
  name: text('name').notNull(),
  phone: text('phone'),
  email: text('email'),
  subject: text('subject'),
  body: text('body').notNull(),
  handled: boolean('handled').notNull().default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const auditLogs = pgTable('audit_logs', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  actorId: uuid('actor_id').references(() => users.id),
  actorRole: text('actor_role'),
  action: text('action').notNull(),
  entityType: text('entity_type'),
  entityId: text('entity_id'),
  before: jsonb('before'),
  after: jsonb('after'),
  ip: inet('ip'),
  userAgent: text('user_agent'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});
