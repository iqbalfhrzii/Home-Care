import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ========== MASTER DATA TABLES ==========

// Pasiens - Patient master data (sesuai API: pasien)
class Pasiens extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mrn =>
      text().withLength(min: 1, max: 50)(); // Medical Record Number
  TextColumn get nama => text()();
  DateTimeColumn get tanggalLahir => dateTime()();
  TextColumn get jenisKelamin => text().withLength(min: 1, max: 1)(); // L/P
  TextColumn get alamat => text()();
  TextColumn get telepon => text().withLength(min: 1, max: 20)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Dokters - Doctor master data (sesuai API: dokter)
class Dokters extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dokterId =>
      text().withLength(min: 1, max: 50)(); // Kode dokter
  TextColumn get namaDokter => text()();
  TextColumn get bidangKeahlian => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Polis - Poli/clinic master data (sesuai API: poli)
class Polis extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kodePoli => text().withLength(min: 1, max: 50)();
  TextColumn get namaPoli => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Icds - ICD-10 codes master data (sesuai API: icd)
class Icds extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kode => text().withLength(min: 1, max: 20)();
  TextColumn get deskripsi => text()();
  TextColumn get katIcd => text().nullable()(); // Kategori ICD
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Tindakans - Medical procedures/actions master data (sesuai API: tindakan)
class Tindakans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kode => text().withLength(min: 1, max: 50)();
  TextColumn get deskripsi => text()();
  TextColumn get tarif => text()(); // String karena bisa ada format currency
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Users - User accounts (sesuai API: user dalam tagihan)
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  DateTimeColumn get emailVerifiedAt => dateTime().nullable()();
  TextColumn get twoFactorSecret => text().nullable()();
  TextColumn get twoFactorRecoveryCodes => text().nullable()();
  TextColumn get twoFactorConfirmedAt => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// KategoriLayanans - Service category for billing (sesuai API: kategori_layanan)
class KategoriLayanans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kode => text().withLength(min: 1, max: 50)();
  TextColumn get nama => text()();
  IntColumn get urutan => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ========== TRANSACTION TABLES ==========

