import 'package:dio/dio.dart';
import 'package:homecare_mobile/core/network/dio.dart' as net;
import 'package:homecare_mobile/features/reports/domain/models/tagihan.dart';

class TagihanRepository {
  final Dio _dio = net.dio;

  Future<List<Tagihan>> getAllTagihan() async {
    try {
      final resp = await _dio.get('/tagihan', queryParameters: {'per_page': 100});
      final data = resp.data;
      final List<dynamic> items = (data is Map && data['data'] is List)
          ? (data['data'] as List)
          : (data is List ? data : const <dynamic>[]);
      return items
          .whereType<Map>()
          .map((e) => Tagihan.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (_) {
      // Gracefully handle non-JSON responses (e.g., HTML from 401/500)
      return const <Tagihan>[];
    } catch (_) {
      return const <Tagihan>[];
    }
  }

  Future<Tagihan?> getTagihanById(int id) async {
    try {
      final resp = await _dio.get('/tagihan/$id');
      final data = resp.data is Map<String, dynamic> ? resp.data as Map<String, dynamic> : {'data': resp.data};
      final map = (data['data'] ?? data);
      if (map is Map<String, dynamic>) {
        return Tagihan.fromJson(map);
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }
}
