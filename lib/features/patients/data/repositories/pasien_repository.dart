import 'package:dio/dio.dart';
import 'package:homecare_mobile/features/patients/domain/models/pasien.dart';
import 'package:homecare_mobile/features/patients/data/datasources/pasien_data_source.dart';
import 'package:homecare_mobile/features/patients/data/datasources/pasien_local_data_source.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';
import 'package:flutter/foundation.dart';

class PasienRepository {
  final PasienDataSource _remoteDataSource;
  final PasienLocalDataSource _localDataSource;
  final RegistrasiRepository _registrasiRepository;

  // Cache untuk menyimpan data pasien dengan field registrasi intact
  List<Pasien>? _cachedPatients;

  PasienRepository(
    this._remoteDataSource,
    this._localDataSource,
    this._registrasiRepository,
  );

  // ========== OFFLINE-FIRST STRATEGY ==========
  // STRATEGI BARU: Ambil dari /registrasi yang sudah include data pasien
  // 1. Fetch dari /registrasi (dapat pasien nested + status registrasi)
  // 2. Extract unique pasien dari registrasi
  // 3. Merge dengan pasien yang belum pernah registrasi
  // 4. Return semua pasien dengan flag isRegistered

  Future<List<Pasien>> getAllPasien() async {
    try {
      // 1. Jika ada cache, return cache (data dengan field registrasi intact)
      if (_cachedPatients != null && _cachedPatients!.isNotEmpty) {
        debugPrint('📦 Returning cached patients: ${_cachedPatients!.length}');
        // Refresh di background (tidak menunggu, tidak throw error)
        _fetchAndSyncFromRegistrasi().catchError((e) {
          debugPrint('⚠️ Background sync failed (using cached data): $e');
        });
        return _cachedPatients!;
      }

      // 2. Jika belum ada cache, load dari local first (instant)
      final localPatients = await _localDataSource.getAllPasien();

      // 3. Jika data kosong atau sedikit, fetch dari API dulu (first time)
      if (localPatients.isEmpty || localPatients.length < 5) {
        debugPrint('📥 No/limited local data, fetching from API first...');
        try {
          await _fetchAndSyncFromRegistrasi();
          return _cachedPatients ?? localPatients;
        } catch (e) {
          debugPrint('⚠️ API fetch failed, using local data: $e');
          return localPatients;
        }
      }

      // 4. Fetch dan sync dari API di background untuk update (jangan throw error)
      _fetchAndSyncFromRegistrasi().catchError((e) {
        debugPrint('⚠️ Background sync failed (using local data): $e');
      });

      return localPatients;
    } catch (e) {
      debugPrint('❌ Error getting patients: $e');
      // Return cached data jika ada, jika tidak ada baru throw error
      if (_cachedPatients != null && _cachedPatients!.isNotEmpty) {
        debugPrint('⚠️ Using cached data due to error');
        return _cachedPatients!;
      }
      rethrow;
    }
  }

  Future<void> _fetchAndSyncFromRegistrasi({bool strict = false}) async {
    try {
      debugPrint('🔄 Starting sync patients from /registrasi API...');

      // Ambil semua pasien dari API /pasien
      final allPasienResponse = await _remoteDataSource.getAllPasien();
      debugPrint(
        '📥 Received ${allPasienResponse.data.length} patients from /pasien API',
      );

      // Build map untuk dedup
      final pasienMap = <int, Pasien>{};
      for (var pasien in allPasienResponse.data) {
        pasienMap[pasien.id] = pasien;
      }
      debugPrint('📦 Initial patients from /pasien: ${pasienMap.length}');

      // Ambil data registrasi untuk mendapatkan pasien yang sudah teregistrasi
      debugPrint('🔄 Fetching registrations from /registrasi...');
      final registrasis = await _registrasiRepository.getAllRegistrasi();
      debugPrint('📥 Received ${registrasis.length} registrations');

      // If registrasi returns empty, preserve previous cache to avoid flicker/regression
      if (registrasis.isEmpty) {
        if (_cachedPatients != null && _cachedPatients!.isNotEmpty) {
          debugPrint(
            '⚠️ Registrasi empty from API, preserving cached registration flags',
          );
          // Still upsert base patients for freshness
          for (var pasien in pasienMap.values) {
            await _localDataSource.upsertPasien(pasien);
          }
          return; // keep existing _cachedPatients
        }
      }

      // Track pasien yang sudah registrasi
      final registeredPasienIds = <int>{};

      // Extract pasien dari setiap registrasi
      for (var registrasi in registrasis) {
        if (registrasi.pasien != null) {
          final pasien = registrasi.pasien!;
          registeredPasienIds.add(pasien.id);

          // Update atau tambahkan pasien dengan data registrasi
          if (pasienMap.containsKey(pasien.id)) {
            // Pasien sudah ada dari /pasien, update dengan registrasi
            pasienMap[pasien.id] = pasienMap[pasien.id]!.copyWith(
              registrasi: [registrasi],
            );
          } else {
            // Pasien baru dari registrasi (tidak ada di /pasien)
            pasienMap[pasien.id] = pasien.copyWith(registrasi: [registrasi]);
          }
        }
      }

      // Calculate statistics
      final unregisteredCount = pasienMap.length - registeredPasienIds.length;
      debugPrint('📊 Total unique patients: ${pasienMap.length}');
      debugPrint('📊 ✅ Registered patients: ${registeredPasienIds.length}');
      debugPrint('📊 ⏳ Unregistered patients: $unregisteredCount');

      // Update local database with all patients (for offline access)
      for (var pasien in pasienMap.values) {
        await _localDataSource.upsertPasien(pasien);
      }

      debugPrint(
        '✅ Synced ${pasienMap.length} patients (${registeredPasienIds.length} registered)',
      );

      // Return data from memory (with registrasi field intact)
      // instead of re-querying from database
      _cachedPatients = pasienMap.values.toList();
    } on DioException catch (e) {
      debugPrint('⚠️ DioException syncing patients:');
      debugPrint('   Type: ${e.type}');
      debugPrint('   Message: ${e.message}');
      debugPrint('   Status: ${e.response?.statusCode}');
      if (strict) rethrow;
    } catch (e, stackTrace) {
      debugPrint('⚠️ Failed to sync from API (offline mode): $e');
      debugPrint('   StackTrace: $stackTrace');
      if (strict) rethrow;
    }
  }

