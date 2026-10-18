import { pgEnum } from 'drizzle-orm/pg-core';

export const userRole = pgEnum('user_role', ['customer', 'driver', 'admin']);
export const userStatus = pgEnum('user_status', ['active', 'suspended', 'deleted']);
export const language = pgEnum('language', ['so', 'en']);
export const driverVerification = pgEnum('driver_verification', ['pending', 'under_review', 'approved', 'rejected', 'suspended']);
export const driverAvailability = pgEnum('driver_availability', ['offline', 'online', 'on_trip']);
export const documentType = pgEnum('document_type', [
  'national_id', 'driving_licence', 'vehicle_registration', 'vehicle_insurance',
  'vehicle_photo_front', 'vehicle_photo_side', 'vehicle_photo_rear', 'profile_photo', 'other',
]);
export const documentStatus = pgEnum('document_status', ['pending', 'approved', 'rejected', 'expired']);
export const serviceType = pgEnum('service_type', ['ride', 'delivery']);
export const deliveryCategory = pgEnum('delivery_category', ['food', 'shopping', 'parcel', 'document', 'pharmacy', 'other']);
export const BOOKING_STATUSES = [
  'quoted', 'requested', 'searching', 'accepted', 'driver_arriving', 'arrived',
  'in_progress', 'arrived_pickup', 'collected', 'in_transit', 'arrived_dropoff', 'recipient_verified',
  'completed', 'delivered', 'paid',
  'cancelled_by_customer', 'cancelled_by_driver', 'cancelled_by_admin', 'expired', 'failed', 'returned',
] as const;
export type BookingStatus = (typeof BOOKING_STATUSES)[number];
export const bookingStatus = pgEnum('booking_status', BOOKING_STATUSES);
export const offerStatus = pgEnum('offer_status', ['pending', 'accepted', 'rejected', 'timed_out', 'withdrawn']);
export const PAYMENT_METHODS = ['cash', 'evc_plus', 'zaad', 'sahal', 'card', 'wallet', 'sandbox'] as const;
export type PaymentMethod = (typeof PAYMENT_METHODS)[number];
export const paymentMethod = pgEnum('payment_method', PAYMENT_METHODS);
export const paymentStatus = pgEnum('payment_status', ['pending', 'authorised', 'captured', 'failed', 'refunded', 'partially_refunded', 'cancelled']);
export const LEDGER_ACCOUNTS = ['customer', 'driver', 'platform_commission', 'platform_cash_clearing', 'provider_fees', 'promotions', 'refunds', 'tips', 'adjustments'] as const;
export type LedgerAccount = (typeof LEDGER_ACCOUNTS)[number];
export const ledgerAccount = pgEnum('ledger_account', LEDGER_ACCOUNTS);
export const payoutStatus = pgEnum('payout_status', ['requested', 'approved', 'paid', 'rejected', 'failed']);
export const promoType = pgEnum('promo_type', ['percent', 'fixed']);
export const notificationChannel = pgEnum('notification_channel', ['push', 'sms', 'in_app']);
export const ticketStatus = pgEnum('ticket_status', ['open', 'in_progress', 'waiting_customer', 'resolved', 'closed']);
export const ticketCategory = pgEnum('ticket_category', ['ride', 'delivery', 'payment', 'lost_item', 'incident', 'account', 'driver', 'other']);
export const otpPurpose = pgEnum('otp_purpose', ['login', 'recipient_delivery', 'account_recovery', 'account_deletion']);
export const zoneKind = pgEnum('zone_kind', ['service_area', 'surge', 'restricted']);
