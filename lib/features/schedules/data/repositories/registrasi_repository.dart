import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:homecare_mobile/core/network/dio.dart';
import 'package:homecare_mobile/features/schedules/domain/models/registrasi.dart';

/// Repository untuk Registrasi
///
/// CACHING STRATEGY:
/// - getAllRegistrasi() : Uses cache (_cached) for list view performance
/// - getRegistrasiById() : ALWAYS bypasses cache, fetches from API with full relations (icds, tindakans)
///   This is CRITICAL for edit forms that need to load existing selections
///
/// Cache is cleared on: create, update, delete, attach, detach operations
class RegistrasiRepository {
  // Cache ONLY for list operations - NOT used for detail fetching
  List<Registrasi>? _cached;

  /// Ambil semua registrasi dari API Laravel (paginated)
  Future<List<Registrasi>> getAllRegistrasi({
    int perPage = 1000,
    String? status,
  }) async {
    // If cache exists, serve it to keep UI responsive
    if (_cached != null) return _cached!;

    // Try progressively smaller page sizes to avoid large-payload issues
    final candidates = <int>{
      perPage,
      200,
      100,
      50,
      25,
      15,
    }.where((p) => p > 0).toList();
    dio_pkg.Response? lastResp;
    dio_pkg.DioException? lastErr;
    for (final size in candidates) {
      try {
        final params = <String, dynamic>{'per_page': size};
        if (status != null && status.isNotEmpty) params['status'] = status;
        final resp = await dio.get(
          '/registrasi',
          queryParameters: params,
          options: dio_pkg.Options(
            receiveTimeout: const Duration(seconds: 25),
            sendTimeout: const Duration(seconds: 20),
            followRedirects: false,
            // Keep body on errors for diagnostics
            receiveDataWhenStatusError: true,
            // Treat non-2xx as responses so we can inspect
            validateStatus: (_) => true,
          ),
        );
        lastResp = resp;
        if (resp.statusCode != null && resp.statusCode! >= 400) {
          debugPrint(
            '❌ Registrasi API error (perPage=$size): status=${resp.statusCode}, data=${resp.data}',
          );
          // Try next smaller page size
          continue;
        }
        final data = resp.data;
        final List<dynamic> items = (data is Map && data['data'] is List)
            ? (data['data'] as List)
            : (data is List ? data : const <dynamic>[]);
        final regs = items
            .map((e) => Registrasi.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _cached = regs;
        return regs;
      } on dio_pkg.DioException catch (e) {
        lastErr = e;
        debugPrint(
          '❌ DioException fetching registrasi (perPage=$size): type=${e.type}, message=${e.message}, error=${e.error}, response=${e.response?.data}',
        );
        // Try next smaller page size
        continue;
      } catch (e) {
        debugPrint('❌ Error fetching registrasi (perPage=$size): $e');
        // Try next smaller page size
        continue;
      }
    }
    // If we reached here, all attempts failed
    if (lastResp != null) {
      debugPrint(
        '⚠️ Returning cached/empty registrasi after last response: status=${lastResp.statusCode}',
      );
    }
    if (lastErr != null) {
      debugPrint(
        '⚠️ Returning cached/empty registrasi after last DioException: type=${lastErr.type}, message=${lastErr.message}',
      );
    }
    return _cached ?? [];
  }

  /// Ambil registrasi pasien tertentu dari API (atau cache) lalu urutkan terbaru.
  Future<List<Registrasi>> getRegistrasiByPasienId(int pasienId) async {
    // Prefer ambil semua lalu filter untuk mengurangi ketergantungan query server
    final all = await getAllRegistrasi();
    final filtered = all.where((r) => r.safePasienId == pasienId).toList();
    filtered.sort((a, b) {
      final ad =
          a.parsedTglReg ??
          a.parsedTglKunjungan ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bd =
          b.parsedTglReg ??
          b.parsedTglKunjungan ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return filtered;
  }

  /// Ambil registrasi terbaru untuk pasien tertentu, jika ada.
  Future<Registrasi?> getLatestRegistrasiForPatient(int pasienId) async {
    final list = await getRegistrasiByPasienId(pasienId);
    if (list.isEmpty) return null;
    return list.first;
  }

  /// Fetch registrasi by ID from API - ALWAYS bypasses cache to get full details with relations
  /// This is critical for edit forms that need icds and tindakans relations
  Future<Registrasi?> getRegistrasiById(int id) async {
    debugPrint('\n🎯 [DETAIL] Fetching registrasi $id - BYPASSING CACHE');
    debugPrint('🌐 [API] GET /registrasi/$id');

    try {
      final resp = await dio.get(
        '/registrasi/$id',
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );

      debugPrint('✅ [API] Response status: ${resp.statusCode}');

      if (resp.statusCode == null || resp.statusCode! >= 400) {
        debugPrint('❌ Get registrasi by id failed: status=${resp.statusCode}');
        debugPrint('📦 Response data: ${resp.data}');
        return null; // NO FALLBACK to cache - we need fresh data with relations
      }

      final data = resp.data is Map && (resp.data as Map).containsKey('data')
          ? resp.data['data']
          : resp.data;

      final registrasi = Registrasi.fromJson(Map<String, dynamic>.from(data));

      debugPrint('✅ [DETAIL] Registrasi loaded successfully');
      debugPrint('   - ID: ${registrasi.id}');
      debugPrint('   - No. Reg: ${registrasi.noReg}');
      debugPrint(
        '   - Has ICDs: ${registrasi.icds != null} (${registrasi.icds?.length ?? 0} items)',
      );
      debugPrint(
        '   - Has Tindakans: ${registrasi.tindakans != null} (${registrasi.tindakans?.length ?? 0} items)',
      );

      return registrasi;
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException get registrasi by id: type=${e.type}, message=${e.message}',
      );
      debugPrint('📦 Response: ${e.response?.data}');
      return null; // NO FALLBACK - let the error surface
    } catch (e) {
      debugPrint('❌ Unexpected error getting registrasi by id: $e');
      return null;
    }
  }

  Future<Registrasi> createRegistrasi(Registrasi registrasi) async {
    try {
      final resp = await dio.post(
        '/registrasi',
        data: registrasi.toJson(),
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Create registrasi error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal membuat registrasi');
      }
      final created = Registrasi.fromJson(
        Map<String, dynamic>.from(
          resp.data is Map && (resp.data as Map).containsKey('data')
              ? resp.data['data']
              : resp.data,
        ),
      );
      clearCache();
      return created;
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException create registrasi: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  Future<Registrasi> createRegistrasiFromMap(Map<String, dynamic> data) async {
    try {
      final resp = await dio.post(
        '/registrasi',
        data: data,
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Create registrasi (map) error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal membuat registrasi');
      }
      final created = Registrasi.fromJson(
        Map<String, dynamic>.from(
          resp.data is Map && (resp.data as Map).containsKey('data')
              ? resp.data['data']
              : resp.data,
        ),
      );
      clearCache();
      return created;
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException create registrasi (map): type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  Future<void> updateRegistrasi(Registrasi registrasi) async {
    try {
      final id = registrasi.id;
      final resp = await dio.put(
        '/registrasi/$id',
        data: registrasi.toJson(),
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Update registrasi error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal mengupdate registrasi');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException update registrasi: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  Future<Registrasi> updateRegistrasiFromMap(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final resp = await dio.put(
        '/registrasi/$id',
        data: data,
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Update registrasi (map) error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal mengupdate registrasi');
      }
      final updated = Registrasi.fromJson(
        Map<String, dynamic>.from(
          resp.data is Map && (resp.data as Map).containsKey('data')
              ? resp.data['data']
              : resp.data,
        ),
      );
      clearCache();
      return updated;
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException update registrasi (map): type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  /// Attach multiple ICD to a registrasi
  Future<void> attachIcd({
    required int registrasiId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final resp = await dio.post(
        '/registrasi/$registrasiId/attach-icd',
        data: {'items': items},
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Attach ICD error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal menambahkan ICD');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException attach ICD: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  /// Attach multiple tindakan to a registrasi
  Future<void> attachTindakan({
    required int registrasiId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final resp = await dio.post(
        '/registrasi/$registrasiId/attach-tindakan',
        data: {'items': items},
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Attach tindakan error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal menambahkan tindakan');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException attach tindakan: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  /// Get existing tindakan for a registrasi
  Future<List<Map<String, dynamic>>> getExistingTindakan(
    int registrasiId,
  ) async {
    try {
      debugPrint(
        '📥 [REPO] Calling getRegistrasiById($registrasiId) for Tindakan...',
      );
      final registrasi = await getRegistrasiById(registrasiId);
      debugPrint(
        '📦 [REPO] Registrasi loaded: id=${registrasi?.id}, noReg=${registrasi?.noReg}',
      );
      debugPrint('📦 [REPO] Has tindakans? ${registrasi?.tindakans != null}');

      if (registrasi == null || registrasi.tindakans == null) {
        debugPrint('⚠️ No Tindakan data found');
        return [];
      }

      debugPrint('📋 Raw Tindakan data: ${registrasi.tindakans}');

      final result = registrasi.tindakans!.map((e) {
        if (e is Map<String, dynamic>) {
          // Check if it has pivot data (for many-to-many relations)
          final pivot = e['pivot'] as Map<String, dynamic>?;
          if (pivot != null) {
            // Has pivot: Merge tindakan data with pivot data
            return {
              'tindakan_id': e['id'],
              'kode': e['kode'],
              'nama_tindakan': e['deskripsi'],
              'kategori': e['kategori'] ?? 'Unknown',
              'jumlah': pivot['jumlah'] ?? 1,
              'harga_satuan': pivot['harga_satuan'] ?? e['tarif'],
              'diskon': pivot['diskon'] ?? 0,
              'petugas_nama': pivot['petugas_nama'],
              'keterangan': pivot['keterangan'],
              'kunjungan_ke': pivot['kunjungan_ke'],
              'is_free': pivot['is_free'] ?? false,
              'dokter_id': pivot['dokter_id'],
              'poli_id': pivot['poli_id'],
              'tanggal_layanan': pivot['tanggal_layanan'],
              ...e,
            };
          } else {
            // No pivot: Use tindakan data directly
            return {
              'tindakan_id': e['id'],
              'kode': e['kode'],
              'nama_tindakan': e['deskripsi'],
              'kategori': e['kategori'] ?? 'Unknown',
              'jumlah': e['jumlah'] ?? 1,
              'harga_satuan': e['harga_satuan'] ?? e['tarif'],
              'diskon': e['diskon'] ?? 0,
              'petugas_nama': e['petugas_nama'],
              'keterangan': e['keterangan'],
              ...e,
            };
          }
        }
        return <String, dynamic>{};
      }).toList();

      debugPrint('✅ Processed Tindakan data: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error getting existing tindakan: $e');
      return [];
    }
  }

  /// Get existing ICD for a registrasi
  Future<List<Map<String, dynamic>>> getExistingIcd(int registrasiId) async {
    try {
      debugPrint(
        '📥 [REPO] Calling getRegistrasiById($registrasiId) for ICD...',
      );
      final registrasi = await getRegistrasiById(registrasiId);
      debugPrint(
        '📦 [REPO] Registrasi loaded: id=${registrasi?.id}, noReg=${registrasi?.noReg}',
      );
      debugPrint('📦 [REPO] Has icds? ${registrasi?.icds != null}');

      if (registrasi == null || registrasi.icds == null) {
        debugPrint('⚠️ No ICD data found');
        return [];
      }

      debugPrint('📋 Raw ICD data: ${registrasi.icds}');

      final result = registrasi.icds!.map((e) {
        if (e is Map<String, dynamic>) {
          // Check if it has pivot data (for many-to-many relations)
          final pivot = e['pivot'] as Map<String, dynamic>?;
          if (pivot != null) {
            // Has pivot: Merge ICD data with pivot data
            return {
              'icd_id': e['id'],
              'kode': e['kode'],
              'deskripsi': e['deskripsi'],
              'is_primary': pivot['is_primary'] ?? false,
              'kasus': pivot['kasus'] ?? 'Sekunder',
              ...e,
            };
          } else {
            // No pivot: Use ICD data directly (assume it's already attached)
            return {
              'icd_id': e['id'],
              'kode': e['kode'],
              'deskripsi': e['deskripsi'],
              'is_primary': e['is_primary'] ?? false,
              'kasus': e['kasus'] ?? 'Sekunder',
              ...e,
            };
          }
        }
        return <String, dynamic>{};
      }).toList();

      debugPrint('✅ Processed ICD data: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error getting existing ICD: $e');
      return [];
    }
  }

  /// Reset helpers
  Future<void> deleteAnamnesaByRegistrasiId(int registrasiId) async {
    try {
      final resp = await dio.delete(
        '/anamnesa',
        queryParameters: {'registrasi_id': registrasiId},
        options: dio_pkg.Options(validateStatus: (_) => true),
      );
      if ((resp.statusCode ?? 500) >= 400) {
        debugPrint(
          '❌ Reset anamnesa error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal reset anamnesa');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException reset anamnesa: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  Future<void> detachAllTindakan(int registrasiId) async {
    try {
      final resp = await dio.post(
        '/registrasi/$registrasiId/detach-tindakan',
        options: dio_pkg.Options(validateStatus: (_) => true),
      );
      if ((resp.statusCode ?? 500) >= 400) {
        debugPrint(
          '❌ Detach tindakan error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal reset tindakan');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException detach tindakan: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  Future<void> detachAllIcd(int registrasiId) async {
    try {
      final resp = await dio.post(
        '/registrasi/$registrasiId/detach-icd',
        options: dio_pkg.Options(validateStatus: (_) => true),
      );
      if ((resp.statusCode ?? 500) >= 400) {
        debugPrint(
          '❌ Detach ICD error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal reset ICD');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException detach ICD: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  /// Get raw registrasi map by id to inspect related entities
  Future<Map<String, dynamic>?> getRegistrasiRawById(int id) async {
    try {
      final resp = await dio.get(
        '/registrasi/$id',
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Get raw registrasi error: status=${resp.statusCode}, data=${resp.data}',
        );
        return null;
      }
      final data = resp.data is Map && (resp.data as Map).containsKey('data')
          ? resp.data['data']
          : resp.data;
      return Map<String, dynamic>.from(data as Map);
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException get raw registrasi: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      return null;
    }
  }

  Future<void> deleteRegistrasi(int id) async {
    try {
      final resp = await dio.delete(
        '/registrasi/$id',
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Delete registrasi error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal menghapus registrasi');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException delete registrasi: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  void clearCache() {
    _cached = null;
  }
}
