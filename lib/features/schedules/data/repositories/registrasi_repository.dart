import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:homecare_mobile/features/schedules/domain/models/registrasi.dart';
import 'package:homecare_mobile/features/schedules/data/datasources/registrasi_data_source.dart';
import 'package:homecare_mobile/features/schedules/data/datasources/registrasi_local_datasource.dart';

class RegistrasiRepository {
  final RegistrasiDataSource _remoteDataSource;
  final RegistrasiLocalDataSource _localDataSource;

  RegistrasiRepository(this._remoteDataSource, this._localDataSource);

  // ========== OFFLINE-FIRST STRATEGY ==========

  /// Get all registrations
  /// Fetch directly from API to get complete data with nested pasien
  Future<List<Registrasi>> getAllRegistrasi() async {
    try {
      debugPrint('🔄 Fetching registrations from /registrasi API...');
      final response = await _remoteDataSource.getAllRegistrasi();
      debugPrint('📥 Received ${response.data.length} registrations from API');

      // Sync to local in background (optional, for offline support)
      _syncToLocal(response.data);

      return response.data;
    } on DioException catch (e) {
      // Network errors - return empty, don't fallback to local without pasien data
      debugPrint('❌ Network error getting registrations: ${e.type}');
      debugPrint('   Message: ${e.message}');
      return [];
    } on FormatException catch (e) {
      // JSON parsing error - return empty, don't use corrupted data
      debugPrint('❌ JSON parsing error: ${e.message}');
      debugPrint('   Offset: ${e.offset}');
      return [];
    } catch (e, stackTrace) {
      debugPrint('❌ Unexpected error getting registrations: $e');
      debugPrint('   Stack: $stackTrace');
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
