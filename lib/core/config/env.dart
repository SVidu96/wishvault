class Env {
  static const String tmdbV3Key = String.fromEnvironment(
    'TMDB_V3_KEY',
    defaultValue: '',
  );
  static const String tmdbV4Token = String.fromEnvironment(
    'TMDB_V4_TOKEN',
    defaultValue: '',
  );
  static const String appDomain = String.fromEnvironment(
    'APP_DOMAIN',
    defaultValue: 'svidu96dev.vercel.app',
  );
  static const String appScheme = String.fromEnvironment(
    'APP_SCHEME',
    defaultValue: 'https',
  );

  static String get movieDetailBaseUrl => '$appScheme://$appDomain/movie';

  static bool get isConfigured =>
      tmdbV3Key.isNotEmpty && tmdbV4Token.isNotEmpty;
}
