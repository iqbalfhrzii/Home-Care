import 'package:dio/dio.dart';
import 'package:homecare_mobile/shared/app_injections.dart';

class TagihanRepository {
  final Dio _dio = getIt<Dio>();

  Future<Response> createTagihan({
    required int registrasiId,
    required String primaryIcd,
    required List<Map<String, dynamic>> items,
    String? noInvoice,
    DateTime? tanggalInvoice,
    String statusPembayaran = 'belum_bayar',
    num deposit = 0,
    String? terbilang,
  }) async {
    // Compute totals client-side
    num total = 0;
    for (final it in items) {
      total += (it['subtotal'] ?? 0) as num;
    }
    final payload = {
      'registrasi_id': registrasiId,
      'no_invoice': noInvoice ?? 'INV-$registrasiId-${DateTime.now().millisecondsSinceEpoch}',
      'tanggal_invoice': (tanggalInvoice ?? DateTime.now()).toIso8601String(),
      'total_biaya': total,
      'deposit': deposit,
      'biaya_yang_harus_dibayar': total - deposit,
      if (terbilang != null) 'terbilang': terbilang,
      'primary_icd': primaryIcd,
      'status_pembayaran': statusPembayaran,
      'dicetak_oleh': 0,
      'tanggal_cetak': DateTime.now().toIso8601String(),
      'print_location': 'BALIKPAPAN',
      'server_time': DateTime.now().toIso8601String(),
      'computer_time': DateTime.now().toIso8601String(),
      'items': items,
    };
    return _dio.post('/api/v1/tagihan', data: payload);
  }
}
