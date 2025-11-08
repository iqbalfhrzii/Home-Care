import 'package:drift/drift.dart';
import 'package:homecare_mobile/shared/local_db/app_database.dart';

class PatientLocalDataSource {
  final AppDatabase db;

  PatientLocalDataSource(this.db);

  Future<List<Pasien>> getAllPatients() async {
    return await db.getAllPasiens();
  }

  Future<int> insertPatient({
    required String noRm,
    required String namaPasien,
    DateTime? tanggalLahir,
    String? alamat,
    String statusRujukan = 'disetujui',
  }) async {
    final companion = PasiensCompanion(
      noRm: Value(noRm),
      namaPasien: Value(namaPasien),
      tanggalLahir: Value(tanggalLahir),
      alamat: Value(alamat),
      statusRujukan: Value(statusRujukan),
    );

    return await db.insertPasien(companion);
  }

  Future<int> updatePatient({
    required int localId,
    String? noRm,
    String? namaPasien,
    DateTime? tanggalLahir,
    String? alamat,
    String? statusRujukan,
  }) async {
    final companion = PasiensCompanion(
      id: Value(localId),
      noRm: noRm == null ? const Value.absent() : Value(noRm),
      namaPasien: namaPasien == null ? const Value.absent() : Value(namaPasien),
      tanggalLahir: tanggalLahir == null
          ? const Value.absent()
          : Value(tanggalLahir),
      alamat: alamat == null ? const Value.absent() : Value(alamat),
      statusRujukan: statusRujukan == null
          ? const Value.absent()
          : Value(statusRujukan),
    );

    return await (db.update(
      db.pasiens,
    )..where((t) => t.id.equals(localId))).write(companion);
  }

  Future<int> deletePatientByLocalId(int localId) async {
    await db.customStatement('DELETE FROM pasiens WHERE id = ?', [localId]);
    return 1;
  }
}
