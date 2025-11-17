import 'package:drift/drift.dart';
import 'package:homecare_mobile/shared/local_db/app_database.dart';

class DatabaseSeeder {
  final AppDatabase database;

  DatabaseSeeder(this.database);

  Future<void> seedPasienData() async {
    // Check if data already exists
    final existingData = await database.getAllPasiens();
    if (existingData.isNotEmpty) {
      print('✅ Database already has ${existingData.length} patients');
      return;
    }

    print('🌱 Seeding patient data...');

    // Sample patients data
    final samplePatients = [
      PasiensCompanion.insert(
        noRm: 'RM001',
        nama: 'Ahmad Wijaya',
        nik: Value('3201012345678901'),
        noBpjs: Value('0001234567890'),
        tempatLahir: 'Jakarta',
        tanggalLahir: DateTime(1985, 5, 15),
        jenisKelamin: 'L',
        golonganDarah: Value('A'),
        alamat: 'Jl. Merdeka No. 10, Jakarta Pusat',
        noTelp: '081234567890',
      ),
      PasiensCompanion.insert(
        noRm: 'RM002',
        nama: 'Siti Nurhaliza',
        nik: Value('3201022345678902'),
        noBpjs: Value('0001234567891'),
        tempatLahir: 'Bandung',
        tanggalLahir: DateTime(1990, 8, 20),
        jenisKelamin: 'P',
        golonganDarah: Value('B'),
        alamat: 'Jl. Sudirman No. 25, Bandung',
        noTelp: '081234567891',
      ),
      PasiensCompanion.insert(
        noRm: 'RM003',
        nama: 'Budi Santoso',
        nik: Value('3201032345678903'),
        noBpjs: Value('0001234567892'),
        tempatLahir: 'Surabaya',
        tanggalLahir: DateTime(1978, 3, 10),
        jenisKelamin: 'L',
        golonganDarah: Value('O'),
        alamat: 'Jl. Ahmad Yani No. 5, Surabaya',
        noTelp: '081234567892',
      ),
      PasiensCompanion.insert(
        noRm: 'RM004',
        nama: 'Dewi Lestari',
        nik: Value('3201042345678904'),
        noBpjs: Value('0001234567893'),
        tempatLahir: 'Yogyakarta',
        tanggalLahir: DateTime(1995, 12, 5),
        jenisKelamin: 'P',
        golonganDarah: Value('AB'),
        alamat: 'Jl. Malioboro No. 15, Yogyakarta',
        noTelp: '081234567893',
      ),
      PasiensCompanion.insert(
        noRm: 'RM005',
        nama: 'Eko Prasetyo',
        nik: Value('3201052345678905'),
        tempatLahir: 'Semarang',
        tanggalLahir: DateTime(1988, 7, 25),
        jenisKelamin: 'L',
        golonganDarah: Value('A'),
        alamat: 'Jl. Pemuda No. 30, Semarang',
        noTelp: '081234567894',
      ),
      PasiensCompanion.insert(
        noRm: 'RM006',
        nama: 'Fitri Handayani',
        nik: Value('3201062345678906'),
        noBpjs: Value('0001234567895'),
        tempatLahir: 'Malang',
        tanggalLahir: DateTime(1992, 11, 18),
        jenisKelamin: 'P',
        golonganDarah: Value('B'),
        alamat: 'Jl. Ijen No. 8, Malang',
        noTelp: '081234567895',
      ),
      PasiensCompanion.insert(
        noRm: 'RM007',
        nama: 'Hendra Gunawan',
        nik: Value('3201072345678907'),
        tempatLahir: 'Solo',
        tanggalLahir: DateTime(1982, 4, 12),
        jenisKelamin: 'L',
        golonganDarah: Value('O'),
        alamat: 'Jl. Slamet Riyadi No. 20, Solo',
        noTelp: '081234567896',
      ),
      PasiensCompanion.insert(
        noRm: 'RM008',
        nama: 'Indah Permata',
        nik: Value('3201082345678908'),
        noBpjs: Value('0001234567897'),
        tempatLahir: 'Medan',
        tanggalLahir: DateTime(1994, 9, 8),
        jenisKelamin: 'P',
        golonganDarah: Value('A'),
        alamat: 'Jl. Gatot Subroto No. 12, Medan',
        noTelp: '081234567897',
      ),
    ];

    // Insert all sample patients
    for (final patient in samplePatients) {
      await database.insertPasien(patient);
    }

    print('✅ Successfully seeded ${samplePatients.length} patients');
  }
}
