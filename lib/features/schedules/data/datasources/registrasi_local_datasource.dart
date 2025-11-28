import 'package:drift/drift.dart';
import 'package:homecare_mobile/features/schedules/domain/models/registrasi.dart'
    as domain;
import 'package:homecare_mobile/shared/local_db/app_database.dart';

class RegistrasiLocalDataSource {
  final AppDatabase _database;

  RegistrasiLocalDataSource(this._database);

  // Convert Drift Registrasi to Domain Registrasi
  domain.Registrasi _toDomainModel(Registrasi driftRegistrasi) {
    return domain.Registrasi(
      id: driftRegistrasi.id,
      noReg: driftRegistrasi.noReg,
      noUrut: driftRegistrasi.noUrut,
      pasienId: driftRegistrasi.pasienId,
      tglJamReg: driftRegistrasi.tglJamReg,
      kodePoli: driftRegistrasi.kodePoli,
      dokterId: driftRegistrasi.dokterId,
      jenisKunjungan: driftRegistrasi.jenisKunjungan,
      asalPasien: driftRegistrasi.asalPasien,
      tipePasien: driftRegistrasi.tipePasien,
      pasienBaru: driftRegistrasi.pasienBaru,
      pagiSore: driftRegistrasi.pagiSore,
      isCash: driftRegistrasi.isCash,
      isPribadi: driftRegistrasi.isPribadi,
      eselon: driftRegistrasi.eselon,
      status: driftRegistrasi.status,
      penanggungId: driftRegistrasi.penanggungId,
      penanggungNama: driftRegistrasi.penanggungNama,
      penanggungNoPegawai: driftRegistrasi.penanggungNoPegawai,
      penanggungAlamat: driftRegistrasi.penanggungAlamat,
      penanggungTelepon: driftRegistrasi.penanggungTelepon,
      createdAt: driftRegistrasi.createdAt.toIso8601String(),
      updatedAt: driftRegistrasi.updatedAt.toIso8601String(),
    );
  }

  // Get all registrations
  Future<List<domain.Registrasi>> getAllRegistrasi() async {
    final driftRegistrasis = await _database.getAllRegistrasis();
    return driftRegistrasis.map(_toDomainModel).toList();
  }

  // Get registration by ID
  Future<domain.Registrasi> getRegistrasiById(int id) async {
    final driftRegistrasi = await _database.getRegistrasiById(id);
    if (driftRegistrasi == null) {
      throw Exception('Registrasi dengan ID $id tidak ditemukan');
    }
    return _toDomainModel(driftRegistrasi);
  }

  // Get registrations by patient ID
  Future<List<domain.Registrasi>> getRegistrasiByPasienId(int pasienId) async {
    final driftRegistrasis = await _database.getRegistrasisByPasienId(pasienId);
    return driftRegistrasis.map(_toDomainModel).toList();
  }

  // Create registration
  Future<domain.Registrasi> createRegistrasi(Map<String, dynamic> data) async {
    // Convert boolean to int for SQLite
    final pasienBaruInt =
        (data['pasien_baru'] == true || data['pasien_baru'] == 1) ? 1 : 0;
    final isCashInt = (data['is_cash'] == true || data['is_cash'] == 1) ? 1 : 0;
    final isPribadiInt = (data['is_pribadi'] == true || data['is_pribadi'] == 1)
        ? 1
        : 0;

    // Convert no_urut to string
    final noUrutStr = data['no_urut']?.toString();

    final companion = RegistrasisCompanion.insert(
      noReg: data['no_reg'] ?? '',
      noUrut: Value(noUrutStr),
      pasienId: data['pasien_id'] ?? 0,
      tglJamReg: data['tgl_jam_reg'] ?? DateTime.now().toIso8601String(),
      kodePoli: Value(data['kode_poli']),
      dokterId: Value(data['dokter_id']),
      jenisKunjungan: data['jenis_kunjungan'] ?? 'Kunjungan Pertama',
      asalPasien: Value(data['asal_pasien']),
      tipePasien: data['tipe_pasien'] ?? 'Pasien Umum',
      pasienBaru: Value(pasienBaruInt),
      pagiSore: Value(data['pagi_sore']),
      isCash: Value(isCashInt),
      isPribadi: Value(isPribadiInt),
      eselon: Value(data['eselon']),
      status: Value(data['status']),
      penanggungId: Value(data['penanggung_id']),
      penanggungNama: Value(data['penanggung_nama']),
      penanggungNoPegawai: Value(data['penanggung_no_pegawai']),
      penanggungAlamat: Value(data['penanggung_alamat']),
      penanggungTelepon: Value(data['penanggung_telepon']),
      isSynced: const Value(false), // Will be synced later
      updatedAt: Value(DateTime.now()),
    );

    final id = await _database.insertRegistrasi(companion);
    return getRegistrasiById(id);
  }

