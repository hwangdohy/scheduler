import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the daily "write your diary" reminder and routes taps on
/// that notification to the diary screen via [onDiaryNotificationTap].
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  static const int _diaryReminderId = 1001;
  static const String diaryPayload = 'open_diary_today';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Set by the app root; called with the payload when a notification
  /// is tapped so navigation can happen after the app is ready.
  ValueChanged<String?>? onNotificationTap;

  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(_deviceLocation());

    // No local-notification implementation exists for web.
    if (kIsWeb) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  Future<void> scheduleDailyDiaryReminder(TimeOfDay time) async {
    if (kIsWeb) return;
    await _plugin.zonedSchedule(
      _diaryReminderId,
      '오늘 하루 어땠나요?',
      '오늘의 일기를 남기고 AI 요약을 받아보세요.',
      _nextInstanceOf(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'diary_reminder',
          '일기 작성 알림',
          channelDescription: '설정한 시간에 오늘의 일기 작성을 알려줍니다.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: diaryPayload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDiaryReminder() async {
    if (kIsWeb) return;
    await _plugin.cancel(_diaryReminderId);
  }

  /// The `timezone` package has no direct device-timezone API, so this
  /// matches the device's current UTC offset against the IANA database
  /// (good enough for a fixed daily local-time reminder).
  tz.Location _deviceLocation() {
    final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (location.currentTimeZone.offset == offsetMs) {
        return location;
      }
    }
    return tz.UTC;
  }

  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
