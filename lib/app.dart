import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'providers/incoming_call_provider.dart';
import 'screens/splash/splash_screen.dart';


class ConnectCallApp extends ConsumerWidget {
  const ConnectCallApp({super.key});

  @override
  Widget build(
  BuildContext context,
  WidgetRef ref,
) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'ConnectCall',
  theme: AppTheme.light,
  navigatorKey: ref.read(navigatorKeyProvider),
  home: const SplashScreen(),
);
  }
}