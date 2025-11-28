import 'package:dio/dio.dart';
import 'package:homecare_mobile/features/reports/domain/models/tagihan.dart';

class TagihanDataSource {
  final Dio _dio;

  TagihanDataSource(this._dio);

  // ==================== TAGIHAN ====================

  // GET /tagihan - Get all tagihan
  Future<TagihanCollection> getAllTagihan() async {
    try {
      final response = await _dio.get('/tagihan');
      return TagihanCollection.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get all tagihan: $e');
    }
  }

  // GET /tagihan/{id} - Get tagihan by ID
  Future<Tagihan> getTagihanById(int id) async {
    try {
      final response = await _dio.get('/tagihan/$id');
      return Tagihan.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to get tagihan by id: $e');
    }
  }

  // POST /tagihan - Create new tagihan
  Future<Tagihan> createTagihan(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/tagihan', data: data);
      return Tagihan.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to create tagihan: $e');
    }
  }

  // PUT /tagihan/{id} - Update tagihan
  Future<Tagihan> updateTagihan(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/tagihan/$id', data: data);
      return Tagihan.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update tagihan: $e');
    }
  }

  // DELETE /tagihan/{id} - Delete tagihan
  Future<void> deleteTagihan(int id) async {
    try {
      await _dio.delete('/tagihan/$id');
    } catch (e) {
      throw Exception('Failed to delete tagihan: $e');
    }
  }

  // GET /tagihan?search=query - Search tagihan
  Future<TagihanCollection> searchTagihan(String query) async {
    try {
      final response = await _dio.get(
        '/tagihan',
        queryParameters: {'search': query},
      );
      return TagihanCollection.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to search tagihan: $e');
    }
  }

  // GET /tagihan?registrasi_id={id} - Get tagihan by registrasi ID
  Future<TagihanCollection> getTagihanByRegistrasiId(int registrasiId) async {
    try {
      final response = await _dio.get(
        '/tagihan',
        queryParameters: {'registrasi_id': registrasiId},
      );
      return TagihanCollection.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get tagihan by registrasi id: $e');
    }
  }

  // GET /tagihan?status_pembayaran={status} - Get by payment status
  Future<TagihanCollection> getTagihanByStatus(String status) async {
    try {
      final response = await _dio.get(
        '/tagihan',
        queryParameters: {'status_pembayaran': status},
      );
      return TagihanCollection.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get tagihan by status: $e');
    }
  }

  // GET /tagihan?tanggal={date} - Get by date
  Future<TagihanCollection> getTagihanByDate(String date) async {
    try {
      final response = await _dio.get(
        '/tagihan',
        queryParameters: {'tanggal': date},
      );
      return TagihanCollection.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get tagihan by date: $e');
    }
  }

  // PUT /tagihan/{id}/bayar - Mark as paid
  Future<Tagihan> markAsPaid(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/tagihan/$id/bayar', data: data);
      return Tagihan.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to mark tagihan as paid: $e');
    }
  }

  // ==================== TAGIHAN ITEMS ====================

  // GET /tagihan/{id}/items - Get items for a tagihan
  Future<TagihanItemCollection> getTagihanItems(int tagihanId) async {
    try {
      final response = await _dio.get('/tagihan/$tagihanId/items');
      return TagihanItemCollection.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get tagihan items: $e');
    }
  }

  // POST /tagihan/{id}/items - Add item to tagihan
  Future<TagihanItem> addTagihanItem(
    int tagihanId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post('/tagihan/$tagihanId/items', data: data);
      return TagihanItem.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to add tagihan item: $e');
    }
  }

  // PUT /tagihan/{tagihanId}/items/{itemId} - Update item
  Future<TagihanItem> updateTagihanItem(
    int tagihanId,
    int itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '/tagihan/$tagihanId/items/$itemId',
        data: data,
      );
      return TagihanItem.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update tagihan item: $e');
    }
  }

  // DELETE /tagihan/{tagihanId}/items/{itemId} - Delete item
  Future<void> deleteTagihanItem(int tagihanId, int itemId) async {
    try {
      await _dio.delete('/tagihan/$tagihanId/items/$itemId');
    } catch (e) {
      throw Exception('Failed to delete tagihan item: $e');
    }
  }
}
