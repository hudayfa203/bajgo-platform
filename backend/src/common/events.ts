import { EventEmitter } from 'node:events';
import { Injectable } from '@nestjs/common';

/**
 * Tiny in-process domain event bus (no extra dependency). Used for loose coupling
 * between modules inside one process — e.g. the dev simulator listening for offers.
 * Cross-process fan-out goes through Redis (see realtime.publisher).
 */
export type DomainEvents = {
  'offer.created': { offerId: string; bookingId: string; driverId: string; expiresAt: string };
  'offer.withdrawn': { offerId: string; driverId: string };
  'booking.status': { bookingId: string; status: string; driverId?: string | null; customerId: string };
  'booking.recipient_code': { bookingId: string; driverId: string | null; code: string };
};

@Injectable()
export class DomainEventBus {
  private readonly ee = new EventEmitter({ captureRejections: false });
  constructor() {
    this.ee.setMaxListeners(50);
  }
  emit<K extends keyof DomainEvents>(event: K, payload: DomainEvents[K]) {
    this.ee.emit(event, payload);
  }
  on<K extends keyof DomainEvents>(event: K, handler: (p: DomainEvents[K]) => void) {
    this.ee.on(event, handler);
    return () => this.ee.off(event, handler);
  }
}
