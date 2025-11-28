# API Integration - Registration (Registrasi) Module

## Overview

Modul Registrasi telah diintegrasikan dengan API menggunakan **offline-first strategy**. Registrasi adalah data parent untuk Anamnesa, ICD, dan Tindakan.

## API Endpoints

### Base Endpoint: `/registrasi`

| Method   | Endpoint                     | Description             | Request Body        | Response                   |
| -------- | ---------------------------- | ----------------------- | ------------------- | -------------------------- |
| `GET`    | `/registrasi`                | Get all registrations   | -                   | `{ "data": [Registrasi] }` |
| `GET`    | `/registrasi/{id}`           | Get registration by ID  | -                   | `{ "data": Registrasi }`   |
| `POST`   | `/registrasi`                | Create new registration | `RegistrasiRequest` | `{ "data": Registrasi }`   |
| `PUT`    | `/registrasi/{id}`           | Update registration     | `RegistrasiRequest` | `{ "data": Registrasi }`   |
| `DELETE` | `/registrasi/{id}`           | Delete registration     | -                   | Success status             |
| `GET`    | `/registrasi?search=query`   | Search registrations    | -                   | `{ "data": [Registrasi] }` |
| `GET`    | `/registrasi?pasien_id={id}` | Get by patient ID       | -                   | `{ "data": [Registrasi] }` |
| `GET`    | `/registrasi?date={date}`    | Get by date             | -                   | `{ "data": [Registrasi] }` |

## JSON Schema

### Registrasi Object

```json
{
  "id": 1,
  "no_reg": "REG-2025-001",
  "no_urut": "001",
  "pasien_id": 1,
  "tgl_jam_reg": "2025-11-26 10:00:00",
  "kode_poli": "POLI001",
  "dokter_id": "DOK001",
  "jenis_kunjungan": "Kunjungan Pertama",
  "asal_pasien": "Rujukan",
  "tipe_pasien": "Pasien Umum",
  "pasien_baru": 1,
  "pagi_sore": "pagi",
  "is_cash": 1,
  "is_pribadi": 0,
  "eselon": null,
  "status": "active",
  "penanggung_id": null,
  "penanggung_nama": null,
  "penanggung_no_pegawai": null,
  "penanggung_alamat": null,
  "penanggung_telepon": null,
  "created_at": "2025-11-26T10:00:00.000000Z",
  "updated_at": "2025-11-26T10:00:00.000000Z"
}
```

### RegistrasiRequest (POST/PUT)

```json
{
  "no_reg": "REG-2025-001",
  "no_urut": "001",
  "pasien_id": 1,
  "tgl_jam_reg": "2025-11-26 10:00:00",
  "kode_poli": "POLI001",
  "dokter_id": "DOK001",
  "jenis_kunjungan": "Kunjungan Pertama",
  "asal_pasien": "Rujukan",
  "tipe_pasien": "Pasien Umum",
  "pasien_baru": 1,
  "pagi_sore": "pagi",
  "is_cash": 1,
  "is_pribadi": 0,
  "eselon": null,
  "status": "active",
  "penanggung_id": null,
  "penanggung_nama": null,
  "penanggung_no_pegawai": null,
  "penanggung_alamat": null,
  "penanggung_telepon": null
}
```

**Field Descriptions:**

- `no_reg`: Registration number (unique)
- `no_urut`: Sequential number
- `pasien_id`: Patient ID (foreign key to Pasien)
- `tgl_jam_reg`: Registration date and time
- `kode_poli`: Clinic/poly code
- `dokter_id`: Doctor ID
- `jenis_kunjungan`: Visit type (e.g., "Kunjungan Pertama", "Kunjungan Ulang")
- `tipe_pasien`: Patient type (e.g., "Pasien Umum", "BPJS", "Asuransi")
- `pasien_baru`: Is new patient (0 or 1)
- `is_cash`: Is cash payment (0 or 1)
- `is_pribadi`: Is private (0 or 1)
- `penanggung_*`: Guarantor information fields

