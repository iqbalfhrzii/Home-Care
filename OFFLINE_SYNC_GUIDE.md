# Offline-First Sync Implementation Guide

## Overview

Fitur offline-first telah diimplementasikan untuk memungkinkan pengguna tetap dapat menggunakan aplikasi bahkan tanpa koneksi internet. Data akan otomatis tersinkronisasi ketika koneksi internet tersedia kembali.

## Arsitektur

```
┌─────────────────────────────────────────────────────────┐
│                    USER INTERFACE                        │
│  (Input Form: Anamnesa, ICD, Tindakan)                  │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              LOCAL DATABASE (SQLite)                     │
│                                                          │
│  • Registrasis (isSynced, serverId)                     │
│  • Anamnesas (isSynced, serverId)                       │
│  • RegistrasiIcds (isSynced, serverId)                  │
│  • RegistrasiTindakans (isSynced, serverId)             │
│                                                          │
│  Master Data (seeded from API):                         │
│  • Icds                                                  │
│  • Tindakans                                             │
│  • Pasiens                                               │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                 SYNC SERVICE                             │
│                                                          │
│  Auto-sync triggers:                                     │
│  1. Connectivity change (offline → online)              │
│  2. Periodic timer (every 5 minutes)                    │
│  3. Manual trigger (tap sync widget)                    │
│                                                          │
│  Sync order:                                            │
│  Registrasi → Anamnesa → ICD → Tindakan                │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                   API SERVER                             │
│                                                          │
│  POST /registrasi/store                                 │
│  POST /anamnesa/store                                   │
│  POST /registrasi/{id}/icd/attach                       │
│  POST /registrasi/{id}/tindakan/attach                  │
└─────────────────────────────────────────────────────────┘
```

## Database Schema Changes (v7 → v8)

### Added Columns

Setiap tabel transaksi sekarang memiliki 2 kolom tambahan:

```dart
// Registrasis
BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
IntColumn get serverId => integer().nullable()(); // ID from server

// Anamnesas
BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
IntColumn get serverId => integer().nullable()();

// RegistrasiIcds
BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
IntColumn get serverId => integer().nullable()();

// RegistrasiTindakans
BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
IntColumn get serverId => integer().nullable()();
```

### Migration

```dart
@override
int get schemaVersion => 8;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) => m.createAll(),
  onUpgrade: (Migrator m, int from, int to) async {
    if (from < 8) {
      await m.addColumn(registrasis, registrasis.isSynced);
      await m.addColumn(registrasis, registrasis.serverId);
      await m.addColumn(anamnesas, anamnesas.isSynced);
      await m.addColumn(anamnesas, anamnesas.serverId);
      await m.addColumn(registrasiIcds, registrasiIcds.isSynced);
      await m.addColumn(registrasiIcds, registrasiIcds.serverId);
      await m.addColumn(registrasiTindakans, registrasiTindakans.isSynced);
      await m.addColumn(registrasiTindakans, registrasiTindakans.serverId);
    }
  },
);
```

## How It Works

### 1. **Seeding Master Data (ICD, Tindakan)**

Saat aplikasi online, master data akan di-download dari API dan disimpan ke database lokal:

```dart
// schedule_icd_pages.dart
Future<void> _fetchIcdsFromApi() async {
  final response = await _dio.get('/icds');

  // Clear old data
  await _database.deleteAllIcds();

  // Insert new data from API
  for (var item in response.data['data']) {
    await _database.insertIcd(
      IcdsCompanion(
        id: Value(item['id']),
        kode: Value(item['kode']),
        deskripsi: Value(item['deskripsi']),
        katIcd: Value(item['kat_icd']),
        isActive: Value(item['is_active']),
      ),
    );
  }
}
```

### 2. **Saving Data Offline**

Saat user mengisi form (anamnesa, ICD, tindakan), data disimpan ke database lokal dengan flag `isSynced = false`:

