import { Inject, Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';
import { ENV, Env } from '../../config/env';

@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly logger = new Logger('Redis');
  readonly client: Redis;
  private readonly extra: Redis[] = [];

  constructor(@Inject(ENV) private readonly env: Env) {
    this.client = new Redis(env.REDIS_URL, { maxRetriesPerRequest: 3, lazyConnect: false, enableOfflineQueue: true });
    this.client.on('error', (e) => this.logger.warn(`redis error: ${e.message}`));
  }

  /** Dedicated connection (subscribers, BullMQ, socket adapter need their own). */
  duplicate(opts: Record<string, unknown> = {}): Redis {
    const c = new Redis(this.env.REDIS_URL, { maxRetriesPerRequest: null, ...opts });
    c.on('error', (e) => this.logger.warn(`redis error: ${e.message}`));
    this.extra.push(c);
    return c;
  }

  async ping(): Promise<boolean> {
    try {
      return (await this.client.ping()) === 'PONG';
    } catch {
      return false;
    }
  }

  /** Fixed-window counter used for rate limits. Returns the count after increment. */
  async hit(key: string, windowS: number): Promise<number> {
    const n = await this.client.incr(key);
    if (n === 1) await this.client.expire(key, windowS);
    return n;
  }

  async getJson<T>(key: string): Promise<T | null> {
    const v = await this.client.get(key);
    return v ? (JSON.parse(v) as T) : null;
  }
  async setJson(key: string, value: unknown, ttlS?: number) {
    const s = JSON.stringify(value);
    if (ttlS) await this.client.set(key, s, 'EX', ttlS);
    else await this.client.set(key, s);
  }

  async onModuleDestroy() {
    await Promise.allSettled([this.client.quit(), ...this.extra.map((c) => c.quit())]);
  }
}
