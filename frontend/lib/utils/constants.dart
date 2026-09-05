import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl => kIsWeb ? webBaseUrl : androidEmulatorBaseUrl;

  static const String webBaseUrl = 'http://127.0.0.1:8000';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000';

  // For a physical phone on the same Wi-Fi, replace androidEmulatorBaseUrl with:
  // static const String androidEmulatorBaseUrl = 'http://192.168.1.5:8000';
}

class AppSpacing {
  static const double screen = 20;
  static const double radius = 22;
}
