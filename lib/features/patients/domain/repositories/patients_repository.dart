import 'package:fpdart/fpdart.dart';
import 'package:homecare_mobile/core/error/failures.dart';
import 'package:homecare_mobile/features/patients/domain/models/patient.dart';
import 'package:homecare_mobile/features/patients/domain/models/patients_response.dart';

abstract class PatientRepository {
  TaskEither<Failure, PatientsResponse> getPatients(int page);
  TaskEither<Failure, Patient> getPatientById(int id);
}
