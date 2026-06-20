/// App environment configuration.
///
/// Override the API base at build/run time:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
///
/// Defaults:
///  - Android emulator reaches host machine via 10.0.2.2
///  - iOS simulator / desktop / web use localhost
class Env {
  Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// Shown on the OTP screen in dev so testers know the mock code.
  static const bool showDevOtpHint = bool.fromEnvironment(
    'SHOW_DEV_OTP',
    defaultValue: true,
  );
}