```dart
// Save anamnesa
await _database.insertAnamnesa(
  AnamnesasCompanion(
    registrasiId: Value(widget.registrationId),
    pengkajianKeperawatan: Value(pengkajianKeperawatan),
    pengkajianMedis: Value(pengkajianMedis),
    khususPerawat: Value(khususPerawat),
    isSynced: const Value(false), // ⬅️ Belum ter-sync
  ),
);

// Save ICD
await _database.insertRegistrasiIcd(
  RegistrasiIcdsCompanion(
    registrasiId: Value(widget.registrationId),
    icdId: Value(icdId),
    isSynced: const Value(false), // ⬅️ Belum ter-sync
  ),
);

// Save tindakan
await _database.insertRegistrasiTindakan(
  RegistrasiTindakansCompanion(
    registrasiId: Value(widget.registrationId),
    tindakanId: Value(tindakanId),
    jumlah: Value(jumlah),
    isSynced: const Value(false), // ⬅️ Belum ter-sync
  ),
);
```

### 3. **Auto-Sync Service**

`SyncService` berjalan di background dan akan otomatis sync data ketika:

#### a. App Startup

```dart
// app_injections.dart
Future<void> initAppInjections() async {
  // Register Sync Service
  getIt.registerLazySingleton<SyncService>(
    () => SyncService(
      getIt<AppDatabase>(),
      dio,
      getIt<Connectivity>(),
    ),
  );

  // Start auto-sync
  getIt<SyncService>().startAutoSync();
}
```

#### b. Connectivity Change (Offline → Online)

```dart
// sync_service.dart
_connectivitySubscription = _connectivity.onConnectivityChanged.listen(
  (List<ConnectivityResult> results) {
    final hasConnection = results.any((result) =>
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi
    );

    if (hasConnection && !_isSyncing) {
      debugPrint('🌐 Connection detected, starting sync...');
      syncAll();
    }
  },
);
```

#### c. Periodic Timer (Every 5 Minutes)

```dart
_syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
  syncAll();
});
```

#### d. Manual Trigger (User Tap)

```dart
// User can tap sync widget to trigger manual sync
GestureDetector(
  onTap: () {
    if (isOnline && !isSyncing) {
      _syncService.syncAll();
    }
  },
  child: SyncStatusWidget(),
)
```

### 4. **Sync Flow**

Sync dilakukan secara berurutan dengan dependency order:

```dart
Future<void> syncAll() async {
  // 1. Sync Registrasi first (parent)
  await _syncRegistrasis();

  // 2. Sync Anamnesa (child of Registrasi)
  await _syncAnamnesas();

  // 3. Sync ICD (child of Registrasi)
  await _syncRegistrasiIcds();

  // 4. Sync Tindakan (child of Registrasi)
  await _syncRegistrasiTindakans();
}
```

#### Example: Sync Anamnesa

```dart
Future<void> _syncAnamnesas() async {
  final unsyncedAnamnesas = await _database.getUnsyncedAnamnesas();

  for (final anamnesa in unsyncedAnamnesas) {
    // Get parent registrasi
    final registrasi = await _database.getRegistrasiById(anamnesa.registrasiId);

    // Skip if parent not synced yet
    if (!registrasi.isSynced) continue;

    // POST to API
    final response = await _dio.post('/anamnesa/store', data: {
      'registrasi_id': registrasi.serverId, // ⬅️ Use server ID
      'pengkajian_keperawatan': anamnesa.pengkajianKeperawatan,
      'pengkajian_medis': anamnesa.pengkajianMedis,
      'khusus_perawat': anamnesa.khususPerawat,
    });

    // Mark as synced
    await _database.markAnamnesaSynced(
      anamnesa.id,           // local ID
      response.data['data']['id'], // server ID
    );
  }
}
```

### 5. **Sync Status Widget**

Widget di home page menampilkan status sync:

```dart
class SyncStatusWidget extends StatefulWidget {
  // Shows:
  // - Number of unsynced items
  // - Online/offline status
  // - Sync in progress indicator
  // - Tap to sync button (if online)
}
```

**Display Examples:**

- **Offline with unsynced data:**

  ```
  🔴 Offline - 3 data menunggu sinkronisasi
  ```

- **Online with unsynced data:**

  ```
  🟠 Ada 3 data belum tersinkronisasi
  Tap untuk sinkronisasi sekarang
  ```

- **Syncing:**

  ```
  🔵 Sedang sinkronisasi... ⟳
  ```

- **All synced:**
  ```
  (Widget hidden)
  ```

## API Endpoints Required

### 1. Master Data Seeding

