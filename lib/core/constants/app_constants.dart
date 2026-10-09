class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Shaurya TMT Sales';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'B2B Distributor & Dealer Management Portal';

  // Networking ------------------------------------------------------------
  /// Flip to `false` once the real backend is available - the mock interceptor
  /// is then bypassed and the same repository code talks to the live API.
  static const bool useMockApi = true;

  static const String baseUrl = 'http://167.71.227.184/api/v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  static const String loginEndpoint = '/auth/login';
  static const String usersEndpoint = '/users';
  static const String punchesEndpoint = '/punches';
  static const String visitsEndpoint = '/visits';
  static const String ordersEndpoint = '/orders';
  static const String productsEndpoint = '/products';
  static const String teamActivityEndpoint = '/team/activity';

  static String userHomeCoordinatesEndpoint(String userId) =>
      '/users/$userId/home-coordinates';

  // DRF token auth header format: 'Authorization: Token <token>'
  static const String authHeaderKey = 'Authorization';
  static const String authScheme = 'Token';

  // Local storage keys -----------------------------------------------------
  static const String sessionBox = 'session_box';
  static const String usersBox = 'users_box';
  static const String punchesBox = 'punches_box';
  static const String visitsBox = 'visits_box';
  static const String ordersBox = 'orders_box';
  static const String productsBox = 'products_box';
  static const String syncQueueBox = 'sync_queue_box';
  static const String teamCacheBox = 'team_cache_box';
  static const String metaBox = 'meta_box';

  static const String authTokenKey = 'auth_token';
  static const String currentUserIdKey = 'current_user_id';
  static const String seededFlagKey = 'seeded_v1';

  // Roles ------------------------------------------------------------------
  static const String roleSalesManager = 'salesManager';
  static const String roleTeamLead = 'teamLead';
  static const String roleSeniorSalesExecutive = 'seniorSalesExecutive';
  static const String roleSalesExecutive = 'salesExecutive';

  static const String kindInternal = 'internal';
  static const String kindExternal = 'external';

  // Demo credentials --------------------------------------------------------
  static const String demoPassword = 'demo123';

  // UI -----------------------------------------------------------------------
  static const double defaultBorderRadius = 16.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 24.0;

  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);

  // Sync ---------------------------------------------------------------------
  static const Duration syncDebounce = Duration(seconds: 2);
  static const int syncMaxRetries = 5;
  static const Duration syncRetryBackoff = Duration(seconds: 5);
}