  // Update registration
  Future<domain.Registrasi> updateRegistrasi(
    int id,
    Map<String, dynamic> data,
  ) async {
    // Convert boolean to int for SQLite
    final pasienBaruInt =
        (data['pasien_baru'] == true || data['pasien_baru'] == 1) ? 1 : 0;
    final isCashInt = (data['is_cash'] == true || data['is_cash'] == 1) ? 1 : 0;
    final isPribadiInt = (data['is_pribadi'] == true || data['is_pribadi'] == 1)
        ? 1
        : 0;

    // Convert no_urut to string
    final noUrutStr = data['no_urut']?.toString();

    final companion = RegistrasisCompanion(
      id: Value(id),
      noReg: Value(data['no_reg'] ?? ''),
      noUrut: Value(noUrutStr),
      pasienId: Value(data['pasien_id'] ?? 0),
      tglJamReg: Value(data['tgl_jam_reg'] ?? DateTime.now().toIso8601String()),
      kodePoli: Value(data['kode_poli']),
      dokterId: Value(data['dokter_id']),
      jenisKunjungan: Value(data['jenis_kunjungan'] ?? 'Kunjungan Pertama'),
      asalPasien: Value(data['asal_pasien']),
      tipePasien: Value(data['tipe_pasien'] ?? 'Pasien Umum'),
      pasienBaru: Value(pasienBaruInt),
      pagiSore: Value(data['pagi_sore']),
      isCash: Value(isCashInt),
      isPribadi: Value(isPribadiInt),
      eselon: Value(data['eselon']),
      status: Value(data['status']),
      penanggungId: Value(data['penanggung_id']),
      penanggungNama: Value(data['penanggung_nama']),
      penanggungNoPegawai: Value(data['penanggung_no_pegawai']),
      penanggungAlamat: Value(data['penanggung_alamat']),
      penanggungTelepon: Value(data['penanggung_telepon']),
      updatedAt: Value(DateTime.now()),
    );

    final success = await _database.updateRegistrasi(id, companion);
    if (!success) {
      throw Exception('Gagal mengupdate registrasi dengan ID $id');
    }

    return getRegistrasiById(id);
  }

  // Delete registration
  Future<void> deleteRegistrasi(int id) async {
    final deleted = await _database.deleteRegistrasi(id);
    if (deleted == 0) {
      throw Exception('Gagal menghapus registrasi dengan ID $id');
    }
  }

  // Upsert registration (insert or update) - for API sync
  Future<void> upsertRegistrasi(domain.Registrasi registrasi) async {
    try {
      final existing = await _database.getRegistrasiById(registrasi.id);

      if (existing != null) {
        // Update existing
        final companion = RegistrasisCompanion(
          id: Value(registrasi.id),
          noReg: Value(registrasi.noReg),
          noUrut: Value(registrasi.noUrut),
          pasienId: Value(registrasi.pasienId),
          tglJamReg: Value(registrasi.tglJamReg),
          kodePoli: Value(registrasi.kodePoli),
          dokterId: Value(registrasi.dokterId),
          jenisKunjungan: Value(registrasi.jenisKunjungan),
          asalPasien: Value(registrasi.asalPasien),
          tipePasien: Value(registrasi.tipePasien),
          pasienBaru: Value(registrasi.pasienBaru),
          pagiSore: Value(registrasi.pagiSore),
          isCash: Value(registrasi.isCash),
          isPribadi: Value(registrasi.isPribadi),
          eselon: Value(registrasi.eselon),
          status: Value(registrasi.status),
          penanggungId: Value(registrasi.penanggungId),
          penanggungNama: Value(registrasi.penanggungNama),
          penanggungNoPegawai: Value(registrasi.penanggungNoPegawai),
          penanggungAlamat: Value(registrasi.penanggungAlamat),
          penanggungTelepon: Value(registrasi.penanggungTelepon),
          isSynced: const Value(true), // Mark as synced from API
          serverId: Value(registrasi.id),
          updatedAt: Value(DateTime.now()),
        );

        await _database.updateRegistrasi(registrasi.id, companion);
      } else {
        // Insert new
        final companion = RegistrasisCompanion.insert(
          id: Value(registrasi.id),
          noReg: registrasi.noReg,
          noUrut: Value(registrasi.noUrut),
          pasienId: registrasi.pasienId,
          tglJamReg: registrasi.tglJamReg,
          kodePoli: Value(registrasi.kodePoli),
          dokterId: Value(registrasi.dokterId),
          jenisKunjungan: registrasi.jenisKunjungan,
          asalPasien: Value(registrasi.asalPasien),
          tipePasien: registrasi.tipePasien,
          pasienBaru: Value(registrasi.pasienBaru),
          pagiSore: Value(registrasi.pagiSore),
          isCash: Value(registrasi.isCash),
          isPribadi: Value(registrasi.isPribadi),
          eselon: Value(registrasi.eselon),
          status: Value(registrasi.status),
          penanggungId: Value(registrasi.penanggungId),
          penanggungNama: Value(registrasi.penanggungNama),
          penanggungNoPegawai: Value(registrasi.penanggungNoPegawai),
          penanggungAlamat: Value(registrasi.penanggungAlamat),
          penanggungTelepon: Value(registrasi.penanggungTelepon),
          isSynced: const Value(true), // From API
          serverId: Value(registrasi.id),
          createdAt: Value(
            registrasi.createdAt != null
                ? DateTime.parse(registrasi.createdAt!)
                : DateTime.now(),
          ),
          updatedAt: Value(
            registrasi.updatedAt != null
                ? DateTime.parse(registrasi.updatedAt!)
                : DateTime.now(),
          ),
        );

        await _database.insertRegistrasi(companion);
      }
    } catch (e) {
      print('❌ Error upserting registrasi: $e');
      rethrow;
    }
  }
}
