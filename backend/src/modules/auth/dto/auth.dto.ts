import { createZodDto } from 'nestjs-zod';
import { z } from 'zod';

export const phoneSchema = z.string().min(7).max(20).describe('Phone in E.164, e.g. +252905000103');

export const deviceSchema = z.object({
  platform: z.enum(['android', 'ios', 'web']),
  name: z.string().max(120).optional(),
  push_token: z.string().max(512).optional(),
  app_version: z.string().max(40).optional(),
});

export class OtpRequestDto extends createZodDto(
  z.object({
    phone: phoneSchema,
    purpose: z.enum(['login', 'account_deletion', 'account_recovery']).default('login'),
    role: z.enum(['customer', 'driver']).default('customer'),
  }),
) {}

export class OtpVerifyDto extends createZodDto(
  z.object({
    phone: phoneSchema,
    code: z.string().regex(/^\d{4,8}$/),
    device: deviceSchema.default({ platform: 'android' }),
  }),
) {}

export class RefreshDto extends createZodDto(z.object({ refresh_token: z.string().min(20) })) {}
export class LogoutDto extends createZodDto(z.object({ all_devices: z.boolean().optional() })) {}
export class AdminLoginDto extends createZodDto(
  z.object({ email: z.string().email(), password: z.string().min(1), totp: z.string().optional() }),
) {}
