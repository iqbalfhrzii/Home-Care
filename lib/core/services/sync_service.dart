import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:homecare_mobile/shared/local_db/app_database.dart';
import 'package:flutter/foundation.dart';

/// Service untuk auto-sync data offline ke server
class SyncService {
  final AppDatabase _database;
  final Dio _dio;
  final Connectivity _connectivity;

  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService(this._database, this._dio, this._connectivity);

  /// Start auto-sync service
  /// Will sync when:
  /// 1. Internet connection is available
  /// 2. Every 5 minutes (configurable)
  /// 3. When connectivity changes from offline to online
  void startAutoSync() {
    debugPrint('🔄 SyncService: Starting auto-sync...');

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final hasConnection = results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

      if (hasConnection && !_isSyncing) {
        debugPrint('🌐 SyncService: Connection detected, starting sync...');
        syncAll();
      }
    });

    // Periodic sync every 5 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncAll();
    });

    // Initial sync
    syncAll();
  }

  /// Stop auto-sync service
  void stopAutoSync() {
    debugPrint('⏹️ SyncService: Stopping auto-sync...');
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  /// Manual trigger untuk sync semua data yang belum ter-sync
  Future<void> syncAll() async {
    if (_isSyncing) {
      debugPrint('⏳ SyncService: Sync already in progress, skipping...');
      return;
    }

    try {
      _isSyncing = true;

      // Check internet connection
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasConnection = connectivityResult.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

      if (!hasConnection) {
        debugPrint('📴 SyncService: No internet connection, skipping sync');
        return;
      }

      final unsyncedCount = await _database.getUnsyncedCount();

      if (unsyncedCount == 0) {
        debugPrint('✅ SyncService: No data to sync');
        return;
      }

      debugPrint('🔄 SyncService: Starting sync for $unsyncedCount items...');

      // Sync in order: Registrasi → Anamnesa → ICD → Tindakan
      // NOTE: GET /registrasi returns 405, but POST /registrasi works for creating
      await _syncRegistrasis();
      await _syncAnamnesas();
      await _syncRegistrasiIcds();
      await _syncRegistrasiTindakans();

      final remainingCount = await _database.getUnsyncedCount();
      debugPrint(
        '✅ SyncService: Sync completed. Remaining unsynced: $remainingCount',
      );
    } catch (e) {
      debugPrint('❌ SyncService: Error during sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync registrasi data
  Future<void> _syncRegistrasis() async {
    try {
      final unsyncedRegistrasis = await _database.getUnsyncedRegistrasis();

      if (unsyncedRegistrasis.isEmpty) return;

      debugPrint('📤 Syncing ${unsyncedRegistrasis.length} registrations...');

      for (final registrasi in unsyncedRegistrasis) {
        try {
          // POST to API
          final response = await _dio.post(
            '/registrasi',
            data: {
              'no_reg': registrasi.noReg,
              'no_urut': registrasi.noUrut,
              'pasien_id': registrasi.pasienId,
              'tgl_jam_reg': registrasi.tglJamReg,
              'kode_poli': registrasi.kodePoli,
              'dokter_id': registrasi.dokterId,
              'jenis_kunjungan': registrasi.jenisKunjungan,
              'asal_pasien': registrasi.asalPasien,
              'tipe_pasien': registrasi.tipePasien,
              'pasien_baru': registrasi.pasienBaru,
              'pagi_sore': registrasi.pagiSore,
              'is_cash': registrasi.isCash,
              'is_pribadi': registrasi.isPribadi,
              'eselon': registrasi.eselon,
              'status': registrasi.status,
              'penanggung_id': registrasi.penanggungId,
              'penanggung_nama': registrasi.penanggungNama,
              'penanggung_no_pegawai': registrasi.penanggungNoPegawai,
              'penanggung_alamat': registrasi.penanggungAlamat,
              'penanggung_telepon': registrasi.penanggungTelepon,
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final serverId = response.data['data']['id'] as int;

            // Mark as synced
            await _database.markRegistrasiSynced(registrasi.id, serverId);

            debugPrint('✅ Registrasi ${registrasi.noReg} synced successfully');
          }
        } catch (e) {
          debugPrint('❌ Error syncing registrasi ${registrasi.noReg}: $e');
          // Continue to next item even if one fails
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _syncRegistrasis: $e');
    }
  }

  /// Sync anamnesa data
  Future<void> _syncAnamnesas() async {
    try {
      final unsyncedAnamnesas = await _database.getUnsyncedAnamnesas();

      if (unsyncedAnamnesas.isEmpty) return;

      debugPrint('📤 Syncing ${unsyncedAnamnesas.length} anamnesas...');

      for (final anamnesa in unsyncedAnamnesas) {
        try {
          // Get synced registrasi ID from server
          final registrasi = await _database.getRegistrasiById(
            anamnesa.registrasiId,
          );

          if (registrasi == null || !registrasi.isSynced) {
            debugPrint('⏭️ Skipping anamnesa - registrasi not synced yet');
            continue;
          }

          // POST to API
          final response = await _dio.post(
            '/anamnesa/store',
            data: {
              'registrasi_id': registrasi.serverId, // Use server ID
              'dokter_id': anamnesa.dokterId,
              'poli_id': anamnesa.poliId,
              'tanggal': anamnesa.tanggal,
              'pengkajian_keperawatan': anamnesa.pengkajianKeperawatan,
              'pengkajian_medis': anamnesa.pengkajianMedis,
              'khusus_perawat': anamnesa.khususPerawat,
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final serverId = response.data['data']['id'] as int;

            // Mark as synced
            await _database.markAnamnesaSynced(anamnesa.id, serverId);

            debugPrint('✅ Anamnesa for registrasi ${registrasi.noReg} synced');
          }
        } catch (e) {
          debugPrint('❌ Error syncing anamnesa: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _syncAnamnesas: $e');
    }
  }

  /// Sync registrasi ICD data
  Future<void> _syncRegistrasiIcds() async {
    try {
      final unsyncedIcds = await _database.getUnsyncedRegistrasiIcds();

      if (unsyncedIcds.isEmpty) return;

      debugPrint('📤 Syncing ${unsyncedIcds.length} registrasi ICDs...');

      for (final registrasiIcd in unsyncedIcds) {
        try {
          // Get synced registrasi ID from server
          final registrasi = await _database.getRegistrasiById(
            registrasiIcd.registrasiId,
          );

          if (registrasi == null || !registrasi.isSynced) {
            debugPrint('⏭️ Skipping ICD - registrasi not synced yet');
            continue;
          }

          // POST to API
          final response = await _dio.post(
            '/registrasi/${registrasi.serverId}/icd/attach',
            data: {'icd_id': registrasiIcd.icdId},
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final serverId = response.data['data']['id'] as int;

            // Mark as synced
            await _database.markRegistrasiIcdSynced(registrasiIcd.id, serverId);

            debugPrint('✅ ICD for registrasi ${registrasi.noReg} synced');
          }
        } catch (e) {
          debugPrint('❌ Error syncing registrasi ICD: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _syncRegistrasiIcds: $e');
    }
  }

  /// Sync registrasi tindakan data
  Future<void> _syncRegistrasiTindakans() async {
    try {
      final unsyncedTindakans = await _database
          .getUnsyncedRegistrasiTindakans();

      if (unsyncedTindakans.isEmpty) return;

      debugPrint(
        '📤 Syncing ${unsyncedTindakans.length} registrasi tindakans...',
      );

      for (final registrasiTindakan in unsyncedTindakans) {
        try {
          // Get synced registrasi ID from server
          final registrasi = await _database.getRegistrasiById(
            registrasiTindakan.registrasiId,
          );

          if (registrasi == null || !registrasi.isSynced) {
            debugPrint('⏭️ Skipping tindakan - registrasi not synced yet');
            continue;
          }

          // POST to API
          final response = await _dio.post(
            '/registrasi/${registrasi.serverId}/tindakan/attach',
            data: {
              'tindakan_id': registrasiTindakan.tindakanId,
              'jumlah': registrasiTindakan.jumlah,
              'harga_satuan': registrasiTindakan.hargaSatuan,
              'diskon': registrasiTindakan.diskon,
              'subtotal': registrasiTindakan.subtotal,
              'petugas_nama': registrasiTindakan.petugasNama,
              'keterangan': registrasiTindakan.keterangan,
              'kunjungan_ke': registrasiTindakan.kunjunganKe,
              'is_free': registrasiTindakan.isFree,
              'dokter_id': registrasiTindakan.dokterId,
              'poli_id': registrasiTindakan.poliId,
              'tanggal_layanan': registrasiTindakan.tanggalLayanan,
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final serverId = response.data['data']['id'] as int;

            // Mark as synced
            await _database.markRegistrasiTindakanSynced(
              registrasiTindakan.id,
              serverId,
            );

            debugPrint('✅ Tindakan for registrasi ${registrasi.noReg} synced');
          }
        } catch (e) {
          debugPrint('❌ Error syncing registrasi tindakan: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _syncRegistrasiTindakans: $e');
    }
  }

  /// Get current sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final unsyncedCount = await _database.getUnsyncedCount();
    final connectivityResult = await _connectivity.checkConnectivity();
    final hasConnection = connectivityResult.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );

    return {
      'unsynced_count': unsyncedCount,
      'is_online': hasConnection,
      'is_syncing': _isSyncing,
    };
  }
}
