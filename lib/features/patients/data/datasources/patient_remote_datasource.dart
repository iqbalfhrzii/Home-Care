import 'package:homecare_mobile/core/network/dio.dart';
import '../../domain/models/patient.dart';

class PatientRemoteDataSource {
  /// Ambil semua data pasien dari API
  Future<List<Patient>> getAllPatients() async {
    try {
      final response = await dio.get('/petugas/pasien');

      final List data =
          response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;

      return data.map((e) => Patient.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Gagal memuat data pasien: $e');
    }
  }

  /// Ambil detail satu pasien berdasarkan ID
  Future<Patient> getPatientDetail(int id) async {
    try {
      final response = await dio.get('/petugas/pasien/$id');
      return Patient.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Gagal memuat detail pasien: $e');
    }
  }

  /// Alias / wrapper untuk getPatientDetail
  Future<Patient> getPatientById(int patientId) async {
    return await getPatientDetail(patientId);
  }
}
