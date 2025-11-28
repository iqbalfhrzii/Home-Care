import 'package:drift/drift.dart';
import 'package:homecare_mobile/shared/local_db/app_database.dart';

class AnamnesaLocalDataSource {
  final AppDatabase _database;

  AnamnesaLocalDataSource(this._database);

  // Get anamnesa by kunjungan/registrasi ID
  Future<Anamnesa?> getAnamnesaByRegistrasiId(int registrasiId) async {
    return await _database.getAnamnesaByKunjunganId(registrasiId);
  }

  // Create or update anamnesa
  Future<int> saveAnamnesa({
    required int registrasiId,
    required String keluhan,
    required String riwayatPenyakitSekarang,
    String? riwayatPenyakitDahulu,
    String? riwayatPenyakitKeluarga,
    String? riwayatAlergi,
    String? tekananDarah,
    int? nadi,
    double? suhuTubuh,
    int? pernapasan,
    String? diagnosis,
    String? rencanaTerapi,
    String? jenisPerawatan,
    String? catatan,
  }) async {
    // Check if anamnesa already exists
    final existing = await getAnamnesaByRegistrasiId(registrasiId);

    if (existing != null) {
      // Update existing
      await _database.updateAnamnesa(
        existing.id,
        AnamnesasCompanion(
          keluhanUtama: Value(keluhan),
          riwayatPenyakitSekarang: Value(riwayatPenyakitSekarang),
          riwayatPenyakitDahulu: Value(riwayatPenyakitDahulu),
          riwayatPenyakitKeluarga: Value(riwayatPenyakitKeluarga),
          riwayatAlergi: Value(riwayatAlergi),
          tekananDarah: Value(tekananDarah),
          nadi: Value(nadi),
          suhuTubuh: Value(suhuTubuh),
          pernapasan: Value(pernapasan),
          catatan: Value(catatan),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return existing.id;
    } else {
      // Insert new
      return await _database.insertAnamnesa(
        AnamnesasCompanion(
          kunjunganId: Value(registrasiId),
          keluhanUtama: Value(keluhan),
          riwayatPenyakitSekarang: Value(riwayatPenyakitSekarang),
          riwayatPenyakitDahulu: Value(riwayatPenyakitDahulu),
          riwayatPenyakitKeluarga: Value(riwayatPenyakitKeluarga),
          riwayatAlergi: Value(riwayatAlergi),
          tekananDarah: Value(tekananDarah),
          nadi: Value(nadi),
          suhuTubuh: Value(suhuTubuh),
          pernapasan: Value(pernapasan),
          catatan: Value(catatan),
        ),
      );
    }
  }

  // Delete anamnesa
  Future<bool> deleteAnamnesa(int id) async {
    final deleted = await _database.delete(_database.anamnesas).delete(
          (_database.anamnesas as dynamic)..where((a) => a.id.equals(id)),
        );
    return deleted > 0;
  }
}
