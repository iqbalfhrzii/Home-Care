import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:homecare_mobile/features/schedules/domain/models/registrasi.dart';
// Removed unused pasien import

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

      final parsed = _parseResponseData(response.data);
      if (parsed is List) {
        debugPrint('📥 Received ${parsed.length} registrations');
        return RegistrasiCollection.fromJson({'data': parsed});
      }

      // As a last resort, try constructing from the original structure
      return RegistrasiCollection.fromJson(
        parsed is Map<String, dynamic> ? parsed : {'data': []},
      );
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
      debugPrint('   Stack: $stackTrace');
      rethrow;
    }
  }

  // Get registration by ID
  Future<Registrasi> getRegistrasiById(int id) async {
    try {
      final response = await _dio.get('/registrasi/$id');
      final parsed = _parseResponseData(response.data);
      if (parsed is Map<String, dynamic>) {
        return Registrasi.fromJson(parsed);
      }
      if (parsed is List && parsed.isNotEmpty && parsed.first is Map) {
        return Registrasi.fromJson(parsed.first as Map<String, dynamic>);
      }
      throw const FormatException('Unexpected response shape for registrasi');
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

      final parsed = _parseResponseData(response.data);
      if (parsed is Map<String, dynamic>) {
        return Registrasi.fromJson(parsed);
      }
      if (parsed is List && parsed.isNotEmpty && parsed.first is Map) {
        return Registrasi.fromJson(parsed.first as Map<String, dynamic>);
      }
      throw const FormatException('Unexpected response shape after create');
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
      final parsed = _parseResponseData(response.data);
      if (parsed is Map<String, dynamic>) {
        return Registrasi.fromJson(parsed);
      }
      throw const FormatException('Unexpected response shape after update');
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
      final parsed = _parseResponseData(response.data);
      if (parsed is List) {
        return RegistrasiCollection.fromJson({'data': parsed});
      }
      return RegistrasiCollection.fromJson(
        parsed is Map<String, dynamic> ? parsed : {'data': []},
      );
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
      final parsed = _parseResponseData(response.data);
      if (parsed is List) {
        return RegistrasiCollection.fromJson({'data': parsed});
      }
      return RegistrasiCollection.fromJson(
        parsed is Map<String, dynamic> ? parsed : {'data': []},
      );
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
      final parsed = _parseResponseData(response.data);
      if (parsed is List) {
        return RegistrasiCollection.fromJson({'data': parsed});
      }
      return RegistrasiCollection.fromJson(
        parsed is Map<String, dynamic> ? parsed : {'data': []},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Normalize various API response shapes to either List or Map
  dynamic _parseResponseData(dynamic raw) {
    if (raw == null) return {'data': []};

    // If server returned a JSON string
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        // Not JSON, return empty
        return {'data': []};
      }
    }

    // Direct list
    if (raw is List) return raw;

    if (raw is Map) {
      // Common: { data: [...] }
      final dataField = raw['data'];
      if (dataField is List) return dataField;

      // Sometimes: { data: { data: [...] } }
      if (dataField is Map && dataField['data'] is List) {
        return dataField['data'];
      }

      // Other shapes like { items: [...] } or { rows: [...] }
      if (raw['items'] is List) return raw['items'];
      if (raw['rows'] is List) return raw['rows'];

      // If it's a single object
      return raw;
    }

    return {'data': []};
  }
}
