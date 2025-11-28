# API Integration - Patient Module

## Overview

Modul Pasien telah diintegrasikan dengan API menggunakan **offline-first strategy**. Data akan:

1. ✅ Load dari database lokal terlebih dahulu (instant display)
2. ✅ Fetch dari API di background untuk update data
3. ✅ Fallback ke local jika API gagal (offline support)

## API Endpoints

### Base URL

```
Dikonfigurasi di: lib/core/network/dio.dart
```

### Endpoints

| Method   | Endpoint               | Description        | Request Body    | Response               |
| -------- | ---------------------- | ------------------ | --------------- | ---------------------- |
| `GET`    | `/pasien`              | Get all patients   | -               | `{ "data": [Pasien] }` |
| `GET`    | `/pasien/{id}`         | Get patient by ID  | -               | `{ "data": Pasien }`   |
| `POST`   | `/pasien`              | Create new patient | `PasienRequest` | `{ "data": Pasien }`   |
| `PUT`    | `/pasien/{id}`         | Update patient     | `PasienRequest` | `{ "data": Pasien }`   |
| `DELETE` | `/pasien/{id}`         | Delete patient     | -               | Success status         |
| `GET`    | `/pasien?search=query` | Search patients    | -               | `{ "data": [Pasien] }` |

## JSON Schema

### Pasien Object

```json
{
  "id": "1",
  "mrn": "RM001",
  "nama": "John Doe",
  "tanggal_lahir": "1990-01-15",
  "jenis_kelamin": "L",
  "alamat": "Jl. Merdeka No. 123",
  "telepon": "081234567890",
  "created_at": "2025-11-26T10:00:00.000000Z",
  "updated_at": "2025-11-26T10:00:00.000000Z"
}
```

### PasienRequest (POST/PUT)

```json
{
  "nama": "John Doe",
  "tanggal_lahir": "1990-01-15",
  "jenis_kelamin": "L",
  "alamat": "Jl. Merdeka No. 123",
  "telepon": "081234567890"
}
```

**Field Validations:**

- `nama`: Required, string
- `tanggal_lahir`: Required, date format (YYYY-MM-DD)
- `jenis_kelamin`: Required, "L" or "P"
- `alamat`: Required, string
- `telepon`: Required, string (phone number)

### Response Format

**Success (GET all):**

```json
{
  "data": [
    {
      "id": "1",
      "mrn": "RM001",
      "nama": "John Doe",
      "tanggal_lahir": "1990-01-15",
      "jenis_kelamin": "L",
      "alamat": "Jl. Merdeka No. 123",
      "telepon": "081234567890",
      "created_at": "2025-11-26T10:00:00Z",
      "updated_at": "2025-11-26T10:00:00Z"
    }
  ]
}
```

**Success (Single):**

```json
{
  "data": {
    "id": "1",
    "mrn": "RM001",
    "nama": "John Doe"
    // ... other fields
  }
}
```

**Error:**

```json
{
  "message": "Error message here",
  "errors": {
    "field_name": ["Error detail"]
  }
}
```

## Architecture

### Data Flow

```
┌─────────────────────────────────────────────────────┐
│                 UI (Presentation)                   │
│  - PatientListPage (display patients)               │
│  - PatientCreatePage (add new patient)              │
│  - PatientEditPage (edit patient)                   │
└────────────────────┬────────────────────────────────┘
                     │ BLoC Events
                     ▼
┌─────────────────────────────────────────────────────┐
│                PatientBloc                           │
│  - LoadPatients → LoadPatientsSuccess/Failure       │
│  - CreatePatient → PatientCreated                   │
│  - UpdatePatient → PatientUpdated                   │
│  - DeletePatient → PatientDeleted                   │
└────────────────────┬────────────────────────────────┘
                     │ Calls
                     ▼
┌─────────────────────────────────────────────────────┐
│              PasienRepository                        │
│  Strategy: Offline-First                            │
│  1. Load from local DB (instant)                    │
│  2. Fetch from API (background)                     │
│  3. Update local DB                                 │
└─────────┬───────────────────────────────┬───────────┘
          │                               │
          ▼                               ▼
┌──────────────────────┐      ┌──────────────────────┐
│ PasienLocalDataSource│      │  PasienDataSource    │
│  (SQLite/Drift)      │      │  (API/Dio)          │
│                      │      │                      │
│ • getAllPasien()     │      │ • GET /pasien        │
│ • getPasienById()    │      │ • GET /pasien/{id}   │
│ • createPasien()     │      │ • POST /pasien       │
│ • updatePasien()     │      │ • PUT /pasien/{id}   │
│ • deletePasien()     │      │ • DELETE /pasien/{id}│
│ • upsertPasien() ⬅️  │      │ • searchPasien()     │
│   (for API sync)     │      │                      │
└──────────────────────┘      └──────────────────────┘
```

