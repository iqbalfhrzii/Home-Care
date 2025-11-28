import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:homecare_mobile/features/schedules/domain/models/dokter.dart';

class DokterDataSource {
  final Dio _dio;

  DokterDataSource(this._dio);

  // Get all dokter
  Future<DokterCollection> getAllDokter() async {
    try {
      debugPrint('🚀 GET /dokter');
      final response = await _dio.get('/dokter');
      debugPrint('📦 Response status: ${response.statusCode}');
      debugPrint('📦 Response data type: ${response.data.runtimeType}');
      debugPrint('📦 Response data: ${response.data}');
      return DokterCollection.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getAllDokter: $e');
      debugPrint('📍 Stack: $stackTrace');
      rethrow;
    }
  }

  // Get dokter by ID
  Future<Dokter> getDokterById(String id) async {
    try {
      debugPrint('🚀 GET /dokter/$id');
      final response = await _dio.get('/dokter/$id');
      debugPrint('📦 Response: ${response.data}');
      return Dokter.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getDokterById: $e');
      debugPrint('📍 Stack: $stackTrace');
      rethrow;
    }
  }

  // Get active dokter
  Future<DokterCollection> getActiveDokter() async {
    try {
      debugPrint('🚀 GET /dokter?status=aktif');
      final response = await _dio.get(
        '/dokter',
        queryParameters: {'status': 'aktif'},
      );
      debugPrint('📦 Response status: ${response.statusCode}');
      debugPrint('📦 Response data type: ${response.data.runtimeType}');
      debugPrint('📦 Response data: ${response.data}');
      return DokterCollection.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getActiveDokter: $e');
      debugPrint('📍 Stack: $stackTrace');
      rethrow;
    }
  }
}
