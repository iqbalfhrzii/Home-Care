import 'package:drift/drift.dart';
import 'package:homecare_mobile/shared/local_db/app_database.dart';

class TindakanLocalDataSource {
  final AppDatabase _database;

  TindakanLocalDataSource(this._database);

  // Get all tindakan for a registrasi
  Future<List<TindakanKunjungan>> getTindakanByRegistrasiId(
      int registrasiId) async {
    return await _database.getTindakansByKunjunganId(registrasiId);
  }

  // Calculate total cost for all tindakan
  Future<int> calculateTotalCost(int registrasiId) async {
    final tindakans = await getTindakanByRegistrasiId(registrasiId);
    return tindakans.fold<int>(
      0,
      (sum, tindakan) => sum + tindakan.totalHarga,
    );
  }

  // Attach tindakan to registrasi
  Future<int> attachTindakan({
    required int registrasiId,
    required String kodeTindakan,
    required String namaTindakan,
    required int jumlah,
    required int hargaSatuan,
    int diskon = 0,
    String? petugasNama,
    String? keterangan,
  }) async {
    // Calculate total after discount
    final subtotal = jumlah * hargaSatuan;
    final totalHarga = subtotal - diskon;

    return await _database.insertTindakanKunjungan(
      TindakanKunjungansCompanion(
        kunjunganId: Value(registrasiId),
        kodeTindakan: Value(kodeTindakan),
        namaTindakan: Value(namaTindakan),
        jumlah: Value(jumlah),
        hargaSatuan: Value(hargaSatuan),
        totalHarga: Value(totalHarga),
        keterangan: Value(keterangan),
      ),
    );
  }

  // Update tindakan quantity
  Future<bool> updateTindakanQuantity(
    int tindakanId,
    int newJumlah,
    int hargaSatuan,
  ) async {
    final totalHarga = newJumlah * hargaSatuan;
    
    final result = await (_database.update(_database.tindakanKunjungans)
          ..where((t) => t.id.equals(tindakanId)))
        .write(
      TindakanKunjungansCompanion(
        jumlah: Value(newJumlah),
        totalHarga: Value(totalHarga),
      ),
    );
    
    return result > 0;
  }

  // Remove tindakan from registrasi
  Future<bool> detachTindakan(int tindakanId) async {
    return await _database.deleteTindakanKunjungan(tindakanId);
  }

  // Clear all tindakan for registrasi
  Future<bool> clearTindakan(int registrasiId) async {
    final allTindakan = await getTindakanByRegistrasiId(registrasiId);
    for (final tindakan in allTindakan) {
      await detachTindakan(tindakan.id);
    }
    return true;
  }

  // Get tindakan summary (for billing)
  Future<Map<String, dynamic>> getTindakanSummary(int registrasiId) async {
    final tindakans = await getTindakanByRegistrasiId(registrasiId);
    
    int totalItems = tindakans.length;
    int totalQuantity = 0;
    int subtotal = 0;
    int totalDiscount = 0;
    int grandTotal = 0;

    for (final tindakan in tindakans) {
      totalQuantity += tindakan.jumlah;
      final itemSubtotal = tindakan.jumlah * tindakan.hargaSatuan;
      subtotal += itemSubtotal;
      final itemDiscount = itemSubtotal - tindakan.totalHarga;
      totalDiscount += itemDiscount;
      grandTotal += tindakan.totalHarga;
    }

    return {
      'total_items': totalItems,
      'total_quantity': totalQuantity,
      'subtotal': subtotal,
      'total_discount': totalDiscount,
      'grand_total': grandTotal,
      'items': tindakans,
    };
  }
}
