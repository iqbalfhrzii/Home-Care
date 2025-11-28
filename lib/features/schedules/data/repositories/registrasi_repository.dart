import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:homecare_mobile/features/schedules/domain/models/registrasi.dart';
import 'package:homecare_mobile/features/schedules/data/datasources/registrasi_data_source.dart';
import 'package:homecare_mobile/features/schedules/data/datasources/registrasi_local_datasource.dart';
import 'package:homecare_mobile/features/patients/data/datasources/pasien_local_data_source.dart';

class RegistrasiRepository {
  final RegistrasiDataSource _remoteDataSource;
  final RegistrasiLocalDataSource _localDataSource;
  final PasienLocalDataSource _pasienLocalDataSource;

  RegistrasiRepository(
    this._remoteDataSource,
    this._localDataSource,
    this._pasienLocalDataSource,
  );

  // ========== OFFLINE-FIRST STRATEGY ==========

  /// Get all registrations
  /// Fetch directly from API to get complete data with nested pasien
  Future<List<Registrasi>> getAllRegistrasi() async {
    const maxAttempts = 3;
    const delays = [
      Duration(milliseconds: 500),
      Duration(seconds: 1),
      Duration(seconds: 2),
    ];

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final isLast = attempt == maxAttempts - 1;
      try {
        debugPrint(
          '🔄 Fetching registrations from /registrasi API (attempt ${attempt + 1})...',
        );
        final response = await _remoteDataSource.getAllRegistrasi();
        debugPrint(
          '📥 Received ${response.data.length} registrations from API',
        );

        // Sync to local in background (optional, for offline support)
        _syncToLocal(response.data);

        return response.data;
      } on DioException catch (e) {
        final transient =
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.unknown;
        debugPrint('❌ Network error getting registrations: ${e.type}');
        debugPrint('   Message: ${e.message}');

        if (!transient || isLast) {
          // On non-transient or final failure, fallback to local data
          break;
        }
        // backoff then retry
        final delay = delays[attempt];
        debugPrint('⏳ Retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
      } on FormatException catch (e) {
        // JSON parsing error - return empty, don't use corrupted data
        debugPrint('❌ JSON parsing error: ${e.message}');
        debugPrint('   Offset: ${e.offset}');
        // Fallback to local
        break;
      } catch (e, stackTrace) {
        debugPrint('❌ Unexpected error getting registrations: $e');
        debugPrint('   Stack: $stackTrace');
        // Fallback to local
        break;
      }
    }

    // Local fallback enriched with local patient data
    try {
      debugPrint('💾 Falling back to local registrations...');
      final locals = await _localDataSource.getAllRegistrasi();
      final enriched = <Registrasi>[];
      for (final reg in locals) {
        try {
          final pasien = await _pasienLocalDataSource.getPasienById(
            reg.pasienId,
          );
          enriched.add(
            Registrasi(
              id: reg.id,
              noReg: reg.noReg,
              noUrut: reg.noUrut,
              pasienId: reg.pasienId,
              tglJamReg: reg.tglJamReg,
              tglJamKunjungan: reg.tglJamKunjungan,
              kodePoli: reg.kodePoli,
              dokterId: reg.dokterId,
              jenisKunjungan: reg.jenisKunjungan,
              asalPasien: reg.asalPasien,
              tipePasien: reg.tipePasien,
              pasienBaru: reg.pasienBaru,
              pagiSore: reg.pagiSore,
              isCash: reg.isCash,
              isPribadi: reg.isPribadi,
              eselon: reg.eselon,
              status: reg.status,
              penanggungId: reg.penanggungId,
              penanggungNama: reg.penanggungNama,
              penanggungNoPegawai: reg.penanggungNoPegawai,
              penanggungAlamat: reg.penanggungAlamat,
              penanggungTelepon: reg.penanggungTelepon,
              pasien: pasien,
              createdAt: reg.createdAt,
              updatedAt: reg.updatedAt,
            ),
          );
        } catch (_) {
          enriched.add(reg); // No local patient found; keep as-is
        }
      }
      debugPrint(
        '💾 Returning ${enriched.length} registrations from local fallback',
      );
      return enriched;
    } catch (fallbackErr) {
      debugPrint('❌ Local fallback failed: $fallbackErr');
      return [];
    }
  }

  /// Sync registrations to local database in background
  Future<void> _syncToLocal(List<Registrasi> registrations) async {
    try {
      for (var registrasi in registrations) {
        try {
          await _localDataSource.upsertRegistrasi(registrasi);
        } catch (e) {
          debugPrint(
            '⚠️ Failed to save registrasi ${registrasi.id} to local: $e',
          );
        }
      }
      debugPrint('✅ Synced ${registrations.length} registrations to local DB');
    } catch (e) {
      debugPrint('⚠️ Error syncing to local: $e');
    }
  }

