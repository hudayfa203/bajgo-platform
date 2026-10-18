import { Inject, Injectable, Logger } from '@nestjs/common';
import { and, desc, eq, isNotNull, sql } from 'drizzle-orm';
import { DbService } from '../../infra/db/db.service';
import { devices, notifications, users } from '../../infra/db/schema';
import { PUSH_PROVIDER, PushProvider } from './push/push.provider';
import { SmsService } from './sms/sms.service';
import { Lang, render, TemplateKey } from './templates';

export interface SendOptions {
  push?: boolean; // default true
  sms?: boolean; // default false (OTP/recipient codes are sent directly via SmsService)
  data?: Record<string, unknown>;
}

/** NotificationService.send(user, template, data) → in_app row always; push via PushProvider; SMS optional. */
@Injectable()
export class NotificationsService {
  private readonly logger = new Logger('Notifications');
  constructor(
    private readonly dbs: DbService,
    private readonly sms: SmsService,
    @Inject(PUSH_PROVIDER) private readonly push: PushProvider,
  ) {}

  async send(userId: string, template: TemplateKey, data: Record<string, unknown> = {}, opts: SendOptions = {}) {
    const [user] = await this.dbs.db
      .select({ id: users.id, language: users.language, phone: users.phoneE164 })
      .from(users)
      .where(eq(users.id, userId));
    if (!user) return;
    const lang = (user.language ?? 'so') as Lang;
    const { title, body } = render(template, lang, data);
    const payload = { ...(opts.data ?? {}), ...data };

    await this.dbs.db.insert(notifications).values({ userId, channel: 'in_app', template, title, body, data: payload, sentAt: new Date(), deliveryStatus: 'delivered' });

    if (opts.push !== false) {
      const tokens = (
        await this.dbs.db
          .select({ token: devices.pushToken })
          .from(devices)
          .where(and(eq(devices.userId, userId), isNotNull(devices.pushToken)))
      )
        .map((d) => d.token!)
        .filter(Boolean);
      if (tokens.length) {
        const strData = Object.fromEntries(Object.entries(payload).map(([k, v]) => [k, typeof v === 'string' ? v : JSON.stringify(v)]));
        const res = await this.push.send({ tokens, title, body, data: strData }).catch((e) => ({ ok: false, sent: 0, error: (e as Error).message }));
        await this.dbs.db.insert(notifications).values({
          userId, channel: 'push', template, title, body, data: payload, sentAt: new Date(),
          deliveryStatus: res.ok ? 'sent' : `failed: ${res.error ?? 'unknown'}`,
        });
      }
    }
    if (opts.sms && user.phone) {
      const res = await this.sms.send({ to: user.phone, text: body, purpose: template });
      await this.dbs.db.insert(notifications).values({ userId, channel: 'sms', template, title, body, data: payload, sentAt: new Date(), deliveryStatus: res.ok ? 'sent' : 'failed' });
    }
  }

  /** Send a templated SMS to a phone number that may not belong to a user (e.g. delivery recipient). */
  async sendSmsTo(phone: string, template: TemplateKey, lang: Lang, data: Record<string, unknown>) {
    const { body } = render(template, lang, data);
    return this.sms.send({ to: phone, text: body, purpose: template });
  }

  async listForUser(userId: string, page: number, limit: number) {
    const rows = await this.dbs.db
      .select()
      .from(notifications)
      .where(and(eq(notifications.userId, userId), eq(notifications.channel, 'in_app')))
      .orderBy(desc(notifications.createdAt))
      .limit(limit)
      .offset((page - 1) * limit);
    const [{ count }] = await this.dbs.db
      .select({ count: sql<number>`count(*)::int` })
      .from(notifications)
      .where(and(eq(notifications.userId, userId), eq(notifications.channel, 'in_app')));
    return {
      data: rows.map((n) => ({ id: n.id, template: n.template, title: n.title, body: n.body, data: n.data, read_at: n.readAt, created_at: n.createdAt })),
      meta: { page, limit, total: count },
    };
  }

  async markRead(userId: string, id: string) {
    await this.dbs.db.update(notifications).set({ readAt: new Date() }).where(and(eq(notifications.id, id), eq(notifications.userId, userId)));
  }
}
