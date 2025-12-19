import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  Future<void> scheduleVisitReminder({
    required int registrasiId,
    required String patientName,
    required String address,
    required DateTime visitTime,
  }) async {
    // Schedule notification 1 hour before visit
    final reminderTime = visitTime.subtract(const Duration(hours: 1));
    
    // Only schedule if reminder time is in the future
    if (reminderTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      registrasiId, // Use registrasiId as notification ID
      '⏰ Kunjungan dalam 1 jam!',
      'Pasien: $patientName\n📍 $address',
      tz.TZDateTime.from(reminderTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'visit_reminders',
          'Pengingat Kunjungan',
          channelDescription: 'Notifikasi pengingat kunjungan pasien',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelVisitReminder(int registrasiId) async {
    await _notifications.cancel(registrasiId);
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notifications',
          'Notifikasi Instant',
          channelDescription: 'Notifikasi langsung untuk update penting',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> showPatientRegisteredNotification({
    required String patientName,
    required String noRm,
    required String visitDate,
  }) async {
    await showInstantNotification(
      title: '✅ Registrasi Berhasil',
      body: 'Pasien $patientName ($noRm) terdaftar untuk kunjungan $visitDate',
    );
  }
}
