import { Injectable } from '@nestjs/common';
import { DbService, DbOrTx } from '../../infra/db/db.service';
import { auditLogs } from '../../infra/db/schema';

export interface AuditActor {
  id?: string | null;
  role?: string | null;
  ip?: string | null;
  userAgent?: string | null;
}

export interface AuditEntry {
  action: string; // pricing.create, driver.approve, booking.assign …
  entityType?: string;
  entityId?: string | null;
  before?: unknown;
  after?: unknown;
}

/** Every mutating admin / verification / finance action is written here. */
@Injectable()
export class AuditService {
  constructor(private readonly dbs: DbService) {}

  async log(actor: AuditActor, entry: AuditEntry, tx?: DbOrTx) {
    const db = tx ?? this.dbs.db;
    await db.insert(auditLogs).values({
      actorId: actor.id ?? null,
      actorRole: actor.role ?? null,
      action: entry.action,
      entityType: entry.entityType ?? null,
      entityId: entry.entityId ?? null,
      before: entry.before ?? null,
      after: entry.after ?? null,
      ip: actor.ip ?? null,
      userAgent: actor.userAgent ?? null,
    });
  }
}
