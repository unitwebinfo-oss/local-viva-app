class ApiConfig {
  // Base URL da API
  static const String baseUrl = 'https://localviva.com.br/api';
  
  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  
  static const String ads = '/ads';
  static const String categories = '/categories';
  static const String favorites = '/favorites';
  static const String messages = '/messages';
  static const String user = '/user';
  static const String userPackage = '/user/package';
  static const String locations = '/locations';
  static const String boost = '/boost';
  static const String paypalBoost = '/paypal_boost';
  
  // Upload URL
  static const String uploadUrl = 'https://localviva.com.br/uploads';
  static const String imageProxyUrl = 'https://localviva.com.br/api/proxy_image.php';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
