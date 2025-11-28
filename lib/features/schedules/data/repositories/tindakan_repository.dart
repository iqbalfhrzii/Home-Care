import 'package:homecare_mobile/features/schedules/data/datasources/tindakan_data_source.dart';
import 'package:homecare_mobile/features/schedules/data/datasources/tindakan_local_datasource.dart';
import 'package:homecare_mobile/features/schedules/domain/models/tindakan.dart';

class TindakanRepository {
  final TindakanDataSource _remoteDataSource;
  final TindakanLocalDataSource _localDataSource;

  TindakanRepository(this._remoteDataSource, this._localDataSource);

  // ==================== MASTER TINDAKAN ====================

  // Get all tindakan - Offline-first
  Future<List<Tindakan>> getAllTindakan() async {
    // 1. Load from local database first (instant display)
    final localTindakan = await _localDataSource.getAllTindakan();

    // 2. Fetch from API in background (non-blocking)
    _fetchAndSyncFromApi();

    return localTindakan;
  }

  // Background sync from API
  Future<void> _fetchAndSyncFromApi() async {
    try {
      final response = await _remoteDataSource.getAllTindakan();

      // Update local database with API data
      for (var tindakan in response.data) {
        await _localDataSource.upsertTindakan(tindakan);
      }

      print('✅ Synced ${response.data.length} tindakan from API');
    } catch (e) {
      // Silent fail - offline support
      print('⚠️ Failed to sync tindakan from API (offline mode): $e');
    }
  }

  // Get tindakan by ID
  Future<Tindakan> getTindakanById(int id) async {
    try {
      // Try to get from API first
      final tindakan = await _remoteDataSource.getTindakanById(id);

      // Update local cache
      await _localDataSource.upsertTindakan(tindakan);

      return tindakan;
    } catch (apiError) {
      // Fallback to local database
      print('⚠️ API failed, using local data: $apiError');
      return await _localDataSource.getTindakanById(id);
    }
  }

  // Get active tindakan - Offline-first
  Future<List<Tindakan>> getActiveTindakan() async {
    try {
      final response = await _remoteDataSource.getActiveTindakan();

      // Update local cache
      for (var tindakan in response.data) {
        await _localDataSource.upsertTindakan(tindakan);
      }

      return response.data;
    } catch (apiError) {
      // Fallback to local
      print('⚠️ API failed, using local data: $apiError');
      return await _localDataSource.getActiveTindakan();
    }
  }

  // Create tindakan - Try server first
  Future<Tindakan> createTindakan(Map<String, dynamic> data) async {
    try {
      // Try to create on server first
      final remoteTindakan = await _remoteDataSource.createTindakan(data);

      // Save to local database with server ID
      await _localDataSource.upsertTindakan(remoteTindakan);

      print('✅ Tindakan created on server and synced locally');
      return remoteTindakan;
    } catch (e) {
      // Fallback: Save locally only (will sync via SyncService later)
      print('⚠️ Failed to create on server, saving locally: $e');
      return await _localDataSource.createTindakan(data);
    }
  }

  // Update tindakan - Try server first
  Future<Tindakan> updateTindakan(int id, Map<String, dynamic> data) async {
    try {
      // Try to update on server first
      final remoteTindakan = await _remoteDataSource.updateTindakan(id, data);

      // Update local database
      await _localDataSource.upsertTindakan(remoteTindakan);

      print('✅ Tindakan updated on server and locally');
      return remoteTindakan;
    } catch (e) {
      // Fallback: Update locally only
      print('⚠️ Failed to update on server, updating locally: $e');
      return await _localDataSource.updateTindakan(id, data);
    }
  }

  // Delete tindakan - Try server first
  Future<void> deleteTindakan(int id) async {
    try {
      // Try to delete on server first
      await _remoteDataSource.deleteTindakan(id);

      // Delete from local database
      await _localDataSource.deleteTindakan(id);

      print('✅ Tindakan deleted from server and locally');
    } catch (e) {
      // Fallback: Delete locally only
      print('⚠️ Failed to delete on server, deleting locally: $e');
      await _localDataSource.deleteTindakan(id);
    }
  }

