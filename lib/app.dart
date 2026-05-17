import 'package:flutter/material.dart';

import 'package:mycondo/app_routes.dart';
import 'package:mycondo/theme/app_theme.dart';

import 'package:mycondo/services/shared/session_timer_service.dart';

class MyCondoApp extends StatelessWidget {
  const MyCondoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        // This detects EVERY tap in the app and resets the timer
        SessionTimerService().resetTimer();
      },
      child: MaterialApp(
        navigatorKey: SessionTimerService().navigatorKey,
        title: 'myCondo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: '/',
        routes: AppRoutes.routes,
      ),
    );
  }
}
