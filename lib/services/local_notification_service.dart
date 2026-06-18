import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'rapilead_notifications';
  static const _channelName = 'RapiLead Notifications';

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Tegucigalpa'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    // Mostrar banner cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      show(
        title: message.notification?.title,
        body: message.notification?.body,
      );
    });
  }

  static Future<void> show({
    String? title,
    String? body,
    bool scheduled = false,
    DateTime? scheduledDate,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    if (scheduled) {
      final when = tz.TZDateTime.now(tz.local).add(
        const Duration(seconds: 5),
      );

      try {
        // Intentar con alarmas exactas (funciona en Android 12-13,
        // requiere permiso SCHEDULE_EXACT_ALARM en Android 14+)
        await _plugin.zonedSchedule(
          0,
          title ?? '',
          body ?? '',
          when,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        try {
          // Fallback: intentar con alarma inexacta
          await _plugin.zonedSchedule(
            0,
            title ?? '',
            body ?? '',
            when,
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (_) {
          // Último fallback: notificación inmediata
          await _plugin.show(0, title ?? '', body ?? '', details);
        }
      }
    } else {
      await _plugin.show(0, title ?? '', body ?? '', details);
    }
  }
}
