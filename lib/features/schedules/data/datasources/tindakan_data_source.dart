import 'package:dio/dio.dart';
import 'package:homecare_mobile/features/schedules/domain/models/tindakan.dart';

class TindakanDataSource {
  final Dio _dio;

  TindakanDataSource(this._dio);

  // ==================== MASTER TINDAKAN ====================

  // GET /tindakan - Get all tindakan (master data)
  Future<TindakanCollection> getAllTindakan() async {
    try {
      final response = await _dio.get('/tindakan');
      return TindakanCollection.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get all tindakan: $e');
    }
  }

  // GET /tindakan/{id} - Get tindakan by ID
  Future<Tindakan> getTindakanById(int id) async {
    try {
      final response = await _dio.get('/tindakan/$id');
      return Tindakan.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to get tindakan by id: $e');
    }
  }

  // POST /tindakan - Create new tindakan
  Future<Tindakan> createTindakan(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/tindakan', data: data);
      return Tindakan.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to create tindakan: $e');
    }
  }

  // PUT /tindakan/{id} - Update tindakan
  Future<Tindakan> updateTindakan(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/tindakan/$id', data: data);
      return Tindakan.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update tindakan: $e');
    }
  }

  // DELETE /tindakan/{id} - Delete tindakan
  Future<void> deleteTindakan(int id) async {
    try {
      await _dio.delete('/tindakan/$id');
    } catch (e) {
      throw Exception('Failed to delete tindakan: $e');
    }
  }

  // GET /tindakan?search=query - Search tindakan
  Future<TindakanCollection> searchTindakan(String query) async {
    try {
      final response = await _dio.get(
        '/tindakan',
        queryParameters: {'search': query},
      );
      return TindakanCollection.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to search tindakan: $e');
    }
  }

  // GET /tindakan?is_active=1 - Get active tindakan only
  Future<TindakanCollection> getActiveTindakan() async {
    try {
      final response = await _dio.get(
        '/tindakan',
        queryParameters: {'is_active': 1},
      );
      return TindakanCollection.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get active tindakan: $e');
    }
  }

  // ==================== REGISTRASI-TINDAKAN ====================

  // GET /registrasi/{id}/tindakan - Get tindakan for a registrasi
  Future<RegistrasiTindakanCollection> getTindakanByRegistrasiId(
    int registrasiId,
  ) async {
    try {
      final response = await _dio.get('/registrasi/$registrasiId/tindakan');
      return RegistrasiTindakanCollection.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get tindakan by registrasi id: $e');
    }
  }

  // POST /registrasi/{id}/tindakan - Attach tindakan to registrasi
  Future<RegistrasiTindakan> attachTindakanToRegistrasi(
    int registrasiId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        '/registrasi/$registrasiId/tindakan',
        data: data,
      );
      return RegistrasiTindakan.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to attach tindakan to registrasi: $e');
    }
  }

  // PUT /registrasi/{registrasiId}/tindakan/{tindakanId} - Update pivot data
  Future<RegistrasiTindakan> updateRegistrasiTindakan(
    int registrasiId,
    int tindakanId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '/registrasi/$registrasiId/tindakan/$tindakanId',
        data: data,
      );
      return RegistrasiTindakan.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update registrasi tindakan: $e');
    }
  }

  // DELETE /registrasi/{registrasiId}/tindakan/{tindakanId} - Detach tindakan
  Future<void> detachTindakanFromRegistrasi(
    int registrasiId,
    int tindakanId,
  ) async {
    try {
      await _dio.delete('/registrasi/$registrasiId/tindakan/$tindakanId');
    } catch (e) {
      throw Exception('Failed to detach tindakan from registrasi: $e');
    }
  }
}
