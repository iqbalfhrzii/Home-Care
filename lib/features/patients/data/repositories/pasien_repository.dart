import 'package:homecare_mobile/features/patients/domain/models/pasien.dart';
import 'package:flutter/foundation.dart';
import 'package:homecare_mobile/core/network/dio.dart';
import 'package:dio/dio.dart' as dio_pkg;

class PasienRepository {
  // Cache untuk menyimpan data pasien dari API
  List<Pasien>? _cachedPatients;

  PasienRepository();

  Future<List<Pasien>> getAllPasien({int perPage = 1000}) async {
    // Ambil dari API Laravel: GET /pasien (paginated)
    try {
      if (_cachedPatients != null) return _cachedPatients!;

      // First request to get meta
      final first = await dio.get(
        '/pasien',
        queryParameters: {'per_page': perPage, 'page': 1},
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 25),
          sendTimeout: const Duration(seconds: 20),
          receiveDataWhenStatusError: true,
          validateStatus: (_) => true,
        ),
      );
      if (first.statusCode != null && first.statusCode! >= 400) {
        debugPrint('❌ Patients API error (page=1): status=${first.statusCode}, data=${first.data}');
        return _cachedPatients ?? [];
      }

      List<Pasien> all = [];
      Map meta = {};
      List<dynamic> items = [];
      if (first.data is Map) {
        final m = first.data as Map;
        meta = Map<String, dynamic>.from(m['meta'] ?? {});
        items = (m['data'] is List) ? (m['data'] as List) : const [];
      } else if (first.data is List) {
        items = first.data as List;
      }
      all.addAll(items.map((e) => Pasien.fromJson(Map<String, dynamic>.from(e))));

      final lastPage = (meta['last_page'] is int)
          ? meta['last_page'] as int
          : int.tryParse('${meta['last_page'] ?? 1}') ?? 1;

      // Fetch remaining pages if any
      for (int page = 2; page <= lastPage; page++) {
        try {
          final resp = await dio.get(
            '/pasien',
            queryParameters: {'per_page': perPage, 'page': page},
            options: dio_pkg.Options(
              receiveTimeout: const Duration(seconds: 25),
              sendTimeout: const Duration(seconds: 20),
              receiveDataWhenStatusError: true,
              validateStatus: (_) => true,
            ),
          );
          if (resp.statusCode != null && resp.statusCode! >= 400) {
            debugPrint('❌ Patients API error (page=$page): status=${resp.statusCode}, data=${resp.data}');
            break;
          }
          List<dynamic> pageItems = [];
          if (resp.data is Map && (resp.data as Map)['data'] is List) {
            pageItems = (resp.data as Map)['data'] as List;
          } else if (resp.data is List) {
            pageItems = resp.data as List;
          }
          all.addAll(pageItems.map((e) => Pasien.fromJson(Map<String, dynamic>.from(e))));
        } on dio_pkg.DioException catch (e) {
          debugPrint('❌ DioException fetching patients (page=$page): type=${e.type}, message=${e.message}, response=${e.response?.data}');
          break;
        }
      }

      _cachedPatients = all;
      return all;
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ DioException fetching patients: type=${e.type}, message=${e.message}, response=${e.response?.data}');
      return _cachedPatients ?? [];
    } catch (e) {
      debugPrint('❌ Error fetching patients: $e');
      return _cachedPatients ?? [];
    }
  }

  Future<Pasien> createPasien(Pasien pasien) async {
    try {
      final resp = await dio.post(
        '/pasien',
        data: pasien.toJson(),
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint('❌ Create pasien error: status=${resp.statusCode}, data=${resp.data}');
        throw Exception('Gagal membuat pasien');
      }
      final created = Pasien.fromJson(Map<String, dynamic>.from(
        resp.data is Map && (resp.data as Map).containsKey('data') ? resp.data['data'] : resp.data,
      ));
      clearCache();
      return created;
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ DioException create pasien: type=${e.type}, message=${e.message}, response=${e.response?.data}');
      rethrow;
    }
  }

  Future<void> updatePasien(Pasien pasien) async {
    try {
      final id = pasien.id;
      final resp = await dio.put(
        '/pasien/$id',
        data: pasien.toJson(),
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint('❌ Update pasien error: status=${resp.statusCode}, data=${resp.data}');
        throw Exception('Gagal mengupdate pasien');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ DioException update pasien: type=${e.type}, message=${e.message}, response=${e.response?.data}');
      rethrow;
    }
  }

  Future<void> deletePasien(int id) async {
    try {
      final resp = await dio.delete(
        '/pasien/$id',
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint('❌ Delete pasien error: status=${resp.statusCode}, data=${resp.data}');
        throw Exception('Gagal menghapus pasien');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ DioException delete pasien: type=${e.type}, message=${e.message}, response=${e.response?.data}');
      rethrow;
    }
  }

  // Clear cache manually
  void clearCache() {
    _cachedPatients = null;
  }
}
