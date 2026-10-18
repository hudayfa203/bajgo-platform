import { Inject, Injectable } from '@nestjs/common';
import { createHmac } from 'node:crypto';
import { and, desc, eq, gt, isNull, sql } from 'drizzle-orm';
import { ENV, Env } from '../../config/env';
import { DbService } from '../../infra/db/db.service';
import { RedisService } from '../../infra/redis/redis.service';
import { otpCodes } from '../../infra/db/schema';
import { SettingsService } from '../settings/settings.service';
import { NotificationsService } from '../notifications/notifications.service';
import { numericCode } from '../../common/utils/ids';
import { RateLimitError, UnauthorizedError } from '../../common/errors/app-error';
import { Lang } from '../notifications/templates';

export type OtpPurpose = 'login' | 'recipient_delivery' | 'account_recovery' | 'account_deletion';

/**
 * OTP lifecycle: hashed at rest (HMAC-SHA256 with OTP_PEPPER), TTL + rate limits from the `otp`
 * setting, Redis fixed-window buckets per phone and per IP, lockout after max verify attempts.
 */
@Injectable()
export class OtpService {
  constructor(
    @Inject(ENV) private readonly env: Env,
    private readonly dbs: DbService,
    private readonly redis: RedisService,
    private readonly settings: SettingsService,
    private readonly notifications: NotificationsService,
  ) {}

  private hash(phone: string, purpose: string, code: string) {
    return createHmac('sha256', this.env.OTP_PEPPER).update(`${phone}|${purpose}|${code}`).digest('hex');
  }

  isTestNumber(phone: string): boolean {
    return !this.env.isProduction && this.env.OTP_TEST_NUMBERS.includes(phone);
  }

  /** Generate, store and send a code. Returns the plain code only for allow-listed dev numbers (dev_code). */
  async request(phone: string, purpose: OtpPurpose, opts: { ip?: string; lang?: Lang; length?: number; template?: 'otp.login' | 'otp.recipient' | 'otp.account_deletion' } = {}) {
    const cfg = await this.settings.get('otp');
    const ttl = cfg.ttl_s;

    if (purpose !== 'recipient_delivery') {
      if (await this.redis.client.exists(`otp:resend:${phone}:${purpose}`)) {
        const ttlLeft = await this.redis.client.ttl(`otp:resend:${phone}:${purpose}`);
        throw new RateLimitError('OTP_RESEND_TOO_SOON', 'Please wait before requesting another code', { retry_after_s: Math.max(ttlLeft, 1) });
      }
      const perPhone = await this.redis.hit(`otp:rl:phone:${phone}`, 3600);
      if (perPhone > cfg.max_sends_per_phone_per_hour) throw new RateLimitError('OTP_PHONE_LIMIT', 'Too many codes requested for this number. Try again in an hour.');
      if (opts.ip) {
        const perIp = await this.redis.hit(`otp:rl:ip:${opts.ip}`, 3600);
        if (perIp > cfg.max_sends_per_ip_per_hour) throw new RateLimitError('OTP_IP_LIMIT', 'Too many codes requested. Try again in an hour.');
      }
    }

    const length = opts.length ?? cfg.length ?? 6;
    const isTest = purpose === 'login' && this.isTestNumber(phone);
    const code = isTest ? this.env.OTP_TEST_CODE.slice(0, length).padStart(length, '0') : numericCode(length);

    await this.dbs.db
      .update(otpCodes)
      .set({ consumedAt: new Date() })
      .where(and(eq(otpCodes.phoneE164, phone), eq(otpCodes.purpose, purpose), isNull(otpCodes.consumedAt)));
    await this.dbs.db.insert(otpCodes).values({
      phoneE164: phone,
      purpose,
      codeHash: this.hash(phone, purpose, code),
      expiresAt: new Date(Date.now() + ttl * 1000),
      ip: opts.ip ?? null,
    });
    if (purpose !== 'recipient_delivery') await this.redis.client.set(`otp:resend:${phone}:${purpose}`, '1', 'EX', cfg.resend_after_s);

    const template = opts.template ?? (purpose === 'account_deletion' ? 'otp.account_deletion' : purpose === 'recipient_delivery' ? 'otp.recipient' : 'otp.login');
    await this.notifications.sendSmsTo(phone, template, opts.lang ?? 'so', { code });

    return { expires_in: ttl, resend_after: cfg.resend_after_s, dev_code: isTest ? code : undefined, code };
  }

  /** Verify the latest live code for phone+purpose. Throws 401 OTP_INVALID / 429 OTP_LOCKED / 401 OTP_EXPIRED. */
  async verify(phone: string, purpose: OtpPurpose, code: string): Promise<void> {
    const cfg = await this.settings.get('otp');
    const [row] = await this.dbs.db
      .select()
      .from(otpCodes)
      .where(and(eq(otpCodes.phoneE164, phone), eq(otpCodes.purpose, purpose), isNull(otpCodes.consumedAt), gt(otpCodes.expiresAt, new Date())))
      .orderBy(desc(otpCodes.createdAt))
      .limit(1);
    if (!row) throw new UnauthorizedError('OTP_EXPIRED', 'Code expired or not requested. Request a new code.');
    if (row.attempts >= cfg.max_verify_attempts) {
      throw new RateLimitError('OTP_LOCKED', 'Too many wrong attempts. Request a new code.');
    }
    if (row.codeHash !== this.hash(phone, purpose, code)) {
      const [u] = await this.dbs.db
        .update(otpCodes)
        .set({ attempts: sql`${otpCodes.attempts} + 1` })
        .where(eq(otpCodes.id, row.id))
        .returning({ attempts: otpCodes.attempts });
      const left = Math.max(cfg.max_verify_attempts - u.attempts, 0);
      if (left === 0) throw new RateLimitError('OTP_LOCKED', 'Too many wrong attempts. Request a new code.');
      throw new UnauthorizedError('OTP_INVALID', 'Wrong code', { attempts_left: left });
    }
    await this.dbs.db.update(otpCodes).set({ consumedAt: new Date() }).where(eq(otpCodes.id, row.id));
  }
}
