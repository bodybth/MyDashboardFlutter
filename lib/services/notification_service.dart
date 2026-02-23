import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    // Request permission
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders', 'Task Reminders',
        channelDescription: 'Reminders for assignments',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await init();
    await _plugin.cancel(id);
  }

  static Future<void> showImmediate({required String title, required String body}) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders', 'Task Reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(0, title, body, details);
  }
}

// Helper to open system alarm clock
Future<void> openAlarmClock(BuildContext context, DateTime time, String label) async {
  // Show a dialog to guide user to set alarm manually
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Row(children: [
        Icon(Icons.alarm, color: Color(0xFF667EEA)),
        SizedBox(width: 8),
        Text('Set Alarm'),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Set this alarm on your clock app:'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('⏰ Time: ${TimeOfDay.fromDateTime(time).format(context)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text('📅 Date: ${time.day}/${time.month}/${time.year}',
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text('🏷️ Label: $label', style: const TextStyle(fontSize: 14)),
            ]),
          ),
          const SizedBox(height: 12),
          const Text('Open your Clock app and add this alarm manually.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
      ],
    ),
  );
}
