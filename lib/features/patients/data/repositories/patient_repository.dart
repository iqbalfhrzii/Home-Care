// Offline dummy stub: legacy repository no longer used. Kept for compatibility.
import '../../domain/models/patient.dart';

class PatientRepository {
  PatientRepository();

  Future<List<Patient>> fetchAllPatients() async {
    return [];
  }

  Future<Patient> fetchPatientDetail(int id) async {
    // Return a simple dummy Patient
    return Patient(
      id: id,
      noRM: 'RM${id.toString().padLeft(4, '0')}',
      namaPasien: 'Pasien #$id',
      tanggalLahir: DateTime(1990, 1, 1).toIso8601String(),
      alamat: 'Alamat dummy',
      statusRujukan: 'Tidak',
    );
  }
}
