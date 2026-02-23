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
  static const String googleBooksApiKey = String.fromEnvironment(
    'GOOGLE_BOOKS_API_KEY',
    defaultValue: '',
  );

  static String get itemDetailBaseUrl => '$appScheme://$appDomain/item';

  static bool get isConfigured =>
      tmdbV3Key.isNotEmpty && tmdbV4Token.isNotEmpty;
}
