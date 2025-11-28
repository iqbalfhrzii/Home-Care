import 'package:drift/drift.dart';
import 'package:homecare_mobile/shared/local_db/app_database.dart';

class DiagnosaLocalDataSource {
  final AppDatabase _database;

  DiagnosaLocalDataSource(this._database);

  // Get all diagnosa for a registrasi
  Future<List<Diagnosa>> getDiagnosaByRegistrasiId(int registrasiId) async {
    return await _database.getDiagnosasByKunjunganId(registrasiId);
  }

  // Get primary diagnosa
  Future<Diagnosa?> getPrimaryDiagnosa(int registrasiId) async {
    return await _database.getPrimaryDiagnosa(registrasiId);
  }

  // Attach ICD to registrasi
  Future<int> attachIcd({
    required int registrasiId,
    required String kodeIcd,
    required String namaIcd,
    bool isPrimary = false,
  }) async {
    // If this is primary, unset other primary diagnoses first
    if (isPrimary) {
      final existing = await getDiagnosaByRegistrasiId(registrasiId);
      for (final diag in existing.where((d) => d.isPrimary)) {
        await _database.delete(_database.diagnosas).delete(
              (_database.diagnosas as dynamic)..where((d) => d.id.equals(diag.id)),
            );
      }
    }

    return await _database.insertDiagnosa(
      DiagnosasCompanion(
        kunjunganId: Value(registrasiId),
        kodeIcd: Value(kodeIcd),
        namaIcd: Value(namaIcd),
        isPrimary: Value(isPrimary),
      ),
    );
  }

  // Remove ICD from registrasi
  Future<bool> detachIcd(int diagnosaId) async {
    return await _database.deleteDiagnosa(diagnosaId);
  }

  // Update primary status
  Future<bool> setPrimaryDiagnosa(int registrasiId, int diagnosaId) async {
    // First, unset all primary diagnoses for this registrasi
    final allDiagnosa = await getDiagnosaByRegistrasiId(registrasiId);
    
    for (final diag in allDiagnosa) {
      if (diag.id == diagnosaId) {
        // Set this as primary
        await _database.delete(_database.diagnosas).delete(
              (_database.diagnosas as dynamic)..where((d) => d.id.equals(diag.id)),
            );
        await _database.insertDiagnosa(
          DiagnosasCompanion(
            kunjunganId: Value(registrasiId),
            kodeIcd: Value(diag.kodeIcd),
            namaIcd: Value(diag.namaIcd),
            isPrimary: const Value(true),
          ),
        );
      } else if (diag.isPrimary) {
        // Unset other primary diagnoses
        await _database.delete(_database.diagnosas).delete(
              (_database.diagnosas as dynamic)..where((d) => d.id.equals(diag.id)),
            );
        await _database.insertDiagnosa(
          DiagnosasCompanion(
            kunjunganId: Value(registrasiId),
            kodeIcd: Value(diag.kodeIcd),
            namaIcd: Value(diag.namaIcd),
            isPrimary: const Value(false),
          ),
        );
      }
    }
    
    return true;
  }

  // Clear all diagnosa for registrasi
  Future<bool> clearDiagnosa(int registrasiId) async {
    final allDiagnosa = await getDiagnosaByRegistrasiId(registrasiId);
    for (final diag in allDiagnosa) {
      await detachIcd(diag.id);
    }
    return true;
  }
}