  /// Get registration by ID
  Future<Registrasi> getRegistrasiById(int id) async {
    try {
      // Use local database only (API returns 405)
      final localRegistrasi = await _localDataSource.getRegistrasiById(id);
      return localRegistrasi;
    } catch (e) {
      debugPrint('❌ Error getting registration from local DB: $e');
      rethrow;
    }
  }

  /// Get registrations by patient ID
  Future<List<Registrasi>> getRegistrasiByPasienId(int pasienId) async {
    try {
      // Use local database only (API returns 405)
      return await _localDataSource.getRegistrasiByPasienId(pasienId);
    } catch (e) {
      debugPrint('❌ Error getting registrations by patient: $e');
      rethrow;
    }
  }

  /// Create registration
  Future<Registrasi> createRegistrasi(Map<String, dynamic> data) async {
    try {
      debugPrint('🚀 Creating registration via API...');

      // Try to create on server first
      final remoteRegistrasi = await _remoteDataSource.createRegistrasi(data);

      debugPrint(
        '✅ Registration created on server with ID: ${remoteRegistrasi.id}',
      );

      // Save to local database for offline access
      await _localDataSource.upsertRegistrasi(remoteRegistrasi);
      debugPrint('✅ Registration synced to local database');

      return remoteRegistrasi;
    } on DioException catch (e) {
      debugPrint('⚠️ Failed to create on server (DioException): ${e.message}');
      debugPrint('   Status: ${e.response?.statusCode}');
      debugPrint('   Response: ${e.response?.data}');
      debugPrint('💾 Falling back to local database only');

      // Fallback: Save locally only
      return await _localDataSource.createRegistrasi(data);
    } catch (e, stackTrace) {
      debugPrint('⚠️ Failed to create on server: $e');
      debugPrint('   StackTrace: $stackTrace');
      debugPrint('💾 Falling back to local database only');

      // Fallback: Save locally only
      return await _localDataSource.createRegistrasi(data);
    }
  }

  /// Update registration
  /// NOTE: API disabled - endpoint returns 405
  Future<Registrasi> updateRegistrasi(int id, Map<String, dynamic> data) async {
    debugPrint('⏸️ API update disabled - updating local database only');

    // Update local database only (API returns 405)
    return await _localDataSource.updateRegistrasi(id, data);

    /* DISABLED - API returns 405
    try {
      // Try to update on server first
      final remoteRegistrasi = await _remoteDataSource.updateRegistrasi(
        id,
        data,
      );

      // Update local database
      await _localDataSource.updateRegistrasi(id, data);

      debugPrint('✅ Registration updated on server and locally');
      return remoteRegistrasi;
    } catch (e) {
      debugPrint('⚠️ Failed to update on server, updating locally: $e');

      // Fallback: Update locally only
      return await _localDataSource.updateRegistrasi(id, data);
    }
    */
  }

  /// Delete registration
  /// NOTE: API disabled - endpoint returns 405
  Future<void> deleteRegistrasi(int id) async {
    debugPrint('⏸️ API delete disabled - deleting from local database only');

    // Delete from local database only (API returns 405)
    await _localDataSource.deleteRegistrasi(id);

    /* DISABLED - API returns 405
    try {
      // Try to delete on server first
      await _remoteDataSource.deleteRegistrasi(id);

      // Delete from local database
      await _localDataSource.deleteRegistrasi(id);

      debugPrint('✅ Registration deleted from server and locally');
    } catch (e) {
      debugPrint('⚠️ Failed to delete on server, deleting locally: $e');

      // Fallback: Delete locally only
      await _localDataSource.deleteRegistrasi(id);
    }
    */
  }

  /// Search registrations
  Future<List<Registrasi>> searchRegistrasi(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllRegistrasi();
      }

      // Use local search only (API returns 405)
      final allRegistrasis = await _localDataSource.getAllRegistrasi();
      return allRegistrasis.where((reg) {
        final searchLower = query.toLowerCase();
        return reg.noReg.toLowerCase().contains(searchLower) ||
            (reg.noUrut?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error searching registrations: $e');
      rethrow;
    }
  }

  /// Get registrations by date
  Future<List<Registrasi>> getRegistrasiByDate(String date) async {
    try {
      // Use local database only (API returns 405)
      final allRegistrasis = await _localDataSource.getAllRegistrasi();
      return allRegistrasis.where((reg) {
        return reg.tglJamReg.startsWith(date);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting registrations by date: $e');
      rethrow;
    }
  }
}
