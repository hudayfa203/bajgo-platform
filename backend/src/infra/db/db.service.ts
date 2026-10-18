import { Inject, Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { drizzle, PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import { ENV, Env } from '../../config/env';
import * as schema from './schema';

export type Db = PostgresJsDatabase<typeof schema>;
export type Tx = Parameters<Parameters<Db['transaction']>[0]>[0];
export type DbOrTx = Db | Tx;

@Injectable()
export class DbService implements OnModuleDestroy {
  private readonly logger = new Logger('Db');
  readonly client: postgres.Sql;
  readonly db: Db;

  constructor(@Inject(ENV) env: Env) {
    this.client = postgres(env.DATABASE_URL, {
      max: env.APP_ENV === 'test' ? 4 : 10,
      idle_timeout: 30,
      onnotice: () => {},
      transform: { undefined: null },
    });
    this.db = drizzle(this.client, { schema });
  }

  async ping(): Promise<boolean> {
    try {
      await this.client`select 1`;
      return true;
    } catch (e) {
      this.logger.warn(`db ping failed: ${(e as Error).message}`);
      return false;
    }
  }

  async onModuleDestroy() {
    await this.client.end({ timeout: 2 });
  }
}
