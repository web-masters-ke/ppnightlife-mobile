class AppConstants {
  static const String appName = 'PartyPeople';
  static const String baseUrl = 'https://api.partypeople.com/v1';
  static const String wsUrl = 'wss://api.partypeople.com/ws';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String onboardingKey = 'onboarding_done';

  // User roles
  static const String rolePartyGoer = 'party_goer';
  static const String roleVenueOwner = 'venue_owner';
  static const String roleAdvertiser = 'advertiser';
  static const String roleDJ = 'dj';
}
