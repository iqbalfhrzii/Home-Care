# Sistem Notifikasi Home Care

## Fitur Notifikasi

Aplikasi Home Care sekarang memiliki sistem notifikasi lengkap yang mencakup:

### 1. Notifikasi Registrasi Pasien

- **Trigger**: Otomatis muncul saat pasien berhasil teregistrasi
- **Konten**: Nama pasien, No. RM, dan tanggal kunjungan
- **Icon**: ✅ (Checkmark hijau)
- **Tipe**: Immediate notification

### 2. Pengingat Kunjungan Terjadwal

- **Trigger**: Otomatis dijadwalkan 1 jam sebelum waktu kunjungan
- **Konten**: Nama pasien, jam kunjungan, dan alamat
- **Icon**: ⏰ (Alarm clock)
- **Tipe**: Scheduled notification

### 3. Pengingat Anamnesa

- **Trigger**: Muncul untuk kunjungan yang belum diisi anamnesa
- **Konten**: Nama pasien, No. RM, dan status
- **Icon**: 📋 (Clipboard)
- **Tipe**: On-demand notification

### 4. Notifikasi di Home Page

- **Kunjungan Hari Ini**: Menampilkan pasien yang dijadwalkan hari ini
- **Anamnesa Belum Diisi**: Menampilkan kunjungan yang perlu dilengkapi
- **Auto-refresh**: Data notifikasi ter-update saat home page dibuka

## Implementasi Teknis

### Package yang Digunakan

```yaml
dependencies:
  flutter_local_notifications: ^18.0.1
  timezone: ^0.9.4
```

### Service Class

- **NotificationService**: Singleton service untuk manage semua notifikasi
- **Lokasi**: `lib/core/services/notification_service.dart`
- **Inisialisasi**: Otomatis saat app startup melalui `app_injections.dart`

### Android Permissions

Sudah ditambahkan di `AndroidManifest.xml`:

- `POST_NOTIFICATIONS` - Untuk menampilkan notifikasi
- `VIBRATE` - Untuk getaran
- `RECEIVE_BOOT_COMPLETED` - Untuk restore scheduled notifications setelah restart
- `SCHEDULE_EXACT_ALARM` - Untuk notifikasi terjadwal yang tepat waktu
- `USE_EXACT_ALARM` - Alternative untuk Android 14+

### Channels yang Dibuat

1. **patient_registration** - Notifikasi registrasi pasien
2. **visit_reminder** - Pengingat kunjungan
3. **scheduled_visit_reminder** - Pengingat kunjungan terjadwal
4. **anamnesa_reminder** - Pengingat anamnesa

## Cara Penggunaan

### 1. Notifikasi Otomatis saat Registrasi

Tidak perlu kode tambahan. Otomatis muncul saat pasien berhasil teregistrasi di `registration_form_page.dart`:

```dart
// Otomatis dipanggil setelah insertRegistrasi berhasil
await notificationService.showPatientRegisteredNotification(
  patientName: patient.nama,
  noRm: patient.noRm,
  visitDate: DateFormat('d MMMM yyyy', 'id_ID').format(_tanggalKunjungan),
);
```

### 2. Schedule Pengingat Kunjungan

Otomatis dijadwalkan saat registrasi:

```dart
await notificationService.scheduleVisitReminder(
  id: registrasiId,
  patientName: patient.nama,
  visitDateTime: visitDateTime,
  visitTime: jamKunjunganFormatted,
  address: patient.alamat,
);
```

### 3. Manual Trigger (Opsional)

Jika ingin trigger manual dari kode lain:

```dart
final notificationService = getIt<NotificationService>();

// Notifikasi registrasi
await notificationService.showPatientRegisteredNotification(
  patientName: "Budi Santoso",
  noRm: "RM-001",
  visitDate: "21 November 2025",
);

// Pengingat kunjungan
await notificationService.showVisitReminderNotification(
  patientName: "Budi Santoso",
  visitTime: "10:30",
  address: "Jl. Merdeka No. 123",
);

// Pengingat anamnesa
await notificationService.showAnamnesaReminderNotification(
  patientName: "Budi Santoso",
  noRm: "RM-001",
);
```

### 4. Cancel Notifikasi

```dart
// Cancel specific notification
await notificationService.cancelNotification(notificationId);

// Cancel all notifications
await notificationService.cancelAllNotifications();
```

### 5. Lihat Pending Notifications

```dart
final pending = await notificationService.getPendingNotifications();
for (var notif in pending) {
  print('Pending: ${notif.title} - ${notif.body}');
}
```

## Testing

### Test Notifikasi Registrasi

1. Buka halaman Patient List
2. Tap "Tambah Pasien Baru"
3. Isi data pasien
4. Klik "Simpan"
5. **Notifikasi seharusnya muncul** di notification bar

### Test Pengingat Kunjungan

1. Registrasi pasien dengan jadwal kunjungan 1.5 jam dari sekarang
2. Tunggu 30 menit
3. **Notifikasi reminder seharusnya muncul** 1 jam sebelum kunjungan

### Test Notifikasi Home Page

1. Buka Home Page
2. Lihat section "NOTIFIKASI PENTING"
3. **Seharusnya menampilkan**:
   - Kunjungan hari ini (jika ada)
   - Anamnesa yang belum diisi (jika ada)

## Troubleshooting

### Notifikasi Tidak Muncul

1. **Cek Permission**: Pastikan app memiliki izin notifikasi

   - Buka Settings > Apps > Home Care > Notifications
   - Enable "Show notifications"

2. **Cek Battery Optimization**:

   - Buka Settings > Battery > Battery Optimization
   - Pilih "All apps"
   - Cari "Home Care" dan set ke "Don't optimize"

3. **Test Manual**:
   ```dart
   await notificationService.showPatientRegisteredNotification(
     patientName: "Test User",
     noRm: "TEST-001",
     visitDate: "Test Date",
   );
   ```

### Scheduled Notification Tidak Muncul

1. Cek waktu scheduling tidak di masa lalu
2. Cek exact alarm permission (Android 12+)
3. Restart device untuk test boot receiver

### Notifikasi Hilang Setelah Restart

1. Pastikan `RECEIVE_BOOT_COMPLETED` permission ada
2. Pastikan boot receiver terdaftar di AndroidManifest.xml
3. Re-schedule notification setelah boot

## Best Practices

1. **Jangan Spam**: Batasi jumlah notifikasi per hari
2. **Timing**: Schedule notifikasi di waktu yang tepat (1 jam sebelum, bukan 5 menit)
3. **Prioritas**: Gunakan priority yang sesuai (high untuk urgent, default untuk info)
4. **Testing**: Selalu test di device fisik, emulator tidak reliable untuk notifikasi
5. **Payload**: Gunakan payload untuk navigation saat notifikasi di-tap

## Future Improvements

- [ ] Sound custom untuk setiap tipe notifikasi
- [ ] Grouped notifications untuk multiple pasien
- [ ] Action buttons di notifikasi (Lihat Detail, Batalkan, dll)
- [ ] Push notification dari server
- [ ] Notifikasi untuk reminder obat pasien
- [ ] Daily summary notification