## Architecture

### Data Flow

```
┌─────────────────────────────────────────────────────┐
│              UI (Schedule Pages)                     │
│  - ScheduleListPage (list registrations)            │
│  - ScheduleDetailPage (detail + child data)         │
└────────────────────┬────────────────────────────────┘
                     │ Repository calls
                     ▼
┌─────────────────────────────────────────────────────┐
│           RegistrasiRepository                       │
│  Strategy: Offline-First                            │
│  1. Load from local DB (instant)                    │
│  2. Fetch from API (background)                     │
│  3. Update local DB                                 │
└─────────┬───────────────────────────────┬───────────┘
          │                               │
          ▼                               ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│RegistrasiLocalDataSource│  │ RegistrasiDataSource     │
│  (SQLite/Drift)          │  │  (API/Dio)              │
│                          │  │                          │
│ • getAllRegistrasi()     │  │ • GET /registrasi        │
│ • getRegistrasiById()    │  │ • GET /registrasi/{id}   │
│ • getByPasienId()        │  │ • POST /registrasi       │
│ • createRegistrasi()     │  │ • PUT /registrasi/{id}   │
│ • updateRegistrasi()     │  │ • DELETE /registrasi/{id}│
│ • deleteRegistrasi()     │  │ • searchRegistrasi()     │
│ • upsertRegistrasi() ⬅️  │  │ • getByPasienId()        │
│   (for API sync)         │  │ • getByDate()            │
└──────────────────────────┘  └──────────────────────────┘
```

### Relationship with Other Modules

```
Pasien (Patient)
    ↓ has many
Registrasi (Registration) ← Parent for all visit data
    ├─→ Anamnesa (Assessment)
    ├─→ RegistrasiIcds (Diagnoses)
    ├─→ RegistrasiTindakans (Procedures)
    └─→ Tagihan (Billing)
```

## Offline-First Strategy

### 1. Get All Registrations

```dart
Future<List<Registrasi>> getAllRegistrasi() async {
  // 1. Load from local first (instant display)
  final localRegistrasis = await _localDataSource.getAllRegistrasi();

  // 2. Fetch from API in background
  _fetchAndSyncFromApi(); // Non-blocking

  return localRegistrasis;
}
```

**Behavior:**

- ✅ **Online:** Shows local data instantly → updates from API in background
- ✅ **Offline:** Shows local data only (no error)

### 2. Get by Patient ID

```dart
Future<List<Registrasi>> getRegistrasiByPasienId(int pasienId) async {
  try {
    // Try API first for most accurate data
    final response = await _remoteDataSource.getRegistrasiByPasienId(pasienId);

    // Update local cache
    for (var registrasi in response.data) {
      await _localDataSource.upsertRegistrasi(registrasi);
    }

    return response.data;
  } catch (apiError) {
    // Fallback to local
    return await _localDataSource.getRegistrasiByPasienId(pasienId);
  }
}
```

**Behavior:**

- ✅ **Online:** Fetches from API → caches locally
- ✅ **Offline:** Uses local data

### 3. Create Registration

```dart
Future<Registrasi> createRegistrasi(Map<String, dynamic> data) async {
  try {
    // Try to create on server first
    final remoteRegistrasi = await _remoteDataSource.createRegistrasi(data);

    // Save to local database
    await _localDataSource.upsertRegistrasi(remoteRegistrasi);

    return remoteRegistrasi;
  } catch (e) {
    // Fallback: Save locally only (will sync via SyncService)
    return await _localDataSource.createRegistrasi(data);
  }
}
```

**Behavior:**

- ✅ **Online:** Creates on server → saves with server ID
- ✅ **Offline:** Creates locally → will sync when online

### 4. Search & Filter

**Search by query:**

```dart
Future<List<Registrasi>> searchRegistrasi(String query)
```

