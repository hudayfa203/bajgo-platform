import { Injectable } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import { DbService } from '../../infra/db/db.service';
import { RedisService } from '../../infra/redis/redis.service';
import { settings } from '../../infra/db/schema';
import { SETTING_DEFAULTS, SettingKey, SettingsMap } from './settings.types';

const CACHE_TTL_S = 30;

/** Typed accessor over the settings table with a short Redis cache. */
@Injectable()
export class SettingsService {
  constructor(
    private readonly dbs: DbService,
    private readonly redis: RedisService,
  ) {}

  async get<K extends SettingKey>(key: K): Promise<SettingsMap[K]> {
    const cacheKey = `settings:${key}`;
    const cached = await this.redis.getJson<SettingsMap[K]>(cacheKey).catch(() => null);
    if (cached) return { ...SETTING_DEFAULTS[key], ...cached };
    const [row] = await this.dbs.db.select().from(settings).where(eq(settings.key, key));
    const value = { ...SETTING_DEFAULTS[key], ...((row?.value as object) ?? {}) } as SettingsMap[K];
    await this.redis.setJson(cacheKey, value, CACHE_TTL_S).catch(() => undefined);
    return value;
  }

  async set<K extends SettingKey>(key: K, value: Partial<SettingsMap[K]>, updatedBy?: string): Promise<SettingsMap[K]> {
    const current = await this.get(key);
    const next = { ...current, ...value };
    await this.dbs.db
      .insert(settings)
      .values({ key, value: next, updatedBy: updatedBy ?? null })
      .onConflictDoUpdate({ target: settings.key, set: { value: next, updatedBy: updatedBy ?? null, updatedAt: new Date() } });
    await this.redis.client.del(`settings:${key}`);
    return next;
  }

  async all(): Promise<Record<string, unknown>> {
    const rows = await this.dbs.db.select().from(settings);
    return Object.fromEntries(rows.map((r) => [r.key, r.value]));
  }

  async invalidate(key?: SettingKey) {
    if (key) await this.redis.client.del(`settings:${key}`);
    else {
      const keys = await this.redis.client.keys('settings:*');
      if (keys.length) await this.redis.client.del(...keys);
    }
  }
}
