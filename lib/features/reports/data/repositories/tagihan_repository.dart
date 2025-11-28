import 'package:homecare_mobile/features/reports/data/datasources/tagihan_data_source.dart';
import 'package:homecare_mobile/features/reports/data/datasources/tagihan_local_datasource.dart';
import 'package:homecare_mobile/features/reports/domain/models/tagihan.dart';

class TagihanRepository {
  final TagihanDataSource _remoteDataSource;
  final TagihanLocalDataSource _localDataSource;

  TagihanRepository(this._remoteDataSource, this._localDataSource);

  // ==================== TAGIHAN ====================

  // Get all tagihan - Offline-first
  Future<List<Tagihan>> getAllTagihan() async {
    // 1. Load from local database first (instant display)
    final localTagihan = await _localDataSource.getAllTagihan();

    // 2. Fetch from API in background (non-blocking)
    _fetchAndSyncFromApi();

    return localTagihan;
  }

  // Background sync from API
  Future<void> _fetchAndSyncFromApi() async {
    try {
      final response = await _remoteDataSource.getAllTagihan();

      // Update local database with API data
      for (var tagihan in response.data) {
        await _localDataSource.upsertTagihan(tagihan);

        // Also sync items if available
        if (tagihan.items != null) {
          for (var item in tagihan.items!) {
            await _localDataSource.upsertTagihanItem(item);
          }
        }
      }

      print('✅ Synced ${response.data.length} tagihan from API');
    } catch (e) {
      // Silent fail - offline support
      print('⚠️ Failed to sync tagihan from API (offline mode): $e');
    }
  }

  // Get tagihan by ID (with items)
  Future<Tagihan> getTagihanById(int id) async {
    try {
      // Try to get from API first
      final tagihan = await _remoteDataSource.getTagihanById(id);

      // Update local cache
      await _localDataSource.upsertTagihan(tagihan);

      // Sync items
      if (tagihan.items != null) {
        for (var item in tagihan.items!) {
          await _localDataSource.upsertTagihanItem(item);
        }
      }

      return tagihan;
    } catch (apiError) {
      // Fallback to local database
      print('⚠️ API failed, using local data: $apiError');
      final tagihan = await _localDataSource.getTagihanById(id);

      // Load items from local
      final items = await _localDataSource.getTagihanItems(id);
      return tagihan.copyWith(items: items);
    }
  }

  // Get tagihan by registrasi ID
  Future<List<Tagihan>> getTagihanByRegistrasiId(int registrasiId) async {
    try {
      final response = await _remoteDataSource.getTagihanByRegistrasiId(
        registrasiId,
      );

      // Update local cache
      for (var tagihan in response.data) {
        await _localDataSource.upsertTagihan(tagihan);
      }

      return response.data;
    } catch (apiError) {
      // Fallback to local database
      print('⚠️ API failed, using local data: $apiError');
      return await _localDataSource.getTagihanByRegistrasiId(registrasiId);
    }
  }

  // Get tagihan by payment status
  Future<List<Tagihan>> getTagihanByStatus(String status) async {
    try {
      final response = await _remoteDataSource.getTagihanByStatus(status);

      // Update local cache
      for (var tagihan in response.data) {
        await _localDataSource.upsertTagihan(tagihan);
      }

      return response.data;
    } catch (apiError) {
      // Fallback to local
      print('⚠️ API failed, using local data: $apiError');
      return await _localDataSource.getTagihanByStatus(status);
    }
  }

  // Get unpaid tagihan
  Future<List<Tagihan>> getUnpaidTagihan() async {
    return getTagihanByStatus('belum_bayar');
  }

  // Get paid tagihan
  Future<List<Tagihan>> getPaidTagihan() async {
    return getTagihanByStatus('lunas');
  }

  // Create tagihan - Try server first
  Future<Tagihan> createTagihan(Map<String, dynamic> data) async {
    try {
      // Try to create on server first
      final remoteTagihan = await _remoteDataSource.createTagihan(data);

      // Save to local database with server ID
      await _localDataSource.upsertTagihan(remoteTagihan);

      print('✅ Tagihan created on server and synced locally');
      return remoteTagihan;
    } catch (e) {
      // Fallback: Save locally only (will sync via SyncService later)
      print('⚠️ Failed to create on server, saving locally: $e');
      return await _localDataSource.createTagihan(data);
    }
  }

  // Update tagihan - Try server first
  Future<Tagihan> updateTagihan(int id, Map<String, dynamic> data) async {
    try {
      // Try to update on server first
      final remoteTagihan = await _remoteDataSource.updateTagihan(id, data);

      // Update local database
      await _localDataSource.upsertTagihan(remoteTagihan);

      print('✅ Tagihan updated on server and locally');
      return remoteTagihan;
    } catch (e) {
      // Fallback: Update locally only
      print('⚠️ Failed to update on server, updating locally: $e');
      return await _localDataSource.updateTagihan(id, data);
    }
  }

