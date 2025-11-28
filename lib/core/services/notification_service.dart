import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('📱 Notification tapped: ${response.payload}');
    // TODO: Navigate to specific page based on payload
  }

  // Notifikasi untuk pasien berhasil teregistrasi
  Future<void> showPatientRegisteredNotification({
    required String patientName,
    required String noRm,
    required String visitDate,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'patient_registration',
      'Registrasi Pasien',
      channelDescription: 'Notifikasi untuk registrasi pasien baru',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF004B8C),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '✅ Pasien Berhasil Teregistrasi',
      '$patientName ($noRm) - Kunjungan: $visitDate',
      details,
      payload: 'patient_registered:$noRm',
    );
  }

  // Notifikasi pengingat kunjungan
  Future<void> showVisitReminderNotification({
    required String patientName,
    required String visitTime,
    required String address,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'visit_reminder',
      'Pengingat Kunjungan',
      channelDescription: 'Notifikasi pengingat untuk kunjungan pasien',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF004B8C),
      playSound: true,
      enableVibration: true,
      ticker: 'Pengingat Kunjungan',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🏥 Pengingat Kunjungan',
      '$patientName - $visitTime\n📍 $address',
      details,
      payload: 'visit_reminder:$patientName',
    );
  }

  // Schedule notifikasi pengingat (1 jam sebelum kunjungan)
  Future<void> scheduleVisitReminder({
    required int id,
    required String patientName,
    required DateTime visitDateTime,
    required String visitTime,
    required String address,
  }) async {
    final scheduledDate = visitDateTime.subtract(const Duration(hours: 1));

    // Jangan schedule jika waktu sudah lewat
    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'scheduled_visit_reminder',
      'Pengingat Kunjungan Terjadwal',
      channelDescription: 'Notifikasi pengingat kunjungan yang dijadwalkan',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF004B8C),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      '⏰ Kunjungan dalam 1 jam',
      '$patientName - $visitTime\n📍 $address',
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'scheduled_visit:$id',
    );
  }

  // Notifikasi untuk anamnesa belum diisi
  Future<void> showAnamnesaReminderNotification({
    required String patientName,
    required String noRm,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'anamnesa_reminder',
      'Pengingat Anamnesa',
      channelDescription: 'Notifikasi pengingat untuk mengisi anamnesa',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFF59E0B),
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '📋 Anamnesa Belum Diisi',
      '$patientName ($noRm) - Mohon lengkapi data anamnesa',
      details,
      payload: 'anamnesa_reminder:$noRm',
    );
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
