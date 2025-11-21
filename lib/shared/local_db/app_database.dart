import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class Pasiens extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get noRm => text().withLength(min: 1, max: 50)();
  TextColumn get nama => text()();
  TextColumn get nik => text().nullable().withLength(max: 16)();
  TextColumn get noBpjs => text().nullable().withLength(max: 13)();
  TextColumn get tempatLahir => text()();
  DateTimeColumn get tanggalLahir => dateTime()();
  TextColumn get jenisKelamin => text().withLength(min: 1, max: 1)(); // L/P
  TextColumn get golonganDarah => text().nullable().withLength(max: 3)();
  TextColumn get alamat => text()();
  TextColumn get noTelp => text().withLength(min: 1, max: 20)();
  BoolColumn get isRegistered =>
      boolean().withDefault(const Constant(false))(); // Status registrasi
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Registrasi - Registration records with schedule and guarantor info
class Registrasis extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get noReg => text().withLength(min: 1, max: 50)();
  IntColumn get pasienId => integer().references(Pasiens, #id)();
  DateTimeColumn get tglJamReg => dateTime()(); // Registration date/time
  DateTimeColumn get tanggalKunjungan => dateTime()(); // Scheduled visit date
  TextColumn get jamKunjungan =>
      text().withLength(min: 5, max: 5)(); // HH:mm format
  TextColumn get jenisKunjungan =>
      text()(); // Kunjungan Pertama / Kunjungan Ulang
  TextColumn get tipePasien => text()(); // Pasien Umum / BPJS / Asuransi
  TextColumn get penanggungNama => text()();
  TextColumn get penanggungNoPegawai => text().nullable()();
  TextColumn get penanggungAlamat => text()();
  TextColumn get penanggungTelepon => text()();
  TextColumn get penanggungId => text().nullable()();
  TextColumn get eselon => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Kunjungan - Visit records
class Kunjungans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get noKunjungan => text().withLength(min: 1, max: 50)();
  IntColumn get registrasiId =>
      integer().references(Registrasis, #id)(); // Link to registration
  IntColumn get pasienId => integer().references(Pasiens, #id)();
  DateTimeColumn get tanggalKunjungan => dateTime()();
  TextColumn get jamMulai => text().nullable()(); // Start time HH:mm
  TextColumn get jamSelesai => text().nullable()(); // End time HH:mm
  TextColumn get status => text().withDefault(
    const Constant('terjadwal'),
  )(); // terjadwal, dalam_proses, selesai, dibatalkan
  BoolColumn get anamnesaDone =>
      boolean().withDefault(const Constant(false))(); // Step 1
  BoolColumn get tindakanDone =>
      boolean().withDefault(const Constant(false))(); // Step 2
  BoolColumn get icdDone =>
      boolean().withDefault(const Constant(false))(); // Step 3
  IntColumn get progressStep => integer().withDefault(
    const Constant(0),
  )(); // 0-3 calculated from flags above
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Anamnesa - Medical history for each visit
class Anamnesas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get kunjunganId => integer().references(Kunjungans, #id)();
  TextColumn get keluhanUtama => text()();
  TextColumn get riwayatPenyakitSekarang => text()();
  TextColumn get riwayatPenyakitDahulu => text().nullable()();
  TextColumn get riwayatPenyakitKeluarga => text().nullable()();
  TextColumn get riwayatAlergi => text().nullable()();
  TextColumn get tekananDarah => text().nullable()(); // e.g., "120/80"
  IntColumn get nadi => integer().nullable()(); // beats per minute
  RealColumn get suhuTubuh => real().nullable()(); // Celsius
  IntColumn get pernapasan => integer().nullable()(); // breaths per minute
  TextColumn get catatan => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Diagnosa - ICD codes for each visit
class Diagnosas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get kunjunganId => integer().references(Kunjungans, #id)();
  TextColumn get kodeIcd => text().withLength(min: 1, max: 20)();
  TextColumn get namaIcd => text()();
  BoolColumn get isPrimary =>
      boolean().withDefault(const Constant(false))(); // Primary diagnosis
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Tindakan Kunjungan - Actions/procedures during visit
class TindakanKunjungans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get kunjunganId => integer().references(Kunjungans, #id)();
  TextColumn get kodeTindakan => text().withLength(min: 1, max: 50)();
  TextColumn get namaTindakan => text()();
  IntColumn get jumlah => integer().withDefault(const Constant(1))();
  IntColumn get hargaSatuan => integer()(); // Price per unit
  IntColumn get totalHarga => integer()(); // Quantity * Unit price
  TextColumn get keterangan => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Tagihan - Billing records
class Tagihans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get noInvoice => text().withLength(min: 1, max: 50)();
  IntColumn get kunjunganId => integer().references(Kunjungans, #id)();
  IntColumn get pasienId => integer().references(Pasiens, #id)();
  DateTimeColumn get tanggalTagihan => dateTime()();
  IntColumn get totalBiaya => integer()(); // Total cost
  IntColumn get deposit =>
      integer().withDefault(const Constant(0))(); // Deposit paid
  IntColumn get sisaBiaya => integer()(); // Remaining balance
  TextColumn get statusPembayaran => text().withDefault(
    const Constant('pending'),
  )(); // pending, belum_lunas, lunas
  TextColumn get catatan => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [
    Pasiens,
    Registrasis,
    Kunjungans,
    Anamnesas,
    Diagnosas,
    TindakanKunjungans,
    Tagihans,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6; // Updated Kunjungans with registrasiId and progress flags

  // CRUD operations for Pasiens
  Future<List<Pasien>> getAllPasiens() => select(pasiens).get();

  Future<Pasien?> getPasienById(int id) =>
      (select(pasiens)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<List<Pasien>> searchPasiens(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(pasiens)..where(
          (p) =>
              p.nama.lower().like('%$lowerQuery%') |
              p.noRm.lower().like('%$lowerQuery%') |
              p.noTelp.like('%$lowerQuery%') |
              p.nik.lower().like('%$lowerQuery%') |
              p.noBpjs.lower().like('%$lowerQuery%'),
        ))
        .get();
  }

  // Get pasiens by registration status
  Future<List<Pasien>> getPasiensByRegistrationStatus(bool isRegistered) {
    return (select(
      pasiens,
    )..where((p) => p.isRegistered.equals(isRegistered))).get();
  }

  // Count pasiens by registration status
  Future<int> countPasiensByStatus(bool isRegistered) async {
    final query = selectOnly(pasiens)
      ..addColumns([pasiens.id.count()])
      ..where(pasiens.isRegistered.equals(isRegistered));
    final result = await query.getSingleOrNull();
    return result?.read(pasiens.id.count()) ?? 0;
  }

  Future<int> insertPasien(PasiensCompanion companion) =>
      into(pasiens).insert(companion);

  Future<bool> updatePasien(int id, PasiensCompanion companion) async {
    final updated = await (update(
      pasiens,
    )..where((p) => p.id.equals(id))).write(companion);
    return updated > 0;
  }

  Future<int> deletePasien(int id) =>
      (delete(pasiens)..where((p) => p.id.equals(id))).go();

  // ========== REGISTRASI OPERATIONS ==========
  Future<List<Registrasi>> getAllRegistrasis() => select(registrasis).get();

  Future<Registrasi?> getRegistrasiById(int id) =>
      (select(registrasis)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<List<Registrasi>> getRegistrasiByPasienId(int pasienId) {
    return (select(
      registrasis,
    )..where((r) => r.pasienId.equals(pasienId))).get();
  }

  Future<Registrasi?> getLatestRegistrasiByPasienId(int pasienId) =>
      (select(registrasis)
            ..where((r) => r.pasienId.equals(pasienId))
            ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertRegistrasi(RegistrasisCompanion companion) =>
      into(registrasis).insert(companion);

  Future<bool> updateRegistrasi(int id, RegistrasisCompanion companion) async {
    final updated = await (update(
      registrasis,
    )..where((r) => r.id.equals(id))).write(companion);
    return updated > 0;
  }

  Future<int> deleteRegistrasi(int id) =>
      (delete(registrasis)..where((r) => r.id.equals(id))).go();

  // ========== KUNJUNGAN OPERATIONS ==========
  Future<List<Kunjungan>> getAllKunjungans() => select(kunjungans).get();

  Future<Kunjungan?> getKunjunganById(int id) =>
      (select(kunjungans)..where((k) => k.id.equals(id))).getSingleOrNull();

  Future<List<Kunjungan>> getKunjungansByPasienId(int pasienId) {
    return (select(
      kunjungans,
    )..where((k) => k.pasienId.equals(pasienId))).get();
  }

  Future<List<Kunjungan>> getKunjungansByStatus(String status) {
    return (select(kunjungans)..where((k) => k.status.equals(status))).get();
  }

  Future<Kunjungan?> getKunjunganByRegistrasiId(int registrasiId) => (select(
    kunjungans,
  )..where((k) => k.registrasiId.equals(registrasiId))).getSingleOrNull();

  Future<List<Kunjungan>> getTodayKunjungans() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return (select(kunjungans)..where(
          (k) => k.tanggalKunjungan.isBetweenValues(startOfDay, endOfDay),
        ))
        .get();
  }

  Future<int> insertKunjungan(KunjungansCompanion companion) =>
      into(kunjungans).insert(companion);

  Future<bool> updateKunjungan(int id, KunjungansCompanion companion) async {
    final updated = await (update(
      kunjungans,
    )..where((k) => k.id.equals(id))).write(companion);
    return updated > 0;
  }

  Future<bool> updateKunjunganProgress(
    int id, {
    bool? anamnesaDone,
    bool? tindakanDone,
    bool? icdDone,
  }) async {
    // Get current kunjungan data
    final currentKunjungan = await getKunjunganById(id);
    if (currentKunjungan == null) return false;

    // Calculate progress step based on current and new values
    final currentAnamnesaDone = anamnesaDone ?? currentKunjungan.anamnesaDone;
    final currentTindakanDone = tindakanDone ?? currentKunjungan.tindakanDone;
    final currentIcdDone = icdDone ?? currentKunjungan.icdDone;

    int progressStep = 0;
    if (currentAnamnesaDone) progressStep++;
    if (currentTindakanDone) progressStep++;
    if (currentIcdDone) progressStep++;

    final companion = KunjungansCompanion(
      anamnesaDone: anamnesaDone != null
          ? Value(anamnesaDone)
          : const Value.absent(),
      tindakanDone: tindakanDone != null
          ? Value(tindakanDone)
          : const Value.absent(),
      icdDone: icdDone != null ? Value(icdDone) : const Value.absent(),
      progressStep: Value(progressStep),
      updatedAt: Value(DateTime.now()),
    );

    return updateKunjungan(id, companion);
  }

  Future<Anamnesa?> getAnamnesaByKunjunganId(int kunjunganId) => (select(
    anamnesas,
  )..where((a) => a.kunjunganId.equals(kunjunganId))).getSingleOrNull();

  Future<int> insertAnamnesa(AnamnesasCompanion companion) =>
      into(anamnesas).insert(companion);

  Future<bool> updateAnamnesa(int id, AnamnesasCompanion companion) async {
    final updated = await (update(
      anamnesas,
    )..where((a) => a.id.equals(id))).write(companion);
    return updated > 0;
  }

  // ========== DIAGNOSA OPERATIONS ==========
  Future<List<Diagnosa>> getDiagnosasByKunjunganId(int kunjunganId) {
    return (select(
      diagnosas,
    )..where((d) => d.kunjunganId.equals(kunjunganId))).get();
  }

  Future<Diagnosa?> getPrimaryDiagnosa(int kunjunganId) =>
      (select(diagnosas)..where(
            (d) => d.kunjunganId.equals(kunjunganId) & d.isPrimary.equals(true),
          ))
          .getSingleOrNull();

  Future<int> insertDiagnosa(DiagnosasCompanion companion) =>
      into(diagnosas).insert(companion);

  Future<bool> deleteDiagnosa(int id) async {
    final deleted = await (delete(
      diagnosas,
    )..where((d) => d.id.equals(id))).go();
    return deleted > 0;
  }

  // ========== TINDAKAN KUNJUNGAN OPERATIONS ==========
  Future<List<TindakanKunjungan>> getTindakansByKunjunganId(int kunjunganId) {
    return (select(
      tindakanKunjungans,
    )..where((t) => t.kunjunganId.equals(kunjunganId))).get();
  }

  Future<int> insertTindakanKunjungan(TindakanKunjungansCompanion companion) =>
      into(tindakanKunjungans).insert(companion);

  Future<bool> deleteTindakanKunjungan(int id) async {
    final deleted = await (delete(
      tindakanKunjungans,
    )..where((t) => t.id.equals(id))).go();
    return deleted > 0;
  }

  // ========== TAGIHAN OPERATIONS ==========
  Future<List<Tagihan>> getAllTagihans() => select(tagihans).get();

  Future<Tagihan?> getTagihanById(int id) =>
      (select(tagihans)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Tagihan?> getTagihanByKunjunganId(int kunjunganId) => (select(
    tagihans,
  )..where((t) => t.kunjunganId.equals(kunjunganId))).getSingleOrNull();

  Future<List<Tagihan>> getTagihansByStatus(String status) {
    return (select(
      tagihans,
    )..where((t) => t.statusPembayaran.equals(status))).get();
  }

  Future<int> insertTagihan(TagihansCompanion companion) =>
      into(tagihans).insert(companion);

  Future<bool> updateTagihan(int id, TagihansCompanion companion) async {
    final updated = await (update(
      tagihans,
    )..where((t) => t.id.equals(id))).write(companion);
    return updated > 0;
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          // Recreate table with new schema
          await migrator.drop(pasiens);
          await migrator.createAll();
        }
        if (from == 2 && to >= 3) {
          // Add isRegistered column (recreate table untuk simplicity)
          await migrator.drop(pasiens);
          await migrator.createAll();
        }
        if (from == 3 && to >= 4) {
          // Add new tables for kunjungan system
          await migrator.createAll();
        }
        if (from < 6 && to >= 6) {
          // Update Kunjungans table with registrasiId and progress flags
          // Drop and recreate for simplicity in development
          await migrator.drop(kunjungans);
          await migrator.drop(anamnesas);
          await migrator.drop(diagnosas);
          await migrator.drop(tindakanKunjungans);
          await migrator.createTable(kunjungans);
          await migrator.createTable(anamnesas);
          await migrator.createTable(diagnosas);
          await migrator.createTable(tindakanKunjungans);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, 'homecare.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
