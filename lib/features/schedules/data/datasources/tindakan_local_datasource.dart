import 'package:homecare_mobile/shared/local_db/app_database.dart';
import 'package:homecare_mobile/features/schedules/domain/models/tindakan.dart'
    as domain;
import 'package:drift/drift.dart' as drift;

class TindakanLocalDataSource {
  final AppDatabase _database;

  TindakanLocalDataSource(this._database);

  // ==================== MASTER TINDAKAN ====================

  // Convert Drift Tindakan to Domain Tindakan
  domain.Tindakan _toDomainTindakan(Tindakan driftTindakan) {
    return domain.Tindakan(
      id: driftTindakan.id,
      kode: driftTindakan.kode,
      deskripsi: driftTindakan.deskripsi,
      tarif: driftTindakan.tarif,
      isActive: driftTindakan.isActive,
      createdAt: driftTindakan.createdAt.toIso8601String(),
      updatedAt: driftTindakan.updatedAt.toIso8601String(),
    );
  }

  // Get all tindakan
  Future<List<domain.Tindakan>> getAllTindakan() async {
    final tindakans = await _database.getAllTindakans();
    return tindakans.map(_toDomainTindakan).toList();
  }

  // Get tindakan by ID
  Future<domain.Tindakan> getTindakanById(int id) async {
    final tindakan = await _database.getTindakanById(id);
    if (tindakan == null) {
      throw Exception('Tindakan with id $id not found');
    }
    return _toDomainTindakan(tindakan);
  }

  // Get active tindakan only
  Future<List<domain.Tindakan>> getActiveTindakan() async {
    final allTindakan = await _database.getAllTindakans();
    final active = allTindakan.where((t) => t.isActive).toList();
    return active.map(_toDomainTindakan).toList();
  }

  // Create new tindakan
  Future<domain.Tindakan> createTindakan(Map<String, dynamic> data) async {
    final companion = TindakansCompanion(
      kode: drift.Value(data['kode'] as String),
      deskripsi: drift.Value(data['deskripsi'] as String),
      tarif: drift.Value(data['tarif'] as String),
      isActive: data['is_active'] != null
          ? drift.Value(data['is_active'] as bool)
          : const drift.Value(true),
    );

    final id = await _database.insertTindakan(companion);
    return getTindakanById(id);
  }

  // Update tindakan
  Future<domain.Tindakan> updateTindakan(
    int id,
    Map<String, dynamic> data,
  ) async {
    final companion = TindakansCompanion(
      kode: data['kode'] != null
          ? drift.Value(data['kode'] as String)
          : const drift.Value.absent(),
      deskripsi: data['deskripsi'] != null
          ? drift.Value(data['deskripsi'] as String)
          : const drift.Value.absent(),
      tarif: data['tarif'] != null
          ? drift.Value(data['tarif'] as String)
          : const drift.Value.absent(),
      isActive: data['is_active'] != null
          ? drift.Value(data['is_active'] as bool)
          : const drift.Value.absent(),
      updatedAt: drift.Value(DateTime.now()),
    );

    await _database.updateTindakan(id, companion);
    return getTindakanById(id);
  }

  // Delete tindakan
  Future<void> deleteTindakan(int id) async {
    await _database.deleteTindakan(id);
  }

  // Upsert tindakan from API (for sync)
  Future<void> upsertTindakan(domain.Tindakan tindakan) async {
    final existing = await _database.getTindakanById(tindakan.id);

    final companion = TindakansCompanion(
      id: drift.Value(tindakan.id),
      kode: drift.Value(tindakan.kode),
      deskripsi: drift.Value(tindakan.deskripsi),
      tarif: drift.Value(tindakan.tarif),
      isActive: drift.Value(tindakan.isActive),
      createdAt: tindakan.createdAt != null
          ? drift.Value(DateTime.parse(tindakan.createdAt!))
          : const drift.Value.absent(),
      updatedAt: tindakan.updatedAt != null
          ? drift.Value(DateTime.parse(tindakan.updatedAt!))
          : drift.Value(DateTime.now()),
    );

    if (existing != null) {
      await _database.updateTindakan(existing.id, companion);
    } else {
      await _database.insertTindakan(companion);
    }
  }

