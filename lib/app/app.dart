import 'package:flutter/material.dart';

import '../core/di/service_locator.dart';
import '../core/theme/app_theme.dart';

class FoodPleaseApp extends StatelessWidget {
  const FoodPleaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppServices.sessionController,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'FoodPlease',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: AppServices.router,
        );
      },
    );
  }
}
