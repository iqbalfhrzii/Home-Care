import 'package:dio/dio.dart';
import 'package:homecare_mobile/features/patients/domain/models/pasien.dart';

class PasienDataSource {
  final Dio _dio;

  PasienDataSource(this._dio);

  // Get all patients
  Future<PasienCollection> getAllPasien() async {
    try {
      final response = await _dio.get('/pasien');
      return PasienCollection.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Get patient by ID
  Future<Pasien> getPasienById(String id) async {
    try {
      final response = await _dio.get('/pasien/$id');
      return Pasien.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  // Create patient
  Future<Pasien> createPasien(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/pasien', data: data);
      return Pasien.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  // Update patient
  Future<Pasien> updatePasien(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/pasien/$id', data: data);
      return Pasien.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  // Delete patient
  Future<void> deletePasien(String id) async {
    try {
      await _dio
          .delete('/pasien/$id')
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Delete request timeout');
            },
          );
    } catch (e) {
      print('❌ Delete API Error: $e');
      rethrow;
    }
  }

  // Search patients
  Future<PasienCollection> searchPasien(String query) async {
    try {
      final response = await _dio.get(
        '/pasien',
        queryParameters: {'search': query},
      );
      return PasienCollection.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
