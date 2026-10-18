/// Build-time configuration. Values are injected with `--dart-define`, e.g.
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/v1 \
///             --dart-define=WS_URL=http://10.0.2.2:4000/rt \
///             --dart-define=APP_ENV=dev --dart-define=USE_MOCK=true
/// ```
///
/// The app never holds provider keys: map tiles come from [tileUrl] (OSM by
/// default) and routing/geocoding are proxied by the API.
class Env {
  Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/v1',
  );

  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'http://10.0.2.2:4000/rt',
  );

  static const String tileUrl = String.fromEnvironment(
    'TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// `dev` | `staging` | `production`.
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static const bool isProduction = appEnv == 'production';

  /// When true the whole workflow runs against the in-memory [MockApi]
  /// (incoming offers every ~40 s, local state machine). Defaults to true in
  /// `dev` and is compiled out of production builds.
  static const bool _useMockFlag = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: appEnv == 'dev',
  );

  /// Set by the demo APK build (`--dart-define=DEMO=true`). Forces the whole
  /// app onto the on-device simulated backend: no server, nothing real.
  static const bool demo = bool.fromEnvironment('DEMO', defaultValue: true);

  static const bool useMock = (demo || _useMockFlag) && !isProduction;

  /// Shown on the account screen; bumped by the release process.
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.1.0',
  );

  /// Support phone: placeholder until the operations number is confirmed.
  static const String supportPhone = String.fromEnvironment(
    'SUPPORT_PHONE',
    defaultValue: '+252[number]',
  );

  static const String handbookUrl = String.fromEnvironment(
    'HANDBOOK_URL',
    defaultValue: 'https://baj-go.com/drivers',
  );

  static const String userAgentPackage = 'com.bajgo.driver';
}