**Filter by date:**

```dart
Future<List<Registrasi>> getRegistrasiByDate(String date)
```

Both methods try API first, fallback to local search.

## Sync Integration

### Auto-Sync via SyncService

Registrasi yang dibuat offline akan otomatis di-sync ke server:

```dart
// In sync_service.dart
Future<void> _syncRegistrasis() async {
  final unsyncedRegistrasis = await _database.getUnsyncedRegistrasis();

  for (final registrasi in unsyncedRegistrasis) {
    // POST to API
    final response = await _dio.post('/registrasi', data: {...});

    // Mark as synced
    await _database.markRegistrasiSynced(
      registrasi.id,           // local ID
      response.data['data']['id'], // server ID
    );
  }
}
```

**Sync Order:**

1. **Registrasi** ← Sync first (parent)
2. Anamnesa (uses registrasi.serverId)
3. RegistrasiIcds (uses registrasi.serverId)
4. RegistrasiTindakans (uses registrasi.serverId)

## File Structure

```
lib/features/schedules/
├── data/
│   ├── datasources/
│   │   ├── registrasi_data_source.dart       # API calls
│   │   └── registrasi_local_datasource.dart  # Local DB
│   └── repositories/
│       └── registrasi_repository.dart        # Offline-first logic
├── domain/
│   └── models/
│       ├── registrasi.dart                   # Domain model
│       └── registrasi.g.dart                 # Generated JSON
└── presentation/
    └── pages/
        ├── schedule_list_page.dart           # List registrations
        └── schedule_detail_page.dart         # Detail + child data
```

## Usage Examples

### 1. Load All Registrations

```dart
final repository = getIt<RegistrasiRepository>();
final registrations = await repository.getAllRegistrasi();
```

### 2. Get Registrations by Patient

```dart
final registrations = await repository.getRegistrasiByPasienId(patientId);
```

### 3. Create Registration

```dart
final data = {
  'no_reg': 'REG-2025-001',
  'pasien_id': 1,
  'tgl_jam_reg': DateTime.now().toIso8601String(),
  'jenis_kunjungan': 'Kunjungan Pertama',
  'tipe_pasien': 'Pasien Umum',
  'pasien_baru': 1,
  'is_cash': 1,
  'is_pribadi': 0,
};

final registrasi = await repository.createRegistrasi(data);
```

### 4. Update Registration

```dart
final updatedData = {
  'status': 'completed',
  'dokter_id': 'DOK002',
};

final registrasi = await repository.updateRegistrasi(id, updatedData);
```

### 5. Search Registrations

```dart
final results = await repository.searchRegistrasi('REG-2025');
```

### 6. Get by Date

```dart
final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
final todayRegistrations = await repository.getRegistrasiByDate(today);
```

## Integration with UI

### ScheduleListPage

Uses `RegistrasiRepository` to display all registrations:

```dart
@override
void initState() {
  super.initState();
  _loadRegistrations();
}

Future<void> _loadRegistrations() async {
  final registrations = await getIt<RegistrasiRepository>().getAllRegistrasi();
  setState(() {
    _registrations = registrations;
  });
}
```

### ScheduleDetailPage

Shows registration details and related data (anamnesa, ICD, tindakan):

```dart
Future<void> _loadDetail(int registrationId) async {
  final registrasi = await getIt<RegistrasiRepository>()
      .getRegistrasiById(registrationId);

  // Load related data
  final anamnesa = await _database.getAnamnesaByRegistrasiId(registrationId);
  final icds = await _database.getRegistrasiIcdsByRegistrasiId(registrationId);
  final tindakans = await _database.getRegistrasiTindakansByRegistrasiId(registrationId);

  setState(() {
    _registrasi = registrasi;
    _anamnesa = anamnesa;
    _icds = icds;
    _tindakans = tindakans;
  });
}
```

## Testing Guide

### Test Scenario 1: Online Mode - Load Registrations

