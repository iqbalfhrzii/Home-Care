import 'package:homecare_mobile/shared/local_db/app_database.dart';
import 'package:homecare_mobile/features/reports/domain/models/tagihan.dart'
    as domain;
import 'package:drift/drift.dart' as drift;

class TagihanLocalDataSource {
  final AppDatabase _database;

  TagihanLocalDataSource(this._database);

  // ==================== TAGIHAN ====================

  // Convert Drift Tagihan to Domain Tagihan
  domain.Tagihan _toDomainTagihan(Tagihan driftTagihan) {
    return domain.Tagihan(
      id: driftTagihan.id,
      registrasiId: driftTagihan.registrasiId,
      noInvoice: driftTagihan.noInvoice,
      tanggalInvoice: driftTagihan.tanggalInvoice,
      totalBiaya: driftTagihan.totalBiaya,
      deposit: driftTagihan.deposit,
      biayaYangHarusDibayar: driftTagihan.biayaYangHarusDibayar,
      terbilang: driftTagihan.terbilang,
      primaryIcd: driftTagihan.primaryIcd,
      statusPembayaran: driftTagihan.statusPembayaran,
      dicetakOleh: driftTagihan.dicetakOleh,
      tanggalCetak: driftTagihan.tanggalCetak,
      printLocation: driftTagihan.printLocation,
      serverTime: driftTagihan.serverTime,
      computerTime: driftTagihan.computerTime,
      userId: driftTagihan.userId,
      createdAt: driftTagihan.createdAt.toIso8601String(),
      updatedAt: driftTagihan.updatedAt.toIso8601String(),
    );
  }

  // Get all tagihan
  Future<List<domain.Tagihan>> getAllTagihan() async {
    final tagihans = await _database.getAllTagihans();
    return tagihans.map(_toDomainTagihan).toList();
  }

  // Get tagihan by ID
  Future<domain.Tagihan> getTagihanById(int id) async {
    final tagihan = await _database.getTagihanById(id);
    if (tagihan == null) {
      throw Exception('Tagihan with id $id not found');
    }
    return _toDomainTagihan(tagihan);
  }

  // Get tagihan by registrasi ID
  Future<List<domain.Tagihan>> getTagihanByRegistrasiId(
    int registrasiId,
  ) async {
    final tagihans = await _database.getTagihansByRegistrasiId(registrasiId);
    return tagihans.map(_toDomainTagihan).toList();
  }

  // Get tagihan by payment status
  Future<List<domain.Tagihan>> getTagihanByStatus(String status) async {
    final allTagihan = await _database.getAllTagihans();
    final filtered = allTagihan
        .where((t) => t.statusPembayaran == status)
        .toList();
    return filtered.map(_toDomainTagihan).toList();
  }

  // Create new tagihan
  Future<domain.Tagihan> createTagihan(Map<String, dynamic> data) async {
    final companion = TagihansCompanion(
      registrasiId: drift.Value(data['registrasi_id'] as int),
      noInvoice: drift.Value(data['no_invoice'] as String),
      tanggalInvoice: data['tanggal_invoice'] != null
          ? drift.Value(data['tanggal_invoice'] as String)
          : const drift.Value.absent(),
      totalBiaya: data['total_biaya'] != null
          ? drift.Value(data['total_biaya'] as String)
          : const drift.Value.absent(),
      deposit: data['deposit'] != null
          ? drift.Value(data['deposit'] as String)
          : const drift.Value.absent(),
      biayaYangHarusDibayar: data['biaya_yang_harus_dibayar'] != null
          ? drift.Value(data['biaya_yang_harus_dibayar'] as String)
          : const drift.Value.absent(),
      terbilang: data['terbilang'] != null
          ? drift.Value(data['terbilang'] as String)
          : const drift.Value.absent(),
      primaryIcd: data['primary_icd'] != null
          ? drift.Value(data['primary_icd'] as String)
          : const drift.Value.absent(),
      statusPembayaran: data['status_pembayaran'] != null
          ? drift.Value(data['status_pembayaran'] as String)
          : const drift.Value('belum_bayar'),
      dicetakOleh: data['dicetak_oleh'] != null
          ? drift.Value(data['dicetak_oleh'] as String)
          : const drift.Value.absent(),
      tanggalCetak: data['tanggal_cetak'] != null
          ? drift.Value(data['tanggal_cetak'] as String)
          : const drift.Value.absent(),
      printLocation: data['print_location'] != null
          ? drift.Value(data['print_location'] as String)
          : const drift.Value.absent(),
      serverTime: data['server_time'] != null
          ? drift.Value(data['server_time'] as String)
          : const drift.Value.absent(),
      computerTime: data['computer_time'] != null
          ? drift.Value(data['computer_time'] as String)
          : const drift.Value.absent(),
      userId: data['user_id'] != null
          ? drift.Value(data['user_id'] as int)
          : const drift.Value.absent(),
    );

    final id = await _database.insertTagihan(companion);
    return getTagihanById(id);
  }

