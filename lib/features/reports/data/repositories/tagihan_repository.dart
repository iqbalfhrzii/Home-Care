import 'package:dio/dio.dart';
import 'package:homecare_mobile/core/network/dio.dart' as net;
import 'package:homecare_mobile/features/reports/domain/models/tagihan.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';
import 'dart:typed_data';

class TagihanRepository {
  final Dio _dio = net.dio;

  Future<List<Tagihan>> getAllTagihan() async {
    try {
      final resp = await _dio.get(
        '/tagihan',
        queryParameters: {'per_page': 100},
      );
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
      final data = resp.data is Map<String, dynamic>
          ? resp.data as Map<String, dynamic>
          : {'data': resp.data};
      final map = (data['data'] ?? data);
      if (map is Map<String, dynamic>) {
        return Tagihan.fromJson(map);
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  Future<Tagihan?> getTagihanByRegistrasiId(int registrasiId) async {
    try {
      final resp = await _dio.get(
        '/tagihan',
        queryParameters: {'registrasi_id': registrasiId, 'per_page': 1},
      );
      final data = resp.data;
      final List<dynamic> items = (data is Map && data['data'] is List)
          ? (data['data'] as List)
          : (data is List ? data : const <dynamic>[]);
      if (items.isNotEmpty && items.first is Map) {
        return Tagihan.fromJson(Map<String, dynamic>.from(items.first as Map));
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  Future<Tagihan?> createTagihan(Map<String, dynamic> data) async {
    try {
      // Ensure items[] is populated from registrasi.tindakan when missing
      final payload = Map<String, dynamic>.from(data);
      String formatCurrency(num v) => v.toStringAsFixed(2);
      if ((payload['items'] == null ||
              (payload['items'] is List &&
                  (payload['items'] as List).isEmpty)) &&
          payload['registrasi_id'] != null) {
        try {
          final regRepo = getIt<RegistrasiRepository>();
          final raw = await regRepo.getRegistrasiRawById(
            payload['registrasi_id'] is int
                ? payload['registrasi_id']
                : int.tryParse(payload['registrasi_id'].toString()) ?? 0,
          );
          if (raw != null &&
              raw['tindakan'] is List &&
              (raw['tindakan'] as List).isNotEmpty) {
            final List itemsFromTindakan = [];
            for (final t in (raw['tindakan'] as List)) {
              if (t is Map<String, dynamic>) {
                final jumlah = t['pivot'] != null
                    ? (t['pivot']['jumlah'] ?? t['jumlah'] ?? 1)
                    : (t['jumlah'] ?? 1);
                final hargaRaw = t['pivot'] != null
                    ? (t['pivot']['harga_satuan'] ??
                          t['pivot']['tarif'] ??
                          t['tarif'] ??
                          t['harga_satuan'] ??
                          t['harga'])
                    : (t['harga_satuan'] ?? t['tarif'] ?? t['harga']);
                final harga = (hargaRaw is num)
                    ? hargaRaw
                    : (double.tryParse(hargaRaw?.toString() ?? '') ?? 0);
                final diskonRaw = t['pivot'] != null
                    ? (t['pivot']['diskon'] ?? 0)
                    : (t['diskon'] ?? 0);
                final diskon = (diskonRaw is num)
                    ? diskonRaw
                    : (double.tryParse(diskonRaw?.toString() ?? '') ?? 0);
                final subtotal =
                    (jumlah is num
                            ? jumlah
                            : (int.tryParse(jumlah?.toString() ?? '1') ?? 1)) *
                        harga -
                    diskon;
                itemsFromTindakan.add({
                  'kategori_layanan_id':
                      t['kategori_layanan_id'] ?? t['tindakan_id'] ?? 1,
                  'kode_layanan': t['kode'] ?? '',
                  'tanggal_layanan': t['pivot'] != null
                      ? (t['pivot']['tanggal_layanan'] ??
                            payload['tanggal_invoice'])
                      : payload['tanggal_invoice'],
                  'deskripsi': t['deskripsi'] ?? t['nama_tindakan'] ?? '',
                  'jumlah': jumlah is num
                      ? jumlah
                      : (int.tryParse(jumlah?.toString() ?? '1') ?? 1),
                  'harga_satuan': formatCurrency(harga),
                  'diskon': formatCurrency(diskon),
                  'subtotal': formatCurrency(subtotal),
                });
              }
            }
            if (itemsFromTindakan.isNotEmpty) {
              payload['items'] = itemsFromTindakan;
            }
          }
        } catch (e) {
          print('⚠️ Failed to populate items from registrasi: $e');
        }
      }

      // Allow reading error body by accepting any status here and handling below
      final resp = await _dio.post(
        '/tagihan',
        data: payload,
        options: Options(validateStatus: (_) => true),
      );

      if (resp.statusCode != null && resp.statusCode! >= 400) {
        print('❌ Create Tagihan failed. Status: ${resp.statusCode}');
        print('📤 Payload: $payload');
        print('📥 Response: ${resp.data}');
        // If backend indicates a tagihan already exists for this registrasi, try to find
        // the existing Tagihan and perform an update instead of failing.
        try {
          final code = resp.statusCode ?? 0;
          final respData = resp.data;
          final msg = respData is Map
              ? respData['message']?.toString() ?? ''
              : '';
          final hasRegistrasiError =
              respData is Map &&
              respData['errors'] != null &&
              respData['errors']['registrasi_id'] != null;

          // If validation says already exists (422) OR DB returned unique constraint (sqlite 500),
          // attempt to find existing tagihan and call update instead of failing.
          final isUniqueConstraint =
              (respData is Map &&
                  respData['message'] != null &&
                  respData['message'].toString().toLowerCase().contains(
                    'unique',
                  )) ||
              (respData is String &&
                  respData.toLowerCase().contains('unique')) ||
              msg.toLowerCase().contains('unique') ||
              msg.toLowerCase().contains('unique constraint') ||
              (respData is Map &&
                  respData['message'] != null &&
                  respData['message'].toString().toLowerCase().contains(
                    'registrasi_id',
                  ));

          if ((code == 422 &&
                  (msg.contains('sudah ada') || hasRegistrasiError)) ||
              (code >= 500 && isUniqueConstraint)) {
            final registrasiId = data['registrasi_id'];
            if (registrasiId != null) {
              // Try to find existing tagihan by registrasi id from list endpoint
              final all = await getAllTagihan();
              Tagihan? existing;
              final registrasiInt = registrasiId is String
                  ? int.tryParse(registrasiId)
                  : (registrasiId as int?);
              if (registrasiInt != null) {
                try {
                  // Prefer querying the backend for tagihan filtered by registrasi_id
                  final listResp = await _dio.get(
                    '/tagihan',
                    queryParameters: {
                      'registrasi_id': registrasiInt,
                      'per_page': 1,
                    },
                    options: Options(validateStatus: (_) => true),
                  );
                  if (listResp.statusCode != null &&
                      listResp.statusCode! >= 400) {
                    // fallback to listing all tagihan if filtered query fails
                    print(
                      '⚠️ Querying tagihan by registrasi_id failed: status=${listResp.statusCode}, body=${listResp.data}',
                    );
                    for (final t in all) {
                      if (t.registrasiId == registrasiInt) {
                        existing = t;
                        break;
                      }
                    }
                  } else {
                    final listData = listResp.data;
                    final items = (listData is Map && listData['data'] is List)
                        ? (listData['data'] as List)
                        : (listData is List ? listData : const <dynamic>[]);
                    if (items.isNotEmpty &&
                        items.first is Map<String, dynamic>) {
                      existing = Tagihan.fromJson(
                        Map<String, dynamic>.from(items.first as Map),
                      );
                    }
                  }
                } catch (e) {
                  print('⚠️ Failed to query tagihan by registrasi_id: $e');
                  for (final t in all) {
                    if (t.registrasiId == registrasiInt) {
                      existing = t;
                      break;
                    }
                  }
                }
              }
              if (existing != null) {
                print(
                  'ℹ️ Found existing Tagihan (id=${existing.id}) for registrasi=$registrasiId — performing update instead',
                );
                return await updateTagihan(existing.id, data);
              }
            }
          }
        } catch (e) {
          print('⚠️ Fallback update on createTagihan failed: $e');
        }

        throw DioException(requestOptions: resp.requestOptions, response: resp);
      }

      final respData = resp.data;
      final map = (respData is Map && respData['data'] != null)
          ? respData['data']
          : respData;
      if (map is Map<String, dynamic>) {
        return Tagihan.fromJson(map);
      }
      return null;
    } on DioException catch (e) {
      print('❌ Error creating tagihan: ${e.message}');
      print('📥 Dio error response: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Tagihan?> updateTagihan(int id, Map<String, dynamic> data) async {
    try {
      final resp = await _dio.put('/tagihan/$id', data: data);
      final respData = resp.data;
      final map = (respData is Map && respData['data'] != null)
          ? respData['data']
          : respData;
      if (map is Map<String, dynamic>) {
        return Tagihan.fromJson(map);
      }
      return null;
    } on DioException catch (e) {
      print('❌ Error updating tagihan: ${e.message}');
      rethrow;
    }
  }

  Future<bool> deleteTagihan(int id) async {
    try {
      final resp = await _dio.delete(
        '/tagihan/$id',
        options: Options(validateStatus: (_) => true),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        print(
          '❌ Delete Tagihan failed: status=${resp.statusCode}, body=${resp.data}',
        );
        return false;
      }
      return true;
    } on DioException catch (e) {
      print('❌ DioException deleting tagihan: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Error deleting tagihan: $e');
      return false;
    }
  }

  Future<String?> getPrintUrl(int id) async {
    try {
      // Return the print URL - backend will generate PDF
      return '${_dio.options.baseUrl}/tagihan/$id/print';
    } catch (e) {
      print('❌ Error getting print URL: $e');
      return null;
    }
  }

  /// Download the generated PDF bytes for a tagihan using authenticated request
  Future<Uint8List?> downloadPrintPdf(int id) async {
    try {
      final resp = await _dio.get(
        '/tagihan/$id/print',
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (_) => true,
        ),
      );

      if (resp.statusCode == null || resp.statusCode! >= 400) {
        print(
          '❌ Download PDF failed: status=${resp.statusCode}, data=${resp.data}',
        );
        return null;
      }

      final data = resp.data;
      if (data is Uint8List) return data;
      if (data is List<int>) return Uint8List.fromList(data);
      return null;
    } on DioException catch (e) {
      print('❌ DioException downloading PDF: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Error downloading PDF: $e');
      return null;
    }
  }
}
