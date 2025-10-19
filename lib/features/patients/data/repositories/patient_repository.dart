import '../../domain/models/patient.dart';
import '../datasources/patient_remote_datasource.dart';

class PatientRepository {
  final PatientRemoteDataSource remoteDataSource;

  PatientRepository(this.remoteDataSource);

  Future<List<Patient>> fetchAllPatients() async {
    return await remoteDataSource.getAllPatients();
  }

  Future<Patient> fetchPatientDetail(int id) async {
    return await remoteDataSource.getPatientDetail(id);
  }
}
