export interface SmsMessage {
  to: string; // E.164
  text: string;
  purpose: string; // otp_login | otp_recipient | notification …
}
export interface SmsResult {
  ok: boolean;
  providerRef?: string;
  error?: string;
  costCents?: number;
}

/** Abstraction over SMS gateways. Real providers are selected by SMS_PROVIDER. */
export interface SmsProvider {
  readonly name: string;
  send(msg: SmsMessage): Promise<SmsResult>;
}
export const SMS_PROVIDER = Symbol('SMS_PROVIDER');
