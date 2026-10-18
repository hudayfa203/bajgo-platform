import { Global, Module } from '@nestjs/common';
import { ENV, Env } from '../../config/env';
import { NotificationsService } from './notifications.service';
import { ConsolePushProvider, FcmPushProvider, PUSH_PROVIDER } from './push/push.provider';
import { ConsoleSmsProvider } from './sms/console-sms.provider';
import { HttpSmsProvider } from './sms/http-sms.provider';
import { SMS_PROVIDER } from './sms/sms.provider';
import { SmsService } from './sms/sms.service';

@Global()
@Module({
  providers: [
    {
      provide: SMS_PROVIDER,
      inject: [ENV],
      useFactory: (env: Env) =>
        env.SMS_PROVIDER === 'http' ? new HttpSmsProvider(env.SMS_HTTP_URL, env.SMS_HTTP_TOKEN, env.SMS_SENDER_ID) : new ConsoleSmsProvider(),
    },
    {
      provide: PUSH_PROVIDER,
      inject: [ENV],
      useFactory: (env: Env) => (env.PUSH_PROVIDER === 'fcm' ? new FcmPushProvider(env.FCM_SERVICE_ACCOUNT_JSON) : new ConsolePushProvider()),
    },
    SmsService,
    NotificationsService,
  ],
  exports: [SmsService, NotificationsService, SMS_PROVIDER, PUSH_PROVIDER],
})
export class NotificationsModule {}