```
GET /icds
Response: {
  "data": [
    {
      "id": 4087,
      "kode": "F11.6",
      "deskripsi": "MENTAL AND BEHAVIOURAL...",
      "kat_icd": "F11",
      "is_active": true
    }
  ]
}
```

```
GET /tindakans
Response: {
  "data": [
    {
      "id": 1,
      "kode": "T001",
      "deskripsi": "Konsultasi Dokter Umum",
      "tarif": "50000",
      "is_active": true
    }
  ]
}
```

### 2. Transaction Data Sync

```
POST /registrasi/store
Body: {
  "no_reg": "REG-2025-001",
  "pasien_id": 1,
  "tgl_jam_reg": "2025-11-26 10:00:00",
  "jenis_kunjungan": "Kunjungan Pertama",
  // ... other fields
}
Response: {
  "data": {
    "id": 123, // ⬅️ Server ID
    "no_reg": "REG-2025-001",
    // ...
  }
}
```

```
POST /anamnesa/store
Body: {
  "registrasi_id": 123, // ⬅️ Server registrasi ID
  "pengkajian_keperawatan": "{...json...}",
  "pengkajian_medis": "{...json...}",
  "khusus_perawat": "{...json...}"
}
Response: {
  "data": {
    "id": 456, // ⬅️ Server ID
    // ...
  }
}
```

```
POST /registrasi/{registrasi_id}/icd/attach
Body: {
  "icd_id": 4087
}
Response: {
  "data": {
    "id": 789, // ⬅️ Server pivot ID
    // ...
  }
}
```

```
POST /registrasi/{registrasi_id}/tindakan/attach
Body: {
  "tindakan_id": 1,
  "jumlah": "1",
  "harga_satuan": "50000",
  "subtotal": "50000"
}
Response: {
  "data": {
    "id": 101112, // ⬅️ Server pivot ID
    // ...
  }
}
```

## Database Methods

### Query Unsynced Data

```dart
// Get all unsynced registrations
Future<List<Registrasi>> getUnsyncedRegistrasis() =>
  (select(registrasis)..where((r) => r.isSynced.equals(false))).get();

// Get all unsynced anamnesas
Future<List<Anamnesa>> getUnsyncedAnamnesas() =>
  (select(anamnesas)..where((a) => a.isSynced.equals(false))).get();

// Get all unsynced ICD attachments
Future<List<RegistrasiIcd>> getUnsyncedRegistrasiIcds() =>
  (select(registrasiIcds)..where((ri) => ri.isSynced.equals(false))).get();

// Get all unsynced tindakan attachments
Future<List<RegistrasiTindakan>> getUnsyncedRegistrasiTindakans() =>
  (select(registrasiTindakans)..where((rt) => rt.isSynced.equals(false))).get();
```

### Mark as Synced

```dart
// Mark registrasi as synced
Future<bool> markRegistrasiSynced(int localId, int serverId) async {
  final updated = await (update(registrasis)..where((r) => r.id.equals(localId)))
    .write(RegistrasisCompanion(
      isSynced: const Value(true),
      serverId: Value(serverId),
    ));
  return updated > 0;
}

// Similar methods for anamnesa, ICD, and tindakan
```

### Get Unsynced Count

```dart
Future<int> getUnsyncedCount() async {
  final registrasisCount = await (select(registrasis)
    ..where((r) => r.isSynced.equals(false)))
    .get()
    .then((list) => list.length);

  final anamnesasCount = await (select(anamnesas)
    ..where((a) => a.isSynced.equals(false)))
    .get()
    .then((list) => list.length);

  // ... same for ICDs and tindakans

  return registrasisCount + anamnesasCount + icdsCount + tindakansCount;
}
```

## Testing Guide

### Test Scenario 1: First Launch (Seeding)

1. **Open app with internet**
2. Navigate to ICD selection page
3. **Expected:** ICDs loaded from API and stored locally
4. **Verify:** Database contains ICD data

### Test Scenario 2: Offline Form Entry

1. **Enable airplane mode** (no internet)
2. Fill anamnesa form
3. Select ICDs
4. Select tindakans
5. **Save all forms**
6. **Expected:** All data saved to local database with `isSynced = false`
7. **Verify:** Home page shows sync widget with unsynced count

### Test Scenario 3: Auto-Sync on Connectivity

