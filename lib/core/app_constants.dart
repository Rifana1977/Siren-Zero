class AppConstants {
  // Ditto Credentials - Get these from https://portal.ditto.live
  // Navigate to your app → Settings → Get App ID and Playground Token
  static const String dittoAppId = 'dccb98d6-1012-45c8-8b07-45d466ca8e13';
  static const String dittoToken = '0f9e994c-25d6-411c-b3f0-de24a02b6abd';
  
  // Optional: Custom Auth and WebSocket URLs (leave empty for default)
  static const String dittoAuthUrl = 'https://dccb98d6-1012-45c8-8b07-45d466ca8e13.cloud.dittolive.app'; // e.g., 'https://your-auth.ditto.live'
  static const String dittoWebSocketUrl = 'wss://dccb98d6-1012-45c8-8b07-45d466ca8e13.cloud.dittolive.app'; // e.g., 'wss://your-ws.ditto.live'
  
  // Set to true to enable offline-only mode (no cloud sync)
  static const bool dittoOfflineOnly = false;
}
