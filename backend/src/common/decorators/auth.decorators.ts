import { createParamDecorator, ExecutionContext, SetMetadata } from '@nestjs/common';

export const IS_PUBLIC = 'bajgo:public';
export const ROLES = 'bajgo:roles';
export const PERMISSIONS = 'bajgo:permissions';

export type UserRole = 'customer' | 'driver' | 'admin';

/** Authenticated principal attached to the request by JwtAuthGuard. */
export interface AuthUser {
  id: string;
  role: UserRole;
  sessionId: string;
  deviceId?: string;
  language: 'so' | 'en';
  permissions?: string[];
}

export const Public = () => SetMetadata(IS_PUBLIC, true);
export const Roles = (...roles: UserRole[]) => SetMetadata(ROLES, roles);
export const Permissions = (...perms: string[]) => SetMetadata(PERMISSIONS, perms);

export const CurrentUser = createParamDecorator((_data: unknown, ctx: ExecutionContext): AuthUser => {
  return ctx.switchToHttp().getRequest().user;
});

export const Lang = createParamDecorator((_data: unknown, ctx: ExecutionContext): 'so' | 'en' => {
  const req = ctx.switchToHttp().getRequest();
  return req.lang ?? 'so';
});
