import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class Pasiens extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get noRm => text().withLength(min: 1, max: 255)();
  TextColumn get namaPasien => text()();
  DateTimeColumn get tanggalLahir => dateTime().nullable()();
  TextColumn get alamat => text().nullable()();
  TextColumn get statusRujukan =>
      text().withDefault(const Constant('disetujui'))();
}

@DriftDatabase(tables: [Pasiens])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<Pasien>> getAllPasiens() => select(pasiens).get();

  Future<int> insertPasien(PasiensCompanion companion) =>
      into(pasiens).insert(companion);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, 'homecare.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
