class ApiConfig {
  /// Base URL for the landmark API
  /// Set to empty string to use local mock mode (for testing without server)
  static const String baseUrl = 'https://labs.anontech.info/cse489/t3';
  // static const String baseUrl = ''; // Uncomment to use local mock mode

  /// Main API endpoint
  static const String apiEndpoint = '/api.php';

  /// Request timeout in seconds
  static const int requestTimeout = 30;

  /// Enable debug logging
  static const bool enableLogging = true;

  /// Use local mock API instead of remote server (useful for testing)
  static const bool useLocalMockApi =
      true; // Set to true to test locally without server
}