1. **Disable airplane mode** (restore internet)
2. **Expected:**
   - Sync widget shows "Sedang sinkronisasi..."
   - After sync: widget disappears or shows 0 unsynced
3. **Verify:**
   - Database records now have `isSynced = true`
   - Database records now have `serverId` populated
   - API server has received the data

### Test Scenario 4: Manual Sync

1. **With unsynced data and internet available**
2. **Tap on sync widget**
3. **Expected:** Immediate sync starts
4. **Verify:** Sync progress shown, then completes

### Test Scenario 5: Partial Sync Failure

1. **Create registrasi + anamnesa offline**
2. **Turn on internet**
3. **Let registrasi sync, then turn off internet**
4. **Expected:**
   - Registrasi synced (has serverId)
   - Anamnesa still unsynced (no serverId)
5. **Turn on internet again**
6. **Expected:** Anamnesa syncs using parent's serverId

## Logging

All sync operations log to console:

```
🔄 SyncService: Starting auto-sync...
🌐 SyncService: Connection detected, starting sync...
🔄 SyncService: Starting sync for 5 items...
📤 Syncing 1 registrations...
✅ Registrasi REG-2025-001 synced successfully
📤 Syncing 1 anamnesas...
✅ Anamnesa for registrasi REG-2025-001 synced
📤 Syncing 2 registrasi ICDs...
✅ ICD for registrasi REG-2025-001 synced
📤 Syncing 1 registrasi tindakans...
✅ Tindakan for registrasi REG-2025-001 synced
✅ SyncService: Sync completed. Remaining unsynced: 0
```

## Configuration

### Change Sync Interval

Edit `sync_service.dart`:

```dart
// Current: every 5 minutes
_syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
  syncAll();
});

// Change to every 10 minutes:
_syncTimer = Timer.periodic(const Duration(minutes: 10), (_) {
  syncAll();
});
```

### Disable Auto-Sync

```dart
// In app_injections.dart, comment out:
// getIt<SyncService>().startAutoSync();

// Or add a settings toggle:
if (settings.enableAutoSync) {
  getIt<SyncService>().startAutoSync();
}
```

## Dependencies

```yaml
# pubspec.yaml
dependencies:
  connectivity_plus: ^6.1.2 # Network status monitoring
  drift: ^2.28.2 # Database ORM
  dio: ^5.9.0 # HTTP client
```

## File Structure

```
lib/
├── core/
│   └── services/
│       └── sync_service.dart         # Main sync logic
├── shared/
│   ├── local_db/
│   │   └── app_database.dart         # Schema v8 with sync fields
│   └── widgets/
│       └── sync_status_widget.dart   # UI indicator
└── features/
    └── schedules/
        └── presentation/
            └── pages/
                ├── schedule_anamnesa_page.dart    # Sets isSynced=false
                ├── schedule_icd_pages.dart        # Sets isSynced=false + seeding
                └── schedule_tindakan_page.dart    # Sets isSynced=false
```

## Troubleshooting

### Issue: Data not syncing

**Check:**

1. Internet connectivity
2. Console logs for errors
3. API endpoint availability
4. Database `isSynced` flags
5. `serverId` population for parent records

### Issue: Duplicate data on server

**Cause:** Sync ran multiple times before marking as synced

**Solution:**

- Check `isSynced` flag before POST
- Ensure marking as synced happens immediately after successful POST
- Add unique constraints on server side (e.g., registrasi.no_reg)

### Issue: Child records not syncing

**Cause:** Parent record not synced yet (no `serverId`)

**Solution:**

- Sync follows dependency order: Parent → Child
- Anamnesa/ICD/Tindakan skip if parent `!isSynced`
- Wait for next sync cycle

## Future Enhancements

1. **Conflict Resolution:** Handle server-side changes conflicting with local
2. **Selective Sync:** Allow user to choose which data to sync
3. **Background Sync:** Use WorkManager for Android background sync
4. **Retry Logic:** Exponential backoff for failed sync attempts
5. **Compression:** Compress JSON data before sending to API
6. **Delta Sync:** Only sync changed fields, not entire records
7. **Sync History:** Track sync events in a log table

---

**Last Updated:** November 26, 2025  
**Schema Version:** 8  
**Author:** AI Assistant