  // Search tindakan locally
  Future<List<domain.Tindakan>> searchTindakan(String query) async {
    final allTindakan = await _database.getAllTindakans();
    final filtered = allTindakan.where((tindakan) {
      return tindakan.kode.toLowerCase().contains(query.toLowerCase()) ||
          tindakan.deskripsi.toLowerCase().contains(query.toLowerCase());
    }).toList();
    return filtered.map(_toDomainTindakan).toList();
  }

  // ==================== REGISTRASI-TINDAKAN ====================

  // Convert Drift RegistrasiTindakan to Domain
  domain.RegistrasiTindakan _toDomainRegistrasiTindakan(
    RegistrasiTindakan driftRT,
  ) {
    return domain.RegistrasiTindakan(
      id: driftRT.id,
      registrasiId: driftRT.registrasiId,
      tindakanId: driftRT.tindakanId,
      jumlah: driftRT.jumlah,
      hargaSatuan: driftRT.hargaSatuan,
      diskon: driftRT.diskon,
      subtotal: driftRT.subtotal,
      petugasNama: driftRT.petugasNama,
      keterangan: driftRT.keterangan,
      kunjunganKe: driftRT.kunjunganKe,
      isFree: driftRT.isFree,
      dokterId: driftRT.dokterId,
      poliId: driftRT.poliId,
      tanggalLayanan: driftRT.tanggalLayanan,
      createdAt: driftRT.createdAt.toIso8601String(),
    );
  }

  // Get registrasi-tindakan by registrasi ID
  Future<List<domain.RegistrasiTindakan>> getRegistrasiTindakanByRegistrasiId(
    int registrasiId,
  ) async {
    final rts = await _database.getRegistrasiTindakansByRegistrasiId(
      registrasiId,
    );
    return rts.map(_toDomainRegistrasiTindakan).toList();
  }

  // Attach tindakan to registrasi
  Future<domain.RegistrasiTindakan> attachTindakanToRegistrasi(
    int registrasiId,
    Map<String, dynamic> data,
  ) async {
    final companion = RegistrasiTindakansCompanion(
      registrasiId: drift.Value(registrasiId),
      tindakanId: drift.Value(data['tindakan_id'] as int),
      jumlah: data['jumlah'] != null
          ? drift.Value(data['jumlah'] as String)
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
      petugasNama: data['petugas_nama'] != null
          ? drift.Value(data['petugas_nama'] as String)
          : const drift.Value.absent(),
      keterangan: data['keterangan'] != null
          ? drift.Value(data['keterangan'] as String)
          : const drift.Value.absent(),
      kunjunganKe: data['kunjungan_ke'] != null
          ? drift.Value(data['kunjungan_ke'] as String)
          : const drift.Value.absent(),
      isFree: data['is_free'] != null
          ? drift.Value(data['is_free'] as String)
          : const drift.Value.absent(),
      dokterId: data['dokter_id'] != null
          ? drift.Value(data['dokter_id'] as String)
          : const drift.Value.absent(),
      poliId: data['poli_id'] != null
          ? drift.Value(data['poli_id'] as String)
          : const drift.Value.absent(),
      tanggalLayanan: data['tanggal_layanan'] != null
          ? drift.Value(data['tanggal_layanan'] as String)
          : const drift.Value.absent(),
      isSynced: const drift.Value(false), // Will sync later
    );

    final id = await _database.insertRegistrasiTindakan(companion);
    final inserted = await _database.getRegistrasiTindakanById(id);
    if (inserted == null) {
      throw Exception('Failed to insert registrasi tindakan');
    }
    return _toDomainRegistrasiTindakan(inserted);
  }

