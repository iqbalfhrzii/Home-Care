import 'package:dio/dio.dart';
import '../../../../core/network/dio.dart' as net;

class IcdRepository {
  final Dio _dio = net.dio;

  Future<dynamic> getAll({int page = 1, int perPage = 100}) async {
    final resp = await _dio.get(
      '/icd',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return resp.data;
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    try {
      final resp = await _dio.get('/icd/$id');
      return resp.data is Map
          ? Map<String, dynamic>.from(resp.data as Map)
          : null;
    } catch (e) {
      print('Error fetching ICD by ID $id: $e');
      return null;
    }
  }
}
