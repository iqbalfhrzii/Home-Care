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
      id: driftPasien.id.toString(),
      noRm: driftPasien.noRm,
      nama: driftPasien.nama,
      nik: driftPasien.nik,
      noBpjs: driftPasien.noBpjs,
      tempatLahir: driftPasien.tempatLahir,
      tanggalLahir: driftPasien.tanggalLahir.toIso8601String(),
      jenisKelamin: driftPasien.jenisKelamin,
      golonganDarah: driftPasien.golonganDarah,
      alamat: driftPasien.alamat,
      noTelp: driftPasien.noTelp,
      isRegistered: driftPasien.isRegistered,
      createdAt: driftPasien.createdAt.toIso8601String(),
      updatedAt: driftPasien.updatedAt.toIso8601String(),
    );
  }

  // Convert Domain Pasien to Drift Companion (untuk CREATE)
  Future<PasiensCompanion> _toCompanion(Map<String, dynamic> data) async {
    // Generate noRm if not provided
    String noRm = data['no_rm'] as String? ?? '';
    if (noRm.isEmpty) {
      final allPatients = await _database.getAllPasiens();
      final nextNumber = allPatients.length + 1;
      noRm = 'RM${nextNumber.toString().padLeft(3, '0')}';
    }

    return PasiensCompanion.insert(
      noRm: noRm,
      nama: data['nama'] ?? '',
      tempatLahir: data['tempat_lahir'] ?? '',
      tanggalLahir: DateTime.parse(
        data['tanggal_lahir'] ?? DateTime.now().toIso8601String(),
      ),
      jenisKelamin: data['jenis_kelamin'] ?? 'L',
      alamat: data['alamat'] ?? '',
      noTelp: data['no_telp'] ?? '',
      nik: Value(data['nik']),
      noBpjs: Value(data['no_bpjs']),
      golonganDarah: Value(data['golongan_darah']),
      isRegistered: Value(data['is_registered'] ?? false),
      updatedAt: Value(DateTime.now()),
    );
  }

  Future<List<domain.Pasien>> getAllPasien() async {
    final driftPasiens = await _database.getAllPasiens();
    return driftPasiens.map(_toDomainModel).toList();
  }

  Future<domain.Pasien> getPasienById(String id) async {
    final driftPasien = await _database.getPasienById(int.parse(id));
    if (driftPasien == null) {
      throw Exception('Pasien dengan ID $id tidak ditemukan');
    }
    return _toDomainModel(driftPasien);
  }

  Future<domain.Pasien> createPasien(Map<String, dynamic> data) async {
    final companion = await _toCompanion(data);
    final id = await _database.insertPasien(companion);
    return getPasienById(id.toString());
  }

  Future<domain.Pasien> updatePasien(
    String id,
    Map<String, dynamic> data,
  ) async {
    print('🔄 Updating patient ID: $id with data: $data');

    // For update, use Value() for each field
    final companion = PasiensCompanion(
      id: Value(int.parse(id)),
      nama: Value(data['nama'] ?? ''),
      nik: Value(data['nik']),
      noBpjs: Value(data['no_bpjs']),
      tempatLahir: Value(data['tempat_lahir'] ?? ''),
      tanggalLahir: Value(
        DateTime.parse(
          data['tanggal_lahir'] ?? DateTime.now().toIso8601String(),
        ),
      ),
      jenisKelamin: Value(data['jenis_kelamin'] ?? 'L'),
      golonganDarah: Value(data['golongan_darah']),
      alamat: Value(data['alamat'] ?? ''),
      noTelp: Value(data['no_telp'] ?? ''),
      updatedAt: Value(DateTime.now()),
    );

    final success = await _database.updatePasien(int.parse(id), companion);
    if (!success) {
      throw Exception('Gagal mengupdate pasien dengan ID $id');
    }

    print('✅ Update successful, fetching updated data...');
    final updated = await getPasienById(id);
    print('✅ Updated patient data: ${updated.golonganDarah}');
    return updated;
  }

  Future<void> deletePasien(String id) async {
    final deleted = await _database.deletePasien(int.parse(id));
    if (deleted == 0) {
      throw Exception('Gagal menghapus pasien dengan ID $id');
    }
  }

  Future<void> markAsRegistered(String id) async {
    print('🏥 Marking patient ID: $id as registered');

    final companion = PasiensCompanion(
      id: Value(int.parse(id)),
      isRegistered: Value(true),
      updatedAt: Value(DateTime.now()),
    );

    final success = await _database.updatePasien(int.parse(id), companion);
    if (!success) {
      throw Exception('Gagal update status registrasi pasien ID $id');
    }

    print('✅ Patient marked as registered successfully');
  }

  Future<List<domain.Pasien>> searchPasien(String query) async {
    final driftPasiens = await _database.searchPasiens(query);
    return driftPasiens.map(_toDomainModel).toList();
  }
}
