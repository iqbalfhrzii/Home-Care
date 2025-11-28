import 'package:drift/drift.dart';
import 'package:homecare_mobile/features/patients/domain/models/pasien.dart'
    as domain;
import 'package:homecare_mobile/shared/local_db/app_database.dart';

class PasienLocalDataSource {
  final AppDatabase _database;

  PasienLocalDataSource(this._database);

  // Convert Drift Pasien to Domain Pasien
  domain.Pasien _toDomainModel(Pasien driftPasien) {
    return domain.Pasien(
      id: driftPasien.id,
      mrn: driftPasien.mrn,
      nama: driftPasien.nama,
      tanggalLahir: driftPasien.tanggalLahir.toIso8601String(),
      jenisKelamin: driftPasien.jenisKelamin,
      alamat: driftPasien.alamat,
      telepon: driftPasien.telepon,
      createdAt: driftPasien.createdAt.toIso8601String(),
      updatedAt: driftPasien.updatedAt.toIso8601String(),
    );
  }

  // Convert Domain Pasien to Drift Companion (untuk CREATE)
  Future<PasiensCompanion> _toCompanion(Map<String, dynamic> data) async {
    // Generate MRN if not provided
    String mrn = data['mrn'] as String? ?? '';
    if (mrn.isEmpty) {
      final allPatients = await _database.getAllPasiens();
      final nextNumber = allPatients.length + 1;
      mrn = 'RM${nextNumber.toString().padLeft(3, '0')}';
    }

    return PasiensCompanion.insert(
      mrn: mrn,
      nama: data['nama'] ?? '',
      tanggalLahir: DateTime.parse(
        data['tanggal_lahir'] ?? DateTime.now().toIso8601String(),
      ),
      jenisKelamin: data['jenis_kelamin'] ?? 'L',
      alamat: data['alamat'] ?? '',
      telepon: data['telepon'] ?? data['no_telp'] ?? '',
      updatedAt: Value(DateTime.now()),
    );
  }

  Future<List<domain.Pasien>> getAllPasien() async {
    final driftPasiens = await _database.getAllPasiens();
    return driftPasiens.map(_toDomainModel).toList();
  }

  Future<domain.Pasien> getPasienById(int id) async {
    final driftPasien = await _database.getPasienById(id);
    if (driftPasien == null) {
      throw Exception('Pasien dengan ID $id tidak ditemukan');
    }
    return _toDomainModel(driftPasien);
  }

  Future<domain.Pasien> createPasien(Map<String, dynamic> data) async {
    final companion = await _toCompanion(data);
    final id = await _database.insertPasien(companion);
    return getPasienById(id);
  }

  Future<domain.Pasien> updatePasien(int id, Map<String, dynamic> data) async {
    print('🔄 Updating patient ID: $id with data: $data');

    // For update, use Value() for each field
    final companion = PasiensCompanion(
      id: Value(id),
      nama: Value(data['nama'] ?? ''),
      tanggalLahir: Value(
        DateTime.parse(
          data['tanggal_lahir'] ?? DateTime.now().toIso8601String(),
        ),
      ),
      jenisKelamin: Value(data['jenis_kelamin'] ?? 'L'),
      alamat: Value(data['alamat'] ?? ''),
      telepon: Value(data['telepon'] ?? data['no_telp'] ?? ''),
      updatedAt: Value(DateTime.now()),
    );

    final success = await _database.updatePasien(id, companion);
    if (!success) {
      throw Exception('Gagal mengupdate pasien dengan ID $id');
    }

    print('✅ Update successful, fetching updated data...');
    final updated = await getPasienById(id);
    return updated;
  }

  Future<void> deletePasien(int id) async {
    final deleted = await _database.deletePasien(id);
    if (deleted == 0) {
      throw Exception('Gagal menghapus pasien dengan ID $id');
    }
  }

  Future<List<domain.Pasien>> searchPasien(String query) async {
    final driftPasiens = await _database.searchPasiens(query);
    return driftPasiens.map(_toDomainModel).toList();
  }

  // Upsert patient (insert or update) - for API sync
  Future<void> upsertPasien(domain.Pasien pasien) async {
    try {
      final id = pasien.id;

      // Check if exists
      final existing = await _database.getPasienById(id);

      if (existing != null) {
        // Update existing
        final companion = PasiensCompanion(
          id: Value(id),
          mrn: Value(pasien.mrn),
          nama: Value(pasien.nama),
          tanggalLahir: Value(DateTime.parse(pasien.tanggalLahir)),
          jenisKelamin: Value(pasien.jenisKelamin),
          alamat: Value(pasien.alamat),
          telepon: Value(pasien.telepon),
          updatedAt: Value(DateTime.now()),
        );

        await _database.updatePasien(id, companion);
      } else {
        // Insert new
        final companion = PasiensCompanion.insert(
          id: Value(id),
          mrn: pasien.mrn,
          nama: pasien.nama,
          tanggalLahir: DateTime.parse(pasien.tanggalLahir),
          jenisKelamin: pasien.jenisKelamin,
          alamat: pasien.alamat,
          telepon: pasien.telepon,
          createdAt: Value(DateTime.parse(pasien.createdAt)),
          updatedAt: Value(DateTime.parse(pasien.updatedAt)),
        );

        await _database.insertPasien(companion);
      }
    } catch (e) {
      print('❌ Error upserting patient: $e');
      rethrow;
    }
  }
}
