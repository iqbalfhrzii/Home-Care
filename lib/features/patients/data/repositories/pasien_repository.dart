import 'package:homecare_mobile/features/patients/domain/models/pasien.dart';
import 'package:homecare_mobile/features/patients/data/datasources/pasien_data_source.dart';
import 'package:homecare_mobile/features/patients/data/datasources/pasien_local_data_source.dart';

class PasienRepository {
  final PasienDataSource _remoteDataSource;
  final PasienLocalDataSource _localDataSource;

  PasienRepository(this._remoteDataSource, this._localDataSource);

  // ========== LOCAL ONLY MODE ==========
  // API calls disabled for patient CRUD
  // API only used for authentication

  Future<List<Pasien>> getAllPasien() async {
    print('📂 [LOCAL ONLY] Loading all patients from database...');
    return await _localDataSource.getAllPasien();
  }

  Future<Pasien> getPasienById(String id) async {
    print('📂 [LOCAL ONLY] Loading patient by ID: $id');
    return await _localDataSource.getPasienById(id);
  }

  Future<Pasien> createPasien({
    required String nama,
    required String tempatLahir,
    required String tanggalLahir,
    required String jenisKelamin,
    required String alamat,
    required String noTelp,
    String? nik,
    String? noBpjs,
    String? golonganDarah,
  }) async {
    print('📂 [LOCAL ONLY] Creating new patient: $nama');

    final data = {
      'nama': nama,
      'tempat_lahir': tempatLahir,
      'tanggal_lahir': tanggalLahir,
      'jenis_kelamin': jenisKelamin,
      'alamat': alamat,
      'no_telp': noTelp,
      if (nik != null) 'nik': nik,
      if (noBpjs != null) 'no_bpjs': noBpjs,
      if (golonganDarah != null) 'golongan_darah': golonganDarah,
    };

    return await _localDataSource.createPasien(data);
  }

  Future<Pasien> updatePasien({
    required String id,
    required String nama,
    required String tempatLahir,
    required String tanggalLahir,
    required String jenisKelamin,
    required String alamat,
    required String noTelp,
    String? nik,
    String? noBpjs,
    String? golonganDarah,
  }) async {
    print('📂 [LOCAL ONLY] Updating patient: $id');

    final data = {
      'nama': nama,
      'tempat_lahir': tempatLahir,
      'tanggal_lahir': tanggalLahir,
      'jenis_kelamin': jenisKelamin,
      'alamat': alamat,
      'no_telp': noTelp,
      if (nik != null) 'nik': nik,
      if (noBpjs != null) 'no_bpjs': noBpjs,
      if (golonganDarah != null) 'golongan_darah': golonganDarah,
    };

    return await _localDataSource.updatePasien(id, data);
  }

  Future<void> deletePasien(String id) async {
    print('📂 [LOCAL ONLY] Deleting patient: $id');
    await _localDataSource.deletePasien(id);
    print('✅ Patient deleted successfully');
  }

  Future<List<Pasien>> searchPasien(String query) async {
    print('📂 [LOCAL ONLY] Searching patients: $query');
    final allPatients = await _localDataSource.getAllPasien();

    if (query.isEmpty) return allPatients;

    // Local search by name, RM, phone
    return allPatients.where((patient) {
      final searchLower = query.toLowerCase();
      return patient.nama.toLowerCase().contains(searchLower) ||
          patient.noRm.toLowerCase().contains(searchLower) ||
          patient.noTelp.toLowerCase().contains(searchLower);
    }).toList();
  }

  Future<void> markAsRegistered(String patientId) async {
    print('📂 [LOCAL ONLY] Marking patient as registered: $patientId');
    await _localDataSource.markAsRegistered(patientId);
    print('✅ Patient registration status updated');
  }
}
