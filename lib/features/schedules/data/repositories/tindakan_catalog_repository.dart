import 'package:dio/dio.dart';
import '../../../../core/network/dio.dart' as net;

class TindakanCatalogRepository {
  final Dio _dio = net.dio;

  Future<List<Map<String, dynamic>>> getAll() async {
    final resp = await _dio.get('/tindakan', queryParameters: {'per_page': 1000});
    final data = resp.data;
    final List<dynamic> items = (data is Map && data['data'] is List)
        ? (data['data'] as List)
        : (data is List ? data : const <dynamic>[]);
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