  // Update tagihan
  Future<domain.Tagihan> updateTagihan(
    int id,
    Map<String, dynamic> data,
  ) async {
    final companion = TagihansCompanion(
      registrasiId: data['registrasi_id'] != null
          ? drift.Value(data['registrasi_id'] as int)
          : const drift.Value.absent(),
      noInvoice: data['no_invoice'] != null
          ? drift.Value(data['no_invoice'] as String)
          : const drift.Value.absent(),
      tanggalInvoice: data['tanggal_invoice'] != null
          ? drift.Value(data['tanggal_invoice'] as String)
          : const drift.Value.absent(),
      totalBiaya: data['total_biaya'] != null
          ? drift.Value(data['total_biaya'] as String)
          : const drift.Value.absent(),
      deposit: data['deposit'] != null
          ? drift.Value(data['deposit'] as String)
          : const drift.Value.absent(),
      biayaYangHarusDibayar: data['biaya_yang_harus_dibayar'] != null
          ? drift.Value(data['biaya_yang_harus_dibayar'] as String)
          : const drift.Value.absent(),
      terbilang: data['terbilang'] != null
          ? drift.Value(data['terbilang'] as String)
          : const drift.Value.absent(),
      primaryIcd: data['primary_icd'] != null
          ? drift.Value(data['primary_icd'] as String)
          : const drift.Value.absent(),
      statusPembayaran: data['status_pembayaran'] != null
          ? drift.Value(data['status_pembayaran'] as String)
          : const drift.Value.absent(),
      dicetakOleh: data['dicetak_oleh'] != null
          ? drift.Value(data['dicetak_oleh'] as String)
          : const drift.Value.absent(),
      tanggalCetak: data['tanggal_cetak'] != null
          ? drift.Value(data['tanggal_cetak'] as String)
          : const drift.Value.absent(),
      printLocation: data['print_location'] != null
          ? drift.Value(data['print_location'] as String)
          : const drift.Value.absent(),
      serverTime: data['server_time'] != null
          ? drift.Value(data['server_time'] as String)
          : const drift.Value.absent(),
      computerTime: data['computer_time'] != null
          ? drift.Value(data['computer_time'] as String)
          : const drift.Value.absent(),
      userId: data['user_id'] != null
          ? drift.Value(data['user_id'] as int)
          : const drift.Value.absent(),
      updatedAt: drift.Value(DateTime.now()),
    );

    await _database.updateTagihan(id, companion);
    return getTagihanById(id);
  }

  // Delete tagihan
  Future<void> deleteTagihan(int id) async {
    await _database.deleteTagihan(id);
  }

