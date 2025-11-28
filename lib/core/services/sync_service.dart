import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:homecare_mobile/shared/local_db/app_database.dart';
import 'package:flutter/foundation.dart';
import 'package:homecare_mobile/core/storage/secure_storage.dart';
import 'package:homecare_mobile/features/auth/data/datasources/auth_localdatasource.dart';

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

      // Ensure authenticated before hitting API
      final token = await secureStorage.read(key: kAccessTokenKey);
      if (token == null || token.isEmpty) {
        debugPrint('🔒 SyncService: No auth token present, skipping sync');
        return;
      }

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
              'tgl_jam_kunjungan': registrasi.tglJamReg,
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
        } on DioException catch (e) {
          debugPrint(
            '❌ Error syncing registrasi ${registrasi.noReg}: ${e.type}',
          );
          final status = e.response?.statusCode;
          final data = e.response?.data;
          debugPrint('   Status: $status');
          debugPrint('   Response: $data');

          // Attempt to resolve validation conflicts (e.g., duplicate no_reg)
          if (status == 422) {
            try {
              final errors = (data is Map<String, dynamic>)
                  ? data['errors']
                  : null;
              final noRegErrors = (errors is Map<String, dynamic>)
                  ? errors['no_reg']
                  : null;
              final hasNoRegTaken =
                  noRegErrors is List &&
                  noRegErrors.any(
                    (msg) => msg.toString().contains('already been taken'),
                  );

              if (hasNoRegTaken) {
                debugPrint(
                  '🔎 Duplicate no_reg detected, searching existing on server...',
                );
                final searchResp = await _dio.get(
                  '/registrasi',
                  queryParameters: {'search': registrasi.noReg},
                );
                final list =
                    (searchResp.data is Map && searchResp.data['data'] is List)
                    ? (searchResp.data['data'] as List)
                    : (searchResp.data is List)
                    ? (searchResp.data as List)
                    : <dynamic>[];
                if (list.isNotEmpty) {
                  final serverId =
                      (list.first as Map<String, dynamic>)['id'] as int;
                  await _database.markRegistrasiSynced(registrasi.id, serverId);
                  debugPrint(
                    '✅ Linked local ${registrasi.noReg} to server ID $serverId',
                  );
                  continue; // proceed to next item
                }
              }
            } catch (resolveErr) {
              debugPrint('⚠️ Failed resolving duplicate no_reg: $resolveErr');
            }
          }

          // Continue to next item even if one fails
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

          // Decode stored JSON strings
          Map<String, dynamic> kep = {};
          Map<String, dynamic> med = {};
          Map<String, dynamic> khs = {};
          try {
            kep =
                anamnesa.pengkajianKeperawatan != null &&
                    anamnesa.pengkajianKeperawatan!.isNotEmpty
                ? (jsonDecode(anamnesa.pengkajianKeperawatan!)
                      as Map<String, dynamic>)
                : {};
          } catch (_) {}
          try {
            med =
                anamnesa.pengkajianMedis != null &&
                    anamnesa.pengkajianMedis!.isNotEmpty
                ? (jsonDecode(anamnesa.pengkajianMedis!)
                      as Map<String, dynamic>)
                : {};
          } catch (_) {}
          try {
            khs =
                anamnesa.khususPerawat != null &&
                    anamnesa.khususPerawat!.isNotEmpty
                ? (jsonDecode(anamnesa.khususPerawat!) as Map<String, dynamic>)
                : {};
          } catch (_) {}

          // Extract sub-sections from stored keperawatan JSON
          final tv = (kep['tanda_vital'] is Map)
              ? (kep['tanda_vital'] as Map<String, dynamic>)
              : <String, dynamic>{};
          final nutr = (kep['nutrisi'] is Map)
              ? (kep['nutrisi'] as Map<String, dynamic>)
              : <String, dynamic>{};
          final fungs = (kep['fungsional'] is Map)
              ? (kep['fungsional'] as Map<String, dynamic>)
              : <String, dynamic>{};
          final kel = (kep['keluhan'] is Map)
              ? (kep['keluhan'] as Map<String, dynamic>)
              : <String, dynamic>{};
          final masalah = (kep['masalah_keperawatan'] is Map)
              ? (kep['masalah_keperawatan'] as Map<String, dynamic>)
              : <String, dynamic>{};

          // Extract khusus-perawat data
          final intervensiList = (khs['intervensi_time_up_go'] is List)
              ? (khs['intervensi_time_up_go'] as List)
              : const [];
          final skrStrong = (khs['skrining_nutrisi_strongkids'] is Map)
              ? (khs['skrining_nutrisi_strongkids'] as Map)
              : const {};
          final edukasiList = (khs['edukasi_pasien'] is List)
              ? (khs['edukasi_pasien'] as List)
              : const [];

          final payload = <String, dynamic>{
            'registrasi_id': registrasi.serverId,
            'dokter_id': anamnesa.dokterId,
            'poli_id': anamnesa.poliId,
            'tanggal':
                (anamnesa.tanggal != null && anamnesa.tanggal!.length >= 10)
                ? anamnesa.tanggal!.substring(0, 10)
                : DateTime.now().toIso8601String().substring(0, 10),

            // Flat fields from stored nested maps
            'keluhan': kel['keluhan'],
            'riwayat': fungs['riwayat'],
            'riwayat_alergi': tv['riwayat_alergi'] == true,
            'pemeriksaan_fisik': med['pemeriksaan_fisik'],
            'pemeriksaan_penunjang': med['pemeriksaan_penunjang'],
            'diagnosis': med['diagnosis'],
            'rencana_dan_terapi': med['rencana_terapi'],
            'kontrol': med['kontrol'],
            'edukasi': (edukasiList).isNotEmpty,
            'edukasi_ket': '',

            'tekanan_darah': tv['tekanan_darah'],
            'nadi': tv['nadi']?.toString(),
            'suhu': (tv['suhu'] is num)
                ? (tv['suhu'] as num).toDouble()
                : double.tryParse(tv['suhu']?.toString() ?? ''),
            'pernapasan': tv['pernapasan']?.toString(),
            'berat_badan': (nutr['berat_badan'] is num)
                ? (nutr['berat_badan'] as num).toDouble()
                : double.tryParse(nutr['berat_badan']?.toString() ?? ''),
            'tinggi_badan': (nutr['tinggi_badan'] is num)
                ? (nutr['tinggi_badan'] as num).toDouble()
                : double.tryParse(nutr['tinggi_badan']?.toString() ?? ''),
            'imt': (nutr['imt'] is num)
                ? (nutr['imt'] as num).toDouble()
                : double.tryParse(nutr['imt']?.toString() ?? ''),
            'lingkar_kepala': (nutr['lingkar_kepala'] is num)
                ? (nutr['lingkar_kepala'] as num).toDouble()
                : double.tryParse(nutr['lingkar_kepala']?.toString() ?? ''),
            'adl': fungs['adl'] == true,
            'resiko_jatuh': fungs['resiko_jatuh'] == true,
            'alat_bantu': fungs['alat_bantu'],
            'cacat_tubuh': fungs['cacat_tubuh'],
            'prothesa': fungs['prothesa'],

            // Masalah keperawatan flags from stored map
            'jalan_nafas': masalah['jalan_nafas'] == true,
            'pola_nafas': masalah['pola_nafas'] == true,
            'hipertermia': masalah['hipertermia'] == true,
            'nyeri_kronik': masalah['nyeri_kronik'] == true,
            'nyeri_akut': masalah['nyeri_akut'] == true,
            'mual': masalah['mual'] == true,
            'gangguan_perfusi': masalah['gangguan_perfusi'] == true,
            'gangguan_cairan': masalah['gangguan_cairan'] == true,
            'lainnya': masalah['lainnya'],

            // Intervensi time up & go
            'cara_berjalan': intervensiList.contains(
              'Tidak seimbang/sempoyongan/limbung',
            ),
            'cara_berjalan2': intervensiList.contains(
              'Jalan dengan menggunakan alat bantu (huk, tripot, kursi, orang bantu/pendamping)',
            ),
            'menopang': intervensiList.contains(
              'Mengangkat saat akan duduk, tampak menopang/pegang kursi atau meja/benda lain sebagai penyangga saat akan duduk',
            ),

            // STRONGkids (booleans derived from stored answers)
            'strong_kids1': (skrStrong['penyakit_malnutrisi'] ?? '')
                .toString()
                .startsWith('Ya'),
            'strong_kids2': (skrStrong['tampak_kurus'] ?? '')
                .toString()
                .startsWith('Ya'),
            'strong_kids3': (skrStrong['tindakan_khusus'] ?? '')
                .toString()
                .startsWith('Ya'),
            'strong_kids4': (skrStrong['nyeri'] ?? '').toString().startsWith(
              'Ya',
            ),

            // Rencana pulang
            'renc_usia_lanjut': khs['renc_usia_lanjut'] == true,
            'renc_hmbtn_mobil': khs['renc_hmbtn_mobil'] == true,
            'renc_layanan_medis': khs['renc_layanan_medis'] == true,
            'renc_tergnt_org': khs['renc_tergnt_org'] == true,

            // Risiko summary: compute on the fly is not available here; leave null or empty
            'risiko': null,
            // jenis_perawatan if present in medis
            'jenis_perawatan': med['jenis_perawatan'],
          };
          debugPrint('📤 SyncService: Upserting /anamnesa payload built');

          // Avoid duplicates: check if server already has anamnesa for this registrasi
          int? targetId;
          try {
            final check = await _dio.get(
              '/anamnesa',
              queryParameters: {'registrasi_id': registrasi.serverId},
            );
            final list = check.data is Map && check.data['data'] is List
                ? (check.data['data'] as List)
                : (check.data is List ? (check.data as List) : <dynamic>[]);
            if (list.isNotEmpty && list.first is Map) {
              targetId = (list.first as Map<String, dynamic>)['id'] as int?;
            }
          } catch (e) {
            debugPrint('ℹ️ SyncService: Unable to check existing anamnesa: $e');
          }

          final response = targetId != null
              ? await _dio.put('/anamnesa/$targetId', data: payload)
              : await _dio.post('/anamnesa', data: payload);

          if (response.statusCode == 200 || response.statusCode == 201) {
            final body = response.data;
            int serverId;
            if (body is Map &&
                body['data'] is Map &&
                (body['data']['id'] is int)) {
              serverId = body['data']['id'] as int;
            } else if (body is Map && body['id'] is int) {
              serverId = body['id'] as int;
            } else {
              // Fallback to existing id when PUT
              serverId = targetId ?? -1;
            }

            // Mark as synced
            await _database.markAnamnesaSynced(anamnesa.id, serverId);

            debugPrint('✅ Anamnesa for registrasi ${registrasi.noReg} synced');
          }
        } on DioException catch (e) {
          debugPrint('❌ Error syncing anamnesa: ${e.type}');
          debugPrint('   Status: ${e.response?.statusCode}');
          debugPrint('   Response: ${e.response?.data}');
          // Continue to next item
        } catch (e) {
          debugPrint('❌ Error syncing anamnesa (unexpected): $e');
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
