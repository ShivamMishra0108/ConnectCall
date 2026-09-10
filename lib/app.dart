import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

class ConnectCallApp extends StatelessWidget {
  const ConnectCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ConnectCall',

      theme: AppTheme.light,

      home: const SplashScreen(),
    );
  }
}