// Registrasis - Registration records (sesuai API: data root)
class Registrasis extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get noReg => text().withLength(min: 1, max: 50)();
  TextColumn get noUrut => text().nullable()(); // Nomor urut
  IntColumn get pasienId => integer().references(Pasiens, #id)();
  TextColumn get tglJamReg =>
      text()(); // Registration date/time as string (kapan pasien mendaftar)
  TextColumn get tglJamKunjungan =>
      text().nullable()(); // Visit date/time (kapan akan/sudah dikunjungi)
  TextColumn get kodePoli => text().nullable()();
  TextColumn get dokterId => text().nullable()();
  TextColumn get jenisKunjungan =>
      text()(); // Kunjungan Pertama / Kunjungan Ulang
  TextColumn get asalPasien => text().nullable()();
  TextColumn get tipePasien => text()(); // Pasien Umum / BPJS / Asuransi
  IntColumn get pasienBaru =>
      integer().withDefault(const Constant(0))(); // 0 atau 1
  TextColumn get pagiSore => text().nullable()(); // pagi/sore
  IntColumn get isCash =>
      integer().withDefault(const Constant(0))(); // 0 atau 1
  IntColumn get isPribadi =>
      integer().withDefault(const Constant(0))(); // 0 atau 1
  TextColumn get eselon => text().nullable()();
  TextColumn get status => text().nullable()();

  // Penanggung data (embedded dalam registrasi)
  TextColumn get penanggungId => text().nullable()();
  TextColumn get penanggungNama => text().nullable()();
  TextColumn get penanggungNoPegawai => text().nullable()();
  TextColumn get penanggungAlamat => text().nullable()();
  TextColumn get penanggungTelepon => text().nullable()();

  // Offline sync fields
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  IntColumn get serverId => integer().nullable()(); // ID from server after sync

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Anamnesas - Medical assessment (sesuai API: anamnesa)
class Anamnesas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get registrasiId => integer().references(Registrasis, #id)();
  IntColumn get dokterId =>
      integer().nullable()(); // Reference to id in dokters table
  TextColumn get poliId => text().nullable()(); // Kode poli
  TextColumn get tanggal => text().nullable()();

  // Pengkajian Keperawatan - stored as JSON string
  TextColumn get pengkajianKeperawatan => text().nullable()(); // JSON

  // Pengkajian Medis - stored as JSON string
  TextColumn get pengkajianMedis => text().nullable()(); // JSON

  // Khusus Perawat - stored as JSON string
  TextColumn get khususPerawat => text().nullable()(); // JSON

  // Offline sync fields
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  IntColumn get serverId => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// RegistrasiIcds - Junction table for Registrasi-ICD many-to-many relationship
class RegistrasiIcds extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get registrasiId => integer().references(Registrasis, #id)();
  IntColumn get icdId => integer().references(Icds, #id)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  IntColumn get serverId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// RegistrasiTindakans - Junction table for Registrasi-Tindakan with pivot data
class RegistrasiTindakans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get registrasiId => integer().references(Registrasis, #id)();
  IntColumn get tindakanId => integer().references(Tindakans, #id)();

  // Pivot data (sesuai API: pivot dalam tindakan)
  TextColumn get jumlah => text().nullable()();
  TextColumn get hargaSatuan => text().nullable()();
  TextColumn get diskon => text().nullable()();
  TextColumn get subtotal => text().nullable()();
  TextColumn get petugasNama => text().nullable()();
  TextColumn get keterangan => text().nullable()();
  TextColumn get kunjunganKe => text().nullable()();
  TextColumn get isFree => text().nullable()();
  TextColumn get dokterId => text().nullable()();
  TextColumn get poliId => text().nullable()();
  TextColumn get tanggalLayanan => text().nullable()();

  // Offline sync fields
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  IntColumn get serverId => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Tagihans - Billing records (sesuai API: tagihan)
class Tagihans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get registrasiId => integer().references(Registrasis, #id)();
  TextColumn get noInvoice => text().withLength(min: 1, max: 50)();
  TextColumn get tanggalInvoice => text().nullable()();
  TextColumn get totalBiaya => text().nullable()(); // String untuk currency
  TextColumn get deposit => text().nullable()();
  TextColumn get biayaYangHarusDibayar => text().nullable()();
  TextColumn get terbilang => text().nullable()();
  TextColumn get primaryIcd => text().nullable()();
  TextColumn get statusPembayaran =>
      text().withDefault(const Constant('belum_bayar'))(); // belum_bayar, lunas
  TextColumn get dicetakOleh => text().nullable()();
  TextColumn get tanggalCetak => text().nullable()();
  TextColumn get printLocation => text().nullable()();
  TextColumn get serverTime => text().nullable()();
  TextColumn get computerTime => text().nullable()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// TagihanItems - Billing line items (sesuai API: items dalam tagihan)
class TagihanItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tagihanId => integer().references(Tagihans, #id)();
  IntColumn get kategoriLayananId =>
      integer().nullable().references(KategoriLayanans, #id)();
  TextColumn get kodeLayanan => text().nullable()();
  TextColumn get deskripsi => text().nullable()();
  IntColumn get jumlah => integer().withDefault(const Constant(0))();
  TextColumn get hargaSatuan => text().nullable()();
  TextColumn get diskon => text().nullable()();
  TextColumn get subtotal => text().nullable()();
  TextColumn get tanggalLayanan => text().nullable()();
  IntColumn get urutan => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [
    Pasiens,
    Dokters,
    Polis,
    Icds,
    Tindakans,
    Users,
    KategoriLayanans,
    Registrasis,
    Anamnesas,
    RegistrasiIcds,
    RegistrasiTindakans,
    Tagihans,
    TagihanItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 8; // Added offline sync fields

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 8) {
        // Add isSynced and serverId columns to transaction tables
        await m.addColumn(registrasis, registrasis.isSynced);
        await m.addColumn(registrasis, registrasis.serverId);
        await m.addColumn(anamnesas, anamnesas.isSynced);
        await m.addColumn(anamnesas, anamnesas.serverId);
        await m.addColumn(registrasiIcds, registrasiIcds.isSynced);
        await m.addColumn(registrasiIcds, registrasiIcds.serverId);
        await m.addColumn(registrasiTindakans, registrasiTindakans.isSynced);
        await m.addColumn(registrasiTindakans, registrasiTindakans.serverId);
      }
    },
  );

  // ========== PASIEN OPERATIONS ==========
  Future<List<Pasien>> getAllPasiens() => select(pasiens).get();

  Future<Pasien?> getPasienById(int id) =>
      (select(pasiens)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<Pasien?> getPasienByMrn(String mrn) =>
      (select(pasiens)..where((p) => p.mrn.equals(mrn))).getSingleOrNull();

  Future<List<Pasien>> searchPasiens(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(pasiens)..where(
          (p) =>
              p.nama.lower().like('%$lowerQuery%') |
              p.mrn.lower().like('%$lowerQuery%') |
              p.telepon.like('%$lowerQuery%'),
        ))
        .get();
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

  // ========== DOKTER OPERATIONS ==========
  Future<List<Dokter>> getAllDokters() => select(dokters).get();

  Future<Dokter?> getDokterById(int id) =>
      (select(dokters)..where((d) => d.id.equals(id))).getSingleOrNull();

  Future<Dokter?> getDokterByDokterId(String dokterId) => (select(
    dokters,
  )..where((d) => d.dokterId.equals(dokterId))).getSingleOrNull();

  Future<List<Dokter>> getActiveDokters() =>
      (select(dokters)..where((d) => d.isActive.equals(true))).get();

  Future<int> insertDokter(DoktersCompanion companion) =>
      into(dokters).insert(companion);

  Future<bool> updateDokter(int id, DoktersCompanion companion) async {
    final updated = await (update(
      dokters,
    )..where((d) => d.id.equals(id))).write(companion);
    return updated > 0;
  }

  // ========== POLI OPERATIONS ==========
  Future<List<Poli>> getAllPolis() => select(polis).get();

  Future<Poli?> getPoliById(int id) =>
      (select(polis)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<Poli?> getPoliByKode(String kodePoli) => (select(
    polis,
  )..where((p) => p.kodePoli.equals(kodePoli))).getSingleOrNull();

  Future<int> insertPoli(PolisCompanion companion) =>
      into(polis).insert(companion);

  Future<bool> updatePoli(int id, PolisCompanion companion) async {
    final updated = await (update(
      polis,
    )..where((p) => p.id.equals(id))).write(companion);
    return updated > 0;
  }

  // ========== ICD OPERATIONS ==========
  Future<List<Icd>> getAllIcds() => select(icds).get();

  Future<Icd?> getIcdById(int id) =>
      (select(icds)..where((i) => i.id.equals(id))).getSingleOrNull();

  Future<Icd?> getIcdByKode(String kode) =>
      (select(icds)..where((i) => i.kode.equals(kode))).getSingleOrNull();

  Future<List<Icd>> getActiveIcds() =>
      (select(icds)..where((i) => i.isActive.equals(true))).get();

  Future<List<Icd>> searchIcds(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(icds)..where(
          (i) =>
              i.kode.lower().like('%$lowerQuery%') |
              i.deskripsi.lower().like('%$lowerQuery%'),
        ))
        .get();
  }

  Future<int> insertIcd(IcdsCompanion companion) =>
      into(icds).insert(companion);

  Future<bool> updateIcd(int id, IcdsCompanion companion) async {
    final updated = await (update(
      icds,
    )..where((i) => i.id.equals(id))).write(companion);
    return updated > 0;
  }

  Future<int> deleteAllIcds() => delete(icds).go();

  // ========== TINDAKAN OPERATIONS ==========
  Future<List<Tindakan>> getAllTindakans() => select(tindakans).get();

  Future<Tindakan?> getTindakanById(int id) =>
      (select(tindakans)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Tindakan?> getTindakanByKode(String kode) =>
      (select(tindakans)..where((t) => t.kode.equals(kode))).getSingleOrNull();

  Future<List<Tindakan>> getActiveTindakans() =>
      (select(tindakans)..where((t) => t.isActive.equals(true))).get();

  Future<List<Tindakan>> searchTindakans(String query) {
    final lowerQuery = query.toLowerCase();
    return (select(tindakans)..where(
          (t) =>
              t.kode.lower().like('%$lowerQuery%') |
              t.deskripsi.lower().like('%$lowerQuery%'),
        ))
        .get();
  }

  Future<int> insertTindakan(TindakansCompanion companion) =>
      into(tindakans).insert(companion);

  Future<bool> updateTindakan(int id, TindakansCompanion companion) async {
    final updated = await (update(
      tindakans,
    )..where((t) => t.id.equals(id))).write(companion);
    return updated > 0;
  }

  Future<int> deleteTindakan(int id) =>
      (delete(tindakans)..where((t) => t.id.equals(id))).go();

  // ========== USER OPERATIONS ==========
  Future<List<User>> getAllUsers() => select(users).get();

  Future<User?> getUserById(int id) =>
      (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();

  Future<User?> getUserByEmail(String email) =>
      (select(users)..where((u) => u.email.equals(email))).getSingleOrNull();

  Future<int> insertUser(UsersCompanion companion) =>
      into(users).insert(companion);

  Future<bool> updateUser(int id, UsersCompanion companion) async {
    final updated = await (update(
      users,
    )..where((u) => u.id.equals(id))).write(companion);
    return updated > 0;
  }

  // ========== KATEGORI LAYANAN OPERATIONS ==========
  Future<List<KategoriLayanan>> getAllKategoriLayanans() =>
      select(kategoriLayanans).get();

  Future<KategoriLayanan?> getKategoriLayananById(int id) => (select(
    kategoriLayanans,
  )..where((k) => k.id.equals(id))).getSingleOrNull();

  Future<int> insertKategoriLayanan(KategoriLayanansCompanion companion) =>
      into(kategoriLayanans).insert(companion);

  // ========== REGISTRASI OPERATIONS ==========
  Future<List<Registrasi>> getAllRegistrasis() => select(registrasis).get();

  Future<Registrasi?> getRegistrasiById(int id) =>
      (select(registrasis)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<Registrasi?> getRegistrasiByNoReg(String noReg) => (select(
    registrasis,
  )..where((r) => r.noReg.equals(noReg))).getSingleOrNull();

  Future<List<Registrasi>> getRegistrasiByPasienId(int pasienId) {
    return (select(
      registrasis,
    )..where((r) => r.pasienId.equals(pasienId))).get();
  }

  // Alias for consistency with naming convention
  Future<List<Registrasi>> getRegistrasisByPasienId(int pasienId) =>
      getRegistrasiByPasienId(pasienId);

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

  // ========== ANAMNESA OPERATIONS ==========
  Future<List<Anamnesa>> getAllAnamnesas() => select(anamnesas).get();

  Future<Anamnesa?> getAnamnesaById(int id) =>
      (select(anamnesas)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<Anamnesa?> getAnamnesaByRegistrasiId(int registrasiId) => (select(
    anamnesas,
  )..where((a) => a.registrasiId.equals(registrasiId))).getSingleOrNull();

  Future<List<Anamnesa>> getAnamnesasByRegistrasiId(int registrasiId) =>
      (select(
        anamnesas,
      )..where((a) => a.registrasiId.equals(registrasiId))).get();

  Future<int> insertAnamnesa(AnamnesasCompanion companion) =>
      into(anamnesas).insert(companion);

  Future<bool> updateAnamnesa(int id, AnamnesasCompanion companion) async {
    final updated = await (update(
      anamnesas,
    )..where((a) => a.id.equals(id))).write(companion);
    return updated > 0;
  }

  Future<int> deleteAnamnesa(int id) =>
      (delete(anamnesas)..where((a) => a.id.equals(id))).go();

  // ========== REGISTRASI-ICD OPERATIONS ==========
  Future<List<RegistrasiIcd>> getRegistrasiIcdsByRegistrasiId(
    int registrasiId,
  ) {
    return (select(
      registrasiIcds,
    )..where((ri) => ri.registrasiId.equals(registrasiId))).get();
  }

  Future<int> insertRegistrasiIcd(RegistrasiIcdsCompanion companion) =>
      into(registrasiIcds).insert(companion);

  Future<int> deleteRegistrasiIcd(int id) =>
      (delete(registrasiIcds)..where((ri) => ri.id.equals(id))).go();

  Future<int> deleteRegistrasiIcdsByRegistrasiId(int registrasiId) => (delete(
    registrasiIcds,
  )..where((ri) => ri.registrasiId.equals(registrasiId))).go();

  // ========== REGISTRASI-TINDAKAN OPERATIONS ==========
  Future<List<RegistrasiTindakan>> getRegistrasiTindakansByRegistrasiId(
    int registrasiId,
  ) {
    return (select(
      registrasiTindakans,
    )..where((rt) => rt.registrasiId.equals(registrasiId))).get();
  }

  Future<RegistrasiTindakan?> getRegistrasiTindakanById(int id) => (select(
    registrasiTindakans,
  )..where((rt) => rt.id.equals(id))).getSingleOrNull();

  Future<int> insertRegistrasiTindakan(
    RegistrasiTindakansCompanion companion,
  ) => into(registrasiTindakans).insert(companion);

  Future<bool> updateRegistrasiTindakan(
    int id,
    RegistrasiTindakansCompanion companion,
  ) async {
    final updated = await (update(
      registrasiTindakans,
    )..where((rt) => rt.id.equals(id))).write(companion);
    return updated > 0;
  }

  Future<int> deleteRegistrasiTindakan(int id) =>
      (delete(registrasiTindakans)..where((rt) => rt.id.equals(id))).go();

  Future<int> deleteRegistrasiTindakansByRegistrasiId(int registrasiId) =>
      (delete(
        registrasiTindakans,
      )..where((rt) => rt.registrasiId.equals(registrasiId))).go();

  // ========== TAGIHAN OPERATIONS ==========
  Future<List<Tagihan>> getAllTagihans() => select(tagihans).get();

  Future<Tagihan?> getTagihanById(int id) =>
      (select(tagihans)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Tagihan?> getTagihanByRegistrasiId(int registrasiId) => (select(
    tagihans,
  )..where((t) => t.registrasiId.equals(registrasiId))).getSingleOrNull();

  Future<List<Tagihan>> getTagihansByRegistrasiId(int registrasiId) => (select(
    tagihans,
  )..where((t) => t.registrasiId.equals(registrasiId))).get();

  Future<Tagihan?> getTagihanByNoInvoice(String noInvoice) => (select(
    tagihans,
  )..where((t) => t.noInvoice.equals(noInvoice))).getSingleOrNull();

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

  Future<int> deleteTagihan(int id) =>
      (delete(tagihans)..where((t) => t.id.equals(id))).go();

  // ========== TAGIHAN ITEM OPERATIONS ==========
  Future<List<TagihanItem>> getTagihanItemsByTagihanId(int tagihanId) {
    return (select(tagihanItems)
          ..where((ti) => ti.tagihanId.equals(tagihanId))
          ..orderBy([(ti) => OrderingTerm.asc(ti.urutan)]))
        .get();
  }

  Future<TagihanItem?> getTagihanItemById(int id) =>
      (select(tagihanItems)..where((ti) => ti.id.equals(id))).getSingleOrNull();

  Future<int> insertTagihanItem(TagihanItemsCompanion companion) =>
      into(tagihanItems).insert(companion);

  Future<bool> updateTagihanItem(
    int id,
    TagihanItemsCompanion companion,
  ) async {
    final updated = await (update(
      tagihanItems,
    )..where((ti) => ti.id.equals(id))).write(companion);
    return updated > 0;
  }

  Future<int> deleteTagihanItem(int id) =>
      (delete(tagihanItems)..where((ti) => ti.id.equals(id))).go();

  Future<int> deleteTagihanItemsByTagihanId(int tagihanId) => (delete(
    tagihanItems,
  )..where((ti) => ti.tagihanId.equals(tagihanId))).go();

  // ========== OFFLINE SYNC OPERATIONS ==========

  // Get all registrations that haven't been synced
  Future<List<Registrasi>> getUnsyncedRegistrasis() =>
      (select(registrasis)..where((r) => r.isSynced.equals(false))).get();

  // Get all anamnesas that haven't been synced
  Future<List<Anamnesa>> getUnsyncedAnamnesas() =>
      (select(anamnesas)..where((a) => a.isSynced.equals(false))).get();

  // Get all registrasi ICDs that haven't been synced
  Future<List<RegistrasiIcd>> getUnsyncedRegistrasiIcds() =>
      (select(registrasiIcds)..where((ri) => ri.isSynced.equals(false))).get();

  // Get all registrasi tindakans that haven't been synced
  Future<List<RegistrasiTindakan>> getUnsyncedRegistrasiTindakans() => (select(
    registrasiTindakans,
  )..where((rt) => rt.isSynced.equals(false))).get();

  // Mark registrasi as synced
  Future<bool> markRegistrasiSynced(int localId, int serverId) async {
    final updated =
        await (update(registrasis)..where((r) => r.id.equals(localId))).write(
          RegistrasisCompanion(
            isSynced: const Value(true),
            serverId: Value(serverId),
          ),
        );
    return updated > 0;
  }

  // Mark anamnesa as synced
  Future<bool> markAnamnesaSynced(int localId, int serverId) async {
    final updated =
        await (update(anamnesas)..where((a) => a.id.equals(localId))).write(
          AnamnesasCompanion(
            isSynced: const Value(true),
            serverId: Value(serverId),
          ),
        );
    return updated > 0;
  }

  // Mark registrasi ICD as synced
  Future<bool> markRegistrasiIcdSynced(int localId, int serverId) async {
    final updated =
        await (update(
          registrasiIcds,
        )..where((ri) => ri.id.equals(localId))).write(
          RegistrasiIcdsCompanion(
            isSynced: const Value(true),
            serverId: Value(serverId),
          ),
        );
    return updated > 0;
  }

  // Mark registrasi tindakan as synced
  Future<bool> markRegistrasiTindakanSynced(int localId, int serverId) async {
    final updated =
        await (update(
          registrasiTindakans,
        )..where((rt) => rt.id.equals(localId))).write(
          RegistrasiTindakansCompanion(
            isSynced: const Value(true),
            serverId: Value(serverId),
          ),
        );
    return updated > 0;
  }

  // Get count of unsynced items
  Future<int> getUnsyncedCount() async {
    final registrasisCount =
        await (select(registrasis)..where((r) => r.isSynced.equals(false)))
            .get()
            .then((list) => list.length);

    final anamnesasCount =
        await (select(anamnesas)..where((a) => a.isSynced.equals(false)))
            .get()
            .then((list) => list.length);

    final icdsCount =
        await (select(registrasiIcds)..where((ri) => ri.isSynced.equals(false)))
            .get()
            .then((list) => list.length);

    final tindakansCount =
        await (select(registrasiTindakans)
              ..where((rt) => rt.isSynced.equals(false)))
            .get()
            .then((list) => list.length);

    return registrasisCount + anamnesasCount + icdsCount + tindakansCount;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, 'homecare.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
