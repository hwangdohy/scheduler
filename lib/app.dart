import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/diary/diary_screen.dart';
import 'screens/root/main_shell.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class TossScheduleApp extends StatefulWidget {
  const TossScheduleApp({super.key});

  @override
  State<TossScheduleApp> createState() => _TossScheduleAppState();
}

class _TossScheduleAppState extends State<TossScheduleApp> {
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    NotificationService.instance.onNotificationTap = _handleNotificationTap;
    _settings.load();
  }

  void _handleNotificationTap(String? payload) {
    if (payload != NotificationService.diaryPayload) return;
    final today = DateTime.now();
    rootNavigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => DiaryScreen(initialDate: today),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _settings,
      child: Consumer<SettingsService>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: '위클리',
            debugShowCheckedModeBanner: false,
            navigatorKey: rootNavigatorKey,
            theme: AppTheme.light(fontScale: settings.fontSize.scale),
            locale: const Locale('ko', 'KR'),
            supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const MainShell(),
          );
        },
      ),
    );
  }
}
