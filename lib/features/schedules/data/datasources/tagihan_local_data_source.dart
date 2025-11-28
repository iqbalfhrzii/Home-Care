import 'package:drift/drift.dart';
import 'package:homecare_mobile/shared/local_db/app_database.dart';
import 'package:intl/intl.dart';

class TagihanLocalDataSource {
  final AppDatabase _database;

  TagihanLocalDataSource(this._database);

  // Get all tagihan
  Future<List<Tagihan>> getAllTagihan() async {
    return await _database.getAllTagihans();
  }

  // Get tagihan by ID
  Future<Tagihan?> getTagihanById(int id) async {
    return await _database.getTagihanById(id);
  }

  // Get tagihan by registrasi ID
  Future<Tagihan?> getTagihanByRegistrasiId(int registrasiId) async {
    return await _database.getTagihanByKunjunganId(registrasiId);
  }

  // Get tagihan by status
  Future<List<Tagihan>> getTagihanByStatus(String status) async {
    return await _database.getTagihansByStatus(status);
  }

  // Generate tagihan from completed registrasi
  Future<int> generateTagihan({
    required int registrasiId,
    required int pasienId,
    required int totalBiaya,
    int deposit = 0,
    String? catatan,
  }) async {
    // Calculate remaining balance
    final sisaBiaya = totalBiaya - deposit;
    
    // Determine status
    String status;
    if (sisaBiaya <= 0) {
      status = 'lunas';
    } else if (deposit > 0) {
      status = 'belum_lunas';
    } else {
      status = 'pending';
    }

    // Generate invoice number
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final noInvoice = 'INV-$dateStr-${now.millisecondsSinceEpoch.toString().substring(8)}';

    return await _database.insertTagihan(
      TagihansCompanion(
        noInvoice: Value(noInvoice),
        kunjunganId: Value(registrasiId),
        pasienId: Value(pasienId),
        tanggalTagihan: Value(now),
        totalBiaya: Value(totalBiaya),
        deposit: Value(deposit),
        sisaBiaya: Value(sisaBiaya),
        statusPembayaran: Value(status),
        catatan: Value(catatan),
      ),
    );
  }

  // Update payment status
  Future<bool> updatePaymentStatus({
    required int tagihanId,
    required int newDeposit,
  }) async {
    final tagihan = await getTagihanById(tagihanId);
    if (tagihan == null) return false;

    final sisaBiaya = tagihan.totalBiaya - newDeposit;
    
    String status;
    if (sisaBiaya <= 0) {
      status = 'lunas';
    } else if (newDeposit > 0) {
      status = 'belum_lunas';
    } else {
      status = 'pending';
    }

    return await _database.updateTagihan(
      tagihanId,
      TagihansCompanion(
        deposit: Value(newDeposit),
        sisaBiaya: Value(sisaBiaya),
        statusPembayaran: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Mark as paid
  Future<bool> markAsPaid(int tagihanId) async {
    final tagihan = await getTagihanById(tagihanId);
    if (tagihan == null) return false;

    return await _database.updateTagihan(
      tagihanId,
      TagihansCompanion(
        deposit: Value(tagihan.totalBiaya),
        sisaBiaya: const Value(0),
        statusPembayaran: const Value('lunas'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Get tagihan statistics
  Future<Map<String, dynamic>> getTagihanStatistics() async {
    final allTagihan = await getAllTagihan();
    
    final lunas = allTagihan.where((t) => t.statusPembayaran == 'lunas').length;
    final belumLunas = allTagihan.where((t) => t.statusPembayaran == 'belum_lunas').length;
    final pending = allTagihan.where((t) => t.statusPembayaran == 'pending').length;
    
    final totalBiaya = allTagihan.fold<int>(
      0,
      (sum, t) => sum + t.totalBiaya,
    );
    
    final totalDeposit = allTagihan.fold<int>(
      0,
      (sum, t) => sum + t.deposit,
    );
    
    final totalSisa = allTagihan.fold<int>(
      0,
      (sum, t) => sum + t.sisaBiaya,
    );

    return {
      'total': allTagihan.length,
      'lunas': lunas,
      'belum_lunas': belumLunas,
      'pending': pending,
      'total_biaya': totalBiaya,
      'total_deposit': totalDeposit,
      'total_sisa': totalSisa,
    };
  }

  // Delete tagihan
  Future<bool> deleteTagihan(int id) async {
    final deleted = await (_database.delete(_database.tagihans)
          ..where((t) => t.id.equals(id)))
        .go();
    return deleted > 0;
  }
}
