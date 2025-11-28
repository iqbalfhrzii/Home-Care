import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:homecare_mobile/features/schedules/domain/models/poli.dart';

class PoliDataSource {
  final Dio _dio;

  PoliDataSource(this._dio);

  // Get all poli
  Future<PoliCollection> getAllPoli() async {
    try {
      debugPrint('🚀 GET /poli');
      final response = await _dio.get('/poli');
      debugPrint('📦 Response status: ${response.statusCode}');
      debugPrint('📦 Response data type: ${response.data.runtimeType}');
      debugPrint('📦 Response data: ${response.data}');
      return PoliCollection.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getAllPoli: $e');
      debugPrint('📍 Stack: $stackTrace');
      rethrow;
    }
  }

  // Get poli by kode
  Future<Poli> getPoliByKode(String kode) async {
    try {
      debugPrint('🚀 GET /poli/$kode');
      final response = await _dio.get('/poli/$kode');
      debugPrint('📦 Response: ${response.data}');
      return Poli.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getPoliByKode: $e');
      debugPrint('📍 Stack: $stackTrace');
      rethrow;
    }
  }

  // Get active poli
  Future<PoliCollection> getActivePoli() async {
    try {
      debugPrint('🚀 GET /poli?status=aktif');
      final response = await _dio.get(
        '/poli',
        queryParameters: {'status': 'aktif'},
      );
      debugPrint('📦 Response status: ${response.statusCode}');
      debugPrint('📦 Response data type: ${response.data.runtimeType}');
      debugPrint('📦 Response data: ${response.data}');
      return PoliCollection.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      debugPrint('❌ Error in getActivePoli: $e');
      debugPrint('📍 Stack: $stackTrace');
      rethrow;
    }
  }
}
