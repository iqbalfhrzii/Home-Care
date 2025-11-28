import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:homecare_mobile/features/schedules/domain/models/registrasi.dart';
import 'package:homecare_mobile/features/patients/domain/models/pasien.dart';

class RegistrasiDataSource {
  final Dio _dio;

  RegistrasiDataSource(this._dio);

  // Get all registrations
  Future<RegistrasiCollection> getAllRegistrasi() async {
    try {
      // Get all data without pagination limit dengan timeout
      final response = await _dio.get(
        '/registrasi',
        queryParameters: {
          'per_page': 1000, // Get all records at once
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 10), // Timeout 10 detik
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      debugPrint('✅ GET /registrasi - Status: ${response.statusCode}');

      if (response.data == null) {
        throw Exception('Response data is null');
      }

      // Handle pagination response
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;

        // Check if it's a paginated response with 'data' field
        if (data.containsKey('data') && data['data'] is List) {
          final dataArray = data['data'] as List;
          debugPrint('📥 Received ${dataArray.length} registrations');

          return RegistrasiCollection.fromJson({'data': dataArray});
        }
      }

      // Direct list response
      if (response.data is List) {
        final dataArray = response.data as List;
        debugPrint(
          '📥 Received ${dataArray.length} registrations (direct array)',
        );
        return RegistrasiCollection.fromJson({'data': dataArray});
      }

      // Default - try to parse as is
      return RegistrasiCollection.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ DioError GET /registrasi:');
      debugPrint('   Type: ${e.type}');
      debugPrint('   Message: ${e.message}');
      debugPrint('   Status: ${e.response?.statusCode}');
      rethrow;
    } on FormatException catch (e) {
      debugPrint('❌ FormatException parsing response:');
      debugPrint('   Message: ${e.message}');
      debugPrint('   Offset: ${e.offset}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ Error GET /registrasi: $e');
      debugPrint('   Type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Get registration by ID
  Future<Registrasi> getRegistrasiById(int id) async {
    try {
      final response = await _dio.get('/registrasi/$id');
      return Registrasi.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  // Create registration
  Future<Registrasi> createRegistrasi(Map<String, dynamic> data) async {
    try {
      debugPrint('📤 POST /registrasi');
      debugPrint('📦 Data: $data');

      final response = await _dio.post('/registrasi', data: data);

      debugPrint('✅ POST /registrasi - Status: ${response.statusCode}');
      debugPrint('📥 Response: ${response.data}');

      return Registrasi.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      debugPrint('❌ DioError POST /registrasi:');
      debugPrint('   Type: ${e.type}');
      debugPrint('   Message: ${e.message}');
      debugPrint('   Response: ${e.response?.data}');
      debugPrint('   Status: ${e.response?.statusCode}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ Error POST /registrasi: $e');
      debugPrint('   StackTrace: $stackTrace');
      rethrow;
    }
  }

  // Update registration
  Future<Registrasi> updateRegistrasi(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/registrasi/$id', data: data);
      return Registrasi.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  // Delete registration
  Future<void> deleteRegistrasi(int id) async {
    try {
      await _dio.delete('/registrasi/$id');
    } catch (e) {
      rethrow;
    }
  }

  // Search registrations
  Future<RegistrasiCollection> searchRegistrasi(String query) async {
    try {
      final response = await _dio.get(
        '/registrasi',
        queryParameters: {'search': query},
      );
      return RegistrasiCollection.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Get registrations by patient ID
  Future<RegistrasiCollection> getRegistrasiByPasienId(int pasienId) async {
    try {
      final response = await _dio.get(
        '/registrasi',
        queryParameters: {'pasien_id': pasienId},
      );
      return RegistrasiCollection.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Get registrations by date
  Future<RegistrasiCollection> getRegistrasiByDate(String date) async {
    try {
      final response = await _dio.get(
        '/registrasi',
        queryParameters: {'date': date},
      );
      return RegistrasiCollection.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
