import { Logger } from '@nestjs/common';
import { SmsMessage, SmsProvider, SmsResult } from './sms.provider';

/** Development provider: prints the message (including OTP codes) to the log. */
export class ConsoleSmsProvider implements SmsProvider {
  readonly name = 'console';
  private readonly logger = new Logger('SMS');
  async send(msg: SmsMessage): Promise<SmsResult> {
    this.logger.log(`[console-sms] to=${msg.to} purpose=${msg.purpose} text="${msg.text}"`);
    return { ok: true, providerRef: `console-${Date.now()}` };
  }
}