### Offline-First Strategy

#### 1. **Get All Patients**

```dart
Future<List<Pasien>> getAllPasien() async {
  // 1. Load from local first (instant display)
  final localPatients = await _localDataSource.getAllPasien();

  // 2. Fetch from API in background
  _fetchAndSyncFromApi(); // Non-blocking

  return localPatients;
}

Future<void> _fetchAndSyncFromApi() async {
  try {
    final response = await _remoteDataSource.getAllPasien();

    // Update local database
    for (var pasien in response.data) {
      await _localDataSource.upsertPasien(pasien);
    }
  } catch (e) {
    // Silently fail - user can still use local data
  }
}
```

**Behavior:**

- ✅ **Online:** Shows local data instantly → updates in background from API
- ✅ **Offline:** Shows local data only (no error)

#### 2. **Get Patient by ID**

```dart
Future<Pasien> getPasienById(String id) async {
  try {
    // Try local first
    final localPasien = await _localDataSource.getPasienById(id);

    // Fetch latest from API (background)
    _remoteDataSource.getPasienById(id).then((remotePasien) {
      _localDataSource.upsertPasien(remotePasien);
    });

    return localPasien;
  } catch (e) {
    // If not in local, try API
    final remotePasien = await _remoteDataSource.getPasienById(id);
    await _localDataSource.upsertPasien(remotePasien);
    return remotePasien;
  }
}
```

**Behavior:**

- ✅ **Data exists locally:** Returns local → syncs from API in background
- ✅ **Data not in local:** Fetches from API → saves to local
- ❌ **Offline + not in local:** Throws error

#### 3. **Create Patient**

```dart
Future<Pasien> createPasien({...}) async {
  try {
    // Try to create on server first
    final remotePasien = await _remoteDataSource.createPasien(data);

    // Save to local database
    await _localDataSource.upsertPasien(remotePasien);

    return remotePasien;
  } catch (e) {
    // Fallback: Save locally only
    return await _localDataSource.createPasien(data);
  }
}
```

**Behavior:**

- ✅ **Online:** Creates on server → saves to local with server ID
- ✅ **Offline:** Creates in local only (will sync later via SyncService)

#### 4. **Update Patient**

```dart
Future<Pasien> updatePasien({...}) async {
  try {
    // Try to update on server first
    final remotePasien = await _remoteDataSource.updatePasien(id, data);

    // Update local database
    await _localDataSource.updatePasien(id, data);

    return remotePasien;
  } catch (e) {
    // Fallback: Update locally only
    return await _localDataSource.updatePasien(id, data);
  }
}
```

**Behavior:**

- ✅ **Online:** Updates on server → updates local
- ✅ **Offline:** Updates local only (will sync later)

#### 5. **Delete Patient**

```dart
Future<void> deletePasien(String id) async {
  try {
    // Try to delete on server first
    await _remoteDataSource.deletePasien(id);

    // Delete from local database
    await _localDataSource.deletePasien(id);
  } catch (e) {
    // Fallback: Delete locally only
    await _localDataSource.deletePasien(id);
  }
}
```

**Behavior:**

- ✅ **Online:** Deletes from server → deletes from local
- ✅ **Offline:** Deletes from local only

#### 6. **Search Patients**