  // Upsert tagihan from API (for sync)
  Future<void> upsertTagihan(domain.Tagihan tagihan) async {
    final existing = await _database.getTagihanById(tagihan.id);

    final companion = TagihansCompanion(
      id: drift.Value(tagihan.id),
      registrasiId: drift.Value(tagihan.registrasiId),
      noInvoice: drift.Value(tagihan.noInvoice),
      tanggalInvoice: tagihan.tanggalInvoice != null
          ? drift.Value(tagihan.tanggalInvoice!)
          : const drift.Value.absent(),
      totalBiaya: tagihan.totalBiaya != null
          ? drift.Value(tagihan.totalBiaya!)
          : const drift.Value.absent(),
      deposit: tagihan.deposit != null
          ? drift.Value(tagihan.deposit!)
          : const drift.Value.absent(),
      biayaYangHarusDibayar: tagihan.biayaYangHarusDibayar != null
          ? drift.Value(tagihan.biayaYangHarusDibayar!)
          : const drift.Value.absent(),
      terbilang: tagihan.terbilang != null
          ? drift.Value(tagihan.terbilang!)
          : const drift.Value.absent(),
      primaryIcd: tagihan.primaryIcd != null
          ? drift.Value(tagihan.primaryIcd!)
          : const drift.Value.absent(),
      statusPembayaran: drift.Value(tagihan.statusPembayaran),
      dicetakOleh: tagihan.dicetakOleh != null
          ? drift.Value(tagihan.dicetakOleh!)
          : const drift.Value.absent(),
      tanggalCetak: tagihan.tanggalCetak != null
          ? drift.Value(tagihan.tanggalCetak!)
          : const drift.Value.absent(),
      printLocation: tagihan.printLocation != null
          ? drift.Value(tagihan.printLocation!)
          : const drift.Value.absent(),
      serverTime: tagihan.serverTime != null
          ? drift.Value(tagihan.serverTime!)
          : const drift.Value.absent(),
      computerTime: tagihan.computerTime != null
          ? drift.Value(tagihan.computerTime!)
          : const drift.Value.absent(),
      userId: tagihan.userId != null
          ? drift.Value(tagihan.userId!)
          : const drift.Value.absent(),
      createdAt: tagihan.createdAt != null
          ? drift.Value(DateTime.parse(tagihan.createdAt!))
          : const drift.Value.absent(),
      updatedAt: tagihan.updatedAt != null
          ? drift.Value(DateTime.parse(tagihan.updatedAt!))
          : drift.Value(DateTime.now()),
    );

    if (existing != null) {
      await _database.updateTagihan(existing.id, companion);
    } else {
      await _database.insertTagihan(companion);
    }
  }

  // Search tagihan locally
  Future<List<domain.Tagihan>> searchTagihan(String query) async {
    final allTagihan = await _database.getAllTagihans();
    final filtered = allTagihan.where((tagihan) {
      return tagihan.noInvoice.toLowerCase().contains(query.toLowerCase()) ||
          (tagihan.tanggalInvoice?.toLowerCase().contains(
                query.toLowerCase(),
              ) ??
              false);
    }).toList();
    return filtered.map(_toDomainTagihan).toList();
  }

  // ==================== TAGIHAN ITEMS ====================

  // Convert Drift TagihanItem to Domain
  domain.TagihanItem _toDomainTagihanItem(TagihanItem driftItem) {
    return domain.TagihanItem(
      id: driftItem.id,
      tagihanId: driftItem.tagihanId,
      kategoriLayananId: driftItem.kategoriLayananId,
      kodeLayanan: driftItem.kodeLayanan,
      deskripsi: driftItem.deskripsi,
      jumlah: driftItem.jumlah,
      hargaSatuan: driftItem.hargaSatuan,
      diskon: driftItem.diskon,
      subtotal: driftItem.subtotal,
      tanggalLayanan: driftItem.tanggalLayanan,
      urutan: driftItem.urutan,
      createdAt: driftItem.createdAt.toIso8601String(),
      updatedAt: driftItem.updatedAt.toIso8601String(),
    );
  }

  // Get tagihan items by tagihan ID
  Future<List<domain.TagihanItem>> getTagihanItems(int tagihanId) async {
    final items = await _database.getTagihanItemsByTagihanId(tagihanId);
    return items.map(_toDomainTagihanItem).toList();
  }

  // Add tagihan item
  Future<domain.TagihanItem> addTagihanItem(
    int tagihanId,
    Map<String, dynamic> data,
  ) async {
    final companion = TagihanItemsCompanion(
      tagihanId: drift.Value(tagihanId),
      kategoriLayananId: data['kategori_layanan_id'] != null
          ? drift.Value(data['kategori_layanan_id'] as int)
          : const drift.Value.absent(),
      kodeLayanan: data['kode_layanan'] != null
          ? drift.Value(data['kode_layanan'] as String)
          : const drift.Value.absent(),
      deskripsi: data['deskripsi'] != null
          ? drift.Value(data['deskripsi'] as String)
          : const drift.Value.absent(),
      jumlah: data['jumlah'] != null
          ? drift.Value(data['jumlah'] as int)
          : const drift.Value(0),
      hargaSatuan: data['harga_satuan'] != null
          ? drift.Value(data['harga_satuan'] as String)
          : const drift.Value.absent(),
      diskon: data['diskon'] != null
          ? drift.Value(data['diskon'] as String)
          : const drift.Value.absent(),
      subtotal: data['subtotal'] != null
          ? drift.Value(data['subtotal'] as String)
          : const drift.Value.absent(),
      tanggalLayanan: data['tanggal_layanan'] != null
          ? drift.Value(data['tanggal_layanan'] as String)
          : const drift.Value.absent(),
      urutan: data['urutan'] != null
          ? drift.Value(data['urutan'] as int)
          : const drift.Value(0),
    );

    final id = await _database.insertTagihanItem(companion);
    final inserted = await _database.getTagihanItemById(id);
    if (inserted == null) {
      throw Exception('Failed to insert tagihan item');
    }
    return _toDomainTagihanItem(inserted);
  }