  // Update registrasi-tindakan pivot data
  Future<domain.RegistrasiTindakan> updateRegistrasiTindakan(
    int id,
    Map<String, dynamic> data,
  ) async {
    final companion = RegistrasiTindakansCompanion(
      jumlah: data['jumlah'] != null
          ? drift.Value(data['jumlah'] as String)
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
      petugasNama: data['petugas_nama'] != null
          ? drift.Value(data['petugas_nama'] as String)
          : const drift.Value.absent(),
      keterangan: data['keterangan'] != null
          ? drift.Value(data['keterangan'] as String)
          : const drift.Value.absent(),
      kunjunganKe: data['kunjungan_ke'] != null
          ? drift.Value(data['kunjungan_ke'] as String)
          : const drift.Value.absent(),
      isFree: data['is_free'] != null
          ? drift.Value(data['is_free'] as String)
          : const drift.Value.absent(),
      dokterId: data['dokter_id'] != null
          ? drift.Value(data['dokter_id'] as String)
          : const drift.Value.absent(),
      poliId: data['poli_id'] != null
          ? drift.Value(data['poli_id'] as String)
          : const drift.Value.absent(),
      tanggalLayanan: data['tanggal_layanan'] != null
          ? drift.Value(data['tanggal_layanan'] as String)
          : const drift.Value.absent(),
    );

    await _database.updateRegistrasiTindakan(id, companion);
    final updated = await _database.getRegistrasiTindakanById(id);
    if (updated == null) {
      throw Exception('Failed to update registrasi tindakan');
    }
    return _toDomainRegistrasiTindakan(updated);
  }

  // Detach tindakan from registrasi
  Future<void> detachTindakanFromRegistrasi(int id) async {
    await _database.deleteRegistrasiTindakan(id);
  }

  // Upsert registrasi-tindakan from API (for sync)
  Future<void> upsertRegistrasiTindakan(domain.RegistrasiTindakan rt) async {
    final existing = await _database.getRegistrasiTindakanById(rt.id);

    final companion = RegistrasiTindakansCompanion(
      id: drift.Value(rt.id),
      registrasiId: drift.Value(rt.registrasiId),
      tindakanId: drift.Value(rt.tindakanId),
      jumlah: rt.jumlah != null
          ? drift.Value(rt.jumlah!)
          : const drift.Value.absent(),
      hargaSatuan: rt.hargaSatuan != null
          ? drift.Value(rt.hargaSatuan!)
          : const drift.Value.absent(),
      diskon: rt.diskon != null
          ? drift.Value(rt.diskon!)
          : const drift.Value.absent(),
      subtotal: rt.subtotal != null
          ? drift.Value(rt.subtotal!)
          : const drift.Value.absent(),
      petugasNama: rt.petugasNama != null
          ? drift.Value(rt.petugasNama!)
          : const drift.Value.absent(),
      keterangan: rt.keterangan != null
          ? drift.Value(rt.keterangan!)
          : const drift.Value.absent(),
      kunjunganKe: rt.kunjunganKe != null
          ? drift.Value(rt.kunjunganKe!)
          : const drift.Value.absent(),
      isFree: rt.isFree != null
          ? drift.Value(rt.isFree!)
          : const drift.Value.absent(),
      dokterId: rt.dokterId != null
          ? drift.Value(rt.dokterId!)
          : const drift.Value.absent(),
      poliId: rt.poliId != null
          ? drift.Value(rt.poliId!)
          : const drift.Value.absent(),
      tanggalLayanan: rt.tanggalLayanan != null
          ? drift.Value(rt.tanggalLayanan!)
          : const drift.Value.absent(),
      isSynced: const drift.Value(true), // From API
      serverId: drift.Value(rt.id), // Server ID
      createdAt: rt.createdAt != null
          ? drift.Value(DateTime.parse(rt.createdAt!))
          : drift.Value(DateTime.now()),
    );

    if (existing != null) {
      await _database.updateRegistrasiTindakan(existing.id, companion);
    } else {
      await _database.insertRegistrasiTindakan(companion);
    }
  }
}
