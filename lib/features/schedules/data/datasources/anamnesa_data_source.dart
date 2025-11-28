import 'package:dio/dio.dart';
import 'package:homecare_mobile/features/schedules/domain/models/anamnesa.dart';

class AnamnesaDataSource {
  final Dio _dio;

  AnamnesaDataSource(this._dio);

  // GET /anamnesa - Get all anamnesa
  Future<AnamnesaCollection> getAllAnamnesa() async {
    try {
      final response = await _dio.get('/anamnesa');
      return AnamnesaCollection.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get all anamnesa: $e');
    }
  }

  // GET /anamnesa/{id} - Get anamnesa by ID
  Future<Anamnesa> getAnamnesaById(int id) async {
    try {
      final response = await _dio.get('/anamnesa/$id');
      return Anamnesa.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to get anamnesa by id: $e');
    }
  }

  // POST /anamnesa - Create new anamnesa
  Future<Anamnesa> createAnamnesa(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/anamnesa', data: data);
      return Anamnesa.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to create anamnesa: $e');
    }
  }

  // PUT /anamnesa/{id} - Update anamnesa
  Future<Anamnesa> updateAnamnesa(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/anamnesa/$id', data: data);
      return Anamnesa.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update anamnesa: $e');
    }
  }

  // DELETE /anamnesa/{id} - Delete anamnesa
  Future<void> deleteAnamnesa(int id) async {
    try {
      await _dio.delete('/anamnesa/$id');
    } catch (e) {
      throw Exception('Failed to delete anamnesa: $e');
    }
  }

  // GET /anamnesa?search=query - Search anamnesa
  Future<AnamnesaCollection> searchAnamnesa(String query) async {
    try {
      final response = await _dio.get(
        '/anamnesa',
        queryParameters: {'search': query},
      );
      return AnamnesaCollection.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to search anamnesa: $e');
    }
  }

  // GET /anamnesa?registrasi_id={id} - Get anamnesa by registrasi ID
  Future<AnamnesaCollection> getAnamnesaByRegistrasiId(int registrasiId) async {
    try {
      final response = await _dio.get(
        '/anamnesa',
        queryParameters: {'registrasi_id': registrasiId},
      );
      return AnamnesaCollection.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get anamnesa by registrasi id: $e');
    }
  }

  // GET /anamnesa?tanggal={date} - Get anamnesa by date
  Future<AnamnesaCollection> getAnamnesaByDate(String date) async {
    try {
      final response = await _dio.get(
        '/anamnesa',
        queryParameters: {'tanggal': date},
      );
      return AnamnesaCollection.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get anamnesa by date: $e');
    }
  }
}
