import { Inject, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { and, eq, isNull } from 'drizzle-orm';
import { ENV, Env } from '../../config/env';
import { DbService } from '../../infra/db/db.service';
import { RedisService } from '../../infra/redis/redis.service';
import { devices, sessions, users } from '../../infra/db/schema';
import { randomToken, sha256 } from '../../common/utils/ids';
import { UnauthorizedError } from '../../common/errors/app-error';
import { UserRole } from '../../common/decorators/auth.decorators';

export interface AccessClaims {
  sub: string;
  role: UserRole;
  sid: string;
  did?: string;
  lang: 'so' | 'en';
}

export interface TokenPair {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  session_id: string;
}

@Injectable()
export class TokenService {
  constructor(
    @Inject(ENV) private readonly env: Env,
    private readonly jwt: JwtService,
    private readonly dbs: DbService,
    private readonly redis: RedisService,
  ) {}

  async issue(user: { id: string; role: UserRole; language: 'so' | 'en' }, deviceId: string | null, meta: { ip?: string; userAgent?: string } = {}): Promise<TokenPair> {
    const refresh = randomToken(48);
    const [session] = await this.dbs.db
      .insert(sessions)
      .values({
        userId: user.id,
        deviceId,
        refreshTokenHash: sha256(refresh),
        expiresAt: new Date(Date.now() + this.env.JWT_REFRESH_TTL_S * 1000),
        ip: meta.ip ?? null,
        userAgent: meta.userAgent?.slice(0, 300) ?? null,
      })
      .returning({ id: sessions.id });
    const claims: AccessClaims = { sub: user.id, role: user.role, sid: session.id, did: deviceId ?? undefined, lang: user.language };
    const access = await this.jwt.signAsync(claims, { expiresIn: this.env.JWT_ACCESS_TTL_S });
    return { access_token: access, refresh_token: refresh, expires_in: this.env.JWT_ACCESS_TTL_S, session_id: session.id };
  }

  async verifyAccess(token: string): Promise<AccessClaims> {
    try {
      return await this.jwt.verifyAsync<AccessClaims>(token);
    } catch {
      throw new UnauthorizedError('TOKEN_INVALID', 'Access token is invalid or expired');
    }
  }

  async isSessionRevoked(sid: string): Promise<boolean> {
    return (await this.redis.client.exists(`session:revoked:${sid}`)) === 1;
  }

  /** Rotate: the presented refresh token is revoked and a new pair issued. Reuse of a revoked token revokes every session of the user. */
  async rotate(refreshToken: string, meta: { ip?: string; userAgent?: string } = {}): Promise<{ pair: TokenPair; userId: string }> {
    const hash = sha256(refreshToken);
    const [s] = await this.dbs.db.select().from(sessions).where(eq(sessions.refreshTokenHash, hash));
    if (!s) throw new UnauthorizedError('REFRESH_INVALID', 'Refresh token is invalid');
    if (s.revokedAt) {
      await this.revokeAll(s.userId);
      throw new UnauthorizedError('REFRESH_REUSED', 'Refresh token was already used; all sessions revoked');
    }
    if (s.expiresAt < new Date()) throw new UnauthorizedError('REFRESH_EXPIRED', 'Refresh token has expired');
    const [u] = await this.dbs.db.select({ id: users.id, role: users.role, language: users.language, status: users.status }).from(users).where(eq(users.id, s.userId));
    if (!u || u.status !== 'active') throw new UnauthorizedError('ACCOUNT_INACTIVE', 'Account is not active');
    await this.revoke(s.id);
    if (s.deviceId) await this.dbs.db.update(devices).set({ lastActiveAt: new Date() }).where(eq(devices.id, s.deviceId));
    const pair = await this.issue(u, s.deviceId, meta);
    return { pair, userId: u.id };
  }

  async revoke(sessionId: string) {
    await this.dbs.db.update(sessions).set({ revokedAt: new Date() }).where(and(eq(sessions.id, sessionId), isNull(sessions.revokedAt)));
    await this.redis.client.set(`session:revoked:${sessionId}`, '1', 'EX', this.env.JWT_ACCESS_TTL_S + 60);
  }

  async revokeAll(userId: string) {
    const rows = await this.dbs.db
      .update(sessions)
      .set({ revokedAt: new Date() })
      .where(and(eq(sessions.userId, userId), isNull(sessions.revokedAt)))
      .returning({ id: sessions.id });
    if (rows.length) {
      const pipe = this.redis.client.pipeline();
      for (const r of rows) pipe.set(`session:revoked:${r.id}`, '1', 'EX', this.env.JWT_ACCESS_TTL_S + 60);
      await pipe.exec();
    }
  }
}
