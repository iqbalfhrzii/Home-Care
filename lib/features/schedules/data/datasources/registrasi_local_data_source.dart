import 'package:drift/drift.dart';
import 'package:homecare_mobile/shared/local_db/app_database.dart';

class RegistrasiLocalDataSource {
  final AppDatabase _database;

  RegistrasiLocalDataSource(this._database);

  // Get all registrasi/kunjungan
  Future<List<Kunjungan>> getAllRegistrasi() async {
    return await _database.getAllKunjungans();
  }

  // Get registrasi by ID
  Future<Kunjungan?> getRegistrasiById(int id) async {
    return await _database.getKunjunganById(id);
  }

  // Get registrasi by pasien ID
  Future<List<Kunjungan>> getRegistrasiByPasienId(int pasienId) async {
    return await _database.getKunjungansByPasienId(pasienId);
  }

  // Get registrasi by status
  Future<List<Kunjungan>> getRegistrasiByStatus(String status) async {
    return await _database.getKunjungansByStatus(status);
  }

  // Create new registrasi
  Future<int> createRegistrasi({
    required String noReg,
    required int pasienId,
    required DateTime tglJamReg,
    String status = 'dalam_proses',
  }) async {
    return await _database.insertKunjungan(
      KunjungansCompanion(
        noKunjungan: Value(noReg),
        pasienId: Value(pasienId),
        tanggalKunjungan: Value(tglJamReg),
        status: Value(status),
        progressStep: const Value(0),
      ),
    );
  }

  // Update registrasi status
  Future<bool> updateRegistrasiStatus(int id, String status) async {
    return await _database.updateKunjungan(
      id,
      KunjungansCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Update progress step
  Future<bool> updateProgressStep(int id, int step) async {
    return await _database.updateKunjungan(
      id,
      KunjungansCompanion(
        progressStep: Value(step),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Complete registrasi (set to selesai)
  Future<bool> completeRegistrasi(int id) async {
    return await _database.updateKunjungan(
      id,
      KunjungansCompanion(
        status: const Value('selesai'),
        progressStep: const Value(3),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
