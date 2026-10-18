/// Build-time configuration. Values come from `--dart-define`.
///
/// Demo build (what ships as BajGo-Customer-Demo.apk):
///   flutter build apk --dart-define=DEMO=true
/// Live build against a backend:
///   flutter build apk --dart-define=API_BASE_URL=https://api.baj-go.com/v1 \
///                     --dart-define=WS_URL=https://api.baj-go.com
class Env {
  const Env._();

  /// When true the app runs entirely on-device against a simulated backend.
  /// No network calls are made, no real bookings exist. Clearly labelled in the UI.
  static const bool demo = bool.fromEnvironment('DEMO', defaultValue: true);

  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:4000/v1');

  static const String wsUrl =
      String.fromEnvironment('WS_URL', defaultValue: 'http://10.0.2.2:4000');

  /// OpenStreetMap raster tiles by default. Swap for a Google/Mapbox style URL in production.
  static const String tileUrl = String.fromEnvironment(
    'TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  static const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'demo');

  static const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');

  /// Garowe city centre — the map's initial camera.
  static const double defaultLat = 8.4064;
  static const double defaultLng = 48.4847;
  static const double defaultZoom = 14.5;

  static const String countryCode = '+252';
  static const String supportEmail = 'info@baj-go.com';
  static const String website = 'https://baj-go.com';

  /// Fixed OTP accepted in demo/dev builds only. Never used when APP_ENV=production.
  static const String demoOtp = '123456';
}