  // Mark as paid
  Future<Tagihan> markAsPaid(int id, Map<String, dynamic> paymentData) async {
    try {
      // Try to mark as paid on server
      final remoteTagihan = await _remoteDataSource.markAsPaid(id, paymentData);

      // Update local database
      await _localDataSource.upsertTagihan(remoteTagihan);

      print('✅ Tagihan marked as paid on server and locally');
      return remoteTagihan;
    } catch (e) {
      // Fallback: Update locally
      print('⚠️ Failed to mark as paid on server, updating locally: $e');
      final updateData = {'status_pembayaran': 'lunas', ...paymentData};
      return await _localDataSource.updateTagihan(id, updateData);
    }
  }

  // Delete tagihan - Try server first
  Future<void> deleteTagihan(int id) async {
    try {
      // Try to delete on server first
      await _remoteDataSource.deleteTagihan(id);

      // Delete from local database
      await _localDataSource.deleteTagihan(id);

      print('✅ Tagihan deleted from server and locally');
    } catch (e) {
      // Fallback: Delete locally only
      print('⚠️ Failed to delete on server, deleting locally: $e');
      await _localDataSource.deleteTagihan(id);
    }
  }

  // Search tagihan - Try API first
  Future<List<Tagihan>> searchTagihan(String query) async {
    try {
      final response = await _remoteDataSource.searchTagihan(query);

      // Update local cache
      for (var tagihan in response.data) {
        await _localDataSource.upsertTagihan(tagihan);
      }

      return response.data;
    } catch (apiError) {
      // Fallback to local search
      print('⚠️ API search failed, using local search: $apiError');
      return await _localDataSource.searchTagihan(query);
    }
  }

  // Get tagihan by date
  Future<List<Tagihan>> getTagihanByDate(String date) async {
    try {
      final response = await _remoteDataSource.getTagihanByDate(date);

      // Update local cache
      for (var tagihan in response.data) {
        await _localDataSource.upsertTagihan(tagihan);
      }

      return response.data;
    } catch (apiError) {
      // Fallback to local
      print('⚠️ API failed, using local filter: $apiError');
      // Simple local filter by tanggalInvoice
      final allTagihan = await _localDataSource.getAllTagihan();
      return allTagihan
          .where((t) => t.tanggalInvoice?.startsWith(date) ?? false)
          .toList();
    }
  }

  // ==================== TAGIHAN ITEMS ====================

  // Get tagihan items
  Future<List<TagihanItem>> getTagihanItems(int tagihanId) async {
    try {
      final response = await _remoteDataSource.getTagihanItems(tagihanId);

      // Update local cache
      for (var item in response.data) {
        await _localDataSource.upsertTagihanItem(item);
      }

      return response.data;
    } catch (apiError) {
      // Fallback to local
      print('⚠️ API failed, using local data: $apiError');
      return await _localDataSource.getTagihanItems(tagihanId);
    }
  }

  // Add tagihan item - Try server first
  Future<TagihanItem> addTagihanItem(
    int tagihanId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Try to add on server first
      final remoteItem = await _remoteDataSource.addTagihanItem(
        tagihanId,
        data,
      );

      // Save to local database
      await _localDataSource.upsertTagihanItem(remoteItem);

      print('✅ Tagihan item added on server and synced locally');
      return remoteItem;
    } catch (e) {
      // Fallback: Save locally only
      print('⚠️ Failed to add on server, saving locally: $e');
      return await _localDataSource.addTagihanItem(tagihanId, data);
    }
  }

  // Update tagihan item - Try server first
  Future<TagihanItem> updateTagihanItem(
    int tagihanId,
    int itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Try to update on server first
      final remoteItem = await _remoteDataSource.updateTagihanItem(
        tagihanId,
        itemId,
        data,
      );

      // Update local database
      await _localDataSource.upsertTagihanItem(remoteItem);

      print('✅ Tagihan item updated on server and locally');
      return remoteItem;
    } catch (e) {
      // Fallback: Update locally only
      print('⚠️ Failed to update on server, updating locally: $e');
      return await _localDataSource.updateTagihanItem(itemId, data);
    }
  }

  // Delete tagihan item - Try server first
  Future<void> deleteTagihanItem(int tagihanId, int itemId) async {
    try {
      // Try to delete on server first
      await _remoteDataSource.deleteTagihanItem(tagihanId, itemId);

      // Delete from local database
      await _localDataSource.deleteTagihanItem(itemId);

      print('✅ Tagihan item deleted from server and locally');
    } catch (e) {
      // Fallback: Delete locally only
      print('⚠️ Failed to delete on server, deleting locally: $e');
      await _localDataSource.deleteTagihanItem(itemId);
    }
  }
}
