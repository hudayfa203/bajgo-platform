import { Logger } from '@nestjs/common';
import { ProviderNotConfigured } from '../../../common/errors/app-error';
import { SmsMessage, SmsProvider, SmsResult } from './sms.provider';

/**
 * Generic HTTP gateway adapter: POST JSON `{ to, text, sender_id }` with a bearer token.
 * Point SMS_HTTP_URL at a local aggregator's endpoint; adjust the payload mapping here if it differs.
 */
export class HttpSmsProvider implements SmsProvider {
  readonly name = 'http';
  private readonly logger = new Logger('SMS');
  constructor(
    private readonly url: string | undefined,
    private readonly token: string | undefined,
    private readonly senderId: string,
  ) {}

  async send(msg: SmsMessage): Promise<SmsResult> {
    if (!this.url) throw new ProviderNotConfigured('HttpSmsProvider', ['SMS_HTTP_URL']);
    try {
      const res = await fetch(this.url, {
        method: 'POST',
        headers: { 'content-type': 'application/json', ...(this.token ? { authorization: `Bearer ${this.token}` } : {}) },
        body: JSON.stringify({ to: msg.to, text: msg.text, sender_id: this.senderId }),
        signal: AbortSignal.timeout(10000),
      });
      const body = (await res.json().catch(() => ({}))) as Record<string, unknown>;
      if (!res.ok) return { ok: false, error: `HTTP ${res.status}: ${JSON.stringify(body).slice(0, 200)}` };
      return { ok: true, providerRef: String(body.id ?? body.message_id ?? body.reference ?? '') };
    } catch (e) {
      this.logger.warn(`http sms failed: ${(e as Error).message}`);
      return { ok: false, error: (e as Error).message };
    }
  }
}
