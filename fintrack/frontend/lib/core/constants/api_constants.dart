import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Determine appropriate default host based on runtime platform
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    try {
      if (Platform.isAndroid) {
        // Android emulator loopback address
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://localhost:8000';
  }

  // Auth endpoints
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String me = '/api/auth/me';

  // Transactions endpoints
  static const String transactions = '/api/transactions';

  // Analytics endpoints
  static const String analyticsSummary = '/api/analytics/summary';
  static const String analyticsMonthly = '/api/analytics/monthly';
  static const String analyticsCategories = '/api/analytics/categories';

  // Categories endpoint
  static const String categories = '/api/categories';
}
