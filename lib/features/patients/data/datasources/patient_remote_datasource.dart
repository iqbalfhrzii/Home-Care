import 'package:dio/dio.dart';
import 'package:homecare_mobile/core/network/dio.dart';
import '../../domain/models/patient.dart';

class PatientRemoteDataSource {
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

  Future<Patient> createPatient(Map<String, dynamic> payload) async {
    try {
      final response = await dio.post('/petugas/pasien', data: payload);
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return Patient.fromJson(data);
    } on DioError catch (e) {
      final status = e.response?.statusCode;
      final respData = e.response?.data;
      final message =
          'Gagal membuat pasien: status=$status, data=$respData, message=${e.message}';
      throw Exception(message);
    } catch (e) {
      throw Exception('Gagal membuat pasien: $e');
    }
  }

  Future<Patient> getPatientDetail(int id) async {
    try {
      final response = await dio.get('/petugas/pasien/$id');
      return Patient.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Gagal memuat detail pasien: $e');
    }
  }

  Future<Patient> getPatientById(int patientId) async {
    return await getPatientDetail(patientId);
  }
}
