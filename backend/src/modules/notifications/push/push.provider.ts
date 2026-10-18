import { Logger } from '@nestjs/common';
import { ProviderNotConfigured } from '../../../common/errors/app-error';

export interface PushMessage {
  tokens: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
}
export interface PushProvider {
  readonly name: string;
  send(msg: PushMessage): Promise<{ ok: boolean; sent: number; error?: string }>;
}
export const PUSH_PROVIDER = Symbol('PUSH_PROVIDER');

export class ConsolePushProvider implements PushProvider {
  readonly name = 'console';
  private readonly logger = new Logger('Push');
  async send(msg: PushMessage) {
    this.logger.log(`[console-push] tokens=${msg.tokens.length} title="${msg.title}" body="${msg.body}"`);
    return { ok: true, sent: msg.tokens.length };
  }
}

/**
 * Firebase Cloud Messaging adapter — STUB. Requires FCM_SERVICE_ACCOUNT_JSON and the
 * firebase-admin SDK (not installed to keep the image lean). Fails closed until configured.
 */
export class FcmPushProvider implements PushProvider {
  readonly name = 'fcm';
  constructor(private readonly serviceAccountJson?: string) {}
  async send(_msg: PushMessage): Promise<{ ok: boolean; sent: number; error?: string }> {
    if (!this.serviceAccountJson) throw new ProviderNotConfigured('FcmPushProvider', ['FCM_SERVICE_ACCOUNT_JSON']);
    throw new ProviderNotConfigured('FcmPushProvider', ['firebase-admin SDK integration (not yet implemented)']);
  }
}
