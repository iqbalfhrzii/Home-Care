import 'package:homecare_mobile/features/schedules/domain/models/anamnesa.dart';
import 'package:flutter/foundation.dart';
import 'package:homecare_mobile/core/network/dio.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';

class AnamnesaRepository {
  AnamnesaRepository();

  void _clearRegistrasiCache() {
    try {
      getIt<RegistrasiRepository>().clearCache();
      debugPrint('🗑️ Registrasi cache cleared');
    } catch (e) {
      debugPrint('⚠️ Failed to clear registrasi cache: $e');
    }
  }

  Future<List<Anamnesa>> getAllAnamnesa() async {
    try {
      final resp = await dio.get(
        '/anamnesa',
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint('❌ Anamnesa list error: status=${resp.statusCode}, data=${resp.data}');
        return [];
      }
      final data = resp.data;
      final List<dynamic> items = (data is Map && data['data'] is List)
          ? (data['data'] as List)
          : (data is List ? data : const <dynamic>[]);
      return items.map((e) => Anamnesa.fromJson(Map<String, dynamic>.from(e))).toList();
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ DioException list anamnesa: type=${e.type}, message=${e.message}, response=${e.response?.data}');
      return [];
    }
  }

  Future<Anamnesa> getAnamnesaById(int id) async {
    try {
      final resp = await dio.get(
        '/anamnesa/$id',
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint('❌ Get anamnesa error: status=${resp.statusCode}, data=${resp.data}');
        throw Exception('Gagal memuat anamnesa');
      }
      final data = resp.data is Map && (resp.data as Map).containsKey('data') ? resp.data['data'] : resp.data;
      return Anamnesa.fromJson(Map<String, dynamic>.from(data));
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ DioException get anamnesa: type=${e.type}, message=${e.message}, response=${e.response?.data}');
      rethrow;
    }
  }

  Future<Anamnesa> createAnamnesa(Anamnesa anamnesa) async {
    try {
      final resp = await dio.post(
        '/anamnesa',
        data: anamnesa.toJson(),
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint('❌ Create anamnesa error: status=${resp.statusCode}, data=${resp.data}');
        throw Exception('Gagal membuat anamnesa');
      }
      final data = resp.data is Map && (resp.data as Map).containsKey('data') ? resp.data['data'] : resp.data;
      _clearRegistrasiCache();
      return Anamnesa.fromJson(Map<String, dynamic>.from(data));
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ DioException create anamnesa: type=${e.type}, message=${e.message}, response=${e.response?.data}');
      rethrow;
    }
  }

  /// Alternate create using raw payload map following cURL spec
  Future<void> createAnamnesaWithPayload({
    required int registrasiId,
    required Map<String, dynamic> data,
  }) async {
    final body = {
      'registrasi_id': registrasiId,
      ...data,
    };
    try {
      debugPrint('[POST] /api/v1/anamnesa registrasi_id=$registrasiId');
      final resp = await dio.post(
        '/anamnesa',
        data: body,
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );
      debugPrint('[POST] /api/v1/anamnesa -> status=${resp.statusCode}');
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        throw Exception('Gagal membuat anamnesa');
      }
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ DioException create (payload) anamnesa: type=${e.type}, message=${e.message}, response=${e.response?.data}');
      rethrow;
    }
  }

  /// Upsert: if registrasi already has anamnesa, update it; otherwise create.
  Future<void> upsertAnamnesa({
    required int registrasiId,
    required Map<String, dynamic> data,
  }) async {
    debugPrint('🔵 [UPSERT] Starting upsert for registrasiId=$registrasiId');
    debugPrint('🔵 [UPSERT] Payload keys: ${data.keys.join(", ")}');
    
    final regRepo = getIt<RegistrasiRepository>();
    Map<String, dynamic>? raw;
    try {
      raw = await regRepo.getRegistrasiRawById(registrasiId);
      debugPrint('✅ [UPSERT] Got registrasi data');
    } catch (e) {
      debugPrint('⚠️ [UPSERT] Failed to get registrasi: $e');
      raw = null;
    }
    
    final existing = raw != null && raw['anamnesa'] is Map<String, dynamic>
      ? Map<String, dynamic>.from(raw['anamnesa'] as Map)
        : null;

    if (existing != null && (existing['id'] != null)) {
      final int anamnesaId = existing['id'] is String
          ? int.tryParse(existing['id']) ?? existing['id'] as int
          : existing['id'] as int;
      debugPrint('🔄 [UPSERT] Updating existing anamnesa id=$anamnesaId');
      
      try {
        final payload = {'registrasi_id': registrasiId, ...data}..removeWhere((k, v) => v == null);
        debugPrint('📤 [PUT] /api/v1/anamnesa/$anamnesaId');
        
        final resp = await dio.put(
          '/anamnesa/$anamnesaId',
          data: payload,
          options: dio_pkg.Options(
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            validateStatus: (_) => true,
            contentType: 'application/json',
          ),
        );
        
        debugPrint('📥 [PUT] Response status=${resp.statusCode}');
        
        if (resp.statusCode != null && resp.statusCode! >= 400) {
          debugPrint('❌ [PUT] Failed: ${resp.data}');
          throw Exception('Update failed with status ${resp.statusCode}');
        }
        
        debugPrint('✅ [UPSERT] Update successful');
        _clearRegistrasiCache();
        return;
      } catch (e) {
        debugPrint('❌ [PUT] Exception: $e');
        debugPrint('🔄 [UPSERT] Fallback to POST');
      }
    } else {
      debugPrint('➕ [UPSERT] Creating new anamnesa');
    }

    // Create new anamnesa
    try {
      final payload = {'registrasi_id': registrasiId, ...data}..removeWhere((k, v) => v == null);
      debugPrint('📤 [POST] /api/v1/anamnesa');
      debugPrint('📤 [POST] Payload size: ${payload.length} fields');
      
      final resp = await dio.post(
        '/anamnesa',
        data: payload,
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          validateStatus: (_) => true,
          contentType: 'application/json',
        ),
      );
      
      debugPrint('📥 [POST] Response status=${resp.statusCode}');
      
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint('❌ [POST] Failed: ${resp.data}');
        throw Exception('Create failed with status ${resp.statusCode}: ${resp.data}');
      }
      
      debugPrint('✅ [UPSERT] Create successful');
      _clearRegistrasiCache();
    } catch (e) {
      debugPrint('❌ [POST] Exception: $e');
      rethrow;
    }
  }

  Future<void> updateAnamnesa(Anamnesa anamnesa) async {
    try {
      final resp = await dio.put(
        '/anamnesa/${anamnesa.id}',
        data: anamnesa.toJson(),
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint('❌ Update anamnesa error: status=${resp.statusCode}, data=${resp.data}');
        throw Exception('Gagal mengupdate anamnesa');
      }
      _clearRegistrasiCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ DioException update anamnesa: type=${e.type}, message=${e.message}, response=${e.response?.data}');
      rethrow;
    }
  }

  Future<void> deleteAnamnesa(int id) async {
    try {
      final resp = await dio.delete(
        '/anamnesa/$id',
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint('❌ Delete anamnesa error: status=${resp.statusCode}, data=${resp.data}');
        throw Exception('Gagal menghapus anamnesa');
      }
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ DioException delete anamnesa: type=${e.type}, message=${e.message}, response=${e.response?.data}');
      rethrow;
    }
  }
}