  // _fetchAndSyncFromApi unused; removed to satisfy lints

  Future<Pasien> getPasienById(int id) async {
    try {
      // Try local first
      final localPasien = await _localDataSource.getPasienById(id);

      // Try to fetch latest from API (background)
      _remoteDataSource
          .getPasienById(id)
          .then((remotePasien) {
            _localDataSource.upsertPasien(remotePasien);
          })
          .catchError((e) {
            debugPrint('⚠️ Failed to fetch patient from API: $e');
          });

      return localPasien;
    } catch (e) {
      // If not in local, try API
      try {
        final remotePasien = await _remoteDataSource.getPasienById(id);
        await _localDataSource.upsertPasien(remotePasien);
        return remotePasien;
      } catch (apiError) {
        debugPrint('❌ Error getting patient: $apiError');
        rethrow;
      }
    }
  }

  Future<Pasien> createPasien({
    required String nama,
    required String tanggalLahir,
    required String jenisKelamin,
    required String alamat,
    required String telepon,
  }) async {
    final data = {
      'nama': nama,
      'tanggal_lahir': tanggalLahir,
      'jenis_kelamin': jenisKelamin,
      'alamat': alamat,
      'telepon': telepon,
    };

    try {
      // Try to create on server first
      final remotePasien = await _remoteDataSource.createPasien(data);

      // Save to local database
      await _localDataSource.upsertPasien(remotePasien);

      debugPrint('✅ Patient created on server and synced locally');
      return remotePasien;
    } catch (e) {
      debugPrint('⚠️ Failed to create on server, saving locally: $e');

      // Fallback: Save locally only
      return await _localDataSource.createPasien(data);
    }
  }

  Future<Pasien> updatePasien({
    required int id,
    required String nama,
    required String tanggalLahir,
    required String jenisKelamin,
    required String alamat,
    required String telepon,
  }) async {
    final data = {
      'nama': nama,
      'tanggal_lahir': tanggalLahir,
      'jenis_kelamin': jenisKelamin,
      'alamat': alamat,
      'telepon': telepon,
    };

    try {
      // Try to update on server first
      final remotePasien = await _remoteDataSource.updatePasien(id, data);

      // Update local database
      await _localDataSource.updatePasien(id, data);

      debugPrint('✅ Patient updated on server and locally');
      return remotePasien;
    } catch (e) {
      debugPrint('⚠️ Failed to update on server, updating locally: $e');

      // Fallback: Update locally only
      return await _localDataSource.updatePasien(id, data);
    }
  }

  Future<void> deletePasien(int id) async {
    try {
      // Try to delete on server first
      await _remoteDataSource.deletePasien(id);

      // Delete from local database
      await _localDataSource.deletePasien(id);

      debugPrint('✅ Patient deleted from server and locally');
    } catch (e) {
      debugPrint('⚠️ Failed to delete on server, deleting locally: $e');

      // Fallback: Delete locally only
      await _localDataSource.deletePasien(id);
    }
  }

  Future<List<Pasien>> searchPasien(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllPasien();
      }

      // Try API search first
      try {
        final response = await _remoteDataSource.searchPasien(query);

        // Update local cache
        for (var pasien in response.data) {
          await _localDataSource.upsertPasien(pasien);
        }

        return response.data;
      } catch (apiError) {
        debugPrint('⚠️ API search failed, using local search: $apiError');

        // Fallback to local search
        final allPatients = await _localDataSource.getAllPasien();
        return allPatients.where((patient) {
          final searchLower = query.toLowerCase();
          return patient.nama.toLowerCase().contains(searchLower) ||
              patient.mrn.toLowerCase().contains(searchLower) ||
              patient.telepon.toLowerCase().contains(searchLower);
        }).toList();
      }
    } catch (e) {
      debugPrint('❌ Error searching patients: $e');
      rethrow;
    }
  }

  // ========== API-FIRST STRATEGY (requested) ==========
  /// Fetch patients from API first (including merging with registrasi),
  /// then fallback to local database if API fails.
  Future<List<Pasien>> getAllPasienApiFirst() async {
    try {
      debugPrint('🌐 [API-FIRST] Loading patients from API...');
      await _fetchAndSyncFromRegistrasi(strict: true);
      if (_cachedPatients != null && _cachedPatients!.isNotEmpty) {
        debugPrint(
          '🌐 [API-FIRST] Returning ${_cachedPatients!.length} patients from API',
        );
        return _cachedPatients!;
      }
      // If for some reason cache is empty after API, fallback to local
      final local = await _localDataSource.getAllPasien();
      debugPrint(
        '💾 [API-FIRST] Cache empty after API, returning local: ${local.length}',
      );
      return local;
    } catch (e) {
      debugPrint('⚠️ [API-FIRST] API failed, falling back to local: $e');
      return await _localDataSource.getAllPasien();
    }
  }
}
