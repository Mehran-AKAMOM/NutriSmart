import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Daily reminder notifications (meals + water), scheduled on the device.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'nutrismart_reminders',
    'Reminders',
    channelDescription: 'Meal and water reminders from NutriSmart',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings);
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  /// Asks for notification permission (Android 13+). Returns true if allowed.
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  /// Replaces all scheduled reminders with [reminders].
  Future<void> scheduleDaily(List<Reminder> reminders) async {
    await init();
    if (!_ready) return;
    await _plugin.cancelAll();
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        r.id,
        r.title,
        r.body,
        _nextInstanceOf(r.time),
        const NotificationDetails(android: _channel),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      );
    }
  }

  Future<void> cancelAll() async {
    await init();
    if (_ready) await _plugin.cancelAll();
  }

  Future<void> showTest() async {
    await init();
    if (!_ready) return;
    await _plugin.show(
      999,
      'NutriSmart reminders are on ✅',
      'You will get your meal and water reminders at the times you chose.',
      const NotificationDetails(android: _channel),
    );
  }

  /// The next time the clock shows [t] (today if still ahead, else tomorrow).
  /// We convert the local time to UTC so no timezone database lookup is needed
  /// (Kenya has no daylight saving, so the UTC time is the same every day).
  tz.TZDateTime _nextInstanceOf(TimeOfDay t) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return tz.TZDateTime.from(next.toUtc(), tz.UTC);
  }
}

class Reminder {
  final int id;
  final String title;
  final String body;
  final TimeOfDay time;
  const Reminder(this.id, this.title, this.body, this.time);
}