```dart
Future<List<Pasien>> searchPasien(String query) async {
  try {
    // Try API search first
    final response = await _remoteDataSource.searchPasien(query);

    // Update local cache
    for (var pasien in response.data) {
      await _localDataSource.upsertPasien(pasien);
    }

    return response.data;
  } catch (e) {
    // Fallback to local search
    final allPatients = await _localDataSource.getAllPasien();
    return allPatients.where((patient) {
      final searchLower = query.toLowerCase();
      return patient.nama.toLowerCase().contains(searchLower) ||
          patient.mrn.toLowerCase().contains(searchLower) ||
          patient.telepon.toLowerCase().contains(searchLower);
    }).toList();
  }
}
```

**Behavior:**

- ✅ **Online:** Searches via API → caches results locally
- ✅ **Offline:** Searches local database

## File Structure

```
lib/features/patients/
├── data/
│   ├── datasources/
│   │   ├── pasien_data_source.dart        # API calls (Dio)
│   │   └── pasien_local_data_source.dart  # Local DB (Drift)
│   └── repositories/
│       └── pasien_repository.dart         # Offline-first logic
├── domain/
│   └── models/
│       ├── pasien.dart                    # Domain model
│       └── pasien.g.dart                  # Generated JSON
└── presentation/
    ├── bloc/
    │   ├── patient_bloc.dart              # Business logic
    │   ├── patient_event.dart             # Events
    │   └── patient_state.dart             # States
    └── pages/
        ├── patient_list_page.dart         # List view
        ├── patient_create_page.dart       # Create form
        └── patient_edit_page.dart         # Edit form
```

## Usage Examples

### 1. Load All Patients

```dart
// In PatientBloc
void _onLoadPatients(LoadPatients event, Emitter<PatientState> emit) async {
  emit(PatientLoading());

  try {
    final patients = await repository.getAllPasien();
    emit(LoadPatientsSuccess(patients));
  } catch (e) {
    emit(PatientError(e.toString()));
  }
}
```

**UI Behavior:**

- Shows loading spinner
- Displays patients from local DB (instant)
- Updates in background if API available

### 2. Create Patient

```dart
// In UI
BlocProvider.of<PatientBloc>(context).add(
  CreatePatient(
    nama: 'John Doe',
    tanggalLahir: '1990-01-15',
    jenisKelamin: 'L',
    alamat: 'Jl. Merdeka No. 123',
    telepon: '081234567890',
  ),
);
```

**Flow:**

1. Submit form
2. BLoC calls `repository.createPasien()`
3. Repository tries API → fallback to local
4. Emit `PatientCreated` event
5. Navigate back to list

### 3. Update Patient

```dart
// In UI
BlocProvider.of<PatientBloc>(context).add(
  UpdatePatient(
    id: '1',
    nama: 'Jane Doe',
    tanggalLahir: '1992-05-20',
    jenisKelamin: 'P',
    alamat: 'Jl. Sudirman No. 456',
    telepon: '082345678901',
  ),
);
```

### 4. Delete Patient

```dart
// In UI
BlocProvider.of<PatientBloc>(context).add(
  DeletePatient(id: '1'),
);
```

### 5. Search Patients

```dart
// In UI
BlocProvider.of<PatientBloc>(context).add(
  SearchPatients(query: 'John'),
);
```

## Testing Guide

### Test Scenario 1: Online Mode - Full Sync

1. **Ensure internet connection**
2. Open patient list page
3. **Expected:**
   - Shows local patients instantly
   - Background sync from API
   - List updates with latest data from server
4. **Verify:** Console logs show API calls

### Test Scenario 2: Offline Mode - Local Only

1. **Enable airplane mode**
2. Open patient list page
3. **Expected:**
   - Shows local patients
   - No errors
   - Console shows "Failed to sync from API (offline mode)"
4. **Verify:** Can still browse, create, edit, delete locally

### Test Scenario 3: Create Patient Online

1. **With internet**
2. Click "Add Patient"
3. Fill form and submit
4. **Expected:**
   - POST to `/pasien`
   - Success message
   - Patient appears in list with server ID
