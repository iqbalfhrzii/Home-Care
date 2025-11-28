import 'package:homecare_mobile/features/schedules/data/datasources/anamnesa_data_source.dart';
import 'package:homecare_mobile/features/schedules/data/datasources/anamnesa_local_datasource.dart';
import 'package:homecare_mobile/features/schedules/domain/models/anamnesa.dart';

class AnamnesaRepository {
  final AnamnesaDataSource _remoteDataSource;
  final AnamnesaLocalDataSource _localDataSource;

  AnamnesaRepository(this._remoteDataSource, this._localDataSource);

  // Get all anamnesa - Offline-first
  Future<List<Anamnesa>> getAllAnamnesa() async {
    // 1. Load from local database first (instant display)
    final localAnamnesas = await _localDataSource.getAllAnamnesa();

    // 2. Fetch from API in background (non-blocking)
    _fetchAndSyncFromApi();

    return localAnamnesas;
  }

  // Background sync from API
  Future<void> _fetchAndSyncFromApi() async {
    try {
      final response = await _remoteDataSource.getAllAnamnesa();

      // Update local database with API data
      for (var anamnesa in response.data) {
        await _localDataSource.upsertAnamnesa(anamnesa);
      }

      print('✅ Synced ${response.data.length} anamnesa from API');
    } catch (e) {
      // Silent fail - offline support
      print('⚠️ Failed to sync anamnesa from API (offline mode): $e');
    }
  }

  // Get anamnesa by ID
  Future<Anamnesa> getAnamnesaById(int id) async {
    try {
      // Try to get from API first
      final anamnesa = await _remoteDataSource.getAnamnesaById(id);

      // Update local cache
      await _localDataSource.upsertAnamnesa(anamnesa);

      return anamnesa;
    } catch (apiError) {
      // Fallback to local database
      print('⚠️ API failed, using local data: $apiError');
      return await _localDataSource.getAnamnesaById(id);
    }
  }

  // Get anamnesa by registrasi ID - Try API first
  Future<List<Anamnesa>> getAnamnesaByRegistrasiId(int registrasiId) async {
    try {
      final response = await _remoteDataSource.getAnamnesaByRegistrasiId(
        registrasiId,
      );

      // Update local cache
      for (var anamnesa in response.data) {
        await _localDataSource.upsertAnamnesa(anamnesa);
      }

      return response.data;
    } catch (apiError) {
      // Fallback to local database
      print('⚠️ API failed, using local data: $apiError');
      return await _localDataSource.getAnamnesaByRegistrasiId(registrasiId);
    }
  }

  // Create anamnesa - Try server first
  Future<Anamnesa> createAnamnesa(Map<String, dynamic> data) async {
    try {
      // Try to create on server first
      final remoteAnamnesa = await _remoteDataSource.createAnamnesa(data);

      // Save to local database with server ID
      await _localDataSource.upsertAnamnesa(remoteAnamnesa);

      print('✅ Anamnesa created on server and synced locally');
      return remoteAnamnesa;
    } catch (e) {
      // Fallback: Save locally only (will sync via SyncService later)
      print('⚠️ Failed to create on server, saving locally: $e');
      return await _localDataSource.createAnamnesa(data);
    }
  }

  // Update anamnesa - Try server first
  Future<Anamnesa> updateAnamnesa(int id, Map<String, dynamic> data) async {
    try {
      // Try to update on server first
      final remoteAnamnesa = await _remoteDataSource.updateAnamnesa(id, data);

      // Update local database
      await _localDataSource.upsertAnamnesa(remoteAnamnesa);

      print('✅ Anamnesa updated on server and locally');
      return remoteAnamnesa;
    } catch (e) {
      // Fallback: Update locally only
      print('⚠️ Failed to update on server, updating locally: $e');
      return await _localDataSource.updateAnamnesa(id, data);
    }
  }

  // Delete anamnesa - Try server first
  Future<void> deleteAnamnesa(int id) async {
    try {
      // Try to delete on server first
      await _remoteDataSource.deleteAnamnesa(id);

      // Delete from local database
      await _localDataSource.deleteAnamnesa(id);

      print('✅ Anamnesa deleted from server and locally');
    } catch (e) {
      // Fallback: Delete locally only
      print('⚠️ Failed to delete on server, deleting locally: $e');
      await _localDataSource.deleteAnamnesa(id);
    }
  }

  // Search anamnesa - Try API first
  Future<List<Anamnesa>> searchAnamnesa(String query) async {
    try {
      final response = await _remoteDataSource.searchAnamnesa(query);

      // Update local cache
      for (var anamnesa in response.data) {
        await _localDataSource.upsertAnamnesa(anamnesa);
      }

      return response.data;
    } catch (apiError) {
      // Fallback to local search
      print('⚠️ API search failed, using local search: $apiError');
      return await _localDataSource.searchAnamnesa(query);
    }
  }

  // Get anamnesa by date - Try API first
  Future<List<Anamnesa>> getAnamnesaByDate(String date) async {
    try {
      final response = await _remoteDataSource.getAnamnesaByDate(date);

      // Update local cache
      for (var anamnesa in response.data) {
        await _localDataSource.upsertAnamnesa(anamnesa);
      }

      return response.data;
    } catch (apiError) {
      // Fallback to local filter
      print('⚠️ API failed, using local filter: $apiError');
      return await _localDataSource.getAnamnesaByDate(date);
    }
  }
}
