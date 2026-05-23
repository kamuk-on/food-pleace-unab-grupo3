import 'package:flutter/foundation.dart';

enum AppEnvironment { development, staging, production }

AppEnvironment resolveAppEnvironment() {
  const String rawEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  switch (rawEnvironment) {
    case 'production':
      return AppEnvironment.production;
    case 'staging':
      return AppEnvironment.staging;
    default:
      return AppEnvironment.development;
  }
}

extension AppEnvironmentX on AppEnvironment {
  static AppEnvironment get current => resolveAppEnvironment();

  String get label {
    switch (this) {
      case AppEnvironment.development:
        return 'development';
      case AppEnvironment.staging:
        return 'staging';
      case AppEnvironment.production:
        return 'production';
    }
  }

  String get baseUrl {
    const String configuredBaseUrl = String.fromEnvironment(
      'FOODPLEASE_API_BASE_URL',
      defaultValue: '',
    );
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    switch (this) {
      case AppEnvironment.development:
        return _developmentBaseUrl;
      case AppEnvironment.staging:
        return 'https://staging.foodplease.app/api/v1';
      case AppEnvironment.production:
        return 'https://foodplease.app/api/v1';
    }
  }

  Duration get connectTimeout {
    switch (this) {
      case AppEnvironment.development:
        return const Duration(seconds: 8);
      case AppEnvironment.staging:
      case AppEnvironment.production:
        return const Duration(seconds: 12);
    }
  }

  Duration get receiveTimeout {
    switch (this) {
      case AppEnvironment.development:
        return const Duration(seconds: 12);
      case AppEnvironment.staging:
      case AppEnvironment.production:
        return const Duration(seconds: 20);
    }
  }
}

String get _developmentBaseUrl {
  if (kIsWeb) {
    return 'http://127.0.0.1:5000/api/v1';
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://10.0.2.2:5000/api/v1';
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return 'http://127.0.0.1:5000/api/v1';
  }
}
