/**
 * Bilingual notification templates. Somali first (default language), English second.
 * Tone follows packages/brand/messaging.json: short sentences, warm, prices up front.
 * NEW SOMALI STRINGS — flagged for native review in the build report.
 */
export type Lang = 'so' | 'en';
export interface Template {
  title: Record<Lang, string>;
  body: Record<Lang, string>;
}

export const TEMPLATES = {
  'booking.searching': {
    title: { so: 'Waan raadineynaa', en: 'Finding your Bajaaj' },
    body: { so: 'Waxaan kuu raadineynaa Bajaaj kuu dhow.', en: 'We are finding a Bajaaj near you.' },
  },
  'booking.accepted': {
    title: { so: 'Darawal waa la helay', en: 'Driver found' },
    body: { so: '{driver} wuu soo socdaa. Bajaaj {fleet_code}.', en: '{driver} is on the way. Bajaaj {fleet_code}.' },
  },
  'driver.arriving': {
    title: { so: 'Darawalkaagu wuu soo dhowaaday', en: 'Driver arriving' },
    body: { so: 'Darawalkaagu wuu kuu soo dhowaanayaa. Diyaar noqo.', en: 'Your driver is almost there. Please be ready.' },
  },
  'driver.arrived': {
    title: { so: 'Darawalkaagu wuu yimid', en: 'Driver arrived' },
    body: { so: 'Darawalkaagu wuu yimid. Bajaaj {fleet_code}.', en: 'Your driver has arrived. Bajaaj {fleet_code}.' },
  },
  'trip.started': {
    title: { so: 'Safarku wuu bilaabmay', en: 'Trip started' },
    body: { so: 'Safarkaagu wuu bilaabmay. Safar wanaagsan!', en: 'Your trip has started. Have a good trip!' },
  },
  'trip.completed': {
    title: { so: 'Waad gaartay', en: 'You have arrived' },
    body: { so: 'Waad gaartay. Qiimaha: {fare}. Mahadsanid, BajGo.', en: 'You have arrived. Fare: {fare}. Thank you for riding with BajGo.' },
  },
  'delivery.collected': {
    title: { so: 'Xirmada waa la qaaday', en: 'Package collected' },
    body: { so: 'Xirmadaada waa la qaaday, wuu kuu socdaa.', en: 'Your package has been collected and is on its way.' },
  },
  'delivery.delivered': {
    title: { so: 'Xirmada waa la gaarsiiyay', en: 'Package delivered' },
    body: { so: 'Xirmadaada waa la gaarsiiyay. Qiimaha: {fare}. Mahadsanid.', en: 'Your package has been delivered. Fare: {fare}. Thank you.' },
  },
  'booking.cancelled': {
    title: { so: 'Dalabka waa la joojiyay', en: 'Booking cancelled' },
    body: { so: 'Dalabka {reference} waa la joojiyay. {reason}', en: 'Booking {reference} was cancelled. {reason}' },
  },
  'booking.expired': {
    title: { so: 'Darawal lama helin', en: 'No driver found' },
    body: { so: 'Nasiib darro, darawal lama helin. Fadlan mar kale isku day.', en: 'Sorry, no driver was found. Please try again.' },
  },
  'payment.received': {
    title: { so: 'Lacagta waa la helay', en: 'Payment received' },
    body: { so: 'Lacagta {amount} waa la helay. Mahadsanid.', en: 'Payment of {amount} received. Thank you.' },
  },
  'payout.paid': {
    title: { so: 'Lacag bixin', en: 'Payout sent' },
    body: { so: 'Lacag bixintaada {amount} waa la diray.', en: 'Your payout of {amount} has been sent.' },
  },
  'offer.new': {
    title: { so: 'Dalab cusub', en: 'New request' },
    body: { so: 'Dalab cusub: {service} {distance_km} km. Taabo si aad u aqbasho.', en: 'New request: {service} {distance_km} km. Tap to accept.' },
  },
  'delivery.failed': {
    title: { so: 'Gudbinta ma suurtagalin', en: 'Delivery not completed' },
    body: { so: 'Xirmadaada lama gaarsiin karin ({reason}). Darawalku wuu soo celinayaa.', en: 'Your package could not be delivered ({reason}). The driver is bringing it back.' },
  },
  'delivery.returned': {
    title: { so: 'Xirmada waa la soo celiyay', en: 'Package returned' },
    body: { so: 'Xirmadaada waa lagu soo celiyay diraha.', en: 'Your package has been returned to the sender.' },
  },
  'otp.login': {
    title: { so: 'BajGo', en: 'BajGo' },
    body: { so: 'Koodhkaaga BajGo waa {code}. Ha la wadaagin cidna.', en: 'Your BajGo code is {code}. Do not share it with anyone.' },
  },
  'otp.recipient': {
    title: { so: 'BajGo Delivery', en: 'BajGo Delivery' },
    body: {
      so: 'Xirmo ayaa kuu socota BajGo. Koodhka gudbinta: {code}. Sii darawalka marka uu yimaado.',
      en: 'A BajGo package is on its way to you. Handover code: {code}. Give it to the driver on arrival.',
    },
  },
  'otp.account_deletion': {
    title: { so: 'BajGo', en: 'BajGo' },
    body: { so: 'Koodhka tirtirista xisaabta BajGo: {code}.', en: 'BajGo account deletion code: {code}.' },
  },
} satisfies Record<string, Template>;

export type TemplateKey = keyof typeof TEMPLATES;

export function render(key: TemplateKey, lang: Lang, data: Record<string, unknown> = {}): { title: string; body: string } {
  const t = TEMPLATES[key];
  const fill = (s: string) =>
    s.replace(/\{(\w+)\}/g, (_, k) => (data[k] === undefined || data[k] === null ? '' : String(data[k]))).replace(/\s+\./g, '.').trim();
  return { title: fill(t.title[lang] ?? t.title.so), body: fill(t.body[lang] ?? t.body.so) };
}

export const formatUsd = (cents: number) => `$${(cents / 100).toFixed(2)}`;