1. **With internet**
2. Open schedule list page
3. **Expected:**
   - Shows local registrations instantly
   - Background sync from API
   - List updates with fresh data
4. **Verify:** Console shows sync logs

### Test Scenario 2: Offline Mode

1. **Enable airplane mode**
2. Open schedule list page
3. **Expected:**
   - Shows local registrations
   - No errors
4. **Verify:** Console: "Failed to sync from API (offline mode)"

### Test Scenario 3: Create Registration Online

1. **With internet**
2. Create new registration
3. **Expected:**
   - POST to `/registrasi`
   - Success message
   - Registration has server ID
4. **Verify:** `isSynced = true`, `serverId` populated

### Test Scenario 4: Create Registration Offline

1. **Enable airplane mode**
2. Create new registration
3. **Expected:**
   - Saves to local DB only
   - Success message
4. **Verify:**
   - `isSynced = false`
   - Will sync when online (via SyncService)

### Test Scenario 5: View Patient Registrations

1. Open patient detail
2. View registration history
3. **Expected:**
   - Shows all registrations for that patient
   - Ordered by date (newest first)

### Test Scenario 6: Filter by Date

1. Select a date
2. **Expected:**
   - Shows registrations for that date only
   - Online: queries API
   - Offline: filters local data

## Console Logs

### Successful Operations

```
✅ Synced 10 registrations from API
✅ Registration created on server and synced locally
✅ Registration updated on server and locally
✅ Registration deleted from server and locally
```

### Offline/Fallback Operations

```
⚠️ Failed to sync from API (offline mode): SocketException
⚠️ Failed to create on server, saving locally
⚠️ API failed, using local data
⚠️ API search failed, using local search
```

## Database Methods

### AppDatabase Methods

```dart
// Get all registrations
Future<List<Registrasi>> getAllRegistrasis()

// Get by ID
Future<Registrasi?> getRegistrasiById(int id)

// Get by patient ID
Future<List<Registrasi>> getRegistrasisByPasienId(int pasienId)

// Get latest registration for patient
Future<Registrasi?> getLatestRegistrasiByPasienId(int pasienId)

// CRUD operations
Future<int> insertRegistrasi(RegistrasisCompanion companion)
Future<bool> updateRegistrasi(int id, RegistrasisCompanion companion)
Future<int> deleteRegistrasi(int id)

// Sync methods
Future<List<Registrasi>> getUnsyncedRegistrasis()
Future<bool> markRegistrasiSynced(int localId, int serverId)
```

## Dependency Injection

### Registration in app_injections.dart

```dart
// Data Sources
getIt.registerLazySingleton<RegistrasiDataSource>(
  () => RegistrasiDataSource(dio),
);

getIt.registerLazySingleton<RegistrasiLocalDataSource>(
  () => RegistrasiLocalDataSource(getIt<AppDatabase>()),
);

// Repository
getIt.registerLazySingleton<RegistrasiRepository>(
  () => RegistrasiRepository(
    getIt<RegistrasiDataSource>(),
    getIt<RegistrasiLocalDataSource>(),
  ),
);
```

### Usage in UI

```dart
final repository = getIt<RegistrasiRepository>();
final registrations = await repository.getAllRegistrasi();
```

## Next Steps

Now that Registrasi is integrated, you can integrate child modules:

1. ✅ **Pasien** - DONE
2. ✅ **Registrasi** - DONE
3. 🔄 **Anamnesa** - `/anamnesa` (child of registrasi)
4. 🔄 **Tindakan** - `/tindakan` (master + junction)
5. 🔄 **Tagihan** - `/tagihan` (billing)

**Note:** Anamnesa, ICD, and Tindakan should use `registrasi.serverId` when syncing to API (not local ID).

---

**Status:** ✅ **IMPLEMENTED**  
**Last Updated:** November 26, 2025  
**Module:** Registration (Registrasi)  
**Build:** ✅ Success (20.0s)