  // Update tagihan item
  Future<domain.TagihanItem> updateTagihanItem(
    int itemId,
    Map<String, dynamic> data,
  ) async {
    final companion = TagihanItemsCompanion(
      kategoriLayananId: data['kategori_layanan_id'] != null
          ? drift.Value(data['kategori_layanan_id'] as int)
          : const drift.Value.absent(),
      kodeLayanan: data['kode_layanan'] != null
          ? drift.Value(data['kode_layanan'] as String)
          : const drift.Value.absent(),
      deskripsi: data['deskripsi'] != null
          ? drift.Value(data['deskripsi'] as String)
          : const drift.Value.absent(),
      jumlah: data['jumlah'] != null
          ? drift.Value(data['jumlah'] as int)
          : const drift.Value.absent(),
      hargaSatuan: data['harga_satuan'] != null
          ? drift.Value(data['harga_satuan'] as String)
          : const drift.Value.absent(),
      diskon: data['diskon'] != null
          ? drift.Value(data['diskon'] as String)
          : const drift.Value.absent(),
      subtotal: data['subtotal'] != null
          ? drift.Value(data['subtotal'] as String)
          : const drift.Value.absent(),
      tanggalLayanan: data['tanggal_layanan'] != null
          ? drift.Value(data['tanggal_layanan'] as String)
          : const drift.Value.absent(),
      urutan: data['urutan'] != null
          ? drift.Value(data['urutan'] as int)
          : const drift.Value.absent(),
      updatedAt: drift.Value(DateTime.now()),
    );

    await _database.updateTagihanItem(itemId, companion);
    final updated = await _database.getTagihanItemById(itemId);
    if (updated == null) {
      throw Exception('Failed to update tagihan item');
    }
    return _toDomainTagihanItem(updated);
  }

  // Delete tagihan item
  Future<void> deleteTagihanItem(int itemId) async {
    await _database.deleteTagihanItem(itemId);
  }

  // Upsert tagihan item from API (for sync)
  Future<void> upsertTagihanItem(domain.TagihanItem item) async {
    final existing = await _database.getTagihanItemById(item.id);

    final companion = TagihanItemsCompanion(
      id: drift.Value(item.id),
      tagihanId: drift.Value(item.tagihanId),
      kategoriLayananId: item.kategoriLayananId != null
          ? drift.Value(item.kategoriLayananId!)
          : const drift.Value.absent(),
      kodeLayanan: item.kodeLayanan != null
          ? drift.Value(item.kodeLayanan!)
          : const drift.Value.absent(),
      deskripsi: item.deskripsi != null
          ? drift.Value(item.deskripsi!)
          : const drift.Value.absent(),
      jumlah: drift.Value(item.jumlah),
      hargaSatuan: item.hargaSatuan != null
          ? drift.Value(item.hargaSatuan!)
          : const drift.Value.absent(),
      diskon: item.diskon != null
          ? drift.Value(item.diskon!)
          : const drift.Value.absent(),
      subtotal: item.subtotal != null
          ? drift.Value(item.subtotal!)
          : const drift.Value.absent(),
      tanggalLayanan: item.tanggalLayanan != null
          ? drift.Value(item.tanggalLayanan!)
          : const drift.Value.absent(),
      urutan: drift.Value(item.urutan),
      createdAt: item.createdAt != null
          ? drift.Value(DateTime.parse(item.createdAt!))
          : const drift.Value.absent(),
      updatedAt: item.updatedAt != null
          ? drift.Value(DateTime.parse(item.updatedAt!))
          : drift.Value(DateTime.now()),
    );

    if (existing != null) {
      await _database.updateTagihanItem(existing.id, companion);
    } else {
      await _database.insertTagihanItem(companion);
    }
  }
}
