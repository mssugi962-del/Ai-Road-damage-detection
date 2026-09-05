import 'package:flutter/material.dart';

import 'screens/app_shell.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const RoadDamageApp());
}

class RoadDamageApp extends StatelessWidget {
  const RoadDamageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Road Damage Detection',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      onGenerateRoute: (settings) {
        final builder = switch (settings.name) {
          AppShell.routeName => (_) => const AppShell(),
          _ => (_) => const SplashScreen(),
        };

        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}
