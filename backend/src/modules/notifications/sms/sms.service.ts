import { Inject, Injectable } from '@nestjs/common';
import { DbService } from '../../../infra/db/db.service';
import { smsLog } from '../../../infra/db/schema';
import { SMS_PROVIDER, SmsMessage, SmsProvider, SmsResult } from './sms.provider';

/** Sends an SMS through the configured provider and records it in sms_log. */
@Injectable()
export class SmsService {
  constructor(
    @Inject(SMS_PROVIDER) private readonly provider: SmsProvider,
    private readonly dbs: DbService,
  ) {}

  get providerName() {
    return this.provider.name;
  }

  async send(msg: SmsMessage): Promise<SmsResult> {
    let result: SmsResult;
    try {
      result = await this.provider.send(msg);
    } catch (e) {
      result = { ok: false, error: (e as Error).message };
    }
    await this.dbs.db
      .insert(smsLog)
      .values({
        phoneE164: msg.to,
        provider: this.provider.name,
        purpose: msg.purpose,
        status: result.ok ? 'sent' : 'failed',
        providerRef: result.providerRef ?? null,
        costCents: result.costCents ?? null,
        error: result.error ?? null,
      })
      .catch(() => undefined);
    return result;
  }
}