5. **Verify:**
   - Console: "✅ Patient created on server and synced locally"
   - Database has `id` from server

### Test Scenario 4: Create Patient Offline

1. **Enable airplane mode**
2. Click "Add Patient"
3. Fill form and submit
4. **Expected:**
   - Saves to local DB only
   - Success message
   - Patient appears in list with local ID
5. **Verify:**
   - Console: "⚠️ Failed to create on server, saving locally"
   - Will sync to server when online (via SyncService)

### Test Scenario 5: Update Patient Online

1. **With internet**
2. Edit a patient
3. Submit changes
4. **Expected:**
   - PUT to `/pasien/{id}`
   - Local DB updated
   - Changes reflected immediately
5. **Verify:** Console shows server and local update

### Test Scenario 6: Search Online vs Offline

**Online:**

1. Type search query
2. **Expected:** API call to `/pasien?search=query`
3. Results from server

**Offline:**

1. Type search query
2. **Expected:** Local database search
3. Results from local data

## Error Handling

### API Errors

```dart
try {
  final remotePasien = await _remoteDataSource.createPasien(data);
  // ...
} catch (e) {
  debugPrint('⚠️ Failed to create on server, saving locally: $e');
  // Fallback to local
  return await _localDataSource.createPasien(data);
}
```

**Common API Errors:**

- Network timeout
- 404 Not Found
- 500 Server Error
- Validation errors (422)

All errors are caught and logged, with graceful fallback to local operations.

### Local Database Errors

```dart
Future<Pasien> getPasienById(String id) async {
  final driftPasien = await _database.getPasienById(int.parse(id));
  if (driftPasien == null) {
    throw Exception('Pasien dengan ID $id tidak ditemukan');
  }
  return _toDomainModel(driftPasien);
}
```

## Console Logs

### Successful Operations

```
✅ Synced 5 patients from API
✅ Patient created on server and synced locally
✅ Patient updated on server and locally
✅ Patient deleted from server and locally
```

### Offline/Fallback Operations

```
⚠️ Failed to sync from API (offline mode): SocketException
⚠️ Failed to create on server, saving locally: DioException
⚠️ API search failed, using local search: TimeoutException
```

### Debug Information

```
📂 Loading patient by ID: 1
🔄 Updating patient ID: 1 with data: {nama: Jane Doe, ...}
```

## Configuration

### Change API Base URL

Edit `lib/core/network/dio.dart`:

```dart
final dio = Dio(BaseOptions(
  baseUrl: 'http://your-api-url.com/api', // Change this
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
));
```

### Adjust Timeout

```dart
// In pasien_data_source.dart
Future<void> deletePasien(String id) async {
  await _dio
      .delete('/pasien/$id')
      .timeout(
        const Duration(seconds: 30), // Increase timeout
      );
}
```

## Migration from Local-Only to API

**Before (Local Only):**

```dart
Future<List<Pasien>> getAllPasien() async {
  return await _localDataSource.getAllPasien();
}
```

**After (Offline-First):**

```dart
Future<List<Pasien>> getAllPasien() async {
  final localPatients = await _localDataSource.getAllPasien();
  _fetchAndSyncFromApi(); // Background sync
  return localPatients;
}
```

**Benefits:**

- ✅ No breaking changes to UI
- ✅ Instant response time maintained
- ✅ Automatic background sync
- ✅ Offline support preserved

## Next Steps

After patient module is tested and working:

1. **Registrasi Module** - Same pattern
   - Endpoint: `/registrasi`
   - Offline-first strategy
2. **Anamnesa Module** - Child of Registrasi

   - Endpoint: `/anamnesa`
   - Dependency: Registrasi must be synced first

3. **Tindakan Module** - Master + Junction

   - Endpoint: `/tindakan`
   - Similar to ICD implementation

4. **Tagihan Module** - Billing
   - Endpoint: `/tagihan`
   - Depends on Registrasi + Tindakan

---

**Status:** ✅ **IMPLEMENTED**  
**Last Updated:** November 26, 2025  
**Module:** Patient (Pasien)