  // Search tindakan - Try API first
  Future<List<Tindakan>> searchTindakan(String query) async {
    try {
      final response = await _remoteDataSource.searchTindakan(query);

      // Update local cache
      for (var tindakan in response.data) {
        await _localDataSource.upsertTindakan(tindakan);
      }

      return response.data;
    } catch (apiError) {
      // Fallback to local search
      print('⚠️ API search failed, using local search: $apiError');
      return await _localDataSource.searchTindakan(query);
    }
  }

  // ==================== REGISTRASI-TINDAKAN ====================

  // Get tindakan by registrasi ID - Try API first
  Future<List<RegistrasiTindakan>> getTindakanByRegistrasiId(
    int registrasiId,
  ) async {
    try {
      final response = await _remoteDataSource.getTindakanByRegistrasiId(
        registrasiId,
      );

      // Update local cache
      for (var rt in response.data) {
        await _localDataSource.upsertRegistrasiTindakan(rt);
      }

      return response.data;
    } catch (apiError) {
      // Fallback to local database
      print('⚠️ API failed, using local data: $apiError');
      return await _localDataSource.getRegistrasiTindakanByRegistrasiId(
        registrasiId,
      );
    }
  }

  // Attach tindakan to registrasi - Try server first
  Future<RegistrasiTindakan> attachTindakanToRegistrasi(
    int registrasiId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Try to attach on server first
      final remoteRT = await _remoteDataSource.attachTindakanToRegistrasi(
        registrasiId,
        data,
      );

      // Save to local database
      await _localDataSource.upsertRegistrasiTindakan(remoteRT);

      print('✅ Tindakan attached on server and synced locally');
      return remoteRT;
    } catch (e) {
      // Fallback: Save locally only (will sync via SyncService later)
      print('⚠️ Failed to attach on server, saving locally: $e');
      return await _localDataSource.attachTindakanToRegistrasi(
        registrasiId,
        data,
      );
    }
  }

  // Update registrasi-tindakan pivot data - Try server first
  Future<RegistrasiTindakan> updateRegistrasiTindakan(
    int registrasiId,
    int tindakanId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Try to update on server first
      final remoteRT = await _remoteDataSource.updateRegistrasiTindakan(
        registrasiId,
        tindakanId,
        data,
      );

      // Update local database
      await _localDataSource.upsertRegistrasiTindakan(remoteRT);

      print('✅ Registrasi-tindakan updated on server and locally');
      return remoteRT;
    } catch (e) {
      // Fallback: Update locally only
      print('⚠️ Failed to update on server, updating locally: $e');
      // Find local record by registrasiId + tindakanId
      final localRecords = await _localDataSource
          .getRegistrasiTindakanByRegistrasiId(registrasiId);
      final record = localRecords.firstWhere(
        (rt) => rt.tindakanId == tindakanId,
        orElse: () => throw Exception('Registrasi-tindakan not found locally'),
      );
      return await _localDataSource.updateRegistrasiTindakan(record.id, data);
    }
  }

  // Detach tindakan from registrasi - Try server first
  Future<void> detachTindakanFromRegistrasi(
    int registrasiId,
    int tindakanId,
  ) async {
    try {
      // Try to detach on server first
      await _remoteDataSource.detachTindakanFromRegistrasi(
        registrasiId,
        tindakanId,
      );

      // Find and delete from local
      final localRecords = await _localDataSource
          .getRegistrasiTindakanByRegistrasiId(registrasiId);
      final record = localRecords.firstWhere(
        (rt) => rt.tindakanId == tindakanId,
        orElse: () => throw Exception('Registrasi-tindakan not found locally'),
      );
      await _localDataSource.detachTindakanFromRegistrasi(record.id);

      print('✅ Tindakan detached from server and locally');
    } catch (e) {
      // Fallback: Delete locally only
      print('⚠️ Failed to detach on server, deleting locally: $e');
      final localRecords = await _localDataSource
          .getRegistrasiTindakanByRegistrasiId(registrasiId);
      final record = localRecords.firstWhere(
        (rt) => rt.tindakanId == tindakanId,
        orElse: () => throw Exception('Registrasi-tindakan not found locally'),
      );
      await _localDataSource.detachTindakanFromRegistrasi(record.id);
    }
  }
}
